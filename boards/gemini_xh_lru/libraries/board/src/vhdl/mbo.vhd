-------------------------------------------------------------------------------
--
-- File Name: mbo_a.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Wed June 13 10:50:00 2017
-- Template Rev: 1.0
--
-- Title: MBO Mapping file
--
-- Description: Maps the fixed quads in the 25G MAC to the MBO lanes which are
--              all arbitrary placed during PCB layout. All lane numbers reffered
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
USE work.gemini_xh_lru_board_ethernet_mbo_reg_pkg.ALL;
USE work.board_pkg.ALL;

ENTITY mbo IS
   GENERIC (
      g_technology         : t_technology;
      g_mbo                : t_mbo;

      g_txpostcursor       : t_slv_5_arr(0 TO 11) := (OTHERS => "00000");   -- No post emphasis
      g_txmaincursor       : t_slv_7_arr(0 TO 11) := (OTHERS => "0101000");
      g_txprecursor        : t_slv_5_arr(0 TO 11) := (OTHERS => "00000");   -- No pre emphasis
      g_txdiffctrl         : t_slv_5_arr(0 TO 11) := (OTHERS => "10110");   -- 809mVpp
      g_rxlpmen            : STD_LOGIC_VECTOR(0 TO 11) := (OTHERS => '1')); -- DFE off
   PORT (
      mbo_clk_p            : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      mbo_clk_n            : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      mbo_tx_p             : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
      mbo_tx_n             : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
      mbo_rx_p             : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
      mbo_rx_n             : IN STD_LOGIC_VECTOR(11 DOWNTO 0);

      sys_rst              : IN STD_LOGIC;
      axi_rst              : IN STD_LOGIC;

      rst_clk              : IN STD_LOGIC;
      axi_clk              : IN STD_LOGIC;

      loopback             : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      tx_disable           : IN STD_LOGIC_VECTOR(0 TO 11);
      rx_disable           : IN STD_LOGIC_VECTOR(0 TO 11);

      tx_clk_out           : OUT STD_LOGIC_VECTOR(0 TO 11);

      -- Statistics Interface
      s_axi_mosi           : IN t_axi4_lite_mosi;
      s_axi_miso           : OUT t_axi4_lite_miso;

      -- Status
      link_locked          : OUT STD_LOGIC_VECTOR(0 TO 11);

      -- User Interface Signals
      user_rx_reset        : OUT STD_LOGIC_VECTOR(0 TO 11);
      user_tx_reset        : OUT STD_LOGIC_VECTOR(0 TO 11);

      -- Recieved data from optics
      data_rx_sosi         : OUT t_axi4_sosi_arr(0 TO 11);
      data_rx_siso         : IN t_axi4_siso_arr(0 TO 11);

      -- Data to be transmitted to optics
      data_tx_sosi         : IN t_axi4_sosi_arr(0 TO 11);
      data_tx_siso         : OUT t_axi4_siso_arr(0 TO 11));
END mbo;

