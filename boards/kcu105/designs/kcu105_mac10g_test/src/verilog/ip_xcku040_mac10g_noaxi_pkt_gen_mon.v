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
////module lbus_if
module ip_xcku040_mac10g_noaxi_pkt_gen_mon
(
  input                      gen_clk,
  input                      mon_clk,
  input                      dclk,
  input                      sys_reset,
  input wire                 restart_tx_rx,

//// RX Signals
//  output wire         rx_reset,
  input  wire         user_rx_reset,
//// RX LBUS Signals
  input  wire rx_axis_tvalid,
  input  wire [63:0] rx_axis_tdata,
  input  wire rx_axis_tlast,
  input  wire [7:0] rx_axis_tkeep,
  input  wire rx_axis_tuser,
  input  wire [55:0] rx_preambleout,

 
//  output wire [1:0] tx_ptp_1588op_in,
//  output wire [15:0] tx_ptp_tag_field_in,
//  input  wire tx_ptp_tstamp_valid_out,
//  input  wire [15:0] tx_ptp_tstamp_tag_out,
//  input  wire [79:0] tx_ptp_tstamp_out,
//  input  wire [79:0] rx_ptp_tstamp_out,
//  input  wire rx_ptp_tstamp_valid_out,

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

 
//  input  wire stat_tx_ptp_fifo_read_error,
//  input  wire stat_tx_ptp_fifo_write_error,

//// TX Signals
//  output wire         tx_reset,
  input  wire         user_tx_reset,

//// TX LBUS Signals
  input  wire tx_axis_tready,
  output wire tx_axis_tvalid,
  output wire [63:0] tx_axis_tdata,
  output wire tx_axis_tlast,
  output wire [7:0] tx_axis_tkeep,
  output wire tx_axis_tuser,
  input  wire tx_unfout,
  output wire [55:0] tx_preamblein,

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


 
//  output wire [79:0] ctl_rx_systemtimerin,
//  output wire [79:0] ctl_tx_systemtimerin,

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

    output reg  [4:0]  completion_status,
    output wire        rx_gt_locked_led,
    output wire        rx_block_lock_led
   );

  parameter PKT_NUM         = 1;    //// Many Internal Counters are based on PKT_NUM = 20
  parameter FIXED_PACKET_LENGTH = 256;
  parameter MIN_LENGTH          = 64;
  parameter MAX_LENGTH          = 9000;

  wire [2:0] data_pattern_select;
  wire insert_crc;
  wire [4:0] completion_status_int;
  wire stat_rx_aligned;
  wire stat_rx_synced;
  wire stat_rx_status;
  wire pktgen_enable;
  reg  pktgen_enable_int;
  wire pktgen_enable_sync;
  
  wire tx_total_bytes_overflow;
  wire tx_sent_overflow;
  wire [31:0] tx_packet_count;
  wire [47:0] tx_sent_count;
  reg  [47:0] tx_sent_count_int;
  wire [47:0] tx_sent_count_sync;
  wire [63:0] tx_total_bytes;
  reg  [63:0] tx_total_bytes_int;
  wire [63:0] tx_total_bytes_sync;
  wire tx_time_out;
  reg  tx_time_out_int;
  wire tx_time_out_sync;
  wire tx_done;
  reg  tx_done_int;
  wire tx_done_sync;

  wire stat_rx_block_lock_sync;
  wire [31:0] rx_error_count;
  wire [31:0] rx_prot_err_count; 
  wire [63:0] rx_total_bytes;
  reg  [63:0] rx_total_bytes_int;
  wire [63:0] rx_total_bytes_sync;
  wire [47:0] rx_packet_count;
  reg  [47:0] rx_packet_count_int;
  wire [47:0] rx_packet_count_sync;
  wire rx_packet_count_overflow;
  wire rx_total_bytes_overflow;
  wire rx_prot_err_overflow;
  wire rx_error_overflow;
  
  wire rx_errors;
  reg  rx_errors_int;
  wire rx_errors_sync;
  wire rx_block_lock_sync;
  wire [31:0] rx_data_err_count;
  wire rx_data_err;
  assign rx_data_err = |rx_data_err_count; 
  wire rx_data_err_overflow;



  assign rx_errors            = |rx_prot_err_count || |rx_error_count ;
  assign tx_packet_count      = PKT_NUM;
  assign stat_rx_status       = stat_rx_block_lock_sync ;
  assign stat_rx_aligned      = stat_rx_block_lock_sync ;
  assign stat_rx_synced       = stat_rx_block_lock_sync ;
  assign data_pattern_select  = 3'd0;
  assign clear_count          = 1'b0;
  assign insert_crc           = 1'b0;

 


