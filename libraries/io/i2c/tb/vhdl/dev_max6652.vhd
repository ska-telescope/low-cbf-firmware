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


ENTITY dev_max6652 IS
  GENERIC(
    g_address   : STD_LOGIC_VECTOR(6 DOWNTO 0)
  );
  PORT(
    scl         : IN    STD_LOGIC;
    sda         : INOUT STD_LOGIC;
    volt_2v5    : IN    INTEGER;       -- unit 13 mV
    volt_3v3    : IN    INTEGER;       -- unit 17 mV
    volt_12v    : IN    INTEGER;       -- unit 62 mV
    volt_vcc    : IN    INTEGER;       -- unit 26 mV
    temp        : IN    INTEGER        -- unit degrees C
  );
END dev_max6652;


ARCHITECTURE beh OF dev_max6652 IS

  CONSTANT c_cmd_read_2v5  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00100000";
  CONSTANT c_cmd_read_12v  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00100001";
  CONSTANT c_cmd_read_3v3  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00100010";
  CONSTANT c_cmd_read_vcc  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00100011";
  CONSTANT c_cmd_read_temp : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00100111";
  CONSTANT c_cmd_config    : STD_LOGIC_VECTOR(7 DOWNTO 0) := "01000000";

  SIGNAL enable    : STD_LOGIC;                       --new access, may be write command or write data
  SIGNAL stop      : STD_LOGIC;                       --end of access
  SIGNAL wr_dat    : STD_LOGIC_VECTOR(7 DOWNTO 0);    --I2C write data
  SIGNAL wr_val    : STD_LOGIC;
  SIGNAL rd_dat    : STD_LOGIC_VECTOR(7 DOWNTO 0);    --I2C read data
  SIGNAL rd_req    : STD_LOGIC;

  SIGNAL cmd_en     : STD_LOGIC := '0';
  SIGNAL cmd        : STD_LOGIC_VECTOR(7 DOWNTO 0);    --device command
  SIGNAL config_reg : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00001000";
  
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

  p_write : PROCESS (enable, wr_val)          --first write byte is treated as command
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
        CASE cmd IS
          WHEN c_cmd_config => config_reg <= wr_dat;
          WHEN OTHERS       => NULL;          --no further model for write access
        END CASE;
      END IF;
    END IF;
  END PROCESS;
    
  p_read : PROCESS (rd_req)
  BEGIN
    IF RISING_EDGE(rd_req) THEN
      CASE cmd IS                             --only model read V and read temp
        WHEN c_cmd_read_2v5  => rd_dat <= STD_LOGIC_VECTOR(TO_UNSIGNED(volt_2v5,8));
        WHEN c_cmd_read_12v  => rd_dat <= STD_LOGIC_VECTOR(TO_UNSIGNED(volt_12v,8));
        WHEN c_cmd_read_3v3  => rd_dat <= STD_LOGIC_VECTOR(TO_UNSIGNED(volt_3v3,8));
        WHEN c_cmd_read_vcc  => rd_dat <= STD_LOGIC_VECTOR(TO_UNSIGNED(volt_vcc,8));
        WHEN c_cmd_read_temp => rd_dat <= STD_LOGIC_VECTOR(TO_SIGNED(temp,8));
        WHEN c_cmd_config    => rd_dat <= config_reg;
        WHEN OTHERS          => rd_dat <= (OTHERS => '1');
      END CASE;
    END IF;
  END PROCESS;

END beh;
