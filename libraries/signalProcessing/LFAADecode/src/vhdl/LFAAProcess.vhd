----------------------------------------------------------------------------------
-- Company: CSIRO
-- Engineer: David Humphrey
-- 
-- Create Date: 23.04.2019 22:26:05
-- Module Name: LFAAProcess - Behavioral
-- Project Name: Perentie
-- Description: 
--  Takes in LFAA data from the 40GE interface, decodes it, finds the matching virtual channel,
-- and outputs the packet to downstream modules.
-- 
----------------------------------------------------------------------------------

library IEEE, axi4_lib, xpm, LFAADecode_lib, ctc_lib, dsp_top_lib;
--use ctc_lib.ctc_pkg.all;
use DSP_top_lib.DSP_top_pkg.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use axi4_lib.axi4_stream_pkg.ALL;
use axi4_lib.axi4_lite_pkg.ALL;
use xpm.vcomponents.all;
use LFAADecode_lib.LFAADecode_lfaadecode_reg_pkg.ALL;

entity LFAAProcess is
    port(
        -- Data in from the 40GE MAC
        i_data_rx_sosi     : in t_axi4_sosi;   -- 128 bit wide data in, only fields that are used are .tdata, .tvalid, .tuser
        i_data_clk         : in std_logic;     -- 312.5 MHz for 40GE MAC
        i_data_rst         : in std_logic;
        -- Data out 
        o_data_out         : out std_logic_vector(127 downto 0);
        o_valid_out        : out std_logic;
        -- miscellaneous
        i_my_mac           : in std_logic_vector(47 downto 0); -- MAC address for this board; incoming packets from the 40GE interface are filtered using this.
        i_wallTime         : in t_wall_time;                   -- Defined in DSP_top_pkg, 32 bit seconds (.sec), 30 bit nanoseconds (.ns). 
        --i_time_sec         : in std_logic_vector(31 downto 0); -- Current time in this clock domain; 32 bit second count
        --i_time_frac        : in std_logic_vector(26 downto 0); -- Count in units of 8ns; only use 64 ns steps (drop the low 3 bits in this module) 
        -- Interface to the registers
        i_reg_rw           : in t_statctrl_rw;
        o_reg_count        : out t_statctrl_count;
        -- Virtual channel table memory in the registers
        o_searchAddr       : out std_logic_vector(9 downto 0); -- read address to the VCTable_ram in the registers.
        i_VCTable_rd_data  : in std_logic_vector(31 downto 0); -- read data from VCTable_ram in the registers; assumed valid 2 clocks after searchAddr.
        -- Virtual channel stats in the registers.
        o_statsWrData      : out std_logic_vector(31 downto 0);
        o_statsWE          : out std_logic;
        o_statsAddr        : out std_logic_vector(12 downto 0);  -- 8 words of info per virtual channel, 768 virtual channels, 8*768 = 6144 deep.
        i_statsRdData      : in std_logic_vector(31 downto 0);
        -- debug
        o_dbg              : out std_logic_vector(13 downto 0)
    );
end LFAAProcess;

