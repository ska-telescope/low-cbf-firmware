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

-- Purpose: Test bench for common_fanout_tree
-- Usage:
--   > as 10
--   > run -all
-- . The tb is self checking and asserts when the fanout data are not equal and
--   when the fanout data is not incrementing.

LIBRARY IEEE, common_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;
USE work.common_lfsr_sequences_pkg.ALL;
USE work.tb_common_pkg.ALL;

ENTITY tb_common_fanout_tree IS
  GENERIC (
    -- TB control
    g_random_in_en              : BOOLEAN := FALSE;
    g_random_in_val             : BOOLEAN := FALSE;
    -- DUT settings
    g_nof_stages                : POSITIVE := 2;    -- >= 1
    g_nof_output_per_cell       : POSITIVE := 2;    -- >= 1
    g_nof_output                : POSITIVE := 3;    -- >= 1 and <= g_nof_output_per_cell**g_nof_stages
    g_cell_pipeline_factor_arr  : t_natural_arr := (1, 2);  -- range: g_nof_stages-1 DOWNTO 0, stage g_nof_stages-1 is output stage. Value: stage factor to multiply with g_cell_pipeline_arr
    g_cell_pipeline_arr         : t_natural_arr := (1, 0)   -- range: g_nof_output_per_cell-1 DOWNTO 0. Value: 0 for wires, >0 for register stages
  );
  PORT (
    tb_end_o             : OUT STD_LOGIC);
END tb_common_fanout_tree;


ARCHITECTURE tb OF tb_common_fanout_tree IS

  CONSTANT clk_period          : TIME := 10 ns;

  CONSTANT c_rl                : NATURAL := 1;
  CONSTANT c_init              : NATURAL := 0;
  CONSTANT c_dat_w             : NATURAL := 8;

  CONSTANT c_nof_output        : NATURAL := g_nof_output_per_cell**g_nof_stages;
  CONSTANT c_tree_pipeline_arr : t_natural_arr(c_nof_output-1 DOWNTO 0) := func_common_fanout_tree_pipelining(g_nof_stages, g_nof_output_per_cell, c_nof_output,
                                                                                                              g_cell_pipeline_factor_arr, g_cell_pipeline_arr);
  CONSTANT c_tree_pipeline_max : NATURAL := largest(c_tree_pipeline_arr);

  TYPE t_data_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_dat_w-1 DOWNTO 0);

  SIGNAL tb_end              : STD_LOGIC := '0';
  SIGNAL rst                 : STD_LOGIC := '1';
  SIGNAL clk                 : STD_LOGIC := '1';
  SIGNAL ready               : STD_LOGIC := '1';
  SIGNAL verify_en           : STD_LOGIC := '0';
  SIGNAL random_0            : STD_LOGIC_VECTOR(14 DOWNTO 0) := (OTHERS=>'0');  -- use different lengths to have different random sequences
  SIGNAL random_1            : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS=>'0');  -- use different lengths to have different random sequences

  SIGNAL in_en               : STD_LOGIC := '1';
  SIGNAL cnt_en              : STD_LOGIC := '1';
  SIGNAL in_val              : STD_LOGIC := '0';
  SIGNAL in_dat              : STD_LOGIC_VECTOR(c_dat_w-1 DOWNTO 0);
  SIGNAL out_en_vec          : STD_LOGIC_VECTOR(g_nof_output        -1 DOWNTO 0);
  SIGNAL out_val_vec         : STD_LOGIC_VECTOR(g_nof_output        -1 DOWNTO 0);
  SIGNAL out_dat_vec         : STD_LOGIC_VECTOR(g_nof_output*c_dat_w-1 DOWNTO 0);
  SIGNAL out_dat_arr         : t_data_arr(g_nof_output-1 DOWNTO 0);
  SIGNAL prev_out_dat_arr    : t_data_arr(g_nof_output-1 DOWNTO 0);

  SIGNAL dbg_c_tree_pipeline_arr : t_natural_arr(c_nof_output-1 DOWNTO 0) := c_tree_pipeline_arr;
  SIGNAL ref_en_vec             : STD_LOGIC_VECTOR(g_nof_output-1 DOWNTO 0);
  SIGNAL ref_val_vec            : STD_LOGIC_VECTOR(g_nof_output-1 DOWNTO 0);
  SIGNAL ref_dat_arr            : t_data_arr(      g_nof_output-1 DOWNTO 0);

