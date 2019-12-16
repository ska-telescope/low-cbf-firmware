----------------------------------------------------------------------------------
-- Company: CSIRO 
-- Engineer: David Humphrey (dave.humphrey@csiro.au)
-- 
-- Create Date: 18.07.2019
-- Module Name: IC_outputMux - Behavioral
-- 
-- Description 
-- -----------
--   Outputs data from a selected input port to a 25GE debug port.
--   This is similar to the IC_outputMux components, but instead of responding to notifications and issuing requests, 
--   this module just watches for any packets from a particular input port in the interconnect.
--   The input port that is being watched is selectable via MACE. 
--   Because 25GE has more overhead than the other 25G links, a FIFO is used to ensure we can send back-to-back packets.
--   The packets generated have the following headers attached :
--     Ethernet
--       Destination MAC  : 6 bytes
--       Source MAC       : 6 bytes
--       Ethertype        : 0x0800   (i.e. IPv4)
--     IPv4 Header fields (20 bytes)
--       first 2 bytes          : 0x45, 0x00
--       Total length (2 bytes) : 20 (IPv4 header) + 8 (UDP header) + 14 (dbgMux header, see below) + [whatever the actual packet length is]
--                                = 44 + [packet length]
--       identification         : 0x0000
--       flags and fragment     : 0x0000
--       time to live           : 0x7F
--       protocol               : 0x11  (i.e. UDP)
--       Header checksum        : 2 bytes, calculated based on other fields.
--       Source IP              : DHCP assigned IP address used by MACE.
--       Destination IP         : 192.168.1.7    (Programmable)
--     UDP header fields (8 bytes)
--       source port            : 0x1234
--       destination port       : 0x5678
--       Length (2 bytes)       : 8 (UDP header) + 14 (dbgMux header) + [packet length]
--                                = 24 + packet length
--       checksum               : 2 bytes, calculated based on the other fields.
--     dbgMux Header (14 bytes, takes us to a multiple of 8 bytes for the header)
--       myAddr                 : 2 bytes (actually 12 bits, top four bits added as 0x0, from the input i_myAddr)
--       interconnect port the packet came from          : 1 byte (5 bits used)
--       interconnect port the packet was being sent to  : 1 byte (5 bits used)
--       sequence number        : 2 bytes. Can be used to detect skipped packets.
--       
--
-- "PORTSUSED"
-- -------
--  The generic PORTSUSED allows for ports to be masked out of the output multiplexer in order to save resources.
--  
-- Addressing
-- ----------
--  After the Ethernet, IPv4, UDP and dbgMux headers, packets are sent to the 25GE port
--  as received. This means they include the internal addressing information  
--  in the first (64 bit) word :
--
--   DEST    SRC1     SRC2    SRC3     PacketTYPE
-- (63:52)  (51:40)  (39:28) (27:16)  (15:8)
-- 
-- Each address (DEST, SRC1, SRC2, SRC3) is made up of 
--  (11:8) = Y coordinate
--  (7:4) = X coordinate
--  (3:0) = Z coordinate
--
-- Structure
-- ---------
-- 
--  data in   -> buffer (4xBRAMs) -> Readout FSM --> output FIFO --> 25GE interface  
--             \-> BUF FIFO      -/ Read address
--                                     |
--  Write FSM <- clock crossing -------+
--
--  * The buffer is used as a fifo for the packet data, to allow back to back frames to be sent, even though the 25GE needs extra data inserted.
--  * The "Buf FIFO" tells the readout FSM the address of a packet in the buffer
--  * The read address is fed back to the write FSM via an XPM clock crossing
--  * The output FIFO is needed to allow the 25GE interface to stall the data.
--
----------------------------------------------------------------------------------

library common_lib, axi4_lib;
use common_lib.common_pkg.all;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
Library xpm;
use xpm.vcomponents.all;
USE axi4_lib.axi4_stream_pkg.ALL;

entity IC_dbgMux is
    generic(
        -- PortsUsed allows input side ports to be masked out from the multiplexer to save resources. 
        -- Set bits to 0 to mask a port.
        PORTSUSED : std_logic_vector(31 downto 0) := x"ffffffff"
    );
    port(
        -- Input data is on this clock (about 400 MHz)
        i_IC_clk : in std_logic;
        i_rst : in std_logic;
        --------------------------------------------
        -- Configuration information on i_IC_clk
        i_myAddr : in std_logic_vector(11 downto 0);  -- X,Y and Z coordinates of this FPGA in the array, used for routing.
        -- Data selection logic :
        --  if i_dataSelSelSrc = '0' then
        --     use data from the input port specified by "i_dataSel"
        --  else
        --     use data going to the output port "i_dataSel"
        --     Note the input port that is going to the output port "i_dataSel" is "i_port(i_dataSel)"
        i_dataSel : in std_logic_vector(4 downto 0);  -- port to dump data from.
        i_dataSelIsOutput : in std_logic;             -- '0' to use input port i_dataSel, otherwise use input port i_port(i_dataSel) 
        i_port  : in t_slv_5_arr(31 downto 0);     -- The input port that data is being requested from for each destination port
        i_destIP : in std_logic_vector(31 downto 0);  -- destination IP address to use.
        i_srcMAC : in std_logic_vector(47 downto 0);  -- Source MAC address for the debug packets
        i_destMAC : in std_logic_vector(47 downto 0); -- Destination MAC address for the debug packets
        -- Configuration information on some other clock
        i_ipAddr : in std_logic_vector(31 downto 0);
        i_ipAddrClk : in std_logic;
        -- Packet Data being streamed out by the input side modules. i_dataSel chooses which port we are listening to. 
        i_packetData  : in t_slv_64_arr(31 downto 0);      -- 
        i_packetOutputMux : in t_slv_5_arr(31 downto 0);   -- Destination output MUX for this packet (i.e. send the packet through this module if i_packetOutputMux = OUTPUTMUX).
        i_packetValid : in std_logic_vector(31 downto 0);
        -- 25 GE debug port (output of the interconnect module)
        o_dbg25GE : out t_axi4_sosi;   -- Note that the valid signal should be high for the entire packet (only the core can stall).
        i_dbg25GE : in  t_axi4_siso;
        i_dbg25GE_clk : in std_logic;
        -- Status
        i_clrErrorCounts : in std_logic;
        o_errCounts : out std_logic_vector(7 downto 0)  -- (7:0) = Dropped packets. Counter wraps but bit(7) is sticky.
    );
end IC_dbgMux;

