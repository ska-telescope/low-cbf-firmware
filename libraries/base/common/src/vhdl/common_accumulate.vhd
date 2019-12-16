-------------------------------------------------------------------------------
--
-- Copyright (C) 2010
-- ASTRON (Netherlands Institute for Radio Astronomy) <http://www.astron.nl/>
-- JIVE (Joint Institute for VLBI in Europe) <http://www.jive.nl/>
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

-- Description:
--   Signed accumulator of valid input data. The accumlator gets reloaded with 
--   valid in_dat or set to 0 when there is no valid in_dat when sload is
--   active.

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.common_pkg.ALL;

ENTITY common_accumulate IS
  GENERIC (
    g_representation  : STRING  := "SIGNED"  -- or "UNSIGNED"
  );
  PORT (
    rst     : IN  STD_LOGIC := '0';
    clk     : IN  STD_LOGIC;
    clken   : IN  STD_LOGIC := '1';
    sload   : IN  STD_LOGIC;
    in_val  : IN  STD_LOGIC := '1';
    in_dat  : IN  STD_LOGIC_VECTOR;
    out_dat : OUT STD_LOGIC_VECTOR
  );
END common_accumulate;


ARCHITECTURE rtl OF common_accumulate IS

 CONSTANT c_acc_w : NATURAL := out_dat'LENGTH;
 
 SIGNAL result : STD_LOGIC_VECTOR(c_acc_w-1 DOWNTO 0);

BEGIN

  PROCESS(rst, clk)
  BEGIN
    IF rst ='1' THEN
      result <= (OTHERS =>'0');
    ELSIF rising_edge(clk) THEN
      IF clken ='1' THEN
        IF sload ='1' THEN
          result <= (OTHERS =>'0');
          IF in_val='1' THEN
            IF g_representation="SIGNED" THEN
              result <= RESIZE_SVEC(in_dat, c_acc_w);
            ELSE
              result <= RESIZE_UVEC(in_dat, c_acc_w);
            END IF;
          END IF;
        ELSIF in_val='1' THEN
          IF g_representation="SIGNED" THEN
            result <= STD_LOGIC_VECTOR(  SIGNED(result) +   SIGNED(RESIZE_SVEC(in_dat, c_acc_w)));
          ELSE
            result <= STD_LOGIC_VECTOR(UNSIGNED(result) + UNSIGNED(RESIZE_UVEC(in_dat, c_acc_w)));
          END IF;
        END IF;
      END IF;
    END IF;
  END PROCESS;

  out_dat <= result;

END rtl;
