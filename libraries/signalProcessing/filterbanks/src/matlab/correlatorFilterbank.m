function [dout] = correlatorFilterbank(din, doRounding)
% Filterbank, FFT 4096 points, 12 taps.

FIRtaps = round(2^17 * generate_MaxFlt(4096,12));

%% Pad with 11*4096 zeros to match the first output in the simulation.
totalSamples = length(din);
outputSamples = floor(totalSamples/4096);
dinp = zeros(totalSamples+45056,1);
dinp(45057:end) = din;

%% initialise
dout = zeros(3456,outputSamples);
fftIn = zeros(4096,1);

%% 
for outputSample = 1:outputSamples
    % FIR filter, with scaling
    for n1 = 1:4096
        fftIn(n1) = sum(FIRtaps(n1:4096:end) .* dinp((outputSample-1)*4096 + (n1:4096:(n1+4096*11))))/2^9;
        
       % if (outputSample == 3)
       %     keyboard
       % end
        
        if (doRounding)
            fftIn(n1) = round(fftIn(n1));
        end
    end
    
    % FFT
    dout1 = fftshift(fft(fftIn))/8192;
    dout(:,outputSample) = dout1(321:(321 + 3455));
end


