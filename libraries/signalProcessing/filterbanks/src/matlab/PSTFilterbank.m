function [dout] = PSTFilterbank(din, doRounding)
% Filterbank, FFT 256 points, 12 taps.

FIRtaps = round(2^17 * generate_MaxFlt(256,12));

%% Pad with 11*256 + 64 = 2880 zeros to match the first output in the simulation.
totalSamples = length(din);
outputSamples = floor(totalSamples/192);
dinp = zeros(totalSamples+2880,1);
dinp(2881:end) = din;

%% initialise
dout = zeros(216,outputSamples);
fftIn = zeros(256,1);

%% 
for outputSample = 1:outputSamples
    % FIR filter, with scaling
    for n1 = 1:256
        fftIn(n1) = sum(FIRtaps(n1:256:end) .* dinp((outputSample-1)*192 + (n1:256:(n1+256*11))))/2^9;
        
     %   if (outputSample == 10)
     %       disp(FIRtaps(n1:256:end));
     %       disp(dinp((outputSample-1)*192 + (n1:256:(n1+256*11))));
     %       keyboard
     %   end
        
        if (doRounding)
            fftIn(n1) = round(fftIn(n1));
        end
    end

   % if (outputSample == 10)
   %     keyboard
   % end
    
    % FFT
    dout1 = fftshift(fft(fftIn))/2048;
    
    % Derotate the output (rotation occurs due to oversampling)
    % Rotation is by pi/2, advancing with each frequency bin and time sample.
    % note : DC is at 129; no rotation; Output sample 0 has no rotation.
    % rotation defined here is in units of pi/2
    rotation = mod(outputSample * (-128:127),4);
    dout2 = dout1 .* shiftdim(exp(1i*2*pi*rotation/4));
    
    %keyboard
    
   % if (outputSample == 16)
   %     keyboard
   % end    
    
    dout(:,outputSample) = dout2(21:(21 + 215));
end

