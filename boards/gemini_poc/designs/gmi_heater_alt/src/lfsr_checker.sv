
module lfsr_checker (
    input              clk,
    input              reset,
    input      [31:0]  datain,
    output             err);

    wire   [31:0]  next_lfsr;
    reg    [31:0]  next_lfsr_q;

    lfsr #(.WIDTH(32)) lfsr_inst (.datain(datain), .dataout(next_lfsr));

    always @(posedge clk) next_lfsr_q <= next_lfsr;
    reg compare, temp_error;
    always @(posedge clk) if (next_lfsr_q == datain) compare <= 1; else compare <= 0;
    always @(posedge clk) if (reset == 1) temp_error <= 0; else if (!compare) temp_error <= 1;
 
    assign err = temp_error;
      
endmodule
