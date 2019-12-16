-------------------------------------------------------------------------------
--
-- Copyright (C) 2010-2016
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

LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE common_lib.common_pkg.ALL;


ENTITY tb_vcu110_board_node_ctrl IS
END tb_vcu110_board_node_ctrl;


ARCHITECTURE tb OF tb_vcu110_board_node_ctrl IS

  CONSTANT c_scale             : NATURAL := 100;             -- scale to speed up simulation
  
  CONSTANT c_xo_clk_period     : TIME := 1 us;               -- 1 MHz XO, slow XO to speed up simulation
  CONSTANT c_mm_clk_period     : TIME := c_xo_clk_period/5;  -- 5 MHz PLL output from XO reference
  CONSTANT c_mm_locked_time    : TIME := 10 us;
    
  CONSTANT c_pulse_us          : NATURAL := 5;              -- nof 5 MHz clk cycles to get us period
  CONSTANT c_pulse_ms          : NATURAL := 1000/c_scale;   -- nof pulse_us pulses to get ms period
  CONSTANT c_pulse_s           : NATURAL := 1000;           -- nof pulse_ms pulses to get  s period
  
  CONSTANT c_wdi_extend_w      : NATURAL := 14;     -- extend wdi by about 2**(14-1)= 8 s (as defined by c_pulse_ms)
  CONSTANT c_wdi_period        : TIME :=  1000 ms;  -- wdi toggle after c_wdi_period
  
  -- Use c_sw_period=40000 ms to show that the c_wdi_extend_w=5 is not enough, the WD will kick in when the sw is off during reload
  CONSTANT c_sw_period         : TIME := 40000 ms;  -- sw active for c_sw_period then inactive during reload for c_sw_period, etc.
  -- Use c_sw_period=10000 ms to show that the c_wdi_extend_w=5 is enough, the WD will not kick in when the sw is off during reload
  --CONSTANT c_sw_period         : TIME := 6000 ms;  -- sw active for c_sw_period then inactive during reload for c_sw_period, etc.
  
  SIGNAL mm_clk      : STD_LOGIC := '0';
  SIGNAL mm_locked   : STD_LOGIC := '0';
  SIGNAL mm_rst      : STD_LOGIC;
  
  SIGNAL wdi         : STD_LOGIC := '0';
  SIGNAL wdi_in      : STD_LOGIC;
  SIGNAL wdi_out     : STD_LOGIC;
  
  SIGNAL sw          : STD_LOGIC := '0';
  
  SIGNAL pulse_us    : STD_LOGIC;
  SIGNAL pulse_ms    : STD_LOGIC;
  SIGNAL pulse_s     : STD_LOGIC;
  
BEGIN

  -- run 2000 ms
  
  mm_clk <= NOT mm_clk AFTER c_mm_clk_period/2;
  mm_locked <= '0', '1' AFTER c_mm_locked_time;
  
  wdi    <= NOT wdi AFTER c_wdi_period/c_scale;  -- wd interrupt
  sw     <= NOT sw  AFTER c_sw_period/c_scale;   -- sw active / reload
  
  wdi_in <= wdi AND sw;  -- sw wdi only when sw is active, during sw inactive the wdi_out will be extended
  
  dut : ENTITY work.vcu110_board_node_ctrl
  GENERIC MAP (
    g_pulse_us     => c_pulse_us,
    g_pulse_ms     => c_pulse_ms,
    g_pulse_s      => c_pulse_s,
    g_wdi_extend_w => c_wdi_extend_w
  )
  PORT MAP (
    -- MM clock domain reset
    mm_clk      => mm_clk,
    mm_locked   => mm_locked,
    mm_rst      => mm_rst,
    -- WDI extend
    mm_wdi_in   => wdi_in,
    mm_wdi_out  => wdi_out,
    -- Pulses
    mm_pulse_us => pulse_us,
    mm_pulse_ms => pulse_ms,
    mm_pulse_s  => pulse_s
  );
  
END tb;
