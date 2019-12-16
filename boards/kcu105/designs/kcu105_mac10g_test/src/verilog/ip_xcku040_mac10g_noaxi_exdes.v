////------------------------------------------------------------------------------
////  (c) Copyright 2013 Xilinx, Inc. All rights reserved.
////
////  This file contains confidential and proprietary information
////  of Xilinx, Inc. and is protected under U.S. and
////  international copyright and other intellectual property
////  laws.
////
////  DISCLAIMER
////  This disclaimer is not a license and does not grant any
////  rights to the materials distributed herewith. Except as
////  otherwise provided in a valid license issued to you by
////  Xilinx, and to the maximum extent permitted by applicable
////  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
////  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
////  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
////  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
////  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
////  (2) Xilinx shall not be liable (whether in contract or tort,
////  including negligence, or under any other theory of
////  liability) for any loss or damage of any kind or nature
////  related to, arising under or in connection with these
////  materials, including for any direct, or any indirect,
////  special, incidental, or consequential loss or damage
////  (including loss of data, profits, goodwill, or any type of
////  loss or damage suffered as a result of any action brought
////  by a third party) even if such damage or loss was
////  reasonably foreseeable or Xilinx had been advised of the
////  possibility of the same.
////
////  CRITICAL APPLICATIONS
////  Xilinx products are not designed or intended to be fail-
////  safe, or for use in any application requiring fail-safe
////  performance, such as life-support or safety devices or
////  systems, Class III medical devices, nuclear facilities,
////  applications related to the deployment of airbags, or any
////  other applications that could lead to death, personal
////  injury, or severe property or environmental damage
////  (individually and collectively, "Critical
////  Applications"). Customer assumes the sole risk and
////  liability of any use of Xilinx products in Critical
////  Applications, subject only to applicable laws and
////  regulations governing limitations on product liability.
////
////  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
////  PART OF THIS FILE AT ALL TIMES.
////------------------------------------------------------------------------------


