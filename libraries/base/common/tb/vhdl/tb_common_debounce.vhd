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

-- Purpose : Test bench for common_debounce (all g_type's)
-- Description:
--   The tb is not self checking. Manually observe the wave window and check
--   the q_out during and after reset and compare g_high and q_low with q_both:
--
--   . q_both changes level only when d_in is stable at the other level
--   . q_high goes high with q_both and low  immediately with d_in
--   . q_low  goes low  with q_both and high immediately with d_in
--
--   Therefore:
--
--   . A one cycle level change "1110111" only affects q_high
--   . A one cycle level change "0001000" only affects q_low
--
-- Usage:
--   > as 5
--   > run -a

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE work.common_pkg.ALL;

ENTITY tb_common_debounce IS
END tb_common_debounce;

ARCHITECTURE tb OF tb_common_debounce IS
  
  CONSTANT clk_period   : TIME := 10 ns;
  
  CONSTANT c_rst_level_both  : STD_LOGIC := '0';  -- choose any reset level, because both levels are equivalent
  CONSTANT c_rst_level_high  : STD_LOGIC := '0';  -- choose '0' = not '1' for q_high reset level
  CONSTANT c_rst_level_low   : STD_LOGIC := '1';  -- choose '1' = not '0' for q_low reset level
  
  --CONSTANT d_in_level : STD_LOGIC := '1'; 
  CONSTANT d_in_level : STD_LOGIC := '0'; 
  
  CONSTANT c_latency    : NATURAL := 16;
  CONSTANT c_short      : NATURAL :=    c_latency/2;
  CONSTANT c_long       : NATURAL := 10*c_latency;

  SIGNAL tb_end    : STD_LOGIC := '0';
  SIGNAL rst       : STD_LOGIC := '1';
  SIGNAL clk       : STD_LOGIC := '0';
  SIGNAL d_in      : STD_LOGIC;
  SIGNAL q_high    : STD_LOGIC;
  SIGNAL q_both    : STD_LOGIC;
  SIGNAL q_low     : STD_LOGIC;

BEGIN

  -- run 20 us
  
  clk <= NOT clk OR tb_end AFTER clk_period/2;
  rst <= '1', '0' AFTER clk_period*c_long;
  
  p_in_stimuli : PROCESS
  BEGIN
    d_in  <= NOT d_in_level;
    FOR I IN 0 TO c_long  LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    FOR I IN 0 TO c_long  LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    
    IF d_in_level='1' THEN
      d_in  <= '1';
      FOR I IN 0 TO c_long  LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    END IF;
    
    -- Change 1 --> 0
    d_in  <= '0';
    FOR I IN 0 TO c_short LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    d_in  <= '1';
    FOR I IN 0 TO c_short LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    d_in  <= '0';
    FOR I IN 0 TO c_short LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    d_in  <= '1';
    FOR I IN 0 TO c_short LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    d_in  <= '0';
    FOR I IN 0 TO c_short LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    d_in  <= '1';
    FOR I IN 0 TO c_short LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    d_in  <= '0';
    -- Stable 0
    FOR I IN 0 TO c_long  LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    
    -- Change 0 --> 1
    d_in  <= '1';
    FOR I IN 0 TO c_short LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    d_in  <= '0';
    FOR I IN 0 TO c_short LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    d_in  <= '1';
    FOR I IN 0 TO c_short LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    d_in  <= '0';
    FOR I IN 0 TO c_short LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    d_in  <= '1';
    FOR I IN 0 TO c_short LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    d_in  <= '0';
    FOR I IN 0 TO c_short LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    d_in  <= '1';
    -- Stable 1
    FOR I IN 0 TO c_long  LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    
    -- No change 1 --> 0, too short to notice
    FOR I IN 0 TO c_long  LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    d_in  <= '0';
    FOR I IN 0 TO c_short LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    d_in  <= '1';
    FOR I IN 0 TO c_long  LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    FOR I IN 0 TO c_long  LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    
    -- Change 1 --> 0
    d_in  <= '0';
    FOR I IN 0 TO c_short LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    d_in  <= '1';
    FOR I IN 0 TO c_short LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    d_in  <= '0';
    FOR I IN 0 TO c_short LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    d_in  <= '1';
    FOR I IN 0 TO c_short LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    d_in  <= '0';
    FOR I IN 0 TO c_short LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    d_in  <= '1';
    FOR I IN 0 TO c_short LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    d_in  <= '0';
    -- Stable 0
    FOR I IN 0 TO c_long  LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    FOR I IN 0 TO c_long  LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    
    -- Change 0 --> 1
    d_in  <= '1';
    FOR I IN 0 TO c_long  LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    FOR I IN 0 TO c_long  LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    
    -- One cyle 1 --> 0 --> 1
    d_in  <= '0';
    WAIT UNTIL rising_edge(clk);
    d_in  <= '1';
    FOR I IN 0 TO c_long  LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    FOR I IN 0 TO c_long  LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    -- Change 1 --> 0
    d_in  <= '0';
    FOR I IN 0 TO c_long LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    -- One cyle 0 --> 1 --> 0
    d_in  <= '1';
    WAIT UNTIL rising_edge(clk);
    d_in  <= '0';
    FOR I IN 0 TO c_long  LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
    FOR I IN 0 TO c_long  LOOP WAIT UNTIL rising_edge(clk);  END LOOP;
        
    tb_end <= '1';
    WAIT;
  END PROCESS;
  
  u_debounce_both : ENTITY work.common_debounce
  GENERIC MAP (
    g_delay_len  => c_meta_delay_len,
    g_latency    => c_latency,
    g_init_level => c_rst_level_both
  )
  PORT MAP (
    rst   => rst,
    clk   => clk,
    clken => '1',
    d_in  => d_in,
    q_out => q_both
  );
  
  u_debounce_high : ENTITY work.common_debounce
  GENERIC MAP (
    g_type       => "HIGH",
    g_delay_len  => c_meta_delay_len,
    g_latency    => c_latency,
    g_init_level => c_rst_level_high
  )
  PORT MAP (
    rst   => rst,
    clk   => clk,
    clken => '1',
    d_in  => d_in,
    q_out => q_high
  );

  u_debounce_low : ENTITY work.common_debounce
  GENERIC MAP (
    g_type       => "LOW",
    g_delay_len  => c_meta_delay_len,
    g_latency    => c_latency,
    g_init_level => c_rst_level_low
  )
  PORT MAP (
    rst   => rst,
    clk   => clk,
    clken => '1',
    d_in  => d_in,
    q_out => q_low
  );
END tb;
