-------------------------------------------------------------------------------
--
-- Copyright (C) 2009
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

-- Purpose: Test bench for common_fifo_dc_mixed_widths
-- Usage:
--   > as 10
--   > run -all
--   . observe rd_dat in wave window

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;
USE work.tb_common_pkg.ALL;


ENTITY tb_common_fifo_dc_mixed_widths IS
  GENERIC (
    g_wr_clk_freq : POSITIVE := 1;   -- normalized write clock frequency
    g_rd_clk_freq : POSITIVE := 1;   -- normalized read  clock frequency
    g_wr_dat_w    : NATURAL :=  8;
    g_rd_dat_w    : NATURAL := 16
    --g_rd_dat_w    : NATURAL := 4
  );
END tb_common_fifo_dc_mixed_widths;


ARCHITECTURE tb OF tb_common_fifo_dc_mixed_widths IS

  CONSTANT clk_period           : TIME := 10 ns;
  
  CONSTANT c_run_interval       : NATURAL := 2**g_wr_dat_w;
  
  CONSTANT c_wr_fifo_nof_words  : NATURAL := 32;
  
  SIGNAL tb_end               : STD_LOGIC := '0';
  SIGNAL rst                  : STD_LOGIC;
  
  SIGNAL wr_clk               : STD_LOGIC := '0';
  SIGNAL wr_dat               : STD_LOGIC_VECTOR(g_wr_dat_w-1 DOWNTO 0);
  SIGNAL wr_val               : STD_LOGIC;
  SIGNAL wr_ful               : STD_LOGIC;
  SIGNAL wr_usedw             : STD_LOGIC_VECTOR(ceil_log2(c_wr_fifo_nof_words)-1 DOWNTO 0);


  SIGNAL rd_clk               : STD_LOGIC := '0';
  SIGNAL rd_dat               : STD_LOGIC_VECTOR(g_rd_dat_w-1 DOWNTO 0);
  SIGNAL rd_req               : STD_LOGIC;
  SIGNAL rd_val               : STD_LOGIC;
  SIGNAL rd_emp               : STD_LOGIC;
  SIGNAL rd_usedw             : STD_LOGIC_VECTOR(ceil_log2(c_wr_fifo_nof_words*g_wr_dat_w/g_rd_dat_w)-1 DOWNTO 0);
  
  
BEGIN

  rst <= '1', '0' AFTER clk_period*7;
  
  wr_clk  <= NOT wr_clk OR tb_end AFTER g_rd_clk_freq*clk_period/2;
  rd_clk  <= NOT rd_clk OR tb_end AFTER g_wr_clk_freq*clk_period/2;
  
  p_wr_stimuli : PROCESS
  BEGIN
    wr_dat <= TO_UVEC(0, g_wr_dat_w);
    wr_val <= '0';
    WAIT UNTIL rst='0';
    proc_common_wait_some_cycles(wr_clk, 10);
    
    wr_val <= '1';
    WAIT UNTIL rising_edge(wr_clk);
    FOR I IN 0 TO 2*c_run_interval-1 LOOP
      wr_dat <= INCR_UVEC(wr_dat, 1);
      wr_val <= '1';
      WAIT UNTIL rising_edge(wr_clk);
    END LOOP;
    wr_val <= '0';
    proc_common_wait_some_cycles(wr_clk, 10);
    
    FOR I IN 0 TO 9 LOOP
      wr_dat <= INCR_UVEC(wr_dat, 1);
      wr_val <= '1';
      WAIT UNTIL rising_edge(wr_clk);
      wr_val <= '0';
      proc_common_wait_some_cycles(wr_clk, 10);
    END LOOP;
    
    proc_common_wait_some_cycles(wr_clk, 100);
    proc_common_wait_some_cycles(rd_clk, 100);
    tb_end <= '1';
    WAIT;
  END PROCESS;
  
  rd_req <= '1';
  
  u_dut : ENTITY work.common_fifo_dc_mixed_widths
  GENERIC MAP (
    g_nof_words => c_wr_fifo_nof_words,
    g_wr_dat_w  => g_wr_dat_w,
    g_rd_dat_w  => g_rd_dat_w
  )
  PORT MAP (
    rst     => rst,
    wr_clk  => wr_clk,
    wr_dat  => wr_dat,
    wr_req  => wr_val,
    wr_ful  => wr_ful,
    wrusedw => wr_usedw,
    rd_clk  => rd_clk,
    rd_dat  => rd_dat,
    rd_req  => rd_req,
    rd_emp  => rd_emp,
    rdusedw => rd_usedw,
    rd_val  => rd_val
  );
  
END tb;
