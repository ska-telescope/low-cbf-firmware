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

-- Purpose: Clock an asynchronous din into the clk clock domain
-- Description:
--   The delay line combats the potential meta-stability of clocked in data.

LIBRARY IEEE, common_lib;
USE IEEE.std_logic_1164.ALL;
USE common_lib.common_pkg.ALL;

ENTITY common_async IS
  GENERIC (
    g_rising_edge : BOOLEAN := TRUE;
    g_rst_level   : STD_LOGIC := '0';
    g_delay_len   : POSITIVE := c_meta_delay_len   -- use common_pipeline if g_delay_len=0 for wires only is also needed
  );
  PORT (
    rst  : IN  STD_LOGIC := '0';
    clk  : IN  STD_LOGIC;
    din  : IN  STD_LOGIC;
    dout : OUT STD_LOGIC
  );
END;


ARCHITECTURE rtl OF common_async IS
  
  SIGNAL din_meta : STD_LOGIC_VECTOR(0 TO g_delay_len-1) := (OTHERS=>g_rst_level);
  
  -- Synthesis constraint to ensure that register is kept in this instance region
  attribute preserve : boolean;
  attribute preserve of din_meta : signal is true;
  
BEGIN

  p_clk : PROCESS (rst, clk)
  BEGIN
    IF g_rising_edge=TRUE THEN
      -- Default use rising edge
      IF rst='1' THEN
        din_meta <= (OTHERS=>g_rst_level);
      ELSIF rising_edge(clk) THEN
        din_meta <= din & din_meta(0 TO din_meta'HIGH-1);
      END IF;
    ELSE
      -- also support using falling edge
      IF rst='1' THEN
        din_meta <= (OTHERS=>g_rst_level);
      ELSIF falling_edge(clk) THEN
        din_meta <= din & din_meta(0 TO din_meta'HIGH-1);
      END IF;
    END IF;
  END PROCESS;
  
  dout <= din_meta(din_meta'HIGH);
  
END rtl;
