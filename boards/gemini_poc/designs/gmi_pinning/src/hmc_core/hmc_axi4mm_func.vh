//==============================================================================
// HMC-Controller Functions
//==============================================================================
// hmc_cov_off
function integer clogb2;
  input integer value;
  begin
    value = value - 1;
    for (clogb2=0; value>0; clogb2=clogb2+1) value = value >> 1;
  end
endfunction

function integer cquotient;
  input real numerator;
  input real denominator;
  begin
    for (cquotient=0; numerator>0; cquotient=cquotient+1) numerator = (numerator > denominator) ? (numerator - denominator) : 0;
  end
endfunction

function [31:0] fn_msb_1_1hvec_32b;
  input [31:0] in;
  reg   [31:0] mask;
  integer      fi, fj;
  begin
    for (fi=31; fi>=0; fi=fi-1) begin
      mask[fi] = in[fi];
      for (fj=31; fj>fi; fj=fj-1)
        mask[fi] = mask[fi] & ~in[fj];
    end
    fn_msb_1_1hvec_32b = mask;
  end
endfunction

function [31:0] fn_lsb_1_1hvec_32b;
  input [31:0] in;
  reg   [31:0] mask;
  integer      fi, fj;
  begin
    for (fi=0; fi<32; fi=fi+1) begin
      mask[fi] = in[fi];
      for (fj=0; fj<fi; fj=fj+1)
        mask[fi] = mask[fi] & ~in[fj];
    end
    fn_lsb_1_1hvec_32b = mask;
  end
endfunction

