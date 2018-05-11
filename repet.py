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
    05/10/18
"""

from math import ceil, log2
from numpy import concatenate, zeros
from numpy.fft import fft
from scipy.signal import hamming

def original(audio_signal, sample_rate):
    """
    repet REPET (original)
        background_signal = repet.original(audio_signal, sample_rate)

    Arguments:
        audio_signal: audio signal [number_samples, number_channels]
        sample_rate: sample rate in Hz
        background_signal: background signal [number_samples, number_channels]

    Example:
    """


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