ARCHITECTURE rtl OF mbo IS

   ---------------------------------------------------------------------------
   -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
   ---------------------------------------------------------------------------

   CONSTANT c_mbo_rx_remap      : t_integer_arr(0 TO 11) := sel_mbo_mapping(g_mbo, false);
   CONSTANT c_mbo_tx_remap      : t_integer_arr(0 TO 11) := sel_mbo_mapping(g_mbo, true);

   CONSTANT c_mbo_rx_polarity   : STD_LOGIC_VECTOR(0 TO 11) := sel_mbo_polarity(g_mbo, false);
   CONSTANT c_mbo_tx_polarity   : STD_LOGIC_VECTOR(0 TO 11) := sel_mbo_polarity(g_mbo, true);

   ---------------------------------------------------------------------------
   -- SIGNAL DECLARATIONS  --
   ---------------------------------------------------------------------------

   SIGNAL gt_rxp_in                    : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL gt_rxn_in                    : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL gt_txp_out                   : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL gt_txn_out                   : STD_LOGIC_VECTOR(11 DOWNTO 0);

   SIGNAL i_user_rx_reset              : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL i_user_tx_reset              : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL i_rx_enable                  : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL i_tx_enable                  : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL i_tx_send_idle               : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL i_tx_send_rfi                : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL i_tx_send_lfi                : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL i_loopback                   : t_tech_slv_3_arr(3 DOWNTO 0);
   SIGNAL i_tx_clk_out                 : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL i_rx_clk_in                  : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL rx_clk_out                   : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL i_rx_locked                  : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL i_rx_receive_local_fault     : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL i_rx_local_fault             : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL i_rx_remote_fault            : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL i_sys_rst                    : STD_LOGIC_VECTOR(0 TO 2);

   SIGNAL i_link_locked                : STD_LOGIC_VECTOR(0 TO 11);
   SIGNAL i_tx_clk_out_map             : STD_LOGIC_VECTOR(0 TO 11);
   SIGNAL i_tx_send_idle_map           : STD_LOGIC_VECTOR(0 TO 11);
   SIGNAL i_tx_send_rfi_map            : STD_LOGIC_VECTOR(0 TO 11);
   SIGNAL i_tx_send_lfi_map            : STD_LOGIC_VECTOR(0 TO 11);
   SIGNAL i_rx_remote_fault_map        : STD_LOGIC_VECTOR(0 TO 11);
   SIGNAL i_rx_locked_map              : STD_LOGIC_VECTOR(0 TO 11);
   SIGNAL i_rx_local_fault_map         : STD_LOGIC_VECTOR(0 TO 11);
   SIGNAL i_rx_receive_local_fault_map : STD_LOGIC_VECTOR(0 TO 11);
   SIGNAL data_rx_clk                  : STD_LOGIC_VECTOR(0 TO 11);

   SIGNAL i_data_rx_sosi               : t_axi4_sosi_arr(11 DOWNTO 0);
   SIGNAL i_data_rx_siso               : t_axi4_siso_arr(11 DOWNTO 0);
   SIGNAL i_data_tx_sosi               : t_axi4_sosi_arr(11 DOWNTO 0);
   SIGNAL i_data_tx_siso               : t_axi4_siso_arr(11 DOWNTO 0);

   SIGNAL stat_rx_total_packets        : t_tech_slv_2_arr(11 DOWNTO 0);
   SIGNAL stat_rx_bad_fcs              : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL stat_rx_bad_code             : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL stat_tx_total_packets        : STD_LOGIC_VECTOR(11 DOWNTO 0);

   SIGNAL stat_rx_count                : t_slv_16_arr(0 TO 35);
   SIGNAL stat_rx_increment            : t_slv_2_arr(0 TO 35);
   SIGNAL stat_rx_count_zero           : STD_LOGIC_VECTOR(0 TO 35);

   SIGNAL stat_tx_count                : t_slv_16_arr(0 TO 11);
   SIGNAL stat_tx_increment            : t_slv_1_arr(0 TO 11);
   SIGNAL stat_tx_count_zero           : STD_LOGIC_VECTOR(0 TO 11);

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


   FUNCTION sel_mbo_quad (idx : INTEGER) RETURN t_quad_locations_25g IS
   BEGIN
      IF g_mbo = MBO_A THEN
         IF idx = 0 THEN
            RETURN QUAD_25G_232;
         ELSIF idx = 1 THEN
            RETURN QUAD_25G_233;
         ELSE
            RETURN QUAD_25G_234;
         END IF;
      ELSIF g_mbo = MBO_B THEN
         IF idx = 0 THEN
            RETURN QUAD_25G_228;
         ELSIF idx = 1 THEN
            RETURN QUAD_25G_229;
         ELSE
            RETURN QUAD_25G_230;
         END IF;
      ELSE
         IF idx = 0 THEN
            RETURN QUAD_25G_224;
         ELSIF idx = 1 THEN
            RETURN QUAD_25G_225;
         ELSE
            RETURN QUAD_25G_226;
         END IF;
      END IF;
   END FUNCTION;

BEGIN

resets_reg: PROCESS(rst_clk)         -- Drives tx_user_reset through LUT, needs to be isolated to meet timing
   BEGIN
      IF RISING_EDGE(rst_clk) THEN
         FOR i IN 0 TO 2 LOOP
            i_sys_rst(i) <= sys_rst;
         END LOOP;

         FOR i IN 0 TO 11 LOOP
            user_tx_reset(c_mbo_tx_remap(i)) <= i_user_tx_reset(i);
            user_rx_reset(c_mbo_rx_remap(i)) <= i_user_rx_reset(i);
         END LOOP;
      END IF;
   END PROCESS;

