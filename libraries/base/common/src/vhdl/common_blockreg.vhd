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

-- Purpose: 
-- . 'Shift register' that shifts on block boundary instead of single
--    word boundary: If the register is full, it shifts out an entire
--    block.
-- Description: 
-- . A normal shift register cannot be used (instead of a FIFO) for 
--   this purpose, because those fill from left to right and shifting 
--   out the contents causes gaps to be shifted in.
-- Remarks:
-- . The output latency (in cycles) can be calculated as follows:
--   out_latency = block_size*rate_div - (in_block_size*rate_div - in_block_size) + 1
--   in which: 
--   . rate_div = rate divider, e.g. 4 when 1/4 of the input is valid.
--   . in_block_size = input block size.
--   . the '+1' is caused by 'nxt_' register latency; always there (not 
--     valid-dependent like the rest).

LIBRARY IEEE, technology_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;

ENTITY common_blockreg IS
  GENERIC (
    g_technology : t_technology := c_tech_select_default;
    g_block_size : NATURAL;
    g_dat_w      : NATURAL
  );
  PORT (
    rst          : IN  STD_LOGIC;
    clk          : IN  STD_LOGIC;
    
    in_dat       : IN  STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    in_val       : IN  STD_LOGIC;
    
    out_dat      : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    out_val      : OUT STD_LOGIC
  );
END common_blockreg;


ARCHITECTURE str OF common_blockreg IS

  SIGNAL i_out_val    : STD_LOGIC;

  SIGNAL usedw        : STD_LOGIC_VECTOR(ceil_log2(g_block_size+1)-1 DOWNTO 0);
  SIGNAL rd_req       : STD_LOGIC;
  SIGNAL prev_rd_req  : STD_LOGIC;

  SIGNAL out_cnt      : STD_LOGIC_VECTOR(ceil_log2(g_block_size)-1 DOWNTO 0);
  SIGNAL nxt_out_cnt  : STD_LOGIC_VECTOR(ceil_log2(g_block_size)-1 DOWNTO 0);

BEGIN

  gen_bypass: IF g_block_size=1 GENERATE
    out_dat <= in_dat;
    out_val <= in_val;
  END GENERATE;

  gen_block_out: IF g_block_size>1 GENERATE

    out_val <= i_out_val;
  
    u_fifo : ENTITY work.common_fifo_sc
    GENERIC MAP (
      g_technology  => g_technology,
      g_note_is_ful => FALSE,
      g_dat_w       => g_dat_w,
      g_nof_words   => g_block_size+1
    )
    PORT MAP (
      clk    => clk,
      rst    => rst,
  
      wr_dat => in_dat,
      wr_req => in_val,
  
      usedw  => usedw,
      rd_req => rd_req,
  
      rd_dat => out_dat,
      rd_val => i_out_val
    );
  
    -----------------------------------------------------------------------------
    -- Toggle rd_req to create output blocks of g_block_size
    -----------------------------------------------------------------------------
    p_block_out: PROCESS(in_val, prev_rd_req, out_cnt, usedw)
    BEGIN
      rd_req <= prev_rd_req;
      IF UNSIGNED(out_cnt)=g_block_size-1 THEN
        -- End of current output block
        IF UNSIGNED(usedw)<g_block_size THEN
          -- de-asserting rd_req will not cause FIFO to overflow
          rd_req <= '0';
        END IF;
      END IF;
      IF UNSIGNED(usedw)=g_block_size THEN
        -- Start of new output block
        rd_req <= '1';
      END IF;
    END PROCESS;
   
    -----------------------------------------------------------------------------
    -- Valid output word counter
    -----------------------------------------------------------------------------
    p_out_cnt : PROCESS(i_out_val, out_cnt)
    BEGIN
      nxt_out_cnt <= out_cnt;
      IF i_out_val='1' THEN
        nxt_out_cnt <= INCR_UVEC(out_cnt, 1);
        IF UNSIGNED(out_cnt)=g_block_size-1 THEN
          nxt_out_cnt <= (OTHERS=>'0');
        END IF;
      END IF;
    END PROCESS;
         
    -----------------------------------------------------------------------------
    -- Registers
    -----------------------------------------------------------------------------
    p_clk : PROCESS(rst, clk)
    BEGIN
      IF rst='1' THEN
         out_cnt     <= (OTHERS=>'0');
         prev_rd_req <= '0';
       ELSIF rising_edge(clk) THEN
         out_cnt     <= nxt_out_cnt;
         prev_rd_req <= rd_req;
      END IF;
    END PROCESS;

  END GENERATE;

END str;