function [31:0] fn_msb_1_abv_incl_msk_32b;
  input [31:0] in;
  reg   [31:0] in_mask [31:0];
  integer fi, fj;
  begin
    fn_msb_1_abv_incl_msk_32b[31] = 1'b1;
    for (fi=30; fi>=0; fi=fi-1) begin
      in_mask[fi] = in & ({32{1'b1}} << (fi+1));
      fn_msb_1_abv_incl_msk_32b[fi] = (~|in_mask[fi]);
    end
  end
endfunction

function [31:0] fn_lsb_1_abv_incl_msk_32b;
  input [31:0] in;
  reg   [31:0] in_mask [31:0];
  integer fi, fj;
  begin
    for (fi=0; fi<32; fi=fi+1) begin
      in_mask[fi] = in & ({32{1'b1}} >> (31-fi));
      fn_lsb_1_abv_incl_msk_32b[fi] = (|in_mask[fi]);
    end
  end
endfunction

function [31:0] fn_lsb_1_abv_excl_msk_32b;
  input [31:0] in;
  reg   [31:0] in_mask [31:0];
  integer fi, fj;
  begin
    fn_lsb_1_abv_excl_msk_32b[0] = 1'b0;
    for (fi=1; fi<32; fi=fi+1) begin
      in_mask[fi] = in & ({32{1'b1}} >> (32-fi));
      fn_lsb_1_abv_excl_msk_32b[fi] = (|in_mask[fi]);
    end
  end
endfunction

function [31:0] fn_lsb_1_blw_incl_msk_32b;
  input [31:0] in;
  reg   [31:0] in_mask;
  reg          in_1_exist;
  integer fi, fj;
  begin
    in_1_exist = |in;
    for (fi=0; fi<32; fi=fi+1) begin
      in_mask[fi] = 1'b1;
      for (fj=0; fj<fi; fj=fj+1) begin
        in_mask[fi] = in_mask[fi] & ~in[fj];
      end
    end
    fn_lsb_1_blw_incl_msk_32b = in_mask & {32{in_1_exist}};
  end
endfunction

function [4:0] fn_cnt_pktlen_by_ploadvec;
  input [15:0] pload_vec;
  reg   [5:0] in_0;
  reg   [5:0] in_1;
  reg   [2:0] num_0;
  reg   [2:0] num_1;
  reg         pkt_256byte;
  begin
    pkt_256byte = pload_vec[8];
    in_0  = {{6{1'b0}}, pload_vec};
    in_1  = {{6{1'b0}}, (pload_vec >> 6)};
    num_0 = fn_cnt_1s_in_6bits(in_0, 1'b0);
    num_1 = fn_cnt_1s_in_6bits(in_1, 1'b0);
    fn_cnt_pktlen_by_ploadvec = (pkt_256byte) ? 5'd16 :
                                                {1'b0, fn_3bits_adder(num_0, num_1)};
  end
endfunction

function [4:0] fn_conv_1h32b_vec_to_bin;
  input [31:0] vec_in;
  reg    [4:0] bin_val;
  integer fi, fj, fz;
  begin
    for (fi=1; fi<=5; fi=fi+1) begin
      bin_val[5-fi] = 1'b0;
      for (fj=0; fj<(2**(fi-1)); fj=fj+1) begin
        for (fz=0; fz<(32>>fi); fz=fz+1) begin
          bin_val[5-fi] = bin_val[5-fi] | vec_in[32-1-((32>>(fi-1))*fj)-fz];
        end
      end
    end
    fn_conv_1h32b_vec_to_bin = bin_val;
  end
endfunction

function [3:0] fn_cnt_1s_in_12b_vec;
  input [11:0] in;
  input  [3:0] vec_size;
  reg    [5:0] in_0;
  reg    [5:0] in_1;
  reg    [2:0] num_0;
  reg    [2:0] num_1;
  begin
    in_0  = {{6{1'b0}}, in};
    in_1  = {{6{1'b0}}, (in >> 6)};
    num_0 = fn_cnt_1s_in_6bits(in_0, 1'b0);
    num_1 = fn_cnt_1s_in_6bits(in_1, 1'b0);
    fn_cnt_1s_in_12b_vec = ({4{(vec_size <= 6)}} & {1'b0, num_0}) |
                           ({4{(vec_size >= 7)}} & fn_3bits_adder(num_0, num_1));
  end
endfunction

function [2:0] fn_cnt_1s_in_6bits;
  input [5:0] in;
  input       plus1;
  reg   [2:0] num;
  reg   [2:0] num_plus1;
  begin
    case (in)
      6'd00 : num = 3'd0;
      6'd01 : num = 3'd1;
      6'd02 : num = 3'd1;
      6'd03 : num = 3'd2;
      6'd04 : num = 3'd1;
      6'd05 : num = 3'd2;
      6'd06 : num = 3'd2;
      6'd07 : num = 3'd3;
      6'd08 : num = 3'd1;
      6'd09 : num = 3'd2;
      6'd10 : num = 3'd2;
      6'd11 : num = 3'd3;
      6'd12 : num = 3'd2;
      6'd13 : num = 3'd3;
      6'd14 : num = 3'd3;
      6'd15 : num = 3'd4;
      6'd16 : num = 3'd1;
      6'd17 : num = 3'd2;
      6'd18 : num = 3'd2;
      6'd19 : num = 3'd3;
      6'd20 : num = 3'd2;
      6'd21 : num = 3'd3;
      6'd22 : num = 3'd3;
      6'd23 : num = 3'd4;
      6'd24 : num = 3'd2;
      6'd25 : num = 3'd3;
      6'd26 : num = 3'd3;
      6'd27 : num = 3'd4;
      6'd28 : num = 3'd3;
      6'd29 : num = 3'd4;
      6'd30 : num = 3'd4;
      6'd31 : num = 3'd5;
      6'd32 : num = 3'd1;
      6'd33 : num = 3'd2;
      6'd34 : num = 3'd2;
      6'd35 : num = 3'd3;
      6'd36 : num = 3'd2;
      6'd37 : num = 3'd3;
      6'd38 : num = 3'd3;
      6'd39 : num = 3'd4;
      6'd40 : num = 3'd2;
      6'd41 : num = 3'd3;
      6'd42 : num = 3'd3;
      6'd43 : num = 3'd4;
      6'd44 : num = 3'd3;
      6'd45 : num = 3'd4;
      6'd46 : num = 3'd4;
      6'd47 : num = 3'd5;
      6'd48 : num = 3'd2;
      6'd49 : num = 3'd3;
      6'd50 : num = 3'd3;
      6'd51 : num = 3'd4;
      6'd52 : num = 3'd3;
      6'd53 : num = 3'd4;
      6'd54 : num = 3'd4;
      6'd55 : num = 3'd5;
      6'd56 : num = 3'd3;
      6'd57 : num = 3'd4;
      6'd58 : num = 3'd4;
      6'd59 : num = 3'd5;
      6'd60 : num = 3'd4;
      6'd61 : num = 3'd5;
      6'd62 : num = 3'd5;
      6'd63 : num = 3'd6;
    endcase
    case (in)
      6'd00 : num_plus1 = 3'd0 + 3'd1;
      6'd01 : num_plus1 = 3'd1 + 3'd1;
      6'd02 : num_plus1 = 3'd1 + 3'd1;
      6'd03 : num_plus1 = 3'd2 + 3'd1;
      6'd04 : num_plus1 = 3'd1 + 3'd1;
      6'd05 : num_plus1 = 3'd2 + 3'd1;
      6'd06 : num_plus1 = 3'd2 + 3'd1;
      6'd07 : num_plus1 = 3'd3 + 3'd1;
      6'd08 : num_plus1 = 3'd1 + 3'd1;
      6'd09 : num_plus1 = 3'd2 + 3'd1;
      6'd10 : num_plus1 = 3'd2 + 3'd1;
      6'd11 : num_plus1 = 3'd3 + 3'd1;
      6'd12 : num_plus1 = 3'd2 + 3'd1;
      6'd13 : num_plus1 = 3'd3 + 3'd1;
      6'd14 : num_plus1 = 3'd3 + 3'd1;
      6'd15 : num_plus1 = 3'd4 + 3'd1;
      6'd16 : num_plus1 = 3'd1 + 3'd1;
      6'd17 : num_plus1 = 3'd2 + 3'd1;
      6'd18 : num_plus1 = 3'd2 + 3'd1;
      6'd19 : num_plus1 = 3'd3 + 3'd1;
      6'd20 : num_plus1 = 3'd2 + 3'd1;
      6'd21 : num_plus1 = 3'd3 + 3'd1;
      6'd22 : num_plus1 = 3'd3 + 3'd1;
      6'd23 : num_plus1 = 3'd4 + 3'd1;
      6'd24 : num_plus1 = 3'd2 + 3'd1;
      6'd25 : num_plus1 = 3'd3 + 3'd1;
      6'd26 : num_plus1 = 3'd3 + 3'd1;
      6'd27 : num_plus1 = 3'd4 + 3'd1;
      6'd28 : num_plus1 = 3'd3 + 3'd1;
      6'd29 : num_plus1 = 3'd4 + 3'd1;
      6'd30 : num_plus1 = 3'd4 + 3'd1;
      6'd31 : num_plus1 = 3'd5 + 3'd1;
      6'd32 : num_plus1 = 3'd1 + 3'd1;
      6'd33 : num_plus1 = 3'd2 + 3'd1;
      6'd34 : num_plus1 = 3'd2 + 3'd1;
      6'd35 : num_plus1 = 3'd3 + 3'd1;
      6'd36 : num_plus1 = 3'd2 + 3'd1;
      6'd37 : num_plus1 = 3'd3 + 3'd1;
      6'd38 : num_plus1 = 3'd3 + 3'd1;
      6'd39 : num_plus1 = 3'd4 + 3'd1;
      6'd40 : num_plus1 = 3'd2 + 3'd1;
      6'd41 : num_plus1 = 3'd3 + 3'd1;
      6'd42 : num_plus1 = 3'd3 + 3'd1;
      6'd43 : num_plus1 = 3'd4 + 3'd1;
      6'd44 : num_plus1 = 3'd3 + 3'd1;
      6'd45 : num_plus1 = 3'd4 + 3'd1;
      6'd46 : num_plus1 = 3'd4 + 3'd1;
      6'd47 : num_plus1 = 3'd5 + 3'd1;
      6'd48 : num_plus1 = 3'd2 + 3'd1;
      6'd49 : num_plus1 = 3'd3 + 3'd1;
      6'd50 : num_plus1 = 3'd3 + 3'd1;
      6'd51 : num_plus1 = 3'd4 + 3'd1;
      6'd52 : num_plus1 = 3'd3 + 3'd1;
      6'd53 : num_plus1 = 3'd4 + 3'd1;
      6'd54 : num_plus1 = 3'd4 + 3'd1;
      6'd55 : num_plus1 = 3'd5 + 3'd1;
      6'd56 : num_plus1 = 3'd3 + 3'd1;
      6'd57 : num_plus1 = 3'd4 + 3'd1;
      6'd58 : num_plus1 = 3'd4 + 3'd1;
      6'd59 : num_plus1 = 3'd5 + 3'd1;
      6'd60 : num_plus1 = 3'd4 + 3'd1;
      6'd61 : num_plus1 = 3'd5 + 3'd1;
      6'd62 : num_plus1 = 3'd5 + 3'd1;
      6'd63 : num_plus1 = 3'd6 + 3'd1;
    endcase
    fn_cnt_1s_in_6bits = (plus1) ? num_plus1 : num;
  end
endfunction

function [3:0] fn_3bits_adder;
  input [2:0] in1;
  input [2:0] in2;
  reg   [3:0] num;
  begin
    case ({in2, in1})
      6'd00 : num = 4'd0;
      6'd01 : num = 4'd1;
      6'd02 : num = 4'd2;
      6'd03 : num = 4'd3;
      6'd04 : num = 4'd4;
      6'd05 : num = 4'd5;
      6'd06 : num = 4'd6;
      6'd07 : num = 4'd7;
      6'd08 : num = 4'd1;
      6'd09 : num = 4'd2;
      6'd10 : num = 4'd3;
      6'd11 : num = 4'd4;
      6'd12 : num = 4'd5;
      6'd13 : num = 4'd6;
      6'd14 : num = 4'd7;
      6'd15 : num = 4'd8;
      6'd16 : num = 4'd2;
      6'd17 : num = 4'd3;
      6'd18 : num = 4'd4;
      6'd19 : num = 4'd5;
      6'd20 : num = 4'd6;
      6'd21 : num = 4'd7;
      6'd22 : num = 4'd8;
      6'd23 : num = 4'd9;
      6'd24 : num = 4'd3;
      6'd25 : num = 4'd4;
      6'd26 : num = 4'd5;
      6'd27 : num = 4'd6;
      6'd28 : num = 4'd7;
      6'd29 : num = 4'd8;
      6'd30 : num = 4'd9;
      6'd31 : num = 4'd10;
      6'd32 : num = 4'd4;
      6'd33 : num = 4'd5;
      6'd34 : num = 4'd6;
      6'd35 : num = 4'd7;
      6'd36 : num = 4'd8;
      6'd37 : num = 4'd9;
      6'd38 : num = 4'd10;
      6'd39 : num = 4'd11;
      6'd40 : num = 4'd5;
      6'd41 : num = 4'd6;
      6'd42 : num = 4'd7;
      6'd43 : num = 4'd8;
      6'd44 : num = 4'd9;
      6'd45 : num = 4'd10;
      6'd46 : num = 4'd11;
      6'd47 : num = 4'd12;
      6'd48 : num = 4'd6;
      6'd49 : num = 4'd7;
      6'd50 : num = 4'd8;
      6'd51 : num = 4'd9;
      6'd52 : num = 4'd10;
      6'd53 : num = 4'd11;
      6'd54 : num = 4'd12;
      6'd55 : num = 4'd13;
      6'd56 : num = 4'd7;
      6'd57 : num = 4'd8;
      6'd58 : num = 4'd9;
      6'd59 : num = 4'd10;
      6'd60 : num = 4'd11;
      6'd61 : num = 4'd12;
      6'd62 : num = 4'd13;
      6'd63 : num = 4'd14;
    endcase
    fn_3bits_adder = num;
  end
endfunction

function [5:0] fn_6bits_cnt_inc_1;
  input [5:0] in;
  begin
    case (in)
      6'd00 : fn_6bits_cnt_inc_1 = 6'd00 + 1'b1;
      6'd01 : fn_6bits_cnt_inc_1 = 6'd01 + 1'b1;
      6'd02 : fn_6bits_cnt_inc_1 = 6'd02 + 1'b1;
      6'd03 : fn_6bits_cnt_inc_1 = 6'd03 + 1'b1;
      6'd04 : fn_6bits_cnt_inc_1 = 6'd04 + 1'b1;
      6'd05 : fn_6bits_cnt_inc_1 = 6'd05 + 1'b1;
      6'd06 : fn_6bits_cnt_inc_1 = 6'd06 + 1'b1;
      6'd07 : fn_6bits_cnt_inc_1 = 6'd07 + 1'b1;
      6'd08 : fn_6bits_cnt_inc_1 = 6'd08 + 1'b1;
      6'd09 : fn_6bits_cnt_inc_1 = 6'd09 + 1'b1;
      6'd10 : fn_6bits_cnt_inc_1 = 6'd10 + 1'b1;
      6'd11 : fn_6bits_cnt_inc_1 = 6'd11 + 1'b1;
      6'd12 : fn_6bits_cnt_inc_1 = 6'd12 + 1'b1;
      6'd13 : fn_6bits_cnt_inc_1 = 6'd13 + 1'b1;
      6'd14 : fn_6bits_cnt_inc_1 = 6'd14 + 1'b1;
      6'd15 : fn_6bits_cnt_inc_1 = 6'd15 + 1'b1;
      6'd16 : fn_6bits_cnt_inc_1 = 6'd16 + 1'b1;
      6'd17 : fn_6bits_cnt_inc_1 = 6'd17 + 1'b1;
      6'd18 : fn_6bits_cnt_inc_1 = 6'd18 + 1'b1;
      6'd19 : fn_6bits_cnt_inc_1 = 6'd19 + 1'b1;
      6'd20 : fn_6bits_cnt_inc_1 = 6'd20 + 1'b1;
      6'd21 : fn_6bits_cnt_inc_1 = 6'd21 + 1'b1;
      6'd22 : fn_6bits_cnt_inc_1 = 6'd22 + 1'b1;
      6'd23 : fn_6bits_cnt_inc_1 = 6'd23 + 1'b1;
      6'd24 : fn_6bits_cnt_inc_1 = 6'd24 + 1'b1;
      6'd25 : fn_6bits_cnt_inc_1 = 6'd25 + 1'b1;
      6'd26 : fn_6bits_cnt_inc_1 = 6'd26 + 1'b1;
      6'd27 : fn_6bits_cnt_inc_1 = 6'd27 + 1'b1;
      6'd28 : fn_6bits_cnt_inc_1 = 6'd28 + 1'b1;
      6'd29 : fn_6bits_cnt_inc_1 = 6'd29 + 1'b1;
      6'd30 : fn_6bits_cnt_inc_1 = 6'd30 + 1'b1;
      6'd31 : fn_6bits_cnt_inc_1 = 6'd31 + 1'b1;
      6'd32 : fn_6bits_cnt_inc_1 = 6'd32 + 1'b1;
      6'd33 : fn_6bits_cnt_inc_1 = 6'd33 + 1'b1;
      6'd34 : fn_6bits_cnt_inc_1 = 6'd34 + 1'b1;
      6'd35 : fn_6bits_cnt_inc_1 = 6'd35 + 1'b1;
      6'd36 : fn_6bits_cnt_inc_1 = 6'd36 + 1'b1;
      6'd37 : fn_6bits_cnt_inc_1 = 6'd37 + 1'b1;
      6'd38 : fn_6bits_cnt_inc_1 = 6'd38 + 1'b1;
      6'd39 : fn_6bits_cnt_inc_1 = 6'd39 + 1'b1;
      6'd40 : fn_6bits_cnt_inc_1 = 6'd40 + 1'b1;
      6'd41 : fn_6bits_cnt_inc_1 = 6'd41 + 1'b1;
      6'd42 : fn_6bits_cnt_inc_1 = 6'd42 + 1'b1;
      6'd43 : fn_6bits_cnt_inc_1 = 6'd43 + 1'b1;
      6'd44 : fn_6bits_cnt_inc_1 = 6'd44 + 1'b1;
      6'd45 : fn_6bits_cnt_inc_1 = 6'd45 + 1'b1;
      6'd46 : fn_6bits_cnt_inc_1 = 6'd46 + 1'b1;
      6'd47 : fn_6bits_cnt_inc_1 = 6'd47 + 1'b1;
      6'd48 : fn_6bits_cnt_inc_1 = 6'd48 + 1'b1;
      6'd49 : fn_6bits_cnt_inc_1 = 6'd49 + 1'b1;
      6'd50 : fn_6bits_cnt_inc_1 = 6'd50 + 1'b1;
      6'd51 : fn_6bits_cnt_inc_1 = 6'd51 + 1'b1;
      6'd52 : fn_6bits_cnt_inc_1 = 6'd52 + 1'b1;
      6'd53 : fn_6bits_cnt_inc_1 = 6'd53 + 1'b1;
      6'd54 : fn_6bits_cnt_inc_1 = 6'd54 + 1'b1;
      6'd55 : fn_6bits_cnt_inc_1 = 6'd55 + 1'b1;
      6'd56 : fn_6bits_cnt_inc_1 = 6'd56 + 1'b1;
      6'd57 : fn_6bits_cnt_inc_1 = 6'd57 + 1'b1;
      6'd58 : fn_6bits_cnt_inc_1 = 6'd58 + 1'b1;
      6'd59 : fn_6bits_cnt_inc_1 = 6'd59 + 1'b1;
      6'd60 : fn_6bits_cnt_inc_1 = 6'd60 + 1'b1;
      6'd61 : fn_6bits_cnt_inc_1 = 6'd61 + 1'b1;
      6'd62 : fn_6bits_cnt_inc_1 = 6'd62 + 1'b1;
      6'd63 : fn_6bits_cnt_inc_1 = 6'd63 + 1'b1;
    endcase
  end
endfunction

function [5:0] fn_6bits_cnt_dec_1;
  input [5:0] in;
  begin
    case (in)
      6'd00 : fn_6bits_cnt_dec_1 = 6'd00 - 1'b0;
      6'd01 : fn_6bits_cnt_dec_1 = 6'd01 - 1'b1;
      6'd02 : fn_6bits_cnt_dec_1 = 6'd02 - 1'b1;
      6'd03 : fn_6bits_cnt_dec_1 = 6'd03 - 1'b1;
      6'd04 : fn_6bits_cnt_dec_1 = 6'd04 - 1'b1;
      6'd05 : fn_6bits_cnt_dec_1 = 6'd05 - 1'b1;
      6'd06 : fn_6bits_cnt_dec_1 = 6'd06 - 1'b1;
      6'd07 : fn_6bits_cnt_dec_1 = 6'd07 - 1'b1;
      6'd08 : fn_6bits_cnt_dec_1 = 6'd08 - 1'b1;
      6'd09 : fn_6bits_cnt_dec_1 = 6'd09 - 1'b1;
      6'd10 : fn_6bits_cnt_dec_1 = 6'd10 - 1'b1;
      6'd11 : fn_6bits_cnt_dec_1 = 6'd11 - 1'b1;
      6'd12 : fn_6bits_cnt_dec_1 = 6'd12 - 1'b1;
      6'd13 : fn_6bits_cnt_dec_1 = 6'd13 - 1'b1;
      6'd14 : fn_6bits_cnt_dec_1 = 6'd14 - 1'b1;
      6'd15 : fn_6bits_cnt_dec_1 = 6'd15 - 1'b1;
      6'd16 : fn_6bits_cnt_dec_1 = 6'd16 - 1'b1;
      6'd17 : fn_6bits_cnt_dec_1 = 6'd17 - 1'b1;
      6'd18 : fn_6bits_cnt_dec_1 = 6'd18 - 1'b1;
      6'd19 : fn_6bits_cnt_dec_1 = 6'd19 - 1'b1;
      6'd20 : fn_6bits_cnt_dec_1 = 6'd20 - 1'b1;
      6'd21 : fn_6bits_cnt_dec_1 = 6'd21 - 1'b1;
      6'd22 : fn_6bits_cnt_dec_1 = 6'd22 - 1'b1;
      6'd23 : fn_6bits_cnt_dec_1 = 6'd23 - 1'b1;
      6'd24 : fn_6bits_cnt_dec_1 = 6'd24 - 1'b1;
      6'd25 : fn_6bits_cnt_dec_1 = 6'd25 - 1'b1;
      6'd26 : fn_6bits_cnt_dec_1 = 6'd26 - 1'b1;
      6'd27 : fn_6bits_cnt_dec_1 = 6'd27 - 1'b1;
      6'd28 : fn_6bits_cnt_dec_1 = 6'd28 - 1'b1;
      6'd29 : fn_6bits_cnt_dec_1 = 6'd29 - 1'b1;
      6'd30 : fn_6bits_cnt_dec_1 = 6'd30 - 1'b1;
      6'd31 : fn_6bits_cnt_dec_1 = 6'd31 - 1'b1;
      6'd32 : fn_6bits_cnt_dec_1 = 6'd32 - 1'b1;
      6'd33 : fn_6bits_cnt_dec_1 = 6'd33 - 1'b1;
      6'd34 : fn_6bits_cnt_dec_1 = 6'd34 - 1'b1;
      6'd35 : fn_6bits_cnt_dec_1 = 6'd35 - 1'b1;
      6'd36 : fn_6bits_cnt_dec_1 = 6'd36 - 1'b1;
      6'd37 : fn_6bits_cnt_dec_1 = 6'd37 - 1'b1;
      6'd38 : fn_6bits_cnt_dec_1 = 6'd38 - 1'b1;
      6'd39 : fn_6bits_cnt_dec_1 = 6'd39 - 1'b1;
      6'd40 : fn_6bits_cnt_dec_1 = 6'd40 - 1'b1;
      6'd41 : fn_6bits_cnt_dec_1 = 6'd41 - 1'b1;
      6'd42 : fn_6bits_cnt_dec_1 = 6'd42 - 1'b1;
      6'd43 : fn_6bits_cnt_dec_1 = 6'd43 - 1'b1;
      6'd44 : fn_6bits_cnt_dec_1 = 6'd44 - 1'b1;
      6'd45 : fn_6bits_cnt_dec_1 = 6'd45 - 1'b1;
      6'd46 : fn_6bits_cnt_dec_1 = 6'd46 - 1'b1;
      6'd47 : fn_6bits_cnt_dec_1 = 6'd47 - 1'b1;
      6'd48 : fn_6bits_cnt_dec_1 = 6'd48 - 1'b1;
      6'd49 : fn_6bits_cnt_dec_1 = 6'd49 - 1'b1;
      6'd50 : fn_6bits_cnt_dec_1 = 6'd50 - 1'b1;
      6'd51 : fn_6bits_cnt_dec_1 = 6'd51 - 1'b1;
      6'd52 : fn_6bits_cnt_dec_1 = 6'd52 - 1'b1;
      6'd53 : fn_6bits_cnt_dec_1 = 6'd53 - 1'b1;
      6'd54 : fn_6bits_cnt_dec_1 = 6'd54 - 1'b1;
      6'd55 : fn_6bits_cnt_dec_1 = 6'd55 - 1'b1;
      6'd56 : fn_6bits_cnt_dec_1 = 6'd56 - 1'b1;
      6'd57 : fn_6bits_cnt_dec_1 = 6'd57 - 1'b1;
      6'd58 : fn_6bits_cnt_dec_1 = 6'd58 - 1'b1;
      6'd59 : fn_6bits_cnt_dec_1 = 6'd59 - 1'b1;
      6'd60 : fn_6bits_cnt_dec_1 = 6'd60 - 1'b1;
      6'd61 : fn_6bits_cnt_dec_1 = 6'd61 - 1'b1;
      6'd62 : fn_6bits_cnt_dec_1 = 6'd62 - 1'b1;
      6'd63 : fn_6bits_cnt_dec_1 = 6'd63 - 1'b1;
    endcase
  end
endfunction
// hmc_cov_on


