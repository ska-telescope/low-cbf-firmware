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
USE work.common_pkg.ALL;

ENTITY common_request IS
  PORT (
    rst         : IN  STD_LOGIC;
    clk         : IN  STD_LOGIC;
    clken       : IN  STD_LOGIC := '1';
    sync        : IN  STD_LOGIC := '1';
    in_req      : IN  STD_LOGIC;
    out_req_evt : OUT STD_LOGIC
  );
END common_request;


-- Request control:
-- . All inputs and outputs are registered
-- . A new request is indicated by in_req going from 0 to 1
-- . The pending request gets issued immediately or when the optional sync
--   pulse occurs
-- . The output request is a pulse as indicated by the postfix '_evt'

ARCHITECTURE rtl OF common_request IS

  SIGNAL sync_reg        : STD_LOGIC;
  SIGNAL in_req_reg      : STD_LOGIC;
  SIGNAL in_req_prev     : STD_LOGIC;
  SIGNAL in_req_evt      : STD_LOGIC;
  SIGNAL req_pending     : STD_LOGIC;
  SIGNAL out_req         : STD_LOGIC;
  SIGNAL out_req_prev    : STD_LOGIC;
  SIGNAL nxt_out_req_evt : STD_LOGIC;

BEGIN

  p_clk : PROCESS(rst, clk)
  BEGIN
    IF rst='1' THEN
      -- input
      sync_reg <= '0';
      in_req_reg <= '0';
      -- internal
      in_req_prev <= '0';
      out_req_prev <= '0';
      -- output
      out_req_evt <= '0';
    ELSIF rising_edge(clk) THEN
      IF clken='1' THEN
        -- input
        sync_reg <= sync;
        in_req_reg <= in_req;
        -- internal
        in_req_prev <= in_req_reg;
        out_req_prev <= out_req;
        -- output
        out_req_evt <= nxt_out_req_evt;
      END IF;
    END IF;
  END PROCESS;

  in_req_evt <= in_req_reg AND NOT in_req_prev;

  u_protocol_act : ENTITY work.common_switch
  PORT MAP (
    rst         => rst,
    clk         => clk,
    clken       => clken,
    switch_high => in_req_evt,
    switch_low  => out_req,
    out_level   => req_pending
  );

  out_req <= req_pending AND sync_reg;
  nxt_out_req_evt <= out_req AND NOT out_req_prev;

END rtl;