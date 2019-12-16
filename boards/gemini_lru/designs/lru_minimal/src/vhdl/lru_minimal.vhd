-------------------------------------------------------------------------------
--
-- File Name: lru_minimal.vhd
-- Contributing Authors: Andrew Brown, Leon Hiemstra
-- Type: RTL
-- Created: Thurs Oct 19 16:40:00 2017
-- Template Rev: 1.0
--
-- Title: Top Level of Gemini LRU minimal project
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

LIBRARY IEEE, UNISIM, common_lib, axi4_lib, gemini_lru_board_lib, technology_lib, spi_lib, onewire_lib, tech_mac_10g_lib;
LIBRARY eth_lib, arp_lib, dhcp_lib, gemini_server_lib, gemini_subscription_lib, ping_protocol_lib;
LIBRARY tech_axi4_quadspi_prom_lib, tech_system_monitor_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE axi4_lib.axi4_full_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE gemini_lru_board_lib.board_pkg.ALL;
USE gemini_lru_board_lib.ip_pkg.ALL;
USE work.lru_minimal_bus_pkg.ALL;
USE work.lru_minimal_system_reg_pkg.ALL;
USE UNISIM.vcomponents.all;



-------------------------------------------------------------------------------
ENTITY lru_minimal IS
   GENERIC (
      g_technology         : t_technology := c_tech_gemini;
      g_sim                : BOOLEAN := FALSE);
   PORT (
      -- Global clks
--      clk_aux_b_p          : in std_logic;                           -- Differential clock input
--      clk_aux_b_n          : in std_logic;
--      clk_aux_c            : inout std_logic;                        -- Multi-purpose IO to MMBX
      clk_c_p              : IN std_logic_vector(4 DOWNTO 0);        -- Shared 156.25MHz clock (QSFP & MBO)
      clk_c_n              : IN std_logic_vector(4 DOWNTO 0);
--      clk_d_p              : in std_logic_vector(2 downto 0);        -- variable clock inputs to enable MBO operation at ADC-speed (Shared between MBO connections, see schematic, clk_d)
--      clk_d_n              : in std_logic_vector(2 downto 0);
--      clk_e_p              : in std_logic;                           -- 125MHz PTP clk
--      clk_e_n              : in std_logic;
--      clk_f                : in std_logic;                           -- 20MHz PTP clk
      clk_g_p              : IN STD_LOGIC;                           -- 266.67 Memory reference clock
      clk_g_n              : IN STD_LOGIC;
      clk_h                : IN STD_LOGIC;                            -- 20MHz LO clk
--      clk_bp_p             : in std_logic;                           -- Clock connection from the backplane connector
--      clk_bp_n             : in std_logic;

      -- SFP
      sfp_sda              : INOUT STD_LOGIC;
      sfp_scl              : INOUT STD_LOGIC;
      sfp_fault            : IN STD_LOGIC;
      sfp_tx_enable        : OUT STD_LOGIC;
      sfp_mod_abs          : IN STD_LOGIC;
      sfp_led              : out std_logic;

      qsfp_a_led           : out std_logic;
      qsfp_b_led           : out std_logic;
      qsfp_c_led           : out std_logic;
      qsfp_d_led           : out std_logic;

      sfp_clk_c_p          : IN STD_LOGIC;                           -- 156.25MHz reference
      sfp_clk_c_n          : IN STD_LOGIC;
--      sfp_clk_e_p          : in std_logic;                           -- 125MHz reference (PTP)
--      sfp_clk_e_n          : in std_logic;
      sfp_tx_p             : OUT STD_LOGIC;
      sfp_tx_n             : OUT STD_LOGIC;
      sfp_rx_p             : IN STD_LOGIC;
      sfp_rx_n             : IN STD_LOGIC;

      -- Backplane Connector I/O
      bp_id                : inout std_logic;                        -- 1-wire interface to the EEPROM on the backplane
      bp_id_pullup         : out std_logic;                          -- Strong pullup enable

--      bp_power_scl         : out std_logic;                          -- Power control clock
--      bp_power_sda         : inout std_logic;                        -- Power control data
--
--      bp_aux_io_p          : inout std_logic_vector(1 downto 0);
--      bp_aux_io_n          : inout std_logic_vector(1 downto 0);
--
      -- Power Interface
      power_sda            : INOUT STD_LOGIC;
      power_sdc            : INOUT STD_LOGIC;
      power_alert_n        : IN STD_LOGIC;

      shutdown             : OUT STD_LOGIC;                          -- Assert to latch power off

      -- Configuration IO
      spi_d                : inout std_logic_vector(7 downto 4);    -- Other IO through startup block
      spi_cs               : inout std_logic_vector(1 downto 1);    -- Other IO through startup block

--      -- PTP
--      ptp_pll_reset        : out std_logic;                          -- PLL reset
      ptp_clk_sel          : out std_logic;                          -- PTP Interface
--      ptp_sync_n           : out std_logic_vector(1 downto 0);
--      ptp_sclk             : out std_logic;
--      ptp_din              : out std_logic;

      -- Misc IO
      led_din              : OUT STD_LOGIC;                          -- SPI Led Interface
      led_dout             : IN STD_LOGIC;
      led_cs               : OUT STD_LOGIC;
      led_sclk             : OUT STD_LOGIC;

      serial_id            : INOUT STD_LOGIC;                        -- Onboard serial number PROM & MAC ID
      serial_id_pullup     : INOUT STD_LOGIC;

      hum_sda              : INOUT STD_LOGIC;                        -- Humidity & temperature chip
      hum_sdc              : INOUT STD_LOGIC;

      debug                : INOUT STD_LOGIC_VECTOR(3 DOWNTO 0);     -- General debug IOs
      version              : IN STD_LOGIC_VECTOR(1 DOWNTO 0));
