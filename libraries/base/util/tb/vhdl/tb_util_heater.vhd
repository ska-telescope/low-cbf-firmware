-------------------------------------------------------------------------------
--
-- Copyright (C) 2010
-- ASTRON (Netherlands Institute for Radio Astronomy) <http://www.astron.nl/>
-- JIVE (Joint Institute for VLBI in Europe) <http://www.jive.nl/>
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
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE common_lib.tb_common_mem_pkg.ALL;
USE work.util_heater_pkg.ALL;


ENTITY tb_util_heater IS
END tb_util_heater;


ARCHITECTURE tb OF tb_util_heater IS

  CONSTANT mm_clk_period     : TIME := 8 ns;
  CONSTANT st_clk_period     : TIME := 5 ns;
  
  CONSTANT c_word_heater_on  : INTEGER := -1; -- 16#FFFFFFFF#;
  CONSTANT c_word_heater_off : INTEGER := 0;
  
  CONSTANT c_time_heater_on  : NATURAL := 100;
  CONSTANT c_time_heater_off : NATURAL := 20;
  
  CONSTANT c_nof_mac4        : NATURAL := 1;
  CONSTANT c_pipeline        : NATURAL := 1;
  CONSTANT c_nof_ram         : NATURAL := 2;
  CONSTANT c_nof_logic       : NATURAL := 3;
  
  CONSTANT c_reg_nof_words   : NATURAL := 2;  -- derived from c_nof_mac4 / c_word_w
  
  SIGNAL tb_end        : STD_LOGIC := '0';
  SIGNAL mm_rst        : STD_LOGIC;
  SIGNAL mm_clk        : STD_LOGIC := '0';
  SIGNAL st_rst        : STD_LOGIC;
  SIGNAL st_clk        : STD_LOGIC := '0';
  
  SIGNAL mm_mosi       : t_mem_mosi;
  SIGNAL mm_miso       : t_mem_miso;
  
BEGIN

  -- as 10
  -- run -all
  
  mm_clk <= NOT mm_clk OR tb_end AFTER mm_clk_period/2;
  st_clk <= NOT st_clk OR tb_end AFTER st_clk_period/2;
  
  mm_rst <= '1', '0' AFTER mm_clk_period*5;
  st_rst <= '1', '0' AFTER st_clk_period*5;
  
  p_mm_stimuli : PROCESS
  BEGIN
    mm_miso <= c_mem_miso_rst;
    mm_mosi <= c_mem_mosi_rst;
    
    -- Use while instead of WAIT UNTIL mm_rst='0' because wait until requires a change
    WHILE mm_rst='1' LOOP
      WAIT UNTIL rising_edge(mm_clk);
    END LOOP;

    FOR I IN 0 TO 9 LOOP
      WAIT UNTIL rising_edge(mm_clk);
    END LOOP;
    
    FOR I IN 0 TO c_reg_nof_words-1 LOOP
      proc_mem_mm_bus_wr(I, c_word_heater_on, mm_clk, mm_miso, mm_mosi);  -- Enable multiplier 31 : 0
    END LOOP;
    
    FOR I IN 0 TO c_time_heater_on-1 LOOP
      WAIT UNTIL rising_edge(mm_clk);
    END LOOP;
    
    FOR I IN 0 TO c_reg_nof_words-1 LOOP
      proc_mem_mm_bus_wr(I, c_word_heater_off, mm_clk, mm_miso, mm_mosi);  -- Disable multiplier 31 : 0
    END LOOP;
    
    FOR I IN 0 TO c_time_heater_off-1 LOOP
      WAIT UNTIL rising_edge(mm_clk);
    END LOOP;
    tb_end <= '1';
    WAIT;
  END PROCESS;
  
  dut : ENTITY work.util_heater
  GENERIC MAP (
    g_nof_mac4   => c_nof_mac4,
    g_pipeline   => c_pipeline,
    g_nof_ram    => c_nof_ram,
    g_nof_logic  => c_nof_logic
  )
  PORT MAP (
    mm_rst  => mm_rst,  -- MM is the microprocessor control clock domain 
    mm_clk  => mm_clk,
    st_rst  => st_rst,  -- ST is the DSP clock domain
    st_clk  => st_clk,
    -- Memory Mapped Slave
    sla_in  => mm_mosi,
    sla_out => mm_miso
  );
  
END tb;
