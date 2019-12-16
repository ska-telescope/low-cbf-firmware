LIBRARY IEEE, technology_lib, common_lib;
USE IEEE.std_logic_1164.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;


ENTITY mac_10g_226_2 IS
  PORT (
    gt_rxp_in_0 : IN STD_LOGIC;
    gt_rxn_in_0 : IN STD_LOGIC;
    gt_txp_out_0 : OUT STD_LOGIC;
    gt_txn_out_0 : OUT STD_LOGIC;
    rx_core_clk_0 : IN STD_LOGIC;
    txoutclksel_in_0 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    rxoutclksel_in_0 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    gt_dmonitorout_0 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
    gt_eyescandataerror_0 : OUT STD_LOGIC;
    gt_eyescanreset_0 : IN STD_LOGIC;
    gt_eyescantrigger_0 : IN STD_LOGIC;
    gt_pcsrsvdin_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    gt_rxbufreset_0 : IN STD_LOGIC;
    gt_rxbufstatus_0 : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    gt_rxcdrhold_0 : IN STD_LOGIC;
    gt_rxcommadeten_0 : IN STD_LOGIC;
    gt_rxdfeagchold_0 : IN STD_LOGIC;
    gt_rxdfelpmreset_0 : IN STD_LOGIC;
    gt_rxlatclk_0 : IN STD_LOGIC;
    gt_rxlpmen_0 : IN STD_LOGIC;
    gt_rxpcsreset_0 : IN STD_LOGIC;
    gt_rxpmareset_0 : IN STD_LOGIC;
    gt_rxpolarity_0 : IN STD_LOGIC;
    gt_rxprbscntreset_0 : IN STD_LOGIC;
    gt_rxprbserr_0 : OUT STD_LOGIC;
    gt_rxprbssel_0 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    gt_rxrate_0 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    gt_rxslide_in_0 : IN STD_LOGIC;
    gt_rxstartofseq_0 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    gt_txbufstatus_0 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    gt_txdiffctrl_0 : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    gt_txinhibit_0 : IN STD_LOGIC;
    gt_txlatclk_0 : IN STD_LOGIC;
    gt_txmaincursor_0 : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    gt_txpcsreset_0 : IN STD_LOGIC;
    gt_txpmareset_0 : IN STD_LOGIC;
    gt_txpolarity_0 : IN STD_LOGIC;
    gt_txpostcursor_0 : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    gt_txprbsforceerr_0 : IN STD_LOGIC;
    gt_txprbssel_0 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    gt_txprecursor_0 : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    gtwiz_reset_tx_datapath_0 : IN STD_LOGIC;
    gtwiz_reset_rx_datapath_0 : IN STD_LOGIC;
    rxrecclkout_0 : OUT STD_LOGIC;
    gt_drpclk_0 : IN STD_LOGIC;
    gt_drpdo_0 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    gt_drprdy_0 : OUT STD_LOGIC;
    gt_drpen_0 : IN STD_LOGIC;
    gt_drpwe_0 : IN STD_LOGIC;
    gt_drpaddr_0 : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    gt_drpdi_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    sys_reset : IN STD_LOGIC;
    dclk : IN STD_LOGIC;
    tx_clk_out_0 : OUT STD_LOGIC;
    rx_clk_out_0 : OUT STD_LOGIC;
    gt_refclk_p : IN STD_LOGIC;
    gt_refclk_n : IN STD_LOGIC;
    gt_refclk_out : OUT STD_LOGIC;
    gtpowergood_out_0 : OUT STD_LOGIC;
    rx_reset_0 : IN STD_LOGIC;
    user_rx_reset_0 : OUT STD_LOGIC;
    rx_axis_tvalid_0 : OUT STD_LOGIC;
    rx_axis_tdata_0 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    rx_axis_tlast_0 : OUT STD_LOGIC;
    rx_axis_tkeep_0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    rx_axis_tuser_0 : OUT STD_LOGIC;
    ctl_rx_enable_0 : IN STD_LOGIC;
    ctl_rx_check_preamble_0 : IN STD_LOGIC;
    ctl_rx_check_sfd_0 : IN STD_LOGIC;
    ctl_rx_force_resync_0 : IN STD_LOGIC;
    ctl_rx_delete_fcs_0 : IN STD_LOGIC;
    ctl_rx_ignore_fcs_0 : IN STD_LOGIC;
    ctl_rx_max_packet_len_0 : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
    ctl_rx_min_packet_len_0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    ctl_rx_process_lfi_0 : IN STD_LOGIC;
    ctl_rx_test_pattern_0 : IN STD_LOGIC;
    ctl_rx_data_pattern_select_0 : IN STD_LOGIC;
    ctl_rx_test_pattern_enable_0 : IN STD_LOGIC;
    ctl_rx_custom_preamble_enable_0 : IN STD_LOGIC;
    ctl_rx_pause_enable_0 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    ctl_rx_enable_gcp_0 : IN STD_LOGIC;
    ctl_rx_check_mcast_gcp_0 : IN STD_LOGIC;
    ctl_rx_check_ucast_gcp_0 : IN STD_LOGIC;
    ctl_rx_pause_da_ucast_0 : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
    ctl_rx_check_sa_gcp_0 : IN STD_LOGIC;
    ctl_rx_pause_sa_0 : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
    ctl_rx_check_etype_gcp_0 : IN STD_LOGIC;
    ctl_rx_check_opcode_gcp_0 : IN STD_LOGIC;
    ctl_rx_opcode_min_gcp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_rx_opcode_max_gcp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_rx_etype_gcp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_rx_enable_pcp_0 : IN STD_LOGIC;
    ctl_rx_check_mcast_pcp_0 : IN STD_LOGIC;
    ctl_rx_check_ucast_pcp_0 : IN STD_LOGIC;
    ctl_rx_pause_da_mcast_0 : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
    ctl_rx_check_sa_pcp_0 : IN STD_LOGIC;
    ctl_rx_check_etype_pcp_0 : IN STD_LOGIC;
    ctl_rx_etype_pcp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_rx_check_opcode_pcp_0 : IN STD_LOGIC;
    ctl_rx_opcode_min_pcp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_rx_opcode_max_pcp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_rx_enable_gpp_0 : IN STD_LOGIC;
    ctl_rx_check_mcast_gpp_0 : IN STD_LOGIC;
    ctl_rx_check_ucast_gpp_0 : IN STD_LOGIC;
    ctl_rx_check_sa_gpp_0 : IN STD_LOGIC;
    ctl_rx_check_etype_gpp_0 : IN STD_LOGIC;
    ctl_rx_etype_gpp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_rx_check_opcode_gpp_0 : IN STD_LOGIC;
    ctl_rx_opcode_gpp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_rx_enable_ppp_0 : IN STD_LOGIC;
    ctl_rx_check_mcast_ppp_0 : IN STD_LOGIC;
    ctl_rx_check_ucast_ppp_0 : IN STD_LOGIC;
    ctl_rx_check_sa_ppp_0 : IN STD_LOGIC;
    ctl_rx_check_etype_ppp_0 : IN STD_LOGIC;
    ctl_rx_etype_ppp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_rx_check_opcode_ppp_0 : IN STD_LOGIC;
    ctl_rx_opcode_ppp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_rx_pause_ack_0 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    ctl_rx_check_ack_0 : IN STD_LOGIC;
    ctl_rx_forward_control_0 : IN STD_LOGIC;
    stat_rx_pause_req_0 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    stat_rx_pause_valid_0 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    stat_rx_pause_quanta0_0 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    stat_rx_pause_quanta1_0 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    stat_rx_pause_quanta2_0 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    stat_rx_pause_quanta3_0 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    stat_rx_pause_quanta4_0 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    stat_rx_pause_quanta5_0 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    stat_rx_pause_quanta6_0 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    stat_rx_pause_quanta7_0 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    stat_rx_pause_quanta8_0 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    stat_rx_pause_0 : OUT STD_LOGIC;
    stat_rx_user_pause_0 : OUT STD_LOGIC;
    stat_rx_framing_err_0 : OUT STD_LOGIC;
    stat_rx_framing_err_valid_0 : OUT STD_LOGIC;
    stat_rx_local_fault_0 : OUT STD_LOGIC;
    stat_rx_block_lock_0 : OUT STD_LOGIC;
    stat_rx_valid_ctrl_code_0 : OUT STD_LOGIC;
    stat_rx_status_0 : OUT STD_LOGIC;
    stat_rx_remote_fault_0 : OUT STD_LOGIC;
    stat_rx_bad_fcs_0 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    stat_rx_stomped_fcs_0 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    stat_rx_truncated_0 : OUT STD_LOGIC;
    stat_rx_internal_local_fault_0 : OUT STD_LOGIC;
    stat_rx_received_local_fault_0 : OUT STD_LOGIC;
    stat_rx_hi_ber_0 : OUT STD_LOGIC;
    stat_rx_got_signal_os_0 : OUT STD_LOGIC;
    stat_rx_test_pattern_mismatch_0 : OUT STD_LOGIC;
    stat_rx_total_bytes_0 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    stat_rx_total_packets_0 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    stat_rx_total_good_bytes_0 : OUT STD_LOGIC_VECTOR(13 DOWNTO 0);
    stat_rx_total_good_packets_0 : OUT STD_LOGIC;
    stat_rx_packet_bad_fcs_0 : OUT STD_LOGIC;
    stat_rx_packet_64_bytes_0 : OUT STD_LOGIC;
    stat_rx_packet_65_127_bytes_0 : OUT STD_LOGIC;
    stat_rx_packet_128_255_bytes_0 : OUT STD_LOGIC;
    stat_rx_packet_256_511_bytes_0 : OUT STD_LOGIC;
    stat_rx_packet_512_1023_bytes_0 : OUT STD_LOGIC;
    stat_rx_packet_1024_1518_bytes_0 : OUT STD_LOGIC;
    stat_rx_packet_1519_1522_bytes_0 : OUT STD_LOGIC;
    stat_rx_packet_1523_1548_bytes_0 : OUT STD_LOGIC;
    stat_rx_packet_1549_2047_bytes_0 : OUT STD_LOGIC;
    stat_rx_packet_2048_4095_bytes_0 : OUT STD_LOGIC;
    stat_rx_packet_4096_8191_bytes_0 : OUT STD_LOGIC;
    stat_rx_packet_8192_9215_bytes_0 : OUT STD_LOGIC;
    stat_rx_packet_small_0 : OUT STD_LOGIC;
    stat_rx_packet_large_0 : OUT STD_LOGIC;
    stat_rx_unicast_0 : OUT STD_LOGIC;
    stat_rx_multicast_0 : OUT STD_LOGIC;
    stat_rx_broadcast_0 : OUT STD_LOGIC;
    stat_rx_oversize_0 : OUT STD_LOGIC;
    stat_rx_toolong_0 : OUT STD_LOGIC;
    stat_rx_undersize_0 : OUT STD_LOGIC;
    stat_rx_fragment_0 : OUT STD_LOGIC;
    stat_rx_vlan_0 : OUT STD_LOGIC;
    stat_rx_inrangeerr_0 : OUT STD_LOGIC;
    stat_rx_jabber_0 : OUT STD_LOGIC;
    stat_rx_bad_code_0 : OUT STD_LOGIC;
    stat_rx_bad_sfd_0 : OUT STD_LOGIC;
    stat_rx_bad_preamble_0 : OUT STD_LOGIC;
    stat_tx_ptp_fifo_read_error_0 : OUT STD_LOGIC;
    stat_tx_ptp_fifo_write_error_0 : OUT STD_LOGIC;
    tx_reset_0 : IN STD_LOGIC;
    user_tx_reset_0 : OUT STD_LOGIC;
    tx_axis_tready_0 : OUT STD_LOGIC;
    tx_axis_tvalid_0 : IN STD_LOGIC;
    tx_axis_tdata_0 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    tx_axis_tlast_0 : IN STD_LOGIC;
    tx_axis_tkeep_0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    tx_axis_tuser_0 : IN STD_LOGIC;
    tx_unfout_0 : OUT STD_LOGIC;
    tx_preamblein_0 : IN STD_LOGIC_VECTOR(55 DOWNTO 0);
    rx_preambleout_0 : OUT STD_LOGIC_VECTOR(55 DOWNTO 0);
    tx_ptp_1588op_in_0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    tx_ptp_tag_field_in_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    tx_ptp_tstamp_valid_out_0 : OUT STD_LOGIC;
    rx_ptp_tstamp_valid_out_0 : OUT STD_LOGIC;
    tx_ptp_tstamp_tag_out_0 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    tx_ptp_tstamp_out_0 : OUT STD_LOGIC_VECTOR(79 DOWNTO 0);
    rx_ptp_tstamp_out_0 : OUT STD_LOGIC_VECTOR(79 DOWNTO 0);
    stat_tx_local_fault_0 : OUT STD_LOGIC;
    stat_tx_total_bytes_0 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    stat_tx_total_packets_0 : OUT STD_LOGIC;
    stat_tx_total_good_bytes_0 : OUT STD_LOGIC_VECTOR(13 DOWNTO 0);
    stat_tx_total_good_packets_0 : OUT STD_LOGIC;
    stat_tx_bad_fcs_0 : OUT STD_LOGIC;
    stat_tx_packet_64_bytes_0 : OUT STD_LOGIC;
    stat_tx_packet_65_127_bytes_0 : OUT STD_LOGIC;
    stat_tx_packet_128_255_bytes_0 : OUT STD_LOGIC;
    stat_tx_packet_256_511_bytes_0 : OUT STD_LOGIC;
    stat_tx_packet_512_1023_bytes_0 : OUT STD_LOGIC;
    stat_tx_packet_1024_1518_bytes_0 : OUT STD_LOGIC;
    stat_tx_packet_1519_1522_bytes_0 : OUT STD_LOGIC;
    stat_tx_packet_1523_1548_bytes_0 : OUT STD_LOGIC;
    stat_tx_packet_1549_2047_bytes_0 : OUT STD_LOGIC;
    stat_tx_packet_2048_4095_bytes_0 : OUT STD_LOGIC;
    stat_tx_packet_4096_8191_bytes_0 : OUT STD_LOGIC;
    stat_tx_packet_8192_9215_bytes_0 : OUT STD_LOGIC;
    stat_tx_packet_small_0 : OUT STD_LOGIC;
    stat_tx_packet_large_0 : OUT STD_LOGIC;
    stat_tx_unicast_0 : OUT STD_LOGIC;
    stat_tx_multicast_0 : OUT STD_LOGIC;
    stat_tx_broadcast_0 : OUT STD_LOGIC;
    stat_tx_vlan_0 : OUT STD_LOGIC;
    stat_tx_frame_error_0 : OUT STD_LOGIC;
    stat_tx_pause_0 : OUT STD_LOGIC;
    stat_tx_user_pause_0 : OUT STD_LOGIC;
    stat_tx_pause_valid_0 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    ctl_tx_pause_req_0 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    ctl_tx_resend_pause_0 : IN STD_LOGIC;
    ctl_tx_pause_enable_0 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    ctl_tx_pause_quanta0_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_tx_pause_quanta1_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_tx_pause_quanta2_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_tx_pause_quanta3_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_tx_pause_quanta4_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_tx_pause_quanta5_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_tx_pause_quanta6_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_tx_pause_quanta7_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_tx_pause_quanta8_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_tx_pause_refresh_timer0_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_tx_pause_refresh_timer1_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_tx_pause_refresh_timer2_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_tx_pause_refresh_timer3_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_tx_pause_refresh_timer4_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_tx_pause_refresh_timer5_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_tx_pause_refresh_timer6_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_tx_pause_refresh_timer7_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_tx_pause_refresh_timer8_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_tx_da_gpp_0 : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
    ctl_tx_sa_gpp_0 : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
    ctl_tx_ethertype_gpp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_tx_opcode_gpp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_tx_da_ppp_0 : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
    ctl_tx_sa_ppp_0 : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
    ctl_tx_ethertype_ppp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_tx_opcode_ppp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    ctl_tx_enable_0 : IN STD_LOGIC;
    ctl_tx_systemtimerin_0 : IN STD_LOGIC_VECTOR(79 DOWNTO 0);
    ctl_rx_systemtimerin_0 : IN STD_LOGIC_VECTOR(79 DOWNTO 0);
    ctl_tx_send_rfi_0 : IN STD_LOGIC;
    ctl_tx_send_lfi_0 : IN STD_LOGIC;
    ctl_tx_send_idle_0 : IN STD_LOGIC;
    ctl_tx_fcs_ins_enable_0 : IN STD_LOGIC;
    ctl_tx_ignore_fcs_0 : IN STD_LOGIC;
    ctl_tx_test_pattern_0 : IN STD_LOGIC;
    ctl_tx_test_pattern_enable_0 : IN STD_LOGIC;
    ctl_tx_test_pattern_select_0 : IN STD_LOGIC;
    ctl_tx_data_pattern_select_0 : IN STD_LOGIC;
    ctl_tx_test_pattern_seed_a_0 : IN STD_LOGIC_VECTOR(57 DOWNTO 0);
    ctl_tx_test_pattern_seed_b_0 : IN STD_LOGIC_VECTOR(57 DOWNTO 0);
    ctl_tx_ipg_value_0 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    ctl_tx_custom_preamble_enable_0 : IN STD_LOGIC;
    gt_loopback_in_0 : IN STD_LOGIC_VECTOR(2 DOWNTO 0)
  );
