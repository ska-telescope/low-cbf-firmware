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

-- Purpose: Multi page memory
-- Description:
--   When next_page_* pulses then the next access will occur in the next page.
-- Remarks:
-- . See common_paged_ram_crw_crw for details.

LIBRARY IEEE, technology_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
LIBRARY common_lib;
USE work.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;

ENTITY common_paged_ram_r_w IS
  GENERIC (
    g_technology      : t_technology := c_tech_select_default;
    g_str             : STRING := "use_adr";
    g_data_w          : NATURAL;
    g_nof_pages       : NATURAL := 2;  -- >= 2
    g_page_sz         : NATURAL;
    g_wr_start_page   : NATURAL := 0;
    g_rd_start_page   : NATURAL := 0;
    g_rd_latency      : NATURAL := 1
  );
  PORT (
    rst          : IN  STD_LOGIC;
    clk          : IN  STD_LOGIC;
    clken        : IN  STD_LOGIC := '1';
    wr_next_page : IN  STD_LOGIC;
    wr_adr       : IN  STD_LOGIC_VECTOR(ceil_log2(g_page_sz)-1 DOWNTO 0) := (OTHERS=>'0');
    wr_en        : IN  STD_LOGIC := '0';
    wr_dat       : IN  STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0) := (OTHERS=>'0');
    rd_next_page : IN  STD_LOGIC;
    rd_adr       : IN  STD_LOGIC_VECTOR(ceil_log2(g_page_sz)-1 DOWNTO 0) := (OTHERS=>'0');
    rd_en        : IN  STD_LOGIC := '1';
    rd_dat       : OUT STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    rd_val       : OUT STD_LOGIC
  );
END common_paged_ram_r_w;


ARCHITECTURE str OF common_paged_ram_r_w IS

BEGIN

  u_rw_rw : ENTITY work.common_paged_ram_rw_rw
  GENERIC MAP (
    g_technology     => g_technology,
    g_str            => g_str,
    g_data_w         => g_data_w,
    g_nof_pages      => g_nof_pages,
    g_page_sz        => g_page_sz,
    g_start_page_a   => g_wr_start_page,
    g_start_page_b   => g_rd_start_page,
    g_rd_latency     => g_rd_latency,
    g_true_dual_port => FALSE
  )
  PORT MAP (
    rst         => rst,
    clk         => clk,
    clken       => clken,
    next_page_a => wr_next_page,
    adr_a       => wr_adr,
    wr_en_a     => wr_en,
    wr_dat_a    => wr_dat,
    rd_en_a     => '0',
    rd_dat_a    => OPEN,
    rd_val_a    => OPEN,
    next_page_b => rd_next_page,
    adr_b       => rd_adr,
    wr_en_b     => '0',
    wr_dat_b    => (OTHERS=>'0'),
    rd_en_b     => rd_en,
    rd_dat_b    => rd_dat,
    rd_val_b    => rd_val
  );

END str;
