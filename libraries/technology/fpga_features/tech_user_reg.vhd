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

LIBRARY ieee, technology_lib, UNISIM;
USE ieee.std_logic_1164.all;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE UNISIM.VCOMPONENTS.ALL;

ENTITY tech_user_reg IS
  GENERIC (
    g_technology     : t_technology := c_tech_select_default);
  PORT (
    data : OUT  STD_LOGIC_VECTOR(31 DOWNTO 0));
END tech_user_reg;


ARCHITECTURE str OF tech_user_reg IS

BEGIN

   gen_usr_access : IF tech_is_device(g_technology, c_tech_device_ultrascalep + c_tech_device_ultrascale) GENERATE
      u_useraccese2: USR_ACCESSE2
      PORT MAP (
         CFGCLK     => OPEN,
         DATA       => data,
         DATAVALID  => OPEN);
   END GENERATE;

END ARCHITECTURE;