ip_xcku040_mac10g_noaxi_user_cdc_sync i_ip_xcku040_mac10g_noaxi_core_cdc_sync_block_lock_syncer (
    .clk                 (dclk),
    .signal_in           (stat_rx_block_lock),
    .signal_out          (stat_rx_block_lock_sync)
  );

ip_xcku040_mac10g_noaxi_user_cdc_sync i_ip_xcku040_mac10g_noaxi_core_cdc_sync_block_lock_syncer_gen (
    .clk                 (gen_clk),
    .signal_in           (stat_rx_block_lock),
    .signal_out          (rx_block_lock_sync)
  );

  always @(posedge gen_clk)
  begin
      tx_total_bytes_int  <= tx_total_bytes;
  end
  
ip_xcku040_mac10g_noaxi_cdc_sync_2stage 
  #(
    .WIDTH        (64)
  ) i_xxv_ethernet_2_tx_total_bytes_syncer (
    .clk          (dclk ),
    .signal_in    (tx_total_bytes_int),
    .signal_out   (tx_total_bytes_sync)
  );

  always @(posedge gen_clk)
  begin
      tx_sent_count_int <= tx_sent_count;
  end

ip_xcku040_mac10g_noaxi_cdc_sync_2stage 
  #(
    .WIDTH        (48)
  ) i_xxv_ethernet_2_tx_packet_count_syncer (
    .clk          (dclk ),
    .signal_in    (tx_sent_count_int),
    .signal_out   (tx_sent_count_sync)
  );

  always @(posedge gen_clk)
  begin
      tx_time_out_int   <= tx_time_out ;
  end

ip_xcku040_mac10g_noaxi_cdc_sync_2stage 
  #(
    .WIDTH        (1)
  ) i_ip_xcku040_mac10g_noaxi_tx_time_out_syncer (
    .clk          (dclk ),
    .signal_in    (tx_time_out_int),
    .signal_out   (tx_time_out_sync)
  );

  always @(posedge gen_clk)
  begin
      tx_done_int       <= tx_done ;
  end

ip_xcku040_mac10g_noaxi_cdc_sync_2stage 
  #(
    .WIDTH        (1)
  ) i_ip_xcku040_mac10g_noaxi_tx_done_syncer (
    .clk          (dclk ),
    .signal_in    (tx_done_int),
    .signal_out   (tx_done_sync)
  );

  always @(posedge mon_clk)
  begin
      rx_packet_count_int <= rx_packet_count;
  end

ip_xcku040_mac10g_noaxi_cdc_sync_2stage 
  #(
    .WIDTH        (48)
  ) i_ip_xcku040_mac10g_noaxi_rx_packet_count_syncer (
    .clk          (dclk ),
    .signal_in    (rx_packet_count_int),
    .signal_out   (rx_packet_count_sync)
  );

  always @(posedge mon_clk)
  begin
      rx_total_bytes_int  <= rx_total_bytes;
  end

ip_xcku040_mac10g_noaxi_cdc_sync_2stage 
  #(
    .WIDTH        (64)
  ) i_ip_xcku040_mac10g_noaxi_rx_total_bytes_syncer (
    .clk          (dclk ),
    .signal_in    (rx_total_bytes_int),
    .signal_out   (rx_total_bytes_sync)
  );

  always @(posedge mon_clk)
  begin
      rx_errors_int       <= rx_errors;
  end

ip_xcku040_mac10g_noaxi_cdc_sync_2stage 
  #(
    .WIDTH        (1)
  ) i_ip_xcku040_mac10g_noaxi_rx_errors_syncer (
    .clk          (dclk ),
    .signal_in    (rx_errors_int),
    .signal_out   (rx_errors_sync)
  );


  reg rx_data_err_reg;

  always@ (posedge mon_clk)
  begin
      rx_data_err_reg <= rx_data_err;
  end

  wire rx_data_err_sync;
ip_xcku040_mac10g_noaxi_cdc_sync_2stage 
  #(
    .WIDTH        (1)
  ) i_ip_xcku040_mac10g_noaxi_rx_data_err_syncer (
    .clk          (dclk ),
    .signal_in    (rx_data_err_reg),
    .signal_out   (rx_data_err_sync)
  );

  always@ (posedge dclk)
  begin
      pktgen_enable_int <= pktgen_enable;
  end

