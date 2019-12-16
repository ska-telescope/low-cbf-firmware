////------------------------------------------------------------------------------
//// Copyright 2015 Xilinx, Inc. All rights reserved.
////
//// This file contains confidential and proprietary information of Xilinx, Inc.
//// and is protected under U.S. and international copyright and other
//// intellectual property laws.
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
////BASR MAC TRAFFIC GENERATOR
module l_ethernet_40G_qsfp_d_0_pkt_gen_mon #(
  parameter PKT_NUM             = 20    //// Many Internal Counters are based on PKT_NUM = 20
) (
    input                      gen_clk,
    input                      mon_clk,
    input                      dclk,
    input                      usr_fsm_clk,
    input                      sys_reset,
    input                      restart_tx_rx,
  //// AXI4 Lite interface ports
    output wire s_axi_aclk,
    output wire s_axi_aresetn,
    output wire [31:0] s_axi_awaddr,
    output wire s_axi_awvalid,
    input  wire s_axi_awready,
    output wire [31:0] s_axi_wdata,
    output wire [3:0] s_axi_wstrb,
    output wire s_axi_wvalid,
    input  wire s_axi_wready,
    input  wire [1:0] s_axi_bresp,
    input  wire s_axi_bvalid,
    output wire s_axi_bready,
    output wire [31:0] s_axi_araddr,
    output wire s_axi_arvalid,
    input  wire s_axi_arready,
    input  wire [31:0] s_axi_rdata,
    input  wire [1:0] s_axi_rresp,
    input  wire s_axi_rvalid,
    output wire s_axi_rready,
    output wire pm_tick,
//// RX Signals
    output wire         rx_reset,
    input  wire         user_rx_reset,
//// RX LBUS Signals
    input  wire rx_axis_tvalid,
    input  wire [127:0] rx_axis_tdata,
    input  wire rx_axis_tuser_ena0,
    input  wire rx_axis_tuser_sop0,
    input  wire rx_axis_tuser_eop0,
    input  wire [2:0] rx_axis_tuser_mty0,
    input  wire rx_axis_tuser_err0,
    input  wire rx_axis_tuser_ena1,
    input  wire rx_axis_tuser_sop1,
    input  wire rx_axis_tuser_eop1,
    input  wire [2:0] rx_axis_tuser_mty1,
    input  wire rx_axis_tuser_err1,
    input  wire [55:0] rx_preambleout,

//// RX Control Signals

//// RX Pause Control Signals
    output wire [8:0] ctl_rx_pause_ack,

//// RX Stats Signals
    input  wire [3:0] stat_rx_block_lock,
    input  wire stat_rx_framing_err_valid_0,
    input  wire stat_rx_framing_err_0,
    input  wire stat_rx_framing_err_valid_1,
    input  wire stat_rx_framing_err_1,
    input  wire stat_rx_framing_err_valid_2,
    input  wire stat_rx_framing_err_2,
    input  wire stat_rx_framing_err_valid_3,
    input  wire stat_rx_framing_err_3,
    input  wire [3:0] stat_rx_vl_demuxed,
    input  wire [1:0] stat_rx_vl_number_0,
    input  wire [1:0] stat_rx_vl_number_1,
    input  wire [1:0] stat_rx_vl_number_2,
    input  wire [1:0] stat_rx_vl_number_3,
    input  wire [3:0] stat_rx_synced,
    input  wire stat_rx_misaligned,
    input  wire stat_rx_aligned_err,
    input  wire [3:0] stat_rx_synced_err,
    input  wire [3:0] stat_rx_mf_len_err,
    input  wire [3:0] stat_rx_mf_repeat_err,
    input  wire [3:0] stat_rx_mf_err,
    input  wire stat_rx_bip_err_0,
    input  wire stat_rx_bip_err_1,
    input  wire stat_rx_bip_err_2,
    input  wire stat_rx_bip_err_3,
    input  wire stat_rx_aligned,
    input  wire stat_rx_hi_ber,
    input  wire stat_rx_status,
    input  wire [1:0] stat_rx_bad_code,
    input  wire [1:0] stat_rx_total_packets,
    input  wire stat_rx_total_good_packets,
    input  wire [5:0] stat_rx_total_bytes,
    input  wire [13:0] stat_rx_total_good_bytes,
    input  wire [1:0] stat_rx_packet_small,
    input  wire stat_rx_jabber,
    input  wire stat_rx_packet_large,
    input  wire stat_rx_oversize,
    input  wire [1:0] stat_rx_undersize,
    input  wire stat_rx_toolong,
    input  wire [1:0] stat_rx_fragment,
    input  wire stat_rx_packet_64_bytes,
    input  wire stat_rx_packet_65_127_bytes,
    input  wire stat_rx_packet_128_255_bytes,
    input  wire stat_rx_packet_256_511_bytes,
    input  wire stat_rx_packet_512_1023_bytes,
    input  wire stat_rx_packet_1024_1518_bytes,
    input  wire stat_rx_packet_1519_1522_bytes,
    input  wire stat_rx_packet_1523_1548_bytes,
    input  wire [1:0] stat_rx_bad_fcs,
    input  wire stat_rx_packet_bad_fcs,
    input  wire [1:0] stat_rx_stomped_fcs,
    input  wire stat_rx_packet_1549_2047_bytes,
    input  wire stat_rx_packet_2048_4095_bytes,
    input  wire stat_rx_packet_4096_8191_bytes,
    input  wire stat_rx_packet_8192_9215_bytes,
    input  wire stat_rx_bad_preamble,
    input  wire stat_rx_bad_sfd,
    input  wire stat_rx_got_signal_os,
    input  wire [1:0] stat_rx_test_pattern_mismatch,
    input  wire stat_rx_truncated,
    input  wire stat_rx_local_fault,
    input  wire stat_rx_remote_fault,
    input  wire stat_rx_internal_local_fault,
    input  wire stat_rx_received_local_fault,

    input  wire stat_rx_unicast,
    input  wire stat_rx_multicast,
    input  wire stat_rx_broadcast,
    input  wire stat_rx_vlan,
    input  wire stat_rx_pause,
    input  wire stat_rx_user_pause,
    input  wire stat_rx_inrangeerr,
    input  wire [8:0] stat_rx_pause_valid,
    input  wire [15:0] stat_rx_pause_quanta0,
    input  wire [15:0] stat_rx_pause_quanta1,
    input  wire [15:0] stat_rx_pause_quanta2,
    input  wire [15:0] stat_rx_pause_quanta3,
    input  wire [15:0] stat_rx_pause_quanta4,
    input  wire [15:0] stat_rx_pause_quanta5,
    input  wire [15:0] stat_rx_pause_quanta6,
    input  wire [15:0] stat_rx_pause_quanta7,
    input  wire [15:0] stat_rx_pause_quanta8,
    input  wire [8:0] stat_rx_pause_req,

//// TX Signals
    output wire         tx_reset,
    input  wire         user_tx_reset,

//// TX LBUS Signals
    input  wire tx_axis_tready,
    output wire tx_axis_tvalid,
    output wire [127:0] tx_axis_tdata,
    output wire tx_axis_tuser_ena0,
    output wire tx_axis_tuser_sop0,
    output wire tx_axis_tuser_eop0,
    output wire [2:0] tx_axis_tuser_mty0,
    output wire tx_axis_tuser_err0,
    output wire tx_axis_tuser_ena1,
    output wire tx_axis_tuser_sop1,
    output wire tx_axis_tuser_eop1,
    output wire [2:0] tx_axis_tuser_mty1,
    output wire tx_axis_tuser_err1,
    input  wire tx_unfout,
    output wire [55:0] tx_preamblein,

//// TX Control Signals
    output wire ctl_tx_send_lfi,
    output wire ctl_tx_send_rfi,
    output wire ctl_tx_send_idle,

//// TX Pause Control Signals
    output wire [8:0] ctl_tx_pause_req,
    output wire ctl_tx_resend_pause,

//// TX Stats Signals
    input  wire stat_tx_total_packets,
    input  wire [4:0] stat_tx_total_bytes,
    input  wire stat_tx_total_good_packets,
    input  wire [13:0] stat_tx_total_good_bytes,
    input  wire stat_tx_packet_64_bytes,
    input  wire stat_tx_packet_65_127_bytes,
    input  wire stat_tx_packet_128_255_bytes,
    input  wire stat_tx_packet_256_511_bytes,
    input  wire stat_tx_packet_512_1023_bytes,
    input  wire stat_tx_packet_1024_1518_bytes,
    input  wire stat_tx_packet_1519_1522_bytes,
    input  wire stat_tx_packet_1523_1548_bytes,
    input  wire stat_tx_packet_small,
    input  wire stat_tx_packet_large,
    input  wire stat_tx_packet_1549_2047_bytes,
    input  wire stat_tx_packet_2048_4095_bytes,
    input  wire stat_tx_packet_4096_8191_bytes,
    input  wire stat_tx_packet_8192_9215_bytes,
    input  wire stat_tx_bad_fcs,
    input  wire stat_tx_frame_error,
    input  wire stat_tx_local_fault,

    input  wire stat_tx_unicast,
    input  wire stat_tx_multicast,
    input  wire stat_tx_broadcast,
    input  wire stat_tx_vlan,
    input  wire stat_tx_pause,
    input  wire stat_tx_user_pause,
    input  wire [8:0] stat_tx_pause_valid,


  output wire gtwiz_reset_tx_datapath, 
  output wire gtwiz_reset_rx_datapath, 
    input  wire [67:0] gt_dmonitorout,
    input  wire [3:0] gt_eyescandataerror,
    output wire [3:0] gt_eyescanreset,
    output wire [3:0] gt_eyescantrigger,
    output wire [63:0] gt_pcsrsvdin,
    output wire [3:0] gt_rxbufreset,
    input  wire [11:0] gt_rxbufstatus,
    output wire [3:0] gt_rxcdrhold,
    output wire [3:0] gt_rxcommadeten,
    output wire [3:0] gt_rxdfeagchold,
    output wire [3:0] gt_rxdfelpmreset,
    output wire [3:0] gt_rxlatclk,
    output wire [3:0] gt_rxlpmen,
    output wire [3:0] gt_rxpcsreset,
    output wire [3:0] gt_rxpmareset,
    output wire [3:0] gt_rxpolarity,
    output wire [3:0] gt_rxprbscntreset,
    input  wire [3:0] gt_rxprbserr,
    output wire [15:0] gt_rxprbssel,
    output wire [11:0] gt_rxrate,
    output wire [3:0] gt_rxslide_in,
    input  wire [7:0] gt_rxstartofseq,
    input  wire [7:0] gt_txbufstatus,
    output wire [19:0] gt_txdiffctrl,
    output wire [3:0] gt_txinhibit,
    output wire [3:0] gt_txlatclk,
    output wire [27:0] gt_txmaincursor,
    output wire [3:0] gt_txpcsreset,
    output wire [3:0] gt_txpmareset,
    output wire [3:0] gt_txpolarity,
    output wire [19:0] gt_txpostcursor,
    output wire [3:0] gt_txprbsforceerr,
    output wire [15:0] gt_txprbssel,
    output wire [19:0] gt_txprecursor,

    input  wire [15:0] gt_ch_drpdo_0,
    input  wire [0:0] gt_ch_drprdy_0,
    output wire [0:0] gt_ch_drpen_0,
    output wire [0:0] gt_ch_drpwe_0,
    output wire [9:0] gt_ch_drpaddr_0,
    output wire [15:0] gt_ch_drpdi_0,
    input  wire [15:0] gt_ch_drpdo_1,
    input  wire [0:0] gt_ch_drprdy_1,
    output wire [0:0] gt_ch_drpen_1,
    output wire [0:0] gt_ch_drpwe_1,
    output wire [9:0] gt_ch_drpaddr_1,
    output wire [15:0] gt_ch_drpdi_1,
    input  wire [15:0] gt_ch_drpdo_2,
    input  wire [0:0] gt_ch_drprdy_2,
    output wire [0:0] gt_ch_drpen_2,
    output wire [0:0] gt_ch_drpwe_2,
    output wire [9:0] gt_ch_drpaddr_2,
    output wire [15:0] gt_ch_drpdi_2,
    input  wire [15:0] gt_ch_drpdo_3,
    input  wire [0:0] gt_ch_drprdy_3,
    output wire [0:0] gt_ch_drpen_3,
    output wire [0:0] gt_ch_drpwe_3,
    output wire [9:0] gt_ch_drpaddr_3,
    output wire [15:0] gt_ch_drpdi_3,
    output wire  [4:0] completion_status,
    output wire        rx_gt_locked_led,
    output wire        rx_aligned_led
   );

  wire [2:0] data_pattern_select;
  wire insert_crc;
  wire clear_count;
  wire pktgen_enable;
  reg  pktgen_enable_int;
  wire synced_pktgen_enable;
  wire rx_lane_align;
  
  wire tx_total_bytes_overflow;
  wire tx_sent_overflow;
  wire [47:0] tx_sent_count;
  reg  [47:0] tx_sent_count_int;
  wire [47:0] synced_tx_sent_count;
  wire [63:0] tx_total_bytes;
  reg  [63:0] tx_total_bytes_int;
  wire [63:0] synced_tx_total_bytes;
  wire tx_time_out;
  reg  tx_time_out_int;
  wire synced_tx_time_out;
  wire tx_done;
  reg  tx_done_int;
  wire synced_tx_done;

  wire [3:0] synced_stat_rx_block_lock;
  wire [3:0] synced_stat_rx_synced;
  wire synced_stat_rx_aligned;
  wire synced_stat_rx_status;
  wire synced_restart_tx_rx;

  wire rx_errors;
  reg  rx_errors_int;
  wire synced_rx_errors;
  wire [31:0] rx_data_err_count;
  reg [31:0] rx_data_err_count_int;
  wire [31:0] synced_rx_data_err_count;
  wire [31:0] rx_error_count;
  wire [31:0] rx_prot_err_count; 
  wire [63:0] rx_total_bytes;
  reg  [63:0] rx_total_bytes_int;
  wire [63:0] synced_rx_total_bytes;
  wire [47:0] rx_packet_count;
  reg  [47:0] rx_packet_count_int;
  wire [47:0] synced_rx_packet_count;
  wire rx_packet_count_overflow;
  wire rx_total_bytes_overflow;
  wire rx_prot_err_overflow;
  wire rx_error_overflow;
  
  wire rx_data_err_overflow;

  //// AXI4 Lite interface ports
  assign s_axi_aclk = dclk;
  assign s_axi_aresetn = ~sys_reset;
  assign pm_tick = 0;
  wire axi_fsm_restart;
  
 l_ethernet_40G_qsfp_d_0_axi4_lite_user_if i_l_ethernet_40G_qsfp_d_0_axi4_lite_user_if (
 .s_axi_aclk (s_axi_aclk),
 .s_axi_sreset (~s_axi_aresetn ),
 .stat_rx_aligned (stat_rx_aligned),
 .rx_gt_locked(~user_rx_reset),
 .restart (axi_fsm_restart),
 .completion_status (completion_status),
 .s_axi_pm_tick (pm_tick),
 .s_axi_awaddr (s_axi_awaddr),
 .s_axi_awvalid (s_axi_awvalid),
 .s_axi_awready (s_axi_awready),
 .s_axi_wdata (s_axi_wdata),
 .s_axi_wstrb (s_axi_wstrb),
 .s_axi_wvalid (s_axi_wvalid),
 .s_axi_wready (s_axi_wready),
 .s_axi_bresp (s_axi_bresp),
 .s_axi_bvalid (s_axi_bvalid),
 .s_axi_bready (s_axi_bready),
 .s_axi_araddr (s_axi_araddr),
 .s_axi_arvalid (s_axi_arvalid),
 .s_axi_arready (s_axi_arready),
 .s_axi_rdata (s_axi_rdata),
 .s_axi_rresp (s_axi_rresp),
 .s_axi_rvalid (s_axi_rvalid),
 .s_axi_rready (s_axi_rready)

);

  assign ctl_tx_send_lfi = 0;
  assign ctl_tx_send_rfi = 0;
  assign ctl_tx_send_idle = 0;
  assign ctl_rx_pause_ack = 0;
  assign ctl_tx_pause_req = 0;
  assign ctl_tx_resend_pause = 0;
  assign ctl_rx_vl_marker_id0 = {24'h907647, 8'h00, ~24'h907647, 8'h00};
  assign ctl_tx_vl_marker_id0 = {24'h907647, 8'h00, ~24'h907647, 8'h00};
  assign ctl_rx_vl_marker_id1 = {24'hF0C4E6, 8'h00, ~24'hF0C4E6, 8'h00};
  assign ctl_tx_vl_marker_id1 = {24'hF0C4E6, 8'h00, ~24'hF0C4E6, 8'h00};
  assign ctl_rx_vl_marker_id2 = {24'hC5659B, 8'h00, ~24'hC5659B, 8'h00};
  assign ctl_tx_vl_marker_id2 = {24'hC5659B, 8'h00, ~24'hC5659B, 8'h00};
  assign ctl_rx_vl_marker_id3 = {24'hA2793D, 8'h00, ~24'hA2793D, 8'h00};
  assign ctl_tx_vl_marker_id3 = {24'hA2793D, 8'h00, ~24'hA2793D, 8'h00};

  assign ctl_rx_pause_ack = 9'b0;
  assign ctl_tx_pause_req = 9'b0;
  assign ctl_tx_resend_pause = 1'b0;



  wire ok_to_start;
  assign rx_errors            = |rx_prot_err_count || |rx_error_count ;
  assign ok_to_start = 1'b1;

l_ethernet_40G_qsfp_d_0_pkt_gen_mon_syncer_level
#(
  .WIDTH       ( 4 )
 ) i_l_ethernet_40G_qsfp_d_0_stat_rx_block_lock_syncer (
  .clk           (  usr_fsm_clk  ),
  .reset         (  sys_reset  ),
  .datain        (  stat_rx_block_lock  ),
  .dataout       (  synced_stat_rx_block_lock  )
);

l_ethernet_40G_qsfp_d_0_pkt_gen_mon_syncer_level
#(
  .WIDTH       ( 4 )
 ) i_l_ethernet_40G_qsfp_d_0_stat_rx_synced_syncer (
  .clk           (  usr_fsm_clk  ),
  .reset         (  sys_reset  ),
  .datain        (  stat_rx_synced  ),
  .dataout       (  synced_stat_rx_synced  )
);

l_ethernet_40G_qsfp_d_0_pkt_gen_mon_syncer_level i_l_ethernet_40G_qsfp_d_0_stat_rx_aligned_usr_fsm_clk_syncer (
  .clk           (  usr_fsm_clk  ),
  .reset         (  sys_reset  ),
  .datain        (  stat_rx_aligned  ),
  .dataout       (  synced_stat_rx_aligned  )
);

l_ethernet_40G_qsfp_d_0_pkt_gen_mon_syncer_level i_l_ethernet_40G_qsfp_d_0_stat_rx_aligned_gen_clk_syncer (
  .clk           (  gen_clk  ),
  .reset         (  sys_reset  ),
  .datain        (  stat_rx_aligned  ),
  .dataout       (  rx_lane_align  )
);

  reg stat_rx_status_int;
  always @(posedge mon_clk)
  begin
      stat_rx_status_int   <= stat_rx_status ;
  end

l_ethernet_40G_qsfp_d_0_pkt_gen_mon_syncer_level i_l_ethernet_40G_qsfp_d_0_stat_rx_status_syncer (
  .clk           (  usr_fsm_clk  ),
  .reset         (  sys_reset  ),
  .datain        (  stat_rx_status_int  ),
  .dataout       (  synced_stat_rx_status  )
);

l_ethernet_40G_qsfp_d_0_pkt_gen_mon_syncer_level i_l_ethernet_40G_qsfp_d_0_restart_tx_rx_syncer (
  .clk           (  usr_fsm_clk  ),
  .reset         (  sys_reset  ),
  .datain        (  restart_tx_rx  ),
  .dataout       (  synced_restart_tx_rx  )
);

  always @(posedge gen_clk)
  begin
      tx_time_out_int   <= tx_time_out ;
  end

l_ethernet_40G_qsfp_d_0_pkt_gen_mon_syncer_level i_l_ethernet_40G_qsfp_d_0_tx_time_out_syncer (
  .clk          (  usr_fsm_clk ),
  .reset        (  sys_reset  ),
  .datain       (  tx_time_out_int  ),
  .dataout      (  synced_tx_time_out  )
);

  always @(posedge gen_clk)
  begin
      tx_done_int       <= tx_done ;
  end

l_ethernet_40G_qsfp_d_0_pkt_gen_mon_syncer_level i_l_ethernet_40G_qsfp_d_0_tx_done_syncer (
  .clk          (  usr_fsm_clk ),
  .reset        (  sys_reset  ),
  .datain       (  tx_done_int  ),
  .dataout      (  synced_tx_done  )
);

  always@ (posedge usr_fsm_clk)
  begin
      pktgen_enable_int <= pktgen_enable;
  end

l_ethernet_40G_qsfp_d_0_pkt_gen_mon_syncer_level i_l_ethernet_40G_qsfp_d_0_pkt_gen_enable_syncer (
    .clk          (  gen_clk  ),
    .reset        (  sys_reset  ),
    .datain       (  pktgen_enable_int  ),
    .dataout      (  synced_pktgen_enable  )
);

  always @(posedge gen_clk)
  begin
      tx_total_bytes_int  <= tx_total_bytes;
  end
  
l_ethernet_40G_qsfp_d_0_pkt_gen_mon_syncer_level 
  #(
    .WIDTH        (64)
  ) i_l_ethernet_40G_qsfp_d_0_tx_total_bytes_syncer (
    .clk       (usr_fsm_clk ),
    .reset     (sys_reset),
    .datain    (tx_total_bytes_int),
    .dataout   (synced_tx_total_bytes)
  );

  always @(posedge gen_clk)
  begin
      tx_sent_count_int <= tx_sent_count;
  end

l_ethernet_40G_qsfp_d_0_pkt_gen_mon_syncer_level
  #(
    .WIDTH        (48)
  ) i_l_ethernet_40G_qsfp_d_0_tx_packet_count_syncer (
    .clk       (usr_fsm_clk ),
    .reset     (sys_reset),
    .datain    (tx_sent_count_int),
    .dataout   (synced_tx_sent_count)
  );

  always @(posedge mon_clk)
  begin
      rx_packet_count_int <= rx_packet_count;
  end

l_ethernet_40G_qsfp_d_0_pkt_gen_mon_syncer_level 
  #(
    .WIDTH        (48)
  ) i_l_ethernet_40G_qsfp_d_0_rx_packet_count_syncer (
    .clk       (usr_fsm_clk ),
    .reset     (sys_reset),
    .datain    (rx_packet_count_int),
    .dataout   (synced_rx_packet_count)
  );

  always @(posedge mon_clk)
  begin
      rx_total_bytes_int  <= rx_total_bytes;
  end

l_ethernet_40G_qsfp_d_0_pkt_gen_mon_syncer_level 
  #(
    .WIDTH        (64)
  ) i_l_ethernet_40G_qsfp_d_0_rx_total_bytes_syncer (
    .clk       (usr_fsm_clk ),
    .reset     (sys_reset),
    .datain    (rx_total_bytes_int),
    .dataout   (synced_rx_total_bytes)
  );

  always @(posedge mon_clk)
  begin
      rx_errors_int       <= rx_errors;
  end

l_ethernet_40G_qsfp_d_0_pkt_gen_mon_syncer_level 
  #(
    .WIDTH        (1)
  ) i_l_ethernet_40G_qsfp_d_0_rx_errors_syncer (
    .clk       (usr_fsm_clk),
    .reset     (sys_reset),
    .datain    (rx_errors_int),
    .dataout   (synced_rx_errors)
  );
  always @(posedge mon_clk)
  begin
      rx_data_err_count_int       <= rx_data_err_count;
  end

l_ethernet_40G_qsfp_d_0_pkt_gen_mon_syncer_level 
  #(
    .WIDTH        (32)
  ) i_l_ethernet_40G_qsfp_d_0_rx_data_err_count_syncer (
    .clk       (usr_fsm_clk),
    .reset     (sys_reset),
    .datain    (rx_data_err_count_int),
    .dataout   (synced_rx_data_err_count)
  );

