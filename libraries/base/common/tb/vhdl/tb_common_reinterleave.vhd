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
USE work.tb_common_pkg.ALL;

-- Purpose: Test bench to check reinterleave function visually
-- Usage:
--   > do wave_reinterleave.do
--   > run 400ns
--   > observe how the DUT inputs are reinterleaved onto the DUT outputs.
-- Remark: This TB is meant to be easy to the eyes. For stress-testing, use the tb_tb.

ENTITY tb_common_reinterleave IS
  GENERIC (
    g_dat_w          : NATURAL := 16;   -- Data width including concatenated stream ID byte (if used)
    g_nof_in         : NATURAL := 2;    -- Max 6 if stream ID is used
    g_deint_block_size  : NATURAL := 2;
    g_nof_out        : NATURAL := 2;
    g_inter_block_size : NATURAL := 2;
    g_concat_id      : BOOLEAN := TRUE; -- Concatenate a 1 byte stream ID 0xA..F @ MSB so user can follow streams in wave window
    g_cnt_sync       : BOOLEAN := TRUE  -- When TRUE all generated streams start at 0, else they're offset by 16 counter values.
 );
END;

ARCHITECTURE rtl OF tb_common_reinterleave IS

  TYPE t_dat_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
  TYPE t_val_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC;

  -----------------------------------------------------------------------------
  -- Standard TB clocking, RST and control
  -----------------------------------------------------------------------------
  CONSTANT c_clk_period : TIME := 10 ns;

  SIGNAL clk            : STD_LOGIC := '1';
  SIGNAL rst            : STD_LOGIC;
  SIGNAL tb_end         : STD_LOGIC := '0';

  -----------------------------------------------------------------------------
  -- Override g_dat_w if user want to concatenate stream IDs
  -----------------------------------------------------------------------------
  CONSTANT c_id_w       : NATURAL := c_nibble_w; -- HEX 0xA..0xF

  CONSTANT c_cnt_dat_w  : NATURAL := sel_a_b(g_concat_id, g_dat_w-c_id_w, g_dat_w);

  CONSTANT c_nof_id     : NATURAL := 6; -- HEX 0xA..0xF
  CONSTANT c_id_arr     : t_slv_4_arr(c_nof_id-1 DOWNTO 0) := (x"F", x"E", x"D", x"C", x"B", x"A");

  SIGNAL cnt_ena        : STD_LOGIC;
  SIGNAL cnt_rdy        : STD_LOGIC := '1';

  -----------------------------------------------------------------------------
  -- Array of DUT input buses
  -----------------------------------------------------------------------------
  SIGNAL dut_in_dat_arr : t_dat_arr(g_nof_in-1 DOWNTO 0);
  SIGNAL dut_in_val_arr : t_val_arr(g_nof_in-1 DOWNTO 0);
  
  -- DUT input array flattened into SLV
  SIGNAL dut_in_dat     : STD_LOGIC_VECTOR(g_nof_in*g_dat_w-1 DOWNTO 0);

  -----------------------------------------------------------------------------
  -- DUT output array 
  -----------------------------------------------------------------------------
  SIGNAL dut_out_dat_arr : t_dat_arr(g_nof_out-1 DOWNTO 0);
  
  -- DUT output Array flattened into SLV (= REVERSE FUNCTION input)
  SIGNAL dut_out_dat     : STD_LOGIC_VECTOR(g_nof_out*g_dat_w-1 DOWNTO 0);
  SIGNAL dut_out_val     : STD_LOGIC_VECTOR(g_nof_out-1 DOWNTO 0);

  -----------------------------------------------------------------------------
  -- REVERSE FUNCTION output
  -----------------------------------------------------------------------------
  SIGNAL rev_out_dat     : STD_LOGIC_VECTOR(g_nof_in*g_dat_w-1 DOWNTO 0);
  SIGNAL rev_out_val     : STD_LOGIC_VECTOR(g_nof_in-1 DOWNTO 0);

  -- REVERSE FUNCTION output array
  SIGNAL rev_out_dat_arr : t_dat_arr(g_nof_in-1 DOWNTO 0);

