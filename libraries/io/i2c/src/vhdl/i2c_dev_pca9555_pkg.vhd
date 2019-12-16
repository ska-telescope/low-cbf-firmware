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

PACKAGE i2c_dev_pca9555_pkg IS


  CONSTANT PCA9555_REG_INPUT0        : NATURAL := 16#00#;
  CONSTANT PCA9555_REG_INPUT1        : NATURAL := 16#01#;

  CONSTANT PCA9555_REG_OUTPUT0       : NATURAL := 16#02#;
  CONSTANT PCA9555_REG_OUTPUT1       : NATURAL := 16#03#;

  CONSTANT PCA9555_REG_POLARITY0     : NATURAL := 16#04#;
  CONSTANT PCA9555_REG_POLARITY1     : NATURAL := 16#05#;

  CONSTANT PCA9555_REG_CONFIG0       : NATURAL := 16#06#;
  CONSTANT PCA9555_REG_CONFIG1       : NATURAL := 16#07#;


END PACKAGE;