END lru_minimal;

-------------------------------------------------------------------------------
ARCHITECTURE structure OF lru_minimal IS

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


   ---------------------------------------------------------------------------
   -- SIGNAL DECLARATIONS  --
   ---------------------------------------------------------------------------

   SIGNAL clk_125                : STD_LOGIC;
   SIGNAL clk_100                : STD_LOGIC;
   SIGNAL clk_eth                : STD_LOGIC;

   SIGNAL system_reset_shift     : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '1');
   SIGNAL system_reset           : STD_LOGIC;
   SIGNAL system_locked          : STD_LOGIC;
   SIGNAL end_of_startup         : STD_LOGIC;

   SIGNAL local_mac              : STD_LOGIC_VECTOR(47 DOWNTO 0);
   SIGNAL local_ip               : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL prom_ip                : STD_LOGIC_VECTOR(31 DOWNTO 0);

   SIGNAL eth_in_siso            : t_axi4_siso;
   SIGNAL eth_in_sosi            : t_axi4_sosi;
   SIGNAL eth_out_sosi           : t_axi4_sosi;
   SIGNAL eth_out_siso           : t_axi4_siso;
   SIGNAL eth_rx_reset           : STD_LOGIC;
   SIGNAL eth_tx_reset           : STD_LOGIC;
   SIGNAL ctl_rx_pause_ack       : STD_LOGIC_VECTOR(8 DOWNTO 0);
   SIGNAL ctl_rx_pause_enable    : STD_LOGIC_VECTOR(8 DOWNTO 0);
   SIGNAL stat_rx_pause_req      : STD_LOGIC_VECTOR(8 DOWNTO 0);
   SIGNAL eth_locked             : STD_LOGIC;
   SIGNAL axi_rst                : STD_LOGIC;

   SIGNAL decoder_out_sosi       : t_axi4_sosi_arr(0 TO c_num_eth_lanes-1);
   SIGNAL decoder_out_siso       : t_axi4_siso_arr(0 TO c_num_eth_lanes-1);
   SIGNAL encoder_in_sosi        : t_axi4_sosi_arr(0 TO c_num_eth_lanes-1);
   SIGNAL encoder_in_siso        : t_axi4_siso_arr(0 TO c_num_eth_lanes-1);

   SIGNAL mc_master_mosi         : t_axi4_full_mosi;
   SIGNAL mc_master_miso         : t_axi4_full_miso;
   SIGNAL mc_lite_miso           : t_axi4_lite_miso_arr(c_nof_lite_slaves-1 DOWNTO 0);
   SIGNAL mc_lite_mosi           : t_axi4_lite_mosi_arr(c_nof_lite_slaves-1 DOWNTO 0);
   SIGNAL mc_full_miso           : t_axi4_full_miso_arr(c_nof_full_slaves-1 downto 0);
   SIGNAL mc_full_mosi           : t_axi4_full_mosi_arr(c_nof_full_slaves-1 downto 0);

   SIGNAL prom_startup_complete  : STD_LOGIC;
   SIGNAL local_prom_ip          : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL serial_number          : STD_LOGIC_VECTOR(31 DOWNTO 0);

   SIGNAL led1_colour            : STD_LOGIC_VECTOR(23 DOWNTO 0);
   SIGNAL led2_colour            : STD_LOGIC_VECTOR(23 DOWNTO 0);
   SIGNAL led3_colour            : STD_LOGIC_VECTOR(23 DOWNTO 0);

   SIGNAL local_time             : STD_LOGIC_VECTOR(63 DOWNTO 0);
   SIGNAL event_in               : STD_LOGIC_VECTOR(31 DOWNTO 0);

   SIGNAL backplane_ip_valid                 : STD_LOGIC;
   SIGNAL backplane_ip                       : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL bp_prom_startup_complete           : STD_LOGIC;
   SIGNAL bp_serial_number                   : STD_LOGIC_VECTOR(31 DOWNTO 0);

   SIGNAL dhcp_start                         : STD_LOGIC;
   SIGNAL accepted_dhcp_server_out                         : STD_LOGIC;

   SIGNAL system_fields_rw                   : t_system_rw;
   SIGNAL system_fields_ro                   : t_system_ro;

   SIGNAL shutdown_extended                  : STD_LOGIC;
   SIGNAL shutdown_edge                      : STD_LOGIC;

   SIGNAL pps                                : STD_LOGIC;
   SIGNAL pps_extended                       : STD_LOGIC;
   SIGNAL eth_act_extended                   : STD_LOGIC;

   SIGNAL prom_spi_i             : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL prom_spi_o             : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL prom_spi_t             : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL prom_spi_ss_o          : STD_LOGIC;
   SIGNAL prom_spi_ss_t          : STD_LOGIC;

   ---------------------------------------------------------------------------
   -- COMPONENT DECLARATIONS  --
   ---------------------------------------------------------------------------
