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

-- Purpose: Test bench for common_operation_tree operations
-- Usage:
--   > as 1
--   > run -all
--   . Observe expanded in_data_arr_p and expected = result with radix unsigned
--     or signed in Wave Window
-- . The p_verify makes the tb self checking and asserts when the results are
--   not equal

LIBRARY IEEE, common_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;
USE work.common_lfsr_sequences_pkg.ALL;
USE work.tb_common_pkg.ALL;


ENTITY tb_common_operation_tree IS
  GENERIC (
    g_operation      : STRING  := "MAX";      -- supported operations "MAX", "MIN"
    g_representation : STRING  := "UNSIGNED";
    g_pipeline       : NATURAL := 1;  -- amount of pipelining per stage
    g_pipeline_mod   : NATURAL := 1;  -- only pipeline the stage output by g_pipeline when the stage number MOD g_pipeline_mod = 0
    g_nof_inputs     : NATURAL := 5   -- >= 1
  );
  PORT (
    tb_end_o             : OUT STD_LOGIC);
END tb_common_operation_tree;


ARCHITECTURE tb OF tb_common_operation_tree IS

  CONSTANT clk_period      : TIME := 10 ns;

  CONSTANT c_dat_w         : NATURAL := 8;
  CONSTANT c_data_vec_w    : NATURAL := g_nof_inputs*c_dat_w;
  CONSTANT c_nof_stages    : NATURAL := ceil_log2(g_nof_inputs);

  CONSTANT c_smax          : INTEGER :=  2**(c_dat_w-1)-1;
  CONSTANT c_smin          : INTEGER := -2**(c_dat_w-1);
  CONSTANT c_umax          : INTEGER :=  2**c_dat_w-1;
  CONSTANT c_umin          : INTEGER :=  0;

  CONSTANT c_pipeline_tree : NATURAL := g_pipeline*c_nof_stages / g_pipeline_mod;

  TYPE t_data_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_dat_w-1 DOWNTO 0);

  -- Use random data values for the g_nof_inputs time in the data_vec
  FUNCTION func_data_vec(init : INTEGER) RETURN STD_LOGIC_VECTOR IS
    VARIABLE v_data_vec : STD_LOGIC_VECTOR(c_data_vec_w-1 DOWNTO 0);
    VARIABLE v_in       : STD_LOGIC_VECTOR(c_dat_w-1 DOWNTO 0);
  BEGIN
    v_in := TO_SVEC(init, c_dat_w);
    FOR I IN 0 TO g_nof_inputs-1 LOOP
      v_data_vec((I+1)*c_dat_w-1 DOWNTO I*c_dat_w) := v_in;
      v_in := func_common_random(v_in);
    END LOOP;
    RETURN v_data_vec;
  END;

  -- Calculate the expected result of the operation on the data in the data_vec
  FUNCTION func_result(operation, representation : STRING; data_vec : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
    VARIABLE v_in     : STD_LOGIC_VECTOR(c_dat_w-1 DOWNTO 0);
    VARIABLE v_result : INTEGER := 0;
  BEGIN
    -- Init v_result
    IF representation="SIGNED" THEN
      IF operation="MIN" THEN v_result := c_smax; END IF;
      IF operation="MAX" THEN v_result := c_smin; END IF;
    ELSE
      IF operation="MIN" THEN v_result := c_umax; END IF;
      IF operation="MAX" THEN v_result := c_umin; END IF;
    END IF;
    -- Find v_result
    FOR I IN 0 TO g_nof_inputs-1 LOOP
      v_in := data_vec((I+1)*c_dat_w-1 DOWNTO I*c_dat_w);
      IF representation="SIGNED" THEN
        IF operation="MIN" THEN IF v_result > SIGNED(v_in) THEN v_result := TO_SINT(v_in); END IF; END IF;
        IF operation="MAX" THEN IF v_result < SIGNED(v_in) THEN v_result := TO_SINT(v_in); END IF; END IF;
      ELSE
        IF operation="MIN" THEN IF v_result > UNSIGNED(v_in) THEN v_result := TO_UINT(v_in); END IF; END IF;
        IF operation="MAX" THEN IF v_result < UNSIGNED(v_in) THEN v_result := TO_UINT(v_in); END IF; END IF;
      END IF;
    END LOOP;
    -- Return v_result
    IF representation="SIGNED" THEN
      RETURN TO_SVEC(v_result, c_dat_w);
    ELSE
      RETURN TO_UVEC(v_result, c_dat_w);
    END IF;
  END;

  SIGNAL tb_end             : STD_LOGIC := '0';
  SIGNAL rst                : STD_LOGIC;
  SIGNAL clk                : STD_LOGIC := '1';

  SIGNAL expected_comb      : STD_LOGIC_VECTOR(c_dat_w-1 DOWNTO 0);  -- expected combinatorial result

  SIGNAL in_val             : STD_LOGIC;
  SIGNAL in_en_vec          : STD_LOGIC_VECTOR(g_nof_inputs-1 DOWNTO 0) := (OTHERS=>'1');
  SIGNAL in_data_vec        : STD_LOGIC_VECTOR(c_data_vec_w-1 DOWNTO 0);
  SIGNAL in_data_vec_p      : STD_LOGIC_VECTOR(c_data_vec_w-1 DOWNTO 0);
  SIGNAL in_data_arr_p      : t_data_arr(0 TO g_nof_inputs-1);

  SIGNAL result             : STD_LOGIC_VECTOR(c_dat_w-1 DOWNTO 0);  -- dut result
  SIGNAL expected           : STD_LOGIC_VECTOR(c_dat_w-1 DOWNTO 0);  -- expected pipelined result
  SIGNAL expected_val       : STD_LOGIC;

BEGIN

  tb_end_o <= tb_end;

  clk <= NOT clk OR tb_end AFTER clk_period/2;
  rst <= '1', '0' AFTER clk_period*3;

  p_stimuli : PROCESS
  BEGIN
    in_data_vec <= (OTHERS=>'0');
    in_val <= '0';
    proc_common_wait_until_low(clk, rst);
    proc_common_wait_some_cycles(clk, 5);

    -- Apply equal dat value inputs
    in_val <= '1';
    FOR I IN c_smin TO c_smax LOOP
      in_data_vec <= func_data_vec(I);
      proc_common_wait_some_cycles(clk, 1);
    END LOOP;
    in_data_vec <= (OTHERS=>'0');
    proc_common_wait_some_cycles(clk, 50);

    tb_end <= '1';
    WAIT;
  END PROCESS;

  -- For easier manual analysis in the wave window:
  -- . Pipeline the in_data_vec to align with the result
  -- . Map the concatenated dat in in_data_vec into an in_data_arr_p array
  u_data_vec_p : ENTITY work.common_pipeline
  GENERIC MAP (
    g_representation => "SIGNED",
    g_pipeline       => c_pipeline_tree,
    g_reset_value    => 0,
    g_in_dat_w       => c_data_vec_w,
    g_out_dat_w      => c_data_vec_w
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => in_data_vec,
    out_dat => in_data_vec_p
  );

  p_data_arr : PROCESS(in_data_vec_p)
  BEGIN
    FOR I IN 0 TO g_nof_inputs-1 LOOP
      in_data_arr_p(I) <= in_data_vec_p((I+1)*c_dat_w-1 DOWNTO I*c_dat_w);
    END LOOP;
  END PROCESS;

  expected_comb <= func_result(g_operation, g_representation, in_data_vec);

  u_result : ENTITY work.common_pipeline
  GENERIC MAP (
    g_representation => "SIGNED",
    g_pipeline       => c_pipeline_tree,
    g_reset_value    => 0,
    g_in_dat_w       => c_dat_w,
    g_out_dat_w      => c_dat_w
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => expected_comb,
    out_dat => expected
  );

  u_expected_val : ENTITY work.common_pipeline_sl
  GENERIC MAP (
    g_pipeline       => c_pipeline_tree,
    g_reset_value    => 0
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => in_val,
    out_dat => expected_val
  );

  dut : ENTITY work.common_operation_tree
  GENERIC MAP (
    g_operation      => g_operation,
    g_representation => g_representation,
    g_pipeline       => g_pipeline,
    g_pipeline_mod   => g_pipeline_mod,
    g_nof_inputs     => g_nof_inputs,
    g_dat_w          => c_dat_w
  )
  PORT MAP (
    clk         => clk,
    in_data_vec => in_data_vec,
    in_en_vec   => in_en_vec,
    result      => result
  );

  p_verify : PROCESS(rst, clk)
  BEGIN
    IF rst='0' THEN
      IF rising_edge(clk) THEN
        ASSERT result = expected REPORT "Error: wrong result" SEVERITY ERROR;
      END IF;
    END IF;
  END PROCESS;

END tb;
