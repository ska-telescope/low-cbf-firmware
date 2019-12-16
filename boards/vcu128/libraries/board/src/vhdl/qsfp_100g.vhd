-------------------------------------------------------------------------------
--
-- File Name: qsfp_100g.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Tuesday Nov 28 11:50:00 2017
-- Template Rev: 1.0
--
-- Title: QSFP Mapping file
--
-- Description: Maps the fixed quads in the 100G MAC to the specified QSFP
--              all arbitrary placed during PCB layout
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

LIBRARY IEEE, common_lib, technology_lib, tech_mac_100g_lib, axi4_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE tech_mac_100g_lib.tech_mac_100g_pkg.ALL;
USE work.vcu128_board_ethernet_qsfp_reg_pkg.ALL;
USE work.board_pkg.ALL;

ENTITY qsfp_100g IS
   GENERIC (
      g_technology            : t_technology;
      g_qsfp                  : t_qsfp;

      g_txpostcursor          : t_slv_5_arr(0 TO 3) := (OTHERS => "00000");   -- No post emphasis
      g_txmaincursor          : t_slv_7_arr(0 TO 3) := (OTHERS => "1010000");
      g_txprecursor           : t_slv_5_arr(0 TO 3) := (OTHERS => "00000");   -- 0.1dB pre emphasis
      g_txdiffctrl            : t_slv_5_arr(0 TO 3) := (OTHERS => "11000");   -- 950mVpp
      g_rxlpmen               : STD_LOGIC_VECTOR(0 TO 3) := (OTHERS => '1')); -- DFE Off
   PORT (
      qsfp_clk_p              : IN STD_LOGIC;
      qsfp_clk_n              : IN STD_LOGIC;
      qsfp_tx_p               : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      qsfp_tx_n               : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      qsfp_rx_p               : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      qsfp_rx_n               : IN STD_LOGIC_VECTOR(3 DOWNTO 0);

      rst_clk                 : IN STD_LOGIC;   -- WARNING - Check drp clock frequency setting in the core when changing anything.
      axi_clk                 : IN STD_LOGIC;

      sys_rst                 : IN STD_LOGIC;
      axi_rst                 : IN STD_LOGIC;

      loopback                : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      tx_disable              : IN STD_LOGIC;
      rx_disable              : IN STD_LOGIC;

      tx_clk_out              : OUT STD_LOGIC;

      -- Status
      link_locked             : OUT STD_LOGIC;

      -- Statistics Interface
      s_axi_mosi              : IN t_axi4_lite_mosi;
      s_axi_miso              : OUT t_axi4_lite_miso;

      -- User Interface Signals
      user_rx_reset           : OUT STD_LOGIC;
      user_tx_reset           : OUT STD_LOGIC;

      -- Recieved data from optics
      data_rx_sosi            : OUT t_lbus_sosi;

      -- Data to be transmitted to optics
      data_tx_sosi            : IN t_lbus_sosi;
      data_tx_siso            : OUT t_lbus_siso);
END qsfp_100g;

