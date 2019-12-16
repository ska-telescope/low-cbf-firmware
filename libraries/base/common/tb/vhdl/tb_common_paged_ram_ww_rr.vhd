-------------------------------------------------------------------------------
--
-- Copyright (C) 2013
-- ASTRON (Netherlands Institute for Radio Astronomy) <http://www.astron.nl/>
-- JIVE (Joint Institute for VLBI in Europe) <http://www.jive.nl/>
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
USE work.tb_common_pkg.ALL;

-- Purpose: Test bench for common_paged_ram_ww_rr
-- Description:
--   Verifies two DUTs ww_rr and w_rr using incrementing data.
-- Features:
-- . Page size can be any size g_page_sz >= 1, so not only powers of 2
-- . Use c_gap_sz = 0 to try writing and reading multiple page without idle
--   cycles
--
-- Usage:
-- > as 10
-- > run -all


ENTITY tb_common_paged_ram_ww_rr IS
  GENERIC (
    g_pipeline_in     : NATURAL := 0;   -- >= 0
    g_pipeline_out    : NATURAL := 1;   -- >= 0
    g_page_sz         : NATURAL := 10   -- >= 1
  );
  PORT (
    tb_end_o          : OUT STD_LOGIC);
END tb_common_paged_ram_ww_rr;

ARCHITECTURE tb OF tb_common_paged_ram_ww_rr IS

  CONSTANT clk_period        : TIME := 10 ns;

  CONSTANT c_nof_blocks      : NATURAL := 4;

  CONSTANT c_ram_rd_latency  : NATURAL := 1;
  CONSTANT c_rd_latency      : NATURAL := g_pipeline_in + c_ram_rd_latency + g_pipeline_out;
  CONSTANT c_offset_a        : NATURAL := 2 MOD g_page_sz;  -- use c_offset_a and c_offset_b to have a read and b read from independent address
  CONSTANT c_offset_b        : NATURAL := 5 MOD g_page_sz;

  CONSTANT c_data_w          : NATURAL := 8;
  CONSTANT c_gap_sz          : NATURAL := 0;  -- >= 0
  CONSTANT c_addr_w          : NATURAL := ceil_log2(g_page_sz);
  CONSTANT c_rl              : NATURAL := 1;

  SIGNAL rst               : STD_LOGIC;
  SIGNAL clk               : STD_LOGIC := '1';
  SIGNAL tb_end            : STD_LOGIC := '0';

  -- DUT
  SIGNAL next_page         : STD_LOGIC;

  SIGNAL in_en             : STD_LOGIC;
  SIGNAL in_adr            : STD_LOGIC_VECTOR(c_addr_w-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL in_mod_adr        : NATURAL;
  SIGNAL in_dat            : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0) := (OTHERS=>'0');

  SIGNAL wr_en_a           : STD_LOGIC;
  SIGNAL wr_adr_a          : STD_LOGIC_VECTOR(c_addr_w-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL wr_dat_a          : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0) := (OTHERS=>'0');

  SIGNAL wr_en_b           : STD_LOGIC;
  SIGNAL wr_adr_b          : STD_LOGIC_VECTOR(c_addr_w-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL wr_dat_b          : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0) := (OTHERS=>'0');

  SIGNAL rd_en_a           : STD_LOGIC;
  SIGNAL rd_adr_a          : STD_LOGIC_VECTOR(c_addr_w-1 DOWNTO 0);
  SIGNAL wrr_rd_dat_a      : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);
  SIGNAL wrr_rd_val_a      : STD_LOGIC;
  SIGNAL wwrr_rd_dat_a     : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);
  SIGNAL wwrr_rd_val_a     : STD_LOGIC;

  SIGNAL rd_en_b           : STD_LOGIC;
  SIGNAL rd_adr_b          : STD_LOGIC_VECTOR(c_addr_w-1 DOWNTO 0);
  SIGNAL wrr_rd_dat_b      : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);
  SIGNAL wrr_rd_val_b      : STD_LOGIC;
  SIGNAL wwrr_rd_dat_b     : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);
  SIGNAL wwrr_rd_val_b     : STD_LOGIC;

  -- Verify
  SIGNAL ready                  : STD_LOGIC := '1';
  SIGNAL verify_en              : STD_LOGIC;

  SIGNAL wrr_mod_dat_a          : NATURAL;
  SIGNAL wrr_mod_dat_b          : NATURAL;
  SIGNAL wrr_offset_dat_a       : NATURAL;
  SIGNAL wrr_offset_dat_b       : NATURAL;
  SIGNAL wrr_result_dat_a       : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);
  SIGNAL wrr_result_dat_b       : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);
  SIGNAL prev_wrr_result_dat_a  : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);
  SIGNAL prev_wrr_result_dat_b  : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);

  SIGNAL wwrr_mod_dat_a         : NATURAL;
  SIGNAL wwrr_mod_dat_b         : NATURAL;
  SIGNAL wwrr_offset_dat_a      : NATURAL;
  SIGNAL wwrr_offset_dat_b      : NATURAL;
  SIGNAL wwrr_result_dat_a      : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);
  SIGNAL wwrr_result_dat_b      : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);
  SIGNAL prev_wwrr_result_dat_a : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);
  SIGNAL prev_wwrr_result_dat_b : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);

