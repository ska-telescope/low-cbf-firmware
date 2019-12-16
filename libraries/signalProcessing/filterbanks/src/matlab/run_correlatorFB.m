% Test the correlator filterbank.
% Script to generate test data and compare the simulation output with the matlab model.
% Note - set generateSimData to true the first time the function is called.
clear all;
generateSimData = false;
useAllNoise = true;
checkSimData = true;
doMatlabRounding = 0;
framesToDrop = 11;    % Number of output frames the firmware drops after reset.

if (generateSimData)
    totalSamples = 160*4096; % 84x4096 samples.
    packets = totalSamples/4096;
    % The firmware takes four channels, generate 4 different inputs
    testData = zeros(4,totalSamples);
    if (useAllNoise)
        testData(1,:) = 64 * (rand(1,totalSamples) - 0.5) + 1i * 64 * (rand(1,totalSamples) - 0.5);
        testData(2,:) = 64 * (rand(1,totalSamples) - 0.5) + 1i * 64 * (rand(1,totalSamples) - 0.5);
        testData(3,:) = 64 * (rand(1,totalSamples) - 0.5) + 1i * 64 * (rand(1,totalSamples) - 0.5);
        testData(4,:) = 64 * (rand(1,totalSamples) - 0.5) + 1i * 64 * (rand(1,totalSamples) - 0.5);
    else
        % channel 1 - 8 bit counter
        dtest1r = mod((0:(totalSamples - 1)),256);
        dtest1i = mod((16:(totalSamples + 16 - 1)),256);
        for k = 1:length(dtest1r)
            if (dtest1r(k) > 127) 
                dtest1r(k) = dtest1r(k) - 256;
            end
        end
        for k = 1:length(dtest1i)
            if (dtest1i(k) > 127) 
                dtest1i(k) = dtest1i(k) - 256;
            end
        end
        testData(1,:) = dtest1r + 1i * dtest1i;

        % channel 2 - single tone
        % filterbank takes samples with period 1080ns (925.925 kHz), frequency bins are 925925/4096 = 226 Hz
        f1 = 226 * 80;
        testData(2,:) = 126 * exp(1i*(0:(totalSamples - 1)) * 1080e-9 * 2 * pi * f1);

        % channel 3 - uniformly distributed noise, +/-64
        testData(3,:) = 64 * (rand(1,totalSamples) - 0.5) + 1i * 64 * (rand(1,totalSamples) - 0.5);

        % Channel 4 - set of tones, including the edges of the band
        f2 = 226.0559082 * [-1728:691:1727];
        testData(4,:) = zeros(1,totalSamples);
        for fc = 1:6
            testData(4,:) = testData(4,:) + exp(1i * (2*pi*rand(1) + (0:(totalSamples-1)) * 1080e-9 * 2 * pi * f2(fc)));
        end
        tmax = max(abs(testData(4,:)));
        testData(4,:) = 100 * testData(4,:)/tmax;
    
    end
    % Convert to Integers
    testData = round(testData);
    
    % Write to text files for input to the simulation.
    for ch = 1:4
        fid = fopen(['correlatorFBDin' num2str(ch-1) '.txt'],'w');
        dstr = '000000';
        fprintf(fid,['0 0000\n']);  % idle
        fprintf(fid,['0 0000\n']);  % idle
        for packet = 1:packets
            for rline = 1:4096
                d1 = real(testData(ch,(packet-1)*4096 + rline));
                d2 = imag(testData(ch,(packet-1)*4096 + rline));
                if (d1 < 0)
                    d1 = d1 + 256;
                end
                if (d2 < 0)
                    d2 = d2 + 256;
                end
                dstr(3:4) = dec2hex(d1,2);
                dstr(1:2) = dec2hex(d2,2);
                fprintf(fid,['1 ' dstr '\n']);  % valid and data.
            end
            fprintf(fid,'0 0000\n');  % three idles between packets.
            fprintf(fid,'0 0000\n');  % idle
            fprintf(fid,'0 0000\n');  % idle
        end
        fclose(fid);
    end
    save correlatorTestData testData
else
    load correlatorTestData;
end


