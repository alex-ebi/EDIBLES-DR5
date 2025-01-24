from pathlib import Path
import numpy as np


def get_wave_path(hdr):
    try:
        wave = hdr['ESO INS GRAT1 WLEN']
    except KeyError:
        wave = hdr['ESO INS GRAT2 WLEN']

    setting = hdr['ESO INS PATH'].lower()

    return wave, setting


def get_filter_name(hdr):
    try:
        filter_name = hdr['ESO INS FILT2 NAME']
    except KeyError:
        filter_name = hdr['ESO INS FILT3 NAME']

    return filter_name


def wave_from_dispersion(flux, start_wave, dispersion, crpix=0):
    """
    Calculates a wavelength array as a equidistant grid.
    Starts from 'star_wave' and makes further points with a constant separation 'dispersion'.

    Parameters
    ----------
    flux : np.array
        Flux array. Needed to know length of spectrum.
    start_wave : float
        Starting wavelength.
    dispersion : float
        Wavelength step.
    crpix : int
        Index of reference pixel.

    Returns
    -------
    np.array
        Wavelength array matching to flux array in length.
    """
    index_col = np.array(range(len(flux)))
    index_col = index_col - crpix
    wave = index_col * dispersion + start_wave

    return wave
