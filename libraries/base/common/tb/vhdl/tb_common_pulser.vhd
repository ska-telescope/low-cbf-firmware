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

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;

ENTITY tb_common_pulser IS
END tb_common_pulser;

ARCHITECTURE tb OF tb_common_pulser IS

  CONSTANT clk_period   : TIME := 40 ns;
  
  CONSTANT c_reset_len  : NATURAL := 3;
  
  CONSTANT c_pulse_us   : NATURAL := 25;
  CONSTANT c_pulse_ms   : NATURAL := 1000;
  
  SIGNAL rst                   : STD_LOGIC;
  SIGNAL clk                   : STD_LOGIC := '0';
  
  SIGNAL pulse_us              : STD_LOGIC;
  SIGNAL pulse_ms_via_clk_en   : STD_LOGIC;
  SIGNAL pulse_ms_via_pulse_en : STD_LOGIC;

  SIGNAL pulse_ms_clr          : STD_LOGIC;
  
BEGIN

  -- as 3
  -- run 7 ms
  
  clk <= NOT clk  AFTER clk_period/2;
  
  p_pulse_clr : PROCESS
  BEGIN
    pulse_ms_clr <= '0';
    FOR I IN 0 TO 1500 LOOP
      WAIT UNTIL pulse_us='1';
      WAIT UNTIL rising_edge(clk);
    END LOOP;
    
    WAIT UNTIL pulse_us='1';
    pulse_ms_clr <= '1';
    WAIT UNTIL rising_edge(clk);
    pulse_ms_clr <= '0';
    WAIT;
  END PROCESS;
  
  u_reset : ENTITY work.common_areset
  GENERIC MAP (
    g_rst_level => '1',  -- power up default will be inferred in FPGA
    g_delay_len => c_reset_len
  )
  PORT MAP (
    in_rst    => '0',    -- release reset after some clock cycles
    clk       => clk,
    out_rst   => rst
  );
    
  u_pulse_us : ENTITY work.common_pulser
  GENERIC MAP (
    g_pulse_period => c_pulse_us,
    g_pulse_phase  => c_pulse_us-1
  )
  PORT MAP (
    rst            => rst,
    clk            => clk,
    clken          => '1',
    pulse_en       => '1',
    pulse_clr      => '0',
    pulse_out      => pulse_us
  );
      
  u_pulse_ms_via_clk_en : ENTITY work.common_pulser
  GENERIC MAP (
    g_pulse_period => c_pulse_ms
  )
  PORT MAP (
    rst            => rst,
    clk            => clk,
    clken          => pulse_us,
    pulse_en       => '1',
    pulse_clr      => pulse_ms_clr,
    pulse_out      => pulse_ms_via_clk_en
  );
  
  u_pulse_ms_via_pulse_en : ENTITY work.common_pulser
  GENERIC MAP (
    g_pulse_period => c_pulse_ms
  )
  PORT MAP (
    rst            => rst,
    clk            => clk,
    clken          => '1',
    pulse_en       => pulse_us,
    pulse_clr      => pulse_ms_clr,
    pulse_out      => pulse_ms_via_pulse_en
  );
  
END tb;
