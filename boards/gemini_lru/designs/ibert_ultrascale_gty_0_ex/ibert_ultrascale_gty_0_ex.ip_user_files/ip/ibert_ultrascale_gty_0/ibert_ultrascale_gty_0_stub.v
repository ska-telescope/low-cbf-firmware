// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.4 (lin64) Build 2086221 Fri Dec 15 20:54:30 MST 2017
// Date        : Tue Jun 12 15:20:39 2018
// Host        : dop350 running 64-bit Ubuntu 16.04.4 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/hiemstra/svnlowcbf/LOWCBF/Firmware/build/lru/vivado/lru_qsfp_mbobc_25G_ibert_build_180111_153000/ibert_ultrascale_gty_0_ex/ibert_ultrascale_gty_0_ex.srcs/sources_1/ip/ibert_ultrascale_gty_0/ibert_ultrascale_gty_0_stub.v
// Design      : ibert_ultrascale_gty_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xcvu9p-flga2577-2L-e-es1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "ibert_ultrascale_gty,Vivado 2017.4" *)
module ibert_ultrascale_gty_0(txn_o, txp_o, rxn_i, rxp_i, gtrefclk0_i, 
  gtrefclk1_i, gtnorthrefclk0_i, gtnorthrefclk1_i, gtsouthrefclk0_i, gtsouthrefclk1_i, 
  gtrefclk00_i, gtrefclk10_i, gtrefclk01_i, gtrefclk11_i, gtnorthrefclk00_i, 
  gtnorthrefclk10_i, gtnorthrefclk01_i, gtnorthrefclk11_i, gtsouthrefclk00_i, 
  gtsouthrefclk10_i, gtsouthrefclk01_i, gtsouthrefclk11_i, clk)
/* synthesis syn_black_box black_box_pad_pin="txn_o[51:0],txp_o[51:0],rxn_i[51:0],rxp_i[51:0],gtrefclk0_i[12:0],gtrefclk1_i[12:0],gtnorthrefclk0_i[12:0],gtnorthrefclk1_i[12:0],gtsouthrefclk0_i[12:0],gtsouthrefclk1_i[12:0],gtrefclk00_i[12:0],gtrefclk10_i[12:0],gtrefclk01_i[12:0],gtrefclk11_i[12:0],gtnorthrefclk00_i[12:0],gtnorthrefclk10_i[12:0],gtnorthrefclk01_i[12:0],gtnorthrefclk11_i[12:0],gtsouthrefclk00_i[12:0],gtsouthrefclk10_i[12:0],gtsouthrefclk01_i[12:0],gtsouthrefclk11_i[12:0],clk" */;
  output [51:0]txn_o;
  output [51:0]txp_o;
  input [51:0]rxn_i;
  input [51:0]rxp_i;
  input [12:0]gtrefclk0_i;
  input [12:0]gtrefclk1_i;
  input [12:0]gtnorthrefclk0_i;
  input [12:0]gtnorthrefclk1_i;
  input [12:0]gtsouthrefclk0_i;
  input [12:0]gtsouthrefclk1_i;
  input [12:0]gtrefclk00_i;
  input [12:0]gtrefclk10_i;
  input [12:0]gtrefclk01_i;
  input [12:0]gtrefclk11_i;
  input [12:0]gtnorthrefclk00_i;
  input [12:0]gtnorthrefclk10_i;
  input [12:0]gtnorthrefclk01_i;
  input [12:0]gtnorthrefclk11_i;
  input [12:0]gtsouthrefclk00_i;
  input [12:0]gtsouthrefclk10_i;
  input [12:0]gtsouthrefclk01_i;
  input [12:0]gtsouthrefclk11_i;
  input clk;
endmodule
