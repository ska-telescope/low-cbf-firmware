-------------------------------------------------------------------------------
--
-- Copyright (C) 2017
-- ASTRON (Netherlands Institute for Radio Astronomy) <http:--www.astron.nl/>
-- JIVE (Joint Institute for VLBI in Europe) <http:--www.jive.nl/>
-- P.O.Box 2, 7990 AA Dwingeloo, The Netherlands
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http:--www.gnu.org/licenses/>.
--
-------------------------------------------------------------------------------

LIBRARY IEEE, UNISIM, common_lib, axi4_lib, technology_lib, arp_lib, dhcp_lib;
LIBRARY tech_mac_10g_lib, tech_axi4_quadspi_prom_lib, tech_system_monitor_lib;
LIBRARY eth_lib, arp_lib, dhcp_lib, gemini_server_lib, gemini_subscription_lib, ping_protocol_lib;
LIBRARY kcu105_board_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE axi4_lib.axi4_full_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE kcu105_board_lib.kcu105_board_pkg.ALL;
USE kcu105_board_lib.ip_pkg.ALL;
USE work.kcu105_eeprom_test_bus_pkg.ALL;
USE work.kcu105_eeprom_test_system_reg_pkg.ALL;
USE UNISIM.vcomponents.all;

ENTITY kcu105_eeprom_test IS
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
END kcu105_eeprom_test;

