`timescale 1ns/1ps

module  example_hmc_lfsr 
  #(parameter DATA_WIDTH = 48,
    parameter PRBS_SIZE  = 15,
    parameter PRBS_POLY  = 15'b100000000000011
  ) (
    input       [PRBS_SIZE-1:0] lfsr_in,
    output reg  [PRBS_SIZE-1:0] lfsr_out,
    output reg [DATA_WIDTH-1:0] prbs_out
);

  reg [PRBS_SIZE-1:0] lfsr_var;		// temp variables used in LFSR calculation

  integer i;

  always @(*) begin : lfsr_loop
    lfsr_var = lfsr_in;
    for(i=0; i<DATA_WIDTH; i=i+1) begin
       prbs_out[i] = lfsr_var[0];
       lfsr_var = {(^(PRBS_POLY & {1'b0, lfsr_var[PRBS_SIZE-2:0]})), lfsr_var[PRBS_SIZE-1:1]};
    end
    lfsr_out = lfsr_var;
  end

endmodule


