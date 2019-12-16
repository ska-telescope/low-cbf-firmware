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
// File       : tgen_axi4mm_wreq.v
// Version    : 1.0  
//-----------------------------------------------------------------------------
`timescale 1ns/1ps

module tgen_axi4mm_wreq
  #(parameter HMC_VER=1,							// HMC standard version; 1:Gen2; 2:Gen3
    parameter FLIT_W=128,							// HMC FLIT width (bits)
    parameter TGEN_REQ_NUM=8,						// Traffic-Gen # of request
    parameter AXI4_IF_DT_FLIT=8,					// AXI4MM DATA interface FLIT number
    parameter TGEN_MAX_DT_HLEN=4,					// Traffic-Gen maximum HLEN value
    parameter AXI4_UID_W=(HMC_VER==1) ? 9 : 11,		// AXI4MM User-ID width (bits)
    parameter AXI4_CMD_W=(HMC_VER==1) ? 6 : 7,		// AXI4MM CMD width (bits)
    parameter AXI4_AUSER_W=AXI4_CMD_W+3,			// AXI4MM AxUSER width: {CUB[2:0], CMD[n-1:0]}; n=6(gen2) or 7(gen3)
    parameter AXI4_BUSER_W=(HMC_VER==1) ? 18 : 152,	// AXI4MM BUSER width (bits)
                                                    //  - Gen2:{ageout, slid[2:0], errstat[6:0], dinv, cmd[5:0]};
                                                    //  - Gen3:{data[127:0], dt_vld, 3'b0, ageout, af, slid[2:0], errstat[6:0], dinv, cmd[6:0]}
    parameter AXI4_IF_DT_W=FLIT_W*AXI4_IF_DT_FLIT,			// AXI4MM DATA bus width (bits)
    parameter CSR_CMD_BUS_W=AXI4_AUSER_W+32+8,				// CSR command bus width (bits)
    parameter CSR_WDT_BUS_W=AXI4_IF_DT_W+AXI4_IF_DT_FLIT+1	// CSR data bus width (bits)
  ) (
    input                               clk,
    input                               rst,
    // CSR interface
    input                               req_cmd_push,
    input                               req_wdt_push,
    input           [CSR_CMD_BUS_W-1:0] req_cmd_in,
    input           [CSR_WDT_BUS_W-1:0] req_wdt_in,
    input                               tgen_clear,
    input                               tgen_start,
    output reg                          tgen_ch_addr_tx,
    output reg                          tgen_ch_data_tx,
    output reg                          tgen_ch_resp_rx,
    output reg                          tgen_busy,
    output wire                         tgen_done,
    output wire                         tgen_pass,
    // AXI4-MM Write-Address channel
    output wire                         axi4mm_awvalid,		// AWVALID
    output reg         [AXI4_UID_W-1:0] axi4mm_awid,		// AWID
    output wire                [34-1:0] axi4mm_awaddr,		// AWADDR
    output wire      [AXI4_AUSER_W-1:0] axi4mm_awuser,		// AWUSER
    output wire                 [8-1:0] axi4mm_awlen,		// AWLEN
    input                               axi4mm_awready,		// AWREADY
    // AXI4-MM Write-Data channel
    output wire                         axi4mm_wvalid,		// WVALID
    output reg         [AXI4_UID_W-1:0] axi4mm_wid,			// WID
    output wire      [AXI4_IF_DT_W-1:0] axi4mm_wdata,		// WDATA
    output wire   [AXI4_IF_DT_FLIT-1:0] axi4mm_wstrb,		// WSTRB
    input                               axi4mm_wready,		// WREADY
    // AXI4-MM Write-Response channel
    input                               axi4mm_bvalid,		// BVALID
    input              [AXI4_UID_W-1:0] axi4mm_bid,			// BID
    input            [AXI4_BUSER_W-1:0] axi4mm_buser,		// BUSER
    input                       [2-1:0] axi4mm_bresp,		// BRESP
    output wire                         axi4mm_bready		// BREADY
  );

localparam TGEN_REQ_CNTR_W = clogb2(TGEN_REQ_NUM+1);
localparam TGEN_REQ_NUM_M1 = TGEN_REQ_NUM - 1;
localparam LOG2_TGEN_REQ_NUM = clogb2(TGEN_REQ_NUM);
localparam LOG2_TGEN_DT_HLEN = clogb2(TGEN_MAX_DT_HLEN);
localparam BUSER_CHK_MSK = {1'b1, 3'b0, 7'h7f, 1'b1, 6'h3f};
localparam BUSER_CHK_VAL = {1'b0, 3'b0, 7'h00, 1'b0, 6'h39};
localparam CMD_FIFO_WIDTH = CSR_CMD_BUS_W;
localparam CMD_FIFO_ADR_W = LOG2_TGEN_REQ_NUM;
localparam DAT_FIFO_WIDTH = CSR_WDT_BUS_W;
localparam DAT_FIFO_ADR_W = LOG2_TGEN_REQ_NUM+LOG2_TGEN_DT_HLEN;

localparam CMDFF_ADDR_BIT = 0;
localparam CMDFF_ADDR_LEN = 32;
localparam CMDFF_AUSR_BIT = CMDFF_ADDR_LEN;
localparam CMDFF_AUSR_LEN = AXI4_AUSER_W;
localparam CMDFF_HLEN_BIT = CMDFF_ADDR_LEN+AXI4_AUSER_W;
localparam CMDFF_HLEN_LEN = 8;
localparam WDTFF_DATA_BIT = 0;
localparam WDTFF_DATA_LEN = AXI4_IF_DT_W;
localparam WDTFF_STRB_BIT = AXI4_IF_DT_W;
localparam WDTFF_STRB_LEN = AXI4_IF_DT_FLIT;
localparam WDTFF_LAST_BIT = WDTFF_DATA_LEN+WDTFF_STRB_LEN;
localparam WDTFF_LAST_LEN = 1;

function integer clogb2;
  input integer value;
  begin
    value = value - 1;
    for (clogb2=0; value>0; clogb2=clogb2+1) value = value >> 1;
  end
endfunction

//------------------------------------------------------------------------------
// reg/wire declaration
//------------------------------------------------------------------------------
reg                          tgen_reqad_wdw;
reg                          tgen_reqdt_wdw;
reg                          tgen_resp_wdw;
reg    [TGEN_REQ_CNTR_W-1:0] tgen_resp_cntr;
reg     [CMD_FIFO_ADR_W-1:0] wreq_adr_mem_wad;
reg     [CMD_FIFO_ADR_W-1:0] wreq_adr_mem_rad;
reg                    [1:0] wreq_adr_mem_re_d;
reg     [DAT_FIFO_ADR_W-1:0] wreq_dat_mem_wad;
reg     [DAT_FIFO_ADR_W-1:0] wreq_dat_mem_rad;
reg                    [1:0] wreq_dat_mem_re_d;
reg                          axi4mm_bvalid_d;
reg         [AXI4_UID_W-1:0] axi4mm_bid_d;
reg       [AXI4_BUSER_W-1:0] axi4mm_buser_d;
reg                    [1:0] axi4mm_bresp_d;
reg       [TGEN_REQ_NUM-1:0] resp_bid_rxed;
reg                    [1:0] tgen_resp_rx_last_d;
reg                          resp_chk_fail;

wire                         tgen_req_drv_en;
wire                         tgen_1st_req_sent;
wire                         tgen_resp_data_rx;
wire                         tgen_resp_rx_last;
wire                         tgen_resp_bid_dup;
wire                         tgen_resp_chk_ok;
wire                         wreq_adr_mem_re;
wire    [CMD_FIFO_WIDTH-1:0] wreq_adr_mem_rdt;
wire                         pfch_wreq_adr_vld;
wire    [CMD_FIFO_WIDTH-1:0] pfch_wreq_adr_data;
wire                         pfch_wreq_adr_ack;
wire                         wreq_dat_mem_re;
wire    [DAT_FIFO_WIDTH-1:0] wreq_dat_mem_rdt;
wire                         pfch_wreq_dat_vld;
wire    [DAT_FIFO_WIDTH-1:0] pfch_wreq_dat_data;
wire                         pfch_wreq_dat_ack;
wire                         axi4mm_wlast;

//------------------------------------------------------------------------------
// Traffic-Generator control
//------------------------------------------------------------------------------
assign tgen_req_drv_en = tgen_start;

always @(posedge clk)
  if (rst)
    tgen_reqad_wdw <= 1'b0;
  else
    tgen_reqad_wdw <= ~tgen_clear &
                      (tgen_req_drv_en |
                       (tgen_reqad_wdw & ~(wreq_adr_mem_re & (wreq_adr_mem_rad == TGEN_REQ_NUM_M1))));

always @(posedge clk)
  if (rst)
    tgen_reqdt_wdw <= 1'b0;
  else
    tgen_reqdt_wdw <= ~tgen_clear &
                      (tgen_req_drv_en |
                       (tgen_reqdt_wdw & ~(axi4mm_wvalid & axi4mm_wready & (axi4mm_wid == TGEN_REQ_NUM_M1) & axi4mm_wlast)));

always @(posedge clk)
  if (rst)
    tgen_ch_addr_tx <= 1'b0;
  else
    tgen_ch_addr_tx <= axi4mm_awvalid & axi4mm_awready;

always @(posedge clk)
  if (rst)
    tgen_ch_data_tx <= 1'b0;
  else
    tgen_ch_data_tx <= axi4mm_wvalid & axi4mm_wready & axi4mm_wlast;

always @(posedge clk)
  if (rst)
    tgen_ch_resp_rx <= 1'b0;
  else
    tgen_ch_resp_rx <= axi4mm_bvalid & axi4mm_bready;

//------------------------------------------------------------------------------
// Request command FIFO control
//------------------------------------------------------------------------------
always @(posedge clk)
  if (rst)
    wreq_adr_mem_wad <= {CMD_FIFO_ADR_W{1'b0}};
  else
    wreq_adr_mem_wad <= (tgen_clear) ? {CMD_FIFO_ADR_W{1'b0}} :
                        (req_cmd_push) ? (wreq_adr_mem_wad + 1'b1) :
                                         wreq_adr_mem_wad;

always @(posedge clk)
  if (rst)
    wreq_adr_mem_rad <= {CMD_FIFO_ADR_W{1'b0}};
  else
    wreq_adr_mem_rad <= (tgen_clear) ? {CMD_FIFO_ADR_W{1'b0}} :
                        (wreq_adr_mem_re) ? (wreq_adr_mem_rad + 1'b1) :
                                            wreq_adr_mem_rad;

always @(posedge clk)
  if (rst)
    wreq_adr_mem_re_d <= 2'b0;
  else
    wreq_adr_mem_re_d <= {wreq_adr_mem_re_d, wreq_adr_mem_re};

tgen_wreq_dp_bram
  #(.RAM_WIDTH(CMD_FIFO_WIDTH),
    .RAM_AD_SZ(CMD_FIFO_ADR_W)
  ) u_addr_chn_bram (
    .clk		(clk),
    .ena		(req_cmd_push),
    .wea		(1'b1),
    .adra		(wreq_adr_mem_wad),
    .wdta		(req_cmd_in),
    .enb		(wreq_adr_mem_re),
    .adrb		(wreq_adr_mem_rad),
    .rdtb		(wreq_adr_mem_rdt) );

example_hmc_fifo_pfch_ctrl
  #(.FFDATA_W(CMD_FIFO_WIDTH),
    .PFCH_NUM(5)
  ) u_addr_pfch_ctrl (
    .clk			(clk),
    .rst			(rst),
    .fifo_empty		(~tgen_reqad_wdw),
    .fifo_di_rdy	(),
    .fifo_di_req	(wreq_adr_mem_re),
    .fifo_di_vld	(wreq_adr_mem_re_d[1]),
    .fifo_di_data	(wreq_adr_mem_rdt),
    .pfch_buf_full	(),
    .pfch_do_vld	(pfch_wreq_adr_vld),
    .pfch_do_data	(pfch_wreq_adr_data),
    .pfch_do_ack	(pfch_wreq_adr_ack) );

//------------------------------------------------------------------------------
// Request data FIFO control
//------------------------------------------------------------------------------
always @(posedge clk)
  if (rst)
    wreq_dat_mem_wad <= {DAT_FIFO_ADR_W{1'b0}};
  else
    wreq_dat_mem_wad <= (tgen_clear) ? {DAT_FIFO_ADR_W{1'b0}} :
                        (req_wdt_push) ? (wreq_dat_mem_wad + 1'b1) :
                                         wreq_dat_mem_wad;

always @(posedge clk)
  if (rst)
    wreq_dat_mem_rad <= {DAT_FIFO_ADR_W{1'b0}};
  else
    wreq_dat_mem_rad <= (tgen_clear) ? {DAT_FIFO_ADR_W{1'b0}} :
                        (wreq_dat_mem_re) ? (wreq_dat_mem_rad + 1'b1) :
                                            wreq_dat_mem_rad;

always @(posedge clk)
  if (rst)
    wreq_dat_mem_re_d <= 2'b0;
  else
    wreq_dat_mem_re_d <= {wreq_dat_mem_re_d, wreq_dat_mem_re};

tgen_wreq_dp_bram
  #(.RAM_WIDTH(DAT_FIFO_WIDTH),
    .RAM_AD_SZ(DAT_FIFO_ADR_W)
  ) u_data_chn_bram (
    .clk		(clk),
    .ena		(req_wdt_push),
    .wea		(1'b1),
    .adra		(wreq_dat_mem_wad),
    .wdta		(req_wdt_in),
    .enb		(wreq_dat_mem_re),
    .adrb		(wreq_dat_mem_rad),
    .rdtb		(wreq_dat_mem_rdt) );

example_hmc_fifo_pfch_ctrl
  #(.FFDATA_W(DAT_FIFO_WIDTH),
    .PFCH_NUM(5)
  ) u_data_pfch_ctrl (
    .clk			(clk),
    .rst			(rst),
    .fifo_empty		(~tgen_reqdt_wdw),
    .fifo_di_rdy	(),
    .fifo_di_req	(wreq_dat_mem_re),
    .fifo_di_vld	(wreq_dat_mem_re_d[1]),
    .fifo_di_data	(wreq_dat_mem_rdt),
    .pfch_buf_full	(),
    .pfch_do_vld	(pfch_wreq_dat_vld),
    .pfch_do_data	(pfch_wreq_dat_data),
    .pfch_do_ack	(pfch_wreq_dat_ack) );

//------------------------------------------------------------------------------
// Response check
//------------------------------------------------------------------------------
assign tgen_1st_req_sent = tgen_reqdt_wdw & axi4mm_wvalid & axi4mm_wready & axi4mm_wlast & ~tgen_resp_wdw;
assign tgen_resp_data_rx = tgen_resp_wdw & axi4mm_bvalid & axi4mm_bready;
assign tgen_resp_rx_last = tgen_resp_data_rx & (~|tgen_resp_cntr[TGEN_REQ_CNTR_W-1:1]);

always @(posedge clk)
  if (rst)
    tgen_resp_wdw <= 1'b0;
  else
    tgen_resp_wdw <= ~tgen_clear & (tgen_1st_req_sent | (tgen_resp_wdw & ~tgen_resp_rx_last));

always @(posedge clk)
  if (rst)
    tgen_resp_cntr <= {TGEN_REQ_CNTR_W{1'b0}};
  else
    tgen_resp_cntr <= (tgen_1st_req_sent) ? TGEN_REQ_NUM :
                      (tgen_resp_data_rx) ? (tgen_resp_cntr - 1'b1) :
                                            tgen_resp_cntr;

always @(posedge clk)
  if (rst)
    axi4mm_bvalid_d <= 1'b0;
  else
    axi4mm_bvalid_d <= tgen_resp_data_rx;

always @(posedge clk)
  if (rst) begin
    axi4mm_bid_d <= {AXI4_UID_W{1'b0}};
    axi4mm_buser_d <= {AXI4_BUSER_W{1'b0}};
    axi4mm_bresp_d <= 2'b0;
  end
  else if (tgen_resp_data_rx) begin
    axi4mm_bid_d <= axi4mm_bid;
    axi4mm_buser_d <= axi4mm_buser;
    axi4mm_bresp_d <= axi4mm_bresp;
  end

always @(posedge clk)
  if (rst)
    resp_bid_rxed <= {TGEN_REQ_NUM{1'b0}};
  else if (tgen_clear)
    resp_bid_rxed <= {TGEN_REQ_NUM{1'b0}};
  else if (axi4mm_bvalid_d)
    resp_bid_rxed <= resp_bid_rxed | ({{TGEN_REQ_NUM-1{1'b0}}, 1'b1} << axi4mm_bid_d);

assign tgen_resp_bid_dup = axi4mm_bvalid_d &  resp_bid_rxed[axi4mm_bid_d[LOG2_TGEN_REQ_NUM-1:0]];

assign tgen_resp_chk_ok = (axi4mm_bresp_d == 2'b00) &
                          ((axi4mm_buser_d & BUSER_CHK_MSK) == BUSER_CHK_VAL);

always @(posedge clk)
  if (rst)
    resp_chk_fail <= 1'b0;
  else
    resp_chk_fail <= ~tgen_clear &
                     ~tgen_req_drv_en &
                     (resp_chk_fail | tgen_resp_bid_dup | (axi4mm_bvalid_d & ~tgen_resp_chk_ok));

always @(posedge clk)
  if (rst)
    tgen_resp_rx_last_d <= 2'b0;
  else
    tgen_resp_rx_last_d <= {tgen_resp_rx_last_d, tgen_resp_rx_last};

always @(posedge clk)
  if (rst)
    tgen_busy <= 1'b0;
  else
    tgen_busy <= ~tgen_clear & (tgen_req_drv_en | (tgen_busy & ~tgen_resp_rx_last_d[1]));

assign tgen_done = tgen_resp_rx_last_d[1];

assign tgen_pass = ~resp_chk_fail;

//------------------------------------------------------------------------------
// AXI4 interface control
//------------------------------------------------------------------------------
assign axi4mm_awvalid = pfch_wreq_adr_vld;

always @(posedge clk)
  if (rst)
    axi4mm_awid <= {AXI4_UID_W{1'b0}};
  else
    axi4mm_awid <= (tgen_clear) ? {AXI4_UID_W{1'b0}} :
                   (axi4mm_awvalid & axi4mm_awready) ? (axi4mm_awid + 1'b1) :
                                                       axi4mm_awid;

assign axi4mm_awaddr = {2'b0, pfch_wreq_adr_data[CMDFF_ADDR_BIT+:CMDFF_ADDR_LEN]};
assign axi4mm_awlen  = pfch_wreq_adr_data[CMDFF_HLEN_BIT+:CMDFF_HLEN_LEN];
assign axi4mm_awuser = pfch_wreq_adr_data[CMDFF_AUSR_BIT+:CMDFF_AUSR_LEN];

assign pfch_wreq_adr_ack = axi4mm_awready;

assign axi4mm_wvalid = pfch_wreq_dat_vld & tgen_reqdt_wdw;

always @(posedge clk)
  if (rst)
    axi4mm_wid <= {AXI4_UID_W{1'b0}};
  else
    axi4mm_wid <= (tgen_clear) ? {AXI4_UID_W{1'b0}} :
                  (tgen_reqdt_wdw & axi4mm_wvalid & axi4mm_wready & axi4mm_wlast) ? (axi4mm_wid + 1'b1) :
                                                                                    axi4mm_wid;

assign axi4mm_wdata = pfch_wreq_dat_data[WDTFF_DATA_BIT+:WDTFF_DATA_LEN];
assign axi4mm_wstrb = pfch_wreq_dat_data[WDTFF_STRB_BIT+:WDTFF_STRB_LEN];
assign axi4mm_wlast = pfch_wreq_dat_data[WDTFF_LAST_BIT+:WDTFF_LAST_LEN];

assign pfch_wreq_dat_ack = axi4mm_wready;

assign axi4mm_bready = tgen_resp_wdw;

endmodule


//==============================================================================
// Simple Dual-Ports BRAM
//==============================================================================
module tgen_wreq_dp_bram
  #(parameter RAM_WIDTH=256,			// Block-RAM width
    parameter RAM_AD_SZ=8				// Block-RAM address size
  ) (
    input                       clk,
    input                       ena,
    input                       wea,
    input       [RAM_AD_SZ-1:0] adra,
    input       [RAM_WIDTH-1:0] wdta,
    input                       enb,
    input       [RAM_AD_SZ-1:0] adrb,
    output reg  [RAM_WIDTH-1:0] rdtb
  );

localparam RAM_DEPTH = 2**RAM_AD_SZ;	// Block-RAM depth

(* ram_style = "block" *) reg [RAM_WIDTH-1:0] the_bram [RAM_DEPTH-1:0];
reg [RAM_WIDTH-1:0] bram_rdt;

always @(posedge clk) begin
  if (ena) begin
    if (wea) the_bram[adra] <= wdta;
  end
end

always @(posedge clk) begin
  if (enb) begin
    bram_rdt <= the_bram[adrb];
  end
end

always @(posedge clk) rdtb <= bram_rdt;

endmodule