ARCHITECTURE str OF kcu105_eeprom_test IS

   ---------------------------------------------------------------------------
   -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
   ---------------------------------------------------------------------------

   CONSTANT c_num_eth_lanes      : INTEGER := 6;
   CONSTANT c_default_ip         : STD_LOGIC_VECTOR(31 DOWNTO 0) := X"0a20000a"; -- 10.32.0.10
   CONSTANT c_default_mac        : STD_LOGIC_VECTOR(47 DOWNTO 0) := x"C02B3C4D5E6F";
   CONSTANT c_max_packet_length  : INTEGER := 8192;
   CONSTANT c_tx_priority        : t_integer_arr(0 to 15) := (0,  -- Gemini M&C
                                                              0,
                                                              3,  -- DHCP
                                                              7,  -- ARP
                                                              0,
                                                              0,
                                                              0,0,0,0,0,0,0,0,0,0);

   ---------------------------------------------------------------------------
   -- SIGNAL DECLARATIONS  --
   ---------------------------------------------------------------------------

   SIGNAL clk_125                : STD_LOGIC;
   SIGNAL clk_100                : STD_LOGIC;
   SIGNAL clk_eth_tx             : STD_LOGIC;
   SIGNAL clk_eth_rx             : STD_LOGIC;
   SIGNAL clk_ddr4               : STD_LOGIC;

   SIGNAL system_reset_shift     : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '1');
   SIGNAL system_reset           : STD_LOGIC;
   SIGNAL system_locked          : STD_LOGIC;

   SIGNAL local_mac              : STD_LOGIC_VECTOR(47 DOWNTO 0);
   SIGNAL local_ip               : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL eth_in_siso            : t_axi4_siso;
   SIGNAL eth_in_sosi            : t_axi4_sosi;
   SIGNAL eth_out_sosi           : t_axi4_sosi;
   SIGNAL eth_out_siso           : t_axi4_siso;
   SIGNAL eth_rx_reset           : STD_LOGIC;
   SIGNAL eth_tx_reset           : STD_LOGIC;
   SIGNAL eth_locked             : STD_LOGIC;
   SIGNAL ctl_rx_pause_ack       : STD_LOGIC_VECTOR(8 DOWNTO 0);
   SIGNAL ctl_rx_pause_enable    : STD_LOGIC_VECTOR(8 DOWNTO 0);
   SIGNAL stat_rx_pause_req      : STD_LOGIC_VECTOR(8 DOWNTO 0);

   SIGNAL dhcp_start             : STD_LOGIC;

   SIGNAL decoder_out_sosi       : t_axi4_sosi_arr(0 TO c_num_eth_lanes-1);
   SIGNAL decoder_out_siso       : t_axi4_siso_arr(0 TO c_num_eth_lanes-1);
   SIGNAL encoder_in_sosi        : t_axi4_sosi_arr(0 TO c_num_eth_lanes-1);
   SIGNAL encoder_in_siso        : t_axi4_siso_arr(0 TO c_num_eth_lanes-1);

   SIGNAL mc_master_mosi         : t_axi4_full_mosi;
   SIGNAL mc_master_miso         : t_axi4_full_miso;
   SIGNAL mc_lite_miso           : t_axi4_lite_miso_arr(c_nof_lite_slaves-1 DOWNTO 0);
   SIGNAL mc_lite_mosi           : t_axi4_lite_mosi_arr(c_nof_lite_slaves-1 DOWNTO 0);
   SIGNAL mc_full_miso           : t_axi4_full_miso_arr(c_nof_full_slaves-1 DOWNTO 0);
   SIGNAL mc_full_mosi           : t_axi4_full_mosi_arr(c_nof_full_slaves-1 DOWNTO 0);


   SIGNAL prom_startup_complete  : STD_LOGIC;
   SIGNAL local_prom_ip          : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL serial_number          : STD_LOGIC_VECTOR(31 DOWNTO 0);

   SIGNAL pps                    : STD_LOGIC;
   SIGNAL local_time             : STD_LOGIC_VECTOR(63 DOWNTO 0);          -- UTC time
   SIGNAL event_in               : STD_LOGIC_VECTOR(31 DOWNTO 0);

   SIGNAL prom_spi_i             : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL prom_spi_o             : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL prom_spi_t             : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL prom_spi_ss_o          : STD_LOGIC;
   SIGNAL prom_spi_ss_t          : STD_LOGIC;

   SIGNAL system_fields_rw       : t_system_rw;
   SIGNAL system_fields_ro       : t_system_ro;

   SIGNAL gnd                    : STD_LOGIC_VECTOR(399 DOWNTO 0);
   SIGNAL vcc                    : STD_LOGIC_VECTOR(399 DOWNTO 0);

   COMPONENT ila_0
   PORT (
      clk : IN STD_LOGIC;
      probe0 : IN STD_LOGIC_VECTOR(299 DOWNTO 0));
   END COMPONENT;

   COMPONENT axi_ila
   PORT (
   	clk : IN STD_LOGIC;
   	probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
   	probe1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
   	probe2 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
   	probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
   	probe4 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
   	probe5 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
   	probe6 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
   	probe7 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
   	probe8 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
   	probe9 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
   	probe10 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
   	probe11 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
   	probe12 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
   	probe13 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
   	probe14 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
   	probe15 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
   	probe16 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
   	probe17 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
   	probe18 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
   	probe19 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
   	probe20 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
   	probe21 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
   	probe22 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
   	probe23 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
   	probe24 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
   	probe25 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
   	probe26 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
   	probe27 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
   	probe28 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
   	probe29 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
   	probe30 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
   	probe31 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
   	probe32 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
   	probe33 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
   	probe34 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
   	probe35 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
   	probe36 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
   	probe37 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
   	probe38 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
   	probe39 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
   	probe40 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
   	probe41 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
   	probe42 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
   	probe43 : IN STD_LOGIC_VECTOR(0 DOWNTO 0));
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

