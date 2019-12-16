-------------------------------------------------------------------------------
--
-- Copyright (C) 2015-2016
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

LIBRARY IEEE, common_lib, technology_lib, tech_pll_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;

-- Purpose: PLL for Board node CLK input @ 125 MHz
-- 

ENTITY gmi_board_clk125d_pll IS
  GENERIC (
    g_technology : NATURAL := c_tech_xcvu9p
  );
  PORT (
    arst        : IN  STD_LOGIC := '0';
    clk125_p    : IN  STD_LOGIC := '0';
    clk125_n    : IN  STD_LOGIC := '0';
    c0_clk50    : OUT STD_LOGIC;
    c1_clk375   : OUT STD_LOGIC;
    pll_locked  : OUT STD_LOGIC
  );
END gmi_board_clk125d_pll;


ARCHITECTURE xcvu9p OF gmi_board_clk125d_pll IS

  SIGNAL clk125buf : STD_LOGIC;

BEGIN

  u_pll : ENTITY tech_pll_lib.tech_pll_clk125d
  GENERIC MAP (
    g_technology => g_technology
  )
  PORT MAP (
    areset   => arst,
    inclk0_p => clk125_p,
    inclk0_n => clk125_n,
    c0       => c0_clk50,
    c1       => c1_clk375,
    locked   => pll_locked
  );

END xcvu9p;

