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


`timescale 1ps/1ps

(* DowngradeIPIdentifiedWarnings="yes" *)
module cmac_0_exdes
(

    input           gt0_rxp_in,
    input           gt0_rxn_in,
    input           gt1_rxp_in,
    input           gt1_rxn_in,
    input           gt2_rxp_in,
    input           gt2_rxn_in,
    input           gt3_rxp_in,
    input           gt3_rxn_in,
    output          gt0_txn_out,
    output          gt0_txp_out,
    output          gt1_txn_out,
    output          gt1_txp_out,
    output          gt2_txn_out,
    output          gt2_txp_out,
    output          gt3_txn_out,
    output          gt3_txp_out,
    input           lbus_tx_rx_restart_in,
             
    output wire     tx_done_led,
    output wire     tx_busy_led,
                    
    output wire     rx_gt_locked_led,
    output wire     rx_aligned_led,
    output wire     rx_done_led,
    output wire     rx_data_fail_led,
    output wire     rx_busy_led,

    input           sys_reset,

    input           gt_ref_clk_p,
    input           gt_ref_clk_n,
    input           init_clk_p,
    input           init_clk_n
);

  parameter PKT_NUM      = 1000;    //// 1 to 65535 (Number of packets)
  parameter PKT_SIZE     = 522;     //// 64 to 16383 (Each Packet Size)

  wire [11 :0]    gt_loopback_in;

  //// For other GT loopback options please change the value appropriately
  //// For example, for Near End PMA loopback for 4 Lanes update the gt_loopback_in = {4{3'b010}};
  //// For more information and settings on loopback, refer GT Transceivers user guide

  assign gt_loopback_in  = {4{3'b000}};

  wire            usr_rx_reset;
  wire [128-1:0]  rx_dataout0;
  wire            rx_enaout0;
  wire            rx_sopout0;
  wire            rx_eopout0;
  wire            rx_errout0;
  wire [4-1:0]    rx_mtyout0;
  wire [128-1:0]  rx_dataout1;
  wire            rx_enaout1;
  wire            rx_sopout1;
  wire            rx_eopout1;
  wire            rx_errout1;
  wire [4-1:0]    rx_mtyout1;
  wire [128-1:0]  rx_dataout2;
  wire            rx_enaout2;
  wire            rx_sopout2;
  wire            rx_eopout2;
  wire            rx_errout2;
  wire [4-1:0]    rx_mtyout2;
  wire [128-1:0]  rx_dataout3;
  wire            rx_enaout3;
  wire            rx_sopout3;
  wire            rx_eopout3;
  wire            rx_errout3;
  wire [4-1:0]    rx_mtyout3;

  wire            tx_rdyout;
  wire [128-1:0]  tx_datain0;
  wire            tx_enain0;
  wire            tx_sopin0;
  wire            tx_eopin0;
  wire            tx_errin0;
  wire [4-1:0]    tx_mtyin0;
  wire [128-1:0]  tx_datain1;
  wire            tx_enain1;
  wire            tx_sopin1;
  wire            tx_eopin1;
  wire            tx_errin1;
  wire [4-1:0]    tx_mtyin1;
  wire [128-1:0]  tx_datain2;
  wire            tx_enain2;
  wire            tx_sopin2;
  wire            tx_eopin2;
  wire            tx_errin2;
  wire [4-1:0]    tx_mtyin2;
  wire [128-1:0]  tx_datain3;
  wire            tx_enain3;
  wire            tx_sopin3;
  wire            tx_eopin3;
  wire            tx_errin3;
  wire [4-1:0]    tx_mtyin3;
  wire            tx_ovfout;
  wire            tx_unfout;
  wire            usr_tx_reset;
  wire            gt_rxusrclk2;
  wire [8:0]      stat_tx_pause_valid;
  wire            stat_tx_pause;
  wire            stat_tx_user_pause;
  wire [8:0]      ctl_tx_pause_enable;
  wire [15:0]     ctl_tx_pause_quanta0;
  wire [15:0]     ctl_tx_pause_quanta1;
  wire [15:0]     ctl_tx_pause_quanta2;
  wire [15:0]     ctl_tx_pause_quanta3;
  wire [15:0]     ctl_tx_pause_quanta4;
  wire [15:0]     ctl_tx_pause_quanta5;
  wire [15:0]     ctl_tx_pause_quanta6;
  wire [15:0]     ctl_tx_pause_quanta7;
  wire [15:0]     ctl_tx_pause_quanta8;
  wire [15:0]     ctl_tx_pause_refresh_timer0;
  wire [15:0]     ctl_tx_pause_refresh_timer1;
  wire [15:0]     ctl_tx_pause_refresh_timer2;
  wire [15:0]     ctl_tx_pause_refresh_timer3;
  wire [15:0]     ctl_tx_pause_refresh_timer4;
  wire [15:0]     ctl_tx_pause_refresh_timer5;
  wire [15:0]     ctl_tx_pause_refresh_timer6;
  wire [15:0]     ctl_tx_pause_refresh_timer7;
  wire [15:0]     ctl_tx_pause_refresh_timer8;
  wire [8:0]      ctl_tx_pause_req;
  wire            ctl_tx_resend_pause;
  wire            stat_rx_pause;
  wire [15:0]     stat_rx_pause_quanta0;
  wire [15:0]     stat_rx_pause_quanta1;
  wire [15:0]     stat_rx_pause_quanta2;
  wire [15:0]     stat_rx_pause_quanta3;
  wire [15:0]     stat_rx_pause_quanta4;
  wire [15:0]     stat_rx_pause_quanta5;
  wire [15:0]     stat_rx_pause_quanta6;
  wire [15:0]     stat_rx_pause_quanta7;
  wire [15:0]     stat_rx_pause_quanta8;
  wire [8:0]      stat_rx_pause_req;
  wire [8:0]      stat_rx_pause_valid;
  wire            stat_rx_user_pause;
  wire            ctl_rx_check_etype_gcp;
  wire            ctl_rx_check_etype_gpp;
  wire            ctl_rx_check_etype_pcp;
  wire            ctl_rx_check_etype_ppp;
  wire            ctl_rx_check_mcast_gcp;
  wire            ctl_rx_check_mcast_gpp;
  wire            ctl_rx_check_mcast_pcp;
  wire            ctl_rx_check_mcast_ppp;
  wire            ctl_rx_check_opcode_gcp;
  wire            ctl_rx_check_opcode_gpp;
  wire            ctl_rx_check_opcode_pcp;
  wire            ctl_rx_check_opcode_ppp;
  wire            ctl_rx_check_sa_gcp;
  wire            ctl_rx_check_sa_gpp;
  wire            ctl_rx_check_sa_pcp;
  wire            ctl_rx_check_sa_ppp;
  wire            ctl_rx_check_ucast_gcp;
  wire            ctl_rx_check_ucast_gpp;
  wire            ctl_rx_check_ucast_pcp;
  wire            ctl_rx_check_ucast_ppp;
  wire            ctl_rx_enable_gcp;
  wire            ctl_rx_enable_gpp;
  wire            ctl_rx_enable_pcp;
  wire            ctl_rx_enable_ppp;
  wire [8:0]      ctl_rx_pause_ack;
  wire [8:0]      ctl_rx_pause_enable;
  wire            stat_rx_aligned;
  wire            stat_rx_aligned_err;
  wire [2:0]      stat_rx_bad_code;
  wire [3:0]      stat_rx_bad_fcs;
  wire            stat_rx_bad_preamble;
  wire            stat_rx_bad_sfd;
  wire            stat_rx_bip_err_0;
  wire            stat_rx_bip_err_1;
  wire            stat_rx_bip_err_10;
  wire            stat_rx_bip_err_11;
  wire            stat_rx_bip_err_12;
  wire            stat_rx_bip_err_13;
  wire            stat_rx_bip_err_14;
  wire            stat_rx_bip_err_15;
  wire            stat_rx_bip_err_16;
  wire            stat_rx_bip_err_17;
  wire            stat_rx_bip_err_18;
  wire            stat_rx_bip_err_19;
  wire            stat_rx_bip_err_2;
  wire            stat_rx_bip_err_3;
  wire            stat_rx_bip_err_4;
  wire            stat_rx_bip_err_5;
  wire            stat_rx_bip_err_6;
  wire            stat_rx_bip_err_7;
  wire            stat_rx_bip_err_8;
  wire            stat_rx_bip_err_9;
  wire [19:0]     stat_rx_block_lock;
  wire            stat_rx_broadcast;
  wire [3:0]      stat_rx_fragment;
  wire [3:0]      stat_rx_framing_err_0;
  wire [3:0]      stat_rx_framing_err_1;
  wire [3:0]      stat_rx_framing_err_10;
  wire [3:0]      stat_rx_framing_err_11;
  wire [3:0]      stat_rx_framing_err_12;
  wire [3:0]      stat_rx_framing_err_13;
  wire [3:0]      stat_rx_framing_err_14;
  wire [3:0]      stat_rx_framing_err_15;
  wire [3:0]      stat_rx_framing_err_16;
  wire [3:0]      stat_rx_framing_err_17;
  wire [3:0]      stat_rx_framing_err_18;
  wire [3:0]      stat_rx_framing_err_19;
  wire [3:0]      stat_rx_framing_err_2;
  wire [3:0]      stat_rx_framing_err_3;
  wire [3:0]      stat_rx_framing_err_4;
  wire [3:0]      stat_rx_framing_err_5;
  wire [3:0]      stat_rx_framing_err_6;
  wire [3:0]      stat_rx_framing_err_7;
  wire [3:0]      stat_rx_framing_err_8;
  wire [3:0]      stat_rx_framing_err_9;
  wire            stat_rx_framing_err_valid_0;
  wire            stat_rx_framing_err_valid_1;
  wire            stat_rx_framing_err_valid_10;
  wire            stat_rx_framing_err_valid_11;
  wire            stat_rx_framing_err_valid_12;
  wire            stat_rx_framing_err_valid_13;
  wire            stat_rx_framing_err_valid_14;
  wire            stat_rx_framing_err_valid_15;
  wire            stat_rx_framing_err_valid_16;
  wire            stat_rx_framing_err_valid_17;
  wire            stat_rx_framing_err_valid_18;
  wire            stat_rx_framing_err_valid_19;
  wire            stat_rx_framing_err_valid_2;
  wire            stat_rx_framing_err_valid_3;
  wire            stat_rx_framing_err_valid_4;
  wire            stat_rx_framing_err_valid_5;
  wire            stat_rx_framing_err_valid_6;
  wire            stat_rx_framing_err_valid_7;
  wire            stat_rx_framing_err_valid_8;
  wire            stat_rx_framing_err_valid_9;
  wire            stat_rx_got_signal_os;
  wire            stat_rx_hi_ber;
  wire            stat_rx_inrangeerr;
  wire            stat_rx_internal_local_fault;
  wire            stat_rx_jabber;
  wire            stat_rx_local_fault;
  wire [19:0]     stat_rx_mf_err;
  wire [19:0]     stat_rx_mf_len_err;
  wire [19:0]     stat_rx_mf_repeat_err;
  wire            stat_rx_misaligned;
  wire            stat_rx_multicast;
  wire            stat_rx_oversize;
  wire            stat_rx_packet_1024_1518_bytes;
  wire            stat_rx_packet_128_255_bytes;
  wire            stat_rx_packet_1519_1522_bytes;
  wire            stat_rx_packet_1523_1548_bytes;
  wire            stat_rx_packet_1549_2047_bytes;
  wire            stat_rx_packet_2048_4095_bytes;
  wire            stat_rx_packet_256_511_bytes;
  wire            stat_rx_packet_4096_8191_bytes;
  wire            stat_rx_packet_512_1023_bytes;
  wire            stat_rx_packet_64_bytes;
  wire            stat_rx_packet_65_127_bytes;
  wire            stat_rx_packet_8192_9215_bytes;
  wire            stat_rx_packet_bad_fcs;
  wire            stat_rx_packet_large;
  wire [3:0]      stat_rx_packet_small;
  wire            stat_rx_received_local_fault;
  wire            stat_rx_remote_fault;
  wire            stat_rx_status;
  wire [3:0]      stat_rx_stomped_fcs;
  wire [19:0]     stat_rx_synced;
  wire [19:0]     stat_rx_synced_err;
  wire [2:0]      stat_rx_test_pattern_mismatch;
  wire            stat_rx_toolong;
  wire [7:0]      stat_rx_total_bytes;
  wire [13:0]     stat_rx_total_good_bytes;
  wire            stat_rx_total_good_packets;
  wire [3:0]      stat_rx_total_packets;
  wire            stat_rx_truncated;
  wire [3:0]      stat_rx_undersize;
  wire            stat_rx_unicast;
  wire            stat_rx_vlan;
  wire [19:0]     stat_rx_pcsl_demuxed;
  wire [4:0]      stat_rx_pcsl_number_0;
  wire [4:0]      stat_rx_pcsl_number_1;
  wire [4:0]      stat_rx_pcsl_number_10;
  wire [4:0]      stat_rx_pcsl_number_11;
  wire [4:0]      stat_rx_pcsl_number_12;
  wire [4:0]      stat_rx_pcsl_number_13;
  wire [4:0]      stat_rx_pcsl_number_14;
  wire [4:0]      stat_rx_pcsl_number_15;
  wire [4:0]      stat_rx_pcsl_number_16;
  wire [4:0]      stat_rx_pcsl_number_17;
  wire [4:0]      stat_rx_pcsl_number_18;
  wire [4:0]      stat_rx_pcsl_number_19;
  wire [4:0]      stat_rx_pcsl_number_2;
  wire [4:0]      stat_rx_pcsl_number_3;
  wire [4:0]      stat_rx_pcsl_number_4;
  wire [4:0]      stat_rx_pcsl_number_5;
  wire [4:0]      stat_rx_pcsl_number_6;
  wire [4:0]      stat_rx_pcsl_number_7;
  wire [4:0]      stat_rx_pcsl_number_8;
  wire [4:0]      stat_rx_pcsl_number_9;
  wire            stat_tx_bad_fcs;
  wire            stat_tx_broadcast;
  wire            stat_tx_frame_error;
  wire            stat_tx_local_fault;
  wire            stat_tx_multicast;
  wire            stat_tx_packet_1024_1518_bytes;
  wire            stat_tx_packet_128_255_bytes;
  wire            stat_tx_packet_1519_1522_bytes;
  wire            stat_tx_packet_1523_1548_bytes;
  wire            stat_tx_packet_1549_2047_bytes;
  wire            stat_tx_packet_2048_4095_bytes;
  wire            stat_tx_packet_256_511_bytes;
  wire            stat_tx_packet_4096_8191_bytes;
  wire            stat_tx_packet_512_1023_bytes;
  wire            stat_tx_packet_64_bytes;
  wire            stat_tx_packet_65_127_bytes;
  wire            stat_tx_packet_8192_9215_bytes;
  wire            stat_tx_packet_large;
  wire            stat_tx_packet_small;
  wire [6:0]      stat_tx_total_bytes;
  wire [13:0]     stat_tx_total_good_bytes;
  wire            stat_tx_total_good_packets;
  wire            stat_tx_total_packets;
  wire            stat_tx_unicast;
  wire            stat_tx_vlan;
  wire            ctl_rx_enable;
  wire            ctl_rx_force_resync;
  wire            ctl_rx_test_pattern;
  wire            ctl_tx_enable;
  wire            ctl_tx_send_idle;
  wire            ctl_tx_send_rfi;
  wire            ctl_tx_test_pattern;
  wire            rx_reset;
  wire            tx_reset;
  wire [3 :0]     gt_rxrecclkout;
  wire            txusrclk2;
  wire            init_clk;

IBUFDS#(
.DQS_BIAS("FALSE")//(FALSE,TRUE)
)
IBUFDS_inst(
.O(init_clk),//1-bitoutput:Bufferoutput
.I(init_clk_p),//1-bitinput:Diff_pbufferinput(connectdirectlytotop-levelport)
.IB(init_clk_n)//1-bitinput:Diff_nbufferinput(connectdirectlytotop-levelport)
);
//EndofI

cmac_0 DUT
(
    .gt0_rxp_in                           (gt0_rxp_in),
    .gt0_rxn_in                           (gt0_rxn_in),
    .gt1_rxp_in                           (gt1_rxp_in),
    .gt1_rxn_in                           (gt1_rxn_in),
    .gt2_rxp_in                           (gt2_rxp_in),
    .gt2_rxn_in                           (gt2_rxn_in),
    .gt3_rxp_in                           (gt3_rxp_in),
    .gt3_rxn_in                           (gt3_rxn_in),
    .gt0_txp_out                          (gt0_txp_out),
    .gt0_txn_out                          (gt0_txn_out),
    .gt1_txp_out                          (gt1_txp_out),
    .gt1_txn_out                          (gt1_txn_out),
    .gt2_txp_out                          (gt2_txp_out),
    .gt2_txn_out                          (gt2_txn_out),
    .gt3_txp_out                          (gt3_txp_out),
    .gt3_txn_out                          (gt3_txn_out),
    .gt_txusrclk2                         (txusrclk2),
    .gt_loopback_in                       (gt_loopback_in),
    .gt_rxrecclkout                       (gt_rxrecclkout),
    .sys_reset                            (sys_reset),
    .gt_ref_clk_p                         (gt_ref_clk_p),
    .gt_ref_clk_n                         (gt_ref_clk_n),
    .init_clk                             (init_clk),
    .rx_dataout0                          (rx_dataout0),
    .rx_dataout1                          (rx_dataout1),
    .rx_dataout2                          (rx_dataout2),
    .rx_dataout3                          (rx_dataout3),
    .rx_enaout0                           (rx_enaout0),
    .rx_enaout1                           (rx_enaout1),
    .rx_enaout2                           (rx_enaout2),
    .rx_enaout3                           (rx_enaout3),
    .rx_eopout0                           (rx_eopout0),
    .rx_eopout1                           (rx_eopout1),
    .rx_eopout2                           (rx_eopout2),
    .rx_eopout3                           (rx_eopout3),
    .rx_errout0                           (rx_errout0),
    .rx_errout1                           (rx_errout1),
    .rx_errout2                           (rx_errout2),
    .rx_errout3                           (rx_errout3),
    .rx_mtyout0                           (rx_mtyout0),
    .rx_mtyout1                           (rx_mtyout1),
    .rx_mtyout2                           (rx_mtyout2),
    .rx_mtyout3                           (rx_mtyout3),
    .rx_sopout0                           (rx_sopout0),
    .rx_sopout1                           (rx_sopout1),
    .rx_sopout2                           (rx_sopout2),
    .rx_sopout3                           (rx_sopout3),
    .usr_rx_reset                         (usr_rx_reset),
    .gt_rxusrclk2                         (gt_rxusrclk2),
    .stat_rx_aligned                      (stat_rx_aligned),
    .stat_rx_aligned_err                  (stat_rx_aligned_err),
    .stat_rx_bad_code                     (stat_rx_bad_code),
    .stat_rx_bad_fcs                      (stat_rx_bad_fcs),
    .stat_rx_bad_preamble                 (stat_rx_bad_preamble),
    .stat_rx_bad_sfd                      (stat_rx_bad_sfd),
    .stat_rx_bip_err_0                    (stat_rx_bip_err_0),
    .stat_rx_bip_err_1                    (stat_rx_bip_err_1),
    .stat_rx_bip_err_10                   (stat_rx_bip_err_10),
    .stat_rx_bip_err_11                   (stat_rx_bip_err_11),
    .stat_rx_bip_err_12                   (stat_rx_bip_err_12),
    .stat_rx_bip_err_13                   (stat_rx_bip_err_13),
    .stat_rx_bip_err_14                   (stat_rx_bip_err_14),
    .stat_rx_bip_err_15                   (stat_rx_bip_err_15),
    .stat_rx_bip_err_16                   (stat_rx_bip_err_16),
    .stat_rx_bip_err_17                   (stat_rx_bip_err_17),
    .stat_rx_bip_err_18                   (stat_rx_bip_err_18),
    .stat_rx_bip_err_19                   (stat_rx_bip_err_19),
    .stat_rx_bip_err_2                    (stat_rx_bip_err_2),
    .stat_rx_bip_err_3                    (stat_rx_bip_err_3),
    .stat_rx_bip_err_4                    (stat_rx_bip_err_4),
    .stat_rx_bip_err_5                    (stat_rx_bip_err_5),
    .stat_rx_bip_err_6                    (stat_rx_bip_err_6),
    .stat_rx_bip_err_7                    (stat_rx_bip_err_7),
    .stat_rx_bip_err_8                    (stat_rx_bip_err_8),
    .stat_rx_bip_err_9                    (stat_rx_bip_err_9),
    .stat_rx_block_lock                   (stat_rx_block_lock),
    .stat_rx_broadcast                    (stat_rx_broadcast),
    .stat_rx_fragment                     (stat_rx_fragment),
    .stat_rx_framing_err_0                (stat_rx_framing_err_0),
    .stat_rx_framing_err_1                (stat_rx_framing_err_1),
    .stat_rx_framing_err_10               (stat_rx_framing_err_10),
    .stat_rx_framing_err_11               (stat_rx_framing_err_11),
    .stat_rx_framing_err_12               (stat_rx_framing_err_12),
    .stat_rx_framing_err_13               (stat_rx_framing_err_13),
    .stat_rx_framing_err_14               (stat_rx_framing_err_14),
    .stat_rx_framing_err_15               (stat_rx_framing_err_15),
    .stat_rx_framing_err_16               (stat_rx_framing_err_16),
    .stat_rx_framing_err_17               (stat_rx_framing_err_17),
    .stat_rx_framing_err_18               (stat_rx_framing_err_18),
    .stat_rx_framing_err_19               (stat_rx_framing_err_19),
    .stat_rx_framing_err_2                (stat_rx_framing_err_2),
    .stat_rx_framing_err_3                (stat_rx_framing_err_3),
    .stat_rx_framing_err_4                (stat_rx_framing_err_4),
    .stat_rx_framing_err_5                (stat_rx_framing_err_5),
    .stat_rx_framing_err_6                (stat_rx_framing_err_6),
    .stat_rx_framing_err_7                (stat_rx_framing_err_7),
    .stat_rx_framing_err_8                (stat_rx_framing_err_8),
    .stat_rx_framing_err_9                (stat_rx_framing_err_9),
    .stat_rx_framing_err_valid_0          (stat_rx_framing_err_valid_0),
    .stat_rx_framing_err_valid_1          (stat_rx_framing_err_valid_1),
    .stat_rx_framing_err_valid_10         (stat_rx_framing_err_valid_10),
    .stat_rx_framing_err_valid_11         (stat_rx_framing_err_valid_11),
    .stat_rx_framing_err_valid_12         (stat_rx_framing_err_valid_12),
    .stat_rx_framing_err_valid_13         (stat_rx_framing_err_valid_13),
    .stat_rx_framing_err_valid_14         (stat_rx_framing_err_valid_14),
    .stat_rx_framing_err_valid_15         (stat_rx_framing_err_valid_15),
    .stat_rx_framing_err_valid_16         (stat_rx_framing_err_valid_16),
    .stat_rx_framing_err_valid_17         (stat_rx_framing_err_valid_17),
    .stat_rx_framing_err_valid_18         (stat_rx_framing_err_valid_18),
    .stat_rx_framing_err_valid_19         (stat_rx_framing_err_valid_19),
    .stat_rx_framing_err_valid_2          (stat_rx_framing_err_valid_2),
    .stat_rx_framing_err_valid_3          (stat_rx_framing_err_valid_3),
    .stat_rx_framing_err_valid_4          (stat_rx_framing_err_valid_4),
    .stat_rx_framing_err_valid_5          (stat_rx_framing_err_valid_5),
    .stat_rx_framing_err_valid_6          (stat_rx_framing_err_valid_6),
    .stat_rx_framing_err_valid_7          (stat_rx_framing_err_valid_7),
    .stat_rx_framing_err_valid_8          (stat_rx_framing_err_valid_8),
    .stat_rx_framing_err_valid_9          (stat_rx_framing_err_valid_9),
    .stat_rx_got_signal_os                (stat_rx_got_signal_os),
    .stat_rx_hi_ber                       (stat_rx_hi_ber),
    .stat_rx_inrangeerr                   (stat_rx_inrangeerr),
    .stat_rx_internal_local_fault         (stat_rx_internal_local_fault),
    .stat_rx_jabber                       (stat_rx_jabber),
    .stat_rx_local_fault                  (stat_rx_local_fault),
    .stat_rx_mf_err                       (stat_rx_mf_err),
    .stat_rx_mf_len_err                   (stat_rx_mf_len_err),
    .stat_rx_mf_repeat_err                (stat_rx_mf_repeat_err),
    .stat_rx_misaligned                   (stat_rx_misaligned),
    .stat_rx_multicast                    (stat_rx_multicast),
    .stat_rx_oversize                     (stat_rx_oversize),
    .stat_rx_packet_1024_1518_bytes       (stat_rx_packet_1024_1518_bytes),
    .stat_rx_packet_128_255_bytes         (stat_rx_packet_128_255_bytes),
    .stat_rx_packet_1519_1522_bytes       (stat_rx_packet_1519_1522_bytes),
    .stat_rx_packet_1523_1548_bytes       (stat_rx_packet_1523_1548_bytes),
    .stat_rx_packet_1549_2047_bytes       (stat_rx_packet_1549_2047_bytes),
    .stat_rx_packet_2048_4095_bytes       (stat_rx_packet_2048_4095_bytes),
    .stat_rx_packet_256_511_bytes         (stat_rx_packet_256_511_bytes),
    .stat_rx_packet_4096_8191_bytes       (stat_rx_packet_4096_8191_bytes),
    .stat_rx_packet_512_1023_bytes        (stat_rx_packet_512_1023_bytes),
    .stat_rx_packet_64_bytes              (stat_rx_packet_64_bytes),
    .stat_rx_packet_65_127_bytes          (stat_rx_packet_65_127_bytes),
    .stat_rx_packet_8192_9215_bytes       (stat_rx_packet_8192_9215_bytes),
    .stat_rx_packet_bad_fcs               (stat_rx_packet_bad_fcs),
    .stat_rx_packet_large                 (stat_rx_packet_large),
    .stat_rx_packet_small                 (stat_rx_packet_small),
    .stat_rx_pause                        (stat_rx_pause),
    .stat_rx_pause_quanta0                (stat_rx_pause_quanta0),
    .stat_rx_pause_quanta1                (stat_rx_pause_quanta1),
    .stat_rx_pause_quanta2                (stat_rx_pause_quanta2),
    .stat_rx_pause_quanta3                (stat_rx_pause_quanta3),
    .stat_rx_pause_quanta4                (stat_rx_pause_quanta4),
    .stat_rx_pause_quanta5                (stat_rx_pause_quanta5),
    .stat_rx_pause_quanta6                (stat_rx_pause_quanta6),
    .stat_rx_pause_quanta7                (stat_rx_pause_quanta7),
    .stat_rx_pause_quanta8                (stat_rx_pause_quanta8),
    .stat_rx_pause_req                    (stat_rx_pause_req),
    .stat_rx_pause_valid                  (stat_rx_pause_valid),
    .stat_rx_user_pause                   (stat_rx_user_pause),
    .ctl_rx_check_etype_gcp               (ctl_rx_check_etype_gcp),
    .ctl_rx_check_etype_gpp               (ctl_rx_check_etype_gpp),
    .ctl_rx_check_etype_pcp               (ctl_rx_check_etype_pcp),
    .ctl_rx_check_etype_ppp               (ctl_rx_check_etype_ppp),
    .ctl_rx_check_mcast_gcp               (ctl_rx_check_mcast_gcp),
    .ctl_rx_check_mcast_gpp               (ctl_rx_check_mcast_gpp),
    .ctl_rx_check_mcast_pcp               (ctl_rx_check_mcast_pcp),
    .ctl_rx_check_mcast_ppp               (ctl_rx_check_mcast_ppp),
    .ctl_rx_check_opcode_gcp              (ctl_rx_check_opcode_gcp),
    .ctl_rx_check_opcode_gpp              (ctl_rx_check_opcode_gpp),
    .ctl_rx_check_opcode_pcp              (ctl_rx_check_opcode_pcp),
    .ctl_rx_check_opcode_ppp              (ctl_rx_check_opcode_ppp),
    .ctl_rx_check_sa_gcp                  (ctl_rx_check_sa_gcp),
    .ctl_rx_check_sa_gpp                  (ctl_rx_check_sa_gpp),
    .ctl_rx_check_sa_pcp                  (ctl_rx_check_sa_pcp),
    .ctl_rx_check_sa_ppp                  (ctl_rx_check_sa_ppp),
    .ctl_rx_check_ucast_gcp               (ctl_rx_check_ucast_gcp),
    .ctl_rx_check_ucast_gpp               (ctl_rx_check_ucast_gpp),
    .ctl_rx_check_ucast_pcp               (ctl_rx_check_ucast_pcp),
    .ctl_rx_check_ucast_ppp               (ctl_rx_check_ucast_ppp),
    .ctl_rx_enable_gcp                    (ctl_rx_enable_gcp),
    .ctl_rx_enable_gpp                    (ctl_rx_enable_gpp),
    .ctl_rx_enable_pcp                    (ctl_rx_enable_pcp),
    .ctl_rx_enable_ppp                    (ctl_rx_enable_ppp),
    .ctl_rx_pause_ack                     (ctl_rx_pause_ack),
    .ctl_rx_pause_enable                  (ctl_rx_pause_enable),
    .ctl_rx_enable                        (ctl_rx_enable),
    .ctl_rx_force_resync                  (ctl_rx_force_resync),
    .ctl_rx_test_pattern                  (ctl_rx_test_pattern),
    .core_rx_reset                        (rx_reset),
    .rx_clk                               (txusrclk2),
    .stat_rx_received_local_fault         (stat_rx_received_local_fault),
    .stat_rx_remote_fault                 (stat_rx_remote_fault),
    .stat_rx_status                       (stat_rx_status),
    .stat_rx_stomped_fcs                  (stat_rx_stomped_fcs),
    .stat_rx_synced                       (stat_rx_synced),
    .stat_rx_synced_err                   (stat_rx_synced_err),
    .stat_rx_test_pattern_mismatch        (stat_rx_test_pattern_mismatch),
    .stat_rx_toolong                      (stat_rx_toolong),
    .stat_rx_total_bytes                  (stat_rx_total_bytes),
    .stat_rx_total_good_bytes             (stat_rx_total_good_bytes),
    .stat_rx_total_good_packets           (stat_rx_total_good_packets),
    .stat_rx_total_packets                (stat_rx_total_packets),
    .stat_rx_truncated                    (stat_rx_truncated),
    .stat_rx_undersize                    (stat_rx_undersize),
    .stat_rx_unicast                      (stat_rx_unicast),
    .stat_rx_vlan                         (stat_rx_vlan),
    .stat_rx_pcsl_demuxed                 (stat_rx_pcsl_demuxed),
    .stat_rx_pcsl_number_0                (stat_rx_pcsl_number_0),
    .stat_rx_pcsl_number_1                (stat_rx_pcsl_number_1),
    .stat_rx_pcsl_number_10               (stat_rx_pcsl_number_10),
    .stat_rx_pcsl_number_11               (stat_rx_pcsl_number_11),
    .stat_rx_pcsl_number_12               (stat_rx_pcsl_number_12),
    .stat_rx_pcsl_number_13               (stat_rx_pcsl_number_13),
    .stat_rx_pcsl_number_14               (stat_rx_pcsl_number_14),
    .stat_rx_pcsl_number_15               (stat_rx_pcsl_number_15),
    .stat_rx_pcsl_number_16               (stat_rx_pcsl_number_16),
    .stat_rx_pcsl_number_17               (stat_rx_pcsl_number_17),
    .stat_rx_pcsl_number_18               (stat_rx_pcsl_number_18),
    .stat_rx_pcsl_number_19               (stat_rx_pcsl_number_19),
    .stat_rx_pcsl_number_2                (stat_rx_pcsl_number_2),
    .stat_rx_pcsl_number_3                (stat_rx_pcsl_number_3),
    .stat_rx_pcsl_number_4                (stat_rx_pcsl_number_4),
    .stat_rx_pcsl_number_5                (stat_rx_pcsl_number_5),
    .stat_rx_pcsl_number_6                (stat_rx_pcsl_number_6),
    .stat_rx_pcsl_number_7                (stat_rx_pcsl_number_7),
    .stat_rx_pcsl_number_8                (stat_rx_pcsl_number_8),
    .stat_rx_pcsl_number_9                (stat_rx_pcsl_number_9),
    .stat_tx_bad_fcs                      (stat_tx_bad_fcs),
    .stat_tx_broadcast                    (stat_tx_broadcast),
    .stat_tx_frame_error                  (stat_tx_frame_error),
    .stat_tx_local_fault                  (stat_tx_local_fault),
    .stat_tx_multicast                    (stat_tx_multicast),
    .stat_tx_packet_1024_1518_bytes       (stat_tx_packet_1024_1518_bytes),
    .stat_tx_packet_128_255_bytes         (stat_tx_packet_128_255_bytes),
    .stat_tx_packet_1519_1522_bytes       (stat_tx_packet_1519_1522_bytes),
    .stat_tx_packet_1523_1548_bytes       (stat_tx_packet_1523_1548_bytes),
    .stat_tx_packet_1549_2047_bytes       (stat_tx_packet_1549_2047_bytes),
    .stat_tx_packet_2048_4095_bytes       (stat_tx_packet_2048_4095_bytes),
    .stat_tx_packet_256_511_bytes         (stat_tx_packet_256_511_bytes),
    .stat_tx_packet_4096_8191_bytes       (stat_tx_packet_4096_8191_bytes),
    .stat_tx_packet_512_1023_bytes        (stat_tx_packet_512_1023_bytes),
    .stat_tx_packet_64_bytes              (stat_tx_packet_64_bytes),
    .stat_tx_packet_65_127_bytes          (stat_tx_packet_65_127_bytes),
    .stat_tx_packet_8192_9215_bytes       (stat_tx_packet_8192_9215_bytes),
    .stat_tx_packet_large                 (stat_tx_packet_large),
    .stat_tx_packet_small                 (stat_tx_packet_small),
    .stat_tx_total_bytes                  (stat_tx_total_bytes),
    .stat_tx_total_good_bytes             (stat_tx_total_good_bytes),
    .stat_tx_total_good_packets           (stat_tx_total_good_packets),
    .stat_tx_total_packets                (stat_tx_total_packets),
    .stat_tx_unicast                      (stat_tx_unicast),
    .stat_tx_vlan                         (stat_tx_vlan),
    .ctl_tx_enable                        (ctl_tx_enable),
    .ctl_tx_send_idle                     (ctl_tx_send_idle),
    .ctl_tx_send_rfi                      (ctl_tx_send_rfi),
    .ctl_tx_test_pattern                  (ctl_tx_test_pattern),
    .core_tx_reset                        (tx_reset),
    .stat_tx_pause_valid                  (stat_tx_pause_valid),
    .stat_tx_pause                        (stat_tx_pause),
    .stat_tx_user_pause                   (stat_tx_user_pause),
    .ctl_tx_pause_enable                  (ctl_tx_pause_enable),
    .ctl_tx_pause_quanta0                 (ctl_tx_pause_quanta0),
    .ctl_tx_pause_quanta1                 (ctl_tx_pause_quanta1),
    .ctl_tx_pause_quanta2                 (ctl_tx_pause_quanta2),
    .ctl_tx_pause_quanta3                 (ctl_tx_pause_quanta3),
    .ctl_tx_pause_quanta4                 (ctl_tx_pause_quanta4),
    .ctl_tx_pause_quanta5                 (ctl_tx_pause_quanta5),
    .ctl_tx_pause_quanta6                 (ctl_tx_pause_quanta6),
    .ctl_tx_pause_quanta7                 (ctl_tx_pause_quanta7),
    .ctl_tx_pause_quanta8                 (ctl_tx_pause_quanta8),
    .ctl_tx_pause_refresh_timer0          (ctl_tx_pause_refresh_timer0),
    .ctl_tx_pause_refresh_timer1          (ctl_tx_pause_refresh_timer1),
    .ctl_tx_pause_refresh_timer2          (ctl_tx_pause_refresh_timer2),
    .ctl_tx_pause_refresh_timer3          (ctl_tx_pause_refresh_timer3),
    .ctl_tx_pause_refresh_timer4          (ctl_tx_pause_refresh_timer4),
    .ctl_tx_pause_refresh_timer5          (ctl_tx_pause_refresh_timer5),
    .ctl_tx_pause_refresh_timer6          (ctl_tx_pause_refresh_timer6),
    .ctl_tx_pause_refresh_timer7          (ctl_tx_pause_refresh_timer7),
    .ctl_tx_pause_refresh_timer8          (ctl_tx_pause_refresh_timer8),
    .ctl_tx_pause_req                     (ctl_tx_pause_req),
    .ctl_tx_resend_pause                  (ctl_tx_resend_pause),
    .tx_ovfout                            (tx_ovfout),
    .tx_rdyout                            (tx_rdyout),
    .tx_unfout                            (tx_unfout),
    .tx_datain0                           (tx_datain0),
    .tx_datain1                           (tx_datain1),
    .tx_datain2                           (tx_datain2),
    .tx_datain3                           (tx_datain3),
    .tx_enain0                            (tx_enain0),
    .tx_enain1                            (tx_enain1),
    .tx_enain2                            (tx_enain2),
    .tx_enain3                            (tx_enain3),
    .tx_eopin0                            (tx_eopin0),
    .tx_eopin1                            (tx_eopin1),
    .tx_eopin2                            (tx_eopin2),
    .tx_eopin3                            (tx_eopin3),
    .tx_errin0                            (tx_errin0),
    .tx_errin1                            (tx_errin1),
    .tx_errin2                            (tx_errin2),
    .tx_errin3                            (tx_errin3),
    .tx_mtyin0                            (tx_mtyin0),
    .tx_mtyin1                            (tx_mtyin1),
    .tx_mtyin2                            (tx_mtyin2),
    .tx_mtyin3                            (tx_mtyin3),
    .tx_sopin0                            (tx_sopin0),
    .tx_sopin1                            (tx_sopin1),
    .tx_sopin2                            (tx_sopin2),
    .tx_sopin3                            (tx_sopin3),
    .usr_tx_reset                         (usr_tx_reset),
    .core_drp_reset                       (1'b0),
    .drp_clk                              (1'b0),
    .drp_addr                             (10'b0),
    .drp_di                               (16'b0),
    .drp_en                               (1'b0),
    .drp_do                               (),
    .drp_rdy                              (),
    .drp_we                               (1'b0)
);

cmac_0_pkt_gen_mon
#(
    .PKT_NUM                              (PKT_NUM),
    .PKT_SIZE                             (PKT_SIZE)
) i_cmac_0_pkt_gen_mon  
(
    .gen_mon_clk                          (txusrclk2),
    .usr_tx_reset                         (usr_tx_reset),
    .usr_rx_reset                         (usr_rx_reset),
    .sys_reset                            (sys_reset),
    .lbus_tx_rx_restart_in                (lbus_tx_rx_restart_in),
    .tx_rdyout                            (tx_rdyout),
    .tx_datain0                           (tx_datain0),
    .tx_enain0                            (tx_enain0),
    .tx_sopin0                            (tx_sopin0),
    .tx_eopin0                            (tx_eopin0),
    .tx_errin0                            (tx_errin0),
    .tx_mtyin0                            (tx_mtyin0),
    .tx_datain1                           (tx_datain1),
    .tx_enain1                            (tx_enain1),
    .tx_sopin1                            (tx_sopin1),
    .tx_eopin1                            (tx_eopin1),
    .tx_errin1                            (tx_errin1),
    .tx_mtyin1                            (tx_mtyin1),
    .tx_datain2                           (tx_datain2),
    .tx_enain2                            (tx_enain2),
    .tx_sopin2                            (tx_sopin2),
    .tx_eopin2                            (tx_eopin2),
    .tx_errin2                            (tx_errin2),
    .tx_mtyin2                            (tx_mtyin2),
    .tx_datain3                           (tx_datain3),
    .tx_enain3                            (tx_enain3),
    .tx_sopin3                            (tx_sopin3),
    .tx_eopin3                            (tx_eopin3),
    .tx_errin3                            (tx_errin3),
    .tx_mtyin3                            (tx_mtyin3),
    .tx_ovfout                            (tx_ovfout),
    .tx_unfout                            (tx_unfout),
    .rx_dataout0                          (rx_dataout0),
    .rx_enaout0                           (rx_enaout0),
    .rx_sopout0                           (rx_sopout0),
    .rx_eopout0                           (rx_eopout0),
    .rx_errout0                           (rx_errout0),
    .rx_mtyout0                           (rx_mtyout0),
    .rx_dataout1                          (rx_dataout1),
    .rx_enaout1                           (rx_enaout1),
    .rx_sopout1                           (rx_sopout1),
    .rx_eopout1                           (rx_eopout1),
    .rx_errout1                           (rx_errout1),
    .rx_mtyout1                           (rx_mtyout1),
    .rx_dataout2                          (rx_dataout2),
    .rx_enaout2                           (rx_enaout2),
    .rx_sopout2                           (rx_sopout2),
    .rx_eopout2                           (rx_eopout2),
    .rx_errout2                           (rx_errout2),
    .rx_mtyout2                           (rx_mtyout2),
    .rx_dataout3                          (rx_dataout3),
    .rx_enaout3                           (rx_enaout3),
    .rx_sopout3                           (rx_sopout3),
    .rx_eopout3                           (rx_eopout3),
    .rx_errout3                           (rx_errout3),
    .rx_mtyout3                           (rx_mtyout3),
    .ctl_tx_enable                        (ctl_tx_enable),
    .stat_tx_pause_valid                  (stat_tx_pause_valid),
    .stat_tx_pause                        (stat_tx_pause),
    .stat_tx_user_pause                   (stat_tx_user_pause),
    .ctl_tx_pause_enable                  (ctl_tx_pause_enable),
    .ctl_tx_pause_quanta0                 (ctl_tx_pause_quanta0),
    .ctl_tx_pause_quanta1                 (ctl_tx_pause_quanta1),
    .ctl_tx_pause_quanta2                 (ctl_tx_pause_quanta2),
    .ctl_tx_pause_quanta3                 (ctl_tx_pause_quanta3),
    .ctl_tx_pause_quanta4                 (ctl_tx_pause_quanta4),
    .ctl_tx_pause_quanta5                 (ctl_tx_pause_quanta5),
    .ctl_tx_pause_quanta6                 (ctl_tx_pause_quanta6),
    .ctl_tx_pause_quanta7                 (ctl_tx_pause_quanta7),
    .ctl_tx_pause_quanta8                 (ctl_tx_pause_quanta8),
    .ctl_tx_pause_refresh_timer0          (ctl_tx_pause_refresh_timer0),
    .ctl_tx_pause_refresh_timer1          (ctl_tx_pause_refresh_timer1),
    .ctl_tx_pause_refresh_timer2          (ctl_tx_pause_refresh_timer2),
    .ctl_tx_pause_refresh_timer3          (ctl_tx_pause_refresh_timer3),
    .ctl_tx_pause_refresh_timer4          (ctl_tx_pause_refresh_timer4),
    .ctl_tx_pause_refresh_timer5          (ctl_tx_pause_refresh_timer5),
    .ctl_tx_pause_refresh_timer6          (ctl_tx_pause_refresh_timer6),
    .ctl_tx_pause_refresh_timer7          (ctl_tx_pause_refresh_timer7),
    .ctl_tx_pause_refresh_timer8          (ctl_tx_pause_refresh_timer8),
    .ctl_tx_pause_req                     (ctl_tx_pause_req),
    .ctl_tx_resend_pause                  (ctl_tx_resend_pause),
    .stat_rx_pause                        (stat_rx_pause),
    .stat_rx_pause_quanta0                (stat_rx_pause_quanta0),
    .stat_rx_pause_quanta1                (stat_rx_pause_quanta1),
    .stat_rx_pause_quanta2                (stat_rx_pause_quanta2),
    .stat_rx_pause_quanta3                (stat_rx_pause_quanta3),
    .stat_rx_pause_quanta4                (stat_rx_pause_quanta4),
    .stat_rx_pause_quanta5                (stat_rx_pause_quanta5),
    .stat_rx_pause_quanta6                (stat_rx_pause_quanta6),
    .stat_rx_pause_quanta7                (stat_rx_pause_quanta7),
    .stat_rx_pause_quanta8                (stat_rx_pause_quanta8),
    .stat_rx_pause_req                    (stat_rx_pause_req),
    .stat_rx_pause_valid                  (stat_rx_pause_valid),
    .stat_rx_user_pause                   (stat_rx_user_pause),
    .ctl_rx_check_etype_gcp               (ctl_rx_check_etype_gcp),
    .ctl_rx_check_etype_gpp               (ctl_rx_check_etype_gpp),
    .ctl_rx_check_etype_pcp               (ctl_rx_check_etype_pcp),
    .ctl_rx_check_etype_ppp               (ctl_rx_check_etype_ppp),
    .ctl_rx_check_mcast_gcp               (ctl_rx_check_mcast_gcp),
    .ctl_rx_check_mcast_gpp               (ctl_rx_check_mcast_gpp),
    .ctl_rx_check_mcast_pcp               (ctl_rx_check_mcast_pcp),
    .ctl_rx_check_mcast_ppp               (ctl_rx_check_mcast_ppp),
    .ctl_rx_check_opcode_gcp              (ctl_rx_check_opcode_gcp),
    .ctl_rx_check_opcode_gpp              (ctl_rx_check_opcode_gpp),
    .ctl_rx_check_opcode_pcp              (ctl_rx_check_opcode_pcp),
    .ctl_rx_check_opcode_ppp              (ctl_rx_check_opcode_ppp),
    .ctl_rx_check_sa_gcp                  (ctl_rx_check_sa_gcp),
    .ctl_rx_check_sa_gpp                  (ctl_rx_check_sa_gpp),
    .ctl_rx_check_sa_pcp                  (ctl_rx_check_sa_pcp),
    .ctl_rx_check_sa_ppp                  (ctl_rx_check_sa_ppp),
    .ctl_rx_check_ucast_gcp               (ctl_rx_check_ucast_gcp),
    .ctl_rx_check_ucast_gpp               (ctl_rx_check_ucast_gpp),
    .ctl_rx_check_ucast_pcp               (ctl_rx_check_ucast_pcp),
    .ctl_rx_check_ucast_ppp               (ctl_rx_check_ucast_ppp),
    .ctl_rx_enable_gcp                    (ctl_rx_enable_gcp),
    .ctl_rx_enable_gpp                    (ctl_rx_enable_gpp),
    .ctl_rx_enable_pcp                    (ctl_rx_enable_pcp),
    .ctl_rx_enable_ppp                    (ctl_rx_enable_ppp),
    .ctl_rx_pause_ack                     (ctl_rx_pause_ack),
    .ctl_rx_pause_enable                  (ctl_rx_pause_enable),
    .stat_rx_aligned_err                  (stat_rx_aligned_err),
    .stat_rx_bad_code                     (stat_rx_bad_code),
    .stat_rx_bad_fcs                      (stat_rx_bad_fcs),
    .stat_rx_bad_preamble                 (stat_rx_bad_preamble),
    .stat_rx_bad_sfd                      (stat_rx_bad_sfd),
    .stat_rx_bip_err_0                    (stat_rx_bip_err_0),
    .stat_rx_bip_err_1                    (stat_rx_bip_err_1),
    .stat_rx_bip_err_10                   (stat_rx_bip_err_10),
    .stat_rx_bip_err_11                   (stat_rx_bip_err_11),
    .stat_rx_bip_err_12                   (stat_rx_bip_err_12),
    .stat_rx_bip_err_13                   (stat_rx_bip_err_13),
    .stat_rx_bip_err_14                   (stat_rx_bip_err_14),
    .stat_rx_bip_err_15                   (stat_rx_bip_err_15),
    .stat_rx_bip_err_16                   (stat_rx_bip_err_16),
    .stat_rx_bip_err_17                   (stat_rx_bip_err_17),
    .stat_rx_bip_err_18                   (stat_rx_bip_err_18),
    .stat_rx_bip_err_19                   (stat_rx_bip_err_19),
    .stat_rx_bip_err_2                    (stat_rx_bip_err_2),
    .stat_rx_bip_err_3                    (stat_rx_bip_err_3),
    .stat_rx_bip_err_4                    (stat_rx_bip_err_4),
    .stat_rx_bip_err_5                    (stat_rx_bip_err_5),
    .stat_rx_bip_err_6                    (stat_rx_bip_err_6),
    .stat_rx_bip_err_7                    (stat_rx_bip_err_7),
    .stat_rx_bip_err_8                    (stat_rx_bip_err_8),
    .stat_rx_bip_err_9                    (stat_rx_bip_err_9),
    .stat_rx_block_lock                   (stat_rx_block_lock),
    .stat_rx_broadcast                    (stat_rx_broadcast),
    .stat_rx_fragment                     (stat_rx_fragment),
    .stat_rx_framing_err_0                (stat_rx_framing_err_0),
    .stat_rx_framing_err_1                (stat_rx_framing_err_1),
    .stat_rx_framing_err_10               (stat_rx_framing_err_10),
    .stat_rx_framing_err_11               (stat_rx_framing_err_11),
    .stat_rx_framing_err_12               (stat_rx_framing_err_12),
    .stat_rx_framing_err_13               (stat_rx_framing_err_13),
    .stat_rx_framing_err_14               (stat_rx_framing_err_14),
    .stat_rx_framing_err_15               (stat_rx_framing_err_15),
    .stat_rx_framing_err_16               (stat_rx_framing_err_16),
    .stat_rx_framing_err_17               (stat_rx_framing_err_17),
    .stat_rx_framing_err_18               (stat_rx_framing_err_18),
    .stat_rx_framing_err_19               (stat_rx_framing_err_19),
    .stat_rx_framing_err_2                (stat_rx_framing_err_2),
    .stat_rx_framing_err_3                (stat_rx_framing_err_3),
    .stat_rx_framing_err_4                (stat_rx_framing_err_4),
    .stat_rx_framing_err_5                (stat_rx_framing_err_5),
    .stat_rx_framing_err_6                (stat_rx_framing_err_6),
    .stat_rx_framing_err_7                (stat_rx_framing_err_7),
    .stat_rx_framing_err_8                (stat_rx_framing_err_8),
    .stat_rx_framing_err_9                (stat_rx_framing_err_9),
    .stat_rx_framing_err_valid_0          (stat_rx_framing_err_valid_0),
    .stat_rx_framing_err_valid_1          (stat_rx_framing_err_valid_1),
    .stat_rx_framing_err_valid_10         (stat_rx_framing_err_valid_10),
    .stat_rx_framing_err_valid_11         (stat_rx_framing_err_valid_11),
    .stat_rx_framing_err_valid_12         (stat_rx_framing_err_valid_12),
    .stat_rx_framing_err_valid_13         (stat_rx_framing_err_valid_13),
    .stat_rx_framing_err_valid_14         (stat_rx_framing_err_valid_14),
    .stat_rx_framing_err_valid_15         (stat_rx_framing_err_valid_15),
    .stat_rx_framing_err_valid_16         (stat_rx_framing_err_valid_16),
    .stat_rx_framing_err_valid_17         (stat_rx_framing_err_valid_17),
    .stat_rx_framing_err_valid_18         (stat_rx_framing_err_valid_18),
    .stat_rx_framing_err_valid_19         (stat_rx_framing_err_valid_19),
    .stat_rx_framing_err_valid_2          (stat_rx_framing_err_valid_2),
    .stat_rx_framing_err_valid_3          (stat_rx_framing_err_valid_3),
    .stat_rx_framing_err_valid_4          (stat_rx_framing_err_valid_4),
    .stat_rx_framing_err_valid_5          (stat_rx_framing_err_valid_5),
    .stat_rx_framing_err_valid_6          (stat_rx_framing_err_valid_6),
    .stat_rx_framing_err_valid_7          (stat_rx_framing_err_valid_7),
    .stat_rx_framing_err_valid_8          (stat_rx_framing_err_valid_8),
    .stat_rx_framing_err_valid_9          (stat_rx_framing_err_valid_9),
    .stat_rx_got_signal_os                (stat_rx_got_signal_os),
    .stat_rx_hi_ber                       (stat_rx_hi_ber),
    .stat_rx_inrangeerr                   (stat_rx_inrangeerr),
    .stat_rx_internal_local_fault         (stat_rx_internal_local_fault),
    .stat_rx_jabber                       (stat_rx_jabber),
    .stat_rx_local_fault                  (stat_rx_local_fault),
    .stat_rx_mf_err                       (stat_rx_mf_err),
    .stat_rx_mf_len_err                   (stat_rx_mf_len_err),
    .stat_rx_mf_repeat_err                (stat_rx_mf_repeat_err),
    .stat_rx_misaligned                   (stat_rx_misaligned),
    .stat_rx_multicast                    (stat_rx_multicast),
    .stat_rx_oversize                     (stat_rx_oversize),
    .stat_rx_packet_1024_1518_bytes       (stat_rx_packet_1024_1518_bytes),
    .stat_rx_packet_128_255_bytes         (stat_rx_packet_128_255_bytes),
    .stat_rx_packet_1519_1522_bytes       (stat_rx_packet_1519_1522_bytes),
    .stat_rx_packet_1523_1548_bytes       (stat_rx_packet_1523_1548_bytes),
    .stat_rx_packet_1549_2047_bytes       (stat_rx_packet_1549_2047_bytes),
    .stat_rx_packet_2048_4095_bytes       (stat_rx_packet_2048_4095_bytes),
    .stat_rx_packet_256_511_bytes         (stat_rx_packet_256_511_bytes),
    .stat_rx_packet_4096_8191_bytes       (stat_rx_packet_4096_8191_bytes),
    .stat_rx_packet_512_1023_bytes        (stat_rx_packet_512_1023_bytes),
    .stat_rx_packet_64_bytes              (stat_rx_packet_64_bytes),
    .stat_rx_packet_65_127_bytes          (stat_rx_packet_65_127_bytes),
    .stat_rx_packet_8192_9215_bytes       (stat_rx_packet_8192_9215_bytes),
    .stat_rx_packet_bad_fcs               (stat_rx_packet_bad_fcs),
    .stat_rx_packet_large                 (stat_rx_packet_large),
    .stat_rx_packet_small                 (stat_rx_packet_small),
    .stat_rx_received_local_fault         (stat_rx_received_local_fault),
    .stat_rx_remote_fault                 (stat_rx_remote_fault),
    .stat_rx_status                       (stat_rx_status),
    .stat_rx_stomped_fcs                  (stat_rx_stomped_fcs),
    .stat_rx_synced                       (stat_rx_synced),
    .stat_rx_synced_err                   (stat_rx_synced_err),
    .stat_rx_test_pattern_mismatch        (stat_rx_test_pattern_mismatch),
    .stat_rx_toolong                      (stat_rx_toolong),
    .stat_rx_total_bytes                  (stat_rx_total_bytes),
    .stat_rx_total_good_bytes             (stat_rx_total_good_bytes),
    .stat_rx_total_good_packets           (stat_rx_total_good_packets),
    .stat_rx_total_packets                (stat_rx_total_packets),
    .stat_rx_truncated                    (stat_rx_truncated),
    .stat_rx_undersize                    (stat_rx_undersize),
    .stat_rx_unicast                      (stat_rx_unicast),
    .stat_rx_vlan                         (stat_rx_vlan),
    .stat_rx_pcsl_demuxed                 (stat_rx_pcsl_demuxed),
    .stat_rx_pcsl_number_0                (stat_rx_pcsl_number_0),
    .stat_rx_pcsl_number_1                (stat_rx_pcsl_number_1),
    .stat_rx_pcsl_number_10               (stat_rx_pcsl_number_10),
    .stat_rx_pcsl_number_11               (stat_rx_pcsl_number_11),
    .stat_rx_pcsl_number_12               (stat_rx_pcsl_number_12),
    .stat_rx_pcsl_number_13               (stat_rx_pcsl_number_13),
    .stat_rx_pcsl_number_14               (stat_rx_pcsl_number_14),
    .stat_rx_pcsl_number_15               (stat_rx_pcsl_number_15),
    .stat_rx_pcsl_number_16               (stat_rx_pcsl_number_16),
    .stat_rx_pcsl_number_17               (stat_rx_pcsl_number_17),
    .stat_rx_pcsl_number_18               (stat_rx_pcsl_number_18),
    .stat_rx_pcsl_number_19               (stat_rx_pcsl_number_19),
    .stat_rx_pcsl_number_2                (stat_rx_pcsl_number_2),
    .stat_rx_pcsl_number_3                (stat_rx_pcsl_number_3),
    .stat_rx_pcsl_number_4                (stat_rx_pcsl_number_4),
    .stat_rx_pcsl_number_5                (stat_rx_pcsl_number_5),
    .stat_rx_pcsl_number_6                (stat_rx_pcsl_number_6),
    .stat_rx_pcsl_number_7                (stat_rx_pcsl_number_7),
    .stat_rx_pcsl_number_8                (stat_rx_pcsl_number_8),
    .stat_rx_pcsl_number_9                (stat_rx_pcsl_number_9),
    .stat_tx_bad_fcs                      (stat_tx_bad_fcs),
    .stat_rx_aligned                      (stat_rx_aligned),
    .stat_tx_broadcast                    (stat_tx_broadcast),
    .stat_tx_frame_error                  (stat_tx_frame_error),
    .stat_tx_local_fault                  (stat_tx_local_fault),
    .stat_tx_multicast                    (stat_tx_multicast),
    .stat_tx_packet_1024_1518_bytes       (stat_tx_packet_1024_1518_bytes),
    .stat_tx_packet_128_255_bytes         (stat_tx_packet_128_255_bytes),
    .stat_tx_packet_1519_1522_bytes       (stat_tx_packet_1519_1522_bytes),
    .stat_tx_packet_1523_1548_bytes       (stat_tx_packet_1523_1548_bytes),
    .stat_tx_packet_1549_2047_bytes       (stat_tx_packet_1549_2047_bytes),
    .stat_tx_packet_2048_4095_bytes       (stat_tx_packet_2048_4095_bytes),
    .stat_tx_packet_256_511_bytes         (stat_tx_packet_256_511_bytes),
    .stat_tx_packet_4096_8191_bytes       (stat_tx_packet_4096_8191_bytes),
    .stat_tx_packet_512_1023_bytes        (stat_tx_packet_512_1023_bytes),
    .stat_tx_packet_64_bytes              (stat_tx_packet_64_bytes),
    .stat_tx_packet_65_127_bytes          (stat_tx_packet_65_127_bytes),
    .stat_tx_packet_8192_9215_bytes       (stat_tx_packet_8192_9215_bytes),
    .stat_tx_packet_large                 (stat_tx_packet_large),
    .stat_tx_packet_small                 (stat_tx_packet_small),
    .stat_tx_total_bytes                  (stat_tx_total_bytes),
    .stat_tx_total_good_bytes             (stat_tx_total_good_bytes),
    .stat_tx_total_good_packets           (stat_tx_total_good_packets),
    .stat_tx_total_packets                (stat_tx_total_packets),
    .stat_tx_unicast                      (stat_tx_unicast),
    .stat_tx_vlan                         (stat_tx_vlan),
    .ctl_rx_enable                        (ctl_rx_enable),
    .ctl_rx_force_resync                  (ctl_rx_force_resync),
    .ctl_rx_test_pattern                  (ctl_rx_test_pattern),
    .ctl_tx_send_idle                     (ctl_tx_send_idle),
    .ctl_tx_send_rfi                      (ctl_tx_send_rfi),
    .ctl_tx_test_pattern                  (ctl_tx_test_pattern),
    .rx_reset                             (rx_reset),
    .tx_reset                             (tx_reset),
    .gt_rxrecclkout                       (gt_rxrecclkout),
    .tx_done_led                          (tx_done_led),
    .tx_busy_led                          (tx_busy_led),
    .rx_gt_locked_led                     (rx_gt_locked_led),
    .rx_aligned_led                       (rx_aligned_led),
    .rx_done_led                          (rx_done_led),
    .rx_data_fail_led                     (rx_data_fail_led),
    .rx_busy_led                          (rx_busy_led)
);



endmodule

