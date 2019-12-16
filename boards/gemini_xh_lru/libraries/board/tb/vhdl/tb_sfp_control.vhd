-------------------------------------------------------------------------------
--
-- File Name: tb_sfp_control.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created:
-- Template Rev: 1.0
--
-- Title: SFP M&C Testbench
--
-- Description: Runs a simple test on the suppoort module for the Gemini LRU
--              SFP module
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
USE work.gemini_xh_lru_board_sfp_reg_pkg.ALL;

ENTITY tb_sfp_control IS

END tb_sfp_control;

ARCHITECTURE testbench OF tb_sfp_control IS

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

   SIGNAL sfp_sda                   : STD_LOGIC;
   SIGNAL sfp_scl                   : STD_LOGIC;
   SIGNAL sfp_fault                 : STD_LOGIC;
   SIGNAL sfp_tx_enable             : STD_LOGIC;
   SIGNAL sfp_mod_abs               : STD_LOGIC;

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

dut: ENTITY work.sfp_control
     GENERIC MAP (g_clk_rate  => 156250000,
                  g_i2c_rate  => 50000,
                  g_startup_time => 1)
     PORT MAP (clk            => axi_clk,
               rst            => reset,
               s_axi_mosi     => s_axi_mosi,
               s_axi_miso     => s_axi_miso,
               sfp_sda        => sfp_sda,
               sfp_scl        => sfp_scl,
               sfp_fault      => sfp_fault,
               sfp_tx_enable  => sfp_tx_enable,
               sfp_mod_abs    => sfp_mod_abs);


---------------------------------------------------------------------------
-- Devices  --
---------------------------------------------------------------------------

   sfp_sda <= 'H';
   sfp_scl <= 'H';

   sfp_mod_abs <= '0';
   sfp_fault <= '0';


U1: ENTITY i2c_lib.dev_sfp
    GENERIC MAP (dev_name => string'(""))
    PORT MAP (sda          => sfp_sda,
              scl          => sfp_scl);

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
      -- Let the monitor cycle complete
      -- Verify the downloaded data

      WAIT FOR 7 ms;

      -- Check saved data
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_sfp_voltage_address, false, X"00000301", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_sfp_tx_bias_address, false, X"0000001A", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_sfp_tx_power_address, false, X"00000266", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_sfp_rx_power_address, false, X"00000017", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_sfp_temperature_address, false, X"0000020C", validate => true);

      -------------------------------------------
      --                Test 2                 --
      -------------------------------------------
      -- Upload a custom program to write a byte to a register and downlaod a word
      -- Verify the downloaded data

      -- Test Program mode
      data_burst(0) := X"00000006";    -- Write Byte OP
      data_burst(1) := X"00000051";    -- DMI
      data_burst(2) := X"00000041";    -- Register Address
      data_burst(3) := X"000000aa";    -- Data
      data_burst(4) := X"00000009";    -- Read word OP
      data_burst(5) := X"00000051";    -- DMI
      data_burst(6) := X"0000004a";    -- Register Address
      data_burst(7) := X"00000013";    -- End

      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_sfp_program_address, true, data_burst(0 TO 7)); -- Write Program

      -- Queue program
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_sfp_control_prog_execute_address, true, X"00000001");

      -- Wait for completion
      axi_lite_wait (axi_clk, s_axi_miso, s_axi_mosi, c_sfp_status_prog_finished_address, X"00000001");

      -- Verify Data
      data_burst(0) := X"0000006b";    -- LSB first
      data_burst(1) := X"0000001b";    -- MSB second

      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_sfp_results_address, false, data_burst(0 TO 1), validate => true); -- Check results

      sim_finished <= '1';
      tb_end <= '1';
      WAIT FOR 1 us;
      REPORT "Finished Simulation" SEVERITY FAILURE;
      WAIT;
   END PROCESS;






END testbench;