//Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2016.2 (lin64) Build 1577090 Thu Jun  2 16:32:35 MDT 2016
//Date        : Wed Sep 28 15:45:53 2016
//Host        : dop350 running 64-bit openSUSE 13.2 (Harlequin) (x86_64)
//Command     : generate_target vcu108_led_axi_wrapper.bd
//Design      : vcu108_led_axi_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module vcu108_led_axi_wrapper
   (axi_led_out,
    clock_rtl,
    reset_rtl);
  output [3:0]axi_led_out;
  input clock_rtl;
  input reset_rtl;

  wire [3:0]axi_led_out;
  wire clock_rtl;
  wire reset_rtl;

  vcu108_led_axi vcu108_led_axi_i
       (.axi_led_out(axi_led_out),
        .clock_rtl(clock_rtl),
        .reset_rtl(reset_rtl));
endmodule
