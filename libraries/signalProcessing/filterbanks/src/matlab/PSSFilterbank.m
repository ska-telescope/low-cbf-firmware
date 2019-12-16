function [dout] = PSSFilterbank(din, doRounding)
% Filterbank, FFT 4096 points, 12 taps.

FIRtaps = round(2^17 * generate_MaxFlt(64,12));

%% Pad with 11*64 = 704 zeros to match the first output in the simulation.
totalSamples = length(din);
outputSamples = floor(totalSamples/64);
dinp = zeros(totalSamples+704,1);
dinp(705:end) = din;

%% initialise
dout = zeros(54,outputSamples);
fftIn = zeros(64,1);

%% 
for outputSample = 1:outputSamples
    % FIR filter, with scaling
    for n1 = 1:64
        fftIn(n1) = sum(FIRtaps(n1:64:end) .* dinp((outputSample-1)*64 + (n1:64:(n1+64*11))))/2^9;
        
       % if (outputSample == 3)
       %     keyboard
       % end
        
        if (doRounding)
            fftIn(n1) = round(fftIn(n1));
        end
    end
    
    % FFT
    dout1 = fftshift(fft(fftIn))/1024;
    dout(:,outputSample) = dout1(6:(6 + 53));
end

