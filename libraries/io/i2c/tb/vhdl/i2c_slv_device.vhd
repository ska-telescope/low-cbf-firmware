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
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_arith.ALL;

ENTITY i2c_slv_device IS
  GENERIC (
    g_address : STD_LOGIC_VECTOR(6 DOWNTO 0) -- Slave I2C address
  );
  PORT (
    scl     : IN    STD_LOGIC;                     --I2C Serial Clock Line
    sda     : INOUT STD_LOGIC;                     --I2C Serial Data Line
    en      : OUT   STD_LOGIC;                     --'1' : new access, wr_dat may be a cmd byte, '0' : wr_dat is a data byte, 
    p       : OUT   STD_LOGIC;                     --rising edge indicates end of access (stop)
    wr_dat  : OUT   STD_LOGIC_VECTOR(7 DOWNTO 0);
    wr_val  : OUT   STD_LOGIC;                     --rising edge indicates valid wr_dat
    rd_req  : OUT   STD_LOGIC;                     --rising edge request new rd_dat
    rd_dat  : IN    STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END i2c_slv_device;


ARCHITECTURE beh OF i2c_slv_device IS

  -- The code reuses the RTL code of i2cslave(rtl).vhd written by A.W. Gunst.
  
  FUNCTION strong( sl : IN STD_LOGIC ) RETURN STD_LOGIC IS
  BEGIN
    IF sl = 'H'THEN
      RETURN '1';
    ELSIF sl = 'L' THEN
      RETURN '0';
    ELSE
      RETURN sl;
    END IF;
  END;
  
  constant g_nof_ctrl_bytes : NATURAL := 1;

  TYPE t_dev_state IS (
    ST_IDLE,
    ST_CMD_OR_DATA,
    ST_READ_CMD,
    ST_READ_DATA
  );
  
  SIGNAL rs             : STD_LOGIC;                  --behavioral restart
  signal prev_rw        : STD_LOGIC := '0';           --behavioral
  signal rd_first       : STD_LOGIC := '0';           --behavioral
  signal rd_next        : STD_LOGIC := '0';           --behavioral
  SIGNAL dev_state      : t_dev_state := ST_IDLE;     --behavioral

  type   state  is (reset,read_addr,read_data,write_data,acknowledge,nacknowledge,wacknowledge,wnacknowledge);
  
  signal RST            : STD_LOGIC;                  --behavioral
  signal CTRL_REG       : STD_LOGIC_VECTOR(8*g_nof_ctrl_bytes-1 downto 0);
  
  signal start          : STD_LOGIC := '0';           --behavioral
  signal stop           : STD_LOGIC := '1';           --behavioral

  signal am             : STD_LOGIC := '0';           --behavioral address match
  
  signal streset        : STD_LOGIC; --bit to reset the start and stop flip flops
  signal latch_ctrl     : STD_LOGIC := '0';           --behavioral
  signal latch_ctrl_dly : STD_LOGIC := '0';           --behavioral
  signal ctrl_tmp       : STD_LOGIC_VECTOR(8*g_nof_ctrl_bytes-1 downto 0); --register to read and write to temporarily 
  signal i_ctrl_reg     : STD_LOGIC_VECTOR(8*g_nof_ctrl_bytes-1 downto 0); --output register 
  signal rw             : STD_LOGIC := '0';           --bit to indicate a read or a write, behavioral
  signal ctrladr        : STD_LOGIC_VECTOR(6 downto 0); --I2C address register
  signal bitcnt         : NATURAL RANGE 0 TO 7;                  --bitcnt for reading bits
  signal bytecnt        : NATURAL RANGE 0 TO g_nof_ctrl_bytes-1; --bytenct for reading bytes
  signal current_state  : state;
  
  signal tri_en         : STD_LOGIC; --signal to enable the tristate buffer for the SDA line
  signal sda_int        : STD_LOGIC; --internal SDA line to drive the SDA pin
  signal wbitcnt        : NATURAL RANGE 0 TO 8;                  --bitcnt for writing bits
  signal wbytecnt       : NATURAL RANGE 0 TO g_nof_ctrl_bytes-1; --bytenct for writing bytes
  signal zeroedge_state : state;
  
BEGIN

  -- Mostly behavioral code:

  RST    <= '0';
  wr_dat <= ctrl_tmp;
  
  p_start : PROCESS (start)
  BEGIN
    rs <= start;
    IF RISING_EDGE(start) THEN
      rs <= NOT stop;
    END IF;
  END PROCESS;
  
  rd_first <= rw AND NOT prev_rw;
  p_dev_read : PROCESS(SCL)
  BEGIN
    IF RISING_EDGE(SCL) THEN
      prev_rw <= rw;
    END IF;
  END PROCESS;
  
  p_dev_state : PROCESS (am, rs, stop)
  BEGIN
    CASE dev_state IS
      WHEN ST_IDLE =>
        IF RISING_EDGE(am) THEN
          dev_state <= ST_CMD_OR_DATA; --address match so expect cmd or data
        END IF;
      WHEN ST_CMD_OR_DATA =>
        IF RISING_EDGE(stop) THEN
          dev_state <= ST_IDLE;        --end of direct data access (write with or without cmd, or read without cmd)
        ELSIF FALLING_EDGE(rs) THEN
          dev_state <= ST_READ_CMD;    --read cmd so continue with address
        END IF;
      WHEN ST_READ_CMD => 
        IF RISING_EDGE(am) THEN
          dev_state <= ST_READ_DATA;   --address match so continue with read data
        ELSIF RISING_EDGE(stop) THEN
          dev_state <= ST_IDLE;        --no address match occured
        END IF;
      WHEN ST_READ_DATA =>
        IF RISING_EDGE(stop) THEN
          dev_state <= ST_IDLE;        --end of cmd read data access
        END IF;
    END CASE;
  END PROCESS;

  --output control signals
  en     <= '1'                 WHEN dev_state=ST_CMD_OR_DATA                           ELSE '0';
  wr_val <= latch_ctrl_dly      WHEN dev_state=ST_CMD_OR_DATA                           ELSE '0';
  rd_req <= rd_first OR rd_next WHEN dev_state=ST_CMD_OR_DATA OR dev_state=ST_READ_DATA ELSE '0';
  p      <= stop;  --output p is can be used to distinghuis beteen direct write data or cmd write data.
                   --  if at p n bytes were written, then it was a direct write,
                   --  else if at p 1+n bytes were written then it the first byte was the cmd.
  
  -- Mostly RTL code:
  
  CTRL_REG <= i_ctrl_reg;

  startcontrol:
  PROCESS(SDA,SCL,streset,RST)   
  BEGIN

    IF FALLING_EDGE(SDA) THEN
      IF strong(SCL) = '1' THEN
        start<='1';
      ELSE
        start<='0';
      END IF;
    END IF;

    IF streset='1' or RST = '1' THEN
      start<='0';
    END IF;
  
  END PROCESS;

  stopcontrol:
  PROCESS(SDA,SCL,streset,RST)
  BEGIN
  
    IF RISING_EDGE(SDA) THEN
      IF strong(SCL) = '1' THEN
        stop<='1';
      ELSE
        stop<='0';
      END IF;
    END IF;

    IF streset='1' or RST='1' THEN
      stop<='0';
    END IF;
  
  END PROCESS;

  control:  --i2c slave
  PROCESS(SCL,RST)
  BEGIN
        
    IF RST='1' THEN
      --reset input connected to bit 17 of CTRL register, hence default for CTRL[17] must be '0' so RST will act as a spike.
      --if the spike is strong enough, then this works also in hardware for the rest of the logic connected to RST.

      -- Rising edge registers:
      streset        <= '0';
      latch_ctrl     <= '0';
      latch_ctrl_dly <= '0';
      ctrl_tmp       <= (OTHERS => '0');
      i_ctrl_reg     <= (OTHERS => '0');
      rw             <= '0';
      ctrladr        <= (OTHERS => '0');
      bitcnt         <= 0;
      bytecnt        <= 0;
      current_state  <= reset;
      am             <= '0';
      
      -- Falling edge registers:
      sda_int        <= 'H';
      tri_en         <= '0';
      wbitcnt        <= 0;
      wbytecnt       <= 0;
      zeroedge_state <= reset;
      rd_next        <= '0';
      
    ELSIF RISING_EDGE(SCL) THEN
    
      -- Latch CTRL register
      latch_ctrl_dly <= latch_ctrl;
      i_ctrl_reg <= rd_dat;
      IF latch_ctrl='1' THEN --latch ctrl register
        i_ctrl_reg <= ctrl_tmp;
      END IF;
      
      -- Statemachine
      --   default assignments (others keep their value accross states during the access)
      streset       <= '0';
      latch_ctrl    <= '0';
      bitcnt        <= 0;
      current_state <= zeroedge_state;
      am            <= '0';
      IF start='1' THEN
        streset       <= '1'; --reset start bit 
        ctrladr       <= ctrladr(5 downto 0) & strong(SDA); --first commands of read_addr state should immediately be executed
        bitcnt        <= 1;
        bytecnt       <= 0;
        current_state <= read_addr;
      ELSIF stop='1' THEN     --only recognized if there occurs an SCL edge between I2C Stop and Start
        streset       <= '1'; --reset stop bit
        bytecnt       <= 0;
        current_state <= reset;
      ELSE
        CASE zeroedge_state IS
          WHEN reset => NULL; --only a Start gets the statemachines out of reset, all SCL edges are ignored until then
          WHEN read_addr =>
            IF bitcnt < 7 THEN
              ctrladr <= ctrladr(5 downto 0) & strong(SDA); --shift the data to the left
                                                            --shift a new bit in (MSB first)
              bitcnt <= bitcnt+1;
            ELSE
              rw <= strong(SDA); --last bit indicates a read or a write
              IF ctrladr = g_address THEN
                am <= '1';
                current_state <= acknowledge;
              ELSE
                current_state <= reset;
              END IF;
            END IF;
          WHEN read_data =>
            IF bitcnt < 7 THEN
              ctrl_tmp(8*g_nof_ctrl_bytes-1 downto 1) <= ctrl_tmp(8*g_nof_ctrl_bytes-2 downto 0); --shift the data to the left
              ctrl_tmp(0) <= strong(SDA);                                                         --shift a new bit in (MSB first)
              bitcnt <= bitcnt+1;
            ELSE --reading the last bit and going immediately to the ack state
              ctrl_tmp(8*g_nof_ctrl_bytes-1 downto 1) <= ctrl_tmp(8*g_nof_ctrl_bytes-2 downto 0); --shift the data to the left
              ctrl_tmp(0) <= strong(SDA);                                                         --shift a new bit in (MSB first)
              IF bytecnt < g_nof_ctrl_bytes-1 THEN --first bytes
                bytecnt <= bytecnt+1;
                current_state <= acknowledge;      --acknowledge the successfull read of a byte
              ELSE                                 --last byte 
                latch_ctrl <= '1';                 --latch at g_nof_ctrl_bytes-th byte (or a multiple of that, due to bytecnt wrap)
                bytecnt <= 0;                      --wrap byte count
                current_state <= acknowledge;      --acknowledge also for the last byte
              END IF;
            END IF;
          WHEN write_data => NULL;
          WHEN acknowledge => 
            IF rw='0' THEN
              current_state <= read_data;   --acknowledge state is one clock period active
            ELSE
              current_state <= write_data;
            END IF;
          WHEN nacknowledge => NULL;
            --When the master addresses another slave, then the statemachine directly goes into reset state.
            --The slave always answers with ACK on a master write data, so the nacknowledge state is never
            --reached.
          WHEN wacknowledge =>
            IF strong(SDA)='0' THEN
              current_state <= write_data; --write went OK, continue writing bytes to the master
            ELSE
              current_state <= reset;      --write failed, so abort the transfer
            END IF;
          WHEN wnacknowledge =>
            --NACK is used to signal the end of a master read access. The slave can not known whether
            --the write transfer to the master was succesful and it does not need to know anyway.
            IF strong(SDA)='1' THEN
              current_state <= reset;      --last write went OK, no more bytes to write to the master
            ELSE
              --By making current_state <= reset the CTRL register can only be read once in one transfer.
              --If more bytes are read then the master will see them as 0xFF (due to SDA pull up). By
              --making current_state <= write_data the CTRL register wraps if it is read more than once.
              --current_state <= reset;      --last write went OK, abort further transfer
              current_state <= write_data; --last write went OK, wrap and continue writing bytes to the master
            END IF;
          WHEN OTHERS =>
            current_state <= reset;
        END CASE;
      END IF;

    ELSIF FALLING_EDGE(SCL) THEN
    
      -- Statemachine
      --   default assignments (others keep their value accross states during the access)
      sda_int        <= 'H';
      tri_en         <= '0'; 
      wbitcnt        <= 0;
      zeroedge_state <= current_state;
      rd_next        <= '0';
      IF start='1' THEN
        wbytecnt       <= 0;
        zeroedge_state <= reset;
      ELSIF stop='1' THEN     --only recognized if there occurs an SCL edge between I2C Stop and Start
        wbytecnt       <= 0;
        zeroedge_state <= reset;
      ELSE
        CASE current_state IS
          WHEN reset => NULL;
          WHEN read_addr => NULL;
          WHEN read_data => NULL;
          WHEN write_data =>
            IF wbitcnt < 8 THEN
              tri_en <= '1'; --enable tri-state buffer to write SDA
              IF i_ctrl_reg(8*g_nof_ctrl_bytes-1-(8*wbytecnt+wbitcnt))='0' THEN
                sda_int <= '0'; --copy one bit to SDA (MSB first), else default to 'H'
              END IF;
              wbitcnt <= wbitcnt+1;
            ELSE
              IF wbytecnt < g_nof_ctrl_bytes-1 THEN --first bytes
                wbytecnt <= wbytecnt+1;
                zeroedge_state <= wacknowledge;     --wait till master acknowledges the successfull read of a byte
              ELSE                                  --last byte
                rd_next <= '1';
                wbytecnt <= 0;                      --wrap byte count
                zeroedge_state <= wnacknowledge;    --wait till master nacknowledges the successfull read of a byte
              END IF;
            END IF;
          WHEN acknowledge =>
            tri_en <= '1';   --enable tri-state buffer to write SDA
            sda_int <= '0';  --acknowledge data
          WHEN nacknowledge => NULL;
            --This state is never reached.
            --To answer an NACK the tri_en can remain '0', because the default SDA is 'H' due to the pull up.
          WHEN wacknowledge => NULL;
          WHEN wnacknowledge => NULL;
          WHEN OTHERS =>
            zeroedge_state <= reset;
        END CASE;
      END IF;
    END IF;
    
  END PROCESS;

  --control the tri state buffer
  SDA <= sda_int WHEN tri_en='1' ELSE 'Z';   
END beh;
