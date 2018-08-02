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
%       08/02/18

% Get screen size
screen_size = get(0,'ScreenSize');

% Create figure window
figure_handle = figure( ...
    'Visible','off', ...
    'Position',[screen_size(3:4)/4+1,screen_size(3:4)/2], ...
    'Name','REPET GUI', ...
    'NumberTitle','off', ...
    'MenuBar','none');

% Create toolbar on figure
uitoolbar;

% Create open and play toggle button on toolbar
openmixture_toggle = uitoggletool( ...
    'CData',iconread('file_open.png'), ...
    'TooltipString','Open mixture', ...
    'Enable','on', ...
    'ClickedCallback',@openmixturecallback);
playmixture_toggle = uitoggletool( ...
    'CData',playicon, ...
    'TooltipString','Play mixture', ...
    'Enable','off');

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

% % Create save and play background toggle button on toolbar
% savebackground_toggle = uitoggletool( ...
%     'Separator','On', ...
%     'CData',iconread('file_save.png'), ...
%     'TooltipString','Save background', ...
%     'Enable','off');
% playbackground_toggle = uitoggletool( ...
%     'CData',playicon, ...
%     'TooltipString','Play background', ...
%     'Enable','off');
% 
% % Create save and play foreground toggle button on toolbar
% saveforeground_toggle = uitoggletool( ...
%     'Separator','On', ...
%     'CData',iconread('file_save.png'), ...
%     'TooltipString','Save foreground', ...
%     'Enable','off');
% playforeground_toggle = uitoggletool( ...
%     'CData',playicon, ...
%     'TooltipString','Play foreground', ...
%     'Enable','off');

% Create mixture signal, mixture spectrogram, and beat spectrum axes
mixturesignal_axes = axes( ...
    'Units','normalized', ...
    'Box','on', ...
    'Position',[0.04,0.93,0.45,0.05], ...
    'XTick',[], ...
    'YTick',[]);
mixturespectrogram_axes = axes( ...
    'Units','normalized', ...
    'Box','on', ...
    'Position',[0.04,0.56,0.45,0.30], ...
    'XTick',[], ...
    'YTick',[]);
% beatspectrum_axes = axes( ...
%     'Units','normalized', ...
%     'Box','on', ...
%     'Position',[0.04,0.38,0.45,0.10], ...
%     'XTick',[], ...
%     'YTick',[]);

% % Create background signal and spectrogram axes
% backgroundsignal_axes = axes( ...
%     'Units','normalized', ...
%     'Box','on', ...
%     'Position',[0.54,0.93,0.45,0.05], ...
%     'XTick',[], ...
%     'YTick',[]);
% backgroundspectrogram_axes = axes( ...
%     'Units','normalized', ...
%     'Box','on', ...
%     'Position',[0.54,0.56,0.45,0.30], ...
%     'XTick',[], ...
%     'YTick',[]);
% 
% % Create foreground wave and spectrogram axes
% foregroundsignal_axes = axes( ...
%     'Units','normalized', ...
%     'Box','on', ...
%     'Position',[0.54,0.43,0.45,0.05], ...
%     'XTick',[], ...
%     'YTick',[]);
% foregroundspectrogram_axes = axes( ...
%     'Units','normalized', ...
%     'Box','on', ...
%     'Position',[0.54,0.06,0.45,0.30], ...
%     'XTick',[], ...
%     'YTick',[]);

