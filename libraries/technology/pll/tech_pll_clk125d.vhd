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


ENTITY tech_pll_clk125d IS
  GENERIC (
    g_technology : t_technology := c_tech_select_default
  );
  PORT (
    areset    : IN STD_LOGIC  := '0';
    inclk0_p  : IN STD_LOGIC  := '0';
    inclk0_n  : IN STD_LOGIC  := '0';
    c0        : OUT STD_LOGIC ;
    c1        : OUT STD_LOGIC ;
    locked    : OUT STD_LOGIC 
  );
END tech_pll_clk125d;

ARCHITECTURE str OF tech_pll_clk125d IS

BEGIN

  gen_ip_xcvu9p : IF tech_is_device(g_technology,c_tech_device_ultrascalep) GENERATE
    u0 : ip_xcvu9p_mmcm_clk125d
    PORT MAP (

      clk_in1_p  => inclk0_p,
      clk_in1_n  => inclk0_n,
      clk_out1   => c0,
      clk_out2   => c1,
      reset      => areset,
      locked     => locked
    );
  END GENERATE;
END ARCHITECTURE;
