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
USE IEEE.STD_LOGIC_1164.ALL;


ENTITY common_complex_add_sub IS
  GENERIC (
    g_direction       : STRING  := "ADD";      -- or "SUB"
    g_representation  : STRING  := "SIGNED";   -- or "UNSIGNED"
    g_pipeline_input  : NATURAL := 0;          -- 0 or 1
    g_pipeline_output : NATURAL := 1;          -- >= 0
    g_in_dat_w        : NATURAL := 8;
    g_out_dat_w       : NATURAL := 9           -- only support g_out_dat_w=g_in_dat_w and g_out_dat_w=g_in_dat_w+1
  );
  PORT (
    clk      : IN  STD_LOGIC;
    clken    : IN  STD_LOGIC := '1';
    in_ar    : IN  STD_LOGIC_VECTOR(g_in_dat_w-1 DOWNTO 0);
    in_ai    : IN  STD_LOGIC_VECTOR(g_in_dat_w-1 DOWNTO 0);
    in_br    : IN  STD_LOGIC_VECTOR(g_in_dat_w-1 DOWNTO 0);
    in_bi    : IN  STD_LOGIC_VECTOR(g_in_dat_w-1 DOWNTO 0);
    out_re   : OUT STD_LOGIC_VECTOR(g_out_dat_w-1 DOWNTO 0);
    out_im   : OUT STD_LOGIC_VECTOR(g_out_dat_w-1 DOWNTO 0)
  );
END common_complex_add_sub;


ARCHITECTURE str OF common_complex_add_sub IS
BEGIN
  add_re : ENTITY work.common_add_sub
  GENERIC MAP (
    g_direction       => g_direction,
    g_representation  => g_representation,
    g_pipeline_input  => g_pipeline_input,
    g_pipeline_output => g_pipeline_output,
    g_in_dat_w        => g_in_dat_w,
    g_out_dat_w       => g_out_dat_w
  )
  PORT MAP (
    clk     => clk,
    clken   => clken,
    in_a    => in_ar,
    in_b    => in_br,
    result  => out_re
  );

  add_im : ENTITY work.common_add_sub
  GENERIC MAP (
    g_direction       => g_direction,
    g_representation  => g_representation,
    g_pipeline_input  => g_pipeline_input,
    g_pipeline_output => g_pipeline_output,
    g_in_dat_w        => g_in_dat_w,
    g_out_dat_w       => g_out_dat_w
  )
  PORT MAP (
    clk     => clk,
    clken   => clken,
    in_a    => in_ai,
    in_b    => in_bi,
    result  => out_im
  );
END str;
