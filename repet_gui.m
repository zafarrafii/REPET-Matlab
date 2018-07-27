function repet_gui
% REPET_GUI REpeating Pattern Extraction Technique (REPET) Graphical User Interface (GUI).
%
%   REPET_GUI
%       Select tool (toolbar left):                                         Select/deselect on wave axes (left/right mouse click)
%       Zoom tool (toolbar center):                                         Zoom in/out on any axes (left/right mouse click)
%       Pan tool (toolbar right):                                           Pan left and right on any axes
%
%       Load mixture button (top-left quarter, top-left):                   Load mixture file (WAVE files only)
%       Play mixture button (top-left quarter, top-left):                   Play/stop mixture audio
%       Mixture wave axes (top-left quarter, top):                          Display mixture wave
%       REPET button (top-left quarter, top-right):                         Process mixture selection using REPET
%       Mixture spectrogram axes (top-left quarter, bottom):                Display spectrogram of mixture selection
%
%       Beat spectrum axes (bottom-left, quarter top):                      Display beat spectrum of mixture selection
%       Period slider/edit (bottom-left, quarter top):                      Modify repeating period (in seconds)
%       Hardness slider/edit (bottom-left, quarter center):                 Modify masking hardness (in [0,1])
%           Turns soft time-frequency mask into binary time-frequency mask
%           The closer to 0, the softer the mask, the less separation artifacts (0 = original soft mask)
%           The closer to 1, the harder the mask, the less source interference (1 = full binary mask)
%       Threshold slider/edit (bottom-left quarter, bottom):                Modify masking threshold (in [0,1])
%           Defines pivot value around which the energy will be spread apart (when hardness > 0)
%           The closer to 0, the more energy for the background, the less interference in the foreground
%           The closer to 1, the less energy for the background, the less interference from the foreground
%
%       Save background button (top-right quarter, top-left):               Save background estimate of mixture selection in WAVE file
%       Play background button (top-right quarter, top-left):               Play/stop background audio of mixture selection
%       Background wave axes (top-right quarter, top):                      Display background wave of mixture selection
%       Background spectrogram axes (top-right quarter, bottom):            Display background spectrogram of mixture selection
%
%       Save foreground button (bottom-right quarter, top-left):            Save foreground estimate of mixture selection in WAVE file
%       Play foreground button (bottom-right quarter top-left):             Play/stop foreground audio of mixture selection
%       Foreground wave axes (bottom-right quarter, top):                   Display foreground wave of mixture selection
%       Foreground spectrogram axes (bottom-right quarter, bottom):         Display foreground spectrogram of mixture selection
%
%   See also http://zafarrafii.com/#REPET
% 
%   References:
%       Zafar Rafii, Antoine Liutkus, and Bryan Pardo. "REPET for 
%       Background/Foreground Separation in Audio," Blind Source 
%       Separation, chapter 14, pages 395-411, Springer Berlin Heidelberg, 
%       2014.
%       
%       Zafar Rafii and Bryan Pardo. "Audio Separation System and Method," 
%       US 20130064379 A1, March 2013.
%   
%       Zafar Rafii and Bryan Pardo. "REpeating Pattern Extraction 
%       Technique (REPET): A Simple Method for Music/Voice Separation," 
%       IEEE Transactions on Audio, Speech, and Language Processing, volume 
%       21, number 1, pages 71-82, January, 2013.
%       
%       Zafar Rafii and Bryan Pardo. "A Simple Music/Voice Separation 
%       Method based on the Extraction of the Repeating Musical Structure," 
%       36th International Conference on Acoustics, Speech and Signal 
%       Processing, Prague, Czech Republic, May 22-27, 2011.
%   
%   Author:
%       Zafar Rafii
%       zafarrafii@gmail.com
%       http://zafarrafii.com
%       https://github.com/zafarrafii
%       https://www.linkedin.com/in/zafarrafii/
%       07/27/18

