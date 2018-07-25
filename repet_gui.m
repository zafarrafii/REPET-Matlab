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
%       07/25/18

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

% Create structure of handles
handles_structure = guihandles(figure_handle); 

% Create toolbar on figure
uitoolbar;

% Create open and play toggle button on toolbar
handles_structure.openaudio_toggle = uitoggletool( ...
    'CData',iconread('file_open.png'), ...
    'TooltipString','Open audio', ...
    'Enable','on', ...
    'ClickedCallback',@openaudiocallback);
handles_structure.playaudio_toggle = uitoggletool( ...
    'CData',playicon, ...
    'TooltipString','Play audio', ...
    'Enable','off', ...
    'ClickedCallback',@playaudiocallback);

% Create pointer, zoom, and hand toggle button on toolbar
handles_structure.select_toggle = uitoggletool( ...
    'Separator','On', ...
    'CData',iconread('tool_pointer.png'), ...
    'TooltipString','Select', ...
    'Enable','off');
handles_structure.zoom_toggle = uitoggletool( ...
    'CData',iconread('tool_zoom_in.png'), ...
    'TooltipString','Zoom', ...
    'Enable','off');
handles_structure.pan_toggle = uitoggletool( ...
    'CData',iconread('tool_hand.png'), ...
    'TooltipString','Pan', ...
    'Enable','off');

% Create repet toggle button on toolbar
handles_structure.repet_toggle = uitoggletool( ...
    'Separator','On', ...
    'CData',repeticon, ...
    'TooltipString','REPET', ...
    'Enable','off');

% Create save and play background toggle button on toolbar
handles_structure.savebackground_toggle = uitoggletool( ...
    'Separator','On', ...
    'CData',iconread('file_save.png'), ...
    'TooltipString','Save background', ...
    'Enable','off');
handles_structure.playbackground_toggle = uitoggletool( ...
    'CData',playicon, ...
    'TooltipString','Play background', ...
    'Enable','off');

% Create save and play foreground toggle button on toolbar
handles_structure.saveforeground_toggle = uitoggletool( ...
    'Separator','On', ...
    'CData',iconread('file_save.png'), ...
    'TooltipString','Save foreground', ...
    'Enable','off');
handles_structure.playforeground_toggle = uitoggletool( ...
    'CData',playicon, ...
    'TooltipString','Play foreground', ...
    'Enable','off');

% Create signal, spectrogram, and beat spectrum axes
handles_structure.audiosignal_axes = axes( ...
    'Units','normalized', ...
    'Box','on', ...
    'Position',[0.025,0.85,0.45,0.1], ...
    'XTick',[], ...
    'YTick',[]);
handles_structure.audiospectrogram_axes = axes( ...
    'Units','normalized', ...
    'Box','on', ...
    'Position',[0.025,0.55,0.45,0.2], ...
    'XTick',[], ...
    'YTick',[]);
handles_structure.beatspectrum_axes = axes( ...
    'Units','normalized', ...
    'Box','on', ...
    'Position',[0.025,0.35,0.45,0.1], ...
    'XTick',[], ...
    'YTick',[]);

% Create background signal and spectrogram axes
handles_structure.backgroundsignal_axes = axes( ...
    'Units','normalized', ...
    'Box','on', ...
    'Position',[0.525,0.85,0.45,0.1], ...
    'XTick',[], ...
    'YTick',[]);
handles_structure.backgroundspectrogram_axes = axes( ...
    'Units','normalized', ...
    'Box','on', ...
    'Position',[0.525,0.55,0.45,0.2], ...
    'XTick',[], ...
    'YTick',[]);

% Create foreground wave and spectrogram axes
handles_structure.foregroundsignal_axes = axes( ...
    'Units','normalized', ...
    'Box','on', ...
    'Position',[0.525,0.35,0.45,0.1], ...
    'XTick',[], ...
    'YTick',[]);
handles_structure.foregroundspectrogram_axes = axes( ...
    'Units','normalized', ...
    'Box','on', ...
    'Position',[0.525,0.05,0.45,0.2], ...
    'XTick',[], ...
    'YTick',[]);

% Make the figure visible
figure_handle.Visible = 'on';

% Store the structure of handles
guidata(figure_handle,handles_structure)

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

% Callback function for the open audio toggle button
function openaudiocallback(~,~)

% Retrieve the structure of handles
handles_structure = guidata(gcbo);

% Change back the state of the toggle button to off
handles_structure.openaudio_toggle.State = 'off';

% Open file selection dialog box
[audio_name,audio_path] = uigetfile({'*.wav';'*.mp3'}, ...
    'Select WAVE or MP3 File to Open');
if isequal(audio_name,0)
    return
end

% Build full name
audio_file = fullfile(audio_path,audio_name);

% Read audio file and return sample rate in Hz
[audio_signal,sample_rate] = audioread(audio_file);
audio_signal = audio_signal(1:sample_rate,:);
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
plot(handles_structure.audiosignal_axes,(1:number_samples)/sample_rate,audio_signal);

% Update the axes properties
handles_structure.audiosignal_axes.XLim = [1,number_samples]/sample_rate;
handles_structure.audiosignal_axes.YLim = [-1,1];
handles_structure.audiosignal_axes.XGrid = 'on';
handles_structure.audiosignal_axes.Title.String = audio_name;
handles_structure.audiosignal_axes.Title.Interpreter = 'None';
handles_structure.audiosignal_axes.XLabel.String = 'time (s)';

% Display the audio spectrogram
audio_spectrogram = mean(audio_spectrogram,3);
% color_limits = db([min(audio_spectrogram(:)),max(audio_spectrogram(:))]);
imagesc(handles_structure.audiospectrogram_axes,db(audio_spectrogram))

% Update the axes properties
handles_structure.audiospectrogram_axes.Colormap = jet;
handles_structure.audiospectrogram_axes.YDir = 'normal';
handles_structure.audiospectrogram_axes.XGrid = 'on';
handles_structure.audiospectrogram_axes.Title.String = 'Audio spectrogram';
handles_structure.audiospectrogram_axes.XTick = round((1:floor(number_samples/sample_rate))*sample_rate/step_length);
handles_structure.audiospectrogram_axes.XTickLabel = 1:floor(number_samples/sample_rate);
handles_structure.audiospectrogram_axes.XLabel.String = 'time (s)';
handles_structure.audiospectrogram_axes.YTick = round((1e3:1e3:sample_rate/2)/sample_rate*window_length);
handles_structure.audiospectrogram_axes.YTickLabel = 1:sample_rate/2*1e-3;
handles_structure.audiospectrogram_axes.YLabel.String = 'frequency (kHz)';

% Update the toggle buttons
handles_structure.playaudio_toggle.Enable = 'on';
handles_structure.select_toggle.Enable = 'on';
handles_structure.zoom_toggle.Enable = 'on';
handles_structure.pan_toggle.Enable = 'on';
handles_structure.repet_toggle.Enable = 'on';

% Create object for playing audio
handles_structure.audio_player = audioplayer(audio_signal,sample_rate);


set(handles_structure.audio_player, ...
    'StartFcn',@audioplayer_startfcn, ...
    'StopFcn',@audioplayer_stopfcn)

% Update the structur of handles
guidata(gcbo,handles_structure)
    
end

% Callback function for the play audio toggle button
function playaudiocallback(~,~)

% Retrieve the structure of handles
handles_structure = guidata(gcbo);

% Change back the state of the toggle button to off
handles_structure.playaudio_toggle.State = 'off';

% If playback is in progress
if isplaying(handles_structure.audio_player)
    
    % Stop playback
    stop(handles_structure.audio_player)
    
