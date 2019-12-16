module lfsr_generator(
    input              clk,
    input              reset,
    input              dv_in,
    output             dv_out,
    output     [31:0]  dataout);

    wire   [31:0]  next_lfsr;
    reg   [31:0]  dataout_temp;
    reg           dv_out_temp;

    lfsr #(.WIDTH(32)) lfsr_inst (.datain(dataout), .dataout(next_lfsr));

    always @(posedge clk) begin
        if (reset==1) begin
            dataout_temp <= 1;
            dv_out_temp  <= 0;
        end else begin
            dv_out_temp <= dv_in;
            if (dv_in==1) dataout_temp <= next_lfsr;
        end
    end
    assign dataout = dataout_temp;
    assign dv_out = dv_out_temp;

endmodule
