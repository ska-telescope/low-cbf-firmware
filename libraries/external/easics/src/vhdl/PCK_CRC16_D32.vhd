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
--   * data width: 32
--
-- Info : tools@easics.be
--        http://www.easics.com
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package PCK_CRC16_D32 is
  -- polynomial: (0 2 15 16)
  -- data width: 32
  -- convention: the first serial bit is D[31]
  function nextCRC16_D32
    (Data: std_logic_vector(31 downto 0);
     crc:  std_logic_vector(15 downto 0))
    return std_logic_vector;
end PCK_CRC16_D32;


package body PCK_CRC16_D32 is

  -- polynomial: (0 2 15 16)
  -- data width: 32
  -- convention: the first serial bit is D[31]
  function nextCRC16_D32
    (Data: std_logic_vector(31 downto 0);
     crc:  std_logic_vector(15 downto 0))
    return std_logic_vector is

    variable d:      std_logic_vector(31 downto 0);
    variable c:      std_logic_vector(15 downto 0);
    variable newcrc: std_logic_vector(15 downto 0);

  begin
    d := Data;
    c := crc;

    newcrc(0) := d(31) xor d(30) xor d(27) xor d(26) xor d(25) xor d(24) xor d(23) xor d(22) xor d(21) xor d(20) xor d(19) xor d(18) xor d(17) xor d(16) xor d(15) xor d(13) xor d(12) xor d(11) xor d(10) xor d(9) xor d(8) xor d(7) xor d(6) xor d(5) xor d(4) xor d(3) xor d(2) xor d(1) xor d(0) xor c(0) xor c(1) xor c(2) xor c(3) xor c(4) xor c(5) xor c(6) xor c(7) xor c(8) xor c(9) xor c(10) xor c(11) xor c(14) xor c(15);
    newcrc(1) := d(31) xor d(28) xor d(27) xor d(26) xor d(25) xor d(24) xor d(23) xor d(22) xor d(21) xor d(20) xor d(19) xor d(18) xor d(17) xor d(16) xor d(14) xor d(13) xor d(12) xor d(11) xor d(10) xor d(9) xor d(8) xor d(7) xor d(6) xor d(5) xor d(4) xor d(3) xor d(2) xor d(1) xor c(0) xor c(1) xor c(2) xor c(3) xor c(4) xor c(5) xor c(6) xor c(7) xor c(8) xor c(9) xor c(10) xor c(11) xor c(12) xor c(15);
    newcrc(2) := d(31) xor d(30) xor d(29) xor d(28) xor d(16) xor d(14) xor d(1) xor d(0) xor c(0) xor c(12) xor c(13) xor c(14) xor c(15);
    newcrc(3) := d(31) xor d(30) xor d(29) xor d(17) xor d(15) xor d(2) xor d(1) xor c(1) xor c(13) xor c(14) xor c(15);
    newcrc(4) := d(31) xor d(30) xor d(18) xor d(16) xor d(3) xor d(2) xor c(0) xor c(2) xor c(14) xor c(15);
    newcrc(5) := d(31) xor d(19) xor d(17) xor d(4) xor d(3) xor c(1) xor c(3) xor c(15);
    newcrc(6) := d(20) xor d(18) xor d(5) xor d(4) xor c(2) xor c(4);
    newcrc(7) := d(21) xor d(19) xor d(6) xor d(5) xor c(3) xor c(5);
    newcrc(8) := d(22) xor d(20) xor d(7) xor d(6) xor c(4) xor c(6);
    newcrc(9) := d(23) xor d(21) xor d(8) xor d(7) xor c(5) xor c(7);
    newcrc(10) := d(24) xor d(22) xor d(9) xor d(8) xor c(6) xor c(8);
    newcrc(11) := d(25) xor d(23) xor d(10) xor d(9) xor c(7) xor c(9);
    newcrc(12) := d(26) xor d(24) xor d(11) xor d(10) xor c(8) xor c(10);
    newcrc(13) := d(27) xor d(25) xor d(12) xor d(11) xor c(9) xor c(11);
    newcrc(14) := d(28) xor d(26) xor d(13) xor d(12) xor c(10) xor c(12);
    newcrc(15) := d(31) xor d(30) xor d(29) xor d(26) xor d(25) xor d(24) xor d(23) xor d(22) xor d(21) xor d(20) xor d(19) xor d(18) xor d(17) xor d(16) xor d(15) xor d(14) xor d(12) xor d(11) xor d(10) xor d(9) xor d(8) xor d(7) xor d(6) xor d(5) xor d(4) xor d(3) xor d(2) xor d(1) xor d(0) xor c(0) xor c(1) xor c(2) xor c(3) xor c(4) xor c(5) xor c(6) xor c(7) xor c(8) xor c(9) xor c(10) xor c(13) xor c(14) xor c(15);
    return newcrc;
  end nextCRC16_D32;

end PCK_CRC16_D32;
