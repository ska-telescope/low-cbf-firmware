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

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.common_pkg.ALL;
USE work.common_mem_pkg.ALL;
USE work.tb_common_pkg.ALL;
USE work.tb_common_mem_pkg.ALL; 

ENTITY tb_common_mem_mux IS 
 GENERIC (    
    g_nof_mosi    : POSITIVE := 16;     -- Number of memory interfaces in the array.                       
    g_mult_addr_w : POSITIVE := 4       -- Address width of each memory-interface element in the array.
  );
END tb_common_mem_mux;

-- Usage:
--   > as 10
--   > run -all
  

ARCHITECTURE tb OF tb_common_mem_mux IS

  CONSTANT clk_period   : TIME    := 10 ns;
  
  CONSTANT c_data_w     : NATURAL := 32; 
  CONSTANT c_test_ram   : t_c_mem := (latency      => 1,
                                      adr_w        => g_mult_addr_w,
                                      dat_w        => c_data_w,
                                      nof_dat      => 2**g_mult_addr_w,
                                      addr_base    => 0,
                                      nof_slaves   => 1,
                                      init_sl      => '0'); 
  SIGNAL rst      : STD_LOGIC;
  SIGNAL clk      : STD_LOGIC := '1'; 
  SIGNAL tb_end   : STD_LOGIC;
  
  SIGNAL mosi_arr : t_mem_mosi_arr(g_nof_mosi - 1 DOWNTO 0); 
  SIGNAL miso_arr : t_mem_miso_arr(g_nof_mosi - 1 DOWNTO 0); 
  SIGNAL mosi     : t_mem_mosi;
  SIGNAL miso     : t_mem_miso;

BEGIN

  clk <= NOT clk OR tb_end AFTER clk_period/2;
  rst <= '1', '0' AFTER clk_period*5;
  
  p_stimuli : PROCESS 
    VARIABLE temp : INTEGER;
  BEGIN
    tb_end <= '0';
    mosi   <= c_mem_mosi_rst;  
      
    -- Write the whole memory range
    FOR I IN 0 TO g_nof_mosi-1 LOOP
      FOR J IN 0 TO 2**g_mult_addr_w-1 LOOP
        proc_mem_mm_bus_wr(I*2**g_mult_addr_w + J, I+J, clk, mosi);  
      END LOOP;
    END LOOP;
    
    -- Read back the whole range and check if data is as expected
    FOR I IN 0 TO g_nof_mosi-1 LOOP
      FOR J IN 0 TO 2**g_mult_addr_w-1 LOOP
        proc_mem_mm_bus_rd(I*2**g_mult_addr_w + J, clk, mosi); 
        proc_common_wait_some_cycles(clk, 1);   
        temp := TO_UINT(miso.rddata(31 DOWNTO 0));  
        IF(temp /= I+J) THEN
          REPORT "Error! Readvalue is not as expected" SEVERITY ERROR;  
        END IF;
      END LOOP;
    END LOOP;
    tb_end <= '1';
    WAIT;
  END PROCESS;

  generation_of_test_rams : FOR I IN 0 TO g_nof_mosi-1 GENERATE 
    u_test_rams : ENTITY work.common_ram_r_w
    GENERIC MAP (
      g_ram       => c_test_ram,
      g_init_file => "UNUSED"
    )
    PORT MAP (
      rst       => rst, 
      clk       => clk, 
      clken     => '1',
      wr_en     => mosi_arr(I).wr, 
      wr_adr    => mosi_arr(I).address(g_mult_addr_w-1 DOWNTO 0),
      wr_dat    => mosi_arr(I).wrdata(c_data_w-1 DOWNTO 0),  
      rd_en     => mosi_arr(I).rd,
      rd_adr    => mosi_arr(I).address(g_mult_addr_w-1 DOWNTO 0),  
      rd_dat    => miso_arr(I).rddata(c_data_w-1 DOWNTO 0),
      rd_val    => miso_arr(I).rdval   
    );
  END GENERATE;
  
  d_dut : ENTITY work.common_mem_mux
  GENERIC MAP (    
    g_nof_mosi    => g_nof_mosi,         
    g_mult_addr_w => g_mult_addr_w  
  )
  PORT MAP (
    mosi_arr => mosi_arr,  
    miso_arr => miso_arr,  
    mosi     => mosi,
    miso     => miso
  );
        
END tb;
