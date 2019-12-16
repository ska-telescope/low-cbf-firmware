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

-- Purpose: Test bench for common_acapture
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

ENTITY tb_common_acapture IS
END tb_common_acapture;


ARCHITECTURE tb OF tb_common_acapture IS

  CONSTANT in_clk_period    : TIME := 10 ns;
  CONSTANT out_clk_period   : TIME := 7 ns;
  
  CONSTANT c_delay_len  : NATURAL := 3;

  SIGNAL dbg_state                : NATURAL;
  
  SIGNAL tb_end                   : STD_LOGIC := '0';
  SIGNAL in_rst                   : STD_LOGIC;
  SIGNAL in_clk                   : STD_LOGIC := '0';
  SIGNAL out_clk                  : STD_LOGIC := '0';
  
  SIGNAL in_dat                   : STD_LOGIC;
  SIGNAL out_cap                  : STD_LOGIC;

BEGIN

  in_clk  <= NOT in_clk  OR tb_end AFTER in_clk_period/2;
  out_clk <= NOT out_clk OR tb_end AFTER out_clk_period/2;
    
  p_in_stimuli : PROCESS
  BEGIN
    dbg_state <= 0;
    in_rst <= '1';
    in_dat <= '0';
    proc_common_wait_some_cycles(in_clk, 5);
    in_rst <= '0';
    FOR I IN 0 TO 4 LOOP
      proc_common_wait_some_cycles(in_clk, 9);
      in_dat <= '1';
      proc_common_wait_some_cycles(in_clk, 1);
      in_dat <= '0';
    END LOOP;
    
    dbg_state <= 9;
    proc_common_wait_some_cycles(in_clk, 10);
    tb_end <= '1';
    WAIT;
  END PROCESS;

  u_acapture : ENTITY work.common_acapture
  GENERIC MAP (
    g_rst_level => '0'
  )
  PORT MAP (
    in_rst  => in_rst,
    in_clk  => in_clk,
    in_dat  => in_dat,
    out_clk => out_clk,
    out_cap => out_cap
  );
  
END tb;
