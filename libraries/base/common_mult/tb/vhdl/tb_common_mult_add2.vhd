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

-- Purpose: Tb for common_mult_add2 architectures
-- Description:
--   The tb is self verifying.
-- Usage:
--   > as 10
--   > run -all

LIBRARY IEEE, common_lib, technology_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE technology_lib.technology_pkg.ALL;


ENTITY tb_common_mult_add2 IS
  GENERIC (
    g_technology       : t_technology := c_tech_select_default;
    g_variant          : STRING   := "RTL";
    g_in_dat_w         : NATURAL := 5;
    g_out_dat_w        : NATURAL := 11;     -- 2*g_in_dat_w+1
    g_force_dsp        : BOOLEAN := TRUE;   -- when TRUE resize input width to >= 18 for 'stratix4'
    g_add_sub          : STRING := "ADD";   -- or "SUB"
    g_pipeline_input   : NATURAL := 1;
    g_pipeline_product : NATURAL := 0;
    g_pipeline_adder   : NATURAL := 1;
    g_pipeline_output  : NATURAL := 1
  );
END tb_common_mult_add2;


ARCHITECTURE tb OF tb_common_mult_add2 IS

  CONSTANT clk_period    : TIME := 10 ns;
  CONSTANT c_pipeline    : NATURAL := g_pipeline_input + g_pipeline_product + g_pipeline_adder + g_pipeline_output;
  CONSTANT c_nof_mult    : NATURAL := 2;  -- fixed
  
  CONSTANT c_max_p         : INTEGER :=  2**(g_in_dat_w-1)-1;
  CONSTANT c_min  : INTEGER := -c_max_p;
  CONSTANT c_max_n         : INTEGER := -2**(g_in_dat_w-1);
  
  FUNCTION func_result(in_a0, in_b0, in_a1, in_b1 : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
    -- From mti_numeric_std.vhd follows:
    -- . SIGNED * --> output width = 2 * input width
    -- . SIGNED + --> output width = largest(input width)
    CONSTANT c_in_w   : NATURAL := g_in_dat_w;
    CONSTANT c_res_w  : NATURAL := 2*g_in_dat_w+ceil_log2(c_nof_mult);  -- use sufficiently large result width
    VARIABLE v_a0     : SIGNED(c_in_w-1 DOWNTO 0);
    VARIABLE v_b0     : SIGNED(c_in_w-1 DOWNTO 0);
    VARIABLE v_a1     : SIGNED(c_in_w-1 DOWNTO 0);
    VARIABLE v_b1     : SIGNED(c_in_w-1 DOWNTO 0);
    VARIABLE v_result : SIGNED(c_res_w-1 DOWNTO 0);
  BEGIN
    -- Calculate expected result
    v_a0 := RESIZE_NUM(SIGNED(in_a0), c_in_w);
    v_b0 := RESIZE_NUM(SIGNED(in_b0), c_in_w);
    v_a1 := RESIZE_NUM(SIGNED(in_a1), c_in_w);
    v_b1 := RESIZE_NUM(SIGNED(in_b1), c_in_w);
    IF g_add_sub="ADD" THEN v_result := RESIZE_NUM(v_a0*v_b0, c_res_w) + v_a1*v_b1; END IF;
    IF g_add_sub="SUB" THEN v_result := RESIZE_NUM(v_a0*v_b0, c_res_w) - v_a1*v_b1; END IF;
    -- Wrap to avoid warning: NUMERIC_STD.TO_SIGNED: vector truncated
    IF v_result >  2**(g_out_dat_w-1)-1 THEN v_result := v_result - 2**g_out_dat_w; END IF;
    IF v_result < -2**(g_out_dat_w-1)   THEN v_result := v_result + 2**g_out_dat_w; END IF;
    RETURN STD_LOGIC_VECTOR(v_result);
  END;

  SIGNAL tb_end              : STD_LOGIC := '0';
  SIGNAL rst                 : STD_LOGIC;
  SIGNAL clk                 : STD_LOGIC := '0';
  SIGNAL in_a0               : STD_LOGIC_VECTOR(g_in_dat_w-1 DOWNTO 0);
  SIGNAL in_b0               : STD_LOGIC_VECTOR(g_in_dat_w-1 DOWNTO 0);
  SIGNAL in_a1               : STD_LOGIC_VECTOR(g_in_dat_w-1 DOWNTO 0);
  SIGNAL in_b1               : STD_LOGIC_VECTOR(g_in_dat_w-1 DOWNTO 0);
  SIGNAL in_a                : STD_LOGIC_VECTOR(c_nof_mult*g_in_dat_w-1 DOWNTO 0);
  SIGNAL in_b                : STD_LOGIC_VECTOR(c_nof_mult*g_in_dat_w-1 DOWNTO 0);
  
  SIGNAL out_result          : STD_LOGIC_VECTOR(g_out_dat_w-1 DOWNTO 0);  -- combinatorial result
  SIGNAL result_expected     : STD_LOGIC_VECTOR(g_out_dat_w-1 DOWNTO 0);  -- pipelined results
  SIGNAL result_rtl          : STD_LOGIC_VECTOR(g_out_dat_w-1 DOWNTO 0);

BEGIN

  clk  <= NOT clk OR tb_end AFTER clk_period/2;
  
  -- run 1 us
  p_in_stimuli : PROCESS
  BEGIN
    rst <= '1';
    in_a0 <= TO_SVEC(0, g_in_dat_w);
    in_b0 <= TO_SVEC(0, g_in_dat_w);
    in_a1 <= TO_SVEC(0, g_in_dat_w);
    in_b1 <= TO_SVEC(0, g_in_dat_w);
    WAIT UNTIL rising_edge(clk);
    FOR I IN 0 TO 9 LOOP
      WAIT UNTIL rising_edge(clk);
    END LOOP;
    rst <= '0';
    FOR I IN 0 TO 9 LOOP
      WAIT UNTIL rising_edge(clk);
    END LOOP;
    
    -- Some special combinations
    in_a0 <= TO_SVEC(2, g_in_dat_w);
    in_b0 <= TO_SVEC(3, g_in_dat_w);
    in_a1 <= TO_SVEC(4, g_in_dat_w);
    in_b1 <= TO_SVEC(5, g_in_dat_w);
    WAIT UNTIL rising_edge(clk);
    in_a0 <= TO_SVEC(c_max_p, g_in_dat_w);  -- p*p + p*p = 2pp
    in_b0 <= TO_SVEC(c_max_p, g_in_dat_w);
    in_a1 <= TO_SVEC(c_max_p, g_in_dat_w);
    in_b1 <= TO_SVEC(c_max_p, g_in_dat_w);
    WAIT UNTIL rising_edge(clk);
    in_a0 <= TO_SVEC(c_max_n, g_in_dat_w);  -- -p*-p + -p*-p = -2pp
    in_b0 <= TO_SVEC(c_max_n, g_in_dat_w);
    in_a1 <= TO_SVEC(c_max_n, g_in_dat_w);
    in_b1 <= TO_SVEC(c_max_n, g_in_dat_w);
    WAIT UNTIL rising_edge(clk);
    in_a0 <= TO_SVEC(c_max_p, g_in_dat_w);  -- p*-p + p*-p =  = -2pp
    in_b0 <= TO_SVEC(c_max_n, g_in_dat_w);
    in_a1 <= TO_SVEC(c_max_p, g_in_dat_w);
    in_b1 <= TO_SVEC(c_max_n, g_in_dat_w);
    WAIT UNTIL rising_edge(clk);
    in_a0 <= TO_SVEC(c_max_p, g_in_dat_w);  -- p*(-p-1)_ + p*(-p-1) = -(2pp + 2p)
    in_b0 <= TO_SVEC(c_min, g_in_dat_w);
    in_a1 <= TO_SVEC(c_max_p, g_in_dat_w);
    in_b1 <= TO_SVEC(c_min, g_in_dat_w);
    WAIT UNTIL rising_edge(clk);
    in_a0 <= TO_SVEC(c_max_n, g_in_dat_w);  -- -p*(-p-1)_ + -p*(-p-1) = 2pp + 2p
    in_b0 <= TO_SVEC(c_min, g_in_dat_w);
    in_a1 <= TO_SVEC(c_max_n, g_in_dat_w);
    in_b1 <= TO_SVEC(c_min, g_in_dat_w);
    WAIT UNTIL rising_edge(clk);
    
    FOR I IN 0 TO 49 LOOP
      WAIT UNTIL rising_edge(clk);
    END LOOP;
    
    -- All combinations
    FOR I IN -2**(g_in_dat_w-1) TO 2**(g_in_dat_w-1)-1 LOOP
      FOR J IN -2**(g_in_dat_w-1) TO 2**(g_in_dat_w-1)-1 LOOP
        FOR K IN -2**(g_in_dat_w-1) TO 2**(g_in_dat_w-1)-1 LOOP
          FOR L IN -2**(g_in_dat_w-1) TO 2**(g_in_dat_w-1)-1 LOOP
            in_a0 <= TO_SVEC(I, g_in_dat_w);
            in_b0 <= TO_SVEC(J, g_in_dat_w);
            in_a1 <= TO_SVEC(K, g_in_dat_w);
            in_b1 <= TO_SVEC(L, g_in_dat_w);
            WAIT UNTIL rising_edge(clk);
          END LOOP;
        END LOOP;
      END LOOP;
    END LOOP;
    
    tb_end <= '1';
    WAIT;
  END PROCESS;
  
  in_a <= in_a1 & in_a0;
  in_b <= in_b1 & in_b0;
  
  out_result <= func_result(in_a0, in_b0, in_a1, in_b1);
  
  u_result : ENTITY common_lib.common_pipeline
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
  
  
  u_dut_rtl : ENTITY work.common_mult_add2
  GENERIC MAP (
    g_in_a_w           => g_in_dat_w,
    g_in_b_w           => g_in_dat_w,
    g_res_w            => g_out_dat_w,      -- g_in_a_w + g_in_b_w + log2(2)
    g_force_dsp        => g_force_dsp,      -- not applicable for 'rtl'
    g_add_sub          => g_add_sub,
    g_nof_mult         => 2,
    g_pipeline_input   => g_pipeline_input,
    g_pipeline_product => g_pipeline_product,
    g_pipeline_adder   => g_pipeline_adder,
    g_pipeline_output  => g_pipeline_output
  )
  PORT MAP (
    rst     => '0',
    clk     => clk,
    clken   => '1',
    in_a    => in_a,
    in_b    => in_b,
    res     => result_rtl
  );  
      
  p_verify : PROCESS(rst, clk)
  BEGIN
    IF rst='0' THEN
      IF rising_edge(clk) THEN
        ASSERT result_rtl          = result_expected REPORT "Error: wrong RTL result" SEVERITY ERROR;
      END IF;
    END IF;
  END PROCESS;
  
END tb;
