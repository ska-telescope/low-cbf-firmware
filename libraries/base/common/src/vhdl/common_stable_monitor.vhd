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
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;

-- Purpose: Monitor whether r_in did not go low since the previous ack
-- Description:
--   When r_in = '0' then r_stable = '0'. The r_stable is '1' if r_in = '1' and
--   remains '1'. The r_stable measurement interval restarts after an pulse on
--   r_stable_ack. Hence by pulsing r_stable_ack the user can start a new fresh
--   interval for monitoring r_stable.
-- Remarks:

ENTITY common_stable_monitor IS
  PORT (
    rst          : IN  STD_LOGIC;
    clk          : IN  STD_LOGIC;
    -- MM
    r_in         : IN  STD_LOGIC;
    r_stable     : OUT STD_LOGIC;
    r_stable_ack : IN  STD_LOGIC
  );
END common_stable_monitor;


ARCHITECTURE rtl OF common_stable_monitor IS

  SIGNAL nxt_r_stable  : STD_LOGIC;
  SIGNAL r_evt         : STD_LOGIC;
  SIGNAL r_evt_occured : STD_LOGIC;
  
BEGIN

  p_clk: PROCESS(clk, rst)
  BEGIN
    IF rst='1' THEN
      r_stable <= '0';
    ELSIF rising_edge(clk) THEN
      r_stable <= nxt_r_stable;
    END IF;
  END PROCESS;

  nxt_r_stable <= r_in AND NOT r_evt_occured;
  
  u_r_evt : ENTITY work.common_evt
  GENERIC MAP (
    g_evt_type => "BOTH",
    g_out_reg  => FALSE
  )
  PORT MAP (
    rst      => rst,
    clk      => clk,
    in_sig   => r_in,
    out_evt  => r_evt
  );
  
  u_r_evt_occured : ENTITY work.common_switch
  GENERIC MAP (
    g_rst_level    => '0',
    g_priority_lo  => FALSE,
    g_or_high      => TRUE,
    g_and_low      => FALSE
  )
  PORT MAP (
    rst         => rst,
    clk         => clk,
    switch_high => r_evt,
    switch_low  => r_stable_ack,
    out_level   => r_evt_occured
  );  
    
END rtl;
