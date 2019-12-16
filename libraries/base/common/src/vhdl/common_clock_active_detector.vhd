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

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.common_pkg.ALL;

-- Purpose: Detect 400 MHz in_clk active in the 200 MHz dp_clk domain
-- Description:
    
ENTITY common_clock_active_detector IS
  GENERIC (
    g_in_period_w       : NATURAL := 8;     -- created 2**g_in_period_w period source signal in in_clk domain
    g_dp_detect_period  : NATURAL := 128;   -- expected period for source signal in dp_clk domain given 2**g_in_period_w in in_clk domain
    g_dp_detect_margin  : NATURAL := 1
  );
  PORT (
    -- PHY input interface
    in_clk               : IN  STD_LOGIC;
    dp_rst               : IN  STD_LOGIC := '0';
    dp_clk               : IN  STD_LOGIC;
    dp_in_clk_detected   : OUT STD_LOGIC;
    dp_in_clk_stable     : OUT STD_LOGIC;
    dp_in_clk_stable_ack : IN  STD_LOGIC := '1'
  );
END common_clock_active_detector;


ARCHITECTURE str OF common_clock_active_detector IS

  CONSTANT c_delay_len           : NATURAL := c_meta_delay_len;
  
  CONSTANT c_dp_detect_period_w  : NATURAL := ceil_log2(g_dp_detect_period);
  CONSTANT c_dp_detect_max       : NATURAL := g_dp_detect_period+g_dp_detect_margin;
  CONSTANT c_dp_detect_min       : NATURAL := g_dp_detect_period-g_dp_detect_margin;
  CONSTANT c_dp_clk_cnt_w        : NATURAL := c_dp_detect_period_w + 1;    -- +1 to be wide enough to fit somewhat more than maximum nof clock cycles per interval
  CONSTANT c_dp_clk_cnt_max      : NATURAL := 2**c_dp_clk_cnt_w-1;
  
  SIGNAL dbg_g_in_period_w       : NATURAL := g_in_period_w;
  SIGNAL dbg_g_dp_detect_period  : NATURAL := g_dp_detect_period;
  SIGNAL dbg_g_dp_detect_margin  : NATURAL := g_dp_detect_margin;
  SIGNAL dbg_c_dp_detect_max     : NATURAL := c_dp_detect_max;
  SIGNAL dbg_c_dp_detect_min     : NATURAL := c_dp_detect_min;
  SIGNAL dbg_c_dp_clk_cnt_max    : NATURAL := c_dp_clk_cnt_max;
  
  SIGNAL in_clk_cnt              : STD_LOGIC_VECTOR(g_in_period_w-1 DOWNTO 0);
  SIGNAL in_toggle               : STD_LOGIC;
  
  SIGNAL dp_toggle               : STD_LOGIC;
  SIGNAL dp_toggle_revt          : STD_LOGIC;  
  SIGNAL dp_clk_cnt_en           : STD_LOGIC;
  SIGNAL dp_clk_cnt_clr          : STD_LOGIC;
  SIGNAL dp_clk_cnt              : STD_LOGIC_VECTOR(c_dp_clk_cnt_w-1 DOWNTO 0);
  SIGNAL dp_clk_interval         : STD_LOGIC_VECTOR(c_dp_clk_cnt_w-1 DOWNTO 0);
  SIGNAL nxt_dp_clk_interval     : STD_LOGIC_VECTOR(c_dp_clk_cnt_w-1 DOWNTO 0);
  SIGNAL i_dp_in_clk_detected    : STD_LOGIC;
  SIGNAL nxt_dp_in_clk_detected  : STD_LOGIC;
  
BEGIN

  u_common_counter_in_clk : ENTITY work.common_counter
  GENERIC MAP (
    g_width => g_in_period_w
  )
  PORT MAP (
    rst     => '0',
    clk     => in_clk,
    count   => in_clk_cnt
  );
  
  in_toggle <= in_clk_cnt(in_clk_cnt'HIGH);
  
  u_common_async_dp_toggle : ENTITY work.common_async
  GENERIC MAP (
    g_rst_level => '1',
    g_delay_len => c_delay_len
  )
  PORT MAP (
    rst  => dp_rst,
    clk  => dp_clk,
    din  => in_toggle,
    dout => dp_toggle
  );
  
  u_common_evt : ENTITY work.common_evt
  GENERIC MAP (
    g_evt_type   => "RISING",
    g_out_reg    => TRUE
  )
  PORT MAP (
    rst      => dp_rst,
    clk      => dp_clk,
    in_sig   => dp_toggle,
    out_evt  => dp_toggle_revt
  );
  
  dp_clk_cnt_en  <= '1' WHEN UNSIGNED(dp_clk_cnt) < c_dp_clk_cnt_max ELSE '0';
  dp_clk_cnt_clr <= dp_toggle_revt OR NOT dp_clk_cnt_en;
  
  u_common_counter_dp_clk : ENTITY work.common_counter
  GENERIC MAP (
    g_width => c_dp_clk_cnt_w
  )
  PORT MAP (
    rst     => dp_rst,
    clk     => dp_clk,
    cnt_clr => dp_clk_cnt_clr,
    cnt_en  => dp_clk_cnt_en,
    count   => dp_clk_cnt
  );
  
  nxt_dp_clk_interval <= INCR_UVEC(dp_clk_cnt, 1) WHEN dp_clk_cnt_clr='1' ELSE dp_clk_interval;
  
  nxt_dp_in_clk_detected <= '1' WHEN UNSIGNED(dp_clk_interval) >= c_dp_detect_min AND UNSIGNED(dp_clk_interval) <= c_dp_detect_max ELSE '0';
  
  p_dp_reg : PROCESS(dp_rst, dp_clk)
  BEGIN
    IF dp_rst='1' THEN
      dp_clk_interval      <= (OTHERS=>'0');
      i_dp_in_clk_detected <= '0';
    ELSIF rising_edge(dp_clk) THEN
      dp_clk_interval      <= nxt_dp_clk_interval;
      i_dp_in_clk_detected <= nxt_dp_in_clk_detected;
    END IF;
  END PROCESS;
  
  dp_in_clk_detected <= i_dp_in_clk_detected;
  
  u_common_stable_monitor : ENTITY work.common_stable_monitor
  PORT MAP (
    rst          => dp_rst,
    clk          => dp_clk,
    -- MM
    r_in         => i_dp_in_clk_detected,
    r_stable     => dp_in_clk_stable,
    r_stable_ack => dp_in_clk_stable_ack
  );
  
END str;
