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

LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;

-- Purpose: Control the FIFO fill level and report the dual clock lock status
-- Description:
--   When the FIFO has been filled in state s_detect_wr_clk then wr_clk_rst goes
--   high, because then the input write clock to the FIFO is active. The
--   wr_clk_rst pulse is then issued to reset the phase of the FIFO wr_clk.
--   This assumes that the FIFO wr_clk comes from an external clock divider
--   that divides a higher rate sample clock.
--   The dual clock FIFO is held in reset by means of the g_hold_dc_fifo_rst
--   timeout in state s_reset_fifo until it is sure that the wr_clk has
--   restarted again. After that the c_fifo_latency timeout in state
--   s_init_fifo is used to ensure that the FIFO filling must have started
--   after that dc_fifo_rst was released.
--   When the dual clock FIFO has been filled again in state s_fill_fifo then
--   the wr_clk and the rd_clk are assumed to be in lock and the state becomes
--   s_fill_level. In state s_fill_level the c_fifo_latency timeout is used
--   to wait until the rd_usedw is stable. The rd_usedw still increments a few
--   because the FIFO has some latency between applying rd_req and rd_usedw
--   reacting on that in case rd_usedw is derived from wr_usedw directly. The
--   actual FIFO fill level is then registered in fill_level and used in the
--   state s_dc_locked.
--   If the dual clocks of the dual clock (dc) fifo are in lock in then the
--   rd_usedw will remain constant +-g_rd_fill_margin, because then the
--   FIFO wr_clk and FIFO rd_clk have the same rate but can have a different
--   phase. Default g_rd_fill_margin = 0.
--   If rd_usedw goes below fill_level-0 then the FIFO wr_clk has stopped or
--   is slower than the FIFO rd_clk. If the rd_usedw goes above fill_level+0
--   then the FIFO wr_clk is faster than the FIFO rd_clk. Both these cases
--   indicate that the wr_clk and rd_clk lost lock.
--   The +- g_rd_fill_margin can be used to cope with phase jitter on the
--   clocks, but typically it should be 0 for systems that have a stable phase
--   relation between the wr_clk and the rd_clk, also after each powerup.
--   The control tries to recover from the loss of lock between the wr_clk and
--   the rd_clk by resetting the FIFO and letting it fill again to the
--   g_rd_fill_level in the state s_detect_wr_clk.
--   The dual clock lock status is indicated by dc_locked, when '1' then the
---  wr_clk and rd_clk are currently in lock. Whether one or  multiple losses
--   of dc lock occured is reported via dc_stable. The dc_stable is '1' when
---  the dc_locked is '1' and has not gone low (i.e. no loss of lock occured)
--   since the last time that dc_stable was acknowledged via dc_stable_ack.
--   Hence by pulsing dc_stable_ack the user can start a new fresh period for
--   dc_stable.
-- Remarks:
-- . See tb_lvdsh_dd for a test bench that uses common_fifo_dc_lock_control 
-- . Use the FIFO rd_clk clock domain to clock this common_fifo_dc_lock_control
-- . Best use a FIFO of at least size 16 and a fill level of 4, >= 3 to have
--   margin from empty at the read side and <= 8 (= 16 - 8 = 8), to have margin
--   from full at the write side.
-- . Increase g_rd_fill_level to have more time between wr_clk_rst going high
--   and dc_locked going high.
-- . The rd_fill_level can also be set via MM control to support different a
--   fill level per signal path, e.g. to compensate for cable length
--   differences between these signal paths in units of the rd_clk period.