architecture Behavioral of LFAAProcess is

    -- relevant fields extracted from the .tuser field of the input data_rx_sosi (which comes from the 40GE MAC)
    -- data_rx_sosi.tuser has two sets of these groups of signals, one data_rx_sosi.tdata(63:0), and one for data_rx_sosi.tdata(127:64) 
    type t_tuser_segment is record
        ena : std_logic;
        sop : std_logic;
        eop : std_logic;
        mty : std_logic_vector(2 downto 0);
        err : std_logic;
    end record;
    
    signal tuserSeg0, tuserSeg1, tuserSeg0Del, tuserSeg1Del : t_tuser_segment;
    
    -- Define a type to match fields in the data coming in
    constant fieldsToMatch : natural := 30;
    
    type t_field_match is record
        wordCount  : std_logic_vector(2 downto 0); -- which 128-bit word the field should match to. This will always be in the first 8 128-bit words.
        byteOffset : natural; -- where in the 128-bit word the relevant bits should sit
        bytes      : natural;  -- How many bits we are checking
        expected   : std_logic_vector(47 downto 0); -- Value we expect for a valid SPEAD packet
        check      : std_logic;   -- Whether we should check against the expected value or not
    end record;
    
    type t_field_values is array(0 to (fieldsToMatch-1)) of std_logic_vector(47 downto 0);
    type t_field_match_loc_array is array(0 to (fieldsToMatch-1)) of t_field_match;

    -- Alignments - Data in is aligned to an offset of 0 (when sop0 = '1') or 8 bytes (when sop1 = '1').
    -- An initial alignment shifts packets that use sop1, so that all packets have an alignment of 0.
    --  IPv4 header will have an offset of +14 bytes (assuming 2 bytes for ethertype)
    --  UDP header will have an offset of +34 bytes (2*16+2)
    --  SPEAD header will have an offset of +42 bytes (2*16+10) 
    --  Data part will have an offset of +114 bytes   (7*16 + 2)
    --  The data is 8192 bytes = 512 * 16, so the total number of words is 520, with only 2 bytes valid in the final word. 
    -- Note all SPEAD IDs listed in the comments below exclude the msb, which is '1' ( = immediate) for all except for sample_offset (SPEAD ID 0x3300)
    --
    -- A note on byte order from the 40GE core -
    --  Bytes are sent so that the first byte in the ethernet frame is bits(7:0), second byte is bits(15:8) etc.
    -- So e.g. for a first data word with bits(127:0) = 0x00450008201D574B6B50FFEEDDCCBBAA, we have
    --  destination MAC address = AA:BB:CC:DD:EE:FF
    --  Source MAC address = 50:6B:4B:57:1D:20
    --  Ethertype = "0800"
    --  IPv4 header byte 0 = 0x45
    --  IPv4 DSCP/ECN field = 0x0
    constant c_fieldmatch_loc : t_field_match_loc_array := 
        ((wordCount => "000", byteOffset => 0, bytes => 6,  expected => x"000000000000", check => '0'), -- 0. Destination MAC address, first 6 bytes of the frame.
         (wordCount => "000", byteOffset => 12, bytes => 2, expected => x"000000000800", check => '1'), -- 1. Ethertype field at byte 12 should be 0x0800 for IPv4 packets
         (wordCount => "000", byteOffset => 14, bytes => 1, expected => x"000000000045", check => '1'), -- 2. Version and header length fields of the IPv4 header, at byte 14. should be x45.
         (wordCount => "001", byteOffset => 0, bytes => 2,  expected => x"000000002064", check => '1'), -- 3. Total Length from the IPv4 header. Should be 20 (IPv4) + 8 (UDP) + 72 (SPEAD) + 8192 (Data) = 8292 = x2064
         (wordCount => "001", byteOffset => 7, bytes=> 1,   expected => x"000000000011", check => '1'), -- 4. Protocol field from the IPv4 header, Should be 0x11 (UDP).
         (wordCount => "010", byteOffset => 4, bytes => 2,  expected => x"000000000000", check => '0'), -- 5. Destination UDP port - expected value to be configured via MACE
         (wordCount => "010", byteOffset => 6, bytes => 2,  expected => x"000000002050", check => '1'), -- 6. UDP length. Should be 8 (UDP) + 72 (SPEAD) + 8192 (Data) = x2050
         (wordCount => "010", byteOffset => 10, bytes => 2, expected => x"000000005304", check => '1'), -- 7. First 2 bytes of the SPEAD header, should be 0x53 ("MAGIC"), 0x04 ("Version")
         (wordCount => "010", byteOffset => 12, bytes => 2, expected => x"000000000206", check => '1'),    -- 8. Bytes 3 and 4 of the SPEAD header, should be 0x02 ("ItemPointerWidth"), 0x06 ("HeapAddrWidht")
         (wordCount => "011", byteOffset => 0, bytes => 2,  expected => x"000000000008", check => '1'),    -- 9. Bytes 7 and 8 of the SPEAD header, should be 0x00 and 0x08 ("Number of Items")
         (wordCount => "011", byteOffset => 2, bytes => 2,  expected => x"000000008001", check => '1'), -- 10. SPEAD ID 0x0001 = "heap_counter" field, should be 0x8001.
         (wordCount => "011", byteOffset => 4, bytes => 2,  expected => x"000000000000", check => '0'),    -- 11. Logical Channel ID
         (wordCount => "011", byteOffset => 6, bytes => 4,  expected => x"000000000000", check => '0'),    -- 12. Packet Counter 
         (wordCount => "011", byteOffset => 10, bytes => 2, expected => x"000000008004", check => '1'), -- 13. SPEAD ID 0x0004 = "pkt_len" (data for this SPEAD ID is ignored)
         (wordCount => "100", byteOffset => 2, bytes => 2,  expected => x"000000009027", check => '1'), -- 14. SPEAD ID 0x1027 = "sync_time"
         (wordCount => "100", byteOffset => 4, bytes => 6,  expected => x"000000000000", check => '0'),     -- 15. sync time in seconds from UNIX epoch
         (wordCount => "100", byteOffset => 10, bytes => 2, expected => x"000000009600", check => '1'), -- 16. SPEAD ID 0x1600 = timestamp, time in nanoseconds after "sync_time"
         (wordCount => "100", byteOffset => 12, bytes => 4, expected => x"000000000000", check => '0'),    -- 17. first 4 bytes of timestamp
         (wordCount => "101", byteoffset => 0, bytes => 2,  expected => x"000000000000", check => '0'),    -- 18. Last 2 bytes of the timestamp
         (wordCount => "101", byteoffset => 2, bytes => 2,  expected => x"000000009011", check => '1'), -- 19. SPEAD ID 0x1011 = center_freq
         (wordCount => "101", byteoffset => 4, bytes => 6,  expected => x"000000000000", check => '0'),     -- 20. center_frequency in Hz
         (wordCount => "101", byteoffset => 10, bytes => 2, expected => x"00000000b000", check => '1'), -- 21. SPEAD ID 0x3000 = csp_channel_info
         (wordCount => "101", byteoffset => 14, bytes => 2, expected => x"000000000000", check => '0'),    -- 22. beam_id
         (wordCount => "110", byteoffset => 0, bytes => 2,  expected => x"000000000000", check => '0'),    -- 23. frequency_id
         (wordCount => "110", byteoffset => 2, bytes => 2,  expected => x"00000000b001", check => '1'), -- 24. SPEAD ID 0x3001 = csp_antenna_info
         (wordCount => "110", byteoffset => 4, bytes => 1,  expected => x"000000000000", check => '0'),    -- 25. substation_id
         (wordCount => "110", byteoffset => 5, bytes => 1,  expected => x"000000000000", check => '0'),    -- 26. subarray_id
         (wordCount => "110", byteoffset => 6, bytes => 2,  expected => x"000000000000", check => '0'),    -- 27. station_id
         (wordCount => "110", byteoffset => 8, bytes => 2,  expected => x"000000000000", check => '0'),    -- 28. nof_contributing_antennas
         (wordCount => "110", byteoffset => 10, bytes => 2, expected => x"00000000b300", check => '1')  -- 29. SPEAD ID 0x3300 = sample_offset
    );

    -- For data coming in, capture the following fields to registers, and use them to look up the virtual channel from the table in the registers.
    --  - frequency_id, 9 bits, SPEAD ID 0x3000
    --  - beam_id, 4 bits, SPEAD ID 0x3000
    --  - substation_id, 3 bits, SPEAD ID 0x3001
    --  - subarray_id, 5 bits, SPEAD ID 0x3001
    --  - station_id, 10 bits, SPEAD ID 0x3001
    constant c_frequency_id_index : natural := 23;  -- 23rd field in c_fieldmatch_loc
    constant c_beam_id_index : natural := 22;
    constant c_substation_id_index : natural := 25;
    constant c_subarray_id_index : natural := 26;
    constant c_station_id_index : natural := 27;
    constant c_packet_counter : natural := 12;
    
    constant c_SPEAD_logical_channel : natural := 11;
    constant c_nof_antennas : natural := 28;
    constant c_timestamp_high : natural := 17;  -- 4 high bytes
    constant c_timestamp_low : natural := 18;   -- 2 low bytes
    constant c_sync_time : natural := 15; -- sync time, 6 bytes.
    
    --signal expectedValues : t_field_values;  -- some expected values are constants drawn from c_fieldmatch_loc.expected, others are set via MACE.
    signal actualValues : t_field_values;
    signal fieldMatch : std_logic_vector(29 downto 0) := (others => '1');
    signal allFieldsMatch : std_logic := '0';
    
    signal dataSeg0Del : std_logic_vector(63 downto 0);
    signal dataSeg1Del : std_logic_vector(63 downto 0);
    signal dataAligned : std_logic_vector(127 downto 0);
    signal dataAlignedValid : std_logic;
    signal dataAlignedmty : std_logic_vector(3 downto 0) := "0000";
    signal dataAlignedEOP : std_logic := '0';
    
    signal rxActive : std_logic := '0';  -- we are receiving a frame.
    signal rxCount : std_logic_vector(9 downto 0) := (others => '0'); -- which 128 bit word we are up to.
    signal dataAlignedCount : std_logic_vector(9 downto 0) := (others => '0');
    signal rxAlign : std_logic := '0'; 
    
    signal txCount : std_logic_vector(8 downto 0) := (others => '0');
    type t_tx_fsm is (idle, send_hdr, send_data);
    signal tx_fsm, tx_fsm_del1, tx_fsm_del2 : t_tx_fsm := idle;
    type t_rx_fsm is (idle, frame_start, start_lookup, wait_lookup, set_header, wait_done);
    signal rx_fsm : t_rx_fsm := idle;
    type t_stats_fsm is (idle, wait_good_packet, get_packet_count, check_packet_count, rd_out_of_order_count0, rd_out_of_order_count1, rd_out_of_order_count2, wr_out_of_order_count, wr_packet_count, wr_channel, wr_UNIXTime, wr_timestampLow, wr_timestampHigh, wr_synctimeLow, wr_synctimeHigh);
    signal stats_fsm : t_stats_fsm := idle;
    
    signal HdrBuf0 : std_logic_vector(59 downto 0);
    signal HdrBuf1 : std_logic_vector(59 downto 0);
    
    signal data_out_int : std_logic_vector(127 downto 0);
    signal valid_out_int : std_logic;
    
    signal wrBufSel : std_logic := '0';
    signal rdBufSel : std_logic := '0';
    signal tvalidDel : std_logic := '0';
    signal rxSOP : std_logic := '0';
    signal dataAligned2byte : std_logic_vector(15 downto 0);
    signal dataAlignedErr : std_logic;
    
    signal bufWE : std_logic_vector(0 downto 0);
    signal bufWrCount : std_logic_vector(9 downto 0);
    signal bufDin : std_logic_vector(127 downto 0);
    signal bufWrAddr, bufRdAddr : std_logic_vector(9 downto 0);
    signal data_clk_vec : std_logic_vector(0 downto 0);
    signal bufDout : std_logic_vector(127 downto 0);
    signal bufDinErr : std_logic := '0';
    signal bufDinEOP : std_logic := '0';
    signal bufDinGoodLength : std_logic := '0';

    signal vstats_field_wr : t_vstats_rw;
    signal vstats_field_ro :  t_vstats_ro;
    signal vstats_channelPower_in :  t_vstats_channelpower_ram_in;
    signal vstats_channelPower_out :  t_vstats_channelpower_ram_out;
    signal vstats_VHistogram_in : t_vstats_vhistogram_ram_in;
    signal vstats_VHistogram_out : t_vstats_vhistogram_ram_out; 
    
    signal searchAddr, searchAddrDel1, searchAddrDel2, searchAddr9bit : std_logic_vector(9 downto 0);
    signal searchRunning, searchRunningDel1, searchRunningDel2, searchRunningDel3 : std_logic;
    signal stationSel : std_logic;
    signal searchFailedDel1, searchFailed, searchFailedDel2 : std_logic;
    
    signal VirtualChannel : std_logic_vector(8 downto 0);
    signal searchDone : std_logic;
    signal NoMatch : std_logic;
    signal VirtualSearch : std_logic_vector(31 downto 0);
    
    signal badEthPacket, nonSPEADPacket, badIPUDPPacket, goodPacket, noVirtualChannel : std_logic := '0'; 
    signal stationID0base : std_logic_vector(9 downto 0);
    
    signal statsAddr : std_logic_vector(12 downto 0);
    signal statsBaseAddr : std_logic_Vector(12 downto 0);
    signal virtualChannelx8 : std_logic_vector(12 downto 0);
    signal statsWrData, statsNewPacketCount : std_logic_vector(31 downto 0) := x"00000000";
    signal statsNOFAntennas, statsSPEADLogicalChannel : std_logic_vector(15 downto 0);
    signal packetCountOutOfOrder : std_logic := '0';
    signal oldPacketCount : std_logic_vector(31 downto 0);
    signal oldOutOfOrderCount : std_logic_vector(3 downto 0);
    signal statsWE : std_logic := '0';
    
    signal dataAlignedSOP : std_logic := '0';
    signal statsSOPTime : t_wall_time;
    signal SOPTime : t_wall_time;
    signal tx_fsm_dbg, stats_fsm_dbg, rx_fsm_dbg : std_logic_vector(3 downto 0);
    signal goodPacket_dbg : std_logic;
    signal nonSPEADPacket_dbg : std_logic;
    signal VCTable_rd_data_del1 : std_logic_vector(31 downto 0);
    signal rxAlignOld : std_logic := '0';
    signal statsTimestamp, statsSyncTime : std_logic_vector(47 downto 0);