% Make the figure a fourth of the screen
screen_size = get(0,'ScreenSize');
figure_size = screen_size(3:4)/2;

% Create figure window
figure_handle = figure( ...
    'Visible','off', ...
    'Position',[screen_size(3:4)/4+1,figure_size], ...
    'Name','REPET GUI', ...
    'NumberTitle','off', ...
    'MenuBar','none');

% Create toolbar on figure
uitoolbar;

% Create open and play toggle button on toolbar
openaudio_toggle = uitoggletool( ...
    'CData',iconread('file_open.png'), ...
    'TooltipString','Open audio', ...
    'Enable','on', ...
    'ClickedCallback',@openaudiocallback);
playaudio_toggle = uitoggletool( ...
    'CData',playicon, ...
    'TooltipString','Play audio', ...
    'Enable','off', ...
    'ClickedCallback',@playaudiocallback);

% Create pointer, zoom, and hand toggle button on toolbar
select_toggle = uitoggletool( ...
    'Separator','On', ...
    'CData',iconread('tool_pointer.png'), ...
    'TooltipString','Select', ...
    'Enable','off');
zoom_toggle = uitoggletool( ...
    'CData',iconread('tool_zoom_in.png'), ...
    'TooltipString','Zoom', ...
    'Enable','off');
pan_toggle = uitoggletool( ...
    'CData',iconread('tool_hand.png'), ...
    'TooltipString','Pan', ...
    'Enable','off');

% Create repet toggle button on toolbar
repet_toggle = uitoggletool( ...
    'Separator','On', ...
    'CData',repeticon, ...
    'TooltipString','REPET', ...
    'Enable','off');

% Create save and play background toggle button on toolbar
savebackground_toggle = uitoggletool( ...
    'Separator','On', ...
    'CData',iconread('file_save.png'), ...
    'TooltipString','Save background', ...
    'Enable','off');
playbackground_toggle = uitoggletool( ...
    'CData',playicon, ...
    'TooltipString','Play background', ...
    'Enable','off');

% Create save and play foreground toggle button on toolbar
saveforeground_toggle = uitoggletool( ...
    'Separator','On', ...
    'CData',iconread('file_save.png'), ...
    'TooltipString','Save foreground', ...
    'Enable','off');
playforeground_toggle = uitoggletool( ...
    'CData',playicon, ...
    'TooltipString','Play foreground', ...
    'Enable','off');

% Create signal, spectrogram, and beat spectrum axes
audiosignal_axes = axes( ...
    'Units','normalized', ...
    'Box','on', ...
    'Position',[0.025,0.85,0.45,0.1], ...
    'XTick',[], ...
    'YTick',[]);
audiospectrogram_axes = axes( ...
    'Units','normalized', ...
    'Box','on', ...
    'Position',[0.025,0.55,0.45,0.2], ...
    'XTick',[], ...
    'YTick',[]);
beatspectrum_axes = axes( ...
    'Units','normalized', ...
    'Box','on', ...
    'Position',[0.025,0.35,0.45,0.1], ...
    'XTick',[], ...
    'YTick',[]);

% Create background signal and spectrogram axes
backgroundsignal_axes = axes( ...
    'Units','normalized', ...
    'Box','on', ...
    'Position',[0.525,0.85,0.45,0.1], ...
    'XTick',[], ...
    'YTick',[]);
backgroundspectrogram_axes = axes( ...
    'Units','normalized', ...
    'Box','on', ...
    'Position',[0.525,0.55,0.45,0.2], ...
    'XTick',[], ...
    'YTick',[]);

% Create foreground wave and spectrogram axes
foregroundsignal_axes = axes( ...
    'Units','normalized', ...
    'Box','on', ...
    'Position',[0.525,0.35,0.45,0.1], ...
    'XTick',[], ...
    'YTick',[]);
foregroundspectrogram_axes = axes( ...
    'Units','normalized', ...
    'Box','on', ...
    'Position',[0.525,0.05,0.45,0.2], ...
    'XTick',[], ...
    'YTick',[]);