ENTITY common_fifo_dc_lock_control IS
  GENERIC (
    g_hold_wr_clk_rst  : NATURAL := 2;  -- >= 1, nof cycles to hold the wr_clk_rst
    g_hold_dc_fifo_rst : NATURAL := 7;  -- >= 1, nof cycles to hold the dc_fifo_rst, sufficiently long for wr_clk to have restarted after wr_clk_rst release
    g_rd_fill_level    : NATURAL := 8;
    g_rd_fill_margin   : NATURAL := 1
  );
  PORT (
    -- FIFO rd_clk domain
    rd_rst        : IN  STD_LOGIC;   -- connect to FIFO rd_rst
    rd_clk        : IN  STD_LOGIC;   -- connect to FIFO rd_clk
    rd_usedw      : IN  STD_LOGIC_VECTOR;
    rd_req        : OUT STD_LOGIC;
    wr_clk_rst    : OUT STD_LOGIC;
    dc_fifo_rst   : OUT STD_LOGIC;
    
    -- MM in rd_clk domain
    rd_fill_level : IN  NATURAL := g_rd_fill_level;
    dc_locked     : OUT STD_LOGIC;
    dc_stable     : OUT STD_LOGIC;
    dc_stable_ack : IN  STD_LOGIC
  );
END common_fifo_dc_lock_control;


