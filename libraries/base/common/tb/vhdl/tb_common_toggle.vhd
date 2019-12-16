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


-- Purpose: Test bench for common_toggle.vhd
-- Usage:
-- > as 10
-- > run -all
-- Observe the out_toggle during the different stimuli indicated by tb_state.

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE work.common_pkg.ALL;
USE work.tb_common_pkg.ALL;

ENTITY tb_common_toggle IS
END tb_common_toggle;

ARCHITECTURE tb OF tb_common_toggle IS

  CONSTANT clk_period    : TIME := 10 ns;
  CONSTANT c_nof_toggles : NATURAL := 5;

  SIGNAL tb_end     : STD_LOGIC := '0';
  SIGNAL rst        : STD_LOGIC;
  SIGNAL clk        : STD_LOGIC := '0';
  SIGNAL tb_state   : NATURAL := 0;
  SIGNAL in_dat     : STD_LOGIC;
  SIGNAL in_val     : STD_LOGIC;
  SIGNAL out_toggle : STD_LOGIC;

BEGIN

  clk  <= NOT clk OR tb_end AFTER clk_period/2;
  rst  <= '1', '0' AFTER 7 * clk_period;
    
  p_in_stimuli : PROCESS
  BEGIN
    tb_state <= 0;
    in_dat <= '0';
    in_val <= '0';
    proc_common_wait_until_low(clk, rst);
    proc_common_wait_some_cycles(clk, 10);
    
    -- 1) Toggle in_at while in_val is active
    tb_state <= 1;
    in_val <= '1';
    in_dat <= '0';
    FOR I IN 0 TO c_nof_toggles-1 LOOP
      proc_common_wait_some_cycles(clk, 10);
      in_dat <= '1';
      proc_common_wait_some_cycles(clk, 10);
      in_dat <= '0';
    END LOOP;
    
    -- 2) Toggle in_at while in_val is inactive should be ingored
    tb_state <= 2;
    in_val <= '0';
    in_dat <= '0';
    FOR I IN 0 TO c_nof_toggles-1 LOOP
      proc_common_wait_some_cycles(clk, 10);
      in_dat <= '1';
      proc_common_wait_some_cycles(clk, 10);
      in_dat <= '0';
    END LOOP;
    
    -- Toggle in_at while in_val is active
    tb_state <= 3;
    in_val <= '1';
    in_dat <= '0';
    FOR I IN 0 TO c_nof_toggles-1 LOOP
      proc_common_wait_some_cycles(clk, 10);
      in_dat <= '1';
      proc_common_wait_some_cycles(clk, 10);
      in_dat <= '0';
    END LOOP;
    
    tb_state <= 9;
    proc_common_wait_some_cycles(clk, 100);
    tb_end <= '1';
    WAIT;
  END PROCESS;

  u_toggle : ENTITY work.common_toggle
  GENERIC MAP (
    g_evt_type   => "RISING",
    g_rst_level  => '0'
  )
  PORT MAP (
    rst         => rst,
    clk         => clk,
    clken       => '1',
    in_dat      => in_dat,
    in_val      => in_val,
    out_dat     => out_toggle
  );
  
END tb;
