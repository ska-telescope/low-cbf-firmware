-------------------------------------------------------------------------------
--
-- File Name: gemini_lru_test.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Thurs Oct 19 16:40:00 2017
-- Template Rev: 1.0
--
-- Title: Top Level of Gemini LRU DSP project
--
-- Description: Top level file for implmentation the ethernet TX framer. Muxes
--              multiple lanes together
--
--
-- Compiler options:
--
--
-- Dependencies:
--
--
--
-------------------------------------------------------------------------------

LIBRARY IEEE, UNISIM, common_lib, axi4_lib, technology_lib, util_lib;
LIBRARY gemini_lru_board_lib, spi_lib, onewire_lib, eth_lib, arp_lib, dhcp_lib, gemini_server_lib, gemini_subscription_lib, ping_protocol_lib;
LIBRARY tech_ddr4_lib, tech_mac_100g_lib, tech_axi4_quadspi_prom_lib, tech_system_monitor_lib, tech_axi4_infrastructure_lib;
library dsp_top_lib;
use DSP_top_lib.DSP_top_pkg.all;

Library xpm;
use xpm.vcomponents.all;

--library LFAADecode_lib, timingcontrol_lib, capture128bit_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE axi4_lib.axi4_full_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
--USE gemini_lru_board_lib.ip_pkg.ALL;
USE gemini_lru_board_lib.board_pkg.ALL;
USE tech_mac_100g_lib.tech_mac_100g_pkg.ALL;

USE work.gemini_lru_dsp_bus_pkg.ALL;
USE work.gemini_lru_dsp_system_reg_pkg.ALL;
USE work.ip_pkg.ALL;
USE UNISIM.vcomponents.all;

-------------------------------------------------------------------------------
ENTITY gemini_lru_DSP IS
   GENERIC (
      g_technology         : t_technology := c_tech_gemini;
      g_sim                : BOOLEAN := FALSE);
   PORT (
      -- Global clks
--      clk_aux_b_p          : in std_logic;                           -- Differential clock input
--      clk_aux_b_n          : in std_logic;
--      clk_aux_c            : inout std_logic;                        -- Multi-purpose IO to MMBX
      clk_c_p              : IN std_logic_vector(4 DOWNTO 0);        -- Shared 156.25MHz clock for 10G (QSFP & MBO)
      clk_c_n              : IN std_logic_vector(4 DOWNTO 0);
--      clk_d_p              : in std_logic_vector(2 downto 0);        -- variable clock inputs to enable MBO operation at ADC-speed (Shared between MBO connections, see schematic, clk_d)
--      clk_d_n              : in std_logic_vector(2 downto 0);
      -- Both clk_e and clk_f are controlled via  
      clk_e_p              : in std_logic;         -- Either 156.25 MHz or 125MHz PTP clk, output of PLL chip CDCM61004, controlled by ptp_clk_sel   
      clk_e_n              : in std_logic;
      -- clk_f is a 20MHz PTP clk, comes from a oven controlled, voltage controlled 20 MHz oscillator. 
      -- The voltage control range is +/-100ppm, which is significantly worse than clk_e (which is about +/- 10 ppm)
--      clk_f                : in std_logic;                           
      clk_g_p              : IN STD_LOGIC;                           -- 266.67 Memory reference clock
      clk_g_n              : IN STD_LOGIC;
      clk_h                : IN STD_LOGIC;                            -- 20MHz LO clk
--      clk_bp_p             : in std_logic;                           -- Clock connection from the backplane connector
--      clk_bp_n             : in std_logic;

--      -- DDR4 interface
--      ddr4_ck_p            : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
--      ddr4_ck_n            : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);

--      ddr4_cke             : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
--      ddr4_reset_n         : OUT STD_LOGIC;

--      ddr4_adr             : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
--      ddr4_act_n           : OUT STD_LOGIC;
--      ddr4_ba              : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
--      ddr4_bg              : out STD_LOGIC_VECTOR(1 DOWNTO 0);
--      --ddr4_parity          : OUT STD_LOGIC; (Not used)
--      ddr4_cs              : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
--      ddr4_odt             : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
--      --ddr4_alert           : inout STD_LOGIC; (Not used)
--      ddr4_dm              : INOUT STD_LOGIC_VECTOR(8 DOWNTO 0);
--      ddr4_dq              : INOUT STD_LOGIC_VECTOR(71 DOWNTO 0);
--      ddr4_dqs_p           : INOUT STD_LOGIC_VECTOR(8 DOWNTO 0);
--      ddr4_dqs_n           : INOUT STD_LOGIC_VECTOR(8 DOWNTO 0);
--      -- DDR4 SPD Interface
--      ddr4_scl             : INOUT STD_LOGIC;
--      ddr4_sda             : INOUT STD_LOGIC;
--      --ddr4_event_n         : inout std_logic; (Not used)

      -- MBO
      mbo_a_clk_p          : IN STD_LOGIC_VECTOR(2 downto 0);        -- 161.13MHz reference (clk_b & clk_a)
      mbo_a_clk_n          : IN STD_LOGIC_VECTOR(2 downto 0);
      mbo_a_tx_p           : OUT STD_LOGIC_VECTOR(11 downto 0);
      mbo_a_tx_n           : OUT STD_LOGIC_VECTOR(11 downto 0);
      mbo_a_rx_p           : IN STD_LOGIC_VECTOR(11 downto 0);
      mbo_a_rx_n           : IN STD_LOGIC_VECTOR(11 downto 0);
      mbo_a_reset          : OUT STD_LOGIC;                          -- LVCMOS 1.8V

      -- mbo_b and mbo_c not used for the time being - (only 3 boards to interconnect)
--      mbo_b_clk_p          : IN STD_LOGIC_VECTOR(2 downto 0);        -- 161.13MHz reference (clk_a)
--      mbo_b_clk_n          : IN STD_LOGIC_VECTOR(2 downto 0);
--      mbo_b_tx_p           : OUT STD_LOGIC_VECTOR(11 downto 0);
--      mbo_b_tx_n           : OUT STD_LOGIC_VECTOR(11 downto 0);
--      mbo_b_rx_p           : IN STD_LOGIC_VECTOR(11 downto 0);
--      mbo_b_rx_n           : IN STD_LOGIC_VECTOR(11 downto 0);
--      mbo_b_reset          : OUT STD_LOGIC;                          -- LVCMOS 1.8V

--      mbo_c_clk_p          : IN STD_LOGIC_VECTOR(2 downto 0);        -- 161.13MHz reference (clk_a)
--      mbo_c_clk_n          : IN STD_LOGIC_VECTOR(2 downto 0);
--      mbo_c_tx_p           : OUT STD_LOGIC_VECTOR(11 downto 0);
--      mbo_c_tx_n           : OUT STD_LOGIC_VECTOR(11 downto 0);
--      mbo_c_rx_p           : IN STD_LOGIC_VECTOR(11 downto 0);
--      mbo_c_rx_n           : IN STD_LOGIC_VECTOR(11 downto 0);
--      mbo_c_reset          : OUT STD_LOGIC;                          -- LVCMOS 1.8V

      mbo_int_n            : IN STD_LOGIC;
      mbo_sda              : INOUT STD_LOGIC;                        -- OC drive, internal Pullups
      mbo_scl              : INOUT STD_LOGIC;                        -- LVCMOS 1.8V

      -- QSFP
      qsfp_a_mod_prs_n     : IN STD_LOGIC;
      qsfp_a_mod_sel       : OUT STD_LOGIC;
      qsfp_a_reset         : OUT STD_LOGIC;
      qsfp_a_led           : OUT STD_LOGIC;
      qsfp_a_clk_p         : IN STD_LOGIC;                           -- 161.13MHz reference
      qsfp_a_clk_n         : IN STD_LOGIC;
      qsfp_a_tx_p          : OUT STD_LOGIC_VECTOR(3 downto 0);
      qsfp_a_tx_n          : OUT STD_LOGIC_VECTOR(3 downto 0);
      qsfp_a_rx_p          : IN STD_LOGIC_VECTOR(3 downto 0);
      qsfp_a_rx_n          : IN STD_LOGIC_VECTOR(3 downto 0);

      qsfp_b_mod_prs_n     : IN STD_LOGIC;
      qsfp_b_mod_sel       : OUT STD_LOGIC;
      qsfp_b_reset         : OUT STD_LOGIC;
      qsfp_b_led           : OUT STD_LOGIC;
      qsfp_b_clk_p         : IN STD_LOGIC;                           -- 161.13MHz reference
      qsfp_b_clk_n         : IN STD_LOGIC;
      qsfp_b_tx_p          : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      qsfp_b_tx_n          : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      qsfp_b_rx_p          : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      qsfp_b_rx_n          : IN STD_LOGIC_VECTOR(3 DOWNTO 0);

      qsfp_c_mod_prs_n     : IN STD_LOGIC;
      qsfp_c_mod_sel       : OUT STD_LOGIC;
      qsfp_c_reset         : OUT STD_LOGIC;
      qsfp_c_led           : OUT STD_LOGIC;
      qsfp_c_clk_p         : IN STD_LOGIC;                      -- 161.13MHz reference
      qsfp_c_clk_n         : IN STD_LOGIC;
      qsfp_c_tx_p          : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      qsfp_c_tx_n          : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      qsfp_c_rx_p          : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      qsfp_c_rx_n          : IN STD_LOGIC_VECTOR(3 DOWNTO 0);

      qsfp_d_mod_prs_n     : IN STD_LOGIC;
      qsfp_d_mod_sel       : OUT STD_LOGIC;
      qsfp_d_reset         : OUT STD_LOGIC;
      qsfp_d_led           : OUT STD_LOGIC;
--      qsfp_d_clk_p         : IN STD_LOGIC;                     -- 161.13MHz reference
--      qsfp_d_clk_n         : IN STD_LOGIC;
      qsfp_d_tx_p          : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      qsfp_d_tx_n          : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      qsfp_d_rx_p          : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      qsfp_d_rx_n          : IN STD_LOGIC_VECTOR(3 DOWNTO 0);

      qsfp_int_n           : IN STD_LOGIC;
      qsfp_sda             : INOUT STD_LOGIC;
      qsfp_scl             : INOUT STD_LOGIC;

      -- SFP
      sfp_sda              : INOUT STD_LOGIC;
      sfp_scl              : INOUT STD_LOGIC;
      sfp_fault            : IN STD_LOGIC;
      sfp_tx_enable        : OUT STD_LOGIC;
      sfp_mod_abs          : IN STD_LOGIC;
      sfp_led              : OUT STD_LOGIC;

      sfp_clk_c_p          : IN STD_LOGIC;    -- 156.25MHz reference
      sfp_clk_c_n          : IN STD_LOGIC;
--      sfp_clk_e_p          : in std_logic;  -- 125/156.25MHz reference (PTP). Copy of clk_e_p/n, but capacitively coupled, goes to MGT 121
--      sfp_clk_e_n          : in std_logic;
      sfp_tx_p             : OUT STD_LOGIC;
      sfp_tx_n             : OUT STD_LOGIC;
      sfp_rx_p             : IN STD_LOGIC;
      sfp_rx_n             : IN STD_LOGIC;

      -- Backplane Connector I/O
      bp_id                : INOUT STD_LOGIC; -- 1-wire interface to the EEPROM on the backplane
      bp_id_pullup         : OUT STD_LOGIC;   -- Strong pullup enable

      bp_power_scl         : INOUT STD_LOGIC; -- Power control clock
      bp_power_sda         : INOUT STD_LOGIC; -- Power control data

--      bp_aux_io_p          : inout std_logic_vector(1 downto 0);
--      bp_aux_io_n          : inout std_logic_vector(1 downto 0);

      -- Power Interface
      power_sda            : INOUT STD_LOGIC;
      power_sdc            : INOUT STD_LOGIC;
      power_alert_n        : IN STD_LOGIC;

      shutdown             : OUT STD_LOGIC;                          -- Assert to latch power off

      -- Configuration IO
      spi_d                : INOUT STD_LOGIC_VECTOR(7 DOWNTO 4);        -- Other IO through startup block
      spi_cs               : INOUT STD_LOGIC_VECTOR(1 DOWNTO 1);        -- Other IO through startup block

      -- PTP - serial interface to AD5662BRM nanodacs, which controls the voltage to two oscillators
      -- * 20 MHz, which comes in as 20 MHz on clk_f 
      -- * 25 MHz, which is converted up to either 156.25 MHz or 125 MHz, depending on ptp_clk_sel, and 
      --   comes in on both sfp_clk_e_p/n and clk_e_p/n.
      --   sfp_clk_e_p/n could be used for synchronous ethernet/white rabbit
      -- AD5662BRM info -
      --   - ptp_sclk maximum frequency is MHz
      --   - data sampled on the falling edge of ptp_sclk
      --   - 24 bits per command, with
      --      - 6 don't cares
      --      - "00" for normal operation (other options are power-down states).
      --      - 16 data bits, straight binary 0 to 65535.
      ptp_pll_reset        : out std_logic;                          -- PLL reset
      ptp_clk_sel          : OUT STD_LOGIC;                          -- PTP Interface (156.25MH select when high)
      ptp_sync_n           : out std_logic_vector(1 downto 0);  -- bit(0) = active low enable for DAC controlling the clk_e = 25 MHz crystal (which is then upconverted to either 125 or 156.25 MHz), bit(1) = active low enable for DAC controlling the clk_f = 20 MHz crystal.  
      ptp_sclk             : out std_logic;
      ptp_din              : out std_logic;

      -- Misc IO
      led_din              : OUT STD_LOGIC;                          -- SPI Led Interface
      led_dout             : IN STD_LOGIC;
      led_cs               : OUT STD_LOGIC;
      led_sclk             : OUT STD_LOGIC;

      serial_id            : INOUT STD_LOGIC;                        -- Onboard serial number PROM & MAC ID
      serial_id_pullup     : OUT STD_LOGIC;

      hum_sda              : INOUT STD_LOGIC;                        -- Humidity & temperature chip
      hum_sdc              : INOUT STD_LOGIC;

      debug                : INOUT STD_LOGIC_VECTOR(3 DOWNTO 0);     -- General debug IOs
      version              : IN STD_LOGIC_VECTOR(1 DOWNTO 0));
END gemini_lru_dsp;

