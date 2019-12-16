-------------------------------------------------------------------------------
--
-- Copyright (C) 2015
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

-- Purpose: Test bench for common_led_controller
-- Description:
--   When ctrl_on='0' then toggle_ms drives the LED
--   When ctrl+on='1' then the LED is on and it pulses off when a ctrl_evt occurs
--                    too fast ctrl_evt get lost in a single pulse off.
--   The tb is self-stopping, but not self-checking. The verification needs to be
--   done manually in the wave window.
-- Usage:
--   > as 3
--   > run -a

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE work.common_pkg.ALL;

ENTITY tb_common_led_controller IS
END tb_common_led_controller;

ARCHITECTURE tb OF tb_common_led_controller IS

  CONSTANT c_pulse_us      : NATURAL := 10;
  CONSTANT c_1000          : NATURAL := 10;  -- use eg 10 instead of 1000 to speed up simulation
  CONSTANT c_led_nof_ms    : NATURAL := 3;
  CONSTANT c_on_nof_ms     : NATURAL := 50;
  CONSTANT c_off_nof_ms    : NATURAL := 100;
  CONSTANT c_nof_repeat    : NATURAL := 2;
  
  CONSTANT clk_period   : TIME := 1000 ns / c_pulse_us;
  
  SIGNAL tb_end         : STD_LOGIC := '0';
  SIGNAL rst            : STD_LOGIC;
  SIGNAL clk            : STD_LOGIC := '0';  
  SIGNAL pulse_ms       : STD_LOGIC;
  SIGNAL toggle_ms      : STD_LOGIC;
  
  SIGNAL ctrl_on        : STD_LOGIC;
  SIGNAL ctrl_evt       : STD_LOGIC;
  SIGNAL dbg_evt        : NATURAL;
  
  SIGNAL LED            : STD_LOGIC;
  
BEGIN
  
  clk <= NOT clk OR tb_end AFTER clk_period/2;
  rst <= '1', '0' AFTER clk_period*7;
  
  p_stimuli : PROCESS
    VARIABLE v_evt : POSITIVE;
  BEGIN
    FOR R IN 0 TO c_nof_repeat-1 LOOP
      -- ctrl_on='0' => ctrl_input = toggle_ms drives the LED
      ctrl_on  <= '0';
      ctrl_evt <= '0';
      FOR I IN 0 TO c_on_nof_ms-1 LOOP
        WAIT UNTIL pulse_ms='1';
      END LOOP;
      
      -- ctrl_on='1' => LED on and ctrl_evt pulses the LED off
      ctrl_on  <= '1';
      ctrl_evt <= '0';
      FOR I IN 0 TO c_on_nof_ms-1 LOOP
        WAIT UNTIL pulse_ms='1';
      END LOOP;
      
      -- ctrl_on='1' => LED on and ctrl_evt pulses the LED off
      v_evt := 1;
      FOR I IN 0 TO c_off_nof_ms-1 LOOP
        IF I=v_evt THEN
          ctrl_evt <= '1';
          WAIT UNTIL rising_edge(clk);
          ctrl_evt <= '0';
          v_evt := v_evt+I;
        END IF;
        dbg_evt <= v_evt;
        WAIT UNTIL pulse_ms='1';
      END LOOP;
    END LOOP;
      
    tb_end <= '1';
    WAIT FOR 1 us;
    WAIT;
  END PROCESS;
  
  u_common_pulser_us_ms_s : ENTITY work.common_pulser_us_ms_s
  GENERIC MAP (
    g_pulse_us   => c_pulse_us,  -- nof clk cycles to get us period
    g_pulse_ms   => c_1000,      -- nof pulse_us pulses to get ms period
    g_pulse_s    => c_1000       -- nof pulse_ms pulses to get s period
  )
  PORT MAP (
    rst          => rst,
    clk          => clk,
    pulse_ms     => pulse_ms     -- pulses after every g_pulse_us*g_pulse_ms clock cycles
  );
  
  u_common_toggle_ms : ENTITY work.common_toggle
  PORT MAP (
    rst         => rst,
    clk         => clk,
    in_dat      => pulse_ms,
    out_dat     => toggle_ms
  );

  
  u_common_led_controller : ENTITY work.common_led_controller
  GENERIC MAP (
    g_nof_ms      => c_led_nof_ms
  )
  PORT MAP (
    rst               => rst,
    clk               => clk,
    pulse_ms          => pulse_ms,
    -- led control
    ctrl_on           => ctrl_on,
    ctrl_evt          => ctrl_evt,
    ctrl_input        => toggle_ms,
    -- led output
    led               => LED
  );
  
END tb;
