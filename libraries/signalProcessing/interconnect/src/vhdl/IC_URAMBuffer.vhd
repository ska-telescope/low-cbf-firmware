----------------------------------------------------------------------------------
-- Company: CSIRO 
-- Engineer: David Humphrey (dave.humphrey@csiro.au)
-- 
-- Create Date: 14.07.2019
-- Module Name: IC_URAMBuffer - Behavioral
--
-- Description 
-- -----------
--   + Takes in packets
--   + Checks or generates the FCS
--   + Stores in a URAM buffer
--   + Discards packets that have a bad FCS (if the FCS is being checked) or that don't fit in the buffer
--   + Notifies the destination interconnect port that a packet is available.
--   + Streams out the packet to the destination when the destination is ready.
--
-- Buffer management
-- -----------------
-- One ultraRAM is (4096 deep) x (66 bit words). The URAM buffer is treated as blocks of 
--   + URAMBLOCKS = 1 ==> 128 words (32 * 128 = 4096 = 1 URAM block),
--   + URAMBLOCKS = 2 ==> 256 words (32 * 256 = 8192 = 2 URAM blocks).
-- Each block has a single bit to indicate if it is currently in use or not (signal "blockUsed")
-- The generic URAMBLOCKS selects the number of URAM blocks to use in the buffer, up to a maximum of 8.
-- For writes into the buffer, the buffer is treated as a circular buffer :
--   + New packets start at the next block boundary (i.e. the first word in the packet is always 128 word aligned in the buffer)
--   + Packets are always contiguous in the uram, although they can wrap back from the last block to the first block
--     e.g. a packet could use blocks 30, 31, 0, 1, 2 (if 1 URAM is used, i.e. URAMBLOCKS = 1)
--   + The blockUsed bit is checked for each block before the block is written to. If the blockUsed bit is set,
--     then there is insufficient space in the buffer and the packet is dropped. Dropped packets should never 
--     happen; there is a error bit to indicate if they do.
--   + The top 2 bits of each word in the URAM (65:64) are used to indicate start and end of a frame ("01" = sof, "10" = eof)
--
-- Reads from the buffer do not necessarily occur in the same order as the writes. (See the discussion below on allowing out-of-order reads)
-- For reads from the buffer:
--   + When an error-free packet is written into the buffer, a notification is generated, to be sent to the destination port
--     The notification includes :
--       * The destination port
--       * The URAM block (i.e. 128 or 256 word boundary, depending on URAMBLOCKS) that the packet starts on.
--     The notification goes into a small fifo in this module, with the output of the fifo exposed as ports.
--     the notification fifo is needed to ensure notifications are not lost, since multiple source modules could notify
--     at the same time, so notifications will not be processed every clock (on average they may only be processed every
--     Nth clock, where N is the number of source ports).
--   + When a destination port is ready to take a packet, the block boundary for the packet is sent to this module,
--     and this module reads the packet out, starting at the start of that block and ending when the high two bits indicate
--     eof.
--
-- Addressing
-- ----------
-- The first (64 bit) word of each packet must contain :
--
--   DEST    SRC1     SRC2    SRC3     PacketTYPE
-- (63:52)  (51:40)  (39:28) (27:16)  (15:8)
-- 
-- Each address (DEST, SRC1, SRC2, SRC3) is made up of 
--  (11:8) = Y coordinate
--  (7:4) = X coordinate
--  (3:0) = Z coordinate
--
-- Packets travel through FPGAs in in the order : SRC3 -> SRC2 -> SRC1 -> DEST
-- If there are less than 3 hops to the destination, then the unused addresses are 0xfff
-- e.g. a single hop packet would have SRC3 = SRC2 = 0xfff
--
-- The interconnect module has output ports which go to each possible destination. 
-- The output ports are numbered as :
--  0-6 : Z connect (e.g. port 3 sends data over the fiber to a different Z location, and the same X,Y coordinates as this FPGA)
--  7-11 : X connect
--  12-16 : Y connect
--  17 up : The signal processing chain in this FPGA, identified as (17 + packetType)
--
-- Timing Packets 
-- --------------
-- Packets sent by the timing module (PacketTYPE = 0) are a special case :
--  + PacketType = 0
--  + They are always single hop
--  + SRC3 = Port this packet came from (i.e. this identifies which particular GTY the packet was sent from).
--  + The current wall time when the packet is received is attached to the end of the packet.
--    This word replaces the word containing the FCS (since this FPGA is the destination for a timing packet,
--    we do not need the FCS anymore).
-- 
-- Why allow out-of-order reads ?
-- ------------------------------
-- This is to ensure the optical links are used efficiently, since the destination port for a given
-- packet could be busy with a packet from another source port, temporarily blocking this port. 
-- Blocking is statistically likely to occur for a non-negligible portion of the time, impacting the 
-- overall performance of the interconnect, since the average rate into the URAM cannot exceed the average rate out without
-- causing packets to be lost. By allowing packets other than the oldest packet in the buffer to be read when the destination
-- port is ready, the probability of blocking is significantly reduced.
-- 
----------------------------------------------------------------------------------

library IEEE, axi4_lib, interconnect_lib, common_lib, ctc_lib, dsp_top_lib;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
Library xpm;
use xpm.vcomponents.all;
use common_lib.common_pkg.all;
use interconnect_lib.all;
use dsp_top_lib.dsp_top_pkg.all;
--use ctc_lib.ctc_pkg.all;

