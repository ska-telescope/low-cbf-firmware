-------------------------------------------------------------------------------
--
-- Copyright (C) 2011
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

LIBRARY ieee, common_lib, tech_mult_lib, technology_lib;
USE ieee.std_logic_1164.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE common_lib.common_pkg.ALL;

-- Function: Default one or more independent products dependent on g_nof_mult
--
--   If g_nof_mult = 2 then the input vectors are
--     a = a(1) & a(0) and b = b(1) & b(0)
--   and the independent products in the product vector will be:
--     p = a(1)*b(1) & a(0)*b(0)
--
-- Remarks:
-- . When g_out_p_w < g_in_a_w+g_in_b_w then the common_mult truncates the
--   MSbit of the product.
-- . For c_prod_w = g_in_a_w+g_in_b_w the full product range is preserved. Use
--   g_out_p_w = c_prod_w-1 to skip the double sign bit that is only needed
--   when the maximum positive product -2**(g_in_a_w-1) * -2**(g_in_b_w-1) has
--   to be represented, which is typically not needed in DSP.

ENTITY common_mult IS
  GENERIC (
    g_technology       : t_technology := c_tech_select_default;
    g_variant          : STRING   := "IP";
    g_in_a_w           : POSITIVE := 18;
    g_in_b_w           : POSITIVE := 18;
    g_out_p_w          : POSITIVE := 36;      -- c_prod_w = g_in_a_w+g_in_b_w, use smaller g_out_p_w to truncate MSbits, or larger g_out_p_w to extend MSbits
    g_nof_mult         : POSITIVE := 1;       -- using 2 for 18x18, 4 for 9x9 may yield better results when inferring * is used
    g_pipeline_input   : NATURAL  := 1;        -- 0 or 1
    g_pipeline_product : NATURAL  := 1;        -- 0 or 1
    g_pipeline_output  : NATURAL  := 1;        -- >= 0
    g_representation   : STRING   := "SIGNED"   -- or "UNSIGNED"
  );
  PORT (
    rst        : IN  STD_LOGIC := '0';
    clk        : IN  STD_LOGIC;
    clken      : IN  STD_LOGIC := '1';
    in_a       : IN  STD_LOGIC_VECTOR(g_nof_mult*g_in_a_w-1 DOWNTO 0);
    in_b       : IN  STD_LOGIC_VECTOR(g_nof_mult*g_in_b_w-1 DOWNTO 0);
    out_p      : OUT STD_LOGIC_VECTOR(g_nof_mult*g_out_p_w-1 DOWNTO 0)
  );
END common_mult;

ARCHITECTURE str OF common_mult IS

  -- Extra output pipelining using common_pipeline is only needed when g_pipeline_output > 1
  CONSTANT c_pipeline_output : NATURAL := sel_a_b(g_pipeline_output>0, g_pipeline_output-1, 0);

  SIGNAL result        : STD_LOGIC_VECTOR(out_p'RANGE);                      -- stage dependent on g_pipeline_output  being 0 or 1

BEGIN

  u_mult : ENTITY tech_mult_lib.tech_mult
  GENERIC MAP(
    g_technology       => g_technology,
    g_variant          => g_variant,
    g_in_a_w           => g_in_a_w,
    g_in_b_w           => g_in_b_w,
    g_out_p_w          => g_out_p_w,
    g_nof_mult         => g_nof_mult,
    g_pipeline_input   => g_pipeline_input,
    g_pipeline_product => g_pipeline_product,
    g_pipeline_output  => g_pipeline_output,
    g_representation   => g_representation
  )
  PORT MAP(
    rst        => rst,
    clk        => clk,
    clken      => clken,
    in_a       => in_a,
    in_b       => in_b,
    out_p      => result
  );     

  ------------------------------------------------------------------------------
  -- Extra output pipelining
  ------------------------------------------------------------------------------

  u_output_pipe : ENTITY common_lib.common_pipeline  -- pipeline output
  GENERIC MAP (
    g_representation => g_representation,
    g_pipeline       => c_pipeline_output,
    g_in_dat_w       => result'LENGTH,
    g_out_dat_w      => result'LENGTH
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    clken   => clken,
    in_dat  => STD_LOGIC_VECTOR(result),
    out_dat => out_p
  );

END str;
