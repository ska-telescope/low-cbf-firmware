-------------------------------------------------------------------------------
--
-- Copyright (C) 2011
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

-- Purpose: Same function as avs_common_mm.vhd, but with the read latency set
--          to 2 instead of 1 in the hardware description TCL file.
-- Description:
--   The avs_common_mm_readlatency2_hw.tcl determines the read latency. This
--   component wraps the default avs_common_mm which has readlatency 1 in its
--   avs_common_mm_hw.tcl.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY avs_common_mm_readlatency2 IS
  GENERIC (
    g_adr_w     : NATURAL := 5;
    g_dat_w     : NATURAL := 32
  );
  PORT (
    -- MM side
    csi_system_reset       : IN  STD_LOGIC;
    csi_system_clk         : IN  STD_LOGIC;
    
    avs_mem_address        : IN  STD_LOGIC_VECTOR(g_adr_w-1 DOWNTO 0);
    avs_mem_write          : IN  STD_LOGIC;     
    avs_mem_writedata      : IN  STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);    
    avs_mem_read           : IN  STD_LOGIC;    
    avs_mem_readdata       : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
   
    -- User side
    coe_reset_export       : OUT STD_LOGIC;
    coe_clk_export         : OUT STD_LOGIC;
    
    coe_address_export     : OUT STD_LOGIC_VECTOR(g_adr_w-1 DOWNTO 0);
    coe_write_export       : OUT STD_LOGIC;     
    coe_writedata_export   : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);    
    coe_read_export        : OUT STD_LOGIC;    
    coe_readdata_export    : IN  STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0)
  );
END avs_common_mm_readlatency2;


ARCHITECTURE wrap OF avs_common_mm_readlatency2 IS
BEGIN

  -- wires
  coe_reset_export     <= csi_system_reset;
  coe_clk_export       <= csi_system_clk;
  
  coe_address_export   <= avs_mem_address;
  coe_write_export     <= avs_mem_write;
  coe_writedata_export <= avs_mem_writedata;
  coe_read_export      <= avs_mem_read;
  avs_mem_readdata     <= coe_readdata_export;
    
END wrap;