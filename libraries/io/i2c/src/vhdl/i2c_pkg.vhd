-------------------------------------------------------------------------------
--
-- Copyright (C) 2009
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

LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE common_lib.common_pkg.ALL;

PACKAGE i2c_pkg IS

  -- I2C register size settings
  --
  CONSTANT c_i2c_control_adr_w     : NATURAL := 1;   -- fixed
  CONSTANT c_i2c_protocol_adr_w    : NATURAL := 10;  -- 2*10 = 1 kByte is sufficient and fits in 1 M9K RAM block
  CONSTANT c_i2c_result_adr_w      : NATURAL := 10;
  
  CONSTANT c_i2c_dat_w             : NATURAL := 8;   -- bytes
  
  TYPE t_c_i2c_mm IS RECORD
    control_adr_w    : NATURAL; -- = 1, fixed
    protocol_adr_w   : NATURAL;
    protocol_nof_dat : NATURAL;
    result_adr_w     : NATURAL;
    result_nof_dat   : NATURAL;
  END RECORD;
  
  CONSTANT c_i2c_mm : t_c_i2c_mm := (c_i2c_control_adr_w, c_i2c_protocol_adr_w, 2**c_i2c_protocol_adr_w, c_i2c_result_adr_w, 2**c_i2c_result_adr_w);
  
  -- I2C clock rate and comma time settings
  --
  TYPE t_c_i2c_phy IS RECORD
    clk_cnt   : NATURAL;  -- minimal clk_cnt >= 2 when comma_w > 0, when comma_w=0 then minimum clk_cnt = 1
    comma_w   : NATURAL;  -- 2**c_i2c_comma_w * system clock period comma time after I2C start and after each octet, 0 for no comma time
  END RECORD;
  
  CONSTANT c_i2c_bit_rate    : NATURAL := 50;   -- fixed default I2C bit rate in kbps
  CONSTANT c_i2c_comma_w_dis : NATURAL := 0;
  CONSTANT c_i2c_clk_cnt_sim : NATURAL := 2;  -- suits also comma_w > 0
  CONSTANT c_i2c_phy_sim     : t_c_i2c_phy := (1, c_i2c_comma_w_dis);
  
  -- Calculate clk_cnt from system_clock_freq_in_MHz
  FUNCTION func_i2c_calculate_clk_cnt(system_clock_freq_in_MHz, bit_rate_in_kHz : NATURAL) RETURN NATURAL;
  FUNCTION func_i2c_calculate_clk_cnt(system_clock_freq_in_MHz : NATURAL) RETURN NATURAL;
  
  -- Calculate (clk_cnt, comma_w) from system_clock_freq_in_MHz
  FUNCTION func_i2c_calculate_phy(system_clock_freq_in_MHz, comma_w : NATURAL) RETURN t_c_i2c_phy;
  FUNCTION func_i2c_calculate_phy(system_clock_freq_in_MHz          : NATURAL) RETURN t_c_i2c_phy;
  
  -- Select functions
  FUNCTION func_i2c_sel_a_b(sel : BOOLEAN; a, b : t_c_i2c_mm)  RETURN t_c_i2c_mm;
  FUNCTION func_i2c_sel_a_b(sel : BOOLEAN; a, b : t_c_i2c_phy) RETURN t_c_i2c_phy;

END i2c_pkg;

PACKAGE BODY i2c_pkg IS

  FUNCTION func_i2c_calculate_clk_cnt(system_clock_freq_in_MHz, bit_rate_in_kHz : NATURAL) RETURN NATURAL IS
    -- . Adapt c_i2c_clk_freq and c_i2c_bit_rate and c_i2c_clk_cnt will be set appropriately
    -- . Default no comma time is needed, it appeared necessary for the uP based I2C slave in the LOFAR HBA client
    CONSTANT c_clk_cnt_factor : NATURAL := 5;
  BEGIN
    RETURN system_clock_freq_in_MHz  * 1000 / bit_rate_in_kHz / c_clk_cnt_factor - 1;
  END;
  
  FUNCTION func_i2c_calculate_clk_cnt(system_clock_freq_in_MHz : NATURAL) RETURN NATURAL IS
    -- . Adapt c_i2c_clk_freq and c_i2c_bit_rate and c_i2c_clk_cnt will be set appropriately
    -- . Default no comma time is needed, it appeared necessary for the uP based I2C slave in the LOFAR HBA client
    CONSTANT c_clk_cnt_factor : NATURAL := 5;
  BEGIN
    RETURN system_clock_freq_in_MHz  * 1000 / c_i2c_bit_rate / c_clk_cnt_factor - 1;
  END;

  FUNCTION func_i2c_calculate_phy(system_clock_freq_in_MHz, comma_w : NATURAL) RETURN t_c_i2c_phy IS
  BEGIN
    RETURN (func_i2c_calculate_clk_cnt(system_clock_freq_in_MHz), comma_w);
  END;
  
  FUNCTION func_i2c_calculate_phy(system_clock_freq_in_MHz : NATURAL) RETURN t_c_i2c_phy IS
  BEGIN
    RETURN func_i2c_calculate_phy(system_clock_freq_in_MHz, c_i2c_comma_w_dis);
  END;
  
  FUNCTION func_i2c_sel_a_b(sel : BOOLEAN; a, b : t_c_i2c_mm) RETURN t_c_i2c_mm IS
  BEGIN
    IF sel = TRUE THEN
      RETURN a;
    ELSE
      RETURN b;
    END IF;
  END;
  
  FUNCTION func_i2c_sel_a_b(sel : BOOLEAN; a, b : t_c_i2c_phy) RETURN t_c_i2c_phy IS
  BEGIN
    IF sel = TRUE THEN
      RETURN a;
    ELSE
      RETURN b;
    END IF;
  END;
END i2c_pkg;
