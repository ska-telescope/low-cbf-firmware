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
module l_ethernet_40G_qsfp_d_0_trans_debug
(
  output wire [0:0]    gtwiz_reset_tx_datapath,
  output wire [0:0]    gtwiz_reset_rx_datapath,
  input  wire [67:0]    gt_dmonitorout,
  input  wire [3:0]    gt_eyescandataerror,
  output wire [3:0]    gt_eyescanreset,
  output wire [3:0]    gt_eyescantrigger,
  output wire [63:0]    gt_pcsrsvdin,
  output wire [3:0]    gt_rxbufreset,
  input  wire [11:0]    gt_rxbufstatus,
  output wire [3:0]    gt_rxcdrhold,
  output wire [3:0]    gt_rxcommadeten,
  output wire [3:0]    gt_rxdfeagchold,
  output wire [3:0]    gt_rxdfelpmreset,
  output wire [3:0]    gt_rxlatclk,
  output wire [3:0]    gt_rxlpmen,
  output wire [3:0]    gt_rxpcsreset,
  output wire [3:0]    gt_rxpmareset,
  output wire [3:0]    gt_rxpolarity,
  output wire [3:0]    gt_rxprbscntreset,
  input  wire [3:0]    gt_rxprbserr,
  output wire [15:0]    gt_rxprbssel,
  output wire [11:0]    gt_rxrate,
  output wire [3:0]    gt_rxslide_in,
  input  wire [7:0]    gt_rxstartofseq,
  input  wire [7:0]    gt_txbufstatus,
  output wire [19:0]    gt_txdiffctrl,
  output wire [3:0]    gt_txinhibit,
  output wire [3:0]    gt_txlatclk,
  output wire [27:0]    gt_txmaincursor,
  output wire [3:0]    gt_txpcsreset,
  output wire [3:0]    gt_txpmareset,
  output wire [3:0]    gt_txpolarity,
  output wire [19:0]    gt_txpostcursor,
  output wire [3:0]    gt_txprbsforceerr,
  output wire [15:0]    gt_txprbssel,
  output wire [19:0]    gt_txprecursor,

  input  wire [15:0]  gt_ch_drpdo_0,
  input  wire [0:0]   gt_ch_drprdy_0,
  output reg [0:0]    gt_ch_drpen_0,
  output reg [0:0]    gt_ch_drpwe_0,
  output reg [9:0]    gt_ch_drpaddr_0,
  output reg [15:0]   gt_ch_drpdi_0,
  input  wire [15:0]  gt_ch_drpdo_1,
  input  wire [0:0]   gt_ch_drprdy_1,
  output reg [0:0]    gt_ch_drpen_1,
  output reg [0:0]    gt_ch_drpwe_1,
  output reg [9:0]    gt_ch_drpaddr_1,
  output reg [15:0]   gt_ch_drpdi_1,
  input  wire [15:0]  gt_ch_drpdo_2,
  input  wire [0:0]   gt_ch_drprdy_2,
  output reg [0:0]    gt_ch_drpen_2,
  output reg [0:0]    gt_ch_drpwe_2,
  output reg [9:0]    gt_ch_drpaddr_2,
  output reg [15:0]   gt_ch_drpdi_2,
  input  wire [15:0]  gt_ch_drpdo_3,
  input  wire [0:0]   gt_ch_drprdy_3,
  output reg [0:0]    gt_ch_drpen_3,
  output reg [0:0]    gt_ch_drpwe_3,
  output reg [9:0]    gt_ch_drpaddr_3,
  output reg [15:0]   gt_ch_drpdi_3,

  input                reset,            //// rst for this module 
  input                drp_clk           //// drp clock, connect to same clock that goes to gt drp clock. 

    );
    ////internal register declation

  assign gt_eyescanreset = 4'b0;
  assign gt_eyescantrigger = 4'b0;
  assign gt_pcsrsvdin = 64'b0;
  assign gt_rxbufreset = 4'b0;
  assign gt_rxcdrhold = 4'b0;
  assign gt_rxcommadeten = 4'b0;
  assign gt_rxdfeagchold = 4'b0;
  assign gt_rxdfelpmreset = 4'b0;
  assign gt_rxlatclk = 4'b0;
  assign gt_rxlpmen = 4'b0;
  assign gt_rxpcsreset = 4'b0;
  assign gt_rxpmareset = 4'b0;
  assign gt_rxpolarity = 4'b0;
  assign gt_rxprbscntreset = 4'b0;
  assign gt_rxprbssel = 16'h0;
  assign gt_rxrate = 16'h0;
  assign gt_rxslide_in = 4'b0;
  assign gt_txdiffctrl = 10'h318;
  assign gt_txinhibit = 4'b0;
  assign gt_txlatclk = 4'b0;
  assign gt_txmaincursor = 28'h0;
  assign gt_txpcsreset = 4'b0;
  assign gt_txpmareset = 4'b0;
  assign gt_txpolarity = 4'b0;
  assign gt_txpostcursor = {5'h15,5'h15,5'h15,5'h15};
  assign gt_txprbsforceerr = 4'b0;
  assign gt_txprbssel = 16'h0;
  assign gt_txprecursor = 20'h0;
  assign gtwiz_reset_tx_datapath = 1'b0;
  assign gtwiz_reset_rx_datapath = 1'b0;
    always @(posedge drp_clk)
    begin
        if  (reset == 1'b1)
        begin
            gt_ch_drpaddr_0 <=  10'b0;
            gt_ch_drpen_0   <=  1'b0;
            gt_ch_drpdi_0   <=  16'b0;
            gt_ch_drpwe_0   <=  1'b0;
        end
        else
        begin
            gt_ch_drpaddr_0 <=  10'b0;
            gt_ch_drpen_0   <=  1'b0;
            gt_ch_drpdi_0   <=  16'b0;
            gt_ch_drpwe_0   <=  1'b0;
         end
    end
    always @(posedge drp_clk)
    begin
        if  (reset == 1'b1)
        begin
            gt_ch_drpaddr_1 <=  10'b0;
            gt_ch_drpen_1   <=  1'b0;
            gt_ch_drpdi_1   <=  16'b0;
            gt_ch_drpwe_1   <=  1'b0;
        end
        else
        begin
            gt_ch_drpaddr_1 <=  10'b0;
            gt_ch_drpen_1   <=  1'b0;
            gt_ch_drpdi_1   <=  16'b0;
            gt_ch_drpwe_1   <=  1'b0;
         end
    end
    always @(posedge drp_clk)
    begin
        if  (reset == 1'b1)
        begin
            gt_ch_drpaddr_2 <=  10'b0;
            gt_ch_drpen_2   <=  1'b0;
            gt_ch_drpdi_2   <=  16'b0;
            gt_ch_drpwe_2   <=  1'b0;
        end
        else
        begin
            gt_ch_drpaddr_2 <=  10'b0;
            gt_ch_drpen_2   <=  1'b0;
            gt_ch_drpdi_2   <=  16'b0;
            gt_ch_drpwe_2   <=  1'b0;
         end
    end
    always @(posedge drp_clk)
    begin
        if  (reset == 1'b1)
        begin
            gt_ch_drpaddr_3 <=  10'b0;
            gt_ch_drpen_3   <=  1'b0;
            gt_ch_drpdi_3   <=  16'b0;
            gt_ch_drpwe_3   <=  1'b0;
        end
        else
        begin
            gt_ch_drpaddr_3 <=  10'b0;
            gt_ch_drpen_3   <=  1'b0;
            gt_ch_drpdi_3   <=  16'b0;
            gt_ch_drpwe_3   <=  1'b0;
         end
    end


endmodule
