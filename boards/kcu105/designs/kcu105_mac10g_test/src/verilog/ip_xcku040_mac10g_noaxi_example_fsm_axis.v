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

module ip_xcku040_mac10g_noaxi_example_fsm_axis #( 
 parameter VL_LANES_PER_GENERATOR = 1
) (
input wire dclk,
input wire fsm_reset,
input wire [VL_LANES_PER_GENERATOR-1:0] stat_rx_block_lock,
input wire [VL_LANES_PER_GENERATOR-1:0] stat_rx_synced,
input wire stat_rx_aligned,
input wire stat_rx_status,
input wire tx_timeout,
input wire tx_done,
input wire ok_to_start,

input wire [47:0] rx_packet_count,
input wire [63:0] rx_total_bytes,
input wire  rx_errors,
input wire  rx_data_errors,
input wire [47:0] tx_sent_count,
input wire [63:0] tx_total_bytes,


output reg sys_reset,
output reg pktgen_enable,

output reg [4:0] completion_status
);


`ifdef SIM_SPEED_UP
 parameter [31:0] STARTUP_TIME = 32'd5000;
`else
 parameter [31:0] STARTUP_TIME = 32'd50_000;
`endif
 parameter        GENERATOR_COUNT = 1;
 parameter [4:0]   NO_START = {5{1'b1}},
                   TEST_START = 5'd0,
                   SUCCESSFUL_COMPLETION = 5'd1,
                   NO_BLOCK_LOCK = 5'd2,
                   PARTIAL_BLOCK_LOCK = 5'd3,
                   INCONSISTENT_BLOCK_LOCK = 5'd4,
                   NO_LANE_SYNC = 5'd5,
                   PARTIAL_LANE_SYNC = 5'd6,
                   INCONSISTENT_LANE_SYNC = 5'd7,
                   NO_ALIGN_OR_STATUS = 5'd8,
                   LOSS_OF_STATUS = 5'd9,
                   TX_TIMED_OUT = 5'd10,
                   NO_DATA_SENT = 5'd11,
                   SENT_COUNT_MISMATCH = 5'd12,
                   BYTE_COUNT_MISMATCH = 5'd13,
                   LBUS_PROTOCOL = 5'd14,
                   BIT_ERRORS_IN_DATA = 5'd15;

/* Parameter definitions of STATE variables for 5 bit state machine */
localparam [4:0]  S0 = 5'b00000,     // S0 = 0
                  S1 = 5'b00001,     // S1 = 1
                  S2 = 5'b00011,     // S2 = 3
                  S3 = 5'b00010,     // S3 = 2
                  S4 = 5'b00110,     // S4 = 6
                  S5 = 5'b00111,     // S5 = 7
                  S6 = 5'b00101,     // S6 = 5
                  S7 = 5'b00100,     // S7 = 4
                  S8 = 5'b01100,     // S8 = 12
                  S9 = 5'b01101,     // S9 = 13
                  S10 = 5'b01111,     // S10 = 15
                  S11 = 5'b01110,     // S11 = 14
                  S12 = 5'b01010,     // S12 = 10
                  S13 = 5'b01011,     // S13 = 11
                  S14 = 5'b01001,     // S14 = 9
                  S15 = 5'b01000,     // S15 = 8
                  S16 = 5'b11000,     // S16 = 24
                  S17 = 5'b11001;     // S17 = 25


reg [4:0] state ;
reg [31:0] common_timer;
reg rx_packet_count_mismatch;
reg rx_byte_count_mismatch;
reg rx_non_zero_error_count;
reg tx_zero_sent;

always @( posedge dclk )
    begin
      if ( fsm_reset == 1'b1 ) begin
        common_timer <= 0;
        state <= S0;
        sys_reset <= 1'b0 ;
        pktgen_enable <= 1'b0;
        completion_status <= NO_START ;
        rx_packet_count_mismatch <= 0;
        rx_byte_count_mismatch <= 0;
        rx_non_zero_error_count <= 0;
        tx_zero_sent <= 0;
      end
      else begin :check_loop
        integer i;
        common_timer <= |common_timer ? common_timer - 1 : common_timer;
        rx_non_zero_error_count <=  rx_data_errors ;
        rx_packet_count_mismatch <= 0;
        rx_byte_count_mismatch <= 0;
        tx_zero_sent <= 0;
        for ( i = 0; i < GENERATOR_COUNT; i=i+1 ) begin
          if ( tx_total_bytes[(64 * i)+:64] != rx_total_bytes[(64 * i)+:64] ) rx_byte_count_mismatch <= 1'b1;
          if ( tx_sent_count[(48 * i)+:48] != rx_packet_count[(48 * i)+:48] ) rx_packet_count_mismatch <= 1'b1;         // Check all generators for received counts equal transmitted count
          if ( ~|tx_sent_count[(48 * i)+:48] ) tx_zero_sent <= 1'b1;                                                       // If any channel fails to send any data, flag zero-sent
        end
        case ( state )
          S0: state <= ok_to_start ? S1 : S0;
          S1: begin
`ifdef SIM_SPEED_UP
                common_timer <= cvt_us ( 32'd100 );               // If this is the example simulation then only wait for 100 us
`else
                common_timer <= cvt_us ( 32'd10_000 );               // Wait for 10ms...do nothing; settling time for MMCs, oscilators, QPLLs etc.
`endif
                completion_status <= TEST_START;
                state <= S2;
              end
          S2: state <= (|common_timer) ? S2 : S3;
          S3: begin
                common_timer <= 3;
                sys_reset <= 1'b1;
                state <= S4;
              end
          S4: state <= (|common_timer) ? S4 : S5;
          S5: begin
                common_timer <= cvt_us( 5 );                    // Allow about 5 us for the reset to propagate into the downstream hardware
                sys_reset <= 1'b0;     // Clear the reset
                state <= S16;
              end
         S16: state <= (|common_timer) ? S16 : S17;
         S17: begin
                common_timer <= cvt_us( STARTUP_TIME );            // Set 20ms wait period
                state <= S6;
              end
          S6: if(|common_timer) state <= |stat_rx_block_lock ? S7 : S6 ;
              else begin
                state <= S15;
                completion_status <= NO_BLOCK_LOCK;
              end
          S7: if(|common_timer) state <= &stat_rx_block_lock ? S8 : S7 ;
              else begin
                state <= S15;
                completion_status <= PARTIAL_BLOCK_LOCK;
              end
          S8: if(|common_timer) begin
                if( ~&stat_rx_block_lock ) begin
                  state <= S15;
                  completion_status <= INCONSISTENT_BLOCK_LOCK;
                end
                else state <= |stat_rx_synced ? S9 : S8 ;
              end
              else begin
                state <= S15;
                completion_status <= NO_LANE_SYNC;
              end
          S9: if(|common_timer) begin
                if( ~&stat_rx_block_lock ) begin
                  state <= S15;
                  completion_status <= INCONSISTENT_BLOCK_LOCK;
                end
                else state <= &stat_rx_synced ? S10 : S9 ;
              end
              else begin
                state <= S15;
                completion_status <= PARTIAL_LANE_SYNC;
              end
          S10: if(|common_timer) begin
                if( ~&stat_rx_block_lock ) begin
                  state <= S15;
                  completion_status <= INCONSISTENT_BLOCK_LOCK;
                end
                else if( ~&stat_rx_synced ) begin
                  state <= S15;
                  completion_status <= INCONSISTENT_LANE_SYNC;
                end
                else begin
                  state <= (stat_rx_aligned && stat_rx_status ) ? S11 : S10 ;
                end
              end
              else begin
                state <= S15;
                completion_status <= NO_ALIGN_OR_STATUS;
              end
          S11: begin
                 state <= S12;
`ifdef SIM_SPEED_UP
                 common_timer <= cvt_us( 32'd50 );            // Set 50us wait period while aligned (simulation only )
`else
                 common_timer <= cvt_us( 32'd1_000 );            // Set 1ms wait period while aligned
`endif
               end
          S12: if(|common_timer) begin
                 if( ~&stat_rx_block_lock || ~&stat_rx_synced || ~stat_rx_aligned || ~stat_rx_status ) begin
                   state <= S15;
                   completion_status <= LOSS_OF_STATUS;
                 end
               end
               else begin
                state <= S13;
                pktgen_enable <= 1'b1;                          // Turn on the packet generator
`ifdef SIM_SPEED_UP
                common_timer <= cvt_us( 32'd200 );            
`else
                common_timer <= cvt_us( 32'd10_000 );
`endif
              end
          S13: if(|common_timer) begin
                 if( ~&stat_rx_block_lock || ~&stat_rx_synced || ~stat_rx_aligned || ~stat_rx_status ) begin
                   state <= S15;
                   completion_status <= LOSS_OF_STATUS;
                 end
               end
               else state <= S14;
          S14: begin
                 state <= S15;
                 completion_status <= SUCCESSFUL_COMPLETION;
                 if(tx_timeout || ~tx_done) completion_status <= TX_TIMED_OUT;
                 else if(rx_packet_count_mismatch) completion_status <= SENT_COUNT_MISMATCH;
                 else if(rx_byte_count_mismatch) completion_status <= BYTE_COUNT_MISMATCH;
                 else if(rx_errors) completion_status <= LBUS_PROTOCOL;
                 else if(rx_non_zero_error_count) completion_status <= BIT_ERRORS_IN_DATA;
                 else if(tx_zero_sent) completion_status <= NO_DATA_SENT;
               end
          S15: state <= S15;            // Finish and wait forever
        endcase
      end
    end


function [31:0] cvt_us( input [31:0] d );
cvt_us = ( ( d * 300 ) + 3 ) / 4 ;
endfunction

endmodule

