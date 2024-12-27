import numpy as np
import pandas as pd
from scipy.interpolate import interp1d
from pandas import DataFrame
from astro_scripts_uibk import transformations, convolve
from warnings import warn
import scipy as sp


def slice_spectrum(array_in: np.array, x_min: float, x_max: float) -> np.array:
    """
    Returns a spectrum interval for x_min < wave < x_max.

    Parameters
    ----------
    array_in : np.array([wave, flux, additional_columns])
        Input spectrum.
    x_min : float
        Minimum wave coordinate of slice.
    x_max : float
        Maximum wave coordinate of slice.

    Returns
    -------
    np.array([wave, flux, additional_columns])
        Spectrum slice
    """
    warn('This method is deprecated. Use crop_spectrum instead.', DeprecationWarning, stacklevel=2)
    if x_min > x_max:
        raise ValueError('Slice_spectrum error: x_min is larger than x_max!')

    b1 = array_in[0] < x_max  # boolean array of wave values smaller than x_max
    b2 = x_min < array_in[0]  # boolean array of wave values larger than x_min
    bool_array = np.logical_and(b1, b2)  # boolean array of wave values larger than x_min and smaller than x_max

    return array_in[:, bool_array]


def crop_spectrum(array_in: np.array, x_min: float, x_max: float) -> np.array:
    """
    Returns a spectrum interval for x_min < wave < x_max.

    Parameters
    ----------
    array_in : np.array([wave, flux, additional_columns])
        Input spectrum.
    x_min : float
        Minimum wave coordinate of slice.
    x_max : float
        Maximum wave coordinate of slice.

    Returns
    -------
    np.array([wave, flux, additional_columns])
        Spectrum slice
    """
    if x_min > x_max:
        raise ValueError('Slice_spectrum error: x_min is larger than x_max!')

    b1 = array_in[0] < x_max  # boolean array of wave values smaller than x_max
    b2 = x_min < array_in[0]  # boolean array of wave values larger than x_min
    bool_array = np.logical_and(b1, b2)  # boolean array of wave values larger than x_min and smaller than x_max

    return array_in[:, bool_array]


def exclude_spikes_limits(spectrum: np.array, flux_min=None, flux_max=None) -> np.array:
    """
    Excludes parts of a spectrum which exceed specified flux thresholds (flux_min and/or flux_max).
    Used to exclude e.g. cosmics.

    Parameters
    ----------
    spectrum : np.array([wave, flux])
        Input spectrum.
    flux_min : float
        Minimum flux threshold.
    flux_max : float
        Maximum flux threshold.

    Returns
    -------
    np.array([wave, flux, additional_columns])
        Spectrum within thresholds.
    """
    b1, b2 = np.full(len(spectrum[1]), True), np.full(len(spectrum[1]), True)
    if flux_min is not None:
        b2 = spectrum[1] > flux_min  # boolean array of flux values larger than flux_min
    if flux_max is not None:
        b1 = spectrum[1] < flux_max  # boolean array of flux values smaller than flux_max

    # boolean array of flux values smaller than flux_max and larger than flux_min
    bool_array = np.logical_and(b1, b2)

    return spectrum[:, bool_array]


def filter_spikes_normalized(spectrum: np.array, threshold=.02, window=5):
    """
    Filters a spectrum for spikes with a median filter.
    The kwargs should be checked and varied to correctly filter the spectrum.

    First, for every flux bin, we calculate a median flux from a surrounding interval of (window = 5) bins.
    Then the normalized difference between flux and median flux is calculated:

    difference = np.abs(Flux - Median(Flux))/Median(Flux)

    Parameters
    ----------
    spectrum : np.array([wave, flux, (additional columns)])
        Filtered input spectrum
    threshold : float
        Threshold of median filter.
    window : float
        Full width of interval to calculate median at one point.

    Returns
    -------
    np.array([wave, flux, additional_columns])
        Filtered spectrum.
    """
    df = DataFrame(data=spectrum.T)

    median = df[1].rolling(window=window, center=True).median().bfill().ffill()

    difference = np.abs(df[1] - median) / median

    inlier_idx = difference < threshold

    return df.loc[:][inlier_idx].to_numpy().T  # return standard spectrum format


