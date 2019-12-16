/******************************************************************************
// (c) Copyright 2016 Xilinx, Inc. All rights reserved.
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
******************************************************************************/
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor             : Xilinx
// \   \   \/     Version            : 1.0
//  \   \         Application        : MIG
//  /   /         Filename           : ddr4_v2_2_3_data_chk.sv
// /___/   /\     Date Last Modified : $Date: 2014/09/03 $
// \   \  /  \    Date Created       : Wed Jan 13 2016
//  \___\/\___\
//
//Device: UltraScale
//Design Name: AXI TG
//Purpose:
//  This module compares the read data with the expected data and throws out an error in case of mismatch
//  The expected data is generated by the data_gen block. 
//Reference:
//Revision History:
//*****************************************************************************
`timescale 1ps/1ps 
module ddr4_v2_2_3_data_chk # (
   parameter C_AXI_ID_WIDTH           = 10,
   parameter C_AXI_ADDR_WIDTH         = 32, 
   parameter C_AXI_DATA_WIDTH         = 32,
   parameter C_DATA_PATTERN_PRBS      = 3'd1,
   parameter C_DATA_PATTERN_WALKING0  = 3'd2,
   parameter C_DATA_PATTERN_WALKING1  = 3'd3,
   parameter C_DATA_PATTERN_ALL_F     = 3'd4,
   parameter C_DATA_PATTERN_ALL_0     = 3'd5,
   parameter C_DATA_PATTERN_A5A5      = 3'd6,
   parameter C_STRB_PATTERN_DEFAULT   = 3'd1,
   parameter C_STRB_PATTERN_WALKING1  = 3'd2,
   parameter C_STRB_PATTERN_WALKING0  = 3'd3,
   parameter TCQ                      = 100
  ) 
  (
   input                             tg_rst,
   input                             clk,
   input                             data_en,
   input [2:0]                       data_pattern,
   input                             pattern_init,    // when high the patterns are initialized
   input [C_AXI_ID_WIDTH -1:0]       prbs_seed_i,
   input [2:0]                       strb_pattern,
   input [2:0]                       size_in,
   input                             last,
   input [6:0]                       start_addr,   
   input                             compare_wr_rd,
   input                             compare_bg,
   input [C_AXI_DATA_WIDTH-1:0]      rdata,
   input                             rdata_vld,
   output reg                        mismatch_err,     // Indicates there is a mismatch error
   output reg [C_AXI_DATA_WIDTH-1:0] expected_data,    //when mismatche_err is asserted, this signal shows the expected data
   output reg [C_AXI_DATA_WIDTH-1:0] actual_data,
   output reg [C_AXI_DATA_WIDTH-1:0] error_bits,
   output reg [8:0]                  data_beat_count
  );

wire [C_AXI_DATA_WIDTH-1:0]      data_o_pri; //primary predicted data
wire [C_AXI_DATA_WIDTH-1:0]      data_o_bg; //background predicted data 
wire [C_AXI_DATA_WIDTH/8-1:0]    wstrb_out_pri; //primary predicted strb
wire [C_AXI_DATA_WIDTH/8-1:0]    wstrb_out_bg; //primary predicted strb
reg  [C_AXI_DATA_WIDTH-1:0]      data_o_pri_r; 
reg  [C_AXI_DATA_WIDTH-1:0]      data_o_bg_r; 
reg  [C_AXI_DATA_WIDTH/8-1:0]    wstrb_out_pri_r; 
reg  [C_AXI_DATA_WIDTH/8-1:0]    wstrb_out_bg_r; 
reg                              compare_bg_r,compare_bg_2r,compare_bg_3r,compare_bg_4r; 
wire [C_AXI_DATA_WIDTH -1 :0]    wstrb_out_pri_full;
wire [C_AXI_DATA_WIDTH -1 :0]    wstrb_out_bg_full;
reg  [C_AXI_DATA_WIDTH-1:0]      rdata_r; 
reg                              rdata_vld_r,rdata_vld_2r,rdata_vld_3r,rdata_vld_4r;
reg                              compare_wr_rd_r,compare_wr_rd_2r,compare_wr_rd_3r,compare_wr_rd_4r;
//data predictor 
ddr4_v2_2_3_data_gen # (
  .C_AXI_ID_WIDTH(C_AXI_ID_WIDTH),
  .C_AXI_ADDR_WIDTH(C_AXI_ADDR_WIDTH),
  .C_AXI_DATA_WIDTH(C_AXI_DATA_WIDTH),
  .C_DATA_PATTERN_PRBS(C_DATA_PATTERN_PRBS),
  .C_DATA_PATTERN_WALKING0(C_DATA_PATTERN_WALKING0),
  .C_DATA_PATTERN_WALKING1(C_DATA_PATTERN_WALKING1),
  .C_DATA_PATTERN_ALL_F(C_DATA_PATTERN_ALL_F),
  .C_DATA_PATTERN_ALL_0(C_DATA_PATTERN_ALL_0),
  .C_DATA_PATTERN_A5A5(C_DATA_PATTERN_A5A5),
  .C_STRB_PATTERN_DEFAULT(C_STRB_PATTERN_DEFAULT),
  .C_STRB_PATTERN_WALKING1(C_STRB_PATTERN_WALKING1),
  .C_STRB_PATTERN_WALKING0(C_STRB_PATTERN_WALKING0),
  .TCQ(TCQ)
  )u_data_gen
  (
    .tg_rst(tg_rst),
    .clk(clk),
    .data_en(data_en),
    .data_pattern(data_pattern),
    .pattern_init(pattern_init),
    .prbs_seed_i(prbs_seed_i),
    .strb_pattern(strb_pattern),
    .size_in(size_in),
    .last(last),
    .start_addr(start_addr),
    .data_out(data_o_pri),
    .wstrb_out(wstrb_out_pri),
    .wstrb_out_default(wstrb_out_bg)
  );

assign data_o_bg = {C_AXI_DATA_WIDTH/32{32'h5A5A_A5A5}}; //background pattern

//registering the generator outputs and the read data from the axi wrapper
always @ (posedge clk)begin
  data_o_pri_r <= #TCQ data_o_pri;
  wstrb_out_pri_r <= #TCQ wstrb_out_pri;
  data_o_bg_r <= #TCQ data_o_bg;
  wstrb_out_bg_r <= #TCQ wstrb_out_bg;
  compare_bg_r <= #TCQ compare_bg;
  compare_bg_2r <= #TCQ compare_bg_r;
  compare_bg_3r <= #TCQ compare_bg_2r;
  compare_bg_4r <= #TCQ compare_bg_3r;
  rdata_r <= #TCQ rdata;
  rdata_vld_r <= #TCQ rdata_vld;
  rdata_vld_2r <= #TCQ rdata_vld_r;
  rdata_vld_3r <= #TCQ rdata_vld_2r;
  rdata_vld_4r <= #TCQ rdata_vld_3r;
  compare_wr_rd_r <= #TCQ compare_wr_rd;
  compare_wr_rd_2r <= #TCQ compare_wr_rd_r;
  compare_wr_rd_3r <= #TCQ compare_wr_rd_2r;
  compare_wr_rd_4r <= #TCQ compare_wr_rd_3r;
end

//counter to keep track of which read data beat we are handling
always @(posedge clk) begin
  if(pattern_init)begin
    data_beat_count <= #TCQ 0;
  end
  else if(rdata_vld_4r)begin
    data_beat_count <= #TCQ data_beat_count + 1'b1;;
  end  
end

//expanding wstrb eg: 0001 -> 00000000_00000000_00000000_11111111
genvar i;
generate 
for(i=0;i<C_AXI_DATA_WIDTH;i++)begin
  assign wstrb_out_pri_full[i]=wstrb_out_pri_r[i/8];
  assign wstrb_out_bg_full[i]=wstrb_out_bg_r[i/8];
end  
endgenerate

reg [C_AXI_DATA_WIDTH-1:0] expected_data_pri; 
reg [C_AXI_DATA_WIDTH-1:0] expected_data_bg; 
reg [C_AXI_DATA_WIDTH-1:0] actual_data_pri; 
reg [C_AXI_DATA_WIDTH-1:0] actual_data_bg; 
reg [C_AXI_DATA_WIDTH -1 :0]    mismatch_pri;
reg [C_AXI_DATA_WIDTH -1 :0]    mismatch_bg;
reg                             mismatch;

always @(posedge clk) begin
  expected_data_pri <= #TCQ (data_o_pri_r  & wstrb_out_pri_full);
  actual_data_pri <= #TCQ (rdata_r & wstrb_out_pri_full);
  expected_data_bg <= #TCQ (data_o_bg_r  & (wstrb_out_bg_full ^ wstrb_out_pri_full));
  actual_data_bg <= #TCQ (rdata_r & (wstrb_out_bg_full ^ wstrb_out_pri_full));
  mismatch_pri <= #TCQ expected_data_pri^actual_data_pri;
  mismatch_bg <= #TCQ expected_data_bg^actual_data_bg;
  mismatch <= #TCQ (compare_bg_r)? (|(mismatch_pri | mismatch_bg)) : (|mismatch_pri);
end

reg [C_AXI_DATA_WIDTH-1:0] expected_data_pri_r; 
reg [C_AXI_DATA_WIDTH-1:0] expected_data_bg_r; 
reg [C_AXI_DATA_WIDTH-1:0] actual_data_pri_r; 
reg [C_AXI_DATA_WIDTH-1:0] actual_data_bg_r; 
reg [C_AXI_DATA_WIDTH-1:0] expected_data_pri_2r; 
reg [C_AXI_DATA_WIDTH-1:0] expected_data_bg_2r; 
reg [C_AXI_DATA_WIDTH-1:0] actual_data_pri_2r; 
reg [C_AXI_DATA_WIDTH-1:0] actual_data_bg_2r; 
reg [C_AXI_DATA_WIDTH -1 :0]    mismatch_pri_r;
reg [C_AXI_DATA_WIDTH -1 :0]    mismatch_bg_r;

always @(posedge clk) begin //registering to ensure timing meets.
  expected_data_pri_r <= #TCQ expected_data_pri; 
  expected_data_bg_r <= #TCQ expected_data_bg; 
  actual_data_pri_r <= #TCQ actual_data_pri; 
  actual_data_bg_r <= #TCQ actual_data_bg;   
  expected_data_pri_2r <= #TCQ expected_data_pri_r; 
  expected_data_bg_2r <= #TCQ expected_data_bg_r; 
  actual_data_pri_2r <= #TCQ actual_data_pri_r; 
  actual_data_bg_2r <= #TCQ actual_data_bg_r;  
  mismatch_pri_r <= #TCQ mismatch_pri;
  mismatch_bg_r <= #TCQ mismatch_bg;
end

always @(posedge clk)begin
  if(tg_rst)begin
    mismatch_err  <= #TCQ 0;
    expected_data <= #TCQ 0;
    actual_data   <= #TCQ 0;
    error_bits    <= #TCQ 0;
  end
  else if (rdata_vld_4r && mismatch && compare_wr_rd_4r && !compare_bg_4r)begin
    mismatch_err  <= #TCQ 1;
    expected_data <= #TCQ expected_data_pri_2r;
    actual_data   <= #TCQ actual_data_pri_2r;
    error_bits    <= #TCQ mismatch_pri_r;
  end
  else if (rdata_vld_4r && mismatch && compare_wr_rd_4r && compare_bg_4r)begin
    mismatch_err  <= #TCQ 1;
    expected_data <= #TCQ expected_data_pri_2r | expected_data_bg_2r;
    actual_data   <= #TCQ actual_data_pri_2r | actual_data_bg_2r;
    error_bits    <= #TCQ mismatch_pri_r | mismatch_bg_r;
  end
  else begin
    mismatch_err<= #TCQ 0;
    expected_data <= #TCQ expected_data;
    actual_data   <= #TCQ actual_data;
    error_bits    <= #TCQ error_bits;
  end  
end

//synthesis translate off
always @ (posedge clk)begin
  if(mismatch_err)begin
    $display("ERROR:::at %t Read data and Expected data are not matching",$time);
    $display("Read data=%h",actual_data);
    $display("error bits=%h",error_bits);
    $display("Expected data=%h",expected_data);
  end  
end
//synthesis translate on
endmodule
