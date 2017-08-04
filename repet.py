# Public functions
def repet(audio_signal, sample_rate):
    """REPET (original)

    The original REPET aims at identifying and extracting the repeating patterns in an audio mixture,
    by estimating a period of the underlying repeating structure and modeling a segment of the
    periodically repeating background.
    background_signal = repet.original(audio_signal,sample_rate);
    """

    background_signal = audio_signal + sample_rate
    return background_signal


# Private functions
def _nextpow2(input_value):
    """Exponent of next higher power of 2 (from https://wiki.python.org/moin/NumericAndScientificRecipes)"""
    output_value = 1
    while output_value < input_value:
        output_value *= 2
    return output_value


def _stftparameters(window_duration, sample_rate):
    """"STFT parameters (for constant overlap-add)"""

    # Window length in samples (power of 2 for fast FFT)
    window_length = pow(2, _nextpow2(window_duration*sample_rate))