def normalize_spectrum_linear(spectrum: np.array, cont_1: np.array, cont_2: np.array,
                              additional_normalized_columns: list = None) -> np.array:
    """
    Normalizes an absorption spectrum using a linear continuum model defined by two points con_1 and cont_2.

    Parameters
    ----------
    spectrum : np.array([wave, flux, additional_columns])
        Un-normalized spectrum.
    cont_1 : np.array([x, y])
        First continuum point.
    cont_2 : np.array([x, y])
        Second continuum point.
    additional_normalized_columns : list
        Array of column indices. Specifies additional columns to be normalized, using the same continuum points.
        Mind that the additional columns start with the index 2.
        E.g. [2, 3, 5]

    Returns
    -------
    np.array([wave, flux, additional_columns])
        Normalized spectrum.
    """
    wave = spectrum[0]
    flux = spectrum[1]
    additional_columns = spectrum[2:]
    sx1r = cont_1[0]
    sy1r = cont_1[1]
    sx2r = cont_2[0]
    sy2r = cont_2[1]

    f = interp1d([sx1r, sx2r], [sy1r, sy2r], kind='linear', fill_value="extrapolate")

    flux = flux / f(wave)

    if additional_normalized_columns is not None:
        for i in additional_normalized_columns:
            k = i - 2  # shift index from spectrum numbering to numbering in additional_columns
            additional_columns[k] = additional_columns[k] / f(wave)

    if len(additional_columns) > 0:
        out_spec = np.concatenate((np.array([wave, flux]), additional_columns))
    else:
        out_spec = np.array([wave, flux])

    return out_spec


def normalize_mean_flux(spectrum: np.array, wave_1: float, wave_2: float, cont_range=1,
                        additional_normalized_columns: list = None, return_weight=False):
    """
    Normalizes a spectrum using a linear continuum fit.
    Two continuum fluxes are calculated by taking the mean flux around two wavelength points wave_1 and wave_2.
    The area used for the mean flux calculation has the width cont_range.

    Parameters
    ----------
    spectrum : np.array([wave, flux, additional_columns])
        Un-normalized spectrum.
    wave_1 : float
        First continuum point.
    wave_2 : float
        Second continuum point.
    cont_range : float
        The area used for the mean flux calculation.
    additional_normalized_columns : list
        Array of column indices. Specifies additional columns to be normalized, using the same continuum points.
        Mind that the additional columns start with the index 2.
        E.g. [2, 3, 5]
    return_weight : bool
        If True,

    Returns
    -------
    np.array([wave, flux, additional_columns])
        Normalized spectrum.
    """
    c_spec_1 = crop_spectrum(spectrum, wave_1 - cont_range * .5, wave_1 + cont_range * .5)
    c_spec_2 = crop_spectrum(spectrum, wave_2 - cont_range * .5, wave_2 + cont_range * .5)

    cont_1 = np.mean(c_spec_1, axis=1)
    cont_2 = np.mean(c_spec_2, axis=1)

    norm_spec = normalize_spectrum_linear(spectrum, cont_1, cont_2,
                                          additional_normalized_columns=additional_normalized_columns)

    if return_weight:
        weight = 1 / np.std(np.concatenate((crop_spectrum(norm_spec, wave_1 - cont_range * .5,
                                                          wave_1 + cont_range * .5)[1],
                                            crop_spectrum(norm_spec, wave_2 - cont_range * .5,
                                                          wave_2 + cont_range * .5)[1])))
        return norm_spec, weight
    else:
        return norm_spec


def coadd(spectra: list, wave_new: np.array, weights=None):
    """
    Co-addition of multiple spectra.
    The input spectra are interpolated linearly on the new wavelength array (wave_new) and then summed up.

    Parameters
    ----------
    weights
    spectra : list
        List of spectra to be coadded.
    wave_new : np.array
        New wavelength grid for coadded spectrum.

    Returns
    -------
    np.array
        Coadded spectrum.
    """
    res_fluxes, weight_list = [], []

    if weights is None:
        weights = np.ones(len(spectra))

    for spec, weight in zip(spectra, weights):
        f = interp1d(spec[0], spec[1], bounds_error=False)
        res_flux = f(wave_new)

        res_fluxes.append(res_flux)
        weight_list.append([weight] * len(res_flux))

    res_fluxes = np.array(res_fluxes)
    weight_list = np.array(weight_list)

    return np.array([wave_new, np.average(res_fluxes, weights=weight_list, axis=0), np.std(res_fluxes, axis=0)])


