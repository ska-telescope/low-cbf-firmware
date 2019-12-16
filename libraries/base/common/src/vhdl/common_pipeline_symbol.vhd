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

-- Purpose: Per symbol pipeline of the input data stream
-- Description:
--   The in_data is a concatenation of g_nof_symbols, that are each g_symbol_w
--   bits wide. The g_nof_symbols in the in_data slv can be pipelined
--   individualy as set by g_pipeline_arr(g_nof_symbols-1:0). The output
--   control signals val, sop and eop are also pipelined per symbol.
-- Remarks:

ENTITY common_pipeline_symbol IS
  GENERIC (
    g_pipeline_arr : t_natural_arr;   -- range g_nof_symbols-1 DOWNTO 0
    g_nof_symbols  : NATURAL := 4;
    g_symbol_w     : NATURAL := 16
  );
  PORT (
    rst        : IN  STD_LOGIC;
    clk        : IN  STD_LOGIC;
    
    in_data    : IN  STD_LOGIC_VECTOR(g_nof_symbols*g_symbol_w-1 DOWNTO 0);
    in_val     : IN  STD_LOGIC := '0';
    in_sop     : IN  STD_LOGIC := '0';
    in_eop     : IN  STD_LOGIC := '0';
    
    out_data    : OUT STD_LOGIC_VECTOR(g_nof_symbols*g_symbol_w-1 DOWNTO 0);
    out_val_arr : OUT STD_LOGIC_VECTOR(g_nof_symbols-1 DOWNTO 0);  -- pipelined in_val
    out_sop_arr : OUT STD_LOGIC_VECTOR(g_nof_symbols-1 DOWNTO 0);  -- pipelined in_sop
    out_eop_arr : OUT STD_LOGIC_VECTOR(g_nof_symbols-1 DOWNTO 0)   -- pipelined in_eop
  );
END common_pipeline_symbol;


ARCHITECTURE str OF common_pipeline_symbol IS

  TYPE t_symbol_arr  IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(g_symbol_w-1 DOWNTO 0);

  SIGNAL in_dat_arr   : t_symbol_arr(g_nof_symbols-1 DOWNTO 0);
  SIGNAL out_dat_arr  : t_symbol_arr(g_nof_symbols-1 DOWNTO 0);
  
BEGIN

  gen_symbols : FOR I IN g_nof_symbols-1 DOWNTO 0 GENERATE
    -- map input vector to arr
    in_dat_arr(I) <= in_data((I+1)*g_symbol_w-1 DOWNTO I*g_symbol_w);
    
    -- pipeline per symbol
    u_pipe_symbol : ENTITY work.common_pipeline
    GENERIC MAP (
      g_pipeline  => g_pipeline_arr(I),
      g_in_dat_w  => g_symbol_w,
      g_out_dat_w => g_symbol_w
    )
    PORT MAP (
      rst     => rst,
      clk     => clk,
      in_dat  => in_dat_arr(I),
      out_dat => out_dat_arr(I)
    );

    u_pipe_val : ENTITY work.common_pipeline_sl
    GENERIC MAP (
      g_pipeline => g_pipeline_arr(I)
    )
    PORT MAP (
      rst     => rst,
      clk     => clk,
      in_dat  => in_val,
      out_dat => out_val_arr(I)
    );
  
    u_pipe_sop : ENTITY work.common_pipeline_sl
    GENERIC MAP (
      g_pipeline => g_pipeline_arr(I)
    )
    PORT MAP (
      rst     => rst,
      clk     => clk,
      in_dat  => in_sop,
      out_dat => out_sop_arr(I)
    );
    
    u_pipe_eop : ENTITY work.common_pipeline_sl
    GENERIC MAP (
      g_pipeline => g_pipeline_arr(I)
    )
    PORT MAP (
      rst     => rst,
      clk     => clk,
      in_dat  => in_eop,
      out_dat => out_eop_arr(I)
    );
    
    -- map arr to output vector
    out_data((I+1)*g_symbol_w-1 DOWNTO I*g_symbol_w) <= out_dat_arr(I);
  END GENERATE;
  
END str;
