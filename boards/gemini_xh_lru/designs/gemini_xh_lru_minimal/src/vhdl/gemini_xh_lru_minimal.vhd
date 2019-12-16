-------------------------------------------------------------------------------
--
-- File Name: gemini_xh_lru_minimal.vhd
-- Contributing Authors: Andrew Brown, Leon Hiemstra, Daniel van der Schuur
-- Type: RTL
-- Created: Thurs June 7 14:30:00 2017
-- Template Rev: 1.0
--
-- Title: Top Level of Gemini XH LRU minimal project
--
-- Description: Minimal system with MACE
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

LIBRARY IEEE, common_lib, axi4_lib, technology_lib, util_lib;
LIBRARY gemini_xh_lru_board_lib, spi_lib, onewire_lib, eth_lib, arp_lib, dhcp_lib, gemini_server_lib, gemini_subscription_lib, ping_protocol_lib;
LIBRARY tech_axi4_quadspi_prom_lib, tech_system_monitor_lib, tech_axi4_infrastructure_lib, tech_iobuf_lib;
LIBRARY tech_fpga_features_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE axi4_lib.axi4_full_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE gemini_xh_lru_board_lib.ip_pkg.ALL;
USE gemini_xh_lru_board_lib.board_pkg.ALL;
USE work.gemini_xh_lru_minimal_bus_pkg.ALL;
USE work.gemini_xh_lru_minimal_system_reg_pkg.ALL;
USE work.ip_pkg.ALL;

ENTITY gemini_xh_lru_minimal IS
   GENERIC (
      g_technology         : t_technology := c_tech_gemini_xh;
      g_heater             : BOOLEAN := FALSE;
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
--      clk_e_p              : in std_logic;                           -- 125MHz PTP clk
--      clk_e_n              : in std_logic;
--      clk_f                : in std_logic;                           -- 20MHz PTP clk
      clk_g_p              : IN STD_LOGIC;                           -- 266.67 Memory reference clock
      clk_g_n              : IN STD_LOGIC;
      clk_h_p              : IN STD_LOGIC;                           -- 200MHz LO clk
      clk_h_n              : IN STD_LOGIC;
--      clk_bp_p             : in std_logic;
--      clk_bp_n             : in std_logic;

      -- SFP
      sfp_sda              : INOUT STD_LOGIC;
      sfp_scl              : INOUT STD_LOGIC;
      sfp_fault            : IN STD_LOGIC;
      sfp_tx_enable        : OUT STD_LOGIC;
      sfp_mod_abs          : IN STD_LOGIC;
      sfp_led              : OUT STD_LOGIC;

      sfp_clk_c_p          : IN STD_LOGIC;                           -- 156.25MHz reference
      sfp_clk_c_n          : IN STD_LOGIC;
--      sfp_clk_e_p          : in std_logic;                           -- 125/156.25MHz reference (PTP)
--      sfp_clk_e_n          : in std_logic;
      sfp_tx_p             : OUT STD_LOGIC;
      sfp_tx_n             : OUT STD_LOGIC;
      sfp_rx_p             : IN STD_LOGIC;
      sfp_rx_n             : IN STD_LOGIC;

      -- Backplane Connector I/O
      bp_id                : INOUT STD_LOGIC;                           -- 1-wire interface to the EEPROM on the backplane
      bp_id_pullup         : OUT STD_LOGIC;                             -- Strong pullup enable

      bp_power_scl         : INOUT STD_LOGIC;                           -- Power control clock
      bp_power_sda         : INOUT STD_LOGIC;                           -- Power control data

--      bp_aux_io_p          : inout std_logic_vector(1 DOWNTO 0);
--      bp_aux_io_n          : inout std_logic_vector(1 DOWNTO 0);

      -- Power Interface
      power_sda            : INOUT STD_LOGIC;
      power_sdc            : INOUT STD_LOGIC;
      power_alert_n        : IN STD_LOGIC;

      shutdown             : OUT STD_LOGIC;                          -- Assert to latch power off

      -- PTP
--      ptp_pll_reset        : out std_logic;                          -- PLL reset
      ptp_clk_sel          : OUT STD_LOGIC;                          -- PTP Interface (156.25MH select when high)
--      ptp_sync_n           : out std_logic_vector(1 DOWNTO 0);
--      ptp_sclk             : out std_logic;
--      ptp_din              : out std_logic;

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
END gemini_xh_lru_minimal;

-------------------------------------------------------------------------------
ARCHITECTURE structure OF gemini_xh_lru_minimal IS

   ---------------------------------------------------------------------------
   -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
   ---------------------------------------------------------------------------

   CONSTANT c_num_eth_lanes      : INTEGER := 6;
   CONSTANT c_default_ip         : STD_LOGIC_VECTOR(31 DOWNTO 0) := X"0a2000FE"; -- 10.32.0.254
   CONSTANT c_default_mac        : STD_LOGIC_VECTOR(47 DOWNTO 0) := x"C02B3C4D5E7F";
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

   SIGNAL clk_125                            : STD_LOGIC;
   SIGNAL clk_100                            : STD_LOGIC;
   SIGNAL clk_400                            : STD_LOGIC;
   SIGNAL clk_50                             : STD_LOGIC;
   SIGNAL clk_eth                            : STD_LOGIC;      -- RX TX reference clock
   SIGNAL clk_h                              : STD_LOGIC;

   SIGNAL system_reset_shift                 : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '1');
   SIGNAL system_reset                       : STD_LOGIC;
   SIGNAL system_locked                      : STD_LOGIC;
   SIGNAL end_of_startup                     : STD_LOGIC;

   SIGNAL ddr_ip_reset                       : STD_LOGIC;
   SIGNAL ddr_ip_reset_r                     : STD_LOGIC;

   SIGNAL boot_mode_start                    : STD_LOGIC;
   SIGNAL boot_mode_done                     : STD_LOGIC;
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
   SIGNAL qmac_aligned                       : STD_LOGIC;


   SIGNAL ctraffic_user_rx_reset             : STD_LOGIC;
   SIGNAL ctraffic_user_tx_reset             : STD_LOGIC;
   SIGNAL ctraffic_rx_aligned                : STD_LOGIC;
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

   SIGNAL heater_en                          : STD_LOGIC_VECTOR(c_nof_mac4-1 DOWNTO 0);
   SIGNAL heater_sum                         : STD_LOGIC_VECTOR(c_nof_mac4-1 DOWNTO 0);

   SIGNAL gnd                                : STD_LOGIC_VECTOR(255 DOWNTO 0);
   ---------------------------------------------------------------------------
   -- COMPONENT DECLARATIONS  --
   ---------------------------------------------------------------------------


