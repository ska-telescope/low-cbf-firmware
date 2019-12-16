-------------------------------------------------------------------------------
--
-- File Name: i2c_dev_sfp_pkg.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Thurs Oct 19 16:40:00 2017
-- Template Rev: 1.0
--
-- Title: I2C Register Definitions for SFP+ 
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

PACKAGE i2c_dev_sfp_pkg IS

   -- Serial ID Address
   CONSTANT SFP_IDENTIFER                    : NATURAL := 0;         -- 1 byte
   CONSTANT SFP_EXT_IDENTIFER                : NATURAL := 1;         -- 1 byte
   CONSTANT SFP_CONNECTOR                    : NATURAL := 2;         -- 1 byte
   CONSTANT SFP_TRANSCIEVER                  : NATURAL := 3;         -- 8 byte
   CONSTANT SFP_ENCODING                     : NATURAL := 11;        -- 1 byte
   CONSTANT SFP_BITRATE_NOMINAL              : NATURAL := 12;        -- 1 byte
   CONSTANT SFP_RATEID                       : NATURAL := 13;        -- 1 byte
   CONSTANT SFP_LENGTH_9UM_KM                : NATURAL := 14;        -- 1 byte
   CONSTANT SFP_LENGTH_9UM                   : NATURAL := 15;        -- 1 byte
   CONSTANT SFP_LENGTH_50UM_OM2              : NATURAL := 16;        -- 1 byte
   CONSTANT SFP_LENGTH_625UM                 : NATURAL := 17;        -- 1 byte
   CONSTANT SFP_LENGTH_COPPER                : NATURAL := 18;        -- 1 byte   
   CONSTANT SFP_LENGTH_50UM                  : NATURAL := 19;        -- 1 byte   
   CONSTANT SFP_VENDOR_NAME                  : NATURAL := 20;        -- 16 bytes
   CONSTANT SFP_COMPATABILITY                : NATURAL := 36;        -- 1 bytes
   CONSTANT SFP_VENDOR_OUI                   : NATURAL := 37;        -- 3 bytes
   CONSTANT SFP_VENDOR_PN                    : NATURAL := 40;        -- 16 bytes
   CONSTANT SFP_VENDOR_REV                   : NATURAL := 56;        -- 4 bytes
   CONSTANT SFP_WAVELENGTH                   : NATURAL := 60;        -- 4 bytes
   
   CONSTANT SFP_OPTIONS                      : NATURAL := 64;        -- 2 bytes
   CONSTANT SFP_BITRATE_MAX                  : NATURAL := 66;        -- 1 byte
   CONSTANT SFP_BITRATE_MIN                  : NATURAL := 67;        -- 1 byte
   CONSTANT SFP_VENDOR_SERIAL                : NATURAL := 68;        -- 16 bytes
   CONSTANT SFP_DATE_CODE                    : NATURAL := 84;        -- 8 bytes
   CONSTANT SFP_MONITORING_TYPE              : NATURAL := 92;        -- 1 bytes
   CONSTANT SFP_ENHANCED_OPTIONS             : NATURAL := 93;        -- 1 bytes
   CONSTANT SFP_SFF_COMPLIANCE               : NATURAL := 94;        -- 1 bytes
   CONSTANT SFP_VENDOR_SPECIFIC              : NATURAL := 96;        -- 32 bytes


   -- Monitor Address
   CONSTANT SFP_MON_TEMP_HIGH_ALARM          : NATURAL := 0;         -- 2 bytes
   CONSTANT SFP_MON_TEMP_LOW_ALARM           : NATURAL := 2;         -- 2 bytes
   CONSTANT SFP_MON_TEMP_HIGH_WARN           : NATURAL := 4;         -- 2 bytes
   CONSTANT SFP_MON_TEMP_LOW_WARN            : NATURAL := 6;         -- 2 bytes

   CONSTANT SFP_MON_VOLTAGE_TEMP_HIGH_ALARM  : NATURAL := 8;         -- 2 bytes
   CONSTANT SFP_MON_VOLTAGE_TEMP_LOW_ALARM   : NATURAL := 10;        -- 2 bytes
   CONSTANT SFP_MON_VOLTAGE_TEMP_HIGH_WARN   : NATURAL := 12;        -- 2 bytes
   CONSTANT SFP_MON_VOLTAGE_TEMP_LOW_WARN    : NATURAL := 14;        -- 2 bytes

   CONSTANT SFP_MON_BIAS_TEMP_HIGH_ALARM     : NATURAL := 16;        -- 2 bytes
   CONSTANT SFP_MON_BIAS_TEMP_LOW_ALARM      : NATURAL := 18;        -- 2 bytes
   CONSTANT SFP_MON_BIAS_TEMP_HIGH_WARN      : NATURAL := 20;        -- 2 bytes
   CONSTANT SFP_MON_BIAS_TEMP_LOW_WARN       : NATURAL := 22;        -- 2 bytes

   CONSTANT SFP_MON_TX_POWER_TEMP_HIGH_ALARM : NATURAL := 24;        -- 2 bytes
   CONSTANT SFP_MON_TX_POWER_TEMP_LOW_ALARM  : NATURAL := 26;        -- 2 bytes
   CONSTANT SFP_MON_TX_POWER_TEMP_HIGH_WARN  : NATURAL := 28;        -- 2 bytes
   CONSTANT SFP_MON_TX_POWER_TEMP_LOW_WARN   : NATURAL := 30;        -- 2 bytes

   CONSTANT SFP_MON_RX_POWER_TEMP_HIGH_ALARM : NATURAL := 32;        -- 2 bytes
   CONSTANT SFP_MON_RX_POWER_TEMP_LOW_ALARM  : NATURAL := 34;        -- 2 bytes
   CONSTANT SFP_MON_RX_POWER_TEMP_HIGH_WARN  : NATURAL := 36;        -- 2 bytes
   CONSTANT SFP_MON_RX_POWER_TEMP_LOW_WARN   : NATURAL := 38;        -- 2 bytes

   CONSTANT SFP_MON_RX_POWER4_CAL            : NATURAL := 56;        -- 4 bytes
   CONSTANT SFP_MON_RX_POWER3_CAL            : NATURAL := 60;        -- 4 bytes
   CONSTANT SFP_MON_RX_POWER2_CAL            : NATURAL := 64;        -- 4 bytes
   CONSTANT SFP_MON_RX_POWER1_CAL            : NATURAL := 68;        -- 4 bytes
   CONSTANT SFP_MON_RX_POWER0_CAL            : NATURAL := 72;        -- 4 bytes

   CONSTANT SFP_MON_TX_SLOPE_CAL             : NATURAL := 76;        -- 2 bytes
   CONSTANT SFP_MON_TX_OFFSET_CAL            : NATURAL := 78;        -- 2 bytes
   CONSTANT SFP_MON_TX_POWER_SLOPE_CAL       : NATURAL := 80;        -- 2 bytes
   CONSTANT SFP_MON_TX_POWER_OFFSET_CAL      : NATURAL := 82;        -- 2 bytes

   CONSTANT SFP_MON_TEMP_SLOPE_CAL           : NATURAL := 84;        -- 2 bytes
   CONSTANT SFP_MON_TEMP_OFFSET_CAL          : NATURAL := 86;        -- 2 bytes

   CONSTANT SFP_MON_VOLTAGE_SLOPE_CAL        : NATURAL := 88;        -- 2 bytes
   CONSTANT SFP_MON_VOLTAGE_OFFSET_CAL       : NATURAL := 90;        -- 2 bytes

   CONSTANT SFP_MON_TEMPERATURE              : NATURAL := 96;        -- 2 bytes
   CONSTANT SFP_MON_VOLTAGE                  : NATURAL := 98;        -- 2 bytes
   CONSTANT SFP_MON_TX_BIAS                  : NATURAL := 100;       -- 2 bytes
   CONSTANT SFP_MON_TX_POWER                 : NATURAL := 102;       -- 2 bytes
   CONSTANT SFP_MON_RX_POWER                 : NATURAL := 104;       -- 2 bytes

   CONSTANT SFP_MON_STATUS                   : NATURAL := 110;       -- 1 byte

   CONSTANT SFP_MON_ALARM                    : NATURAL := 112;       -- 2 bytes
   CONSTANT SFP_MON_WARN                     : NATURAL := 116;       -- 2 bytes

   CONSTANT SFP_MON_EXT_STATUS               : NATURAL := 118;       -- 2 bytes

   CONSTANT SFP_MON_VENDOR                   : NATURAL := 120;       -- 8 bytes
   CONSTANT SFP_MON_USER                     : NATURAL := 128;       -- 120 bytes

END PACKAGE;
