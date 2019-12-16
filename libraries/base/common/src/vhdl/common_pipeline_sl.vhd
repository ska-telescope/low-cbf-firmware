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
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;

ENTITY common_pipeline_sl IS
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
END common_pipeline_sl;


ARCHITECTURE str OF common_pipeline_sl IS

  SIGNAL in_dat_slv  : STD_LOGIC_VECTOR(0 DOWNTO 0);
  SIGNAL out_dat_slv  : STD_LOGIC_VECTOR(0 DOWNTO 0);

BEGIN

  in_dat_slv(0) <= in_dat WHEN g_out_invert=FALSE ELSE NOT in_dat;
  out_dat       <= out_dat_slv(0);
  
  u_sl : ENTITY work.common_pipeline
  GENERIC MAP (
    g_representation => "UNSIGNED",
    g_pipeline       => g_pipeline,
    g_reset_value    => sel_a_b(g_out_invert, 1-g_reset_value, g_reset_value),
    g_in_dat_w       => 1,
    g_out_dat_w      => 1
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    clken   => clken,
    in_clr  => in_clr,
    in_en   => in_en,
    in_dat  => in_dat_slv,
    out_dat => out_dat_slv
  );
    
END str;
