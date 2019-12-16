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

ENTITY tb_tb_common_paged_ram_ww_rr IS
END tb_tb_common_paged_ram_ww_rr;

ARCHITECTURE tb OF tb_tb_common_paged_ram_ww_rr IS
   SIGNAL tb_end : STD_LOGIC;
BEGIN
  -- Usage:
  -- > as 3
  -- > run -all

  -- DUT settings:
  --   g_pipeline_in     : NATURAL := 0;   -- >= 0
  --   g_pipeline_out    : NATURAL := 0;   -- >= 0
  --   g_page_sz         : NATURAL := 10   -- >= 1

  --u_1             : ENTITY work.tb_common_paged_ram_ww_rr GENERIC MAP (0, 0, 1) PORT MAP (tb_end);
  u_2             : ENTITY work.tb_common_paged_ram_ww_rr GENERIC MAP (0, 0, 2) PORT MAP (tb_end);
  u_8             : ENTITY work.tb_common_paged_ram_ww_rr GENERIC MAP (0, 0, 8) PORT MAP (tb_end);

  u_even          : ENTITY work.tb_common_paged_ram_ww_rr GENERIC MAP (0, 0, 10) PORT MAP (tb_end);
  u_odd           : ENTITY work.tb_common_paged_ram_ww_rr GENERIC MAP (0, 0, 11) PORT MAP (tb_end);

  u_even_pipe_0_1 : ENTITY work.tb_common_paged_ram_ww_rr GENERIC MAP (0, 1, 10) PORT MAP (tb_end);
  u_even_pipe_1_1 : ENTITY work.tb_common_paged_ram_ww_rr GENERIC MAP (1, 1, 10) PORT MAP (tb_end);
  u_odd_pipe_0_1  : ENTITY work.tb_common_paged_ram_ww_rr GENERIC MAP (0, 1, 11) PORT MAP (tb_end);
  u_odd_pipe_1_1  : ENTITY work.tb_common_paged_ram_ww_rr GENERIC MAP (1, 1, 11) PORT MAP (tb_end);

END tb;