REG_GENERATE: FOR i IN 0 TO 11 GENERATE

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

   regs: ENTITY work.gemini_xh_lru_board_ethernet_mbo_reg
   GENERIC MAP (
      g_technology            => g_technology)
   PORT MAP (
      mm_clk                  => axi_clk,
      st_clk_statistics_tx    => i_tx_clk_out_map,
      st_clk_statistics_rx    => data_rx_clk,
      mm_rst                  => axi_rst,
      st_rst_statistics_tx    => X"000",
      st_rst_statistics_rx    => X"000",
      sla_in                  => s_axi_mosi,
      sla_out                 => s_axi_miso,
      statistics_tx_fields_ro => statistics_tx_fields_ro,
      statistics_tx_fields_pr => statistics_tx_fields_pr,
      statistics_rx_fields_ro => statistics_rx_fields_ro,
      statistics_rx_fields_pr => statistics_rx_fields_pr);


   lane_assign: FOR i IN 0 TO 11 GENERATE
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

   gt_gen_rx: FOR i IN 0 TO 11 GENERATE
      stat_rx_increment(c_mbo_rx_remap(i)*3+0) <= stat_rx_total_packets(i);
      stat_rx_increment(c_mbo_rx_remap(i)*3+1) <= "0" & stat_rx_bad_fcs(i);
      stat_rx_increment(c_mbo_rx_remap(i)*3+2) <= "0" & stat_rx_bad_code(i);

      data_rx_clk(c_mbo_rx_remap(i)) <= rx_clk_out(i);

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

   gt_gen_tx: FOR i IN 0 TO 11 GENERATE
      stat_tx_increment(c_mbo_tx_remap(i))(0) <= stat_tx_total_packets(i);

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

   i_loopback <= (OTHERS => loopback);

   io_remap: FOR i IN 0 TO 11 GENERATE

      -- RX Channel
      gt_rxp_in(i)         <= mbo_rx_p(c_mbo_rx_remap(i));
      gt_rxn_in(i)         <= mbo_rx_n(c_mbo_rx_remap(i));
      i_rx_enable(i)       <= NOT rx_disable(c_mbo_rx_remap(i));
      i_data_rx_siso(i)    <= data_rx_siso(c_mbo_rx_remap(i));
      i_rx_clk_in(i)       <= i_tx_clk_out_map(c_mbo_rx_remap(i));

      data_rx_sosi(c_mbo_rx_remap(i))      <= i_data_rx_sosi(i);

      -- TX Channel
      i_tx_enable(i)       <= NOT tx_disable(c_mbo_tx_remap(i));
      i_data_tx_sosi(i)    <= data_tx_sosi(c_mbo_tx_remap(i));

      mbo_tx_p(c_mbo_tx_remap(i))          <= gt_txp_out(i);
      mbo_tx_n(c_mbo_tx_remap(i))          <= gt_txn_out(i);
      i_tx_clk_out_map(c_mbo_tx_remap(i))  <= i_tx_clk_out(i);
      data_tx_siso(c_mbo_tx_remap(i))      <= i_data_tx_siso(i);


      -- Remap important error handling signals
      i_rx_locked_map(c_mbo_rx_remap(i))                <= i_rx_locked(i);
      i_rx_receive_local_fault_map(c_mbo_rx_remap(i))   <= i_rx_receive_local_fault(i);
      i_rx_local_fault_map(c_mbo_rx_remap(i))           <= i_rx_local_fault(i);
      i_rx_remote_fault_map(c_mbo_rx_remap(i))          <= i_rx_remote_fault(i);

      i_tx_send_idle(i)                   <= i_tx_send_idle_map(c_mbo_tx_remap(i));
      i_tx_send_rfi(i)                    <= i_tx_send_rfi_map(c_mbo_tx_remap(i));
      i_tx_send_lfi(i)                    <= i_tx_send_lfi_map(c_mbo_tx_remap(i));
   END GENERATE;

