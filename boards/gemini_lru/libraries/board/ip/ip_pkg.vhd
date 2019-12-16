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

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

PACKAGE ip_pkg IS

    COMPONENT system_clock
    PORT (clk_125       : OUT    STD_LOGIC;
          clk_100       : OUT    STD_LOGIC;
          clk_50        : OUT    STD_LOGIC;
          locked        : OUT    STD_LOGIC;
          resetn        : IN    STD_LOGIC;
          clk_in1       : IN     STD_LOGIC);
    END COMPONENT;

END ip_pkg;
