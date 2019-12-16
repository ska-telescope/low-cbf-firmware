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

PACKAGE i2c_dev_max1617_pkg IS

  -- Also applies to MAX1618
  --                   ADD0_ADD1
  CONSTANT MAX1617_ADR_LOW_LOW           : NATURAL := 2#0011000#;
  CONSTANT MAX1617_ADR_LOW_MID           : NATURAL := 2#0011001#;
  CONSTANT MAX1617_ADR_LOW_HIGH          : NATURAL := 2#0011010#;
  CONSTANT MAX1617_ADR_MID_LOW           : NATURAL := 2#0101001#;
  CONSTANT MAX1617_ADR_MID_MID           : NATURAL := 2#0101010#;
  CONSTANT MAX1617_ADR_MID_HIGH          : NATURAL := 2#0101011#;
  CONSTANT MAX1617_ADR_HIGH_LOW          : NATURAL := 2#1001100#;
  CONSTANT MAX1617_ADR_HIGH_MID          : NATURAL := 2#1001101#;
  CONSTANT MAX1617_ADR_HIGH_HIGH         : NATURAL := 2#1001110#;
  
  CONSTANT MAX1617_CMD_READ_LOCAL_TEMP   : NATURAL := 0;
  CONSTANT MAX1617_CMD_READ_REMOTE_TEMP  : NATURAL := 1;
  CONSTANT MAX1617_CMD_READ_STATUS       : NATURAL := 2;
  CONSTANT MAX1617_CMD_READ_CONFIG       : NATURAL := 3;
  CONSTANT MAX1617_CMD_READ_RATE         : NATURAL := 4;
  CONSTANT MAX1617_CMD_READ_LOCAL_HIGH   : NATURAL := 5;
  CONSTANT MAX1617_CMD_READ_LOCAL_LOW    : NATURAL := 6;
  CONSTANT MAX1617_CMD_READ_REMOTE_HIGH  : NATURAL := 7;
  CONSTANT MAX1617_CMD_READ_REMOTE_LOW   : NATURAL := 8;
  
  CONSTANT MAX1617_CMD_WRITE_CONFIG      : NATURAL := 9;
  CONSTANT MAX1617_CMD_WRITE_RATE        : NATURAL := 10;
  CONSTANT MAX1617_CMD_WRITE_LOCAL_HIGH  : NATURAL := 11;  
  CONSTANT MAX1617_CMD_WRITE_LOCAL_LOW   : NATURAL := 12;
  CONSTANT MAX1617_CMD_WRITE_REMOTE_HIGH : NATURAL := 13;
  CONSTANT MAX1617_CMD_WRITE_REMOTE_LOW  : NATURAL := 14;  
  
  CONSTANT MAX1617_CMD_ONE_SHOT          : NATURAL := 15;
  
  CONSTANT MAX1617_RATE_0_0625           : NATURAL := 0;
  CONSTANT MAX1617_RATE_0_125            : NATURAL := 1;
  CONSTANT MAX1617_RATE_0_25             : NATURAL := 2;
  CONSTANT MAX1617_RATE_0_5              : NATURAL := 3;
  CONSTANT MAX1617_RATE_1                : NATURAL := 4;
  CONSTANT MAX1617_RATE_2                : NATURAL := 5;
  CONSTANT MAX1617_RATE_4                : NATURAL := 6;
  CONSTANT MAX1617_RATE_8                : NATURAL := 7;  

  CONSTANT MAX1617_CONFIG_ID_BI          : NATURAL := 3;
  CONSTANT MAX1617_CONFIG_THERM_BI       : NATURAL := 4;
  CONSTANT MAX1617_CONFIG_POL_BI         : NATURAL := 5;
  CONSTANT MAX1617_CONFIG_RUN_STOP_BI    : NATURAL := 6;
  CONSTANT MAX1617_CONFIG_MASK_BI        : NATURAL := 7;
  
  CONSTANT MAX1617_CONFIG_ID             : NATURAL := 2**MAX1617_CONFIG_ID_BI;
  CONSTANT MAX1617_CONFIG_THERM          : NATURAL := 2**MAX1617_CONFIG_THERM_BI;
  CONSTANT MAX1617_CONFIG_POL            : NATURAL := 2**MAX1617_CONFIG_POL_BI;
  CONSTANT MAX1617_CONFIG_RUN_STOP       : NATURAL := 2**MAX1617_CONFIG_RUN_STOP_BI;
  CONSTANT MAX1617_CONFIG_MASK           : NATURAL := 2**MAX1617_CONFIG_MASK_BI;
  
  CONSTANT MAX1617_STATUS_BUSY_BI        : NATURAL := 7;
  CONSTANT MAX1617_STATUS_RHIGH_BI       : NATURAL := 4;
  CONSTANT MAX1617_STATUS_RLOW_BI        : NATURAL := 3;
  CONSTANT MAX1617_STATUS_DIODE_BI       : NATURAL := 2;
  
  CONSTANT MAX1617_STATUS_BUSY           : NATURAL := 2**MAX1617_STATUS_BUSY_BI;
  CONSTANT MAX1617_STATUS_RHIGH          : NATURAL := 2**MAX1617_STATUS_RHIGH_BI;
  CONSTANT MAX1617_STATUS_RLOW           : NATURAL := 2**MAX1617_STATUS_RLOW_BI;
  CONSTANT MAX1617_STATUS_DIODE          : NATURAL := 2**MAX1617_STATUS_DIODE_BI;

END PACKAGE;
