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
module ip_xcku040_mac10g_noaxi_axis_traffic_gen_mon (
  input  wire tx_clk,
  input  wire rx_clk,
  input  wire tx_resetn,
  input  wire rx_resetn,
  input  wire sys_reset,

//// RX Control Signals
//  output wire ctl_rx_test_pattern,
//  output wire ctl_rx_test_pattern_enable,
//  output wire ctl_rx_data_pattern_select,
//  output wire ctl_rx_enable,
//  output wire ctl_rx_delete_fcs,
//  output wire ctl_rx_ignore_fcs,
//  output wire [14:0] ctl_rx_max_packet_len,
//  output wire [7:0] ctl_rx_min_packet_len,
//  output wire ctl_rx_custom_preamble_enable,
//  output wire ctl_rx_check_sfd,
//  output wire ctl_rx_check_preamble,
//  output wire ctl_rx_process_lfi,
//  output wire ctl_rx_force_resync,

//  output wire ctl_rx_forward_control,
//  output wire [8:0] ctl_rx_pause_ack,
//  output wire ctl_rx_check_ack,
//  output wire [8:0] ctl_rx_pause_enable,
//  output wire ctl_rx_enable_gcp,
//  output wire ctl_rx_check_mcast_gcp,
//  output wire ctl_rx_check_ucast_gcp,
//  output wire [47:0] ctl_rx_pause_da_ucast,
//  output wire ctl_rx_check_sa_gcp,
//  output wire [47:0] ctl_rx_pause_sa,
//  output wire ctl_rx_check_etype_gcp,
//  output wire [15:0] ctl_rx_etype_gcp,
//  output wire ctl_rx_check_opcode_gcp,
//  output wire [15:0] ctl_rx_opcode_min_gcp,
//  output wire [15:0] ctl_rx_opcode_max_gcp,
//  output wire ctl_rx_enable_pcp,
//  output wire ctl_rx_check_mcast_pcp,
//  output wire ctl_rx_check_ucast_pcp,
//  output wire [47:0] ctl_rx_pause_da_mcast,
//  output wire ctl_rx_check_sa_pcp,
//  output wire ctl_rx_check_etype_pcp,
//  output wire [15:0] ctl_rx_etype_pcp,
//  output wire ctl_rx_check_opcode_pcp,
//  output wire [15:0] ctl_rx_opcode_min_pcp,
//  output wire [15:0] ctl_rx_opcode_max_pcp,
//  output wire ctl_rx_enable_gpp,
//  output wire ctl_rx_check_mcast_gpp,
//  output wire ctl_rx_check_ucast_gpp,
//  output wire ctl_rx_check_sa_gpp,
//  output wire ctl_rx_check_etype_gpp,
//  output wire [15:0] ctl_rx_etype_gpp,
//  output wire ctl_rx_check_opcode_gpp,
//  output wire [15:0] ctl_rx_opcode_gpp,
//  output wire ctl_rx_enable_ppp,
//  output wire ctl_rx_check_mcast_ppp,
//  output wire ctl_rx_check_ucast_ppp,
//  output wire ctl_rx_check_sa_ppp,
//  output wire ctl_rx_check_etype_ppp,
//  output wire [15:0] ctl_rx_etype_ppp,
//  output wire ctl_rx_check_opcode_ppp,
//  output wire [15:0] ctl_rx_opcode_ppp,

//// RX Stats Signals
  input  wire stat_rx_block_lock,
//  input  wire stat_rx_framing_err_valid,
//  input  wire stat_rx_framing_err,
//  input  wire stat_rx_hi_ber,
//  input  wire stat_rx_valid_ctrl_code,
//  input  wire stat_rx_bad_code,
//  input  wire [1:0] stat_rx_total_packets,
//  input  wire stat_rx_total_good_packets,
//  input  wire [3:0] stat_rx_total_bytes,
//  input  wire [13:0] stat_rx_total_good_bytes,
//  input  wire stat_rx_packet_small,
//  input  wire stat_rx_jabber,
//  input  wire stat_rx_packet_large,
//  input  wire stat_rx_oversize,
//  input  wire stat_rx_undersize,
//  input  wire stat_rx_toolong,
//  input  wire stat_rx_fragment,
//  input  wire stat_rx_packet_64_bytes,
//  input  wire stat_rx_packet_65_127_bytes,
//  input  wire stat_rx_packet_128_255_bytes,
//  input  wire stat_rx_packet_256_511_bytes,
//  input  wire stat_rx_packet_512_1023_bytes,
//  input  wire stat_rx_packet_1024_1518_bytes,
//  input  wire stat_rx_packet_1519_1522_bytes,
//  input  wire stat_rx_packet_1523_1548_bytes,
//  input  wire [1:0] stat_rx_bad_fcs,
//  input  wire stat_rx_packet_bad_fcs,
//  input  wire [1:0] stat_rx_stomped_fcs,
//  input  wire stat_rx_packet_1549_2047_bytes,
//  input  wire stat_rx_packet_2048_4095_bytes,
//  input  wire stat_rx_packet_4096_8191_bytes,
//  input  wire stat_rx_packet_8192_9215_bytes,
//  input  wire stat_rx_bad_preamble,
//  input  wire stat_rx_bad_sfd,
//  input  wire stat_rx_got_signal_os,
//  input  wire stat_rx_test_pattern_mismatch,
//  input  wire stat_rx_truncated,
//  input  wire stat_rx_local_fault,
//  input  wire stat_rx_remote_fault,
//  input  wire stat_rx_internal_local_fault,
//  input  wire stat_rx_received_local_fault,

//  input  wire stat_rx_unicast,
//  input  wire stat_rx_multicast,
//  input  wire stat_rx_broadcast,
//  input  wire stat_rx_vlan,
//  input  wire stat_rx_pause,
//  input  wire stat_rx_user_pause,
//  input  wire stat_rx_inrangeerr,
//  input  wire [8:0] stat_rx_pause_valid,
//  input  wire [15:0] stat_rx_pause_quanta0,
//  input  wire [15:0] stat_rx_pause_quanta1,
//  input  wire [15:0] stat_rx_pause_quanta2,
//  input  wire [15:0] stat_rx_pause_quanta3,
//  input  wire [15:0] stat_rx_pause_quanta4,
//  input  wire [15:0] stat_rx_pause_quanta5,
//  input  wire [15:0] stat_rx_pause_quanta6,
//  input  wire [15:0] stat_rx_pause_quanta7,
//  input  wire [15:0] stat_rx_pause_quanta8,
//  input  wire [8:0] stat_rx_pause_req,
//// TX Control Signals
//  output wire ctl_tx_test_pattern,
//  output wire ctl_tx_test_pattern_enable,
//  output wire ctl_tx_test_pattern_select,
//  output wire ctl_tx_data_pattern_select,
//  output wire [57:0] ctl_tx_test_pattern_seed_a,
//  output wire [57:0] ctl_tx_test_pattern_seed_b,
//  output wire ctl_tx_enable,
//  output wire ctl_tx_fcs_ins_enable,
//  output wire [3:0] ctl_tx_ipg_value,
//  output wire ctl_tx_send_lfi,
//  output wire ctl_tx_send_rfi,
//  output wire ctl_tx_send_idle,
//  output wire ctl_tx_custom_preamble_enable,
//  output wire ctl_tx_ignore_fcs,

//  output wire [8:0] ctl_tx_pause_req,
//  output wire [8:0] ctl_tx_pause_enable,
//  output wire ctl_tx_resend_pause,
//  output wire [15:0] ctl_tx_pause_quanta0,
//  output wire [15:0] ctl_tx_pause_refresh_timer0,
//  output wire [15:0] ctl_tx_pause_quanta1,
//  output wire [15:0] ctl_tx_pause_refresh_timer1,
//  output wire [15:0] ctl_tx_pause_quanta2,
//  output wire [15:0] ctl_tx_pause_refresh_timer2,
//  output wire [15:0] ctl_tx_pause_quanta3,
//  output wire [15:0] ctl_tx_pause_refresh_timer3,
//  output wire [15:0] ctl_tx_pause_quanta4,
//  output wire [15:0] ctl_tx_pause_refresh_timer4,
//  output wire [15:0] ctl_tx_pause_quanta5,
//  output wire [15:0] ctl_tx_pause_refresh_timer5,
//  output wire [15:0] ctl_tx_pause_quanta6,
//  output wire [15:0] ctl_tx_pause_refresh_timer6,
//  output wire [15:0] ctl_tx_pause_quanta7,
//  output wire [15:0] ctl_tx_pause_refresh_timer7,
//  output wire [15:0] ctl_tx_pause_quanta8,
//  output wire [15:0] ctl_tx_pause_refresh_timer8,
//  output wire [47:0] ctl_tx_da_gpp,
//  output wire [47:0] ctl_tx_sa_gpp,
//  output wire [15:0] ctl_tx_ethertype_gpp,
//  output wire [15:0] ctl_tx_opcode_gpp,
//  output wire [47:0] ctl_tx_da_ppp,
//  output wire [47:0] ctl_tx_sa_ppp,
//  output wire [15:0] ctl_tx_ethertype_ppp,
//  output wire [15:0] ctl_tx_opcode_ppp,

//// TX Stats Signals
//  input  wire stat_tx_total_packets,
//  input  wire [3:0] stat_tx_total_bytes,
//  input  wire stat_tx_total_good_packets,
//  input  wire [13:0] stat_tx_total_good_bytes,
//  input  wire stat_tx_packet_64_bytes,
//  input  wire stat_tx_packet_65_127_bytes,
//  input  wire stat_tx_packet_128_255_bytes,
//  input  wire stat_tx_packet_256_511_bytes,
//  input  wire stat_tx_packet_512_1023_bytes,
//  input  wire stat_tx_packet_1024_1518_bytes,
//  input  wire stat_tx_packet_1519_1522_bytes,
//  input  wire stat_tx_packet_1523_1548_bytes,
//  input  wire stat_tx_packet_small,
//  input  wire stat_tx_packet_large,
//  input  wire stat_tx_packet_1549_2047_bytes,
//  input  wire stat_tx_packet_2048_4095_bytes,
//  input  wire stat_tx_packet_4096_8191_bytes,
//  input  wire stat_tx_packet_8192_9215_bytes,
//  input  wire stat_tx_bad_fcs,
//  input  wire stat_tx_frame_error,
//  input  wire stat_tx_local_fault,

//  input  wire stat_tx_unicast,
//  input  wire stat_tx_multicast,
//  input  wire stat_tx_broadcast,
//  input  wire stat_tx_vlan,
//  input  wire stat_tx_pause,
//  input  wire stat_tx_user_pause,
//  input  wire [8:0] stat_tx_pause_valid,
  input wire stat_tx_block_lock,
  input  pktgen_enable,
//  output wire tx_reset,
//  output wire rx_reset,
  input  wire insert_crc,
  input  wire [31:0] tx_packet_count,
  input  wire clear_count,
//// RX LBUS Signals
  input  wire rx_axis_tvalid,
  input  wire [63:0] rx_axis_tdata,
  input  wire rx_axis_tlast,
  input  wire [7:0] rx_axis_tkeep,
  input  wire rx_axis_tuser,
  input  wire [55:0] rx_preambleout,

  input  wire rx_lane_align,
//// TX LBUS Signals
  input  wire tx_axis_tready,
  output reg tx_axis_tvalid,
  output reg [63:0] tx_axis_tdata,
  output reg tx_axis_tlast,
  output reg [7:0] tx_axis_tkeep,
  output reg tx_axis_tuser,
  output wire [55:0] tx_preamblein,
  input  wire tx_unfout,

  output wire tx_time_out,
  output wire tx_done,
  output wire rx_protocol_error,
  output wire [47:0] rx_packet_count,
  output wire [63:0] rx_total_bytes,
  output wire [31:0] rx_prot_err_count,
  output wire [31:0] rx_error_count,
  output wire rx_packet_count_overflow,
  output wire rx_total_bytes_overflow,
  output wire rx_prot_err_overflow,
  output wire rx_error_overflow,
  output wire [47:0] tx_sent_count,
  output wire tx_sent_overflow,
  output wire [63:0] tx_total_bytes,
  output wire tx_total_bytes_overflow,
  output wire [31:0] rx_data_err_count,
  output wire rx_data_err_overflow,
  output wire rx_gt_locked_led,
  output wire rx_block_lock_led
);
  parameter FIXED_PACKET_LENGTH = 9_000;
  parameter MIN_LENGTH          = 64;
  parameter MAX_LENGTH          = 9000;

  wire tx_enain;
  wire tx_sopin;
  wire [64-1:0] tx_datain;
  wire tx_eopin;
  wire [3-1:0] tx_mtyin;
  wire tx_errin;
  wire tx_rdyout;
  wire tx_ovfout = 1'b0;

  wire fifo_tx_enain;
  wire fifo_tx_sopin;
  wire [64-1:0] fifo_tx_datain;
  wire fifo_tx_eopin;
  wire [3-1:0] fifo_tx_mtyin;
  wire fifo_tx_errin;
  wire loc_traf_tx_busy;
  wire rx_gt_locked_led_int;

  wire [511:0] packet;
  wire packet_avail;
  wire packet_avail_reset;

  // RX
  reg [64-1:0] rx_dataout;
  reg rx_enaout;
  reg rx_sopout;
  reg rx_eopout;
  reg rx_errout;
  reg [3-1:0] rx_mtyout;
  reg rx_inframe_r;
