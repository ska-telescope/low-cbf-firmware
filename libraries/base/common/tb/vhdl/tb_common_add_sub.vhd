-------------------------------------------------------------------------------
--
-- Copyright (C) 2009
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
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;


ENTITY tb_common_add_sub IS
  GENERIC (
    g_direction    : STRING := "SUB";  -- "SUB", "ADD" or "BOTH"
    g_sel_add      : STD_LOGIC :='1';  -- '0' = sub, '1' = add, only valid for g_direction = "BOTH"
    g_pipeline_in  : NATURAL := 0;     -- input pipelining 0 or 1
    g_pipeline_out : NATURAL := 2;     -- output pipelining >= 0
    g_in_dat_w     : NATURAL := 5;
    g_out_dat_w    : NATURAL := 5      -- g_in_dat_w or g_in_dat_w+1
  );
  PORT (
   tb_end_o        : OUT STD_LOGIC);
END tb_common_add_sub;


ARCHITECTURE tb OF tb_common_add_sub IS

  CONSTANT clk_period    : TIME := 10 ns;
  CONSTANT c_pipeline    : NATURAL := g_pipeline_in + g_pipeline_out;

  FUNCTION func_result(in_a, in_b : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
    VARIABLE v_a, v_b, v_result : INTEGER;
  BEGIN
    -- Calculate expected result
    v_a := TO_SINT(in_a);
    v_b := TO_SINT(in_b);
    IF g_direction="ADD"                    THEN v_result := v_a + v_b; END IF;
    IF g_direction="SUB"                    THEN v_result := v_a - v_b; END IF;
    IF g_direction="BOTH" AND g_sel_add='1' THEN v_result := v_a + v_b; END IF;
    IF g_direction="BOTH" AND g_sel_add='0' THEN v_result := v_a - v_b; END IF;
    -- Wrap to avoid warning: NUMERIC_STD.TO_SIGNED: vector truncated
    IF v_result >  2**(g_out_dat_w-1)-1 THEN v_result := v_result - 2**g_out_dat_w; END IF;
    IF v_result < -2**(g_out_dat_w-1)   THEN v_result := v_result + 2**g_out_dat_w; END IF;
    RETURN TO_SVEC(v_result, g_out_dat_w);
  END;

  SIGNAL rst             : STD_LOGIC;
  SIGNAL clk             : STD_LOGIC := '0';
  SIGNAL tb_end          : STD_LOGIC := '0';
  SIGNAL in_a            : STD_LOGIC_VECTOR(g_in_dat_w-1 DOWNTO 0);
  SIGNAL in_b            : STD_LOGIC_VECTOR(g_in_dat_w-1 DOWNTO 0);
  SIGNAL out_result      : STD_LOGIC_VECTOR(g_out_dat_w-1 DOWNTO 0);  -- combinatorial result
  SIGNAL result_expected : STD_LOGIC_VECTOR(g_out_dat_w-1 DOWNTO 0);  -- pipelined results
  SIGNAL result_rtl      : STD_LOGIC_VECTOR(g_out_dat_w-1 DOWNTO 0);

BEGIN

   tb_end_o <= tb_end;

  clk  <= NOT clk OR tb_end AFTER clk_period/2;

  -- run 1 us
  p_in_stimuli : PROCESS
  BEGIN
    rst <= '1';
    in_a <= TO_SVEC(0, g_in_dat_w);
    in_b <= TO_SVEC(0, g_in_dat_w);
    WAIT UNTIL rising_edge(clk);
    FOR I IN 0 TO 9 LOOP
      WAIT UNTIL rising_edge(clk);
    END LOOP;
    rst <= '0';
    FOR I IN 0 TO 9 LOOP
      WAIT UNTIL rising_edge(clk);
    END LOOP;

    -- Some special combinations
    in_a <= TO_SVEC(2, g_in_dat_w);
    in_b <= TO_SVEC(5, g_in_dat_w);
    WAIT UNTIL rising_edge(clk);
    in_a <= TO_SVEC(2, g_in_dat_w);
    in_b <= TO_SVEC(-5, g_in_dat_w);
    WAIT UNTIL rising_edge(clk);
    in_a <= TO_SVEC(-3, g_in_dat_w);
    in_b <= TO_SVEC(-9, g_in_dat_w);
    WAIT UNTIL rising_edge(clk);
    in_a <= TO_SVEC(-3, g_in_dat_w);
    in_b <= TO_SVEC(9, g_in_dat_w);
    WAIT UNTIL rising_edge(clk);
    in_a <= TO_SVEC(11, g_in_dat_w);
    in_b <= TO_SVEC(15, g_in_dat_w);
    WAIT UNTIL rising_edge(clk);
    in_a <= TO_SVEC(11, g_in_dat_w);
    in_b <= TO_SVEC(-15, g_in_dat_w);
    WAIT UNTIL rising_edge(clk);
    in_a <= TO_SVEC(-11, g_in_dat_w);
    in_b <= TO_SVEC(15, g_in_dat_w);
    WAIT UNTIL rising_edge(clk);
    in_a <= TO_SVEC(-11, g_in_dat_w);
    in_b <= TO_SVEC(-15, g_in_dat_w);
    WAIT UNTIL rising_edge(clk);

    FOR I IN 0 TO 49 LOOP
      WAIT UNTIL rising_edge(clk);
    END LOOP;

    -- All combinations
    FOR I IN -2**(g_in_dat_w-1) TO 2**(g_in_dat_w-1)-1 LOOP
      FOR J IN -2**(g_in_dat_w-1) TO 2**(g_in_dat_w-1)-1 LOOP
        in_a <= TO_SVEC(I, g_in_dat_w);
        in_b <= TO_SVEC(J, g_in_dat_w);
        WAIT UNTIL rising_edge(clk);
      END LOOP;
    END LOOP;
    tb_end <= '1';
    WAIT;
  END PROCESS;

  out_result <= func_result(in_a, in_b);

  u_result : ENTITY work.common_pipeline
  GENERIC MAP (
    g_representation => "SIGNED",
    g_pipeline       => c_pipeline,
    g_reset_value    => 0,
    g_in_dat_w       => g_out_dat_w,
    g_out_dat_w      => g_out_dat_w
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    clken   => '1',
    in_dat  => out_result,
    out_dat => result_expected
  );

  u_dut_rtl : ENTITY work.common_add_sub
  GENERIC MAP (
    g_direction       => g_direction,
    g_representation  => "SIGNED",
    g_pipeline_input  => g_pipeline_in,
    g_pipeline_output => g_pipeline_out,
    g_in_dat_w        => g_in_dat_w,
    g_out_dat_w       => g_out_dat_w
  )
  PORT MAP (
    clk     => clk,
    clken   => '1',
    sel_add => g_sel_add,
    in_a    => in_a,
    in_b    => in_b,
    result  => result_rtl
  );

  p_verify : PROCESS(rst, clk)
  BEGIN
    IF rst='0' THEN
      IF rising_edge(clk) THEN
        ASSERT result_rtl      = result_expected REPORT "Error: wrong RTL result" SEVERITY ERROR;
      END IF;
    END IF;
  END PROCESS;

END tb;
