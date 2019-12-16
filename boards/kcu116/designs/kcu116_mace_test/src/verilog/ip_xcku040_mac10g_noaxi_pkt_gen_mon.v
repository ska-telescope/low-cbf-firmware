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
  input  wire tx_unfout,
  output wire [55:0] tx_preamblein,

    output wire        rx_gt_locked_led,
    output wire        rx_block_lock_led
   );

  wire stat_rx_aligned;
  wire stat_rx_synced;
  wire stat_rx_status;

  wire stat_rx_block_lock_sync;
  wire rx_block_lock_sync;

  assign stat_rx_status       = stat_rx_block_lock_sync ;
  assign stat_rx_aligned      = stat_rx_block_lock_sync ;
  assign stat_rx_synced       = stat_rx_block_lock_sync ;


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


ip_xcku040_mac10g_noaxi_axis_traffic_gen_mon #(
) i_ip_xcku040_mac10g_noaxi_TRAFFIC_GENERATOR (
  .tx_clk (gen_clk),
  .tx_resetn (user_tx_reset | restart_tx_rx),
  .rx_clk (mon_clk),
  .rx_resetn (user_rx_reset | restart_tx_rx),
  .sys_reset (sys_reset),
//// RX Stats Signals
  .stat_rx_block_lock (stat_rx_block_lock),
//// TX Stats Signals
  .stat_tx_block_lock (rx_block_lock_sync),

  .rx_lane_align (rx_block_lock_sync),
  .tx_preamblein (tx_preamblein),
  .rx_gt_locked_led (rx_gt_locked_led),
  .rx_block_lock_led (rx_block_lock_led)
  );

endmodule

