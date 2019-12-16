-------------------------------------------------------------------------------
--
-- File Name: tb_pmbus_control.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created:
-- Template Rev: 1.0
--
-- Title: PMBus M&C Testbench
--
-- Description: Runs a simple test on the suppoort module for the Gemini LRU
--              power supply modules
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
USE work.gemini_xh_lru_board_pmbus_reg_pkg.ALL;

ENTITY tb_pmbus_control IS

END tb_pmbus_control;

ARCHITECTURE testbench OF tb_pmbus_control IS

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

   SIGNAL power_sda                 : STD_LOGIC;
   SIGNAL power_sdc                 : STD_LOGIC;
   SIGNAL power_alert_n             : STD_LOGIC;

   -- Testbench
   SIGNAL reset                     : STD_LOGIC;
   SIGNAL tb_end                    : STD_LOGIC := '0';

BEGIN



---------------------------------------------------------------------------
-- Clocks  --
---------------------------------------------------------------------------

   axi_clk <= NOT axi_clk OR tb_end  AFTER c_mm_clk_period/2;
   reset <= '1', '0'    AFTER c_mm_clk_period*c_reset_len;

---------------------------------------------------------------------------
-- DUT  --
---------------------------------------------------------------------------

dut: ENTITY work.pmbus_control
     GENERIC MAP (g_clk_rate     => 156250000,
                  g_startup_time  => 1)
     PORT MAP (clk               => axi_clk,
               rst               => reset,
               s_axi_mosi        => s_axi_mosi,
               s_axi_miso        => s_axi_miso,
               power_sda         => power_sda,
               power_sdc         => power_sdc,
               power_alert_n     => power_alert_n);

---------------------------------------------------------------------------
-- Devices  --
---------------------------------------------------------------------------

   power_sda <= 'Z';
   power_sdc <= 'Z';

   power_alert_n <= '1';

