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
USE work.gemini_lru_board_backplane_control_reg_pkg.ALL;

ENTITY tb_backplane_control IS

END tb_backplane_control;

ARCHITECTURE testbench OF tb_backplane_control IS

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

   SIGNAL bp_sda                    : STD_LOGIC;
   SIGNAL bp_scl                    : STD_LOGIC;
   SIGNAL iobank0                   : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL iobank1                   : STD_LOGIC_VECTOR(7 DOWNTO 0);

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

dut: ENTITY work.backplane_control
     GENERIC MAP (g_clk_rate     => 156250000,
                  g_i2c_rate     => 50000,
                  g_pulse_time   => 2,
                  g_startup_time => 2)
     PORT MAP (clk               => axi_clk,
               rst               => reset,
               s_axi_mosi        => s_axi_mosi,
               s_axi_miso        => s_axi_miso,
               bp_sda            => bp_sda,
               bp_scl            => bp_scl);


---------------------------------------------------------------------------
-- Devices  --
---------------------------------------------------------------------------

   bp_sda <= 'H';
   bp_scl <= 'H';

dev_pca9555_1: entity i2c_lib.dev_pca9555
              generic map (g_address => "0100000")
              port map (sda         => bp_sda,
                        scl         => bp_scl,
                        iobank0     => iobank0,
                        iobank1     => iobank1);

   iobank0 <= (Others => 'H');
   iobank1 <= (Others => 'H');

---------------------------------------------------------------------------
-- Test Script  --
---------------------------------------------------------------------------

--   ASSERT (to_x01(iobank1(4 downto 0)) = "11111") REPORT "Wrong card reset" SEVERITY FAILURE;
--   ASSERT (to_x01(iobank0(5 downto 0)) = "111111") REPORT "Wrong card reset" SEVERITY FAILURE;

tb_stim: PROCESS

      VARIABLE data_burst  : t_slv_32_arr(0 TO 31);
   BEGIN

      axi_lite_init (reset, axi_clk, s_axi_miso, s_axi_mosi);

      -------------------------------------------
      --                Test 1                 --
      -------------------------------------------
      -- Set the Red LED On & wait until transaction is complete
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_backplane_control_control_green_led_address, false, X"00000000");

      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_backplane_control_control_red_led_address, true, X"00000001");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_backplane_control_control_update_leds_address, true, X"00000001");

      axi_lite_wait (axi_clk, s_axi_miso, s_axi_mosi, c_backplane_control_status_idle_address, X"00000001");


      ASSERT (iobank0(7) = '1') REPORT "Red LED Not ON" SEVERITY FAILURE;


      -------------------------------------------
      --                Test 2                 --
      -------------------------------------------
      -- Trigger card 6 to be restarted
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_backplane_control_power_reset_address, true, X"00000820");

      WAIT UNTIL falling_edge(iobank1(5));
      REPORT "Card 6 reset";

      axi_lite_wait (axi_clk, s_axi_miso, s_axi_mosi, c_backplane_control_status_idle_address, X"00000001");



      sim_finished <= '1';
      tb_end <= '1';
      WAIT FOR 1 us;
      REPORT "Finished Simulation" SEVERITY FAILURE;
      WAIT;
   END PROCESS;






END testbench;