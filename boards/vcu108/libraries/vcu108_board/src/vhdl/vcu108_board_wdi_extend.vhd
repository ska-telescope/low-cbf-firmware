-------------------------------------------------------------------------------
--
-- Copyright (C) 2010-2016
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
USE IEEE.STD_LOGIC_1164.ALL;
USE common_lib.common_pkg.ALL;

-- Purpose:
--   Extend the input WDI that is controlled in SW (as it should be) to avoid
--   that the watchdog reset will occur when new SW is loaded, while keeping
--   the HDL image. This component extends the last input WDI by toggling the
--   output WDI for about 2**(g_extend_w-1) ms more.

ENTITY vcu108_board_wdi_extend IS
  GENERIC (
    g_extend_w : NATURAL := 14
  );
  PORT (
    rst              : IN  STD_LOGIC;
    clk              : IN  STD_LOGIC;
    pulse_ms         : IN  STD_LOGIC;  -- pulses every 1 ms
    wdi_in           : IN  STD_LOGIC;
    wdi_out          : OUT STD_LOGIC
  );
END vcu108_board_wdi_extend;


ARCHITECTURE str OF vcu108_board_wdi_extend IS

  SIGNAL wdi_evt     : STD_LOGIC;
  
  SIGNAL wdi_cnt     : STD_LOGIC_VECTOR(g_extend_w-1 DOWNTO 0);
  SIGNAL wdi_cnt_en  : STD_LOGIC;
  
  SIGNAL i_wdi_out   : STD_LOGIC;
  SIGNAL nxt_wdi_out : STD_LOGIC;
  
BEGIN

  wdi_out <= i_wdi_out;
  
  p_clk : PROCESS(rst, clk)
  BEGIN
    IF rst='1' THEN
      i_wdi_out <= '0';
    ELSIF rising_edge(clk) THEN
      i_wdi_out <= nxt_wdi_out;
    END IF;
  END PROCESS;
  
  wdi_cnt_en <= '1' WHEN pulse_ms='1' AND wdi_cnt(wdi_cnt'HIGH)='0' ELSE '0';

  nxt_wdi_out <= NOT i_wdi_out WHEN wdi_cnt_en='1' ELSE i_wdi_out;
  
  u_common_evt : ENTITY common_lib.common_evt
  GENERIC MAP (
    g_evt_type => "BOTH",
    g_out_reg  => TRUE
  )
  PORT MAP (
    rst      => rst,
    clk      => clk,
    in_sig   => wdi_in,
    out_evt  => wdi_evt
  );
  
  u_common_counter : ENTITY common_lib.common_counter
  GENERIC MAP (
    g_width   => g_extend_w
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    cnt_clr => wdi_evt,
    cnt_en  => wdi_cnt_en,
    count   => wdi_cnt
  );
  
END str;
