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

--   Purpose: Shift register for control data bit
--   Description:
--     Delays input data by g_depth. The delay line shifts when in_val is
--     indicates an active clock cycle.
--   Remark:
--   . This common_bit_delay can not use common_delay.vhd because it needs a reset.
--   . Typically rst may be left not connected, because the internal power up
--     state of the shift_reg is 0.
--   . If dynamic restart control is needed then use in_clr for that. Otherwise
--     leave in_clr also not connected.
--   . For large g_depth Quartus infers a RAM block for this bitDelay even if
--     the same signal is applied to both in_bit and in_val. It does not help
--     to remove in_clr or to not use shift_reg(0) combinatorially.

library IEEE;
use IEEE.std_logic_1164.all;

entity common_bit_delay is
  generic (
    g_depth : NATURAL := 16 --Quartus infers fifo for 4 to 4096 g_depth, 8 Bits.
  );
  port (
    clk     : in  std_logic;
    rst     : in  std_logic := '0';   -- asynchronous reset for initial start
    in_clr  : in  std_logic := '0';   -- synchronous reset for control of dynamic restart(s)
    in_bit  : in  std_logic;
    in_val  : in  std_logic := '1';
    out_bit : out std_logic
  );
end entity common_bit_delay;

architecture rtl of common_bit_delay is

  -- Use index (0) as combinatorial input and index(1:g_depth) for the shift
  -- delay, in this way the shift_reg type can support all g_depth >= 0
  signal shift_reg : std_logic_vector(0 to g_depth) := (others=>'0');

begin

  shift_reg(0) <= in_bit;
  
  out_bit <= shift_reg(g_depth);

  gen_reg : if g_depth>0 generate
    p_clk : process(clk, rst)
    begin
      if rst='1' then
        shift_reg(1 to g_depth) <= (others=>'0');
      elsif rising_edge(clk) then
        if in_clr='1' then
          shift_reg(1 to g_depth) <= (others=>'0');
        elsif in_val='1' then
          shift_reg(1 to g_depth) <= shift_reg(0 to g_depth-1);
        end if;
      end if;
    end process;
  end generate;

end rtl;