l_ethernet_40G_qsfp_d_0_mac_example_fsm  #(
`ifdef SIM_SPEED_UP
 .STARTUP_TIME (32'd5000)
`else
 .STARTUP_TIME (32'd50_000)
`endif
  ) i_l_ethernet_40G_qsfp_d_0_EXAMPLE_FSM  (
  .dclk                        (  usr_fsm_clk  ),
  .fsm_reset                   (  sys_reset || synced_restart_tx_rx  ),
  .stat_rx_block_lock          (  synced_stat_rx_block_lock  ),
  .stat_rx_synced              (  synced_stat_rx_synced  ),
  .stat_rx_aligned             (  synced_stat_rx_aligned  ),
  .stat_rx_status              (  synced_stat_rx_status  ),
  .tx_timeout                  (  synced_tx_time_out  ),
  .tx_done                     (  synced_tx_done  ),
  .ok_to_start                 (  ok_to_start  ),

  .rx_packet_count             (  synced_rx_packet_count  ),
  .rx_total_bytes              (  synced_rx_total_bytes  ),
  .rx_errors                   (  synced_rx_errors  ),
  .rx_data_errors              (  |synced_rx_data_err_count  ),
  .tx_sent_count               (  synced_tx_sent_count  ),
  .tx_total_bytes              (  synced_tx_total_bytes  ),

  .sys_reset                   (   ),
  .pktgen_enable               (  pktgen_enable  ),

  .completion_status           (  completion_status  )
);


  assign tx_reset = sys_reset;
  assign rx_reset = sys_reset;
  assign rx_gt_locked_led = ~user_rx_reset;
  assign rx_aligned_led = stat_rx_aligned;

  assign data_pattern_select     =      3'd7;
  assign clear_count             =      1'b0;
  assign insert_crc              =      1'b0;


l_ethernet_40G_qsfp_d_0_mac_pkt_io1 #(
  .FIXED_PACKET_LENGTH ( 256 ),
  .TRAF_MIN_LENGTH     ( 64 ),
  .TRAF_MAX_LENGTH     ( 9000 )
) i_l_ethernet_40G_qsfp_d_0_TRAFFIC_GENERATOR (
  .tx_clk ( gen_clk ),
  .rx_clk ( mon_clk ),
  .tx_reset ( user_tx_reset | restart_tx_rx),
  .rx_reset ( user_rx_reset | restart_tx_rx),


  .tx_enable ( synced_pktgen_enable ),
  .rx_enable ( 1'b1 ),
  .data_pattern_select ( data_pattern_select ),
  .insert_crc ( insert_crc ),
  .tx_packet_count ( PKT_NUM ),
  .clear_count ( clear_count ),

  .rx_lane_align ( rx_lane_align ),
  .tx_axis_tready ( tx_axis_tready ),
  .tx_axis_tvalid ( tx_axis_tvalid ),
  .rx_axis_tvalid ( rx_axis_tvalid ),
  .tx_axis_tdata ( tx_axis_tdata ),
  .rx_axis_tdata ( rx_axis_tdata ),
  .tx_axis_tuser_ena0 ( tx_axis_tuser_ena0 ),
  .tx_axis_tuser_sop0 ( tx_axis_tuser_sop0 ),
  .tx_axis_tuser_eop0 ( tx_axis_tuser_eop0 ),
  .tx_axis_tuser_mty0 ( tx_axis_tuser_mty0 ),
  .tx_axis_tuser_err0 ( tx_axis_tuser_err0 ),
  .tx_axis_tuser_ena1 ( tx_axis_tuser_ena1 ),
  .tx_axis_tuser_sop1 ( tx_axis_tuser_sop1 ),
  .tx_axis_tuser_eop1 ( tx_axis_tuser_eop1 ),
  .tx_axis_tuser_mty1 ( tx_axis_tuser_mty1 ),
  .tx_axis_tuser_err1 ( tx_axis_tuser_err1 ),
  .rx_axis_tuser_ena0 ( rx_axis_tuser_ena0 ),
  .rx_axis_tuser_sop0 ( rx_axis_tuser_sop0 ),
  .rx_axis_tuser_eop0 ( rx_axis_tuser_eop0 ),
  .rx_axis_tuser_mty0 ( rx_axis_tuser_mty0 ),
  .rx_axis_tuser_err0 ( rx_axis_tuser_err0 ),
  .rx_axis_tuser_ena1 ( rx_axis_tuser_ena1 ),
  .rx_axis_tuser_sop1 ( rx_axis_tuser_sop1 ),
  .rx_axis_tuser_eop1 ( rx_axis_tuser_eop1 ),
  .rx_axis_tuser_mty1 ( rx_axis_tuser_mty1 ),
  .rx_axis_tuser_err1 ( rx_axis_tuser_err1 ),
  .tx_unfout (tx_unfout),
  .tx_preamblein (tx_preamblein),
  .rx_preambleout (rx_preambleout),

  .tx_time_out ( tx_time_out ),
  .tx_done ( tx_done ),
  .rx_protocol_error ( rx_protocol_error ),
  .rx_packet_count ( rx_packet_count ),
  .rx_total_bytes ( rx_total_bytes ),
  .rx_prot_err_count ( rx_prot_err_count ),
  .rx_error_count ( rx_error_count ),
  .rx_packet_count_overflow ( rx_packet_count_overflow ),
  .rx_total_bytes_overflow ( rx_total_bytes_overflow ),
  .rx_prot_err_overflow ( rx_prot_err_overflow ),
  .rx_error_overflow ( rx_error_overflow ),
  .tx_sent_count ( tx_sent_count ),
  .tx_sent_overflow ( tx_sent_overflow ),
  .tx_total_bytes ( tx_total_bytes ),
  .tx_total_bytes_overflow ( tx_total_bytes_overflow ),
  .rx_data_err_count ( rx_data_err_count ),
  .rx_data_err_overflow ( rx_data_err_overflow )
  );



l_ethernet_40G_qsfp_d_0_trans_debug i_l_ethernet_40G_qsfp_d_0_trans_debug
(
.gtwiz_reset_tx_datapath (gtwiz_reset_tx_datapath), 
.gtwiz_reset_rx_datapath (gtwiz_reset_rx_datapath), 
  .gt_dmonitorout(gt_dmonitorout),
  .gt_eyescandataerror(gt_eyescandataerror),
  .gt_eyescanreset(gt_eyescanreset),
  .gt_eyescantrigger(gt_eyescantrigger),
  .gt_pcsrsvdin(gt_pcsrsvdin),
  .gt_rxbufreset(gt_rxbufreset),
  .gt_rxbufstatus(gt_rxbufstatus),
  .gt_rxcdrhold(gt_rxcdrhold),
  .gt_rxcommadeten(gt_rxcommadeten),
  .gt_rxdfeagchold(gt_rxdfeagchold),
  .gt_rxdfelpmreset(gt_rxdfelpmreset),
  .gt_rxlatclk(gt_rxlatclk),
  .gt_rxlpmen(gt_rxlpmen),
  .gt_rxpcsreset(gt_rxpcsreset),
  .gt_rxpmareset(gt_rxpmareset),
  .gt_rxpolarity(gt_rxpolarity),
  .gt_rxprbscntreset(gt_rxprbscntreset),
  .gt_rxprbserr(gt_rxprbserr),
  .gt_rxprbssel(gt_rxprbssel),
  .gt_rxrate(gt_rxrate),
  .gt_rxslide_in(gt_rxslide_in),
  .gt_rxstartofseq(gt_rxstartofseq),
  .gt_txbufstatus(gt_txbufstatus),
  .gt_txdiffctrl(gt_txdiffctrl),
  .gt_txinhibit(gt_txinhibit),
  .gt_txlatclk(gt_txlatclk),
  .gt_txmaincursor(gt_txmaincursor),
  .gt_txpcsreset(gt_txpcsreset),
  .gt_txpmareset(gt_txpmareset),
  .gt_txpolarity(gt_txpolarity),
  .gt_txpostcursor(gt_txpostcursor),
  .gt_txprbsforceerr(gt_txprbsforceerr),
  .gt_txprbssel(gt_txprbssel),
  .gt_txprecursor(gt_txprecursor),
  .gt_ch_drpdo_0(gt_ch_drpdo_0),
  .gt_ch_drprdy_0(gt_ch_drprdy_0),
  .gt_ch_drpen_0(gt_ch_drpen_0),
  .gt_ch_drpwe_0(gt_ch_drpwe_0),
  .gt_ch_drpaddr_0(gt_ch_drpaddr_0),
  .gt_ch_drpdi_0(gt_ch_drpdi_0),
  .gt_ch_drpdo_1(gt_ch_drpdo_1),
  .gt_ch_drprdy_1(gt_ch_drprdy_1),
  .gt_ch_drpen_1(gt_ch_drpen_1),
  .gt_ch_drpwe_1(gt_ch_drpwe_1),
  .gt_ch_drpaddr_1(gt_ch_drpaddr_1),
  .gt_ch_drpdi_1(gt_ch_drpdi_1),
  .gt_ch_drpdo_2(gt_ch_drpdo_2),
  .gt_ch_drprdy_2(gt_ch_drprdy_2),
  .gt_ch_drpen_2(gt_ch_drpen_2),
  .gt_ch_drpwe_2(gt_ch_drpwe_2),
  .gt_ch_drpaddr_2(gt_ch_drpaddr_2),
  .gt_ch_drpdi_2(gt_ch_drpdi_2),
  .gt_ch_drpdo_3(gt_ch_drpdo_3),
  .gt_ch_drprdy_3(gt_ch_drprdy_3),
  .gt_ch_drpen_3(gt_ch_drpen_3),
  .gt_ch_drpwe_3(gt_ch_drpwe_3),
  .gt_ch_drpaddr_3(gt_ch_drpaddr_3),
  .gt_ch_drpdi_3(gt_ch_drpdi_3),
  .reset(sys_reset),
  .drp_clk(dclk)
);


endmodule



module l_ethernet_40G_qsfp_d_0_mac_example_fsm  #(
  parameter [31:0] STARTUP_TIME = 32'd20_000,
                   VL_LANES_PER_GENERATOR = 4,
                   GENERATOR_COUNT = 1                  // Number of traffic generators being monitored
  )  (
input wire dclk,
input wire fsm_reset,
input wire [VL_LANES_PER_GENERATOR*GENERATOR_COUNT-1:0] stat_rx_block_lock,
input wire [VL_LANES_PER_GENERATOR*GENERATOR_COUNT-1:0] stat_rx_synced,
input wire stat_rx_aligned,
input wire stat_rx_status,
input wire tx_timeout,
input wire tx_done,
input wire ok_to_start,

input wire [(48 * GENERATOR_COUNT - 1):0] rx_packet_count,
input wire [64 * GENERATOR_COUNT - 1:0] rx_total_bytes,
input wire  rx_errors,
input wire        rx_data_errors,
input wire [(48 * GENERATOR_COUNT - 1):0] tx_sent_count,
input wire [64 * GENERATOR_COUNT - 1:0]  tx_total_bytes,

output reg sys_reset,
output reg pktgen_enable,

output reg [4:0] completion_status
);

localparam [4:0]   NO_START = {5{1'b1}},
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
                common_timer <= cvt_us( 32'd40 );            // Set wait period for packet transmission
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

module l_ethernet_40G_qsfp_d_0_mac_pkt_io1 #(
  parameter integer FIXED_PACKET_LENGTH = 9_000,
                    TRAF_MIN_LENGTH = 64,
                    TRAF_MAX_LENGTH = 9000
               ) (

  input  wire tx_clk,
  input  wire rx_clk,
  input  wire tx_reset,
  input  wire rx_reset,
  input  wire tx_enable,
  input  wire rx_enable,
  input  wire [2:0] data_pattern_select,
  input  wire insert_crc,
  input  wire [31:0] tx_packet_count,
  input  wire clear_count,

  input  wire tx_axis_tready,
  output reg  tx_axis_tvalid,
  input  wire rx_axis_tvalid,
  output reg  [127:0] tx_axis_tdata,
  input  wire [127:0] rx_axis_tdata,
  output reg  tx_axis_tuser_ena0,
  output reg  tx_axis_tuser_sop0,
  output reg  tx_axis_tuser_eop0,
  output reg  [2:0] tx_axis_tuser_mty0,
  output reg  tx_axis_tuser_err0,
  output reg  tx_axis_tuser_ena1,
  output reg  tx_axis_tuser_sop1,
  output reg  tx_axis_tuser_eop1,
  output reg  [2:0] tx_axis_tuser_mty1,
  output reg  tx_axis_tuser_err1,
  input  wire rx_axis_tuser_ena0,
  input  wire rx_axis_tuser_sop0,
  input  wire rx_axis_tuser_eop0,
  input  wire [2:0] rx_axis_tuser_mty0,
  input  wire rx_axis_tuser_err0,
  input  wire rx_axis_tuser_ena1,
  input  wire rx_axis_tuser_sop1,
  input  wire rx_axis_tuser_eop1,
  input  wire [2:0] rx_axis_tuser_mty1,
  input  wire rx_axis_tuser_err1,
  input  wire tx_unfout,
  input  wire [55:0] rx_preambleout,
  output wire [55:0] tx_preamblein,

  input  wire rx_lane_align,
  output wire tx_time_out,
  output wire tx_done,
  output wire rx_protocol_error,
  output wire [47:0] rx_packet_count,
  output wire [63:0] rx_total_bytes,
  output wire [31:0] rx_prot_err_count,
  output wire [31:0] rx_error_count,
  output wire rx_packet_count_overflow,
  output wire rx_total_bytes_overflow,
  output wire rx_prot_err_overflow,
  output wire rx_error_overflow,
  output wire [47:0] tx_sent_count,
  output wire tx_sent_overflow,
  output wire [63:0] tx_total_bytes,
  output wire tx_total_bytes_overflow,
  output wire [31:0] rx_data_err_count,
  output wire rx_data_err_overflow
);

  assign tx_preamblein = {7{8'h55}} ;


  // Segmented bus
  // RX
  reg [64-1:0] rx_dataout0;
  reg rx_enaout0;
  reg rx_sopout0;
  reg rx_eopout0;
  reg rx_errout0;
  reg  [3-1:0] rx_mtyout0;
  reg [64-1:0] rx_dataout1;
  reg rx_enaout1;
  reg rx_sopout1;
  reg rx_eopout1;
  reg rx_errout1;
  reg  [3-1:0] rx_mtyout1;

  always @( posedge rx_clk )
    begin
      if ( rx_reset == 1'b1 )
     begin
        rx_mtyout0 <= 'b0;
        rx_enaout0 <= 'b0;
        rx_eopout0 <= 'b0;
        rx_sopout0 <= 'b0;
        rx_errout0 <= 'b0;
        rx_dataout0 <= 'b0;
        rx_mtyout1 <= 'b0;
        rx_enaout1 <= 'b0;
        rx_eopout1 <= 'b0;
        rx_sopout1 <= 'b0;
        rx_errout1 <= 'b0;
        rx_dataout1 <= 'b0;
     end else
     begin
        rx_mtyout0 <= rx_axis_tuser_mty0;
        rx_enaout0 <= rx_axis_tuser_ena0 && rx_axis_tvalid;
        rx_eopout0 <= rx_axis_tuser_eop0;
        rx_sopout0 <= rx_axis_tuser_sop0;
        rx_errout0 <= rx_axis_tuser_err0;
        rx_dataout0[(8-1-0)*8+:8] <= rx_axis_tdata[(0*64+0*8)+:8];
        rx_dataout0[(8-1-1)*8+:8] <= rx_axis_tdata[(0*64+1*8)+:8];
        rx_dataout0[(8-1-2)*8+:8] <= rx_axis_tdata[(0*64+2*8)+:8];
        rx_dataout0[(8-1-3)*8+:8] <= rx_axis_tdata[(0*64+3*8)+:8];
        rx_dataout0[(8-1-4)*8+:8] <= rx_axis_tdata[(0*64+4*8)+:8];
        rx_dataout0[(8-1-5)*8+:8] <= rx_axis_tdata[(0*64+5*8)+:8];
        rx_dataout0[(8-1-6)*8+:8] <= rx_axis_tdata[(0*64+6*8)+:8];
        rx_dataout0[(8-1-7)*8+:8] <= rx_axis_tdata[(0*64+7*8)+:8];
        rx_mtyout1 <= rx_axis_tuser_mty1;
        rx_enaout1 <= rx_axis_tuser_ena1 && rx_axis_tvalid;
        rx_eopout1 <= rx_axis_tuser_eop1;
        rx_sopout1 <= rx_axis_tuser_sop1;
        rx_errout1 <= rx_axis_tuser_err1;
        rx_dataout1[(8-1-0)*8+:8] <= rx_axis_tdata[(1*64+0*8)+:8];
        rx_dataout1[(8-1-1)*8+:8] <= rx_axis_tdata[(1*64+1*8)+:8];
        rx_dataout1[(8-1-2)*8+:8] <= rx_axis_tdata[(1*64+2*8)+:8];
        rx_dataout1[(8-1-3)*8+:8] <= rx_axis_tdata[(1*64+3*8)+:8];
        rx_dataout1[(8-1-4)*8+:8] <= rx_axis_tdata[(1*64+4*8)+:8];
        rx_dataout1[(8-1-5)*8+:8] <= rx_axis_tdata[(1*64+5*8)+:8];
        rx_dataout1[(8-1-6)*8+:8] <= rx_axis_tdata[(1*64+6*8)+:8];
        rx_dataout1[(8-1-7)*8+:8] <= rx_axis_tdata[(1*64+7*8)+:8];
    end
  end

  wire [(2 * 64)-1:0] tx_datain;
  wire [2-1:0] tx_enain;
  wire [2-1:0] tx_sopin;
  wire [2-1:0] tx_eopin;
  wire [2-1:0] tx_errin;
  wire [(2 * 3)-1:0] tx_mtyin;

  wire tx_rdyout;
  wire tx_ovfout = 1'b0;

  wire [2-1:0] fifo_tx_enain;
  wire [2-1:0] fifo_tx_sopin;
  wire [(2 * 64)-1:0] fifo_tx_datain;
  wire [2-1:0] fifo_tx_eopin;
  wire [(2 * 3)-1:0] fifo_tx_mtyin;
  wire [2-1:0] fifo_tx_errin;

  wire [64-1:0] tx_axis_tdata_byteswap0;
  wire [64-1:0] tx_axis_tdata_byteswap1;


  assign { tx_axis_tdata_byteswap0, tx_axis_tdata_byteswap1 } = fifo_tx_datain ;



always @*
  begin
    tx_axis_tdata[(0*64+(8-1-0)*8)+:8] = tx_axis_tdata_byteswap0[0*8+:8];
    tx_axis_tdata[(0*64+(8-1-1)*8)+:8] = tx_axis_tdata_byteswap0[1*8+:8];
    tx_axis_tdata[(0*64+(8-1-2)*8)+:8] = tx_axis_tdata_byteswap0[2*8+:8];
    tx_axis_tdata[(0*64+(8-1-3)*8)+:8] = tx_axis_tdata_byteswap0[3*8+:8];
    tx_axis_tdata[(0*64+(8-1-4)*8)+:8] = tx_axis_tdata_byteswap0[4*8+:8];
    tx_axis_tdata[(0*64+(8-1-5)*8)+:8] = tx_axis_tdata_byteswap0[5*8+:8];
    tx_axis_tdata[(0*64+(8-1-6)*8)+:8] = tx_axis_tdata_byteswap0[6*8+:8];
    tx_axis_tdata[(0*64+(8-1-7)*8)+:8] = tx_axis_tdata_byteswap0[7*8+:8];
    tx_axis_tdata[(1*64+(8-1-0)*8)+:8] = tx_axis_tdata_byteswap1[0*8+:8];
    tx_axis_tdata[(1*64+(8-1-1)*8)+:8] = tx_axis_tdata_byteswap1[1*8+:8];
    tx_axis_tdata[(1*64+(8-1-2)*8)+:8] = tx_axis_tdata_byteswap1[2*8+:8];
    tx_axis_tdata[(1*64+(8-1-3)*8)+:8] = tx_axis_tdata_byteswap1[3*8+:8];
    tx_axis_tdata[(1*64+(8-1-4)*8)+:8] = tx_axis_tdata_byteswap1[4*8+:8];
    tx_axis_tdata[(1*64+(8-1-5)*8)+:8] = tx_axis_tdata_byteswap1[5*8+:8];
    tx_axis_tdata[(1*64+(8-1-6)*8)+:8] = tx_axis_tdata_byteswap1[6*8+:8];
    tx_axis_tdata[(1*64+(8-1-7)*8)+:8] = tx_axis_tdata_byteswap1[7*8+:8];
    { tx_axis_tuser_ena0, tx_axis_tuser_ena1 } = fifo_tx_enain ;
    { tx_axis_tuser_sop0, tx_axis_tuser_sop1 } = fifo_tx_sopin ;
    { tx_axis_tuser_eop0, tx_axis_tuser_eop1 } = fifo_tx_eopin ;
    { tx_axis_tuser_mty0, tx_axis_tuser_mty1 } = fifo_tx_mtyin ;
    { tx_axis_tuser_err0, tx_axis_tuser_err1 } = fifo_tx_errin ;
    tx_axis_tvalid = |fifo_tx_enain; // keep valid.
  end

   l_ethernet_40G_qsfp_d_0_mac_lbus_buf #(
      .IS_0_LATENCY ( 1 )
  ) i_l_ethernet_40G_qsfp_d_0_axi_fifo (

     .clk ( tx_clk ),
     .reset ( tx_reset ),

     .tx_datain( tx_datain),
     .tx_enain ( tx_enain ),
     .tx_sopin ( tx_sopin ),
     .tx_eopin ( tx_eopin ),
     .tx_errin ( tx_errin ),
     .tx_mtyin ( tx_mtyin ),

     .tx_dataout( fifo_tx_datain),
     .tx_enaout ( fifo_tx_enain ),
     .tx_sopout ( fifo_tx_sopin ),
     .tx_eopout ( fifo_tx_eopin ),
     .tx_errout ( fifo_tx_errin ),
     .tx_mtyout ( fifo_tx_mtyin ),
     .tx_rdyin  ( tx_axis_tready ),
     .tx_rdyout ( tx_rdyout )
  );



  wire [1:0] loc_pkt_tx_enain, loc_traf_tx_enain;
  wire [1:0] loc_pkt_tx_sopin, loc_traf_tx_sopin;
  wire [1:0] loc_pkt_tx_eopin, loc_traf_tx_eopin;
  wire [1:0] loc_pkt_tx_errin, loc_traf_tx_errin;
  wire [5:0] loc_pkt_tx_mtyin, loc_traf_tx_mtyin;
  wire [127:0] loc_pkt_tx_datain, loc_traf_tx_datain;

  assign tx_enain = data_pattern_select[2] ? loc_traf_tx_enain : 'b0 ;
  assign tx_sopin = data_pattern_select[2] ? loc_traf_tx_sopin : 'b0 ;
  assign tx_eopin = data_pattern_select[2] ? loc_traf_tx_eopin : 'b0 ;
  assign tx_errin = data_pattern_select[2] ? loc_traf_tx_errin : 'b0 ;
  assign tx_mtyin = data_pattern_select[2] ? loc_traf_tx_mtyin : 'b0 ;
  assign tx_datain = data_pattern_select[2] ? loc_traf_tx_datain : 'b0 ;

  wire loc_pkt_tx_time_out, loc_pkt_tx_done, loc_traf_tx_time_out, loc_traf_tx_done,loc_pkt_tx_busy,loc_traf_tx_busy;

  assign tx_time_out = data_pattern_select[2] ? loc_traf_tx_time_out : loc_pkt_tx_time_out,
         tx_done     = data_pattern_select[2] ? loc_traf_tx_done : loc_pkt_tx_done;

wire dly_rdyout =  tx_rdyout ;

assign loc_pkt_tx_time_out = 1'b0;
assign loc_pkt_tx_done = 1'b0;
assign loc_pkt_tx_busy = 1'b0;

l_ethernet_40G_qsfp_d_0_mac_traf_gen1 #(
  .min_pkt_len(TRAF_MIN_LENGTH),
  .max_pkt_len(TRAF_MAX_LENGTH)
  ) i_l_ethernet_40G_qsfp_d_0_TRAF_GEN1 (

  .clk            ( tx_clk ),
  .reset          ( tx_reset ),
  .enable         ( tx_enable && data_pattern_select[2] ),
  .tx_rdyout      ( dly_rdyout ),
  .tx_ovfout      ( tx_ovfout ),
  .rx_lane_align  ( rx_lane_align ),
  .packet_count   ( tx_packet_count ),

  .tx_datain      ( loc_traf_tx_datain ),
  .tx_enain       ( loc_traf_tx_enain ),
  .tx_sopin       ( loc_traf_tx_sopin ),
  .tx_eopin       ( loc_traf_tx_eopin ),
  .tx_errin       ( loc_traf_tx_errin ),
  .tx_mtyin       ( loc_traf_tx_mtyin ),
  .time_out       ( loc_traf_tx_time_out ),
  .busy           ( loc_traf_tx_busy ),
  .done           ( loc_traf_tx_done )
);

  wire [1:0] loc_rx_enaout;
  wire [1:0] loc_rx_sopout;
  wire [1:0] loc_rx_eopout;
  wire [1:0] loc_rx_errout;
  wire [5:0] loc_rx_mtyout;
  wire [127:0] loc_rx_dataout;

  assign loc_rx_enaout = { rx_enaout0, rx_enaout1 } ;
  assign loc_rx_sopout = { rx_sopout0, rx_sopout1 } ;
  assign loc_rx_eopout = { rx_eopout0, rx_eopout1 } ;
  assign loc_rx_errout = { rx_errout0, rx_errout1 } ;
  assign loc_rx_mtyout = { rx_mtyout0, rx_mtyout1 } ;
  assign loc_rx_dataout = { rx_dataout0, rx_dataout1 } ;

l_ethernet_40G_qsfp_d_0_mac_traf_chk1 i_l_ethernet_40G_qsfp_d_0_TRAF_CHK1 (

  .clk              ( rx_clk ),
  .reset            ( rx_reset ),
  .enable           ( rx_enable ),
  .clear_count      ( clear_count ),

  .rx_dataout       ( loc_rx_dataout ),
  .rx_enaout        ( loc_rx_enaout ),
  .rx_sopout        ( loc_rx_sopout ),
  .rx_eopout        ( loc_rx_eopout ),
  .rx_errout        ( loc_rx_errout ),
  .rx_mtyout        ( loc_rx_mtyout ),
  .protocol_error   ( rx_protocol_error ),
  .packet_count     ( rx_packet_count ),
  .total_bytes      ( rx_total_bytes ),
  .prot_err_count   ( rx_prot_err_count ),
  .error_count      ( rx_error_count ),
  .packet_count_overflow   ( rx_packet_count_overflow ),
  .total_bytes_overflow    ( rx_total_bytes_overflow ),
  .prot_err_overflow       ( rx_prot_err_overflow ),
  .error_overflow          ( rx_error_overflow )
);
l_ethernet_40G_qsfp_d_0_mac_traf_data_chk i_l_ethernet_40G_qsfp_d_0_TRAF_DATA_CHK (

  .clk              ( rx_clk ),
  .reset            ( rx_reset ),
  .clear_count      ( clear_count ),
  .enable           ( rx_enable && data_pattern_select[2] ),

  .rx_dataout       ( loc_rx_dataout ),
  .rx_enaout        ( loc_rx_enaout ),
  .rx_sopout        ( loc_rx_sopout ),
  .rx_eopout        ( loc_rx_eopout ),
  .rx_errout        ( loc_rx_errout ),
  .rx_mtyout        ( loc_rx_mtyout ),

  .error_count      ( rx_data_err_count ),
  .error_overflow   ( rx_data_err_overflow )
);

  wire [1:0] loc_tx_enain;
  wire [1:0] loc_tx_sopin;
  wire [1:0] loc_tx_eopin;
  wire [1:0] loc_tx_errin;
  wire [5:0] loc_tx_mtyin;
  wire [127:0] loc_tx_datain;

  assign loc_tx_enain = tx_enain;
  assign loc_tx_sopin = tx_sopin;
  assign loc_tx_eopin = tx_eopin;
  assign loc_tx_errin = tx_errin;
  assign loc_tx_mtyin = tx_mtyin;
  assign loc_tx_datain = tx_datain;

l_ethernet_40G_qsfp_d_0_mac_traf_chk1 i_l_ethernet_40G_qsfp_d_0_TRAF_CHK2 (                         // Counter for packets sent

  .clk              ( tx_clk ),
  .reset            ( tx_reset ),
  .enable           ( tx_enable || loc_pkt_tx_busy || loc_traf_tx_busy ),               // Need to keep the tx counters enabled until traffic is stopped.
  .clear_count      ( clear_count ),

  .rx_dataout       ( loc_tx_datain ),
  .rx_enaout        ( loc_tx_enain ),
  .rx_sopout        ( loc_tx_sopin ),
  .rx_eopout        ( loc_tx_eopin ),
  .rx_errout        ( loc_tx_errin ),
  .rx_mtyout        ( loc_tx_mtyin ),
  .protocol_error   ( ),
  .packet_count     ( tx_sent_count ),
  .total_bytes      ( tx_total_bytes ),
  .prot_err_count   ( ),
  .error_count      ( ),
  .packet_count_overflow   ( tx_sent_overflow ),
  .total_bytes_overflow    ( tx_total_bytes_overflow ),
  .prot_err_overflow       ( ),
  .error_overflow          ( )
);




endmodule


module l_ethernet_40G_qsfp_d_0_mac_traf_gen1 #(
  parameter integer min_pkt_len = 64,
                    max_pkt_len = 9000
  ) (                       // Generator to send packet stream

  input  wire clk,
  input  wire reset,
  input  wire enable,
  input  wire tx_rdyout,
  input  wire tx_ovfout,
  input  wire rx_lane_align,
  input  wire [31:0] packet_count,

  output reg [127:0] tx_datain,
  output reg [1:0] tx_enain,
  output reg [1:0] tx_sopin,
  output reg [1:0] tx_eopin,
  output reg [1:0] tx_errin,
  output reg [5:0] tx_mtyin,
  output wire time_out,                 // 1 second timeout
  output reg  busy,                 // indicator that the traffic generator is operating
  output wire done
);

reg [1:0] q_en;
reg [31:0] rand1;
wire [31:0] nxt_rand1;
wire [127:0] nxt_d;
reg [127:0] d_buff;
reg [31:0] counter;
reg [2:0] bsy_cntr;

reg [1:0]  lane_mask;

reg [29:0] op_timer;
reg [31:0] packet_counter;
reg en_stop;

wire ready =  rx_lane_align && tx_rdyout && ~tx_ovfout ;


localparam [32:0] DATA_POLYNOMIAL = 33'b100001000001010000000010010000001;
localparam [31:0] init_crc = 32'b11010111011110111101100110001011;


localparam [47:0] dest_addr   = 48'hFF_FF_FF_FF_FF_FF;            // Broadcast
localparam [47:0] source_addr = 48'h14_FE_B5_DD_9A_82;            // Hardware address of xowjcoppens40
localparam [15:0] length_type = 16'h0600;                       // XEROX NS IDP
localparam [111:0] eth_header = { dest_addr, source_addr, length_type} ;

/* Parameter definitions of STATE variables for 2 bit state machine */
localparam [2:0]  S0 = 3'b000,
                  S1 = 3'b001,
                  S2 = 3'b011,
                  S3 = 3'b010,
                  S4 = 3'b110,
                  S5 = 3'b111,
                  S6 = 3'b101,
                  S7 = 3'b100;

reg [2:0] state;

l_ethernet_40G_qsfp_d_0_mac_pktprbs_gen #(
  .BIT_COUNT(128)
) i_l_ethernet_40G_qsfp_d_0_PKT_PRBS_GEN (
  .ip(rand1),
  .op(nxt_rand1),
  .datout(nxt_d)
);

// reg gen_length;
// reg [3:0] pwr_up;
wire [16:0] pkt_len;
reg set_eop;
reg set_sop;

l_ethernet_40G_qsfp_d_0_mac_pkt_len_gen
 #(
 .min(min_pkt_len),
 .max(max_pkt_len)
 ) i_l_ethernet_40G_qsfp_d_0_PKT_LEN_GEN  (
  .clk      ( clk ),
  .reset   ( reset ),
//.enable   ( gen_length ),
  .enable   ( 1'b1 ),
  .pkt_len  ( pkt_len )
  );

assign time_out = ~|op_timer,
       done     = (state==S7);

reg [0:0] byte_remainder;

always @( posedge clk )
    begin
      if ( reset == 1'b1 ) begin
    tx_datain <= 128'd0 ;
    tx_enain <= 0 ;
    tx_sopin <= 0 ;
    tx_eopin <= 0 ;
    tx_errin <= 0 ;
    tx_mtyin <= 0 ;
    state <= S0;
    q_en <= 0;
    rand1 <= init_crc;
    counter <= 0;
    d_buff <= 128'd0 ;
    op_timer <= 30'd390625000 ;
//  pwr_up <= 0;
    set_eop <= 0;
    set_sop <= 0;
    lane_mask <= 0;
    packet_counter <= 0;
    bsy_cntr <= 0;
    en_stop <= 0;
    byte_remainder <= 0;
  end
  else begin :main_loop
    reg [0:0] next_byte_remainder;
    next_byte_remainder = 3 - pkt_len[3+:2] ;
//  pwr_up <= ~&pwr_up ? pwr_up+1 : pwr_up;
//  gen_length <= ~&pwr_up;             // This flushes the length pipe
    tx_datain <= 128'd0 ;                // default to zero
    tx_enain <= 0 ;
    tx_sopin <= 0 ;
    tx_eopin <= 0 ;
    tx_errin <= 0 ;
    tx_mtyin <= 0 ;

    q_en <= {q_en, enable};

    case(state)
      S0: if (q_en == 2'b01) state <= S1;
      S1: if (ready) state <= S2;
      S2: begin
            packet_counter <= packet_count;
            en_stop <= ~&packet_count;
            rand1 <= init_crc;
//          gen_length <= 1'b1;
            state <= S3;
          end
      S3: begin
            counter <= pkt_len;
            byte_remainder <= next_byte_remainder;
            set_eop <= pkt_len<16;
            set_sop <= 1'b1;
            d_buff <= swapn(nxt_d);
            rand1 <= nxt_rand1;
            state <= |packet_count ? S4 : S7;
            if ( en_stop ) packet_counter <= packet_counter-1;
          end
      S4: if (tx_rdyout) begin :zulu
            rand1 <= nxt_rand1;
            d_buff <= swapn(nxt_d);
            tx_sopin[1] <= set_sop;
            tx_eopin[byte_remainder] <= set_eop;
            tx_datain <= d_buff;
            if(set_sop) tx_datain[127-:112] <= eth_header ;
            set_sop <= 0;
            if(set_eop)begin
              tx_enain <= {2{1'b1}} << byte_remainder ;
              byte_remainder <= next_byte_remainder;
              state <= (|packet_counter && |q_en) ? S4 : S7;
              set_sop <= 1'b1;
              if ( en_stop ) packet_counter <= packet_counter-1;
              counter <= pkt_len;                       // get length of next packet to send
              set_eop <= pkt_len<16;
              tx_mtyin[{byte_remainder,2'b0}+:3] <= ~counter[0+:3];
//            gen_length <= 1'b1;
            end
            else begin
              state <= S4;
              counter <= counter - 16;
              set_eop <= counter < 2*16;
              next_byte_remainder = 3 - counter[3+:2] ;
              byte_remainder <= next_byte_remainder ;
              tx_enain <= {2{1'b1}};
            end
          end
      S7: state <= |q_en ? S7 : S0;

    endcase

    case(state)
      S0,S7:   op_timer <= 30'd390625000 ;
      S4:      if(tx_rdyout) op_timer <= 30'd390625000 ;
      default: op_timer <= |op_timer ? op_timer - 1 : op_timer ;
    endcase

    if ( state <= S0 ) begin
      bsy_cntr <= |bsy_cntr ? bsy_cntr - 1 : bsy_cntr ;             // Hold the busy signal for 8 additional cycles.
      busy <= |bsy_cntr;
    end
    else begin
      busy <= 1'b1;
      bsy_cntr <= {3{1'b1}};
    end

  end
end


function [127:0]  swapn (input [127:0]  d);
integer i;
for (i=0; i<=(127); i=i+8) swapn[i+:8] = d[(127-i)-:8];
endfunction

endmodule

module l_ethernet_40G_qsfp_d_0_mac_traf_chk1 (

  input wire clk,
  input wire reset,
  input wire enable,
  input wire clear_count,

  input wire [127:0] rx_dataout,
  input wire [1:0] rx_enaout,
  input wire [1:0] rx_sopout,
  input wire [1:0] rx_eopout,
  input wire [1:0] rx_errout,
  input wire [5:0] rx_mtyout,

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
reg [2:0]  d1_errout;
reg  [1:0] sop_count,eop_count,ena_count;
reg  [1:0] sop_last_bit,eop_last_bit,ena_first_zero,ena_last_zero;
reg [2:0] m_sop,m_eop,m_ena;
reg [4:0] n1,n2;
reg [5:0] d1_mtyout;
reg [4:0] add_bytes;
reg [4:0] mty_bytes;
reg [1:0] err_chk1,err_chk2,err_chk3,err_chk4,err_chk5,err_chk6;
reg [4:0] delta_bytes;
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
always @( posedge clk )
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
    ena_first_zero <= 0;
    ena_last_zero <= 0;
    ena_count <= 0;
    sop_count <= 0;
    eop_count <= 0;
    m_ena <= 0;
    m_sop <= 0;
    m_eop <= 0;
    sop_last_bit <= 0;
    eop_last_bit <= 0;
    add_bytes <= 0;
    mty_bytes <= 0;
    n1 <= 0;
    n2 <= 0;
    d1_mtyout <= 0;
    d1_errout <= 0;
    err_chk1 <= 0;
    err_chk2 <= 0;
    err_chk3 <= 0;
    err_chk4 <= 0;
    err_chk5 <= 0;
    err_chk6 <= 0;
  end
  else begin
    ena_count <= bit_count(rx_enaout);
    sop_count <= bit_count(rx_sopout & rx_enaout);
    eop_count <= bit_count(rx_eopout & rx_enaout);
    m_ena <= {m_ena,|rx_enaout};
    m_sop <= {m_sop,|(rx_sopout & rx_enaout)};
    m_eop <= {m_eop,|(rx_eopout & rx_enaout)};
    ena_first_zero <= first_zero(rx_enaout);
    ena_last_zero <= last_zero(rx_enaout);
    sop_last_bit <= last_bit(rx_sopout & rx_enaout);
    eop_last_bit <= last_bit(rx_eopout & rx_enaout);
    add_bytes <= sop_bytes(sop_last_bit);
    mty_bytes <= eop_bytes(eop_last_bit,d1_mtyout);
    n1 <= {1'b0,add_bytes} - {1'b0,mty_bytes};
    n2 <= 5'd16 + {1'b0,add_bytes} - {1'b0,mty_bytes};
    d1_mtyout <= rx_mtyout;
    err_chk1 <= {err_chk1,((sop_count > 1) || (eop_count > 1))};
    err_chk2 <= {err_chk2,(|sop_last_bit && |eop_last_bit && (sop_last_bit <= eop_last_bit))};      // Protocol error during state2 end of packet if sop comes before (or same time as) eop
    err_chk3 <= {err_chk3,(|sop_last_bit && |eop_last_bit && (sop_last_bit > eop_last_bit))};       // Protocol error during state1 start of packet if eop comes before sop
    err_chk4 <= {err_chk4,(ena_count!=2) && (ena_count!=0)};                     // Protocol error during state1 or state2 if weird number of ena signals are set without eop or sop
    err_chk5 <= {err_chk5,(|ena_first_zero && (ena_first_zero < eop_last_bit))};       // Protocol error during state2 if there is a low ena before the eop
    err_chk6 <= {err_chk6,(|ena_last_zero &&  (ena_last_zero > sop_last_bit))};       // Protocol error during state1 if there is a low ena after the sop
    d1_errout <= {d1_errout,|(rx_enaout & rx_eopout & rx_errout)};
    delta_bytes <= 0;
    inc_pct_cntr <= 0;
    inc_err_cntr <= 0;
    protocol_error <= 0;
    q_en <= {q_en, enable};

    case (state)
      S0: if (q_en == 2'b01) state <= S1;
      S1: case({m_sop[2],m_eop[2]})
            2'b01: protocol_error <= 1'b1;
            2'b10: begin
                     state <= S2;
                     delta_bytes <= n1;
                     if(err_chk1[1] || err_chk6[1]) protocol_error <= 1'b1;
                   end
            2'b11: begin
                     state <= S1;
                     delta_bytes <= n1;
                     inc_pct_cntr <= 1'b1;
                     if(d1_errout[2]) inc_err_cntr <= 1'b1;
                     if(err_chk1[1] || err_chk3[1]) protocol_error <= 1'b1;
                   end
          endcase
      S2: case({m_sop[2],m_eop[2]})
            2'b10: protocol_error <= 1'b1;
            2'b01: begin
                     if(err_chk1[1] || err_chk5[1]) protocol_error <= 1'b1;
                     state <= S1;
                     delta_bytes <= n1;
                     inc_pct_cntr <= 1'b1;
                     if(d1_errout[2]) inc_err_cntr <= 1'b1;
                   end
            2'b11: begin
                     if(err_chk1[1] || err_chk2[1] || err_chk5[1] || err_chk6[1]) protocol_error <= 1'b1;
                     state <= S2;
                     delta_bytes <= n2;
                     inc_pct_cntr <= 1'b1;
                     if(d1_errout[2]) inc_err_cntr <= 1'b1;
                   end
            default: begin
                       if(m_ena[2]) delta_bytes <= n1;
                       if(err_chk4[1]) protocol_error <= 1'b1;
                     end
          endcase


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
// synthesis translate_off
  reg [8*12-1:0] state_text;                    // Enumerated type conversion to text
  always @(state) case (state)
    S0: state_text = "S0" ;
    S1: state_text = "S1" ;
    S2: state_text = "S2" ;
    S3: state_text = "S3" ;
  endcase
`endif

function [1:0] bit_count( input [1:0] d );              // Count the number of set bits.
integer n,i;
begin
n=0;
for(i=0;i<2;i=i+1) if(d[i]) n=n+1;
bit_count = n;
end
endfunction

function [1:0] last_zero( input [1:0] d );              // Return the first set bit (1..2)
integer n,i;
begin
n=0;
for(i=0;i<2;i=i+1) if(!d[1-i]) n=i+1;
last_zero = n;
end
endfunction

function [1:0] first_zero( input [1:0] d );              // Return the first set bit (1..2)
integer n,i;
begin
n=0;
for(i=1;i>=0;i=i-1) if(!d[1-i]) n=i+1;
first_zero = n;
end
endfunction

function [1:0] last_bit( input [1:0] d );              // Return the last set bit (1..2)
integer n,i;
begin
n=0;
for(i=0;i<2;i=i+1) if(d[1-i]) n=i+1;
last_bit = n;
end
endfunction

function [4:0] sop_bytes( input [1:0] n );              // Return the bytes in a frame starting with sop
case(n)
   2'd1: sop_bytes = 5'd16;
   2'd2: sop_bytes = 5'd8;
   default: sop_bytes = 5'd16;
endcase
endfunction

function [4:0] eop_bytes( input [1:0] n, input [5:0] mty );              // Return the empty bytes in a frame
case(n)
   2'd1: eop_bytes = { 2'h1, mty[3+:3] } ;
   2'd2: eop_bytes = { 2'h0, mty[0+:3] } ;
   default: eop_bytes = 5'd0;
