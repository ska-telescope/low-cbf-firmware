-------------------------------------------------------------------------------
--
-- Copyright (C) 2010
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

-- Purpose: Test bench for common_pulser_us_ms_s
-- Description:
--   The tb checks that the pulse_us occurs aligned when pulse_ms is active
--   and when pulse_s is active.
--   The sync is used to restart the us, ms, s intervals.
-- Usage:
--   > as 3
--   > run -a

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;

ENTITY tb_common_pulser_us_ms_s IS
END tb_common_pulser_us_ms_s;

ARCHITECTURE tb OF tb_common_pulser_us_ms_s IS

  CONSTANT c_pulse_us   : NATURAL := 10;
  CONSTANT c_1000       : NATURAL := 10;  -- use eg 10 instead of 1000 to speed up simulation
  
  CONSTANT clk_period   : TIME := 1000 ns / c_pulse_us;
  
  SIGNAL tb_end         : STD_LOGIC := '0';
  SIGNAL rst            : STD_LOGIC;
  SIGNAL clk            : STD_LOGIC := '0';
  SIGNAL sync           : STD_LOGIC := '0';
  
  SIGNAL pulse_us       : STD_LOGIC;
  SIGNAL pulse_ms       : STD_LOGIC;
  SIGNAL pulse_s        : STD_LOGIC;
  
BEGIN
  
  clk <= NOT clk OR tb_end AFTER clk_period/2;
  rst <= '1', '0' AFTER clk_period*7;
  
  p_sync : PROCESS
  BEGIN
    sync <= '0';
    WAIT UNTIL pulse_s='1';
    WAIT UNTIL pulse_s='1';
    WAIT UNTIL pulse_s='1';
    WAIT FOR (c_1000 * c_1000 * 1 us / 4);
    WAIT UNTIL rising_edge(clk);
    sync <= '1';
    WAIT UNTIL rising_edge(clk);
    sync <= '0';
    WAIT UNTIL rising_edge(clk);
    WAIT UNTIL pulse_s='1';
    WAIT UNTIL pulse_s='1';
    WAIT UNTIL pulse_s='1';
    WAIT UNTIL pulse_s='1';
    WAIT UNTIL pulse_s='1';
    WAIT UNTIL pulse_s='1';
    WAIT UNTIL pulse_s='1';
    WAIT UNTIL pulse_s='1';
    tb_end <= '1';
    WAIT FOR (c_1000 * c_1000 * 1 us);
    WAIT;
  END PROCESS;
  
  p_verify: PROCESS(clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF pulse_s ='1' THEN ASSERT pulse_ms='1' AND pulse_us='1' REPORT "Error: pulse_us, ms, s misaligned" SEVERITY ERROR; END IF;
      IF pulse_ms='1' THEN ASSERT                  pulse_us='1' REPORT "Error: pulse_ms, s misaligned"     SEVERITY ERROR; END IF;
    END IF;
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
    sync         => sync,
    pulse_us     => pulse_us,  -- pulses after every g_pulse_us                      clock cycles
    pulse_ms     => pulse_ms,  -- pulses after every g_pulse_us*g_pulse_ms           clock cycles
    pulse_s      => pulse_s    -- pulses after every g_pulse_us*g_pulse_ms*g_pulse_s clock cycles
  );
  
END tb;