def profile_comp_trafo(spectrum: np.array, cont_points: np.array, center: np.array, wave_number=False):
    """
    Transformation of a single spectral feature (e.g. DIB) for profile comparison with another feature.
    The transformation has multiple steps:
    1. Continuum normalisation using the continuum points (cont_points).
    2. Normalisation to central depth = 1 using the absorption center (center).
    3. Transformation into velocity space using the doppler shift to the absorption center.

    Parameters
    ----------
    spectrum : np.array([wave, flux, additional_columns])
        Input spectrum.
    cont_points : (list, np.array) [cont1, cont2]
        List or array of two continuum points. Each point has the structure: cont1 = [wave, flux].
    center : (list, np.array)
        List or array of wavelength and flux of central absorption point.
    wave_number : bool
        Set to true to compare in wave number space. Default: False

    Returns
    -------
    np.array :
        Transformed spectrum ready for profile comparison.
    """
    # normalize to continuum = 1
    spectrum = normalize_spectrum_linear(spectrum, cont_points[0], cont_points[1])

    # norm line profile to central depth
    depth = 1 - normalize_spectrum_linear(center, cont_points[0], cont_points[1])[1]
    spectrum[1] = 1 - (1 - spectrum[1]) / depth

    if wave_number:
        spectrum[0] = transformations.angstrom_to_wavenumber(spectrum[0], air_to_vac=False) - \
                      transformations.angstrom_to_wavenumber(center[0], air_to_vac=False)
    else:
        # transform to velocity space
        spectrum[0] = transformations.wavelength_to_rv(spectrum[0], center[0])

    return spectrum


def normalize_one_point(spec_list, norm_wl: float, norm_half_range=10, normalize_error=False):
    """
    Normalizes a list of spectra. Useful for fast spectrum comparison.
    Each spectrum is normalized by one divisor, which is the median flux around the normalization wavelength
    **norm_wl**.

    Parameters
    ----------
    spec_list : list
        List of spectra in the format np.array([wave, flux, additional_columns]).
    norm_wl : float
        Wavelength of median flux calculation.
    norm_half_range : float
        Half width of the range used for median flux calculation. (default: 10)

    Returns
    -------
    None
    """
    for spec in spec_list:
        norm_flux = np.nanmedian(crop_spectrum(spec, norm_wl - norm_half_range, norm_wl + norm_half_range)[1])
        spec[1] /= norm_flux
        if normalize_error:
            spec[2] /= norm_flux


def smooth_spec(spectrum: np.array, kernel_size: int):
    """
    Smooths a spectrum using a boxcar kernel with a given kernel size in PIXELS.
    Smooths each axis (wavelength, flux,...) using this kernel.

    Parameters
    ----------
    spectrum : np.array([wave, flux, additional_columns])
        Input spectrum.
    kernel_size : int
        Size of the boxcar smoothing kernel.

    Returns
    -------
    np.array :
        Smoothed spectrum.
    """
    kernel = np.ones(kernel_size) / kernel_size
    out_spec = []
    for i in range(len(spectrum)):
        smoothed_column = np.convolve(spectrum[i], kernel, mode='valid')
        out_spec.append(smoothed_column)

    return np.array(out_spec)


def median_smooth(spectrum: np.array, window: int):
    """
    Smooths a spectrum using a rolling median with a given kernel size in PIXELS.
    Smooths each axis (wavelength, flux,...) using this kernel.

    Parameters
    ----------
    spectrum : np.array([wave, flux, additional_columns])
        Input spectrum.
    window : int
        Size of the boxcar smoothing kernel.

    Returns
    -------
    np.array :
        Smoothed spectrum.
    """
    df = pd.DataFrame(spectrum.T)
    ds = df.rolling(center=True, window=window, on=0).median().dropna()  # Rolling window smoothing and drop NA values

    return ds.T.to_numpy()


def divide_spec(spectrum: np.array, div_spec: np.array):
    """
    Divides one spectrum (spectrum) by another spectrum (div_spec).
    Before division, div_spec gets resampled on the wavelength axis of spectrum.

    Parameters
    ----------
    spectrum : np.array
        Spectrum which is divided by div_spec.
    div_spec : np.array
        Spectrum which divides spectrum.

    Returns
    -------
    np.array
        Divided spectrum.
    """
    spec_crop = crop_spectrum(spectrum, min(div_spec[0]), max(div_spec[0]))  # crop spectrum
    res_spec = convolve.resample(div_spec, spectrum[0])  # resample
    divided_flux = spec_crop[1] / res_spec[1]

    return np.array([spec_crop[0], divided_flux])


def baseline_als(y, lam=1e7, p=0.005, niter=10):
    l = len(y)
    d = sp.sparse.csc_matrix(np.diff(np.eye(l), 2))
    w = np.ones(l)
    for i in range(niter):
        w = sp.sparse.spdiags(w, 0, l, l)
        z1 = w + lam * d.dot(d.transpose())
        z = sp.sparse.linalg.spsolve(z1, w * y)
        w = p * (-y > z) + (1 - p) * (-y < z)
    return -z
