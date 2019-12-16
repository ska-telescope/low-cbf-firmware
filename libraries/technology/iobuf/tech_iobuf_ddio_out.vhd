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
USE work.tech_iobuf_component_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;

ENTITY tech_iobuf_ddio_out IS
  GENERIC (
    g_technology    : t_technology := c_tech_select_default;
    g_width         : NATURAL := 1
  );
  PORT (
    rst        : IN   STD_LOGIC := '0';
    in_clk     : IN   STD_LOGIC;
    in_clk_en  : IN   STD_LOGIC := '1';
    in_dat_hi  : IN   STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);
    in_dat_lo  : IN   STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);
    out_dat    : OUT  STD_LOGIC_VECTOR(g_width-1 DOWNTO 0)
  );
END tech_iobuf_ddio_out;


ARCHITECTURE str OF tech_iobuf_ddio_out IS

BEGIN

  gen_ip_stratixiv : IF tech_is_device(g_technology, c_tech_device_stratixiv) GENERATE
    u0 : ip_stratixiv_ddio_out
    GENERIC MAP ("Stratix IV", g_width)
    PORT MAP (rst, in_clk, in_clk_en, in_dat_hi, in_dat_lo, out_dat);
  END GENERATE;

  gen_ip_arria10 : IF tech_is_device(g_technology, c_tech_device_arria10) GENERATE
    u0 : ip_arria10_ddio_out
    GENERIC MAP (g_width)
    PORT MAP (rst, in_clk, in_clk_en, in_dat_hi, in_dat_lo, out_dat);
  END GENERATE;

  gen_ip_arria10_e3sge3 : IF tech_is_device(g_technology, c_tech_device_arria10_e3sge3) GENERATE
    u0 : ip_arria10_e3sge3_ddio_out
    GENERIC MAP (g_width)
    PORT MAP (rst, in_clk, in_clk_en, in_dat_hi, in_dat_lo, out_dat);
  END GENERATE;

END ARCHITECTURE;
