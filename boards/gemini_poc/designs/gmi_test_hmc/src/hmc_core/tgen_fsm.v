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
// File       : tgen_fsm.v
// Version    : 1.0  
//-----------------------------------------------------------------------------

//==============================================================================
// Traffic-Generator Finite State Machine - runs at free-running clock domain
//==============================================================================
`timescale 1ns/1ps

module tgen_fsm
  #(parameter TGEN_SIM_F=0,
    parameter CSR_ADDR_WIDTH=10,
    parameter HMCC_TOKEN=512
  ) (
    input                            clk,
    input                            rst,
    // General Control
    input                            clk_hmc,
    input                            rst_hmc,
    output reg                       fsm_devinit_en,
    output reg                       fsm_dtgen_en,
    output reg                       fsm_wrreq_en,
    output reg                       fsm_rdreq_en,
    input                            l2_rst_mmcm,
    input                            clkdrv_init_done,
    input                            dev_init_done,
    input                            dtgen_done,
    input                            wrreq_done,
    input                            wrreq_pass,
    input                            rdreq_done,
    input                            rdreq_pass,
    // CSR Access
    output reg                       csr_en,
    output reg                       csr_wr,
    output reg  [CSR_ADDR_WIDTH-1:0] csr_addr,
    output reg                [31:0] csr_wdata,
    input                            csr_done,
    input                     [31:0] csr_rdata,
    // Status
    output reg                       hmc_tgen_proc,
    output reg                       hmc_tgen_done,
    output                           hmc_tgen_pass,
    output reg                       hmc_mmcm_lock,
    output reg                       hmc_gt_tx_done,
    output reg                       hmc_gt_rx_done,
    output reg                       hmc_link_up,
    output reg                 [3:0] dbg_tgen_fsm
  );

localparam FSM_IDLE      = 'd0;
localparam FSM_WT_CLKDRV = 'd1;
localparam FSM_HMC_INIT  = 'd2;
localparam FSM_WT_GTTX   = 'd3;
localparam FSM_DEV_INIT  = 'd4;
localparam FSM_HMCC_CFG0 = 'd5;
localparam FSM_EN_GTRX   = 'd6;
localparam FSM_WT_GTRX   = 'd7;
localparam FSM_WT_PHYDN  = 'd8;
localparam FSM_GEN_DATA  = 'd9;
localparam FSM_TRG_WREQ  = 'd10;
localparam FSM_TRG_RREQ  = 'd11;
localparam FSM_DONE      = 'd12;

localparam FSM_WIDTH = 4;

//------------------------------------------------------------------------------
// reg/wire declaration
//------------------------------------------------------------------------------
reg  [FSM_WIDTH-1:0] fsm_cs, fsm_ns;
reg                  fsm_dtgen_st;
reg                  fsm_wrreq_st;
reg                  fsm_rdreq_st;
reg                  fsm_dtgen_cdc_d;
reg                  fsm_wrreq_cdc_d;
reg                  fsm_rdreq_cdc_d;
reg                  dtgen_done_lvl;
reg                  wrreq_done_lvl;
reg                  rdreq_done_lvl;
reg                  dtgen_done_cdc_d;
reg                  wrreq_done_cdc_d;
reg                  rdreq_done_cdc_d;

wire                 l2_rst_mmcm_cdc;
wire                 clkdrv_init_done_cdc;
wire                 dev_init_done_cdc;
wire                 fsm_dtgen_cdc;
wire                 fsm_wrreq_cdc;
wire                 fsm_rdreq_cdc;
wire                 dtgen_done_cdc;
wire                 wrreq_done_cdc;
wire                 rdreq_done_cdc;
wire                 dtgen_done_fsm;
wire                 wrreq_done_fsm;
wire                 rdreq_done_fsm;
wire                 hmc_tgen_pass_cdc;
reg                  hmc_tgen_pass_hclk;


assign hmc_tgen_pass = hmc_tgen_pass_cdc;
//------------------------------------------------------------------------------
// FSM
//------------------------------------------------------------------------------
always @(posedge clk)
  if (rst)
    fsm_cs <= FSM_IDLE;
  else
    fsm_cs <= fsm_ns;

always @* begin
  fsm_ns = fsm_cs;
  case (fsm_cs)
    FSM_IDLE :
      fsm_ns = (TGEN_SIM_F) ? FSM_HMC_INIT : FSM_WT_CLKDRV;
    FSM_WT_CLKDRV :
      fsm_ns = (clkdrv_init_done_cdc) ? FSM_HMC_INIT : fsm_cs;
    FSM_HMC_INIT :
      fsm_ns = (csr_done) ? FSM_WT_GTTX : fsm_cs;
    FSM_WT_GTTX :
      fsm_ns = (csr_done & (csr_rdata[1] == 1)) ? FSM_DEV_INIT : fsm_cs;
    FSM_DEV_INIT :
      fsm_ns = (dev_init_done_cdc) ? FSM_HMCC_CFG0 : fsm_cs;
    FSM_HMCC_CFG0 :
      fsm_ns = (csr_done) ? FSM_EN_GTRX : fsm_cs;
    FSM_EN_GTRX :
      fsm_ns = (csr_done) ? FSM_WT_GTRX : fsm_cs;
    FSM_WT_GTRX :
      fsm_ns = (csr_done & (csr_rdata[2] == 1)) ? FSM_WT_PHYDN : fsm_cs;
    FSM_WT_PHYDN :
      fsm_ns = (csr_done & (csr_rdata[17] == 1)) ? FSM_GEN_DATA : fsm_cs;
    FSM_GEN_DATA :
      fsm_ns = (dtgen_done_fsm) ? FSM_TRG_WREQ : fsm_cs;
    FSM_TRG_WREQ :
      fsm_ns = (wrreq_done_fsm) ? FSM_TRG_RREQ : fsm_cs;
    FSM_TRG_RREQ :
      fsm_ns = (rdreq_done_fsm) ? FSM_DONE : fsm_cs;
    FSM_DONE :
      fsm_ns = fsm_cs;
  endcase
end

//------------------------------------------------------------------------------
// CSR access control signals 
//------------------------------------------------------------------------------
always @(posedge clk)
  if (rst)
    csr_en <= 1'b0;
  else
    csr_en <= ~csr_done &
              ((fsm_cs == FSM_HMC_INIT ) |
               (fsm_cs == FSM_WT_GTTX  ) |
               (fsm_cs == FSM_HMCC_CFG0) |
               (fsm_cs == FSM_EN_GTRX  ) |
               (fsm_cs == FSM_WT_GTRX  ) |
               (fsm_cs == FSM_WT_PHYDN ));

always @(posedge clk)
  if (rst)
    csr_wr <= 1'b0;
  else
    csr_wr <= ((fsm_cs == FSM_HMC_INIT ) |
               (fsm_cs == FSM_HMCC_CFG0) |
               (fsm_cs == FSM_EN_GTRX  ));

always @(posedge clk)
  if (rst)
    csr_addr <= {CSR_ADDR_WIDTH{1'b0}};
  else
    csr_addr <= ({CSR_ADDR_WIDTH{(fsm_cs == FSM_HMC_INIT )}} & {{CSR_ADDR_WIDTH{1'b0}}, 8'h00}) |
                ({CSR_ADDR_WIDTH{(fsm_cs == FSM_WT_GTTX  )}} & {{CSR_ADDR_WIDTH{1'b0}}, 8'h04}) |
                ({CSR_ADDR_WIDTH{(fsm_cs == FSM_HMCC_CFG0)}} & {{CSR_ADDR_WIDTH{1'b0}}, 8'hb0}) |
                ({CSR_ADDR_WIDTH{(fsm_cs == FSM_EN_GTRX  )}} & {{CSR_ADDR_WIDTH{1'b0}}, 8'h10}) |
                ({CSR_ADDR_WIDTH{(fsm_cs == FSM_WT_GTRX  )}} & {{CSR_ADDR_WIDTH{1'b0}}, 8'h04}) |
                ({CSR_ADDR_WIDTH{(fsm_cs == FSM_WT_PHYDN )}} & {{CSR_ADDR_WIDTH{1'b0}}, 8'h14});

always @(posedge clk)
  if (rst)
    csr_wdata <= 32'b0;
  else
    csr_wdata <= ({32{(fsm_cs == FSM_HMC_INIT )}} & ((TGEN_SIM_F) ? 32'h8000_0000 : 32'h0)) |
                 ({32{(fsm_cs == FSM_HMCC_CFG0)}} & {32'h0, HMCC_TOKEN}) |
                 ({32{(fsm_cs == FSM_EN_GTRX  )}} & 32'h0000_0002);

//------------------------------------------------------------------------------
// AXI4MM control signals 
//------------------------------------------------------------------------------
// clk (free-running) domain
always @(posedge clk)
  if (rst)
    fsm_devinit_en <= 1'b0;
  else
    fsm_devinit_en <= (fsm_cs == FSM_DEV_INIT);

always @(posedge clk)
  if (rst)
    fsm_dtgen_st <= 1'b0;
  else
    fsm_dtgen_st <= (fsm_cs == FSM_GEN_DATA);

always @(posedge clk)
  if (rst)
    fsm_wrreq_st <= 1'b0;
  else
    fsm_wrreq_st <= (fsm_cs == FSM_TRG_WREQ);

always @(posedge clk)
  if (rst)
    fsm_rdreq_st <= 1'b0;
  else
    fsm_rdreq_st <= (fsm_cs == FSM_TRG_RREQ);

always @(posedge clk)
  if (rst) begin
    dtgen_done_cdc_d <= 1'b0;
    wrreq_done_cdc_d <= 1'b0;
    rdreq_done_cdc_d <= 1'b0;
  end
  else begin
    dtgen_done_cdc_d <= dtgen_done_cdc;
    wrreq_done_cdc_d <= wrreq_done_cdc;
    rdreq_done_cdc_d <= rdreq_done_cdc;
  end

assign dtgen_done_fsm = dtgen_done_cdc & ~dtgen_done_cdc_d;
assign wrreq_done_fsm = wrreq_done_cdc & ~wrreq_done_cdc_d;
assign rdreq_done_fsm = rdreq_done_cdc & ~rdreq_done_cdc_d;

// clk_hmc domain
always @(posedge clk_hmc)
  if (rst_hmc) begin
    fsm_dtgen_cdc_d <= 1'b0;
    fsm_wrreq_cdc_d <= 1'b0;
    fsm_rdreq_cdc_d <= 1'b0;
  end
  else begin
    fsm_dtgen_cdc_d <= fsm_dtgen_cdc;
    fsm_wrreq_cdc_d <= fsm_wrreq_cdc;
    fsm_rdreq_cdc_d <= fsm_rdreq_cdc;
  end

always @(posedge clk_hmc)
  if (rst_hmc) begin
    fsm_dtgen_en <= 1'b0;
    fsm_wrreq_en <= 1'b0;
    fsm_rdreq_en <= 1'b0;
  end
  else begin
    fsm_dtgen_en <= fsm_dtgen_cdc & ~fsm_dtgen_cdc_d;
    fsm_wrreq_en <= fsm_wrreq_cdc & ~fsm_wrreq_cdc_d;
    fsm_rdreq_en <= fsm_rdreq_cdc & ~fsm_rdreq_cdc_d;
  end

always @(posedge clk_hmc)
  if (rst_hmc) begin
    dtgen_done_lvl <= 1'b0;
    wrreq_done_lvl <= 1'b0;
    rdreq_done_lvl <= 1'b0;
  end
  else begin
    dtgen_done_lvl <= dtgen_done_lvl ^ dtgen_done;
    wrreq_done_lvl <= wrreq_done_lvl ^ wrreq_done;
    rdreq_done_lvl <= rdreq_done_lvl ^ rdreq_done;
  end

always @(posedge clk_hmc)
  if (rst_hmc)
    hmc_tgen_pass_hclk <= 1'b0;
  else if (wrreq_done)
    hmc_tgen_pass_hclk <= wrreq_pass;
  else if (rdreq_done)
    hmc_tgen_pass_hclk <= hmc_tgen_pass_hclk & rdreq_pass;

//------------------------------------------------------------------------------
// FSM status outputs
//------------------------------------------------------------------------------
always @(posedge clk)
  if (rst)
    hmc_tgen_proc <= 1'b0;
  else
    hmc_tgen_proc <= (fsm_cs != FSM_IDLE) && (fsm_cs != FSM_DONE);

always @(posedge clk)
  if (rst)
    hmc_tgen_done <= 1'b0;
  else
    hmc_tgen_done <= (fsm_cs == FSM_DONE);


always @(posedge clk)
  if (rst)
    hmc_mmcm_lock <= 1'b0;
  else
    hmc_mmcm_lock <= ~l2_rst_mmcm_cdc;

always @(posedge clk)
  if (rst)
    hmc_gt_tx_done <= 1'b0;
  else
    hmc_gt_tx_done <= hmc_gt_tx_done | (fsm_cs == FSM_DEV_INIT);

always @(posedge clk)
  if (rst)
    hmc_gt_rx_done <= 1'b0;
  else
    hmc_gt_rx_done <= hmc_gt_rx_done | (fsm_cs == FSM_WT_PHYDN);

always @(posedge clk)
  if (rst)
    hmc_link_up <= 1'b0;
  else
    hmc_link_up <= hmc_link_up | (fsm_cs == FSM_GEN_DATA);

always @(posedge clk)
  if (rst)
    dbg_tgen_fsm <= FSM_IDLE;
  else
    dbg_tgen_fsm <= fsm_cs;

//------------------------------------------------------------------------------
// CDC logic
//------------------------------------------------------------------------------
xpm_cdc_single # (.DEST_SYNC_FF(3),.SRC_INPUT_REG(0)) u_l2_rst_mmcm_cdc_sync  (.src_clk(1'b0),.dest_clk(clk),.src_in(l2_rst_mmcm     ),.dest_out(l2_rst_mmcm_cdc     ));
xpm_cdc_single # (.DEST_SYNC_FF(3),.SRC_INPUT_REG(0)) u_clkdrv_done_cdc_sync  (.src_clk(1'b0),.dest_clk(clk),.src_in(clkdrv_init_done),.dest_out(clkdrv_init_done_cdc));
xpm_cdc_single # (.DEST_SYNC_FF(3),.SRC_INPUT_REG(0)) u_dev_init_done_cdc_sync(.src_clk(1'b0),.dest_clk(clk),.src_in(dev_init_done   ),.dest_out(dev_init_done_cdc   ));
xpm_cdc_single # (.DEST_SYNC_FF(3),.SRC_INPUT_REG(0)) u_dtgen_done_cdc_sync   (.src_clk(1'b0),.dest_clk(clk),.src_in(dtgen_done_lvl  ),.dest_out(dtgen_done_cdc      ));
xpm_cdc_single # (.DEST_SYNC_FF(3),.SRC_INPUT_REG(0)) u_wrreq_done_cdc_sync   (.src_clk(1'b0),.dest_clk(clk),.src_in(wrreq_done_lvl  ),.dest_out(wrreq_done_cdc      ));
xpm_cdc_single # (.DEST_SYNC_FF(3),.SRC_INPUT_REG(0)) u_rdreq_done_cdc_sync   (.src_clk(1'b0),.dest_clk(clk),.src_in(rdreq_done_lvl  ),.dest_out(rdreq_done_cdc      ));
xpm_cdc_single # (.DEST_SYNC_FF(3),.SRC_INPUT_REG(0)) u_tgen_pass_cdc_sync    (.src_clk(1'b0),.dest_clk(clk),.src_in(hmc_tgen_pass_hclk),.dest_out(hmc_tgen_pass_cdc));

xpm_cdc_single # (.DEST_SYNC_FF(3),.SRC_INPUT_REG(0)) u_fsm_dtgen_st_cdc_sync(.src_clk(1'b0),.dest_clk(clk_hmc),.src_in(fsm_dtgen_st),.dest_out(fsm_dtgen_cdc));
xpm_cdc_single # (.DEST_SYNC_FF(3),.SRC_INPUT_REG(0)) u_fsm_wrreq_st_cdc_sync(.src_clk(1'b0),.dest_clk(clk_hmc),.src_in(fsm_wrreq_st),.dest_out(fsm_wrreq_cdc));
xpm_cdc_single # (.DEST_SYNC_FF(3),.SRC_INPUT_REG(0)) u_fsm_rdreq_st_cdc_sync(.src_clk(1'b0),.dest_clk(clk_hmc),.src_in(fsm_rdreq_st),.dest_out(fsm_rdreq_cdc));

endmodule

