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
%       10/05/18

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

% Play and stop icons for the play audio toggle buttons
play_icon = playicon;
stop_icon = stopicon;

% Create the open and play toggle buttons on toolbar
open_toggle = uitoggletool(toolbar_object, ...
    'CData',iconread('file_open.png'), ...
    'TooltipString','Open', ...
    'Enable','on', ...
    'ClickedCallback',@openclickedcallback);
play_toggle = uitoggletool(toolbar_object, ...
    'CData',play_icon, ...
    'TooltipString','Play', ...
    'Enable','off', ...
    'UserData',struct('PlayIcon',play_icon,'StopIcon',stop_icon));

% Create the pointer, zoom, and hand toggle buttons on toolbar
select_toggle = uitoggletool(toolbar_object, ...
    'Separator','On', ...
    'CData',iconread('tool_pointer.png'), ...
    'TooltipString','Select', ...
    'Enable','off', ...
    'ClickedCallBack',@selectclickedcallback);
zoom_toggle = uitoggletool(toolbar_object, ...
    'CData',iconread('tool_zoom_in.png'), ...
    'TooltipString','Zoom', ...
    'Enable','off',...
    'ClickedCallBack',@zoomclickedcallback);
pan_toggle = uitoggletool(toolbar_object, ...
    'CData',iconread('tool_hand.png'), ...
    'TooltipString','Pan', ...
    'Enable','off',...
    'ClickedCallBack',@panclickedcallback);

% Create uREPET and save toggle button on toolbar
urepet_toggle = uitoggletool(toolbar_object, ...
    'Separator','On', ...
    'CData',urepeticon, ...
    'TooltipString','uREPET', ...
    'Enable','off');
