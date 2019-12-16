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
USE IEEE.NUMERIC_STD.ALL;
USE work.common_pkg.ALL;

-- Purpose: Interleave g_nof_in inputs into one output stream based on g_block_size.
-- Description: 
--   The input streams are concatenated into one SLV. The incoming streams are
--   sequentially multiplexed onto the output, starting from input 0. During 
--   multiplexing of the current input, the other input(s) are buffered and 
--   will be put on the output after g_block_size valid words on the current 
--   input.
-- Remarks:
-- . One valid input applies to all input data streams;
-- . The user must take care of the correct valid/gap ratio on the inputs.

ENTITY common_interleave IS
  GENERIC (
    g_nof_in     : NATURAL; -- >= 2
    g_dat_w      : NATURAL;
    g_block_size : NATURAL
 );
  PORT (
    clk         : IN  STD_LOGIC;
    rst         : IN  STD_LOGIC;

    in_dat      : IN  STD_LOGIC_VECTOR(g_nof_in*g_dat_w-1 DOWNTO 0);
    in_val      : IN  STD_LOGIC;

    out_dat     : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    out_val     : OUT STD_LOGIC
  );
END;

ARCHITECTURE rtl OF common_interleave IS

  TYPE t_dat_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
  TYPE t_val_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC;

  -----------------------------------------------------------------------------
  -- Array of block register inputs
  -----------------------------------------------------------------------------
  SIGNAL bkr_in_dat_arr : t_dat_arr(g_nof_in-1 DOWNTO 0);

  -----------------------------------------------------------------------------
  -- Array of block register outputs
  -----------------------------------------------------------------------------
  SIGNAL bkr_out_dat_arr : t_dat_arr(g_nof_in-1 DOWNTO 0);
  SIGNAL bkr_out_val_arr : STD_LOGIC_VECTOR(g_nof_in-1 DOWNTO 0);
 
  SIGNAL piped_bkr_out_dat_arr : t_dat_arr(g_nof_in-1 DOWNTO 0);
  SIGNAL piped_bkr_out_val_arr : STD_LOGIC_VECTOR(g_nof_in-1 DOWNTO 0);

  -----------------------------------------------------------------------------
  -- Array of multiplexer inputs
  -----------------------------------------------------------------------------
  SIGNAL mux_in_dat_arr : t_dat_arr(g_nof_in-1 DOWNTO 0);
  SIGNAL nxt_mux_in_dat_arr : t_dat_arr(g_nof_in-1 DOWNTO 0);

  -----------------------------------------------------------------------------
  -- Concatenated multiplexer inputs
  -----------------------------------------------------------------------------
  SIGNAL mux_in_concat_dat_arr : STD_LOGIC_VECTOR(g_nof_in*g_dat_w-1 DOWNTO 0);

  -----------------------------------------------------------------------------
  -- Multiplexer input selection control
  -----------------------------------------------------------------------------
  CONSTANT c_mux_in_sel_w : NATURAL := ceil_log2(g_nof_in);

  SIGNAL mux_in_sel       : STD_LOGIC_VECTOR(c_mux_in_sel_w-1 DOWNTO 0);
  SIGNAL nxt_mux_in_sel   : STD_LOGIC_VECTOR(c_mux_in_sel_w-1 DOWNTO 0);
  SIGNAL sch_mux_in_sel   : STD_LOGIC_VECTOR(c_mux_in_sel_w-1 DOWNTO 0);

  CONSTANT c_mux_val_cnt_w  : NATURAL := ceil_log2(g_block_size+1);
  SIGNAL mux_val_cnt        : STD_LOGIC_VECTOR(c_mux_val_cnt_w-1 DOWNTO 0);
  SIGNAL nxt_mux_val_cnt    : STD_LOGIC_VECTOR(c_mux_val_cnt_w-1 DOWNTO 0);

  SIGNAL mux_in_val       : STD_LOGIC;
  SIGNAL nxt_mux_in_val   : STD_LOGIC;

