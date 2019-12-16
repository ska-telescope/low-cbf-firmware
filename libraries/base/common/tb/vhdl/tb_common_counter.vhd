-------------------------------------------------------------------------------
--
-- Copyright (C) 2011
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
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;

ENTITY tb_common_counter IS
END tb_common_counter;

ARCHITECTURE tb OF tb_common_counter IS

  CONSTANT clk_period   : TIME := 10 ns;
  
  CONSTANT c_cnt_init   : NATURAL := 3;
  CONSTANT c_cnt_w      : NATURAL := 5;

  SIGNAL rst      : STD_LOGIC;
  SIGNAL clk      : STD_LOGIC := '0';
  
  SIGNAL cnt_clr  : STD_LOGIC := '0';    -- synchronous cnt_clr is only interpreted when clken is active
  SIGNAL cnt_ld   : STD_LOGIC := '0';    -- cnt_ld loads the output count with the input load value, independent of cnt_en
  SIGNAL cnt_en   : STD_LOGIC := '1';
  SIGNAL load     : STD_LOGIC_VECTOR(c_cnt_w-1 DOWNTO 0) := TO_UVEC(c_cnt_init, c_cnt_w);
  SIGNAL count    : STD_LOGIC_VECTOR(c_cnt_w-1 DOWNTO 0);
  SIGNAL cnt_max  : STD_LOGIC_VECTOR(c_cnt_w-1 DOWNTO 0);

BEGIN

  clk <= NOT clk AFTER clk_period/2;
  rst <= '1', '0' AFTER clk_period*3;
  
  -- run 1 us
  p_in_stimuli : PROCESS
  BEGIN
    cnt_clr <= '0';
    cnt_ld  <= '0';
    cnt_en  <= '0';
    cnt_max <= (OTHERS => '0');
    WAIT UNTIL rst = '0';
    WAIT UNTIL rising_edge(clk);
    
    -- Start counting
    cnt_en  <= '1';
    FOR I IN 0 TO 9 LOOP
      WAIT UNTIL rising_edge(clk);
    END LOOP;
    
    -- Reload counter
    cnt_ld  <= '1';
    WAIT UNTIL rising_edge(clk);
    cnt_ld  <= '0';
    FOR I IN 0 TO 9 LOOP
      WAIT UNTIL rising_edge(clk);
    END LOOP;
    
    -- briefly stop counting
    cnt_en  <= '0';
    WAIT UNTIL rising_edge(clk);
    -- countine counting    
    cnt_en  <= '1';
    FOR I IN 0 TO 9 LOOP
      WAIT UNTIL rising_edge(clk);
    END LOOP;

    -- set the cnt_max
    cnt_max <= TO_SVEC(2**(c_cnt_w-1), c_cnt_w);    
    
    WAIT;
  END PROCESS;

  -- device under test
  u_dut : ENTITY work.common_counter
  GENERIC MAP (
    g_init      => c_cnt_init,
    g_width     => c_cnt_w,
    g_step_size => 1
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    cnt_clr => cnt_clr,
    cnt_ld  => cnt_ld,
    cnt_en  => cnt_en,
    cnt_max => cnt_max,
    load    => load,
    count   => count
  );
      
END tb;


