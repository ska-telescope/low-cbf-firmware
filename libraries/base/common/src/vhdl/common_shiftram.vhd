--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------

-- Purpose:
-- . A RAM of which the output can be shifted in time relative to the input
-- Description:
-- . Valid data is continuously written from adddres 0..g_nof_words-1.
-- . The shift is introduced by manipulating the read address.
-- . The maximum shift value is g_nof_words-2 instead of g_nof_words-1, this
--   is due to the one word/cycle that is required between a write and a read
--   on the same address. Higher shift values than the maximum will be 
--   interpreted as the maximum value.
-- . data_out_shift will always indicate the shift as applied to the
--   corresponding data_out.
-- 
-- 
--    Cycle 0              Cycle 1             Cycle 2           Cycle 3       
--    =======      _       =======     _       =======           =======       
-- data_in      ->| |-->ram_wr_data-->| |                                      
-- data_in_val  ->| |-->ram_wr_addr-->| |                                      
-- data_in_shift->| |-->ram_wr_en---->|_|                                      
--                |_|-->ram_wr_shift   R                                       
--                r0                   _                   _                   
--                      ram_wr_addr-->| |-->ram_rd_en---->| |-->data_out       
--                      ram_wr_en---->| |-->ram_rd_addr-->|_|-->data_out_val   
--                      ram_wr_shift->| |                  R                   
--                                    | |                  _                   
--                                    |_|-->ram_rd_shift->|_|-->data_out_shift 
--                                    r1                  r2                   
--                                                                             
-- R      = RAM I/O                                                            
-- r0..r2 = register stages.                                                   

LIBRARY IEEE, common_lib, technology_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;

ENTITY common_shiftram IS
  GENERIC (
    g_technology  : t_technology := c_tech_select_default;
    g_data_w      : NATURAL;
    g_nof_words   : NATURAL; -- Depth of RAM. Must be a power of two.
    g_output_invalid_during_shift_incr : BOOLEAN := FALSE;
    g_fixed_shift : BOOLEAN := FALSE -- If data_in_shift is constant, set to TRUE
  );                                 -- for better timing results
  PORT (
    rst            : IN  STD_LOGIC;
    clk            : IN  STD_LOGIC;

    data_in        : IN  STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    data_in_val    : IN  STD_LOGIC;
    data_in_shift  : IN  STD_LOGIC_VECTOR(ceil_log2(g_nof_words-1)-1 DOWNTO 0);

    data_out       : OUT STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    data_out_val   : OUT STD_LOGIC;
    data_out_shift : OUT STD_LOGIC_VECTOR(ceil_log2(g_nof_words-1)-1 DOWNTO 0)
  );
END common_shiftram;


