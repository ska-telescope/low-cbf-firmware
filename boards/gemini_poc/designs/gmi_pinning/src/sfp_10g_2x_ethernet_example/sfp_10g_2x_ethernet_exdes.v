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
module sfp_10g_2x_ethernet_exdes
(

    input  wire gt_rxp_in_0,
    input  wire gt_rxn_in_0,
    output wire gt_txp_out_0,
    output wire gt_txn_out_0,
    input wire  restart_tx_rx_0,
    output wire rx_gt_locked_led_0,     // Indicated GT LOCK
    output wire rx_block_lock_led_0,    // Indicated Core Block Lock
    input  wire gt_rxp_in_1,
    input  wire gt_rxn_in_1,
    output wire gt_txp_out_1,
    output wire gt_txn_out_1,
    input wire  restart_tx_rx_1,
    output wire rx_gt_locked_led_1,     // Indicated GT LOCK
    output wire rx_block_lock_led_1,    // Indicated Core Block Lock
    output wire [4:0] completion_status,

    input             sys_reset,
    input             gt_refclk_p,
    input             gt_refclk_n,
    input             dclk,

    input wire gt_rxpolarity_0,
    input wire gt_rxpolarity_1,
    input wire gt_txpolarity_0,
    input wire gt_txpolarity_1
);

  parameter PKT_NUM         = 20;    //// Many Internal Counters are based on PKT_NUM = 20

  
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
//  wire [0:0] gt_rxpolarity_0;
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
//  wire [0:0] gt_txpolarity_0;
  wire [4:0] gt_txpostcursor_0;
  wire [0:0] gt_txprbsforceerr_0;
  wire [3:0] gt_txprbssel_0;
  wire [4:0] gt_txprecursor_0;
  wire [0:0] gtwiz_reset_tx_datapath_0;
  wire [0:0] gtwiz_reset_rx_datapath_0;
////GT DRP interface signals
  wire [15:0] gt_drpdo_0;
  wire [0:0] gt_drprdy_0;
  wire [0:0] gt_drpen_0;
  wire [0:0] gt_drpwe_0;
  wire [9:0] gt_drpaddr_0;
  wire [15:0] gt_drpdi_0;
  wire tx_clk_out_0;
  wire rx_clk_out_0;

  wire [2:0] gt_loopback_in_0; 

//// For other GT loopback options please change the value appropriately
//// For example, for internal loopback gt_loopback_in[2:0] = 3'b010;
//// For more information and settings on loopback, refer GT Transceivers user guide

  assign gt_loopback_in_0 = 3'b000;
                                                
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



//// RX_0 Stats Signals
  wire stat_rx_block_lock_0;
  wire stat_rx_framing_err_valid_0;
  wire [2:0] stat_rx_framing_err_0;
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


//// TX_0 Stats Signals
  wire stat_tx_ptp_fifo_read_error_0;
  wire stat_tx_ptp_fifo_write_error_0;
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





////GT Transceiver debug interface signals
  wire [16:0] gt_dmonitorout_1;
  wire [0:0] gt_eyescandataerror_1;
  wire [0:0] gt_eyescanreset_1;
  wire [0:0] gt_eyescantrigger_1;
  wire [15:0] gt_pcsrsvdin_1;
  wire [0:0] gt_rxbufreset_1;
  wire [2:0] gt_rxbufstatus_1;
  wire [0:0] gt_rxcdrhold_1;
  wire [0:0] gt_rxcommadeten_1;
  wire [0:0] gt_rxdfeagchold_1;
  wire [0:0] gt_rxdfelpmreset_1;
  wire [0:0] gt_rxlatclk_1;
  wire [0:0] gt_rxlpmen_1;
  wire [0:0] gt_rxpcsreset_1;
  wire [0:0] gt_rxpmareset_1;
//  wire [0:0] gt_rxpolarity_1;
  wire [0:0] gt_rxprbscntreset_1;
  wire [0:0] gt_rxprbserr_1;
  wire [3:0] gt_rxprbssel_1;
  wire [2:0] gt_rxrate_1;
  wire [0:0] gt_rxslide_in_1;
  wire [1:0] gt_rxstartofseq_1;
  wire [1:0] gt_txbufstatus_1;
  wire [4:0] gt_txdiffctrl_1;
  wire [0:0] gt_txinhibit_1;
  wire [0:0] gt_txlatclk_1;
  wire [6:0] gt_txmaincursor_1;
  wire [0:0] gt_txpcsreset_1;
  wire [0:0] gt_txpmareset_1;
//  wire [0:0] gt_txpolarity_1;
  wire [4:0] gt_txpostcursor_1;
  wire [0:0] gt_txprbsforceerr_1;
  wire [3:0] gt_txprbssel_1;
  wire [4:0] gt_txprecursor_1;
  wire [0:0] gtwiz_reset_tx_datapath_1;
  wire [0:0] gtwiz_reset_rx_datapath_1;
////GT DRP interface signals
  wire [15:0] gt_drpdo_1;
  wire [0:0] gt_drprdy_1;
  wire [0:0] gt_drpen_1;
  wire [0:0] gt_drpwe_1;
  wire [9:0] gt_drpaddr_1;
  wire [15:0] gt_drpdi_1;
  wire tx_clk_out_1;
  wire rx_clk_out_1;

  wire [2:0] gt_loopback_in_1; 

