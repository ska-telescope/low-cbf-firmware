-------------------------------------------------------------------------------
--
-- Copyright (C) 2013
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

ENTITY tb_tb_common_multiplexer IS
END tb_tb_common_multiplexer;

ARCHITECTURE tb OF tb_tb_common_multiplexer IS
   SIGNAL tb_end : STD_LOGIC;
BEGIN
  -- Usage:
  -- > as 3
  -- > run -all

  --  g_pipeline_demux_in  : NATURAL := 1;
  --  g_pipeline_demux_out : NATURAL := 1;
  --  g_nof_streams        : NATURAL := 4;
  --  g_pipeline_mux_in    : NATURAL := 1;
  --  g_pipeline_mux_out   : NATURAL := 1;
  --  g_dat_w              : NATURAL := 8;
  --  g_random_in_val      : BOOLEAN := TRUE;
  --  g_test_nof_cycles    : NATURAL := 500

  u_demux_mux_p0000       : ENTITY work.tb_common_multiplexer GENERIC MAP (0, 0, 4, 0, 0, 8, TRUE, 500) PORT MAP (tb_end);
  u_demux_mux_p0000_nof_1 : ENTITY work.tb_common_multiplexer GENERIC MAP (0, 0, 1, 0, 0, 8, TRUE, 500) PORT MAP (tb_end);
  u_demux_mux_p0011       : ENTITY work.tb_common_multiplexer GENERIC MAP (0, 0, 4, 1, 1, 8, TRUE, 500) PORT MAP (tb_end);
  u_demux_mux_p1100       : ENTITY work.tb_common_multiplexer GENERIC MAP (1, 1, 4, 0, 0, 8, TRUE, 500) PORT MAP (tb_end);
  u_demux_mux_p1111       : ENTITY work.tb_common_multiplexer GENERIC MAP (1, 1, 4, 1, 1, 8, TRUE, 500) PORT MAP (tb_end);
  u_demux_mux_p1010       : ENTITY work.tb_common_multiplexer GENERIC MAP (1, 0, 4, 1, 0, 8, TRUE, 500) PORT MAP (tb_end);
  u_demux_mux_p0101       : ENTITY work.tb_common_multiplexer GENERIC MAP (0, 1, 4, 0, 1, 8, TRUE, 500) PORT MAP (tb_end);
  u_demux_mux_p1234_nof_1 : ENTITY work.tb_common_multiplexer GENERIC MAP (1, 2, 1, 3, 4, 8, TRUE, 500) PORT MAP (tb_end);
  u_demux_mux_p1234_nof_5 : ENTITY work.tb_common_multiplexer GENERIC MAP (1, 2, 5, 3, 4, 8, TRUE, 500) PORT MAP (tb_end);

END tb;
