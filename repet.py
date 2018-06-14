"""
REpeating Pattern Extraction Technique (REPET) class
    Repetition is a fundamental element in generating and perceiving structure. In audio, mixtures are often composed of
    structures where a repeating background signal is superimposed with a varying foreground signal (e.g., a singer
    overlaying varying vocals on a repeating accompaniment or a varying speech signal mixed up with a repeating
    background noise). On this basis, we present the REpeating Pattern Extraction Technique (REPET), a simple approach
    for separating the repeating background from the non-repeating foreground in an audio mixture. The basic idea is to
    find the repeating elements in the mixture, derive the underlying repeating models, and extract the repeating
    background by comparing the models to the mixture. Unlike other separation approaches, REPET does not depend on
    special parameterizations, does not rely on complex frameworks, and does not require external information. Because
    it is only based on repetition, it has the advantage of being simple, fast, blind, and therefore completely and
    easily automatable.

Functions:
    original - original - REPET (original)
    extended - REPET extended
    adaptive - Adaptive REPET
    sim - REPET-SIM
    simonline - Online REPET-SIM

See also http://zafarrafii.com/#REPET

References:
    Zafar Rafii, Antoine Liutkus, and Bryan Pardo. "REPET for Background/Foreground Separation in Audio," Blind Source
    Separation, chapter 14, pages 395-411, Springer Berlin Heidelberg, 2014.

    Zafar Rafii and Bryan Pardo. "Online REPET-SIM for Real-time Speech Enhancement," 38th International Conference on
    Acoustics, Speech and Signal Processing, Vancouver, BC, Canada, May 26-31, 2013.

    Zafar Rafii and Bryan Pardo. "Audio Separation System and Method," US20130064379 A1, US 13/612,413, March 14, 2013.

    Zafar Rafii and Bryan Pardo. "REpeating Pattern Extraction Technique (REPET): A Simple Method for Music/Voice
    Separation," IEEE Transactions on Audio, Speech, and Language Processing, volume 21, number 1, pages 71-82,
    January, 2013.

    Zafar Rafii and Bryan Pardo. "Music/Voice Separation using the Similarity Matrix," 13th International Society on
    Music Information Retrieval, Porto, Portugal, October 8-12, 2012.

    Antoine Liutkus, Zafar Rafii, Roland Badeau, Bryan Pardo, and Gaël Richard. "Adaptive Filtering for Music/Voice
    Separation Exploiting the Repeating Musical Structure," 37th International Conference on Acoustics, Speech and
    Signal Processing, Kyoto, Japan, March 25-30, 2012.

    Zafar Rafii and Bryan Pardo. "A Simple Music/Voice Separation Method based on the Extraction of the Repeating
    Musical Structure," 36th International Conference on Acoustics, Speech and Signal Processing, Prague, Czech
    Republic, May 22-27, 2011.

Author:
    Zafar Rafii
    zafarrafii@gmail.com
    http://zafarrafii.com
    https://github.com/zafarrafii
    https://www.linkedin.com/in/zafarrafii/
    06/14/18
"""

import numpy as np
import scipy.signal


# Public functions/variables
# Window length in samples (audio stationary around 40 ms; power of 2 for fast FFT and constant overlap-add)
windowlength = lambda sample_rate: 2**int(np.ceil(np.log2(0.04*sample_rate)))

# Window function (periodic Hamming window for constant overlap-add)
windowfunction = lambda window_length: scipy.signal.hamming(window_length, False)

# Step length (half the window length for constant overlap-add)
steplength = lambda window_length: round(window_length/2)

# Cutoff frequency in Hz for the dual high-pass filter of the foreground (vocals are rarely below 100 Hz)
cutoff_frequency = 100

# Period range in seconds for the beat spectrum (for REPET, REPET extented, and adaptive REPET)
period_range = np.array([1, 10])

# Segmentation length in seconds (for REPET extented and adaptive REPET)
segment_length = 10