ARCHITECTURE rtl OF common_fifo_dc_lock_control IS

  CONSTANT c_fifo_latency      : NATURAL := 10;  -- large enough to ensure that the FIFO filling has started, but small enough such that the FIFO is not filled yet
  CONSTANT c_fill_level_max    : NATURAL := 2**rd_usedw'LENGTH-1;
  
  CONSTANT c_cnt_arr           : t_natural_arr := (g_hold_wr_clk_rst, g_hold_dc_fifo_rst, c_fifo_latency);  -- array to hold all timeouts
  CONSTANT c_cnt_max           : NATURAL := largest(c_cnt_arr);                                                  -- largest of all timeouts
  CONSTANT c_cnt_w             : NATURAL := ceil_log2(c_cnt_max+1);
  
  TYPE t_state IS (s_detect_wr_clk, s_restart_wr_clk, s_reset_fifo, s_init_fifo, s_fill_fifo, s_fill_level, s_dc_locked, s_dc_lost);
  
  SIGNAL state                : t_state;
  SIGNAL nxt_state            : t_state;
  
  SIGNAL prev_rd_usedw        : STD_LOGIC_VECTOR(rd_usedw'RANGE);
  
  SIGNAL nxt_wr_clk_rst       : STD_LOGIC;
  SIGNAL nxt_dc_fifo_rst      : STD_LOGIC;
  
  SIGNAL cnt_clr              : STD_LOGIC;
  SIGNAL cnt_en               : STD_LOGIC;
  SIGNAL cnt                  : STD_LOGIC_VECTOR(c_cnt_w-1 DOWNTO 0);
  
  SIGNAL i_dc_locked          : STD_LOGIC;
  SIGNAL nxt_dc_locked        : STD_LOGIC;
  
  SIGNAL fill_level           : NATURAL RANGE 0 TO c_fill_level_max;
  SIGNAL nxt_fill_level       : NATURAL;
  
BEGIN

  dc_locked <= i_dc_locked;
      
  p_rd_clk: PROCESS(rd_clk, rd_rst)
  BEGIN
    IF rd_rst='1' THEN
      state         <= s_detect_wr_clk;
      prev_rd_usedw <= (OTHERS=>'0');
      wr_clk_rst    <= '0';
      dc_fifo_rst   <= '1';
      i_dc_locked   <= '0';
      fill_level    <= 0;
    ELSIF rising_edge(rd_clk) THEN
      state         <= nxt_state;
      prev_rd_usedw <= rd_usedw;
      wr_clk_rst    <= nxt_wr_clk_rst;
      dc_fifo_rst   <= nxt_dc_fifo_rst;
      i_dc_locked   <= nxt_dc_locked;
      fill_level    <= nxt_fill_level;
    END IF;
  END PROCESS;

  p_state : PROCESS(state, prev_rd_usedw, rd_usedw, rd_fill_level, fill_level, cnt)
  BEGIN
    rd_req          <= '0';
    cnt_clr         <= '0';
    cnt_en          <= '0';
    nxt_wr_clk_rst  <= '0';
    nxt_dc_fifo_rst <= '0';
    nxt_dc_locked   <= '0';
    nxt_fill_level  <= fill_level;
    nxt_state       <= state;
    
    CASE state IS
      WHEN s_detect_wr_clk =>
        IF UNSIGNED(rd_usedw)>=rd_fill_level-1 THEN
          -- the FIFO has filled, so there is activity on the wr_clk
          -- assume the wr_clk is reliable, if it is not then that will be detected and recovered from in state s_fill_fifo
          cnt_clr <= '1';
          nxt_state <= s_restart_wr_clk;
        END IF;
      WHEN s_restart_wr_clk =>
        cnt_en <= '1';
        IF UNSIGNED(cnt)<g_hold_wr_clk_rst THEN
          nxt_wr_clk_rst <= '1';  -- reset and restart the external write clock divider by asserting wr_clk_rst for g_hold_wr_clk_rst cycles of the rd_clk
        ELSE
          cnt_clr <= '1';
          nxt_state <= s_reset_fifo;
        END IF;
      WHEN s_reset_fifo =>
        cnt_en <= '1';
        IF UNSIGNED(cnt)<g_hold_dc_fifo_rst THEN
          nxt_dc_fifo_rst <= '1';    -- reset the input FIFO until the wr_clk has been able to restart for sure
        ELSE
          cnt_clr <= '1';
          nxt_state <= s_init_fifo;
        END IF;
      WHEN s_init_fifo =>
        cnt_en <= '1';
        IF UNSIGNED(cnt)>c_fifo_latency THEN
          -- reset release latency : the FIFO should have started filling by now
          nxt_state <= s_fill_fifo;
        END IF;
      WHEN s_fill_fifo =>
        IF UNSIGNED(rd_usedw)=UNSIGNED(prev_rd_usedw)+1 THEN
          -- the FIFO filling properly at every rd_clk cycle
          IF UNSIGNED(rd_usedw)>=rd_fill_level-1 THEN
            rd_req <= '1';
            cnt_clr <= '1';
            nxt_state <= s_fill_level;
          END IF;
        ELSE
          -- the FIFO filling went too slow or too fast so the potential lock is lost
          nxt_state <= s_dc_lost;
        END IF;
      WHEN s_fill_level =>
        rd_req <= '1';
        cnt_en <= '1';
        IF UNSIGNED(cnt)>c_fifo_latency THEN
          -- synchronizer chain latency : the FIFO fill level on the write side should be stable by now
          nxt_fill_level <= TO_UINT(rd_usedw);
          nxt_state <= s_dc_locked;
        END IF;
      WHEN s_dc_locked =>
        rd_req <= '1';
        nxt_dc_locked <= '1';
        IF UNSIGNED(rd_usedw)<fill_level-g_rd_fill_margin OR UNSIGNED(rd_usedw)>fill_level+g_rd_fill_margin THEN
          -- the FIFO fill level changed (too much) so the lock is lost
          nxt_state <= s_dc_lost;
        END IF;
      WHEN OTHERS =>  -- s_dc_lost
        nxt_dc_fifo_rst <= '1';  -- reset the input FIFO to reset rd_usedw
        nxt_state <= s_detect_wr_clk;
    END CASE;
  END PROCESS;
  
  u_cnt : ENTITY common_lib.common_counter
  GENERIC MAP (
    g_width  => c_cnt_w
  )
  PORT MAP (
    rst     => rd_rst,
    clk     => rd_clk,
    cnt_clr => cnt_clr,
    cnt_en  => cnt_en,
    count   => cnt
  );
  
  u_dc_locked_monitor : ENTITY work.common_stable_monitor
  PORT MAP (
    rst          => rd_rst,
    clk          => rd_clk,
    -- MM
    r_in         => i_dc_locked,
    r_stable     => dc_stable,
    r_stable_ack => dc_stable_ack
  );
    
END rtl;
