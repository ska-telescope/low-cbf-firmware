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

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;

-- Purpose: Shift register when in_val is active with optional flush at in_eop.
-- Description:
--   The shift register contains g_nof_dat-1 shift registers, so it directly
--   combinatorially includes in_dat. The shift register shifts when in_val
--   is active. 
--   If g_flush_en is FALSE then the shift register is always filled when valid
--   data comes out. Hence the out_dat then shifts out with in_val.
--   If g_flush_en is TRUE then the shift register flushes itself when in_eop
--   = '1'. The in_eop marks the last valid in_dat of a block.
--   The out_cnt counts the number of in_val modulo g_nof_dat and restarts at
--   the in_eop. The in_cnt starts at 1, in this way the out_cnt=0 marks the
--   out_data_vec that contain a complete set of g_nof_dat number of new
--   out_dat.
-- Remarks:
-- . Optionally the output can be pipelined via g_pipeline.

ENTITY common_shiftreg IS
  GENERIC (
    g_pipeline  : NATURAL := 0;      -- pipeline output
    g_flush_en  : BOOLEAN := FALSE;  -- use true to flush shift register when in_eop is active else only shift at active in_val
    g_nof_dat   : POSITIVE := 4;     -- nof data in the shift register, including in_dat, so >= 1
    g_dat_w     : NATURAL := 16
  );
  PORT (
    rst          : IN  STD_LOGIC;
    clk          : IN  STD_LOGIC;
    
    in_dat       : IN  STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    in_val       : IN  STD_LOGIC := '1';
    in_sop       : IN  STD_LOGIC := '0';
    in_eop       : IN  STD_LOGIC := '0';
   
    out_req      : IN  STD_LOGIC := '0'; 
    out_data_vec : OUT STD_LOGIC_VECTOR(g_nof_dat*g_dat_w-1 DOWNTO 0);
    out_val_vec  : OUT STD_LOGIC_VECTOR(g_nof_dat-1 DOWNTO 0);
    out_sop_vec  : OUT STD_LOGIC_VECTOR(g_nof_dat-1 DOWNTO 0);
    out_eop_vec  : OUT STD_LOGIC_VECTOR(g_nof_dat-1 DOWNTO 0);
    out_cnt      : OUT STD_LOGIC_VECTOR(sel_a_b(g_nof_dat=1,1,ceil_log2(g_nof_dat))-1 DOWNTO 0);   -- avoid ISE synthesis failure on NULL range for g_nof_dat=1
    
    out_dat      : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);  -- = out_data_vec(0)
    out_val      : OUT STD_LOGIC;                             -- = out_val_vec(0)
    out_sop      : OUT STD_LOGIC;                             -- = out_sop_vec(0)
    out_eop      : OUT STD_LOGIC                              -- = out_eop_vec(0)
  );
END common_shiftreg;


