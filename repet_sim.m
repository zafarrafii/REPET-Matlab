%   REpeating Pattern Extraction Technique (REPET): REPET-SIM
%   
%   REPET is a simple method for separating the repeating background (e.g., the accompaniment)
%   from the non-repeating foreground (e.g., the melody) in an audio mixture. 
%   REPET can be generalized to look for similarities instead of periodicities.
%
%   Usage:
%       y = repet_sim(x,fs,par);
%
%   Input(s):
%       x: audio mixture [t samples, k channels]
%       fs: sampling frequency in Hz
%       par: similarity parameters (3 values) (default: [0,1,100])
%            par(1): minimal threshold for the similarity with the repeating frames in [0,1]
%            par(2): minimal distance between repeating frames in seconds
%            par(3): maximal number of repeating frames for the median filter
%
%   Output(s):
%       y: repeating background [t samples, k channels]
%          (the corresponding non-repeating foreground is equal to x-y)
%
%	Example(s):
%       [x,fs,nbits] = wavread('mixture.wav');                              % Read some audio mixture
%       y = repet_sim(x,fs,[0,1,100]);                                      % Derives the repeating background with threshold of 0, distance of 1 second, and number of 100 frames
%       wavwrite(y,fs,nbits,'background.wav');                              % Write the repeating background
%       wavwrite(x-y,fs,nbits,'foreground.wav');                            % Write the corresponding non-repeating foreground
%
%   See also http://music.eecs.northwestern.edu/research.php?project=repet

%   Author: Zafar Rafii (zafarrafii@u.northwestern.edu)
%   Update: September 2013
%   Copyright: Zafar Rafii and Bryan Pardo, Northwestern University
%   Reference(s):
%       [1] Zafar Rafii and Bryan Pardo. "Audio Separation System and Method," 
%           US20130064379 A1, US 13/612,413, March 14, 2013.
%       [2] Zafar Rafii and Bryan Pardo. 
%           "Music/Voice Separation using the Similarity Matrix," 
%           13th International Society on Music Information Retrieval, 
%           Porto, Portugal, October 8-12, 2012.

function y = repet_sim(x,fs,par)

if nargin < 3, par = [0,1,100]; end                                         % Default similarity parameters

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
V = abs(X(1:end/2+1,:,:));                                                  % Magnitude spectrogram (with DC component and without mirrored frequencies)

S = similarity_matrix(mean(V,3));                                           % Similarity matrix of the mean magnitude spectrograms
par(2) = round(par(2)*fs/stp);                                              % Distance in time frames
S = similarity_indices(S,par);                                              % Similarity indices for all the frames

y = zeros(t,k);
for i = 1:k                                                                 % Loop over the channels
    Mi = repeating_mask(V(:,:,i),S);                                        % Repeating mask for channel i
    Mi(1+(1:cof),:) = 1;                                                    % High-pass filtering of the (dual) non-repeating foreground
    Mi = cat(1,Mi,flipud(Mi(2:end-1,:)));                                   % Mirror the frequencies
    yi = istft(Mi.*X(:,:,i),win,stp);                                       % Estimated repeating background
    y(:,i) = yi(1:t);                                                       % Truncate to the original mixture length
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

%   Similarity matrix using the cosine similarity
%       S = similarity_matrix(X);
%
%   Input(s):
%       X: spectrogram [n frequency bins, m time frames]
%
%   Output(s):
%       S: similarity matrix [m time lags, m time lags]

function S = similarity_matrix(X)

for j = 1:size(X,2)                                                         % Loop over the frames
    X(:,j) = X(:,j)/(norm(X(:,j),2)+eps);                                   % Euclidean normalization of the frames
end
S = X'*X;                                                                   % Cosine similarity matrix

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%   Similarity indices for all the frames using the similarity matrix
%       I = similarity_indices(S,sim);
%
%   Input(s):
%       S: similarity matrix [m time lags, m time lags]
%       sim: similarity parameters (3 values)
%            sim(1): minimal threshold for the similarity with the repeating frames in [0,1]
%            sim(2): minimal distance between repeating frames in time frames
%            sim(3): maximal number of repeating frames for the median filter
%
%   Output(s):
%       I: similarity indices for all the frames

function I = similarity_indices(S,sim)

m = size(S,1);                                                              % Number of frames
I = cell(1,m);
w = waitbar(0,'REPET-SIM 1/2');                                             % Wait bar
for j = 1:m                                                                 % Loop over the frames
    [~,i] = findpeaks(S(:,j), ...                                           % Find local maxima
        'minpeakheight',sim(1), ...                                         % Minimum peak height
        'minpeakdistance',sim(2), ...                                       % Minimum peak distance
        'npeaks',sim(3), ...                                                % Number of peaks
        'sortstr','descend');                                               % Peak sorting
    I{j} = i;                                                               % Similarity indices for frame j
    waitbar(j/m,w);
end
close(w)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%   Repeating mask from the magnitude spectrogram and the similarity indices
%       M = repeating_mask(V,I);
%
%   Input(s):
%       V: magnitude spectrogram [n frequency bins, m time frames]
%       I: similarity indices for all the frames
%
%   Output(s):
%       M: repeating mask in [0,1] [n frequency bins, m time frames]

function M = repeating_mask(V,I)

[n,m] = size(V);                                                            % Number of frequency bins and time frames
W = zeros(n,m);
w = waitbar(0,'REPET-SIM 2/2');                                             % Wait bar
for j = 1:m                                                                 % Loop over the frames
    i = I{j};                                                               % Similarities indices for frame j (i(1) = j)
    W(:,j) = median(V(:,i),2);                                              % Median of the similar frames for frame j
    waitbar(j/m,w);
end
close(w)
W = min(V,W);                                                               % For every time-frequency bins, we must have W <= V
M = (W+eps)./(V+eps);                                                       % Normalize W by V
