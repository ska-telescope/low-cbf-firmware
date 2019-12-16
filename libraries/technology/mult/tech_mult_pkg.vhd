-------------------------------------------------------------------------------
--
-- Copyright (C) 2014
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

LIBRARY IEEE, technology_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE technology_lib.technology_pkg.ALL;

PACKAGE tech_mult_pkg IS  

  TYPE t_c_tech_mult_variant IS RECORD
    -- PHY variant within a technology
    name  : STRING(1 TO 3);  -- = "RTL" or " IP"
    ip    : BOOLEAN;  -- = TRUE  TRUE = Megawizard IP, FALSE = RTL implemenation
  END RECORD;

  --                                                                      name    ip
  CONSTANT c_tech_mult_stratixiv_rtl                  : t_c_tech_mult_variant := ("RTL",  FALSE);
  CONSTANT c_tech_mult_stratixiv_ip                   : t_c_tech_mult_variant := (" IP",  TRUE);
  CONSTANT c_tech_mult_arria10_rtl                    : t_c_tech_mult_variant := ("RTL",  FALSE);
  CONSTANT c_tech_mult_arria10_ip                     : t_c_tech_mult_variant := (" IP",  TRUE);
  CONSTANT c_tech_mult_xcvu095_rtl                    : t_c_tech_mult_variant := ("RTL",  FALSE);
  CONSTANT c_tech_mult_xcvu095_ip                     : t_c_tech_mult_variant := (" IP",  TRUE);

END tech_mult_pkg;
