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
// File       : hmc_iic.v
// Version    : 1.0  
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// Project    : The Xilinx HMC Host Controller  
// File       : hmc_iic.v
// Version    : 1.0  
//-----------------------------------------------------------------------------

`timescale 1ns/1ps
module hmc_iic #(
parameter IIC_MUX_ADDR = 7'h74,
parameter IIC_HMC_ADDR = 7'h14,
parameter GT_SPEED     = 10,
parameter FULL_WIDTH   = 1,
parameter CLOCK_FREQ   = 125,
parameter HMC_LINK_ID  = 1'b1,
parameter HMC_TOKEN_CNT = 32'd240
)(
    input   rst,
    input   clk,

    inout   iic_scl_io,
    inout   iic_sda_io,

    input   hmc_iic_start,
    output  hmc_iic_done
);

localparam NUM_CMD         = 29;
localparam CMD_WIDTH       = 86;
localparam ROM_ADDR_WIDTH  = 5;

localparam OP_WR   = 3'h0; //wr operation
localparam OP_RD   = 3'h1; //rd operation
localparam OP_DV   = 3'h2; //verify read data 
localparam OP_WT   = 3'h3; //wait operation, dev_addr uses as wait cycle
localparam OP_ED   = 3'h4; //end of iic sequence

reg [CMD_WIDTH-1:0] cmd_rom[NUM_CMD-1:0];
//ROM initialization
localparam HMC_LINK_SPEED  = (GT_SPEED ==10 ) ? 32'h0 :
                             (GT_SPEED ==12.5) ? 32'h1 :
                             (GT_SPEED ==15  ) ? 32'h2 : 
                                                 32'h3; //reserved for REV 1.1
localparam HMC_LINK_WIDTH  = (FULL_WIDTH ==1 ) ? 32'h0 :
                                                 32'h00010000; 
localparam HMC_LINK_CONF   = HMC_LINK_SPEED | HMC_LINK_WIDTH ;

localparam RQST_ID_ADDR      = 32'h00000000;
localparam IBUF_TK_ADDR      = (HMC_LINK_ID == 'd0) ? 32'h00040000 :
                               (HMC_LINK_ID == 'd1) ? 32'h00050000 :
                               (HMC_LINK_ID == 'd2) ? 32'h00060000 :
                                                      32'h00070000 ;
localparam LNK_RTY_ADDR      = (HMC_LINK_ID == 'd0) ? 32'h004c0000 :
                               (HMC_LINK_ID == 'd1) ? 32'h004d0000 :
                               (HMC_LINK_ID == 'd2) ? 32'h004e0000 :
                                                      32'h004f0000 ;
localparam LNK_CNF_ADDR      = (HMC_LINK_ID == 'd0) ? 32'h00240000 :
                               (HMC_LINK_ID == 'd1) ? 32'h00250000 :
                               (HMC_LINK_ID == 'd2) ? 32'h00260000 :
                                                      32'h00270000 ;
localparam LNK_RLL_ADDR      = (HMC_LINK_ID == 'd0) ? 32'h00240003 :
                               (HMC_LINK_ID == 'd1) ? 32'h00250003 :
                               (HMC_LINK_ID == 'd2) ? 32'h00260003 :
                                                      32'h00270003 ;
localparam ADD_CFG_ADDR      = 32'h002C0000;
localparam VLT_CTL_ADDR      = 32'h00108000;
localparam ERIDATA_LNK       = (HMC_LINK_ID == 'd0) ? 32'h002B0000 :
                               (HMC_LINK_ID == 'd1) ? 32'h002B0001 :
                               (HMC_LINK_ID == 'd2) ? 32'h002B0002 :
                                                      32'h002B0003 ;

localparam NVM_WR_DIS_ADDR   = 32'h40680002;
localparam LNK_CNF_LNK0_ADDR = 32'h00240000;
localparam LNK_CNF_LNK1_ADDR = 32'h00250000;
localparam LNK_CNF_LNK2_ADDR = 32'h00260000;
localparam LNK_CNF_LNK3_ADDR = 32'h00270000;

localparam ERIDATA_LNK0      = 32'h002B0000; 
localparam ERIDATA_LNK1      = 32'h002B0001;
localparam ERIDATA_LNK2      = 32'h002B0002;
localparam ERIDATA_LNK3      = 32'h002B0003;
localparam ERIREQ_REG        = 32'h002B0004;
localparam ERIREQ_START      = 32'hF86B0004;

localparam WAIT_CYCLE        = 32'd5000; 

initial begin
    //            op_code , dev_addr     , reg_addr          , raddr_ben , wdata          , wdata_ben , rdata_ben
    cmd_rom[0] = {OP_WR   , IIC_MUX_ADDR , 32'h0             , 4'h0      , 32'hFF000000   , 4'h8      , 4'h0}; //turn in all port
    cmd_rom[1] = {OP_WR   , IIC_HMC_ADDR , LNK_RLL_ADDR      , 4'hF      , 32'h00c80000   , 4'hF      , 4'h0};
    cmd_rom[2] = {OP_WR   , IIC_HMC_ADDR , LNK_RTY_ADDR      , 4'hF      , 32'h00000001   , 4'hF      , 4'h0}; //enable retry
    cmd_rom[3] = {OP_WR   , IIC_HMC_ADDR , LNK_CNF_LNK0_ADDR , 4'hF      , 32'h00000EF8   , 4'hF      , 4'h0};
    cmd_rom[4] = {OP_WR   , IIC_HMC_ADDR , LNK_CNF_LNK1_ADDR , 4'hF      , 32'h00000EF8   , 4'hF      , 4'h0};
    cmd_rom[5] = {OP_WR   , IIC_HMC_ADDR , LNK_CNF_LNK2_ADDR , 4'hF      , 32'h00000EF8   , 4'hF      , 4'h0};
    cmd_rom[6] = {OP_WR   , IIC_HMC_ADDR , LNK_CNF_LNK3_ADDR , 4'hF      , 32'h00000EF8   , 4'hF      , 4'h0};
    cmd_rom[7] = {OP_WR   , IIC_HMC_ADDR , LNK_CNF_ADDR      , 4'hF      , 32'h00000FD9   , 4'hF      , 4'h0};
    cmd_rom[8] = {OP_WR   , IIC_HMC_ADDR , IBUF_TK_ADDR      , 4'hF      , HMC_TOKEN_CNT  , 4'hF      , 4'h0};
    cmd_rom[9] = {OP_WR   , IIC_HMC_ADDR , VLT_CTL_ADDR      , 4'hF      , 32'h0000087C   , 4'hF      , 4'h0};
    cmd_rom[10]= {OP_WR   , IIC_HMC_ADDR , ERIDATA_LNK       , 4'hF      , HMC_LINK_CONF , 4'hF      , 4'h0}; //link ctrl
    cmd_rom[11]= {OP_WR   , IIC_HMC_ADDR , ERIREQ_REG        , 4'hF      , 32'h813F0005   , 4'hF      , 4'h0};
    cmd_rom[12]= {OP_WT   , 7'b0         , 32'h0             , 4'h0      , WAIT_CYCLE     , 4'h0      , 4'h0};
    cmd_rom[13]= {OP_RD   , IIC_HMC_ADDR , ERIREQ_START      , 4'hF      , 32'h0          , 4'h0      , 4'hF};
    cmd_rom[14]= {OP_WT   , 7'b0         , 32'h0             , 4'h0      , WAIT_CYCLE     , 4'h0      , 4'h0};
    cmd_rom[15]= {OP_DV   , 7'b0         , 32'h0             , 4'h0      , 32'h0          , 4'h0      , 4'h0};
    cmd_rom[16]= {OP_WR   , IIC_HMC_ADDR , ERIDATA_LNK       , 4'hF      , 32'h40000000   , 4'hF      , 4'h0}; //PHY CTRL,AC coupling
    cmd_rom[17]= {OP_WR   , IIC_HMC_ADDR , ERIREQ_REG        , 4'hF      , 32'h80000006   , 4'hF      , 4'h0};
    cmd_rom[18]= {OP_RD   , IIC_HMC_ADDR , ERIREQ_START      , 4'hF      , 32'h0          , 4'h0      , 4'hF};
    cmd_rom[19]= {OP_WT   , 7'b0         , 32'h0             , 4'h0      , WAIT_CYCLE     , 4'h0      , 4'h0};
    cmd_rom[20]= {OP_DV   , 7'b0         , 32'h0             , 4'h0      , 32'h0          , 4'h0      , 4'h0};
    cmd_rom[21]= {OP_WR   , IIC_HMC_ADDR , ERIREQ_REG        , 4'hF      , 32'h8000003f   , 4'hF      , 4'h0};  //set init continue
    cmd_rom[22]= {OP_WT   , 7'b0         , 32'h0             , 4'h0      , WAIT_CYCLE     , 4'h0      , 4'h0};
    cmd_rom[23]= {OP_RD   , IIC_HMC_ADDR , ERIREQ_START      , 4'hF      , 32'h0          , 4'h0      , 4'hF};
    cmd_rom[24]= {OP_WT   , 7'b0         , 32'h0             , 4'h0      , WAIT_CYCLE     , 4'h0      , 4'h0};
    cmd_rom[25]= {OP_DV   , 7'b0         , 32'h0             , 4'h0      , 32'h0          , 4'h0      , 4'h0};
    cmd_rom[26]= {OP_WR   , IIC_HMC_ADDR , NVM_WR_DIS_ADDR   , 4'hF      , 32'h1          , 4'hF      , 4'h0};  //Disable NVM write 
    cmd_rom[27]= {OP_WT   , 7'b0         , 32'h0             , 4'h0      , 32'h8          , 4'h0      , 4'h0};
    cmd_rom[28]= {OP_ED   , 7'b0 , 32'h0 , 4'h0      , 32'h0          , 4'h0      , 4'h0};  // eof
end

localparam ST_IDLE = 3'h0;
localparam ST_CMD  = 3'h1;
localparam ST_WR   = 3'h2;
localparam ST_RD   = 3'h3;
localparam ST_DV   = 3'h4;
localparam ST_WAIT = 3'h5;
localparam ST_J_RD = 3'h6; // jump to the last read
localparam ST_RTY  = 3'h7; // retry current inst of arb error detested

localparam INTER_INST_GAP = 32'h1000; // inter-instruction gap for HMC device

wire        iic_scl_o;
wire        iic_scl_t; //iic scl output enable
wire        iic_sda_i;
wire        iic_sda_o;
wire        iic_sda_t; //iic sda output enable

wire        iic_req;
wire [6:0]  iic_dev_addr;
wire [31:0] iic_reg_addr;
wire [3:0]  iic_raddr_ben; //register address byte enable
wire [31:0] iic_wdata;
wire [3:0]  iic_wdata_ben;
wire [3:0]  iic_rdata_ben;
wire        iic_ack;
wire [31:0] iic_rdata;
wire        iic_error;  //error status

wire idle_st;
wire cmd_st;
wire wr_st;
wire rd_st;
wire dv_st;
wire wait_st;
wire rty_st;

wire cmd_wait;
wire cmd_wr  ;
wire cmd_rd  ;
wire cmd_dv  ;


wire [ROM_ADDR_WIDTH-1:0] inst_ptr_nxt;
reg  [ROM_ADDR_WIDTH-1:0] inst_ptr;
wire [ROM_ADDR_WIDTH-1:0] last_rd_ptr_nxt;
reg  [ROM_ADDR_WIDTH-1:0] last_rd_ptr;

wire [CMD_WIDTH-1:0] inst_nxt;
reg  [CMD_WIDTH-1:0] inst;

reg  [2:0] c_st;
reg  [2:0] nxt_st;
wire [2:0] op_code;

wire req_nxt;
reg  req;

wire  data_match_nxt;
reg   data_match;

wire [31:0] timer_nxt;
wire        timeout;
reg  [31:0] timer;
wire done_nxt;
reg  done;

wire [31:0] rdata_nxt;
reg  [31:0] rdata;

assign idle_st = (c_st == ST_IDLE) ; 
assign cmd_st  = (c_st == ST_CMD ) ; 
assign wr_st   = (c_st == ST_WR  ) ; 
assign rd_st   = (c_st == ST_RD  ) ; 
assign dv_st   = (c_st == ST_DV  ) ; 
assign wait_st = (c_st == ST_WAIT) ; 
assign rty_st  = (c_st == ST_RTY);

assign  cmd_wr   = (op_code == OP_WR);
assign  cmd_rd   = (op_code == OP_RD);
assign  cmd_dv   = (op_code == OP_DV);
assign  cmd_wait = (op_code == OP_WT);
assign  cmd_end  = (op_code == OP_ED);

always @ (*)
begin
    nxt_st = c_st;
    case(c_st) 
        ST_IDLE: begin 
            nxt_st = hmc_iic_start ? ST_CMD : c_st;
        end
        ST_CMD: begin
            nxt_st = cmd_end  ? ST_IDLE :
                     cmd_wait ? ST_WAIT :
                     cmd_wr   ? ST_WR   : 
                     cmd_rd   ? ST_RD   :
                     cmd_dv   ? ST_DV   : c_st; 
        end
        ST_WR  : begin
            nxt_st = (iic_req & iic_ack) ? (iic_error ? ST_RTY : ST_CMD) : c_st;
        end 
        ST_RD  : begin  
            nxt_st = (iic_req & iic_ack) ? (iic_error ? ST_RTY : ST_CMD) : c_st;
        end 
        ST_DV  : begin
            nxt_st = data_match ? ST_WAIT :ST_J_RD; 
        end 
        ST_J_RD : begin
            nxt_st = ST_WAIT;
        end
        ST_RTY : begin
            nxt_st = ST_WAIT;
        end
        ST_WAIT: begin
            nxt_st = timeout ? ST_CMD : c_st;
        end 
    endcase
end

assign inst_ptr_nxt = idle_st ? {ROM_ADDR_WIDTH{1'b0}}: 
                      cmd_st  ? inst_ptr + 1'b1       :
                      (rd_st | wr_st) & (iic_req & iic_ack & iic_error) ? (inst_ptr - 1'b1) :
                      (dv_st & ~data_match) ? last_rd_ptr : inst_ptr;
assign inst_nxt = (nxt_st == ST_CMD) ? cmd_rom[inst_ptr] : inst;

assign last_rd_ptr_nxt = (cmd_st & cmd_rd)? inst_ptr : last_rd_ptr; 

assign op_code       = inst[85:83];
assign iic_dev_addr  = inst[82:76]; 
assign iic_reg_addr  = inst[75:44];
assign iic_raddr_ben = inst[43:40];
assign iic_wdata     = inst[39:8];
assign iic_wdata_ben = inst[7:4];
assign iic_rdata_ben = inst[3:0];

assign req_nxt   = cmd_st & (cmd_wr | cmd_rd) ? 1'b1 :
                   (wr_st |rd_st) ? req :
                                  1'b0;
assign iic_req   = req; 
assign timer_nxt = (cmd_st & cmd_wait) ? iic_wdata :
                      wait_st ? (timer - 1'b1) : INTER_INST_GAP;
assign timeout = ~|timer; 

assign data_match_nxt = (cmd_st & cmd_dv) ? (rdata == iic_wdata) : 1'b0;

assign done_nxt = done ? done : (cmd_st & cmd_end);
assign hmc_iic_done = done;

assign rdata_nxt = (rd_st & iic_req & iic_ack) ? iic_rdata : rdata;

`ifndef LIB_VH
`define LIB_VH
`define XSRREG(clk, reset, q,d,rstval)	\
    always @(posedge clk )			\
    begin					\
     if (reset == 1'b1)			\
         q <= rstval;				\
     else					\
	     q <=  d;				\
     end
`endif

`XSRREG(clk, rst, c_st, nxt_st, ST_IDLE) // single pulse
`XSRREG(clk, rst, inst_ptr, inst_ptr_nxt, {ROM_ADDR_WIDTH{1'b0}}) 
`XSRREG(clk, rst, last_rd_ptr, last_rd_ptr_nxt, {ROM_ADDR_WIDTH{1'b0}}) 
`XSRREG(clk, rst, inst, inst_nxt, {CMD_WIDTH{1'b0}}) 
`XSRREG(clk, rst, req,req_nxt, 1'b0) 
`XSRREG(clk, rst, timer,timer_nxt, {32{1'b1}}) 
`XSRREG(clk, rst, data_match,data_match_nxt, 1'b0) 
`XSRREG(clk, rst, done,done_nxt, 1'b0) 
`XSRREG(clk, rst, rdata,rdata_nxt, 32'b0) 

/*******************************************************************************/
iic_driver u_iic_driver(
  .clk          (clk),
  .rst          (rst),
  .iic_scl_i    (iic_scl_i),
  .iic_scl_o    (iic_scl_o),
  .iic_scl_t    (iic_scl_t), //iic scl output enable
  .iic_sda_i    (iic_sda_i),
  .iic_sda_o    (iic_sda_o),
  .iic_sda_t    (iic_sda_t), //iic sda output enable
  .iic_req      (iic_req),
  .iic_dev_addr (iic_dev_addr),
  .iic_reg_addr (iic_reg_addr),
  .iic_raddr_ben(iic_raddr_ben), //register address byte enable
  .iic_wdata    (iic_wdata),
  .iic_wdata_ben(iic_wdata_ben),
  .iic_rdata_ben(iic_rdata_ben),
  .iic_ack      (iic_ack),
  .iic_rdata    (iic_rdata),
  .iic_error    (iic_error)  //error status
);

IOBUF iic_scl_iobuf_inst (
  .I  (iic_scl_o),
  .IO (iic_scl_io),
  .O  (iic_scl_i),
  .T  (iic_scl_t) );

IOBUF iic_sda_iobuf_inst (
  .I  (iic_sda_o),
  .IO (iic_sda_io),
  .O  (iic_sda_i),
  .T  (iic_sda_t) );

endmodule
/*******************************************************************************/
//todo error handling

