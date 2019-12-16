-------------------------------------------------------------------------------
--
-- File Name: i2c_dev_bmr466_pkg.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Thurs Oct 19 16:40:00 2017
-- Template Rev: 1.0
--
-- Title: I2C Register Definitions for BMR466
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

PACKAGE i2c_dev_bmr466_pkg IS

   CONSTANT BMR466_OPERATION                    : NATURAL := 16#01#;    -- RW Byte
   CONSTANT BMR466_ON_OFF_CONFIG                : NATURAL := 16#02#;    -- RW Byte
   CONSTANT BMR466_CLEAR_FAULTS                 : NATURAL := 16#03#;    -- Write Byte
   CONSTANT BMR466_STORE_DEFAULT_ALL            : NATURAL := 16#11#;    -- Write Byte
   CONSTANT BMR466_RESTORE_DEFAULT_ALL          : NATURAL := 16#12#;    -- Write Byte
   CONSTANT BMR466_STORE_USER_ALL               : NATURAL := 16#15#;    -- Write Byte
   CONSTANT BMR466_RESTORE_USER_ALL             : NATURAL := 16#16#;    -- Write Byte
   
   CONSTANT BMR466_VOUT_MODE                    : NATURAL := 16#20#;    -- Read Byte
   CONSTANT BMR466_VOUT_COMMAND                 : NATURAL := 16#21#;    -- RW Word
   CONSTANT BMR466_VOUT_TRIM                    : NATURAL := 16#22#;    -- RW Word
   CONSTANT BMR466_VOUT_CAL_OFFSET              : NATURAL := 16#23#;    -- RW Word
   CONSTANT BMR466_VOUT_MAX                     : NATURAL := 16#24#;    -- RW Word
   CONSTANT BMR466_VOUT_MARGIN_HIGH             : NATURAL := 16#25#;    -- RW Word
   CONSTANT BMR466_VOUT_MARGIN_LOW              : NATURAL := 16#26#;    -- RW Word
   CONSTANT BMR466_VOUT_TRANSITION_RATE         : NATURAL := 16#27#;    -- RW Word
   CONSTANT BMR466_VOUT_DROOP                   : NATURAL := 16#28#;    -- RW Word
   
   CONSTANT BMR466_MAX_DUTY                     : NATURAL := 16#32#;    -- RW Word
   CONSTANT BMR466_FREQUENCY_SWITCH             : NATURAL := 16#32#;    -- RW Word
   CONSTANT BMR466_INTERLEAVE                   : NATURAL := 16#37#;    -- RW Word

   CONSTANT BMR466_IOUT_CAL_GAIN                : NATURAL := 16#38#;    -- RW Word
   CONSTANT BMR466_IOUT_CAL_OFFSET              : NATURAL := 16#39#;    -- RW Word

   CONSTANT BMR466_VOUT_OV_FAULT_LIMIT          : NATURAL := 16#40#;    -- RW Word
   CONSTANT BMR466_VOUT_OV_FAULT_RESPONSE       : NATURAL := 16#41#;    -- RW Byte
   CONSTANT BMR466_VOUT_UV_FAULT_LIMIT          : NATURAL := 16#44#;    -- RW Word
   CONSTANT BMR466_VOUT_UV_FAULT_RESPONSE       : NATURAL := 16#45#;    -- RW Byte

   CONSTANT BMR466_IOUT_OC_FAULT_LIMIT          : NATURAL := 16#46#;    -- RW Word
   CONSTANT BMR466_IOUT_UC_FAULT_LIMIT          : NATURAL := 16#4B#;    -- RW Word

   CONSTANT BMR466_OT_FAULT_LIMIT               : NATURAL := 16#4F#;    -- RW Word
   CONSTANT BMR466_OT_FAULT_RESPONSE            : NATURAL := 16#50#;    -- RW Byte
   CONSTANT BMR466_OT_WARN_LIMIT                : NATURAL := 16#51#;    -- RW Word

   CONSTANT BMR466_UT_WARN_LIMIT                : NATURAL := 16#52#;    -- RW Word
   CONSTANT BMR466_UT_FAULT_LIMIT               : NATURAL := 16#53#;    -- RW Word
   CONSTANT BMR466_UT_FAULT_RESPONSE            : NATURAL := 16#54#;    -- RW Byte

   CONSTANT BMR466_VIN_OV_FAULT_LIMIT           : NATURAL := 16#55#;    -- RW Word
   CONSTANT BMR466_VIN_OV_FAULT_RESPONSE        : NATURAL := 16#56#;    -- RW Byte
   CONSTANT BMR466_VIN_OV_WARN_LIMIT            : NATURAL := 16#57#;    -- RW Word

   CONSTANT BMR466_VIN_UV_WARN_LIMIT            : NATURAL := 16#58#;    -- RW Word
   CONSTANT BMR466_VIN_UV_FAULT_LIMIT           : NATURAL := 16#59#;    -- RW Word
   CONSTANT BMR466_VIN_UV_FAULT_RESPONSE        : NATURAL := 16#5a#;    -- RW Byte

   CONSTANT BMR466_POWER_GOOD_ON                : NATURAL := 16#5e#;    -- RW Word
   CONSTANT BMR466_TON_DELAY                    : NATURAL := 16#60#;    -- RW Word
   CONSTANT BMR466_TON_RISE                     : NATURAL := 16#61#;    -- RW Word
   CONSTANT BMR466_TOFF_DELAY                   : NATURAL := 16#64#;    -- RW Word
   CONSTANT BMR466_TOFF_FALL                    : NATURAL := 16#65#;    -- RW Word

   CONSTANT BMR466_STATUS_BYTE                  : NATURAL := 16#78#;    -- Read Byte
   CONSTANT BMR466_STATUS_WORD                  : NATURAL := 16#79#;    -- Read Word
   CONSTANT BMR466_STATUS_VOUT                  : NATURAL := 16#7a#;    -- Read Byte
   CONSTANT BMR466_STATUS_IOUT                  : NATURAL := 16#7b#;    -- Read Byte
   CONSTANT BMR466_STATUS_INPUT                 : NATURAL := 16#7c#;    -- Read Byte
   CONSTANT BMR466_STATUS_TEMPERATURE           : NATURAL := 16#7d#;    -- Read Byte
   CONSTANT BMR466_STATUS_CML                   : NATURAL := 16#7e#;    -- Read Byte
   CONSTANT BMR466_STATUS_MFR_SPECIFIC          : NATURAL := 16#80#;    -- Read Byte

   CONSTANT BMR466_READ_VIN                     : NATURAL := 16#88#;    -- Read Word
   CONSTANT BMR466_READ_VOUT                    : NATURAL := 16#8B#;    -- Read Word
   CONSTANT BMR466_READ_IOUT                    : NATURAL := 16#8c#;    -- Read Word
   CONSTANT BMR466_READ_TEMPERATURE_1           : NATURAL := 16#8d#;    -- Read Word
   CONSTANT BMR466_READ_DUTY_CYCLE              : NATURAL := 16#94#;    -- Read Word
   CONSTANT BMR466_READ_FREQUENCY               : NATURAL := 16#95#;    -- Read Word

   CONSTANT BMR466_PMBUS_REVISION               : NATURAL := 16#98#;    -- Read Byte

   CONSTANT BMR466_MFR_ID                       : NATURAL := 16#99#;    -- RW Block 22bytes
   CONSTANT BMR466_MFR_MODEL                    : NATURAL := 16#9a#;    -- RW Block 14bytes
   CONSTANT BMR466_MFR_REVISION                 : NATURAL := 16#9b#;    -- RW Block 24bytes
   CONSTANT BMR466_MFR_LOCATION                 : NATURAL := 16#9c#;    -- RW Block 7bytes
   CONSTANT BMR466_MFR_DATE                     : NATURAL := 16#9d#;    -- RW Block 10bytes
   CONSTANT BMR466_MFR_SERIAL                   : NATURAL := 16#9e#;    -- RW Block 13bytes
   
   CONSTANT BMR466_USER_DATA_00                 : NATURAL := 16#b0#;    -- RW Block 23bytes
   
   CONSTANT BMR466_AUTO_COMP_CONFIG             : NATURAL := 16#bc#;    -- RW Byte
   CONSTANT BMR466_AUTO_COMP_CONTROL            : NATURAL := 16#bd#;    -- Write Byte

   CONSTANT BMR466_DEADTIME_MAX                 : NATURAL := 16#bf#;    -- RW Word

   CONSTANT BMR466_MFR_CONFIG                   : NATURAL := 16#d0#;    -- RW Word
   CONSTANT BMR466_USER_CONFIG                  : NATURAL := 16#d1#;    -- RW Word
   CONSTANT BMR466_ISHARE_CONFIG                : NATURAL := 16#d2#;    -- RW Word
   CONSTANT BMR466_GCB_CONFIG                   : NATURAL := 16#d3#;    -- RW Word

   CONSTANT BMR466_POWER_GOOD_DELAY             : NATURAL := 16#d4#;    -- RW Word
   CONSTANT BMR466_PID_TAPS                     : NATURAL := 16#d5#;    -- RW Block 9bytes
   CONSTANT BMR466_INDUCTOR                     : NATURAL := 16#d6#;    -- RW Word
   CONSTANT BMR466_NLR_CONFIG                   : NATURAL := 16#d7#;    -- RW Block 4bytes
   CONSTANT BMR466_OVUV_CONFIG                  : NATURAL := 16#d8#;    -- RW Byte
   CONSTANT BMR466_XTEMP_SCALE                  : NATURAL := 16#d9#;    -- RW Word
   CONSTANT BMR466_XTEMP_OFFSET                 : NATURAL := 16#da#;    -- RW Word
   CONSTANT BMR466_VOUT_MAX_LIMIT               : NATURAL := 16#db#;    -- Read Word
   CONSTANT BMR466_TEMPCO_CONFIG                : NATURAL := 16#dc#;    -- RW Byte
   CONSTANT BMR466_DEADTIME                     : NATURAL := 16#dd#;    -- RW Word
   CONSTANT BMR466_DEADTIME_CONFIG              : NATURAL := 16#de#;    -- RW Word
   CONSTANT BMR466_SEQUENCE                     : NATURAL := 16#e0#;    -- RW Word
   CONSTANT BMR466_TRACK_CONFIG                 : NATURAL := 16#e1#;    -- RW Byte
   CONSTANT BMR466_GCB_GROUP                    : NATURAL := 16#e2#;    -- Read Block 4bytes
   CONSTANT BMR466_DEVICE_ID                    : NATURAL := 16#e4#;    -- Read Block 16bytes

   CONSTANT BMR466_MFR_IOUT_OC_FAULT_RESPONSE   : NATURAL := 16#e5#;    -- RW Byte
   CONSTANT BMR466_MFR_IOUT_UC_FAULT_RESPONSE   : NATURAL := 16#e6#;    -- RW Byte
   CONSTANT BMR466_IOUT_AVG_OC_FAULT_LIMIT      : NATURAL := 16#e7#;    -- RW Word
   CONSTANT BMR466_IOUT_AVG_UC_FAULT_LIMIT      : NATURAL := 16#e8#;    -- RW Word

   CONSTANT BMR466_MISC_CONFIG                  : NATURAL := 16#e9#;    -- RW Word
   CONSTANT BMR466_SNAPSHOT                     : NATURAL := 16#ea#;    -- Read Block 32bytes
   CONSTANT BMR466_BLANK_PARAMS                 : NATURAL := 16#eb#;    -- Read Block 16bytes
   CONSTANT BMR466_PHASE_CONTROL                : NATURAL := 16#f0#;    -- RW Byte
   CONSTANT BMR466_SNAPSHOT_CONTROL             : NATURAL := 16#f3#;    -- RW Byte
   CONSTANT BMR466_SECURITY_LEVEL               : NATURAL := 16#fa#;    -- Read Byte
   CONSTANT BMR466_PRIVATE_PASSWORD             : NATURAL := 16#fb#;    -- RW Block 9bytes
   CONSTANT BMR466_PUBLIC_PASSWORD              : NATURAL := 16#fc#;    -- RW Block 4bytes
   CONSTANT BMR466_UNPROTECT                    : NATURAL := 16#fd#;    -- RW Block 32bytes




  
  
END PACKAGE;