COMPONENT ila_0
      PORT (
         clk : IN STD_LOGIC;
         probe0 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
         probe1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
         probe2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
         probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
         probe4 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
         probe5 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
         probe6 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
         probe7 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
         probe8 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
         probe9 : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
         probe10 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
         probe11 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
         probe12 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
         probe13 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
         probe14 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
         probe15 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
         probe16 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
         probe17 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
         probe18 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
         probe19 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
         );
      END COMPONENT;

BEGIN


  ---------------------------------------------------------------------------
  -- CLOCKING & RESETS  --
  ---------------------------------------------------------------------------

system_pll: system_clock
            PORT MAP (clk_in1    => clk_h,
                      clk_125    => clk_125,
                      clk_100  => clk_100,
                      resetn   => end_of_startup,
                      locked     => system_locked);

system_pll_reset: PROCESS(clk_125)
   BEGIN
      IF RISING_EDGE(clk_125) THEN
         system_reset_shift <=  system_reset_shift(6 DOWNTO 0) & NOT(system_locked);
      END IF;
   END PROCESS;

   system_reset <= system_reset_shift(7);

   ptp_clk_sel <= '1';

--   gen_decoder_out_siso_tready: FOR i IN 0 TO c_num_eth_lanes-1 GENERATE
--       decoder_out_siso(i).tready <= '1';
--   END GENERATE;
   decoder_out_siso(1).tready <= '1';
--   decoder_out_siso(2).tready <= '1';
 --  decoder_out_siso(4).tready <= '1';
   decoder_out_siso(5).tready <= '1';

   --led1_colour <= X"00FF00" WHEN lane_ok = (lane_ok'RANGE => '1') ELSE X"FF0000";
   --led2_colour(7 DOWNTO 0) <= X"FF" WHEN ctraffic_done = '1' ELSE X"00";
   --led2_colour(15 DOWNTO 8) <= X"FF" WHEN ctraffic_aligned = '1' ELSE X"00";
   --led2_colour(23 DOWNTO 16) <= X"FF" WHEN ctraffic_failed = '1' ELSE X"00";

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
      s_axi_mosi           => mc_lite_mosi(c_ethernet_mace_statistics_lite_index),
      s_axi_miso           => mc_lite_miso(c_ethernet_mace_statistics_lite_index),
      ctl_rx_pause_ack     => ctl_rx_pause_ack,
      ctl_rx_pause_enable  => ctl_rx_pause_enable,
      stat_rx_pause_req    => stat_rx_pause_req);

   axi_rst <= eth_rx_reset;
   sfp_led <= eth_locked;

