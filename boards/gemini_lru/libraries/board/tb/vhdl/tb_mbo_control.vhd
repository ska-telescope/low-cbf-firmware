-------------------------------------------------------------------------------
--
-- File Name: tb_mbo_control.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created:
-- Template Rev: 1.0
--
-- Title: MBO M&C Testbench
--
-- Description: Runs a simple test on the suppoort module for the Gemini LRU
--              MBO modules
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
USE work.gemini_lru_board_mbo_reg_pkg.ALL;

ENTITY tb_mbo_control IS

END tb_mbo_control;

ARCHITECTURE testbench OF tb_mbo_control IS

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

   SIGNAL mbo_a_reset               : STD_LOGIC;
   SIGNAL mbo_b_reset               : STD_LOGIC;
   SIGNAL mbo_c_reset               : STD_LOGIC;
   SIGNAL mbo_int_n                 : STD_LOGIC;
   SIGNAL mbo_sda                   : STD_LOGIC;
   SIGNAL mbo_scl                   : STD_LOGIC;

   SIGNAL mbo_a_reset_n             : STD_LOGIC;
   SIGNAL mbo_b_reset_n             : STD_LOGIC;
   SIGNAL mbo_c_reset_n             : STD_LOGIC;


   -- Testbench
   SIGNAL reset                     : STD_LOGIC;
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

dut: ENTITY work.mbo_control
     GENERIC MAP (g_clk_rate     => 156250000,
                  g_startup_time => 1)
     PORT MAP (clk               => axi_clk,
               rst               => reset,
               s_axi_mosi        => s_axi_mosi,
               s_axi_miso        => s_axi_miso,
               mbo_a_reset       => mbo_a_reset,
               mbo_b_reset       => mbo_b_reset,
               mbo_c_reset       => mbo_c_reset,
               mbo_a_rx_locked   => X"FFF",
               mbo_b_rx_locked   => X"FFF",
               mbo_c_rx_locked   => X"FFF",
               mbo_int_n         => mbo_int_n,
               mbo_sda           => mbo_sda,
               mbo_scl           => mbo_scl);

---------------------------------------------------------------------------
-- Devices  --
---------------------------------------------------------------------------

   mbo_sda <= 'H';
   mbo_scl <= 'H';

   mbo_int_n <= '1';

   mbo_a_reset_n <= not mbo_a_reset;
   mbo_b_reset_n <= not mbo_b_reset;
   mbo_c_reset_n <= not mbo_c_reset;

U1: ENTITY i2c_lib.dev_obt
    generic map (dev_name  => string'("A"))
    PORT MAP (a            => "0000",
              reset_n      => mbo_a_reset_n,
              sda          => mbo_sda,
              scl          => mbo_scl);

U2: ENTITY i2c_lib.dev_obt
    generic map (dev_name  => string'("B"))
    PORT MAP (a           => "0001",
              reset_n      => mbo_b_reset_n,
              sda          => mbo_sda,
              scl          => mbo_scl);

U3: ENTITY i2c_lib.dev_obt
    generic map (dev_name  => string'("C"))
    PORT MAP (a           => "0010",
              reset_n      => mbo_c_reset_n,
              sda          => mbo_sda,
              scl          => mbo_scl);

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
      -- Disable MBO B TX link 4

      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_mbo_control_tx_disable_address_1, true, X"00000010");

      -------------------------------------------
      --                Test 2                 --
      -------------------------------------------
      -- Let the monitor cycle complete
      -- Verify the downloaded data

      WAIT FOR 390 ms;

      -- Check saved data
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_mbo_tx_vcc_address_0, false, X"0000814c", true, X"0000FFFF");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_mbo_rx_los_address_1, false, X"00000080", true, X"00000FFF");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_mbo_vcchi_address_0, false, X"000088B8", true, X"0000FFFF");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_mbo_tx_fault_address_1, false, X"00000200", true, X"00000FFF");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_mbo_temperature_address_1, false, X"0000189e", true, X"0000FFFF");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_mbo_tx_fault_address_2, false, X"00000200", true, X"00000FFF");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_mbo_tx_vcc_address_1, false, X"0000814c", true, X"0000FFFF");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_mbo_rx_cdr_unlocked_address_1, false, X"00000000", true, X"00000FFF");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_mbo_temperature_address_2, false, X"0000189e", true, X"0000FFFF");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_mbo_status_interrupt_address_1, false, X"00000001", true, X"00000001");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_mbo_rx_los_address_2, false, X"00000080", true, X"00000FFF");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_mbo_rx_cdr_unlocked_address_0, false, X"00000000", true, X"00000FFF");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_mbo_vcchi_address_2, false, X"000088B8", true, X"0000FFFF");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_mbo_status_rx_not_ready_address_0, false, X"00000000", true, X"00000001");

      -------------------------------------------
      --                Test 2                 --
      -------------------------------------------
      -- Upload a custom program to write a byte to a register and downlaod a word
      -- Verify the downloaded data

      -- Test Program mode
      data_burst(0) := X"00000006";    -- Write Byte OP
      data_burst(1) := X"00000052";    -- C TX
      data_burst(2) := X"0000003E";    -- Register Address
      data_burst(3) := X"000000b7";    -- Data
      data_burst(4) := X"00000007";    -- Read byte OP
      data_burst(5) := X"00000052";    -- C TX
      data_burst(6) := X"00000008";    -- Register Address
      data_burst(7) := X"00000013";    -- End

      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_control_program_address, true, data_burst(0 TO 7)); -- Write Program

      -- Queue program
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_control_control_prog_execute_address, true, X"00000001");

      -- Check sucess
      axi_lite_wait (axi_clk, s_axi_miso, s_axi_mosi, c_control_status_prog_finished_address, X"00000001");

      -- Verify Data
      data_burst(0) := X"00000081";

      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_control_results_address, false, data_burst(0 TO 0), validate => true); -- Check results

      sim_finished <= '1';
      tb_end <= '1';
      WAIT FOR 1 us;
      REPORT "Finished Simulation" SEVERITY FAILURE;
      WAIT;
   END PROCESS;






END testbench;