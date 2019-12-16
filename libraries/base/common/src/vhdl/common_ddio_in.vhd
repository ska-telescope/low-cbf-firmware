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

-- Purpose: Capture double data rate FPGA input

LIBRARY IEEE, technology_lib, tech_iobuf_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;

ENTITY common_ddio_in IS
  GENERIC(
    g_technology : t_technology := c_tech_select_default;
    g_width      : NATURAL := 1
  );
  PORT (
    in_dat      : IN  STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);
    in_clk      : IN  STD_LOGIC;
    in_clk_en   : IN  STD_LOGIC := '1';
    rst         : IN  STD_LOGIC := '0';
    out_dat_hi  : OUT STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);
    out_dat_lo  : OUT STD_LOGIC_VECTOR(g_width-1 DOWNTO 0)
  );
END common_ddio_in;


ARCHITECTURE str OF common_ddio_in IS
BEGIN

  u_ddio_in : ENTITY tech_iobuf_lib.tech_iobuf_ddio_in
  GENERIC MAP (
    g_technology    => g_technology,
    g_width         => g_width
  )
  PORT MAP (
    in_dat     => in_dat,
    in_clk     => in_clk,
    in_clk_en  => in_clk_en,
    rst        => rst,
    out_dat_hi => out_dat_hi,
    out_dat_lo => out_dat_lo
  );

END str;
