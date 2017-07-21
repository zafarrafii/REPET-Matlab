%   REpeating Pattern Extraction Technique (REPET): original REPET with segmentation
%   
%   REPET is a simple method for separating the repeating background 
%   from the non-repeating foreground in an audio mixture. 
%   REPET can be extended by locally modeling the repetitions.
%
%   Usage:
%       y = repet_seg(x,fs,per,par);
%
%   Input(s):
%       x: audio mixture [t samples, k channels]
%       fs: sampling frequency in Hz
%       per: repeating period range (if two values) 
%            or defined repeating period (if one value) in seconds 
%            (default: [0.8,min(8,seg(1)/3)])
%       par: segmentation parameters (two values) (default: [24,12])
%            par(1): segmentation window length in seconds
%            par(2): segmentation step length in seconds
%
%   Output(s):
%       y: repeating background [t samples, k channels]
%          (the corresponding non-repeating foreground is equal to x-y)
%
%	Example(s):
%       [x,fs,nbits] = wavread('mixture.wav');                              % Read some audio mixture
%       y = repet(x,fs,[0.8,8],[24,12]);                                    % Derives the repeating background using windows of 24 seconds and steps of 12 seconds
%       wavwrite(y,fs,nbits,'background.wav');                              % Write the repeating background
%       wavwrite(x-y,fs,nbits,'foreground.wav');                            % Write the corresponding non-repeating foreground
%
%   See also http://music.eecs.northwestern.edu/research.php?project=repet

%   Author: Zafar Rafii (zafarrafii@u.northwestern.edu)
%   Update: September 2013
%   Copyright: Zafar Rafii and Bryan Pardo, Northwestern University
%   Reference(s):
%       [1] Zafar Rafii and Bryan Pardo. "Acoustic Separation System and Method," 
%           Re: US Provisional Patent Application Serial No. 61/534,280
%       [2] Zafar Rafii and Bryan Pardo. 
%           "REpeating Pattern Extraction Technique (REPET): A Simple Method for Music/Voice Separation," 
%           IEEE Transactions on Audio, Speech, and Language Processing, 
%           Volume 21, Issue 1, pp. 71-82, January, 2013.
%       [3] Zafar Rafii and Bryan Pardo. 
%           "A Simple Music/Voice Separation Method based on the Extraction of the Repeating Musical Structure," 
%           36th International Conference on Acoustics, Speech and Signal Processing,
%           Prague, Czech Republic, May 22-27, 2011.

function y = repet_seg(x,fs,per,par)

if nargin < 4, par = [24,12]; end                                           % Default segmentation parameters
if nargin < 3, per = [0.8,min(8,par(1)/3)]; end                             % Default repeating period range

len = 0.040;                                                                % Analysis window length in seconds (audio stationary around 40 milliseconds)
N = 2.^nextpow2(len*fs);                                                    % Analysis window length in samples (power of 2 for faster FFT)
win = hamming(N,'periodic');                                                % Analysis window (even N and 'periodic' Hamming for constant overlap-add)
stp = N/2;                                                                  % Analysis step length (N/2 for constant overlap-add)

cof = 100;                                                                  % Cutoff frequency in Hz for the dual high-pass filtering (e.g., singing voice rarely below 100 Hz)
cof = ceil(cof*(N-1)/fs);                                                   % Cutoff frequency in frequency bins for the dual high-pass filtering (DC component = bin 0)

per = ceil((per*fs+N/stp-1)/stp);                                           % Repeating period in time frames (compensate for STFT zero-padding at the beginning)

w = round(par(1)*fs);                                                       % Segmentation window length in samples
s = round(par(2)*fs);                                                       % Segmentation step length in samples
o = w-s;                                                                    % Segmentation overlap length in samples

[t,k] = size(x);                                                            % Number of samples and channels
if t < w+s
    m = 1;                                                                  % Just one segment if the signal is too short
else
    m = 1+floor((t-w)/s);                                                   % Number of segments (the last one could be longer)
    v = triang(2*o);                                                        % Triangular window for the overlapping parts
end