`timescale 1fs/1fs

(* DowngradeIPIdentifiedWarnings="yes" *)
module ip_xcku040_mac10g_noaxi_exdes
(
    input  wire [1-1:0] gt_rxp_in,
    input  wire [1-1:0] gt_rxn_in,
    output wire [1-1:0] gt_txp_out,
    output wire [1-1:0] gt_txn_out,
    input wire  restart_tx_rx_0,
    output wire rx_gt_locked_led_0,     // Indicates GT LOCK
    output wire rx_block_lock_led_0,    // Indicates Core Block Lock
    output wire [4:0] completion_status,

    input             sys_reset,
    input             gt_refclk_p,
    input             gt_refclk_n,
    input             dclk_p,
    input             dclk_n
);

  parameter PKT_NUM         = 1;    //// Many Internal Counters are based on PKT_NUM = 20

  wire [2:0] gt_loopback_in_0; 

//// For other GT loopback options please change the value appropriately
//// For example, for internal loopback gt_loopback_in[2:0] = 3'b010;
//// For more information and settings on loopback, refer GT Transceivers user guide

  assign gt_loopback_in_0 = 3'b000;
                                                
  
////GT Transceiver debug interface signals
  wire [16:0] gt_dmonitorout_0;
  wire [0:0] gt_eyescandataerror_0;
  wire [0:0] gt_eyescanreset_0;
  wire [0:0] gt_eyescantrigger_0;
  wire [15:0] gt_pcsrsvdin_0;
  wire [0:0] gt_rxbufreset_0;
  wire [2:0] gt_rxbufstatus_0;
  wire [0:0] gt_rxcdrhold_0;
  wire [0:0] gt_rxcommadeten_0;
  wire [0:0] gt_rxdfeagchold_0;
  wire [0:0] gt_rxdfelpmreset_0;
  wire [0:0] gt_rxlatclk_0;
  wire [0:0] gt_rxlpmen_0;
  wire [0:0] gt_rxpcsreset_0;
  wire [0:0] gt_rxpmareset_0;
  wire [0:0] gt_rxpolarity_0;
  wire [0:0] gt_rxprbscntreset_0;
  wire [0:0] gt_rxprbserr_0;
  wire [3:0] gt_rxprbssel_0;
  wire [2:0] gt_rxrate_0;
  wire [0:0] gt_rxslide_in_0;
  wire [1:0] gt_rxstartofseq_0;
  wire [1:0] gt_txbufstatus_0;
  wire [4:0] gt_txdiffctrl_0;
  wire [0:0] gt_txinhibit_0;
  wire [0:0] gt_txlatclk_0;
  wire [6:0] gt_txmaincursor_0;
  wire [0:0] gt_txpcsreset_0;
  wire [0:0] gt_txpmareset_0;
  wire [0:0] gt_txpolarity_0;
  wire [4:0] gt_txpostcursor_0;
  wire [0:0] gt_txprbsforceerr_0;
  wire [3:0] gt_txprbssel_0;
  wire [4:0] gt_txprecursor_0;
////GT DRP interface signals
  wire [15:0] gt_drpdo_0;
  wire [0:0] gt_drprdy_0;
  wire [0:0] gt_drpen_0;
  wire [0:0] gt_drpwe_0;
  wire [9:0] gt_drpaddr_0;
  wire [15:0] gt_drpdi_0;
  wire rx_core_clk_0;
  wire rx_clk_out_0;
  wire tx_clk_out_0;
  //assign rx_core_clk_0 = tx_clk_out_0;
  assign rx_core_clk_0 = rx_clk_out_0;


//// RX_0 Signals
  wire rx_reset_0;
  wire user_rx_reset_0;
  wire rxrecclkout_0;

//// RX_0 User Interface Signals
  wire rx_axis_tvalid_0;
  wire [63:0] rx_axis_tdata_0;
  wire rx_axis_tlast_0;
  wire [7:0] rx_axis_tkeep_0;
  wire rx_axis_tuser_0;
  wire [55:0] rx_preambleout_0;



//// RX_0 Control Signals
  wire ctl_rx_test_pattern_0;
  wire ctl_rx_test_pattern_enable_0;
  wire ctl_rx_data_pattern_select_0;
  wire ctl_rx_enable_0;
  wire ctl_rx_delete_fcs_0;
  wire ctl_rx_ignore_fcs_0;
  wire [14:0] ctl_rx_max_packet_len_0;
  wire [7:0] ctl_rx_min_packet_len_0;
  wire ctl_rx_custom_preamble_enable_0;
  wire ctl_rx_check_sfd_0;
  wire ctl_rx_check_preamble_0;
  wire ctl_rx_process_lfi_0;
  wire ctl_rx_force_resync_0;

  wire ctl_rx_forward_control_0;
  wire [8:0] ctl_rx_pause_ack_0;
  wire ctl_rx_check_ack_0;
  wire [8:0] ctl_rx_pause_enable_0;
  wire ctl_rx_enable_gcp_0;
  wire ctl_rx_check_mcast_gcp_0;
  wire ctl_rx_check_ucast_gcp_0;
  wire [47:0] ctl_rx_pause_da_ucast_0;
  wire ctl_rx_check_sa_gcp_0;
  wire [47:0] ctl_rx_pause_sa_0;
  wire ctl_rx_check_etype_gcp_0;
  wire [15:0] ctl_rx_etype_gcp_0;
  wire ctl_rx_check_opcode_gcp_0;
  wire [15:0] ctl_rx_opcode_min_gcp_0;
  wire [15:0] ctl_rx_opcode_max_gcp_0;
  wire ctl_rx_enable_pcp_0;
  wire ctl_rx_check_mcast_pcp_0;
  wire ctl_rx_check_ucast_pcp_0;
  wire [47:0] ctl_rx_pause_da_mcast_0;
  wire ctl_rx_check_sa_pcp_0;
  wire ctl_rx_check_etype_pcp_0;
  wire [15:0] ctl_rx_etype_pcp_0;
  wire ctl_rx_check_opcode_pcp_0;
  wire [15:0] ctl_rx_opcode_min_pcp_0;
  wire [15:0] ctl_rx_opcode_max_pcp_0;
  wire ctl_rx_enable_gpp_0;
  wire ctl_rx_check_mcast_gpp_0;
  wire ctl_rx_check_ucast_gpp_0;
  wire ctl_rx_check_sa_gpp_0;
  wire ctl_rx_check_etype_gpp_0;
  wire [15:0] ctl_rx_etype_gpp_0;
  wire ctl_rx_check_opcode_gpp_0;
  wire [15:0] ctl_rx_opcode_gpp_0;
  wire ctl_rx_enable_ppp_0;
  wire ctl_rx_check_mcast_ppp_0;
  wire ctl_rx_check_ucast_ppp_0;
  wire ctl_rx_check_sa_ppp_0;
  wire ctl_rx_check_etype_ppp_0;
  wire [15:0] ctl_rx_etype_ppp_0;
  wire ctl_rx_check_opcode_ppp_0;
  wire [15:0] ctl_rx_opcode_ppp_0;

//// RX_0 Stats Signals
  wire stat_rx_block_lock_0;
  wire stat_rx_framing_err_valid_0;
  wire stat_rx_framing_err_0;
  wire stat_rx_hi_ber_0;
  wire stat_rx_valid_ctrl_code_0;
  wire stat_rx_bad_code_0;
  wire [1:0] stat_rx_total_packets_0;
  wire stat_rx_total_good_packets_0;
  wire [3:0] stat_rx_total_bytes_0;
  wire [13:0] stat_rx_total_good_bytes_0;
  wire stat_rx_packet_small_0;
  wire stat_rx_jabber_0;
  wire stat_rx_packet_large_0;
  wire stat_rx_oversize_0;
  wire stat_rx_undersize_0;
  wire stat_rx_toolong_0;
  wire stat_rx_fragment_0;
  wire stat_rx_packet_64_bytes_0;
  wire stat_rx_packet_65_127_bytes_0;
  wire stat_rx_packet_128_255_bytes_0;
  wire stat_rx_packet_256_511_bytes_0;
  wire stat_rx_packet_512_1023_bytes_0;
  wire stat_rx_packet_1024_1518_bytes_0;
  wire stat_rx_packet_1519_1522_bytes_0;
  wire stat_rx_packet_1523_1548_bytes_0;
  wire [1:0] stat_rx_bad_fcs_0;
  wire stat_rx_packet_bad_fcs_0;
  wire [1:0] stat_rx_stomped_fcs_0;
  wire stat_rx_packet_1549_2047_bytes_0;
  wire stat_rx_packet_2048_4095_bytes_0;
  wire stat_rx_packet_4096_8191_bytes_0;
  wire stat_rx_packet_8192_9215_bytes_0;
  wire stat_rx_bad_preamble_0;
  wire stat_rx_bad_sfd_0;
  wire stat_rx_got_signal_os_0;
  wire stat_rx_test_pattern_mismatch_0;
  wire stat_rx_truncated_0;
  wire stat_rx_local_fault_0;
  wire stat_rx_remote_fault_0;
  wire stat_rx_internal_local_fault_0;
  wire stat_rx_received_local_fault_0;
   wire stat_rx_status_0;
  wire stat_rx_unicast_0;
  wire stat_rx_multicast_0;
  wire stat_rx_broadcast_0;
  wire stat_rx_vlan_0;
  wire stat_rx_pause_0;
  wire stat_rx_user_pause_0;
  wire stat_rx_inrangeerr_0;
  wire [8:0] stat_rx_pause_valid_0;
  wire [15:0] stat_rx_pause_quanta0_0;
  wire [15:0] stat_rx_pause_quanta1_0;
  wire [15:0] stat_rx_pause_quanta2_0;
  wire [15:0] stat_rx_pause_quanta3_0;
  wire [15:0] stat_rx_pause_quanta4_0;
  wire [15:0] stat_rx_pause_quanta5_0;
  wire [15:0] stat_rx_pause_quanta6_0;
  wire [15:0] stat_rx_pause_quanta7_0;
  wire [15:0] stat_rx_pause_quanta8_0;
  wire [8:0] stat_rx_pause_req_0;
  wire [1:0] tx_ptp_1588op_in_0;
  wire [15:0] tx_ptp_tag_field_in_0;
  wire tx_ptp_tstamp_valid_out_0;
  wire [15:0] tx_ptp_tstamp_tag_out_0;
  wire [79:0] tx_ptp_tstamp_out_0;
  wire [79:0] rx_ptp_tstamp_out_0;
  wire rx_ptp_tstamp_valid_out_0;
  wire [79:0] ctl_rx_systemtimerin_0;
  wire [79:0] ctl_tx_systemtimerin_0;
  wire stat_tx_ptp_fifo_read_error_0;
  wire stat_tx_ptp_fifo_write_error_0;
//// TX_0 Signals
  wire tx_reset_0;
  wire user_tx_reset_0;

//// TX_0 User Interface Signals
  wire tx_axis_tready_0;
  wire tx_axis_tvalid_0;
  wire [63:0] tx_axis_tdata_0;
  wire tx_axis_tlast_0;
  wire [7:0] tx_axis_tkeep_0;
  wire tx_axis_tuser_0;
  wire tx_unfout_0;
  wire [55:0] tx_preamblein_0;

//// TX_0 Control Signals
  wire ctl_tx_test_pattern_0;
  wire ctl_tx_test_pattern_enable_0;
  wire ctl_tx_test_pattern_select_0;
  wire ctl_tx_data_pattern_select_0;
  wire [57:0] ctl_tx_test_pattern_seed_a_0;
  wire [57:0] ctl_tx_test_pattern_seed_b_0;
  wire ctl_tx_enable_0;
  wire ctl_tx_fcs_ins_enable_0;
  wire [3:0] ctl_tx_ipg_value_0;
  wire ctl_tx_send_lfi_0;
  wire ctl_tx_send_rfi_0;
  wire ctl_tx_send_idle_0;
  wire ctl_tx_custom_preamble_enable_0;
  wire ctl_tx_ignore_fcs_0;

  wire [8:0] ctl_tx_pause_req_0;
  wire [8:0] ctl_tx_pause_enable_0;
  wire ctl_tx_resend_pause_0;
  wire [15:0] ctl_tx_pause_quanta0_0;
  wire [15:0] ctl_tx_pause_refresh_timer0_0;
  wire [15:0] ctl_tx_pause_quanta1_0;
  wire [15:0] ctl_tx_pause_refresh_timer1_0;
  wire [15:0] ctl_tx_pause_quanta2_0;
  wire [15:0] ctl_tx_pause_refresh_timer2_0;
  wire [15:0] ctl_tx_pause_quanta3_0;
  wire [15:0] ctl_tx_pause_refresh_timer3_0;
  wire [15:0] ctl_tx_pause_quanta4_0;
  wire [15:0] ctl_tx_pause_refresh_timer4_0;
  wire [15:0] ctl_tx_pause_quanta5_0;
  wire [15:0] ctl_tx_pause_refresh_timer5_0;
  wire [15:0] ctl_tx_pause_quanta6_0;
  wire [15:0] ctl_tx_pause_refresh_timer6_0;
  wire [15:0] ctl_tx_pause_quanta7_0;
  wire [15:0] ctl_tx_pause_refresh_timer7_0;
  wire [15:0] ctl_tx_pause_quanta8_0;
  wire [15:0] ctl_tx_pause_refresh_timer8_0;
  wire [47:0] ctl_tx_da_gpp_0;
  wire [47:0] ctl_tx_sa_gpp_0;
  wire [15:0] ctl_tx_ethertype_gpp_0;
  wire [15:0] ctl_tx_opcode_gpp_0;
  wire [47:0] ctl_tx_da_ppp_0;
  wire [47:0] ctl_tx_sa_ppp_0;
  wire [15:0] ctl_tx_ethertype_ppp_0;
  wire [15:0] ctl_tx_opcode_ppp_0;

//// TX_0 Stats Signals
  wire stat_tx_total_packets_0;
  wire [3:0] stat_tx_total_bytes_0;
  wire stat_tx_total_good_packets_0;
  wire [13:0] stat_tx_total_good_bytes_0;
  wire stat_tx_packet_64_bytes_0;
  wire stat_tx_packet_65_127_bytes_0;
  wire stat_tx_packet_128_255_bytes_0;
  wire stat_tx_packet_256_511_bytes_0;
  wire stat_tx_packet_512_1023_bytes_0;
  wire stat_tx_packet_1024_1518_bytes_0;
  wire stat_tx_packet_1519_1522_bytes_0;
  wire stat_tx_packet_1523_1548_bytes_0;
  wire stat_tx_packet_small_0;
  wire stat_tx_packet_large_0;
  wire stat_tx_packet_1549_2047_bytes_0;
  wire stat_tx_packet_2048_4095_bytes_0;
  wire stat_tx_packet_4096_8191_bytes_0;
  wire stat_tx_packet_8192_9215_bytes_0;
  wire stat_tx_bad_fcs_0;
  wire stat_tx_frame_error_0;
  wire stat_tx_local_fault_0;

  wire stat_tx_unicast_0;
  wire stat_tx_multicast_0;
  wire stat_tx_broadcast_0;
  wire stat_tx_vlan_0;
  wire stat_tx_pause_0;
  wire stat_tx_user_pause_0;
  wire [8:0] stat_tx_pause_valid_0;





//// FEC Stats Signals

   wire gtpowergood_out_0;

  wire  [4:0 ]completion_status_0;
  wire  gt_refclk_out;
  wire  dclk;

IBUFDS#(
.DQS_BIAS("FALSE")//(FALSE,TRUE)
)
IBUFDS_inst(
.O(dclk),//1-bitoutput:Bufferoutput
.I(dclk_p),//1-bitinput:Diff_pbufferinput(connectdirectlytotop-levelport)
.IB(dclk_n)//1-bitinput:Diff_nbufferinput(connectdirectlytotop-levelport)
);
//EndofI


ip_xcku040_mac10g_noaxi_trans_debug i_ip_xcku040_mac10g_noaxi_trans_debug
(
    .gt_dmonitorout(gt_dmonitorout_0),
    .gt_eyescandataerror(gt_eyescandataerror_0),
    .gt_eyescanreset(gt_eyescanreset_0),
    .gt_eyescantrigger(gt_eyescantrigger_0),
    .gt_pcsrsvdin(gt_pcsrsvdin_0),
    .gt_rxbufreset(gt_rxbufreset_0),
    .gt_rxbufstatus(gt_rxbufstatus_0),
    .gt_rxcdrhold(gt_rxcdrhold_0),
    .gt_rxcommadeten(gt_rxcommadeten_0),
    .gt_rxdfeagchold(gt_rxdfeagchold_0),
    .gt_rxdfelpmreset(gt_rxdfelpmreset_0),
    .gt_rxlatclk(gt_rxlatclk_0),
    .gt_rxlpmen(gt_rxlpmen_0),
    .gt_rxpcsreset(gt_rxpcsreset_0),
    .gt_rxpmareset(gt_rxpmareset_0),
    .gt_rxpolarity(gt_rxpolarity_0),
    .gt_rxprbscntreset(gt_rxprbscntreset_0),
    .gt_rxprbserr(gt_rxprbserr_0),
    .gt_rxprbssel(gt_rxprbssel_0),
    .gt_rxrate(gt_rxrate_0),
    .gt_rxslide_in(gt_rxslide_in_0),
    .gt_rxstartofseq(gt_rxstartofseq_0),
    .gt_txbufstatus(gt_txbufstatus_0),
    .gt_txdiffctrl(gt_txdiffctrl_0),
    .gt_txinhibit(gt_txinhibit_0),
    .gt_txlatclk(gt_txlatclk_0),
    .gt_txmaincursor(gt_txmaincursor_0),
    .gt_txpcsreset(gt_txpcsreset_0),
    .gt_txpmareset(gt_txpmareset_0),
    .gt_txpolarity(gt_txpolarity_0),
    .gt_txpostcursor(gt_txpostcursor_0),
    .gt_txprbsforceerr(gt_txprbsforceerr_0),
    .gt_txprbssel(gt_txprbssel_0),
    .gt_txprecursor(gt_txprecursor_0),
    .gtwiz_reset_tx_datapath (gtwiz_reset_tx_datapath_0), 
    .gtwiz_reset_rx_datapath (gtwiz_reset_rx_datapath_0), 
    .gt_drpdo(gt_drpdo_0),
    .gt_drprdy(gt_drprdy_0),
    .gt_drpen(gt_drpen_0),
    .gt_drpwe(gt_drpwe_0),
    .gt_drpaddr(gt_drpaddr_0),
    .gt_drpdi(gt_drpdi_0),
    .reset(sys_reset),
    .drp_clk(dclk)
);


ip_xcku040_mac10g_noaxi DUT
(
    .gt_rxp_in (gt_rxp_in),
    .gt_rxn_in (gt_rxn_in),
    .gt_txp_out (gt_txp_out),
    .gt_txn_out (gt_txn_out),
    .tx_clk_out_0 (tx_clk_out_0),
    .rx_core_clk_0 (rx_core_clk_0),
    .rx_clk_out_0 (rx_clk_out_0),

    .gt_loopback_in_0 (gt_loopback_in_0),
    .rx_reset_0 (rx_reset_0),
    .user_rx_reset_0 (user_rx_reset_0),
    .rxrecclkout_0 (rxrecclkout_0),


//// RX User Interface Signals
    .rx_axis_tvalid_0 (rx_axis_tvalid_0),
    .rx_axis_tdata_0 (rx_axis_tdata_0),
    .rx_axis_tlast_0 (rx_axis_tlast_0),
    .rx_axis_tkeep_0 (rx_axis_tkeep_0),
    .rx_axis_tuser_0 (rx_axis_tuser_0),
    .rx_preambleout_0 (rx_preambleout_0),

    .tx_ptp_1588op_in_0 (tx_ptp_1588op_in_0),
    .tx_ptp_tag_field_in_0 (tx_ptp_tag_field_in_0),
    .tx_ptp_tstamp_valid_out_0 (tx_ptp_tstamp_valid_out_0),
    .tx_ptp_tstamp_tag_out_0 (tx_ptp_tstamp_tag_out_0),
    .tx_ptp_tstamp_out_0 (tx_ptp_tstamp_out_0),
    .rx_ptp_tstamp_valid_out_0 (rx_ptp_tstamp_valid_out_0),
    .rx_ptp_tstamp_out_0 (rx_ptp_tstamp_out_0),

//// RX Control Signals
    .ctl_rx_test_pattern_0 (ctl_rx_test_pattern_0),
    .ctl_rx_test_pattern_enable_0 (ctl_rx_test_pattern_enable_0),
    .ctl_rx_data_pattern_select_0 (ctl_rx_data_pattern_select_0),
    .ctl_rx_enable_0 (ctl_rx_enable_0),
    .ctl_rx_delete_fcs_0 (ctl_rx_delete_fcs_0),
    .ctl_rx_ignore_fcs_0 (ctl_rx_ignore_fcs_0),
    .ctl_rx_max_packet_len_0 (ctl_rx_max_packet_len_0),
    .ctl_rx_min_packet_len_0 (ctl_rx_min_packet_len_0),
    .ctl_rx_custom_preamble_enable_0 (ctl_rx_custom_preamble_enable_0),
    .ctl_rx_check_sfd_0 (ctl_rx_check_sfd_0),
    .ctl_rx_check_preamble_0 (ctl_rx_check_preamble_0),
    .ctl_rx_process_lfi_0 (ctl_rx_process_lfi_0),
    .ctl_rx_force_resync_0 (ctl_rx_force_resync_0),

    .ctl_rx_forward_control_0 (ctl_rx_forward_control_0),
    .ctl_rx_pause_ack_0 (ctl_rx_pause_ack_0),
    .ctl_rx_check_ack_0 (ctl_rx_check_ack_0),
    .ctl_rx_pause_enable_0 (ctl_rx_pause_enable_0),
    .ctl_rx_enable_gcp_0 (ctl_rx_enable_gcp_0),
    .ctl_rx_check_mcast_gcp_0 (ctl_rx_check_mcast_gcp_0),
    .ctl_rx_check_ucast_gcp_0 (ctl_rx_check_ucast_gcp_0),
    .ctl_rx_pause_da_ucast_0 (ctl_rx_pause_da_ucast_0),
    .ctl_rx_check_sa_gcp_0 (ctl_rx_check_sa_gcp_0),
    .ctl_rx_pause_sa_0 (ctl_rx_pause_sa_0),
    .ctl_rx_check_etype_gcp_0 (ctl_rx_check_etype_gcp_0),
    .ctl_rx_etype_gcp_0 (ctl_rx_etype_gcp_0),
    .ctl_rx_check_opcode_gcp_0 (ctl_rx_check_opcode_gcp_0),
    .ctl_rx_opcode_min_gcp_0 (ctl_rx_opcode_min_gcp_0),
    .ctl_rx_opcode_max_gcp_0 (ctl_rx_opcode_max_gcp_0),
    .ctl_rx_enable_pcp_0 (ctl_rx_enable_pcp_0),
    .ctl_rx_check_mcast_pcp_0 (ctl_rx_check_mcast_pcp_0),
    .ctl_rx_check_ucast_pcp_0 (ctl_rx_check_ucast_pcp_0),
    .ctl_rx_pause_da_mcast_0 (ctl_rx_pause_da_mcast_0),
    .ctl_rx_check_sa_pcp_0 (ctl_rx_check_sa_pcp_0),
    .ctl_rx_check_etype_pcp_0 (ctl_rx_check_etype_pcp_0),
    .ctl_rx_etype_pcp_0 (ctl_rx_etype_pcp_0),
    .ctl_rx_check_opcode_pcp_0 (ctl_rx_check_opcode_pcp_0),
    .ctl_rx_opcode_min_pcp_0 (ctl_rx_opcode_min_pcp_0),
    .ctl_rx_opcode_max_pcp_0 (ctl_rx_opcode_max_pcp_0),
    .ctl_rx_enable_gpp_0 (ctl_rx_enable_gpp_0),
    .ctl_rx_check_mcast_gpp_0 (ctl_rx_check_mcast_gpp_0),
    .ctl_rx_check_ucast_gpp_0 (ctl_rx_check_ucast_gpp_0),
    .ctl_rx_check_sa_gpp_0 (ctl_rx_check_sa_gpp_0),
    .ctl_rx_check_etype_gpp_0 (ctl_rx_check_etype_gpp_0),
    .ctl_rx_etype_gpp_0 (ctl_rx_etype_gpp_0),
    .ctl_rx_check_opcode_gpp_0 (ctl_rx_check_opcode_gpp_0),
    .ctl_rx_opcode_gpp_0 (ctl_rx_opcode_gpp_0),
    .ctl_rx_enable_ppp_0 (ctl_rx_enable_ppp_0),
    .ctl_rx_check_mcast_ppp_0 (ctl_rx_check_mcast_ppp_0),
    .ctl_rx_check_ucast_ppp_0 (ctl_rx_check_ucast_ppp_0),
    .ctl_rx_check_sa_ppp_0 (ctl_rx_check_sa_ppp_0),
    .ctl_rx_check_etype_ppp_0 (ctl_rx_check_etype_ppp_0),
    .ctl_rx_etype_ppp_0 (ctl_rx_etype_ppp_0),
    .ctl_rx_check_opcode_ppp_0 (ctl_rx_check_opcode_ppp_0),
    .ctl_rx_opcode_ppp_0 (ctl_rx_opcode_ppp_0),

  .ctl_rx_systemtimerin_0 (ctl_rx_systemtimerin_0),
  .ctl_tx_systemtimerin_0 (ctl_tx_systemtimerin_0),

//// RX Stats Signals
    .stat_rx_block_lock_0 (stat_rx_block_lock_0),
    .stat_rx_framing_err_valid_0 (stat_rx_framing_err_valid_0),
    .stat_rx_framing_err_0 (stat_rx_framing_err_0),
    .stat_rx_hi_ber_0 (stat_rx_hi_ber_0),
    .stat_rx_valid_ctrl_code_0 (stat_rx_valid_ctrl_code_0),
    .stat_rx_bad_code_0 (stat_rx_bad_code_0),
    .stat_rx_total_packets_0 (stat_rx_total_packets_0),
    .stat_rx_total_good_packets_0 (stat_rx_total_good_packets_0),
    .stat_rx_total_bytes_0 (stat_rx_total_bytes_0),
    .stat_rx_total_good_bytes_0 (stat_rx_total_good_bytes_0),
    .stat_rx_packet_small_0 (stat_rx_packet_small_0),
    .stat_rx_jabber_0 (stat_rx_jabber_0),
    .stat_rx_packet_large_0 (stat_rx_packet_large_0),
    .stat_rx_oversize_0 (stat_rx_oversize_0),
    .stat_rx_undersize_0 (stat_rx_undersize_0),
    .stat_rx_toolong_0 (stat_rx_toolong_0),
    .stat_rx_fragment_0 (stat_rx_fragment_0),
    .stat_rx_packet_64_bytes_0 (stat_rx_packet_64_bytes_0),
    .stat_rx_packet_65_127_bytes_0 (stat_rx_packet_65_127_bytes_0),
    .stat_rx_packet_128_255_bytes_0 (stat_rx_packet_128_255_bytes_0),
    .stat_rx_packet_256_511_bytes_0 (stat_rx_packet_256_511_bytes_0),
    .stat_rx_packet_512_1023_bytes_0 (stat_rx_packet_512_1023_bytes_0),
    .stat_rx_packet_1024_1518_bytes_0 (stat_rx_packet_1024_1518_bytes_0),
    .stat_rx_packet_1519_1522_bytes_0 (stat_rx_packet_1519_1522_bytes_0),
    .stat_rx_packet_1523_1548_bytes_0 (stat_rx_packet_1523_1548_bytes_0),
    .stat_rx_bad_fcs_0 (stat_rx_bad_fcs_0),
    .stat_rx_packet_bad_fcs_0 (stat_rx_packet_bad_fcs_0),
    .stat_rx_stomped_fcs_0 (stat_rx_stomped_fcs_0),
    .stat_rx_packet_1549_2047_bytes_0 (stat_rx_packet_1549_2047_bytes_0),
    .stat_rx_packet_2048_4095_bytes_0 (stat_rx_packet_2048_4095_bytes_0),
    .stat_rx_packet_4096_8191_bytes_0 (stat_rx_packet_4096_8191_bytes_0),
    .stat_rx_packet_8192_9215_bytes_0 (stat_rx_packet_8192_9215_bytes_0),
    .stat_rx_bad_preamble_0 (stat_rx_bad_preamble_0),
    .stat_rx_bad_sfd_0 (stat_rx_bad_sfd_0),
    .stat_rx_got_signal_os_0 (stat_rx_got_signal_os_0),
    .stat_rx_test_pattern_mismatch_0 (stat_rx_test_pattern_mismatch_0),
    .stat_rx_truncated_0 (stat_rx_truncated_0),
    .stat_rx_local_fault_0 (stat_rx_local_fault_0),
    .stat_rx_remote_fault_0 (stat_rx_remote_fault_0),
    .stat_rx_internal_local_fault_0 (stat_rx_internal_local_fault_0),
    .stat_rx_received_local_fault_0 (stat_rx_received_local_fault_0),
   .stat_rx_status_0 (stat_rx_status_0),
    .stat_rx_unicast_0 (stat_rx_unicast_0),
    .stat_rx_multicast_0 (stat_rx_multicast_0),
    .stat_rx_broadcast_0 (stat_rx_broadcast_0),
    .stat_rx_vlan_0 (stat_rx_vlan_0),
    .stat_rx_pause_0 (stat_rx_pause_0),
    .stat_rx_user_pause_0 (stat_rx_user_pause_0),
    .stat_rx_inrangeerr_0 (stat_rx_inrangeerr_0),
    .stat_rx_pause_valid_0 (stat_rx_pause_valid_0),
    .stat_rx_pause_quanta0_0 (stat_rx_pause_quanta0_0),
    .stat_rx_pause_quanta1_0 (stat_rx_pause_quanta1_0),
    .stat_rx_pause_quanta2_0 (stat_rx_pause_quanta2_0),
    .stat_rx_pause_quanta3_0 (stat_rx_pause_quanta3_0),
    .stat_rx_pause_quanta4_0 (stat_rx_pause_quanta4_0),
    .stat_rx_pause_quanta5_0 (stat_rx_pause_quanta5_0),
    .stat_rx_pause_quanta6_0 (stat_rx_pause_quanta6_0),
    .stat_rx_pause_quanta7_0 (stat_rx_pause_quanta7_0),
    .stat_rx_pause_quanta8_0 (stat_rx_pause_quanta8_0),
    .stat_rx_pause_req_0 (stat_rx_pause_req_0),

  .stat_tx_ptp_fifo_read_error_0 (stat_tx_ptp_fifo_read_error_0),
  .stat_tx_ptp_fifo_write_error_0 (stat_tx_ptp_fifo_write_error_0),

    .tx_reset_0 (tx_reset_0),
    .user_tx_reset_0 (user_tx_reset_0),
//// TX User Interface Signals
    .tx_axis_tready_0 (tx_axis_tready_0),
    .tx_axis_tvalid_0 (tx_axis_tvalid_0),
    .tx_axis_tdata_0 (tx_axis_tdata_0),
    .tx_axis_tlast_0 (tx_axis_tlast_0),
    .tx_axis_tkeep_0 (tx_axis_tkeep_0),
    .tx_axis_tuser_0 (tx_axis_tuser_0),
    .tx_unfout_0 (tx_unfout_0),
    .tx_preamblein_0 (tx_preamblein_0),

//// TX Control Signals
    .ctl_tx_test_pattern_0 (ctl_tx_test_pattern_0),
    .ctl_tx_test_pattern_enable_0 (ctl_tx_test_pattern_enable_0),
    .ctl_tx_test_pattern_select_0 (ctl_tx_test_pattern_select_0),
    .ctl_tx_data_pattern_select_0 (ctl_tx_data_pattern_select_0),
    .ctl_tx_test_pattern_seed_a_0 (ctl_tx_test_pattern_seed_a_0),
    .ctl_tx_test_pattern_seed_b_0 (ctl_tx_test_pattern_seed_b_0),
    .ctl_tx_enable_0 (ctl_tx_enable_0),
    .ctl_tx_fcs_ins_enable_0 (ctl_tx_fcs_ins_enable_0),
    .ctl_tx_ipg_value_0 (ctl_tx_ipg_value_0),
    .ctl_tx_send_lfi_0 (ctl_tx_send_lfi_0),
    .ctl_tx_send_rfi_0 (ctl_tx_send_rfi_0),
    .ctl_tx_send_idle_0 (ctl_tx_send_idle_0),
    .ctl_tx_custom_preamble_enable_0 (ctl_tx_custom_preamble_enable_0),
    .ctl_tx_ignore_fcs_0 (ctl_tx_ignore_fcs_0),

    .ctl_tx_pause_req_0 (ctl_tx_pause_req_0),
    .ctl_tx_pause_enable_0 (ctl_tx_pause_enable_0),
    .ctl_tx_resend_pause_0 (ctl_tx_resend_pause_0),
    .ctl_tx_pause_quanta0_0 (ctl_tx_pause_quanta0_0),
    .ctl_tx_pause_refresh_timer0_0 (ctl_tx_pause_refresh_timer0_0),
    .ctl_tx_pause_quanta1_0 (ctl_tx_pause_quanta1_0),
    .ctl_tx_pause_refresh_timer1_0 (ctl_tx_pause_refresh_timer1_0),
    .ctl_tx_pause_quanta2_0 (ctl_tx_pause_quanta2_0),
    .ctl_tx_pause_refresh_timer2_0 (ctl_tx_pause_refresh_timer2_0),
    .ctl_tx_pause_quanta3_0 (ctl_tx_pause_quanta3_0),
    .ctl_tx_pause_refresh_timer3_0 (ctl_tx_pause_refresh_timer3_0),
    .ctl_tx_pause_quanta4_0 (ctl_tx_pause_quanta4_0),
    .ctl_tx_pause_refresh_timer4_0 (ctl_tx_pause_refresh_timer4_0),
    .ctl_tx_pause_quanta5_0 (ctl_tx_pause_quanta5_0),
    .ctl_tx_pause_refresh_timer5_0 (ctl_tx_pause_refresh_timer5_0),
    .ctl_tx_pause_quanta6_0 (ctl_tx_pause_quanta6_0),
    .ctl_tx_pause_refresh_timer6_0 (ctl_tx_pause_refresh_timer6_0),
    .ctl_tx_pause_quanta7_0 (ctl_tx_pause_quanta7_0),
    .ctl_tx_pause_refresh_timer7_0 (ctl_tx_pause_refresh_timer7_0),
    .ctl_tx_pause_quanta8_0 (ctl_tx_pause_quanta8_0),
    .ctl_tx_pause_refresh_timer8_0 (ctl_tx_pause_refresh_timer8_0),
    .ctl_tx_da_gpp_0 (ctl_tx_da_gpp_0),
    .ctl_tx_sa_gpp_0 (ctl_tx_sa_gpp_0),
    .ctl_tx_ethertype_gpp_0 (ctl_tx_ethertype_gpp_0),
    .ctl_tx_opcode_gpp_0 (ctl_tx_opcode_gpp_0),
    .ctl_tx_da_ppp_0 (ctl_tx_da_ppp_0),
    .ctl_tx_sa_ppp_0 (ctl_tx_sa_ppp_0),
    .ctl_tx_ethertype_ppp_0 (ctl_tx_ethertype_ppp_0),
    .ctl_tx_opcode_ppp_0 (ctl_tx_opcode_ppp_0),

//// TX Stats Signals
    .stat_tx_total_packets_0 (stat_tx_total_packets_0),
    .stat_tx_total_bytes_0 (stat_tx_total_bytes_0),
    .stat_tx_total_good_packets_0 (stat_tx_total_good_packets_0),
    .stat_tx_total_good_bytes_0 (stat_tx_total_good_bytes_0),
    .stat_tx_packet_64_bytes_0 (stat_tx_packet_64_bytes_0),
    .stat_tx_packet_65_127_bytes_0 (stat_tx_packet_65_127_bytes_0),
    .stat_tx_packet_128_255_bytes_0 (stat_tx_packet_128_255_bytes_0),
    .stat_tx_packet_256_511_bytes_0 (stat_tx_packet_256_511_bytes_0),
    .stat_tx_packet_512_1023_bytes_0 (stat_tx_packet_512_1023_bytes_0),
    .stat_tx_packet_1024_1518_bytes_0 (stat_tx_packet_1024_1518_bytes_0),
    .stat_tx_packet_1519_1522_bytes_0 (stat_tx_packet_1519_1522_bytes_0),
    .stat_tx_packet_1523_1548_bytes_0 (stat_tx_packet_1523_1548_bytes_0),
    .stat_tx_packet_small_0 (stat_tx_packet_small_0),
    .stat_tx_packet_large_0 (stat_tx_packet_large_0),
    .stat_tx_packet_1549_2047_bytes_0 (stat_tx_packet_1549_2047_bytes_0),
    .stat_tx_packet_2048_4095_bytes_0 (stat_tx_packet_2048_4095_bytes_0),
    .stat_tx_packet_4096_8191_bytes_0 (stat_tx_packet_4096_8191_bytes_0),
    .stat_tx_packet_8192_9215_bytes_0 (stat_tx_packet_8192_9215_bytes_0),
    .stat_tx_bad_fcs_0 (stat_tx_bad_fcs_0),
    .stat_tx_frame_error_0 (stat_tx_frame_error_0),
    .stat_tx_local_fault_0 (stat_tx_local_fault_0),

    .stat_tx_unicast_0 (stat_tx_unicast_0),
    .stat_tx_multicast_0 (stat_tx_multicast_0),
    .stat_tx_broadcast_0 (stat_tx_broadcast_0),
    .stat_tx_vlan_0 (stat_tx_vlan_0),
    .stat_tx_pause_0 (stat_tx_pause_0),
    .stat_tx_user_pause_0 (stat_tx_user_pause_0),
    .stat_tx_pause_valid_0 (stat_tx_pause_valid_0),


    .gt_dmonitorout_0 (gt_dmonitorout_0),
    .gt_eyescandataerror_0 (gt_eyescandataerror_0),
    .gt_eyescanreset_0 (gt_eyescanreset_0),
    .gt_eyescantrigger_0 (gt_eyescantrigger_0),
    .gt_pcsrsvdin_0 (gt_pcsrsvdin_0),
    .gt_rxbufreset_0 (gt_rxbufreset_0),
    .gt_rxbufstatus_0 (gt_rxbufstatus_0),
    .gt_rxcdrhold_0 (gt_rxcdrhold_0),
    .gt_rxcommadeten_0 (gt_rxcommadeten_0),
    .gt_rxdfeagchold_0 (gt_rxdfeagchold_0),
    .gt_rxdfelpmreset_0 (gt_rxdfelpmreset_0),
    .gt_rxlatclk_0 (gt_rxlatclk_0),
    .gt_rxlpmen_0 (gt_rxlpmen_0),
    .gt_rxpcsreset_0 (gt_rxpcsreset_0),
    .gt_rxpmareset_0 (gt_rxpmareset_0),
    .gt_rxpolarity_0 (gt_rxpolarity_0),
    .gt_rxprbscntreset_0 (gt_rxprbscntreset_0),
    .gt_rxprbserr_0 (gt_rxprbserr_0),
    .gt_rxprbssel_0 (gt_rxprbssel_0),
    .gt_rxrate_0 (gt_rxrate_0),
    .gt_rxslide_in_0 (gt_rxslide_in_0),
    .gt_rxstartofseq_0 (gt_rxstartofseq_0),
    .gt_txbufstatus_0 (gt_txbufstatus_0),
    .gt_txdiffctrl_0 (gt_txdiffctrl_0),
    .gt_txinhibit_0 (gt_txinhibit_0),
    .gt_txlatclk_0 (gt_txlatclk_0),
    .gt_txmaincursor_0 (gt_txmaincursor_0),
    .gt_txpcsreset_0 (gt_txpcsreset_0),
    .gt_txpmareset_0 (gt_txpmareset_0),
    .gt_txpolarity_0 (gt_txpolarity_0),
    .gt_txpostcursor_0 (gt_txpostcursor_0),
    .gt_txprbsforceerr_0 (gt_txprbsforceerr_0),
    .gt_txprbssel_0 (gt_txprbssel_0),
    .gt_txprecursor_0 (gt_txprecursor_0),
    .gt_drpdo_0 (gt_drpdo_0),
    .gt_drprdy_0 (gt_drprdy_0),
    .gt_drpen_0 (gt_drpen_0),
    .gt_drpwe_0 (gt_drpwe_0),
    .gt_drpaddr_0 (gt_drpaddr_0),
    .gt_drpdi_0 (gt_drpdi_0),
    .gt_drpclk_0 (dclk),
    .gtwiz_reset_tx_datapath_0 (gtwiz_reset_tx_datapath_0),
    .gtwiz_reset_rx_datapath_0 (gtwiz_reset_rx_datapath_0),
    .gtpowergood_out_0 (gtpowergood_out_0),
    .gt_refclk_p (gt_refclk_p),
    .gt_refclk_n (gt_refclk_n),
    .gt_refclk_out (gt_refclk_out),
    .sys_reset (sys_reset),
    .dclk (dclk)
);

ip_xcku040_mac10g_noaxi_pkt_gen_mon #(
.PKT_NUM (PKT_NUM))i_ip_xcku040_mac10g_noaxi_pkt_gen_mon_0
(
  .gen_clk (tx_clk_out_0),
  .mon_clk (rx_core_clk_0),
  .dclk (dclk),
  .sys_reset (sys_reset),
//// User Interface signals
  .completion_status (completion_status_0),
  .restart_tx_rx (restart_tx_rx_0),
//// RX Signals
  .rx_reset(rx_reset_0),
  .user_rx_reset(user_rx_reset_0),
  .rx_axis_tvalid (rx_axis_tvalid_0),
  .rx_axis_tdata (rx_axis_tdata_0),
  .rx_axis_tlast (rx_axis_tlast_0),
  .rx_axis_tkeep (rx_axis_tkeep_0),
  .rx_axis_tuser (rx_axis_tuser_0),
  .rx_preambleout (rx_preambleout_0),

  .tx_ptp_1588op_in (tx_ptp_1588op_in_0),
  .tx_ptp_tag_field_in (tx_ptp_tag_field_in_0),
  .tx_ptp_tstamp_valid_out (tx_ptp_tstamp_valid_out_0),
  .tx_ptp_tstamp_tag_out (tx_ptp_tstamp_tag_out_0),
  .tx_ptp_tstamp_out (tx_ptp_tstamp_out_0),
  .rx_ptp_tstamp_valid_out (rx_ptp_tstamp_valid_out_0),
  .rx_ptp_tstamp_out (rx_ptp_tstamp_out_0),

//// RX Control Signals
  .ctl_rx_test_pattern (ctl_rx_test_pattern_0),
  .ctl_rx_test_pattern_enable (ctl_rx_test_pattern_enable_0),
  .ctl_rx_data_pattern_select (ctl_rx_data_pattern_select_0),
  .ctl_rx_enable (ctl_rx_enable_0),
  .ctl_rx_delete_fcs (ctl_rx_delete_fcs_0),
  .ctl_rx_ignore_fcs (ctl_rx_ignore_fcs_0),
  .ctl_rx_max_packet_len (ctl_rx_max_packet_len_0),
  .ctl_rx_min_packet_len (ctl_rx_min_packet_len_0),
  .ctl_rx_custom_preamble_enable (ctl_rx_custom_preamble_enable_0),
  .ctl_rx_check_sfd (ctl_rx_check_sfd_0),
  .ctl_rx_check_preamble (ctl_rx_check_preamble_0),
  .ctl_rx_process_lfi (ctl_rx_process_lfi_0),
  .ctl_rx_force_resync (ctl_rx_force_resync_0),

  .ctl_rx_forward_control (ctl_rx_forward_control_0),
  .ctl_rx_pause_ack (ctl_rx_pause_ack_0),
  .ctl_rx_check_ack (ctl_rx_check_ack_0),
  .ctl_rx_pause_enable (ctl_rx_pause_enable_0),
  .ctl_rx_enable_gcp (ctl_rx_enable_gcp_0),
  .ctl_rx_check_mcast_gcp (ctl_rx_check_mcast_gcp_0),
  .ctl_rx_check_ucast_gcp (ctl_rx_check_ucast_gcp_0),
  .ctl_rx_pause_da_ucast (ctl_rx_pause_da_ucast_0),
  .ctl_rx_check_sa_gcp (ctl_rx_check_sa_gcp_0),
  .ctl_rx_pause_sa (ctl_rx_pause_sa_0),
  .ctl_rx_check_etype_gcp (ctl_rx_check_etype_gcp_0),
  .ctl_rx_etype_gcp (ctl_rx_etype_gcp_0),
  .ctl_rx_check_opcode_gcp (ctl_rx_check_opcode_gcp_0),
  .ctl_rx_opcode_min_gcp (ctl_rx_opcode_min_gcp_0),
  .ctl_rx_opcode_max_gcp (ctl_rx_opcode_max_gcp_0),
  .ctl_rx_enable_pcp (ctl_rx_enable_pcp_0),
  .ctl_rx_check_mcast_pcp (ctl_rx_check_mcast_pcp_0),
  .ctl_rx_check_ucast_pcp (ctl_rx_check_ucast_pcp_0),
  .ctl_rx_pause_da_mcast (ctl_rx_pause_da_mcast_0),
  .ctl_rx_check_sa_pcp (ctl_rx_check_sa_pcp_0),
  .ctl_rx_check_etype_pcp (ctl_rx_check_etype_pcp_0),
  .ctl_rx_etype_pcp (ctl_rx_etype_pcp_0),
  .ctl_rx_check_opcode_pcp (ctl_rx_check_opcode_pcp_0),
  .ctl_rx_opcode_min_pcp (ctl_rx_opcode_min_pcp_0),
  .ctl_rx_opcode_max_pcp (ctl_rx_opcode_max_pcp_0),
  .ctl_rx_enable_gpp (ctl_rx_enable_gpp_0),
  .ctl_rx_check_mcast_gpp (ctl_rx_check_mcast_gpp_0),
  .ctl_rx_check_ucast_gpp (ctl_rx_check_ucast_gpp_0),
  .ctl_rx_check_sa_gpp (ctl_rx_check_sa_gpp_0),
  .ctl_rx_check_etype_gpp (ctl_rx_check_etype_gpp_0),
  .ctl_rx_etype_gpp (ctl_rx_etype_gpp_0),
  .ctl_rx_check_opcode_gpp (ctl_rx_check_opcode_gpp_0),
  .ctl_rx_opcode_gpp (ctl_rx_opcode_gpp_0),
  .ctl_rx_enable_ppp (ctl_rx_enable_ppp_0),
  .ctl_rx_check_mcast_ppp (ctl_rx_check_mcast_ppp_0),
  .ctl_rx_check_ucast_ppp (ctl_rx_check_ucast_ppp_0),
  .ctl_rx_check_sa_ppp (ctl_rx_check_sa_ppp_0),
  .ctl_rx_check_etype_ppp (ctl_rx_check_etype_ppp_0),
  .ctl_rx_etype_ppp (ctl_rx_etype_ppp_0),
  .ctl_rx_check_opcode_ppp (ctl_rx_check_opcode_ppp_0),
  .ctl_rx_opcode_ppp (ctl_rx_opcode_ppp_0),

  .ctl_rx_systemtimerin (ctl_rx_systemtimerin_0),
  .ctl_tx_systemtimerin (ctl_tx_systemtimerin_0),

//// RX Stats Signals
  .stat_rx_block_lock (stat_rx_block_lock_0),
  .stat_rx_framing_err_valid (stat_rx_framing_err_valid_0),
  .stat_rx_framing_err (stat_rx_framing_err_0),
  .stat_rx_hi_ber (stat_rx_hi_ber_0),
  .stat_rx_valid_ctrl_code (stat_rx_valid_ctrl_code_0),
  .stat_rx_bad_code (stat_rx_bad_code_0),
  .stat_rx_total_packets (stat_rx_total_packets_0),
  .stat_rx_total_good_packets (stat_rx_total_good_packets_0),
  .stat_rx_total_bytes (stat_rx_total_bytes_0),
  .stat_rx_total_good_bytes (stat_rx_total_good_bytes_0),
  .stat_rx_packet_small (stat_rx_packet_small_0),
  .stat_rx_jabber (stat_rx_jabber_0),
  .stat_rx_packet_large (stat_rx_packet_large_0),
  .stat_rx_oversize (stat_rx_oversize_0),
  .stat_rx_undersize (stat_rx_undersize_0),
  .stat_rx_toolong (stat_rx_toolong_0),
  .stat_rx_fragment (stat_rx_fragment_0),
  .stat_rx_packet_64_bytes (stat_rx_packet_64_bytes_0),
  .stat_rx_packet_65_127_bytes (stat_rx_packet_65_127_bytes_0),
  .stat_rx_packet_128_255_bytes (stat_rx_packet_128_255_bytes_0),
  .stat_rx_packet_256_511_bytes (stat_rx_packet_256_511_bytes_0),
  .stat_rx_packet_512_1023_bytes (stat_rx_packet_512_1023_bytes_0),
  .stat_rx_packet_1024_1518_bytes (stat_rx_packet_1024_1518_bytes_0),
  .stat_rx_packet_1519_1522_bytes (stat_rx_packet_1519_1522_bytes_0),
  .stat_rx_packet_1523_1548_bytes (stat_rx_packet_1523_1548_bytes_0),
  .stat_rx_bad_fcs (stat_rx_bad_fcs_0),
  .stat_rx_packet_bad_fcs (stat_rx_packet_bad_fcs_0),
  .stat_rx_stomped_fcs (stat_rx_stomped_fcs_0),
  .stat_rx_packet_1549_2047_bytes (stat_rx_packet_1549_2047_bytes_0),
  .stat_rx_packet_2048_4095_bytes (stat_rx_packet_2048_4095_bytes_0),
  .stat_rx_packet_4096_8191_bytes (stat_rx_packet_4096_8191_bytes_0),
  .stat_rx_packet_8192_9215_bytes (stat_rx_packet_8192_9215_bytes_0),
  .stat_rx_bad_preamble (stat_rx_bad_preamble_0),
  .stat_rx_bad_sfd (stat_rx_bad_sfd_0),
  .stat_rx_got_signal_os (stat_rx_got_signal_os_0),
  .stat_rx_test_pattern_mismatch (stat_rx_test_pattern_mismatch_0),
  .stat_rx_truncated (stat_rx_truncated_0),
  .stat_rx_local_fault (stat_rx_local_fault_0),
  .stat_rx_remote_fault (stat_rx_remote_fault_0),
  .stat_rx_internal_local_fault (stat_rx_internal_local_fault_0),
  .stat_rx_received_local_fault (stat_rx_received_local_fault_0),

  .stat_rx_unicast (stat_rx_unicast_0),
  .stat_rx_multicast (stat_rx_multicast_0),
  .stat_rx_broadcast (stat_rx_broadcast_0),
  .stat_rx_vlan (stat_rx_vlan_0),
  .stat_rx_pause (stat_rx_pause_0),
  .stat_rx_user_pause (stat_rx_user_pause_0),
  .stat_rx_inrangeerr (stat_rx_inrangeerr_0),
  .stat_rx_pause_valid (stat_rx_pause_valid_0),
  .stat_rx_pause_quanta0 (stat_rx_pause_quanta0_0),
  .stat_rx_pause_quanta1 (stat_rx_pause_quanta1_0),
  .stat_rx_pause_quanta2 (stat_rx_pause_quanta2_0),
  .stat_rx_pause_quanta3 (stat_rx_pause_quanta3_0),
  .stat_rx_pause_quanta4 (stat_rx_pause_quanta4_0),
  .stat_rx_pause_quanta5 (stat_rx_pause_quanta5_0),
  .stat_rx_pause_quanta6 (stat_rx_pause_quanta6_0),
  .stat_rx_pause_quanta7 (stat_rx_pause_quanta7_0),
  .stat_rx_pause_quanta8 (stat_rx_pause_quanta8_0),
  .stat_rx_pause_req (stat_rx_pause_req_0),

  .stat_tx_ptp_fifo_read_error (stat_tx_ptp_fifo_read_error_0),
  .stat_tx_ptp_fifo_write_error (stat_tx_ptp_fifo_write_error_0),
  .tx_reset(tx_reset_0),
  .user_tx_reset (user_tx_reset_0),
//// TX LBUS Signals
  .tx_axis_tready (tx_axis_tready_0),
  .tx_axis_tvalid (tx_axis_tvalid_0),
  .tx_axis_tdata (tx_axis_tdata_0),
  .tx_axis_tlast (tx_axis_tlast_0),
  .tx_axis_tkeep (tx_axis_tkeep_0),
  .tx_axis_tuser (tx_axis_tuser_0),
  .tx_unfout (tx_unfout_0),
  .tx_preamblein (tx_preamblein_0),

//// TX Control Signals
  .ctl_tx_test_pattern (ctl_tx_test_pattern_0),
  .ctl_tx_test_pattern_enable (ctl_tx_test_pattern_enable_0),
  .ctl_tx_test_pattern_select (ctl_tx_test_pattern_select_0),
  .ctl_tx_data_pattern_select (ctl_tx_data_pattern_select_0),
  .ctl_tx_test_pattern_seed_a (ctl_tx_test_pattern_seed_a_0),
  .ctl_tx_test_pattern_seed_b (ctl_tx_test_pattern_seed_b_0),
  .ctl_tx_enable (ctl_tx_enable_0),
  .ctl_tx_fcs_ins_enable (ctl_tx_fcs_ins_enable_0),
  .ctl_tx_ipg_value (ctl_tx_ipg_value_0),
  .ctl_tx_send_lfi (ctl_tx_send_lfi_0),
  .ctl_tx_send_rfi (ctl_tx_send_rfi_0),
  .ctl_tx_send_idle (ctl_tx_send_idle_0),
  .ctl_tx_custom_preamble_enable (ctl_tx_custom_preamble_enable_0),
  .ctl_tx_ignore_fcs (ctl_tx_ignore_fcs_0),

  .ctl_tx_pause_req (ctl_tx_pause_req_0),
  .ctl_tx_pause_enable (ctl_tx_pause_enable_0),
  .ctl_tx_resend_pause (ctl_tx_resend_pause_0),
  .ctl_tx_pause_quanta0 (ctl_tx_pause_quanta0_0),
  .ctl_tx_pause_refresh_timer0 (ctl_tx_pause_refresh_timer0_0),
  .ctl_tx_pause_quanta1 (ctl_tx_pause_quanta1_0),
  .ctl_tx_pause_refresh_timer1 (ctl_tx_pause_refresh_timer1_0),
  .ctl_tx_pause_quanta2 (ctl_tx_pause_quanta2_0),
  .ctl_tx_pause_refresh_timer2 (ctl_tx_pause_refresh_timer2_0),
  .ctl_tx_pause_quanta3 (ctl_tx_pause_quanta3_0),
  .ctl_tx_pause_refresh_timer3 (ctl_tx_pause_refresh_timer3_0),
  .ctl_tx_pause_quanta4 (ctl_tx_pause_quanta4_0),
  .ctl_tx_pause_refresh_timer4 (ctl_tx_pause_refresh_timer4_0),
  .ctl_tx_pause_quanta5 (ctl_tx_pause_quanta5_0),
  .ctl_tx_pause_refresh_timer5 (ctl_tx_pause_refresh_timer5_0),
  .ctl_tx_pause_quanta6 (ctl_tx_pause_quanta6_0),
  .ctl_tx_pause_refresh_timer6 (ctl_tx_pause_refresh_timer6_0),
  .ctl_tx_pause_quanta7 (ctl_tx_pause_quanta7_0),
  .ctl_tx_pause_refresh_timer7 (ctl_tx_pause_refresh_timer7_0),
  .ctl_tx_pause_quanta8 (ctl_tx_pause_quanta8_0),
  .ctl_tx_pause_refresh_timer8 (ctl_tx_pause_refresh_timer8_0),
  .ctl_tx_da_gpp (ctl_tx_da_gpp_0),
  .ctl_tx_sa_gpp (ctl_tx_sa_gpp_0),
  .ctl_tx_ethertype_gpp (ctl_tx_ethertype_gpp_0),
  .ctl_tx_opcode_gpp (ctl_tx_opcode_gpp_0),
  .ctl_tx_da_ppp (ctl_tx_da_ppp_0),
  .ctl_tx_sa_ppp (ctl_tx_sa_ppp_0),
  .ctl_tx_ethertype_ppp (ctl_tx_ethertype_ppp_0),
  .ctl_tx_opcode_ppp (ctl_tx_opcode_ppp_0),

//// TX Stats Signals
  .stat_tx_total_packets (stat_tx_total_packets_0),
  .stat_tx_total_bytes (stat_tx_total_bytes_0),
  .stat_tx_total_good_packets (stat_tx_total_good_packets_0),
  .stat_tx_total_good_bytes (stat_tx_total_good_bytes_0),
  .stat_tx_packet_64_bytes (stat_tx_packet_64_bytes_0),
  .stat_tx_packet_65_127_bytes (stat_tx_packet_65_127_bytes_0),
  .stat_tx_packet_128_255_bytes (stat_tx_packet_128_255_bytes_0),
  .stat_tx_packet_256_511_bytes (stat_tx_packet_256_511_bytes_0),
  .stat_tx_packet_512_1023_bytes (stat_tx_packet_512_1023_bytes_0),
  .stat_tx_packet_1024_1518_bytes (stat_tx_packet_1024_1518_bytes_0),
  .stat_tx_packet_1519_1522_bytes (stat_tx_packet_1519_1522_bytes_0),
  .stat_tx_packet_1523_1548_bytes (stat_tx_packet_1523_1548_bytes_0),
  .stat_tx_packet_small (stat_tx_packet_small_0),
  .stat_tx_packet_large (stat_tx_packet_large_0),
  .stat_tx_packet_1549_2047_bytes (stat_tx_packet_1549_2047_bytes_0),
  .stat_tx_packet_2048_4095_bytes (stat_tx_packet_2048_4095_bytes_0),
  .stat_tx_packet_4096_8191_bytes (stat_tx_packet_4096_8191_bytes_0),
  .stat_tx_packet_8192_9215_bytes (stat_tx_packet_8192_9215_bytes_0),
  .stat_tx_bad_fcs (stat_tx_bad_fcs_0),
  .stat_tx_frame_error (stat_tx_frame_error_0),
  .stat_tx_local_fault (stat_tx_local_fault_0),

  .stat_tx_unicast (stat_tx_unicast_0),
  .stat_tx_multicast (stat_tx_multicast_0),
  .stat_tx_broadcast (stat_tx_broadcast_0),
  .stat_tx_vlan (stat_tx_vlan_0),
  .stat_tx_pause (stat_tx_pause_0),
  .stat_tx_user_pause (stat_tx_user_pause_0),
  .stat_tx_pause_valid (stat_tx_pause_valid_0),
   
  .rx_gt_locked_led (rx_gt_locked_led_0),
  .rx_block_lock_led (rx_block_lock_led_0)
    );



assign completion_status = completion_status_0;


endmodule



