-------------------------------------------------------------------------------
--
-- Copyright (C) 2010
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
USE IEEE.std_logic_1164.ALL;
USE common_lib.common_pkg.ALL;

-- Status:
-- . Compiles OK, but still needs to be functionally verified with a test bench.
-- . Add support for out_dat width is g_dat_w+1
-- . Perhaps u_stage_add_input can be merged into gen_stage

-- Purpose: Multi stage adder
-- Description:
--   E.g. a N stage adder will need N pipeline stages and each pipeline stage
--   has N parallel sections. The N stages are needed to ripple trhough the 
--   carry of the N sections. Each section is an instantiation of
--   common_add_sub, so in total N**2 sections.
-- Remarks:
-- . Synthesizing common_top.vhd shows that even a 64b adder can run at 500 MHz
--   on Stratix IV so this multi stage adder is not needed.


ENTITY common_adder_staged IS
  GENERIC (
    g_dat_w            : NATURAL;
    g_adder_w          : NATURAL;  -- g_adder_w internal adder width
    g_pipeline_input   : NATURAL;  -- 0 no input registers, else register input
    g_pipeline_output  : NATURAL   -- pipeline for the adder, must be >= ceil(g_dat_w / g_adder_w) to allow g_adder_w < g_dat_w
  );
  PORT (
    clk         : IN  STD_LOGIC;
    clken       : IN  STD_LOGIC := '1';
    in_dat_a    : IN  STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    in_dat_b    : IN  STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    in_val      : IN  STD_LOGIC := '1';
    out_dat     : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    out_val     : OUT STD_LOGIC
  );
END common_adder_staged;


ARCHITECTURE str OF common_adder_staged IS
  
  CONSTANT c_pipeline  : NATURAL := g_pipeline_input + g_pipeline_output;
  
  CONSTANT c_nof_adder : NATURAL := g_dat_w / g_adder_w + sel_a_b(g_dat_w MOD g_adder_w = 0, 0, 1);

  TYPE t_inp_matrix IS ARRAY (INTEGER RANGE <>, INTEGER RANGE <>) OF STD_LOGIC_VECTOR(g_adder_w-1 DOWNTO 0);  -- (STAGE, SECTION)
  TYPE t_sum_matrix IS ARRAY (INTEGER RANGE <>, INTEGER RANGE <>) OF STD_LOGIC_VECTOR(g_adder_w   DOWNTO 0);  -- (STAGE, SECTION), width +1 for carry bit
  
  -- Input signals
  SIGNAL reg_dat_a      : STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL reg_dat_b      : STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0) := (OTHERS=>'0');
  
  SIGNAL vec_dat_a      : STD_LOGIC_VECTOR(c_nof_adder*g_adder_w-1 DOWNTO 0);
  SIGNAL vec_dat_b      : STD_LOGIC_VECTOR(c_nof_adder*g_adder_w-1 DOWNTO 0);
  
  -- Internal sub adders
  SIGNAL m_a            : t_inp_matrix(0 TO c_nof_adder-1,  0 TO c_nof_adder-1);
  SIGNAL m_b            : t_inp_matrix(0 TO c_nof_adder-1,  0 TO c_nof_adder-1);
  SIGNAL m_sum          : t_sum_matrix(0 TO c_nof_adder-1, -1 TO c_nof_adder-1);  -- section index -1 for first zero carry input
  
  SIGNAL vec_add        : STD_LOGIC_VECTOR(c_nof_adder*g_adder_w-1 DOWNTO 0);
  
  -- Pipeline control signals, map to slv to be able to use common_pipeline
  SIGNAL in_val_slv     : STD_LOGIC_VECTOR(0 DOWNTO 0);
  SIGNAL out_val_slv    : STD_LOGIC_VECTOR(0 DOWNTO 0);
  