BEGIN

    gnd <= (OTHERS  => '0');

  ---------------------------------------------------------------------------
  -- CLOCKING & RESETS  --
  ---------------------------------------------------------------------------

   clk_h_buf: ENTITY tech_iobuf_lib.tech_iobuf_diff_in
   GENERIC MAP (
      g_technology   => g_technology,
      g_width        => 1)
   PORT MAP (
      i(0) => clk_h_p,
      ib(0) => clk_h_n,
      o(0) => clk_h);

   system_pll: system_clock
   PORT MAP (
      clk_in1  => clk_h,
      clk_400  => clk_400,
      clk_125  => clk_125,
      clk_100  => clk_100,
      clk_50   => clk_50,
      resetn   => end_of_startup,
      locked   => system_locked);

   system_pll_reset: PROCESS(clk_100)
   BEGIN
      IF RISING_EDGE(clk_100) THEN
         system_reset_shift <= system_reset_shift(6 DOWNTO 0) & NOT(system_locked);
      END IF;
   END PROCESS;

   system_reset <= system_reset_shift(7);

  ---------------------------------------------------------------------------
  -- Ethernet MAC & Framework  --
  ---------------------------------------------------------------------------

   u_mace_mac: ENTITY gemini_xh_lru_board_lib.mace_mac
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
      stat_rx_pause_req    => stat_rx_pause_req);


   axi_rst <= eth_tx_reset;

   sfp_support: ENTITY gemini_xh_lru_board_lib.sfp_control
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
      sfp_mod_abs    => sfp_mod_abs);


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
      rst               => axi_rst,
      mymac_addr        => local_mac,
      eth_in_sosi       => eth_in_sosi,
      eth_out_sosi      => decoder_out_sosi,
      eth_out_siso      => decoder_out_siso);

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
      axi_rst              => axi_rst,
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
      g_min_recycle_secs   => 0)                      -- Need to timeout connections straight away
   PORT MAP (
      clk                  => clk_eth,
      rst                  => axi_rst,
      ethrx_in             => decoder_out_sosi(0),
      ethrx_out            => decoder_out_siso(0),
      ethtx_in             => encoder_in_siso(0),
      ethtx_out            => encoder_in_sosi(0),
      mm_in                => mc_master_miso,
      mm_out               => mc_master_mosi,
      tod_in               => system_fields_ro.time_uptime);

   decoder_out_siso(1).tready <= '1';

   dhcp_start <= eth_locked AND prom_startup_complete;

   u_dhcp_protocol: ENTITY dhcp_lib.dhcp_protocol
   GENERIC MAP (
      g_technology         => g_technology)
   PORT MAP (
      axi_clk              => clk_eth,
      axi_rst              => axi_rst,
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
      frame_out_siso       => encoder_in_siso(2));

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
      eth_out_siso   => encoder_in_siso(4));

   u_pubsub_protocol: ENTITY gemini_subscription_lib.subscription_protocol
   GENERIC MAP (
      g_technology      => g_technology,
      g_num_clients     => 3)
   PORT MAP (
      axi_clk           => clk_eth,
      axi_rst           => axi_rst,
      time_in           => local_time,
      event_in          => event_in,
      s_axi_mosi        => mc_lite_mosi(c_gemini_subscription_lite_index),
      s_axi_miso        => mc_lite_miso(c_gemini_subscription_lite_index),
      stream_out_sosi   => encoder_in_sosi(5),
      stream_out_siso   => encoder_in_siso(5));

   decoder_out_siso(5).tready <= '1';


  ---------------------------------------------------------------------------
  -- Bus Interconnect  --
  ---------------------------------------------------------------------------

   u_interconnect: ENTITY work.gemini_xh_lru_minimal_bus_top
   PORT MAP (
      CLK            => clk_eth,
      RST            => axi_rst,
      SLA_IN         => mc_master_mosi,
      SLA_OUT        => mc_master_miso,
      MSTR_IN_LITE   => mc_lite_miso,
      MSTR_OUT_LITE  => mc_lite_mosi,
      MSTR_IN_FULL   => mc_full_miso,
      MSTR_OUT_FULL  => mc_full_mosi);


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

   pmbus_support: ENTITY gemini_xh_lru_board_lib.pmbus_control
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

   onewire_prom: ENTITY gemini_xh_lru_board_lib.prom_interface
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

   humidity_support: ENTITY gemini_xh_lru_board_lib.humidity_control
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
      spi_i          => gnd(3 DOWNTO 0),
      spi_o          => OPEN,
      spi_t          => OPEN,
      spi_ss_i       => '0',
      spi_ss_o       => OPEN,
      spi_ss_t       => OPEN,
      end_of_startup => end_of_startup);

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

   backplane_prom: ENTITY gemini_xh_lru_board_lib.prom_interface
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

   bp_power_control: ENTITY gemini_xh_lru_board_lib.backplane_control
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

   fpga_regs: ENTITY work.gemini_xh_lru_minimal_system_reg
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
   build_reg: ENTITY tech_fpga_features_lib.tech_user_reg
   PORT MAP (
      data       => system_fields_ro.build_date);

   -- Uptime counter
   uptime_cnt: ENTITY gemini_xh_lru_board_lib.uptime_counter
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

   shutdown_timer_edge: ENTITY common_lib.common_evt
   GENERIC MAP(
      g_evt_type  => "FALLING",
      g_out_reg   => TRUE)
   PORT MAP (
      clk         => clk_eth,
      in_sig      => shutdown_extended,
      out_evt     => shutdown);


   ptp_clk_sel <= '1';

  ---------------------------------------------------------------------------
  -- Debug  --
  ---------------------------------------------------------------------------

   u_axi_ila : entity tech_axi4_infrastructure_lib.tech_axi4_ila
   GENERIC MAP (
      g_technology => g_technology)
   PORT MAP (
      m_clk       => clk_eth,
      m_axi_miso  => mc_master_miso,
      m_axi_mosi  => mc_master_mosi);


   mace_debug : ila_0
   PORT MAP (
      clk                     => clk_eth,
      probe0(63 DOWNTO 0)     => eth_out_sosi.tdata(63 DOWNTO 0),
      probe0(127 DOWNTO 64)   => eth_in_sosi.tdata(63 DOWNTO 0),
      probe0(128)             => eth_out_sosi.tvalid,
      probe0(129)             => eth_in_sosi.tvalid,
      probe0(130)             => eth_in_sosi.tlast,
      probe0(131)             => eth_in_sosi.tuser(0),
      probe0(139 DOWNTO 132)  => eth_in_sosi.tkeep(7 DOWNTO 0),
      probe0(140)             => eth_out_sosi.tlast,
      probe0(148 DOWNTO 141)  => eth_out_sosi.tkeep(7 DOWNTO 0),
      probe0(149)             => eth_out_siso.tready,
      probe0(150)             => eth_in_siso.tready,
      probe0(199 DOWNTO 151)  => gnd(199 DOWNTO 151));


   top_debug : ila_0
   PORT MAP (
      clk                     => clk_eth,
      probe0(44 DOWNTO 0)     => gnd(44 downto 0), --traffic_rx_lock(0 TO 44),
      probe0(76 DOWNTO 45)    => local_prom_ip,
      probe0(124 DOWNTO 77)   => local_mac,
      probe0(156 DOWNTO 125)  => serial_number,
      probe0(157)             => dhcp_start,
      probe0(189 DOWNTO 158)  => local_ip,
      probe0(190)             => qmac_aligned,
      probe0(195 DOWNTO 191)  => gnd(195 downto 191), --completion_status(36),
      probe0(196)             => gnd(196), --ctraffic_rx_aligned,
      probe0(197)             => eth_locked,
      probe0(199 DOWNTO 198)  => gnd(199 DOWNTO 198));




END structure;
