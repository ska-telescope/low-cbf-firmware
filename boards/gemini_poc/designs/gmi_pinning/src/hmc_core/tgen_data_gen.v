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
// File       : tgen_data_gen.v
// Version    : 1.0  
//-----------------------------------------------------------------------------
`timescale 1ns/1ps

module tgen_data_gen
  #(parameter HMC_VER=1,							// HMC standard version; 1:Gen2; 2:Gen3
    parameter FLIT_W=128,							// HMC FLIT width (bits)
    parameter TGEN_REQ_NUM=8,						// Traffic-Generator # of requests
    parameter DEV_CUB_ID=3'b000,					// HMC device CUB-ID
    parameter AXI4_IF_DT_FLIT=8,					// AXI4MM DATA interface FLIT number
    parameter AXI4_DT_CHNNL_ALIGN=1,				// AXI4MM DATA channel is always aligned to bit-0
    parameter TGEN_MAX_DT_HLEN=4,					// Traffic-Gen maximum HLEN value
    parameter AXI4_CMD_W=(HMC_VER==1) ? 6 : 7,		// AXI4MM CMD width (bits)
    parameter AXI4_AUSER_W=AXI4_CMD_W+3,			// AXI4MM AxUSER width: {CUB[2:0], CMD[n-1:0]}; n=6(gen2) or 7(gen3)
    parameter AXI4_IF_DT_W=FLIT_W*AXI4_IF_DT_FLIT,
    parameter CSR_WCMD_BUS_W=AXI4_AUSER_W+32+8,
    parameter CSR_RCMD_BUS_W=AXI4_AUSER_W+32,
    parameter CSR_DATA_BUS_W=AXI4_IF_DT_W+AXI4_IF_DT_FLIT+1
  ) (
    input                               clk,
    input                               rst,
    // FSM Interface
    input                               fsm_dtgen_en,
    output reg                          fsm_dtgen_dn,
    // AXI4-MM Control Interface
    output reg                          req_wcmd_push,
    output wire                         req_rcmd_push,
    output reg                          req_wdt_push,
    output reg                          req_rdt_push,
    output reg     [CSR_WCMD_BUS_W-1:0] req_wcmd_bus,
    output reg     [CSR_RCMD_BUS_W-1:0] req_rcmd_bus,
    output wire    [CSR_DATA_BUS_W-1:0] req_wdt_bus,
    output wire    [CSR_DATA_BUS_W-1:0] req_rdt_bus
  );

localparam FLIT_DWD_CNT = FLIT_W/32;
localparam LOG2_AXI4_IF_FLIT = clogb2(AXI4_IF_DT_FLIT);
localparam PWR2_MAX_DT_HLEN = 2**(clogb2(TGEN_MAX_DT_HLEN));
localparam MAX_DT_FLIT_NUM = AXI4_IF_DT_FLIT*PWR2_MAX_DT_HLEN;

//------------------------------------------------------------------------------
// reg/wire declaration
//------------------------------------------------------------------------------
reg        [TGEN_REQ_NUM-1:0] dtgen_pkt_vec;
reg    [PWR2_MAX_DT_HLEN-1:0] dtgen_pkt_hlen_vec;
reg    [PWR2_MAX_DT_HLEN-1:0] dtgen_pkt_wdt_last;
reg                           req_cmd_push_en;
reg     [MAX_DT_FLIT_NUM-1:0] dtgen_pkt_strb_vec;
reg                    [30:0] rand_addr_poly_r;
reg                    [31:0] rand_addr_num_r;
reg                    [31:0] rand_addr_num_d1;
reg                    [31:0] rand_addr_num_d2;
reg                    [30:0] rand_ctrl_poly_r;
reg                    [31:0] rand_ctrl_num_r;
reg                     [3:0] rand_data_cmdlen_pre;
reg     [MAX_DT_FLIT_NUM-1:0] rand_data_strb_pre;
reg                     [5:0] rand_data_tot_flit;
reg                     [3:0] rand_data_cmdlen;
reg     [MAX_DT_FLIT_NUM-1:0] rand_data_strb;
reg                     [7:0] rand_data_hlen;

wire                          dtgen_start;
wire                          dtgen_pkt_dn;
wire                          dtgen_finish;
wire                          new_req_cmd_en;
wire                          dtgen_wreq_pkt_dn;
wire                          dtgen_rreq_pkt_dn;
wire       [AXI4_IF_DT_W-1:0] dtgen_random_data;
reg        [AXI4_IF_DT_W-1:0] dtgen_data_mask;
wire                   [30:0] rand_addr_poly_w;
wire                   [31:0] rand_addr_num_w;
wire                   [30:0] rand_ctrl_poly_w;
wire                   [31:0] rand_ctrl_num_w;
wire  [LOG2_AXI4_IF_FLIT-1:0] rand_data_ofst_p1;
wire  [LOG2_AXI4_IF_FLIT-1:0] rand_data_ofst_p0;
wire  [LOG2_AXI4_IF_FLIT-1:0] rand_data_ofst;
wire                    [4:0] rand_data_len_real;

integer ii;
genvar gi;

//------------------------------------------------------------------------------
// Data generation control
//------------------------------------------------------------------------------
assign dtgen_start = fsm_dtgen_en;
assign dtgen_pkt_dn = dtgen_rreq_pkt_dn;

always @(posedge clk)
  if (rst)
    dtgen_pkt_vec <= {TGEN_REQ_NUM{1'b0}};
  else if (dtgen_start)
    dtgen_pkt_vec <= {{TGEN_REQ_NUM-1{1'b0}}, 1'b1};
  else if (dtgen_pkt_dn)
    dtgen_pkt_vec <= {dtgen_pkt_vec, 1'b0};

assign dtgen_finish = dtgen_pkt_dn & dtgen_pkt_vec[TGEN_REQ_NUM-1];

assign new_req_cmd_en = dtgen_start | (dtgen_pkt_dn & ~dtgen_finish);

always @(posedge clk)
  if (rst)
    req_cmd_push_en <= 1'b0;
  else
    req_cmd_push_en <= new_req_cmd_en;

always @(posedge clk)
  if (rst)
    dtgen_pkt_hlen_vec <= {PWR2_MAX_DT_HLEN{1'b0}};
  else if (req_cmd_push_en)
    dtgen_pkt_hlen_vec <= {{PWR2_MAX_DT_HLEN{1'b0}}, 1'b1};
  else
    dtgen_pkt_hlen_vec <= {dtgen_pkt_hlen_vec, 1'b0};

always @(posedge clk)
  if (rst)
    fsm_dtgen_dn <= 1'b0;
  else
    fsm_dtgen_dn <= dtgen_finish;

//------------------------------------------------------------------------------
// WR-Request generation
//------------------------------------------------------------------------------
always @(posedge clk)
  if (rst)
    dtgen_pkt_wdt_last <= {PWR2_MAX_DT_HLEN{1'b0}};
  else if (req_cmd_push_en)
    dtgen_pkt_wdt_last <= ({{PWR2_MAX_DT_HLEN{1'b0}}, 1'b1} << rand_data_hlen);

assign dtgen_wreq_pkt_dn = |(dtgen_pkt_hlen_vec & dtgen_pkt_wdt_last);

always @(posedge clk)
  if (rst)
    req_wcmd_push <= 1'b0;
  else
    req_wcmd_push <= req_cmd_push_en;

always @(posedge clk)
  if (rst)
    req_wdt_push <= 1'b0;
  else
    req_wdt_push <= req_cmd_push_en | (req_wdt_push & ~dtgen_wreq_pkt_dn);

always @(posedge clk)
  if (rst)
    req_wcmd_bus <= {CSR_WCMD_BUS_W{1'b0}};
  else if (HMC_VER == 1)
    req_wcmd_bus <= {rand_data_hlen, DEV_CUB_ID, 3'b001, rand_data_cmdlen[2:0], rand_addr_num_d2};

always @(posedge clk)
  if (rst)
    dtgen_pkt_strb_vec <= {MAX_DT_FLIT_NUM{1'b0}};
  else if (req_cmd_push_en)
    dtgen_pkt_strb_vec <= rand_data_strb;
  else
    dtgen_pkt_strb_vec <= (dtgen_pkt_strb_vec >> AXI4_IF_DT_FLIT);

always @* begin
  for (ii=0; ii<AXI4_IF_DT_FLIT; ii=ii+1)
    dtgen_data_mask[FLIT_W*ii+:FLIT_W] = {FLIT_W{dtgen_pkt_strb_vec[ii]}} & dtgen_random_data[FLIT_W*ii+:FLIT_W];
end

assign req_wdt_bus = {dtgen_wreq_pkt_dn, dtgen_pkt_strb_vec[AXI4_IF_DT_FLIT-1:0], dtgen_data_mask};

//------------------------------------------------------------------------------
// RD-Request data generation
//------------------------------------------------------------------------------
assign dtgen_rreq_pkt_dn = dtgen_pkt_hlen_vec[PWR2_MAX_DT_HLEN-1];

assign req_rcmd_push = req_wcmd_push;

always @(posedge clk)
  if (rst)
    req_rcmd_bus <= {CSR_RCMD_BUS_W{1'b0}};
  else if (HMC_VER == 1)
    req_rcmd_bus <= {DEV_CUB_ID, 3'b110, rand_data_cmdlen[2:0], rand_addr_num_d2};

always @(posedge clk)
  if (rst)
    req_rdt_push <= 1'b0;
  else
    req_rdt_push <= req_cmd_push_en | (req_rdt_push & ~dtgen_rreq_pkt_dn);

assign req_rdt_bus = req_wdt_bus;

//------------------------------------------------------------------------------
// Random data generator
//------------------------------------------------------------------------------
// Address
example_hmc_lfsr
#(.DATA_WIDTH(32),
  .PRBS_SIZE(31),
  .PRBS_POLY(31'b1000000_00000000_00000000_00001001)
) u_addr_lfsr (
  .lfsr_in	(rand_addr_poly_r),
  .lfsr_out	(rand_addr_poly_w),
  .prbs_out	(rand_addr_num_w) );

always @(posedge clk)
  if (rst) begin
    rand_addr_poly_r <= 31'h8_3c3c;
    rand_addr_num_r <= 32'b0;
  end
  else begin
    rand_addr_poly_r <= rand_addr_poly_w;
    rand_addr_num_r <= rand_addr_num_w & {{32-LOG2_AXI4_IF_FLIT-4{1'b1}}, {LOG2_AXI4_IF_FLIT{(AXI4_DT_CHNNL_ALIGN != 1)}}, 4'b0};
  end

always @(posedge clk)
  if (rst) begin
    rand_addr_num_d1 <= 32'b0;
    rand_addr_num_d2 <= 32'b0;
  end
  else begin
    rand_addr_num_d1 <= rand_addr_num_r;
    rand_addr_num_d2 <= rand_addr_num_d1;
  end

assign rand_data_ofst_p1 = rand_addr_num_r[4+:LOG2_AXI4_IF_FLIT];
assign rand_data_ofst_p0 = rand_addr_num_d1[4+:LOG2_AXI4_IF_FLIT];
assign rand_data_ofst    = rand_addr_num_d2[4+:LOG2_AXI4_IF_FLIT];

// Data length information
example_hmc_lfsr
#(.DATA_WIDTH(32),
  .PRBS_SIZE(31),
  .PRBS_POLY(31'b1000000_00000000_00000000_00001001)
) u_ctrl_lfsr (
  .lfsr_in	(rand_ctrl_poly_r),
  .lfsr_out	(rand_ctrl_poly_w),
  .prbs_out	(rand_ctrl_num_w) );

always @(posedge clk)
  if (rst) begin
    rand_ctrl_poly_r <= 31'h7_55aa;
    rand_ctrl_num_r <= 32'b0;
  end
  else begin
    rand_ctrl_poly_r <= rand_ctrl_poly_w;
    rand_ctrl_num_r <= rand_ctrl_num_w;
  end

assign rand_data_len_real = (~|rand_ctrl_num_r[2:0]) ? 5'd1 :
                            (HMC_VER == 1) ? {1'b0, ((rand_ctrl_num_r[3]) ? 4'd8 : {1'b0, rand_ctrl_num_r[2:0]})} : 
                                             ((rand_ctrl_num_r[4]) ? 5'd16 :
                                              (rand_ctrl_num_r[3]) ? 5'd8 :
                                                                     {2'b0, rand_ctrl_num_r[2:0]});

always @(posedge clk)
  if (rst) begin
    rand_data_cmdlen_pre <= 4'b0;
    rand_data_strb_pre <= {MAX_DT_FLIT_NUM{1'b0}};
    rand_data_tot_flit <= 6'b0;
  end
  else begin
    rand_data_cmdlen_pre <= (rand_data_len_real - 1'b1);
    rand_data_strb_pre <= ({MAX_DT_FLIT_NUM{1'b1}} << rand_data_len_real);
    rand_data_tot_flit <= {1'b0, rand_data_len_real} + rand_data_ofst_p1;
  end

always @(posedge clk)
  if (rst) begin
    rand_data_cmdlen <= 4'b0;
    rand_data_strb <= {MAX_DT_FLIT_NUM{1'b0}};
    rand_data_hlen <= 8'b0;
  end
  else begin
    rand_data_cmdlen <= rand_data_cmdlen_pre;
    rand_data_strb <= ~rand_data_strb_pre << rand_data_ofst_p0;
    rand_data_hlen <= (|rand_data_tot_flit[LOG2_AXI4_IF_FLIT-1:0]) ?
                        {8'b0, rand_data_tot_flit[5:LOG2_AXI4_IF_FLIT]} :
                        ({8'b0, rand_data_tot_flit[5:LOG2_AXI4_IF_FLIT]} - 1'b1);
  end

// Payload content
generate for (gi=0; gi<(FLIT_DWD_CNT*AXI4_IF_DT_FLIT); gi=gi+1) begin
  reg  [31:0] the_rand_num_r;
  reg  [30:0] the_rand_poly_r;
  wire [31:0] the_rand_num_w;
  wire [30:0] the_rand_poly_w;

  example_hmc_lfsr
  #(.DATA_WIDTH(32),
    .PRBS_SIZE(31),
    .PRBS_POLY(31'b1000000_00000000_00000000_00001001)
  ) u_data_lfsr (
    .lfsr_in	(the_rand_poly_r),
    .lfsr_out	(the_rand_poly_w),
    .prbs_out	(the_rand_num_w) );

  always @(posedge clk)
    if (rst) begin
      the_rand_num_r <= 32'b0;
      the_rand_poly_r <= 31'h1_2345+gi;
    end
    else begin
      the_rand_num_r <= the_rand_num_w;
      the_rand_poly_r <= the_rand_poly_w;
    end

  assign dtgen_random_data[32*gi+:32] = the_rand_num_r;
end
endgenerate

//------------------------------------------------------------------------------
// Functions
//------------------------------------------------------------------------------
function integer clogb2;
  input integer value;
  begin
    value = value - 1;
    for (clogb2=0; value>0; clogb2=clogb2+1) value = value >> 1;
  end
endfunction

endmodule

