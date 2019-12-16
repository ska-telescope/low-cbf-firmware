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

-- Purpose: Dual page memory with single wr in one page and dual rd in other page
-- Description:
--   When next_page pulses then the next access will occur in the other page.
-- Remarks:
--   Each page uses one or more RAM blocks.

LIBRARY IEEE, technology_lib;
USE IEEE.std_logic_1164.ALL;
USE work.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;

ENTITY common_paged_ram_w_rr IS
  GENERIC (
    g_technology      : t_technology := c_tech_select_default;
    g_pipeline_in     : NATURAL := 0;  -- >= 0
    g_pipeline_out    : NATURAL := 0;  -- >= 0
    g_data_w          : NATURAL;
    g_page_sz         : NATURAL;
    g_ram_rd_latency  : NATURAL := 1  -- >= 1
  );
  PORT (
    rst         : IN  STD_LOGIC;
    clk         : IN  STD_LOGIC;
    clken       : IN  STD_LOGIC := '1';
    -- next page control
    next_page   : IN  STD_LOGIC;
    -- single write access to one page
    wr_adr      : IN  STD_LOGIC_VECTOR(ceil_log2(g_page_sz)-1 DOWNTO 0) := (OTHERS=>'0');
    wr_en       : IN  STD_LOGIC := '0';
    wr_dat      : IN  STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0) := (OTHERS=>'0');
    -- double read access from the other one page
    rd_adr_a    : IN  STD_LOGIC_VECTOR(ceil_log2(g_page_sz)-1 DOWNTO 0) := (OTHERS=>'0');
    rd_en_a     : IN  STD_LOGIC := '1';
    rd_adr_b    : IN  STD_LOGIC_VECTOR(ceil_log2(g_page_sz)-1 DOWNTO 0) := (OTHERS=>'0');
    rd_en_b     : IN  STD_LOGIC := '1';
    -- double read data from the other one page after c_rd_latency
    rd_dat_a    : OUT STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    rd_val_a    : OUT STD_LOGIC;
    rd_dat_b    : OUT STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    rd_val_b    : OUT STD_LOGIC
  );
END common_paged_ram_w_rr;


ARCHITECTURE str OF common_paged_ram_w_rr IS

BEGIN

  u_ww_rr : ENTITY work.common_paged_ram_ww_rr
  GENERIC MAP (
    g_technology     => g_technology,
    g_pipeline_in    => g_pipeline_in,
    g_pipeline_out   => g_pipeline_out,
    g_data_w         => g_data_w,
    g_page_sz        => g_page_sz,
    g_ram_rd_latency => g_ram_rd_latency
  )
  PORT MAP (
    rst         => rst,
    clk         => clk,
    clken       => clken,
    -- next page control
    next_page   => next_page,
    -- double write access to one page  --> use only page a
    wr_adr_a    => wr_adr,
    wr_en_a     => wr_en,
    wr_dat_a    => wr_dat,
    -- double read access from the other one page
    rd_adr_a    => rd_adr_a,
    rd_en_a     => rd_en_a,
    rd_adr_b    => rd_adr_b,
    rd_en_b     => rd_en_b,
    -- double read data from the other one page after c_rd_latency
    rd_dat_a    => rd_dat_a,
    rd_val_a    => rd_val_a,
    rd_dat_b    => rd_dat_b,
    rd_val_b    => rd_val_b
  );
  
END str;
