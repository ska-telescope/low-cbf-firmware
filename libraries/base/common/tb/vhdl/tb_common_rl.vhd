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

-- Purpose: Test bench for common_rl_decrease and common_rl_increase.
--   The tb also uses a common_fifo_sc to investigate the relation between RL
--   and FIFO full to find out what almost full margin is needed to avoid FIFO
--   overflow.
-- Description:
--   The DUT consists of:
--
--   . a FIFO with RL=1
--   . followed by common_rl_decrease to make it a look ahead FIFO with RL=0
--   . and then common_rl_increase to get back to RL=1.
--
--   The tb uses fifo_almost_full to force rl_increase_in_ready='1' to avoid
--   FIFO overflow. The minimal almost full margin depends on the RL in the
--   chain.
--
--   Default g_rl_decrease_en and g_rl_increase_en are TRUE, but the tb also
--   works when g_rl_increase_en is FALSE or both are FALSE.

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;
USE work.common_lfsr_sequences_pkg.ALL;
USE work.tb_common_pkg.ALL;


ENTITY tb_common_rl IS
  GENERIC (
    g_nof_blocks               : NATURAL := 1000;   -- nof blocks to simulate
    g_random_enable            : BOOLEAN := TRUE;   -- use TRUE for random input enable flow control
    g_random_ready             : BOOLEAN := TRUE;   -- use TRUE for random output ready flow control
    g_fifo_size                : NATURAL := 1024;
    g_rl_decrease_en           : BOOLEAN := TRUE;   -- use TRUE to make the FIFO with RL = 1 behave as a show ahead fifo with RL = 0
    g_rl_increase_en           : BOOLEAN := FALSE;  -- use TRUE to go back to RL = 1
    g_rl_increase_hold_dat_en  : BOOLEAN := TRUE
  );
  PORT (
    tb_end_o                   : OUT STD_LOGIC);
END tb_common_rl;

-- Run 20 us, observe src_out_dat in wave window

