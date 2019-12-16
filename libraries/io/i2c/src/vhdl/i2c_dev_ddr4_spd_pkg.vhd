-------------------------------------------------------------------------------
--
-- File Name: i2c_dev_bmr457_pkg.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Tues Mar 20 15:24:00 2017
-- Template Rev: 1.0
--
-- Title: I2C Register Definitions for DDR4 SPD
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

PACKAGE i2c_dev_ddr4_spd_pkg IS

   CONSTANT DDR4_SPD_SPD_SIZE                      : NATURAL := 16#00#;    -- R Byte
   CONSTANT DDR4_SPD_REVISION                      : NATURAL := 16#01#;    -- R Byte
   CONSTANT DDR4_SPD_DRAM_TYPE                     : NATURAL := 16#02#;    -- R Byte
   CONSTANT DDR4_SPD_MODULE_TYPE                   : NATURAL := 16#03#;    -- R Byte
   CONSTANT DDR4_SPD_DENSITY                       : NATURAL := 16#04#;    -- R Byte
   CONSTANT DDR4_SPD_ADDRESSING                    : NATURAL := 16#05#;    -- R Byte
   CONSTANT DDR4_SPD_PACKAGE                       : NATURAL := 16#06#;    -- R Byte
   CONSTANT DDR4_SPD_FEATURES                      : NATURAL := 16#07#;    -- R Byte
   CONSTANT DDR4_SPD_THERMAL_REFRESH_OPTIONS       : NATURAL := 16#08#;    -- R Byte
   CONSTANT DDR4_SPD_OPTIONS                       : NATURAL := 16#09#;    -- R Byte
   CONSTANT DDR4_SPD_SECONDARY_PACKAGE             : NATURAL := 16#0A#;    -- R Byte
   CONSTANT DDR4_SPD_NOMINAL_VOLTAGE               : NATURAL := 16#0B#;    -- R Byte
   CONSTANT DDR4_SPD_MODULE_ORGANISATION           : NATURAL := 16#0C#;    -- R Byte
   CONSTANT DDR4_SPD_BUS_WIDTH                     : NATURAL := 16#0D#;    -- R Byte
   CONSTANT DDR4_SPD_THERMAL_SENSOR                : NATURAL := 16#0E#;    -- R Byte
   CONSTANT DDR4_SPD_EXTENDED_MODULE_TYPE          : NATURAL := 16#0F#;    -- R Byte
   CONSTANT DDR4_SPD_TIMEBASES                     : NATURAL := 16#11#;    -- R Byte
   CONSTANT DDR4_SPD_MIN_CYCLE_TIME                : NATURAL := 16#12#;    -- R Byte
   CONSTANT DDR4_SPD_MAX_CYCLE_TIME                : NATURAL := 16#13#;    -- R Byte
   CONSTANT DDR4_SPD_CAS_SUPPORTED                 : NATURAL := 16#14#;    -- R 4 Bytes
   CONSTANT DDR4_SPD_MIN_CAS                       : NATURAL := 16#18#;    -- R Byte
   CONSTANT DDR4_SPD_RAS_TO_CAS                    : NATURAL := 16#19#;    -- R Byte
   CONSTANT DDR4_SPD_ROW_PRECHARGE                 : NATURAL := 16#1A#;    -- R Byte
   CONSTANT DDR4_SPD_TRAS_TRC_UPPER                : NATURAL := 16#1B#;    -- R Byte
   CONSTANT DDR4_SPD_TRAS_MIN                      : NATURAL := 16#1C#;    -- R Byte
   CONSTANT DDR4_SPD_TRC_MIN                       : NATURAL := 16#1D#;    -- R Byte
   CONSTANT DDR4_SPD_TRFC1_MIN                     : NATURAL := 16#1E#;    -- R Word
   CONSTANT DDR4_SPD_TRFC2_MIN                     : NATURAL := 16#20#;    -- R Word
   CONSTANT DDR4_SPD_TRFC4_MIN                     : NATURAL := 16#22#;    -- R Word
   CONSTANT DDR4_SPD_TFAW_MIN                      : NATURAL := 16#24#;    -- R Word
   CONSTANT DDR4_SPD_TRRD_S_MIN                    : NATURAL := 16#26#;    -- R Byte
   CONSTANT DDR4_SPD_TRRD_L_MIN                    : NATURAL := 16#27#;    -- R Byte
   CONSTANT DDR4_SPD_TCCD_L_MIN                    : NATURAL := 16#28#;    -- R Byte
   CONSTANT DDR4_SPD_tWR_MIN                       : NATURAL := 16#29#;    -- R Byte

   -- Upper Block
   CONSTANT DDR4_SPD_MODULE_MANUFACTURER_ID        : NATURAL := 16#40#;   -- R Word
   CONSTANT DDR4_SPD_MANUFACTURE_LOCATION          : NATURAL := 16#42#;   -- R Byte
   CONSTANT DDR4_SPD_MANUFACTURE_DATE              : NATURAL := 16#43#;   -- R Word
   CONSTANT DDR4_SPD_SERIAL_NUMBER                 : NATURAL := 16#45#;   -- R 4 Bytes
   CONSTANT DDR4_SPD_PART_NUMBER                   : NATURAL := 16#49#;   -- R 20 Byte
   CONSTANT DDR4_SPD_REVISION_CODE                 : NATURAL := 16#5d#;   -- R Byte
   CONSTANT DDR4_SPD_DRAM_MANUFACTURER_ID          : NATURAL := 16#5e#;   -- R Word
   CONSTANT DDR4_SPD_DRAM_STEPPING                 : NATURAL := 16#60#;   -- R Byte


   CONSTANT DDR4_TEMPERATURE_CAPABILITY            : NATURAL := 16#00#;    -- R word
   CONSTANT DDR4_TEMPERATURE_CONFIGURATION         : NATURAL := 16#01#;    -- RW word
   CONSTANT DDR4_TEMPERATURE_HIGH_LIMIT            : NATURAL := 16#02#;    -- RW word
   CONSTANT DDR4_TEMPERATURE_LOW_LIMIT             : NATURAL := 16#03#;    -- RW word
   CONSTANT DDR4_TEMPERATURE_TCRIT_LIMIT           : NATURAL := 16#04#;    -- RW word
   CONSTANT DDR4_TEMPERATURE_AMBIENT_TEMPERATURE   : NATURAL := 16#05#;    -- R word
   CONSTANT DDR4_TEMPERATURE_MANUFACTURER          : NATURAL := 16#06#;    -- R word
   CONSTANT DDR4_TEMPERATURE_REVISION              : NATURAL := 16#07#;    -- R word


END PACKAGE;
