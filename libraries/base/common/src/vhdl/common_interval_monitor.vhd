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

LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;

-- Purpose: Monitor the nof valid clock cycles between two in_evt pulses
-- Description:
--   The in_evt pulses define the interval. Leave in_val not connected to count
--   every clock cycle.
-- Remarks:

ENTITY common_interval_monitor IS
  GENERIC (
    g_interval_cnt_w  : NATURAL := 20   -- wide enough to fit somewhat more than maximum nof valid clock cycles per interval
  );
  PORT (
    rst           : IN  STD_LOGIC;
    clk           : IN  STD_LOGIC;
    -- ST
    in_val        : IN  STD_LOGIC := '1';
    in_evt        : IN  STD_LOGIC;
    -- MM
    interval_cnt  : OUT STD_LOGIC_VECTOR(g_interval_cnt_w-1 DOWNTO 0)
  );
END common_interval_monitor;


ARCHITECTURE rtl OF common_interval_monitor IS

  SIGNAL clk_cnt          : STD_LOGIC_VECTOR(interval_cnt'RANGE);
  SIGNAL nxt_clk_cnt      : STD_LOGIC_VECTOR(interval_cnt'RANGE);
  SIGNAL i_interval_cnt   : STD_LOGIC_VECTOR(interval_cnt'RANGE);
  SIGNAL nxt_interval_cnt : STD_LOGIC_VECTOR(interval_cnt'RANGE);
  
BEGIN

  interval_cnt <= i_interval_cnt;

  p_clk: PROCESS(clk, rst)
  BEGIN
    IF rst='1' THEN
      clk_cnt        <= (OTHERS=>'1');
      i_interval_cnt <= (OTHERS=>'1');
    ELSIF rising_edge(clk) THEN
      clk_cnt        <= nxt_clk_cnt;
      i_interval_cnt <= nxt_interval_cnt;
    END IF;
  END PROCESS;

  p_counter : PROCESS(clk_cnt, i_interval_cnt, in_evt, in_val)
  BEGIN
    nxt_clk_cnt      <= clk_cnt;
    nxt_interval_cnt <= i_interval_cnt;
    
    IF in_evt='1' THEN
      -- If there is an in_evt pulse, then capture the clk_cnt into interval_cnt and restart clk_cnt
      nxt_clk_cnt      <= (OTHERS=>'0');
      nxt_interval_cnt <= INCR_UVEC(clk_cnt, 1);
    ELSIF SIGNED(clk_cnt)=-1 THEN
      -- If there occur no in_evt pulses, then clk_cnt will eventually stop at maximum (= -1)
      nxt_clk_cnt      <= (OTHERS=>'1');
      nxt_interval_cnt <= (OTHERS=>'1');
    ELSIF in_val='1' THEN
      -- Increment for valid clk cycles
      nxt_clk_cnt <= INCR_UVEC(clk_cnt, 1);
    END IF;
  END PROCESS;
  
END rtl;
