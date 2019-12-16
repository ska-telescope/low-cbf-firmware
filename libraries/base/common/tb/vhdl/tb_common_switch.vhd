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
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;
USE work.tb_common_pkg.ALL;

ENTITY tb_common_switch IS
END tb_common_switch;

-- Usage:
--   > as 10
--   > run -all
--   . expand out_level in the Wave window to check the behaviour of the 16 possible BOOLEAN generic setttings
--   . for expected Wave window see tb_common_switch.jpg
--
-- Description:
--   Runs 8 instances in parallel to try all combinations of:
--   . g_priority_lo
--   . g_or_high
--   . g_and_low
  

ARCHITECTURE tb OF tb_common_switch IS

  CONSTANT clk_period   : TIME := 10 ns;

  CONSTANT c_nof_generics : NATURAL := 3;
  
  CONSTANT c_nof_dut          : NATURAL := 2**c_nof_generics;
  CONSTANT c_generics_matrix  : t_boolean_matrix(0 TO c_nof_dut-1, 0 TO c_nof_generics-1) := ((FALSE, FALSE, FALSE),
                                                                                              (FALSE, FALSE,  TRUE),
                                                                                              (FALSE,  TRUE, FALSE),
                                                                                              (FALSE,  TRUE,  TRUE),
                                                                                              ( TRUE, FALSE, FALSE),
                                                                                              ( TRUE, FALSE,  TRUE),
                                                                                              ( TRUE,  TRUE, FALSE),
                                                                                              ( TRUE,  TRUE,  TRUE));
  -- View constants in Wave window
  SIGNAL dbg_c_generics_matrix  : t_boolean_matrix(0 TO c_nof_dut-1, 0 TO c_nof_generics-1) := c_generics_matrix;
  SIGNAL dbg_state              : NATURAL;
  
  SIGNAL rst                      : STD_LOGIC;
  SIGNAL clk                      : STD_LOGIC := '0';
  SIGNAL tb_end                   : STD_LOGIC := '0';
  SIGNAL in_hi                    : STD_LOGIC;
  SIGNAL in_lo                    : STD_LOGIC;
  
  SIGNAL dbg_prio_lo              : STD_LOGIC;
  SIGNAL dbg_prio_lo_and          : STD_LOGIC;
  SIGNAL dbg_prio_lo_or           : STD_LOGIC;
  SIGNAL dbg_prio_lo_or_and       : STD_LOGIC;
  
  SIGNAL dbg_prio_hi              : STD_LOGIC;
  SIGNAL dbg_prio_hi_and          : STD_LOGIC;
  SIGNAL dbg_prio_hi_or           : STD_LOGIC;
  SIGNAL dbg_prio_hi_or_and       : STD_LOGIC;
  
  SIGNAL out_level : STD_LOGIC_VECTOR(0 TO c_nof_dut-1);

