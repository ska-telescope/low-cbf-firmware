-------------------------------------------------------------------------------
--
-- File Name: tb_qsfp_control.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created:
-- Template Rev: 1.0
--
-- Title: QSFP M&C Testbench
--
-- Description: Runs a simple test on the suppoort module for the Gemini LRU
--              QSFP modules
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

LIBRARY IEEE, common_lib, axi4_lib, technology_lib, i2c_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.math_real.ALL;
USE IEEE.std_logic_textio.ALL;
USE STD.textio.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE work.gemini_lru_board_qsfp_reg_pkg.ALL;

ENTITY tb_qsfp_control IS

END tb_qsfp_control;

ARCHITECTURE testbench OF tb_qsfp_control IS

  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------

   CONSTANT c_mm_clk_period         : TIME := 6.4 ns;
   CONSTANT c_reset_len             : INTEGER := 10;

  ---------------------------------------------------------------------------
  -- SIGNAL DECLARATIONS  --
  ---------------------------------------------------------------------------

   SIGNAL axi_clk                   : STD_LOGIC := '0';

   -- DUT Signals
   SIGNAL s_axi_mosi                : t_axi4_lite_mosi;
   SIGNAL s_axi_miso                : t_axi4_lite_miso;

   SIGNAL qsfp_sda                  : STD_LOGIC;
   SIGNAL qsfp_scl                  : STD_LOGIC;
   SIGNAL qsfp_a_mod_prs_n          : std_logic;
   SIGNAL qsfp_a_mod_sel            : std_logic;
   SIGNAL qsfp_a_reset              : std_logic;
   SIGNAL qsfp_b_mod_prs_n          : std_logic;
   SIGNAL qsfp_b_mod_sel            : std_logic;
   SIGNAL qsfp_b_reset              : std_logic;
   SIGNAL qsfp_c_mod_prs_n          : std_logic;
   SIGNAL qsfp_c_mod_sel            : std_logic;
   SIGNAL qsfp_c_reset              : std_logic;
   SIGNAL qsfp_d_mod_prs_n          : std_logic;
   SIGNAL qsfp_d_mod_sel            : std_logic;
   SIGNAL qsfp_d_reset              : std_logic;
   SIGNAL qsfp_int_n                : std_logic;

   SIGNAL qsfp_a_reset_n            : std_logic;
   SIGNAL qsfp_b_reset_n            : std_logic;
   SIGNAL qsfp_c_reset_n            : std_logic;
   SIGNAL qsfp_d_reset_n            : std_logic;

   SIGNAL qsfp_a_mod_sel_n          : std_logic;
   SIGNAL qsfp_b_mod_sel_n          : std_logic;
   SIGNAL qsfp_c_mod_sel_n          : std_logic;
   SIGNAL qsfp_d_mod_sel_n          : std_logic;

   -- Testbench
   SIGNAL reset                     : STD_LOGIC := '1';
   SIGNAL sim_finished              : STD_LOGIC := '0';
   SIGNAL tb_end                    : STD_LOGIC := '0';

BEGIN



---------------------------------------------------------------------------
-- Clocks  --
---------------------------------------------------------------------------

   axi_clk <= NOT axi_clk OR sim_finished  AFTER c_mm_clk_period/2;
   reset <= '1', '0'    AFTER c_mm_clk_period*c_reset_len;

---------------------------------------------------------------------------
-- DUT  --
---------------------------------------------------------------------------

dut: ENTITY work.qsfp_control
     GENERIC MAP (g_clk_rate     => 156250000,
                  g_i2c_rate     => 50000,
                  g_startup_time => 1)
     PORT MAP (clk               => axi_clk,
               rst               => reset,
               s_axi_mosi        => s_axi_mosi,
               s_axi_miso        => s_axi_miso,
               qsfp_a_rx_locked  => X"F",
               qsfp_a_mod_prs_n  => qsfp_a_mod_prs_n,
               qsfp_a_mod_sel    => qsfp_a_mod_sel,
               qsfp_a_reset      => qsfp_a_reset,
               qsfp_b_rx_locked  => X"F",
               qsfp_b_mod_prs_n  => qsfp_b_mod_prs_n,
               qsfp_b_mod_sel    => qsfp_b_mod_sel,
               qsfp_b_reset      => qsfp_b_reset,
               qsfp_c_rx_locked  => X"F",
               qsfp_c_mod_prs_n  => qsfp_c_mod_prs_n,
               qsfp_c_mod_sel    => qsfp_c_mod_sel,
               qsfp_c_reset      => qsfp_c_reset,
               qsfp_d_rx_locked  => X"F",
               qsfp_d_mod_prs_n  => qsfp_d_mod_prs_n,
               qsfp_d_mod_sel    => qsfp_d_mod_sel,
               qsfp_d_reset      => qsfp_d_reset,
               qsfp_int_n        => qsfp_int_n,
               qsfp_sda          => qsfp_sda,
               qsfp_scl          => qsfp_scl);


