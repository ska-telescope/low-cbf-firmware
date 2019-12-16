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
-- Description:
--   c0 = 20 MHz
--   c1 = 50 MHz
--   c2 = 100 MHz
--   c3 = 125 MHz
-- 

ENTITY vcu110_board_clk125_pll IS
  GENERIC (
    g_technology : NATURAL := c_tech_xcvu190;
    g_use_clkbuf : BOOLEAN := FALSE
  );
  PORT (
    arst        : IN  STD_LOGIC := '0';
    clk125      : IN  STD_LOGIC := '0'; -- connect to UniBoard ETH_clk pin (125 MHz)

    c0_clk20    : OUT STD_LOGIC;  -- PLL c0
    c1_clk50    : OUT STD_LOGIC;  -- PLL c1
    c2_clk100   : OUT STD_LOGIC;  -- PLL c2
    c3_clk125   : OUT STD_LOGIC;  -- PLL c3
    pll_locked  : OUT STD_LOGIC
  );
END vcu110_board_clk125_pll;


ARCHITECTURE xcvu095 OF vcu110_board_clk125_pll IS

  SIGNAL clk125buf : STD_LOGIC;

BEGIN

  no_clkbuf : IF g_use_clkbuf=FALSE GENERATE
    clk125buf <= clk125;
  END GENERATE;
  
  u_pll : ENTITY tech_pll_lib.tech_pll_clk125
  GENERIC MAP (
    g_technology => g_technology
  )
  PORT MAP (
    areset  => arst,
    inclk0  => clk125buf,
    c0      => c0_clk20,
    c1      => c1_clk50,
    c2      => c2_clk100,
    c3      => c3_clk125,
    locked  => pll_locked
  );

END xcvu095;
