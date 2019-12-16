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
--   * polynomial: (0 4 13 15 16)
--   * data width: 16
--
-- Info : tools@easics.be
--        http://www.easics.com
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package PCK_CRC16_D16 is
  -- polynomial: (0 4 13 15 16)
  -- data width: 16
  -- convention: the first serial bit is D[15]
  function nextCRC16_D16
    (Data: std_logic_vector(15 downto 0);
     crc:  std_logic_vector(15 downto 0))
    return std_logic_vector;
end PCK_CRC16_D16;


package body PCK_CRC16_D16 is

  -- polynomial: (0 4 13 15 16)
  -- data width: 16
  -- convention: the first serial bit is D[15]
  function nextCRC16_D16
    (Data: std_logic_vector(15 downto 0);
     crc:  std_logic_vector(15 downto 0))
    return std_logic_vector is

    variable d:      std_logic_vector(15 downto 0);
    variable c:      std_logic_vector(15 downto 0);
    variable newcrc: std_logic_vector(15 downto 0);

  begin
    d := Data;
    c := crc;

    newcrc(0) := d(15) xor d(12) xor d(11) xor d(9) xor d(8) xor d(7) xor d(4) xor d(2) xor d(1) xor d(0) xor c(0) xor c(1) xor c(2) xor c(4) xor c(7) xor c(8) xor c(9) xor c(11) xor c(12) xor c(15);
    newcrc(1) := d(13) xor d(12) xor d(10) xor d(9) xor d(8) xor d(5) xor d(3) xor d(2) xor d(1) xor c(1) xor c(2) xor c(3) xor c(5) xor c(8) xor c(9) xor c(10) xor c(12) xor c(13);
    newcrc(2) := d(14) xor d(13) xor d(11) xor d(10) xor d(9) xor d(6) xor d(4) xor d(3) xor d(2) xor c(2) xor c(3) xor c(4) xor c(6) xor c(9) xor c(10) xor c(11) xor c(13) xor c(14);
    newcrc(3) := d(15) xor d(14) xor d(12) xor d(11) xor d(10) xor d(7) xor d(5) xor d(4) xor d(3) xor c(3) xor c(4) xor c(5) xor c(7) xor c(10) xor c(11) xor c(12) xor c(14) xor c(15);
    newcrc(4) := d(13) xor d(9) xor d(7) xor d(6) xor d(5) xor d(2) xor d(1) xor d(0) xor c(0) xor c(1) xor c(2) xor c(5) xor c(6) xor c(7) xor c(9) xor c(13);
    newcrc(5) := d(14) xor d(10) xor d(8) xor d(7) xor d(6) xor d(3) xor d(2) xor d(1) xor c(1) xor c(2) xor c(3) xor c(6) xor c(7) xor c(8) xor c(10) xor c(14);
    newcrc(6) := d(15) xor d(11) xor d(9) xor d(8) xor d(7) xor d(4) xor d(3) xor d(2) xor c(2) xor c(3) xor c(4) xor c(7) xor c(8) xor c(9) xor c(11) xor c(15);
    newcrc(7) := d(12) xor d(10) xor d(9) xor d(8) xor d(5) xor d(4) xor d(3) xor c(3) xor c(4) xor c(5) xor c(8) xor c(9) xor c(10) xor c(12);
    newcrc(8) := d(13) xor d(11) xor d(10) xor d(9) xor d(6) xor d(5) xor d(4) xor c(4) xor c(5) xor c(6) xor c(9) xor c(10) xor c(11) xor c(13);
    newcrc(9) := d(14) xor d(12) xor d(11) xor d(10) xor d(7) xor d(6) xor d(5) xor c(5) xor c(6) xor c(7) xor c(10) xor c(11) xor c(12) xor c(14);
    newcrc(10) := d(15) xor d(13) xor d(12) xor d(11) xor d(8) xor d(7) xor d(6) xor c(6) xor c(7) xor c(8) xor c(11) xor c(12) xor c(13) xor c(15);
    newcrc(11) := d(14) xor d(13) xor d(12) xor d(9) xor d(8) xor d(7) xor c(7) xor c(8) xor c(9) xor c(12) xor c(13) xor c(14);
    newcrc(12) := d(15) xor d(14) xor d(13) xor d(10) xor d(9) xor d(8) xor c(8) xor c(9) xor c(10) xor c(13) xor c(14) xor c(15);
    newcrc(13) := d(14) xor d(12) xor d(10) xor d(8) xor d(7) xor d(4) xor d(2) xor d(1) xor d(0) xor c(0) xor c(1) xor c(2) xor c(4) xor c(7) xor c(8) xor c(10) xor c(12) xor c(14);
    newcrc(14) := d(15) xor d(13) xor d(11) xor d(9) xor d(8) xor d(5) xor d(3) xor d(2) xor d(1) xor c(1) xor c(2) xor c(3) xor c(5) xor c(8) xor c(9) xor c(11) xor c(13) xor c(15);
    newcrc(15) := d(15) xor d(14) xor d(11) xor d(10) xor d(8) xor d(7) xor d(6) xor d(3) xor d(1) xor d(0) xor c(0) xor c(1) xor c(3) xor c(6) xor c(7) xor c(8) xor c(10) xor c(11) xor c(14) xor c(15);
    return newcrc;
  end nextCRC16_D16;

end PCK_CRC16_D16;
