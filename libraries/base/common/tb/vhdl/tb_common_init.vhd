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
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;

ENTITY tb_common_init IS
END tb_common_init;

ARCHITECTURE tb OF tb_common_init IS

  CONSTANT c_reset_len  : NATURAL := 3;
  CONSTANT c_latency_w  : NATURAL := 4;
  
  CONSTANT clk_period   : TIME := 10 ns;
  
  SIGNAL rst      : STD_LOGIC;
  SIGNAL clk      : STD_LOGIC := '0';
  SIGNAL hold     : STD_LOGIC;
  SIGNAL init     : STD_LOGIC;

BEGIN

  clk <= NOT clk  AFTER clk_period/2;
  
  u_reset : ENTITY work.common_areset
  GENERIC MAP (
    g_rst_level => '1',  -- power up default will be inferred in FPGA
    g_delay_len => c_reset_len
  )
  PORT MAP (
    in_rst    => '0',    -- release reset after some clock cycles
    clk       => clk,
    out_rst   => rst
  );
    
  u_init: ENTITY work.common_init
  GENERIC MAP (
    g_latency_w => c_latency_w
  )
  PORT MAP (
    rst   => rst,
    clk   => clk,
    hold  => hold,
    init  => init
  );
      
END tb;
