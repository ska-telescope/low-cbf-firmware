////------------------------------------------------------------------------------
////  (c) Copyright 2013 Xilinx, Inc. All rights reserved.
////
////  This file contains confidential and proprietary information
////  of Xilinx, Inc. and is protected under U.S. and
////  international copyright and other intellectual property
////  laws.
////
////  DISCLAIMER
////  This disclaimer is not a license and does not grant any
////  rights to the materials distributed herewith. Except as
////  otherwise provided in a valid license issued to you by
////  Xilinx, and to the maximum extent permitted by applicable
////  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
////  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
////  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
////  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
////  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
////  (2) Xilinx shall not be liable (whether in contract or tort,
////  including negligence, or under any other theory of
////  liability) for any loss or damage of any kind or nature
////  related to, arising under or in connection with these
////  materials, including for any direct, or any indirect,
////  special, incidental, or consequential loss or damage
////  (including loss of data, profits, goodwill, or any type of
////  loss or damage suffered as a result of any action brought
////  by a third party) even if such damage or loss was
////  reasonably foreseeable or Xilinx had been advised of the
////  possibility of the same.
////
////  CRITICAL APPLICATIONS
////  Xilinx products are not designed or intended to be fail-
////  safe, or for use in any application requiring fail-safe
////  performance, such as life-support or safety devices or
////  systems, Class III medical devices, nuclear facilities,
////  applications related to the deployment of airbags, or any
////  other applications that could lead to death, personal
////  injury, or severe property or environmental damage
////  (individually and collectively, "Critical
////  Applications"). Customer assumes the sole risk and
////  liability of any use of Xilinx products in Critical
////  Applications, subject only to applicable laws and
////  regulations governing limitations on product liability.
////
////  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
////  PART OF THIS FILE AT ALL TIMES.
////------------------------------------------------------------------------------

`timescale 1fs/1fs
(* DowngradeIPIdentifiedWarnings="yes" *)

module ip_xcku040_mac10g_noaxi_buf (
  input  wire clk,
  input  wire reset,
  input wire [63:0] tx_datain,
  input wire tx_enain,
  input wire tx_sopin,
  input wire tx_eopin,
  input wire tx_errin,
  input wire [2:0] tx_mtyin,

  output wire [63:0] tx_dataout,
  output wire tx_enaout,
  output wire tx_sopout,
  output wire tx_eopout,
  output wire tx_errout,
  output wire [2:0] tx_mtyout,
  input  wire tx_rdyin,
  output  reg tx_rdyout
);

parameter integer IS_0_LATENCY = 0;                      // default to single cycle latency
reg [70:0] rd_buf[0:7];
reg [2:0] waddr;

generate
if ( IS_0_LATENCY ) begin               // If this is a zero latency implementation

reg [2:0] waddr_p1;


wire my_tx_enaout;
assign { tx_dataout, my_tx_enaout, tx_sopout, tx_eopout, tx_errout, tx_mtyout } = rd_buf[0];
assign tx_enaout = my_tx_enaout;

integer i;
always @( posedge clk )
    begin
      if ( reset == 1'b1 ) begin
        waddr <= 3'h0;
        waddr_p1 <= 3'h1;
        tx_rdyout <= 0;
        for(i=0;i<8;i=i+1) rd_buf[i] <= 71'h0;
      end
      else begin

        if(tx_rdyin) for(i=1;i<8;i=i+1) rd_buf[i-1] <= rd_buf[i];

        tx_rdyout <= (waddr < 3'd4 );

        case({|tx_enain,tx_rdyin})
          2'b01: begin
                   waddr <=  |waddr ? waddr-1 : waddr  ;
                   waddr_p1 <= |waddr ? waddr : 3'h1;
                 end
          2'b10: begin
                   rd_buf[waddr_p1] <= { tx_datain, tx_enain, tx_sopin, tx_eopin, tx_errin, tx_mtyin };
                   waddr <= ( &waddr_p1 ? waddr : waddr + 1 ) ;
                   waddr_p1 <= ( &waddr_p1 ? waddr_p1 : waddr + 2 ) ;
                 end
          2'b11: rd_buf[waddr] <= { tx_datain, tx_enain, tx_sopin, tx_eopin, tx_errin, tx_mtyin };
        endcase
      end
    end

end             // End of zero latency block
else begin      // Begining of single cycle latency block

reg [63:0] loc_tx_dataout;
reg loc_tx_enaout;
reg loc_tx_sopout;
reg loc_tx_eopout;
reg loc_tx_errout;
reg [2:0] loc_tx_mtyout;

reg [70:0] qd1;
wire [70:0] rd1;
reg [2:0] raddr;

assign { tx_dataout, tx_enaout, tx_sopout, tx_eopout, tx_errout, tx_mtyout } = { loc_tx_dataout, loc_tx_enaout, loc_tx_sopout, loc_tx_eopout, loc_tx_errout, loc_tx_mtyout } ;

integer i;
always @( posedge clk )
    begin
      if ( reset == 1'b1 ) begin
        qd1 <= 71'h0;
        waddr <= 3'h0;
        raddr <= 3'h0;
        tx_rdyout <= 0;
        for(i=0;i<8;i=i+1) rd_buf[i] <= 71'h0;
        { loc_tx_dataout, loc_tx_enaout, loc_tx_sopout, loc_tx_eopout, loc_tx_errout, loc_tx_mtyout } <= 71'h0;
      end
      else begin
        if(tx_rdyin && (raddr != waddr) ) begin
          { loc_tx_dataout, loc_tx_enaout, loc_tx_sopout, loc_tx_eopout, loc_tx_errout, loc_tx_mtyout } <= rd_buf[raddr];
          raddr <= ( raddr + 1 ) % 8 ;
        end
        else begin
          { loc_tx_dataout, loc_tx_enaout, loc_tx_sopout, loc_tx_eopout, loc_tx_errout, loc_tx_mtyout } <= 71'hx;
          loc_tx_enaout <= 0;
        end
        tx_rdyout <= tx_rdyin;
        if(|tx_enain)begin
          rd_buf[waddr] <= { tx_datain, tx_enain, tx_sopin, tx_eopin, tx_errin, tx_mtyin };
          waddr <= ( waddr + 1 ) % 8 ;
        end
      end
    end

end
endgenerate

endmodule
