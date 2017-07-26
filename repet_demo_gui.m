%   REpeating Pattern Extraction Technique (REPET): original REPET GUI demo
%
%   REPET is a simple method for separating the repeating background (e.g., the accompaniment)
%   from the non-repeating foreground (e.g., the melody) in an audio mixture. 
%
%   Usage:
%       repet_demo_gui
%
%       - Select tool (toolbar left):                                       Select/deselect on wave axes (left/right mouse click)
%       - Zoom tool (toolbar middle):                                       Zoom in/out on axes (left/right mouse click)
%       - Pan tool (toolbar right):                                         Pan left and right on axes
%
%       - Load mixture button (top-left quarter top left):                  Load mixture file (WAVE files only)
%       - Play mixture button (top-left quarter top left):                  Play/stop mixture audio
%       - Mixture wave axes (top-left quarter top):                         Display mixture wave
%       - REPET button (top-left quarter top right):                        Process mixture selection using REPET algorithm
%       - Mixture spectrogram axes (top-left quarter bottom):               Display spectrogram of mixture selection
%
%       - Beat spectrum axes (bottom-left quarter top):                     Display beat spectrum of mixture selection
%       - Period slider/edit (bottom-left quarter top):                     Modify repeating period (in seconds)
%
%       - Hardness slider/edit (bottom-left quarter middle):                Modify masking hardness (in [0,1])
%           - transforms soft time-frequency mask into binary time-frequency mask
%           - the closer to 0, the softer the mask, the less separation artifacts (0 = original soft mask)
%           - the closer to 1, the harder the mask, the less source interference (1 = full binary mask)
%       - Threshold slider/edit (bottom-left quarter bottom):               Modify masking threshold (in [0,1])
%           - defines pivot value around which the energy will be spread apart (when hardness > 0)
%           - the closer to 0, the more energy for the repeating background, the less interference in the non-repeating foreground
%           - the closer to 1, the less energy for the repeating background, the less interference from the non-repeating foreground
%
%       - Save background button (top-right quarter top left):              Save background estimate of mixture selection in WAVE file
%       - Play background button (top-right quarter top left):              Play/stop background audio of mixture selection
%       - Background wave axes (top-right quarter top):                 	Display background wave of mixture selection
%       - Background spectrogram axes (top-right quarter bottom):           Display background spectrogram of mixture selection
%
%       - Save foreground button (bottom-right quarter top left):           Save foreground estimate of mixture selection in WAVE file
%       - Play foreground button (bottom-right quarter top left):           Play/stop foreground audio of mixture selection
%       - Foreground wave axes (bottom-right quarter top):                  Display foreground wave of mixture selection
%       - Foreground spectrogram axes (bottom-right quarter bottom):        Display foreground spectrogram of mixture selection
%
%   See also http://music.eecs.northwestern.edu/research.php?project=repet

%   Author: Zafar Rafii (zafarrafii@u.northwestern.edu)
%   Update: September 2013
%   Copyright: Zafar Rafii and Bryan Pardo, Northwestern University
%   Reference(s):
%       [1] Zafar Rafii and Bryan Pardo. "Audio Separation System and Method," 
%           US20130064379 A1, US 13/612,413, March 14, 2013.
%       [2] Zafar Rafii and Bryan Pardo. 
%           "REpeating Pattern Extraction Technique (REPET): A Simple Method for Music/Voice Separation," 
%           IEEE Transactions on Audio, Speech, and Language Processing, 
%           Volume 21, Issue 1, pp. 71-82, January, 2013.
%       [3] Zafar Rafii and Bryan Pardo. 
%           "A Simple Music/Voice Separation Method based on the Extraction of the Repeating Musical Structure," 
%           36th International Conference on Acoustics, Speech and Signal Processing,
%           Prague, Czech Republic, May 22-27, 2011.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function repet_demo_gui

% Create figure object with toolbar and save the handles in a structure h:

