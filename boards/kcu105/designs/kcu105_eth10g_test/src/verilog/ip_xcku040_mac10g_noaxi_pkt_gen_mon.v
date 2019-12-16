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

//// RX Stats Signals
  input  wire stat_rx_block_lock,

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
  wire [15:0] nof_tx_packets;
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
  .completion_status           (completion_status_int),
  .nof_tx_packets              (nof_tx_packets)
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
//// RX Stats Signals
  .stat_rx_block_lock (stat_rx_block_lock),
//// TX Stats Signals
  .stat_tx_block_lock (rx_block_lock_sync),
  .insert_crc (insert_crc),
  .tx_packet_count (tx_packet_count),
  .clear_count (clear_count),

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
  .rx_block_lock_led (rx_block_lock_led),
  .nof_tx_packets ( nof_tx_packets )
  );

endmodule

