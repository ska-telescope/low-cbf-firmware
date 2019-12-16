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

ENTITY tb_tb_common_add_sub IS
END tb_tb_common_add_sub;

ARCHITECTURE tb OF tb_tb_common_add_sub IS
   SIGNAL tb_end     : STD_LOGIC;
BEGIN
  -- g_direction    : STRING := "SUB";  -- "SUB" or "ADD"
  -- g_sel_add      : STD_LOGIC :='1';  -- '0' = sub, '1' = add, only valid for g_direction = "BOTH"
  -- g_pipeline_in  : NATURAL := 0;     -- input pipelining 0 or 1
  -- g_pipeline_out : NATURAL := 1;     -- output pipelining >= 0
  -- g_in_dat_w     : NATURAL := 5;
  -- g_out_dat_w    : NATURAL := 5;     -- g_in_dat_w or g_in_dat_w+1

  u_add_5_5      : ENTITY work.tb_common_add_sub GENERIC MAP ("ADD",  '1', 0, 2, 5, 5) PORT MAP (tb_end);
  u_add_5_6      : ENTITY work.tb_common_add_sub GENERIC MAP ("ADD",  '1', 0, 2, 5, 6) PORT MAP (tb_end);
  u_sub_5_5      : ENTITY work.tb_common_add_sub GENERIC MAP ("SUB",  '0', 0, 2, 5, 5) PORT MAP (tb_end);
  u_sub_5_6      : ENTITY work.tb_common_add_sub GENERIC MAP ("SUB",  '0', 0, 2, 5, 6) PORT MAP (tb_end);
  u_both_add_5_5 : ENTITY work.tb_common_add_sub GENERIC MAP ("BOTH", '1', 0, 2, 5, 5) PORT MAP (tb_end);
  u_both_add_5_6 : ENTITY work.tb_common_add_sub GENERIC MAP ("BOTH", '1', 0, 2, 5, 6) PORT MAP (tb_end);
  u_both_sub_5_5 : ENTITY work.tb_common_add_sub GENERIC MAP ("BOTH", '0', 0, 2, 5, 5) PORT MAP (tb_end);
  u_both_sub_5_6 : ENTITY work.tb_common_add_sub GENERIC MAP ("BOTH", '0', 0, 2, 5, 6) PORT MAP (tb_end);

END tb;