else
    
    % Play audio from audioplayer object
    play(handles_structure.audio_player)
    
end

% Update the structure of handles
guidata(gcbo,handles_structure)

end


function audioplayer_startfcn(~,~)

% Retrieve the structure of handles
handles_structure = guidata(gcbo);

% Update the toggle button icon
handles_structure.playaudio_toggle.CData = stopicon;

% Update the structure of handles
guidata(gcbo,handles_structure)

end

function audioplayer_stopfcn(~,~)
        
% Retrieve the structure of handles
handles_structure = guidata(gcbo);

% Update the toggle button icon
handles_structure.playaudio_toggle.CData = playicon;

% Update the structure of handles
guidata(gcbo,handles_structure)

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

% Inverse STFT
function audio_signal = istft(audio_stft,window_function,step_length)

% Window length and number of time frames
[window_length,number_times] = size(audio_stft);

% Number of samples for the signal
number_samples = (number_times-1)*step_length+window_length;

% Initialize the signal
audio_signal = zeros(number_samples,1);

% Inverse Fourier transform of the frames and real part to
% ensure real values
audio_stft = real(ifft(audio_stft));

% Loop over the time frames
for time_index = 1:number_times
    
    % Inverse Fourier transform of the signal (normalized
    % overlap-add if proper window and step)
    sample_index = step_length*(time_index-1);
    audio_signal(1+sample_index:window_length+sample_index) ...
        = audio_signal(1+sample_index:window_length+sample_index)+audio_stft(:,time_index);
    
end

% Remove the zero-padding at the start and the end
audio_signal = audio_signal(window_length-step_length+1:number_samples-(window_length-step_length));

% Un-window the signal (just in case)
audio_signal = audio_signal/sum(window_function(1:step_length:window_length));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function repet_demo_gui

mixture_wave_axes_position = [50,430,150,50];                               % Additional gap for the bottom position
h.mixture_wave_axes = create_initial_axes( ...
    mixture_wave_axes_position);                                            % Create initial axes (see below)
mixture_spectrogram_axes_position = [50,290,150,100];                       % Left position aligned with mixture_wave_axes and additional gap to see xlabel and title
h.mixture_spectrogram_axes = create_initial_axes( ...
    mixture_spectrogram_axes_position);

% Create objects related with the beat spectrum and save their handles in h:

beatspectrum_axes_position = [50,180,150,50];                               % Left position aligned with mixture_spectrogram_axes and additional gap to separate from mixture objects
h.beatspectrum_axes = create_initial_axes( ...
    beatspectrum_axes_position);

period_slider_position = [50,120,90,20];                                    % Left position aligned withbeatspectrum_axes and additional gap to see xlabel
h.period_slider = create_initial_slider( ...
    period_slider_position,'Modify repeating period',@period_slider_callback);  % Create initial slider (see below)
period_edit_position = [150,120,50,20];                                     % Bottom position aligned with period_slider
h.period_edit = create_initial_edit( ...
    period_edit_position,'Repeating period (in s)',@period_edit_callback);  % Create initial edit (see below)

% Create objects related with the time-frequency mask and save their handles in h:

hardness_slider_position = [50,70,90,20];                                   % Additional gap to separate from beat spectrum objects
h.hardness_slider = create_initial_slider( ...
    hardness_slider_position,'Modify masking hardness',@hardness_slider_callback);
set(h.hardness_slider, ...
    'Value',1);                                                             % Initial hardness value
hardness_edit_position = [150,70,50,20];
h.hardness_edit = create_initial_edit( ...
    hardness_edit_position,'Masking hardness (in [0,1])',@hardness_edit_callback);

threshold_slider_position = [50,40,90,20];
h.threshold_slider = create_initial_slider( ...
    threshold_slider_position,'Modify masking threshold',@threshold_slider_callback);
set(h.threshold_slider, ...
    'Value',0.4);                                                           % Initial threshold value
threshold_edit_position = [150,40,50,20];
h.threshold_edit = create_initial_edit( ...
    threshold_edit_position,'Masking threshold (in [0,1])',@threshold_edit_callback);

% Create objects related with the background and save their handles in h:

save_background_pushbutton_position = [290,460,30,30];                      % Left position aligned with save_foreground_pushbutton and additional gap to separate from foreground objects
h.save_background_pushbutton = create_initial_pushbutton( ...
    save_icon,save_background_pushbutton_position,'Save background',@save_background_pushbutton_callback);
play_background_pushbutton_position = [290,420,30,30];                      % Left position aligned with save_background_pushbutton
h.play_background_pushbutton = create_initial_pushbutton( ...
    play_icon,play_background_pushbutton_position,'Play background',@play_background_pushbutton_callback);

background_wave_axes_position = [330,430,150,50];                           % Additional gap to separate from foreground objects
h.background_wave_axes = create_initial_axes( ...
    background_wave_axes_position);
background_spectrogram_axes_position = [330,290,150,100];                   % Left position aligned with background_wave_axes
h.background_spectrogram_axes = create_initial_axes( ...
    background_spectrogram_axes_position);

% Create objects related with the foreground and save their handles in h:

save_foreground_pushbutton_position = [290,210,30,30];                      % Bottom position aligned with load_mixture_pushbutton and additional gap to separate from mixture objects
h.save_foreground_pushbutton = create_initial_pushbutton( ...
    save_icon,save_foreground_pushbutton_position,'Save foreground',@save_foreground_pushbutton_callback);
play_foreground_pushbutton_position = [290,170,30,30];                      % Left position aligned with save_foreground_pushbutton
h.play_foreground_pushbutton = create_initial_pushbutton( ...
    play_icon,play_foreground_pushbutton_position,'Play foreground',@play_foreground_pushbutton_callback);

foreground_wave_axes_position = [330,180,150,50];
h.foreground_wave_axes = create_initial_axes( ...
    foreground_wave_axes_position);
foreground_spectrogram_axes_position = [330,40,150,100];                    % Left position aligned with foreground_wave_axes and bottom position aligned with mixture_spectrogram_axes
h.foreground_spectrogram_axes = create_initial_axes( ...
    foreground_spectrogram_axes_position);

% Initialize objects related with the audioplayer and save the handles in h (for figure_closerequestfcn):

h.mixture_audioplayer = [];
h.background_audioplayer = [];
h.foreground_audioplayer = [];

guidata(h.figure,h)                                                         % Save the structure of handles

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function figure_closerequestfcn(varargin)

h = guidata(gcbo);

if ~isempty(h.mixture_audioplayer)                                          % Stop any playing audioplayer before closing figure
    if isplaying(h.mixture_audioplayer)
        stop(h.mixture_audioplayer);
    end
end
if ~isempty(h.foreground_audioplayer)
    if isplaying(h.foreground_audioplayer)
        stop(h.foreground_audioplayer);
    end
end
if ~isempty(h.background_audioplayer)
    if isplaying(h.background_audioplayer)
        stop(h.background_audioplayer);
    end
end

delete(gcf)                                                                 % Delete figure

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function hslider = create_initial_slider(slider_position,slider_tooltipstring,slider_callback)

hslider = uicontrol( ...                                                    % Initially, Value = 0 and [Min,Max] = [0,1]
    'BackgroundColor','w', ...
    'Enable','off', ...
    'Position',slider_position, ...
    'Style','slider', ...
    'TooltipString',slider_tooltipstring, ...
    'Callback',slider_callback);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function hedit = create_initial_edit(edit_position,edit_tooltipstring,edit_callback)

