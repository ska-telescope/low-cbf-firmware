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
USE IEEE.NUMERIC_STD.ALL;
USE std.TEXTIO.ALL;


ENTITY file_output IS
  GENERIC (
    g_file_name   : STRING;
    g_nof_data    : NATURAL := 1;
    g_data_width  : NATURAL;
    g_data_type   : STRING := "SIGNED"
  );
  PORT (
    clk      : IN STD_LOGIC;
    rst      : IN STD_LOGIC;
    in_dat   : IN STD_LOGIC_VECTOR(g_nof_data*g_data_width-1 DOWNTO 0);
    in_val   : IN STD_LOGIC
  );
BEGIN
  ASSERT g_data_type = "SIGNED" OR g_data_type = "UNSIGNED"
    REPORT "Unknown data type."
    SEVERITY ERROR;
END file_output;


ARCHITECTURE beh OF file_output IS
   FILE out_file : TEXT;
BEGIN
  PROCESS(rst, clk)
    VARIABLE out_line : LINE;
  BEGIN
    IF rst='1' THEN
      file_close(out_file);
      file_open (out_file, g_file_name, WRITE_MODE);
    ELSIF RISING_EDGE(clk) THEN
      IF in_val='1' THEN
        FOR i IN 0 TO g_nof_data-1 LOOP
          IF g_data_type = "UNSIGNED" THEN
            write(out_line, INTEGER(TO_INTEGER(UNSIGNED(in_dat((i+1)*g_data_width-1 DOWNTO i*g_data_width)))));
            write(out_line, ' ');
          ELSE
            write(out_line, INTEGER(TO_INTEGER(SIGNED(in_dat((i+1)*g_data_width-1 DOWNTO i*g_data_width)))));
            write(out_line, ' ');
          END IF;
        END LOOP;
        writeline(out_file,out_line);
      END IF;
    END IF;
  END PROCESS;
END beh;
