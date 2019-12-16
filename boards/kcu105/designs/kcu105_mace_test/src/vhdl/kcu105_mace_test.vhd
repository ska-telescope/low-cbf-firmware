-------------------------------------------------------------------------------
--
-- File Name: kcu105_mace_test.vhd
-- Contributing Authors:
-- Type: RTL
-- Created: Thurs Oct 19 16:40:00 2017
-- Template Rev: 1.0
--
-- Title: Top Level of KCU105 MACE test project
--
-- Description:  Implements a MACE control system with a limited number of
--               peripherals for software testing
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

LIBRARY IEEE, UNISIM, common_lib, axi4_lib, technology_lib;
LIBRARY kcu105_board_lib, eth_lib, arp_lib, dhcp_lib, gemini_server_lib, gemini_subscription_lib, ping_protocol_lib;
LIBRARY tech_axi4_quadspi_prom_lib, tech_system_monitor_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE axi4_lib.axi4_full_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE kcu105_board_lib.board_pkg.ALL;
USE kcu105_board_lib.ip_pkg.ALL;
USE work.kcu105_mace_test_bus_pkg.ALL;
USE work.kcu105_mace_test_system_reg_pkg.ALL;
USE UNISIM.vcomponents.all;

ENTITY kcu105_mace_test IS
   GENERIC (
      g_technology         : t_technology := c_tech_xcku040);
   PORT (
      SFP0_RX_P            : IN STD_LOGIC;
      SFP0_RX_N            : IN STD_LOGIC;
      SFP0_TX_P            : OUT STD_LOGIC;
      SFP0_TX_N            : OUT STD_LOGIC;
      SFP0_TX_DISABLE      : OUT STD_LOGIC;
      SFP0_LOS_LS          : IN STD_LOGIC;

      IIC_MAIN_SCL_LS      : INOUT STD_LOGIC;
      IIC_MAIN_SDA_LS      : INOUT STD_LOGIC;

      GPIO_LED_3_LS        : OUT STD_LOGIC;
      GPIO_LED_4_LS        : OUT STD_LOGIC;
      GPIO_LED_5_LS        : OUT STD_LOGIC;
      GPIO_LED_6_LS        : OUT STD_LOGIC;
      GPIO_LED_7_LS        : OUT STD_LOGIC;

      QSPI1_CS_B           : INOUT STD_LOGIC;
      QSPI1_IO0            : INOUT STD_LOGIC;
      QSPI1_IO1            : INOUT STD_LOGIC;
      QSPI1_IO2            : INOUT STD_LOGIC;
      QSPI1_IO3            : INOUT STD_LOGIC;

      SYSMON_VP_R          : IN STD_LOGIC;
      SYSMON_VN_R          : IN STD_LOGIC;
      SYSMON_AD0_R_P       : IN STD_LOGIC;
      SYSMON_AD0_R_N       : IN STD_LOGIC;
      SYSMON_AD2_R_P       : IN STD_LOGIC;
      SYSMON_AD2_R_N       : IN STD_LOGIC;
      SYSMON_AD8_R_P       : IN STD_LOGIC;
      SYSMON_AD8_R_N       : IN STD_LOGIC;

      CPU_RESET            : IN STD_LOGIC;      -- Active high
      SI5328_OUT_C_P       : IN STD_LOGIC;      -- 156.25 MHz
      SI5328_OUT_C_N       : IN STD_LOGIC;
      CLK_125MHZ_P         : IN STD_LOGIC;      -- 125 MHz
      CLK_125MHZ_n         : IN STD_LOGIC);
END kcu105_mace_test;