assign rx_gt_locked_led = ~tx_resetn & rx_gt_locked_led_int;
assign  tx_preamblein        = 56'b0;

ip_xcku040_mac10g_noaxi_axis_pkt_gen i_ip_xcku040_mac10g_noaxi_PKT_GEN  (   // Generator to send 1 packet

  .clk ( tx_clk ),
  .reset ( tx_resetn ),
  .enable ( pktgen_enable ),
  .tx_rdyout ( tx_rdyout ),
  .tx_ovfout ( tx_ovfout ),
  .rx_lane_align ( rx_lane_align ),
  .packet_count ( tx_packet_count ),
  .insert_crc ( insert_crc ),
//  .tx_reset ( tx_reset ),
//// TX LBUS Signals

//// TX Control Signals
//  .ctl_tx_test_pattern (ctl_tx_test_pattern),
//  .ctl_tx_test_pattern_enable (ctl_tx_test_pattern_enable),
//  .ctl_tx_test_pattern_select (ctl_tx_test_pattern_select),
//  .ctl_tx_data_pattern_select (ctl_tx_data_pattern_select),
//  .ctl_tx_test_pattern_seed_a (ctl_tx_test_pattern_seed_a),
//  .ctl_tx_test_pattern_seed_b (ctl_tx_test_pattern_seed_b),
//  .ctl_tx_enable (ctl_tx_enable),
//  .ctl_tx_fcs_ins_enable (ctl_tx_fcs_ins_enable),
//  .ctl_tx_ipg_value (ctl_tx_ipg_value),
//  .ctl_tx_send_lfi (ctl_tx_send_lfi),
//  .ctl_tx_send_rfi (ctl_tx_send_rfi),
//  .ctl_tx_send_idle (ctl_tx_send_idle),
//  .ctl_tx_custom_preamble_enable (ctl_tx_custom_preamble_enable),
//  .ctl_tx_ignore_fcs (ctl_tx_ignore_fcs),

//  .ctl_tx_pause_req (ctl_tx_pause_req),
//  .ctl_tx_pause_enable (ctl_tx_pause_enable),
//  .ctl_tx_resend_pause (ctl_tx_resend_pause),
//  .ctl_tx_pause_quanta0 (ctl_tx_pause_quanta0),
//  .ctl_tx_pause_refresh_timer0 (ctl_tx_pause_refresh_timer0),
//  .ctl_tx_pause_quanta1 (ctl_tx_pause_quanta1),
//  .ctl_tx_pause_refresh_timer1 (ctl_tx_pause_refresh_timer1),
//  .ctl_tx_pause_quanta2 (ctl_tx_pause_quanta2),
//  .ctl_tx_pause_refresh_timer2 (ctl_tx_pause_refresh_timer2),
//  .ctl_tx_pause_quanta3 (ctl_tx_pause_quanta3),
//  .ctl_tx_pause_refresh_timer3 (ctl_tx_pause_refresh_timer3),
//  .ctl_tx_pause_quanta4 (ctl_tx_pause_quanta4),
//  .ctl_tx_pause_refresh_timer4 (ctl_tx_pause_refresh_timer4),
//  .ctl_tx_pause_quanta5 (ctl_tx_pause_quanta5),
//  .ctl_tx_pause_refresh_timer5 (ctl_tx_pause_refresh_timer5),
//  .ctl_tx_pause_quanta6 (ctl_tx_pause_quanta6),
//  .ctl_tx_pause_refresh_timer6 (ctl_tx_pause_refresh_timer6),
//  .ctl_tx_pause_quanta7 (ctl_tx_pause_quanta7),
//  .ctl_tx_pause_refresh_timer7 (ctl_tx_pause_refresh_timer7),
//  .ctl_tx_pause_quanta8 (ctl_tx_pause_quanta8),
//  .ctl_tx_pause_refresh_timer8 (ctl_tx_pause_refresh_timer8),
//  .ctl_tx_da_gpp (ctl_tx_da_gpp),
//  .ctl_tx_sa_gpp (ctl_tx_sa_gpp),
//  .ctl_tx_ethertype_gpp (ctl_tx_ethertype_gpp),
//  .ctl_tx_opcode_gpp (ctl_tx_opcode_gpp),
//  .ctl_tx_da_ppp (ctl_tx_da_ppp),
//  .ctl_tx_sa_ppp (ctl_tx_sa_ppp),
//  .ctl_tx_ethertype_ppp (ctl_tx_ethertype_ppp),
//  .ctl_tx_opcode_ppp (ctl_tx_opcode_ppp),

//// TX Stats Signals
//  .stat_tx_total_packets (stat_tx_total_packets),
//  .stat_tx_total_bytes (stat_tx_total_bytes),
//  .stat_tx_total_good_packets (stat_tx_total_good_packets),
//  .stat_tx_total_good_bytes (stat_tx_total_good_bytes),
//  .stat_tx_packet_64_bytes (stat_tx_packet_64_bytes),
//  .stat_tx_packet_65_127_bytes (stat_tx_packet_65_127_bytes),
//  .stat_tx_packet_128_255_bytes (stat_tx_packet_128_255_bytes),
//  .stat_tx_packet_256_511_bytes (stat_tx_packet_256_511_bytes),
//  .stat_tx_packet_512_1023_bytes (stat_tx_packet_512_1023_bytes),
//  .stat_tx_packet_1024_1518_bytes (stat_tx_packet_1024_1518_bytes),
//  .stat_tx_packet_1519_1522_bytes (stat_tx_packet_1519_1522_bytes),
//  .stat_tx_packet_1523_1548_bytes (stat_tx_packet_1523_1548_bytes),
//  .stat_tx_packet_small (stat_tx_packet_small),
//  .stat_tx_packet_large (stat_tx_packet_large),
//  .stat_tx_packet_1549_2047_bytes (stat_tx_packet_1549_2047_bytes),
//  .stat_tx_packet_2048_4095_bytes (stat_tx_packet_2048_4095_bytes),
//  .stat_tx_packet_4096_8191_bytes (stat_tx_packet_4096_8191_bytes),
//  .stat_tx_packet_8192_9215_bytes (stat_tx_packet_8192_9215_bytes),
//  .stat_tx_bad_fcs (stat_tx_bad_fcs),
//  .stat_tx_frame_error (stat_tx_frame_error),
//  .stat_tx_local_fault (stat_tx_local_fault),

//  .stat_tx_unicast (stat_tx_unicast),
//  .stat_tx_multicast (stat_tx_multicast),
//  .stat_tx_broadcast (stat_tx_broadcast),
//  .stat_tx_vlan (stat_tx_vlan),
//  .stat_tx_pause (stat_tx_pause),
//  .stat_tx_user_pause (stat_tx_user_pause),
//  .stat_tx_pause_valid (stat_tx_pause_valid),

  .tx_datain ( tx_datain ),
  .tx_enain ( tx_enain ),
  .tx_sopin ( tx_sopin ),
  .tx_eopin ( tx_eopin ),
  .tx_errin ( tx_errin ),
  .tx_mtyin ( tx_mtyin ),
  .time_out ( tx_time_out ),
  .busy ( loc_traf_tx_busy),
  .done ( tx_done ),

  .packet ( packet ),
  .packet_avail ( packet_avail ),
  .packet_avail_reset ( packet_avail_reset )
);


