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

   COMPONENT ila_0
      PORT (
   	   clk : IN STD_LOGIC;
   	   probe0 : IN STD_LOGIC_VECTOR(199 DOWNTO 0));
   END COMPONENT;


END ip_pkg;
