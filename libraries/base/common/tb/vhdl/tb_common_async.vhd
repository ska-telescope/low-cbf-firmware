-------------------------------------------------------------------------------
--
-- Copyright (C) 2012
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

-- Purpose: Test bench to compare common_async with common_areset
-- Usage:
--   > as 1
--   > run -all
--
-- Description:

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;
USE work.tb_common_pkg.ALL;

ENTITY tb_common_async IS
END tb_common_async;


ARCHITECTURE tb OF tb_common_async IS

  CONSTANT clk_period   : TIME := 10 ns;
  
  CONSTANT c_delay_len  : NATURAL := 3;

  SIGNAL dbg_state                : NATURAL;
  
  SIGNAL tb_end                   : STD_LOGIC := '0';
  SIGNAL clk                      : STD_LOGIC := '0';
  
  SIGNAL in_rst                   : STD_LOGIC;
  SIGNAL in_dat                   : STD_LOGIC;
  
  SIGNAL out_async                : STD_LOGIC;
  SIGNAL out_areset               : STD_LOGIC;

BEGIN

  clk  <= NOT clk OR tb_end AFTER clk_period/2;
    
  p_in_stimuli : PROCESS
  BEGIN
    dbg_state <= 0;
    in_dat <= '1';
    in_rst <= '1';
    proc_common_wait_some_cycles(clk, 5);
    in_dat <= '0';
    in_rst <= '0';
    proc_common_wait_some_cycles(clk, 50);

    dbg_state <= 1;
    in_dat <= '1';
    proc_common_wait_some_cycles(clk, 5);
    in_dat <= '0';
    proc_common_wait_some_cycles(clk, 50);
    
    dbg_state <= 2;
    in_rst <= '1';
    proc_common_wait_some_cycles(clk, 5);
    in_rst <= '0';
    proc_common_wait_some_cycles(clk, 50);
    
    dbg_state <= 9;
    proc_common_wait_some_cycles(clk, 10);
    tb_end <= '1';
    WAIT;
  END PROCESS;

  u_async : ENTITY work.common_async
  GENERIC MAP (
    g_rst_level => '1',
    g_delay_len => c_delay_len
  )
  PORT MAP (
    rst  => in_rst,
    clk  => clk,
    din  => in_dat,
    dout => out_async
  );
        
  u_areset : ENTITY work.common_areset
  GENERIC MAP (
    g_rst_level => '1',
    g_delay_len => c_delay_len
  )
  PORT MAP (
    in_rst    => in_rst,
    clk       => clk,
    out_rst   => out_areset
  );
  
END tb;
