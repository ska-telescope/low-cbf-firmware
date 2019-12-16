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

ENTITY common_ram_r_w IS
  GENERIC (
    g_technology : t_technology := c_tech_select_default;
    g_ram        : t_c_mem := c_mem_ram;
    g_init_file  : STRING := "UNUSED";
    g_true_dual_port : BOOLEAN := TRUE
  );
  PORT (
    rst       : IN  STD_LOGIC := '0';
    clk       : IN  STD_LOGIC;
    clken     : IN  STD_LOGIC := '1';
    wr_en     : IN  STD_LOGIC := '0';
    wr_adr    : IN  STD_LOGIC_VECTOR(g_ram.adr_w-1 DOWNTO 0) := (OTHERS=>'0');
    wr_dat    : IN  STD_LOGIC_VECTOR(g_ram.dat_w-1 DOWNTO 0) := (OTHERS=>'0');
    rd_en     : IN  STD_LOGIC := '1';
    rd_adr    : IN  STD_LOGIC_VECTOR(g_ram.adr_w-1 DOWNTO 0);
    rd_dat    : OUT STD_LOGIC_VECTOR(g_ram.dat_w-1 DOWNTO 0);
    rd_val    : OUT STD_LOGIC
  );
END common_ram_r_w;


ARCHITECTURE str OF common_ram_r_w IS

BEGIN

  -- Use port a only for write
  -- Use port b only for read
  
  u_rw_rw : ENTITY work.common_ram_rw_rw
  GENERIC MAP (
    g_technology => g_technology,
    g_ram        => g_ram,
    g_init_file  => g_init_file,
    g_true_dual_port => g_true_dual_port
  )
  PORT MAP (
    rst       => rst,
    clk       => clk,
    clken     => clken,
    wr_en_a   => wr_en,
    wr_en_b   => '0',
    wr_dat_a  => wr_dat,
    --wr_dat_b  => (OTHERS=>'0'),
    adr_a     => wr_adr,
    adr_b     => rd_adr,
    rd_en_a   => '0',
    rd_en_b   => rd_en,
    rd_dat_a  => OPEN,
    rd_dat_b  => rd_dat,
    rd_val_a  => OPEN,
    rd_val_b  => rd_val
  );
  
END str;