ARCHITECTURE tb OF tb_common_rl IS

  CONSTANT clk_period         : TIME := 10 ns;

  CONSTANT c_dat_w            : NATURAL := 16;
  CONSTANT c_random_w         : NATURAL := 61;

  CONSTANT c_gen_rl           : NATURAL := 1;                                               -- input generator has fixed RL = 1
  CONSTANT c_fifo_rl          : NATURAL := 1;                                               -- FIFO has RL = 1 fixed

  CONSTANT c_rl_decrease_rl   : NATURAL := sel_a_b(g_rl_decrease_en, 0, 1);                 -- show ahead FIFO has RL = 0

  CONSTANT c_rl_increase_en   : BOOLEAN := c_rl_decrease_rl=1 AND g_rl_increase_en;         -- only accept increase RL to 1 if current RL is 0
  CONSTANT c_rl_increase_rl   : NATURAL := sel_a_b(c_rl_increase_en, 1, c_rl_decrease_rl);  -- determine output RL

  CONSTANT c_fifo_af_margin   : NATURAL := c_fifo_rl + c_rl_increase_rl;

  SIGNAL rst                        : STD_LOGIC;
  SIGNAL clk                        : STD_LOGIC := '0';
  SIGNAL tb_end                     : STD_LOGIC := '0';

  SIGNAL fifo_out_ready             : STD_LOGIC;
  SIGNAL fifo_in_dat                : STD_LOGIC_VECTOR(c_dat_w-1 DOWNTO 0);
  SIGNAL fifo_in_val                : STD_LOGIC;

  SIGNAL fifo_emp                   : STD_LOGIC;
  SIGNAL fifo_ful                   : STD_LOGIC;
  SIGNAL fifo_almost_full           : STD_LOGIC := '0';
  SIGNAL fifo_usedw                 : STD_LOGIC_VECTOR(ceil_log2(g_fifo_size)-1 DOWNTO 0);

  SIGNAL fifo_in_ready              : STD_LOGIC;
  SIGNAL fifo_out_dat               : STD_LOGIC_VECTOR(c_dat_w-1 DOWNTO 0);
  SIGNAL fifo_out_val               : STD_LOGIC;

  SIGNAL rl_decrease_in_ready       : STD_LOGIC;
  SIGNAL rl_decrease_out_dat        : STD_LOGIC_VECTOR(c_dat_w-1 DOWNTO 0);
  SIGNAL rl_decrease_out_val        : STD_LOGIC;

  SIGNAL rl_increase_in_ready       : STD_LOGIC;
  SIGNAL rl_increase_out_dat        : STD_LOGIC_VECTOR(c_dat_w-1 DOWNTO 0);
  SIGNAL rl_increase_out_val        : STD_LOGIC;

  SIGNAL enable                     : STD_LOGIC := '1';
  SIGNAL random0                    : STD_LOGIC_VECTOR(c_random_w-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL random1                    : STD_LOGIC_VECTOR(c_random_w   DOWNTO 0) := (OTHERS=>'0');
  SIGNAL verify_en                  : STD_LOGIC := '1';

  SIGNAL prev_fifo_in_ready         : STD_LOGIC;
  SIGNAL prev_fifo_out_dat          : STD_LOGIC_VECTOR(c_dat_w-1 DOWNTO 0);
  SIGNAL prev_rl_decrease_in_ready  : STD_LOGIC;
  SIGNAL prev_rl_decrease_out_dat   : STD_LOGIC_VECTOR(c_dat_w-1 DOWNTO 0);
  SIGNAL prev_rl_increase_in_ready  : STD_LOGIC;
  SIGNAL prev_rl_increase_out_dat   : STD_LOGIC_VECTOR(c_dat_w-1 DOWNTO 0);

BEGIN
  tb_end_o <= tb_end;

  rst <= '1', '0' AFTER clk_period*7;
  clk <= NOT clk OR tb_end AFTER clk_period/2;

  tb_end    <= '0', '1' AFTER clk_period*g_nof_blocks*g_fifo_size;
  verify_en <= '0', '1' AFTER clk_period*(10 + c_random_w);

  random0 <= func_common_random(random0) WHEN rising_edge(clk);
  random1 <= func_common_random(random1) WHEN rising_edge(clk);

  ------------------------------------------------------------------------------
  -- Stimuli
  ------------------------------------------------------------------------------
  -- Flow control
  enable               <= random0(random0'HIGH)                     WHEN g_random_enable=TRUE ELSE '1';
  rl_increase_in_ready <= random1(random1'HIGH) OR fifo_almost_full WHEN g_random_ready=TRUE ELSE '1';

  -- Generate FIFO input with c_gen_rl = 1 and counter data starting at 0
  proc_common_gen_data(c_gen_rl, 0, rst, clk, enable, fifo_out_ready, fifo_in_dat, fifo_in_val);


  ------------------------------------------------------------------------------
  -- Verification
  ------------------------------------------------------------------------------
  -- Verify dut output incrementing data
  proc_common_verify_data(c_fifo_rl,        clk, verify_en, fifo_in_ready,        fifo_out_val,        fifo_out_dat,        prev_fifo_out_dat);
  proc_common_verify_data(c_rl_decrease_rl, clk, verify_en, rl_decrease_in_ready, rl_decrease_out_val, rl_decrease_out_dat, prev_rl_decrease_out_dat);
  proc_common_verify_data(c_rl_increase_rl, clk, verify_en, rl_increase_in_ready, rl_increase_out_val, rl_increase_out_dat, prev_rl_increase_out_dat);

  -- Verify dut output stream ready - valid relation
  proc_common_verify_valid(c_fifo_rl,        clk, verify_en, fifo_in_ready,        prev_fifo_in_ready,        fifo_out_val);
  proc_common_verify_valid(c_rl_decrease_rl, clk, verify_en, rl_decrease_in_ready, prev_rl_decrease_in_ready, rl_decrease_out_val);
  proc_common_verify_valid(c_rl_increase_rl, clk, verify_en, rl_increase_in_ready, prev_rl_increase_in_ready, rl_increase_out_val);


  ------------------------------------------------------------------------------
  -- DUT
  ------------------------------------------------------------------------------

  -- model input without ready flow control (anyway can not use NOT fifo_ful, because that stimuli come with RL=1 so will stop 1 cycle too late when FIFO is full)
  fifo_out_ready <= '1';

  u_fifo_sc : ENTITY work.common_fifo_sc
  GENERIC MAP (
    g_note_is_ful => TRUE,   -- when TRUE report NOTE when FIFO goes full, fifo overflow is always reported as FAILURE
    g_dat_w       => c_dat_w,
    g_nof_words   => g_fifo_size,
    g_af_margin   => c_fifo_af_margin
  )
  PORT MAP (
    rst      => rst,
    clk      => clk,
    wr_dat   => fifo_in_dat,
    wr_req   => fifo_in_val,
    wr_ful   => fifo_ful,
    wr_aful  => fifo_almost_full,  -- get FIFO almost full to be used to force rl_increase_in_ready
    rd_dat   => fifo_out_dat,
    rd_req   => fifo_in_ready,
    rd_emp   => fifo_emp,
    rd_val   => fifo_out_val,
    usedw    => fifo_usedw
  );

  -- RL 1 --> 0
  u_rl_decrease : ENTITY work.common_rl_decrease
  GENERIC MAP (
    g_adapt       => g_rl_decrease_en,
    g_dat_w       => c_dat_w
  )
  PORT MAP (
    rst           => rst,
    clk           => clk,
    -- ST sink: RL = 1
    snk_out_ready => fifo_in_ready,
    snk_in_dat    => fifo_out_dat,
    snk_in_val    => fifo_out_val,
    -- ST source: RL = 0
    src_in_ready  => rl_decrease_in_ready,
    src_out_dat   => rl_decrease_out_dat,
    src_out_val   => rl_decrease_out_val
  );


  -- RL 0 --> 1
  u_rl_increase : ENTITY work.common_rl_increase
  GENERIC MAP (
    g_adapt       => c_rl_increase_en,
    g_hold_dat_en => g_rl_increase_hold_dat_en,
    g_dat_w       => c_dat_w
  )
  PORT MAP (
    rst           => rst,
    clk           => clk,
    -- Sink
    snk_out_ready => rl_decrease_in_ready,
    snk_in_dat    => rl_decrease_out_dat,
    snk_in_val    => rl_decrease_out_val,
    -- Source
    src_in_ready  => rl_increase_in_ready,
    src_out_dat   => rl_increase_out_dat,
    src_out_val   => rl_increase_out_val
  );

END tb;
