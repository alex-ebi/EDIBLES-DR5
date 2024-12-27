# astro_scripts_uibk/spectrum/convolve.py


import numpy as np
from scipy.interpolate import interp1d
from PyAstronomy import pyasl
from astropy.convolution import convolve
from scipy import integrate
import math
from scipy.stats import binned_statistic

clight = 299792.5


def find_nearest_index(array: np.array, value: float, is_sorted=False) -> int:
    """
    Returns the index of an array where the value is nearest to a specified value.

    Parameters
    ----------
    array : np.array
        An array with numbers as values.

    value : float
        The input-value for which we search the closest value in the array.

    is_sorted: bool
        Use a much faster search algorithm for sorted arrays if set to True.

    Returns
    -------
    int
        The index of the cell which has the closest value to the input-value.
    """
    if is_sorted:
        idx = np.searchsorted(array, value)
        if (idx > 0 and idx == array.size) or (np.abs(array[idx - 1] - value) < np.abs(array[idx] - value)):
            idx -= 1
    else:
        array = np.asarray(array)
        idx = (np.abs(array - value)).argmin()

    return idx


def find_nearest_value(array: np.array, value: float, is_sorted=False) -> float:
    """
    Returns the value of an array which is nearest to a specified value.

    Parameters
    ----------
    array : np.array
        An array with numbers as values.

    value : float
        The input-value for which we search the closest value in the array.

    is_sorted: bool
        Use a much faster search algorithm for sorted arrays if set to True.

    Returns
    -------
    float
        The array-value which is closest to the input-value.
    """

    return float(array[find_nearest_index(array, value, is_sorted)])


def get_lower_interval_index(intervals: np.array, value: float) -> int:
    """
    Get the index of the closest lower boundary of a value.
    A list of boundaries is provided by 'intervals'.

    Parameters
    ----------
    intervals : np.array
        Sorted numpy array, defining the interval bounds.
    value : float
        The input-value for which we search the lower bound index.

    Returns
    -------
    int
        The array-index of the point <= value
    """
    idx = find_nearest_index(intervals, value, is_sorted=True)
    if value < intervals[idx]:
        return idx - 1
    else:
        return idx


def wave_to_bin(wave_points: np.array) -> np.array:
    """
    Convert central wavelength points into an array of bins:
        Example: [0,1,2,3] -> [-0.5,0.5,1.5,2.5,3.5]

    Parameters
    ----------
    wave_points : np.array
        Wavelength array of observed spectrum.

    Returns
    -------
    np.array
        Array of bin-boundaries.
    """
    first = wave_points[0] - (wave_points[1] - wave_points[0]) * 0.5
    b = wave_points[:-2] + (wave_points[1:-1] - wave_points[:-2]) * 0.5
    b = np.append(first, b)
    last = (wave_points[-1] - wave_points[-2]) * 0.5
    last = np.array([wave_points[-1] - last, wave_points[-1] + last])
    b = np.append(b, last)
    return b


def rebin_plot(obs_wave: np.array, model_spec: np.array) -> np.array:
    """
    Rebins model spectrum to bins of observation, e.g. for accurate plot.
    Model spectrum has to have higher resolution than observation and should be one bin range broader.

    Parameters
    ----------
    obs_wave : np.array
        Wavelength array of observed spectrum.

    model_spec : np.array
        Model spectrum (*np.array([wave, flux])*)

    Returns
    -------
    np.array([wave, flux])
        Rebinned model spectrum.
    """
    bins = wave_to_bin(obs_wave)
    binned_flux, _, _ = binned_statistic(model_spec[0], model_spec[1], bins=bins)

    return np.array([obs_wave, binned_flux])


def resample(spectrum: np.array, wave_new: np.array, assume_sorted=True) -> np.array:
    """
    Resample a spectrum to given wavelength points.

    Parameters
    ----------
    spectrum : np.array
        Input spectrum (*np.array([wave, flux])*)

    wave_new : numpy array of wavelength points for the new spectrum

    assume_sorted : bool

    Returns
    -------
    np_array:
        resampled spectrum
    """
    f = interp1d(spectrum[0], spectrum[1], assume_sorted=assume_sorted)
    flux_new = f(wave_new)
    return np.array([wave_new, flux_new])


