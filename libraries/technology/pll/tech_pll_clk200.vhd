-------------------------------------------------------------------------------
--
-- Copyright (C) 2014
-- ASTRON (Netherlands Institute for Radio Astronomy) <http://www.astron.nl/>
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

LIBRARY ieee, technology_lib;
USE ieee.std_logic_1164.all;
USE work.tech_pll_component_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;

ENTITY tech_pll_clk200 IS
  GENERIC (
    g_technology       : t_technology := c_tech_select_default;
    g_operation_mode   : STRING := "NORMAL";   -- or "SOURCE_SYNCHRONOUS" --> requires PLL_COMPENSATE assignment to an input pin to compensate for (stratixiv)
    g_clk0_phase_shift : STRING := "0";
    g_clk1_phase_shift : STRING := "0"
  );
  PORT (
    areset  : IN STD_LOGIC  := '0';
    inclk0  : IN STD_LOGIC  := '0';
    c0      : OUT STD_LOGIC ;
    c1      : OUT STD_LOGIC ;
    c2      : OUT STD_LOGIC ;
    locked  : OUT STD_LOGIC
  );
END tech_pll_clk200;

ARCHITECTURE str OF tech_pll_clk200 IS

BEGIN

  gen_ip_stratixiv : IF g_technology=c_tech_stratixiv GENERATE
    u0 : ip_stratixiv_pll_clk200
    GENERIC MAP (g_operation_mode, g_clk0_phase_shift, g_clk1_phase_shift)
    PORT MAP (areset, inclk0, c0, c1, c2, locked);
  END GENERATE;

  gen_ip_arria10 : IF g_technology=c_tech_arria10 GENERATE
    u0 : ip_arria10_pll_clk200
    PORT MAP (
      rst      => areset,
      refclk   => inclk0,
      outclk_0 => c0,
      outclk_1 => c1,
      outclk_2 => c2,
      locked   => locked
    );
  END GENERATE;

  gen_ip_arria10_e3sge3 : IF g_technology=c_tech_arria10_e3sge3 GENERATE
    u0 : ip_arria10_e3sge3_pll_clk200
    PORT MAP (
      rst      => areset,
      refclk   => inclk0,
      outclk_0 => c0,
      outclk_1 => c1,
      outclk_2 => c2,
      locked   => locked
    );
  END GENERATE;

END ARCHITECTURE;