BEGIN

  ASSERT NOT(g_pipeline_output < c_nof_adder AND g_adder_w < g_dat_w)
    REPORT "common_adder_staged: internal adder width < output adder width is only possible for pipeline >= nof adder"
    SEVERITY FAILURE;
  
  ------------------------------------------------------------------------------
  -- Input
  ------------------------------------------------------------------------------
  
  u_pipe_a : ENTITY common_lib.common_pipeline
  GENERIC MAP (
    g_representation => "UNSIGNED",
    g_pipeline       => g_pipeline_input,
    g_reset_value    => 0,
    g_in_dat_w       => g_dat_w,
    g_out_dat_w      => g_dat_w
  )
  PORT MAP (
    clk     => clk,
    clken   => clken,
    in_dat  => in_dat_a,
    out_dat => reg_dat_a
  );
  
  u_pipe_b : ENTITY common_lib.common_pipeline
  GENERIC MAP (
    g_representation => "UNSIGNED",
    g_pipeline       => g_pipeline_input,
    g_reset_value    => 0,
    g_in_dat_w       => g_dat_w,
    g_out_dat_w      => g_dat_w
  )
  PORT MAP (
    clk     => clk,
    clken   => clken,
    in_dat  => in_dat_b,
    out_dat => reg_dat_b
  );
  
  ------------------------------------------------------------------------------
  -- Multiple adder sections (g_adder_w < g_dat_w)
  --
  -- . The number of sections depends on the g_dat_w / g_adder_w, the g_adder_w
  --   has to be small enough to ease timing closure for synthesis
  -- . The first register stage adds the input data and the subsequent stages
  --   add the carry from the preceding stage
  -- . The number of stages equals the number of sections.
  -- . The example below shows a case where all stages are needed to propagate
  --   the carry:
  --
  --          adder sections
  --             2    1    0   -1
  --           876  543  210       -- g_dat_w = 9, g_adder_w = 3
  -- STAGE 0:
  --           111  111  111       -- m_a(  0, SECTION) = in_dat_a
  --           000  000  001       -- m_b(  0, SECTION) = in_dat_b
  --          0111 0111 1000    0  -- m_sum(0, SECTION)
  -- STAGE 1:
  --           111  111  000       -- m_a(  1, SECTION) = m_sum(0, SECTION  )(2:0)
  --             0    1    0       -- m_b(  1, SECTION) = m_sum(0, SECTION-1)(3)   = carry
  --          0111 1000 0000    0  -- m_sum(1, SECTION)
  -- STAGE 2:
  --           111  000  000       -- m_a(  2, SECTION) = m_sum(1, SECTION  )(2:0)
  --             1    0    0       -- m_b(  2, SECTION) = m_sum(1, SECTION-1)(3)   = carry
  --          1000 0000 0000    0  -- m_sum(2, SECTION)
  --
  --           000  000  000                            = out_dat
  ------------------------------------------------------------------------------
  
  gen_multi : IF g_pipeline_output>=c_nof_adder AND g_adder_w < g_dat_w GENERATE
  
    -- resize input length to multiple of g_adder_w
    vec_dat_a <= RESIZE_SVEC(reg_dat_a, c_nof_adder*g_adder_w);
    vec_dat_b <= RESIZE_SVEC(reg_dat_b, c_nof_adder*g_adder_w);
    
    -- initialize the first carry input for each stage to zero
    init_carry : FOR STAGE IN 0 TO c_nof_adder-1 GENERATE
      m_sum(STAGE, -1) <= (OTHERS=>'0');
    END GENERATE;
    
    gen_sections : FOR SECTION IN 0 TO c_nof_adder-1 GENERATE
      -- Map the input slv to adder stage 0
      m_a(0, SECTION) <= vec_dat_a((SECTION+1)*g_adder_w-1 DOWNTO SECTION*g_adder_w);
      m_b(0, SECTION) <= vec_dat_b((SECTION+1)*g_adder_w-1 DOWNTO SECTION*g_adder_w);
      
      u_stage_add_input : ENTITY common_lib.common_add_sub
      GENERIC MAP (
        g_direction       => "ADD",
        g_representation  => "UNSIGNED",  -- must treat the sections as unsigned
        g_pipeline_input  => 0,
        g_pipeline_output => 1,
        g_in_dat_w        => g_adder_w,
        g_out_dat_w       => g_adder_w+1
      )
      PORT MAP (
        clk     => clk,
        clken   => clken,
        in_a    => m_a(0, SECTION),
        in_b    => m_b(0, SECTION),
        result  => m_sum(0, SECTION)
      );
      
      gen_stage : FOR STAGE IN 1 TO c_nof_adder-1 GENERATE
        m_a(STAGE, SECTION) <=             m_sum(STAGE-1, SECTION  )(g_adder_w-1 DOWNTO 0);   -- sum from preceding stage
        m_b(STAGE, SECTION) <= RESIZE_UVEC(m_sum(STAGE-1, SECTION-1)(g_adder_w), g_adder_w);  -- carry from less significant section in preceding stage

        -- Adder stages to add and propagate the carry for each section
        u_add_carry : ENTITY common_lib.common_add_sub
        GENERIC MAP (
          g_direction       => "ADD",
          g_representation  => "UNSIGNED",  -- must treat the sections as unsigned
          g_pipeline_input  => 0,
          g_pipeline_output => 1,
          g_in_dat_w        => g_adder_w,
          g_out_dat_w       => g_adder_w+1
        )
        PORT MAP (
          clk     => clk,
          clken   => clken,
          in_a    => m_a(STAGE, SECTION),
          in_b    => m_b(STAGE, SECTION),  -- + carry 0 or 1 from the less significant adder section
          result  => m_sum(STAGE, SECTION)
        );
      END GENERATE;
      
      -- map the adder sections from the last stage to the output to slv
      vec_add((SECTION+1)*g_adder_w-1 DOWNTO SECTION*g_adder_w) <= m_sum(c_nof_adder-1, SECTION)(g_adder_w-1 DOWNTO 0);    
    END GENERATE;
      
    -- Rest output pipeline
    u_out_val : ENTITY common_lib.common_pipeline
    GENERIC MAP (
      g_representation => "UNSIGNED",
      g_pipeline       => g_pipeline_output-c_nof_adder,
      g_reset_value    => 0,
      g_in_dat_w       => g_dat_w,
      g_out_dat_w      => g_dat_w
    )
    PORT MAP (
      clk     => clk,
      clken   => clken,
      in_dat  => vec_add(g_dat_w-1 DOWNTO 0),  -- resize length of multiple g_adder_w back to g_dat_w width
      out_dat => out_dat
    );
  END GENERATE;
  
  
  ------------------------------------------------------------------------------
  -- Parallel output control pipeline
  ------------------------------------------------------------------------------
  
  u_out_val : ENTITY common_lib.common_pipeline
  GENERIC MAP (
    g_representation => "UNSIGNED",
    g_pipeline       => c_pipeline,
    g_reset_value    => 0,
    g_in_dat_w       => 1,
    g_out_dat_w      => 1
  )
  PORT MAP (
    clk     => clk,
    clken   => clken,
    in_dat  => in_val_slv,
    out_dat => out_val_slv
  );
  
  in_val_slv(0) <= in_val;
  out_val       <= out_val_slv(0);
    
END str;
