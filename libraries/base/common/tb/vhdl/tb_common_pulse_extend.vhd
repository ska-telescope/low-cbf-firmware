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
USE work.tb_common_pkg.ALL;

ENTITY tb_common_pulse_extend IS
  GENERIC (
    g_p_in_level   : STD_LOGIC := '0';
    g_ep_out_level : STD_LOGIC := '0'
  );
END tb_common_pulse_extend;

ARCHITECTURE tb OF tb_common_pulse_extend IS

  CONSTANT clk_period     : TIME := 10 ns;
    
  CONSTANT c_extend_w     : NATURAL := 3;
  CONSTANT c_extend_len   : NATURAL := 2**c_extend_w;
  CONSTANT c_interval_len : NATURAL := 2*c_extend_len;

  SIGNAL tb_end    : STD_LOGIC := '0';
  SIGNAL rst       : STD_LOGIC;
  SIGNAL clk       : STD_LOGIC := '0';
  SIGNAL pulse_in  : STD_LOGIC;
  SIGNAL pulse_out : STD_LOGIC;

BEGIN

  clk <= NOT clk OR tb_end AFTER clk_period/2;
    
  p_in_stimuli : PROCESS
  BEGIN
    rst <= '1';
    pulse_in <= '0';
    proc_common_wait_some_cycles(clk, 10);
    rst <= '0';
    proc_common_wait_some_cycles(clk, c_interval_len);
    pulse_in <= '1';
    proc_common_wait_some_cycles(clk, c_interval_len);
    pulse_in <= '0';
    proc_common_wait_some_cycles(clk, c_interval_len);
    proc_common_wait_some_cycles(clk, c_extend_len);
    pulse_in <= '1';
    proc_common_wait_some_cycles(clk, c_interval_len);
    pulse_in <= '0';
    proc_common_wait_some_cycles(clk, c_interval_len);
    pulse_in <= '1';
    proc_common_wait_some_cycles(clk, c_interval_len);
    proc_common_wait_some_cycles(clk, c_extend_len);
    tb_end <= '1';
    WAIT;
  END PROCESS;
  
  u_spulse : ENTITY work.common_pulse_extend
  GENERIC MAP (
    g_rst_level    => '0',
    g_p_in_level   => g_p_in_level,
    g_ep_out_level => g_ep_out_level,
    g_extend_w     => c_extend_w
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    p_in    => pulse_in,
    ep_out  => pulse_out
  );
      
END tb;
