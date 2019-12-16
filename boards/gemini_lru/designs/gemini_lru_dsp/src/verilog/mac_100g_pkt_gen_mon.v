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

`timescale 1ps/1ps
(* DowngradeIPIdentifiedWarnings="yes" *)
////module lbus_if
module mac_100g_pkt_gen_mon
   #(
    parameter PKT_NUM      = 1000,    //// 1 to 65535 (Number of packets)
    parameter PKT_SIZE     = 522      //// 64 to 16383 (Each Packet Size)
   )
   (
    input                      gen_mon_clk,
    input                      usr_tx_reset,
    input                      usr_rx_reset,
    input                      sys_reset,
    input                      send_continuous_pkts,
    //// User Interface signals
    input                      lbus_tx_rx_restart_in,
    //// LBUS Tx Signals
    input                      tx_rdyout,
    output wire [128-1:0]      tx_datain0,
    output wire                tx_enain0,
    output wire                tx_sopin0,
    output wire                tx_eopin0,
    output wire                tx_errin0,
    output wire [4-1:0]        tx_mtyin0,
    output wire [128-1:0]      tx_datain1,
    output wire                tx_enain1,
    output wire                tx_sopin1,
    output wire                tx_eopin1,
    output wire                tx_errin1,
    output wire [4-1:0]        tx_mtyin1,
    output wire [128-1:0]      tx_datain2,
    output wire                tx_enain2,
    output wire                tx_sopin2,
    output wire                tx_eopin2,
    output wire                tx_errin2,
    output wire [4-1:0]        tx_mtyin2,
    output wire [128-1:0]      tx_datain3,
    output wire                tx_enain3,
    output wire                tx_sopin3,
    output wire                tx_eopin3,
    output wire                tx_errin3,
    output wire [4-1:0]        tx_mtyin3,
    input                      tx_ovfout,
    input                      tx_unfout,

    //// LBUS Rx Signals
    input       [128-1:0]      rx_dataout0,
    input                      rx_enaout0,
    input                      rx_sopout0,
    input                      rx_eopout0,
    input                      rx_errout0,
    input       [4-1:0]        rx_mtyout0,
    input       [128-1:0]      rx_dataout1,
    input                      rx_enaout1,
    input                      rx_sopout1,
    input                      rx_eopout1,
    input                      rx_errout1,
    input       [4-1:0]        rx_mtyout1,
    input       [128-1:0]      rx_dataout2,
    input                      rx_enaout2,
    input                      rx_sopout2,
    input                      rx_eopout2,
    input                      rx_errout2,
    input       [4-1:0]        rx_mtyout2,
    input       [128-1:0]      rx_dataout3,
    input                      rx_enaout3,
    input                      rx_sopout3,
    input                      rx_eopout3,
    input                      rx_errout3,
    input       [3:0]          rx_mtyout3,

    input                      stat_rx_aligned,
    output wire                ctl_tx_enable,

    output wire                ctl_tx_send_rfi,
    output wire                ctl_tx_send_lfi,

    output wire                ctl_rx_enable,
    output wire                ctl_rsfec_ieee_error_indication_mode,
    output wire                ctl_rx_rsfec_enable,
    output wire                ctl_rx_rsfec_enable_correction,
    output wire                ctl_rx_rsfec_enable_indication,
    output wire                ctl_tx_rsfec_enable,
    input  wire [3 :0]         gt_rxrecclkout,
    output wire                tx_done_led,
    output wire                tx_busy_led,

    output wire                rx_gt_locked_led,
    output wire                rx_aligned_led,
    output wire                rx_done_led,
    output wire                rx_data_fail_led,
    output wire                rx_busy_led
    );


mac_100g_pkt_gen
#(
.PKT_NUM                               (PKT_NUM),
.PKT_SIZE                              (PKT_SIZE)
) i_mac_100g_pkt_gen
(
.clk                                   (gen_mon_clk),
.reset                                 (usr_tx_reset),
.sys_reset                             (sys_reset),
.send_continuous_pkts                  (send_continuous_pkts),
.stat_rx_aligned                       (stat_rx_aligned),
.lbus_tx_rx_restart_in                 (lbus_tx_rx_restart_in),
.ctl_tx_enable                         (ctl_tx_enable),

.ctl_tx_send_rfi                       (ctl_tx_send_rfi),
.ctl_tx_send_lfi                       (ctl_tx_send_lfi),

.ctl_tx_rsfec_enable                   (ctl_tx_rsfec_enable),

.gt_rxrecclkout                        (gt_rxrecclkout),
.tx_done_led                           (tx_done_led),
.tx_busy_led                           (tx_busy_led),
.tx_rdyout                             (tx_rdyout),
.tx_datain0                            (tx_datain0),
.tx_enain0                             (tx_enain0),
.tx_sopin0                             (tx_sopin0),
.tx_eopin0                             (tx_eopin0),
.tx_errin0                             (tx_errin0),
.tx_mtyin0                             (tx_mtyin0),
.tx_datain1                            (tx_datain1),
.tx_enain1                             (tx_enain1),
.tx_sopin1                             (tx_sopin1),
.tx_eopin1                             (tx_eopin1),
.tx_errin1                             (tx_errin1),
.tx_mtyin1                             (tx_mtyin1),
.tx_datain2                            (tx_datain2),
.tx_enain2                             (tx_enain2),
.tx_sopin2                             (tx_sopin2),
.tx_eopin2                             (tx_eopin2),
.tx_errin2                             (tx_errin2),
.tx_mtyin2                             (tx_mtyin2),
.tx_datain3                            (tx_datain3),
.tx_enain3                             (tx_enain3),
.tx_sopin3                             (tx_sopin3),
.tx_eopin3                             (tx_eopin3),
.tx_errin3                             (tx_errin3),
.tx_mtyin3                             (tx_mtyin3),
.tx_ovfout                             (tx_ovfout),
.tx_unfout                             (tx_unfout)
);

mac_100g_pkt_mon
#(
.PKT_NUM                               (PKT_NUM)
) i_mac_100g_pkt_mon
(
.clk                                   (gen_mon_clk),
.reset                                 (usr_rx_reset),
.sys_reset                             (sys_reset),
.send_continuous_pkts                  (send_continuous_pkts),
.stat_rx_aligned                       (stat_rx_aligned),
.lbus_tx_rx_restart_in                 (lbus_tx_rx_restart_in),
.ctl_rx_enable                         (ctl_rx_enable),
.ctl_rsfec_ieee_error_indication_mode  (ctl_rsfec_ieee_error_indication_mode),
.ctl_rx_rsfec_enable                   (ctl_rx_rsfec_enable),
.ctl_rx_rsfec_enable_correction        (ctl_rx_rsfec_enable_correction),
.ctl_rx_rsfec_enable_indication        (ctl_rx_rsfec_enable_indication),

.rx_gt_locked_led                      (rx_gt_locked_led),
.rx_aligned_led                        (rx_aligned_led),
.rx_done_led                           (rx_done_led),
.rx_data_fail_led                      (rx_data_fail_led),
.rx_busy_led                           (rx_busy_led),





.rx_dataout0                           (rx_dataout0),
.rx_enaout0                            (rx_enaout0),
.rx_sopout0                            (rx_sopout0),
.rx_eopout0                            (rx_eopout0),
.rx_errout0                            (rx_errout0),
.rx_mtyout0                            (rx_mtyout0),
.rx_dataout1                           (rx_dataout1),
.rx_enaout1                            (rx_enaout1),
.rx_sopout1                            (rx_sopout1),
.rx_eopout1                            (rx_eopout1),
.rx_errout1                            (rx_errout1),
.rx_mtyout1                            (rx_mtyout1),
.rx_dataout2                           (rx_dataout2),
.rx_enaout2                            (rx_enaout2),
.rx_sopout2                            (rx_sopout2),
.rx_eopout2                            (rx_eopout2),
.rx_errout2                            (rx_errout2),
.rx_mtyout2                            (rx_mtyout2),
.rx_dataout3                           (rx_dataout3),
.rx_enaout3                            (rx_enaout3),
.rx_sopout3                            (rx_sopout3),
.rx_eopout3                            (rx_eopout3),
.rx_errout3                            (rx_errout3),
.rx_mtyout3                            (rx_mtyout3)
);


endmodule

