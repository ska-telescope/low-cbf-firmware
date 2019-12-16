-------------------------------------------------------------------------------
--
-- File Name: i2c_addresses_pkg.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Thurs Oct 19 16:40:00 2017
-- Template Rev: 1.0
--
-- Title: I2C Constants
--
-- Description: List of I2C constants for Gemini LRU
--
--
-- Compiler options:
--
--
-- Dependencies:
--
--
--
-------------------------------------------------------------------------------

LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;

PACKAGE i2c_addresses_pkg IS

   -- PMBus
   CONSTANT c_pmbus_vdd_corea_address        : NATURAL := 16#20#;
   CONSTANT c_pmbus_vdd_coreb_address        : NATURAL := 16#21#;
   CONSTANT c_pmbus_vdd_corec_address        : NATURAL := 16#22#;
   CONSTANT c_pmbus_vdd_cored_address        : NATURAL := 16#23#;
   CONSTANT c_pmbus_vdd0v85_address          : NATURAL := 16#40#; -- Channel 0
   CONSTANT c_pmbus_vdd0v9_address           : NATURAL := 16#40#; -- Channel 1
   CONSTANT c_pmbus_vdd1v2_tr_address        : NATURAL := 16#43#;
   CONSTANT c_pmbus_vdd1v2_hbm_address       : NATURAL := 16#44#;
   CONSTANT c_pmbus_vdd1v8_address           : NATURAL := 16#41#; -- Channel 0
   CONSTANT c_pmbus_vdd2v5_address           : NATURAL := 16#41#; -- Channel 1
   CONSTANT c_pmbus_vdd3v3_address           : NATURAL := 16#42#;

   CONSTANT c_pmbus_vdd12v_address           : NATURAL := 16#10#;

   -- MBO
   CONSTANT c_mboa_tx_address                : NATURAL := 16#50#;
   CONSTANT c_mboa_rx_address                : NATURAL := 16#40#;
   CONSTANT c_mbob_tx_address                : NATURAL := 16#51#;
   CONSTANT c_mbob_rx_address                : NATURAL := 16#41#;
   CONSTANT c_mboc_tx_address                : NATURAL := 16#52#;
   CONSTANT c_mboc_rx_address                : NATURAL := 16#42#;

   -- QSFP
   CONSTANT c_qsfp_address                   : NATURAL := 16#50#;

   -- SFP
   CONSTANT c_sfp_address                    : NATURAL := 16#50#;
   CONSTANT c_sfp_mon_address                : NATURAL := 16#51#;

   -- Humidity
   CONSTANT c_hum_address                    : NATURAL := 16#40#;

   -- DDR4
   CONSTANT c_ddr4_spd_address               : NATURAL := 16#50#;
   CONSTANT c_ddr4_spd_lower_address         : NATURAL := 16#36#;
   CONSTANT c_ddr4_spd_upper_address         : NATURAL := 16#37#;
   CONSTANT c_ddr4_temp_address              : NATURAL := 16#18#;

   -- Backplane
   CONSTANT c_bp_gpio_address                : NATURAL := 16#20#;

END i2c_addresses_pkg;
