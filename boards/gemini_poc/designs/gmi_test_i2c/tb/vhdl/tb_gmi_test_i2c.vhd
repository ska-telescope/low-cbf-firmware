-------------------------------------------------------------------------------
--
-- Copyright (C) 2012
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

-- Purpose: Test bench for gmi_led.
-- Description:
--   The DUT can be targeted at unb 0, node 3 with the same Python scripts 
--   that are used on hardware. 
-- Usage:
--   On command line do:
--     > run_modelsim & (to start Modeslim)
--
--   In Modelsim do:
--     > lp gmi_led
--     > mk clean all (only first time to clean all libraries)
--     > mk all (to compile all libraries that are needed for gmi_led)
--     . load tb_gmi_led simulation by double clicking the tb_gmi_led icon
--     > as 10 (to view signals in Wave Window)
--     > run 100 us (or run -all)
--
--

LIBRARY IEEE, common_lib, gmi_board_lib, i2c_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE gmi_board_lib.gmi_board_pkg.ALL;
USE common_lib.tb_common_pkg.ALL;
USE i2c_lib.i2c_dev_unb2_pkg.ALL;
USE i2c_lib.i2c_commander_unb2_pmbus_pkg.ALL;




ENTITY tb_gmi_test_i2c IS
    GENERIC (
      g_design_name : STRING  := "gmi_test_i2c"
    );
END tb_gmi_test_i2c;

ARCHITECTURE tb OF tb_gmi_test_i2c IS

  CONSTANT c_sim          : BOOLEAN := TRUE;
  CONSTANT c_clk_e_period : TIME := 8 ns;  -- 125 MHz XO

  -- DUT
  SIGNAL clk_e_p          : STD_LOGIC := '0';
  SIGNAL clk_e_n          : STD_LOGIC;

  SIGNAL led_d            : STD_LOGIC;
  SIGNAL led_cs           : STD_LOGIC;
  SIGNAL led_sclk         : STD_LOGIC;

  SIGNAL sens_scl     : STD_LOGIC;
  SIGNAL sens_sda     : STD_LOGIC;
  SIGNAL optics_l_reset_n : STD_LOGIC;

  CONSTANT c_fpga_temp_address   : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0011000";  -- MAX1618 address LOW LOW
  CONSTANT c_fpga_temp           : INTEGER := 60;
  CONSTANT c_eth_temp_address    : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0101001";  -- MAX1618 address MID LOW
  CONSTANT c_eth_temp            : INTEGER := 40;
  CONSTANT c_hot_swap_address    : STD_LOGIC_VECTOR(6 DOWNTO 0) := "1000100";  -- LTC4260 address L L L
  CONSTANT c_hot_swap_R_sense    : REAL := 0.01;                               -- = 10 mOhm on UniBoard

  CONSTANT c_uniboard_current    : REAL := 5.0;   -- = assume 5.0 A on UniBoard
  CONSTANT c_uniboard_supply     : REAL := 48.0;  -- = assume 48.0 V on UniBoard
  CONSTANT c_uniboard_adin       : REAL := -1.0;  -- = NC on UniBoard

  CONSTANT c_pmbus_tcvr0_address : STD_LOGIC_VECTOR(6 DOWNTO 0) := TO_UVEC(I2C_UNB2_PMB_TCVR0_BMR461_ADR, 7);
BEGIN

  ----------------------------------------------------------------------------
  -- System setup
  ----------------------------------------------------------------------------
  clk_e_p <= NOT clk_e_p AFTER c_clk_e_period/2;
  clk_e_n <= NOT clk_e_p;
  
  sens_scl <= 'H'; -- pull up
  sens_sda <= 'H'; -- pull up
  ------------------------------------------------------------------------------
  -- DUT
  ------------------------------------------------------------------------------
  u_gmi_test_i2c : ENTITY work.gmi_test_i2c
    GENERIC MAP (
      g_sim         => c_sim,
      g_design_name => g_design_name
    )
    PORT MAP (
      clk_e_p     => clk_e_p,
      clk_e_n     => clk_e_n,

      led_din     => led_d,
      led_dout    => led_d,
      led_cs      => led_cs,
      led_sclk    => led_sclk,

      optics_l_scl     => sens_scl,
      optics_l_sda     => sens_sda,
      optics_l_reset_n => optics_l_reset_n
    );

  ------------------------------------------------------------------------------
  -- UniBoard sensors
  ------------------------------------------------------------------------------
  -- I2C slaves that are available for each FPGA
  u_fpga_temp : ENTITY i2c_lib.dev_max1618
  GENERIC MAP (
    g_address => c_fpga_temp_address
  )
  PORT MAP (
    scl  => sens_scl,
    sda  => sens_sda,
    temp => c_fpga_temp
  );

  -- I2C slaves that are available only via FPGA back node 3
  u_eth_temp : ENTITY i2c_lib.dev_max1618
  GENERIC MAP (
    g_address => c_eth_temp_address
  )
  PORT MAP (
    scl  => sens_scl,
    sda  => sens_sda,
    temp => c_eth_temp
  );

  u_power : ENTITY i2c_lib.dev_ltc4260
  GENERIC MAP (
    g_address => c_hot_swap_address,
    g_R_sense => c_hot_swap_R_sense
  )
  PORT MAP (
    scl               => sens_scl,
    sda               => sens_sda,
    ana_current_sense => c_uniboard_current,
    ana_volt_source   => c_uniboard_supply,
    ana_volt_adin     => c_uniboard_adin
  );

  u_pmbus_tcvr0 : ENTITY i2c_lib.dev_pmbus
  GENERIC MAP (
    g_address => c_pmbus_tcvr0_address
  )
  PORT MAP (
    scl       => sens_scl,
    sda       => sens_sda,
    vout_mode => 13,
    vin       => 92,
    vout      => 18,
    iout      => 12,
    vcap      => 0,
    temp      => 36
  );
END tb;

