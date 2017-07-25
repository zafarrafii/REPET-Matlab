%   REpeating Pattern Extraction Technique (REPET): adaptive REPET (thanks Antoine!)
%   
%   REPET is a simple method for separating the repeating background 
%   from the non-repeating foreground in an audio mixture. 
%   REPET can be extended by locally modeling the repetitions.
%   
%   Usage:
%       y = repet_ada(x,fs,per,par);
%
%   Input(s):
%       x: mixture data [t samples, k channels]
%       fs: sampling frequency in Hz
%       per: repeating period range (if two values) 
%            or defined repeating period (if one value) in seconds 
%            (default: [0.8,min(8,seg(1)/3)])
%       par: adaptive parameters (two values) (default: [24,12,7])
%            par(1): adaptive window length in seconds
%            par(2): adaptive step length in seconds
%            par(3): order for the median filter
%
%   Output(s):
%       y: repeating background [t samples, k channels]
%          (the corresponding non-repeating foreground is equal to x-y)
%
%	Example(s):
%       [x,fs,nbits] = wavread('mixture.wav');                              % Read some audio mixture
%       y = repet(x,fs,[0.8,8],[24,12,7]);                                  % Derives the repeating background using windows of 24 seconds, steps of 12 seconds, and order of 7
%       wavwrite(y,fs,nbits,'background.wav');                              % Write the repeating background
%       wavwrite(x-y,fs,nbits,'foreground.wav');                            % Write the corresponding non-repeating foreground
%
%   See also http://music.eecs.northwestern.edu/research.php?project=repet

%   Author: Zafar Rafii (zafarrafii@u.northwestern.edu)
%   Update: September 2013
%   Copyright: Zafar Rafii and Bryan Pardo, Northwestern University
%   Reference(s):
%       [1]: Antoine Liutkus, Zafar Rafii, Roland Badeau, Bryan Pardo, and Gaël Richard. 
%            "Adaptive Filtering for Music/Voice Separation Exploiting the Repeating Musical Structure," 
%            37th International Conference on Acoustics, Speech and Signal Processing,
%            Kyoto, Japan, March 25-30, 2012.

function y = repet_ada(x,fs,per,par)

if nargin < 4, par = [24,12,7]; end                                         % Default adaptive parameters
if nargin < 3, per = [0.8,min(8,par(1)/3)]; end                             % Default repeating period range

len = 0.040;                                                                % Analysis window length in seconds (audio stationary around 40 milliseconds)
N = 2.^nextpow2(len*fs);                                                    % Analysis window length in samples (power of 2 for faster FFT)
win = hamming(N,'periodic');                                                % Analysis window (even N and 'periodic' Hamming for constant overlap-add)
stp = N/2;                                                                  % Analysis step length (N/2 for constant overlap-add)

cof = 100;                                                                  % Cutoff frequency in Hz for the dual high-pass filtering (e.g., singing voice rarely below 100 Hz)
cof = ceil(cof*(N-1)/fs);                                                   % Cutoff frequency in frequency bins for the dual high-pass filtering (DC component = bin 0)

[t,k] = size(x);                                                            % Number of samples and channels
X = [];
for i = 1:k                                                                 % Loop over the channels
    Xi = stft(x(:,i),win,stp);                                              % Short-Time Fourier Transform (STFT) of channel i
    X = cat(3,X,Xi);                                                        % Concatenate the STFTs
end
V = abs(X(1:N/2+1,:,:));                                                    % Magnitude spectrogram (with DC component and without mirrored frequencies)

per = ceil((per*fs+N/stp-1)/stp);                                           % Repeating period in time frames (compensate for STFT zero-padding at the beginning)
par(1:2) = round(par(1:2)*fs/stp);                                          % Adaptive window length and step length in time frames
B = beat_spectrogram(mean(V.^2,3),par(1),par(2));                           % Beat spectrogram of the mean power spectrograms
P = repeating_periods(B,per);                                               % Repeating periods in time frames

y = zeros(t,k);
for i = 1:k                                                                 % Loop over the channels
    Mi = repeating_mask(V(:,:,i),P,par(3));                                 % Repeating mask
    Mi(1+(1:cof),:) = 1;                                                    % High-pass filtering of the (dual) non-repeating foreground
    Mi = cat(1,Mi,flipud(Mi(2:end-1,:)));                                   % Mirror the frequencies
    yi = istft(Mi.*X(:,:,i),win,stp);                                       % Estimated repeating background
    y(:,i) = yi(1:t);                                                       % Truncate to the original length of the mixture
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%   Short-Time Fourier Transform (STFT) using fft
%       X = stft(x,win,stp);
%
%   Input(s):
%       x: signal [t samples, 1]
%       win: analysis window [N samples, 1]
%       stp: analysis step
%
%   Output(s):
%       X: Short-Time Fourier Transform [N bins, m frames]

function X = stft(x,win,stp)

