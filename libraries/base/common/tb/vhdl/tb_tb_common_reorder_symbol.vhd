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

ENTITY tb_tb_common_reorder_symbol IS
END tb_tb_common_reorder_symbol;

ARCHITECTURE tb OF tb_tb_common_reorder_symbol IS
   SIGNAL tb_end  : STD_LOGIC;
BEGIN
  -- Usage:
  -- > as 3
  -- > run -all

  -- g_nof_input    : NATURAL := 5;
  -- g_nof_output   : NATURAL := 5;
  -- g_symbol_w     : NATURAL := 8;
  -- g_select_arr   : t_natural_arr := (3, 3, 3, 3, 3, 0);  --array_init(3, 6)  -- range must fit [c_N*(c_N-1)/2-1:0]
  -- g_pipeline_arr : t_natural_arr := (0,0,0,0,0)  --array_init(0, 5)  -- range must fit [0:c_N]

  u_3_3_sel_333_p1111 : ENTITY work.tb_common_reorder_symbol GENERIC MAP (3, 3, 8, (3,3,3), (1,1,1,1)) PORT MAP (tb_end);
  u_3_3_sel_333_p0000 : ENTITY work.tb_common_reorder_symbol GENERIC MAP (3, 3, 8, (3,3,3), (0,0,0,0)) PORT MAP (tb_end);
  u_3_3_sel_330_p0000 : ENTITY work.tb_common_reorder_symbol GENERIC MAP (3, 3, 8, (3,3,0), (0,0,0,0)) PORT MAP (tb_end);
  u_3_3_sel_303_p0000 : ENTITY work.tb_common_reorder_symbol GENERIC MAP (3, 3, 8, (3,0,3), (0,0,0,0)) PORT MAP (tb_end);
  u_3_3_sel_033_p0000 : ENTITY work.tb_common_reorder_symbol GENERIC MAP (3, 3, 8, (0,3,3), (0,0,0,0)) PORT MAP (tb_end);
  u_3_3_sel_003_p0000 : ENTITY work.tb_common_reorder_symbol GENERIC MAP (3, 3, 8, (0,0,3), (0,0,0,0)) PORT MAP (tb_end);
  u_3_3_sel_030_p0000 : ENTITY work.tb_common_reorder_symbol GENERIC MAP (3, 3, 8, (0,3,0), (0,0,0,0)) PORT MAP (tb_end);
  u_3_3_sel_300_p0000 : ENTITY work.tb_common_reorder_symbol GENERIC MAP (3, 3, 8, (3,0,0), (0,0,0,0)) PORT MAP (tb_end);
  u_3_3_sel_000_p0000 : ENTITY work.tb_common_reorder_symbol GENERIC MAP (3, 3, 8, (0,0,0), (0,0,0,0)) PORT MAP (tb_end);

  u_4_4_sel_333333_p11111 : ENTITY work.tb_common_reorder_symbol GENERIC MAP (4, 4, 8, (3,3,3,3,3,3), (1,1,1,1,1)) PORT MAP (tb_end);
  u_4_4_sel_333333_p00000 : ENTITY work.tb_common_reorder_symbol GENERIC MAP (4, 4, 8, (3,3,3,3,3,3), (0,0,0,0,0)) PORT MAP (tb_end);
  u_4_4_sel_333330_p00000 : ENTITY work.tb_common_reorder_symbol GENERIC MAP (4, 4, 8, (3,3,3,3,3,0), (0,0,0,0,0)) PORT MAP (tb_end);
  u_4_4_sel_333303_p00000 : ENTITY work.tb_common_reorder_symbol GENERIC MAP (4, 4, 8, (3,3,3,3,0,3), (0,0,0,0,0)) PORT MAP (tb_end);
  u_4_4_sel_333033_p00000 : ENTITY work.tb_common_reorder_symbol GENERIC MAP (4, 4, 8, (3,3,3,0,3,3), (0,0,0,0,0)) PORT MAP (tb_end);
  u_4_4_sel_330333_p00000 : ENTITY work.tb_common_reorder_symbol GENERIC MAP (4, 4, 8, (3,3,0,3,3,3), (0,0,0,0,0)) PORT MAP (tb_end);
  u_4_4_sel_303333_p00000 : ENTITY work.tb_common_reorder_symbol GENERIC MAP (4, 4, 8, (3,0,3,3,3,3), (0,0,0,0,0)) PORT MAP (tb_end);
  u_4_4_sel_033333_p00000 : ENTITY work.tb_common_reorder_symbol GENERIC MAP (4, 4, 8, (0,3,3,3,3,3), (0,0,0,0,0)) PORT MAP (tb_end);

  u_5_5_sel_3333333333_p000000 : ENTITY work.tb_common_reorder_symbol GENERIC MAP (5, 5, 8, (3,3,3,3,3,3,3,3,3,3), (0,0,0,0,0,0)) PORT MAP (tb_end);

END tb;
