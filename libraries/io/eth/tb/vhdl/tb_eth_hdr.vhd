-------------------------------------------------------------------------------
--
-- Copyright (C) 2010
-- ASTRON (Netherlands Institute for Radio Astronomy) <http://www.astron.nl/>
-- JIVE (Joint Institute for VLBI in Europe) <http://www.jive.nl/>
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

-- Purpose: Testbench for eth_hdr
-- Description:
--   Stimuli and tb_end based on proc_dp_count_en() state machine in tb_dp_pkg.vhd
--   Verification by proc_dp_verify_*().
-- Usage:
--   > as 10
--   > run -all

LIBRARY IEEE, common_lib, dp_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE dp_lib.dp_stream_pkg.ALL;
USE dp_lib.tb_dp_pkg.ALL;
USE work.eth_pkg.ALL;

ENTITY tb_eth_hdr IS
END tb_eth_hdr;


ARCHITECTURE tb OF tb_eth_hdr IS

  -- DUT ready latency
  CONSTANT c_dut_latency    : NATURAL := 1;              -- fixed 1 for eth_hdr
  CONSTANT c_tx_latency     : NATURAL := c_dut_latency;  -- TX ready latency of TB
  CONSTANT c_tx_void        : NATURAL := sel_a_b(c_tx_latency, 1, 0);  -- used to avoid empty range VHDL warnings when c_tx_latency=0
  CONSTANT c_tx_offset_sop  : NATURAL := 0;
  CONSTANT c_tx_period_sop  : NATURAL := 30;
  CONSTANT c_tx_offset_eop  : NATURAL := c_tx_period_sop-1;
  CONSTANT c_tx_period_eop  : NATURAL := c_tx_period_sop;
  CONSTANT c_rx_latency     : NATURAL := c_dut_latency;  -- RX ready latency from DUT
  CONSTANT c_verify_en_wait : NATURAL := 16;             -- wait some cycles before asserting verify enable
  
  CONSTANT c_random_w       : NATURAL := 19;
  
  SIGNAL tb_end         : STD_LOGIC := '0';
  SIGNAL clk            : STD_LOGIC := '0';
  SIGNAL rst            : STD_LOGIC;
  SIGNAL sync           : STD_LOGIC;
  SIGNAL lfsr1          : STD_LOGIC_VECTOR(c_random_w-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL lfsr2          : STD_LOGIC_VECTOR(c_random_w   DOWNTO 0) := (OTHERS=>'0');
  
  SIGNAL cnt_dat        : STD_LOGIC_VECTOR(c_dp_data_w-1 DOWNTO 0);
  SIGNAL cnt_val        : STD_LOGIC;
  SIGNAL cnt_en         : STD_LOGIC;
  
  SIGNAL tx_data        : t_dp_data_arr(0 TO c_tx_latency + c_tx_void)    := (OTHERS=>(OTHERS=>'0'));
  SIGNAL tx_val         : STD_LOGIC_VECTOR(0 TO c_tx_latency + c_tx_void) := (OTHERS=>'0');
  
  SIGNAL in_ready       : STD_LOGIC;
  SIGNAL in_data        : STD_LOGIC_VECTOR(c_dp_data_w-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL in_val         : STD_LOGIC;
  SIGNAL in_sop         : STD_LOGIC;
  SIGNAL in_eop         : STD_LOGIC;
  
  SIGNAL out_ready      : STD_LOGIC;
  SIGNAL prev_out_ready : STD_LOGIC_VECTOR(0 TO c_rx_latency);
  SIGNAL out_data       : STD_LOGIC_VECTOR(c_dp_data_w-1 DOWNTO 0);
  SIGNAL out_val        : STD_LOGIC;
  SIGNAL out_sop        : STD_LOGIC;
  SIGNAL out_eop        : STD_LOGIC;
  SIGNAL prev_out_data  : STD_LOGIC_VECTOR(out_data'RANGE);
  
  SIGNAL state          : t_dp_state_enum;
  
  SIGNAL verify_en      : STD_LOGIC;
  SIGNAL verify_done    : STD_LOGIC;
  
  SIGNAL exp_data       : STD_LOGIC_VECTOR(c_dp_data_w-1 DOWNTO 0) := TO_UVEC(1000, c_dp_data_w);

  SIGNAL snk_in         : t_dp_sosi;
  SIGNAL snk_out        : t_dp_siso;
  
  SIGNAL src_in         : t_dp_siso;
  SIGNAL src_out        : t_dp_sosi;

BEGIN

  clk <= NOT clk OR tb_end AFTER clk_period/2;
  rst <= '1', '0' AFTER clk_period*7;
  
  -- Sync interval
  proc_dp_sync_interval(clk, sync);
  
  -- Input data
  cnt_val <= in_ready AND cnt_en;
  
  proc_dp_cnt_dat(rst, clk, cnt_val, cnt_dat);
  proc_dp_tx_data(c_tx_latency, rst, clk, cnt_val, cnt_dat, tx_data, tx_val, in_data, in_val);
  proc_dp_tx_ctrl(c_tx_offset_sop, c_tx_period_sop, in_data, in_val, in_sop);
  proc_dp_tx_ctrl(c_tx_offset_eop, c_tx_period_eop, in_data, in_val, in_eop);

  -- Stimuli control
  proc_dp_count_en(rst, clk, sync, lfsr1, state, verify_done, tb_end, cnt_en);
  proc_dp_out_ready(rst, clk, sync, lfsr2, out_ready);
  
  -- Output verify
  proc_dp_verify_en(c_verify_en_wait, rst, clk, sync, verify_en);
  proc_dp_verify_data("src_out.data", c_rx_latency, clk, verify_en, out_ready, out_val, out_data, prev_out_data);
  proc_dp_verify_valid(c_rx_latency, clk, verify_en, out_ready, prev_out_ready, out_val);
  proc_dp_verify_ctrl(c_tx_offset_sop, c_tx_period_sop, "sop", clk, verify_en, out_data, out_val, out_sop);
  proc_dp_verify_ctrl(c_tx_offset_eop, c_tx_period_eop, "eop", clk, verify_en, out_data, out_val, out_eop);
  
  -- Check that the test has ran at all
  proc_dp_verify_value(e_at_least, clk, verify_done, exp_data, out_data);
    
  ------------------------------------------------------------------------------
  -- DUT eth_hdr
  ------------------------------------------------------------------------------
  
  -- Interface TB tx - DUT sink
  in_ready     <= snk_out.ready;
  snk_in.data  <= RESIZE_DP_DATA(in_data);
  snk_in.valid <= in_val;
  snk_in.sop   <= in_sop;
  snk_in.eop   <= in_eop;
  snk_in.empty <= (OTHERS=>'0');  -- not used
  
  -- Interface DUT source - TB rx
  src_in.ready <= out_ready;
  out_data     <= src_out.data(c_dp_data_w-1 DOWNTO 0);
  out_val      <= src_out.valid;
  out_sop      <= src_out.sop;
  out_eop      <= src_out.eop;
  
  -- Note there is no need to disable the ip_hdr_checksum replacement, because the change that this test bench
  -- generates a IP packet is very small.
  dut : ENTITY work.eth_hdr
  PORT MAP (
    rst         => rst,
    clk         => clk,

    -- Streaming Sink
    snk_in      => snk_in,
    snk_out     => snk_out,
    
    -- Streaming Source
    src_in      => src_in,
    src_out     => src_out
  );
  
END tb;
