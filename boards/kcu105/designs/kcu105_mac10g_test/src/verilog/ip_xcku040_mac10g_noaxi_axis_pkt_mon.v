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

module ip_xcku040_mac10g_noaxi_axis_pkt_mon (

  input wire clk,
  input wire reset,
  input wire clear_count,
  input wire sys_reset,
//// RX Control Signals
//  output wire ctl_rx_test_pattern,
//  output wire ctl_rx_test_pattern_enable,
//  output wire ctl_rx_data_pattern_select,
//  output wire ctl_rx_enable,
//  output wire ctl_rx_delete_fcs,
//  output wire ctl_rx_ignore_fcs,
//  output wire [14:0] ctl_rx_max_packet_len,
//  output wire [7:0] ctl_rx_min_packet_len,
//  output wire ctl_rx_custom_preamble_enable,
//  output wire ctl_rx_check_sfd,
//  output wire ctl_rx_check_preamble,
//  output wire ctl_rx_process_lfi,
//  output wire ctl_rx_force_resync,

//  output wire ctl_rx_forward_control,
//  output wire [8:0] ctl_rx_pause_ack,
//  output wire ctl_rx_check_ack,
//  output wire [8:0] ctl_rx_pause_enable,
//  output wire ctl_rx_enable_gcp,
//  output wire ctl_rx_check_mcast_gcp,
//  output wire ctl_rx_check_ucast_gcp,
//  output wire [47:0] ctl_rx_pause_da_ucast,
//  output wire ctl_rx_check_sa_gcp,
//  output wire [47:0] ctl_rx_pause_sa,
//  output wire ctl_rx_check_etype_gcp,
//  output wire [15:0] ctl_rx_etype_gcp,
//  output wire ctl_rx_check_opcode_gcp,
//  output wire [15:0] ctl_rx_opcode_min_gcp,
//  output wire [15:0] ctl_rx_opcode_max_gcp,
//  output wire ctl_rx_enable_pcp,
//  output wire ctl_rx_check_mcast_pcp,
//  output wire ctl_rx_check_ucast_pcp,
//  output wire [47:0] ctl_rx_pause_da_mcast,
//  output wire ctl_rx_check_sa_pcp,
//  output wire ctl_rx_check_etype_pcp,
//  output wire [15:0] ctl_rx_etype_pcp,
//  output wire ctl_rx_check_opcode_pcp,
//  output wire [15:0] ctl_rx_opcode_min_pcp,
//  output wire [15:0] ctl_rx_opcode_max_pcp,
//  output wire ctl_rx_enable_gpp,
//  output wire ctl_rx_check_mcast_gpp,
//  output wire ctl_rx_check_ucast_gpp,
//  output wire ctl_rx_check_sa_gpp,
//  output wire ctl_rx_check_etype_gpp,
//  output wire [15:0] ctl_rx_etype_gpp,
//  output wire ctl_rx_check_opcode_gpp,
//  output wire [15:0] ctl_rx_opcode_gpp,
//  output wire ctl_rx_enable_ppp,
//  output wire ctl_rx_check_mcast_ppp,
//  output wire ctl_rx_check_ucast_ppp,
//  output wire ctl_rx_check_sa_ppp,
//  output wire ctl_rx_check_etype_ppp,
//  output wire [15:0] ctl_rx_etype_ppp,
//  output wire ctl_rx_check_opcode_ppp,
//  output wire [15:0] ctl_rx_opcode_ppp,

//// RX Stats Signals
  input  wire stat_rx_block_lock,
//  input  wire stat_rx_framing_err_valid,
//  input  wire stat_rx_framing_err,
//  input  wire stat_rx_hi_ber,
//  input  wire stat_rx_valid_ctrl_code,
//  input  wire stat_rx_bad_code,
//  input  wire [1:0] stat_rx_total_packets,
//  input  wire stat_rx_total_good_packets,
//  input  wire [3:0] stat_rx_total_bytes,
//  input  wire [13:0] stat_rx_total_good_bytes,
//  input  wire stat_rx_packet_small,
//  input  wire stat_rx_jabber,
//  input  wire stat_rx_packet_large,
//  input  wire stat_rx_oversize,
//  input  wire stat_rx_undersize,
//  input  wire stat_rx_toolong,
//  input  wire stat_rx_fragment,
//  input  wire stat_rx_packet_64_bytes,
//  input  wire stat_rx_packet_65_127_bytes,
//  input  wire stat_rx_packet_128_255_bytes,
//  input  wire stat_rx_packet_256_511_bytes,
//  input  wire stat_rx_packet_512_1023_bytes,
//  input  wire stat_rx_packet_1024_1518_bytes,
//  input  wire stat_rx_packet_1519_1522_bytes,
//  input  wire stat_rx_packet_1523_1548_bytes,
//  input  wire [1:0] stat_rx_bad_fcs,
//  input  wire stat_rx_packet_bad_fcs,
//  input  wire [1:0] stat_rx_stomped_fcs,
//  input  wire stat_rx_packet_1549_2047_bytes,
//  input  wire stat_rx_packet_2048_4095_bytes,
//  input  wire stat_rx_packet_4096_8191_bytes,
//  input  wire stat_rx_packet_8192_9215_bytes,
//  input  wire stat_rx_bad_preamble,
//  input  wire stat_rx_bad_sfd,
//  input  wire stat_rx_got_signal_os,
//  input  wire stat_rx_test_pattern_mismatch,
//  input  wire stat_rx_truncated,
//  input  wire stat_rx_local_fault,
//  input  wire stat_rx_remote_fault,
//  input  wire stat_rx_internal_local_fault,
//  input  wire stat_rx_received_local_fault,

//  input  wire stat_rx_unicast,
//  input  wire stat_rx_multicast,
//  input  wire stat_rx_broadcast,
//  input  wire stat_rx_vlan,
//  input  wire stat_rx_pause,
//  input  wire stat_rx_user_pause,
//  input  wire stat_rx_inrangeerr,
//  input  wire [8:0] stat_rx_pause_valid,
//  input  wire [15:0] stat_rx_pause_quanta0,
//  input  wire [15:0] stat_rx_pause_quanta1,
//  input  wire [15:0] stat_rx_pause_quanta2,
//  input  wire [15:0] stat_rx_pause_quanta3,
//  input  wire [15:0] stat_rx_pause_quanta4,
//  input  wire [15:0] stat_rx_pause_quanta5,
//  input  wire [15:0] stat_rx_pause_quanta6,
//  input  wire [15:0] stat_rx_pause_quanta7,
//  input  wire [15:0] stat_rx_pause_quanta8,
//  input  wire [8:0] stat_rx_pause_req,
//// RX LBUS Signals
  input wire [64-1:0] rx_dataout,
  input wire rx_enaout,
  input wire rx_sopout,
  input wire rx_eopout,
  input wire rx_errout,
  input wire [3-1:0] rx_mtyout,

 // output wire rx_reset,
  output reg protocol_error,
  output wire [47:0] packet_count,
  output wire [63:0] total_bytes,
  output wire [31:0] prot_err_count,
  output wire [31:0] error_count,
  output wire packet_count_overflow,
  output wire prot_err_overflow,
  output wire error_overflow,
  output wire total_bytes_overflow,
  output reg rx_gt_locked_led,
  output reg rx_block_lock_led 
);
  parameter MIN_LENGTH     = 64;
  parameter MAX_LENGTH     = 9000;