# Step in seconds (for REPET extented)
segment_step = 5

# Filter order for the median filter (for adaptive REPET)
filter_order = 5

# Minimal threshold for two similar frames in [0,1], minimal distance between two similar frames in seconds, and maximal
# number of similar frames for one frame (for REPET-SIM and online REPET-SIM)
similarity_threshold = 0
similarity_distance = 1
similarity_number = 100

# Buffer length in seconds (for online REPET-SIM)
buffer_length = 5


# Public functions
def original(audio_signal, sample_rate):
    """
    repet REPET (original)
        background_signal = repet.original(audio_signal, sample_rate)

    Arguments:
        audio_signal: audio signal [number_samples, number_channels]
        sample_rate: sample rate in Hz
        background_signal: background signal [number_samples, number_channels]

    Example: Estimate the background and foreground signals, and display their spectrograms
        # Import modules
        import scipy.io.wavfile
        import z

        # Audio signal (normalized) and sample rate in Hz
        sample_rate, audio_signal = scipy.io.wavfile.read('audio_file.wav')
        audio_signal = audio_signal / (2.0**(audio_signal.itemsize*8-1))

        # Estimate the background signal and infer the foreground signal
        background_signal = repet.original(audio_signal, sample_rate);
        foreground_signal = audio_signal-background_signal;

        # Write the background and foreground signals (un-normalized)
        scipy.io.wavfile.write('background_signal.wav', sample_rate, background_signal)
        scipy.io.wavfile.write('foreground_signal.wav', sample_rate, foreground_signal)

        #
    """

    # Number of samples and channels
    number_samples, number_channels = np.shape(audio_signal)

    # Window length, window function, and step length for the STFT
    window_length = windowlength(sample_rate)
    window_function = windowfunction(window_length)
    step_length = steplength(window_length)

    # Number of time frames
    number_times = int(np.ceil((window_length-step_length+number_samples)/step_length))

    # Initialize the STFT
    audio_stft = np.zeros((window_length, number_times, number_channels), dtype=complex)

    # Loop over the channels
    for channel_index in range(0, number_channels):

        # STFT of the current channel
        audio_stft[:, :, channel_index] = _stft(audio_signal[:, channel_index], window_function, step_length)

    # Magnitude spectrogram (with DC component and without mirrored frequencies)
    audio_spectrogram = abs(audio_stft[0:int(window_length/2)+1, :, :])

    # Beat spectrum of the spectrograms averaged over the channels (squared to emphasize peaks of periodicitiy)
    beat_spectrum = _beatspectrum(np.power(np.mean(audio_spectrogram, 2), 2))

    # Period range in time frames for the beat spectrum
    period_range2 = round(period_range*sample_rate/step_length)
    period_range2[0] = period_range2[0]-1

    # Repeating period in time frames given the period range
    repeating_period = _periods(beat_spectrum, period_range2)

    # Cutoff frequency in frequency channels for the dual high-pass filter of the foreground
    cutoff_frequency2 = int(np.ceil(cutoff_frequency*(window_length-1)/sample_rate))-1

    # Initialize the background signal
    background_signal = np.zeros((number_samples, number_channels))

    # Loop over the channels
    #for channel_index in range(0, number_channels):

        # Repeating mask for the current channel
        #repeating_mask = _mask(audio_spectrogram[:, :, channel_index], repeating_period)

    return background_signal


def extended(audio_signal, sample_rate):
    """
    extended REPET extended
    """


def adaptive(audio_signal, sample_rate):
    """
    adaptive Adaptive REPET
    """


def sim(audio_signal, sample_rate):
    """
    sim REPET-SIM
    """


def simonline(audio_signal, sample_rate):
    """
    simonline Online REPET-SIM
    """


