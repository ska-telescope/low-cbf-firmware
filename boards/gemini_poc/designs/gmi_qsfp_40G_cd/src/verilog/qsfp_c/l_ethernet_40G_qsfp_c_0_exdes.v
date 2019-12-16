////------------------------------------------------------------------------------
////  (c) Copyright 2015 Xilinx, Inc. All rights reserved.
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
module l_ethernet_40G_qsfp_c_0_exdes
(
  input  wire gt_rxp_in_0,
  input  wire gt_rxn_in_0,
  output wire gt_txp_out_0,
  output wire gt_txn_out_0,
  input  wire gt_rxp_in_1,
  input  wire gt_rxn_in_1,
  output wire gt_txp_out_1,
  output wire gt_txn_out_1,
  input  wire gt_rxp_in_2,
  input  wire gt_rxn_in_2,
  output wire gt_txp_out_2,
  output wire gt_txn_out_2,
  input  wire gt_rxp_in_3,
  input  wire gt_rxn_in_3,
  output wire gt_txp_out_3,
  output wire gt_txn_out_3,
                      
    output wire       rx_gt_locked_led,
    output wire       rx_aligned_led,
    output wire [4:0] completion_status,

    input             sys_reset,
    input             restart_tx_rx,

    input             gt_refclk_p,
    input             gt_refclk_n,
    input             dclk,
    input [3:0] gt_rxpolarity_0,
    input [3:0] gt_txpolarity_0
);

`ifdef SIM_SPEED_UP
  parameter PKT_NUM         = 20;    //// Many Internal Counters are based on PKT_NUM = 20
`else
  parameter PKT_NUM         = 1000;    //// Many Internal Counters are based on PKT_NUM = 1000