ARCHITECTURE rtl OF qsfp_100g IS

  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------

   CONSTANT c_qsfp_rx_remap      : t_integer_arr(0 TO 3) := sel_qsfp_mapping(g_qsfp, false);
   CONSTANT c_qsfp_tx_remap      : t_integer_arr(0 TO 3) := sel_qsfp_mapping(g_qsfp, true);

   CONSTANT c_qsfp_rx_polarity   : STD_LOGIC_VECTOR(0 TO 3) := sel_qsfp_polarity(g_qsfp, false);
   CONSTANT c_qsfp_tx_polarity   : STD_LOGIC_VECTOR(0 TO 3) := sel_qsfp_polarity(g_qsfp, true);

   ---------------------------------------------------------------------------
   -- SIGNAL DECLARATIONS  --
   ---------------------------------------------------------------------------

   SIGNAL gt_rxp_in                 : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL gt_rxn_in                 : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL gt_txp_out                : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL gt_txn_out                : STD_LOGIC_VECTOR(3 DOWNTO 0);


   SIGNAL stat_rx_total_packets     : STD_LOGIC_VECTOR(2 DOWNTO 0);
   SIGNAL stat_rx_bad_fcs           : STD_LOGIC;
   SIGNAL stat_rx_bad_code          : STD_LOGIC_VECTOR(2 DOWNTO 0);

   SIGNAL stat_tx_total_packets     : STD_LOGIC;

   SIGNAL stat_rx_count             : t_slv_16_arr(0 TO 2);
   SIGNAL stat_rx_increment         : t_slv_3_arr(0 TO 2);
   SIGNAL stat_rx_count_zero        : STD_LOGIC_VECTOR(0 TO 2);

   SIGNAL stat_tx_count             : t_slv_16_arr(0 TO 0);
   SIGNAL stat_tx_increment         : t_slv_1_arr(0 TO 0);
   SIGNAL stat_tx_count_zero        : STD_LOGIC_VECTOR(0 TO 0);

   SIGNAL i_tx_clk_out              : STD_LOGIC;
   SIGNAL i_rx_locked               : STD_LOGIC;
   SIGNAL tx_enable                 : STD_LOGIC;
   SIGNAL rx_enable                 : STD_LOGIC;
   SIGNAL i_user_rx_reset           : STD_LOGIC;
   SIGNAL i_sys_rst                 : STD_LOGIC;
   SIGNAL i_user_tx_reset           : STD_LOGIC;
   SIGNAL rx_clk_out                : STD_LOGIC_VECTOR(3 DOWNTO 0);

   SIGNAL m_axi_miso                : t_axi4_lite_miso;
   SIGNAL m_axi_mosi                : t_axi4_lite_mosi;

   SIGNAL statistics_tx_fields_ro      : t_statistics_tx_ro;
   SIGNAL statistics_tx_fields_pr      : t_statistics_tx_pr;
   SIGNAL statistics_rx_fields_ro      : t_statistics_rx_ro;
   SIGNAL statistics_rx_fields_pr      : t_statistics_rx_pr;

   ---------------------------------------------------------------------------
   -- ATTRIBUTES  --
   ---------------------------------------------------------------------------

   ATTRIBUTE DONT_TOUCH                : STRING;
   ATTRIBUTE DONT_TOUCH OF i_sys_rst : SIGNAL IS "true";

   ---------------------------------------------------------------------------
   -- FUNCTIONS DECLARATIONS  --
   ---------------------------------------------------------------------------

   FUNCTION sel_qsfp_quad RETURN t_quad_locations_100g IS
   BEGIN
      IF g_qsfp = QSFP1 THEN
         RETURN QUAD_100G_135;
      ELSIF g_qsfp = QSFP2 THEN
         RETURN QUAD_100G_134;
      ELSIF g_qsfp = QSFP3 THEN
         RETURN QUAD_100G_132;
      ELSIF g_qsfp = QSFP4 THEN
         RETURN QUAD_100G_131;
      ELSE
         RETURN QUAD_100G_135;
      END IF;
   END FUNCTION;
   
BEGIN
   
   
   tx_clk_out <= i_tx_clk_out;
   
   reset_reg: PROCESS(rst_clk)         -- Drives tx_user_reset through LUT, needs to be isolated to meet timing
   BEGIN
      IF RISING_EDGE(rst_clk) THEN
         i_sys_rst <= sys_rst;
   
         user_tx_reset <= i_user_tx_reset;
         user_rx_reset <= i_user_rx_reset;
      END IF;
   END PROCESS;
   
   out_reg: PROCESS(i_tx_clk_out)         -- Register locked signal
   BEGIN
      IF RISING_EDGE(i_tx_clk_out) THEN
         link_locked <= i_rx_locked;
      END IF;
   END PROCESS;
   
   ---------------------------------------------------------------------------
   -- Registers  --
   ---------------------------------------------------------------------------
   
   regs: ENTITY work.vcu128_board_ethernet_qsfp_reg
   GENERIC MAP (
      g_technology   => g_technology)
   PORT MAP (
      mm_clk                  => axi_clk,
      st_clk_statistics_tx(0) => i_tx_clk_out,
      st_clk_statistics_rx(0) => i_tx_clk_out,
      mm_rst                  => axi_rst,
      st_rst_statistics_tx    => "0",
      st_rst_statistics_rx    => "0",
      sla_in                  => s_axi_mosi,
      sla_out                 => s_axi_miso,
      statistics_tx_fields_ro => statistics_tx_fields_ro,
      statistics_tx_fields_pr => statistics_tx_fields_pr,
      statistics_rx_fields_ro => statistics_rx_fields_ro,
      statistics_rx_fields_pr => statistics_rx_fields_pr);


      statistics_rx_fields_ro.total_rx_packets <= stat_rx_count(0);
      statistics_rx_fields_ro.total_rx_crc_error <= stat_rx_count(1);
      statistics_rx_fields_ro.total_rx_bit_error <= stat_rx_count(2);

      statistics_tx_fields_ro.total_tx_packets <= stat_tx_count(0);

      stat_rx_count_zero(0) <= statistics_rx_fields_pr.total_rx_packets;
      stat_rx_count_zero(1) <= statistics_rx_fields_pr.total_rx_crc_error;
      stat_rx_count_zero(2) <= statistics_rx_fields_pr.total_rx_bit_error;

      stat_tx_count_zero(0) <= statistics_tx_fields_pr.total_tx_packets;

