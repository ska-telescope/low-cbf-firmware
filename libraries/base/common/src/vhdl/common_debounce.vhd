-------------------------------------------------------------------------------
--
-- Copyright (C) 2009
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

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;

-- Purpose:
--
-- The output follows the input, but only if the input is stable for at least
-- g_latency clock cycles.

ENTITY common_debounce IS
  GENERIC (
    g_type       : STRING := "BOTH";  -- "BOTH" = debounce g_latency clk cycles for both bgoing high when d_in='1' and for going low when d_in='0'
                                      -- "HIGH" = debounce g_latency clk cycles for going high when d_in='1', go low  immediately when d_in='0'
                                      -- "LOW"  = debounce g_latency clk cycles for going low  when d_in='0', go high immediately when d_in='1'
    g_delay_len  : NATURAL := c_meta_delay_len;  -- = 3,  combat meta stability
    g_latency    : NATURAL := 8;                 -- >= 1, combat debounces over nof clk cycles
    g_init_level : STD_LOGIC := '1'
  );
  PORT (
    rst   : IN  STD_LOGIC := '0';
    clk   : IN  STD_LOGIC;
    clken : IN  STD_LOGIC := '1';
    d_in  : IN  STD_LOGIC;
    q_out : OUT STD_LOGIC
  );
END common_debounce;


ARCHITECTURE rtl OF common_debounce IS
  
  CONSTANT c_latency_w  : NATURAL := ceil_log2(g_latency+1);
  
  SIGNAL cnt         : STD_LOGIC_VECTOR(c_latency_w-1 DOWNTO 0);   -- use cnt = g_latency to stop the counter
  SIGNAL cnt_clr     : STD_LOGIC;
  SIGNAL cnt_en      : STD_LOGIC;
  SIGNAL stable_d    : STD_LOGIC;
  
  SIGNAL d_dly       : STD_LOGIC_VECTOR(0 TO g_delay_len-1) := (OTHERS=>g_init_level);
  SIGNAL d_reg       : STD_LOGIC := g_init_level;
  SIGNAL prev_d      : STD_LOGIC := g_init_level;
  SIGNAL i_q_out     : STD_LOGIC := g_init_level;
  SIGNAL nxt_q_out   : STD_LOGIC;
  
BEGIN

  q_out <= i_q_out;
  
  p_clk : PROCESS (rst, clk)
  BEGIN
    IF rst='1' THEN
      d_dly    <= (OTHERS=>g_init_level);
      d_reg    <= g_init_level;
      prev_d   <= g_init_level;
      i_q_out  <= g_init_level;
    ELSIF rising_edge(clk) THEN
      IF clken='1' THEN
        d_dly    <= d_in & d_dly(0 TO d_dly'HIGH-1);
        d_reg    <= d_dly(d_dly'HIGH);
        prev_d   <= d_reg;
        i_q_out  <= nxt_q_out;
      END IF;
    END IF;
  END PROCESS;
  
  stable_d <= '1' WHEN UNSIGNED(cnt)>=g_latency ELSE '0';
  cnt_en   <= NOT stable_d;
  
  gen_both : IF g_type="BOTH" GENERATE
    cnt_clr <= d_reg XOR prev_d;
    nxt_q_out <= prev_d WHEN stable_d='1' ELSE i_q_out;
  END GENERATE;
  
  gen_high : IF g_type="HIGH" GENERATE
    cnt_clr <= NOT d_reg;
    nxt_q_out <= prev_d WHEN stable_d='1' ELSE '0';
  END GENERATE;
  
  gen_low : IF g_type="LOW" GENERATE
    cnt_clr <= d_reg;
    nxt_q_out <= prev_d WHEN stable_d='1' ELSE '1';
  END GENERATE;
  
  u_counter : ENTITY work.common_counter
  GENERIC MAP (
    g_width     => c_latency_w
  )
  PORT MAP (
    rst     => '0',
    clk     => clk,
    clken   => clken,
    cnt_clr => cnt_clr,
    cnt_en  => cnt_en,
    count   => cnt
  );
  
END rtl;