architecture Behavioral of IC_dbgMux is

    type rd_fsm_type is (idle, sendDMAC, sendSMAC, sendIPv4, sendIPv4Checksum, sendUDP, sendDbgHdr, sendData, waitFinalFifo);
    signal rd_fsm, rd_fsmDel1, rd_fsmDel2 : rd_fsm_type := idle;

    type wr_fsm_type is (idle, wrPacket, dropPacket);
    signal wr_fsm : wr_fsm_type := idle;

    signal selectedPacketData : std_logic_vector(63 downto 0);
    signal maskedPacketData : t_slv_64_arr(31 downto 0);
    signal maskedOutputMux : t_slv_5_arr(31 downto 0);
    signal maskedValid : std_logic_vector(31 downto 0);
    
    signal maskedPacketData7_0, maskedPacketData15_8, maskedPacketData23_16, maskedPacketData31_24 : t_slv_64_arr(7 downto 0);
    signal maskedOutputMux7_0, maskedOutputMux15_8, maskedOutputMux23_16, maskedOutputMux31_24 : t_slv_5_arr(7 downto 0);
    signal maskedValid7_0, maskedValid15_8, maskedValid23_16, maskedValid31_24 : std_logic_vector(7 downto 0); 
    
    signal dataSel20 : std_logic_vector(2 downto 0);
    signal dataSel43 : std_logic_vector(1 downto 0);
    
    signal packetData7_0, packetData15_8, packetData23_16, packetData31_24 : std_logic_vector(63 downto 0);
    signal outputMux7_0, outputMux15_8, outputMux23_16, outputMux31_24 : std_logic_vector(4 downto 0);
    signal valid7_0, valid15_8, valid23_16, valid31_24 : std_logic;
    
    signal spaceAvailable : std_logic := '0';
    signal fifoSpaceUsed : std_logic_vector(10 downto 0);
    signal fifoWrAddr, fifoWrAddrStart, fifoRdAddr, fifoRdAddr_ICclk_cap : std_logic_vector(10 downto 0);
    signal fifoRdAddr_ICclk : std_logic_vector(10 downto 0);
    signal fifoWrEn : std_logic;
    signal fifoWrData, fifoRdData : std_logic_vector(63 downto 0);
    signal fifoRdAddr_ICclk_valid : std_logic;
    
    signal infoFifoAlmostFull : std_logic;
    signal infoFifoWrEn : std_logic := '0';
    signal infoFifoWrData : std_logic_vector(49 downto 0);
    signal infoFifoDout : std_logic_vector(49 downto 0);
    signal infoFifoEmpty : std_logic;
    signal infoFifoRd : std_logic;
    
    signal packetData : std_logic_vector(63 downto 0);
    signal outputMux, outputMuxDel : std_logic_vector(4 downto 0);
    signal valid, validDel1 : std_logic;
    
    signal fifoWrEn_slv : std_logic_vector(0 downto 0);
    signal sequenceNo : std_logic_vector(15 downto 0) := x"0000";
    
    signal fifoRdAddr_send : std_logic;
    signal fifoRdAddr_src_rcv : std_logic;
    signal srcIPAddr, srcIPAddr_25GEclk : std_logic_vector(31 downto 0);
    signal ipAddr_send : std_logic;
    signal srcIPAddr_src_rcv : std_logic;
    signal srcIPAddr_25GEclk_valid : std_logic;
    
    signal destIPAddr : std_logic_vector(31 downto 0);
    signal myAddr : std_logic_vector(11 downto 0);
    signal destIPAddr_25GEClk_valid : std_logic := '0';
    signal destmyAddrIPAddr_25GEclk : std_logic_vector(139 downto 0);
    signal destIPAddr_src_rcv : std_logic := '0';
    signal destipAddr_send : std_logic := '0';
    
    signal srcIPAddr0, srcIPAddr1, destIPAddr0, destIPAddr1, IPchecksum1_low, IPchecksum1_high, IPchecksum2_low, IPchecksum2_high : std_logic_vector(19 downto 0);
    signal IPchecksum0, IPchecksum1, IPchecksum2, IPchecksum3, staticIPHdrSum : std_logic_vector(19 downto 0);
    
    signal fifoRdLength : std_logic_vector(10 downto 0);
    signal fifoLastAddr : std_logic_vector(10 downto 0);
    
    signal sequenceOut : std_logic_vector(15 downto 0);
    signal outputMuxOut : std_logic_vector(4 downto 0);
    signal lengthBytes, IPTotalLength, UDPTotalLength : std_logic_vector(19 downto 0);
    
    signal finalFifoRdData : std_logic_vector(64 downto 0);
    signal finalFifoEmpty : std_logic;
    signal finalFifoFull : std_logic;
    signal finalFifoDin : std_logic_vector(64 downto 0);
    signal finalFifoRdEn : std_logic;
    signal finalFifoWrEn : std_logic;
    signal finalFifoWrSize : std_logic_vector(5 downto 0);
    signal destIP_myAddr : std_logic_vector(139 downto 0);
    signal inputSel : std_logic_vector(4 downto 0);
    signal setLast, setLastDel1, setLastDel2 : std_logic;
    signal infoFifoRdCount, infoFifoWrCount : std_logic_vector(5 downto 0);
    signal AnyError : std_logic;
    signal ErrorCount : std_logic_vector(6 downto 0);
    signal dbg25GE_rst, dbg25GE_rst_del1 : std_logic;
    
    signal destMAC : std_logic_vector(47 downto 0);
    signal srcMAC : std_logic_vector(47 downto 0);
    signal dataSel : std_logic_vector(4 downto 0);
    
