-------------------------------------------------------------------------------
-- (c) Copyright - Commonwealth Scientific and Industrial Research Organisation
-- (CSIRO) - 2009
--
-- All Rights Reserved.
--
-- Restricted Use.
--
-- Copyright protects this code. Except as permitted by the Copyright Act, you
-- may only use the code as expressly permitted under the terms on which the
-- code was licensed to you.
--
-------------------------------------------------------------------------------
--
-- File Name:    utils.vhd
-- Type:         RTL
-- Designer:
-- Created:      16:26:56 13/03/2012
-- Template Rev: 0.1
--
-- Title:        Utilities Package
--
-- Description:  General utility functions
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package utils_pkg is
  
   function to_stdlogicvector(b: std_logic; i: integer) return std_logic_vector;
   function to_vector(number: integer; length: integer) return std_logic_vector;
   function conv_integer(a: std_logic_vector) return integer;
   function ceil_log2 (a : integer) return integer;
   function ceil_div (a : integer; b : integer) return integer;
   function power (a : integer; b : integer) return integer;

end utils_pkg;


package body utils_pkg is

   function to_stdlogicvector(b: std_logic; i: integer) return std_logic_vector is
      variable output : std_logic_vector(i downto 0);
   begin
      output := (others => b);
      return output;       
   end;

   -- Converts a number to a vector
   function to_vector(number: integer; length: integer) return std_logic_vector is
      variable output : std_logic_vector(length-1 downto 0);
      variable temp , j: integer;
   begin
      temp := number;
      output := (others => '0');
      for i in 0 to length-1 loop
         j := (length-i-1);
         if temp >= 2 ** j then
            temp := temp - (2 ** j);      
            output(j) := '1';
         end if;           
      end loop;
      return output;       
   end;

   -- power function, a raised to b
   function power (a : integer; b : integer) return integer is
      variable result : integer := 1;
   begin
      if b = 0 then
         return 1;
      end if;
   
      for i in 0 to b-1 loop
         result := a*result;
      end loop;
      return result;
   end;

   -- Do a division and take the ceil of the result a/b
   function ceil_div (a : integer; b : integer) return integer is
      variable c, remainder : integer;
   begin
      remainder := a rem b;
      if remainder = 0 then
         c := a/b;
      else
         c := ((a-remainder)/b) + 1;
      end if;
      return c;
   end;


   --Determines the lowest power of 2 that will fit the integer
   function ceil_log2 (a : integer) return integer is
      variable j, c : integer;
   begin
      c := 0;
      j := 1;
      for i in 0 to a loop
         j := 2 ** i;                                                      --Powers of 2
         if j >= a then
            return i;
         end if;

      end loop;
      return 1;
   end;

   --Function converts a vector into an integer
   function conv_integer(a: std_logic_vector) return  integer is
   begin
      return to_integer(unsigned(a));
   end;

end utils_pkg;