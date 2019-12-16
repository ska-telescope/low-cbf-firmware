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

-- Purpose: Test bench for common_shiftreg.vhd
-- Usage:
-- > as 3
-- > run -all
--   proc_common_verify_data self-checks the incrementing output

ENTITY tb_common_shiftreg IS
  GENERIC (
    g_pipeline  : NATURAL := 0;
    g_flush_en  : BOOLEAN := TRUE;  -- use true to flush shift register when full else only shift at active in_val
    g_nof_dat   : NATURAL := 3;     -- nof dat in the shift register, including in_dat
    g_dat_w     : NATURAL := 8
  );
END tb_common_shiftreg;

ARCHITECTURE tb OF tb_common_shiftreg IS

  CONSTANT clk_period   : TIME := 10 ns;
  
  CONSTANT c_cnt_w      : NATURAL := ceil_log2(g_nof_dat);
  CONSTANT c_repeat     : NATURAL := 5;
  CONSTANT c_gap_len    : NATURAL := 50;
  
  -- Stimuli
  SIGNAL tb_end         : STD_LOGIC := '0';
  SIGNAL rst            : STD_LOGIC;
  SIGNAL clk            : STD_LOGIC := '1';
  
  SIGNAL in_dat         : STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL nxt_in_dat     : STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
  SIGNAL in_val         : STD_LOGIC;
  SIGNAL nxt_in_val     : STD_LOGIC;
  SIGNAL in_sop         : STD_LOGIC;
  SIGNAL nxt_in_sop     : STD_LOGIC;
  SIGNAL in_eop         : STD_LOGIC;
  SIGNAL nxt_in_eop     : STD_LOGIC;
  
  -- DUT output
  SIGNAL out_data_vec   : STD_LOGIC_VECTOR(g_nof_dat*g_dat_w-1 DOWNTO 0);
  SIGNAL out_val_vec    : STD_LOGIC_VECTOR(g_nof_dat-1 DOWNTO 0);
  SIGNAL out_sop_vec    : STD_LOGIC_VECTOR(g_nof_dat-1 DOWNTO 0);
  SIGNAL out_eop_vec    : STD_LOGIC_VECTOR(g_nof_dat-1 DOWNTO 0);
  SIGNAL out_cnt        : STD_LOGIC_VECTOR(c_cnt_w-1 DOWNTO 0);
  
  SIGNAL out_dat        : STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL out_val        : STD_LOGIC;
  SIGNAL out_sop        : STD_LOGIC;
  SIGNAL out_eop        : STD_LOGIC;
  
  -- Verify
  SIGNAL verify_en      : STD_LOGIC := '0';
  SIGNAL ready          : STD_LOGIC := '1';
  SIGNAL prev_out_dat   : STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0) := (OTHERS=>'1');
    
BEGIN

  -- Stimuli
  clk <= NOT clk OR tb_end AFTER clk_period/2;
  rst <= '1', '0' AFTER 3*clk_period;
  
  p_clk : PROCESS (rst, clk)
  BEGIN
    IF rst='1' THEN
      in_dat <= (OTHERS=>'0');
      in_val <= '0';
      in_sop <= '0';
      in_eop <= '0';
    ELSIF rising_edge(clk) THEN
      in_dat <= nxt_in_dat;
      in_val <= nxt_in_val;
      in_sop <= nxt_in_sop;
      in_eop <= nxt_in_eop;
    END IF;
  END PROCESS;
      
  nxt_in_dat <= STD_LOGIC_VECTOR(SIGNED(in_dat)+1) WHEN in_val='1' ELSE in_dat;
  
  p_stimuli : PROCESS
  BEGIN
    nxt_in_val <= '0';
    nxt_in_sop <= '0';
    nxt_in_eop <= '0';
    proc_common_wait_some_cycles(clk, 10);
    verify_en <= '1';

    -- Verify flush    
    proc_common_sop(clk, nxt_in_val, nxt_in_sop);
    proc_common_wait_some_cycles(clk, g_nof_dat*5);
    proc_common_eop_flush(g_nof_dat, clk, nxt_in_val, nxt_in_eop);
    proc_common_wait_some_cycles(clk, c_gap_len);
    
    -- Verify pulsed valid without flush
    FOR I IN 1 TO c_repeat LOOP
      proc_common_sop(clk, nxt_in_val, nxt_in_sop);
      FOR J IN 0 TO 5*g_nof_dat+I-1 LOOP
        proc_common_val_duty(I, I, clk, nxt_in_val);
      END LOOP;
      proc_common_eop_flush(0, clk, nxt_in_val, nxt_in_eop);
    END LOOP;
    proc_common_wait_some_cycles(clk, c_gap_len);
    
    -- Verify pulsed valid with flush
    FOR I IN 1 TO c_repeat LOOP
      proc_common_sop(clk, nxt_in_val, nxt_in_sop);
      FOR J IN 0 TO 5*g_nof_dat+I-1 LOOP
        proc_common_val_duty(I, I, clk, nxt_in_val);
      END LOOP;
      proc_common_eop_flush(g_nof_dat, clk, nxt_in_val, nxt_in_eop);
    END LOOP;
    proc_common_wait_some_cycles(clk, c_gap_len);
    
    -- Verify chirped valid with flush
    FOR I IN g_nof_dat-1 TO 2*g_nof_dat LOOP
      proc_common_sop(clk, nxt_in_val, nxt_in_sop);
      FOR J IN g_nof_dat-1 TO 2*g_nof_dat LOOP
        proc_common_val_duty(I, I, clk, nxt_in_val);
      END LOOP;
      proc_common_eop_flush(g_nof_dat, clk, nxt_in_val, nxt_in_eop);
    END LOOP;
    proc_common_wait_some_cycles(clk, c_gap_len);
    
    -- Verify continue valid with flush
    proc_common_sop(clk, nxt_in_val, nxt_in_sop);
    proc_common_wait_some_cycles(clk, 25);
    proc_common_eop_flush(g_nof_dat, clk, nxt_in_val, nxt_in_eop);
    
    proc_common_wait_some_cycles(clk, c_gap_len);
    tb_end <= '1';
    WAIT;
  END PROCESS;
  
  -- DUT
  u_shiftreg : ENTITY work.common_shiftreg
  GENERIC MAP (
    g_pipeline  => g_pipeline,
    g_flush_en  => g_flush_en,
    g_nof_dat   => g_nof_dat,
    g_dat_w     => g_dat_w
  )
  PORT MAP (
    rst          => rst,
    clk          => clk,
    
    in_dat       => in_dat,
    in_val       => in_val,
    in_sop       => in_sop,
    in_eop       => in_eop,
    
    out_data_vec => out_data_vec,
    out_val_vec  => out_val_vec,
    out_sop_vec  => out_sop_vec,
    out_eop_vec  => out_eop_vec,
    out_cnt      => out_cnt,
    
    out_dat      => out_dat,
    out_val      => out_val,
    out_sop      => out_sop,
    out_eop      => out_eop
  );
  
  -- Verification  
  proc_common_verify_data(1, clk, verify_en, ready, out_val, out_dat, prev_out_dat);
  
END tb;
