-------------------------------------------------------------------------------
--
-- Copyright (C) 2012-2016
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

-- Purpose: Provide general control infrastructure
-- Usage: In a design <design_name>.vhd that consists of:
--   . mmm_<design_name>.vhd with MM bus and the peripherals
--   . ctrl_kcu105_board.vhd with e.g. 1GbE, PPS, I2C, Remu, EPCS

LIBRARY IEEE, UNISIM, common_lib, technology_lib, tech_pll_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE UNISIM.vcomponents.all; 
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE work.kcu116_board_pkg.ALL;

ENTITY ctrl_kcu116_board IS
  GENERIC (
    ----------------------------------------------------------------------------
    -- General
    ----------------------------------------------------------------------------
    g_technology     : t_technology := c_tech_xcku5p;
    g_sim            : BOOLEAN := FALSE;
    g_design_name    : STRING := "UNUSED";
    g_fw_version     : t_kcu116_board_fw_version := (0, 0);  -- firmware version x.y
    g_stamp_date     : NATURAL := 0;
    g_stamp_time     : NATURAL := 0;
    g_stamp_svn      : NATURAL := 0;
    g_design_note    : STRING  := "UNUSED";
    g_mm_clk_freq    : NATURAL := c_kcu116_board_mm_clk_freq_100M;
 
    
    ----------------------------------------------------------------------------
    -- Auxiliary Interface
    ----------------------------------------------------------------------------
    g_fpga_temp_high : NATURAL := 85;
    g_app_led_red    : BOOLEAN := FALSE;  -- when TRUE use external LED control via app_led_red
    g_app_led_green  : BOOLEAN := FALSE;  -- when TRUE use external LED control via app_led_green
    
    g_aux            : t_c_kcu116_board_aux := c_kcu116_board_aux;
    g_factory_image  : BOOLEAN := FALSE
  );
  PORT (
    mm_clk  : IN STD_LOGIC;
    mm_rst  : IN STD_LOGIC;
    tod     : OUT STD_LOGIC_VECTOR(13 DOWNTO 0);
    led_in  : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
    led_out : OUT STD_LOGIC_VECTOR(4 DOWNTO 0)
  );
END ctrl_kcu116_board;


ARCHITECTURE str OF ctrl_kcu116_board IS

  CONSTANT c_rom_version : NATURAL := 1; -- Only increment when something changes to the register map of rom_system_info. 
  CONSTANT c_reset_len   : NATURAL := 4;  -- >= c_meta_delay_len from common_pkg
  CONSTANT c_mm_clk_freq : NATURAL := sel_a_b(g_sim=FALSE,g_mm_clk_freq,c_kcu116_board_mm_clk_freq_10M);
    
  
  SIGNAL mm_pulse_ms : STD_LOGIC;
  SIGNAL mm_pulse_s  : STD_LOGIC;

BEGIN

  u_kcu116_board_node_ctrl : ENTITY work.kcu116_board_node_ctrl
  GENERIC MAP (
    g_pulse_us => c_mm_clk_freq / (10**6)     -- nof system clock cycles to get us period, equal to system clock frequency / 10**6
  )
  PORT MAP (
    -- MM clock domain reset
    mm_clk      => mm_clk,
    
    -- Pulses
    mm_pulse_us => OPEN,
    mm_pulse_ms => mm_pulse_ms,
    mm_pulse_s  => mm_pulse_s  -- could be used to toggle a LED
  );

  u_tod_counter : ENTITY common_lib.common_counter
  GENERIC MAP (
    g_width => 14
  )
  PORT MAP (
    rst     => mm_rst,
    clk     => mm_pulse_s,
    count   => tod
  );

  u_extend_led0 : ENTITY common_lib.common_pulse_extend
  GENERIC MAP (
    g_extend_w => 24 -- (2^24) / 125e6 = 0.13422 th of 1 sec
  )
  PORT MAP (
    rst     => mm_rst,
    clk     => mm_clk,
    p_in    => led_in(0),
    ep_out  => led_out(0)
  );
  u_extend_led1 : ENTITY common_lib.common_pulse_extend
  GENERIC MAP (
    g_extend_w => 24 -- (2^24) / 125e6 = 0.13422 th of 1 sec
  )
  PORT MAP (
    rst     => mm_rst,
    clk     => mm_clk,
    p_in    => led_in(1),
    ep_out  => led_out(1)
  );
  u_extend_led2 : ENTITY common_lib.common_pulse_extend
  GENERIC MAP (
    g_extend_w => 24 -- (2^24) / 125e6 = 0.13422 th of 1 sec
  )
  PORT MAP (
    rst     => mm_rst,
    clk     => mm_clk,
    p_in    => led_in(2),
    ep_out  => led_out(2)
  );
  u_extend_led3 : ENTITY common_lib.common_pulse_extend
  GENERIC MAP (
    g_extend_w => 24 -- (2^24) / 125e6 = 0.13422 th of 1 sec
  )
  PORT MAP (
    rst     => mm_rst,
    clk     => mm_clk,
    p_in    => led_in(3),
    ep_out  => led_out(3)
  );
  u_extend_led4 : ENTITY common_lib.common_pulse_extend
  GENERIC MAP (
    g_extend_w => 24 -- (2^24) / 125e6 = 0.13422 th of 1 sec
  )
  PORT MAP (
    rst     => mm_rst,
    clk     => mm_clk,
    p_in    => led_in(4),
    ep_out  => led_out(4)
  );

END str;
