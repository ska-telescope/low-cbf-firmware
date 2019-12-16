-------------------------------------------------------------------------------
--
-- Copyright (C) 2014
-- ASTRON (Netherlands Institute for Radio Astronomy) <http://www.astron.nl/>
-- P.O.Box 2, 7990 AA Dwingeloo, The Netherlands
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
-------------------------------------------------------------------------------

-- Purpose: Define the list of FPGA technology identifiers
-- Description:
--   The technology dependent IP is organised per FPGA device type, board type
--   and tools type. A numebr of constants are defined below for board device and
--   tools supported. Within each technology wrapper there 3 terms should be used
--   to define whihc IP should be selected
-- Remark:
-- . The package also contains some low level functions that often are copied
--   from common_pkg.vhd. They need to be redefined in this technology_pkg.vhd
--   because the common_lib also use technology dependent IP like RAM, FIFO,
--   DDIO. Therefore common_lib can not be used in the IP wrappers for those
--   IP blocks, because common_lib is compiled later.
-- . For technology wrappers that are not used by components in common_lib the
--   common_pkg.vhd can be used. Similar technology wrappers that are not used
--   by components in dp_lib can use the dp_stream_pkg.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.MATH_REAL.ALL;

PACKAGE technology_pkg IS

   TYPE t_tech_slv_2_arr       IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(1 DOWNTO 0);
   TYPE t_tech_slv_3_arr       IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(2 DOWNTO 0);
   TYPE t_tech_slv_4_arr       IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(3 DOWNTO 0);
   TYPE t_tech_slv_5_arr       IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(4 DOWNTO 0);
   TYPE t_tech_slv_7_arr       IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(6 DOWNTO 0);

   TYPE t_technology IS RECORD
      board_technology        : INTEGER;
      device_technology       : INTEGER;
      tools_technology        : INTEGER;
   END RECORD;

   -- Board identifiers in any order
   CONSTANT c_tech_board_any              : INTEGER := 0;
   CONSTANT c_tech_board_vcu108           : INTEGER := 1;
   CONSTANT c_tech_board_vcu110           : INTEGER := 2;
   CONSTANT c_tech_board_kcu105           : INTEGER := 4;
   CONSTANT c_tech_board_gemini_poc       : INTEGER := 8;
   CONSTANT c_tech_board_gemini_lru       : INTEGER := 16;
   CONSTANT c_tech_board_kcu116           : INTEGER := 32;
   CONSTANT c_tech_board_gemini_xh_lru    : INTEGER := 64;
   CONSTANT c_tech_board_vcu128           : INTEGER := 128;

   CONSTANT c_tech_device_any             : INTEGER := 0;
   CONSTANT c_tech_device_virtex4         : INTEGER := 1;
   CONSTANT c_tech_device_stratixiv       : INTEGER := 2;
   CONSTANT c_tech_device_virtex6         : INTEGER := 4;
   CONSTANT c_tech_device_virtex7         : INTEGER := 8;
   CONSTANT c_tech_device_arria10         : INTEGER := 16;
   CONSTANT c_tech_device_arria10_e3sge3  : INTEGER := 32;
   CONSTANT c_tech_device_ultrascale      : INTEGER := 64;
   CONSTANT c_tech_device_ultrascalep     : INTEGER := 128;

   CONSTANT c_tech_tools_any              : INTEGER := 0;

   CONSTANT c_tech_vendor_xilinx          : INTEGER := 1;



   -- Technology identifiers
   CONSTANT c_tech_inferred         : t_technology := (board_technology => c_tech_board_any,
                                                       device_technology => c_tech_device_any,
                                                       tools_technology => c_tech_tools_any);

   CONSTANT c_tech_virtex4          : t_technology := (board_technology => c_tech_board_any,        -- e.g. used on RSP3 for Lofar
                                                       device_technology => c_tech_device_virtex4,
                                                       tools_technology => c_tech_tools_any);

   CONSTANT c_tech_stratixiv        : t_technology := (board_technology => c_tech_board_any,        -- e.g. used on UniBoard1
                                                       device_technology => c_tech_device_stratixiv,
                                                       tools_technology => c_tech_tools_any);

   CONSTANT c_tech_virtex6          : t_technology := (board_technology => c_tech_board_any,        -- e.g. used on Roach2 for Casper
                                                       device_technology => c_tech_device_virtex6,
                                                       tools_technology => c_tech_tools_any);

   CONSTANT c_tech_virtex7          : t_technology := (board_technology => c_tech_board_any,        -- e.g. used on Roach3 for Casper
                                                       device_technology => c_tech_device_virtex7,
                                                       tools_technology => c_tech_tools_any);

   CONSTANT c_tech_arria10          : t_technology := (board_technology => c_tech_board_any,        -- e.g. used on UniBoard2 first proto (1 board version "00" may 2015)
                                                       device_technology => c_tech_device_arria10,
                                                       tools_technology => c_tech_tools_any);

   CONSTANT c_tech_arria10_e3sge3   : t_technology := (board_technology => c_tech_board_any,        -- e.g. used on UniBoard2 second run (7 boards version "01" dec 2015)
                                                       device_technology => c_tech_device_arria10_e3sge3,
                                                       tools_technology => c_tech_tools_any);

   CONSTANT c_tech_xcvu095          : t_technology := (board_technology => c_tech_board_vcu108,     -- e.g. used on Xilinx VCU108 evaluation board
                                                       device_technology => c_tech_device_ultrascale,
                                                       tools_technology => c_tech_tools_any);

   CONSTANT c_tech_xcvu190          : t_technology := (board_technology => c_tech_board_vcu110,     -- e.g. used on Xilinx VCU110 evaluation board
                                                       device_technology => c_tech_device_ultrascale,
                                                       tools_technology => c_tech_tools_any);

   CONSTANT c_tech_xcku040          : t_technology := (board_technology => c_tech_board_kcu105,     -- e.g. used on Xilinx KCU105 evaluation board
                                                       device_technology => c_tech_device_ultrascale,
                                                       tools_technology => c_tech_tools_any);

   CONSTANT c_tech_xcku5p           : t_technology := (board_technology => c_tech_board_kcu116,     -- e.g. used on Xilinx KCU116 evaluation board
                                                       device_technology => c_tech_device_ultrascalep,
                                                       tools_technology => c_tech_tools_any);

   CONSTANT c_tech_xcvu9p           : t_technology := (board_technology => c_tech_board_gemini_poc, -- e.g. used on Gemini POC
                                                       device_technology => c_tech_device_ultrascalep,
                                                       tools_technology => c_tech_tools_any);

   CONSTANT c_tech_gemini           : t_technology := (board_technology => c_tech_board_gemini_lru, -- e.g. used on Gemini LRU
                                                       device_technology => c_tech_device_ultrascalep,
                                                       tools_technology => c_tech_tools_any);

   CONSTANT c_tech_gemini_xh        : t_technology := (board_technology => c_tech_board_gemini_xh_lru, -- e.g. used on Gemini XH LRU
                                                       device_technology => c_tech_device_ultrascalep,
                                                       tools_technology => c_tech_tools_any);

   CONSTANT c_tech_vcu128           : t_technology := (board_technology => c_tech_board_vcu128, -- e.g. used on vcu128 HBM evaluation board
                                                       device_technology => c_tech_device_ultrascalep,
                                                       tools_technology => c_tech_tools_any);

   -- Functions
   FUNCTION tech_is_device(sel : t_technology; check : INTEGER)  RETURN BOOLEAN;
   FUNCTION tech_is_board(sel : t_technology; check : INTEGER)  RETURN BOOLEAN;
   FUNCTION tech_is_vendor(sel : t_technology; check : INTEGER) RETURN BOOLEAN;

   FUNCTION tech_max(a, b : INTEGER) RETURN INTEGER;

   FUNCTION tech_sel_a_b(sel, check, a, b : STRING)  RETURN STRING;
   FUNCTION tech_sel_a_b(sel : BOOLEAN; a, b : STRING)  RETURN STRING;
   FUNCTION tech_sel_a_b(sel : INTEGER; a, b : STRING)  RETURN STRING;
   FUNCTION tech_sel_a_b(sel : BOOLEAN; a, b : INTEGER) RETURN INTEGER;

   FUNCTION tech_true_log2(n : NATURAL) RETURN NATURAL;  -- tech_true_log2(n) = log2(n)
   FUNCTION tech_ceil_log2(n : NATURAL) RETURN NATURAL;  -- tech_ceil_log2(n) = log2(n), but force tech_ceil_log2(1) = 1

   FUNCTION tech_ceil_div(n, d : NATURAL) RETURN NATURAL;   -- tech_ceil_div    = n/d + (n MOD d)/=0

   FUNCTION tech_fix_type(a : STD_LOGIC) RETURN STD_LOGIC_VECTOR;
   FUNCTION tech_fix_type(a : STD_LOGIC) RETURN STD_LOGIC;
   FUNCTION tech_fix_type(a : STD_LOGIC_VECTOR) RETURN STD_LOGIC;

