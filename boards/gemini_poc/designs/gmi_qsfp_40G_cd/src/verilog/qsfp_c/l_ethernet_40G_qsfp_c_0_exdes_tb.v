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

module l_ethernet_40G_qsfp_c_0_exdes_tb
(
);

    task  display_result;
        input [4:0] completion_status;
        begin
            if ( completion_status == 5'd1 ) 
               begin
                  $display("INFO : CORE TEST COMPLETED AND PASSED");
                  $display("INFO : Test Completed Successfully");
               end
            else begin
               $display("%c[1;31m",27);
               $display("******");
               case ( completion_status )
                 5'd0:  $display("ERROR@%0t : Test did not run.", $time );
                 5'd2:  $display("ERROR@%0t : No block lock on any lanes.", $time );
                 5'd3:  $display("ERROR@%0t : Not all lanes achieved block lock.", $time );
                 5'd4:  $display("ERROR@%0t : Some lanes lost block lock after achieving block lock.", $time );
                 5'd5:  $display("ERROR@%0t : No lane sync on any lanes.", $time );
                 5'd6:  $display("ERROR@%0t : Not all lanes achieved sync.", $time );
                 5'd7:  $display("ERROR@%0t : Some lanes lost sync after achieving sync.", $time );
                 5'd8:  $display("ERROR@%0t : No alignment status or rx_status was achieved.", $time );
                 5'd9:  $display("ERROR@%0t : Loss of alignment status or rx_status after both were achieved.", $time );
                 5'd10: $display("ERROR@%0t : TX timed out.", $time );
                 5'd11: $display("ERROR@%0t : No tx data was sent.", $time );
                 5'd12: $display("ERROR@%0t : Number of packets received did not equal the number of packets sent.", $time );
                 5'd13: $display("ERROR@%0t : Total number of bytes received did not equal the total number of bytes sent.", $time );
                 5'd14: $display("ERROR@%0t : An lbus protocol error was detected.", $time );
                 5'd15: $display("ERROR@%0t : Bit errors were detected in the received packets.", $time );
                 5'd31: $display("ERROR@%0t : Test is stuck in reset.", $time );
                 default: $display("ERROR@%0t : An invalid completion status (%h) was detected.", $time, completion_status );
               endcase
               $display("******");
               $display("%c[0m",27);
               $display("ERROR : All the Test Cases Completed but Failed with Errors/Warnings");
            end
        end
    endtask

    reg dclk;
    reg gt_refclk_p;
    reg gt_refclk_n;
    reg sys_reset;
    reg restart_tx_rx;
    wire gt_0_p_loopback;
    wire gt_0_n_loopback;
    wire gt_1_p_loopback;
    wire gt_1_n_loopback;
    wire gt_2_p_loopback;
    wire gt_2_n_loopback;
    wire gt_3_p_loopback;
    wire gt_3_n_loopback;
    wire rx_gt_locked_led;
    wire rx_aligned_led;
    wire [4:0] completion_status;

    reg timed_out;
    reg time_out_cntr_en;
    reg [24:0] time_out_cntr;

l_ethernet_40G_qsfp_c_0_exdes EXDES
(
    .gt_rxp_in_0(gt_0_p_loopback),
    .gt_rxn_in_0(gt_0_n_loopback),
    .gt_txp_out_0(gt_0_p_loopback),
    .gt_txn_out_0(gt_0_n_loopback),
    .gt_rxp_in_1(gt_1_p_loopback),
    .gt_rxn_in_1(gt_1_n_loopback),
    .gt_txp_out_1(gt_1_p_loopback),
    .gt_txn_out_1(gt_1_n_loopback),
    .gt_rxp_in_2(gt_2_p_loopback),
    .gt_rxn_in_2(gt_2_n_loopback),
    .gt_txp_out_2(gt_2_p_loopback),
    .gt_txn_out_2(gt_2_n_loopback),
    .gt_rxp_in_3(gt_3_p_loopback),
    .gt_rxn_in_3(gt_3_n_loopback),
    .gt_txp_out_3(gt_3_p_loopback),
    .gt_txn_out_3(gt_3_n_loopback),
    .rx_gt_locked_led(rx_gt_locked_led),
    .rx_aligned_led(rx_aligned_led),
    .completion_status(completion_status),
    .gt_refclk_p(gt_refclk_p),
    .gt_refclk_n(gt_refclk_n),
    .sys_reset(sys_reset),
    .restart_tx_rx(restart_tx_rx),
    .dclk(dclk)
);

    initial
    begin
        gt_refclk_p = 0;
        gt_refclk_n = 1;
        dclk = 0;
        sys_reset = 1;   
        restart_tx_rx = 0;   
        repeat (100) @(posedge dclk);
        sys_reset = 0;
        $display("INFO : SYS_RESET RELEASED TO 40G CORE");

        time_out_cntr_en = 1;
        $display("INFO : WAITING FOR THE GT LOCK..........");

        wait(rx_gt_locked_led || timed_out);

        if (rx_gt_locked_led)
            $display("INFO : GT LOCKED");
        else 
        begin
            $display("ERROR: GT LOCK FAILED - Timed Out");
            $finish; 
        end
        time_out_cntr_en = 0;

        $display("INFO : WAITING FOR RX_ALIGNED..........");
        repeat (1) @(posedge dclk);
     
        time_out_cntr_en = 1;
        wait(rx_aligned_led || timed_out);
        if(rx_aligned_led) 
        begin
            $display("INFO : RX ALIGNED");
            $display("INFO : CORE Version is 2.0");
        end
        else 
        begin
            $display("ERROR: RX ALIGNED FAILED - Timed Out");
            $finish; 
        end
        time_out_cntr_en = 0;

        wait ( ( completion_status != 5'h1F ) && ( completion_status != 5'h0 ) ) ;

        repeat(10) #1_000_000_000;         // wait for 10 more us

        display_result(completion_status);

        $display(" ");
        $display("INFO : ***** PACKET GENERATION RESTARTED *****");
        $display(" ");

        restart_tx_rx = 1;   
        repeat (100) @(posedge dclk);
        restart_tx_rx = 0;  

        wait ( ( completion_status != 5'h1F ) && ( completion_status != 5'h0 ) ) ;
        repeat(10) #1_000_000_000;         // wait for 10 more us

        display_result(completion_status); 


        
        $finish; 

    end

    //////////////////////////////////////////////////
    ////time_out_cntr signal generation Max 26ms
    //////////////////////////////////////////////////
    always @( posedge dclk or negedge sys_reset )
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


    initial
    begin
        gt_refclk_p =1;
        forever #3103030.303   gt_refclk_p = ~ gt_refclk_p;
    end

    initial
    begin
        gt_refclk_n =0;
        forever #3103030.303   gt_refclk_n = ~ gt_refclk_n;
    end

    initial
    begin
        dclk =1;
        forever #5000000.000   dclk = ~ dclk;
    end

endmodule
