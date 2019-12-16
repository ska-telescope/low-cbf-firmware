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
// File       : hmc_ul.v
// Version    : 1.0  
//-----------------------------------------------------------------------------

//==============================================================================
// HMC User Layer Top module
//==============================================================================
`timescale 1ns/1ps

module hmc_ul
  #(parameter HMC_VER=1,								// HMC protocol version
    parameter N_FLIT=6,									// number of FLITs for TL/LL
    parameter FLIT_W=128,
    parameter AXI4_IF_DT_FLIT=8,
    parameter AXI4_UID_W=(HMC_VER==1) ? 9 : 11,			// AXI4MM User-ID width (bits)
    parameter AXI4_CMD_W=(HMC_VER==1) ? 6 : 7,			// AXI4MM CMD width (bits)
    parameter AXI4_AUSER_W=AXI4_CMD_W+3,				// AXI4MM AxUSER width: {CUB[2:0], CMD[n-1:0]}; n=6(gen2) or 7(gen3)
    parameter AXI4_BUSER_W=(HMC_VER==1) ? 18 : 152,		// AXI4MM BUSER width (bits)
    parameter AXI4_RUSER_W=(HMC_VER==1) ? 18 : 20,		// AXI4MM RUSER width (bits)
    parameter AXI4_IF_WDT_W=FLIT_W*AXI4_IF_DT_FLIT,		// AXI4MM WDATA bus width (bits)
    parameter AXI4_IF_RDT_W=FLIT_W*AXI4_IF_DT_FLIT,		// AXI4MM RDATA bus width (bits)
    parameter TL_DATA_W=FLIT_W*N_FLIT					// TL-RX data width (bits)
  ) (
    input                                clk,
    input                                rst,
    // AXI4-MM Write-Address channel
    input                                axi4mm_awvalid,	// AWVALID
    input               [AXI4_UID_W-1:0] axi4mm_awid,		// AWID
    input                       [34-1:0] axi4mm_awaddr,		// AWADDR
    input             [AXI4_AUSER_W-1:0] axi4mm_awuser,		// AWUSER
    input                        [8-1:0] axi4mm_awlen,		// AWLEN
    output wire                          axi4mm_awready,	// AWREADY
    // AXI4-MM Write-Data channel
    input                                axi4mm_wvalid,		// WVALID
    input               [AXI4_UID_W-1:0] axi4mm_wid,		// WID
    input            [AXI4_IF_WDT_W-1:0] axi4mm_wdata,		// WDATA
    input          [AXI4_IF_DT_FLIT-1:0] axi4mm_wstrb,		// WSTRB
    output wire                          axi4mm_wready,		// WREADY
    // AXI4-MM Read-Address channel
    input                                axi4mm_arvalid,	// ARVALID
    input               [AXI4_UID_W-1:0] axi4mm_arid,		// ARID
    input                       [34-1:0] axi4mm_araddr,		// ARADDR
    input             [AXI4_AUSER_W-1:0] axi4mm_aruser,		// ARUSER
    output wire                          axi4mm_arready,	// ARREADY
    // AXI4-MM WR-Response Interface
    output wire                          axi4mm_bvalid,
    output wire         [AXI4_UID_W-1:0] axi4mm_bid,
    output wire       [AXI4_BUSER_W-1:0] axi4mm_buser,
    output wire                  [2-1:0] axi4mm_bresp,
    input                                axi4mm_bready,
    // AXI4-MM RD-Response Interface
    output wire                          axi4mm_rvalid,
    output wire         [AXI4_UID_W-1:0] axi4mm_rid,
    output wire       [AXI4_RUSER_W-1:0] axi4mm_ruser,
    output wire      [AXI4_IF_RDT_W-1:0] axi4mm_rdata,
    output wire                  [2-1:0] axi4mm_rresp,
    output wire                          axi4mm_rlast,
    input                                axi4mm_rready,
    // Transaction Layer TX Interface
    output wire                          tltx_valid,
    output wire          [TL_DATA_W-1:0] tltx_flit_dat,
    output wire             [N_FLIT-1:0] tltx_flit_vld,
    output wire             [N_FLIT-1:0] tltx_flit_sop,
    output wire             [N_FLIT-1:0] tltx_flit_eop,
    input                                tltx_ready,
    // Transaction-Layer RX Interface
    input                                tlrx_valid,
    input                [TL_DATA_W-1:0] tlrx_flit_dat,
    input                   [N_FLIT-1:0] tlrx_flit_vld,
    input                   [N_FLIT-1:0] tlrx_flit_sop,
    input                   [N_FLIT-1:0] tlrx_flit_eop,
    output wire                          tlrx_ready
);

localparam ULPORT_N = 1;
localparam USE_ATOMIC_CMD = 0;
localparam AXI4_MAX_DT_FLIT = 8;
localparam AXI4_WDT_CHNNL_ALIGN = 1;
localparam AXI4_RDT_CHNNL_ALIGN = 1;
localparam AXI4_UID_REORDER = 0;
localparam UL_TXMEM_DEPTH = 512;

ul_top
  #(.HMC_VER(HMC_VER),
    .N_FLIT(N_FLIT),
    .FLIT_W(FLIT_W),
    .ULPORT_N(ULPORT_N),
    .USE_ATOMIC_CMD(USE_ATOMIC_CMD),
    .AXI4_IF_WDT_FLIT(AXI4_IF_DT_FLIT),
    .AXI4_IF_RDT_FLIT(AXI4_IF_DT_FLIT),
    .AXI4_MAX_WDT_FLIT(AXI4_MAX_DT_FLIT),
    .AXI4_MAX_RDT_FLIT(AXI4_MAX_DT_FLIT),
    .AXI4_WDT_CHNNL_ALIGN(AXI4_WDT_CHNNL_ALIGN),
    .AXI4_RDT_CHNNL_ALIGN(AXI4_RDT_CHNNL_ALIGN),
    .AXI4_UID_REORDER(AXI4_UID_REORDER),
    .UL_TXMEM_DEPTH(UL_TXMEM_DEPTH)
  ) ul_inst (
    .clk				(clk),
    .rst				(rst),
    .cfg_aging_tm_round	(32'hffff),
    .stt_tag_mgmt_cnt	(),
    .stt_tag_mgmt_err	(),
    .axi4mm_awvalid		(axi4mm_awvalid),
    .axi4mm_awid		(axi4mm_awid),
    .axi4mm_awaddr		(axi4mm_awaddr),
    .axi4mm_awuser		(axi4mm_awuser),
    .axi4mm_awlen		(axi4mm_awlen),
    .axi4mm_awready		(axi4mm_awready),
    .axi4mm_wvalid		(axi4mm_wvalid),
    .axi4mm_wid			(axi4mm_wid),
    .axi4mm_wdata		(axi4mm_wdata),
    .axi4mm_wstrb		(axi4mm_wstrb),
    .axi4mm_wready		(axi4mm_wready),
    .axi4mm_arvalid		(axi4mm_arvalid),
    .axi4mm_arid		(axi4mm_arid),
    .axi4mm_araddr		(axi4mm_araddr),
    .axi4mm_aruser		(axi4mm_aruser),
    .axi4mm_arready		(axi4mm_arready),
    .axi4mm_bvalid		(axi4mm_bvalid),
    .axi4mm_bid			(axi4mm_bid),
    .axi4mm_buser		(axi4mm_buser),
    .axi4mm_bresp		(axi4mm_bresp),
    .axi4mm_bready		(axi4mm_bready),
    .axi4mm_rvalid		(axi4mm_rvalid),
    .axi4mm_rid			(axi4mm_rid),
    .axi4mm_ruser		(axi4mm_ruser),
    .axi4mm_rdata		(axi4mm_rdata),
    .axi4mm_rresp		(axi4mm_rresp),
    .axi4mm_rlast		(axi4mm_rlast),
    .axi4mm_rready		(axi4mm_rready),
    .tltx_valid			(tltx_valid),
    .tltx_flit_dat		(tltx_flit_dat),
    .tltx_flit_vld		(tltx_flit_vld),
    .tltx_flit_sop		(tltx_flit_sop),
    .tltx_flit_eop		(tltx_flit_eop),
    .tltx_ready			(tltx_ready),
    .tlrx_valid			(tlrx_valid),
    .tlrx_flit_dat		(tlrx_flit_dat),
    .tlrx_flit_vld		(tlrx_flit_vld),
    .tlrx_flit_sop		(tlrx_flit_sop),
    .tlrx_flit_eop		(tlrx_flit_eop),
    .tlrx_ready			(tlrx_ready) );

endmodule