//// For other GT loopback options please change the value appropriately
//// For example, for internal loopback gt_loopback_in[2:0] = 3'b010;
//// For more information and settings on loopback, refer GT Transceivers user guide

  assign gt_loopback_in_1 = 3'b000;
                                                
//// RX_1 Signals
  wire rx_reset_1;
  wire user_rx_reset_1;
  wire rxrecclkout_1;

//// RX_1 User Interface Signals
  wire rx_axis_tvalid_1;
  wire [63:0] rx_axis_tdata_1;
  wire rx_axis_tlast_1;
  wire [7:0] rx_axis_tkeep_1;
  wire rx_axis_tuser_1;
  wire [55:0] rx_preambleout_1;


//// RX_1 Control Signals
  wire ctl_rx_test_pattern_1;
  wire ctl_rx_test_pattern_enable_1;
  wire ctl_rx_data_pattern_select_1;
  wire ctl_rx_enable_1;
  wire ctl_rx_delete_fcs_1;
  wire ctl_rx_ignore_fcs_1;
  wire [14:0] ctl_rx_max_packet_len_1;
  wire [7:0] ctl_rx_min_packet_len_1;
  wire ctl_rx_custom_preamble_enable_1;
  wire ctl_rx_check_sfd_1;
  wire ctl_rx_check_preamble_1;
  wire ctl_rx_process_lfi_1;
  wire ctl_rx_force_resync_1;



//// RX_1 Stats Signals
  wire stat_rx_block_lock_1;
  wire stat_rx_framing_err_valid_1;
  wire [2:0] stat_rx_framing_err_1;
  wire stat_rx_hi_ber_1;
  wire stat_rx_valid_ctrl_code_1;
  wire stat_rx_bad_code_1;
  wire [1:0] stat_rx_total_packets_1;
  wire stat_rx_total_good_packets_1;
  wire [3:0] stat_rx_total_bytes_1;
  wire [13:0] stat_rx_total_good_bytes_1;
  wire stat_rx_packet_small_1;
  wire stat_rx_jabber_1;
  wire stat_rx_packet_large_1;
  wire stat_rx_oversize_1;
  wire stat_rx_undersize_1;
  wire stat_rx_toolong_1;
  wire stat_rx_fragment_1;
  wire stat_rx_packet_64_bytes_1;
  wire stat_rx_packet_65_127_bytes_1;
  wire stat_rx_packet_128_255_bytes_1;
  wire stat_rx_packet_256_511_bytes_1;
  wire stat_rx_packet_512_1023_bytes_1;
  wire stat_rx_packet_1024_1518_bytes_1;
  wire stat_rx_packet_1519_1522_bytes_1;
  wire stat_rx_packet_1523_1548_bytes_1;
  wire [1:0] stat_rx_bad_fcs_1;
  wire stat_rx_packet_bad_fcs_1;
  wire [1:0] stat_rx_stomped_fcs_1;
  wire stat_rx_packet_1549_2047_bytes_1;
  wire stat_rx_packet_2048_4095_bytes_1;
  wire stat_rx_packet_4096_8191_bytes_1;
  wire stat_rx_packet_8192_9215_bytes_1;
  wire stat_rx_bad_preamble_1;
  wire stat_rx_bad_sfd_1;
  wire stat_rx_got_signal_os_1;
  wire stat_rx_test_pattern_mismatch_1;
  wire stat_rx_truncated_1;
  wire stat_rx_local_fault_1;
  wire stat_rx_remote_fault_1;
  wire stat_rx_internal_local_fault_1;
  wire stat_rx_received_local_fault_1;


//// TX_1 Signals
  wire tx_reset_1;
  wire user_tx_reset_1;

//// TX_1 User Interface Signals
  wire tx_axis_tready_1;
  wire tx_axis_tvalid_1;
  wire [63:0] tx_axis_tdata_1;
  wire tx_axis_tlast_1;
  wire [7:0] tx_axis_tkeep_1;
  wire tx_axis_tuser_1;
  wire [55:0] tx_preamblein_1;

//// TX_1 Control Signals
  wire ctl_tx_test_pattern_1;
  wire ctl_tx_test_pattern_enable_1;
  wire ctl_tx_test_pattern_select_1;
  wire ctl_tx_data_pattern_select_1;
  wire [57:0] ctl_tx_test_pattern_seed_a_1;
  wire [57:0] ctl_tx_test_pattern_seed_b_1;
  wire ctl_tx_enable_1;
  wire ctl_tx_fcs_ins_enable_1;
  wire [3:0] ctl_tx_ipg_value_1;
  wire ctl_tx_send_lfi_1;
  wire ctl_tx_send_rfi_1;
  wire ctl_tx_send_idle_1;
  wire ctl_tx_custom_preamble_enable_1;
  wire ctl_tx_ignore_fcs_1;


