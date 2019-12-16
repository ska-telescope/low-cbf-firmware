function [rxData] = get_captured_data_hex(src_fname,frameLength)
% Get data captured from the filterbank simulation, and convert to complex numbers and frames
% rxData(512,M), where M is the number of frames.

% Load the source data from a file
fid = fopen(src_fname);
[a,cnt] = fscanf(fid,'%x %x %x');
fclose(fid);

b = reshape(a,3,floor(cnt/3));

% Put data in frames
frameCount = 0;
totalFrames = 1;
for c1 = 1:floor(cnt/3)
    if (b(1,c1) == 0)
        frameCount = 0;
        totalFrames = totalFrames + 1;
    else
        frameCount = frameCount+1;
        if (frameCount > frameLength)
            warning(['frame is longer than frameLength (' num2strframeLength ')']);
        end
        realPart = b(2,c1);
        imagPart = b(3,c1);
        if (realPart > 32767)
            realPart = realPart - 65536;
        end
        if (imagPart > 32767)
            imagPart = imagPart - 65536;
        end
        rxData(frameCount,totalFrames) = realPart + 1i * imagPart;
    end
end


