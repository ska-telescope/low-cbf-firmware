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

ENTITY common_pipeline IS
  GENERIC (
    g_representation : STRING  := "SIGNED";   -- or "UNSIGNED"
    g_pipeline       : NATURAL := 1;  -- 0 for wires, > 0 for registers, 
    g_reset_value    : INTEGER := 0;
    g_in_dat_w       : NATURAL := 8;
    g_out_dat_w      : NATURAL := 9
  );
  PORT (
    rst     : IN  STD_LOGIC := '0';
    clk     : IN  STD_LOGIC;
    clken   : IN  STD_LOGIC := '1';
    in_clr  : IN  STD_LOGIC := '0';
    in_en   : IN  STD_LOGIC := '1';
    in_dat  : IN  STD_LOGIC_VECTOR(g_in_dat_w-1 DOWNTO 0);
    out_dat : OUT STD_LOGIC_VECTOR(g_out_dat_w-1 DOWNTO 0)
  );
END common_pipeline;


ARCHITECTURE rtl OF common_pipeline IS

  CONSTANT c_reset_value : STD_LOGIC_VECTOR(out_dat'RANGE) := TO_SVEC(g_reset_value, out_dat'LENGTH);
  
  TYPE t_out_dat IS ARRAY (NATURAL RANGE <>) OF STD_LOGIC_VECTOR(out_dat'RANGE);
  
  SIGNAL out_dat_p  : t_out_dat(0 TO g_pipeline) := (OTHERS=>c_reset_value);

BEGIN

  gen_pipe_n : IF g_pipeline>0 GENERATE
    p_clk : PROCESS(clk, rst)
    BEGIN
      IF rst='1' THEN
        out_dat_p(1 TO g_pipeline) <= (OTHERS=>c_reset_value);
      ELSIF rising_edge(clk) THEN
        IF clken='1' THEN
          IF in_clr = '1' THEN
            out_dat_p(1 TO g_pipeline) <= (OTHERS=>c_reset_value);
          ELSIF in_en = '1' THEN
            out_dat_p(1 TO g_pipeline) <= out_dat_p(0 TO g_pipeline-1);
          END IF;
        END IF;
      END IF;
    END PROCESS;
  END GENERATE;
    
  out_dat_p(0) <= RESIZE_SVEC(in_dat, out_dat'LENGTH) WHEN g_representation=  "SIGNED" ELSE
                  RESIZE_UVEC(in_dat, out_dat'LENGTH) WHEN g_representation="UNSIGNED";
  
  out_dat <= out_dat_p(g_pipeline);
  
END rtl;
