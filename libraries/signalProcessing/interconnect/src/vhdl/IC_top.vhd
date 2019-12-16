----------------------------------------------------------------------------------
-- Company: CSIRO 
-- Engineer: David Humphrey (dave.humphrey@csiro.au)
-- 
-- Create Date: 02.04.2019 13:40:03
-- Module Name: InterconnectTop - Behavioral
-- Description: 
--  Route packets to the correct destination.
--  Each packet source is either a GTY, or the signal processing chain.
--  Each packet destination is either a GTY, or the signal processing chain.
-- 
----------------------------------------------------------------------------------
library IEEE, common_lib, axi4_lib, interconnect_lib, DSP_top_lib, ctc_lib;
--use ctc_lib.ctc_pkg.all;
use DSP_top_lib.DSP_top_pkg.all;
use common_lib.common_pkg.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use axi4_lib.axi4_lite_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
Library xpm;
use xpm.vcomponents.all;
USE interconnect_lib.interconnect_reg_pkg.ALL;

entity IC_Top is
    generic (
        ARRAYRELEASE : integer range 0 to 5 := 0 
    );
    port (
        -- source IP address to use for debug packets
        i_srcIPAddr : in std_logic_vector(31 downto 0);
        i_srcIPAddr_clk : in std_logic;
        -- Packets from GTYs.
        -- All GTYs send data in on the same clock.
        i_IC_clk : in std_logic;
        i_IC_rst : in std_logic_vector(31 downto 0);
        -- Wall time is used to timestamp incoming packets. This is only used for timing packets.
        i_wallTime : in t_wall_time;  -- seconds since 1970
        -- XYZ interconnect inputs
        i_gtyZdata  : in t_slv_64_arr(6 downto 0);
        i_gtyZValid : in std_logic_vector(6 downto 0);
        i_gtyZSof   : in std_logic_vector(6 downto 0);
        i_gtyZEof   : in std_logic_vector(6 downto 0);
        i_gtyYdata  : in t_slv_64_arr(4 downto 0);
        i_gtyYValid : in std_logic_vector(4 downto 0);
        i_gtyYSof   : in std_logic_vector(4 downto 0);
        i_gtyYEof   : in std_logic_vector(4 downto 0);
        i_gtyXdata  : in t_slv_64_arr(4 downto 0);
        i_gtyXValid : in std_logic_vector(4 downto 0);
        i_gtyXSof   : in std_logic_vector(4 downto 0);
        i_gtyXEof   : in std_logic_vector(4 downto 0);
        -------------------------------------------------
        -- Signal chain inputs 
        -- 1. LFAA ingest pipeline
        i_LFAAingest_data : in std_logic_vector(127 downto 0);
        i_LFAAingest_valid : in std_logic;
        i_LFAAingest_clk : in std_logic;
        -- 2. 
        -------------------------------------------------
        -- XYZ interconnect outputs
        o_gtyZData : out t_slv_64_arr(6 downto 0);
        o_gtyZValid : out std_logic_vector(6 downto 0);
        o_gtyYData : out t_slv_64_arr(4 downto 0);
        o_gtyYValid : out std_logic_vector(4 downto 0);
        o_gtyXData : out t_slv_64_arr(4 downto 0);
        o_gtyXValid : out std_logic_vector(4 downto 0);
        -------------------------------------------------
        -- Signal chain outputs
        -- 1. timing
        o_timingData  : out std_logic_vector(63 downto 0);
        o_timingValid : out std_logic;
        -- 2. Coarse Corner Turn
        o_CTCData : out std_logic_vector(63 downto 0);
        o_CTCSOP  : out std_logic;
        o_CTCValid : out std_logic;
        --------------------------------------------------
        -- 25 GE debug port
        o_dbg25GE : out t_axi4_sosi;   -- Note that the valid signal should be high for the entire packet (only the core can stall).
        i_dbg25GE : in  t_axi4_siso;
        i_dbg25GE_clk : in std_logic;
        --------------------------------------------------
        -- Registers AXI Lite Interface
        i_s_axi_mosi     : in t_axi4_lite_mosi;
        o_s_axi_miso     : out t_axi4_lite_miso;
        i_s_axi_clk      : in std_logic;
        i_s_axi_rst      : in std_logic       
    );
end IC_Top;

architecture Behavioral of IC_Top is
    
    -- interconnect input ports are indexed with a 5 bit value.
    -- These are used to keep track of which input port data comes from
    -- Note : 7 Z connections, only the first is listed as a constant, the rest are derived by adding 0 to 6.
    constant inputPortZ0 : std_logic_vector(4 downto 0) := "00000";
    -- Note : 5 Y connections, only the first is listed as a constant, the rest are derived by adding 0 to 4. 
    constant inputPortY0 : std_logic_vector(4 downto 0) := "00111";
    -- Note : 5 X connections, only the first is listed as a constant, the rest are derived by adding 0 to 4.
    constant inputPortX0 : std_logic_vector(4 downto 0) := "01100";
    
    constant inputPortTiming : std_logic_vector(4 downto 0) := "10001";
    constant inputPortLFAA1 : std_logic_vector(4 downto 0) := "10010";
    constant inputPortLFAA2 : std_logic_vector(4 downto 0) := "10011";
    
    type array7x12bit_type is array(6 downto 0) of std_logic_vector(11 downto 0);
    signal ZdestArray : array7x12bit_type;
    type array5x12bit_type is array(4 downto 0) of std_logic_vector(11 downto 0);
    signal YdestArray : array5x12bit_type;
    signal XdestArray : array5x12bit_type;
    type array24x21bit_type is array(23 downto 0) of std_logic_vector(20 downto 0);
    signal NotifyBlockPortData : array24x21bit_type;
    signal NotifyBlockPortValid : std_logic_vector(23 downto 0);
    signal NotifyBlockPortRead : std_logic_vector(23 downto 0);
    constant totalInputPorts : integer := 24;
    
    signal notifyCheckCount : std_logic_vector(4 downto 0);
    signal notifyCheckCountDel1 : std_logic_vector(4 downto 0);
    
    signal gtyXYZData : t_slv_64_arr(16 downto 0);
    signal gtyXYZValid : std_logic_vector(16 downto 0);
    signal gtyXYZSof : std_logic_vector(16 downto 0);
    signal gtyXYZEof : std_logic_vector(16 downto 0);
    
    signal ICData : t_slv_64_arr(31 downto 0); 
    signal ICOutputMux : t_slv_5_arr(31 downto 0);
    signal ICValid : std_logic_vector(31 downto 0);

    signal statPacketDrop : std_logic_vector(31 downto 0);
    signal statBadFCS : std_logic_vector(31 downto 0);
    signal statGoodPacket : std_logic_vector(31 downto 0);
    signal statUnroutable : std_logic_vector(31 downto 0);
    signal statFIFOFull : std_logic_vector(31 downto 0);

    signal LFAAData1, LFAAData2 : std_logic_vector(63 downto 0);
    signal LFAAValid1, LFAAsof1, LFAAeof1, LFAAValid2, LFAAsof2, LFAAeof2 : std_logic;
    signal statLFAADrop, statLFAAOverflow : std_logic;
    
    signal statmuxFifoFull : std_logic_vector(31 downto 0);
    signal statmuxPortInvalid : std_logic_vector(31 downto 0);
    signal requestBlock : t_slv_5_arr(31 downto 0);
    signal requestPort : t_slv_5_arr(31 downto 0);
    signal requestValid : std_logic_vector(31 downto 0);

    signal notifyPortDataSel : std_logic_vector(20 downto 0);
    signal notifyPortValidSel : std_logic;

    signal wallTimeSend : std_logic := '0';
    signal wallTimeHold : std_logic_vector(58 downto 0);
    signal wallTimeICClk : std_logic_vector(58 downto 0);
    signal walltimeRcv  : std_logic;
    signal wallTimeICClkValid : std_logic;
    
    signal statInBufErrors : t_slv_16_arr(19 downto 0);
    signal clrInBufErrors : std_logic;
    
    signal clrMuxErrors : std_logic;
    signal MuxErrCounts : t_slv_8_arr(19 downto 0);

    signal st_clk_ic : std_logic_vector(0 downto 0);
    signal st_rst_ic : std_logic_vector(0 downto 0);
    signal reg_rw : t_icstatctrl_rw;
    signal reg_ro : t_icstatctrl_ro;
    signal reg_count : t_icstatctrl_count;
    signal count_rsti : std_logic;
    signal wallTimeSendDel1 : std_logic;
    signal nullWallTime : t_wall_time;
    signal dbgSrcMAC : std_logic_vector(47 downto 0);
    signal dbgDestMAC : std_logic_vector(47 downto 0);
    