entity IC_URAMBuffer is
    generic(
        -- 0 = 3 FPGAs (X x Y x Z = 1x1x3), 1 = 12 FPGAs (X x Y x Z = 1x6x2), 2 = etc....
        -- See confluence page (perentie -> Model development -> packetised model overview -> model configuration)    
        ARRAYRELEASE : integer range 0 to 5 := 0;
        GENERATEFCS : std_logic := '0'; --  if '1', then generate the FCS here. if '0' then check the FCS.
        URAMBLOCKS : integer range 1 to 2 := 1
    );
    port(
        -- Everything is on a single clock (about 400 MHz)
        i_IC_clk : in std_logic;
        i_rst : in std_logic;
        -- Configuration information
        i_myAddr : in std_logic_vector(11 downto 0);  -- X,Y and Z coordinates of this FPGA in the array, used for routing.
        i_myPort : in std_logic_vector(4 downto 0); -- unique ID for this input port in the interconnect. 
        -- Wall time is used to timestamp incoming packets. This is only used for timing packets.
        i_wallTime : in t_wall_time;
        -- Packet Data input
        -- Note : When generating the FCS, there must be at least one cycle between packets with i_valid low,
        -- in order to allow time to insert the FCS word.
        i_data      : in std_logic_vector(63 downto 0); 
        i_valid     : in std_logic;
        i_sof       : in std_logic;
        i_eof       : in std_logic;
        -- Notification to destination ports of packets being available.
        o_blockPort      : out std_logic_vector(20 downto 0); -- destination port (bits(15:0)), buffer block (bits(20:16))
        o_blockPortValid : out std_logic;
        i_blockPortRead  : in std_logic;
        -------------------
        -- data packets out
        -- Requests in from the destination ports
        i_block : in t_slv_5_arr(31 downto 0);     -- Each destination port has a 5 bit vector to specify the block it wants a frame from.
        i_port  : in t_slv_5_arr(31 downto 0);     -- The port that data is being requested from (compared here with i_myPort)
        i_blockReq : in std_logic_vector(31 downto 0); -- One request line for each destination port. 
        -- The packets
        o_data      : out std_logic_vector(63 downto 0);
        o_outputMux : out std_logic_vector(4 downto 0); -- the output mux that the packet is being sent to. Matches the index of the request from the input bus (i_block, i_port, i_blockReq)
        o_valid     : out std_logic;
        -- status
        o_goodPacket       : out std_logic;  -- Valid packet was received (either FCS was good, or FCS checking not enabled).
        i_clrErrorCounts   : in std_logic;   -- reset o_errorCounts and o_SingleHopSrcDest
        -- The 4 bit counters that make up o_errorCounts have a 3 bit counter, with the 4th bit used to indicate any occurence of the condition.
        o_errorCounts   : out std_logic_vector(15 downto 0) -- (3:0) = packet drop count, (7:4) = bad FCS count, (11:8) = unroutable count, (15:12) = Notification fifoFull count
    );
end IC_URAMBuffer;

architecture Behavioral of IC_URAMBuffer is
    
    type input_fsm_type is (idle, wrPacket, discardNoSpace);
    signal input_fsm : input_fsm_type := idle;    
    
    signal fcsData   : std_logic_vector(63 downto 0);
    signal validDel1, validDel2 : std_logic;
    signal sofDel1, sofDel2 : std_logic;
    signal blockUsed, blockUsedTemp : std_logic_vector(31 downto 0) := x"00000000";
    signal blockStartFull : std_logic_vector((10 + URAMBLOCKS) downto 0);
    signal blockStart, blockStartDel1 : std_logic_vector(4 downto 0);
    signal wrAddrFullDel2, wrAddrDel1 : std_logic_vector((10 + URAMBLOCKS) downto 0);
    signal destEQme, src1EQme, src2EQme, src3EQme : std_logic := '0';
    signal src2Unused, src3Unused : std_logic := '0';
    signal SRC1YXZ : std_logic_vector(11 downto 0);
    signal SRC2YXZ : std_logic_vector(11 downto 0);
    signal SRC3YXZ : std_logic_vector(11 downto 0);
    signal destYXZ : std_logic_vector(11 downto 0);
    signal packetType : std_logic_vector(7 downto 0);
    
    signal fifoDin : std_logic_vector(20 downto 0);
    signal fifoWrEn, fifoEmpty, fifoFull : std_logic;

    signal blockSel : std_logic_vector(4 downto 0);
    signal blockSelValid : std_logic;
    signal anyRequest : std_logic;
    
    type output_fsm_type is (idle, sendPacket, enforceMinLength);
    signal minLengthCount : std_logic_vector(3 downto 0);
    signal output_fsm, output_fsm_del1, output_fsm_del2 : output_fsm_type := idle;
    signal eofOccurred : std_logic := '0';
    signal curBlock, curBlockDel1, curBlockDel2 : std_logic_vector(4 downto 0);
    signal clearBlock : std_logic_vector(4 downto 0);
    signal clearBlockUsed : std_logic;
    signal bufRdAddr, bufRdAddrDel1, bufRdAddrDel2 : std_logic_vector(10 + URAMBLOCKS downto 0);    
    signal destinationPort : std_logic_vector(15 downto 0);
    
    signal bufWrAddr : std_logic_vector(10 + URAMBLOCKS downto 0);
    signal updateBlockUsed : std_logic;
    signal routable : std_logic;
    
    -- first word fall through fifo used for notifications of available packets
    component fifo11x16
    port (
        clk   : IN STD_LOGIC;
        srst  : IN STD_LOGIC;
        din   : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
        wr_en : IN STD_LOGIC;
        rd_en : IN STD_LOGIC;
        dout  : OUT STD_LOGIC_VECTOR(10 DOWNTO 0);
        full  : OUT STD_LOGIC;
        empty : OUT STD_LOGIC;
        wr_rst_busy : OUT STD_LOGIC;
        rd_rst_busy : OUT STD_LOGIC);
    end component;    
    
    signal eofDel1, eofDel2 : std_logic;
    signal sofWallTime : t_wall_time;
    signal timingPacket : std_logic := '0';
    signal calculatedFCS : std_logic_vector(31 downto 0);
    signal FCSokDel2 : std_logic;
    signal dataDel2 : std_logic_vector(63 downto 0);
    signal plainValidDel2 : std_logic;
    signal nextXYZ : std_logic_vector(11 downto 0);
    signal addrFound : std_logic;
    signal thisBlockUsed : std_logic;
    signal wrBlockIndex : std_logic_vector(4 downto 0);
    signal nextBlockStart : std_logic_vector(4 downto 0);
    signal nextBlockStartFull : std_logic_vector((10 + URAMBLOCKS) downto 0);
    signal bufDin : std_logic_vector(65 downto 0);
    signal bufWE : std_logic_vector(0 downto 0);
    signal bufDout : std_logic_vector(65 downto 0);
    signal req, reqZeroed : std_logic_vector(31 downto 0);
    signal oMuxIndex, curOMux, curOMuxDel1, curOMuxDel2 : std_logic_vector(4 downto 0);
    
    signal oPacketDrop : std_logic;  -- input packet was dropped due to a lack of space in the URAM buffer.
    signal obadFCS     : std_logic;  -- input packet was dropped because the FCS was bad.
    signal ounroutable : std_logic;  -- Packet requests impossible routing (e.g. X and Y coordinate change in one hop)
    signal ofifoFull   : std_logic;  -- notification fifo filled up; Should be impossible.
    
    signal AnyPacketDrops : std_logic := '0';
    signal packetDrops : std_logic_vector(2 downto 0) := "000";
    signal AnyBadFCSs : std_logic := '0';
    signal badFCSs : std_logic_vector(2 downto 0) := "000";
    signal AnyUnroutables : std_logic := '0';
    signal unroutables : std_logic_vector(2 downto 0) := "000";
    signal AnyFifoFulls : std_logic := '0';
    signal fifoFulls : std_logic_vector(2 downto 0) := "000";
    
