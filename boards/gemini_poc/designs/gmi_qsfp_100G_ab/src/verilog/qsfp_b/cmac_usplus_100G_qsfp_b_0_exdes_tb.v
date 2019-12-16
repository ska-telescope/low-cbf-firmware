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

module cmac_usplus_100G_qsfp_b_0_exdes_tb
(
);

  parameter       OPERATION = 3;
  `define         PKT_GEN  0
  `define         PKT_MON  1
  `define         GT_LOCK  2
  `define         RX_ALIGN 3

    task  display_result;
        input [1:0] module_name;
        input test_result, timeout;
        begin
            if (timeout== 1'b1)
            begin
                if (module_name == 2'd0)
                    $display("ERROR : Packet Generator failed - Time Out Error");
                else if  (module_name == 2'd1)
                    $display("ERROR : Packet Monitor failed - Time Out Error");
                else if  (module_name == 2'd2)
                    $display("ERROR : GT LOCK failed - Time Out Error");
                else if  (module_name == 2'd3)
                    $display("ERROR : Rx_Aligned failed - Time Out Error");
                
            $display("ERROR : Time Out Error");
            $finish;
            end
            else if (test_result == 1'b1)
            begin 
                if (module_name == 2'd0)
                    $display("WARNING : Packets generation stopped due to tx_ovfout / tx_unfout");
                else
                    $display("ERROR : ALL PACKETS RECEIVED, WITH ERRORS");
            end
            else 
            begin 
                if (module_name == 2'd0)
                    $display("INFO : ALL PACKETS SENT, NO ERRORS");
                else if (module_name == 2'd1)
                    $display("INFO : ALL PACKETS RECEIVED, NO ERRORS");
                else if (module_name == 2'd2)
                    $display("INFO : GT LOCKED");
                else if (module_name == 2'd3)
                    $display("INFO : RX-ALIGNED");
            end
        end
   endtask

    reg             init_clk;
    reg             gt_ref_clk_p;
    reg             gt_ref_clk_n;
    reg             sys_reset;
    reg             s_axi_pm_tick;
    reg             test_fail;
    reg             timed_out;
    reg             time_out_cntr_en;
    reg  [23 :0]    time_out_cntr;

    wire            gt0_p_loopback;
    wire            gt0_n_loopback;
    wire            gt1_p_loopback;
    wire            gt1_n_loopback;
    wire            gt2_p_loopback;
    wire            gt2_n_loopback;
    wire            gt3_p_loopback;
    wire            gt3_n_loopback;

    reg             lbus_tx_rx_restart_in;
             
             
    wire            tx_done_led;
    wire            tx_busy_led;

    wire            rx_gt_locked_led;
    wire            rx_aligned_led;
    wire            rx_done_led;
    wire            rx_data_fail_led;
    wire            rx_busy_led;

cmac_usplus_100G_qsfp_b_0_exdes EXDES
(
.gt_ref_clk_p                    (gt_ref_clk_p),
.gt_ref_clk_n                    (gt_ref_clk_n),
.sys_reset                       (sys_reset),
.s_axi_pm_tick                   (s_axi_pm_tick),
.lbus_tx_rx_restart_in           (lbus_tx_rx_restart_in),
.tx_done_led                     (tx_done_led),
.tx_busy_led                     (tx_busy_led),
.rx_gt_locked_led                (rx_gt_locked_led),
.rx_aligned_led                  (rx_aligned_led),
.rx_done_led                     (rx_done_led),
.rx_data_fail_led                (rx_data_fail_led),
.rx_busy_led                     (rx_busy_led),
.gt0_rxp_in                      (gt0_p_loopback),
.gt0_rxn_in                      (gt0_n_loopback),
.gt1_rxp_in                      (gt1_p_loopback),
.gt1_rxn_in                      (gt1_n_loopback),
.gt2_rxp_in                      (gt2_p_loopback),
.gt2_rxn_in                      (gt2_n_loopback),
.gt3_rxp_in                      (gt3_p_loopback),
.gt3_rxn_in                      (gt3_n_loopback),
.gt0_txp_out                     (gt0_p_loopback),
.gt0_txn_out                     (gt0_n_loopback),
.gt1_txp_out                     (gt1_p_loopback),
.gt1_txn_out                     (gt1_n_loopback),
.gt2_txp_out                     (gt2_p_loopback),
.gt2_txn_out                     (gt2_n_loopback),
.gt3_txp_out                     (gt3_p_loopback),
.gt3_txn_out                     (gt3_n_loopback),

.init_clk                        (init_clk)
);

    initial
    begin
      gt_ref_clk_p = 0;
      gt_ref_clk_n = 1;
      init_clk   = 0;
      sys_reset  = 1;   
      lbus_tx_rx_restart_in = 0;
      s_axi_pm_tick = 1'b0;

      repeat (100) @(posedge init_clk);
      sys_reset = 0;
      $display("INFO : SYS_RESET RELEASED TO CMAC IP");

      $display("INFO : WAITING FOR THE GT LOCK..........");
      time_out_cntr_en = 1;
      if (OPERATION == 0)
      begin
          $display("ERROR : Invalid Operation");
          $display("INFO  : Test FAILED");
          $finish;
      end

      wait(rx_gt_locked_led || timed_out);
             
      time_out_cntr_en = 0;

             
      repeat (1) @(posedge init_clk);
      time_out_cntr_en = 1;

      wait (rx_aligned_led || timed_out);
             
      time_out_cntr_en = 0;

      repeat (1) @(posedge init_clk);
      lbus_tx_rx_restart_in = 0;
      s_axi_pm_tick = 1'b0;
             

             
      wait(tx_done_led);
      display_result(`PKT_GEN, 1'b0, 1'b0);
      wait(rx_done_led);
      display_result(`PKT_MON, rx_data_fail_led, 1'b0);
      //// To drive the s_axi_pm_tick from TB, please un-comment the below lines and use
      // repeat (262) @(posedge init_clk);  //// Clock delay after pause operation to assert s_axi_pm_tick
      // s_axi_pm_tick = 1'b1;                 //// If the user wishes to provide the pm tick thru the s_axi_pm_tick input pin, assign 1'b1 else 1'b0
      //                                    //// If input pin s_axi_pm_tick = 1'b0, then AXI pm tick write 1'b1 will happen thru AXI interface
      // repeat (1) @(posedge init_clk);
      // s_axi_pm_tick = 1'b0;
      wait((!tx_busy_led) && (!rx_busy_led));

      repeat (5) @(posedge init_clk);

      $display(" ");
      $display("INFO : ***** PACKET GENERATION RESTARTED *****");
      $display(" ");
             
      lbus_tx_rx_restart_in = 1;
      repeat (4) @(posedge init_clk);
      lbus_tx_rx_restart_in = 0;

      wait((!tx_done_led) && (!rx_done_led));
      wait(tx_done_led);
      display_result(`PKT_GEN, 1'b0, 1'b0);
      wait(rx_done_led);
      display_result(`PKT_MON, rx_data_fail_led, 1'b0);
      //// To drive the s_axi_pm_tick from TB, please un-comment the below lines and use
      // repeat (262) @(posedge init_clk);  //// Clock delay after pause operation to assert s_axi_pm_tick
      // s_axi_pm_tick = 1'b1;                 //// If the user wishes to provide the pm tick thru the s_axi_pm_tick input pin, assign 1'b1 else 1'b0
      //                                    //// If input pin s_axi_pm_tick = 1'b0, then AXI pm tick write 1'b1 will happen thru AXI interface
      // repeat (1) @(posedge init_clk);
      // s_axi_pm_tick = 1'b0;
      wait((!tx_busy_led) && (!rx_busy_led));


      repeat (500) @(posedge init_clk);

      if (test_fail == 1'b1)
           $display("ERROR : All the Test Cases Completed but Failed with Errors/Warnings");
      else     
           $display("INFO : Test Completed Successfully");

      $finish;
          
    end

    //////////////////////////////////////////////////
    ////time_out_cntr signal generation Max 26ms
    //////////////////////////////////////////////////
    always @( posedge init_clk or negedge sys_reset )
    begin
        if ( sys_reset == 1'b1 )
        begin
            timed_out     <= 1'b0;
            time_out_cntr <= 24'd0;
        end
        else
        begin
            timed_out <= time_out_cntr[20];
            if (time_out_cntr_en == 1'b1)
                time_out_cntr <= time_out_cntr + 24'd1;
            else
                time_out_cntr <= 24'd0;
        end
    end

    //////////////////////////////////////////////////
    ////test_fail signal generation
    //////////////////////////////////////////////////
    always @( posedge init_clk or posedge sys_reset )
    begin
        if ( sys_reset == 1'b1 )
        begin
            test_fail     <= 1'b0;
        end
        else
        begin
            if (rx_data_fail_led == 1'b1)
                test_fail <= 1'b1;
        end
    end

    initial
    begin
        gt_ref_clk_p =1;
        forever #3103.030   gt_ref_clk_p = ~ gt_ref_clk_p;
    end

    initial
    begin
        gt_ref_clk_n =0;
        forever #3103.030   gt_ref_clk_n = ~ gt_ref_clk_n;
    end

    initial
    begin
        init_clk =1;
        forever #4000.000 init_clk = ~init_clk;
    end

endmodule

