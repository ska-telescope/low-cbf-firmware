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
USE work.common_pkg.ALL;

ARCHITECTURE recursive OF common_adder_tree IS

  -- common_add_sub pipelining
  CONSTANT c_pipeline_in  : NATURAL := 0;
  CONSTANT c_pipeline_out : NATURAL := g_pipeline;

  CONSTANT c_nof_h1       : NATURAL :=                g_nof_inputs/2;  -- lower half
  CONSTANT c_nof_h2       : NATURAL := g_nof_inputs - g_nof_inputs/2;  -- upper half
  
  -- The h1 branch needs an extra dummy stage when c_nof_h1 is a power of 2 AND c_nof_h2=c_nof_h1+1
  FUNCTION func_stage_h1(h1, h2 : NATURAL) RETURN BOOLEAN IS
    VARIABLE v_ret : BOOLEAN := FALSE;
  BEGIN
    IF h1 > 1 THEN
      IF h1 = 2**ceil_log2(h1) AND h2 = h1+1 THEN
        v_ret := TRUE;
      END IF;
    END IF;
    RETURN v_ret;
  END;
  
  CONSTANT c_stage_h1     : BOOLEAN := func_stage_h1(c_nof_h1, c_nof_h2);
  
  CONSTANT c_sum_w        : NATURAL := g_dat_w+ceil_log2(g_nof_inputs);  -- internally work with worst case bit growth
  CONSTANT c_sum_h_w      : NATURAL := c_sum_w-1;
  CONSTANT c_sum_h1_w     : NATURAL := sel_a_b(c_stage_h1, c_sum_h_w-1, c_sum_h_w);
  CONSTANT c_sum_h2_w     : NATURAL :=                                  c_sum_h_w;
  
  COMPONENT common_adder_tree IS
    GENERIC (
      g_representation : STRING;
      g_pipeline       : NATURAL;
      g_nof_inputs     : NATURAL;
      g_dat_w          : NATURAL;
      g_sum_w          : NATURAL
    );
    PORT (
      clk    : IN  STD_LOGIC;
      clken  : IN  STD_LOGIC := '1';
      in_dat : IN  STD_LOGIC_VECTOR(g_nof_inputs*g_dat_w-1 DOWNTO 0);
      sum    : OUT STD_LOGIC_VECTOR(             g_sum_w-1 DOWNTO 0)
    );
  END COMPONENT;
  
  -- The FOR ALL the instance label must be at level 1, it can not point within a generate statement because then it gets at level 2.
  --FOR ALL : common_adder_tree USE ENTITY work.common_adder_tree(recursive);

  SIGNAL sum_h1     : STD_LOGIC_VECTOR(c_sum_h1_w-1 DOWNTO 0);
  SIGNAL sum_h1_reg : STD_LOGIC_VECTOR(c_sum_h2_w-1 DOWNTO 0);
  SIGNAL sum_h2     : STD_LOGIC_VECTOR(c_sum_h2_w-1 DOWNTO 0);
  
  SIGNAL result     : STD_LOGIC_VECTOR(c_sum_w-1 DOWNTO 0);
  
BEGIN

  leaf_pipe : IF g_nof_inputs = 1 GENERATE
    u_reg : ENTITY work.common_pipeline
    GENERIC MAP (
      g_representation => g_representation,
      g_pipeline       => g_pipeline,
      g_in_dat_w       => g_dat_w,
      g_out_dat_w      => g_dat_w+1
    )
    PORT MAP (
      clk     => clk,
      clken   => clken,
      in_dat  => in_dat,
      out_dat => result
    );
  END GENERATE;
  
  leaf_add : IF g_nof_inputs = 2 GENERATE
    u_add : ENTITY work.common_add_sub
    GENERIC MAP (
      g_direction       => "ADD",
      g_representation  => g_representation,
      g_pipeline_input  => c_pipeline_in,
      g_pipeline_output => c_pipeline_out,
      g_in_dat_w        => g_dat_w,
      g_out_dat_w       => c_sum_w
    )
    PORT MAP (
      clk     => clk,
      clken   => clken,
      in_a    => in_dat(  g_dat_w-1 DOWNTO 0      ),
      in_b    => in_dat(2*g_dat_w-1 DOWNTO g_dat_w),
      result  => result
    );
  END GENERATE;
  
  gen_tree : IF g_nof_inputs > 2 GENERATE
    u_h1 : common_adder_tree
    GENERIC MAP (
      g_representation => g_representation,
      g_pipeline       => g_pipeline,
      g_nof_inputs     => c_nof_h1,
      g_dat_w          => g_dat_w,
      g_sum_w          => c_sum_h1_w
    )
    PORT MAP (
      clk    => clk,
      clken  => clken,
      in_dat => in_dat(c_nof_h1*g_dat_w-1 DOWNTO 0),
      sum    => sum_h1
    );
    
    u_h2 : common_adder_tree
    GENERIC MAP (
      g_representation => g_representation,
      g_pipeline       => g_pipeline,
      g_nof_inputs     => c_nof_h2,
      g_dat_w          => g_dat_w,
      g_sum_w          => c_sum_h2_w
    )
    PORT MAP (
      clk    => clk,
      clken  => clken,
      in_dat => in_dat(g_nof_inputs*g_dat_w-1 DOWNTO c_nof_h1*g_dat_w),
      sum    => sum_h2
    );
    
    no_reg_h1 : IF c_stage_h1 = FALSE GENERATE
      sum_h1_reg <= sum_h1;
    END GENERATE;
    
    gen_reg_h1 : IF c_stage_h1 = TRUE GENERATE
      u_reg_h1 : ENTITY work.common_pipeline
      GENERIC MAP (
        g_representation => g_representation,
        g_pipeline       => g_pipeline,
        g_in_dat_w       => c_sum_h1_w,
        g_out_dat_w      => c_sum_h2_w
      )
      PORT MAP (
        clk     => clk,
        clken   => clken,
        in_dat  => sum_h1,
        out_dat => sum_h1_reg
      );
    END GENERATE;
    
    trunk_add : ENTITY work.common_add_sub
    GENERIC MAP (
      g_direction       => "ADD",
      g_representation  => g_representation,
      g_pipeline_input  => c_pipeline_in,
      g_pipeline_output => c_pipeline_out,
      g_in_dat_w        => c_sum_h_w,
      g_out_dat_w       => c_sum_w
    )
    PORT MAP (
      clk     => clk,
      clken   => clken,
      in_a    => sum_h1_reg,
      in_b    => sum_h2,
      result  => result
    );
  END GENERATE;
  
  sum <= RESIZE_SVEC(result, g_sum_w) WHEN g_representation="SIGNED" ELSE RESIZE_UVEC(result, g_sum_w);
  
END recursive;
