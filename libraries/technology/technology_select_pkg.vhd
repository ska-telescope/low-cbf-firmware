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

-- Purpose: Define default technology selection value for g_technology.
-- Description:
--   In case g_technology is not overruled by the application design then the
--   g_technology defaults to c_tech_select_default.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.technology_pkg.ALL;

PACKAGE technology_select_pkg IS

  CONSTANT c_tech_select_default : t_technology := c_tech_xcku040;

  
END technology_select_pkg;
