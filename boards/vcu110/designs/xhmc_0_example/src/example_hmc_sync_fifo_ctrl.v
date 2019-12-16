`timescale 1ns/1ps
module  example_hmc_sync_fifo_ctrl 
  #(parameter FFDATA_W=512,
              FFADDR_W=10,
              WR_LTNCY=1,		// latency for wptr to be viewable in read domain
              RD_LTNCY=2,		// latency from read strobe to rdata out; min = 1
              IN_BP_MODE=1,		// input back-pressure mode: 0: FIFO full; 1: FIFO hit threshold;
              IN_STRICT_BP=1	// input strict back-pressure: 0: accept data when rdy=0 but FIFO non-full; 1: not accept data when rdy=0;
  ) (
  input                      clk,
  input                      rst,
  input                      cfg_bp_en,			// FIFO back pressure enable
  input         [FFADDR_W:0] cfg_alfull_thrd,	// FIFO almost full threshold
  // FIFO input
  input                      di_wr,				// Din write strobe
  input       [FFDATA_W-1:0] di,				// Din
  output wire                di_if_rdy,			// Interface ready for Din
  output wire                di_ff_rdy,			// FIFO ready for Din
  // FIFO output
  input                      do_rd,				// Dout read strobe
  output wire                do_vld,			// Dout ready
  output wire                ff_empty,
  // Memory interface
  output reg                 mem_we,
  output reg  [FFADDR_W-1:0] mem_wad,
  output reg  [FFDATA_W-1:0] mem_wdt,
  output reg                 mem_re,
  output reg  [FFADDR_W-1:0] mem_rad,
  // FIFO status
  output reg                 di_ovflow,			// Din write overflow
  (* KEEP = "TRUE" *) output reg    [FFADDR_W:0] dt_cnt,			// current available data count
  (* KEEP = "TRUE" *) output reg    [FFADDR_W:0] sp_cnt				// current FIFO space count
);

  // ===========================================================================
  // reg/wire declaration
  // ===========================================================================
  reg    [FFADDR_W:0] wrptr;
  reg    [FFADDR_W:0] rdptr;
  reg                 ff_full_r;
  (* KEEP = "TRUE" *) reg                 ff_afull_r;
  (* max_fanout=64 *) reg  [RD_LTNCY-1:0] rd_dly;

  wire                wr_en;
  wire   [FFADDR_W:0] wrptr_nx;
  wire   [FFADDR_W:0] sp_cnt_nx;
  wire                ff_full;
  wire                ff_afull;
  wire                ff_rdy_mux;
  wire                di_rdy_mux;
  wire   [FFADDR_W:0] wrptr_4_rd;
  wire                do_used;

  integer             ii;

  // ===========================================================================
  // Implementation
  // ===========================================================================
  // ---------------------------------------------------------------------------
  // write pointer operation
  // ---------------------------------------------------------------------------
  //assign wr_en = di_wr & ff_rdy_mux;
  assign wr_en = di_wr;

  assign wrptr_nx = (wrptr + 1'b1);

  always @(posedge clk)
    if (rst)
      wrptr <= {FFADDR_W+1{1'b0}};
    else
      wrptr <= (wr_en) ? wrptr_nx : wrptr;

  // FIFO is full when read/write pointers are equal but MSB bit inverted
  assign ff_full = (wr_en) ?
                     ((wrptr_nx[FFADDR_W] ^ rdptr[FFADDR_W]) &
					  (wrptr_nx[FFADDR_W-1:0] == rdptr[FFADDR_W-1:0])) :
	                 ((wrptr[FFADDR_W] ^ rdptr[FFADDR_W]) &
	                  (wrptr[FFADDR_W-1:0] == rdptr[FFADDR_W-1:0]));

  assign ff_afull = (sp_cnt[FFADDR_W:0] <= cfg_alfull_thrd); 
  
  always @(posedge clk)
    if (rst)
      ff_full_r <= 1'b1;
    else
      ff_full_r <= ff_full;

  always @(posedge clk)
    if (rst)
      ff_afull_r <= 1'b1;
    else
      ff_afull_r <= ff_afull;

  assign di_rdy_mux = (IN_BP_MODE) ? ~ff_afull_r : ~ff_full_r;
  assign ff_rdy_mux = (IN_STRICT_BP) ? di_rdy_mux : ~ff_full_r;

  assign di_if_rdy = di_rdy_mux | ~cfg_bp_en;
  assign di_ff_rdy = ff_rdy_mux;

  always @(posedge clk)
    if (rst)
      di_ovflow <= 1'b0;
    else
      di_ovflow <= wr_en & ff_full_r;

  // ---------------------------------------------------------------------------
  // memory write interface
  // ---------------------------------------------------------------------------
  always @(posedge clk)
    if (rst) begin
      mem_we  <= 1'b0;
      mem_wad <= {FFADDR_W{1'b0}};
      mem_wdt <= {FFDATA_W{1'b0}};
    end
    else begin
      mem_we  <= wr_en;
      mem_wad <= wrptr[FFADDR_W-1:0];
      mem_wdt <= di;
    end

  // ---------------------------------------------------------------------------
  // delay the wrptr by WR_LTNCY clocks to make sure write-data is ready for read
  // ---------------------------------------------------------------------------
generate if (WR_LTNCY >= 1) begin
  reg    [FFADDR_W:0] wrptr_dly [WR_LTNCY-1:0];

  always @(posedge clk)
    if (rst)
      for (ii=0; ii<WR_LTNCY; ii=ii+1)
        wrptr_dly[ii] <= {FFADDR_W+1{1'b0}};
    else begin
      wrptr_dly[0] <= wrptr;
      for (ii=1; ii<WR_LTNCY; ii=ii+1)
        wrptr_dly[ii] <= wrptr_dly[ii-1];
    end

  assign wrptr_4_rd = wrptr_dly[WR_LTNCY-1];
end
endgenerate

generate if (WR_LTNCY == 0) begin
  assign wrptr_4_rd = wrptr;
end
endgenerate

  // ---------------------------------------------------------------------------
  // read pointer operation
  // ---------------------------------------------------------------------------
  assign do_used = do_vld;

  // FIFO is empty when read/write pointers are exactly equal
  assign ff_empty = (wrptr_4_rd[FFADDR_W:0] == rdptr[FFADDR_W:0]);

  always @(posedge clk)
    if (rst)
      rdptr <= {FFADDR_W+1{1'b0}};
    else
      rdptr <= (do_rd) ? (rdptr + 1'b1) : rdptr;

  // ---------------------------------------------------------------------------
  // memory read interface
  // ---------------------------------------------------------------------------
  always @(posedge clk)
    if (rst) begin
      mem_re  <= 1'b0;
      mem_rad <= {FFADDR_W{1'b0}};
    end
    else begin
      mem_re  <= do_rd;
      mem_rad <= rdptr[FFADDR_W-1:0];
    end

  generate if (RD_LTNCY > 1) begin : gen_rd_ltncy_gt_1
    always @(posedge clk)
      if (rst)
        rd_dly <= {RD_LTNCY{1'b0}};
      else
        rd_dly <= {rd_dly[RD_LTNCY-2:0], mem_re};

    assign do_vld = rd_dly[RD_LTNCY-1];
  end
  endgenerate

  generate if (RD_LTNCY == 1) begin : gen_rd_ltncy_eq_1
    always @(posedge clk)
      if (rst)
        rd_dly <= 1'b0;
      else
        rd_dly <= mem_re;

    assign do_vld = rd_dly;
  end
  endgenerate

  // ---------------------------------------------------------------------------
  // statistics for data count and space count 
  // ---------------------------------------------------------------------------
  wire dt_cnt_inc =  wr_en & ~do_used;
  wire dt_cnt_dec = ~wr_en &  do_used;
  wire sp_cnt_inc = ~wr_en &  mem_re;
  wire sp_cnt_dec =  wr_en & ~mem_re;

  always @(posedge clk)
    if (rst)
      dt_cnt <= {FFADDR_W+1{1'b0}};
    else
      //dt_cnt <= (dt_cnt_inc) ? ((dt_cnt[FFADDR_W]) ? dt_cnt : dt_cnt + 1'b1) :
      dt_cnt <= (dt_cnt_inc) ? (&(dt_cnt) ? dt_cnt : dt_cnt + 1'b1) :
                (dt_cnt_dec) ? ((|dt_cnt) ? dt_cnt - 1'b1 : dt_cnt) :
                               dt_cnt;

  assign sp_cnt_nx = (sp_cnt_inc) ? ((&sp_cnt) ? sp_cnt : sp_cnt + 1'b1) :
                     (sp_cnt_dec) ? ((|sp_cnt) ? sp_cnt - 1'b1 : sp_cnt) :
                               sp_cnt;
  always @(posedge clk)
    if (rst)
      sp_cnt <= {1'b1, {FFADDR_W{1'b0}}};
    else
      sp_cnt <= sp_cnt_nx; 
      
endmodule


