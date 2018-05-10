"""The module's docstring"""

class repet(object):
    """
    repet REpeating Pattern Extraction Technique (REPET) class
        Repetition is a fundamental element in generating and perceiving structure. In audio, mixtures are often
        composed of structures where a repeating background signal is superimposed with a varying foreground signal
        (e.g., a singer overlaying varying vocals on a repeating accompaniment or a varying speech signal mixed up with
        a repeating background noise). On this basis, we present the REpeating Pattern Extraction Technique (REPET), a
        simple approach for separating the repeating background from the non-repeating foreground in an audio mixture.
        The basic idea is to find the repeating elements in the mixture, derive the underlying repeating models, and
        extract the repeating  background by comparing the models to the mixture. Unlike other separation approaches,
        REPET does not depend on special parameterizations, does not rely on complex frameworks, and does not require
        external information. Because it is only based on repetition, it has the advantage of being simple, fast, blind,
        and therefore completely and easily automatable.

    """

    def original(self):
        """
        repet REPET (original)
        """

    def extended(self):
        """
        extended REPET extended
        """

    def adaptive(self):
        """
        adaptive Adaptive REPET
        """

    def sim(self):
        """
        sim REPET-SIM
        """

    def simonline(self):
        """
        simonline Online REPET-SIM
        """

def my_function():
    """The function's docstring"""

'''
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
'''
