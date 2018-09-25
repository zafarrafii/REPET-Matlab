
%% PARAMETERS
fs = 44100;
fmin = 25;
B = 48;
gamma = 10; 
fmax = fs/2;

shiftBins = 48;

%% INPUT SIGNAL
% x = wavread('brent2.wav');
x = wavread('kempff1.wav');
x = x(:); xlen = length(x);

%% COMPUTE COEFFIENTS
Xcq = cqt(x, B, fs, fmin, fmax, 'rasterize', 'full', 'gamma', gamma, ...
    'phasemode', 'global', 'normalize' , 'sine', 'winfun', 'hann');
c = Xcq.c;

%% PITCH SHIFTING
if shiftBins ~= 0
    Y = phaseUpdate(c,Xcq.fbas,shiftBins,Xcq.xlen, fs, 1e-6);
    Y = circshift(Y,shiftBins);
    if shiftBins > 0
        Y(1:shiftBins) = 0;
    elseif shiftBins < 0
        Y(end-shiftBins+1:end) = 0;
    end
    Xcq.c = Y;
end

%% ICQT
[y gd] = icqt(Xcq);
