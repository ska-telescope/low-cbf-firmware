-------------------------------------------------------------------------------
--
-- Copyright (C) 2016
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

-- Purpose: Test bench for kcu105_led.
-- Description:
-- Usage:
--   On command line do:
--     > run_modelsim & (to start Modeslim)
--
--   In Modelsim do:
--     > lp kcu105_led
--     > mk clean all (only first time to clean all libraries)
--     > mk all (to compile all libraries that are needed for kcu116_led)
--     . load tb_kcu116_led simulation by double clicking the tb_kcu116_led icon
--     > as 10 (to view signals in Wave Window)
--     > run 100 us 
--
--

LIBRARY IEEE, common_lib, kcu116_led_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.tb_common_pkg.ALL;

ENTITY tb_kcu116_led IS
END tb_kcu116_led;

ARCHITECTURE tb OF tb_kcu116_led IS

  CONSTANT c_clk_period   : TIME := 3.333 ns;  -- 300 MHz

  -- DUT
  SIGNAL clk_p            : STD_LOGIC := '0';
  SIGNAL clk_n            : STD_LOGIC;

  SIGNAL led              : STD_LOGIC_VECTOR(7 downto 0);

BEGIN

  ----------------------------------------------------------------------------
  -- System setup
  ----------------------------------------------------------------------------
  clk_p <= NOT clk_p AFTER c_clk_period/2;
  clk_n <= NOT clk_p;
  
  ------------------------------------------------------------------------------
  -- DUT
  ------------------------------------------------------------------------------
  u_kcu116_led : ENTITY kcu116_led_lib.kcu116_led
    PORT MAP (
      SYSCLK_300_P     => clk_p,
      SYSCLK_300_N     => clk_n,
      o_led            => led
    );

END tb;
