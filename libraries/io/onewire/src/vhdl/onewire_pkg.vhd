-------------------------------------------------------------------------------
--
-- File Name: onewire_pkg.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Thurs Nov 15 17:17:00 2017
-- Template Rev: 1.0
--
-- Title: Onwire Interface Package 
--
-- Description: General definitions for the onewire interface module
--
--
-- Compiler options:
-- 
-- 
-- Dependencies:
-- 
-- 
-- 
-------------------------------------------------------------------------------

LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE common_lib.common_pkg.ALL;

PACKAGE onewire_pkg IS

   -- Opcodes used in one wire sequences definitions
   TYPE t_phy_opcode IS (
      OP_WRITE8,        -- Write 8 bits
      OP_READ8,         -- Read 8 bits     
      OP_PRESENCE       -- Generate Presence/reset pulse
   );

   -- Command that can be issued by the transaction state machine
   TYPE t_onewire_cmd IS (
      CMD_READ_ROM,                       -- Read ROM code
      CMD_WRITE_MEMORY,                   -- Write to memory array
      CMD_READ_MEMORY                     -- Read from memory array
   );



   ---------------------------------------------------------------------------
   -- CONSTANTS  --
   ---------------------------------------------------------------------------

   -- One wire op codes
   CONSTANT ONEWIRE_WRITE_SCRATCHPAD            : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"0F";
   CONSTANT ONEWIRE_READ_SCRATCHPAD             : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"AA";
   CONSTANT ONEWIRE_COPY_SCRATCHPAD             : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"55";
  
   CONSTANT ONEWIRE_READ_MEMORY                 : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"F0";

   -- One wire ROM codes
   CONSTANT ONEWIRE_READ_ROM                    : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"33";
   CONSTANT ONEWIRE_MATCH_ROM                   : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"55";
   CONSTANT ONEWIRE_SEARCH_ROM                  : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"F0";
   CONSTANT ONEWIRE_SKIP_ROM                    : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"CC";
   CONSTANT ONEWIRE_RESUME                      : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"A5";
   
   CONSTANT ONEWIRE_OVERDRIVE_SKIP_ROM          : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"3C";
   CONSTANT ONEWIRE_OVERDRIVE_MATCH_ROM         : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"69";

END onewire_pkg;

