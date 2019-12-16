//-----------------------------------------------------------------------------
//
// (c) Copyright 2012-2012 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : The Xilinx HMC Host Controller  
// File       : hmc_core_example.v
// Version    : 1.0  
//-----------------------------------------------------------------------------

//==============================================================================
// hmc_core example design
//==============================================================================
`timescale 1ns/1ps
module hmc_core_d
  #(parameter HMC_VER       = 1       ,  // HMC standard version; 1:Gen2; 2:Gen3
  parameter N_FLIT          = 4,  // number of FLITs
  parameter FULL_WIDTH      = 1,  // HMC full-width (1) or half-width (0)
  parameter GT_NUM_CHANNEL  = 16,  // Number of GT lanes
  parameter GT_USE_GTH      = 0,  // By default, uses GTH to establish HMC links
  parameter GT_SPEED        = 15,  // GT speed (10/12.5/15/25/28/30)
  parameter GT_REFCLK_FREQ  = 125,  // GT reference clock frequency (125Mhz/156.25Mhz/166.67Mhz/312.5Mhz)
  parameter DEV_CUB_ID      =3'b000          ,  // HMC device CUB-ID
  parameter HMC_DEV_LINK_ID=1'b0,           // HMC DEVICE link ID
  parameter IIC_MUX_ADDR    =7'h74,             // IIC MUX ADDRESS
  parameter IIC_HMC_ADDR    =7'h14,             // HMC device IIC address
  parameter TGEN_SIM_F      =0
  ) (
     input                               rst
    ,input                               clk_free
    // HMC-Device interface
    ,input                               refclk_p
    ,input                               refclk_n
    ,output wire    [GT_NUM_CHANNEL-1:0] txp
    ,output wire    [GT_NUM_CHANNEL-1:0] txn
    ,input          [GT_NUM_CHANNEL-1:0] rxp
    ,input          [GT_NUM_CHANNEL-1:0] rxn
    ,input                               lxrxps
    ,output wire                         lxtxps
    ,output wire                         device_p_rst_n
    ,output wire                         HMC_REFCLK_BOOT_0
    ,output wire                         HMC_REFCLK_BOOT_1
    ,output wire                         HMC_REFCLK_SEL
    ,input                               HMC_FERR_B
    // Hardware control for evaluation board
    ,inout  wire                         IIC_MAIN_SCL_LS
    ,inout  wire                         IIC_MAIN_SDA_LS
    ,output wire                         IIC_MUX_RESET_B_LS
    ,output wire                         SI5328_RST_N_LS
    ,output wire                         SM_FAN_PWM     //HMC device fan 
    ,output wire                         SM_FAN_TACH    //FPGA fan
    ,output wire                         GPIO_LED_0_LS
    ,output wire                         GPIO_LED_1_LS
    ,output wire                         GPIO_LED_2_LS
    ,output wire                         GPIO_LED_3_LS
    ,output wire                         GPIO_LED_4_LS
    ,output wire                         GPIO_LED_5_LS
    ,output wire                         GPIO_LED_6_LS
    ,output wire                         GPIO_LED_7_LS
  );


localparam FLIT_W = 128;                           // FLIT width (bits)
localparam HMCC_TOKEN = 512;                       // HMC-Controller initial token #
localparam HMC_TOKEN = 32'd240;                    // HMC-device initial token #
localparam CSR_ADDR_WIDTH = 10;                    // HMC-Controller CSR address width
localparam GT_USE_GTY = (GT_USE_GTH==0) ? 1 : 0;   // Uses GTY to establish HMC links
localparam AXI4_UID_W = (HMC_VER==1) ? 9 : 11;     // AXI4MM User-ID width (bits)
localparam AXI4_CMD_W = (HMC_VER==1) ? 6 : 7;      // AXI4MM CMD width (bits)
localparam AXI4_AUSER_W = AXI4_CMD_W+3;            // AXI4MM AxUSER width: {CUB[2:0], CMD[n-1:0]}; n=6(gen2) or 7(gen3)
localparam AXI4_BUSER_W = (HMC_VER==1) ? 18 : 152; // AXI4MM BUSER width (bits)
                                                   // - Gen2:{ageout, slid[2:0], errstat[6:0], dinv, cmd[5:0]};
                                                   // - Gen3:{data[127:0], dt_vld, 3'b0, ageout, af, slid[2:0], errstat[6:0], dinv, cmd[6:0]}
localparam AXI4_RUSER_W = (HMC_VER==1) ? 18 : 20;  // AXI4MM RUSER width (bits)
                                                   // - Gen2:{ageout, slid[2:0], errstat[6:0], dinv, cmd[5:0]};
                                                   // - Gen3:{ageout, af, slid[2:0], errstat[6:0], dinv, cmd[6:0]}
localparam AXI4_IF_DATA_W = 1024;                  // AXI4MM DATA bus width (bits)
localparam HMC_TL_IF_DAT_W = 128*N_FLIT;           // HMC TL DATA bus width (bits)
localparam TGEN_REQ_NUM = 32;                      // Traffic-Generator # of requests

//------------------------------------------------------------------------------
// reg/wire declaration
//------------------------------------------------------------------------------
wire                         refclk_out;

wire                          clk_axi4l;
wire                          rst_axi4l;
reg                     [2:0] rst_ul_sync;
wire                          axi4mm_awvalid;
wire         [AXI4_UID_W-1:0] axi4mm_awid;
wire                 [34-1:0] axi4mm_awaddr;
wire       [AXI4_AUSER_W-1:0] axi4mm_awuser;
wire                  [8-1:0] axi4mm_awlen;
wire                          axi4mm_awready;
wire                          axi4mm_wvalid;
wire         [AXI4_UID_W-1:0] axi4mm_wid;
wire     [AXI4_IF_DATA_W-1:0] axi4mm_wdata;
wire                    [7:0] axi4mm_wstrb;
wire                          axi4mm_wready;
wire                          axi4mm_arvalid;
wire         [AXI4_UID_W-1:0] axi4mm_arid;
wire                 [34-1:0] axi4mm_araddr;
wire       [AXI4_AUSER_W-1:0] axi4mm_aruser;
wire                          axi4mm_arready;
wire                          axi4mm_bvalid;
wire         [AXI4_UID_W-1:0] axi4mm_bid;
wire       [AXI4_BUSER_W-1:0] axi4mm_buser;
wire                  [2-1:0] axi4mm_bresp;
wire                          axi4mm_bready;
wire                          axi4mm_rvalid;
wire         [AXI4_UID_W-1:0] axi4mm_rid;
wire       [AXI4_RUSER_W-1:0] axi4mm_ruser;
wire     [AXI4_IF_DATA_W-1:0] axi4mm_rdata;
wire                          axi4mm_rlast;
wire                  [2-1:0] axi4mm_rresp;
wire                          axi4mm_rready;
wire                          axi4l_clk;
wire                          axi4l_resetn;
wire                          axi4l_awvalid;
wire     [CSR_ADDR_WIDTH-1:0] axi4l_awaddr;
wire                          axi4l_awready;
wire                          axi4l_wvalid;
wire                   [31:0] axi4l_wdata;
wire                    [3:0] axi4l_wstrb;
wire                          axi4l_wready;
wire                          axi4l_bvalid;
wire                    [1:0] axi4l_bresp;
wire                          axi4l_bready;
wire                          axi4l_arvalid;
wire     [CSR_ADDR_WIDTH-1:0] axi4l_araddr;
wire                          axi4l_arready;
wire                          axi4l_rready;
wire                          axi4l_rvalid;
wire                   [31:0] axi4l_rdata;
wire                    [1:0] axi4l_rresp;
wire                          tltx_valid;
wire    [HMC_TL_IF_DAT_W-1:0] tltx_flit_dat;
wire             [N_FLIT-1:0] tltx_flit_vld;
wire             [N_FLIT-1:0] tltx_flit_sop;
wire             [N_FLIT-1:0] tltx_flit_eop;
wire                          tltx_ready;
wire                          ultx_valid;
wire    [HMC_TL_IF_DAT_W-1:0] ultx_flit_dat;
wire             [N_FLIT-1:0] ultx_flit_vld;
wire             [N_FLIT-1:0] ultx_flit_sop;
wire             [N_FLIT-1:0] ultx_flit_eop;
wire                          ultx_ready;
wire                          tlrx_valid;
wire    [HMC_TL_IF_DAT_W-1:0] tlrx_flit_dat;
wire             [N_FLIT-1:0] tlrx_flit_vld;
wire             [N_FLIT-1:0] tlrx_flit_sop;
wire             [N_FLIT-1:0] tlrx_flit_eop;
wire                          tlrx_ready;
wire                          hmc_devinit_en;
wire                          dev_init_done;
// Simulation probes
wire                         clk_hmc;
wire                         hmc_tgen_proc   ;
wire                         hmc_tgen_done   ;
wire                         hmc_tgen_pass   ;
wire                         hmc_mmcm_lock   ;
wire                         hmc_gt_tx_done  ;
wire                         hmc_gt_rx_done  ;
wire                         hmc_link_up     ;
wire                         hmc_wrreq_proc  ;
wire                         hmc_rdreq_proc  ;
wire  [7:0]                  axi4mm_ch_aw_cnt;
wire  [7:0]                  axi4mm_ch_w_cnt ;
wire  [7:0]                  axi4mm_ch_b_cnt ;
wire  [7:0]                  axi4mm_ch_ar_cnt;
wire  [7:0]                  axi4mm_ch_r_cnt ;
wire  [3:0]                  dbg_tgen_fsm   ;



assign clk_axi4l = clk_free; 

xpm_cdc_sync_rst # (.DEST_SYNC_FF(3)) u_rst_axi4l_sync(.src_rst(rst), .dest_clk(clk_axi4l), .dest_rst(rst_axi4l));

//------------------------------------------------------------------------------
// Traffic-Generator instantiation
//------------------------------------------------------------------------------
tgen_top
  #(.HMC_VER(HMC_VER),
    .FLIT_W              (FLIT_W),
    .TGEN_REQ_NUM        (TGEN_REQ_NUM),
    .TGEN_SIM_F          (TGEN_SIM_F),
    .HMCC_TOKEN          (HMCC_TOKEN),
    .DEV_CUB_ID          (DEV_CUB_ID),
    .AXI4_IF_DT_FLIT     (8),
    .AXI4_DT_CHNNL_ALIGN (1),
    .CSR_ADDR_WIDTH      (CSR_ADDR_WIDTH)
  ) u_tgen_top (
    .clk_free         (clk_free),
    .clk_hmc          (clk_hmc),
    .rst              (rst),
    .clkdrv_init_done (1'b1),
    .dev_init_done    (dev_init_done),
    .hmc_tgen_proc    (hmc_tgen_proc),
    .hmc_tgen_done    (hmc_tgen_done),
    .hmc_tgen_pass    (hmc_tgen_pass),
    .hmc_mmcm_lock    (hmc_mmcm_lock),
    .hmc_gt_tx_done   (hmc_gt_tx_done),
    .hmc_gt_rx_done   (hmc_gt_rx_done),
    .hmc_link_up      (hmc_link_up),
    .hmc_devinit_en   (hmc_devinit_en),
    .hmc_wrreq_proc   (hmc_wrreq_proc),
    .hmc_rdreq_proc   (hmc_rdreq_proc),
    .axi4mm_ch_aw_cnt (axi4mm_ch_aw_cnt),
    .axi4mm_ch_w_cnt  (axi4mm_ch_w_cnt),
    .axi4mm_ch_b_cnt  (axi4mm_ch_b_cnt),
    .axi4mm_ch_ar_cnt (axi4mm_ch_ar_cnt),
    .axi4mm_ch_r_cnt  (axi4mm_ch_r_cnt),
    .dbg_tgen_fsm     (dbg_tgen_fsm),
    .l2_rst_mmcm      (l2_rst_mmcm),
    .axi4mm_awvalid   (axi4mm_awvalid),
    .axi4mm_awid      (axi4mm_awid),
    .axi4mm_awaddr    (axi4mm_awaddr),
    .axi4mm_awuser    (axi4mm_awuser),
    .axi4mm_awlen     (axi4mm_awlen),
    .axi4mm_awready   (axi4mm_awready),
    .axi4mm_wvalid    (axi4mm_wvalid),
    .axi4mm_wid       (axi4mm_wid),
    .axi4mm_wdata     (axi4mm_wdata),
    .axi4mm_wstrb     (axi4mm_wstrb),
    .axi4mm_wready    (axi4mm_wready),
    .axi4mm_arvalid   (axi4mm_arvalid),
    .axi4mm_arid      (axi4mm_arid),
    .axi4mm_araddr    (axi4mm_araddr),
    .axi4mm_aruser    (axi4mm_aruser),
    .axi4mm_arready   (axi4mm_arready),
    .axi4mm_bvalid    (axi4mm_bvalid),
    .axi4mm_bid       (axi4mm_bid),
    .axi4mm_buser     (axi4mm_buser),
    .axi4mm_bresp     (axi4mm_bresp),
    .axi4mm_bready    (axi4mm_bready),
    .axi4mm_rvalid    (axi4mm_rvalid),
    .axi4mm_rid       (axi4mm_rid),
    .axi4mm_ruser     (axi4mm_ruser),
    .axi4mm_rdata     (axi4mm_rdata),
    .axi4mm_rlast     (axi4mm_rlast),
    .axi4mm_rresp     (axi4mm_rresp),
    .axi4mm_rready    (axi4mm_rready),
    .axi4l_clk        (clk_axi4l),
    .axi4l_resetn     (~rst_axi4l),
    .axi4l_awvalid    (axi4l_awvalid),
    .axi4l_awaddr     (axi4l_awaddr),
    .axi4l_awready    (axi4l_awready),
    .axi4l_wvalid     (axi4l_wvalid),
    .axi4l_wdata      (axi4l_wdata),
    .axi4l_wstrb      (axi4l_wstrb),
    .axi4l_wready     (axi4l_wready),
    .axi4l_bvalid     (axi4l_bvalid),
    .axi4l_bresp      (axi4l_bresp),
    .axi4l_bready     (axi4l_bready),
    .axi4l_arvalid    (axi4l_arvalid),
    .axi4l_araddr     (axi4l_araddr),
    .axi4l_arready    (axi4l_arready),
    .axi4l_rready     (axi4l_rready),
    .axi4l_rvalid     (axi4l_rvalid),
    .axi4l_rdata      (axi4l_rdata),
    .axi4l_rresp      (axi4l_rresp) );

//------------------------------------------------------------------------------
// HMC-Core and HMC-UL instantiation
//------------------------------------------------------------------------------
xhmc_d
 u_xhmc_d (
    .refclk_p       (refclk_p),
    .refclk_n       (refclk_n),
    .txp            (txp),
    .txn            (txn),
    .rxp            (rxp),
    .rxn            (rxn),
    .rst            (rst),
    .clk_in         (clk_free),
    .clk_out        (clk_hmc),
    .refclk_out     (refclk_out),
    .l2_rst_mmcm    (l2_rst_mmcm),
    .l3_rst_gtdn    (),
    .l4_rst_phydn   (),
    .lxrxps         (lxrxps),
    .lxtxps         (lxtxps),
    .p_rst_n_link   (device_p_rst_n),
    .p_rst_n_device (device_p_rst_n),
    .tltx_valid     (tltx_valid),
    .tltx_flit_dat  (tltx_flit_dat),
    .tltx_flit_vld  (tltx_flit_vld),
    .tltx_flit_sop  (tltx_flit_sop),
    .tltx_flit_eop  (tltx_flit_eop),
    .tltx_ready     (tltx_ready),
    .tlrx_valid     (tlrx_valid),
    .tlrx_flit_dat  (tlrx_flit_dat),
    .tlrx_flit_vld  (tlrx_flit_vld),
    .tlrx_flit_sop  (tlrx_flit_sop),
    .tlrx_flit_eop  (tlrx_flit_eop),
    .tlrx_ready     (tlrx_ready),
    .s_axi_aclk     (clk_axi4l),
    .s_axi_aresetn  (~rst_axi4l),
    .s_axi_awvalid  (axi4l_awvalid),
    .s_axi_awaddr   (axi4l_awaddr),
    .s_axi_awready  (axi4l_awready),
    .s_axi_wvalid   (axi4l_wvalid),
    .s_axi_wdata    (axi4l_wdata),
    .s_axi_wstrb    (axi4l_wstrb),
    .s_axi_wready   (axi4l_wready),
    .s_axi_bvalid   (axi4l_bvalid),
    .s_axi_bresp    (axi4l_bresp),
    .s_axi_bready   (axi4l_bready),
    .s_axi_arvalid  (axi4l_arvalid),
    .s_axi_araddr   (axi4l_araddr),
    .s_axi_arready  (axi4l_arready),
    .s_axi_rready   (axi4l_rready),
    .s_axi_rvalid   (axi4l_rvalid),
    .s_axi_rdata    (axi4l_rdata),
    .s_axi_rresp    (axi4l_rresp),
    .errresp_ready  (1'b1),
    .errresp_valid  (),
    .errresp_data   (),
    .csr_ext_in     (32'b0),
    .csr_ext_out1   (),
    .csr_ext_out2   (),
    .hmc_int        (hmc_int)
	
);


always @(posedge clk_hmc or posedge rst)
  if (rst)
    rst_ul_sync <= 3'b111;
  else
    rst_ul_sync <= {rst_ul_sync, 1'b0};

hmc_ul
  #(.HMC_VER(HMC_VER),
    .N_FLIT(N_FLIT)
  ) u_hmc_ul (
    .clk            (clk_hmc),
    .rst            (rst_ul_sync[2]),
    .axi4mm_awvalid (axi4mm_awvalid),
    .axi4mm_awid    (axi4mm_awid),
    .axi4mm_awaddr  (axi4mm_awaddr),
    .axi4mm_awuser  (axi4mm_awuser),
    .axi4mm_awlen   (axi4mm_awlen),
    .axi4mm_awready (axi4mm_awready),
    .axi4mm_wvalid  (axi4mm_wvalid),
    .axi4mm_wid     (axi4mm_wid),
    .axi4mm_wdata   (axi4mm_wdata),
    .axi4mm_wstrb   (axi4mm_wstrb),
    .axi4mm_wready  (axi4mm_wready),
    .axi4mm_arvalid (axi4mm_arvalid),
    .axi4mm_arid    (axi4mm_arid),
    .axi4mm_araddr  (axi4mm_araddr),
    .axi4mm_aruser  (axi4mm_aruser),
    .axi4mm_arready (axi4mm_arready),
    .axi4mm_bvalid  (axi4mm_bvalid),
    .axi4mm_bid     (axi4mm_bid),
    .axi4mm_buser   (axi4mm_buser),
    .axi4mm_bresp   (axi4mm_bresp),
    .axi4mm_bready  (axi4mm_bready),
    .axi4mm_rvalid  (axi4mm_rvalid),
    .axi4mm_rid     (axi4mm_rid),
    .axi4mm_ruser   (axi4mm_ruser),
    .axi4mm_rdata   (axi4mm_rdata),
    .axi4mm_rresp   (axi4mm_rresp),
    .axi4mm_rlast   (axi4mm_rlast),
    .axi4mm_rready  (axi4mm_rready),
    .tltx_valid     (ultx_valid),
    .tltx_flit_dat  (ultx_flit_dat),
    .tltx_flit_vld  (ultx_flit_vld),
    .tltx_flit_sop  (ultx_flit_sop),
    .tltx_flit_eop  (ultx_flit_eop),
    .tltx_ready     (ultx_ready),
    .tlrx_valid     (tlrx_valid),
    .tlrx_flit_dat  (tlrx_flit_dat),
    .tlrx_flit_vld  (tlrx_flit_vld),
    .tlrx_flit_sop  (tlrx_flit_sop),
    .tlrx_flit_eop  (tlrx_flit_eop),
    .tlrx_ready     (tlrx_ready) );
//------------------------------------------------------------------------------
//use pre-fetch module to bridge the user layer TX and core logic TC
//------------------------------------------------------------------------------
localparam SHIM_MEM_D_W = 3*N_FLIT + HMC_TL_IF_DAT_W; 

reg [SHIM_MEM_D_W-1:0] shim_mem [7:0];
reg  [SHIM_MEM_D_W-1:0] shim_mem_rdt_t,shim_mem_rdt;
wire shim_mem_we ; 
wire [2:0] shim_mem_wad; 
wire [SHIM_MEM_D_W-1:0] shim_mem_wdt; 
wire shim_mem_re ; 
wire [2:0] shim_mem_rad;
wire shim_fifo_empty;

example_hmc_sync_fifo_ctrl #(
  .FFDATA_W    (SHIM_MEM_D_W),
  .FFADDR_W    (3) ,
  .WR_LTNCY    (1) ,		// latency for wptr to be viewable in read domain
  .RD_LTNCY    (2) ,		// latency from read strobe to rdata out; min = 1
  .IN_BP_MODE  (1) ,		// input back-pressure mode: 0: FIFO full; 1: FIFO hit threshold;
  .IN_STRICT_BP(0)	        // input strict back-pressure: 0: accept data when rdy=0 but FIFO non-full; 1: not accept data when rdy=0;
  ) u_ul2tl_tx_shim (
  .clk             (clk_hmc),
  .rst             (rst_ul_sync[2]),
  .cfg_bp_en       (1'b1), // FIFO back pressure enable
  .cfg_alfull_thrd (4'd2), // FIFO almost full threshold
  // FIFO input
  .di_wr           (ultx_valid), // Din write strobe
  .di              ({ultx_flit_sop, ultx_flit_eop, ultx_flit_vld, ultx_flit_dat}), // Din
  .di_if_rdy       (), // Interface ready for Din
  .di_ff_rdy       (ultx_ready), // FIFO ready for Din
  // FIFO output
  .do_rd           ((~shim_fifo_empty) & tltx_ready), // Dout read strobe
  .do_vld          (tltx_valid), // Dout valid
  .ff_empty        (shim_fifo_empty),
  // Memory interface
  .mem_we          (shim_mem_we ),
  .mem_wad         (shim_mem_wad),
  .mem_wdt         (shim_mem_wdt),
  .mem_re          (shim_mem_re ),
  .mem_rad         (shim_mem_rad),
  // FIFO status
  .di_ovflow       (), // Din write overflow
  .dt_cnt          (), // current available data count
  .sp_cnt          ()  // current FIFO space count
);

always @(posedge clk_hmc) begin
	if (shim_mem_we) 
		shim_mem[shim_mem_wad] <= shim_mem_wdt;
end

always @(posedge clk_hmc) begin
	if (shim_mem_re)
		shim_mem_rdt_t <= shim_mem[shim_mem_rad]; //addtional pipeline to relax the timing
		shim_mem_rdt   <= shim_mem_rdt_t;
end

assign tltx_flit_dat = shim_mem_rdt[HMC_TL_IF_DAT_W-1:0];
assign tltx_flit_vld = shim_mem_rdt[1*N_FLIT + HMC_TL_IF_DAT_W-1 :0*N_FLIT + HMC_TL_IF_DAT_W];
assign tltx_flit_eop = shim_mem_rdt[2*N_FLIT + HMC_TL_IF_DAT_W-1 :1*N_FLIT + HMC_TL_IF_DAT_W];
assign tltx_flit_sop = shim_mem_rdt[3*N_FLIT + HMC_TL_IF_DAT_W-1 :2*N_FLIT + HMC_TL_IF_DAT_W];

generate if (TGEN_SIM_F==0) begin : GEN_DEV_HW_INIT
hmc_iic #(
    .IIC_MUX_ADDR  (IIC_MUX_ADDR),
    .IIC_HMC_ADDR  (IIC_HMC_ADDR),
    .GT_SPEED      (GT_SPEED),
    .FULL_WIDTH    (FULL_WIDTH),
    .CLOCK_FREQ    (GT_REFCLK_FREQ),
    .HMC_LINK_ID   (HMC_DEV_LINK_ID),
    .HMC_TOKEN_CNT (HMC_TOKEN)
) u_iic_inst(
    .rst          (rst),
    .clk          (clk_free),
    .iic_scl_io   (IIC_MAIN_SCL_LS),
    .iic_sda_io   (IIC_MAIN_SDA_LS),
    .hmc_iic_start(hmc_devinit_en),
    .hmc_iic_done (dev_init_done)
);
end
endgenerate 

generate if(TGEN_SIM_F == 1) begin :GEN_SKIP_DEV_INIT
    assign dev_init_done = 1'b1;
    assign IIC_MAIN_SCL_LS = 1'bZ;
    assign IIC_MAIN_SDA_LS = 1'bZ;
end
endgenerate


//------------------------------------------------------------------------------
// VCU109 hardware control
//------------------------------------------------------------------------------
assign SM_FAN_PWM  = 1'b1;               //HMC device fan 
assign SM_FAN_TACH = 1'b1;               //FPGA fan

assign IIC_MUX_RESET_B_LS = 1'b1;
assign SI5328_RST_N_LS    = 1'b1;

assign GPIO_LED_0_LS = hmc_tgen_proc;
assign GPIO_LED_1_LS = hmc_tgen_done;
assign GPIO_LED_2_LS = hmc_tgen_pass;
assign GPIO_LED_3_LS = hmc_mmcm_lock;
assign GPIO_LED_4_LS = hmc_gt_tx_done;
assign GPIO_LED_5_LS = hmc_gt_rx_done;
assign GPIO_LED_6_LS = hmc_link_up;
assign GPIO_LED_7_LS = HMC_FERR_B;

//HMC device reference clock select bootstrap: 2'b0 -> 125Mhz; 2'b01 ->156.25Mhz 
assign {HMC_REFCLK_BOOT_1, HMC_REFCLK_BOOT_0} = (GT_REFCLK_FREQ ==    125) ? 2'b00 :
                                                (GT_REFCLK_FREQ == 156.25) ? 2'b01 :
                                                (GT_REFCLK_FREQ == 166.67) ? 2'b10 :
                                                                             2'b11;
assign HMC_REFCLK_SEL = 1'b1;	// Tied to 1, EVB's REFCLK are AC-coupled

endmodule




