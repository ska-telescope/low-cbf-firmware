-------------------------------------------------------------------------------
--
-- Copyright (C) 2010
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

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;

-- Purpose:
--   Convert signed integer to semi-floating point number.
-- Description:
--   If the output data width <= the input data width then output data MSbit is
--   a one bit exponent and the rest of the output data bits are the signed
--   mantissa. When the exponent bit is '1' then the mantissa should be
--   mutliplied with the factor 2^(input width-(output width-1)) to obtain the
--   floating point value, otherwise factor is 1. For example:
--
--   in_dat[53:0] -> out_dat[31]   = exponent bit '0' for factor 1 or '1' for
--                                   factor 2^(54-(32-1))=2^23 
--                   out_dat[30:0] = signed mantissa
--
--   If the output data width > the input data width then the output data
--   exponent will be '0' and the output data will have no loss in accuracy.
-- Remark:
-- . The function uses truncation (so not rounding). For small numbers with
--   exponent bit is '0' the manitissa represents the input exactly, for
--   large numbers with exponent bit is '1' the manitissa is a truncated value
--   of the input data.
-- . The pipeline is 1 because the output is registered or when 2 then also the
--   input will be registered.

ENTITY common_int2float IS
  GENERIC (
    g_pipeline  : NATURAL := 1
  );
  PORT (
    clk        : IN   STD_LOGIC;
    clken      : IN   STD_LOGIC := '1';
    in_dat     : IN   STD_LOGIC_VECTOR;
    out_dat    : OUT  STD_LOGIC_VECTOR
  );
END common_int2float;


ARCHITECTURE rtl OF common_int2float IS

  SIGNAL reg_dat      : STD_LOGIC_VECTOR(in_dat'RANGE);
  SIGNAL nxt_reg_dat  : STD_LOGIC_VECTOR(in_dat'RANGE);
  SIGNAL nxt_out_dat  : STD_LOGIC_VECTOR(out_dat'RANGE);
  
BEGIN

  -- registers
  gen_reg_input : IF g_pipeline=2 GENERATE
    p_reg_input : PROCESS(clk)
    BEGIN
      IF rising_edge(clk) THEN
        IF clken='1' THEN
          reg_dat <= in_dat;
        END IF;
      END IF;
    END PROCESS;
  END GENERATE;
  no_reg_input : IF g_pipeline=1 GENERATE
    reg_dat <= in_dat;
  END GENERATE;
  ASSERT g_pipeline=1 OR g_pipeline=2
    REPORT "common_int2float: pipeline value not supported"
    SEVERITY FAILURE;
  
  p_clk : PROCESS(clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF clken='1' THEN
        out_dat <= nxt_out_dat;
      END IF;
    END IF;
  END PROCESS;
  
  map_float : IF out_dat'LENGTH > in_dat'LENGTH GENERATE
    nxt_out_dat <= '0' & RESIZE_SVEC(reg_dat, out_dat'LENGTH-1);
  END GENERATE;
  
  gen_float : IF out_dat'LENGTH <= in_dat'LENGTH GENERATE
    p_float: PROCESS (reg_dat)
    BEGIN
      IF UNSIGNED(reg_dat(in_dat'HIGH DOWNTO out_dat'HIGH-1))=0 OR
           SIGNED(reg_dat(in_dat'HIGH DOWNTO out_dat'HIGH-1))=-1 THEN
        nxt_out_dat <= '0' & reg_dat(out_dat'HIGH-1 DOWNTO 0);
      ELSE
        nxt_out_dat <= '1' & reg_dat(in_dat'HIGH DOWNTO in_dat'HIGH-out_dat'HIGH+1);      
      END IF;
    END PROCESS;
  END GENERATE;
    
END rtl;   
