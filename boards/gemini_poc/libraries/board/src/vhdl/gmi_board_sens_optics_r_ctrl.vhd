-------------------------------------------------------------------------------
--
-- Copyright (C) 2012-2014
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

LIBRARY IEEE, common_lib, i2c_lib;
USE IEEE.std_logic_1164.ALL;
USE i2c_lib.i2c_smbus_pkg.ALL;
USE i2c_lib.i2c_dev_gmi_pkg.ALL;
USE common_lib.common_pkg.ALL;


ENTITY gmi_board_sens_optics_r_ctrl IS
  GENERIC (
    g_sim        : BOOLEAN := FALSE;
    g_nof_result : NATURAL := 40;
    g_temp_high  : NATURAL := 85
  );
  PORT (
    rst        : IN  STD_LOGIC;
    clk        : IN  STD_LOGIC;
    start      : IN  STD_LOGIC;  -- pulse to start the I2C sequence to read out the sensors
    out_dat    : OUT STD_LOGIC_VECTOR(c_byte_w-1 DOWNTO 0);
    out_val    : OUT STD_LOGIC;    
    in_dat     : IN  STD_LOGIC_VECTOR(c_byte_w-1 DOWNTO 0);
    in_val     : IN  STD_LOGIC;
    in_err     : IN  STD_LOGIC; 
    in_ack     : IN  STD_LOGIC;
    in_end     : IN  STD_LOGIC;
    result_val : OUT STD_LOGIC;
    result_err : OUT STD_LOGIC;
    result_dat : OUT t_slv_8_arr(0 TO g_nof_result-1)
  );
END ENTITY;


