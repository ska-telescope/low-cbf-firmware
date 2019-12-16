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
USE work.common_components_pkg.ALL;

-- Purpose: Select M symbols from an input data stream with N symbols
-- Description:
--   The in_data is a concatenation of N=g_nof_input, that are each g_symbol_w
--   bits wide. The out_data is a concatenation of M=g_nof_output, that are
--   each g_symbol_w bits wide. The input symbol with index set by in_select m
--   is passed on to the output symbol m in out_data.
-- Remarks:
-- . If the in_select index is too large for g_nof_input range then the output
--   passes on symbol 0.
-- . This common_select_m_symbols is functionally equivalent to 
--   common_reorder_symbol. The advantage of common_select_m_symbols is that
--   the definition of in_select is more intinutive. The advantage of 
--   common_reorder_symbol may be that the structure of reorder2 cells with
--   minimal line crossings allow achieving a higher f_max.

ENTITY common_select_m_symbols IS
  GENERIC (
    g_nof_input     : NATURAL := 4;
    g_nof_output    : NATURAL := 4;
    g_symbol_w      : NATURAL := 16;
    g_pipeline_in   : NATURAL := 0;   -- pipeline in_data
    g_pipeline_in_m : NATURAL := 0;   -- pipeline in_data for M-fold fan out
    g_pipeline_out  : NATURAL := 1    -- pipeline out_data
  );
  PORT (
    rst        : IN  STD_LOGIC;
    clk        : IN  STD_LOGIC;
    
    in_data    : IN  STD_LOGIC_VECTOR(g_nof_input*g_symbol_w-1 DOWNTO 0);
    in_val     : IN  STD_LOGIC := '0';
    in_sop     : IN  STD_LOGIC := '0';
    in_eop     : IN  STD_LOGIC := '0';
    in_sync    : IN  STD_LOGIC := '0';
    
    in_select  : IN  STD_LOGIC_VECTOR(g_nof_output*ceil_log2(g_nof_input)-1 DOWNTO 0);
    
    out_data   : OUT STD_LOGIC_VECTOR(g_nof_output*g_symbol_w-1 DOWNTO 0);
    out_val    : OUT STD_LOGIC;         -- pipelined in_val
    out_sop    : OUT STD_LOGIC;         -- pipelined in_sop
    out_eop    : OUT STD_LOGIC;         -- pipelined in_eop
    out_sync   : OUT STD_LOGIC          -- pipelined in_sync
  );
END common_select_m_symbols;


ARCHITECTURE str OF common_select_m_symbols IS

  CONSTANT c_sel_w      : NATURAL := ceil_log2(g_nof_input);
  
  TYPE t_symbol_arr  IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(g_symbol_w-1 DOWNTO 0);
  TYPE t_select_arr  IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_sel_w-1 DOWNTO 0);
  
  SIGNAL in_data_arr    : t_symbol_arr(g_nof_input-1 DOWNTO 0);
  SIGNAL in_data_reg    : STD_LOGIC_VECTOR(in_data'RANGE);
  SIGNAL in_val_reg     : STD_LOGIC;
  SIGNAL in_sop_reg     : STD_LOGIC;
  SIGNAL in_eop_reg     : STD_LOGIC;
  SIGNAL in_sync_reg    : STD_LOGIC;
    
  SIGNAL in_select_arr  : t_select_arr(g_nof_output-1 DOWNTO 0);
  SIGNAL in_select_reg  : STD_LOGIC_VECTOR(in_select'RANGE);
  
  SIGNAL out_data_arr   : t_symbol_arr(g_nof_output-1 DOWNTO 0);
  SIGNAL out_val_arr    : STD_LOGIC_VECTOR(g_nof_output-1 DOWNTO 0);
  SIGNAL out_sop_arr    : STD_LOGIC_VECTOR(g_nof_output-1 DOWNTO 0);
  SIGNAL out_eop_arr    : STD_LOGIC_VECTOR(g_nof_output-1 DOWNTO 0);
  SIGNAL out_sync_arr   : STD_LOGIC_VECTOR(g_nof_output-1 DOWNTO 0);
  
BEGIN

  -- pipeline input
  u_pipe_in_data   : common_pipeline GENERIC MAP ("SIGNED", g_pipeline_in, 0, in_data'LENGTH,   in_data'LENGTH)   PORT MAP (rst, clk, '1', '0', '1', in_data,   in_data_reg);
  u_pipe_in_select : common_pipeline GENERIC MAP ("SIGNED", g_pipeline_in, 0, in_select'LENGTH, in_select'LENGTH) PORT MAP (rst, clk, '1', '0', '1', in_select, in_select_reg);
  
  u_pipe_in_val    : common_pipeline_sl GENERIC MAP (g_pipeline_in, 0, FALSE) PORT MAP (rst, clk, '1', '0', '1', in_val,  in_val_reg);
  u_pipe_in_sop    : common_pipeline_sl GENERIC MAP (g_pipeline_in, 0, FALSE) PORT MAP (rst, clk, '1', '0', '1', in_sop,  in_sop_reg);
  u_pipe_in_eop    : common_pipeline_sl GENERIC MAP (g_pipeline_in, 0, FALSE) PORT MAP (rst, clk, '1', '0', '1', in_eop,  in_eop_reg);
  u_pipe_in_sync   : common_pipeline_sl GENERIC MAP (g_pipeline_in, 0, FALSE) PORT MAP (rst, clk, '1', '0', '1', in_sync, in_sync_reg);

  -- Ease viewing the in_data in the Wave window by mapping it on in_data_arr
  gen_n : FOR I IN 0 TO g_nof_input-1 GENERATE
    in_data_arr(I) <= in_data_reg((I+1)*g_symbol_w-1 DOWNTO I*g_symbol_w);
  END GENERATE;
  
  gen_m : FOR I IN 0 TO g_nof_output-1 GENERATE
    in_select_arr(I) <= in_select_reg((I+1)*c_sel_w-1 DOWNTO I*c_sel_w);
    
    u_sel : ENTITY work.common_select_symbol
    GENERIC MAP (
      g_pipeline_in  => g_pipeline_in_m,
      g_pipeline_out => g_pipeline_out,
      g_nof_symbols  => g_nof_input,
      g_symbol_w     => g_symbol_w,
      g_sel_w        => c_sel_w
    )
    PORT MAP (
      rst        => rst,
      clk        => clk,
      
      in_data    => in_data_reg,
      in_val     => in_val_reg, 
      in_sop     => in_sop_reg, 
      in_eop     => in_eop_reg, 
      in_sync    => in_sync_reg,
      
      in_sel     => in_select_arr(I),
      out_sel    => OPEN,
      
      out_symbol => out_data_arr(I),
      out_val    => out_val_arr(I),       -- pipelined in_val
      out_sop    => out_sop_arr(I),       -- pipelined in_sop
      out_eop    => out_eop_arr(I),       -- pipelined in_eop
      out_sync   => out_sync_arr(I)       -- pipelined in_sync
    );
    
    out_data((I+1)*g_symbol_w-1 DOWNTO I*g_symbol_w) <= out_data_arr(I);
  END GENERATE;
  
  -- Use instance I=0 to pipeline the control
  out_val  <= out_val_arr(0);
  out_sop  <= out_sop_arr(0);
  out_eop  <= out_eop_arr(0);
  out_sync <= out_sync_arr(0);

END str;