ARCHITECTURE str OF common_shiftreg IS

  TYPE t_data_arr  IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
  
  CONSTANT c_cnt_w      : NATURAL := out_cnt'LENGTH;

  SIGNAL shift_en       : STD_LOGIC;
  SIGNAL flush          : STD_LOGIC;
    
  SIGNAL data_arr       : t_data_arr(g_nof_dat-1 DOWNTO 0) := (OTHERS=>(OTHERS=>'0'));
  SIGNAL nxt_data_arr   : t_data_arr(g_nof_dat-2 DOWNTO 0);
  SIGNAL val_arr        : STD_LOGIC_VECTOR(g_nof_dat-1 DOWNTO 0);
  SIGNAL nxt_val_arr    : STD_LOGIC_VECTOR(g_nof_dat-2 DOWNTO 0);
  SIGNAL sop_arr        : STD_LOGIC_VECTOR(g_nof_dat-1 DOWNTO 0);
  SIGNAL nxt_sop_arr    : STD_LOGIC_VECTOR(g_nof_dat-2 DOWNTO 0);
  SIGNAL eop_arr        : STD_LOGIC_VECTOR(g_nof_dat-1 DOWNTO 0);
  SIGNAL nxt_eop_arr    : STD_LOGIC_VECTOR(g_nof_dat-2 DOWNTO 0);
  
  SIGNAL in_cnt         : STD_LOGIC_VECTOR(c_cnt_w-1 DOWNTO 0);
  SIGNAL nxt_in_cnt     : STD_LOGIC_VECTOR(c_cnt_w-1 DOWNTO 0);
  
  SIGNAL data_vec       : STD_LOGIC_VECTOR(g_nof_dat*g_dat_w-1 DOWNTO 0);
  SIGNAL val_vec        : STD_LOGIC_VECTOR(g_nof_dat-1 DOWNTO 0);
  SIGNAL sop_vec        : STD_LOGIC_VECTOR(g_nof_dat-1 DOWNTO 0);
  SIGNAL eop_vec        : STD_LOGIC_VECTOR(g_nof_dat-1 DOWNTO 0);
  
  SIGNAL i_out_data_vec : STD_LOGIC_VECTOR(g_nof_dat*g_dat_w-1 DOWNTO 0);
  SIGNAL i_out_val_vec  : STD_LOGIC_VECTOR(g_nof_dat-1 DOWNTO 0);
  SIGNAL i_out_sop_vec  : STD_LOGIC_VECTOR(g_nof_dat-1 DOWNTO 0);
  SIGNAL i_out_eop_vec  : STD_LOGIC_VECTOR(g_nof_dat-1 DOWNTO 0);
  
