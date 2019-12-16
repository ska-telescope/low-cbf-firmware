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

ENTITY common_add_sub IS
  GENERIC (
    g_direction       : STRING  := "ADD";      -- or "SUB", or "BOTH" and use sel_add
    g_representation  : STRING  := "SIGNED";   -- or "UNSIGNED", important if g_out_dat_w > g_in_dat_w, not relevant if g_out_dat_w = g_in_dat_w
    g_pipeline_input  : NATURAL := 0;          -- 0 or 1
    g_pipeline_output : NATURAL := 1;          -- >= 0
    g_in_dat_w        : NATURAL := 8;
    g_out_dat_w       : NATURAL := 9           -- only support g_out_dat_w=g_in_dat_w and g_out_dat_w=g_in_dat_w+1
  );
  PORT (
    clk     : IN  STD_LOGIC;
    clken   : IN  STD_LOGIC := '1';
    sel_add : IN  STD_LOGIC := '1';           -- only used for g_direction "BOTH"
    in_a    : IN  STD_LOGIC_VECTOR(g_in_dat_w-1 DOWNTO 0);
    in_b    : IN  STD_LOGIC_VECTOR(g_in_dat_w-1 DOWNTO 0);
    result  : OUT STD_LOGIC_VECTOR(g_out_dat_w-1 DOWNTO 0)
  );
END common_add_sub;

ARCHITECTURE str OF common_add_sub IS

  CONSTANT c_res_w     : NATURAL := g_in_dat_w+1;
  
  SIGNAL in_a_p        : STD_LOGIC_VECTOR(in_a'RANGE);
  SIGNAL in_b_p        : STD_LOGIC_VECTOR(in_b'RANGE);
  
  SIGNAL in_add        : STD_LOGIC;
  SIGNAL sel_add_p     : STD_LOGIC;
  
  SIGNAL result_p      : STD_LOGIC_VECTOR(c_res_w-1 DOWNTO 0);
  
BEGIN

  in_add <= '1' WHEN g_direction="ADD" OR (g_direction="BOTH" AND sel_add='1') ELSE '0';

  no_input_reg : IF g_pipeline_input=0 GENERATE  -- wired input
    in_a_p    <= in_a;
    in_b_p    <= in_b;
    sel_add_p <= in_add;
  END GENERATE;
  gen_input_reg : IF g_pipeline_input>0 GENERATE  -- register input
    p_reg : PROCESS(clk)
    BEGIN
      IF rising_edge(clk) THEN
        IF clken='1' THEN
          in_a_p    <= in_a;
          in_b_p    <= in_b;
          sel_add_p <= in_add;
        END IF;
      END IF;
    END PROCESS;
  END GENERATE;

  gen_signed : IF g_representation = "SIGNED" GENERATE
    result_p <= ADD_SVEC(in_a_p, in_b_p, c_res_w) WHEN sel_add_p='1' ELSE SUB_SVEC(in_a_p, in_b_p, c_res_w);
  END GENERATE;
  gen_unsigned : IF g_representation = "UNSIGNED" GENERATE
    result_p <= ADD_UVEC(in_a_p, in_b_p, c_res_w) WHEN sel_add_p='1' ELSE SUB_UVEC(in_a_p, in_b_p, c_res_w);
  END GENERATE;
  
  u_output_pipe : ENTITY work.common_pipeline  -- pipeline output
  GENERIC MAP (
    g_representation => g_representation,
    g_pipeline       => g_pipeline_output,  -- 0 for wires, >0 for register stages
    g_in_dat_w       => result'LENGTH,
    g_out_dat_w      => result'LENGTH
  )
  PORT MAP (
    clk     => clk,
    clken   => clken,
    in_dat  => result_p(result'RANGE),
    out_dat => result
  );
  
END str;