--------------------------------------------------------------------------------
-- Copyright (C) 1999-2008 Easics NV.
-- This source file may be used and distributed without restriction
-- provided that this copyright statement is not removed from the file
-- and that any derivative work contains the original copyright notice
-- and the associated disclaimer.
--
-- THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
-- OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
-- WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
--
-- Purpose : synthesizable CRC function
--   * polynomial: (0 2 15 16)
--   * data width: 4
--
-- Info : tools@easics.be
--        http://www.easics.com
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package PCK_CRC16_D4 is
  -- polynomial: (0 2 15 16)
  -- data width: 4
  -- convention: the first serial bit is D[3]
  function nextCRC16_D4
    (Data: std_logic_vector(3 downto 0);
     crc:  std_logic_vector(15 downto 0))
    return std_logic_vector;
end PCK_CRC16_D4;


package body PCK_CRC16_D4 is

  -- polynomial: (0 2 15 16)
  -- data width: 4
  -- convention: the first serial bit is D[3]
  function nextCRC16_D4
    (Data: std_logic_vector(3 downto 0);
     crc:  std_logic_vector(15 downto 0))
    return std_logic_vector is

    variable d:      std_logic_vector(3 downto 0);
    variable c:      std_logic_vector(15 downto 0);
    variable newcrc: std_logic_vector(15 downto 0);

  begin
    d := Data;
    c := crc;

    newcrc(0) := d(3) xor d(2) xor d(1) xor d(0) xor c(12) xor c(13) xor c(14) xor c(15);
    newcrc(1) := d(3) xor d(2) xor d(1) xor c(13) xor c(14) xor c(15);
    newcrc(2) := d(1) xor d(0) xor c(12) xor c(13);
    newcrc(3) := d(2) xor d(1) xor c(13) xor c(14);
    newcrc(4) := d(3) xor d(2) xor c(0) xor c(14) xor c(15);
    newcrc(5) := d(3) xor c(1) xor c(15);
    newcrc(6) := c(2);
    newcrc(7) := c(3);
    newcrc(8) := c(4);
    newcrc(9) := c(5);
    newcrc(10) := c(6);
    newcrc(11) := c(7);
    newcrc(12) := c(8);
    newcrc(13) := c(9);
    newcrc(14) := c(10);
    newcrc(15) := d(3) xor d(2) xor d(1) xor d(0) xor c(11) xor c(12) xor c(13) xor c(14) xor c(15);
    return newcrc;
  end nextCRC16_D4;

end PCK_CRC16_D4;
