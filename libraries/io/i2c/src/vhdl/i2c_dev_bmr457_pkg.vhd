-------------------------------------------------------------------------------
--
-- File Name: i2c_dev_bmr457_pkg.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Thurs Oct 19 16:40:00 2017
-- Template Rev: 1.0
--
-- Title: I2C Register Definitions for BMR457
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

PACKAGE i2c_dev_bmr457_pkg IS

   CONSTANT BMR457_OPERATION                    : NATURAL := 16#01#;    -- RW Byte
   CONSTANT BMR457_ON_OFF_CONFIG                : NATURAL := 16#02#;    -- RW Byte
   CONSTANT BMR457_CLEAR_FAULTS                 : NATURAL := 16#03#;    -- Write Byte
   CONSTANT BMR457_WRITE_PROTECT                : NATURAL := 16#10#;    -- RW Byte
   CONSTANT BMR457_STORE_DEFAULT_ALL            : NATURAL := 16#11#;    -- Write Byte
   CONSTANT BMR457_RESTORE_DEFAULT_ALL          : NATURAL := 16#12#;    -- Write Byte
   CONSTANT BMR457_STORE_USER_ALL               : NATURAL := 16#15#;    -- Write Byte
   CONSTANT BMR457_RESTORE_USER_ALL             : NATURAL := 16#16#;    -- Write Byte
   
   CONSTANT BMR457_CAPABILITY                   : NATURAL := 16#19#;    -- RW Byte
   
   CONSTANT BMR457_VOUT_MODE                    : NATURAL := 16#20#;    -- Read Byte
   CONSTANT BMR457_VOUT_COMMAND                 : NATURAL := 16#21#;    -- RW Word
   CONSTANT BMR457_VOUT_TRIM                    : NATURAL := 16#22#;    -- RW Word
   CONSTANT BMR457_VOUT_CAL_OFFSET              : NATURAL := 16#23#;    -- RW Word
   CONSTANT BMR457_VOUT_MAX                     : NATURAL := 16#24#;    -- RW Word
   CONSTANT BMR457_VOUT_MARGIN_HIGH             : NATURAL := 16#25#;    -- RW Word
   CONSTANT BMR457_VOUT_MARGIN_LOW              : NATURAL := 16#26#;    -- RW Word
   CONSTANT BMR457_VOUT_TRANSITION_RATE         : NATURAL := 16#27#;    -- RW Word
   
   CONSTANT BMR457_SCALE_LOOP                   : NATURAL := 16#29#;    -- RW Word
   CONSTANT BMR457_SCALE_MONITOR                : NATURAL := 16#2a#;    -- RW Word
   
   CONSTANT BMR457_MAX_DUTY                     : NATURAL := 16#32#;    -- RW Word
   CONSTANT BMR457_FREQUENCY_SWITCH             : NATURAL := 16#32#;    -- RW Word
   
   CONSTANT BMR457_VIN_ON                       : NATURAL := 16#35#;    -- RW Word
   CONSTANT BMR457_VIN_OFF                      : NATURAL := 16#36#;    -- RW Word
   
   CONSTANT BMR457_IOUT_CAL_GAIN                : NATURAL := 16#38#;    -- RW Word
   CONSTANT BMR457_IOUT_CAL_OFFSET              : NATURAL := 16#39#;    -- RW Word

   CONSTANT BMR457_VOUT_OV_FAULT_LIMIT          : NATURAL := 16#40#;    -- RW Word
   CONSTANT BMR457_VOUT_OV_FAULT_RESPONSE       : NATURAL := 16#41#;    -- RW Byte
   CONSTANT BMR457_VOUT_OV_WARN_LIMIT           : NATURAL := 16#42#;    -- RW Word
   CONSTANT BMR457_VOUT_UV_WARN_LIMIT           : NATURAL := 16#43#;    -- RW Word
   CONSTANT BMR457_VOUT_UV_FAULT_LIMIT          : NATURAL := 16#44#;    -- RW Word
   CONSTANT BMR457_VOUT_UV_FAULT_RESPONSE       : NATURAL := 16#45#;    -- RW Byte

   CONSTANT BMR457_IOUT_OC_FAULT_LIMIT          : NATURAL := 16#46#;    -- RW Word
   CONSTANT BMR457_IOUT_OC_FAULT_RESPONSE       : NATURAL := 16#47#;    -- RW Word
   CONSTANT BMR457_IOUT_OC_LV_FAULT_LIMIT       : NATURAL := 16#48#;    -- RW Word
   CONSTANT BMR457_IOUT_OC_WARN_LIMIT           : NATURAL := 16#4a#;    -- RW Word
   
  
   CONSTANT BMR457_OT_FAULT_LIMIT               : NATURAL := 16#4F#;    -- RW Word
   CONSTANT BMR457_OT_FAULT_RESPONSE            : NATURAL := 16#50#;    -- RW Byte
   CONSTANT BMR457_OT_WARN_LIMIT                : NATURAL := 16#51#;    -- RW Word

   CONSTANT BMR457_UT_WARN_LIMIT                : NATURAL := 16#52#;    -- RW Word
   CONSTANT BMR457_UT_FAULT_LIMIT               : NATURAL := 16#53#;    -- RW Word
   CONSTANT BMR457_UT_FAULT_RESPONSE            : NATURAL := 16#54#;    -- RW Byte

   CONSTANT BMR457_VIN_OV_FAULT_LIMIT           : NATURAL := 16#55#;    -- RW Word
   CONSTANT BMR457_VIN_OV_FAULT_RESPONSE        : NATURAL := 16#56#;    -- RW Byte
   CONSTANT BMR457_VIN_OV_WARN_LIMIT            : NATURAL := 16#57#;    -- RW Word

   CONSTANT BMR457_VIN_UV_WARN_LIMIT            : NATURAL := 16#58#;    -- RW Word
   CONSTANT BMR457_VIN_UV_FAULT_LIMIT           : NATURAL := 16#59#;    -- RW Word
   CONSTANT BMR457_VIN_UV_FAULT_RESPONSE        : NATURAL := 16#5a#;    -- RW Byte

   CONSTANT BMR457_POWER_GOOD_ON                : NATURAL := 16#5e#;    -- RW Word
   CONSTANT BMR457_POWER_GOOD_OFF               : NATURAL := 16#5f#;    -- RW Word
   
   CONSTANT BMR457_TON_DELAY                    : NATURAL := 16#60#;    -- RW Word
   CONSTANT BMR457_TON_RISE                     : NATURAL := 16#61#;    -- RW Word
   CONSTANT BMR457_TON_MAX_FAULT_LIMIT          : NATURAL := 16#62#;    -- RW Word
   CONSTANT BMR457_TON_MAX_FAULT_RESPONSE       : NATURAL := 16#63#;    -- RW Byte
   CONSTANT BMR457_TOFF_DELAY                   : NATURAL := 16#64#;    -- RW Word
   CONSTANT BMR457_TOFF_FALL                    : NATURAL := 16#65#;    -- RW Word
   CONSTANT BMR457_TOFF_MAX_WARN_LIMIT          : NATURAL := 16#66#;    -- RW Word

   CONSTANT BMR457_STATUS_BYTE                  : NATURAL := 16#78#;    -- Read Byte
   CONSTANT BMR457_STATUS_WORD                  : NATURAL := 16#79#;    -- Read Word
   CONSTANT BMR457_STATUS_VOUT                  : NATURAL := 16#7a#;    -- Read Byte
   CONSTANT BMR457_STATUS_IOUT                  : NATURAL := 16#7b#;    -- Read Byte
   CONSTANT BMR457_STATUS_INPUT                 : NATURAL := 16#7c#;    -- Read Byte
   CONSTANT BMR457_STATUS_TEMPERATURE           : NATURAL := 16#7d#;    -- Read Byte
   CONSTANT BMR457_STATUS_CML                   : NATURAL := 16#7e#;    -- Read Byte
   CONSTANT BMR457_STATUS_OTHER                 : NATURAL := 16#7f#;    -- Read Byte

   CONSTANT BMR457_READ_VIN                     : NATURAL := 16#88#;    -- Read Word
   CONSTANT BMR457_READ_VOUT                    : NATURAL := 16#8B#;    -- Read Word
   CONSTANT BMR457_READ_IOUT                    : NATURAL := 16#8c#;    -- Read Word
   CONSTANT BMR457_READ_TEMPERATURE_1           : NATURAL := 16#8d#;    -- Read Word
   CONSTANT BMR457_READ_TEMPERATURE_2           : NATURAL := 16#8e#;    -- Read Word
   CONSTANT BMR457_READ_DUTY_CYCLE              : NATURAL := 16#94#;    -- Read Word
   CONSTANT BMR457_READ_FREQUENCY               : NATURAL := 16#95#;    -- Read Word

   CONSTANT BMR457_PMBUS_REVISION               : NATURAL := 16#98#;    -- Read Byte

   CONSTANT BMR457_MFR_ID                       : NATURAL := 16#99#;    -- RW Block 22bytes
   CONSTANT BMR457_MFR_MODEL                    : NATURAL := 16#9a#;    -- RW Block 14bytes
   CONSTANT BMR457_MFR_REVISION                 : NATURAL := 16#9b#;    -- RW Block 24bytes
   CONSTANT BMR457_MFR_LOCATION                 : NATURAL := 16#9c#;    -- RW Block 7bytes
   CONSTANT BMR457_MFR_DATE                     : NATURAL := 16#9d#;    -- RW Block 10bytes
   CONSTANT BMR457_MFR_SERIAL                   : NATURAL := 16#9e#;    -- RW Block 13bytes
   
   CONSTANT BMR457_USER_DATA_00                 : NATURAL := 16#b0#;    -- RW Block 23bytes

   CONSTANT BMR457_MFR_POWER_GOOD_POLARITY      : NATURAL := 16#d0#;    -- RW Word
   
   CONSTANT BMR457_MFR_VIN_SCALE_MONITOR        : NATURAL := 16#D3#;
   CONSTANT BMR457_MFR_SELECT_TEMP_SENSOR       : NATURAL := 16#DC#;
   CONSTANT BMR457_MFR_VIN_OFFSET               : NATURAL := 16#DD#;
   CONSTANT BMR457_MFR_VOUT_OFFSET_MONITOR      : NATURAL := 16#DE#;
   CONSTANT BMR457_MFR_TEMP_OFFSET_INT          : NATURAL := 16#E1#;
   CONSTANT BMR457_MFR_REMOTE_TEMP_CAL          : NATURAL := 16#E2#;
   CONSTANT BMR457_MFR_REMOTE_CTRL              : NATURAL := 16#E3#;
   CONSTANT BMR457_MFR_DEAD_BAND_DELAY          : NATURAL := 16#E5#;
   CONSTANT BMR457_MFR_TEMP_COEFF               : NATURAL := 16#E7#;
   CONSTANT BMR457_MFR_DEBUG_BUFF               : NATURAL := 16#F0#;
   CONSTANT BMR457_MFR_SETUP_PASSWORD           : NATURAL := 16#F1#;
   CONSTANT BMR457_MFR_DISABLE_SECURITY_ONCE    : NATURAL := 16#F2#;
   CONSTANT BMR457_MFR_DEAD_BAND_IOUT_THRESHOLD : NATURAL := 16#F3#;
   CONSTANT BMR457_MFR_SECURITY_BIT_MASK        : NATURAL := 16#F4#;
   CONSTANT BMR457_MFR_PRIMARY_TURN             : NATURAL := 16#F5#;
   CONSTANT BMR457_MFR_SECONDARY_TURN           : NATURAL := 16#F6#;
   CONSTANT BMR457_MFR_ILIM_SOFTSTART           : NATURAL := 16#F8#;
   CONSTANT BMR457_MFR_MULTI_PIN_CONFIG         : NATURAL := 16#F9#;
   CONSTANT BMR457_MFR_DEAD_BAND_VIN_THRESHOLD  : NATURAL := 16#FA#;
   CONSTANT BMR457_MFR_DEAD_BAND_VIN_IOUT_HYS   : NATURAL := 16#FB#;
   CONSTANT BMR457_MFR_RESTART                  : NATURAL := 16#FE#;

END PACKAGE;
