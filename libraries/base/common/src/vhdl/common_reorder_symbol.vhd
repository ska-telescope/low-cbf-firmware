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

-- Purpose: Reorder symbols from input data stream
--
-- Description:
--   The in_data is a concatenation of g_nof_input symbols. 
--   The out_data is a concatenation of g_nof_output symbols.
--   The symbols are each g_symbol_w bits wide.
--   Each input symbol can be directed to each output symbol by making the 
--   appropriate settings via in_select.
--   Each stage is constructed of 2-input-2-output reorder cells.
--   Each stage can be pipelined or not dependent on g_pipeline_arr.
--
-- Two-input-two-output reorder:
--   The function func_reorder2() performs the mapping of two inputs data to
--   two output data. When select = '0' the pass on the own input else pass
--   on the other output. The short notation for func_reorder2() is X. The
--   scheme below shows the connections for X dependent on the two select bits.
--
--      input[1]  ----   -\--   . /-   -\/-  output[1]
--      input[0]  ----   . \-   -/--   -/\-  output[0]
--   select[1:0]  "00"   "01"   "10"   "11"
--                = 0    = 1    = 2    = 3
--
--   Note that when select is "00" or "11" the inputs are passed on or swapped,
--   else when select is "01" or "10" then one of the inputs is duplicated and
--   the other input is then not passed on.
--
--   The function func_common_reorder2_get_select() gets the select setting
--   from select_2arr for the reorder2 cell.
--
-- Example:
--   The example shows how the in_data and out_data are mapped on to a general
--   two-dimensional reorder array that maps c_N inputs to c_N outputs using
--   c_N stages.
-- 
--    select_2arr(I)(K)
--   reorder_2arr(I)(J) for c_N = 4
--   
--         row J
--         0  [4] . . . . . . [4]  --> OPEN
--                     X   X       --> these X will get optimized to pipeline
--   in_data  [3] . . . . . . [3]  out_data
--                   X1  X4
--            [2] . . . . . . [2]
--                     X2  X5
--            [1] . . . . . . [1]
--                   X0  X3        --> the X# number is the index in in_select[]
--            [0] . . . . . . [0]
--                     X   X       --> these X will get optimized to pipeline
--         0 [-1] . . . . . . [-1] --> OPEN
--               -1 0 1 2 3 4
--                  Stage I        --> the stage number I is the index in g_pipeline_arr
--
-- Remarks:
-- . The input data maps to stage -1 and gets input pipelined to stage 0. The
--   output data maps to stage c_N.
-- . If g_nof_input /= g_nof_output then some in_select bits will be don't
--   care, because the in_select array is dimensioned for c_N.
-- . The implementation makes use of the fact that synthesis will optimize 
--   away redundant logic. Therefore row -1 and row c_N can be used in 
--   reorder_2arr whereby the X will reduce to wires. Similar the in_select
--   bits that are not used in subsequent stages will get removed from the
--   pipeline select_2arr.


ENTITY common_reorder_symbol IS
  GENERIC (
    g_nof_input    : NATURAL := 4;
    g_nof_output   : NATURAL := 4;
    g_symbol_w     : NATURAL := 16;
    g_select_w     : NATURAL := 2;                      -- fixed 2 bit per X select
    g_nof_select   : NATURAL := 6;                      -- size must match c_N*(c_N-1)/2
    g_pipeline_arr : t_natural_arr := array_init(0, 5)  -- range must fit [0:c_N]
  );
  PORT (
    rst        : IN  STD_LOGIC;
    clk        : IN  STD_LOGIC;
    
    in_data    : IN  STD_LOGIC_VECTOR(g_nof_input*g_symbol_w-1 DOWNTO 0);
    in_val     : IN  STD_LOGIC := '0';
    in_sop     : IN  STD_LOGIC := '0';
    in_eop     : IN  STD_LOGIC := '0';
    in_sync    : IN  STD_LOGIC := '0';
    
    in_select  : IN  STD_LOGIC_VECTOR(g_nof_select*g_select_w-1 DOWNTO 0);
    
    out_data   : OUT STD_LOGIC_VECTOR(g_nof_output*g_symbol_w-1 DOWNTO 0);
    out_val    : OUT STD_LOGIC;         -- pipelined in_val
    out_sop    : OUT STD_LOGIC;         -- pipelined in_sop
    out_eop    : OUT STD_LOGIC;         -- pipelined in_eop
    out_sync   : OUT STD_LOGIC          -- pipelined in_sync
  );
END common_reorder_symbol;


ARCHITECTURE rtl OF common_reorder_symbol IS

  CONSTANT c_N                           : NATURAL := largest(g_nof_input, g_nof_output);  -- nof stages of the reorder network
  
  CONSTANT c_pipeline_arr                : t_natural_arr(0 TO c_N) := g_pipeline_arr;      -- force range [0:c_N]
  CONSTANT c_total_pipeline              : NATURAL := func_sum(c_pipeline_arr);
  
  CONSTANT c_nof_reorder2_total          : NATURAL := c_N*(c_N-1)/2;  -- = g_nof_select

  TYPE t_symbol_arr  IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(g_symbol_w-1 DOWNTO 0);   -- one stage
  TYPE t_symbol_2arr IS ARRAY (INTEGER RANGE <>) OF t_symbol_arr(c_N DOWNTO -1);               -- all stages
  TYPE t_select_2arr IS ARRAY (INTEGER RANGE <>) OF t_natural_arr(g_nof_select-1 DOWNTO 0);    -- all stages
  
  -- Perform the basic two port reorder cell function, see description section for explanation
  FUNCTION func_reorder2(data : t_symbol_arr(1 DOWNTO 0); sel : NATURAL) RETURN t_symbol_arr IS
    VARIABLE v_sel   : STD_LOGIC_VECTOR(1 DOWNTO 0) := TO_UVEC(sel, 2);
    VARIABLE v_data  : t_symbol_arr(1 DOWNTO 0);
  BEGIN
    v_data := data;
    IF v_sel(1)='1' THEN v_data(1) := data(0); END IF;
    IF v_sel(0)='1' THEN v_data(0) := data(1); END IF;
    RETURN v_data;
  END func_reorder2;
  
  SIGNAL select_2arr       : t_select_2arr(-1 TO c_N) := (OTHERS=>(OTHERS=>0));
  SIGNAL reorder_2arr      : t_symbol_2arr(-1 TO c_N) := (OTHERS=>(OTHERS=>(OTHERS=>'0')));
  SIGNAL nxt_reorder_2arr  : t_symbol_2arr( 1 TO c_N) := (OTHERS=>(OTHERS=>(OTHERS=>'0')));
  
