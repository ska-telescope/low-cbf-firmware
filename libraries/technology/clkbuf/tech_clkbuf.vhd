-------------------------------------------------------------------------------
--
-- Copyright (C) 2015
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
USE work.tech_clkbuf_component_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;

-- Declare IP libraries to ensure default binding in simulation. The IP library clause is ignored by synthesis.
LIBRARY ip_arria10_clkbuf_global_altclkctrl_150;
LIBRARY ip_arria10_e3sge3_clkbuf_global_altclkctrl_151;

ENTITY tech_clkbuf IS
  GENERIC (
    g_technology       : NATURAL := c_tech_select_default;
    g_clock_net        : STRING  := "GLOBAL"
  );
  PORT (
    inclk  : IN  STD_LOGIC;
    outclk : OUT STD_LOGIC
  );
END tech_clkbuf;

ARCHITECTURE str OF tech_clkbuf IS

BEGIN

  -----------------------------------------------------------------------------
  -- ip_arria10
  -----------------------------------------------------------------------------
  
  gen_ip_arria10 : IF g_technology=c_tech_arria10 AND g_clock_net="GLOBAL" GENERATE
    u0 : ip_arria10_clkbuf_global
    PORT MAP (
      inclk  => inclk,   -- inclk
      outclk => outclk   -- outclk
    );
  END GENERATE;

  -----------------------------------------------------------------------------
  -- ip_arria10_e3sge3
  -----------------------------------------------------------------------------
  
  gen_ip_arria10_e3sge3 : IF g_technology=c_tech_arria10_e3sge3 AND g_clock_net="GLOBAL" GENERATE
    u0 : ip_arria10_e3sge3_clkbuf_global
    PORT MAP (
      inclk  => inclk,   -- inclk
      outclk => outclk   -- outclk
    );
  END GENERATE;
END ARCHITECTURE;
