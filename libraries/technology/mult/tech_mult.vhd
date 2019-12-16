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
LIBRARY ip_arria10_mult_lib;


ENTITY tech_mult IS
  GENERIC (
    g_technology       : t_technology  := c_tech_select_default;
    g_variant          : STRING := "IP";
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
    rst        : IN  STD_LOGIC;
    clk        : IN  STD_LOGIC;
    clken      : IN  STD_LOGIC := '1';
    in_a       : IN  STD_LOGIC_VECTOR(g_nof_mult*g_in_a_w-1 DOWNTO 0);
    in_b       : IN  STD_LOGIC_VECTOR(g_nof_mult*g_in_b_w-1 DOWNTO 0);
    out_p      : OUT STD_LOGIC_VECTOR(g_nof_mult*g_out_p_w-1 DOWNTO 0)
  );
END tech_mult;

ARCHITECTURE str of tech_mult is

  -- When g_out_p_w < g_in_a_w+g_in_b_w then the LPM_MULT truncates the LSbits of the product. Therefore
  -- define c_prod_w to be able to let common_mult truncate the LSBits of the product.
  CONSTANT c_prod_w : NATURAL := g_in_a_w + g_in_b_w;

  SIGNAL prod  : STD_LOGIC_VECTOR(g_nof_mult*c_prod_w-1 DOWNTO 0);

begin

  gen_ip_stratixiv_ip : IF (g_technology=c_tech_stratixiv AND g_variant="IP") GENERATE
    u0 : ip_stratixiv_mult
    GENERIC MAP(
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
      clk        => clk,
      clken      => clken,
      in_a       => in_a,
      in_b       => in_b,
      out_p      => prod
    );
  END GENERATE;

  gen_ip_stratixiv_rtl : IF (g_technology=c_tech_stratixiv AND g_variant="RTL") GENERATE
    u0 : ip_stratixiv_mult_rtl
    GENERIC MAP(
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
      out_p      => prod
    );
  END GENERATE;

  gen_ip_arria10_ip : IF (g_technology=c_tech_arria10 AND g_variant="IP") GENERATE
    u0 : ip_arria10_mult
    GENERIC MAP(
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
      clk        => clk,
      clken      => clken,
      in_a       => in_a,
      in_b       => in_b,
      out_p      => prod
    );
  END GENERATE;

  gen_ip_arria10_rtl : IF (g_technology=c_tech_arria10 AND g_variant="RTL") GENERATE
    u0 : ip_arria10_mult_rtl
    GENERIC MAP(
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
      out_p      => prod
    );
  END GENERATE;

  gen_trunk : FOR I IN 0 TO g_nof_mult-1 GENERATE
  -- Truncate MSbits, also for signed (common_pkg.vhd for explanation of RESIZE_SVEC)
    out_p((I+1)*g_out_p_w-1 DOWNTO I*g_out_p_w) <= RESIZE_SVEC(prod((I+1)*c_prod_w-1 DOWNTO I*c_prod_w), g_out_p_w) WHEN g_representation="SIGNED" ELSE
                                                  RESIZE_UVEC(prod((I+1)*c_prod_w-1 DOWNTO I*c_prod_w), g_out_p_w);
  END GENERATE;

end str;

