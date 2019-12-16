-------------------------------------------------------------------------------
--
-- Copyright (C) 2011
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

-------------------------------------------------------------------------------
-- 
-- Purpose: Decompose a single MM interface into an array of MM interfaces.
-- Description:
--   Inverse operation of common_mem_mux.
--
--                                      g_rd_latency
--                                     ______________
--        use index of mosi_arr        |            |
--        with active rd or wr  ---+-->| delay line |--\
--                                 |   |____________|  |
--                                 |                   |
--                   selected      v                   |
--   mosi_arr -----> mosi_address[h:w]-----------------------------> mosi
--                                                     |
--                                            selected v
--   miso_arr <-------------------------------miso_arr[ ]<--------- miso
--
--        . not selected mosi_arr are ignored
--        . not selected miso_arr get c_mem_miso_rst
--
-- Remarks:
-- . In simulation selecting an unused element address will cause a simulation
--   failure. Therefore the element index is only accepted when it is in the
--   g_nof_mosi-1 DOWNTO 0 range.
-- . In case common_mem_demux and common_mem_mux would be used in series, then
--   only the one needs to account for g_rd_latency>0, the other can use 0.
--
-------------------------------------------------------------------------------


LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;

ENTITY common_mem_demux IS
  GENERIC (    
    g_nof_mosi    : POSITIVE := 256;     -- Number of memory interfaces in the array.
    g_mult_addr_w : POSITIVE := 8;       -- Address width of each memory-interface element in the muliplexed array.
    g_rd_latency  : NATURAL := 0
  );
  PORT (
    clk      : IN  STD_LOGIC := '0';   -- only used when g_rd_latency > 0
    mosi_arr : IN  t_mem_mosi_arr(g_nof_mosi - 1 DOWNTO 0); 
    miso_arr : OUT t_mem_miso_arr(g_nof_mosi - 1 DOWNTO 0);
    mosi     : OUT t_mem_mosi;
    miso     : IN  t_mem_miso := c_mem_miso_rst
  );
END common_mem_demux;

ARCHITECTURE rtl OF common_mem_demux IS
  
  CONSTANT c_index_w        : NATURAL := ceil_log2(g_nof_mosi);
  CONSTANT c_total_addr_w   : NATURAL := c_index_w + g_mult_addr_w;

  SIGNAL index_arr : t_natural_arr(0 TO g_rd_latency);
  SIGNAL index_rw  : NATURAL;  -- read or write access
  SIGNAL index_rd  : NATURAL;  -- read response

BEGIN

  gen_single : IF g_nof_mosi=1 GENERATE 
    mosi        <= mosi_arr(0);
    miso_arr(0) <= miso;
  END GENERATE;
    
  gen_multiple : IF g_nof_mosi>1 GENERATE 
    -- The activated element of the array is detected here
    p_index : PROCESS(mosi_arr)
    BEGIN
      index_arr(0) <= 0;
      FOR I IN 0 TO g_nof_mosi-1 LOOP
        IF mosi_arr(I).wr='1' OR mosi_arr(I).rd='1' THEN
          index_arr(0) <= I;
        END IF;
      END LOOP;
    END PROCESS;

    -- Pipeline the index of the activated element to account for the read latency
    p_clk : PROCESS(clk)
    BEGIN
      IF rising_edge(clk) THEN
        index_arr(1 TO g_rd_latency) <= index_arr(0 TO g_rd_latency-1);
      END IF;
    END PROCESS;
    
    index_rw <= index_arr(0);
    index_rd <= index_arr(g_rd_latency);
    
    -- Master access, can be write or read
    p_mosi : PROCESS(mosi_arr, index_rw)
    BEGIN
      mosi <= mosi_arr(index_rw);
      mosi.address(c_total_addr_w-1 DOWNTO g_mult_addr_w) <= TO_UVEC(index_rw, c_index_w);
    END PROCESS;
    
    -- Slave response to read access after g_rd_latency clk cycles
    p_miso : PROCESS(miso, index_rd)
    BEGIN
      miso_arr <= (OTHERS=>c_mem_miso_rst);
      miso_arr(index_rd) <= miso;
    END PROCESS;
  END GENERATE; 
  
END rtl;