ARCHITECTURE str OF kcu105_mace_test IS

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
   SIGNAL clk_eth                : STD_LOGIC;      -- RX Recovered clock (synchronous Ethernet reference)
   SIGNAL clk_tx_eth             : STD_LOGIC;      -- TX Clock

   SIGNAL system_reset_shift     : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '1');
   SIGNAL system_reset           : STD_LOGIC;
   SIGNAL system_locked          : STD_LOGIC;


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

   SIGNAL decoder_out_sosi       : t_axi4_sosi_arr(0 TO c_num_eth_lanes-1);
   SIGNAL decoder_out_siso       : t_axi4_siso_arr(0 TO c_num_eth_lanes-1);
   SIGNAL encoder_in_sosi        : t_axi4_sosi_arr(0 TO c_num_eth_lanes-1);
   SIGNAL encoder_in_siso        : t_axi4_siso_arr(0 TO c_num_eth_lanes-1);

   SIGNAL mc_master_mosi         : t_axi4_full_mosi;
   SIGNAL mc_master_miso         : t_axi4_full_miso;
   SIGNAL mc_lite_miso           : t_axi4_lite_miso_arr(0 TO c_nof_lite_slaves-1);
   SIGNAL mc_lite_mosi           : t_axi4_lite_mosi_arr(0 TO c_nof_lite_slaves-1);
   SIGNAL mc_full_miso           : t_axi4_full_miso_arr(0 TO c_nof_full_slaves-1);
   SIGNAL mc_full_mosi           : t_axi4_full_mosi_arr(0 TO c_nof_full_slaves-1);

   SIGNAL local_time             : STD_LOGIC_VECTOR(63 DOWNTO 0);
   SIGNAL event_in               : STD_LOGIC_VECTOR(31 DOWNTO 0);

   SIGNAL dhcp_start             : STD_LOGIC;

   SIGNAL system_fields_ro       : t_system_ro;
   SIGNAL testbram_in           : t_system_xyz_testbram_ram_in;

   SIGNAL pps                    : STD_LOGIC;

   SIGNAL prom_spi_i             : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL prom_spi_o             : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL prom_spi_t             : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL prom_spi_ss_o          : STD_LOGIC;
   SIGNAL prom_spi_ss_t          : STD_LOGIC;


   SIGNAL gnd                    : STD_LOGIC_VECTOR(299 DOWNTO 0);
   SIGNAL vcc                    : STD_LOGIC_VECTOR(255 DOWNTO 0);

   COMPONENT ila_0
   PORT (
      clk : IN STD_LOGIC;
      probe0 : IN STD_LOGIC_VECTOR(199 DOWNTO 0));
   END COMPONENT;

   COMPONENT ila_2
   PORT (
       clk : IN STD_LOGIC;
       probe0 : IN STD_LOGIC_VECTOR(32 DOWNTO 0); 
       probe1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
       probe2 : IN STD_LOGIC_VECTOR(7 DOWNTO 0); 
       probe3 : IN STD_LOGIC_VECTOR(2 DOWNTO 0); 
       probe4 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
       probe5 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
       probe6 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
       probe7 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
       probe8 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
       probe9 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
       probe10 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
       probe11 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
   );
   END COMPONENT  ;


BEGIN
   vcc <= (OTHERS => '1');
   gnd <= (OTHERS  => '0');

  ---------------------------------------------------------------------------
  -- CLOCKING & RESETS  --
  ---------------------------------------------------------------------------

