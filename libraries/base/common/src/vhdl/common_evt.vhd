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
USE work.common_pkg.ALL;

ENTITY common_evt IS
  GENERIC (
    g_evt_type   : STRING := "RISING";  -- type can be: "RISING", "FALLING", or "BOTH"
    g_out_invert : BOOLEAN := FALSE;    -- if TRUE then invert the output to have active low output, else default use active high output
    g_out_reg    : BOOLEAN := FALSE     -- if TRUE then the output is registered, else it is not
  );
  PORT (
    rst      : IN  STD_LOGIC := '0';
    clk      : IN  STD_LOGIC;
    clken    : IN  STD_LOGIC := '1';
    in_sig   : IN  STD_LOGIC;
    out_evt  : OUT STD_LOGIC
  );
END common_evt;


ARCHITECTURE rtl OF common_evt IS

  SIGNAL in_sig_prev  : STD_LOGIC := '0';
  SIGNAL sig_evt      : STD_LOGIC;
  SIGNAL sig_evt_n    : STD_LOGIC;

BEGIN

  -- Create previous in_sig
  p_clk : PROCESS(rst, clk)
  BEGIN
    IF rst='1' THEN
      in_sig_prev <= '0';
    ELSIF rising_edge(clk) THEN
      IF clken='1' THEN
        in_sig_prev <= in_sig;
      END IF;
    END IF;
  END PROCESS;

  -- Detect input event
  gen_rising  : IF g_evt_type="RISING"  GENERATE sig_evt <=     in_sig AND NOT in_sig_prev;  END GENERATE;
  gen_falling : IF g_evt_type="FALLING" GENERATE sig_evt <= NOT in_sig AND     in_sig_prev;  END GENERATE;
  gen_both    : IF g_evt_type="BOTH"    GENERATE sig_evt <=     in_sig XOR     in_sig_prev;  END GENERATE;
  
  sig_evt_n <= NOT sig_evt;
  
  -- Output combinatorial event pulse
  no_out_reg : IF g_out_reg=FALSE GENERATE
    out_evt <= sel_a_b(g_out_invert, sig_evt_n, sig_evt);
  END GENERATE;
  
  -- Output registered event pulse
  gen_out_reg : IF g_out_reg=TRUE GENERATE
    p_clk : PROCESS(rst, clk)
    BEGIN
      IF rst='1' THEN
        out_evt <= sel_a_b(g_out_invert, '1', '0') ;
      ELSIF rising_edge(clk) THEN
        IF clken='1' THEN
          out_evt <= sel_a_b(g_out_invert, sig_evt_n, sig_evt);
        END IF;
      END IF;
    END PROCESS;
  END GENERATE;
  
END rtl;