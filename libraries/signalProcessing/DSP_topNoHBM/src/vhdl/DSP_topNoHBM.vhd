-------------------------------------------------------------------------------
--
-- File Name: vcu128_gemini_dsp.vhd
-- Contributing Authors: David Humphrey
-- Type: RTL
-- Created: July 2019
--
-- Title: Top Level for the Perentie signal processing code.
--
-- Description: 
--  Includes all the signal processing and data manipulation modules.
--  There are several different "signal chains". The input and output data for a signal chain
--  is either an optical port or the interconnect module.
--  The interconnect module routes data between the signal chains and the FPGA to FPGA optical network.
--  
--  Signal Chains:
--   (1) Timing
--   This has a single module, "timingControl". Timing control has following tasks:
--      - Keep track of "wall_time"
--      - Synchonise wall_time to either MACE or another FPGAs wall_time
--      - Control the OCXO via the SPI interface to the DAC (Note this is not available on the VCU128 board)
--      - Provide wall_time in other clock domains
--
--    (2) Station Processing Ingest:
--    Takes data from the 40GE LFAA input, and sends it to the interconnect module.
--      40GE fiber -> LFAADecode -> Capture128Bit -> LocalDoppler -> Interconnect
--    Submodules:
--     - LFAADecode
--        Extracts data from the 40GE UDP/SPEAD packets, matches to the virtual channel table, and forwards packets
--     - Capture128bit
--        Capture packets at the output of the LFAADecode module
--     + LocalDoppler
--        Applies doppler correction.
--
--    (3) Station Processing filterbanks
--    Interconnect -> Coarse Corner Turn -> filterbanks -> Fine Delay -> interconnect
--    Submodules
--     - Coarse corner turn (CTC) 
--        Uses HBM memory to rearrange the data into 0.9 second bursts for each station
--     - Filterbanks
--     - Fine Delay
--     
--    (4)... more to come.
--
-------------------------------------------------------------------------------

LIBRARY IEEE, common_lib, axi4_lib, ctc_hbm_lib;
library LFAADecode_lib, timingcontrol_lib, capture128bit_lib, captureFine_lib, DSP_top_lib, ctc_lib, filterbanks_lib, interconnect_lib;
--use ctc_lib.ctc_pkg.all;
library DSP_top_lib;
use DSP_top_lib.DSP_top_pkg.all;
use DSP_top_lib.DSP_topNoHBM_reg_pkg.all;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE axi4_lib.axi4_full_pkg.ALL;

