function W = generate_MaxFlt(nbuff, nTap)
% Generate maximal flat filter coefficients

%{
% Author: J Bunton, 22 August 2015
Filter Response to meet correlator requirements
For a monochromatic signal, total power (all channels) remains constant
independent of frequency
Starting point are the maximally flat filters
this is improved with some simple optimisation

Calculation should be done only once per Simulink simulation  

nbuff = typically 4096
nTaps = # of taps, typically 8 or 12 

%} 

%{ 
SVN keywords
 $Rev:: 47                                                                                         $: Revision of last commit
 $Author:: bradford                                                                                $: Author of last commit
 $Date:: 2016-04-19 16:30:25 +1000 (Tue, 19 Apr 2016)                                              $: Date of last commit
 $LastChangedDate:: 2016-04-19 16:30:25 +1000 (Tue, 19 Apr 2016)                                   $: Date of last change
 $HeadURL: svn://codehostingbt.aut.ac.nz/svn/LOWCBF/Modelling/CSP_DSP/CSP_Dataflow/generate_MaxFl#$: Repo location
%}


%% Filter design coefficients 
% disp('generate_MaxFlt')

nTap2 = 2*nTap;  % say around 8 or 12 
nTap2p1 = nTap2+1; 

imp=maxflat(nTap2,'sym',.5*nTap2/nTap2p1);
imp=interpft(imp,nTap2)*nTap2p1/nTap2; %Take to 2*ntap (24) tap filter (2 channel, 12tap FIR)

% plot(db(fft(imp)),'o-')

% Interate to improve (hard coded 10 times) 
for k=1:10

    impf=fft(imp);
    imph=imp.*cos( ((1:length(imp))-1)*pi);
    impfh=fft(imph);
    errorf =(impf.*conj(impf)+impfh.*conj(impfh));
    errorf=errorf/errorf(1);
    errorf=1-errorf;
    error=fftshift((ifft(errorf)));
    imp=imp+error/2.0; %(2.5*( abs(impf)+abs(impfh) ));

end

cor=imp;
corh=cor.*cos( ((1:length(imp))-1)*pi);

corf=freqz(cor,2048)*2048;
corfh=freqz(corh,2000)*2000;
ampf=corf.*conj(corf)+corfh.*conj(corfh);
error = fftshift((ifft(1-ampf)));


%{
Variable nbuff*nTap is the length of the filter. 
Typically: 4096 freq channels * 8 taps) 

12x32 is a 12 tap FIR section, 32 channel filterbank
%} 
%
W=interpft(cor,nbuff*nTap);  %change this line to alter length of filter.
W = W(:); % force column 

return 