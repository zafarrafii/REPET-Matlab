
%% PARAMETERS
fs = 44100;
fmin = 27.5;
B = 48;
gamma = 20; 
fmax = fs/2;

%% INPUT SIGNAL
x = wavread('brent2.wav');
x = x(:); xlen = length(x);

%% COMPUTE COEFFIENTS
% full rasterized transform
Xcq = cqt(x, B, fs, fmin, fmax, 'rasterize', 'full','gamma', gamma);

% piecewise rasterized transform
% Xcq = cqt(x, B, fs, fmin, fmax,  'rasterize', 'piecewise', 'format', 'sparse', 'gamma', gamma);

% no rasterization
% Xcq = cqt(x, B, fs, fmin, fmax, 'rasterize', 'none', 'gamma', gamma);

c = Xcq.c;

%% ICQT
[y gd] = icqt(Xcq);

%% RECONSTRUCTION ERROR [dB]
SNR = 20*log10(norm(x-y)/norm(x));
disp(['reconstruction error = ' num2str(SNR) ' dB']);

%% REDUNDANCY
if iscell(c)
   disp(['redundancy = ' num2str( (2*sum(cellfun(@numel,c)) + ...
       length(Xcq.cDC) + length(Xcq.cNyq)) / length(x))]); 
elseif issparse(c)
   disp(['redundancy = ' num2str( (2*nnz(c) + length(Xcq.cDC) + ...
       length(Xcq.cNyq)) / length(x))]);  
else
   disp(['redundancy = ' num2str( (2*size(c,1)*size(c,2) + ...
       length(Xcq.cDC) + length(Xcq.cNyq)) / length(x))]); 
end

%% PLOT
if 1
switch(Xcq.rast)
    case 'full'
        figure; imagesc(20*log10(abs(flipud(c))+eps));
        hop = xlen/size(c,2);
        xtickVec = 0:round(fs/hop):size(c,2)-1;
        set(gca,'XTick',xtickVec);
        ytickVec = 0:B:size(c,1)-1;
        set(gca,'YTick',ytickVec);
        ytickLabel = round(fmin * 2.^( (size(c,1)-ytickVec)/B));
        set(gca,'YTickLabel',ytickLabel);
        xtickLabel = 0 : length(xtickVec) ;
        set(gca,'XTickLabel',xtickLabel);
        xlabel('time [s]', 'FontSize', 12, 'Interpreter','latex'); 
        ylabel('frequency [Hz]', 'FontSize', 12, 'Interpreter','latex');
        set(gca, 'FontSize', 10);

    case 'piecewise'
        if strcmp(Xcq.format, 'sparse')
            cFill = cqtFillSparse(c,Xcq.M,Xcq.B);
            figure; imagesc(20*log10(abs(flipud(cFill))));

            hop = xlen/size(c,2);
            xtickVec = 0:round(fs/hop):size(c,2)-1;
            set(gca,'XTick',xtickVec);
            ytickVec = 0:B:size(c,1)-1;
            set(gca,'YTick',ytickVec);
            ytickLabel = round(fmin * 2.^( (size(c,1)-ytickVec)/B));
            set(gca,'YTickLabel',ytickLabel);
            xtickLabel = 0 : length(xtickVec) ;
            set(gca,'XTickLabel',xtickLabel);
            xlabel('time [s]', 'FontSize', 12, 'Interpreter','latex'); 
            ylabel('frequency [Hz]', 'FontSize', 12, 'Interpreter','latex');
            set(gca, 'FontSize', 10);
        else
            figure; plotnsgtf(c.',Xcq.shift,fs,fmin,fmax,B,2,60);
        end
        
    otherwise
        figure; plotnsgtf({Xcq.cDC Xcq.c{1:end} Xcq.cNyq}.',Xcq.shift,fs,fmin,fmax,B,2,60); 
end
end