ip_xcku040_mac10g_noaxi_axis_pkt_mon  
#(  .MIN_LENGTH (MIN_LENGTH),
    .MAX_LENGTH (MAX_LENGTH)
  )i_ip_xcku040_mac10g_noaxi_PKT_CHK(

  .clk ( rx_clk ),
  .reset ( rx_resetn ),
  .clear_count ( clear_count ),
  .sys_reset ( sys_reset ),
//// RX LBUS Signals

  .rx_dataout ( rx_dataout ),
  .rx_enaout ( rx_enaout ),
  .rx_sopout ( rx_sopout ),
  .rx_eopout ( rx_eopout ),
  .rx_errout ( rx_errout ),
  .rx_mtyout ( rx_mtyout ),
//// RX Control Signals
//  .ctl_rx_test_pattern (ctl_rx_test_pattern),
//  .ctl_rx_test_pattern_enable (ctl_rx_test_pattern_enable),
//  .ctl_rx_data_pattern_select (ctl_rx_data_pattern_select),
//  .ctl_rx_enable (ctl_rx_enable),
//  .ctl_rx_delete_fcs (ctl_rx_delete_fcs),
//  .ctl_rx_ignore_fcs (ctl_rx_ignore_fcs),
//  .ctl_rx_max_packet_len (ctl_rx_max_packet_len),
//  .ctl_rx_min_packet_len (ctl_rx_min_packet_len),
//  .ctl_rx_custom_preamble_enable (ctl_rx_custom_preamble_enable),
//  .ctl_rx_check_sfd (ctl_rx_check_sfd),
//  .ctl_rx_check_preamble (ctl_rx_check_preamble),
//  .ctl_rx_process_lfi (ctl_rx_process_lfi),
//  .ctl_rx_force_resync (ctl_rx_force_resync),

//  .ctl_rx_forward_control (ctl_rx_forward_control),
//  .ctl_rx_pause_ack (ctl_rx_pause_ack),
//  .ctl_rx_check_ack (ctl_rx_check_ack),
//  .ctl_rx_pause_enable (ctl_rx_pause_enable),
//  .ctl_rx_enable_gcp (ctl_rx_enable_gcp),
//  .ctl_rx_check_mcast_gcp (ctl_rx_check_mcast_gcp),
//  .ctl_rx_check_ucast_gcp (ctl_rx_check_ucast_gcp),
//  .ctl_rx_pause_da_ucast (ctl_rx_pause_da_ucast),
//  .ctl_rx_check_sa_gcp (ctl_rx_check_sa_gcp),
//  .ctl_rx_pause_sa (ctl_rx_pause_sa),
//  .ctl_rx_check_etype_gcp (ctl_rx_check_etype_gcp),
//  .ctl_rx_etype_gcp (ctl_rx_etype_gcp),
//  .ctl_rx_check_opcode_gcp (ctl_rx_check_opcode_gcp),
//  .ctl_rx_opcode_min_gcp (ctl_rx_opcode_min_gcp),
//  .ctl_rx_opcode_max_gcp (ctl_rx_opcode_max_gcp),
//  .ctl_rx_enable_pcp (ctl_rx_enable_pcp),
//  .ctl_rx_check_mcast_pcp (ctl_rx_check_mcast_pcp),
//  .ctl_rx_check_ucast_pcp (ctl_rx_check_ucast_pcp),
//  .ctl_rx_pause_da_mcast (ctl_rx_pause_da_mcast),
//  .ctl_rx_check_sa_pcp (ctl_rx_check_sa_pcp),
//  .ctl_rx_check_etype_pcp (ctl_rx_check_etype_pcp),
//  .ctl_rx_etype_pcp (ctl_rx_etype_pcp),
//  .ctl_rx_check_opcode_pcp (ctl_rx_check_opcode_pcp),
//  .ctl_rx_opcode_min_pcp (ctl_rx_opcode_min_pcp),
//  .ctl_rx_opcode_max_pcp (ctl_rx_opcode_max_pcp),
//  .ctl_rx_enable_gpp (ctl_rx_enable_gpp),
//  .ctl_rx_check_mcast_gpp (ctl_rx_check_mcast_gpp),
//  .ctl_rx_check_ucast_gpp (ctl_rx_check_ucast_gpp),
//  .ctl_rx_check_sa_gpp (ctl_rx_check_sa_gpp),
//  .ctl_rx_check_etype_gpp (ctl_rx_check_etype_gpp),
//  .ctl_rx_etype_gpp (ctl_rx_etype_gpp),
//  .ctl_rx_check_opcode_gpp (ctl_rx_check_opcode_gpp),
//  .ctl_rx_opcode_gpp (ctl_rx_opcode_gpp),
//  .ctl_rx_enable_ppp (ctl_rx_enable_ppp),
//  .ctl_rx_check_mcast_ppp (ctl_rx_check_mcast_ppp),
//  .ctl_rx_check_ucast_ppp (ctl_rx_check_ucast_ppp),
//  .ctl_rx_check_sa_ppp (ctl_rx_check_sa_ppp),
//  .ctl_rx_check_etype_ppp (ctl_rx_check_etype_ppp),
//  .ctl_rx_etype_ppp (ctl_rx_etype_ppp),
//  .ctl_rx_check_opcode_ppp (ctl_rx_check_opcode_ppp),
//  .ctl_rx_opcode_ppp (ctl_rx_opcode_ppp),

//// RX Stats Signals
  .stat_rx_block_lock (stat_rx_block_lock),
//  .stat_rx_framing_err_valid (stat_rx_framing_err_valid),
//  .stat_rx_framing_err (stat_rx_framing_err),
//  .stat_rx_hi_ber (stat_rx_hi_ber),
//  .stat_rx_valid_ctrl_code (stat_rx_valid_ctrl_code),
//  .stat_rx_bad_code (stat_rx_bad_code),
//  .stat_rx_total_packets (stat_rx_total_packets),
//  .stat_rx_total_good_packets (stat_rx_total_good_packets),
//  .stat_rx_total_bytes (stat_rx_total_bytes),
//  .stat_rx_total_good_bytes (stat_rx_total_good_bytes),
//  .stat_rx_packet_small (stat_rx_packet_small),
//  .stat_rx_jabber (stat_rx_jabber),
//  .stat_rx_packet_large (stat_rx_packet_large),
//  .stat_rx_oversize (stat_rx_oversize),
//  .stat_rx_undersize (stat_rx_undersize),
//  .stat_rx_toolong (stat_rx_toolong),
//  .stat_rx_fragment (stat_rx_fragment),
//  .stat_rx_packet_64_bytes (stat_rx_packet_64_bytes),
//  .stat_rx_packet_65_127_bytes (stat_rx_packet_65_127_bytes),
//  .stat_rx_packet_128_255_bytes (stat_rx_packet_128_255_bytes),
//  .stat_rx_packet_256_511_bytes (stat_rx_packet_256_511_bytes),
//  .stat_rx_packet_512_1023_bytes (stat_rx_packet_512_1023_bytes),
//  .stat_rx_packet_1024_1518_bytes (stat_rx_packet_1024_1518_bytes),
//  .stat_rx_packet_1519_1522_bytes (stat_rx_packet_1519_1522_bytes),
//  .stat_rx_packet_1523_1548_bytes (stat_rx_packet_1523_1548_bytes),
//  .stat_rx_bad_fcs (stat_rx_bad_fcs),
//  .stat_rx_packet_bad_fcs (stat_rx_packet_bad_fcs),
//  .stat_rx_stomped_fcs (stat_rx_stomped_fcs),
//  .stat_rx_packet_1549_2047_bytes (stat_rx_packet_1549_2047_bytes),
//  .stat_rx_packet_2048_4095_bytes (stat_rx_packet_2048_4095_bytes),
//  .stat_rx_packet_4096_8191_bytes (stat_rx_packet_4096_8191_bytes),
//  .stat_rx_packet_8192_9215_bytes (stat_rx_packet_8192_9215_bytes),
//  .stat_rx_bad_preamble (stat_rx_bad_preamble),
//  .stat_rx_bad_sfd (stat_rx_bad_sfd),
//  .stat_rx_got_signal_os (stat_rx_got_signal_os),
//  .stat_rx_test_pattern_mismatch (stat_rx_test_pattern_mismatch),
//  .stat_rx_truncated (stat_rx_truncated),
//  .stat_rx_local_fault (stat_rx_local_fault),
//  .stat_rx_remote_fault (stat_rx_remote_fault),
//  .stat_rx_internal_local_fault (stat_rx_internal_local_fault),
//  .stat_rx_received_local_fault (stat_rx_received_local_fault),

//  .stat_rx_unicast (stat_rx_unicast),
//  .stat_rx_multicast (stat_rx_multicast),
//  .stat_rx_broadcast (stat_rx_broadcast),
//  .stat_rx_vlan (stat_rx_vlan),
//  .stat_rx_pause (stat_rx_pause),
//  .stat_rx_user_pause (stat_rx_user_pause),
//  .stat_rx_inrangeerr (stat_rx_inrangeerr),
//  .stat_rx_pause_valid (stat_rx_pause_valid),
//  .stat_rx_pause_quanta0 (stat_rx_pause_quanta0),
//  .stat_rx_pause_quanta1 (stat_rx_pause_quanta1),
//  .stat_rx_pause_quanta2 (stat_rx_pause_quanta2),
//  .stat_rx_pause_quanta3 (stat_rx_pause_quanta3),
//  .stat_rx_pause_quanta4 (stat_rx_pause_quanta4),
//  .stat_rx_pause_quanta5 (stat_rx_pause_quanta5),
//  .stat_rx_pause_quanta6 (stat_rx_pause_quanta6),
//  .stat_rx_pause_quanta7 (stat_rx_pause_quanta7),
//  .stat_rx_pause_quanta8 (stat_rx_pause_quanta8),
//  .stat_rx_pause_req (stat_rx_pause_req),

//  .rx_reset ( rx_reset ),
  .protocol_error ( rx_protocol_error ),
  .packet_count ( rx_packet_count ),
  .total_bytes ( rx_total_bytes ),
  .prot_err_count ( rx_prot_err_count ),
  .error_count ( rx_error_count ),
  .packet_count_overflow ( rx_packet_count_overflow ),
  .total_bytes_overflow ( rx_total_bytes_overflow ),
  .prot_err_overflow ( rx_prot_err_overflow ),
  .error_overflow ( rx_error_overflow ),
  .rx_gt_locked_led (rx_gt_locked_led_int),
  .rx_block_lock_led (rx_block_lock_led)
);

  always @( posedge rx_clk  )
    begin
      if ( rx_resetn == 1'b1 )
     begin
        rx_mtyout <= 'b0;
        rx_enaout <= 'b0;
        rx_eopout <= 'b0;
        rx_sopout <= 'b0;
        rx_errout <= 'b0;
        rx_dataout <= 'b0;
        rx_inframe_r <= 'b0;
     end else
     begin
        rx_mtyout <= 'd0;
        case (rx_axis_tkeep)
          ({8{1'b1}} >> 0) : rx_mtyout <= 0;
          ({8{1'b1}} >> 1) : rx_mtyout <= 1;
          ({8{1'b1}} >> 2) : rx_mtyout <= 2;
          ({8{1'b1}} >> 3) : rx_mtyout <= 3;
          ({8{1'b1}} >> 4) : rx_mtyout <= 4;
          ({8{1'b1}} >> 5) : rx_mtyout <= 5;
          ({8{1'b1}} >> 6) : rx_mtyout <= 6;
          ({8{1'b1}} >> 7) : rx_mtyout <= 7;
        endcase
        if ( rx_inframe_r == 1'b0 ) begin
           rx_inframe_r <= rx_axis_tvalid;
           rx_sopout <= rx_axis_tvalid;
        end else begin
           rx_inframe_r <= ~(rx_axis_tlast && rx_axis_tvalid);
           rx_sopout <= 'b0;
        end
        rx_eopout  <= rx_axis_tlast;
        rx_enaout  <= rx_axis_tvalid;
        rx_eopout  <= rx_axis_tlast;
        rx_errout  <= rx_axis_tuser;
        rx_dataout[(8-1-0)*8+:8] <= rx_axis_tdata[0*8+:8];
        rx_dataout[(8-1-1)*8+:8] <= rx_axis_tdata[1*8+:8];
        rx_dataout[(8-1-2)*8+:8] <= rx_axis_tdata[2*8+:8];
        rx_dataout[(8-1-3)*8+:8] <= rx_axis_tdata[3*8+:8];
        rx_dataout[(8-1-4)*8+:8] <= rx_axis_tdata[4*8+:8];
        rx_dataout[(8-1-5)*8+:8] <= rx_axis_tdata[5*8+:8];
        rx_dataout[(8-1-6)*8+:8] <= rx_axis_tdata[6*8+:8];
        rx_dataout[(8-1-7)*8+:8] <= rx_axis_tdata[7*8+:8];
    end
  end

 always @*
  begin

    tx_axis_tdata[(8-1-0)*8+:8] = fifo_tx_datain[0*8+:8];
    tx_axis_tdata[(8-1-1)*8+:8] = fifo_tx_datain[1*8+:8];
    tx_axis_tdata[(8-1-2)*8+:8] = fifo_tx_datain[2*8+:8];
    tx_axis_tdata[(8-1-3)*8+:8] = fifo_tx_datain[3*8+:8];
    tx_axis_tdata[(8-1-4)*8+:8] = fifo_tx_datain[4*8+:8];
    tx_axis_tdata[(8-1-5)*8+:8] = fifo_tx_datain[5*8+:8];
    tx_axis_tdata[(8-1-6)*8+:8] = fifo_tx_datain[6*8+:8];
    tx_axis_tdata[(8-1-7)*8+:8] = fifo_tx_datain[7*8+:8];
    tx_axis_tvalid = fifo_tx_enain; // keep valid.
    tx_axis_tlast  = fifo_tx_eopin;
    tx_axis_tuser  = fifo_tx_eopin && fifo_tx_errin;

    case (fifo_tx_mtyin)
      0 : tx_axis_tkeep = {8{1'b1}} >> 0;
      1 : tx_axis_tkeep = {8{1'b1}} >> 1;
      2 : tx_axis_tkeep = {8{1'b1}} >> 2;
      3 : tx_axis_tkeep = {8{1'b1}} >> 3;
      4 : tx_axis_tkeep = {8{1'b1}} >> 4;
      5 : tx_axis_tkeep = {8{1'b1}} >> 5;
      6 : tx_axis_tkeep = {8{1'b1}} >> 6;
      7 : tx_axis_tkeep = {8{1'b1}} >> 7;
    endcase

  end

  ip_xcku040_mac10g_noaxi_buf #(
      .IS_0_LATENCY ( 1 )
  ) i_ip_xcku040_mac10g_noaxi_axi_fifo (

     .clk ( tx_clk ),
     .reset ( tx_resetn ),

     .tx_datain( tx_datain),
     .tx_enain ( tx_enain ),
     .tx_sopin ( tx_sopin ),
     .tx_eopin ( tx_eopin ),
     .tx_errin ( tx_errin ),
     .tx_mtyin ( tx_mtyin ),

     .tx_dataout( fifo_tx_datain),
     .tx_enaout ( fifo_tx_enain ),
     .tx_sopout ( fifo_tx_sopin ),
     .tx_eopout ( fifo_tx_eopin ),
     .tx_errout ( fifo_tx_errin ),
     .tx_mtyout ( fifo_tx_mtyin ),
     .tx_rdyin  ( tx_axis_tready ),
     .tx_rdyout ( tx_rdyout )
  );

ip_xcku040_mac10g_noaxi_traf_chk1 i_ip_xcku040_mac10g_noaxi_TRAF_CHK2 (                         // Counter for packets sent

  .clk ( tx_clk ),
  .reset ( tx_resetn ),
  .enable ( pktgen_enable || loc_traf_tx_busy ),
  .clear_count ( clear_count ),

  .rx_dataout ( tx_datain ),
  .rx_enaout ( tx_enain ),
  .rx_sopout ( tx_sopin ),
  .rx_eopout ( tx_eopin ),
  .rx_errout ( tx_errin ),
  .rx_mtyout ( tx_mtyin ),
  .protocol_error ( ),
  .packet_count ( tx_sent_count ),
  .total_bytes ( tx_total_bytes ),
  .prot_err_count ( ),
  .error_count ( ),
  .packet_count_overflow ( tx_sent_overflow ),
  .total_bytes_overflow ( tx_total_bytes_overflow ),
  .prot_err_overflow ( ),
  .error_overflow ( )
);

ip_xcku040_mac10g_noaxi_traf_data_chk i_ip_xcku040_mac10g_noaxi_TRAF_DATA_CHK (

  .clk ( rx_clk ),
  .reset ( rx_resetn ),
  .clear_count ( clear_count ),
  .enable ( 1'b1 ),

  .rx_dataout ( rx_dataout ),
  .rx_enaout ( rx_enaout ),
  .rx_sopout ( rx_sopout ),
  .rx_eopout ( rx_eopout ),
  .rx_errout ( rx_errout ),
  .rx_mtyout ( rx_mtyout ),

  .error_count ( rx_data_err_count ),
  .error_overflow ( rx_data_err_overflow ),
  .packet ( packet ),
  .packet_avail (packet_avail ),
  .packet_avail_reset ( packet_avail_reset )
);

endmodule
