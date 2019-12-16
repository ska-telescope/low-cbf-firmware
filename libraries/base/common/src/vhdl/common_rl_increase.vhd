-------------------------------------------------------------------------------
--
-- Copyright (C) 2013
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

-- >>> Ported from UniBoard dp_latency_increase for fixed RL 0 --> 1
--
-- Purpose:
--   Increase the ready latency from RL=0 to RL=1.
-- Description:
--   Increasing the RL makes a look ahead FIFO appear as a normal FIFO.
-- Remark:
-- . The data are passed on as wires when g_hold_dat_en=FALSE. When TRUE then
--   the data is held until the next active src_out_val to ease applications 
--   that still depend on the src_out_dat value after src_out_val has gone low.
--   With RL=0 at the snk_in a new valid snk_in_dat can arrive before it is 
--   acknowledged by the registered src_in_ready.
-- . The src_out_val control is internally AND with the snk_out_ready.

ENTITY common_rl_increase IS
  GENERIC (
    g_adapt       : BOOLEAN := TRUE;   -- default when TRUE then increase sink RL 0 to source RL 1, else then implement wires
    g_hold_dat_en : BOOLEAN := TRUE;   -- default when TRUE hold the src_out_dat until the next active src_out_val, else just pass on snk_in_dat as wires
    g_dat_w       : NATURAL := 18
  );
  PORT (
    rst           : IN  STD_LOGIC;
    clk           : IN  STD_LOGIC;
    -- Sink
    snk_out_ready : OUT STD_LOGIC;  -- sink RL = 0
    snk_in_dat    : IN  STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0) := (OTHERS=>'X');
    snk_in_val    : IN  STD_LOGIC := 'X';
    -- Source
    src_in_ready  : IN  STD_LOGIC;  -- source RL = 1
    src_out_dat   : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    src_out_val   : OUT STD_LOGIC
  );
END common_rl_increase;


ARCHITECTURE rtl OF common_rl_increase IS

  SIGNAL ready_reg    : STD_LOGIC;
  
  SIGNAL hold_dat     : STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL nxt_hold_dat : STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
  SIGNAL hold_val     : STD_LOGIC;
  
BEGIN

  gen_wires : IF g_adapt=FALSE GENERATE
    snk_out_ready <= src_in_ready;
    
    src_out_dat   <= snk_in_dat;
    src_out_val   <= snk_in_val;
  END GENERATE;
  
  gen_adapt : IF g_adapt=TRUE GENERATE
    p_clk : PROCESS(rst, clk)
    BEGIN
      IF rst='1' THEN
        ready_reg <= '0';
      ELSIF rising_edge(clk) THEN
        ready_reg <= src_in_ready;
        hold_dat  <= nxt_hold_dat;
      END IF;
    END PROCESS;
    
    -- SISO
    snk_out_ready <= ready_reg;  -- Adjust ready latency
    
    -- SOSI
    hold_val     <= snk_in_val AND ready_reg;
    src_out_val  <= hold_val;
    
    nxt_hold_dat <= snk_in_dat WHEN hold_val='1' ELSE hold_dat;
    src_out_dat  <= snk_in_dat WHEN g_hold_dat_en=FALSE ELSE nxt_hold_dat;
  END GENERATE;
  
END rtl;
