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

LIBRARY IEEE, common_lib, technology_lib;
USE IEEE.std_logic_1164.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE work.tech_mult_component_pkg.ALL;

-- Declare IP libraries to ensure default binding in simulation. The IP library clause is ignored by synthesis.
LIBRARY ip_stratixiv_mult_lib;
--LIBRARY ip_arria10_mult_lib;
--LIBRARY ip_arria10_mult_rtl_lib;
LIBRARY ip_arria10_complex_mult_altmult_complex_150;
LIBRARY ip_arria10_complex_mult_rtl_lib;


ENTITY tech_complex_mult IS
  GENERIC (
    g_sim              : BOOLEAN := TRUE;
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
    result_re  : OUT  STD_LOGIC_VECTOR(g_out_p_w-1 DOWNTO 0);
    result_im  : OUT  STD_LOGIC_VECTOR(g_out_p_w-1 DOWNTO 0)
  );
END tech_complex_mult;

ARCHITECTURE str of tech_complex_mult is 

  -- Force to maximum 18 bit width, because:
  -- . the ip_stratixiv_complex_mult is generated for 18b inputs and 36b output and then uses 4 real multipliers and no additional registers
  -- . if one input   > 18b then another IP needs to be regenerated and that will use  8 real multipliers and some extra LUTs and registers
  -- . if both inputs > 18b then another IP needs to be regenerated and that will use 16 real multipliers and some extra LUTs and registers
  -- . if the output is set to 18b+18b + 1b =37b to account for the sum then another IP needs to be regenerated and that will use some extra registers
  -- ==> for inputs <= 18b this ip_stratixiv_complex_mult is appropriate and it can not be made parametrisable to fit also inputs > 18b.
  CONSTANT c_dsp_dat_w    : NATURAL  := 18;
  CONSTANT c_dsp_prod_w   : NATURAL  := 2*c_dsp_dat_w;
  
  SIGNAL ar        : STD_LOGIC_VECTOR(c_dsp_dat_w-1 DOWNTO 0);
  SIGNAL ai        : STD_LOGIC_VECTOR(c_dsp_dat_w-1 DOWNTO 0);
  SIGNAL br        : STD_LOGIC_VECTOR(c_dsp_dat_w-1 DOWNTO 0);
  SIGNAL bi        : STD_LOGIC_VECTOR(c_dsp_dat_w-1 DOWNTO 0);
  SIGNAL mult_re   : STD_LOGIC_VECTOR(c_dsp_prod_w-1 DOWNTO 0);
  SIGNAL mult_im   : STD_LOGIC_VECTOR(c_dsp_prod_w-1 DOWNTO 0);

  -- sim_model=1
  SIGNAL result_re_undelayed : STD_LOGIC_VECTOR(g_in_b_w+g_in_a_w-1 DOWNTO 0);
  SIGNAL result_im_undelayed : STD_LOGIC_VECTOR(g_in_b_w+g_in_a_w-1 DOWNTO 0);

