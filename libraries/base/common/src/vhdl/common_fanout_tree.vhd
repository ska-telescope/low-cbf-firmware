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

-- Purpose: Parallel fanout tree.
-- Description:
-- . Pipelined fanout of 1 input to g_nof_output.
-- . Suppose g_nof_output_per_cell=2 and g_nof_stages=3, so g_nof_output <=
--   g_nof_output_per_cell**g_nof_stages = c_nof_outputs = 8.
--
--   The pipeline fanout cell for g_nof_output_per_cell=2 is:
--
--                      out
--            .  1 -->  [1
--           in  0 -->   0]
--
--   The pipeline stage diagram for g_nof_stages=3 consists of 1+2+4=7 fanout
--   cells:
--                              out  
--            .  .  .  111  --> [7
--        3   .  .  .  110  -->  6
--            .  .  .  101  -->  5
--        2   .  .  .  100  -->  4
--            .  .  11 011  -->  3
--        1   .  .  10 010  -->  2
--            .  1  01 001  -->  1
--        0  in  0  00 000  -->  0]
--   cell i
--   stage j -1  0   1   2
--
--   The binary numbers at each stage indicate the fanout trajectory from input
--   to outputs. Stage -1 is the input data.
--   Internally define c_nof_outputs >= g_nof_output. Synthesis will optimise
--   away any unused outputs c_nof_outputs-1 DOWNTO g_nof_output.
--
--   The g_cell_pipeline_arr and g_cell_pipeline_factor_arr together define the
--   pipelining per cell as calculated by func_output_pipelining. In practise
--   this provides sufficient freedom and ease for defining the entire fanout
--   pipelining scheme.
--
--   Pipeline examples:
--    
--   . Same number of pipeline cycles for all g_nof_output
--       g_cell_pipeline_factor_arr = (1, 1, 1)
--       g_cell_pipeline_arr        = (1, 1)
--   . Same number of pipeline cycles for all g_nof_output, but with wires
--     so no pipelining at somes stages use:
--       g_cell_pipeline_factor_arr = (1, 0, 1)
--       g_cell_pipeline_arr        = (1, 1)
--   . Pipelining the g_nof_output by g_nof_output-1:0 cycles:
--       g_cell_pipeline_factor_arr = (1, 2, 4)
--       g_cell_pipeline_arr        = (1, 0)
--
-- Remarks:
-- . Alternatively a matrix g_pipeline_mat could be defined with dimensions
--   g_nof_stages * g_nof_outputs to have complete freedom for defining the
--   pipelining.

ENTITY common_fanout_tree IS
  GENERIC (
    g_nof_stages                : POSITIVE := 1;   -- >= 1
    g_nof_output_per_cell       : POSITIVE := 1;   -- >= 1
    g_nof_output                : POSITIVE := 1;   -- >= 1 and <= g_nof_output_per_cell**g_nof_stages
    g_cell_pipeline_factor_arr  : t_natural_arr;   -- range: g_nof_stages-1 DOWNTO 0, stage g_nof_stages-1 is output stage. Value: stage factor to multiply with g_cell_pipeline_arr
    g_cell_pipeline_arr         : t_natural_arr;   -- range: g_nof_output_per_cell-1 DOWNTO 0. Value: 0 for wires, >0 for register stages
    g_dat_w                     : NATURAL := 8
  );
  PORT (
    clk           : IN  STD_LOGIC;
    clken         : IN  STD_LOGIC := '1';
    in_en         : IN  STD_LOGIC := '1';
    in_val        : IN  STD_LOGIC := '1';
    in_dat        : IN  STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    out_en_vec    : OUT STD_LOGIC_VECTOR(g_nof_output        -1 DOWNTO 0);
    out_val_vec   : OUT STD_LOGIC_VECTOR(g_nof_output        -1 DOWNTO 0);
    out_dat_vec   : OUT STD_LOGIC_VECTOR(g_nof_output*g_dat_w-1 DOWNTO 0)
  );
END common_fanout_tree;

