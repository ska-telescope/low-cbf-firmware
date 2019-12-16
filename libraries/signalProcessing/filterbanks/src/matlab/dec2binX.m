function [b1] = dec2binX(din,bitwidth)
% convert din to binary with a given bitwidth

if (din < 0)
   din = 2^bitwidth + din;
end

b0 = dec2bin(din);
if (length(b0) > bitwidth)
   disp(length(b0));
   disp(bitwidth);
   error('data too big in dec2binX to fit in requested bitwidth');
end   

if (length(b0) < bitwidth)
   % pad with zeros
   b1(1:bitwidth) = '0';
   b1((bitwidth - length(b0) + 1):bitwidth) = b0;
else
   b1 = b0;
end