# Private functions
def _stft(audio_signal, window_function, step_length):
    """Short-time Fourier transform (STFT) (with zero-padding at the edges)"""

    # Number of samples and window length
    number_samples = len(audio_signal)
    window_length = len(window_function)

    # Number of time frames
    number_times = int(np.ceil((window_length - step_length + number_samples) / step_length))

    # Zero-padding at the start and end to center the windows
    audio_signal = np.pad(audio_signal, (window_length - step_length, number_times * step_length - number_samples),
                          'constant', constant_values=0)

    # Initialize the STFT
    audio_stft = np.zeros((window_length, number_times))

    # Loop over the time frames
    for time_index in range(0, number_times):

        # Window the signal
        sample_index = step_length * time_index
        audio_stft[:, time_index] = audio_signal[sample_index:window_length + sample_index] * window_function

    # Fourier transform of the frames
    audio_stft = np.fft.fft(audio_stft, axis=0)

    return audio_stft


def _istft(audio_stft, window_function, step_length):
    """Inverse short-time Fourier transform (STFT)"""

    # Window length and number of time frames
    window_length, number_times = np.shape(audio_stft)

    # Number of samples for the signal
    number_samples = (number_times - 1) * step_length + window_length

    # Initialize the signal
    audio_signal = np.zeros(number_samples)

    # Inverse Fourier transform of the frames and real part to ensure real values
    audio_stft = np.real(np.fft.ifft(audio_stft, axis=0))

    # Loop over the time frames
    for time_index in range(0, number_times):

        # Constant overlap-add (if proper window and step)
        sample_index = step_length * time_index
        audio_signal[sample_index:window_length + sample_index] \
            = audio_signal[sample_index:window_length + sample_index] + audio_stft[:, time_index]

    # Remove the zero-padding at the start and end
    audio_signal = audio_signal[window_length - step_length:number_samples - (window_length - step_length)]

    # Un-apply window (just in case)
    audio_signal = audio_signal / sum(window_function[0:window_length:step_length])

    return audio_signal


def _acorr(data_matrix):
    """Autocorrelation using the Wiener–Khinchin theorem"""

    # Number of points in each column
    number_points = data_matrix.shape[0]

    # Power Spectral Density (PSD): PSD(X) = np.multiply(fft(X), conj(fft(X))) (after zero-padding for proper
    # autocorrelation)
    data_matrix = np.power(np.abs(np.fft.fft(data_matrix, n=2*number_points, axis=0)), 2)

    # Wiener–Khinchin theorem: PSD(X) = np.fft.fft(repet._acorr(X))
    autocorrelation_matrix = np.real(np.fft.ifft(data_matrix, axis=0))

    # Discard the symmetric part
    autocorrelation_matrix = autocorrelation_matrix[0:number_points, :]

    # Unbiased autocorrelation (lag 0 to number_points-1)
    autocorrelation_matrix = (autocorrelation_matrix.T/np.arange(number_points, 0, -1)).T

    return autocorrelation_matrix


def _beatspectrum(audio_spectrogram):
    """Beat spectrum using the autocorrelation"""

    # Autocorrelation of the frequency channels
    beat_spectrum = _acorr(audio_spectrogram.T)

    # Mean over the frequency channels
    beat_spectrum = np.mean(beat_spectrum, axis=1)

    return beat_spectrum


def _beatspectrogram(audio_spectrogram, segment_length):
    """Beat spectrogram using the the beat spectrum"""

    # Number of frequency channels and time frames
    number_frequencies, number_times = np.shape(audio_spectrogram)

    # Zero-padding the audio spectrogram to center the segments
    audio_spectrogram = np.pad(audio_spectrogram,
                               ((0, 0), (int(np.ceil((segment_length-1)/2)), int(np.floor((segment_length-1)/2)))),
                               'constant', constant_values=0)

    # Initialize beat spectrogram
    beat_spectrogram = np.zeros((segment_length, number_times))

    # Loop over the time frames (including the last one)
    for time_index in range(0, number_times):

        # Beat spectrum of the centered audio spectrogram segment
        beat_spectrogram[:, time_index] = _beatspectrum(audio_spectrogram[:, time_index:time_index+segment_length])

    return beat_spectrogram


