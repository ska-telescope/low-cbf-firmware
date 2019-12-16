-------------------------------------------------------------------------------
--
-- Copyright (C) 2013
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
USE work.common_pkg.ALL;
USE work.common_mem_pkg.ALL;

-- Purpose: Component declarations to check positional mapping
-- Description:
-- Remarks:

PACKAGE common_components_pkg IS

  COMPONENT common_pipeline IS
  GENERIC (
    g_representation : STRING  := "SIGNED";   -- or "UNSIGNED"
    g_pipeline       : NATURAL := 1;  -- 0 for wires, > 0 for registers, 
    g_reset_value    : INTEGER := 0;
    g_in_dat_w       : NATURAL := 8;
    g_out_dat_w      : NATURAL := 9
  );
  PORT (
    rst     : IN  STD_LOGIC := '0';
    clk     : IN  STD_LOGIC;
    clken   : IN  STD_LOGIC := '1';
    in_clr  : IN  STD_LOGIC := '0';
    in_en   : IN  STD_LOGIC := '1';
    in_dat  : IN  STD_LOGIC_VECTOR(g_in_dat_w-1 DOWNTO 0);
    out_dat : OUT STD_LOGIC_VECTOR(g_out_dat_w-1 DOWNTO 0)
  );
  END COMPONENT;

  COMPONENT common_pipeline_sl IS
    GENERIC (
      g_pipeline       : NATURAL := 1;  -- 0 for wires, > 0 for registers, 
      g_reset_value    : NATURAL := 0;  -- 0 or 1, bit reset value,
      g_out_invert     : BOOLEAN := FALSE
    );
    PORT (
      rst     : IN  STD_LOGIC := '0';
      clk     : IN  STD_LOGIC;
      clken   : IN  STD_LOGIC := '1';
      in_clr  : IN  STD_LOGIC := '0';
      in_en   : IN  STD_LOGIC := '1';
      in_dat  : IN  STD_LOGIC;
      out_dat : OUT STD_LOGIC
    );
  END COMPONENT;
  
END common_components_pkg;


PACKAGE BODY common_components_pkg IS
END common_components_pkg;
