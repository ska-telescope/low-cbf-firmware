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

LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE work.i2c_dev_ltc4260_pkg.ALL;


ENTITY dev_ltc4260 IS
  GENERIC(
    g_address : STD_LOGIC_VECTOR(c_byte_w-2 DOWNTO 0);  -- 7 bit address, so without R/Wn bit
    g_R_sense : REAL := 0.01
  );
  PORT(
    scl               : INOUT STD_LOGIC := 'H';  -- Default output 'H' (instead of 'X' !)
    sda               : INOUT STD_LOGIC;
    ana_current_sense : IN    REAL;
    ana_volt_source   : IN    REAL;
    ana_volt_adin     : IN    REAL
  );
END dev_ltc4260;


ARCHITECTURE beh OF dev_ltc4260 IS

  -- Convert V sense into I sense
  CONSTANT c_I_unit_sense  : REAL := LTC4260_V_UNIT_SENSE / g_R_sense;  -- = 0.3 mV / 10 mOhm
  
  -- Digitized values
  SIGNAL dig_current_sense : INTEGER;
  SIGNAL dig_volt_source   : INTEGER;
  SIGNAL dig_volt_adin     : INTEGER;
  
  -- I2C control
  SIGNAL enable      : STD_LOGIC;  -- new access, may be write command or write data
  SIGNAL stop        : STD_LOGIC;  -- end of access
  SIGNAL wr_dat      : STD_LOGIC_VECTOR(c_byte_w-1 DOWNTO 0);  -- I2C write data
  SIGNAL wr_val      : STD_LOGIC;
  SIGNAL rd_dat      : STD_LOGIC_VECTOR(c_byte_w-1 DOWNTO 0);  -- I2C read data
  SIGNAL rd_req      : STD_LOGIC;

  SIGNAL cmd_en      : STD_LOGIC := '0';
  SIGNAL cmd         : STD_LOGIC_VECTOR(c_byte_w-1 DOWNTO 0);  -- device command
  
  -- LTC4260 registers (with power up defaults)
  SIGNAL control_reg : STD_LOGIC_VECTOR(c_byte_w-1 DOWNTO 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(LTC4260_CONTROL_DEFAULT, c_byte_w));
  
BEGIN

  -- Digitize the measured current and voltages
  dig_current_sense <= INTEGER(ana_current_sense / c_I_unit_sense);        -- e.g. 5.0 A / 0.03 = 166
  dig_volt_source   <= INTEGER(ana_volt_source / LTC4260_V_UNIT_SOURCE);   -- e.g. 48.0 V / 0.4 = 120
  dig_volt_adin     <= INTEGER(ana_volt_adin / LTC4260_V_UNIT_ADIN);
  
  i2c_slv_device : ENTITY work.i2c_slv_device
  GENERIC MAP (
    g_address => g_address
  )
  PORT MAP (
    scl     => scl,
    sda     => sda,
    en      => enable,
    p       => stop,
    wr_dat  => wr_dat,
    wr_val  => wr_val,
    rd_req  => rd_req,
    rd_dat  => rd_dat
  );

  -- Support PROTOCOL_WRITE_BYTE
  p_write : PROCESS (enable, wr_val)  -- first write byte is treated as command
  BEGIN
    IF RISING_EDGE(enable) THEN
      cmd_en <= '1';
    ELSIF FALLING_EDGE(enable) THEN
      cmd_en <= '0';
    END IF;
    IF RISING_EDGE(wr_val) THEN
      cmd_en <= '0';
      IF cmd_en='1' THEN
        cmd <= wr_dat;
      ELSE
        CASE TO_INTEGER(UNSIGNED(cmd)) IS
          WHEN LTC4260_CMD_CONTROL => control_reg <= wr_dat;
          WHEN OTHERS              => NULL;  -- no further model for write access
        END CASE;
      END IF;
    END IF;
  END PROCESS;

  -- Support PROTOCOL_READ_BYTE
  p_read : PROCESS (rd_req)
  BEGIN
    IF RISING_EDGE(rd_req) THEN
      CASE TO_INTEGER(UNSIGNED(cmd)) IS       -- only model read I and V
        WHEN LTC4260_CMD_CONTROL => rd_dat <= control_reg;
        WHEN LTC4260_CMD_ALERT   => rd_dat <= (OTHERS => '1');
        WHEN LTC4260_CMD_STATUS  => rd_dat <= (OTHERS => '1');
        WHEN LTC4260_CMD_FAULT   => rd_dat <= (OTHERS => '1');
        WHEN LTC4260_CMD_SENSE   => rd_dat <= STD_LOGIC_VECTOR(TO_UNSIGNED(dig_current_sense, c_byte_w));
        WHEN LTC4260_CMD_SOURCE  => rd_dat <= STD_LOGIC_VECTOR(TO_UNSIGNED(dig_volt_source,   c_byte_w));
        WHEN LTC4260_CMD_ADIN    => rd_dat <= STD_LOGIC_VECTOR(TO_UNSIGNED(dig_volt_adin,     c_byte_w));
        WHEN OTHERS              => rd_dat <= (OTHERS => '1');
      END CASE;
    END IF;
  END PROCESS;

END beh;
