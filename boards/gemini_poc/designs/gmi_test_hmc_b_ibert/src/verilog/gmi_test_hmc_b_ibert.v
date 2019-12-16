
// file: ibert_ultrascaleplus_gty_0.v
//////////////////////////////////////////////////////////////////////////////
//   ____  ____ 
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version : 2012.3
//  \   \         Application : IBERT Ultrascale 
//  /   /         Filename : example_ibert_ultrascaleplus_gty_0
// /___/   /\     
// \   \  /  \ 
//  \___\/\___\
//
//
// Module example_ibert_ultrascaleplus_gty_0
// Generated by Xilinx IBERT_Ultrascale 
//////////////////////////////////////////////////////////////////////////////


`define C_NUM_GTY_QUADS 4
`define C_GTY_REFCLKS_USED 4
//module example_ibert_ultrascaleplus_gty_0
module gmi_test_hmc_b_ibert
(
  // GT top level ports
  output [(4*`C_NUM_GTY_QUADS)-1:0]		gty_txn_o,
  output [(4*`C_NUM_GTY_QUADS)-1:0]		gty_txp_o,
  input  [(4*`C_NUM_GTY_QUADS)-1:0]    	gty_rxn_i,
  input  [(4*`C_NUM_GTY_QUADS)-1:0]   	gty_rxp_i,
  input                           	gty_sysclkp_i,
  input                           	gty_sysclkn_i,
  input  [`C_GTY_REFCLKS_USED-1:0]      gty_refclk0p_i,
  input  [`C_GTY_REFCLKS_USED-1:0]      gty_refclk0n_i,
  input  [`C_GTY_REFCLKS_USED-1:0]      gty_refclk1p_i,
  input  [`C_GTY_REFCLKS_USED-1:0]      gty_refclk1n_i,
   input [0:0]ferr_n_tri_i,
   //output [0:0]hmc_refclk_sel_tri_o,
   inout iic_main_scl_io,
   inout iic_main_sda_io,
   //output [2:0]iic_mux_reset_b,
   //output [1:0]lxrxps_tri_o,
   //input [1:0]lxtxps_tri_i,
   //output [1:0]refclk_boot_tri_o,
   input reset,
   input rs232_uart_rxd,
   output rs232_uart_txd
);

  //
  // Ibert refclk internal signals
  //
   wire  [`C_NUM_GTY_QUADS-1:0]    gty_qrefclk0_i;
   wire  [`C_NUM_GTY_QUADS-1:0]    gty_qrefclk1_i;
   wire  [`C_NUM_GTY_QUADS-1:0]    gty_qnorthrefclk0_i;
   wire  [`C_NUM_GTY_QUADS-1:0]    gty_qnorthrefclk1_i;        	
   wire  [`C_NUM_GTY_QUADS-1:0]    gty_qsouthrefclk0_i;
   wire  [`C_NUM_GTY_QUADS-1:0]    gty_qsouthrefclk1_i;
   wire  [`C_NUM_GTY_QUADS-1:0]    gty_qrefclk00_i;
   wire  [`C_NUM_GTY_QUADS-1:0]    gty_qrefclk10_i;
   wire  [`C_NUM_GTY_QUADS-1:0]    gty_qrefclk01_i;
   wire  [`C_NUM_GTY_QUADS-1:0]    gty_qrefclk11_i;  
   wire  [`C_NUM_GTY_QUADS-1:0]    gty_qnorthrefclk00_i;
   wire  [`C_NUM_GTY_QUADS-1:0]    gty_qnorthrefclk10_i;
   wire  [`C_NUM_GTY_QUADS-1:0]    gty_qnorthrefclk01_i;
   wire  [`C_NUM_GTY_QUADS-1:0]    gty_qnorthrefclk11_i;  
   wire  [`C_NUM_GTY_QUADS-1:0]    gty_qsouthrefclk00_i;
   wire  [`C_NUM_GTY_QUADS-1:0]    gty_qsouthrefclk10_i;
   wire  [`C_NUM_GTY_QUADS-1:0]    gty_qsouthrefclk01_i;
   wire  [`C_NUM_GTY_QUADS-1:0]    gty_qsouthrefclk11_i; 
   wire  [`C_GTY_REFCLKS_USED-1:0] gty_refclk0_i;
   wire  [`C_GTY_REFCLKS_USED-1:0] gty_refclk1_i;
   wire  [`C_GTY_REFCLKS_USED-1:0] gty_odiv2_0_i;
   wire  [`C_GTY_REFCLKS_USED-1:0] gty_odiv2_1_i;
   wire                        gty_sysclk_i;

 //wire [0:0]ferr_n_tri_i;
  wire [0:0]hmc_refclk_sel_tri_o;
  wire iic_main_scl_i;
  //wire iic_main_scl_io;
  wire iic_main_scl_o;
  wire iic_main_scl_t;
  wire iic_main_sda_i;
  //wire iic_main_sda_io;
  wire iic_main_sda_o;
  wire iic_main_sda_t;
  wire [2:0]iic_mux_reset_b;
  wire [1:0]lxrxps_tri_o;
  wire [1:0]lxtxps_tri_i;
  wire [1:0]refclk_boot_tri_o;
  //wire reset;
  //wire rs232_uart_rxd;
  //wire rs232_uart_txd;
  
  //
  // Refclk IBUFDS instantiations
  //

    IBUFDS_GTE4 u_buf_q10_clk0
      (
        .O            (gty_refclk0_i[0]),
        .ODIV2        (gty_odiv2_0_i[0]),
        .CEB          (1'b0),
        .I            (gty_refclk0p_i[0]),
        .IB           (gty_refclk0n_i[0])
      );

    IBUFDS_GTE4 u_buf_q10_clk1
      (
        .O            (gty_refclk1_i[0]),
        .ODIV2        (gty_odiv2_1_i[0]),
        .CEB          (1'b0),
        .I            (gty_refclk1p_i[0]),
        .IB           (gty_refclk1n_i[0])
      );

    IBUFDS_GTE4 u_buf_q11_clk0
      (
        .O            (gty_refclk0_i[1]),
        .ODIV2        (gty_odiv2_0_i[1]),
        .CEB          (1'b0),
        .I            (gty_refclk0p_i[1]),
        .IB           (gty_refclk0n_i[1])
      );

    IBUFDS_GTE4 u_buf_q11_clk1
      (
        .O            (gty_refclk1_i[1]),
        .ODIV2        (gty_odiv2_1_i[1]),
        .CEB          (1'b0),
        .I            (gty_refclk1p_i[1]),
        .IB           (gty_refclk1n_i[1])
      );

    IBUFDS_GTE4 u_buf_q12_clk0
      (
        .O            (gty_refclk0_i[2]),
        .ODIV2        (gty_odiv2_0_i[2]),
        .CEB          (1'b0),
        .I            (gty_refclk0p_i[2]),
        .IB           (gty_refclk0n_i[2])
      );

    IBUFDS_GTE4 u_buf_q12_clk1
      (
        .O            (gty_refclk1_i[2]),
        .ODIV2        (gty_odiv2_1_i[2]),
        .CEB          (1'b0),
        .I            (gty_refclk1p_i[2]),
        .IB           (gty_refclk1n_i[2])
      );

    IBUFDS_GTE4 u_buf_q13_clk0
      (
        .O            (gty_refclk0_i[3]),
        .ODIV2        (gty_odiv2_0_i[3]),
        .CEB          (1'b0),
        .I            (gty_refclk0p_i[3]),
        .IB           (gty_refclk0n_i[3])
      );

    IBUFDS_GTE4 u_buf_q13_clk1
      (
        .O            (gty_refclk1_i[3]),
        .ODIV2        (gty_odiv2_1_i[3]),
        .CEB          (1'b0),
        .I            (gty_refclk1p_i[3]),
        .IB           (gty_refclk1n_i[3])
      );


  //
  // Refclk connection from each IBUFDS to respective quads depending on the source selected in gui
  //
  assign gty_qrefclk0_i[0] = gty_refclk0_i[0];
  assign gty_qrefclk1_i[0] = gty_refclk1_i[0];
  assign gty_qnorthrefclk0_i[0] = 1'b0;
  assign gty_qnorthrefclk1_i[0] = 1'b0;
  assign gty_qsouthrefclk0_i[0] = 1'b0;
  assign gty_qsouthrefclk1_i[0] = 1'b0;
//GTYE4_COMMON clock connection
  assign gty_qrefclk00_i[0] = gty_refclk0_i[0];
  assign gty_qrefclk10_i[0] = gty_refclk1_i[0];
  assign gty_qrefclk01_i[0] = 1'b0;
  assign gty_qrefclk11_i[0] = 1'b0;  
  assign gty_qnorthrefclk00_i[0] = 1'b0;
  assign gty_qnorthrefclk10_i[0] = 1'b0;
  assign gty_qnorthrefclk01_i[0] = 1'b0;
  assign gty_qnorthrefclk11_i[0] = 1'b0;  
  assign gty_qsouthrefclk00_i[0] = 1'b0;
  assign gty_qsouthrefclk10_i[0] = 1'b0;  
  assign gty_qsouthrefclk01_i[0] = 1'b0;
  assign gty_qsouthrefclk11_i[0] = 1'b0; 
 

  assign gty_qrefclk0_i[1] = gty_refclk0_i[1];
  assign gty_qrefclk1_i[1] = gty_refclk1_i[1];
  assign gty_qnorthrefclk0_i[1] = 1'b0;
  assign gty_qnorthrefclk1_i[1] = 1'b0;
  assign gty_qsouthrefclk0_i[1] = 1'b0;
  assign gty_qsouthrefclk1_i[1] = 1'b0;
//GTYE4_COMMON clock connection
  assign gty_qrefclk00_i[1] = gty_refclk0_i[1];
  assign gty_qrefclk10_i[1] = gty_refclk1_i[1];
  assign gty_qrefclk01_i[1] = 1'b0;
  assign gty_qrefclk11_i[1] = 1'b0;  
  assign gty_qnorthrefclk00_i[1] = 1'b0;
  assign gty_qnorthrefclk10_i[1] = 1'b0;
  assign gty_qnorthrefclk01_i[1] = 1'b0;
  assign gty_qnorthrefclk11_i[1] = 1'b0;  
  assign gty_qsouthrefclk00_i[1] = 1'b0;
  assign gty_qsouthrefclk10_i[1] = 1'b0;  
  assign gty_qsouthrefclk01_i[1] = 1'b0;
  assign gty_qsouthrefclk11_i[1] = 1'b0; 
 

  assign gty_qrefclk0_i[2] = gty_refclk0_i[2];
  assign gty_qrefclk1_i[2] = gty_refclk1_i[2];
  assign gty_qnorthrefclk0_i[2] = 1'b0;
  assign gty_qnorthrefclk1_i[2] = 1'b0;
  assign gty_qsouthrefclk0_i[2] = 1'b0;
  assign gty_qsouthrefclk1_i[2] = 1'b0;
//GTYE4_COMMON clock connection
  assign gty_qrefclk00_i[2] = gty_refclk0_i[2];
  assign gty_qrefclk10_i[2] = gty_refclk1_i[2];
  assign gty_qrefclk01_i[2] = 1'b0;
  assign gty_qrefclk11_i[2] = 1'b0;  
  assign gty_qnorthrefclk00_i[2] = 1'b0;
  assign gty_qnorthrefclk10_i[2] = 1'b0;
  assign gty_qnorthrefclk01_i[2] = 1'b0;
  assign gty_qnorthrefclk11_i[2] = 1'b0;  
  assign gty_qsouthrefclk00_i[2] = 1'b0;
  assign gty_qsouthrefclk10_i[2] = 1'b0;  
  assign gty_qsouthrefclk01_i[2] = 1'b0;
  assign gty_qsouthrefclk11_i[2] = 1'b0; 
 

  assign gty_qrefclk0_i[3] = gty_refclk0_i[3];
  assign gty_qrefclk1_i[3] = gty_refclk1_i[3];
  assign gty_qnorthrefclk0_i[3] = 1'b0;
  assign gty_qnorthrefclk1_i[3] = 1'b0;
  assign gty_qsouthrefclk0_i[3] = 1'b0;
  assign gty_qsouthrefclk1_i[3] = 1'b0;
//GTYE4_COMMON clock connection
  assign gty_qrefclk00_i[3] = gty_refclk0_i[3];
  assign gty_qrefclk10_i[3] = gty_refclk1_i[3];
  assign gty_qrefclk01_i[3] = 1'b0;
  assign gty_qrefclk11_i[3] = 1'b0;  
  assign gty_qnorthrefclk00_i[3] = 1'b0;
  assign gty_qnorthrefclk10_i[3] = 1'b0;
  assign gty_qnorthrefclk01_i[3] = 1'b0;
  assign gty_qnorthrefclk11_i[3] = 1'b0;  
  assign gty_qsouthrefclk00_i[3] = 1'b0;
  assign gty_qsouthrefclk10_i[3] = 1'b0;  
  assign gty_qsouthrefclk01_i[3] = 1'b0;
  assign gty_qsouthrefclk11_i[3] = 1'b0; 
 

  //
  // Sysclock IBUFDS instantiation
  //
  IBUFGDS 
   #(.DIFF_TERM("FALSE"))
   u_ibufgds
    (
      .I(gty_sysclkp_i),
      .IB(gty_sysclkn_i),
      .O(gty_sysclk_i)
    );


  //
  // IBERT core instantiation
  //
  ibert_ultrascaleplus_gty_0 u_ibert_gty_core
    (
      .txn_o(gty_txn_o),
      .txp_o(gty_txp_o),
      .rxn_i(gty_rxn_i),
      .rxp_i(gty_rxp_i),
      .clk(gty_sysclk_i),
      .gtrefclk0_i(gty_qrefclk0_i),
      .gtrefclk1_i(gty_qrefclk1_i),
      .gtnorthrefclk0_i(gty_qnorthrefclk0_i),
      .gtnorthrefclk1_i(gty_qnorthrefclk1_i),
      .gtsouthrefclk0_i(gty_qsouthrefclk0_i),
      .gtsouthrefclk1_i(gty_qsouthrefclk1_i),
      .gtrefclk00_i(gty_qrefclk00_i),
      .gtrefclk10_i(gty_qrefclk10_i),
      .gtrefclk01_i(gty_qrefclk01_i),
      .gtrefclk11_i(gty_qrefclk11_i),
      .gtnorthrefclk00_i(gty_qnorthrefclk00_i),
      .gtnorthrefclk10_i(gty_qnorthrefclk10_i),
      .gtnorthrefclk01_i(gty_qnorthrefclk01_i),
      .gtnorthrefclk11_i(gty_qnorthrefclk11_i),
      .gtsouthrefclk00_i(gty_qsouthrefclk00_i),
      .gtsouthrefclk10_i(gty_qsouthrefclk10_i),
      .gtsouthrefclk01_i(gty_qsouthrefclk01_i),
      .gtsouthrefclk11_i(gty_qsouthrefclk11_i)
    );

  IOBUF iic_main_scl_iobuf
       (.I(iic_main_scl_o),
        .IO(iic_main_scl_io),
        .O(iic_main_scl_i),
        .T(iic_main_scl_t));
  IOBUF iic_main_sda_iobuf
       (.I(iic_main_sda_o),
        .IO(iic_main_sda_io),
        .O(iic_main_sda_i),
        .T(iic_main_sda_t));
  system system_i
       (.FERR_N_tri_i(ferr_n_tri_i),
        .HMC_REFCLK_SEL_tri_o(hmc_refclk_sel_tri_o),
        .LxRXPS_tri_o(lxrxps_tri_o),
        .LxTXPS_tri_i(lxtxps_tri_i),
        .REFCLK_BOOT_tri_o(refclk_boot_tri_o),
        .gty_sysclk_i(gty_sysclk_i),
        .iic_main_scl_i(iic_main_scl_i),
        .iic_main_scl_o(iic_main_scl_o),
        .iic_main_scl_t(iic_main_scl_t),
        .iic_main_sda_i(iic_main_sda_i),
        .iic_main_sda_o(iic_main_sda_o),
        .iic_main_sda_t(iic_main_sda_t),
        .iic_mux_reset_b(iic_mux_reset_b),
        .reset(reset),
        .rs232_uart_rxd(rs232_uart_rxd),
        .rs232_uart_txd(rs232_uart_txd));


endmodule
