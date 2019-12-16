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

module cmac_usplus_100G_qsfp_a_0_user_if
   (
    input  wire            lbus_clk,
    input  wire            reset,
    input  wire            rx_gt_locked,
    input  wire            stat_rx_aligned,
    input                  rx_done,
    input                  rx_busy,
    output wire            rx_busy_led,

    output wire            sanity_init_done,
    output wire            pause_init_done,

    input                  s_axi_aclk,
    input                  s_axi_sreset,
    input                  s_axi_pm_tick
//    output  [31:0]         s_axi_awaddr,
//    output                 s_axi_awvalid,
//    
//    input                  s_axi_awready,
//    
//    output  [31:0]         s_axi_wdata,
//    output  [3:0]          s_axi_wstrb,
//    output                 s_axi_wvalid,
//    input                  s_axi_wready,
//    
//    input   [1:0]          s_axi_bresp,
//    input                  s_axi_bvalid,
//    output                 s_axi_bready,
//    
//    output  [31:0]         s_axi_araddr,
//    output                 s_axi_arvalid,
//    input                  s_axi_arready,
//    input   [31:0]         s_axi_rdata,
//    input   [1:0]          s_axi_rresp,
//    input                  s_axi_rvalid,
//    output                 s_axi_rready

    );

    //// axi_user_prestate
    parameter STATE_AXI_IDLE            = 0;
    parameter STATE_GT_LOCKED           = 1;
    parameter STATE_INIT_RX_ALIGNED     = 2;
    parameter STATE_WAIT_RX_ALIGNED     = 3;
    parameter STATE_AXI_RD_WR           = 4;
    parameter STATE_INIT_PKT_TRANSFER   = 5;
    parameter STATE_WAIT_SANITY_DONE    = 6;
    parameter STATE_TX_RX_PAUSE_INIT    = 7; 
    parameter STATE_TX_RX_PAUSE_DONE    = 8; 
    parameter STATE_TEST_WAIT           = 9;
    parameter STATE_READ_STATS          = 10;
    parameter STATE_READ_DONE           = 11;
    parameter STATE_TEST_DONE           = 12;
    parameter STATE_INVALID_AXI_RD_WR   = 13;

    //// axi_reg_map address
    parameter  ADDR_GT_RESET_REG                        =  32'h00000000;
    parameter  ADDR_RESET_REG                           =  32'h00000004;
    parameter  ADDR_MODE_REG                            =  32'h00000008;
    parameter  ADDR_CONFIG_TX_REG1                      =  32'h0000000C;
    parameter  ADDR_CONFIG_RX_REG1                      =  32'h00000014;
    parameter  ADDR_CONFIG_TX_BIP_OVERRIDE              =  32'h0000002C;
    parameter  ADDR_CONFIG_TX_FLOW_CTL_CONTROL_REG1     =  32'h00000030;
    parameter  ADDR_CONFIG_TX_FLOW_CTL_REFRESH_REG1     =  32'h00000034;
    parameter  ADDR_CONFIG_TX_FLOW_CTL_REFRESH_REG2     =  32'h00000038;
    parameter  ADDR_CONFIG_TX_FLOW_CTL_REFRESH_REG3     =  32'h0000003C;
    parameter  ADDR_CONFIG_TX_FLOW_CTL_REFRESH_REG4     =  32'h00000040;
    parameter  ADDR_CONFIG_TX_FLOW_CTL_REFRESH_REG5     =  32'h00000044;
    parameter  ADDR_CONFIG_TX_FLOW_CTL_QUANTA_REG1      =  32'h00000048;
    parameter  ADDR_CONFIG_TX_FLOW_CTL_QUANTA_REG2      =  32'h0000004C;
    parameter  ADDR_CONFIG_TX_FLOW_CTL_QUANTA_REG3      =  32'h00000050;
    parameter  ADDR_CONFIG_TX_FLOW_CTL_QUANTA_REG4      =  32'h00000054;
    parameter  ADDR_CONFIG_TX_FLOW_CTL_QUANTA_REG5      =  32'h00000058;
    parameter  ADDR_CONFIG_RX_FLOW_CTL_CONTROL_REG1     =  32'h00000084;
    parameter  ADDR_CONFIG_RX_FLOW_CTL_CONTROL_REG2     =  32'h00000088;

    parameter  ADDR_CORE_VERSION_REG                    =  32'h00000024;
    parameter  ADDR_STAT_TX_TOTAL_PACKETS_LSB           =  32'h00000500;
    parameter  ADDR_STAT_TX_TOTAL_PACKETS_MSB           =  32'h00000504;
    parameter  ADDR_STAT_TX_TOTAL_GOOD_PACKETS_LSB      =  32'h00000508;
    parameter  ADDR_STAT_TX_TOTAL_GOOD_PACKETS_MSB      =  32'h0000050C;
    parameter  ADDR_STAT_TX_TOTAL_BYTES_LSB             =  32'h00000510;
    parameter  ADDR_STAT_TX_TOTAL_BYTES_MSB             =  32'h00000514;
    parameter  ADDR_STAT_TX_TOTAL_GOOD_BYTES_LSB        =  32'h00000518;
    parameter  ADDR_STAT_TX_TOTAL_GOOD_BYTES_MSB        =  32'h0000051C;
    parameter  ADDR_STAT_TX_PACKET_64_BYTES_LSB         =  32'h00000520;
    parameter  ADDR_STAT_TX_PACKET_64_BYTES_MSB         =  32'h00000524;
    parameter  ADDR_STAT_TX_PACKET_256_511_BYTES_LSB    =  32'h00000538;
    parameter  ADDR_STAT_TX_PACKET_256_511_BYTES_MSB    =  32'h0000053C;
    parameter  ADDR_STAT_TX_PACKET_512_1023_BYTES_LSB   =  32'h00000540;
    parameter  ADDR_STAT_TX_PACKET_512_1023_BYTES_MSB   =  32'h00000544;
    parameter  ADDR_STAT_TX_PACKET_1523_1548_BYTES_LSB  =  32'h00000558;
    parameter  ADDR_STAT_TX_PACKET_1523_1548_BYTES_MSB  =  32'h0000055C;
    parameter  ADDR_STAT_TX_PACKET_8192_9215_BYTES_LSB  =  32'h00000578;
    parameter  ADDR_STAT_TX_PACKET_8192_9215_BYTES_MSB  =  32'h0000057C;

    parameter  ADDR_STAT_RX_TOTAL_PACKETS_LSB           =  32'h00000608;
    parameter  ADDR_STAT_RX_TOTAL_PACKETS_MSB           =  32'h0000060C;
    parameter  ADDR_STAT_RX_TOTAL_GOOD_PACKETS_LSB      =  32'h00000610;
    parameter  ADDR_STAT_RX_TOTAL_GOOD_PACKETS_MSB      =  32'h00000614;
    parameter  ADDR_STAT_RX_TOTAL_BYTES_LSB             =  32'h00000618;
    parameter  ADDR_STAT_RX_TOTAL_BYTES_MSB             =  32'h0000061C;
    parameter  ADDR_STAT_RX_TOTAL_GOOD_BYTES_LSB        =  32'h00000620;
    parameter  ADDR_STAT_RX_TOTAL_GOOD_BYTES_MSB        =  32'h00000624;
    parameter  ADDR_STAT_RX_PACKET_64_BYTES_LSB         =  32'h00000628;
    parameter  ADDR_STAT_RX_PACKET_64_BYTES_MSB         =  32'h0000062C;
    parameter  ADDR_STAT_RX_PACKET_256_511_BYTES_LSB    =  32'h00000640;
    parameter  ADDR_STAT_RX_PACKET_256_511_BYTES_MSB    =  32'h00000644;
    parameter  ADDR_STAT_RX_PACKET_512_1023_BYTES_LSB   =  32'h00000648;
    parameter  ADDR_STAT_RX_PACKET_512_1023_BYTES_MSB   =  32'h0000064C;
    parameter  ADDR_STAT_RX_PACKET_1523_1548_BYTES_LSB  =  32'h00000660;
    parameter  ADDR_STAT_RX_PACKET_1523_1548_BYTES_MSB  =  32'h00000664;
    parameter  ADDR_STAT_RX_PACKET_8192_9215_BYTES_LSB  =  32'h00000680;
    parameter  ADDR_STAT_RX_PACKET_8192_9215_BYTES_MSB  =  32'h00000684;

    parameter  ADDR_TICK_REG                            =  32'h000002B0;

    ////State Registers for TX
    reg  [3:0]     axi_user_prestate;

