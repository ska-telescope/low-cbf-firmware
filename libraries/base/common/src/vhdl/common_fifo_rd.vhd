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
USE work.common_pkg.ALL;

-- Purpose: Adapt from ready latency 1 to 0 to make a look ahead FIFO
-- Description: -
-- Remark:
-- . Derived from dp_latency_adapter.vhd.
-- . There is no need for a rd_emp output signal, because a show ahead FIFO
--   will have rd_val='0' when it is empty.


ENTITY common_fifo_rd IS
  GENERIC (
    g_dat_w : NATURAL := 18
  );
  PORT (
    rst        : IN  STD_LOGIC;
    clk        : IN  STD_LOGIC;
    -- ST sink: RL = 1
    fifo_req   : OUT STD_LOGIC;
    fifo_dat   : IN  STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    fifo_val   : IN  STD_LOGIC := '0';    
    -- ST source: RL = 0
    rd_req     : IN  STD_LOGIC;
    rd_dat     : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    rd_val     : OUT STD_LOGIC
  );
END common_fifo_rd;


ARCHITECTURE wrap OF common_fifo_rd IS

  
BEGIN

  u_rl0 : ENTITY work.common_rl_decrease
  GENERIC MAP (
    g_adapt       => TRUE,
    g_dat_w       => g_dat_w
  )
  PORT MAP (
    rst           => rst,
    clk           => clk,
    -- ST sink: RL = 1
    snk_out_ready => fifo_req,
    snk_in_dat    => fifo_dat,
    snk_in_val    => fifo_val,
    -- ST source: RL = 0
    src_in_ready  => rd_req,
    src_out_dat   => rd_dat,
    src_out_val   => rd_val
  );
  
END wrap;
