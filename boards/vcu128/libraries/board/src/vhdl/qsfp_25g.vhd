-------------------------------------------------------------------------------
--
-- File Name: qsfp_25g.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Tuesday Nov 28 11:50:00 2017
-- Template Rev: 1.0
--
-- Title: QSFP Mapping file
--
-- Description: Maps the fixed quads in the 25G MAC to the specified QSFP
--              all arbitrary placed during PCB layout. All lane numbers referred
--              to in the IO of the module for generics or signals refer to the
--              optical lanes of the MBO
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

LIBRARY IEEE, common_lib, axi4_lib, technology_lib, tech_mac_25g_quad_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE tech_mac_25g_quad_lib.tech_mac_25g_quad_pkg.ALL;
USE work.vcu128_board_ethernet_quad_qsfp_reg_pkg.ALL;
USE work.board_pkg.ALL;

ENTITY qsfp_25g IS
   GENERIC (
      g_technology         : t_technology;
      g_qsfp               : t_qsfp;

      g_txpostcursor       : t_slv_5_arr(0 TO 3) := (OTHERS => "00000");   -- No post emphasis
      g_txmaincursor       : t_slv_7_arr(0 TO 3) := (OTHERS => "1010000");
      g_txprecursor        : t_slv_5_arr(0 TO 3) := (OTHERS => "00000");   -- 0.1dB pre emphasis
      g_txdiffctrl         : t_slv_5_arr(0 TO 3) := (OTHERS => "11000");   -- 950mVpp
      g_rxlpmen            : STD_LOGIC_VECTOR(0 TO 3) := (OTHERS => '1')); -- DFE Off
   PORT (
      qsfp_clk_p           : IN STD_LOGIC;
      qsfp_clk_n           : IN STD_LOGIC;
      qsfp_tx_p            : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      qsfp_tx_n            : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      qsfp_rx_p            : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      qsfp_rx_n            : IN STD_LOGIC_VECTOR(3 DOWNTO 0);

      sys_rst              : IN STD_LOGIC;
      axi_rst              : IN STD_LOGIC;

      rst_clk              : IN STD_LOGIC;
      axi_clk              : IN STD_LOGIC;

      loopback             : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      tx_disable           : IN STD_LOGIC_VECTOR(0 TO 3);
      rx_disable           : IN STD_LOGIC_VECTOR(0 TO 3);

      tx_clk_out           : OUT STD_LOGIC_VECTOR(0 TO 3);

      -- Status
      link_locked          : OUT STD_LOGIC_VECTOR(0 TO 3);

      -- Statistics Interface
      s_axi_mosi           : IN t_axi4_lite_mosi;
      s_axi_miso           : OUT t_axi4_lite_miso;

      -- User Interface Signals
      user_rx_reset        : OUT STD_LOGIC_VECTOR(0 TO 3);
      user_tx_reset        : OUT STD_LOGIC_VECTOR(0 TO 3);

      -- Recieved data from optics
      data_rx_sosi         : OUT t_axi4_sosi_arr(0 TO 3);
      data_rx_siso         : IN t_axi4_siso_arr(0 TO 3);

      -- Data to be transmitted to optics
      data_tx_sosi         : IN t_axi4_sosi_arr(0 TO 3);
      data_tx_siso         : OUT t_axi4_siso_arr(0 TO 3));
END qsfp_25g;

