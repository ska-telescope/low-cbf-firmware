-------------------------------------------------------------------------------
--
-- Copyright (C) 2014
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
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;

-- Purpose:
--   Output active r_in if it is still active after some delay.
-- Description:
--   This function can be used to filter out temporary toggling in r_in. The
--   r_stable only becomes active after r_in has remained active for 
--   2**(g_delayed_w-1) clk cycles. The r_stable always goes inactive when
--   r_in is inactive. The active level can be set with g_active_level to '1'
--   or '0'.
-- Remarks:

ENTITY common_stable_delayed IS
  GENERIC (
    g_active_level : STD_LOGIC := '1';
    g_delayed_w    : NATURAL := 8
  );
  PORT (
    rst          : IN  STD_LOGIC;
    clk          : IN  STD_LOGIC;
    -- MM
    r_in         : IN  STD_LOGIC;
    r_stable     : OUT STD_LOGIC
  );
END common_stable_delayed;


ARCHITECTURE rtl OF common_stable_delayed IS

  SIGNAL p_in      : STD_LOGIC;
  SIGNAL p_stable  : STD_LOGIC;
  
  SIGNAL cnt_clr   : STD_LOGIC;
  SIGNAL cnt_en    : STD_LOGIC;
  SIGNAL cnt       : STD_LOGIC_VECTOR(g_delayed_w-1 DOWNTO 0);
  
BEGIN

  -- Map r to internal p, to be able to internally operate with active level is '1'
  p_in     <= r_in     WHEN g_active_level='1' ELSE NOT r_in;
  r_stable <= p_stable WHEN g_active_level='1' ELSE NOT p_stable;
  
  cnt_clr <= NOT p_in;
  cnt_en  <= NOT cnt(cnt'HIGH);
  
  u_common_counter : ENTITY common_lib.common_counter
  GENERIC MAP (
    g_width  => g_delayed_w
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    cnt_clr => cnt_clr,
    cnt_en  => cnt_en,
    count   => cnt
  );

  p_stable <= cnt(cnt'HIGH);
    
END rtl;