def macro_broadening(sx, sy, macroturbulence):
    """
    Convolves spectrum with radial tangential macroturbulence broadening profile.

    Parameters
    ----------
    sx : np.array
        Equidistant wavelength array.
    sy :
        Flux array.

    macroturbulence : float
        Macroturbulence velocity in km/s

    Returns
    -------
    np.array
        Convolved Flux array.
    """
    lambda0 = (sx[0] + sx[-1]) * .5
    deltaw = sx[3] - sx[2]
    dlammacro = macroturbulence * (lambda0 / clight)

    def macro_profile(n, _dlammacro):
        def func(x):
            theta_r = np.sin(x) * np.exp(-(n * deltaw) ** 2 / (_dlammacro * np.cos(x)) ** 2)
            theta_t = np.cos(x) * np.exp(-(n * deltaw) ** 2 / (_dlammacro * np.sin(x)) ** 2)
            return theta_r + theta_t

        return integrate.quad(func, 0, math.pi * .5)[0]

    macroarray = np.array([macro_profile(0, dlammacro)])
    k = 1
    while macroarray[0] > .01 or macroarray[-1] > .01:
        macroarray = np.append(macroarray, macro_profile(k, dlammacro))
        macroarray = np.append(macro_profile(-k, dlammacro), macroarray)
        k = k + 1

    sy = convolve(sy, macroarray, normalize_kernel=True)

    return sy


def inst_rot_macro(spectrum: np.array, resolution=None, vsini=None, eps=0.4, macroturbulence=None, fixed_deltaw=None,
                   interval_size=100, overlap=300, is_equidistant=False):
    """
    Instrumental, rotational and macroturbulence broadening.
    Performance can be improved at the cost of accuracy by increasing the interval size.
    For high broadening velocities you might experience periodic artifacts at the end of each interval.
    If this happens, increase the overlap parameter.

    Parameters
    ----------
    spectrum : np.array
        Input spectrum (*np.array([wave, flux])*)

    resolution : float
        instrumental resolution R = lambda / delta_lambda

    vsini : float
        Projected rotational velocity in km/s

    eps : float
        Linear limb darkening coefficient

    macroturbulence : float
        Macroturbulence velocity in km/s

    fixed_deltaw : float
        Optional: New wavelength step (in Angstrom) - equidistant steps necessary for convolution

    interval_size : float
        Size of the intervals where one central wavelength is used for convolution. In units of Angstrom.

    overlap : int
        Overlap of intervals in units of Pixels.

    is_equidistant : bool
        Set to True if the spectrum is already equidistant. Then, resampling is omitted. (Default: False)

    Returns
    -------
    np.array
        Convolved spectrum.
    """
    if is_equidistant:  # if the input spectrum is already equidistant, omit resampling
        sx, sy = spectrum
    else:
        # Calculate delta lambda if not specified as kwarg.
        if fixed_deltaw is None:
            fixed_deltaw = np.nanmedian(spectrum[0][1:] - spectrum[0][:-1])

        # Equidistant wavelength grid.
        resample_grid = np.arange(spectrum[0][1], spectrum[0][-2], fixed_deltaw)

        sx, sy = resample(spectrum, resample_grid)  # resample spectrum

    interval_index = np.where((sx - sx[0]) < interval_size)[0][-1]  # find length of interval in pixels

    interval_number = int(np.floor(len(sx) / (interval_index + 1)))  # calculate number of intervals
    x_con = np.array([])
    y_con = np.array([])

    for n in range(interval_number):
        # extract interval from spectrum
        sxn = sx[n * (interval_index + 1):(n + 1) * (interval_index + 1) + overlap]
        syn = sy[n * (interval_index + 1):(n + 1) * (interval_index + 1) + overlap]

        # Apply instrumental broadening
        if resolution is not None:
            syn, _ = pyasl.instrBroadGaussFast(sxn, syn, resolution, fullout=True)

        # Apply rotational broadening
        if vsini is not None:
            syn = pyasl.fastRotBroad(sxn, syn, eps, vsini)

        # Apply macroturbulence broadening
        if macroturbulence is not None:
            syn = macro_broadening(sxn, syn, macroturbulence)

        x_con = np.append(x_con, sxn[overlap // 2:-overlap // 2])
        y_con = np.append(y_con, syn[overlap // 2:-overlap // 2])

    return np.array([x_con, y_con])


def multiply(spec: np.array, grid_spec: np.array) -> np.array:
    # resample spec on grid_spec
    spec = resample(spec, grid_spec[0])


def lorentzian(x, x0, a, gam):
    return a * gam ** 2 / (gam ** 2 + (x - x0) ** 2)
