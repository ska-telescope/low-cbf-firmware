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
-- Description: List of I2C constants for KCU105 board
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

   -- SFP
   CONSTANT c_sfp_address                    : NATURAL := 16#50#;
   CONSTANT c_sfp_mon_address                : NATURAL := 16#51#;




END i2c_addresses_pkg;
