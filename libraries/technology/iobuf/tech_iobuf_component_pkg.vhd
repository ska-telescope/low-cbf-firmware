-------------------------------------------------------------------------------
--
-- Copyright (C) 2014
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

-- Purpose: IP components declarations for various devices that get wrapped by the tech components

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

PACKAGE tech_iobuf_component_pkg IS

  -----------------------------------------------------------------------------
  -- ip_stratixiv
  -----------------------------------------------------------------------------
  
  COMPONENT ip_stratixiv_ddio_in IS
  GENERIC(
    g_device_family : STRING := "Stratix IV";
    g_width         : NATURAL := 1
  );
  PORT (
    in_dat      : IN  STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);
    in_clk      : IN  STD_LOGIC;
    in_clk_en   : IN  STD_LOGIC := '1';
    rst         : IN  STD_LOGIC := '0';
    out_dat_hi  : OUT STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);
    out_dat_lo  : OUT STD_LOGIC_VECTOR(g_width-1 DOWNTO 0)
  );
  END COMPONENT;
  
  COMPONENT ip_stratixiv_ddio_out IS
  GENERIC(
    g_device_family : STRING  := "Stratix IV";
    g_width         : NATURAL := 1
  );
  PORT (
    rst        : IN   STD_LOGIC := '0';
    in_clk     : IN   STD_LOGIC;
    in_clk_en  : IN   STD_LOGIC := '1';
    in_dat_hi  : IN   STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);
    in_dat_lo  : IN   STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);
    out_dat    : OUT  STD_LOGIC_VECTOR(g_width-1 DOWNTO 0)
  );
  END COMPONENT;
  
  
  -----------------------------------------------------------------------------
  -- ip_arria10
  -----------------------------------------------------------------------------
  
  COMPONENT ip_arria10_ddio_in IS
  GENERIC (
    g_width : NATURAL := 1
  );
  PORT (
    in_dat      : IN  STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);
    in_clk      : IN  STD_LOGIC;
    in_clk_en   : IN  STD_LOGIC := '1';   -- Not Connected
    rst         : IN  STD_LOGIC := '0';
    out_dat_hi  : OUT STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);
    out_dat_lo  : OUT STD_LOGIC_VECTOR(g_width-1 DOWNTO 0)
  );
  END COMPONENT;
  
  COMPONENT ip_arria10_ddio_out IS
  GENERIC(
    g_width : NATURAL := 1
  );
  PORT (
    rst        : IN   STD_LOGIC := '0';
    in_clk     : IN   STD_LOGIC;
    in_clk_en  : IN   STD_LOGIC := '1';   -- Not Connected
    in_dat_hi  : IN   STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);
    in_dat_lo  : IN   STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);
    out_dat    : OUT  STD_LOGIC_VECTOR(g_width-1 DOWNTO 0)
  );
  END COMPONENT;
  
  -----------------------------------------------------------------------------
  -- ip_arria10_e3sge3
  -----------------------------------------------------------------------------
  
  COMPONENT ip_arria10_e3sge3_ddio_in IS
  GENERIC (
    g_width : NATURAL := 1
  );
  PORT (
    in_dat      : IN  STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);
    in_clk      : IN  STD_LOGIC;
    in_clk_en   : IN  STD_LOGIC := '1';   -- Not Connected
    rst         : IN  STD_LOGIC := '0';
    out_dat_hi  : OUT STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);
    out_dat_lo  : OUT STD_LOGIC_VECTOR(g_width-1 DOWNTO 0)
  );
  END COMPONENT;
  
  COMPONENT ip_arria10_e3sge3_ddio_out IS
  GENERIC(
    g_width : NATURAL := 1
  );
  PORT (
    rst        : IN   STD_LOGIC := '0';
    in_clk     : IN   STD_LOGIC;
    in_clk_en  : IN   STD_LOGIC := '1';   -- Not Connected
    in_dat_hi  : IN   STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);
    in_dat_lo  : IN   STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);
    out_dat    : OUT  STD_LOGIC_VECTOR(g_width-1 DOWNTO 0)
  );
  END COMPONENT;
  
END tech_iobuf_component_pkg;