save_toggle = uitoggletool(toolbar_object, ...
    'CData',iconread('file_save.png'), ...
    'TooltipString','Save', ...
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

% Initialize the audio player (for the figure's close request callback)
audio_player = audioplayer(0,80);

% Make the figure visible
figure_object.Visible = 'on';

    % Clicked callback function for the open toggle button
    function openclickedcallback(~,~)
        
        % Change the toggle button state to off
        open_toggle.State = 'off';
        
        % Remove the figure's close request callback so that it allows
        % all the other objects to get created before it can get closed
        figure_object.CloseRequestFcn = '';
        
        % Change the pointer symbol while the figure is busy
        figure_object.Pointer = 'watch';
        
        % Open file selection dialog box; return if cancel
        [audio_name,audio_path] = uigetfile({'*.wav';'*.mp3'}, ...
            'Select WAVE or MP3 File to Open');
        if isequal(audio_name,0) || isequal(audio_path,0)
            figure_object.CloseRequestFcn = @figurecloserequestfcn;
            return
        end
        
        % Clear all the (old) axes and hide them
        cla(signal_axes)
        signal_axes.Visible = 'off';
        cla(spectrogram_axes)
        spectrogram_axes.Visible = 'off';
        
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
        for channel_index = 1:number_channels
            audio_cqt{channel_index} ...
                = cqt(audio_signal(:,channel_index),octave_resolution,sample_rate,minimum_frequency,maximum_frequency);
            audio_spectrogram = cat(3,audio_spectrogram,abs(audio_cqt{channel_index}.c));
        end
        
        % Number of frequency channels and time frames
        [number_frequencies,number_times,~] = size(audio_spectrogram);
        
        % True maximum frequency in Hz
        maximum_frequency = minimum_frequency*2.^((number_frequencies-1)/octave_resolution);
        
        % Time range in seconds
        time_range = [1,number_times]/number_times*number_samples/sample_rate;
        
        % Display the audio spectrogram (in dB, averaged over the channels)
        % and make it unable to capture mouse clicks
        % (compensating for the buggy padding that the log scale is adding)
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
        spectrogram_axes.UserData = NaN;
        spectrogram_axes.ButtonDownFcn = @spectrogramaxesbuttondownfcn;
        drawnow
        
        % Initialize the selection object as an array for graphic objects
        number_lines = 4;
        selection_object = gobjects(number_lines,1);

        % Create object for playing audio
        audio_player = audioplayer(audio_signal,sample_rate);
        
        % Set a play line and a select line on the signal axes
        selectline(signal_axes)
        playline(signal_axes,audio_player,play_toggle);
        
        % Add clicked callback function to the play toggle button
        play_toggle.ClickedCallback = {@playclickedcallback,audio_player,signal_axes};
        
        % Enable the save and parameters toggle buttons
        play_toggle.Enable = 'on';
        select_toggle.Enable = 'on';
        zoom_toggle.Enable = 'on';
        pan_toggle.Enable = 'on';
        
        % Change the select toggle button states to on
        select_toggle.State = 'on';
        
        % Add the figure's close request callback back
        figure_object.CloseRequestFcn = @figurecloserequestfcn;
        
        % Change the pointer symbol back
        figure_object.Pointer = 'arrow';
        
        % Mouse-click callback for the axes
        function spectrogramaxesbuttondownfcn(~,~)
            
            % Location of the mouse pointer
            current_point = spectrogram_axes.CurrentPoint;
            
            % If the current point is out of the plot limits, return
            if current_point(1,1) < time_range(1) || current_point(1,1) > time_range(2) || ...
                    current_point(1,2) < minimum_frequency || current_point(1,2) > maximum_frequency
                return
            end
            
            % Current figure handle
            figure_object = gcf;
            
            % Mouse selection type
            selection_type = figure_object.SelectionType;
            
            % If click left mouse button
            if strcmp(selection_type,'normal')
                
                % If not empty, delete the selectiong object
                if ~isempty(selection_object)
                    delete(selection_object)
                end
                
                % Create the lines for the selection object
                for line_index = 1:number_lines
                    selection_object(line_index) = line(spectrogram_axes, ...
                        current_point(1,1)*[1,1],current_point(1,2)*[1,1], ...
                        'Color','k', ...
                        'ButtonDownFcn',@linebuttondownfcn);
                end
                
                % Change the pointer when the mouse moves over the lines, 
                % the spectrogram axes, and the figure object
                enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','hand');
                for line_index = 1:number_lines 
                    iptSetPointerBehavior(selection_object(line_index),enterFcn);
                end
                iptSetPointerBehavior(spectrogram_axes,enterFcn);
                iptSetPointerBehavior(figure_object,enterFcn);
                iptPointerManager(figure_object);
                
                % Add window button motion and up callback functions to the
                % figure
                figure_object.WindowButtonMotionFcn = {@figurewindowbuttonmotionfcn,select_line(1)};
                figure_object.WindowButtonUpFcn = @figurewindowbuttonupfcn;

                % Update the spectrogram axes' user data
                spectrogram_axes.UserData = [current_point(1,1)*[1,1],current_point(1,2)*[1,1]];
                
            end
            
            % ...
            function linebuttondownfcn(~,~)
                
                rand
                
            end
            
        end
        
        

        
        return
        
        
        background_or_foreground = 'b';                                             % Initial recovering background (or foreground)
        max_number_repetitions = 5;                                                 % Initial max number of repetitions
        min_time_separation = 1;                                                    % Initial min time separation between repetitions (in seconds)
        min_frequency_separation = 1;                                               % Initial min frequency separation between repetitions (in semitones)
        
        
        
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

    % Clicked callback function for the select toggle button
    function selectclickedcallback(~,~)
        
        % Keep the select toggle button state to on and change the zoom and
        % pan toggle button states to off
        select_toggle.State = 'on';
        zoom_toggle.State = 'off';
        pan_toggle.State = 'off';
        
        % Turn the zoom off
        zoom off
        
        % Turn the pan off
        pan off
        
    end

    % Clicked callback function for the zoom toggle button
    function zoomclickedcallback(~,~)
        
        % Keep the zoom toggle button state to on and change the select and
        % pan toggle button states to off
        select_toggle.State = 'off';
        zoom_toggle.State = 'on';
        pan_toggle.State = 'off';
        
        % Make the zoom enable on the figure
        zoom_object = zoom(figure_object);
        zoom_object.Enable = 'on';
        
        % Set the zoom for the x-axis only on the signal axes
        setAxesZoomConstraint(zoom_object,signal_axes,'x');
        
        % Turn the pan off
        pan off
        
    end

    % Clicked callback function for the pan toggle button
    function panclickedcallback(~,~)
        
        % Keep the pan toggle button state to on and change the select and
        % zoom toggle button states to off
        select_toggle.State = 'off';
        zoom_toggle.State = 'off';
        pan_toggle.State = 'on';
        
        % Turn the zoom off
        zoom off
        
        % Make the pan enable on the figure
        pan_object = pan(figure_object);
        pan_object.Enable = 'on';
        
        % Set the pan for the x-axis only on the signal axes
        setAxesPanConstraint(pan_object,signal_axes,'x');
        
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


%     function saveclickedcallback(~,~)
%         
%         if isempty(x)                                                       % Return if no input/output
%             return
%         end
%         
%         [filename2,pathname] = uiputfile( ...                               % Open standard dialog box for saving files
%             {'*.wav', 'WAVE files (*.wav)'; ...
%             '*.mp3', 'MP3 files (*.mp3)'}, ...
%             'Save the audio file');
%         if isequal(filename2,0)                                             % Return if user selects Cancel
%             return
%         end
%         
%         p = size(x,2);                                                      % Number of channels
%         x = [];
%         for k = 1:p                                                         % Loop over the channels
%             Xcqk = Xcq{k};
%             x = cat(2,x,icqt(Xcqk));
%         end
%         file = fullfile(pathname,filename2);                                % Build full file name from parts
%         audiowrite(file,x,fs)                                               % Write audio file
%         
%     end
% 
%     function parametersclickedcallback(~,~)
%         
%         prompt = {'Recovering background (b) or foreground (f):', ...
%             'Max number of repetitions:', ...
%             'Min time separation between repetitions (in seconds):', ...
%             'Min frequency separation between repetitions (in semitones):'};
%         dlg_title = 'Parameters';
%         num_lines = 1;
%         def = {background_or_foreground, ...
%             num2str(max_number_repetitions), ...
%             num2str(min_time_separation), ...
%             num2str(min_frequency_separation)};
%         answer = inputdlg(prompt,dlg_title,num_lines,def);                  % Create and open input dialog box
%         if isempty(answer)                                                  % Return if user selects Cancel
%             return
%         end
%         
%         background_or_foreground = answer{1};
%         max_number_repetitions = str2double(answer{2});
%         min_time_separation = str2double(answer{3});
%         min_frequency_separation = str2double(answer{4});
%         
%     end

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
function playline(signal_axes,audio_player,play_toggle)

% Play and stop icons from the play toggle buttons' user data
play_icon = play_toggle.UserData.PlayIcon;
stop_icon = play_toggle.UserData.StopIcon;

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
        
        % Change the play toggle button icon to a stop icon and the tooltip 
        % to 'Stop'
        play_toggle.CData = stop_icon;
        play_toggle.TooltipString = 'Stop';
        
        % Get the select limits from the signal axes' user data
        select_limits = signal_axes.UserData.SelectXLim;
        
        % Create a play line on the signal axes
        play_line = line(signal_axes,select_limits(1)*[1,1],[-1,1]);
        
    end

    % Function to execute one time when playback stops
    function audioplayerstopfcn(~,~)
        
        % Change the play toggle button icon to a play icon and the tooltip 
        % to 'Play'
        play_toggle.CData = play_icon;
        play_toggle.TooltipString = 'Play';
        
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

% Clicked callback function for the play toggle button
function playclickedcallback(object_handle,~,audio_player,signal_axes)

% Change the toggle button state to off
object_handle.State = 'off';

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
