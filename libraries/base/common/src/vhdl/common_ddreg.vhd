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

-- Purpose: Capture internal signal at double data rate
-- Description:
-- . Function:
--   The double data rate in_dat samples that arrive at time series t0, t1, t2,
--   ... get output with samples t0, t2, ... in out_dat_lo and samples t1, t3,
--   ... in out_dat_hi. Hence out_dat = out_dat_hi & out_dat_lo contains the
--   time series samples in little endian format with the first sample in the
--   LSpart. This is similar to common_ddio_in.
--
-- . Schematic:
--   The in_dat is first registered by in_clk and then captured by out_clk. 
--   There is a common_ddreg_r for capturing at rising edge of out_clk and
--   a common_ddreg_f for capturing at falling edge of out_clk. These are
--   separate components to allow placing each of them in a single ALM using
--   a logic lock region. Together they do not fit in a single ALM, because
--   one ALM can fit only two clocks, so in_clk and out_clk-r or in_clk and
--   out_clk-f, but not in_clk and out_clk-r and out_clk-f. After
--   common_ddreg_f a seperate common_ddreg_fr is used to carry the data from
--   the falling edge flipflop to the rising edge flipflop in the out_clk
--   clock domain.
--
--             ------------------------------------
--   in_dat -->| ddreg_r                          |----> out_dat_hi
--   in_clk -->| async     async                  |<---- out_clk
--             ------------------------------------
--
--             -------------------     ------------
--   in_dat -->| ddreg_f         |---->| ddreg_fr |----> out_dat_lo
--   in_clk -->| async     async |<-\  | fFF  rFF |<-+-- out_clk
--             -------------------  |  ------------  |
--                                  |                |
--                                  \----------------/
--
--   The common_async in common_ddreg_r and common_ddreg_f has a preserve
--   register synthesis attribute to ensure that the input register clocked
--   by in_clk does not get optimized away because it exists in both 
--   common_ddreg_r and common_ddreg_f.
--   In this way the clock domain transition from in_clk --> out_clk-r for
--   in_dat to out_dat_hi is kept within 1 ALM, to restrict the data path delay
--   and to make it as synthesis design indepentent as possible. Similar or
--   the clock domain transition from in_clk --> out_clk-f for in_dat to
--   out_dat_lo.
-- Remark:
-- . Similar to common_ddio_in but for internal signal instead of FPGA input
--   pin signal.

--------------------------------------------------------------------------------
-- common_ddreg_r
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.common_pkg.ALL;

ENTITY common_ddreg_r IS
  GENERIC (
    g_in_delay_len    : POSITIVE := 1;
    g_out_delay_len   : POSITIVE := c_meta_delay_len;
    g_tsetup_delay_hi : BOOLEAN := FALSE
  );
  PORT (
    in_clk      : IN  STD_LOGIC;
    in_dat      : IN  STD_LOGIC;
    rst         : IN  STD_LOGIC := '0';
    out_clk     : IN  STD_LOGIC;
    out_dat_r   : OUT STD_LOGIC
  );
END common_ddreg_r;


ARCHITECTURE str OF common_ddreg_r IS
  
  SIGNAL in_dat_r   : STD_LOGIC;
  SIGNAL in_dat_d   : STD_LOGIC;
  
BEGIN

  u_in : ENTITY work.common_async
  GENERIC MAP (
    g_delay_len => g_in_delay_len
  )
  PORT MAP (
    rst  => rst,
    clk  => in_clk,
    din  => in_dat,
    dout => in_dat_r
  );
  
  in_dat_d <= in_dat_r WHEN g_tsetup_delay_hi=FALSE ELSE in_dat_r WHEN rising_edge(out_clk);
  
  -- Output at rising edge
  u_out_hi : ENTITY work.common_async
  GENERIC MAP (
    g_delay_len => g_out_delay_len
  )
  PORT MAP (
    rst  => rst,
    clk  => out_clk,
    din  => in_dat_d,
    dout => out_dat_r
  );
END str;


--------------------------------------------------------------------------------
-- common_ddreg_f
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.common_pkg.ALL;

ENTITY common_ddreg_f IS
  GENERIC (
    g_in_delay_len    : POSITIVE := 1;
    g_out_delay_len   : POSITIVE := c_meta_delay_len;
    g_tsetup_delay_lo : BOOLEAN := FALSE
  );
  PORT (
    in_clk      : IN  STD_LOGIC;
    in_dat      : IN  STD_LOGIC;
    rst         : IN  STD_LOGIC := '0';
    out_clk     : IN  STD_LOGIC;
    out_dat_f   : OUT STD_LOGIC  -- clocked at falling edge of out_clk
  );
