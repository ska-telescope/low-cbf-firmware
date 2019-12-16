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
// File       : iic_driver.v
// Version    : 1.0  
//-----------------------------------------------------------------------------

`timescale 1ns/1ps
module iic_driver(
  input         clk,
  input         rst,
  input         iic_scl_i,
  output        iic_scl_o,
  output        iic_scl_t, //iic scl output enable
  input         iic_sda_i,
  output        iic_sda_o,
  output        iic_sda_t, //iic sda output enable
  input         iic_req,
  input  [6:0]  iic_dev_addr,
  input  [31:0] iic_reg_addr,
  input  [3:0]  iic_raddr_ben, //register address byte enable
  input  [31:0] iic_wdata,
  input  [3:0]  iic_wdata_ben,
  input  [3:0]  iic_rdata_ben,
  output        iic_ack,
  output [31:0] iic_rdata,
  output        iic_error  //error status
);

localparam ST_IDLE     =4'd0;
localparam ST_START    =4'd1;
localparam ST_STOP     =4'd2;
localparam ST_DEV_ADDR =4'd3;
localparam ST_REG_ADDR =4'd4;
localparam ST_WR_BYTE  =4'd5;
localparam ST_RD_BYTE  =4'd6;
localparam ST_TX_ACK   =4'd7;
localparam ST_RX_ACK   =4'd8;
//localparam ST_SDA_HIGH =4'd9;  //FORCE SDA to 1 while SCL IS HIGH
localparam ST_SCL_LOW  =4'd9; //FORCE SCL to low
localparam ST_WAIT_SCL =4'd10; //wait slave releasing SCL

localparam CLK_DIV  = 12'd1249; // reduce the clock from 125Mhz to 100Khz
localparam HALF_DIV = 12'd624; // Pulse duration of SCL 
localparam QUAL_DIV = 12'd312; // Pulse duration of SCL 

/*******************************************************************************/

wire  idle_st    ;
wire  start_st   ;
wire  stop_st    ;
wire  dev_addr_st;
wire  reg_addr_st;
wire  wr_byte_st ;
wire  rd_byte_st ;
wire  tx_ack_st  ;
wire  rx_ack_st  ;
wire  wait_scl_st  ;
wire  scl_low_st  ;

wire wr_pending;
wire raddr_pending;
wire wdata_pending;
wire rdata_pending;
wire bit_pending;
wire wr_bit_mux;
wire wr_bit;

reg          clk_en;
reg [11:0]   clk_cnt;
reg [3:0]    c_st;
reg [3:0]    nxt_st;

reg          ack;
reg          scl_t;
reg          sda_t;
reg          ack_err; //no valid ACK 
reg          arb_err; //collision during transmission

reg          cmd_type;
reg  [3:0]   byte_mask;
reg  [3:0]   raddr_ben;
reg  [3:0]   wdata_ben;
reg  [7:0]   wr_dbyte;
reg  [2:0]   bit_cnt;
reg  [3:0]   rdata_ben;
reg  [7:0]   rd_byte;
reg  [31:0]  rdata;

/*******************************************************************************/
assign iic_ack   = ack;
assign iic_error = ack_err | arb_err;
assign iic_scl_o = 1'b0;
assign iic_sda_o = 1'b0;

assign iic_scl_t = scl_t;
assign iic_sda_t = sda_t;
assign iic_rdata = rdata;
 
assign raddr_pending = |raddr_ben;
assign wdata_pending = |wdata_ben;
assign rdata_pending = |rdata_ben;
assign wr_pending    = raddr_pending | wdata_pending;

//state decoding
assign  idle_st     = (c_st == ST_IDLE    );
assign  start_st    = (c_st == ST_START   );
assign  stop_st     = (c_st == ST_STOP    );
assign  dev_addr_st = (c_st == ST_DEV_ADDR);
assign  reg_addr_st = (c_st == ST_REG_ADDR);
assign  wr_byte_st  = (c_st == ST_WR_BYTE );
assign  rd_byte_st  = (c_st == ST_RD_BYTE );
assign  tx_ack_st   = (c_st == ST_TX_ACK  );
assign  rx_ack_st   = (c_st == ST_RX_ACK  );
assign  scl_low_st  = (c_st == ST_SCL_LOW); 
assign  wait_scl_st = (c_st == ST_WAIT_SCL);

always @(*) 
begin
    nxt_st = c_st;
    if(clk_en) begin
        case(c_st)
            ST_IDLE :begin
                //if(iic_req & iic_scl_i & iic_sda_i ) begin //TODO
                if(iic_req  & iic_scl_i) begin
                    nxt_st = ST_START;
                end
            end
            ST_START:begin
                nxt_st = ST_DEV_ADDR;
            end
            ST_DEV_ADDR :begin
                nxt_st = bit_pending ? c_st : ST_RX_ACK;
            end
            ST_REG_ADDR : begin
                nxt_st = bit_pending ? c_st : ST_RX_ACK;
            end
            ST_WR_BYTE : begin 
                nxt_st = bit_pending ? c_st : ST_RX_ACK;
            end
            ST_RD_BYTE : begin
                nxt_st = bit_pending ? c_st : ST_TX_ACK;
            end
            ST_STOP : begin
                nxt_st = ST_IDLE;
            end
            ST_TX_ACK : begin
                nxt_st = rdata_pending ? ST_RD_BYTE  : //read request pending
                                         ST_STOP;
            end
            ST_RX_ACK : begin 
                nxt_st = iic_sda_i ? ST_STOP : ST_SCL_LOW;
            end
            ST_SCL_LOW : begin
                nxt_st = raddr_pending ? ST_REG_ADDR : //reg address valid
                         wdata_pending ? ST_WR_BYTE  : //wdata available
                         (rdata_pending & cmd_type)  ? ST_RD_BYTE  : //first read
                         (rdata_pending & ~cmd_type) ? ST_START : //repeated start
                                         ST_STOP;
            end
        endcase    
    end //end if(clk_en)        
end
/*******************************************************************************/
// sda & scl generation
/*******************************************************************************/
wire [11:0] clk_cnt_nxt;
assign clk_cnt_nxt = clk_en ? 12'b0 : (clk_cnt + 1'b1);

wire clk_en_nxt;
assign clk_en_nxt = (clk_cnt == CLK_DIV);

wire scl_t_nxt;
wire scl_en;    // output enable 
assign scl_en    = (dev_addr_st | reg_addr_st | wr_byte_st |
                   rd_byte_st  | tx_ack_st | rx_ack_st | stop_st);
assign scl_t_nxt = scl_low_st ? 1'b0 :
                   ((~scl_en) | wait_scl_st)  ? 1'b1 : 
                   (clk_cnt == 12'b0) ? 1'b0 :
                   (clk_cnt == HALF_DIV) ? 1'b1 : scl_t;

wire sda_t_clken;
wire sda_t_nxt;
assign sda_t_clken = (clk_cnt == QUAL_DIV); //Ja& (start_st | wr_byte_st | tx_ack_st | stop_st);
assign sda_t_nxt   = (stop_st & clk_en)  ? 1'b1 :
                     (!sda_t_clken)      ? sda_t :
                      stop_st            ? 1'b0   :
                     (start_st | tx_ack_st) ? 1'b0  :
                     (dev_addr_st | reg_addr_st | wr_byte_st) ? wr_bit : 1'b1 ;
                     //(stop_st | sda_high_st) ? 1'b0  :sda_t; //TODO

//arbition error
wire arb_err_nxt;
wire tx_mismatch;
assign tx_mismatch = clk_en & (dev_addr_st | reg_addr_st | wr_byte_st |tx_ack_st) &
                     (iic_sda_i == sda_t); 
assign arb_err_nxt = tx_mismatch & (~idle_st); 

//ack error
wire ack_nxt;
assign ack_nxt =  (clk_en & stop_st) ? 1'b1 : 1'b0;

wire ack_err_nxt;
assign ack_err_nxt = (clk_en & rx_ack_st & iic_sda_i) ? 1'b1 :
                      idle_st                         ? 1'b0 : ack_err;
/*******************************************************************************/
// data manipulations
/*******************************************************************************/
wire cmd_type_nxt;
assign cmd_type_nxt = (clk_en & start_st) ? (~raddr_pending) & (~wdata_pending) : cmd_type;

//Write data control
wire [3:0] byte_mask_nxt;
assign byte_mask_nxt = (~clk_en | bit_pending)  ? byte_mask :
                       (start_st | stop_st ) ? 4'b1000 :
                       (reg_addr_st & (raddr_ben== 4'h8)) ? 4'b1000 :
                       (wr_byte_st  & (wdata_ben== 4'h8)) ? 4'b1000 :
                       (rd_byte_st  & (rdata_ben== 4'h8)) ? 4'b1000 :
                       (rd_byte_st |reg_addr_st |wr_byte_st)? {1'b0,byte_mask[3:1]} :
                                           byte_mask;


wire [3:0] raddr_ben_nxt;
assign raddr_ben_nxt = (~clk_en)   ? raddr_ben :
                       idle_st     ? iic_raddr_ben :
                       dev_addr_st ? (cmd_type ? 4'b0 :raddr_ben) :
                       (reg_addr_st & ~bit_pending) ? {raddr_ben[2:0],1'b0} :
                                     raddr_ben;

wire [7:0] raddr_byte_mux;                       
assign raddr_byte_mux = byte_mask[3] ? iic_reg_addr[31:24] :
                        byte_mask[2] ? iic_reg_addr[23:16] :
                          byte_mask[1] ? iic_reg_addr[15:8]  :
                                       iic_reg_addr[7:0];

wire [3:0] wdata_ben_nxt;
assign wdata_ben_nxt = (~clk_en)   ? wdata_ben :
                       idle_st     ? iic_wdata_ben :
                       dev_addr_st ? (cmd_type ? 4'b0 : wdata_ben) :
                       (wr_byte_st & ~bit_pending) ? {wdata_ben[2:0],1'b0} :
                                     wdata_ben;

wire [7:0] wdata_byte_mux;                       
assign wdata_byte_mux = byte_mask[3] ? iic_wdata[31:24] :
                        byte_mask[2] ? iic_wdata[23:16] :
                          byte_mask[1] ? iic_wdata[15:8]  :
                                       iic_wdata[7:0];

wire [7:0] wr_dbyte_nxt;
assign wr_dbyte_nxt = (~clk_en)   ? wr_dbyte :
                      start_st    ? {iic_dev_addr, cmd_type_nxt} :
                      (rx_ack_st & raddr_pending) ? raddr_byte_mux :
                      (rx_ack_st & wdata_pending) ? wdata_byte_mux : wr_dbyte;

wire [2:0] bit_cnt_nxt; 
assign bit_cnt_nxt = (!clk_en) ? bit_cnt :
                     (dev_addr_st | reg_addr_st | wr_byte_st | rd_byte_st) ? (bit_cnt - 1'b1) :
                     3'h7;                                           
assign bit_pending = (|bit_cnt); 

assign wr_bit_mux = (bit_cnt == 3'h7) ? wr_dbyte[7] :  
                    (bit_cnt == 3'h6) ? wr_dbyte[6] :  
                    (bit_cnt == 3'h5) ? wr_dbyte[5] :  
                    (bit_cnt == 3'h4) ? wr_dbyte[4] :  
                    (bit_cnt == 3'h3) ? wr_dbyte[3] :  
                    (bit_cnt == 3'h2) ? wr_dbyte[2] :  
                    (bit_cnt == 3'h1) ? wr_dbyte[1] :  
                                        wr_dbyte[0] ;  
assign wr_bit = wr_bit_mux;

//read data control
wire [3:0] rdata_ben_nxt;
assign rdata_ben_nxt = (~clk_en) ? rdata_ben :
                       idle_st   ? iic_rdata_ben :
                       (rd_byte_st & ~bit_pending)? {rdata_ben[2:0],1'b0} :
                                   rdata_ben;

wire       rd_clk_en;
wire [7:0] rd_byte_nxt;

assign rd_clk_en = (clk_cnt == HALF_DIV) & rd_byte_st;
assign rd_byte_nxt = rd_clk_en ? ({rd_byte[6:0],iic_sda_i}) : rd_byte; 

wire         rdata_clken;
wire [7:0]   rbyte0,rbyte1,rbyte2,rbyte3;
wire [31:0]  rdata_nxt;

assign rdata_clken = (rd_byte_st & clk_en & ~bit_pending);
assign rbyte3 = (rdata_clken & byte_mask[3]) ? rd_byte : rdata[31:24];   
assign rbyte2 = (rdata_clken & byte_mask[2]) ? rd_byte : rdata[23:16];   
assign rbyte1 = (rdata_clken & byte_mask[1]) ? rd_byte : rdata[15:8];   
assign rbyte0 = (rdata_clken & byte_mask[0]) ? rd_byte : rdata[7:0];   
assign rdata_nxt  = {rbyte3,rbyte2,rbyte1,rbyte0};

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

`XSRREG(clk, rst, c_st, nxt_st, ST_IDLE)
`XSRREG(clk, rst, clk_cnt, clk_cnt_nxt, 12'b0)
`XSRREG(clk, rst, clk_en, clk_en_nxt, 1'b0)
`XSRREG(clk, rst, scl_t, scl_t_nxt, 1'b1)
`XSRREG(clk, rst, sda_t, sda_t_nxt, 1'b1)
`XSRREG(clk, rst, arb_err, arb_err_nxt, 1'b0)
`XSRREG(clk, rst, ack ,ack_nxt, 1'b0)
`XSRREG(clk, rst, ack_err ,ack_err_nxt, 1'b0)
`XSRREG(clk, rst, cmd_type, cmd_type_nxt, 1'b0)
`XSRREG(clk, rst, byte_mask, byte_mask_nxt, 4'b1000)
`XSRREG(clk, rst, raddr_ben, raddr_ben_nxt, 4'b0)
`XSRREG(clk, rst, wdata_ben, wdata_ben_nxt, 4'b0)
`XSRREG(clk, rst, wr_dbyte, wr_dbyte_nxt, 8'b0)
`XSRREG(clk, rst, bit_cnt, bit_cnt_nxt, 3'h7)
`XSRREG(clk, rst, rdata_ben, rdata_ben_nxt, 4'b0)
`XSRREG(clk, rst, rd_byte,rd_byte_nxt, 8'b0)
`XSRREG(clk, rst, rdata,rdata_nxt, 32'b0)

endmodule


//TODO arbitration based on spec
