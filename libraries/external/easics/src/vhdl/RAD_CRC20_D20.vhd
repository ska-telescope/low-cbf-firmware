-----------------------------------------------------------------------
-- File:  RAD_CRC20_D20.vhd                              
-- Date:  Mon Aug 28 13:24:08 2006                                                      
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
--   * polynomial: (0 17 20)
--   * data width: 20
--                                                                     
-- Info: tools@easics.be
--       http://www.easics.com                                  
-----------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;

package RAD_CRC20_D20 is

  -- polynomial: (0 17 20)
  -- data width: 20
  -- convention: the first serial data bit is D(19)
  function nextRAD_CRC20_D20
    ( Data:  std_logic_vector(19 downto 0);
      CRC:   std_logic_vector(19 downto 0) )
    return std_logic_vector;

end RAD_CRC20_D20;

library IEEE;
use IEEE.std_logic_1164.all;

package body RAD_CRC20_D20 is

  -- polynomial: (0 17 20)
  -- data width: 20
  -- convention: the first serial data bit is D(19)
  function nextRAD_CRC20_D20  
    ( Data:  std_logic_vector(19 downto 0);
      CRC:   std_logic_vector(19 downto 0) )
    return std_logic_vector is

    variable D: std_logic_vector(19 downto 0);
    variable C: std_logic_vector(19 downto 0);
    variable NewCRC: std_logic_vector(19 downto 0);

  begin

    D := Data;
    C := CRC;

    NewCRC(0) := D(18) xor D(15) xor D(12) xor D(9) xor D(6) xor D(3) xor 
                 D(0) xor C(0) xor C(3) xor C(6) xor C(9) xor C(12) xor 
                 C(15) xor C(18);
    NewCRC(1) := D(19) xor D(16) xor D(13) xor D(10) xor D(7) xor D(4) xor 
                 D(1) xor C(1) xor C(4) xor C(7) xor C(10) xor C(13) xor 
                 C(16) xor C(19);
    NewCRC(2) := D(17) xor D(14) xor D(11) xor D(8) xor D(5) xor D(2) xor 
                 C(2) xor C(5) xor C(8) xor C(11) xor C(14) xor C(17);
    NewCRC(3) := D(18) xor D(15) xor D(12) xor D(9) xor D(6) xor D(3) xor 
                 C(3) xor C(6) xor C(9) xor C(12) xor C(15) xor C(18);
    NewCRC(4) := D(19) xor D(16) xor D(13) xor D(10) xor D(7) xor D(4) xor 
                 C(4) xor C(7) xor C(10) xor C(13) xor C(16) xor C(19);
    NewCRC(5) := D(17) xor D(14) xor D(11) xor D(8) xor D(5) xor C(5) xor 
                 C(8) xor C(11) xor C(14) xor C(17);
    NewCRC(6) := D(18) xor D(15) xor D(12) xor D(9) xor D(6) xor C(6) xor 
                 C(9) xor C(12) xor C(15) xor C(18);
    NewCRC(7) := D(19) xor D(16) xor D(13) xor D(10) xor D(7) xor C(7) xor 
                 C(10) xor C(13) xor C(16) xor C(19);
    NewCRC(8) := D(17) xor D(14) xor D(11) xor D(8) xor C(8) xor C(11) xor 
                 C(14) xor C(17);
    NewCRC(9) := D(18) xor D(15) xor D(12) xor D(9) xor C(9) xor C(12) xor 
                 C(15) xor C(18);
    NewCRC(10) := D(19) xor D(16) xor D(13) xor D(10) xor C(10) xor C(13) xor 
                  C(16) xor C(19);
    NewCRC(11) := D(17) xor D(14) xor D(11) xor C(11) xor C(14) xor C(17);
    NewCRC(12) := D(18) xor D(15) xor D(12) xor C(12) xor C(15) xor C(18);
    NewCRC(13) := D(19) xor D(16) xor D(13) xor C(13) xor C(16) xor C(19);
    NewCRC(14) := D(17) xor D(14) xor C(14) xor C(17);
    NewCRC(15) := D(18) xor D(15) xor C(15) xor C(18);
    NewCRC(16) := D(19) xor D(16) xor C(16) xor C(19);
    NewCRC(17) := D(18) xor D(17) xor D(15) xor D(12) xor D(9) xor D(6) xor 
                  D(3) xor D(0) xor C(0) xor C(3) xor C(6) xor C(9) xor 
                  C(12) xor C(15) xor C(17) xor C(18);
    NewCRC(18) := D(19) xor D(18) xor D(16) xor D(13) xor D(10) xor D(7) xor 
                  D(4) xor D(1) xor C(1) xor C(4) xor C(7) xor C(10) xor 
                  C(13) xor C(16) xor C(18) xor C(19);
    NewCRC(19) := D(19) xor D(17) xor D(14) xor D(11) xor D(8) xor D(5) xor 
                  D(2) xor C(2) xor C(5) xor C(8) xor C(11) xor C(14) xor 
                  C(17) xor C(19);

    return NewCRC;

  end nextRAD_CRC20_D20;

end RAD_CRC20_D20;