BEGIN

  tb_end_o <= tb_end;

  clk <= NOT clk AND NOT tb_end AFTER clk_period/2;
  rst <= '1', '0' AFTER clk_period*2;

  -- Single write use in_en
  in_mod_adr <= TO_UINT(in_adr) MOD g_page_sz;
  in_dat <= INCR_UVEC(in_dat, 1) WHEN rising_edge(clk) AND in_en='1';
  in_adr <= TO_UVEC((TO_UINT(in_adr) + 1) MOD g_page_sz, c_addr_w) WHEN rising_edge(clk) AND in_en='1';

  -- Double write use in_en for halve of the g_page_sz time
  wr_en_a  <= in_en WHEN in_mod_adr MOD 2=0 ELSE '0';  -- use port a to write the even addresses
  wr_dat_a <= in_dat;
  wr_adr_a <= in_adr;

  wr_en_b  <= '0'   WHEN in_mod_adr=g_page_sz-1 AND g_page_sz MOD 2 = 1 ELSE  -- do not write at last address in case of odd g_page_sz
              in_en WHEN in_mod_adr MOD 2=0 ELSE '0';                         -- use port b to write the odd addresses

  wr_dat_b <= INCR_UVEC(in_dat, 1);
  wr_adr_b <= TO_UVEC((TO_UINT(in_adr) + 1) MOD g_page_sz, c_addr_w);

  -- Double read use in_en
  rd_en_a  <= in_en;
  rd_adr_a <= TO_UVEC((TO_UINT(in_adr) + c_offset_a) MOD g_page_sz, c_addr_w);  -- b read from other address than a
  rd_en_b  <= in_en;
  rd_adr_b <= TO_UVEC((TO_UINT(in_adr) + c_offset_b) MOD g_page_sz, c_addr_w);  -- b read from other address than a

  p_stimuli : PROCESS
  BEGIN
    next_page <= '0';
    in_en     <= '0';
    proc_common_wait_until_low(clk, rst);
    proc_common_wait_some_cycles(clk, 3);

    -- Access the pages several times
    FOR I IN 0 TO c_nof_blocks-1 LOOP
      in_en <= '1';
      proc_common_wait_some_cycles(clk, g_page_sz-1);
      next_page <= '1';
      proc_common_wait_some_cycles(clk, 1);
      next_page <= '0';
      in_en <= '0';
      proc_common_wait_some_cycles(clk, c_gap_sz);  -- optional gap between the pages
    END LOOP;

    in_en <= '0';
    proc_common_wait_some_cycles(clk, 1+g_page_sz/2);
    tb_end <= '1';
    WAIT;
  END PROCESS;

  p_verify : PROCESS
  BEGIN
    verify_en <= '0';
    proc_common_wait_until_high(clk, next_page);
    proc_common_wait_some_cycles(clk, c_rd_latency);
    proc_common_wait_some_cycles(clk, 1);             -- use first read value as initial reference value
    verify_en <= '1';
    WAIT;
  END PROCESS;

  ------------------------------------------------------------------------------
  -- DUTs
  ------------------------------------------------------------------------------

  -- Double write - double read
  u_dut_ww_rr : ENTITY work.common_paged_ram_ww_rr
  GENERIC MAP (
    g_pipeline_in  => g_pipeline_in,
    g_pipeline_out => g_pipeline_out,
    g_data_w       => c_data_w,
    g_page_sz      => g_page_sz
  )
  PORT MAP (
    rst         => rst,
    clk         => clk,
    clken       => '1',
    -- next page control
    next_page   => next_page,
    -- double write access to one page
    wr_adr_a    => wr_adr_a,
    wr_en_a     => wr_en_a,
    wr_dat_a    => wr_dat_a,
    wr_adr_b    => wr_adr_b,
    wr_en_b     => wr_en_b,
    wr_dat_b    => wr_dat_b,
    -- double read access from the other one page
    rd_adr_a    => rd_adr_a,
    rd_en_a     => rd_en_a,
    rd_adr_b    => rd_adr_b,
    rd_en_b     => rd_en_b,
    -- double read data from the other one page after c_rd_latency
    rd_dat_a    => wwrr_rd_dat_a,
    rd_val_a    => wwrr_rd_val_a,
    rd_dat_b    => wwrr_rd_dat_b,
    rd_val_b    => wwrr_rd_val_b
  );

  -- Single write - double read
  u_dut_w_rr : ENTITY work.common_paged_ram_w_rr
  GENERIC MAP (
    g_pipeline_in  => g_pipeline_in,
    g_pipeline_out => g_pipeline_out,
    g_data_w       => c_data_w,
    g_page_sz      => g_page_sz
  )
  PORT MAP (
    rst         => rst,
    clk         => clk,
    clken       => '1',
    -- next page control
    next_page   => next_page,
    -- double write access to one page
    wr_adr      => in_adr,
    wr_en       => in_en,
    wr_dat      => in_dat,
    -- double read access from the other one page
    rd_adr_a    => rd_adr_a,
    rd_en_a     => rd_en_a,
    rd_adr_b    => rd_adr_b,
    rd_en_b     => rd_en_b,
    -- double read data from the other one page after c_rd_latency
    rd_dat_a    => wrr_rd_dat_a,
    rd_val_a    => wrr_rd_val_a,
    rd_dat_b    => wrr_rd_dat_b,
    rd_val_b    => wrr_rd_val_b
  );

  ------------------------------------------------------------------------------
  -- Verify
  ------------------------------------------------------------------------------

  -- Undo the read offset address to restore incrementing data
  -- . Single write - double read:
  wrr_mod_dat_a    <= TO_UINT(wrr_rd_dat_a) MOD g_page_sz;
  wrr_mod_dat_b    <= TO_UINT(wrr_rd_dat_b) MOD g_page_sz;
  wrr_offset_dat_a <= 0 WHEN wrr_mod_dat_a=c_offset_a ELSE g_page_sz WHEN wrr_mod_dat_a=0;
  wrr_offset_dat_b <= 0 WHEN wrr_mod_dat_b=c_offset_b ELSE g_page_sz WHEN wrr_mod_dat_b=0;
  wrr_result_dat_a <= INCR_UVEC(wrr_rd_dat_a, wrr_offset_dat_a);
  wrr_result_dat_b <= INCR_UVEC(wrr_rd_dat_b, wrr_offset_dat_b);
  -- . Double write - double read:
  wwrr_mod_dat_a    <= TO_UINT(wwrr_rd_dat_a) MOD g_page_sz;
  wwrr_mod_dat_b    <= TO_UINT(wwrr_rd_dat_b) MOD g_page_sz;
  wwrr_offset_dat_a <= 0 WHEN wwrr_mod_dat_a=c_offset_a ELSE g_page_sz WHEN wwrr_mod_dat_a=0;
  wwrr_offset_dat_b <= 0 WHEN wwrr_mod_dat_b=c_offset_b ELSE g_page_sz WHEN wwrr_mod_dat_b=0;
  wwrr_result_dat_a <= INCR_UVEC(wwrr_rd_dat_a, wrr_offset_dat_a);
  wwrr_result_dat_b <= INCR_UVEC(wwrr_rd_dat_b, wrr_offset_dat_b);

  -- Verify that the read data is incrementing data
  -- . Single write - double read:
  proc_common_verify_data(c_rl, clk, verify_en, ready, wrr_rd_val_a, wrr_result_dat_a, prev_wrr_result_dat_a);
  proc_common_verify_data(c_rl, clk, verify_en, ready, wrr_rd_val_b, wrr_result_dat_b, prev_wrr_result_dat_b);
  -- Double write - double read:
  proc_common_verify_data(c_rl, clk, verify_en, ready, wwrr_rd_val_a, wwrr_result_dat_a, prev_wwrr_result_dat_a);
  proc_common_verify_data(c_rl, clk, verify_en, ready, wwrr_rd_val_b, wwrr_result_dat_b, prev_wwrr_result_dat_b);

END tb;
