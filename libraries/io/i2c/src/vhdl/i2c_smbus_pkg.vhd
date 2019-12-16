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
USE common_lib.common_pkg.ALL;

PACKAGE i2c_smbus_pkg IS

  -- Opcodes used in protocol definitions      
  TYPE OPCODE IS (
      -- I2C opcodes
      OP_LD_ADR,     -- LOAD ADDRESS REGISTER
      OP_LD_CNT,     -- LOAD COUNTER REGISTER     
      OP_WR_CNT,     -- WRITE COUNTER REGISTER
      OP_WR_ADR_WR,  -- WRITE ADDRESS FOR WRTTE
      OP_WR_ADR_RD,  -- WRITE ADDRESS FOR READ
      OP_WR_DAT,     -- WRITE BYTE OF DATA
      OP_WR_BLOCK,   -- WRITE BLOCK OF DATA
      OP_RD_ACK,     -- READ BYTE OF DATA AND ACKNOWLEDGE
      OP_RD_NACK,    -- READ BYTE DATA AND DO NOT ACKNOWLEDGE
      OP_RD_BLOCK,   -- READ BLOCK OF DATA      
      OP_STOP,       -- STOP
      -- Control opcodes
      OP_IDLE,       -- IDLE
      OP_END,        -- END OF LIST OF PROTOCOLS
      OP_LD_TIMEOUT, -- LOAD TIMEOUT VALUE
      OP_WAIT,       -- WAIT FOR TIMEOUT TIME UNITS
      OP_RD_SDA      -- SAMPLE SDA LINE
  );

  -- SMBUS protocol definitions  
  -- a protocol is implemented as fixed length array of opcodes  
  TYPE SMBUS_PROTOCOL IS  ARRAY (0 TO 15) OF OPCODE;

  -- The following protocols are as defined in the System Management Bus Specification v2.0

  -- Protocol: reserved
  CONSTANT PROTOCOL_RESERVED : SMBUS_PROTOCOL := ( OTHERS => OP_IDLE );    

  -- Protocol: write only the address + write bit
  CONSTANT PROTOCOL_WRITE_QUICK  : SMBUS_PROTOCOL := 
    ( OP_LD_ADR, OP_WR_ADR_WR, OP_STOP, OTHERS => OP_IDLE );
      
  -- Protocol: write only address + read bit
  CONSTANT PROTOCOL_READ_QUICK : SMBUS_PROTOCOL := 
    ( OP_LD_ADR, OP_WR_ADR_RD, OP_STOP, OTHERS => OP_IDLE );
      
  -- Protocol: send byte to specified adress
  CONSTANT PROTOCOL_SEND_BYTE : SMBUS_PROTOCOL := 
    ( OP_LD_ADR, OP_WR_ADR_WR, OP_WR_DAT, OP_STOP, OTHERS => OP_IDLE );    
  
  -- Protocol: receive byte from specified address
  CONSTANT PROTOCOL_RECEIVE_BYTE : SMBUS_PROTOCOL := 
    ( OP_LD_ADR, OP_WR_ADR_RD, OP_RD_NACK, OP_STOP, OTHERS => OP_IDLE );    
  
  -- Protocol: write byte to specified address and register
  CONSTANT PROTOCOL_WRITE_BYTE : SMBUS_PROTOCOL := 
    ( OP_LD_ADR, OP_WR_ADR_WR, OP_WR_DAT, OP_WR_DAT, OP_STOP, OTHERS => OP_IDLE );    
  
  -- Protocol: read byte from specified address and register
  CONSTANT PROTOCOL_READ_BYTE : SMBUS_PROTOCOL := 
    ( OP_LD_ADR, OP_WR_ADR_WR, OP_WR_DAT, OP_WR_ADR_RD, OP_RD_NACK, OP_STOP, 
      OTHERS => OP_IDLE );    
  
  -- Protocol: write word to specified address and register
  CONSTANT PROTOCOL_WRITE_WORD : SMBUS_PROTOCOL := 
    ( OP_LD_ADR, OP_WR_ADR_WR, OP_WR_DAT, OP_WR_DAT, OP_WR_DAT, OP_STOP,
      OTHERS => OP_IDLE );
  
  -- Protocol: read word from specified address and register
  CONSTANT PROTOCOL_READ_WORD : SMBUS_PROTOCOL := 
    ( OP_LD_ADR, OP_WR_ADR_WR, OP_WR_DAT, OP_WR_ADR_RD, OP_RD_ACK, OP_RD_NACK, 
      OP_STOP, OTHERS => OP_IDLE);

  -- Protocol: write block to specified address and register
  CONSTANT PROTOCOL_WRITE_BLOCK : SMBUS_PROTOCOL := 
    ( OP_LD_ADR, OP_WR_ADR_WR, OP_WR_DAT, OP_LD_CNT, OP_WR_CNT, OP_WR_BLOCK, 
      OP_STOP, OTHERS => OP_IDLE);
  
  -- Protocol: read block to specified address and register
  CONSTANT PROTOCOL_READ_BLOCK : SMBUS_PROTOCOL := 
    ( OP_LD_ADR, OP_WR_ADR_WR, OP_WR_DAT, OP_WR_ADR_RD, OP_RD_ACK, OP_LD_CNT, 
      OP_RD_BLOCK, OP_STOP, OTHERS => OP_IDLE);    

  -- Protocol process call
  CONSTANT PROTOCOL_PROCESS_CALL : SMBUS_PROTOCOL := 
    ( OP_LD_ADR, OP_WR_ADR_WR, OP_WR_DAT, OP_WR_DAT, OP_WR_DAT,
      OP_LD_ADR, OP_WR_ADR_WR, OP_WR_DAT, OP_WR_ADR_RD, OP_RD_ACK, OP_RD_NACK, 
      OP_STOP, OTHERS => OP_IDLE);

  -- The following protocols are additional custom protocols

  -- Protocol: write block to specified address and register, do not write count
  CONSTANT PROTOCOL_C_WRITE_BLOCK_NO_CNT : SMBUS_PROTOCOL := 
    ( OP_LD_ADR, OP_WR_ADR_WR, OP_WR_DAT, OP_LD_CNT, OP_WR_BLOCK, OP_STOP,
      OTHERS => OP_IDLE);
  
  -- Protocol: read block to specified address and register, do not expect count
  CONSTANT PROTOCOL_C_READ_BLOCK_NO_CNT : SMBUS_PROTOCOL := 
    ( OP_LD_ADR, OP_WR_ADR_WR, OP_WR_DAT, OP_WR_ADR_RD, OP_LD_CNT, OP_RD_BLOCK,
      OP_STOP, OTHERS => OP_IDLE);
      
  -- Protocol: send one or more bytes to specified address
  CONSTANT PROTOCOL_C_SEND_BLOCK : SMBUS_PROTOCOL := 
    ( OP_LD_ADR, OP_WR_ADR_WR, OP_LD_CNT, OP_WR_BLOCK, OP_STOP, OTHERS => OP_IDLE );    

  -- Protocol: receive one or more bytes from specified address
  CONSTANT PROTOCOL_C_RECEIVE_BLOCK : SMBUS_PROTOCOL := 
    ( OP_LD_ADR, OP_WR_ADR_RD, OP_LD_CNT, OP_RD_BLOCK, OP_STOP, OTHERS => OP_IDLE );    

  -- Protocol: no operation
  CONSTANT PROTOCOL_C_NOP : SMBUS_PROTOCOL := ( OTHERS => OP_IDLE );    
  
  -- Protocol: wait for the specified number (32 bit long) of delay units
  CONSTANT PROTOCOL_C_WAIT : SMBUS_PROTOCOL := 
    ( OP_LD_TIMEOUT, OP_LD_TIMEOUT, OP_LD_TIMEOUT, OP_LD_TIMEOUT, OP_WAIT, OTHERS => OP_IDLE );    
  
  -- Protocol: signal end of sequence of protocols
  CONSTANT PROTOCOL_C_END : SMBUS_PROTOCOL := 
    ( OP_END, OTHERS => OP_IDLE );    

  -- Protocol: sample SDA line
  -- . Use protocol sample SDA after sufficient WAIT timeout or stand alone to ensure that the slow SDA has been pulled up
  CONSTANT PROTOCOL_C_SAMPLE_SDA : SMBUS_PROTOCOL := 
    ( OP_LD_TIMEOUT, OP_LD_TIMEOUT, OP_LD_TIMEOUT, OP_LD_TIMEOUT, OP_WAIT, OP_RD_SDA, OTHERS => OP_IDLE );
      
   CONSTANT PROTOCOL_C_DELAYED_READ_WORD : SMBUS_PROTOCOL :=
      ( OP_LD_ADR, OP_WR_ADR_WR, OP_WR_DAT, OP_LD_TIMEOUT, OP_LD_TIMEOUT, OP_LD_TIMEOUT, OP_LD_TIMEOUT, OP_WAIT, OP_WR_ADR_RD, OP_RD_ACK, OP_RD_NACK, 
      OP_STOP, OTHERS => OP_IDLE);
      
      
   TYPE PROTOCOL_ARRAY IS ARRAY (NATURAL RANGE <>) OF SMBUS_PROTOCOL;
  
  -- Protocol list
  -- This maps a protocol identifier to the corresponding protocol
  CONSTANT SMBUS_PROTOCOLS : PROTOCOL_ARRAY := (
    -- Official SMBus protocols
    PROTOCOL_RESERVED,               -- 00
    PROTOCOL_RESERVED,               -- 01
    PROTOCOL_WRITE_QUICK,            -- 02
    PROTOCOL_READ_QUICK,             -- 03
    PROTOCOL_SEND_BYTE,              -- 04
    PROTOCOL_RECEIVE_BYTE,           -- 05
    PROTOCOL_WRITE_BYTE,             -- 06
    PROTOCOL_READ_BYTE,              -- 07
    PROTOCOL_WRITE_WORD,             -- 08
    PROTOCOL_READ_WORD,              -- 09
    PROTOCOL_WRITE_BLOCK,            -- 0A
    PROTOCOL_READ_BLOCK,             -- 0B
    PROTOCOL_PROCESS_CALL,           -- 0C
    -- Additional custom protocols
    PROTOCOL_C_WRITE_BLOCK_NO_CNT,   -- 0D
    PROTOCOL_C_READ_BLOCK_NO_CNT,    -- 0E
    PROTOCOL_C_SEND_BLOCK,           -- 0F
    PROTOCOL_C_RECEIVE_BLOCK,        -- 10
    PROTOCOL_C_NOP,                  -- 11
    PROTOCOL_C_WAIT,                 -- 12
    PROTOCOL_C_END,                  -- 13
    PROTOCOL_C_SAMPLE_SDA,           -- 14
    PROTOCOL_C_DELAYED_READ_WORD     -- 15
  );
  
  -- SMBUS protocol identifiers.
  -- As defined in the SMBUS Control Method Interface Specification v1.0
  CONSTANT SMBUS_RESERVED_0            : NATURAL := 16#00#;    
  CONSTANT SMBUS_RESERVED_1            : NATURAL := 16#01#;    
  CONSTANT SMBUS_WRITE_QUICK           : NATURAL := 16#02#;
  CONSTANT SMBUS_READ_QUICK            : NATURAL := 16#03#;
  CONSTANT SMBUS_SEND_BYTE             : NATURAL := 16#04#;
  CONSTANT SMBUS_RECEIVE_BYTE          : NATURAL := 16#05#;
  CONSTANT SMBUS_WRITE_BYTE            : NATURAL := 16#06#;
  CONSTANT SMBUS_READ_BYTE             : NATURAL := 16#07#;
  CONSTANT SMBUS_WRITE_WORD            : NATURAL := 16#08#;
  CONSTANT SMBUS_READ_WORD             : NATURAL := 16#09#;
  CONSTANT SMBUS_WRITE_BLOCK           : NATURAL := 16#0A#;
  CONSTANT SMBUS_READ_BLOCK            : NATURAL := 16#0B#;
  CONSTANT SMBUS_PROCESS_CALL          : NATURAL := 16#0C#;
  -- Extra custom protocols identifiers
  CONSTANT SMBUS_C_WRITE_BLOCK_NO_CNT  : NATURAL := 16#0D#;
  CONSTANT SMBUS_C_READ_BLOCK_NO_CNT   : NATURAL := 16#0E#;
  CONSTANT SMBUS_C_SEND_BLOCK          : NATURAL := 16#0F#;
  CONSTANT SMBUS_C_RECEIVE_BLOCK       : NATURAL := 16#10#;
  CONSTANT SMBUS_C_NOP                 : NATURAL := 16#11#;
  CONSTANT SMBUS_C_WAIT                : NATURAL := 16#12#;
  CONSTANT SMBUS_C_END                 : NATURAL := 16#13#;
  CONSTANT SMBUS_C_SAMPLE_SDA          : NATURAL := 16#14#;
  CONSTANT SMBUS_C_DELAYED_READ_WORD   : NATURAL := 16#15#;
  
  CONSTANT c_smbus_unknown_protocol    : NATURAL := 16#15#; -- Equal to largest valid SMBUS protocol ID
  
  CONSTANT c_smbus_timeout_nof_byte    : NATURAL := 4;      -- Four byte timeout value set via OP_LD_TIMEOUT
  CONSTANT c_smbus_timeout_word_w      : NATURAL := c_smbus_timeout_nof_byte * 8;
  CONSTANT c_smbus_timeout_w           : NATURAL := 28;     -- Only use 28 bits for actual timeout counter, 2^28 > 200M cycles in 1 sec
  
END PACKAGE;
