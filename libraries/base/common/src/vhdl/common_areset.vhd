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


-- Purpose: Immediately apply reset and synchronously release it at rising clk
-- Description:
--   Using common_areset is equivalent to using common_async with same signal
--   applied to rst and din.

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE work.common_pkg.ALL;

ENTITY common_areset IS
  GENERIC (
    g_rst_level : STD_LOGIC := '1';
    g_delay_len : NATURAL   := c_meta_delay_len
  );
  PORT (
    in_rst    : IN  STD_LOGIC;
    clk       : IN  STD_LOGIC;
    out_rst   : OUT STD_LOGIC
  );
END;


ARCHITECTURE str OF common_areset IS
 
  CONSTANT c_rst_level_n : STD_LOGIC := NOT g_rst_level;
  
BEGIN

  -- When in_rst becomes g_rst_level then out_rst follows immediately (asynchronous reset apply).
  -- When in_rst becomes NOT g_rst_level then out_rst follows after g_delay_len cycles (synchronous reset release).
  
  -- This block can also synchronise other signals than reset:
  -- . g_rst_level = '0': output asynchronoulsy follows the falling edge input and synchronises the rising edge input.
  -- . g_rst_level = '1': output asynchronoulsy follows the rising edge input and synchronises the falling edge input.
  
  u_async : ENTITY work.common_async
  GENERIC MAP (
    g_rst_level => g_rst_level,
    g_delay_len => g_delay_len
  )
  PORT MAP (
    rst  => in_rst,
    clk  => clk,
    din  => c_rst_level_n,
    dout => out_rst
  );
  
END str;
