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

--            :<-----------period----------->:
--            :__________                    :_________ .............g_act_lvl
-- dc_out ____|          |___________________|         |________ ...!g_act_lvl
--            :          :
--            :<-active->:



--            :<-s_idle->:<-----s_idle------>:
--            :__________:                   :_________
-- dc_out ____|          |___________________|         |________
--            ^          ^
--            |          |
--            |          s_deassert
--            s_assert 

LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.common_pkg.ALL;

ENTITY common_duty_cycle IS
  GENERIC (
    g_rst_lvl : STD_LOGIC := '0'; -- dc_out level on reset
    g_dis_lvl : STD_LOGIC := '0'; -- dc_out level when disabled
    g_act_lvl : STD_LOGIC := '1'; -- Level that's DC controlled
    g_per_cnt : POSITIVE; -- Nof clk cycles per period. Note: if the dc_per_cnt input is used, this generic sets the maximum period.
    g_act_cnt : NATURAL   -- Nof clk cycles/period active level
  );
  PORT (
    rst         : IN  STD_LOGIC;
    clk         : IN  STD_LOGIC;

    dc_per_cnt  : IN  STD_LOGIC_VECTOR(ceil_log2(g_per_cnt+1)-1 DOWNTO 0) := TO_UVEC(g_per_cnt, ceil_log2(g_per_cnt+1));
    dc_act_cnt  : IN  STD_LOGIC_VECTOR(ceil_log2(g_per_cnt+1)-1 DOWNTO 0) := TO_UVEC(g_act_cnt, ceil_log2(g_per_cnt+1));

    dc_out_en   : IN  STD_LOGIC := '1';
    dc_out      : OUT STD_LOGIC
  );
END;

ARCHITECTURE rtl OF common_duty_cycle IS

  CONSTANT c_cycle_cnt_w : NATURAL := ceil_log2(g_per_cnt+1);

  TYPE t_state_enum IS (s_idle, s_assert, s_deassert); 

  TYPE t_reg IS RECORD
    state     : t_state_enum;
    cycle_cnt : NATURAL RANGE 0 TO g_per_cnt;
    dc_pulse  : STD_LOGIC;    
  END RECORD;

  SIGNAL r, nxt_r : t_reg;

BEGIN

  p_comb : PROCESS(rst, dc_out_en, dc_per_cnt, dc_act_cnt, r)
    VARIABLE v : t_reg;
  BEGIN
    v := r;    
 
    IF TO_UVEC(r.cycle_cnt, c_cycle_cnt_w) = dc_per_cnt THEN 
      v.cycle_cnt := 1;
    ELSE
      v.cycle_cnt := r.cycle_cnt + 1; 
    END IF;

    CASE r.state IS

      WHEN s_idle     => v.state := s_idle;
                         IF TO_UVEC(r.cycle_cnt, c_cycle_cnt_w)=dc_act_cnt OR dc_act_cnt=TO_UVEC(0, c_cycle_cnt_w) THEN 
                           v.state := s_deassert;                          
                         ELSIF TO_UVEC(r.cycle_cnt, c_cycle_cnt_w)=dc_per_cnt OR dc_act_cnt=dc_per_cnt THEN
                           v.state := s_assert;
                         END IF;

      WHEN s_assert   => v.dc_pulse := g_act_lvl;
                         IF TO_UVEC(r.cycle_cnt, c_cycle_cnt_w)=dc_act_cnt AND dc_act_cnt<dc_per_cnt THEN 
                           v.state := s_deassert;
                         END IF;

      WHEN s_deassert => v.dc_pulse := NOT(g_act_lvl);
                         IF TO_UVEC(r.cycle_cnt, c_cycle_cnt_w)=dc_per_cnt AND dc_act_cnt/=TO_UVEC(0, c_cycle_cnt_w) THEN 
                           v.state := s_assert; 
                         END IF;      
    END CASE;

    IF rst = '1' THEN 
      v.state     := s_idle; 
      v.cycle_cnt := 0;
      v.dc_pulse  := g_rst_lvl;
    END IF;

    nxt_r <= v;
  END PROCESS;

  p_seq : PROCESS(clk)
  BEGIN
    IF rising_edge(clk) THEN r <= nxt_r; END IF;
  END PROCESS;

  dc_out <= r.dc_pulse WHEN dc_out_en = '1' ELSE g_dis_lvl WHEN rst='0' ELSE g_rst_lvl;

END rtl;

