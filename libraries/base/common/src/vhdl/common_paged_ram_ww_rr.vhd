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

-- Purpose: Dual page memory with dual wr in one page and dual rd in other page
-- Description:
--   When next_page pulses then the next access will occur in the other page.
-- Remarks:
--   Each page uses one or more RAM blocks.

LIBRARY IEEE, technology_lib;
USE IEEE.std_logic_1164.ALL;
USE work.common_pkg.ALL;
USE work.common_mem_pkg.ALL;
USE work.common_components_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;

ENTITY common_paged_ram_ww_rr IS
  GENERIC (
    g_technology      : t_technology := c_tech_select_default;
    g_pipeline_in     : NATURAL := 0;  -- >= 0
    g_pipeline_out    : NATURAL := 0;  -- >= 0
    g_data_w          : NATURAL;
    g_page_sz         : NATURAL;
    g_ram_rd_latency  : NATURAL := 1   -- >= 1
  );
  PORT (
    rst         : IN  STD_LOGIC;
    clk         : IN  STD_LOGIC;
    clken       : IN  STD_LOGIC := '1';
    -- next page control
    next_page   : IN  STD_LOGIC;
    -- double write access to one page
    wr_adr_a    : IN  STD_LOGIC_VECTOR(ceil_log2(g_page_sz)-1 DOWNTO 0) := (OTHERS=>'0');
    wr_en_a     : IN  STD_LOGIC := '0';
    wr_dat_a    : IN  STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0) := (OTHERS=>'0');
    wr_adr_b    : IN  STD_LOGIC_VECTOR(ceil_log2(g_page_sz)-1 DOWNTO 0) := (OTHERS=>'0');
    wr_en_b     : IN  STD_LOGIC := '0';
    wr_dat_b    : IN  STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0) := (OTHERS=>'0');
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
END common_paged_ram_ww_rr;


ARCHITECTURE rtl OF common_paged_ram_ww_rr IS

  CONSTANT c_sel_latency      : NATURAL := g_pipeline_in + g_ram_rd_latency;
  CONSTANT c_rd_latency       : NATURAL := g_pipeline_in + g_ram_rd_latency + g_pipeline_out;
  
  CONSTANT c_nof_ports        : NATURAL := 2;  -- Fixed dual port, port a and port b
  CONSTANT c_nof_pages        : NATURAL := 2;  -- Fixed dual page, page 0 and page 1
  
  CONSTANT c_addr_w           : NATURAL := ceil_log2(g_page_sz);
  
  CONSTANT c_page_ram         : t_c_mem := (latency      => g_ram_rd_latency,
                                            adr_w        => c_addr_w,
                                            dat_w        => g_data_w,
                                            nof_dat      => g_page_sz,
                                            addr_base    => 0, 
                                            nof_slaves   => 1,
                                            init_sl      => '0');
                                           
  TYPE t_data_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
  TYPE t_addr_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_addr_w-1 DOWNTO 0);
  
  -- Page select control
  SIGNAL page_sel           : STD_LOGIC;
  SIGNAL nxt_page_sel       : STD_LOGIC;
  SIGNAL page_sel_dly       : STD_LOGIC_VECTOR(0 TO c_sel_latency-1);
  SIGNAL nxt_page_sel_dly   : STD_LOGIC_VECTOR(0 TO c_sel_latency-1);
  SIGNAL page_sel_in        : STD_LOGIC;
  SIGNAL page_sel_out       : STD_LOGIC;

  -- Double write in one page and double read in the other page
  -- . input
  SIGNAL nxt_page_wr_dat_a  : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
  SIGNAL nxt_page_wr_dat_b  : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
  SIGNAL page_wr_dat_a      : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
  SIGNAL page_wr_dat_b      : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
  SIGNAL nxt_page_wr_en_a   : STD_LOGIC_VECTOR(0 TO c_nof_pages-1);
  SIGNAL nxt_page_wr_en_b   : STD_LOGIC_VECTOR(0 TO c_nof_pages-1);
  SIGNAL page_wr_en_a       : STD_LOGIC_VECTOR(0 TO c_nof_pages-1);
  SIGNAL page_wr_en_b       : STD_LOGIC_VECTOR(0 TO c_nof_pages-1);
  SIGNAL nxt_page_rd_en_a   : STD_LOGIC_VECTOR(0 TO c_nof_pages-1);
  SIGNAL nxt_page_rd_en_b   : STD_LOGIC_VECTOR(0 TO c_nof_pages-1);
  SIGNAL page_rd_en_a       : STD_LOGIC_VECTOR(0 TO c_nof_pages-1);
  SIGNAL page_rd_en_b       : STD_LOGIC_VECTOR(0 TO c_nof_pages-1);
  SIGNAL nxt_page_adr_a     : t_addr_arr(0 TO c_nof_pages-1);
  SIGNAL nxt_page_adr_b     : t_addr_arr(0 TO c_nof_pages-1);
  SIGNAL page_adr_a         : t_addr_arr(0 TO c_nof_pages-1);
  SIGNAL page_adr_b         : t_addr_arr(0 TO c_nof_pages-1);
  
  -- . output
  SIGNAL page_rd_dat_a      : t_data_arr(0 TO c_nof_pages-1);
  SIGNAL page_rd_val_a      : STD_LOGIC_VECTOR(0 TO c_nof_pages-1);
  SIGNAL page_rd_dat_b      : t_data_arr(0 TO c_nof_pages-1);
  SIGNAL page_rd_val_b      : STD_LOGIC_VECTOR(0 TO c_nof_pages-1);
  
  SIGNAL nxt_rd_dat_a       : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
  SIGNAL nxt_rd_val_a       : STD_LOGIC;
  SIGNAL nxt_rd_dat_b       : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
  SIGNAL nxt_rd_val_b       : STD_LOGIC;
  
