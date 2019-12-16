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


-- Usage: 
--   > as 10
--   > run 10 us
--   in Wave window zoom in and expand out_dat to see the 50 ps delays

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;

ENTITY tb_common_iobuf_in IS
END tb_common_iobuf_in;

ARCHITECTURE tb OF tb_common_iobuf_in IS

  CONSTANT clk_period   : TIME := 10 ns;
  
  CONSTANT c_width      : NATURAL := 8;
  CONSTANT c_delay_init : NATURAL := 0;
  CONSTANT c_delay_incr : NATURAL := 1;
  CONSTANT c_delay_arr  : t_natural_arr(0 TO c_width-1) := array_init(c_delay_init, c_width, c_delay_incr);   -- 0, 1, 2, 3, ...
  
  SIGNAL rst      : STD_LOGIC;
  SIGNAL clk      : STD_LOGIC := '0';

  SIGNAL in_dat   : STD_LOGIC_VECTOR(c_width-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL out_dat  : STD_LOGIC_VECTOR(c_width-1 DOWNTO 0);
  
BEGIN

  clk <= NOT clk  AFTER clk_period/2;
  rst <= '1', '0' AFTER clk_period*7;
  
  in_dat <= NOT(in_dat) WHEN rising_edge(clk);
  
  u_dut : ENTITY work.common_iobuf_in
  GENERIC MAP (
    g_width      => c_width,
    g_delay_arr  => c_delay_arr
  )
  PORT MAP (
    config_rst => rst,
    config_clk => clk,
    in_dat     => in_dat,
    out_dat    => out_dat
  );
        
END tb;
