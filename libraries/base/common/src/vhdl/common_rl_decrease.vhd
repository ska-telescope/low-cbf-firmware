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

-- >>> Ported from UniBoard dp_latency_adapter for fixed RL 0 --> 1

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

-- Purpose: Adapt from ready latency 1 to 0 to make a look ahead FIFO
-- Description: -
-- Remark:
-- . A show ahead FIFO with RL=0 does not need a rd_emp output signal, because
--   with RL=0 the rd_val='0' when it is empty (so emp <= NOT rd_val).


ENTITY common_rl_decrease IS
  GENERIC (
    g_adapt       : BOOLEAN := TRUE;    -- default when TRUE then decrease sink RL 1 to source RL 0, else then implement wires
    g_dat_w       : NATURAL := 18
  );
  PORT (
    rst           : IN  STD_LOGIC;
    clk           : IN  STD_LOGIC;
    -- ST sink: RL = 1
    snk_out_ready : OUT STD_LOGIC;
    snk_in_dat    : IN  STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    snk_in_val    : IN  STD_LOGIC := 'X';    
    -- ST source: RL = 0
    src_in_ready  : IN  STD_LOGIC;
    src_out_dat   : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    src_out_val   : OUT STD_LOGIC
  );
END common_rl_decrease;


ARCHITECTURE rtl OF common_rl_decrease IS

  -- Internally use streaming record for the SOSI, for the SISO.ready directly use src_in_ready
  TYPE t_sosi IS RECORD  -- Source Out or Sink In
    data     : STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    valid    : STD_LOGIC;
  END RECORD;

  TYPE t_sosi_arr IS ARRAY (INTEGER RANGE <>) OF t_sosi;
  
  CONSTANT c_sosi_rst : t_sosi := ((OTHERS=>'0'), '0');

  -- SOSI IO  
  SIGNAL snk_in       : t_sosi;
  SIGNAL src_out      : t_sosi;
  
  -- The default FIFO has ready latency RL = 1, need to use input RL + 1 words for the buf array, to go to output RL = 0 for show ahead FIFO
  SIGNAL buf          : t_sosi_arr(1 DOWNTO 0);
  SIGNAL nxt_buf      : t_sosi_arr(1 DOWNTO 0);
  
BEGIN

  gen_wires : IF g_adapt=FALSE GENERATE
    snk_out_ready <= src_in_ready;
    
    src_out_dat   <= snk_in_dat;
    src_out_val   <= snk_in_val;
  END GENERATE;
  
  gen_adapt : IF g_adapt=TRUE GENERATE
    snk_in.data  <= snk_in_dat;
    snk_in.valid <= snk_in_val;
    
    src_out_dat <= src_out.data;
    src_out_val <= src_out.valid;
  
    -- Buf[0] contains the FIFO output with zero ready latency
    src_out <= buf(0);
  
    p_clk : PROCESS(rst, clk)
    BEGIN
      IF rst='1' THEN
        buf <= (OTHERS=>c_sosi_rst);
      ELSIF rising_edge(clk) THEN
        buf <= nxt_buf;
      END IF;
    END PROCESS;
  
    p_snk_out_ready : PROCESS(buf, src_in_ready, snk_in)
    BEGIN
      snk_out_ready <= '0';
      IF src_in_ready='1' THEN
        -- Default snk_out_ready when src_in_ready.
        snk_out_ready <= '1';
      ELSE
        -- Extra snk_out_ready to look ahead for RL = 0.
        IF buf(0).valid='0' THEN
          snk_out_ready <= '1';
        ELSIF buf(1).valid='0' THEN
          snk_out_ready <= NOT(snk_in.valid);
        END IF;
      END IF;
    END PROCESS;
    
    p_buf : PROCESS(buf, src_in_ready, snk_in)
    BEGIN
      -- Keep or shift the buf dependent on src_in_ready, no need to explicitly check buf().valid
      nxt_buf <= buf;
      IF src_in_ready='1' THEN
        nxt_buf(0) <= buf(1);
        nxt_buf(1).valid <= '0';  -- not strictly necessary, but robust
      END IF;
  
      -- Put input data at the first available location dependent on src_in_ready, no need to explicitly check snk_in_val
      IF buf(0).valid='0' THEN
        nxt_buf(0) <= snk_in;
      ELSE
        IF buf(1).valid='0' THEN
          IF src_in_ready='0' THEN
            nxt_buf(1) <= snk_in;
          ELSE
            nxt_buf(0) <= snk_in;
          END IF;
        END IF;
      END IF;
    END PROCESS;
  END GENERATE;
  
END rtl;
