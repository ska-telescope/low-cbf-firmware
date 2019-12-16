-------------------------------------------------------------------------------
--
-- Copyright (C) 2012
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

ENTITY common_toggle IS
  GENERIC (
    g_evt_type   : STRING := "RISING";  -- type can be toggle at "RISING", "FALLING", or "BOTH" edges of in_dat when in_val='1'
    g_rst_level  : STD_LOGIC := '0'     -- Defines the output level at reset.
  );
  PORT (
    rst         : IN  STD_LOGIC;
    clk         : IN  STD_LOGIC;
    clken       : IN  STD_LOGIC := '1';
    in_dat      : IN  STD_LOGIC;
    in_val      : IN  STD_LOGIC := '1';
    out_dat     : OUT STD_LOGIC
  );
END;

ARCHITECTURE rtl OF common_toggle IS
  
  SIGNAL prev_in_dat          : STD_LOGIC;
  SIGNAL in_hld               : STD_LOGIC;
  SIGNAL in_evt               : STD_LOGIC;
  
  SIGNAL i_out_dat            : STD_LOGIC;
  SIGNAL nxt_out_dat          : STD_LOGIC;
  
BEGIN

  out_dat <= i_out_dat;
  
  p_reg : PROCESS(rst, clk)
  BEGIN
    IF rst='1' THEN
      prev_in_dat <= g_rst_level;
      i_out_dat   <= g_rst_level;
    ELSIF rising_edge(clk) THEN
      IF clken='1' THEN
        prev_in_dat <= in_hld;
        i_out_dat   <= nxt_out_dat;
      END IF;
    END IF;
  END PROCESS;
  
  -- Hold in_dat combinatorially
  in_hld <= in_dat WHEN in_val='1' ELSE prev_in_dat;

  -- Detect in_dat event  
  u_in_evt : ENTITY work.common_evt
  GENERIC MAP (
    g_evt_type   => g_evt_type,
    g_out_invert => FALSE,
    g_out_reg    => TRUE
  )
  PORT MAP (
    rst      => rst,
    clk      => clk,
    clken    => clken,
    in_sig   => in_hld,
    out_evt  => in_evt
  );

  -- Toggle output at in_dat event
  nxt_out_dat <= NOT i_out_dat WHEN in_evt='1' ELSE i_out_dat;
  
END rtl;
