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

-- Purpose: Capture internal STD_LOGIC signal at double data rate
-- Description: See common_ddreg.vhd
-- Remark:

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.common_pkg.ALL;

ENTITY common_ddreg_slv IS
  GENERIC (
    g_in_delay_len  : POSITIVE := c_meta_delay_len;
    g_out_delay_len : POSITIVE := c_meta_delay_len
  );
  PORT (
    in_clk      : IN  STD_LOGIC;
    in_dat      : IN  STD_LOGIC_VECTOR;
    rst         : IN  STD_LOGIC := '0';
    out_clk     : IN  STD_LOGIC;
    out_dat_hi  : OUT STD_LOGIC_VECTOR;
    out_dat_lo  : OUT STD_LOGIC_VECTOR
  );
END common_ddreg_slv;


ARCHITECTURE str OF common_ddreg_slv IS  
BEGIN

  gen_slv: FOR I IN in_dat'RANGE GENERATE
    u_ddreg : ENTITY work.common_ddreg
    GENERIC MAP (
      g_in_delay_len  => g_in_delay_len,
      g_out_delay_len => g_out_delay_len
    )
    PORT MAP (
      in_clk      => in_clk,
      in_dat      => in_dat(I),
      rst         => rst,
      out_clk     => out_clk,
      out_dat_hi  => out_dat_hi(I),
      out_dat_lo  => out_dat_lo(I)
    );
  END GENERATE;
  
END str;
