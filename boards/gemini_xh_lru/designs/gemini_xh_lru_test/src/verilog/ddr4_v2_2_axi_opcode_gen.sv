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
//  /   /         Filename           : ddr4_v2_2_3_axi_opcode_gen.sv
// /___/   /\     Date Last Modified : $Date: 2014/09/03 $
// \   \  /  \    Date Created       : Wed Jan 13 2016
//  \___\/\___\
//
//Device: UltraScale
//Design Name: AXI TG
//Purpose:
//   This block converts the higher level instructions from the boot/prbs/custom modules to axi level opcodes(which are later handled by axi_wrapper)
//   higher level instructions are converted to write and read opcodes
//Reference:
//Revision History:
//*****************************************************************************
`timescale 1ps/1ps 
module ddr4_v2_2_3_axi_opcode_gen #(
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
  parameter APP_DATA_WIDTH	     = 32, 
  parameter C_AXI_NBURST_SUPPORT     = 0,	
  parameter SEND_NBURST              = 0,
  parameter TCQ                      = 100,
  parameter ECC			     = "OFF"	 
)(
  input                                  clk,
  input                                  tg_rst,
  input                                  opcode_gen_start,
  output                                 opcode_gen_done,
  input [C_AXI_ADDR_WIDTH -1:0]          instr_axi_addr,
  input [7:0]                            instr_axi_length,
  input [2:0]                            instr_axi_size,
  input [1:0]                            instr_axi_burst,
  input [2:0]                            instr_axi_strb_pattern,
  input                                  reset_id,
// AXI write address channel signals
  input                                  axi_awready, // Indicates slave is ready to accept a 
  output reg [C_AXI_ID_WIDTH-1:0]        axi_awid,    // Write ID
  output reg [C_AXI_ADDR_WIDTH-1:0]      axi_awaddr,  // Write address
  output reg [7:0]                       axi_awlen,   // Write Burst Length
  output reg [2:0]                       axi_awsize,  // Write Burst size
  output reg [1:0]                       axi_awburst, // Write Burst type
  output reg                             axi_awlock,  // Write lock type
  output reg [3:0]                       axi_awcache, // Write Cache type
  output reg [2:0]                       axi_awprot,  // Write Protection type
  output reg                             axi_awvalid, // Write address valid
// AXI write data channel signals
  input                                  axi_wready,  // Write data ready
  output [C_AXI_DATA_WIDTH-1:0]          axi_wdata,    // Write data
  output [C_AXI_DATA_WIDTH/8-1:0]        axi_wstrb,    // Write strobes
  output                                 axi_wlast,    // Last write transaction   
  output                                 axi_wvalid,   // Write valid  
// AXI write response channel signals
  input  [C_AXI_ID_WIDTH-1:0]            axi_bid,     // Response ID
  input  [1:0]                           axi_bresp,   // Write response
  input                                  axi_bvalid,  // Write reponse valid
  output reg                             axi_bready,  // Response ready
// AXI read address channel signals
  input                                  axi_arready,     // Read address ready
  output reg [C_AXI_ID_WIDTH-1:0]        axi_arid,        // Read ID
  output reg [C_AXI_ADDR_WIDTH-1:0]      axi_araddr,      // Read address
  output reg [7:0]                       axi_arlen,       // Read Burst Length
  output reg [2:0]                       axi_arsize,      // Read Burst size
  output reg [1:0]                       axi_arburst,     // Read Burst type
  output reg                             axi_arlock,      // Read lock type
  output reg [3:0]                       axi_arcache,     // Read Cache type
  output reg [2:0]                       axi_arprot,      // Read Protection type
  output reg                             axi_arvalid,     // Read address valid 
// AXI read data channel signals   
  input  [C_AXI_ID_WIDTH-1:0]            axi_rid,     // Response ID
  input  [1:0]                           axi_rresp,   // Read response
  input                                  axi_rvalid,  // Read reponse valid
  input  [C_AXI_DATA_WIDTH-1:0]          axi_rdata,    // Read data
  input                                  axi_rlast,    // Read last
  output reg                             axi_rready,  // Read Response ready
  //error signals
  output                                 vio_axi_tg_mismatch_error,
  output [C_AXI_DATA_WIDTH-1:0]          vio_axi_tg_expected_bits,
  output [C_AXI_DATA_WIDTH-1:0]          vio_axi_tg_actual_bits,
  output [C_AXI_DATA_WIDTH-1:0]          vio_axi_tg_error_bits,
  output [8:0]                           vio_axi_tg_data_beat_count,
  output [C_AXI_ID_WIDTH-1:0]            vio_axi_tg_error_status_id,
  output [C_AXI_ADDR_WIDTH-1:0]          vio_axi_tg_error_status_addr,
  output [7:0]                           vio_axi_tg_error_status_len,
  output [2:0]                           vio_axi_tg_error_status_size,
  output [1:0]                           vio_axi_tg_error_status_burst,
  output                                 vio_axi_tg_write_resp_error,
  output                                 vio_axi_tg_read_resp_error
);


//axi wrapper signals
reg                         cmd_en_wr;
reg [C_AXI_ADDR_WIDTH -1:0] awaddr;
reg [7:0]                   awlen;
reg [2:0]                   awsize;
reg [1:0]                   awburst;
reg [2:0]                   wdata_pattern;
reg [2:0]                   wstrb_pattern;
wire                        write_done;
reg                         cmd_en_rd;
reg [C_AXI_ADDR_WIDTH -1:0] araddr;
reg [7:0]                   arlen;
reg [2:0]                   arsize;
reg [1:0]                   arburst;
reg [2:0]                   rdata_pattern;
reg [2:0]                   rstrb_pattern;
reg                         compare_wr_rd;
reg                         compare_bg;
wire                        read_done;

reg tg_opcode_gen_idle_s;
reg tg_opcode_gen_load_s ;
reg tg_opcode_gen_write_simple_s ;
reg tg_opcode_gen_write_a5a5_aligned_addr_s ;
reg tg_opcode_gen_read_simple_s ;
reg tg_opcode_gen_read_bg_s ;
reg tg_opcode_gen_done_s ;

//registering the input addr/cmds when in LOAD state for timing
reg [C_AXI_ADDR_WIDTH -1:0]          instr_axi_addr_r;
reg [7:0]                            instr_axi_length_r;
reg [2:0]                            instr_axi_size_r;
reg [1:0]                            instr_axi_burst_r;
reg [2:0]                            instr_axi_strb_pattern_r;
always @(posedge clk) begin
  if(tg_opcode_gen_idle_s && opcode_gen_start)begin
    instr_axi_addr_r <= #TCQ instr_axi_addr;
    instr_axi_length_r <= #TCQ instr_axi_length;
    instr_axi_size_r <= #TCQ instr_axi_size;
    instr_axi_burst_r <= #TCQ instr_axi_burst;
    instr_axi_strb_pattern_r <= #TCQ instr_axi_strb_pattern;    
  end 
end

//generation of aligned addr
reg [C_AXI_ADDR_WIDTH -1 :0] aligned_addr;
always @ (*)begin
  case(instr_axi_size_r)
    3'b000: aligned_addr  = instr_axi_addr_r;
    3'b001: aligned_addr  = {instr_axi_addr_r[C_AXI_ADDR_WIDTH -1 : 1],1'd0};
    3'b010: aligned_addr  = {instr_axi_addr_r[C_AXI_ADDR_WIDTH -1 : 2],2'd0};
    3'b011: aligned_addr  = {instr_axi_addr_r[C_AXI_ADDR_WIDTH -1 : 3],3'd0};
    3'b100: aligned_addr  = {instr_axi_addr_r[C_AXI_ADDR_WIDTH -1 : 4],4'd0};
    3'b101: aligned_addr  = {instr_axi_addr_r[C_AXI_ADDR_WIDTH -1 : 5],5'd0};
    3'b110: aligned_addr  = {instr_axi_addr_r[C_AXI_ADDR_WIDTH -1 : 6],6'd0};
    3'b111: aligned_addr  = {instr_axi_addr_r[C_AXI_ADDR_WIDTH -1 : 7],7'd0};
   default: aligned_addr  = 'd0;
   endcase
end 

reg [C_AXI_ADDR_WIDTH -1 :0] ecc_aligned_addr; 
always @ (*)begin
	ecc_aligned_addr = {instr_axi_addr_r[C_AXI_ADDR_WIDTH -1 : 6],6'd0} ; 
end	
  	

reg [6:0] start_addr_lower_bits;
always @ (*)begin
  case(instr_axi_size_r)
    3'b000: start_addr_lower_bits  = 7'd0;
    3'b001: start_addr_lower_bits  = {6'd0,instr_axi_addr_r[0]};
    3'b010: start_addr_lower_bits  = {5'd0,instr_axi_addr_r[1:0]};
    3'b011: start_addr_lower_bits  = {4'd0,instr_axi_addr_r[2:0]};
    3'b100: start_addr_lower_bits  = {3'd0,instr_axi_addr_r[3:0]};
    3'b101: start_addr_lower_bits  = {2'd0,instr_axi_addr_r[4:0]};
    3'b110: start_addr_lower_bits  = {1'd0,instr_axi_addr_r[5:0]};
    3'b111: start_addr_lower_bits  =  instr_axi_addr_r[6:0];
   default: start_addr_lower_bits  =  7'd0;
  endcase
end 

reg [6:0] ecc_start_addr_lower_bits;
always @ (*)begin
	ecc_start_addr_lower_bits  = {1'd0,instr_axi_addr_r[5:0]};
end

reg partial_len; 
always @(*) begin
   case(instr_axi_size_r)
      3'b000: partial_len  = (instr_axi_length_r[5:0] == 6'b111111)? 1'b0: 1'b1;
      3'b001: partial_len  = (instr_axi_length_r[4:0] == 5'b11111 )? 1'b0: 1'b1; 
      3'b010: partial_len  = (instr_axi_length_r[3:0] == 4'b1111  )? 1'b0: 1'b1;
      3'b011: partial_len  = (instr_axi_length_r[2:0] == 3'b111   )? 1'b0: 1'b1;
      3'b100: partial_len  = (instr_axi_length_r[1:0] == 2'b11    )? 1'b0: 1'b1;
      3'b101: partial_len  = (instr_axi_length_r[0]   == 1'b1     )? 1'b0: 1'b1;
      3'b110: partial_len  =  1'b0;
      3'b111: partial_len  =  1'b0;
      default: partial_len = 1'b0;
   endcase
end

reg [7:0] full_axi_length;
always @(*) begin
   case(instr_axi_size_r)
      3'b000: full_axi_length  = {instr_axi_length[7:6],6'b111111};
      3'b001: full_axi_length  = {instr_axi_length[7:5],5'b11111}; 
      3'b010: full_axi_length  = {instr_axi_length[7:4],4'b1111};
      3'b011: full_axi_length  = {instr_axi_length[7:3],3'b111};
      3'b100: full_axi_length  = {instr_axi_length[7:2],2'b11} ;
      3'b101: full_axi_length  = {instr_axi_length[7:1],1'b1};
      3'b110: full_axi_length  = instr_axi_length;
      3'b111: full_axi_length  = instr_axi_length;
      default: full_axi_length = instr_axi_length;
   endcase
end

wire instr_axi_addr_is_aligned = (ecc_start_addr_lower_bits == 7'd0)? 1'b1: 1'b0; 
wire ecc_prevent_bg_write  = ((SEND_NBURST== 1) ? 1'b1: ((((APP_DATA_WIDTH > C_AXI_DATA_WIDTH) && partial_len) == 1)? 1'b1 : 1'b0)) && (ECC == "ON");

//state machine states
reg [3:0] tg_opcode_gen_sm_ps;
localparam TG_OPCODE_GEN_IDLE = 4'd0;
localparam TG_OPCODE_GEN_LOAD = 4'd1;
localparam TG_OPCODE_GEN_WRITE_SIMPLE = 4'd2;
localparam TG_OPCODE_GEN_WRITE_A5A5 = 4'd3;
localparam TG_OPCODE_GEN_WRITE_A5A5_ALIGNED_ADDR = 4'd4;
localparam TG_OPCODE_GEN_READ_SIMPLE = 4'd5;
localparam TG_OPCODE_GEN_READ_BG = 4'd6;
localparam TG_OPCODE_GEN_DONE = 4'd7;

wire arc_tg_opcode_gen_idle_to_load;
wire arc_tg_opcode_gen_load_to_write_simple;
wire arc_tg_opcode_gen_load_to_write_a5a5_aligned_addr;
wire arc_tg_opcode_gen_write_simple_to_read_simple;
wire arc_tg_opcode_gen_write_simple_to_read_bg;
wire arc_tg_opcode_gen_write_a5a5_aligned_addr_to_write_simple;
wire arc_tg_opcode_gen_read_simple_to_done;
wire arc_tg_opcode_gen_read_bg_to_done;
wire arc_tg_opcode_gen_done_to_idle;
//the following states are to be traversed if
//1. we want to do simple write followed by read; this is done for aligned addr and default wsrtb
// IDLE ->LOAD ->WRITE_SIMPLE ->READ_SIMPLE ->DONE 
//2. we will write background pattern A5A5 to aligned addr, then prbs write to unaligned addr followed by read_bg. This is used for unaligned addr and/or walking strb
// IDLE ->LOAD ->WRITE_A5A5_ALIGNED_ADDR ->WRITE_SIMPLE ->READ_BG ->DONE 

assign arc_tg_opcode_gen_idle_to_load = (tg_opcode_gen_idle_s && opcode_gen_start)? 1'b1 :1'b0;
assign arc_tg_opcode_gen_load_to_write_simple = (tg_opcode_gen_load_s && (instr_axi_strb_pattern == C_STRB_PATTERN_DEFAULT) && instr_axi_addr_is_aligned && !ecc_prevent_bg_write)?1'b1 : 1'b0;
assign arc_tg_opcode_gen_load_to_write_a5a5_aligned_addr =  (tg_opcode_gen_load_s && ((instr_axi_strb_pattern != C_STRB_PATTERN_DEFAULT) || (!instr_axi_addr_is_aligned)||(ecc_prevent_bg_write)))? 1'b1 : 1'b0;
assign arc_tg_opcode_gen_write_simple_to_read_simple = (tg_opcode_gen_write_simple_s && write_done && (instr_axi_strb_pattern == C_STRB_PATTERN_DEFAULT) && instr_axi_addr_is_aligned)? 1'b1 :1'b0;
assign arc_tg_opcode_gen_write_simple_to_read_bg = (tg_opcode_gen_write_simple_s && write_done && ((instr_axi_strb_pattern != C_STRB_PATTERN_DEFAULT) || !instr_axi_addr_is_aligned))? 1'b1 :1'b0;
assign arc_tg_opcode_gen_write_a5a5_aligned_addr_to_write_simple = (tg_opcode_gen_write_a5a5_aligned_addr_s && write_done)? 1'b1:1'b0 ;
assign arc_tg_opcode_gen_read_simple_to_done = (tg_opcode_gen_read_simple_s && read_done)? 1'b1:1'b0;
assign arc_tg_opcode_gen_read_bg_to_done = (tg_opcode_gen_read_bg_s && read_done)? 1'b1:1'b0;
assign arc_tg_opcode_gen_done_to_idle = 1'b1;

//opcode generation state machine
always@(posedge clk) begin
  if (tg_rst) begin
    tg_opcode_gen_sm_ps <= #TCQ TG_OPCODE_GEN_IDLE;
    tg_opcode_gen_idle_s <= #TCQ 1'b1;
    tg_opcode_gen_load_s <= #TCQ 1'b0;
    tg_opcode_gen_write_simple_s <= #TCQ 1'b0;
    tg_opcode_gen_write_a5a5_aligned_addr_s <= #TCQ 1'b0;
    tg_opcode_gen_read_simple_s <= #TCQ 1'b0;
    tg_opcode_gen_read_bg_s <= #TCQ 1'b0;
    tg_opcode_gen_done_s <= #TCQ 1'b0;
  end
  else begin
	  casez (tg_opcode_gen_sm_ps)
      TG_OPCODE_GEN_IDLE: 
		    if (arc_tg_opcode_gen_idle_to_load) begin
		      tg_opcode_gen_sm_ps <= #TCQ TG_OPCODE_GEN_LOAD;
		      tg_opcode_gen_idle_s <= #TCQ 1'b0;
		      tg_opcode_gen_load_s  <= #TCQ 1'b1;
		    end        
      TG_OPCODE_GEN_LOAD: 
		    if (arc_tg_opcode_gen_load_to_write_simple) begin
		      tg_opcode_gen_sm_ps <= #TCQ TG_OPCODE_GEN_WRITE_SIMPLE;
		      tg_opcode_gen_load_s <= #TCQ 1'b0;
		      tg_opcode_gen_write_simple_s  <= #TCQ 1'b1;
		    end           
		    else if (arc_tg_opcode_gen_load_to_write_a5a5_aligned_addr) begin
		      tg_opcode_gen_sm_ps <= #TCQ TG_OPCODE_GEN_WRITE_A5A5_ALIGNED_ADDR;
		      tg_opcode_gen_load_s <= #TCQ 1'b0;
		      tg_opcode_gen_write_a5a5_aligned_addr_s  <= #TCQ 1'b1;
		    end
    TG_OPCODE_GEN_WRITE_SIMPLE: 
		    if (arc_tg_opcode_gen_write_simple_to_read_simple) begin
		      tg_opcode_gen_sm_ps <= #TCQ TG_OPCODE_GEN_READ_SIMPLE;
		      tg_opcode_gen_write_simple_s <= #TCQ 1'b0;
		      tg_opcode_gen_read_simple_s  <= #TCQ 1'b1;
		    end       
		    else if (arc_tg_opcode_gen_write_simple_to_read_bg) begin
		      tg_opcode_gen_sm_ps <= #TCQ TG_OPCODE_GEN_READ_BG;
		      tg_opcode_gen_write_simple_s <= #TCQ 1'b0;
		      tg_opcode_gen_read_bg_s  <= #TCQ 1'b1;
		    end       
     TG_OPCODE_GEN_WRITE_A5A5_ALIGNED_ADDR: 
		    if (arc_tg_opcode_gen_write_a5a5_aligned_addr_to_write_simple) begin
		      tg_opcode_gen_sm_ps <= #TCQ TG_OPCODE_GEN_WRITE_SIMPLE;
		      tg_opcode_gen_write_a5a5_aligned_addr_s <= #TCQ 1'b0;
		      tg_opcode_gen_write_simple_s  <= #TCQ 1'b1;
		    end
    TG_OPCODE_GEN_READ_SIMPLE: 
		    if (arc_tg_opcode_gen_read_simple_to_done) begin
		      tg_opcode_gen_sm_ps <= #TCQ TG_OPCODE_GEN_DONE;
		      tg_opcode_gen_read_simple_s <= #TCQ 1'b0;
		      tg_opcode_gen_done_s <= #TCQ 1'b1;
		    end
    TG_OPCODE_GEN_READ_BG: 
		    if (arc_tg_opcode_gen_read_bg_to_done) begin
		      tg_opcode_gen_sm_ps <= #TCQ TG_OPCODE_GEN_DONE;
		      tg_opcode_gen_read_bg_s <= #TCQ 1'b0;
		      tg_opcode_gen_done_s <= #TCQ 1'b1;
		    end
     TG_OPCODE_GEN_DONE: 
		    if (arc_tg_opcode_gen_done_to_idle) begin
		      tg_opcode_gen_sm_ps <= #TCQ TG_OPCODE_GEN_IDLE;
		      tg_opcode_gen_done_s <= #TCQ 1'b0;
		      tg_opcode_gen_idle_s  <= #TCQ 1'b1;
		    end       
    endcase
  end
end  

assign opcode_gen_done = tg_opcode_gen_done_s;

always @ (*)begin
  if (tg_rst) begin
    cmd_en_wr = 1'b0;
    awaddr = 'd0;
    awlen = 'd0;
    awsize = 'd0;
    awburst = 'd0;
    wdata_pattern = 'd0;
    wstrb_pattern = 'd0;    
  end
  else if (tg_opcode_gen_write_simple_s) begin
    cmd_en_wr = 1'b1;
    awaddr = instr_axi_addr_r;
    awlen = instr_axi_length_r;
    awsize = instr_axi_size_r;
    awburst = instr_axi_burst_r;
    wdata_pattern = C_DATA_PATTERN_PRBS;
    wstrb_pattern = instr_axi_strb_pattern_r;    
  end  
  else if (tg_opcode_gen_write_a5a5_aligned_addr_s) begin
    cmd_en_wr = 1'b1;
    awaddr = (ecc_prevent_bg_write == 1) ? ecc_aligned_addr: aligned_addr; 
    awlen =  (ecc_prevent_bg_write == 1) ? full_axi_length : instr_axi_length_r; 
    awsize = instr_axi_size_r;
    awburst = instr_axi_burst_r;
    wdata_pattern = C_DATA_PATTERN_A5A5;
    wstrb_pattern = C_STRB_PATTERN_DEFAULT;    
  end  
  else begin
    cmd_en_wr = 1'b0;  
    awaddr = 'd0;
    awlen = 'd0;
    awsize = 'd0;
    awburst = 'd0;
    wdata_pattern = 'd0;
    wstrb_pattern = 'd0;    
  end  
end

always @ (*)begin
  if (tg_rst) begin
    cmd_en_rd = 1'b0;
    araddr = 'd0;
    arlen = 'd0;
    arsize = 'd0;
    arburst = 'd0;
    rdata_pattern = 'd0;
    rstrb_pattern = 'd0;   
    compare_wr_rd = 1'b0;
    compare_bg = 1'b0;
  end
  else if (tg_opcode_gen_read_simple_s) begin
    cmd_en_rd = 1'b1;
    araddr = instr_axi_addr_r;
    arlen = instr_axi_length_r;
    arsize = instr_axi_size_r;
    arburst = instr_axi_burst_r;
    rdata_pattern = C_DATA_PATTERN_PRBS;
    rstrb_pattern = instr_axi_strb_pattern_r;    
    compare_wr_rd = 1'b1;
    compare_bg = 1'b0;
  end  
  else if (tg_opcode_gen_read_bg_s) begin
    cmd_en_rd = 1'b1;
    araddr = instr_axi_addr_r;
    arlen = instr_axi_length_r;
    arsize = instr_axi_size_r;
    arburst = instr_axi_burst_r;
    rdata_pattern = C_DATA_PATTERN_PRBS;
    rstrb_pattern = instr_axi_strb_pattern_r;    
    compare_wr_rd = 1'b1;
    compare_bg = 1'b1;
  end  
  else begin
    cmd_en_rd = 1'b0;
    araddr = 'd0;
    arlen = 'd0;
    arsize = 'd0;
    arburst = 'd0;
    rdata_pattern = 'd0;
    rstrb_pattern = 'd0;   
    compare_wr_rd = 1'b0;
    compare_bg = 1'b0;
  end  
end

ddr4_v2_2_3_axi_wrapper #(
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
) u_axi_wrapper (
  .clk             ( clk),
  .tg_rst          ( tg_rst),
  .cmd_en_wr       ( cmd_en_wr),
  .awaddr          ( awaddr),
  .awlen           ( awlen),
  .awsize          ( awsize),
  .awburst         ( awburst),
  .wdata_pattern   ( wdata_pattern),
  .wstrb_pattern   ( wstrb_pattern),
  .write_done      ( write_done),
  .cmd_en_rd       ( cmd_en_rd),
  .araddr          ( araddr),
  .arlen           ( arlen),
  .arsize          ( arsize),
  .arburst         ( arburst),
  .rdata_pattern   ( rdata_pattern),
  .rstrb_pattern   ( rstrb_pattern),
  .compare_wr_rd   ( compare_wr_rd),
  .compare_bg      ( compare_bg),
  .read_done       ( read_done),
  .reset_id        ( reset_id),
  .axi_awready     ( axi_awready),
  .axi_awid        ( axi_awid),
  .axi_awaddr      ( axi_awaddr),
  .axi_awlen       ( axi_awlen),
  .axi_awsize      ( axi_awsize),
  .axi_awburst     ( axi_awburst),
  .axi_awlock      ( axi_awlock),
  .axi_awcache     ( axi_awcache),
  .axi_awprot      ( axi_awprot),
  .axi_awvalid     ( axi_awvalid),
  .axi_wready      ( axi_wready),
  .axi_wdata       ( axi_wdata),
  .axi_wstrb       ( axi_wstrb),
  .axi_wlast       ( axi_wlast),
  .axi_wvalid      ( axi_wvalid),
  .axi_bid         ( axi_bid),
  .axi_bresp       ( axi_bresp),
  .axi_bvalid      ( axi_bvalid),
  .axi_bready      ( axi_bready),
  .axi_arready     ( axi_arready),
  .axi_arid        ( axi_arid),
  .axi_araddr      ( axi_araddr),
  .axi_arlen       ( axi_arlen),
  .axi_arsize      ( axi_arsize),
  .axi_arburst     ( axi_arburst),
  .axi_arlock      ( axi_arlock),
  .axi_arcache     ( axi_arcache),
  .axi_arprot      ( axi_arprot),
  .axi_arvalid     ( axi_arvalid),
  .axi_rid         ( axi_rid),
  .axi_rresp       ( axi_rresp),
  .axi_rvalid      ( axi_rvalid),
  .axi_rdata       ( axi_rdata),
  .axi_rlast       ( axi_rlast),
  .axi_rready      ( axi_rready),
  .vio_axi_tg_mismatch_error(vio_axi_tg_mismatch_error),
  .vio_axi_tg_expected_bits(vio_axi_tg_expected_bits),
  .vio_axi_tg_actual_bits(vio_axi_tg_actual_bits),
  .vio_axi_tg_error_bits(vio_axi_tg_error_bits),
  .vio_axi_tg_data_beat_count(vio_axi_tg_data_beat_count),
  .vio_axi_tg_error_status_id(vio_axi_tg_error_status_id),
  .vio_axi_tg_error_status_addr(vio_axi_tg_error_status_addr),
  .vio_axi_tg_error_status_len(vio_axi_tg_error_status_len),
  .vio_axi_tg_error_status_size(vio_axi_tg_error_status_size),
  .vio_axi_tg_error_status_burst(vio_axi_tg_error_status_burst),
  .vio_axi_tg_write_resp_error(vio_axi_tg_write_resp_error),
  .vio_axi_tg_read_resp_error(vio_axi_tg_read_resp_error)
);

endmodule



