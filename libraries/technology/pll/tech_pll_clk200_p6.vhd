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


ENTITY tech_pll_clk200_p6 IS
  GENERIC (
    g_technology       : t_technology := c_tech_select_default;
    g_pll_type         : STRING := "Left_Right"; -- "AUTO", "Left_Right", or "Top_Bottom". Set "Left_Right" to direct using PLL_L3 close to CLK pin on UniBoard, because with "AUTO" still a top/bottom PLL may get inferred.
    g_operation_mode   : STRING := "NORMAL";     -- or "SOURCE_SYNCHRONOUS" --> requires PLL_COMPENSATE assignment to an input pin to compensate for (stratixiv)
    g_clk0_phase_shift : STRING := "0";          -- = 0 degrees for clk 200 MHz
    g_clk1_used        : STRING := "PORT_USED";  -- or "PORT_UNUSED"
    g_clk2_used        : STRING := "PORT_USED";  -- or "PORT_UNUSED"
    g_clk3_used        : STRING := "PORT_USED";  -- or "PORT_UNUSED"
    g_clk4_used        : STRING := "PORT_USED";  -- or "PORT_UNUSED"
    g_clk5_used        : STRING := "PORT_USED";  -- or "PORT_UNUSED"
    g_clk6_used        : STRING := "PORT_USED";  -- or "PORT_UNUSED"
    g_clk1_divide_by   : NATURAL := 32;          -- = clk 200/32 MHz
    g_clk2_divide_by   : NATURAL := 32;          -- = clk 200/32 MHz
    g_clk3_divide_by   : NATURAL := 32;          -- = clk 200/32 MHz
    g_clk4_divide_by   : NATURAL := 32;          -- = clk 200/32 MHz
    g_clk5_divide_by   : NATURAL := 32;          -- = clk 200/32 MHz
    g_clk6_divide_by   : NATURAL := 32;          -- = clk 200/32 MHz
    g_clk1_phase_shift : STRING := "0";          -- = 0
    g_clk2_phase_shift : STRING := "156";        -- = 011.25
    g_clk3_phase_shift : STRING := "313";        -- = 022.5
    g_clk4_phase_shift : STRING := "469";        -- = 033.75
    g_clk5_phase_shift : STRING := "625";        -- = 045
                                -- "781"         -- = 056.25
    g_clk6_phase_shift : STRING := "938"         -- = 067.5
                                -- "1094"        -- = 078.75
  );
  PORT
  (
    areset    : IN STD_LOGIC  := '0';
    inclk0    : IN STD_LOGIC  := '0';
    c0        : OUT STD_LOGIC ;
    c1        : OUT STD_LOGIC ;
    c2        : OUT STD_LOGIC ;
    c3        : OUT STD_LOGIC ;
    c4        : OUT STD_LOGIC ;
    c5        : OUT STD_LOGIC ;
    c6        : OUT STD_LOGIC ;
    locked    : OUT STD_LOGIC
  );
END tech_pll_clk200_p6;


ARCHITECTURE str OF tech_pll_clk200_p6 IS
BEGIN

  gen_ip_stratixiv : IF g_technology=c_tech_stratixiv GENERATE
    u0 : ip_stratixiv_pll_clk200_p6
    GENERIC MAP (g_pll_type, g_operation_mode,
                 g_clk0_phase_shift,
                 g_clk1_used,        g_clk2_used,        g_clk3_used,        g_clk4_used,        g_clk5_used,        g_clk6_used,
                 g_clk1_divide_by,   g_clk2_divide_by,   g_clk3_divide_by,   g_clk4_divide_by,   g_clk5_divide_by,   g_clk6_divide_by,
                 g_clk1_phase_shift, g_clk2_phase_shift, g_clk3_phase_shift, g_clk4_phase_shift, g_clk5_phase_shift, g_clk6_phase_shift)
    PORT MAP (areset, inclk0, c0, c1, c2, c3, c4, c5, c6, locked);
  END GENERATE;

END ARCHITECTURE;