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


ENTITY dev_pca9555 IS
  GENERIC(
    g_address   : STD_LOGIC_VECTOR(6 DOWNTO 0)  -- PCA9555 slave address is "0100" & A2 & A1 & A0
  );
  PORT(
    scl         : IN    STD_LOGIC;
    sda         : INOUT STD_LOGIC;
    iobank0     : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    iobank1     : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END dev_pca9555;

ARCHITECTURE beh OF dev_pca9555 IS

  CONSTANT c_cmd_input_0   : NATURAL := 0;
  CONSTANT c_cmd_input_1   : NATURAL := 1;
  CONSTANT c_cmd_output_0  : NATURAL := 2;
  CONSTANT c_cmd_output_1  : NATURAL := 3;
  CONSTANT c_cmd_invert_0  : NATURAL := 4;
  CONSTANT c_cmd_invert_1  : NATURAL := 5;
  CONSTANT c_cmd_config_0  : NATURAL := 6;
  CONSTANT c_cmd_config_1  : NATURAL := 7;

  SIGNAL enable       : STD_LOGIC;                       --new access, may be write command or write data
  SIGNAL stop         : STD_LOGIC;                       --end of access
  SIGNAL wr_dat       : STD_LOGIC_VECTOR(7 DOWNTO 0);    --I2C write data
  SIGNAL wr_val       : STD_LOGIC;
  SIGNAL rd_dat       : STD_LOGIC_VECTOR(7 DOWNTO 0);    --I2C read data
  SIGNAL rd_req       : STD_LOGIC;

  SIGNAL cmd_en       : STD_LOGIC := '0';
  SIGNAL wr_cmd       : NATURAL;                         --device write command
  SIGNAL rd_cmd       : NATURAL;                         --device read command

  SIGNAL input_reg0   : STD_LOGIC_VECTOR(7 DOWNTO 0);    --device registers with powerup default value
  SIGNAL input_reg1   : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL output_reg0  : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '1');
  SIGNAL output_reg1  : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '1');
  SIGNAL invert_reg0  : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
  SIGNAL invert_reg1  : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
  SIGNAL config_reg0  : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '1');
  SIGNAL config_reg1  : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '1');

BEGIN

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

  -- First write byte is treated as command
  -- After sending data to one register, the next data byte will be sent to the other register in the pair
  -- There is no limitation on the number of data bytes sent in one write transmission
  -- Similar for reading data from a register.
  p_write : PROCESS (enable, wr_val)
  BEGIN
    IF RISING_EDGE(enable) THEN
      cmd_en <= '1';
    ELSIF FALLING_EDGE(enable) THEN
      cmd_en <= '0';
    END IF;
    IF RISING_EDGE(wr_val) THEN
      cmd_en <= '0';
      IF cmd_en='1' THEN
        wr_cmd <= TO_INTEGER(UNSIGNED(wr_dat));
      ELSE
        CASE wr_cmd IS
          WHEN c_cmd_input_0  => NULL;                   wr_cmd <= c_cmd_input_1;
          WHEN c_cmd_input_1  => NULL;                   wr_cmd <= c_cmd_input_0;
          WHEN c_cmd_output_0 => output_reg0 <= wr_dat;  wr_cmd <= c_cmd_output_1;
          WHEN c_cmd_output_1 => output_reg1 <= wr_dat;  wr_cmd <= c_cmd_output_0;
          WHEN c_cmd_invert_0 => invert_reg0 <= wr_dat;  wr_cmd <= c_cmd_invert_1;
          WHEN c_cmd_invert_1 => invert_reg1 <= wr_dat;  wr_cmd <= c_cmd_invert_0;
          WHEN c_cmd_config_0 => config_reg0 <= wr_dat;  wr_cmd <= c_cmd_config_1;
          WHEN c_cmd_config_1 => config_reg1 <= wr_dat;  wr_cmd <= c_cmd_config_0;
          WHEN OTHERS         => NULL;
        END CASE;
      END IF;
    END IF;
  END PROCESS;

  p_read : PROCESS (wr_val, rd_req)
  BEGIN
    IF RISING_EDGE(wr_val) THEN
      IF cmd_en='1' THEN
        rd_cmd <= TO_INTEGER(UNSIGNED(wr_dat));
      END IF;
    END IF;
    IF RISING_EDGE(rd_req) THEN
      CASE rd_cmd IS
        WHEN c_cmd_input_0  => rd_dat <= input_reg0;   rd_cmd <= c_cmd_input_1;
        WHEN c_cmd_input_1  => rd_dat <= input_reg1;   rd_cmd <= c_cmd_input_0;
        WHEN c_cmd_output_0 => rd_dat <= output_reg0;  rd_cmd <= c_cmd_output_1;
        WHEN c_cmd_output_1 => rd_dat <= output_reg1;  rd_cmd <= c_cmd_output_0;
        WHEN c_cmd_invert_0 => rd_dat <= invert_reg0;  rd_cmd <= c_cmd_invert_1;
        WHEN c_cmd_invert_1 => rd_dat <= invert_reg1;  rd_cmd <= c_cmd_invert_0;
        WHEN c_cmd_config_0 => rd_dat <= config_reg0;  rd_cmd <= c_cmd_config_1;
        WHEN c_cmd_config_1 => rd_dat <= config_reg1;  rd_cmd <= c_cmd_config_0;
        WHEN OTHERS         => rd_dat <= (OTHERS => '1');
      END CASE;
    END IF;
  END PROCESS;

  iobank0 <= (OTHERS => 'Z');
  iobank1 <= (OTHERS => 'Z');

  input_reg0 <= iobank0 xor invert_reg0;
  input_reg1 <= iobank1 xor invert_reg1;

  p_iobank : PROCESS(output_reg0, config_reg0, output_reg1, config_reg1)
  BEGIN
    FOR I IN 7 DOWNTO 0 LOOP
      IF config_reg0(I)='0' THEN iobank0(I) <= output_reg0(I); ELSE iobank0(I) <= 'Z'; END IF;
      IF config_reg1(I)='0' THEN iobank1(I) <= output_reg1(I); ELSE iobank1(I) <= 'Z'; END IF;
    END LOOP;
  END PROCESS;

END beh;
