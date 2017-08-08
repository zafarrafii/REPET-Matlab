from math import ceil, log2
from numpy import concatenate, zeros
from numpy.fft import fft
from scipy.signal import hamming

# Public functions
def repet(audio_signal, sample_rate):
    """REPET (original)

    The original REPET aims at identifying and extracting the repeating patterns in an audio mixture,
    by estimating a period of the underlying repeating structure and modeling a segment of the
    periodically repeating background.
    background_signal = repet.original(audio_signal,sample_rate);
    """

    background_signal = audio_signal * sample_rate
    return background_signal


def _stftparameters(window_duration, sample_rate):
    """STFT parameters (for constant overlap-add)"""
    # Window length in samples (power of 2 for fast FFT)
    window_length = int(pow(2, ceil(log2(window_duration*sample_rate))))

    # Window function(even window length and 'periodic' Hamming window for constant overlap - add)
    window_function = hamming(window_length, False)

    # Step length (half the window length for constant overlap-add)
    step_length = window_length/2

    return window_length, window_function, step_length


def _stft(audio_signal, window_function, step_length):
    """Short-Time Fourier Transform (STFT) (with zero-padding at the edges)"""

    # Number of samples
    number_samples = len(audio_signal)

    # Window length in samples
    window_length = len(window_function)

    # Number of time frames
    number_times = int(ceil((window_length-step_length+number_samples)/step_length))

    # Zero-padding at the start and end to center the windows
    audio_signal = concatenate((zeros(window_length-step_length), audio_signal,
                                zeros(number_times*step_length-number_samples)))

    # Initialize the STFT
    audio_stft = zeros((window_length, number_times))

    # Loop over the time frames
    for time_index in range(number_times):

        # Window the signal
        sample_index = step_length*time_index
        audio_stft[:, time_index] = audio_signal[sample_index:window_length+sample_index]*window_function

    # Fourier transform of the frames
    audio_stft = fft(audio_stft, axis=0)

    return audio_stft


def test():

    from matplotlib.pyplot import imshow
    from numpy import log10

    audio_signal = range(1, 44101)
    window_function = hamming(2048)
    step_length = 1024

    audio_stft = _stft(audio_signal, window_function, step_length)
    imshow(20*log10(abs(audio_stft)), extent=[0, 1, 0, 1])

    return audio_stft
