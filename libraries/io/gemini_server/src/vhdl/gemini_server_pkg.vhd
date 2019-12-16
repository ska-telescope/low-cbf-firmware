----------------------------------
-- Copyright (C) 2017
-- CSIRO (Commonwealth Scientific and Industrial Research Organization) <http://www.csiro.au/>
-- GPO Box 1700, Canberra, ACT 2601, Australia
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
--   Author           Date      Version comments
--   John Matthews    Dec 2017  Original
-----------------------------------

-- Purpose: Gemini Server specific constants and functions
--
-- Description: 
--   
-- Remarks:
--

LIBRARY IEEE, common_lib;
USE IEEE.std_logic_1164.ALL;
USE common_lib.common_pkg.ALL;

PACKAGE gemini_server_pkg IS

    -- Gemini Protocol version field
    CONSTANT c_gemver : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"01"; -- Defined by Gemini Protocol

    -- Gemini Protocol request command codes
    CONSTANT c_gemreq_connect : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"01"; 
    CONSTANT c_gemreq_read_inc : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"03"; 
    CONSTANT c_gemreq_read_rep : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"02"; 
    CONSTANT c_gemreq_write_inc : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"05"; 
    CONSTANT c_gemreq_write_rep : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"04"; 

    -- Gemini Protocol response command codes
    CONSTANT c_gemresp_ack : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"10"; 
    CONSTANT c_gemresp_nackt : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"20"; 
    CONSTANT c_gemresp_nackp : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"40"; 

    -- MMCmd bit encodings
    -- Note how bits match Gemini Protocol command encodings
    CONSTANT c_mmcmd_w : INTEGER := 8;
    CONSTANT c_mmcmd_type : INTEGER := 0; -- ie b0
    CONSTANT c_mmcmd_read : INTEGER := 1;
    CONSTANT c_mmcmd_write : INTEGER := 2;
    CONSTANT c_mmcmd_connect : INTEGER := 3;
    CONSTANT c_mmcmd_ack : INTEGER := 4;
    CONSTANT c_mmcmd_nackt : INTEGER := 5;
    CONSTANT c_mmcmd_nackp : INTEGER := 6;
    CONSTANT c_mmcmd_replay : INTEGER := 7;

    -- Width of fields used by Gemini Protocol
    CONSTANT c_gempro_ver_w : INTEGER := 8;
    CONSTANT c_gempro_cmd_w : INTEGER := 8;
    CONSTANT c_gempro_csn_w : INTEGER := 8;
    CONSTANT c_gempro_ssn_w : INTEGER := 8;
    CONSTANT c_gempro_nreg_w : INTEGER := 16;
    CONSTANT c_gempro_addr_w : INTEGER := 32;
    CONSTANT c_gempro_fc_w : INTEGER := 16;
    CONSTANT c_gempro_reg_w : INTEGER := 32;

END gemini_server_pkg;

PACKAGE BODY gemini_server_pkg IS

END gemini_server_pkg;

