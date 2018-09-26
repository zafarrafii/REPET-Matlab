function urepet
% UREPET a simple user interface system for recovering patterns repeating 
% in time and frequency in mixtures of sounds
%
%   Toolbar:
%       Open Mixture:                   Open mixture file (as .wav or .mp3)
%       Play Mixture:                   Play/stop selected mixture audio
%       Select:                         Select/deselect on signal axes (left/right mouse click)
%       Zoom:                           Zoom on any axes
%       Pan:                            Pan on any axes
%       REPET:                          Process selected mixture using REPET
%       Save Background:                Save background estimate of selected mixture (as .wav)
%       Play Background:                Play/stop background audio of selected mixture
%       Save Foreground:                Save foreground estimate of selected mixture (as .wav)
%       Play Foreground:                Play/stop foreground audio of selected mixture
%
%   See also http://zafarrafii.com/#REPET
%
%   Reference:
%       Zafar Rafii, Antoine Liutkus, and Bryan Pardo. "A Simple User 
%       Interface System for Recovering Patterns Repeating in Time and 
%       Frequency in Mixtures of Sounds," 40th IEEE International 
%       Conference on Acoustics, Speech and Signal Processing, Brisbane, 
%       Australia, April 19-24, 2015.
%
%   Author:
%       Zafar Rafii
%       zafarrafii@gmail.com
%       http://zafarrafii.com
%       https://github.com/zafarrafii
%       https://www.linkedin.com/in/zafarrafii/
%       09/25/18

% Get screen size
screen_size = get(0,'ScreenSize');

% Create the figure window
figure_object = figure( ...
    'Visible','off', ...
    'Position',[screen_size(3:4)/4+1,screen_size(3:4)/2], ...
    'Name','uREPET', ...
    'NumberTitle','off', ...
    'MenuBar','none', ...
    'CloseRequestFcn',@figurecloserequestfcn);

% Create a toolbar on figure
toolbar_object = uitoolbar(figure_object);

% Create the open, save, and parameters toggle buttons on toolbar
open_toggle = uitoggletool(toolbar_object, ...
    'CData',iconread('file_open.png'), ...
    'TooltipString','Open', ...
    'Enable','on', ...
    'ClickedCallback',@openclickedcallback);
save_toggle = uitoggletool(toolbar_object, ...
    'CData',iconread('file_save.png'), ...
    'TooltipString','Save', ...
    'Enable','off', ...
    'ClickedCallback',@saveclickedcallback);
parameters_toggle = uitoggletool(toolbar_object, ...
    'CData',iconread('tool_legend.png'), ...
    'TooltipString','Parameters', ...
    'Enable','off', ...
    'ClickedCallback',@parametersclickedcallback);

% Create the spectrogram axes
spectrogram_axes = axes( ...
    'OuterPosition',[0,0,1,1], ...
    'Visible','off');

