--------------------------------------------------------------------------------
--
-- Copyright (C) 2011
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
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY common_flank_to_pulse IS   
  PORT (                  
    clk                : IN STD_LOGIC;
    rst                : IN STD_LOGIC;
    flank_in           : IN STD_LOGIC;
    pulse_out          : OUT STD_LOGIC 
  );
END common_flank_to_pulse;


ARCHITECTURE str OF common_flank_to_pulse IS

  SIGNAL flank_in_dly : STD_LOGIC;

BEGIN  

 p_in_dly : PROCESS(rst, clk)
  BEGIN
    IF rst='1' THEN
      flank_in_dly  <='0';
    ELSIF rising_edge(clk) THEN
      flank_in_dly <= flank_in;
    END IF;    
  END PROCESS;
  
  pulse_out <= flank_in AND NOT(flank_in_dly);

END str;


