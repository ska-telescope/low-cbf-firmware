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
USE IEEE.std_logic_1164.ALL;
USE work.common_pkg.ALL;

-- Purpose: Per symbol add of the two input data stream
-- Description:
--   The in_a, in_b and out_data are slv with g_nof_symbols-1:0 concatenated
--   symbols. The out_data contains the sum of each pair of symbols in in_a
--   and in_b. The symbol width is g_symbol_w. The output can be pipelined via
--   g_pipeline.
-- Remarks:
-- . No need for g_representation = "SIGNED" or "UNSIGNED", because that is
--   only important if output width > input width, and not relevant here where 
--   both output width and input width are g_symbol_w

ENTITY common_add_symbol IS
  GENERIC (
    g_pipeline     : NATURAL := 0;
    g_nof_symbols  : NATURAL := 4;
    g_symbol_w     : NATURAL := 16
  );
  PORT (
    rst        : IN  STD_LOGIC;
    clk        : IN  STD_LOGIC;
    
    in_a       : IN  STD_LOGIC_VECTOR(g_nof_symbols*g_symbol_w-1 DOWNTO 0);
    in_b       : IN  STD_LOGIC_VECTOR(g_nof_symbols*g_symbol_w-1 DOWNTO 0);
    in_val     : IN  STD_LOGIC := 'X';
    in_sop     : IN  STD_LOGIC := 'X';
    in_eop     : IN  STD_LOGIC := 'X';
    
    out_data   : OUT STD_LOGIC_VECTOR(g_nof_symbols*g_symbol_w-1 DOWNTO 0);
    out_val    : OUT STD_LOGIC;  -- pipelined in_val
    out_sop    : OUT STD_LOGIC;  -- pipelined in_sop
    out_eop    : OUT STD_LOGIC   -- pipelined in_eop
  );
END common_add_symbol;


ARCHITECTURE str OF common_add_symbol IS

  TYPE t_symbol_arr  IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(g_symbol_w-1 DOWNTO 0);

  SIGNAL in_a_arr     : t_symbol_arr(g_nof_symbols-1 DOWNTO 0);
  SIGNAL in_b_arr     : t_symbol_arr(g_nof_symbols-1 DOWNTO 0);
  SIGNAL sum_dat_arr  : t_symbol_arr(g_nof_symbols-1 DOWNTO 0);
  SIGNAL sum_data     : STD_LOGIC_VECTOR(g_nof_symbols*g_symbol_w-1 DOWNTO 0);
  
BEGIN

  gen_symbols : FOR I IN g_nof_symbols-1 DOWNTO 0 GENERATE
    -- map input vector to arr
    in_a_arr(I) <= in_a((I+1)*g_symbol_w-1 DOWNTO I*g_symbol_w);
    in_b_arr(I) <= in_b((I+1)*g_symbol_w-1 DOWNTO I*g_symbol_w);
    
    -- add per symbol
    sum_dat_arr(I) <= ADD_UVEC(in_a_arr(I), in_b_arr(I));
    
    -- map arr to output vector
    sum_data((I+1)*g_symbol_w-1 DOWNTO I*g_symbol_w) <= sum_dat_arr(I);
  END GENERATE;
  
  -- pipeline data output
  u_out_data : ENTITY work.common_pipeline
  GENERIC MAP (
    g_pipeline  => g_pipeline,
    g_in_dat_w  => g_nof_symbols*g_symbol_w,
    g_out_dat_w => g_nof_symbols*g_symbol_w
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => sum_data,
    out_dat => out_data
  );

  -- pipeline control output
  u_out_val : ENTITY work.common_pipeline_sl
  GENERIC MAP (
    g_pipeline => g_pipeline
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => in_val,
    out_dat => out_val
  );
  
  u_out_sop : ENTITY work.common_pipeline_sl
  GENERIC MAP (
    g_pipeline => g_pipeline
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => in_sop,
    out_dat => out_sop
  );
  
  u_out_eop : ENTITY work.common_pipeline_sl
  GENERIC MAP (
    g_pipeline => g_pipeline
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => in_eop,
    out_dat => out_eop
  );
  
END str;