BEGIN

  -- page select
  p_reg : PROCESS (rst, clk)
  BEGIN
    IF rst = '1' THEN
      page_sel     <= '0';
      page_sel_dly <= (OTHERS=>'0');
    ELSIF rising_edge(clk) THEN
      page_sel     <= nxt_page_sel;
      page_sel_dly <= nxt_page_sel_dly;
    END IF;
  END PROCESS;

  nxt_page_sel <= NOT page_sel WHEN next_page='1' ELSE page_sel;
  
  nxt_page_sel_dly(0)                    <= page_sel;
  nxt_page_sel_dly(1 TO c_sel_latency-1) <= page_sel_dly(0 TO c_sel_latency-2);
  
  page_sel_in  <= page_sel;
  page_sel_out <= page_sel_dly(c_sel_latency-1);
  
  -- apply the data to both pages, the page_wr_en* is only active for the selected page
  nxt_page_wr_dat_a   <= wr_dat_a;
  nxt_page_wr_dat_b   <= wr_dat_b;
  
  -- use page_sel_in for RAM access control
  nxt_page_wr_en_a(0) <= wr_en_a  WHEN page_sel_in='0' ELSE '0';
  nxt_page_wr_en_b(0) <= wr_en_b  WHEN page_sel_in='0' ELSE '0';
  nxt_page_wr_en_a(1) <= wr_en_a  WHEN page_sel_in='1' ELSE '0';
  nxt_page_wr_en_b(1) <= wr_en_b  WHEN page_sel_in='1' ELSE '0';
  
  nxt_page_rd_en_a(0) <= rd_en_a  WHEN page_sel_in='1' ELSE '0';
  nxt_page_rd_en_b(0) <= rd_en_b  WHEN page_sel_in='1' ELSE '0';
  nxt_page_rd_en_a(1) <= rd_en_a  WHEN page_sel_in='0' ELSE '0';
  nxt_page_rd_en_b(1) <= rd_en_b  WHEN page_sel_in='0' ELSE '0';
      
  nxt_page_adr_a(0)   <= wr_adr_a WHEN page_sel_in='0' ELSE rd_adr_a;
  nxt_page_adr_b(0)   <= wr_adr_b WHEN page_sel_in='0' ELSE rd_adr_b;
  nxt_page_adr_a(1)   <= wr_adr_a WHEN page_sel_in='1' ELSE rd_adr_a;
  nxt_page_adr_b(1)   <= wr_adr_b WHEN page_sel_in='1' ELSE rd_adr_b;
  
  -- input mux pipelining
  u_pipe_page_wr_dat_a : common_pipeline    GENERIC MAP ("SIGNED", g_pipeline_in, 0, g_data_w, g_data_w) PORT MAP (rst, clk, clken, '0', '1', nxt_page_wr_dat_a, page_wr_dat_a);
  u_pipe_page_wr_dat_b : common_pipeline    GENERIC MAP ("SIGNED", g_pipeline_in, 0, g_data_w, g_data_w) PORT MAP (rst, clk, clken, '0', '1', nxt_page_wr_dat_b, page_wr_dat_b);
  
  two_pages : FOR I IN 0 TO c_nof_pages-1 GENERATE
    -- input mux pipelining
    u_pipe_page_wr_en_a  : common_pipeline_sl GENERIC MAP (          g_pipeline_in, 0, FALSE)              PORT MAP (rst, clk, clken, '0', '1', nxt_page_wr_en_a(I),  page_wr_en_a(I));
    u_pipe_page_wr_en_b  : common_pipeline_sl GENERIC MAP (          g_pipeline_in, 0, FALSE)              PORT MAP (rst, clk, clken, '0', '1', nxt_page_wr_en_b(I),  page_wr_en_b(I));
    u_pipe_page_rd_en_a  : common_pipeline_sl GENERIC MAP (          g_pipeline_in, 0, FALSE)              PORT MAP (rst, clk, clken, '0', '1', nxt_page_rd_en_a(I),  page_rd_en_a(I));
    u_pipe_page_rd_en_b  : common_pipeline_sl GENERIC MAP (          g_pipeline_in, 0, FALSE)              PORT MAP (rst, clk, clken, '0', '1', nxt_page_rd_en_b(I),  page_rd_en_b(I));
    u_pipe_page_adr_a    : common_pipeline    GENERIC MAP ("SIGNED", g_pipeline_in, 0, c_addr_w, c_addr_w) PORT MAP (rst, clk, clken, '0', '1', nxt_page_adr_a(I),    page_adr_a(I));
    u_pipe_page_adr_b    : common_pipeline    GENERIC MAP ("SIGNED", g_pipeline_in, 0, c_addr_w, c_addr_w) PORT MAP (rst, clk, clken, '0', '1', nxt_page_adr_b(I),    page_adr_b(I));

    u_page : ENTITY work.common_ram_rw_rw
    GENERIC MAP (
      g_technology => g_technology,
      g_ram       => c_page_ram,
      g_init_file => "UNUSED"
    )
    PORT MAP (
      rst       => rst,
      clk       => clk,
      clken     => clken,
      adr_a     => page_adr_a(I),
      wr_en_a   => page_wr_en_a(I),
      wr_dat_a  => page_wr_dat_a,
      rd_en_a   => page_rd_en_a(I),
      rd_dat_a  => page_rd_dat_a(I),
      rd_val_a  => page_rd_val_a(I),
      adr_b     => page_adr_b(I),
      wr_en_b   => page_wr_en_b(I),
      wr_dat_b  => page_wr_dat_b,
      rd_en_b   => page_rd_en_b(I),
      rd_dat_b  => page_rd_dat_b(I),
      rd_val_b  => page_rd_val_b(I)
    );
  END GENERATE;
  
  -- use page_sel_out to account for the RAM read latency
  nxt_rd_dat_a <= page_rd_dat_a(0) WHEN page_sel_out='1' ELSE page_rd_dat_a(1);
  nxt_rd_dat_b <= page_rd_dat_b(0) WHEN page_sel_out='1' ELSE page_rd_dat_b(1);
  nxt_rd_val_a <= page_rd_val_a(0) WHEN page_sel_out='1' ELSE page_rd_val_a(1);
  nxt_rd_val_b <= page_rd_val_b(0) WHEN page_sel_out='1' ELSE page_rd_val_b(1);
  
  -- output mux pipelining
  u_pipe_rd_dat_a : common_pipeline    GENERIC MAP ("SIGNED", g_pipeline_out, 0, g_data_w, g_data_w) PORT MAP (rst, clk, clken, '0', '1', nxt_rd_dat_a, rd_dat_a);
  u_pipe_rd_dat_b : common_pipeline    GENERIC MAP ("SIGNED", g_pipeline_out, 0, g_data_w, g_data_w) PORT MAP (rst, clk, clken, '0', '1', nxt_rd_dat_b, rd_dat_b);
  u_pipe_rd_val_a : common_pipeline_sl GENERIC MAP (          g_pipeline_out, 0, FALSE)              PORT MAP (rst, clk, clken, '0', '1', nxt_rd_val_a, rd_val_a);
  u_pipe_rd_val_b : common_pipeline_sl GENERIC MAP (          g_pipeline_out, 0, FALSE)              PORT MAP (rst, clk, clken, '0', '1', nxt_rd_val_b, rd_val_b);
    
END rtl;
