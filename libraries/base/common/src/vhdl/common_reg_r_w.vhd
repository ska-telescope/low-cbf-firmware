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

LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;

-- Derived from LOFAR cfg_single_reg

-- Purpose: Provide a MM interface to a register vector
--
-- Description:
--   The register has g_reg.nof_slaves replicas of g_reg.nof_dat words and
--   each word is g_reg.dat_w bits wide. At the control side the register
--   is accessed per word using the address input wr_adr or rd_adr as index.
--   At the data side the whole register group of
--   g_reg.nof_slaves*g_reg.dat_w*g_reg.nof_dat bits is available at once.
--   This is the key difference with using a RAM.
--
--   E.g. for g_reg.nof_slaves = 1, g_reg.nof_dat = 3 and g_reg.dat_w = 32 the
--   addressing accesses the register bits as follows:
--     wr_adr[1:0], rd_adr[1:0] = 0 --> reg[31:0]
--     wr_adr[1:0], rd_adr[1:0] = 1 --> reg[63:32]
--     wr_adr[1:0], rd_adr[1:0] = 2 --> reg[95:64]
--   E.g. for wr_adr = 0 and wr_en = '1': out_reg[31:0] = wr_dat[31:0]
--   E.g. for rd_adr = 0 and rd_en = '1':  rd_dat[31:0] = in_reg[31:0]
--
--   The word in the register that got accessed is reported via reg_wr_arr
--   or via reg_rd_arr depended on whether it was a write access or an read
--   access.
--
-- Usage:
-- 1) Connect out_reg to in_reg for write and readback register.
-- 2) Do not connect out_reg to in_reg for seperate write only register and
--    read only register at the same address.
-- 3) Leave out_reg OPEN for read only register.
-- 4) Connect wr_adr and rd_adr to have a shared address bus register.

ENTITY common_reg_r_w IS
   GENERIC (
      g_reg       : t_c_mem := c_mem_reg;
      g_init_reg  : STD_LOGIC_VECTOR(c_mem_reg_init_w-1 DOWNTO 0) := (OTHERS => '0');
      g_clr_mask  : STD_LOGIC_VECTOR(c_mem_reg_init_w-1 DOWNTO 0) := (OTHERS => '0'));
   PORT (
      mm_rst      : IN  STD_LOGIC := '0';
      mm_clk      : IN  STD_LOGIC;
      mm_clken    : IN  STD_LOGIC := '1';

      -- control side
      wr_en       : IN  STD_LOGIC;
      wr_adr      : IN  STD_LOGIC_VECTOR(g_reg.adr_w-1 DOWNTO 0);
      wr_dat      : IN  STD_LOGIC_VECTOR(g_reg.dat_w-1 DOWNTO 0);
      wr_val      : OUT STD_LOGIC;
      wr_busy     : OUT STD_LOGIC;

      rd_en       : IN  STD_LOGIC;
      rd_adr      : IN  STD_LOGIC_VECTOR(g_reg.adr_w-1 DOWNTO 0);
      rd_dat      : OUT STD_LOGIC_VECTOR(g_reg.dat_w-1 DOWNTO 0);
      rd_val      : OUT STD_LOGIC;
      rd_busy     : OUT STD_LOGIC;

      -- data side
      reg_wr_arr  : OUT STD_LOGIC_VECTOR(            g_reg.nof_slaves*g_reg.nof_dat-1 DOWNTO 0);
      reg_rd_arr  : OUT STD_LOGIC_VECTOR(            g_reg.nof_slaves*g_reg.nof_dat-1 DOWNTO 0);
      out_reg     : OUT STD_LOGIC_VECTOR(g_reg.dat_w*g_reg.nof_slaves*g_reg.nof_dat-1 DOWNTO 0);
      in_reg      : IN  STD_LOGIC_VECTOR(g_reg.dat_w*g_reg.nof_slaves*g_reg.nof_dat-1 DOWNTO 0));
END common_reg_r_w;