ARCHITECTURE rtl OF qsfp_25g IS



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

   SIGNAL gt_rxp_in                    : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL gt_rxn_in                    : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL gt_txp_out                   : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL gt_txn_out                   : STD_LOGIC_VECTOR(3 DOWNTO 0);

   SIGNAL i_user_rx_reset              : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL i_user_tx_reset              : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL i_rx_enable                  : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL i_tx_enable                  : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL i_tx_send_idle               : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL i_tx_send_rfi                : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL i_tx_send_lfi                : STD_LOGIC_VECTOR(3 DOWNTO 0);

   SIGNAL i_link_locked                : STD_LOGIC_VECTOR(0 TO 3);
   SIGNAL i_tx_clk_out_map             : STD_LOGIC_VECTOR(0 TO 3);
   SIGNAL i_tx_send_idle_map           : STD_LOGIC_VECTOR(0 TO 3);
   SIGNAL i_tx_send_rfi_map            : STD_LOGIC_VECTOR(0 TO 3);
   SIGNAL i_tx_send_lfi_map            : STD_LOGIC_VECTOR(0 TO 3);
   SIGNAL i_rx_remote_fault_map        : STD_LOGIC_VECTOR(0 TO 3);
   SIGNAL i_rx_locked_map              : STD_LOGIC_VECTOR(0 TO 3);
   SIGNAL i_rx_local_fault_map         : STD_LOGIC_VECTOR(0 TO 3);
   SIGNAL i_rx_receive_local_fault_map : STD_LOGIC_VECTOR(0 TO 3);
   SIGNAL i_sys_rst                    : STD_LOGIC;

   SIGNAL stat_rx_count                : t_slv_16_arr(0 TO 11);
   SIGNAL stat_rx_increment            : t_slv_2_arr(0 TO 11);
   SIGNAL stat_rx_count_zero           : STD_LOGIC_VECTOR(0 TO 11);

   SIGNAL stat_tx_count                : t_slv_16_arr(0 TO 3);
   SIGNAL stat_tx_increment            : t_slv_1_arr(0 TO 3);
   SIGNAL stat_tx_count_zero           : STD_LOGIC_VECTOR(0 TO 3);

   SIGNAL i_tx_clk_out                 : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL i_rx_clk_in                  : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL data_tx_clk                  : STD_LOGIC_VECTOR(0 TO 3);
   SIGNAL data_rx_clk                  : STD_LOGIC_VECTOR(0 TO 3);
   SIGNAL rx_clk_out                   : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL i_loopback                   : t_tech_slv_3_arr(3 DOWNTO 0);

   SIGNAL i_rx_locked                  : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL i_rx_link_status             : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL i_rx_local_fault             : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL i_rx_receive_local_fault     : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL i_rx_remote_fault            : STD_LOGIC_VECTOR(3 DOWNTO 0);


   SIGNAL i_data_rx_sosi               : t_axi4_sosi_arr(3 DOWNTO 0);
   SIGNAL i_data_rx_siso               : t_axi4_siso_arr(3 DOWNTO 0);
   SIGNAL i_data_tx_sosi               : t_axi4_sosi_arr(3 DOWNTO 0);
   SIGNAL i_data_tx_siso               : t_axi4_siso_arr(3 DOWNTO 0);

   SIGNAL stat_rx_total_packets        : t_tech_slv_2_arr(3 DOWNTO 0);
   SIGNAL stat_rx_bad_fcs              : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL stat_rx_bad_code             : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL stat_tx_total_packets        : STD_LOGIC_VECTOR(3 DOWNTO 0);

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


   FUNCTION sel_qsfp_quad RETURN t_quad_locations_25g IS
   BEGIN
      IF g_qsfp = QSFP1 THEN
         RETURN QUAD_25G_135;
      ELSIF g_qsfp = QSFP2 THEN
         RETURN QUAD_25G_134;
      ELSIF g_qsfp = QSFP3 THEN
         RETURN QUAD_25G_132;
      ELSIF g_qsfp = QSFP4 THEN
         RETURN QUAD_25G_131;
      ELSE
         RETURN QUAD_25G_135;
      END IF;
   END FUNCTION;

BEGIN

reset_reg: PROCESS(rst_clk)         -- Drives tx_user_reset through LUT, needs to be isolated to meet timing
   BEGIN
      IF RISING_EDGE(rst_clk) THEN
         i_sys_rst <= sys_rst;

         FOR i IN 0 TO 3 LOOP
            user_tx_reset(c_qsfp_tx_remap(i)) <= i_user_tx_reset(i);
            user_rx_reset(c_qsfp_rx_remap(i)) <= i_user_rx_reset(i);
         END LOOP;
      END IF;
   END PROCESS;

REG_GENERATE: FOR i IN 0 TO 3 GENERATE

   out_reg: PROCESS(data_rx_clk(i))         -- Register locked signal
      BEGIN
         IF RISING_EDGE(data_rx_clk(i)) THEN
            link_locked(i) <= i_link_locked(i);
         END IF;
      END PROCESS;

END GENERATE;