-------------------------------------------------------------------------------
entity DSP_topNoHBM is
    generic (
        -- See dsp_top_pkg for functions that map ARRAYRELEASE to actual parameter for that release.
        -- See also the confluence pages.
        -- -3 = single FPGA, very cut down numbers for the corner turn. Simulation only.
        -- -2 = single FPGA, cut down numbers of channels and shorter frames for simulation only.
        -- -1 = single FPGA
        -- 0 = PISA,    FPGA array dimensions (z,x,y) = (3,1,1)
        -- 1 = AA1,     FPGA array dimensions (z,x,y) = (2,1,6)
        -- 2 = AA2,     FPGA array dimensions (z,x,y) = (2,6,3)
        -- 3 = AA3-ITF, FPGA array dimensions (z,x,y) = (4,6,2)
        -- 4 = AA3-CPF, FPGA array dimensions (z,x,y) = (8,6,3)
        -- 5 = AA4,     FPGA array dimensions (z,x,y) = (8,6,6)
        ARRAYRELEASE : integer range -3 to 5 := 0;
        g_sim        : BOOLEAN := FALSE;
        INCLUDE_FB   : boolean := true);
    port (
        -- source IP address used for debug data; connect to the DHCP assigned address.
        i_srcIPAddr     : in std_logic_vector(31 downto 0);
        i_srcIPAddr_clk : in std_logic;
        -- Processing clocks
        i_clk100 : in std_logic; -- HBM reference clock
        -- HBM_AXI_clk and wallClk should be derived from the OCXO on the gemini boards, so that clocks on different boards run very close to the same frequency.
        i_HBM_clk : in std_logic; -- 400 MHz for the vcu128 board, up to 450 for production devices. Also used for general purpose processing.
        i_HBM_clk_rst : in std_logic;
        i_wall_clk : in std_logic;    -- 250 MHz, derived from the 125MHz OCXO. Used for timing of events (e.g. when to start reading in the corner turn)
        -- 40GE LFAA ingest data
        i_LFAA40GE : in t_axi4_sosi;
        o_LFAA40GE : out t_axi4_siso;
        i_LFAA40GE_clk : in std_logic;
        i_mac40G : in std_logic_vector(47 downto 0); --    mac40G <= x"aabbccddeeff";
        -- 25 GE debug port (output of the interconnect module)
        o_dbg25GE : out t_axi4_sosi;
        i_dbg25GE : in  t_axi4_siso;
        i_dbg25GE_clk : in std_logic;
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
        -- XYZ interconnect outputs
        o_gtyZData  : out t_slv_64_arr(6 downto 0);
        o_gtyZValid : out std_logic_vector(6 downto 0);
        o_gtyYData  : out t_slv_64_arr(4 downto 0);
        o_gtyYValid : out std_logic_vector(4 downto 0);
        o_gtyXData  : out t_slv_64_arr(4 downto 0);
        o_gtyXValid : out std_logic_vector(4 downto 0);
        -- Serial interface to the OCXO
        o_ptp_pll_reset : out std_logic;                     -- PLL reset
        o_ptp_clk_sel   : out std_logic;                     -- PTP Interface (156.25MH select when high)
        o_ptp_sync_n    : out std_logic_vector(1 downto 0);  -- bit(0) = active low enable for DAC controlling the clk_e = 25 MHz crystal (which is then upconverted to either 125 or 156.25 MHz), bit(1) = active low enable for DAC controlling the clk_f = 20 MHz crystal.  
        o_ptp_sclk      : out std_logic;
        o_ptp_din       : out std_logic;
        -----------------------------------------------------------------------
        -- AXI slave interfaces for modules
        i_MACE_clk  : in std_logic;
        i_MACE_rst  : in std_logic;
        ---- dsp top full slave (access to the HBM)
        --i_HBMDbgFull_axi_mosi : in t_axi4_full_mosi;
        --o_HBMDbgFull_axi_miso : out t_axi4_full_miso;
        -- DSP top lite slave
        i_dsptopLite_axi_mosi : in t_axi4_lite_mosi;
        o_dsptopLite_axi_miso : out t_axi4_lite_miso;
        -- LFAADecode, lite + full slave
        i_LFAALite_axi_mosi : in t_axi4_lite_mosi;  -- => mc_lite_mosi(c_LFAADecode_lite_index),
        o_LFAALite_axi_miso : out t_axi4_lite_miso; -- => mc_lite_miso(c_LFAADecode_lite_index),
        i_LFAAFull_axi_mosi : in  t_axi4_full_mosi; -- => mc_full_mosi(c_LFAAdecode_full_index),
        o_LFAAFull_axi_miso : out t_axi4_full_miso; -- => mc_full_miso(c_LFAAdecode_full_index),
        -- Capture, lite + full
        i_Cap128Lite_axi_mosi : in t_axi4_lite_mosi;  -- => mc_lite_mosi(c_capture128bit_lite_index) 
        o_Cap128Lite_axi_miso : out t_axi4_lite_miso; -- => mc_lite_miso(c_capture128bit_lite_index) 
        i_Cap128Full_axi_mosi : in  t_axi4_full_mosi; -- => mc_full_mosi(c_capture128bit_full_index) 
        o_Cap128Full_axi_miso : out t_axi4_full_miso; -- => mc_full_miso(c_capture128bit_full_index)             
        -- Timing control
        i_timing_axi_mosi : in  t_axi4_lite_mosi; -- => mc_lite_mosi(c_timingcontrol_lite_index)
        o_timing_axi_miso : out t_axi4_lite_miso; -- => mc_lite_miso(c_timingcontrol_lite_index)
        -- Interconnect
        i_IC_axi_mosi : in t_axi4_lite_mosi;
        o_IC_axi_miso : out t_axi4_lite_miso
        ---- Corner Turn
        --i_CTC_axi_mosi : in  t_axi4_lite_mosi;
        --o_CTC_axi_miso : out t_axi4_lite_miso;
        ---- Fine Capture, lite + full
        --i_CapFineLite_axi_mosi : in t_axi4_lite_mosi;  -- => mc_lite_mosi(c_capture128bit_lite_index) 
        --o_CapFineLite_axi_miso : out t_axi4_lite_miso; -- => mc_lite_miso(c_capture128bit_lite_index) 
        --i_CapFineFull_axi_mosi : in  t_axi4_full_mosi; -- => mc_full_mosi(c_capture128bit_full_index) 
        --o_CapFineFull_axi_miso : out t_axi4_full_miso; -- => mc_full_miso(c_capture128bit_full_index)
        ---- Filterbanks FIR taps
        --i_FB_axi_mosi : in t_axi4_full_mosi;
        --o_FB_axi_miso : out t_axi4_full_miso
    );