figure_color = [240,240,240]/255;                                           % Grey94 RGB
screen_size = get(0,'ScreenSize');                                          % Screen size [1,1,width,height]
figure_position = [round(screen_size(3)/2-500/2),round(screen_size(4)/2-500/2),500,500];    % [left,bottom,width,height]
h.figure = figure( ...
    'Color',figure_color, ...
    'DockControls','off', ...                                               % Do not display controls used to dock figure
    'MenuBar','none', ...                                                   % Disable figure menu bar
    'Name','REPET demo', ...                                                % Figure window title
    'NumberTitle','off', ...                                                % Do not display figure window title number (by default 'on' with programming GUI)
    'Position',figure_position, ...                                         % Centered position
    'Renderer','zbuffer', ...                                               % Rendering method ('zbuffer' is faster and more accurate than 'painters'; 'opengl' is even faster but it behaves weird)
    'Resize','off', ...                                                     % Disable window resizing
    'CloseRequestFcn',@figure_closerequestfcn);                             % Call figure_closerequestfcn when figure closes

toolbar = uitoolbar(h.figure);                                              % Create a toolbar at the top of the figure window
h.select_toggletool = create_initial_toggletool( ...                        % Create an initial select toggle button on toolbar
    toolbar,pointer_icon,'Selection tool',@select_toggletool_clickedcallback);
h.zoom_toggletool = create_initial_toggletool( ...                          % Create an initial zoom toggle button on toolbar
    toolbar,zoom_icon,'Zoom tool',@zoom_toggletool_clickedcallback);
h.pan_toggletool = create_initial_toggletool( ...                           % Create an initial pan toggle button on toolbar
    toolbar,hand_icon,'Pan tool',@pan_toggletool_clickedcallback);

% Create objects related with the mixture and save their handles in h:

load_mixture_pushbutton_position = [10,460,30,30];
h.load_mixture_pushbutton = create_initial_pushbutton( ...
    load_icon,load_mixture_pushbutton_position,'Load mixture',@load_mixture_pushbutton_callback);   % Create initial push button (see below)
set(h.load_mixture_pushbutton, ...
    'Enable','on')                                                          % Load is the only object initially enabled
play_mixture_pushbutton_position = [10,420,30,30];                          % Left position aligned with load_mixture_pushbutton
h.play_mixture_pushbutton = create_initial_pushbutton( ...
    play_icon,play_mixture_pushbutton_position,'Play mixture',@play_mixture_pushbutton_callback);
repet_mixture_pushbutton_position = [210,430,50,50];                        % Additional gap for the bottom position
h.repet_mixture_pushbutton = uicontrol( ...                                 % Repet push button (does not use create_initial_pushbutton)
    'Enable','off', ...
    'FontWeight','bold', ...
    'Position',repet_mixture_pushbutton_position, ...
    'String','REPET',...
    'Style','pushbutton',...
    'TooltipString','Process mixture', ...
    'Callback',@repet_mixture_pushbutton_callback);

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

function disable_enable_figure                                              % Commented because of compatibility problems

% javaframe = get(handle(gcf),'JavaFrame');                                   % Hidden property of the figure
% figurepanelcontainer = get(javaframe,'FigurePanelContainer');               % Figure's content area (not including menu bar and toolbar)
% switch figurepanelcontainer.isEnabled                                       % Check if the content area is disabled or not
%     case 0
%         figurepanelcontainer.setEnabled(true)                               % Enable the content area if disabled
%         javaframe.fFigureClient.setCursor(java.awt.Cursor(java.awt.Cursor.DEFAULT_CURSOR))  % Set the cursor watch to the default pointer
%     case 1
%         javaframe.fFigureClient.setCursor(java.awt.Cursor(java.awt.Cursor.WAIT_CURSOR))     % Set the cursor default pointer to watch
%         figurepanelcontainer.setEnabled(false)                              % Disable the content area if enabled
% end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function i = pointer_icon

