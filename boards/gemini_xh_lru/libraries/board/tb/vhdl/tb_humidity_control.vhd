-------------------------------------------------------------------------------
--
-- File Name: tb_humidity_control.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created:
-- Template Rev: 1.0
--
-- Title: Humidity M&C Testbench
--
-- Description: Runs a simple test on the suppoort module for the Gemini LRU
--              Humidity sensor
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
USE work.gemini_xh_lru_board_humidity_reg_pkg.ALL;

ENTITY tb_humidity_control IS

END tb_humidity_control;

ARCHITECTURE testbench OF tb_humidity_control IS

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

   SIGNAL hum_sda                   : STD_LOGIC;
   SIGNAL hum_scl                   : STD_LOGIC;

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

dut: ENTITY work.humidity_control
     GENERIC MAP (g_clk_rate     => 156250000,
                  g_i2c_rate     => 50000,
                  g_startup_time => 2)
     PORT MAP (clk               => axi_clk,
               rst               => reset,
               s_axi_mosi        => s_axi_mosi,
               s_axi_miso        => s_axi_miso,
               hum_sda           => hum_sda,
               hum_scl           => hum_scl);


---------------------------------------------------------------------------
-- Devices  --
---------------------------------------------------------------------------

   hum_sda <= 'H';
   hum_scl <= 'H';

dev_si7020_1: entity i2c_lib.dev_si7020
              generic map (dev_name => string'(""))
              port map (sda         => hum_sda,
                        scl         => hum_scl);


---------------------------------------------------------------------------
-- Test Script  --
---------------------------------------------------------------------------

tb_stim: PROCESS

      VARIABLE data_burst  : t_slv_32_arr(0 TO 31);
   BEGIN
      axi_lite_init (reset, axi_clk, s_axi_miso, s_axi_mosi);

      -------------------------------------------
      --                Test 1                 --s
      -------------------------------------------
      -- Let the monitor cycle complete
      -- Verify the downloaded data

      -- Needs to wait for at least 1 cycle for the registers to be updated
      WAIT FOR 30 ms;

      -- Check saved data
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_humidity_humidity_address, false, X"00008B44", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_humidity_temperature_address, false, X"00006A6D", validate => true);



      sim_finished <= '1';
      tb_end <= '1';
      WAIT FOR 1 us;
      REPORT "Finished Simulation" SEVERITY FAILURE;
      WAIT;
   END PROCESS;






END testbench;