---------------------------------------------------------------------------
-- Devices  --
---------------------------------------------------------------------------

   qsfp_sda <= 'H';
   qsfp_scl <= 'H';

   qsfp_a_mod_prs_n <= '0';
   qsfp_b_mod_prs_n <= '0';
   qsfp_c_mod_prs_n <= '0';
   qsfp_d_mod_prs_n <= '0';
   qsfp_int_n <= '0';

   -- Inverted in HW
   qsfp_a_reset_n <= not qsfp_a_reset;
   qsfp_b_reset_n <= not qsfp_b_reset;
   qsfp_c_reset_n <= not qsfp_c_reset;
   qsfp_d_reset_n <= not qsfp_d_reset;

   qsfp_a_mod_sel_n <= not qsfp_a_mod_sel;
   qsfp_b_mod_sel_n <= not qsfp_b_mod_sel;
   qsfp_c_mod_sel_n <= not qsfp_c_mod_sel;
   qsfp_d_mod_sel_n <= not qsfp_d_mod_sel;

qsfpA: entity i2c_lib.dev_qsfp
       generic map (dev_name  => string'("A"))
       port map (reset_n      => qsfp_a_reset_n,
                 mod_sel_n    => qsfp_a_mod_sel_n,
                 sda          => qsfp_sda,
                 scl          => qsfp_scl);

qsfpB: entity i2c_lib.dev_qsfp
       generic map (dev_name  => string'("B"))
       port map (reset_n      => qsfp_b_reset_n,
                 mod_sel_n    => qsfp_b_mod_sel_n,
                 sda          => qsfp_sda,
                 scl          => qsfp_scl);

qsfpC: entity i2c_lib.dev_qsfp
       generic map (dev_name  => string'("C"))
       port map (reset_n      => qsfp_c_reset_n,
                 mod_sel_n    => qsfp_c_mod_sel_n,
                 sda          => qsfp_sda,
                 scl          => qsfp_scl);

qsfpD: entity i2c_lib.dev_qsfp
       generic map (dev_name  => string'("D"))
       port map (reset_n      => qsfp_d_reset_n,
                 mod_sel_n    => qsfp_d_mod_sel_n,
                 sda          => qsfp_sda,
                 scl          => qsfp_scl);

---------------------------------------------------------------------------
-- Test Script  --
---------------------------------------------------------------------------

tb_stim: PROCESS

      VARIABLE data_burst  : t_slv_32_arr(0 TO 31);
   BEGIN

      axi_lite_init (reset, axi_clk, s_axi_miso, s_axi_mosi);


      -------------------------------------------
      --                Test 1                 --
      -------------------------------------------
      -- Set QSFP C to lane 2 to disabled
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_qsfp_control_tx_disable_address_3, true, X"00000400");

      -------------------------------------------
      --                Test 2                 --
      -------------------------------------------
      -- Let the monitor cycle complete
      -- Verify a subset of the downloaded data

      WAIT FOR 49 ms;

      -- Check saved data
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_qsfp_voltage_address_0, false, X"0000814c", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_qsfp_tx_bias1_address_0, false, X"000061a8", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_qsfp_rx_power1_address_0, false, X"00003578", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_qsfp_temperature_address_0, false, X"0000189e", validate => true);

      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_qsfp_voltage_address_1, false, X"0000814c", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_qsfp_tx_bias2_address_1, false, X"00005266", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_qsfp_rx_power3_address_1, false, X"0000abde", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_qsfp_temperature_address_1, false, X"0000189e", validate => true);

      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_qsfp_voltage_address_2, false, X"0000814c", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_qsfp_tx_bias3_address_2, false, X"000089e2", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_qsfp_rx_power0_address_2, false, X"00001122", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_qsfp_temperature_address_2, false, X"0000189e", validate => true);

      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_qsfp_voltage_address_3, false, X"0000814c", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_qsfp_tx_bias0_address_3, false, X"0000f446", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_qsfp_rx_power2_address_3, false, X"00002780", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_qsfp_temperature_address_3, false, X"0000189e", validate => true);


      -------------------------------------------
      --                Test 3                 --
      -------------------------------------------
      -- Upload a custom program to write a byte to a register and downlaod a word
      -- Verify the downloaded data

      -- Test Program mode
      data_burst(0) := X"00000006";    -- Write Byte OP
      data_burst(1) := X"00000050";    -- QSFP
      data_burst(2) := X"00000057";    -- Register Address
      data_burst(3) := X"000000aa";    -- Data
      data_burst(4) := X"00000009";    -- Read word OP
      data_burst(5) := X"00000050";    -- QSFP
      data_burst(6) := X"00000059";    -- Register Address
      data_burst(7) := X"00000013";    -- End

      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_control_program_address, true, data_burst(0 TO 7)); -- Write Program

      -- Run on QSFPs B and D
      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_control_control_prog_select_address, true, X"0000000a");

      -- Queue program
      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_control_control_prog_execute_address, true, X"00000001");

      -- Wait for completion
      axi_lite_wait (axi_clk, s_axi_miso, s_axi_mosi, c_control_status_prog_finished_address, X"00000001");

      -- Verify Data
      data_burst(0) := X"000000aa";    -- MSB first
      data_burst(1) := X"000000bb";    -- LSB
      data_burst(2) := X"000000aa";
      data_burst(3) := X"000000bb";

      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_control_results_address, false, data_burst(0 TO 3), validate => true); -- Check results


      sim_finished <= '1';
      tb_end <= '1';
      WAIT FOR 1 us;
      REPORT "Finished Simulation" SEVERITY FAILURE;
      WAIT;
   END PROCESS;






END testbench;