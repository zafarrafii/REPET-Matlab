function urepet
% UREPET Simple user interface system for recovering patterns repeating in 
% time and frequency in mixtures of sounds
%
%   Toolbar:
%       Open:       Open audio file (as .wav or .mp3)
%       Save:       Save processed audio (as .wav)
%       Play:       Play/stop selected audio
%       Select:     Select/deselect on signal axes for playing and on
%                   spectrogram axes for processing (left/right click)
%       Zoom:       Zoom on any axes
%       Pan:        Pan on any axes
%       uREPET:     Process the selected region using uREPET
%       Background: Select to estimate the background (default) or deselect
%                   to estimate the foreground
%       Undo:       Undo the last changes
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
%       10/23/18

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

% Play and stop icons for the play buttons
play_icon = playicon;
stop_icon = stopicon;

% Create the open, save, and play push buttons on toolbar
open_button = uipushtool(toolbar_object, ...
    'CData',iconread('file_open.png'), ...
    'TooltipString','Open', ...
    'Enable','on', ...
    'ClickedCallback',@openclickedcallback); %#ok<*NASGU>
save_button = uipushtool(toolbar_object, ...
    'CData',iconread('file_save.png'), ...
    'TooltipString','Save', ...
    'Enable','off');
play_button = uipushtool(toolbar_object, ...
    'CData',play_icon, ...
    'TooltipString','Play', ...
    'Enable','off', ...
    'UserData',struct('PlayIcon',play_icon,'StopIcon',stop_icon));

% Create the pointer, zoom, and hand toggle buttons on toolbar
select_button = uitoggletool(toolbar_object, ...
    'Separator','On', ...
    'CData',iconread('tool_pointer.png'), ...
    'TooltipString','Select', ...
    'Enable','off', ...
    'ClickedCallBack',@selectclickedcallback);
zoom_button = uitoggletool(toolbar_object, ...
    'CData',iconread('tool_zoom_in.png'), ...
    'TooltipString','Zoom', ...
    'Enable','off',...
    'ClickedCallBack',@zoomclickedcallback);
pan_button = uitoggletool(toolbar_object, ...
    'CData',iconread('tool_hand.png'), ...
    'TooltipString','Pan', ...
    'Enable','off',...
    'ClickedCallBack',@panclickedcallback);

% Create uREPET, parameters, and undo push buttons on toolbar
urepet_button = uipushtool(toolbar_object, ...
    'Separator','On', ...
    'CData',urepeticon, ...
    'TooltipString','uREPET', ...
    'Enable','off');
background_button = uitoggletool(toolbar_object, ...
    'CData',iconread('tool_font_bold.png'), ...
    'TooltipString','Background', ...
    'Enable','off', ...
    'ClickedCallBack',@backgroundclickedcallback);
undo_icon = iconread('tool_rotate_3d.png');
undo_icon(6:12,6:12,:) = NaN;
undo_button = uipushtool(toolbar_object, ...
    'CData',undo_icon, ...
    'TooltipString','Undo', ...
    'Enable','off');

% Create the signal and spectrogram axes
signal_axes = axes( ...
    'OuterPosition',[0,0.9,1,0.1], ...
    'Visible','off');
spectrogram_axes = axes( ...
    'OuterPosition',[0,0,1,0.9], ...
    'Visible','off');

% Synchronize the x-axis limits of the signal and spectrogram axes
linkaxes([signal_axes,spectrogram_axes],'x')

% Change the pointer when the mouse moves over the signal axes
enterFcn = @(figure_handle,currentPoint) set(figure_handle,'Pointer','ibeam');
iptSetPointerBehavior(signal_axes,enterFcn);
iptPointerManager(figure_object);

% Change the pointer when the mouse moves over the figure object and the 
% spectrogram axes
enterFcn = @(figure_handle,currentPoint) set(figure_handle,'Pointer','arrow');
iptSetPointerBehavior(figure_object,enterFcn)
iptSetPointerBehavior(spectrogram_axes,enterFcn)
iptPointerManager(figure_object);

