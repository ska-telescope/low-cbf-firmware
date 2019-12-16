-------------------------------------------------------------------------------
--
-- Copyright (C) 2009
-- ASTRON (Netherlands Institute for Radio Astronomy) <http://www.astron.nl/>
-- P.O.Box 2, 7990 AA Dwingeloo, The Netherlands
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-------------------------------------------------------------------------------

PACKAGE i2c_dev_max6652_pkg IS

  CONSTANT MAX6652_ADR_GND                 : NATURAL := 2#0010100#;
  CONSTANT MAX6652_ADR_VCC                 : NATURAL := 2#0010101#;
  CONSTANT MAX6652_ADR_SDA                 : NATURAL := 2#0010110#;
  CONSTANT MAX6652_ADR_SCL                 : NATURAL := 2#0010111#;  
  
  CONSTANT MAX6652_REG_READ_VIN_2_5        : NATURAL := 16#20#;
  CONSTANT MAX6652_REG_READ_VIN_12         : NATURAL := 16#21#;
  CONSTANT MAX6652_REG_READ_VIN_3_3        : NATURAL := 16#22#;
  CONSTANT MAX6652_REG_READ_VCC            : NATURAL := 16#23#;  
  CONSTANT MAX6652_REG_READ_TEMP           : NATURAL := 16#27#;
   
  CONSTANT MAX6652_REG_HIGH_LIMIT_VIN_2_5  : NATURAL := 16#2B#;
  CONSTANT MAX6652_REG_LOW_LIMIT_VIN_2_5   : NATURAL := 16#2C#;
  CONSTANT MAX6652_REG_HIGH_LIMIT_VIN_12   : NATURAL := 16#2D#;
  CONSTANT MAX6652_REG_LOW_LIMIT_VIN_12    : NATURAL := 16#2E#;
  CONSTANT MAX6652_REG_HIGH_LIMIT_VIN_3_3  : NATURAL := 16#2F#;
  CONSTANT MAX6652_REG_LOW_LIMIT_VIN_3_3   : NATURAL := 16#30#;  
  CONSTANT MAX6652_REG_HIGH_LIMIT_VCC      : NATURAL := 16#31#;  
  CONSTANT MAX6652_REG_LOW_LIMIT_VCC       : NATURAL := 16#32#;  
  CONSTANT MAX6652_REG_HOT_TEMP_LIMIT      : NATURAL := 16#39#;
  CONSTANT MAX6652_REG_HOT_TEMP_HIST       : NATURAL := 16#3A#;
  
  CONSTANT MAX6652_REG_CONFIG              : NATURAL := 16#40#;
  CONSTANT MAX6652_REG_INT_STATUS          : NATURAL := 16#41#;
  CONSTANT MAX6652_REG_INT_MASK            : NATURAL := 16#43#;  
  CONSTANT MAX6652_REG_DEV_ADR             : NATURAL := 16#48#;
  CONSTANT MAX6652_REG_TEMP_CONFIG         : NATURAL := 16#4B#;
  
  CONSTANT MAX6652_CONFIG_START            : NATURAL := 16#01#;
  CONSTANT MAX6652_CONFIG_INT_EN           : NATURAL := 16#02#;
  CONSTANT MAX6652_CONFIG_INT_CLR          : NATURAL := 16#04#;
  CONSTANT MAX6652_CONFIG_LINE_FREQ_SEL    : NATURAL := 16#10#;
  CONSTANT MAX6652_CONFIG_SHORT_CYCLE      : NATURAL := 16#20#;
  CONSTANT MAX6652_CONFIG_RESET            : NATURAL := 16#80#;  
  
END PACKAGE;