END mac_10g_226_2;

ARCHITECTURE str OF mac_10g_226_2 IS

   COMPONENT mac_10g_226_2_gth
     PORT (
       gt_txp_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
       gt_txn_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
       gt_rxp_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
       gt_rxn_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
       rx_core_clk_0 : IN STD_LOGIC;
       txoutclksel_in_0 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
       rxoutclksel_in_0 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
       gt_dmonitorout_0 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
       gt_eyescandataerror_0 : OUT STD_LOGIC;
       gt_eyescanreset_0 : IN STD_LOGIC;
       gt_eyescantrigger_0 : IN STD_LOGIC;
       gt_pcsrsvdin_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       gt_rxbufreset_0 : IN STD_LOGIC;
       gt_rxbufstatus_0 : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
       gt_rxcdrhold_0 : IN STD_LOGIC;
       gt_rxcommadeten_0 : IN STD_LOGIC;
       gt_rxdfeagchold_0 : IN STD_LOGIC;
       gt_rxdfelpmreset_0 : IN STD_LOGIC;
       gt_rxlatclk_0 : IN STD_LOGIC;
       gt_rxlpmen_0 : IN STD_LOGIC;
       gt_rxpcsreset_0 : IN STD_LOGIC;
       gt_rxpmareset_0 : IN STD_LOGIC;
       gt_rxpolarity_0 : IN STD_LOGIC;
       gt_rxprbscntreset_0 : IN STD_LOGIC;
       gt_rxprbserr_0 : OUT STD_LOGIC;
       gt_rxprbssel_0 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
       gt_rxrate_0 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
       gt_rxslide_in_0 : IN STD_LOGIC;
       gt_rxstartofseq_0 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
       gt_txbufstatus_0 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
       gt_txdiffctrl_0 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
       gt_txinhibit_0 : IN STD_LOGIC;
       gt_txlatclk_0 : IN STD_LOGIC;
       gt_txmaincursor_0 : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
       gt_txpcsreset_0 : IN STD_LOGIC;
       gt_txpmareset_0 : IN STD_LOGIC;
       gt_txpolarity_0 : IN STD_LOGIC;
       gt_txpostcursor_0 : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
       gt_txprbsforceerr_0 : IN STD_LOGIC;
       gt_txprbssel_0 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
       gt_txprecursor_0 : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
       gtwiz_reset_tx_datapath_0 : IN STD_LOGIC;
       gtwiz_reset_rx_datapath_0 : IN STD_LOGIC;
       rxrecclkout_0 : OUT STD_LOGIC;
       gt_drpclk_0 : IN STD_LOGIC;
       gt_drpdo_0 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
       gt_drprdy_0 : OUT STD_LOGIC;
       gt_drpen_0 : IN STD_LOGIC;
       gt_drpwe_0 : IN STD_LOGIC;
       gt_drpaddr_0 : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
       gt_drpdi_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       sys_reset : IN STD_LOGIC;
       dclk : IN STD_LOGIC;
       tx_clk_out_0 : OUT STD_LOGIC;
       rx_clk_out_0 : OUT STD_LOGIC;
       gt_refclk_p : IN STD_LOGIC;
       gt_refclk_n : IN STD_LOGIC;
       gt_refclk_out : OUT STD_LOGIC;
       gtpowergood_out_0 : OUT STD_LOGIC;
       rx_reset_0 : IN STD_LOGIC;
       user_rx_reset_0 : OUT STD_LOGIC;
       rx_axis_tvalid_0 : OUT STD_LOGIC;
       rx_axis_tdata_0 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
       rx_axis_tlast_0 : OUT STD_LOGIC;
       rx_axis_tkeep_0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
       rx_axis_tuser_0 : OUT STD_LOGIC;
       ctl_rx_enable_0 : IN STD_LOGIC;
       ctl_rx_check_preamble_0 : IN STD_LOGIC;
       ctl_rx_check_sfd_0 : IN STD_LOGIC;
       ctl_rx_force_resync_0 : IN STD_LOGIC;
       ctl_rx_delete_fcs_0 : IN STD_LOGIC;
       ctl_rx_ignore_fcs_0 : IN STD_LOGIC;
       ctl_rx_max_packet_len_0 : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
       ctl_rx_min_packet_len_0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
       ctl_rx_process_lfi_0 : IN STD_LOGIC;
       ctl_rx_test_pattern_0 : IN STD_LOGIC;
       ctl_rx_data_pattern_select_0 : IN STD_LOGIC;
       ctl_rx_test_pattern_enable_0 : IN STD_LOGIC;
       ctl_rx_custom_preamble_enable_0 : IN STD_LOGIC;
       ctl_rx_pause_enable_0 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
       ctl_rx_enable_gcp_0 : IN STD_LOGIC;
       ctl_rx_check_mcast_gcp_0 : IN STD_LOGIC;
       ctl_rx_check_ucast_gcp_0 : IN STD_LOGIC;
       ctl_rx_pause_da_ucast_0 : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
       ctl_rx_check_sa_gcp_0 : IN STD_LOGIC;
       ctl_rx_pause_sa_0 : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
       ctl_rx_check_etype_gcp_0 : IN STD_LOGIC;
       ctl_rx_check_opcode_gcp_0 : IN STD_LOGIC;
       ctl_rx_opcode_min_gcp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_rx_opcode_max_gcp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_rx_etype_gcp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_rx_enable_pcp_0 : IN STD_LOGIC;
       ctl_rx_check_mcast_pcp_0 : IN STD_LOGIC;
       ctl_rx_check_ucast_pcp_0 : IN STD_LOGIC;
       ctl_rx_pause_da_mcast_0 : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
       ctl_rx_check_sa_pcp_0 : IN STD_LOGIC;
       ctl_rx_check_etype_pcp_0 : IN STD_LOGIC;
       ctl_rx_etype_pcp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_rx_check_opcode_pcp_0 : IN STD_LOGIC;
       ctl_rx_opcode_min_pcp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_rx_opcode_max_pcp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_rx_enable_gpp_0 : IN STD_LOGIC;
       ctl_rx_check_mcast_gpp_0 : IN STD_LOGIC;
       ctl_rx_check_ucast_gpp_0 : IN STD_LOGIC;
       ctl_rx_check_sa_gpp_0 : IN STD_LOGIC;
       ctl_rx_check_etype_gpp_0 : IN STD_LOGIC;
       ctl_rx_etype_gpp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_rx_check_opcode_gpp_0 : IN STD_LOGIC;
       ctl_rx_opcode_gpp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_rx_enable_ppp_0 : IN STD_LOGIC;
       ctl_rx_check_mcast_ppp_0 : IN STD_LOGIC;
       ctl_rx_check_ucast_ppp_0 : IN STD_LOGIC;
       ctl_rx_check_sa_ppp_0 : IN STD_LOGIC;
       ctl_rx_check_etype_ppp_0 : IN STD_LOGIC;
       ctl_rx_etype_ppp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_rx_check_opcode_ppp_0 : IN STD_LOGIC;
       ctl_rx_opcode_ppp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_rx_pause_ack_0 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
       ctl_rx_check_ack_0 : IN STD_LOGIC;
       ctl_rx_forward_control_0 : IN STD_LOGIC;
       stat_rx_pause_req_0 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
       stat_rx_pause_valid_0 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
       stat_rx_pause_quanta0_0 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
       stat_rx_pause_quanta1_0 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
       stat_rx_pause_quanta2_0 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
       stat_rx_pause_quanta3_0 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
       stat_rx_pause_quanta4_0 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
       stat_rx_pause_quanta5_0 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
       stat_rx_pause_quanta6_0 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
       stat_rx_pause_quanta7_0 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
       stat_rx_pause_quanta8_0 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
       stat_rx_pause_0 : OUT STD_LOGIC;
       stat_rx_user_pause_0 : OUT STD_LOGIC;
       stat_rx_framing_err_0 : OUT STD_LOGIC;
       stat_rx_framing_err_valid_0 : OUT STD_LOGIC;
       stat_rx_local_fault_0 : OUT STD_LOGIC;
       stat_rx_block_lock_0 : OUT STD_LOGIC;
       stat_rx_valid_ctrl_code_0 : OUT STD_LOGIC;
       stat_rx_status_0 : OUT STD_LOGIC;
       stat_rx_remote_fault_0 : OUT STD_LOGIC;
       stat_rx_bad_fcs_0 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
       stat_rx_stomped_fcs_0 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
       stat_rx_truncated_0 : OUT STD_LOGIC;
       stat_rx_internal_local_fault_0 : OUT STD_LOGIC;
       stat_rx_received_local_fault_0 : OUT STD_LOGIC;
       stat_rx_hi_ber_0 : OUT STD_LOGIC;
       stat_rx_got_signal_os_0 : OUT STD_LOGIC;
       stat_rx_test_pattern_mismatch_0 : OUT STD_LOGIC;
       stat_rx_total_bytes_0 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
       stat_rx_total_packets_0 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
       stat_rx_total_good_bytes_0 : OUT STD_LOGIC_VECTOR(13 DOWNTO 0);
       stat_rx_total_good_packets_0 : OUT STD_LOGIC;
       stat_rx_packet_bad_fcs_0 : OUT STD_LOGIC;
       stat_rx_packet_64_bytes_0 : OUT STD_LOGIC;
       stat_rx_packet_65_127_bytes_0 : OUT STD_LOGIC;
       stat_rx_packet_128_255_bytes_0 : OUT STD_LOGIC;
       stat_rx_packet_256_511_bytes_0 : OUT STD_LOGIC;
       stat_rx_packet_512_1023_bytes_0 : OUT STD_LOGIC;
       stat_rx_packet_1024_1518_bytes_0 : OUT STD_LOGIC;
       stat_rx_packet_1519_1522_bytes_0 : OUT STD_LOGIC;
       stat_rx_packet_1523_1548_bytes_0 : OUT STD_LOGIC;
       stat_rx_packet_1549_2047_bytes_0 : OUT STD_LOGIC;
       stat_rx_packet_2048_4095_bytes_0 : OUT STD_LOGIC;
       stat_rx_packet_4096_8191_bytes_0 : OUT STD_LOGIC;
       stat_rx_packet_8192_9215_bytes_0 : OUT STD_LOGIC;
       stat_rx_packet_small_0 : OUT STD_LOGIC;
       stat_rx_packet_large_0 : OUT STD_LOGIC;
       stat_rx_unicast_0 : OUT STD_LOGIC;
       stat_rx_multicast_0 : OUT STD_LOGIC;
       stat_rx_broadcast_0 : OUT STD_LOGIC;
       stat_rx_oversize_0 : OUT STD_LOGIC;
       stat_rx_toolong_0 : OUT STD_LOGIC;
       stat_rx_undersize_0 : OUT STD_LOGIC;
       stat_rx_fragment_0 : OUT STD_LOGIC;
       stat_rx_vlan_0 : OUT STD_LOGIC;
       stat_rx_inrangeerr_0 : OUT STD_LOGIC;
       stat_rx_jabber_0 : OUT STD_LOGIC;
       stat_rx_bad_code_0 : OUT STD_LOGIC;
       stat_rx_bad_sfd_0 : OUT STD_LOGIC;
       stat_rx_bad_preamble_0 : OUT STD_LOGIC;
       stat_tx_ptp_fifo_read_error_0 : OUT STD_LOGIC;
       stat_tx_ptp_fifo_write_error_0 : OUT STD_LOGIC;
       tx_reset_0 : IN STD_LOGIC;
       user_tx_reset_0 : OUT STD_LOGIC;
       tx_axis_tready_0 : OUT STD_LOGIC;
       tx_axis_tvalid_0 : IN STD_LOGIC;
       tx_axis_tdata_0 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
       tx_axis_tlast_0 : IN STD_LOGIC;
       tx_axis_tkeep_0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
       tx_axis_tuser_0 : IN STD_LOGIC;
       tx_unfout_0 : OUT STD_LOGIC;
       tx_preamblein_0 : IN STD_LOGIC_VECTOR(55 DOWNTO 0);
       rx_preambleout_0 : OUT STD_LOGIC_VECTOR(55 DOWNTO 0);
       tx_ptp_1588op_in_0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
       tx_ptp_tag_field_in_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       tx_ptp_tstamp_valid_out_0 : OUT STD_LOGIC;
       rx_ptp_tstamp_valid_out_0 : OUT STD_LOGIC;
       tx_ptp_tstamp_tag_out_0 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
       tx_ptp_tstamp_out_0 : OUT STD_LOGIC_VECTOR(79 DOWNTO 0);
       rx_ptp_tstamp_out_0 : OUT STD_LOGIC_VECTOR(79 DOWNTO 0);
       stat_tx_local_fault_0 : OUT STD_LOGIC;
       stat_tx_total_bytes_0 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
       stat_tx_total_packets_0 : OUT STD_LOGIC;
       stat_tx_total_good_bytes_0 : OUT STD_LOGIC_VECTOR(13 DOWNTO 0);
       stat_tx_total_good_packets_0 : OUT STD_LOGIC;
       stat_tx_bad_fcs_0 : OUT STD_LOGIC;
       stat_tx_packet_64_bytes_0 : OUT STD_LOGIC;
       stat_tx_packet_65_127_bytes_0 : OUT STD_LOGIC;
       stat_tx_packet_128_255_bytes_0 : OUT STD_LOGIC;
       stat_tx_packet_256_511_bytes_0 : OUT STD_LOGIC;
       stat_tx_packet_512_1023_bytes_0 : OUT STD_LOGIC;
       stat_tx_packet_1024_1518_bytes_0 : OUT STD_LOGIC;
       stat_tx_packet_1519_1522_bytes_0 : OUT STD_LOGIC;
       stat_tx_packet_1523_1548_bytes_0 : OUT STD_LOGIC;
       stat_tx_packet_1549_2047_bytes_0 : OUT STD_LOGIC;
       stat_tx_packet_2048_4095_bytes_0 : OUT STD_LOGIC;
       stat_tx_packet_4096_8191_bytes_0 : OUT STD_LOGIC;
       stat_tx_packet_8192_9215_bytes_0 : OUT STD_LOGIC;
       stat_tx_packet_small_0 : OUT STD_LOGIC;
       stat_tx_packet_large_0 : OUT STD_LOGIC;
       stat_tx_unicast_0 : OUT STD_LOGIC;
       stat_tx_multicast_0 : OUT STD_LOGIC;
       stat_tx_broadcast_0 : OUT STD_LOGIC;
       stat_tx_vlan_0 : OUT STD_LOGIC;
       stat_tx_frame_error_0 : OUT STD_LOGIC;
       stat_tx_pause_0 : OUT STD_LOGIC;
       stat_tx_user_pause_0 : OUT STD_LOGIC;
       stat_tx_pause_valid_0 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
       ctl_tx_pause_req_0 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
       ctl_tx_resend_pause_0 : IN STD_LOGIC;
       ctl_tx_pause_enable_0 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
       ctl_tx_pause_quanta0_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_tx_pause_quanta1_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_tx_pause_quanta2_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_tx_pause_quanta3_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_tx_pause_quanta4_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_tx_pause_quanta5_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_tx_pause_quanta6_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_tx_pause_quanta7_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_tx_pause_quanta8_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_tx_pause_refresh_timer0_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_tx_pause_refresh_timer1_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_tx_pause_refresh_timer2_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_tx_pause_refresh_timer3_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_tx_pause_refresh_timer4_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_tx_pause_refresh_timer5_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_tx_pause_refresh_timer6_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_tx_pause_refresh_timer7_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_tx_pause_refresh_timer8_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_tx_da_gpp_0 : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
       ctl_tx_sa_gpp_0 : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
       ctl_tx_ethertype_gpp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_tx_opcode_gpp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_tx_da_ppp_0 : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
       ctl_tx_sa_ppp_0 : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
       ctl_tx_ethertype_ppp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_tx_opcode_ppp_0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
       ctl_tx_enable_0 : IN STD_LOGIC;
       ctl_tx_systemtimerin_0 : IN STD_LOGIC_VECTOR(79 DOWNTO 0);
       ctl_rx_systemtimerin_0 : IN STD_LOGIC_VECTOR(79 DOWNTO 0);
       ctl_tx_send_rfi_0 : IN STD_LOGIC;
       ctl_tx_send_lfi_0 : IN STD_LOGIC;
       ctl_tx_send_idle_0 : IN STD_LOGIC;
       ctl_tx_fcs_ins_enable_0 : IN STD_LOGIC;
       ctl_tx_ignore_fcs_0 : IN STD_LOGIC;
       ctl_tx_test_pattern_0 : IN STD_LOGIC;
       ctl_tx_test_pattern_enable_0 : IN STD_LOGIC;
       ctl_tx_test_pattern_select_0 : IN STD_LOGIC;
       ctl_tx_data_pattern_select_0 : IN STD_LOGIC;
       ctl_tx_test_pattern_seed_a_0 : IN STD_LOGIC_VECTOR(57 DOWNTO 0);
       ctl_tx_test_pattern_seed_b_0 : IN STD_LOGIC_VECTOR(57 DOWNTO 0);
       ctl_tx_ipg_value_0 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
       ctl_tx_custom_preamble_enable_0 : IN STD_LOGIC;
       gt_loopback_in_0 : IN STD_LOGIC_VECTOR(2 DOWNTO 0)
     );
   END COMPONENT;