BEGIN

  ------------------------------------------------------------------------------
  -- Map the input to stage I=-1 with optional input pipelining to stage I=0
  ------------------------------------------------------------------------------
  
  -- in_data
  gen_in_data : FOR J IN 0 TO g_nof_input-1 GENERATE
    reorder_2arr(-1)(J) <= in_data((J+1)*g_symbol_w-1 DOWNTO J*g_symbol_w);
    
    -- optional input pipelining
    u_pipe_input : ENTITY work.common_pipeline
    GENERIC MAP (
      g_pipeline   => c_pipeline_arr(0),
      g_in_dat_w   => g_symbol_w,
      g_out_dat_w  => g_symbol_w
    )
    PORT MAP (
      rst     => rst,
      clk     => clk,
      in_dat  => reorder_2arr(-1)(J),
      out_dat => reorder_2arr(0)(J)
    );
  END GENERATE;

  -- in_select
  gen_in_select : FOR K IN 0 TO g_nof_select-1 GENERATE
    -- convert in_select slv to integer array
    select_2arr(-1)(K) <= TO_UINT(in_select((K+1)*g_select_w-1 DOWNTO K*g_select_w));
    
    -- align in_select to the optional input pipelining
    u_pipe_input : ENTITY work.common_pipeline_natural
    GENERIC MAP (
      g_pipeline => c_pipeline_arr(0),
      g_dat_w    => g_select_w
    )
    PORT MAP (
      rst     => rst,
      clk     => clk,
      in_dat  => select_2arr(-1)(K),
      out_dat => select_2arr(0)(K)
    );
  END GENERATE;
    
  
  ------------------------------------------------------------------------------
  -- Reorder network for c_N inputs to the c_N outputs
  ------------------------------------------------------------------------------
  
  -- stage I=1:c_N
  gen_stage : FOR I IN 1 TO c_N GENERATE
    gen_row : FOR J IN 0 TO c_N GENERATE
      -- generate the 2-input reorder cells for each stage
      gen_reorder2 : IF func_common_reorder2_is_there(I, J) GENERATE
        nxt_reorder_2arr(I)(J DOWNTO J-1) <= func_reorder2(reorder_2arr(I-1)(J DOWNTO J-1), func_common_reorder2_get_select(I, J, c_N, select_2arr(I-1)));
      END GENERATE;
      
      -- optional pipelining per reorder stage
      u_pipe_stage : ENTITY work.common_pipeline
      GENERIC MAP (
        g_pipeline   => c_pipeline_arr(I),
        g_in_dat_w   => g_symbol_w,
        g_out_dat_w  => g_symbol_w
      )
      PORT MAP (
        rst     => rst,
        clk     => clk,
        in_dat  => nxt_reorder_2arr(I)(J),
        out_dat => reorder_2arr(I)(J)
      );
    END GENERATE;
    
    -- align in_select to the optional pipelining per reorder stage
    gen_select : FOR K IN 0 TO g_nof_select-1 GENERATE
      u_pipe_stage : ENTITY work.common_pipeline_natural
      GENERIC MAP (
        g_pipeline => c_pipeline_arr(I),
        g_dat_w    => g_select_w
      )
      PORT MAP (
        rst     => rst,
        clk     => clk,
        in_dat  => select_2arr(I-1)(K),
        out_dat => select_2arr(I)(K)
      );
    END GENERATE;
  END GENERATE;
  
  
  ------------------------------------------------------------------------------
  -- Map the stage I=c_N to the output
  ------------------------------------------------------------------------------
  
  gen_output : FOR J IN 0 TO g_nof_output-1 GENERATE
    out_data((J+1)*g_symbol_w-1 DOWNTO J*g_symbol_w) <= reorder_2arr(c_N)(J);
  END GENERATE;
  
  
  ------------------------------------------------------------------------------
  -- Pipeline the optional data control lines
  ------------------------------------------------------------------------------
  
  u_out_val : ENTITY work.common_pipeline_sl
  GENERIC MAP (
    g_pipeline => c_total_pipeline
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => in_val,
    out_dat => out_val
  );

  u_out_sop : ENTITY work.common_pipeline_sl
  GENERIC MAP (
    g_pipeline => c_total_pipeline
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => in_sop,
    out_dat => out_sop
  );
  
  u_out_eop : ENTITY work.common_pipeline_sl
  GENERIC MAP (
    g_pipeline => c_total_pipeline
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => in_eop,
    out_dat => out_eop
  );
  
  u_out_sync : ENTITY work.common_pipeline_sl
  GENERIC MAP (
    g_pipeline => c_total_pipeline
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => in_sync,
    out_dat => out_sync
  );

END rtl;
