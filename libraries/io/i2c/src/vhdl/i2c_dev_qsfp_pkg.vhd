-------------------------------------------------------------------------------
--
-- File Name: i2c_dev_sfp_pkg.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Thurs Oct 19 16:40:00 2017
-- Template Rev: 1.0
--
-- Title: I2C Register Definitions for QSFP+ 
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

PACKAGE i2c_dev_qsfp_pkg IS

   CONSTANT QSFP_IDENTIFER                   : NATURAL := 0;         -- 1 byte
   CONSTANT QSFP_STATUS                      : NATURAL := 1;         -- 2 bytes
   
   CONSTANT QSFP_INT_LOS                     : NATURAL := 3;         -- 1 byte
   CONSTANT QSFP_INT_FAULT                   : NATURAL := 4;         -- 1 byte
   CONSTANT QSFP_INT_TEMP                    : NATURAL := 6;         -- 1 byte
   CONSTANT QSFP_INT_VOLTAGE                 : NATURAL := 7;         -- 1 byte
   CONSTANT QSFP_INT_RX_POWER                : NATURAL := 9;         -- 2 bytes
   CONSTANT QSFP_INT_TX_BIAS                 : NATURAL := 11;        -- 2 bytes
   
   CONSTANT QSFP_MON_TEMPERATURE             : NATURAL := 22;        -- 2 bytes
   CONSTANT QSFP_MON_VOLTAGE                 : NATURAL := 26;        -- 2 bytes
   CONSTANT QSFP_MON_RX1_POWER               : NATURAL := 34;        -- 2 bytes
   CONSTANT QSFP_MON_RX2_POWER               : NATURAL := 36;        -- 2 bytes
   CONSTANT QSFP_MON_RX3_POWER               : NATURAL := 38;        -- 2 bytes
   CONSTANT QSFP_MON_RX4_POWER               : NATURAL := 40;        -- 2 bytes
   CONSTANT QSFP_MON_TX1_BIAS                : NATURAL := 42;        -- 2 bytes
   CONSTANT QSFP_MON_TX2_BIAS                : NATURAL := 44;        -- 2 bytes
   CONSTANT QSFP_MON_TX3_BIAS                : NATURAL := 46;        -- 2 bytes
   CONSTANT QSFP_MON_TX4_BIAS                : NATURAL := 48;        -- 2 bytes
   
   CONSTANT QSFP_CTRL_TX_DISABLE             : NATURAL := 86;        -- 1 byte
   CONSTANT QSFP_CTRL_RX_RATE                : NATURAL := 87;        -- 1 byte
   CONSTANT QSFP_CTRL_TX_RATE                : NATURAL := 88;        -- 1 byte
   CONSTANT QSFP_CTRL_RX4_APPLICATION        : NATURAL := 89;        -- 1 byte
   CONSTANT QSFP_CTRL_RX3_APPLICATION        : NATURAL := 90;        -- 1 byte
   CONSTANT QSFP_CTRL_RX2_APPLICATION        : NATURAL := 91;        -- 1 byte
   CONSTANT QSFP_CTRL_RX1_APPLICATION        : NATURAL := 92;        -- 1 byte
   CONSTANT QSFP_CTRL_POWER                  : NATURAL := 93;        -- 1 byte
   CONSTANT QSFP_CTRL_TX4_APPLICATION        : NATURAL := 94;        -- 1 byte
   CONSTANT QSFP_CTRL_TX3_APPLICATION        : NATURAL := 95;        -- 1 byte
   CONSTANT QSFP_CTRL_TX2_APPLICATION        : NATURAL := 96;        -- 1 byte
   CONSTANT QSFP_CTRL_TX1_APPLICATION        : NATURAL := 97;        -- 1 byte

   CONSTANT QSFP_INT_MASK_LOS                : NATURAL := 100;       -- 1 byte
   CONSTANT QSFP_INT_MASK_FAULT              : NATURAL := 101;       -- 1 byte
   CONSTANT QSFP_INT_MASK_TEMP               : NATURAL := 103;       -- 1 byte
   CONSTANT QSFP_INT_MASK_VOLTAGE            : NATURAL := 104;       -- 1 byte
   
   CONSTANT QSFP_PASSWORD_CHANGE             : NATURAL := 119;       -- 4 bytes
   CONSTANT QSFP_PASSWORD_ENTRY              : NATURAL := 123;       -- 4 bytes
   CONSTANT QSFP_PAGE_SELECT                 : NATURAL := 127;       -- 1 byte
   
   -- Upper Page 0
   CONSTANT QSFP_IDENTIFIER                  : NATURAL := 128;       -- 1 byte
   CONSTANT QSFP_EXT_IDENTIFIER              : NATURAL := 129;       -- 1 byte
   CONSTANT QSFP_CONNECTOR                   : NATURAL := 130;       -- 1 byte
   CONSTANT QSFP_TRANSCIEVER                 : NATURAL := 131;       -- 8 byte
   CONSTANT QSFP_ENCODING                    : NATURAL := 139;       -- 1 byte
   CONSTANT QSFP_BITRATE_NOMINAL             : NATURAL := 140;       -- 1 byte
   CONSTANT QSFP_RATEID                      : NATURAL := 141;       -- 1 byte
   CONSTANT QSFP_LENGTH_SMF                  : NATURAL := 142;       -- 1 byte
   CONSTANT QSFP_LENGTH_E_5UM                : NATURAL := 143;       -- 1 byte
   CONSTANT QSFP_LENGTH_50UM                 : NATURAL := 144;       -- 1 byte
   CONSTANT QSFP_LENGTH_625UM                : NATURAL := 145;       -- 1 byte
   CONSTANT QSFP_LENGTH_COPPER               : NATURAL := 146;       -- 1 byte   
   CONSTANT QSFP_DEVICE_TECH                 : NATURAL := 147;       -- 1 byte   
   CONSTANT QSFP_VENDOR_NAME                 : NATURAL := 148;       -- 16 bytes
   CONSTANT QSFP_EXT_TRANSCIEVER             : NATURAL := 164;       -- 1 bytes
   CONSTANT QSFP_VENDOR_OUI                  : NATURAL := 165;       -- 3 bytes
   CONSTANT QSFP_VENDOR_PN                   : NATURAL := 168;       -- 16 bytes
   CONSTANT QSFP_VENDOR_REV                  : NATURAL := 184;       -- 2 bytes
   CONSTANT QSFP_WAVELENGTH                  : NATURAL := 186;       -- 2 bytes
   CONSTANT QSFP_WAVELENGTH_TOLERANCE        : NATURAL := 188;       -- 2 bytes
   CONSTANT QSFP_MAX_CASE_TEMP               : NATURAL := 190;       -- 1 bytes
   
   CONSTANT QSFP_OPTIONS                     : NATURAL := 192;       -- 4 bytes
   CONSTANT QSFP_VENDOR_SERIAL               : NATURAL := 196;       -- 16 bytes
   CONSTANT QSFP_DATE_CODE                   : NATURAL := 212;       -- 8 bytes
   CONSTANT QSFP_MONITORING_TYPE             : NATURAL := 220;       -- 1 bytes
   CONSTANT QSFP_ENHANCED_OPTIONS            : NATURAL := 221;       -- 1 bytes
   CONSTANT QSFP_VENDOR_SPECIFIC             : NATURAL := 224;       -- 32 bytes


END PACKAGE;