END common_ddreg_f;


ARCHITECTURE str OF common_ddreg_f IS
  
  SIGNAL in_dat_r   : STD_LOGIC;
  SIGNAL in_dat_d   : STD_LOGIC;
  
BEGIN

  u_in : ENTITY work.common_async
  GENERIC MAP (
    g_delay_len => g_in_delay_len
  )
  PORT MAP (
    rst  => rst,
    clk  => in_clk,
    din  => in_dat,
    dout => in_dat_r
  );
  
  in_dat_d <= in_dat_r WHEN g_tsetup_delay_lo=FALSE ELSE in_dat_r WHEN falling_edge(out_clk);
  
  -- Capture input at falling edge
  u_fall : ENTITY work.common_async
  GENERIC MAP (
    g_rising_edge => FALSE,
    g_delay_len   => g_out_delay_len
  )
  PORT MAP (
    rst  => rst,
    clk  => out_clk,
    din  => in_dat_d,
    dout => out_dat_f
  );
  
END str;


--------------------------------------------------------------------------------
-- common_ddreg_fr
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.common_pkg.ALL;

ENTITY common_ddreg_fr IS
  PORT (
    rst         : IN  STD_LOGIC := '0';
    clk         : IN  STD_LOGIC;
    in_dat_f    : IN  STD_LOGIC;         -- clocked at falling edge of clk
    out_dat_r   : OUT STD_LOGIC          -- clocked at rising edge of clk
  );
END common_ddreg_fr;


ARCHITECTURE str OF common_ddreg_fr IS
  
  SIGNAL in_dat_d   : STD_LOGIC;
  
BEGIN

  in_dat_d  <= in_dat_f WHEN falling_edge(clk);  -- input at falling edge
  out_dat_r <= in_dat_d WHEN rising_edge(clk);   -- Output at rising edge
  
END str;


--------------------------------------------------------------------------------
-- common_ddreg
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.common_pkg.ALL;

ENTITY common_ddreg IS
  GENERIC (
    g_in_delay_len    : POSITIVE := 1;
    g_out_delay_len   : POSITIVE := c_meta_delay_len;
    g_tsetup_delay_hi : BOOLEAN := FALSE;
    g_tsetup_delay_lo : BOOLEAN := FALSE
  );
  PORT (
    in_clk      : IN  STD_LOGIC;
    in_dat      : IN  STD_LOGIC;
    rst         : IN  STD_LOGIC := '0';
    out_clk     : IN  STD_LOGIC;
    out_dat_hi  : OUT STD_LOGIC;
    out_dat_lo  : OUT STD_LOGIC
  );
END common_ddreg;


ARCHITECTURE str OF common_ddreg IS

  SIGNAL out_dat_f   : STD_LOGIC;
  
BEGIN

  -- out_dat_hi
  u_ddreg_hi : ENTITY work.common_ddreg_r
  GENERIC MAP (
    g_in_delay_len    => g_in_delay_len,
    g_out_delay_len   => g_out_delay_len,
    g_tsetup_delay_hi => g_tsetup_delay_hi
  )
  PORT MAP (
    in_clk     => in_clk,
    in_dat     => in_dat,
    rst        => rst,
    out_clk    => out_clk,
    out_dat_r  => out_dat_hi
  );
  
  -- out_dat_lo
  u_ddreg_fall : ENTITY work.common_ddreg_f
  GENERIC MAP (
    g_in_delay_len    => g_in_delay_len,
    g_out_delay_len   => g_out_delay_len-1,
    g_tsetup_delay_lo => g_tsetup_delay_lo
  )
  PORT MAP (
    in_clk     => in_clk,
    in_dat     => in_dat,
    rst        => rst,
    out_clk    => out_clk,
    out_dat_f  => out_dat_f    -- clocked at falling edge of out_clk
  );
    
  u_ddreg_lo : ENTITY work.common_ddreg_fr
  PORT MAP (
    rst         => rst,
    clk         => out_clk,
    in_dat_f    => out_dat_f,
    out_dat_r   => out_dat_lo  -- clocked at rising edge of out_clk
  );
END str;
