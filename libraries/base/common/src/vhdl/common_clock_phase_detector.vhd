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

-- Purpose: Measure the phase between two clocks
-- Description:
--   The in_clk is sampled by clk. One clk is sufficient to detect the phase
--   of the in_clk. E.g. for in_clk = 2x clk:
--
--            phase  0    180   360
--                   . 90  . 270 .
--                   .  .  .  .  .
--                   .  .  .  .  .
--               _   .__.  .__.  .__    __    __    __
--   in_clk  :    |__|  |__|  |__|  |__|  |__|  |__|
--                   ._____       _____       _____
--   clk     :   ____|     |_____|     |_____|     |__
--
--   Measure in_clk at rising edge of clk or falling edge dependent on
--   g_rising_edge. When in_clk = 2x clk then only half of the in_clk cycles
--   are sampled which is sufficient:
--
--                   ._____       _____       __     in_phs
--   clk   0- 90: ___|     |_____|     |_____|    --> 1
--                   .   _____       _____      
--   clk  90-180: |_____|     |_____|     |_____  --> 0
--                ___.      _____       _____        
--   clk 180-270:    |_____|     |_____|     |__  --> 1
--                 _____       _____       _____
--   clk 270-360: |  .  |_____|     |_____|       --> 0
--
--
--   Define phase as the value measured by clk. The phase is detected
--   when it is not changing so in_phs = in_phs_dly(0) (is previous in_phs).
--
--   The clock phase detection works when in_clk = M x clk, because then M-1
--   of the in_clk cycles are skipped. When clk = N x in_clk then the in_clk
--   high and low are detected N times, which needs to be accounted for in
--   the determining of phs_evt. E.g. for clk = 2x in_clk:
--
--               phase  0    180   360
--                      . 90  . 270 .
--                      .  .  .  .  .
--                      .  .  .  .  .
--                      ._____.  .  ._____       _____
--   in_clk :       ____|  .  |_____|     |_____|     |__
--                  _   .__.  .__.  .__    __    __    __
--   clk    :        |__|  |__|  |__|  |__|  |__|  |__|  
--
--                      ._____       _____       __     in_phs
--   in_clk   0- 90: ___|     |_____|     |_____|    --> 0 1
--                      .   _____       _____      
--   in_clk  90-180: |_____|     |_____|     |_____  --> 0 1
--                   ___.      _____       _____        
--   in_clk 180-270:    |_____|     |_____|     |__  --> 1 0
--                    _____       _____       _____
--   in_clk 270-360: |  .  |_____|     |_____|       --> 1 0
--
-- Remark:
-- . For in_clk faster than clk the detected phase = in_phs is constant. For
--   clk faster than in_clk so N>1 the detected phase toggles, because then
--   the clk is fast enough to follow the transitions of the in_clk. In both
--   cases the phase_det monitors whether there occurs an unexpected transition
--   event.
-- . The clock tree logic in the FPGA ensures that clk captures the input
--   in_clk independent of how it is layout. The short routing from in_clk
--   to the D-input of the flipflop in common_async will have a small data
--   path delay and therefore this data path delay will be nearly independent
--   of the size of the design in which it is synthesised. Therefore it is
--   not necessary or appropriate to put a small logic lock region of 1 ALM
--   on common_clock_phase_detector. 
-- . The g_meta_delay_len is increased to be a multiple of c_period_len and
--   then +1 such that the clock phase relation is detected independent of
--   g_meta_delay_len. Default g_offset_delay_len=0, however e.g. by using
--   g_offset_delay_len=-1 it is possible to compensate for an external
--   pipeline stage.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.common_pkg.ALL;

ENTITY common_clock_phase_detector IS
  GENERIC (
    g_rising_edge      : BOOLEAN := TRUE;
    g_phase_rst_level  : STD_LOGIC := '0';
    g_meta_delay_len   : POSITIVE := c_meta_delay_len;
    g_offset_delay_len : INTEGER  := 0;
    g_clk_factor       : POSITIVE := 1     -- = N
  );
  PORT (
    in_clk    : IN  STD_LOGIC;           -- used as data input for clk domain
    rst       : IN  STD_LOGIC := '0';
    clk       : IN  STD_LOGIC;
    phase     : OUT STD_LOGIC;
    phase_det : OUT STD_LOGIC
  );
END common_clock_phase_detector;


ARCHITECTURE str OF common_clock_phase_detector IS

  CONSTANT c_period_len : NATURAL := 2*g_clk_factor;
  CONSTANT c_delay_len  : NATURAL := ceil_value(g_meta_delay_len, c_period_len)+1 + g_offset_delay_len;  -- detect clock phase relation independent of g_meta_delay_len
  
  SIGNAL in_phs_cap    : STD_LOGIC;
  SIGNAL in_phs        : STD_LOGIC;
  SIGNAL in_phs_dly    : STD_LOGIC_VECTOR(g_clk_factor-1 DOWNTO 0);
  SIGNAL phs_evt       : STD_LOGIC;
  SIGNAL nxt_phase_det : STD_LOGIC;
  
BEGIN

  -- Capture the in_clk in the clk domain
  u_async : ENTITY work.common_async
  GENERIC MAP (
    g_rising_edge => g_rising_edge,
    g_rst_level   => g_phase_rst_level,
    g_delay_len   => c_delay_len
  )
  PORT MAP (
    rst  => rst,
    clk  => clk,
    din  => in_clk,
    dout => in_phs_cap
  );
  
  -- Process the registers in the rising edge clk domain
  gen_r_wire : IF g_rising_edge=TRUE GENERATE
    in_phs <= in_phs_cap;
  END GENERATE;
  gen_fr_reg : IF g_rising_edge=FALSE GENERATE
    in_phs <= g_phase_rst_level WHEN rst='1' ELSE in_phs_cap WHEN rising_edge(clk);  -- get from f to r
  END GENERATE;
  
  in_phs_dly(0)                       <= in_phs                              WHEN rising_edge(clk);  -- when N=1 or M>1
  in_phs_dly(g_clk_factor-1 DOWNTO 1) <= in_phs_dly(g_clk_factor-2 DOWNTO 0) WHEN rising_edge(clk);  -- when N>1
  
  phase_det <= '0' WHEN rst='1' ELSE nxt_phase_det WHEN rising_edge(clk);
  
  -- Combinatorial function
  phs_evt <= '1' WHEN in_phs_dly(g_clk_factor-1) /= in_phs ELSE '0';
  
  nxt_phase_det <= NOT phs_evt;

  phase <= in_phs;
  
END str;