t = length(x);                                                              % Number of samples
N = length(win);                                                            % Analysis window length
m = ceil((N-stp+t)/stp);                                                    % Number of frames with zero-padding
x = [zeros(N-stp,1);x;zeros(m*stp-t,1)];                                    % Zero-padding for constant overlap-add
X = zeros(N,m);
for j = 1:m                                                                 % Loop over the frames
    X(:,j) = fft(x((1:N)+stp*(j-1)).*win);                                  % Windowing and fft
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%   Inverse Short-Time Fourier Transform using ifft
%       x = istft(X,win,stp);
%
%   Input(s):
%       X: Short-Time Fourier Transform [N bins, m frames]
%       win: analysis window [N samples, 1]
%       stp: analysis step
%
%   Output(s):
%       x: signal [t samples, 1]

function x = istft(X,win,stp)

[N,m] = size(X);                                                            % Number of frequency bins and time frames
l = (m-1)*stp+N;                                                            % Length with zero-padding
x = zeros(l,1);
for j = 1:m                                                                 % Loop over the frames
    x((1:N)+stp*(j-1)) = x((1:N)+stp*(j-1))+real(ifft(X(:,j)));             % Un-windowing and ifft (assuming constant overlap-add)
end
x(l-(N-stp)+1:l) = [];                                                      % Remove zero-padding at the beginning
x(1:N-stp) = [];                                                            % Remove zero-padding at the end
x = x/sum(win(1:stp:N));                                                    % Normalize constant overlap-add using win

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%   Autocorrelation function using fft according to the Wiener–Khinchin theorem
%       C = acorr(X);
%
%   Input(s):
%       X: data matrix [n elements, m vectors]
%
%   Output(s):
%       C: autocorrelation matrix [n lags, m vectors]

function C = acorr(X)

[n,m] = size(X);
X = [X;zeros(n,m)];                                                         % Zero-padding to twice the length for a proper autocorrelation
X = abs(fft(X)).^2;                                                         % Power Spectral Density: PSD(X) = fft(X).*conj(fft(X))
C = ifft(X);                                                                % Wiener–Khinchin theorem: PSD(X) = fft(acorr(X))
C = C(1:n,:);                                                               % Discard the symmetric part (lags n-1 to 1)
C = C./repmat((n:-1:1)',[1,m]);                                             % Unbiased autocorrelation (lags 0 to n-1)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%   Beat spectrum using the autocorrelation function
%       b = beat_spectrum(X);
%
%   Input(s):
%       X: spectrogram [n frequency bins, m time frames]
%
%   Output(s):
%       b: beat spectrum [1, m time lags]

function b = beat_spectrum(X)

B = acorr(X');                                                              % Correlogram using acorr [m lags, n bins]
b = mean(B,2);                                                              % Mean along the frequency bins

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Beat spectrogram using the beat_spectrum
%       B = beat_spectrogram(X,w,h);
%
%   Input(s):
%       X: spectrogram [n bins, m frames]
%       w: time window length
%       h: hop size
%
%   Output(s):
%       B: beat spectrogram [w lags, m frames] (lags from 0 to w-1)

function B = beat_spectrogram(X,w,h)

[n,m] = size(X);                                                            % Number of frequency bins and time frames
X = [zeros(n,ceil((w-1)/2)),X,zeros(n,floor((w-1)/2))];                     % Zero-padding to center windows
B = zeros(w,m);
b = waitbar(0,'Adaptive REPET 1/2');                                        % Wait bar
for j = [1:h:m-1,m]                                                         % Loop over the time frames (including the last one)
    B(:,j) = beat_spectrum(X(:,(1:w)+j-1))';                                % Beat spectrum of the windowed spectrogram centered on frame j
    waitbar(j/m,b);
end
close(b)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%   Repeating periods from the beat spectrogram
%       P = repeating_periods(B,r);
%
%   Input(s):
%       B: beat_spectrogram [l lags, m frames]
%       r: repeating period range in time frames [min lag, max lag]
%
%   Output(s):
%       P: repeating periods in time frames [1, m frames]

function P = repeating_periods(B,r)

B(1,:) = [];                                                                % Discard lags 0
B = B(r(1):r(2),:);                                                         % Beat spectrogram in the repeating period range
[~,P] = max(B,[],1);                                                        % Maximum values in the repeating period range for all the frames
P = P+r(1);                                                                 % The repeating periods are estimated as the indices of the maximum values

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Repeating mask from the magnitude spectrogram and the repeating periods
%       M = repeating_mask(V,p,k);
%
%   Input(s):
%       V: magnitude spectrogram [n bins, m frames]
%       p: repeating periods in time frames [1, m frames]
%       k: order for the median filter
%
%   Output(s):
%       M: repeating (soft) mask in [0,1] [n bins, m frames]

function M = repeating_mask(V,p,k)

[n,m] = size(V);                                                            % Number of frequency bins and time frames
k = (1:k)-ceil(k/2);                                                        % Order vector centered in 0
W = zeros(n,m);
b = waitbar(0,'Adaptive REPET 2/2');                                        % Wait bar
for j = 1:m                                                                 % Loop over the frames
    i = j+k*p(j);                                                           % Indices of the frames for the median filtering  (e.g.: k=3 => i=[-1,0,1], k=4 => i=[-1,0,1,2])
    i(i<1 | i>m) = [];                                                      % Discard out-of-range indices
    W(:,j) = median(V(:,i),2);                                              % Median filter centered on frame j
    waitbar(j/m,b);
end
close(b)
W = min(V,W);                                                               % For every time-frequency bins, we must have W <= V
M = (W+eps)./(V+eps);                                                       % Normalize W by V
