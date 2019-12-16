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

-- Purpose: Dual clock FIFO

LIBRARY IEEE, technology_lib, tech_fifo_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;

ENTITY common_fifo_dc IS
  GENERIC (
    g_technology        : t_technology := c_tech_select_default;
    g_note_is_ful       : BOOLEAN := TRUE;   -- when TRUE report NOTE when FIFO goes full, fifo overflow is always reported as FAILURE
    g_fail_rd_emp       : BOOLEAN := FALSE;  -- when TRUE report FAILURE when read from an empty FIFO
    g_use_lut           : BOOLEAN := FALSE;  -- when TRUE then force using LUTs via Altera eab="OFF",
                                             -- else use default eab="ON" and ram_block_type="AUTO", default ram_block_type="AUTO" is sufficient, because
                                             -- there seems no need to force using RAM and there are two types of Stratix IV RAM (M9K and M144K)
    g_prog_full_thresh  : INTEGER := 10;     -- Programmable full threshold level
    g_prog_empty_thresh : INTEGER := 10;     -- Programmable empty threshold level
    g_fifo_latency      : INTEGER := 1;      -- Read latency (0 = FWFT)
    g_dat_w             : NATURAL := 36;
    g_nof_words         : NATURAL := 256   -- 36 * 256 = 1 M9K
  );
  PORT (
    rst           : IN  STD_LOGIC;
    wr_clk        : IN  STD_LOGIC;
    wr_dat        : IN  STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    wr_req        : IN  STD_LOGIC;
    wr_ful        : OUT STD_LOGIC;
    wr_prog_ful   : OUT STD_LOGIC;                -- FIFO Programmable full
    wrusedw       : OUT STD_LOGIC_VECTOR(ceil_log2(g_nof_words)-1 DOWNTO 0);
    rd_clk        : IN  STD_LOGIC;
    rd_dat        : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    rd_req        : IN  STD_LOGIC;
    rd_emp        : OUT STD_LOGIC;
    rd_prog_emp   : OUT STD_LOGIC;                -- FIFO Programmable empty
    rdusedw       : OUT STD_LOGIC_VECTOR(ceil_log2(g_nof_words)-1 DOWNTO 0);
    rd_val        : OUT STD_LOGIC := '0'    
  );
END common_fifo_dc;


ARCHITECTURE str of common_fifo_dc IS

  CONSTANT c_use_eab          : STRING := sel_a_b(g_use_lut, "OFF", "ON");  -- when g_use_lut=TRUE then force using LUTs via Altera eab="OFF", else default to ram_block_type = "AUTO"

  CONSTANT c_nof_words  : NATURAL := 2**ceil_log2(g_nof_words);  -- ensure size is power of 2 for dual clock FIFO

  SIGNAL wr_rst  : STD_LOGIC;
  SIGNAL wr_init : STD_LOGIC;
  SIGNAL wr_en   : STD_LOGIC;
  SIGNAL rd_en   : STD_LOGIC;
  SIGNAL ful     : STD_LOGIC; 
  SIGNAL emp     : STD_LOGIC;
  
  SIGNAL nxt_rd_val : STD_LOGIC;

BEGIN

  -- Control logic copied from LOFAR common_fifo_dc(virtex4).vhd
  
  -- Need to make sure the reset lasts at least 3 cycles (see fifo_generator_ug175.pdf)
  -- Wait at least 4 cycles after reset release before allowing FIFO wr_en (see fifo_generator_ug175.pdf)
  
  -- Use common_areset to:
  -- . asynchronously detect rst even when the wr_clk is stopped
  -- . synchronize release of rst to wr_clk domain
  -- Using common_areset is equivalent to using common_async with same signal applied to rst and din.
  u_wr_rst : ENTITY work.common_areset
  GENERIC MAP (
    g_rst_level => '1',
    g_delay_len => 3
  )
  PORT MAP (
    in_rst    => rst,
    clk       => wr_clk,
    out_rst   => wr_rst
  );

  -- Delay wr_init to ensure that FIFO ful has gone low after reset release
  u_wr_init : ENTITY work.common_areset
  GENERIC MAP (
    g_rst_level => '1',
    g_delay_len => 4
  )
  PORT MAP (
    in_rst  => wr_rst,
    clk     => wr_clk,
    out_rst => wr_init   -- assume init has finished g_delay_len cycles after release of wr_rst
  );
  
  -- The FIFO under read and over write protection are kept enabled in the MegaWizard
  wr_en <= wr_req AND NOT wr_init;  -- check on NOT ful is not necessary when overflow_checking="ON" (Altera) or according to fifo_generator_ug175.pdf (Xilinx)
  rd_en <= rd_req;                  -- check on NOT emp is not necessary when underflow_checking="ON" (Altera)

  nxt_rd_val <= rd_req AND NOT emp;  -- check on NOT emp is necessary for rd_val

  wr_ful <= ful WHEN wr_init='0' ELSE '0';

  rd_emp <= emp;
  
  p_rd_clk : PROCESS(rd_clk)
  BEGIN
    IF rising_edge(rd_clk) THEN
      rd_val <= nxt_rd_val;
    END IF;
  END PROCESS;
  
  u_fifo : ENTITY tech_fifo_lib.tech_fifo_dc
  GENERIC MAP (
    g_technology        => g_technology,
    g_use_eab           => c_use_eab,
    g_prog_full_thresh  => g_prog_full_thresh,
    g_prog_empty_thresh => g_prog_empty_thresh,
    g_fifo_latency      => g_fifo_latency,
    g_dat_w             => g_dat_w,
    g_nof_words         => c_nof_words
  )
  PORT MAP (
    aclr    => wr_rst,   -- MegaWizard fifo_dc seems to use aclr synchronous with wr_clk
    data    => wr_dat,
    rdclk   => rd_clk,
    rdreq   => rd_en,
    wrclk   => wr_clk,
    wrreq   => wr_en,
    q       => rd_dat,
    prog_empty => rd_prog_emp,
    prog_full => wr_prog_ful,
    rdempty => emp,
    rdusedw => rdusedw,
    wrfull  => ful,
    wrusedw => wrusedw
  );
  
  proc_common_fifo_asserts("common_fifo_dc", g_note_is_ful, g_fail_rd_emp, wr_rst, wr_clk, ful, wr_en, rd_clk, emp, rd_en);
  
END str;
