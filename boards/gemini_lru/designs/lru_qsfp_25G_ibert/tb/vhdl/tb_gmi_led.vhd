-------------------------------------------------------------------------------
--
-- Copyright (C) 2012
-- ASTRON (Netherlands Institute for Radio Astronomy) <http://www.astron.nl/>
-- JIVE (Joint Institute for VLBI in Europe) <http://www.jive.nl/>
-- P.O.Box 2, 7990 AA Dwingeloo, The Netherlands
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-------------------------------------------------------------------------------

-- Purpose: Test bench for gmi_led.
-- Description:
-- Usage:
--   On command line do:
--     > run_modelsim & (to start Modeslim)
--
--   In Modelsim do:
--     > lp gmi_led
--     > mk clean all (only first time to clean all libraries)
--     > mk all (to compile all libraries that are needed for gmi_led)
--     . load tb_gmi_led simulation by double clicking the tb_gmi_led icon
--     > as 10 (to view signals in Wave Window)
--     > run 100 us 
--     > run 1000 us or more, to see the SPI entity driving the LEDs
--
--

LIBRARY IEEE, common_lib, gmi_board_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE gmi_board_lib.gmi_board_pkg.ALL;
USE common_lib.tb_common_pkg.ALL;

ENTITY tb_gmi_led IS
    GENERIC (
      g_design_name : STRING  := "gmi_led"
    );
END tb_gmi_led;

ARCHITECTURE tb OF tb_gmi_led IS

  CONSTANT c_sim          : BOOLEAN := TRUE;
  CONSTANT c_clk_e_period : TIME := 8 ns;  -- 125 MHz XO

  -- DUT
  SIGNAL clk_e_p          : STD_LOGIC := '0';
  SIGNAL clk_e_n          : STD_LOGIC;

  SIGNAL debug_mmbx       : STD_LOGIC;

  SIGNAL led_d            : STD_LOGIC;
  SIGNAL led_cs           : STD_LOGIC;
  SIGNAL led_sclk         : STD_LOGIC;

BEGIN

  ----------------------------------------------------------------------------
  -- System setup
  ----------------------------------------------------------------------------
  clk_e_p <= NOT clk_e_p AFTER c_clk_e_period/2;
  clk_e_n <= NOT clk_e_p;
  
  ------------------------------------------------------------------------------
  -- DUT
  ------------------------------------------------------------------------------
  u_gmi_led : ENTITY work.gmi_led
    GENERIC MAP (
      g_sim         => c_sim,
      g_design_name => g_design_name
    )
    PORT MAP (
      clk_e_p     => clk_e_p,
      clk_e_n     => clk_e_n,

      debug_mmbx  => debug_mmbx,
      led_din     => led_d,
      led_dout    => led_d,
      led_cs      => led_cs,
      led_sclk    => led_sclk
    );

END tb;
