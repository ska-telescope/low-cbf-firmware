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
USE IEEE.std_logic_1164.ALL;
USE work.common_pkg.ALL;

-- Purpose: Parallel operation tree.
-- Description:
-- . Perform the operation on g_nof_inputs from an input vector in_data_vec.
-- Remarks:
-- . The implementation follows the same scheme as common_adder_tree_a_str  
-- . Instead of using common_pipeline in case g_nof_inputs is not a power of 2
--   it would have been easier to internally extend the input in_data_vec to a
--   power of 2 using default input values for the unused inputs or by
--   setting in_en_vec fixed to '0' for them. Synthesis will then optimise them
--   away.
-- . More operations can be added e.g.:
--   - Operation "ADD" to provide same as common_adder_tree.vhd, but with more
--     control over the stage pipelining thanks to g_pipeline_mod
--   - Operation "SEL" with in_sel input to provide same as
--     common_select_symbol.vhd but with pipelining per stage instead of only
--     at the output

ENTITY common_operation_tree IS
  GENERIC (
    g_operation      : STRING   := "MAX";      -- supported operations "MAX", "MIN"
    g_representation : STRING   := "SIGNED";
    g_pipeline       : NATURAL  := 0;          -- amount of output pipelining per stage
    g_pipeline_mod   : POSITIVE := 1;          -- only pipeline the stage output by g_pipeline when the stage number MOD g_pipeline_mod = 0
    g_nof_inputs     : NATURAL  := 4;          -- >= 1, nof stages = ceil_log2(g_nof_inputs)
    g_dat_w          : NATURAL  := 8
  );
  PORT (
    clk         : IN  STD_LOGIC;
    clken       : IN  STD_LOGIC := '1';
    in_data_vec : IN  STD_LOGIC_VECTOR(g_nof_inputs*g_dat_w-1 DOWNTO 0);
    in_en_vec   : IN  STD_LOGIC_VECTOR(g_nof_inputs        -1 DOWNTO 0);
    result      : OUT STD_LOGIC_VECTOR(             g_dat_w-1 DOWNTO 0)
  );
END common_operation_tree;

ARCHITECTURE str OF common_operation_tree IS

  -- operation pipelining
  CONSTANT c_pipeline_in  : NATURAL := 0;
  CONSTANT c_pipeline_out : NATURAL := g_pipeline;
  
  CONSTANT c_w            : NATURAL := g_dat_w;                 -- input data width
  
  CONSTANT c_N            : NATURAL := g_nof_inputs;            -- nof inputs to the adder tree
  CONSTANT c_nof_stages   : NATURAL := ceil_log2(c_N);          -- nof stages in the adder tree
  
  TYPE t_stage_arr    IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_N*g_dat_w-1 DOWNTO 0);
  TYPE t_stage_en_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_N        -1 DOWNTO 0);
  
  SIGNAL stage_arr    : t_stage_arr(-1 TO c_nof_stages-1) := (OTHERS=>(OTHERS=>'0'));
  SIGNAL stage_en_arr : t_stage_en_arr(-1 TO c_nof_stages-1) := (OTHERS=>(OTHERS=>'1'));
  
BEGIN

  gen_tree : IF g_nof_inputs > 1 GENERATE
    -- Input wires
    stage_arr(-1)    <= in_data_vec;
    stage_en_arr(-1) <= in_en_vec;    -- the first stage enables depend on in_en_vec, the other stages are always enabled
    
    -- Adder tree
    gen_stage : FOR j IN 0 TO c_nof_stages-1 GENERATE
      gen_oper : FOR i IN 0 TO (c_N+(2**j)-1)/(2**(j+1)) - 1 GENERATE
        u_operj : ENTITY work.common_operation
        GENERIC MAP (
          g_operation       => g_operation,
          g_representation  => g_representation,
          g_pipeline_input  => c_pipeline_in,
          g_pipeline_output => sel_a_b((j+1) MOD g_pipeline_mod = 0, c_pipeline_out, 0),
          g_dat_w           => c_w
        )
        PORT MAP (
          clk     => clk,
          clken   => clken,
          in_a    => stage_arr(j-1)((2*i+1)*c_w-1 DOWNTO (2*i+0)*c_w),
          in_b    => stage_arr(j-1)((2*i+2)*c_w-1 DOWNTO (2*i+1)*c_w),
          in_en_a => sl(stage_en_arr(j-1)(2*i   DOWNTO 2*i  )),
          in_en_b => sl(stage_en_arr(j-1)(2*i+1 DOWNTO 2*i+1)),
          result  => stage_arr(j)((i+1)*c_w-1 DOWNTO i*c_w)
        );
      END GENERATE;
      
      gen_pipe : IF ((c_N+(2**j)-1)/(2**j)) MOD 2 /= 0 GENERATE
        u_pipej : ENTITY work.common_pipeline
        GENERIC MAP (
          g_representation => g_representation,
          g_pipeline       => sel_a_b((j+1) MOD g_pipeline_mod = 0, c_pipeline_out, 0),
          g_in_dat_w       => c_w,
          g_out_dat_w      => c_w
        )
        PORT MAP (
          clk     => clk,
          clken   => clken,
          in_dat  => stage_arr(j-1)((2*((c_N+(2**j)-1)/(2**(j+1)))+1)*c_w-1 DOWNTO
                                    (2*((c_N+(2**j)-1)/(2**(j+1)))+0)*c_w),
          out_dat => stage_arr(j)(((c_N+(2**j)-1)/(2**(j+1))+1)*c_w-1 DOWNTO
                                  ((c_N+(2**j)-1)/(2**(j+1))  )*c_w)
        );
      END GENERATE;
    END GENERATE;
    
    result <= stage_arr(c_nof_stages-1)(c_w-1 DOWNTO 0);
  END GENERATE;  -- gen_tree

  no_tree : IF g_nof_inputs = 1 GENERATE
    u_reg : ENTITY work.common_pipeline
    GENERIC MAP (
      g_representation => g_representation,
      g_pipeline       => g_pipeline,
      g_in_dat_w       => g_dat_w,
      g_out_dat_w      => g_dat_w
    )
    PORT MAP (
      clk     => clk,
      clken   => clken,
      in_dat  => in_data_vec,
      out_dat => result
    );  
  END GENERATE;  -- no_tree
  
END str;