BEGIN
  tb_end_o <= tb_end;

  clk <= NOT clk OR tb_end AFTER clk_period/2;
  rst <= '1', '0' AFTER 3*clk_period;

  p_stimuli : PROCESS
  BEGIN
    proc_common_wait_until_high(clk, in_en);
    proc_common_wait_until_high(clk, in_val);
    proc_common_wait_some_cycles(clk, c_tree_pipeline_max);

    verify_en <= '1';
    proc_common_wait_some_cycles(clk, 2**c_dat_w);

    proc_common_wait_some_cycles(clk, 10);
    tb_end <= '1';
    WAIT;
  END PROCESS;

  random_0 <= func_common_random(random_0) WHEN rising_edge(clk);
  random_1 <= func_common_random(random_1) WHEN rising_edge(clk);

  in_en  <= '1' WHEN g_random_in_en =FALSE ELSE random_0(random_0'HIGH);
  cnt_en <= '1' WHEN g_random_in_val=FALSE ELSE random_1(random_1'HIGH);

  proc_common_gen_data(c_rl, c_init, rst, clk, cnt_en, ready, in_dat, in_val);

  dut : ENTITY work.common_fanout_tree
  GENERIC MAP (
    g_nof_stages               => g_nof_stages,
    g_nof_output_per_cell      => g_nof_output_per_cell,
    g_nof_output               => g_nof_output,
    g_cell_pipeline_factor_arr => g_cell_pipeline_factor_arr,
    g_cell_pipeline_arr        => g_cell_pipeline_arr,
    g_dat_w                    => c_dat_w
  )
  PORT MAP (
    clk           => clk,
    in_en         => in_en,
    in_dat        => in_dat,
    in_val        => in_val,
    out_en_vec    => out_en_vec,
    out_dat_vec   => out_dat_vec,
    out_val_vec   => out_val_vec
  );

  -- Verify data for fanout output 0
  proc_common_verify_data(c_rl, clk, verify_en, ready, out_val_vec(0), out_dat_arr(0), prev_out_dat_arr(0));

  gen_verify_tree : FOR i IN g_nof_output-1 DOWNTO 0 GENERATE
    out_dat_arr(i) <= out_dat_vec((i+1)*c_dat_w-1 DOWNTO i*c_dat_w);

    -- Reference pipeline compensate
    ref_en_vec(i)  <= out_en_vec( i)'DELAYED((c_tree_pipeline_max-c_tree_pipeline_arr(i)) * clk_period);
    ref_val_vec(i) <= out_val_vec(i)'DELAYED((c_tree_pipeline_max-c_tree_pipeline_arr(i)) * clk_period);
    ref_dat_arr(i) <= out_dat_arr(i)'DELAYED((c_tree_pipeline_max-c_tree_pipeline_arr(i)) * clk_period);

    -- Verify fanout tree by comparing all fanout with output 0
    p_verify_out_dat_arr : PROCESS(clk)
    BEGIN
      IF rising_edge(clk) THEN
        IF verify_en='1' THEN
          ASSERT ref_en_vec(i)  = ref_en_vec(0)  REPORT "Error: wrong fanout enable result" SEVERITY ERROR;
          ASSERT ref_val_vec(i) = ref_val_vec(0) REPORT "Error: wrong fanout valid  result" SEVERITY ERROR;
          ASSERT ref_dat_arr(i) = ref_dat_arr(0) REPORT "Error: wrong fanout data   result" SEVERITY ERROR;
        END IF;
      END IF;
    END PROCESS;
  END GENERATE;

END tb;