hedit = uicontrol( ...
    'BackgroundColor','w', ...                                              % Background color white
    'Enable','off', ...
    'Position',edit_position, ...
    'Style','edit', ...
    'TooltipString',edit_tooltipstring, ...
    'Callback',edit_callback);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function select_toggletool_clickedcallback(varargin)

h = guidata(gcbo);

set(h.select_toggletool, ...
    'State','on')                                                           % No matter what the state of the clicked toggletool was, set it to 'on'
set(h.zoom_toggletool, ...
    'State','off')                                                          % Set the state of the other toggletools to 'off'
set(h.pan_toggletool, ...
    'State','off')

zoom off
pan off

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function zoom_toggletool_clickedcallback(varargin)

h = guidata(gcbo);

set(h.zoom_toggletool, ...
    'State','on')
set(h.select_toggletool, ...
    'State','off')
set(h.pan_toggletool, ...
    'State','off')

pan off
zoom on

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pan_toggletool_clickedcallback(varargin)

h = guidata(gcbo);

set(h.pan_toggletool, ...
    'State','on')
set(h.select_toggletool, ...
    'State','off')
set(h.zoom_toggletool, ...
    'State','off')

zoom off
pan on

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function load_mixture_pushbutton_callback(varargin)

disable_enable_figure                                                       % Disable content area of figure while loading

h = guidata(gcbo);                                                          % Get the structure of handles from the handle of object whose callback is executing

% Stop any playing audioplayer before trying to load:

if ~isempty(h.mixture_audioplayer)
    if isplaying(h.mixture_audioplayer)
        stop(h.mixture_audioplayer);
    end
end
if ~isempty(h.background_audioplayer)
    if isplaying(h.background_audioplayer)
        stop(h.background_audioplayer);
    end
end
if ~isempty(h.foreground_audioplayer)
    if isplaying(h.foreground_audioplayer)
        stop(h.foreground_audioplayer);
    end
end

% Load mixture:

[filename,filepath] = uigetfile( ...                                        % Open file dialog box in the current directory
    {'*.wav', 'WAVE files (*.wav)'; ...
    '*.*',  'All Files (*.*)'}, ...
    'Select a WAVE file');
if isequal(filename,0)                                                      % Return if 'cancel'
    disable_enable_figure
    return
end

[~,filename,fileext] = fileparts(filename);                                 % File name (without path and extension) and file extension
if ~strcmp(fileext,'.wav')                                                  % Return if extension unknown
    disable_enable_figure
    return
end

file = fullfile(filepath,[filename,fileext]);                               % File with path and extension
[x,fs] = audioread(file);
h.mixture_audio = x;                                                        % Mixture audio (fs will be automatically saved in audioplayer)
h.mixture_audioplayer = audioplayer(x,fs);                                  % Mixture audioplayer

if length(filename) > 20                                                    % Shorten file name if more than 20 characters
    filename = [filename(1:20),'~'];
end
h.mixture_name = filename;                                                  % Mixture name

% Plot mixture:

L = length(x);                                                              % Length in samples
axes(h.mixture_wave_axes); %#ok<*MAXES>
plot((1:L)/fs,x);                                                           % Plot in seconds
set(h.mixture_wave_axes, ...
    'XGrid','on', ...
    'XLim',[1,L]/fs, ...
    'YLim',[-1,1], ...
    'YTickLabel',[])
title(filename,'Interpreter','none')                                        % No interpreter to avoid underscore = subscript
xlabel('time (s)')
setAxesZoomMotion(zoom,h.mixture_wave_axes,'horizontal');                   % Constrained horizontal zoom

h.selection_indices = [1,L];                                                % Initial selection indices in samples (to check if modified later)
lim = axis(h.mixture_wave_axes);                                            % Axis' limits [xmin xmax ymin ymax]
drag_select(h.mixture_wave_axes,lim)                                        % To have interactive selection boundaries on the axes (see below)

play_audio(h.mixture_audioplayer,h.play_mixture_pushbutton,h.mixture_wave_axes,1)   % To have interactive play button and playing line on the axes (see below)

% Reset the rest of the objects, if not already reset:

zoom off
pan off
set(h.select_toggletool, ...
    'Enable','on', ...
    'State','on')
set(h.zoom_toggletool, ...
    'Enable','on', ...
    'State','off')
set(h.pan_toggletool, ...
    'Enable','on', ...
    'State','off')

set(h.play_mixture_pushbutton, ...
    'Enable','on')
set(h.repet_mixture_pushbutton, ...
    'Enable','on')
h.period_value = 0;                                                         % Initialize period value (to check if modified later)

c = get(h.mixture_spectrogram_axes,'Children');                             % Plot within axes
if ~isempty(c)
    
    % Unlink wave and spectrogram axes:
    
    removetarget(h.link_axes, ...                                           % Simply clearing the handle does not work!
        [h.mixture_wave_axes, ...
        h.mixture_spectrogram_axes, ...
        h.background_wave_axes, ...
        h.background_spectrogram_axes, ...
        h.foreground_wave_axes, ...
        h.foreground_spectrogram_axes]);
    removetarget(h.link_spectrogram_axes, ...
        [h.mixture_spectrogram_axes, ...
        h.background_spectrogram_axes, ...
        h.foreground_spectrogram_axes]);
    
    % Reset mixture spectrogram and beat spectrum:
    
    figure_color = get(h.figure,'Color');
    cla(h.mixture_spectrogram_axes,'reset')                                 % Deletes all graphics objects and resets all axes properties, except Position and Units (no need to zoom reset)
    set(h.mixture_spectrogram_axes, ...
        'Color',figure_color, ...
        'Box','on', ...
        'XTick',[], ...
        'YTick',[])
    cla(h.beatspectrum_axes,'reset')
    set(h.beatspectrum_axes, ...
        'Color',figure_color, ...
        'Box','on', ...
        'XTick',[], ...
        'YTick',[])
    
    % Reset sliders and edits:
    
    set(h.period_slider, ...                                                % No need to reset period value, it will be re-estimated
        'Enable','off');
    set(h.period_edit, ...                                                  % Clear edit string or it would still show
        'Enable','off', ...
        'String','')
    set(h.hardness_slider, ...                                              % No need to reset hardness value, it will stay as chosen
        'Enable','off')
    set(h.hardness_edit, ...
        'Enable','off', ...
        'String','')
    set(h.threshold_slider, ...                                             % No need to reset threshold value, it will stay as chosen
        'Enable','off')
    set(h.threshold_edit, ...
        'Enable','off', ...
        'String','')
    
    % Reset background:
    
    set(h.save_background_pushbutton, ...
        'Enable','off')
    set(h.play_background_pushbutton, ...
        'Enable','off')
    cla(h.background_wave_axes,'reset')
    set(h.background_wave_axes, ...
        'Color',figure_color, ...
        'Box','on', ...
        'XTick',[], ...
        'YTick',[])
    cla(h.background_spectrogram_axes,'reset')
    set(h.background_spectrogram_axes, ...
        'Color',figure_color, ...
        'Box','on', ...
        'XTick',[], ...
        'YTick',[])
    
    % Reset foreground:
    
    set(h.save_foreground_pushbutton, ...
        'Enable','off')
    set(h.play_foreground_pushbutton, ...
        'Enable','off')
    cla(h.foreground_wave_axes,'reset')
    set(h.foreground_wave_axes, ...
        'Color',figure_color, ...
        'Box','on', ...
        'XTick',[], ...
        'YTick',[])
    cla(h.foreground_spectrogram_axes,'reset')
    set(h.foreground_spectrogram_axes, ...
        'Color',figure_color, ...
        'Box','on', ...
        'XTick',[], ...
        'YTick',[])
    
end

