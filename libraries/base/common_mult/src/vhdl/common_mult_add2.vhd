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

LIBRARY IEEE, technology_lib, tech_mult_lib, common_lib;
USE IEEE.std_logic_1164.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;

-- Function: vector low part product + or - vector high part product
--   Call:
--     a = a(1) & a(0)
--     b = b(1) & b(0)
--   then:
--     result = a(0)*b(0) + a(1)*b(1) when g_add_sub = "ADD"
--     result = a(0)*b(0) - a(1)*b(1) when g_add_sub = "SUB"
--   and:
--     res = RESIZE_NUM(result)
--
-- Architectures:
-- . rtl      : uses RTL to have all registers in one clocked process
--

ENTITY common_mult_add2 IS
  GENERIC (
    g_technology       : t_technology  := c_tech_select_default;
    g_variant          : STRING   := "RTL";
    g_in_a_w           : POSITIVE;
    g_in_b_w           : POSITIVE;
    g_res_w            : POSITIVE;          -- g_in_a_w + g_in_b_w + log2(4)
    g_force_dsp        : BOOLEAN := TRUE;   -- when TRUE resize input width to >= 18
    g_add_sub          : STRING := "ADD";   -- or "SUB" only available with rtl architecture
    g_nof_mult         : INTEGER := 4;      -- fixed
    g_pipeline_input   : NATURAL := 1;      -- 0 or 1
    g_pipeline_product : NATURAL := 0;      -- 0 or 1
    g_pipeline_adder   : NATURAL := 1;      -- 0 or 1, first sum
    g_pipeline_output  : NATURAL := 1       -- >= 0,   second sum and optional rounding
  );
  PORT (
    rst        : IN  STD_LOGIC := '0';
    clk        : IN  STD_LOGIC;
    clken      : IN  STD_LOGIC := '1';
    in_a       : IN  STD_LOGIC_VECTOR(g_nof_mult*g_in_a_w-1 DOWNTO 0);
    in_b       : IN  STD_LOGIC_VECTOR(g_nof_mult*g_in_b_w-1 DOWNTO 0);
    res        : OUT STD_LOGIC_VECTOR(g_res_w-1 DOWNTO 0)
  );
END common_mult_add2;

ARCHITECTURE str OF common_mult_add2 IS

  -- Extra output pipelining is only needed when g_pipeline_output > 1
  CONSTANT c_pipeline_output : NATURAL := sel_a_b(g_pipeline_output>0, g_pipeline_output-1, 0);
  SIGNAL   result            : STD_LOGIC_VECTOR(res'RANGE);

BEGIN

  u_mult_add2 : ENTITY tech_mult_lib.tech_mult_add2
  GENERIC MAP(
    g_technology       => g_technology,
    g_variant          => g_variant,
    g_in_a_w           => g_in_a_w,
    g_in_b_w           => g_in_b_w,
    g_res_w            => g_res_w,
    g_force_dsp        => g_force_dsp,
    g_add_sub          => g_add_sub,
    g_nof_mult         => g_nof_mult,
    g_pipeline_input   => g_pipeline_input,
    g_pipeline_product => g_pipeline_product,
    g_pipeline_adder   => g_pipeline_adder,
    g_pipeline_output  => g_pipeline_output
  )
  PORT MAP(
    rst   => rst,
    clk   => clk,
    clken => clken,
    in_a  => in_a,
    in_b  => in_b,
    res   => result
  );

  ------------------------------------------------------------------------------
  -- Extra output pipelining
  ------------------------------------------------------------------------------
  
  u_output_pipe : ENTITY common_lib.common_pipeline  -- pipeline output
  GENERIC MAP (
    g_representation => "SIGNED",
    g_pipeline       => c_pipeline_output,
    g_in_dat_w       => res'LENGTH,
    g_out_dat_w      => res'LENGTH
  )
  PORT MAP (
    clk     => clk,
    clken   => clken,
    in_dat  => result,
    out_dat => res
  );
  
END str;