ARCHITECTURE str OF common_fanout_tree IS

  CONSTANT c_nof_output               : NATURAL := g_nof_output_per_cell**g_nof_stages;
  
  -- Define t_natural_arr range
  CONSTANT c_cell_pipeline_factor_arr : t_natural_arr(g_nof_stages-1 DOWNTO 0)          := g_cell_pipeline_factor_arr;  -- value: stage factor to multiply with g_cell_pipeline_arr
  CONSTANT c_cell_pipeline_arr        : t_natural_arr(g_nof_output_per_cell-1 DOWNTO 0) := g_cell_pipeline_arr;         -- value: 0 for wires, >0 for register stages
  
  TYPE t_stage_dat_vec_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_nof_output*g_dat_w-1 DOWNTO 0);
  TYPE t_stage_sl_vec_arr  IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_nof_output        -1 DOWNTO 0);
  
  SIGNAL stage_en_vec_arr  : t_stage_sl_vec_arr( -1 TO g_nof_stages-1) := (OTHERS=>(OTHERS=>'0'));
  SIGNAL stage_val_vec_arr : t_stage_sl_vec_arr( -1 TO g_nof_stages-1) := (OTHERS=>(OTHERS=>'0'));
  SIGNAL stage_dat_vec_arr : t_stage_dat_vec_arr(-1 TO g_nof_stages-1) := (OTHERS=>(OTHERS=>'0'));
  
BEGIN

  gen_tree : IF g_nof_output > 1 GENERATE
    -- Input wires
    stage_en_vec_arr( -1)(0)                  <= in_en;
    stage_val_vec_arr(-1)(0)                  <= in_val;
    stage_dat_vec_arr(-1)(g_dat_w-1 DOWNTO 0) <= in_dat;
    
    -- Fanout tree
    gen_stage : FOR j IN 0 TO g_nof_stages-1 GENERATE
      gen_cell : FOR i IN 0 TO g_nof_output_per_cell**j-1 GENERATE
        -- output k = 
        u_fanout : ENTITY work.common_fanout
        GENERIC MAP (
          g_nof_output   => g_nof_output_per_cell,
          g_pipeline_arr => c_cell_pipeline_factor_arr(j) * c_cell_pipeline_arr,
          g_dat_w        => g_dat_w
        )
        PORT MAP (
          clk         => clk,
          clken       => clken,
          in_en       => stage_en_vec_arr( j-1)(                       i),
          in_val      => stage_val_vec_arr(j-1)(                       i),
          in_dat      => stage_dat_vec_arr(j-1)((i+1)*g_dat_w-1 DOWNTO i*g_dat_w),
          out_en_vec  => stage_en_vec_arr( j)((i+1)*g_nof_output_per_cell        -1 DOWNTO i*g_nof_output_per_cell),
          out_val_vec => stage_val_vec_arr(j)((i+1)*g_nof_output_per_cell        -1 DOWNTO i*g_nof_output_per_cell),
          out_dat_vec => stage_dat_vec_arr(j)((i+1)*g_nof_output_per_cell*g_dat_w-1 DOWNTO i*g_nof_output_per_cell*g_dat_w)
        );
      END GENERATE;
    END GENERATE;
    
    out_en_vec  <= stage_en_vec_arr( g_nof_stages-1)(g_nof_output        -1 DOWNTO 0);
    out_val_vec <= stage_val_vec_arr(g_nof_stages-1)(g_nof_output        -1 DOWNTO 0);
    out_dat_vec <= stage_dat_vec_arr(g_nof_stages-1)(g_nof_output*g_dat_w-1 DOWNTO 0);
  END GENERATE;  -- gen_tree

  no_tree : IF g_nof_output = 1 GENERATE
    u_reg : ENTITY work.common_fanout
    GENERIC MAP (
      g_nof_output   => 1,
      g_pipeline_arr => c_cell_pipeline_factor_arr(0) * c_cell_pipeline_arr,
      g_dat_w        => g_dat_w
    )
    PORT MAP (
      clk         => clk,
      clken       => clken,
      in_en       => in_en,
      in_val      => in_val,
      in_dat      => in_dat,
      out_en_vec  => out_en_vec,
      out_val_vec => out_val_vec,
      out_dat_vec => out_dat_vec
    );  
  END GENERATE;  -- no_tree
  
END str;