endcase
endfunction

endmodule

module l_ethernet_40G_qsfp_d_0_mac_traf_data_chk (

  input wire clk,
  input wire reset,
  input wire enable,
  input wire clear_count,

  input wire [127:0] rx_dataout,
  input wire [1:0] rx_enaout,
  input wire [1:0] rx_sopout,
  input wire [1:0] rx_eopout,
  input wire [1:0] rx_errout,
  input wire [5:0] rx_mtyout,

  output wire [31:0] error_count,
  output wire error_overflow
);
reg [32:0] err_cntr;
assign error_count            = err_cntr[32] ? {32{1'b1}} : err_cntr[31:0],
       error_overflow         = err_cntr[32];

localparam [47:0] dest_addr   = 48'hFF_FF_FF_FF_FF_FF;            // Broadcast
localparam [47:0] source_addr = 48'h14_FE_B5_DD_9A_82;            // Hardware address of xowjcoppens40
localparam [15:0] length_type = 16'h0600;                       // XEROX NS IDP
localparam [111:0] eth_header = { dest_addr, source_addr, length_type} ;
/* Parameter definitions of STATE variables for 2 bit state machine */
localparam [2:0]  S0 = 3'b000,
                  S1 = 3'b001,
                  S2 = 3'b011,
                  S3 = 3'b010,
                  S4 = 3'b110;
reg [2:0] state;
reg [31:0] crc_ip1;
reg [31:0] crc_ip2[0:1];
wire [31:0] nxt_crc;
reg set_derr;

wire [ 127:0] dat1,dat2;
wire [ 127:0] exp1,exp2;

l_ethernet_40G_qsfp_d_0_mac_pktprbs_gen
 #(
  .BIT_COUNT ( 128 )
) i_l_ethernet_40G_qsfp_d_0_PKTPRBS_GEN1 (
  .ip         ( crc_ip1 ),
  .op         (  ),
  .datout     ( dat1 )
);

l_ethernet_40G_qsfp_d_0_mac_pktprbs_gen
 #(
  .BIT_COUNT ( 128 )
) i_l_ethernet_40G_qsfp_d_0_PKTPRBS_GEN2 (
  .ip         ( crc_ip2[1] ),
  .op         ( nxt_crc ),
  .datout     ( dat2 )
);

assign exp1 = swapn ( dat1 ) ;
assign exp2 = swapn ( dat2 ) ;

reg [ 127:0] zzmask[0:2];
reg [ 127:0] cmpr[0:2];
reg [ 127:0] d_dat[0:2];
reg [2:0] d_ena;
reg [2:0] d_sop;
reg [2:0] d_eop;
reg [2:0] v_pkt;
reg [0:0] sop_offset;
reg [ 127:0] cmpA, cmpB, mask1, mask2;
reg [ 127:0] d_mask2;
reg [1:0] split_crc;
reg  ena_msk;
reg  en_msk1;
reg  en_crc1;

integer i;

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
        sop_offset <= 1'h0;
        en_msk1 <= 0;
        en_crc1 <= 0;
        state <= S0;
        cmpA <= 128'h0;
        cmpB <= 128'h0;
        mask1 <= 128'h0;
        mask2 <= 128'h0;
        d_mask2 <= 128'h0;
        split_crc <= 0;
        ena_msk <= 0;
        for (i=0; i<=2; i=i+1) zzmask[i] <= 128'h0;
        for (i=0; i<=2; i=i+1) cmpr[i] <= 128'h0;
        for (i=0; i<=2; i=i+1) d_dat[i] <= 128'h0;

      end
      else begin :read_loop
        reg loc_sop,loc_eop, start_stop, stop_start;
        loc_sop = |( rx_enaout & rx_sopout ) ;
        loc_eop = |( rx_enaout & rx_eopout ) ;
        start_stop = rx_enaout[1] && rx_sopout[1] && rx_enaout[0] & rx_eopout[0]  ;
        stop_start = loc_eop && loc_sop && !start_stop;

        d_ena <= {d_ena, |rx_enaout && enable};
        d_sop <= {d_sop, loc_sop };
        d_eop <= {d_eop, loc_eop };
        v_pkt <= {v_pkt, ( v_pkt[0] ? loc_sop || ~loc_eop : loc_sop && ~loc_eop ) } ;

        d_dat[0] <= rx_dataout;
        for (i=1; i<=2; i=i+1) zzmask[i] <= zzmask[i-1] ;
        for (i=1; i<=2; i=i+1) cmpr[i] <= cmpr[i-1] ;
        for (i=1; i<=2; i=i+1) d_dat[i] <= d_dat[i-1] ;
        if(|rx_enaout) en_crc1 <= 0;
        en_msk1 <= 0;
        if(d_ena[0]) d_mask2 <= mask2 ;
        if(d_ena[1]) begin
          cmpr[2] <= ( cmpA & mask1 ) | ( cmpB & d_mask2 ) ;
          zzmask[2] <= mask1 | d_mask2  ;
        end

        if(d_ena[0]) begin
          crc_ip2[1] <= en_crc1 ? crc_ip2[0] : nxt_crc ;
          cmpA <= {eth_header,16'h0} >> {sop_offset, 6'd0} ;
          mask1 <= {{112{en_msk1}},16'h0} >> {sop_offset,6'd0} ;
        end
        case ( state )
          S1: if (|rx_enaout) begin
                crc_ip1    <= crc_swapn(rx_dataout[48+:32]) ;
                crc_ip2[0] <= crc_swapn(rx_dataout[0+:32]) ;
                ena_msk <= 1'b1;
                en_msk1 <= 1'b1;
                en_crc1 <= 1'b1;
                state <= S2;
              end
          S2: if (d_ena[0]) begin
                cmpA <= {eth_header, 32'h0,exp1[127-:48]} ;
                mask1 <= {{112{en_msk1}},32'h0,{48{en_msk1}} } ;
                state <= S0;
              end
          S3: if (|rx_enaout) begin
                crc_ip1 <= crc_swapn( {crc_ip1[0+:16], rx_dataout[127-:16] } );
                crc_ip2[0] <= crc_swapn(rx_dataout[0+:32]) ;
                ena_msk <= 1'b1;
                en_crc1 <= 1'b1;
                state <= S4;
              end
          S4: if (d_ena[0]) begin
                cmpA <= exp1 >> 16 ;
                mask1 <= {128{en_msk1}} >> 16 ;
                state <= S0;
              end
          default: state <= S0;
        endcase
        if(d_ena[0]) cmpB <= exp2 ;

        casez ( rx_enaout & rx_sopout )
          2'b?1: begin
                     ena_msk <= 1'b0;
                     en_crc1 <= 1'b0;
                     en_msk1 <= 1'b1;
                     state <= S1;
                     sop_offset <= 1'd1;
                   end
          2'b1?: begin
                     crc_ip1 <= rx_dataout[0+:32] ;
                     state <= S3;
                     ena_msk <= 1'b0;
                     sop_offset <= 1'd0;
                     en_msk1 <= 1'b1;
                   end
        endcase

        if ( |rx_enaout ) casez ( rx_enaout & rx_eopout )
          2'b?1: mask2 <= {128{1'b1}} << {1'd0,rx_mtyout[0+:3],3'b0};
          2'b1?: mask2 <= {128{1'b1}} << {1'd1,rx_mtyout[3+:3],3'b0};
          default: mask2 <= {128{ena_msk}} ;
        endcase
        else mask2 <= 128'h0 ;

        if ( loc_eop && ~loc_sop )  ena_msk <= 0;
        set_derr <= |{(cmpr[2] ^ d_dat[2]) & zzmask[2] } && d_ena[2] && v_pkt[2];

        if(set_derr && !err_cntr[32]) err_cntr <= err_cntr + 1;

        if(clear_count) err_cntr <= 33'h0;

      end
    end

function [127:0]  swapn (input [127:0]  d);
integer i;
for (i=0; i<=(127); i=i+8) swapn[i+:8] = d[(127-i)-:8];
endfunction

function [31:0] crc_swapn (input [31:0] d);
integer i;
for (i=0; i<=31; i=i+1) crc_swapn[i] = d[{i[5:3],~i[2:0]}];
endfunction


endmodule

module l_ethernet_40G_qsfp_d_0_mac_pkt_len_gen #(
  parameter integer min=64,
                    max=9000
      ) (
  input  wire clk,
  input  wire reset,
  input  wire enable,
  output reg [16:0] pkt_len
  );

localparam [32:0] CRC_POLYNOMIAL = 33'b100001000001010000000010010000001;
localparam [31:0] init_crc = 32'b11010111011110111101100110001011;
localparam integer pkt_diff = max - min + 1;

reg [31:0] p1[0:15], p2[0:7], p3[0:3], p4[0:1], p5;

reg [31:0] CRC;

integer i;
always @( posedge clk )
    begin
      if ( reset == 1'b1 ) begin
    for(i=0;i<16;i=i+1) p1[i]<=0;
    for(i=0;i<8;i=i+1)  p2[i]<=0;
    for(i=0;i<4;i=i+1)  p3[i]<=0;
    for(i=0;i<2;i=i+1)  p4[i]<=0;
                        p5   <=0;
    pkt_len <= 0;
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


module l_ethernet_40G_qsfp_d_0_mac_lbus_buf #(
        parameter integer IS_0_LATENCY = 0                      // default to single cycle latency
        ) (

  input  wire clk,
  input  wire reset,
  input wire [127:0] tx_datain,
  input wire [1:0] tx_enain,
  input wire [1:0] tx_sopin,
  input wire [1:0] tx_eopin,
  input wire [1:0] tx_errin,
  input wire [5:0] tx_mtyin,

  output wire [127:0] tx_dataout,
  output wire [1:0] tx_enaout,
  output wire [1:0] tx_sopout,
  output wire [1:0] tx_eopout,
  output wire [1:0] tx_errout,
  output wire [5:0] tx_mtyout,
  input  wire tx_rdyin,
  output  reg tx_rdyout
);

reg [141:0] rd_buf[0:7];
reg [2:0] waddr;

generate
if ( IS_0_LATENCY ) begin               // If this is a zero latency implementation

reg [2:0] waddr_p1;


wire [1:0] my_tx_enaout;
assign { tx_dataout, my_tx_enaout, tx_sopout, tx_eopout, tx_errout, tx_mtyout } = rd_buf[0];
assign tx_enaout = my_tx_enaout;

