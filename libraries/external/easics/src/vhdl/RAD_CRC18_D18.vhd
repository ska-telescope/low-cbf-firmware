-----------------------------------------------------------------------
-- File:  RAD_CRC18_D18.vhd                              
-- Date:  Mon Nov 14 09:07:57 2005                                                      
--                                                                     
-- Copyright (C) 1999-2003 Easics NV.                 
-- This source file may be used and distributed without restriction    
-- provided that this copyright statement is not removed from the file 
-- and that any derivative work contains the original copyright notice
-- and the associated disclaimer.
--
-- THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
-- OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
-- WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
--
-- Purpose: VHDL package containing a synthesizable CRC function
--   * polynomial: (0 1 4 18)
--   * data width: 18
--                                                                     
-- Info: tools@easics.be
--       http://www.easics.com                                  
-----------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;

package RAD_CRC18_D18 is

  -- polynomial: (0 1 4 18)
  -- data width: 18
  -- convention: the first serial data bit is D(17)
  function nextRAD_CRC18_D18
    ( Data:  std_logic_vector(17 downto 0);
      CRC:   std_logic_vector(17 downto 0) )
    return std_logic_vector;

end RAD_CRC18_D18;

library IEEE;
use IEEE.std_logic_1164.all;

package body RAD_CRC18_D18 is

  -- polynomial: (0 1 4 18)
  -- data width: 18
  -- convention: the first serial data bit is D(17)
  function nextRAD_CRC18_D18  
    ( Data:  std_logic_vector(17 downto 0);
      CRC:   std_logic_vector(17 downto 0) )
    return std_logic_vector is

    variable D: std_logic_vector(17 downto 0);
    variable C: std_logic_vector(17 downto 0);
    variable NewCRC: std_logic_vector(17 downto 0);

  begin

    D := Data;
    C := CRC;

    NewCRC(0) := D(17) xor D(14) xor D(0) xor C(0) xor C(14) xor C(17);
    NewCRC(1) := D(17) xor D(15) xor D(14) xor D(1) xor D(0) xor C(0) xor 
                 C(1) xor C(14) xor C(15) xor C(17);
    NewCRC(2) := D(16) xor D(15) xor D(2) xor D(1) xor C(1) xor C(2) xor 
                 C(15) xor C(16);
    NewCRC(3) := D(17) xor D(16) xor D(3) xor D(2) xor C(2) xor C(3) xor 
                 C(16) xor C(17);
    NewCRC(4) := D(14) xor D(4) xor D(3) xor D(0) xor C(0) xor C(3) xor 
                 C(4) xor C(14);
    NewCRC(5) := D(15) xor D(5) xor D(4) xor D(1) xor C(1) xor C(4) xor 
                 C(5) xor C(15);
    NewCRC(6) := D(16) xor D(6) xor D(5) xor D(2) xor C(2) xor C(5) xor 
                 C(6) xor C(16);
    NewCRC(7) := D(17) xor D(7) xor D(6) xor D(3) xor C(3) xor C(6) xor 
                 C(7) xor C(17);
    NewCRC(8) := D(8) xor D(7) xor D(4) xor C(4) xor C(7) xor C(8);
    NewCRC(9) := D(9) xor D(8) xor D(5) xor C(5) xor C(8) xor C(9);
    NewCRC(10) := D(10) xor D(9) xor D(6) xor C(6) xor C(9) xor C(10);
    NewCRC(11) := D(11) xor D(10) xor D(7) xor C(7) xor C(10) xor C(11);
    NewCRC(12) := D(12) xor D(11) xor D(8) xor C(8) xor C(11) xor C(12);
    NewCRC(13) := D(13) xor D(12) xor D(9) xor C(9) xor C(12) xor C(13);
    NewCRC(14) := D(14) xor D(13) xor D(10) xor C(10) xor C(13) xor C(14);
    NewCRC(15) := D(15) xor D(14) xor D(11) xor C(11) xor C(14) xor C(15);
    NewCRC(16) := D(16) xor D(15) xor D(12) xor C(12) xor C(15) xor C(16);
    NewCRC(17) := D(17) xor D(16) xor D(13) xor C(13) xor C(16) xor C(17);

    return NewCRC;

  end nextRAD_CRC18_D18;

end RAD_CRC18_D18;

