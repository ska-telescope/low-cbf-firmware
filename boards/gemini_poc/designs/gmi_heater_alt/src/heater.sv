// This is a block of logic that is designed to to just burn power.  It uses 
// DSP48, SRL, BRAM and CLB logic in a balanced way.  Pipelining has been
// used so that the clock speed can run close to the peak operating frequency of the FPGA.
// Local parameters have been provided so that the mix of logic can be tuned for a particular part.
// Multiple channels can be instantiated and then enabled individually in order to scale power consumption.
// An LFSR is used as the data source so the toggle rate is exactly 50%. Knowing
// the toggle rate allows Xpower to predict current draw very accurately.
// A checker is at the end of the pipe to verify that the logic is running error free.
// Use with caution. Such a design can easily exceed current and thermal limitations 
// of a board.
module heater (
    input                  clk,
    input                  enable,
    input                  err_clear,
    output                 err);
    
    reg  reset, reset_pre;
    always @(posedge clk) reset_pre <= ~enable;
    always @(posedge clk) reset <= reset_pre;
    
    // an lfsr data source
    wire [31:0] lfsr_dout;    
    lfsr_generator lfsr_gen_inst(.clk(clk), .reset(reset), .dv_in(1), .dv_out(), .dataout(lfsr_dout));

    // some srl delays
    localparam Nsrl = 6;
    wire [Nsrl-1:0] srl_dout[31:0];
    srl32 srl32_0(.CLK(clk), .D(lfsr_dout), .Q(srl_dout[0]));
    genvar i,j;  
    generate for (i=1;i<Nsrl;i=i+1) begin: gen_srl
        srl32 srl32_1(.CLK(clk), .D(srl_dout[i-1]), .Q(srl_dout[i]));
    end endgenerate

    // some BRAM delays
    localparam Nbram = 4;
    wire [Nbram-1:0] bram_dout[31:0];
    (* dont_touch="true" *)reg [Nbram-1:0] count[9:0];
    generate for (i=0;i<Nbram;i=i+1) begin: gen_count
        always @(posedge clk) count[i]=count[i]+1;
    end endgenerate
    sp_bram sp_bram_0(.clka(clk), .wea(1), .addra(count[0]), .dina(srl_dout[Nsrl-1]),  .douta(bram_dout[0]));
    generate for (i=1;i<Nbram;i=i+1) begin: gen_bram
        sp_bram sp_bram_1(.clka(clk), .wea(1), .addra(count[i]), .dina(bram_dout[i-1]), .douta(bram_dout[i]));
    end endgenerate

    // some DSP48 delays
    localparam Ndsp = 6;
    wire [Ndsp-1:0] dsp_dout[47:0];
    reg [Ndsp-1:0] dsp_dout_q[47:0];
    dsp_nop dsp_0(.CLK(clk), .D(0), .C({16'd0, bram_dout[Nbram-1]}), .P(dsp_dout[0]));
    always @(posedge clk) dsp_dout_q[0] <= dsp_dout[0];
    generate for (i=1;i<Ndsp;i=i+1) begin: gen_dsp
        dsp_nop dsp_1(.CLK(clk), .D(0), .C(dsp_dout_q[i-1]), .P(dsp_dout[i]));
        always @(posedge clk) dsp_dout_q[i] <= dsp_dout[i];
    end endgenerate

    // some pipeline registers
    localparam Npipe = 64;
    reg [Npipe-1:0] ff_dout[31:0];
    wire [Npipe-1:0] ff_dout_wire[31:0];
    always @(posedge clk) ff_dout[0] <= dsp_dout_q[Ndsp-1];//[31:0];
    generate  for (i=1; i<Npipe; i=i+1) begin: gen_reg 
        assign ff_dout_wire[i] = ff_dout[i];
        for (j=0; j<32; j=j+1) begin: gen_ff
            (* dont_touch="true" *) FDRE FDRE_inst(.Q(ff_dout_wire[i][j]), .C(clk), .CE(1), .R(0), .D(ff_dout[i-1][j]));
        end  
    end  endgenerate 
    
    // an lsfr data checker
    lfsr_checker lfsr_check_inst(.clk(clk), .reset(err_clear), .datain(ff_dout[Npipe-1]), .err(err));

endmodule


