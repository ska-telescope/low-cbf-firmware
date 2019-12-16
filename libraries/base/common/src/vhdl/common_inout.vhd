-------------------------------------------------------------------------------
--
-- Copyright (C) 2009
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

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

-- Tristate buffer

ENTITY common_inout IS
  PORT (
    dat_inout        : INOUT STD_LOGIC;
    dat_in_from_line : OUT   STD_LOGIC;
    dat_out_to_line  : IN    STD_LOGIC := '0';  -- default drive INOUT low when output enabled
    dat_out_en       : IN    STD_LOGIC := '0'   -- output enable, default use INOUT as tristate input
  );
END common_inout;


ARCHITECTURE rtl OF common_inout IS

BEGIN

  dat_inout <= 'Z' WHEN dat_out_en='0' ELSE dat_out_to_line;
  
  dat_in_from_line <= NOT (NOT dat_inout);  -- do via NOT(NOT) for simulation to force 'H' -> '1' and 'L' --> '0'

END rtl;