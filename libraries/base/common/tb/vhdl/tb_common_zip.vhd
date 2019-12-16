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
--
-- Purpose: Test bench for common_zip
-- Features:
--
-- Usage:
-- > as 10
-- > run -all
-- Observe manually in Wave Window that the values of the in_dat_arr are zipped
-- to the out_dat vector. 

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;
USE work.common_lfsr_sequences_pkg.ALL;
USE work.tb_common_pkg.ALL;


ENTITY tb_common_zip IS
  GENERIC (
    g_nof_streams : natural := 3;  -- Number of input streams to be zipped
    g_dat_w       : natural := 8
  );
END tb_common_zip;


ARCHITECTURE tb OF tb_common_zip IS

  CONSTANT clk_period   : TIME      := 10 ns;
  CONSTANT c_rl         : NATURAL   := 1;     -- Read Latency = 1

  SIGNAL rst         : STD_LOGIC;
  SIGNAL clk         : STD_LOGIC := '0';
  SIGNAL tb_end      : STD_LOGIC := '0';

  SIGNAL ready       : STD_LOGIC := '1';       -- Ready is always '1'
  SIGNAL in_dat_arr  : t_slv_64_arr(g_nof_streams-1 DOWNTO 0);  
  SIGNAL in_val      : STD_LOGIC := '1';
  SIGNAL out_dat     : std_logic_vector(g_dat_w-1 DOWNTO 0); 
  SIGNAL out_val     : std_logic;                            
  SIGNAL ena         : STD_LOGIC := '1';
  SIGNAL ena_mask    : STD_LOGIC := '1';
  SIGNAL enable      : STD_LOGIC := '1';
BEGIN

  clk    <= NOT clk OR tb_end AFTER clk_period/2;
  rst    <= '1', '0' AFTER 7 * clk_period;
  tb_end <= '0', '1' AFTER 1 us;
  
  gen_data : FOR I IN 0 TO g_nof_streams-1 GENERATE
    proc_common_gen_data(c_rl, I*10, rst, clk, enable, ready, in_dat_arr(I), in_val);
  END GENERATE;
  
  -- The "ena" forms the dutu cycle for the in_val signal
  proc_common_gen_pulse(1, g_nof_streams, '1', clk, ena); 
   
  -- The "ena_mask" creates a gap between series of incoming packets in order
  -- to simulate the starting and stopping of the incoming streams. 
  proc_common_gen_pulse(g_nof_streams*10, g_nof_streams*15, '1', clk, ena_mask);  
  enable <= ena and ena_mask;
  
  u_dut : ENTITY work.common_zip
  GENERIC MAP (
    g_nof_streams => g_nof_streams, 
    g_dat_w       => g_dat_w       
  )
  PORT MAP (
    rst        => rst,
    clk        => clk,
    in_val     => in_val,
    in_dat_arr => in_dat_arr,
    out_val    => out_val,   
    out_dat    => out_dat   
  );
  
END tb;

