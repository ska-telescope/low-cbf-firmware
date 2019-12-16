---------------------------------------------------------------------------------------------------
-- 
-- COMMON_TB_PKG
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert_abel@gmx.net)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
-- 
-- Provides basic helper functions for test benches.
--
-- The syntax of check_equal is similar to that of vunit's check_equal.
-- This is supposed to allow an easier transition between systems that use vunit (SKA.Mid)
-- and systems that do not (RadioHDL).
-- More vunit inspired functions and procedures may be added.
--
---------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

package common_tb_pkg is
    
    procedure check_equal(a:signed;   b:signed;   t: string; s:severity_level:=FAILURE);
    procedure check_equal(a:signed;   b:integer;  t: string; s:severity_level:=FAILURE);
    procedure check_equal(a:unsigned; b:unsigned; t: string; s:severity_level:=FAILURE);
    procedure check_equal(a:unsigned; b:integer;  t: string; s:severity_level:=FAILURE);
    procedure check_equal(a:integer;  b:integer;  t: string; s:severity_level:=FAILURE);
    procedure echo   (t: string := "");
    procedure echoln (t: string := "");

end package common_tb_pkg;



package body common_tb_pkg is

    procedure echo (t: string := "") is
    begin
        std.textio.write(std.textio.output, t);
    end procedure;

    procedure echoln (t: string := "") is
    begin
        std.textio.write(std.textio.output, t & LF);
    end procedure;

    procedure check_equal(a:integer; b:integer; t:string; s:severity_level:=FAILURE) is
    begin
        if a /= b then
            echoln;
            echoln("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
            echoln("!!!   Error detected for signal: " & t);  
            echoln("!!!   Expected: " & integer'image(b));
            echoln("!!!   Received: " & integer'image(a));
            echoln("!!!");
            report "Values differ!" severity s;
        end if; 
    end procedure;

    procedure check_equal(a:signed; b:signed; t:string; s:severity_level:=FAILURE) is
    begin
        check_equal(to_integer(a), to_integer(b), t, s); 
    end procedure;

    procedure check_equal(a:signed; b:integer; t:string; s:severity_level:=FAILURE) is
    begin
        check_equal(to_integer(a), b, t, s); 
    end procedure;

    procedure check_equal(a:unsigned; b:unsigned; t:string; s:severity_level:=FAILURE) is
    begin
        check_equal(to_integer(a), to_integer(b), t, s); 
    end procedure;

    procedure check_equal(a:unsigned; b:integer; t:string; s:severity_level:=FAILURE) is
    begin
        check_equal(to_integer(a), b, t, s); 
    end procedure;


end common_tb_pkg;