wire   enable;
reg [48:0] pct_cntr;
reg [32:0] perr_cntr, err_cntr;
wire       rx_block_lock;
reg        rx_gt_locked_led_1d;
reg        rx_gt_locked_led_2d;
reg        rx_gt_locked_led_3d;
reg        rx_block_lock_led_1d;
reg        rx_block_lock_led_2d;
reg        rx_block_lock_led_3d;
reg [1:0]  state ;
reg [1:0]  q_en;
reg [3:0]  delta_bytes;
reg [64:0] byte_cntr;
reg        inc_pct_cntr;
reg        inc_err_cntr;

assign enable                     = 1'b1;
//assign rx_reset                   = 1'b0;
assign rx_block_lock              = stat_rx_block_lock;


assign clear_count                = 1'b0;



/* Parameter definitions of STATE variables for 1 bit state machine */
localparam [1:0]  S0 = 2'b00,
                  S1 = 2'b01,
                  S2 = 2'b11,
                  S3 = 2'b10;

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


   //////////////////////////////////////////////////
    ////Registering the LED ports
    //////////////////////////////////////////////////

    always @( posedge clk )
    begin
        if ( reset == 1'b1 )
        begin
            rx_gt_locked_led_1d     <= 1'b0;
            rx_gt_locked_led_2d     <= 1'b0;
            rx_gt_locked_led_3d     <= 1'b0;
            rx_block_lock_led_1d    <= 1'b0;
            rx_block_lock_led_2d    <= 1'b0;
            rx_block_lock_led_3d    <= 1'b0;
        end
        else
        begin
            rx_gt_locked_led_1d     <= ~reset;
            rx_gt_locked_led_2d     <= rx_gt_locked_led_1d;
            rx_gt_locked_led_3d     <= rx_gt_locked_led_2d;
            rx_block_lock_led_1d    <= rx_block_lock;
            rx_block_lock_led_2d    <= rx_block_lock_led_1d;
            rx_block_lock_led_3d    <= rx_block_lock_led_2d;
        end
    end

   //////////////////////////////////////////////////
    ////Assign RX LED Output ports with ASYN sys_reset
    //////////////////////////////////////////////////
    always @( posedge clk, posedge sys_reset  )
    begin
        if ( sys_reset == 1'b1 )
        begin
            rx_gt_locked_led     <= 1'b0;
            rx_block_lock_led    <= 1'b0;
        end
        else
        begin
            rx_gt_locked_led     <= rx_gt_locked_led_3d;
            rx_block_lock_led    <= rx_block_lock_led_3d;
        end
    end


endmodule
