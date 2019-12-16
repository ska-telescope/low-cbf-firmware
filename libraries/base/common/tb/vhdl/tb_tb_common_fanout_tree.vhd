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

ENTITY tb_tb_common_fanout_tree IS
END tb_tb_common_fanout_tree;

ARCHITECTURE tb OF tb_tb_common_fanout_tree IS
   SIGNAL tb_end  : STD_LOGIC;
BEGIN
  -- Usage:
  -- > as 3
  -- > run -all

  -- TB control:
  --   g_random_in_en              : BOOLEAN := FALSE;
  --   g_random_in_val             : BOOLEAN := FALSE;
  -- DUT settings:
  --   g_nof_stages                : POSITIVE := 2;    -- >= 1
  --   g_nof_output_per_cell       : POSITIVE := 2;    -- >= 1
  --   g_nof_output                : POSITIVE := 3;    -- >= 1 and <= g_nof_output_per_cell**g_nof_stages
  --   g_cell_pipeline_factor_arr  : t_natural_arr := (1, 2)    -- range: g_nof_stages-1 DOWNTO 0, stage g_nof_stages-1 is output stage. Value: stage factor to multiply with g_cell_pipeline_arr
  --   g_cell_pipeline_arr         : t_natural_arr := (1, 0);   -- range: g_nof_output_per_cell-1 DOWNTO 0. Value: 0 for wires, >0 for register stages

  u_val_2_2_4_equal       : ENTITY work.tb_common_fanout_tree GENERIC MAP (FALSE, TRUE, 2, 2,   4,            (1, 1),          (1, 1)) PORT MAP (tb_end);
  u_val_2_2_4_incr        : ENTITY work.tb_common_fanout_tree GENERIC MAP (FALSE, TRUE, 2, 2,   4,            (1, 2),          (1, 0)) PORT MAP (tb_end);
  u_val_3_3_27_incr       : ENTITY work.tb_common_fanout_tree GENERIC MAP (FALSE, TRUE, 3, 3,  27,         (1, 3, 9),       (2, 1, 0)) PORT MAP (tb_end);
  u_val_4_3_75_incr       : ENTITY work.tb_common_fanout_tree GENERIC MAP (FALSE, TRUE, 4, 3,  75,     (1, 3, 9, 27),       (2, 1, 0)) PORT MAP (tb_end);
  u_val_8_2_256_equal     : ENTITY work.tb_common_fanout_tree GENERIC MAP (FALSE, TRUE, 8, 2, 256,   array_init(1,8), array_init(1,2)) PORT MAP (tb_end);

END tb;
