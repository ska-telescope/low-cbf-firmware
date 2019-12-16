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

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

-- Purpose: Determine when there is an active frame
-- Description:
-- . The frame_busy goes high combinatorially with the in_sop and low after the
--   in_eop.
-- . The frame_idle = NOT frame_busy.
-- Remark:

ENTITY common_frame_busy IS
  PORT (
    rst        : IN  STD_LOGIC;
    clk        : IN  STD_LOGIC;
    in_sop     : IN  STD_LOGIC;
    in_eop     : IN  STD_LOGIC;
    frame_idle : OUT STD_LOGIC;
    frame_busy : OUT STD_LOGIC
  );
END common_frame_busy;


ARCHITECTURE str OF common_frame_busy IS

  SIGNAL in_frm            : STD_LOGIC;
  SIGNAL nxt_in_frm        : STD_LOGIC;
  
  SIGNAL i_frame_busy      : STD_LOGIC;
BEGIN

  p_clk : PROCESS(rst, clk)
  BEGIN
    IF rst='1' THEN
      in_frm <= '0';
    ELSIF rising_edge(clk) THEN
      in_frm <= nxt_in_frm;
    END IF;
  END PROCESS;
  
  nxt_in_frm <= '1' WHEN in_sop='1' ELSE '0' WHEN in_eop='1' ELSE in_frm;
  
  -- Due to one clk cycle latency in_frm active does not cover the in_sop, so therefor also require NOT in_sop for frame_busy
  i_frame_busy <= in_sop OR in_frm;
  
  frame_busy <=     i_frame_busy;
  frame_idle <= NOT i_frame_busy;
  
END str;
