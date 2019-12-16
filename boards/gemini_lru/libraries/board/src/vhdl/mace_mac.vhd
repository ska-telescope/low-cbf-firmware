-------------------------------------------------------------------------------
--
-- File Name: mace_mac.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Thurs Oct 19 16:40:00 2017
-- Template Rev: 1.0
--
-- Title: M&C support for MBO Parts
--
-- Description: Provides the register level interface for the MBO components
--              for monitoring and manual adjustment of registers if required.
--              Also provides a mechanism for programming the MBOs with parameters
--              at startup
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

LIBRARY IEEE, common_lib, i2c_lib, axi4_lib, technology_lib, tech_mac_10g_lib, tech_axi4_infrastructure_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE work.gemini_lru_board_ethernet_mace_reg_pkg.ALL;
USE tech_mac_10g_lib.tech_mac_10g_pkg.ALL;

ENTITY mace_mac IS
   GENERIC (
      g_technology         : t_technology);
   PORT (
      sfp_rx_p             : IN STD_LOGIC;
      sfp_rx_n             : IN STD_LOGIC;
      sfp_tx_p             : OUT STD_LOGIC;
      sfp_tx_n             : OUT STD_LOGIC;

      sfp_clk_c_p          : IN STD_LOGIC;
      sfp_clk_c_n          : IN STD_LOGIC;

      system_reset         : IN STD_LOGIC;
      rst_clk              : IN STD_LOGIC;
      tx_clk               : OUT STD_LOGIC;                 -- Also drives RX FIFO
      rx_clk               : OUT STD_LOGIC;
      axi_clk              : IN STD_LOGIC;

      -- User Interface Signals
      eth_in_sosi          : OUT t_axi4_sosi;
      eth_in_siso          : IN t_axi4_siso;

      eth_out_sosi         : IN t_axi4_sosi;
      eth_out_siso         : OUT t_axi4_siso;

      eth_rx_reset         : OUT STD_LOGIC;
      eth_tx_reset         : OUT STD_LOGIC;

      eth_locked           : OUT STD_LOGIC;

      -- Statistics Interface
      s_axi_mosi           : IN t_axi4_lite_mosi;
      s_axi_miso           : OUT t_axi4_lite_miso;

      -- Pause
      local_mac            : IN STD_LOGIC_VECTOR(47 DOWNTO 0);             -- Needed in case PAUSE packets are unicast
      ctl_rx_pause_ack     : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
      ctl_rx_pause_enable  : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
      stat_rx_pause_req    : OUT STD_LOGIC_VECTOR(8 DOWNTO 0));
END mace_mac;

ARCHITECTURE rtl OF mace_mac IS


  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------



  ---------------------------------------------------------------------------
  -- SIGNAL DECLARATIONS  --
  ---------------------------------------------------------------------------

   SIGNAL stat_rx_total_bytes       : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL stat_rx_total_packets     : STD_LOGIC_VECTOR(1 DOWNTO 0);
   SIGNAL stat_rx_bad_fcs           : STD_LOGIC_VECTOR(1 DOWNTO 0);
   SIGNAL stat_rx_user_pause        : STD_LOGIC;
   SIGNAL stat_rx_vlan              : STD_LOGIC;
   SIGNAL stat_rx_oversize          : STD_LOGIC;
   SIGNAL stat_rx_packet_small      : STD_LOGIC;

   SIGNAL stat_tx_total_bytes       : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL stat_tx_total_packets     : STD_LOGIC;
   SIGNAL stat_tx_packet_small      : STD_LOGIC;
   SIGNAL stat_tx_packet_large      : STD_LOGIC;

   SIGNAL stat_rx_count             : t_slv_16_arr(0 TO 6);
   SIGNAL stat_rx_increment         : t_slv_4_arr(0 TO 6);
   SIGNAL stat_rx_count_zero        : STD_LOGIC_VECTOR(0 TO 6);

   SIGNAL stat_tx_count             : t_slv_16_arr(0 TO 3);
   SIGNAL stat_tx_increment         : t_slv_4_arr(0 TO 3);
   SIGNAL stat_tx_count_zero        : STD_LOGIC_VECTOR(0 TO 3);

   SIGNAL rx_clk_out                : STD_LOGIC;
   SIGNAL i_eth_locked              : STD_LOGIC;
   SIGNAL i_eth_rx_reset            : STD_LOGIC;
   SIGNAL i_eth_tx_reset            : STD_LOGIC;
   SIGNAL i_tx_clk_out              : STD_LOGIC;

   SIGNAL statistics_tx_fields_ro   : t_statistics_tx_ro;
   SIGNAL statistics_tx_fields_pr   : t_statistics_tx_pr;
   SIGNAL statistics_rx_fields_ro   : t_statistics_rx_ro;
   SIGNAL statistics_rx_fields_pr   : t_statistics_rx_pr;