% Make the figure visible
figure_object.Visible = 'on';

    function openclickedcallback(~,~)
        
        % Change the toggle button state to off
        open_toggle.State = 'off';
        
        % Remove the figure's close request callback so that it allows
        % all the other objects to get created before it can get closed
        figure_object.CloseRequestFcn = '';
        
        % Change the pointer symbol while the figure is busy
        figure_object.Pointer = 'watch';
        
        % Open file selection dialog box; return if cancel
        [input_name,input_path] = uigetfile({'*.wav';'*.mp3'}, ...
            'Select WAVE or MP3 File to Open');
        if isequal(input_name,0) || isequal(input_path,0)
            figure_object.CloseRequestFcn = @figurecloserequestfcn;
            return
        end
        
        % Clear all the (old) axes and hide them
        cla(spectrogram_axes)
        spectrogram_axes.Visible = 'off';
        
        % Build full file name
        input_file = fullfile(input_path,input_name);
        
        % Read mixture file and return sample rate in Hz
        [input_signal,sample_rate] = audioread(input_file);
        
        % Number of samples and channels
        [number_samples,number_channels] = size(input_signal);
        
        % Add the constant-Q transform (CQT) toolbox folder to the search 
        % path
        addpath('urepet/CQT_toolbox_2013')
        
        % Number of frequency channels per octave
        octave_resolution = 24;
        
        % Minimum and maximum frequency in Hz
        minimum_frequency = 27.5;
        maximum_frequency = sample_rate/2;
        
        % Initialize the CQT and the spectrogram
        input_cqt = cell(1,number_channels);
        input_spectrogram = [];
        
        % Compute the CQT and spectrogram for every channel
        for channel_index = 1:number_channels
            input_cqt{channel_index} ...
                = cqt(input_signal(:,channel_index),octave_resolution,sample_rate,minimum_frequency,maximum_frequency);
            input_spectrogram = cat(3,input_spectrogram,abs(input_cqt{channel_index}.c));
        end
        
        % Number of frequency channels and time frames
        [number_frequencies,number_times,~] = size(input_spectrogram);
        
        % True maximum frequency
        maximum_frequency = minimum_frequency*2.^((number_frequencies-1)/octave_resolution);
        
        % Display the input spectrogram (in dB, averaged over the channels)
        % (compensating for the buggy padding that the log scale is adding)
        imagesc(spectrogram_axes, ...
            [1,number_times]/number_times*number_samples/sample_rate, ...
            [(minimum_frequency*2*number_frequencies+maximum_frequency)/(2*number_frequencies+1), ...
            (maximum_frequency*2*number_frequencies+minimum_frequency)/(2*number_frequencies+1)], ...
            db(mean(input_spectrogram,3)))
        
        % Update the mixture spectrogram axes properties
        spectrogram_axes.YScale = 'log';
        spectrogram_axes.YDir = 'normal';
        spectrogram_axes.XGrid = 'on';
        spectrogram_axes.Colormap = jet;
        spectrogram_axes.Title.String = 'Log-spectrogram';
        spectrogram_axes.XLabel.String = 'Time (s)';
        spectrogram_axes.YLabel.String = 'Frequency (Hz)';
        drawnow

        % Enable the save and parameters toggle buttons
        save_toggle.Enable = 'on';
        parameters_toggle.Enable = 'on';
        
        % Add the figure's close request callback back
        figure_object.CloseRequestFcn = @figurecloserequestfcn;
        
        % Change the pointer symbol back
        figure_object.Pointer = 'arrow';
        
        return
        
        
        x = [];                                                                     % Initial input/output
        fs = [];
        Xcq = [];
        background_or_foreground = 'b';                                             % Initial recovering background (or foreground)
        max_number_repetitions = 5;                                                 % Initial max number of repetitions
        min_time_separation = 1;                                                    % Initial min time separation between repetitions (in seconds)
        min_frequency_separation = 1;                                               % Initial min frequency separation between repetitions (in semitones)

        
        return
        
        
        P = db(mean(V,3));                                                  % Mean spectrogram in decibels
        imagesc(P);                                                         % Scale data and display image object
        set(gca, ...
            'CLim',[min(P(:)),max(P(:))], ...                               % Color limits for objects using colormap
            'XTick',round(m/(l/fs)):round(m/(l/fs)):m, ...                  % X-tick mark locations (every 1 second)
            'XTickLabel',1:round(l/fs), ...                                 % X-tick mark labels (every 1 second)
            'YDir','normal', ...                                            % Direction of increasing values along axis
            'YTick',1:B:n, ...                                              % Y-tick mark locations (every "A" Hz)
            'YTickLabel',fmin*2.^(0:ceil(n/B)-1))                           % Y-tick mark labels (every "A" Hz)
        title(filename, ...                                                 % Add title to current axes
            'Interpreter','none')                                           % Interpretation of text characters
        xlabel('time (s)')                                                  % Label x-axis
        ylabel('log-frequency (Hz)')                                        % Label y-axis
        
        while 1                                                             % Infinite loop
            h = imrect(gca);                                                % Create draggable rectangle
            if isempty(h)                                                   % Return if figure close
                return
            end
            fcn = makeConstrainToRectFcn('imrect', ...
                get(gca,'XLim'),get(gca,'YLim'));                           % Create rectangularly bounded drag constraint function
            setPositionConstraintFcn(h,fcn);                                % Set position constraint function of ROI object
            position = wait(h);                                             % Block MATLAB command line until ROI creation is finished
            if isempty(position)                                            % Return if figure close
                return
            end
            delete(h)                                                       % Remove files or objects
            
            b = waitbar(0,'Please wait...');                                % Open wait bar dialog box
            j = round(position(1));                                         % X-position
            i = round(position(2));                                         % Y-position
            w = round(position(3));                                         % Width
            h = round(position(4));                                         % Height
            R = V(i:i+h-1,j:j+w-1,:);                                       % Selected rectangle
            C = normxcorr2(mean(R,3),mean(V,3));                            % Normalized 2-D cross-correlation
            V = padarray(V,[h-1,w-1,0],'replicate');                        % Pad array for finding peaks
            
            np = max_number_repetitions;                                    % Maximum number of peaks
            mpd = [min_frequency_separation*2, ...
                min_time_separation*round(m/(l/fs))];                       % Minimum peak separation
            k = 1;                                                          % Initialize peak counter
            while k <= np                                                   % Repeat execution of statements while condition is true
                [~,I] = max(C(:));                                          % Linear index of peak
                [I,J] = ind2sub([n+h-1,m+w-1],I);                           % Subscripts from linear index
                C(max(1,I-mpd(1)+1):min(n+h-1,I+mpd(1)+1), ...
                    max(1,J-mpd(2)+1):min(m+w-1,J+mpd(2)+1)) = 0;           % Zero neighborhood around peak
                R = cat(4,R,V(I:I+h-1,J:J+w-1,:));                          % Concatenate similar rectangles
                waitbar(k/np,b)                                             % Update wait bar dialog box
                k = k+1;                                                    % Update peak counter
            end
            close(b)                                                        % Close wait bar dialog box
            
            V = V(h:n+h-1,w:m+w-1,:);                                       % Remove pad array
            M = (min(median(R,4),R(:,:,:,1))+eps)./(R(:,:,:,1)+eps);        % Time-frequency mask of the underlying repeating structure
            if strcmp(background_or_foreground,'f')                         % If recovering foreground
                M = 1-M;
            end
            P = getimage(gca);                                              % Image data from axes
            P(i:i+h-1,j:j+w-1) = 0;
            for k = 1:p                                                     % Loop over the channels
                Xcqk = Xcq{k};
                Xcqk.c(i:i+h-1,j:j+w-1) = Xcqk.c(i:i+h-1,j:j+w-1,:).*M(:,:,k);  % Apply time-frequency mask to CQT
                Xcq{k} = Xcqk;
                P(i:i+h-1,j:j+w-1) = P(i:i+h-1,j:j+w-1)+Xcqk.c(i:i+h-1,j:j+w-1);
            end
            P(i:i+h-1,j:j+w-1) = db(P(i:i+h-1,j:j+w-1)/p);                  % Update rectangle in image
            set(get(gca,'Children'),'CData',P)                              % Update image in axes
       end
        
    end

    function saveclickedcallback(~,~)
        
        if isempty(x)                                                       % Return if no input/output
            return
        end
        
        [filename2,pathname] = uiputfile( ...                               % Open standard dialog box for saving files
            {'*.wav', 'WAVE files (*.wav)'; ...
            '*.mp3', 'MP3 files (*.mp3)'}, ...
            'Save the audio file');
        if isequal(filename2,0)                                             % Return if user selects Cancel
            return
        end
        
        p = size(x,2);                                                      % Number of channels
        x = [];
        for k = 1:p                                                         % Loop over the channels
            Xcqk = Xcq{k};
            x = cat(2,x,icqt(Xcqk));
        end
        file = fullfile(pathname,filename2);                                % Build full file name from parts
        audiowrite(file,x,fs)                                               % Write audio file
        
    end

    function parametersclickedcallback(~,~)
        
        prompt = {'Recovering background (b) or foreground (f):', ...
            'Max number of repetitions:', ...
            'Min time separation between repetitions (in seconds):', ...
            'Min frequency separation between repetitions (in semitones):'};
        dlg_title = 'Parameters';
        num_lines = 1;
        def = {background_or_foreground, ...
            num2str(max_number_repetitions), ...
            num2str(min_time_separation), ...
            num2str(min_frequency_separation)};
        answer = inputdlg(prompt,dlg_title,num_lines,def);                  % Create and open input dialog box
        if isempty(answer)                                                  % Return if user selects Cancel
            return
        end
        
        background_or_foreground = answer{1};
        max_number_repetitions = str2double(answer{2});
        min_time_separation = str2double(answer{3});
        min_frequency_separation = str2double(answer{4});
        
    end

    % Close request callback function for the figure
    function figurecloserequestfcn(~,~)
        
        % Create question dialog box to close the figure
        user_answer = questdlg('Close uREPET?',...
            'Close uREPET','Yes','No','Yes');
        switch user_answer
            case 'Yes'
                delete(figure_object)
            case 'No'
                return
        end
        
    end

end

% Read icon from Matlab
function image_data = iconread(icon_name)

% Read icon image from Matlab ([16x16x3] 16-bit PNG) and also return
% its transparency ([16x16] AND mask)
[image_data,~,image_transparency] ...
    = imread(fullfile(matlabroot,'toolbox','matlab','icons',icon_name),'PNG');

% Convert the image to double precision (in [0,1])
image_data = im2double(image_data);

% Convert the 0's to NaN's in the image using the transparency
image_data(image_transparency==0) = NaN;

end