guidata(gcbo,h)                                                             % Save the changes to the structure of handles

disable_enable_figure                                                       % Reenable content area of figure once loaded

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function play_mixture_pushbutton_callback(varargin)

h = guidata(gcbo);

if ~isplaying(h.mixture_audioplayer)
    ind = get(h.mixture_wave_axes,'UserData');                              % Get selection indices in seconds from axes' userdata
    fs = get(h.mixture_audioplayer,'SampleRate');                           % Get sampling frequency in Hz from audioplayer
    ind = round(ind*fs);                                                    % Selection indices in samples
    if isempty(ind)                                                         % If no selection
        L = get(h.mixture_audioplayer,'TotalSamples');                      % Get total number of samples from audioplayer
        ind = [1,L];                                                        % Play from beginning to end
    else
        if ind(1) == ind(2)                                                 % If same indices
            xlim = get(h.mixture_wave_axes,'XLim');
            L = get(h.mixture_audioplayer,'TotalSamples');
            if ind(1) == xlim(2)                                            % If same indices at the very end
                ind = [1,L];                                                % Play from beginning to end
            else
                ind = [ind(1),L];                                           % If same indices not at the very end, play from index to end
            end
        else
            ind = sort(ind);                                                % If not the same indices, sort the indices
        end
    end
    play(h.mixture_audioplayer,ind);                                        % Play selection in samples
else
    stop(h.mixture_audioplayer);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function repet_mixture_pushbutton_callback(varargin)

disable_enable_figure

h = guidata(gcbo);

% Mixture selection indices:

ind = get(h.mixture_wave_axes,'UserData');                                  % Get selection indices in seconds from axes' userdata
x = h.mixture_audio;                                                        % Full mixture audio
L = length(x);                                                              % Full length
fs = get(h.mixture_audioplayer,'SampleRate');

if isempty(ind) || ind(1) == ind(2)                                         % If no selection or same indices
    ind = [1,L];                                                            % Selection from beginning to end in samples
else
    ind = sort(round(ind*fs));                                              % Indices in samples (sorted)
end

% Compute/display spectrogram, beat spectrum, and period:

c = get(h.mixture_spectrogram_axes,'Children');                             % Plot within axes
per = get(h.period_slider,'Value');                                         % Period in seconds
if isempty(c) || (~isempty(c) && ~all(ind == h.selection_indices))          % If no spectrogram, or spectrogram but selection indices have been modified
    
    % Compute spectrograms of mixture selection:
    
    k = size(x,2);                                                          % Number of channels
    x = x(ind(1):ind(2),:);                                                 % Mixture selection
    
    N = 2^nextpow2(fs*0.04);                                                % Analysis length (power of 2 for faster fft) (music stationary around 40 ms)
    win = hamming(N,'periodic');                                            % Analysis window (periodic Hamming window for constant overlap-add)
    stp = N/2;                                                              % Analysis step (length(win)/2 for constant overlap-add)
    
    X = [];
    for i = 1:k                                                             % Loop over the channels
        xi = x(:,i);
        Xi = stft(xi,win,stp);                                              % STFT of channel i (see below)
        X = cat(3,X,Xi);
    end
    h.mixture_stft = X;                                                     % Save mixture selection STFTs
    
    % Plot spectrogram of mixture selection:
    
    m = size(X,2);                                                          % Number of time frames
    n = N/2+1;                                                              % Number of frequency bins (including DC component)
    h.time = (ind(1):(ind(2)-ind(1))/(m-1):ind(2))/fs;                      % Time vector in seconds of length m time frames for the spectrogram
    h.freq = (1:n-1)*(fs/N)*1e-3;                                           % Frequency vector in kHz of length n-1 frequency bins for the spectrogram (not including DC component)
    S = 20*log10(abs(mean(X(2:N/2+1,:,:),3)));                              % Spectrogram without DC component in dB averaged over the channels (for mixture_spectrogram_axes)
    h.clim = [min(S(:)),max(S(:))];                                         % Linking CLim between spectrograms is not immediate
    
    axes(h.mixture_wave_axes)
    xlabel('')                                                              % Clear mixture wave axes xlabel to save space for mixture spectrogram axes title
    axes(h.mixture_spectrogram_axes);
    imagesc(h.time,h.freq,S)
    set(h.mixture_spectrogram_axes, ...
        'XLim',[1,L]/fs, ...
        'XGrid','on', ...
        'YDir','normal', ...
        'YLim',[h.freq(1),h.freq(n-1)])
    title('Spectrogram (dB)');
    xlabel('time (s)');
    ylabel('frequency (kHz)');
    h.axis = axis;
    
    spectrogram_colorbar_position = [210,290,20,100];                       % Bottom position aligned with mixture_spectrogram_axes
    colorbar('Peer',h.mixture_spectrogram_axes, ...                         % Creates a colorbar associated with mixture_spectrogram_axes
        'Units','pixels', ...                                               % Set units before position!
        'Position',spectrogram_colorbar_position)
    
    % Compute and plot beat spectrum:
    
    V = abs(X(1:end/2+1,:,:));                                              % Magnitude spectrograms (including DC component)
    b = beat_spectrum(mean(V.^2,3));                                        % Beat spectrum of the mean power spectrograms
    b = b/b(1);                                                             % Normalization by the first term (lag 0)
    h.tlag = (1:(ind(2)-ind(1))/(m-1):(ind(2)-ind(1)))/fs;                  % Lag vector in seconds for the beat spectrum (not including lag 0)
    
    axes(h.beatspectrum_axes);
    plot(h.tlag,b(2:m),'k');                                                % Beat spectrum (not including lag 0) (black color)
    set(h.beatspectrum_axes, ...
        'XLim',[h.tlag(1),h.tlag(m-1)], ...                                 % length(tlag) = m-1
        'YLim',[0,1])
    title('Beat spectrum')
    xlabel('lag (s)')
    setAxesZoomMotion(zoom,h.beatspectrum_axes,'horizontal');               % Constrained horizontal zoom
    
    % Compute and display period:
    
    per = repeating_period(b);                                              % Estimated period in time frames
    drag_beat(h.beatspectrum_axes,h.period_slider,h.period_edit,h.tlag,per)    % To have interactive period selection (with integer multiples) on the axes (see below)
    
    m2 = floor((m-1)/2);                                                    % Range of the period candidates (length(tlag) = m-1)
    set(h.period_slider, ...
        'Enable','on', ...
        'Min',h.tlag(1), ...                                                % Min value in seconds
        'Max',h.tlag(m2), ...                                               % Max value in seconds
        'SliderStep',[1,10]/(m2-1), ...                                     % Minor (when click arrow) and major (when click slider) slider step (1 sample and 10 samples in seconds)
        'Value',h.tlag(per))                                                % Value in seconds
    set(h.period_edit, ...
        'Enable','on', ...
        'String',num2str(h.tlag(per),'%.4f'))                               % Value in seconds with a precision of 4 digits    
    h.period_value = h.tlag(per);                                           % Save period value in seconds
    
elseif per ~= h.period_value                                                % If spectrogram and same selection indices, but period has been modified
    
    h.period_value = per;                                                   % Save period value in seconds
    [~,per] = min(abs(h.tlag-per));                                         % Closest period index in time frames
    
    X = h.mixture_stft;                                                     % Need to compute parameters because computed only in the previous statement
    V = abs(X(1:end/2+1,:,:));
    [N,m,k] = size(X);
    n = N/2+1;                                                              % Need to compute parameters for the next if statement
    
else                                                                        % If spectrogram and same selection indices, and same period, return
    
    disable_enable_figure
    return
    
end

% Compute mask and estimates:

if isempty(c) || (~isempty(c) && ~all(ind == h.selection_indices)) || ...   % If no spectrogram or spectrogram but selection indices have been modified, or period has been modified
        per ~= h.period_value
    
    h.selection_indices = ind;
    
    % Compute mask:
    
    M = zeros(n,m,k);
    for i = 1:k                                                             % Loop over the channels
        M(:,:,i) = repeating_mask(V(:,:,i),per);                            % Repeating mask obtain using the REPET algorithm
    end
    h.repeating_mask = M;                                                   % Save masks
    
    % Enable sliders/edits:
    
    set(h.hardness_slider, ...
        'Enable','on');
    har = get(h.hardness_slider,'Value');
    set(h.hardness_edit, ...
        'Enable','on', ...
        'String',num2str(har,'%.2f'));

    set(h.threshold_slider,'Enable','on');
    thr = get(h.threshold_slider,'Value');
    set(h.threshold_edit, ...
        'Enable','on', ...
        'String',num2str(thr,'%.2f'));
    
    % Compute mask and estimates:
    
    h = estimates(h);
    
    % Link wave and spectrogram axes:
    
    h.link_axes = linkprop([ ...
        h.mixture_wave_axes, ...
        h.mixture_spectrogram_axes, ...
        h.background_wave_axes, ...
        h.background_spectrogram_axes, ...
        h.foreground_wave_axes, ...
        h.foreground_spectrogram_axes], ...
        'Xlim');
    h.link_spectrogram_axes = linkprop([ ...
        h.mixture_spectrogram_axes, ...
        h.foreground_spectrogram_axes, ...
        h.background_spectrogram_axes], ...
        {'Xlim','Ylim'});                                                   % Do not link CLim because it is not direct, use handles instead
    
    disable_enable_figure
    guidata(gcbo,h)
    
else                                                                        % If spectrogram and same selection indices, and same period, return
    
    disable_enable_figure
    return
    
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function period_slider_callback(varargin)

h = guidata(gcbo);

per = get(h.period_slider,'Value');                                         % Period in seconds
[~,per] = min(abs(h.tlag-per));                                             % Closest period index in time frames
beat = findobj(h.beatspectrum_axes,'Color','r');                            % Beat lines are red objects in the beat spectrum axes'
delete(beat)
plot_beat(h.beatspectrum_axes,h.period_slider,h.period_edit,h.tlag,per)     % Update beat lines (period_edit is updated via plot_beat)

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function period_edit_callback(varargin)

h = guidata(gcbo);

per = get(h.period_edit,'String');                                          % Period in seconds (string)
per = str2double(per);                                                      % Period in seconds (NaN if not string of a number)
if isnan(per)                                                               % If not a number, reset edit from slider and return
    per = get(h.period_slider,'Value');
    set(h.period_edit, ...
        'String',num2str(per,'%.4f'));
    return
end

m = length(h.tlag);                                                         % Number of lags (not including lag 0)
m2 = floor(m/2);                                                            % Range of the period candidates
if per < h.tlag(1)                                                          % If period out of range, force it to the extreme values
    per = h.tlag(1);
elseif per > h.tlag(m2)
    per = h.tlag(m2);
end

[~,per] = min(abs(h.tlag-per));
beat = findobj(h.beatspectrum_axes,'Color','r');
delete(beat)
plot_beat(h.beatspectrum_axes,h.period_slider,h.period_edit,h.tlag,per)     % Update beat lines (period_slider is updated via plot_beat)

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function hardness_slider_callback(varargin)

h = guidata(gcbo);

har = get(h.hardness_slider,'Value');
set(h.hardness_edit, ...
    'String',num2str(har,'%.2f'))

h = estimates(h);

guidata(gcbo,h)

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function hardness_edit_callback(varargin)

h = guidata(gcbo);

har = get(h.hardness_edit,'String');
har = str2double(har);
if isnan(har)
    har = get(h.hardness_slider,'Value');
    set(h.hardness_edit, ...
        'String',num2str(har,'%.2f'));
    return
end

if har < 0
    har = 0;
elseif har > 1
    har = 1;
end

set(h.hardness_edit, ...
    'String',num2str(har,'%.2f'));
set(h.hardness_slider, ...
    'Value',har);

h = estimates(h);

guidata(gcbo,h)

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function threshold_slider_callback(varargin)

h = guidata(gcbo);

thr = get(h.threshold_slider,'Value');
set(h.threshold_edit, ...
    'String',num2str(thr,'%.2f'))

h = estimates(h);

guidata(gcbo,h)

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function threshold_edit_callback(varargin)

h = guidata(gcbo);

thr = get(h.threshold_edit,'String');
thr = str2double(thr);
if isnan(thr)
    thr = get(h.threshold_slider,'Value');
    set(h.threshold_edit, ...
        'String',num2str(thr,'%.2f'));
    return
end

if thr < 0
    thr = 0;
elseif thr > 1
    thr = 1;
end

set(h.threshold_edit, ...
    'String',num2str(thr,'%.2f'))
set(h.threshold_slider, ...
    'Value',thr)

h = estimates(h);

guidata(gcbo,h)

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function h = estimates(h)

% Stop any playing foreground and background audioplayer first:

if ~isempty(h.foreground_audioplayer)
    if isplaying(h.foreground_audioplayer)
        stop(h.foreground_audioplayer);
    end
end
if ~isempty(h.background_audioplayer)
    if isplaying(h.background_audioplayer)
        stop(h.background_audioplayer);
    end
end

% Modify repeating mask and compute repeating audio:

M = h.repeating_mask;
har = get(h.hardness_slider,'Value');
thr = get(h.threshold_slider,'Value');

X = h.mixture_stft;
[N,m,k] = size(X);
win = hamming(N,'periodic');
stp = N/2;
n = N/2+1;

x = h.mixture_audio;
L = length(x);
ind = h.selection_indices;
x = x(ind(1):ind(2),:);                                                     % Mixture selection
l = length(x);                                                              % Length of the selection in samples

Y = zeros(N,m,k);
y = zeros(l,k);
for i = 1:k                                                                 % Loop over the channels
    Mi = masking_sigmoid(M(:,:,i),har,thr);                                 % Modify the masks via a special sigmoid function (see below)
    Mi = cat(1,Mi,flipud(Mi(2:end-1,:)));                                   % Symmetrize the mask
    Y(:,:,i) = Mi.*X(:,:,i);                                                % Estimated repeating background STFT
    yi = istft(Y(:,:,i),win,stp);                                           % Estimated repeating background audio
    y(:,i) = yi(1:l);                                                       % Truncate to the original length of the mixture selection
end
h.repeating_audio = y;                                                      % Save the repeating audio

fs = get(h.mixture_audioplayer,'SampleRate');

% Plot background wave and spectrogram, and enable audio:

axes(h.background_wave_axes);
plot((ind(1):ind(2))/fs,y);
set(h.background_wave_axes, ...
    'XGrid','on', ...
    'XLim',[1,L]/fs, ...
    'YLim',[-1,1], ...
    'YTickLabel',[])
title('Repeating Background')
ylim = get(h.mixture_wave_axes,'YLim');
lim = [ind/fs,ylim];                                                        % Axis' selection limits
drag_select(h.background_wave_axes,lim)
setAxesZoomMotion(zoom,h.background_wave_axes,'horizontal')

S2 = 20*log10(abs(mean(Y(2:N/2+1,:,:),3)));
axes(h.background_spectrogram_axes);
imagesc(h.time,h.freq,S2,h.clim)
set(h.background_spectrogram_axes, ...
    'XLim',[1,L]/fs, ...
    'XGrid','on', ...
    'YDir','normal', ...
    'YLim',[h.freq(1),h.freq(n-1)])