//// TX_1 Stats Signals
  wire stat_tx_ptp_fifo_read_error_1;
  wire stat_tx_ptp_fifo_write_error_1;
  wire stat_tx_total_packets_1;
  wire [3:0] stat_tx_total_bytes_1;
  wire stat_tx_total_good_packets_1;
  wire [13:0] stat_tx_total_good_bytes_1;
  wire stat_tx_packet_64_bytes_1;
  wire stat_tx_packet_65_127_bytes_1;
  wire stat_tx_packet_128_255_bytes_1;
  wire stat_tx_packet_256_511_bytes_1;
  wire stat_tx_packet_512_1023_bytes_1;
  wire stat_tx_packet_1024_1518_bytes_1;
  wire stat_tx_packet_1519_1522_bytes_1;
  wire stat_tx_packet_1523_1548_bytes_1;
  wire stat_tx_packet_small_1;
  wire stat_tx_packet_large_1;
  wire stat_tx_packet_1549_2047_bytes_1;
  wire stat_tx_packet_2048_4095_bytes_1;
  wire stat_tx_packet_4096_8191_bytes_1;
  wire stat_tx_packet_8192_9215_bytes_1;
  wire stat_tx_bad_fcs_1;
  wire stat_tx_frame_error_1;
  wire stat_tx_local_fault_1;






  wire  [4:0 ]completion_status_0;
  wire  [4:0 ]completion_status_1;




