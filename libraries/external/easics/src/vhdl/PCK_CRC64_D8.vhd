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
--   * polynomial: (0 1 4 7 9 10 12 13 17 19 21 22 23 24 27 29 31 32 33 35 37 38 39 40 45 46 47 52 53 54 55 57 62 64)
--   * data width: 8
--
-- Info : tools@easics.be
--        http://www.easics.com
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package PCK_CRC64_D8 is
  -- polynomial: (0 1 4 7 9 10 12 13 17 19 21 22 23 24 27 29 31 32 33 35 37 38 39 40 45 46 47 52 53 54 55 57 62 64)
  -- data width: 8
  -- convention: the first serial bit is D[7]
  function nextCRC64_D8
    (Data: std_logic_vector(7 downto 0);
     crc:  std_logic_vector(63 downto 0))
    return std_logic_vector;
end PCK_CRC64_D8;


package body PCK_CRC64_D8 is

  -- polynomial: (0 1 4 7 9 10 12 13 17 19 21 22 23 24 27 29 31 32 33 35 37 38 39 40 45 46 47 52 53 54 55 57 62 64)
  -- data width: 8
  -- convention: the first serial bit is D[7]
  function nextCRC64_D8
    (Data: std_logic_vector(7 downto 0);
     crc:  std_logic_vector(63 downto 0))
    return std_logic_vector is

    variable d:      std_logic_vector(7 downto 0);
    variable c:      std_logic_vector(63 downto 0);
    variable newcrc: std_logic_vector(63 downto 0);

  begin
    d := Data;
    c := crc;

    newcrc(0) := d(7) xor d(6) xor d(4) xor d(2) xor d(0) xor c(56) xor c(58) xor c(60) xor c(62) xor c(63);
    newcrc(1) := d(6) xor d(5) xor d(4) xor d(3) xor d(2) xor d(1) xor d(0) xor c(56) xor c(57) xor c(58) xor c(59) xor c(60) xor c(61) xor c(62);
    newcrc(2) := d(7) xor d(6) xor d(5) xor d(4) xor d(3) xor d(2) xor d(1) xor c(57) xor c(58) xor c(59) xor c(60) xor c(61) xor c(62) xor c(63);
    newcrc(3) := d(7) xor d(6) xor d(5) xor d(4) xor d(3) xor d(2) xor c(58) xor c(59) xor c(60) xor c(61) xor c(62) xor c(63);
    newcrc(4) := d(5) xor d(3) xor d(2) xor d(0) xor c(56) xor c(58) xor c(59) xor c(61);
    newcrc(5) := d(6) xor d(4) xor d(3) xor d(1) xor c(57) xor c(59) xor c(60) xor c(62);
    newcrc(6) := d(7) xor d(5) xor d(4) xor d(2) xor c(58) xor c(60) xor c(61) xor c(63);
    newcrc(7) := d(7) xor d(5) xor d(4) xor d(3) xor d(2) xor d(0) xor c(56) xor c(58) xor c(59) xor c(60) xor c(61) xor c(63);
    newcrc(8) := d(6) xor d(5) xor d(4) xor d(3) xor d(1) xor c(0) xor c(57) xor c(59) xor c(60) xor c(61) xor c(62);
    newcrc(9) := d(5) xor d(0) xor c(1) xor c(56) xor c(61);
    newcrc(10) := d(7) xor d(4) xor d(2) xor d(1) xor d(0) xor c(2) xor c(56) xor c(57) xor c(58) xor c(60) xor c(63);
    newcrc(11) := d(5) xor d(3) xor d(2) xor d(1) xor c(3) xor c(57) xor c(58) xor c(59) xor c(61);
    newcrc(12) := d(7) xor d(3) xor d(0) xor c(4) xor c(56) xor c(59) xor c(63);
    newcrc(13) := d(7) xor d(6) xor d(2) xor d(1) xor d(0) xor c(5) xor c(56) xor c(57) xor c(58) xor c(62) xor c(63);
    newcrc(14) := d(7) xor d(3) xor d(2) xor d(1) xor c(6) xor c(57) xor c(58) xor c(59) xor c(63);
    newcrc(15) := d(4) xor d(3) xor d(2) xor c(7) xor c(58) xor c(59) xor c(60);
    newcrc(16) := d(5) xor d(4) xor d(3) xor c(8) xor c(59) xor c(60) xor c(61);
    newcrc(17) := d(7) xor d(5) xor d(2) xor d(0) xor c(9) xor c(56) xor c(58) xor c(61) xor c(63);
    newcrc(18) := d(6) xor d(3) xor d(1) xor c(10) xor c(57) xor c(59) xor c(62);
    newcrc(19) := d(6) xor d(0) xor c(11) xor c(56) xor c(62);
    newcrc(20) := d(7) xor d(1) xor c(12) xor c(57) xor c(63);
    newcrc(21) := d(7) xor d(6) xor d(4) xor d(0) xor c(13) xor c(56) xor c(60) xor c(62) xor c(63);
    newcrc(22) := d(6) xor d(5) xor d(4) xor d(2) xor d(1) xor d(0) xor c(14) xor c(56) xor c(57) xor c(58) xor c(60) xor c(61) xor c(62);
    newcrc(23) := d(5) xor d(4) xor d(3) xor d(1) xor d(0) xor c(15) xor c(56) xor c(57) xor c(59) xor c(60) xor c(61);
    newcrc(24) := d(7) xor d(5) xor d(1) xor d(0) xor c(16) xor c(56) xor c(57) xor c(61) xor c(63);
    newcrc(25) := d(6) xor d(2) xor d(1) xor c(17) xor c(57) xor c(58) xor c(62);
    newcrc(26) := d(7) xor d(3) xor d(2) xor c(18) xor c(58) xor c(59) xor c(63);
    newcrc(27) := d(7) xor d(6) xor d(3) xor d(2) xor d(0) xor c(19) xor c(56) xor c(58) xor c(59) xor c(62) xor c(63);
    newcrc(28) := d(7) xor d(4) xor d(3) xor d(1) xor c(20) xor c(57) xor c(59) xor c(60) xor c(63);
    newcrc(29) := d(7) xor d(6) xor d(5) xor d(0) xor c(21) xor c(56) xor c(61) xor c(62) xor c(63);
    newcrc(30) := d(7) xor d(6) xor d(1) xor c(22) xor c(57) xor c(62) xor c(63);
    newcrc(31) := d(6) xor d(4) xor d(0) xor c(23) xor c(56) xor c(60) xor c(62);
    newcrc(32) := d(6) xor d(5) xor d(4) xor d(2) xor d(1) xor d(0) xor c(24) xor c(56) xor c(57) xor c(58) xor c(60) xor c(61) xor c(62);
    newcrc(33) := d(5) xor d(4) xor d(3) xor d(1) xor d(0) xor c(25) xor c(56) xor c(57) xor c(59) xor c(60) xor c(61);
    newcrc(34) := d(6) xor d(5) xor d(4) xor d(2) xor d(1) xor c(26) xor c(57) xor c(58) xor c(60) xor c(61) xor c(62);
    newcrc(35) := d(5) xor d(4) xor d(3) xor d(0) xor c(27) xor c(56) xor c(59) xor c(60) xor c(61);
    newcrc(36) := d(6) xor d(5) xor d(4) xor d(1) xor c(28) xor c(57) xor c(60) xor c(61) xor c(62);
    newcrc(37) := d(5) xor d(4) xor d(0) xor c(29) xor c(56) xor c(60) xor c(61);
    newcrc(38) := d(7) xor d(5) xor d(4) xor d(2) xor d(1) xor d(0) xor c(30) xor c(56) xor c(57) xor c(58) xor c(60) xor c(61) xor c(63);
    newcrc(39) := d(7) xor d(5) xor d(4) xor d(3) xor d(1) xor d(0) xor c(31) xor c(56) xor c(57) xor c(59) xor c(60) xor c(61) xor c(63);
    newcrc(40) := d(7) xor d(5) xor d(1) xor d(0) xor c(32) xor c(56) xor c(57) xor c(61) xor c(63);
    newcrc(41) := d(6) xor d(2) xor d(1) xor c(33) xor c(57) xor c(58) xor c(62);
    newcrc(42) := d(7) xor d(3) xor d(2) xor c(34) xor c(58) xor c(59) xor c(63);
    newcrc(43) := d(4) xor d(3) xor c(35) xor c(59) xor c(60);
    newcrc(44) := d(5) xor d(4) xor c(36) xor c(60) xor c(61);
    newcrc(45) := d(7) xor d(5) xor d(4) xor d(2) xor d(0) xor c(37) xor c(56) xor c(58) xor c(60) xor c(61) xor c(63);
    newcrc(46) := d(7) xor d(5) xor d(4) xor d(3) xor d(2) xor d(1) xor d(0) xor c(38) xor c(56) xor c(57) xor c(58) xor c(59) xor c(60) xor c(61) xor c(63);
    newcrc(47) := d(7) xor d(5) xor d(3) xor d(1) xor d(0) xor c(39) xor c(56) xor c(57) xor c(59) xor c(61) xor c(63);
    newcrc(48) := d(6) xor d(4) xor d(2) xor d(1) xor c(40) xor c(57) xor c(58) xor c(60) xor c(62);
    newcrc(49) := d(7) xor d(5) xor d(3) xor d(2) xor c(41) xor c(58) xor c(59) xor c(61) xor c(63);
    newcrc(50) := d(6) xor d(4) xor d(3) xor c(42) xor c(59) xor c(60) xor c(62);
    newcrc(51) := d(7) xor d(5) xor d(4) xor c(43) xor c(60) xor c(61) xor c(63);
    newcrc(52) := d(7) xor d(5) xor d(4) xor d(2) xor d(0) xor c(44) xor c(56) xor c(58) xor c(60) xor c(61) xor c(63);
    newcrc(53) := d(7) xor d(5) xor d(4) xor d(3) xor d(2) xor d(1) xor d(0) xor c(45) xor c(56) xor c(57) xor c(58) xor c(59) xor c(60) xor c(61) xor c(63);
    newcrc(54) := d(7) xor d(5) xor d(3) xor d(1) xor d(0) xor c(46) xor c(56) xor c(57) xor c(59) xor c(61) xor c(63);
    newcrc(55) := d(7) xor d(1) xor d(0) xor c(47) xor c(56) xor c(57) xor c(63);
    newcrc(56) := d(2) xor d(1) xor c(48) xor c(57) xor c(58);
    newcrc(57) := d(7) xor d(6) xor d(4) xor d(3) xor d(0) xor c(49) xor c(56) xor c(59) xor c(60) xor c(62) xor c(63);
    newcrc(58) := d(7) xor d(5) xor d(4) xor d(1) xor c(50) xor c(57) xor c(60) xor c(61) xor c(63);
    newcrc(59) := d(6) xor d(5) xor d(2) xor c(51) xor c(58) xor c(61) xor c(62);
    newcrc(60) := d(7) xor d(6) xor d(3) xor c(52) xor c(59) xor c(62) xor c(63);
    newcrc(61) := d(7) xor d(4) xor c(53) xor c(60) xor c(63);
    newcrc(62) := d(7) xor d(6) xor d(5) xor d(4) xor d(2) xor d(0) xor c(54) xor c(56) xor c(58) xor c(60) xor c(61) xor c(62) xor c(63);
    newcrc(63) := d(7) xor d(6) xor d(5) xor d(3) xor d(1) xor c(55) xor c(57) xor c(59) xor c(61) xor c(62) xor c(63);
    return newcrc;
  end nextCRC64_D8;

end PCK_CRC64_D8;
