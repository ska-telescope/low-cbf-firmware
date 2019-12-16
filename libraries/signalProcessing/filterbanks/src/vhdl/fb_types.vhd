----------------------------------------------------------------------------------
-- Company: CSIRO
-- Engineer: David Humphrey
--
-- Create Date: 09/18/2012 09:22:53 AM
-- Module Name: eband_types_pkg - Behavioral
-- Description:
--  Types used in the eband FPGA.
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package fb_types is
  
    type array1bit_type is array( natural range <> ) of std_logic_vector(0 downto 0);
    type array6bit_type is array( natural range <> ) of std_logic_vector(5 downto 0);
    type array7bit_type is array( natural range <> ) of std_logic_vector(6 downto 0);
    type array8bit_type is array( natural range <> ) of std_logic_vector(7 downto 0);
    type array9bit_type is array( natural range <> ) of std_logic_vector(8 downto 0);
    type array12bit_type is array( natural range <> ) of std_logic_vector(11 downto 0);
    type array16bit_type is array( natural range <> ) of std_logic_vector(15 downto 0);
    type array18bit_type is array( natural range <> ) of std_logic_vector(17 downto 0);
    type array25bit_type is array( natural range <> ) of std_logic_vector(24 downto 0);
    type array27bit_type is array( natural range <> ) of std_logic_vector(26 downto 0);
    type array32bit_type is array( natural range <> ) of std_logic_vector(31 downto 0);
    type array36bit_type is array( natural range <> ) of std_logic_vector(35 downto 0);
    type array48bit_type is array( natural range <> ) of std_logic_vector(47 downto 0);
    type array64bit_type is array( natural range <> ) of std_logic_vector(63 downto 0);
    type array80bit_type is array( natural range <> ) of std_logic_vector(79 downto 0); 
    type array90bit_type is array( natural range <> ) of std_logic_vector(89 downto 0);
    type array96bit_type is array( natural range <> ) of std_logic_vector(95 downto 0);
    type array120bit_type is array( natural range <> ) of std_logic_vector(119 downto 0);
    
end fb_types;