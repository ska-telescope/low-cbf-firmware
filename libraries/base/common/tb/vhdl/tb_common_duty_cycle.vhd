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

LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.tb_common_pkg.ALL;

ENTITY tb_common_duty_cycle IS
END tb_common_duty_cycle;

ARCHITECTURE tb OF tb_common_duty_cycle IS

  CONSTANT c_clk_period   : TIME    := 10 ns;

  CONSTANT c_dc_max_period_cnt : NATURAL := 30;
 
  SIGNAL tb_end       : STD_LOGIC := '0';
  SIGNAL rst          : STD_LOGIC := '1';
  SIGNAL clk          : STD_LOGIC := '1';

  SIGNAL dc_per_cnt   : STD_LOGIC_VECTOR(ceil_log2(c_dc_max_period_cnt+1)-1 DOWNTO 0);   
  SIGNAL dc_act_cnt   : STD_LOGIC_VECTOR(ceil_log2(c_dc_max_period_cnt+1)-1 DOWNTO 0);

  SIGNAL dc_out_en    : STD_LOGIC;
  SIGNAL dc_out       : STD_LOGIC;

BEGIN

  -----------------------------------------------------------------------------
  -- Stimuli
  -----------------------------------------------------------------------------
  rst <= '1', '0' AFTER c_clk_period*7;
  clk <= (NOT clk) OR tb_end AFTER c_clk_period/2;
  
  -- MM control
  p_mm : PROCESS
  BEGIN
    tb_end    <= '0';

    dc_per_cnt <= TO_UVEC(10, ceil_log2(c_dc_max_period_cnt+1));
    dc_act_cnt <= TO_UVEC(3,  ceil_log2(c_dc_max_period_cnt+1));

    -- Basic output enable control.
    dc_out_en <= '0';

    -- ** Disabled ** --

    WAIT FOR 400 ns;
    WAIT UNTIL clk='1';
    dc_out_en <= '1';
    WAIT FOR 1 us;
    WAIT UNTIL clk='1';
    dc_out_en <= '0';

    -- ** Disabled ** --

    WAIT FOR 1 us;

    -- Now actively control DC active level
    FOR i IN 0 TO 10 LOOP
      dc_act_cnt <= TO_UVEC(i, ceil_log2(c_dc_max_period_cnt+1));
      dc_out_en <= '1';
      WAIT FOR 100 ns;
      WAIT UNTIL clk='1';      
    END LOOP;
    
    WAIT FOR 80 ns;
    dc_out_en <= '0';

    -- ** Disabled ** --

    WAIT FOR 1 us;
    WAIT UNTIL clk='1';

    -- Now actively control DC active level for 2x the previous period count => twice the resolution.
    dc_per_cnt <= TO_UVEC(20, ceil_log2(c_dc_max_period_cnt+1));

    FOR i IN 0 TO 20 LOOP
      dc_act_cnt <= TO_UVEC(i, ceil_log2(c_dc_max_period_cnt+1));
      dc_out_en <= '1';
      WAIT FOR 100 ns;
      WAIT UNTIL clk='1';      
    END LOOP;

    WAIT FOR 1 us;

    tb_end   <= '1';
    WAIT;
  END PROCESS;  
  
  -----------------------------------------------------------------------------
  -- DUT: common_duty_cycle
  -----------------------------------------------------------------------------
  
  dut : ENTITY work.common_duty_cycle
  GENERIC MAP (
    g_rst_lvl => '0',
    g_dis_lvl => '0',
    g_act_lvl => '1',
    g_per_cnt => c_dc_max_period_cnt,
    g_act_cnt => 10
  )
  PORT MAP (
    rst         => rst,
    clk         => clk,

    dc_per_cnt  => dc_per_cnt,
    dc_act_cnt  => dc_act_cnt,
                 
    dc_out_en   => dc_out_en,
    dc_out      => dc_out
   );
    
END tb;