END technology_pkg;

PACKAGE BODY technology_pkg IS


   -- -ve values return false if match occurs
   -- +ve values return true if macth occurs
   FUNCTION tech_is_device(sel : t_technology; check : INTEGER)  RETURN BOOLEAN IS
   BEGIN
      IF check > 0 THEN
         -- Assume false unless proven true
         IF (to_unsigned(check, 32) AND to_unsigned(sel.device_technology, 32)) /= 0 THEN
            RETURN TRUE;
         ELSE
            RETURN FALSE;
         END IF;
      ELSIF check = 0 THEN
         RETURN TRUE;
      ELSE
         -- Assuem true unless bit mask true
         IF (to_unsigned(-check, 32) AND to_unsigned(sel.device_technology, 32)) /= 0 THEN
            RETURN FALSE;
         ELSE
            RETURN TRUE;
         END IF;
      END IF;
   END;

   -- -ve values return false if match occurs
   -- +ve values return true if match occurs
   FUNCTION tech_is_board(sel : t_technology; check : INTEGER)  RETURN BOOLEAN IS
   BEGIN
      IF check > 0 THEN
         -- Assume false unless proven true
         IF (to_unsigned(check, 32) AND to_unsigned(sel.board_technology, 32)) /= 0 THEN
            RETURN TRUE;
         ELSE
            RETURN FALSE;
         END IF;
      ELSIF check = 0 THEN
         RETURN TRUE;
      ELSE
         -- Assuem true unless bit mask true
         IF (to_unsigned(-check, 32) AND to_unsigned(sel.board_technology, 32)) /= 0 THEN
            RETURN FALSE;
         ELSE
            RETURN TRUE;
         END IF;
      END IF;
   END;


   FUNCTION tech_is_vendor(sel : t_technology; check : INTEGER)  RETURN BOOLEAN IS
   BEGIN
      IF check = c_tech_vendor_xilinx THEN
         IF sel.device_technology = c_tech_device_any OR sel.device_technology = c_tech_device_virtex4 OR
            sel.device_technology = c_tech_device_virtex6 OR sel.device_technology = c_tech_device_virtex7 OR
            sel.device_technology = c_tech_device_ultrascale OR sel.device_technology = c_tech_device_ultrascalep THEN
            RETURN TRUE;
         END IF;
      ELSE
         RETURN FALSE;
      END IF;
   END;

   FUNCTION tech_max(a, b : INTEGER) RETURN INTEGER IS
   BEGIN
      IF a>b THEN RETURN a; ELSE RETURN b; END IF;
   END;

   FUNCTION tech_sel_a_b(sel, check, a, b : STRING) RETURN STRING IS
   BEGIN
      IF sel=check THEN RETURN a; ELSE RETURN b; END IF;
   END;

   FUNCTION tech_sel_a_b(sel : BOOLEAN; a, b : STRING) RETURN STRING IS
   BEGIN
      IF sel=TRUE THEN RETURN a; ELSE RETURN b; END IF;
   END;

   FUNCTION tech_sel_a_b(sel : INTEGER; a, b : STRING) RETURN STRING IS
   BEGIN
      IF sel/=0 THEN RETURN a; ELSE RETURN b; END IF;
   END;

   FUNCTION tech_sel_a_b(sel : BOOLEAN; a, b : INTEGER) RETURN INTEGER IS
   BEGIN
      IF sel=TRUE THEN RETURN a; ELSE RETURN b; END IF;
   END;

   FUNCTION tech_true_log2(n : NATURAL) RETURN NATURAL IS
   -- Purpose: For calculating extra vector width of existing vector
   -- Description: Return mathematical ceil(log2(n))
   --   n    log2()
   --   0 -> -oo  --> FAILURE
   --   1 ->  0
   --   2 ->  1
   --   3 ->  2
   --   4 ->  2
   --   5 ->  3
   --   6 ->  3
   --   7 ->  3
   --   8 ->  3
   --   9 ->  4
   --   etc, up to n = NATURAL'HIGH = 2**31-1
   BEGIN
      RETURN natural(integer(ceil(log2(real(n)))));
   END;

   FUNCTION tech_ceil_log2(n : NATURAL) RETURN NATURAL IS
   -- Purpose: For calculating vector width of new vector
   -- Description:
   --   Same as tech_true_log2() except tech_ceil_log2(1) = 1, which is needed to support
   --   the vector width width for 1 address, to avoid NULL array for single
   --   word register address.
   BEGIN
      IF n = 1 THEN
         RETURN 1;  -- avoid NULL array
      ELSE
         RETURN tech_true_log2(n);
      END IF;
   END;

   FUNCTION tech_ceil_div(n, d : NATURAL) RETURN NATURAL IS
   BEGIN
      RETURN n/d + tech_sel_a_b(n MOD d = 0, 0, 1);
   END;

   -- Dynamically sort out conversion between 1 bit vector and std logic
   FUNCTION tech_fix_type(a : STD_LOGIC) RETURN STD_LOGIC_VECTOR IS
      VARIABLE ret   : STD_LOGIC_VECTOR(0 DOWNTO 0);
   BEGIN
      ret(0) := a;
      RETURN ret;
   END;

   FUNCTION tech_fix_type(a : STD_LOGIC) RETURN STD_LOGIC IS
   BEGIN
      RETURN a;
   END;

   FUNCTION tech_fix_type(a : STD_LOGIC_VECTOR) RETURN STD_LOGIC IS
   BEGIN
      RETURN a(0);
   END;

END technology_pkg;