begin
    
    nullWallTime.sec <= (others => '0');
    nullWallTime.ns <= (others => '0');
    
    -------------------------------------------------------------------------------
    -- Input ports 
    -------------------------------------------------------------------------------
    -- Input side ports are indexed (i.e. the i_myPort signal on each instance of IC_URAMBuffer):
    --  0-6   = Z connect
    --  7-11  = Y connect
    --  12-16 = X connect
    --  17    = Timing
    --  18    = LFAA1
    --  19    = LFAA2
    
    reg_ro.Z0_in_Buf_Errors <= statInBufErrors(0);
    reg_ro.Z1_in_Buf_Errors <= statInBufErrors(1);
    reg_ro.Z2_in_Buf_Errors <= statInBufErrors(2);
    reg_ro.Z3_in_Buf_Errors <= statInBufErrors(3);
    reg_ro.Z4_in_Buf_Errors <= statInBufErrors(4);
    reg_ro.Z5_in_Buf_Errors <= statInBufErrors(5);
    reg_ro.Z6_in_Buf_Errors <= statInBufErrors(6);

    reg_ro.Y0_in_Buf_Errors <= statInBufErrors(7);
    reg_ro.Y1_in_Buf_Errors <= statInBufErrors(8);
    reg_ro.Y2_in_Buf_Errors <= statInBufErrors(9);
    reg_ro.Y3_in_Buf_Errors <= statInBufErrors(10);
    reg_ro.Y4_in_Buf_Errors <= statInBufErrors(11);
    
    reg_ro.X0_in_Buf_Errors <= statInBufErrors(12);
    reg_ro.X1_in_Buf_Errors <= statInBufErrors(13);
    reg_ro.X2_in_Buf_Errors <= statInBufErrors(14);
    reg_ro.X3_in_Buf_Errors <= statInBufErrors(15);
    reg_ro.X4_in_Buf_Errors <= statInBufErrors(16);
    
    reg_ro.LFAA0_in_Buf_Errors <= statInBufErrors(17);
    reg_ro.LFAA1_in_Buf_Errors <= statInBufErrors(18);
    
    clrInBufErrors <= reg_rw.IC_Buf_error_reset;
    clrMuxErrors <= reg_rw.IC_Mux_error_reset;
    
    Zgen : for Zi in 0 to 6 generate
        gtyXYZData(Zi) <= i_gtyZData(Zi);
        gtyXYZValid(Zi) <= i_gtyZValid(Zi);
        gtyXYZSof(Zi) <= i_gtyZSof(Zi);
        gtyXYZEof(Zi) <= i_gtyZEof(Zi);
    end generate;
    
    Ygen : for Yi in 0 to 4 generate
        gtyXYZData(7+Yi) <= i_gtyYData(Yi);
        gtyXYZValid(7+Yi) <= i_gtyYValid(Yi);
        gtyXYZSof(7+Yi) <= i_gtyYSof(Yi);
        gtyXYZEof(7+Yi) <= i_gtyYEof(Yi);
    end generate;
    
    Xgen : for Xi in 0 to 4 generate
        gtyXYZData(12+Xi) <= i_gtyYData(Xi);
        gtyXYZValid(12+Xi) <= i_gtyYValid(Xi);
        gtyXYZSof(12+Xi) <= i_gtyYSof(Xi);
        gtyXYZEof(12+Xi) <= i_gtyYEof(Xi);
    end generate;
    
    
    XYZinGen : for XYZin in 0 to 16 generate   -- 17 input ports, 7 + 5 + 5 for Z,Y,X links respectively.
        XYZins : entity interconnect_lib.IC_URAMBuffer -- interconnect_lib.IC_URAMBuffer
        generic map (
            -- 0 = 3 FPGAs (X x Y x Z = 1x1x3), 1 = 12 FPGAs (X x Y x Z = 1x6x2), 2 = etc....
            -- See confluence page (perentie -> Model development -> packetised model overview -> model configuration)    
            ARRAYRELEASE => ARRAYRELEASE, -- : integer 0 to 5 := 0;
            GENERATEFCS => '0', -- if '1', then generate the FCS here. if '0' then check the FCS.
            URAMBLOCKS  => 1  -- : integer 1 to 2 := 1
        ) port map (
            -- Everything is on a single clock (about 400 MHz)
            i_IC_clk => i_IC_clk, -- in std_logic;
            i_rst    => i_IC_rst(XYZin), -- in std_logic;
            -- Configuration information
            i_myAddr => reg_rw.myAddr, -- X,Y and Z coordinates of this FPGA in the array (needed for routing).
            i_myPort => std_logic_vector(to_unsigned(XYZin,5)),  -- in std_logic_vector(4 downto 0); -- unique ID for this input port in the interconnect. 
            -- Wall time is used to timestamp incoming packets. This is only used for timing packets.
            i_wallTime => i_wallTime,   -- in t_wall_time;
            -- Packet Data input
            -- Note : When generating the FCS, there must be at least one cycle between packets with i_valid low,
            -- in order to allow time to insert the FCS word.
            i_data  => gtyXYZData(XYZin),  -- in (63:0); 
            i_valid => gtyXYZValid(XYZin), -- in std_logic;
            i_sof   => gtyXYZSof(XYZin),   -- in std_logic;
            i_eof   => gtyXYZEof(XYZin),   -- in std_logic;
            -- Notification to destination ports of packets being available.
            o_blockPort      => NotifyBlockPortData(XYZin),  -- out std_logic_vector(20 downto 0); -- Destination port address (bits(15:0)), buffer block (bits(20:16))
            o_blockPortValid => NotifyBlockPortValid(XYZin), -- out std_logic;
            i_blockPortRead  => NotifyBlockPortRead(XYZin),  -- in std_logic;
            -------------------
            -- data packets out
            -- Requests in from the destination ports
            i_block => requestBlock,  -- in t_slv_5_arr(31:0); -- Each destination port provides a 5 bit vector to specify the block it wants a frame from.
            i_port  => requestPort,   -- in t_slv_5_arr(31:0); -- The port that data is being requested from (compared internally with i_myPort)
            i_blockReq => requestValid, -- in std_logic_vector(31 downto 0); -- One request line for each destination port. 
            -- The packets
            o_data  => ICData(XYZin),  -- out std_logic_vector(63 downto 0);
            o_outputMux => ICOutputMux(XYZin), -- out std_logic_vector(4 downto 0); -- the output mux that this packet is being sent to.
            o_valid => ICValid(XYZin), -- out std_logic;
            -- status
            o_goodPacket     => statGoodPacket(XYZin), -- out std_logic;  -- Valid packet was received (either FCS was good, or FCS checking not enabled).
            i_clrErrorCounts => clrInBufErrors,          -- in std_logic;   -- reset o_errorCounts and o_SingleHopSrcDest
            -- The 4 bit counters that make up o_errorCounts have a 3 bit counter, with the 4th bit used to indicate any occurence of the condition.
            o_errorCounts    => statInBufErrors(XYZin)   -- out(15:0) -- (3:0) = packet drop count, (7:4) = bad FCS count, (11:8) = unroutable count, (15:12) = Notification fifoFull count
        );
    end generate;
    
    
    LFAAInput : entity interconnect_lib.IC_LFAAInput -- interconnect_lib.IC_LFAAInput
    generic map (
        -- 0 = 3 FPGAs (X x Y x Z = 1x1x3), 1 = 12 FPGAs (X x Y x Z = 1x6x2), 2 = etc....
        -- See confluence page (perentie - Model development - packetised model overview - model configuration)    
        ARRAYRELEASE => ARRAYRELEASE)
    port map (
        -- Configuration (on i_IC_clk)
        i_myAddr => reg_rw.myAddr,  -- in(11:0);  -- X,Y and Z coordinates of this FPGA in the array (needed for routing).
        -- Packet Data input
        i_data     => i_LFAAIngest_data,  -- in(127:0);
        i_valid    => i_LFAAIngest_valid, -- in std_logic;
        i_data_clk => i_LFAAIngest_clk,   -- in std_logic;  -- LFAA ingest pipeline clock; 312.5 MHz, from the 40GE input
        -- Packets output.
        -- Two output interfaces, one for even and one for odd indexed virtual channels.
        i_IC_clk => i_IC_clk, --  in std_logic;     -- Interconnect clock (about 400 MHz)
        o_data1  => LFAAData1,  -- out std_logic_vector(63 downto 0);
        o_valid1 => LFAAValid1, -- out std_logic;
        o_sof1   => LFAAsof1,   -- out std_logic;
        o_eof1   => LFAAeof1,   -- out std_logic;
        o_data2  => LFAAData2,  -- out (63:0);
        o_valid2 => LFAAValid2, -- out std_logic;
        o_sof2   => LFAAsof2,   -- out std_logic;
        o_eof2   => LFAAeof2,   -- out std_logic;
        -- status
        o_LFAADrop => statLFAADrop,    -- out std_logic; -- input packet from LFAA was dropped since neither FIFO was empty; should be impossible.
        o_overflow => statLFAAOverflow -- out std_logic
    );
    
    
    LFAABuf1 : entity interconnect_lib.IC_URAMBuffer -- interconnect_lib.IC_URAMBuffer
    generic map (
        -- 0 = 3 FPGAs (X x Y x Z = 1x1x3), 1 = 12 FPGAs (X x Y x Z = 1x6x2), 2 = etc....
        -- See confluence page (perentie -> Model development -> packetised model overview -> model configuration)    
        ARRAYRELEASE => ARRAYRELEASE, -- : integer 0 to 5 := 0;
        GENERATEFCS => '1', -- if '1', then generate the FCS here. if '0' then check the FCS.
        URAMBLOCKS  => 1  -- : integer 1 to 2 := 1
    ) port map (
        -- Everything is on a single clock (about 400 MHz)
        i_IC_clk => i_IC_clk, -- in std_logic;
        i_rst    => i_IC_rst(17), -- in std_logic;
        -- Configuration information
        i_myAddr => reg_rw.myAddr,  -- X,Y and Z coordinates of this FPGA in the array (needed for routing).
        i_myPort => inputPortLFAA1, -- in std_logic_vector(4 downto 0); -- unique ID for this input port in the interconnect. 
        -- Wall time is used to timestamp incoming packets. This is only used for timing packets. 
        i_wallTime => nullwallTime, -- in t_wall_time; No timing packets can come through this input buffer, only LFAA data.
        -- Packet Data input
        -- Note : When generating the FCS, there must be at least one cycle between packets with i_valid low,
        -- in order to allow time to insert the FCS word.
        i_data  => LFAAData1,  -- in (63:0); 
        i_valid => LFAAValid1, -- in std_logic;
        i_sof   => LFAAsof1,   -- in std_logic;
        i_eof   => LFAAeof1,   -- in std_logic;
        -- Notification to destination ports of packets being available.
        o_blockPort      => NotifyBlockPortData(to_integer(unsigned(inputPortLFAA1))),  -- out(20:0); -- Destination port address (bits(15:0)), buffer block (bits(20:16))
        o_blockPortValid => NotifyBlockPortValid(to_integer(unsigned(inputPortLFAA1))), -- out std_logic;
        i_blockPortRead  => NotifyBlockPortRead(to_integer(unsigned(inputPortLFAA1))),  -- in std_logic;
        -------------------
        -- data packets out
        -- Requests in from the destination ports
        i_block => requestBlock,  -- in array32x5bit_type;     -- Each destination port provides a 5 bit vector to specify the block it wants a frame from.
        i_port  => requestPort,   -- in array32x5bit_type;     -- The port that data is being requested from (compared internally with i_myPort)
        i_blockReq => requestValid, -- in std_logic_vector(31 downto 0); -- One request line for each destination port. 
        -- The packets
        o_data  => ICData(to_integer(unsigned(inputPortLFAA1))),  -- out(63:0);
        o_outputMux => ICOutputMux(to_integer(unsigned(inputPortLFAA1))), -- out(4:0); -- the start block that the packet is being read from.
        o_valid => ICValid(to_integer(unsigned(inputPortLFAA1))), -- out std_logic;
        -- status
        o_goodPacket     => statGoodPacket(to_integer(unsigned(inputPortLFAA1))), -- out std_logic;  -- Valid packet was received (either FCS was good, or FCS checking not enabled).
        i_clrErrorCounts => clrInBufErrors,          -- in std_logic;   -- reset o_errorCounts and o_SingleHopSrcDest
        -- The 4 bit counters that make up o_errorCounts have a 3 bit counter, with the 4th bit used to indicate any occurence of the condition.
        o_errorCounts    => statInBufErrors(to_integer(unsigned(inputPortLFAA1)))   -- out(15:0) -- (3:0) = packet drop count, (7:4) = bad FCS count, (11:8) = unroutable count, (15:12) = Notification fifoFull count
    );

    LFAABuf2 : entity interconnect_lib.IC_URAMBuffer -- interconnect_lib.IC_URAMBuffer
    generic map (
        -- 0 = 3 FPGAs (X x Y x Z = 1x1x3), 1 = 12 FPGAs (X x Y x Z = 1x6x2), 2 = etc....
        -- See confluence page (perentie -> Model development -> packetised model overview -> model configuration)    
        ARRAYRELEASE => ARRAYRELEASE, -- : integer 0 to 5 := 0;
        GENERATEFCS => '1', -- if '1', then generate the FCS here. if '0' then check the FCS.
        URAMBLOCKS  => 1  -- : integer 1 to 2 := 1
    ) port map (
        -- Everything is on a single clock (about 400 MHz)
        i_IC_clk => i_IC_clk, -- in std_logic;
        i_rst    => i_IC_rst(18), -- in std_logic;
        -- Configuration information
        i_myAddr => reg_rw.myAddr,  -- X,Y and Z coordinates of this FPGA in the array (needed for routing).
        i_myPort => inputPortLFAA2, -- in(4:0); -- unique ID for this input port in the interconnect. 
        -- Wall time is used to timestamp incoming packets. This is only used for timing packets. 
        i_wallTime => nullwallTime, -- in t_wall_time; No timing packets can come through this input buffer, only LFAA data.
        -- Packet Data input
        -- Note : When generating the FCS, there must be at least one cycle between packets with i_valid low,
        -- in order to allow time to insert the FCS word.
        i_data  => LFAAData2,  -- in (63:0); 
        i_valid => LFAAValid2, -- in std_logic;
        i_sof   => LFAAsof2,   -- in std_logic;
        i_eof   => LFAAeof2,   -- in std_logic;
        -- Notification to destination ports of packets being available.
        o_blockPort      => NotifyBlockPortData(to_integer(unsigned(inputPortLFAA2))),  -- out std_logic_vector(20 downto 0); -- Destination port address (bits(15:0)), buffer block (bits(20:16))
        o_blockPortValid => NotifyBlockPortValid(to_integer(unsigned(inputPortLFAA2))), -- out std_logic;
        i_blockPortRead  => NotifyBlockPortRead(to_integer(unsigned(inputPortLFAA2))),  -- in std_logic;
        -------------------
        -- data packets out
        -- Requests in from the destination ports
        i_block => requestBlock,  -- in array32x5bit_type; Each destination port provides a 5 bit vector to specify the block it wants a frame from.
        i_port  => requestPort,   -- in array32x5bit_type; The port that data is being requested from (compared internally with i_myPort)
        i_blockReq => requestValid, -- in(31:0); One request line for each destination port. 
        -- The packets
        o_data  => ICData(to_integer(unsigned(inputPortLFAA2))),  -- out(63:0);
        o_outputMux => ICOutputMux(to_integer(unsigned(inputPortLFAA2))), -- out(4:0); The start block that the packet is being read from.
        o_valid => ICValid(to_integer(unsigned(inputPortLFAA2))), -- out std_logic;
        -- status
        o_goodPacket     => statGoodPacket(to_integer(unsigned(inputPortLFAA2))), -- out std_logic;  -- Valid packet was received (either FCS was good, or FCS checking not enabled).
        i_clrErrorCounts => clrInBufErrors,          -- in std_logic;   -- reset o_errorCounts and o_SingleHopSrcDest
        -- The 4 bit counters that make up o_errorCounts have a 3 bit counter, with the 4th bit used to indicate any occurence of the condition.
        o_errorCounts    => statInBufErrors(to_integer(unsigned(inputPortLFAA2)))   -- out(15:0) -- (3:0) = packet drop count, (7:4) = bad FCS count, (11:8) = unroutable count, (15:12) = Notification fifoFull count
    );
    
    -- Tie off unused input ports 
    NotifyBlockPortValid(23 downto 20) <= (others => '0');
    NotifyBlockPortValid(17) <= '0';
    NotifyBlockPortData(23 downto 20) <= (others => (others => '0'));
    NotifyBlockPortData(17) <= (others => '0');
    
    -----------------------------------------------------------------------------------------
    -- Forwarding of notifications
    -- Cycle through all the input ports, read any active notifications, and send to the output ports
    --
    
    process(i_IC_clk)
    begin
        if rising_edge(i_IC_clk) then
            if i_IC_rst(19) = '1' then
                notifyCheckCount <= (others => '0');
            else
                if (unsigned(notifyCheckCount) = (totalInputPorts - 1)) then
                    notifyCheckCount <= (others => '0');
                else
                    notifyCheckCount <= std_logic_vector(unsigned(notifyCheckCount) + 1);
                end if;
               
                notifyCheckCountDel1 <= notifyCheckCount; 
                NotifyPortDataSel <= NotifyBlockPortData(to_integer(unsigned(notifyCheckCount)));
                NotifyPortValidSel <= NotifyBlockPortValid(to_integer(unsigned(notifyCheckCount)));
                
                -- fifo read signal back to the buffer
                NotifyBlockPortRead <= (others => '0');
                NotifyBlockPortRead(to_integer(unsigned(notifyCheckCountDel1))) <= NotifyPortValidSel;
                
            end if;
        end if;
    end process;
    
    
    -----------------------------------------------------------------------------------------
    -- Output side
    -----------------------------------------------------------------------------------------
    -- Output ports are numbered (via the OUTPUTMUX generic)
    -- 0-6 : Z interconnect
    -- 7-11 : Y interconnect
    -- 12-16 : X interconnect
    -- 17 : Timing
    -- 18 : Coarse corner turn
    --
    
    omuxZgen : for i in 0 to 6 generate
    
        zgeni : entity interconnect_lib.IC_outputMux -- interconnect_lib.IC_outputMux
        generic map (
            -- 0 = 3 FPGAs (X x Y x Z = 1x1x3), 1 = 12 FPGAs (X x Y x Z = 1x6x2), 2 = etc....
            -- See confluence page (perentie -> Model development -> packetised model overview -> model configuration)    
            ARRAYRELEASE => ARRAYRELEASE, -- : integer 0 to 5 := 0;
            -- Z outputs can come from : 
            --  + X (7-11)
            --  + Y (12-16)
            --  + timing (17)
            --  + LFAA   (18 and 19)
            PORTSUSED => x"000fff80",
            OUTPUTMUX => std_logic_vector(to_unsigned(i,5)),
            FIBEROUTPUT => '1',
            DROPADDRWORD => '0'
        ) port map (
            -- Everything is on a single clock (about 400 MHz)
            i_IC_clk => i_IC_clk, -- in std_logic;
            i_rst    => i_IC_rst(20),    -- in std_logic;
            -- Configuration information
            i_myAddr => reg_rw.myAddr,   -- in(11:0); -- X,Y and Z coordinates of this FPGA in the array, used for routing.
            i_destAddr => ZDestArray(i), -- in(11:0); -- X,Y and Z coordinates of the place this output mux sends data to.
            i_destPort => "1111",        -- in(3:0);  -- signal chain port this output mux sends data to. Only used if i_myAddr = i_destAddr, (i.e. when packets coming to this mux are destined for this FPGA). 
            -- Packet Data being streamed out by the input side modules 
            i_packetData => ICData,           -- in array32x64bit_type; 
            i_packetOutputMux => ICOutputMux, -- in array32x5bit_type, destination address (bits(11:0)) and signal chain port (bits(15:12)) for the packet being streamed.
            i_packetValid => ICValid,         -- in (31:0);
            -- Notification from input ports of packets being available at a particular block in a buffer 
            -- These go to a FIFO in this module, if the destination address matches i_destAddr, i_destPort.
            i_NotificationAddress => notifyPortDataSel(15 downto 0),  -- in (15:0), destination address for this packet, (11:0) = XYZ coordinates, (15:12) = signal chain port. 
            i_NotificationBlock   => notifyPortDataSel(20 downto 16), -- in (4:0),  the block in the buffer that the packet is stored at.
            i_NotificationPort    => notifyCheckCountDel1,            -- in (4:0),  the input port that this notification comes from.
            i_NotificationValid   => notifyPortValidSel,              -- in std_logic;
            -- Requests out to the input ports
            o_requestBlock => requestBlock(i),  -- out(4:0), Block in the buffer that we want to get data from.
            o_requestPort  => requestPort(i),   -- out(4:0), The input port that data is being requested from.
            o_requestValid => requestValid(i),  -- out std_logic, o_requestBlock and o_requestPort are valid. 
            -- The packets
            o_data  => o_gtyZData(i),  -- out std_logic_vector(63 downto 0);
            o_valid => o_gtyZValid(i), -- out std_logic;
            -- status
            i_clrErrorCounts => clrMuxErrors, -- in std_logic;
            o_errCounts => MuxErrCounts(i)    -- out(7:0), (3:0) = fifo full, bit(3) is sticky; (7:4) = input port invalid count, bit(7) is sticky.
        );
        
        ZdestArray(0) <= reg_rw.destAddr0;
        ZdestArray(1) <= reg_rw.destAddr1;
        ZdestArray(2) <= reg_rw.destAddr2;
        ZdestArray(3) <= reg_rw.destAddr3;
        ZdestArray(4) <= reg_rw.destAddr4;
        ZdestArray(5) <= reg_rw.destAddr5;
        ZdestArray(6) <= reg_rw.destAddr6;
        
    end generate;
    
    omuxYgen : for i in 0 to 4 generate
    
        Ygeni : entity interconnect_lib.IC_outputMux -- interconnect_lib.IC_outputMux
        generic map (
            -- 0 = 3 FPGAs (X x Y x Z = 1x1x3), 1 = 12 FPGAs (X x Y x Z = 1x6x2), 2 = etc....
            -- See confluence page (perentie -> Model development -> packetised model overview -> model configuration)    
            ARRAYRELEASE => ARRAYRELEASE, -- : integer 0 to 5 := 0;
            -- Y outputs can come from : 
            --  + Z (0-6)
            --  + X (12-16)
            --  + timing (17)
            PORTSUSED => x"0003f07f",
            -- OUTPUTMUX is a unique number for this output mux. 
            -- it must match the index used to select the connection to the request bus (requestBlock, requestPort, requestValid).
            OUTPUTMUX => std_logic_vector(to_unsigned(i+7,5)),
            FIBEROUTPUT => '1',
            DROPADDRWORD => '0'
        ) port map (
            -- Everything is on a single clock (about 400 MHz)
            i_IC_clk => i_IC_clk, -- in std_logic;
            i_rst    => i_IC_rst(21),    -- in std_logic;
            -- Configuration information
            i_myAddr => reg_rw.myAddr,   -- in(11:0); -- X,Y and Z coordinates of this FPGA in the array, used for routing.
            i_destAddr => YDestArray(i), -- in(11:0); -- X,Y and Z coordinates of the place this output mux sends data to.
            i_destPort => "1111",        -- in(3:0);  -- signal chain port this output mux sends data to. Only used if i_myAddr = i_destAddr, (i.e. when packets coming to this mux are destined for this FPGA). 
            -- Packet Data being streamed out by the input side modules 
            i_packetData => ICData,           -- in array32x64bit_type; 
            i_packetOutputMux => ICOutputMux, -- in array32x5bit_type, destination address (bits(11:0)) and signal chain port (bits(15:12)) for the packet being streamed.
            i_packetValid => ICValid,         -- in (31:0);
            -- Notification from input ports of packets being available at a particular block in a buffer 
            -- These go to a FIFO in this module, if the destination address matches i_destAddr, i_destPort.
            i_NotificationAddress => notifyPortDataSel(15 downto 0),  -- in (15:0), destination address for this packet, (11:0) = XYZ coordinates, (15:12) = signal chain port. 
            i_NotificationBlock   => notifyPortDataSel(20 downto 16), -- in (4:0),  the block in the buffer that the packet is stored at.
            i_NotificationPort    => notifyCheckCountDel1,            -- in (4:0),  the input port that this notification comes from.
            i_NotificationValid   => notifyPortValidSel,              -- in std_logic;
            -- Requests out to the input ports
            o_requestBlock => requestBlock(7+i),  -- out(4:0), Block in the buffer that we want to get data from.
            o_requestPort  => requestPort(7+i),   -- out(4:0), The input port that data is being requested from.
            o_requestValid => requestValid(7+i),  -- out std_logic, o_requestBlock and o_requestPort are valid. 
            -- The packets
            o_data  => o_gtyYData(i),  -- out std_logic_vector(63 downto 0);
            o_valid => o_gtyYValid(i), -- out std_logic;
            -- status
            i_clrErrorCounts => clrMuxErrors, -- in std_logic;
            o_errCounts => MuxErrCounts(7+i)    -- out(7:0), (3:0) = fifo full, bit(3) is sticky; (7:4) = input port invalid count, bit(7) is sticky
        );
        
        YdestArray(0) <= reg_rw.destAddr7;
        YdestArray(1) <= reg_rw.destAddr8;
        YdestArray(2) <= reg_rw.destAddr9;
        YdestArray(3) <= reg_rw.destAddr10;
        YdestArray(4) <= reg_rw.destAddr11;
        
    end generate; 

    omuxXgen : for i in 0 to 4 generate
    
        Xgeni : entity interconnect_lib.IC_outputMux -- interconnect_lib.IC_outputMux
        generic map (
            -- 0 = 3 FPGAs (X x Y x Z = 1x1x3), 1 = 12 FPGAs (X x Y x Z = 1x6x2), 2 = etc....
            -- See confluence page (perentie -> Model development -> packetised model overview -> model configuration)    
            ARRAYRELEASE => ARRAYRELEASE, -- : integer 0 to 5 := 0;
            -- X outputs can come from : 
            --  + Z (0-6)
            --  + Y (7-11)
            --  + timing (17)
            PORTSUSED => x"00020fff",
            -- OUTPUTMUX is a unique number for this output mux. 
            -- it must match the index used to select the connection to the request bus (requestBlock, requestPort, requestValid).
            OUTPUTMUX => std_logic_vector(to_unsigned(i+12,5)),
            FIBEROUTPUT => '1',
            DROPADDRWORD => '0'
        ) port map (
            -- Everything is on a single clock (about 400 MHz)
            i_IC_clk => i_IC_clk, -- in std_logic;
            i_rst    => i_IC_rst(22),    -- in std_logic;
            -- Configuration information
            i_myAddr => reg_rw.myAddr,   -- in(11:0); -- X,Y and Z coordinates of this FPGA in the array, used for routing.
            i_destAddr => XDestArray(i), -- in(11:0); -- X,Y and Z coordinates of the place this output mux sends data to.
            i_destPort => "1111",        -- in(3:0);  -- signal chain port this output mux sends data to. Only used if i_myAddr = i_destAddr, (i.e. when packets coming to this mux are destined for this FPGA). 
            -- Packet Data being streamed out by the input side modules 
            i_packetData => ICData,           -- in array32x64bit_type; 
            i_packetOutputMux => ICOutputMux, -- in array32x5bit_type, destination address (bits(11:0)) and signal chain port (bits(15:12)) for the packet being streamed.
            i_packetValid => ICValid,         -- in (31:0);
            -- Notification from input ports of packets being available at a particular block in a buffer 
            -- These go to a FIFO in this module, if the destination address matches i_destAddr, i_destPort.
            i_NotificationAddress => notifyPortDataSel(15 downto 0),  -- in (15:0), destination address for this packet, (11:0) = XYZ coordinates, (15:12) = signal chain port. 
            i_NotificationBlock   => notifyPortDataSel(20 downto 16), -- in (4:0),  the block in the buffer that the packet is stored at.
            i_NotificationPort    => notifyCheckCountDel1,            -- in (4:0),  the input port that this notification comes from.
            i_NotificationValid   => notifyPortValidSel,              -- in std_logic;
            -- Requests out to the input ports
            o_requestBlock => requestBlock(12+i),  -- out(4:0), Block in the buffer that we want to get data from.
            o_requestPort  => requestPort(12+i),   -- out(4:0), The input port that data is being requested from.
            o_requestValid => requestValid(12+i),  -- out std_logic, o_requestBlock and o_requestPort are valid. 
            -- The packets
            o_data  => o_gtyXData(i),  -- out std_logic_vector(63 downto 0);
            o_valid => o_gtyXValid(i), -- out std_logic;
            -- status
            i_clrErrorCounts => clrMuxErrors, -- in std_logic;
            o_errCounts => MuxErrCounts(12+i)    -- out(7:0), (3:0) = fifo full, bit(3) is sticky; (7:4) = input port invalid count, bit(7) is sticky.
        );
        
        XdestArray(0) <= reg_rw.destAddr12;
        XdestArray(1) <= reg_rw.destAddr13;
        XdestArray(2) <= reg_rw.destAddr14;
        XdestArray(3) <= reg_rw.destAddr15;
        XdestArray(4) <= reg_rw.destAddr16;
        
    end generate;
    
    -- Timing outputs can come from any fiber port (i.e. 0 to 16). Just use ICData, ICBlock, ICValid
    Tgeni : entity interconnect_lib.IC_outputMux -- interconnect_lib.IC_outputMux
    generic map (
        -- 0 = 3 FPGAs (X x Y x Z = 1x1x3), 1 = 12 FPGAs (X x Y x Z = 1x6x2), 2 = etc....
        -- See confluence page (perentie -> Model development -> packetised model overview -> model configuration)    
        ARRAYRELEASE => ARRAYRELEASE, -- : integer 0 to 5 := 0;
        -- timing outputs can come from : 
        --  + Z (0-6)
        --  + Y (7-11)
        --  + X (12-16)
        PORTSUSED => x"0001ffff",
        -- OUTPUTMUX is a unique number for this output mux. 
        -- it must match the index used to select the connection to the request bus (requestBlock, requestPort, requestValid).
        OUTPUTMUX => std_logic_vector(to_unsigned(17,5)),
        FIBEROUTPUT => '0',
        DROPADDRWORD => '0'  -- The timing module needs to see the addressing information
    ) port map (
        -- Everything is on a single clock (about 400 MHz)
        i_IC_clk => i_IC_clk, -- in std_logic;
        i_rst    => i_IC_rst(23),    -- in std_logic;
        -- Configuration information
        i_myAddr => reg_rw.myAddr,   -- in(11:0); -- X,Y and Z coordinates of this FPGA in the array, used for routing.
        i_destAddr => reg_rw.myAddr, -- in(11:0); -- X,Y and Z coordinates of the place this output mux sends data to.
        i_destPort => "0000",        -- in(3:0);  -- signal chain port this output mux sends data to. Only used if i_myAddr = i_destAddr, (i.e. when packets coming to this mux are destined for this FPGA). 
        -- Packet Data being streamed out by the input side modules 
        i_packetData => ICData,           -- in array32x64bit_type; 
        i_packetOutputMux => ICOutputMux, -- in array32x5bit_type, destination address (bits(11:0)) and signal chain port (bits(15:12)) for the packet being streamed.
        i_packetValid => ICValid,         -- in (31:0);
        -- Notification from input ports of packets being available at a particular block in a buffer 
        -- These go to a FIFO in this module, if the destination address matches i_destAddr, i_destPort.
        i_NotificationAddress => notifyPortDataSel(15 downto 0),  -- in (15:0), destination address for this packet, (11:0) = XYZ coordinates, (15:12) = signal chain port. 
        i_NotificationBlock   => notifyPortDataSel(20 downto 16), -- in (4:0),  the block in the buffer that the packet is stored at.
        i_NotificationPort    => notifyCheckCountDel1,            -- in (4:0),  the input port that this notification comes from.
        i_NotificationValid   => notifyPortValidSel,              -- in std_logic;
        -- Requests out to the input ports
        o_requestBlock => requestBlock(17),  -- out(4:0), Block in the buffer that we want to get data from.
        o_requestPort  => requestPort(17),   -- out(4:0), The input port that data is being requested from.
        o_requestValid => requestValid(17),  -- out std_logic, o_requestBlock and o_requestPort are valid. 
        -- The packets
        o_data  => o_timingData,  -- out std_logic_vector(63 downto 0);
        o_valid => o_timingValid, -- out std_logic;
        -- status
        i_clrErrorCounts => clrMuxErrors, -- in std_logic;
        o_errCounts => MuxErrCounts(17)   -- out(7:0), (3:0) = fifo full, bit(3) is sticky; (7:4) = input port invalid count, bit(7) is sticky.
    );
    
    -- Coarse corner turn outputs can come from Z inputs or LFAA
    CTCgeni : entity interconnect_lib.IC_outputMux -- interconnect_lib.IC_outputMux
    generic map (
        -- 0 = 3 FPGAs (X x Y x Z = 1x1x3), 1 = 12 FPGAs (X x Y x Z = 1x6x2), 2 = etc....
        -- See confluence page (perentie -> Model development -> packetised model overview -> model configuration)    
        ARRAYRELEASE => ARRAYRELEASE, -- : integer 0 to 5 := 0; 
        -- Ports that can go to the corner turn are Z inputs (0-6) and LFAA
        --  0-6   = Z connect
        --  18    = LFAA1
        --  19    = LFAA2
        PORTSUSED => x"000C007f",
        -- OUTPUTMUX is a unique number for this output mux. 
        -- it must match the index used to select the connection to the request bus (requestBlock, requestPort, requestValid).
        OUTPUTMUX => std_logic_vector(to_unsigned(18,5)),
        FIBEROUTPUT => '0',
        DROPADDRWORD => '1'   -- CTC does not want to see the address word.
    ) port map (
        -- Everything is on a single clock (about 400 MHz)
        i_IC_clk => i_IC_clk, -- in std_logic;
        i_rst    => i_IC_rst(24),    -- in std_logic;
        -- Configuration information
        i_myAddr => reg_rw.myAddr,   -- in(11:0); -- X,Y and Z coordinates of this FPGA in the array, used for routing.
        i_destAddr => reg_rw.myAddr, -- in(11:0); -- X,Y and Z coordinates of the place this output mux sends data to.
        i_destPort => "0001",        -- in(3:0);  -- signal chain port this output mux sends data to. Only used if i_myAddr = i_destAddr, (i.e. when packets coming to this mux are destined for this FPGA). 
        -- Packet Data being streamed out by the input side modules 
        i_packetData => ICData,           -- in t_slv64_arr(31:0); 
        i_packetOutputMux => ICOutputMux, -- in t_slv5_arr(31:0), destination address (bits(11:0)) and signal chain port (bits(15:12)) for the packet being streamed.
        i_packetValid => ICValid,         -- in (31:0);
        -- Notification from input ports of packets being available at a particular block in a buffer 
        -- These go to a FIFO in this module, if the destination address matches i_destAddr, i_destPort.
        i_NotificationAddress => notifyPortDataSel(15 downto 0),  -- in (15:0), destination address for this packet, (11:0) = XYZ coordinates, (15:12) = signal chain port. 
        i_NotificationBlock   => notifyPortDataSel(20 downto 16), -- in (4:0),  the block in the buffer that the packet is stored at.
        i_NotificationPort    => notifyCheckCountDel1,            -- in (4:0),  the input port that this notification comes from.
        i_NotificationValid   => notifyPortValidSel,              -- in std_logic;
        -- Requests out to the input ports
        o_requestBlock => requestBlock(18),  -- out(4:0), Block in the buffer that we want to get data from.
        o_requestPort  => requestPort(18),   -- out(4:0), The input port that data is being requested from.
        o_requestValid => requestValid(18),  -- out std_logic, o_requestBlock and o_requestPort are valid. 
        -- The packets
        o_data  => o_CTCData,  -- out std_logic_vector(63 downto 0);
        o_sop   => o_CTCSOP,   -- out std_logic;
        o_valid => o_CTCValid, -- out std_logic;
        -- status
        i_clrErrorCounts => clrMuxErrors, -- in std_logic;
        o_errCounts => MuxErrCounts(18)    -- out(7:0), (3:0) = fifo full, bit(3) is sticky; (7:4) = input port invalid count, bit(7) is sticky.
    );
    
    -- Debug output port - sends data on any of the inputs to the 25GE fiber output
    dbgmuxinst : entity interconnect_lib.IC_dbgMux
    generic map(
        -- PortsUsed allows input side ports to be masked out from the multiplexer to save resources. 
        -- Set bits to 0 to mask a port.
        PORTSUSED => x"ffffffff" --  std_logic_vector(31 downto 0) := x"ffffffff"
    ) port map (
        -- Everything is on a single clock (about 400 MHz)
        i_IC_clk => i_IC_clk,           -- in std_logic;
        i_rst    => i_IC_rst(25),       -- in std_logic;
        -- Configuration information on i_IC_clk
        i_myAddr => reg_rw.myAddr,      -- in(11:0); X,Y and Z coordinates of this FPGA in the array, reported in the debug packets.
        i_dataSel => reg_rw.dbgDataSel, -- in(4:0);  -- Input port to dump data from.
        i_dataSelIsOutput => reg_rw.dbgDataSelIsOutput,    -- '0' to use input port i_dataSel, otherwise use input port i_port(i_dataSel) 
        i_port  => requestPort, --  in t_slv_5_arr(31 downto 0);     -- The input port that data is being requested from for each destination port
        i_destIP  => reg_rw.dbgDestIP,  -- in(31:0);  -- destination IP address to use.
        i_srcMAC  => dbgSrcMAC,         -- in(47:0);  -- Source MAC address for the debug packets
        i_destMAC => dbgDestMAC,        -- in(47:0); -- Destination MAC address for the debug packets
        -- source IP address; connect the DHCP assigned address
        i_ipAddr => i_srcIPAddr,          -- in(31:0);
        i_ipAddrClk => i_srcIPAddr_clk,   -- in std_logic;
        -- Packet Data being streamed out by the input side modules. i_dataSel chooses which port we are listening to. 
        i_packetData  => ICData,          -- in t_slv_64_arr(31:0);       -- 
        i_packetOutputMux => ICOutputMux, -- in t_slv_5_arr(31:0);   -- Destination output MUX for this packet (i.e. send the packet through this module if i_packetOutputMux = OUTPUTMUX).
        i_packetValid => ICValid,         -- in(31:0);
        -- 25 GE debug port (output of the interconnect module)
        o_dbg25GE => o_dbg25GE, -- out t_axi4_sosi;   -- Note that the valid signal should be high for the entire packet (only the core can stall).
        i_dbg25GE => i_dbg25GE, -- in  t_axi4_siso;
        i_dbg25GE_clk => i_dbg25GE_clk, --  in std_logic;
        -- Status
        i_clrErrorCounts => clrMuxErrors, -- in std_logic;
        o_errCounts => MuxErrCounts(19)   -- out(7:0)  -- (7:0) = Dropped packets. Counter wraps but bit(7) is sticky.
    );
    dbgSrcMAC(31 downto 0) <= reg_rw.dbgSrcMAC1;
    dbgSrcMAC(47 downto 32) <= reg_rw.dbgSrcMAC2;
    dbgDestMAC(31 downto 0) <= reg_rw.dbgDestMAC1;
    dbgDestMAC(47 downto 32) <= reg_rw.dbgDestMAC2;
    
    reg_ro.Z0_omux_error <= MuxErrCounts(0);
    reg_ro.Z1_omux_error <= MuxErrCounts(1);
    reg_ro.Z2_omux_error <= MuxErrCounts(2);
    reg_ro.Z3_omux_error <= MuxErrCounts(3);
    reg_ro.Z4_omux_error <= MuxErrCounts(4);
    reg_ro.Z5_omux_error <= MuxErrCounts(5);
    reg_ro.Z6_omux_error <= MuxErrCounts(6);
    reg_ro.Y0_omux_error <= MuxErrCounts(7);
    reg_ro.Y1_omux_error <= MuxErrCounts(8);
    reg_ro.Y2_omux_error <= MuxErrCounts(9);
    reg_ro.Y3_omux_error <= MuxErrCounts(10);
    reg_ro.Y4_omux_error <= MuxErrCounts(11);
    reg_ro.X0_omux_error <= MuxErrCounts(12);
    reg_ro.X1_omux_error <= MuxErrCounts(13);
    reg_ro.X2_omux_error <= MuxErrCounts(14);
    reg_ro.X3_omux_error <= MuxErrCounts(15);
    reg_ro.X4_omux_error <= MuxErrCounts(16);
    reg_ro.timing_omux_error <= MuxErrCounts(17);
    reg_ro.CTC_omux_error <= MuxErrCounts(18);
    reg_ro.DBG_omux_error <= MuxErrCounts(19);
    -- Tie off unused requestBlock, requestPort, requestValid entries
    tieoff: for reqZero in 19 to 31 generate 
        requestBlock(reqZero) <= "00000";
        requestPort(reqZero) <= "00000";
        requestValid(reqZero) <= '0';
    end generate;
    
    ---------------------------------------------------------------------
    -- Registers
    --
    --
    
    ICREGi : entity interconnect_lib.interconnect_reg
    PORT map (
        MM_CLK              => i_s_axi_clk,   -- in std_logic;
        MM_RST              => i_s_axi_rst,   -- in std_logic;
        st_clk_icstatctrl   => st_clk_ic,     -- in(0:0);
        st_rst_icstatctrl   => st_rst_ic,     -- in(0:0);
        SLA_IN              => i_s_axi_mosi,  -- in t_axi4_lite_mosi;
        SLA_OUT             => o_s_axi_miso,  -- out t_axi4_lite_miso;
        ICSTATCTRL_FIELDS_RW => reg_rw,       -- out t_icstatctrl_rw;
        ICSTATCTRL_FIELDS_RO => reg_ro,       -- in  t_icstatctrl_ro;
        ICSTATCTRL_FIELDS_COUNT => reg_count, -- in t_icstatctrl_count;
        count_rsti              => count_rsti  -- in std_logic
    );
    
    st_clk_ic(0) <= i_IC_clk;
    st_rst_ic(0) <= i_IC_rst(31);
    count_rsti <= '0';
    
    reg_count.Z0_good_count <= statGoodPacket(0);
    reg_count.Z1_good_count <= statGoodPacket(1);
    reg_count.Z2_good_count <= statGoodPacket(2);
    reg_count.Z3_good_count <= statGoodPacket(3);
    reg_count.Z4_good_count <= statGoodPacket(4);
    reg_count.Z5_good_count <= statGoodPacket(5);
    reg_count.Z6_good_count <= statGoodPacket(6);
    reg_count.Y0_good_count <= statGoodPacket(7);
    reg_count.Y1_good_count <= statGoodPacket(8);
    reg_count.Y2_good_count <= statGoodPacket(9);
    reg_count.Y3_good_count <= statGoodPacket(10);
    reg_count.Y4_good_count <= statGoodPacket(11);
    reg_count.X0_good_count <= statGoodPacket(12);
    reg_count.X1_good_count <= statGoodPacket(13);
    reg_count.X2_good_count <= statGoodPacket(14);
    reg_count.X3_good_count <= statGoodPacket(15);
    reg_count.X4_good_count <= statGoodPacket(16);
    reg_count.Timing_good_count <= '0';
    reg_count.LFAA0_good_count <= statGoodPacket(to_integer(unsigned(inputPortLFAA1)));
    reg_count.LFAA1_good_count <= statGoodPacket(to_integer(unsigned(inputPortLFAA2)));
    reg_count.lfaa_drops <= statLFAADrop;
    reg_count.lfaa_fifo_overflows <= statLFAAOverflow;
    
end Behavioral;
