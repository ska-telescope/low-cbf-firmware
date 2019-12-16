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
USE IEEE.std_logic_1164.all;
USE work.common_pkg.ALL;


ENTITY common_counter IS
  GENERIC (
    g_latency   : NATURAL := 1;  -- default 1 for registered count output, use 0 for immediate combinatorial count output
    g_init      : INTEGER := 0;
    g_width     : NATURAL := 32;
    g_max       : NATURAL := 0;  -- default 0 to disable the g_max setting. 
    g_step_size : INTEGER := 1   -- counting in steps of g_step_size, can be + or -
  );
  PORT (
    rst     : IN  STD_LOGIC := '0';    -- either use asynchronous rst or synchronous cnt_clr
    clk     : IN  STD_LOGIC;
    clken   : IN  STD_LOGIC := '1';
    cnt_clr : IN  STD_LOGIC := '0';    -- synchronous cnt_clr is only interpreted when clken is active
    cnt_ld  : IN  STD_LOGIC := '0';    -- cnt_ld loads the output count with the input load value, independent of cnt_en
    cnt_en  : IN  STD_LOGIC := '1';
    cnt_max : IN  STD_LOGIC_VECTOR(g_width-1 DOWNTO 0) := TO_UVEC(g_max,  g_width);     
    load    : IN  STD_LOGIC_VECTOR(g_width-1 DOWNTO 0) := TO_SVEC(g_init, g_width);
    count   : OUT STD_LOGIC_VECTOR(g_width-1 DOWNTO 0)
  );
END common_counter;


ARCHITECTURE rtl OF common_counter IS
   
  CONSTANT zeros    : STD_LOGIC_VECTOR(count'RANGE) := (OTHERS => '0');           -- used to check if cnt_max is zero
  SIGNAL reg_count  : STD_LOGIC_VECTOR(count'RANGE) := TO_SVEC(g_init, g_width);  -- in case rst is not used
  SIGNAL nxt_count  : STD_LOGIC_VECTOR(count'RANGE) := TO_SVEC(g_init, g_width);  -- to avoid Warning: NUMERIC_STD.">=": metavalue detected, returning FALSE, when using unsigned()
  SIGNAL comb_count : STD_LOGIC_VECTOR(count'RANGE) := TO_SVEC(g_init, g_width);  -- to avoid Warning: NUMERIC_STD.">=": metavalue detected, returning FALSE, when using unsigned()

BEGIN

  comb_count <= nxt_count;
  
  count <= comb_count WHEN g_latency=0 ELSE reg_count;

  ASSERT g_step_size /= 0 REPORT "common_counter: g_step_size must be /= 0" SEVERITY FAILURE;
  
  p_clk : PROCESS (rst, clk)
  BEGIN
    IF rst = '1' THEN
      reg_count <= TO_SVEC(g_init, g_width);
    ELSIF rising_edge(clk) THEN
      IF clken='1' THEN
        reg_count <= nxt_count;
      END IF;
    END IF;
  END PROCESS;
  
  p_count : PROCESS(reg_count, cnt_clr, cnt_en, cnt_ld, load, cnt_max)
  BEGIN
    nxt_count <= reg_count;
    IF cnt_clr='1' OR (reg_count=cnt_max AND cnt_max /= zeros) THEN
      nxt_count <= (OTHERS => '0');
    ELSIF cnt_ld='1' THEN
      nxt_count <= load;
    ELSIF cnt_en='1' THEN
      nxt_count <= INCR_UVEC(reg_count, g_step_size);
    END IF;
  END PROCESS;
  
END rtl;