% Make the figure visible
figure_handle.Visible = 'on';

    % Clicked callback function for the open mixture toggle button
    function openmixturecallback(~,~)
        
        % Change toggle button state to off
        openmixture_toggle.State = 'off';
        
        % Open file selection dialog box
        [mixture_name,mixture_path] = uigetfile({'*.wav';'*.mp3'}, ...
            'Select WAVE or MP3 File to Open');
        if isequal(mixture_name,0)
            return
        end
        
        % Build full file name
        mixture_file = fullfile(mixture_path,mixture_name);

        % Read audio file and return sample rate in Hz
        [mixture_signal,sample_rate] = audioread(mixture_file);
        mixture_signal = mixture_signal(1:2*sample_rate,:);
        % Number of samples and channels
        [number_samples,number_channels] = size(mixture_signal);

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
        mixture_stft = zeros(window_length,number_times,number_channels);

        % Loop over the channels
        for channel_index = 1:number_channels

            % STFT of the current channel
            mixture_stft(:,:,channel_index) ...
                = stft(mixture_signal(:,channel_index),window_function,step_length);

        end

        % Magnitude spectrogram (with DC component and without mirrored
        % frequencies)
        mixture_spectrogram = abs(mixture_stft(1:window_length/2+1,:,:));

        % Plot the mixture signal
        plot(mixturesignal_axes,(1:number_samples)/sample_rate,mixture_signal);
        
        % Update the axes properties
        mixturesignal_axes.XLim = [1,number_samples]/sample_rate;
        mixturesignal_axes.YLim = [-1,1];
        mixturesignal_axes.XGrid = 'on';
        mixturesignal_axes.Title.String = mixture_name;
        mixturesignal_axes.Title.Interpreter = 'None';
        mixturesignal_axes.XLabel.String = 'time (s)';
        
        % Display the audio spectrogram
        imagesc(mixturespectrogram_axes, ...
            [1,number_times]/number_times*number_samples/sample_rate, ...
            [1,window_length/2]/window_length*sample_rate, ...
            db(mean(mixture_spectrogram(2:end,:),3)))
        
        % Update the axes properties
        mixturespectrogram_axes.Colormap = jet;
        mixturespectrogram_axes.YDir = 'normal';
        mixturespectrogram_axes.XGrid = 'on';
        mixturespectrogram_axes.Title.String = 'Audio spectrogram';
        mixturespectrogram_axes.XLabel.String = 'time (s)';
        mixturespectrogram_axes.YLabel.String = 'frequency (Hz)';
        
        % Create object for playing audio
        mixture_player = audioplayer(mixture_signal,sample_rate);
        
        % Add clicked callback function to the play mixture toggle button
        playmixture_toggle.ClickedCallback = {@playaudiocallback,mixture_player};
        
        % Add an audio line on the mixture signal axes using the mixture 
        % player
        audioline(mixture_player,mixturesignal_axes);
        
        % Enable the play mixture, select, zoom, pan, and repet toggle 
        % buttons
        playmixture_toggle.Enable = 'on';
        select_toggle.Enable = 'on';
        zoom_toggle.Enable = 'on';
        pan_toggle.Enable = 'on';
        repet_toggle.Enable = 'on';
        
    end

end

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

% Clicked callback function for the play mixture, background, and 
% foreground toggle buttons
function playaudiocallback(object_handle,~,audio_player)

% Change the toggle button state to off
object_handle.State = 'off';

% If the playback is in progress
if isplaying(audio_player)
    
    % Change the toggle button icon to a play icon
    object_handle.CData = playicon;
    
    % Stop the audio
    stop(audio_player)
    
else
    
    % Change the toggle button icon to a stop icon
    object_handle.CData = stopicon;
    
    % Play the audio
    play(audio_player)
    
end

end

% Create, update, and delete an audio line on a signal axes using an audio 
% player
function audioline(audio_player,signal_axes)

% Add callback functions to the audio player
audio_player.StartFcn = @audioplayer_startfcn;
audio_player.StopFcn = @audioplayer_stopfcn;
audio_player.TimerFcn = @audioplayer_timerfcn;

% Initialize the audio line
audio_line = [];

    % Function to execute one time when playback starts
    function audioplayer_startfcn(~,~)
        
        % Create an audio line
        audio_line = line(signal_axes,[0,0],[-1,1]);
        
    end
    
    % Function to execute one time when playback stops
    function audioplayer_stopfcn(~,~)
        
        % Delete the audio line
        delete(audio_line)
        
    end
    
    % Function to execute repeatedly during playback
    function audioplayer_timerfcn(~,~)
        
        % Current sample and sample rate in Hz from the audio player
        current_sample = audio_player.CurrentSample;
        sample_rate = audio_player.SampleRate;
        
        % Update the audio line
        set(audio_line,'XData',[1,1]*current_sample/sample_rate)
        
    end

end
