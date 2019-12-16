--------------------------------------------------------------------------------
--   Author: Raj Thilak Rajan : rajan at astron.nl: Nov 2009
--   Copyright (C) 2009-2010
--   ASTRON (Netherlands Institute for Radio Astronomy)
--   P.O.Box 2, 7990 AA Dwingeloo, The Netherlands
--
--   This file is part of the UniBoard software suite.
--   The file is free software: you can redistribute it and/or modify
--   it under the terms of the GNU General Public License as published by
--   the Free Software Foundation, either version 3 of the License, or
--   (at your option) any later version.
--
--   This program is distributed in the hope that it will be useful,
--   but WITHOUT ANY WARRANTY; without even the implied warranty of
--   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--   GNU General Public License for more details.
--
--   You should have received a copy of the GNU General Public License
--   along with this program.  If not, see <http://www.gnu.org/licenses/>.
--------------------------------------------------------------------------------

--   Purpose: Shift register for data
--   Description:
--     Delays input data by g_depth. The delay line shifts when in_val is
--     indicates an active clock cycle.

library ieee;
use IEEE.STD_LOGIC_1164.all;

entity common_delay is
  generic (
    g_dat_w    : NATURAL := 8;   -- need g_dat_w to be able to use (others=>'') assignments for two dimensional unconstraint vector arrays
    g_depth    : NATURAL := 16
  );
  port (
    clk      : in  STD_LOGIC;
    in_val   : in  STD_LOGIC := '1';
    in_dat   : in  STD_LOGIC_VECTOR(g_dat_w-1 downto 0);
    out_dat  : out STD_LOGIC_VECTOR(g_dat_w-1 downto 0)
  );
end entity common_delay;

architecture rtl of common_delay is

  -- Use index (0) as combinatorial input and index(1:g_depth) for the shift
  -- delay, in this way the t_dly_arr type can support all g_depth >= 0
  type t_dly_arr is array (0 to g_depth) of STD_LOGIC_VECTOR(g_dat_w-1 downto 0);

  signal shift_reg : t_dly_arr := (others=>(others=>'0'));

begin

  shift_reg(0) <= in_dat;
  
  out_dat <= shift_reg(g_depth);

  gen_reg : if g_depth>0 generate
    p_clk : process(clk)
    begin
      if rising_edge(clk) then
        if in_val='1' then
          shift_reg(1 to g_depth) <= shift_reg(0 to g_depth-1);
        end if;
      end if;
    end process;
  end generate;

end rtl;
