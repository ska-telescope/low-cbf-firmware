LIBRARY IEEE, technology_lib, common_lib, axi4_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE work.tech_mac_10g_component_pkg.ALL;
USE work.tech_mac_10g_pkg.ALL;

ENTITY tech_mac_10g IS
   GENERIC (
      g_technology            : t_technology;
      g_device                : t_locations_10g;
      g_txpostcursor          : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00000";   -- No post emphasis
      g_txmaincursor          : STD_LOGIC_VECTOR(6 DOWNTO 0) := "1010000";
      g_txprecursor           : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00000";   -- 0.1dB pre emphasis
      g_txdiffctrl            : STD_LOGIC_VECTOR(4 DOWNTO 0) := "11000";   -- 950mVpp
      g_txpolarity            : STD_LOGIC := '0';
      g_rxpolarity            : STD_LOGIC := '0';
      g_rxlpmen               : STD_LOGIC := '0';                          -- DFE
      g_min_length            : INTEGER := 64;
      g_max_length            : INTEGER := 8000;                           -- Max packet (MTU)
      g_error_passing         : BOOLEAN := TRUE);                          -- Enable RX to TX error passing (for duplex links only)
   PORT (
      gt_rxp_in               : IN STD_LOGIC;
      gt_rxn_in               : IN STD_LOGIC;
      gt_txp_out              : OUT STD_LOGIC;
      gt_txn_out              : OUT STD_LOGIC;

      gt_refclk_p             : IN STD_LOGIC;
      gt_refclk_n             : IN STD_LOGIC;

      sys_reset               : IN STD_LOGIC;
      dclk                    : IN STD_LOGIC;

      tx_clk_out              : OUT STD_LOGIC;
      rx_clk_in               : IN STD_LOGIC;
      rx_clk_out              : OUT STD_LOGIC;

      -- User Interface Signals
      eth_in_sosi             : OUT t_axi4_sosi;
      eth_in_siso             : IN t_axi4_siso;

      eth_out_sosi            : IN t_axi4_sosi;
      eth_out_siso            : OUT t_axi4_siso;

      user_rx_reset           : OUT STD_LOGIC;
      user_tx_reset           : OUT STD_LOGIC;

      eth_locked              : OUT STD_LOGIC;

      -- Statistics Interface
      stat_rx_total_bytes     : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);    -- Number of bytes received
      stat_rx_total_packets   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);    -- Total RX packets
      stat_rx_bad_fcs         : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);    -- Bad checksums
      stat_rx_user_pause      : OUT STD_LOGIC;                       -- Good Priority Pause
      stat_rx_vlan            : OUT STD_LOGIC;                       -- Good Vlan tagged packets
      stat_rx_oversize        : OUT STD_LOGIC;                       -- Larger than max MTU
      stat_rx_packet_small    : OUT STD_LOGIC;                       -- Runt packets
      stat_rx_bad_code        : OUT STD_LOGIC;                       -- Bad 64/66 code

      stat_tx_total_bytes     : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);    -- Number of bytes transmitted
      stat_tx_total_packets   : OUT STD_LOGIC;                       -- Total TX packets
      stat_tx_packet_small    : OUT STD_LOGIC;                       -- Runt packets
      stat_tx_packet_large    : OUT STD_LOGIC;                       -- Larger than max MTU

      -- Pause
      local_mac            : IN STD_LOGIC_VECTOR(47 DOWNTO 0);       -- Needed in case PAUSE packets are unicast
      ctl_rx_pause_ack     : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
      ctl_rx_pause_enable  : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
      stat_rx_pause_req    : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
      -- debug
      dbg_rx_block_lock  : out std_logic;
      dbg_rx_remote_fault : out std_logic;
      dbg_loopback : in std_logic_vector(2 downto 0)
      );
END tech_mac_10g;

ARCHITECTURE str OF tech_mac_10g IS

   CONSTANT c_min_length               : STD_LOGIC_VECTOR(7 DOWNTO 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(g_min_length, 8));
   CONSTANT c_max_length               : STD_LOGIC_VECTOR(14 DOWNTO 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(g_max_length, 15));

   SIGNAL gnd                          : STD_LOGIC_VECTOR(79 DOWNTO 0);
   SIGNAL ctl_tx_send_idle             : STD_LOGIC;
   SIGNAL ctl_tx_send_rfi              : STD_LOGIC;
   SIGNAL ctl_tx_send_lfi              : STD_LOGIC;
   SIGNAL stat_rx_block_lock           : STD_LOGIC;
   SIGNAL stat_rx_received_local_fault : STD_LOGIC;
   SIGNAL stat_rx_internal_local_fault : STD_LOGIC;
   SIGNAL stat_rx_remote_fault         : STD_LOGIC;