BEGIN

   rx_clk <= rx_clk_out;
   eth_rx_reset <= i_eth_rx_reset;
   eth_tx_reset <= i_eth_tx_reset;

   tx_clk <= i_tx_clk_out;

---------------------------------------------------------------------------
-- Registers  --
---------------------------------------------------------------------------

   regs: ENTITY work.gemini_lru_board_ethernet_mace_reg
   GENERIC MAP (
      g_technology            => g_technology)
   PORT MAP (
      mm_clk                  => axi_clk,
      st_clk_statistics_tx(0) => i_tx_clk_out,
      st_clk_statistics_rx(0) => rx_clk_out,
      mm_rst                  => i_eth_tx_reset,
      st_rst_statistics_tx    => "0",
      st_rst_statistics_rx    => "0",
      sla_in                  => s_axi_mosi,
      sla_out                 => s_axi_miso,
      statistics_tx_fields_ro => statistics_tx_fields_ro,
      statistics_tx_fields_pr => statistics_tx_fields_pr,
      statistics_rx_fields_ro => statistics_rx_fields_ro,
      statistics_rx_fields_pr => statistics_rx_fields_pr);

   statistics_rx_fields_ro.total_rx_bytes <= stat_rx_count(0);
   statistics_rx_fields_ro.total_rx_packets <= stat_rx_count(1);
   statistics_rx_fields_ro.total_rx_crc_error <= stat_rx_count(2);
   statistics_rx_fields_ro.total_rx_pause_packets <= stat_rx_count(3);
   statistics_rx_fields_ro.total_rx_vlan_packets <= stat_rx_count(4);
   statistics_rx_fields_ro.total_rx_oversized_packets <= stat_rx_count(5);
   statistics_rx_fields_ro.total_rx_runt_packets <= stat_rx_count(6);

   statistics_tx_fields_ro.total_tx_bytes <= stat_tx_count(0);
   statistics_tx_fields_ro.total_tx_packets <= stat_tx_count(1);
   statistics_tx_fields_ro.total_tx_runt_packets <= stat_tx_count(2);
   statistics_tx_fields_ro.total_tx_oversized_packets <= stat_tx_count(3);


   stat_rx_count_zero(0) <= statistics_rx_fields_pr.total_rx_bytes;
   stat_rx_count_zero(1) <= statistics_rx_fields_pr.total_rx_packets;
   stat_rx_count_zero(2) <= statistics_rx_fields_pr.total_rx_crc_error;
   stat_rx_count_zero(3) <= statistics_rx_fields_pr.total_rx_pause_packets;
   stat_rx_count_zero(4) <= statistics_rx_fields_pr.total_rx_vlan_packets;
   stat_rx_count_zero(5) <= statistics_rx_fields_pr.total_rx_oversized_packets;
   stat_rx_count_zero(6) <= statistics_rx_fields_pr.total_rx_runt_packets;

   stat_tx_count_zero(0) <= statistics_tx_fields_pr.total_tx_bytes;
   stat_tx_count_zero(1) <= statistics_tx_fields_pr.total_tx_packets;
   stat_tx_count_zero(2) <= statistics_tx_fields_pr.total_tx_runt_packets;
   stat_tx_count_zero(3) <= statistics_tx_fields_pr.total_tx_oversized_packets;

