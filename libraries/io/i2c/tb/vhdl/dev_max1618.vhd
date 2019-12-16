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

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.i2c_dev_max1617_pkg.ALL;


ENTITY dev_max1618 IS
  GENERIC(
    g_address   : STD_LOGIC_VECTOR(6 DOWNTO 0)
  );
  PORT(
    scl         : IN    STD_LOGIC;
    sda         : INOUT STD_LOGIC;
    temp        : IN    INTEGER
  );
END dev_max1618;


ARCHITECTURE beh OF dev_max1618 IS

  SIGNAL enable    : STD_LOGIC;                       --enable
  SIGNAL stop      : STD_LOGIC;                       --stop
  SIGNAL wr_dat    : STD_LOGIC_VECTOR(7 DOWNTO 0);    --I2C write data
  SIGNAL wr_val    : STD_LOGIC;
  SIGNAL rd_dat    : STD_LOGIC_VECTOR(7 DOWNTO 0);    --I2C read data
  SIGNAL rd_req    : STD_LOGIC;

  SIGNAL cmd_en    : STD_LOGIC := '0';
  SIGNAL cmd       : NATURAL;                         --device command
  
  SIGNAL config_reg   : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00001000";
  SIGNAL status_reg   : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
  SIGNAL temp_hi_reg  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "01111111";
  SIGNAL temp_lo_reg  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "11001001";
  
BEGIN

  i2c_slv_device : ENTITY work.i2c_slv_device
  GENERIC MAP (
    g_address => g_address
  )
  PORT MAP (
    scl   	=> scl,
    sda     => sda,
    en      => enable,
    p       => stop,
    wr_dat  => wr_dat,
    wr_val  => wr_val,
    rd_req  => rd_req,
    rd_dat  => rd_dat
  );
  
  -- Model only config thermostat mode
  status_reg(MAX1617_STATUS_RHIGH_BI) <= '1' WHEN temp >= UNSIGNED(temp_hi_reg) ELSE '0' WHEN temp <= UNSIGNED(temp_lo_reg);  -- ELSE latch
  status_reg(MAX1617_STATUS_RLOW_BI)  <= '1' WHEN temp <= UNSIGNED(temp_lo_reg) ELSE '0' WHEN temp >= UNSIGNED(temp_hi_reg);  -- ELSE latch
  
  p_write : PROCESS (enable, wr_val)  --first write byte is treated as command
  BEGIN
    IF RISING_EDGE(enable) THEN
      cmd_en <= '1';
    ELSIF FALLING_EDGE(enable) THEN
      cmd_en <= '0';
    END IF;
    IF RISING_EDGE(wr_val) THEN
      cmd_en <= '0';
      IF cmd_en='1' THEN
        cmd <= TO_INTEGER(UNSIGNED(wr_dat));
      ELSE
        CASE cmd IS  --only model some write cmd
          WHEN MAX1617_CMD_WRITE_CONFIG      => config_reg  <= wr_dat;
          WHEN MAX1617_CMD_WRITE_REMOTE_HIGH => temp_hi_reg <= wr_dat;
          WHEN MAX1617_CMD_WRITE_REMOTE_LOW  => temp_lo_reg <= wr_dat;
          WHEN OTHERS                        => NULL;
        END CASE;
      END IF;
    END IF;
  END PROCESS;
  
  p_read : PROCESS (rd_req)
  BEGIN
    IF RISING_EDGE(rd_req) THEN
      CASE cmd IS  --only model some read cmd
        WHEN MAX1617_CMD_READ_REMOTE_TEMP  => rd_dat <= STD_LOGIC_VECTOR(TO_SIGNED(temp,8));
        WHEN MAX1617_CMD_READ_CONFIG       => rd_dat <= config_reg;
        WHEN MAX1617_CMD_READ_STATUS       => rd_dat <= status_reg;
        WHEN MAX1617_CMD_READ_REMOTE_HIGH  => rd_dat <= temp_hi_reg;
        WHEN MAX1617_CMD_READ_REMOTE_LOW   => rd_dat <= temp_lo_reg;
        WHEN OTHERS                        => rd_dat <= (OTHERS => '1');
      END CASE;
    END IF;
  END PROCESS;

END beh;