title('Spectrogram (dB)');
xlabel('time (s)');
ylabel('frequency (kHz)');

h.background_audioplayer = audioplayer(y,fs);
play_audio(h.background_audioplayer,h.play_background_pushbutton,h.background_wave_axes,ind(1))
set(h.save_background_pushbutton, ...
    'Enable','on')
set(h.play_background_pushbutton, ...
    'Enable','on')

% Plot foreground wave and spectrogram, and enable audio:

axes(h.foreground_wave_axes)
plot((ind(1):ind(2))/fs,x-y)
set(h.foreground_wave_axes, ...
    'XGrid','on', ...
    'XLim',[1,L]/fs, ...
    'YLim',[-1,1], ...
    'YTickLabel',[])
title('Non-repeating Foreground')
setAxesZoomMotion(zoom,h.foreground_wave_axes,'horizontal');
drag_select(h.foreground_wave_axes,lim)

S1 = 20*log10(abs(mean(X(2:N/2+1,:,:)-Y(2:N/2+1,:,:),3)));
axes(h.foreground_spectrogram_axes)
imagesc(h.time,h.freq,S1,h.clim)
set(h.foreground_spectrogram_axes, ...
    'XLim',[1,L]/fs, ...
    'XGrid','on', ...
    'YDir','normal', ...
    'YLim',[h.freq(1),h.freq(n-1)])
title('Spectrogram (dB)');
xlabel('time (s)');
ylabel('frequency (kHz)');

h.foreground_audioplayer = audioplayer(x-y,fs);
play_audio(h.foreground_audioplayer,h.play_foreground_pushbutton,h.foreground_wave_axes,ind(1))
set(h.save_foreground_pushbutton, ...
    'Enable','on')
set(h.play_foreground_pushbutton, ...
    'Enable','on')

% Link wave and spectrogram axes:
    
    h.link_axes = linkprop([ ...
        h.mixture_wave_axes, ...
        h.mixture_spectrogram_axes, ...
        h.background_wave_axes, ...
        h.background_spectrogram_axes, ...
        h.foreground_wave_axes, ...
        h.foreground_spectrogram_axes], ...
        'Xlim');
    h.link_spectrogram_axes = linkprop([ ...
        h.mixture_spectrogram_axes, ...
        h.background_spectrogram_axes, ...
        h.foreground_spectrogram_axes], ...
        {'Xlim','Ylim'});                                                   % Do not link CLim because it is not direct, use handles instead

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function save_background_pushbutton_callback(varargin)

disable_enable_figure

h = guidata(gcbo);

filename = [h.mixture_name,'_background'];                                  % By default, save as _background.wav
[filename,filepath] = uiputfile( ...
    {'*.wav','WAVE files (*.wav)'}, ...
    'Save as WAVE file', ...
    filename);
if isequal(filename,0)
    disable_enable_figure
    return
end

y = h.repeating_audio;
fs = get(h.mixture_audioplayer,'SampleRate');
file = fullfile(filepath,filename);
audiowrite(file,y,fs);

disable_enable_figure

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function play_background_pushbutton_callback(varargin)

h = guidata(gcbo);

if ~isplaying(h.background_audioplayer)
    ind = get(h.background_wave_axes,'UserData');
    fs = get(h.background_audioplayer,'SampleRate');
    ind = round(ind*fs);
    xlim = h.selection_indices;
    if isempty(ind)
        ind = xlim;
    else
        if ind(1) == ind(2)
            ind = [ind(1),xlim(2)];
        else
            ind = sort(ind);
        end
    end
    play(h.background_audioplayer,ind-xlim(1)+1);
else
    stop(h.background_audioplayer);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function save_foreground_pushbutton_callback(varargin)

disable_enable_figure

h = guidata(gcbo);

filename = [h.mixture_name,'_foreground'];                                  % By default, save as _foreground.wav
[filename,filepath] = uiputfile( ...                                        % Save file dialog box in the current directory
    {'*.wav','WAVE files (*.wav)'}, ...
    'Save as WAVE file', ...
    filename);
if isequal(filename,0)
    disable_enable_figure
    return
end

ind = h.selection_indices;
x = h.mixture_audio;
x = x(ind(1):ind(2),:);
y = h.repeating_audio;
fs = get(h.mixture_audioplayer,'SampleRate');
file = fullfile(filepath,filename);                                         % File with path and extension
audiowrite(file,x-y,fs);

disable_enable_figure

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function play_foreground_pushbutton_callback(varargin)

h = guidata(gcbo);

if ~isplaying(h.foreground_audioplayer)
    ind = get(h.foreground_wave_axes,'UserData');
    fs = get(h.foreground_audioplayer,'SampleRate');
    ind = round(ind*fs);
    xlim = h.selection_indices;
    if isempty(ind)
        ind = xlim;
    else
        if ind(1) == ind(2)
            ind = [ind(1),xlim(2)];
        else
            ind = sort(ind);
        end
    end
    play(h.foreground_audioplayer,ind-xlim(1)+1);
else
    stop(h.foreground_audioplayer);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function drag_select(haxes,lim)

col = [192,192,192]/255;                                                    % Color of the patch and the lines when full patch (Grey, Silver RGB)
col1 = [84,84,84]/255;                                                      % Color of line 1 when just one line (Dim Grey RGB)

l1 = [];                                                                    % Initalize line 1
p = [];                                                                     % Initalize patch
l2 = [];                                                                    % Initalize line 2

set(haxes, ...
    'ButtonDownFcn',@ClickAxesFcn)                                          % Execute ClickAxesFcn when axes is clicked (nested function)
