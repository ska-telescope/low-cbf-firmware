-------------------------------------------------------------------------------
--
-- Copyright (C) 2015
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

PACKAGE tech_clkbuf_component_pkg IS

  -----------------------------------------------------------------------------
  -- ip_arria10
  -----------------------------------------------------------------------------
  
  COMPONENT ip_arria10_clkbuf_global IS
  PORT (
    inclk  : in  std_logic := '0'; --  altclkctrl_input.inclk
    outclk : out std_logic         -- altclkctrl_output.outclk
  );
  END COMPONENT;


  -----------------------------------------------------------------------------
  -- ip_arria10_e3sge3
  -----------------------------------------------------------------------------
  
  COMPONENT ip_arria10_e3sge3_clkbuf_global IS
  PORT (
    inclk  : in  std_logic := '0'; --  altclkctrl_input.inclk
    outclk : out std_logic         -- altclkctrl_output.outclk
  );
  END COMPONENT;
    
END tech_clkbuf_component_pkg;

