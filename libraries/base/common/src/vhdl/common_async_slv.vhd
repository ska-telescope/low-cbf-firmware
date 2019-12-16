-------------------------------------------------------------------------------
--
-- Copyright (C) 2012
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

-- Purpose: Clock an asynchronous input slv into the clk domain
-- Description:
--   See common_async.
-- Remark:

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE work.common_pkg.ALL;

ENTITY common_async_slv IS
  GENERIC (
    g_rst_level : STD_LOGIC := '0';
    g_delay_len : POSITIVE := c_meta_delay_len   -- use common_pipeline if g_delay_len=0 for wires only is also needed
  );
  PORT (
    rst  : IN  STD_LOGIC := '0';
    clk  : IN  STD_LOGIC;
    din  : IN  STD_LOGIC_VECTOR;
    dout : OUT STD_LOGIC_VECTOR
  );
END;

ARCHITECTURE str OF common_async_slv IS
BEGIN

  gen_slv: FOR I IN dout'RANGE GENERATE
    u_common_async : ENTITY work.common_async
    GENERIC MAP (
      g_rst_level => g_rst_level,
      g_delay_len => g_delay_len
    )
    PORT MAP (
      rst  => rst,
      clk  => clk,
      din  => din(I),
      dout => dout(I)
    );
  END GENERATE;
  
END str;