u_eth_rx: ENTITY eth_lib.eth_rx
          GENERIC MAP (g_technology    => g_technology,
                       g_num_eth_lanes => c_num_eth_lanes)
          PORT MAP (clk                => clk_eth,
                    rst                => axi_rst,
                    mymac_addr         => local_mac,
                    eth_in_sosi        => eth_in_sosi,
                    eth_out_sosi       => decoder_out_sosi,
                    eth_out_siso       => decoder_out_siso
           );
rx_watch: ila_0
                     PORT MAP (clk      => clk_eth,
                               --probe0   => eth_in_sosi.tdata(63 DOWNTO 0),
                               probe0   => encoder_in_sosi(4).tdata(63 DOWNTO 0),
                               probe1(0)   => eth_in_sosi.tvalid,
                               probe2(0)  => decoder_out_siso(0).tready,--eth_in_sosi.tkeep(0),
                               probe3(0)  => decoder_out_siso(1).tready,--eth_in_sosi.tlast,
                               probe4(0)  => decoder_out_siso(2).tready,--eth_in_sosi.tuser(0),
                               probe5(0)  => decoder_out_siso(3).tready,--system_reset,
                               probe6(0)  => decoder_out_siso(4).tready,--eth_rx_reset,
                               probe7(0) =>  encoder_in_siso(4).tready,

                               --probe8 => decoder_out_sosi(2).tdata(63 DOWNTO 0),
                               probe8 => decoder_out_sosi(4).tdata(63 DOWNTO 0),

                               probe9(15 downto 0) =>  (others=>'0'),
                               probe9(47 downto 16) => (others=>'0'),
                               probe10 => eth_out_sosi.tdata(63 downto 0),
                               probe11(0) => eth_out_sosi.tvalid,
                               probe12(0) =>decoder_out_siso(3).tready,--eth_out_sosi.tlast,
                               probe13(0) =>dhcp_start,--eth_out_sosi.tuser(0),
                               probe14(0) =>encoder_in_sosi(4).tvalid,
                               probe15(0) =>encoder_in_sosi(4).tlast,
                               probe16(0) =>encoder_in_sosi(4).tuser(0),
                               probe17(0) =>decoder_out_sosi(2).tvalid,
                               probe18(0) =>decoder_out_sosi(3).tvalid,
                               probe19(0) =>decoder_out_sosi(4).tvalid
                               );


u_eth_tx : ENTITY eth_lib.eth_tx
           GENERIC MAP (g_technology        => g_technology,
                        g_num_frame_inputs  => c_num_eth_lanes,
                        g_max_packet_length => c_max_packet_length,
                        g_lane_priority     => c_tx_priority)
           PORT MAP (eth_tx_clk             => clk_eth,
                     eth_rx_clk             => clk_eth,
                     axi_clk                => clk_eth,
                     axi_rst                => axi_rst,
                     eth_tx_rst             => eth_tx_reset,
                     eth_address_ip         => local_ip,
                     eth_address_mac        => local_mac,
                     eth_pause_rx_enable    => ctl_rx_pause_enable,
                     eth_pause_rx_req       => stat_rx_pause_req,
                     eth_pause_rx_ack       => ctl_rx_pause_ack,
                     eth_out_sosi           => eth_out_sosi,
                     eth_out_siso           => eth_out_siso,
                     framer_in_sosi         => encoder_in_sosi,
                     framer_in_siso         => encoder_in_siso);

  ---------------------------------------------------------------------------
  -- Protocol Blocks  --
  ---------------------------------------------------------------------------

u_gemini_server: ENTITY gemini_server_lib.gemini_server
                 GENERIC MAP (g_technology   => g_technology,
                              g_min_recycle_secs => 0)
                 PORT MAP (clk               => clk_eth,
                           rst               => axi_rst,
                           ethrx_in          => decoder_out_sosi(0),
                           ethrx_out         => decoder_out_siso(0),
                           ethtx_in          => encoder_in_siso(0),
                           ethtx_out         => encoder_in_sosi(0),
                           mm_in             => mc_master_miso,
                           mm_out            => mc_master_mosi,
                           tod_in            => system_fields_ro.time_uptime);


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
      s_axi_mosi           => mc_lite_mosi(c_dhcp_dhcp_lite_index),
      s_axi_miso           => mc_lite_miso(c_dhcp_dhcp_lite_index),
      frame_in_sosi        => decoder_out_sosi(2),
      frame_in_siso        => decoder_out_siso(2),
      frame_out_sosi       => encoder_in_sosi(2),
      frame_out_siso       => encoder_in_siso(2));