% Create object for playing audio
audio_player = [];

% Make the figure visible
figure_handle.Visible = 'on';

    % Create play icon, with transparency
    function image_data = playicon
        
        % Create the upper-half of a black triangle, with NaN's everywhere else
        image_data = [nan(2,16);[nan(6,3),kron(triu(nan(6,5)),ones(1,2)),nan(6,3)]];
        
        % Create the whole black triangle in 3d
        image_data = repmat([image_data;image_data(end:-1:1,:)],[1,1,3]);
        
    end

    % Create stop icon, with transparency
    function image_data = stopicon
        
        % Create a black square, with NaN's everywhere else
        image_data = nan(16,16);
        image_data(4:13,4:13) = 0;
        
        % Make the black square in 3d
        image_data = repmat(image_data,[1,1,3]);
        
    end

    % Create repet icon, with transparency
    function image_data = repeticon

        % Create R, E, P, E, and T in 3d
        image_data = nan(16,16,1);
        
        image_data(2:8,2:3) = 0;
        image_data([2,3,5,6],4) = 0;
        image_data([3:5,7:8],5) = 0;
        
        image_data(2:8,7:8) = 0;
        image_data([2,3,5,7,8],9) = 0;
        image_data([2,3,7,8],10) = 0;
        
        image_data(10:16,2:3) = 0;
        image_data([10,11,13,14],4) = 0;
        image_data(11:13,5) = 0;
        
        image_data(10:16,7:8) = 0;
        image_data([10,11,13,15,16],9) = 0;
        image_data([10,11,15,16],10) = 0;
        
        image_data(10:11,12:15) = 0;
        image_data(12:16,13:14) = 0;
        
        image_data = repmat(image_data,[1,1,3]);
        
    end

    % Read icon from Matlab, with transparency
    function image_data = iconread(icon_name)
        
        % Read icon image from Matlab ([16x16x3] 16-bit PNG) and also return its 
        % transparency ([16x16] AND mask)
        [image_data,~,image_transparency] ...
            = imread(fullfile(matlabroot,'toolbox','matlab','icons',icon_name),'PNG');
        
        % Convert the image to double precision (in [0,1])
        image_data = im2double(image_data);
        
        % Convert the 0's to NaN's in the image using the transparency
        image_data(image_transparency==0) = NaN;

    end

    % Callback function for the open audio toggle button
    function openaudiocallback(~,~)

        % Change back the state of the toggle button to off
        openaudio_toggle.State = 'off';

        % Open file selection dialog box
        [audio_name,audio_path] = uigetfile({'*.wav';'*.mp3'}, ...
            'Select WAVE or MP3 File to Open');
        if isequal(audio_name,0)
            return
        end

        % Build full file name
        audio_file = fullfile(audio_path,audio_name);

        % Read audio file and return sample rate in Hz
        [audio_signal,sample_rate] = audioread(audio_file);
        audio_signal = audio_signal(1:1*sample_rate,:);
        % Number of samples and channels
        [number_samples,number_channels] = size(audio_signal);

        % Window length in samples (audio stationary around 40 ms; power of 2 for 
        % fast FFT and constant overlap-add)
        window_length = 2.^nextpow2(0.04*sample_rate);

        % Window function ('periodic' Hamming window for constant overlap-add)
        window_function = hamming(window_length,'periodic');

        % Step function (half the (even) window length for constant overlap-add)
        step_length = window_length/2;

        % Number of time frames
        number_times = ceil((window_length-step_length+number_samples)/step_length);

        % Initialize the STFT
        audio_stft = zeros(window_length,number_times,number_channels);

        % Loop over the channels
        for channel_index = 1:number_channels

            % STFT of the current channel
            audio_stft(:,:,channel_index) ...
                = stft(audio_signal(:,channel_index),window_function,step_length);

        end

        % Magnitude spectrogram (with DC component and without mirrored
        % frequencies)
        audio_spectrogram = abs(audio_stft(1:window_length/2+1,:,:));

        % Plot the audio signal
        plot(audiosignal_axes,(1:number_samples)/sample_rate,audio_signal);

        % Update the axes properties
        audiosignal_axes.XLim = [1,number_samples]/sample_rate;
        audiosignal_axes.YLim = [-1,1];
        audiosignal_axes.XGrid = 'on';
        audiosignal_axes.Title.String = audio_name;
        audiosignal_axes.Title.Interpreter = 'None';
        audiosignal_axes.XLabel.String = 'time (s)';
        
        % Display the audio spectrogram
        imagesc(audiospectrogram_axes,db(mean(audio_spectrogram,3)))
        
        % Update the axes properties
        audiospectrogram_axes.Colormap = jet;
        audiospectrogram_axes.YDir = 'normal';
        audiospectrogram_axes.XGrid = 'on';
        audiospectrogram_axes.Title.String = 'Audio spectrogram';
        audiospectrogram_axes.XTick = ceil(((1:floor(number_samples/sample_rate))*sample_rate+window_length-step_length)/step_length);
        audiospectrogram_axes.XTickLabel = 1:floor(number_samples/sample_rate);
        audiospectrogram_axes.XLabel.String = 'time (s)';
        audiospectrogram_axes.YTick = round((1e3:1e3:sample_rate/2)/sample_rate*window_length);
        audiospectrogram_axes.YTickLabel = 1:sample_rate/2*1e-3;
        audiospectrogram_axes.YLabel.String = 'frequency (kHz)';
        
        % Update the toggle buttons
        playaudio_toggle.Enable = 'on';
        select_toggle.Enable = 'on';
        zoom_toggle.Enable = 'on';
        pan_toggle.Enable = 'on';
        repet_toggle.Enable = 'on';
        
        % Create object for playing audio
        audio_player = audioplayer(audio_signal,sample_rate);
        
        set(audio_player, ...
            'StartFcn',@audioplayer_startfcn, ...
            'StopFcn',@audioplayer_stopfcn, ...
            'TimerFcn',@audioplayer_timerfcn)
        
    end

    % Callback function for the play audio toggle button
    function playaudiocallback(~,~)
        
        % Change back the state of the toggle button to off
        playaudio_toggle.State = 'off';
        
        % If playback is in progress
        if isplaying(audio_player)
            
            % Stop playback
            stop(audio_player)
            
        else
            
            % Play audio from audioplayer object
            play(audio_player)
            
        end
        
    end

    function audioplayer_startfcn(~,~)
        
        % Update the toggle button icon
        playaudio_toggle.CData = stopicon;
        
    end

    function audioplayer_stopfcn(~,~)

        % Update the toggle button icon
        playaudio_toggle.CData = playicon;

    end

    function audioplayer_timerfcn(~,~)
        
        rand
        
    end

    % Short-time Fourier transform (STFT) (with zero-padding at the edges)
    function audio_stft = stft(audio_signal,window_function,step_length)
        
        % Number of samples and window length
        number_samples = length(audio_signal);
        window_length = length(window_function);
        
        % Number of time frames
        number_times = ceil((window_length-step_length+number_samples)/step_length);
        
        % Zero-padding at the start and end to center the windows
        audio_signal = [zeros(window_length-step_length,1);audio_signal; ...
            zeros(number_times*step_length-number_samples,1)];
        
        % Initialize the STFT
        audio_stft = zeros(window_length,number_times);
        
        % Loop over the time frames
        for time_index = 1:number_times
            
            % Window the signal
            sample_index = step_length*(time_index-1);
            audio_stft(:,time_index) = audio_signal(1+sample_index:window_length+sample_index).*window_function;
            
        end
        
        % Fourier transform of the frames
        audio_stft = fft(audio_stft);
        
    end

end