---------------------------------------------------------------------------
-- Counters  --
---------------------------------------------------------------------------

   stat_rx_increment(0) <= stat_rx_total_packets;
   stat_rx_increment(1) <= "00" & stat_rx_bad_fcs;
   stat_rx_increment(2) <= stat_rx_bad_code;

   stats_accumulators_rx: FOR i IN 0 TO 2 GENERATE
      u_cnt_acc: ENTITY common_lib.common_accumulate
      GENERIC MAP (
         g_representation  => "UNSIGNED")
      PORT MAP (
         rst      => '0',
         clk      => i_tx_clk_out,
         clken    => '1',
         sload    => stat_rx_count_zero(i),
         in_val   => '1',
         in_dat   => stat_rx_increment(i),
         out_dat  => stat_rx_count(i));
   END GENERATE;

   stat_tx_increment(0)(0) <= stat_tx_total_packets;

   stats_accumulators_tx: FOR i IN 0 TO 0 GENERATE
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
--  Remapping --
---------------------------------------------------------------------------


   io_remap: FOR i IN 0 TO 3 GENERATE

      -- RX Channel
      gt_rxp_in(i)         <= qsfp_rx_p(c_qsfp_rx_remap(i));
      gt_rxn_in(i)         <= qsfp_rx_n(c_qsfp_rx_remap(i));

      -- TX Channel
      qsfp_tx_p(c_qsfp_tx_remap(i))    <= gt_txp_out(i);
      qsfp_tx_n(c_qsfp_tx_remap(i))    <= gt_txn_out(i);
   END GENERATE;

   rx_enable <= NOT rx_disable;
   tx_enable <= NOT tx_disable;

---------------------------------------------------------------------------
--  Module --
---------------------------------------------------------------------------

   u_qsfp: ENTITY tech_mac_100g_lib.tech_mac_100g
   GENERIC MAP (
      g_technology             => g_technology,
      g_device                 => sel_qsfp_quad,
      g_txpostcursor           => remap_attribute_slv5(g_txpostcursor, 0, c_qsfp_tx_remap),
      g_txmaincursor           => remap_attribute_slv7(g_txmaincursor, 0, c_qsfp_tx_remap),
      g_txprecursor            => remap_attribute_slv5(g_txprecursor, 0, c_qsfp_tx_remap),
      g_txdiffctrl             => remap_attribute_slv5(g_txdiffctrl,0,  c_qsfp_tx_remap),
      g_rxlpmen                => remap_attribute_slv(g_rxlpmen, c_qsfp_rx_remap),
      g_txpolarity             => remap_attribute_slv(c_qsfp_tx_polarity, c_qsfp_tx_remap),
      g_rxpolarity             => remap_attribute_slv(c_qsfp_rx_polarity, c_qsfp_rx_remap))
   PORT MAP (
      gt_rxp_in                => gt_rxp_in,
      gt_rxn_in                => gt_rxn_in,
      gt_txp_out               => gt_txp_out,
      gt_txn_out               => gt_txn_out,
      gt_refclk_p              => qsfp_clk_p,
      gt_refclk_n              => qsfp_clk_n,
      sys_reset                => i_sys_rst,
      dclk                     => rst_clk,
      loopback                 => loopback,
      tx_enable                => tx_enable,
      rx_enable                => rx_enable,
      tx_clk_out               => i_tx_clk_out,
      rx_clk_in                => i_tx_clk_out,
      rx_clk_out               => rx_clk_out,
      rx_locked                => i_rx_locked,
      stat_rx_total_bytes      => OPEN,
      stat_rx_total_packets    => stat_rx_total_packets,
      stat_rx_bad_fcs          => stat_rx_bad_fcs,
      stat_rx_bad_code         => stat_rx_bad_code,
      stat_tx_total_bytes      => OPEN,
      stat_tx_total_packets    => stat_tx_total_packets,
      user_rx_reset            => i_user_rx_reset,
      user_tx_reset            => i_user_tx_reset,
      data_rx_sosi             => data_rx_sosi,
      data_tx_sosi             => data_tx_sosi,
      data_tx_siso             => data_tx_siso);



END rtl;