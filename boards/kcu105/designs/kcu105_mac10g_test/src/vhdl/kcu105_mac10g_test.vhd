-------------------------------------------------------------------------------
--
-- Copyright (C) 2017
-- ASTRON (Netherlands Institute for Radio Astronomy) <http:--www.astron.nl/>
-- JIVE (Joint Institute for VLBI in Europe) <http:--www.jive.nl/>
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
-- along with this program.  If not, see <http:--www.gnu.org/licenses/>.
--
-------------------------------------------------------------------------------

LIBRARY IEEE, UNISIM, common_lib, kcu105_board_lib, technology_lib, tech_mac_10g_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE kcu105_board_lib.kcu105_board_pkg.ALL;
USE tech_mac_10g_lib.tech_mac_10g_component_pkg.ALL;
USE UNISIM.vcomponents.all;



ENTITY kcu105_mac10g_test IS
  GENERIC (
    g_design_name   : STRING  := "kcu105_mac10g_test";
    g_design_note   : STRING  := "UNUSED";
    g_technology    : t_technology := c_tech_xcku040;
    g_sim           : BOOLEAN := FALSE; --Overridden by TB
    g_sim_unb_nr    : NATURAL := 0;
    g_sim_node_nr   : NATURAL := 0;
    g_stamp_date    : NATURAL := 0;  -- Date (YYYYMMDD)
    g_stamp_time    : NATURAL := 0;  -- Time (HHMMSS)
    g_stamp_svn     : NATURAL := 0;  -- SVN revision
    g_factory_image : BOOLEAN := TRUE;
    PKT_NUM         : NATURAL := 1  -- Many Internal Counters are based on PKT_NUM = 20
  );
  PORT (
    gt_rxp_in  : in std_logic;
    gt_rxn_in  : in std_logic;
    gt_txp_out : out std_logic;
    gt_txn_out : out std_logic;

    restart_tx_rx_0     : in  std_logic;
    rx_gt_locked_led_0  : out std_logic; -- Indicates GT LOCK
    rx_block_lock_led_0 : out std_logic; -- Indicates Core Block Lock
    completion_status   : out std_logic_vector(4 downto 0);

    sys_reset   : in std_logic;
    gt_refclk_p : in std_logic;  -- 156.25 MHz
    gt_refclk_n : in std_logic;
    dclk_p      : in std_logic;  -- 125 MHz
    dclk_n      : in std_logic
  );
END kcu105_mac10g_test;

ARCHITECTURE str OF kcu105_mac10g_test IS

  -- Firmware version x.y
  CONSTANT c_fw_version         : t_kcu105_board_fw_version := (1, 1);
  CONSTANT c_reset_len          : NATURAL := 4;  -- >= c_meta_delay_len from common_pkg
  CONSTANT c_mm_clk_freq        : NATURAL := c_kcu105_board_mm_clk_freq_125M;


  SIGNAL  dclk : STD_LOGIC;

  SIGNAL rx_core_clk : STD_LOGIC;
  SIGNAL tx_clk_out : STD_LOGIC;
  SIGNAL rx_clk_out : STD_LOGIC;

    -- RX Signals  
  SIGNAL  user_rx_reset : STD_LOGIC;
  SIGNAL  rx_axis_tvalid : STD_LOGIC;
  SIGNAL  rx_axis_tdata : STD_LOGIC_VECTOR(63 DOWNTO 0);
  SIGNAL  rx_axis_tlast : STD_LOGIC;
  SIGNAL  rx_axis_tkeep : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL  rx_axis_tuser : STD_LOGIC;
  SIGNAL  rx_preambleout : STD_LOGIC_VECTOR(55 DOWNTO 0);

    -- RX Stats Signals
  SIGNAL  stat_rx_block_lock : STD_LOGIC;

    -- TX Signals
  SIGNAL  user_tx_reset : STD_LOGIC;


    -- TX LBUS Signals
  SIGNAL  tx_axis_tready : STD_LOGIC;
  SIGNAL  tx_axis_tvalid : STD_LOGIC;
  SIGNAL  tx_axis_tdata : STD_LOGIC_VECTOR(63 DOWNTO 0);
  SIGNAL  tx_axis_tlast : STD_LOGIC;
  SIGNAL  tx_axis_tkeep : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL  tx_axis_tuser : STD_LOGIC;
  SIGNAL  tx_unfout : STD_LOGIC;
  SIGNAL  tx_preamblein : STD_LOGIC_VECTOR(55 DOWNTO 0);

  SIGNAL  completion_status_0 : STD_LOGIC_VECTOR(4 DOWNTO 0);


  component ip_xcku040_mac10g_noaxi_pkt_gen_mon is
    GENERIC (
      PKT_NUM : NATURAL
    );
    port (
      gen_clk : IN STD_LOGIC;
      mon_clk : IN STD_LOGIC;
      dclk : IN STD_LOGIC;
      sys_reset : IN STD_LOGIC;
      restart_tx_rx : IN STD_LOGIC;
  
    -- RX Signals
      user_rx_reset : IN STD_LOGIC;
    -- RX LBUS Signals
      rx_axis_tvalid : IN STD_LOGIC;
      rx_axis_tdata : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      rx_axis_tlast : IN STD_LOGIC;
      rx_axis_tkeep : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      rx_axis_tuser : IN STD_LOGIC;
      rx_preambleout : IN STD_LOGIC_VECTOR(55 DOWNTO 0);
  
    -- RX Stats Signals
      stat_rx_block_lock : IN STD_LOGIC;
  
    -- TX Signals
      user_tx_reset : IN STD_LOGIC;
  
    -- TX LBUS Signals
      tx_axis_tready : IN STD_LOGIC;
      tx_axis_tvalid : OUT STD_LOGIC;
      tx_axis_tdata : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      tx_axis_tlast : OUT STD_LOGIC;
      tx_axis_tkeep : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      tx_axis_tuser : OUT STD_LOGIC;
      tx_unfout : IN STD_LOGIC;
      tx_preamblein : OUT STD_LOGIC_VECTOR(55 DOWNTO 0);
  
      completion_status : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
      rx_gt_locked_led : OUT STD_LOGIC;
      rx_block_lock_led : OUT STD_LOGIC
  );
  end component ip_xcku040_mac10g_noaxi_pkt_gen_mon; 



