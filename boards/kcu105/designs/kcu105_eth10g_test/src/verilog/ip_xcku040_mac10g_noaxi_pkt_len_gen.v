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

module ip_xcku040_mac10g_noaxi_pkt_len_gen (
  input  wire clk,
  input  wire reset,
  input  wire enable,
  output reg [16:0] pkt_len
  );

  parameter integer min=64;   // in bytes
  parameter integer max=9000; // in bytes
localparam integer pkt_diff = max - min + 1;

localparam [32:0] CRC_POLYNOMIAL = 33'b100001000001010000000010010000001;
localparam [31:0] init_crc = 32'b11010111011110111101100110001011;

reg [31:0] p1[0:15], p2[0:7], p3[0:3], p4[0:1], p5;

reg [31:0] CRC;

integer i;
always @( posedge clk or posedge reset )
    begin
      if ( reset == 1'b1 ) begin
    for(i=0;i<16;i=i+1) p1[i]<=0;
    for(i=0;i<8;i=i+1)  p2[i]<=0;
    for(i=0;i<4;i=i+1)  p3[i]<=0;
    for(i=0;i<2;i=i+1)  p4[i]<=0;
                        p5   <=0;
    CRC <= init_crc;
  end
  else begin
    if(enable)begin
      for(i=0;i<16;i=i+1) p1[i] <= CRC[i] ? (pkt_diff << i) : 0;
      for(i=0;i<16;i=i+2) p2[i/2] <= p1[i] + p1[i+1];
      for(i=0;i<16;i=i+4) p3[i/4] <= p2[i/2] + p2[i/2+1];
      for(i=0;i<16;i=i+8) p4[i/8] <= p3[i/4] + p3[i/4+1];
      p5 <= p4[0] + p4[1];
      pkt_len <= {1'b0,p5[31:16]} + min;
      CRC <= {CRC,^(CRC_POLYNOMIAL & {CRC,1'b0})};
    end
  end
end


endmodule

