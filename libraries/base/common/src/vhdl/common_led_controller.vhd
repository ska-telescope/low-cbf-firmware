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

LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE common_lib.common_pkg.ALL;

-- Purpose: Provide visual activity information via a LED.
-- Description:
--   ctrl_on = '0' : then led = ctrl_input, so completely driven by external control
--   ctrl_on = '1' : then led = '1' but pulses '0' for g_nof_ms each time that a ctrl_evt clk pulse occurs
-- Remark:
--   The p_state machine ensures that after g_nof_ms off the led also stays on
--   for at least g_nof_ms, to avoid that a too fast ctrl_evt rate would cause
--   the led too stay off. Therefore the maximum event rate that can be
--   signalled is 1/(2*g_nof_ms). If events occur faster then these can not be
--   visualized exactly anymore and will get lost.

ENTITY common_led_controller IS
  GENERIC (
    g_nof_ms      : NATURAL := 100         -- force LED off for g_nof_ms and then on for at least g_nof_ms
  );
  PORT (
    rst           : IN  STD_LOGIC;
    clk           : IN  STD_LOGIC;
    pulse_ms      : IN  STD_LOGIC := '0';  -- pulses every ms, used to time the ctrl_evt effect on the led
    -- led control
    ctrl_on       : IN  STD_LOGIC := '0';
    ctrl_evt      : IN  STD_LOGIC := '0';  -- when ctrl_on='1' then the led output is on and pulses off for g_nof_ms when a ctrl_evt='1' event pulse occurs
    ctrl_input    : IN  STD_LOGIC := '0';  -- when ctrl_on='0' then use ctrl_input to control the led output
    -- led output
    led           : OUT STD_LOGIC
  );
END common_led_controller;


ARCHITECTURE rtl OF common_led_controller IS

  TYPE t_state IS (s_idle, s_off, s_on);

  SIGNAL state          : t_state;
  SIGNAL nxt_state      : t_state;
  
  -- Register inputs locally at this input to ease timing closure in case there are multiple common_led_controller all using the same central source
  SIGNAL pulse_ms_reg   : STD_LOGIC;
  SIGNAL ctrl_input_reg : STD_LOGIC;
  
  SIGNAL cnt            : NATURAL RANGE 0 TO g_nof_ms;
  SIGNAL nxt_cnt        : NATURAL;
  
  SIGNAL nxt_led        : STD_LOGIC;
  
BEGIN

  p_clk : PROCESS(rst, clk)
  BEGIN
    IF rst='1' THEN
      pulse_ms_reg   <= '0';
      ctrl_input_reg <= '0';
      cnt            <= 0;
      state          <= s_idle;
      led            <= '0';
    ELSIF rising_edge(clk) THEN
      pulse_ms_reg   <= pulse_ms;
      ctrl_input_reg <= ctrl_input;
      cnt            <= nxt_cnt;
      state          <= nxt_state;
      led            <= nxt_led;
    END IF;
  END PROCESS;
  
  p_state : PROCESS(state, ctrl_on, ctrl_evt, ctrl_input_reg, pulse_ms_reg, cnt)
  BEGIN
    IF ctrl_on='0' THEN
      -- Default behaviour when ctrl_on = '0'
      nxt_cnt   <= 0;
      nxt_state <= s_idle;
      nxt_led   <= ctrl_input_reg;
    ELSE
      -- Pulse led off briefly on event when ctrl_on = '1'
      nxt_cnt   <= cnt;
      nxt_state <= state;
      nxt_led   <= '1';
      CASE state IS
        WHEN s_idle =>
          nxt_cnt <= 0;
          IF ctrl_evt='1' THEN
            nxt_state <= s_off;
          END IF;
        WHEN s_off =>
          nxt_led <= '0';
          IF pulse_ms_reg='1' THEN
            nxt_cnt <= cnt+1;
            IF cnt=g_nof_ms THEN
              nxt_cnt <= 0;
              nxt_state <= s_on;
            END IF;
          END IF;
        WHEN OTHERS =>  -- s_on
          IF pulse_ms_reg='1' THEN
            nxt_cnt <= cnt+1;
            IF cnt=g_nof_ms THEN
              nxt_cnt <= 0;
              nxt_state <= s_idle;
            END IF;
          END IF;
      END CASE;
    END IF;
  END PROCESS;
  
END rtl;