BEGIN

  -----------------------------------------------------------------------------
  -- Wire SLV -> Array
  -----------------------------------------------------------------------------
  gen_wire_in_dat: FOR i IN 0 TO g_nof_in-1 GENERATE
    bkr_in_dat_arr(i) <= in_dat( i*g_dat_w+g_dat_w -1 DOWNTO i*g_dat_w);
  END GENERATE;

  -----------------------------------------------------------------------------
  -- Block registers output bursts of g_block_size data words at a time. To
  -- offset these blocks  in time with respect to each other the outputs are 
  -- incrementally pipelined.
  -----------------------------------------------------------------------------
  gen_blockregs: FOR i IN 0 TO g_nof_in-1 GENERATE
    u_blockreg : ENTITY work.common_blockreg
    GENERIC MAP (
      g_block_size=> g_block_size,
      g_dat_w     => g_dat_w
    )
    PORT MAP (
      rst          => rst,
      clk          => clk,
      
      in_dat       => bkr_in_dat_arr(i),
      in_val       => in_val,

      out_dat      => bkr_out_dat_arr(i),
      out_val      => bkr_out_val_arr(i)
      );

    u_dat_block_offset_pipe : ENTITY work.common_pipeline
    GENERIC MAP (
      g_pipeline  => i*g_block_size,
      g_in_dat_w  => g_dat_w,
      g_out_dat_w => g_dat_w
    )
    PORT MAP (
      rst     => rst,
      clk     => clk,
      in_dat  => bkr_out_dat_arr(i),
      out_dat => piped_bkr_out_dat_arr(i)
    );

    u_val_block_offset_pipe : ENTITY work.common_pipeline
    GENERIC MAP (
      g_pipeline  => i*g_block_size,
      g_in_dat_w  => 1,
      g_out_dat_w => 1
    )
    PORT MAP (
      rst     => rst,
      clk     => clk,
      in_dat  => slv(bkr_out_val_arr(i)),
      sl(out_dat) => piped_bkr_out_val_arr(i)
    );

  END GENERATE;

  -----------------------------------------------------------------------------
  -- Array -> concatenated SLV conversion
  -----------------------------------------------------------------------------
  gen_arr_to_concat : FOR i IN 0 TO g_nof_in-1 GENERATE
    mux_in_concat_dat_arr(i*g_dat_w+g_dat_w -1 DOWNTO i*g_dat_w) <= mux_in_dat_arr(i);
  END GENERATE;

  -----------------------------------------------------------------------------
  -- The multiplexer
  -----------------------------------------------------------------------------
  u_mux : ENTITY work.common_multiplexer
  GENERIC MAP (
    g_nof_in => g_nof_in,
    g_dat_w  => g_dat_w
  )
  PORT MAP (
    rst        => rst,
    clk        => clk,

    in_sel     => mux_in_sel,    
    in_dat     => mux_in_concat_dat_arr,
    in_val     => mux_in_val,
    
    out_dat    => out_dat,
    out_val    => out_val
  );

  -----------------------------------------------------------------------------
  -- Multiplexer input selection
  -----------------------------------------------------------------------------
  -- Scheduled input
  sch_mux_in_sel <= INCR_UVEC(mux_in_sel, 1) WHEN UNSIGNED(mux_in_sel)<g_nof_in-1 ELSE (OTHERS=>'0'); 

  p_nxt_mux_in_sel : PROCESS(mux_in_sel, mux_val_cnt, sch_mux_in_sel, piped_bkr_out_val_arr, piped_bkr_out_dat_arr)
  BEGIN
    nxt_mux_in_sel     <= mux_in_sel;
    nxt_mux_val_cnt    <= mux_val_cnt;  

    nxt_mux_in_dat_arr <= piped_bkr_out_dat_arr;
    nxt_mux_in_val     <= orv(piped_bkr_out_val_arr);

    IF orv(piped_bkr_out_val_arr)='1' THEN
      IF UNSIGNED(mux_val_cnt) = g_block_size THEN
        nxt_mux_val_cnt <= TO_UVEC(1, c_mux_val_cnt_w);
        nxt_mux_in_sel  <= sch_mux_in_sel;
      ELSE
        nxt_mux_val_cnt <= INCR_UVEC(mux_val_cnt, 1);
      END IF;
    ELSE
      IF UNSIGNED(mux_val_cnt) = g_block_size THEN
        nxt_mux_val_cnt <= TO_UVEC(0, c_mux_val_cnt_w);
        nxt_mux_in_sel  <= sch_mux_in_sel;
      END IF;
    END IF;
  END PROCESS;

  -----------------------------------------------------------------------------
  -- Registers
  -----------------------------------------------------------------------------
  p_reg : PROCESS(rst, clk)
  BEGIN
    IF rst='1' THEN
      mux_in_sel     <= (OTHERS=>'0');
      mux_in_val     <= '0';
      mux_in_dat_arr  <= (OTHERS=>(OTHERS=>'0'));
      mux_val_cnt    <= (OTHERS=>'0');
    ELSIF rising_edge(clk) THEN
      mux_in_sel     <= nxt_mux_in_sel;
      mux_in_val     <= nxt_mux_in_val;
      mux_in_dat_arr <= nxt_mux_in_dat_arr;
      mux_val_cnt    <= nxt_mux_val_cnt;
    END IF;
  END PROCESS;

END rtl;
