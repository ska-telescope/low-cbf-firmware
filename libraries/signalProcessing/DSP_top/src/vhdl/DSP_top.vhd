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
use ctc_lib.ctc_pkg.all;
use DSP_top_lib.DSP_top_pkg.all;
use DSP_top_lib.DSP_top_reg_pkg.all;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE axi4_lib.axi4_full_pkg.ALL;

-------------------------------------------------------------------------------
entity DSP_top is
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
        -- dsp top full slave (access to the HBM)
        i_HBMDbgFull_axi_mosi : in t_axi4_full_mosi;
        o_HBMDbgFull_axi_miso : out t_axi4_full_miso;
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
        o_IC_axi_miso : out t_axi4_lite_miso;
        -- Corner Turn
        i_CTC_axi_mosi : in  t_axi4_lite_mosi;
        o_CTC_axi_miso : out t_axi4_lite_miso;
        -- Fine Capture, lite + full
        i_CapFineLite_axi_mosi : in t_axi4_lite_mosi;  -- => mc_lite_mosi(c_capture128bit_lite_index) 
        o_CapFineLite_axi_miso : out t_axi4_lite_miso; -- => mc_lite_miso(c_capture128bit_lite_index) 
        i_CapFineFull_axi_mosi : in  t_axi4_full_mosi; -- => mc_full_mosi(c_capture128bit_full_index) 
        o_CapFineFull_axi_miso : out t_axi4_full_miso; -- => mc_full_miso(c_capture128bit_full_index)
        -- Filterbanks FIR taps
        i_FB_axi_mosi : in t_axi4_full_mosi;
        o_FB_axi_miso : out t_axi4_full_miso
    );
END DSP_top;