END DSP_topNoHBM;

-------------------------------------------------------------------------------
ARCHITECTURE structure OF DSP_topNoHBM IS

    ---------------------------------------------------------------------------
    -- SIGNAL DECLARATIONS  --
    --------------------------------------------------------------------------- 
    
    signal dbg_timer_expire : std_logic;
    signal dbg_timer  :  std_logic_vector(15 downto 0);    
    signal LFAADecode_dbg : std_logic_vector(13 downto 0);
    signal LFAA_tx_fsm, LFAA_stats_fsm, LFAA_rx_fsm : std_logic_vector(3 downto 0);
    signal LFAA_goodpacket, LFAA_nonSPEAD : std_logic;
    
    signal gnd : std_logic_vector(199 downto 0);
    
    signal LFAAingest_data : std_logic_vector(127 downto 0);
    signal LFAAingest_valid : std_logic;
    signal timingPacketData : std_logic_vector(63 downto 0);
    signal timingPacketValid : std_logic;
    
    signal clk_LFAA40GE_wallTime : t_wall_time;
    signal clk_HBM_wallTime : t_wall_time;
    signal clk_wall_wallTime : t_wall_time;
    
    signal CTCDataIn : std_logic_vector(63 downto 0);
    signal CTCValidIn : std_logic;
    signal CTCSOPIn   : std_logic;
    
    --signal CTCsofOut    : std_logic_vector(pc_CTC_OUTPUT_NUMBER-1 downto 0);
    --signal CTCHeaderOut : t_ctc_output_header_a(pc_CTC_OUTPUT_NUMBER-1 downto 0);
    --signal CTCDataOut   : t_ctc_output_data_a(pc_CTC_OUTPUT_NUMBER-1 downto 0);
    --signal CTCDataValidOut : std_logic_vector(pc_CTC_OUTPUT_NUMBER-1 downto 0);
    --signal CTCValidOut : std_logic_vector(pc_CTC_OUTPUT_NUMBER-1 downto 0);
    
    signal MACE_clk_vec : std_logic_vector(0 downto 0);
    signal MACE_clk_rst : std_logic_vector(0 downto 0);
    
    signal dsp_top_rw  : t_statctrl_rw;
    
    --signal CTC_CorSof : std_logic; -- single cycle pulse: this cycle is the first of 204*4096
    --signal CTC_CorHeader : t_ctc_output_header_a(pc_CTC_OUTPUT_NUMBER-1 downto 0);    -- meta data belonging to the data coming out
    --signal CTC_CorHeaderValid : std_logic;                                            -- new meta data (every output packet, aka 4096 cycles) 
    --signal CTC_CorData : t_ctc_output_data_a(pc_CTC_OUTPUT_NUMBER-1 downto 0);      -- the actual output data
    --signal CTC_CorDataValid : std_logic;

    --signal CTC_PSSPSTSof : std_logic; 
    --signal CTC_PSSPSTData : t_ctc_output_data_a(2 downto 0);  -- 3 different streams, each 32 bits (8 bits each for VpolRe, VpolIm, HpolRe, HpolIm)
    --signal CTC_PSSPSTDataValid : std_logic;
    --signal CTC_PSSPSTHeader : t_ctc_output_header_a(2 downto 0); -- one header per stream
    --signal CTC_PSSPSTHeaderValid : std_logic;
    
    --signal CTC_HBM_clk_rst : std_logic;          -- reset going to the HBM core
    --signal CTC_HBM_mosi : t_axi4_full_mosi;   -- data going to the HBM core
    --signal CTC_HBM_miso : t_axi4_full_miso;   -- data coming from the HBM core
    --signal CTC_HBM_ready : std_logic;
    
    --signal FB_CorHeader : t_ctc_output_header_a(1 downto 0); -- meta data belonging to the data coming out
    --signal FB_CorHeaderValid : std_logic;                    -- new meta data (every output packet, aka 4096 cycles) 
    --signal FB_CorData : t_ctc_output_data_a(1 downto 0);     -- the actual output data
    --signal FB_CorDataValid : std_logic;
    
    --signal FB_PSSHeader      : t_ctc_output_header_a(2 downto 0);
    --signal FB_PSSHeaderValid : std_logic;
    --signal FB_PSSData        : t_ctc_output_data_a(2 downto 0);
    --signal FB_PSSDataValid   : std_logic;
    -- PST filterbank data output
    --signal FB_PSTHeader      : t_ctc_output_header_a(2 downto 0);
    --signal FB_PSTHeaderValid : std_logic;
    --signal FB_PSTData        : t_ctc_output_data_a(2 downto 0);
    --signal FB_PSTDataValid   : std_logic;
    --signal HBMPage : std_logic_vector(9 downto 0);
    --signal hbm_width_rst : std_logic := '0';
    
    --signal MACE_HBM_mosi : t_axi4_full_mosi;
    --signal MACE_HBM_miso : t_axi4_full_miso;
    
    --signal hbm_axi_rst, hbm_axi_rst_del1, hbm_axi_rst_del2, hbm_axi_rst_del3 : std_logic := '0';
    signal IC_rst, IC_rst_del1, IC_rst_del2, IC_rst_del3 : std_logic_vector(31 downto 0);
    
    -- Functions to convert from arrayRelease to FPGA count etc. are in DSP_top_pkg.vhd
    constant c_FPGA_COUNT : integer := get_FPGA_Zcount(ARRAYRELEASE);
    constant c_COARSE_CHANNELS : integer := get_coarse_channels(ARRAYRELEASE);
    constant c_OUTPUT_TIME_COUNT : integer := get_output_time_count(ARRAYRELEASE);
    constant c_AUX_WIDTH : integer := get_aux_width(ARRAYRELEASE);    --PISA: 24
    constant c_OUTPUT_PRELOAD : integer := get_output_preload(ARRAYRELEASE); -- PISA : 11
    constant c_COARSE_DELAY_OFFSET : integer := get_coarse_delay_offset(ARRAYRELEASE); -- PISA : 2
    constant c_IC_ARRAYRELEASE : integer := get_IC_array_release(ARRAYRELEASE); -- maps negative values used for CTC to 0 for the IC module.
    constant c_MAXIMUM_DRIFT : integer := get_maximum_drift(ARRAYRELEASE);
    
