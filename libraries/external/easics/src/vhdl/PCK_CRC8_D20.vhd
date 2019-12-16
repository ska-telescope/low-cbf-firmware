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
--   * polynomial: (0 1 2 8)
--   * data width: 20
--
-- Info : tools@easics.be
--        http://www.easics.com
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package PCK_CRC8_D20 is
  -- polynomial: (0 1 2 8)
  -- data width: 20
  -- convention: the first serial bit is D[19]
  function nextCRC8_D20
    (Data: std_logic_vector(19 downto 0);
     crc:  std_logic_vector(7 downto 0))
    return std_logic_vector;
end PCK_CRC8_D20;


package body PCK_CRC8_D20 is

  -- polynomial: (0 1 2 8)
  -- data width: 20
  -- convention: the first serial bit is D[19]
  function nextCRC8_D20
    (Data: std_logic_vector(19 downto 0);
     crc:  std_logic_vector(7 downto 0))
    return std_logic_vector is

    variable d:      std_logic_vector(19 downto 0);
    variable c:      std_logic_vector(7 downto 0);
    variable newcrc: std_logic_vector(7 downto 0);

  begin
    d := Data;
    c := crc;

    newcrc(0) := d(19) xor d(18) xor d(16) xor d(14) xor d(12) xor d(8) xor d(7) xor d(6) xor d(0) xor c(0) xor c(2) xor c(4) xor c(6) xor c(7);
    newcrc(1) := d(18) xor d(17) xor d(16) xor d(15) xor d(14) xor d(13) xor d(12) xor d(9) xor d(6) xor d(1) xor d(0) xor c(0) xor c(1) xor c(2) xor c(3) xor c(4) xor c(5) xor c(6);
    newcrc(2) := d(17) xor d(15) xor d(13) xor d(12) xor d(10) xor d(8) xor d(6) xor d(2) xor d(1) xor d(0) xor c(0) xor c(1) xor c(3) xor c(5);
    newcrc(3) := d(18) xor d(16) xor d(14) xor d(13) xor d(11) xor d(9) xor d(7) xor d(3) xor d(2) xor d(1) xor c(1) xor c(2) xor c(4) xor c(6);
    newcrc(4) := d(19) xor d(17) xor d(15) xor d(14) xor d(12) xor d(10) xor d(8) xor d(4) xor d(3) xor d(2) xor c(0) xor c(2) xor c(3) xor c(5) xor c(7);
    newcrc(5) := d(18) xor d(16) xor d(15) xor d(13) xor d(11) xor d(9) xor d(5) xor d(4) xor d(3) xor c(1) xor c(3) xor c(4) xor c(6);
    newcrc(6) := d(19) xor d(17) xor d(16) xor d(14) xor d(12) xor d(10) xor d(6) xor d(5) xor d(4) xor c(0) xor c(2) xor c(4) xor c(5) xor c(7);
    newcrc(7) := d(18) xor d(17) xor d(15) xor d(13) xor d(11) xor d(7) xor d(6) xor d(5) xor c(1) xor c(3) xor c(5) xor c(6);
    return newcrc;
  end nextCRC8_D20;

end PCK_CRC8_D20;