sfp_10g_2x_ethernet DUT
(
    .gt_rxp_in_0 (gt_rxp_in_0),
    .gt_rxn_in_0 (gt_rxn_in_0),
    .gt_txp_out_0 (gt_txp_out_0),
    .gt_txn_out_0 (gt_txn_out_0),

    .tx_clk_out_0 (tx_clk_out_0),
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



    .tx_reset_0 (tx_reset_0),
    .user_tx_reset_0 (user_tx_reset_0),
//// TX User Interface Signals
    .tx_axis_tready_0 (tx_axis_tready_0),
    .tx_axis_tvalid_0 (tx_axis_tvalid_0),
    .tx_axis_tdata_0 (tx_axis_tdata_0),
    .tx_axis_tlast_0 (tx_axis_tlast_0),
    .tx_axis_tkeep_0 (tx_axis_tkeep_0),
    .tx_axis_tuser_0 (tx_axis_tuser_0),
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


//// TX Stats Signals
    .stat_tx_ptp_fifo_read_error_0 (stat_tx_ptp_fifo_read_error_0),
    .stat_tx_ptp_fifo_write_error_0 (stat_tx_ptp_fifo_write_error_0),
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
    .gtwiz_reset_tx_datapath_0 (gtwiz_reset_tx_datapath_0),
    .gtwiz_reset_rx_datapath_0 (gtwiz_reset_rx_datapath_0),
    .gt_drpdo_0 (gt_drpdo_0),
    .gt_drprdy_0 (gt_drprdy_0),
    .gt_drpen_0 (gt_drpen_0),
    .gt_drpwe_0 (gt_drpwe_0),
    .gt_drpaddr_0 (gt_drpaddr_0),
    .gt_drpdi_0 (gt_drpdi_0),
    .gt_drpclk_0 (dclk),


    .gt_rxp_in_1 (gt_rxp_in_1),
    .gt_rxn_in_1 (gt_rxn_in_1),
    .gt_txp_out_1 (gt_txp_out_1),
    .gt_txn_out_1 (gt_txn_out_1),

    .tx_clk_out_1 (tx_clk_out_1),
    .rx_clk_out_1 (rx_clk_out_1),

    .gt_loopback_in_1 (gt_loopback_in_1),
    .rx_reset_1 (rx_reset_1),
    .user_rx_reset_1 (user_rx_reset_1),
    .rxrecclkout_1 (rxrecclkout_1),


//// RX User Interface Signals
    .rx_axis_tvalid_1 (rx_axis_tvalid_1),
    .rx_axis_tdata_1 (rx_axis_tdata_1),
    .rx_axis_tlast_1 (rx_axis_tlast_1),
    .rx_axis_tkeep_1 (rx_axis_tkeep_1),
    .rx_axis_tuser_1 (rx_axis_tuser_1),
    .rx_preambleout_1 (rx_preambleout_1),


//// RX Control Signals
    .ctl_rx_test_pattern_1 (ctl_rx_test_pattern_1),
    .ctl_rx_test_pattern_enable_1 (ctl_rx_test_pattern_enable_1),
    .ctl_rx_data_pattern_select_1 (ctl_rx_data_pattern_select_1),
    .ctl_rx_enable_1 (ctl_rx_enable_1),
    .ctl_rx_delete_fcs_1 (ctl_rx_delete_fcs_1),
    .ctl_rx_ignore_fcs_1 (ctl_rx_ignore_fcs_1),
    .ctl_rx_max_packet_len_1 (ctl_rx_max_packet_len_1),
    .ctl_rx_min_packet_len_1 (ctl_rx_min_packet_len_1),
    .ctl_rx_custom_preamble_enable_1 (ctl_rx_custom_preamble_enable_1),
    .ctl_rx_check_sfd_1 (ctl_rx_check_sfd_1),
    .ctl_rx_check_preamble_1 (ctl_rx_check_preamble_1),
    .ctl_rx_process_lfi_1 (ctl_rx_process_lfi_1),
    .ctl_rx_force_resync_1 (ctl_rx_force_resync_1),



//// RX Stats Signals
    .stat_rx_block_lock_1 (stat_rx_block_lock_1),
    .stat_rx_framing_err_valid_1 (stat_rx_framing_err_valid_1),
    .stat_rx_framing_err_1 (stat_rx_framing_err_1),
    .stat_rx_hi_ber_1 (stat_rx_hi_ber_1),
    .stat_rx_valid_ctrl_code_1 (stat_rx_valid_ctrl_code_1),
    .stat_rx_bad_code_1 (stat_rx_bad_code_1),
    .stat_rx_total_packets_1 (stat_rx_total_packets_1),
    .stat_rx_total_good_packets_1 (stat_rx_total_good_packets_1),
    .stat_rx_total_bytes_1 (stat_rx_total_bytes_1),
    .stat_rx_total_good_bytes_1 (stat_rx_total_good_bytes_1),
    .stat_rx_packet_small_1 (stat_rx_packet_small_1),
    .stat_rx_jabber_1 (stat_rx_jabber_1),
    .stat_rx_packet_large_1 (stat_rx_packet_large_1),
    .stat_rx_oversize_1 (stat_rx_oversize_1),
    .stat_rx_undersize_1 (stat_rx_undersize_1),
    .stat_rx_toolong_1 (stat_rx_toolong_1),
    .stat_rx_fragment_1 (stat_rx_fragment_1),
    .stat_rx_packet_64_bytes_1 (stat_rx_packet_64_bytes_1),
    .stat_rx_packet_65_127_bytes_1 (stat_rx_packet_65_127_bytes_1),
    .stat_rx_packet_128_255_bytes_1 (stat_rx_packet_128_255_bytes_1),
    .stat_rx_packet_256_511_bytes_1 (stat_rx_packet_256_511_bytes_1),
    .stat_rx_packet_512_1023_bytes_1 (stat_rx_packet_512_1023_bytes_1),
    .stat_rx_packet_1024_1518_bytes_1 (stat_rx_packet_1024_1518_bytes_1),
    .stat_rx_packet_1519_1522_bytes_1 (stat_rx_packet_1519_1522_bytes_1),
    .stat_rx_packet_1523_1548_bytes_1 (stat_rx_packet_1523_1548_bytes_1),
    .stat_rx_bad_fcs_1 (stat_rx_bad_fcs_1),
    .stat_rx_packet_bad_fcs_1 (stat_rx_packet_bad_fcs_1),
    .stat_rx_stomped_fcs_1 (stat_rx_stomped_fcs_1),
    .stat_rx_packet_1549_2047_bytes_1 (stat_rx_packet_1549_2047_bytes_1),
    .stat_rx_packet_2048_4095_bytes_1 (stat_rx_packet_2048_4095_bytes_1),
    .stat_rx_packet_4096_8191_bytes_1 (stat_rx_packet_4096_8191_bytes_1),
    .stat_rx_packet_8192_9215_bytes_1 (stat_rx_packet_8192_9215_bytes_1),
    .stat_rx_bad_preamble_1 (stat_rx_bad_preamble_1),
    .stat_rx_bad_sfd_1 (stat_rx_bad_sfd_1),
    .stat_rx_got_signal_os_1 (stat_rx_got_signal_os_1),
    .stat_rx_test_pattern_mismatch_1 (stat_rx_test_pattern_mismatch_1),
    .stat_rx_truncated_1 (stat_rx_truncated_1),
    .stat_rx_local_fault_1 (stat_rx_local_fault_1),
    .stat_rx_remote_fault_1 (stat_rx_remote_fault_1),
    .stat_rx_internal_local_fault_1 (stat_rx_internal_local_fault_1),
    .stat_rx_received_local_fault_1 (stat_rx_received_local_fault_1),



    .tx_reset_1 (tx_reset_1),
    .user_tx_reset_1 (user_tx_reset_1),
//// TX User Interface Signals
    .tx_axis_tready_1 (tx_axis_tready_1),
    .tx_axis_tvalid_1 (tx_axis_tvalid_1),
    .tx_axis_tdata_1 (tx_axis_tdata_1),
    .tx_axis_tlast_1 (tx_axis_tlast_1),
    .tx_axis_tkeep_1 (tx_axis_tkeep_1),
    .tx_axis_tuser_1 (tx_axis_tuser_1),
    .tx_preamblein_1 (tx_preamblein_1),

//// TX Control Signals
    .ctl_tx_test_pattern_1 (ctl_tx_test_pattern_1),
    .ctl_tx_test_pattern_enable_1 (ctl_tx_test_pattern_enable_1),
    .ctl_tx_test_pattern_select_1 (ctl_tx_test_pattern_select_1),
    .ctl_tx_data_pattern_select_1 (ctl_tx_data_pattern_select_1),
    .ctl_tx_test_pattern_seed_a_1 (ctl_tx_test_pattern_seed_a_1),
    .ctl_tx_test_pattern_seed_b_1 (ctl_tx_test_pattern_seed_b_1),
    .ctl_tx_enable_1 (ctl_tx_enable_1),
    .ctl_tx_fcs_ins_enable_1 (ctl_tx_fcs_ins_enable_1),
    .ctl_tx_ipg_value_1 (ctl_tx_ipg_value_1),
    .ctl_tx_send_lfi_1 (ctl_tx_send_lfi_1),
    .ctl_tx_send_rfi_1 (ctl_tx_send_rfi_1),
    .ctl_tx_send_idle_1 (ctl_tx_send_idle_1),
    .ctl_tx_custom_preamble_enable_1 (ctl_tx_custom_preamble_enable_1),
    .ctl_tx_ignore_fcs_1 (ctl_tx_ignore_fcs_1),


//// TX Stats Signals
    .stat_tx_ptp_fifo_read_error_1 (stat_tx_ptp_fifo_read_error_1),
    .stat_tx_ptp_fifo_write_error_1 (stat_tx_ptp_fifo_write_error_1),
    .stat_tx_total_packets_1 (stat_tx_total_packets_1),
    .stat_tx_total_bytes_1 (stat_tx_total_bytes_1),
    .stat_tx_total_good_packets_1 (stat_tx_total_good_packets_1),
    .stat_tx_total_good_bytes_1 (stat_tx_total_good_bytes_1),
    .stat_tx_packet_64_bytes_1 (stat_tx_packet_64_bytes_1),
    .stat_tx_packet_65_127_bytes_1 (stat_tx_packet_65_127_bytes_1),
    .stat_tx_packet_128_255_bytes_1 (stat_tx_packet_128_255_bytes_1),
    .stat_tx_packet_256_511_bytes_1 (stat_tx_packet_256_511_bytes_1),
    .stat_tx_packet_512_1023_bytes_1 (stat_tx_packet_512_1023_bytes_1),
    .stat_tx_packet_1024_1518_bytes_1 (stat_tx_packet_1024_1518_bytes_1),
    .stat_tx_packet_1519_1522_bytes_1 (stat_tx_packet_1519_1522_bytes_1),
    .stat_tx_packet_1523_1548_bytes_1 (stat_tx_packet_1523_1548_bytes_1),
    .stat_tx_packet_small_1 (stat_tx_packet_small_1),
    .stat_tx_packet_large_1 (stat_tx_packet_large_1),
    .stat_tx_packet_1549_2047_bytes_1 (stat_tx_packet_1549_2047_bytes_1),
    .stat_tx_packet_2048_4095_bytes_1 (stat_tx_packet_2048_4095_bytes_1),
    .stat_tx_packet_4096_8191_bytes_1 (stat_tx_packet_4096_8191_bytes_1),
    .stat_tx_packet_8192_9215_bytes_1 (stat_tx_packet_8192_9215_bytes_1),
    .stat_tx_bad_fcs_1 (stat_tx_bad_fcs_1),
    .stat_tx_frame_error_1 (stat_tx_frame_error_1),
    .stat_tx_local_fault_1 (stat_tx_local_fault_1),




    .gt_dmonitorout_1 (gt_dmonitorout_1),
    .gt_eyescandataerror_1 (gt_eyescandataerror_1),
    .gt_eyescanreset_1 (gt_eyescanreset_1),
    .gt_eyescantrigger_1 (gt_eyescantrigger_1),
    .gt_pcsrsvdin_1 (gt_pcsrsvdin_1),
    .gt_rxbufreset_1 (gt_rxbufreset_1),
    .gt_rxbufstatus_1 (gt_rxbufstatus_1),
    .gt_rxcdrhold_1 (gt_rxcdrhold_1),
    .gt_rxcommadeten_1 (gt_rxcommadeten_1),
    .gt_rxdfeagchold_1 (gt_rxdfeagchold_1),
    .gt_rxdfelpmreset_1 (gt_rxdfelpmreset_1),
    .gt_rxlatclk_1 (gt_rxlatclk_1),
    .gt_rxlpmen_1 (gt_rxlpmen_1),
    .gt_rxpcsreset_1 (gt_rxpcsreset_1),
    .gt_rxpmareset_1 (gt_rxpmareset_1),
    .gt_rxpolarity_1 (gt_rxpolarity_1),
    .gt_rxprbscntreset_1 (gt_rxprbscntreset_1),
    .gt_rxprbserr_1 (gt_rxprbserr_1),
    .gt_rxprbssel_1 (gt_rxprbssel_1),
    .gt_rxrate_1 (gt_rxrate_1),
    .gt_rxslide_in_1 (gt_rxslide_in_1),
    .gt_rxstartofseq_1 (gt_rxstartofseq_1),
    .gt_txbufstatus_1 (gt_txbufstatus_1),
    .gt_txdiffctrl_1 (gt_txdiffctrl_1),
    .gt_txinhibit_1 (gt_txinhibit_1),
    .gt_txlatclk_1 (gt_txlatclk_1),
    .gt_txmaincursor_1 (gt_txmaincursor_1),
    .gt_txpcsreset_1 (gt_txpcsreset_1),
    .gt_txpmareset_1 (gt_txpmareset_1),
    .gt_txpolarity_1 (gt_txpolarity_1),
    .gt_txpostcursor_1 (gt_txpostcursor_1),
    .gt_txprbsforceerr_1 (gt_txprbsforceerr_1),
    .gt_txprbssel_1 (gt_txprbssel_1),
    .gt_txprecursor_1 (gt_txprecursor_1),
    .gtwiz_reset_tx_datapath_1 (gtwiz_reset_tx_datapath_1),
    .gtwiz_reset_rx_datapath_1 (gtwiz_reset_rx_datapath_1),
    .gt_drpdo_1 (gt_drpdo_1),
    .gt_drprdy_1 (gt_drprdy_1),
    .gt_drpen_1 (gt_drpen_1),
    .gt_drpwe_1 (gt_drpwe_1),
    .gt_drpaddr_1 (gt_drpaddr_1),
    .gt_drpdi_1 (gt_drpdi_1),
    .gt_drpclk_1 (dclk),


    .gt_refclk_p (gt_refclk_p),
    .gt_refclk_n (gt_refclk_n),
    .sys_reset (sys_reset),
    .dclk (dclk)
);

