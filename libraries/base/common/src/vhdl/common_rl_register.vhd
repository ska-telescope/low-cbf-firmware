-------------------------------------------------------------------------------
--
-- Copyright (C) 2013
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

-- >>> Ported from UniBoard dp_pipeline_ready for fixed RL 1 --> 0 --> 1

LIBRARY IEEE, common_lib;
USE IEEE.std_logic_1164.ALL;

-- Purpose: Register both the data and the ready by going from RL=1 to 0 to 1.
-- Description: -
-- Remark:
-- . To only register the data dp_pipeline is suited. To register the ready
--   this ported dp_pipeline_ready is needed. Pipelining the ready also
--   pipelines the data, because the RL goes from 1 --> 0 --> 1.
-- . Conform the RL specification it is correct to use g_hold_dat_en = FALSE.
--   However use g_hold_dat_en = TRUE if functionaly the application requires
--   src_out_dat to hold the last valid value when src_out_val goes low.
--   Otherwise a new valid snk_in_dat that arrives with RL = 0 will already
--   set src_out_dat before src_out_val becomes valid due to src_in_ready.


ENTITY common_rl_register IS
  GENERIC (
    g_adapt       : BOOLEAN := TRUE;  -- default when TRUE then register RL 1 --> 0 --> 1, else then implement wires
    g_hold_dat_en : BOOLEAN := TRUE;  -- default when TRUE hold the src_out_dat until the next active src_out_val, else just pass on snk_in_dat as wires
    g_dat_w       : NATURAL := 18
  );
  PORT (
    rst           : IN  STD_LOGIC;
    clk           : IN  STD_LOGIC;
    -- ST sink: RL = 1
    snk_out_ready : OUT STD_LOGIC;
    snk_in_dat    : IN  STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    snk_in_val    : IN  STD_LOGIC := 'X';    
    -- ST source: RL = 1
    src_in_ready  : IN  STD_LOGIC;
    src_out_dat   : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    src_out_val   : OUT STD_LOGIC
  );
END common_rl_register;


ARCHITECTURE str OF common_rl_register IS

  SIGNAL reg_ready  : STD_LOGIC;
  SIGNAL reg_dat    : STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
  SIGNAL reg_val    : STD_LOGIC;    
  
BEGIN

  u_rl0 : ENTITY common_lib.common_rl_decrease
  GENERIC MAP (
    g_adapt       => g_adapt,
    g_dat_w       => g_dat_w
  )
  PORT MAP (
    rst           => rst,
    clk           => clk,
    -- ST sink: RL = 1
    snk_out_ready => snk_out_ready,
    snk_in_dat    => snk_in_dat,
    snk_in_val    => snk_in_val,  
    -- ST source: RL = 0
    src_in_ready  => reg_ready,
    src_out_dat   => reg_dat,
    src_out_val   => reg_val
  );
  
  u_rl1 : ENTITY common_lib.common_rl_increase
  GENERIC MAP (
    g_adapt       => g_adapt,
    g_hold_dat_en => g_hold_dat_en,
    g_dat_w       => g_dat_w
  )
  PORT MAP (
    rst           => rst,
    clk           => clk,
    -- Sink
    snk_out_ready => reg_ready,     -- sink RL = 0
    snk_in_dat    => reg_dat,
    snk_in_val    => reg_val,
    -- Source
    src_in_ready  => src_in_ready,  -- source RL = 1
    src_out_dat   => src_out_dat,
    src_out_val   => src_out_val
  );
  
END str;
