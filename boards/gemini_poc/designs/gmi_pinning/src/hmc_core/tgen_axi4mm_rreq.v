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
// File       : tgen_axi4mm_rreq.v
// Version    : 1.0  
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

module tgen_axi4mm_rreq
  #(parameter HMC_VER=1,							// HMC standard version; 1:Gen2; 2:Gen3
    parameter FLIT_W=128,							// HMC FLIT width (bits)
    parameter TGEN_REQ_NUM=8,						// Traffic-Gen # of request
    parameter AXI4_IF_DT_FLIT=8,					// AXI4MM DATA interface FLIT number
    parameter TGEN_MAX_DT_HLEN=4,					// Traffic-Gen maximum HLEN value
    parameter AXI4_UID_W=(HMC_VER==1) ? 9 : 11,		// AXI4MM User-ID width (bits)
    parameter AXI4_CMD_W=(HMC_VER==1) ? 6 : 7,		// AXI4MM CMD width (bits)
    parameter AXI4_AUSER_W=AXI4_CMD_W+3,			// AXI4MM AxUSER width: {CUB[2:0], CMD[n-1:0]}; n=6(gen2) or 7(gen3)
    parameter AXI4_RUSER_W=(HMC_VER==1) ? 18 : 20,	// AXI4MM RUSER width (bits)
                                                    //  - Gen2:{ageout, slid[2:0], errstat[6:0], dinv, cmd[5:0]};
                                                    //  - Gen3:{ageout, af, slid[2:0], errstat[6:0], dinv, cmd[6:0]}
    parameter AXI4_IF_DT_W=FLIT_W*AXI4_IF_DT_FLIT,			// AXI4MM DATA bus width (bits)
    parameter CSR_CMD_BUS_W=AXI4_AUSER_W+32,				// CSR command bus width (bits)
    parameter CSR_RDT_BUS_W=AXI4_IF_DT_W+AXI4_IF_DT_FLIT+1	// CSR data bus width (bits)
  ) (
    input                               clk,
    input                               rst,
    // CSR interface
    input                               req_cmd_push,
    input                               req_rdt_push,
    input           [CSR_CMD_BUS_W-1:0] req_cmd_in,
    input           [CSR_RDT_BUS_W-1:0] req_rdt_in,
    input                               tgen_clear,
    input                               tgen_start,
    output reg                          tgen_ch_addr_tx,
    output reg                          tgen_ch_resp_rx,
    output reg                          tgen_busy,
    output wire                         tgen_done,
    output wire                         tgen_pass,
    // AXI4-MM Read-Address channel
    output wire                         axi4mm_arvalid,		// ARVALID
    output reg         [AXI4_UID_W-1:0] axi4mm_arid,		// ARID
    output wire                [34-1:0] axi4mm_araddr,		// ARADDR
    output wire      [AXI4_AUSER_W-1:0] axi4mm_aruser,		// ARUSER
    input                               axi4mm_arready,		// ARREADY
    // AXI4-MM Read-Response channel
    input                               axi4mm_rvalid,		// RVALID
    input              [AXI4_UID_W-1:0] axi4mm_rid,			// RID
    input            [AXI4_RUSER_W-1:0] axi4mm_ruser,		// RUSER
    input            [AXI4_IF_DT_W-1:0] axi4mm_rdata,		// RDATA
    input                               axi4mm_rlast,		// RLAST
    input                       [2-1:0] axi4mm_rresp,		// RRESP
    output wire                         axi4mm_rready		// RREADY
  );

