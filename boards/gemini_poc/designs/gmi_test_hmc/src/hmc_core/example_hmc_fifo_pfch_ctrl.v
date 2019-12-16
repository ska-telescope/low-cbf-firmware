// =============================================================================
// * Pre-fetch data in local buffer to compensate memory read latency and
//   provide the capability of no-gap burst read
// * In general, it needs to prefetch (memory_read_latency + 1) of data locally
//   in order to achieve no-gap transmission.
// * This module prefetches (PFCH_NUM + 1) of data
// =============================================================================

`timescale 1ns/1ps


module  example_hmc_fifo_pfch_ctrl 
  #(parameter FFDATA_W=512,
              PFCH_NUM=3,			// MIN=1
              USE_DIST_RAM=1,		// use Distributed-RAM
              ACT_FETCH_MODE=1,		// 1: Active fetching mode; 0: Passive buffer mode
              MAX_PFCH_N=PFCH_NUM
  ) (
  input                      clk,
  input                      rst,
  // to FIFO
  input                      fifo_empty,	// FIFO is empty. must be independent of fifo_di_req
  output wire                fifo_di_rdy,	// FIFO data input ready
  output wire                fifo_di_req,	// FIFO data input request. use combinational output for continuous data
  input                      fifo_di_vld,	// FIFO data input valid
  input       [FFDATA_W-1:0] fifo_di_data,	// FIFO data input
  output wire                pfch_buf_full,	// pre-fetch buffers full
  // to output
  output wire                pfch_do_vld,	// pre-fetch output data is valid
  output wire [FFDATA_W-1:0] pfch_do_data,	// pre-fetch output data
  input                      pfch_do_ack	// pre-fetch output data acknowledge
);

  localparam PFCH_N_LOG2 = clogb2(PFCH_NUM);
  localparam BUFADDR_W   = maxof2(PFCH_N_LOG2, 1);

  function integer clogb2;
    input integer value;
    begin
      value = value - 1;
      for (clogb2=0; value>0; clogb2=clogb2+1) value = value >> 1;
    end
  endfunction

  function integer maxof2;
    input integer value1;
    input integer value2;
    begin
      maxof2 = (value2 > value1) ? value2 : value1;
    end
  endfunction

  // ===========================================================================
  // reg/wire declaration
  // ===========================================================================
  (* max_fanout=64 *) reg  [BUFADDR_W-1:0] pfch_buf_wptr;	// pre-fetch buffer write pointer
  (* max_fanout=64 *) reg  [BUFADDR_W-1:0] pfch_buf_rptr;	// pre-fetch buffer read pointer
  reg    [BUFADDR_W:0] pfch_buf_cnt;	// pre-fetch buffer stored data count
  reg    [BUFADDR_W:0] pfch_req_cnt;	// pre-fetch buffer requested (pending) data count
  (* max_fanout=64  *) reg                 pfch_do_vld_r;	// pre-fetch output data is valid
  (* max_fanout=256 *) reg  [FFDATA_W-1:0] pfch_do_data_r;	// pre-fetch output data

  (* max_fanout=64 *) wire pfch_buf_push;	// pre-fetch buffer push
  (* max_fanout=64 *) wire pfch_buf_pop;	// pre-fetch buffer pop to output register
  wire  [FFDATA_W-1:0] pfch_buf_rdt;	// read data output from pfch_dt_buf
  wire [BUFADDR_W-1:0] buf_wptr_nxt;	// next buffer write pointer
  wire [BUFADDR_W-1:0] buf_rptr_nxt;	// next buffer read pointer

  integer ii;

  // ===========================================================================
  // Implementation
  // ===========================================================================
  generate
    if (ACT_FETCH_MODE == 1) begin : genblk_auto_fetch_mode
    // ---------------------------------------------------------------------------
    // pre-fetch data request from FIFO
    // ---------------------------------------------------------------------------
      // request data when (pfch_req_cnt < MAX_PFCH_N) and FIFO is not empty
      assign fifo_di_rdy = (pfch_req_cnt < MAX_PFCH_N);
      assign fifo_di_req = ~fifo_empty & fifo_di_rdy;

      always @(posedge clk)
        if (rst)
          pfch_req_cnt <= {BUFADDR_W+1{1'b0}};
        else
          pfch_req_cnt <= (fifo_di_req & ~pfch_buf_pop) ? pfch_req_cnt + 1'b1 :
                          (~fifo_di_req & pfch_buf_pop) ? pfch_req_cnt - 1'b1 :
                                                          pfch_req_cnt;
    end
    else begin : genblk_passive_buffer_mode
      // request data when (pfch_buf_cnt < MAX_PFCH_N)
      assign fifo_di_rdy = (pfch_buf_cnt < MAX_PFCH_N);
      assign fifo_di_req = 1'b0;
    end
  endgenerate

  // ---------------------------------------------------------------------------
  // pre-fetch buffer push action
  // ---------------------------------------------------------------------------
  assign pfch_buf_push = fifo_di_vld & ~pfch_buf_full;

  // buffer write pointer
  assign buf_wptr_nxt = (pfch_buf_wptr == (PFCH_NUM-1)) ? {BUFADDR_W{1'b0}} : (pfch_buf_wptr + 1'b1);

  always @(posedge clk)
    if (rst)
      pfch_buf_wptr <= {BUFADDR_W{1'b0}};
    else
      pfch_buf_wptr <= (pfch_buf_push) ? buf_wptr_nxt : pfch_buf_wptr;

  generate
    if (USE_DIST_RAM == 1) begin : genblk_buf_dist_ram
      (* ram_style="distributed" *) reg [FFDATA_W-1:0] pfch_dt_buf [PFCH_NUM-1:0];	// local pre-fetch buffers
      // buffer write
      always @(posedge clk) begin
        if (pfch_buf_push)
          pfch_dt_buf[pfch_buf_wptr] <= fifo_di_data;
      end
      // buffer read
      assign pfch_buf_rdt = pfch_dt_buf[pfch_buf_rptr];
    end
    else begin : genblk_buf_register
      (* keep="TRUE" *) reg [FFDATA_W-1:0] pfch_dt_buf [PFCH_NUM-1:0];	// local pre-fetch buffers
      // buffer write
      always @(posedge clk) begin
        if (rst)
          for (ii=0; ii<PFCH_NUM; ii=ii+1)
            pfch_dt_buf[ii] <= {FFDATA_W{1'b0}};
        else if (pfch_buf_push)
          for (ii=0; ii<PFCH_NUM; ii=ii+1)
            pfch_dt_buf[ii] <= (pfch_buf_wptr == ii) ? fifo_di_data : pfch_dt_buf[ii];
      end
      // buffer read
      assign pfch_buf_rdt = pfch_dt_buf[pfch_buf_rptr];
    end
  endgenerate

  // buffer data count
  always @(posedge clk)
    if (rst)
      pfch_buf_cnt <= {BUFADDR_W+1{1'b0}};
    else
      pfch_buf_cnt <= (pfch_buf_push & ~pfch_buf_pop) ? pfch_buf_cnt + 1'b1 :
                      (~pfch_buf_push & pfch_buf_pop) ? pfch_buf_cnt - 1'b1 :
                                                        pfch_buf_cnt;

  assign pfch_buf_full = (pfch_buf_cnt == PFCH_NUM);

  // ---------------------------------------------------------------------------
  // load pre-fetch data from buffers to output
  // ---------------------------------------------------------------------------
  assign pfch_buf_pop = (|pfch_buf_cnt) & (~pfch_do_vld | pfch_do_ack);

  // buffer read pointer
  assign buf_rptr_nxt = (pfch_buf_rptr == (PFCH_NUM-1)) ? {BUFADDR_W{1'b0}} : (pfch_buf_rptr + 1'b1);

  always @(posedge clk)
    if (rst)
      pfch_buf_rptr <= {BUFADDR_W{1'b0}};
    else
      pfch_buf_rptr <= (pfch_buf_pop) ? buf_rptr_nxt : pfch_buf_rptr;

  always @(posedge clk)
    if (rst)
      pfch_do_vld_r <= 1'b0;
    else
      pfch_do_vld_r <= pfch_buf_pop | (pfch_do_vld_r & ~pfch_do_ack);

  always @(posedge clk)
    if (rst)
      pfch_do_data_r <= {FFDATA_W{1'b0}};
    else
      pfch_do_data_r <= (pfch_buf_pop) ? pfch_buf_rdt : pfch_do_data_r;

  assign pfch_do_vld  = pfch_do_vld_r;
  assign pfch_do_data = pfch_do_data_r;

endmodule


