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

ENTITY tb_tb_common_rl IS
END tb_tb_common_rl;

ARCHITECTURE tb OF tb_tb_common_rl IS

  CONSTANT c_nof_blocks  : NATURAL := 1000;
  CONSTANT c_fifo_size   : NATURAL := 64;

  SIGNAL tb_end : STD_LOGIC;
BEGIN
  -- Usage:
  -- > as 2
  -- > run -all

  -- g_nof_blocks              : NATURAL := 1000;   -- nof blocks to simulate
  -- g_random_enable           : BOOLEAN := TRUE;   -- use TRUE for random input enable flow control
  -- g_random_ready            : BOOLEAN := TRUE;   -- use TRUE for random output ready flow control
  -- g_fifo_size               : NATURAL := 1024;
  -- g_rl_decrease_en          : BOOLEAN := FALSE;
  -- g_rl_increase_en          : BOOLEAN := FALSE
  -- g_rl_increase_hold_dat_en : BOOLEAN := TRUE

  u_random_fifo_sc_decr_0_incr_1_f  : ENTITY work.tb_common_rl GENERIC MAP (c_nof_blocks, TRUE, TRUE, c_fifo_size,  TRUE,  TRUE, FALSE) PORT MAP (tb_end);
  u_random_fifo_sc_decr_0_incr_1_t  : ENTITY work.tb_common_rl GENERIC MAP (c_nof_blocks, TRUE, TRUE, c_fifo_size,  TRUE,  TRUE,  TRUE) PORT MAP (tb_end);
  u_random_fifo_sc_decr_0           : ENTITY work.tb_common_rl GENERIC MAP (c_nof_blocks, TRUE, TRUE, c_fifo_size,  TRUE, FALSE, FALSE) PORT MAP (tb_end);
  u_random_fifo_sc                  : ENTITY work.tb_common_rl GENERIC MAP (c_nof_blocks, TRUE, TRUE, c_fifo_size, FALSE, FALSE,  TRUE) PORT MAP (tb_end);

END tb;
