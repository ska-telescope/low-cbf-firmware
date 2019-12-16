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

LIBRARY IEEE, common_lib, technology_lib, tech_mult_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;

--
-- Function: Signed complex multiply
--   p = a * b       when g_conjugate_b = FALSE
--     = (ar + j ai) * (br + j bi)
--     =  ar*br - ai*bi + j ( ar*bi + ai*br)
--
--   p = a * conj(b) when g_conjugate_b = TRUE
--     = (ar + j ai) * (br - j bi)
--     =  ar*br + ai*bi + j (-ar*bi + ai*br)
--
-- Architectures:
-- . rtl          : uses RTL to have all registers in one clocked process
-- . str          : uses two RTL instances of common_mult_add2 for out_pr and out_pi
-- . str_stratix4 : uses two Stratix4 instances of common_mult_add2 for out_pr and out_pi
-- . stratix4     : uses MegaWizard component from common_complex_mult(stratix4).vhd
-- . rtl_dsp      : uses RTL with one process (as in Altera example)
-- . altera_rtl   : uses RTL with one process (as in Altera example, by Raj R. Thilak)
--
-- Preferred architecture: 'str', see synth\quartus\common_top.vhd

ENTITY common_complex_mult IS
  GENERIC (
    g_sim              : BOOLEAN := FALSE;
    g_sim_level        : NATURAL := 0; -- 0: Simulate variant passed via g_variant for given g_technology
    g_technology       : t_technology := c_tech_select_default;
    g_variant          : STRING := "IP";
    g_in_a_w           : POSITIVE;
    g_in_b_w           : POSITIVE;
    g_out_p_w          : POSITIVE;          -- default use g_out_p_w = g_in_a_w+g_in_b_w = c_prod_w
    g_conjugate_b      : BOOLEAN := FALSE;
    g_pipeline_input   : NATURAL := 1;      -- 0 or 1
    g_pipeline_product : NATURAL := 0;      -- 0 or 1
    g_pipeline_adder   : NATURAL := 1;      -- 0 or 1
    g_pipeline_output  : NATURAL := 1       -- >= 0
  );
  PORT (
    rst        : IN   STD_LOGIC := '0';
    clk        : IN   STD_LOGIC;
    clken      : IN   STD_LOGIC := '1';
    in_ar      : IN   STD_LOGIC_VECTOR(g_in_a_w-1 DOWNTO 0);              
    in_ai      : IN   STD_LOGIC_VECTOR(g_in_a_w-1 DOWNTO 0);              
    in_br      : IN   STD_LOGIC_VECTOR(g_in_b_w-1 DOWNTO 0);              
    in_bi      : IN   STD_LOGIC_VECTOR(g_in_b_w-1 DOWNTO 0);
    in_val     : IN   STD_LOGIC := '1';
    out_pr     : OUT  STD_LOGIC_VECTOR(g_out_p_w-1 DOWNTO 0);              
    out_pi     : OUT  STD_LOGIC_VECTOR(g_out_p_w-1 DOWNTO 0);
    out_val    : OUT  STD_LOGIC
  );     
END common_complex_mult;


ARCHITECTURE str OF common_complex_mult IS

  CONSTANT c_pipeline        : NATURAL := g_pipeline_input + g_pipeline_product + g_pipeline_adder + g_pipeline_output;
  
  -- MegaWizard IP ip_stratixiv_complex_mult was generated with latency c_dsp_latency = 3
  CONSTANT c_dsp_latency     : NATURAL := 3;
  
  -- Extra output pipelining is only needed when c_pipeline > c_dsp_latency
  CONSTANT c_pipeline_output : NATURAL := sel_a_b(c_pipeline>c_dsp_latency, c_pipeline-c_dsp_latency, 0);  
  
  SIGNAL result_re : STD_LOGIC_VECTOR(g_out_p_w-1 DOWNTO 0);
  SIGNAL result_im : STD_LOGIC_VECTOR(g_out_p_w-1 DOWNTO 0);

BEGIN

  -- User specificied latency must be >= MegaWizard IP dsp_mult_add2 latency
  ASSERT c_pipeline >= c_dsp_latency
    REPORT "tech_complex_mult: pipeline value not supported"
    SEVERITY FAILURE;
    
  -- Propagate in_val with c_pipeline latency
  u_out_val : ENTITY common_lib.common_pipeline_sl
  GENERIC MAP (
    g_pipeline  => c_pipeline
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    clken   => clken,
    in_dat  => in_val,
    out_dat => out_val
  );

  u_complex_mult : ENTITY tech_mult_lib.tech_complex_mult
  GENERIC MAP(
    g_sim              => g_sim,
    g_sim_level        => g_sim_level,
    g_technology       => g_technology,
    g_variant          => g_variant,
    g_in_a_w           => g_in_a_w,
    g_in_b_w           => g_in_b_w,
    g_out_p_w          => g_out_p_w,
    g_conjugate_b      => g_conjugate_b,
    g_pipeline_input   => g_pipeline_input,
    g_pipeline_product => g_pipeline_product,
    g_pipeline_adder   => g_pipeline_adder,
    g_pipeline_output  => g_pipeline_output
  )
  PORT MAP(
    rst        => rst,
    clk        => clk,
    clken      => clken,
    in_ar      => in_ar,
    in_ai      => in_ai,
    in_br      => in_br,
    in_bi      => in_bi,
    result_re  => result_re,
    result_im  => result_im
  );     

  ------------------------------------------------------------------------------
  -- Extra output pipelining
  ------------------------------------------------------------------------------
  
  u_output_re_pipe : ENTITY common_lib.common_pipeline  -- pipeline output
  GENERIC MAP (
    g_representation => "SIGNED",
    g_pipeline       => c_pipeline_output,
    g_in_dat_w       => g_out_p_w,
    g_out_dat_w      => g_out_p_w
  )
  PORT MAP (
    clk     => clk,
    clken   => clken,
    in_dat  => STD_LOGIC_VECTOR(result_re),
    out_dat => out_pr
  );

  u_output_im_pipe : ENTITY common_lib.common_pipeline  -- pipeline output
  GENERIC MAP (
    g_representation => "SIGNED",
    g_pipeline       => c_pipeline_output,
    g_in_dat_w       => g_out_p_w,
    g_out_dat_w      => g_out_p_w
  )
  PORT MAP (
    clk     => clk,
    clken   => clken,
    in_dat  => STD_LOGIC_VECTOR(result_im),
    out_dat => out_pi
  );


END str;
