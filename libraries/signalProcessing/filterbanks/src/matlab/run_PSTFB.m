% Test the PST filterbank.
% Script to generate test data and compare the simulation output with the matlab model.
% Note - set generateSimData to true the first time the function is called.
clear all;
generateSimData = false;
checkSimData = true;
doMatlabRounding = 0;
framesToDrop = 15;    % Number of output frames the firmware drops after reset.

if (generateSimData)
    totalSamples = 6144; % 32*192 = 256 * 24 samples.
    packets = totalSamples/64;  % PST packets are still 64 samples.
    % The firmware takes 6 channels, generate 6 different inputs
    testData = zeros(6,totalSamples);
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
    % filterbank takes samples with period 1080ns (925.925 kHz), frequency bins are 925925/256 = 3617 Hz
    f1 = (1/1080e-9/256) * 8;
    testData(2,:) = 126 * exp(1i*(0:(totalSamples - 1)) * 1080e-9 * 2 * pi * f1);
    
    % channel 3 - uniformly distributed noise, +/-64
    testData(3,:) = 64 * (rand(1,totalSamples) - 0.5) + 1i * 64 * (rand(1,totalSamples) - 0.5);
    
    % Channel 4 - set of tones, including the edges of the band
    f2 = (1/1080e-9 / 256) * [-108 -15 0 1 2 3 4 5 6 7 8 9 10 11 18 107];
    phi = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];
    testData(4,:) = zeros(1,totalSamples);
    for fc = 1:16
        testData(4,:) = testData(4,:) + exp(1i * (2*pi*phi(fc) + (0:(totalSamples-1)) * 1080e-9 * 2 * pi * f2(fc)));
    end
    tmax = max(abs(testData(4,:)));
    testData(4,:) = 100 * testData(4,:)/tmax;
    
    % Channel 5 - uniformly distributed noise, +/-127
    testData(5,:) = 127 * 2 * (rand(1,totalSamples) - 0.5) + 1i * 127 * 2 * (rand(1,totalSamples) - 0.5);
    
    % Channel 6 - uniformly distributed noise, +/-16
    testData(6,:) = 16 * (rand(1,totalSamples) - 0.5) + 1i * 16 * (rand(1,totalSamples) - 0.5);
    
    % Convert to Integers
    testData = round(testData);
    
    % Write to text files for input to the simulation.
    for ch = 1:6
        fid = fopen(['PSTFBDin' num2str(ch-1) '.txt'],'w');
        dstr = '000000';
        fprintf(fid,['0 0000\n']);  % idle
        fprintf(fid,['0 0000\n']);  % idle
        for packet = 1:packets
            for rline = 1:64
                d1 = real(testData(ch,(packet-1)*64 + rline));
                d2 = imag(testData(ch,(packet-1)*64 + rline));
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
            % 22 idles between packets, total length of packets is 86 clocks
            for idlecount = 1:22
                fprintf(fid,'0 0000\n');  % three idles between packets.
            end
        end
        fclose(fid);
    end
    save PSTTestData testData
else
    load PSTTestData;
end


% Plot the input data
figure(1);
clf;
for pc = 1:6
    subplot(6,1,pc);
    hold on;
    grid on;
    plot(real(testData(pc,:)),'r.-');
    plot(imag(testData(pc,:)),'g.-');
    if (pc == 1)
        title('PST filterbank test input Data');
    end
end

% Run Matlab version
packets = length(testData)/192;
ml = zeros([6,216,(length(testData)/192)]);
for ch = 1:6
    ml(ch,:,:) = PSTFilterbank(testData(ch,:),doMatlabRounding);
end

% Get the output of the simulation.
if (checkSimData)
    rx_data{1} = get_captured_data_hex('PSTFBDout0_log.txt',216);
    rx_data{2} = get_captured_data_hex('PSTFBDout1_log.txt',216);
    rx_data{3} = get_captured_data_hex('PSTFBDout2_log.txt',216);
    rx_data{4} = get_captured_data_hex('PSTFBDout3_log.txt',216);
    rx_data{5} = get_captured_data_hex('PSTFBDout4_log.txt',216);
    rx_data{6} = get_captured_data_hex('PSTFBDout5_log.txt',216);
    s1 = size(rx_data{1});
    packetsCaptured = s1(2);
else
    rx_data{1} = 0;
    rx_data{2} = 0;
    rx_data{3} = 0;
    rx_data{4} = 0;
    rx_data{5} = 0;
    rx_data{6} = 0;    
    packetsCaptured = 0;
end

% for ch = 1:4
%     rx_data{ch} = rx_data{ch};
% end
    
% Compare Matlab and Simulation
if (checkSimData)
    for p = (framesToDrop+1):(framesToDrop + packetsCaptured)
        for ch = 1:6
            d{ch}((((p-framesToDrop)-1)*216+1):(((p-framesToDrop)-1)*216 + 216)) = shiftdim(ml(ch,:,p)) - rx_data{ch}(:,p-framesToDrop);
        end
    end

    for dtype = 1:6
        [maxr(dtype),indexr(dtype)] = max(abs(real(d{dtype})));
        meanr(dtype) = mean(real(d{dtype}));
        stdr(dtype) = std(real(d{dtype}));
        [maxi(dtype),indexi(dtype)] = max(abs(imag(d{dtype})));
        meani(dtype) = mean(imag(d{dtype}));
        stdi(dtype) = std(imag(d{dtype}));

        disp(['Channel ' num2str(dtype) ', Real part errors (max, mean, std)      = (' num2str(maxr(dtype)) ', ' num2str(meanr(dtype)) ', ' num2str(stdr(dtype)) ')']);
        disp(['Channel ' num2str(dtype) ', Imaginary part errors (max, mean, std) = (' num2str(maxi(dtype)) ', ' num2str(meani(dtype)) ', ' num2str(stdi(dtype)) ')']);
    end
end

% Plot matlab, simulation and errors
for p = (framesToDrop + 1):packets
    
    for ch = 1:6
        figure(ch+1);
        clf;
        subplot(2,1,1)
        title(['channel ' num2str(ch) ', red matlab, green simulation, black difference'])
        hold on;
        grid on;
        plot(real(ml(ch,:,p)),'r.-');
        if (checkSimData)
            plot(real(rx_data{ch}(:,p-framesToDrop)),'go-');
            plot(shiftdim(real(ml(ch,:,p))) - real(rx_data{ch}(:,p-framesToDrop)),'k*');
            curD = shiftdim(real(ml(ch,:,(p)))) - real(rx_data{ch}(:,p-framesToDrop));
            curDLP = filter(gausswin(40)/sum(gausswin(40)),[1],curD);
            plot(curDLP,'k-');
            
        end
        subplot(2,1,2)
        hold on;
        grid on;
        plot(imag(ml(ch,:,p)),'r.-');
        if (checkSimData)
            plot(imag(rx_data{ch}(:,p-framesToDrop)),'go-');
            plot(shiftdim(imag(ml(ch,:,p))) - imag(rx_data{ch}(:,p-framesToDrop)),'k*');
            curD = shiftdim(imag(ml(ch,:,(p)))) - imag(rx_data{ch}(:,p-framesToDrop));
            curDLP = filter(gausswin(40)/sum(gausswin(40)),[1],curD);
            plot(curDLP,'k-');            
        end
    end
    
    disp(['Frame ' num2str(p)]);
    pause;
end
