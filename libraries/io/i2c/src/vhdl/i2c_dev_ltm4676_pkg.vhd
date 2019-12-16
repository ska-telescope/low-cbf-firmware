-------------------------------------------------------------------------------
--
-- File Name: i2c_dev_ltm4676_pkg.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Thurs Oct 19 16:40:00 2017
-- Template Rev: 1.0
--
-- Title: I2C Register Definitions for LTM467X
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

PACKAGE i2c_dev_ltm4676_pkg IS

   CONSTANT LTM4676_PAGE                        : NATURAL := 16#00#;    -- RW Byte, set 0 for channel 0 or 1 for channel 1
   CONSTANT LTM4676_PAGE_PLUS_WRITE             : NATURAL := 16#05#;    -- Write Block
   CONSTANT LTM4676_PAGE_PLUS_READ              : NATURAL := 16#06#;    -- RW Block
   CONSTANT LTM4676_WRITE_PROTECT               : NATURAL := 16#10#;    -- RW Byte
   CONSTANT LTM4676_MFR_ADDRESS                 : NATURAL := 16#e6#;    -- RW Byte
   CONSTANT LTM4676_RAIL_ADDRESS                : NATURAL := 16#fa#;    -- RW Byte

   CONSTANT LTM4676_MFR_CHAN_CONFIG             : NATURAL := 16#d0#;    -- RW Byte
   CONSTANT LTM4676_CONFIG_ALL                  : NATURAL := 16#d1#;    -- RW Byte
   
   CONSTANT LTM4676_ON_OFF_CONFIG               : NATURAL := 16#02#;    -- RW Byte
   CONSTANT LTM4676_OPERATION                   : NATURAL := 16#01#;    -- RW Byte
   CONSTANT LTM4676_MFR_RESET                   : NATURAL := 16#fd#;    -- Write Byte
   
   CONSTANT LTM4676_MFR_PWM_MODE                : NATURAL := 16#d4#;    -- RW Byte
   CONSTANT LTM4676_MFR_PWM_CONFIG              : NATURAL := 16#f5#;    -- RW Byte
   CONSTANT LTM4676_FREQUENCY_SWITCH            : NATURAL := 16#33#;    -- RW Word
   
   CONSTANT LTM4676_VIN_OV_FAULT_LIMIT          : NATURAL := 16#55#;    -- RW Word
   CONSTANT LTM4676_VIN_UV_WARN_LIMIT           : NATURAL := 16#58#;    -- RW Word
   CONSTANT LTM4676_VIN_ON                      : NATURAL := 16#35#;    -- RW Word
   CONSTANT LTM4676_VIN_OFF                     : NATURAL := 16#36#;    -- RW Word
   
   CONSTANT LTM4676_VOUT_MODE                   : NATURAL := 16#20#;    -- R Byte
   CONSTANT LTM4676_VOUT_MAX                    : NATURAL := 16#24#;    -- RW Word
   CONSTANT LTM4676_VOUT_OV_FAULT_LIMIT         : NATURAL := 16#40#;    -- RW Word
   CONSTANT LTM4676_VOUT_OV_WARN_LIMIT          : NATURAL := 16#42#;    -- RW Word
   CONSTANT LTM4676_VOUT_MARGIN_HIGH            : NATURAL := 16#25#;    -- RW Word
   CONSTANT LTM4676_VOUT_COMMAND                : NATURAL := 16#21#;    -- RW Word
   CONSTANT LTM4676_VOUT_MARGIN_LOW             : NATURAL := 16#26#;    -- RW Word
   CONSTANT LTM4676_VOUT_UV_WARN_LIMIT          : NATURAL := 16#43#;    -- RW Word
   CONSTANT LTM4676_VOUT_UV_FAULT_LIMIT         : NATURAL := 16#44#;    -- RW Word
   CONSTANT LTM4676_MFR_VOUT_MAX                : NATURAL := 16#a5#;    -- Read Word
   
   CONSTANT LTM4676_MFR_IIN_OFFSET              : NATURAL := 16#e9#;    -- RW Word
   
   CONSTANT LTM4676_IOUT_CAL_GAIN               : NATURAL := 16#38#;    -- RW Word
   CONSTANT LTM4676_MFR_IOUT_CAL_GAIN_TC        : NATURAL := 16#f6#;    -- RW Word
   
   CONSTANT LTM4676_IIN_OC_WARN_LIMIT           : NATURAL := 16#5d#;    -- RW Word
   
   CONSTANT LTM4676_IOUT_OC_FAULT_LIMIT         : NATURAL := 16#46#;    -- RW Word
   CONSTANT LTM4676_IOUT_OC_WARN_LIMIT          : NATURAL := 16#4a#;    -- RW Word
   
   CONSTANT LTM4676_MFR_TEMP_1_GAIN             : NATURAL := 16#f8#;    -- RW Word
   CONSTANT LTM4676_MFR_TEMP_1_OFFSET           : NATURAL := 16#f9#;    -- RW Word

   CONSTANT LTM4676_OT_FAULT_LIMIT              : NATURAL := 16#4f#;    -- RW Word
   CONSTANT LTM4676_OT_WARN_LIMIT               : NATURAL := 16#51#;    -- RW Word
   CONSTANT LTM4676_UT_FAULT_LIMIT              : NATURAL := 16#53#;    -- RW Word
   
   CONSTANT LTM4676_TON_DELAY                   : NATURAL := 16#60#;    -- RW Word
   CONSTANT LTM4676_TON_RISE                    : NATURAL := 16#61#;    -- RW Word
   CONSTANT LTM4676_TON_MAX_FAULT_LIMIT         : NATURAL := 16#62#;    -- RW Word
   CONSTANT LTM4676_VOUT_TRANSITION_RATE        : NATURAL := 16#27#;    -- RW Word
   
   CONSTANT LTM4676_TOFF_DELAY                  : NATURAL := 16#64#;    -- RW Word
   CONSTANT LTM4676_TOFF_FALL                   : NATURAL := 16#65#;    -- RW Word
   CONSTANT LTM4676_TOFF_MAX_WARN_LIMIT         : NATURAL := 16#66#;    -- RW Word
   
   CONSTANT LTM4676_MFR_RESTART_DELAY           : NATURAL := 16#dc#;    -- RW Word
   
   CONSTANT LTM4676_MFR_RETRY_DELAY             : NATURAL := 16#d8#;    -- RW Word
   
   CONSTANT LTM4676_VIN_OV_FAULT_RESPONSE       : NATURAL := 16#56#;    -- RW Byte
   CONSTANT LTM4676_VOUT_OV_FAULT_RESPONSE      : NATURAL := 16#41#;    -- RW Byte
   CONSTANT LTM4676_VOUT_UV_FAULT_RESPONSE      : NATURAL := 16#45#;    -- RW Byte
   CONSTANT LTM4676_TON_MAX_FAULT_RESPONSE      : NATURAL := 16#63#;    -- RW Byte
   CONSTANT LTM4676_IOUT_OC_FAULT_RESPONSE      : NATURAL := 16#47#;    -- RW Byte
   CONSTANT LTM4676_MFR_OT_FAULT_RESPONSE       : NATURAL := 16#d6#;    -- RW Byte
   CONSTANT LTM4676_OT_FAULT_RESPONSE           : NATURAL := 16#50#;    -- RW Byte
   CONSTANT LTM4676_UT_FAULT_RESPONSE           : NATURAL := 16#54#;    -- RW Byte
   
   CONSTANT LTM4676_MFR_GPIO_PROPAGATE          : NATURAL := 16#d2#;    -- RW Word
   CONSTANT LTM4676_MFR_GPIO_RESPONSE           : NATURAL := 16#d5#;    -- RW Byte
   
   CONSTANT LTM4676_USER_DATA_00                : NATURAL := 16#b0#;    -- RW Word
   CONSTANT LTM4676_USER_DATA_01                : NATURAL := 16#b1#;    -- RW Word
   CONSTANT LTM4676_USER_DATA_02                : NATURAL := 16#b2#;    -- RW Word
   CONSTANT LTM4676_USER_DATA_03                : NATURAL := 16#b3#;    -- RW Word
   CONSTANT LTM4676_USER_DATA_04                : NATURAL := 16#b4#;    -- RW Word
   
   CONSTANT LTM4676_PMBUS_REVISION              : NATURAL := 16#98#;    -- R Byte
   CONSTANT LTM4676_CAPABILITY                  : NATURAL := 16#19#;    -- R Byte
   CONSTANT LTM4676_MFR_ID                      : NATURAL := 16#99#;    -- R String
   CONSTANT LTM4676_MFR_MODEL                   : NATURAL := 16#9a#;    -- R String
   CONSTANT LTM4676_MFR_SERIAL                  : NATURAL := 16#9e#;    -- R Block
   CONSTANT LTM4676_MFR_SPECIAL_ID              : NATURAL := 16#e7#;    -- R Word

   CONSTANT LTM4676_CLEAR_FAULTS                : NATURAL := 16#03#;    -- Write Byte
   CONSTANT LTM4676_SMBALERT_MASK               : NATURAL := 16#1b#;    -- RW Block
   CONSTANT LTM4676_MFR_CLEAR_PEAKS             : NATURAL := 16#e3#;    -- Write Byte
   CONSTANT LTM4676_STATUS_BYTE                 : NATURAL := 16#78#;    -- RW Byte
   CONSTANT LTM4676_STATUS_WORD                 : NATURAL := 16#79#;    -- RW Word
   CONSTANT LTM4676_STATUS_VOUT                 : NATURAL := 16#7a#;    -- RW Byte
   CONSTANT LTM4676_STATUS_IOUT                 : NATURAL := 16#7b#;    -- RW Byte
   CONSTANT LTM4676_STATUS_INPUT                : NATURAL := 16#7c#;    -- RW Byte
   CONSTANT LTM4676_STATUS_TEMPERATURE          : NATURAL := 16#7d#;    -- RW Byte
   CONSTANT LTM4676_STATUS_CML                  : NATURAL := 16#7e#;    -- RW Byte
   CONSTANT LTM4676_STATUS_MFR_SPECIFIC         : NATURAL := 16#80#;    -- RW Byte
   CONSTANT LTM4676_MFR_PADS                    : NATURAL := 16#e5#;    -- Read Word
   CONSTANT LTM4676_MFR_COMMON                  : NATURAL := 16#ef#;    -- Read Byte
   CONSTANT LTM4676_MFR_INFO                    : NATURAL := 16#b6#;    -- Read Word
   
   CONSTANT LTM4676_READ_VIN                    : NATURAL := 16#88#;    -- Read Word
   CONSTANT LTM4676_READ_VOUT                   : NATURAL := 16#8b#;    -- Read Word
   CONSTANT LTM4676_READ_IIN                    : NATURAL := 16#89#;    -- Read Word
   CONSTANT LTM4676_MFR_READ_IIN                : NATURAL := 16#ed#;    -- Read Word
   CONSTANT LTM4676_READ_IOUT                   : NATURAL := 16#8c#;    -- Read Word
   CONSTANT LTM4676_READ_TEMPERATURE_1          : NATURAL := 16#8d#;    -- Read Word
   CONSTANT LTM4676_READ_TEMPERATURE_2          : NATURAL := 16#8e#;    -- Read Word
   CONSTANT LTM4676_READ_DUTY_CYCLE             : NATURAL := 16#94#;    -- Read Word
   CONSTANT LTM4676_READ_POUT                   : NATURAL := 16#96#;    -- Read Word
   CONSTANT LTM4676_MFR_VOUT_PEAK               : NATURAL := 16#dd#;    -- Read Word
   CONSTANT LTM4676_MFR_VIN_PEAK                : NATURAL := 16#de#;    -- Read Word
   CONSTANT LTM4676_MFR_TEMPERATURE_1_PEAK      : NATURAL := 16#df#;    -- Read Word
   CONSTANT LTM4676_MFR_TEMPERATURE_2_PEAK      : NATURAL := 16#f4#;    -- Read Word
   CONSTANT LTM4676_MFR_IOUT_PEAK               : NATURAL := 16#d7#;    -- Read Word
   CONSTANT LTM4676_MFR_ADC_CONTROL             : NATURAL := 16#d8#;    -- RW Byte
   CONSTANT LTM4676_MFR_ADC_TELEMETRY_STATUS    : NATURAL := 16#da#;    -- RW Byte
   
   CONSTANT LTM4676_STORE_USER_ALL              : NATURAL := 16#15#;    -- Write Byte
   CONSTANT LTM4676_RESTORE_USER_ALL            : NATURAL := 16#16#;    -- Write Byte
   CONSTANT LTM4676_MFR_COMPARE_USER_ALL        : NATURAL := 16#f0#;    -- Write Byte
   
   CONSTANT LTM4676_MFR_FAULT_LOG               : NATURAL := 16#ee#;    -- Read Block
   CONSTANT LTM4676_MFR_FAULT_LOG_STORE         : NATURAL := 16#ea#;    -- Write Byte
   CONSTANT LTM4676_MFR_FAULT_LOG_CLEAR         : NATURAL := 16#ec#;    -- Write Byte
   
   CONSTANT LTM4676_MFR_EE_UNLOCK               : NATURAL := 16#bd#;    -- RW Byte
   CONSTANT LTM4676_MFR_EE_ERASE                : NATURAL := 16#be#;    -- RW Byte
   CONSTANT LTM4676_MFR_EE_DATA                 : NATURAL := 16#bf#;    -- RW Word
   

END PACKAGE;
