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

-- Purpose: Clock an input slv from the in_clk domain into out_clk domain
-- Description:
--   See common_acapture and common_top.
-- Remark:
-- . A Stratix IV LAB contains 10 ALM so 20 FF. Hence common_acapture_slv can
--   fit in 1 LAB if in_dat'LENGTH <= 10.

LIBRARY IEEE, common_lib;
USE IEEE.std_logic_1164.ALL;
USE common_lib.common_pkg.ALL;

ENTITY common_acapture_slv IS
  GENERIC (
    g_rst_level     : STD_LOGIC := '0';
    g_in_delay_len  : POSITIVE := 1;  -- = 1, typically fixed
    g_out_delay_len : POSITIVE := 1   -- >= 1, e.g. use c_meta_delay_len
  );
  PORT (
    in_rst  : IN  STD_LOGIC := '0';
    in_clk  : IN  STD_LOGIC;
    in_dat  : IN  STD_LOGIC_VECTOR;
    out_clk : IN  STD_LOGIC;
    out_cap : OUT STD_LOGIC_VECTOR
  );
END;


ARCHITECTURE str OF common_acapture_slv IS
  
  -- Provide in_cap to be able to view timing between out_clk and in_cap in Wave window
  SIGNAL in_cap : STD_LOGIC_VECTOR(in_dat'RANGE);
  
BEGIN

  gen_slv: FOR I IN in_dat'RANGE GENERATE
    u_acap : ENTITY work.common_acapture
    GENERIC MAP (
      g_rst_level     => g_rst_level,
      g_in_delay_len  => g_in_delay_len,
      g_out_delay_len => g_out_delay_len
    )
    PORT MAP (
      in_rst  => in_rst,
      in_clk  => in_clk,
      in_dat  => in_dat(I),
      in_cap  => in_cap(I),
      out_clk => out_clk,
      out_cap => out_cap(I)
    );
  END GENERATE;
    
END str;