---------------------------------------------------------------------------
-- MAC Instatiation  --
---------------------------------------------------------------------------

   quads_gen: FOR i IN 0 TO 2 GENERATE
      u_quad: ENTITY tech_mac_25g_quad_lib.tech_mac_25g_quad
      GENERIC MAP (
         g_technology             => g_technology,
         g_device                 => sel_mbo_quad(i),
         g_txpostcursor           => remap_attribute_slv5(g_txpostcursor, i, c_mbo_tx_remap),
         g_txmaincursor           => remap_attribute_slv7(g_txmaincursor, i, c_mbo_tx_remap),
         g_txprecursor            => remap_attribute_slv5(g_txprecursor, i, c_mbo_tx_remap),
         g_txdiffctrl             => remap_attribute_slv5(g_txdiffctrl, i, c_mbo_tx_remap),
         g_txpolarity             => remap_attribute_slv(c_mbo_tx_polarity, i, c_mbo_tx_remap),
         g_rxpolarity             => remap_attribute_slv(c_mbo_rx_polarity, i, c_mbo_rx_remap),
         g_rxlpmen                => remap_attribute_slv(g_rxlpmen, i, c_mbo_rx_remap))
      PORT MAP (
         gt_rxp_in                => gt_rxp_in(4*(i+1)-1 DOWNTO 4*i),
         gt_rxn_in                => gt_rxn_in(4*(i+1)-1 DOWNTO 4*i),
         gt_txp_out               => gt_txp_out(4*(i+1)-1 DOWNTO 4*i),
         gt_txn_out               => gt_txn_out(4*(i+1)-1 DOWNTO 4*i),
         gt_refclk_p              => mbo_clk_p(i),
         gt_refclk_n              => mbo_clk_n(i),
         sys_reset                => i_sys_rst(i),
         dclk                     => rst_clk,
         loopback                 => i_loopback,
         tx_enable                => i_tx_enable(4*(i+1)-1 DOWNTO 4*i),
         tx_send_idle             => i_tx_send_idle(4*(i+1)-1 DOWNTO 4*i),
         tx_send_rfi              => i_tx_send_rfi(4*(i+1)-1 DOWNTO 4*i),
         tx_send_lfi              => i_tx_send_lfi(4*(i+1)-1 DOWNTO 4*i),
         rx_enable                => i_rx_enable(4*(i+1)-1 DOWNTO 4*i),
         tx_clk_out               => i_tx_clk_out(4*(i+1)-1 DOWNTO 4*i),
         rx_locked                => i_rx_locked(4*(i+1)-1 DOWNTO 4*i),
         rx_receive_local_fault   => i_rx_receive_local_fault(4*(i+1)-1 DOWNTO 4*i),
         rx_local_fault           => i_rx_local_fault(4*(i+1)-1 DOWNTO 4*i),
         rx_remote_fault          => i_rx_remote_fault(4*(i+1)-1 DOWNTO 4*i),
         rx_clk_in                => i_rx_clk_in(4*(i+1)-1 DOWNTO 4*i),
         rx_clk_out               => rx_clk_out(4*(i+1)-1 DOWNTO 4*i),
         stat_rx_total_bytes      => OPEN,
         stat_rx_total_packets    => stat_rx_total_packets(4*(i+1)-1 DOWNTO 4*i),
         stat_rx_bad_fcs          => stat_rx_bad_fcs(4*(i+1)-1 DOWNTO 4*i),
         stat_rx_bad_code         => stat_rx_bad_code(4*(i+1)-1 DOWNTO 4*i),
         stat_tx_total_bytes      => OPEN,
         stat_tx_total_packets    => stat_tx_total_packets(4*(i+1)-1 DOWNTO 4*i),
         user_rx_reset            => i_user_rx_reset(4*(i+1)-1 DOWNTO 4*i),
         user_tx_reset            => i_user_tx_reset(4*(i+1)-1 DOWNTO 4*i),
         data_rx_sosi             => i_data_rx_sosi(4*(i+1)-1 DOWNTO 4*i),
         data_rx_siso             => i_data_rx_siso(4*(i+1)-1 DOWNTO 4*i),
         data_tx_sosi             => i_data_tx_sosi(4*(i+1)-1 DOWNTO 4*i),
         data_tx_siso             => i_data_tx_siso(4*(i+1)-1 DOWNTO 4*i));
   END GENERATE;


END rtl;