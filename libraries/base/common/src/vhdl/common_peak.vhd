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

-- Purpose: Provide the maximum value that is seen on the input on the output. 
-- Description: The peak value of the input data is captured and maintained
--              on the output. A pulse on in_clear will reset thepeak value. 
--              Only valid data will be considered. 
--
--
--
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE work.common_pkg.ALL;

ENTITY common_peak IS
  GENERIC (
    g_dat_w : POSITIVE := 8
  );
  PORT (
    rst       : IN  STD_LOGIC := '0';
    clk       : IN  STD_LOGIC;
    in_dat    : IN  STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    in_val    : IN  STD_LOGIC := '1';
    in_clear  : IN  STD_LOGIC;
    out_dat   : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    out_val   : OUT STD_LOGIC
  );
END common_peak;

ARCHITECTURE rtl OF common_peak IS

  TYPE reg_type IS RECORD
    peak    : STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    out_val : STD_LOGIC;
  END RECORD;

  SIGNAL r, rin      : reg_type;
  
BEGIN

  p_comb : PROCESS(r, rst, in_val, in_dat, in_clear)
    VARIABLE v : reg_type;
  BEGIN
   
    v := r;
   
    IF in_val = '1' THEN 
      IF TO_UINT(in_dat) > TO_UINT(r.peak) THEN 
        v.peak := in_dat;
        v.out_val := '1';
      END IF; 
    END IF; 
    
    IF in_clear = '1' then
      v.peak := (OTHERS => '0');
      v.out_val := '0';
    END IF; 
    
    IF(rst = '1') THEN 
      v.peak   := (OTHERS => '0');
      v.out_val:= '0';
    END IF;

    rin <= v;  
         
  END PROCESS;
  
  p_regs : PROCESS(clk)
  BEGIN 
    IF RISING_EDGE(clk) THEN 
      r <= rin; 
    END IF; 
  END PROCESS;

  out_val   <= r.out_val;
  out_dat   <= r.peak;
  
END rtl;