//    reg  [31:0]    axi_wr_data;
//    reg  [31:0]    axi_read_data;
//    wire [31:0]    axi_rd_data;
//    reg  [31:0]    axi_wr_addr, axi_rd_addr;
//    reg  [3:0]     axi_wr_strobe;
//    reg            axi_wr_data_valid;
//    reg            axi_wr_addr_valid;
//    reg            axi_rd_addr_valid;
//    reg            axi_rd_req;
//    reg            axi_wr_req;
//    wire           axi_wr_ack;
//    wire           axi_rd_ack;
//    wire           axi_wr_err;
//    wire           axi_rd_err;
    reg  [7:0]     rd_wr_cntr; 
    reg  [47:0]    tx_total_pkt, tx_total_bytes, tx_total_good_pkts, tx_total_good_bytes;
    reg  [47:0]    tx_packet_64_bytes, tx_packet_256_511_bytes, tx_packet_512_1023_bytes, tx_packet_1523_1548_bytes, tx_packet_8192_9215_bytes;
    reg  [47:0]    rx_total_pkt, rx_total_bytes, rx_total_good_pkts, rx_total_good_bytes;
    reg  [47:0]    rx_packet_64_bytes, rx_packet_256_511_bytes, rx_packet_512_1023_bytes, rx_packet_1523_1548_bytes, rx_packet_8192_9215_bytes;
    reg            sanity_init_done_r;
    reg            pause_init_done_r;
    reg            init_rx_aligned;
    reg            init_data_sanity;
    reg            init_tx_rx_pause;
    reg            init_stat_read;
    wire           stat_rx_aligned_sync;
    wire           gt_locked_sync;
    wire           rx_done_sync;
    wire           rx_busy_sync;
    reg            rx_busy_led_r;

    wire           pm_tick_r;


    ////----------------------------------------TX Module -----------------------//
    
    
    //////////////////////////////////////////////////
    ////State Machine 
    //////////////////////////////////////////////////
    always @( posedge s_axi_aclk )
    begin
        if ( s_axi_sreset == 1'b1 )
        begin
            axi_user_prestate         <= STATE_AXI_IDLE;
//            axi_rd_addr               <= 32'd0;
//            axi_rd_addr_valid         <= 1'b0;
//            axi_wr_data               <= 32'd0;
//            axi_read_data             <= 32'd0;
//            axi_wr_addr               <= 32'd0;
//            axi_wr_addr_valid         <= 1'b0;
//            axi_wr_data_valid         <= 1'b0;
//            axi_wr_strobe             <= 4'd0;
//            axi_rd_req                <= 1'b0;
//            axi_wr_req                <= 1'b0;
            rd_wr_cntr                <= 8'd0;
            init_rx_aligned           <= 1'b0;
            init_data_sanity          <= 1'b0;
            init_tx_rx_pause          <= 1'b0;
            init_stat_read            <= 1'b0;
            sanity_init_done_r        <= 1'b0;
            pause_init_done_r         <= 1'b0;
            tx_total_pkt              <= 48'd0;
            tx_total_bytes            <= 48'd0;
            tx_total_good_pkts        <= 48'd0;
            tx_total_good_bytes       <= 48'd0;
            tx_packet_64_bytes        <= 48'd0;
            tx_packet_256_511_bytes   <= 48'd0;
            tx_packet_512_1023_bytes  <= 48'd0;
            tx_packet_1523_1548_bytes <= 48'd0;
            tx_packet_8192_9215_bytes <= 48'd0;
            rx_busy_led_r             <= 1'b0;
            rx_total_pkt              <= 48'd0;
            rx_total_bytes            <= 48'd0;
            rx_total_good_pkts        <= 48'd0;
            rx_total_good_bytes       <= 48'd0;
            rx_packet_64_bytes        <= 48'd0;
            rx_packet_256_511_bytes   <= 48'd0;
            rx_packet_512_1023_bytes  <= 48'd0;
            rx_packet_1523_1548_bytes <= 48'd0;
            rx_packet_8192_9215_bytes <= 48'd0;
        end
        else
        begin
        case (axi_user_prestate)
            STATE_AXI_IDLE            :
                                     begin
//                                         axi_rd_addr               <= 32'd0;
//                                         axi_rd_addr_valid         <= 1'b0;
//                                         axi_wr_data               <= 32'd0;
//                                         axi_read_data             <= 32'd0;
//                                         axi_wr_addr               <= 32'd0;
//                                         axi_wr_addr_valid         <= 1'b0;
//                                         axi_wr_data_valid         <= 1'b0;
//                                         axi_wr_strobe             <= 4'd0;
//                                         axi_rd_req                <= 1'b0;
//                                         axi_wr_req                <= 1'b0;
                                         rd_wr_cntr                <= 8'd0;
                                         init_rx_aligned           <= 1'b0;
                                         init_data_sanity          <= 1'b0;
                                         init_tx_rx_pause          <= 1'b0;
                                         init_stat_read            <= 1'b0;
                                         sanity_init_done_r        <= 1'b0;
                                         pause_init_done_r         <= 1'b0;
                                         tx_total_pkt              <= 48'd0;
                                         tx_total_bytes            <= 48'd0;
                                         tx_total_good_pkts        <= 48'd0;
                                         tx_total_good_bytes       <= 48'd0;
                                         tx_packet_64_bytes        <= 48'd0;
                                         tx_packet_256_511_bytes   <= 48'd0;
                                         tx_packet_512_1023_bytes  <= 48'd0;
                                         tx_packet_1523_1548_bytes <= 48'd0;
                                         tx_packet_8192_9215_bytes <= 48'd0;
                                         rx_busy_led_r             <= 1'b0;
                                         rx_total_pkt              <= 48'd0;
                                         rx_total_bytes            <= 48'd0;
                                         rx_total_good_pkts        <= 48'd0;
                                         rx_total_good_bytes       <= 48'd0;
                                         rx_packet_64_bytes        <= 48'd0;
                                         rx_packet_256_511_bytes   <= 48'd0;
                                         rx_packet_512_1023_bytes  <= 48'd0;
                                         rx_packet_1523_1548_bytes <= 48'd0;
                                         rx_packet_8192_9215_bytes <= 48'd0;

                                         //// State transition
                                         if  (gt_locked_sync == 1'b1)
                                         begin
                                             $display("INFO : GT LOCKED");
                                             axi_user_prestate <= STATE_GT_LOCKED;
                                         end
                                         else
                                             axi_user_prestate <= STATE_AXI_IDLE;
                                     end
            STATE_GT_LOCKED          :
                                     begin
//                                         axi_rd_addr             <= 32'd0;
//                                         axi_rd_addr_valid       <= 1'b0;
//                                         axi_wr_data             <= 32'd0;
//                                         axi_read_data           <= 32'd0;
//                                         axi_wr_addr             <= 32'd0;
//                                         axi_wr_addr_valid       <= 1'b0;
//                                         axi_wr_data_valid       <= 1'b0;
//                                         axi_wr_strobe           <= 4'd0;
//                                         axi_rd_req              <= 1'b0;
//                                         axi_wr_req              <= 1'b0;
                                         rd_wr_cntr              <= 8'd0;
                                         rx_busy_led_r           <= 1'b1;
                                         init_rx_aligned         <= 1'b0;
                                         init_data_sanity        <= 1'b0;
                                         init_tx_rx_pause        <= 1'b0;
                                         init_stat_read          <= 1'b0;
                                         sanity_init_done_r      <= 1'b0;
                                         pause_init_done_r       <= 1'b0;

                                         //// State transition
                                         if  (gt_locked_sync == 1'b0)
                                             axi_user_prestate <= STATE_AXI_IDLE;
                                         else 
                                             axi_user_prestate <= STATE_INIT_RX_ALIGNED;
                                     end
            STATE_INIT_RX_ALIGNED    :
                                     begin
                                         rx_busy_led_r           <= 1'b1;
                                         init_rx_aligned         <= 1'b1;

                                         case (rd_wr_cntr)
                                             'd0     : begin
                                                           $display( "           AXI4 Lite Write Started to Config the Core CTL_* Ports ..." );
//                                                           axi_wr_data             <= 32'h00000001;           //// ctl_rx_enable
//                                                           axi_wr_addr             <= ADDR_CONFIG_RX_REG1;    //// CONFIGURATION_RX_REG1
//                                                           axi_wr_addr_valid       <= 1'b1;
//                                                           axi_wr_data_valid       <= 1'b1;
//                                                           axi_wr_strobe           <= 4'hF;
//                                                           axi_rd_req              <= 1'b0;
//                                                           axi_wr_req              <= 1'b1;
                                                       end
                                             'd1     : begin
//                                                           axi_wr_data             <= 32'h00000018;          //// ctl_tx_send_lfi,ctl_tx_send_rfi
//                                                           axi_wr_addr             <= ADDR_CONFIG_TX_REG1;   //// CONFIGURATION_TX_REG1
//                                                           axi_wr_addr_valid       <= 1'b1;
//                                                           axi_wr_data_valid       <= 1'b1;
//                                                           axi_wr_strobe           <= 4'hF;
//                                                           axi_rd_req              <= 1'b0;
//                                                           axi_wr_req              <= 1'b1;
                                                       end
                                             default : begin
//                                                           axi_wr_data             <= 32'h0;
//                                                           axi_wr_addr             <= 32'h0;
//                                                           axi_wr_addr_valid       <= 1'b0;
//                                                           axi_wr_data_valid       <= 1'b0;
//                                                           axi_wr_strobe           <= 4'h0;
//                                                           axi_rd_req              <= 1'b0;
//                                                           axi_wr_req              <= 1'b0;
                                                       end
                                         endcase

                                         //// State transition
                                         if  (gt_locked_sync == 1'b0)
                                             axi_user_prestate <= STATE_AXI_IDLE;
                                         else if  (rd_wr_cntr == 8'd2)
                                         begin
                                             $display( "           AXI4 Lite Write Completed" );
                                             $display("INFO : WAITING FOR CMAC RX_ALIGNED..........");
                                             axi_user_prestate <= STATE_WAIT_RX_ALIGNED;
                                         end
                                         else
                                             axi_user_prestate <= STATE_AXI_RD_WR;
                                     end
            STATE_AXI_RD_WR          :
                                     begin
//                                         if (s_axi_awready == 1'b1)
//                                         begin
//                                             axi_wr_addr             <= 32'd0;
//                                             axi_wr_addr_valid       <= 1'b0;
//                                             axi_wr_req              <= 1'b0;
//                                         end
//                                         if (s_axi_wready == 1'b1)
//                                         begin
//                                             axi_wr_data             <= 32'd0;
//                                             axi_wr_data_valid       <= 1'b0;
//                                             axi_wr_strobe           <= 4'd0;
//                                         end
//                                         if (s_axi_arready == 1'b1)
//                                         begin
//                                             axi_rd_addr             <= 32'd0;
//                                             axi_rd_addr_valid       <= 1'b0;
//                                             axi_rd_req              <= 1'b0;
//                                         end
                                         
                                         //// State transition
                                         if (pm_tick_r == 1'b1)
                                         begin
                                            rd_wr_cntr        <= rd_wr_cntr + 8'd1;
                                            axi_user_prestate <= STATE_READ_STATS;
                                         end
//                                         else if  ((axi_wr_ack == 1'b1 && axi_wr_err == 1'b1) || (axi_rd_ack == 1'b1 && axi_rd_err == 1'b1))
//                                         begin
//                                             $display("ERROR : INVALID AXI4 Lite READ/WRITE OPERATION OCCURED, APPLY SYS_RESET TO RECOVER ..........");
//                                             axi_user_prestate <= STATE_INVALID_AXI_RD_WR;
//                                         end
//                                         else if  ((axi_wr_ack == 1'b1 && axi_wr_err == 1'b0) || (axi_rd_ack == 1'b1 && axi_rd_err == 1'b0))
//                                         begin
//                                             rd_wr_cntr              <= rd_wr_cntr + 8'd1;
//                                             axi_read_data           <= axi_rd_data;
//                                             if  (init_rx_aligned == 1'b1)
//                                                 axi_user_prestate <= STATE_INIT_RX_ALIGNED;
//                                             else if  (init_data_sanity == 1'b1)
//                                                 axi_user_prestate <= STATE_INIT_PKT_TRANSFER;
//                                             else if  (init_tx_rx_pause == 1'b1)
//                                                 axi_user_prestate <= STATE_TX_RX_PAUSE_INIT;
//                                             else if  (init_stat_read == 1'b1)
//                                                 axi_user_prestate <= STATE_READ_STATS;
//                                             else
//                                                 axi_user_prestate <= STATE_AXI_RD_WR;
//                                         end
                                     end
            STATE_WAIT_RX_ALIGNED    :
                                     begin
                                         rx_busy_led_r           <= 1'b1;
//                                         axi_rd_addr             <= 32'd0;
//                                         axi_rd_addr_valid       <= 1'b0;
//                                         axi_wr_data             <= 32'd0;
//                                         axi_read_data           <= 32'd0;
//                                         axi_wr_addr             <= 32'd0;
//                                         axi_wr_addr_valid       <= 1'b0;
//                                         axi_wr_data_valid       <= 1'b0;
//                                         axi_wr_strobe           <= 4'd0;
//                                         axi_rd_req              <= 1'b0;
//                                         axi_wr_req              <= 1'b0;
                                         rd_wr_cntr              <= 8'd0;
                                         init_rx_aligned         <= 1'b0;
                                         init_data_sanity        <= 1'b0;
                                         init_tx_rx_pause        <= 1'b0;
                                         init_stat_read          <= 1'b0;
                                         sanity_init_done_r      <= 1'b0;
                                         pause_init_done_r       <= 1'b0;

                                         //// State transition
                                         if  (gt_locked_sync == 1'b0)
                                             axi_user_prestate <= STATE_AXI_IDLE;
                                         else if  (stat_rx_aligned_sync == 1'b1)
                                         begin
                                             $display("INFO : RX-ALIGNED");
                                             axi_user_prestate <= STATE_INIT_PKT_TRANSFER;
                                         end
                                         else
                                             axi_user_prestate <= STATE_WAIT_RX_ALIGNED;
                                     end
            STATE_INIT_PKT_TRANSFER  : 
                                     begin
                                         rx_busy_led_r           <= 1'b1;
                                         init_data_sanity        <= 1'b1;

//                                         case (rd_wr_cntr)
//                                             'd0     : begin
//                                                           $display( "           AXI4 Lite Read Started for Core Version Reg..." );
//                                                           axi_rd_addr             <= ADDR_CORE_VERSION_REG;
//                                                           axi_rd_addr_valid       <= 1'b1;
//                                                           axi_rd_req              <= 1'b1;
//                                                           axi_wr_req              <= 1'b0;
//                                                       end
//                                             'd1     : begin
//                                                           $display( "           Core_Version  =  %d.%0d", axi_read_data[15:8], axi_read_data[7:0] );
//                                                           $display( "           AXI4 Lite Write Started to Enable data sanity check..." );
//                                                           axi_wr_data             <= 32'h00000001;         //// ctl_tx_enable=1 and ctl_tx_send_lfi=0,ctl_tx_send_rfi=0
//                                                           axi_wr_addr             <= ADDR_CONFIG_TX_REG1;  //// CONFIGURATION_TX_REG1
//                                                           axi_wr_addr_valid       <= 1'b1;
//                                                           axi_wr_data_valid       <= 1'b1;
//                                                           axi_wr_strobe           <= 4'hF;
//                                                           axi_rd_addr_valid       <= 1'b0;
//                                                           axi_rd_req              <= 1'b0;
//                                                           axi_wr_req              <= 1'b1;
//                                                       end
//                                             default : begin
//                                                           axi_wr_data             <= 32'h0;
//                                                           axi_wr_addr             <= 32'h0;
//                                                           axi_wr_addr_valid       <= 1'b0;
//                                                           axi_wr_data_valid       <= 1'b0;
//                                                           axi_wr_strobe           <= 4'h0;
//                                                           axi_rd_addr_valid       <= 1'b0;
//                                                           axi_rd_req              <= 1'b0;
//                                                           axi_wr_req              <= 1'b0;
//                                                       end
//                                         endcase

                                         //// State transition
                                         if  (gt_locked_sync == 1'b0 || stat_rx_aligned_sync == 1'b0)
                                             axi_user_prestate <= STATE_AXI_IDLE;
                                         else if  (rd_wr_cntr == 8'd2)
                                         begin
                                             $display( "           AXI4 Lite Write Completed" );
                                             $display("INFO : Packet Generator and Monitor (SANITY Testing) STARTED");
                                             axi_user_prestate <= STATE_WAIT_SANITY_DONE;
                                         end
                                         else
                                             axi_user_prestate <= STATE_AXI_RD_WR;
                                     end
            STATE_WAIT_SANITY_DONE   :
                                      begin
                                         rx_busy_led_r           <= 1'b1;
//                                         axi_rd_addr             <= 32'd0;
//                                         axi_rd_addr_valid       <= 1'b0;
//                                         axi_wr_data             <= 32'd0;
//                                         axi_read_data           <= 32'd0;
//                                         axi_wr_addr             <= 32'd0;
//                                         axi_wr_addr_valid       <= 1'b0;
//                                         axi_wr_data_valid       <= 1'b0;
//                                         axi_wr_strobe           <= 4'd0;
//                                         axi_rd_req              <= 1'b0;
//                                         axi_wr_req              <= 1'b0;
                                         rd_wr_cntr              <= 8'd0;
                                         init_rx_aligned         <= 1'b0;
                                         init_data_sanity        <= 1'b0;
                                         init_tx_rx_pause        <= 1'b0;
                                         init_stat_read          <= 1'b0;
                                         sanity_init_done_r      <= 1'b1;
                                         pause_init_done_r       <= 1'b0;

                                         //// State transition
                                         if  (gt_locked_sync == 1'b0 || stat_rx_aligned_sync == 1'b0)
                                             axi_user_prestate <= STATE_AXI_IDLE;
                                         else if  (rx_done_sync == 1'b1) 
                                             axi_user_prestate <= STATE_TX_RX_PAUSE_INIT;
                                         else
                                             axi_user_prestate <= STATE_WAIT_SANITY_DONE;
                                     end
            STATE_TX_RX_PAUSE_INIT   : 
                                     begin
                                         rx_busy_led_r           <= 1'b1;
                                         init_tx_rx_pause        <= 1'b1;

//                                         case (rd_wr_cntr)
//                                             'd0       : begin
//                                                           $display( "           AXI4 Lite Write Started for PAUSE PACKETS TEST..." );
//                                                           axi_wr_data             <= 32'h00003DFF;
//                                                           axi_wr_addr             <= ADDR_CONFIG_RX_FLOW_CTL_CONTROL_REG1;  //// CONFIGURATION_RX_FLOW_CONTROL_CONTROL_REG1
//                                                           axi_wr_addr_valid       <= 1'b1;
//                                                           axi_wr_data_valid       <= 1'b1;
//                                                           axi_wr_strobe           <= 4'hF;
//                                                           axi_rd_req              <= 1'b0;
//                                                           axi_wr_req              <= 1'b1;
//                                                       end
//                                             'd1       : begin
//                                                           axi_wr_data             <= 32'h0001C631;
//                                                           axi_wr_addr             <= ADDR_CONFIG_RX_FLOW_CTL_CONTROL_REG2;  //// CONFIGURATION_RX_FLOW_CONTROL_CONTROL_REG2
//                                                           axi_wr_addr_valid       <= 1'b1;
//                                                           axi_wr_data_valid       <= 1'b1;
//                                                           axi_wr_strobe           <= 4'hF;
//                                                           axi_rd_req              <= 1'b0;
//                                                           axi_wr_req              <= 1'b1;
//                                                       end
//                                             'd2       : begin
//                                                           axi_wr_data             <= 32'hFFFFFFFF;                         //// {QUANTA1, QUANTA0}
//                                                           axi_wr_addr             <= ADDR_CONFIG_TX_FLOW_CTL_QUANTA_REG1;  //// CONFIGURATION_TX_FLOW_CONTROL_QUANTA_REG1
//                                                           axi_wr_addr_valid       <= 1'b1;
//                                                           axi_wr_data_valid       <= 1'b1;
//                                                           axi_wr_strobe           <= 4'hF;
//                                                           axi_rd_req              <= 1'b0;
//                                                           axi_wr_req              <= 1'b1;
//                                                       end
//                                             'd3       : begin
//                                                           axi_wr_data             <= 32'hFFFFFFFF;                         //// {QUANTA3, QUANTA2}
//                                                           axi_wr_addr             <= ADDR_CONFIG_TX_FLOW_CTL_QUANTA_REG2;  //// CONFIGURATION_TX_FLOW_CONTROL_QUANTA_REG2
//                                                           axi_wr_addr_valid       <= 1'b1;
//                                                           axi_wr_data_valid       <= 1'b1;
//                                                           axi_wr_strobe           <= 4'hF;
//                                                           axi_rd_req              <= 1'b0;
//                                                           axi_wr_req              <= 1'b1;
//                                                       end
//                                             'd4       : begin
//                                                           axi_wr_data             <= 32'hFFFFFFFF;                         //// {QUANTA5, QUANTA4}
//                                                           axi_wr_addr             <= ADDR_CONFIG_TX_FLOW_CTL_QUANTA_REG3;  //// CONFIGURATION_TX_FLOW_CONTROL_QUANTA_REG3
//                                                           axi_wr_addr_valid       <= 1'b1;
//                                                           axi_wr_data_valid       <= 1'b1;
//                                                           axi_wr_strobe           <= 4'hF;
//                                                           axi_rd_req              <= 1'b0;
//                                                           axi_wr_req              <= 1'b1;
//                                                       end
//                                             'd5       : begin
//                                                           axi_wr_data             <= 32'hFFFFFFFF;                         //// {QUANTA7, QUANTA6}
//                                                           axi_wr_addr             <= ADDR_CONFIG_TX_FLOW_CTL_QUANTA_REG4;  //// CONFIGURATION_TX_FLOW_CONTROL_QUANTA_REG4
//                                                           axi_wr_addr_valid       <= 1'b1;
//                                                           axi_wr_data_valid       <= 1'b1;
//                                                           axi_wr_strobe           <= 4'hF;
//                                                           axi_rd_req              <= 1'b0;
//                                                           axi_wr_req              <= 1'b1;
//                                                       end
//                                             'd6       : begin
//                                                           axi_wr_data             <= 32'h0000FFFF;                         //// {8'h00, QUANTA8}
//                                                           axi_wr_addr             <= ADDR_CONFIG_TX_FLOW_CTL_QUANTA_REG5;  //// CONFIGURATION_TX_FLOW_CONTROL_QUANTA_REG5
//                                                           axi_wr_addr_valid       <= 1'b1;
//                                                           axi_wr_data_valid       <= 1'b1;
//                                                           axi_wr_strobe           <= 4'hF;
//                                                           axi_rd_req              <= 1'b0;
//                                                           axi_wr_req              <= 1'b1;
//                                                       end
//                                             'd7       : begin
//                                                           axi_wr_data             <= 32'hFFFFFFFF;                          //// {REF_TIMER1, REF_TIMER0}
//                                                           axi_wr_addr             <= ADDR_CONFIG_TX_FLOW_CTL_REFRESH_REG1;  //// CONFIGURATION_TX_FLOW_CONTROL_REFRESH_REG1
//                                                           axi_wr_addr_valid       <= 1'b1;
//                                                           axi_wr_data_valid       <= 1'b1;
//                                                           axi_wr_strobe           <= 4'hF;
//                                                           axi_rd_req              <= 1'b0;
//                                                           axi_wr_req              <= 1'b1;
//                                                       end
//                                             'd8       : begin
//                                                           axi_wr_data             <= 32'hFFFFFFFF;                          //// {REF_TIMER3, REF_TIMER2}
//                                                           axi_wr_addr             <= ADDR_CONFIG_TX_FLOW_CTL_REFRESH_REG2;  //// CONFIGURATION_TX_FLOW_CONTROL_REFRESH_REG2
//                                                           axi_wr_addr_valid       <= 1'b1;
//                                                           axi_wr_data_valid       <= 1'b1;
//                                                           axi_wr_strobe           <= 4'hF;
//                                                           axi_rd_req              <= 1'b0;
//                                                           axi_wr_req              <= 1'b1;
//                                                       end
//                                             'd9       : begin
//                                                           axi_wr_data             <= 32'hFFFFFFFF;                          //// {REF_TIMER5, REF_TIMER4}
//                                                           axi_wr_addr             <= ADDR_CONFIG_TX_FLOW_CTL_REFRESH_REG3;  //// CONFIGURATION_TX_FLOW_CONTROL_REFRESH_REG3
//                                                           axi_wr_addr_valid       <= 1'b1;
//                                                           axi_wr_data_valid       <= 1'b1;
//                                                           axi_wr_strobe           <= 4'hF;
//                                                           axi_rd_req              <= 1'b0;
//                                                           axi_wr_req              <= 1'b1;
//                                                       end
//                                             'd10      : begin
//                                                           axi_wr_data             <= 32'hFFFFFFFF;                          //// {REF_TIMER7, REF_TIMER6}
//                                                           axi_wr_addr             <= ADDR_CONFIG_TX_FLOW_CTL_REFRESH_REG4;  //// CONFIGURATION_TX_FLOW_CONTROL_REFRESH_REG4
//                                                           axi_wr_addr_valid       <= 1'b1;
//                                                           axi_wr_data_valid       <= 1'b1;
//                                                           axi_wr_strobe           <= 4'hF;
//                                                           axi_rd_req              <= 1'b0;
//                                                           axi_wr_req              <= 1'b1;
//                                                       end
//                                             'd11      : begin
//                                                           axi_wr_data             <= 32'h0000FFFF;                          //// {8'h00, REF_TIMER8}
//                                                           axi_wr_addr             <= ADDR_CONFIG_TX_FLOW_CTL_REFRESH_REG5;  //// CONFIGURATION_TX_FLOW_CONTROL_REFRESH_REG5
//                                                           axi_wr_addr_valid       <= 1'b1;
//                                                           axi_wr_data_valid       <= 1'b1;
//                                                           axi_wr_strobe           <= 4'hF;
//                                                           axi_rd_req              <= 1'b0;
//                                                           axi_wr_req              <= 1'b1;
//                                                       end
//                                             'd12      : begin
//                                                           axi_wr_data             <= 32'h000001FF;
//                                                           axi_wr_addr             <= ADDR_CONFIG_TX_FLOW_CTL_CONTROL_REG1;  //// CONFIGURATION_TX_FLOW_CONTROL_CONTROL_REG1
//                                                           axi_wr_addr_valid       <= 1'b1;
//                                                           axi_wr_data_valid       <= 1'b1;
//                                                           axi_wr_strobe           <= 4'hF;
//                                                           axi_rd_req              <= 1'b0;
//                                                           axi_wr_req              <= 1'b1;
//                                                       end
//                                              default : begin
//                                                           axi_wr_data             <= 32'h0;
//                                                           axi_wr_addr             <= 32'h0;
//                                                           axi_wr_addr_valid       <= 1'b0;
//                                                           axi_wr_data_valid       <= 1'b0;
//                                                           axi_wr_strobe           <= 4'h0;
//                                                           axi_rd_req              <= 1'b0;
//                                                           axi_wr_req              <= 1'b0;
//                                                       end
//                                         endcase

                                         //// State transition
                                         if  (gt_locked_sync == 1'b0 || stat_rx_aligned_sync == 1'b0)
                                             axi_user_prestate <= STATE_AXI_IDLE;
                                         else if  (rd_wr_cntr == 8'd13)
                                         begin
                                             $display( "           AXI4 Lite Write Completed" );
                                             $display("INFO : PAUSE PACKETS TESTING..........");
                                             axi_user_prestate <= STATE_TX_RX_PAUSE_DONE;
                                         end
                                         else
                                             axi_user_prestate <= STATE_AXI_RD_WR;
                                     end
            STATE_TX_RX_PAUSE_DONE   :
                                      begin
                                         rx_busy_led_r           <= 1'b1;
//                                         axi_rd_addr             <= 32'd0;
//                                         axi_rd_addr_valid       <= 1'b0;
//                                         axi_read_data           <= 32'd0;
//                                         axi_wr_data             <= 32'd0;
//                                         axi_wr_addr             <= 32'd0;
//                                         axi_wr_addr_valid       <= 1'b0;
//                                         axi_wr_data_valid       <= 1'b0;
//                                         axi_wr_strobe           <= 4'd0;
//                                         axi_rd_req              <= 1'b0;
//                                         axi_wr_req              <= 1'b0;
                                         rd_wr_cntr              <= 8'd0;
                                         init_rx_aligned         <= 1'b0;
                                         init_data_sanity        <= 1'b0;
                                         init_tx_rx_pause        <= 1'b0;
                                         init_stat_read          <= 1'b0;
                                         sanity_init_done_r      <= 1'b1;
                                         pause_init_done_r       <= 1'b1;

                                         //// State transition
                                         if  (gt_locked_sync == 1'b0 || stat_rx_aligned_sync == 1'b0)
                                             axi_user_prestate <= STATE_AXI_IDLE;
                                         else if (rx_busy_sync == 1'b0)
                                         begin
                                             $display("INFO : PAUSE PACKETS TEST COMPLETED and PASSED");
                                             axi_user_prestate <= STATE_TEST_WAIT;
                                         end
                                     end
            STATE_TEST_WAIT          :
                                      begin
                                         rx_busy_led_r           <= 1'b1;
//                                         axi_rd_addr             <= 32'd0;
//                                         axi_rd_addr_valid       <= 1'b0;
//                                         axi_read_data           <= 32'd0;
//                                         axi_wr_data             <= 32'd0;
//                                         axi_wr_addr             <= 32'd0;
//                                         axi_wr_addr_valid       <= 1'b0;
//                                         axi_wr_data_valid       <= 1'b0;
//                                         axi_wr_strobe           <= 4'd0;
//                                         axi_rd_req              <= 1'b0;
//                                         axi_wr_req              <= 1'b0;
                                         rd_wr_cntr              <= 8'd0;
                                         init_rx_aligned         <= 1'b0;
                                         init_data_sanity        <= 1'b0;
                                         init_tx_rx_pause        <= 1'b0;
                                         init_stat_read          <= 1'b0;
                                         sanity_init_done_r      <= 1'b1;
                                         pause_init_done_r       <= 1'b0;

                                         //// State transition
                                         if  (gt_locked_sync == 1'b0 || stat_rx_aligned_sync == 1'b0)
                                             axi_user_prestate <= STATE_AXI_IDLE;
                                         else if  (rx_busy_sync == 1'b0)
                                         begin
                                             axi_user_prestate <= STATE_READ_STATS;
                                         end
                                         else
                                             axi_user_prestate <= STATE_TEST_WAIT;
                                     end
            STATE_READ_STATS         : 
                                     begin
                                         rx_busy_led_r           <= 1'b1;
                                         init_stat_read          <= 1'b1;

//                                         case (rd_wr_cntr)
//                                             'd0       : begin
//                                                             if (pm_tick_r == 1'b1)
//                                                             begin
//                                                                $display( "           PM Tick input is driven as %b", pm_tick_r );
//                                                                axi_rd_addr             <= ADDR_STAT_TX_TOTAL_PACKETS_LSB;
//                                                                axi_rd_addr_valid       <= 1'b1;
//                                                                axi_rd_req              <= 1'b1;
//                                                                axi_wr_req              <= 1'b0;
//                                                             end
//                                                             else
//                                                             begin
//                                                                $display( "           PM Tick is written through AXI4 Lite" );
//                                                                axi_wr_data             <= 32'h00000001;   //// If input pin pm_tick = 1'b0, then AXI pm tick write 1'b1 will happen thru AXI interface
//                                                                axi_wr_addr             <= ADDR_TICK_REG;  //// ADDR_TICK_REG
//                                                                axi_wr_addr_valid       <= 1'b1;
//                                                                axi_wr_data_valid       <= 1'b1;
//                                                                axi_wr_strobe           <= 4'hF;
//                                                                axi_rd_req              <= 1'b0;
//                                                                axi_wr_req              <= 1'b1;
//                                                             end
//                                                       end
//                                             'd1       : begin
//                                                             $display( "           AXI4 Lite Read Started for TX and RX Stats..." );
//                                                             axi_rd_addr                     <= ADDR_STAT_TX_TOTAL_PACKETS_LSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                       end
//                                             'd2       : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_TX_TOTAL_PACKETS_MSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             tx_total_pkt[31:0]              <= axi_read_data;
//                                                       end
//                                             'd3       : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_TX_TOTAL_GOOD_PACKETS_LSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             tx_total_pkt[47:32]             <= axi_read_data[15:0];
//                                                       end
//                                             'd4       : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_TX_TOTAL_GOOD_PACKETS_MSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             tx_total_good_pkts[31:0]        <= axi_read_data;
//                                                       end
//                                             'd5       : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_TX_TOTAL_BYTES_LSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             tx_total_good_pkts[47:32]       <= axi_read_data[15:0];
//                                                       end
//                                             'd6       : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_TX_TOTAL_BYTES_MSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             tx_total_bytes[31:0]            <= axi_read_data;
//                                                       end
//                                             'd7       : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_TX_TOTAL_GOOD_BYTES_LSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             tx_total_bytes[47:32]           <= axi_read_data[15:0];
//                                                       end
//                                             'd8       : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_TX_TOTAL_GOOD_BYTES_MSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             tx_total_good_bytes[31:0]       <= axi_read_data;
//                                                       end
//                                             'd9       : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_RX_TOTAL_PACKETS_LSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             tx_total_good_bytes[47:32]      <= axi_read_data[15:0];
//                                                       end
//                                             'd10      : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_RX_TOTAL_PACKETS_MSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             rx_total_pkt[31:0]              <= axi_read_data;
//                                                       end
//                                             'd11      : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_RX_TOTAL_GOOD_PACKETS_LSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             rx_total_pkt[47:32]             <= axi_read_data[15:0];
//                                                       end
//                                             'd12      : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_RX_TOTAL_GOOD_PACKETS_MSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             rx_total_good_pkts[31:0]        <= axi_read_data;
//                                                       end
//                                             'd13      : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_RX_TOTAL_BYTES_LSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             rx_total_good_pkts[47:32]       <= axi_read_data[15:0];
//                                                       end
//                                             'd14      : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_RX_TOTAL_BYTES_MSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             rx_total_bytes[31:0]            <= axi_read_data;
//                                                       end
//                                             'd15      : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_RX_TOTAL_GOOD_BYTES_LSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             rx_total_bytes[47:32]           <= axi_read_data[15:0];
//                                                       end
//                                             'd16      : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_RX_TOTAL_GOOD_BYTES_MSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             rx_total_good_bytes[31:0]       <= axi_read_data;
//                                                       end
//                                             'd17      : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_TX_PACKET_64_BYTES_LSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             rx_total_good_bytes[47:32]      <= axi_read_data[15:0];
//                                                       end
//                                             'd18      : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_TX_PACKET_64_BYTES_MSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             tx_packet_64_bytes[31:0]        <= axi_read_data;
//                                                       end
//                                             'd19      : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_RX_PACKET_64_BYTES_LSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             tx_packet_64_bytes[47:32]       <= axi_read_data[15:0];
//                                                       end
//                                             'd20      : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_RX_PACKET_64_BYTES_MSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             rx_packet_64_bytes[31:0]        <= axi_read_data;
//                                                       end
//                                             'd21      : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_TX_PACKET_256_511_BYTES_LSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             rx_packet_64_bytes[47:32]       <= axi_read_data[15:0];
//                                                       end
//                                             'd22      : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_TX_PACKET_256_511_BYTES_MSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             tx_packet_256_511_bytes[31:0]   <= axi_read_data;
//                                                       end
//                                             'd23       : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_RX_PACKET_256_511_BYTES_LSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             tx_packet_256_511_bytes[47:32]  <= axi_read_data[15:0];
//                                                       end
//                                             'd24      : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_RX_PACKET_256_511_BYTES_MSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             rx_packet_256_511_bytes[31:0]   <= axi_read_data;
//                                                       end
//                                             'd25      : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_TX_PACKET_512_1023_BYTES_LSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             rx_packet_256_511_bytes[47:32]  <= axi_read_data[15:0];
//                                                       end
//                                             'd26      : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_TX_PACKET_512_1023_BYTES_MSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             tx_packet_512_1023_bytes[31:0]  <= axi_read_data;
//                                                       end
//                                             'd27      : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_RX_PACKET_512_1023_BYTES_LSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             tx_packet_512_1023_bytes[47:32] <= axi_read_data[15:0];
//                                                       end
//                                             'd28      : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_RX_PACKET_512_1023_BYTES_MSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             rx_packet_512_1023_bytes[31:0]  <= axi_read_data;
//                                                       end
//                                             'd29      : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_TX_PACKET_1523_1548_BYTES_LSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             rx_packet_512_1023_bytes[47:32] <= axi_read_data[15:0];
//                                                       end
//                                             'd30      : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_TX_PACKET_1523_1548_BYTES_MSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             tx_packet_1523_1548_bytes[31:0] <= axi_read_data;
//                                                       end
//                                             'd31      : begin
//                                                             axi_rd_addr                      <= ADDR_STAT_RX_PACKET_1523_1548_BYTES_LSB;
//                                                             axi_rd_addr_valid                <= 1'b1;
//                                                             axi_rd_req                       <= 1'b1;
//                                                             axi_wr_req                       <= 1'b0;
//                                                             tx_packet_1523_1548_bytes[47:32] <= axi_read_data[15:0];
//                                                       end
//                                             'd32      : begin
//                                                             axi_rd_addr                     <= ADDR_STAT_RX_PACKET_1523_1548_BYTES_MSB;
//                                                             axi_rd_addr_valid               <= 1'b1;
//                                                             axi_rd_req                      <= 1'b1;
//                                                             axi_wr_req                      <= 1'b0;
//                                                             rx_packet_1523_1548_bytes[31:0] <= axi_read_data;
//                                                       end
//                                             'd33      : begin
//                                                             axi_rd_addr                      <= ADDR_STAT_TX_PACKET_8192_9215_BYTES_LSB;
//                                                             axi_rd_addr_valid                <= 1'b1;
//                                                             axi_rd_req                       <= 1'b1;
//                                                             axi_wr_req                       <= 1'b0;
//                                                             rx_packet_1523_1548_bytes[47:32] <= axi_read_data[15:0];
//                                                       end
//                                             'd34      : begin
//                                                             axi_rd_addr                      <= ADDR_STAT_TX_PACKET_8192_9215_BYTES_MSB;
//                                                             axi_rd_addr_valid                <= 1'b1;
//                                                             axi_rd_req                       <= 1'b1;
//                                                             axi_wr_req                       <= 1'b0;
//                                                             tx_packet_8192_9215_bytes[31:0]  <= axi_read_data;
//                                                       end
//                                             'd35      : begin
//                                                             axi_rd_addr                      <= ADDR_STAT_RX_PACKET_8192_9215_BYTES_LSB;
//                                                             axi_rd_addr_valid                <= 1'b1;
//                                                             axi_rd_req                       <= 1'b1;
//                                                             axi_wr_req                       <= 1'b0;
//                                                             tx_packet_8192_9215_bytes[47:32] <= axi_read_data[15:0];
//                                                       end
//                                             'd36      : begin
//                                                             axi_rd_addr                      <= ADDR_STAT_RX_PACKET_8192_9215_BYTES_MSB;
//                                                             axi_rd_addr_valid                <= 1'b1;
//                                                             axi_rd_req                       <= 1'b1;
//                                                             axi_wr_req                       <= 1'b0;
//                                                             rx_packet_8192_9215_bytes[31:0]  <= axi_read_data;
//                                                       end
//                                             'd37      : begin
//                                                             rx_packet_8192_9215_bytes[47:32] <= axi_read_data[15:0];
//                                                             axi_wr_addr                      <= 32'h0;
//                                                             axi_wr_addr_valid                <= 1'b0;
//                                                             axi_wr_data_valid                <= 1'b0;
//                                                             axi_wr_strobe                    <= 4'h0;
//                                                             axi_rd_req                       <= 1'b0;
//                                                             axi_wr_req                       <= 1'b0;
//                                                             axi_rd_addr                      <= 32'd0;
//                                                             axi_rd_addr_valid                <= 1'b0;
//                                                       end
//                                              default : begin
//                                                             axi_wr_data                      <= 32'h0;
//                                                             axi_wr_addr                      <= 32'h0;
//                                                             axi_wr_addr_valid                <= 1'b0;
//                                                             axi_wr_data_valid                <= 1'b0;
//                                                             axi_wr_strobe                    <= 4'h0;
//                                                             axi_rd_req                       <= 1'b0;
//                                                             axi_wr_req                       <= 1'b0;
//                                                             axi_rd_addr                      <= 32'd0;
//                                                             axi_rd_addr_valid                <= 1'b0;
//                                                       end
//                                         endcase

                                         //// State transition
                                         if  (gt_locked_sync == 1'b0 || stat_rx_aligned_sync == 1'b0)
                                         begin
                                             axi_user_prestate <= STATE_AXI_IDLE;
                                         end
                                         else if  (rd_wr_cntr == 8'd37)
                                         begin
                                             axi_user_prestate <= STATE_READ_DONE;
                                         end
                                         else
                                             axi_user_prestate <= STATE_AXI_RD_WR;
                                     end
            STATE_READ_DONE          :
                                     begin
                                         rx_busy_led_r           <= 1'b0;
//                                         axi_rd_addr             <= 32'd0;
//                                         axi_rd_addr_valid       <= 1'b0;
//                                         axi_wr_data             <= 32'd0;
//                                         axi_wr_addr             <= 32'd0;
//                                         axi_wr_addr_valid       <= 1'b0;
//                                         axi_wr_data_valid       <= 1'b0;
//                                         axi_wr_strobe           <= 4'd0;
//                                         axi_rd_req              <= 1'b0;
//                                         axi_wr_req              <= 1'b0;
                                         rd_wr_cntr              <= 8'd0;
                                         init_rx_aligned         <= 1'b0;
                                         init_data_sanity        <= 1'b0;
                                         init_tx_rx_pause        <= 1'b0;
                                         init_stat_read          <= 1'b0;
                                         sanity_init_done_r      <= 1'b0;
                                         pause_init_done_r       <= 1'b0;

                                         $display( "               STAT_TX_TOTAL_PACKETS           = %d,     STAT_RX_TOTAL_PACKETS           = %d", tx_total_pkt, rx_total_pkt );
                                         $display( "               STAT_TX_TOTAL_GOOD_PACKETS      = %d,     STAT_RX_TOTAL_GOOD_PACKETS      = %d", tx_total_good_pkts, rx_total_good_pkts );
                                         $display( "               STAT_TX_TOTAL_BYTES             = %d,     STAT_RX_TOTAL_BYTES             = %d", tx_total_bytes, rx_total_bytes );
                                         $display( "               STAT_TX_TOTAL_GOOD_BYTES        = %d,     STAT_RX_TOTAL_GOOD_BYTES        = %d", tx_total_good_bytes, rx_total_good_bytes );
                                         $display( "               STAT_TX_PACKET_64_BYTES         = %d,     STAT_RX_PACKET_64_BYTES         = %d", tx_packet_64_bytes, rx_packet_64_bytes );
                                         $display( "               STAT_TX_PACKET_256_511_BYTES    = %d,     STAT_RX_PACKET_256_511_BYTES    = %d", tx_packet_256_511_bytes, rx_packet_256_511_bytes );
                                         $display( "               STAT_TX_PACKET_512_1023_BYTES   = %d,     STAT_RX_PACKET_512_1023_BYTES   = %d", tx_packet_512_1023_bytes, rx_packet_512_1023_bytes );
                                         $display( "               STAT_TX_PACKET_1523_1548_BYTES  = %d,     STAT_RX_PACKET_1523_1548_BYTES  = %d", tx_packet_1523_1548_bytes, rx_packet_1523_1548_bytes );
                                         $display( "               STAT_TX_PACKET_8192_9215_BYTES  = %d,     STAT_RX_PACKET_8192_9215_BYTES  = %d", tx_packet_8192_9215_bytes, rx_packet_8192_9215_bytes );
                                         $display( "           AXI4 Lite Read Completed" );
                                         //// State transition
                                         if  (gt_locked_sync == 1'b0 || stat_rx_aligned_sync == 1'b0)
                                             axi_user_prestate <= STATE_AXI_IDLE;
                                         else 
                                             axi_user_prestate <= STATE_TEST_DONE;
                                     end
             STATE_TEST_DONE         :
                                     begin
                                         rx_busy_led_r           <= 1'b0;
//                                         axi_rd_addr             <= 32'd0;
//                                         axi_rd_addr_valid       <= 1'b0;
//                                         axi_wr_data             <= 32'd0;
//                                         axi_wr_addr             <= 32'd0;
//                                         axi_wr_addr_valid       <= 1'b0;
//                                         axi_wr_data_valid       <= 1'b0;
//                                         axi_wr_strobe           <= 4'd0;
//                                         axi_rd_req              <= 1'b0;
//                                         axi_wr_req              <= 1'b0;
                                         rd_wr_cntr              <= 8'd0;
                                         init_rx_aligned         <= 1'b0;
                                         init_data_sanity        <= 1'b0;
                                         init_tx_rx_pause        <= 1'b0;
                                         init_stat_read          <= 1'b0;
                                         sanity_init_done_r      <= 1'b0;
                                         pause_init_done_r       <= 1'b0;

                                         //// State transition
                                         if  (gt_locked_sync == 1'b0 || stat_rx_aligned_sync == 1'b0)
                                             axi_user_prestate <= STATE_AXI_IDLE;
                                         else if (rx_busy_sync == 1'b1 && stat_rx_aligned_sync == 1'b1)
                                             axi_user_prestate <= STATE_WAIT_SANITY_DONE;
                                         else
                                             axi_user_prestate <= STATE_TEST_DONE;
                                     end
             STATE_INVALID_AXI_RD_WR :
                                     begin
                                         rx_busy_led_r           <= 1'b0;
//                                         axi_rd_addr             <= 32'd0;
//                                         axi_rd_addr_valid       <= 1'b0;
//                                         axi_wr_data             <= 32'd0;
//                                         axi_wr_addr             <= 32'd0;
//                                         axi_wr_addr_valid       <= 1'b0;
//                                         axi_wr_data_valid       <= 1'b0;
//                                         axi_wr_strobe           <= 4'd0;
//                                         axi_rd_req              <= 1'b0;
//                                         axi_wr_req              <= 1'b0;
                                         rd_wr_cntr              <= 8'd0;
                                         init_rx_aligned         <= 1'b0;
                                         init_data_sanity        <= 1'b0;
                                         init_tx_rx_pause        <= 1'b0;
                                         init_stat_read          <= 1'b0;
                                         sanity_init_done_r      <= 1'b0;
                                         pause_init_done_r       <= 1'b0;

                                         //// State transition
                                         if  (gt_locked_sync == 1'b0)
                                             axi_user_prestate <= STATE_AXI_IDLE;
                                         else
                                             axi_user_prestate <= STATE_INVALID_AXI_RD_WR;
                                     end
            default                  :
                                     begin
//                                         axi_rd_addr               <= 32'd0;
//                                         axi_rd_addr_valid         <= 1'b0;
//                                         axi_wr_data               <= 32'd0;
//                                         axi_read_data             <= 32'd0;
//                                         axi_wr_addr               <= 32'd0;
//                                         axi_wr_addr_valid         <= 1'b0;
//                                         axi_wr_data_valid         <= 1'b0;
//                                         axi_wr_strobe             <= 4'd0;
//                                         axi_rd_req                <= 1'b0;
//                                         axi_wr_req                <= 1'b0;
                                         rd_wr_cntr                <= 8'd0;
                                         init_rx_aligned           <= 1'b0;
                                         init_data_sanity          <= 1'b0;
                                         init_tx_rx_pause          <= 1'b0;
                                         init_stat_read            <= 1'b0;
                                         sanity_init_done_r        <= 1'b0;
                                         pause_init_done_r         <= 1'b0;
                                         tx_total_pkt              <= 48'd0;
                                         tx_total_bytes            <= 48'd0;
                                         tx_total_good_pkts        <= 48'd0;
                                         tx_total_good_bytes       <= 48'd0;
                                         tx_packet_64_bytes        <= 48'd0;
                                         tx_packet_256_511_bytes   <= 48'd0;
                                         tx_packet_512_1023_bytes  <= 48'd0;
                                         tx_packet_1523_1548_bytes <= 48'd0;
                                         tx_packet_8192_9215_bytes <= 48'd0;
                                         rx_busy_led_r             <= 1'b0;
                                         rx_total_pkt              <= 48'd0;
                                         rx_total_bytes            <= 48'd0;
                                         rx_total_good_pkts        <= 48'd0;
                                         rx_total_good_bytes       <= 48'd0;
                                         rx_packet_64_bytes        <= 48'd0;
                                         rx_packet_256_511_bytes   <= 48'd0;
                                         rx_packet_512_1023_bytes  <= 48'd0;
                                         rx_packet_1523_1548_bytes <= 48'd0;
                                         rx_packet_8192_9215_bytes <= 48'd0;
                                         axi_user_prestate         <= STATE_AXI_IDLE;
                                     end
            endcase
        end
    end

 
   cmac_usplus_100G_qsfp_a_0_cdc_sync_axi i_cmac_usplus_100G_qsfp_a_0_cmac_cdc_sync_sanity_init_done
  (
   .clk              (lbus_clk),
   .signal_in        (sanity_init_done_r), 
   .signal_out       (sanity_init_done)
  );
  
   cmac_usplus_100G_qsfp_a_0_cdc_sync_axi i_cmac_usplus_100G_qsfp_a_0_cmac_cdc_sync_pause_init_done
  (
   .clk              (lbus_clk),
   .signal_in        (pause_init_done_r), 
   .signal_out       (pause_init_done)
  );

   cmac_usplus_100G_qsfp_a_0_cdc_sync_axi i_cmac_usplus_100G_qsfp_a_0_cmac_cdc_sync_rx_gt_locked_led
  (
   .clk              (s_axi_aclk),
   .signal_in        (rx_gt_locked), 
   .signal_out       (gt_locked_sync)
  );
  
   cmac_usplus_100G_qsfp_a_0_cdc_sync_axi i_cmac_usplus_100G_qsfp_a_0_cmac_cdc_sync_stat_rx_aligned
  (
   .clk              (s_axi_aclk),
   .signal_in        (stat_rx_aligned), 
   .signal_out       (stat_rx_aligned_sync)
  );
 
   cmac_usplus_100G_qsfp_a_0_cdc_sync_axi i_cmac_usplus_100G_qsfp_a_0_cmac_cdc_sync_rx_done_led
  (
   .clk              (s_axi_aclk),
   .signal_in        (rx_done), 
   .signal_out       (rx_done_sync)
  );
 
  cmac_usplus_100G_qsfp_a_0_cdc_sync_axi i_cmac_usplus_100G_qsfp_a_0_cmac_cdc_sync_rx_busy
  (
   .clk              (s_axi_aclk),
   .signal_in        (rx_busy), 
   .signal_out       (rx_busy_sync)
  );

  assign rx_busy_led      = rx_busy_led_r;

  assign pm_tick_r        = s_axi_pm_tick;
    ////----------------------------------------END TX Module-----------------------//

endmodule


(* DowngradeIPIdentifiedWarnings="yes" *)
module cmac_usplus_100G_qsfp_a_0_cdc_sync_axi (
 input clk,
 input signal_in,
 output wire signal_out
);

                          wire sig_in_cdc_from ;
 (* ASYNC_REG = "TRUE" *) reg  s_out_d2_cdc_to;
 (* ASYNC_REG = "TRUE" *) reg  s_out_d3;

assign sig_in_cdc_from = signal_in;
assign signal_out      = s_out_d3;

always @(posedge clk)
begin
  s_out_d2_cdc_to  <= sig_in_cdc_from;
  s_out_d3         <= s_out_d2_cdc_to;
end

endmodule

