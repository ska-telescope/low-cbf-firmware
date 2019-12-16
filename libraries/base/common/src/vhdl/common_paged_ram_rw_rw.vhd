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

ENTITY common_paged_ram_rw_rw IS
  GENERIC (
    g_technology      : t_technology := c_tech_select_default;
    g_str             : STRING := "use_adr";
    g_data_w          : NATURAL;
    g_nof_pages       : NATURAL := 2;  -- >= 2
    g_page_sz         : NATURAL;
    g_start_page_a    : NATURAL := 0;
    g_start_page_b    : NATURAL := 0;
    g_rd_latency      : NATURAL := 1;
    g_true_dual_port  : BOOLEAN := TRUE
  );
  PORT (
    rst         : IN  STD_LOGIC;
    clk         : IN  STD_LOGIC;
    clken       : IN  STD_LOGIC := '1';
    next_page_a : IN  STD_LOGIC;
    adr_a       : IN  STD_LOGIC_VECTOR(ceil_log2(g_page_sz)-1 DOWNTO 0) := (OTHERS=>'0');
    wr_en_a     : IN  STD_LOGIC := '0';
    wr_dat_a    : IN  STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0) := (OTHERS=>'0');
    rd_en_a     : IN  STD_LOGIC := '1';
    rd_dat_a    : OUT STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    rd_val_a    : OUT STD_LOGIC;
    next_page_b : IN  STD_LOGIC;
    adr_b       : IN  STD_LOGIC_VECTOR(ceil_log2(g_page_sz)-1 DOWNTO 0) := (OTHERS=>'0');
    wr_en_b     : IN  STD_LOGIC := '0';
    wr_dat_b    : IN  STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0) := (OTHERS=>'0');
    rd_en_b     : IN  STD_LOGIC := '1';
    rd_dat_b    : OUT STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    rd_val_b    : OUT STD_LOGIC
  );
END common_paged_ram_rw_rw;


ARCHITECTURE str OF common_paged_ram_rw_rw IS

BEGIN

  u_crw_crw : ENTITY work.common_paged_ram_crw_crw
  GENERIC MAP (
    g_technology     => g_technology,
    g_str            => g_str,
    g_data_w         => g_data_w,
    g_nof_pages      => g_nof_pages,
    g_page_sz        => g_page_sz,
    g_start_page_a   => g_start_page_a,
    g_start_page_b   => g_start_page_b,
    g_rd_latency     => g_rd_latency,
    g_true_dual_port => g_true_dual_port
  )
  PORT MAP (
    rst_a       => rst,
    rst_b       => rst,
    clk_a       => clk,
    clk_b       => clk,
    clken_a     => clken,
    clken_b     => clken,
    next_page_a => next_page_a,
    adr_a       => adr_a,
    wr_en_a     => wr_en_a,
    wr_dat_a    => wr_dat_a,
    rd_en_a     => rd_en_a,
    rd_dat_a    => rd_dat_a,
    rd_val_a    => rd_val_a,
    next_page_b => next_page_b,
    adr_b       => adr_b,
    wr_en_b     => wr_en_b,
    wr_dat_b    => wr_dat_b,
    rd_en_b     => rd_en_b,
    rd_dat_b    => rd_dat_b,
    rd_val_b    => rd_val_b
  );

END str;
