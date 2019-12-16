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

--14-6-2005 
--file i2cslave.vhd
--entity description of i2c slave for the RCU
--written by A.W. Gunst

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

ENTITY i2cslave IS
  GENERIC (
    g_rx_filter       : BOOLEAN := TRUE;  -- when TRUE enable I2C input SCL/SDA signal filtering 
    g_address         : STD_LOGIC_VECTOR(6 downto 0) := "0000001";  -- Slave I2C address
    g_nof_ctrl_bytes  : NATURAL := 3 --size of control register in bytes
  );

  PORT(
    clk         : IN  STD_LOGIC;                                      --system clock (clk freq >> SCL freq)
    SDA	        : INOUT STD_LOGIC;                                    --I2C Serial Data Line
    SCL         : IN  STD_LOGIC;                                      --I2C Serial Clock Line
    RST         : IN  STD_LOGIC;                                      --optional reset bit
    CTRL_REG    : OUT STD_LOGIC_VECTOR(8*g_nof_ctrl_bytes-1 downto 0) --ctrl for RCU control 
  );				
END i2cslave;


ARCHITECTURE rtl OF i2cslave IS

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

  type   state  is (reset,read_addr,read_data,write_data,acknowledge,nacknowledge,wacknowledge,wnacknowledge);
  
  -- Start of g_rx_filter related declarations
  CONSTANT c_meta_len   : NATURAL := 3;    -- use 3 FF to tackle meta stability between SCL and clk domain
  CONSTANT c_clk_cnt_w  : NATURAL := 5;    -- use lower effective clk rate
  CONSTANT c_line_len   : NATURAL := 7;    -- use FF line to filter SCL
                                           -- The maximum bit rate is 100 kbps, so 10 us SCL period. The pullup rise time
                                           -- of SCL and SDA is worst case (10k pullup) about 2 us, so a line_len of about
                                           -- 1 us suffices. At 200 MHz the line covers is 2^5 * 7 * 5 ns = 1.12 us of SCL,
                                           -- respectively 1.4 us at 160 MHz.
  CONSTANT c_version    : STD_LOGIC_VECTOR(3 downto 0) := "0001";

  SIGNAL clk_en         : STD_LOGIC := '0';
  SIGNAL nxt_clk_en     : STD_LOGIC;
  SIGNAL clk_cnt        : UNSIGNED(c_clk_cnt_w-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL nxt_clk_cnt    : UNSIGNED(clk_cnt'RANGE);
  
  SIGNAL scl_meta       : STD_LOGIC_VECTOR(0 TO c_meta_len-1);
  SIGNAL scl_line       : STD_LOGIC_VECTOR(0 TO c_line_len-1);
  SIGNAL scl_or         : STD_LOGIC;
  SIGNAL nxt_scl_or     : STD_LOGIC;
  SIGNAL scl_and        : STD_LOGIC;
  SIGNAL nxt_scl_and    : STD_LOGIC;
  SIGNAL scl_hi         : STD_LOGIC;
  SIGNAL scl_lo         : STD_LOGIC;
  SIGNAL scl_rx         : STD_LOGIC;
  SIGNAL nxt_scl_rx     : STD_LOGIC;
  
  SIGNAL sda_meta       : STD_LOGIC_VECTOR(0 TO c_meta_len-1);
  SIGNAL sda_line       : STD_LOGIC_VECTOR(0 TO c_line_len-1);
  SIGNAL sda_or         : STD_LOGIC;
  SIGNAL nxt_sda_or     : STD_LOGIC;
  SIGNAL sda_and        : STD_LOGIC;
  SIGNAL nxt_sda_and    : STD_LOGIC;
  SIGNAL sda_hi         : STD_LOGIC;
  SIGNAL sda_lo         : STD_LOGIC;
  SIGNAL sda_rx         : STD_LOGIC;
  SIGNAL nxt_sda_rx     : STD_LOGIC;
  -- End of g_rx_filter related declarations

  signal start          : STD_LOGIC;
  signal stop           : STD_LOGIC;
  
  signal streset        : STD_LOGIC; --bit to reset the start and stop flip flops
  signal latch_ctrl     : STD_LOGIC;
  signal latch_ctrl_dly : STD_LOGIC;
  signal ctrl_tmp       : STD_LOGIC_VECTOR(8*g_nof_ctrl_bytes-1 downto 0); --register to read and write to temporarily 
  signal i_ctrl_reg     : STD_LOGIC_VECTOR(8*g_nof_ctrl_bytes-1 downto 0); --output register 
  signal rw             : STD_LOGIC; --bit to indicate a read or a write    
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

  CTRL_REG <= i_ctrl_reg;

  no_rx : IF g_rx_filter = FALSE GENERATE
    scl_rx <= strong(SCL);
    sda_rx <= strong(SDA);
  END GENERATE;
  
  gen_rx : IF g_rx_filter = TRUE GENERATE
    p_clk : PROCESS(rst, clk)
    BEGIN
      IF RST='1' THEN
--         clk_cnt  <= (OTHERS => '0');
--         clk_en   <= '0';
        -- SCL
        scl_meta <= (OTHERS => '1');
        scl_line <= (OTHERS => '1');
        scl_or   <= '1';
        scl_and  <= '1';
        scl_hi   <= '1';
        scl_lo   <= '0';
        scl_rx   <= '1';
        -- SDA
        sda_meta <= (OTHERS => '1');
        sda_line <= (OTHERS => '1');
        sda_or   <= '1';
        sda_and  <= '1';
        sda_hi   <= '1';
        sda_lo   <= '0';
        sda_rx   <= '1';
      ELSIF RISING_EDGE(clk) THEN
        clk_cnt  <= clk_cnt + 1;
        clk_en   <= nxt_clk_en;
        IF clk_en='1' THEN
          -- SCL
          scl_meta <= strong(SCL) & scl_meta(0 TO scl_meta'HIGH-1);
          scl_line <= scl_meta(scl_meta'HIGH) & scl_line(0 TO scl_line'HIGH-1);
          scl_or   <= nxt_scl_or;
          scl_and  <= nxt_scl_and;
          scl_hi   <=     scl_or AND scl_and;
          scl_lo   <= NOT(scl_or OR  scl_and);
          scl_rx   <= nxt_scl_rx;
          -- SDA
          sda_meta <= strong(SDA) & sda_meta(0 TO sda_meta'HIGH-1);
          sda_line <= sda_meta(sda_meta'HIGH) & sda_line(0 TO sda_line'HIGH-1);
          sda_or   <= nxt_sda_or;
          sda_and  <= nxt_sda_and;
          sda_hi   <=     sda_or AND sda_and;
          sda_lo   <= NOT(sda_or OR  sda_and);
          sda_rx   <= nxt_sda_rx;
        END IF;
      END IF;
    END PROCESS;
    
    nxt_clk_en <= '1' WHEN SIGNED(clk_cnt) = -1 ELSE '0';

    -- SCL
    nxt_scl_or  <= '0' WHEN UNSIGNED(scl_line) =  0 ELSE '1';
    nxt_scl_and <= '1' WHEN   SIGNED(scl_line) = -1 ELSE '0';
    nxt_scl_rx  <= '1' WHEN scl_hi='1' ELSE '0' WHEN scl_lo='1' ELSE scl_rx;
    
    -- SDA
    nxt_sda_or  <= '0' WHEN UNSIGNED(sda_line) =  0 ELSE '1';
    nxt_sda_and <= '1' WHEN   SIGNED(sda_line) = -1 ELSE '0';
    nxt_sda_rx  <= '1' WHEN sda_hi='1' ELSE '0' WHEN sda_lo='1' ELSE sda_rx;
  END GENERATE;


  startcontrol: PROCESS(streset, RST, sda_rx)
  BEGIN
    IF streset='1' or RST = '1' THEN
      start<='0';
    ELSIF FALLING_EDGE(sda_rx) THEN
      IF scl_rx = '1' THEN
        start<='1';
      ELSE
        start<='0';
      END IF;
    END IF;
  END PROCESS;

  stopcontrol: PROCESS(streset, RST, sda_rx)
  BEGIN
    IF streset='1' or RST='1' THEN
      stop<='0';
    ELSIF RISING_EDGE(sda_rx) THEN
      IF scl_rx = '1' THEN
        stop<='1';
      ELSE
        stop<='0';
      END IF;
    END IF;
  END PROCESS;
  

  control: PROCESS(RST, scl_rx)  --i2c slave
  BEGIN
        
    IF RST='1' THEN
      --reset input connected to bit 17 of CTRL register, hence default for CTRL[17] must be '0' so RST will act as a spike.
      --if the spike is strong enough, then this works also in hardware for the rest of the logic connected to RST.

      -- Rising edge registers:
      streset        <= '0';
      latch_ctrl     <= '0';
      latch_ctrl_dly <= '0';
      ctrl_tmp       <= (OTHERS => '0');
      --i_ctrl_reg     <= X"0007c7"; --all supplies on, LBL 1a mode
      --i_ctrl_reg     <= X"00F979"; --LBL mode 1a
      --i_ctrl_reg     <= X"00FD79"; --LBL mode 1b
      --i_ctrl_reg     <= X"00FB7A"; --LBH mode 1a
      --i_ctrl_reg     <= X"00FF7A"; --LBH mode 1b
      --i_ctrl_reg     <= X"00FFA4"; --HBA mode 2
      --i_ctrl_reg     <= X"00FF94"; --HBA mode 3
      --i_ctrl_reg     <= X"00FF84"; --HBA mode 4
      --i_ctrl_reg     <= X"00F179"; --LBL mode 1a incl. 16 dB attenuation
      i_ctrl_reg     <= (OTHERS => '0');
      i_ctrl_reg(23 downto 20) <= c_version;
      rw             <= '0';
      ctrladr        <= (OTHERS => '0');
      bitcnt         <= 0;
      bytecnt        <= 0;
      current_state  <= reset;
      
      -- Falling edge registers:
      sda_int        <= 'H';
      tri_en         <= '0';
      wbitcnt        <= 0;
      wbytecnt       <= 0;
      zeroedge_state <= reset;
      
    ELSIF RISING_EDGE(scl_rx) THEN
    
      -- Latch CTRL register
      latch_ctrl_dly <= latch_ctrl;
      IF latch_ctrl_dly = '1' THEN --latch ctrl register after ack
        i_ctrl_reg <= ctrl_tmp;
        i_ctrl_reg(23 downto 20) <= c_version;
      END IF;
      
      -- Statemachine
      --   default assignments (others keep their value accross states during the access)
      streset       <= '0';
      latch_ctrl    <= '0';
      bitcnt        <= 0;
      current_state <= zeroedge_state;
      IF start='1' THEN
        streset       <= '1'; --reset start bit 
        ctrladr       <= ctrladr(5 downto 0) & sda_rx; --first commands of read_addr state should immediately be executed
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
              ctrladr <= ctrladr(5 downto 0) & sda_rx; --shift the data to the left
                                                       --shift a new bit in (MSB first)
              bitcnt <= bitcnt+1;
            ELSE
              rw <= sda_rx; --last bit indicates a read or a write
              IF ctrladr = g_address THEN
                current_state <= acknowledge;
              ELSE
                current_state <= reset;
              END IF;
            END IF;
          WHEN read_data =>
            IF bitcnt < 7 THEN
              ctrl_tmp(8*g_nof_ctrl_bytes-1 downto 1) <= ctrl_tmp(8*g_nof_ctrl_bytes-2 downto 0); --shift the data to the left
              ctrl_tmp(0) <= sda_rx;                                                              --shift a new bit in (MSB first)
              bitcnt <= bitcnt+1;
            ELSE --reading the last bit and going immediately to the ack state
              ctrl_tmp(8*g_nof_ctrl_bytes-1 downto 1) <= ctrl_tmp(8*g_nof_ctrl_bytes-2 downto 0); --shift the data to the left
              ctrl_tmp(0) <= sda_rx;                                                              --shift a new bit in (MSB first)
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
            IF sda_rx='0' THEN
              current_state <= write_data; --write went OK, continue writing bytes to the master
            ELSE
              current_state <= reset;      --write failed, so abort the transfer
            END IF;
          WHEN wnacknowledge =>
            --NACK is used to signal the end of a master read access. The slave can not known whether
            --the write transfer to the master was succesful and it does not need to know anyway.
            IF sda_rx='1' THEN
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

    ELSIF FALLING_EDGE(scl_rx) THEN
    
      -- Statemachine
      --   default assignments (others keep their value accross states during the access)
      sda_int        <= 'H';
      tri_en         <= '0'; 
      wbitcnt        <= 0;
      zeroedge_state <= current_state;
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
END rtl;
