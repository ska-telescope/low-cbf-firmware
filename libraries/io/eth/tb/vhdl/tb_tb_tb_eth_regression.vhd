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

-- Purpose: Multi-testbench for regression test of all tb in eth library
-- Description:
-- Usage:
--   > as 4
--   > run -all

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY tb_tb_tb_eth_regression IS
END tb_tb_tb_eth_regression;

ARCHITECTURE tb OF tb_tb_tb_eth_regression IS
BEGIN

  u_tb_tb_eth          : ENTITY work.tb_tb_eth;
  u_tb_eth_hdr         : ENTITY work.tb_eth_hdr;
  u_tb_eth_checksum    : ENTITY work.tb_eth_checksum;
  u_tb_eth_crc_ctrl    : ENTITY work.tb_eth_crc_ctrl;
  u_tb_eth_udp_offload : ENTITY work.tb_eth_udp_offload;
  u_tb_eth_IHL_to_20   : ENTITY work.tb_eth_IHL_to_20;
  
END tb;
