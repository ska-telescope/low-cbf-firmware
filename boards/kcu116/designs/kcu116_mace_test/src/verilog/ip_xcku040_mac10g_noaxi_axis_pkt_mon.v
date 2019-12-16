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

module ip_xcku040_mac10g_noaxi_axis_pkt_mon (

  input wire clk,
  input wire reset,
  input wire sys_reset,
//// RX Stats Signals
  input  wire stat_rx_block_lock,

  output reg rx_gt_locked_led,
  output reg rx_block_lock_led 
);
wire       rx_block_lock;
reg        rx_gt_locked_led_1d;
reg        rx_gt_locked_led_2d;
reg        rx_gt_locked_led_3d;
reg        rx_block_lock_led_1d;
reg        rx_block_lock_led_2d;
reg        rx_block_lock_led_3d;

assign rx_block_lock              = stat_rx_block_lock;


   //////////////////////////////////////////////////
    ////Registering the LED ports
    //////////////////////////////////////////////////

    always @( posedge clk )
    begin
        if ( reset == 1'b1 )
        begin
            rx_gt_locked_led_1d     <= 1'b0;
            rx_gt_locked_led_2d     <= 1'b0;
            rx_gt_locked_led_3d     <= 1'b0;
            rx_block_lock_led_1d    <= 1'b0;
            rx_block_lock_led_2d    <= 1'b0;
            rx_block_lock_led_3d    <= 1'b0;
        end
        else
        begin
            rx_gt_locked_led_1d     <= ~reset;
            rx_gt_locked_led_2d     <= rx_gt_locked_led_1d;
            rx_gt_locked_led_3d     <= rx_gt_locked_led_2d;
            rx_block_lock_led_1d    <= rx_block_lock;
            rx_block_lock_led_2d    <= rx_block_lock_led_1d;
            rx_block_lock_led_3d    <= rx_block_lock_led_2d;
        end
    end

   //////////////////////////////////////////////////
    ////Assign RX LED Output ports with ASYN sys_reset
    //////////////////////////////////////////////////
    always @( posedge clk, posedge sys_reset  )
    begin
        if ( sys_reset == 1'b1 )
        begin
            rx_gt_locked_led     <= 1'b0;
            rx_block_lock_led    <= 1'b0;
        end
        else
        begin
            rx_gt_locked_led     <= rx_gt_locked_led_3d;
            rx_block_lock_led    <= rx_block_lock_led_3d;
        end
    end


endmodule
