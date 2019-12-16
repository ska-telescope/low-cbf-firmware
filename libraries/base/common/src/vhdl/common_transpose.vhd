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

LIBRARY IEEE, common_lib;
USE IEEE.std_logic_1164.ALL;
USE common_lib.common_pkg.ALL;

-- Purpose: Transpose the g_nof_data symbols in g_nof_data in_data to
--                        g_nof_data symbols in g_nof_data out_data,
--          with support for interleaved address calculation via in_offset.
-- Description:
-- . Each in_data has g_nof_data symbols. After every g_nof_data in_data the
--   symbols in the g_nof_data by g_nof_data matrix transposed. 
-- . In parallel for each out_data the in_addr is incremented by 0, 1, ...,
--   or (g_nof_data-1) * in_offset. The in_offset can be set fixed via
--   g_addr_offset or dynamically via in_offset.
-- Remarks:

ENTITY common_transpose IS
  GENERIC (
    g_pipeline_shiftreg  : NATURAL := 0;
    g_pipeline_transpose : NATURAL := 0;
    g_pipeline_hold      : NATURAL := 0;
    g_pipeline_select    : NATURAL := 1;
    g_nof_data           : NATURAL := 4;
    g_data_w             : NATURAL := 16;  -- must be multiple of g_nof_data
    g_addr_w             : NATURAL := 9;
    g_addr_offset        : NATURAL := 0    -- default use fixed offset, in_offset * g_nof_data must fit in g_addr_w address range
  );
  PORT (
    rst        : IN  STD_LOGIC;
    clk        : IN  STD_LOGIC;
    
    in_offset  : IN  STD_LOGIC_VECTOR(g_addr_w-1 DOWNTO 0) := TO_UVEC(g_addr_offset, g_addr_w);
    in_addr    : IN  STD_LOGIC_VECTOR(g_addr_w-1 DOWNTO 0) := (OTHERS=>'0');
    in_data    : IN  STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    in_val     : IN  STD_LOGIC;
    in_eop     : IN  STD_LOGIC;
    
    out_addr   : OUT STD_LOGIC_VECTOR(g_addr_w-1 DOWNTO 0);
    out_data   : OUT STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    out_val    : OUT STD_LOGIC;
    out_eop    : OUT STD_LOGIC
  );
END common_transpose;


ARCHITECTURE str OF common_transpose IS

  CONSTANT c_sel_w          : NATURAL := ceil_log2(g_nof_data);
  
  CONSTANT c_nof_data_max   : NATURAL := 8;
  CONSTANT c_holdline_arr   : t_natural_arr(c_nof_data_max-1 DOWNTO 0) := (2, 2, 2, 2, 2, 2, 2, 1);
  
  CONSTANT c_pipeline_sel   : NATURAL := g_pipeline_transpose+g_pipeline_hold;
  
  SIGNAL offset_addr_vec  : STD_LOGIC_VECTOR(g_nof_data*g_addr_w-1 DOWNTO 0);
  
  SIGNAL sreg_addr_vec    : STD_LOGIC_VECTOR(g_nof_data*g_addr_w-1 DOWNTO 0);
  SIGNAL sreg_data_vec    : STD_LOGIC_VECTOR(g_nof_data*g_data_w-1 DOWNTO 0);
  SIGNAL sreg_val         : STD_LOGIC;
  SIGNAL sreg_eop         : STD_LOGIC;
  SIGNAL sreg_sel         : STD_LOGIC_VECTOR(c_sel_w-1 DOWNTO 0);
  SIGNAL sreg_full        : STD_LOGIC;
  
  SIGNAL add_addr_vec     : STD_LOGIC_VECTOR(g_nof_data*g_addr_w-1 DOWNTO 0);
  SIGNAL trans_data_vec   : STD_LOGIC_VECTOR(g_nof_data*g_data_w-1 DOWNTO 0);
  SIGNAL trans_full       : STD_LOGIC;
  
  SIGNAL hold_addr_vec    : STD_LOGIC_VECTOR(g_nof_data*g_addr_w-1 DOWNTO 0);
  SIGNAL hold_data_vec    : STD_LOGIC_VECTOR(g_nof_data*g_data_w-1 DOWNTO 0);
  SIGNAL hold_val         : STD_LOGIC;
  SIGNAL hold_eop         : STD_LOGIC;
  SIGNAL hold_sel         : STD_LOGIC_VECTOR(c_sel_w-1 DOWNTO 0);
  
