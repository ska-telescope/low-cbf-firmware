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

-- Purpose: Testbench for common_spulse.
-- Description:
--   The tb is not self checking, so manually observe working in Wave window.
-- Usage:
-- > as 10
-- > run 1 us

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;

ENTITY tb_common_spulse IS
END tb_common_spulse;

ARCHITECTURE tb OF tb_common_spulse IS

  CONSTANT c_meta_delay    : NATURAL := 2;
  
  --CONSTANT in_clk_period   : TIME := 10 ns;
  CONSTANT in_clk_period   : TIME := 27 ns;
  CONSTANT out_clk_period  : TIME := 17 ns;

  SIGNAL in_rst    : STD_LOGIC;
  SIGNAL out_rst   : STD_LOGIC;
  SIGNAL in_clk    : STD_LOGIC := '0';
  SIGNAL out_clk   : STD_LOGIC := '0';
  SIGNAL in_pulse  : STD_LOGIC;
  SIGNAL out_pulse : STD_LOGIC;

BEGIN

  in_clk  <= NOT in_clk  AFTER in_clk_period/2;
  out_clk <= NOT out_clk AFTER out_clk_period/2;
    
  p_in_stimuli : PROCESS
  BEGIN
    in_rst <= '1';
    in_pulse <= '0';
    WAIT UNTIL rising_edge(in_clk);
    in_rst <= '0';
    FOR I IN 0 TO 9 LOOP
      WAIT UNTIL rising_edge(in_clk);
    END LOOP;
    in_pulse <= '1';
    WAIT UNTIL rising_edge(in_clk);
    in_pulse <= '0';
    WAIT;
  END PROCESS;

  u_out_rst : ENTITY work.common_areset
  PORT MAP (
    in_rst   => in_rst,
    clk      => out_clk,
    out_rst  => out_rst
  );
  
  u_spulse : ENTITY work.common_spulse
  GENERIC MAP (
    g_delay_len => c_meta_delay
  )
  PORT MAP (
    in_clk     => in_clk,
    in_rst     => in_rst,
    in_pulse   => in_pulse,
    out_clk    => out_clk,
    out_rst    => out_rst,
    out_pulse  => out_pulse
  );
      
END tb;
