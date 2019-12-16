----------------------------------------------------------------------------------
-- Company: CSIRO
-- Engineer: David Humphrey
-- 
-- Create Date: 23.04.2019 22:26:05
-- Module Name: LFAAProcess - Behavioral
-- Project Name: Perentie
-- Description: 
--  Generates test data in accord with the data in the virtual channel table.
--  The data in the packets is random numbers generated with an LFSR.
--  
----------------------------------------------------------------------------------

library IEEE, axi4_lib, xpm, LFAADecode_lib, common_lib;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use axi4_lib.axi4_stream_pkg.ALL;
use axi4_lib.axi4_lite_pkg.ALL;
use xpm.vcomponents.all;
use LFAADecode_lib.LFAADecode_lfaadecode_reg_pkg.ALL;

entity testProcess is
    port(
        i_data_clk        : in std_logic;     -- 312.5 MHz for 40GE MAC
        i_data_rst        : in std_logic;
        -- Data out 
        o_data_out        : out std_logic_vector(127 downto 0);
        o_valid_out       : out std_logic;
        -- miscellaneous
        i_time_sec        : in std_logic_vector(31 downto 0);  -- UNIX time in seconds.
        i_time_frac       : in std_logic_vector(23 downto 0);  -- fraction of a second, units of 64ns, counts from 0 to 15624999.
        -- Interface to the registers
        i_reg_rw          : in t_statctrl_rw;
        o_reg_ro          : out t_statctrl_ro;
        o_reg_count       : out t_statctrl_count;
        -- Virtual channel table memory in the registers
        --  Address mapping :
        --    - StationID1 in address 0-383
        --    - StationID2 in address 512-895
        --  data :
        --    - (8:0)  = frequency_id;
        --    - (12:9) = beam_id;
        --    - (15:13) = substation_id;
        --    - (20:16) = subarray_id;
        --    - (30:21) = station_id;
        --    - (31) = invalid (i.e. '1' if the entry is invalid);
        o_searchAddr      : out std_logic_vector(9 downto 0); -- read address to the VCTable_ram in the registers.
        i_VCTable_rd_data : in std_logic_vector(31 downto 0); -- read data from VCTable_ram in the registers; assumed valid 2 clocks after searchAddr.
        -- Virtual channel stats in the registers.
        -- Address Mapping :
        --    - Address is virtual_channel * 4, with offset:
        --      - stationID1 in address 0 to 3071
        --      - stationID2 in address 3072 to 6143
        -- Data :
        --    - Word 0 : statsNOFAntennas & statsSPEADLogicalChannel 
        --        * Unused in this module
        --    - Word 1 : Packet Count
        --    - Word 2 : bits(7:0) = out of order count, bits(31:8) = fractional time of most recent packet
        --    - Word 3 : Unix time of most recent packet. 
        --    - Word 4 to 7 are unused for test data generation.
        o_statsWrData     : out std_logic_vector(31 downto 0);
        o_statsWE         : out std_logic;
        o_statsAddr       : out std_logic_vector(12 downto 0);
        i_statsRdData     : in std_logic_vector(31 downto 0)         
    );
end testProcess;
    