`endif


////GT Transceiver debug interface signals
  wire [67:0] gt_dmonitorout_0;
  wire [3:0] gt_eyescandataerror_0;
  wire [3:0] gt_eyescanreset_0;
  wire [3:0] gt_eyescantrigger_0;
  wire [63:0] gt_pcsrsvdin_0;
  wire [3:0] gt_rxbufreset_0;
  wire [11:0] gt_rxbufstatus_0;
  wire [3:0] gt_rxcdrhold_0;
  wire [3:0] gt_rxcommadeten_0;
  wire [3:0] gt_rxdfeagchold_0;
  wire [3:0] gt_rxdfelpmreset_0;
  wire [3:0] gt_rxlatclk_0;
  wire [3:0] gt_rxlpmen_0;
  wire [3:0] gt_rxpcsreset_0;
  wire [3:0] gt_rxpmareset_0;
//  wire [3:0] gt_rxpolarity_0;
  wire [3:0] gt_rxprbscntreset_0;
  wire [3:0] gt_rxprbserr_0;
  wire [15:0] gt_rxprbssel_0;
  wire [11:0] gt_rxrate_0;
  wire [3:0] gt_rxslide_in_0;
  wire [7:0] gt_rxstartofseq_0;
  wire [7:0] gt_txbufstatus_0;
  wire [19:0] gt_txdiffctrl_0;
  wire [3:0] gt_txinhibit_0;
  wire [3:0] gt_txlatclk_0;
  wire [27:0] gt_txmaincursor_0;
  wire [3:0] gt_txpcsreset_0;
  wire [3:0] gt_txpmareset_0;
//  wire [3:0] gt_txpolarity_0;
  wire [19:0] gt_txpostcursor_0;
  wire [3:0] gt_txprbsforceerr_0;
  wire [15:0] gt_txprbssel_0;
  wire [19:0] gt_txprecursor_0;
////GT Channel DRP ports
  wire [15:0] gt_ch_drpdo_0;
  wire [0:0] gt_ch_drprdy_0;
  wire [0:0] gt_ch_drpen_0;
  wire [0:0] gt_ch_drpwe_0;
  wire [9:0] gt_ch_drpaddr_0;
  wire [15:0] gt_ch_drpdi_0;
  wire [15:0] gt_ch_drpdo_1;
  wire [0:0] gt_ch_drprdy_1;
  wire [0:0] gt_ch_drpen_1;
  wire [0:0] gt_ch_drpwe_1;
  wire [9:0] gt_ch_drpaddr_1;
  wire [15:0] gt_ch_drpdi_1;
  wire [15:0] gt_ch_drpdo_2;
  wire [0:0] gt_ch_drprdy_2;
  wire [0:0] gt_ch_drpen_2;
  wire [0:0] gt_ch_drpwe_2;
  wire [9:0] gt_ch_drpaddr_2;
  wire [15:0] gt_ch_drpdi_2;
  wire [15:0] gt_ch_drpdo_3;
  wire [0:0] gt_ch_drprdy_3;
  wire [0:0] gt_ch_drpen_3;
  wire [0:0] gt_ch_drpwe_3;
  wire [9:0] gt_ch_drpaddr_3;
  wire [15:0] gt_ch_drpdi_3;
////GT Common DRP ports
  wire [0:0] gt_common_drpclk;
  wire [15:0] gt_common_drpdo;
  wire [0:0] gt_common_drprdy;
  wire [0:0] gt_common_drpen;
  wire [0:0] gt_common_drpwe;
  wire [9:0] gt_common_drpaddr;
  wire [15:0] gt_common_drpdi;
  assign gt_common_drpclk = dclk;
  assign gt_common_drpaddr = 10'b0;
  assign gt_common_drpdi = 16'b0;
  assign gt_common_drpwe = 1'b0;
  assign gt_common_drpen = 1'b0;
  wire rx_gt_locked_led_0;
  wire rx_aligned_led_0;

  wire rx_core_clk_0;
  wire rx_clk_out_0;
  wire tx_clk_out_0;
  //assign rx_core_clk_0 = tx_clk_out_0;
  assign rx_core_clk_0 = rx_clk_out_0;

  wire usr_fsm_clk;
  assign usr_fsm_clk = dclk;
  
  


//// AXI_0 interface ports
  wire s_axi_aclk_0;
  wire s_axi_aresetn_0;
  wire [31:0] s_axi_awaddr_0;
  wire s_axi_awvalid_0;
  wire s_axi_awready_0;
  wire [31:0] s_axi_wdata_0;
  wire [3:0] s_axi_wstrb_0;
  wire s_axi_wvalid_0;
  wire s_axi_wready_0;
  wire [1:0] s_axi_bresp_0;
  wire s_axi_bvalid_0;
  wire s_axi_bready_0;
  wire [31:0] s_axi_araddr_0;
  wire s_axi_arvalid_0;
  wire s_axi_arready_0;
  wire [31:0] s_axi_rdata_0;
  wire [1:0] s_axi_rresp_0;
  wire s_axi_rvalid_0;
  wire s_axi_rready_0;
  wire pm_tick_0;
//// RX_0 Signals
  wire rx_reset_0;
  wire user_rx_reset_0;

//// RX_0 User Interface Signals
  wire rx_axis_tvalid_0;
  wire [127:0] rx_axis_tdata_0;
  wire [69:0] rx_axis_tuser_0;

//// RX_0 Control Signals

  wire [8:0] ctl_rx_pause_ack_0;

//// RX_0 Stats Signals
  wire [3:0] stat_rx_block_lock_0;
  wire stat_rx_framing_err_valid_0_0;
  wire stat_rx_framing_err_0_0;
  wire stat_rx_framing_err_valid_1_0;
  wire stat_rx_framing_err_1_0;
  wire stat_rx_framing_err_valid_2_0;
  wire stat_rx_framing_err_2_0;
  wire stat_rx_framing_err_valid_3_0;
  wire stat_rx_framing_err_3_0;
  wire [3:0] stat_rx_vl_demuxed_0;
  wire [1:0] stat_rx_vl_number_0_0;
  wire [1:0] stat_rx_vl_number_1_0;
  wire [1:0] stat_rx_vl_number_2_0;
  wire [1:0] stat_rx_vl_number_3_0;
  wire [3:0] stat_rx_synced_0;
  wire stat_rx_misaligned_0;
  wire stat_rx_aligned_err_0;
  wire [3:0] stat_rx_synced_err_0;
  wire [3:0] stat_rx_mf_len_err_0;
  wire [3:0] stat_rx_mf_repeat_err_0;
  wire [3:0] stat_rx_mf_err_0;
  wire stat_rx_bip_err_0_0;
  wire stat_rx_bip_err_1_0;
  wire stat_rx_bip_err_2_0;
  wire stat_rx_bip_err_3_0;
  wire stat_rx_aligned_0;
  wire stat_rx_hi_ber_0;
  wire stat_rx_status_0;
  wire [1:0] stat_rx_bad_code_0;
  wire [1:0] stat_rx_total_packets_0;
  wire stat_rx_total_good_packets_0;
  wire [5:0] stat_rx_total_bytes_0;
  wire [13:0] stat_rx_total_good_bytes_0;
  wire [1:0] stat_rx_packet_small_0;
  wire stat_rx_jabber_0;
  wire stat_rx_packet_large_0;
  wire stat_rx_oversize_0;
  wire [1:0] stat_rx_undersize_0;
  wire stat_rx_toolong_0;
  wire [1:0] stat_rx_fragment_0;
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
  wire [1:0] stat_rx_test_pattern_mismatch_0;
  wire stat_rx_truncated_0;
  wire stat_rx_local_fault_0;
  wire stat_rx_remote_fault_0;
  wire stat_rx_internal_local_fault_0;
  wire stat_rx_received_local_fault_0;

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

//// TX_0 Signals
  wire tx_reset_0;
  wire user_tx_reset_0;

//// TX_0 User Interface Signals
  wire tx_axis_tready_0;
  wire tx_axis_tvalid_0;
  wire [127:0] tx_axis_tdata_0;
  wire [69:0] tx_axis_tuser_0;
  wire tx_unfout_0;

//// TX_0 Control Signals
  wire ctl_tx_send_lfi_0;
  wire ctl_tx_send_rfi_0;
  wire ctl_tx_send_idle_0;

  wire [8:0] ctl_tx_pause_req_0;
  wire ctl_tx_resend_pause_0;

//// TX_0 Stats Signals
  wire stat_tx_total_packets_0;
  wire [4:0] stat_tx_total_bytes_0;
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







  wire [4:0] completion_status_0;
  wire [3:0] rxrecclkout_0;



l_ethernet_40G_qsfp_c_0 DUT
(
    .gt_rxp_in_0 (gt_rxp_in_0),
    .gt_rxn_in_0 (gt_rxn_in_0),
    .gt_txp_out_0 (gt_txp_out_0),
    .gt_txn_out_0 (gt_txn_out_0),
    .gt_rxp_in_1 (gt_rxp_in_1),
    .gt_rxn_in_1 (gt_rxn_in_1),
    .gt_txp_out_1 (gt_txp_out_1),
    .gt_txn_out_1 (gt_txn_out_1),
    .gt_rxp_in_2 (gt_rxp_in_2),
    .gt_rxn_in_2 (gt_rxn_in_2),
    .gt_txp_out_2 (gt_txp_out_2),
    .gt_txn_out_2 (gt_txn_out_2),
    .gt_rxp_in_3 (gt_rxp_in_3),
    .gt_rxn_in_3 (gt_rxn_in_3),
    .gt_txp_out_3 (gt_txp_out_3),
    .gt_txn_out_3 (gt_txn_out_3),

    .tx_clk_out_0 (tx_clk_out_0),
    .rx_core_clk_0 (rx_core_clk_0),
    .rx_clk_out_0 (rx_clk_out_0),
    .rxrecclkout_0 (rxrecclkout_0),

    .s_axi_aclk_0 (s_axi_aclk_0),
    .s_axi_aresetn_0 (s_axi_aresetn_0),
    .s_axi_awaddr_0 (s_axi_awaddr_0),
    .s_axi_awvalid_0 (s_axi_awvalid_0),
    .s_axi_awready_0 (s_axi_awready_0),
    .s_axi_wdata_0 (s_axi_wdata_0),
    .s_axi_wstrb_0 (s_axi_wstrb_0),
    .s_axi_wvalid_0 (s_axi_wvalid_0),
    .s_axi_wready_0 (s_axi_wready_0),
    .s_axi_bresp_0 (s_axi_bresp_0),
    .s_axi_bvalid_0 (s_axi_bvalid_0),
    .s_axi_bready_0 (s_axi_bready_0),
    .s_axi_araddr_0 (s_axi_araddr_0),
    .s_axi_arvalid_0 (s_axi_arvalid_0),
    .s_axi_arready_0 (s_axi_arready_0),
    .s_axi_rdata_0 (s_axi_rdata_0),
    .s_axi_rresp_0 (s_axi_rresp_0),
    .s_axi_rvalid_0 (s_axi_rvalid_0),
    .s_axi_rready_0 (s_axi_rready_0),
    .pm_tick_0 (pm_tick_0),
    .rx_reset_0 (rx_reset_0),
    .user_rx_reset_0 (user_rx_reset_0),
//// RX User Interface Signals
    .rx_axis_tvalid_0 (rx_axis_tvalid_0),
    .rx_axis_tdata_0 (rx_axis_tdata_0),
    .rx_axis_tuser_0 (rx_axis_tuser_0),



//// RX Control Signals

    .ctl_rx_pause_ack_0 (ctl_rx_pause_ack_0),



//// RX Stats Signals
    .stat_rx_block_lock_0 (stat_rx_block_lock_0),
    .stat_rx_framing_err_valid_0_0 (stat_rx_framing_err_valid_0_0),
    .stat_rx_framing_err_0_0 (stat_rx_framing_err_0_0),
    .stat_rx_framing_err_valid_1_0 (stat_rx_framing_err_valid_1_0),
    .stat_rx_framing_err_1_0 (stat_rx_framing_err_1_0),
    .stat_rx_framing_err_valid_2_0 (stat_rx_framing_err_valid_2_0),
    .stat_rx_framing_err_2_0 (stat_rx_framing_err_2_0),
    .stat_rx_framing_err_valid_3_0 (stat_rx_framing_err_valid_3_0),
    .stat_rx_framing_err_3_0 (stat_rx_framing_err_3_0),
    .stat_rx_vl_demuxed_0 (stat_rx_vl_demuxed_0),
    .stat_rx_vl_number_0_0 (stat_rx_vl_number_0_0),
    .stat_rx_vl_number_1_0 (stat_rx_vl_number_1_0),
    .stat_rx_vl_number_2_0 (stat_rx_vl_number_2_0),
    .stat_rx_vl_number_3_0 (stat_rx_vl_number_3_0),
    .stat_rx_synced_0 (stat_rx_synced_0),
    .stat_rx_misaligned_0 (stat_rx_misaligned_0),
    .stat_rx_aligned_err_0 (stat_rx_aligned_err_0),
    .stat_rx_synced_err_0 (stat_rx_synced_err_0),
    .stat_rx_mf_len_err_0 (stat_rx_mf_len_err_0),
    .stat_rx_mf_repeat_err_0 (stat_rx_mf_repeat_err_0),
    .stat_rx_mf_err_0 (stat_rx_mf_err_0),
    .stat_rx_bip_err_0_0 (stat_rx_bip_err_0_0),
    .stat_rx_bip_err_1_0 (stat_rx_bip_err_1_0),
    .stat_rx_bip_err_2_0 (stat_rx_bip_err_2_0),
    .stat_rx_bip_err_3_0 (stat_rx_bip_err_3_0),
    .stat_rx_aligned_0 (stat_rx_aligned_0),
    .stat_rx_hi_ber_0 (stat_rx_hi_ber_0),
    .stat_rx_status_0 (stat_rx_status_0),
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


    .tx_reset_0 (tx_reset_0),
    .user_tx_reset_0 (user_tx_reset_0),
//// TX User Interface Signals
    .tx_axis_tready_0 (tx_axis_tready_0),
    .tx_axis_tvalid_0 (tx_axis_tvalid_0),
    .tx_axis_tdata_0 (tx_axis_tdata_0),
    .tx_axis_tuser_0 (tx_axis_tuser_0),
    .tx_unfout_0 (tx_unfout_0),

//// TX Control Signals
    .ctl_tx_send_lfi_0 (ctl_tx_send_lfi_0),
    .ctl_tx_send_rfi_0 (ctl_tx_send_rfi_0),
    .ctl_tx_send_idle_0 (ctl_tx_send_idle_0),

    .ctl_tx_pause_req_0 (ctl_tx_pause_req_0),
    .ctl_tx_resend_pause_0 (ctl_tx_resend_pause_0),

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
    .gt_ch_drpdo_0 (gt_ch_drpdo_0),
    .gt_ch_drprdy_0 (gt_ch_drprdy_0),
    .gt_ch_drpen_0 (gt_ch_drpen_0),
    .gt_ch_drpwe_0 (gt_ch_drpwe_0),
    .gt_ch_drpaddr_0 (gt_ch_drpaddr_0),
    .gt_ch_drpdi_0 (gt_ch_drpdi_0),
    .gt_ch_drpclk_0 (dclk),
    .gt_ch_drpdo_1 (gt_ch_drpdo_1),
    .gt_ch_drprdy_1 (gt_ch_drprdy_1),
    .gt_ch_drpen_1 (gt_ch_drpen_1),
    .gt_ch_drpwe_1 (gt_ch_drpwe_1),
    .gt_ch_drpaddr_1 (gt_ch_drpaddr_1),
    .gt_ch_drpdi_1 (gt_ch_drpdi_1),
    .gt_ch_drpclk_1 (dclk),
    .gt_ch_drpdo_2 (gt_ch_drpdo_2),
    .gt_ch_drprdy_2 (gt_ch_drprdy_2),
    .gt_ch_drpen_2 (gt_ch_drpen_2),
    .gt_ch_drpwe_2 (gt_ch_drpwe_2),
    .gt_ch_drpaddr_2 (gt_ch_drpaddr_2),
    .gt_ch_drpdi_2 (gt_ch_drpdi_2),
    .gt_ch_drpclk_2 (dclk),
    .gt_ch_drpdo_3 (gt_ch_drpdo_3),
    .gt_ch_drprdy_3 (gt_ch_drprdy_3),
    .gt_ch_drpen_3 (gt_ch_drpen_3),
    .gt_ch_drpwe_3 (gt_ch_drpwe_3),
    .gt_ch_drpaddr_3 (gt_ch_drpaddr_3),
    .gt_ch_drpdi_3 (gt_ch_drpdi_3),
    .gt_ch_drpclk_3 (dclk),
    .gt_common_drpclk (gt_common_drpclk),
    .gt_common_drpdo (gt_common_drpdo),
    .gt_common_drprdy (gt_common_drprdy),
    .gt_common_drpen (gt_common_drpen),
    .gt_common_drpwe (gt_common_drpwe),
    .gt_common_drpaddr (gt_common_drpaddr),
    .gt_common_drpdi (gt_common_drpdi),
    .gtwiz_reset_tx_datapath_0 (gtwiz_reset_tx_datapath_0),
    .gtwiz_reset_rx_datapath_0 (gtwiz_reset_rx_datapath_0),
    .gt_refclk_p(gt_refclk_p),
    .gt_refclk_n(gt_refclk_n),
    .sys_reset (sys_reset),
    .dclk (dclk)
);

l_ethernet_40G_qsfp_c_0_pkt_gen_mon #(
.PKT_NUM (PKT_NUM))
 i_l_ethernet_40G_qsfp_c_0_pkt_gen_mon_0
(
  .gen_clk (tx_clk_out_0),
  .mon_clk (rx_core_clk_0),
  .dclk (dclk),
  .usr_fsm_clk (usr_fsm_clk),
  .sys_reset (sys_reset),
  .restart_tx_rx (restart_tx_rx),
  //// User Interface signals
  .completion_status (completion_status_0),
//// AXI4 Lite Interface Signals
  .s_axi_aclk (s_axi_aclk_0),
  .s_axi_aresetn (s_axi_aresetn_0),
  .s_axi_awaddr (s_axi_awaddr_0),
  .s_axi_awvalid (s_axi_awvalid_0),
  .s_axi_awready (s_axi_awready_0),
  .s_axi_wdata (s_axi_wdata_0),
  .s_axi_wstrb (s_axi_wstrb_0),
  .s_axi_wvalid (s_axi_wvalid_0),
  .s_axi_wready (s_axi_wready_0),
  .s_axi_bresp (s_axi_bresp_0),
  .s_axi_bvalid (s_axi_bvalid_0),
  .s_axi_bready (s_axi_bready_0),
  .s_axi_araddr (s_axi_araddr_0),
  .s_axi_arvalid (s_axi_arvalid_0),
  .s_axi_arready (s_axi_arready_0),
  .s_axi_rdata (s_axi_rdata_0),
  .s_axi_rresp (s_axi_rresp_0),
  .s_axi_rvalid (s_axi_rvalid_0),
  .s_axi_rready (s_axi_rready_0),
  .pm_tick (pm_tick_0),
  .rx_reset (rx_reset_0),
  .user_rx_reset(user_rx_reset_0),
//// RX User IF Signals
  .rx_axis_tvalid (rx_axis_tvalid_0),
  .rx_axis_tdata (rx_axis_tdata_0),
  .rx_axis_tuser_ena0 (rx_axis_tuser_0[56:56]),
  .rx_axis_tuser_sop0 (rx_axis_tuser_0[57:57]),
  .rx_axis_tuser_eop0 (rx_axis_tuser_0[58:58]),
  .rx_axis_tuser_mty0 (rx_axis_tuser_0[61:59]),
  .rx_axis_tuser_err0 (rx_axis_tuser_0[62:62]),
  .rx_axis_tuser_ena1 (rx_axis_tuser_0[63:63]),
  .rx_axis_tuser_sop1 (rx_axis_tuser_0[64:64]),
  .rx_axis_tuser_eop1 (rx_axis_tuser_0[65:65]),
  .rx_axis_tuser_mty1 (rx_axis_tuser_0[68:66]),
  .rx_axis_tuser_err1 (rx_axis_tuser_0[69:69]),
  .rx_preambleout (rx_axis_tuser_0[55:0]),

//// RX Control Signals

  .ctl_rx_pause_ack (ctl_rx_pause_ack_0),

//// RX Stats Signals
  .stat_rx_block_lock (stat_rx_block_lock_0),
  .stat_rx_framing_err_valid_0 (stat_rx_framing_err_valid_0_0),
  .stat_rx_framing_err_0 (stat_rx_framing_err_0_0),
  .stat_rx_framing_err_valid_1 (stat_rx_framing_err_valid_1_0),
  .stat_rx_framing_err_1 (stat_rx_framing_err_1_0),
  .stat_rx_framing_err_valid_2 (stat_rx_framing_err_valid_2_0),
  .stat_rx_framing_err_2 (stat_rx_framing_err_2_0),
  .stat_rx_framing_err_valid_3 (stat_rx_framing_err_valid_3_0),
  .stat_rx_framing_err_3 (stat_rx_framing_err_3_0),
  .stat_rx_vl_demuxed (stat_rx_vl_demuxed_0),
  .stat_rx_vl_number_0 (stat_rx_vl_number_0_0),
  .stat_rx_vl_number_1 (stat_rx_vl_number_1_0),
  .stat_rx_vl_number_2 (stat_rx_vl_number_2_0),
  .stat_rx_vl_number_3 (stat_rx_vl_number_3_0),
  .stat_rx_synced (stat_rx_synced_0),
  .stat_rx_misaligned (stat_rx_misaligned_0),
  .stat_rx_aligned_err (stat_rx_aligned_err_0),
  .stat_rx_synced_err (stat_rx_synced_err_0),
  .stat_rx_mf_len_err (stat_rx_mf_len_err_0),
  .stat_rx_mf_repeat_err (stat_rx_mf_repeat_err_0),
  .stat_rx_mf_err (stat_rx_mf_err_0),
  .stat_rx_bip_err_0 (stat_rx_bip_err_0_0),
  .stat_rx_bip_err_1 (stat_rx_bip_err_1_0),
  .stat_rx_bip_err_2 (stat_rx_bip_err_2_0),
  .stat_rx_bip_err_3 (stat_rx_bip_err_3_0),
  .stat_rx_aligned (stat_rx_aligned_0),
  .stat_rx_hi_ber (stat_rx_hi_ber_0),
  .stat_rx_status (stat_rx_status_0),
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
  .tx_reset (tx_reset_0),
  .user_tx_reset (user_tx_reset_0),
//// TX User IF Signals
  .tx_axis_tready (tx_axis_tready_0),
  .tx_axis_tvalid (tx_axis_tvalid_0),
  .tx_axis_tdata (tx_axis_tdata_0),
  .tx_axis_tuser_ena0 (tx_axis_tuser_0[56:56]),
  .tx_axis_tuser_sop0 (tx_axis_tuser_0[57:57]),
  .tx_axis_tuser_eop0 (tx_axis_tuser_0[58:58]),
  .tx_axis_tuser_mty0 (tx_axis_tuser_0[61:59]),
  .tx_axis_tuser_err0 (tx_axis_tuser_0[62:62]),
  .tx_axis_tuser_ena1 (tx_axis_tuser_0[63:63]),
  .tx_axis_tuser_sop1 (tx_axis_tuser_0[64:64]),
  .tx_axis_tuser_eop1 (tx_axis_tuser_0[65:65]),
  .tx_axis_tuser_mty1 (tx_axis_tuser_0[68:66]),
  .tx_axis_tuser_err1 (tx_axis_tuser_0[69:69]),
  .tx_unfout (tx_unfout_0),
  .tx_preamblein (tx_axis_tuser_0[55:0]),

//// TX Control Signals
  .ctl_tx_send_lfi (ctl_tx_send_lfi_0),
  .ctl_tx_send_rfi (ctl_tx_send_rfi_0),
  .ctl_tx_send_idle (ctl_tx_send_idle_0),

  .ctl_tx_pause_req (ctl_tx_pause_req_0),
  .ctl_tx_resend_pause (ctl_tx_resend_pause_0),

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


  .gtwiz_reset_tx_datapath (gtwiz_reset_tx_datapath_0),
  .gtwiz_reset_rx_datapath (gtwiz_reset_rx_datapath_0),
// GT TransDebug ports
  .gt_dmonitorout (gt_dmonitorout_0),
  .gt_eyescandataerror (gt_eyescandataerror_0),
  .gt_eyescanreset (gt_eyescanreset_0),
  .gt_eyescantrigger (gt_eyescantrigger_0),
  .gt_pcsrsvdin (gt_pcsrsvdin_0),
  .gt_rxbufreset (gt_rxbufreset_0),
  .gt_rxbufstatus (gt_rxbufstatus_0),
  .gt_rxcdrhold (gt_rxcdrhold_0),
  .gt_rxcommadeten (gt_rxcommadeten_0),
  .gt_rxdfeagchold (gt_rxdfeagchold_0),
  .gt_rxdfelpmreset (gt_rxdfelpmreset_0),
  .gt_rxlatclk (gt_rxlatclk_0),
  .gt_rxlpmen (gt_rxlpmen_0),
  .gt_rxpcsreset (gt_rxpcsreset_0),
  .gt_rxpmareset (gt_rxpmareset_0),
//  .gt_rxpolarity (gt_rxpolarity_0),
  .gt_rxprbscntreset (gt_rxprbscntreset_0),
  .gt_rxprbserr (gt_rxprbserr_0),
  .gt_rxprbssel (gt_rxprbssel_0),
  .gt_rxrate (gt_rxrate_0),
  .gt_rxslide_in (gt_rxslide_in_0),
  .gt_rxstartofseq (gt_rxstartofseq_0),
  .gt_txbufstatus (gt_txbufstatus_0),
  .gt_txdiffctrl (gt_txdiffctrl_0),
  .gt_txinhibit (gt_txinhibit_0),
  .gt_txlatclk (gt_txlatclk_0),
  .gt_txmaincursor (gt_txmaincursor_0),
  .gt_txpcsreset (gt_txpcsreset_0),
  .gt_txpmareset (gt_txpmareset_0),
//  .gt_txpolarity (gt_txpolarity_0),
  .gt_txpostcursor (gt_txpostcursor_0),
  .gt_txprbsforceerr (gt_txprbsforceerr_0),
  .gt_txprbssel (gt_txprbssel_0),
  .gt_txprecursor (gt_txprecursor_0),
  .gt_ch_drpdo_0 (gt_ch_drpdo_0),
  .gt_ch_drprdy_0 (gt_ch_drprdy_0),
  .gt_ch_drpen_0 (gt_ch_drpen_0),
  .gt_ch_drpwe_0 (gt_ch_drpwe_0),
  .gt_ch_drpaddr_0 (gt_ch_drpaddr_0),
  .gt_ch_drpdi_0 (gt_ch_drpdi_0),
  .gt_ch_drpdo_1 (gt_ch_drpdo_1),
  .gt_ch_drprdy_1 (gt_ch_drprdy_1),
  .gt_ch_drpen_1 (gt_ch_drpen_1),
  .gt_ch_drpwe_1 (gt_ch_drpwe_1),
  .gt_ch_drpaddr_1 (gt_ch_drpaddr_1),
  .gt_ch_drpdi_1 (gt_ch_drpdi_1),
  .gt_ch_drpdo_2 (gt_ch_drpdo_2),
  .gt_ch_drprdy_2 (gt_ch_drprdy_2),
  .gt_ch_drpen_2 (gt_ch_drpen_2),
  .gt_ch_drpwe_2 (gt_ch_drpwe_2),
  .gt_ch_drpaddr_2 (gt_ch_drpaddr_2),
  .gt_ch_drpdi_2 (gt_ch_drpdi_2),
  .gt_ch_drpdo_3 (gt_ch_drpdo_3),
  .gt_ch_drprdy_3 (gt_ch_drprdy_3),
  .gt_ch_drpen_3 (gt_ch_drpen_3),
  .gt_ch_drpwe_3 (gt_ch_drpwe_3),
  .gt_ch_drpaddr_3 (gt_ch_drpaddr_3),
  .gt_ch_drpdi_3 (gt_ch_drpdi_3),

  .rx_gt_locked_led (rx_gt_locked_led_0),
  .rx_aligned_led (rx_aligned_led_0)
    );



assign rx_gt_locked_led  = rx_gt_locked_led_0;
assign rx_aligned_led = rx_aligned_led_0;
assign completion_status = completion_status_0;


endmodule



