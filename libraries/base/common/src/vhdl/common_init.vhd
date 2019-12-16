-------------------------------------------------------------------------------
--
-- Copyright (C) 2010
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
USE IEEE.std_logic_1164.ALL;

-- Purpose:
--
-- 1) The hold can be used as a synchronous reset for the rest of the logic.
--    The difference with common_areset is that common_init uses a counter
--    whereas common_areset uses a shift register to set the hold time for the
--    hold. Hence with common_init it is possible to define very long reset
--    hold times with minimal logic.
-- 2) The init can be used to ensure that all subsequent logic starts
--    at the same clock cycle. Due to no constraint on rst timing, the rst
--    signal could be released 1 or even 2 cycles earlier for one register in
--    the FPGA than for another register. The init pulse can be used to start
--    the init action, when rst has been released for all registers in the
--    whole FPGA for sure.
--
-- Remarks:
-- .  In LOFAR only init was used

ENTITY common_init IS
  GENERIC (
    g_latency_w : NATURAL := 4  -- >= 1
  );
  PORT (
    rst    : IN  STD_LOGIC;
    clk    : IN  STD_LOGIC;
    hold   : OUT STD_LOGIC;
    init   : OUT STD_LOGIC
  );
END;


ARCHITECTURE rtl OF common_init IS
  
  SIGNAL cnt           : STD_LOGIC_VECTOR(g_latency_w DOWNTO 0);   -- use cnt(g_latency_w) to stop the counter
  SIGNAL cnt_en        : STD_LOGIC;
  SIGNAL prev_cnt_en   : STD_LOGIC;
  
  -- add extra output register stage to ease timing, because these signals will typically have a large fan out
  SIGNAL hold_reg      : STD_LOGIC;
  SIGNAL init_reg      : STD_LOGIC;
  SIGNAL nxt_init_reg  : STD_LOGIC;
  
BEGIN


  p_clk : PROCESS (rst, clk)
  BEGIN
    IF rst='1' THEN
      prev_cnt_en   <= '1';
      hold          <= '1';
      hold_reg      <= '1';
      init          <= '0';
      init_reg      <= '0';
    ELSIF RISING_EDGE(clk) THEN
      prev_cnt_en   <= cnt_en;
      hold_reg      <= cnt_en;
      hold          <= hold_reg;
      init_reg      <= nxt_init_reg;
      init          <= init_reg;
    END IF;
  END PROCESS;
  
  cnt_en <= NOT cnt(cnt'HIGH);
  
  nxt_init_reg <= '1' WHEN cnt_en='0' AND prev_cnt_en='1' ELSE '0';
  
  u_counter : ENTITY common_lib.common_counter
  GENERIC MAP (
    g_width     => g_latency_w+1
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    cnt_clr => '0',
    cnt_en  => cnt_en,
    count   => cnt
  );
  
END rtl;
