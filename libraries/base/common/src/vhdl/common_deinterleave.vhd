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

-- Purpose: Deinterleave input into g_nof_out output streams based on g_block_size.
-- Description: 
--   The output streams are concatenated into one SLV. Only one output is active 
--   at a time. The active output is selected automatically and incrementally, 
--   starting with output 0. The next output is selected after g_block_size 
--   valid words on the currently selected output.
-- Remarks:

ENTITY common_deinterleave IS
  GENERIC (
    g_nof_out    : NATURAL;
    g_dat_w      : NATURAL;
    g_block_size : NATURAL;
    g_align_out  : BOOLEAN := FALSE 
 );
  PORT (
    clk         : IN  STD_LOGIC;
    rst         : IN  STD_LOGIC;

    in_dat      : IN  STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    in_val      : IN  STD_LOGIC;

    out_dat     : OUT STD_LOGIC_VECTOR(g_nof_out*g_dat_w-1 DOWNTO 0);
    out_val     : OUT STD_LOGIC_VECTOR(g_nof_out-1 DOWNTO 0)
  );
END;

ARCHITECTURE rtl OF common_deinterleave IS
  
  -----------------------------------------------------------------------------
  -- Multiplexer input selection control
  -----------------------------------------------------------------------------
  CONSTANT c_demux_out_sel_w : NATURAL := ceil_log2(g_nof_out);

  SIGNAL demux_out_sel       : STD_LOGIC_VECTOR(c_demux_out_sel_w-1 DOWNTO 0);
  SIGNAL nxt_demux_out_sel   : STD_LOGIC_VECTOR(c_demux_out_sel_w-1 DOWNTO 0);
  SIGNAL sch_demux_out_sel   : STD_LOGIC_VECTOR(c_demux_out_sel_w-1 DOWNTO 0);

  SIGNAL demux_out_dat       : STD_LOGIC_VECTOR(g_nof_out*g_dat_w-1 DOWNTO 0);
  SIGNAL demux_out_val       : STD_LOGIC_VECTOR(g_nof_out-1 DOWNTO 0);

  CONSTANT c_demux_val_cnt_w  : NATURAL := ceil_log2(g_block_size+1);
  SIGNAL demux_val_cnt        : STD_LOGIC_VECTOR(c_demux_val_cnt_w-1 DOWNTO 0);
  SIGNAL nxt_demux_val_cnt    : STD_LOGIC_VECTOR(c_demux_val_cnt_w-1 DOWNTO 0);
  
BEGIN

  u_demux : ENTITY work.common_demultiplexer
  GENERIC MAP (
    g_nof_out => g_nof_out,
    g_dat_w   => g_dat_w
  )
  PORT MAP (
    in_dat     => in_dat,
    in_val     => in_val,

    out_sel    => demux_out_sel,            
    out_dat    => demux_out_dat,
    out_val    => demux_out_val
  );

  -----------------------------------------------------------------------------
  -- Demultiplexer output selection
  -----------------------------------------------------------------------------
  -- Scheduled input
  sch_demux_out_sel <= INCR_UVEC(demux_out_sel, 1) WHEN UNSIGNED(demux_out_sel)<g_nof_out-1 ELSE (OTHERS=>'0'); 

  p_nxt_demux_out_sel : PROCESS(in_val, demux_out_sel, demux_val_cnt, sch_demux_out_sel)
  BEGIN
    nxt_demux_out_sel    <= demux_out_sel;
    nxt_demux_val_cnt    <= demux_val_cnt;  

    IF in_val='1' THEN
      IF UNSIGNED(demux_val_cnt) = g_block_size-1 THEN
        nxt_demux_val_cnt <= TO_UVEC(0, c_demux_val_cnt_w);
        nxt_demux_out_sel  <= sch_demux_out_sel;
      ELSE
        nxt_demux_val_cnt <= INCR_UVEC(demux_val_cnt, 1);
      END IF;
    END IF;
  END PROCESS;

  -----------------------------------------------------------------------------
  -- Registers
  -----------------------------------------------------------------------------
  p_reg : PROCESS(rst, clk)
  BEGIN
    IF rst='1' THEN
      demux_out_sel    <= (OTHERS=>'0');
      demux_val_cnt    <= (OTHERS=>'0');
    ELSIF rising_edge(clk) THEN
      demux_out_sel    <= nxt_demux_out_sel;
      demux_val_cnt    <= nxt_demux_val_cnt;
    END IF;
  END PROCESS;

  -----------------------------------------------------------------------------
  -- Forward the deinterleaved data to the outputs without alignment
  -----------------------------------------------------------------------------
  gen_no_align: IF g_align_out = FALSE GENERATE
    out_dat <= demux_out_dat;
    out_val <= demux_out_val;
  END GENERATE;

  -----------------------------------------------------------------------------
  -- Align the output streams by adding pipeline stages
  -----------------------------------------------------------------------------
  gen_align_out: IF g_align_out = TRUE GENERATE
    gen_inter: FOR i IN 0 TO g_nof_out-1 GENERATE
      u_shiftreg : ENTITY work.common_shiftreg
      GENERIC MAP (
        g_pipeline  => g_nof_out*g_block_size - (i+1)*g_block_size,
        g_nof_dat   => 1, 
        g_dat_w     => g_dat_w
      )
      PORT MAP (
        rst          => rst,
        clk          => clk,
        
        in_dat       => demux_out_dat(i*g_dat_w+g_dat_w -1 DOWNTO i*g_dat_w),
        in_val       => demux_out_val(i),
           
        out_dat      => out_dat(i*g_dat_w+g_dat_w -1 DOWNTO i*g_dat_w),
        out_val      => out_val(i)
      );
    END GENERATE;
  END GENERATE;


END rtl;