architecture Behavioral of testProcess is

    signal generateEn : std_logic;
    signal generateEnDel : std_logic;
    signal frameStartSec : std_logic_vector(31 downto 0);
    signal frameStartFrac : std_logic_vector(31 downto 0);
    
    constant frameTime64ns : std_logic_vector(31 downto 0) := x"00D72800"; -- Number of 64 ns steps in one frame = 1080e-9 * 2048 * 408 / 64e-9
    constant time1sec64ns : std_logic_vector(31 downto 0) := x"00EE6B27";  -- Decimal 15624999 = last 64ns step in 1 second. 
    
    signal startFrame : std_logic := '0';
    
    signal dataCount : std_logic_vector(9 downto 0);
    signal data_out : std_logic_vector(127 downto 0);
    signal valid_out : std_logic;
    type pkt_fsm_type is (idle, rdVirtualChannel, rdVirtualChannelWait0, rdVirtualChannelWait1, sendHeader, sendData,  setChannel, setPacketCount, setTimeStampFrac, setTimeStampInt, pktDone, wait899);
    signal pkt_fsm : pkt_fsm_type := idle;
    signal packetCount : std_logic_vector(31 downto 0);
    signal virtualChannel : std_logic_vector(9 downto 0);
    signal packetInFrame : std_logic_vector(8 downto 0);
    signal frequencyID : std_logic_vector(8 downto 0);
    signal stationID : std_logic_vector(8 downto 0);
    signal waitCount : std_logic_vector(9 downto 0);
    signal setSeed : std_logic := '0';
    signal seed : std_logic_vector(31 downto 0);
    signal seedFull : std_logic_vector(127 downto 0);
    signal randData : std_logic_vector(127 downto 0);
    signal statsWE : std_logic;
    signal statsAddr : std_logic_vector(12 downto 0);
    signal statsWrData : std_logic_vector(31 downto 0);
    signal valid_out_del : std_logic;
    signal goodPacket : std_logic;
    signal VirtualChannelx8 : std_logic_vector(12 downto 0);
    signal statsBaseAddr : std_logic_Vector(12 downto 0);
    signal statsTimeFrac : std_logic_vector(23 downto 0);
    signal statsTimeInt : std_logic_vector(31 downto 0);
    