f = get(haxes,'Parent');                                                    % Axes' parent = containing figure
c = get(haxes,'Children');                                                  % Axes' children = contained plot
set(c, ...
    'HitTest','off')                                                        % Make children not clickable for axes below to be clickable

    function ClickAxesFcn(varargin)
        
        cp = get(haxes,'CurrentPoint');                                     % Coordinates of the mouse click whithin the axes
        if cp(1,1) < lim(1) || cp(1,1) > lim(2) ...                         % Return if mouse click not within the axes' box
                || cp(1,2) < lim(3) || cp(1,2) > lim(4)
            return
        end
        
        cl = get(f,'SelectionType');                                        % Selection type of the mouse click
        if strcmp(cl,'normal')                                              % Update lines and patch if left click (see below)
        elseif strcmp(cl,'alt')                                             % Execute DeleteFcn if right click (nested function)
            DeleteFcn
            return
        else                                                                % Return if another type of click
            return
        end
        
        delete(l1);
        delete(p);
        delete(l2);
        
        l1_x = cp(1,1)*ones(1,2);                                           % x-coordinates for line 1
        l1 = line(l1_x,lim(3:4), ...                                        % Line 1 (by default on the top of axes, above the plot)
            'ButtonDownFcn',@ClickLine1Fcn, ...                             % Execute ClickLine1Fcn when line 1 is clicked  (nested function)
            'Color',col1, ...                                               % Different color for line 1 when just one line
            'LineWidth',1);
        
        p_x = cp(1,1)*ones(1,4);                                            % x-coordinates for patch
        p_y = [lim(3),lim(4),lim(4),lim(3)];                                % y-coordinates for patch
        p = patch(p_x,p_y,'w',...                                           % Patch (originally white) (by default at the bottom of axes, under the plot because of zbuffer)
            'FaceColor',col, ...                                            % Patch color
            'EdgeColor','none', ...                                         % No patch edges
            'HitTest','off', ...                                            % Make patch not clickable for axes below to be clickable
            'LineWidth',1);
        
        l2_x = cp(1,1)*ones(1,2);                                           % x-coordinates for line 2
        l2 = line(l2_x,lim(3:4), ...                                        % Line 2 (by default on the top of axes, above the plot)
            'ButtonDownFcn',@ClickLine2Fcn, ...                             % Execute ClickLine2Fcn when line 2 is clicked (nested function)
            'Color',col, ...                                                % Line 2 color (same as patch)
            'LineWidth',1);
        uistack(l2,'bottom')                                                % Stack line 2 at the bottom of axes, under the plot and line 1
        
        set(f, ...
            'WindowButtonMotionFcn',@DragLine2Fcn, ...                      % Execute DragLine2Fcn when mouse moves over the figure (nested function)
            'WindowButtonUpFcn',@ReleaseFcn)                                % Execute ReleaseFcn when mouse button is released from the figure (nested function)
        
        function ClickLine1Fcn(varargin)
            
            cl = get(f,'SelectionType');
            if strcmp(cl,'normal')                                          % If left click
                set(f, ...
                    'WindowButtonMotionFcn',@DragLine1Fcn, ...              % Execute DragLine1Fcn when mouse moves over the figure
                    'WindowButtonUpFcn',@ReleaseFcn)                        % Execute ReleaseFcn when mouse button is released from the figure
            elseif strcmp(cl,'alt')
                DeleteFcn
            else
                return
            end
            
        end
        
        function ClickLine2Fcn(varargin)
            
            cl = get(f,'SelectionType');
            if strcmp(cl,'normal')                                          % If left click
                set(f, ...
                    'WindowButtonMotionFcn',@DragLine2Fcn, ...              % Execute DragLine2Fcn when mouse moves over the figure
                    'WindowButtonUpFcn',@ReleaseFcn)                        % Execute ReleaseFcn when mouse button is released from the figure
            elseif strcmp(cl,'alt')
                DeleteFcn
            else
                return
            end
            
        end
        
        function DragLine1Fcn(varargin)
            
            cp = get(haxes,'CurrentPoint');
            if cp(1,1) < lim(1)                                             % Force line 1 to stay inside axes' box
                cp(1,1) = lim(1);
            elseif cp(1,1) > lim(2)
                cp(1,1) = lim(2);
            end
            
            l1_x = cp(1,1)*ones(1,2);
            set(l1, ...                                                     % Update line 1
                'XData',l1_x)
            p_x = [cp(1,1)*ones(1,2),p_x(3:4)];
            set(p, ...                                                      % Update patch
                'XData',p_x)
            
            if l1_x(1) == l2_x(1)                                           % When just one line
                set(l1, ...
                    'Color',col1)                                          % Line 1 takes a different color
                uistack(l1,'top')                                           % Line 1 goes on the top of axes, above the plot, hiding line 2 and patch (which is invisible since its has no edges)
            else                                                            % When full patch
                set(l1, ...
                    'Color',col)                                            % Line 1 takes the same color as line 2 and patch
                uistack(l1,'bottom')                                        % Line 1 goes at the bottom of axes, under the plot, just like line 2 and patch (which are now showing)
            end
            
        end
        
        function DragLine2Fcn(varargin)
            
            cp = get(haxes,'CurrentPoint');
            if cp(1,1) < lim(1)                                             % Force line 2 to stay inside axes' box
                cp(1,1) = lim(1);
            elseif cp(1,1) > lim(2)
                cp(1,1) = lim(2);
            end
            
            l2_x = cp(1,1)*ones(1,2);
            set(l2, ...                                                     % Update line 2
                'XData',l2_x)
            p_x = [p_x(1:2),cp(1,1)*ones(1,2)];
            set(p, ...                                                      % Update patch
                'XData',p_x)
            
            if l1_x(1) == l2_x(1)                                           % When just one line
                set(l1, ...
                    'Color',col1)                                           % Line 1 takes a different color
                uistack(l1,'top')                                           % Line 1 goes on the top of axes, above the plot, hiding line 2 and patch (which is invisible since its has no edges)
            else                                                            % When full patch
                set(l1, ...
                    'Color',col)                                            % Line 1 takes the same color as line 2 and patch
                uistack(l1,'bottom')                                        % Line 1 goes at the bottom of axes, under the plot, just like line 2 and patch (which are now showing)
            end
            
        end
        
        function ReleaseFcn(varargin)
            
            set(f, ...
                'WindowButtonMotionFcn','', ...                             % Reset the WindowButtonMotionFcn callback of the figure
                'WindowButtonUpFcn','')                                     % Reset the WindowButtonUpFcn callback of the figure
            
            if isempty(p)                                                   % If lines and patch have been deleted
                ind = [];                                                   % Reinitialize selection indices
            else                                                            % Else, get x-coordinates of lines
                l1_x = get(l1,'XData');
                l2_x = get(l2,'XData');
                ind = [l1_x(1),l2_x(1)];
            end
            
            set(haxes, ...
                'UserData',ind)                                             % Save selection indices in the axes' userdata
        end
        
        function DeleteFcn
            
            delete(l1)
            delete(p)
            delete(l2)
            
            l1 = [];                                                        % Reinitalize line 1
            p = [];                                                         % Reinitalize patch
            l2 = [];                                                        % Reinitalize line 2
            
            set(f, ...
                'WindowButtonUpFcn',@ReleaseFcn)                            % Execute ReleaseFcn when mouse button is released from the figure (nested function)
            
        end
        
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function play_audio(haudioplayer,hpushbutton,haxes,j)

l = [];                                                                     % Initialize line
i0 = get(haudioplayer,'CurrentSample');                                     % Initial current sample
fs = get(haudioplayer,'SampleRate');                                        % Sampling frequency in Hz
c = [47,79,79]/255;                                                         % Dark Slate Grey RGB

set(haudioplayer, ...
    'StartFcn',@haudioplayer_startfcn, ...                                  % Call haudioplayer_startfcn when the audioplayer starts (no need for further inputs since nested)
    'StopFcn',@haudioplayer_stopfcn, ...                                    % Call haudioplayer_stopfcn when the audioplayer stops
    'TimerFcn',@haudioplayer_timerfcn)                                      % Call haudioplayer_timerfcn while the audioplayer is playing

    function haudioplayer_startfcn(varargin)                                % No need for inputs since nested (the data are shared between functions)
        
        set(hpushbutton, ...
            'CData',stop_icon)                                              % The play icon becomes a stop icon
        i = get(haudioplayer,'CurrentSample');                              % Current sample in samples
        axes(haxes)
        l = line([1,1]*(i+j-1)/fs,[-1,1], ...                               % Initialize line in axes
            'Color',c, ...                                                  % Line color
            'HitTest','off', ...                                            % Make the line not clickable
            'LineWidth',1);
        
    end

    function haudioplayer_stopfcn(varargin)
        
        set(hpushbutton, ...
            'CData',play_icon)                                              % The stop icon becomes a play icon
        delete(l)                                                           % Delete line from axes
        
    end

    function haudioplayer_timerfcn(varargin)
        
        i = get(haudioplayer,'CurrentSample');
        if i > i0                                                           % To make sure the current sample is larger than the initial current sample (there could be errors)
            set(l,'XData',[1,1]*(i+j-1)/fs)                                 % Update line in the axes
        end
        
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function drag_beat(haxes,hslider,hedit,tlag,per)

c = get(haxes,'Children');                                                  % The axes' children are the contained plots
set(c, ...
    'HitTest','off')                                                        % Make children not clickable for axes below to be clickable