def _selfsimilaritymatrix(data_matrix):
    """Self-similarity matrix using the cosine similarity"""

    # Divide each column by its Euclidean norm
    data_matrix = data_matrix/np.sqrt(sum(np.power(data_matrix, 2), 0))

    # Multiply each normalized columns with each other
    similarity_matrix = np.matmul(data_matrix.T, data_matrix)

    return similarity_matrix


def _similaritymatrix(data_matrix1, data_matrix2):
    """Similarity matrix using the cosine similarity"""

    # Divide each column by its Euclidean norm
    data_matrix1 = data_matrix1/np.sqrt(sum(np.power(data_matrix1, 2), 0))
    data_matrix2 = data_matrix2/np.sqrt(sum(np.power(data_matrix2, 2), 0))

    # Multiply each normalized columns with each other
    similarity_matrix = np.matmul(data_matrix1.T, data_matrix2)

    return similarity_matrix


def _periods(beat_spectra, period_range):
    """Repeating periods from the beat spectra (spectrum or spectrogram)"""

    # The repeating periods are the indices of the maxima in the beat spectra for the period range (they do not account
    # for lag 0 and should be shorter than a third of the length as at least three segments are needed for the median)
    if beat_spectra.ndim == 1:
        repeating_periods = np.argmax(
            beat_spectra[period_range[0] + 1:min(period_range[1], int(np.floor(beat_spectra.shape[0] / 3)))])
    else:
        repeating_periods = np.argmax(
            beat_spectra[period_range[0] + 1:min(period_range[1], int(np.floor(beat_spectra.shape[0] / 3))), :], axis=0)

    # Re-adjust the index or indices
    repeating_periods = repeating_periods + period_range[0] + 1

    return repeating_periods


def _localmaxima(data_vector, minimum_value, minimum_distance, number_values):
    """Local maxima, values and indices"""

    # Number of data points
    number_data = len(data_vector)

    # Initialize maximum values and locations
    maximum_values = []
    maximum_indices = []

    # Loop over the data points
    for data_index in range(0, number_data):

        # The local maximum should be greater than the maximum value
        if data_vector[data_index] >= minimum_value:

            # The local maximum should be strictly greater than the neighboring data points within +- minimum distance
            if all(data_vector[data_index] > data_vector[max(data_index-minimum_distance, 0):data_index-1]) \
                    and all(data_vector[data_index]
                            > data_vector[data_index+1:min(data_index+minimum_distance, number_data)]):

                # Save the maximum value and index
                maximum_values = np.append(maximum_values, data_vector[data_index])
                maximum_indices = np.append(maximum_indices, data_index)

    # Sort the maximum values in descending order
    sort_indices = np.argsort(maximum_values)
    sort_indices = sort_indices[::-1]

    # Keep only the top maximum values and indices
    number_values = min(number_values, len(maximum_values))
    maximum_values = maximum_values[0:number_values]
    maximum_indices = maximum_indices[sort_indices[0:number_values]].astype(int)

    return maximum_values, maximum_indices


def _indices(similarity_matrix, similarity_threshold, similarity_distance, similarity_number):
    """Similarity indices from the similarity matrix"""

    #Number of time frames
    number_times = similarity_matrix.shape[0]

    # Initialize the similarity indices
    similarity_indices = [None]*number_times

    # Loop over the time frames
    for time_index in range(0, number_times):

        # Indices of the local maxima
        _, maximum_indices = \
            _localmaxima(similarity_matrix[:, time_index], similarity_threshold, similarity_distance, similarity_number)

        # Similarity indices for the current time frame
        similarity_indices[time_index] = maximum_indices

    return similarity_indices


def test():

    import scipy.io.wavfile

    sample_rate, audio_signal = scipy.io.wavfile.read('audio_file.wav')
    audio_signal = audio_signal / (2.0 ** (audio_signal.itemsize * 8 - 1))

    return original(audio_signal, sample_rate)