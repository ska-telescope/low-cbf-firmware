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

ENTITY tb_tb_common_operation_tree IS
END tb_tb_common_operation_tree;

ARCHITECTURE tb OF tb_tb_common_operation_tree IS
   SIGNAL tb_end : STD_LOGIC;
BEGIN
  -- Usage:
  -- > as 2
  -- > run -all

  -- g_operation      : STRING  := "MAX";      -- supported operations "MAX", "MIN"
  -- g_representation : STRING  := "SIGNED";
  -- g_pipeline       : NATURAL := 1;  -- amount of pipelining per stage
  -- g_pipeline_mod   : NATURAL := 1;  -- only pipeline the stage output by g_pipeline when the stage number MOD g_pipeline_mod = 0
  -- g_nof_inputs     : NATURAL := 5   -- >= 1

  u_smax_0      : ENTITY work.tb_common_operation_tree GENERIC MAP ("MAX", "SIGNED", 0, 1, 5) PORT MAP (tb_end);
  u_smax_1      : ENTITY work.tb_common_operation_tree GENERIC MAP ("MAX", "SIGNED", 1, 1, 7) PORT MAP (tb_end);
  u_smax_1_4_8  : ENTITY work.tb_common_operation_tree GENERIC MAP ("MAX", "SIGNED", 1, 4, 8) PORT MAP (tb_end);
  u_smax_1_4_9  : ENTITY work.tb_common_operation_tree GENERIC MAP ("MAX", "SIGNED", 1, 4, 9) PORT MAP (tb_end);
  u_smax_1_4_16 : ENTITY work.tb_common_operation_tree GENERIC MAP ("MAX", "SIGNED", 1, 4, 16) PORT MAP (tb_end);

  u_umax_0      : ENTITY work.tb_common_operation_tree GENERIC MAP ("MAX", "UNSIGNED", 0, 1, 5) PORT MAP (tb_end);
  u_umax_1      : ENTITY work.tb_common_operation_tree GENERIC MAP ("MAX", "UNSIGNED", 1, 1, 7) PORT MAP (tb_end);
  u_umax_1_2_16 : ENTITY work.tb_common_operation_tree GENERIC MAP ("MAX", "UNSIGNED", 1, 2, 16) PORT MAP (tb_end);

  u_smin_0      : ENTITY work.tb_common_operation_tree GENERIC MAP ("MIN", "SIGNED", 0, 1, 5) PORT MAP (tb_end);
  u_smin_1      : ENTITY work.tb_common_operation_tree GENERIC MAP ("MIN", "SIGNED", 1, 1, 7) PORT MAP (tb_end);
  u_smin_1_2_8  : ENTITY work.tb_common_operation_tree GENERIC MAP ("MIN", "SIGNED", 1, 2, 8) PORT MAP (tb_end);

  u_umin_0      : ENTITY work.tb_common_operation_tree GENERIC MAP ("MIN", "UNSIGNED", 0, 1, 5) PORT MAP (tb_end);
  u_umin_1      : ENTITY work.tb_common_operation_tree GENERIC MAP ("MIN", "UNSIGNED", 1, 1, 7) PORT MAP (tb_end);
  u_umin_1_1_8  : ENTITY work.tb_common_operation_tree GENERIC MAP ("MIN", "UNSIGNED", 1, 1, 8) PORT MAP (tb_end);

END tb;
