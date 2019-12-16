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

-- Purpose: Scope component to show the concateneated DP in_data at the SCLK
--          sample rate in the Wave Window
-- Description: 
-- . See dp_wideband_sp_arr_scope (for g_nof_streams=1)
-- . The wideband in_data has g_wideband_factor nof samples per word. For
--   g_wideband_big_endian=TRUE sthe first sample is in the MS symbol.
-- Remark:
-- . Only for simulation.


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.common_pkg.ALL;

ENTITY common_wideband_data_scope IS
  GENERIC (
    g_sim                 : BOOLEAN := FALSE;
    g_wideband_factor     : NATURAL := 4;        -- Wideband rate factor = 4 for dp_clk processing frequency is 200 MHz frequency and SCLK sample frequency Fs is 800 MHz
    g_wideband_big_endian : BOOLEAN := TRUE;     -- When true in_data[3:0] = sample[t0,t1,t2,t3], else when false : in_data[3:0] = sample[t3,t2,t1,t0]
    g_dat_w               : NATURAL := 8         -- Actual width of the data samples
  );
  PORT (
    -- Sample clock
    SCLK      : IN STD_LOGIC := '0';  -- sample clk, use only for simulation purposes
    
    -- Streaming input data
    in_data   : IN STD_LOGIC_VECTOR(g_wideband_factor*g_dat_w-1 DOWNTO 0);
    in_val    : IN STD_LOGIC;
    
    -- Scope output samples
    out_dat   : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    out_int   : OUT INTEGER
  );
END common_wideband_data_scope;


ARCHITECTURE beh OF common_wideband_data_scope IS

  SIGNAL scope_cnt   : NATURAL;
  SIGNAL scope_dat   : STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
  
BEGIN

  sim_only : IF g_sim=TRUE GENERATE
    -- View in_data at the sample rate using out_dat 
    p_scope_dat : PROCESS(SCLK)
      VARIABLE vI : NATURAL;
    BEGIN
      IF rising_edge(SCLK) THEN
        IF g_wideband_big_endian=TRUE THEN
          vI := g_wideband_factor-1-scope_cnt;
        ELSE
          vI := scope_cnt;
        END IF;
        scope_cnt <= 0;
        IF in_val='1' AND scope_cnt < g_wideband_factor-1 THEN
          scope_cnt <= scope_cnt + 1;
        END IF;
        scope_dat <= in_data((vI+1)*g_dat_w-1 DOWNTO vI*g_dat_w);
      END IF;
    END PROCESS;
    
    out_dat <= scope_dat;
    out_int <= TO_SINT(scope_dat);
  END GENERATE;
  
END beh;
