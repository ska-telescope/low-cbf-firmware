-------------------------------------------------------------------------------
--
-- Copyright (C) 2010
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

LIBRARY IEEE, common_lib;
USE IEEE.std_logic_1164.ALL;
USE common_lib.common_pkg.ALL;


PACKAGE util_heater_pkg IS

  ------------------------------------------------------------------------------
  -- Definitions for MM register
  ------------------------------------------------------------------------------
  
  -- The maximum number of 18x18 multipliers       in the Stratix IV SGX230 = 1288
  -- The maximum number of 1kbit  M9K   RAM blocks in the Stratix IV SGX230 = 1235
  -- The maximum number of 16kbit M144K RAM blocks in the Stratix IV SGX230 = 22
  
  --CONSTANT c_util_heater_nof_mac4_max     : NATURAL := 352; --stratix4                         -- >= 1288/4 and multiple of c_word_w=32 
  CONSTANT c_util_heater_nof_mac4_max     : NATURAL := 2000; --stratix4                         -- >= 1288/4 and multiple of c_word_w=32 
  CONSTANT c_util_heater_reg_nof_words    : NATURAL := c_util_heater_nof_mac4_max / c_word_w;  -- note: needs adjustment if not multiple of c_word_w
  
  CONSTANT c_util_heater_reg_addr_w       : NATURAL := ceil_log2(c_util_heater_reg_nof_words);
  
  TYPE t_util_heater_reg_mm_bus IS RECORD
    -- Master In Slave Out
    rddata    : STD_LOGIC_VECTOR(c_word_w-1 DOWNTO 0);
    -- Master Out Slave In
    address   : STD_LOGIC_VECTOR(c_util_heater_reg_addr_w-1 DOWNTO 0);
    wrdata    : STD_LOGIC_VECTOR(c_word_w-1 DOWNTO 0);
    wr        : STD_LOGIC;
    rd        : STD_LOGIC;
  END RECORD;
  
  CONSTANT c_util_heater_reg_mm_bus : t_util_heater_reg_mm_bus := ((OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0'), '0', '0');
  
END util_heater_pkg;


PACKAGE BODY util_heater_pkg IS
END util_heater_pkg;