ARCHITECTURE rtl OF common_shiftram IS

  -- RAM constants
  CONSTANT c_ram_rl      : NATURAL := 1;
  CONSTANT c_ram_addr_w  : NATURAL := ceil_log2(g_nof_words);
  CONSTANT c_ram_data_w  : NATURAL := g_data_w;
  CONSTANT c_ram_nof_dat : NATURAL := g_nof_words;
  CONSTANT c_ram_init_sl : STD_LOGIC := '0';
  CONSTANT c_ram         : t_c_mem := (latency => c_ram_rl, 
                                       adr_w => c_ram_addr_w, 
                                       dat_w => c_ram_data_w, 
                                       nof_dat => c_ram_nof_dat, 
                                       addr_base => 0, 
                                       nof_slaves => 1,
                                       init_sl => c_ram_init_sl);

  SIGNAL ram_data_out     : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
  SIGNAL ram_data_out_val : STD_LOGIC;

  -- Register stage 0
  TYPE t_reg_0 IS RECORD
    ram_wr_data     : STD_LOGIC_VECTOR(c_ram_data_w-1 DOWNTO 0);
    ram_wr_addr     : STD_LOGIC_VECTOR(c_ram_addr_w-1 DOWNTO 0);
    ram_wr_en       : STD_LOGIC;
    ram_wr_shift    : STD_LOGIC_VECTOR(c_ram_addr_w-1 DOWNTO 0);
    ram_wr_shift_incr : BOOLEAN;
  END RECORD;

  CONSTANT c_reg_0_defaults : t_reg_0 := ( (OTHERS=>'0'),
                                           (OTHERS=>'0'),
                                           '0',
                                           (OTHERS=>'0'),
                                           FALSE);

  SIGNAL r0, nxt_r0 : t_reg_0 := c_reg_0_defaults;

  -- Register stage 1
  TYPE t_reg_1 IS RECORD
    ram_rd_addr     : STD_LOGIC_VECTOR(c_ram_addr_w-1 DOWNTO 0);
    ram_rd_en       : STD_LOGIC;
    ram_rd_shift    : STD_LOGIC_VECTOR(c_ram_addr_w-1 DOWNTO 0);
  END RECORD;

  CONSTANT c_reg_1_defaults : t_reg_1 := ( (OTHERS=>'0'),
                                           '0',
                                           (OTHERS=>'0'));

  SIGNAL r1, nxt_r1 : t_reg_1 := c_reg_1_defaults; 

  -- Register stage 2
  TYPE t_reg_2 IS RECORD
    data_out_shift    : STD_LOGIC_VECTOR(c_ram_addr_w-1 DOWNTO 0);
  END RECORD;

  CONSTANT c_reg_2_defaults : t_reg_2 :=  (OTHERS=>(OTHERS=>'0'));

  SIGNAL r2, nxt_r2 : t_reg_2 := c_reg_2_defaults; 

  -- Register stage 3 (optional)
  TYPE t_reg_3 IS RECORD
    data_out_shift    : STD_LOGIC_VECTOR(c_ram_addr_w-1 DOWNTO 0);
    data_out          : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    data_out_val      : STD_LOGIC;
  END RECORD;

  CONSTANT c_reg_3_defaults : t_reg_3 :=  ( (OTHERS=>'0'),
                                            (OTHERS=>'0'),
                                            '0');

  SIGNAL r3, nxt_r3 : t_reg_3 := c_reg_3_defaults; 

BEGIN

  -----------------------------------------------------------------------------
  -- Register stage 0
  -----------------------------------------------------------------------------
  r0 <= nxt_r0 WHEN rising_edge(clk);

  p_comb_0 : PROCESS(rst, r0, data_in, data_in_val, data_in_shift)
    VARIABLE v : t_reg_0;
    VARIABLE v_data_in_shift : STD_LOGIC_VECTOR(c_ram_addr_w-1 DOWNTO 0);
  BEGIN
    v := r0;

    v.ram_wr_data  := data_in;
    v.ram_wr_en    := data_in_val;

    IF data_in_val = '1' THEN
      -- Limit max shift to g_nof_words-2
        v_data_in_shift := data_in_shift;
  
      IF v_data_in_shift = TO_UVEC(g_nof_words-1, c_ram_addr_w) THEN
        v_data_in_shift := TO_UVEC(g_nof_words-2, c_ram_addr_w);
      END IF;
  
      IF r0.ram_wr_en = '1' THEN
        v.ram_wr_addr := INCR_UVEC(r0.ram_wr_addr, 1);
      END IF;      
  
      IF r0.ram_wr_shift_incr = TRUE THEN
        -- New shift value is more than one higher than previous shift
        v.ram_wr_shift := INCR_UVEC(r0.ram_wr_shift, 1);
      END IF;  
      IF TO_UINT(v_data_in_shift) < TO_UINT(v.ram_wr_shift) THEN
        -- User wants to lower the shift. Forward this request immediately
        v.ram_wr_shift := v_data_in_shift;
      END IF;
  
      -- Smooth out the shift input by the user so it does not increment by
      -- more than one at a time
      IF TO_UINT(v_data_in_shift) > TO_UINT(v.ram_wr_shift) THEN
        v.ram_wr_shift_incr := TRUE;
      ELSE
        v.ram_wr_shift_incr := FALSE;
      END IF;

    END IF;

    IF rst = '1' THEN
      v := c_reg_0_defaults;
    END IF;
 
    nxt_r0 <= v;
  END PROCESS;

  -----------------------------------------------------------------------------
  -- Register stage 1
  -----------------------------------------------------------------------------
  r1 <= nxt_r1 WHEN rising_edge(clk);

  p_comb_1 : PROCESS(rst, r1, r0)
    VARIABLE v : t_reg_1;
    VARIABLE v_shift_diff : INTEGER := 0;
  BEGIN
    v := r1;

    v.ram_rd_en    := r0.ram_wr_en;
    v.ram_rd_shift := r0.ram_wr_shift;

    IF r1.ram_rd_en = '1' THEN
      -- Read next address
      v.ram_rd_addr  := INCR_UVEC(r1.ram_rd_addr, 1);

      IF TO_UINT(r0.ram_wr_shift) > TO_UINT(r1.ram_rd_shift) THEN
        -- We need to shift by reading the same address again
        v.ram_rd_addr := r1.ram_rd_addr;
      END IF;

      IF g_fixed_shift=FALSE AND (TO_UINT(r0.ram_wr_shift) < TO_UINT(r1.ram_rd_shift)) THEN
        -- Apply shift decrease at instantaniously
        v_shift_diff := TO_UINT(r1.ram_rd_shift) - TO_UINT(r0.ram_wr_shift) +1;
        v.ram_rd_addr := INCR_UVEC(r1.ram_rd_addr, v_shift_diff);
      END IF;

    END IF;

    IF rst = '1' THEN
      v := c_reg_1_defaults;
    END IF;
 
    nxt_r1 <= v;
  END PROCESS;

  -----------------------------------------------------------------------------
  -- Register stage 2
  -----------------------------------------------------------------------------
  r2 <= nxt_r2 WHEN rising_edge(clk);

  p_comb_2 : PROCESS(rst, r2, r1)
    VARIABLE v : t_reg_2;
  BEGIN
    v := r2;

    v.data_out_shift := r1.ram_rd_shift;    

    IF rst = '1' THEN
      v := c_reg_2_defaults;
    END IF;
 
    nxt_r2 <= v;
  END PROCESS;

