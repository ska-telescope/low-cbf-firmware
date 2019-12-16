//-----------------------------------------------------------------------------
//
// (c) Copyright 2012-2012 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : The Xilinx HMC Host Controller  
// File       : tgen_csr_access.v
// Version    : 1.0  
//-----------------------------------------------------------------------------

//==============================================================================
// Traffic-generator HMC CSR access control
//==============================================================================
`timescale 1ns/1ps

module tgen_csr_access
  #(parameter CSR_ADDR_WIDTH=10
  ) (
    // Control inputs
    input                            clk,
    input                            rst,
    input                            csr_en,
    input                            csr_wr,
    input       [CSR_ADDR_WIDTH-1:0] csr_addr,
    input                     [31:0] csr_wdata,
    output reg                       csr_done,
    output wire               [31:0] csr_rdata,
    // HMC AXI4_LITE I/F
    input                            axi4l_aclk,
    input                            axi4l_aresetn,
    output reg                       axi4l_awvalid,		//WRITE-ADDRESS channel
    output wire [CSR_ADDR_WIDTH-1:0] axi4l_awaddr,		//word address
    input                            axi4l_awready,
    output reg                       axi4l_wvalid,		//WRITE-DATA channel
    output wire               [31:0] axi4l_wdata,
    output wire                [3:0] axi4l_wstrb,
    input                            axi4l_wready,
    input                            axi4l_bvalid,		//WRITE-RESPONSE channel 
    input                      [1:0] axi4l_bresp,
    output reg                       axi4l_bready,
    output reg                       axi4l_arvalid,		//READ-ADDRESS channel
    output wire [CSR_ADDR_WIDTH-1:0] axi4l_araddr,		//word address
    input                            axi4l_arready,
    output reg                       axi4l_rready,		//READ-DATA channel
    input                            axi4l_rvalid,
    input                     [31:0] axi4l_rdata,
    input                      [1:0] axi4l_rresp
  );

//------------------------------------------------------------------------------
// reg/wire declaration
//------------------------------------------------------------------------------
reg                          csr_en_d;
reg                          csr_wen_lvl;
reg                          csr_aren_lvl;
reg                          axi4l_wen_lvl_d;
reg                          axi4l_aren_lvl_d;
reg                          axi4l_wdn_lvl;
reg                          axi4l_ardn_lvl;
reg                          axi4l_ren_lvl;
reg                          csr_wdn_lvl_d;
reg                          csr_ardn_lvl_d;
reg                          axi4l_rdn_lvl_d;

wire [CSR_ADDR_WIDTH+32-1:0] csr_wchn;
wire [CSR_ADDR_WIDTH+32-1:0] axi4l_wchn;
wire                         axi4l_wen_lvl;
wire                         axi4l_aren_lvl;
wire                         axi4l_rdn_lvl;
wire                         axi4l_wen;
wire                         axi4l_wdn_en;
wire                         csr_wdn_lvl;
wire                         csr_ardn_lvl;
wire                         csr_wdn_en;
wire                         csr_rdn_en;



//------------------------------------------------------------------------------
// clk domain
//------------------------------------------------------------------------------
// controller inputs
assign csr_wchn     = {csr_addr,csr_wdata};

always @(posedge clk)
  if (rst)
    csr_en_d <= 1'b0;
  else
    csr_en_d <= csr_en;

always @(posedge clk)
  if (rst)
    csr_wen_lvl <= 1'b0;
  else
    csr_wen_lvl <= csr_en & csr_wr & ~csr_wen_lvl & ~csr_wdn_lvl ? 1'b1 : 
	               (csr_wen_lvl & csr_wdn_lvl) ? 1'b0 : csr_wen_lvl ;

always @(posedge clk)
  if (rst)
    csr_aren_lvl <= 1'b0;
  else
    csr_aren_lvl <= csr_en & ~csr_wr & ~csr_aren_lvl & ~csr_ardn_lvl? 1'b1 :
	               (csr_aren_lvl & csr_ardn_lvl) ? 1'b0 : csr_aren_lvl;

// controller outputs
always @(posedge clk)
  if (rst)
    csr_wdn_lvl_d <= 1'b0;
  else
    csr_wdn_lvl_d <= csr_wdn_lvl;

assign csr_wdn_en = csr_wdn_lvl & ~csr_wdn_lvl_d;

always @(posedge clk)
  if (rst)
    csr_done <= 1'b0;
  else
    csr_done <= csr_wdn_en | csr_rdn_en;

//------------------------------------------------------------------------------
// axi4l_aclk domain
//------------------------------------------------------------------------------
assign axi4l_awaddr = axi4l_wchn[32+:CSR_ADDR_WIDTH];
assign axi4l_wdata  = axi4l_wchn[31:0];

// WR-Address channel
always @(posedge axi4l_aclk)
  if (!axi4l_aresetn)
    axi4l_wen_lvl_d <= 1'b0;
  else
    axi4l_wen_lvl_d <= axi4l_wen_lvl;

assign axi4l_wen = axi4l_wen_lvl & ~axi4l_wen_lvl_d;

always @(posedge axi4l_aclk)
  if (!axi4l_aresetn)
    axi4l_awvalid <= 1'b0;
  else
    axi4l_awvalid <= axi4l_wen | (axi4l_awvalid & ~axi4l_awready);

// WR-Data channel
always @(posedge axi4l_aclk)
  if (!axi4l_aresetn)
    axi4l_wvalid <= 1'b0;
  else
    axi4l_wvalid <= axi4l_wen | (axi4l_wvalid & ~axi4l_wready);

assign axi4l_wstrb = 4'hf;

// WR-Response channel
always @(posedge axi4l_aclk)
  if (!axi4l_aresetn)
    axi4l_bready <= 1'b0;
  else
    axi4l_bready <= (axi4l_awvalid & axi4l_awready) | (axi4l_bready & ~axi4l_bvalid);

assign axi4l_wdn_en = axi4l_bready & axi4l_bvalid;

always @(posedge axi4l_aclk)
  if (!axi4l_aresetn)
    axi4l_wdn_lvl <= 1'b0;
  else
    axi4l_wdn_lvl <= axi4l_wdn_en ? 1'b1 :
	                 (axi4l_wdn_lvl & ~axi4l_wen_lvl) ? 1'b0 : axi4l_wdn_lvl;

// RD-Address channel
always @(posedge axi4l_aclk)
  if (!axi4l_aresetn)
    axi4l_aren_lvl_d <= 1'b0;
  else
    axi4l_aren_lvl_d <= axi4l_aren_lvl;

assign axi4l_aren = axi4l_aren_lvl & ~axi4l_aren_lvl_d;

always @(posedge axi4l_aclk)
  if (!axi4l_aresetn)
    axi4l_arvalid <= 1'b0;
  else
    axi4l_arvalid <= axi4l_aren | (axi4l_arvalid & ~axi4l_arready);

always @(posedge axi4l_aclk)
  if (!axi4l_aresetn)
    axi4l_ardn_lvl <= 1'b0;
  else 
    axi4l_ardn_lvl <= (axi4l_arvalid & axi4l_arready) ? 1'b1 :
	                  (~axi4l_aren_lvl & axi4l_ardn_lvl) ? 1'b0 : axi4l_ardn_lvl;

// RD-Response channel
always @ (posedge axi4l_aclk)
  if (!axi4l_aresetn) 
    axi4l_ren_lvl <= 1'b0;
  else
    axi4l_ren_lvl <= axi4l_rdn_lvl ? 1'b0 :
	                 (axi4l_rvalid & ~axi4l_ren_lvl) ? 1'b1 :
	                  axi4l_ren_lvl;

always @(posedge axi4l_aclk)
  if (!axi4l_aresetn)
    axi4l_rdn_lvl_d <= 1'b0;
  else
    axi4l_rdn_lvl_d <= axi4l_rdn_lvl;


always @(posedge axi4l_aclk)
  if (!axi4l_aresetn)
    axi4l_rready <= 1'b0;
  else
    axi4l_rready <= axi4l_rdn_lvl & ~axi4l_rdn_lvl_d;

//------------------------------------------------------------------------------
// CDC logic
//------------------------------------------------------------------------------

xpm_cdc_handshake #(
  // Module parameters
  .WIDTH        (CSR_ADDR_WIDTH+32),
  .DEST_EXT_HSK (1),
  .DEST_SYNC_FF (3)
) u_waddr_c2a_cdc(
  // Module ports
  .src_clk  (clk), 
  .src_in   (csr_wchn), 
  .src_send (csr_wen_lvl), 
  .src_rcv  (csr_wdn_lvl) , 
  .dest_clk (axi4l_aclk) , 
  .dest_out (axi4l_wchn), 
  .dest_req (axi4l_wen_lvl), 
  .dest_ack (axi4l_wdn_lvl)
);

xpm_cdc_handshake #(
  // Module parameters
  .WIDTH        (CSR_ADDR_WIDTH),
  .DEST_EXT_HSK (1),
  .DEST_SYNC_FF (3)
) u_raddr_c2a_cdc(
  // Module ports
  .src_clk  (clk), 
  .src_in   (csr_addr), 
  .src_send (csr_aren_lvl), 
  .src_rcv  (csr_ardn_lvl) , 
  .dest_clk (axi4l_aclk) , 
  .dest_out (axi4l_araddr), 
  .dest_req (axi4l_aren_lvl), 
  .dest_ack (axi4l_ardn_lvl)
);


xpm_cdc_handshake #(
  // Module parameters
  .WIDTH        (32),
  .DEST_EXT_HSK (0),
  .DEST_SYNC_FF (3)
) u_rdata_cac_cdc(
  // Module ports
  .src_clk  (axi4l_aclk), 
  .src_in   (axi4l_rdata), 
  .src_send (axi4l_ren_lvl),  
  .src_rcv  (axi4l_rdn_lvl) , 
  .dest_clk (clk) , 
  .dest_out (csr_rdata), 
  .dest_req (csr_rdn_en), 
  .dest_ack (1'b0)
);

endmodule