% Initialize the audio player (for the figure's close request callback)
audio_player = audioplayer(0,80);

% Make the figure visible
figure_object.Visible = 'on';

    % Clicked callback function for the open button
    function openclickedcallback(~,~)
        
        % Open file selection dialog box; return if cancel
        [audio_name,audio_path] = uigetfile({'*.wav';'*.mp3'}, ...
            'Select WAVE or MP3 File to Open');
        if isequal(audio_name,0) || isequal(audio_path,0)
            return
        end
        
        % Remove the figure's close request callback so that it allows all 
        % the other objects to get created before it can get closed
        figure_object.CloseRequestFcn = '';
        
        % Change the pointer symbol while the figure is busy
        figure_object.Pointer = 'watch';
        drawnow
        
        % If any audio is playing, stop it
        if isplaying(audio_player)
            stop(audio_player)
        end
        
        % Clear all the (old) axes and hide them
        cla(signal_axes)
        signal_axes.Visible = 'off';
        cla(spectrogram_axes)
        spectrogram_axes.Visible = 'off';
        drawnow
        
        % Build full file name
        audio_file = fullfile(audio_path,audio_name);
        
        % Read audio file and return sample rate in Hz
        [audio_signal,sample_rate] = audioread(audio_file);
        
        % Number of samples and channels
        [number_samples,number_channels] = size(audio_signal);
        
        % Plot the audio signal and make it unable to capture mouse clicks
        plot(signal_axes, ...
            1/sample_rate:1/sample_rate:number_samples/sample_rate, ...
            audio_signal, ...
            'PickableParts','none');
        
        % Update the signal axes properties
        signal_axes.XLim = [1,number_samples]/sample_rate;
        signal_axes.YLim = [-1,1];
        signal_axes.XGrid = 'on';
        signal_axes.Title.String = audio_name;
        signal_axes.Title.Interpreter = 'None';
        signal_axes.XLabel.String = 'Time (s)';
        signal_axes.Layer = 'top';
        signal_axes.UserData.PlotXLim = [1,number_samples]/sample_rate;
        signal_axes.UserData.SelectXLim = [1,number_samples]/sample_rate;
        drawnow
        
        % Add the constant-Q transform (CQT) toolbox folder to the search 
        % path
        addpath('urepet/CQT_toolbox_2013')
        
        % Number of frequency channels per octave, and minimum and maximum 
        % frequency in Hz
        octave_resolution = 24;
        minimum_frequency = 27.5;
        maximum_frequency = sample_rate/2;
        
        % Initialize the CQT object and the spectrogram
        audio_cqt = cell(1,number_channels);
        audio_spectrogram = [];
        
        % Compute the CQT object and the spectrogram for every channel
        for channel_index = 1:number_channels %#ok<*FXUP>
            audio_cqt{channel_index} ...
                = cqt(audio_signal(:,channel_index),octave_resolution,sample_rate,minimum_frequency,maximum_frequency);
            audio_spectrogram = cat(3,audio_spectrogram,abs(audio_cqt{channel_index}.c));
        end
        
        % Number of frequency channels and time frames
        [number_frequencies,number_times,~] = size(audio_spectrogram);
        
        % Update the maximum frequency in Hz
        maximum_frequency = minimum_frequency*2.^((number_frequencies-1)/octave_resolution);
        
        % Time range in seconds
        time_range = [1,number_times]/number_times*number_samples/sample_rate;
        
        % Display the audio spectrogram (in dB, averaged over the channels)
        % and make it unable to capture mouse clicks (compensate for the 
        % buggy padding that the log scale will introduce)
        imagesc(spectrogram_axes, ...
            time_range, ...
            [(minimum_frequency*2*number_frequencies+maximum_frequency)/(2*number_frequencies+1), ...
            (maximum_frequency*2*number_frequencies+minimum_frequency)/(2*number_frequencies+1)], ...
            db(mean(audio_spectrogram,3)), ...
            'PickableParts','none');
        
        % Update the mixture spectrogram axes properties
        spectrogram_axes.YScale = 'log';
        spectrogram_axes.YDir = 'normal';
        spectrogram_axes.XGrid = 'on';
        spectrogram_axes.Colormap = jet;
        spectrogram_axes.Title.String = 'Log-spectrogram';
        spectrogram_axes.XLabel.String = 'Time (s)';
        spectrogram_axes.YLabel.String = 'Frequency (Hz)';
        spectrogram_axes.ButtonDownFcn = @spectrogramaxesbuttondownfcn;
        drawnow
        
        % Color limits
        color_limits = spectrogram_axes.CLim;
        
        % Create object for playing audio
        audio_player = audioplayer(audio_signal,sample_rate);
        
        % Set a play line and a select line on the signal axes
        selectline(signal_axes)
        playline(signal_axes,audio_player,play_button);
        
        % Add clicked callback function to the play button
        play_button.ClickedCallback = {@playclickedcallback,audio_player,signal_axes};
        
        % Add key-press callback functions to the figure
        figure_object.KeyPressFcn  = @keypressfcncallback;
        
        % Add clicked callback function to the uREPET button
        urepet_button.ClickedCallback = @urepetclickedcallback;
        
        % Initialize the rectangle object as an array for graphic objects
        rectangle_object = gobjects(0);
        
        % Functions to translate frequency value in Hz to frequency indices 
        % and time value in second to time indices
        hz2freq = @(frequency_value) round(octave_resolution*log2(frequency_value/minimum_frequency)+1);
        sec2time = @(time_value) round(time_value/(number_samples/sample_rate)*number_times);
        
        % Enable the play, select, zoom, pan, and uREPET buttons
        play_button.Enable = 'on';
        select_button.Enable = 'on';
        zoom_button.Enable = 'on';
        pan_button.Enable = 'on';
        urepet_button.Enable = 'on';
        background_button.Enable = 'on';
        background_button.State = 'on';
        
        % Change the select button state to on
        select_button.State = 'on';
        
        % Change the pointer symbol back
        figure_object.Pointer = 'arrow';
        drawnow
        
        % Add the figure's close request callback back
        figure_object.CloseRequestFcn = @figurecloserequestfcn;
        
        % Key-press callback function to the figure
        function keypressfcncallback(~,~)
            
            % If the current character is the space character
            if ~strcmp(' ',figure_object.CurrentCharacter)
                return
            end
            
            % If the playback is in progress
            if isplaying(audio_player)
                
                % Stop the audio
                stop(audio_player)
                
            else
                
                % Sample rate and number of samples from the audio player
                sample_rate = audio_player.SampleRate;
                number_samples = audio_player.TotalSamples;
                
                % Plot and select limits from the signal axes' user data
                plot_limits = signal_axes.UserData.PlotXLim;
                select_limits = signal_axes.UserData.SelectXLim;
                
                % Derive the sample range for the audio player
                if select_limits(1) == select_limits(2)
                    % If it is a select line
                    sample_range = [round((select_limits(1)-plot_limits(1))*sample_rate)+1,number_samples];
                else
                    % If it is a select region
                    sample_range = round((select_limits-plot_limits(1))*sample_rate+1);
                end
                
                % Play the audio given the sample range
                play(audio_player,sample_range)
                
            end
            
        end
        
        % Mouse-click callback for the spectrogram axes
        function spectrogramaxesbuttondownfcn(~,~)
            
            % Location of the mouse pointer
            current_point = spectrogram_axes.CurrentPoint;
            
            % If the current point is out of the spectrogram limits, return
            if current_point(1,1) < time_range(1) || current_point(1,1) > time_range(2) || ...
                    current_point(1,2) < minimum_frequency || current_point(1,2) > maximum_frequency
                return
            end
            
            % If click left mouse button
            if strcmp(figure_object.SelectionType,'normal')
                
                % Delete the current rectangle object
                delete(rectangle_object)
                
                % Begin drawing ROI from specified point
                rectangle_object = images.roi.Rectangle('Parent',spectrogram_axes, ...
                    'DrawingArea',[time_range(1),minimum_frequency,diff(time_range),maximum_frequency-minimum_frequency]);
                beginDrawingFromPoint(rectangle_object,current_point(1,1:2));
                
            end
            
        end
        
        % Clicked callback function for the uREPET button
        function urepetclickedcallback(~,~)
            
            % If the rectangle object is empty or not valid, return
            if isempty(rectangle_object) || ~isvalid(rectangle_object)
                return
            end
            
            % Position of ROI
            rectangle_position = rectangle_object.Position;
            
            % If the width and height of the rectangle object are both 0, 
            % return
            if all(~rectangle_position(3:4))
                return
            end
            
            % Remove the figure's close request callback so that it allows
            % all the other objects to get created before it can get closed
            figure_object.CloseRequestFcn = '';
            
            % Change the pointer symbol while the figure is busy
            figure_object.Pointer = 'watch';
            drawnow
            
            % If any audio is playing, stop it
            if isplaying(audio_player)
                stop(audio_player)
            end
            
            % Store the original audio signal and CQT in case of undo
            audio_signal0 = audio_signal;
            audio_cqt0 = audio_cqt;
            
            % Frequency and time indices of the rectangle object
            frequency_indices = hz2freq(rectangle_position(2)+[0,rectangle_position(4)]);
            time_indices = sec2time(rectangle_position(1)+[0,rectangle_position(3)]);
            
            % Audio rectangle from the audio spectrogram
            audio_rectangle = audio_spectrogram(frequency_indices(1):frequency_indices(2), ...
                time_indices(1):time_indices(2),:);
            rectangle_size = size(audio_rectangle);
            
            % Normalized 2-D cross-correlation between the audio rectangle 
            % and the audio spectrogram, averaged over the channels
            audio_correlation = normxcorr2(mean(audio_rectangle,3),mean(audio_spectrogram,3));
            
            % Remove the parts added by the zero-padding
            audio_correlation = audio_correlation(rectangle_size(1):end-rectangle_size(1)+1, ...
                rectangle_size(2):end-rectangle_size(2)+1);
            correlation_size = size(audio_correlation);
            
            % Maximum number of repetitions, minimum frequency separation 
            % (in semitones), and minimum time separation (in seconds)
            number_repetitions = 10;
            frequency_separation = 1;
            time_separation = 1;
            
            % Frequency and time separation in frequency and time indices
            frequency_separation = frequency_separation*octave_resolution;
            time_separation = sec2time(time_separation);
            
            % Zero the region around the first self-similar repetition 
            % given the frequency and time separation
            audio_correlation(max(frequency_indices(1)-frequency_separation,1):min(frequency_indices(1)+frequency_separation,correlation_size(1)), ...
                max(time_indices(1)-time_separation,1):min(time_indices(1)+time_separation,correlation_size(2))) = 0;
            
            % Loop over the other repetitions
            for repetition_index = 2:number_repetitions
                
                % Frequency and time indices of the maximum repetition
                [~,maximum_index] = max(audio_correlation(:));
                [frequency_index,time_index] = ind2sub(correlation_size,maximum_index);
                
                % Zero the region around the maximum repetition given the 
                % frequency and time separation
                audio_correlation(max(frequency_index-frequency_separation,1):min(frequency_index+frequency_separation,correlation_size(1)), ...
                    max(time_index-time_separation,1):min(time_index+time_separation,correlation_size(2))) = 0;
                
                % Save the similar rectangles
                audio_rectangle = cat(4,audio_rectangle, ...
                    audio_spectrogram(frequency_index:frequency_index+rectangle_size(1)-1, ...
                    time_index:time_index+rectangle_size(2)-1,:));
                
            end
            
            % Compute the mask from the rectangles for the spectrogram
            audio_mask = (min(median(audio_rectangle,4),audio_rectangle(:,:,:,1))+eps)./(audio_rectangle(:,:,:,1)+eps);
            
            % If the background button is off, invert the mask
            if strcmp(background_button.State,'off')
                audio_mask = audio_mask-1;
            end
            
            % Apply the mask to the CQT object and the spectrogram, and
            % update the audio signal
            audio_signal = zeros(number_samples,number_channels);
            for channel_index = 1:number_channels
                audio_cqt{channel_index}.c(frequency_indices(1):frequency_indices(2),time_indices(1):time_indices(2)) ...
                    = audio_mask(:,:,channel_index).*audio_cqt{channel_index}.c(frequency_indices(1):frequency_indices(2),time_indices(1):time_indices(2));
                audio_spectrogram(frequency_indices(1):frequency_indices(2),time_indices(1):time_indices(2),channel_index) ...
                    = audio_mask(:,:,channel_index).*audio_spectrogram(frequency_indices(1):frequency_indices(2),time_indices(1):time_indices(2),channel_index);
                audio_signali = icqt(audio_cqt{channel_index});
                audio_signal(:,channel_index) = audio_signali(1:number_samples);
            end
            
            % Update the signal axes
            channel_index = number_channels;
            for children_index = 1:numel(signal_axes.Children)
                if numel(signal_axes.Children(children_index).YData) == number_samples
                    signal_axes.Children(children_index).YData = audio_signal(:,channel_index)';
                    channel_index = channel_index-1;
                end
            end
            drawnow
            
            % Update the spectrogram axes
            spectrogram_axes.Children(end).CData(frequency_indices(1):frequency_indices(2),time_indices(1):time_indices(2)) ...
                = db(mean(audio_spectrogram(frequency_indices(1):frequency_indices(2),time_indices(1):time_indices(2),:),3));
            spectrogram_axes.CLim = color_limits;
            drawnow
            
            % Update the audio player, and the play line and clicked 
            % callback function of the play button
            audio_player = audioplayer(audio_signal,sample_rate);
            playline(signal_axes,audio_player,play_button);
            play_button.ClickedCallback = {@playclickedcallback,audio_player,signal_axes};
            
            % Add clicked callback functions to the save and undo buttons
            save_button.ClickedCallback = @saveclickedcallback;
            undo_button.ClickedCallback = @undoclickedcallback;
            
            % Enable the save and undo buttons
            save_button.Enable = 'on';
            undo_button.Enable = 'on';
            
            % Add the figure's close request callback back
            figure_object.CloseRequestFcn = @figurecloserequestfcn;
            
            % Change the pointer symbol back
            figure_object.Pointer = 'arrow';
            
            % Clicked callback function for the save button
            function saveclickedcallback(~,~)
                
                % Open dialog box for saving files; return if cancel
                [audio_name,audio_path] = uiputfile('*.wav*', ...
                    'Save Audio as WAVE File','urepet_file.wav');
                if isequal(audio_name,0) || isequal(audio_path,0)
                    return
                end
                
                % Build full file name
                audio_file = fullfile(audio_path,audio_name);
                
                % Write the audio file
                audiowrite(audio_file,audio_signal,sample_rate)
                
            end
            
            % Clicked callback function for the undo button
            function undoclickedcallback(~,~)
                
                % Disable the button
                undo_button.Enable = 'off';
                
                % Restore the audio signal and CQT
                audio_signal = audio_signal0;
                audio_cqt = audio_cqt0;
                
                % Restore the audio spectrogram
                audio_spectrogram = [];
                for channel_index = 1:number_channels
                    audio_spectrogram = cat(3,audio_spectrogram,abs(audio_cqt{channel_index}.c));
                end
                
                % Update the signal axes
                channel_index = number_channels;
                for children_index = 1:numel(signal_axes.Children)
                    if numel(signal_axes.Children(children_index).YData) == number_samples
                        signal_axes.Children(children_index).YData = audio_signal(:,channel_index)';
                        channel_index = channel_index-1;
                    end
                end
                drawnow
                
                % Update the spectrogram axes
                spectrogram_axes.Children(end).CData(frequency_indices(1):frequency_indices(2),time_indices(1):time_indices(2)) ...
                    = db(mean(audio_spectrogram(frequency_indices(1):frequency_indices(2),time_indices(1):time_indices(2),:),3));
                spectrogram_axes.CLim = color_limits;
                drawnow
                
                % Update the audio player, and the play line and clicked
                % callback function of the play button
                audio_player = audioplayer(audio_signal,sample_rate);
                playline(signal_axes,audio_player,play_button);
                play_button.ClickedCallback = {@playclickedcallback,audio_player,signal_axes};
                
            end
            
        end
        
    end

    % Clicked callback function for the select button
    function selectclickedcallback(~,~)
        
        % Keep the select button state to on and change the zoom and pan 
        % button states to off
        select_button.State = 'on';
        zoom_button.State = 'off';
        pan_button.State = 'off';
        
        % Turn the zoom off
        zoom off
        
        % Turn the pan off
        pan off
        
    end

    % Clicked callback function for the zoom button
    function zoomclickedcallback(~,~)
        
        % Keep the zoom button state to on and change the select and pan 
        % button states to off
        select_button.State = 'off';
        zoom_button.State = 'on';
        pan_button.State = 'off';
        
        % Make the zoom enable on the figure
        zoom_object = zoom(figure_object);
        zoom_object.Enable = 'on';
        
        % Set the zoom for the x-axis only on the signal axes
        setAxesZoomConstraint(zoom_object,signal_axes,'x');
        
        % Turn the pan off
        pan off
        
    end

    % Clicked callback function for the pan button
    function panclickedcallback(~,~)
        
        % Keep the pan button state to on and change the select and zoom 
        % button states to off
        select_button.State = 'off';
        zoom_button.State = 'off';
        pan_button.State = 'on';
        
        % Turn the zoom off
        zoom off
        
        % Make the pan enable on the figure
        pan_object = pan(figure_object);
        pan_object.Enable = 'on';
        
        % Set the pan for the x-axis only on the signal axes
        setAxesPanConstraint(pan_object,signal_axes,'x');
        
    end

    % Clicked callback function for the background button
    function backgroundclickedcallback(~,~)
        
        % Change the tooltip string depending on the state of the button
        if strcmp(background_button.State,'on')
            background_button.TooltipString = 'Background';
        elseif strcmp(background_button.State,'off')
            background_button.TooltipString = 'Foreground';
        end
        
    end

    % Close request callback function for the figure
    function figurecloserequestfcn(~,~)
        
        % If the audio is playing, stop it
        if isplaying(audio_player)
            stop(audio_player)
        end
        
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

% Create play icon
function image_data = playicon

% Create the upper-half of a black play triangle with NaN's everywhere else
image_data = [nan(2,16);[nan(6,3),kron(triu(nan(6,5)),ones(1,2)),nan(6,3)]];

% Make the whole black play triangle image
image_data = repmat([image_data;image_data(end:-1:1,:)],[1,1,3]);

end

% Create stop icon
function image_data = stopicon

% Create a black stop square with NaN's everywhere else
image_data = nan(16,16);
image_data(4:13,4:13) = 0;

% Make the black stop square an image
image_data = repmat(image_data,[1,1,3]);

end

% Create REPET icon
function image_data = urepeticon

% Create a matrix with NaN's
image_data = nan(16,16,1);

% Create black u, R, E, P, E, and T letters
image_data(4:7,2) = 0;
image_data(7:8,3) = 0;
image_data(4:8,4:5) = 0;

image_data(2:8,7:8) = 0;
image_data([2,3,5,6],9) = 0;
image_data([3:5,7:8],10) = 0;

image_data(2:8,12:13) = 0;
image_data([2,3,5,7,8],14) = 0;
image_data([2,3,7,8],15) = 0;

image_data(10:16,2:3) = 0;
image_data([10,11,13,14],4) = 0;
image_data(11:13,5) = 0;

image_data(10:16,7:8) = 0;
image_data([10,11,13,15,16],9) = 0;
image_data([10,11,15,16],10) = 0;

image_data(10:11,12:15) = 0;
image_data(12:16,13:14) = 0;

% Make the image
image_data = repmat(image_data,[1,1,3]);

end

% Set a select line on the signal axes
function selectline(signal_axes)

% Initialize the select line as an array for graphic objects (two lines and
% one patch)
select_line = gobjects(3,1);

% Add mouse-click callback function to the signal axes
signal_axes.ButtonDownFcn = @signalaxesbuttondownfcn;

    % Mouse-click callback function for the signal axes
    function signalaxesbuttondownfcn(~,~)
        
        % Location of the mouse pointer
        current_point = signal_axes.CurrentPoint;
        
        % Plot limits from the audio signal axes' user data
        plot_limits = signal_axes.UserData.PlotXLim;
        
        % If the current point is out of the plot limits, return
        if current_point(1,1) < plot_limits(1) || current_point(1,1) > plot_limits(2) || ...
                current_point(1,2) < -1 || current_point(1,2) > 1
            return
        end
        
        % Current figure handle
        figure_object = gcf;
        
        % Mouse selection type
        selection_type = figure_object.SelectionType;
        
        % If click left mouse button
        if strcmp(selection_type,'normal')
            
            % If not empty, delete the select line
            if ~isempty(select_line)
                delete(select_line)
            end
            
            % Create a first line on the audio signal axes
            color_value1 = 0.5*[1,1,1];
            select_line(1) = line(signal_axes, ...
                current_point(1,1)*[1,1],[-1,1], ...
                'Color',color_value1, ...
                'ButtonDownFcn',@selectlinebuttondownfcn);
            
            % Create a second line and a non-clickable patch with different
            % colors and move them at the bottom of the current stack
            color_value2 = 0.75*[1,1,1];
            select_line(2) = line(signal_axes, ...
                current_point(1,1)*[1,1],[-1,1], ...
                'Color',color_value2, ...
                'ButtonDownFcn',@selectlinebuttondownfcn);
            uistack(select_line(2),'bottom')
            select_line(3) = patch(signal_axes, ...
                current_point(1,1)*[1,1,1,1],[-1,1,1,-1],color_value2, ...
                'LineStyle','none', ...
                'PickableParts','none');
            uistack(select_line(3),'bottom')
            
            % Change the pointer when the mouse moves over the lines, the
            % signal axes, and the figure object
            enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','hand');
            iptSetPointerBehavior(select_line(1),enterFcn);
            iptSetPointerBehavior(select_line(2),enterFcn);
            iptSetPointerBehavior(signal_axes,enterFcn);
            iptSetPointerBehavior(figure_object,enterFcn);
            iptPointerManager(figure_object);
            
            % Add window button motion and up callback functions to the
            % figure
            figure_object.WindowButtonMotionFcn = {@figurewindowbuttonmotionfcn,select_line(1)};
            figure_object.WindowButtonUpFcn = @figurewindowbuttonupfcn;
            
            % Update the select limits in the signal axes' user data
            signal_axes.UserData.SelectXLim = current_point(1,1)*[1,1];
            
        % If click right mouse button
        elseif strcmp(selection_type,'alt')
            
            % If not empty, delete the select line
            if ~isempty(select_line)
                delete(select_line)
            end
            
            % Update the select limits in the signal axes' user data
            signal_axes.UserData.SelectXLim = plot_limits;
            
        end
        
        % Mouse-click callback function for the lines
        function selectlinebuttondownfcn(object_handle,~)
            
            % Mouse selection type
            selection_type = figure_object.SelectionType;
            
            % If click left mouse button
            if strcmp(selection_type,'normal')
                
                % Change the pointer when the mouse moves over the signal 
                % axes or the figure object
                enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','hand');
                iptSetPointerBehavior(signal_axes,enterFcn);
                iptSetPointerBehavior(figure_object,enterFcn);
                iptPointerManager(figure_object);
                
                % Add window button motion and up callback functions to
                % the figure
                figure_object.WindowButtonMotionFcn = {@figurewindowbuttonmotionfcn,object_handle};
                figure_object.WindowButtonUpFcn = @figurewindowbuttonupfcn;
                
            % If click right mouse button
            elseif strcmp(selection_type,'alt')
                
                % Delete the select line
                delete(select_line)
                
                % Update the select limits in the signal axes' user data
                signal_axes.UserData.SelectXLim = plot_limits;
                
            end
            
        end
        
        % Window button motion callback function for the figure
        function figurewindowbuttonmotionfcn(~,~,select_linei)
            
            % Location of the mouse pointer
            current_point = signal_axes.CurrentPoint;
            
            % If the current point is out of the plot limits, change it 
            % into the plot limits
            if current_point(1,1) < plot_limits(1)
                current_point(1,1) = plot_limits(1);
            elseif current_point(1,1) > plot_limits(2)
                current_point(1,1) = plot_limits(2);
            end
            
            % Update the coordinates of the audio line that has been
            % clicked and the coordinates of the audio patch
            select_linei.XData = current_point(1,1)*[1,1];
            select_line(3).XData = [select_line(1).XData,select_line(2).XData];
            
            % If the two lines are at different coordinates and the patch
            % is a full rectangle
            if select_line(1).XData(1) ~= select_line(2).XData(1)
                
                % Change the color of the first line to match the color of
                % the second line and the patch, and move it at the bottom
                % of the current stack
                select_line(1).Color = color_value2;
                uistack(select_line(1),'bottom')
                
            % If the two lines are at the same coordinates and the patch is
            % a vertical line
            else
                
                % Change the color of the first line back, and move
                % it at the top of the current stack
                select_line(1).Color = color_value1;
                uistack(select_line(1),'top')
                
            end
            
        end
        
        % Window button up callback function for the figure
        function figurewindowbuttonupfcn(~,~)
            
            % Change the pointer back when the mouse moves over the signal 
            % axes and the figure object
            enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','ibeam');
            iptSetPointerBehavior(signal_axes,enterFcn);
            iptPointerManager(figure_object);
            enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','arrow');
            iptSetPointerBehavior(figure_object,enterFcn);
            iptPointerManager(figure_object);
            
            % Coordinates of the two audio lines
            x_value1 = select_line(1).XData(1);
            x_value2 = select_line(2).XData(1);
            
            % Update the select limits in the audio signal axes' user data
            % depending if the two lines have the same or different
            % coordinates
            if x_value1 == x_value2
                signal_axes.UserData.SelectXLim = [x_value1,x_value1];
            elseif x_value1 < x_value2
                signal_axes.UserData.SelectXLim = [x_value1,x_value2];
            else
                signal_axes.UserData.SelectXLim = [x_value2,x_value1];
            end
            
            % Remove the window button motion and up callback functions of
            % the figure
            figure_object.WindowButtonMotionFcn = '';
            figure_object.WindowButtonUpFcn = '';
            
        end
        
    end

end

% Set a play line on the signal axes using the audio player
function playline(signal_axes,audio_player,play_button)

% Play and stop icons from the play buttons' user data
play_icon = play_button.UserData.PlayIcon;
stop_icon = play_button.UserData.StopIcon;

% Sample rate in Hz from the audio player
sample_rate = audio_player.SampleRate;

% Get the plot limits from the signal axes' user data
plot_limits = signal_axes.UserData.PlotXLim;

% Initialize the play line
play_line = [];

% Add callback functions to the audio player
audio_player.StartFcn = @audioplayerstartfcn;
audio_player.StopFcn = @audioplayerstopfcn;
audio_player.TimerFcn = @audioplayertimerfcn;

    % Function to execute one time when the playback starts
    function audioplayerstartfcn(~,~)
        
        % Change the play button icon to a stop icon and the tooltip to 
        % 'Stop'
        play_button.CData = stop_icon;
        play_button.TooltipString = 'Stop';
        
        % Get the select limits from the signal axes' user data
        select_limits = signal_axes.UserData.SelectXLim;
        
        % Create a play line on the signal axes
        play_line = line(signal_axes,select_limits(1)*[1,1],[-1,1]);
        
    end

    % Function to execute one time when playback stops
    function audioplayerstopfcn(~,~)
        
        % Change the play button icon to a play icon and the tooltip to 
        % 'Play'
        play_button.CData = play_icon;
        play_button.TooltipString = 'Play';
        
        % Delete the play line
        delete(play_line)
        
    end

    % Function to execute repeatedly during playback
    function audioplayertimerfcn(~,~)
        
        % Current sample and sample range from the audio player
        current_sample = audio_player.CurrentSample;
        
        % Make sure the current sample is only increasing (to prevent the
        % play line from showing up at the start when the playback is over)
        if current_sample > 1
            
            % Update the play line
            play_line.XData = (plot_limits(1)+current_sample/sample_rate)*[1,1];
            
        end
        
    end

end

% Clicked callback function for the play button
function playclickedcallback(~,~,audio_player,signal_axes)

% If the playback is in progress
if isplaying(audio_player)
    
    % Stop the audio
    stop(audio_player)
    
else
    
    % Sample rate and number of samples from the audio player
    sample_rate = audio_player.SampleRate;
    number_samples = audio_player.TotalSamples;
    
    % Plot and select limits from the signal axes' user data
    plot_limits = signal_axes.UserData.PlotXLim;
    select_limits = signal_axes.UserData.SelectXLim;
    
    % Derive the sample range for the audio player
    if select_limits(1) == select_limits(2)
        % If it is a select line
        sample_range = [round((select_limits(1)-plot_limits(1))*sample_rate)+1,number_samples];
    else
        % If it is a select region
        sample_range = round((select_limits-plot_limits(1))*sample_rate+1);
    end
    
    % Play the audio given the sample range
    play(audio_player,sample_range)
    
end

end
