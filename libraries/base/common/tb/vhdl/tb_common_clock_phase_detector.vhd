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

-- Purpose: Test bench for common_clock_phase_detector
-- Usage:
--   > as 5
--   > run -all
--
-- Description:

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;
USE work.tb_common_pkg.ALL;

ENTITY tb_common_clock_phase_detector IS
  GENERIC (
    --g_clk_factor     : REAL := 0.5     -- = clk rate / in_clk rate, must be integer or 1/integer
    g_clk_factor     : REAL := 2.0     -- = clk rate / in_clk rate, must be integer or 1/integer
  );
END tb_common_clock_phase_detector;


ARCHITECTURE tb OF tb_common_clock_phase_detector IS

  CONSTANT c_clk_factor_num : NATURAL := sel_a_b(g_clk_factor>=1.0, INTEGER(g_clk_factor),     1);
  CONSTANT c_clk_factor_den : NATURAL := sel_a_b(g_clk_factor <1.0, INTEGER(1.0/g_clk_factor), 1);
  
  CONSTANT c_in_clk_period : TIME := c_clk_factor_num * 5 ns;
  
  CONSTANT in_clk_drift    : TIME := 6 ps;  -- must be 0 or even, use drift to model different clock phases
  CONSTANT in_clk_period   : TIME := c_in_clk_period + in_clk_drift;
  
  CONSTANT clk_period      : TIME := c_clk_factor_den * c_in_clk_period / c_clk_factor_num;
  
  CONSTANT c_on_interval   : NATURAL := 5000;
  CONSTANT c_off_interval  : NATURAL := 500;
  CONSTANT c_delay_len     : NATURAL := 3;
  
  SIGNAL tb_end         : STD_LOGIC := '0';
  SIGNAL in_en          : STD_LOGIC := '1';
  SIGNAL in_clk         : STD_LOGIC := '0';
  
  SIGNAL rst            : STD_LOGIC;
  SIGNAL clk            : STD_LOGIC := '0';
  SIGNAL phase_r        : STD_LOGIC;
  SIGNAL phase_r_det    : STD_LOGIC;
  SIGNAL phase_f        : STD_LOGIC;
  SIGNAL phase_f_det    : STD_LOGIC;

BEGIN

  in_clk <= NOT (in_clk AND in_en) OR tb_end AFTER in_clk_period/2;
  clk    <= NOT clk OR tb_end AFTER clk_period/2;
  
  rst <= '1', '0' AFTER clk_period*10;
  
  p_in_stimuli : PROCESS
  BEGIN
    in_en  <= '1';
    proc_common_wait_some_cycles(clk, c_on_interval);
    in_en  <= '0';
    proc_common_wait_some_cycles(clk, c_off_interval);
    in_en  <= '1';
    proc_common_wait_some_cycles(clk, c_on_interval);
    in_en  <= '0';
    proc_common_wait_some_cycles(clk, c_off_interval);
    in_en  <= '1';
    proc_common_wait_some_cycles(clk, c_on_interval);
    tb_end <= '1';
    WAIT;
  END PROCESS;
  
  u_common_clock_phase_detector_r : ENTITY work.common_clock_phase_detector
  GENERIC MAP (
    g_rising_edge    => TRUE,
    g_meta_delay_len => c_delay_len,
    g_clk_factor     => c_clk_factor_num
  )
  PORT MAP (
    in_clk    => in_clk,           -- used as data input for clk domain
    rst       => rst,
    clk       => clk,
    phase     => phase_r,
    phase_det => phase_r_det
  );
  
  u_common_clock_phase_detector_f : ENTITY work.common_clock_phase_detector
  GENERIC MAP (
    g_rising_edge    => FALSE,
    g_meta_delay_len => c_delay_len,
    g_clk_factor     => c_clk_factor_num
  )
  PORT MAP (
    in_clk    => in_clk,           -- used as data input for clk domain
    rst       => rst,
    clk       => clk,
    phase     => phase_f,
    phase_det => phase_f_det
  );
  
END tb;