begin
    
    o_dbg <= nonSPEADPacket_dbg & goodPacket_dbg & rx_fsm_dbg & stats_fsm_dbg & tx_fsm_dbg;
    
    -- For data coming in from the 40G MAC, the only fields that are used are
    --  data_rx_sosi.tdata
    --  data_rx_sosi.tuser
    --  data_rx_sosi.tvalid
    -- segment 0 relates to data_rx_sosi.tdata(63:0)
    tuserSeg0.ena <= i_data_rx_sosi.tuser(56);
    tuserSeg0.sop <= i_data_rx_sosi.tuser(57);  -- start of packet
    tuserSeg0.eop <= i_data_rx_sosi.tuser(58);  -- end of packet
    tuserSeg0.mty <= i_data_rx_sosi.tuser(61 DOWNTO 59); -- number of unused bytes in segment 0, only used when eop0 = '1', ena0 = '1', tvalid = '1'. 
    tuserSeg0.err <= i_data_rx_sosi.tuser(62);  -- error reported by 40GE MAC (e.g. FCS, bad 64/66 bit block, bad packet length), only valid on eop0, ena0 and tvalid all = '1'
    -- segment 1 relates to data_rx_sosi.tdata(127:64)
    tuserSeg1.ena <= i_data_rx_sosi.tuser(63);
    tuserSeg1.sop <= i_data_rx_sosi.tuser(64);
    tuserSeg1.eop <= i_data_rx_sosi.tuser(65);
    tuserSeg1.mty <= i_data_rx_sosi.tuser(68 DOWNTO 66);
    tuserSeg1.err <= i_data_rx_sosi.tuser(69);
    --rx_preambleout  <= data_rx_sosi.tuser(55 DOWNTO 0);
    
    ------------------------------------------------------------------------------
    -- Capture and validate all the packet headers (MAC, IPv4, UDP, SPEAD)
    ------------------------------------------------------------------------------
    -- These fields go direct to the output packet header:
    --  - channel frequency. 9 bit value. Sky frequency = channel frequency * 781.25 hKHz = frequency_id as above (i.e. from SPEAD ID 0x3000)
    --  - station_id - 1, (Subtract 1 from station_id so it becomes a 9 bit value)
    --  - Packet count, from SPEAD ID 0x1
    
    process(i_data_clk, i_data_rst)
        variable allFieldsMatchv : std_logic := '0';
    begin
        if i_data_rst = '1' then
            wrBufSel <= '0';
            rdBufSel <= '0';
            rx_fsm <= idle;
        elsif rising_edge(i_data_clk) then
            -- Align the input so that start of packet is always in the first 64 bits
            if i_data_rx_sosi.tvalid = '1' then
                dataSeg0Del <= i_data_rx_sosi.tdata(63 downto 0);
                tuserSeg0Del <= tuserSeg0;
                dataSeg1Del <= i_data_rx_sosi.tdata(127 downto 64);
                tuserSeg1Del <= tuserSeg1;
            end if;
            if tuserSeg0.sop = '1' and i_data_rx_sosi.tvalid = '1' and tuserSeg0.ena = '1' then
                rxCount <= (others => '0'); -- which 128 bit word we are up to.
                rxAlign <= '0';   -- alignment of 0 means the start of packet occurred on segment 0.
                rxSOP <= '1';
            elsif tuserSeg1.sop = '1' and i_data_rx_sosi.tvalid = '1' and tuserSeg1.ena = '1' then
                rxCount <= (others => '0');
                rxAlign <= '1';   -- start of packet occurred on segment 1 
                rxSOP <= '1';
            elsif i_data_rx_sosi.tvalid = '1' and (tuserSeg0.ena = '1' or tuserSeg1.ena = '1') then
                rxCount <= std_logic_vector(unsigned(rxCount) + 1);
                rxSOP <= '0';
            else
                rxSOP <= '0';
            end if;
            tvalidDel <= i_data_rx_sosi.tvalid;
            
            -- Next pipeline stage; build the 16 byte data, aligned with the sof at byte 0. 
            -- Note that dataSeg0Del, dataSeg1Del are only loaded when tvalid = '1', so we only
            -- need to check i_data_rx_sosi.tvalid and start of frame to determine when dataAligned is valid.
            if rxAlign = '0' then
                dataAligned <= dataSeg1Del & dataSeg0Del;
                dataAlignedValid <= tvalidDel;
                if tuserSeg0Del.eop = '1' then -- dataAlignedmty = empty for the whole 16 bytes
                    dataAlignedmty <= '1' & tuserSeg0Del.mty;
                    dataAlignedEOP <= '1';
                    dataAlignedErr <= tuserSeg0Del.err;
                elsif tuserSeg1Del.eop = '1' then
                    dataAlignedmty <= '0' & tuserSeg1Del.mty;
                    dataAlignedEOP <= '1';
                    dataAlignedErr <= tuserSeg1Del.err;
                else
                    dataAlignedmty <= "0000";
                    dataAlignedEOP <= '0';
                    dataAlignedErr <= '0';
                end if;
            else
                dataAligned <= i_data_rx_sosi.tdata(63 downto 0) & dataSeg1Del;
                dataAlignedValid <= i_data_rx_sosi.tvalid and tuserSeg0.ena and (not tuserSeg0.sop);
                if tuserSeg1Del.eop = '1' then -- dataAlignedmty = empty for the whole 16 bytes
                    dataAlignedmty <= '1' & tuserSeg1Del.mty;
                    dataAlignedEOP <= '1';
                    dataAlignedErr <= tuserSeg1Del.err;
                elsif tuserSeg0.eop = '1' then
                    dataAlignedmty <= '0' & tuserSeg0.mty;
                    dataAlignedEOP <= '1';
                    dataAlignedErr <= tuserSeg0.err;
                else
                    dataAlignedmty <= "0000";
                    dataAlignedEOP <= '0';
                    dataAlignedErr <= '0';
                end if;
            end if;
            dataAlignedSOP <= rxSOP;
            dataAlignedCount <= rxCount;
            
            
            -- Data portion of the packet is written to the double buffer, with an appropriate alignment for the data.
            if ((unsigned(rxCount) = 7) and i_data_rx_sosi.tvalid = '1') then
                -- first word of samples to write to the buffer
                bufWE(0) <= '1';
                bufWrCount <= (others => '0');
                -- Once we get part way through the packet, we note the alignment used for this packet.
                -- This is needed because it is possible for a frame to end on segment 0 and a new frame
                -- to start on segment 1 on the same clock cycle. When this occurs, we need to use the old
                -- alignment for the data being written to the buffer, but the new alignment for capture of
                -- the header information in the new packet.
                rxAlignOld <= rxAlign;
                if rxAlign = '0' then
                    -- The data portion of the packet has a 2 byte offset relative to dataAligned
                    -- since the SPEAD data portion has a 2 byte offset relative to 8 byte boundaries.
                    bufDin <= i_data_rx_sosi.tdata(15 downto 0) & dataSeg1Del & dataSeg0Del(63 downto 16); 
                else
                    bufDin <= i_data_rx_sosi.tdata(79 downto 64) & i_data_rx_sosi.tdata(63 downto 0) & dataSeg1Del(63 downto 16);
                end if;
                bufDinEOP <= '0';
                bufDinErr <= '0';
                bufDinGoodLength <= '0';
            elsif ((unsigned(bufWrCount) < 511) and i_data_rx_sosi.tvalid = '1') then
                bufWE(0) <= '1';
                bufWrCount <= std_logic_vector(unsigned(bufWrCount) + 1);
                if rxAlignOld = '0' then  -- rxAlignHold holds over the alignment setting until the frame is complete.
                    bufDin <= i_data_rx_sosi.tdata(15 downto 0) & dataSeg1Del & dataSeg0Del(63 downto 16); -- data portion of the packet has a 2 byte offset relative to dataAligned.
                    if ((unsigned(bufWrCount) = 510) and (tuserSeg0Del.mty = "000" and tuserSeg1Del.mty = "000" and tuserSeg0.mty = "110")) then
                        bufDinGoodLength <= '1';
                    else
                        bufDinGoodLength <= '0';
                    end if;
                    if ((unsigned(bufWrCount) = 510) and (tuserSeg0.eop = '1')) then
                        bufDinEOP <= '1';
                    else
                        bufDinEOP <= '0';
                    end if; 
                    bufDinErr <= tuserSeg0.err;
                else
                    bufDin <= i_data_rx_sosi.tdata(79 downto 64) & i_data_rx_sosi.tdata(63 downto 0) & dataSeg1Del(63 downto 16);                    
                    if ((unsigned(bufWrCount) = 510) and (tuserSeg1Del.mty = "000" and tuserSeg0.mty = "000" and tuserSeg1.mty = "110")) then
                        bufDinGoodLength <= '1';
                    else
                        bufDinGoodLength <= '0';
                    end if;
                    if ((unsigned(bufWrCount) = 510) and (tuserSeg1.eop = '1')) then
                        bufDinEOP <= '1';
                    else
                        bufDinEOP <= '0';
                    end if; 
                    bufDinErr <= tuserSeg1.err;
                end if;
            else
                bufWE(0) <= '0';
                bufDinEOP <= '0';
                bufDinErr <= '0';
                bufDinGoodLength <= '0';
            end if;
            ------------------------------------------------------------------------------------------------
            -- Capture all the relevant fields in the headers 
            for i in 0 to (fieldsToMatch-1) loop
                if ((dataAlignedCount(9 downto 3) = "0000000") and 
                    (dataAlignedCount(2 downto 0) = c_fieldmatch_loc(i).wordcount) and 
                    (dataAlignedValid = '1')) then
                    -- Copy the bytes into the actualValues array, re-ordering so that the most significant byte has the highest index.
                    -- e.g. ethertype field goes from x0008 in dataAligned to x0800 in the actualValues array.
                    for j in 0 to (c_fieldmatch_loc(i).bytes-1) loop
                        actualValues(i)(((j+1) * 8 - 1) downto (j*8)) <= 
                            dataAligned(((c_fieldmatch_loc(i).byteOffset + c_fieldmatch_loc(i).bytes - j)*8 - 1) downto 
                                        ((c_fieldmatch_loc(i).byteOffset + c_fieldmatch_loc(i).bytes - j)*8 - 8));
                    end loop;
                end if;
            end loop;
            
            if dataAlignedSOP = '1' then
                SOPTime <= i_wallTime;
               -- SOPTimeFrac <= i_time_frac(26 downto 3);  -- units of 64 ns, counts 0 to 15624999
               -- SOPTimeInt <= i_time_sec;                 -- Unix time (seconds since 1970)
            end if;
            
            ------------------------------------------------------------------------------------------------
            -- Check all the relevant fields in the headers
            for i in 0 to (fieldsToMatch-1) loop
                if c_fieldmatch_loc(i).check = '1' then
                    if (actualValues(i)((c_fieldmatch_loc(i).bytes*8 - 1) downto 0) = c_fieldmatch_loc(i).expected((c_fieldmatch_loc(i).bytes*8 - 1) downto 0)) then
                        fieldMatch(i) <= '1';
                    else
                        fieldMatch(i) <= '0';
                    end if;
                else
                    fieldMatch(i) <= '1';
                end if;
            end loop;
            
            allFieldsMatchv := '1';
            for i in 0 to (fieldsToMatch-1) loop
                if fieldMatch(i) = '0' then
                    allFieldsMatchv := '0';
                end if;
            end loop;
            allFieldsMatch <= allFieldsMatchv;
            
            -----------------------------------------------------------------------------------------------
            -- Once we have captured the header information, trigger searching of the virtual channel table
            if rx_fsm = start_lookup then
                if (i_reg_rw.stationID1 = actualValues(c_station_id_index)(9 downto 0)) then
                    searchAddr <= (others => '0');
                    searchRunning <= '1';
                    stationSel <= '0';
                    searchFailed <= '0';
                elsif (i_reg_rw.stationID2 = actualValues(c_station_id_index)(9 downto 0)) then
                    searchAddr <= "1000000000";
                    searchRunning <= '1';
                    stationSel <= '1';
                    searchFailed <= '0';
                else
                    searchFailed <= '1';
                end if;
            elsif searchRunning = '1' then
                if unsigned(searchAddr9bit) < 383 then
                    searchAddr <= std_logic_vector(unsigned(searchAddr) + 1);
                else
                    searchRunning <= '0';
                end if;
            end if;
            
            -- two cycle latency reading from the virtual channel table
            searchAddrDel1 <= searchAddr;
            searchAddrDel2 <= searchAddrDel1;
            
            searchRunningDel1 <= searchRunning;
            searchRunningDel2 <= searchRunningDel1;
            searchRunningDel3 <= searchRunningDel2;
            
            searchFailedDel1 <= searchFailed;
            searchFailedDel2 <= searchFailedDel1;
            
            VCTable_rd_data_del1 <= i_VCTable_rd_data;
            
            if rx_fsm = start_lookup then
                VirtualChannel <= (others => '1');
                searchDone <= '0';
                NoMatch <= '1';
            elsif searchFailedDel2 = '1' or (searchDone = '0' and searchRunningDel2 = '0' and searchRunningDel3 = '1') then
                searchDone <= '1';
                NoMatch <= '1';
            elsif (searchDone = '0' and searchRunningDel2 = '1' and (VCTable_rd_data_del1 = VirtualSearch)) then
                virtualChannel <= searchAddrDel2(8 downto 0);
                searchDone <= '1';
                NoMatch <= '0';
            end if;
            
            ------------------------------------------------------------------------------------------------
            -- Packet Ingest FSM
            case rx_fsm is
                when idle =>
                    badEthPacket <= '0';   -- When the ethernet interface reports an error
                    nonSPEADPacket <= '0'; -- No errors, but either the wrong length, or not SPEAD
                    badIPUDPPacket <= '0'; -- Error in the UDP or IP headers
                    goodPacket <= '0';     -- Good SPEAD packet
                    noVirtualChannel <= '0'; -- Didn't find a matching virtual channel
                    rx_fsm_dbg <= "0000";
                    if dataAlignedSOP = '1' then
                        rx_fsm <= frame_start;
                    end if;
                    
                when frame_start =>
                    rx_fsm_dbg <= "0001";
                    goodPacket <= '0';
                    badEthPacket <= '0';
                    badIPUDPPacket <= '0';
                    -- Wait until we have captured all the header information, then start the lookup process
                    if dataAlignedEOP = '1' and dataAlignedSOP = '0' then
                        rx_fsm <= idle;
                        nonSPEADPacket <= '1';
                    elsif dataAlignedCount(9 downto 0) = "0000001010" and dataAlignedValid = '1' then
                        -- Waiting until dataAlignedCount is 10 ensures that the stats_fsm state machine from the previous packet is finished. 
                        rx_fsm <= start_lookup;
                        nonSPEADPacket <= '0';
                    else
                        nonSPEADPacket <= '0';
                    end if;
                    
                when start_lookup =>
                    rx_fsm_dbg <= "0010";
                    goodPacket <= '0';
                    badIPUDPPacket <= '0';
                    if dataAlignedSOP = '1' then
                        rx_fsm <= frame_start;
                        nonSPEADPacket <= '1';
                        badEthPacket <= '0';
                    elsif dataAlignedEOP = '1' then
                        rx_fsm <= idle;
                        if dataAlignedErr = '1' then
                            badEthPacket <= '1';
                            nonSPEADPacket <= '0';
                        else
                            nonSPEADPacket <= '1';
                            badEthPacket <= '0';
                        end if;
                    else
                        nonSPEADPacket <= '0';
                        badEthPacket <= '0';
                        rx_fsm <= wait_lookup;
                    end if;
                
                when wait_lookup =>
                    rx_fsm_dbg <= "0011";
                    goodPacket <= '0';
                    badIPUDPPacket <= '0';
                    if dataAlignedSOP = '1' then
                        rx_fsm <= frame_start;
                        badEthPacket <= '0';
                        nonSPEADPacket <= '1';
                    elsif dataAlignedEOP = '1' then
                        rx_fsm <= idle;
                        if dataAlignedErr = '1' then
                            badEthPacket <= '1';
                            nonSPEADPacket <= '0';
                        else
                            nonSPEADPacket <= '1';
                            badEthPacket <= '0';
                        end if;
                        noVirtualChannel <= '0';
                    elsif searchDone = '1' then
                        if NoMatch = '1' then
                            rx_fsm <= idle;
                            noVirtualChannel <= '1';
                            nonSPEADPacket <= '0';
                        elsif allFieldsMatch = '0' then
                            rx_fsm <= idle;
                            nonSPEADPacket <= '1';
                            noVirtualChannel <= '0';
                        else
                            nonSPEADPacket <= '0';
                            noVirtualChannel <= '0';
                            rx_fsm <= set_header;
                        end if;
                    end if;
                
                when set_header =>
                    rx_fsm_dbg <= "0100";
                    goodPacket <= '0';
                    badIPUDPPacket <= '0';
                    if dataAlignedSOP = '1' then
                        rx_fsm <= frame_start;
                        nonSPEADPacket <= '1';
                        badEthPacket <= '0';
                    elsif dataAlignedEOP = '1' then
                        rx_fsm <= idle;
                        if dataAlignedErr = '1' then
                            badEthPacket <= '1';
                            nonSPEADPacket <= '0';
                        else
                            nonSPEADPacket <= '1';
                            badEthPacket <= '0';
                        end if;
                    else
                        nonSPEADPacket <= '0';
                        badEthPacket <= '0';
                        rx_fsm <= wait_done;
                    end if;
                    if wrBufSel = '0' then
                        HdrBuf0(8 downto 0) <= virtualChannel;
                        HdrBuf0(17 downto 9) <= actualValues(c_frequency_id_index)(8 downto 0);
                        HdrBuf0(26 downto 18) <= stationID0base(8 downto 0);
                        HdrBuf0(58 downto 27) <= actualValues(c_packet_counter)(31 downto 0);  -- packet count
                        HdrBuf0(59) <= stationSel;
                    else
                        HdrBuf1(8 downto 0) <= virtualChannel;
                        HdrBuf1(17 downto 9) <= actualValues(c_frequency_id_index)(8 downto 0);
                        HdrBuf1(26 downto 18) <= stationID0base(8 downto 0);
                        HdrBuf1(58 downto 27) <= actualValues(c_packet_counter)(31 downto 0);  -- packet count
                        HdrBuf1(59) <= stationSel;
                    end if;
                    
                when wait_done =>
                    badIPUDPPacket <= '0';
                    rx_fsm_dbg <= "0101";
                    if bufDinEOP = '1' then
                        if (bufDinGoodLength = '1' and bufDinErr = '0') then 
                            -- Good frame received - correct length, no errors.
                            wrBufSel <= not wrBufSel;
                            rdBufSel <= wrBufSel;
                            goodPacket <= '1';
                            badEthPacket <= '0';
                            nonSPEADPacket <= '0';
                        else
                            goodPacket <= '0';
                            if bufDinErr = '1' then
                                badEthPacket <= '1';
                                nonSPEADPacket <= '0';
                            else
                                nonSPEADPacket <= '1';
                                badEthPacket <= '0';
                            end if;
                        end if;
                        if dataAlignedSOP = '1' then
                            rx_fsm <= frame_start;
                        else
                            rx_fsm <= idle;
                        end if;
                    elsif dataAlignedSOP = '1' then
                        rx_fsm <= frame_start;
                        goodPacket <= '0';
                        badEthPacket <= '0';
                        nonSPEADPacket <= '1';
                    else
                        goodPacket <= '0';
                        badEthPacket <= '0';
                        nonSPEADPacket <= '0';
                    end if;
                
                when others =>
                    rx_fsm <= idle;
            end case;
            
            -------------------------------------------------------------------------------------------------
            -- Channel Statistics FSM
            -- Writes to the VC_stats memory in the registers module.
            -- For each virtual channel and station, the stats memory has
            --   0. channel + nof_contributing antennas,
            --   1. most recent packet count            
            --   2. out of order count, fractional time
            --   3. Unix time
            --
            -- The state machine runs through linearly from "idle" to the end doing the following things
            --  idle               - wait until the search of the virtual channel table completes successfully.
            --  wait_good_packet   - Wait until the end of the ethernet frame so we know that we have received a good packet.
            --  get_packet_count   - read the previous packet count for this virtual channel
            --  check_packet_count - Compare previous with current packet count to see if it is out of order (should be previous value + 1)
            --  rd_out_of_order_count - read old count of out of order packets
            --  rd_out_of_order_count1
            --  rd_out_of_order_count2 - account for read latency of the memory. 
            --  wr_packet_count       - write the most recent packet count (stats memory address = VC*4 + 1)
            --  wr_out_of_order_count - write the new out_of_order_count in bits(7:0), and the fractional time for the packet reception in bits(31:8) (stats memory address = VC*4 + 2)
            --  wr_channel            - write SPEAD logical_channel (bits(15:0)) and SPEAD nof_contributing_antennas (bits(31:16)) (stats memory address = VC*4 + 0)
            --  wr_UNIXTime           - write the UNIX time for the packet reception (stats memory address = VC*4 + 3)
            --  
            case stats_fsm is
                when idle =>
                    stats_fsm_dbg <= "0000";
                    -- in this state, we wait for the lookup of the virtual channel to complete,
                    -- then grab the relevant information and go on to waiting to verify that this is a good SPEAD packet.
                    if rx_fsm = wait_lookup and searchDone = '1' and NoMatch = '0' then
                        stats_fsm <= wait_good_packet;
                        if stationSel = '0' then
                            statsBaseAddr <= VirtualChannelx8; -- address to read in the stats memory
                        else -- read address starts at 1536
                            statsBaseAddr <= std_logic_vector(3072 + unsigned(virtualChannelx8));
                        end if;
                        statsNewPacketCount <= actualValues(c_packet_counter)((c_fieldmatch_loc(c_packet_counter).bytes*8 - 1) downto 0);
                        statsSPEADLogicalChannel <= actualValues(c_SPEAD_logical_channel)((c_fieldmatch_loc(c_SPEAD_logical_channel).bytes*8 - 1) downto 0);
                        statsNOFAntennas <= actualValues(c_nof_antennas)((c_fieldmatch_loc(c_nof_antennas).bytes*8 - 1) downto 0);
                        
                        statsTimestamp(47 downto 16) <= actualValues(c_timestamp_high)(31 downto 0);  -- 4 high bytes
                        statsTimestamp(15 downto 0) <= actualValues(c_timestamp_low)(15 downto 0);     -- 2 low bytes
                        statsSyncTime(47 downto 0) <= actualValues(c_sync_time)(47 downto 0);
                        
                        statsSOPTime <= SOPTime;
                        
                    end if;
                    packetCountOutOfOrder <= '0';
                    statsWE <= '0';
                    
                when wait_good_packet => -- Note that if the packet is good, then this should take at least 10s of clock cycles.
                    stats_fsm_dbg <= "0001";
                    statsAddr <= std_logic_vector(unsigned(statsBaseaddr) + 1);  -- read the most recent packet number for this virtual channel
                    if goodPacket = '1' then
                        stats_fsm <= get_packet_count; 
                    elsif rx_fsm = idle or badEthPacket = '1' or nonSPEADPacket = '1' or badIPUDPPacket = '1' then
                        stats_fsm <= idle;
                    end if;
                   
                when get_packet_count => -- old packet count is in VCstats_ram_out.rd_dat in this state, since statsAddr has been held for many clocks.
                    stats_fsm_dbg <= "0010";
                    stats_fsm <= check_packet_count;
                    oldPacketCount <= i_statsRdData;
                    
                when check_packet_count =>
                    stats_fsm_dbg <= "0011";
                    if statsNewPacketCount /= std_logic_vector(unsigned(oldPacketCount) + 1) then
                        packetCountOutOfOrder <= '1';
                    else
                        packetCountOutOfOrder <= '0';
                    end if;
                    stats_fsm <= rd_out_of_order_count0;
                    statsAddr <= std_logic_vector(unsigned(statsBaseaddr) + 2); -- offset 2 in the 4 stats words per virtual channel = number of out of order packets.
                
                when rd_out_of_order_count0 =>
                    stats_fsm_dbg <= "0100";
                    stats_fsm <= rd_out_of_order_count1;
             
                when rd_out_of_order_count1 =>
                    stats_fsm_dbg <= "0101";
                    stats_fsm <= rd_out_of_order_count2;
                
                when rd_out_of_order_count2 =>
                    stats_fsm_dbg <= "0110";
                    oldOutOfOrderCount <= i_statsRdData(31 downto 28);
                    stats_fsm <= wr_out_of_order_count;

                when wr_out_of_order_count =>   -- out of order count is at address offset 2
                    stats_fsm_dbg <= "0111";
                    stats_fsm <= wr_packet_count;
                    -- statsAddr is unchanged from the read of the out of order count, at <base for this virtual channel>+1
                    statsAddr <= std_logic_vector(unsigned(statsBaseaddr) + 2);
                    if packetCountOutOfOrder = '1' then
                        statsWrData(31 downto 28) <= std_logic_vector(unsigned(oldOutOfOrderCount) + 1);
                    else
                        statsWrData(31 downto 28) <= oldOutOfOrderCount;
                    end if;
                    statsWrData(27 downto 0) <= statsSOPTime.ns(29 downto 2); -- Recorded value is in units of 4 ns
                    statsWE <= '1';
                    
                when wr_packet_count =>   -- packet count is at address offset 1
                    stats_fsm_dbg <= "1000";
                    stats_fsm <= wr_channel;
                    statsAddr <= std_logic_vector(unsigned(statsBaseaddr) + 1);
                    statsWrData <= statsNewPacketCount;
                    statsWE <= '1';
                    
                when wr_channel =>   -- channel is at address offset 0
                    stats_fsm_dbg <= "1001";
                    stats_fsm <= wr_UNIXTime;
                    statsAddr <= statsBaseaddr;
                    statsWrData <= statsNOFAntennas & statsSPEADLogicalChannel;
                    statsWE <= '1';
                
                when wr_UNIXTime =>  -- UNIX time is at address offset 3
                    stats_fsm_dbg <= "1010";
                    stats_fsm <= wr_timestampLow;
                    statsAddr <= std_logic_vector(unsigned(statsBaseaddr) + 3);
                    statsWrData <= statsSOPTime.sec;
                    statsWE   <= '1';
                
                when wr_timestampLow =>
                    stats_fsm_dbg <= "1011";
                    stats_fsm <= wr_timestampHigh;
                    statsAddr <= std_logic_vector(unsigned(statsBaseaddr) + 4);
                    statsWrData <= statsTimestamp(31 downto 0);
                    statsWE   <= '1';
                
                when wr_timestampHigh =>
                    stats_fsm_dbg <= "1100";
                    stats_fsm <= wr_synctimeLow;
                    statsAddr <= std_logic_vector(unsigned(statsBaseaddr) + 5);
                    statsWrData <= x"0000" & statsTimestamp(47 downto 32);
                    statsWE   <= '1';
                
                when wr_synctimeLow =>
                    stats_fsm_dbg <= "1101";
                    stats_fsm <= wr_synctimeHigh;
                    statsAddr <= std_logic_vector(unsigned(statsBaseaddr) + 6);
                    statsWrData <= statsSyncTime(31 downto 0);
                    statsWE   <= '1';
                
                when wr_synctimeHigh =>
                    stats_fsm_dbg <= "1110";
                    stats_fsm <= idle;
                    statsAddr <= std_logic_vector(unsigned(statsBaseaddr) + 7);
                    statsWrData <= x"0000" & statsSyncTime(47 downto 32);
                    statsWE   <= '1';
                
                when others =>
                    stats_fsm <= idle;
            end case;
            
            
            -------------------------------------------------------------------------------------------------
            -- Packet readout FSM
            -- Note this is only triggered if the input packet was good, so there cannot be errors here.
            -- In particular, short frames are not forwarded, so this fsm can only be started in the idle state. 
            case tx_fsm is
                when idle =>
                    tx_fsm_dbg <= "0000";
                    if goodPacket = '1' then
                        tx_fsm <= send_hdr;
                    end if;
                    txCount <= (others => '0'); -- Note - 513 transfers in each output packet.
                    
                when send_hdr =>
                    tx_fsm_dbg <= "0001";
                    tx_fsm <= send_data;
                    txCount <= (others => '0');
                    
                when send_data =>
                    tx_fsm_dbg <= "0010";
                    if (unsigned(txCount) = 511) then
                        tx_fsm <= idle;
                    end if;
                    txCount <= std_logic_vector(unsigned(txCount) + 1);
                    
                when others =>
                    tx_fsm <= idle;
            end case;
            
            tx_fsm_del1 <= tx_fsm;
            tx_fsm_del2 <= tx_fsm_del1;
            
            if tx_fsm_del2 = send_hdr then
                if rdBufSel = '0' then
                    data_out_int(59 downto 0) <= HdrBuf0;
                else
                    data_out_int(59 downto 0) <= HdrBuf1;
                end if;
                data_out_int(127 downto 60) <= (others => '0');
                valid_out_int <= '1';
            elsif tx_fsm_del2 = send_data then
                data_out_int <= bufDout;
                valid_out_int <= '1';
            else
                data_out_int <= (others => '0');
                valid_out_int <= '0';
            end if;
            
            goodPacket_dbg <= goodPacket;
            nonSPEADPacket_dbg <= nonSPEADPacket;
            
        end if;
    end process;
    
    o_data_out <= data_out_int;
    o_valid_out <= valid_out_int;
    
    searchAddr9bit <= '0' & searchAddr(8 downto 0);
    
    VirtualSearch(8 downto 0) <= actualValues(c_frequency_id_index)(8 downto 0);
    VirtualSearch(12 downto 9) <= actualValues(c_beam_id_index)(3 downto 0);
    VirtualSearch(15 downto 13) <= actualValues(c_substation_id_index)(2 downto 0);
    VirtualSearch(20 downto 16) <= actualValues(c_subarray_id_index)(4 downto 0);
    VirtualSearch(30 downto 21) <= actualValues(c_station_id_index)(9 downto 0);
    VirtualSearch(31) <= '0';
    virtualChannelx8 <= '0' & virtualChannel & "000";
    
    stationID0base <= std_logic_vector(unsigned(actualValues(c_station_id_index)(9 downto 0)) - 1); -- station ID in the packet is range 0-511, SPEAD version is range 1 to 512..
    
    bufWrAddr <= wrBufSel & bufWrCount(8 downto 0);
    bufRdAddr <= rdBufSel & txCount;
    
    o_reg_count.spead_packet_count <= goodPacket;
    o_reg_count.nonspead_packet_count <= nonSPEADPacket;
    o_reg_count.badethernetframes <= badEthPacket;
    o_reg_count.badipudpframes <= badIPUDPPacket;
    o_reg_count.novirtualchannelcount <= noVirtualChannel;
    
    o_searchAddr <= searchAddr;
    o_statsAddr <= statsAddr;
    o_statsWE <= statsWE;
    o_statsWrData <= statsWrData;
    -----------------------------------------------------------------------------
    -- Capture the data part of the packet
    ----------------------------------------------------------------------------- 
    -- Data is double buffered.
    -- Implemented in a single memory, 128 bits wide x 1024 deep
    -- Each buffer uses exactly half the memory (512 entries). Note 512 x 128 bits =  8192 bytes = data part of an input packet
    -- xpm_memory_sdpram: Simple Dual Port RAM
    -- Xilinx Parameterized Macro, Version 2017.4
    xpm_memory_sdpram_inst : xpm_memory_sdpram
    generic map (    
        -- Common module generics
        MEMORY_SIZE             => 131072,           -- Total memory size in bits; 1024 x 128 = 
        MEMORY_PRIMITIVE        => "block",         --string; "auto", "distributed", "block" or "ultra" ;
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
        WRITE_DATA_WIDTH_A      => 128,             --positive integer
        BYTE_WRITE_WIDTH_A      => 128,             --integer; 8, 9, or WRITE_DATA_WIDTH_A value
        ADDR_WIDTH_A            => 10,              --positive integer
    
        -- Port B module generics
        READ_DATA_WIDTH_B       => 128,            --positive integer
        ADDR_WIDTH_B            => 10,             --positive integer
        READ_RESET_VALUE_B      => "0",            --string
        READ_LATENCY_B          => 2,              --non-negative integer
        WRITE_MODE_B            => "no_change")    --string; "write_first", "read_first", "no_change" 
    port map (
        -- Common module ports
        sleep                   => '0',
        -- Port A (Write side)
        clka                    => i_data_clk,
        ena                     => '1',
        wea                     => bufWE,
        addra                   => bufWrAddr,
        dina                    => bufDin,
        injectsbiterra          => '0',
        injectdbiterra          => '0',
        -- Port B (read side)
        clkb                    => i_data_clk,
        rstb                    => '0',
        enb                     => '1',
        regceb                  => '1',
        addrb                   => bufRdAddr,
        doutb                   => bufDout,
        sbiterrb                => open,
        dbiterrb                => open
    );


end Behavioral;