BEGIN

  clk  <= NOT clk OR tb_end AFTER clk_period/2;
    
  p_in_stimuli : PROCESS
  BEGIN
    dbg_state <= 0;
    rst <= '1';
    in_hi <= '0';
    in_lo <= '0';
    proc_common_wait_some_cycles(clk, 1);
    rst <= '0';
    proc_common_wait_some_cycles(clk, 10);
    -- 1) Single hi pulse
    dbg_state <= 1;
    in_hi <= '1';
    proc_common_wait_some_cycles(clk, 1);
    in_hi <= '0';
    proc_common_wait_some_cycles(clk, 5);
    in_lo <= '1';
    proc_common_wait_some_cycles(clk, 1);
    in_hi <= '0';
    in_lo <= '0';
    proc_common_wait_some_cycles(clk, 10);
    -- 2) Second hi pulse during active lo gets ignored
    dbg_state <= 2;
    in_hi <= '1';
    proc_common_wait_some_cycles(clk, 1);
    in_hi <= '0';
    proc_common_wait_some_cycles(clk, 5);
    in_hi <= '1';
    in_lo <= '1';
    proc_common_wait_some_cycles(clk, 1);
    in_hi <= '0';
    in_lo <= '1';
    proc_common_wait_some_cycles(clk, 1);
    in_lo <= '0';
    proc_common_wait_some_cycles(clk, 10);
    -- 3) Second hi pulse while lo is just active, should be recognized as second out pulse
    dbg_state <= 3;
    in_hi <= '1';
    proc_common_wait_some_cycles(clk, 1);
    in_hi <= '0';
    proc_common_wait_some_cycles(clk, 5);
    in_hi <= '1';
    in_lo <= '1';
    proc_common_wait_some_cycles(clk, 1);
    in_hi <= '0';
    in_lo <= '0';
    proc_common_wait_some_cycles(clk, 5);
    proc_common_wait_some_cycles(clk, 1);
    in_hi <= '0';
    proc_common_wait_some_cycles(clk, 5);
    in_lo <= '1';
    proc_common_wait_some_cycles(clk, 1);
    in_hi <= '0';
    in_lo <= '0';
    proc_common_wait_some_cycles(clk, 10);
    -- 4) Continue active hi with single lo pulse
    dbg_state <= 4;
    in_hi <= '1';
    proc_common_wait_some_cycles(clk, 5);
    in_lo <= '1';
    proc_common_wait_some_cycles(clk, 1);
    in_lo <= '0';
    proc_common_wait_some_cycles(clk, 10);
    in_lo <= '1';
    proc_common_wait_some_cycles(clk, 3);
    in_lo <= '0';
    proc_common_wait_some_cycles(clk, 10);
    in_hi <= '0';
    proc_common_wait_some_cycles(clk, 3);
    in_lo <= '1';
    proc_common_wait_some_cycles(clk, 1);
    in_lo <= '0';
    proc_common_wait_some_cycles(clk, 10);
    -- 5) Active hi immediately after active lo
    dbg_state <= 5;
    in_hi <= '1';
    proc_common_wait_some_cycles(clk, 1);
    in_hi <= '0';
    proc_common_wait_some_cycles(clk, 5);
    in_lo <= '1';
    proc_common_wait_some_cycles(clk, 1);
    in_lo <= '0';
    in_hi <= '1';
    proc_common_wait_some_cycles(clk, 1);
    in_hi <= '0';
    proc_common_wait_some_cycles(clk, 5);
    in_lo <= '1';
    proc_common_wait_some_cycles(clk, 1);
    in_lo <= '0';
    proc_common_wait_some_cycles(clk, 10);
    -- 6) Simultaneous hi pulse and lo pulse
    dbg_state <= 6;
    in_hi <= '1';
    in_lo <= '1';
    proc_common_wait_some_cycles(clk, 1);
    in_hi <= '0';
    in_lo <= '0';
    proc_common_wait_some_cycles(clk, 5);
    in_lo <= '1';
    proc_common_wait_some_cycles(clk, 1);
    in_lo <= '0';
    proc_common_wait_some_cycles(clk, 10);
    -- 7) Multiple simultaneous hi pulse and lo pulse
    dbg_state <= 7;
    in_hi <= '1';
    in_lo <= '1';
    proc_common_wait_some_cycles(clk, 1);
    in_hi <= '0';
    in_lo <= '0';
    proc_common_wait_some_cycles(clk, 5);
    in_hi <= '1';
    in_lo <= '1';
    proc_common_wait_some_cycles(clk, 1);
    in_hi <= '0';
    in_lo <= '0';
    proc_common_wait_some_cycles(clk, 5);
    in_hi <= '1';
    in_lo <= '1';
    proc_common_wait_some_cycles(clk, 1);
    in_hi <= '0';
    in_lo <= '0';
    proc_common_wait_some_cycles(clk, 5);
    in_lo <= '1';  -- ensure low output if it was still high
    proc_common_wait_some_cycles(clk, 1);
    in_lo <= '0';
    proc_common_wait_some_cycles(clk, 10);
    
    dbg_state <= 255;
    proc_common_wait_some_cycles(clk, 10);
    tb_end <= '1';
    WAIT;
  END PROCESS;

  dbg_prio_lo              <= out_level(4);
  dbg_prio_lo_and          <= out_level(5);
  dbg_prio_lo_or           <= out_level(6);
  dbg_prio_lo_or_and       <= out_level(7);
  
  dbg_prio_hi              <= out_level(0);
  dbg_prio_hi_and          <= out_level(1);
  dbg_prio_hi_or           <= out_level(2);
  dbg_prio_hi_or_and       <= out_level(3);
  
  gen_dut : FOR I IN 0 TO c_nof_dut-1 GENERATE
    u_switch : ENTITY work.common_switch
    GENERIC MAP (
      g_rst_level    => '0',    -- output level at reset.
      --g_rst_level    => '1',
      g_priority_lo  => c_generics_matrix(I,0),
      g_or_high      => c_generics_matrix(I,1),
      g_and_low      => c_generics_matrix(I,2)
    )
    PORT MAP (
      clk         => clk,
      rst         => rst,
      switch_high => in_hi,
      switch_low  => in_lo,
      out_level   => out_level(I)
    );
  END GENERATE;
        
END tb;
