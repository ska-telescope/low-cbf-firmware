-------------------------------------------------------------------------------
--
-- Copyright (C) 2012
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

LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;

-- Purpose: Multi-test bench for common_transpose.vhd
-- Usage:
-- > as 3
-- > run -all

ENTITY tb_tb_common_transpose IS
END tb_tb_common_transpose;

ARCHITECTURE tb OF tb_tb_common_transpose IS
   SIGNAL tb_end : STD_LOGIC;
BEGIN

--                                                            g_pipeline_shiftreg  : NATURAL := 0;
--                                                            |  g_pipeline_transpose : NATURAL := 0;
--                                                            |  |  g_pipeline_hold      : NATURAL := 0;
--                                                            |  |  |  g_pipeline_select    : NATURAL := 1;
--                                                            |  |  |  |   g_nof_data           : NATURAL := 3;
--                                                            |  |  |  |   |   g_data_w             : NATURAL := 12
--                                                            |  |  |  |   |   |
  u_4_4   : ENTITY common_lib.tb_common_transpose GENERIC MAP(0, 0, 0, 1,  4,  4) PORT MAP (tb_end);

  u_4_8   : ENTITY common_lib.tb_common_transpose GENERIC MAP(0, 0, 0, 1,  4,  8) PORT MAP (tb_end);

  u_3_12  : ENTITY common_lib.tb_common_transpose GENERIC MAP(0, 0, 0, 1,  3, 12) PORT MAP (tb_end);
  u_3_12p : ENTITY common_lib.tb_common_transpose GENERIC MAP(1, 3, 1, 0,  3, 12) PORT MAP (tb_end);

  u_4_16  : ENTITY common_lib.tb_common_transpose GENERIC MAP(0, 0, 0, 1,  4, 16) PORT MAP (tb_end);
  u_4_16p : ENTITY common_lib.tb_common_transpose GENERIC MAP(1, 2, 3, 1,  4, 16) PORT MAP (tb_end);

END tb;