system_pll_reset: PROCESS(clk_125)
   BEGIN
      IF RISING_EDGE(clk_125) THEN
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
      clk_125              => clk_125,
      clk_tx               => clk_eth_tx,
      clk_rx               => clk_eth_rx,
      clk_axi              => clk_eth_rx,
      eth_rx_reset         => eth_rx_reset,
      eth_in_sosi          => eth_in_sosi,
      eth_in_siso          => eth_in_siso,
      eth_out_sosi         => eth_out_sosi,
      eth_out_siso         => eth_out_siso,
      eth_locked           => eth_locked,
      eth_tx_reset         => eth_tx_reset,
      local_mac            => local_mac,
      s_axi_mosi           => c_axi4_lite_mosi_rst, --mc_lite_mosi(c_ethernet_statistics_lite_index),
      s_axi_miso           => open, --mc_lite_miso(c_ethernet_statistics_lite_index),
      ctl_rx_pause_ack     => ctl_rx_pause_ack,
      ctl_rx_pause_enable  => ctl_rx_pause_enable,
      stat_rx_pause_req    => stat_rx_pause_req);

   GPIO_LED_3_LS <= eth_locked;

   u_eth_rx: ENTITY eth_lib.eth_rx
   GENERIC MAP (
      g_technology    => g_technology,
      g_num_eth_lanes => c_num_eth_lanes)
   PORT MAP (
      clk                => clk_eth_rx,
      rst                => eth_rx_reset,
      mymac_addr         => local_mac,
      eth_in_sosi        => eth_in_sosi,
      eth_out_sosi       => decoder_out_sosi,
      eth_out_siso       => decoder_out_siso);

   u_eth_tx : ENTITY eth_lib.eth_tx
   GENERIC MAP (
      g_technology        => g_technology,
      g_num_frame_inputs  => c_num_eth_lanes,
      g_max_packet_length => c_max_packet_length,
      g_lane_priority     => c_tx_priority)
   PORT MAP (
      eth_tx_clk             => clk_eth_tx,
      eth_rx_clk             => clk_eth_rx,
      axi_clk                => clk_eth_rx,
      axi_rst                => eth_rx_reset,
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
   GENERIC MAP (
      g_technology      => g_technology,
      g_min_recycle_secs => 0)                      -- Need to timeout connections straight away
   PORT MAP (
      clk               => clk_eth_rx,
      rst               => eth_rx_reset,
      ethrx_in          => decoder_out_sosi(0),
      ethrx_out         => decoder_out_siso(0),
      ethtx_in          => encoder_in_siso(0),
      ethtx_out         => encoder_in_sosi(0),
      mm_in             => mc_master_miso,
      mm_out            => mc_master_mosi,
      tod_in            => system_fields_ro.time_uptime);

   decoder_out_siso(1).tready <= '1';
   dhcp_start <= eth_locked;

   u_dhcp_protocol: ENTITY dhcp_lib.dhcp_protocol
   GENERIC MAP (
      g_technology         => g_technology)
   PORT MAP (
      axi_clk                 => clk_eth_rx,
      axi_rst                 => eth_rx_reset,
      ip_address_default      => local_prom_ip,
      mac_address             => local_mac,
      serial_number           => serial_number,
      dhcp_start              => dhcp_start,
      ip_address              => local_ip,
      ip_event                => event_in(0),
      s_axi_mosi              => mc_lite_mosi(c_dhcp_dhcp_lite_index),
      s_axi_miso              => mc_lite_miso(c_dhcp_dhcp_lite_index),
      frame_in_sosi           => decoder_out_sosi(2),
      frame_in_siso           => decoder_out_siso(2),
      frame_out_sosi          => encoder_in_sosi(2),
      frame_out_siso          => encoder_in_siso(2));

   u_arp_protocol: ENTITY arp_lib.arp_responder
   GENERIC MAP (
      g_technology   => g_technology)
   PORT MAP (
      clk               => clk_eth_rx,
      rst               => eth_rx_reset,
      eth_addr_ip       => local_ip,
      eth_addr_mac      => local_mac,
      frame_in_sosi     => decoder_out_sosi(3),
      frame_in_siso     => decoder_out_siso(3),
      frame_out_siso    => encoder_in_siso(3),
      frame_out_sosi    => encoder_in_sosi(3));

   u_icmp_protocol: ENTITY ping_protocol_lib.ping_protocol
   PORT MAP (
      clk          => clk_eth_rx,
      rst          => eth_rx_reset,
      eth_in_sosi  => decoder_out_sosi(4),
      eth_out_sosi => encoder_in_sosi(4));

   decoder_out_siso(4).tready <= '1';

   u_pubsub_protocol: ENTITY gemini_subscription_lib.subscription_protocol
   GENERIC MAP (
      g_technology    => g_technology,
      g_num_clients   => 4)
   PORT MAP (
      axi_clk            => clk_eth_rx,
      axi_rst            => eth_rx_reset,
      time_in            => local_time,
      event_in           => event_in,
      s_axi_mosi         => mc_lite_mosi(c_gemini_subscription_client_lite_index),
      s_axi_miso         => mc_lite_miso(c_gemini_subscription_client_lite_index),
      stream_out_sosi    => encoder_in_sosi(5),
      stream_out_siso    => encoder_in_siso(5));

   decoder_out_siso(5).tready <= '1';

  ---------------------------------------------------------------------------
  -- AXI INTERCONNECT  --
  ---------------------------------------------------------------------------

   u_interconnect: ENTITY work.kcu105_eeprom_test_bus_top
   PORT MAP (
      CLK            => clk_eth_rx,
      RST            => eth_rx_reset,
      SLA_IN         => mc_master_mosi,
      SLA_OUT        => mc_master_miso,
      MSTR_IN_LITE   => mc_lite_miso,
      MSTR_OUT_LITE  => mc_lite_mosi,
      MSTR_IN_FULL   => mc_full_miso,
      MSTR_OUT_FULL  => mc_full_mosi);

  ---------------------------------------------------------------------------
  -- HARDWARE BOARD SUPPORT  --
  ---------------------------------------------------------------------------

   u_config_prom: ENTITY tech_axi4_quadspi_prom_lib.tech_axi4_quadspi_prom
   GENERIC MAP (
      g_technology    => g_technology)
   PORT MAP (
      axi_clk            => clk_eth_rx,
      spi_clk            => clk_100,
      axi_rst            => eth_rx_reset,
      spi_interrupt      => OPEN,
      spi_mosi           => mc_full_mosi(c_axi4_quadspi_prom_axi4_quadspi_prom_full_index),
      spi_miso           => mc_full_miso(c_axi4_quadspi_prom_axi4_quadspi_prom_full_index),
      spi_i              => prom_spi_i,
      spi_o              => prom_spi_o,
      spi_t              => prom_spi_t,
      spi_ss_i           => QSPI1_CS_B,
      spi_ss_o           => prom_spi_ss_o,
      spi_ss_t           => prom_spi_ss_t,
      end_of_startup     => OPEN);

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

   -- EEPROM
   serial_number <= X"00000001";
   local_mac <= c_default_mac;
   local_prom_ip <= c_default_ip;
   prom_startup_complete <= '1';

  ---------------------------------------------------------------------------
  -- TOP Level Registers  --
  ---------------------------------------------------------------------------

   fpga_regs: ENTITY work.kcu105_eeprom_test_system_reg
   GENERIC MAP (
      g_technology    => g_technology)
   PORT MAP (
      CLK                => clk_eth_rx,
      RST                => eth_rx_reset,
      SLA_IN             => mc_lite_mosi(c_system_system_lite_index),
      SLA_OUT            => mc_lite_miso(c_system_system_lite_index),
      SYSTEM_FIELDS_RW   => system_fields_rw,
      SYSTEM_FIELDS_RO   => system_fields_ro);

   -- Build Date
   u_useraccese2: USR_ACCESSE2
   PORT MAP (
      CFGCLK => OPEN,
      DATA => system_fields_ro.build_date,
      DATAVALID => OPEN);

-- Uptime counter
   uptime_cnt: ENTITY kcu105_board_lib.uptime_counter
   GENERIC MAP (
      g_tod_width   => 14,
      g_clk_freq    => 125.0E6)
   PORT MAP (
      clk              => clk_125,
      rst              => system_reset,
      pps              => pps,
      tod_rollover     => system_fields_ro.time_wrapped,
      tod              => system_fields_ro.time_uptime);

  ---------------------------------------------------------------------------
  -- Board Support  --
  ---------------------------------------------------------------------------

   system_monitor: ENTITY tech_system_monitor_lib.tech_system_monitor
   GENERIC MAP (
      g_technology       => g_technology)
   PORT MAP (
      axi_clk               => clk_eth_rx,
      axi_reset             => eth_rx_reset,
      axi_lite_mosi         => mc_lite_mosi(c_system_monitor_system_monitor_lite_index),
      axi_lite_miso         => mc_lite_miso(c_system_monitor_system_monitor_lite_index),
      over_temperature      => OPEN,
      voltage_alarm         => OPEN,
      temp_out              => OPEN,
      v_p                   => SYSMON_VP_R,
      v_n                   => SYSMON_VN_R,
      vaux_p(15 DOWNTO 9)   => gnd(15 DOWNTO 9),
      vaux_p(8)             => SYSMON_AD8_R_P,
      vaux_p(7 DOWNTO 3)    => gnd(7 DOWNTO 3),
      vaux_p(2)             => SYSMON_AD2_R_P,
      vaux_p(1)             => '0',
      vaux_p(0)             => SYSMON_AD0_R_P,
      vaux_n(15 DOWNTO 9)   => gnd(15 DOWNTO 9),
      vaux_n(8)             => SYSMON_AD8_R_N,
      vaux_n(7 DOWNTO 3)    => gnd(7 DOWNTO 3),
      vaux_n(2)             => SYSMON_AD2_R_N,
      vaux_n(1)             => '0',
      vaux_n(0)             => SYSMON_AD0_R_N);

   sfp_support: ENTITY kcu105_board_lib.sfp_control
   PORT MAP (
      rst             => eth_rx_reset,
      clk             => clk_eth_rx,
      s_axi_mosi      => mc_lite_mosi(c_sfp_sfp_lite_index),
      s_axi_miso      => mc_lite_miso(c_sfp_sfp_lite_index),
      sfp_sda         => IIC_MAIN_SDA_LS,
      sfp_scl         => IIC_MAIN_SCL_LS,
      sfp_fault       => '0',
      sfp_tx_enable   => SFP0_TX_DISABLE,
      sfp_mod_abs     => '0');


  ---------------------------------------------------------------------------
  -- Debug  --
  ---------------------------------------------------------------------------


   -- Use the local pps to generate a LED pulse
led_pps_extend : ENTITY common_lib.common_pulse_extend
                 GENERIC MAP (g_extend_w => 24) -- 135ms on time
                 PORT MAP (clk     => clk_125,
                           rst     => system_reset,
                           p_in    => pps,
                           ep_out  => GPIO_LED_5_LS);

   -- Ethernet Activity
led_act_extend : ENTITY common_lib.common_pulse_extend
                 GENERIC MAP (g_extend_w => 25) -- 215ms on time
                 PORT MAP (clk     => clk_eth_rx,
                           rst     => system_reset,
                           p_in    => eth_in_sosi.tuser(0),
                           ep_out  => GPIO_LED_4_LS);


tx_watch: ila_0
          PORT MAP (clk                   => clk_eth_tx,
                    probe0(63 DOWNTO 0)   => eth_out_sosi.tdata(63 DOWNTO 0),
                    probe0(64)            => eth_out_sosi.tvalid,
                    probe0(72 DOWNTO 65)  => eth_out_sosi.tstrb(7 DOWNTO 0),
                    probe0(80 DOWNTO 73)  => eth_out_sosi.tkeep(7 DOWNTO 0),
                    probe0(81)            => eth_out_sosi.tlast,
                    probe0(82)            => eth_out_sosi.tuser(0),
                    probe0(83)            => eth_out_siso.tready,
                    probe0(299 DOWNTO 84) => gnd(299 DOWNTO 84));

rx_watch: ila_0
          PORT MAP (clk                   => clk_eth_rx,
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
                    probe0(299 DOWNTO 198) => gnd(299 DOWNTO 198));

other_debug: ila_0
             PORT MAP (clk   => clk_eth_rx,
                       probe0(0)   => system_reset,
                       probe0(1)   => system_locked,
                       probe0(2)   => eth_rx_reset,
                       probe0(3)   => eth_tx_reset,
                       probe0(4)   => eth_locked,
                       probe0(52 DOWNTO 5)   => local_mac,
                       probe0(84 DOWNTO 53)   => local_ip,
                       probe0(85)   => SFP0_LOS_LS,
                       probe0(299 DOWNTO 86) => gnd(299 DOWNTO 86));



END str;

