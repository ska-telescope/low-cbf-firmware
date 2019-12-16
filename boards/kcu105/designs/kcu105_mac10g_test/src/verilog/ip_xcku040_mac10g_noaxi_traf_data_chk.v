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

module ip_xcku040_mac10g_noaxi_traf_data_chk (

  input wire clk,
  input wire reset,
  input wire enable,
  input wire clear_count,

  input wire [63:0] rx_dataout,
  input wire rx_enaout,
  input wire rx_sopout,
  input wire rx_eopout,
  input wire rx_errout,
  input wire [2:0] rx_mtyout,

  output wire [31:0] error_count,
  output wire error_overflow,
  output wire [511:0] packet,
  output wire packet_avail,
  input wire packet_avail_reset
);
reg [32:0] err_cntr;
assign error_count            = err_cntr[32] ? {32{1'b1}} : err_cntr[31:0],
       error_overflow         = err_cntr[32];

localparam [15:0]  icmp_reply   = 16'h00_00;

localparam [47:0] dest_addr   = 48'h00_60_DD_46_DE_E3;  // perseus.atnf.csiro.au  (10G NIC)
localparam [47:0] source_addr = 48'h11_22_33_44_55_66;  // me
localparam [15:0] eth_type    = 16'h0800;               // eth type = IP
localparam [111:0] eth_header = { dest_addr, source_addr, eth_type} ;

/* Parameter definitions of STATE variables for 1 bit state machine */
localparam [1:0]  S0 = 2'b00,
                  S1 = 2'b01,
                  S2 = 2'b11,
                  S3 = 2'b10;
reg [1:0] state[0:2];
reg [7:0] header_bit_count ;

reg [31:0] crc_ip1;
reg [31:0] crc_ip2[0:1];
wire [31:0] nxt_crc;
reg set_derr;

wire [ 63:0] dat1,dat2;
wire [ 63:0] exp1,exp2;

ip_xcku040_mac10g_noaxi_payload_gen
 #(
  .BIT_COUNT ( 64 )
) i_PKTPRBS_GEN1 (
  .ip         ( crc_ip1 ),
  .op         (  ),
  .datout     ( dat1 )
);

ip_xcku040_mac10g_noaxi_payload_gen
 #(
  .BIT_COUNT ( 64 )
) i_PKTPRBS_GEN2 (
  .ip         ( crc_ip2[1] ),
  .op         ( nxt_crc ),
  .datout     ( dat2 )
);

assign exp1 = swapn ( dat1 ) ;
assign exp2 = swapn ( dat2 ) ;

reg [ 63:0] zzmask[0:2];
reg [ 63:0] cmpr[0:2];
reg [ 63:0] d_dat[0:7];
reg [2:0] d_ena;
reg [2:0] d_sop;
reg [2:0] d_eop;
reg [2:0] v_pkt;

reg [511:0] packet_reg;
reg packet_avail_reg;
reg packet_copy_reg;
reg [2:0] d_dat_idx;

integer i;

assign packet = packet_reg;
assign packet_avail = packet_avail_reg;