% Plot the input data
figure(1);
clf;
subplot(4,1,1);
hold on;
grid on;
plot(real(testData(1,:)),'r.-');
plot(imag(testData(1,:)),'g.-');
title('Input Data');
subplot(4,1,2);
hold on;
grid on;
plot(real(testData(2,:)),'r.-');
plot(imag(testData(2,:)),'g.-');
subplot(4,1,3);
hold on;
grid on;
plot(real(testData(3,:)),'r.-');
plot(imag(testData(3,:)),'g.-');
subplot(4,1,4);
hold on;
grid on;
plot(real(testData(4,:)),'r.-');
plot(imag(testData(4,:)),'g.-');

% Run matlab version
packets = length(testData)/4096;
ml = zeros([4,3456,(length(testData)/4096)]);
for ch = 1:4
    ml(ch,:,:) = correlatorFilterbank(testData(ch,:),doMatlabRounding);
end

% Get the output of the simulation.
if (checkSimData)
    rx_data{1} = get_captured_data_hex('correlatorFBDout0_log.txt',3456);
    rx_data{2} = get_captured_data_hex('correlatorFBDout1_log.txt',3456);
    rx_data{3} = get_captured_data_hex('correlatorFBDout2_log.txt',3456);
    rx_data{4} = get_captured_data_hex('correlatorFBDout3_log.txt',3456);
    s1 = size(rx_data{1});
    packetsCaptured = s1(2);
else
    rx_data{1} = 0;
    rx_data{2} = 0;
    rx_data{3} = 0;
    rx_data{4} = 0;
    packetsCaptured = 0;
end

% for ch = 1:4
%     rx_data{ch} = rx_data{ch};
% end
    
% Compare Matlab and Simulation
if (checkSimData)
    for p = 1:(packetsCaptured-1)
        for ch = 1:4
            d{ch}(((p-1)*3456+1):((p-1)*3456 + 3456)) = shiftdim(ml(ch,:,(p + framesToDrop))) - rx_data{ch}(:,p);
        end
    end

    disp(['Results for ' num2str(packetsCaptured-1) ' packets']);
    
    for dtype = 1:4
        [maxr(dtype),indexr(dtype)] = max(abs(real(d{dtype})));
        meanr(dtype) = mean(real(d{dtype}));
        stdr(dtype) = std(real(d{dtype}));
        [maxi(dtype),indexi(dtype)] = max(abs(imag(d{dtype})));
        meani(dtype) = mean(imag(d{dtype}));
        stdi(dtype) = std(imag(d{dtype}));

        disp(['Channel ' num2str(dtype) ', Real part errors (max, mean, std)      = (' num2str(maxr(dtype)) ', ' num2str(meanr(dtype)) ', ' num2str(stdr(dtype)) ')']);
        disp(['Channel ' num2str(dtype) ', Imaginary part errors (max, mean, std) = (' num2str(maxi(dtype)) ', ' num2str(meani(dtype)) ', ' num2str(stdi(dtype)) ')']);
    end
    disp(['Mean error across all channels = ' num2str((sum(meanr) + sum(meani)) / (length(meanr) + length(meani)))]);
end

% Plot matlab, simulation and errors
for p = 1:(packetsCaptured)
    
    for ch = 1:4
        figure(ch+1);
        clf;
        subplot(2,1,1)
        title(['channel ' num2str(ch) ', red matlab, green simulation, black difference'])
        hold on;
        grid on;
        %plot(real(ml(ch,:,(p+framesToDrop))),'r.-');
        if (checkSimData)
           % plot(real(rx_data{ch}(:,p)),'go-');
           % plot(shiftdim(real(ml(ch,:,(p+framesToDrop)))) - real(rx_data{ch}(:,p)),'k*');
            curD = shiftdim(real(ml(ch,:,(p+framesToDrop)))) - real(rx_data{ch}(:,p));
            curDLP = filter(gausswin(40)/sum(gausswin(40)),[1],curD);
            plot(curDLP,'k-');
        end
        subplot(2,1,2)
        hold on;
        grid on;
        %plot(imag(ml(ch,:,(p+framesToDrop))),'r.-');
        if (checkSimData)
           % plot(imag(rx_data{ch}(:,p)),'go-');
           % plot(shiftdim(imag(ml(ch,:,(p+framesToDrop)))) - imag(rx_data{ch}(:,p)),'k*');
            curD = shiftdim(imag(ml(ch,:,(p+framesToDrop)))) - imag(rx_data{ch}(:,p));
            curDLP = filter(gausswin(40)/sum(gausswin(40)),[1],curD);
            plot(curDLP,'k-');
        end
    end
    
    disp(['Frame ' num2str(p)]);
    pause;
end