ARCHITECTURE rtl OF gmi_board_sens_optics_r_ctrl IS

  TYPE t_SEQUENCE IS ARRAY (NATURAL RANGE <>) OF NATURAL;
  
  -- The I2C bit rate is c_i2c_bit_rate = 50 [kbps], so 20 us period. Hence 20 us wait time for SDA is enough
  -- Assume clk <= 200 MHz, so 5 ns period. Hence timeout of 4000 is enough.
  CONSTANT c_timeout_sda : NATURAL := sel_a_b(g_sim, 0, 16);  -- wait 16 * 256 = 4096 clk periods
  
  CONSTANT c_SEQ : t_SEQUENCE := (
    SMBUS_SEND_BYTE,   I2C_GMI_L_OPTIC_MUX_ADR, 1,    -- set MUX to channel
    SMBUS_C_NOP,
    SMBUS_READ_BYTE,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_ID,
    --SMBUS_READ_BYTE,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_TEMP_LSB,
    SMBUS_READ_WORD,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_TEMP_MSB,
    --SMBUS_READ_BYTE,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_VOLT_LSB,
    SMBUS_READ_WORD,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_VOLT_MSB,

    SMBUS_SEND_BYTE,   I2C_GMI_L_OPTIC_MUX_ADR, 2,    -- set MUX to channel
    SMBUS_C_NOP,
    SMBUS_READ_BYTE,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_ID,
    --SMBUS_READ_BYTE,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_TEMP_LSB,
    SMBUS_READ_WORD,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_TEMP_MSB,
    --SMBUS_READ_BYTE,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_VOLT_LSB,
    SMBUS_READ_WORD,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_VOLT_MSB,

    SMBUS_SEND_BYTE,   I2C_GMI_L_OPTIC_MUX_ADR, 4,    -- set MUX to channel
    SMBUS_C_NOP,
    SMBUS_READ_BYTE,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_ID,
    --SMBUS_READ_BYTE,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_TEMP_LSB,
    SMBUS_READ_WORD,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_TEMP_MSB,
    --SMBUS_READ_BYTE,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_VOLT_LSB,
    SMBUS_READ_WORD,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_VOLT_MSB,

    SMBUS_SEND_BYTE,   I2C_GMI_L_OPTIC_MUX_ADR, 8,    -- set MUX to channel
    SMBUS_C_NOP,
    SMBUS_READ_BYTE,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_ID,
    --SMBUS_READ_BYTE,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_TEMP_LSB,
    SMBUS_READ_WORD,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_TEMP_MSB,
    --SMBUS_READ_BYTE,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_VOLT_LSB,
    SMBUS_READ_WORD,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_VOLT_MSB,

    SMBUS_SEND_BYTE,   I2C_GMI_L_OPTIC_MUX_ADR, 16,   -- set MUX to channel
    SMBUS_C_NOP,
    SMBUS_READ_BYTE,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_ID,
    --SMBUS_READ_BYTE,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_TEMP_LSB,
    SMBUS_READ_WORD,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_TEMP_MSB,
    --SMBUS_READ_BYTE,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_VOLT_LSB,
    SMBUS_READ_WORD,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_VOLT_MSB,

    SMBUS_SEND_BYTE,   I2C_GMI_L_OPTIC_MUX_ADR, 32,   -- set MUX to channel
    SMBUS_C_NOP,
    SMBUS_READ_BYTE,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_ID,
    --SMBUS_READ_BYTE,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_TEMP_LSB,
    SMBUS_READ_WORD,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_TEMP_MSB,
    --SMBUS_READ_BYTE,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_VOLT_LSB,
    SMBUS_READ_WORD,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_VOLT_MSB,

    SMBUS_SEND_BYTE,   I2C_GMI_L_OPTIC_MUX_ADR, 64,   -- set MUX to channel
    SMBUS_C_NOP,
    SMBUS_READ_BYTE,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_ID,
    --SMBUS_READ_BYTE,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_TEMP_LSB,
    SMBUS_READ_WORD,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_TEMP_MSB,
    --SMBUS_READ_BYTE,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_VOLT_LSB,
    SMBUS_READ_WORD,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_VOLT_MSB,

    SMBUS_SEND_BYTE,   I2C_GMI_L_OPTIC_MUX_ADR, 128,  -- set MUX to channel
    SMBUS_C_NOP,
    SMBUS_READ_BYTE,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_ID,
    --SMBUS_READ_BYTE,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_TEMP_LSB,
    SMBUS_READ_WORD,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_TEMP_MSB,
    --SMBUS_READ_BYTE,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_VOLT_LSB,
    SMBUS_READ_WORD,   I2C_GMI_L_OPTIC_QSFP_ADR, I2C_QSFP_READ_VOLT_MSB,

    SMBUS_C_SAMPLE_SDA, 0, c_timeout_sda, 0, 0,
    SMBUS_C_END,
    SMBUS_C_NOP
  );
    
  CONSTANT c_seq_len : NATURAL := c_SEQ'LENGTH-1;
  
  -- The protocol list c_SEQ yields a list of result bytes (result_dat)
  -- make sure that g_nof_result matches the number of result bytes
  
  SIGNAL start_reg       : STD_LOGIC;
  
  SIGNAL seq_cnt         : NATURAL RANGE 0 TO c_seq_len := c_seq_len;
  SIGNAL nxt_seq_cnt     : NATURAL;
  
  SIGNAL rx_cnt          : NATURAL RANGE 0 TO g_nof_result;
  SIGNAL nxt_rx_cnt      : NATURAL;
  
  SIGNAL rx_val          : STD_LOGIC;
  SIGNAL nxt_rx_val      : STD_LOGIC;
  SIGNAL rx_err          : STD_LOGIC;
  SIGNAL nxt_rx_err      : STD_LOGIC;
  SIGNAL rx_dat          : t_slv_8_arr(result_dat'RANGE);  
  SIGNAL nxt_rx_dat      : t_slv_8_arr(result_dat'RANGE); 
  SIGNAL nxt_result_val  : STD_LOGIC;
  SIGNAL nxt_result_err  : STD_LOGIC;
  SIGNAL i_result_dat    : t_slv_8_arr(result_dat'RANGE);  
  SIGNAL nxt_result_dat  : t_slv_8_arr(result_dat'RANGE);   
  
BEGIN

  result_dat <= i_result_dat;

  regs: PROCESS(rst, clk)
  BEGIN
    IF rst='1' THEN
      start_reg     <= '0';
      seq_cnt       <= c_seq_len;
      rx_cnt        <= 0;
      rx_val        <= '0';
      rx_err        <= '0';
      rx_dat        <= (OTHERS=>(OTHERS=>'0'));
      result_val    <= '0';
      result_err    <= '0';
      i_result_dat  <= (OTHERS=>(OTHERS=>'0'));
    ELSIF rising_edge(clk) THEN
      start_reg     <= start;
      seq_cnt       <= nxt_seq_cnt;
      rx_cnt        <= nxt_rx_cnt;
      rx_val        <= nxt_rx_val;
      rx_err        <= nxt_rx_err;
      rx_dat        <= nxt_rx_dat;
      result_val    <= nxt_result_val;
      result_err    <= nxt_result_err;
      i_result_dat  <= nxt_result_dat;
    END IF;
  END PROCESS;
  
  -- Issue the protocol list
  p_seq_cnt : PROCESS(seq_cnt, start_reg, in_ack)
  BEGIN
    nxt_seq_cnt <= seq_cnt;
    IF start_reg = '1' THEN
      nxt_seq_cnt <= 0;
    ELSIF seq_cnt<c_seq_len AND in_ack='1' THEN
      nxt_seq_cnt <= seq_cnt + 1;
    END IF;
  END PROCESS;

  out_dat <= STD_LOGIC_VECTOR(TO_UVEC(c_SEQ(seq_cnt), c_byte_w));
  out_val <= '1' WHEN seq_cnt<c_seq_len ELSE '0';
  
  -- Fill the rx_dat byte array
  p_rx_dat : PROCESS(start_reg, rx_err, in_err, rx_dat, rx_cnt, in_dat, in_val)
  BEGIN
    nxt_rx_err <= rx_err;
    IF start_reg = '1' THEN
      nxt_rx_err <= '0';
    ELSIF in_err='1' THEN
      nxt_rx_err <= '1';
    END IF;
    
    nxt_rx_dat <= rx_dat;
    nxt_rx_cnt <= rx_cnt;
    IF start_reg = '1' THEN
      nxt_rx_dat <= (OTHERS=>(OTHERS=>'0'));
      nxt_rx_cnt <= 0;
    ELSIF in_val='1' THEN
      nxt_rx_dat(rx_cnt) <= in_dat;
      nxt_rx_cnt         <= rx_cnt + 1;
    END IF;
  END PROCESS;

  nxt_rx_val <= in_end;
  
  -- Capture the complete rx_dat byte array
  nxt_result_val <= rx_val;
  nxt_result_err <= rx_err;
  nxt_result_dat <= rx_dat WHEN rx_val='1' ELSE i_result_dat;
    
END rtl;
