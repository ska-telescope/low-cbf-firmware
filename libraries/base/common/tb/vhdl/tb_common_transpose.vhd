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
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.tb_common_pkg.ALL;

-- Purpose: Test bench for common_transpose.vhd
-- Usage:
-- > as 3
-- > run -all
--   p_verify self-checks the data output and the addr output of two times the
--   transpose.

ENTITY tb_common_transpose IS
  GENERIC (
    g_pipeline_shiftreg  : NATURAL := 0;
    g_pipeline_transpose : NATURAL := 0;
    g_pipeline_hold      : NATURAL := 0;
    g_pipeline_select    : NATURAL := 1;
    g_nof_data           : NATURAL := 3;
    g_data_w             : NATURAL := 12;
    g_addr_w             : NATURAL := 9;
    g_addr_offset        : NATURAL := 10    -- default use fixed offset, in_offset * g_nof_data must fit in g_addr_w address range
  );
  PORT (
    tb_end_o           : OUT STD_LOGIC);
END tb_common_transpose;

ARCHITECTURE tb OF tb_common_transpose IS

  CONSTANT clk_period     : TIME := 10 ns;

  CONSTANT c_pipeline     : NATURAL := g_pipeline_shiftreg + g_pipeline_transpose + g_pipeline_select;
  CONSTANT c_repeat       : NATURAL := 10;
  CONSTANT c_lo           : NATURAL := 0;
  CONSTANT c_interval_len : NATURAL := 100;
  CONSTANT c_blk_len      : NATURAL := 10;
  CONSTANT c_gap_len      : NATURAL := 50;

  CONSTANT c_symbol_w     : NATURAL := g_data_w/g_nof_data;

  CONSTANT c_frame_len    : NATURAL :=  7 * g_nof_data;
  CONSTANT c_frame_eop    : NATURAL := (c_frame_len-1) MOD c_frame_len;

  PROCEDURE proc_align_eop(SIGNAL clk      : IN  STD_LOGIC;
                           SIGNAL stimuli_phase : IN  STD_LOGIC;
                           SIGNAL in_val   : OUT STD_LOGIC) IS
  BEGIN
    WHILE stimuli_phase='0' LOOP
      in_val <= '1';
      proc_common_wait_some_cycles(clk, 1);
    END LOOP;
    in_val <= '0';
  END proc_align_eop;

  -- Stimuli
  SIGNAL tb_end         : STD_LOGIC := '0';
  SIGNAL rst            : STD_LOGIC;
  SIGNAL clk            : STD_LOGIC := '1';

  SIGNAL stimuli_end    : STD_LOGIC;
  SIGNAL stimuli_data   : STD_LOGIC_VECTOR(c_word_w-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL stimuli_phase  : STD_LOGIC;

  SIGNAL in_offset      : STD_LOGIC_VECTOR(g_addr_w-1 DOWNTO 0) := TO_UVEC(g_addr_offset, g_addr_w);
  SIGNAL in_addr        : STD_LOGIC_VECTOR(g_addr_w-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL in_data        : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL in_val         : STD_LOGIC;
  SIGNAL in_eop         : STD_LOGIC;

  -- DUT output
  SIGNAL trans_offset   : STD_LOGIC_VECTOR(g_addr_w-1 DOWNTO 0) := TO_SVEC(-g_addr_offset, g_addr_w);  -- use -g_addr_offset as inverse operation
  SIGNAL trans_addr     : STD_LOGIC_VECTOR(g_addr_w-1 DOWNTO 0);
  SIGNAL trans_data     : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
  SIGNAL trans_val      : STD_LOGIC;
  SIGNAL trans_eop      : STD_LOGIC;

  SIGNAL out_addr       : STD_LOGIC_VECTOR(g_addr_w-1 DOWNTO 0);
  SIGNAL out_data       : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
  SIGNAL out_val        : STD_LOGIC;
  SIGNAL out_eop        : STD_LOGIC;

  -- Verify
  SIGNAL verify_en      : STD_LOGIC := '0';
  SIGNAL ready          : STD_LOGIC := '1';
  SIGNAL prev_out_addr  : STD_LOGIC_VECTOR(g_addr_w-1 DOWNTO 0) := (OTHERS=>'1');
  SIGNAL prev_out_data  : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0) := (OTHERS=>'1');

BEGIN

   tb_end_o <= tb_end;

  -- Stimuli
  clk <= NOT clk OR tb_end AFTER clk_period/2;
  rst <= '1', '0' AFTER 3*clk_period;

  p_stimuli : PROCESS
  BEGIN
    in_val <= '0';
    in_eop <= '0';
    verify_en <= '0';
    proc_common_wait_until_low(clk, rst);
    proc_common_wait_some_cycles(clk, 10);
    verify_en <= '1';

    -- Verify pulsed valid
    FOR J IN 0 TO 2*g_nof_data LOOP
      FOR I IN 1 TO c_blk_len+J LOOP
        proc_common_val_duty(1, 1, clk, in_val);
      END LOOP;
      proc_align_eop(clk, stimuli_phase, in_val);
      proc_common_eop(clk, in_val, in_eop);
      proc_common_wait_some_cycles(clk, 2*c_blk_len);
    END LOOP;

    FOR J IN 0 TO 2*g_nof_data LOOP
      FOR I IN 1 TO c_blk_len+J LOOP
        proc_common_val_duty(1, 1, clk, in_val);
      END LOOP;
      proc_align_eop(clk, stimuli_phase, in_val);
      proc_common_wait_some_cycles(clk, 1);
      proc_common_eop(clk, in_val, in_eop);
      proc_common_wait_some_cycles(clk, 2*c_blk_len);
    END LOOP;

    -- Verify muli pulsed valid
    FOR P IN 0 TO 1 LOOP
      FOR I IN c_lo TO c_repeat LOOP
        FOR J IN c_lo TO c_repeat LOOP
          IF P=0 THEN
            proc_common_val_duty(I, J, clk, in_val);
          ELSE
            proc_common_val_duty(J, I, clk, in_val);
          END IF;
        END LOOP;
      END LOOP;
      proc_common_wait_some_cycles(clk, c_gap_len);
      FOR I IN c_lo TO c_repeat LOOP
        FOR J IN c_repeat DOWNTO c_lo LOOP
          IF P=0 THEN
            proc_common_val_duty(I, J, clk, in_val);
          ELSE
            proc_common_val_duty(J, I, clk, in_val);
          END IF;
        END LOOP;
      END LOOP;
      proc_common_wait_some_cycles(clk, c_gap_len);
      FOR I IN c_repeat DOWNTO c_lo LOOP
        FOR J IN c_lo TO c_repeat LOOP
          IF P=0 THEN
            proc_common_val_duty(I, J, clk, in_val);
          ELSE
            proc_common_val_duty(J, I, clk, in_val);
          END IF;
        END LOOP;
      END LOOP;
      proc_common_wait_some_cycles(clk, c_gap_len);
      FOR I IN c_repeat DOWNTO c_lo LOOP
        FOR J IN c_repeat DOWNTO c_lo LOOP
          IF P=0 THEN
            proc_common_val_duty(I, J, clk, in_val);
          ELSE
            proc_common_val_duty(J, I, clk, in_val);
          END IF;
        END LOOP;
      END LOOP;
      proc_align_eop(clk, stimuli_phase, in_val);
      proc_common_eop(clk, in_val, in_eop);
      proc_common_wait_some_cycles(clk, c_gap_len);
    END LOOP;

    -- Verify active valid
    in_val <= '1';
    proc_common_wait_until_lo_hi(clk, stimuli_end);
    proc_common_wait_some_cycles(clk, c_interval_len);
    proc_align_eop(clk, stimuli_phase, in_val);
    proc_common_eop(clk, in_val, in_eop);
    in_val <= '0';
    proc_common_wait_some_cycles(clk, c_gap_len);

    tb_end <= '1';
    WAIT;
  END PROCESS;

  stimuli_end <= '1' WHEN SIGNED(in_data)=-1 ELSE '0';

  in_addr <= stimuli_data(g_addr_w-1 DOWNTO 0);
  in_data <= stimuli_data(g_data_w-1 DOWNTO 0);

  stimuli_data  <= INCR_UVEC(stimuli_data, 1) WHEN rising_edge(clk) AND in_val='1';
  stimuli_phase <= in_val WHEN TO_UINT(stimuli_data) MOD g_nof_data = g_nof_data-2 ELSE '0';

  -- DUT
  u_transpose_in : ENTITY common_lib.common_transpose
  GENERIC MAP (
    g_pipeline_shiftreg  => g_pipeline_shiftreg,
    g_pipeline_transpose => g_pipeline_transpose,
    g_pipeline_hold      => g_pipeline_hold,
    g_pipeline_select    => g_pipeline_select,
    g_nof_data           => g_nof_data,
    g_data_w             => g_data_w,
    g_addr_w             => g_addr_w,
    g_addr_offset        => g_addr_offset
  )
  PORT MAP (
    rst        => rst,
    clk        => clk,

    in_offset  => in_offset,
    in_addr    => in_addr,
    in_data    => in_data,
    in_val     => in_val,
    in_eop     => in_eop,

    out_addr   => trans_addr,
    out_data   => trans_data,
    out_val    => trans_val,
    out_eop    => trans_eop
  );

  u_transpose_out : ENTITY common_lib.common_transpose
  GENERIC MAP (
    g_pipeline_shiftreg  => g_pipeline_shiftreg,
    g_pipeline_transpose => g_pipeline_transpose,
    g_pipeline_hold      => g_pipeline_hold,
    g_pipeline_select    => g_pipeline_select,
    g_nof_data           => g_nof_data,
    g_data_w             => g_data_w,
    g_addr_w             => g_addr_w,
    g_addr_offset        => g_addr_offset
  )
  PORT MAP (
    rst        => rst,
    clk        => clk,

    in_offset  => trans_offset,
    in_addr    => trans_addr,
    in_data    => trans_data,
    in_val     => trans_val,
    in_eop     => trans_eop,

    out_addr   => out_addr,
    out_data   => out_data,
    out_val    => out_val,
    out_eop    => out_eop
  );

  -- Verification p_verify
  proc_common_verify_data(1, clk, verify_en, ready, out_val, out_addr, prev_out_addr);
  proc_common_verify_data(1, clk, verify_en, ready, out_val, out_data, prev_out_data);

END tb;
