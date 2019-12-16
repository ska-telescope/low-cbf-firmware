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

PACKAGE i2c_dev_ltc4260_pkg IS

  -- Positive High Voltage Hot Swap Controller with I2C Compatible Monitoring
  
  CONSTANT LTC4260_ADR_MW                : NATURAL := 2#1011111#;  -- Mass write (broadcast)
  CONSTANT LTC4260_ADR_AR                : NATURAL := 2#0001100#;  -- Alert response
  CONSTANT LTC4260_ADR_LOW_LOW_LOW       : NATURAL := 2#1000100#;
  
  -- Use SMBUS Write Byte or Read Byte to access the command registers
  CONSTANT LTC4260_CMD_CONTROL           : NATURAL := 0;
  CONSTANT LTC4260_CMD_ALERT             : NATURAL := 1;
  CONSTANT LTC4260_CMD_STATUS            : NATURAL := 2;
  CONSTANT LTC4260_CMD_FAULT             : NATURAL := 3;
  CONSTANT LTC4260_CMD_SENSE             : NATURAL := 4;
  CONSTANT LTC4260_CMD_SOURCE            : NATURAL := 5;
  CONSTANT LTC4260_CMD_ADIN              : NATURAL := 6;
  
  CONSTANT LTC4260_V_UNIT_SENSE          : REAL := 0.0003;      --   0.3 mV over Rs (e.g. 10 mOhm) for current sense
  CONSTANT LTC4260_V_UNIT_SOURCE         : REAL := 0.4;         -- 400   mV supply voltage (e.g +48 V)
  CONSTANT LTC4260_V_UNIT_ADIN           : REAL := 0.01;        --  10   mV ADC
  
  CONSTANT LTC4260_CONTROL_DEFAULT       : NATURAL := 2#00011011#;  --   00 = power good
                                                                    -- &  0 = disable test mode
                                                                    -- &  1 = Enable massa write
                                                                    -- &  1 = turn FET On
                                                                    -- &  0 = Overcurrent Autoretry Disabled
                                                                    -- &  1 = Undervoltage Autoretry Enabled
                                                                    -- &  1 = Overvoltage Autoretry Enabled
  
END PACKAGE;