[i,~,a] = imread(fullfile(matlabroot,'toolbox','matlab','icons','tool_pointer.png'),'PNG'); % Use the pointer icon from MATLAB (i is the [16x16x3] 16-bit PNG image and a is the [16x16] AND mask for the transparency)
i = im2double(i);                                                           % Convert the image to double precision, rescaling the data between 0 and 1
a = im2double(a);                                                           % Convert the mask to double precision (0 = transparent pixels, 1 = non-transparent pixels)
a(a==0) = NaN;                                                              % Convert 0 to NaN (= transparency for pushbutton's cdata)
i = i.*repmat(a,[1,1,3]);                                                   % Mask the 3 layers of the image

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function i = zoom_icon

[i,~,a] = imread(fullfile(matlabroot,'toolbox','matlab','icons','tool_zoom_in.png'),'PNG');	% Use the zoom icon from MATLAB
i = im2double(i);
a = im2double(a);
a(a==0) = NaN;
i = i.*repmat(a,[1,1,3]);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function i = hand_icon

[i,~,a] = imread(fullfile(matlabroot,'toolbox','matlab','icons','tool_hand.png'),'PNG');	% Use the hand icon from MATLAB
i = im2double(i);
a = im2double(a);
a(a==0) = NaN;
i = i.*repmat(a,[1,1,3]);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function i = load_icon

[i,~,a] = imread(fullfile(matlabroot,'toolbox','matlab','icons','file_open.png'),'PNG');    % Use the load icon from MATLAB
i = im2double(i);
a = im2double(a);
a(a==0) = NaN;
i = i.*repmat(a,[1,1,3]);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function i = save_icon

[i,~,a] = imread(fullfile(matlabroot,'toolbox','matlab','icons','file_save.png'),'PNG');    % Use the save icon from MATLAB
i = im2double(i);
a = im2double(a);
a(a==0) = NaN;
i = i.*repmat(a,[1,1,3]);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function i = play_icon

s = 11;                                                                     % Odd size (width and height)
j = triu(ones((s-1)/2,(s+1)/2),1);                                          % Upper triangular '1' / lower triangular '0'
j(j==1) = NaN;                                                              % 0 = black pixels and NaN = transparent pixels
j = [j;zeros(1,(s+1)/2);flipud(j)];                                         % [s,(s+1)/2] black play icon on a transparent background
i = nan(11,11);                                                             % [s,s-1] stretched play icon
i(:,1:2:end) = j(:,1:end);
i(:,2:2:end) = j(:,2:end);
i = repmat(i,[1,1,3]);                                                      % Play icon image

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function i = stop_icon

i = zeros(11,11,3);                                                         % Black stop icon

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function htoggletool = create_initial_toggletool(htoolbar,toggletool_cdata,toggletool_tooltipstring,toggletool_clickedcallback)

htoggletool = uitoggletool(htoolbar, ...
    'CData',toggletool_cdata, ...
    'Enable','off', ...
    'TooltipString',toggletool_tooltipstring, ...
    'ClickedCallback',toggletool_clickedcallback);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function hpushbutton = create_initial_pushbutton(pushbutton_cdata,pushbutton_position,pushbutton_tooltipstring,pushbutton_callback)

hpushbutton =  uicontrol( ...
    'CData',pushbutton_cdata, ...
    'Enable','off', ...
    'Position',pushbutton_position, ...
    'Style','pushbutton', ...
    'TooltipString',pushbutton_tooltipstring, ...
    'Callback',pushbutton_callback);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function haxes = create_initial_axes(axes_position)

figure_color = [240,240,240]/255;

haxes = axes( ...
    'Units','pixels', ...                                                   % Set units before position!
    'Box','on', ...
    'Color',figure_color, ...                                               % Initially same color as figure
    'Position',axes_position, ...
    'XTick',[], ...                                                         % Initially no ticks
    'YTick',[]);                                                            % Initialize ButtonDownFcn only when plotting or it will be reset

end

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
[x,fs,nbits] = wavread(file);
h.mixture_audio = x;                                                        % Mixture audio (fs and nbits will be automatically saved in audioplayer)
h.mixture_audioplayer = audioplayer(x,fs,nbits);                            % Mixture audioplayer

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
nbits = get(h.mixture_audioplayer,'BitsPerSample');

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

h.background_audioplayer = audioplayer(y,fs,nbits);
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

h.foreground_audioplayer = audioplayer(x-y,fs,nbits);
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
nbits = get(h.mixture_audioplayer,'BitsPerSample');
file = fullfile(filepath,filename);
wavwrite(y,fs,nbits,file);

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
nbits = get(h.mixture_audioplayer,'BitsPerSample');
file = fullfile(filepath,filename);                                         % File with path and extension
wavwrite(x-y,fs,nbits,file);

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

function X = stft(x,win,stp)

t = length(x);                                                              % Number of samples
N = length(win);                                                            % Analysis window length
m = ceil((N-stp+t)/stp);                                                    % Number of frames with zero-padding
x = [zeros(N-stp,1);x;zeros(m*stp-t,1)];                                    % Zero-padding for constant overlap-add
X = zeros(N,m);
for j = 1:m                                                                 % Loop over the frames
    X(:,j) = fft(x((1:N)+stp*(j-1)).*win);                                  % Windowing and fft
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

end

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
