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

module ip_xcku040_mac10g_noaxi_traf_chk1 (
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

  output reg protocol_error,
  output wire [47:0] packet_count,
  output wire [63:0] total_bytes,
  output wire [31:0] prot_err_count,
  output wire [31:0] error_count,
  output wire packet_count_overflow,
  output wire prot_err_overflow,
  output wire error_overflow,
  output wire total_bytes_overflow
);

/* Parameter definitions of STATE variables for 1 bit state machine */
localparam [1:0]  S0 = 2'b00,
                  S1 = 2'b01,
                  S2 = 2'b11,
                  S3 = 2'b10;
reg [48:0] pct_cntr;
reg [32:0] perr_cntr, err_cntr;

reg [1:0] state ;
reg [1:0] q_en;
reg [3:0] delta_bytes;
(* keep = "true" *) reg [64:0] byte_cntr;
reg inc_pct_cntr;
reg inc_err_cntr;

assign packet_count           = pct_cntr[48] ? {48{1'b1}} : pct_cntr[47:0],
       packet_count_overflow  = pct_cntr[48],
       prot_err_count         = perr_cntr[32] ? {32{1'b1}} : perr_cntr[31:0],
       prot_err_overflow      = perr_cntr[32],
       error_count            = err_cntr[32] ? {32{1'b1}} : err_cntr[31:0],
       error_overflow         = err_cntr[32],
       total_bytes            = byte_cntr[64] ? {64{1'b1}} : byte_cntr[63:0],
       total_bytes_overflow   = byte_cntr[64];

integer i;
always @( posedge clk or posedge reset )
    begin
      if ( reset == 1'b1 ) begin
    q_en <= 0;
    state <= S0;
    protocol_error <= 0;
    pct_cntr <= 49'h0;
    err_cntr <= 33'h0;
    perr_cntr <= 33'h0;
    byte_cntr <= 65'h0;
    inc_pct_cntr <= 0;
    inc_err_cntr <= 0;
    delta_bytes <= 0;
  end
  else begin
    delta_bytes <= 0;
    inc_pct_cntr <= 0;
    inc_err_cntr <= 0;
    protocol_error <= 0;
    q_en <= {q_en, enable};

    case (state)
      S0: if (q_en == 2'b01) state <= S1;

      S1: if(rx_enaout)begin
            case({rx_sopout,rx_eopout})
              2'b01: protocol_error <= 1'b1;
              2'b10: begin
                       state <= S2;
                       delta_bytes <= 4'd8;
                     end
              2'b11: begin
                       delta_bytes <= 4'd8 - {1'b0,rx_mtyout} ;
                       inc_pct_cntr <= 1'b1;
                       if(rx_errout) inc_err_cntr <= 1'b1;
                     end
            endcase
          end
      S2: if(rx_enaout)begin
            case({rx_sopout,rx_eopout})
              2'b01: begin
                       delta_bytes <= 4'd8 - {1'b0,rx_mtyout} ;
                       inc_pct_cntr <= 1'b1;
                       if(rx_errout) inc_err_cntr <= 1'b1;
                       state <= S1;
                     end
              2'b10: begin
                       protocol_error <= 1'b1;
                       delta_bytes <= 4'd8;
                     end
              2'b11: begin
                       delta_bytes <= 4'd8 - {1'b0,rx_mtyout} ;
                       if(rx_errout) inc_err_cntr <= 1'b1;
                       inc_pct_cntr <= 1'b1;
                       protocol_error <= 1'b1;
                     end
              default: delta_bytes <= 4'd8;
            endcase
          end
      default: state <= S0;
    endcase

    if(~|q_en) state <= S0;
    if(!byte_cntr[64]) byte_cntr <= byte_cntr + {1'b0,delta_bytes};
    if(protocol_error && !perr_cntr[32]) perr_cntr <= perr_cntr + 1;
    if(inc_pct_cntr && !pct_cntr[48])  pct_cntr <= pct_cntr + 1;
    if(inc_err_cntr && !err_cntr[32]) err_cntr <= err_cntr + 1;
    if(clear_count)begin
      byte_cntr <= 65'h0;
      pct_cntr <= 49'h0;
      err_cntr <= 33'h0;
      perr_cntr <= 33'h0;
    end
  end
end

`ifdef SARANCE_RTL_DEBUG
// pragma translate_off
  reg [8*12-1:0] state_text;                    // Enumerated type conversion to text
  always @(state) case (state)
    S0: state_text = "S0" ;
    S1: state_text = "S1" ;
    S2: state_text = "S2" ;
    S3: state_text = "S3" ;
  endcase
`endif

endmodule
