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

-- Purpose: Provide the basic node clock control (resets, pulses, WDI)
-- Description:
--   . Create mm_rst for mm_clk:
--   . Extend WDI to avoid watchdog reset during software reload
--   . Pulse every 1 us, 1 ms and 1 s

ENTITY kcu116_board_node_ctrl IS
  GENERIC (
    g_pulse_us     : NATURAL := 125;     -- nof system clock cycles to get us period, equal to system clock frequency / 10**6
    g_pulse_ms     : NATURAL := 1000;    -- nof pulse_us pulses to get ms period (fixed, use less to speed up simulation)
    g_pulse_s      : NATURAL := 1000;    -- nof pulse_ms pulses to get  s period (fixed, use less to speed up simulation)
    g_wdi_extend_w : NATURAL := 14       -- extend the mm_wdi_in by toggling the mm_wdi_out for about 2**(14-1)= 8 s more
  );
  PORT (
    -- MM clock domain reset
    mm_clk          : IN  STD_LOGIC;         -- MM clock
    mm_locked       : IN  STD_LOGIC := '1';  -- MM clock PLL locked (or use default '1')
    mm_rst          : OUT STD_LOGIC;         -- MM reset released after MM clock PLL has locked
    ph_rst          : OUT STD_LOGIC;         -- MM pheripheral reset: extra long
    
    -- Pulses
    mm_pulse_us     : OUT STD_LOGIC;         -- pulses every us
    mm_pulse_ms     : OUT STD_LOGIC;         -- pulses every ms
    mm_pulse_s      : OUT STD_LOGIC          -- pulses every s
  );
END kcu116_board_node_ctrl;


ARCHITECTURE str OF kcu116_board_node_ctrl IS

  CONSTANT c_reset_len   : NATURAL := 16;  -- >= c_meta_delay_len from common_pkg

  SIGNAL mm_locked_n     : STD_LOGIC;
  SIGNAL i_mm_rst        : STD_LOGIC;
  SIGNAL i_mm_pulse_ms   : STD_LOGIC;
  SIGNAL i_ph_rst        : STD_LOGIC;
  
BEGIN

  -- Create mm_rst reset in mm_clk domain based on mm_locked 
  mm_rst <= i_mm_rst;  
  
  mm_locked_n <= NOT mm_locked;
  
  u_common_areset_mm : ENTITY common_lib.common_areset
  GENERIC MAP (
    g_rst_level => '1',       -- power up default will be inferred in FPGA
    g_delay_len => c_reset_len
  )
  PORT MAP (
    in_rst    => mm_locked_n,  -- release reset after some clock cycles when the PLL has locked
    clk       => mm_clk,
    out_rst   => i_mm_rst
  );  
  
  -- Create 1 pulse per us, per ms and per s  
  mm_pulse_ms <= i_mm_pulse_ms;

  u_common_pulser_us_ms_s : ENTITY common_lib.common_pulser_us_ms_s
  GENERIC MAP (
    g_pulse_us  => g_pulse_us,
    g_pulse_ms  => g_pulse_ms,
    g_pulse_s   => g_pulse_s
  )
  PORT MAP (
    rst         => i_mm_rst,
    clk         => mm_clk,
    pulse_us    => mm_pulse_us,
    pulse_ms    => i_mm_pulse_ms,
    pulse_s     => mm_pulse_s
  );

  u_common_areset_ph : ENTITY common_lib.common_areset
  GENERIC MAP (
    g_rst_level => '1',       -- power up default will be inferred in FPGA
    g_delay_len => c_reset_len*2
  )
  PORT MAP (
    in_rst    => mm_locked_n,  -- release reset after some clock cycles when the PLL has locked
    clk       => mm_clk,
    out_rst   => i_ph_rst
  );
END str;
