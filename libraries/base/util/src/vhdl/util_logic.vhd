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


-- Purpose : Dummy function to use logic (LUTs and FF)
-- Description:
--   There are g_nof_reg >= 0 register stages in series. Each register stage
--   does outp := outp XOR inp to use LUTs and FF in an FPGA.
-- Remark:
-- . Using common_pipeline.vhd to invoke logic can get implemented in RAM
--   blocks for larger pipeline settings. Therefor this util_logic puts a
--   feedback with XOR at every stage to enforce using logic (LUTs and FF).

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY util_logic IS
  GENERIC (
    g_nof_reg  : NATURAL := 1    -- 0 for wires, > 0 for registers
  );
  PORT (
    clk     : IN  STD_LOGIC;
    clken   : IN  STD_LOGIC := '1';
    in_dat  : IN  STD_LOGIC_VECTOR;
    out_dat : OUT STD_LOGIC_VECTOR
  );
END util_logic;


ARCHITECTURE rtl OF util_logic IS

  CONSTANT c_reset_value : STD_LOGIC_VECTOR(out_dat'RANGE) := (OTHERS=>'0');
  
  TYPE t_out_dat IS ARRAY (NATURAL RANGE <>) OF STD_LOGIC_VECTOR(out_dat'RANGE);
  
  SIGNAL out_dat_reg     : t_out_dat(0 TO g_nof_reg) := (OTHERS=>c_reset_value);
  SIGNAL nxt_out_dat_reg : t_out_dat(0 TO g_nof_reg);

BEGIN

  gen_reg : FOR I IN 1 TO g_nof_reg GENERATE
    p_clk : PROCESS(clk)
    BEGIN
      IF rising_edge(clk) THEN
        IF clken='1' THEN
          FOR J IN out_dat'RANGE LOOP
            out_dat_reg(I)(J) <= out_dat_reg(I)(J) XOR out_dat_reg(I-1)(J);
          END LOOP;
        END IF;
      END IF;
    END PROCESS;
  END GENERATE;
  
  -- Implement out_dat_reg(0) <= in_dat in a for loop that checks for initial
  -- 'X' in in_dat, because in simulation these 'X' will propagate forever
  -- due to the XOR feedback function.
  p_in_dat : PROCESS(in_dat)
  BEGIN
    FOR J IN out_dat'RANGE LOOP
      out_dat_reg(0)(J) <= '0';
      IF in_dat(J) = '0' OR in_dat(J) = '1' THEN
        out_dat_reg(0)(J) <= in_dat(J);
      END IF;
    END LOOP;
  END PROCESS;
  
  out_dat <= out_dat_reg(g_nof_reg);
  
END rtl;

