% Get the ROM contents for the FIR filter coefficients

PSSFilterbankTaps = round(2^17 * generate_MaxFlt(64,12));   % PSS, 64 point FFT, 12 taps.
PSTFilterbankTaps = round(2^17 * generate_MaxFlt(256,12));  % PST, 256 point FFT, 12 taps
correlatorFilterbankTaps = round(2^17 * generate_MaxFlt(4096,12)); % Correlator, 4096 point FFT, 12 taps.


% Correlator FIR taps
filtertaps = correlatorFilterbankTaps;
for rom = 1:12
    fid = fopen(['correlatorFIRTaps' num2str(rom) '.coe'],'w');
    fprintf(fid,'memory_initialization_radix = 2;\n');
    fprintf(fid,'memory_initialization_vector = ');
    for rline = 1:4096
        dstr = dec2binX(filtertaps((rom-1)*4096 + (rline-1) + 1),18);
        fprintf(fid,['\n' dstr]);
    end
    fprintf(fid,';\n');
    fclose(fid);
end

% PSS FIR taps
% Coefficients are double buffered (because it doesn't cost anything to do it)
% so are just duplicated here.
filtertaps = PSSFilterbankTaps;
for rom = 1:12
    fid = fopen(['PSSFIRTaps' num2str(rom) '.coe'],'w');
    fprintf(fid,'memory_initialization_radix = 2;\n');
    fprintf(fid,'memory_initialization_vector = ');
    % First half of the memory.
    for rline = 1:64
        dstr = dec2binX(filtertaps((rom-1)*64 + (rline-1) + 1),18);
        fprintf(fid,['\n' dstr]);
    end
    % Another copy for the other half of the memory (double buffered).
    for rline = 1:64
        dstr = dec2binX(filtertaps((rom-1)*64 + (rline-1) + 1),18);
        fprintf(fid,['\n' dstr]);
    end    
    fprintf(fid,';\n');
    fclose(fid);
end

% PST FIR taps
filtertaps = PSTFilterbankTaps;
for rom = 1:12
    fid = fopen(['PSTFIRTaps' num2str(rom) '.coe'],'w');
    fprintf(fid,'memory_initialization_radix = 2;\n');
    fprintf(fid,'memory_initialization_vector = ');
    % First half of the memory.
    for rline = 1:256
        dstr = dec2binX(filtertaps((rom-1)*256 + (rline-1) + 1),18);
        fprintf(fid,['\n' dstr]);
    end
    % Another copy for the other half of the memory (double buffered).
    for rline = 1:256
        dstr = dec2binX(filtertaps((rom-1)*256 + (rline-1) + 1),18);
        fprintf(fid,['\n' dstr]);
    end    
    fprintf(fid,';\n');
    fclose(fid);
end


