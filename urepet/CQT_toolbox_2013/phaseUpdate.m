function Y = phaseUpdate(c, fbas, shiftBins, xlen, fs, threshold)

%PHASEUPDATE Modify phases of Constant-Q/Variable-Q representation to 
%            retain phase coherence after coefficient shift
%            (transposition). For readability reasons a fully
%            rasterized representation is needed. However, the same 
%            procedure can be implemented based on a piecewise rasterized
%            representation.
%
%   Usage:  Y = phaseUpdate(c, fbas, shiftBins, xlen, fs, threshold)
%
%   Input parameters:
%         c         : transform coefficients
%         fbas      : center frequencies of filters
%         shiftBins : pitch-shifting factor in CQT bins
%         xlen      : length of input signal
%         fs        : sampling rate
%         threshold : mininum amplitude for peak-picking
%
%   Output parameters: 
%         Y         : modified transform coefficients
%
%   See also:  cqt, icqt
%
%   References:
%     C. Schörkhuber, A. Klapuri, and A. Sontacchi. Audio Pitch Shifting 
%     Using the Constant-Q Transform.
%     C. Schörkhuber, A. Klapuri, and A. Sontacchi. Pitch Shifting of Audio 
%     Signals Using the Constant-Q Trasnform.
%     C. Schörkhuber, A. Klapuri, N. Holighaus, and M. Dörfler. A Matlab 
%     Toolbox for Efficient Perfect Reconstruction log-f Time-Frequecy 
%     Transforms.
%
%
% Copyright (C) 2011 Christian Schörkhuber.
% 
% This work is licensed under the Creative Commons 
% Attribution-NonCommercial-ShareAlike 3.0 Unported 
% License. To view a copy of this license, visit 
% http://creativecommons.org/licenses/by-nc-sa/3.0/ 
% or send a letter to 
% Creative Commons, 444 Castro Street, Suite 900, 
% Mountain View, California, 94041, USA.

% Authors: Christian Schörkhuber
% Date: 10.12.2011

mag = abs(c);
H = xlen/size(c,2);
bins = size(c,1);

Y = zeros(size(c));
Y(:,1) = c(:,1);
accumulated_rotation_angles=zeros(size(c,1),1);
modFrame = zeros(size(c,1),1);
rotAng = zeros(bins,1);

for ii = 2:size(c,2)
   
    %peak picking
    af = mag(:,ii);
    dl1 = (af(2:end-1) - af(1:end-2)) > 0;
    dr1 = (af(2:end-1) - af(3:end)) > 0;
    val = af(2:end-1);
    valcrit = val > threshold;
    extraMask = true(size(val));
    peaks = find(dl1 & dr1 & valcrit & extraMask) + 1;
    if shiftBins > 0
        tmpidx = find(peaks >= bins-shiftBins,1);
        if ~isempty(tmpidx)
            peaks = peaks(1:tmpidx-1);
        end
    elseif shiftBins < 0
        tmpidx = find(peaks <= abs(shiftBins),1,'last');
        if ~isempty(tmpidx)
            peaks = peaks(tmpidx+1:end);
        end
    end
    
    if ~isempty(peaks)
        
       %find regions of influence around peaks
       regions = round(0.5*(peaks(1:end-1)+peaks(2:end)));  
       regions = [0; regions; bins];
       
       %update phases 
       %(one rotation value for each region = vertical phase locking)
       shift_freq = fbas(peaks+shiftBins) - fbas(peaks);
       norm_shift_freq1 = 2*pi*shift_freq/fs;
       rotation_angles=accumulated_rotation_angles(peaks) + H*norm_shift_freq1;  
       for u=1:length(peaks)
            rotAng(regions(u)+1:regions(u+1)) = rotation_angles(u);
       end
       modFrame = c(:,ii) .* exp(1i*rotAng);
       accumulated_rotation_angles = rotAng;
        
    else
        
        modFrame = c(:,ii); %if no peaks are found
        
    end
       
    Y(:,ii) = modFrame;
    
end