begin
    
    ---------------------------------------------------------------------------
    -- Generation or checking of the FCS.
    -- signals dataDel2, ValidDel2, sofDel2, eofDel2, wrAddrDel2 and fcsOKDel2 are generated
    --  +  When generating the FCS, these signals include an extra word at the end with the FCS,
    --     and so are validDel2 runs for one more clock as compared to i_valid
    --  +  When checking the FCS, validDel2 has the same number of cycles as i_valid.
    --  +  wrAddrDel2 is a count of the number of words in the packet, starting from 0.
    --
    process(i_IC_clk)
    begin
        if rising_edge(i_IC_clk) then
            if i_sof = '1' then
                -- Low byte of the first word in a frame is a control byte which is not used for the FCS.
                fcsData <= i_data(63 downto 8) & x"00";
            else
                fcsData <= i_data;
            end if;
            validDel1 <= i_valid;
            sofDel1 <= i_sof;
            eofDel1 <= i_eof;
            if i_sof = '1' then
                wrAddrDel1 <= (others => '0');
            elsif validDel1 = '1' then
                wrAddrDel1 <= std_logic_vector(unsigned(wrAddrDel1) + 1);
            end if;
        end if;
    end process;
    
    -- FCS generation/checking
    --FCSGenCheck : entity interconnect_lib.crc32Full64Step
    FCSGenCheck : entity interconnect_lib.crc32Full64Step
    port map (
        clk         => i_IC_clk,         -- in std_logic;
        data_i      => fcsData,          -- in(63:0);
        valid_i     => validDel1,        -- in std_logic;
        sof_i       => sofDel1,          -- in std_logic;
        state_o     => calculatedFCS,    -- out(31:0), valid in the cycle after the last data word.
        new_state_o => open -- out(31:0) -- logic only path from data_i, bytes_i
    );
    
    FCSCHECK_GEN : if GENERATEFCS = '0' generate
        
        -- Not generating the FCS, so we are checking the FCS.
        FCSokDel2 <= '1' when validDel2 = '1' and eofDel2 = '1' and calculatedFCS = fcsData(63 downto 32) else '0';
        
        process(i_IC_clk)
        begin
            if rising_edge(i_IC_clk) then
                if sofDel1 = '1' and validDel1 = '1' then
                    sofWallTime <= i_wallTime;
                    if fcsData(15 downto 8) = "00000000" then
                        timingPacket <= '1';
                    else
                        timingPacket <= '0';
                    end if;
                end if;
                if eofDel1 = '1' and validDel1 = '1' and timingPacket = '1' then
                    dataDel2 <= sofWallTime.sec & "00" & sofWallTime.ns;
                else
                    dataDel2 <= fcsData;
                end if;
                validDel2 <= validDel1;
                sofDel2 <= sofDel1;
                eofDel2 <= eofDel1;
                --wrAddrDel2 <= wrAddrDel1;
            end if;
        end process;
    
    end generate;
    
    FCSGENERATE_GEN : if GENERATEFCS = '1' generate
        -- Generate the FCS and create one extra word at the end of the packet with the FCS.
        process(i_IC_clk)
        begin
            if rising_edge(i_IC_clk) then
                eofDel2 <= eofDel1;
                sofDel2 <= sofDel1;
                plainValidDel2 <= validDel1;
                validDel2 <= validDel1 or eofDel2;
                if eofDel2 = '1' and plainValidDel2 = '1' then
                    dataDel2 <= calculatedFCS & x"00000000";
                else
                    dataDel2 <= fcsData;
                end if;
                --wrAddrDel2 <= wrAddrDel1;
            end if;
        end process;
        FCSokDel2 <= '1';  -- We just generated the FCS, so it must be good.
    end generate;
    
    -- Capture the addressing data so we can determine the destination port
    process(i_IC_clk)
        variable destXYZv : std_logic_vector(11 downto 0);
        variable SRC1XYZv : std_logic_vector(11 downto 0);
        variable SRC2XYZv : std_logic_vector(11 downto 0);
        variable SRC3XYZv : std_logic_vector(11 downto 0);    
    begin
        if rising_edge(i_IC_clk) then

            destXYZv := fcsData(63 downto 52);
            SRC1XYZv := fcsData(51 downto 40);
            SRC2XYZv := fcsData(39 downto 28);
            SRC3XYZv := fcsData(27 downto 16);

            -- Signals destEQme, nextYXZ and addrFound all align with dataDel2, validDel2
            if destXYZv = i_myAddr then
                destEQme <= '1';
            else
                destEQme <= '0';
            end if;
            
            if SRC1XYZv = i_myAddr then
                nextXYZ <= destXYZv;
                addrFound <= '1';
            elsif SRC2XYZv = i_myAddr then
                nextXYZ <= SRC1XYZv;
                addrFound <= '1';
            elsif SRC3XYZv = i_myAddr then
                nextXYZ <= SRC2XYZv;
                addrFound <= '1';
            else
                nextXYZ <= (others => '1'); 
                addrFound <= '0';
            end if;
            
        end if;
    end process;
    
    
    ----------------------------------------------------------------------------
    -- Manage the write pointer for the URAM buffer 
    process(i_IC_clk)
        variable packetTypev : std_logic_vector(3 downto 0);
    begin
        if rising_edge(i_IC_clk) then
        
            if i_rst = '1' then
                bufWrAddr <= (others => '0');
                -- Address of the first block in the URAM that the packet is written to.
                -- 32 blocks, so the block address is 5 bits.
                blockStart <= (others => '0'); 
                input_fsm <= idle;
                blockUsed <= (others => '0');
                updateBlockUsed <= '0';
                routable <= '0';
            else
                case input_fsm is
                    when idle =>
                        if validDel2 = '1' and sofDel2 = '1' then
                            if thisBlockUsed = '0' then
                                input_fsm <= wrPacket;
                            else
                                input_fsm <= discardNoSpace;
                            end if;
                            -- Get the destination address for this packet.
                            packetTypev := dataDel2(11 downto 8);
                            if destEQme = '1' then
                                destinationPort <= packetTypev(3 downto 0) & i_myAddr; -- identifies the signal processing chain.
                                routable <= '1';
                            elsif addrFound = '1' then -- we are at src1, or src2 or src3. Go to nextYXZ
                                if ((nextXYZ(11 downto 4) = i_myAddr(11 downto 4))  or   -- X and Y match i_myAddr
                                    (nextXYZ(11 downto 8) = i_myAddr(11 downto 8) and nextXYZ(3 downto 0) = i_myAddr(3 downto 0)) or -- X and Z match i_myAddr, do a Y hop
                                    (nextXYZ(7 downto 0) = i_myAddr(7 downto 0))) then
                                    -- either X and Y match myAddr, or X and Z match myAddr, or Y and Z match myAddr,
                                    -- so we can route over the appropriate link to get the nextXYZ. 
                                    destinationPort <= "0000" & nextXYZ(11 downto 0);  -- do a Z hop.
                                    routable <= '1';
                                else
                                    destinationPort <= (others => '1'); -- unroutable.
                                    routable <= '0';
                                end if;
                            else  -- This FPGA is not in the list of addresses, so the packet is unroutable
                                routable <= '0';
                            end if;
                            
                        end if;
                        updateBlockUsed <= '0';
                    
                    when wrPacket =>
                        if validDel2 = '1' and thisBlockUsed = '1' and eofDel2 = '0' then
                            input_fsm <= discardNoSpace;
                            updateBlockUsed <= '0';
                        elsif validDel2 = '1' and eofDel2 = '1' then
                            input_fsm <= idle;
                            if thisBlockUsed = '0' and FCSokDel2 = '1' and routable = '1' then
                                -- wrAddrFullDel2 is the last write address for this frame; +1 to round up to the next block.
                                blockStart <= nextBlockStart;   -- = std_logic_vector(unsigned(wrAddrFullDel2((10 + URAMBLOCKS) downto (6 + URAMBLOCKS))) + 1);
                                updateBlockUsed <= '1';
                            end if;
                        else
                            updateBlockUsed <= '0';
                        end if;
                        
                    when discardNoSpace => 
                        -- tried to write to part of the buffer that was already used.
                        -- Wait until the packet finishes
                        updateBlockUsed <= '0';
                        if eofDel2 = '1' then
                            input_fsm <= idle;
                        end if;
                        
                    when others =>
                        input_fsm <= idle;
                        
                end case;
                
                -- Keep track of blockUsed;
                --  - Since we don't know until the end of a packet whether we want to keep it or not, a temporary version of blockUsed 
                --    is maintained as we do the write, which is then or'd into blockUsed once we know the packet was OK.
                if validDel2 = '1' then
                    if sofDel2 = '1' then
                        blockUsedTemp <= (others => '0');
                        blockUsedTemp(to_integer(unsigned(wrAddrFullDel2((10 + URAMBLOCKS) downto (6 + URAMBLOCKS))))) <= '1';
                    else
                        blockUsedTemp(to_integer(unsigned(wrAddrFullDel2((10 + URAMBLOCKS) downto (6 + URAMBLOCKS))))) <= '1';
                    end if;
                end if;
                
                
                -- reading from a block puts blockused to 0
                if clearBlockUsed = '1' then
                    blockUsed(to_integer(unsigned(clearBlock))) <= '0';
                end if; 
                -- end of a packet, update the blocks written to. 
                if updateBlockUsed = '1' then
                    blockUsed <= blockUsed or blockUsedTemp;
                end if;
                
                
            end if;
            
            blockStartDel1 <= blockStart;
            
            if eofDel2 = '1' then
                bufDin(65 downto 64) <= "10";
            elsif sofDel2 = '1' then
                bufDin(65 downto 64) <= "01";
            else
                bufDin(65 downto 64) <= "00";
            end if;
            bufDin(63 downto 0) <= dataDel2;
            
            -- Because this uses wrAddrDel1, it needs to anticipate the next value of blockStart for the case where
            -- frames are back to back, hence "NextBlockStartFull" 
            if (validDel2 = '1' and eofDel2 = '1' and input_fsm /= discardNoSpace and thisBlockUsed = '0') then
                wrAddrFullDel2 <= std_logic_vector(unsigned(NextBlockStartFull) + unsigned(wrAddrDel1));
            else
                wrAddrFullDel2 <= std_logic_vector(unsigned(BlockStartFull) + unsigned(wrAddrDel1));
            end if;
            
            bufWrAddr <= wrAddrFullDel2;
            if (validDel2 = '1' and thisBlockUsed = '0' and input_fsm /= discardNoSpace) then
                bufWe(0) <= '1';
            else
                bufWe(0) <= '0';
            end if;
            
            -- Status bits out
            if validDel2 = '1' and thisBlockUsed = '1' and input_fsm /= discardNoSpace then
                -- exclude the state discardNoSpace so we only generate one pulse on o_packetDrop
                opacketDrop <= '1';
            else
                opacketDrop <= '0';
            end if;
            o_goodPacket <= updateBlockUsed;
            if FCSokDel2 = '1' and validDel2 = '1' and eofDel2 = '1' then
                o_goodPacket <= '1';
            else
                o_goodPacket <= '0';
            end if;
            if FCSokDel2 = '1' and validDel2 = '1' and eofDel2 = '1' and routable = '0' then
                ounroutable <= '1'; -- packet was OK but the requested routing is impossible.
            else
                ounroutable <= '0';
            end if;
            ofifoFull <= fifoFull;
            
        end if;
    end process;
    
    blockStartFull((10 + URAMBLOCKS) downto (6 + URAMBLOCKS)) <= blockStart; -- either 11:7 or 12:8
    blockStartFull((5 + URAMBLOCKS) downto 0) <= (others => '0');
    
    nextBlockStart <= std_logic_vector(unsigned(wrAddrFullDel2((10 + URAMBLOCKS) downto (6 + URAMBLOCKS))) + 1);
    nextBlockStartFull((10 + URAMBLOCKS) downto (6 + URAMBLOCKS)) <= nextBlockStart; -- either 11:7 or 12:8
    nextBlockStartFull((5 + URAMBLOCKS) downto 0) <= (others => '0');
    
    -- Is the block we are about to write to already used ?
    wrBlockIndex <= wrAddrFullDel2((10 + URAMBLOCKS) downto (6 + URAMBLOCKS));  -- (11:7) for 128 word blocks, or (12:8) for 256 word blocks
    thisBlockUsed <= blockUsed(to_integer(unsigned(wrBlockIndex)));
    
    ----------------------------------------------------------------------------
    -- Memory blocks
    -- main buffer is ultraRam, 
    --  bufWE
    --  bufWrAddr
    --  bufDin
    --  bufRdAddr
    --  bufDout
    
    -- UltraRAM buffer
    uram_inst : xpm_memory_sdpram
    generic map (    
        -- Common module generics
        MEMORY_SIZE             => (270336 * URAMBLOCKS),  -- Total memory size in bits; 4096 x 66 = 270336
        MEMORY_PRIMITIVE        => "ultra",        --string; "auto", "distributed", "block" or "ultra" ;
        CLOCKING_MODE           => "common_clock", --string; "common_clock", "independent_clock" 
        MEMORY_INIT_FILE        => "none",         --string; "none" or "<filename>.mem" 
        MEMORY_INIT_PARAM       => "",             --string;
        USE_MEM_INIT            => 0,              --integer; 0,1
        WAKEUP_TIME             => "disable_sleep",--string; "disable_sleep" or "use_sleep_pin" 
        MESSAGE_CONTROL         => 0,              --integer; 0,1
        ECC_MODE                => "no_ecc",       --string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode" 
        AUTO_SLEEP_TIME         => 0,              --Do not Change
        USE_EMBEDDED_CONSTRAINT => 0,              --integer: 0,1
        MEMORY_OPTIMIZATION     => "true",          --string; "true", "false"
        -- Port A module generics
        WRITE_DATA_WIDTH_A      => 66,                --positive integer
        BYTE_WRITE_WIDTH_A      => 66,                --integer; 8, 9, or WRITE_DATA_WIDTH_A value
        ADDR_WIDTH_A            => (11 + URAMBLOCKS), --positive integer
    
        -- Port B module generics
        READ_DATA_WIDTH_B       => 66,                --positive integer
        ADDR_WIDTH_B            => (11 + URAMBLOCKS), --positive integer
        READ_RESET_VALUE_B      => "0",            --string
        READ_LATENCY_B          => 2,              --non-negative integer
        WRITE_MODE_B            => "read_first")    --string; "write_first", "read_first", "no_change" 
    port map (
        -- Common module ports
        sleep                   => '0',
        -- Port A (Write side)
        clka                    => i_IC_clk,
        ena                     => '1',
        wea                     => bufWE,
        addra                   => bufWrAddr,
        dina                    => bufDin,
        injectsbiterra          => '0',
        injectdbiterra          => '0',
        -- Port B (read side)
        clkb                    => i_IC_clk,
        rstb                    => '0',
        enb                     => '1',
        regceb                  => '1',
        addrb                   => bufRdAddr,
        doutb                   => bufDout,
        sbiterrb                => open,
        dbiterrb                => open
    );
    
    
    -----------------------------------------------------------------------------------------------------------
    -- Read side
    -----------------------------------------------------------------------------------------------------------
    --
    -- Determine which block to read out, using the input ports:
    --   i_myPort : in std_logic_vector(4 downto 0); -- unique ID for this input port in the interconnect. 
    --   i_block : in array32x5bit_type;     -- Each destination port has a 5 bit vector to specify the block it wants a frame from.
    --   i_port  : in array32x5bit_type;     -- The port that data is being requested from (compared here with i_myPort)
    --   i_blockReq : in std_logic_vector(31 downto 0); -- One request line for each destination port. 
    
    process(i_IC_clk)
        variable foundOne : std_logic := '0';
        variable blockSelv : std_logic_vector(4 downto 0);
    begin
        if rising_edge(i_IC_clk) then
            for i in 0 to 31 loop
                if i_port(i) = i_myPort and i_blockReq(i) = '1' then
                    req(i) <= '1';
                else
                    req(i) <= '0';
                end if;
            end loop;
            
            -- Use req(i) to select one of the i_block inputs.
            -- If more than one bit in req is high, select the one with the smallest index.
            foundOne := '0';
            for i in 0 to 31 loop
                if foundOne = '1' then
                    reqZeroed(i) <= '0';
                else
                    reqZeroed(i) <= req(i);
                end if;
                if req(i) = '1' then
                    foundOne := '1';
                end if;
            end loop;
            anyRequest <= foundOne;
            
            -- Select the block from i_block which has '1' set in reqZeroed
            blockSelv := "00000";
            for i in 0 to 31 loop
                blockSelv(0) := blockSelv(0) or (i_block(i)(0) and reqZeroed(i));
                blockSelv(1) := blockSelv(1) or (i_block(i)(1) and reqZeroed(i));
                blockSelv(2) := blockSelv(2) or (i_block(i)(2) and reqZeroed(i));
                blockSelv(3) := blockSelv(3) or (i_block(i)(3) and reqZeroed(i));
                blockSelv(4) := blockSelv(4) or (i_block(i)(4) and reqZeroed(i));
            end loop;
            blockSel <= blockSelv;
            blockSelValid <= anyRequest;
            
            -- Work out the index into the  i_block, i_port, iblockReq arrays that we are reading from 
            -- i.e. the index of the non-zero value in reqZeroed(31:0) 
            oMuxIndex(0) <= reqZeroed(1) or reqZeroed(3) or reqZeroed(5) or reqZeroed(7) or reqZeroed(9) or reqZeroed(11) or reqZeroed(13) or reqZeroed(15) or 
                            reqZeroed(17) or reqZeroed(19) or reqZeroed(21) or reqZeroed(23) or reqZeroed(25) or reqZeroed(27) or reqZeroed(29) or reqZeroed(31);
            oMuxIndex(1) <= reqZeroed(2) or reqZeroed(3) or reqZeroed(6) or reqZeroed(7) or reqZeroed(10) or reqZeroed(11) or reqZeroed(14) or reqZeroed(15) or 
                            reqZeroed(18) or reqZeroed(19) or reqZeroed(22) or reqZeroed(23) or reqZeroed(26) or reqZeroed(27) or reqZeroed(30) or reqZeroed(31);
            oMuxIndex(2) <= reqZeroed(4) or reqZeroed(5) or reqZeroed(6) or reqZeroed(7) or reqZeroed(12) or reqZeroed(13) or reqZeroed(14) or reqZeroed(15) or 
                            reqZeroed(20) or reqZeroed(21) or reqZeroed(22) or reqZeroed(23) or reqZeroed(28) or reqZeroed(29) or reqZeroed(30) or reqZeroed(31);
            oMuxIndex(3) <= reqZeroed(8) or reqZeroed(9) or reqZeroed(10) or reqZeroed(11) or reqZeroed(12) or reqZeroed(13) or reqZeroed(14) or reqZeroed(15) or 
                            reqZeroed(24) or reqZeroed(25) or reqZeroed(26) or reqZeroed(27) or reqZeroed(28) or reqZeroed(29) or reqZeroed(30) or reqZeroed(31);
            oMuxIndex(4) <= reqZeroed(16) or reqZeroed(17) or reqZeroed(18) or reqZeroed(19) or reqZeroed(20) or reqZeroed(21) or reqZeroed(22) or reqZeroed(23) or 
                            reqZeroed(24) or reqZeroed(25) or reqZeroed(26) or reqZeroed(27) or reqZeroed(28) or reqZeroed(29) or reqZeroed(30) or reqZeroed(31);
            -----------------------------------------------------------------------------
            -- Wait for blockSelValid, then read the packet starting at the block blockSel
            
            case output_fsm is
                when idle =>
                    if blockSelValid = '1' then
                        bufRdAddr((10 + URAMBLOCKS) downto (6 + URAMBLOCKS)) <= blockSel;
                        bufRdAddr((5 + URAMBLOCKS) downto 0) <= (others => '0');
                        curBlock <= blockSel;
                        curOMux <= oMuxIndex;
                        output_fsm <= sendPacket;
                    end if;
                    minLengthCount <= "0000";
                    
                when sendPacket =>
                    bufRdAddr <= std_logic_vector(unsigned(bufRdAddr) + 1);
                    if (output_fsm_del2 = sendPacket) then
                        if bufDout(65 downto 64) = "10" then -- eof
                            if minLengthCount(3) /= '1' then
                                output_fsm <= enforceMinLength;
                            else
                                output_fsm <= idle;
                            end if;
                        end if;
                    end if;
                    if minLengthCount(3) /= '1' then
                        minLengthCount <= std_logic_vector(unsigned(minLengthCount) + 1);
                    end if; 
              
                when enforceMinLength =>
                    -- enforce a minimum time between servicing requests of 8 clocks.
                    -- This is to ensure the destination ports don't get served data for requests 
                    -- that they have since dropped.
                    if minLengthCount /= "1111" then
                        minLengthCount <= std_logic_vector(unsigned(minLengthCount) + 1);
                    end if;
                    if minLengthCount(3) = '1' then
                        output_fsm <= idle;
                    end if;
                    
                when others =>
                    output_fsm <= idle;
                    
            end case;
            
            output_fsm_del1 <= output_fsm;
            output_fsm_del2 <= output_fsm_del1;
            
            bufRdAddrDel1 <= bufRdAddr;
            bufRdAddrDel2 <= bufRdAddrDel1;
            
            curBlockDel1 <= curBlock;
            curBlockDel2 <= curBlockDel1;
            
            curOMuxDel1 <= curOMux;
            curOMuxDel2 <= curOMuxDel1;
            
            o_data <= bufDout(63 downto 0);
            if output_fsm_del2 = sendPacket and output_fsm = sendPacket then
                -- two cycle latency on the memory means we need to wait until output_fsm_del2 = sendPacket.
                -- Last word is detected from the data itself (encoded in bits(65:64)), so output_fsm goes back
                -- to idle after the last word is valid.
                o_valid <= '1';
            else
                o_valid <= '0';
            end if;
            o_outputMux <= curOMuxDel2;
            
            if output_fsm_del2 = idle then
                eofOccurred <= '0';
            elsif output_fsm_del2 = sendPacket and bufDout(65 downto 64) = "10" then
                eofOccurred <= '1';
            end if;
            
            if output_fsm_del2 = sendPacket and (to_integer(unsigned(bufRdAddrDel2((5 + URAMBLOCKS) downto 0))) = 0) and eofOccurred = '0' then
                clearBlockUsed <= '1';
                clearBlock <= bufRdAddrDel2((10 + URAMBLOCKS) downto (6 + URAMBLOCKS));
            else
                clearBlockUsed <= '0';
            end if;
            
        end if;
    end process;
    
    -- FIFO for the notifications of available packets.
    -- 13 bits wide, 16 entries deep
    -- bits(15:0) = destinationPort
    -- bits(20:16) = block start address in the buffer
    --
    
    fifoDin <= blockStartDel1 & destinationPort; -- 5 bit + 16 bit. 
    fifoWrEn <= updateBlockUsed;
    o_blockPortValid <= not fifoEmpty;
    
    xpm_fifo_sync_inst : xpm_fifo_sync
    generic map (
        DOUT_RESET_VALUE => "0",    -- String, Reset value of read data path.
        ECC_MODE => "no_ecc",       -- String, Allowed values: no_ecc, en_ecc.
        FIFO_MEMORY_TYPE => "distributed", -- String, Allowed values: auto, block, distributed. 
        FIFO_READ_LATENCY => 0,     -- Integer, Range: 0 - 10. Must be 0 for first READ_MODE = "fwft" (first word fall through).    
        FIFO_WRITE_DEPTH => 16,     -- Integer, Range: 16 - 4194304. Defines the FIFO Write Depth. Must be power of two.
        FULL_RESET_VALUE => 0,      -- Integer, Range: 0 - 1. Sets full, almost_full and prog_full to FULL_RESET_VALUE during reset
        PROG_EMPTY_THRESH => 10,    -- Integer, Range: 3 - 4194301.Specifies the minimum number of read words in the FIFO at or below which prog_empty is asserted.
        PROG_FULL_THRESH => 10,     -- Integer, Range: 5 - 4194301. Specifies the maximum number of write words in the FIFO at or above which prog_full is asserted.
        RD_DATA_COUNT_WIDTH => 1,   -- Integer, Range: 1 - 23. Specifies the width of rd_data_count. To reflect the correct value, the width should be log2(FIFO_READ_DEPTH)+1. FIFO_READ_DEPTH = FIFO_WRITE_DEPTH*WRITE_DATA_WIDTH/READ_DATA_WIDTH         
        READ_DATA_WIDTH => 21,      -- Integer, Range: 1 - 4096. Defines the width of the read data port, dout
        READ_MODE => "fwft",        -- String, Allowed values: std, fwft. Default value = std.
        --SIM_ASSERT_CHK => 0,        -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
        USE_ADV_FEATURES => "0000", -- String
        -- |---------------------------------------------------------------------------------------------------------------------|
        -- | Enables data_valid, almost_empty, rd_data_count, prog_empty, underflow, wr_ack, almost_full, wr_data_count,         |
        -- | prog_full, overflow features.                                                                                       |
        -- |                                                                                                                     |
        -- |   Setting USE_ADV_FEATURES[0] to 1 enables overflow flag;     Default value of this bit is 1                        |
        -- |   Setting USE_ADV_FEATURES[1]  to 1 enables prog_full flag;    Default value of this bit is 1                       |
        -- |   Setting USE_ADV_FEATURES[2]  to 1 enables wr_data_count;     Default value of this bit is 1                       |
        -- |   Setting USE_ADV_FEATURES[3]  to 1 enables almost_full flag;  Default value of this bit is 0                       |
        -- |   Setting USE_ADV_FEATURES[4]  to 1 enables wr_ack flag;       Default value of this bit is 0                       |
        -- |   Setting USE_ADV_FEATURES[8]  to 1 enables underflow flag;    Default value of this bit is 1                       |
        -- |   Setting USE_ADV_FEATURES[9]  to 1 enables prog_empty flag;   Default value of this bit is 1                       |
        -- |   Setting USE_ADV_FEATURES[10] to 1 enables rd_data_count;     Default value of this bit is 1                       |
        -- |   Setting USE_ADV_FEATURES[11] to 1 enables almost_empty flag; Default value of this bit is 0                       |
        -- |   Setting USE_ADV_FEATURES[12] to 1 enables data_valid flag;   Default value of this bit is 0                       |
        WAKEUP_TIME => 0,          -- Integer, Range: 0 - 2. 0 = Disable sleep 
        WRITE_DATA_WIDTH => 21,    -- Integer, Range: 1 - 4096. Defines the width of the write data port, din             
        WR_DATA_COUNT_WIDTH => 1   -- Integer, Range: 1 - 23. Specifies the width of wr_data_count. To reflect the correct value, the width should be log2(FIFO_WRITE_DEPTH)+1.   |
    )
    port map (
        almost_empty => open, -- 1-bit output: Almost Empty : When asserted, this signal indicates that only one more read can be performed before the FIFO goes to empty.
        almost_full => open,  -- 1-bit output: Almost Full: When asserted, this signal indicates that only one more write can be performed before the FIFO is full.
        data_valid => open,   -- 1-bit output: Read Data Valid: When asserted, this signal indicates that valid data is available on the output bus (dout).
        dbiterr => open,      -- 1-bit output: Double Bit Error: Indicates that the ECC decoder detected a double-bit error and data in the FIFO core is corrupted.
        dout => o_blockPort,  -- READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven when reading the FIFO.
        empty => fifoEmpty, -- 1-bit output: Empty Flag: When asserted, this signal indicates that
                            -- the FIFO is empty. Read requests are ignored when the FIFO is empty, initiating a read while empty is not destructive to the FIFO.
        full => fifoFull,   -- 1-bit output: Full Flag: When asserted, this signal indicates that the FIFO is full. Write requests are ignored when the FIFO is full,
                            -- initiating a write when the FIFO is full is not destructive to the contents of the FIFO.
        overflow => open,   -- 1-bit output: Overflow: This signal indicates that a write request (wren) during the prior clock cycle was rejected, because the FIFO is
                            -- full. Overflowing the FIFO is not destructive to the contents of the FIFO.
        prog_empty => open, -- 1-bit output: Programmable Empty: This signal is asserted when the number of words in the FIFO is less than or equal to the programmable
                            -- empty threshold value. It is de-asserted when the number of words in the FIFO exceeds the programmable empty threshold value.
        prog_full => open,  -- 1-bit output: Programmable Full: This signal is asserted when the number of words in the FIFO is greater than or equal to the
                            -- programmable full threshold value. It is de-asserted when the number of words in the FIFO is less than the programmable full threshold value.
        rd_data_count => open, -- RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates the number of words read from the FIFO.
        rd_rst_busy => open,   -- 1-bit output: Read Reset Busy: Active-High indicator that the FIFO read domain is currently in a reset state.
        sbiterr => open,           -- 1-bit output: Single Bit Error: Indicates that the ECC decoder detected and fixed a single-bit error.
        underflow => open,         -- 1-bit output: Underflow: Indicates that the read request (rd_en) during the previous clock cycle was rejected because the FIFO is empty. Under flowing the FIFO is not destructive to the FIFO.
        wr_ack => open,            -- 1-bit output: Write Acknowledge: This signal indicates that a write request (wr_en) during the prior clock cycle is succeeded.
        wr_data_count => open,     -- WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates the number of words written into the FIFO.
        wr_rst_busy => open,       -- 1-bit output: Write Reset Busy: Active-High indicator that the FIFO write domain is currently in a reset state.
        din => fifoDin,            -- WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when writing the FIFO.
        injectdbiterr => '0',      -- 1-bit input: Double Bit Error Injection: Injects a double bit error if the ECC feature is used on block RAMs or UltraRAM macros.
        injectsbiterr => '0',      -- 1-bit input: Single Bit Error Injection: Injects a single bit error if the ECC feature is used on block RAMs or UltraRAM macros.
        rd_en => i_blockPortRead,  -- 1-bit input: Read Enable: If the FIFO is not empty, asserting this signal causes data (on dout) to be read from the FIFO. Must be held active-low when rd_rst_busy is active high.
        rst => i_rst,              -- 1-bit input: Reset.
        sleep => '0',              -- 1-bit input: Dynamic power saving: If sleep is High, the memory/fifo block is in power saving mode.
        wr_clk => i_IC_clk,        -- 1-bit input: Write clock: Used for write operation. wr_clk must be a free running clock.
        wr_en => fifoWrEn          -- bit input: Write Enable: If the FIFO is not full, asserting this signal causes data (on din) to be written to the FIFO. Must be held active-low when rst or wr_rst_busy is active high.
    );
    
    ---------------------------------------------------------------------
    -- Capture and report error statistics
    
    process(i_IC_clk)
    begin
        if rising_edge(i_IC_clk) then
        
            if validDel2 = '1' and eofDel2 = '1' and FCSokDel2 = '0' and GENERATEFCS = '0' then
                oBadFCS <= '1';
            else
                oBadFCS <= '0';
            end if;
            
            if i_clrErrorCounts = '1' then
                AnyPacketDrops <= '0';
                packetDrops <= "000";
                AnyBadFCSs <= '0';
                badFCSs <= "000";
                AnyUnroutables <= '0';
                unroutables <= "000";
                AnyFifoFulls <= '0';
                fifoFulls <= "000";
            else
                if oPacketDrop = '1' then
                    anyPacketDrops <= '1';
                    packetDrops <= std_logic_vector(unsigned(packetDrops) + 1);
                end if;
                if obadFCS = '1' then
                    anyBadFCSs <= '1';
                    badFCSs <= std_logic_vector(unsigned(badFCSs) + 1);
                end if;
                if oUnroutable = '1' then
                    anyUnroutables <= '1';
                    unroutables <= std_logic_vector(unsigned(unroutables) + 1);
                end if;
                if ofifoFull = '1' then
                    anyFifoFulls <= '1';
                    fifoFulls <= std_logic_vector(unsigned(fifoFulls) + 1);
                end if;
            end if;
        end if;
    end process;
    
    o_errorCounts(15 downto 12) <= anyFifoFulls & fifoFulls;
    o_errorCounts(11 downto 8) <= AnyUnroutables & unroutables;
    o_errorCounts(7 downto 4) <= AnyBadFCSs & badFCSs;
    o_errorCounts(3 downto 0) <= anyPacketDrops & packetDrops;
    
    
end Behavioral;