begin
    gnd <= (others => '0');
    
    ICinst : entity interconnect_lib.IC_Top
    generic map (
        ARRAYRELEASE => c_IC_ARRAYRELEASE -- : integer range 0 to 5 := 0 
    )
    port map (
        -- source IP address to use for debug packets
        i_srcIPAddr     => i_srcIPAddr,     -- in(31:0);
        i_srcIPAddr_clk => i_srcIPAddr_clk, -- in std_logic;    
        -- Packets from GTYs.
        -- All GTYs send data in on the same clock.
        i_IC_clk => i_HBM_clk,   -- in std_logic;
        i_IC_rst => IC_rst_del3, -- in std_logic_vector(31:0);
        -- Wall time is used to timestamp incoming packets. This is only used for timing packets.
        i_wallTime =>  clk_HBM_wallTime, -- in t_wall_time;  -- seconds since 1970
        -- XYZ interconnect inputs
        i_gtyZdata  => i_gtyZdata,  -- in t_slv_64_arr(6:0);
        i_gtyZValid => i_gtyZValid, -- in (6:0);
        i_gtyZSof   => i_gtyZSof,   -- in (6:0);
        i_gtyZEof   => i_gtyZEof,   -- in (6:0);
        i_gtyYdata  => i_gtyYdata,  -- in t_slv_64_arr(4:0);
        i_gtyYValid => i_gtyYValid, -- in (4:0);
        i_gtyYSof   => i_gtyYSof,   -- in (4:0);
        i_gtyYEof   => i_gtyYEof,   -- in (4:0);
        i_gtyXdata  => i_gtyXdata,  -- in t_slv_64_arr(4:0);
        i_gtyXValid => i_gtyXValid, -- in (4:0);
        i_gtyXSof   => i_gtyXSof,   -- in (4:0);
        i_gtyXEof   => i_gtyXEof,   -- in (4:0);
        -------------------------------------------------
        -- Signal chain inputs 
        -- 1. LFAA ingest pipeline
        i_LFAAingest_data => LFAAingest_data,   -- in(127:0);
        i_LFAAingest_valid => LFAAingest_valid, -- in std_logic;
        i_LFAAingest_clk => i_LFAA40GE_clk,     -- in std_logic;
        -- 2. To be added...
        -------------------------------------------------
        -- XYZ interconnect outputs
        o_gtyZData  => o_gtyZData,  -- out t_slv_64_arr(6:0);
        o_gtyZValid => o_gtyZValid, -- out (6:0);
        o_gtyYData  => o_gtyYData,  -- out t_slv_64_arr(4:0);
        o_gtyYValid => o_gtyYValid, -- out (4:0);
        o_gtyXData  => o_gtyXData,  -- out t_slv_64_arr(4:0);
        o_gtyXValid => o_gtyXValid, -- out (4:0);
        -------------------------------------------------
        -- Signal chain outputs
        -- 1. timing
        o_timingData => timingPacketData,   -- out std_logic_vector(63 downto 0);
        o_timingValid => timingPacketValid, -- out std_logic;
        -- 2. Coarse Corner Turn
        o_CTCData  => CTCDataIn,  -- out std_logic_vector(63 downto 0);
        o_CTCSOP   => CTCSopIn,   -- out std_logic;
        o_CTCValid => CTCValidIn, -- out std_logic;
        --------------------------------------------------
        -- 25 GE debug port
        o_dbg25GE  => o_dbg25GE,        -- out t_axi4_sosi;   -- Note that the valid signal should be high for the entire packet (only the core can stall).
        i_dbg25GE  => i_dbg25GE,        -- in  t_axi4_siso;
        i_dbg25GE_clk => i_dbg25GE_clk, -- in std_logic;
        --------------------------------------------------
        -- Registers AXI Lite Interface
        i_s_axi_mosi => i_IC_axi_mosi, -- in t_axi4_lite_mosi;
        o_s_axi_miso => o_IC_axi_miso, -- out t_axi4_lite_miso;
        i_s_axi_clk  => i_MACE_clk,    -- in std_logic;
        i_s_axi_rst  => i_MACE_rst     -- in std_logic       
    );
    
    --------------------------------------------------------------------------
    -- Signal Processing signal Chains
    --------------------------------------------------------------------------
    
    --------------------------------------------------------------------------
    -- Timing 
    --  Just the timing_control module in this signal chain
    --
    timingInst : entity timingcontrol_lib.timing_control
    port map (
        -- Registers
        mm_clk    => i_MACE_clk, -- in std_logic;
        mm_rst    => i_MACE_rst, -- in std_logic;
        i_sla_in  => i_timing_axi_mosi, -- mc_lite_mosi(c_timingcontrol_lite_index), -- in  t_axi4_lite_mosi;
        o_sla_out => o_timing_axi_miso, -- mc_lite_miso(c_timingcontrol_lite_index), -- out t_axi4_lite_miso;
        -- clocks
        i_HBM_clk      => i_HBM_clk,    -- in std_logic; -- 400 MHz for the vcu128 board, up to 450 for production devices. Also used for general purpose processing.
        i_wall_clk     => i_wall_clk,          -- in std_logic; -- 250 MHz, derived from the 125MHz OCXO. Used for timing of events (e.g. when to start reading in the corner turn)
        i_LFAA40GE_clk => i_LFAA40GE_clk,  -- in std_logic;
        -- wall time outputs in each clock domain
        o_clk_HBM_wallTime      => clk_HBM_wallTime, --  out t_wall_time;      -- wall time in i_HBM_AXI_clk domain
        o_clk_LFAA40GE_wallTime => clk_LFAA40GE_wallTime, -- out t_wall_time; -- wall time in LFAA40GE clk domain
        o_clk_wall_wallTime     => clk_wall_wallTime, -- out t_wall_time;     -- wall time in wall clk domain
        --
        -- Serial interface to AD5662BRM nanodacs, which controls the voltage to two oscillators
        -- * 20 MHz, which comes in as 20 MHz on clk_f. This crystal has a range of +/-100 ppm, so better to use the 25 MHz crystal 
        -- * 25 MHz, which is converted up to either 156.25 MHz or 125 MHz, depending on ptp_clk_sel.
        --           The crystal has a range of +/-6 ppm (or maybe 12.. not clear which version we have). 
        --           This clock comes in on both sfp_clk_e_p/n and clk_e_p/n.
        --           sfp_clk_e_p/n could be used for synchronous ethernet/white rabbit.
        -- AD5662BRM info -
        --   - ptp_sclk maximum frequency is MHz
        --   - data sampled on the falling edge of ptp_sclk
        --   - 24 bits per command, with
        --      - 6 don't cares
        --      - "00" for normal operation (other options are power-down states).
        --      - 16 data bits, straight binary 0 to 65535.
        o_ptp_pll_reset => o_ptp_pll_reset, -- out std_logic;                     -- PLL reset
        o_ptp_clk_sel   => o_ptp_clk_sel,   -- out std_logic;                     -- PTP Interface (156.25MH select when high)
        o_ptp_sync_n    => o_ptp_sync_n,    -- out std_logic_vector(1 downto 0);  -- bit(0) = active low enable for DAC controlling the clk_e = 25 MHz crystal (which is then upconverted to either 125 or 156.25 MHz), bit(1) = active low enable for DAC controlling the clk_f = 20 MHz crystal.  
        o_ptp_sclk      => o_ptp_sclk,      -- out std_logic;
        o_ptp_din       => o_ptp_din,       -- out std_logic;
        --------------------------------------------------------
        --------------------------------------------------------
        -- Packets from the internal network
        -- Timing packets from other FPGAs come in on this link.
        -- Expected format is 3 words :
        --   (1) source MAC (6 bytes) + source port (1 byte) + packet type (1 byte)
        --       - This should be the header of all packets on the internal network
        --       - Packet type of 0 = timing information.
        --   (2) source time (24 bit fractional + 32 bit integer seconds + 1 byte unused).
        --   (3) Interval (24 bit fractional + 32 bit integer seconds + 1 bit to indicate valid)
        --       - This is the time gap since the last packet according to the remote clock.  
        --         The source time in the previous word can have jumps, so we cannot calculate the
        --         time locally.
        --   (4) Last word in the packet (FCS + 4 bytes unused).
        i_packet_data  => timingPacketData,  -- in(63:0)
        i_packet_valid => timingPacketValid  -- in std_logic;
    );
    
    
    --------------------------------------------------------------------------
    -- LFAA Ingest Signal Chain
    --  - LFAADecode
    --     - includes statistics capture module.
    --     - includes test packet generation
    --  - Packet Capture
    --
    LFAAin : entity LFAADecode_lib.LFAADecodeTop
    port map(
        -- Data in from the 40GE MAC
        i_data_rx_sosi     => i_LFAA40GE,     -- in t_axi4_sosi;   -- 128 bit wide data in, only fields that are used are .tdata, .tvalid, .tuser
        o_data_rx_siso     => o_LFAA40GE,     -- out t_axi4_siso;  -- Only tready, and actually ignored by the 40GE MAC 
        i_data_clk         => i_LFAA40GE_clk, -- in std_logic;     -- 312.5 MHz for 40GE MAC
        i_data_rst         => '0', -- in std_logic;
        -- Data out 
        o_data_out         => LFAAingest_data,  --  out std_logic_vector(127 downto 0);
        o_valid_out        => LFAAingest_valid, --  out std_logic;
        -- miscellaneous
        i_my_mac           => i_mac40G,      -- in std_logic_vector(47 downto 0); -- MAC address for this board; incoming packets from the 40GE interface are filtered using this.
        i_wallTime         => clk_LFAA40GE_wallTime,  -- in t_wall_time -- UNIX time in seconds (i.e. since 1970)
        --AXI Interface
        i_s_axi_mosi       => i_LFAALite_axi_mosi, -- in t_axi4_lite_mosi; at the top level use mc_lite_mosi(c_LFAADecode_lite_index)
        o_s_axi_miso       => o_LFAALite_axi_miso, -- out t_axi4_lite_miso;
        i_s_axi_clk        => i_MACE_clk,         
        i_s_axi_rst        => i_MACE_rst,
        -- registers AXI Full interface
        i_vcstats_MM_IN    => i_LFAAFull_axi_mosi, -- in  t_axi4_full_mosi; At the top level use mc_full_mosi(c_LFAAdecode_full_index),
        o_vcstats_MM_OUT   => o_LFAAFull_axi_miso, -- out t_axi4_full_miso;
        -- debug
        o_dbg              => LFAADecode_dbg
    );
    
    
    pcapture : entity capture128bit_lib.capture128bit
    port map (
        -- Packet Data to capture
        i_data      => LFAAingest_data,   -- in 127:0;
        i_valid     => LFAAingest_valid,  -- in std_logic;
        i_data_clk  => i_LFAA40GE_clk,    -- in std_logic;
        -- control registers AXI Lite Interface
        i_s_axi_mosi => i_Cap128Lite_axi_mosi, -- mc_lite_mosi(c_capture128bit_lite_index) -- in t_axi4_lite_mosi;
        o_s_axi_miso => o_Cap128Lite_axi_miso, -- mc_lite_miso(c_capture128bit_lite_index) -- out t_axi4_lite_miso;
        i_s_axi_clk  => i_MACE_clk,
        i_s_axi_rst  => i_MACE_rst,
        -- AXI Full interface for the capture buffer
        i_capmem_MM_IN  => i_Cap128Full_axi_mosi, -- mc_full_mosi(c_capture128bit_full_index) -- in  t_axi4_full_mosi;
        o_capmem_MM_OUT => o_Cap128Full_axi_miso  -- mc_full_miso(c_capture128bit_full_index) -- out t_axi4_full_miso;        
    );
    
    
    
    process(i_HBM_clk)
    begin
        if rising_edge(i_HBM_clk) then
            -- individual resets with some pipeline stages to avoid timing issues
           -- hbm_axi_rst <= i_HBM_clk_rst or dsp_top_rw.HBMwidth2HBM_axi_rst;
           -- hbm_axi_rst_del1 <= hbm_axi_rst;
           -- hbm_axi_rst_del2 <= hbm_axi_rst_del1;
           -- hbm_axi_rst_del3 <= hbm_axi_rst_del1;
            
            for i in 0 to 31 loop
                IC_rst(i) <= i_HBM_clk_rst or dsp_top_rw.IC_rsts(i);
            end loop;
            IC_rst_del1 <= IC_rst;
            IC_rst_del2 <= IC_rst_del1;
            IC_rst_del3 <= IC_rst_del2;
            
        end if;
    end process;
    
    ---------------------------------------------------------------------------
    -- Registers
    dsptopregi : entity DSP_top_lib.dsp_topNoHBM_reg
    port map (
        MM_CLK          => i_MACE_clk,
        MM_RST          => i_MACE_rst,
        st_clk_statctrl => MACE_clk_vec, -- in STD_LOGIC_VECTOR(0 TO 0);
        st_rst_statctrl => MACE_clk_rst, -- in STD_LOGIC_VECTOR(0 TO 0);
        SLA_IN          => i_dsptopLite_axi_mosi, -- in  t_axi4_lite_mosi;
        SLA_OUT         => o_dsptopLite_axi_miso, -- out t_axi4_lite_miso;
        STATCTRL_FIELDS_RW => dsp_top_rw -- : OUT t_statctrl_rw
    );
    MACE_clk_vec(0) <= i_HBM_clk;
    MACE_clk_rst(0) <= '0';
    
    ---------------------------------------------------------------------------
    -- Debug  --
    ---------------------------------------------------------------------------
    
