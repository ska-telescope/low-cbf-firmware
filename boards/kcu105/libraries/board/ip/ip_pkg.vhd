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

    component system_clock
    port (clk_125       : out    std_logic;
          clk_100       : out    std_logic;
          locked        : out    std_logic;
          reset         : in    std_logic;
          clk_in1_p     : in     std_logic;
          clk_in1_n     : in     std_logic);
    end component;

END ip_pkg;
