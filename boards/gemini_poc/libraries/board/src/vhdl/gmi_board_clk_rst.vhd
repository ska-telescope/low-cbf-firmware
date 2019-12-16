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
--   1) initial power up xo_rst_n that can be used to reset a SOPC system (via
--      reset_n).
--   2) sys_rst released when the sys_clk PLL from the SOPC system has locked,
--      can be used as a system reset for the sys_clk domain.

ENTITY gmi_board_clk_rst IS
  PORT (
    -- Reference clock and reset to SOPC system PLL
    xo_clk                 : IN  STD_LOGIC;  -- reference XO clock (e.g. 25 MHz also use by PLL in SOPC)
    xo_rst_n               : OUT STD_LOGIC;  -- NOT xo_rst (e.g. to reset the SOPC with NIOS2 uP)
    -- System clock and locked from SOPC system PLL
    sys_clk                : IN  STD_LOGIC;  -- system clock derived from the reference XO clock (e.g. 125 MHz by a PLL from SOPC with NIOS2 uP)
    sys_locked             : IN  STD_LOGIC;  -- system clock PLL locked
    sys_rst                : OUT STD_LOGIC   -- system reset released some cycles after the system clock PLL has in locked
  );
END gmi_board_clk_rst;


ARCHITECTURE str OF gmi_board_clk_rst IS

  CONSTANT c_reset_len   : NATURAL := 4;  -- >= c_meta_delay_len from common_pkg
  
  -- XO clock domain
  SIGNAL xo_rst          : STD_LOGIC;  -- initial reset released after some XO clock cycles
  
  -- SYS clock domain
  SIGNAL sys_locked_n    : STD_LOGIC;
  
BEGIN

  -- Reference clock and reset to SOPC system PLL
  xo_rst_n <= NOT xo_rst;

  u_common_areset_xo : ENTITY common_lib.common_areset
  GENERIC MAP (
    g_rst_level => '1',       -- power up default will be inferred in FPGA
    g_delay_len => c_reset_len
  )
  PORT MAP (
    in_rst    => '0',         -- release reset after some clock cycles
    clk       => xo_clk,
    out_rst   => xo_rst
  );

  -- System clock from SOPC system PLL and system reset
  sys_locked_n <= NOT sys_locked;
  
  u_common_areset_sys : ENTITY common_lib.common_areset
  GENERIC MAP (
    g_rst_level => '1',       -- power up default will be inferred in FPGA
    g_delay_len => c_reset_len
  )
  PORT MAP (
    in_rst    => sys_locked_n,  -- release reset after some clock cycles when the PLL has locked
    clk       => sys_clk,
    out_rst   => sys_rst
  );
  
END str;