---------------------------------------------------------------------------
-- Counters  --
---------------------------------------------------------------------------


   stat_rx_increment(0) <= stat_rx_total_bytes;
   stat_rx_increment(1) <= "00" & stat_rx_total_packets;
   stat_rx_increment(2) <= "00" & stat_rx_bad_fcs;
   stat_rx_increment(3) <= "000" & stat_rx_user_pause;
   stat_rx_increment(4) <= "000" & stat_rx_vlan;
   stat_rx_increment(5) <= "000" & stat_rx_oversize;
   stat_rx_increment(6) <= "000" & stat_rx_packet_small;


   stats_rx_accumulators: FOR i IN 0 TO 6 GENERATE
      u_cnt_acc: ENTITY common_lib.common_accumulate
      GENERIC MAP (
         g_representation  => "UNSIGNED")
      PORT MAP (
         rst      => '0',
         clk      => rx_clk_out,
         clken    => '1',
         sload    => stat_rx_count_zero(i),
         in_val   => '1',
         in_dat   => stat_rx_increment(i),
         out_dat  => stat_rx_count(i));
   END GENERATE;

   stat_tx_increment(0) <= stat_tx_total_bytes;
   stat_tx_increment(1) <= "000" & stat_tx_total_packets;
   stat_tx_increment(2) <= "000" & stat_tx_packet_small;
   stat_tx_increment(3) <= "000" & stat_tx_packet_large;

   stats_tx_accumulators: FOR i IN 0 TO 3 GENERATE
      u_cnt_acc: ENTITY common_lib.common_accumulate
      GENERIC MAP (
         g_representation  => "UNSIGNED")
      PORT MAP (
         rst      => '0',
         clk      => i_tx_clk_out,
         clken    => '1',
         sload    => stat_tx_count_zero(i),
         in_val   => '1',
         in_dat   => stat_tx_increment(i),
         out_dat  => stat_tx_count(i));
   END GENERATE;


---------------------------------------------------------------------------
--  Retime --
---------------------------------------------------------------------------

lock_resync: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         eth_locked <= i_eth_locked;
      END IF;
   END PROCESS;

---------------------------------------------------------------------------
-- MAC Module  --
---------------------------------------------------------------------------

   u_mace_mac: ENTITY tech_mac_10g_lib.tech_mac_10g
   GENERIC MAP (
      g_technology            => g_technology,
      g_device                => SINGLE_10G_120_3,
      g_txpolarity            => '1',
      g_rxpolarity            => '1',
      g_rxlpmen               => '1',                -- DFE Off
      g_error_passing         => TRUE)
   PORT MAP (
      gt_rxp_in               => sfp_rx_p,
      gt_rxn_in               => sfp_rx_n,
      gt_txp_out              => sfp_tx_p,
      gt_txn_out              => sfp_tx_n,
      gt_refclk_p             => sfp_clk_c_p,
      gt_refclk_n             => sfp_clk_c_n,
      sys_reset               => system_reset,
      dclk                    => rst_clk,
      tx_clk_out              => i_tx_clk_out,
      rx_clk_in               => axi_clk,
      rx_clk_out              => rx_clk_out,
      user_rx_reset           => i_eth_rx_reset,
      eth_in_sosi             => eth_in_sosi,
      eth_in_siso             => eth_in_siso,
      eth_out_sosi            => eth_out_sosi,
      eth_out_siso            => eth_out_siso,
      eth_locked              => i_eth_locked,
      user_tx_reset           => i_eth_tx_reset,
      local_mac               => local_mac,
      stat_rx_total_bytes     => stat_rx_total_bytes,
      stat_rx_total_packets   => stat_rx_total_packets,
      stat_rx_bad_fcs         => stat_rx_bad_fcs,
      stat_rx_user_pause      => stat_rx_user_pause,
      stat_rx_vlan            => stat_rx_vlan,
      stat_rx_oversize        => stat_rx_oversize,
      stat_rx_packet_small    => stat_rx_packet_small,
      stat_tx_total_bytes     => stat_tx_total_bytes,
      stat_tx_total_packets   => stat_tx_total_packets,
      stat_tx_packet_small    => stat_tx_packet_small,
      stat_tx_packet_large    => stat_tx_packet_large,
      ctl_rx_pause_ack        => ctl_rx_pause_ack,
      ctl_rx_pause_enable     => ctl_rx_pause_enable,
      stat_rx_pause_req       => stat_rx_pause_req,
      dbg_loopback            => "000");

END rtl;