BEGIN

   gnd <= (OTHERS => '0');

   eth_locked <= stat_rx_block_lock AND NOT stat_rx_remote_fault;

   dbg_rx_block_lock <= stat_rx_block_lock;
   dbg_rx_remote_fault <= stat_rx_remote_fault;

   ctl_tx_send_idle <= stat_rx_received_local_fault WHEN g_error_passing = TRUE ELSE '0';    -- Send idles if we detect remote error
   ctl_tx_send_rfi <= NOT stat_rx_block_lock WHEN g_error_passing = TRUE ELSE '0';           -- Send remote error until we are locked locally
   ctl_tx_send_lfi <= stat_rx_internal_local_fault WHEN g_error_passing = TRUE ELSE '0';     -- Send local error if something breaks here

   gen_ip_gemini_lru: IF tech_is_board(g_technology, c_tech_board_gemini_lru) GENERATE

      quad120_3: mac_10g_120_3
      PORT MAP (
         gt_rxp_in_0 => gt_rxp_in, gt_rxn_in_0 => gt_rxn_in,
         gt_txp_out_0 => gt_txp_out, gt_txn_out_0 => gt_txn_out,
         gt_refclk_p => gt_refclk_p, gt_refclk_n => gt_refclk_n,
         rx_core_clk_0 => rx_clk_in, txoutclksel_in_0 => "101", rxoutclksel_in_0 => "101",
         tx_clk_out_0 => tx_clk_out, rx_clk_out_0 => rx_clk_out,

         tx_reset_0 => sys_reset, sys_reset => sys_reset, rx_reset_0 => sys_reset,
         gt_loopback_in_0 => "000",

         gt_dmonitorout_0 => OPEN, gt_eyescandataerror_0 => OPEN, gt_eyescanreset_0 => '0',
         gt_eyescantrigger_0 => '0', gt_pcsrsvdin_0 => X"0000", gt_rxbufreset_0 => '0',
         gt_rxbufstatus_0 => OPEN, gt_rxcdrhold_0 => '0', gt_rxcommadeten_0 => '0',

         gt_rxdfeagchold_0 => '0', gt_rxdfelpmreset_0 => '0', gt_rxlatclk_0 => dclk,
         gt_rxlpmen_0 => g_rxlpmen, gt_rxpcsreset_0 => '0', gt_rxpmareset_0 => '0',
         gt_rxprbscntreset_0 => '0', gt_rxprbserr_0 => OPEN, gt_rxprbssel_0 => X"0",
         gt_rxrate_0 => "000", gt_rxslide_in_0 => '0', gt_rxstartofseq_0 => open,
         gt_txbufstatus_0 => open, gt_txinhibit_0 => '0', gt_txlatclk_0 => dclk,

         gt_txdiffctrl_0 => g_txdiffctrl, gt_txmaincursor_0 => g_txmaincursor, gt_txpostcursor_0 => g_txpostcursor,
         gt_txprecursor_0 => g_txprecursor, gt_rxpolarity_0 => g_rxpolarity, gt_txpolarity_0 => g_txpolarity,

         gt_refclk_out => open, gtpowergood_out_0 => open,
         gt_txpcsreset_0 => '0', gt_txpmareset_0 => '0', gt_txprbsforceerr_0 => '0',
         gt_txprbssel_0 => "0000", gtwiz_reset_tx_datapath_0 => '0',
         gtwiz_reset_rx_datapath_0 => '0', rxrecclkout_0 => open,

         -- DRP
         dclk => dclk,
         gt_drpclk_0 => dclk, gt_drpdo_0 => open, gt_drprdy_0 => open,
         gt_drpen_0 => '0', gt_drpwe_0 => '0', gt_drpaddr_0 => "0000000000",
         gt_drpdi_0 => X"0000",

         -- AXI RX
         user_rx_reset_0 => user_rx_reset, rx_axis_tvalid_0 => eth_in_sosi.tvalid,
         rx_axis_tdata_0 => eth_in_sosi.tdata(63 DOWNTO 0), rx_axis_tlast_0 => eth_in_sosi.tlast,
         rx_axis_tkeep_0 => eth_in_sosi.tkeep(7 DOWNTO 0), rx_axis_tuser_0 => eth_in_sosi.tuser(0),

         -- RX Control
         ctl_rx_enable_0 => '1', ctl_rx_check_preamble_0 => '1', ctl_rx_check_sfd_0 => '1',
         ctl_rx_force_resync_0 => '0', ctl_rx_delete_fcs_0 => '1', ctl_rx_ignore_fcs_0 => '0',
         ctl_rx_max_packet_len_0 => c_max_length, ctl_rx_min_packet_len_0 => c_min_length,
         ctl_rx_process_lfi_0 => '1', ctl_rx_test_pattern_0 => '0' ,
         ctl_rx_data_pattern_select_0 => '0', ctl_rx_test_pattern_enable_0 => '0',
         ctl_rx_custom_preamble_enable_0 => '0', ctl_rx_forward_control_0 => '0',

         -- PAUSE Common Info
         ctl_rx_pause_da_mcast_0 => X"0180C2000001", ctl_rx_pause_da_ucast_0 => local_mac,
         ctl_rx_etype_pcp_0 => X"8808", ctl_rx_etype_ppp_0 => X"8808",
         ctl_rx_opcode_min_pcp_0 => X"0101", ctl_rx_opcode_max_pcp_0 => X"0101", ctl_rx_opcode_ppp_0 => X"0101",
         ctl_rx_pause_sa_0 => gnd(47 DOWNTO 0),
         ctl_rx_etype_gcp_0 => X"8808", ctl_rx_etype_gpp_0 => X"8808",
         ctl_rx_opcode_min_gcp_0 => X"0001", ctl_rx_opcode_max_gcp_0 => X"0006", ctl_rx_opcode_gpp_0 => X"0001",

         -- PAUSE Priority Control (802.1qbb)
         ctl_rx_enable_pcp_0 => '1', ctl_rx_enable_ppp_0 => '1',
         ctl_rx_check_mcast_pcp_0 => '1', ctl_rx_check_mcast_ppp_0 => '1',
         ctl_rx_check_ucast_pcp_0 => '1', ctl_rx_check_ucast_ppp_0 => '1',
         ctl_rx_check_sa_pcp_0 => '0',  ctl_rx_check_sa_ppp_0 => '0',
         ctl_rx_check_etype_pcp_0 => '1', ctl_rx_check_etype_ppp_0 =>'1' ,
         ctl_rx_check_opcode_pcp_0 => '1', ctl_rx_check_opcode_ppp_0 => '1',

         -- PAUSE Global Control (Only 802.1qbb supported)
         ctl_rx_enable_gcp_0 => '0', ctl_rx_enable_gpp_0 => '0',
         ctl_rx_check_mcast_gcp_0 => '1', ctl_rx_check_mcast_gpp_0 => '1',
         ctl_rx_check_ucast_gcp_0 => '1', ctl_rx_check_ucast_gpp_0 => '1',
         ctl_rx_check_sa_gcp_0 => '0', ctl_rx_check_sa_gpp_0 => '0',
         ctl_rx_check_etype_gcp_0 => '1', ctl_rx_check_etype_gpp_0 => '1',
         ctl_rx_check_opcode_gcp_0 => '1', ctl_rx_check_opcode_gpp_0 => '1',

         ctl_rx_check_ack_0 => '1', ctl_rx_pause_enable_0 => ctl_rx_pause_enable,
         ctl_rx_pause_ack_0 => ctl_rx_pause_ack, stat_rx_pause_req_0 => stat_rx_pause_req,

         stat_rx_pause_valid_0 => open, stat_rx_pause_quanta0_0 => open, stat_rx_pause_quanta1_0 => open,
         stat_rx_pause_quanta2_0 => open, stat_rx_pause_quanta3_0 => open, stat_rx_pause_quanta4_0 => open,
         stat_rx_pause_quanta5_0 => open, stat_rx_pause_quanta6_0 => open, stat_rx_pause_quanta7_0 => open,
         stat_rx_pause_quanta8_0 => open,

         -- Error Handling
         stat_rx_block_lock_0 => stat_rx_block_lock, stat_rx_remote_fault_0 => stat_rx_remote_fault,
         stat_rx_received_local_fault_0 => stat_rx_received_local_fault,
         stat_rx_internal_local_fault_0 => stat_rx_internal_local_fault,

         -- Statistics
         stat_rx_bad_fcs_0 => stat_rx_bad_fcs, stat_rx_oversize_0 => stat_rx_oversize,
         stat_rx_total_bytes_0 => stat_rx_total_bytes, stat_rx_total_packets_0 => stat_rx_total_packets,
         stat_rx_vlan_0 => stat_rx_vlan, stat_rx_packet_small_0 => stat_rx_packet_small,
         stat_rx_user_pause_0 => stat_rx_user_pause, stat_rx_bad_code_0 => stat_rx_bad_code,

         stat_rx_pause_0 => open,  stat_rx_valid_ctrl_code_0 => open,
         stat_rx_framing_err_0 => open, stat_rx_framing_err_valid_0 => open, stat_rx_local_fault_0 => open,
         stat_rx_status_0 => open, stat_rx_got_signal_os_0 => open, stat_rx_bad_preamble_0 => open,
         stat_rx_stomped_fcs_0 => open, stat_rx_truncated_0 => open, stat_rx_hi_ber_0 => open,
         stat_rx_test_pattern_mismatch_0 => open, stat_rx_inrangeerr_0 => open, stat_rx_jabber_0 => open,
         stat_rx_total_good_bytes_0 => open, stat_rx_total_good_packets_0 => open, stat_rx_packet_bad_fcs_0 => open,
         stat_rx_packet_64_bytes_0 => open, stat_rx_packet_65_127_bytes_0 => open, stat_rx_packet_128_255_bytes_0 => open,
         stat_rx_packet_256_511_bytes_0 => open, stat_rx_packet_512_1023_bytes_0 => open,
         stat_rx_packet_1024_1518_bytes_0 => open, stat_rx_packet_1519_1522_bytes_0 => open,
         stat_rx_packet_1523_1548_bytes_0 => open, stat_rx_packet_1549_2047_bytes_0 => open,
         stat_rx_packet_2048_4095_bytes_0 => open, stat_rx_packet_4096_8191_bytes_0 => open,
         stat_rx_packet_8192_9215_bytes_0 => open,  stat_rx_packet_large_0 => open,
         stat_rx_unicast_0 => open, stat_rx_multicast_0 => open, stat_rx_broadcast_0 => open, stat_rx_bad_sfd_0 => open,
         stat_rx_toolong_0 => open, stat_rx_undersize_0 => open, stat_rx_fragment_0 => open,

         stat_tx_packet_large_0 => stat_tx_packet_large, stat_tx_packet_small_0 => stat_tx_packet_small,
         stat_tx_total_bytes_0 => stat_tx_total_bytes, stat_tx_total_packets_0 => stat_tx_total_packets,

         stat_tx_local_fault_0 => open, stat_tx_user_pause_0 => open,
         stat_tx_total_good_bytes_0 => open, stat_tx_total_good_packets_0 => open, stat_tx_bad_fcs_0 => open,
         stat_tx_packet_64_bytes_0 => open, stat_tx_packet_65_127_bytes_0 => open, stat_tx_packet_128_255_bytes_0 => open,
         stat_tx_packet_256_511_bytes_0 => open, stat_tx_packet_512_1023_bytes_0 => open,
         stat_tx_packet_1024_1518_bytes_0 => open, stat_tx_packet_1519_1522_bytes_0 => open,
         stat_tx_packet_1523_1548_bytes_0 => open, stat_tx_packet_1549_2047_bytes_0 => open,
         stat_tx_packet_2048_4095_bytes_0 => open, stat_tx_packet_4096_8191_bytes_0 => open,
         stat_tx_packet_8192_9215_bytes_0 => open, stat_tx_pause_valid_0 => open,
         stat_tx_unicast_0 => open, stat_tx_multicast_0 => open, stat_tx_broadcast_0 => open,
         stat_tx_vlan_0 => open, stat_tx_frame_error_0 => open, stat_tx_pause_0 => open,

         -- PTP
         stat_tx_ptp_fifo_read_error_0 => open, stat_tx_ptp_fifo_write_error_0 => open,
         tx_ptp_1588op_in_0 => "00", tx_ptp_tag_field_in_0 => X"0000",
         tx_ptp_tstamp_valid_out_0 => open, rx_ptp_tstamp_valid_out_0 => open,
         tx_ptp_tstamp_tag_out_0 => open, tx_ptp_tstamp_out_0 => open, rx_ptp_tstamp_out_0 => open,
         ctl_tx_systemtimerin_0 => gnd(79 downto 0),
         ctl_rx_systemtimerin_0 => gnd(79 downto 0),

         -- AXI TX
         user_tx_reset_0 => user_tx_reset, tx_axis_tready_0 => eth_out_siso.tready,
         tx_axis_tvalid_0 => eth_out_sosi.tvalid, tx_axis_tdata_0 => eth_out_sosi.tdata(63 DOWNTO 0),
         tx_axis_tlast_0 => eth_out_sosi.tlast, tx_axis_tkeep_0 => eth_out_sosi.tkeep(7 DOWNTO 0),
         tx_axis_tuser_0 => eth_out_sosi.tuser(0),

         -- TX Settings
         tx_unfout_0 => OPEN, ctl_tx_enable_0 => '1',
         tx_preamblein_0 => gnd(55 DOWNTO 0), rx_preambleout_0 => open,
         ctl_tx_send_rfi_0 => ctl_tx_send_rfi, ctl_tx_send_lfi_0 => ctl_tx_send_lfi, ctl_tx_send_idle_0 => ctl_tx_send_idle,
         ctl_tx_fcs_ins_enable_0 => '1', ctl_tx_ignore_fcs_0 => '0', ctl_tx_test_pattern_0 => '0',
         ctl_tx_test_pattern_enable_0 => '0', ctl_tx_test_pattern_select_0 => '0',
         ctl_tx_data_pattern_select_0 => '0', ctl_tx_test_pattern_seed_a_0 => gnd(57 DOWNTO 0),
         ctl_tx_test_pattern_seed_b_0 => gnd(57 DOWNTO 0), ctl_tx_ipg_value_0 => X"C",
         ctl_tx_custom_preamble_enable_0 => '0',

         -- TX PAUSE
         ctl_tx_pause_req_0 => "000000000", ctl_tx_pause_enable_0 => "000000000",
         ctl_tx_resend_pause_0 => '0',
         ctl_tx_pause_quanta0_0 => X"0000",
         ctl_tx_pause_quanta1_0 => X"0000", ctl_tx_pause_quanta2_0 => X"0000",
         ctl_tx_pause_quanta3_0 => X"0000", ctl_tx_pause_quanta4_0 => X"0000",
         ctl_tx_pause_quanta5_0 => X"0000", ctl_tx_pause_quanta6_0 => X"0000",
         ctl_tx_pause_quanta7_0 => X"0000", ctl_tx_pause_quanta8_0 => X"0000",
         ctl_tx_pause_refresh_timer0_0 => X"0000", ctl_tx_pause_refresh_timer1_0 => X"0000",
         ctl_tx_pause_refresh_timer2_0 => X"0000", ctl_tx_pause_refresh_timer3_0 => X"0000",
         ctl_tx_pause_refresh_timer4_0 => X"0000", ctl_tx_pause_refresh_timer5_0 => X"0000",
         ctl_tx_pause_refresh_timer6_0 => X"0000", ctl_tx_pause_refresh_timer7_0 => X"0000",
         ctl_tx_pause_refresh_timer8_0 => X"0000",
         ctl_tx_sa_gpp_0 => local_mac, ctl_tx_sa_ppp_0 => local_mac,
         ctl_tx_ethertype_gpp_0 => X"8808", ctl_tx_ethertype_ppp_0 => X"8808",
         ctl_tx_opcode_gpp_0 => X"0001", ctl_tx_opcode_ppp_0 => X"0101",
         ctl_tx_da_gpp_0 => X"0180C2000001", ctl_tx_da_ppp_0 => X"0180C2000001");
   END GENERATE;

   gen_ip_gemini_xh_lru: IF tech_is_board(g_technology, c_tech_board_gemini_xh_lru) GENERATE

      quad124_0: mac_10g_124_0
      PORT MAP (
         gt_rxp_in_0 => gt_rxp_in, gt_rxn_in_0 => gt_rxn_in,
         gt_txp_out_0 => gt_txp_out, gt_txn_out_0 => gt_txn_out,
         gt_refclk_p => gt_refclk_p, gt_refclk_n => gt_refclk_n,
         rx_core_clk_0 => rx_clk_in, txoutclksel_in_0 => "101", rxoutclksel_in_0 => "101",
         tx_clk_out_0 => tx_clk_out, rx_clk_out_0 => rx_clk_out,

         tx_reset_0 => sys_reset, sys_reset => sys_reset, rx_reset_0 => sys_reset,
         gt_loopback_in_0 => "000",

         gt_dmonitorout_0 => OPEN, gt_eyescandataerror_0 => OPEN, gt_eyescanreset_0 => '0',
         gt_eyescantrigger_0 => '0', gt_pcsrsvdin_0 => X"0000", gt_rxbufreset_0 => '0',
         gt_rxbufstatus_0 => OPEN, gt_rxcdrhold_0 => '0', gt_rxcommadeten_0 => '0',

         gt_rxdfeagchold_0 => '0', gt_rxdfelpmreset_0 => '0', gt_rxlatclk_0 => dclk,
         gt_rxlpmen_0 => g_rxlpmen, gt_rxpcsreset_0 => '0', gt_rxpmareset_0 => '0',
         gt_rxprbscntreset_0 => '0', gt_rxprbserr_0 => OPEN, gt_rxprbssel_0 => X"0",
         gt_rxrate_0 => "000", gt_rxslide_in_0 => '0', gt_rxstartofseq_0 => open,
         gt_txbufstatus_0 => open, gt_txinhibit_0 => '0', gt_txlatclk_0 => dclk,

         gt_txdiffctrl_0 => g_txdiffctrl, gt_txmaincursor_0 => g_txmaincursor, gt_txpostcursor_0 => g_txpostcursor,
         gt_txprecursor_0 => g_txprecursor, gt_rxpolarity_0 => g_rxpolarity, gt_txpolarity_0 => g_txpolarity,

         gt_refclk_out => open, gtpowergood_out_0 => open,
         gt_txpcsreset_0 => '0', gt_txpmareset_0 => '0', gt_txprbsforceerr_0 => '0',
         gt_txprbssel_0 => "0000", gtwiz_reset_tx_datapath_0 => '0',
         gtwiz_reset_rx_datapath_0 => '0', rxrecclkout_0 => open,

         -- DRP
         dclk => dclk,
         gt_drpclk_0 => dclk, gt_drpdo_0 => open, gt_drprdy_0 => open,
         gt_drpen_0 => '0', gt_drpwe_0 => '0', gt_drpaddr_0 => "0000000000",
         gt_drpdi_0 => X"0000",

         -- AXI RX
         user_rx_reset_0 => user_rx_reset, rx_axis_tvalid_0 => eth_in_sosi.tvalid,
         rx_axis_tdata_0 => eth_in_sosi.tdata(63 DOWNTO 0), rx_axis_tlast_0 => eth_in_sosi.tlast,
         rx_axis_tkeep_0 => eth_in_sosi.tkeep(7 DOWNTO 0), rx_axis_tuser_0 => eth_in_sosi.tuser(0),

         -- RX Control
         ctl_rx_enable_0 => '1', ctl_rx_check_preamble_0 => '1', ctl_rx_check_sfd_0 => '1',
         ctl_rx_force_resync_0 => '0', ctl_rx_delete_fcs_0 => '1', ctl_rx_ignore_fcs_0 => '0',
         ctl_rx_max_packet_len_0 => c_max_length, ctl_rx_min_packet_len_0 => c_min_length,
         ctl_rx_process_lfi_0 => '1', ctl_rx_test_pattern_0 => '0' ,
         ctl_rx_data_pattern_select_0 => '0', ctl_rx_test_pattern_enable_0 => '0',
         ctl_rx_custom_preamble_enable_0 => '0', ctl_rx_forward_control_0 => '0',

         -- PAUSE Common Info
         ctl_rx_pause_da_mcast_0 => X"0180C2000001", ctl_rx_pause_da_ucast_0 => local_mac,
         ctl_rx_etype_pcp_0 => X"8808", ctl_rx_etype_ppp_0 => X"8808",
         ctl_rx_opcode_min_pcp_0 => X"0101", ctl_rx_opcode_max_pcp_0 => X"0101", ctl_rx_opcode_ppp_0 => X"0101",
         ctl_rx_pause_sa_0 => gnd(47 DOWNTO 0),
         ctl_rx_etype_gcp_0 => X"8808", ctl_rx_etype_gpp_0 => X"8808",
         ctl_rx_opcode_min_gcp_0 => X"0001", ctl_rx_opcode_max_gcp_0 => X"0006", ctl_rx_opcode_gpp_0 => X"0001",

         -- PAUSE Priority Control (802.1qbb)
         ctl_rx_enable_pcp_0 => '1', ctl_rx_enable_ppp_0 => '1',
         ctl_rx_check_mcast_pcp_0 => '1', ctl_rx_check_mcast_ppp_0 => '1',
         ctl_rx_check_ucast_pcp_0 => '1', ctl_rx_check_ucast_ppp_0 => '1',
         ctl_rx_check_sa_pcp_0 => '0',  ctl_rx_check_sa_ppp_0 => '0',
         ctl_rx_check_etype_pcp_0 => '1', ctl_rx_check_etype_ppp_0 =>'1' ,
         ctl_rx_check_opcode_pcp_0 => '1', ctl_rx_check_opcode_ppp_0 => '1',

         -- PAUSE Global Control (Only 802.1qbb supported)
         ctl_rx_enable_gcp_0 => '0', ctl_rx_enable_gpp_0 => '0',
         ctl_rx_check_mcast_gcp_0 => '1', ctl_rx_check_mcast_gpp_0 => '1',
         ctl_rx_check_ucast_gcp_0 => '1', ctl_rx_check_ucast_gpp_0 => '1',
         ctl_rx_check_sa_gcp_0 => '0', ctl_rx_check_sa_gpp_0 => '0',
         ctl_rx_check_etype_gcp_0 => '1', ctl_rx_check_etype_gpp_0 => '1',
         ctl_rx_check_opcode_gcp_0 => '1', ctl_rx_check_opcode_gpp_0 => '1',

         ctl_rx_check_ack_0 => '1', ctl_rx_pause_enable_0 => ctl_rx_pause_enable,
         ctl_rx_pause_ack_0 => ctl_rx_pause_ack, stat_rx_pause_req_0 => stat_rx_pause_req,

         stat_rx_pause_valid_0 => open, stat_rx_pause_quanta0_0 => open, stat_rx_pause_quanta1_0 => open,
         stat_rx_pause_quanta2_0 => open, stat_rx_pause_quanta3_0 => open, stat_rx_pause_quanta4_0 => open,
         stat_rx_pause_quanta5_0 => open, stat_rx_pause_quanta6_0 => open, stat_rx_pause_quanta7_0 => open,
         stat_rx_pause_quanta8_0 => open,

         -- Error Handling
         stat_rx_block_lock_0 => stat_rx_block_lock, stat_rx_remote_fault_0 => stat_rx_remote_fault,
         stat_rx_received_local_fault_0 => stat_rx_received_local_fault,
         stat_rx_internal_local_fault_0 => stat_rx_internal_local_fault,

         -- Statistics
         stat_rx_bad_fcs_0 => stat_rx_bad_fcs, stat_rx_oversize_0 => stat_rx_oversize,
         stat_rx_total_bytes_0 => stat_rx_total_bytes, stat_rx_total_packets_0 => stat_rx_total_packets,
         stat_rx_vlan_0 => stat_rx_vlan, stat_rx_packet_small_0 => stat_rx_packet_small,
         stat_rx_user_pause_0 => stat_rx_user_pause, stat_rx_bad_code_0 => stat_rx_bad_code,

         stat_rx_pause_0 => open,  stat_rx_valid_ctrl_code_0 => open,
         stat_rx_framing_err_0 => open, stat_rx_framing_err_valid_0 => open, stat_rx_local_fault_0 => open,
         stat_rx_status_0 => open, stat_rx_got_signal_os_0 => open, stat_rx_bad_preamble_0 => open,
         stat_rx_stomped_fcs_0 => open, stat_rx_truncated_0 => open, stat_rx_hi_ber_0 => open,
         stat_rx_test_pattern_mismatch_0 => open, stat_rx_inrangeerr_0 => open, stat_rx_jabber_0 => open,
         stat_rx_total_good_bytes_0 => open, stat_rx_total_good_packets_0 => open, stat_rx_packet_bad_fcs_0 => open,
         stat_rx_packet_64_bytes_0 => open, stat_rx_packet_65_127_bytes_0 => open, stat_rx_packet_128_255_bytes_0 => open,
         stat_rx_packet_256_511_bytes_0 => open, stat_rx_packet_512_1023_bytes_0 => open,
         stat_rx_packet_1024_1518_bytes_0 => open, stat_rx_packet_1519_1522_bytes_0 => open,
         stat_rx_packet_1523_1548_bytes_0 => open, stat_rx_packet_1549_2047_bytes_0 => open,
         stat_rx_packet_2048_4095_bytes_0 => open, stat_rx_packet_4096_8191_bytes_0 => open,
         stat_rx_packet_8192_9215_bytes_0 => open,  stat_rx_packet_large_0 => open,
         stat_rx_unicast_0 => open, stat_rx_multicast_0 => open, stat_rx_broadcast_0 => open, stat_rx_bad_sfd_0 => open,
         stat_rx_toolong_0 => open, stat_rx_undersize_0 => open, stat_rx_fragment_0 => open,

         stat_tx_packet_large_0 => stat_tx_packet_large, stat_tx_packet_small_0 => stat_tx_packet_small,
         stat_tx_total_bytes_0 => stat_tx_total_bytes, stat_tx_total_packets_0 => stat_tx_total_packets,

         stat_tx_local_fault_0 => open, stat_tx_user_pause_0 => open,
         stat_tx_total_good_bytes_0 => open, stat_tx_total_good_packets_0 => open, stat_tx_bad_fcs_0 => open,
         stat_tx_packet_64_bytes_0 => open, stat_tx_packet_65_127_bytes_0 => open, stat_tx_packet_128_255_bytes_0 => open,
         stat_tx_packet_256_511_bytes_0 => open, stat_tx_packet_512_1023_bytes_0 => open,
         stat_tx_packet_1024_1518_bytes_0 => open, stat_tx_packet_1519_1522_bytes_0 => open,
         stat_tx_packet_1523_1548_bytes_0 => open, stat_tx_packet_1549_2047_bytes_0 => open,
         stat_tx_packet_2048_4095_bytes_0 => open, stat_tx_packet_4096_8191_bytes_0 => open,
         stat_tx_packet_8192_9215_bytes_0 => open, stat_tx_pause_valid_0 => open,
         stat_tx_unicast_0 => open, stat_tx_multicast_0 => open, stat_tx_broadcast_0 => open,
         stat_tx_vlan_0 => open, stat_tx_frame_error_0 => open, stat_tx_pause_0 => open,

         -- PTP
         stat_tx_ptp_fifo_read_error_0 => open, stat_tx_ptp_fifo_write_error_0 => open,
         tx_ptp_1588op_in_0 => "00", tx_ptp_tag_field_in_0 => X"0000",
         tx_ptp_tstamp_valid_out_0 => open, rx_ptp_tstamp_valid_out_0 => open,
         tx_ptp_tstamp_tag_out_0 => open, tx_ptp_tstamp_out_0 => open, rx_ptp_tstamp_out_0 => open,
         ctl_tx_systemtimerin_0 => gnd(79 downto 0),
         ctl_rx_systemtimerin_0 => gnd(79 downto 0),

         -- AXI TX
         user_tx_reset_0 => user_tx_reset, tx_axis_tready_0 => eth_out_siso.tready,
         tx_axis_tvalid_0 => eth_out_sosi.tvalid, tx_axis_tdata_0 => eth_out_sosi.tdata(63 DOWNTO 0),
         tx_axis_tlast_0 => eth_out_sosi.tlast, tx_axis_tkeep_0 => eth_out_sosi.tkeep(7 DOWNTO 0),
         tx_axis_tuser_0 => eth_out_sosi.tuser(0),

         -- TX Settings
         tx_unfout_0 => OPEN, ctl_tx_enable_0 => '1',
         tx_preamblein_0 => gnd(55 DOWNTO 0), rx_preambleout_0 => open,
         ctl_tx_send_rfi_0 => ctl_tx_send_rfi, ctl_tx_send_lfi_0 => ctl_tx_send_lfi, ctl_tx_send_idle_0 => ctl_tx_send_idle,
         ctl_tx_fcs_ins_enable_0 => '1', ctl_tx_ignore_fcs_0 => '0', ctl_tx_test_pattern_0 => '0',
         ctl_tx_test_pattern_enable_0 => '0', ctl_tx_test_pattern_select_0 => '0',
         ctl_tx_data_pattern_select_0 => '0', ctl_tx_test_pattern_seed_a_0 => gnd(57 DOWNTO 0),
         ctl_tx_test_pattern_seed_b_0 => gnd(57 DOWNTO 0), ctl_tx_ipg_value_0 => X"C",
         ctl_tx_custom_preamble_enable_0 => '0',

         -- TX PAUSE
         ctl_tx_pause_req_0 => "000000000", ctl_tx_pause_enable_0 => "000000000",
         ctl_tx_resend_pause_0 => '0',
         ctl_tx_pause_quanta0_0 => X"0000",
         ctl_tx_pause_quanta1_0 => X"0000", ctl_tx_pause_quanta2_0 => X"0000",
         ctl_tx_pause_quanta3_0 => X"0000", ctl_tx_pause_quanta4_0 => X"0000",
         ctl_tx_pause_quanta5_0 => X"0000", ctl_tx_pause_quanta6_0 => X"0000",
         ctl_tx_pause_quanta7_0 => X"0000", ctl_tx_pause_quanta8_0 => X"0000",
         ctl_tx_pause_refresh_timer0_0 => X"0000", ctl_tx_pause_refresh_timer1_0 => X"0000",
         ctl_tx_pause_refresh_timer2_0 => X"0000", ctl_tx_pause_refresh_timer3_0 => X"0000",
         ctl_tx_pause_refresh_timer4_0 => X"0000", ctl_tx_pause_refresh_timer5_0 => X"0000",
         ctl_tx_pause_refresh_timer6_0 => X"0000", ctl_tx_pause_refresh_timer7_0 => X"0000",
         ctl_tx_pause_refresh_timer8_0 => X"0000",
         ctl_tx_sa_gpp_0 => local_mac, ctl_tx_sa_ppp_0 => local_mac,
         ctl_tx_ethertype_gpp_0 => X"8808", ctl_tx_ethertype_ppp_0 => X"8808",
         ctl_tx_opcode_gpp_0 => X"0001", ctl_tx_opcode_ppp_0 => X"0101",
         ctl_tx_da_gpp_0 => X"0180C2000001", ctl_tx_da_ppp_0 => X"0180C2000001");
   END GENERATE;


   gen_ip_kcu105: IF tech_is_board(g_technology, c_tech_board_kcu105) GENERATE

      quad126_2: mac_10g_226_2
      PORT MAP (
         gt_rxp_in_0 => gt_rxp_in, gt_rxn_in_0 => gt_rxn_in,
         gt_txp_out_0 => gt_txp_out, gt_txn_out_0 => gt_txn_out,
         gt_refclk_p => gt_refclk_p, gt_refclk_n => gt_refclk_n,
         rx_core_clk_0 => rx_clk_in, txoutclksel_in_0 => "101", rxoutclksel_in_0 => "101",
         tx_clk_out_0 => tx_clk_out, rx_clk_out_0 => rx_clk_out,

         tx_reset_0 => sys_reset, sys_reset => sys_reset, rx_reset_0 => sys_reset,
         gt_loopback_in_0 => "000",

         gt_dmonitorout_0 => OPEN, gt_eyescandataerror_0 => OPEN, gt_eyescanreset_0 => '0',
         gt_eyescantrigger_0 => '0', gt_pcsrsvdin_0 => X"0000", gt_rxbufreset_0 => '0',
         gt_rxbufstatus_0 => OPEN, gt_rxcdrhold_0 => '0', gt_rxcommadeten_0 => '0',

         gt_rxdfeagchold_0 => '0', gt_rxdfelpmreset_0 => '0', gt_rxlatclk_0 => dclk,
         gt_rxlpmen_0 => g_rxlpmen, gt_rxpcsreset_0 => '0', gt_rxpmareset_0 => '0',
         gt_rxprbscntreset_0 => '0', gt_rxprbserr_0 => OPEN, gt_rxprbssel_0 => X"0",
         gt_rxrate_0 => "000", gt_rxslide_in_0 => '0', gt_rxstartofseq_0 => open,
         gt_txbufstatus_0 => open, gt_txinhibit_0 => '0', gt_txlatclk_0 => dclk,

         gt_txdiffctrl_0 => g_txdiffctrl, gt_txmaincursor_0 => g_txmaincursor, gt_txpostcursor_0 => g_txpostcursor,
         gt_txprecursor_0 => g_txprecursor, gt_rxpolarity_0 => g_rxpolarity, gt_txpolarity_0 => g_txpolarity,

         gt_refclk_out => open, gtpowergood_out_0 => open,
         gt_txpcsreset_0 => '0', gt_txpmareset_0 => '0', gt_txprbsforceerr_0 => '0',
         gt_txprbssel_0 => "0000", gtwiz_reset_tx_datapath_0 => '0',
         gtwiz_reset_rx_datapath_0 => '0', rxrecclkout_0 => open,

         -- DRP
         dclk => dclk,
         gt_drpclk_0 => dclk, gt_drpdo_0 => open, gt_drprdy_0 => open,
         gt_drpen_0 => '0', gt_drpwe_0 => '0', gt_drpaddr_0 => "0000000000",
         gt_drpdi_0 => X"0000",

         -- AXI RX
         user_rx_reset_0 => user_rx_reset, rx_axis_tvalid_0 => eth_in_sosi.tvalid,
         rx_axis_tdata_0 => eth_in_sosi.tdata(63 DOWNTO 0), rx_axis_tlast_0 => eth_in_sosi.tlast,
         rx_axis_tkeep_0 => eth_in_sosi.tkeep(7 DOWNTO 0), rx_axis_tuser_0 => eth_in_sosi.tuser(0),

         -- RX Control
         ctl_rx_enable_0 => '1', ctl_rx_check_preamble_0 => '1', ctl_rx_check_sfd_0 => '1',
         ctl_rx_force_resync_0 => '0', ctl_rx_delete_fcs_0 => '1', ctl_rx_ignore_fcs_0 => '0',
         ctl_rx_max_packet_len_0 => c_max_length, ctl_rx_min_packet_len_0 => c_min_length,
         ctl_rx_process_lfi_0 => '1', ctl_rx_test_pattern_0 => '0' ,
         ctl_rx_data_pattern_select_0 => '0', ctl_rx_test_pattern_enable_0 => '0',
         ctl_rx_custom_preamble_enable_0 => '0', ctl_rx_forward_control_0 => '0',

         -- PAUSE Common Info
         ctl_rx_pause_da_mcast_0 => X"0180C2000001", ctl_rx_pause_da_ucast_0 => local_mac,
         ctl_rx_etype_pcp_0 => X"8808", ctl_rx_etype_ppp_0 => X"8808",
         ctl_rx_opcode_min_pcp_0 => X"0101", ctl_rx_opcode_max_pcp_0 => X"0101", ctl_rx_opcode_ppp_0 => X"0101",
         ctl_rx_pause_sa_0 => gnd(47 DOWNTO 0),
         ctl_rx_etype_gcp_0 => X"8808", ctl_rx_etype_gpp_0 => X"8808",
         ctl_rx_opcode_min_gcp_0 => X"0001", ctl_rx_opcode_max_gcp_0 => X"0006", ctl_rx_opcode_gpp_0 => X"0001",

         -- PAUSE Priority Control (802.1qbb)
         ctl_rx_enable_pcp_0 => '1', ctl_rx_enable_ppp_0 => '1',
         ctl_rx_check_mcast_pcp_0 => '1', ctl_rx_check_mcast_ppp_0 => '1',
         ctl_rx_check_ucast_pcp_0 => '1', ctl_rx_check_ucast_ppp_0 => '1',
         ctl_rx_check_sa_pcp_0 => '0',  ctl_rx_check_sa_ppp_0 => '0',
         ctl_rx_check_etype_pcp_0 => '1', ctl_rx_check_etype_ppp_0 =>'1' ,
         ctl_rx_check_opcode_pcp_0 => '1', ctl_rx_check_opcode_ppp_0 => '1',

         -- PAUSE Global Control (Only 802.1qbb supported)
         ctl_rx_enable_gcp_0 => '0', ctl_rx_enable_gpp_0 => '0',
         ctl_rx_check_mcast_gcp_0 => '1', ctl_rx_check_mcast_gpp_0 => '1',
         ctl_rx_check_ucast_gcp_0 => '1', ctl_rx_check_ucast_gpp_0 => '1',
         ctl_rx_check_sa_gcp_0 => '0', ctl_rx_check_sa_gpp_0 => '0',
         ctl_rx_check_etype_gcp_0 => '1', ctl_rx_check_etype_gpp_0 => '1',
         ctl_rx_check_opcode_gcp_0 => '1', ctl_rx_check_opcode_gpp_0 => '1',

         ctl_rx_check_ack_0 => '1', ctl_rx_pause_enable_0 => ctl_rx_pause_enable,
         ctl_rx_pause_ack_0 => ctl_rx_pause_ack, stat_rx_pause_req_0 => stat_rx_pause_req,

         stat_rx_pause_valid_0 => open, stat_rx_pause_quanta0_0 => open, stat_rx_pause_quanta1_0 => open,
         stat_rx_pause_quanta2_0 => open, stat_rx_pause_quanta3_0 => open, stat_rx_pause_quanta4_0 => open,
         stat_rx_pause_quanta5_0 => open, stat_rx_pause_quanta6_0 => open, stat_rx_pause_quanta7_0 => open,
         stat_rx_pause_quanta8_0 => open,

         -- Error Handling
         stat_rx_block_lock_0 => stat_rx_block_lock, stat_rx_remote_fault_0 => stat_rx_remote_fault,
         stat_rx_received_local_fault_0 => stat_rx_received_local_fault,
         stat_rx_internal_local_fault_0 => stat_rx_internal_local_fault,

         -- Statistics
         stat_rx_bad_fcs_0 => stat_rx_bad_fcs, stat_rx_oversize_0 => stat_rx_oversize,
         stat_rx_total_bytes_0 => stat_rx_total_bytes, stat_rx_total_packets_0 => stat_rx_total_packets,
         stat_rx_vlan_0 => stat_rx_vlan, stat_rx_packet_small_0 => stat_rx_packet_small,
         stat_rx_user_pause_0 => stat_rx_user_pause, stat_rx_bad_code_0 => stat_rx_bad_code,

         stat_rx_pause_0 => open,  stat_rx_valid_ctrl_code_0 => open,
         stat_rx_framing_err_0 => open, stat_rx_framing_err_valid_0 => open, stat_rx_local_fault_0 => open,
         stat_rx_status_0 => open, stat_rx_got_signal_os_0 => open, stat_rx_bad_preamble_0 => open,
         stat_rx_stomped_fcs_0 => open, stat_rx_truncated_0 => open, stat_rx_hi_ber_0 => open,
         stat_rx_test_pattern_mismatch_0 => open, stat_rx_inrangeerr_0 => open, stat_rx_jabber_0 => open,
         stat_rx_total_good_bytes_0 => open, stat_rx_total_good_packets_0 => open, stat_rx_packet_bad_fcs_0 => open,
         stat_rx_packet_64_bytes_0 => open, stat_rx_packet_65_127_bytes_0 => open, stat_rx_packet_128_255_bytes_0 => open,
         stat_rx_packet_256_511_bytes_0 => open, stat_rx_packet_512_1023_bytes_0 => open,
         stat_rx_packet_1024_1518_bytes_0 => open, stat_rx_packet_1519_1522_bytes_0 => open,
         stat_rx_packet_1523_1548_bytes_0 => open, stat_rx_packet_1549_2047_bytes_0 => open,
         stat_rx_packet_2048_4095_bytes_0 => open, stat_rx_packet_4096_8191_bytes_0 => open,
         stat_rx_packet_8192_9215_bytes_0 => open,  stat_rx_packet_large_0 => open,
         stat_rx_unicast_0 => open, stat_rx_multicast_0 => open, stat_rx_broadcast_0 => open, stat_rx_bad_sfd_0 => open,
         stat_rx_toolong_0 => open, stat_rx_undersize_0 => open, stat_rx_fragment_0 => open,

         stat_tx_packet_large_0 => stat_tx_packet_large, stat_tx_packet_small_0 => stat_tx_packet_small,
         stat_tx_total_bytes_0 => stat_tx_total_bytes, stat_tx_total_packets_0 => stat_tx_total_packets,

         stat_tx_local_fault_0 => open, stat_tx_user_pause_0 => open,
         stat_tx_total_good_bytes_0 => open, stat_tx_total_good_packets_0 => open, stat_tx_bad_fcs_0 => open,
         stat_tx_packet_64_bytes_0 => open, stat_tx_packet_65_127_bytes_0 => open, stat_tx_packet_128_255_bytes_0 => open,
         stat_tx_packet_256_511_bytes_0 => open, stat_tx_packet_512_1023_bytes_0 => open,
         stat_tx_packet_1024_1518_bytes_0 => open, stat_tx_packet_1519_1522_bytes_0 => open,
         stat_tx_packet_1523_1548_bytes_0 => open, stat_tx_packet_1549_2047_bytes_0 => open,
         stat_tx_packet_2048_4095_bytes_0 => open, stat_tx_packet_4096_8191_bytes_0 => open,
         stat_tx_packet_8192_9215_bytes_0 => open, stat_tx_pause_valid_0 => open,
         stat_tx_unicast_0 => open, stat_tx_multicast_0 => open, stat_tx_broadcast_0 => open,
         stat_tx_vlan_0 => open, stat_tx_frame_error_0 => open, stat_tx_pause_0 => open,

         -- PTP
         stat_tx_ptp_fifo_read_error_0 => open, stat_tx_ptp_fifo_write_error_0 => open,
         tx_ptp_1588op_in_0 => "00", tx_ptp_tag_field_in_0 => X"0000",
         tx_ptp_tstamp_valid_out_0 => open, rx_ptp_tstamp_valid_out_0 => open,
         tx_ptp_tstamp_tag_out_0 => open, tx_ptp_tstamp_out_0 => open, rx_ptp_tstamp_out_0 => open,
         ctl_tx_systemtimerin_0 => gnd(79 downto 0),
         ctl_rx_systemtimerin_0 => gnd(79 downto 0),

         -- AXI TX
         user_tx_reset_0 => user_tx_reset, tx_axis_tready_0 => eth_out_siso.tready,
         tx_axis_tvalid_0 => eth_out_sosi.tvalid, tx_axis_tdata_0 => eth_out_sosi.tdata(63 DOWNTO 0),
         tx_axis_tlast_0 => eth_out_sosi.tlast, tx_axis_tkeep_0 => eth_out_sosi.tkeep(7 DOWNTO 0),
         tx_axis_tuser_0 => eth_out_sosi.tuser(0),

         -- TX Settings
         tx_unfout_0 => OPEN, ctl_tx_enable_0 => '1',
         tx_preamblein_0 => gnd(55 DOWNTO 0), rx_preambleout_0 => open,
         ctl_tx_send_rfi_0 => ctl_tx_send_rfi, ctl_tx_send_lfi_0 => ctl_tx_send_lfi, ctl_tx_send_idle_0 => ctl_tx_send_idle,
         ctl_tx_fcs_ins_enable_0 => '1', ctl_tx_ignore_fcs_0 => '0', ctl_tx_test_pattern_0 => '0',
         ctl_tx_test_pattern_enable_0 => '0', ctl_tx_test_pattern_select_0 => '0',
         ctl_tx_data_pattern_select_0 => '0', ctl_tx_test_pattern_seed_a_0 => gnd(57 DOWNTO 0),
         ctl_tx_test_pattern_seed_b_0 => gnd(57 DOWNTO 0), ctl_tx_ipg_value_0 => X"C",
         ctl_tx_custom_preamble_enable_0 => '0',

         -- TX PAUSE
         ctl_tx_pause_req_0 => "000000000", ctl_tx_pause_enable_0 => "000000000",
         ctl_tx_resend_pause_0 => '0',
         ctl_tx_pause_quanta0_0 => X"0000",
         ctl_tx_pause_quanta1_0 => X"0000", ctl_tx_pause_quanta2_0 => X"0000",
         ctl_tx_pause_quanta3_0 => X"0000", ctl_tx_pause_quanta4_0 => X"0000",
         ctl_tx_pause_quanta5_0 => X"0000", ctl_tx_pause_quanta6_0 => X"0000",
         ctl_tx_pause_quanta7_0 => X"0000", ctl_tx_pause_quanta8_0 => X"0000",
         ctl_tx_pause_refresh_timer0_0 => X"0000", ctl_tx_pause_refresh_timer1_0 => X"0000",
         ctl_tx_pause_refresh_timer2_0 => X"0000", ctl_tx_pause_refresh_timer3_0 => X"0000",
         ctl_tx_pause_refresh_timer4_0 => X"0000", ctl_tx_pause_refresh_timer5_0 => X"0000",
         ctl_tx_pause_refresh_timer6_0 => X"0000", ctl_tx_pause_refresh_timer7_0 => X"0000",
         ctl_tx_pause_refresh_timer8_0 => X"0000",
         ctl_tx_sa_gpp_0 => local_mac, ctl_tx_sa_ppp_0 => local_mac,
         ctl_tx_ethertype_gpp_0 => X"8808", ctl_tx_ethertype_ppp_0 => X"8808",
         ctl_tx_opcode_gpp_0 => X"0001", ctl_tx_opcode_ppp_0 => X"0101",
         ctl_tx_da_gpp_0 => X"0180C2000001", ctl_tx_da_ppp_0 => X"0180C2000001");
   END GENERATE;

   gen_ip_vcu128: IF tech_is_board(g_technology, c_tech_board_vcu128) GENERATE

      quad135_0: mac_10g_135_0
      PORT MAP (
         gt_rxp_in_0 => gt_rxp_in, gt_rxn_in_0 => gt_rxn_in,
         gt_txp_out_0 => gt_txp_out, gt_txn_out_0 => gt_txn_out,
         gt_refclk_p => gt_refclk_p, gt_refclk_n => gt_refclk_n,
         rx_core_clk_0 => rx_clk_in, txoutclksel_in_0 => "101", rxoutclksel_in_0 => "101",
         tx_clk_out_0 => tx_clk_out, rx_clk_out_0 => rx_clk_out,

         tx_reset_0 => sys_reset, sys_reset => sys_reset, rx_reset_0 => sys_reset,
         gt_loopback_in_0 => "000",

         gt_dmonitorout_0 => OPEN, gt_eyescandataerror_0 => OPEN, gt_eyescanreset_0 => '0',
         gt_eyescantrigger_0 => '0', gt_pcsrsvdin_0 => X"0000", gt_rxbufreset_0 => '0',
         gt_rxbufstatus_0 => OPEN, gt_rxcdrhold_0 => '0', gt_rxcommadeten_0 => '0',

         gt_rxdfeagchold_0 => '0', gt_rxdfelpmreset_0 => '0', gt_rxlatclk_0 => dclk,
         gt_rxlpmen_0 => g_rxlpmen, gt_rxpcsreset_0 => '0', gt_rxpmareset_0 => '0',
         gt_rxprbscntreset_0 => '0', gt_rxprbserr_0 => OPEN, gt_rxprbssel_0 => X"0",
         gt_rxrate_0 => "000", gt_rxslide_in_0 => '0', gt_rxstartofseq_0 => open,
         gt_txbufstatus_0 => open, gt_txinhibit_0 => '0', gt_txlatclk_0 => dclk,

         gt_txdiffctrl_0 => g_txdiffctrl, gt_txmaincursor_0 => g_txmaincursor, gt_txpostcursor_0 => g_txpostcursor,
         gt_txprecursor_0 => g_txprecursor, gt_rxpolarity_0 => g_rxpolarity, gt_txpolarity_0 => g_txpolarity,

         gt_refclk_out => open, gtpowergood_out_0 => open,
         gt_txpcsreset_0 => '0', gt_txpmareset_0 => '0', gt_txprbsforceerr_0 => '0',
         gt_txprbssel_0 => "0000", gtwiz_reset_tx_datapath_0 => '0',
         gtwiz_reset_rx_datapath_0 => '0', rxrecclkout_0 => open,

         -- DRP
         dclk => dclk,
         gt_drpclk_0 => dclk, gt_drpdo_0 => open, gt_drprdy_0 => open,
         gt_drpen_0 => '0', gt_drpwe_0 => '0', gt_drpaddr_0 => "0000000000",
         gt_drpdi_0 => X"0000",

         -- AXI RX
         user_rx_reset_0 => user_rx_reset, rx_axis_tvalid_0 => eth_in_sosi.tvalid,
         rx_axis_tdata_0 => eth_in_sosi.tdata(63 DOWNTO 0), rx_axis_tlast_0 => eth_in_sosi.tlast,
         rx_axis_tkeep_0 => eth_in_sosi.tkeep(7 DOWNTO 0), rx_axis_tuser_0 => eth_in_sosi.tuser(0),

         -- RX Control
         ctl_rx_enable_0 => '1', ctl_rx_check_preamble_0 => '1', ctl_rx_check_sfd_0 => '1',
         ctl_rx_force_resync_0 => '0', ctl_rx_delete_fcs_0 => '1', ctl_rx_ignore_fcs_0 => '0',
         ctl_rx_max_packet_len_0 => c_max_length, ctl_rx_min_packet_len_0 => c_min_length,
         ctl_rx_process_lfi_0 => '1', ctl_rx_test_pattern_0 => '0' ,
         ctl_rx_data_pattern_select_0 => '0', ctl_rx_test_pattern_enable_0 => '0',
         ctl_rx_custom_preamble_enable_0 => '0', ctl_rx_forward_control_0 => '0',

         -- PAUSE Common Info
         ctl_rx_pause_da_mcast_0 => X"0180C2000001", ctl_rx_pause_da_ucast_0 => local_mac,
         ctl_rx_etype_pcp_0 => X"8808", ctl_rx_etype_ppp_0 => X"8808",
         ctl_rx_opcode_min_pcp_0 => X"0101", ctl_rx_opcode_max_pcp_0 => X"0101", ctl_rx_opcode_ppp_0 => X"0101",
         ctl_rx_pause_sa_0 => gnd(47 DOWNTO 0),
         ctl_rx_etype_gcp_0 => X"8808", ctl_rx_etype_gpp_0 => X"8808",
         ctl_rx_opcode_min_gcp_0 => X"0001", ctl_rx_opcode_max_gcp_0 => X"0006", ctl_rx_opcode_gpp_0 => X"0001",

         -- PAUSE Priority Control (802.1qbb)
         ctl_rx_enable_pcp_0 => '1', ctl_rx_enable_ppp_0 => '1',
         ctl_rx_check_mcast_pcp_0 => '1', ctl_rx_check_mcast_ppp_0 => '1',
         ctl_rx_check_ucast_pcp_0 => '1', ctl_rx_check_ucast_ppp_0 => '1',
         ctl_rx_check_sa_pcp_0 => '0',  ctl_rx_check_sa_ppp_0 => '0',
         ctl_rx_check_etype_pcp_0 => '1', ctl_rx_check_etype_ppp_0 =>'1' ,
         ctl_rx_check_opcode_pcp_0 => '1', ctl_rx_check_opcode_ppp_0 => '1',

         -- PAUSE Global Control (Only 802.1qbb supported)
         ctl_rx_enable_gcp_0 => '0', ctl_rx_enable_gpp_0 => '0',
         ctl_rx_check_mcast_gcp_0 => '1', ctl_rx_check_mcast_gpp_0 => '1',
         ctl_rx_check_ucast_gcp_0 => '1', ctl_rx_check_ucast_gpp_0 => '1',
         ctl_rx_check_sa_gcp_0 => '0', ctl_rx_check_sa_gpp_0 => '0',
         ctl_rx_check_etype_gcp_0 => '1', ctl_rx_check_etype_gpp_0 => '1',
         ctl_rx_check_opcode_gcp_0 => '1', ctl_rx_check_opcode_gpp_0 => '1',

         ctl_rx_check_ack_0 => '1', ctl_rx_pause_enable_0 => ctl_rx_pause_enable,
         ctl_rx_pause_ack_0 => ctl_rx_pause_ack, stat_rx_pause_req_0 => stat_rx_pause_req,

         stat_rx_pause_valid_0 => open, stat_rx_pause_quanta0_0 => open, stat_rx_pause_quanta1_0 => open,
         stat_rx_pause_quanta2_0 => open, stat_rx_pause_quanta3_0 => open, stat_rx_pause_quanta4_0 => open,
         stat_rx_pause_quanta5_0 => open, stat_rx_pause_quanta6_0 => open, stat_rx_pause_quanta7_0 => open,
         stat_rx_pause_quanta8_0 => open,

         -- Error Handling
         stat_rx_block_lock_0 => stat_rx_block_lock, stat_rx_remote_fault_0 => stat_rx_remote_fault,
         stat_rx_received_local_fault_0 => stat_rx_received_local_fault,
         stat_rx_internal_local_fault_0 => stat_rx_internal_local_fault,

         -- Statistics
         stat_rx_bad_fcs_0 => stat_rx_bad_fcs, stat_rx_oversize_0 => stat_rx_oversize,
         stat_rx_total_bytes_0 => stat_rx_total_bytes, stat_rx_total_packets_0 => stat_rx_total_packets,
         stat_rx_vlan_0 => stat_rx_vlan, stat_rx_packet_small_0 => stat_rx_packet_small,
         stat_rx_user_pause_0 => stat_rx_user_pause, stat_rx_bad_code_0 => stat_rx_bad_code,

         stat_rx_pause_0 => open,  stat_rx_valid_ctrl_code_0 => open,
         stat_rx_framing_err_0 => open, stat_rx_framing_err_valid_0 => open, stat_rx_local_fault_0 => open,
         stat_rx_status_0 => open, stat_rx_got_signal_os_0 => open, stat_rx_bad_preamble_0 => open,
         stat_rx_stomped_fcs_0 => open, stat_rx_truncated_0 => open, stat_rx_hi_ber_0 => open,
         stat_rx_test_pattern_mismatch_0 => open, stat_rx_inrangeerr_0 => open, stat_rx_jabber_0 => open,
         stat_rx_total_good_bytes_0 => open, stat_rx_total_good_packets_0 => open, stat_rx_packet_bad_fcs_0 => open,
         stat_rx_packet_64_bytes_0 => open, stat_rx_packet_65_127_bytes_0 => open, stat_rx_packet_128_255_bytes_0 => open,
         stat_rx_packet_256_511_bytes_0 => open, stat_rx_packet_512_1023_bytes_0 => open,
         stat_rx_packet_1024_1518_bytes_0 => open, stat_rx_packet_1519_1522_bytes_0 => open,
         stat_rx_packet_1523_1548_bytes_0 => open, stat_rx_packet_1549_2047_bytes_0 => open,
         stat_rx_packet_2048_4095_bytes_0 => open, stat_rx_packet_4096_8191_bytes_0 => open,
         stat_rx_packet_8192_9215_bytes_0 => open,  stat_rx_packet_large_0 => open,
         stat_rx_unicast_0 => open, stat_rx_multicast_0 => open, stat_rx_broadcast_0 => open, stat_rx_bad_sfd_0 => open,
         stat_rx_toolong_0 => open, stat_rx_undersize_0 => open, stat_rx_fragment_0 => open,

         stat_tx_packet_large_0 => stat_tx_packet_large, stat_tx_packet_small_0 => stat_tx_packet_small,
         stat_tx_total_bytes_0 => stat_tx_total_bytes, stat_tx_total_packets_0 => stat_tx_total_packets,

         stat_tx_local_fault_0 => open, stat_tx_user_pause_0 => open,
         stat_tx_total_good_bytes_0 => open, stat_tx_total_good_packets_0 => open, stat_tx_bad_fcs_0 => open,
         stat_tx_packet_64_bytes_0 => open, stat_tx_packet_65_127_bytes_0 => open, stat_tx_packet_128_255_bytes_0 => open,
         stat_tx_packet_256_511_bytes_0 => open, stat_tx_packet_512_1023_bytes_0 => open,
         stat_tx_packet_1024_1518_bytes_0 => open, stat_tx_packet_1519_1522_bytes_0 => open,
         stat_tx_packet_1523_1548_bytes_0 => open, stat_tx_packet_1549_2047_bytes_0 => open,
         stat_tx_packet_2048_4095_bytes_0 => open, stat_tx_packet_4096_8191_bytes_0 => open,
         stat_tx_packet_8192_9215_bytes_0 => open, stat_tx_pause_valid_0 => open,
         stat_tx_unicast_0 => open, stat_tx_multicast_0 => open, stat_tx_broadcast_0 => open,
         stat_tx_vlan_0 => open, stat_tx_frame_error_0 => open, stat_tx_pause_0 => open,

         -- PTP
         stat_tx_ptp_fifo_read_error_0 => open, stat_tx_ptp_fifo_write_error_0 => open,
         tx_ptp_1588op_in_0 => "00", tx_ptp_tag_field_in_0 => X"0000",
         tx_ptp_tstamp_valid_out_0 => open, rx_ptp_tstamp_valid_out_0 => open,
         tx_ptp_tstamp_tag_out_0 => open, tx_ptp_tstamp_out_0 => open, rx_ptp_tstamp_out_0 => open,
         ctl_tx_systemtimerin_0 => gnd(79 downto 0),
         ctl_rx_systemtimerin_0 => gnd(79 downto 0),

         -- AXI TX
         user_tx_reset_0 => user_tx_reset, tx_axis_tready_0 => eth_out_siso.tready,
         tx_axis_tvalid_0 => eth_out_sosi.tvalid, tx_axis_tdata_0 => eth_out_sosi.tdata(63 DOWNTO 0),
         tx_axis_tlast_0 => eth_out_sosi.tlast, tx_axis_tkeep_0 => eth_out_sosi.tkeep(7 DOWNTO 0),
         tx_axis_tuser_0 => eth_out_sosi.tuser(0),

         -- TX Settings
         tx_unfout_0 => OPEN, ctl_tx_enable_0 => '1',
         tx_preamblein_0 => gnd(55 DOWNTO 0), rx_preambleout_0 => open,
         ctl_tx_send_rfi_0 => ctl_tx_send_rfi, ctl_tx_send_lfi_0 => ctl_tx_send_lfi, ctl_tx_send_idle_0 => ctl_tx_send_idle,
         ctl_tx_fcs_ins_enable_0 => '1', ctl_tx_ignore_fcs_0 => '0', ctl_tx_test_pattern_0 => '0',
         ctl_tx_test_pattern_enable_0 => '0', ctl_tx_test_pattern_select_0 => '0',
         ctl_tx_data_pattern_select_0 => '0', ctl_tx_test_pattern_seed_a_0 => gnd(57 DOWNTO 0),
         ctl_tx_test_pattern_seed_b_0 => gnd(57 DOWNTO 0), ctl_tx_ipg_value_0 => X"C",
         ctl_tx_custom_preamble_enable_0 => '0',

         -- TX PAUSE
         ctl_tx_pause_req_0 => "000000000", ctl_tx_pause_enable_0 => "000000000",
         ctl_tx_resend_pause_0 => '0',
         ctl_tx_pause_quanta0_0 => X"0000",
         ctl_tx_pause_quanta1_0 => X"0000", ctl_tx_pause_quanta2_0 => X"0000",
         ctl_tx_pause_quanta3_0 => X"0000", ctl_tx_pause_quanta4_0 => X"0000",
         ctl_tx_pause_quanta5_0 => X"0000", ctl_tx_pause_quanta6_0 => X"0000",
         ctl_tx_pause_quanta7_0 => X"0000", ctl_tx_pause_quanta8_0 => X"0000",
         ctl_tx_pause_refresh_timer0_0 => X"0000", ctl_tx_pause_refresh_timer1_0 => X"0000",
         ctl_tx_pause_refresh_timer2_0 => X"0000", ctl_tx_pause_refresh_timer3_0 => X"0000",
         ctl_tx_pause_refresh_timer4_0 => X"0000", ctl_tx_pause_refresh_timer5_0 => X"0000",
         ctl_tx_pause_refresh_timer6_0 => X"0000", ctl_tx_pause_refresh_timer7_0 => X"0000",
         ctl_tx_pause_refresh_timer8_0 => X"0000",
         ctl_tx_sa_gpp_0 => local_mac, ctl_tx_sa_ppp_0 => local_mac,
         ctl_tx_ethertype_gpp_0 => X"8808", ctl_tx_ethertype_ppp_0 => X"8808",
         ctl_tx_opcode_gpp_0 => X"0001", ctl_tx_opcode_ppp_0 => X"0101",
         ctl_tx_da_gpp_0 => X"0180C2000001", ctl_tx_da_ppp_0 => X"0180C2000001");
   END GENERATE;


END str;