BEGIN

  -----------------------------------------------------------------------------
  -- Standard TB clocking, RST and control
  -----------------------------------------------------------------------------
  clk    <= NOT clk OR tb_end AFTER c_clk_period/2;
  rst    <= '1', '0' AFTER 3*c_clk_period;

  -----------------------------------------------------------------------------
  -- Generate g_nof_in test data streams with counter data plus optional ID
  -----------------------------------------------------------------------------
  cnt_ena <= '0', '1' AFTER 20*c_clk_period;

  gen_cnt_dat : FOR i IN 0 TO g_nof_in-1 GENERATE 
    -- Generate counter data. Let the generated stream start at 0 unless user wants 
    -- the streams to be asynchronous (then separate them by an offset of 10).
    proc_common_gen_data(1, sel_a_b(g_cnt_sync, 0, i*16), rst, clk, cnt_ena, cnt_rdy, dut_in_dat_arr(i)(c_cnt_dat_w-1 DOWNTO 0), dut_in_val_arr(i));
    -- Concatenate ID if desired
    gen_id_data : IF g_concat_id = TRUE GENERATE
      dut_in_dat_arr(i)(g_dat_w-1 DOWNTO c_cnt_dat_w) <= c_id_arr(i);
    END GENERATE;    
  END GENERATE;

  -----------------------------------------------------------------------------
  -- The I/O of common_reinterleave and its lower level components operate 
  -- on the same data width share the same clock, so if g_nof_in>g_nof_out, 
  -- lower the effective input data rate accordingly by introducing gaps.
  -----------------------------------------------------------------------------
  gen_dut_in_dat_gaps : IF g_nof_in > g_nof_out GENERATE
    p_cnt_dat_gaps : PROCESS
    BEGIN
      cnt_rdy <= '0';
      WAIT FOR c_clk_period * (ceil_div(g_nof_in,g_nof_out) -1);
      cnt_rdy <= '1';
      WAIT FOR c_clk_period;
    END PROCESS;
  END GENERATE;

  -----------------------------------------------------------------------------
  -- Map the array of counter data streams to SLV
  -----------------------------------------------------------------------------
  gen_wires_in : FOR i IN 0 TO g_nof_in-1 GENERATE 
    dut_in_dat( i*g_dat_w+g_dat_w -1 DOWNTO i*g_dat_w) <= dut_in_dat_arr(i);
  END GENERATE;

  -----------------------------------------------------------------------------
  -- DUT
  -----------------------------------------------------------------------------
  u_reinterleave : ENTITY work.common_reinterleave
  GENERIC MAP (
    g_nof_in         => g_nof_in,
    g_deint_block_size  => g_deint_block_size,
    g_nof_out        => g_nof_out,
    g_inter_block_size => g_inter_block_size,
    g_dat_w          => g_dat_w
  )
  PORT MAP (
    rst        => rst,
    clk        => clk,
    
    in_dat     => dut_in_dat,
    in_val     => dut_in_val_arr(0), -- All input streams should be synchronous in terms of timing
    
    out_dat    => dut_out_dat,
    out_val    => dut_out_val
  );

  -----------------------------------------------------------------------------
  -- Map DUT output SLV to array of streams (to ease viewing in wave window)
  -----------------------------------------------------------------------------
  gen_dut_out : FOR i IN 0 TO g_nof_out-1 GENERATE 
    dut_out_dat_arr(i) <= dut_out_dat( i*g_dat_w+g_dat_w -1 DOWNTO i*g_dat_w);
  END GENERATE;

  -----------------------------------------------------------------------------
  -- REVERSE FUNCTION; the outputs should match the DUT inputs (with delay)
  -----------------------------------------------------------------------------
  u_rev_reinterleave : ENTITY work.common_reinterleave
  GENERIC MAP (
    g_nof_in         => g_nof_out, -- Note the reversed generics
    g_deint_block_size  => g_inter_block_size,
    g_nof_out        => g_nof_in,
    g_inter_block_size => g_deint_block_size,
    g_dat_w          => g_dat_w
  )
  PORT MAP (
    rst        => rst,
    clk        => clk,
    
    in_dat     => dut_out_dat,
    in_val     => dut_out_val(0),
    
    out_dat    => rev_out_dat,
    out_val    => rev_out_val
  );

  -----------------------------------------------------------------------------
  -- Map REV output SLV to array of streams
  -----------------------------------------------------------------------------
  gen_rev_out : FOR i IN 0 TO g_nof_out-1 GENERATE 
    rev_out_dat_arr(i) <= rev_out_dat( i*g_dat_w+g_dat_w -1 DOWNTO i*g_dat_w);
  END GENERATE;


END rtl;