-------------------------------------------------------------------------------
ARCHITECTURE structure OF gemini_lru_dsp IS

   ---------------------------------------------------------------------------
   -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
   ---------------------------------------------------------------------------

   CONSTANT c_num_eth_lanes      : INTEGER := 6;
   CONSTANT c_default_ip         : STD_LOGIC_VECTOR(31 DOWNTO 0) := X"0a2000FE"; -- 10.32.0.254
   CONSTANT c_default_mac        : STD_LOGIC_VECTOR(47 DOWNTO 0) := x"C02B3C4D5E6F";
   CONSTANT c_max_packet_length  : INTEGER := 8192;
   CONSTANT c_tx_priority        : t_integer_arr(0 to 15) := (0,  -- Gemini M&C
                                                              4,  -- PTP
                                                              3,  -- DHCP
                                                              7,  -- ARP
                                                              6,  -- ICMP
                                                              0,  -- Gemini Pub/Sub
                                                              0,0,0,0,0,0,0,0,0,0);
   
   CONSTANT c_nof_mac            : INTEGER := 392*2;
   CONSTANT c_nof_mac_per_block  : INTEGER := c_nof_mac/8;
   CONSTANT c_nof_mac4           : INTEGER := c_nof_mac_per_block*8;

   ---------------------------------------------------------------------------
   -- SIGNAL DECLARATIONS  --
   ---------------------------------------------------------------------------

   SIGNAL clk_400                            : STD_LOGIC;
   SIGNAL clk_100                            : STD_LOGIC;
   SIGNAL clk_50                             : STD_LOGIC;
   SIGNAL clk_eth                            : STD_LOGIC;      -- RX Recovered clock (synchronous Ethernet reference)
   SIGNAL clk_ddr4                           : STD_LOGIC;

   SIGNAL system_reset_shift                 : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '1');
   SIGNAL system_reset                       : STD_LOGIC;
   SIGNAL system_locked                      : STD_LOGIC;
   SIGNAL end_of_startup                     : STD_LOGIC;

   SIGNAL ddr_ip_reset                       : STD_LOGIC;
   SIGNAL ddr_ip_reset_r                     : STD_LOGIC;
   SIGNAL ddr4_cal_done                      : STD_LOGIC;
   SIGNAL ddr4_cal_done_r                    : STD_LOGIC;
   SIGNAL ddr4_reset                         : STD_LOGIC;
   SIGNAL ddr4_sync_rst                      : STD_LOGIC;
   SIGNAL ddr4_axi4_mosi                     : t_axi4_full_mosi;
   SIGNAL ddr4_axi4_miso                     : t_axi4_full_miso;

   SIGNAL boot_mode_start                    : STD_LOGIC;
   SIGNAL boot_mode_done                     : STD_LOGIC;
   SIGNAL ddr4_data_msmatch_err              : STD_LOGIC;
   SIGNAL ddr4_write_err                     : STD_LOGIC;
   SIGNAL ddr4_read_err                      : STD_LOGIC;
   SIGNAL boot_mode_running                  : STD_LOGIC;
   SIGNAL prbs_mode_running                  : STD_LOGIC;
   SIGNAL led2_colour_e                      : STD_LOGIC_VECTOR(23 DOWNTO 0);

   SIGNAL local_mac                          : STD_LOGIC_VECTOR(47 DOWNTO 0);
   SIGNAL local_ip                           : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL prom_ip                            : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL eth_in_siso                        : t_axi4_siso;
   SIGNAL eth_in_sosi                        : t_axi4_sosi;
   SIGNAL eth_out_sosi                       : t_axi4_sosi;
   SIGNAL eth_out_siso                       : t_axi4_siso;
   SIGNAL eth_rx_reset                       : STD_LOGIC;
   SIGNAL eth_tx_reset                       : STD_LOGIC;
   SIGNAL ctl_rx_pause_ack                   : STD_LOGIC_VECTOR(8 DOWNTO 0);
   SIGNAL ctl_rx_pause_enable                : STD_LOGIC_VECTOR(8 DOWNTO 0);
   SIGNAL stat_rx_pause_req                  : STD_LOGIC_VECTOR(8 DOWNTO 0);
   SIGNAL eth_locked                         : STD_LOGIC;
   SIGNAL axi_rst                            : STD_LOGIC;
   signal gemini_mm_rst                      : std_logic;

   SIGNAL decoder_out_sosi                   : t_axi4_sosi_arr(0 TO c_num_eth_lanes-1);
   SIGNAL decoder_out_siso                   : t_axi4_siso_arr(0 TO c_num_eth_lanes-1);
   SIGNAL encoder_in_sosi                    : t_axi4_sosi_arr(0 TO c_num_eth_lanes-1);
   SIGNAL encoder_in_siso                    : t_axi4_siso_arr(0 TO c_num_eth_lanes-1);

   SIGNAL mc_master_mosi                     : t_axi4_full_mosi;
   SIGNAL mc_master_miso                     : t_axi4_full_miso;
   SIGNAL mc_lite_miso                       : t_axi4_lite_miso_arr(0 TO c_nof_lite_slaves-1);
   SIGNAL mc_lite_mosi                       : t_axi4_lite_mosi_arr(0 TO c_nof_lite_slaves-1);
   SIGNAL mc_full_miso                       : t_axi4_full_miso_arr(0 TO c_nof_full_slaves-1);
   SIGNAL mc_full_mosi                       : t_axi4_full_mosi_arr(0 TO c_nof_full_slaves-1);

   SIGNAL prom_startup_complete              : STD_LOGIC;
   SIGNAL local_prom_ip                      : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL serial_number                      : STD_LOGIC_VECTOR(31 DOWNTO 0);

   SIGNAL led1_colour                        : STD_LOGIC_VECTOR(23 DOWNTO 0);
   SIGNAL led2_colour                        : STD_LOGIC_VECTOR(23 DOWNTO 0);
   SIGNAL i_led3_colour                      : STD_LOGIC_VECTOR(23 DOWNTO 0);
   SIGNAL led3_colour                        : STD_LOGIC_VECTOR(23 DOWNTO 0);

   SIGNAL local_time                         : STD_LOGIC_VECTOR(63 DOWNTO 0);
   SIGNAL event_in                           : STD_LOGIC_VECTOR(31 DOWNTO 0);

   SIGNAL mbo_a_tx_clk_out                   : STD_LOGIC_VECTOR(0 TO 11);
   SIGNAL mbo_a_tx_disable                   : STD_LOGIC_VECTOR(0 TO 11);
   SIGNAL mbo_a_rx_disable                   : STD_LOGIC_VECTOR(0 TO 11);
   SIGNAL mbo_a_loopback                     : STD_LOGIC_VECTOR(2 DOWNTO 0);
   SIGNAL mbo_a_rx_locked                    : STD_LOGIC_VECTOR(0 TO 11);

   SIGNAL mbo_b_tx_clk_out                   : STD_LOGIC_VECTOR(0 TO 11);
   SIGNAL mbo_b_tx_disable                   : STD_LOGIC_VECTOR(0 TO 11);
   SIGNAL mbo_b_rx_disable                   : STD_LOGIC_VECTOR(0 TO 11);
   SIGNAL mbo_b_loopback                     : STD_LOGIC_VECTOR(2 DOWNTO 0);
   SIGNAL mbo_b_rx_locked                    : STD_LOGIC_VECTOR(0 TO 11);

   SIGNAL mbo_c_tx_clk_out                   : STD_LOGIC_VECTOR(0 TO 11);
   SIGNAL mbo_c_tx_disable                   : STD_LOGIC_VECTOR(0 TO 11);
   SIGNAL mbo_c_rx_disable                   : STD_LOGIC_VECTOR(0 TO 11);
   SIGNAL mbo_c_loopback                     : STD_LOGIC_VECTOR(2 DOWNTO 0);
   SIGNAL mbo_c_rx_locked                    : STD_LOGIC_VECTOR(0 TO 11);

   SIGNAL qsfp_d_tx_clk_out                  : STD_LOGIC;
   SIGNAL qsfp_d_tx_disable                  : STD_LOGIC_VECTOR(0 TO 3);
   SIGNAL qsfp_d_rx_disable                  : STD_LOGIC_VECTOR(0 TO 3);
   SIGNAL qsfp_d_loopback                    : STD_LOGIC_VECTOR(2 DOWNTO 0);
   SIGNAL qsfp_d_rx_locked                   : STD_LOGIC_VECTOR(0 TO 3);

   SIGNAL qsfp_c_tx_clk_out                  : STD_LOGIC;
   SIGNAL qsfp_c_tx_disable                  : STD_LOGIC_VECTOR(0 TO 3);
   SIGNAL qsfp_c_rx_disable                  : STD_LOGIC_VECTOR(0 TO 3);
   SIGNAL qsfp_c_loopback                    : STD_LOGIC_VECTOR(2 DOWNTO 0);
   SIGNAL qsfp_c_rx_locked                   : STD_LOGIC_VECTOR(0 TO 3);

   SIGNAL qsfp_b_tx_clk_out                  : STD_LOGIC_VECTOR(0 TO 3);
   SIGNAL qsfp_b_tx_disable                  : STD_LOGIC_VECTOR(0 TO 3);
   SIGNAL qsfp_b_rx_disable                  : STD_LOGIC_VECTOR(0 TO 3);
   SIGNAL qsfp_b_loopback                    : STD_LOGIC_VECTOR(2 DOWNTO 0);
   SIGNAL qsfp_b_rx_locked                   : STD_LOGIC_VECTOR(0 TO 3);

   SIGNAL qsfp_a_tx_clk_out                  : STD_LOGIC_VECTOR(0 TO 3);
   SIGNAL qsfp_a_tx_disable                  : STD_LOGIC_VECTOR(0 TO 3);
   SIGNAL qsfp_a_rx_disable                  : STD_LOGIC_VECTOR(0 TO 3);
   SIGNAL qsfp_a_loopback                    : STD_LOGIC_VECTOR(2 DOWNTO 0);
   SIGNAL qsfp_a_rx_locked                   : STD_LOGIC_VECTOR(0 TO 3);


   SIGNAL traffic_gen_clk                    : STD_LOGIC_VECTOR(0 TO 44);
   SIGNAL completion_status                  : t_slv_5_arr(0 TO 44);
   SIGNAL lane_ok                            : STD_LOGIC_VECTOR(0 TO 44);
   SIGNAL traffic_user_rx_reset              : STD_LOGIC_VECTOR(0 TO 44);
   SIGNAL traffic_user_tx_reset              : STD_LOGIC_VECTOR(0 TO 44);
   SIGNAL traffic_rx_lock                    : STD_LOGIC_VECTOR(0 TO 44);
   SIGNAL data_rx_siso                       : t_axi4_siso_arr(0 TO 44);
   SIGNAL data_rx_sosi                       : t_axi4_sosi_arr(0 TO 44);
   SIGNAL data_rx_sosi_reg                   : t_axi4_sosi_arr(0 TO 44);
   SIGNAL data_tx_siso                       : t_axi4_siso_arr(0 TO 44);
   SIGNAL data_tx_sosi                       : t_axi4_sosi_arr(0 TO 44);

   SIGNAL qmac_rx_locked                     : STD_LOGIC_vector(3 DOWNTO 0);
   SIGNAL qmac_rx_synced                     : STD_LOGIC_vector(3 DOWNTO 0);
   SIGNAL qmac_rx_aligned                    : STD_LOGIC;
   SIGNAL qmac_rx_status                     : STD_LOGIC;


   SIGNAL ctraffic_user_rx_reset             : STD_LOGIC;
   SIGNAL ctraffic_user_tx_reset             : STD_LOGIC;
   SIGNAL ctraffic_rx_aligned                : STD_LOGIC;
   SIGNAL cdata_tx_siso                      : t_lbus_siso;
   SIGNAL cdata_tx_sosi                      : t_lbus_sosi;
   SIGNAL cdata_rx_sosi                      : t_lbus_sosi;
   SIGNAL ctraffic_tx_enable                 : STD_LOGIC;
   SIGNAL ctraffic_rx_enable                 : STD_LOGIC;
   SIGNAL ctraffic_tx_send_rfi               : STD_LOGIC;
   SIGNAL ctraffic_tx_send_lfi               : STD_LOGIC;
   SIGNAL ctraffic_rsfec_tx_enable           : STD_LOGIC;
   SIGNAL ctraffic_rsfec_rx_enable           : STD_LOGIC;
   SIGNAL ctraffic_rsfec_error_mode          : STD_LOGIC;
   SIGNAL ctraffic_rsfec_enable_correction   : STD_LOGIC;
   SIGNAL ctraffic_rsfec_enable_indication   : STD_LOGIC;
   SIGNAL ctraffic_done                      : STD_LOGIC;
   SIGNAL ctraffic_aligned                   : STD_LOGIC;
   SIGNAL ctraffic_failed                    : STD_LOGIC;

   SIGNAL backplane_ip_valid                 : STD_LOGIC;
   SIGNAL backplane_ip                       : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL bp_prom_startup_complete           : STD_LOGIC;
   SIGNAL bp_serial_number                   : STD_LOGIC_VECTOR(31 DOWNTO 0);

   SIGNAL dhcp_start                         : STD_LOGIC;

   SIGNAL system_fields_rw                   : t_system_rw;
   SIGNAL system_fields_ro                   : t_system_ro;

   SIGNAL shutdown_extended                  : STD_LOGIC;
   SIGNAL shutdown_edge                      : STD_LOGIC;

   SIGNAL pps                                : STD_LOGIC;
   SIGNAL pps_extended                       : STD_LOGIC;
   SIGNAL eth_act                            : STD_LOGIC;
   SIGNAL eth_act_extended                   : STD_LOGIC;

   SIGNAL prom_spi_i                         : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL prom_spi_o                         : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL prom_spi_t                         : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL prom_spi_ss_o                      : STD_LOGIC;
   SIGNAL prom_spi_ss_t                      : STD_LOGIC;

   SIGNAL gnd                                : STD_LOGIC_VECTOR(255 DOWNTO 0);
   ---------------------------------------------------------------------------
   -- COMPONENT DECLARATIONS  --
   ---------------------------------------------------------------------------

   COMPONENT pkt_gen_mon
      PORT (
         gen_clk              : IN STD_LOGIC;
         mon_clk              : IN STD_LOGIC;
         dclk                 : IN STD_LOGIC;
         sys_reset            : IN STD_LOGIC;
         restart_tx_rx        : IN STD_LOGIC;
         send_continuous_pkts : IN STD_LOGIC;
         user_rx_reset        : IN STD_LOGIC;
         rx_axis_tvalid       : IN STD_LOGIC;
         rx_axis_tdata        : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
         rx_axis_tlast        : IN STD_LOGIC;
         rx_axis_tkeep        : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
         rx_axis_tuser        : IN STD_LOGIC;
         stat_rx_block_lock   : IN STD_LOGIC;
         user_tx_reset        : IN STD_LOGIC;
         tx_axis_tready       : IN STD_LOGIC;
         tx_axis_tvalid       : OUT STD_LOGIC;
         tx_axis_tdata        : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
         tx_axis_tlast        : OUT STD_LOGIC;
         tx_axis_tkeep        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
         tx_axis_tuser        : OUT STD_LOGIC;
         completion_status    : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
         rx_gt_locked_led     : OUT STD_LOGIC;
         rx_block_lock_led    : OUT STD_LOGIC);
   END COMPONENT;

   COMPONENT mac_40g_pkt_gen_mon
      GENERIC (
         PKT_NUM                 : INTEGER := 20);
      PORT (
         gen_clk                 : IN STD_LOGIC;
         mon_clk                 : IN STD_LOGIC;
         dclk                    : IN STD_LOGIC;
         usr_fsm_clk             : IN STD_LOGIC;
         sys_reset               : IN STD_LOGIC;
         restart_tx_rx           : IN STD_LOGIC;
         send_continuous_pkts    : IN STD_LOGIC;
         user_rx_reset           : IN STD_LOGIC;
         rx_axis_tvalid          : IN STD_LOGIC;
         rx_axis_tdata           : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
         rx_axis_tuser_ena0      : IN STD_LOGIC;
         rx_axis_tuser_sop0      : IN STD_LOGIC;
         rx_axis_tuser_eop0      : IN STD_LOGIC;
         rx_axis_tuser_mty0      : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
         rx_axis_tuser_err0      : IN STD_LOGIC;
         rx_axis_tuser_ena1      : IN STD_LOGIC;
         rx_axis_tuser_sop1      : IN STD_LOGIC;
         rx_axis_tuser_eop1      : IN STD_LOGIC;
         rx_axis_tuser_mty1      : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
         rx_axis_tuser_err1      : IN STD_LOGIC;
         rx_preambleout          : IN STD_LOGIC_VECTOR(55 DOWNTO 0);
         stat_rx_block_lock      : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
         stat_rx_synced          : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
         stat_rx_aligned         : IN STD_LOGIC;
         stat_rx_status          : IN STD_LOGIC;
         user_tx_reset           : IN STD_LOGIC;
         tx_axis_tready          : IN STD_LOGIC;
         tx_axis_tvalid          : OUT STD_LOGIC;
         tx_axis_tdata           : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
         tx_axis_tuser_ena0      : OUT STD_LOGIC;
         tx_axis_tuser_sop0      : OUT STD_LOGIC;
         tx_axis_tuser_eop0      : OUT STD_LOGIC;
         tx_axis_tuser_mty0      : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
         tx_axis_tuser_err0      : OUT STD_LOGIC;
         tx_axis_tuser_ena1      : OUT STD_LOGIC;
         tx_axis_tuser_sop1      : OUT STD_LOGIC;
         tx_axis_tuser_eop1      : OUT STD_LOGIC;
         tx_axis_tuser_mty1      : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
         tx_axis_tuser_err1      : OUT STD_LOGIC;
         tx_preamblein           : OUT  STD_LOGIC_VECTOR(55 DOWNTO 0);
         completion_status       : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
         rx_gt_locked_led        : OUT STD_LOGIC;
         rx_aligned_led          : OUT STD_LOGIC);
   END COMPONENT;


   COMPONENT mac_100g_pkt_gen_mon
      PORT (
         gen_mon_clk                            : IN STD_LOGIC;
         usr_tx_reset                           : IN STD_LOGIC;
         usr_rx_reset                           : IN STD_LOGIC;
         sys_reset                              : IN STD_LOGIC;
         send_continuous_pkts                   : IN STD_LOGIC;
         lbus_tx_rx_restart_in                  : IN STD_LOGIC;
         tx_rdyout                              : IN STD_LOGIC;
         tx_datain0                             : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
         tx_enain0                              : OUT STD_LOGIC;
         tx_sopin0                              : OUT STD_LOGIC;
         tx_eopin0                              : OUT STD_LOGIC;
         tx_errin0                              : OUT STD_LOGIC;
         tx_mtyin0                              : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
         tx_datain1                             : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
         tx_enain1                              : OUT STD_LOGIC;
         tx_sopin1                              : OUT STD_LOGIC;
         tx_eopin1                              : OUT STD_LOGIC;
         tx_errin1                              : OUT STD_LOGIC;
         tx_mtyin1                              : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
         tx_datain2                             : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
         tx_enain2                              : OUT STD_LOGIC;
         tx_sopin2                              : OUT STD_LOGIC;
         tx_eopin2                              : OUT STD_LOGIC;
         tx_errin2                              : OUT STD_LOGIC;
         tx_mtyin2                              : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
         tx_datain3                             : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
         tx_enain3                              : OUT STD_LOGIC;
         tx_sopin3                              : OUT STD_LOGIC;
         tx_eopin3                              : OUT STD_LOGIC;
         tx_errin3                              : OUT STD_LOGIC;
         tx_mtyin3                              : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
         tx_ovfout                              : IN STD_LOGIC;
         tx_unfout                              : IN STD_LOGIC;
         rx_dataout0                            : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
         rx_enaout0                             : IN STD_LOGIC;
         rx_sopout0                             : IN STD_LOGIC;
         rx_eopout0                             : IN STD_LOGIC;
         rx_errout0                             : IN STD_LOGIC;
         rx_mtyout0                             : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
         rx_dataout1                            : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
         rx_enaout1                             : IN STD_LOGIC;
         rx_sopout1                             : IN STD_LOGIC;
         rx_eopout1                             : IN STD_LOGIC;
         rx_errout1                             : IN STD_LOGIC;
         rx_mtyout1                             : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
         rx_dataout2                            : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
         rx_enaout2                             : IN STD_LOGIC;
         rx_sopout2                             : IN STD_LOGIC;
         rx_eopout2                             : IN STD_LOGIC;
         rx_errout2                             : IN STD_LOGIC;
         rx_mtyout2                             : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
         rx_dataout3                            : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
         rx_enaout3                             : IN STD_LOGIC;
         rx_sopout3                             : IN STD_LOGIC;
         rx_eopout3                             : IN STD_LOGIC;
         rx_errout3                             : IN STD_LOGIC;
         rx_mtyout3                             : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
         stat_rx_aligned                        : IN STD_LOGIC;
         ctl_tx_enable                          : OUT STD_LOGIC;
         ctl_tx_send_rfi                        : OUT STD_LOGIC;
         ctl_tx_send_lfi                        : OUT STD_LOGIC;
         ctl_rx_enable                          : OUT STD_LOGIC;
         ctl_rsfec_ieee_error_indication_mode   : OUT STD_LOGIC;
         ctl_rx_rsfec_enable                    : OUT STD_LOGIC;
         ctl_rx_rsfec_enable_correction         : OUT STD_LOGIC;
         ctl_rx_rsfec_enable_indication         : OUT STD_LOGIC;
         ctl_tx_rsfec_enable                    : OUT STD_LOGIC;
         tx_done_led                            : OUT STD_LOGIC;
         tx_busy_led                            : OUT STD_LOGIC;
         rx_gt_locked_led                       : OUT STD_LOGIC;
         rx_aligned_led                         : OUT STD_LOGIC;
         rx_done_led                            : OUT STD_LOGIC;
         rx_data_fail_led                       : OUT STD_LOGIC;
         rx_busy_led                            : OUT STD_LOGIC);
   END COMPONENT;

   COMPONENT ddr4_v2_2_3_axi_tg_top
      PORT (
         clk                              : IN STD_LOGIC;
         tg_rst                           : IN STD_LOGIC;
         boot_mode_start                  : IN STD_LOGIC;
         boot_mode_stop                   : IN STD_LOGIC;
         boot_mode_done                   : OUT STD_LOGIC;
         custom_mode_start                : IN STD_LOGIC;
         custom_mode_stop                 : IN STD_LOGIC;
         custom_mode_done                 : OUT STD_LOGIC;
         prbs_mode_start                  : IN STD_LOGIC;
         prbs_mode_stop                   : IN STD_LOGIC;
         prbs_mode_done                   : OUT STD_LOGIC;
         prbs_mode_seed                   : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
         axi_awready                      : IN STD_LOGIC;
         axi_awid                         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
         axi_awaddr                       : OUT STD_LOGIC_VECTOR(32 DOWNTO 0);
         axi_awlen                        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
         axi_awsize                       : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
         axi_awburst                      : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
         axi_awlock                       : OUT STD_LOGIC;
         axi_awcache                      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
         axi_awprot                       : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
         axi_awvalid                      : OUT STD_LOGIC;
         axi_wready                       : IN STD_LOGIC;
         axi_wdata                        : OUT STD_LOGIC_VECTOR(511 DOWNTO 0);
         axi_wstrb                        : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
         axi_wlast                        : OUT STD_LOGIC;
         axi_wvalid                       : OUT STD_LOGIC;
         axi_bid                          : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
         axi_bresp                        : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
         axi_bvalid                       : IN STD_LOGIC;
         axi_bready                       : OUT STD_LOGIC;
         axi_arready                      : IN STD_LOGIC;
         axi_arid                         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
         axi_araddr                       : OUT STD_LOGIC_VECTOR(32 DOWNTO 0);
         axi_arlen                        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
         axi_arsize                       : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
         axi_arburst                      : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
         axi_arlock                       : OUT STD_LOGIC;
         axi_arcache                      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
         axi_arprot                       : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
         axi_arvalid                      : OUT STD_LOGIC;
         axi_rid                          : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
         axi_rresp                        : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
         axi_rvalid                       : IN STD_LOGIC;
         axi_rdata                        : IN STD_LOGIC_VECTOR(511 DOWNTO 0);
         axi_rlast                        : IN STD_LOGIC;
         axi_rready                       : OUT STD_LOGIC;
         vio_axi_tg_mismatch_error        : OUT STD_LOGIC;
         vio_axi_tg_expected_bits         : OUT STD_LOGIC_VECTOR(511 DOWNTO 0);
         vio_axi_tg_actual_bits           : OUT STD_LOGIC_VECTOR(511 DOWNTO 0);
         vio_axi_tg_error_bits            : OUT STD_LOGIC_VECTOR(511 DOWNTO 0);
         vio_axi_tg_data_beat_count       : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
         vio_axi_tg_error_status_id       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
         vio_axi_tg_error_status_addr     : OUT STD_LOGIC_VECTOR(32 DOWNTO 0);
         vio_axi_tg_error_status_len      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
         vio_axi_tg_error_status_size     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
         vio_axi_tg_error_status_burst    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
         vio_axi_tg_write_resp_error      : OUT STD_LOGIC;
         vio_axi_tg_read_resp_error       : OUT STD_LOGIC;
         vio_axi_tg_boot_mode_running     : OUT STD_LOGIC;
         vio_axi_tg_custom_mode_running   : OUT STD_LOGIC;
         vio_axi_tg_prbs_mode_running     : OUT STD_LOGIC;
         vio_axi_tg_dbg_instr_pointer     : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
   END COMPONENT;

    COMPONENT ila_0
    PORT (
   	    clk : IN STD_LOGIC;
   	    probe0 : IN STD_LOGIC_VECTOR(99 DOWNTO 0));
    END COMPONENT;

    COMPONENT ila_big1
    PORT (
        clk : IN STD_LOGIC;
        probe0 : IN STD_LOGIC_VECTOR(36 DOWNTO 0)
    );
    END COMPONENT  ;


   -- These signals added after being removed from the ports for the cut-down version of the FPGA for signal processing
   signal mbo_b_reset : STD_LOGIC;                          -- LVCMOS 1.8V
   signal mbo_c_reset : std_logic;

   -- for capture by the debug core.
   signal seg0_sop, seg0_eop, seg0_ena, seg1_sop, seg1_eop, seg1_ena, seg0_err, seg1_err : std_logic;
   signal seg0_mty, seg1_mty : std_logic_vector(2 downto 0);
   signal qsfp_c_led_del2, qsfp_c_led_del1 : std_logic;
   signal qsfp_d_led_del2, qsfp_d_led_del1 : std_logic;

   signal mac40G : std_logic_vector(47 downto 0);

   signal ptp_clk        : std_logic;                     -- 125 MHz clock
   signal ptp_time_frac  : std_logic_vector(26 downto 0); -- fraction of a second in units of 8 ns
   signal ptp_time_sec   : std_logic_vector(31 downto 0);
   signal LFAADecode_dbg : std_logic_vector(13 downto 0);
   signal LFAA_tx_fsm, LFAA_stats_fsm, LFAA_rx_fsm : std_logic_vector(3 downto 0);
   signal goodpacket, nonSPEAD : std_logic;
   
   signal wvalid0, wvalid1, wvalid2, wvalid3, rvalid0, rvalid1, rvalid2, rvalid3 : std_logic;
   
   signal req_crsb_state    : std_logic_vector(2 downto 0);
   signal req_main_state    : std_logic_vector(3 downto 0);
   signal replay_state      : std_logic_vector(3 downto 0);
   signal completion_state  : std_logic_vector(3 downto 0);
   signal rq_state          : std_logic_vector(3 downto 0);
   signal rq_stream_state   : std_logic_vector(3 downto 0);
   signal resp_state        : std_logic_vector(3 downto 0);
   signal crqb_fifo_rd_data_sel_out : std_logic_vector(87 DOWNTO 0);
   signal crqb_fifo_rd_out : std_logic_vector(2 downto 0);  
   
   signal s2mm_in_dbg  : t_axi4_sosi;  -- Sink in
   signal s2mm_out_dbg : t_axi4_siso; -- Sink out
   signal s2mm_cmd_in_dbg : t_axi4_sosi; -- Sink in
   signal s2mm_cmd_out_dbg : t_axi4_siso; -- Sink out
   signal s2mm_sts_in_dbg :  t_axi4_siso;  -- Source in
   signal s2mm_sts_out_dbg : t_axi4_sosi;  

   signal shutdown_extended_del1, shutdown_extended_del2, shutdown_extended_del3, shutdown_extended_del4 : std_logic := '0';
   signal rst_qsfp_a, rst_qsfp_b, rst_qsfp_c, rst_qsfp_d : std_logic;
   
   signal LFAA_data : std_logic_vector(127 downto 0);
   signal LFAA_valid : std_logic;
   signal dbg_timer_expire : std_logic;
   signal dbg_timer  :  std_logic_vector(15 downto 0);
   signal clk_400_rst : std_logic;
   
   component ptpPLL125
   port(
       clk_out1          : out    std_logic;
       clk_in1_p         : in     std_logic;
       clk_in1_n         : in     std_logic);
   end component;
   
    COMPONENT system_clock
    PORT (clk_400       : OUT    STD_LOGIC;
          clk_100       : OUT    STD_LOGIC;
          clk_50        : OUT    STD_LOGIC;
          locked        : OUT    STD_LOGIC;
          resetn        : IN    STD_LOGIC;
          clk_in1       : IN     STD_LOGIC);
    END COMPONENT;
    
    signal wall_clk :  std_logic;
    
begin

    gnd <= (OTHERS  => '0');

    ---------------------------------------------------------------------------
    -- CLOCKING & RESETS  --
    ---------------------------------------------------------------------------

    -- Generate the 250 MHz "wall clock" from the 125MHz OCXO. 
    ptpPLL : ptpPLL125
    port map ( 
        -- Clock out ports  
        clk_out1 => wall_clk,
        -- Clock in ports
        clk_in1_p => clk_e_p,
        clk_in1_n => clk_e_n
    );

    system_pll: system_clock
    PORT MAP (
      clk_in1  => clk_h,
      clk_400  => clk_400,
      clk_100  => clk_100,
      clk_50  => clk_50,
      resetn   => end_of_startup,
      locked   => system_locked);

    system_pll_reset: PROCESS(clk_100)
    BEGIN
        IF RISING_EDGE(clk_100) THEN
            system_reset_shift <= system_reset_shift(6 DOWNTO 0) & NOT(system_locked);
            rst_qsfp_a <= system_reset or system_fields_rw.qsfpgty_resets(0);
            rst_qsfp_b <= system_reset or system_fields_rw.qsfpgty_resets(1);
            rst_qsfp_c <= system_reset or system_fields_rw.qsfpgty_resets(2);
            rst_qsfp_d <= system_reset or system_fields_rw.qsfpgty_resets(3);
        END IF;
    END PROCESS;
    
    system_reset <= system_reset_shift(7);
    
    
    -- transfer reset to the 25GE clock domain
    xpm_cdc_rst_inst : xpm_cdc_pulse
    generic map (
        DEST_SYNC_FF => 4,   -- DECIMAL; range: 2-10
        INIT_SYNC_FF => 0,   -- DECIMAL; 0=disable simulation init values, 1=enable simulation init values
        REG_OUTPUT => 1,     -- DECIMAL; 0=disable registered output, 1=enable registered output
        RST_USED => 0,       -- DECIMAL; 0=no reset, 1=implement reset
        SIM_ASSERT_CHK => 0  -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    )
    port map (
        dest_pulse => clk_400_rst,  -- 1-bit output: Outputs a pulse the size of one dest_clk period when a pulse transfer is correctly initiated on src_pulse input.
        dest_clk => clk_400,        -- 1-bit input: Destination clock.
        dest_rst => '0',            -- 1-bit input: optional; required when RST_USED = 1
        src_clk => clk_100,         -- 1-bit input: Source clock.
        src_pulse => system_reset,  -- 1-bit input: Rising edge of this signal initiates a pulse transfer to the destination clock domain.
        src_rst => '0'              -- 1-bit input: optional; required when RST_USED = 1
    );    
    
    ---------------------------------------------------------------------------
    -- 25G MACs  --
    ---------------------------------------------------------------------------
    
    ---------------------------------------------------------------------------
    -- MBO Interfaces  --
    ---------------------------------------------------------------------------

    u_mb0a_1: ENTITY gemini_lru_board_lib.mbo
    GENERIC MAP (
        g_technology    => g_technology,
        g_mbo           => MBO_A)
    PORT MAP (
        mbo_clk_p       => mbo_a_clk_p,
        mbo_clk_n       => mbo_a_clk_n,
        mbo_tx_p        => mbo_a_tx_p,
        mbo_tx_n        => mbo_a_tx_n,
        mbo_rx_p        => mbo_a_rx_p,
        mbo_rx_n        => mbo_a_rx_n,
        sys_rst         => system_reset,
        axi_rst         => axi_rst,
        rst_clk         => clk_100,
        axi_clk         => clk_eth,
        loopback        => mbo_a_loopback,
        tx_disable      => mbo_a_tx_disable,
        rx_disable      => mbo_a_rx_disable,
        tx_clk_out      => mbo_a_tx_clk_out,
        link_locked     => mbo_a_rx_locked,
        s_axi_mosi      => mc_lite_mosi(c_mboa_ethernet_mbo_lite_index),
        s_axi_miso      => mc_lite_miso(c_mboa_ethernet_mbo_lite_index),
        user_rx_reset   => traffic_user_rx_reset(0 TO 11),
        user_tx_reset   => traffic_user_tx_reset(0 TO 11),
        data_rx_sosi    => data_rx_sosi(0 TO 11),
        data_rx_siso    => data_rx_siso(0 TO 11),
        data_tx_sosi    => data_tx_sosi(0 TO 11),
        data_tx_siso    => data_tx_siso(0 TO 11)
    );

------------------------------------------------------------------------------------------------------------------------------
-- mbo_b and mbo_c commented out for the time being; 
-- one mbo is fine for signal processing with up to 36 FPGAs (which on current (March 2019) plans we hit in Array Release 2)
--    
--   u_mb0b_1: ENTITY gemini_lru_board_lib.mbo
--   GENERIC MAP (
--      g_technology    => g_technology,
--      g_mbo           => MBO_B)
--   PORT MAP (
--      mbo_clk_p       => mbo_b_clk_p,
--      mbo_clk_n       => mbo_b_clk_n,
--      mbo_tx_p        => mbo_b_tx_p,
--      mbo_tx_n        => mbo_b_tx_n,
--      mbo_rx_p        => mbo_b_rx_p,
--      mbo_rx_n        => mbo_b_rx_n,
--      sys_rst         => system_reset,
--      axi_rst         => axi_rst,
--      rst_clk            => clk_100,
--      axi_clk         => clk_eth,
--      loopback        => mbo_b_loopback,
--      tx_disable      => mbo_b_tx_disable,
--      rx_disable      => mbo_b_rx_disable,
--      tx_clk_out      => mbo_b_tx_clk_out,
--      link_locked     => mbo_b_rx_locked,
--      s_axi_mosi      => mc_lite_mosi(c_mbob_ethernet_mbo_lite_index),
--      s_axi_miso      => mc_lite_miso(c_mbob_ethernet_mbo_lite_index),
--      user_rx_reset   => traffic_user_rx_reset(12 TO 23),
--      user_tx_reset   => traffic_user_tx_reset(12 TO 23),
--      data_rx_sosi    => data_rx_sosi(12 TO 23),
--      data_rx_siso    => data_rx_siso(12 TO 23),
--      data_tx_sosi    => data_tx_sosi(12 TO 23),
--      data_tx_siso    => data_tx_siso(12 TO 23));

--   u_mb0c_1: ENTITY gemini_lru_board_lib.mbo
--   GENERIC MAP (
--      g_technology    => g_technology,
--      g_mbo           => MBO_C)
--   PORT MAP (
--      mbo_clk_p       => mbo_c_clk_p,
--      mbo_clk_n       => mbo_c_clk_n,
--      mbo_tx_p        => mbo_c_tx_p,
--      mbo_tx_n        => mbo_c_tx_n,
--      mbo_rx_p        => mbo_c_rx_p,
--      mbo_rx_n        => mbo_c_rx_n,
--      sys_rst         => system_reset,
--      axi_rst         => axi_rst,
--      rst_clk         => clk_100,
--      axi_clk         => clk_eth,
--      loopback        => mbo_c_loopback,
--      tx_disable      => mbo_c_tx_disable,
--      rx_disable      => mbo_c_rx_disable,
--      tx_clk_out      => mbo_c_tx_clk_out,
--      link_locked     => mbo_c_rx_locked,
--      s_axi_mosi      => mc_lite_mosi(c_mboc_ethernet_mbo_lite_index),
--      s_axi_miso      => mc_lite_miso(c_mboc_ethernet_mbo_lite_index),
--      user_rx_reset   => traffic_user_rx_reset(24 TO 35),
--      user_tx_reset   => traffic_user_tx_reset(24 TO 35),
--      data_rx_sosi    => data_rx_sosi(24 TO 35),
--      data_rx_siso    => data_rx_siso(24 TO 35),
--      data_tx_sosi    => data_tx_sosi(24 TO 35),
--      data_tx_siso    => data_tx_siso(24 TO 35));

    mbo_support: ENTITY gemini_lru_board_lib.mbo_control
    GENERIC MAP (
        g_technology   => g_technology)
    PORT MAP (
        clk               => clk_eth,
        rst               => axi_rst,
        s_axi_mosi        => mc_lite_mosi(c_mbo_lite_index),
        s_axi_miso        => mc_lite_miso(c_mbo_lite_index),
        mbo_a_tx_disable  => mbo_a_tx_disable,
        mbo_a_rx_disable  => mbo_a_rx_disable,
        mbo_a_loopback    => mbo_a_loopback,
        mbo_a_rx_locked   => mbo_a_rx_locked,
        mbo_b_tx_disable  => mbo_b_tx_disable,
        mbo_b_rx_disable  => mbo_b_rx_disable,
        mbo_b_loopback    => mbo_b_loopback,
        mbo_b_rx_locked   => mbo_b_rx_locked,
        mbo_c_tx_disable  => mbo_c_tx_disable,
        mbo_c_rx_disable  => mbo_c_rx_disable,
        mbo_c_loopback    => mbo_c_loopback,
        mbo_c_rx_locked   => mbo_c_rx_locked,
        mbo_a_reset       => mbo_a_reset,
        mbo_b_reset       => mbo_b_reset,
        mbo_c_reset       => mbo_c_reset,
        mbo_int_n         => mbo_int_n,
        mbo_sda           => mbo_sda,
        mbo_scl           => mbo_scl
    );

    ---------------------------------------------------------------------------
    -- QSFP Interfaces  --
    ---------------------------------------------------------------------------

    u_qsfp_a: ENTITY gemini_lru_board_lib.qsfp_25g
    GENERIC MAP (
         g_technology      => g_technology,
         g_qsfp            => QSFP_A)
    PORT MAP(
        qsfp_clk_p        => qsfp_a_clk_p,
        qsfp_clk_n        => qsfp_a_clk_n,
        qsfp_tx_p         => qsfp_a_tx_p,
        qsfp_tx_n         => qsfp_a_tx_n,
        qsfp_rx_p         => qsfp_a_rx_p,
        qsfp_rx_n         => qsfp_a_rx_n,
        sys_rst           => rst_qsfp_a, -- system_reset,
        axi_rst           => axi_rst,
        rst_clk           => clk_100,
        axi_clk           => clk_eth,
        loopback          => qsfp_a_loopback,
        tx_disable        => qsfp_a_tx_disable,
        rx_disable        => qsfp_a_rx_disable,
        tx_clk_out        => qsfp_a_tx_clk_out,
        link_locked       => qsfp_a_rx_locked,
        s_axi_mosi        => mc_lite_mosi(c_qsfpa_ethernet_quad_qsfp_lite_index),
        s_axi_miso        => mc_lite_miso(c_qsfpa_ethernet_quad_qsfp_lite_index),
        user_rx_reset     => traffic_user_rx_reset(41 TO 44),
        user_tx_reset     => traffic_user_tx_reset(41 TO 44),
        data_rx_sosi      => data_rx_sosi(41 TO 44),
        data_rx_siso      => data_rx_siso(41 TO 44),
        data_tx_sosi      => data_tx_sosi(41 TO 44),
        data_tx_siso      => data_tx_siso(41 TO 44)
    );

    u_qsfp_b: ENTITY gemini_lru_board_lib.qsfp_25g
    GENERIC MAP (
        g_technology      => g_technology,
        g_qsfp            => QSFP_B)
    PORT MAP(
        qsfp_clk_p        => qsfp_b_clk_p,
        qsfp_clk_n        => qsfp_b_clk_n,
        qsfp_tx_p         => qsfp_b_tx_p,
        qsfp_tx_n         => qsfp_b_tx_n,
        qsfp_rx_p         => qsfp_b_rx_p,
        qsfp_rx_n         => qsfp_b_rx_n,
        sys_rst           => rst_qsfp_b, -- system_reset,
        axi_rst           => axi_rst,
        rst_clk           => clk_100,
        axi_clk           => clk_eth,
        loopback          => qsfp_b_loopback,
        tx_disable        => qsfp_b_tx_disable,
        rx_disable        => qsfp_b_rx_disable,
        tx_clk_out        => qsfp_b_tx_clk_out,
        link_locked       => qsfp_b_rx_locked,
        s_axi_mosi        => mc_lite_mosi(c_qsfpb_ethernet_quad_qsfp_lite_index),
        s_axi_miso        => mc_lite_miso(c_qsfpb_ethernet_quad_qsfp_lite_index),
        user_rx_reset     => traffic_user_rx_reset(37 TO 40),
        user_tx_reset     => traffic_user_tx_reset(37 TO 40),
        data_rx_sosi      => data_rx_sosi(37 TO 40),
        data_rx_siso      => data_rx_siso(37 TO 40),
        data_tx_sosi      => data_tx_sosi(37 TO 40),
        data_tx_siso      => data_tx_siso(37 TO 40)
    );

    u_qsfp_c: ENTITY gemini_lru_board_lib.qsfp_100g
    GENERIC MAP (
        g_technology             => g_technology,
        g_qsfp                   => QSFP_C)
    PORT MAP(
        qsfp_clk_p               => qsfp_c_clk_p,     -- Dedicated 161MHz clock
        qsfp_clk_n               => qsfp_c_clk_n,
        qsfp_tx_p                => qsfp_c_tx_p,
        qsfp_tx_n                => qsfp_c_tx_n,
        qsfp_rx_p                => qsfp_c_rx_p,
        qsfp_rx_n                => qsfp_c_rx_n,
        sys_rst                  => rst_qsfp_c, -- system_reset,
        axi_rst                  => axi_rst,
        rst_clk                  => clk_100,
        axi_clk                  => clk_eth,
        loopback                 => qsfp_c_loopback,
        tx_disable               => qsfp_c_tx_disable(0),
        rx_disable               => qsfp_c_rx_disable(0),
        tx_clk_out               => qsfp_c_tx_clk_out,
        link_locked              => qsfp_c_rx_locked(0),
        s_axi_mosi               => mc_lite_mosi(c_qsfpc_ethernet_qsfp_lite_index),
        s_axi_miso               => mc_lite_miso(c_qsfpc_ethernet_qsfp_lite_index),
        user_rx_reset            => ctraffic_user_rx_reset,
        user_tx_reset            => ctraffic_user_tx_reset,
        data_rx_sosi             => cdata_rx_sosi,
        data_tx_sosi             => cdata_tx_sosi,
        data_tx_siso             => cdata_tx_siso
    );

    qsfp_c_rx_locked(1 TO 3) <= (OTHERS => qsfp_c_rx_locked(0));

    u_qsfp_d: ENTITY gemini_lru_board_lib.qsfp_40g
    GENERIC MAP (
        g_technology      => g_technology,
        g_qsfp            => QSFP_D)
    PORT MAP(
        qsfp_clk_p        => clk_c_p(3),          -- 156.25MHz clock shared
        qsfp_clk_n        => clk_c_n(3),
        qsfp_tx_p         => qsfp_d_tx_p,
        qsfp_tx_n         => qsfp_d_tx_n,
        qsfp_rx_p         => qsfp_d_rx_p,
        qsfp_rx_n         => qsfp_d_rx_n,
        sys_rst           => rst_qsfp_d,  -- system_reset,
        axi_rst           => axi_rst,
        rst_clk           => clk_100,
        axi_clk           => clk_eth,
        loopback          => qsfp_d_loopback,
        tx_disable        => qsfp_d_tx_disable(0),
        rx_disable        => qsfp_d_rx_disable(0),
        tx_clk_out        => qsfp_d_tx_clk_out,
        link_locked       => qsfp_d_rx_locked(0),
        rx_locked         => qmac_rx_locked,
        rx_synced         => qmac_rx_synced,
        rx_aligned        => qmac_rx_aligned,
        rx_status         => qmac_rx_status,
        user_rx_reset     => traffic_user_rx_reset(36),
        user_tx_reset     => traffic_user_tx_reset(36),
        s_axi_mosi        => mc_lite_mosi(c_qsfpd_ethernet_qsfp_lite_index),
        s_axi_miso        => mc_lite_miso(c_qsfpd_ethernet_qsfp_lite_index),
        -- received data from optics (sosi = source out, sink in)
        data_rx_sosi      => data_rx_sosi(36),
        data_rx_siso      => data_rx_siso(36),
        -- data to be sent to the optics
        data_tx_sosi      => data_tx_sosi(36),
        data_tx_siso      => data_tx_siso(36)
    );

    qsfp_d_rx_locked(1 TO 3) <= (OTHERS => qsfp_d_rx_locked(0));

    qsfp_support: ENTITY gemini_lru_board_lib.qsfp_control
    GENERIC MAP (
        g_technology      => g_technology)
    PORT MAP (
        clk               => clk_eth,
        rst               => axi_rst,
        s_axi_mosi        => mc_lite_mosi(c_qsfp_lite_index),
        s_axi_miso        => mc_lite_miso(c_qsfp_lite_index),
        qsfp_a_tx_disable => qsfp_a_tx_disable,
        qsfp_a_rx_disable => qsfp_a_rx_disable,
        qsfp_a_loopback   => qsfp_a_loopback,
        qsfp_a_rx_locked  => qsfp_a_rx_locked,
        qsfp_b_tx_disable => qsfp_b_tx_disable,
        qsfp_b_rx_disable => qsfp_b_rx_disable,
        qsfp_b_loopback   => qsfp_b_loopback,
        qsfp_b_rx_locked  => qsfp_b_rx_locked,
   --     qsfp_c_tx_disable => qsfp_c_tx_disable,
   --     qsfp_c_rx_disable => qsfp_c_rx_disable,
        qsfp_c_loopback   => qsfp_c_loopback,
        qsfp_c_rx_locked  => qsfp_c_rx_locked,
        qsfp_d_tx_disable => qsfp_d_tx_disable,
        qsfp_d_rx_disable => qsfp_d_rx_disable,
        qsfp_d_loopback   => qsfp_d_loopback,
        qsfp_d_rx_locked  => qsfp_d_rx_locked,
        qsfp_a_mod_prs_n  => qsfp_a_mod_prs_n,
        qsfp_a_mod_sel    => qsfp_a_mod_sel,
        qsfp_a_reset      => qsfp_a_reset,
        qsfp_b_mod_prs_n  => qsfp_b_mod_prs_n,
        qsfp_b_mod_sel    => qsfp_b_mod_sel,
        qsfp_b_reset      => qsfp_b_reset,
        qsfp_c_mod_prs_n  => qsfp_c_mod_prs_n,
        qsfp_c_mod_sel    => qsfp_c_mod_sel,
        qsfp_c_reset      => qsfp_c_reset,
        qsfp_d_mod_prs_n  => qsfp_d_mod_prs_n,
        qsfp_d_mod_sel    => qsfp_d_mod_sel,
        qsfp_d_reset      => qsfp_d_reset,
        qsfp_int_n        => qsfp_int_n,
        qsfp_sda          => qsfp_sda,
        qsfp_scl          => qsfp_scl
    );


    qsfp_a_led <= '1' WHEN qsfp_a_rx_locked /= X"0" ELSE '0';
    qsfp_b_led <= '1' WHEN qsfp_b_rx_locked /= X"0" ELSE '0';
   
    process(qsfp_c_tx_clk_out)
    begin
        if rising_edge(qsfp_c_tx_clk_out) then
            if qsfp_c_rx_locked /= X"0" then
                qsfp_c_led_del1 <= '1';
            else
                qsfp_c_led_del1 <= '0';
            end if;
            qsfp_c_led_del2 <= qsfp_c_led_del1;
            qsfp_c_led <= qsfp_c_led_del2;
        end if;
    end process;
   
    process(qsfp_d_tx_clk_out)
    begin
        if rising_edge(qsfp_d_tx_clk_out) then
            if qsfp_d_rx_locked /= X"0" then
                qsfp_d_led_del1 <= '1';
            else
                qsfp_d_led_del1 <= '0';
            end if;
            qsfp_d_led_del2 <= qsfp_d_led_del1;
            qsfp_d_led <= qsfp_d_led_del2;
        end if;
    end process;
    
    ---------------------------------------------------------------------------
    -- Packet Generators  --
    ---------------------------------------------------------------------------

    traffic_gen_clk(0 TO 11)  <= mbo_a_tx_clk_out;
    traffic_gen_clk(12 TO 23) <= mbo_b_tx_clk_out;
    traffic_gen_clk(24 TO 35) <= mbo_c_tx_clk_out;
    traffic_gen_clk(36)       <= qsfp_d_tx_clk_out;
    traffic_gen_clk(37 TO 40) <= qsfp_b_tx_clk_out;
    traffic_gen_clk(41 TO 44) <= qsfp_a_tx_clk_out;
 
    traffic_rx_lock(0 TO 11)  <= mbo_a_rx_locked;
    traffic_rx_lock(12 TO 23) <= mbo_b_rx_locked;
    traffic_rx_lock(24 TO 35) <= mbo_c_rx_locked;
 
    traffic_rx_lock(36) <= qsfp_d_rx_locked(0);
    traffic_rx_lock(37 TO 40) <= qsfp_b_rx_locked;
    traffic_rx_lock(41 TO 44) <= qsfp_a_rx_locked;
 
 
     trdygen0 : for i in 0 to 35 generate
         data_rx_siso(i).tready <= '1'; -- Always ready, but not actually used in MAC
     end generate;
     trdygen1 : for i in 37 to 44 generate
         data_rx_siso(i).tready <= '1';
     end generate;
 
     pkt_gen: FOR i IN 0 TO 40 GENERATE
 
         data_reg: PROCESS(traffic_gen_clk(i))
         BEGIN
             IF rising_edge(traffic_gen_clk(i)) THEN
                 data_rx_sosi_reg(i) <= data_rx_sosi(i);
             END IF;
         END PROCESS;
     
         --
         -- No packet generation/monitoring in DSP version.
         data_tx_sosi(i).tvalid <= '0';
         data_tx_sosi(i).tdata <= (others => '0');
         data_tx_sosi(i).tlast <= '0';
         data_tx_sosi(i).tkeep <= (others => '0');
         data_tx_sosi(i).tuser <= (others => '0');
         completion_status(i) <= "00001";
         
         lane_ok(i) <= '1' WHEN completion_status(i) = "00001" ELSE '0';
 
    END GENERATE;
 
    -- Note (41) is used for the debug port
    completion_status(41) <= "00001";
    lane_ok(41) <= '1';
    
     
    pkt_gen42_44: FOR i IN 42 TO 44 GENERATE
 
         data_reg: PROCESS(traffic_gen_clk(i))
         BEGIN
             IF rising_edge(traffic_gen_clk(i)) THEN
                 data_rx_sosi_reg(i) <= data_rx_sosi(i);
             END IF;
         END PROCESS;
     
         --
         -- No packet generation/monitoring in DSP version.
         data_tx_sosi(i).tvalid <= '0';
         data_tx_sosi(i).tdata <= (others => '0');
         data_tx_sosi(i).tlast <= '0';
         data_tx_sosi(i).tkeep <= (others => '0');
         data_tx_sosi(i).tuser <= (others => '0');
         completion_status(i) <= "00001";
         
         lane_ok(i) <= '1' WHEN completion_status(i) = "00001" ELSE '0';
 
    END GENERATE;
    
 
    led3_colour(23 DOWNTO 8) <= X"00FF" WHEN lane_ok = (lane_ok'RANGE => '1') ELSE X"FF00";
    
    completion_status(36) <= "00000";
    data_tx_sosi(36).tvalid <= '0';
    data_tx_sosi(36).tdata <= (others => '0');
    data_tx_sosi(36).tuser <= (others => '0');
    
    u_mac_100g_pkt_gen_mon: mac_100g_pkt_gen_mon
    PORT MAP (
        gen_mon_clk                            => qsfp_c_tx_clk_out,
        usr_tx_reset                           => ctraffic_user_tx_reset,
        usr_rx_reset                           => ctraffic_user_rx_reset,
        sys_reset                              => system_reset,
        lbus_tx_rx_restart_in                  => '0',
        send_continuous_pkts                   => '1',
        tx_rdyout                              => cdata_tx_siso.ready,
        tx_datain0                             => cdata_tx_sosi.data(127 DOWNTO 0),
        tx_enain0                              => cdata_tx_sosi.valid(0),
        tx_sopin0                              => cdata_tx_sosi.sop(0),
        tx_eopin0                              => cdata_tx_sosi.eop(0),
        tx_errin0                              => cdata_tx_sosi.error(0),
        tx_mtyin0                              => cdata_tx_sosi.empty(0),
        tx_datain1                             => cdata_tx_sosi.data(255 DOWNTO 128),
        tx_enain1                              => cdata_tx_sosi.valid(1),
        tx_sopin1                              => cdata_tx_sosi.sop(1),
        tx_eopin1                              => cdata_tx_sosi.eop(1),
        tx_errin1                              => cdata_tx_sosi.error(1),
        tx_mtyin1                              => cdata_tx_sosi.empty(1),
        tx_datain2                             => cdata_tx_sosi.data(383 DOWNTO 256),
        tx_enain2                              => cdata_tx_sosi.valid(2),
        tx_sopin2                              => cdata_tx_sosi.sop(2),
        tx_eopin2                              => cdata_tx_sosi.eop(2),
        tx_errin2                              => cdata_tx_sosi.error(2),
        tx_mtyin2                              => cdata_tx_sosi.empty(2),
        tx_datain3                             => cdata_tx_sosi.data(511 DOWNTO 384),
        tx_enain3                              => cdata_tx_sosi.valid(3),
        tx_sopin3                              => cdata_tx_sosi.sop(3),
        tx_eopin3                              => cdata_tx_sosi.eop(3),
        tx_errin3                              => cdata_tx_sosi.error(3),
        tx_mtyin3                              => cdata_tx_sosi.empty(3),
        tx_ovfout                              => cdata_tx_siso.overflow,
        tx_unfout                              => cdata_tx_siso.underflow,
        rx_dataout0                            => cdata_rx_sosi.data(127 DOWNTO 0),
        rx_enaout0                             => cdata_rx_sosi.valid(0),
        rx_sopout0                             => cdata_rx_sosi.sop(0),
        rx_eopout0                             => cdata_rx_sosi.eop(0),
        rx_errout0                             => cdata_rx_sosi.error(0),
        rx_mtyout0                             => cdata_rx_sosi.empty(0),
        rx_dataout1                            => cdata_rx_sosi.data(255 DOWNTO 128),
        rx_enaout1                             => cdata_rx_sosi.valid(1),
        rx_sopout1                             => cdata_rx_sosi.sop(1),
        rx_eopout1                             => cdata_rx_sosi.eop(1),
        rx_errout1                             => cdata_rx_sosi.error(1),
        rx_mtyout1                             => cdata_rx_sosi.empty(1),
        rx_dataout2                            => cdata_rx_sosi.data(383 DOWNTO 256),
        rx_enaout2                             => cdata_rx_sosi.valid(2),
        rx_sopout2                             => cdata_rx_sosi.sop(2),
        rx_eopout2                             => cdata_rx_sosi.eop(2),
        rx_errout2                             => cdata_rx_sosi.error(2),
        rx_mtyout2                             => cdata_rx_sosi.empty(2),
        rx_dataout3                            => cdata_rx_sosi.data(511 DOWNTO 384),
        rx_enaout3                             => cdata_rx_sosi.valid(3),
        rx_sopout3                             => cdata_rx_sosi.sop(3),
        rx_eopout3                             => cdata_rx_sosi.eop(3),
        rx_errout3                             => cdata_rx_sosi.error(3),
        rx_mtyout3                             => cdata_rx_sosi.empty(3),
        stat_rx_aligned                        => ctraffic_rx_aligned,
        ctl_tx_enable                          => ctraffic_tx_enable,
        ctl_tx_send_rfi                        => OPEN,
        ctl_tx_send_lfi                        => OPEN,
        ctl_rx_enable                          => ctraffic_rx_enable,
        ctl_rsfec_ieee_error_indication_mode   => OPEN,
        ctl_rx_rsfec_enable                    => OPEN,
        ctl_rx_rsfec_enable_correction         => OPEN,
        ctl_rx_rsfec_enable_indication         => OPEN,
        ctl_tx_rsfec_enable                    => OPEN,
        tx_done_led                            => ctraffic_done,
        tx_busy_led                            => OPEN,
        rx_gt_locked_led                       => OPEN,
        rx_aligned_led                         => ctraffic_aligned,
        rx_done_led                            => OPEN,
        rx_data_fail_led                       => ctraffic_failed,
        rx_busy_led                            => OPEN
    );
    
    qsfp_c_tx_disable(0) <= NOT ctraffic_tx_enable;
    qsfp_c_rx_disable(0) <= NOT ctraffic_rx_enable;
    ctraffic_rx_aligned <= qsfp_c_rx_locked(0);
    
    i_led3_colour(7 DOWNTO 0) <= X"FF" WHEN ctraffic_done = '1' AND ctraffic_aligned = '1' AND  ctraffic_failed = '0' ELSE X"00";
    
    u_cmac_led_reg: ENTITY common_lib.common_delay
    GENERIC MAP (
        g_dat_w     => 8,
        g_depth     => 1)
    PORT MAP (
        clk         => qsfp_c_tx_clk_out,
        in_val      => '1',
        in_dat      => i_led3_colour(7 DOWNTO 0),
        out_dat     => led3_colour(7 DOWNTO 0)
    );

    ---------------------------------------------------------------------------
    -- Ethernet MAC & Framework  --
    ---------------------------------------------------------------------------

    u_mace_mac: ENTITY gemini_lru_board_lib.mace_mac
    GENERIC MAP (
        g_technology         => g_technology)
    PORT MAP (
        sfp_rx_p             => sfp_rx_p,
        sfp_rx_n             => sfp_rx_n,
        sfp_tx_p             => sfp_tx_p,
        sfp_tx_n             => sfp_tx_n,
        sfp_clk_c_p          => sfp_clk_c_p,
        sfp_clk_c_n          => sfp_clk_c_n,
        system_reset         => system_reset,
        rst_clk              => clk_100,
        tx_clk               => clk_eth,
        rx_clk               => OPEN,             -- Synchronous clock for PTP timing reference (also unreliable)
        axi_clk              => clk_eth,
        eth_rx_reset         => eth_rx_reset,
        eth_in_sosi          => eth_in_sosi,
        eth_in_siso          => eth_in_siso,
        eth_out_sosi         => eth_out_sosi,
        eth_out_siso         => eth_out_siso,
        eth_locked           => eth_locked,
        eth_tx_reset         => eth_tx_reset,
        local_mac            => local_mac,
        s_axi_mosi           => mc_lite_mosi(c_ethernet_mace_lite_index),
        s_axi_miso           => mc_lite_miso(c_ethernet_mace_lite_index),
        ctl_rx_pause_ack     => ctl_rx_pause_ack,
        ctl_rx_pause_enable  => ctl_rx_pause_enable,
        stat_rx_pause_req    => stat_rx_pause_req
    );
    
    axi_rst <= eth_tx_reset;
 
    sfp_support: ENTITY gemini_lru_board_lib.sfp_control
    GENERIC MAP (
        g_technology   => g_technology)
    PORT MAP (
        rst            => axi_rst,
        clk            => clk_eth,
        s_axi_mosi     => mc_lite_mosi(c_sfp_lite_index),
        s_axi_miso     => mc_lite_miso(c_sfp_lite_index),
        sfp_sda        => sfp_sda,
        sfp_scl        => sfp_scl,
        sfp_fault      => sfp_fault,
        sfp_tx_enable  => sfp_tx_enable,
        sfp_mod_abs    => sfp_mod_abs
    );
    sfp_led <= eth_locked;
 
    ---------------------------------------------------------------------------
    -- MACE Protocol Blocks  --
    ---------------------------------------------------------------------------

    u_eth_rx: ENTITY eth_lib.eth_rx
    GENERIC MAP (
        g_technology      => g_technology,
        g_num_eth_lanes   => c_num_eth_lanes)
    PORT MAP (
        clk               => clk_eth,
        rst               => axi_rst,   -- do not use gemini_mm_rst, as it is only for modules downstream of the gemini block.
        mymac_addr        => local_mac,
        eth_in_sosi       => eth_in_sosi,
        eth_out_sosi      => decoder_out_sosi,
        eth_out_siso      => decoder_out_siso
    );
    
    u_eth_tx : ENTITY eth_lib.eth_tx
    GENERIC MAP (
        g_technology         => g_technology,
        g_num_frame_inputs   => c_num_eth_lanes,
        g_max_packet_length  => c_max_packet_length,
        g_lane_priority      => c_tx_priority)
    PORT MAP (
        eth_tx_clk           => clk_eth,
        eth_rx_clk           => clk_eth,
        axi_clk              => clk_eth,
        axi_rst              => axi_rst,  -- do not use gemini_mm_rst, as it is only for modules downstream of the gemini block.
        eth_tx_rst           => eth_tx_reset,
        eth_address_ip       => local_ip,
        eth_address_mac      => local_mac,
        eth_pause_rx_enable  => ctl_rx_pause_enable,
        eth_pause_rx_req     => stat_rx_pause_req,
        eth_pause_rx_ack     => ctl_rx_pause_ack,
        eth_out_sosi         => eth_out_sosi,
        eth_out_siso         => eth_out_siso,
        framer_in_sosi       => encoder_in_sosi,
        framer_in_siso       => encoder_in_siso);
  
    u_gemini_server: ENTITY gemini_server_lib.gemini_server
    GENERIC MAP (
        g_technology         => g_technology,
        g_txfr_timeout       => 6250,
        g_min_recycle_secs   => 30)                      -- Need to timeout connections straight away
    PORT MAP (
        clk                  => clk_eth,
        rst                  => axi_rst,
        mm_reset_out         => gemini_mm_rst,  -- out std_logic; -- reset to downstream modules on the mm bus, to prevent lockup from broken transactions issued by the datamover when it is reset.
        ethrx_in             => decoder_out_sosi(0),
        ethrx_out            => decoder_out_siso(0),
        ethtx_in             => encoder_in_siso(0),
        ethtx_out            => encoder_in_sosi(0),
        mm_in                => mc_master_miso,
        mm_out               => mc_master_mosi,
        tod_in               => system_fields_ro.time_uptime,
        -- debug
        req_csrb_state => req_crsb_state, -- out std_logic_vector(2 downto 0);
        req_main_state => req_main_state, -- out std_logic_vector(3 downto 0);
        replay_state   => replay_state,   -- out std_logic_vector(3 downto 0);
        completion_state => completion_state, --  out std_logic_vector(3 downto 0);
        rq_state         => rq_state,        -- out std_logic_vector(3 downto 0);
        rq_stream_state  => rq_stream_state, -- out std_logic_vector(3 downto 0);
        resp_state       => resp_state,       -- out std_logic_vector(3 downto 0);
        crqb_fifo_rd_data_sel_out => crqb_fifo_rd_data_sel_out, --  out std_logic_vector(87 DOWNTO 0);
        crqb_fifo_rd_out => crqb_fifo_rd_out,  -- out std_logic_vector(2 downto 0)
        -- debug commands to datamover
        s2mm_in_dbg  => s2mm_in_dbg, -- : out t_axi4_sosi;  -- Sink in
        s2mm_out_dbg => s2mm_out_dbg, -- : out t_axi4_siso; -- Sink out
        -- AXI4S Sink: S2MM Command
        s2mm_cmd_in_dbg => s2mm_cmd_in_dbg, -- : out t_axi4_sosi; -- Sink in
        s2mm_cmd_out_dbg => s2mm_cmd_out_dbg, -- : OUT t_axi4_siso; -- Sink out
        -- AXI4S Source: M_AXIS_S2MM_STS
        s2mm_sts_in_dbg => s2mm_sts_in_dbg, -- : out t_axi4_siso;  -- Source in
        s2mm_sts_out_dbg => s2mm_sts_out_dbg, -- : OUT t_axi4_sosi  -- Source out
        dbg_timer_expire => dbg_timer_expire, -- out std_logic;
        dbg_timer => dbg_timer -- : out std_logic_vector(15 downto 0)
    );
 
    decoder_out_siso(1).tready <= '1';
 
    dhcp_start <= eth_locked AND prom_startup_complete;
 
    u_dhcp_protocol: ENTITY dhcp_lib.dhcp_protocol
    GENERIC MAP (
        g_technology         => g_technology,
        -- Startup delay (after reset) before transmitting (in mS)
        -- The switch takes 30 seconds to wake up when the new bitfile is loaded, so wait a bit past that before requesting an IP address. 
        g_startup_delay      => 35000                     
    )
    PORT MAP (
        axi_clk              => clk_eth,
        axi_rst              => axi_rst,
        mm_rst               => axi_rst, -- in std_logic, for logic connected to s_axi_mosi, s_axi_miso.
        ip_address_default   => prom_ip,
        mac_address          => local_mac,
        serial_number        => serial_number,
        dhcp_start           => dhcp_start,
        ip_address           => local_ip,
        ip_event             => event_in(0),
        s_axi_mosi           => mc_lite_mosi(c_dhcp_lite_index),
        s_axi_miso           => mc_lite_miso(c_dhcp_lite_index),
        frame_in_sosi        => decoder_out_sosi(2),
        frame_in_siso        => decoder_out_siso(2),
        frame_out_sosi       => encoder_in_sosi(2),
        frame_out_siso       => encoder_in_siso(2)
    );
  
    u_arp_protocol: ENTITY arp_lib.arp_responder
    GENERIC MAP (
        g_technology   => g_technology)
    PORT MAP (
        clk            => clk_eth,
        rst            => axi_rst,
        eth_addr_ip    => local_ip,
        eth_addr_mac   => local_mac,
        frame_in_sosi  => decoder_out_sosi(3),
        frame_in_siso  => decoder_out_siso(3),
        frame_out_siso => encoder_in_siso(3),
        frame_out_sosi => encoder_in_sosi(3));
  
    u_icmp_protocol: ENTITY ping_protocol_lib.ping_protocol
    PORT MAP (
        clk            => clk_eth,
        rst            => axi_rst,
        my_mac         => local_mac,
        eth_in_sosi    => decoder_out_sosi(4),
        eth_in_siso    => decoder_out_siso(4),
        eth_out_sosi   => encoder_in_sosi(4),
        eth_out_siso   => encoder_in_siso(4)
    );
  
    u_pubsub_protocol: ENTITY gemini_subscription_lib.subscription_protocol
    GENERIC MAP (
        g_technology      => g_technology,
        g_num_clients     => 3)
    PORT MAP (
        axi_clk           => clk_eth,
        axi_rst           => axi_rst,
        mm_rst            => axi_rst, -- in std_logic, for logic connected to s_axi_mosi, s_axi_miso.
        time_in           => local_time,
        event_in          => event_in,
        s_axi_mosi        => mc_lite_mosi(c_gemini_subscription_lite_index),
        s_axi_miso        => mc_lite_miso(c_gemini_subscription_lite_index),
        stream_out_sosi   => encoder_in_sosi(5),
        stream_out_siso   => encoder_in_siso(5)
    );
  
    decoder_out_siso(5).tready <= '1';


    ---------------------------------------------------------------------------
    -- Bus Interconnect  --
    ---------------------------------------------------------------------------

    u_interconnect: ENTITY work.gemini_lru_dsp_bus_top
    PORT MAP (
        CLK            => clk_eth,
        RST            => gemini_mm_rst, -- axi_rst,
        SLA_IN         => mc_master_mosi,
        SLA_OUT        => mc_master_miso,
        MSTR_IN_LITE   => mc_lite_miso,
        MSTR_OUT_LITE  => mc_lite_mosi,
        MSTR_IN_FULL   => mc_full_miso,
        MSTR_OUT_FULL  => mc_full_mosi
    );

  ---------------------------------------------------------------------------
  -- DDR4 Memory  --
  ---------------------------------------------------------------------------

--   u_cal_pipe: ENTITY common_lib.common_delay
--   GENERIC MAP (
--      g_dat_w  => 1,
--      g_depth  => 1)
--   PORT MAP (
--      clk         => clk_ddr4,
--      in_val      => '1',
--      in_dat(0)   => ddr4_cal_done,
--      out_dat(0)  => ddr4_cal_done_r);


--   boot_mode_start <= ddr4_cal_done and not ddr4_cal_done_r; --boot_mode_start needs to be a pulse

--   u_ddr4_v2_2_3_axi_tg_top: ddr4_v2_2_3_axi_tg_top
--   PORT MAP (
--      clk                            => clk_ddr4,
--      tg_rst                         => ddr4_sync_rst,
--      boot_mode_start                => boot_mode_start,
--      boot_mode_stop                 => '0',
--      boot_mode_done                 => boot_mode_done,
--      custom_mode_start              => '0',
--      custom_mode_stop               => '0',
--      custom_mode_done               => OPEN,
--      prbs_mode_start                => boot_mode_done,
--      prbs_mode_stop                 => '0',
--      prbs_mode_done                 => OPEN,
--      prbs_mode_seed                 => X"ABCD1234",
--      axi_awready                    => ddr4_axi4_miso.awready,
--      axi_awid                       => ddr4_axi4_mosi.awid(3 DOWNTO 0),
--      axi_awaddr                     => ddr4_axi4_mosi.awaddr,
--      axi_awlen                      => ddr4_axi4_mosi.awlen,
--      axi_awsize                     => ddr4_axi4_mosi.awsize,
--      axi_awburst                    => ddr4_axi4_mosi.awburst,
--      axi_awlock                     => OPEN,
--      axi_awcache                    => ddr4_axi4_mosi.awcache,
--      axi_awprot                     => OPEN,
--      axi_awvalid                    => ddr4_axi4_mosi.awvalid,
--      axi_wready                     => ddr4_axi4_miso.wready ,
--      axi_wdata                      => ddr4_axi4_mosi.wdata,
--      axi_wstrb                      => ddr4_axi4_mosi.wstrb,
--      axi_wlast                      => ddr4_axi4_mosi.wlast,
--      axi_wvalid                     => ddr4_axi4_mosi.wvalid,
--      axi_bid                        => ddr4_axi4_miso.bid(3 DOWNTO 0),
--      axi_bresp                      => ddr4_axi4_miso.bresp,
--      axi_bvalid                     => ddr4_axi4_miso.bvalid,
--      axi_bready                     => ddr4_axi4_mosi.bready,
--      axi_arready                    => ddr4_axi4_miso.arready,
--      axi_arid                       => ddr4_axi4_mosi.arid(3 DOWNTO 0),
--      axi_araddr                     => ddr4_axi4_mosi.araddr,
--      axi_arlen                      => ddr4_axi4_mosi.arlen,
--      axi_arsize                     => ddr4_axi4_mosi.arsize,
--      axi_arburst                    => ddr4_axi4_mosi.arburst,
--      axi_arlock                     => OPEN,
--      axi_arcache                    => ddr4_axi4_mosi.arcache,
--      axi_arprot                     => OPEN,
--      axi_arvalid                    => ddr4_axi4_mosi.arvalid,
--      axi_rid                        => ddr4_axi4_miso.rid(3 DOWNTO 0),
--      axi_rresp                      => ddr4_axi4_miso.rresp,
--      axi_rvalid                     => ddr4_axi4_miso.rvalid,
--      axi_rdata                      => ddr4_axi4_miso.rdata,
--      axi_rlast                      => ddr4_axi4_miso.rlast,
--      axi_rready                     => ddr4_axi4_mosi.rready,
--      -- Axi tg Error status signals
--      vio_axi_tg_mismatch_error      => ddr4_data_msmatch_err,
--      vio_axi_tg_expected_bits       => OPEN,
--      vio_axi_tg_actual_bits         => OPEN,
--      vio_axi_tg_error_bits          => OPEN,
--      vio_axi_tg_data_beat_count     => OPEN,
--      vio_axi_tg_error_status_id     => OPEN,
--      vio_axi_tg_error_status_addr   => OPEN,
--      vio_axi_tg_error_status_len    => OPEN,
--      vio_axi_tg_error_status_size   => OPEN,
--      vio_axi_tg_error_status_burst  => OPEN,
--      vio_axi_tg_write_resp_error    => ddr4_write_err,
--      vio_axi_tg_read_resp_error     => ddr4_read_err,
--      vio_axi_tg_boot_mode_running   => boot_mode_running,
--      vio_axi_tg_custom_mode_running => OPEN,
--      vio_axi_tg_prbs_mode_running   => prbs_mode_running,
--      vio_axi_tg_dbg_instr_pointer   => OPEN);


--   led2_colour_e(23 DOWNTO 16) <= X"FF" WHEN ddr4_write_err = '1' OR  ddr4_read_err = '1' ELSE X"00";
--   led2_colour_e(15 DOWNTO 8) <= X"FF" WHEN boot_mode_running = '1' OR prbs_mode_running = '1' ELSE X"00";
--   led2_colour_e(7 DOWNTO 0) <= X"FF" WHEN ddr4_data_msmatch_err = '1' ELSE X"00";

     -- If uncommenting this, also enable the timing constraint in the gemini_lru_dsp.xdc file
     --
--   u_led_pipe: ENTITY common_lib.common_delay
--   GENERIC MAP (
--      g_dat_w  => 24,
--      g_depth  => 2)
--   PORT MAP (
--      clk         => clk_ddr4,
--      in_val      => '1',
--      in_dat      => led2_colour_e,
--      out_dat     => led2_colour);
    led2_colour <= (others => '0');

--   -- Reset on startup or under register control
--   ddr_ip_reset <= system_reset OR ddr4_reset;

--   -- Domain cross (level only)
--   ddr_reset_reg: ENTITY common_lib.common_pipeline
--   GENERIC MAP (
--      g_pipeline    => 2,
--      g_in_dat_w    => 1,
--      g_out_dat_w   => 1)
--   PORT MAP (
--      rst         => '0',
--      clk         => clk_100,
--      clken       => '1',
--      in_clr      => '0',
--      in_en       => '1',
--      in_dat(0)   => ddr_ip_reset,
--      out_dat(0)  => ddr_ip_reset_r);


--   u_ddr4: ENTITY tech_ddr4_lib.tech_ddr4
--   GENERIC MAP (
--      g_technology         => g_technology)
--   PORT MAP (
--      sys_clk_p            => clk_g_p,
--      sys_clk_n            => clk_g_n,
--      sys_rst              => ddr_ip_reset_r,
--      areset_n             => '1',
--      ui_clk               => clk_ddr4,
--      ui_clk_sync_rst      => ddr4_sync_rst,
--      init_calib_complete  => ddr4_cal_done,
--      axi4_mosi            => ddr4_axi4_mosi,
--      axi4_miso            => ddr4_axi4_miso,
--      ddr4_reset_n         => ddr4_reset_n,
--      ddr4_cke             => ddr4_cke,
--      ddr4_ck_c            => ddr4_ck_n,
--      ddr4_ck_t            => ddr4_ck_p,
--      ddr4_bg              => ddr4_bg,
--      ddr4_ba              => ddr4_ba,
--      ddr4_adr             => ddr4_adr,
--      ddr4_act_n           => ddr4_act_n,
--      ddr4_cs_n            => ddr4_cs(1 DOWNTO 0),
--      ddr4_odt             => ddr4_odt,
--      ddr4_dm_dbi_n        => ddr4_dm,
--      ddr4_dq              => ddr4_dq,
--      ddr4_dqs_c           => ddr4_dqs_n,
--      ddr4_dqs_t           => ddr4_dqs_p);

--   ddr4_cs(3 DOWNTO 2) <= (OTHERS => '1');

--   ddr4_support: ENTITY gemini_lru_board_lib.ddr4_control
--   GENERIC MAP (
--      g_technology      => g_technology)
--   PORT MAP (
--      clk               => clk_eth,
--      rst               => axi_rst,
--      s_axi_mosi        => mc_lite_mosi(c_ddr4_lite_index),
--      s_axi_miso        => mc_lite_miso(c_ddr4_lite_index),
--      ddr4_calibrated   => ddr4_cal_done,
--      ddr4_reset        => ddr4_reset,
--      ddr4_sda          => ddr4_sda,
--      ddr4_scl          => ddr4_scl);

  ---------------------------------------------------------------------------
  -- LED SUPPORT  --
  ---------------------------------------------------------------------------

    -- Use the local pps to generate a LED pulse
    led_pps_extend : ENTITY common_lib.common_pulse_extend
    GENERIC MAP (
       g_extend_w  => 23) -- 84ms on time
    PORT MAP (
       clk         => clk_100,
       rst         => '0',
       p_in        => pps,
       ep_out      => pps_extended);

    eth_act_cross: ENTITY common_lib.common_async
    GENERIC MAP (
       g_delay_len => 1)
    PORT MAP (
       rst         => '0',
       clk         => clk_eth,
       din         => eth_in_sosi.tlast,
       dout        => eth_act);

    -- Ethernet Activity
    led_act_extend : ENTITY common_lib.common_pulse_extend
    GENERIC MAP (
       g_extend_w  => 24) -- 167ms on time
    PORT MAP (
       clk         => clk_100,
       rst         => '0',
       p_in        => eth_act,
       ep_out      => eth_act_extended);

    -- Status LED
    led1_colour <= X"bc42f4" WHEN pps_extended = '1' ELSE             -- 1pps (Purple)
                   X"20f410" WHEN eth_act_extended = '1' ELSE         -- Ethernet Act (Green)
                   X"000000";

    u_led_driver : ENTITY spi_lib.spi_max6966
    GENERIC MAP (
       g_simulation  => g_sim,
       g_input_clk   => 100)
    PORT MAP (
       clk           => clk_100,
       rst           => system_reset,
       enable        => '1',
       led1_colour   => led1_colour,
       led2_colour   => led2_colour,
       led3_colour   => led3_colour,
       din           => led_din,
       sclk          => led_sclk,
       cs            => led_cs,
       dout          => led_dout);

   ---------------------------------------------------------------------------
   -- HARDWARE BOARD SUPPORT  --
   ---------------------------------------------------------------------------

    pmbus_support: ENTITY gemini_lru_board_lib.pmbus_control
    GENERIC MAP (
       g_technology   => g_technology)
    PORT MAP (
       clk            => clk_eth,
       rst            => axi_rst,
       s_axi_mosi     => mc_lite_mosi(c_pmbus_lite_index),
       s_axi_miso     => mc_lite_miso(c_pmbus_lite_index),
       power_sda      => power_sda,
       power_sdc      => power_sdc,
       power_alert_n  => power_alert_n);

    onewire_prom: ENTITY gemini_lru_board_lib.prom_interface
    GENERIC MAP (
       g_technology      => g_technology,
       g_default_ip      => c_default_ip,
       g_default_mac     => c_default_mac)
    PORT MAP (
       clk               => clk_eth,
       rst               => axi_rst,
       mac               => local_mac,
       ip                => local_prom_ip,
       ip_valid          => OPEN,
       serial_number     => serial_number,
       aux               => OPEN,
       startup_complete  => prom_startup_complete,
       prom_present      => OPEN,
       s_axi_mosi        => mc_lite_mosi(c_onewire_prom_lite_index),
       s_axi_miso        => mc_lite_miso(c_onewire_prom_lite_index),
       onewire_strong    => serial_id_pullup,
       onewire           => serial_id);

    humidity_support: ENTITY gemini_lru_board_lib.humidity_control
    GENERIC MAP (
       g_technology   => g_technology)
    PORT MAP (
       clk            => clk_eth,
       rst            => axi_rst,
       s_axi_mosi     => mc_lite_mosi(c_humidity_lite_index),
       s_axi_miso     => mc_lite_miso(c_humidity_lite_index),
       hum_sda        => hum_sda,
       hum_scl        => hum_sdc);

    -- Use backplane IP address if available
    prom_ip <= backplane_ip WHEN backplane_ip_valid = '1' ELSE
               local_prom_ip;

    config_prom: ENTITY tech_axi4_quadspi_prom_lib.tech_axi4_quadspi_prom
    GENERIC MAP (
       g_technology   => g_technology)
    PORT MAP (
       axi_clk        => clk_eth,
       spi_clk        => clk_100,
       axi_rst        => axi_rst,
       spi_interrupt  => OPEN,
       spi_mosi       => mc_full_mosi(c_axi4_quadspi_prom_full_index),
       spi_miso       => mc_full_miso(c_axi4_quadspi_prom_full_index),
       spi_i          => prom_spi_i,
       spi_o          => prom_spi_o,
       spi_t          => prom_spi_t,
       spi_ss_i       => spi_cs(1),
       spi_ss_o       => prom_spi_ss_o,
       spi_ss_t       => prom_spi_ss_t,
       end_of_startup => end_of_startup);

    -- Second SPI PROM CS pin not through startup block
    spi_cs(1) <= prom_spi_ss_o WHEN prom_spi_ss_t = '0' ELSE 'Z';

    spi_d(4) <= prom_spi_o(0) WHEN prom_spi_t(0) = '0' ELSE 'Z';
    prom_spi_i(0) <= spi_d(4);

    spi_d(5) <= prom_spi_o(1) WHEN prom_spi_t(1) = '0' ELSE 'Z';
    prom_spi_i(1) <= spi_d(5);

    spi_d(6) <= prom_spi_o(2) WHEN prom_spi_t(2) = '0' ELSE 'Z';
    prom_spi_i(2) <= spi_d(6);

    spi_d(7) <= prom_spi_o(3) WHEN prom_spi_t(3) = '0' ELSE 'Z';
    prom_spi_i(3) <= spi_d(7);

    system_monitor: ENTITY tech_system_monitor_lib.tech_system_monitor
    GENERIC MAP (
       g_technology      => g_technology)
    PORT MAP (
       axi_clk           => clk_eth,
       axi_reset         => axi_rst,
       axi_lite_mosi     => mc_lite_mosi(c_system_monitor_lite_index),
       axi_lite_miso     => mc_lite_miso(c_system_monitor_lite_index),
       over_temperature  => event_in(2),
       voltage_alarm     => OPEN,
       temp_out          => OPEN,
       v_p               => '0',
       v_n               => '0',
       vaux_p            => X"0000",
       vaux_n            => X"0000");

   ---------------------------------------------------------------------------
   -- Backplane Interfaces  --
   ---------------------------------------------------------------------------

    backplane_prom: ENTITY gemini_lru_board_lib.prom_interface
    GENERIC MAP (
       g_technology      => g_technology,
       g_default_ip      => c_default_ip,
       g_default_mac     => c_default_mac)
    PORT MAP (
       clk               => clk_eth,
       rst               => axi_rst,
       mac               => OPEN,
       ip                => backplane_ip,
       ip_valid          => backplane_ip_valid,
       aux               => OPEN,
       serial_number     => bp_serial_number,          -- | 0x80 (8bits) | Slot (8bits) | BP SN (16 bits) |
       startup_complete  => bp_prom_startup_complete,
       prom_present      => OPEN,
       s_axi_mosi        => mc_lite_mosi(c_backplane_prom_onewire_prom_lite_index),
       s_axi_miso        => mc_lite_miso(c_backplane_prom_onewire_prom_lite_index),
       onewire_strong    => bp_id_pullup,
       onewire           => bp_id);

    bp_power_control: ENTITY gemini_lru_board_lib.backplane_control
    GENERIC MAP (
       g_technology   => g_technology)
    PORT MAP (
       rst            => axi_rst,
       clk            => clk_eth,
       s_axi_mosi     => mc_lite_mosi(c_backplane_control_lite_index),
       s_axi_miso     => mc_lite_miso(c_backplane_control_lite_index),
       bp_sda         => bp_power_sda,
       bp_scl         => bp_power_scl);

   ---------------------------------------------------------------------------
   -- TOP Level Registers  --
   ---------------------------------------------------------------------------

    fpga_regs: ENTITY work.gemini_lru_dsp_system_reg
    GENERIC MAP (
       g_technology      => g_technology)
    PORT MAP (
       mm_clk            => clk_eth,
       mm_rst            => axi_rst,
       sla_in            => mc_lite_mosi(c_system_lite_index),
       sla_out           => mc_lite_miso(c_system_lite_index),
       system_fields_rw  => system_fields_rw,
       system_fields_ro  => system_fields_ro);

    -- Build Date
    u_useraccese2: USR_ACCESSE2
    PORT MAP (
       CFGCLK     => OPEN,
       DATA       => system_fields_ro.build_date,
       DATAVALID  => OPEN);

    -- Uptime counter
    uptime_cnt: ENTITY gemini_lru_board_lib.uptime_counter
    GENERIC MAP (
       g_tod_width    => 14,
       g_clk_freq     => 100.0E6)
    PORT MAP (
       clk            => clk_100,
       rst            => system_reset,
       pps            => pps,
       tod_rollover   => system_fields_ro.time_wrapped,
       tod            => system_fields_ro.time_uptime);

    -- Broadcast shutdown request
    event_in(1) <= system_fields_rw.control_lru_shutdown;

    -- Shutdown logic
    shutdown_reg_edge: ENTITY common_lib.common_evt
    GENERIC MAP(
       g_evt_type  => "RISING")
    PORT MAP (
       clk         => clk_eth,
       in_sig      => system_fields_rw.control_lru_shutdown,
       out_evt     => shutdown_edge);

    shutdown_timer: ENTITY common_lib.common_pulse_extend
    GENERIC MAP (
       g_extend_w  => 27) -- 0.859s
    PORT MAP (
       clk         => clk_eth,
       rst         => axi_rst,
       p_in        => shutdown_edge,
       ep_out      => shutdown_extended);

    process(clk_eth)
    begin
       if rising_edge(clk_eth) then
          -- pipeline stages to prevent timing problems, since this can be routed right across the chip
          -- (axi_rst and shutdown are at distant places on the chip).
          shutdown_extended_del1 <= shutdown_extended;
          shutdown_extended_del2 <= shutdown_extended_del1;
          shutdown_extended_del3 <= shutdown_extended_del2;
          shutdown_extended_del4 <= shutdown_extended_del3;
       end if;
    end process;

    shutdown_timer_edge: ENTITY common_lib.common_evt
    GENERIC MAP(
       g_evt_type  => "FALLING",
       g_out_reg   => TRUE)
    PORT MAP (
       clk         => clk_eth,
       in_sig      => shutdown_extended_del4,
       out_evt     => shutdown);


    debug(0) <= '0';

    --------------------------------------------------------------------------
    -- Signal Processing
    dsp_topi : entity dsp_top_lib.DSP_topNoHBM
    generic map (
        ARRAYRELEASE => 0, -- : integer range -2 to 5 := 0;
        g_sim        => false -- : BOOLEAN := FALSE
    )
    port map (
        -- Source IP address used for debug data; connect to the DHCP assigned address.
        i_srcIPAddr     => local_ip, -- in(31:0);
        i_srcIPAddr_clk => clk_eth,  -- in std_logic;
        -- Processing clocks
        i_clk100 => clk_100, --  in std_logic; -- HBM reference clock
        -- HBM_AXI_clk and wallClk should be derived from the OCXO on the gemini boards, so that clocks on different boards run very close to the same frequency.
        i_HBM_clk => clk_400, --  in std_logic; -- 400 MHz for the vcu128 board, up to 450 for production devices. Also used for general purpose processing.
        i_HBM_clk_rst => clk_400_rst, --  in std_logic;
        i_wall_clk => wall_clk, --  in std_logic;    -- 250 MHz, derived from the 125MHz OCXO. Used for timing of events (e.g. when to start reading in the corner turn)
        -- 40GE LFAA ingest data
        i_LFAA40GE => data_rx_sosi(36),     -- in t_axi4_sosi;
        o_LFAA40GE => data_rx_siso(36),     -- out t_axi4_siso;
        i_LFAA40GE_clk => qsfp_d_tx_clk_out, -- in std_logic;
        i_mac40G => mac40G,                 -- in std_logic_vector(47 downto 0); --    mac40G <= x"aabbccddeeff";        
        -- 25 GE debug port (output of the interconnect module)
        -- connected to QSFP A
        o_dbg25GE => data_tx_sosi(41), -- out t_axi4_sosi;
        i_dbg25GE => data_tx_siso(41), -- in  t_axi4_siso;
        i_dbg25GE_clk => qsfp_a_tx_clk_out(0), -- in std_logic;
        -- XYZ interconnect inputs
        i_gtyZdata  => (others => (others => '0')), -- in t_slv_64_arr(6 downto 0);
        i_gtyZValid => "0000000", -- in std_logic_vector(6 downto 0);
        i_gtyZSof   => "0000000", -- in std_logic_vector(6 downto 0);
        i_gtyZEof   => "0000000", -- in std_logic_vector(6 downto 0);
        i_gtyYdata  => (others => (others => '0')), -- in t_slv_64_arr(4 downto 0);
        i_gtyYValid => "00000", -- in std_logic_vector(4 downto 0);
        i_gtyYSof   => "00000", -- in std_logic_vector(4 downto 0);
        i_gtyYEof   => "00000", -- in std_logic_vector(4 downto 0);
        i_gtyXdata  => (others => (others => '0')), -- in t_slv_64_arr(4 downto 0);
        i_gtyXValid => "00000", -- in std_logic_vector(4 downto 0);
        i_gtyXSof   => "00000", -- in std_logic_vector(4 downto 0);
        i_gtyXEof   => "00000", -- in std_logic_vector(4 downto 0);        
        -- XYZ interconnect outputs
        o_gtyZData  => open,    -- out t_slv_64_arr(6 downto 0);
        o_gtyZValid => open,    -- out std_logic_vector(6 downto 0);
        o_gtyYData  => open,    -- out t_slv_64_arr(4 downto 0);
        o_gtyYValid => open,    -- out std_logic_vector(4 downto 0);
        o_gtyXData  => open,    -- out t_slv_64_arr(4 downto 0);
        o_gtyXValid => open,    -- out std_logic_vector(4 downto 0);
        -- Serial interface to the OCXO
        o_ptp_pll_reset        => ptp_pll_reset, -- out std_logic;                     -- PLL reset
        o_ptp_clk_sel          => ptp_clk_sel,   -- out std_logic;                     -- PTP Interface (156.25MH select when high)
        o_ptp_sync_n           => ptp_sync_n,    -- out std_logic_vector(1 downto 0);  -- bit(0) = active low enable for DAC controlling the clk_e = 25 MHz crystal (which is then upconverted to either 125 or 156.25 MHz), bit(1) = active low enable for DAC controlling the clk_f = 20 MHz crystal.  
        o_ptp_sclk             => ptp_sclk,      -- out std_logic;
        o_ptp_din              => ptp_din,       -- out std_logic;
        -----------------------------------------------------------------------
        -- AXI slave interfaces for modules
        i_MACE_clk  => clk_eth, -- in std_logic;
        i_MACE_rst  => axi_rst, -- in std_logic;
        -- DSP top lite slave
        i_dsptopLite_axi_mosi => mc_lite_mosi(c_dsp_topNoHBM_lite_index), -- in t_axi4_lite_mosi;
        o_dsptopLite_axi_miso => mc_lite_miso(c_dsp_topNoHBM_lite_index), -- out t_axi4_lite_miso;
        -- LFAADecode, lite + full slave
        i_LFAALite_axi_mosi => mc_lite_mosi(c_LFAADecode_lite_index), -- in t_axi4_lite_mosi; 
        o_LFAALite_axi_miso => mc_lite_miso(c_LFAADecode_lite_index), -- out t_axi4_lite_miso;
        i_LFAAFull_axi_mosi => mc_full_mosi(c_lfaadecode_full_index), -- in  t_axi4_full_mosi;
        o_LFAAFull_axi_miso => mc_full_miso(c_lfaadecode_full_index), -- out t_axi4_full_miso;
        -- Capture, lite + full
        i_Cap128Lite_axi_mosi => mc_lite_mosi(c_capture128bit_lite_index), -- in t_axi4_lite_mosi;
        o_Cap128Lite_axi_miso => mc_lite_miso(c_capture128bit_lite_index), -- out t_axi4_lite_miso;
        i_Cap128Full_axi_mosi => mc_full_mosi(c_capture128bit_full_index), -- in  t_axi4_full_mosi;
        o_Cap128Full_axi_miso => mc_full_miso(c_capture128bit_full_index), -- out t_axi4_full_miso;
        -- Timing control
        i_timing_axi_mosi => mc_lite_mosi(c_timingcontrol_lite_index), -- in  t_axi4_lite_mosi;
        o_timing_axi_miso => mc_lite_miso(c_timingcontrol_lite_index), -- out t_axi4_lite_miso;
        -- Interconnect
        i_IC_axi_mosi => mc_lite_mosi(c_interconnect_lite_index), -- in t_axi4_lite_mosi;
        o_IC_axi_miso => mc_lite_miso(c_interconnect_lite_index)  -- out t_axi4_lite_miso;
    );
    
    mac40G <= x"aabbccddeeff";
       
    ---------------------------------------------------------------------------
    -- Debug  --
    ---------------------------------------------------------------------------

    pdebug_tx : ila_0
    port map (
        clk => qsfp_a_tx_clk_out(0),
        probe0(0) => data_tx_siso(41).tready,
        probe0(1) => data_tx_sosi(41).tvalid,
        probe0(2) => data_tx_sosi(41).tlast,
        probe0(66 downto 3) => data_tx_sosi(41).tdata(63 downto 0),
        probe0(74 downto 67) => data_tx_sosi(41).tkeep(7 downto 0), 
        probe0(75) => data_tx_sosi(41).tuser(0),
        probe0(99 downto 76) => gnd(99 DOWNTO 76)
    );

    pdebug_rx : ila_0
    port map (
        clk => qsfp_a_tx_clk_out(0),
        probe0(0) => data_rx_siso(41).tready,
        probe0(1) => data_rx_sosi(41).tvalid,
        probe0(2) => data_rx_sosi(41).tlast,
        probe0(66 downto 3) => data_rx_sosi(41).tdata(63 downto 0),
        probe0(74 downto 67) => data_rx_sosi(41).tkeep(7 downto 0), 
        probe0(75) => data_rx_sosi(41).tuser(0),
        probe0(99 downto 76) => gnd(99 DOWNTO 76)
    );



--   u_axi_ila : entity tech_axi4_infrastructure_lib.tech_axi4_ila
--   GENERIC MAP (
--      g_technology => g_technology)
--   PORT MAP (
--      m_clk       => clk_eth,
--      m_axi_miso  => mc_master_miso,
--      m_axi_mosi  => mc_master_mosi);

   wvalid0 <= mc_lite_mosi(0).awvalid;
   wvalid1 <= mc_lite_mosi(1).awvalid;
   wvalid2 <= mc_lite_mosi(2).awvalid;
   wvalid3 <= mc_lite_mosi(3).awvalid;
   rvalid0 <= mc_lite_mosi(0).arvalid;
   rvalid1 <= mc_lite_mosi(1).arvalid;
   rvalid2 <= mc_lite_mosi(2).arvalid;
   rvalid3 <= mc_lite_mosi(3).arvalid;

--   mace_debug : ila_0
--   PORT MAP (
--      clk                     => clk_eth,
--      probe0(63 DOWNTO 0)     => eth_out_sosi.tdata(63 DOWNTO 0),
--      probe0(127 DOWNTO 64)   => eth_in_sosi.tdata(63 DOWNTO 0),
--      probe0(128)             => eth_out_sosi.tvalid,
--      probe0(129)             => eth_in_sosi.tvalid,
--      probe0(130)             => eth_in_sosi.tlast,
--      probe0(131)             => eth_in_sosi.tuser(0),
--      probe0(139 DOWNTO 132)  => eth_in_sosi.tkeep(7 DOWNTO 0),
--      probe0(140)             => eth_out_sosi.tlast,
--      probe0(148 DOWNTO 141)  => eth_out_sosi.tkeep(7 DOWNTO 0),
--      probe0(149)             => eth_out_siso.tready,
--      probe0(150)             => eth_in_siso.tready,
--      probe0(151)             => wvalid0,
--      probe0(152)             => wvalid1,
--      probe0(153)             => wvalid2,
--      probe0(154)             => wvalid3,
--      probe0(155)             => rvalid0,
--      probe0(156)             => rvalid1,
--      probe0(157)             => rvalid2,
--      probe0(158)             => rvalid3,
--      probe0(199 DOWNTO 159)  => gnd(199 DOWNTO 159));

--   connectdbg : ila_0
--   port map (
--      clk => clk_eth,
----mc_master_mosi.araddr(31 downto 0),
--      probe0(2 downto 0) => mc_master_mosi.arprot(2 downto 0),
--        probe0(3) => mc_master_mosi.arvalid,
--        probe0(35 downto 4) => mc_master_mosi.awaddr(31 downto 0),
--        probe0(38 downto 36) => mc_master_mosi.awprot(2 downto 0),
--        probe0(39) => mc_master_mosi.awvalid,
--        probe0(40) => mc_master_mosi.bready,
--        probe0(41) => mc_master_mosi.rready,
--        probe0(49 downto 42) => mc_master_mosi.wdata(7 downto 0),
--        probe0(53 downto 50) => mc_master_mosi.wstrb(3 downto 0),
--        probe0(54) => mc_master_mosi.wvalid,
--        probe0(56 downto 55) => mc_master_mosi.arburst(1 downto 0),
--        probe0(58 downto 57) => mc_master_mosi.awburst(1 downto 0),
--        probe0(62 downto 59) => mc_master_mosi.arcache(3 downto 0),
--        probe0(66 downto 63) => mc_master_mosi.awcache(3 downto 0),
--        probe0(74 downto 67) => mc_master_mosi.arlen(7 downto 0),
--        probe0(77 downto 75) => mc_master_mosi.arsize(2 downto 0),
--        probe0(80 downto 78) => mc_master_mosi.awsize(2 downto 0),
--        probe0(88 downto 81) => mc_master_mosi.awlen(7 downto 0),
--        probe0(89) => mc_master_mosi.arlock,
--        probe0(90) => mc_master_mosi.awlock,
--        probe0(91) => mc_master_mosi.wlast,
--        probe0(95 downto 92) => mc_master_mosi.awqos(3 downto 0),
--        probe0(99 downto 96) => mc_master_mosi.arqos(3 downto 0),
        
--        probe0(100) => mc_master_miso.awready,
--        probe0(101) => mc_master_miso.wready,
--        probe0(103 downto 102) => mc_master_miso.bresp(1 downto 0),
--        probe0(104) => mc_master_miso.bvalid,
--        probe0(105) => mc_master_miso.arready,
--        --probe0(40) => mc_master_miso.rdata(31 downto 0),
--        probe0(107 downto 106) => mc_master_miso.rresp(1 downto 0),
--        probe0(108) => mc_master_miso.rvalid,
--        probe0(109) => mc_master_miso.rlast,
--        probe0(110)             => wvalid0,
--        probe0(111)             => wvalid1,
--        probe0(112)             => wvalid2,
--        probe0(113)             => wvalid3,
--        probe0(114)             => rvalid0,
--        probe0(115)             => rvalid1,
--        probe0(116)             => rvalid2,
--        probe0(117)             => rvalid3,
--        probe0(118)             => mc_lite_mosi(1).awvalid,
--        probe0(119)             => mc_lite_mosi(1).bready,
--        probe0(120)             => mc_lite_mosi(1).wvalid,
--        probe0(137 downto 121)  => mc_lite_mosi(1).awaddr(16 downto 0),
--        probe0(145 downto 138)  => mc_lite_mosi(1).wdata(7 downto 0),
--        probe0(146)             => mc_lite_mosi(1).arvalid,
--        probe0(163 downto 147)  => mc_lite_mosi(1).araddr(16 downto 0),
--        probe0(164)             => mc_lite_miso(1).bvalid,
--        probe0(165)             => mc_lite_miso(1).wready,
--        probe0(166)             => mc_lite_miso(1).awready,
--        probe0(168 downto 167)  => mc_lite_miso(1).bresp(1 downto 0),
--        probe0(169)             => mc_lite_miso(1).arready,
--        probe0(170)             => mc_lite_miso(1).rvalid,
--        probe0(178 downto 171)  => mc_lite_miso(1).rdata(7 downto 0),
--        probe0(180 downto 179)  => mc_lite_miso(1).rresp(1 downto 0),
--        probe0(181)             => axi_rst,
        
--        probe0(182)  => mc_full_mosi(0).awvalid,
--        probe0(183)  => mc_full_mosi(0).wvalid,
--        probe0(184)  => mc_full_mosi(0).arvalid,
--        probe0(185)  => mc_full_mosi(0).bready,
--        probe0(186)  => mc_full_mosi(0).rready,
--        probe0(187)  => mc_full_miso(0).awready,
--        probe0(188)  => mc_full_miso(0).wready,
--        probe0(189)  => mc_full_miso(0).bvalid,
--        probe0(190)  => mc_full_miso(0).arready,
--        probe0(191)  => mc_full_miso(0).rvalid,
        
--        probe0(192)  => gemini_mm_rst, --
--        probe0(199 downto 193)  => gnd(199 downto 193)
--    );
   

   
--   gemini_debug : ila_0
--   PORT MAP (
--      clk                   => clk_eth,
--      probe0(2 DOWNTO 0)    => req_crsb_state,
--      probe0(3)             => '0',
--      probe0(7 downto 4)    => req_main_state,
--      probe0(11 downto 8)   => replay_state,
--      probe0(15 downto 12)  => completion_state,
--      probe0(19 downto 16)  => rq_state,
--      probe0(23 downto 20)  => rq_stream_state,
--      probe0(27 downto 24)  => resp_state,
--      probe0(28)            => '0',
--      probe0(31 downto 29)  => crqb_fifo_rd_out,
--      probe0(111 downto 32) => crqb_fifo_rd_data_sel_out(79 downto 0),
--      probe0(119 downto 112) => s2mm_in_dbg.tdata(7 downto 0),
--      probe0(120)            => s2mm_in_dbg.tvalid,
--      probe0(136 downto 121) => s2mm_cmd_in_dbg.tdata(17 downto 2),
--      probe0(137)            => s2mm_cmd_in_dbg.tdata(23),
--      probe0(169 downto 138) => s2mm_cmd_in_dbg.tdata(63 downto 32),
--      probe0(170)            => s2mm_cmd_in_dbg.tvalid,
--      probe0(171)            => s2mm_cmd_out_dbg.tready,
      
--      probe0(172)            => s2mm_sts_in_dbg.tready,
--      probe0(180 downto 173) => s2mm_sts_out_dbg.tdata(7 downto 0),
--      probe0(181)            => s2mm_sts_out_dbg.tlast,
--      probe0(182)            => s2mm_sts_out_dbg.tvalid,
--      probe0(198 downto 183) => mc_master_mosi.awaddr(15 downto 0),
--      probe0(199)            => mc_master_mosi.awvalid
--   );

--    connectdbg3 : ila_0
--    port map (
--        clk => clk_eth,
--        probe0(2 downto 0) => req_crsb_state,
--        probe0(6 downto 3) => req_main_state, -- out std_logic_vector(3 downto 0);
--        probe0(10 downto 7) => replay_state,   -- out std_logic_vector(3 downto 0);
--        probe0(14 downto 11) => completion_state, --  out std_logic_vector(3 downto 0);
--        probe0(18 downto 15) => rq_state,        -- out std_logic_vector(3 downto 0);
--        probe0(22 downto 19) => rq_stream_state, -- out std_logic_vector(3 downto 0);
--        probe0(26 downto 23) => resp_state,       -- out std_logic_vector(3 downto 0);
--        probe0(114 downto 27) => crqb_fifo_rd_data_sel_out, --  out std_logic_vector(87 DOWNTO 0);
--        probe0(117 downto 115) => crqb_fifo_rd_out,  -- out std_logic_vector(2 downto 0)   
        
--        probe0(118) => mc_lite_mosi(1).bready,
--        probe0(131 downto 119) => mc_lite_mosi(1).araddr(12 downto 0),
--        probe0(132) => mc_lite_mosi(1).arvalid,
--        probe0(133) => mc_lite_mosi(1).rready,
--        probe0(134) => mc_lite_miso(1).rvalid,
--        probe0(166 downto 135) => mc_lite_miso(1).rdata(31 downto 0),
--        probe0(167) => mc_lite_miso(1).arready,
--        probe0(168) => dbg_timer_expire,
--        probe0(184 downto 169) => dbg_timer,
--        probe0(199 downto 185) => gnd(199 downto 185)
--    );


   
   --mace_debug : ila_0
   --   PORT MAP (
   --      clk                     => clk_eth,
   --      probe0(7 DOWNTO 0)     => eth_out_sosi.tdata(63 DOWNTO 0),
   --      probe0(15 DOWNTO 8)   => eth_in_sosi.tdata(63 DOWNTO 0),
   --      probe0(16)             => eth_out_sosi.tvalid,
   --      probe0(17)             => eth_in_sosi.tvalid,
   --      probe0(18)             => eth_in_sosi.tlast,
   --      probe0(19)             => eth_in_sosi.tuser(0),
   --      --probe0(139 DOWNTO 132)  => eth_in_sosi.tkeep(7 DOWNTO 0),
   --      probe0(20)             => eth_out_sosi.tlast,
   --      --probe0(148 DOWNTO 141)  => eth_out_sosi.tkeep(7 DOWNTO 0),
   --      probe0(21)             => eth_out_siso.tready,
   --      probe0(150)             => eth_in_siso.tready,
   --      probe0(151)             => wvalid0,
   --      probe0(152)             => wvalid1,
   --      probe0(153)             => wvalid2,
   --      probe0(154)             => wvalid3,
   --      probe0(155)             => rvalid0,
   --      probe0(156)             => rvalid1,
   --      probe0(157)             => rvalid2,
   --      probe0(158)             => rvalid3,
   --      probe0(199 DOWNTO 159)  => gnd(199 DOWNTO 159));
   
   
--      probe0(19)             => eth_in_sosi.tuser(0),
--      --probe0(139 DOWNTO 132)  => eth_in_sosi.tkeep(7 DOWNTO 0),
--      probe0(20)             => eth_out_sosi.tlast,
--      --probe0(148 DOWNTO 141)  => eth_out_sosi.tkeep(7 DOWNTO 0),
--      probe0(21)             => eth_out_siso.tready,
--      probe0(150)             => eth_in_siso.tready,
--      probe0(151)             => wvalid0,
--      probe0(152)             => wvalid1,
--      probe0(153)             => wvalid2,
--      probe0(154)             => wvalid3,
--      probe0(155)             => rvalid0,
--      probe0(156)             => rvalid1,
--      probe0(157)             => rvalid2,
--      probe0(158)             => rvalid3,
--      probe0(199 DOWNTO 159)  => gnd(199 DOWNTO 159));


--   mace_debug : ila_0
--   PORT MAP (
--      clk                     => clk_eth,
--      probe0(7 DOWNTO 0)     => eth_out_sosi.tdata(63 DOWNTO 0),
--      probe0(15 DOWNTO 8)   => eth_in_sosi.tdata(63 DOWNTO 0),
--      probe0(16)             => eth_out_sosi.tvalid,
--      probe0(17)             => eth_in_sosi.tvalid,
--      probe0(18)             => eth_in_sosi.tlast,
--      probe0(19)             => eth_in_sosi.tuser(0),
--      --probe0(139 DOWNTO 132)  => eth_in_sosi.tkeep(7 DOWNTO 0),
--      probe0(20)             => eth_out_sosi.tlast,
--      --probe0(148 DOWNTO 141)  => eth_out_sosi.tkeep(7 DOWNTO 0),
--      probe0(21)             => eth_out_siso.tready,
--      probe0(150)             => eth_in_siso.tready,
--      probe0(151)             => wvalid0,
--      probe0(152)             => wvalid1,
--      probe0(153)             => wvalid2,
--      probe0(154)             => wvalid3,
--      probe0(155)             => rvalid0,
--      probe0(156)             => rvalid1,
--      probe0(157)             => rvalid2,
--      probe0(158)             => rvalid3,
--      probe0(199 DOWNTO 159)  => gnd(199 DOWNTO 159));


-- data_rx_sosi     : in t_axi4_sosi;   -- 128 bit wide data in, only fields that are used are .tdata, .tvalid, .tuser
   seg0_ena <= data_rx_sosi(36).tuser(56);
   seg0_sop <= data_rx_sosi(36).tuser(57);  -- start of packet
   seg0_eop <= data_rx_sosi(36).tuser(58);  -- end of packet
   seg0_mty <= data_rx_sosi(36).tuser(61 DOWNTO 59); -- number of unused bytes in segment 0, only used when eop0 = '1', ena0 = '1', tvalid = '1'. 
   seg0_err <= data_rx_sosi(36).tuser(62);  -- error reported by 40GE MAC (e.g. FCS, bad 64/66 bit block, bad packet length), only valid on eop0, ena0 and tvalid all = '1'
---- segment 1 relates to data_rx_sosi.tdata(127:64)
   seg1_ena <= data_rx_sosi(36).tuser(63);
   seg1_sop <= data_rx_sosi(36).tuser(64);
   seg1_eop <= data_rx_sosi(36).tuser(65);
   seg1_mty <= data_rx_sosi(36).tuser(68 DOWNTO 66);
   seg1_err <= data_rx_sosi(36).tuser(69);
   
   LFAA_tx_fsm <= LFAADecode_dbg(3 downto 0);
   LFAA_stats_fsm <= LFAADecode_dbg(7 downto 4);
   LFAA_rx_fsm <= LFAADecode_dbg(11 downto 8);
   goodpacket <= LFAADecode_dbg(12);
   nonSPEAD   <= LFAADecode_dbg(13);
   
--   top_debug : ila_0
--   PORT MAP (
--      clk                     => qsfp_d_tx_clk_out,
--      probe0(127 DOWNTO 0)    => data_rx_sosi(36).tdata(127 downto 0),
--      probe0(128)             => data_rx_sosi(36).tvalid,
--      probe0(129)             => seg0_ena,
--      probe0(130)             => seg0_sop,
--      probe0(131)             => seg0_eop,
--      probe0(134 DOWNTO 132)  => seg0_mty,
--      probe0(135)             => seg0_err,
--      probe0(136)             => seg1_ena,
--      probe0(137)             => seg1_sop,
--      probe0(138)             => seg1_eop,
--      probe0(141 downto 139)  => seg1_mty,
--      probe0(142)             => seg1_err,
--      probe0(146 downto 143)  => LFAA_rx_fsm,
--      probe0(150 downto 147)  => LFAA_stats_fsm,
--      probe0(154 downto 151)  => LFAA_tx_fsm,
--      probe0(155)             => goodPacket,
--      probe0(156)             => nonSPEAD,
--      probe0(199 DOWNTO 157)  => gnd(199 DOWNTO 157));

--   top_debug : ila_big1
--   PORT MAP (
--      clk                   => qsfp_d_tx_clk_out,
--      probe0(7 DOWNTO 0)    => data_rx_sosi(36).tdata(7 downto 0),
--      probe0(8)             => data_rx_sosi(36).tvalid,
--      probe0(9)             => seg0_ena,
--      probe0(10)            => seg0_sop,
--      probe0(11)            => seg0_eop,
--      probe0(14 DOWNTO 12)  => seg0_mty,
--      probe0(15)            => seg0_err,
--      probe0(16)            => seg1_ena,
--      probe0(17)            => seg1_sop,
--      probe0(18)            => seg1_eop,
--      probe0(21 downto 19)  => seg1_mty,
--      probe0(22)            => seg1_err,
--      probe0(26 downto 23)  => LFAA_rx_fsm,
--      probe0(30 downto 27)  => LFAA_stats_fsm,
--      probe0(34 downto 31)  => LFAA_tx_fsm,
--      probe0(35)            => goodPacket,
--      probe0(36)            => nonSPEAD
--   );


--   ddr4_reg : ila_0
--   PORT MAP (
--      clk                     => clk_eth,
--      probe0(31 DOWNTO 0)     => mc_lite_mosi(c_ddr4_ddr4_lite_index).awaddr,
--      probe0(63 DOWNTO 32)    => mc_lite_mosi(c_ddr4_ddr4_lite_index).araddr,
--      probe0(64)              => mc_lite_mosi(c_ddr4_ddr4_lite_index).awvalid,
--      probe0(96 DOWNTO 65)    => mc_lite_mosi(c_ddr4_ddr4_lite_index).wdata,
--      probe0(97)              => mc_lite_mosi(c_ddr4_ddr4_lite_index).wvalid,
--      probe0(98)              => mc_lite_mosi(c_ddr4_ddr4_lite_index).bready,
--      probe0(99)              => mc_lite_mosi(c_ddr4_ddr4_lite_index).arvalid,
--      probe0(100)             => mc_lite_mosi(c_ddr4_ddr4_lite_index).rready,
--      probe0(104 DOWNTO 101)  => mc_lite_mosi(c_ddr4_ddr4_lite_index).wstrb,
--      probe0(105)             => mc_lite_miso(c_ddr4_ddr4_lite_index).awready,
--      probe0(106)             => mc_lite_miso(c_ddr4_ddr4_lite_index).wready,
--      probe0(107)             => mc_lite_miso(c_ddr4_ddr4_lite_index).bvalid,
--      probe0(108)             => mc_lite_miso(c_ddr4_ddr4_lite_index).rvalid,
--      probe0(109)             => mc_lite_miso(c_ddr4_ddr4_lite_index).arready,
--      probe0(141 DOWNTO 110)  => mc_lite_miso(c_ddr4_ddr4_lite_index).rdata,
--      probe0(143 DOWNTO 142)  => mc_lite_miso(c_ddr4_ddr4_lite_index).rresp,
--      probe0(145 DOWNTO 144)  => mc_lite_miso(c_ddr4_ddr4_lite_index).bresp,
--      probe0(199 DOWNTO 146)  => gnd(199 DOWNTO 146));


--   eth25g_debug : ila_0
--   PORT MAP (
--      clk                     => qsfp_b_tx_clk_out(0),
--      probe0(2 DOWNTO 0)     => qsfp_b_loopback,
--      probe0(3)    => qsfp_b_tx_disable(0),
--      probe0(4)   => qsfp_b_rx_disable(0),
--      probe0(5)  => qsfp_b_rx_locked(0),
--      probe0(6)  => traffic_user_rx_reset(37),
--      probe0(7)  => traffic_user_tx_reset(37),
--      probe0(8)  => data_tx_sosi(37).tvalid,
--      probe0(9)  => data_tx_sosi(37).tlast,
--      probe0(10)  => data_tx_sosi(37).tvalid,
--      probe0(11)  => data_tx_sosi(37).tlast,
--      probe0(12)  => data_tx_siso(37).tready,
--      probe0(13)  => data_tx_siso(37).tready,
--      probe0(77 DOWNTO 14)  => data_tx_sosi(37).tdata(63 DOWNTO 0),
--      probe0(141 DOWNTO 78)  => data_rx_sosi(37).tdata(63 DOWNTO 0),
--      probe0(199 DOWNTO 142)  => gnd(57 DOWNTO 0));


--   eth100g_debug : ila_0
--   PORT MAP (
--      clk                     => qsfp_c_tx_clk_out,
--      probe0(0)               => ctraffic_user_tx_reset,
--      probe0(1)               => ctraffic_user_rx_reset,
--      probe0(2)               => cdata_tx_siso.ready,
--      probe0(6 downto 3)      => cdata_tx_sosi.valid,
--      probe0(10 downto 7)     => cdata_tx_sosi.eop,
--      probe0(14 downto 11)    => cdata_tx_sosi.error,
--      probe0(18 downto 15)    => cdata_tx_sosi.empty(0),
--      probe0(19)              => cdata_tx_siso.overflow,
--      probe0(20)              => cdata_tx_siso.underflow,
--      probe0(21)              => ctraffic_rx_aligned,
--      probe0(22)              => ctraffic_aligned,
--      probe0(199 downto 23)   => cdata_tx_sosi.data(176 downto 0));

--   eth40g_debug : ila_0
--   PORT MAP (
--      clk                     => traffic_gen_clk(36),
--      probe0(13 DOWNTO 0)     => data_tx_sosi(36).tuser(69 DOWNTO 56),
--      probe0(141 DOWNTO 14)   => data_tx_sosi(36).tdata(127 DOWNTO 0),
--      probe0(142)             => data_tx_sosi(36).tvalid,
--      probe0(143)             => traffic_user_rx_reset(36),
--      probe0(147 downto 144)  => qmac_rx_locked,
--      probe0(151 downto 148)  => qmac_rx_synced,
--      probe0(152)             => qmac_rx_aligned,
--      probe0(153)             => qmac_rx_status,
--      probe0(154)             => traffic_user_tx_reset(36),
--      probe0(159 downto 155)  => completion_status(36),
--      probe0(160)             => '0',
--      probe0(161)             => qsfp_d_tx_disable(0),
--      probe0(162)             => qsfp_d_rx_disable(0),
--      probe0(163)             => qsfp_d_rx_locked(0),
--      probe0(199 DOWNTO 164)  => gnd(35 DOWNTO 0));


END structure;