begin
    
    ------------------------------------------------------------------------
    -- FIFO for input packets.
    -- Implemented in block RAM.
    -- The FIFO has two purposes :
    --  1. So we know the length of the packet before we send it, since length is needed in the IPv4 and UDP headers.
    --  2. To allow back-to-back packets to be sent, even though the Ethernet headers take up some extra time.
    -- We need space for 2 Jumbo frames = about 16384 bytes.
    -- So use 4 BRAMs. (Sized as 2048 deep x 64 bits wide).
    -- The memory is dual clock, since the 25GE clock is asynchronous to the interconnect clock. 
    -- There still needs to be a small FIFO on the output to handle stalls by the ethernet core. 
    -- 
    -- When a packet comes in,
    --  - It is written to the BRAM. 
    --  - If we run out of space in the BRAM the packet is discarded.
    --  - Once the packet is written, an entry is written to a FIFO to indicate that the packet can be read out and forwarded to the 25GE interface.
    --
    
    
    -- Mask out any unused ports to save resources, then use two pipeline stages to select the port we are listening to.
    maskGen: for i in 0 to 31 generate
        maskedPacketData(i) <= i_packetData(i) when PORTSUSED(i) = '1' else (others => '0');
        maskedOutputMux(i) <= i_packetOutputMux(i) when PORTSUSED(i) = '1' else (others => '0');
        maskedValid(i) <= i_packetValid(i) when PORTSUSED(i) = '1' else '0';
    end generate;
    
    maskedPacketData7_0 <= maskedPacketData(7 downto 0);
    maskedPacketData15_8 <= maskedPacketData(15 downto 8);
    maskedPacketData23_16 <= maskedPacketData(23 downto 16);
    maskedPacketData31_24 <= maskedPacketData(31 downto 24);
    
    maskedOutputMux7_0 <= maskedOutputMux(7 downto 0);
    maskedOutputMux15_8 <= maskedOutputMux(15 downto 8);
    maskedOutputMux23_16 <= maskedOutputMux(23 downto 16);
    maskedOutputMux31_24 <= maskedOutputMux(31 downto 24);
    
    maskedValid7_0 <= maskedValid(7 downto 0);
    maskedValid15_8 <= maskedValid(15 downto 8);
    maskedValid23_16 <= maskedValid(23 downto 16);
    maskedValid31_24 <= maskedValid(31 downto 24);    
    
    process(i_IC_clk)
    begin
        if rising_edge(i_IC_clk) then
            
            -- i_dataSel either selects the input port, or the output port.
            if i_dataSelIsOutput = '0' then
                dataSel <= i_dataSel;
            else
                -- when using the output port, select the input port that the output port is currently requesting.
                dataSel <= i_port(to_integer(unsigned(i_dataSel)));
            end if;
        
            -- Select the bus currently in use
            dataSel20(2 downto 0) <= dataSel(2 downto 0);
            dataSel43(1 downto 0) <= dataSel(4 downto 3);
            
            packetData7_0 <= maskedPacketData7_0(to_integer(unsigned(dataSel20)));
            packetData15_8 <= maskedPacketData15_8(to_integer(unsigned(dataSel20)));
            packetData23_16 <= maskedPacketData23_16(to_integer(unsigned(dataSel20)));
            packetData31_24 <= maskedPacketData31_24(to_integer(unsigned(dataSel20)));
            
            outputMux7_0 <= maskedOutputMux7_0(to_integer(unsigned(dataSel20)));
            outputMux15_8 <= maskedOutputMux15_8(to_integer(unsigned(dataSel20)));
            outputMux23_16 <= maskedOutputMux23_16(to_integer(unsigned(dataSel20)));
            outputMux31_24 <= maskedOutputMux31_24(to_integer(unsigned(dataSel20)));
            
            valid7_0 <= maskedValid7_0(to_integer(unsigned(dataSel20)));
            valid15_8 <= maskedValid15_8(to_integer(unsigned(dataSel20)));
            valid23_16 <= maskedValid23_16(to_integer(unsigned(dataSel20)));
            valid31_24 <= maskedValid31_24(to_integer(unsigned(dataSel20)));
            
            case dataSel43 is
                when "00" => 
                    packetData <= packetData7_0;
                    outputMux <= outputMux7_0;
                    valid <= valid7_0;
                when "01" => 
                    packetData <= packetData15_8;
                    outputMux <= outputMux15_8;
                    valid <= valid15_8;
                when "10" => 
                    packetData <= packetData23_16;
                    outputMux <= outputMux23_16;
                    valid <= valid23_16;
                when others => 
                    packetData <= packetData31_24;
                    outputMux <= outputMux31_24;
                    valid <= valid31_24;
            end case;
            
            -------------------------------------------------------------------
            -- State machine to write to the memory.
            --  - Only starts writing on a rising edge of valid.
            --  - Only writes if there is sufficient space in the buffer.
            --  - Discards the packet by resetting the write pointer if it overflows the buffer.
            --  - Puts data into the FIFO to notify the read side that a packet is ready.
            --
            -- Fifo management :
            --  On the write side, we always stop before the write address hits the read address.
            --  So if the read and write address are the same, then the FIFO is empty.
            
            if fifoRdAddr_ICclk_valid = '1' then
                fifoRdAddr_ICclk_cap <= fifoRdAddr_ICclk;
            end if;
            
            FifoSpaceUsed <= std_logic_vector(unsigned(fifoWrAddr) - unsigned(fifoRdAddr_ICclk_cap));
            if (unsigned(FifoSpaceUsed) <  1792) then
                spaceAvailable <= '1';
            else
                spaceAvailable <= '0';
            end if;
            
            validDel1 <= valid;
            
            if valid = '1' and validDel1 = '0' then
                sequenceNo <= std_logic_vector(unsigned(sequenceNo) + 1);
            end if;
            
            if i_rst = '1' then
                wr_fsm <= idle;
                infoFifoWrEn <= '0';
                fifoWrAddr <= (others => '0');
                fifoWrAddrStart <= (others => '0');
            else
                case wr_fsm is
                    when idle =>
                        if valid = '1' and validDel1 = '0' then
                            if validDel1 = '0' and spaceAvailable = '1' and infoFifoAlmostFull = '0' then
                                wr_fsm <= wrPacket;
                                fifoWrEn <= '1';
                                outputMuxDel <= outputMux;
                            else
                                wr_fsm <= dropPacket;
                                fifoWrEn <= '0';
                            end if;
                        end if;
                        infoFifoWrEn <= '0';
                        fifoWrAddrStart <= fifoWrAddr;
                    
                    when dropPacket =>
                        infoFifoWrEn <= '0';
                        wr_fsm <= idle;
                    
                    when wrPacket =>
                        if spaceAvailable = '0' then
                            -- Ran out of space in the fifo, so drop the packet. 
                            fifoWrEn <= '0';
                            fifoWrAddr <= fifoWrAddrStart; -- Rewind to the write pointer to the start of the packet.
                            wr_fsm <= idle;
                            infoFifoWrEn <= '0';
                        else
                            fifoWrAddr <= std_logic_vector(unsigned(fifoWrAddr) + 1);
                            if valid = '0' then
                                fifoWrEn <= '0';
                                infoFifoWrEn <= '1';  -- write sequence number, start address and length to the info fifo to notify the read side that a packet is ready.
                                infoFifoWrData(49 downto 45) <= dataSel; -- interconnect input port
                                infoFifoWrData(44 downto 40) <= outputMuxDel; -- output MUX
                                infoFifoWrData(39 downto 24) <= sequenceNo;
                                infoFifoWrData(23) <= '0';
                                infoFifoWrData(22 downto 12) <= std_logic_vector(unsigned(fifoWrAddr) - unsigned(fifoWrAddrStart) + 1); -- length of the packet (in 64 bit words)
                                infoFifoWrData(11) <= '0';
                                infoFifoWrData(10 downto 0) <= fifoWrAddrStart;  -- start address of the packet 
                                wr_fsm <= idle;
                            else
                                fifoWrEn <= '1';
                                infoFifoWrEn <= '0';
                            end if;
                        end if;
                        
                    when others =>
                        wr_fsm <= idle;
                end case;
            end if;
            
            fifoWrData <= packetData; -- fifoWrData will align with fifoWrEn
            
            if i_clrErrorCounts = '1' then
                anyError <= '0';
                errorCount <= (others => '0');
            elsif wr_fsm = dropPacket then
                if errorCount = "1111111" then
                    anyError <= '1';
                end if;
                errorCount <= std_logic_vector(unsigned(errorCount) + 1);
            end if;
            o_errCounts <= anyError & errorCount;
        end if;
    end process;
    
    -- BRAM buffer memory
    -- 2048 x 64 bits.
    xpm_memory_sdpram_inst : xpm_memory_sdpram
    generic map (
        ADDR_WIDTH_A => 11,               -- DECIMAL
        ADDR_WIDTH_B => 11,               -- DECIMAL
        AUTO_SLEEP_TIME => 0,            -- DECIMAL
        BYTE_WRITE_WIDTH_A => 64,        -- DECIMAL, same as data width for single bit
        CLOCKING_MODE => "independent_clock", -- String
        ECC_MODE => "no_ecc",            -- String
        MEMORY_INIT_FILE => "none",      -- String
        MEMORY_INIT_PARAM => "0",        -- String
        MEMORY_OPTIMIZATION => "true",   -- String
        MEMORY_PRIMITIVE => "auto",      -- String
        MEMORY_SIZE => 131072,           -- DECIMAL, in total bits, so 64 * 2048 = 2^17
        MESSAGE_CONTROL => 0,            -- DECIMAL
        READ_DATA_WIDTH_B => 64,         -- DECIMAL
        READ_LATENCY_B => 2,             -- DECIMAL
        READ_RESET_VALUE_B => "0",       -- String
        RST_MODE_A => "SYNC",            -- String
        RST_MODE_B => "SYNC",            -- String
        USE_EMBEDDED_CONSTRAINT => 0,    -- DECIMAL
        USE_MEM_INIT => 0,               -- DECIMAL
        WAKEUP_TIME => "disable_sleep",  -- String
        WRITE_DATA_WIDTH_A => 64,        -- DECIMAL
        WRITE_MODE_B => "no_change"      -- String
    )
    port map (
        dbiterrb => open,      -- 1-bit output: Status signal to indicate double bit error occurrence on the data output of port B.
        doutb => fifoRdData,   -- READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
        sbiterrb => open,      -- 1-bit output: Status signal to indicate single bit error occurrence on the data output of port B.
        addra => fifoWrAddr,   -- ADDR_WIDTH_A-bit input: Address for port A write operations.
        addrb => fifoRdAddr,   -- ADDR_WIDTH_B-bit input: Address for port B read operations.
        clka => i_IC_clk,      -- 1-bit input: Clock signal for port A. 
        clkb => i_dbg25GE_clk, -- 1-bit input: Clock signal for port B.
        dina => fifoWrData,    -- WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
        ena => '1',            -- 1-bit input: Memory enable signal for port A. Must be high on clock cycles when write operations are initiated.
        enb => '1',            -- 1-bit input: Memory enable signal for port B. Must be high on clock cycles when read operations are initiated.
        injectdbiterra => '0', -- 1-bit input: Controls double bit error injection on input data.
        injectsbiterra => '0', -- 1 bit input: Controls single bit error injection on input data.
        regceb => '1',         -- 1-bit input: Clock Enable for the last register stage on the output data path.
        rstb => '0',           -- 1-bit input: Reset signal for the final port B output register stage.
        sleep => '0',          -- 1-bit input: sleep signal to enable the dynamic power saving feature.
        wea => fifoWrEn_slv        -- WRITE_DATA_WIDTH_A-bit input: Write enable vector for port A input data port dina. 1 bit wide when word-wide writes are used.
    );
    fifoWrEn_slv(0) <= fifoWrEn;
    
    -- FIFO to notify the read side that a packet is available in the BRAM buffer
    -- FIFO data is : 
    --  11:0  = Start address in the BRAM buffer (12 bits, max is 2047).
    --  23:12 = Length of the packet (12 bits).
    --  39:24 = Sequence number.
    --  44:40 = output Mux.
    --  49:45 = interconnect input port.
    infoFifo_inst : xpm_fifo_async
    generic map (
        CDC_SYNC_STAGES => 2,       -- DECIMAL
        DOUT_RESET_VALUE => "0",    -- String
        ECC_MODE => "no_ecc",       -- String
        FIFO_MEMORY_TYPE => "distributed", -- String, Allowed values: auto, block, distributed. 
        FIFO_READ_LATENCY => 0,     -- DECIMAL
        FIFO_WRITE_DEPTH => 32,     -- DECIMAL
        FULL_RESET_VALUE => 0,      -- DECIMAL
        PROG_EMPTY_THRESH => 10,    -- DECIMAL
        PROG_FULL_THRESH => 10,     -- DECIMAL
        RD_DATA_COUNT_WIDTH => 6,   -- DECIMAL
        READ_DATA_WIDTH => 50,      -- DECIMAL
        READ_MODE => "fwft",        -- String
        RELATED_CLOCKS => 0,        -- DECIMAL
        USE_ADV_FEATURES => "0707", -- String
        WAKEUP_TIME => 0,           -- DECIMAL
        WRITE_DATA_WIDTH => 50,     -- DECIMAL
        WR_DATA_COUNT_WIDTH => 6    -- DECIMAL
    )
    port map (
        almost_empty => open,   -- 1-bit output: Almost Empty : When asserted, this signal indicates that only one more read can be performed before the FIFO goes to empty.
        almost_full => infoFifoAlmostFull, -- 1-bit output: Almost Full: When asserted, this signal indicates that only one more write can be performed before the FIFO is full.
        data_valid => open,             -- 1-bit output: Read Data Valid: When asserted, this signal indicates that valid data is available on the output bus (dout).
        dbiterr => open,                -- 1-bit output: Double Bit Error:
        dout => infoFifoDout,           -- READ_DATA_WIDTH-bit output: Read Data
        empty => infoFifoEmpty,         -- 1-bit output: Empty Flag
        full => open,                   -- 1-bit output: Full Flag
        overflow => open,               -- 1-bit output: Overflow: This signal indicates that a write request (wren) during the prior clock cycle was rejected, because the FIFO is full. Overflowing the FIFO is not destructive to the contents of the FIFO.
        prog_empty => open,             -- 1-bit output: Programmable Empty: This signal is asserted when the number of words in the FIFO is less than or equal to the programmable.
        prog_full => open,              -- 1-bit output: Programmable Full: This signal is asserted when the number of words in the FIFO is greater than or equal to the programmable full threshold value.
        rd_data_count => infoFifoRdCount, -- RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates the number of words read from the FIFO.
        rd_rst_busy => open,            -- 1-bit output: Read Reset Busy: Active-High indicator that the FIFO read domain is currently in a reset state.
        sbiterr => open,                -- 1-bit output: Single Bit Error: Indicates that the ECC decoder detected and fixed a single-bit error.
        underflow => open,              -- 1-bit output: Underflow: Indicates that the read request (rd_en) during the previous clock cycle was rejected because the FIFO is empty. Under flowing the FIFO is not destructive to the FIFO.
        wr_ack => open,                 -- 1-bit output: Write Acknowledge
        wr_data_count => infoFifoWrCount, -- WR_DATA_COUNT_WIDTH-bit output: Write Data Count
        wr_rst_busy => open,            -- 1-bit output: Write Reset Busy
        din => infoFifoWrData,          -- WRITE_DATA_WIDTH-bit input: Write Data
        injectdbiterr => '0',           -- 1-bit input: Double Bit Error Injection
        injectsbiterr => '0',           -- 1-bit input: Single Bit Error Injection
        rd_clk => i_dbg25GE_clk,        -- 1-bit input: Read clock
        rd_en => infoFifoRd,            -- 1-bit input: Read Enable: 
        rst => '0',                     -- 1-bit input: Reset: Must be synchronous to wr_clk.
        sleep => '0',                   -- 1-bit input: Dynamic power saving
        wr_clk => i_IC_clk,             -- 1-bit input: Write clock:
        wr_en => infoFifoWrEn           -- 1-bit input: Write Enable:
    );
 
    
    
    -- Pass the current read address of the BRAM buffer back to the write side so it knows not to overflow the buffer.
    -- Cross the clock domains.
    xpm_cdc_handshake_inst1 : xpm_cdc_handshake
    generic map (
       DEST_EXT_HSK => 0,   -- DECIMAL; 0=internal handshake, 1=external handshake
       DEST_SYNC_FF => 4,   -- DECIMAL; range: 2-10
       INIT_SYNC_FF => 0,   -- DECIMAL; 0=disable simulation init values, 1=enable simulation init values
       SIM_ASSERT_CHK => 0, -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
       SRC_SYNC_FF => 4,    -- DECIMAL; range: 2-10
       WIDTH => 11          -- DECIMAL; range: 1-1024
    )
    port map (
        dest_out => fifoRdAddr_ICclk, -- WIDTH-bit output: Input bus (src_in) synchronized to destination clock domain. This output is registered.
        dest_req => fifoRdAddr_ICclk_valid, -- 1-bit output: Assertion of this signal indicates that new dest_out data is ready. When DEST_EXT_HSK = 0, this signal asserts for one clock when dest_out bus is valid. This output is registered.
        src_rcv => fifoRdAddr_src_rcv,   -- 1-bit output: Acknowledgement from destination logic that src_in has been received. This signal will be deasserted once destination handshake has fully completed, thus completing a full data transfer. This output is registered.
        dest_ack => '1', -- 1-bit input: optional; required when DEST_EXT_HSK = 1
        dest_clk => i_IC_clk,        -- 1-bit input: Destination clock.
        src_clk => i_dbg25GE_clk,    -- 1-bit input: Source clock.
        src_in => fifoRdAddr,        -- WIDTH-bit input: Input bus that will be synchronized to the destination clock domain.
        src_send => fifoRdAddr_send  -- 1-bit input: Assertion of this signal allows the src_in bus to be synchronized to the destination clock domain.
                                     -- assert when src_rcv is deasserted, deassert once src_rcv is asserted.
    );
    
    -- Get the DHCP provided source IP address into the i_dbg25GE clock domain
    process(i_ipAddrClk)
    begin
        if rising_edge(i_ipAddrClk) then
            -- Transfer the buffer read address as often as possible 
            if srcIPAddr_src_rcv = '0' then
                ipAddr_send <= '1';
            elsif srcIPAddr_src_rcv = '1' then
                ipAddr_send <= '0';
            end if;
        end if;
    end process;    

    xpm_cdc_handshake_inst2 : xpm_cdc_handshake
    generic map (
       DEST_EXT_HSK => 0,   -- DECIMAL; 0=internal handshake, 1=external handshake
       DEST_SYNC_FF => 4,   -- DECIMAL; range: 2-10
       INIT_SYNC_FF => 0,   -- DECIMAL; 0=disable simulation init values, 1=enable simulation init values
       SIM_ASSERT_CHK => 0, -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
       SRC_SYNC_FF => 4,    -- DECIMAL; range: 2-10
       WIDTH => 32          -- DECIMAL; range: 1-1024
    )
    port map (
        dest_out => srcIPAddr_25GEclk,       -- WIDTH-bit output: Input bus (src_in) synchronized to destination clock domain. This output is registered.
        dest_req => srcIPAddr_25GEclk_valid, -- 1-bit output: Assertion of this signal indicates that new dest_out data is ready. When DEST_EXT_HSK = 0, this signal asserts for one clock when dest_out bus is valid. This output is registered.
        src_rcv => srcIPAddr_src_rcv,        -- 1-bit output: Acknowledgement from destination logic that src_in has been received. This signal will be deasserted once destination handshake has fully completed, thus completing a full data transfer. This output is registered.
        dest_ack => '1',                     -- 1-bit input: optional; required when DEST_EXT_HSK = 1
        dest_clk => i_dbg25GE_clk,           -- 1-bit input: Destination clock.
        src_clk => i_ipAddrClk,      -- 1-bit input: Source clock.
        src_in => i_ipAddr,          -- WIDTH-bit input: Input bus that will be synchronized to the destination clock domain.
        src_send => ipAddr_send      -- 1-bit input: Assertion of this signal allows the src_in bus to be synchronized to the destination clock domain.
                                     -- assert when src_rcv is deasserted, deassert once src_rcv is asserted.
    );
    
    -- Get the destination IP address into the i_dbg25GE clock domain
    process(i_IC_clk)
    begin
        if rising_edge(i_IC_clk) then
            -- Transfer the buffer read address as often as possible 
            if destIPAddr_src_rcv = '0' then
                destipAddr_send <= '1';
            elsif destIPAddr_src_rcv = '1' then
                destipAddr_send <= '0';
            end if;
            destIP_myAddr <= i_destMAC & i_srcMAC & i_myAddr & i_destIP;
        end if;
    end process;

    xpm_cdc_handshake_inst3 : xpm_cdc_handshake
    generic map (
       DEST_EXT_HSK => 0,   -- DECIMAL; 0=internal handshake, 1=external handshake
       DEST_SYNC_FF => 4,   -- DECIMAL; range: 2-10
       INIT_SYNC_FF => 0,   -- DECIMAL; 0=disable simulation init values, 1=enable simulation init values
       SIM_ASSERT_CHK => 0, -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
       SRC_SYNC_FF => 4,    -- DECIMAL; range: 2-10
       WIDTH => 140         -- DECIMAL; range: 1-1024
    )
    port map (
        dest_out => destmyAddrIPAddr_25GEclk,       -- WIDTH-bit output: Input bus (src_in) synchronized to destination clock domain. This output is registered.
        dest_req => destIPAddr_25GEclk_valid, -- 1-bit output: Assertion of this signal indicates that new dest_out data is ready. When DEST_EXT_HSK = 0, this signal asserts for one clock when dest_out bus is valid. This output is registered.
        src_rcv => destIPAddr_src_rcv,        -- 1-bit output: Acknowledgement from destination logic that src_in has been received. This signal will be deasserted once destination handshake has fully completed, thus completing a full data transfer. This output is registered.
        dest_ack => '1',                      -- 1-bit input: optional; required when DEST_EXT_HSK = 1
        dest_clk => i_dbg25GE_clk,            -- 1-bit input: Destination clock.
        src_clk => i_IC_clk,                  -- 1-bit input: Source clock.
        src_in => destIP_myAddr,              -- WIDTH-bit input: Input bus that will be synchronized to the destination clock domain.
        src_send => destIPAddr_send           -- 1-bit input: Assertion of this signal allows the src_in bus to be synchronized to the destination clock domain.
                                              -- assert when src_rcv is deasserted, deassert once src_rcv is asserted.
    );
    
    -- transfer reset to the 25GE clock domain
    xpm_cdc_rst_inst : xpm_cdc_pulse
    generic map (
        DEST_SYNC_FF => 4,   -- DECIMAL; range: 2-10
        INIT_SYNC_FF => 1,   -- DECIMAL; 0=disable simulation init values, 1=enable simulation init values
        REG_OUTPUT => 1,     -- DECIMAL; 0=disable registered output, 1=enable registered output
        RST_USED => 0,       -- DECIMAL; 0=no reset, 1=implement reset
        SIM_ASSERT_CHK => 0  -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    )
    port map (
        dest_pulse => dbg25GE_rst, -- 1-bit output: Outputs a pulse the size of one dest_clk period when a pulse transfer is correctly initiated on src_pulse input.
        dest_clk => i_dbg25GE_clk, -- 1-bit input: Destination clock.
        dest_rst => '0',           -- 1-bit input: optional; required when RST_USED = 1
        src_clk => i_IC_clk,       -- 1-bit input: Source clock.
        src_pulse => i_rst,       -- 1-bit input: Rising edge of this signal initiates a pulse transfer to the destination clock domain.
        src_rst => '0'          -- 1-bit input: optional; required when RST_USED = 1
    );
    
    
    process(i_dbg25GE_clk)
    begin
        if rising_edge(i_dbg25GE_clk) then
            -- Transfer the buffer read address as often as possible 
            dbg25GE_rst_del1 <= dbg25GE_rst;
            if dbg25GE_rst_del1 = '1' then
                fifoRdAddr_send <= '0';
            elsif fifoRdAddr_src_rcv = '0' then
                fifoRdAddr_send <= '1';
            elsif fifoRdAddr_src_rcv = '1' then
                fifoRdAddr_send <= '0';
            end if;
            
            -- capture the src and dest IP addresses from the clock crossings.
            if srcIPAddr_25GEclk_valid = '1' then
                srcIPAddr <= srcIPAddr_25GEclk;
            end if;
            
            if destIPAddr_25GEclk_valid = '1' then
                destMAC <= destmyAddrIpAddr_25GEclk(139 downto 92);
                srcMAC <= destmyAddrIpAddr_25GEclk(91 downto 44);
                myAddr <= destmyAddrIpAddr_25GEclk(43 downto 32);  -- 12 bit address of this FPGA
                destIPAddr <= destmyAddrIpAddr_25GEclk(31 downto 0); -- Destination IP address to use.
            end if;
            
            if dbg25GE_rst = '1' then
                rd_fsm <= idle;
                fifoRdAddr <= (others => '0');
                fifoRdLength <= (others => '0');
                sequenceOut <= (others => '0');
                outputMuxOut <= (others => '0');
                inputSel <= (others => '0');
                infoFifoRd <= '0';
                setLast <= '0';
            else
                case rd_fsm is
                    when idle =>
                        if (infoFifoEmpty = '0' and (unsigned(finalFifoWrSize) < 8)) then
                            fifoRdAddr <= infoFifoDout(10 downto 0);
                            fifoRdLength <= infoFifoDout(22 downto 12);
                            sequenceOut <= infoFifoDout(39 downto 24);
                            outputMuxOut <= infoFifoDout(44 downto 40);
                            inputSel <= infoFiFoDout(49 downto 45);
                            rd_fsm <= sendDMAC;
                        end if;
                        infoFifoRd <= '0';
                        setLast <= '0';
                        
                    when sendDMAC => -- destination MAC + 2 bytes of the source MAC address
                        fifoLastAddr <= std_logic_vector(unsigned(fifoRdAddr) + unsigned(fifoRdLength) - 1);
                        rd_fsm <= sendSMAC;
                        infoFifoRd <= '1';
                        setLast <= '0';
                        
                    when sendSMAC => -- 4 bytes of the source MAC address + 2 bytes of ethertype + 2 bytes of IPv4 header
                        rd_fsm <= sendIPv4;
                        infoFifoRd <= '0';
                        setLast <= '0';
                        
                    when sendIPv4 => -- length (2bytes) + identification (2 bytes) + flags (2 bytes) + time to live (1 byte) + protocol (1 byte)
                        rd_fsm <= sendIPv4Checksum;
                        infoFifoRd <= '0';
                        setLast <= '0';
                        
                    when sendIPv4Checksum => -- checksum (2 bytes), source IP address (4 bytes), 2 bytes of destination IP address
                        rd_fsm <= sendUDP;
                        infoFifoRd <= '0';
                        setLast <= '0';
                        
                    when sendUDP => -- last 2 bytes of destination IP address, source port (2 bytes), dest port (2 bytes), length (2 bytes)
                        rd_fsm <= sendDbgHdr;
                        infoFifoRd <= '0';
                        setLast <= '0';
                        
                    when sendDbgHdr => -- UDP checksum (2 bytes), i_myAddr (2 bytes), interconnect source port (1 byte), interconnect dest port (1 byte), sequence number (2 bytes)
                        rd_fsm <= sendData;
                        infoFifoRd <= '0';
                        setLast <= '0';
                        
                    when sendData => -- data read from the BRAM FIFO.
                        fifoRdAddr <= std_logic_vector(unsigned(fifoRdAddr) + 1);
                        if fifoRdAddr = fifoLastAddr then
                            -- Done, go back to idle.
                            rd_fsm <= idle;
                            setLast <= '1';
                        elsif (unsigned(finalFifoWrSize) > 15) then 
                            rd_fsm <= waitFinalFifo;
                            setLast <= '0';
                        end if;
                        infoFifoRd <= '0';
                        
                    when waitFinalFifo =>
                        if (unsigned(finalFifoWrSize) < 8) then
                            rd_fsm <= sendData;
                        end if;
                        infoFifoRd <= '0';
                        setLast <= '0';
                        
                    when others =>
                        rd_fsm <= idle;
                end case;
            end if;
            
            -- Data written to the final fifo lags by two clocks to account for the latency reading the memory. 
            rd_fsmDel1 <= rd_fsm;
            rd_fsmDel2 <= rd_fsmDel1;
            case rd_fsmDel2 is
                when sendDMAC => -- destination MAC + 2 bytes of the source MAC address
                    finalFifoDin(63 downto 0) <=  srcMAC(15 downto 0) & destMAC;
                    finalFifoWrEn <= '1';
                when sendSMAC => -- 4 bytes of the source MAC address + 2 bytes of ethertype + 2 bytes of IPv4 header
                    finalFifoDin(63 downto 0) <= x"00450008" & srcMAC(47 downto 16);
                    finalFifoWrEn <= '1';
                when sendIPv4 => -- length (2bytes) + identification (2 bytes) + flags (2 bytes) + time to live (1 byte) + protocol (1 byte)
                    finalFifoDin(63 downto 0) <= x"117F" & x"0000" & x"0000" & IPtotalLength(7 downto 0) & IPtotalLength(15 downto 8);
                    finalFifoWrEn <= '1';
                when sendIPv4Checksum => -- checksum (2 bytes), source IP address (4 bytes), 2 bytes of destination IP address
                    finalFifoDin(63 downto 0) <= destIPAddr(23 downto 16) & destIPAddr(31 downto 24) & srcIPAddr(7 downto 0) & srcIPAddr(15 downto 8) & srcIPAddr(23 downto 16) & srcIPAddr(31 downto 24) & (not IPchecksum3(7 downto 0)) & (not IPchecksum3(15 downto 8));
                    finalFifoWrEn <= '1';
                when sendUDP => -- last 2 bytes of destination IP address, source port (2 bytes), dest port (2 bytes), length (2 bytes)
                    finalFifoDin(63 downto 0) <= UDPtotalLength(7 downto 0) & UDPtotalLength(15 downto 8) & x"78" & x"56" & x"34" & x"12" & destIPAddr(7 downto 0) & destIPAddr(15 downto 8);
                    finalFifoWrEn <= '1';
                when sendDbgHdr => 
                    -- UDP checksum (2 bytes), i_myAddr (2 bytes), interconnect source port (1 byte), interconnect dest port (1 byte), sequence number (2 bytes)
                    -- UDP checksum is optional; set to zero.
                    finalFifoDin(63 downto 0) <= sequenceOut(7 downto 0) & sequenceOut(15 downto 8) & "000" & outputMuxOut & "000" & inputSel & myAddr(7 downto 0) & "0000" & myAddr(11 downto 8) & x"0000";
                    finalFifoWrEn <= '1';
                when sendData => -- sendData
                    finalFifoDin(63 downto 0) <= fifoRdData; -- Data from the BRAM buffer.
                    finalFifoWrEn <= '1';
                when others => -- idle or waitFinalFifo
                    finalFifoDin(63 downto 0) <= (others => '0');
                    finalFifoWrEn <= '0';
            end case;
            
            -- "last" bit.
            setLastDel1 <= setLast;
            --setLastDel2 <= setLastDel1;
            finalFifoDin(64) <= setLastDel1; -- Note setLast is already delayed one cycle, so setLastDel1 aligns with rd_fsmDel1.
            
            IPtotalLength <= std_logic_vector(38 + unsigned(lengthBytes));
            UDPtotalLength <= std_logic_vector(8 + unsigned(lengthBytes));
            -- Calculate the IPv4 checksum.
            -- The checksum is the ones complement of the ones complement sum of all the 16-bit words in the header. 
            -- 16 bit words in the header are :
            --  version etc.          = 0x4500
            --  total length          = 38 + [packet length]
            --  identification        = 0x0000
            --  flags + fragment      = 0x0000
            --  time to live+protocol = 0x7f11
            --  checksum              = 0x0000    (checksum value for the purpose of computing the checksum)
            --  source IP             = DHCP assigned 
            --  source IP             =       "
            --  Dest IP               = value from register. (default 192.168.1.7 ?)
            --  Dest IP
            --
            -- Adds up all the static (or semi-static) stuff, then add in the length 
            -- Note : Static part of the addition is 0x4500 + d38 + 0 + 0 + 0x7f11 + 0 = 0xC437  
            IPchecksum0 <= std_logic_vector(unsigned(staticIPHdrSum) + unsigned(srcIPAddr0) + unsigned(srcIPAddr1));
            IPchecksum1 <= std_logic_vector(unsigned(destIPAddr0) + unsigned(destIPAddr1) + unsigned(IPchecksum0));
            -- wrap around sum for ones complement arithmetic, and add in the actual length. Wrap around sum is needed at most twice.
            IPchecksum2 <= std_logic_vector(unsigned(IPchecksum1_high) + unsigned(IPchecksum1_low) + unsigned(lengthBytes));
            IPchecksum3 <= std_logic_vector(unsigned(IPchecksum2_high) + unsigned(IPchecksum2_low));
        end if;
    end process;
    
    staticIPHdrSum <= x"0C437";
    lengthBytes <= "000000" & fifoRdLength & "000"; -- Fifo is in units of 8 bytes; x8 to get byte length.
    srcIPAddr0 <= "0000" & srcIPAddr(15 downto 0);
    srcIPAddr1 <= "0000" & srcIPAddr(31 downto 16);
    destIPAddr0 <= "0000" & destIPAddr(15 downto 0);
    destIPAddr1 <= "0000" & destIPAddr(31 downto 16);
    
    IPchecksum1_low <= "0000" & IPchecksum1(15 downto 0);
    IPchecksum1_high <= "0000000000000000" & IPchecksum1(19 downto 16);
    
    IPchecksum2_low <= "0000" & IPchecksum2(15 downto 0);
    IPchecksum2_high <= "0000000000000000" & IPchecksum2(19 downto 16);
    
    
    -- FIFO to couple reading of the BRAM buffer to the 25GE interface.
    -- Needed because the 25GE interface can stall.
    finalFifo_inst : xpm_fifo_sync
    generic map (
        DOUT_RESET_VALUE => "0",    -- String, Reset value of read data path.
        ECC_MODE => "no_ecc",       -- String, Allowed values: no_ecc, en_ecc.
        FIFO_MEMORY_TYPE => "distributed", -- String, Allowed values: auto, block, distributed. 
        FIFO_READ_LATENCY => 0,     -- Integer, Range: 0 - 10. Must be 0 for first READ_MODE = "fwft" (first word fall through).    
        FIFO_WRITE_DEPTH => 32,     -- Integer, Range: 16 - 4194304. Defines the FIFO Write Depth. Must be power of two.
        FULL_RESET_VALUE => 0,      -- Integer, Range: 0 - 1. Sets full, almost_full and prog_full to FULL_RESET_VALUE during reset
        PROG_EMPTY_THRESH => 10,    -- Integer, Range: 3 - 4194301.Specifies the minimum number of read words in the FIFO at or below which prog_empty is asserted.
        PROG_FULL_THRESH => 10,     -- Integer, Range: 5 - 4194301. Specifies the maximum number of write words in the FIFO at or above which prog_full is asserted.
        RD_DATA_COUNT_WIDTH => 6,   -- Integer, Range: 1 - 23. Specifies the width of rd_data_count. To reflect the correct value, the width should be log2(FIFO_READ_DEPTH)+1. FIFO_READ_DEPTH = FIFO_WRITE_DEPTH*WRITE_DATA_WIDTH/READ_DATA_WIDTH         
        READ_DATA_WIDTH => 65,      -- Integer, Range: 1 - 4096. Defines the width of the read data port, dout
        READ_MODE => "fwft",        -- String, Allowed values: std, fwft. Default value = std.
        --SIM_ASSERT_CHK => 0,        -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
        USE_ADV_FEATURES => "0004", -- String
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
        WRITE_DATA_WIDTH => 65,    -- Integer, Range: 1 - 4096. Defines the width of the write data port, din             
        WR_DATA_COUNT_WIDTH => 6   -- Integer, Range: 1 - 23. Specifies the width of wr_data_count. To reflect the correct value, the width should be log2(FIFO_WRITE_DEPTH)+1.   |
    )
    port map (
        almost_empty => open, -- 1-bit output: Almost Empty : When asserted, this signal indicates that only one more read can be performed before the FIFO goes to empty.
        almost_full => open,  -- 1-bit output: Almost Full: When asserted, this signal indicates that only one more write can be performed before the FIFO is full.
        data_valid => open,   -- 1-bit output: Read Data Valid: When asserted, this signal indicates that valid data is available on the output bus (dout).
        dbiterr => open,      -- 1-bit output: Double Bit Error: Indicates that the ECC decoder detected a double-bit error and data in the FIFO core is corrupted.
        dout => finalFifoRdData,  -- READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven when reading the FIFO.
        empty => finalFifoEmpty,  -- 1-bit output: Empty Flag: When asserted, this signal indicates that
                                 -- the FIFO is empty. Read requests are ignored when the FIFO is empty, initiating a read while empty is not destructive to the FIFO.
        full => finalFifofull,    -- 1-bit output: Full Flag: When asserted, this signal indicates that the FIFO is full. Write requests are ignored when the FIFO is full,
                                 -- initiating a write when the FIFO is full is not destructive to the contents of the FIFO.
        overflow => open,   -- 1-bit output: Overflow: This signal indicates that a write request (wren) during the prior clock cycle was rejected, because the FIFO is
                            -- full. Overflowing the FIFO is not destructive to the contents of the FIFO.
        prog_empty => open, -- 1-bit output: Programmable Empty: This signal is asserted when the number of words in the FIFO is less than or equal to the programmable
                            -- empty threshold value. It is de-asserted when the number of words in the FIFO exceeds the programmable empty threshold value.
        prog_full => open,  -- 1-bit output: Programmable Full: This signal is asserted when the number of words in the FIFO is greater than or equal to the
                            -- programmable full threshold value. It is de-asserted when the number of words in the FIFO is less than the programmable full threshold value.
        rd_data_count => open,      -- RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates the number of words read from the FIFO.
        rd_rst_busy => open, -- 1-bit output: Read Reset Busy: Active-High indicator that the FIFO read domain is currently in a reset state.
        sbiterr => open,            -- 1-bit output: Single Bit Error: Indicates that the ECC decoder detected and fixed a single-bit error.
        underflow => open,          -- 1-bit output: Underflow: Indicates that the read request (rd_en) during the previous clock cycle was rejected because the FIFO is empty. Under flowing the FIFO is not destructive to the FIFO.
        wr_ack => open,             -- 1-bit output: Write Acknowledge: This signal indicates that a write request (wr_en) during the prior clock cycle is succeeded.
        wr_data_count => finalFifoWrSize,      -- WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates the number of words written into the FIFO.
        wr_rst_busy => open, -- 1-bit output: Write Reset Busy: Active-High indicator that the FIFO write domain is currently in a reset state.
        din => finalFifoDin,         -- WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when writing the FIFO.
        injectdbiterr => '0',       -- 1-bit input: Double Bit Error Injection: Injects a double bit error if the ECC feature is used on block RAMs or UltraRAM macros.
        injectsbiterr => '0',       -- 1-bit input: Single Bit Error Injection: Injects a single bit error if the ECC feature is used on block RAMs or UltraRAM macros.
        rd_en => finalFifoRdEn,      -- 1-bit input: Read Enable: If the FIFO is not empty, asserting this signal causes data (on dout) to be read from the FIFO. Must be held active-low when rd_rst_busy is active high.
        rst => dbg25GE_rst,               -- 1-bit input: Reset.
        sleep => '0',               -- 1-bit input: Dynamic power saving: If sleep is High, the memory/fifo block is in power saving mode.
        wr_clk => i_dbg25GE_clk,         -- 1-bit input: Write clock: Used for write operation. wr_clk must be a free running clock.
        wr_en => finalFifoWrEn       -- bit input: Write Enable: If the FIFO is not full, asserting this signal causes data (on din) to be written to the FIFO. Must be held active-low when rst or wr_rst_busy is active high.
    );
   
    -- Out :
    o_dbg25GE.tvalid <= not finalFifoEmpty;
    o_dbg25GE.tlast <= finalFifoRdData(64);
    o_dbg25GE.tdata(63 downto 0) <= finalFifoRdData(63 downto 0);
    o_dbg25GE.tkeep(7 downto 0) <= "11111111"; 
    o_dbg25GE.tuser(0) <= '0';
    -- in :
    finalFifoRdEn <= i_dbg25GE.tready and (not finalFifoEmpty);
    
end Behavioral;

