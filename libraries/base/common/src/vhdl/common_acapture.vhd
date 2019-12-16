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

-- Purpose: Clock an input from the in_clk domain into out_clk domain
-- Description:
--   Use one FF0 to capture the input in the in_clk domain and then capture
--   that FF output into the out_clk domain with a second FF1.
-- Remark:
-- . With fitter placement or timing constraints it can be ensured that the
--   data path from FF0-Q to FF1-D is small and more or less constants for
--   different designs that use this common_acapture. The common_top.qsf
--   shows this using a LogicLock region constraint for common_acapture that
--   has the size of 1 LAB (= 10 ALM, = 20 FF). It is not possible to set
--   a LogicLock region per ALM. The routing within the LAB can still differ
--   e.g. dependent on g_out_delay_len, however it appears to range between
--   0.385 and 0.478 ps, so within 100 ps.
-- . The purpose of common_acapture is to ensure stable timing between two
--   releated clock domains. The assumption is that the clock phases are such
--   that meta-stability will not occur. Therefore typically g_out_delay_len
--   = 1 could be used.

LIBRARY IEEE, common_lib;
USE IEEE.std_logic_1164.ALL;
USE common_lib.common_pkg.ALL;

ENTITY common_acapture IS
  GENERIC (
    g_rst_level     : STD_LOGIC := '0';
    g_in_delay_len  : POSITIVE := 1;  -- = 1, typically fixed
    g_out_delay_len : POSITIVE := 1   -- >= 1, e.g. use c_meta_delay_len
  );
  PORT (
    in_rst  : IN  STD_LOGIC := '0';
    in_clk  : IN  STD_LOGIC;
    in_dat  : IN  STD_LOGIC;
    in_cap  : OUT STD_LOGIC;  -- typically leave OPEN, available only for monitoring with common_acapture_slv
    out_clk : IN  STD_LOGIC;
    out_cap : OUT STD_LOGIC
  );
END;


ARCHITECTURE str OF common_acapture IS
  
  SIGNAL i_in_cap   : STD_LOGIC;
  
BEGIN

  in_cap <= i_in_cap;
  
  -- pipeline input (all in input clock domain)
  u_async_in : ENTITY work.common_async
  GENERIC MAP (
    g_rst_level => g_rst_level,
    g_delay_len => g_in_delay_len
  )
  PORT MAP (
    rst  => in_rst,
    clk  => in_clk,
    din  => in_dat,
    dout => i_in_cap
  );
  
  -- capture input into output clock domain with first FF, and
  -- additional pipeline output with extra FF when g_out_delay_len > 1 to combat potential meta-stability
  u_async_out : ENTITY work.common_async
  GENERIC MAP (
    g_rst_level => g_rst_level,
    g_delay_len => g_out_delay_len
  )
  PORT MAP (
    rst  => in_rst,
    clk  => out_clk,
    din  => i_in_cap,
    dout => out_cap
  );
  
END str;