begin
    
    -- 
    process(i_data_clk, i_data_rst)
    begin
        if rising_edge(i_data_clk) then
            
            -------------------------------------------------------
            -- Find the time to start generating frames 
            generateEn <= i_reg_rw.testGenCtrl; -- Rising edge of enable triggers updating of the frame start time.
            generateEnDel <= generateEn;
            
            if generateEn = '1' and generateEnDel = '0' then
                -- Start generation; set the time for the next frame
                frameStartSec <= i_reg_rw.testGenFrameStart;
                frameStartFrac <= (others => '0');
            elsif (unsigned(frameStartFrac) > unsigned(time1sec64ns)) then
                -- Must have incremented the fractional time in a previous clock cycle, and gone over a 1 second boundary
                frameStartFrac <= std_logic_vector(unsigned(frameStartFrac) - unsigned(time1sec64ns));
                frameStartSec <= std_logic_vector(unsigned(frameStartSec) + 1);
            elsif ((unsigned(frameStartSec) < unsigned(i_time_sec)) or 
                   ((unsigned(frameStartSec) = unsigned(i_time_sec)) and (unsigned(frameStartFrac) < unsigned(i_time_frac)))) then 
                -- frame start is before the current time, increment it until it is in front of the current time
                frameStartFrac <= std_logic_vector(unsigned(frameStartFrac) + unsigned(frameTime64ns)); 
                
            end if;
            
            if ((frameStartSec = i_time_sec) and (frameStartFrac(23 downto 0) = i_time_frac)) then
                startFrame <= '1';
            else
                startFrame <= '0';
            end if;
            
            
            -------------------------------------------------------
            -- Generate frames by reading the virtual channel memory
            -- The total time available for each frame is 900 clocks @ 312.5 MHz
            -- note : 900 * 3.2ns * 768 = 2.2ms = 2048 * 1080ns
            -- This runs a little bit faster so that we have time to clear the packet count 
            -- in the stats memory if we needed to.
            -- So 899 clocks.
            -- 
            if generateEn = '1' and generateEnDel = '0' then
                -- start of generation of packets, set the packet count for all channels to zero.
                pkt_fsm <= idle;
                packetCount <= (others => '0');
            else
                case pkt_fsm is
                    when idle =>
                        valid_out <= '0';
                        statsWE <= '0';
                        virtualChannel <= (others => '0');  -- counts 0 to 383, 512 to 895
                        packetInFrame <= (others => '0');   -- counts 0 to 407 within the frame
                        if startFrame = '1' then
                            pkt_fsm <= rdVirtualChannel;
                        end if;
                    
                    when rdVirtualChannel =>  -- wait while we 
                        valid_out <= '0';
                        statsWE <= '0'; 
                        pkt_fsm <= rdVirtualChannelWait0;
                        
                    when rdVirtualChannelWait0 =>
                        valid_out <= '0';
                        statsWE <= '0';
                        pkt_fsm <= rdVirtualChannelWait1;
                    
                    when rdVirtualChannelWait1 =>
                        valid_out <= '0';
                        statsWE <= '0';
                        frequencyID <= i_VCTable_rd_data(8 downto 0);
                        stationID <= i_VCTable_rd_data(29 downto 21);
                        if i_VCTable_rd_data(31) = '1' then  -- This entry in the virtual channel table is not used.
                            pkt_fsm <= wait899;
                        else
                            pkt_fsm <= sendHeader;
                        end if;
                        
                    when sendHeader =>
                        data_out(8 downto 0) <= virtualChannel(8 downto 0);
                        data_out(17 downto 9) <= frequencyID; -- obtained from bits(8:0) of the virtual channel table;
                        data_out(26 downto 18) <= stationID;  -- stationID is from bits(29:21) of the virtual channel table
                        data_out(58 downto 27) <= packetCount;  -- internal counter (also written back to the stats memory)
                        data_out(59) <= virtualChannel(9);  -- top bit of the address into the virtual channel table.
                        data_out(127 downto 60) <= (others => '0');
                        valid_out <= '1';
                        dataCount <= (others => '0');
                        statsWE <= '0';
                        statsTimeFrac <= i_time_frac;
                        statsTimeInt <= i_time_sec;
                        pkt_fsm <= sendData;
                    
                    when sendData =>
                        statsWE <= '0';
                        valid_out <= '1';
                        if (unsigned(dataCount) = 511) then
                            pkt_fsm <= setChannel;
                        end if;
                        if i_reg_rw.packetGenMode = "001" then -- send zeros
                            data_out(127 downto 0) <= (others => '0');
                        elsif i_reg_rw.packetGenMode = "010" then -- -1, 0, +1
                            for i in 0 to 15 loop
                                if randData(i*8+1 downto i*8) = "01" then
                                    data_out(i*8+7 downto i*8) <= "00000001";
                                elsif randData(i*8+1 downto i*8) = "10" then
                                    data_out(i*8+7 downto i*8) <= "00000001";
                                else -- "00" and "11" map to zero,
                                    data_out(i*8+7 downto i*8) <= "00000000";
                                end if;
                            end loop;
                        elsif i_reg_rw.packetGenMode = "011" then -- -7 to 7
                            for i in 0 to 15 loop
                                if randData(i*8+3 downto i*8) = "0000" or randData(i*8+3 downto i*8) = "1000"  then
                                    data_out(i*8+7 downto i*8) <= "00000000"; -- two values map to 0 so that the output is unbiased.
                                else
                                    data_out(i*8+7 downto i*8) <= randData(i*8+3) & randData(i*8+3) & randData(i*8+3) & randData(i*8+3) & randData(i*8+3 downto i*8);
                                end if;
                            end loop;
                        elsif i_reg_rw.packetGenMode = "100" then -- -15 to 15
                            for i in 0 to 15 loop
                                if randData(i*8+4 downto i*8) = "00000" or randData(i*8+4 downto i*8) = "10000"  then
                                    data_out(i*8+7 downto i*8) <= "00000000"; -- two values map to 0 so that the output is unbiased.
                                else
                                    data_out(i*8+7 downto i*8) <= randData(i*8+4) & randData(i*8+4) & randData(i*8+4) & randData(i*8+4 downto i*8);
                                end if;
                            end loop;                            
                        elsif i_reg_rw.packetGenMode = "101" then -- -31 to 31
                            for i in 0 to 15 loop
                                if randData(i*8+5 downto i*8) = "000000" or randData(i*8+5 downto i*8) = "100000"  then
                                    data_out(i*8+7 downto i*8) <= "00000000"; -- two values map to 0 so that the output is unbiased.
                                else
                                    data_out(i*8+7 downto i*8) <= randData(i*8+5) & randData(i*8+5) & randData(i*8+5 downto i*8);
                                end if;
                            end loop;
                        elsif i_reg_rw.packetGenMode = "110" then -- -63 to 63
                            for i in 0 to 15 loop
                                if randData(i*8+6 downto i*8) = "0000000" or randData(i*8+6 downto i*8) = "1000000"  then
                                    data_out(i*8+7 downto i*8) <= "00000000"; -- two values map to 0 so that the output is unbiased.
                                else
                                    data_out(i*8+7 downto i*8) <= randData(i*8+6) & randData(i*8+6 downto i*8);
                                end if;
                            end loop;
                        else -- -127 to 127
                            for i in 0 to 15 loop
                                if randData(i*8+7 downto i*8) = "00000000" or randData(i*8+7 downto i*8) = "10000000"  then
                                    data_out(i*8+7 downto i*8) <= "00000000"; -- two values map to 0 so that the output is unbiased. Also we don't flag anything as RFI.
                                else
                                    data_out(i*8+7 downto i*8) <= randData(i*8+7 downto i*8);
                                end if;
                            end loop;
                        end if;
                        dataCount <= std_logic_vector(unsigned(dataCount) + 1);
                    
                    when setChannel =>  -- channel at address offset 0 in the stats mamory
                        statsAddr <= statsBaseaddr;
                        statsWrData <= x"0100" & "0000000" & virtualChannel(8 downto 0);  -- top 16 bits is "nof_antennas"; for test packets just set to 256. 
                        statsWE <= '1';
                        pkt_fsm <= setPacketCount;
                        valid_out <= '0';
                        data_out <= (others => '0');
                        
                    when setPacketCount =>  -- packet count at address offset 1 in the stats memory
                        pkt_fsm <= setTimeStampFrac;
                        valid_out <= '0';
                        data_out <= (others => '0');
                        statsAddr <= std_logic_vector(unsigned(statsBaseaddr) + 1);
                        statsWrData <= packetCount;
                        statsWE <= '1';

                    when setTimeStampFrac => -- at address offset 2 in the stats memory
                        pkt_fsm <= setTimeStampInt;
                        valid_out <= '0';
                        data_out <= (others => '0');     
                        statsAddr <= std_logic_vector(unsigned(statsBaseaddr) + 2);
                        statsWrData(7 downto 0) <= x"00"; -- this is the out of order count, which is zero in test mode.
                        statsWrData(31 downto 8) <= statsTimeFrac;
                        statsWE <= '1';
                        
                    when setTimeStampInt =>  -- The time stamp for this packet in the stats memory, address offset 3
                        pkt_fsm <= pktDone;
                        valid_out <= '0';
                        data_out <= (others => '0');
                        statsAddr <= std_logic_vector(unsigned(statsBaseaddr) + 3);
                        statsWrData <= statsTimeInt;
                        statsWE   <= '1';                        
                     
                    when pktDone =>
                        if (unsigned(virtualChannel) = 383) then
                            virtualChannel <= "1000000000"; -- 512
                            pkt_fsm <= wait899; 
                        elsif (unsigned(virtualChannel) = 895) then
                            virtualChannel <= (others => '0');
                            packetCount <= std_logic_vector(unsigned(packetCount) + 1);
                            if unsigned(packetInFrame) = 407 then
                                packetInFrame <= (others => '0');
                                pkt_fsm <= idle;
                            else
                                packetInFrame <= std_logic_vector(unsigned(packetInFrame) + 1);
                                pkt_fsm <= wait899;
                            end if;
                        else
                            virtualChannel <= std_logic_vector(unsigned(virtualChannel) + 1);
                            pkt_fsm <= wait899;
                        end if;
                        valid_out <= '0';
                        data_out <= (others => '0');
                        statsWE <= '0';
                        statsWrData <= (others => '0');
                    
                    when wait899 => 
                        -- Wait until a total of 899 clocks have passed so that packets are spaced correctly
                        valid_out <= '0';
                        if unsigned(waitCount) = 898 then -- check this value...
                            pkt_fsm <= rdVirtualChannel;
                        end if;
                        
                    when others =>
                        pkt_fsm <= idle;
                end case;
            end if;
            
            
            if virtualChannel(9) = '0' then
                statsBaseAddr <= VirtualChannelx8; -- address to read in the stats memory
            else -- read address starts at 1536
                statsBaseAddr <= std_logic_vector(3072 + unsigned(virtualChannelx8));
            end if;
            
            if generateEn = '1' and generateEnDel = '0' then
                setSeed <= '1';
            else
                setSeed <= '0';
            end if;
            
            seed <= i_reg_rw.randSeed;
            
            if pkt_fsm = rdVirtualChannel then
                waitCount <= (others => '0');
            else
                waitCount <= std_logic_vector(unsigned(waitCount) + 1);
            end if;
            
            valid_out_del <= valid_out;
            if valid_out = '0' and valid_out_del = '1' then
                goodPacket <= '1'; -- just triggers the counter in the registers of the number of packets sent.
            else
                goodPacket <= '0';
            end if; 
            
        end if;
    end process;
    
    VirtualChannelx8 <= '0' & virtualChannel(8 downto 0) & "000";
    
    o_searchAddr <= virtualChannel;
    
    o_statsAddr <= statsAddr;
    o_statsWE <= statsWE;
    o_statsWrData <= statsWrData;
    
    -- Drive counters in the registers module.
    -- spead_packet_count counts the number of packets sent;
    -- The other counters are never triggered because errors cannot happen in test mode.
    o_reg_count.spead_packet_count <= goodPacket;
    o_reg_count.nonspead_packet_count <= '0';
    o_reg_count.badethernetframes <= '0';
    o_reg_count.badipudpframes <= '0';
    o_reg_count.novirtualchannelcount <= '0';
    
    o_reg_ro.testcurrentframestartseconds <= frameStartSec;  -- next start of frame time, seconds, 32 bits.
    o_reg_ro.testcurrentframestartfrac <= frameStartFrac(23 downto 0);    -- next start of frame time, fraction of a second, 24 bits (units of 64 ns)
    
    -- STATCTRL_FIELDS_RW.testgenframestart<= statctrl_out_reg(c_byte_w*4+31 downto c_byte_w*4);
    -- STATCTRL_FIELDS_RW.testgenctrl        <= statctrl_out_reg(c_byte_w*8);
    
    o_data_out <= data_out;
    o_valid_out <= valid_out;
    
    
    
    LFSRInst : entity  common_lib.common_multiStepLFSR
    generic map (
        WIDTH => 128,  -- Number of bits in the shift register.
        STEPS => 128)  -- Number of steps to advance by each clock.
    port map (
        clk => i_data_clk,
        set_seed_i => setSeed, 
        seed_i     => seedFull,  --  in std_logic_vector((WIDTH-1) downto 0);
        enable_i   => valid_out, --  in std_logic;   -- enable advance to the next state
        rand_o     => randData   -- out std_logic_vector((WIDTH-1) downto 0)          
    );
    
    seedFull <= (not seed) & seed & (not seed) & seed; -- Expand the seed out to 128 bits (and guarantee that it is not all zeros). 
    
    
end Behavioral;
