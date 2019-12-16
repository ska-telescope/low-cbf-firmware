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

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

-- Purpose: Extend the active high time of a pulse
-- Description:
--   Extend an input pulse p_in to an output pulse ep_out that is delayed by 1
--   clock cycle and lasts for 2**g_extend_w number of clock cycles longer
--   after that p_in went low.

ENTITY common_pulse_extend IS
  GENERIC (
    g_rst_level    : STD_LOGIC := '0';          -- Assign this output on reste being applied
    g_p_in_level   : STD_LOGIC := '1';          -- Activate the pulse extender on this level
    g_ep_out_level : STD_LOGIC := '1';          -- Output this level when the pulse extender is running
    g_extend_w     : NATURAL := 1
  );
  PORT (
    rst     : IN  STD_LOGIC := '0';
    clk     : IN  STD_LOGIC;
    clken   : IN  STD_LOGIC := '1';
    p_in    : IN  STD_LOGIC;
    ep_out  : OUT STD_LOGIC
  );
END common_pulse_extend;


ARCHITECTURE rtl OF common_pulse_extend IS

  SIGNAL cnt        : STD_LOGIC_VECTOR(g_extend_w-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL nxt_cnt    : STD_LOGIC_VECTOR(cnt'RANGE);
  SIGNAL cnt_is_0   : STD_LOGIC;
  SIGNAL i_ep_out   : STD_LOGIC := g_rst_level;
  SIGNAL nxt_ep_out : STD_LOGIC;

BEGIN

  -- Extend ep_out active for 2**g_extend_w cycles longer than p_in active
  -- Inactive p_in for less than 2**g_extend_w cycles will get lost in ep_out

  ep_out <= i_ep_out;

  registers_proc : PROCESS (clk, rst)
  BEGIN
    IF rst = '1' THEN
      cnt      <= (OTHERS => '0');
      i_ep_out <= g_rst_level;
    ELSIF rising_edge(clk) THEN
      IF clken='1' THEN
        cnt      <= nxt_cnt;
        i_ep_out <= nxt_ep_out;
      END IF;
    END IF;
  END PROCESS;

  nxt_ep_out <= g_ep_out_level WHEN p_in=g_p_in_level OR cnt_is_0='0' ELSE NOT g_ep_out_level;

  cnt_is_0 <= '1' WHEN UNSIGNED(cnt)=0 ELSE '0';

  p_cnt : PROCESS(p_in, cnt_is_0, cnt)
  BEGIN
    nxt_cnt <= (OTHERS => '0');
    IF p_in=g_p_in_level THEN
      nxt_cnt <= STD_LOGIC_VECTOR(TO_UNSIGNED(1,cnt'LENGTH));
    ELSIF cnt_is_0='0' THEN
      nxt_cnt <= STD_LOGIC_VECTOR(UNSIGNED(cnt) + 1);
    END IF;
  END PROCESS;

END ARCHITECTURE;