-------------------------------------------------------------------------------
ARCHITECTURE structure OF DSP_top IS

    ---------------------------------------------------------------------------
    -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
    ---------------------------------------------------------------------------

    

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
    
    signal CTCsofOut    : std_logic_vector(pc_CTC_OUTPUT_NUMBER-1 downto 0);
    signal CTCHeaderOut : t_ctc_output_header_a(pc_CTC_OUTPUT_NUMBER-1 downto 0);
    signal CTCDataOut   : t_ctc_output_data_a(pc_CTC_OUTPUT_NUMBER-1 downto 0);
    signal CTCDataValidOut : std_logic_vector(pc_CTC_OUTPUT_NUMBER-1 downto 0);
    signal CTCValidOut : std_logic_vector(pc_CTC_OUTPUT_NUMBER-1 downto 0);
    
    signal MACE_clk_vec : std_logic_vector(0 downto 0);
    signal MACE_clk_rst : std_logic_vector(0 downto 0);
    
    signal dsp_top_rw  : t_statctrl_rw;
    
    signal CTC_CorSof : std_logic; -- single cycle pulse: this cycle is the first of 204*4096
    signal CTC_CorHeader : t_ctc_output_header_a(pc_CTC_OUTPUT_NUMBER-1 downto 0);    -- meta data belonging to the data coming out
    signal CTC_CorHeaderValid : std_logic;                                            -- new meta data (every output packet, aka 4096 cycles) 
    signal CTC_CorData : t_ctc_output_data_a(pc_CTC_OUTPUT_NUMBER-1 downto 0);      -- the actual output data
    signal CTC_CorDataValid : std_logic;

    signal CTC_PSSPSTSof : std_logic; 
    signal CTC_PSSPSTData : t_ctc_output_data_a(2 downto 0);  -- 3 different streams, each 32 bits (8 bits each for VpolRe, VpolIm, HpolRe, HpolIm)
    signal CTC_PSSPSTDataValid : std_logic;
    signal CTC_PSSPSTHeader : t_ctc_output_header_a(2 downto 0); -- one header per stream
    signal CTC_PSSPSTHeaderValid : std_logic;
    
    signal CTC_HBM_clk_rst : std_logic;          -- reset going to the HBM core
    signal CTC_HBM_mosi : t_axi4_full_mosi;   -- data going to the HBM core
    signal CTC_HBM_miso : t_axi4_full_miso;   -- data coming from the HBM core
    signal CTC_HBM_ready : std_logic;
    
    signal FB_CorHeader : t_ctc_output_header_a(1 downto 0); -- meta data belonging to the data coming out
    signal FB_CorHeaderValid : std_logic;                    -- new meta data (every output packet, aka 4096 cycles) 
    signal FB_CorData : t_ctc_output_data_a(1 downto 0);     -- the actual output data
    signal FB_CorDataValid : std_logic;
    
    signal FB_PSSHeader      : t_ctc_output_header_a(2 downto 0);
    signal FB_PSSHeaderValid : std_logic;
    signal FB_PSSData        : t_ctc_output_data_a(2 downto 0);
    signal FB_PSSDataValid   : std_logic;
    -- PST filterbank data output
    signal FB_PSTHeader      : t_ctc_output_header_a(2 downto 0);
    signal FB_PSTHeaderValid : std_logic;
    signal FB_PSTData        : t_ctc_output_data_a(2 downto 0);
    signal FB_PSTDataValid   : std_logic;
    signal HBMPage : std_logic_vector(9 downto 0);
    signal hbm_width_rst : std_logic := '0';
    
    signal MACE_HBM_mosi : t_axi4_full_mosi;
    signal MACE_HBM_miso : t_axi4_full_miso;
    
    signal hbm_axi_rst, hbm_axi_rst_del1, hbm_axi_rst_del2, hbm_axi_rst_del3 : std_logic := '0';
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
    
    --------------------------------------------------------------------------
    -- Coarse Corner Turn Signal Chain
    --   - Coarse Corner turn
    --   - Filterbanks
    --   - Fine delay
    --   - Fine Capture
    
    ctci : entity ctc_lib.ctc
    generic map(
        g_USE_DATA_IN_STOP    => false, -- boolean;    --PISA: FALSE -use the stop signal on the ingress?
        g_FPGA_COUNT          => c_FPGA_COUNT,     -- integer;    --PISA: 3     -how many FPGAs are used?
        g_INPUT_STOP_WORDS    => 10,    -- integer := 10; --PISA:    -ignore if g_USE_DATA_IN_STOP is FALSE  -- how many cycles does it take from o_data_in_stop='1' to input data being halted?
        g_USE_HBM             => (not g_sim),  -- boolean; --        -TRUE: use Xilinx' HBM model, FALSE: use HBM emulator (simpler, faster, no SystemVerilog needed)
        g_HBM_EMU_STUTTER     => false, -- boolean;    --            -if HBM emulator used: set w_ready and wa_ready to '0' in a pseudo random pattern    
        g_HBM_BURST_LEN       => 16,    -- integer;    --PISA: 16    -length of HBM burst 
        g_COARSE_CHANNELS     => c_COARSE_CHANNELS,   -- integer;    --PISA: 128   -how many different CCs are there?
        g_INPUT_BLOCK_SIZE    => 2048,  -- integer;    --PISA: 2048  -how many time stamps are in one CC? (unit: 32 bit (dual pol)) 
        g_OUTPUT_BLOCK_SIZE   => 4096,  -- integer;    --PISA: 4096  -how many time stamps are in one output block? (unit: 32 bit (dual pol))
        g_OUTPUT_TIME_COUNT   => c_OUTPUT_TIME_COUNT,   -- integer;    --PISA: 204   -how many output blocks come consecutively?
        g_STATION_GROUP_SIZE  => 2,     -- integer;    --PISA: 2     -how many stations are in one station_group (on the output side)                
        g_OUTPUT_PRELOAD      => c_OUTPUT_PRELOAD,    -- integer;    --PISA: 11    -how many output blocks do we need to preload to initialise the filter banks?
        -- g_AUX_WIDTH = 2*g_OUTPUT_TIME_COUNT - (pc_CTC_MAX_STATIONS*g_COARSE_CHANNELS)/2   (if this is negative, change the values above!)
        g_AUX_WIDTH           => c_AUX_WIDTH,    -- integer;    --PISA: 24    -unit: INPUT_TIME_COUNT - how many packet counts wide are the AUX buffers?
        g_WIDTH_PADDING       => 26,    -- integer;    --PISA: 26    -unit: INPUT_TIME_COUNT - how wide is the padding around the MAIN buffer?
        g_MAXIMUM_DRIFT       => c_MAXIMUM_DRIFT,    -- integer;    --PISA: 20    -unit: INPUT_TIME_COUNT - how far does the CTC allow stations to be late before cutting them off?
        g_COARSE_DELAY_OFFSET => c_COARSE_DELAY_OFFSET,  -- integer     --PISA: 2     -unit: INPUT_TIME_COUNT - how many input blocks too early do we start reading to allow for coarse delay?
        g_USE_DATA_IN_RECORD  => false -- boolean := true -- only use for the stand alone ctc testbench.
    )
    port map (
        i_hbm_clk         => i_HBM_clk,  -- AXI clock: for ES and -1 devices: <=400MHz, for PS of -2 and higher: <=450MHz (HBM core and most of the CTC run in this clock domain)  
        i_mace_clk        => i_MACE_clk, -- clock connected to MACE
        i_mace_clk_rst    => i_MACE_rst, -- this is the only incoming reset - all other resets are created internally in the config module
        --MACE:
        i_saxi_mosi       => i_CTC_axi_mosi, -- in  t_axi4_lite_mosi;
        o_saxi_miso       => o_CTC_axi_miso, -- out t_axi4_lite_miso;        
        --wall time:
        i_input_clk_wall_time  => clk_HBM_wallTime, -- in t_wall_time; wall time in input_clk domain            
        i_output_clk_wall_time => clk_HBM_wallTime, -- in t_wall_time; wall time in output_clk domain       
        --ingress (in input_clk):
        i_input_clk       => i_HBM_clk,  -- in std_logic; clock domain for the ingress
        i_data_in         => CTCDataIn,  -- in(63:0);     incoming data stream (header, data)
        i_data_in_vld     => CTCValidIn, -- in std_logic; is the current data cycle valid?
        i_data_in_sop     => CTCSOPIn,   -- in std_logic; first cycle of the header?
        o_data_in_stop    => open,       -- out std_logic; ignore if g_USE_DATA_IN_STOP is FALSE
        --i_data_in_record  : in  t_ctc_input_data := (others => pc_CTC_DATA_ZERO); -- FOR SIMULATION ONLY (data + meta) 
        --egress (in output_clk):
        i_output_clk      => i_HBM_clk,          -- in  std_logic; clock domain for the egress
        o_start_of_frame  => CTC_CorSof,         -- out std_logic; single cycle pulse: this cycle is the first of 204*4096
        o_header_out      => CTC_CorHeader,      -- out t_ctc_output_header_a(pc_CTC_OUTPUT_NUMBER-1 downto 0);    -- meta data belonging to the data coming out
        o_header_out_vld  => CTC_CorHeaderValid, -- out std_logic;                                                 -- new meta data (every output packet, aka 4096 cycles) 
        o_data_out        => CTC_CorData,        -- out t_ctc_output_data_a(pc_CTC_OUTPUT_NUMBER-1 downto 0);      -- the actual output data
        o_data_out_vld    => CTC_CorDataValid,   -- out std_logic;                                                 -- is this cycle valid? if i_stop is not used, a 4096 packet is uninteruptedly valid
        o_packet_vld      => CTCValidOut,        -- out std_logic_vector(pc_CTC_OUTPUT_NUMBER-1 downto 0);        -- is this 2048 cycle half of the packet valid or RFI? (RFI = missing input packet)         
        i_data_out_stop   => '0',                -- in  std_logic;                                                 -- set to '0' if not used
        --HBM INTERFACE
        o_hbm_clk_rst => CTC_HBM_clk_rst, -- out std_logic;          -- reset going to the HBM core
        o_hbm_mosi    => CTC_HBM_mosi,    -- out t_axi4_full_mosi;   -- data going to the HBM core
        i_hbm_miso    => CTC_HBM_miso,    -- in  t_axi4_full_miso;   -- data coming from the HBM core
        i_hbm_ready   => CTC_HBM_ready   -- in  std_logic           -- HBM reset finished? (=apb_complete)
    );
    
    HBMwrapGen : if (not g_sim) generate
        hbmwrapi : entity ctc_hbm_lib.hbm_wrapper
        port map (
            i_hbm_ref_clk   => i_clk100,        -- in  std_logic; 
            i_axi_clk       => i_HBM_clk,       -- in  std_logic; 
            i_axi_clk_rst   => CTC_HBM_clk_rst, -- in  std_logic;
            i_saxi_00       => CTC_HBM_mosi,    -- in  t_axi4_full_mosi;
            o_saxi_00       => CTC_HBM_miso,    -- out t_axi4_full_miso;
            i_saxi_02       => MACE_HBM_mosi,   -- in  t_axi4_full_mosi;
            o_saxi_02       => MACE_HBM_miso,   -- out t_axi4_full_miso;
            i_apb_clk       => i_clk100,        -- in  std_logic;   
            o_apb_complete  => CTC_HBM_ready    -- out std_logic
        );
    end generate;
    
    HBMwrapNoGen : if g_sim generate
        CTC_HBM_miso.arready <= '0';
        CTC_HBM_miso.awready <= '0';
        CTC_HBM_miso.rdata <= (others => '0');
        CTC_HBM_miso.rid <= (others => '0');
        CTC_HBM_miso.rlast <= '0';
        CTC_HBM_miso.rresp <= (others => '0');
        CTC_HBM_miso.rvalid <= '0';
        CTC_HBM_miso.wready <= '0';
        CTC_HBM_miso.bid <= (others => '0');
        CTC_HBM_miso.bresp <= (others => '0');
        CTC_HBM_miso.bvalid <= '0';
        MACE_HBM_miso.arready <= '0';
        MACE_HBM_miso.awready <= '0';
        MACE_HBM_miso.rdata <= (others => '0');
        MACE_HBM_miso.rid <= (others => '0');
        MACE_HBM_miso.rlast <= '0';
        MACE_HBM_miso.rresp <= (others => '0');
        MACE_HBM_miso.rvalid <= '0';
        MACE_HBM_miso.wready <= '0';
        MACE_HBM_miso.bid <= (others => '0');
        MACE_HBM_miso.bresp <= (others => '0');
        MACE_HBM_miso.bvalid <= '0';
        CTC_HBM_ready <= '1';
    end generate;
    

    axi_width_converti : entity DSP_top_lib.axi_width_wrapper
    port map (
        -- AXI full bus going into the width converter
        -- 32 bit wide data bus
        i_MACE_clk     => i_MACE_clk,           -- in  std_logic;
        i_MACE_clk_rst => hbm_width_rst,           -- in  std_logic;
        i_MACE_mosi   => i_HBMDbgFull_axi_mosi, -- in t_axi4_full_mosi;
        o_MACE_miso   => o_HBMDbgFull_axi_miso, -- out t_axi4_full_miso;
        -- Memory page into the HBM is 4 MBytes in size
        -- So top ten bits of the address come from the page
        -- This is in the MACE clock domain.
        i_page => HBMPage, -- in std_logic_vector(9 downto 0);
        -- AXI full bus coming out of the width converter
        -- 256 bit wide data bus
        i_HBM_clk     => i_HBM_clk,        -- in  std_logic;
        i_HBM_rst     => HBM_axi_rst_del3, -- in  std_logic;
        i_HBM_miso    => MACE_HBM_miso,    -- in  t_axi4_full_mosi;
        o_HBM_mosi    => MACE_HBM_mosi     -- out t_axi4_full_miso
    );
    
    process(i_MACE_clk)
    begin
        if rising_edge(i_MACE_clk) then
            HBMPage <= dsp_top_rw.HBMPage(31 downto 22);
            hbm_width_rst <= i_MACE_rst or dsp_top_rw.mace2hbmwidth_axi_rst;
        end if;
    end process;
    
    process(i_HBM_clk)
    begin
        if rising_edge(i_HBM_clk) then
            -- individual resets with some pipeline stages to avoid timing issues
            hbm_axi_rst <= i_HBM_clk_rst or dsp_top_rw.HBMwidth2HBM_axi_rst;
            hbm_axi_rst_del1 <= hbm_axi_rst;
            hbm_axi_rst_del2 <= hbm_axi_rst_del1;
            hbm_axi_rst_del3 <= hbm_axi_rst_del1;
            
            for i in 0 to 31 loop
                IC_rst(i) <= i_HBM_clk_rst or dsp_top_rw.IC_rsts(i);
            end loop;
            IC_rst_del1 <= IC_rst;
            IC_rst_del2 <= IC_rst_del1;
            IC_rst_del3 <= IC_rst_del2;
            
        end if;
    end process;
    
    
    -- PSS/PST output is not yet implemented in the corner turn.
    CTC_PSSPSTSof <= '0';
    CTC_PSSPSTData <= (others => (data => (hpol => pc_CTC_PAYLOAD_ZERO,vpol => pc_CTC_PAYLOAD_ZERO),meta => (others => pc_CTC_META_ZERO)));   -- in t_ctc_output_data_a(2 downto 0);  -- 3 different streams, each 32 bits (8 bits each for VpolRe, VpolIm, HpolRe, HpolIm)
    CTC_PSSPSTDataValid <= '0';
    CTC_PSSPSTHeader <= (others => pc_CTC_OUTPUT_HEADER_ZERO); -- in t_ctc_output_header_a(2 downto 0); -- one header per stream
    CTC_PSSPSTHeaderValid <= '0';

    fbgen : if INCLUDE_FB generate
        fbtopi : entity filterbanks_lib.FB_Top
        port map (
            -- clock, target is 400 MHz
            i_data_clk  => i_HBM_clk,     -- in std_logic;
            i_data_rst  => i_HBM_clk_rst, -- in std_logic;
            -- AXI slave interface, 64k word block of space with the fir filter coefficients.
            i_MACE_clk  => i_MACE_clk,    -- in std_logic;
            i_MACE_rst  => i_MACE_rst,    -- in std_logic;
            i_axi_mosi  => i_FB_axi_mosi, -- in  t_axi4_full_mosi;
            o_axi_miso  => o_FB_axi_miso, -- out t_axi4_full_miso;
            -----------------------------------------
            -- Correlator filterbank input.
            i_CorSOF         => CTC_CorSOF,         -- in std_logic;                            -- start of frame.
            i_CorHeader      => CTC_CorHeader,      -- in t_ctc_output_header_a(1 downto 0);    -- meta data belonging to the data coming out
            i_CorHeaderValid => CTC_CorHeaderValid, -- in std_logic;                            -- new meta data (every output packet, aka 4096 cycles) 
            i_CorData        => CTC_CorData,        -- in t_ctc_output_data_a(1 downto 0);      -- the actual output data
            i_CorDataValid   => CTC_CorDataValid,   -- in std_logic;
            -- Correlator Filterbank output
            o_CorHeader      => FB_CorHeader,      -- out t_ctc_output_header_a(1 downto 0);    -- meta data belonging to the data coming out
            o_CorHeaderValid => FB_CorHeaderValid, -- out std_logic;                            -- new meta data (every output packet, aka 4096 cycles) 
            o_CorData        => FB_CorData,        -- out t_ctc_output_data_a(1 downto 0);      -- the actual output data
            o_CorDataValid   => FB_CorDataValid,   -- out std_logic;
            -----------------------------------------
            -- PSS and PST Data input, common valid signal, expects packets of 64 samples. 
            -- Requires at least 2 clocks idle time between packets.
            -- Due to oversampling, also requires on average 86 clocks between packets - specifically, no more than 3 packets in 258 clocks.
            i_PSSPSTSOF         => '0',                   -- in std_logic; 
            i_PSSPSTHeader      => CTC_PSSPSTHeader,      -- in t_ctc_output_header_a(2 downto 0);
            i_PSSPSTHeaderValid => CTC_PSSPSTHeaderValid, -- in std_logic;
            i_PSSPSTData        => CTC_PSSPSTData,        -- in t_ctc_output_data_a(2 downto 0);
            i_PSSPSTDataValid   => CTC_PSSPSTDataValid,   -- in std_logic;
            -- PSS filterbank data Output
            o_PSSHeader      => FB_PSSHeader,      -- out t_ctc_output_header_a(2 downto 0);
            o_PSSHeaderValid => FB_PSSHeaderValid, -- out std_logic;
            o_PSSData        => FB_PSSData,        -- out t_ctc_output_data_a(2 downto 0);
            o_PSSDataValid   => FB_PSSDataValid,   -- out std_logic;
            -- PST filterbank data output
            o_PSTHeader      => FB_PSTHeader,      -- out t_ctc_output_header_a(2 downto 0);
            o_PSTHeaderValid => FB_PSTHeaderValid, -- out std_logic;
            o_PSTData        => FB_PSTData,        -- out t_ctc_output_data_a(2 downto 0);
            o_PSTDataValid   => FB_PSTDataValid    -- out std_logic
        );
    end generate;


    capFinei : entity captureFine_lib.captureFine
    port map(
        -- Packet Data to capture
        -- ctc correlator data
        i_CTC_data   => CTC_CorData,      -- in t_ctc_output_data_a(1 downto 0);   -- Each of the 2 inputs is 32 bits, 8 bits each for VpolRe, VpolIm, HpolRe, HpolIm 
        i_CTC_hdr    => CTC_CorHeader,    -- in t_ctc_output_header_a(1 downto 0); -- 
        i_CTC_valid  => CTC_CorDataValid, -- in std_logic;
        i_data_clk   => i_HBM_clk,        -- in std_logic;
        -- Correlator Filterbank output data
        i_CFB_data   => FB_CorData,  --  in t_ctc_output_data_a(1 downto 0);   -- 2 streams, each 32 bits, as per CTC correlator data.
        i_CFB_hdr    => FB_CorHeader,   --  in t_ctc_output_header_a(1 downto 0); -- 
        i_CFB_valid  => FB_CorDatavalid, -- in std_logic;
        -- CTC PSS/PST data (comes out on the same bus)
        i_CTC_PSSPST_data  => CTC_PSSPSTData,   -- in t_ctc_output_data_a(2 downto 0);  -- 3 different streams, each 32 bits (8 bits each for VpolRe, VpolIm, HpolRe, HpolIm)
        i_CTC_PSSPST_hdr   => CTC_PSSPSTHeader, -- in t_ctc_output_header_a(2 downto 0); -- one header per stream
        i_CTC_PSSPST_valid => CTC_PSSPSTDataValid,  -- in std_logic;
        -- PSS Filterbank output data
        i_PSSFB_data  => FB_PSSData,      -- in t_ctc_output_data_a(2 downto 0);  -- 3 different streams, each 32 bits (8 bits each for VpolRe, VpolIm, HpolRe, HpolIm)
        i_PSSFB_hdr   => FB_PSSHeader,    -- in t_ctc_output_header_a(2 downto 0); -- one header per stream
        i_PSSFB_valid => FB_PSSDataValid, -- in std_logic;
        -- PST Filterbank output data
        i_PSTFB_data  => FB_PSTData,      -- in t_ctc_output_data_a(2 downto 0);  -- 3 different streams, each 32 bits (8 bits each for VpolRe, VpolIm, HpolRe, HpolIm)
        i_PSTFB_hdr   => FB_PSTHeader,    -- in t_ctc_output_header_a(2 downto 0); -- one header per stream
        i_PSTFB_valid => FB_PSTDataValid, -- in std_logic;
        -- control registers AXI Lite Interface
        i_s_axi_mosi  => i_CapFineLite_axi_mosi, -- in t_axi4_lite_mosi;
        o_s_axi_miso  => o_CapFineLite_axi_miso, -- out t_axi4_lite_miso;
        i_s_axi_clk   => i_MACE_clk,             -- in std_logic;
        i_s_axi_rst   => i_MACE_rst,             -- in std_logic;
        -- AXI Full interface for the capture buffer
        i_capmem_MM_IN  => i_CapFineFull_axi_mosi, -- in  t_axi4_full_mosi;
        o_capmem_MM_OUT => o_CapFineFull_axi_miso -- out t_axi4_full_miso        
    );
    
    
    ---------------------------------------------------------------------------
    -- Registers
    dsptopregi : entity DSP_top_lib.dsp_top_reg
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
