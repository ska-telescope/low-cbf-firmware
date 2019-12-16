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

//// RX Stats Signals
  input  wire stat_rx_block_lock,
  input wire stat_tx_block_lock,
  input  pktgen_enable,
//  output wire tx_reset,
//  output wire rx_reset,
  input  wire insert_crc,
  input  wire [31:0] tx_packet_count,
  input  wire clear_count,

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
  output wire rx_block_lock_led,
  output wire [15:0] nof_tx_packets
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
  .packet_avail_reset ( packet_avail_reset ),
  .nof_tx_packets ( nof_tx_packets)

);


ip_xcku040_mac10g_noaxi_axis_pkt_mon i_ip_xcku040_mac10g_noaxi_PKT_CHK (

  .clk ( rx_clk ),
  .reset ( rx_resetn ),
  .sys_reset ( sys_reset ),
//// RX Stats Signals
  .stat_rx_block_lock (stat_rx_block_lock),
  .rx_gt_locked_led (rx_gt_locked_led_int),
  .rx_block_lock_led (rx_block_lock_led)
);


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


endmodule
