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

ENTITY tb_common_flank_to_pulse IS
END tb_common_flank_to_pulse;

ARCHITECTURE tb OF tb_common_flank_to_pulse IS

  CONSTANT clk_period   : TIME := 10 ns;
  
  SIGNAL rst    : STD_LOGIC;
  SIGNAL clk    : STD_LOGIC := '0';
  SIGNAL flank_in : STD_LOGIC;
  SIGNAL pulse_out : STD_LOGIC;

BEGIN

  clk  <= NOT clk  AFTER clk_period/2;
     
  p_in_stimuli : PROCESS
  BEGIN
    rst <= '1';
    flank_in <= '0';
    WAIT UNTIL rising_edge(clk);
    rst <= '0';    
    WAIT FOR 200 ns;
    flank_in <= '1';
    WAIT FOR 200 ns;
    flank_in <='0';
    WAIT FOR 200 ns;
    flank_in <= '1';
    WAIT FOR 200 ns;
    flank_in <= '0';
    WAIT;
  END PROCESS;
   
  u_dut: ENTITY work.common_flank_to_pulse
  PORT MAP (
    clk     => clk,
    rst     => rst,
    flank_in => flank_in,
    pulse_out => pulse_out
  );
      
END tb;
