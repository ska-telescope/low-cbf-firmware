-------------------------------------------------------------------------------
--
-- File Name: tb_uptime.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created:
-- Template Rev: 1.0
--
-- Title:
--
-- Description:
--
-- Compiler options:
--
--
-- Dependencies:
--
--
--
-------------------------------------------------------------------------------

LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.math_real.ALL;
USE common_lib.common_pkg.ALL;


ENTITY tb_uptime_counter IS

END tb_uptime_counter;

ARCHITECTURE testbench OF tb_uptime_counter IS

  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------

   CONSTANT c_axi_clk_period     : TIME := 6.4 ns;

  ---------------------------------------------------------------------------
  -- SIGNAL DECLARATIONS  --
  ---------------------------------------------------------------------------

   SIGNAL axi_clk                   : STD_LOGIC := '0';
   SIGNAL reset                     : STD_LOGIC := '1';
   SIGNAL finished_sim              : STD_LOGIC := '0';

   -- DUT Signals
   SIGNAL pps                       : STD_LOGIC;
   SIGNAL tod                       : STD_LOGIC_VECTOR(13 DOWNTO 0);
   SIGNAL tod_rollover              : STD_LOGIC;


BEGIN



---------------------------------------------------------------------------
-- Clocks  --
---------------------------------------------------------------------------

   axi_clk <= NOT axi_clk or finished_sim AFTER c_axi_clk_period/2;

---------------------------------------------------------------------------
-- DUT  --
---------------------------------------------------------------------------

dut: ENTITY work.uptime_counter
     GENERIC MAP (g_tod_width => 14,
                  g_clk_freq  => 156.25E6)
     PORT MAP (clk            => axi_clk,
               rst            => reset,
               pps            => pps,
               tod            => tod,
               tod_rollover   => tod_rollover);

---------------------------------------------------------------------------
-- Test Script  --
---------------------------------------------------------------------------

tb_stim: PROCESS

   BEGIN
      reset <= '1';
      finished_sim <= '0';

      reset <= '1';
      WAIT FOR 100 ns;
      reset <= '0';
      WAIT FOR 500 ns;


      WAIT FOR 2000 ms;



      finished_sim <= '1';
      REPORT "Finished Simulation" SEVERITY note;
      WAIT;
   END PROCESS;






END testbench;