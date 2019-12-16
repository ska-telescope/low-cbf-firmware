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
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;

-- Purpose: Output a one cycle pulse every period
-- Description:
--   The pulse period can dynamically be set via the input pulse_period.
--   Default pulse_period = g_pulse_period, to also support static setting of
--   the pulse period. The pulse_clr can be used to synchronise the pulser.
--   The g_pulse_phase defines when the first pulse occurs after rst release:
--   . g_pulse_phase=0                : first pulse after g_pulse_period cycles
--   . g_pulse_phase=g_pulse_period   : first pulse after g_pulse_period cycles
--   . g_pulse_phase=g_pulse_period-1 : first pulse after              1 cycles
--   . g_pulse_phase=g_pulse_period-N : first pulse after              N cycles
ENTITY common_pulser IS
  GENERIC (
    g_pulse_period : NATURAL := 25000;  -- nof clk cycles to get pulse period
    g_pulse_phase  : NATURAL := 0
  );
  PORT (
    rst            : IN  STD_LOGIC;
    clk            : IN  STD_LOGIC;
    clken          : IN  STD_LOGIC := '1';  -- support running on clken freq
    pulse_period   : IN  STD_LOGIC_VECTOR(ceil_log2(g_pulse_period+1)-1 DOWNTO 0) := TO_UVEC(g_pulse_period, ceil_log2(g_pulse_period+1));
    pulse_en       : IN  STD_LOGIC := '1';  -- enable the pulse interval timer
    pulse_clr      : IN  STD_LOGIC := '0';  -- restart the pulse interval timer
    pulse_out      : OUT STD_LOGIC
  );
END common_pulser;


ARCHITECTURE rtl OF common_pulser IS

  CONSTANT c_pulse_period_w  : NATURAL := ceil_log2(g_pulse_period+1);
  
  -- Map g_pulse_phase = phs natural range to equivalent integer range of c_pulse_init that is used by g_init of common_counter to avoid truncation warning for conversion to slv
  -- For example for c_pulse_period_w = w = 3:
  --  0 1 2 3  4  5  6  7
  --  0 1 2 3 -4 -3 -2 -1  --> if p < 2**(w-1) then return phs else return phs-2**w
  CONSTANT c_pulse_init      : INTEGER := sel_a_b(g_pulse_phase<2**(c_pulse_period_w-1), g_pulse_phase, g_pulse_phase-2**c_pulse_period_w);
  
  SIGNAL cnt           : STD_LOGIC_VECTOR(c_pulse_period_w-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL cnt_en        : STD_LOGIC;
  SIGNAL cnt_clr       : STD_LOGIC;
  SIGNAL cnt_period    : STD_LOGIC;
  
BEGIN

  p_clk : PROCESS(clk, rst)
  BEGIN
    IF rst='1' THEN
      pulse_out <= '0';
    ELSIF rising_edge(clk) THEN
      IF clken='1' THEN
        pulse_out <= cnt_period;
      END IF;
    END IF;
  END PROCESS;

  -- pulse period counter
  cnt_period <= '1' WHEN pulse_en='1' AND UNSIGNED(cnt)=UNSIGNED(pulse_period)-1 ELSE '0';  
  
  cnt_en     <= pulse_en;
  cnt_clr    <= pulse_clr OR cnt_period;
  
  u_cnt : ENTITY common_lib.common_counter
  GENERIC MAP (
    g_init      => c_pulse_init,
    g_width     => c_pulse_period_w
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    clken   => clken,
    cnt_clr => cnt_clr,
    cnt_en  => cnt_en,
    count   => cnt
  );
  
END rtl;
