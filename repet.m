classdef repet
    % repet REpeating Pattern Extraction Technique (REPET) class
    %   Repetition is a fundamental element in generating and perceiving 
    %   structure. In audio, mixtures are often composed of structures 
    %   where a repeating background signal is superimposed with a varying 
    %   foreground signal (e.g., a singer overlaying varying vocals on a 
    %   repeating accompaniment or a varying speech signal mixed up with a 
    %   repeating background noise). On this basis, we present the 
    %   REpeating Pattern Extraction Technique (REPET), a simple approach 
    %   for separating the repeating background from the non-repeating 
    %   foreground in an audio mixture. The basic idea is to find the 
    %   repeating elements in the mixture, derive the underlying repeating 
    %   models, and extract the repeating  background by comparing the 
    %   models to the mixture. Unlike other separation approaches, REPET 
    %   does not depend on special parameterizations, does not rely on 
    %   complex frameworks, and does not require external information. 
    %   Because it is only based on repetition, it has the advantage of 
    %   being simple, fast, blind, and therefore completely and easily 
    %   automatable.
    % 
    % repet Methods:
    %   original - REPET (original)
    %   extended - REPET extended
    %   adaptive - Adaptive REPET
    %   sim - REPET-SIM
    %   simonline - Online REPET-SIM
    % 
    % See also http://zafarrafii.com/#REPET
    % 
    % References:
    %   Zafar Rafii, Antoine Liutkus, and Bryan Pardo. "REPET for 
    %   Background/Foreground Separation in Audio," Blind Source 
    %   Separation, chapter 14, pages 395-411, Springer Berlin Heidelberg, 
    %   2014.
    %   
    %   Zafar Rafii and Bryan Pardo. "Online REPET-SIM for Real-time Speech 
    %   Enhancement," 38th International Conference on Acoustics, Speech 
    %   and Signal Processing, Vancouver, BC, Canada, May 26-31, 2013.
    %   
    %   Zafar Rafii and Bryan Pardo. "Audio Separation System and Method," 
    %   US20130064379 A1, US 13/612,413, March 14, 2013.
    %   
    %   Zafar Rafii and Bryan Pardo. "REpeating Pattern Extraction 
    %   Technique (REPET): A Simple Method for Music/Voice Separation," 
    %   IEEE Transactions on Audio, Speech, and Language Processing, volume 
    %   21, number 1, pages 71-82, January, 2013.
    %   
    %   Zafar Rafii and Bryan Pardo. "Music/Voice Separation using the 
    %   Similarity Matrix," 13th International Society on Music Information 
    %   Retrieval, Porto, Portugal, October 8-12, 2012.
    %   
    %   Antoine Liutkus, Zafar Rafii, Roland Badeau, Bryan Pardo, and Gaël 
    %   Richard. "Adaptive Filtering for Music/Voice Separation Exploiting 
    %   the Repeating Musical Structure," 37th International Conference on 
    %   Acoustics, Speech and Signal Processing, Kyoto, Japan, March 25-30, 
    %   2012.
    %       
    %   Zafar Rafii and Bryan Pardo. "A Simple Music/Voice Separation 
    %   Method based on the Extraction of the Repeating Musical Structure," 
    %   36th International Conference on Acoustics, Speech and Signal 
    %   Processing, Prague, Czech Republic, May 22-27, 2011.
    %   
    % Author:
    %   Zafar Rafii
    %   zafarrafii@gmail.com
    %   http://zafarrafii.com
    %   https://github.com/zafarrafii
    %   https://www.linkedin.com/in/zafarrafii/
    %   05/10/18
    
    % Defined properties
    properties (Access = public, Constant = false, Hidden = false)
        % Window length in seconds for the STFT (audio stationary around 40 
        % milliseconds)
        window_duration = 0.040;
        
        % Cutoff frequency in Hz for the dual high-pass filter of the
        % foreground (vocals are rarely below 100 Hz)
        cutoff_frequency = 100;
        
        % Period range in seconds for the beat spectrum (for REPET, REPET 
        % extented, and adaptive REPET)
        period_range = [1,10];
        
        % Segmentation length and step in seconds (for REPET extented and 
        % adaptive REPET)
        segment_length = 10;
        segment_step = 5;
        
        % Filter order for the median filter (for adaptive REPET)
        filter_order = 5;
        
        % Minimal threshold for two similar frames in [0,1], minimal 
        % distance between two similar frames in seconds, and maximal 
        % number of similar frames for one frame (for REPET-SIM and online 
        % REPET-SIM)
        similarity_threshold = 0;
        similarity_distance = 1;
        similarity_number = 100;
        
        % Buffer length in seconds (for online REPET-SIM)
        buffer_length = 5;
            
    end
    
    % Main methods
    methods (Access = public, Hidden = false, Static = true)
        
        function background_signal = original(audio_signal,sample_rate)
            % repet REPET (original)
            %   The original REPET aims at identifying and extracting the 
            %   repeating patterns in an audio mixture, by estimating a 
            %   period of the underlying repeating structure and modeling a 
            %   segment of the periodically repeating background.
            %   
            %   background_signal = repet.original(audio_signal,sample_rate);
            %   
            %   Arguments:
            %       audio_signal: audio signal [number_samples,number_channels]
            %       sample_rate: sample rate in Hz
            %       background_signal: background signal [number_samples,number_channels]
            %   
            %   Example: Estimate the background and foreground signals, and display their spectrograms
            %       % Read the audio signal and return the sample rate
            %       [audio_signal,sample_rate] = audioread('audio_file.wav');
            %       
            %       % Estimate the background signal and infer the foreground signal
            %       background_signal = repet.original(audio_signal,sample_rate);
            %       foreground_signal = audio_signal-background_signal;
            %       
            %       % Write the background and foreground signals
            %       audiowrite('background_signal.wav',background_signal,sample_rate)
            %       audiowrite('foreground_signal.wav',foreground_signal,sample_rate)
            %       
            %       % Compute the audio, background, and foreground spectrograms
            %       window_length = 2^nextpow2(0.04*sample_rate);
            %       step_length = window_length/2;
            %       window_function = hamming(window_length,'periodic');
            %       audio_spectrogram = abs(spectrogram(mean(audio_signal,2),window_length,window_length-step_length));
            %       background_spectrogram = abs(spectrogram(mean(background_signal,2),window_length,window_length-step_length));
            %       foreground_spectrogram = abs(spectrogram(mean(foreground_signal,2),window_length,window_length-step_length));
            %       
            %       % Display the audio, background, and foreground spectrograms (up to 5kHz)
            %       figure
            %       subplot(3,1,1), imagesc(db(audio_spectrogram(2:window_length/8,:))), axis xy
            %       title('Audio Spectrogram (dB)')
            %       xticks(round((1:floor(length(audio_signal)/sample_rate))*sample_rate/step_length))
            %       xticklabels(1:floor(length(audio_signal)/sample_rate)), xlabel('Time (s)')
            %       yticks(round((1e3:1e3:sample_rate/8)/sample_rate*window_length))
            %       yticklabels(1:sample_rate/8*1e-3), ylabel('Frequency (kHz)')
            %       set(gca,'FontSize',30)
            %       subplot(3,1,2), imagesc(db(background_spectrogram(2:window_length/8,:))), axis xy
            %       title('Background Spectrogram (dB)')
            %       xticks(round((1:floor(length(audio_signal)/sample_rate))*sample_rate/step_length))
            %       xticklabels(1:floor(length(audio_signal)/sample_rate)), xlabel('Time (s)')
            %       yticks(round((1e3:1e3:sample_rate/8)/sample_rate*window_length))
            %       yticklabels(1:sample_rate/8*1e-3), ylabel('Frequency (kHz)')
            %       set(gca,'FontSize',30)
            %       subplot(3,1,3), imagesc(db(foreground_spectrogram(2:window_length/8,:))), axis xy
            %       title('Foreground Spectrogram (dB)')
            %       xticks(round((1:floor(length(audio_signal)/sample_rate))*sample_rate/step_length))
            %       xticklabels(1:floor(length(audio_signal)/sample_rate)), xlabel('Time (s)')
            %       yticks(round((1e3:1e3:sample_rate/8)/sample_rate*window_length))
            %       yticklabels(1:sample_rate/8*1e-3), ylabel('Frequency (kHz)')
            %       set(gca,'FontSize',30)
            %       colormap(jet)
            %       
            %   See also repet.extended, repet.adaptive, repet.sim, repet.simonline
            
            %%% Fourier analysis
            % STFT parameters
            [window_length,window_function,step_length] = repet.stftparameters(repet.window_duration,sample_rate);
            
            % Number of samples and channels
            [number_samples,number_channels] = size(audio_signal);
            
            % Initialize the STFT
            audio_stft = [];
            
            % Loop over the channels
            for channel_index = 1:number_channels
                
                % STFT of the current channel
                audio_stft1 = repet.stft(audio_signal(:,channel_index),window_function,step_length);
                
                % Concatenate the STFTs
                audio_stft = cat(3,audio_stft,audio_stft1);
                
            end
            
            % Magnitude spectrogram (with DC component and without mirrored 
            % frequencies)
            audio_spectrogram = abs(audio_stft(1:window_length/2+1,:,:));
            
            %%% Repetition/periodicity analysis
            % Beat spectrum of the mean power spectrograms (squared to 
            % emphasize peaks of periodicitiy)
            beat_spectrum = repet.beatspectrum(mean(audio_spectrogram.^2,3));
            
            % Period range in time frames for the beat spectrum
            period_range = round(repet.period_range*sample_rate/step_length);
            
            % Repeating period in time frames given the period range
            repeating_period = repet.periods(beat_spectrum,period_range);
            
            %%% Background estimation
            % Cutoff frequency in frequency channels for the dual high-pass 
            % filter of the foreground
            cutoff_frequency = ceil(repet.cutoff_frequency*(window_length-1)/sample_rate);
            
            % Initialize the background signal
            background_signal = zeros(number_samples,number_channels);
            
            % Loop over the channels
            for channel_index = 1:number_channels
                
                % Repeating mask for the current channel
                repeating_mask = repet.mask(audio_spectrogram(:,:,channel_index),repeating_period);
                
                % High-pass filtering of the dual foreground
                repeating_mask(2:cutoff_frequency+1,:) = 1;
                
                % Mirror the frequency channels
                repeating_mask = cat(1,repeating_mask,flipud(repeating_mask(2:end-1,:)));
                
                % Estimated repeating background for the current channel
                background_signal1 = repet.istft(repeating_mask.*audio_stft(:,:,channel_index),window_function,step_length);
                
                % Truncate to the original number of samples
                background_signal(:,channel_index) = background_signal1(1:number_samples);
                
            end
            
        end
        
        function background_signal = extended(audio_signal,sample_rate)
            % extended REPET extended
            %   The original REPET can be easily extended to handle varying 
            %   repeating structures, by simply applying the method along 
            %   time, on individual segments or via a sliding window.
            %   
            %   background_signal = repet.extended(audio_signal,sample_rate);
            %   
            %   Arguments:
            %       audio_signal: audio signal [number_samples,number_channels]
            %       sample_rate: sample rate in Hz
            %       background_signal: background signal [number_samples,number_channels]
            %   
            %   Example: Compute and display the spectrogram of an audio file
            %       % Read the audio signal and return the sample rate
            %       [audio_signal,sample_rate] = audioread('audio_file.wav');
            %       
            %       % Estimate the background signal and infer the foreground signal
            %       background_signal = repet.extended(audio_signal,sample_rate);
            %       foreground_signal = audio_signal-background_signal;
            %       
            %       % Write the background and foreground signals
            %       audiowrite('background_signal.wav',background_signal,sample_rate)
            %       audiowrite('foreground_signal.wav',foreground_signal,sample_rate)
            %       
            %       % Compute the audio, background, and foreground spectrograms
            %       window_length = 2^nextpow2(0.04*sample_rate);
            %       step_length = window_length/2;
            %       window_function = hamming(window_length,'periodic');
            %       audio_spectrogram = abs(spectrogram(mean(audio_signal,2),window_length,window_length-step_length));
            %       background_spectrogram = abs(spectrogram(mean(background_signal,2),window_length,window_length-step_length));
            %       foreground_spectrogram = abs(spectrogram(mean(foreground_signal,2),window_length,window_length-step_length));
            %       
            %       % Display the audio, background, and foreground spectrograms (up to 5kHz)
            %       figure
            %       subplot(3,1,1), imagesc(db(audio_spectrogram(2:window_length/8,:))), axis xy
            %       title('Audio Spectrogram (dB)')
            %       xticks(round((1:floor(length(audio_signal)/sample_rate))*sample_rate/step_length))
            %       xticklabels(1:floor(length(audio_signal)/sample_rate)), xlabel('Time (s)')
            %       yticks(round((1e3:1e3:sample_rate/8)/sample_rate*window_length))
            %       yticklabels(1:sample_rate/8*1e-3), ylabel('Frequency (kHz)')
            %       set(gca,'FontSize',30)
            %       subplot(3,1,2), imagesc(db(background_spectrogram(2:window_length/8,:))), axis xy
            %       title('Background Spectrogram (dB)')
            %       xticks(round((1:floor(length(audio_signal)/sample_rate))*sample_rate/step_length))
            %       xticklabels(1:floor(length(audio_signal)/sample_rate)), xlabel('Time (s)')
            %       yticks(round((1e3:1e3:sample_rate/8)/sample_rate*window_length))
            %       yticklabels(1:sample_rate/8*1e-3), ylabel('Frequency (kHz)')
            %       set(gca,'FontSize',30)
            %       subplot(3,1,3), imagesc(db(foreground_spectrogram(2:window_length/8,:))), axis xy
            %       title('Foreground Spectrogram (dB)')
            %       xticks(round((1:floor(length(audio_signal)/sample_rate))*sample_rate/step_length))
            %       xticklabels(1:floor(length(audio_signal)/sample_rate)), xlabel('Time (s)')
            %       yticks(round((1e3:1e3:sample_rate/8)/sample_rate*window_length))
            %       yticklabels(1:sample_rate/8*1e-3), ylabel('Frequency (kHz)')
            %       set(gca,'FontSize',30)
            %       colormap(jet)
            %
            %   See also repet.original, repet.adaptive, repet.sim, repet.simonline
            
            %%%% Derived parameters
            % Segmentation length, step, and overlap in samples
            segment_length = round(repet.segment_length*sample_rate);
            segment_step = round(repet.segment_step*sample_rate);
            segment_overlap = segment_length-segment_step;
            
            % Number of samples and channels
            [number_samples,number_channels] = size(audio_signal);
            
            % One segment if the signal is too short
            if number_samples < segment_length+segment_step
                number_segments = 1;
            else
                % Number of segments (the last one could be longer)
                number_segments = 1+floor((number_samples-segment_length)/segment_step);
                
                % Triangular window for the overlapping parts
                segment_window = triang(2*segment_overlap);
                
            end
            
            % STFT parameters
            [window_length,window_function,step_length] = repet.stftparameters(repet.window_duration,sample_rate);
            
            % Period range in time frames for the beat spectrum
            period_range = round(repet.period_range*sample_rate/step_length);
            
            % Cutoff frequency in frequency channels for the dual high-pass 
            % filter of the foreground
            cutoff_frequency = ceil(repet.cutoff_frequency*(window_length-1)/sample_rate);
            
            %%%% Segmentation
            % Initialize background signal
            background_signal = zeros(number_samples,number_channels);
            
            % Open wait bar
            wait_bar = waitbar(0,'REPET extended');
            
            % Loop over the segments
            for segment_index = 1:number_segments
                
                % Case one segment
                if number_segments == 1
                    audio_segment = audio_signal;
                    segment_length = number_samples;
                else
                    
                    % Sample index for the segment
                    sample_index = (segment_index-1)*segment_step;
                    
                    % Case first segments (same length)
                    if segment_index < number_segments
                        audio_segment = audio_signal(sample_index+1:sample_index+segment_length,:);
                    
                    % Case last segment (could be longer)
                    elseif segment_index == number_segments
                        audio_segment = audio_signal(sample_index+1:number_samples,:);
                        segment_length = length(audio_segment);
                    end
                    
                end
                
                %%% Fourier analysis
                % Initialize STFT
                audio_stft = [];
                
                % Loop over the channels
                for channel_index = 1:number_channels
                    
                    % STFT of the current channel
                    audio_stft1 = repet.stft(audio_segment(:,channel_index),window_function,step_length);
                    
                    % Concatenate the STFTs
                    audio_stft = cat(3,audio_stft,audio_stft1);
                    
                end
                
                % Magnitude spectrogram (with DC component and without 
                % mirrored frequencies)
                audio_spectrogram = abs(audio_stft(1:window_length/2+1,:,:));
                
                %%% Repetition/periodicity analysis
                % Beat spectrum of the mean power spectrograms (squared to 
                % emphasize peaks of periodicitiy)
                beat_spectrum = repet.beatspectrum(mean(audio_spectrogram.^2,3));
                
                % Repeating period in time frames given the period range
                repeating_period = repet.periods(beat_spectrum,period_range);
                
                %%% Background estimation
                % Initialize the background segment
                background_segment = zeros(segment_length,number_channels);
                
                % Loop over the channels
                for channel_index = 1:number_channels
                    
                    % Repeating mask for the current channel
                    repeating_mask = repet.mask(audio_spectrogram(:,:,channel_index),repeating_period);
                    
                    % High-pass filtering of the dual foreground
                    repeating_mask(2:cutoff_frequency+1,:) = 1;
                    
                    % Mirror the frequency channels
                    repeating_mask = cat(1,repeating_mask,flipud(repeating_mask(2:end-1,:)));
                    
                    % Estimated repeating background for the current channel
                    background_segment1 = repet.istft(repeating_mask.*audio_stft(:,:,channel_index),window_function,step_length);
                    
                    % Truncate to the original number of samples
                    background_segment(:,channel_index) = background_segment1(1:segment_length);
                    
                end
                
                %%%% Combination
                % Case one segment
                if number_segments == 1
                    background_signal = background_segment;
                else
                    
                    % Case first segment
                    if segment_index == 1
                        background_signal(1:segment_length,:) ...
                            = background_signal(1:segment_length,:) + background_segment;
                        
                    % Case last segments
                    elseif segment_index <= number_segments
                        
                        % Half windowing of the overlap part of the background signal on the right
                        background_signal(sample_index+1:sample_index+segment_overlap,:) ...
                            = background_signal(sample_index+1:sample_index+segment_overlap,:).*segment_window(segment_overlap+1:2*segment_overlap);
                        
                        % Half windowing of the overlap part of the background segment on the left
                        background_segment(1:segment_overlap,:) ...
                            = background_segment(1:segment_overlap,:).*segment_window(1:segment_overlap);
                        background_signal(sample_index+1:sample_index+segment_length,:) ...
                            = background_signal(sample_index+1:sample_index+segment_length,:) + background_segment;
                        
                    end
                end
                
                % Update wait bar
                waitbar(segment_index/number_segments,wait_bar);
                
            end
            
            % Close wait bar
            close(wait_bar)
            
        end
        
        function background_signal = adaptive(audio_signal,sample_rate)
            % adaptive Adaptive REPET
            %   The original REPET works well when the repeating background 
            %   is relatively stable (e.g., a verse or the chorus in a 
            %   song); however, the repeating background can also vary over 
            %   time (e.g., a verse followed by the chorus in the song). 
            %   The adaptive REPET is an extension of the original REPET 
            %   that can handle varying repeating structures, by estimating 
            %   the time-varying repeating periods and extracting the 
            %   repeating background locally, without the need for 
            %   segmentation or windowing.
            %   
            %   background_signal = repet.adaptive(audio_signal,sample_rate);
            %   
            %   Arguments:
            %       audio_signal: audio signal [number_samples,number_channels]
            %       sample_rate: sample rate in Hz
            %       background_signal: background signal [number_samples,number_channels]
            %   
            %   Example: Compute and display the spectrogram of an audio file
            %       % Read the audio signal and return the sample rate
            %       [audio_signal,sample_rate] = audioread('audio_file.wav');
            %       
            %       % Estimate the background signal and infer the foreground signal
            %       background_signal = repet.adaptive(audio_signal,sample_rate);
            %       foreground_signal = audio_signal-background_signal;
            %       
            %       % Write the background and foreground signals
            %       audiowrite('background_signal.wav',background_signal,sample_rate)
            %       audiowrite('foreground_signal.wav',foreground_signal,sample_rate)
            %       
            %       % Compute the audio, background, and foreground spectrograms
            %       window_length = 2^nextpow2(0.04*sample_rate);
            %       step_length = window_length/2;
            %       window_function = hamming(window_length,'periodic');
            %       audio_spectrogram = abs(spectrogram(mean(audio_signal,2),window_length,window_length-step_length));
            %       background_spectrogram = abs(spectrogram(mean(background_signal,2),window_length,window_length-step_length));
            %       foreground_spectrogram = abs(spectrogram(mean(foreground_signal,2),window_length,window_length-step_length));
            %       
            %       % Display the audio, background, and foreground spectrograms (up to 5kHz)
            %       figure
            %       subplot(3,1,1), imagesc(db(audio_spectrogram(2:window_length/8,:))), axis xy
            %       title('Audio Spectrogram (dB)')
            %       xticks(round((1:floor(length(audio_signal)/sample_rate))*sample_rate/step_length))
            %       xticklabels(1:floor(length(audio_signal)/sample_rate)), xlabel('Time (s)')
            %       yticks(round((1e3:1e3:sample_rate/8)/sample_rate*window_length))
            %       yticklabels(1:sample_rate/8*1e-3), ylabel('Frequency (kHz)')
            %       set(gca,'FontSize',30)
            %       subplot(3,1,2), imagesc(db(background_spectrogram(2:window_length/8,:))), axis xy
            %       title('Background Spectrogram (dB)')
            %       xticks(round((1:floor(length(audio_signal)/sample_rate))*sample_rate/step_length))
            %       xticklabels(1:floor(length(audio_signal)/sample_rate)), xlabel('Time (s)')
            %       yticks(round((1e3:1e3:sample_rate/8)/sample_rate*window_length))
            %       yticklabels(1:sample_rate/8*1e-3), ylabel('Frequency (kHz)')
            %       set(gca,'FontSize',30)
            %       subplot(3,1,3), imagesc(db(foreground_spectrogram(2:window_length/8,:))), axis xy
            %       title('Foreground Spectrogram (dB)')
            %       xticks(round((1:floor(length(audio_signal)/sample_rate))*sample_rate/step_length))
            %       xticklabels(1:floor(length(audio_signal)/sample_rate)), xlabel('Time (s)')
            %       yticks(round((1e3:1e3:sample_rate/8)/sample_rate*window_length))
            %       yticklabels(1:sample_rate/8*1e-3), ylabel('Frequency (kHz)')
            %       set(gca,'FontSize',30)
            %       colormap(jet)
            %
            %   See also repet.original, repet.extended, repet.sim, repet.simonline
            
            %%% Fourier analysis
            % STFT parameters
            [window_length,window_function,step_length] = repet.stftparameters(repet.window_duration,sample_rate);
            
            % Number of samples and channels
            [number_samples,number_channels] = size(audio_signal);
            
            % Initialize the STFT
            audio_stft = [];
            
            % Loop over the channels
            for channel_index = 1:number_channels
                
                % STFT of the current channel
                audio_stft1 = repet.stft(audio_signal(:,channel_index),window_function,step_length);
                
                % Concatenate the STFTs
                audio_stft = cat(3,audio_stft,audio_stft1);
                
            end
            
            % Magnitude spectrogram (with DC component and without mirrored 
            % frequencies)
            audio_spectrogram = abs(audio_stft(1:window_length/2+1,:,:));
            
            %%% Repetition/periodicity analysis
            % Segment length and step in time frames for the beat 
            % spectrogram
            segment_length = round(repet.segment_length*sample_rate/step_length);
            segment_step = round(repet.segment_step*sample_rate/step_length);
            
            % Beat spectrogram of the mean power spectrograms (squared to 
            % emphasize peaks of periodicitiy)
            beat_spectrogram = repet.beatspectrogram(mean(audio_spectrogram.^2,3),segment_length,segment_step);
            
            % Period range in time frames for the beat spectrogram 
            period_range = round(repet.period_range*sample_rate/step_length);
            
            % Repeating period in time frames given the period range
            repeating_periods = repet.periods(beat_spectrogram,period_range);
            
            %%% Background estimation
            % Cutoff frequency in frequency channels for the dual high-pass 
            % filter of the foreground
            cutoff_frequency = ceil(repet.cutoff_frequency*(window_length-1)/sample_rate);
            
            % Initialize the background signal
            background_signal = zeros(number_samples,number_channels);
            
            % Loop over the channels
            for channel_index = 1:number_channels
                
                % Repeating mask for the current channel
                repeating_mask = repet.adaptivemask(audio_spectrogram(:,:,channel_index),repeating_periods,repet.filter_order);
                
                % High-pass filtering of the dual foreground
                repeating_mask(2:cutoff_frequency+1,:) = 1;
                
                % Mirror the frequency channels
                repeating_mask = cat(1,repeating_mask,flipud(repeating_mask(2:end-1,:)));
                
                % Estimated repeating background for the current channel
                background_signal1 = repet.istft(repeating_mask.*audio_stft(:,:,channel_index),window_function,step_length);
                
                % Truncate to the original number of samples
                background_signal(:,channel_index) = background_signal1(1:number_samples);
                
            end
            
        end
        
        function background_signal = sim(audio_signal,sample_rate)
            % sim REPET-SIM
            %   The REPET methods work well when the repeating background 
            %   has periodically repeating patterns (e.g., jackhammer 
            %   noise); however, the repeating patterns can also happen 
            %   intermittently or without a global or local periodicity 
            %   (e.g., frogs by a pond). REPET-SIM is a generalization of 
            %   REPET that can also handle non-periodically repeating 
            %   structures, by using a similarity matrix to identify the 
            %   repeating elements.
            %   
            %   background_signal = repet.sim(audio_signal,sample_rate);
            %   
            %   Arguments:
            %       audio_signal: audio signal [number_samples,number_channels]
            %       sample_rate: sample rate in Hz
            %       background_signal: background signal [number_samples,number_channels]
            %   
            %   Example: Compute and display the spectrogram of an audio file
            %       % Read the audio signal and return the sample rate
            %       [audio_signal,sample_rate] = audioread('audio_file.wav');
            %       
            %       % Estimate the background signal and infer the foreground signal
            %       background_signal = repet.sim(audio_signal,sample_rate);
            %       foreground_signal = audio_signal-background_signal;
            %       
            %       % Write the background and foreground signals
            %       audiowrite('background_signal.wav',background_signal,sample_rate)
            %       audiowrite('foreground_signal.wav',foreground_signal,sample_rate)
            %       
            %       % Compute the audio, background, and foreground spectrograms
            %       window_length = 2^nextpow2(0.04*sample_rate);
            %       step_length = window_length/2;
            %       window_function = hamming(window_length,'periodic');
            %       audio_spectrogram = abs(spectrogram(mean(audio_signal,2),window_length,window_length-step_length));
            %       background_spectrogram = abs(spectrogram(mean(background_signal,2),window_length,window_length-step_length));
            %       foreground_spectrogram = abs(spectrogram(mean(foreground_signal,2),window_length,window_length-step_length));
            %       
            %       % Display the audio, background, and foreground spectrograms (up to 5kHz)
            %       figure
            %       subplot(3,1,1), imagesc(db(audio_spectrogram(2:window_length/8,:))), axis xy
            %       title('Audio Spectrogram (dB)')
            %       xticks(round((1:floor(length(audio_signal)/sample_rate))*sample_rate/step_length))
            %       xticklabels(1:floor(length(audio_signal)/sample_rate)), xlabel('Time (s)')
            %       yticks(round((1e3:1e3:sample_rate/8)/sample_rate*window_length))
            %       yticklabels(1:sample_rate/8*1e-3), ylabel('Frequency (kHz)')
            %       set(gca,'FontSize',30)
            %       subplot(3,1,2), imagesc(db(background_spectrogram(2:window_length/8,:))), axis xy
            %       title('Background Spectrogram (dB)')
            %       xticks(round((1:floor(length(audio_signal)/sample_rate))*sample_rate/step_length))
            %       xticklabels(1:floor(length(audio_signal)/sample_rate)), xlabel('Time (s)')
            %       yticks(round((1e3:1e3:sample_rate/8)/sample_rate*window_length))
            %       yticklabels(1:sample_rate/8*1e-3), ylabel('Frequency (kHz)')
            %       set(gca,'FontSize',30)
            %       subplot(3,1,3), imagesc(db(foreground_spectrogram(2:window_length/8,:))), axis xy
            %       title('Foreground Spectrogram (dB)')
            %       xticks(round((1:floor(length(audio_signal)/sample_rate))*sample_rate/step_length))
            %       xticklabels(1:floor(length(audio_signal)/sample_rate)), xlabel('Time (s)')
            %       yticks(round((1e3:1e3:sample_rate/8)/sample_rate*window_length))
            %       yticklabels(1:sample_rate/8*1e-3), ylabel('Frequency (kHz)')
            %       set(gca,'FontSize',30)
            %       colormap(jet)
            %
            %   See also repet.original, repet.extended, repet.adaptive, repet.simonline
            
            %%% Fourier analysis
            % STFT parameters
            [window_length,window_function,step_length] = repet.stftparameters(repet.window_duration,sample_rate);
            
            % Number of samples and channels
            [number_samples,number_channels] = size(audio_signal);
            
            % Initialize the STFT
            audio_stft = [];
            
            % Loop over the channels
            for channel_index = 1:number_channels
                
                % STFT of the current channel
                audio_stft1 = repet.stft(audio_signal(:,channel_index),window_function,step_length);
                
                % Concatenate the STFTs
                audio_stft = cat(3,audio_stft,audio_stft1);
                
            end
            
            % Magnitude spectrogram (with DC component and without mirrored 
            % frequencies)
            audio_spectrogram = abs(audio_stft(1:window_length/2+1,:,:));
            
            %%% Repetition/similarity analysis
            % Self-similarity of the mean magnitude spectrogram
            similarity_matrix = repet.similarity(mean(audio_spectrogram,3));
            
            % Similarity distance in time frames
            similarity_distance = round(repet.similarity_distance*sample_rate/step_length);
            
            % Similarity indices for all the frames
            similarity_indices = repet.indices(similarity_matrix,repet.similarity_threshold,similarity_distance,repet.similarity_number);

            %%% Background signal
            % Cutoff frequency in frequency channels for the dual high-pass 
            % filter of the foreground
            cutoff_frequency = ceil(repet.cutoff_frequency*(window_length-1)/sample_rate);
            
            % Initialize the background signal
            background_signal = zeros(number_samples,number_channels);
            
            % Loop over the channels
            for channel_index = 1:number_channels
                
                % Repeating mask for the current channel
                repeating_mask = repet.simmask(audio_spectrogram(:,:,channel_index),similarity_indices);
                
                % High-pass filtering of the dual foreground
                repeating_mask(2:cutoff_frequency+1,:) = 1;
                
                % Mirror the frequency channels
                repeating_mask = cat(1,repeating_mask,flipud(repeating_mask(2:end-1,:)));
                
                % Estimated repeating background for the current channel
                background_signal1 = repet.istft(repeating_mask.*audio_stft(:,:,channel_index),window_function,step_length);
                
                % Truncate to the original number of samples
                background_signal(:,channel_index) = background_signal1(1:number_samples);
                
            end
            
        end
        
        function background_signal = simonline(audio_signal,sample_rate)
            % simonline Online REPET-SIM
            %   REPET-SIM can be easily implemented online to handle 
            %   real-time computing, particularly for real-time speech 
            %   enhancement. The online REPET-SIM simply processes the time 
            %   frames of the mixture one after the other given a buffer 
            %   that temporally stores past frames.
            %   background_signal = repet.sim(audio_signal,sample_rate);
            %   
            %   Arguments:
            %       audio_signal: audio signal [number_samples,number_channels]
            %       sample_rate: sample rate in Hz
            %       background_signal: background signal [number_samples,number_channels]
            %   
            %   Example: Compute and display the spectrogram of an audio file
            %       % Read the audio signal and return the sample rate
            %       [audio_signal,sample_rate] = audioread('audio_file.wav');
            %       
            %       % Estimate the background signal and infer the foreground signal
            %       background_signal = repet.simonline(audio_signal,sample_rate);
            %       foreground_signal = audio_signal-background_signal;
            %       
            %       % Write the background and foreground signals
            %       audiowrite('background_signal.wav',background_signal,sample_rate)
            %       audiowrite('foreground_signal.wav',foreground_signal,sample_rate)
            %       
            %       % Compute the audio, background, and foreground spectrograms
            %       window_length = 2^nextpow2(0.04*sample_rate);
            %       step_length = window_length/2;
            %       window_function = hamming(window_length,'periodic');
            %       audio_spectrogram = abs(spectrogram(mean(audio_signal,2),window_length,window_length-step_length));
            %       background_spectrogram = abs(spectrogram(mean(background_signal,2),window_length,window_length-step_length));
            %       foreground_spectrogram = abs(spectrogram(mean(foreground_signal,2),window_length,window_length-step_length));
            %       
            %       % Display the audio, background, and foreground spectrograms (up to 5kHz)
            %       figure
            %       subplot(3,1,1), imagesc(db(audio_spectrogram(2:window_length/8,:))), axis xy
            %       title('Audio Spectrogram (dB)')
            %       xticks(round((1:floor(length(audio_signal)/sample_rate))*sample_rate/step_length))
            %       xticklabels(1:floor(length(audio_signal)/sample_rate)), xlabel('Time (s)')
            %       yticks(round((1e3:1e3:sample_rate/8)/sample_rate*window_length))
            %       yticklabels(1:sample_rate/8*1e-3), ylabel('Frequency (kHz)')
            %       set(gca,'FontSize',30)
            %       subplot(3,1,2), imagesc(db(background_spectrogram(2:window_length/8,:))), axis xy
            %       title('Background Spectrogram (dB)')
            %       xticks(round((1:floor(length(audio_signal)/sample_rate))*sample_rate/step_length))
            %       xticklabels(1:floor(length(audio_signal)/sample_rate)), xlabel('Time (s)')
            %       yticks(round((1e3:1e3:sample_rate/8)/sample_rate*window_length))
            %       yticklabels(1:sample_rate/8*1e-3), ylabel('Frequency (kHz)')
            %       set(gca,'FontSize',30)
            %       subplot(3,1,3), imagesc(db(foreground_spectrogram(2:window_length/8,:))), axis xy
            %       title('Foreground Spectrogram (dB)')
            %       xticks(round((1:floor(length(audio_signal)/sample_rate))*sample_rate/step_length))
            %       xticklabels(1:floor(length(audio_signal)/sample_rate)), xlabel('Time (s)')
            %       yticks(round((1e3:1e3:sample_rate/8)/sample_rate*window_length))
            %       yticklabels(1:sample_rate/8*1e-3), ylabel('Frequency (kHz)')
            %       set(gca,'FontSize',30)
            %       colormap(jet)
            %
            %   See also repet.original, repet.extended, repet.adaptive, repet.sim
            
            %%% Fourier analysis
            % STFT parameters
            [window_length,window_function,step_length] = repet.stftparameters(repet.window_duration,sample_rate);
            
            % Number of samples and channels
            [number_samples,number_channels] = size(audio_signal);
            
            % Initialize the STFT
            audio_stft = [];
            
            % Loop over the channels
            for channel_index = 1:number_channels
                
                % STFT of the current channel
                audio_stft1 = repet.stft(audio_signal(:,channel_index),window_function,step_length);
                
                % Concatenate the STFTs
                audio_stft = cat(3,audio_stft,audio_stft1);
                
            end
            
            %%% Repetition/similarity analysis
            % Buffer in time frames
            buffer_length = round(repet.buffer_length*sample_rate/step_length);
            
            % Similarity distance in time frames
            similarity_distance = round(repet.similarity_distance*sample_rate/step_length);
            
            % Cutoff frequency in frequency channels for the dual high-pass 
            % filter of the foreground
            cutoff_frequency = ceil(repet.cutoff_frequency*(window_length-1)/sample_rate);
            
            % Number of time frames
            number_times = size(audio_stft,2);
            
            % Initialize background STFT
            background_stft = zeros(window_length,number_times,number_channels);
            
            % Open the wait bar
            wait_bar = waitbar(0,'Online REPET-SIM');
            
            % Loop over the frames, for all the channels
            for time_index = similarity_distance+2:number_times
                
                % Magnitude spectrum of the frame being processing
                audio_spectrum = abs(audio_stft(1:end/2+1,time_index,:));
                
                % Magnitude spectrum  of the past frames in the buffer
                audio_buffer = abs(audio_stft(1:end/2+1,max(time_index-buffer_length+1,1):time_index,:));
                
                % Cosine similarity between the frame being processed and 
                % the past frames in the buffer, for both channels
                similarity_vector = (mean(audio_spectrum,3)/norm(mean(audio_spectrum,3),2))'...
                    *(mean(audio_buffer,3)./sqrt(sum(mean(audio_buffer,3).^2,1)));
                
                % Find the indices of the similar frames using findpeaks
                [~,similarity_indices] = findpeaks(similarity_vector, ...
                    'MinPeakHeight',repet.similarity_threshold, ...
                    'MinPeakDistance',similarity_distance, ...
                    'NPeaks',repet.similarity_number, ...
                    'SortStr','descend');
                
                % Loop over the channels
                for channel_index = 1:number_channels
                    
                    % Repeating spectrum for the frame being processed
                    repeating_spectrum = median(audio_buffer(:,similarity_indices,channel_index),2);
                    
                    % Refine the repeating spectrum
                    repeating_spectrum = min(audio_spectrum(:,:,channel_index),repeating_spectrum);
                    
                    % Repeating mask for the frame being processing
                    repeating_mask = (repeating_spectrum+eps)./(audio_spectrum(:,:,channel_index)+eps);
                    
                    % High-pass filtering of the (dual) non-repeating 
                    % foreground
                    repeating_mask(2:cutoff_frequency+1,:) = 1;
                    
                    % Mirror the frequencies
                    repeating_mask = cat(1,repeating_mask,flipud(repeating_mask(2:end-1)));
                    
                    % Apply the repeating mask to the STFT of the frame 
                    % being processed
                    background_stft(:,time_index,channel_index) = repeating_mask.*audio_stft(:,time_index,channel_index);
                    
                end
                
                % Update the wait bar
                waitbar(time_index/number_times,wait_bar);
                
            end
            
            % Close the wait bar
            close(wait_bar)
            
            %%% Background synthesis
            % Initialize the background signal
            background_signal = zeros(number_samples,number_channels);
            
            % Loop over the channels
            for channel_index = 1:number_channels
                
                % Synthesize the repeating background signal
                background_signal1 = repet.istft(background_stft(:,:,channel_index),window_function,step_length);
                
                % Truncate it to the original length
                background_signal(:,channel_index) = background_signal1(1:number_samples);
            end
            
        end
        
    end
    
    % Other methods
    methods (Access = protected, Hidden = true, Static = true)

        % STFT parameters (for constant overlap-add)
        function [window_length,window_function,step_length] = stftparameters(window_duration,sample_rate)
            
            % Window length in samples (power of 2 for fast FFT)
            window_length = 2.^nextpow2(window_duration*sample_rate);
            
            % Window function (even window length and 'periodic' Hamming 
            % window for constant overlap-add)
            window_function = hamming(window_length,'periodic');
            
            % Step length (half the window length for constant overlap-add)
            step_length = window_length/2;
            
        end
        
        % Short-time Fourier transform (STFT) (with zero-padding at the 
        % edges)
        function audio_stft = stft(audio_signal,window_function,step_length)
            
            % Number of samples
            number_samples = length(audio_signal);
            
            % Window length in samples
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
        
        % Inverse short-time Fourier transform (STFT)
        function audio_signal = istft(audio_stft,window_function,step_length)
            
            % Number of time frames
            [~,number_times] = size(audio_stft);
            
            % Window length in samples
            window_length = length(window_function);
            
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
        
        % Autocorrelation using the Wiener–Khinchin theorem (faster than 
        % using xcorr)
        function autocorrelation_matrix = acorr(data_matrix)
            
            % Number of points in each column
            number_points = size(data_matrix,1);
            
            % Power Spectral Density (PSD): PSD(X) = fft(X).*conj(fft(X))
            % (after zero-padding for proper autocorrelation)
            data_matrix = abs(fft(data_matrix,2*number_points)).^2;
            
            % Wiener–Khinchin theorem: PSD(X) = fft(acorr(X))
            autocorrelation_matrix = ifft(data_matrix); 
            
            % Discard the symmetric part
            autocorrelation_matrix = autocorrelation_matrix(1:number_points,:);
            
            % Unbiased autocorrelation (lag 0 to number_points-1)
            autocorrelation_matrix = autocorrelation_matrix./(number_points:-1:1)';
            
        end
        
        % Beat spectrum using the autocorrelation
        function beat_spectrum = beatspectrum(audio_spectrogram)
            
            % Autocorrelation of the frequency channels
            beat_spectrum = repet.acorr(audio_spectrogram');
            
            % Mean over the frequency channels
            beat_spectrum = mean(beat_spectrum,2);
            
        end
        
        % Beat spectrogram using the beat spectrum
        function beat_spectrogram = beatspectrogram(audio_spectrogram,segment_length,segment_step)

            % Number of frequency channels and time frames
            [number_frequencies,number_times] = size(audio_spectrogram);
            
            % Zero-padding the audio spectrogram to center the segments
            audio_spectrogram = [zeros(number_frequencies,ceil((segment_length-1)/2)),audio_spectrogram,zeros(number_frequencies,floor((segment_length-1)/2))];
            
            % Initialize beat spectrogram
            beat_spectrogram = zeros(segment_length,number_times);
            
            % Open wait bar
            wait_bar = waitbar(0,'Adaptive REPET 1/2');
            
            % Loop over the time frames (including the last one)
            for time_index = [1:segment_step:number_times-1,number_times]
                
                % Beat spectrum of the centered audio spectrogram segment
                beat_spectrogram(:,time_index) = repet.beatspectrum(audio_spectrogram(:,time_index:time_index+segment_length-1));
                
                % Update wait bar
                waitbar(time_index/number_times,wait_bar);
                
            end
            
            % Close wait bar
            close(wait_bar)

        end
        
        % Self-similarity matrix using the cosine similarity (faster than
        % pdist2)
        function similarity_matrix = similarity(data_matrix)
            
            % Divide each column by its Euclidean norm
            data_matrix = data_matrix./sqrt(sum(data_matrix.^2,1));
            
            % Multiply each normalized columns with each other
            similarity_matrix = data_matrix'*data_matrix;
            
        end
        
        % Repeating periods from the beat spectra (spectrum or spectrogram)
        function repeating_periods = periods(beat_spectra,period_range)
            
            % The repeating periods are the indices of the maximum values 
            % in the beat spectra given the period range (they do not count 
            % lag 0 and should be shorter than one third of the signal 
            % length since the median needs at least three segments)
            [~,repeating_periods] = max(beat_spectra(period_range(1)+1:min(period_range(2),floor(size(beat_spectra,1)/3)),:),[],1);
            
            % Re-adjust the index or indices
            repeating_periods = repeating_periods+period_range(1);
            
        end
        
        % Similarity indices from the similarity matrix using findpeaks
        function similarity_indices = indices(similarity_matrix,similarity_threshold,similarity_distance,similarity_number)
            
            % Number of time frames
           	number_times = size(similarity_matrix,1);
            
            % Initialize the similarity indices
            similarity_indices = cell(1,number_times);
            
            % Open wait bar
            wait_bar = waitbar(0,'REPET-SIM 1/2');
            
            % Loop over the time frames
            for time_index = 1:number_times
                
                % Find local maxima using findpeaks
                [~,peak_indices] = findpeaks(similarity_matrix(:,time_index), ...
                    'MinPeakHeight',similarity_threshold, ...
                    'MinPeakDistance',similarity_distance, ...
                    'NPeaks',similarity_number, ...
                    'SortStr','descend');
                
                % Similarity indices for the current time frame
                similarity_indices{time_index} = peak_indices;
                
                % Update wait bar
                waitbar(time_index/number_times,wait_bar);
                
            end
            
            % Close wait bar
            close(wait_bar)
            
        end
        
        % Repeating mask for REPET
        function repeating_mask = mask(audio_spectrogram,repeating_period)
            
            % Number of frequency channels and time frames
            [number_frequencies,number_times] = size(audio_spectrogram);
            
            % Number of repeating segments, including the last partial one
            number_segments = ceil(number_times/repeating_period);
            
            % Pad the audio spectrogram to have an integer number of 
            % segments
            audio_spectrogram = [audio_spectrogram,nan(number_frequencies,number_segments*repeating_period-number_times)];
            
            % Reshape the audio spectrogram for the columns to represent 
            % the segments
            audio_spectrogram = reshape(audio_spectrogram,[number_frequencies*repeating_period,number_segments]);
            
            % Derive the repeating segment by taking the median over the 
            % segments, ignoring the nan parts
            repeating_segment = [median(audio_spectrogram(1:number_frequencies*(number_times-(number_segments-1)*repeating_period),1:number_segments),2); ... 
                median(audio_spectrogram(number_frequencies*(number_times-(number_segments-1)*repeating_period)+1:number_frequencies*repeating_period,1:number_segments-1),2)];
            
            % Derive the repeating spectrogram by making sure it has less 
            % energy than the audio spectrogram
            repeating_spectrogram = bsxfun(@min,audio_spectrogram,repeating_segment);
            
            % Derive the repeating mask by normalizing the repeating 
            % spectrogram by the audio spectrogram
            repeating_mask = (repeating_spectrogram+eps)./(audio_spectrogram+eps);
            
            % Reshape the repeating mask
            repeating_mask = reshape(repeating_mask,[number_frequencies,number_segments*repeating_period]);
            
            % Truncate the repeating mask to the orignal number of time 
            % frames
            repeating_mask = repeating_mask(:,1:number_times);
            
        end
        
        % Repeating mask for the Adaptive REPET
        function repeating_mask = adaptivemask(audio_spectrogram,repeating_periods,filter_order)
            
            % Number of frequency channels and time frames
            [number_channels,number_times] = size(audio_spectrogram);
            
            % Indices of the frames for the median filter centered on 0 
            % (e.g., 3 => [-1,0,1], 4 => [-1,0,1,2], etc.)
            frame_indices = (1:filter_order)-ceil(filter_order/2);
            
            % Initialize the repeating spectrogram
            repeating_spectrogram = zeros(number_channels,number_times);
            
            % Open wait bar
            wait_bar = waitbar(0,'Adaptive REPET 2/2');
            
            % Loop over the time frames
            for time_index = 1:number_times
                
                % Indices of the frames for the median filter
                time_indices = time_index+frame_indices*repeating_periods(time_index);
                
                % Discard out-of-range indices
                time_indices(time_indices<1 | time_indices>number_times) = [];
                
                % Median filter on the current time frame
                repeating_spectrogram(:,time_index) = median(audio_spectrogram(:,time_indices),2);
                
                % Update wait bar
                waitbar(time_index/number_times,wait_bar);
                
            end
            
            % Close wait bar
            close(wait_bar)
            
            % Make sure the energy in the repeating spectrogram is smaller 
            % than in the audio spectrogram, for every time-frequency bin
            repeating_spectrogram = min(audio_spectrogram,repeating_spectrogram);
            
            % Derive the repeating mask by normalizing the repeating
            % spectrogram by the audio spectrogram
            repeating_mask = (repeating_spectrogram+eps)./(audio_spectrogram+eps);

        end
        
        % Repeating mask for REPET-SIM
        function repeating_mask = simmask(audio_spectrogram,similarity_indices)
            
            % Number of frequency bins and time frames
            [number_frequencies,number_times] = size(audio_spectrogram);
            
            % Initialize the repeating spectrogram
            repeating_spectrogram = zeros(number_frequencies,number_times);
            
            % Open Wait bar
            wait_bar = waitbar(0,'REPET-SIM 2/2');
            
            % Loop over the time frames
            for time_index = 1:number_times
                
                % Indices of the frames for the median filter
                time_indices = similarity_indices{time_index};
                
                % Median filter on the current time frame
                repeating_spectrogram(:,time_index) = median(audio_spectrogram(:,time_indices),2);                                              % Median of the similar frames for frame j
                
                % Update wait bar
                waitbar(time_index/number_times,wait_bar);
                
            end
            
            % Close wait bar
            close(wait_bar)
            
            % Make sure the energy in the repeating spectrogram is smaller 
            % than in the audio spectrogram, for every time-frequency bin
            repeating_spectrogram = min(audio_spectrogram,repeating_spectrogram);
            
            % Derive the repeating mask by normalizing the repeating
            % spectrogram by the audio spectrogram
            repeating_mask = (repeating_spectrogram+eps)./(audio_spectrogram+eps);

        end
    
    end
    
end