u_arp_protocol: ENTITY arp_lib.arp_responder
                GENERIC MAP (g_technology   => g_technology)
                PORT MAP (clk               => clk_eth,
                          rst               => axi_rst,
                          eth_addr_ip       => local_ip,
                          eth_addr_mac      => local_mac,
                          frame_in_sosi     => decoder_out_sosi(3),
                          frame_in_siso     => decoder_out_siso(3),
                          frame_out_siso    => encoder_in_siso(3),
                          frame_out_sosi    => encoder_in_sosi(3));

u_icmp_protocol: ENTITY ping_protocol_lib.ping_protocol
                 GENERIC MAP (g_technology   => g_technology)
                 PORT MAP (clk          => clk_eth,
                           rst          => axi_rst,
                           eth_in_sosi  => decoder_out_sosi(4),
                           eth_in_siso  => decoder_out_siso(4),
                           eth_out_sosi => encoder_in_sosi(4),
                           eth_out_siso => encoder_in_siso(4),
                           my_mac       => local_mac);



u_pubsub_protocol: ENTITY gemini_subscription_lib.subscription_protocol
                   GENERIC MAP (g_technology    => g_technology,
                                g_num_clients   => 3)
                   PORT MAP (axi_clk            => clk_eth,
                             axi_rst            => axi_rst,
                             time_in            => local_time,
                             event_in           => event_in,
                             s_axi_mosi         => mc_lite_mosi(c_gemini_subscription_client_lite_index),
                             s_axi_miso         => mc_lite_miso(c_gemini_subscription_client_lite_index),
                             stream_out_sosi    => encoder_in_sosi(5),
                             stream_out_siso    => encoder_in_siso(5));


  ---------------------------------------------------------------------------
  -- Bus Interface  --
  ---------------------------------------------------------------------------

u_interconnect: ENTITY work.lru_minimal_bus_top
                PORT MAP (CLK             => clk_eth,
                          RST             => axi_rst,
                          SLA_IN          => mc_master_mosi,
                          SLA_OUT         => mc_master_miso,
                          MSTR_IN_LITE    => mc_lite_miso,
                          MSTR_OUT_LITE   => mc_lite_mosi,
                          MSTR_IN_FULL    => mc_full_miso,
                          MSTR_OUT_FULL   => mc_full_mosi);


  ---------------------------------------------------------------------------
  -- LED SUPPORT  --
  ---------------------------------------------------------------------------

   -- Use the local pps to generate a LED pulse
led_pps_extend : ENTITY common_lib.common_pulse_extend
                 GENERIC MAP (g_extend_w => 24) -- 135ms on time
                 PORT MAP (clk     => clk_125,
                           rst     => system_reset,
                           p_in    => pps,
                           ep_out  => pps_extended);

   -- Ethernet Activity
led_act_extend : ENTITY common_lib.common_pulse_extend
                 GENERIC MAP (g_extend_w => 25) -- 215ms on time
                 PORT MAP (clk     => clk_eth,
                           rst     => system_reset,
                           p_in    => eth_in_sosi.tlast,
                           ep_out  => eth_act_extended);


   led1_colour(7 DOWNTO 0) <= X"80" WHEN pps_extended = '1' ELSE X"00";       -- 1pps (Blue)
   led1_colour(15 DOWNTO 8) <= X"FF" WHEN eth_act_extended = '1' ELSE X"00";  -- Ethernet Act (Green)

   led2_colour <= (OTHERS => '0');
   led3_colour <= (OTHERS => '0');

u_led_driver : ENTITY spi_lib.spi_max6966
               GENERIC MAP (g_simulation  => g_sim,
                            g_input_clk   => 125)
               PORT MAP (clk           => clk_125,
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
      s_axi_mosi        => mc_lite_mosi(c_onewire_prom_onewire_prom_lite_index),
      s_axi_miso        => mc_lite_miso(c_onewire_prom_onewire_prom_lite_index),
      onewire_strong    => serial_id_pullup,
      onewire           => serial_id);


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
      s_axi_mosi        => mc_lite_mosi(c_backplane_prom_onewire_prom_BACKPLANE_PROM_onewire_prom_lite_index),
      s_axi_miso        => mc_lite_miso(c_backplane_prom_onewire_prom_BACKPLANE_PROM_onewire_prom_lite_index),
      onewire_strong    => bp_id_pullup,
      onewire           => bp_id);

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
      spi_mosi       => mc_full_mosi(c_axi4_quadspi_prom_axi4_quadspi_prom_full_index),
      spi_miso       => mc_full_miso(c_axi4_quadspi_prom_axi4_quadspi_prom_full_index),
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


