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
// File       : tgen_top.v
// Version    : 1.0  
//-----------------------------------------------------------------------------

//==============================================================================
// Traffic Generator Top
//==============================================================================

`timescale 1ns/1ps

module tgen_top
  #(parameter HMC_VER=1,                            // HMC standard version; 1:Gen2; 2:Gen3
    parameter FLIT_W=128,                           // HMC FLIT width (bits)
    parameter TGEN_REQ_NUM=8,                       // Traffic-Generator # of requests
    parameter TGEN_SIM_F=0,
    parameter HMCC_TOKEN=512,
    parameter DEV_CUB_ID=3'b000,                    // HMC device CUB-ID
    parameter AXI4_IF_DT_FLIT=8,                    // AXI4MM DATA interface FLIT number
    parameter AXI4_DT_CHNNL_ALIGN=1,                // AXI4MM DATA channel is always aligned to bit-0
    parameter CSR_ADDR_WIDTH=10,
    parameter AXI4_UID_W=(HMC_VER==1) ? 9 : 11,     // AXI4MM User-ID width (bits)
    parameter AXI4_CMD_W=(HMC_VER==1) ? 6 : 7,      // AXI4MM CMD width (bits)
    parameter AXI4_AUSER_W=AXI4_CMD_W+3,            // AXI4MM AxUSER width: {CUB[2:0], CMD[n-1:0]}; n=6(gen2) or 7(gen3)
    parameter AXI4_BUSER_W=(HMC_VER==1) ? 18 : 152, // AXI4MM BUSER width (bits)
                                                    //  - Gen2:{ageout, slid[2:0], errstat[6:0], dinv, cmd[5:0]};
                                                    //  - Gen3:{data[127:0], dt_vld, 3'b0, ageout, af, slid[2:0], errstat[6:0], dinv, cmd[6:0]}
    parameter AXI4_RUSER_W=(HMC_VER==1) ? 18 : 20,  // AXI4MM RUSER width (bits)
                                                    //  - Gen2:{ageout, slid[2:0], errstat[6:0], dinv, cmd[5:0]};
                                                    //  - Gen3:{ageout, af, slid[2:0], errstat[6:0], dinv, cmd[6:0]}
    parameter AXI4_IF_DT_W=FLIT_W*AXI4_IF_DT_FLIT   // AXI4MM DATA bus width (bits)
  ) (
    input                               clk_free,
    input                               clk_hmc,
    input                               rst,
    // Traffic-Generator Status
    input                               clkdrv_init_done,
    input                               dev_init_done,
    output wire                         hmc_tgen_proc,
    output wire                         hmc_tgen_done,
    output wire                         hmc_tgen_pass,
    output wire                         hmc_mmcm_lock,
    output wire                         hmc_gt_tx_done,
    output wire                         hmc_gt_rx_done,
    output wire                         hmc_link_up,
    output wire                         hmc_devinit_en,
    output wire                         hmc_wrreq_proc,
    output wire                         hmc_rdreq_proc,
    output reg                    [7:0] axi4mm_ch_aw_cnt,
    output reg                    [7:0] axi4mm_ch_w_cnt,
    output reg                    [7:0] axi4mm_ch_b_cnt,
    output reg                    [7:0] axi4mm_ch_ar_cnt,
    output reg                    [7:0] axi4mm_ch_r_cnt,
    output wire                   [3:0] dbg_tgen_fsm,
    // HMC Controller Status
    input                               l2_rst_mmcm,
    // AXI4-MM Write-Address channel
    output wire                         axi4mm_awvalid,		// AWVALID
    output wire        [AXI4_UID_W-1:0] axi4mm_awid,		// AWID
    output wire                [34-1:0] axi4mm_awaddr,		// AWADDR
    output wire      [AXI4_AUSER_W-1:0] axi4mm_awuser,		// AWUSER
    output wire                 [8-1:0] axi4mm_awlen,		// AWLEN
    input                               axi4mm_awready,		// AWREADY
    // AXI4-MM Write-Data channel
    output wire                         axi4mm_wvalid,		// WVALID
    output wire        [AXI4_UID_W-1:0] axi4mm_wid,			// WID
    output wire      [AXI4_IF_DT_W-1:0] axi4mm_wdata,		// WDATA
    output wire   [AXI4_IF_DT_FLIT-1:0] axi4mm_wstrb,		// WSTRB
    input                               axi4mm_wready,		// WREADY
    // AXI4-MM Read-Address channel
    output wire                         axi4mm_arvalid,		// ARVALID
    output wire        [AXI4_UID_W-1:0] axi4mm_arid,		// ARID
    output wire                [34-1:0] axi4mm_araddr,		// ARADDR
    output wire      [AXI4_AUSER_W-1:0] axi4mm_aruser,		// ARUSER
    input                               axi4mm_arready,		// ARREADY
    // AXI4-MM Write-Response channel
    input                               axi4mm_bvalid,		// BVALID
    input              [AXI4_UID_W-1:0] axi4mm_bid,			// BID
    input            [AXI4_BUSER_W-1:0] axi4mm_buser,		// BUSER
    input                       [2-1:0] axi4mm_bresp,		// BRESP
    output wire                         axi4mm_bready,		// BREADY
    // AXI4-MM Read-Response channel
    input                               axi4mm_rvalid,		// RVALID
    input              [AXI4_UID_W-1:0] axi4mm_rid,			// RID
    input            [AXI4_RUSER_W-1:0] axi4mm_ruser,		// RUSER
    input            [AXI4_IF_DT_W-1:0] axi4mm_rdata,		// RDATA
    input                               axi4mm_rlast,		// RLAST
    input                       [2-1:0] axi4mm_rresp,		// RRESP
    output wire                         axi4mm_rready,		// RREADY
    // HMC AXI4_LITE I/F
    input                               axi4l_clk,
    input                               axi4l_resetn,
    output wire                         axi4l_awvalid,		//WRITE-ADDRESS channel
    output wire    [CSR_ADDR_WIDTH-1:0] axi4l_awaddr,		//word address
    input                               axi4l_awready,
    output wire                         axi4l_wvalid,		//WRITE-DATA channel
    output wire                  [31:0] axi4l_wdata,
    output wire                   [3:0] axi4l_wstrb,
    input                               axi4l_wready,
    input                               axi4l_bvalid,		//WRITE-RESPONSE channel 
    input                         [1:0] axi4l_bresp,
    output wire                         axi4l_bready,
    output wire                         axi4l_arvalid,		//READ-ADDRESS channel
    output wire    [CSR_ADDR_WIDTH-1:0] axi4l_araddr,		//word address
    input                               axi4l_arready,
    output wire                         axi4l_rready,		//READ-DATA channel
    input                               axi4l_rvalid,
    input                        [31:0] axi4l_rdata,
    input                         [1:0] axi4l_rresp
  );

localparam TGEN_MAX_DT_HLEN = (HMC_VER==1) ? (cquotient(8, AXI4_IF_DT_FLIT) + ((AXI4_DT_CHNNL_ALIGN==1) ? 1'b0 : 1'b1)) :
                                             (cquotient(16, AXI4_IF_DT_FLIT) + ((AXI4_DT_CHNNL_ALIGN==1) ? 1'b0 : 1'b1));
localparam CSR_WCMD_BUS_W = AXI4_AUSER_W+32+8;
localparam CSR_RCMD_BUS_W = AXI4_AUSER_W+32;
localparam CSR_DATA_BUS_W = AXI4_IF_DT_W+AXI4_IF_DT_FLIT+1;

//------------------------------------------------------------------------------
// reg/wire declaration
//------------------------------------------------------------------------------
wire [CSR_ADDR_WIDTH-1:0] fsm_csr_addr;
wire               [31:0] fsm_csr_wdata;
wire               [31:0] fsm_csr_rdata;
wire [CSR_WCMD_BUS_W-1:0] dtgen_wcmd_bus;
wire [CSR_RCMD_BUS_W-1:0] dtgen_rcmd_bus;
wire [CSR_DATA_BUS_W-1:0] dtgen_wdt_bus;
wire [CSR_DATA_BUS_W-1:0] dtgen_rdt_bus;
wire                      axi4mm_ch_aw_tx;
wire                      axi4mm_ch_ar_tx;
wire                      axi4mm_ch_w_tx;
wire                      axi4mm_ch_b_rx;
wire                      axi4mm_ch_r_rx;

xpm_cdc_sync_rst #(.DEST_SYNC_FF(3)) u_rst_free_sync(.src_rst(rst), .dest_clk(clk_free), .dest_rst(rst_free));
xpm_cdc_sync_rst #(.DEST_SYNC_FF(3)) u_rst_hmc_sync (.src_rst(rst), .dest_clk(clk_hmc ), .dest_rst(rst_hmc));

xpm_cdc_single #(.DEST_SYNC_FF(3),.SRC_INPUT_REG(0)) u_wrreq_proc_cdc_sync(.src_clk(1'b0),.dest_clk(clk_free),.src_in(tgen_wrreq_busy),.dest_out(hmc_wrreq_proc));
xpm_cdc_single #(.DEST_SYNC_FF(3),.SRC_INPUT_REG(0)) u_rdreq_proc_cdc_sync(.src_clk(1'b0),.dest_clk(clk_free),.src_in(tgen_rdreq_busy),.dest_out(hmc_rdreq_proc));

//------------------------------------------------------------------------------
// TGEN FSM instantiation
//------------------------------------------------------------------------------
tgen_fsm
  #(.TGEN_SIM_F(TGEN_SIM_F),
    .CSR_ADDR_WIDTH(CSR_ADDR_WIDTH),
    .HMCC_TOKEN(HMCC_TOKEN)
  ) u_tgen_fsm (
    .clk              (clk_free),
    .rst              (rst_free),
    .clk_hmc          (clk_hmc),
    .rst_hmc          (rst_hmc),
    .fsm_devinit_en   (hmc_devinit_en),
    .fsm_dtgen_en     (fsm_dtgen_en),
    .fsm_wrreq_en     (fsm_wrreq_en),
    .fsm_rdreq_en     (fsm_rdreq_en),
    .l2_rst_mmcm      (l2_rst_mmcm),
    .clkdrv_init_done (clkdrv_init_done),
    .dev_init_done    (dev_init_done),
    .dtgen_done       (dtgen_fsm_done),
    .wrreq_done       (wrreq_fsm_done),
    .wrreq_pass       (wrreq_fsm_pass),
    .rdreq_done       (rdreq_fsm_done),
    .rdreq_pass       (rdreq_fsm_pass),
    .csr_en           (fsm_csr_en),
    .csr_wr           (fsm_csr_wr),
    .csr_addr         (fsm_csr_addr),
    .csr_wdata        (fsm_csr_wdata),
    .csr_done         (fsm_csr_done),
    .csr_rdata        (fsm_csr_rdata),
    .hmc_tgen_proc    (hmc_tgen_proc),
    .hmc_tgen_done    (hmc_tgen_done),
    .hmc_tgen_pass    (hmc_tgen_pass),
    .hmc_mmcm_lock    (hmc_mmcm_lock),
    .hmc_gt_tx_done   (hmc_gt_tx_done),
    .hmc_gt_rx_done   (hmc_gt_rx_done),
    .hmc_link_up      (hmc_link_up),
    .dbg_tgen_fsm     (dbg_tgen_fsm) );

//------------------------------------------------------------------------------
// TGEN CSR Control instantiation
//------------------------------------------------------------------------------
tgen_csr_access
  #(.CSR_ADDR_WIDTH(CSR_ADDR_WIDTH)
  ) u_tgen_csr_access (
    .clk           (clk_free),
    .rst           (rst_free),
    .csr_en        (fsm_csr_en),
    .csr_wr        (fsm_csr_wr),
    .csr_addr      (fsm_csr_addr),
    .csr_wdata     (fsm_csr_wdata),
    .csr_done      (fsm_csr_done),
    .csr_rdata     (fsm_csr_rdata),
    .axi4l_aclk    (axi4l_clk),
    .axi4l_aresetn (axi4l_resetn),
    .axi4l_awvalid (axi4l_awvalid),
    .axi4l_awaddr  (axi4l_awaddr),
    .axi4l_awready (axi4l_awready),
    .axi4l_wvalid  (axi4l_wvalid),
    .axi4l_wdata   (axi4l_wdata),
    .axi4l_wstrb   (axi4l_wstrb),
    .axi4l_wready  (axi4l_wready),
    .axi4l_bvalid  (axi4l_bvalid),
    .axi4l_bresp   (axi4l_bresp),
    .axi4l_bready  (axi4l_bready),
    .axi4l_arvalid (axi4l_arvalid),
    .axi4l_araddr  (axi4l_araddr),
    .axi4l_arready (axi4l_arready),
    .axi4l_rready  (axi4l_rready),
    .axi4l_rvalid  (axi4l_rvalid),
    .axi4l_rdata   (axi4l_rdata),
    .axi4l_rresp   (axi4l_rresp) );

//------------------------------------------------------------------------------
// TGEN Data Generation instantiation
//------------------------------------------------------------------------------
tgen_data_gen
  #(.HMC_VER(HMC_VER),
    .FLIT_W(FLIT_W),
    .TGEN_REQ_NUM(TGEN_REQ_NUM),
    .DEV_CUB_ID(DEV_CUB_ID),
    .AXI4_IF_DT_FLIT(AXI4_IF_DT_FLIT),
    .AXI4_DT_CHNNL_ALIGN(AXI4_DT_CHNNL_ALIGN),
    .TGEN_MAX_DT_HLEN(TGEN_MAX_DT_HLEN)
  ) u_tgen_data_gen (
    .clk           (clk_hmc),
    .rst           (rst_hmc),
    .fsm_dtgen_en  (fsm_dtgen_en),
    .fsm_dtgen_dn  (dtgen_fsm_done),
    .req_wcmd_push (dtgen_wcmd_push),
    .req_rcmd_push (dtgen_rcmd_push),
    .req_wdt_push  (dtgen_wdt_push),
    .req_rdt_push  (dtgen_rdt_push),
    .req_wcmd_bus  (dtgen_wcmd_bus),
    .req_rcmd_bus  (dtgen_rcmd_bus),
    .req_wdt_bus   (dtgen_wdt_bus),
    .req_rdt_bus   (dtgen_rdt_bus) );

//------------------------------------------------------------------------------
// TGEN AXI4MM WRITE-Request Control instantiation
//------------------------------------------------------------------------------
tgen_axi4mm_wreq
  #(.HMC_VER(HMC_VER),
    .FLIT_W(FLIT_W),
    .TGEN_REQ_NUM(TGEN_REQ_NUM),
    .AXI4_IF_DT_FLIT(AXI4_IF_DT_FLIT),
    .TGEN_MAX_DT_HLEN(TGEN_MAX_DT_HLEN)
  ) u_tgen_axi4mm_wreq (
    .clk             (clk_hmc),
    .rst             (rst_hmc),
    .req_cmd_push    (dtgen_wcmd_push),
    .req_wdt_push    (dtgen_wdt_push),
    .req_cmd_in      (dtgen_wcmd_bus),
    .req_wdt_in      (dtgen_wdt_bus),
    .tgen_clear      (fsm_dtgen_en),
    .tgen_start      (fsm_wrreq_en),
    .tgen_ch_addr_tx (axi4mm_ch_aw_tx),
    .tgen_ch_data_tx (axi4mm_ch_w_tx),
    .tgen_ch_resp_rx (axi4mm_ch_b_rx),
    .tgen_busy       (tgen_wrreq_busy),
    .tgen_done       (wrreq_fsm_done),
    .tgen_pass       (wrreq_fsm_pass),
    .axi4mm_awvalid  (axi4mm_awvalid),
    .axi4mm_awid     (axi4mm_awid),
    .axi4mm_awaddr   (axi4mm_awaddr),
    .axi4mm_awuser   (axi4mm_awuser),
    .axi4mm_awlen    (axi4mm_awlen),
    .axi4mm_awready  (axi4mm_awready),
    .axi4mm_wvalid   (axi4mm_wvalid),
    .axi4mm_wid      (axi4mm_wid),
    .axi4mm_wdata    (axi4mm_wdata),
    .axi4mm_wstrb    (axi4mm_wstrb),
    .axi4mm_wready   (axi4mm_wready),
    .axi4mm_bvalid   (axi4mm_bvalid),
    .axi4mm_bid      (axi4mm_bid),
    .axi4mm_buser    (axi4mm_buser),
    .axi4mm_bresp    (axi4mm_bresp),
    .axi4mm_bready   (axi4mm_bready) );

always @(posedge clk_hmc)
  if (rst_hmc) begin
    axi4mm_ch_aw_cnt <= 8'b0;
    axi4mm_ch_w_cnt <= 8'b0;
    axi4mm_ch_b_cnt <= 8'b0;
  end
  else if (fsm_dtgen_en) begin
    axi4mm_ch_aw_cnt <= 8'b0;
    axi4mm_ch_w_cnt <= 8'b0;
    axi4mm_ch_b_cnt <= 8'b0;
  end
  else begin
    axi4mm_ch_aw_cnt <= (axi4mm_ch_aw_tx) ? (axi4mm_ch_aw_cnt + 1'b1) : axi4mm_ch_aw_cnt;
    axi4mm_ch_w_cnt <= (axi4mm_ch_w_tx) ? (axi4mm_ch_w_cnt + 1'b1) : axi4mm_ch_w_cnt;
    axi4mm_ch_b_cnt <= (axi4mm_ch_b_rx) ? (axi4mm_ch_b_cnt + 1'b1) : axi4mm_ch_b_cnt;
  end

//------------------------------------------------------------------------------
// TGEN AXI4MM READ-Request Control instantiation
//------------------------------------------------------------------------------
tgen_axi4mm_rreq
  #(.HMC_VER(HMC_VER),
    .FLIT_W(FLIT_W),
    .TGEN_REQ_NUM(TGEN_REQ_NUM),
    .AXI4_IF_DT_FLIT(AXI4_IF_DT_FLIT),
    .TGEN_MAX_DT_HLEN(TGEN_MAX_DT_HLEN)
  ) u_tgen_axi4mm_rreq (
    .clk             (clk_hmc),
    .rst             (rst_hmc),
    .req_cmd_push    (dtgen_rcmd_push),
    .req_rdt_push    (dtgen_rdt_push),
    .req_cmd_in      (dtgen_rcmd_bus),
    .req_rdt_in      (dtgen_rdt_bus),
    .tgen_clear      (fsm_dtgen_en),
    .tgen_start      (fsm_rdreq_en),
    .tgen_ch_addr_tx (axi4mm_ch_ar_tx),
    .tgen_ch_resp_rx (axi4mm_ch_r_rx),
    .tgen_busy       (tgen_rdreq_busy),
    .tgen_done       (rdreq_fsm_done),
    .tgen_pass       (rdreq_fsm_pass),
    .axi4mm_arvalid  (axi4mm_arvalid),
    .axi4mm_arid     (axi4mm_arid),
    .axi4mm_araddr   (axi4mm_araddr),
    .axi4mm_aruser   (axi4mm_aruser),
    .axi4mm_arready  (axi4mm_arready),
    .axi4mm_rvalid   (axi4mm_rvalid),
    .axi4mm_rid      (axi4mm_rid),
    .axi4mm_ruser    (axi4mm_ruser),
    .axi4mm_rdata    (axi4mm_rdata),
    .axi4mm_rlast    (axi4mm_rlast),
    .axi4mm_rresp    (axi4mm_rresp),
    .axi4mm_rready   (axi4mm_rready) );

always @(posedge clk_hmc)
  if (rst_hmc) begin
    axi4mm_ch_ar_cnt <= 8'b0;
    axi4mm_ch_r_cnt <= 8'b0;
  end
  else if (fsm_dtgen_en) begin
    axi4mm_ch_ar_cnt <= 8'b0;
    axi4mm_ch_r_cnt <= 8'b0;
  end
  else begin
    axi4mm_ch_ar_cnt <= (axi4mm_ch_ar_tx) ? (axi4mm_ch_ar_cnt + 1'b1) : axi4mm_ch_ar_cnt;
    axi4mm_ch_r_cnt <= (axi4mm_ch_r_rx) ? (axi4mm_ch_r_cnt + 1'b1) : axi4mm_ch_r_cnt;
  end

//------------------------------------------------------------------------------
// Functions
//------------------------------------------------------------------------------
function integer cquotient;
  input real numerator;
  input real denominator;
  begin
    for (cquotient=0; numerator>0; cquotient=cquotient+1) numerator = (numerator > denominator) ? (numerator - denominator) : 0;
  end
endfunction

endmodule