plot_beat(haxes,hslider,hedit,tlag,per)                                     % Initialize beat lines
set(haxes, ...
    'ButtonDownFcn',@ClickAxesFcn)                                          % Execute ClickAxesFcn when axes is clicked (nested function)

xlim = get(haxes,'XLim');
ylim = get(haxes,'YLim');
m = length(tlag);                                                           % Number of lags (not including lag 0)
xlim(2) = tlag(floor(m/2));                                                 % Maximal possible lag for the period in seconds

f = get(haxes,'Parent');                                                    % The axes' parent is the containing figure

    function ClickAxesFcn(varargin)
        
        cl = get(f,'SelectionType');                                        % Type of click
        cp = get(haxes,'CurrentPoint');                                     % Coordinates of click
        if ~strcmp(cl,'normal') || ...
                cp(1,1) < xlim(1) || cp(1,1) > xlim(2) ...
                || cp(1,2) < ylim(1) || cp(1,2) > ylim(2)
            return                                                          % Return if not left click or not within the limits
        end
        
        beat = findobj(haxes,'Color','r');                                  % Beat lines are red objects (saving in userdata can still lead to errors)
        delete(beat)
        [~,per] = min(abs(tlag-cp(1)));                                     % Closest period index in time frames
        plot_beat(haxes,hslider,hedit,tlag,per)                             % Update beat lines (but not slider and edit)
        
        set(f, ...
            'WindowButtonMotionFcn',@DragLineFcn, ...                       % Execute DragLineFcn when mouse moves over the figure (nested function)
            'WindowButtonUpFcn',@ReleaseFcn)                                % Execute ReleaseFcn when mouse button is released from the figure (nested function)
        
    end
    
    function DragLineFcn(varargin)
        
        cp = get(haxes,'CurrentPoint');
        if cp(1,1) < xlim(1)                                                % Force line to stay within the period range
            cp(1,1) = xlim(1);
        elseif cp(1,1) > xlim(2)
            cp(1,1) = xlim(2);
        end
        
        beat = findobj(haxes,'Color','r');
        delete(beat)
        [~,per] = min(abs(tlag-cp(1)));
        plot_beat(haxes,hslider,hedit,tlag,per)
        
    end
    
    function ReleaseFcn(varargin)
        
        set(f, ...
            'WindowButtonMotionFcn','', ...                                 % Reset the WindowButtonMotionFcn callback of the figure
            'WindowButtonUpFcn','')                                         % Reset the WindowButtonUpFcn callback of the figure
        
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function plot_beat(haxes,hslider,hedit,tlag,per)

m = length(tlag);                                                           % Number of lags (not including lag 0)
r = floor(m/per);                                                           % Number of lines

axes(haxes)
beat = line(repmat(tlag(per:per:r*per),[2,1]),repmat([0;1],[1,r]), ...      % Beat lines
    'Color','r', ...                                                        % Color red
    'LineStyle',':', ...                                                    % The lines are dotted, except for line 1 (see below)
    'LineWidth',1, ...
    'HitTest','off');                                                       % The lines are not clickable, except for line 1 (see below)
set(beat(1), ...
    'HitTest','on', ...                                                     % Line 1 is clickable
    'LineStyle','-', ...                                                    % Line 1 is solid
    'ButtonDownFcn',@ClickLineFcn);                                         % Execute ClickLineFcn when line 1 is clicked (nested function)

set(hslider, ...
    'Value',tlag(per));                                                     % Update slider with period in seconds each time beat is plotted
set(hedit, ...
    'String',num2str(tlag(per),'%.4f'));                                    % Update edit with period in seconds with a precision of 4 digits each time beat is plotted

xlim = get(haxes,'XLim');
xlim(2) = tlag(floor(m/2));
f = get(haxes,'Parent');

    function ClickLineFcn(varargin)
        
        cl = get(f,'SelectionType');
        if strcmp(cl,'normal')
            set(f, ...
                'WindowButtonMotionFcn',@DragLineFcn, ...
                'WindowButtonUpFcn',@ReleaseFcn)
        end
        
    end

    function DragLineFcn(varargin)
        
        cp = get(haxes,'CurrentPoint');
        if cp(1,1) < xlim(1)
            cp(1,1) = xlim(1);
        elseif cp(1,1) > xlim(2)
            cp(1,1) = xlim(2);
        end
        
        beat = findobj(haxes,'Color','r');
        delete(beat)
        [~,per] = min(abs(tlag-cp(1)));
        plot_beat(haxes,hslider,hedit,tlag,per)
        
    end

    function ReleaseFcn(varargin)
        
        set(f, ...
            'WindowButtonMotionFcn','', ...
            'WindowButtonUpFcn','')
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function C = acorr(X)

[n,m] = size(X);
X = [X;zeros(n,m)];                                                         % Zero-padding to twice the length for a proper autocorrelation
X = abs(fft(X)).^2;                                                         % Power Spectral Density: PSD(X) = fft(X).*conj(fft(X))
C = ifft(X);                                                                % Wiener–Khinchin theorem: PSD(X) = fft(acorr(X))
C = C(1:n,:);                                                               % Discard the symmetric part (lags n-1 to 1)
C = C./repmat((n:-1:1)',[1,m]);                                             % Unbiased autocorrelation (lags 0 to n-1)

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function b = beat_spectrum(X)

B = acorr(X');                                                              % Correlogram using acorr [m lags, n bins]
b = mean(B,2);                                                              % Mean along the frequency bins

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function p = repeating_period(b)                                            % Old algorithm for estimating the repeating period

d = 2;                                                                      % Deviation parameter for potential shifted peaks (+-2 lags)
l = length(b);                                                              % Number of time lags
l = round(3/4*l);                                                           % New number of time lags
b = b(1:l);                                                                 % Keep only the first 3/4 lags (the rest is generally inacurrate)
l3 = floor(l/3);                                                            % Range for the period candidates (to have at least 3 segments for the median)
P = zeros(1,l3);                                                            % Vector for the period candidates
for p = 2+d:l3                                                              % Loop over the period candidates (start at 2 because the local neighbors for 1 is the value itself)
    e = floor(p*3/4);                                                       % (Half) range of the neighbors around the integer multiples of the period candidate p
    I = zeros(1,floor((l-e)/p));                                            % Vector for the integer multiples of the period candidate p
    for i = p:p:l-e                                                         % Loop over the number of integer multiples
        bd = b(i+(-d:d));                                                   % Integer multiple i +-deviation d
        [~,id] = max(bd);                                                   % Index of the integer multiple in bd
        id = id-d-1;                                                        % True index value
        be = b(i+(-e:e));                                                   % Neighbors around the integer multiple i
        [imax,ie] = max(be);                                                % Maxima and corresponding index
        ie = ie-e-1;                                                        % True index value
        if id == ie                                                         % If it is a maxima, it is counted
            I(i/p) = imax-mean(be);                                         % Value of the integer multiple i filtered by the mean of its neighbors
        end
    end
    P(p) = mean(I);                                                         % Mean energy over the integer multiples for the period candidate p
end
[~,p] = max(P);                                                             % Period candidate that gives the highest mean energy

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Y = masking_sigmoid(X,h,t)

X1 = X(X<t);                                                                % Values below the threshold
X2 = X(X==t);                                                               % Pivot values
X3 = X(X>t);                                                                % Values above the threshold
Y = zeros(size(X));
Y(X<t) = (X1/t^h).^(1/(1-h));                                               % Left partial sigmoid
Y(X==t) = X2;                                                               % Pivot values stay the same
Y(X>t) = 1-((1-X3)/(1-t)^h).^(1/(1-h));                                     % Right partial sigmoid

end