integer i;
always @( posedge clk )
    begin
      if ( reset == 1'b1 ) begin
        waddr <= 3'h0;
        waddr_p1 <= 3'h1;
        tx_rdyout <= 0;
        for(i=0;i<8;i=i+1) rd_buf[i] <= 142'h0;
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

reg [127:0] loc_tx_dataout;
reg [1:0] loc_tx_enaout;
reg [1:0] loc_tx_sopout;
reg [1:0] loc_tx_eopout;
reg [1:0] loc_tx_errout;
reg [5:0] loc_tx_mtyout;

reg [141:0] qd1;
wire [141:0] rd1;
reg [2:0] raddr;

assign { tx_dataout, tx_enaout, tx_sopout, tx_eopout, tx_errout, tx_mtyout } = { loc_tx_dataout, loc_tx_enaout, loc_tx_sopout, loc_tx_eopout, loc_tx_errout, loc_tx_mtyout } ;

integer i;
always @( posedge clk )
    begin
      if ( reset == 1'b1 ) begin
        qd1 <= 142'h0;
        waddr <= 3'h0;
        raddr <= 3'h0;
        tx_rdyout <= 0;
        for(i=0;i<8;i=i+1) rd_buf[i] <= 142'h0;
        { loc_tx_dataout, loc_tx_enaout, loc_tx_sopout, loc_tx_eopout, loc_tx_errout, loc_tx_mtyout } <= 142'h0;
      end
      else begin
        if(tx_rdyin && (raddr != waddr) ) begin
          { loc_tx_dataout, loc_tx_enaout, loc_tx_sopout, loc_tx_eopout, loc_tx_errout, loc_tx_mtyout } <= rd_buf[raddr];
          raddr <= ( raddr + 1 ) % 8 ;
        end
        else begin
          { loc_tx_dataout, loc_tx_enaout, loc_tx_sopout, loc_tx_eopout, loc_tx_errout, loc_tx_mtyout } <= 142'hx;
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

module l_ethernet_40G_qsfp_d_0_mac_pktprbs_gen
 #(
  parameter BIT_COUNT = 64
) (
  input   wire [31:0] ip,
  output  wire [31:0] op,
  output  wire [(BIT_COUNT-1):0] datout
);

//     G(x) = x32 + x27 + x21 + x19 + x10 + x7 + 1
localparam [32:0] CRC_POLYNOMIAL = 33'b100001000001010000000010010000001;

localparam REMAINDER_SIZE = 32;

generate

case (BIT_COUNT)

  1280: begin :gen_1280_loop
          assign op[0] = ip[1]^ip[4]^ip[5]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[31],
                 op[1] = ip[0]^ip[2]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[29],
                 op[2] = ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[30],
                 op[3] = ip[2]^ip[4]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[31],
                 op[4] = ip[0]^ip[3]^ip[5]^ip[7]^ip[8]^ip[9]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26],
                 op[5] = ip[1]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27],
                 op[6] = ip[2]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28],
                 op[7] = ip[3]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29],
                 op[8] = ip[4]^ip[7]^ip[9]^ip[11]^ip[12]^ip[13]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 op[9] = ip[5]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 op[10] = ip[0]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 op[11] = ip[0]^ip[1]^ip[8]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[19]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 op[12] = ip[0]^ip[1]^ip[2]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[25]^ip[26]^ip[30],
                 op[13] = ip[1]^ip[2]^ip[3]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[31],
                 op[14] = ip[0]^ip[2]^ip[3]^ip[4]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[22]^ip[23]^ip[28],
                 op[15] = ip[1]^ip[3]^ip[4]^ip[5]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[23]^ip[24]^ip[29],
                 op[16] = ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[24]^ip[25]^ip[30],
                 op[17] = ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[25]^ip[26]^ip[31],
                 op[18] = ip[0]^ip[4]^ip[6]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[22]^ip[26],
                 op[19] = ip[1]^ip[5]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[23]^ip[27],
                 op[20] = ip[2]^ip[6]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[24]^ip[28],
                 op[21] = ip[3]^ip[7]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[25]^ip[29],
                 op[22] = ip[4]^ip[8]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[26]^ip[30],
                 op[23] = ip[5]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[27]^ip[31],
                 op[24] = ip[0]^ip[6]^ip[7]^ip[12]^ip[14]^ip[16]^ip[17]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28],
                 op[25] = ip[1]^ip[7]^ip[8]^ip[13]^ip[15]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29],
                 op[26] = ip[2]^ip[8]^ip[9]^ip[14]^ip[16]^ip[18]^ip[19]^ip[22]^ip[24]^ip[26]^ip[29]^ip[30],
                 op[27] = ip[3]^ip[9]^ip[10]^ip[15]^ip[17]^ip[19]^ip[20]^ip[23]^ip[25]^ip[27]^ip[30]^ip[31],
                 op[28] = ip[0]^ip[4]^ip[7]^ip[11]^ip[16]^ip[18]^ip[19]^ip[20]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 op[29] = ip[0]^ip[1]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[17]^ip[20]^ip[25]^ip[28]^ip[29],
                 op[30] = ip[1]^ip[2]^ip[6]^ip[8]^ip[9]^ip[11]^ip[13]^ip[18]^ip[21]^ip[26]^ip[29]^ip[30],
                 op[31] = ip[2]^ip[3]^ip[7]^ip[9]^ip[10]^ip[12]^ip[14]^ip[19]^ip[22]^ip[27]^ip[30]^ip[31];

          assign datout[0] = ip[6]^ip[9]^ip[18]^ip[20]^ip[26]^ip[31],
                 datout[1] = ip[5]^ip[8]^ip[17]^ip[19]^ip[25]^ip[30],
                 datout[2] = ip[4]^ip[7]^ip[16]^ip[18]^ip[24]^ip[29],
                 datout[3] = ip[3]^ip[6]^ip[15]^ip[17]^ip[23]^ip[28],
                 datout[4] = ip[2]^ip[5]^ip[14]^ip[16]^ip[22]^ip[27],
                 datout[5] = ip[1]^ip[4]^ip[13]^ip[15]^ip[21]^ip[26],
                 datout[6] = ip[0]^ip[3]^ip[12]^ip[14]^ip[20]^ip[25],
                 datout[7] = ip[2]^ip[6]^ip[9]^ip[11]^ip[13]^ip[18]^ip[19]^ip[20]^ip[24]^ip[26]^ip[31],
                 datout[8] = ip[1]^ip[5]^ip[8]^ip[10]^ip[12]^ip[17]^ip[18]^ip[19]^ip[23]^ip[25]^ip[30],
                 datout[9] = ip[0]^ip[4]^ip[7]^ip[9]^ip[11]^ip[16]^ip[17]^ip[18]^ip[22]^ip[24]^ip[29],
                 datout[10] = ip[3]^ip[8]^ip[9]^ip[10]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[31],
                 datout[11] = ip[2]^ip[7]^ip[8]^ip[9]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[30],
                 datout[12] = ip[1]^ip[6]^ip[7]^ip[8]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[21]^ip[24]^ip[26]^ip[29],
                 datout[13] = ip[0]^ip[5]^ip[6]^ip[7]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[23]^ip[25]^ip[28],
                 datout[14] = ip[4]^ip[5]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[26]^ip[27]^ip[31],
                 datout[15] = ip[3]^ip[4]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[25]^ip[26]^ip[30],
                 datout[16] = ip[2]^ip[3]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[24]^ip[25]^ip[29],
                 datout[17] = ip[1]^ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[24]^ip[28],
                 datout[18] = ip[0]^ip[1]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[27],
                 datout[19] = ip[0]^ip[4]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[31],
                 datout[20] = ip[3]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[26]^ip[30]^ip[31],
                 datout[21] = ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[25]^ip[29]^ip[30],
                 datout[22] = ip[1]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[24]^ip[28]^ip[29],
                 datout[23] = ip[0]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[18]^ip[23]^ip[27]^ip[28],
                 datout[24] = ip[3]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[27]^ip[31],
                 datout[25] = ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[26]^ip[30],
                 datout[26] = ip[1]^ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[25]^ip[29],
                 datout[27] = ip[0]^ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[24]^ip[28],
                 datout[28] = ip[1]^ip[3]^ip[4]^ip[8]^ip[11]^ip[13]^ip[14]^ip[16]^ip[20]^ip[23]^ip[26]^ip[27]^ip[31],
                 datout[29] = ip[0]^ip[2]^ip[3]^ip[7]^ip[10]^ip[12]^ip[13]^ip[15]^ip[19]^ip[22]^ip[25]^ip[26]^ip[30],
                 datout[30] = ip[1]^ip[2]^ip[11]^ip[12]^ip[14]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[31] = ip[0]^ip[1]^ip[10]^ip[11]^ip[13]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30],
                 datout[32] = ip[0]^ip[6]^ip[10]^ip[12]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[33] = ip[5]^ip[6]^ip[11]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[34] = ip[4]^ip[5]^ip[10]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[35] = ip[3]^ip[4]^ip[9]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[29],
                 datout[36] = ip[2]^ip[3]^ip[8]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[28],
                 datout[37] = ip[1]^ip[2]^ip[7]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[24]^ip[26]^ip[27],
                 datout[38] = ip[0]^ip[1]^ip[6]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26],
                 datout[39] = ip[0]^ip[5]^ip[6]^ip[9]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[31],
                 datout[40] = ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[41] = ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30],
                 datout[42] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29],
                 datout[43] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28],
                 datout[44] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27],
                 datout[45] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[19]^ip[21]^ip[25]^ip[31],
                 datout[46] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[24]^ip[26]^ip[30]^ip[31],
                 datout[47] = ip[1]^ip[2]^ip[4]^ip[10]^ip[12]^ip[13]^ip[14]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[48] = ip[0]^ip[1]^ip[3]^ip[9]^ip[11]^ip[12]^ip[13]^ip[17]^ip[19]^ip[22]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[49] = ip[0]^ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[16]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[50] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[15]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[51] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[14]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[52] = ip[3]^ip[4]^ip[5]^ip[8]^ip[13]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[53] = ip[2]^ip[3]^ip[4]^ip[7]^ip[12]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28]^ip[30],
                 datout[54] = ip[1]^ip[2]^ip[3]^ip[6]^ip[11]^ip[14]^ip[15]^ip[16]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[29],
                 datout[55] = ip[0]^ip[1]^ip[2]^ip[5]^ip[10]^ip[13]^ip[14]^ip[15]^ip[18]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28],
                 datout[56] = ip[0]^ip[1]^ip[4]^ip[6]^ip[12]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[57] = ip[0]^ip[3]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[13]^ip[16]^ip[17]^ip[19]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[58] = ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[16]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[59] = ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[60] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[61] = ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[12]^ip[13]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[62] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[11]^ip[12]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[26]^ip[27]^ip[30],
                 datout[63] = ip[0]^ip[1]^ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[25]^ip[29]^ip[31],
                 datout[64] = ip[0]^ip[2]^ip[4]^ip[6]^ip[8]^ip[10]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[24]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[65] = ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[13]^ip[14]^ip[15]^ip[16]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[66] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[12]^ip[13]^ip[14]^ip[15]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[67] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[68] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[69] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[70] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[30],
                 datout[71] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[72] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[16]^ip[21]^ip[22]^ip[24]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[73] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[9]^ip[15]^ip[18]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[74] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[14]^ip[17]^ip[18]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[75] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[13]^ip[16]^ip[17]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[76] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[9]^ip[12]^ip[15]^ip[16]^ip[18]^ip[21]^ip[23]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[77] = ip[0]^ip[1]^ip[3]^ip[8]^ip[9]^ip[11]^ip[14]^ip[15]^ip[17]^ip[18]^ip[22]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[78] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[79] = ip[1]^ip[5]^ip[7]^ip[8]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[80] = ip[0]^ip[4]^ip[6]^ip[7]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[81] = ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[82] = ip[2]^ip[4]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[83] = ip[1]^ip[3]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[84] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[85] = ip[1]^ip[5]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[86] = ip[0]^ip[4]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[87] = ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[88] = ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30],
                 datout[89] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[29],
                 datout[90] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28],
                 datout[91] = ip[1]^ip[2]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[92] = ip[0]^ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[93] = ip[0]^ip[2]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[94] = ip[1]^ip[4]^ip[7]^ip[8]^ip[13]^ip[14]^ip[16]^ip[17]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[95] = ip[0]^ip[3]^ip[6]^ip[7]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30],
                 datout[96] = ip[2]^ip[5]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29]^ip[31],
                 datout[97] = ip[1]^ip[4]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28]^ip[30],
                 datout[98] = ip[0]^ip[3]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[29],
                 datout[99] = ip[2]^ip[8]^ip[11]^ip[12]^ip[19]^ip[21]^ip[25]^ip[28]^ip[31],
                 datout[100] = ip[1]^ip[7]^ip[10]^ip[11]^ip[18]^ip[20]^ip[24]^ip[27]^ip[30],
                 datout[101] = ip[0]^ip[6]^ip[9]^ip[10]^ip[17]^ip[19]^ip[23]^ip[26]^ip[29],
                 datout[102] = ip[5]^ip[6]^ip[8]^ip[16]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28]^ip[31],
                 datout[103] = ip[4]^ip[5]^ip[7]^ip[15]^ip[19]^ip[21]^ip[24]^ip[25]^ip[27]^ip[30],
                 datout[104] = ip[3]^ip[4]^ip[6]^ip[14]^ip[18]^ip[20]^ip[23]^ip[24]^ip[26]^ip[29],
                 datout[105] = ip[2]^ip[3]^ip[5]^ip[13]^ip[17]^ip[19]^ip[22]^ip[23]^ip[25]^ip[28],
                 datout[106] = ip[1]^ip[2]^ip[4]^ip[12]^ip[16]^ip[18]^ip[21]^ip[22]^ip[24]^ip[27],
                 datout[107] = ip[0]^ip[1]^ip[3]^ip[11]^ip[15]^ip[17]^ip[20]^ip[21]^ip[23]^ip[26],
                 datout[108] = ip[0]^ip[2]^ip[6]^ip[9]^ip[10]^ip[14]^ip[16]^ip[18]^ip[19]^ip[22]^ip[25]^ip[26]^ip[31],
                 datout[109] = ip[1]^ip[5]^ip[6]^ip[8]^ip[13]^ip[15]^ip[17]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[110] = ip[0]^ip[4]^ip[5]^ip[7]^ip[12]^ip[14]^ip[16]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30],
                 datout[111] = ip[3]^ip[4]^ip[9]^ip[11]^ip[13]^ip[15]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[112] = ip[2]^ip[3]^ip[8]^ip[10]^ip[12]^ip[14]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[113] = ip[1]^ip[2]^ip[7]^ip[9]^ip[11]^ip[13]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29],
                 datout[114] = ip[0]^ip[1]^ip[6]^ip[8]^ip[10]^ip[12]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[28],
                 datout[115] = ip[0]^ip[5]^ip[6]^ip[7]^ip[11]^ip[15]^ip[16]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[116] = ip[4]^ip[5]^ip[9]^ip[10]^ip[14]^ip[15]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[117] = ip[3]^ip[4]^ip[8]^ip[9]^ip[13]^ip[14]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30],
                 datout[118] = ip[2]^ip[3]^ip[7]^ip[8]^ip[12]^ip[13]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[28]^ip[29],
                 datout[119] = ip[1]^ip[2]^ip[6]^ip[7]^ip[11]^ip[12]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[27]^ip[28],
                 datout[120] = ip[0]^ip[1]^ip[5]^ip[6]^ip[10]^ip[11]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[26]^ip[27],
                 datout[121] = ip[0]^ip[4]^ip[5]^ip[6]^ip[10]^ip[15]^ip[16]^ip[19]^ip[25]^ip[31],
                 datout[122] = ip[3]^ip[4]^ip[5]^ip[6]^ip[14]^ip[15]^ip[20]^ip[24]^ip[26]^ip[30]^ip[31],
                 datout[123] = ip[2]^ip[3]^ip[4]^ip[5]^ip[13]^ip[14]^ip[19]^ip[23]^ip[25]^ip[29]^ip[30],
                 datout[124] = ip[1]^ip[2]^ip[3]^ip[4]^ip[12]^ip[13]^ip[18]^ip[22]^ip[24]^ip[28]^ip[29],
                 datout[125] = ip[0]^ip[1]^ip[2]^ip[3]^ip[11]^ip[12]^ip[17]^ip[21]^ip[23]^ip[27]^ip[28],
                 datout[126] = ip[0]^ip[1]^ip[2]^ip[6]^ip[9]^ip[10]^ip[11]^ip[16]^ip[18]^ip[22]^ip[27]^ip[31],
                 datout[127] = ip[0]^ip[1]^ip[5]^ip[6]^ip[8]^ip[10]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[30]^ip[31],
                 datout[128] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[129] = ip[3]^ip[4]^ip[5]^ip[9]^ip[13]^ip[15]^ip[16]^ip[17]^ip[20]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[130] = ip[2]^ip[3]^ip[4]^ip[8]^ip[12]^ip[14]^ip[15]^ip[16]^ip[19]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[131] = ip[1]^ip[2]^ip[3]^ip[7]^ip[11]^ip[13]^ip[14]^ip[15]^ip[18]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[132] = ip[0]^ip[1]^ip[2]^ip[6]^ip[10]^ip[12]^ip[13]^ip[14]^ip[17]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[133] = ip[0]^ip[1]^ip[5]^ip[6]^ip[11]^ip[12]^ip[13]^ip[16]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[134] = ip[0]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[24]^ip[30]^ip[31],
                 datout[135] = ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[16]^ip[17]^ip[22]^ip[23]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[136] = ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[13]^ip[15]^ip[16]^ip[21]^ip[22]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[137] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[12]^ip[14]^ip[15]^ip[20]^ip[21]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[138] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[11]^ip[13]^ip[14]^ip[19]^ip[20]^ip[23]^ip[26]^ip[27]^ip[28],
                 datout[139] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[31],
                 datout[140] = ip[0]^ip[1]^ip[3]^ip[8]^ip[11]^ip[12]^ip[19]^ip[20]^ip[21]^ip[24]^ip[30]^ip[31],
                 datout[141] = ip[0]^ip[2]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[19]^ip[23]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[142] = ip[1]^ip[5]^ip[8]^ip[10]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[143] = ip[0]^ip[4]^ip[7]^ip[9]^ip[19]^ip[21]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[144] = ip[3]^ip[8]^ip[9]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[145] = ip[2]^ip[7]^ip[8]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[146] = ip[1]^ip[6]^ip[7]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[147] = ip[0]^ip[5]^ip[6]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[148] = ip[4]^ip[5]^ip[6]^ip[9]^ip[18]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[149] = ip[3]^ip[4]^ip[5]^ip[8]^ip[17]^ip[18]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[150] = ip[2]^ip[3]^ip[4]^ip[7]^ip[16]^ip[17]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[29],
                 datout[151] = ip[1]^ip[2]^ip[3]^ip[6]^ip[15]^ip[16]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28],
                 datout[152] = ip[0]^ip[1]^ip[2]^ip[5]^ip[14]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27],
                 datout[153] = ip[0]^ip[1]^ip[4]^ip[6]^ip[9]^ip[13]^ip[14]^ip[19]^ip[21]^ip[22]^ip[31],
                 datout[154] = ip[0]^ip[3]^ip[5]^ip[6]^ip[8]^ip[9]^ip[12]^ip[13]^ip[21]^ip[26]^ip[30]^ip[31],
                 datout[155] = ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[18]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[156] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[17]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[157] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[16]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[158] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[15]^ip[18]^ip[20]^ip[22]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[159] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[14]^ip[17]^ip[19]^ip[21]^ip[22]^ip[26]^ip[27]^ip[30],
                 datout[160] = ip[0]^ip[1]^ip[2]^ip[3]^ip[9]^ip[13]^ip[16]^ip[21]^ip[25]^ip[29]^ip[31],
                 datout[161] = ip[0]^ip[1]^ip[2]^ip[6]^ip[8]^ip[9]^ip[12]^ip[15]^ip[18]^ip[24]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[162] = ip[0]^ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[14]^ip[17]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[163] = ip[0]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[164] = ip[3]^ip[4]^ip[7]^ip[8]^ip[12]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[165] = ip[2]^ip[3]^ip[6]^ip[7]^ip[11]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[166] = ip[1]^ip[2]^ip[5]^ip[6]^ip[10]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[167] = ip[0]^ip[1]^ip[4]^ip[5]^ip[9]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[168] = ip[0]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[169] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[30]^ip[31],
                 datout[170] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[29]^ip[30],
                 datout[171] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[28]^ip[29],
                 datout[172] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[21]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[173] = ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[174] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[24]^ip[26]^ip[29]^ip[30],
                 datout[175] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[14]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[176] = ip[0]^ip[1]^ip[4]^ip[5]^ip[7]^ip[10]^ip[13]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[177] = ip[0]^ip[3]^ip[4]^ip[12]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[178] = ip[2]^ip[3]^ip[6]^ip[9]^ip[11]^ip[15]^ip[16]^ip[19]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[179] = ip[1]^ip[2]^ip[5]^ip[8]^ip[10]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[180] = ip[0]^ip[1]^ip[4]^ip[7]^ip[9]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[181] = ip[0]^ip[3]^ip[8]^ip[9]^ip[12]^ip[13]^ip[16]^ip[18]^ip[19]^ip[21]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[182] = ip[2]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[15]^ip[17]^ip[24]^ip[27]^ip[30]^ip[31],
                 datout[183] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[14]^ip[16]^ip[23]^ip[26]^ip[29]^ip[30],
                 datout[184] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[13]^ip[15]^ip[22]^ip[25]^ip[28]^ip[29],
                 datout[185] = ip[3]^ip[4]^ip[5]^ip[8]^ip[12]^ip[14]^ip[18]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[186] = ip[2]^ip[3]^ip[4]^ip[7]^ip[11]^ip[13]^ip[17]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[30],
                 datout[187] = ip[1]^ip[2]^ip[3]^ip[6]^ip[10]^ip[12]^ip[16]^ip[18]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[29],
                 datout[188] = ip[0]^ip[1]^ip[2]^ip[5]^ip[9]^ip[11]^ip[15]^ip[17]^ip[18]^ip[21]^ip[23]^ip[24]^ip[25]^ip[28],
                 datout[189] = ip[0]^ip[1]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[14]^ip[16]^ip[17]^ip[18]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[31],
                 datout[190] = ip[0]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[30]^ip[31],
                 datout[191] = ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[192] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[193] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[194] = ip[1]^ip[2]^ip[4]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[195] = ip[0]^ip[1]^ip[3]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[26]^ip[27]^ip[30],
                 datout[196] = ip[0]^ip[2]^ip[6]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[25]^ip[29]^ip[31],
                 datout[197] = ip[1]^ip[5]^ip[6]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[19]^ip[24]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[198] = ip[0]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[18]^ip[23]^ip[25]^ip[27]^ip[29]^ip[30],
                 datout[199] = ip[3]^ip[4]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[17]^ip[18]^ip[20]^ip[22]^ip[24]^ip[28]^ip[29]^ip[31],
                 datout[200] = ip[2]^ip[3]^ip[5]^ip[7]^ip[9]^ip[10]^ip[13]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[27]^ip[28]^ip[30],
                 datout[201] = ip[1]^ip[2]^ip[4]^ip[6]^ip[8]^ip[9]^ip[12]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[26]^ip[27]^ip[29],
                 datout[202] = ip[0]^ip[1]^ip[3]^ip[5]^ip[7]^ip[8]^ip[11]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[25]^ip[26]^ip[28],
                 datout[203] = ip[0]^ip[2]^ip[4]^ip[7]^ip[9]^ip[10]^ip[13]^ip[14]^ip[16]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[204] = ip[1]^ip[3]^ip[8]^ip[12]^ip[13]^ip[15]^ip[18]^ip[20]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[205] = ip[0]^ip[2]^ip[7]^ip[11]^ip[12]^ip[14]^ip[17]^ip[19]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30],
                 datout[206] = ip[1]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[207] = ip[0]^ip[8]^ip[9]^ip[10]^ip[12]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[208] = ip[6]^ip[7]^ip[8]^ip[11]^ip[14]^ip[19]^ip[21]^ip[24]^ip[27]^ip[29]^ip[31],
                 datout[209] = ip[5]^ip[6]^ip[7]^ip[10]^ip[13]^ip[18]^ip[20]^ip[23]^ip[26]^ip[28]^ip[30],
                 datout[210] = ip[4]^ip[5]^ip[6]^ip[9]^ip[12]^ip[17]^ip[19]^ip[22]^ip[25]^ip[27]^ip[29],
                 datout[211] = ip[3]^ip[4]^ip[5]^ip[8]^ip[11]^ip[16]^ip[18]^ip[21]^ip[24]^ip[26]^ip[28],
                 datout[212] = ip[2]^ip[3]^ip[4]^ip[7]^ip[10]^ip[15]^ip[17]^ip[20]^ip[23]^ip[25]^ip[27],
                 datout[213] = ip[1]^ip[2]^ip[3]^ip[6]^ip[9]^ip[14]^ip[16]^ip[19]^ip[22]^ip[24]^ip[26],
                 datout[214] = ip[0]^ip[1]^ip[2]^ip[5]^ip[8]^ip[13]^ip[15]^ip[18]^ip[21]^ip[23]^ip[25],
                 datout[215] = ip[0]^ip[1]^ip[4]^ip[6]^ip[7]^ip[9]^ip[12]^ip[14]^ip[17]^ip[18]^ip[22]^ip[24]^ip[26]^ip[31],
                 datout[216] = ip[0]^ip[3]^ip[5]^ip[8]^ip[9]^ip[11]^ip[13]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[217] = ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[218] = ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[219] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[220] = ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[221] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[30],
                 datout[222] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[25]^ip[29]^ip[31],
                 datout[223] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[24]^ip[28]^ip[30],
                 datout[224] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[23]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[225] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[226] = ip[1]^ip[2]^ip[4]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[227] = ip[0]^ip[1]^ip[3]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[228] = ip[0]^ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[17]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[229] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[230] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[231] = ip[3]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[232] = ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[30],
                 datout[233] = ip[1]^ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[26]^ip[27]^ip[29],
                 datout[234] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[11]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28],
                 datout[235] = ip[0]^ip[1]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[236] = ip[0]^ip[3]^ip[4]^ip[8]^ip[12]^ip[14]^ip[15]^ip[16]^ip[19]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[237] = ip[2]^ip[3]^ip[6]^ip[7]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[238] = ip[1]^ip[2]^ip[5]^ip[6]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[239] = ip[0]^ip[1]^ip[4]^ip[5]^ip[7]^ip[9]^ip[11]^ip[12]^ip[13]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[240] = ip[0]^ip[3]^ip[4]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[241] = ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[16]^ip[17]^ip[22]^ip[27]^ip[30]^ip[31],
                 datout[242] = ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[15]^ip[16]^ip[21]^ip[26]^ip[29]^ip[30],
                 datout[243] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[14]^ip[15]^ip[20]^ip[25]^ip[28]^ip[29],
                 datout[244] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[13]^ip[14]^ip[18]^ip[19]^ip[20]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[245] = ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[17]^ip[19]^ip[20]^ip[23]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[246] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[16]^ip[18]^ip[19]^ip[22]^ip[24]^ip[26]^ip[29]^ip[30],
                 datout[247] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[15]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29],
                 datout[248] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[10]^ip[14]^ip[16]^ip[17]^ip[18]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[249] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[250] = ip[0]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[24]^ip[29]^ip[30]^ip[31],
                 datout[251] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[252] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[253] = ip[0]^ip[2]^ip[3]^ip[4]^ip[7]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[19]^ip[20]^ip[21]^ip[24]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[254] = ip[1]^ip[2]^ip[3]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[19]^ip[23]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[255] = ip[0]^ip[1]^ip[2]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[18]^ip[22]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[256] = ip[0]^ip[1]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[17]^ip[18]^ip[20]^ip[21]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[257] = ip[0]^ip[5]^ip[7]^ip[10]^ip[11]^ip[16]^ip[17]^ip[18]^ip[19]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[258] = ip[4]^ip[10]^ip[15]^ip[16]^ip[17]^ip[20]^ip[23]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[259] = ip[3]^ip[9]^ip[14]^ip[15]^ip[16]^ip[19]^ip[22]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[260] = ip[2]^ip[8]^ip[13]^ip[14]^ip[15]^ip[18]^ip[21]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[261] = ip[1]^ip[7]^ip[12]^ip[13]^ip[14]^ip[17]^ip[20]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28],
                 datout[262] = ip[0]^ip[6]^ip[11]^ip[12]^ip[13]^ip[16]^ip[19]^ip[21]^ip[23]^ip[25]^ip[26]^ip[27],
                 datout[263] = ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[22]^ip[24]^ip[25]^ip[31],
                 datout[264] = ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[21]^ip[23]^ip[24]^ip[30],
                 datout[265] = ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[20]^ip[22]^ip[23]^ip[29],
                 datout[266] = ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[19]^ip[21]^ip[22]^ip[28],
                 datout[267] = ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[11]^ip[18]^ip[20]^ip[21]^ip[27],
                 datout[268] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[17]^ip[19]^ip[20]^ip[26],
                 datout[269] = ip[0]^ip[3]^ip[4]^ip[5]^ip[16]^ip[19]^ip[20]^ip[25]^ip[26]^ip[31],
                 datout[270] = ip[2]^ip[3]^ip[4]^ip[6]^ip[9]^ip[15]^ip[19]^ip[20]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[271] = ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[14]^ip[18]^ip[19]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30],
                 datout[272] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[13]^ip[17]^ip[18]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29],
                 datout[273] = ip[0]^ip[1]^ip[3]^ip[9]^ip[12]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[274] = ip[0]^ip[2]^ip[6]^ip[8]^ip[9]^ip[11]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[275] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[16]^ip[17]^ip[21]^ip[24]^ip[29]^ip[30]^ip[31],
                 datout[276] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[13]^ip[14]^ip[15]^ip[16]^ip[20]^ip[23]^ip[28]^ip[29]^ip[30],
                 datout[277] = ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[278] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[279] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[17]^ip[18]^ip[20]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[280] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[16]^ip[17]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[281] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[15]^ip[16]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[282] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[283] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[284] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[11]^ip[12]^ip[13]^ip[16]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[285] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[286] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[16]^ip[17]^ip[21]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[287] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[13]^ip[15]^ip[16]^ip[18]^ip[22]^ip[24]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[288] = ip[0]^ip[3]^ip[4]^ip[5]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[289] = ip[2]^ip[3]^ip[4]^ip[6]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[290] = ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[291] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[292] = ip[0]^ip[1]^ip[3]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[293] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[27]^ip[30]^ip[31],
                 datout[294] = ip[1]^ip[5]^ip[7]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[29]^ip[30]^ip[31],
                 datout[295] = ip[0]^ip[4]^ip[6]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[28]^ip[29]^ip[30],
                 datout[296] = ip[3]^ip[5]^ip[6]^ip[10]^ip[11]^ip[12]^ip[14]^ip[17]^ip[19]^ip[21]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[297] = ip[2]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[18]^ip[20]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[298] = ip[1]^ip[3]^ip[4]^ip[8]^ip[9]^ip[10]^ip[12]^ip[15]^ip[17]^ip[19]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[299] = ip[0]^ip[2]^ip[3]^ip[7]^ip[8]^ip[9]^ip[11]^ip[14]^ip[16]^ip[18]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[300] = ip[1]^ip[2]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[301] = ip[0]^ip[1]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[302] = ip[0]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[303] = ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[304] = ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30],
                 datout[305] = ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29],
                 datout[306] = ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28],
                 datout[307] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27],
                 datout[308] = ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[13]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[25]^ip[31],
                 datout[309] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[12]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[24]^ip[30],
                 datout[310] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[11]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[23]^ip[29],
                 datout[311] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[13]^ip[14]^ip[16]^ip[22]^ip[26]^ip[28]^ip[31],
                 datout[312] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[12]^ip[13]^ip[15]^ip[18]^ip[20]^ip[21]^ip[25]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[313] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[17]^ip[18]^ip[19]^ip[24]^ip[25]^ip[29]^ip[30]^ip[31],
                 datout[314] = ip[0]^ip[1]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[17]^ip[20]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[315] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^
                         ip[31],
                 datout[316] = ip[1]^ip[3]^ip[5]^ip[7]^ip[11]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[317] = ip[0]^ip[2]^ip[4]^ip[6]^ip[10]^ip[13]^ip[14]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[318] = ip[1]^ip[3]^ip[5]^ip[6]^ip[12]^ip[13]^ip[15]^ip[17]^ip[19]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[319] = ip[0]^ip[2]^ip[4]^ip[5]^ip[11]^ip[12]^ip[14]^ip[16]^ip[18]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[320] = ip[1]^ip[3]^ip[4]^ip[6]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[321] = ip[0]^ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[20]^ip[22]^ip[24]^ip[26]^ip[28]^ip[30],
                 datout[322] = ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[323] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 datout[324] = ip[0]^ip[2]^ip[4]^ip[5]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[325] = ip[1]^ip[3]^ip[4]^ip[6]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[326] = ip[0]^ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[327] = ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[17]^ip[18]^ip[21]^ip[22]^ip[23]^ip[28]^ip[29]^ip[31],
                 datout[328] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[16]^ip[17]^ip[20]^ip[21]^ip[22]^ip[27]^ip[28]^ip[30],
                 datout[329] = ip[0]^ip[2]^ip[4]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[15]^ip[16]^ip[18]^ip[19]^ip[21]^ip[27]^ip[29]^ip[31],
                 datout[330] = ip[1]^ip[3]^ip[4]^ip[7]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[17]^ip[28]^ip[30]^ip[31],
                 datout[331] = ip[0]^ip[2]^ip[3]^ip[6]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[16]^ip[27]^ip[29]^ip[30],
                 datout[332] = ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[12]^ip[13]^ip[15]^ip[18]^ip[20]^ip[28]^ip[29]^ip[31],
                 datout[333] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[11]^ip[12]^ip[14]^ip[17]^ip[19]^ip[27]^ip[28]^ip[30],
                 datout[334] = ip[0]^ip[3]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[20]^ip[27]^ip[29]^ip[31],
                 datout[335] = ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[10]^ip[12]^ip[15]^ip[18]^ip[19]^ip[20]^ip[28]^ip[30]^ip[31],
                 datout[336] = ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[9]^ip[11]^ip[14]^ip[17]^ip[18]^ip[19]^ip[27]^ip[29]^ip[30],
                 datout[337] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[8]^ip[10]^ip[13]^ip[16]^ip[17]^ip[18]^ip[26]^ip[28]^ip[29],
                 datout[338] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[12]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[25]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[339] = ip[0]^ip[2]^ip[4]^ip[5]^ip[9]^ip[11]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[24]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[340] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[23]^ip[24]^ip[29]^ip[30]^ip[31],
                 datout[341] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[28]^ip[29]^ip[30],
                 datout[342] = ip[1]^ip[2]^ip[4]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[343] = ip[0]^ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[19]^ip[20]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[344] = ip[0]^ip[2]^ip[5]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[19]^ip[24]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[345] = ip[1]^ip[4]^ip[10]^ip[11]^ip[12]^ip[14]^ip[20]^ip[23]^ip[24]^ip[28]^ip[30]^ip[31],
                 datout[346] = ip[0]^ip[3]^ip[9]^ip[10]^ip[11]^ip[13]^ip[19]^ip[22]^ip[23]^ip[27]^ip[29]^ip[30],
                 datout[347] = ip[2]^ip[6]^ip[8]^ip[10]^ip[12]^ip[20]^ip[21]^ip[22]^ip[28]^ip[29]^ip[31],
                 datout[348] = ip[1]^ip[5]^ip[7]^ip[9]^ip[11]^ip[19]^ip[20]^ip[21]^ip[27]^ip[28]^ip[30],
                 datout[349] = ip[0]^ip[4]^ip[6]^ip[8]^ip[10]^ip[18]^ip[19]^ip[20]^ip[26]^ip[27]^ip[29],
                 datout[350] = ip[3]^ip[5]^ip[6]^ip[7]^ip[17]^ip[19]^ip[20]^ip[25]^ip[28]^ip[31],
                 datout[351] = ip[2]^ip[4]^ip[5]^ip[6]^ip[16]^ip[18]^ip[19]^ip[24]^ip[27]^ip[30],
                 datout[352] = ip[1]^ip[3]^ip[4]^ip[5]^ip[15]^ip[17]^ip[18]^ip[23]^ip[26]^ip[29],
                 datout[353] = ip[0]^ip[2]^ip[3]^ip[4]^ip[14]^ip[16]^ip[17]^ip[22]^ip[25]^ip[28],
                 datout[354] = ip[1]^ip[2]^ip[3]^ip[6]^ip[9]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[31],
                 datout[355] = ip[0]^ip[1]^ip[2]^ip[5]^ip[8]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[30],
                 datout[356] = ip[0]^ip[1]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[357] = ip[0]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[358] = ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[14]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[359] = ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[13]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[360] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[12]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[361] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[11]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[31],
                 datout[362] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[10]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[30],
                 datout[363] = ip[1]^ip[2]^ip[3]^ip[4]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[29]^ip[31],
                 datout[364] = ip[0]^ip[1]^ip[2]^ip[3]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[24]^ip[28]^ip[30],
                 datout[365] = ip[0]^ip[1]^ip[2]^ip[6]^ip[9]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[23]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[366] = ip[0]^ip[1]^ip[5]^ip[6]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[367] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[29]^
                         ip[30]^ip[31],
                 datout[368] = ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[369] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[370] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[21]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[371] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[20]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[372] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[13]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[373] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[12]^ip[14]^ip[17]^ip[19]^ip[23]^ip[24]^ip[30]^ip[31],
                 datout[374] = ip[1]^ip[2]^ip[4]^ip[11]^ip[13]^ip[16]^ip[20]^ip[22]^ip[23]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[375] = ip[0]^ip[1]^ip[3]^ip[10]^ip[12]^ip[15]^ip[19]^ip[21]^ip[22]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[376] = ip[0]^ip[2]^ip[6]^ip[11]^ip[14]^ip[21]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[377] = ip[1]^ip[5]^ip[6]^ip[9]^ip[10]^ip[13]^ip[18]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[378] = ip[0]^ip[4]^ip[5]^ip[8]^ip[9]^ip[12]^ip[17]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[379] = ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[16]^ip[18]^ip[20]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[380] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[15]^ip[17]^ip[19]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28]^ip[30],
                 datout[381] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[29],
                 datout[382] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28],
                 datout[383] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[384] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[385] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[18]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30],
                 datout[386] = ip[0]^ip[1]^ip[2]^ip[3]^ip[7]^ip[11]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[387] = ip[0]^ip[1]^ip[2]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[388] = ip[0]^ip[1]^ip[6]^ip[8]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[21]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[389] = ip[0]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[18]^ip[23]^ip[24]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[390] = ip[4]^ip[5]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[391] = ip[3]^ip[4]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[392] = ip[2]^ip[3]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[393] = ip[1]^ip[2]^ip[5]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[394] = ip[0]^ip[1]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27],
                 datout[395] = ip[0]^ip[3]^ip[5]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[31],
                 datout[396] = ip[2]^ip[4]^ip[6]^ip[7]^ip[11]^ip[12]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[30]^ip[31],
                 datout[397] = ip[1]^ip[3]^ip[5]^ip[6]^ip[10]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[29]^ip[30],
                 datout[398] = ip[0]^ip[2]^ip[4]^ip[5]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[28]^ip[29],
                 datout[399] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[11]^ip[13]^ip[15]^ip[16]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[400] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[12]^ip[14]^ip[15]^ip[18]^ip[20]^ip[22]^ip[25]^ip[26]^ip[27]^ip[30],
                 datout[401] = ip[1]^ip[2]^ip[4]^ip[11]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[29]^ip[31],
                 datout[402] = ip[0]^ip[1]^ip[3]^ip[10]^ip[12]^ip[13]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[23]^ip[24]^ip[28]^ip[30],
                 datout[403] = ip[0]^ip[2]^ip[6]^ip[11]^ip[12]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[23]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[404] = ip[1]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[405] = ip[0]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[406] = ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[23]^ip[28]^ip[29]^ip[31],
                 datout[407] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[11]^ip[12]^ip[13]^ip[16]^ip[18]^ip[22]^ip[27]^ip[28]^ip[30],
                 datout[408] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[10]^ip[11]^ip[12]^ip[15]^ip[17]^ip[21]^ip[26]^ip[27]^ip[29],
                 datout[409] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[14]^ip[16]^ip[20]^ip[25]^ip[26]^ip[28],
                 datout[410] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[10]^ip[13]^ip[15]^ip[18]^ip[19]^ip[20]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[411] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[12]^ip[14]^ip[17]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[412] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[11]^ip[13]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30],
                 datout[413] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[12]^ip[15]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[414] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[11]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[415] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[13]^ip[15]^ip[17]^ip[21]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[416] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[12]^ip[14]^ip[16]^ip[20]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[417] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^
                         ip[28]^ip[29]^ip[31],
                 datout[418] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^
                         ip[30]^ip[31],
                 datout[419] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[11]^ip[13]^ip[16]^ip[19]^ip[21]^ip[23]^ip[24]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[420] = ip[0]^ip[1]^ip[2]^ip[3]^ip[7]^ip[9]^ip[10]^ip[12]^ip[15]^ip[22]^ip[23]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[421] = ip[0]^ip[1]^ip[2]^ip[8]^ip[11]^ip[14]^ip[18]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[422] = ip[0]^ip[1]^ip[6]^ip[7]^ip[9]^ip[10]^ip[13]^ip[17]^ip[18]^ip[19]^ip[21]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[423] = ip[0]^ip[5]^ip[8]^ip[12]^ip[16]^ip[17]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[424] = ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[15]^ip[16]^ip[18]^ip[20]^ip[23]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[425] = ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[14]^ip[15]^ip[17]^ip[19]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[426] = ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[13]^ip[14]^ip[16]^ip[18]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[427] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[12]^ip[13]^ip[15]^ip[17]^ip[20]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[428] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[11]^ip[12]^ip[14]^ip[16]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27],
                 datout[429] = ip[1]^ip[2]^ip[4]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[31],
                 datout[430] = ip[0]^ip[1]^ip[3]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[30],
                 datout[431] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[11]^ip[13]^ip[21]^ip[22]^ip[23]^ip[26]^ip[29]^ip[31],
                 datout[432] = ip[1]^ip[5]^ip[7]^ip[9]^ip[10]^ip[12]^ip[18]^ip[21]^ip[22]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[433] = ip[0]^ip[4]^ip[6]^ip[8]^ip[9]^ip[11]^ip[17]^ip[20]^ip[21]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30],
                 datout[434] = ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[16]^ip[18]^ip[19]^ip[23]^ip[24]^ip[28]^ip[29]^ip[31],
                 datout[435] = ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[15]^ip[17]^ip[18]^ip[22]^ip[23]^ip[27]^ip[28]^ip[30],
                 datout[436] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[14]^ip[16]^ip[17]^ip[21]^ip[22]^ip[26]^ip[27]^ip[29],
                 datout[437] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[13]^ip[15]^ip[16]^ip[20]^ip[21]^ip[25]^ip[26]^ip[28],
                 datout[438] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[9]^ip[12]^ip[14]^ip[15]^ip[18]^ip[19]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[439] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[8]^ip[11]^ip[13]^ip[14]^ip[17]^ip[18]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[440] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[441] = ip[0]^ip[1]^ip[2]^ip[5]^ip[8]^ip[11]^ip[12]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^
                         ip[30]^ip[31],
                 datout[442] = ip[0]^ip[1]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^
                         ip[30]^ip[31],
                 datout[443] = ip[0]^ip[3]^ip[5]^ip[8]^ip[10]^ip[13]^ip[14]^ip[15]^ip[16]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[444] = ip[2]^ip[4]^ip[6]^ip[7]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[445] = ip[1]^ip[3]^ip[5]^ip[6]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[446] = ip[0]^ip[2]^ip[4]^ip[5]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[447] = ip[1]^ip[3]^ip[4]^ip[6]^ip[10]^ip[11]^ip[12]^ip[15]^ip[19]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[448] = ip[0]^ip[2]^ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[14]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[30],
                 datout[449] = ip[1]^ip[2]^ip[4]^ip[6]^ip[8]^ip[10]^ip[13]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[29]^ip[31],
                 datout[450] = ip[0]^ip[1]^ip[3]^ip[5]^ip[7]^ip[9]^ip[12]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[28]^ip[30],
                 datout[451] = ip[0]^ip[2]^ip[4]^ip[8]^ip[9]^ip[11]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[452] = ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[16]^ip[22]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[453] = ip[0]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[13]^ip[14]^ip[15]^ip[21]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[454] = ip[1]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[18]^ip[23]^ip[28]^ip[29]^ip[31],
                 datout[455] = ip[0]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[17]^ip[22]^ip[27]^ip[28]^ip[30],
                 datout[456] = ip[2]^ip[3]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[16]^ip[18]^ip[20]^ip[21]^ip[27]^ip[29]^ip[31],
                 datout[457] = ip[1]^ip[2]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[15]^ip[17]^ip[19]^ip[20]^ip[26]^ip[28]^ip[30],
                 datout[458] = ip[0]^ip[1]^ip[3]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[16]^ip[18]^ip[19]^ip[25]^ip[27]^ip[29],
                 datout[459] = ip[0]^ip[2]^ip[4]^ip[7]^ip[8]^ip[13]^ip[15]^ip[17]^ip[20]^ip[24]^ip[28]^ip[31],
                 datout[460] = ip[1]^ip[3]^ip[7]^ip[9]^ip[12]^ip[14]^ip[16]^ip[18]^ip[19]^ip[20]^ip[23]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[461] = ip[0]^ip[2]^ip[6]^ip[8]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[22]^ip[25]^ip[26]^ip[29]^ip[30],
                 datout[462] = ip[1]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[463] = ip[0]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[464] = ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[27]^ip[29]^ip[31],
                 datout[465] = ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[30],
                 datout[466] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[25]^ip[27]^ip[29],
                 datout[467] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[24]^ip[26]^ip[28],
                 datout[468] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[15]^ip[16]^ip[19]^ip[23]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[469] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[14]^ip[15]^ip[20]^ip[22]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[470] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[13]^ip[14]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[471] = ip[0]^ip[1]^ip[2]^ip[4]^ip[9]^ip[12]^ip[13]^ip[17]^ip[19]^ip[22]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[472] = ip[0]^ip[1]^ip[3]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[16]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[473] = ip[0]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[15]^ip[18]^ip[19]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[474] = ip[1]^ip[4]^ip[5]^ip[7]^ip[8]^ip[10]^ip[14]^ip[17]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[475] = ip[0]^ip[3]^ip[4]^ip[6]^ip[7]^ip[9]^ip[13]^ip[16]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[476] = ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[12]^ip[15]^ip[18]^ip[21]^ip[22]^ip[25]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[477] = ip[1]^ip[2]^ip[4]^ip[7]^ip[8]^ip[11]^ip[14]^ip[17]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[478] = ip[0]^ip[1]^ip[3]^ip[6]^ip[7]^ip[10]^ip[13]^ip[16]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[479] = ip[0]^ip[2]^ip[5]^ip[12]^ip[15]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[28]^ip[31],
                 datout[480] = ip[1]^ip[4]^ip[6]^ip[9]^ip[11]^ip[14]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[481] = ip[0]^ip[3]^ip[5]^ip[8]^ip[10]^ip[13]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[29]^ip[30],
                 datout[482] = ip[2]^ip[4]^ip[6]^ip[7]^ip[12]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[483] = ip[1]^ip[3]^ip[5]^ip[6]^ip[11]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[484] = ip[0]^ip[2]^ip[4]^ip[5]^ip[10]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29],
                 datout[485] = ip[1]^ip[3]^ip[4]^ip[6]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[31],
                 datout[486] = ip[0]^ip[2]^ip[3]^ip[5]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[30],
                 datout[487] = ip[1]^ip[2]^ip[4]^ip[6]^ip[9]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[23]^ip[29]^ip[31],
                 datout[488] = ip[0]^ip[1]^ip[3]^ip[5]^ip[8]^ip[11]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[22]^ip[28]^ip[30],
                 datout[489] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[490] = ip[1]^ip[3]^ip[5]^ip[8]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[491] = ip[0]^ip[2]^ip[4]^ip[7]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[492] = ip[1]^ip[3]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[23]^ip[28]^ip[29]^ip[31],
                 datout[493] = ip[0]^ip[2]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[22]^ip[27]^ip[28]^ip[30],
                 datout[494] = ip[1]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[20]^ip[21]^ip[27]^ip[29]^ip[31],
                 datout[495] = ip[0]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[19]^ip[20]^ip[26]^ip[28]^ip[30],
                 datout[496] = ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[19]^ip[20]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[497] = ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[18]^ip[19]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 datout[498] = ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[17]^ip[18]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29],
                 datout[499] = ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[16]^ip[17]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28],
                 datout[500] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[15]^ip[16]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27],
                 datout[501] = ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[24]^ip[31],
                 datout[502] = ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[23]^ip[30],
                 datout[503] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[22]^ip[29],
                 datout[504] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[15]^ip[19]^ip[20]^ip[21]^ip[26]^ip[28]^ip[31],
                 datout[505] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[19]^ip[25]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[506] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[13]^ip[20]^ip[24]^ip[25]^ip[29]^ip[30]^ip[31],
                 datout[507] = ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[12]^ip[18]^ip[19]^ip[20]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[508] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[11]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[509] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[10]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[510] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[511] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[9]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[22]^ip[24]^ip[27]^ip[30]^ip[31],
                 datout[512] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[29]^ip[30]^ip[31],
                 datout[513] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[26]^ip[28]^ip[29]^ip[30]^
                         ip[31],
                 datout[514] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[25]^ip[27]^ip[28]^ip[29]^
                         ip[30],
                 datout[515] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[24]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[516] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[23]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[517] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[25]^ip[27]^ip[29]^
                         ip[31],
                 datout[518] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[28]^ip[30]^ip[31],
                 datout[519] = ip[0]^ip[1]^ip[3]^ip[4]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[23]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[520] = ip[0]^ip[2]^ip[3]^ip[6]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[20]^ip[22]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[521] = ip[1]^ip[2]^ip[5]^ip[6]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[522] = ip[0]^ip[1]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[523] = ip[0]^ip[3]^ip[4]^ip[6]^ip[8]^ip[10]^ip[12]^ip[13]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[524] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[11]^ip[12]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[525] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[10]^ip[11]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[526] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[9]^ip[10]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26]^ip[28]^ip[29],
                 datout[527] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[12]^ip[13]^ip[16]^ip[17]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[528] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[15]^ip[16]^ip[18]^ip[23]^ip[24]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[529] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[15]^ip[17]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30],
                 datout[530] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[531] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[532] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[9]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[533] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[534] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[10]^ip[12]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^
                         ip[31],
                 datout[535] = ip[0]^ip[1]^ip[3]^ip[5]^ip[11]^ip[13]^ip[14]^ip[17]^ip[19]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[536] = ip[0]^ip[2]^ip[4]^ip[6]^ip[9]^ip[10]^ip[12]^ip[13]^ip[16]^ip[21]^ip[23]^ip[24]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[537] = ip[1]^ip[3]^ip[5]^ip[6]^ip[8]^ip[11]^ip[12]^ip[15]^ip[18]^ip[22]^ip[23]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[538] = ip[0]^ip[2]^ip[4]^ip[5]^ip[7]^ip[10]^ip[11]^ip[14]^ip[17]^ip[21]^ip[22]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[539] = ip[1]^ip[3]^ip[4]^ip[10]^ip[13]^ip[16]^ip[18]^ip[21]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[540] = ip[0]^ip[2]^ip[3]^ip[9]^ip[12]^ip[15]^ip[17]^ip[20]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[541] = ip[1]^ip[2]^ip[6]^ip[8]^ip[9]^ip[11]^ip[14]^ip[16]^ip[18]^ip[19]^ip[20]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[542] = ip[0]^ip[1]^ip[5]^ip[7]^ip[8]^ip[10]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[24]^ip[26]^ip[28]^ip[30],
                 datout[543] = ip[0]^ip[4]^ip[7]^ip[12]^ip[14]^ip[16]^ip[17]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[544] = ip[3]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[545] = ip[2]^ip[8]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[546] = ip[1]^ip[7]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[23]^ip[26]^ip[28]^ip[29],
                 datout[547] = ip[0]^ip[6]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[25]^ip[27]^ip[28],
                 datout[548] = ip[5]^ip[6]^ip[7]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[21]^ip[24]^ip[27]^ip[31],
                 datout[549] = ip[4]^ip[5]^ip[6]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[20]^ip[23]^ip[26]^ip[30],
                 datout[550] = ip[3]^ip[4]^ip[5]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[19]^ip[22]^ip[25]^ip[29],
                 datout[551] = ip[2]^ip[3]^ip[4]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[18]^ip[21]^ip[24]^ip[28],
                 datout[552] = ip[1]^ip[2]^ip[3]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[17]^ip[20]^ip[23]^ip[27],
                 datout[553] = ip[0]^ip[1]^ip[2]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[16]^ip[19]^ip[22]^ip[26],
                 datout[554] = ip[0]^ip[1]^ip[5]^ip[8]^ip[10]^ip[15]^ip[20]^ip[21]^ip[25]^ip[26]^ip[31],
                 datout[555] = ip[0]^ip[4]^ip[6]^ip[7]^ip[14]^ip[18]^ip[19]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[556] = ip[3]^ip[5]^ip[9]^ip[13]^ip[17]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[557] = ip[2]^ip[4]^ip[8]^ip[12]^ip[16]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[558] = ip[1]^ip[3]^ip[7]^ip[11]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[559] = ip[0]^ip[2]^ip[6]^ip[10]^ip[14]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28],
                 datout[560] = ip[1]^ip[5]^ip[6]^ip[13]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[27]^ip[31],
                 datout[561] = ip[0]^ip[4]^ip[5]^ip[12]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[24]^ip[26]^ip[30],
                 datout[562] = ip[3]^ip[4]^ip[6]^ip[9]^ip[11]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[23]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[563] = ip[2]^ip[3]^ip[5]^ip[8]^ip[10]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[22]^ip[24]^ip[25]^ip[28]^ip[30],
                 datout[564] = ip[1]^ip[2]^ip[4]^ip[7]^ip[9]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[21]^ip[23]^ip[24]^ip[27]^ip[29],
                 datout[565] = ip[0]^ip[1]^ip[3]^ip[6]^ip[8]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[20]^ip[22]^ip[23]^ip[26]^ip[28],
                 datout[566] = ip[0]^ip[2]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[567] = ip[1]^ip[4]^ip[5]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[21]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[568] = ip[0]^ip[3]^ip[4]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[18]^ip[20]^ip[23]^ip[24]^ip[29]^ip[30],
                 datout[569] = ip[2]^ip[3]^ip[10]^ip[11]^ip[12]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[570] = ip[1]^ip[2]^ip[9]^ip[10]^ip[11]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[571] = ip[0]^ip[1]^ip[8]^ip[9]^ip[10]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[29],
                 datout[572] = ip[0]^ip[6]^ip[7]^ip[8]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[23]^ip[25]^ip[28]^ip[31],
                 datout[573] = ip[5]^ip[7]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[24]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[574] = ip[4]^ip[6]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[21]^ip[23]^ip[25]^ip[26]^ip[29]^ip[30],
                 datout[575] = ip[3]^ip[5]^ip[7]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[20]^ip[22]^ip[24]^ip[25]^ip[28]^ip[29],
                 datout[576] = ip[2]^ip[4]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[21]^ip[23]^ip[24]^ip[27]^ip[28],
                 datout[577] = ip[1]^ip[3]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[26]^ip[27],
                 datout[578] = ip[0]^ip[2]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[17]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26],
                 datout[579] = ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[14]^ip[16]^ip[21]^ip[24]^ip[25]^ip[26]^ip[31],
                 datout[580] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[13]^ip[15]^ip[20]^ip[23]^ip[24]^ip[25]^ip[30],
                 datout[581] = ip[1]^ip[3]^ip[4]^ip[5]^ip[8]^ip[12]^ip[14]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29]^ip[31],
                 datout[582] = ip[0]^ip[2]^ip[3]^ip[4]^ip[7]^ip[11]^ip[13]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[30],
                 datout[583] = ip[1]^ip[2]^ip[3]^ip[9]^ip[10]^ip[12]^ip[16]^ip[17]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[584] = ip[0]^ip[1]^ip[2]^ip[8]^ip[9]^ip[11]^ip[15]^ip[16]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[28]^ip[30],
                 datout[585] = ip[0]^ip[1]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[18]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[586] = ip[0]^ip[5]^ip[7]^ip[8]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[587] = ip[4]^ip[7]^ip[9]^ip[12]^ip[13]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[588] = ip[3]^ip[6]^ip[8]^ip[11]^ip[12]^ip[15]^ip[17]^ip[18]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[589] = ip[2]^ip[5]^ip[7]^ip[10]^ip[11]^ip[14]^ip[16]^ip[17]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[590] = ip[1]^ip[4]^ip[6]^ip[9]^ip[10]^ip[13]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28],
                 datout[591] = ip[0]^ip[3]^ip[5]^ip[8]^ip[9]^ip[12]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27],
                 datout[592] = ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[31],
                 datout[593] = ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[30],
                 datout[594] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[29],
                 datout[595] = ip[1]^ip[3]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[28]^ip[31],
                 datout[596] = ip[0]^ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[25]^ip[27]^ip[30],
                 datout[597] = ip[1]^ip[2]^ip[3]^ip[7]^ip[8]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[24]^ip[29]^ip[31],
                 datout[598] = ip[0]^ip[1]^ip[2]^ip[6]^ip[7]^ip[11]^ip[13]^ip[14]^ip[16]^ip[18]^ip[23]^ip[28]^ip[30],
                 datout[599] = ip[0]^ip[1]^ip[5]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[600] = ip[0]^ip[4]^ip[6]^ip[8]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[601] = ip[3]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[602] = ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[18]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[603] = ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[17]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[604] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[16]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28],
                 datout[605] = ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[11]^ip[12]^ip[13]^ip[15]^ip[18]^ip[22]^ip[23]^ip[25]^ip[27]^ip[31],
                 datout[606] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[10]^ip[11]^ip[12]^ip[14]^ip[17]^ip[21]^ip[22]^ip[24]^ip[26]^ip[30],
                 datout[607] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[10]^ip[11]^ip[13]^ip[16]^ip[18]^ip[21]^ip[23]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[608] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[10]^ip[12]^ip[15]^ip[17]^ip[18]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[609] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[11]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[610] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[10]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[611] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[12]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^
                         ip[31],
                 datout[612] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[11]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^
                         ip[30],
                 datout[613] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[614] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[8]^ip[11]^ip[12]^ip[13]^ip[16]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28]^ip[30]^ip[31],
                 datout[615] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[616] = ip[1]^ip[3]^ip[4]^ip[5]^ip[8]^ip[10]^ip[11]^ip[14]^ip[17]^ip[18]^ip[21]^ip[22]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[617] = ip[0]^ip[2]^ip[3]^ip[4]^ip[7]^ip[9]^ip[10]^ip[13]^ip[16]^ip[17]^ip[20]^ip[21]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[618] = ip[1]^ip[2]^ip[3]^ip[8]^ip[12]^ip[15]^ip[16]^ip[18]^ip[19]^ip[23]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[619] = ip[0]^ip[1]^ip[2]^ip[7]^ip[11]^ip[14]^ip[15]^ip[17]^ip[18]^ip[22]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[620] = ip[0]^ip[1]^ip[9]^ip[10]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[621] = ip[0]^ip[6]^ip[8]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[24]^ip[28]^ip[30]^ip[31],
                 datout[622] = ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[23]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[623] = ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[22]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[624] = ip[3]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[21]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[625] = ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[20]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28],
                 datout[626] = ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[19]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27],
                 datout[627] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[18]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26],
                 datout[628] = ip[0]^ip[1]^ip[3]^ip[5]^ip[8]^ip[10]^ip[11]^ip[14]^ip[17]^ip[18]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[31],
                 datout[629] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[10]^ip[13]^ip[16]^ip[17]^ip[18]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[630] = ip[1]^ip[3]^ip[5]^ip[12]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[631] = ip[0]^ip[2]^ip[4]^ip[11]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[632] = ip[1]^ip[3]^ip[6]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[633] = ip[0]^ip[2]^ip[5]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[634] = ip[1]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[635] = ip[0]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[28]^ip[30],
                 datout[636] = ip[2]^ip[4]^ip[5]^ip[7]^ip[10]^ip[11]^ip[12]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[637] = ip[1]^ip[3]^ip[4]^ip[6]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 datout[638] = ip[0]^ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29],
                 datout[639] = ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[28]^ip[31],
                 datout[640] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[21]^ip[22]^ip[23]^ip[27]^ip[30],
                 datout[641] = ip[0]^ip[2]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[29]^ip[31],
                 datout[642] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[643] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[25]^ip[27]^ip[29]^ip[30],
                 datout[644] = ip[1]^ip[2]^ip[4]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[24]^ip[28]^ip[29]^ip[31],
                 datout[645] = ip[0]^ip[1]^ip[3]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[23]^ip[27]^ip[28]^ip[30],
                 datout[646] = ip[0]^ip[2]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[20]^ip[22]^ip[27]^ip[29]^ip[31],
                 datout[647] = ip[1]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[28]^ip[30]^ip[31],
                 datout[648] = ip[0]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[27]^ip[29]^ip[30],
                 datout[649] = ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[28]^ip[29]^ip[31],
                 datout[650] = ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[27]^ip[28]^ip[30],
                 datout[651] = ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[26]^ip[27]^ip[29],
                 datout[652] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[25]^ip[26]^ip[28],
                 datout[653] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[24]^ip[25]^ip[27],
                 datout[654] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[11]^ip[12]^ip[14]^ip[15]^ip[18]^ip[20]^ip[23]^ip[24]^ip[31],
                 datout[655] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[26]^ip[30]^ip[31],
                 datout[656] = ip[0]^ip[1]^ip[3]^ip[5]^ip[8]^ip[10]^ip[12]^ip[13]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[657] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[11]^ip[12]^ip[15]^ip[16]^ip[19]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[658] = ip[1]^ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[659] = ip[0]^ip[2]^ip[4]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[660] = ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[12]^ip[13]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[661] = ip[0]^ip[2]^ip[5]^ip[6]^ip[7]^ip[11]^ip[12]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[662] = ip[1]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[16]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[663] = ip[0]^ip[3]^ip[4]^ip[8]^ip[9]^ip[10]^ip[15]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[28]^ip[30],
                 datout[664] = ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[14]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[665] = ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[13]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 datout[666] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[12]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29],
                 datout[667] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[11]^ip[14]^ip[15]^ip[16]^ip[22]^ip[23]^ip[24]^ip[28]^ip[31],
                 datout[668] = ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[669] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[25]^ip[26]^ip[29]^ip[30],
                 datout[670] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[28]^ip[29],
                 datout[671] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[17]^ip[19]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[672] = ip[0]^ip[1]^ip[2]^ip[4]^ip[8]^ip[10]^ip[11]^ip[14]^ip[16]^ip[20]^ip[22]^ip[23]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[673] = ip[0]^ip[1]^ip[3]^ip[6]^ip[7]^ip[10]^ip[13]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[29]^ip[30]^ip[31],
                 datout[674] = ip[0]^ip[2]^ip[5]^ip[12]^ip[14]^ip[17]^ip[19]^ip[21]^ip[23]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[675] = ip[1]^ip[4]^ip[6]^ip[9]^ip[11]^ip[13]^ip[16]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[676] = ip[0]^ip[3]^ip[5]^ip[8]^ip[10]^ip[12]^ip[15]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[677] = ip[2]^ip[4]^ip[6]^ip[7]^ip[11]^ip[14]^ip[18]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[678] = ip[1]^ip[3]^ip[5]^ip[6]^ip[10]^ip[13]^ip[17]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[679] = ip[0]^ip[2]^ip[4]^ip[5]^ip[9]^ip[12]^ip[16]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[680] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[11]^ip[15]^ip[18]^ip[21]^ip[22]^ip[24]^ip[25]^ip[28]^ip[31],
                 datout[681] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[10]^ip[14]^ip[17]^ip[20]^ip[21]^ip[23]^ip[24]^ip[27]^ip[30],
                 datout[682] = ip[1]^ip[2]^ip[4]^ip[7]^ip[13]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[29]^ip[31],
                 datout[683] = ip[0]^ip[1]^ip[3]^ip[6]^ip[12]^ip[15]^ip[17]^ip[18]^ip[21]^ip[22]^ip[28]^ip[30],
                 datout[684] = ip[0]^ip[2]^ip[5]^ip[6]^ip[9]^ip[11]^ip[14]^ip[16]^ip[17]^ip[18]^ip[21]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[685] = ip[1]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[686] = ip[0]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[687] = ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[23]^ip[28]^ip[29]^ip[31],
                 datout[688] = ip[1]^ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[22]^ip[27]^ip[28]^ip[30],
                 datout[689] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[21]^ip[26]^ip[27]^ip[29],
                 datout[690] = ip[0]^ip[1]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[25]^ip[28]^ip[31],
                 datout[691] = ip[0]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[24]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[692] = ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[23]^ip[25]^ip[29]^ip[30]^ip[31],
                 datout[693] = ip[1]^ip[2]^ip[4]^ip[6]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[24]^ip[28]^ip[29]^ip[30],
                 datout[694] = ip[0]^ip[1]^ip[3]^ip[5]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[27]^ip[28]^ip[29],
                 datout[695] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[22]^ip[27]^ip[28]^ip[31],
                 datout[696] = ip[1]^ip[3]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[27]^ip[30]^ip[31],
                 datout[697] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[26]^ip[29]^ip[30],
                 datout[698] = ip[1]^ip[3]^ip[5]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[699] = ip[0]^ip[2]^ip[4]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[700] = ip[1]^ip[3]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[20]^ip[23]^ip[24]^ip[27]^ip[29]^ip[31],
                 datout[701] = ip[0]^ip[2]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[19]^ip[22]^ip[23]^ip[26]^ip[28]^ip[30],
                 datout[702] = ip[1]^ip[4]^ip[8]^ip[10]^ip[11]^ip[12]^ip[15]^ip[20]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[703] = ip[0]^ip[3]^ip[7]^ip[9]^ip[10]^ip[11]^ip[14]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 datout[704] = ip[2]^ip[8]^ip[10]^ip[13]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[705] = ip[1]^ip[7]^ip[9]^ip[12]^ip[18]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 datout[706] = ip[0]^ip[6]^ip[8]^ip[11]^ip[17]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29],
                 datout[707] = ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[16]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28]^ip[31],
                 datout[708] = ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[15]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[30],
                 datout[709] = ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[14]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[29],
                 datout[710] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[13]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[25]^ip[28],
                 datout[711] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[12]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[24]^ip[27],
                 datout[712] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[11]^ip[13]^ip[16]^ip[17]^ip[18]^ip[19]^ip[23]^ip[26],
                 datout[713] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[9]^ip[10]^ip[12]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[25]^ip[26]^ip[31],
                 datout[714] = ip[0]^ip[2]^ip[3]^ip[5]^ip[6]^ip[8]^ip[11]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[715] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[716] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[717] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^
                         ip[27]^ip[28]^ip[29]^ip[31],
                 datout[718] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^
                         ip[28]^ip[30]^ip[31],
                 datout[719] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^
                         ip[27]^ip[29]^ip[30],
                 datout[720] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[721] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[722] = ip[0]^ip[1]^ip[3]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[23]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[723] = ip[0]^ip[2]^ip[6]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[22]^ip[24]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[724] = ip[1]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[20]^ip[21]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^
                         ip[31],
                 datout[725] = ip[0]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[20]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[726] = ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[727] = ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[18]^ip[19]^ip[20]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[728] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[729] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[730] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[731] = ip[0]^ip[1]^ip[2]^ip[3]^ip[7]^ip[8]^ip[10]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[22]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[732] = ip[0]^ip[1]^ip[2]^ip[7]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[733] = ip[0]^ip[1]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[734] = ip[0]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^
                         ip[31],
                 datout[735] = ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^
                         ip[30]^ip[31],
                 datout[736] = ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^
                         ip[30],
                 datout[737] = ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^
                         ip[29],
                 datout[738] = ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^
                         ip[28],
                 datout[739] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^
                         ip[27],
                 datout[740] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^
                         ip[26],
                 datout[741] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[15]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[31],
                 datout[742] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[11]^ip[14]^ip[16]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[743] = ip[0]^ip[1]^ip[2]^ip[3]^ip[9]^ip[10]^ip[13]^ip[15]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[744] = ip[0]^ip[1]^ip[2]^ip[6]^ip[8]^ip[12]^ip[14]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[745] = ip[0]^ip[1]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[13]^ip[17]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[746] = ip[0]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[12]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[747] = ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[748] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[749] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[750] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[8]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[751] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[23]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[752] = ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[20]^ip[22]^ip[23]^ip[24]^ip[30]^ip[31],
                 datout[753] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[19]^ip[21]^ip[22]^ip[23]^ip[29]^ip[30],
                 datout[754] = ip[0]^ip[1]^ip[3]^ip[7]^ip[8]^ip[10]^ip[11]^ip[14]^ip[21]^ip[22]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[755] = ip[0]^ip[2]^ip[7]^ip[10]^ip[13]^ip[18]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[756] = ip[1]^ip[12]^ip[17]^ip[18]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[757] = ip[0]^ip[11]^ip[16]^ip[17]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[758] = ip[6]^ip[9]^ip[10]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[759] = ip[5]^ip[8]^ip[9]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[760] = ip[4]^ip[7]^ip[8]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[761] = ip[3]^ip[6]^ip[7]^ip[12]^ip[13]^ip[15]^ip[17]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[762] = ip[2]^ip[5]^ip[6]^ip[11]^ip[12]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27],
                 datout[763] = ip[1]^ip[4]^ip[5]^ip[10]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26],
                 datout[764] = ip[0]^ip[3]^ip[4]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25],
                 datout[765] = ip[2]^ip[3]^ip[6]^ip[8]^ip[11]^ip[13]^ip[15]^ip[16]^ip[19]^ip[21]^ip[22]^ip[24]^ip[26]^ip[31],
                 datout[766] = ip[1]^ip[2]^ip[5]^ip[7]^ip[10]^ip[12]^ip[14]^ip[15]^ip[18]^ip[20]^ip[21]^ip[23]^ip[25]^ip[30],
                 datout[767] = ip[0]^ip[1]^ip[4]^ip[6]^ip[9]^ip[11]^ip[13]^ip[14]^ip[17]^ip[19]^ip[20]^ip[22]^ip[24]^ip[29],
                 datout[768] = ip[0]^ip[3]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[31],
                 datout[769] = ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[15]^ip[19]^ip[22]^ip[25]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[770] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[14]^ip[18]^ip[21]^ip[24]^ip[25]^ip[26]^ip[29]^ip[30],
                 datout[771] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[13]^ip[17]^ip[20]^ip[23]^ip[24]^ip[25]^ip[28]^ip[29],
                 datout[772] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[12]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[773] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[11]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[30],
                 datout[774] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[9]^ip[10]^ip[14]^ip[16]^ip[17]^ip[21]^ip[22]^ip[24]^ip[25]^ip[29]^ip[31],
                 datout[775] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[8]^ip[13]^ip[15]^ip[16]^ip[18]^ip[21]^ip[23]^ip[24]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[776] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[9]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[777] = ip[0]^ip[1]^ip[4]^ip[5]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[778] = ip[0]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^
                         ip[29]^ip[30]^ip[31],
                 datout[779] = ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[780] = ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[781] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[782] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[18]^ip[19]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[783] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[17]^ip[20]^ip[21]^ip[23]^ip[24]^ip[27]^ip[30]^ip[31],
                 datout[784] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[16]^ip[19]^ip[20]^ip[22]^ip[23]^ip[26]^ip[29]^ip[30],
                 datout[785] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[786] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[14]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[787] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[13]^ip[17]^ip[19]^ip[23]^ip[24]^ip[27]^ip[29]^ip[31],
                 datout[788] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[9]^ip[12]^ip[16]^ip[20]^ip[22]^ip[23]^ip[28]^ip[30]^ip[31],
                 datout[789] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[11]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[790] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[17]^ip[19]^ip[21]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[791] = ip[0]^ip[1]^ip[3]^ip[5]^ip[7]^ip[8]^ip[13]^ip[16]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[792] = ip[0]^ip[2]^ip[4]^ip[7]^ip[9]^ip[12]^ip[15]^ip[18]^ip[20]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[793] = ip[1]^ip[3]^ip[8]^ip[9]^ip[11]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[794] = ip[0]^ip[2]^ip[7]^ip[8]^ip[10]^ip[13]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[795] = ip[1]^ip[7]^ip[12]^ip[15]^ip[16]^ip[17]^ip[22]^ip[25]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[796] = ip[0]^ip[6]^ip[11]^ip[14]^ip[15]^ip[16]^ip[21]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[797] = ip[5]^ip[6]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[18]^ip[23]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[798] = ip[4]^ip[5]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[17]^ip[22]^ip[24]^ip[26]^ip[28]^ip[30],
                 datout[799] = ip[3]^ip[4]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[16]^ip[21]^ip[23]^ip[25]^ip[27]^ip[29],
                 datout[800] = ip[2]^ip[3]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[15]^ip[20]^ip[22]^ip[24]^ip[26]^ip[28],
                 datout[801] = ip[1]^ip[2]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[14]^ip[19]^ip[21]^ip[23]^ip[25]^ip[27],
                 datout[802] = ip[0]^ip[1]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[13]^ip[18]^ip[20]^ip[22]^ip[24]^ip[26],
                 datout[803] = ip[0]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[12]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[31],
                 datout[804] = ip[2]^ip[3]^ip[5]^ip[7]^ip[9]^ip[11]^ip[16]^ip[17]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[805] = ip[1]^ip[2]^ip[4]^ip[6]^ip[8]^ip[10]^ip[15]^ip[16]^ip[18]^ip[21]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30],
                 datout[806] = ip[0]^ip[1]^ip[3]^ip[5]^ip[7]^ip[9]^ip[14]^ip[15]^ip[17]^ip[20]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29],
                 datout[807] = ip[0]^ip[2]^ip[4]^ip[8]^ip[9]^ip[13]^ip[14]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[808] = ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[15]^ip[17]^ip[19]^ip[21]^ip[22]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[809] = ip[0]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[14]^ip[16]^ip[18]^ip[20]^ip[21]^ip[24]^ip[26]^ip[29]^ip[30],
                 datout[810] = ip[1]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[811] = ip[0]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[812] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[24]^ip[27]^ip[29]^ip[31],
                 datout[813] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[23]^ip[26]^ip[28]^ip[30],
                 datout[814] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[27]^ip[29],
                 datout[815] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[21]^ip[24]^ip[28]^ip[31],
                 datout[816] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[23]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[817] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[22]^ip[25]^ip[26]^ip[29]^ip[30],
                 datout[818] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[18]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[819] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[10]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[820] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[821] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[822] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^
                         ip[31],
                 datout[823] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[11]^ip[13]^ip[14]^ip[16]^ip[21]^ip[22]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[824] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[18]^ip[21]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[825] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[14]^ip[17]^ip[20]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[826] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[28]^
                         ip[29]^ip[31],
                 datout[827] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[15]^ip[17]^ip[19]^ip[20]^ip[21]^ip[24]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[828] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[11]^ip[14]^ip[16]^ip[19]^ip[23]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[829] = ip[0]^ip[1]^ip[2]^ip[3]^ip[9]^ip[10]^ip[13]^ip[15]^ip[20]^ip[22]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[830] = ip[0]^ip[1]^ip[2]^ip[6]^ip[8]^ip[12]^ip[14]^ip[18]^ip[19]^ip[20]^ip[21]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[831] = ip[0]^ip[1]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[13]^ip[17]^ip[19]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[832] = ip[0]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[12]^ip[16]^ip[20]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[833] = ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[15]^ip[18]^ip[19]^ip[20]^ip[23]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[834] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[14]^ip[17]^ip[18]^ip[19]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[835] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[13]^ip[16]^ip[17]^ip[18]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[836] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[8]^ip[12]^ip[15]^ip[16]^ip[17]^ip[20]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[837] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[838] = ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[30]^ip[31],
                 datout[839] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[29]^ip[30],
                 datout[840] = ip[0]^ip[1]^ip[3]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[21]^ip[22]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[841] = ip[0]^ip[2]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[18]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[842] = ip[1]^ip[7]^ip[8]^ip[10]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[843] = ip[0]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[844] = ip[5]^ip[8]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[845] = ip[4]^ip[7]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[846] = ip[3]^ip[6]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[847] = ip[2]^ip[5]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[17]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[848] = ip[1]^ip[4]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27],
                 datout[849] = ip[0]^ip[3]^ip[6]^ip[8]^ip[10]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26],
                 datout[850] = ip[2]^ip[5]^ip[6]^ip[7]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[31],
                 datout[851] = ip[1]^ip[4]^ip[5]^ip[6]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[30],
                 datout[852] = ip[0]^ip[3]^ip[4]^ip[5]^ip[8]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[29],
                 datout[853] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[22]^ip[23]^ip[26]^ip[28]^ip[31],
                 datout[854] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[25]^ip[27]^ip[30],
                 datout[855] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[24]^ip[26]^ip[29],
                 datout[856] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[18]^ip[19]^ip[23]^ip[25]^ip[26]^ip[28]^ip[31],
                 datout[857] = ip[0]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[15]^ip[17]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[858] = ip[1]^ip[2]^ip[4]^ip[5]^ip[7]^ip[10]^ip[11]^ip[14]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30]^ip[31],
                 datout[859] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[9]^ip[10]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29]^ip[30],
                 datout[860] = ip[0]^ip[2]^ip[3]^ip[5]^ip[6]^ip[8]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[861] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[19]^ip[21]^ip[22]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[862] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[12]^ip[14]^ip[15]^ip[18]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[863] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[11]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[23]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[864] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[9]^ip[10]^ip[12]^ip[13]^ip[16]^ip[17]^ip[20]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[865] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[8]^ip[9]^ip[11]^ip[12]^ip[15]^ip[16]^ip[19]^ip[21]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[866] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[22]^ip[24]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[867] = ip[0]^ip[1]^ip[2]^ip[5]^ip[7]^ip[8]^ip[10]^ip[13]^ip[14]^ip[18]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[868] = ip[0]^ip[1]^ip[4]^ip[7]^ip[12]^ip[13]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[869] = ip[0]^ip[3]^ip[9]^ip[11]^ip[12]^ip[16]^ip[17]^ip[20]^ip[21]^ip[22]^ip[24]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[870] = ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[15]^ip[16]^ip[18]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[871] = ip[1]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[872] = ip[0]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[873] = ip[3]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[15]^ip[16]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[874] = ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[14]^ip[15]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[30],
                 datout[875] = ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[13]^ip[14]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[29],
                 datout[876] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[12]^ip[13]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[28],
                 datout[877] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[11]^ip[12]^ip[18]^ip[19]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[31],
                 datout[878] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[10]^ip[11]^ip[17]^ip[18]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[30],
                 datout[879] = ip[1]^ip[2]^ip[3]^ip[4]^ip[10]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[880] = ip[0]^ip[1]^ip[2]^ip[3]^ip[9]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30],
                 datout[881] = ip[0]^ip[1]^ip[2]^ip[6]^ip[8]^ip[9]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[882] = ip[0]^ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[13]^ip[14]^ip[15]^ip[16]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[883] = ip[0]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[884] = ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[885] = ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[886] = ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[887] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[18]^ip[20]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[888] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[13]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[889] = ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[12]^ip[16]^ip[17]^ip[19]^ip[23]^ip[24]^ip[30]^ip[31],
                 datout[890] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[11]^ip[15]^ip[16]^ip[18]^ip[22]^ip[23]^ip[29]^ip[30],
                 datout[891] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[10]^ip[14]^ip[15]^ip[17]^ip[21]^ip[22]^ip[28]^ip[29],
                 datout[892] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[13]^ip[14]^ip[16]^ip[18]^ip[21]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[893] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[9]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[894] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[24]^ip[29]^ip[30]^ip[31],
                 datout[895] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[23]^ip[26]^ip[28]^ip[29]^
                         ip[30]^ip[31],
                 datout[896] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[25]^ip[27]^ip[28]^
                         ip[29]^ip[30],
                 datout[897] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[21]^ip[24]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[898] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[23]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[899] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[900] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[19]^ip[20]^ip[21]^ip[24]^ip[28]^ip[30]^ip[31],
                 datout[901] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[19]^ip[23]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[902] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[20]^ip[22]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[903] = ip[1]^ip[3]^ip[4]^ip[5]^ip[10]^ip[11]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[904] = ip[0]^ip[2]^ip[3]^ip[4]^ip[9]^ip[10]^ip[17]^ip[18]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[905] = ip[1]^ip[2]^ip[3]^ip[6]^ip[8]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[906] = ip[0]^ip[1]^ip[2]^ip[5]^ip[7]^ip[15]^ip[16]^ip[18]^ip[19]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[907] = ip[0]^ip[1]^ip[4]^ip[9]^ip[14]^ip[15]^ip[17]^ip[22]^ip[23]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[908] = ip[0]^ip[3]^ip[6]^ip[8]^ip[9]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[28]^ip[30]^ip[31],
                 datout[909] = ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[910] = ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[911] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[912] = ip[2]^ip[3]^ip[4]^ip[5]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[23]^ip[24]^ip[27]^ip[28]^ip[31],
                 datout[913] = ip[1]^ip[2]^ip[3]^ip[4]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[22]^ip[23]^ip[26]^ip[27]^ip[30],
                 datout[914] = ip[0]^ip[1]^ip[2]^ip[3]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[21]^ip[22]^ip[25]^ip[26]^ip[29],
                 datout[915] = ip[0]^ip[1]^ip[2]^ip[6]^ip[7]^ip[11]^ip[12]^ip[13]^ip[18]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28]^ip[31],
                 datout[916] = ip[0]^ip[1]^ip[5]^ip[9]^ip[10]^ip[11]^ip[12]^ip[17]^ip[18]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[917] = ip[0]^ip[4]^ip[6]^ip[8]^ip[10]^ip[11]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30]^ip[31],
                 datout[918] = ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[919] = ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[920] = ip[1]^ip[3]^ip[4]^ip[5]^ip[8]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[921] = ip[0]^ip[2]^ip[3]^ip[4]^ip[7]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[922] = ip[1]^ip[2]^ip[3]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[22]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[923] = ip[0]^ip[1]^ip[2]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[21]^ip[23]^ip[24]^ip[26]^ip[30],
                 datout[924] = ip[0]^ip[1]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[22]^ip[23]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[925] = ip[0]^ip[5]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[926] = ip[4]^ip[6]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[927] = ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[928] = ip[2]^ip[4]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[929] = ip[1]^ip[3]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28],
                 datout[930] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27],
                 datout[931] = ip[1]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[19]^ip[21]^ip[22]^ip[24]^ip[25]^ip[31],
                 datout[932] = ip[0]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[18]^ip[20]^ip[21]^ip[23]^ip[24]^ip[30],
                 datout[933] = ip[3]^ip[5]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[26]^ip[29]^ip[31],
                 datout[934] = ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[25]^ip[28]^ip[30],
                 datout[935] = ip[1]^ip[3]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[15]^ip[16]^ip[17]^ip[20]^ip[21]^ip[24]^ip[27]^ip[29],
                 datout[936] = ip[0]^ip[2]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[23]^ip[26]^ip[28],
                 datout[937] = ip[1]^ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[19]^ip[20]^ip[22]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[938] = ip[0]^ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[18]^ip[19]^ip[21]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[939] = ip[1]^ip[2]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[17]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[940] = ip[0]^ip[1]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[16]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30],
                 datout[941] = ip[0]^ip[3]^ip[5]^ip[7]^ip[10]^ip[11]^ip[15]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[942] = ip[2]^ip[4]^ip[10]^ip[14]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[943] = ip[1]^ip[3]^ip[9]^ip[13]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[944] = ip[0]^ip[2]^ip[8]^ip[12]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[29],
                 datout[945] = ip[1]^ip[6]^ip[7]^ip[9]^ip[11]^ip[14]^ip[15]^ip[16]^ip[19]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[946] = ip[0]^ip[5]^ip[6]^ip[8]^ip[10]^ip[13]^ip[14]^ip[15]^ip[18]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[30],
                 datout[947] = ip[4]^ip[5]^ip[6]^ip[7]^ip[12]^ip[13]^ip[14]^ip[17]^ip[18]^ip[23]^ip[24]^ip[25]^ip[29]^ip[31],
                 datout[948] = ip[3]^ip[4]^ip[5]^ip[6]^ip[11]^ip[12]^ip[13]^ip[16]^ip[17]^ip[22]^ip[23]^ip[24]^ip[28]^ip[30],
                 datout[949] = ip[2]^ip[3]^ip[4]^ip[5]^ip[10]^ip[11]^ip[12]^ip[15]^ip[16]^ip[21]^ip[22]^ip[23]^ip[27]^ip[29],
                 datout[950] = ip[1]^ip[2]^ip[3]^ip[4]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[20]^ip[21]^ip[22]^ip[26]^ip[28],
                 datout[951] = ip[0]^ip[1]^ip[2]^ip[3]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[19]^ip[20]^ip[21]^ip[25]^ip[27],
                 datout[952] = ip[0]^ip[1]^ip[2]^ip[6]^ip[7]^ip[8]^ip[12]^ip[13]^ip[19]^ip[24]^ip[31],
                 datout[953] = ip[0]^ip[1]^ip[5]^ip[7]^ip[9]^ip[11]^ip[12]^ip[20]^ip[23]^ip[26]^ip[30]^ip[31],
                 datout[954] = ip[0]^ip[4]^ip[8]^ip[9]^ip[10]^ip[11]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[955] = ip[3]^ip[6]^ip[7]^ip[8]^ip[10]^ip[17]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[956] = ip[2]^ip[5]^ip[6]^ip[7]^ip[9]^ip[16]^ip[18]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[957] = ip[1]^ip[4]^ip[5]^ip[6]^ip[8]^ip[15]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[958] = ip[0]^ip[3]^ip[4]^ip[5]^ip[7]^ip[14]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[959] = ip[2]^ip[3]^ip[4]^ip[9]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[960] = ip[1]^ip[2]^ip[3]^ip[8]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[30],
                 datout[961] = ip[0]^ip[1]^ip[2]^ip[7]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[29],
                 datout[962] = ip[0]^ip[1]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[28]^ip[31],
                 datout[963] = ip[0]^ip[6]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[19]^ip[21]^ip[23]^ip[25]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[964] = ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[22]^ip[24]^ip[25]^ip[29]^ip[30]^ip[31],
                 datout[965] = ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[21]^ip[23]^ip[24]^ip[28]^ip[29]^ip[30],
                 datout[966] = ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[20]^ip[22]^ip[23]^ip[27]^ip[28]^ip[29],
                 datout[967] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[19]^ip[21]^ip[22]^ip[26]^ip[27]^ip[28],
                 datout[968] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[18]^ip[20]^ip[21]^ip[25]^ip[26]^ip[27],
                 datout[969] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[17]^ip[19]^ip[20]^ip[24]^ip[25]^ip[26],
                 datout[970] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[9]^ip[16]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[31],
                 datout[971] = ip[0]^ip[2]^ip[3]^ip[4]^ip[8]^ip[9]^ip[15]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[972] = ip[1]^ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[14]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[973] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[13]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[974] = ip[0]^ip[1]^ip[4]^ip[5]^ip[7]^ip[9]^ip[12]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[975] = ip[0]^ip[3]^ip[4]^ip[8]^ip[9]^ip[11]^ip[16]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[976] = ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[15]^ip[18]^ip[21]^ip[22]^ip[24]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[977] = ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[14]^ip[17]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[978] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[13]^ip[16]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[979] = ip[0]^ip[3]^ip[4]^ip[5]^ip[7]^ip[9]^ip[12]^ip[15]^ip[19]^ip[20]^ip[21]^ip[24]^ip[27]^ip[28]^ip[31],
                 datout[980] = ip[2]^ip[3]^ip[4]^ip[8]^ip[9]^ip[11]^ip[14]^ip[19]^ip[23]^ip[27]^ip[30]^ip[31],
                 datout[981] = ip[1]^ip[2]^ip[3]^ip[7]^ip[8]^ip[10]^ip[13]^ip[18]^ip[22]^ip[26]^ip[29]^ip[30],
                 datout[982] = ip[0]^ip[1]^ip[2]^ip[6]^ip[7]^ip[9]^ip[12]^ip[17]^ip[21]^ip[25]^ip[28]^ip[29],
                 datout[983] = ip[0]^ip[1]^ip[5]^ip[8]^ip[9]^ip[11]^ip[16]^ip[18]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[984] = ip[0]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[15]^ip[17]^ip[18]^ip[20]^ip[23]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[985] = ip[3]^ip[5]^ip[7]^ip[8]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[29]^ip[30]^ip[31],
                 datout[986] = ip[2]^ip[4]^ip[6]^ip[7]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[28]^ip[29]^ip[30],
                 datout[987] = ip[1]^ip[3]^ip[5]^ip[6]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[27]^ip[28]^ip[29],
                 datout[988] = ip[0]^ip[2]^ip[4]^ip[5]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[26]^ip[27]^ip[28],
                 datout[989] = ip[1]^ip[3]^ip[4]^ip[6]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[25]^ip[27]^ip[31],
                 datout[990] = ip[0]^ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[24]^ip[26]^ip[30],
                 datout[991] = ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[992] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[17]^ip[19]^ip[22]^ip[24]^ip[25]^ip[28]^ip[30],
                 datout[993] = ip[0]^ip[2]^ip[4]^ip[5]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[16]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[994] = ip[1]^ip[3]^ip[4]^ip[7]^ip[10]^ip[11]^ip[15]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[995] = ip[0]^ip[2]^ip[3]^ip[6]^ip[9]^ip[10]^ip[14]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[996] = ip[1]^ip[2]^ip[5]^ip[6]^ip[8]^ip[13]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[28]^ip[29]^ip[31],
                 datout[997] = ip[0]^ip[1]^ip[4]^ip[5]^ip[7]^ip[12]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[27]^ip[28]^ip[30],
                 datout[998] = ip[0]^ip[3]^ip[4]^ip[9]^ip[11]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[27]^ip[29]^ip[31],
                 datout[999] = ip[2]^ip[3]^ip[6]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[28]^ip[30]^ip[31],
                 datout[1000] = ip[1]^ip[2]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[27]^ip[29]^ip[30],
                 datout[1001] = ip[0]^ip[1]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[26]^ip[28]^ip[29],
                 datout[1002] = ip[0]^ip[3]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[18]^ip[20]^ip[25]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[1003] = ip[2]^ip[4]^ip[8]^ip[10]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[24]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[1004] = ip[1]^ip[3]^ip[7]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30],
                 datout[1005] = ip[0]^ip[2]^ip[6]^ip[8]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29],
                 datout[1006] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^
                         ip[31],
                 datout[1007] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[27]^ip[30],
                 datout[1008] = ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[22]^ip[24]^ip[25]^ip[29]^ip[31],
                 datout[1009] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[21]^ip[23]^ip[24]^ip[28]^ip[30],
                 datout[1010] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[20]^ip[22]^ip[23]^ip[27]^ip[29],
                 datout[1011] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[19]^ip[21]^ip[22]^ip[26]^ip[28],
                 datout[1012] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[8]^ip[10]^ip[11]^ip[12]^ip[15]^ip[21]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[1013] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[14]^ip[18]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[1014] = ip[1]^ip[2]^ip[3]^ip[5]^ip[10]^ip[13]^ip[17]^ip[18]^ip[20]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[1015] = ip[0]^ip[1]^ip[2]^ip[4]^ip[9]^ip[12]^ip[16]^ip[17]^ip[19]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[1016] = ip[0]^ip[1]^ip[3]^ip[6]^ip[8]^ip[9]^ip[11]^ip[15]^ip[16]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[1017] = ip[0]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[18]^ip[19]^ip[21]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[1018] = ip[1]^ip[4]^ip[5]^ip[7]^ip[8]^ip[13]^ip[14]^ip[17]^ip[22]^ip[24]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[1019] = ip[0]^ip[3]^ip[4]^ip[6]^ip[7]^ip[12]^ip[13]^ip[16]^ip[21]^ip[23]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[1020] = ip[2]^ip[3]^ip[5]^ip[9]^ip[11]^ip[12]^ip[15]^ip[18]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[1021] = ip[1]^ip[2]^ip[4]^ip[8]^ip[10]^ip[11]^ip[14]^ip[17]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[1022] = ip[0]^ip[1]^ip[3]^ip[7]^ip[9]^ip[10]^ip[13]^ip[16]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[1023] = ip[0]^ip[2]^ip[8]^ip[12]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[31],
                 datout[1024] = ip[1]^ip[6]^ip[7]^ip[9]^ip[11]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[1025] = ip[0]^ip[5]^ip[6]^ip[8]^ip[10]^ip[13]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[29]^ip[30],
                 datout[1026] = ip[4]^ip[5]^ip[6]^ip[7]^ip[12]^ip[15]^ip[17]^ip[19]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[1027] = ip[3]^ip[4]^ip[5]^ip[6]^ip[11]^ip[14]^ip[16]^ip[18]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[1028] = ip[2]^ip[3]^ip[4]^ip[5]^ip[10]^ip[13]^ip[15]^ip[17]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29],
                 datout[1029] = ip[1]^ip[2]^ip[3]^ip[4]^ip[9]^ip[12]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[28],
                 datout[1030] = ip[0]^ip[1]^ip[2]^ip[3]^ip[8]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27],
                 datout[1031] = ip[0]^ip[1]^ip[2]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[24]^ip[31],
                 datout[1032] = ip[0]^ip[1]^ip[5]^ip[8]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[22]^ip[23]^ip[26]^ip[30]^ip[31],
                 datout[1033] = ip[0]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[22]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[1034] = ip[3]^ip[5]^ip[8]^ip[11]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[1035] = ip[2]^ip[4]^ip[7]^ip[10]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[1036] = ip[1]^ip[3]^ip[6]^ip[9]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[1037] = ip[0]^ip[2]^ip[5]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[18]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[1038] = ip[1]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[1039] = ip[0]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[30],
                 datout[1040] = ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[1041] = ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[25]^ip[28]^ip[30],
                 datout[1042] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[20]^ip[21]^ip[23]^ip[24]^ip[27]^ip[29],
                 datout[1043] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[28]^ip[31],
                 datout[1044] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[21]^ip[22]^ip[27]^ip[30],
                 datout[1045] = ip[0]^ip[1]^ip[3]^ip[4]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[21]^ip[29]^ip[31],
                 datout[1046] = ip[0]^ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[1047] = ip[1]^ip[2]^ip[5]^ip[7]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[1048] = ip[0]^ip[1]^ip[4]^ip[6]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[1049] = ip[0]^ip[3]^ip[5]^ip[6]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[1050] = ip[2]^ip[4]^ip[5]^ip[6]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[1051] = ip[1]^ip[3]^ip[4]^ip[5]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[1052] = ip[0]^ip[2]^ip[3]^ip[4]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29],
                 datout[1053] = ip[1]^ip[2]^ip[3]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^
                         ip[31],
                 datout[1054] = ip[0]^ip[1]^ip[2]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^
                         ip[30],
                 datout[1055] = ip[0]^ip[1]^ip[4]^ip[8]^ip[10]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[29]^ip[31],
                 datout[1056] = ip[0]^ip[3]^ip[6]^ip[7]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[1057] = ip[2]^ip[5]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[1058] = ip[1]^ip[4]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[1059] = ip[0]^ip[3]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[1060] = ip[2]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[31],
                 datout[1061] = ip[1]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[30],
                 datout[1062] = ip[0]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[22]^ip[25]^ip[26]^ip[29],
                 datout[1063] = ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[16]^ip[18]^ip[19]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28]^ip[31],
                 datout[1064] = ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[15]^ip[17]^ip[18]^ip[20]^ip[23]^ip[24]^ip[25]^ip[27]^ip[30],
                 datout[1065] = ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[16]^ip[17]^ip[19]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29],
                 datout[1066] = ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[13]^ip[15]^ip[16]^ip[18]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28],
                 datout[1067] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[12]^ip[14]^ip[15]^ip[17]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27],
                 datout[1068] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[11]^ip[13]^ip[14]^ip[16]^ip[19]^ip[20]^ip[21]^ip[23]^ip[26],
                 datout[1069] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[19]^ip[22]^ip[25]^ip[26]^ip[31],
                 datout[1070] = ip[0]^ip[1]^ip[3]^ip[8]^ip[11]^ip[12]^ip[14]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[1071] = ip[0]^ip[2]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[18]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[1072] = ip[1]^ip[5]^ip[8]^ip[10]^ip[12]^ip[17]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[1073] = ip[0]^ip[4]^ip[7]^ip[9]^ip[11]^ip[16]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[1074] = ip[3]^ip[8]^ip[9]^ip[10]^ip[15]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[1075] = ip[2]^ip[7]^ip[8]^ip[9]^ip[14]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[1076] = ip[1]^ip[6]^ip[7]^ip[8]^ip[13]^ip[19]^ip[20]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[1077] = ip[0]^ip[5]^ip[6]^ip[7]^ip[12]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[1078] = ip[4]^ip[5]^ip[9]^ip[11]^ip[17]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[1079] = ip[3]^ip[4]^ip[8]^ip[10]^ip[16]^ip[18]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[1080] = ip[2]^ip[3]^ip[7]^ip[9]^ip[15]^ip[17]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[29],
                 datout[1081] = ip[1]^ip[2]^ip[6]^ip[8]^ip[14]^ip[16]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28],
                 datout[1082] = ip[0]^ip[1]^ip[5]^ip[7]^ip[13]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27],
                 datout[1083] = ip[0]^ip[4]^ip[9]^ip[12]^ip[14]^ip[19]^ip[21]^ip[22]^ip[31],
                 datout[1084] = ip[3]^ip[6]^ip[8]^ip[9]^ip[11]^ip[13]^ip[21]^ip[26]^ip[30]^ip[31],
                 datout[1085] = ip[2]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[20]^ip[25]^ip[29]^ip[30],
                 datout[1086] = ip[1]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[19]^ip[24]^ip[28]^ip[29],
                 datout[1087] = ip[0]^ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[18]^ip[23]^ip[27]^ip[28],
                 datout[1088] = ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[17]^ip[18]^ip[20]^ip[22]^ip[27]^ip[31],
                 datout[1089] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[16]^ip[17]^ip[19]^ip[21]^ip[26]^ip[30],
                 datout[1090] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[15]^ip[16]^ip[18]^ip[20]^ip[25]^ip[29],
                 datout[1091] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[9]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[24]^ip[26]^ip[28]^ip[31],
                 datout[1092] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[23]^ip[25]^ip[27]^ip[30],
                 datout[1093] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[24]^ip[29]^ip[31],
                 datout[1094] = ip[0]^ip[1]^ip[3]^ip[5]^ip[8]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[1095] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[22]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[1096] = ip[1]^ip[3]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[16]^ip[20]^ip[21]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[1097] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[13]^ip[15]^ip[19]^ip[20]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[1098] = ip[1]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[19]^ip[20]^ip[22]^ip[23]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[1099] = ip[0]^ip[2]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[18]^ip[19]^ip[21]^ip[22]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[1100] = ip[1]^ip[3]^ip[7]^ip[8]^ip[10]^ip[12]^ip[17]^ip[21]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[1101] = ip[0]^ip[2]^ip[6]^ip[7]^ip[9]^ip[11]^ip[16]^ip[20]^ip[24]^ip[26]^ip[28]^ip[30],
                 datout[1102] = ip[1]^ip[5]^ip[8]^ip[9]^ip[10]^ip[15]^ip[18]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[1103] = ip[0]^ip[4]^ip[7]^ip[8]^ip[9]^ip[14]^ip[17]^ip[18]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 datout[1104] = ip[3]^ip[7]^ip[8]^ip[9]^ip[13]^ip[16]^ip[17]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[1105] = ip[2]^ip[6]^ip[7]^ip[8]^ip[12]^ip[15]^ip[16]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 datout[1106] = ip[1]^ip[5]^ip[6]^ip[7]^ip[11]^ip[14]^ip[15]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29],
                 datout[1107] = ip[0]^ip[4]^ip[5]^ip[6]^ip[10]^ip[13]^ip[14]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28],
                 datout[1108] = ip[3]^ip[4]^ip[5]^ip[6]^ip[12]^ip[13]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[1109] = ip[2]^ip[3]^ip[4]^ip[5]^ip[11]^ip[12]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[1110] = ip[1]^ip[2]^ip[3]^ip[4]^ip[10]^ip[11]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[29],
                 datout[1111] = ip[0]^ip[1]^ip[2]^ip[3]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[28],
                 datout[1112] = ip[0]^ip[1]^ip[2]^ip[6]^ip[8]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[31],
                 datout[1113] = ip[0]^ip[1]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[19]^ip[21]^ip[22]^ip[25]^ip[30]^ip[31],
                 datout[1114] = ip[0]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[21]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[1115] = ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[18]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[1116] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[17]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[1117] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[16]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[1118] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[15]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[1119] = ip[0]^ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[1120] = ip[1]^ip[2]^ip[3]^ip[7]^ip[8]^ip[13]^ip[17]^ip[19]^ip[21]^ip[23]^ip[24]^ip[30]^ip[31],
                 datout[1121] = ip[0]^ip[1]^ip[2]^ip[6]^ip[7]^ip[12]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[29]^ip[30],
                 datout[1122] = ip[0]^ip[1]^ip[5]^ip[9]^ip[11]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[1123] = ip[0]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[1124] = ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[13]^ip[15]^ip[16]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[1125] = ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[12]^ip[14]^ip[15]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[1126] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[11]^ip[13]^ip[14]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[1127] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[10]^ip[12]^ip[13]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28],
                 datout[1128] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[11]^ip[12]^ip[18]^ip[21]^ip[23]^ip[25]^ip[27]^ip[31],
                 datout[1129] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[10]^ip[11]^ip[17]^ip[20]^ip[22]^ip[24]^ip[26]^ip[30],
                 datout[1130] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[10]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[1131] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[15]^ip[17]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[1132] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[14]^ip[16]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[1133] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[13]^ip[15]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[1134] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[12]^ip[14]^ip[17]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[1135] = ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[9]^ip[11]^ip[13]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[1136] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[8]^ip[10]^ip[12]^ip[15]^ip[16]^ip[17]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[1137] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[11]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[21]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[1138] = ip[0]^ip[1]^ip[4]^ip[5]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[17]^ip[24]^ip[28]^ip[30]^ip[31],
                 datout[1139] = ip[0]^ip[3]^ip[4]^ip[6]^ip[8]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[23]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[1140] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[1141] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[1142] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[1143] = ip[0]^ip[2]^ip[3]^ip[4]^ip[8]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[1144] = ip[1]^ip[2]^ip[3]^ip[6]^ip[7]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[24]^ip[27]^ip[30]^ip[31],
                 datout[1145] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[23]^ip[26]^ip[29]^ip[30],
                 datout[1146] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[1147] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^
                         ip[30]^ip[31],
                 datout[1148] = ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[19]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[1149] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[18]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[1150] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[17]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[1151] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[16]^ip[18]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[31],
                 datout[1152] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[7]^ip[11]^ip[15]^ip[17]^ip[18]^ip[21]^ip[23]^ip[27]^ip[30]^ip[31],
                 datout[1153] = ip[0]^ip[1]^ip[3]^ip[4]^ip[9]^ip[10]^ip[14]^ip[16]^ip[17]^ip[18]^ip[22]^ip[29]^ip[30]^ip[31],
                 datout[1154] = ip[0]^ip[2]^ip[3]^ip[6]^ip[8]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[1155] = ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[9]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[1156] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[8]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[1157] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^
                         ip[29]^ip[31],
                 datout[1158] = ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^
                         ip[30]^ip[31],
                 datout[1159] = ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^
                         ip[29]^ip[30],
                 datout[1160] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[25]^ip[26]^
                         ip[28]^ip[29],
                 datout[1161] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[24]^ip[25]^ip[26]^
                         ip[27]^ip[28]^ip[31],
                 datout[1162] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[23]^ip[24]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[1163] = ip[0]^ip[3]^ip[4]^ip[5]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30]^ip[31],
                 datout[1164] = ip[2]^ip[3]^ip[4]^ip[6]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[29]^
                         ip[30]^ip[31],
                 datout[1165] = ip[1]^ip[2]^ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[25]^ip[27]^ip[28]^
                         ip[29]^ip[30],
                 datout[1166] = ip[0]^ip[1]^ip[2]^ip[4]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^
                         ip[28]^ip[29],
                 datout[1167] = ip[0]^ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[23]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[1168] = ip[0]^ip[2]^ip[5]^ip[7]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[20]^ip[22]^ip[24]^ip[27]^ip[30]^ip[31],
                 datout[1169] = ip[1]^ip[4]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[29]^ip[30]^ip[31],
                 datout[1170] = ip[0]^ip[3]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[28]^ip[29]^ip[30],
                 datout[1171] = ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[1172] = ip[1]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[1173] = ip[0]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[1174] = ip[3]^ip[5]^ip[7]^ip[8]^ip[10]^ip[13]^ip[14]^ip[16]^ip[17]^ip[20]^ip[23]^ip[24]^ip[25]^ip[28]^ip[31],
                 datout[1175] = ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[22]^ip[23]^ip[24]^ip[27]^ip[30],
                 datout[1176] = ip[1]^ip[3]^ip[5]^ip[6]^ip[8]^ip[11]^ip[12]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[26]^ip[29],
                 datout[1177] = ip[0]^ip[2]^ip[4]^ip[5]^ip[7]^ip[10]^ip[11]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[22]^ip[25]^ip[28],
                 datout[1178] = ip[1]^ip[3]^ip[4]^ip[10]^ip[12]^ip[13]^ip[16]^ip[18]^ip[19]^ip[21]^ip[24]^ip[26]^ip[27]^ip[31],
                 datout[1179] = ip[0]^ip[2]^ip[3]^ip[9]^ip[11]^ip[12]^ip[15]^ip[17]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26]^ip[30],
                 datout[1180] = ip[1]^ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[1181] = ip[0]^ip[1]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30],
                 datout[1182] = ip[0]^ip[4]^ip[7]^ip[8]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[1183] = ip[3]^ip[7]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[1184] = ip[2]^ip[6]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[1185] = ip[1]^ip[5]^ip[7]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[29],
                 datout[1186] = ip[0]^ip[4]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[28],
                 datout[1187] = ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[24]^ip[27]^ip[31],
                 datout[1188] = ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[23]^ip[26]^ip[30],
                 datout[1189] = ip[1]^ip[3]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[22]^ip[25]^ip[29],
                 datout[1190] = ip[0]^ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[21]^ip[24]^ip[28],
                 datout[1191] = ip[1]^ip[2]^ip[3]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[23]^ip[26]^ip[27]^ip[31],
                 datout[1192] = ip[0]^ip[1]^ip[2]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[22]^ip[25]^ip[26]^ip[30],
                 datout[1193] = ip[0]^ip[1]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[1194] = ip[0]^ip[4]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[1195] = ip[3]^ip[7]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[1196] = ip[2]^ip[6]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[1197] = ip[1]^ip[5]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[1198] = ip[0]^ip[4]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28],
                 datout[1199] = ip[3]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[16]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^ip[31],
                 datout[1200] = ip[2]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[15]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[30],
                 datout[1201] = ip[1]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[25]^ip[29],
                 datout[1202] = ip[0]^ip[3]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[13]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[28],
                 datout[1203] = ip[2]^ip[3]^ip[4]^ip[8]^ip[12]^ip[15]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[26]^ip[27]^ip[31],
                 datout[1204] = ip[1]^ip[2]^ip[3]^ip[7]^ip[11]^ip[14]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[26]^ip[30],
                 datout[1205] = ip[0]^ip[1]^ip[2]^ip[6]^ip[10]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[24]^ip[25]^ip[29],
                 datout[1206] = ip[0]^ip[1]^ip[5]^ip[6]^ip[12]^ip[14]^ip[16]^ip[17]^ip[23]^ip[24]^ip[26]^ip[28]^ip[31],
                 datout[1207] = ip[0]^ip[4]^ip[5]^ip[6]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[1208] = ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[29]^ip[30]^
                         ip[31],
                 datout[1209] = ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[28]^ip[29]^ip[30],
                 datout[1210] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[27]^ip[28]^ip[29],
                 datout[1211] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[26]^ip[27]^ip[28],
                 datout[1212] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[21]^ip[25]^ip[27]^ip[31],
                 datout[1213] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[24]^ip[30]^ip[31],
                 datout[1214] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[23]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[1215] = ip[1]^ip[2]^ip[4]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^
                         ip[31],
                 datout[1216] = ip[0]^ip[1]^ip[3]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^
                         ip[30],
                 datout[1217] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[1218] = ip[1]^ip[5]^ip[7]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[1219] = ip[0]^ip[4]^ip[6]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[22]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[1220] = ip[3]^ip[5]^ip[6]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[21]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[1221] = ip[2]^ip[4]^ip[5]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[20]^ip[24]^ip[27]^ip[28]^ip[30],
                 datout[1222] = ip[1]^ip[3]^ip[4]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[19]^ip[23]^ip[26]^ip[27]^ip[29],
                 datout[1223] = ip[0]^ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[18]^ip[22]^ip[25]^ip[26]^ip[28],
                 datout[1224] = ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[17]^ip[18]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[1225] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[16]^ip[17]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[1226] = ip[0]^ip[2]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[15]^ip[16]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[1227] = ip[1]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[14]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[1228] = ip[0]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[13]^ip[14]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30],
                 datout[1229] = ip[1]^ip[2]^ip[4]^ip[5]^ip[9]^ip[12]^ip[13]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29]^ip[31],
                 datout[1230] = ip[0]^ip[1]^ip[3]^ip[4]^ip[8]^ip[11]^ip[12]^ip[16]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28]^ip[30],
                 datout[1231] = ip[0]^ip[2]^ip[3]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[27]^ip[29]^ip[31],
                 datout[1232] = ip[1]^ip[2]^ip[5]^ip[8]^ip[10]^ip[14]^ip[16]^ip[17]^ip[21]^ip[28]^ip[30]^ip[31],
                 datout[1233] = ip[0]^ip[1]^ip[4]^ip[7]^ip[9]^ip[13]^ip[15]^ip[16]^ip[20]^ip[27]^ip[29]^ip[30],
                 datout[1234] = ip[0]^ip[3]^ip[8]^ip[9]^ip[12]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[28]^ip[29]^ip[31],
                 datout[1235] = ip[2]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[17]^ip[19]^ip[20]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[1236] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[16]^ip[18]^ip[19]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[1237] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[15]^ip[17]^ip[18]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29],
                 datout[1238] = ip[3]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[1239] = ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[30],
                 datout[1240] = ip[1]^ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[14]^ip[15]^ip[16]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29],
                 datout[1241] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[11]^ip[13]^ip[14]^ip[15]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28],
                 datout[1242] = ip[0]^ip[1]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[31],
                 datout[1243] = ip[0]^ip[3]^ip[4]^ip[8]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[21]^ip[22]^ip[23]^ip[25]^ip[30]^ip[31],
                 datout[1244] = ip[2]^ip[3]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[18]^ip[21]^ip[22]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[1245] = ip[1]^ip[2]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[17]^ip[20]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[1246] = ip[0]^ip[1]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[19]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[1247] = ip[0]^ip[3]^ip[4]^ip[7]^ip[8]^ip[11]^ip[13]^ip[15]^ip[19]^ip[20]^ip[21]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[1248] = ip[2]^ip[3]^ip[7]^ip[9]^ip[10]^ip[12]^ip[14]^ip[19]^ip[22]^ip[27]^ip[30]^ip[31],
                 datout[1249] = ip[1]^ip[2]^ip[6]^ip[8]^ip[9]^ip[11]^ip[13]^ip[18]^ip[21]^ip[26]^ip[29]^ip[30],
                 datout[1250] = ip[0]^ip[1]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[17]^ip[20]^ip[25]^ip[28]^ip[29],
                 datout[1251] = ip[0]^ip[4]^ip[7]^ip[11]^ip[16]^ip[18]^ip[19]^ip[20]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[1252] = ip[3]^ip[9]^ip[10]^ip[15]^ip[17]^ip[19]^ip[20]^ip[23]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[1253] = ip[2]^ip[8]^ip[9]^ip[14]^ip[16]^ip[18]^ip[19]^ip[22]^ip[24]^ip[26]^ip[29]^ip[30],
                 datout[1254] = ip[1]^ip[7]^ip[8]^ip[13]^ip[15]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29],
                 datout[1255] = ip[0]^ip[6]^ip[7]^ip[12]^ip[14]^ip[16]^ip[17]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28],
                 datout[1256] = ip[5]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[27]^ip[31],
                 datout[1257] = ip[4]^ip[8]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[26]^ip[30],
                 datout[1258] = ip[3]^ip[7]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[25]^ip[29],
                 datout[1259] = ip[2]^ip[6]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[24]^ip[28],
                 datout[1260] = ip[1]^ip[5]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[23]^ip[27],
                 datout[1261] = ip[0]^ip[4]^ip[6]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[22]^ip[26],
                 datout[1262] = ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[25]^ip[26]^ip[31],
                 datout[1263] = ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[24]^ip[25]^ip[30],
                 datout[1264] = ip[1]^ip[3]^ip[4]^ip[5]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[23]^ip[24]^ip[29],
                 datout[1265] = ip[0]^ip[2]^ip[3]^ip[4]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[22]^ip[23]^ip[28],
                 datout[1266] = ip[1]^ip[2]^ip[3]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[31],
                 datout[1267] = ip[0]^ip[1]^ip[2]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[25]^ip[26]^ip[30],
                 datout[1268] = ip[0]^ip[1]^ip[8]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[19]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[1269] = ip[0]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[1270] = ip[5]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[1271] = ip[4]^ip[7]^ip[9]^ip[11]^ip[12]^ip[13]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[1272] = ip[3]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[1273] = ip[2]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28],
                 datout[1274] = ip[1]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27],
                 datout[1275] = ip[0]^ip[3]^ip[5]^ip[7]^ip[8]^ip[9]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26],
                 datout[1276] = ip[2]^ip[4]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[31],
                 datout[1277] = ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[30],
                 datout[1278] = ip[0]^ip[2]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[29],
                 datout[1279] = ip[1]^ip[4]^ip[5]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[31];
        end // gen_1280_loop

  512: begin :gen_512_loop

          assign op[0] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[9]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[22]^ip[24]^ip[27]^ip[30]^ip[31],
                 op[1] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[27]^ip[28]^ip[31],
                 op[2] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[10]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29],
                 op[3] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[11]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 op[4] = ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[12]^ip[18]^ip[19]^ip[20]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 op[5] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[13]^ip[20]^ip[24]^ip[25]^ip[29]^ip[30]^ip[31],
                 op[6] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[19]^ip[25]^ip[26]^ip[27]^ip[30]^ip[31],
                 op[7] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[15]^ip[19]^ip[20]^ip[21]^ip[26]^ip[28]^ip[31],
                 op[8] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[22]^ip[29],
                 op[9] = ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[23]^ip[30],
                 op[10] = ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[24]^ip[31],
                 op[11] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[15]^ip[16]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27],
                 op[12] = ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[16]^ip[17]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28],
                 op[13] = ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[17]^ip[18]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29],
                 op[14] = ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[18]^ip[19]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 op[15] = ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[19]^ip[20]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 op[16] = ip[0]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[19]^ip[20]^ip[26]^ip[28]^ip[30],
                 op[17] = ip[1]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[20]^ip[21]^ip[27]^ip[29]^ip[31],
                 op[18] = ip[0]^ip[2]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[22]^ip[27]^ip[28]^ip[30],
                 op[19] = ip[1]^ip[3]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[23]^ip[28]^ip[29]^ip[31],
                 op[20] = ip[0]^ip[2]^ip[4]^ip[7]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[24]^ip[27]^ip[29]^ip[30],
                 op[21] = ip[1]^ip[3]^ip[5]^ip[8]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[25]^ip[28]^ip[30]^ip[31],
                 op[22] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[26]^ip[27]^ip[29]^ip[31],
                 op[23] = ip[0]^ip[1]^ip[3]^ip[5]^ip[8]^ip[11]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[22]^ip[28]^ip[30],
                 op[24] = ip[1]^ip[2]^ip[4]^ip[6]^ip[9]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[23]^ip[29]^ip[31],
                 op[25] = ip[0]^ip[2]^ip[3]^ip[5]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[30],
                 op[26] = ip[1]^ip[3]^ip[4]^ip[6]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[31],
                 op[27] = ip[0]^ip[2]^ip[4]^ip[5]^ip[10]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29],
                 op[28] = ip[1]^ip[3]^ip[5]^ip[6]^ip[11]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30],
                 op[29] = ip[2]^ip[4]^ip[6]^ip[7]^ip[12]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 op[30] = ip[0]^ip[3]^ip[5]^ip[8]^ip[10]^ip[13]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[29]^ip[30],
                 op[31] = ip[1]^ip[4]^ip[6]^ip[9]^ip[11]^ip[14]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[30]^ip[31];

          assign datout[0] = ip[6]^ip[9]^ip[18]^ip[20]^ip[26]^ip[31],
                 datout[1] = ip[5]^ip[8]^ip[17]^ip[19]^ip[25]^ip[30],
                 datout[2] = ip[4]^ip[7]^ip[16]^ip[18]^ip[24]^ip[29],
                 datout[3] = ip[3]^ip[6]^ip[15]^ip[17]^ip[23]^ip[28],
                 datout[4] = ip[2]^ip[5]^ip[14]^ip[16]^ip[22]^ip[27],
                 datout[5] = ip[1]^ip[4]^ip[13]^ip[15]^ip[21]^ip[26],
                 datout[6] = ip[0]^ip[3]^ip[12]^ip[14]^ip[20]^ip[25],
                 datout[7] = ip[2]^ip[6]^ip[9]^ip[11]^ip[13]^ip[18]^ip[19]^ip[20]^ip[24]^ip[26]^ip[31],
                 datout[8] = ip[1]^ip[5]^ip[8]^ip[10]^ip[12]^ip[17]^ip[18]^ip[19]^ip[23]^ip[25]^ip[30],
                 datout[9] = ip[0]^ip[4]^ip[7]^ip[9]^ip[11]^ip[16]^ip[17]^ip[18]^ip[22]^ip[24]^ip[29],
                 datout[10] = ip[3]^ip[8]^ip[9]^ip[10]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[31],
                 datout[11] = ip[2]^ip[7]^ip[8]^ip[9]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[30],
                 datout[12] = ip[1]^ip[6]^ip[7]^ip[8]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[21]^ip[24]^ip[26]^ip[29],
                 datout[13] = ip[0]^ip[5]^ip[6]^ip[7]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[23]^ip[25]^ip[28],
                 datout[14] = ip[4]^ip[5]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[26]^ip[27]^ip[31],
                 datout[15] = ip[3]^ip[4]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[25]^ip[26]^ip[30],
                 datout[16] = ip[2]^ip[3]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[24]^ip[25]^ip[29],
                 datout[17] = ip[1]^ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[24]^ip[28],
                 datout[18] = ip[0]^ip[1]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[27],
                 datout[19] = ip[0]^ip[4]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[31],
                 datout[20] = ip[3]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[26]^ip[30]^ip[31],
                 datout[21] = ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[25]^ip[29]^ip[30],
                 datout[22] = ip[1]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[24]^ip[28]^ip[29],
                 datout[23] = ip[0]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[18]^ip[23]^ip[27]^ip[28],
                 datout[24] = ip[3]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[27]^ip[31],
                 datout[25] = ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[26]^ip[30],
                 datout[26] = ip[1]^ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[25]^ip[29],
                 datout[27] = ip[0]^ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[24]^ip[28],
                 datout[28] = ip[1]^ip[3]^ip[4]^ip[8]^ip[11]^ip[13]^ip[14]^ip[16]^ip[20]^ip[23]^ip[26]^ip[27]^ip[31],
                 datout[29] = ip[0]^ip[2]^ip[3]^ip[7]^ip[10]^ip[12]^ip[13]^ip[15]^ip[19]^ip[22]^ip[25]^ip[26]^ip[30],
                 datout[30] = ip[1]^ip[2]^ip[11]^ip[12]^ip[14]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[31] = ip[0]^ip[1]^ip[10]^ip[11]^ip[13]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30],
                 datout[32] = ip[0]^ip[6]^ip[10]^ip[12]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[33] = ip[5]^ip[6]^ip[11]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[34] = ip[4]^ip[5]^ip[10]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[35] = ip[3]^ip[4]^ip[9]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[29],
                 datout[36] = ip[2]^ip[3]^ip[8]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[28],
                 datout[37] = ip[1]^ip[2]^ip[7]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[24]^ip[26]^ip[27],
                 datout[38] = ip[0]^ip[1]^ip[6]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26],
                 datout[39] = ip[0]^ip[5]^ip[6]^ip[9]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[31],
                 datout[40] = ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[41] = ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30],
                 datout[42] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29],
                 datout[43] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28],
                 datout[44] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27],
                 datout[45] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[19]^ip[21]^ip[25]^ip[31],
                 datout[46] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[24]^ip[26]^ip[30]^ip[31],
                 datout[47] = ip[1]^ip[2]^ip[4]^ip[10]^ip[12]^ip[13]^ip[14]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[48] = ip[0]^ip[1]^ip[3]^ip[9]^ip[11]^ip[12]^ip[13]^ip[17]^ip[19]^ip[22]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[49] = ip[0]^ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[16]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[50] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[15]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[51] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[14]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[52] = ip[3]^ip[4]^ip[5]^ip[8]^ip[13]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[53] = ip[2]^ip[3]^ip[4]^ip[7]^ip[12]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28]^ip[30],
                 datout[54] = ip[1]^ip[2]^ip[3]^ip[6]^ip[11]^ip[14]^ip[15]^ip[16]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[29],
                 datout[55] = ip[0]^ip[1]^ip[2]^ip[5]^ip[10]^ip[13]^ip[14]^ip[15]^ip[18]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28],
                 datout[56] = ip[0]^ip[1]^ip[4]^ip[6]^ip[12]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[57] = ip[0]^ip[3]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[13]^ip[16]^ip[17]^ip[19]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[58] = ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[16]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[59] = ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[60] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[61] = ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[12]^ip[13]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[62] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[11]^ip[12]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[26]^ip[27]^ip[30],
                 datout[63] = ip[0]^ip[1]^ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[25]^ip[29]^ip[31],
                 datout[64] = ip[0]^ip[2]^ip[4]^ip[6]^ip[8]^ip[10]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[24]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[65] = ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[13]^ip[14]^ip[15]^ip[16]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[66] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[12]^ip[13]^ip[14]^ip[15]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[67] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[68] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[69] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[70] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[30],
                 datout[71] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[72] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[16]^ip[21]^ip[22]^ip[24]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[73] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[9]^ip[15]^ip[18]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[74] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[14]^ip[17]^ip[18]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[75] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[13]^ip[16]^ip[17]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[76] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[9]^ip[12]^ip[15]^ip[16]^ip[18]^ip[21]^ip[23]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[77] = ip[0]^ip[1]^ip[3]^ip[8]^ip[9]^ip[11]^ip[14]^ip[15]^ip[17]^ip[18]^ip[22]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[78] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[79] = ip[1]^ip[5]^ip[7]^ip[8]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[80] = ip[0]^ip[4]^ip[6]^ip[7]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[81] = ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[82] = ip[2]^ip[4]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[83] = ip[1]^ip[3]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[84] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[85] = ip[1]^ip[5]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[86] = ip[0]^ip[4]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[87] = ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[88] = ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30],
                 datout[89] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[29],
                 datout[90] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28],
                 datout[91] = ip[1]^ip[2]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[92] = ip[0]^ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[93] = ip[0]^ip[2]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[94] = ip[1]^ip[4]^ip[7]^ip[8]^ip[13]^ip[14]^ip[16]^ip[17]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[95] = ip[0]^ip[3]^ip[6]^ip[7]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30],
                 datout[96] = ip[2]^ip[5]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29]^ip[31],
                 datout[97] = ip[1]^ip[4]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28]^ip[30],
                 datout[98] = ip[0]^ip[3]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[29],
                 datout[99] = ip[2]^ip[8]^ip[11]^ip[12]^ip[19]^ip[21]^ip[25]^ip[28]^ip[31],
                 datout[100] = ip[1]^ip[7]^ip[10]^ip[11]^ip[18]^ip[20]^ip[24]^ip[27]^ip[30],
                 datout[101] = ip[0]^ip[6]^ip[9]^ip[10]^ip[17]^ip[19]^ip[23]^ip[26]^ip[29],
                 datout[102] = ip[5]^ip[6]^ip[8]^ip[16]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28]^ip[31],
                 datout[103] = ip[4]^ip[5]^ip[7]^ip[15]^ip[19]^ip[21]^ip[24]^ip[25]^ip[27]^ip[30],
                 datout[104] = ip[3]^ip[4]^ip[6]^ip[14]^ip[18]^ip[20]^ip[23]^ip[24]^ip[26]^ip[29],
                 datout[105] = ip[2]^ip[3]^ip[5]^ip[13]^ip[17]^ip[19]^ip[22]^ip[23]^ip[25]^ip[28],
                 datout[106] = ip[1]^ip[2]^ip[4]^ip[12]^ip[16]^ip[18]^ip[21]^ip[22]^ip[24]^ip[27],
                 datout[107] = ip[0]^ip[1]^ip[3]^ip[11]^ip[15]^ip[17]^ip[20]^ip[21]^ip[23]^ip[26],
                 datout[108] = ip[0]^ip[2]^ip[6]^ip[9]^ip[10]^ip[14]^ip[16]^ip[18]^ip[19]^ip[22]^ip[25]^ip[26]^ip[31],
                 datout[109] = ip[1]^ip[5]^ip[6]^ip[8]^ip[13]^ip[15]^ip[17]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[110] = ip[0]^ip[4]^ip[5]^ip[7]^ip[12]^ip[14]^ip[16]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30],
                 datout[111] = ip[3]^ip[4]^ip[9]^ip[11]^ip[13]^ip[15]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[112] = ip[2]^ip[3]^ip[8]^ip[10]^ip[12]^ip[14]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[113] = ip[1]^ip[2]^ip[7]^ip[9]^ip[11]^ip[13]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29],
                 datout[114] = ip[0]^ip[1]^ip[6]^ip[8]^ip[10]^ip[12]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[28],
                 datout[115] = ip[0]^ip[5]^ip[6]^ip[7]^ip[11]^ip[15]^ip[16]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[116] = ip[4]^ip[5]^ip[9]^ip[10]^ip[14]^ip[15]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[117] = ip[3]^ip[4]^ip[8]^ip[9]^ip[13]^ip[14]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30],
                 datout[118] = ip[2]^ip[3]^ip[7]^ip[8]^ip[12]^ip[13]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[28]^ip[29],
                 datout[119] = ip[1]^ip[2]^ip[6]^ip[7]^ip[11]^ip[12]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[27]^ip[28],
                 datout[120] = ip[0]^ip[1]^ip[5]^ip[6]^ip[10]^ip[11]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[26]^ip[27],
                 datout[121] = ip[0]^ip[4]^ip[5]^ip[6]^ip[10]^ip[15]^ip[16]^ip[19]^ip[25]^ip[31],
                 datout[122] = ip[3]^ip[4]^ip[5]^ip[6]^ip[14]^ip[15]^ip[20]^ip[24]^ip[26]^ip[30]^ip[31],
                 datout[123] = ip[2]^ip[3]^ip[4]^ip[5]^ip[13]^ip[14]^ip[19]^ip[23]^ip[25]^ip[29]^ip[30],
                 datout[124] = ip[1]^ip[2]^ip[3]^ip[4]^ip[12]^ip[13]^ip[18]^ip[22]^ip[24]^ip[28]^ip[29],
                 datout[125] = ip[0]^ip[1]^ip[2]^ip[3]^ip[11]^ip[12]^ip[17]^ip[21]^ip[23]^ip[27]^ip[28],
                 datout[126] = ip[0]^ip[1]^ip[2]^ip[6]^ip[9]^ip[10]^ip[11]^ip[16]^ip[18]^ip[22]^ip[27]^ip[31],
                 datout[127] = ip[0]^ip[1]^ip[5]^ip[6]^ip[8]^ip[10]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[30]^ip[31],
                 datout[128] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[129] = ip[3]^ip[4]^ip[5]^ip[9]^ip[13]^ip[15]^ip[16]^ip[17]^ip[20]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[130] = ip[2]^ip[3]^ip[4]^ip[8]^ip[12]^ip[14]^ip[15]^ip[16]^ip[19]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[131] = ip[1]^ip[2]^ip[3]^ip[7]^ip[11]^ip[13]^ip[14]^ip[15]^ip[18]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[132] = ip[0]^ip[1]^ip[2]^ip[6]^ip[10]^ip[12]^ip[13]^ip[14]^ip[17]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[133] = ip[0]^ip[1]^ip[5]^ip[6]^ip[11]^ip[12]^ip[13]^ip[16]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[134] = ip[0]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[24]^ip[30]^ip[31],
                 datout[135] = ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[16]^ip[17]^ip[22]^ip[23]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[136] = ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[13]^ip[15]^ip[16]^ip[21]^ip[22]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[137] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[12]^ip[14]^ip[15]^ip[20]^ip[21]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[138] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[11]^ip[13]^ip[14]^ip[19]^ip[20]^ip[23]^ip[26]^ip[27]^ip[28],
                 datout[139] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[31],
                 datout[140] = ip[0]^ip[1]^ip[3]^ip[8]^ip[11]^ip[12]^ip[19]^ip[20]^ip[21]^ip[24]^ip[30]^ip[31],
                 datout[141] = ip[0]^ip[2]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[19]^ip[23]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[142] = ip[1]^ip[5]^ip[8]^ip[10]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[143] = ip[0]^ip[4]^ip[7]^ip[9]^ip[19]^ip[21]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[144] = ip[3]^ip[8]^ip[9]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[145] = ip[2]^ip[7]^ip[8]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[146] = ip[1]^ip[6]^ip[7]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[147] = ip[0]^ip[5]^ip[6]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[148] = ip[4]^ip[5]^ip[6]^ip[9]^ip[18]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[149] = ip[3]^ip[4]^ip[5]^ip[8]^ip[17]^ip[18]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[150] = ip[2]^ip[3]^ip[4]^ip[7]^ip[16]^ip[17]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[29],
                 datout[151] = ip[1]^ip[2]^ip[3]^ip[6]^ip[15]^ip[16]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28],
                 datout[152] = ip[0]^ip[1]^ip[2]^ip[5]^ip[14]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27],
                 datout[153] = ip[0]^ip[1]^ip[4]^ip[6]^ip[9]^ip[13]^ip[14]^ip[19]^ip[21]^ip[22]^ip[31],
                 datout[154] = ip[0]^ip[3]^ip[5]^ip[6]^ip[8]^ip[9]^ip[12]^ip[13]^ip[21]^ip[26]^ip[30]^ip[31],
                 datout[155] = ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[18]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[156] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[17]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[157] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[16]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[158] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[15]^ip[18]^ip[20]^ip[22]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[159] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[14]^ip[17]^ip[19]^ip[21]^ip[22]^ip[26]^ip[27]^ip[30],
                 datout[160] = ip[0]^ip[1]^ip[2]^ip[3]^ip[9]^ip[13]^ip[16]^ip[21]^ip[25]^ip[29]^ip[31],
                 datout[161] = ip[0]^ip[1]^ip[2]^ip[6]^ip[8]^ip[9]^ip[12]^ip[15]^ip[18]^ip[24]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[162] = ip[0]^ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[14]^ip[17]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[163] = ip[0]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[164] = ip[3]^ip[4]^ip[7]^ip[8]^ip[12]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[165] = ip[2]^ip[3]^ip[6]^ip[7]^ip[11]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[166] = ip[1]^ip[2]^ip[5]^ip[6]^ip[10]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[167] = ip[0]^ip[1]^ip[4]^ip[5]^ip[9]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[168] = ip[0]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[169] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[30]^ip[31],
                 datout[170] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[29]^ip[30],
                 datout[171] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[28]^ip[29],
                 datout[172] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[21]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[173] = ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[174] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[24]^ip[26]^ip[29]^ip[30],
                 datout[175] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[14]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[176] = ip[0]^ip[1]^ip[4]^ip[5]^ip[7]^ip[10]^ip[13]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[177] = ip[0]^ip[3]^ip[4]^ip[12]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[178] = ip[2]^ip[3]^ip[6]^ip[9]^ip[11]^ip[15]^ip[16]^ip[19]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[179] = ip[1]^ip[2]^ip[5]^ip[8]^ip[10]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[180] = ip[0]^ip[1]^ip[4]^ip[7]^ip[9]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[181] = ip[0]^ip[3]^ip[8]^ip[9]^ip[12]^ip[13]^ip[16]^ip[18]^ip[19]^ip[21]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[182] = ip[2]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[15]^ip[17]^ip[24]^ip[27]^ip[30]^ip[31],
                 datout[183] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[14]^ip[16]^ip[23]^ip[26]^ip[29]^ip[30],
                 datout[184] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[13]^ip[15]^ip[22]^ip[25]^ip[28]^ip[29],
                 datout[185] = ip[3]^ip[4]^ip[5]^ip[8]^ip[12]^ip[14]^ip[18]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[186] = ip[2]^ip[3]^ip[4]^ip[7]^ip[11]^ip[13]^ip[17]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[30],
                 datout[187] = ip[1]^ip[2]^ip[3]^ip[6]^ip[10]^ip[12]^ip[16]^ip[18]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[29],
                 datout[188] = ip[0]^ip[1]^ip[2]^ip[5]^ip[9]^ip[11]^ip[15]^ip[17]^ip[18]^ip[21]^ip[23]^ip[24]^ip[25]^ip[28],
                 datout[189] = ip[0]^ip[1]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[14]^ip[16]^ip[17]^ip[18]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[31],
                 datout[190] = ip[0]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[30]^ip[31],
                 datout[191] = ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[192] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[193] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[194] = ip[1]^ip[2]^ip[4]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[195] = ip[0]^ip[1]^ip[3]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[26]^ip[27]^ip[30],
                 datout[196] = ip[0]^ip[2]^ip[6]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[25]^ip[29]^ip[31],
                 datout[197] = ip[1]^ip[5]^ip[6]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[19]^ip[24]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[198] = ip[0]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[18]^ip[23]^ip[25]^ip[27]^ip[29]^ip[30],
                 datout[199] = ip[3]^ip[4]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[17]^ip[18]^ip[20]^ip[22]^ip[24]^ip[28]^ip[29]^ip[31],
                 datout[200] = ip[2]^ip[3]^ip[5]^ip[7]^ip[9]^ip[10]^ip[13]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[27]^ip[28]^ip[30],
                 datout[201] = ip[1]^ip[2]^ip[4]^ip[6]^ip[8]^ip[9]^ip[12]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[26]^ip[27]^ip[29],
                 datout[202] = ip[0]^ip[1]^ip[3]^ip[5]^ip[7]^ip[8]^ip[11]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[25]^ip[26]^ip[28],
                 datout[203] = ip[0]^ip[2]^ip[4]^ip[7]^ip[9]^ip[10]^ip[13]^ip[14]^ip[16]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[204] = ip[1]^ip[3]^ip[8]^ip[12]^ip[13]^ip[15]^ip[18]^ip[20]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[205] = ip[0]^ip[2]^ip[7]^ip[11]^ip[12]^ip[14]^ip[17]^ip[19]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30],
                 datout[206] = ip[1]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[207] = ip[0]^ip[8]^ip[9]^ip[10]^ip[12]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[208] = ip[6]^ip[7]^ip[8]^ip[11]^ip[14]^ip[19]^ip[21]^ip[24]^ip[27]^ip[29]^ip[31],
                 datout[209] = ip[5]^ip[6]^ip[7]^ip[10]^ip[13]^ip[18]^ip[20]^ip[23]^ip[26]^ip[28]^ip[30],
                 datout[210] = ip[4]^ip[5]^ip[6]^ip[9]^ip[12]^ip[17]^ip[19]^ip[22]^ip[25]^ip[27]^ip[29],
                 datout[211] = ip[3]^ip[4]^ip[5]^ip[8]^ip[11]^ip[16]^ip[18]^ip[21]^ip[24]^ip[26]^ip[28],
                 datout[212] = ip[2]^ip[3]^ip[4]^ip[7]^ip[10]^ip[15]^ip[17]^ip[20]^ip[23]^ip[25]^ip[27],
                 datout[213] = ip[1]^ip[2]^ip[3]^ip[6]^ip[9]^ip[14]^ip[16]^ip[19]^ip[22]^ip[24]^ip[26],
                 datout[214] = ip[0]^ip[1]^ip[2]^ip[5]^ip[8]^ip[13]^ip[15]^ip[18]^ip[21]^ip[23]^ip[25],
                 datout[215] = ip[0]^ip[1]^ip[4]^ip[6]^ip[7]^ip[9]^ip[12]^ip[14]^ip[17]^ip[18]^ip[22]^ip[24]^ip[26]^ip[31],
                 datout[216] = ip[0]^ip[3]^ip[5]^ip[8]^ip[9]^ip[11]^ip[13]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[217] = ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[218] = ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[219] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[220] = ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[221] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[30],
                 datout[222] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[25]^ip[29]^ip[31],
                 datout[223] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[24]^ip[28]^ip[30],
                 datout[224] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[23]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[225] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[226] = ip[1]^ip[2]^ip[4]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[227] = ip[0]^ip[1]^ip[3]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[228] = ip[0]^ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[17]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[229] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[230] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[231] = ip[3]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[232] = ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[30],
                 datout[233] = ip[1]^ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[26]^ip[27]^ip[29],
                 datout[234] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[11]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28],
                 datout[235] = ip[0]^ip[1]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[236] = ip[0]^ip[3]^ip[4]^ip[8]^ip[12]^ip[14]^ip[15]^ip[16]^ip[19]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[237] = ip[2]^ip[3]^ip[6]^ip[7]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[238] = ip[1]^ip[2]^ip[5]^ip[6]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[239] = ip[0]^ip[1]^ip[4]^ip[5]^ip[7]^ip[9]^ip[11]^ip[12]^ip[13]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[240] = ip[0]^ip[3]^ip[4]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[241] = ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[16]^ip[17]^ip[22]^ip[27]^ip[30]^ip[31],
                 datout[242] = ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[15]^ip[16]^ip[21]^ip[26]^ip[29]^ip[30],
                 datout[243] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[14]^ip[15]^ip[20]^ip[25]^ip[28]^ip[29],
                 datout[244] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[13]^ip[14]^ip[18]^ip[19]^ip[20]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[245] = ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[17]^ip[19]^ip[20]^ip[23]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[246] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[16]^ip[18]^ip[19]^ip[22]^ip[24]^ip[26]^ip[29]^ip[30],
                 datout[247] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[15]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29],
                 datout[248] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[10]^ip[14]^ip[16]^ip[17]^ip[18]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[249] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[250] = ip[0]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[24]^ip[29]^ip[30]^ip[31],
                 datout[251] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[252] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[253] = ip[0]^ip[2]^ip[3]^ip[4]^ip[7]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[19]^ip[20]^ip[21]^ip[24]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[254] = ip[1]^ip[2]^ip[3]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[19]^ip[23]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[255] = ip[0]^ip[1]^ip[2]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[18]^ip[22]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[256] = ip[0]^ip[1]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[17]^ip[18]^ip[20]^ip[21]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[257] = ip[0]^ip[5]^ip[7]^ip[10]^ip[11]^ip[16]^ip[17]^ip[18]^ip[19]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[258] = ip[4]^ip[10]^ip[15]^ip[16]^ip[17]^ip[20]^ip[23]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[259] = ip[3]^ip[9]^ip[14]^ip[15]^ip[16]^ip[19]^ip[22]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[260] = ip[2]^ip[8]^ip[13]^ip[14]^ip[15]^ip[18]^ip[21]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[261] = ip[1]^ip[7]^ip[12]^ip[13]^ip[14]^ip[17]^ip[20]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28],
                 datout[262] = ip[0]^ip[6]^ip[11]^ip[12]^ip[13]^ip[16]^ip[19]^ip[21]^ip[23]^ip[25]^ip[26]^ip[27],
                 datout[263] = ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[22]^ip[24]^ip[25]^ip[31],
                 datout[264] = ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[21]^ip[23]^ip[24]^ip[30],
                 datout[265] = ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[20]^ip[22]^ip[23]^ip[29],
                 datout[266] = ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[19]^ip[21]^ip[22]^ip[28],
                 datout[267] = ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[11]^ip[18]^ip[20]^ip[21]^ip[27],
                 datout[268] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[17]^ip[19]^ip[20]^ip[26],
                 datout[269] = ip[0]^ip[3]^ip[4]^ip[5]^ip[16]^ip[19]^ip[20]^ip[25]^ip[26]^ip[31],
                 datout[270] = ip[2]^ip[3]^ip[4]^ip[6]^ip[9]^ip[15]^ip[19]^ip[20]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[271] = ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[14]^ip[18]^ip[19]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30],
                 datout[272] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[13]^ip[17]^ip[18]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29],
                 datout[273] = ip[0]^ip[1]^ip[3]^ip[9]^ip[12]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[274] = ip[0]^ip[2]^ip[6]^ip[8]^ip[9]^ip[11]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[275] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[16]^ip[17]^ip[21]^ip[24]^ip[29]^ip[30]^ip[31],
                 datout[276] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[13]^ip[14]^ip[15]^ip[16]^ip[20]^ip[23]^ip[28]^ip[29]^ip[30],
                 datout[277] = ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[278] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[279] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[17]^ip[18]^ip[20]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[280] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[16]^ip[17]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[281] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[15]^ip[16]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[282] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[283] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[284] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[11]^ip[12]^ip[13]^ip[16]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[285] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[286] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[16]^ip[17]^ip[21]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[287] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[13]^ip[15]^ip[16]^ip[18]^ip[22]^ip[24]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[288] = ip[0]^ip[3]^ip[4]^ip[5]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[289] = ip[2]^ip[3]^ip[4]^ip[6]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[290] = ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[291] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[292] = ip[0]^ip[1]^ip[3]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[293] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[27]^ip[30]^ip[31],
                 datout[294] = ip[1]^ip[5]^ip[7]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[29]^ip[30]^ip[31],
                 datout[295] = ip[0]^ip[4]^ip[6]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[28]^ip[29]^ip[30],
                 datout[296] = ip[3]^ip[5]^ip[6]^ip[10]^ip[11]^ip[12]^ip[14]^ip[17]^ip[19]^ip[21]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[297] = ip[2]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[18]^ip[20]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[298] = ip[1]^ip[3]^ip[4]^ip[8]^ip[9]^ip[10]^ip[12]^ip[15]^ip[17]^ip[19]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[299] = ip[0]^ip[2]^ip[3]^ip[7]^ip[8]^ip[9]^ip[11]^ip[14]^ip[16]^ip[18]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[300] = ip[1]^ip[2]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[301] = ip[0]^ip[1]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[302] = ip[0]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[303] = ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[304] = ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30],
                 datout[305] = ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29],
                 datout[306] = ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28],
                 datout[307] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27],
                 datout[308] = ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[13]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[25]^ip[31],
                 datout[309] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[12]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[24]^ip[30],
                 datout[310] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[11]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[23]^ip[29],
                 datout[311] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[13]^ip[14]^ip[16]^ip[22]^ip[26]^ip[28]^ip[31],
                 datout[312] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[12]^ip[13]^ip[15]^ip[18]^ip[20]^ip[21]^ip[25]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[313] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[17]^ip[18]^ip[19]^ip[24]^ip[25]^ip[29]^ip[30]^ip[31],
                 datout[314] = ip[0]^ip[1]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[17]^ip[20]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[315] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^
                         ip[31],
                 datout[316] = ip[1]^ip[3]^ip[5]^ip[7]^ip[11]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[317] = ip[0]^ip[2]^ip[4]^ip[6]^ip[10]^ip[13]^ip[14]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[318] = ip[1]^ip[3]^ip[5]^ip[6]^ip[12]^ip[13]^ip[15]^ip[17]^ip[19]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[319] = ip[0]^ip[2]^ip[4]^ip[5]^ip[11]^ip[12]^ip[14]^ip[16]^ip[18]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[320] = ip[1]^ip[3]^ip[4]^ip[6]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[321] = ip[0]^ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[20]^ip[22]^ip[24]^ip[26]^ip[28]^ip[30],
                 datout[322] = ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[323] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 datout[324] = ip[0]^ip[2]^ip[4]^ip[5]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[325] = ip[1]^ip[3]^ip[4]^ip[6]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[326] = ip[0]^ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[327] = ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[17]^ip[18]^ip[21]^ip[22]^ip[23]^ip[28]^ip[29]^ip[31],
                 datout[328] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[16]^ip[17]^ip[20]^ip[21]^ip[22]^ip[27]^ip[28]^ip[30],
                 datout[329] = ip[0]^ip[2]^ip[4]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[15]^ip[16]^ip[18]^ip[19]^ip[21]^ip[27]^ip[29]^ip[31],
                 datout[330] = ip[1]^ip[3]^ip[4]^ip[7]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[17]^ip[28]^ip[30]^ip[31],
                 datout[331] = ip[0]^ip[2]^ip[3]^ip[6]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[16]^ip[27]^ip[29]^ip[30],
                 datout[332] = ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[12]^ip[13]^ip[15]^ip[18]^ip[20]^ip[28]^ip[29]^ip[31],
                 datout[333] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[11]^ip[12]^ip[14]^ip[17]^ip[19]^ip[27]^ip[28]^ip[30],
                 datout[334] = ip[0]^ip[3]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[20]^ip[27]^ip[29]^ip[31],
                 datout[335] = ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[10]^ip[12]^ip[15]^ip[18]^ip[19]^ip[20]^ip[28]^ip[30]^ip[31],
                 datout[336] = ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[9]^ip[11]^ip[14]^ip[17]^ip[18]^ip[19]^ip[27]^ip[29]^ip[30],
                 datout[337] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[8]^ip[10]^ip[13]^ip[16]^ip[17]^ip[18]^ip[26]^ip[28]^ip[29],
                 datout[338] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[12]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[25]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[339] = ip[0]^ip[2]^ip[4]^ip[5]^ip[9]^ip[11]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[24]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[340] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[23]^ip[24]^ip[29]^ip[30]^ip[31],
                 datout[341] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[28]^ip[29]^ip[30],
                 datout[342] = ip[1]^ip[2]^ip[4]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[343] = ip[0]^ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[19]^ip[20]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[344] = ip[0]^ip[2]^ip[5]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[19]^ip[24]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[345] = ip[1]^ip[4]^ip[10]^ip[11]^ip[12]^ip[14]^ip[20]^ip[23]^ip[24]^ip[28]^ip[30]^ip[31],
                 datout[346] = ip[0]^ip[3]^ip[9]^ip[10]^ip[11]^ip[13]^ip[19]^ip[22]^ip[23]^ip[27]^ip[29]^ip[30],
                 datout[347] = ip[2]^ip[6]^ip[8]^ip[10]^ip[12]^ip[20]^ip[21]^ip[22]^ip[28]^ip[29]^ip[31],
                 datout[348] = ip[1]^ip[5]^ip[7]^ip[9]^ip[11]^ip[19]^ip[20]^ip[21]^ip[27]^ip[28]^ip[30],
                 datout[349] = ip[0]^ip[4]^ip[6]^ip[8]^ip[10]^ip[18]^ip[19]^ip[20]^ip[26]^ip[27]^ip[29],
                 datout[350] = ip[3]^ip[5]^ip[6]^ip[7]^ip[17]^ip[19]^ip[20]^ip[25]^ip[28]^ip[31],
                 datout[351] = ip[2]^ip[4]^ip[5]^ip[6]^ip[16]^ip[18]^ip[19]^ip[24]^ip[27]^ip[30],
                 datout[352] = ip[1]^ip[3]^ip[4]^ip[5]^ip[15]^ip[17]^ip[18]^ip[23]^ip[26]^ip[29],
                 datout[353] = ip[0]^ip[2]^ip[3]^ip[4]^ip[14]^ip[16]^ip[17]^ip[22]^ip[25]^ip[28],
                 datout[354] = ip[1]^ip[2]^ip[3]^ip[6]^ip[9]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[31],
                 datout[355] = ip[0]^ip[1]^ip[2]^ip[5]^ip[8]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[30],
                 datout[356] = ip[0]^ip[1]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[357] = ip[0]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[358] = ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[14]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[359] = ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[13]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[360] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[12]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[361] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[11]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[31],
                 datout[362] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[10]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[30],
                 datout[363] = ip[1]^ip[2]^ip[3]^ip[4]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[29]^ip[31],
                 datout[364] = ip[0]^ip[1]^ip[2]^ip[3]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[24]^ip[28]^ip[30],
                 datout[365] = ip[0]^ip[1]^ip[2]^ip[6]^ip[9]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[23]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[366] = ip[0]^ip[1]^ip[5]^ip[6]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[367] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[29]^
                         ip[30]^ip[31],
                 datout[368] = ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[369] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[370] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[21]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[371] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[20]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[372] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[13]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[373] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[12]^ip[14]^ip[17]^ip[19]^ip[23]^ip[24]^ip[30]^ip[31],
                 datout[374] = ip[1]^ip[2]^ip[4]^ip[11]^ip[13]^ip[16]^ip[20]^ip[22]^ip[23]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[375] = ip[0]^ip[1]^ip[3]^ip[10]^ip[12]^ip[15]^ip[19]^ip[21]^ip[22]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[376] = ip[0]^ip[2]^ip[6]^ip[11]^ip[14]^ip[21]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[377] = ip[1]^ip[5]^ip[6]^ip[9]^ip[10]^ip[13]^ip[18]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[378] = ip[0]^ip[4]^ip[5]^ip[8]^ip[9]^ip[12]^ip[17]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[379] = ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[16]^ip[18]^ip[20]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[380] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[15]^ip[17]^ip[19]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28]^ip[30],
                 datout[381] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[29],
                 datout[382] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28],
                 datout[383] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[384] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[385] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[18]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30],
                 datout[386] = ip[0]^ip[1]^ip[2]^ip[3]^ip[7]^ip[11]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[387] = ip[0]^ip[1]^ip[2]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[388] = ip[0]^ip[1]^ip[6]^ip[8]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[21]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[389] = ip[0]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[18]^ip[23]^ip[24]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[390] = ip[4]^ip[5]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[391] = ip[3]^ip[4]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[392] = ip[2]^ip[3]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[393] = ip[1]^ip[2]^ip[5]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[394] = ip[0]^ip[1]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27],
                 datout[395] = ip[0]^ip[3]^ip[5]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[31],
                 datout[396] = ip[2]^ip[4]^ip[6]^ip[7]^ip[11]^ip[12]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[30]^ip[31],
                 datout[397] = ip[1]^ip[3]^ip[5]^ip[6]^ip[10]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[29]^ip[30],
                 datout[398] = ip[0]^ip[2]^ip[4]^ip[5]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[28]^ip[29],
                 datout[399] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[11]^ip[13]^ip[15]^ip[16]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[400] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[12]^ip[14]^ip[15]^ip[18]^ip[20]^ip[22]^ip[25]^ip[26]^ip[27]^ip[30],
                 datout[401] = ip[1]^ip[2]^ip[4]^ip[11]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[29]^ip[31],
                 datout[402] = ip[0]^ip[1]^ip[3]^ip[10]^ip[12]^ip[13]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[23]^ip[24]^ip[28]^ip[30],
                 datout[403] = ip[0]^ip[2]^ip[6]^ip[11]^ip[12]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[23]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[404] = ip[1]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[405] = ip[0]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[406] = ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[23]^ip[28]^ip[29]^ip[31],
                 datout[407] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[11]^ip[12]^ip[13]^ip[16]^ip[18]^ip[22]^ip[27]^ip[28]^ip[30],
                 datout[408] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[10]^ip[11]^ip[12]^ip[15]^ip[17]^ip[21]^ip[26]^ip[27]^ip[29],
                 datout[409] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[14]^ip[16]^ip[20]^ip[25]^ip[26]^ip[28],
                 datout[410] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[10]^ip[13]^ip[15]^ip[18]^ip[19]^ip[20]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[411] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[12]^ip[14]^ip[17]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[412] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[11]^ip[13]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30],
                 datout[413] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[12]^ip[15]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[414] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[11]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[415] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[13]^ip[15]^ip[17]^ip[21]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[416] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[12]^ip[14]^ip[16]^ip[20]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[417] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^
                         ip[28]^ip[29]^ip[31],
                 datout[418] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^
                         ip[30]^ip[31],
                 datout[419] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[11]^ip[13]^ip[16]^ip[19]^ip[21]^ip[23]^ip[24]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[420] = ip[0]^ip[1]^ip[2]^ip[3]^ip[7]^ip[9]^ip[10]^ip[12]^ip[15]^ip[22]^ip[23]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[421] = ip[0]^ip[1]^ip[2]^ip[8]^ip[11]^ip[14]^ip[18]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[422] = ip[0]^ip[1]^ip[6]^ip[7]^ip[9]^ip[10]^ip[13]^ip[17]^ip[18]^ip[19]^ip[21]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[423] = ip[0]^ip[5]^ip[8]^ip[12]^ip[16]^ip[17]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[424] = ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[15]^ip[16]^ip[18]^ip[20]^ip[23]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[425] = ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[14]^ip[15]^ip[17]^ip[19]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[426] = ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[13]^ip[14]^ip[16]^ip[18]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[427] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[12]^ip[13]^ip[15]^ip[17]^ip[20]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[428] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[11]^ip[12]^ip[14]^ip[16]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27],
                 datout[429] = ip[1]^ip[2]^ip[4]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[31],
                 datout[430] = ip[0]^ip[1]^ip[3]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[30],
                 datout[431] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[11]^ip[13]^ip[21]^ip[22]^ip[23]^ip[26]^ip[29]^ip[31],
                 datout[432] = ip[1]^ip[5]^ip[7]^ip[9]^ip[10]^ip[12]^ip[18]^ip[21]^ip[22]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[433] = ip[0]^ip[4]^ip[6]^ip[8]^ip[9]^ip[11]^ip[17]^ip[20]^ip[21]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30],
                 datout[434] = ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[16]^ip[18]^ip[19]^ip[23]^ip[24]^ip[28]^ip[29]^ip[31],
                 datout[435] = ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[15]^ip[17]^ip[18]^ip[22]^ip[23]^ip[27]^ip[28]^ip[30],
                 datout[436] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[14]^ip[16]^ip[17]^ip[21]^ip[22]^ip[26]^ip[27]^ip[29],
                 datout[437] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[13]^ip[15]^ip[16]^ip[20]^ip[21]^ip[25]^ip[26]^ip[28],
                 datout[438] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[9]^ip[12]^ip[14]^ip[15]^ip[18]^ip[19]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[439] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[8]^ip[11]^ip[13]^ip[14]^ip[17]^ip[18]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[440] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[441] = ip[0]^ip[1]^ip[2]^ip[5]^ip[8]^ip[11]^ip[12]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^
                         ip[30]^ip[31],
                 datout[442] = ip[0]^ip[1]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^
                         ip[30]^ip[31],
                 datout[443] = ip[0]^ip[3]^ip[5]^ip[8]^ip[10]^ip[13]^ip[14]^ip[15]^ip[16]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[444] = ip[2]^ip[4]^ip[6]^ip[7]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[445] = ip[1]^ip[3]^ip[5]^ip[6]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[446] = ip[0]^ip[2]^ip[4]^ip[5]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[447] = ip[1]^ip[3]^ip[4]^ip[6]^ip[10]^ip[11]^ip[12]^ip[15]^ip[19]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[448] = ip[0]^ip[2]^ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[14]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[30],
                 datout[449] = ip[1]^ip[2]^ip[4]^ip[6]^ip[8]^ip[10]^ip[13]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[29]^ip[31],
                 datout[450] = ip[0]^ip[1]^ip[3]^ip[5]^ip[7]^ip[9]^ip[12]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[28]^ip[30],
                 datout[451] = ip[0]^ip[2]^ip[4]^ip[8]^ip[9]^ip[11]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[452] = ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[16]^ip[22]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[453] = ip[0]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[13]^ip[14]^ip[15]^ip[21]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[454] = ip[1]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[18]^ip[23]^ip[28]^ip[29]^ip[31],
                 datout[455] = ip[0]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[17]^ip[22]^ip[27]^ip[28]^ip[30],
                 datout[456] = ip[2]^ip[3]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[16]^ip[18]^ip[20]^ip[21]^ip[27]^ip[29]^ip[31],
                 datout[457] = ip[1]^ip[2]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[15]^ip[17]^ip[19]^ip[20]^ip[26]^ip[28]^ip[30],
                 datout[458] = ip[0]^ip[1]^ip[3]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[16]^ip[18]^ip[19]^ip[25]^ip[27]^ip[29],
                 datout[459] = ip[0]^ip[2]^ip[4]^ip[7]^ip[8]^ip[13]^ip[15]^ip[17]^ip[20]^ip[24]^ip[28]^ip[31],
                 datout[460] = ip[1]^ip[3]^ip[7]^ip[9]^ip[12]^ip[14]^ip[16]^ip[18]^ip[19]^ip[20]^ip[23]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[461] = ip[0]^ip[2]^ip[6]^ip[8]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[22]^ip[25]^ip[26]^ip[29]^ip[30],
                 datout[462] = ip[1]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[463] = ip[0]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[464] = ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[27]^ip[29]^ip[31],
                 datout[465] = ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[30],
                 datout[466] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[25]^ip[27]^ip[29],
                 datout[467] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[24]^ip[26]^ip[28],
                 datout[468] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[15]^ip[16]^ip[19]^ip[23]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[469] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[14]^ip[15]^ip[20]^ip[22]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[470] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[13]^ip[14]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[471] = ip[0]^ip[1]^ip[2]^ip[4]^ip[9]^ip[12]^ip[13]^ip[17]^ip[19]^ip[22]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[472] = ip[0]^ip[1]^ip[3]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[16]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[473] = ip[0]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[15]^ip[18]^ip[19]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[474] = ip[1]^ip[4]^ip[5]^ip[7]^ip[8]^ip[10]^ip[14]^ip[17]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[475] = ip[0]^ip[3]^ip[4]^ip[6]^ip[7]^ip[9]^ip[13]^ip[16]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[476] = ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[12]^ip[15]^ip[18]^ip[21]^ip[22]^ip[25]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[477] = ip[1]^ip[2]^ip[4]^ip[7]^ip[8]^ip[11]^ip[14]^ip[17]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[478] = ip[0]^ip[1]^ip[3]^ip[6]^ip[7]^ip[10]^ip[13]^ip[16]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[479] = ip[0]^ip[2]^ip[5]^ip[12]^ip[15]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[28]^ip[31],
                 datout[480] = ip[1]^ip[4]^ip[6]^ip[9]^ip[11]^ip[14]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[481] = ip[0]^ip[3]^ip[5]^ip[8]^ip[10]^ip[13]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[29]^ip[30],
                 datout[482] = ip[2]^ip[4]^ip[6]^ip[7]^ip[12]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[483] = ip[1]^ip[3]^ip[5]^ip[6]^ip[11]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[484] = ip[0]^ip[2]^ip[4]^ip[5]^ip[10]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29],
                 datout[485] = ip[1]^ip[3]^ip[4]^ip[6]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[31],
                 datout[486] = ip[0]^ip[2]^ip[3]^ip[5]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[30],
                 datout[487] = ip[1]^ip[2]^ip[4]^ip[6]^ip[9]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[23]^ip[29]^ip[31],
                 datout[488] = ip[0]^ip[1]^ip[3]^ip[5]^ip[8]^ip[11]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[22]^ip[28]^ip[30],
                 datout[489] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[490] = ip[1]^ip[3]^ip[5]^ip[8]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[491] = ip[0]^ip[2]^ip[4]^ip[7]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[492] = ip[1]^ip[3]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[23]^ip[28]^ip[29]^ip[31],
                 datout[493] = ip[0]^ip[2]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[22]^ip[27]^ip[28]^ip[30],
                 datout[494] = ip[1]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[20]^ip[21]^ip[27]^ip[29]^ip[31],
                 datout[495] = ip[0]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[19]^ip[20]^ip[26]^ip[28]^ip[30],
                 datout[496] = ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[19]^ip[20]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[497] = ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[18]^ip[19]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 datout[498] = ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[17]^ip[18]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29],
                 datout[499] = ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[16]^ip[17]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28],
                 datout[500] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[15]^ip[16]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27],
                 datout[501] = ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[24]^ip[31],
                 datout[502] = ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[23]^ip[30],
                 datout[503] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[22]^ip[29],
                 datout[504] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[15]^ip[19]^ip[20]^ip[21]^ip[26]^ip[28]^ip[31],
                 datout[505] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[19]^ip[25]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[506] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[13]^ip[20]^ip[24]^ip[25]^ip[29]^ip[30]^ip[31],
                 datout[507] = ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[12]^ip[18]^ip[19]^ip[20]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[508] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[11]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[509] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[10]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[510] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[511] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[9]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[22]^ip[24]^ip[27]^ip[30]^ip[31];


       end // gen_512_loop

  128: begin :gen_128_loop

         assign op[0] = ip[0]^ip[1]^ip[5]^ip[6]^ip[8]^ip[10]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[30]^ip[31],
                op[1] = ip[0]^ip[1]^ip[2]^ip[6]^ip[9]^ip[10]^ip[11]^ip[16]^ip[18]^ip[22]^ip[27]^ip[31],
                op[2] = ip[0]^ip[1]^ip[2]^ip[3]^ip[11]^ip[12]^ip[17]^ip[21]^ip[23]^ip[27]^ip[28],
                op[3] = ip[1]^ip[2]^ip[3]^ip[4]^ip[12]^ip[13]^ip[18]^ip[22]^ip[24]^ip[28]^ip[29],
                op[4] = ip[2]^ip[3]^ip[4]^ip[5]^ip[13]^ip[14]^ip[19]^ip[23]^ip[25]^ip[29]^ip[30],
                op[5] = ip[3]^ip[4]^ip[5]^ip[6]^ip[14]^ip[15]^ip[20]^ip[24]^ip[26]^ip[30]^ip[31],
                op[6] = ip[0]^ip[4]^ip[5]^ip[6]^ip[10]^ip[15]^ip[16]^ip[19]^ip[25]^ip[31],
                op[7] = ip[0]^ip[1]^ip[5]^ip[6]^ip[10]^ip[11]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[26]^ip[27],
                op[8] = ip[1]^ip[2]^ip[6]^ip[7]^ip[11]^ip[12]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[27]^ip[28],
                op[9] = ip[2]^ip[3]^ip[7]^ip[8]^ip[12]^ip[13]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[28]^ip[29],
                op[10] = ip[3]^ip[4]^ip[8]^ip[9]^ip[13]^ip[14]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30],
                op[11] = ip[4]^ip[5]^ip[9]^ip[10]^ip[14]^ip[15]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                op[12] = ip[0]^ip[5]^ip[6]^ip[7]^ip[11]^ip[15]^ip[16]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                op[13] = ip[0]^ip[1]^ip[6]^ip[8]^ip[10]^ip[12]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[28],
                op[14] = ip[1]^ip[2]^ip[7]^ip[9]^ip[11]^ip[13]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29],
                op[15] = ip[2]^ip[3]^ip[8]^ip[10]^ip[12]^ip[14]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30],
                op[16] = ip[3]^ip[4]^ip[9]^ip[11]^ip[13]^ip[15]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[31],
                op[17] = ip[0]^ip[4]^ip[5]^ip[7]^ip[12]^ip[14]^ip[16]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30],
                op[18] = ip[1]^ip[5]^ip[6]^ip[8]^ip[13]^ip[15]^ip[17]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                op[19] = ip[0]^ip[2]^ip[6]^ip[9]^ip[10]^ip[14]^ip[16]^ip[18]^ip[19]^ip[22]^ip[25]^ip[26]^ip[31],
                op[20] = ip[0]^ip[1]^ip[3]^ip[11]^ip[15]^ip[17]^ip[20]^ip[21]^ip[23]^ip[26],
                op[21] = ip[1]^ip[2]^ip[4]^ip[12]^ip[16]^ip[18]^ip[21]^ip[22]^ip[24]^ip[27],
                op[22] = ip[2]^ip[3]^ip[5]^ip[13]^ip[17]^ip[19]^ip[22]^ip[23]^ip[25]^ip[28],
                op[23] = ip[3]^ip[4]^ip[6]^ip[14]^ip[18]^ip[20]^ip[23]^ip[24]^ip[26]^ip[29],
                op[24] = ip[4]^ip[5]^ip[7]^ip[15]^ip[19]^ip[21]^ip[24]^ip[25]^ip[27]^ip[30],
                op[25] = ip[5]^ip[6]^ip[8]^ip[16]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28]^ip[31],
                op[26] = ip[0]^ip[6]^ip[9]^ip[10]^ip[17]^ip[19]^ip[23]^ip[26]^ip[29],
                op[27] = ip[1]^ip[7]^ip[10]^ip[11]^ip[18]^ip[20]^ip[24]^ip[27]^ip[30],
                op[28] = ip[2]^ip[8]^ip[11]^ip[12]^ip[19]^ip[21]^ip[25]^ip[28]^ip[31],
                op[29] = ip[0]^ip[3]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[29],
                op[30] = ip[1]^ip[4]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28]^ip[30],
                op[31] = ip[2]^ip[5]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29]^ip[31];

         assign datout[0] = ip[6]^ip[9]^ip[18]^ip[20]^ip[26]^ip[31],
                datout[1] = ip[5]^ip[8]^ip[17]^ip[19]^ip[25]^ip[30],
                datout[2] = ip[4]^ip[7]^ip[16]^ip[18]^ip[24]^ip[29],
                datout[3] = ip[3]^ip[6]^ip[15]^ip[17]^ip[23]^ip[28],
                datout[4] = ip[2]^ip[5]^ip[14]^ip[16]^ip[22]^ip[27],
                datout[5] = ip[1]^ip[4]^ip[13]^ip[15]^ip[21]^ip[26],
                datout[6] = ip[0]^ip[3]^ip[12]^ip[14]^ip[20]^ip[25],
                datout[7] = ip[2]^ip[6]^ip[9]^ip[11]^ip[13]^ip[18]^ip[19]^ip[20]^ip[24]^ip[26]^ip[31],
                datout[8] = ip[1]^ip[5]^ip[8]^ip[10]^ip[12]^ip[17]^ip[18]^ip[19]^ip[23]^ip[25]^ip[30],
                datout[9] = ip[0]^ip[4]^ip[7]^ip[9]^ip[11]^ip[16]^ip[17]^ip[18]^ip[22]^ip[24]^ip[29],
                datout[10] = ip[3]^ip[8]^ip[9]^ip[10]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[31],
                datout[11] = ip[2]^ip[7]^ip[8]^ip[9]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[30],
                datout[12] = ip[1]^ip[6]^ip[7]^ip[8]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[21]^ip[24]^ip[26]^ip[29],
                datout[13] = ip[0]^ip[5]^ip[6]^ip[7]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[23]^ip[25]^ip[28],
                datout[14] = ip[4]^ip[5]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[26]^ip[27]^ip[31],
                datout[15] = ip[3]^ip[4]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[25]^ip[26]^ip[30],
                datout[16] = ip[2]^ip[3]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[24]^ip[25]^ip[29],
                datout[17] = ip[1]^ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[24]^ip[28],
                datout[18] = ip[0]^ip[1]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[27],
                datout[19] = ip[0]^ip[4]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[31],
                datout[20] = ip[3]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[26]^ip[30]^ip[31],
                datout[21] = ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[25]^ip[29]^ip[30],
                datout[22] = ip[1]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[24]^ip[28]^ip[29],
                datout[23] = ip[0]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[18]^ip[23]^ip[27]^ip[28],
                datout[24] = ip[3]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[27]^ip[31],
                datout[25] = ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[26]^ip[30],
                datout[26] = ip[1]^ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[25]^ip[29],
                datout[27] = ip[0]^ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[24]^ip[28],
                datout[28] = ip[1]^ip[3]^ip[4]^ip[8]^ip[11]^ip[13]^ip[14]^ip[16]^ip[20]^ip[23]^ip[26]^ip[27]^ip[31],
                datout[29] = ip[0]^ip[2]^ip[3]^ip[7]^ip[10]^ip[12]^ip[13]^ip[15]^ip[19]^ip[22]^ip[25]^ip[26]^ip[30],
                datout[30] = ip[1]^ip[2]^ip[11]^ip[12]^ip[14]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                datout[31] = ip[0]^ip[1]^ip[10]^ip[11]^ip[13]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30],
                datout[32] = ip[0]^ip[6]^ip[10]^ip[12]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[31],
                datout[33] = ip[5]^ip[6]^ip[11]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[30]^ip[31],
                datout[34] = ip[4]^ip[5]^ip[10]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[29]^ip[30],
                datout[35] = ip[3]^ip[4]^ip[9]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[29],
                datout[36] = ip[2]^ip[3]^ip[8]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[28],
                datout[37] = ip[1]^ip[2]^ip[7]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[24]^ip[26]^ip[27],
                datout[38] = ip[0]^ip[1]^ip[6]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26],
                datout[39] = ip[0]^ip[5]^ip[6]^ip[9]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[31],
                datout[40] = ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                datout[41] = ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30],
                datout[42] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29],
                datout[43] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28],
                datout[44] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27],
                datout[45] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[19]^ip[21]^ip[25]^ip[31],
                datout[46] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[24]^ip[26]^ip[30]^ip[31],
                datout[47] = ip[1]^ip[2]^ip[4]^ip[10]^ip[12]^ip[13]^ip[14]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                datout[48] = ip[0]^ip[1]^ip[3]^ip[9]^ip[11]^ip[12]^ip[13]^ip[17]^ip[19]^ip[22]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                datout[49] = ip[0]^ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[16]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                datout[50] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[15]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                datout[51] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[14]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30],
                datout[52] = ip[3]^ip[4]^ip[5]^ip[8]^ip[13]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29]^ip[31],
                datout[53] = ip[2]^ip[3]^ip[4]^ip[7]^ip[12]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28]^ip[30],
                datout[54] = ip[1]^ip[2]^ip[3]^ip[6]^ip[11]^ip[14]^ip[15]^ip[16]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[29],
                datout[55] = ip[0]^ip[1]^ip[2]^ip[5]^ip[10]^ip[13]^ip[14]^ip[15]^ip[18]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28],
                datout[56] = ip[0]^ip[1]^ip[4]^ip[6]^ip[12]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                datout[57] = ip[0]^ip[3]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[13]^ip[16]^ip[17]^ip[19]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                datout[58] = ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[16]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                datout[59] = ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                datout[60] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29],
                datout[61] = ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[12]^ip[13]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[27]^ip[28]^ip[31],
                datout[62] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[11]^ip[12]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[26]^ip[27]^ip[30],
                datout[63] = ip[0]^ip[1]^ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[25]^ip[29]^ip[31],
                datout[64] = ip[0]^ip[2]^ip[4]^ip[6]^ip[8]^ip[10]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[24]^ip[26]^ip[28]^ip[30]^ip[31],
                datout[65] = ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[13]^ip[14]^ip[15]^ip[16]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                datout[66] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[12]^ip[13]^ip[14]^ip[15]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                datout[67] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                datout[68] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                datout[69] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[31],
                datout[70] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[30],
                datout[71] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                datout[72] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[16]^ip[21]^ip[22]^ip[24]^ip[25]^ip[28]^ip[30]^ip[31],
                datout[73] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[9]^ip[15]^ip[18]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                datout[74] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[14]^ip[17]^ip[18]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                datout[75] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[13]^ip[16]^ip[17]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30],
                datout[76] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[9]^ip[12]^ip[15]^ip[16]^ip[18]^ip[21]^ip[23]^ip[27]^ip[28]^ip[29]^ip[31],
                datout[77] = ip[0]^ip[1]^ip[3]^ip[8]^ip[9]^ip[11]^ip[14]^ip[15]^ip[17]^ip[18]^ip[22]^ip[27]^ip[28]^ip[30]^ip[31],
                datout[78] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[27]^ip[29]^ip[30]^ip[31],
                datout[79] = ip[1]^ip[5]^ip[7]^ip[8]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[28]^ip[29]^ip[30]^ip[31],
                datout[80] = ip[0]^ip[4]^ip[6]^ip[7]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[27]^ip[28]^ip[29]^ip[30],
                datout[81] = ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[27]^ip[28]^ip[29]^ip[31],
                datout[82] = ip[2]^ip[4]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[26]^ip[27]^ip[28]^ip[30],
                datout[83] = ip[1]^ip[3]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[25]^ip[26]^ip[27]^ip[29],
                datout[84] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[24]^ip[25]^ip[26]^ip[28],
                datout[85] = ip[1]^ip[5]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                datout[86] = ip[0]^ip[4]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                datout[87] = ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                datout[88] = ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30],
                datout[89] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[29],
                datout[90] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28],
                datout[91] = ip[1]^ip[2]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[31],
                datout[92] = ip[0]^ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[30],
                datout[93] = ip[0]^ip[2]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                datout[94] = ip[1]^ip[4]^ip[7]^ip[8]^ip[13]^ip[14]^ip[16]^ip[17]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                datout[95] = ip[0]^ip[3]^ip[6]^ip[7]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30],
                datout[96] = ip[2]^ip[5]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29]^ip[31],
                datout[97] = ip[1]^ip[4]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28]^ip[30],
                datout[98] = ip[0]^ip[3]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[29],
                datout[99] = ip[2]^ip[8]^ip[11]^ip[12]^ip[19]^ip[21]^ip[25]^ip[28]^ip[31],
                datout[100] = ip[1]^ip[7]^ip[10]^ip[11]^ip[18]^ip[20]^ip[24]^ip[27]^ip[30],
                datout[101] = ip[0]^ip[6]^ip[9]^ip[10]^ip[17]^ip[19]^ip[23]^ip[26]^ip[29],
                datout[102] = ip[5]^ip[6]^ip[8]^ip[16]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28]^ip[31],
                datout[103] = ip[4]^ip[5]^ip[7]^ip[15]^ip[19]^ip[21]^ip[24]^ip[25]^ip[27]^ip[30],
                datout[104] = ip[3]^ip[4]^ip[6]^ip[14]^ip[18]^ip[20]^ip[23]^ip[24]^ip[26]^ip[29],
                datout[105] = ip[2]^ip[3]^ip[5]^ip[13]^ip[17]^ip[19]^ip[22]^ip[23]^ip[25]^ip[28],
                datout[106] = ip[1]^ip[2]^ip[4]^ip[12]^ip[16]^ip[18]^ip[21]^ip[22]^ip[24]^ip[27],
                datout[107] = ip[0]^ip[1]^ip[3]^ip[11]^ip[15]^ip[17]^ip[20]^ip[21]^ip[23]^ip[26],
                datout[108] = ip[0]^ip[2]^ip[6]^ip[9]^ip[10]^ip[14]^ip[16]^ip[18]^ip[19]^ip[22]^ip[25]^ip[26]^ip[31],
                datout[109] = ip[1]^ip[5]^ip[6]^ip[8]^ip[13]^ip[15]^ip[17]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                datout[110] = ip[0]^ip[4]^ip[5]^ip[7]^ip[12]^ip[14]^ip[16]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30],
                datout[111] = ip[3]^ip[4]^ip[9]^ip[11]^ip[13]^ip[15]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[31],
                datout[112] = ip[2]^ip[3]^ip[8]^ip[10]^ip[12]^ip[14]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30],
                datout[113] = ip[1]^ip[2]^ip[7]^ip[9]^ip[11]^ip[13]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29],
                datout[114] = ip[0]^ip[1]^ip[6]^ip[8]^ip[10]^ip[12]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[28],
                datout[115] = ip[0]^ip[5]^ip[6]^ip[7]^ip[11]^ip[15]^ip[16]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                datout[116] = ip[4]^ip[5]^ip[9]^ip[10]^ip[14]^ip[15]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                datout[117] = ip[3]^ip[4]^ip[8]^ip[9]^ip[13]^ip[14]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30],
                datout[118] = ip[2]^ip[3]^ip[7]^ip[8]^ip[12]^ip[13]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[28]^ip[29],
                datout[119] = ip[1]^ip[2]^ip[6]^ip[7]^ip[11]^ip[12]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[27]^ip[28],
                datout[120] = ip[0]^ip[1]^ip[5]^ip[6]^ip[10]^ip[11]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[26]^ip[27],
                datout[121] = ip[0]^ip[4]^ip[5]^ip[6]^ip[10]^ip[15]^ip[16]^ip[19]^ip[25]^ip[31],
                datout[122] = ip[3]^ip[4]^ip[5]^ip[6]^ip[14]^ip[15]^ip[20]^ip[24]^ip[26]^ip[30]^ip[31],
                datout[123] = ip[2]^ip[3]^ip[4]^ip[5]^ip[13]^ip[14]^ip[19]^ip[23]^ip[25]^ip[29]^ip[30],
                datout[124] = ip[1]^ip[2]^ip[3]^ip[4]^ip[12]^ip[13]^ip[18]^ip[22]^ip[24]^ip[28]^ip[29],
                datout[125] = ip[0]^ip[1]^ip[2]^ip[3]^ip[11]^ip[12]^ip[17]^ip[21]^ip[23]^ip[27]^ip[28],
                datout[126] = ip[0]^ip[1]^ip[2]^ip[6]^ip[9]^ip[10]^ip[11]^ip[16]^ip[18]^ip[22]^ip[27]^ip[31],
                datout[127] = ip[0]^ip[1]^ip[5]^ip[6]^ip[8]^ip[10]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[30]^ip[31];

       end // gen_128_loop

       default: begin :gen_rtl_loop

                  reg [(BIT_COUNT-1):0] mdat;
                  reg [REMAINDER_SIZE:0] md, nCRC [0:(BIT_COUNT-1)];                       // temp vaiables used in CRC calculation

                  always @(ip) begin :crc_loop
                    integer i;
                    nCRC[0] = {ip,^(CRC_POLYNOMIAL & {ip,1'b0})};
                    for(i=1;i<BIT_COUNT;i=i+1) begin                     // Calculate remaining CRC for all other data bits in parallel
                      md = nCRC[i-1];
                      mdat[i-1] = md[0];
                      nCRC[i] = {md,^(CRC_POLYNOMIAL & {md[(REMAINDER_SIZE-1):0],1'b0})};
                    end
                    md = nCRC[(BIT_COUNT-1)];
                    mdat[(BIT_COUNT-1)] = md[0];
                  end

                  assign op = md;                          // The output polynomial is the very last entry in the array
                  assign datout  = mdat;

                end             // gen_rtl_loop

endcase

endgenerate

endmodule

module l_ethernet_40G_qsfp_d_0_pkt_gen_mon_syncer_level
#(
  parameter WIDTH       = 1,
  parameter RESET_VALUE = 1'b0
 )
(
  input  wire clk,
  input  wire reset,

  input  wire [WIDTH-1:0] datain,
  output wire [WIDTH-1:0] dataout
);

  (* ASYNC_REG = "TRUE" *) reg  [WIDTH-1:0] dataout_reg;
  reg  [WIDTH-1:0] meta_nxt;
  wire [WIDTH-1:0] dataout_nxt;

`ifdef SARANCE_RTL_DEBUG
// pragma translate_off

  integer i;
  integer seed;
  (* ASYNC_REG = "TRUE" *) reg  [WIDTH-1:0] meta;
  (* ASYNC_REG = "TRUE" *) reg  [WIDTH-1:0] meta2;
  reg  [WIDTH-1:0] meta_state;
  reg  [WIDTH-1:0] meta_state_nxt;
  reg  [WIDTH-1:0] last_datain;

  initial seed       = `SEED;
  initial meta_state = {WIDTH{RESET_VALUE}};

  always @*
    begin
      for (i=0; i < WIDTH; i = i + 1)
        begin
          if ( meta_state[i] !== 1'b1 &&
               last_datain[i] !== datain[i] &&
               $dist_uniform(seed,0,9999) < 5000 &&
               meta[i] !== datain[i] )
            begin
              meta_nxt[i]       = meta[i];
              meta_state_nxt[i] = 1'b1;
            end
          else
            begin
              meta_nxt[i]       = datain[i];
              meta_state_nxt[i] = 1'b0;
            end
        end // for

      last_datain = datain;
    end

  always @( posedge clk )
    begin
      meta_state <= meta_state_nxt;
    end


// pragma translate_on
`else
  (* ASYNC_REG = "TRUE" *) reg  [WIDTH-1:0] meta;
  (* ASYNC_REG = "TRUE" *) reg  [WIDTH-1:0] meta2;
  always @*
    begin
      meta_nxt = datain;
    end

`endif

  always @( posedge clk )
    begin
      if ( reset == 1'b1 )
        begin
          meta  <= {WIDTH{RESET_VALUE}};
          meta2 <= {WIDTH{RESET_VALUE}};
        end
      else
        begin
          meta  <= meta_nxt;
          meta2 <= meta;
        end
    end

  assign dataout_nxt = meta2;

  always @( posedge clk )
    begin
      if ( reset == 1'b1 )
        begin
          dataout_reg <= {WIDTH{RESET_VALUE}};
        end
      else
        begin
          dataout_reg <= dataout_nxt;
        end
    end

  assign dataout = dataout_reg;

`ifdef SARANCE_RTL_DEBUG
// pragma translate_off

// pragma translate_on
`endif

endmodule // syncer_level


