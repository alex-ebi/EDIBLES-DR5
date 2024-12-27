import dataclasses
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.widgets import SpanSelector
from astro_scripts_uibk import spectrum_reduction


@dataclasses.dataclass
class EWContainer:
    ew: float
    ew_error: float


def ew_measurement(spectrum: np.array, resolution=100000, cont_range=1):
    """
    Widget for measuring the equivalent width of spectra.
    A linear continuum is calculated by selecting two continuum ranges of width cont_range.
    Then, an equivalent width is calculated using this linear continuum by direct integration over the spectrum.

    Parameters
    ----------
    spectrum : np.array
        Input spectrum.
    resolution : float
        Resolution of the spectrograph.
    cont_range : float
        Width of the continuum ranges.

    Returns
    -------
    (float, float)
        Equivalent width and error of equivalent width.
    """
    ew_set = EWContainer
    f, ax = plt.subplots(figsize=[10, 6])

    span1 = plt.axvspan(min(spectrum[0]) - cont_range * .5, min(spectrum[0]) + cont_range * .5,
                        alpha=.5, color='orange')
    span2 = plt.axvspan(max(spectrum[0]) - cont_range * .5, max(spectrum[0]) + cont_range * .5,
                        alpha=.5, color='orange')

    def onselect(x, y):
        s1min = x - cont_range * .5
        s1max = x + cont_range * .5
        span1.set_xy(np.array([[s1min] * 2 + [s1max] * 2, span1.xy[:-1, 1]]).T)

        s2min = y - cont_range * .5
        s2max = y + cont_range * .5
        span2.set_xy(np.array([[s2min] * 2 + [s2max] * 2, span2.xy[:-1, 1]]).T)

        # calculate normalized spectrum and weights of continuum regions (which is (S/N))
        norm_spec, w = spectrum_reduction.normalize_mean_flux(spectrum, x, y, cont_range=cont_range, return_weight=True)
        # crop spectrum to integrated area
        int_spec = spectrum_reduction.crop_spectrum(norm_spec, x, y)
        # EW
        ew_set.ew = np.trapz(1 - int_spec[1], x=int_spec[0])
        # EW error
        spec_disp = np.mean([x, y]) / resolution  # calculate spectral dispersion
        ew_range = y - x
        ew_set.ew_error = np.sqrt(2 * ew_range * spec_disp) / w

    plt.plot(spectrum[0], spectrum[1])

    rs = SpanSelector(ax, onselect, 'horizontal', props=dict(alpha=0.5, facecolor="tab:blue"))
    rs.set_active(True)
    plt.show()

    return ew_set.ew, ew_set.ew_error


@dataclasses.dataclass
class SpectrumContainer:
    spectrum: np.array
    weight: float = None


def normalize(spectrum: np.array, cont_range=1, return_weight=False):
    """
    Widget for normalizing spectra.
    A linear continuum is calculated by selecting two continuum ranges of width cont_range.
    On quitting the normalization window, the normalized spectrum, and optionally a weight, i.e. S/N ratio is returned.

    Parameters
    ----------
    spectrum : np.array
        Input spectrum.
    cont_range : float
        Width of the continuum ranges.
    return_weight : bool
        If True, the function additionally returns the S/N ratio calculated in the continuum ranges.

    Returns
    -------
    np.array or (np.array, float)
        Normalized spectrum or (Normalized spectrum, S/N)
    """
    out_spec = SpectrumContainer
    f, ax = plt.subplots(figsize=[10, 6])

    span1 = plt.axvspan(min(spectrum[0]) - cont_range * .5, min(spectrum[0]) + cont_range * .5,
                        alpha=.5, color='orange')
    span2 = plt.axvspan(max(spectrum[0]) - cont_range * .5, max(spectrum[0]) + cont_range * .5,
                        alpha=.5, color='orange')

    spec_plot, = plt.plot(spectrum[0], spectrum[1])

    def onselect(x, y):
        s1min = x - cont_range * .5
        s1max = x + cont_range * .5
        span1.set_xy(np.array([[s1min] * 2 + [s1max] * 2, span1.xy[:-1, 1]]).T)

        s2min = y - cont_range * .5
        s2max = y + cont_range * .5
        span2.set_xy(np.array([[s2min] * 2 + [s2max] * 2, span2.xy[:-1, 1]]).T)

        # calculate normalized spectrum and weights of continuum regions (which is (S/N))
        if return_weight:
            norm_spec, w = spectrum_reduction.normalize_mean_flux(spectrum, x, y, cont_range=cont_range,
                                                                  return_weight=return_weight)
            out_spec.spectrum = norm_spec
            out_spec.weight = w
        else:
            norm_spec = spectrum_reduction.normalize_mean_flux(spectrum, x, y, cont_range=cont_range,
                                                               return_weight=return_weight)
            out_spec.spectrum = norm_spec
        spec_plot.set_ydata(norm_spec[1])

    rs = SpanSelector(ax, onselect, 'horizontal', props=dict(alpha=0.5, facecolor="tab:blue"))
    rs.set_active(True)
    plt.show()
    if return_weight:
        return out_spec.spectrum, out_spec.weight
    else:
        return out_spec.spectrum