sfp_10g_2x_ethernet_pkt_gen_mon #(
.PKT_NUM (PKT_NUM))i_sfp_10g_2x_ethernet_pkt_gen_mon_0
(
  .gen_clk (tx_clk_out_0),
  .mon_clk (rx_clk_out_0),
  .dclk (dclk),
  .sys_reset (sys_reset),
  //// User Interface signals
  .completion_status (completion_status_0),
  .restart_tx_rx (restart_tx_rx_0),
//// Trans debug  prots
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
  .gtwiz_reset_tx_datapath (gtwiz_reset_tx_datapath_0),
  .gtwiz_reset_rx_datapath (gtwiz_reset_rx_datapath_0),
//// GT DRP prots
  .gt_drpdo (gt_drpdo_0),
  .gt_drprdy (gt_drprdy_0),
  .gt_drpen (gt_drpen_0),
  .gt_drpwe (gt_drpwe_0),
  .gt_drpaddr (gt_drpaddr_0),
  .gt_drpdi (gt_drpdi_0),
//// RX Signals
  .rx_reset(rx_reset_0),
  .user_rx_reset(user_rx_reset_0),
  .rx_axis_tvalid (rx_axis_tvalid_0),
  .rx_axis_tdata (rx_axis_tdata_0),
  .rx_axis_tlast (rx_axis_tlast_0),
  .rx_axis_tkeep (rx_axis_tkeep_0),
  .rx_axis_tuser (rx_axis_tuser_0),
  .rx_preambleout (rx_preambleout_0),


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


  .tx_reset(tx_reset_0),
  .user_tx_reset (user_tx_reset_0),
//// TX LBUS Signals
  .tx_axis_tready (tx_axis_tready_0),
  .tx_axis_tvalid (tx_axis_tvalid_0),
  .tx_axis_tdata (tx_axis_tdata_0),
  .tx_axis_tlast (tx_axis_tlast_0),
  .tx_axis_tkeep (tx_axis_tkeep_0),
  .tx_axis_tuser (tx_axis_tuser_0),
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


//// TX Stats Signals
  .stat_tx_ptp_fifo_read_error (stat_tx_ptp_fifo_read_error_0),
  .stat_tx_ptp_fifo_write_error (stat_tx_ptp_fifo_write_error_0),
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

   
  .rx_gt_locked_led (rx_gt_locked_led_0),
  .rx_block_lock_led (rx_block_lock_led_0)
    );