ip_xcku040_mac10g_noaxi_user_cdc_sync i_ip_xcku040_mac10g_noaxi_core_cdc_sync_pkt_gen_enable (
    .clk                 (gen_clk),
    .signal_in           (pktgen_enable_int),
    .signal_out          (pktgen_enable_sync)
);

ip_xcku040_mac10g_noaxi_example_fsm_axis  
   i_ip_xcku040_mac10g_noaxi_EXAMPLE_FSM  (
  .dclk                        (dclk),
  .fsm_reset                   (sys_reset| restart_tx_rx),
  .stat_rx_block_lock          (stat_rx_block_lock_sync),
  .stat_rx_synced              (stat_rx_synced),
  .stat_rx_aligned             (stat_rx_aligned),
  .stat_rx_status              (stat_rx_status),
  .tx_timeout                  (tx_time_out_sync),
  .tx_done                     (tx_done_sync),
  .ok_to_start                 (1'b1),
  .rx_packet_count             (rx_packet_count_sync),
  .rx_total_bytes              (rx_total_bytes_sync),
  .rx_errors                   (rx_errors_sync),
  .rx_data_errors              (rx_data_err_sync),
  .tx_sent_count               (tx_sent_count_sync),
  .tx_total_bytes              (tx_total_bytes_sync),
  .sys_reset                   (   ),
  .pktgen_enable               (pktgen_enable),
  .completion_status           (completion_status_int)
);
  always @( posedge dclk, posedge sys_reset  )
  begin
      if ( sys_reset == 1'b1 )
      begin
          completion_status    <= 5'b0;
      end
      else
      begin
          completion_status    <= completion_status_int;
      end
  end

ip_xcku040_mac10g_noaxi_axis_traffic_gen_mon #(
  .FIXED_PACKET_LENGTH ( FIXED_PACKET_LENGTH ),
  .MIN_LENGTH     ( MIN_LENGTH ),
  .MAX_LENGTH     ( MAX_LENGTH )
) i_ip_xcku040_mac10g_noaxi_TRAFFIC_GENERATOR (
  .tx_clk (gen_clk),
  .tx_resetn (user_tx_reset | restart_tx_rx),
  .rx_clk (mon_clk),
  .rx_resetn (user_rx_reset | restart_tx_rx),
  .sys_reset (sys_reset),
  .pktgen_enable (pktgen_enable_sync),
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
  .stat_tx_block_lock (rx_block_lock_sync),
//  .rx_reset (rx_reset),
//  .tx_reset (tx_reset),
  .insert_crc (insert_crc),
  .tx_packet_count (tx_packet_count),
  .clear_count (clear_count),
//// RX LBUS Signals
  .rx_axis_tvalid (rx_axis_tvalid),
  .rx_axis_tdata (rx_axis_tdata),
  .rx_axis_tlast (rx_axis_tlast),
  .rx_axis_tkeep (rx_axis_tkeep),
  .rx_axis_tuser (rx_axis_tuser),
  .rx_preambleout (rx_preambleout),

  .rx_lane_align (rx_block_lock_sync),
//// TX LBUS Signals
  .tx_axis_tready (tx_axis_tready),
  .tx_axis_tvalid (tx_axis_tvalid),
  .tx_axis_tdata (tx_axis_tdata),
  .tx_axis_tlast (tx_axis_tlast),
  .tx_axis_tkeep (tx_axis_tkeep),
  .tx_axis_tuser (tx_axis_tuser),
  .tx_unfout (tx_unfout),
  .tx_preamblein (tx_preamblein),
  .tx_time_out (tx_time_out),
  .tx_done (tx_done),
//  .rx_protocol_error (rx_protocol_error),
  .rx_packet_count (rx_packet_count),
  .rx_total_bytes (rx_total_bytes),
  .rx_prot_err_count (rx_prot_err_count),
  .rx_error_count (rx_error_count),
  .rx_packet_count_overflow (rx_packet_count_overflow),
  .rx_total_bytes_overflow (rx_total_bytes_overflow),
  .rx_prot_err_overflow (rx_prot_err_overflow),
  .rx_error_overflow (rx_error_overflow),
  .tx_sent_count (tx_sent_count),
  .tx_sent_overflow (tx_sent_overflow),
  .tx_total_bytes (tx_total_bytes),
  .tx_total_bytes_overflow (tx_total_bytes_overflow),
  .rx_data_err_count (rx_data_err_count),
  .rx_data_err_overflow (rx_data_err_overflow),
  .rx_gt_locked_led (rx_gt_locked_led),
  .rx_block_lock_led (rx_block_lock_led)
  );

endmodule

