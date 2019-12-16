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
module qsfp_25g_ethernet_a_trans_debug
(
  input  wire [16:0]  gt_dmonitorout,
  input  wire [0:0]   gt_eyescandataerror,
  output reg [0:0]    gt_eyescanreset,
  output reg [0:0]    gt_eyescantrigger,
  output reg [15:0]   gt_pcsrsvdin,
  output reg [0:0]    gt_rxbufreset,
  input  wire [2:0]   gt_rxbufstatus,
  output reg [0:0]    gt_rxcdrhold,
  output reg [0:0]    gt_rxcommadeten,
  output reg [0:0]    gt_rxdfeagchold,
  output reg [0:0]    gt_rxdfelpmreset,
  output reg [0:0]    gt_rxlatclk,
  output reg [0:0]    gt_rxlpmen,
  output reg [0:0]    gt_rxpcsreset,
  output reg [0:0]    gt_rxpmareset,
  output reg [0:0]    gt_rxpolarity,
  output reg [0:0]    gt_rxprbscntreset,
  input  wire [0:0]   gt_rxprbserr,
  output reg [3:0]    gt_rxprbssel,
  output reg [2:0]    gt_rxrate,
  output reg [0:0]    gt_rxslide_in,
  input  wire [1:0]   gt_rxstartofseq,
  input  wire [1:0]   gt_txbufstatus,
  output reg [4:0]    gt_txdiffctrl,
  output reg [0:0]    gt_txinhibit,
  output reg [0:0]    gt_txlatclk,
  output reg [6:0]    gt_txmaincursor,
  output reg [0:0]    gt_txpcsreset,
  output reg [0:0]    gt_txpmareset,
  output reg [0:0]    gt_txpolarity,
  output reg [4:0]    gt_txpostcursor,
  output reg [0:0]    gt_txprbsforceerr,
  output reg [3:0]    gt_txprbssel,
  output reg [4:0]    gt_txprecursor,
  output reg [0:0]    gtwiz_reset_tx_datapath,
  output reg [0:0]    gtwiz_reset_rx_datapath,

  input  wire [15:0]  gt_drpdo,
  input  wire [0:0]   gt_drprdy,
  output reg [0:0]    gt_drpen,
  output reg [0:0]    gt_drpwe,
  output reg [9:0]    gt_drpaddr,
  output reg [15:0]   gt_drpdi,
  input                reset,            //// Reset for this module 
  input                drp_clk          //// DRP clock, connect to same clock that goes to gt drp clock. 
    );


  always @ (posedge drp_clk) 
  begin
  gt_eyescanreset           <= 1'b0;
  gt_eyescantrigger         <= 1'b0;
  gt_pcsrsvdin              <= 16'h0000;
  gt_rxbufreset             <= 1'b0;
  gt_rxcdrhold              <= 1'b0;
  gt_rxcommadeten           <= 1'b0;
  gt_rxdfeagchold           <= 1'b0;
  gt_rxdfelpmreset          <= 1'b0;
  gt_rxlatclk               <= 1'b0;
  gt_rxlpmen                <= 1'b0;
  gt_rxpcsreset             <= 1'b0;
  gt_rxpmareset             <= 1'b0;
  gt_rxpolarity             <= 1'b0;
  gt_rxprbscntreset         <= 1'b0;
  gt_rxprbssel              <= 4'h0;
  gt_rxrate                 <= 3'h0;
  gt_rxslide_in             <= 1'b0;
  gt_txdiffctrl             <= 5'h18;
  gt_txinhibit              <= 1'b0;
  gt_txlatclk               <= 1'b0;
  gt_txmaincursor           <= 7'h0;
  gt_txpcsreset             <= 1'b0;
  gt_txpmareset             <= 1'b0;
  gt_txpolarity             <= 1'b0;
  gt_txpostcursor           <= 5'h15;
  gt_txprbsforceerr         <= 1'b0;
  gt_txprbssel              <= 4'h0;
  gt_txprecursor            <= 5'h0;
  gtwiz_reset_tx_datapath   <= 1'b0;
  gtwiz_reset_rx_datapath   <= 1'b0;
end

    always @(posedge drp_clk)
    begin
        if  (reset == 1'b1)
        begin
            gt_drpaddr <=  10'b0;
            gt_drpen   <=  1'b0;
            gt_drpdi   <=  16'b0;
            gt_drpwe   <=  1'b0;
        end
        else
        begin
            gt_drpaddr <=  10'b0;
            gt_drpen   <=  1'b0;
            gt_drpdi   <=  16'b0;
            gt_drpwe   <=  1'b0;
         end
    end
endmodule