sfp_10g_2x_ethernet_pkt_gen_mon #(
.PKT_NUM (PKT_NUM))i_sfp_10g_2x_ethernet_pkt_gen_mon_1
(
  .gen_clk (tx_clk_out_1),
  .mon_clk (rx_clk_out_1),
  .dclk (dclk),
  .sys_reset (sys_reset),
  //// User Interface signals
  .completion_status (completion_status_1),
  .restart_tx_rx (restart_tx_rx_1),
//// Trans debug  prots
  .gt_dmonitorout (gt_dmonitorout_1),
  .gt_eyescandataerror (gt_eyescandataerror_1),
  .gt_eyescanreset (gt_eyescanreset_1),
  .gt_eyescantrigger (gt_eyescantrigger_1),
  .gt_pcsrsvdin (gt_pcsrsvdin_1),
  .gt_rxbufreset (gt_rxbufreset_1),
  .gt_rxbufstatus (gt_rxbufstatus_1),
  .gt_rxcdrhold (gt_rxcdrhold_1),
  .gt_rxcommadeten (gt_rxcommadeten_1),
  .gt_rxdfeagchold (gt_rxdfeagchold_1),
  .gt_rxdfelpmreset (gt_rxdfelpmreset_1),
  .gt_rxlatclk (gt_rxlatclk_1),
  .gt_rxlpmen (gt_rxlpmen_1),
  .gt_rxpcsreset (gt_rxpcsreset_1),
  .gt_rxpmareset (gt_rxpmareset_1),
//  .gt_rxpolarity (gt_rxpolarity_1),
  .gt_rxprbscntreset (gt_rxprbscntreset_1),
  .gt_rxprbserr (gt_rxprbserr_1),
  .gt_rxprbssel (gt_rxprbssel_1),
  .gt_rxrate (gt_rxrate_1),
  .gt_rxslide_in (gt_rxslide_in_1),
  .gt_rxstartofseq (gt_rxstartofseq_1),
  .gt_txbufstatus (gt_txbufstatus_1),
  .gt_txdiffctrl (gt_txdiffctrl_1),
  .gt_txinhibit (gt_txinhibit_1),
  .gt_txlatclk (gt_txlatclk_1),
  .gt_txmaincursor (gt_txmaincursor_1),
  .gt_txpcsreset (gt_txpcsreset_1),
  .gt_txpmareset (gt_txpmareset_1),
//  .gt_txpolarity (gt_txpolarity_1),
  .gt_txpostcursor (gt_txpostcursor_1),
  .gt_txprbsforceerr (gt_txprbsforceerr_1),
  .gt_txprbssel (gt_txprbssel_1),
  .gt_txprecursor (gt_txprecursor_1),
  .gtwiz_reset_tx_datapath (gtwiz_reset_tx_datapath_1),
  .gtwiz_reset_rx_datapath (gtwiz_reset_rx_datapath_1),
//// GT DRP prots
  .gt_drpdo (gt_drpdo_1),
  .gt_drprdy (gt_drprdy_1),
  .gt_drpen (gt_drpen_1),
  .gt_drpwe (gt_drpwe_1),
  .gt_drpaddr (gt_drpaddr_1),
  .gt_drpdi (gt_drpdi_1),
//// RX Signals
  .rx_reset(rx_reset_1),
  .user_rx_reset(user_rx_reset_1),
  .rx_axis_tvalid (rx_axis_tvalid_1),
  .rx_axis_tdata (rx_axis_tdata_1),
  .rx_axis_tlast (rx_axis_tlast_1),
  .rx_axis_tkeep (rx_axis_tkeep_1),
  .rx_axis_tuser (rx_axis_tuser_1),
  .rx_preambleout (rx_preambleout_1),


//// RX Control Signals
  .ctl_rx_test_pattern (ctl_rx_test_pattern_1),
  .ctl_rx_test_pattern_enable (ctl_rx_test_pattern_enable_1),
  .ctl_rx_data_pattern_select (ctl_rx_data_pattern_select_1),
  .ctl_rx_enable (ctl_rx_enable_1),
  .ctl_rx_delete_fcs (ctl_rx_delete_fcs_1),
  .ctl_rx_ignore_fcs (ctl_rx_ignore_fcs_1),
  .ctl_rx_max_packet_len (ctl_rx_max_packet_len_1),
  .ctl_rx_min_packet_len (ctl_rx_min_packet_len_1),
  .ctl_rx_custom_preamble_enable (ctl_rx_custom_preamble_enable_1),
  .ctl_rx_check_sfd (ctl_rx_check_sfd_1),
  .ctl_rx_check_preamble (ctl_rx_check_preamble_1),
  .ctl_rx_process_lfi (ctl_rx_process_lfi_1),
  .ctl_rx_force_resync (ctl_rx_force_resync_1),



//// RX Stats Signals
  .stat_rx_block_lock (stat_rx_block_lock_1),
  .stat_rx_framing_err_valid (stat_rx_framing_err_valid_1),
  .stat_rx_framing_err (stat_rx_framing_err_1),
  .stat_rx_hi_ber (stat_rx_hi_ber_1),
  .stat_rx_valid_ctrl_code (stat_rx_valid_ctrl_code_1),
  .stat_rx_bad_code (stat_rx_bad_code_1),
  .stat_rx_total_packets (stat_rx_total_packets_1),
  .stat_rx_total_good_packets (stat_rx_total_good_packets_1),
  .stat_rx_total_bytes (stat_rx_total_bytes_1),
  .stat_rx_total_good_bytes (stat_rx_total_good_bytes_1),
  .stat_rx_packet_small (stat_rx_packet_small_1),
  .stat_rx_jabber (stat_rx_jabber_1),
  .stat_rx_packet_large (stat_rx_packet_large_1),
  .stat_rx_oversize (stat_rx_oversize_1),
  .stat_rx_undersize (stat_rx_undersize_1),
  .stat_rx_toolong (stat_rx_toolong_1),
  .stat_rx_fragment (stat_rx_fragment_1),
  .stat_rx_packet_64_bytes (stat_rx_packet_64_bytes_1),
  .stat_rx_packet_65_127_bytes (stat_rx_packet_65_127_bytes_1),
  .stat_rx_packet_128_255_bytes (stat_rx_packet_128_255_bytes_1),
  .stat_rx_packet_256_511_bytes (stat_rx_packet_256_511_bytes_1),
  .stat_rx_packet_512_1023_bytes (stat_rx_packet_512_1023_bytes_1),
  .stat_rx_packet_1024_1518_bytes (stat_rx_packet_1024_1518_bytes_1),
  .stat_rx_packet_1519_1522_bytes (stat_rx_packet_1519_1522_bytes_1),
  .stat_rx_packet_1523_1548_bytes (stat_rx_packet_1523_1548_bytes_1),
  .stat_rx_bad_fcs (stat_rx_bad_fcs_1),
  .stat_rx_packet_bad_fcs (stat_rx_packet_bad_fcs_1),
  .stat_rx_stomped_fcs (stat_rx_stomped_fcs_1),
  .stat_rx_packet_1549_2047_bytes (stat_rx_packet_1549_2047_bytes_1),
  .stat_rx_packet_2048_4095_bytes (stat_rx_packet_2048_4095_bytes_1),
  .stat_rx_packet_4096_8191_bytes (stat_rx_packet_4096_8191_bytes_1),
  .stat_rx_packet_8192_9215_bytes (stat_rx_packet_8192_9215_bytes_1),
  .stat_rx_bad_preamble (stat_rx_bad_preamble_1),
  .stat_rx_bad_sfd (stat_rx_bad_sfd_1),
  .stat_rx_got_signal_os (stat_rx_got_signal_os_1),
  .stat_rx_test_pattern_mismatch (stat_rx_test_pattern_mismatch_1),
  .stat_rx_truncated (stat_rx_truncated_1),
  .stat_rx_local_fault (stat_rx_local_fault_1),
  .stat_rx_remote_fault (stat_rx_remote_fault_1),
  .stat_rx_internal_local_fault (stat_rx_internal_local_fault_1),
  .stat_rx_received_local_fault (stat_rx_received_local_fault_1),


  .tx_reset(tx_reset_1),
  .user_tx_reset (user_tx_reset_1),
//// TX LBUS Signals
  .tx_axis_tready (tx_axis_tready_1),
  .tx_axis_tvalid (tx_axis_tvalid_1),
  .tx_axis_tdata (tx_axis_tdata_1),
  .tx_axis_tlast (tx_axis_tlast_1),
  .tx_axis_tkeep (tx_axis_tkeep_1),
  .tx_axis_tuser (tx_axis_tuser_1),
  .tx_preamblein (tx_preamblein_1),

//// TX Control Signals
  .ctl_tx_test_pattern (ctl_tx_test_pattern_1),
  .ctl_tx_test_pattern_enable (ctl_tx_test_pattern_enable_1),
  .ctl_tx_test_pattern_select (ctl_tx_test_pattern_select_1),
  .ctl_tx_data_pattern_select (ctl_tx_data_pattern_select_1),
  .ctl_tx_test_pattern_seed_a (ctl_tx_test_pattern_seed_a_1),
  .ctl_tx_test_pattern_seed_b (ctl_tx_test_pattern_seed_b_1),
  .ctl_tx_enable (ctl_tx_enable_1),
  .ctl_tx_fcs_ins_enable (ctl_tx_fcs_ins_enable_1),
  .ctl_tx_ipg_value (ctl_tx_ipg_value_1),
  .ctl_tx_send_lfi (ctl_tx_send_lfi_1),
  .ctl_tx_send_rfi (ctl_tx_send_rfi_1),
  .ctl_tx_send_idle (ctl_tx_send_idle_1),
  .ctl_tx_custom_preamble_enable (ctl_tx_custom_preamble_enable_1),
  .ctl_tx_ignore_fcs (ctl_tx_ignore_fcs_1),


//// TX Stats Signals
  .stat_tx_ptp_fifo_read_error (stat_tx_ptp_fifo_read_error_1),
  .stat_tx_ptp_fifo_write_error (stat_tx_ptp_fifo_write_error_1),
  .stat_tx_total_packets (stat_tx_total_packets_1),
  .stat_tx_total_bytes (stat_tx_total_bytes_1),
  .stat_tx_total_good_packets (stat_tx_total_good_packets_1),
  .stat_tx_total_good_bytes (stat_tx_total_good_bytes_1),
  .stat_tx_packet_64_bytes (stat_tx_packet_64_bytes_1),
  .stat_tx_packet_65_127_bytes (stat_tx_packet_65_127_bytes_1),
  .stat_tx_packet_128_255_bytes (stat_tx_packet_128_255_bytes_1),
  .stat_tx_packet_256_511_bytes (stat_tx_packet_256_511_bytes_1),
  .stat_tx_packet_512_1023_bytes (stat_tx_packet_512_1023_bytes_1),
  .stat_tx_packet_1024_1518_bytes (stat_tx_packet_1024_1518_bytes_1),
  .stat_tx_packet_1519_1522_bytes (stat_tx_packet_1519_1522_bytes_1),
  .stat_tx_packet_1523_1548_bytes (stat_tx_packet_1523_1548_bytes_1),
  .stat_tx_packet_small (stat_tx_packet_small_1),
  .stat_tx_packet_large (stat_tx_packet_large_1),
  .stat_tx_packet_1549_2047_bytes (stat_tx_packet_1549_2047_bytes_1),
  .stat_tx_packet_2048_4095_bytes (stat_tx_packet_2048_4095_bytes_1),
  .stat_tx_packet_4096_8191_bytes (stat_tx_packet_4096_8191_bytes_1),
  .stat_tx_packet_8192_9215_bytes (stat_tx_packet_8192_9215_bytes_1),
  .stat_tx_bad_fcs (stat_tx_bad_fcs_1),
  .stat_tx_frame_error (stat_tx_frame_error_1),
  .stat_tx_local_fault (stat_tx_local_fault_1),

   
  .rx_gt_locked_led (rx_gt_locked_led_1),
  .rx_block_lock_led (rx_block_lock_led_1)
    );



assign completion_status[0] = completion_status_0[0] & completion_status_1[0];
assign completion_status[1] = completion_status_0[1] & completion_status_1[1];
assign completion_status[2] = completion_status_0[2] & completion_status_1[2];
assign completion_status[3] = completion_status_0[3] & completion_status_1[3];
assign completion_status[4] = completion_status_0[4] & completion_status_1[4];


endmodule



