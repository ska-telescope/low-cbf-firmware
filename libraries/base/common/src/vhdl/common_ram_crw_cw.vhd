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

ENTITY common_ram_crw_cw IS
  GENERIC (
    g_technology : t_technology := c_tech_select_default;
    g_ram        : t_c_mem := c_mem_ram;
    g_init_file  : STRING := "UNUSED"
  );
  PORT (
    -- MM read/write port clock domain
    mm_rst     : IN  STD_LOGIC := '0';
    mm_clk     : IN  STD_LOGIC;
    mm_clken   : IN  STD_LOGIC := '1';
    mm_wr_en   : IN  STD_LOGIC := '0';
    mm_wr_dat  : IN  STD_LOGIC_VECTOR(g_ram.dat_w-1 DOWNTO 0) := (OTHERS=>'0');
    mm_adr     : IN  STD_LOGIC_VECTOR(g_ram.adr_w-1 DOWNTO 0) := (OTHERS=>'0');
    mm_rd_en   : IN  STD_LOGIC := '1';
    mm_rd_dat  : OUT STD_LOGIC_VECTOR(g_ram.dat_w-1 DOWNTO 0);
    mm_rd_val  : OUT STD_LOGIC;
    
    -- ST write only port clock domain
    st_rst     : IN  STD_LOGIC := '0';
    st_clk     : IN  STD_LOGIC;
    st_clken   : IN  STD_LOGIC := '1';
    st_wr_en   : IN  STD_LOGIC := '0';
    st_wr_dat  : IN  STD_LOGIC_VECTOR(g_ram.dat_w-1 DOWNTO 0) := (OTHERS=>'0');
    st_adr     : IN  STD_LOGIC_VECTOR(g_ram.adr_w-1 DOWNTO 0) := (OTHERS=>'0')
  );
END common_ram_crw_cw;


ARCHITECTURE str OF common_ram_crw_cw IS

BEGIN

  -- Dual clock domain
  -- Use port a for read/write in MM clock domain
  -- Use port b for write only in ST clock domain
  
  u_crw_cw : ENTITY work.common_ram_crw_crw
  GENERIC MAP (
    g_technology => g_technology,
    g_ram        => g_ram,
    g_init_file  => g_init_file
  )
  PORT MAP (
    rst_a     => mm_rst,
    rst_b     => st_rst,
    clk_a     => mm_clk,
    clk_b     => st_clk,
    clken_a   => mm_clken,
    clken_b   => st_clken,
    wr_en_a   => mm_wr_en,
    wr_en_b   => st_wr_en,
    wr_dat_a  => mm_wr_dat,
    wr_dat_b  => st_wr_dat,
    adr_a     => mm_adr,
    adr_b     => st_adr,
    rd_en_a   => mm_rd_en,
    rd_en_b   => '0',
    rd_dat_a  => mm_rd_dat,
    rd_dat_b  => OPEN,
    rd_val_a  => mm_rd_val,
    rd_val_b  => OPEN
  );
  
END str;