---------------------------------------------------------------------------
-- Registers  --
---------------------------------------------------------------------------

   regs: ENTITY work.vcu128_board_ethernet_quad_qsfp_reg
   GENERIC MAP (
      g_technology   => g_technology)
   PORT MAP (
      mm_clk                  => axi_clk,
      st_clk_statistics_tx    => i_tx_clk_out_map,
      st_clk_statistics_rx    => data_rx_clk,
      mm_rst                  => axi_rst,
      st_rst_statistics_tx    => X"0",
      st_rst_statistics_rx    => X"0",
      sla_in                  => s_axi_mosi,
      sla_out                 => s_axi_miso,
      statistics_tx_fields_ro => statistics_tx_fields_ro,
      statistics_tx_fields_pr => statistics_tx_fields_pr,
      statistics_rx_fields_ro => statistics_rx_fields_ro,
      statistics_rx_fields_pr => statistics_rx_fields_pr);


   lane_assign: FOR i IN 0 TO 3 GENERATE
      statistics_rx_fields_ro.total_rx_packets(i) <= stat_rx_count(3*i+0);
      statistics_rx_fields_ro.total_rx_crc_error(i) <= stat_rx_count(3*i+1);
      statistics_rx_fields_ro.total_rx_bit_error(i) <= stat_rx_count(3*i+2);

      statistics_tx_fields_ro.total_tx_packets(i) <= stat_tx_count(i);

      stat_rx_count_zero(3*i+0) <= statistics_rx_fields_pr.total_rx_packets(i);
      stat_rx_count_zero(3*i+1) <= statistics_rx_fields_pr.total_rx_crc_error(i);
      stat_rx_count_zero(3*i+2) <= statistics_rx_fields_pr.total_rx_bit_error(i);

      stat_tx_count_zero(i) <= statistics_tx_fields_pr.total_tx_packets(i);
   END GENERATE;


---------------------------------------------------------------------------
-- Counters  --
---------------------------------------------------------------------------

   gt_gen_rx: FOR i IN 0 TO 3 GENERATE
      stat_rx_increment(c_qsfp_rx_remap(i)*3+0) <= stat_rx_total_packets(i);
      stat_rx_increment(c_qsfp_rx_remap(i)*3+1) <= "0" & stat_rx_bad_fcs(i);
      stat_rx_increment(c_qsfp_rx_remap(i)*3+2) <= "0" & stat_rx_bad_code(i);

      data_rx_clk(c_qsfp_rx_remap(i)) <= rx_clk_out(i);

      stats_accumulators: FOR j IN 0 TO 2 GENERATE
         u_cnt_acc: ENTITY common_lib.common_accumulate
         GENERIC MAP (
            g_representation  => "UNSIGNED")
         PORT MAP (
            rst      => '0',
            clk      => data_rx_clk(i),
            clken    => '1',
            sload    => stat_rx_count_zero(i*3+j),
            in_val   => '1',
            in_dat   => stat_rx_increment(i*3+j),
            out_dat  => stat_rx_count(i*3+j));
      END GENERATE;
   END GENERATE;

   gt_gen_tx: FOR i IN 0 TO 3 GENERATE
      stat_tx_increment(c_qsfp_tx_remap(i))(0) <= stat_tx_total_packets(i);

      stats_accumulators: FOR j IN 0 TO 0 GENERATE
         u_cnt_acc: ENTITY common_lib.common_accumulate
         GENERIC MAP (
            g_representation  => "UNSIGNED")
         PORT MAP (
            rst      => '0',
            clk      => i_tx_clk_out_map(i),
            clken    => '1',
            sload    => stat_tx_count_zero(i+j),
            in_val   => '1',
            in_dat   => stat_tx_increment(i+j),
            out_dat  => stat_tx_count(i+j));
      END GENERATE;
   END GENERATE;

