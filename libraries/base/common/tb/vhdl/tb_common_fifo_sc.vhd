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

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;
USE work.common_lfsr_sequences_pkg.ALL;
USE work.tb_common_pkg.ALL;


ENTITY tb_common_fifo_sc IS
  GENERIC (
    g_random_control : BOOLEAN := TRUE  -- use TRUE for random rd_req control
  );
END tb_common_fifo_sc;

-- Run -all, observe rd_dat in wave window

ARCHITECTURE tb OF tb_common_fifo_sc IS

  CONSTANT clk_period   : TIME := 10 ns;
  CONSTANT c_dat_w      : NATURAL := 16;
  CONSTANT c_fifo_rl    : NATURAL := 1;  -- FIFO has RL = 1
  CONSTANT c_read_rl    : NATURAL := 0;  -- show ahead FIFO has RL = 0

  SIGNAL rst         : STD_LOGIC;
  SIGNAL clk         : STD_LOGIC := '0';
  SIGNAL tb_end      : STD_LOGIC := '0';

  SIGNAL fifo_req    : STD_LOGIC := '1';
  SIGNAL fifo_dat    : STD_LOGIC_VECTOR(c_dat_w-1 DOWNTO 0);
  SIGNAL fifo_val    : STD_LOGIC;

  SIGNAL rd_req      : STD_LOGIC;
  SIGNAL rd_dat      : STD_LOGIC_VECTOR(c_dat_w-1 DOWNTO 0);
  SIGNAL rd_val      : STD_LOGIC;

  SIGNAL enable      : STD_LOGIC := '1';
  SIGNAL random      : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL verify_en   : STD_LOGIC := '1';
  SIGNAL prev_rd_req : STD_LOGIC;
  SIGNAL prev_rd_dat : STD_LOGIC_VECTOR(c_dat_w-1 DOWNTO 0);

BEGIN

  rst <= '1', '0' AFTER clk_period*7;
  clk <= NOT clk OR tb_end AFTER clk_period/2;
  tb_end <= '0', '1' AFTER 20 us;

  verify_en <= '0', '1' AFTER clk_period*35;

  -- Model FIFO output with c_rl = 1 and counter data starting at 0
  proc_common_gen_data(c_fifo_rl, 0, rst, clk, enable, fifo_req, fifo_dat, fifo_val);

  -- Model rd_req
  random <= func_common_random(random) WHEN rising_edge(clk);
  rd_req <= random(random'HIGH) WHEN g_random_control=TRUE ELSE '1';

  -- Verify dut output incrementing data
  proc_common_verify_data(c_read_rl, clk, verify_en, rd_req, rd_val, rd_dat, prev_rd_dat);

  -- Verify dut output stream ready - valid relation, prev_rd_req is an auxiliary signal needed by the proc
  proc_common_verify_valid(c_read_rl, clk, verify_en, rd_req, prev_rd_req, rd_val);


--  u_dut : ENTITY work.common_fifo_sc
--  GENERIC MAP (
--    g_dat_w => c_dat_w,
--    g_nof_words => 64
--  )
--  PORT MAP (
--    rst        => rst,
--    clk        => clk,
--
--    wr_req   => fifo_val,
--    wr_dat   => fifo_dat,
--    rd_req     => rd_req,
--    rd_dat     => rd_dat,
--    rd_val     => rd_val
--  );


  u_dut : ENTITY work.common_fifo_dc
  GENERIC MAP (
    g_dat_w => c_dat_w,
    g_nof_words => 64
  )
  PORT MAP (
    rst        => rst,
    wr_clk        => clk,
    rd_clk        => clk,

    wr_req   => fifo_val,
    wr_dat   => fifo_dat,
    rd_req     => rd_req,
    rd_dat     => rd_dat,
    rd_val     => rd_val
  );



END tb;