BEGIN

  no_sreg : IF g_nof_dat=1 GENERATE
    -- directly assign the inputs to avoid NULL array warning in gen_sreg
    data_vec   <= in_dat;
    val_vec(0) <= in_val;
    sop_vec(0) <= in_sop;
    eop_vec(0) <= in_eop;
  END GENERATE;
  
  gen_sreg : IF g_nof_dat>1 GENERATE
    -- Combinatorial input via high index
    data_arr(g_nof_dat-1) <= in_dat;
    val_arr( g_nof_dat-1) <= in_val;
    sop_arr( g_nof_dat-1) <= in_sop;
    eop_arr( g_nof_dat-1) <= in_eop;
  
    -- Register
    p_clk : PROCESS(rst, clk)
    BEGIN
      IF rst='1' THEN
        val_arr( g_nof_dat-2 DOWNTO 0) <= (OTHERS=>'0');
        sop_arr( g_nof_dat-2 DOWNTO 0) <= (OTHERS=>'0');
        eop_arr( g_nof_dat-2 DOWNTO 0) <= (OTHERS=>'0');
        in_cnt                         <= TO_UVEC(1, c_cnt_w);
      ELSIF rising_edge(clk) THEN
        data_arr(g_nof_dat-2 DOWNTO 0) <= nxt_data_arr(g_nof_dat-2 DOWNTO 0);
        val_arr( g_nof_dat-2 DOWNTO 0) <= nxt_val_arr( g_nof_dat-2 DOWNTO 0);
        sop_arr( g_nof_dat-2 DOWNTO 0) <= nxt_sop_arr( g_nof_dat-2 DOWNTO 0);
        eop_arr( g_nof_dat-2 DOWNTO 0) <= nxt_eop_arr( g_nof_dat-2 DOWNTO 0);
        in_cnt                         <= nxt_in_cnt;
      END IF;
    END PROCESS;
    
    -- Shift control
    u_flush : ENTITY work.common_switch
    GENERIC MAP (
      g_rst_level => '0'
    )
    PORT MAP (
      clk         => clk,
      rst         => rst,
      switch_high => in_eop,
      switch_low  => eop_arr(0),
      out_level   => flush
    );
    
    shift_en <= in_val OR flush WHEN g_flush_en=TRUE ELSE in_val OR out_req;
    
    nxt_data_arr(g_nof_dat-2 DOWNTO 0) <= data_arr(g_nof_dat-1 DOWNTO 1) WHEN shift_en='1' ELSE data_arr(g_nof_dat-2 DOWNTO 0);
    nxt_val_arr( g_nof_dat-2 DOWNTO 0) <= val_arr( g_nof_dat-1 DOWNTO 1) WHEN shift_en='1' ELSE val_arr( g_nof_dat-2 DOWNTO 0);
    nxt_sop_arr( g_nof_dat-2 DOWNTO 0) <= sop_arr( g_nof_dat-1 DOWNTO 1) WHEN shift_en='1' ELSE sop_arr( g_nof_dat-2 DOWNTO 0);
    nxt_eop_arr( g_nof_dat-2 DOWNTO 0) <= eop_arr( g_nof_dat-1 DOWNTO 1) WHEN shift_en='1' ELSE eop_arr( g_nof_dat-2 DOWNTO 0);
    
    p_in_cnt : PROCESS(in_cnt, eop_arr, shift_en)
    BEGIN
      nxt_in_cnt <= in_cnt;
      IF eop_arr(0)='1' THEN
        nxt_in_cnt <= TO_UVEC(1, c_cnt_w);
      ELSIF shift_en='1' THEN
        IF UNSIGNED(in_cnt) < g_nof_dat-1 THEN
          nxt_in_cnt <= INCR_UVEC(in_cnt, 1);
        ELSE
          nxt_in_cnt <= (OTHERS=>'0');
        END IF;
      END IF;
    END PROCESS;
    
    gen_data_vec : FOR I IN g_nof_dat-1 DOWNTO 0 GENERATE
      data_vec((I+1)*g_dat_w-1 DOWNTO I*g_dat_w) <= data_arr(I);  -- map arr to output vector
      val_vec(I) <= val_arr(I) AND shift_en;
      sop_vec(I) <= sop_arr(I) AND shift_en;
      eop_vec(I) <= eop_arr(I) AND shift_en;
    END GENERATE;
  END GENERATE;
  
  -- Pipeline output
  out_data_vec <= i_out_data_vec;
  out_val_vec  <= i_out_val_vec;
  out_sop_vec  <= i_out_sop_vec;
  out_eop_vec  <= i_out_eop_vec;
  
  out_dat      <= i_out_data_vec(g_dat_w-1 DOWNTO 0);
  out_val      <= i_out_val_vec(0);
  out_sop      <= i_out_sop_vec(0);
  out_eop      <= i_out_eop_vec(0);

  u_out_data_vec : ENTITY work.common_pipeline
  GENERIC MAP (
    g_pipeline  => g_pipeline,
    g_in_dat_w  => g_nof_dat*g_dat_w,
    g_out_dat_w => g_nof_dat*g_dat_w
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => data_vec,
    out_dat => i_out_data_vec
  );
  
  u_out_val_vec : ENTITY work.common_pipeline
  GENERIC MAP (
    g_pipeline  => g_pipeline,
    g_in_dat_w  => g_nof_dat,
    g_out_dat_w => g_nof_dat
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => val_vec,
    out_dat => i_out_val_vec
  );
  
  u_out_sop_vec : ENTITY work.common_pipeline
  GENERIC MAP (
    g_pipeline  => g_pipeline,
    g_in_dat_w  => g_nof_dat,
    g_out_dat_w => g_nof_dat
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => sop_vec,
    out_dat => i_out_sop_vec
  );
  
  u_out_eop_vec : ENTITY work.common_pipeline
  GENERIC MAP (
    g_pipeline  => g_pipeline,
    g_in_dat_w  => g_nof_dat,
    g_out_dat_w => g_nof_dat
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => eop_vec,
    out_dat => i_out_eop_vec
  );
  
  u_out_cnt : ENTITY work.common_pipeline
  GENERIC MAP (
    g_pipeline  => g_pipeline,
    g_in_dat_w  => c_cnt_w,
    g_out_dat_w => c_cnt_w
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => in_cnt,
    out_dat => out_cnt
  );
  
END str;