localparam TGEN_REQ_CNTR_W = clogb2(TGEN_REQ_NUM+1);
localparam TGEN_REQ_NUM_M1 = TGEN_REQ_NUM - 1;
localparam LOG2_TGEN_REQ_NUM = clogb2(TGEN_REQ_NUM);
localparam LOG2_TGEN_DT_HLEN = clogb2(TGEN_MAX_DT_HLEN);
localparam RUSER_CHK_MSK = (HMC_VER==1) ? {1'b1, 3'b0, 7'h7f, 1'b1, 6'h3f} : {1'b1, 1'b0, 3'b0, 7'h7f, 1'b1, 6'h3f};
localparam RUSER_CHK_VAL = (HMC_VER==1) ? {1'b0, 3'b0, 7'h00, 1'b0, 6'h38} : {1'b0, 1'b0, 3'b0, 7'h00, 1'b0, 6'h38};
localparam CMD_FIFO_WIDTH = CSR_CMD_BUS_W;
localparam CMD_FIFO_ADR_W = LOG2_TGEN_REQ_NUM;
localparam DAT_FIFO_WIDTH = CSR_RDT_BUS_W;
localparam DAT_FIFO_ADR_W = LOG2_TGEN_REQ_NUM+LOG2_TGEN_DT_HLEN;

localparam CMDFF_ADDR_BIT = 0;
localparam CMDFF_ADDR_LEN = 32;
localparam CMDFF_AUSR_BIT = CMDFF_ADDR_LEN;
localparam CMDFF_AUSR_LEN = AXI4_AUSER_W;
localparam RDTFF_DATA_BIT = 0;
localparam RDTFF_DATA_LEN = AXI4_IF_DT_W;
localparam RDTFF_STRB_BIT = AXI4_IF_DT_W;
localparam RDTFF_STRB_LEN = AXI4_IF_DT_FLIT;
localparam RDTFF_LAST_BIT = RDTFF_DATA_LEN+RDTFF_STRB_LEN;
localparam RDTFF_LAST_LEN = 1;

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

//------------------------------------------------------------------------------
// implementation
//------------------------------------------------------------------------------
reg                          tgen_reqad_wdw;
reg                          tgen_resp_wdw;
reg    [TGEN_REQ_CNTR_W-1:0] tgen_resp_cntr;
reg     [CMD_FIFO_ADR_W-1:0] rreq_adr_mem_wad;
reg     [CMD_FIFO_ADR_W-1:0] rreq_adr_mem_rad;
reg                    [1:0] rreq_adr_mem_re_d;
reg     [DAT_FIFO_ADR_W-1:0] rreq_dat_mem_wad;
reg     [DAT_FIFO_WIDTH-1:0] rreq_dat_mem_rdt_d;
reg                    [3:0] rreq_dat_mem_re_d;
reg                          axi4mm_ruser_chk_en;
reg                          axi4mm_rvalid_d;
reg         [AXI4_UID_W-1:0] axi4mm_rid_d;
reg       [AXI4_RUSER_W-1:0] axi4mm_ruser_d;
reg                    [1:0] axi4mm_rresp_d;
reg       [AXI4_IF_DT_W-1:0] axi4mm_rdata_d0;
reg       [AXI4_IF_DT_W-1:0] axi4mm_rdata_d1;
reg       [AXI4_IF_DT_W-1:0] axi4mm_rdata_d2;
reg                          axi4mm_rlast_d0;
reg                          axi4mm_rlast_d1;
reg                          axi4mm_rlast_d2;
reg       [TGEN_REQ_NUM-1:0] resp_rid_rxed;
reg                    [4:0] tgen_resp_rx_last_d;
reg                          tgen_resp_rdata_ok_r;
reg                          resp_chk_fail;

wire                         tgen_req_drv_en;
wire                         tgen_1st_req_sent;
wire                         tgen_resp_data_rx;
wire                         tgen_resp_data_dn;
wire                         tgen_resp_rx_last;
wire                         tgen_resp_rid_dup;
wire                         tgen_resp_ruser_ok;
reg                          tgen_resp_rdata_ok;
wire                         rreq_adr_mem_re;
wire    [CMD_FIFO_WIDTH-1:0] rreq_adr_mem_rdt;
wire                         rreq_dat_mem_re;
wire    [DAT_FIFO_ADR_W-1:0] rreq_dat_mem_rad;
wire    [DAT_FIFO_WIDTH-1:0] rreq_dat_mem_rdt;
wire                         pfch_rreq_adr_vld;
wire    [CMD_FIFO_WIDTH-1:0] pfch_rreq_adr_data;
wire                         pfch_rreq_adr_ack;
wire      [AXI4_IF_DT_W-1:0] axi4mm_rdata_exp;
wire   [AXI4_IF_DT_FLIT-1:0] axi4mm_rstrb_exp;
wire                         axi4mm_rlast_exp;
reg    [AXI4_IF_DT_FLIT-1:0] axi4mm_rdata_match;   

integer ii;

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
                       (tgen_reqad_wdw & ~(rreq_adr_mem_re & (rreq_adr_mem_rad == TGEN_REQ_NUM_M1))));

always @(posedge clk)
  if (rst)
    tgen_ch_addr_tx <= 1'b0;
  else
    tgen_ch_addr_tx <= axi4mm_arvalid & axi4mm_arready;

always @(posedge clk)
  if (rst)
    tgen_ch_resp_rx <= 1'b0;
  else
    tgen_ch_resp_rx <= axi4mm_rvalid & axi4mm_rready & axi4mm_rlast;

//------------------------------------------------------------------------------
// Request command FIFO control
//------------------------------------------------------------------------------
always @(posedge clk)
  if (rst)
    rreq_adr_mem_wad <= {CMD_FIFO_ADR_W{1'b0}};
  else
    rreq_adr_mem_wad <= (tgen_clear) ? {CMD_FIFO_ADR_W{1'b0}} :
                        (req_cmd_push) ? (rreq_adr_mem_wad + 1'b1) :
                                         rreq_adr_mem_wad;

always @(posedge clk)
  if (rst)
    rreq_adr_mem_rad <= {CMD_FIFO_ADR_W{1'b0}};
  else
    rreq_adr_mem_rad <= (tgen_clear) ? {CMD_FIFO_ADR_W{1'b0}} :
                        (rreq_adr_mem_re) ? (rreq_adr_mem_rad + 1'b1) :
                                            rreq_adr_mem_rad;

always @(posedge clk)
  if (rst)
    rreq_adr_mem_re_d <= 2'b0;
  else
    rreq_adr_mem_re_d <= {rreq_adr_mem_re_d, rreq_adr_mem_re};

tgen_rreq_dp_bram
  #(.RAM_WIDTH(CMD_FIFO_WIDTH),
    .RAM_AD_SZ(CMD_FIFO_ADR_W)
  ) u_addr_chn_bram (
    .clk		(clk),
    .ena		(req_cmd_push),
    .wea		(1'b1),
    .adra		(rreq_adr_mem_wad),
    .wdta		(req_cmd_in),
    .enb		(rreq_adr_mem_re),
    .adrb		(rreq_adr_mem_rad),
    .rdtb		(rreq_adr_mem_rdt) );

example_hmc_fifo_pfch_ctrl
  #(.FFDATA_W(CMD_FIFO_WIDTH),
    .PFCH_NUM(5)
  ) u_addr_pfch_ctrl (
    .clk			(clk),
    .rst			(rst),
    .fifo_empty		(~tgen_reqad_wdw),
    .fifo_di_rdy	(),
    .fifo_di_req	(rreq_adr_mem_re),
    .fifo_di_vld	(rreq_adr_mem_re_d[1]),
    .fifo_di_data	(rreq_adr_mem_rdt),
    .pfch_buf_full	(),
    .pfch_do_vld	(pfch_rreq_adr_vld),
    .pfch_do_data	(pfch_rreq_adr_data),
    .pfch_do_ack	(pfch_rreq_adr_ack) );

//------------------------------------------------------------------------------
// Response data FIFO control
//------------------------------------------------------------------------------
always @(posedge clk)
  if (rst)
    rreq_dat_mem_wad <= {DAT_FIFO_ADR_W{1'b0}};
  else
    rreq_dat_mem_wad <= (tgen_clear) ? {DAT_FIFO_ADR_W{1'b0}} :
                        (req_rdt_push) ? (rreq_dat_mem_wad + 1'b1) :
                                         rreq_dat_mem_wad;

assign rreq_dat_mem_re = tgen_resp_data_rx;

generate 
  if (LOG2_TGEN_DT_HLEN > 0) begin
    reg  [LOG2_TGEN_DT_HLEN-1:0] rreq_dat_mem_rad_idx;
    assign rreq_dat_mem_rad = {axi4mm_rid, rreq_dat_mem_rad_idx}; 
    
    always @(posedge clk)
      if (rst)
        rreq_dat_mem_rad_idx <= {DAT_FIFO_ADR_W{1'b0}};
      else
        rreq_dat_mem_rad_idx <= (tgen_clear | tgen_resp_data_dn) ? {DAT_FIFO_ADR_W{1'b0}} :
                                (rreq_dat_mem_re) ? (rreq_dat_mem_rad_idx + 1'b1) :
                                                     rreq_dat_mem_rad_idx;
  end else begin
    assign rreq_dat_mem_rad = axi4mm_rid;
  end 
endgenerate 

tgen_rreq_dp_bram
  #(.RAM_WIDTH(DAT_FIFO_WIDTH),
    .RAM_AD_SZ(DAT_FIFO_ADR_W)
  ) u_data_chn_bram (
    .clk		(clk),
    .ena		(req_rdt_push),
    .wea		(1'b1),
    .adra		(rreq_dat_mem_wad),
    .wdta		(req_rdt_in),
    .enb		(rreq_dat_mem_re),
    .adrb		(rreq_dat_mem_rad),
    .rdtb		(rreq_dat_mem_rdt) );

always @(posedge clk)
  if (rst)
    rreq_dat_mem_re_d <= 4'b0;
  else
    rreq_dat_mem_re_d <= {rreq_dat_mem_re_d, rreq_dat_mem_re};

always @(posedge clk)
  if (rst)
    rreq_dat_mem_rdt_d <= {DAT_FIFO_WIDTH{1'b0}};
  else
    rreq_dat_mem_rdt_d <= rreq_dat_mem_rdt;

assign axi4mm_rdata_exp = rreq_dat_mem_rdt[RDTFF_DATA_BIT+:RDTFF_DATA_LEN];
assign axi4mm_rstrb_exp = rreq_dat_mem_rdt_d[RDTFF_STRB_BIT+:RDTFF_STRB_LEN];
assign axi4mm_rlast_exp = rreq_dat_mem_rdt_d[RDTFF_LAST_BIT+:RDTFF_LAST_LEN];

//------------------------------------------------------------------------------
// Response check
//------------------------------------------------------------------------------
assign tgen_1st_req_sent = tgen_reqad_wdw & axi4mm_arvalid & axi4mm_arready & ~tgen_resp_wdw;
assign tgen_resp_data_rx = tgen_resp_wdw & axi4mm_rvalid & axi4mm_rready;
assign tgen_resp_data_dn = tgen_resp_data_rx & axi4mm_rlast;
assign tgen_resp_rx_last = tgen_resp_data_dn & (~|tgen_resp_cntr[TGEN_REQ_CNTR_W-1:1]);

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
                      (tgen_resp_data_dn) ? (tgen_resp_cntr - 1'b1) :
                                            tgen_resp_cntr;

always @(posedge clk)
  if (rst)
    axi4mm_ruser_chk_en <= 1'b0;
  else
    axi4mm_ruser_chk_en <= tgen_1st_req_sent |
                           (tgen_resp_data_dn & (|tgen_resp_cntr[TGEN_REQ_CNTR_W-1:1])) |
                           (axi4mm_ruser_chk_en & ~tgen_resp_data_dn);

always @(posedge clk)
  if (rst)
    axi4mm_rvalid_d <= 1'b0;
  else
    axi4mm_rvalid_d <= tgen_resp_data_rx;

always @(posedge clk)
  if (rst) begin
    axi4mm_rid_d <= {AXI4_UID_W{1'b0}};
    axi4mm_ruser_d <= {AXI4_RUSER_W{1'b0}};
    axi4mm_rresp_d <= 2'b0;
    axi4mm_rdata_d0 <= {AXI4_IF_DT_W{1'b0}};
    axi4mm_rlast_d0 <= 1'b0;
    axi4mm_rdata_d1 <= {AXI4_IF_DT_W{1'b0}};
    axi4mm_rlast_d1 <= 1'b0;
    axi4mm_rdata_d2 <= {AXI4_IF_DT_W{1'b0}};
    axi4mm_rlast_d2 <= 1'b0;
  end
  else begin
    axi4mm_rid_d <= axi4mm_rid;
    axi4mm_ruser_d <= axi4mm_ruser;
    axi4mm_rresp_d <= axi4mm_rresp;
    axi4mm_rdata_d0 <= axi4mm_rdata;
    axi4mm_rlast_d0 <= axi4mm_rlast;
    axi4mm_rdata_d1 <= axi4mm_rdata_d0;
    axi4mm_rlast_d1 <= axi4mm_rlast_d0;
    axi4mm_rdata_d2 <= axi4mm_rdata_d1;
    axi4mm_rlast_d2 <= axi4mm_rlast_d1;
  end

always @(posedge clk)
  if (rst)
    resp_rid_rxed <= {TGEN_REQ_NUM{1'b0}};
  else if (tgen_clear)
    resp_rid_rxed <= {TGEN_REQ_NUM{1'b0}};
  else if (axi4mm_ruser_chk_en & axi4mm_rvalid_d & axi4mm_rlast_d0)
    resp_rid_rxed <= resp_rid_rxed | ({{TGEN_REQ_NUM-1{1'b0}}, 1'b1} << axi4mm_rid_d);

assign tgen_resp_rid_dup = resp_rid_rxed[axi4mm_rid_d[LOG2_TGEN_REQ_NUM-1:0]];

assign tgen_resp_ruser_ok = (axi4mm_rresp_d == 2'b00) &
                            ((axi4mm_ruser_d & RUSER_CHK_MSK) == RUSER_CHK_VAL);

always @* begin
  tgen_resp_rdata_ok = (axi4mm_rlast_d2 == axi4mm_rlast_exp);
  for (ii=0; ii<AXI4_IF_DT_FLIT; ii=ii+1)
    tgen_resp_rdata_ok = tgen_resp_rdata_ok &
                         (~axi4mm_rstrb_exp[ii] | axi4mm_rdata_match[ii] );
end

always @(posedge clk)
    if (rst)
        axi4mm_rdata_match <= {AXI4_IF_DT_FLIT{1'b0}};
     else 
       for (ii=0; ii<AXI4_IF_DT_FLIT; ii=ii+1)
         axi4mm_rdata_match[ii] = (axi4mm_rdata_d1[FLIT_W*ii+:FLIT_W] == axi4mm_rdata_exp[FLIT_W*ii+:FLIT_W]);



always @(posedge clk)
  if (rst)
    tgen_resp_rdata_ok_r <= 1'b0;
  else
    tgen_resp_rdata_ok_r <= tgen_resp_rdata_ok;

always @(posedge clk)
  if (rst)
    resp_chk_fail <= 1'b0;
  else
    resp_chk_fail <= ~tgen_clear &
                     ~tgen_req_drv_en &
                     (resp_chk_fail |
                      (axi4mm_ruser_chk_en & axi4mm_rvalid_d & (tgen_resp_rid_dup | ~tgen_resp_ruser_ok)) |
                      (rreq_dat_mem_re_d[3] & ~tgen_resp_rdata_ok_r));

always @(posedge clk)
  if (rst)
    tgen_resp_rx_last_d <= 5'b0;
  else
    tgen_resp_rx_last_d <= {tgen_resp_rx_last_d, tgen_resp_rx_last};

always @(posedge clk)
  if (rst)
    tgen_busy <= 1'b0;
  else
    tgen_busy <= ~tgen_clear & (tgen_req_drv_en | (tgen_busy & ~tgen_resp_rx_last_d[4]));

assign tgen_done = tgen_resp_rx_last_d[4];

assign tgen_pass = ~resp_chk_fail;

//------------------------------------------------------------------------------
// AXI4 interface control
//------------------------------------------------------------------------------
assign axi4mm_arvalid = pfch_rreq_adr_vld;

always @(posedge clk)
  if (rst)
    axi4mm_arid <= {AXI4_UID_W{1'b0}};
  else
    axi4mm_arid <= (tgen_clear) ? {AXI4_UID_W{1'b0}} :
                   (axi4mm_arvalid & axi4mm_arready) ? (axi4mm_arid + 1'b1) :
                                                       axi4mm_arid;

assign axi4mm_araddr = {2'b0, pfch_rreq_adr_data[CMDFF_ADDR_BIT+:CMDFF_ADDR_LEN]};
assign axi4mm_aruser = pfch_rreq_adr_data[CMDFF_AUSR_BIT+:CMDFF_AUSR_LEN];

assign pfch_rreq_adr_ack = axi4mm_arready;

assign axi4mm_rready = tgen_resp_wdw;

endmodule


//==============================================================================
// Simple Dual-Ports BRAM
//==============================================================================
module tgen_rreq_dp_bram
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