begin

  gen_ip_stratixiv_ip : IF (g_sim=FALSE OR (g_sim=TRUE AND g_sim_level=0)) AND (g_technology=c_tech_stratixiv AND g_variant="IP") GENERATE

    -- Adapt DSP input widths
    ar <= RESIZE_SVEC(in_ar, c_dsp_dat_w);
    ai <= RESIZE_SVEC(in_ai, c_dsp_dat_w);
    br <= RESIZE_SVEC(in_br, c_dsp_dat_w);
    bi <= RESIZE_SVEC(in_bi, c_dsp_dat_w) WHEN g_conjugate_b=FALSE ELSE TO_SVEC(-TO_SINT(in_bi), c_dsp_dat_w);

    u0 : ip_stratixiv_complex_mult
    PORT MAP (
         aclr        => rst,
         clock       => clk,
         dataa_imag  => ai,
         dataa_real  => ar,
         datab_imag  => bi,
         datab_real  => br,
         ena         => clken,
         result_imag => mult_im,
         result_real => mult_re
         );

    -- Back to true input widths and then resize for output width
    result_re <= RESIZE_SVEC(mult_re, g_out_p_w);
    result_im <= RESIZE_SVEC(mult_im, g_out_p_w);

  END GENERATE;
   
  gen_ip_stratixiv_rtl : IF (g_sim=FALSE OR (g_sim=TRUE AND g_sim_level=0)) AND (g_technology=c_tech_stratixiv AND g_variant="RTL") GENERATE
    u0 : ip_stratixiv_complex_mult_rtl
  GENERIC MAP(
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
  END GENERATE;

  gen_ip_arria10_ip : IF (g_sim=FALSE OR (g_sim=TRUE AND g_sim_level=0)) AND (g_technology=c_tech_arria10 AND g_variant="IP") GENERATE

    -- Adapt DSP input widths
    ar <= RESIZE_SVEC(in_ar, c_dsp_dat_w);
    ai <= RESIZE_SVEC(in_ai, c_dsp_dat_w);
    br <= RESIZE_SVEC(in_br, c_dsp_dat_w);
    bi <= RESIZE_SVEC(in_bi, c_dsp_dat_w) WHEN g_conjugate_b=FALSE ELSE TO_SVEC(-TO_SINT(in_bi), c_dsp_dat_w);

    u0 : ip_arria10_complex_mult
    PORT MAP (
         aclr        => rst,
         clock       => clk,
         dataa_imag  => ai,
         dataa_real  => ar,
         datab_imag  => bi,
         datab_real  => br,
         ena         => clken,
         result_imag => mult_im,
         result_real => mult_re
         );

    -- Back to true input widths and then resize for output width
    result_re <= RESIZE_SVEC(mult_re, g_out_p_w);
    result_im <= RESIZE_SVEC(mult_im, g_out_p_w);

  END GENERATE;

  gen_ip_arria10_rtl : IF (g_sim=FALSE OR (g_sim=TRUE AND g_sim_level=0)) AND (g_technology=c_tech_arria10 AND g_variant="RTL") GENERATE
    u0 : ip_arria10_complex_mult_rtl
  GENERIC MAP(
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
  END GENERATE;

  -------------------------------------------------------------------------------
  -- Model: forward concatenated inputs to the 'result' output
  -- 
  -- Example:
  --                                    ______ 
  -- Input B.real (in_br) = 0x1111 --> |      |
  --        .imag (in_bi) = 0xBBBB --> |      |
  --                                   | mult | --> Output result.real = 0x00000000
  -- Input A.real (in_ar) = 0x0000 --> |      |                  .imag = 0xBBBBAAAA
  --        .imag (in_ai) = 0xAAAA --> |______|
  -- 
  -- Note: this model is synthsizable as well.
  -- 
  -------------------------------------------------------------------------------
  gen_sim_level_1 : IF g_sim=TRUE AND g_sim_level=1 GENERATE --FIXME: g_sim required? This is synthesizable.

    result_re_undelayed <= in_br & in_ar;
    result_im_undelayed <= in_bi & in_ai;

    u_common_pipeline_re : entity common_lib.common_pipeline
    generic map (
      g_pipeline  => 3,
      g_in_dat_w  => g_in_b_w+g_in_a_w,
      g_out_dat_w => g_out_p_w
    )
    port map (
      clk     => clk,
      in_dat  => result_re_undelayed,
      out_dat => result_re
    );

    u_common_pipeline_im : entity common_lib.common_pipeline
    generic map (
      g_pipeline  => 3,
      g_in_dat_w  => g_in_b_w+g_in_a_w,
      g_out_dat_w => g_out_p_w
    )
    port map (
      clk     => clk,
      in_dat  => result_im_undelayed,
      out_dat => result_im
    );

  END GENERATE;

end str;