---------------------------------------------------------------------------
-- Duplex Handling & Remap  --
---------------------------------------------------------------------------

   tx_clk_out <= i_tx_clk_out_map;
   i_link_locked <= i_rx_locked_map AND NOT i_rx_remote_fault_map;

   -- Setup duplex link error handling i.e. both ends go down if they can't sync
   i_tx_send_idle_map <= i_rx_receive_local_fault_map;   -- Send idles if we detect remote error
   i_tx_send_rfi_map <= NOT i_rx_locked_map;             -- Send remote error until we are locked locally
   i_tx_send_lfi_map <= i_rx_local_fault_map;            -- Send local error if something breaks here

   io_remap: FOR i IN 0 TO 3 GENERATE

      -- RX Channel
      gt_rxp_in(i)         <= qsfp_rx_p(c_qsfp_rx_remap(i));
      gt_rxn_in(i)         <= qsfp_rx_n(c_qsfp_rx_remap(i));
      i_rx_enable(i)       <= NOT rx_disable(c_qsfp_rx_remap(i));
      i_data_rx_siso(i)    <= data_rx_siso(c_qsfp_rx_remap(i));
      i_rx_clk_in(i)       <= i_tx_clk_out_map(c_qsfp_rx_remap(i));

      data_rx_sosi(c_qsfp_rx_remap(i))      <= i_data_rx_sosi(i);

      -- TX Channel
      i_tx_enable(i)       <= NOT tx_disable(c_qsfp_tx_remap(i));
      i_data_tx_sosi(i)    <= data_tx_sosi(c_qsfp_tx_remap(i));

      qsfp_tx_p(c_qsfp_tx_remap(i))          <= gt_txp_out(i);
      qsfp_tx_n(c_qsfp_tx_remap(i))          <= gt_txn_out(i);
      i_tx_clk_out_map(c_qsfp_tx_remap(i))   <= i_tx_clk_out(i);
      data_tx_siso(c_qsfp_tx_remap(i))       <= i_data_tx_siso(i);

      -- Remap important error handling signals
      i_rx_locked_map(c_qsfp_rx_remap(i))                <= i_rx_locked(i);
      i_rx_receive_local_fault_map(c_qsfp_rx_remap(i))   <= i_rx_receive_local_fault(i);
      i_rx_local_fault_map(c_qsfp_rx_remap(i))           <= i_rx_local_fault(i);
      i_rx_remote_fault_map(c_qsfp_rx_remap(i))          <= i_rx_remote_fault(i);

      i_tx_send_idle(i)                      <= i_tx_send_idle_map(c_qsfp_tx_remap(i));
      i_tx_send_rfi(i)                       <= i_tx_send_rfi_map(c_qsfp_tx_remap(i));
      i_tx_send_lfi(i)                       <= i_tx_send_lfi_map(c_qsfp_tx_remap(i));
   END GENERATE;

   i_loopback <= (OTHERS => loopback);

---------------------------------------------------------------------------
-- MAC Instatiation  --
---------------------------------------------------------------------------

   u_qsfp: ENTITY tech_mac_25g_quad_lib.tech_mac_25g_quad
   GENERIC MAP (
      g_technology             => g_technology,
      g_device                 => sel_qsfp_quad,
      g_txpostcursor           => remap_attribute_slv5(g_txpostcursor, c_qsfp_tx_remap),
      g_txmaincursor           => remap_attribute_slv7(g_txmaincursor, c_qsfp_tx_remap),
      g_txprecursor            => remap_attribute_slv5(g_txprecursor, c_qsfp_tx_remap),
      g_txdiffctrl             => remap_attribute_slv5(g_txdiffctrl, c_qsfp_tx_remap),
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
      loopback                 => i_loopback,
      tx_enable                => i_tx_enable,
      tx_send_idle             => i_tx_send_idle,
      tx_send_rfi              => i_tx_send_rfi,
      tx_send_lfi              => i_tx_send_lfi,
      rx_enable                => i_rx_enable,
      tx_clk_out               => i_tx_clk_out,
      rx_locked                => i_rx_locked,
      rx_receive_local_fault   => i_rx_receive_local_fault,
      rx_local_fault           => i_rx_local_fault,
      rx_remote_fault          => i_rx_remote_fault,
      rx_clk_in                => i_rx_clk_in,
      rx_clk_out               => rx_clk_out,
      stat_rx_total_bytes      => OPEN,
      stat_rx_total_packets    => stat_rx_total_packets,
      stat_rx_bad_fcs          => stat_rx_bad_fcs,
      stat_rx_bad_code         => stat_rx_bad_code,
      stat_tx_total_bytes      => OPEN,
      stat_tx_total_packets    => stat_tx_total_packets,
      user_rx_reset            => i_user_rx_reset,
      user_tx_reset            => i_user_tx_reset,
      data_rx_sosi             => i_data_rx_sosi,
      data_rx_siso             => i_data_rx_siso,
      data_tx_sosi             => i_data_tx_sosi,
      data_tx_siso             => i_data_tx_siso);

END rtl;