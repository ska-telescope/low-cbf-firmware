-------------------------------------------------------------------------------
--
-- Copyright (C) 2014
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

LIBRARY IEEE, technology_lib;
USE IEEE.std_logic_1164.ALL;
USE work.common_mem_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;

ENTITY common_rom IS
  GENERIC (
    g_technology : t_technology := c_tech_select_default;
    g_ram        : t_c_mem := c_mem_ram;
    g_init_file  : STRING  := "UNUSED"
  );
  PORT (
    rst           : IN  STD_LOGIC := '0';
    clk           : IN  STD_LOGIC;
    clken         : IN  STD_LOGIC := '1';
    rd_en         : IN  STD_LOGIC := '1';
    rd_adr        : IN  STD_LOGIC_VECTOR(g_ram.adr_w-1 DOWNTO 0) := (OTHERS=>'0');
    rd_dat        : OUT STD_LOGIC_VECTOR(g_ram.dat_w-1 DOWNTO 0) := (OTHERS=>'0');
    rd_val        : OUT STD_LOGIC
  );
END common_rom;


ARCHITECTURE str OF common_rom IS

BEGIN

  -- Only use the read port
  
  u_r_w : ENTITY work.common_ram_r_w
  GENERIC MAP (
    g_technology => g_technology,
    g_ram        => g_ram,
    g_init_file  => g_init_file
  )
  PORT MAP (
    rst       => rst,
    clk       => clk,
    clken     => clken,
    wr_en     => '0',
    --wr_adr    => (OTHERS=>'0'),
    --wr_dat    => (OTHERS=>'0'),
    rd_en     => rd_en,
    rd_adr    => rd_adr,
    rd_dat    => rd_dat,
    rd_val    => rd_val
  );
  
END str;
