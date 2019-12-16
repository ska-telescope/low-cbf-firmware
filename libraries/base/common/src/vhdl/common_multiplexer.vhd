-------------------------------------------------------------------------------
--
-- Copyright (C) 2012
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
USE IEEE.STD_LOGIC_1164.ALL;
USE work.common_pkg.ALL;

-- Purpose: Assign one of g_nof_in input streams to the output based on in_sel input
-- Description: The input streams are concatenated into one SLV.
-- Remarks:

ENTITY common_multiplexer IS
  GENERIC (
    g_pipeline_in  : NATURAL := 0;
    g_pipeline_out : NATURAL := 0;
    g_nof_in       : NATURAL;
    g_dat_w        : NATURAL
 );
  PORT (
    clk         : IN  STD_LOGIC;
    rst         : IN  STD_LOGIC;

    in_sel      : IN  STD_LOGIC_VECTOR(ceil_log2(g_nof_in)-1 DOWNTO 0);
    in_dat      : IN  STD_LOGIC_VECTOR(g_nof_in*g_dat_w-1 DOWNTO 0);
    in_val      : IN  STD_LOGIC;

    out_dat     : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    out_val     : OUT STD_LOGIC
  );
END;

ARCHITECTURE str OF common_multiplexer IS

BEGIN

  u_select_symbol : ENTITY work.common_select_symbol
  GENERIC MAP (
    g_pipeline_in  => g_pipeline_in,
    g_pipeline_out => g_pipeline_out,
    g_nof_symbols  => g_nof_in,
    g_symbol_w     => g_dat_w,
    g_sel_w        => ceil_log2(g_nof_in)
  )
  PORT MAP (
    rst        => rst,
    clk        => clk,
    
    in_data    => in_dat,
    in_val     => in_val,
    
    in_sel     => in_sel,
    
    out_symbol => out_dat,
    out_val    => out_val
  );

END str;