BEGIN
  completion_status <= completion_status_0;

  u_IBUFDS_dclk_inst : IBUFDS
   PORT MAP (
    O => dclk,
    I => dclk_p,
    IB=> dclk_n
  );

  u_tech_mac_10g : ENTITY tech_mac_10g_lib.tech_mac_10g
  GENERIC MAP (
    g_technology => g_technology
  )
  PORT MAP (
    gt_rxp_in  =>gt_rxp_in,
    gt_rxn_in  =>gt_rxn_in,
    gt_txp_out =>gt_txp_out,
    gt_txn_out =>gt_txn_out,


    tx_clk_out => tx_clk_out,
    rx_core_clk => rx_core_clk,
    rx_clk_out => rx_clk_out,

    gt_refclk_p =>gt_refclk_p,
    gt_refclk_n =>gt_refclk_n,

    sys_reset =>sys_reset,
    dclk =>dclk,

    -- RX Signals
    user_rx_reset  =>user_rx_reset,
    rx_axis_tvalid =>rx_axis_tvalid,
    rx_axis_tdata  =>rx_axis_tdata,
    rx_axis_tlast  =>rx_axis_tlast,
    rx_axis_tkeep  =>rx_axis_tkeep,
    rx_axis_tuser  =>rx_axis_tuser,
    rx_preambleout =>rx_preambleout,

    -- RX Stats Signals
    stat_rx_block_lock =>stat_rx_block_lock,

    -- TX Signals,    
    user_tx_reset => user_tx_reset,

    -- TX LBUS Signals,
    tx_axis_tready =>tx_axis_tready,
    tx_axis_tvalid =>tx_axis_tvalid,
    tx_axis_tdata =>tx_axis_tdata,
    tx_axis_tlast =>tx_axis_tlast,
    tx_axis_tkeep =>tx_axis_tkeep,
    tx_axis_tuser =>tx_axis_tuser,
    tx_unfout => tx_unfout,
    tx_preamblein => tx_preamblein
  );



  u_ip_xcku040_mac10g_noaxi_pkt_gen_mon : ip_xcku040_mac10g_noaxi_pkt_gen_mon
  GENERIC MAP (
    PKT_NUM => PKT_NUM
  )
  PORT MAP (
    gen_clk => tx_clk_out,
    mon_clk => rx_core_clk,
    dclk => dclk,
    sys_reset => sys_reset,
  -- User Interface signals
    completion_status => completion_status_0,
    restart_tx_rx => restart_tx_rx_0,
  -- RX Signals
    user_rx_reset=> user_rx_reset,
    rx_axis_tvalid => rx_axis_tvalid,
    rx_axis_tdata => rx_axis_tdata,
    rx_axis_tlast => rx_axis_tlast,
    rx_axis_tkeep => rx_axis_tkeep,
    rx_axis_tuser => rx_axis_tuser,
    rx_preambleout => rx_preambleout,

  -- RX Stats Signals
    stat_rx_block_lock => stat_rx_block_lock,
    user_tx_reset => user_tx_reset,
  -- TX LBUS Signals
    tx_axis_tready => tx_axis_tready,
    tx_axis_tvalid => tx_axis_tvalid,
    tx_axis_tdata => tx_axis_tdata,
    tx_axis_tlast => tx_axis_tlast,
    tx_axis_tkeep => tx_axis_tkeep,
    tx_axis_tuser => tx_axis_tuser,
    tx_unfout => tx_unfout,
    tx_preamblein => tx_preamblein,

    rx_gt_locked_led => rx_gt_locked_led_0,
    rx_block_lock_led => rx_block_lock_led_0
    );

END str;

