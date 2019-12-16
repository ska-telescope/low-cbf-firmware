-------------------------------------------------------------------------------
--
-- Copyright (C) 2012-2015
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

-- Purpose : MMS for gmi_board_sens
-- Description: See gmi_board_sens.vhd

LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;


ENTITY mms_gmi_board_sens IS
  GENERIC (
    g_sim             : BOOLEAN := FALSE;
    g_i2c_peripheral  : NATURAL;
    g_sens_nof_result : NATURAL;  -- Should match nof read bytes via I2C in the gmi_board_sens_ctrl SEQUENCE list
    g_clk_freq        : NATURAL := 100*10**6;  -- clk frequency in Hz
    g_temp_high       : NATURAL := 85;
    g_comma_w         : NATURAL := 0
  );
  PORT (
    -- Clocks and reset
    mm_rst            : IN  STD_LOGIC;  -- reset synchronous with mm_clk
    mm_clk            : IN  STD_LOGIC;  -- memory-mapped bus clock
    mm_start          : IN  STD_LOGIC;
    
    -- Memory-mapped clock domain
    reg_mosi          : IN  t_mem_mosi := c_mem_mosi_rst;  -- actual ranges defined by c_mm_reg
    reg_miso          : OUT t_mem_miso;                    -- actual ranges defined by c_mm_reg
    
    -- i2c bus
    scl               : INOUT STD_LOGIC := 'Z';
    sda               : INOUT STD_LOGIC := 'Z';

    -- Temperature alarm output
    temp_alarm        : OUT STD_LOGIC
  );
END mms_gmi_board_sens;


ARCHITECTURE str OF mms_gmi_board_sens IS

  CONSTANT c_temp_high_w     : NATURAL := 7;  -- Allow user to use only 7 (no sign, only positive) of 8 bits to set set max temp

  SIGNAL sens_err  : STD_LOGIC;
  SIGNAL sens_data : t_slv_8_arr(0 TO g_sens_nof_result-1);

  SIGNAL temp_high : STD_LOGIC_VECTOR(c_temp_high_w-1 DOWNTO 0);
  
  attribute mark_debug: string;
  attribute mark_debug of mm_start: signal is "true";
    
BEGIN

  u_gmi_board_sens_reg : ENTITY work.gmi_board_sens_reg
  GENERIC MAP (
    g_sens_nof_result => g_sens_nof_result,
    g_temp_high       => g_temp_high  
  )
  PORT MAP (
    -- Clocks and reset
    mm_rst       => mm_rst,
    mm_clk       => mm_clk,
    
    -- Memory Mapped Slave in mm_clk domain
    sla_in       => reg_mosi,
    sla_out      => reg_miso,
    
    -- MM registers
    sens_err     => sens_err,  -- using same protocol list for both node2 and all nodes implies that sens_err is only valid for node2.
    sens_data    => sens_data,

    -- Max temp threshold
    temp_high    => temp_high
  );
  
  u_gmi_board_sens : ENTITY work.gmi_board_sens
  GENERIC MAP (
    g_sim             => g_sim,
    g_i2c_peripheral  => g_i2c_peripheral,
    g_clk_freq        => g_clk_freq,
    g_temp_high       => g_temp_high,
    g_sens_nof_result => g_sens_nof_result,
    g_comma_w         => g_comma_w
  )
  PORT MAP (
    clk          => mm_clk,
    rst          => mm_rst,
    start        => mm_start,
    -- i2c bus
    scl          => scl,
    sda          => sda,
    -- read results
    sens_evt     => OPEN,
    sens_err     => sens_err,
    sens_data    => sens_data
  );

  -- Temperature: 7 bits (1 bit per degree) plus sign. A faulty readout (never pulled down = all ones) 
  -- would produce -1 degrees so does not trigger a temperature alarm.
  -- temp_high is 7 bits, preceded by a '0' to allow only positive temps to be set. 
  temp_alarm <= '1' WHEN (SIGNED(sens_data(0)) > SIGNED('0' & temp_high)) ELSE '0';
    
END str;