y = zeros(t,k);
h = waitbar(0,'REPET-WIN');
for j = 1:m                                                                 % Loop over the segments
    if m == 1                                                               % Case one segment
        xj = x;
        w = l;                                                              % Update window length
    elseif m > 1
        if j < m                                                            % Case first segments
            xj = x((1:w)+(j-1)*s,:);
        elseif j == m                                                       % Case last segment (could be longer)
            xj = x((j-1)*s+1:t,:);
            w = length(xj);                                                 % Update window length
        end
    end
    
    Xj = [];
    for i = 1:k                                                             % Loop over the channels
        Xji = stft(xj(:,i),win,stp);                                        % Short-Time Fourier Transform (STFT) of channel i
        Xj = cat(3,Xj,Xji);                                                 % Concatenate the STFTs
    end
    Vj = abs(Xj(1:N/2+1,:,:));                                              % Magnitude spectrogram (with DC component and without mirrored frequencies)
    
    if numel(per) == 1                                                      % If single value
        pj = per;                                                           % Defined repeating period in time frames
    else
        bj = beat_spectrum(mean(Vj.^2,3));                                  % Beat spectrum of the mean power spectrograms (square to emphasize peaks of periodicitiy)
        pj = repeating_period(bj,per);                                      % Estimated repeating period in time frames
    end
    
    yj = zeros(w,k);
    for i = 1:k                                                             % Loop over the channels
        Mji = repeating_mask(Vj(:,:,i),pj);                                 % Repeating mask for channel i
        Mji(1+(1:cof),:) = 1;                                               % High-pass filtering of the (dual) non-repeating foreground
        Mji = cat(1,Mji,flipud(Mji(2:end-1,:)));                            % Mirror the frequencies
        yji = istft(Mji.*Xj(:,:,i),win,stp);                                % Estimated repeating background
        yj(:,i) = yji(1:w);                                                 % Truncate to the original mixture length
    end
    
    if m == 1                                                               % Case one segment
        y = yj;
    elseif m > 1
        if j == 1                                                           % Case first segment
            y(1:w,:) = y(1:w,:) + yj;
        elseif j <= m                                                       % Case last segments
            y((1:o)+(j-1)*s,:) ...                                          % Half windowing of the overlap part of y on the right
                = y((1:o)+(j-1)*s,:).*repmat(v((1:o)+o),[1,k]);
            yj(1:o,:) ...                                                   % Half windowing of the overlap part of yj on the left
                = yj(1:o,:).*repmat(v(1:o),[1,k]);
            y((1:w)+(j-1)*s,:) = y((1:w)+(j-1)*s,:) + yj;
        end
    end
    waitbar(j/m,h);
end
close(h)

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

%   Repeating period from the beat spectrum
%       p = repeating_period(b,r);
%
%   Input(s):
%       b: beat spectrum [1, m time lags]
%       r: repeating period range in time frames [min lag, max lag]
%
%   Output(s):
%       p: repeating period in time frames

function p = repeating_period(b,r)

b(1) = [];                                                                  % Discard lag 0
b = b(r(1):r(2));                                                           % Beat spectrum in the repeating period range
[~,p] = max(b);                                                             % Maximum value in the repeating period range
p = p+r(1);                                                                 % The repeating period is estimated as the index of the maximum value

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%   Repeating mask from the magnitude spectrogram and the repeating period
%       M = repeating_mask(V,p);
%
%   Input(s):
%       V: magnitude spectrogram [n bins, m frames]
%       p: repeating period in time frames
%
%   Output(s):
%       M: repeating mask in [0,1] [n bins, m frames]

function M = repeating_mask(V,p)

[n,m] = size(V);                                                            % Number of frequency bins and time frames
r = ceil(m/p);                                                              % Number of repeating segments (including the last one)
W = [V,nan(n,r*p-m)];                                                       % Padding to have an integer number of segments
W = reshape(W,[n*p,r]);                                                     % Reshape so that the columns are the segments
W = [median(W(1:n*(m-(r-1)*p),1:r),2); ...                                  % Median of the parts repeating for all the r segments (including the last one)
    median(W(n*(m-(r-1)*p)+1:n*p,1:r-1),2)];                                % Median of the parts repeating only for the first r-1 segments (empty if m = r*p)
W = reshape(repmat(W,[1,r]),[n,r*p]);                                       % Duplicate repeating segment model and reshape back to have [n,r*p]
W = W(:,1:m);                                                               % Truncate to the original number of frames to have [n,m]
W = min(V,W);                                                               % For every time-frequency bins, we must have W <= V
M = (W+eps)./(V+eps);                                                       % Normalize W by V