always @( posedge clk )
    begin
      if ( reset == 1'b1 ) begin
        set_derr <= 0;
        crc_ip1 <= 0;
        crc_ip2[0] <= 0;
        crc_ip2[1] <= 0;
        err_cntr <= 33'h0;
        d_ena <= 0;
        d_sop <= 0;
        d_eop <= 0;
        v_pkt <= 0;
        header_bit_count <= 8'd111;
        for (i=0; i<=2; i=i+1) state[i] <= S0;

        for (i=0; i<=2; i=i+1) zzmask[i] <= 64'h0;
        for (i=0; i<=2; i=i+1) cmpr[i] <= 64'h0;
        for (i=0; i<=7; i=i+1) d_dat[i] <= 64'h0;

        packet_reg <= 512'h0;
        packet_avail_reg <= 0;
        packet_copy_reg <= 0;
        d_dat_idx <= 0;

      end
      else begin :read_loop
        reg loc_sop,loc_eop;
        loc_sop = |( rx_enaout & rx_sopout ) ;
        loc_eop = |( rx_enaout & rx_eopout ) ;

        d_ena <= {d_ena, |rx_enaout && enable};
        d_sop <= {d_sop, loc_sop };
        d_eop <= {d_eop, loc_eop };
        v_pkt <= {v_pkt, ( loc_sop || v_pkt[0] ) && ~loc_eop};
        for (i=1; i<=2; i=i+1) state[i] <= state[i-1] ;

        if(rx_enaout) begin
            d_dat[d_dat_idx] <= rx_dataout;
            d_dat_idx <= d_dat_idx+1;
        end

        for (i=1; i<=2; i=i+1) zzmask[i] <= zzmask[i-1] ;
        for (i=1; i<=2; i=i+1) cmpr[i] <= cmpr[i-1] ;
        //for (i=1; i<=8; i=i+1) d_dat[i] <= d_dat[i-1] ;
        zzmask[0] <= loc_eop ? {64{1'b1}} << {rx_mtyout,3'd0} : {64{1'b1}};
        if(rx_enaout) begin
          if ( rx_sopout || v_pkt[0] ) header_bit_count <= ( header_bit_count <= 64 ) ? 0 : header_bit_count - 64 ;
          else header_bit_count <= 111 ;
        end

        if(rx_enaout) case ( state[0] )
          S0: if ( rx_sopout && !rx_eopout ) state[0] <= S1;
          S1: if ( ( header_bit_count < 64 ) && !rx_eopout ) state[0] <= S2;
          S2: if ( rx_sopout || rx_eopout || ~v_pkt[0] ) state[0] <= S0 ;
              else if ( v_pkt[0] && !rx_eopout ) state[0] <= S3 ;
          S3: if ( rx_sopout || rx_eopout || ~v_pkt[0] ) state[0] <= S0 ;
        endcase

        case ( state[0] )
          S0: cmpr[0] <= eth_header[111-:64] ;
          S1: crc_ip1 <= crc_swapn(rx_dataout[0+:32]) << 16 ;
          S2: crc_ip1[0+:16] <= crc_swapn(rx_dataout[63-:32]) >> 16 ;
          default: crc_ip1 <= 32'hx;
        endcase

        if(loc_eop) begin
            packet_copy_reg <= 1;
            d_dat_idx <= 0;
        end
        if(loc_sop | packet_avail_reset) begin
            packet_avail_reg <= 0;
        end
        if(packet_copy_reg) begin
            packet_reg <= {d_dat[0][15:0],d_dat[1][63:32],d_dat[0][63:16],d_dat[1][31:0],d_dat[2],d_dat[3][63:48],d_dat[3][15:0],d_dat[4][63:48],d_dat[3][47:16],icmp_reply,d_dat[4][31:0],d_dat[5],d_dat[6],d_dat[7]}; // swap src/dest
            //             |<------- dest ------------->| |<--- src --->| |-0800 4500--| |<---->| |<----------->| |<- ipsrc ------------------>| |<--ipdest -->|        
            //             |0                                 0||1                    1| |2    2| |3                                                    3||4                  4| |5    5| |6    6| |7    7|
            packet_avail_reg <= 1;
            packet_copy_reg <= 0;
        end


        case (state[1])
          S1: begin
                 cmpr[1] <= { eth_header[0+:48],16'h0} ;
                 zzmask[1][0+:16] <= 16'h0;
              end
          S2: begin
                 cmpr[1] <= {16'h0,exp1[63-:48]};
                 zzmask[1][63-:16] <= 16'h0;
              end
          S3: cmpr[1] <= exp2;
        endcase


        if (rx_enaout) crc_ip2[0] <= crc_swapn(rx_dataout[0+:32]);
        if(d_ena[0]) case (state[1])
          S2:       crc_ip2[1] <= crc_ip2[0];
          default:  crc_ip2[1] <= nxt_crc;
        endcase

        set_derr <= |{(cmpr[1] ^ d_dat[1]) & zzmask[1] } && d_ena[1] && |v_pkt[1+:2];
        if(set_derr && !err_cntr[32]) err_cntr <= err_cntr + 1;

        if(clear_count) err_cntr <= 33'h0;

      end
    end

function [63:0]  swapn (input [63:0]  d);
integer i;
for (i=0; i<=(63); i=i+8) swapn[i+:8] = d[(63-i)-:8];
endfunction

function [31:0] crc_swapn (input [31:0] d);
integer i;
for (i=0; i<=31; i=i+1) crc_swapn[i] = d[{i[5:3],~i[2:0]}];
endfunction


endmodule
