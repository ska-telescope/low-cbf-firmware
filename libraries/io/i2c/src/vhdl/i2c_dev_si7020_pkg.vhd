-------------------------------------------------------------------------------
--
-- File Name: i2c_dev_sfp_pkg.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Thurs Oct 19 16:40:00 2017
-- Template Rev: 1.0
--
-- Title: I2C Register Definitions for Si7020 Humidity sensor 
--
-- Description: 
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

PACKAGE i2c_dev_si7020_pkg IS

   -- Serial ID Address
   CONSTANT SI7020_MES_HUMIDITY_HOLD               : NATURAL := 16#E5#;        
   CONSTANT SI7020_MES_HUMIDITY_NO_HOLD            : NATURAL := 16#F5#;        
   CONSTANT SI7020_MES_TEMP_HOLD                   : NATURAL := 16#E3#;        
   CONSTANT SI7020_MES_TEMP_NO_HOLD                : NATURAL := 16#F3#;        
   CONSTANT SI7020_READ_TEMP_OLD                   : NATURAL := 16#E0#;        
   
   CONSTANT SI7020_RESET                           : NATURAL := 16#FE#;        

   CONSTANT SI7020_WRITE_RHT_REG1                  : NATURAL := 16#E6#;        
   CONSTANT SI7020_READ_RHT_REG1                   : NATURAL := 16#E7#;        

   CONSTANT SI7020_READ_ID1A                       : NATURAL := 16#FA#;
   CONSTANT SI7020_READ_ID1B                       : NATURAL := 16#0F#;
   CONSTANT SI7020_READ_ID2A                       : NATURAL := 16#FC#;        
   CONSTANT SI7020_READ_ID2B                       : NATURAL := 16#C9#;        
   CONSTANT SI7020_READ_FW_REVA                    : NATURAL := 16#84#;        
   CONSTANT SI7020_READ_FW_REVB                    : NATURAL := 16#B8#;        

END PACKAGE;
