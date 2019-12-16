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

LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE common_lib.common_pkg.ALL;

-- Purpose: Provide timing pulses for interval 1 us, 1 ms and 1 s

ENTITY common_pulser_us_ms_s IS
  GENERIC (
    g_pulse_us    : NATURAL := 125;          -- nof clk cycles to get us period
    g_pulse_ms    : NATURAL := 1000;         -- nof pulse_us pulses to get ms period
    g_pulse_s     : NATURAL := 1000          -- nof pulse_ms pulses to get s period
  );
  PORT (
    rst          : IN  STD_LOGIC;
    clk          : IN  STD_LOGIC;
    sync         : IN  STD_LOGIC := '0';
    pulse_us     : OUT STD_LOGIC;  -- pulses after every g_pulse_us                      clock cycles
    pulse_ms     : OUT STD_LOGIC;  -- pulses after every g_pulse_us*g_pulse_ms           clock cycles
    pulse_s      : OUT STD_LOGIC   -- pulses after every g_pulse_us*g_pulse_ms*g_pulse_s clock cycles
  );
END common_pulser_us_ms_s;


ARCHITECTURE str OF common_pulser_us_ms_s IS

  SIGNAL pulse_us_pp     : STD_LOGIC;  -- register to align with pulse_ms
  SIGNAL pulse_us_p      : STD_LOGIC;  -- register to align with pulse_s
  SIGNAL pulse_us_reg    : STD_LOGIC;  -- output register
  SIGNAL i_pulse_us      : STD_LOGIC;

  SIGNAL pulse_ms_p      : STD_LOGIC;  -- register to align with pulse_s
  SIGNAL pulse_ms_reg    : STD_LOGIC;  -- output register
  SIGNAL i_pulse_ms      : STD_LOGIC;
  
  SIGNAL pulse_s_reg     : STD_LOGIC;  -- output register
  SIGNAL i_pulse_s       : STD_LOGIC;
  
BEGIN

  -- register output pulses to ease timing closure
  pulse_us  <= '0' WHEN rst='1' ELSE i_pulse_us WHEN rising_edge(clk);
  pulse_ms  <= '0' WHEN rst='1' ELSE i_pulse_ms WHEN rising_edge(clk);
  pulse_s   <= '0' WHEN rst='1' ELSE i_pulse_s  WHEN rising_edge(clk);
  
  p_clk : PROCESS(clk)
  BEGIN
    IF rising_edge(clk) THEN
      pulse_us_p   <= pulse_us_pp;
      pulse_us_reg <= pulse_us_p;
      pulse_ms_reg <= pulse_ms_p;
      i_pulse_us   <= pulse_us_reg;
      i_pulse_ms   <= pulse_ms_reg;
      i_pulse_s    <= pulse_s_reg;
    END IF;
  END PROCESS;

  u_common_pulser_us : ENTITY common_lib.common_pulser
  GENERIC MAP (
    g_pulse_period => g_pulse_us,
    g_pulse_phase  => g_pulse_us-1
  )
  PORT MAP (
    rst            => rst,
    clk            => clk,
    clken          => '1',
    pulse_en       => '1',
    pulse_clr      => sync,
    pulse_out      => pulse_us_pp
  );
  
  u_common_pulser_ms : ENTITY common_lib.common_pulser
  GENERIC MAP (
    g_pulse_period => g_pulse_ms,
    g_pulse_phase  => g_pulse_ms-1
  )
  PORT MAP (
    rst            => rst,
    clk            => clk,
    clken          => '1',
    pulse_en       => pulse_us_pp,
    pulse_clr      => sync,
    pulse_out      => pulse_ms_p
  );
    
  u_common_pulser_s : ENTITY common_lib.common_pulser
  GENERIC MAP (
    g_pulse_period => g_pulse_s,
    g_pulse_phase  => g_pulse_s-1
  )
  PORT MAP (
    rst            => rst,
    clk            => clk,
    clken          => '1',
    pulse_en       => pulse_ms_p,
    pulse_clr      => sync,
    pulse_out      => pulse_s_reg
  );
  
END str;