ARCHITECTURE rtl OF common_reg_r_w IS

  CONSTANT c_rd_latency  : NATURAL := 1;
  CONSTANT c_pipeline    : NATURAL := g_reg.latency - c_rd_latency;
  CONSTANT c_pipe_dat_w  : NATURAL := 2 + g_reg.dat_w;  -- pipeline rd_val & rd_dat together

  SIGNAL pipe_dat_in     : STD_LOGIC_VECTOR(c_pipe_dat_w-1 DOWNTO 0);
  SIGNAL pipe_dat_out    : STD_LOGIC_VECTOR(c_pipe_dat_w-1 DOWNTO 0);

  SIGNAL nxt_reg_wr_arr  : STD_LOGIC_VECTOR(reg_wr_arr'RANGE);
  SIGNAL nxt_reg_rd_arr  : STD_LOGIC_VECTOR(reg_rd_arr'RANGE);

  SIGNAL i_out_reg       : STD_LOGIC_VECTOR(out_reg'RANGE) := (OTHERS => g_reg.init_sl);
  SIGNAL nxt_out_reg     : STD_LOGIC_VECTOR(out_reg'RANGE) := (OTHERS => g_reg.init_sl);

  SIGNAL int_rd_dat      : STD_LOGIC_VECTOR(rd_dat'RANGE) := (OTHERS => g_reg.init_sl);
  SIGNAL int_rd_val      : STD_LOGIC;
  SIGNAL int_wr_val      : STD_LOGIC;
  SIGNAL nxt_wr_val      : STD_LOGIC;
  SIGNAL nxt_rd_dat      : STD_LOGIC_VECTOR(rd_dat'RANGE) := (OTHERS => g_reg.init_sl);
  SIGNAL nxt_rd_val      : STD_LOGIC;

BEGIN

   -- Not needed for single clock domains
   rd_busy <= '0';
   wr_busy <= '0';


  out_reg <= i_out_reg;

  -- Pipeline to support read data latency > 1
  u_pipe_rd : ENTITY common_lib.common_pipeline
  GENERIC MAP (
    g_pipeline   => c_pipeline,
    g_in_dat_w   => c_pipe_dat_w,
    g_out_dat_w  => c_pipe_dat_w
  )
  PORT MAP (
    clk     => mm_clk,
    clken   => mm_clken,
    in_dat  => pipe_dat_in,
    out_dat => pipe_dat_out
  );

  pipe_dat_in <= int_wr_val & int_rd_val & int_rd_dat;

  rd_dat <= pipe_dat_out(pipe_dat_out'HIGH-2 DOWNTO 0);
  rd_val <= pipe_dat_out(pipe_dat_out'HIGH-1);
  wr_val <= pipe_dat_out(pipe_dat_out'HIGH);

  p_reg : PROCESS (mm_rst, mm_clk)
  BEGIN
    IF mm_rst = '1' THEN
      -- Output signals.
      int_rd_val <= '0';
      int_wr_val <= '0';
      -- Internal signals.
      init_loop: FOR i in 0 to g_reg.nof_slaves-1 LOOP
         i_out_reg(g_reg.dat_w*g_reg.nof_dat*(i+1)-1 DOWNTO g_reg.dat_w*g_reg.nof_dat*i) <= g_init_reg(g_reg.dat_w*g_reg.nof_dat-1 DOWNTO 0);
      END LOOP;
    ELSIF rising_edge(mm_clk) THEN
      -- Output signals.
      reg_wr_arr <= nxt_reg_wr_arr;
      reg_rd_arr <= nxt_reg_rd_arr;
      int_rd_val <= nxt_rd_val;
      int_wr_val <= nxt_wr_val;
      int_rd_dat <= nxt_rd_dat;
      -- Internal signals.
      i_out_reg <= nxt_out_reg;
    END IF;
  END PROCESS;


  p_control : PROCESS (rd_en, int_rd_dat, rd_adr, in_reg, i_out_reg, wr_adr, wr_en, wr_dat)
  BEGIN
    nxt_reg_rd_arr <= (OTHERS=>'0');
    nxt_rd_dat <= int_rd_dat;
    nxt_rd_val <= '0';
    IF rd_en = '1' THEN
      FOR i IN 0 TO g_reg.nof_slaves*g_reg.nof_dat-1 LOOP
        IF UNSIGNED(rd_adr) = (i + g_reg.addr_base) THEN
          nxt_reg_rd_arr(i) <= '1';
          nxt_rd_dat <= in_reg((i+1)*g_reg.dat_w-1 DOWNTO i*g_reg.dat_w);
          nxt_rd_val <= '1';
        END IF;
      END LOOP;
    END IF;

    nxt_reg_wr_arr <= (OTHERS=>'0');
    nxt_out_reg <= i_out_reg;
    nxt_wr_val <= '0';
    IF wr_en = '1' THEN
      FOR i IN 0 TO g_reg.nof_slaves*g_reg.nof_dat-1 LOOP
        IF UNSIGNED(wr_adr) = (i + g_reg.addr_base) THEN
          nxt_reg_wr_arr(i) <= '1';
          nxt_out_reg((i+1)*g_reg.dat_w-1 DOWNTO i*g_reg.dat_w) <= wr_dat;
          nxt_wr_val <= '1';
        END IF;
      END LOOP;
    ELSIF rd_en = '1' THEN
      FOR i in 0 to g_reg.nof_slaves*g_reg.nof_dat-1 LOOP
        IF UNSIGNED(rd_adr) = (i + g_reg.addr_base) THEN
          nxt_out_reg((i+1)*g_reg.dat_w-1 DOWNTO i*g_reg.dat_w) <= i_out_reg((i+1)*g_reg.dat_w-1 DOWNTO i*g_reg.dat_w) and not g_clr_mask((i+1)*g_reg.dat_w-1 DOWNTO i*g_reg.dat_w);
        END IF;
      END LOOP;
    END IF;
  END PROCESS;

END rtl;