BEGIN

u_mac_10g_226_2_gth : mac_10g_226_2_gth
   PORT MAP (
      gt_txp_out(0) => gt_txp_out_0,
      gt_txn_out(0) => gt_txn_out_0,
      gt_rxp_in(0) => gt_rxp_in_0,
      gt_rxn_in(0) => gt_rxn_in_0,
      rx_core_clk_0 => rx_core_clk_0,
      txoutclksel_in_0 => txoutclksel_in_0,
      rxoutclksel_in_0 => rxoutclksel_in_0,
      gt_dmonitorout_0 => gt_dmonitorout_0,
      gt_eyescandataerror_0 => gt_eyescandataerror_0,
      gt_eyescanreset_0 => gt_eyescanreset_0,
      gt_eyescantrigger_0 => gt_eyescantrigger_0,
      gt_pcsrsvdin_0 => gt_pcsrsvdin_0,
      gt_rxbufreset_0 => gt_rxbufreset_0,
      gt_rxbufstatus_0 => gt_rxbufstatus_0,
      gt_rxcdrhold_0 => gt_rxcdrhold_0,
      gt_rxcommadeten_0 => gt_rxcommadeten_0,
      gt_rxdfeagchold_0 => gt_rxdfeagchold_0,
      gt_rxdfelpmreset_0 => gt_rxdfelpmreset_0,
      gt_rxlatclk_0 => gt_rxlatclk_0,
      gt_rxlpmen_0 => gt_rxlpmen_0,
      gt_rxpcsreset_0 => gt_rxpcsreset_0,
      gt_rxpmareset_0 => gt_rxpmareset_0,
      gt_rxpolarity_0 => gt_rxpolarity_0,
      gt_rxprbscntreset_0 => gt_rxprbscntreset_0,
      gt_rxprbserr_0 => gt_rxprbserr_0,
      gt_rxprbssel_0 => gt_rxprbssel_0,
      gt_rxrate_0 => gt_rxrate_0,
      gt_rxslide_in_0 => gt_rxslide_in_0,
      gt_rxstartofseq_0 => gt_rxstartofseq_0,
      gt_txbufstatus_0 => gt_txbufstatus_0,
      gt_txdiffctrl_0 => gt_txdiffctrl_0(4 DOWNTO 1),
      gt_txinhibit_0 => gt_txinhibit_0,
      gt_txlatclk_0 => gt_txlatclk_0,
      gt_txmaincursor_0 => gt_txmaincursor_0,
      gt_txpcsreset_0 => gt_txpcsreset_0,
      gt_txpmareset_0 => gt_txpmareset_0,
      gt_txpolarity_0 => gt_txpolarity_0,
      gt_txpostcursor_0 => gt_txpostcursor_0,
      gt_txprbsforceerr_0 => gt_txprbsforceerr_0,
      gt_txprbssel_0 => gt_txprbssel_0,
      gt_txprecursor_0 => gt_txprecursor_0,
      gtwiz_reset_tx_datapath_0 => gtwiz_reset_tx_datapath_0,
      gtwiz_reset_rx_datapath_0 => gtwiz_reset_rx_datapath_0,
      rxrecclkout_0 => rxrecclkout_0,
      gt_drpclk_0 => gt_drpclk_0,
      gt_drpdo_0 => gt_drpdo_0,
      gt_drprdy_0 => gt_drprdy_0,
      gt_drpen_0 => gt_drpen_0,
      gt_drpwe_0 => gt_drpwe_0,
      gt_drpaddr_0 => gt_drpaddr_0,
      gt_drpdi_0 => gt_drpdi_0,
      sys_reset => sys_reset,
      dclk => dclk,
      tx_clk_out_0 => tx_clk_out_0,
      rx_clk_out_0 => rx_clk_out_0,
      gt_refclk_p => gt_refclk_p,
      gt_refclk_n => gt_refclk_n,
      gt_refclk_out => gt_refclk_out,
      gtpowergood_out_0 => gtpowergood_out_0,
      rx_reset_0 => rx_reset_0,
      user_rx_reset_0 => user_rx_reset_0,
      rx_axis_tvalid_0 => rx_axis_tvalid_0,
      rx_axis_tdata_0 => rx_axis_tdata_0,
      rx_axis_tlast_0 => rx_axis_tlast_0,
      rx_axis_tkeep_0 => rx_axis_tkeep_0,
      rx_axis_tuser_0 => rx_axis_tuser_0,
      ctl_rx_enable_0 => ctl_rx_enable_0,
      ctl_rx_check_preamble_0 => ctl_rx_check_preamble_0,
      ctl_rx_check_sfd_0 => ctl_rx_check_sfd_0,
      ctl_rx_force_resync_0 => ctl_rx_force_resync_0,
      ctl_rx_delete_fcs_0 => ctl_rx_delete_fcs_0,
      ctl_rx_ignore_fcs_0 => ctl_rx_ignore_fcs_0,
      ctl_rx_max_packet_len_0 => ctl_rx_max_packet_len_0,
      ctl_rx_min_packet_len_0 => ctl_rx_min_packet_len_0,
      ctl_rx_process_lfi_0 => ctl_rx_process_lfi_0,
      ctl_rx_test_pattern_0 => ctl_rx_test_pattern_0,
      ctl_rx_data_pattern_select_0 => ctl_rx_data_pattern_select_0,
      ctl_rx_test_pattern_enable_0 => ctl_rx_test_pattern_enable_0,
      ctl_rx_custom_preamble_enable_0 => ctl_rx_custom_preamble_enable_0,
      ctl_rx_pause_enable_0 => ctl_rx_pause_enable_0,
      ctl_rx_enable_gcp_0 => ctl_rx_enable_gcp_0,
      ctl_rx_check_mcast_gcp_0 => ctl_rx_check_mcast_gcp_0,
      ctl_rx_check_ucast_gcp_0 => ctl_rx_check_ucast_gcp_0,
      ctl_rx_pause_da_ucast_0 => ctl_rx_pause_da_ucast_0,
      ctl_rx_check_sa_gcp_0 => ctl_rx_check_sa_gcp_0,
      ctl_rx_pause_sa_0 => ctl_rx_pause_sa_0,
      ctl_rx_check_etype_gcp_0 => ctl_rx_check_etype_gcp_0,
      ctl_rx_check_opcode_gcp_0 => ctl_rx_check_opcode_gcp_0,
      ctl_rx_opcode_min_gcp_0 => ctl_rx_opcode_min_gcp_0,
      ctl_rx_opcode_max_gcp_0 => ctl_rx_opcode_max_gcp_0,
      ctl_rx_etype_gcp_0 => ctl_rx_etype_gcp_0,
      ctl_rx_enable_pcp_0 => ctl_rx_enable_pcp_0,
      ctl_rx_check_mcast_pcp_0 => ctl_rx_check_mcast_pcp_0,
      ctl_rx_check_ucast_pcp_0 => ctl_rx_check_ucast_pcp_0,
      ctl_rx_pause_da_mcast_0 => ctl_rx_pause_da_mcast_0,
      ctl_rx_check_sa_pcp_0 => ctl_rx_check_sa_pcp_0,
      ctl_rx_check_etype_pcp_0 => ctl_rx_check_etype_pcp_0,
      ctl_rx_etype_pcp_0 => ctl_rx_etype_pcp_0,
      ctl_rx_check_opcode_pcp_0 => ctl_rx_check_opcode_pcp_0,
      ctl_rx_opcode_min_pcp_0 => ctl_rx_opcode_min_pcp_0,
      ctl_rx_opcode_max_pcp_0 => ctl_rx_opcode_max_pcp_0,
      ctl_rx_enable_gpp_0 => ctl_rx_enable_gpp_0,
      ctl_rx_check_mcast_gpp_0 => ctl_rx_check_mcast_gpp_0,
      ctl_rx_check_ucast_gpp_0 => ctl_rx_check_ucast_gpp_0,
      ctl_rx_check_sa_gpp_0 => ctl_rx_check_sa_gpp_0,
      ctl_rx_check_etype_gpp_0 => ctl_rx_check_etype_gpp_0,
      ctl_rx_etype_gpp_0 => ctl_rx_etype_gpp_0,
      ctl_rx_check_opcode_gpp_0 => ctl_rx_check_opcode_gpp_0,
      ctl_rx_opcode_gpp_0 => ctl_rx_opcode_gpp_0,
      ctl_rx_enable_ppp_0 => ctl_rx_enable_ppp_0,
      ctl_rx_check_mcast_ppp_0 => ctl_rx_check_mcast_ppp_0,
      ctl_rx_check_ucast_ppp_0 => ctl_rx_check_ucast_ppp_0,
      ctl_rx_check_sa_ppp_0 => ctl_rx_check_sa_ppp_0,
      ctl_rx_check_etype_ppp_0 => ctl_rx_check_etype_ppp_0,
      ctl_rx_etype_ppp_0 => ctl_rx_etype_ppp_0,
      ctl_rx_check_opcode_ppp_0 => ctl_rx_check_opcode_ppp_0,
      ctl_rx_opcode_ppp_0 => ctl_rx_opcode_ppp_0,
      ctl_rx_pause_ack_0 => ctl_rx_pause_ack_0,
      ctl_rx_check_ack_0 => ctl_rx_check_ack_0,
      ctl_rx_forward_control_0 => ctl_rx_forward_control_0,
      stat_rx_pause_req_0 => stat_rx_pause_req_0,
      stat_rx_pause_valid_0 => stat_rx_pause_valid_0,
      stat_rx_pause_quanta0_0 => stat_rx_pause_quanta0_0,
      stat_rx_pause_quanta1_0 => stat_rx_pause_quanta1_0,
      stat_rx_pause_quanta2_0 => stat_rx_pause_quanta2_0,
      stat_rx_pause_quanta3_0 => stat_rx_pause_quanta3_0,
      stat_rx_pause_quanta4_0 => stat_rx_pause_quanta4_0,
      stat_rx_pause_quanta5_0 => stat_rx_pause_quanta5_0,
      stat_rx_pause_quanta6_0 => stat_rx_pause_quanta6_0,
      stat_rx_pause_quanta7_0 => stat_rx_pause_quanta7_0,
      stat_rx_pause_quanta8_0 => stat_rx_pause_quanta8_0,
      stat_rx_pause_0 => stat_rx_pause_0,
      stat_rx_user_pause_0 => stat_rx_user_pause_0,
      stat_rx_framing_err_0 => stat_rx_framing_err_0,
      stat_rx_framing_err_valid_0 => stat_rx_framing_err_valid_0,
      stat_rx_local_fault_0 => stat_rx_local_fault_0,
      stat_rx_block_lock_0 => stat_rx_block_lock_0,
      stat_rx_valid_ctrl_code_0 => stat_rx_valid_ctrl_code_0,
      stat_rx_status_0 => stat_rx_status_0,
      stat_rx_remote_fault_0 => stat_rx_remote_fault_0,
      stat_rx_bad_fcs_0 => stat_rx_bad_fcs_0,
      stat_rx_stomped_fcs_0 => stat_rx_stomped_fcs_0,
      stat_rx_truncated_0 => stat_rx_truncated_0,
      stat_rx_internal_local_fault_0 => stat_rx_internal_local_fault_0,
      stat_rx_received_local_fault_0 => stat_rx_received_local_fault_0,
      stat_rx_hi_ber_0 => stat_rx_hi_ber_0,
      stat_rx_got_signal_os_0 => stat_rx_got_signal_os_0,
      stat_rx_test_pattern_mismatch_0 => stat_rx_test_pattern_mismatch_0,
      stat_rx_total_bytes_0 => stat_rx_total_bytes_0,
      stat_rx_total_packets_0 => stat_rx_total_packets_0,
      stat_rx_total_good_bytes_0 => stat_rx_total_good_bytes_0,
      stat_rx_total_good_packets_0 => stat_rx_total_good_packets_0,
      stat_rx_packet_bad_fcs_0 => stat_rx_packet_bad_fcs_0,
      stat_rx_packet_64_bytes_0 => stat_rx_packet_64_bytes_0,
      stat_rx_packet_65_127_bytes_0 => stat_rx_packet_65_127_bytes_0,
      stat_rx_packet_128_255_bytes_0 => stat_rx_packet_128_255_bytes_0,
      stat_rx_packet_256_511_bytes_0 => stat_rx_packet_256_511_bytes_0,
      stat_rx_packet_512_1023_bytes_0 => stat_rx_packet_512_1023_bytes_0,
      stat_rx_packet_1024_1518_bytes_0 => stat_rx_packet_1024_1518_bytes_0,
      stat_rx_packet_1519_1522_bytes_0 => stat_rx_packet_1519_1522_bytes_0,
      stat_rx_packet_1523_1548_bytes_0 => stat_rx_packet_1523_1548_bytes_0,
      stat_rx_packet_1549_2047_bytes_0 => stat_rx_packet_1549_2047_bytes_0,
      stat_rx_packet_2048_4095_bytes_0 => stat_rx_packet_2048_4095_bytes_0,
      stat_rx_packet_4096_8191_bytes_0 => stat_rx_packet_4096_8191_bytes_0,
      stat_rx_packet_8192_9215_bytes_0 => stat_rx_packet_8192_9215_bytes_0,
      stat_rx_packet_small_0 => stat_rx_packet_small_0,
      stat_rx_packet_large_0 => stat_rx_packet_large_0,
      stat_rx_unicast_0 => stat_rx_unicast_0,
      stat_rx_multicast_0 => stat_rx_multicast_0,
      stat_rx_broadcast_0 => stat_rx_broadcast_0,
      stat_rx_oversize_0 => stat_rx_oversize_0,
      stat_rx_toolong_0 => stat_rx_toolong_0,
      stat_rx_undersize_0 => stat_rx_undersize_0,
      stat_rx_fragment_0 => stat_rx_fragment_0,
      stat_rx_vlan_0 => stat_rx_vlan_0,
      stat_rx_inrangeerr_0 => stat_rx_inrangeerr_0,
      stat_rx_jabber_0 => stat_rx_jabber_0,
      stat_rx_bad_code_0 => stat_rx_bad_code_0,
      stat_rx_bad_sfd_0 => stat_rx_bad_sfd_0,
      stat_rx_bad_preamble_0 => stat_rx_bad_preamble_0,
      stat_tx_ptp_fifo_read_error_0 => stat_tx_ptp_fifo_read_error_0,
      stat_tx_ptp_fifo_write_error_0 => stat_tx_ptp_fifo_write_error_0,
      tx_reset_0 => tx_reset_0,
      user_tx_reset_0 => user_tx_reset_0,
      tx_axis_tready_0 => tx_axis_tready_0,
      tx_axis_tvalid_0 => tx_axis_tvalid_0,
      tx_axis_tdata_0 => tx_axis_tdata_0,
      tx_axis_tlast_0 => tx_axis_tlast_0,
      tx_axis_tkeep_0 => tx_axis_tkeep_0,
      tx_axis_tuser_0 => tx_axis_tuser_0,
      tx_unfout_0 => tx_unfout_0,
      tx_preamblein_0 => tx_preamblein_0,
      rx_preambleout_0 => rx_preambleout_0,
      tx_ptp_1588op_in_0 => tx_ptp_1588op_in_0,
      tx_ptp_tag_field_in_0 => tx_ptp_tag_field_in_0,
      tx_ptp_tstamp_valid_out_0 => tx_ptp_tstamp_valid_out_0,
      rx_ptp_tstamp_valid_out_0 => rx_ptp_tstamp_valid_out_0,
      tx_ptp_tstamp_tag_out_0 => tx_ptp_tstamp_tag_out_0,
      tx_ptp_tstamp_out_0 => tx_ptp_tstamp_out_0,
      rx_ptp_tstamp_out_0 => rx_ptp_tstamp_out_0,
      stat_tx_local_fault_0 => stat_tx_local_fault_0,
      stat_tx_total_bytes_0 => stat_tx_total_bytes_0,
      stat_tx_total_packets_0 => stat_tx_total_packets_0,
      stat_tx_total_good_bytes_0 => stat_tx_total_good_bytes_0,
      stat_tx_total_good_packets_0 => stat_tx_total_good_packets_0,
      stat_tx_bad_fcs_0 => stat_tx_bad_fcs_0,
      stat_tx_packet_64_bytes_0 => stat_tx_packet_64_bytes_0,
      stat_tx_packet_65_127_bytes_0 => stat_tx_packet_65_127_bytes_0,
      stat_tx_packet_128_255_bytes_0 => stat_tx_packet_128_255_bytes_0,
      stat_tx_packet_256_511_bytes_0 => stat_tx_packet_256_511_bytes_0,
      stat_tx_packet_512_1023_bytes_0 => stat_tx_packet_512_1023_bytes_0,
      stat_tx_packet_1024_1518_bytes_0 => stat_tx_packet_1024_1518_bytes_0,
      stat_tx_packet_1519_1522_bytes_0 => stat_tx_packet_1519_1522_bytes_0,
      stat_tx_packet_1523_1548_bytes_0 => stat_tx_packet_1523_1548_bytes_0,
      stat_tx_packet_1549_2047_bytes_0 => stat_tx_packet_1549_2047_bytes_0,
      stat_tx_packet_2048_4095_bytes_0 => stat_tx_packet_2048_4095_bytes_0,
      stat_tx_packet_4096_8191_bytes_0 => stat_tx_packet_4096_8191_bytes_0,
      stat_tx_packet_8192_9215_bytes_0 => stat_tx_packet_8192_9215_bytes_0,
      stat_tx_packet_small_0 => stat_tx_packet_small_0,
      stat_tx_packet_large_0 => stat_tx_packet_large_0,
      stat_tx_unicast_0 => stat_tx_unicast_0,
      stat_tx_multicast_0 => stat_tx_multicast_0,
      stat_tx_broadcast_0 => stat_tx_broadcast_0,
      stat_tx_vlan_0 => stat_tx_vlan_0,
      stat_tx_frame_error_0 => stat_tx_frame_error_0,
      stat_tx_pause_0 => stat_tx_pause_0,
      stat_tx_user_pause_0 => stat_tx_user_pause_0,
      stat_tx_pause_valid_0 => stat_tx_pause_valid_0,
      ctl_tx_pause_req_0 => ctl_tx_pause_req_0,
      ctl_tx_resend_pause_0 => ctl_tx_resend_pause_0,
      ctl_tx_pause_enable_0 => ctl_tx_pause_enable_0,
      ctl_tx_pause_quanta0_0 => ctl_tx_pause_quanta0_0,
      ctl_tx_pause_quanta1_0 => ctl_tx_pause_quanta1_0,
      ctl_tx_pause_quanta2_0 => ctl_tx_pause_quanta2_0,
      ctl_tx_pause_quanta3_0 => ctl_tx_pause_quanta3_0,
      ctl_tx_pause_quanta4_0 => ctl_tx_pause_quanta4_0,
      ctl_tx_pause_quanta5_0 => ctl_tx_pause_quanta5_0,
      ctl_tx_pause_quanta6_0 => ctl_tx_pause_quanta6_0,
      ctl_tx_pause_quanta7_0 => ctl_tx_pause_quanta7_0,
      ctl_tx_pause_quanta8_0 => ctl_tx_pause_quanta8_0,
      ctl_tx_pause_refresh_timer0_0 => ctl_tx_pause_refresh_timer0_0,
      ctl_tx_pause_refresh_timer1_0 => ctl_tx_pause_refresh_timer1_0,
      ctl_tx_pause_refresh_timer2_0 => ctl_tx_pause_refresh_timer2_0,
      ctl_tx_pause_refresh_timer3_0 => ctl_tx_pause_refresh_timer3_0,
      ctl_tx_pause_refresh_timer4_0 => ctl_tx_pause_refresh_timer4_0,
      ctl_tx_pause_refresh_timer5_0 => ctl_tx_pause_refresh_timer5_0,
      ctl_tx_pause_refresh_timer6_0 => ctl_tx_pause_refresh_timer6_0,
      ctl_tx_pause_refresh_timer7_0 => ctl_tx_pause_refresh_timer7_0,
      ctl_tx_pause_refresh_timer8_0 => ctl_tx_pause_refresh_timer8_0,
      ctl_tx_da_gpp_0 => ctl_tx_da_gpp_0,
      ctl_tx_sa_gpp_0 => ctl_tx_sa_gpp_0,
      ctl_tx_ethertype_gpp_0 => ctl_tx_ethertype_gpp_0,
      ctl_tx_opcode_gpp_0 => ctl_tx_opcode_gpp_0,
      ctl_tx_da_ppp_0 => ctl_tx_da_ppp_0,
      ctl_tx_sa_ppp_0 => ctl_tx_sa_ppp_0,
      ctl_tx_ethertype_ppp_0 => ctl_tx_ethertype_ppp_0,
      ctl_tx_opcode_ppp_0 => ctl_tx_opcode_ppp_0,
      ctl_tx_enable_0 => ctl_tx_enable_0,
      ctl_tx_systemtimerin_0 => ctl_tx_systemtimerin_0,
      ctl_rx_systemtimerin_0 => ctl_rx_systemtimerin_0,
      ctl_tx_send_rfi_0 => ctl_tx_send_rfi_0,
      ctl_tx_send_lfi_0 => ctl_tx_send_lfi_0,
      ctl_tx_send_idle_0 => ctl_tx_send_idle_0,
      ctl_tx_fcs_ins_enable_0 => ctl_tx_fcs_ins_enable_0,
      ctl_tx_ignore_fcs_0 => ctl_tx_ignore_fcs_0,
      ctl_tx_test_pattern_0 => ctl_tx_test_pattern_0,
      ctl_tx_test_pattern_enable_0 => ctl_tx_test_pattern_enable_0,
      ctl_tx_test_pattern_select_0 => ctl_tx_test_pattern_select_0,
      ctl_tx_data_pattern_select_0 => ctl_tx_data_pattern_select_0,
      ctl_tx_test_pattern_seed_a_0 => ctl_tx_test_pattern_seed_a_0,
      ctl_tx_test_pattern_seed_b_0 => ctl_tx_test_pattern_seed_b_0,
      ctl_tx_ipg_value_0 => ctl_tx_ipg_value_0,
      ctl_tx_custom_preamble_enable_0 => ctl_tx_custom_preamble_enable_0,
      gt_loopback_in_0 => gt_loopback_in_0
  );

END str;

