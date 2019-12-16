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

-- Purpose: Test bench for common_ddreg_slv
-- Usage:
--   > as 5
--   > run -all
--
-- Description: See common_ddreg.vhd

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;
USE work.tb_common_pkg.ALL;

ENTITY tb_common_ddreg_slv IS
END tb_common_ddreg_slv;


ARCHITECTURE tb OF tb_common_ddreg_slv IS

  CONSTANT in_clk_period   : TIME :=  5 ns;
  
  CONSTANT c_tb_interval   : NATURAL := 100;
  CONSTANT c_in_dat_w      : NATURAL := 8;
  
  SIGNAL tb_end         : STD_LOGIC := '0';
  SIGNAL in_clk         : STD_LOGIC := '0';
  SIGNAL in_dat         : STD_LOGIC_VECTOR(c_in_dat_w-1 DOWNTO 0) := (OTHERS=>'0');
  
  SIGNAL rst            : STD_LOGIC;
  SIGNAL out_clk        : STD_LOGIC := '0';
  SIGNAL out_dat        : STD_LOGIC_VECTOR(2*c_in_dat_w-1 DOWNTO 0);
  SIGNAL out_dat_hi     : STD_LOGIC_VECTOR(c_in_dat_w-1 DOWNTO 0);
  SIGNAL out_dat_lo     : STD_LOGIC_VECTOR(c_in_dat_w-1 DOWNTO 0);

BEGIN

  in_clk  <= NOT in_clk  OR tb_end AFTER in_clk_period/2;
  out_clk <= NOT out_clk WHEN rising_edge(in_clk);
  
  rst <= '1', '0' AFTER in_clk_period*10;
  
  in_dat <= INCR_UVEC(in_dat, 1) WHEN rising_edge(in_clk);
  
  p_in_stimuli : PROCESS
  BEGIN
    proc_common_wait_some_cycles(out_clk, c_tb_interval);
    tb_end <= '1';
    WAIT;
  END PROCESS;
  
  u_common_ddreg_slv : ENTITY work.common_ddreg_slv
  GENERIC MAP (
    g_in_delay_len  => 1,
    g_out_delay_len => c_meta_delay_len
  )
  PORT MAP (
    in_clk      => in_clk,
    in_dat      => in_dat,
    rst         => rst,
    out_clk     => out_clk,
    out_dat_hi  => out_dat_hi,
    out_dat_lo  => out_dat_lo
  );

  out_dat <= out_dat_hi & out_dat_lo;
  
END tb;
