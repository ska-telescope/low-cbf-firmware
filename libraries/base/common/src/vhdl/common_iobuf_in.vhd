-------------------------------------------------------------------------------
--
-- Copyright (C) 2011
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

-- Purpose: Delay differential FPGA input

LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE common_lib.common_pkg.ALL;

ENTITY common_iobuf_in IS
  GENERIC(
    g_device_family : STRING := "Stratix IV";
    g_width         : NATURAL := 8;
    g_delay_arr     : t_natural_arr := array_init(0, 8)  -- nof must match g_width
  );
  PORT (
    config_rst  : IN  STD_LOGIC;
    config_clk  : IN  STD_LOGIC;
    config_done : OUT STD_LOGIC;
    in_dat      : IN  STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);
    out_dat     : OUT STD_LOGIC_VECTOR(g_width-1 DOWNTO 0)
  );
END common_iobuf_in;