--    connectdbg2 : ila_0
--    port map (
--        clk => clk_eth,
--        probe0(199 downto 0) => gnd(199 downto 0)
--    );
    
-- data_rx_sosi     : in t_axi4_sosi;   -- 128 bit wide data in, only fields that are used are .tdata, .tvalid, .tuser
--    seg0_ena <= data_rx_sosi(36).tuser(56);
--    seg0_sop <= data_rx_sosi(36).tuser(57);  -- start of packet
--    seg0_eop <= data_rx_sosi(36).tuser(58);  -- end of packet
--    seg0_mty <= data_rx_sosi(36).tuser(61 DOWNTO 59); -- number of unused bytes in segment 0, only used when eop0 = '1', ena0 = '1', tvalid = '1'. 
--    seg0_err <= data_rx_sosi(36).tuser(62);  -- error reported by 40GE MAC (e.g. FCS, bad 64/66 bit block, bad packet length), only valid on eop0, ena0 and tvalid all = '1'
------ segment 1 relates to data_rx_sosi.tdata(127:64)
--    seg1_ena <= data_rx_sosi(36).tuser(63);
--    seg1_sop <= data_rx_sosi(36).tuser(64);
--    seg1_eop <= data_rx_sosi(36).tuser(65);
--    seg1_mty <= data_rx_sosi(36).tuser(68 DOWNTO 66);
--    seg1_err <= data_rx_sosi(36).tuser(69);
    
    LFAA_tx_fsm <= LFAADecode_dbg(3 downto 0);
    LFAA_stats_fsm <= LFAADecode_dbg(7 downto 4);
    LFAA_rx_fsm <= LFAADecode_dbg(11 downto 8);
    LFAA_goodpacket <= LFAADecode_dbg(12);
    LFAA_nonSPEAD   <= LFAADecode_dbg(13);
    
END structure;