system_pll: system_clock
            PORT MAP (clk_in1_p  => CLK_125MHZ_P,
                      clk_in1_n  => CLK_125MHZ_N,
                      clk_125    => clk_125,
                      clk_100    => clk_100,
                      reset      => CPU_RESET,
                      locked     => system_locked);

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

   u_mace_mac: ENTITY kcu105_board_lib.mace_mac
   GENERIC MAP (
      g_technology         => g_technology)
   PORT MAP (
      sfp_rx_p             => SFP0_RX_P,
      sfp_rx_n             => SFP0_RX_N,
      sfp_tx_p             => SFP0_TX_P,
      sfp_tx_n             => SFP0_TX_N,
      sfp_clk_c_p          => SI5328_OUT_C_P,
      sfp_clk_c_n          => SI5328_OUT_C_N,
      system_reset         => system_reset,
      rst_clk              => clk_100,
      tx_clk               => clk_tx_eth,
      rx_clk               => clk_eth,
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

   GPIO_LED_3_LS <= eth_locked;

   u_eth_rx: ENTITY eth_lib.eth_rx
   GENERIC MAP (
      g_technology      => g_technology,
      g_num_eth_lanes   => c_num_eth_lanes)
   PORT MAP (
      clk               => clk_eth,
      rst               => eth_rx_reset,
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
      eth_tx_clk           => clk_tx_eth,
      eth_rx_clk           => clk_eth,
      axi_clk              => clk_eth,
      axi_rst              => eth_rx_reset,
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

  ---------------------------------------------------------------------------
  -- Protocol Blocks  --
  ---------------------------------------------------------------------------

   u_gemini_server: ENTITY gemini_server_lib.gemini_server
   GENERIC MAP (
      g_technology         => g_technology,
      g_min_recycle_secs   => 30, -- Seconds before timing out a Gemini CNX
      g_txfr_timeout       => 6250) --allow time for packet-length register read
   PORT MAP (
      clk                  => clk_eth,
      rst                  => eth_rx_reset,
      ethrx_in             => decoder_out_sosi(0),
      ethrx_out            => decoder_out_siso(0),
      ethtx_in             => encoder_in_siso(0),
      ethtx_out            => encoder_in_sosi(0),
      mm_in                => mc_master_miso,
      mm_out               => mc_master_mosi,
      tod_in               => system_fields_ro.time_uptime,
    -- status signals to send to the register interface
      client0IP => system_fields_ro.cnx0_client0IP, -- : out std_logic_vector(31 downto 0);
      client0Port => system_fields_ro.cnx1_client0Port, -- : out std_logic_vector(15 downto 0);
      client0LastUsed => system_fields_ro.cnx2_client0LastUsed, -- : out std_logic_vector(31 downto 0);
      client1IP => system_fields_ro.cnx3_client1IP, -- : out std_logic_vector(31 downto 0);
      client1Port  => system_fields_ro.cnx4_client1Port, --: out std_logic_vector(15 downto 0);
      client1LastUsed => system_fields_ro.cnx5_client1LastUsed, -- : out std_logic_vector(31 downto 0);
      client2IP => system_fields_ro.cnx6_client2IP, -- : out std_logic_vector(31 downto 0);
      client2Port  => system_fields_ro.cnx7_client2Port, --: out std_logic_vector(15 downto 0);
      client2LastUsed => system_fields_ro.cnx8_client2LastUsed -- : out std_logic_vector(31 downto 0)
      );

   decoder_out_siso(1).tready <= '1';

   dhcp_start <= eth_locked;

   u_dhcp_protocol: ENTITY dhcp_lib.dhcp_protocol
   GENERIC MAP (
      g_technology         => g_technology)
   PORT MAP (
      axi_clk              => clk_eth,
      axi_rst              => eth_rx_reset,
      ip_address_default   => prom_ip,
      mac_address          => local_mac,
      serial_number        => X"FFFFFFFF",
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
      rst            => eth_rx_reset,
      eth_addr_ip    => local_ip,
      eth_addr_mac   => local_mac,
      frame_in_sosi  => decoder_out_sosi(3),
      frame_in_siso  => decoder_out_siso(3),
      frame_out_siso => encoder_in_siso(3),
      frame_out_sosi => encoder_in_sosi(3));

   u_icmp_protocol: ENTITY ping_protocol_lib.ping_protocol
   PORT MAP (
      clk            => clk_eth,
      rst            => eth_rx_reset,
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
      axi_rst           => eth_rx_reset,
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

   u_interconnect: ENTITY work.kcu105_mace_test_bus_top
   PORT MAP (
      CLK            => clk_eth,
      RST            => eth_rx_reset,
      SLA_IN         => mc_master_mosi,
      SLA_OUT        => mc_master_miso,
      MSTR_IN_LITE   => mc_lite_miso,
      MSTR_OUT_LITE  => mc_lite_mosi,
      MSTR_IN_FULL   => mc_full_miso,
      MSTR_OUT_FULL  => mc_full_mosi);

-- monitoring of u_interconnect input and output
interconnect_mon : ila_2
PORT MAP (
    clk => clk_eth,
    probe0 => mc_master_mosi.araddr, 
    probe1(0) => mc_master_mosi.arvalid, 
    probe2 => mc_master_mosi.arlen,
    probe3 => mc_master_mosi.arsize,
    probe4(0) => mc_lite_mosi(0).arvalid, 
    probe5(0) => mc_lite_mosi(1).arvalid, 
    probe6(0) => mc_lite_mosi(2).arvalid, 
    probe7(0) => mc_lite_mosi(3).arvalid, 
    probe8(0) => mc_lite_mosi(4).arvalid, 
    probe9(0) => mc_lite_mosi(5).arvalid, 
    probe10(0) => mc_full_mosi(0).arvalid,
    probe11(0) => mc_full_mosi(1).arvalid

);
  ---------------------------------------------------------------------------
  -- LED SUPPORT  --
  ---------------------------------------------------------------------------


   -- Use the local pps to generate a LED pulse
   led_pps_extend : ENTITY common_lib.common_pulse_extend
   GENERIC MAP (
      g_extend_w  => 23)
   PORT MAP (
      clk         => clk_100,
      rst         => system_reset,
      p_in        => pps,
      ep_out      => GPIO_LED_4_LS);

   -- Ethernet Activity
   led_act_extend : ENTITY common_lib.common_pulse_extend
   GENERIC MAP (
      g_extend_w  => 24) -- 136ms on time
   PORT MAP (
      clk         => clk_eth,
      rst         => system_reset,
      p_in        => eth_in_sosi.tlast,
      ep_out      => GPIO_LED_5_LS);



  ---------------------------------------------------------------------------
  -- HARDWARE BOARD SUPPORT  --
  ---------------------------------------------------------------------------

   sfp_support: ENTITY kcu105_board_lib.sfp_control
   GENERIC MAP (
      g_technology   => g_technology)
   PORT MAP (
      rst            => eth_rx_reset,
      clk            => clk_eth,
      s_axi_mosi     => mc_lite_mosi(c_sfp_lite_index),
      s_axi_miso     => mc_lite_miso(c_sfp_lite_index),
      sfp_sda        => IIC_MAIN_SDA_LS,
      sfp_scl        => IIC_MAIN_SCL_LS,
      sfp_fault      => '0',
      sfp_tx_enable  => SFP0_TX_DISABLE,
      sfp_mod_abs    => '0');


   config_prom: ENTITY tech_axi4_quadspi_prom_lib.tech_axi4_quadspi_prom
   GENERIC MAP (
      g_technology   => g_technology)
   PORT MAP (
      axi_clk        => clk_eth,
      spi_clk        => clk_100,
      axi_rst        => eth_rx_reset,
      spi_interrupt  => OPEN,
      spi_mosi       => mc_full_mosi(c_axi4_quadspi_prom_full_index),
      spi_miso       => mc_full_miso(c_axi4_quadspi_prom_full_index),
      spi_i          => prom_spi_i,
      spi_o          => prom_spi_o,
      spi_t          => prom_spi_t,
      spi_ss_i       => QSPI1_CS_B,
      spi_ss_o       => prom_spi_ss_o,
      spi_ss_t       => prom_spi_ss_t,
      end_of_startup => OPEN);

   -- Second SPI PROM CS pin not through startup block
   QSPI1_CS_B <= prom_spi_ss_o WHEN prom_spi_ss_t = '0' ELSE 'Z';

   QSPI1_IO0 <= prom_spi_o(0) WHEN prom_spi_t(0) = '0' ELSE 'Z';
   prom_spi_i(0) <= QSPI1_IO0;

   QSPI1_IO1 <= prom_spi_o(1) WHEN prom_spi_t(1) = '0' ELSE 'Z';
   prom_spi_i(1) <= QSPI1_IO1;

   QSPI1_IO2 <= prom_spi_o(2) WHEN prom_spi_t(2) = '0' ELSE 'Z';
   prom_spi_i(2) <= QSPI1_IO2;

   QSPI1_IO3 <= prom_spi_o(3) WHEN prom_spi_t(3) = '0' ELSE 'Z';
   prom_spi_i(3) <= QSPI1_IO3;


   system_monitor: ENTITY tech_system_monitor_lib.tech_system_monitor
   GENERIC MAP (
      g_technology         => g_technology)
   PORT MAP (
      axi_clk              => clk_eth,
      axi_reset            => eth_rx_reset,
      axi_lite_mosi        => mc_lite_mosi(c_system_monitor_lite_index),
      axi_lite_miso        => mc_lite_miso(c_system_monitor_lite_index),
      over_temperature     => event_in(2),
      voltage_alarm        => OPEN,
      temp_out             => OPEN,
      v_p                  => SYSMON_VP_R,
      v_n                  => SYSMON_VN_R,
      vaux_p(15 DOWNTO 9)  => gnd(15 DOWNTO 9),
      vaux_p(8)            => SYSMON_AD8_R_P,
      vaux_p(7 DOWNTO 3)   => gnd(7 DOWNTO 3),
      vaux_p(2)            => SYSMON_AD2_R_P,
      vaux_p(1)            => '0',
      vaux_p(0)            => SYSMON_AD0_R_P,
      vaux_n(15 DOWNTO 9)  => gnd(15 DOWNTO 9),
      vaux_n(8)            => SYSMON_AD8_R_N,
      vaux_n(7 DOWNTO 3)   => gnd(7 DOWNTO 3),
      vaux_n(2)            => SYSMON_AD2_R_N,
      vaux_n(1)            => '0',
      vaux_n(0)            => SYSMON_AD0_R_N);

  ---------------------------------------------------------------------------
  -- TOP Level Registers  --
  ---------------------------------------------------------------------------

   fpga_regs: ENTITY work.kcu105_mace_test_system_reg
   GENERIC MAP (
      g_technology      => g_technology)
   PORT MAP (
      mm_clk            => clk_eth,
      mm_rst            => eth_rx_reset,
      sla_in            => mc_lite_mosi(c_system_lite_index),
      sla_out           => mc_lite_miso(c_system_lite_index),
      system_fields_ro  => system_fields_ro,
      system_xyz_testbram_in => testbram_in
   );
  -- This side of the registers-testbram is not used (only used on args/gemini side)
  testbram_in.wr_dat <= (others => '0');
  testbram_in.clk <= clk_eth;
  testbram_in.wr_en <= '0';
  testbram_in.adr <= (others => '0');
  testbram_in.rd_en <= '0';
  testbram_in.rst <= eth_rx_reset;

   -- Build Date
   u_useraccese2: USR_ACCESSE2
   PORT MAP (
      CFGCLK     => OPEN,
      DATA       => system_fields_ro.build_date,
      DATAVALID  => OPEN);

   -- Uptime counter
   uptime_cnt: ENTITY kcu105_board_lib.uptime_counter
   GENERIC MAP (
      g_tod_width    => 14,
      g_clk_freq     => 100.0E6)
   PORT MAP (
      clk            => clk_100,
      rst            => system_reset,
      pps            => pps,
      tod_rollover   => system_fields_ro.time_wrapped,
      tod            => system_fields_ro.time_uptime);

   demo_ram: ENTITY work.kcu105_mace_test_demo_client_ram
   PORT MAP (
      CLK_A    => clk_eth,
      RST_A    => eth_rx_reset,
      CLK_B    => clk_100,
      RST_B    => system_reset,
      MM_IN    => mc_full_mosi(c_demo_full_index),
      MM_OUT   => mc_full_miso(c_demo_full_index),
      APP_IN   => c_axi4_full_mosi_null,
      APP_OUT  => OPEN);


   local_mac <= c_default_mac;
   prom_ip <= c_default_ip;




rx_watch: ila_0
          PORT MAP (clk                   => clk_eth,
                    probe0(63 DOWNTO 0)   => eth_in_sosi.tdata(63 DOWNTO 0),
                    probe0(64)            => eth_in_sosi.tvalid,
                    probe0(72 DOWNTO 65)  => eth_in_sosi.tstrb(7 DOWNTO 0),
                    probe0(80 DOWNTO 73)  => eth_in_sosi.tkeep(7 DOWNTO 0),
                    probe0(81)            => eth_in_sosi.tlast,
                    probe0(82)            => eth_in_sosi.tuser(0),
                    probe0(83)            => eth_in_siso.tready,
                    probe0(92 DOWNTO 84)  => ctl_rx_pause_ack,
                    probe0(101 DOWNTO 93)  => ctl_rx_pause_enable,
                    probe0(110 DOWNTO 102) => stat_rx_pause_req,
                    probe0(174 DOWNTO 111) => decoder_out_sosi(0).tdata(63 DOWNTO 0),
                    probe0(182 DOWNTO 175) => decoder_out_sosi(0).tstrb(7 DOWNTO 0),
                    probe0(190 DOWNTO 183) => decoder_out_sosi(0).tkeep(7 DOWNTO 0),
                    probe0(191) => decoder_out_sosi(0).tlast,
                    probe0(192) => decoder_out_sosi(0).tvalid,
                    probe0(193) => decoder_out_sosi(1).tvalid,
                    probe0(194) => decoder_out_sosi(2).tvalid,
                    probe0(195) => decoder_out_sosi(3).tvalid,
                    probe0(196) => decoder_out_sosi(4).tvalid,
                    probe0(197) => decoder_out_sosi(5).tvalid,
                    probe0(199 DOWNTO 198) => gnd(199 DOWNTO 198));


END str;