pmbus_support: ENTITY gemini_lru_board_lib.pmbus_control
               PORT MAP (clk              => clk_eth,
                         rst              => axi_rst,
                         s_axi_mosi       => mc_lite_mosi(c_pmbus_control_lite_index),
                         s_axi_miso       => mc_lite_miso(c_pmbus_control_lite_index),
                         power_sda        => power_sda,
                         power_sdc        => power_sdc,
                         power_alert_n    => power_alert_n);

sfp_support: ENTITY gemini_lru_board_lib.sfp_control
             PORT MAP (rst             => axi_rst,
                       clk             => clk_eth,
                       s_axi_mosi      => mc_lite_mosi(c_sfp_sfp_lite_index),
                       s_axi_miso      => mc_lite_miso(c_sfp_sfp_lite_index),
                       sfp_sda         => sfp_sda,
                       sfp_scl         => sfp_scl,
                       sfp_fault       => sfp_fault,
                       sfp_tx_enable   => sfp_tx_enable,
                       sfp_mod_abs     => sfp_mod_abs);

humidity_support: ENTITY gemini_lru_board_lib.humidity_control
                  PORT MAP (clk            => clk_eth,
                            rst            => axi_rst,
                            s_axi_mosi     => mc_lite_mosi(c_humidity_humidity_lite_index),
                            s_axi_miso     => mc_lite_miso(c_humidity_humidity_lite_index),
                            hum_sda        => hum_sda,
                            hum_scl        => hum_sdc);

system_monitor: ENTITY tech_system_monitor_lib.tech_system_monitor
                GENERIC MAP (g_technology       => g_technology)
                PORT MAP (axi_clk               => clk_eth,
                          axi_reset             => axi_rst,
                          axi_lite_mosi         => mc_lite_mosi(c_system_monitor_system_monitor_lite_index),
                          axi_lite_miso         => mc_lite_miso(c_system_monitor_system_monitor_lite_index),
                          over_temperature      => event_in(2),
                          voltage_alarm         => OPEN,
                          temp_out              => OPEN,
                          v_p                   => '0',
                          v_n                   => '0',
                          vaux_p                => X"0000",
                          vaux_n                => X"0000");

  ---------------------------------------------------------------------------
  -- TOP Level Registers  --
  ---------------------------------------------------------------------------

fpga_regs: ENTITY work.lru_minimal_system_reg
           GENERIC MAP (g_technology    => g_technology)
           PORT MAP (MM_CLK             => clk_eth,
                     MM_RST             => axi_rst,
                     SLA_IN             => mc_lite_mosi(c_system_system_lite_index),
                     SLA_OUT            => mc_lite_miso(c_system_system_lite_index),
                     SYSTEM_FIELDS_RW   => system_fields_rw,
                     SYSTEM_FIELDS_RO   => system_fields_ro);

   -- General Status
--   system_fields_ro.status_ddr4_configured <= '1';


-- Build Date
u_useraccese2: USR_ACCESSE2
               PORT MAP (CFGCLK => OPEN,
                         DATA => system_fields_ro.build_date,
                         DATAVALID => OPEN);

-- Uptime counter
uptime_cnt: ENTITY gemini_lru_board_lib.uptime_counter
            GENERIC MAP (g_tod_width   => 14,
                         g_clk_freq    => 125.0E6)
            PORT MAP (clk              => clk_125,
                      rst              => system_reset,
                      pps              => pps,
                      tod_rollover     => system_fields_ro.time_wrapped,
                      tod              => system_fields_ro.time_uptime);


-- Shutdown logic
shutdown_reg_edge: ENTITY common_lib.common_evt
                   GENERIC MAP(g_evt_type => "RISING")
                   PORT MAP (clk       => clk_eth,
                             in_sig    => system_fields_rw.control_lru_shutdown,
                             out_evt   => shutdown_edge);

shutdown_timer: ENTITY common_lib.common_pulse_extend
                GENERIC MAP (g_extend_w => 27) -- 0.859s
                PORT MAP (clk     => clk_eth,
                          rst     => system_reset,
                          p_in    => shutdown_edge,
                          ep_out  => shutdown_extended);

shutdown_timer_edge: ENTITY common_lib.common_evt
                     GENERIC MAP(g_evt_type  => "FALLING",
                                 g_out_reg   => TRUE)
                     PORT MAP (clk     => clk_eth,
                               in_sig  => shutdown_extended,
                               out_evt => shutdown);


END structure;