U1: ENTITY i2c_lib.dev_pmbus_device
    GENERIC MAP (dev_name  => STRING'("0V72A"))
    PORT MAP (address      => "0100000",
              sda          => power_sda,
              scl          => power_sdc);

U2: ENTITY i2c_lib.dev_pmbus_device
    GENERIC MAP (dev_name  => STRING'("0V72B"))
    PORT MAP (address      => "0100001",
              sda          => power_sda,
              scl          => power_sdc);

U3: ENTITY i2c_lib.dev_pmbus_device
    GENERIC MAP (dev_name  => STRING'("0V72C"))
    PORT MAP (address      => "0100010",
              sda          => power_sda,
              scl          => power_sdc);

U4: ENTITY i2c_lib.dev_pmbus_device
    GENERIC MAP (dev_name  => STRING'("0V72D"))
    PORT MAP (address      => "0100011",
              sda          => power_sda,
              scl          => power_sdc);

U5: ENTITY i2c_lib.dev_pmbus_device
    GENERIC MAP (dev_name  => STRING'("0V85 & 0V9"))
    PORT MAP (address      => "1000000",
              sda          => power_sda,
              scl          => power_sdc);

U6: ENTITY i2c_lib.dev_pmbus_device
    GENERIC MAP (dev_name  => STRING'("1V2 MGT/DDR"))
    PORT MAP (address      => "1000011",
              sda          => power_sda,
              scl          => power_sdc);

U7: ENTITY i2c_lib.dev_pmbus_device
    GENERIC MAP (dev_name  => STRING'("1V8 & 2V5"))
    PORT MAP (address      => "1000001",
              sda          => power_sda,
              scl          => power_sdc);

U8: ENTITY i2c_lib.dev_pmbus_device
    GENERIC MAP (dev_name  => STRING'("3V3"))
    PORT MAP (address      => "1000010",
              sda          => power_sda,
              scl          => power_sdc);

U9: ENTITY i2c_lib.dev_pmbus_device
    GENERIC MAP (dev_name  => STRING'("1V2 HBM"))
    PORT MAP (address      => "1000100",
              sda          => power_sda,
              scl          => power_sdc);

U10: ENTITY i2c_lib.dev_pmbus_device
    GENERIC MAP (dev_name  => STRING'("12V"))
    PORT MAP (address      => "0010000",
              sda          => power_sda,
              scl          => power_sdc);

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
      -- Arm the clear fault flags program to run at next opportunity

      WAIT FOR 20 ms;

      -- Clear Fault flags program
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_control_clear_fault_flags_address, true, X"00000001");

      -------------------------------------------
      --                Test 2                 --
      -------------------------------------------
      -- Let the monitor cycle complete
      -- Verify a subset of the downloaded data

      WAIT FOR 52 ms;

      -- Check saved data (Only a small subset of data checked)
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_vcc0v72a_vin_mantissa_address, false, X"00000301", true, X"000007FF");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_vcc0v72a_vin_exponent_address, false, X"0000001A", true, X"0000001F");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_vcc0v72b_vout_mantissa_address, false, X"00000266", true, X"000007FF");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_vcc0v72b_vout_exponent_address, false, X"00000017", true, X"0000001F");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_vcc0v72c_iout_mantissa_address, false, X"0000020C", true, X"000007FF");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_vcc0v72c_iout_exponent_address, false, X"000000F1", true, X"0000001F");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_vcc0v85_temp_mantissa_address, false, X"000006F0", true, X"000007FF");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_vcc0v85_temp_exponent_address, false, X"0000001B", true, X"0000001F");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_vcc0v9_temp_int_mantissa_address, false, X"000003Cf", true, X"000007FF");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_vcc0v9_temp_int_exponent_address, false, X"0000001B", true, X"0000001F");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_vcc1v2_tr_vin_mantissa_address, false, X"00000301", true, X"000007FF");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_vcc1v2_tr_vin_exponent_address, false, X"0000001A", true, X"0000001F");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_vcc1v2_ddr_vout_mantissa_address, false, X"00000266", true, X"000007FF");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_vcc1v2_ddr_vout_exponent_address, false, X"00000017", true, X"0000001F");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_vcc1v8_iout_mantissa_address, false, X"0000020C", true, X"000007FF");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_vcc1v8_iout_exponent_address, false, X"000000F1", true, X"0000001F");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_vcc2v5_temp_mantissa_address, false, X"000006F0", true, X"000007FF");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_vcc2v5_temp_exponent_address, false, X"0000001B", true, X"0000001F");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_vcc3v3_temp_int_mantissa_address, false, X"000003Cf", true, X"000007FF");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_vcc3v3_temp_int_exponent_address, false, X"0000001B", true, X"0000001F");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_vcc3v3a_temp_mantissa_address, false, X"000006F0", true, X"000007FF");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_vcc3v3a_temp_exponent_address, false, X"0000001B", true, X"0000001F");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_vcc12v_iout_mantissa_address, false, X"0000020C", true, X"000007FF");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_vcc12v_iout_exponent_address, false, X"000000F1", true, X"0000001F");

      -------------------------------------------
      --                Test 3                 --
      -------------------------------------------
      -- Upload a custom program to write a byte to a register and downlaod a word
      -- Verify the downloaded data

      -- Test Program mode
      data_burst(0) := X"00000006";    -- Write Byte OP
      data_burst(1) := X"00000022";    -- 0.72V C part
      data_burst(2) := X"00000041";    -- Register Address
      data_burst(3) := X"000000aa";    -- Data
      data_burst(4) := X"00000009";    -- Read word OP
      data_burst(5) := X"00000022";    -- 0.72V C part
      data_burst(6) := X"0000004a";    -- Register Address
      data_burst(7) := X"00000013";    -- End

      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_program_address, true, data_burst(0 TO 7)); -- Write Program

      -- Queue program
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_pmbus_control_prog_execute_address, true, X"00000001");

      -- Wait for completion
      axi_lite_wait (axi_clk, s_axi_miso, s_axi_mosi, c_control_status_prog_finished_address, X"00000001");

      -- Check sucess
      axi_lite_transaction (c_pmbus_status_prog_finished_address, false, X"00000001", true, X"00000001");

      -- Verify Data
      data_burst(0) := X"0000006b";    -- LSB first
      data_burst(1) := X"0000001b";    -- MSB second

      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_control_results_address, false, data_burst(0 TO 1), validate => true); -- Check results

      tb_end <= '1';
      WAIT FOR 1 us;
      REPORT "Finished Simulation" SEVERITY FAILURE;
      WAIT;
   END PROCESS;






END testbench;