BEGIN

  u_sreg_data : ENTITY common_lib.common_shiftreg
  GENERIC MAP (
    g_pipeline  => g_pipeline_shiftreg,
    g_flush_en  => TRUE,
    g_nof_dat   => g_nof_data,
    g_dat_w     => g_data_w
  )
  PORT MAP (
    rst          => rst,
    clk          => clk,
    
    in_dat       => in_data,
    in_val       => in_val,
    in_eop       => in_eop,
    
    out_data_vec => sreg_data_vec,
    out_cnt      => sreg_sel,
    
    out_val      => sreg_val,
    out_eop      => sreg_eop
  );
  
  u_sreg_addr : ENTITY common_lib.common_shiftreg
  GENERIC MAP (
    g_pipeline  => g_pipeline_shiftreg,
    g_flush_en  => TRUE,
    g_nof_dat   => g_nof_data,
    g_dat_w     => g_addr_w
  )
  PORT MAP (
    rst          => rst,
    clk          => clk,
    
    in_dat       => in_addr,
    in_val       => in_val,
    in_eop       => in_eop,
    
    out_data_vec => sreg_addr_vec
  );
  
  sreg_full <= '1' WHEN sreg_val='1' AND TO_UINT(sreg_sel)=0 ELSE '0';

  u_transpose_data : ENTITY common_lib.common_transpose_symbol
  GENERIC MAP (
    g_pipeline  => g_pipeline_transpose,
    g_nof_data  => g_nof_data,
    g_data_w    => g_data_w
  )
  PORT MAP (
    rst        => rst,
    clk        => clk,
    
    in_data    => sreg_data_vec,
    out_data   => trans_data_vec
  );
  
  gen_offsets : FOR I IN g_nof_data-1 DOWNTO 0 GENERATE
    offset_addr_vec((I+1)*g_addr_w-1 DOWNTO I*g_addr_w) <= TO_UVEC(I * TO_UINT(in_offset), g_addr_w);
  END GENERATE;
  
  u_add_addr : ENTITY common_lib.common_add_symbol
  GENERIC MAP (
    g_pipeline    => g_pipeline_transpose,
    g_nof_symbols => g_nof_data,
    g_symbol_w    => g_addr_w
  )
  PORT MAP (
    rst        => rst,
    clk        => clk,
    
    in_a       => offset_addr_vec,
    in_b       => sreg_addr_vec,
    
    out_data   => add_addr_vec
  );
  
  u_trans_full : ENTITY common_lib.common_pipeline_sl
  GENERIC MAP (
    g_pipeline => g_pipeline_transpose
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => sreg_full,
    out_dat => trans_full
  );
  
  u_hold_data : ENTITY common_lib.common_shiftreg_symbol
  GENERIC MAP (
    g_shiftline_arr => c_holdline_arr(g_nof_data-1 DOWNTO 0),
    g_pipeline      => g_pipeline_hold,
    g_flush_en      => FALSE,
    g_nof_symbols   => g_nof_data,
    g_symbol_w      => g_data_w
  )
  PORT MAP (
    rst         => rst,
    clk         => clk,
    
    in_data     => trans_data_vec,
    in_val      => trans_full,
    
    out_data    => hold_data_vec
  );
  
  u_hold_addr : ENTITY common_lib.common_shiftreg_symbol
  GENERIC MAP (
    g_shiftline_arr => c_holdline_arr(g_nof_data-1 DOWNTO 0),
    g_pipeline      => g_pipeline_hold,
    g_flush_en      => FALSE,
    g_nof_symbols   => g_nof_data,
    g_symbol_w      => g_addr_w
  )
  PORT MAP (
    rst         => rst,
    clk         => clk,
    
    in_data     => add_addr_vec,
    in_val      => trans_full,
    
    out_data    => hold_addr_vec
  );
  
  u_hold_sel : ENTITY common_lib.common_pipeline
  GENERIC MAP (
    g_pipeline  => c_pipeline_sel,
    g_in_dat_w  => c_sel_w,
    g_out_dat_w => c_sel_w
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => sreg_sel,
    out_dat => hold_sel
  );
  
  u_hold_val : ENTITY common_lib.common_pipeline_sl
  GENERIC MAP (
    g_pipeline => c_pipeline_sel
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => sreg_val,
    out_dat => hold_val
  );
  
  u_hold_eop : ENTITY common_lib.common_pipeline_sl
  GENERIC MAP (
    g_pipeline => c_pipeline_sel
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => sreg_eop,
    out_dat => hold_eop
  );
  
  u_output_data : ENTITY common_lib.common_select_symbol
  GENERIC MAP (
    g_pipeline_in  => 0,
    g_pipeline_out => g_pipeline_select,
    g_nof_symbols  => g_nof_data,
    g_symbol_w     => g_data_w,
    g_sel_w        => c_sel_w
  )
  PORT MAP (
    rst        => rst,
    clk        => clk,
    
    in_data    => hold_data_vec,
    in_val     => hold_val,
    in_eop     => hold_eop,
    
    in_sel     => hold_sel,
    
    out_symbol => out_data,
    out_val    => out_val,
    out_eop    => out_eop
  );
    
  u_output_addr : ENTITY common_lib.common_select_symbol
  GENERIC MAP (
    g_pipeline_in  => 0,
    g_pipeline_out => g_pipeline_select,
    g_nof_symbols  => g_nof_data,
    g_symbol_w     => g_addr_w,
    g_sel_w        => c_sel_w
  )
  PORT MAP (
    rst        => rst,
    clk        => clk,
    
    in_data    => hold_addr_vec,
    in_val     => hold_val,
    in_eop     => hold_eop,
    
    in_sel     => hold_sel,
    
    out_symbol => out_addr
  );
  
END str;