--  data_out_shift <= r2.data_out_shift;

  -----------------------------------------------------------------------------
  -- RAM
  -----------------------------------------------------------------------------
  u_common_ram_r_w: ENTITY common_lib.common_ram_r_w
  GENERIC MAP (
    g_technology => g_technology,
    g_ram       => c_ram,
    g_init_file => "UNUSED",
    g_true_dual_port => FALSE
  )
  PORT MAP (
    rst       => rst,
    clk       => clk,
    clken     => '1',
    wr_en     => r0.ram_wr_en,
    wr_adr    => r0.ram_wr_addr,
    wr_dat    => r0.ram_wr_data,
    rd_en     => r1.ram_rd_en,
    rd_adr    => r1.ram_rd_addr,
    rd_dat    => ram_data_out,
    rd_val    => ram_data_out_val
  );

  gen_outputs: IF g_output_invalid_during_shift_incr=FALSE GENERATE
    data_out_shift <= r2.data_out_shift;
    data_out       <= ram_data_out;
    data_out_val   <= ram_data_out_val;
  END GENERATE;

  -----------------------------------------------------------------------------
  -- Register stage 3 (optional)
  -----------------------------------------------------------------------------
  gen_output_invalid: IF g_output_invalid_during_shift_incr=TRUE GENERATE

    r3 <= nxt_r3 WHEN rising_edge(clk);
  
    p_comb_2 : PROCESS(rst, r2, r3, data_in_shift, ram_data_out, ram_data_out_val)
      VARIABLE v : t_reg_3;
    BEGIN
      v := r3;

      v.data_out_shift := r2.data_out_shift;   

      IF r2.data_out_shift = data_in_shift THEN
        v.data_out     := ram_data_out;
        v.data_out_val := ram_data_out_val;
      ELSE
        v.data_out     := (OTHERS=>'0');
        v.data_out_val := '0';
      END IF;

      IF rst = '1' THEN
        v := c_reg_3_defaults;
      END IF;
  
      nxt_r3 <= v;
    END PROCESS;
  
    data_out_shift <= r3.data_out_shift;
    data_out       <= r3.data_out;
    data_out_val   <= r3.data_out_val;

  END GENERATE;

END rtl;
