import os
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from matplotlib.widgets import Slider
from matplotlib.widgets import CheckButtons
from scipy import interpolate
from scipy.optimize import minimize
import scipy.integrate as integrate
from astro_scripts_uibk.convolve import find_nearest_index
from astro_scripts_uibk import pub_plot
from astro_scripts_uibk.query import apply_wave, apply_flux
from importlib.resources import files

transmission_file_location = "filter_profiles"
# location of transmission-profile files is relative to this file
package_directory = os.path.dirname(os.path.abspath(__file__))
"""
#solar_magnitude_correction = \
-2.5*np.log10(np.pi*R_sun**2/AU**2)-5*np.log10(AU_in_pc/10)
solar_magnitude_correction = -2.5 * \
    np.log10(np.pi*696340**2/149597870.7**2) + \
    31.5721  # 31.5721 = distance modulus sun"""
solar_magnitude_correction = 41.989746

# New filters can be added by adding a new entry to the following list
# (name, transmission-profile file, zero point magnitude)
# Bessel U Filter, mean = 3600A
filter_list = [("U", "U.dat", 2.5 * np.log10(4.02747e-9)),
               # Bessel B Filter, mean = 4400A
               ("B", "B.dat", 2.5 * np.log10(6.13268e-9)),
               # Bessel V Filter, mean = 5500A
               ("V", "V.dat", 2.5 * np.log10(3.61871e-9)),
               # 2Mass J Filter, mean = 12350A
               ("J", "2MASS_J.dat", 2.5 * np.log10(3.129e-10)),
               # 2Mass H Filter, mean = 16620A
               ("H", "2MASS_H.dat", 2.5 * np.log10(1.133e-10)),
               # 2Mass K Filter, mean = 21590A
               ("K", "2MASS_K.dat", 2.5 * np.log10(4.283e-11)),
               # Wise W1 Filter, mean = 33526A
               ("W1", "W1.dat", -27.7183),
               # Wise W2 Filter, mean = 46028A
               ("W2", "W2.dat", -29.0427),
               # Wise W3 Filter, mean = 115608A
               ("W3", "W3.dat", -32.9652),
               # Wise W4 Filter, mean = 220883A
               ("W4", "W4.dat", -35.7332),
               # ANS narrow Filter, mean = 1550A
               ("ANS_15N", "ANS_15N.dat", -21.0972),
               # ANS wide Filter, mean = 1550A
               ("ANS_15W", "ANS_15W.dat", -21.0972),
               ("ANS_18", "ANS_18.dat", -21.0972),  # ANS Filter, mean = 1800A
               ("ANS_22", "ANS_22.dat", -21.0972),  # ANS Filter, mean = 2200A
               ("ANS_25", "ANS_25.dat", -21.0972),  # ANS Filter, mean = 2500A
               ("ANS_33", "ANS_33.dat", -21.0972),  # ANS Filter, mean = 3300A
               # TD1 Filter, mean = 2740A
               ("TD1_2740", "TD1_2740.dat", -21.0759),
               # TD1 Filter, mean = 2365A
               ("TD1_2365", "TD1_2365.dat", -20.9513),
               # TD1 Filter, mean = 1965A
               ("TD1_1965", "TD1_1965.dat", -20.6125),
               # TD1 Filter, mean = 1565A
               ("TD1_1565", "TD1_1565.dat", -20.4522),
               # Duplicate of 2MASS with different naming
               # 2Mass J Filter, mean = 12350A
               ("2MASS_J", "2MASS_J.dat", 2.5 * np.log10(3.129e-10)),
               # 2Mass H Filter, mean = 16620A
               ("2MASS_H", "2MASS_H.dat", 2.5 * np.log10(1.133e-10)),
               # 2Mass K Filter, mean = 21590A
               ("2MASS_K", "2MASS_K.dat", 2.5 * np.log10(4.283e-11)),
               ]


def my_integral(x: np.array, y: np.array) -> float:
    """
    Integrate y(x) by x
    is defined here to change the integral method for all uses at once
    """
    return integrate.trapezoid(y, x)


def load_filter(filter_filename: str) -> 'tuple(np.array,np.array)':
    """
    Load a filterprofile from a file;
    columns: wavelength(A), transmission

    Parameters
    ----------
    filter_filename: string; name of the file
        Wavelength has to be in Angstrom

    Returns
    -------
    tuple
        (wavelength,normalized transmission profile)
    """
    wave, transmission = np.genfromtxt(filter_filename, comments='#').T
    norm = my_integral(wave, transmission)  # Normalise the profile
    return (wave, transmission / norm)


def filtered_SED(SED_wave: np.array, SED_flux: np.array,
                 filter_wave: np.array,
                 filter_trans: np.array) -> np.array:
    """
    Apply a filter profile to a spectrum
    interpolate on the log-scale because of wavelength spacing in far-IR

    Parameters
    ----------
    SED_wave: np.array
        wavelength
    SED_flux: np.array
        radiation flux
    filter_wave: np.array
        filter wavelength
    filter_trans: np.array
        filter transmission profile

    Returns
    -------
    np.array
        [filtered wavelength points, filtered radiation flux]
    """
    idx0 = max(0, find_nearest_index(SED_wave, filter_wave[0], True) - 1)
    idx1 = min(len(SED_wave) - 1,
               find_nearest_index(SED_wave, filter_wave[-1], True) + 2)
    f = interpolate.interp1d(np.log10(SED_wave[idx0:idx1]),
                             np.log10(SED_flux[idx0:idx1]), kind="linear", assume_sorted=True)
    SED_flux = 10 ** f(np.log10(filter_wave))
    SED_flux = SED_flux * filter_trans
    return np.array([filter_wave, SED_flux])


def calc_color(SED_wave: np.array, SED_flux: np.array, filter_wave: np.array,
               filter_trans: np.array) -> float:
    """
    Calculate magnitude of a filter
    without zero point corrections

    Parameters
    ----------
    SED_wave: np.array
        wavelength
    SED_flux: np.array
        radiation flux
    filter_wave: np.array
        filter wavelength
    filter_trans: np.array
        filter transmission profile

    Returns
    -------
    float
        magnitude of the filter
    """
    SED_filtered_wave, SED_filtered_flux = filtered_SED(
        SED_wave, SED_flux, filter_wave, filter_trans)
    luminosity_observed = my_integral(SED_filtered_wave, SED_filtered_flux)
    # print(luminosity_observed)
    return -2.5 * np.log10(luminosity_observed)


class Filter:
    def __init__(self, filter_file, zeropoint):
        # zeropoint is 2.5*log10(zero_flux); zero_flux in erg/s/cm^2/A
        self.filter_file = os.path.join(package_directory, filter_file)
        self.zp = zeropoint
        self.filter_wave, self.filter_trans = load_filter(self.filter_file)
        self.central_wave = None

    def mag(self, SED_x, SED_y):
        # Magnitude of the star with the applied filter
        return calc_color(SED_x, SED_y, self.filter_wave, self.filter_trans) + self.zp

    def effective_wavelength(self, SED_x, SED_y):
        # effective wavelength according to http://svo2.cab.inta-csic.es/theory/fps/
        SED_filtered_wave, SED_filtered_flux = filtered_SED(
            SED_x, SED_y, self.filter_wave, self.filter_trans)
        denominator = my_integral(SED_filtered_wave, SED_filtered_flux)
        SED_filtered_flux *= SED_filtered_wave
        numerator = my_integral(SED_filtered_wave, SED_filtered_flux)
        return int(numerator / denominator)

    def filtered_sed(self, sed):
        """
        Convolve an SED with filter profile

        Parameters
        ----------
        sed : np.array([wave, flux])

        Returns
        -------
        np.array([wave, physical flux (erg/s/cm^2/A)])

        """
        # convolve SED with filter profile
        sed_filtered_wave, sed_filtered_flux = filtered_SED(sed[0], sed[1], self.filter_wave, self.filter_trans)

        return np.array([sed_filtered_wave, sed_filtered_flux])

    def flux(self, sed):
        """
        Calculates flux of SED with specified filter profile.
        Parameters
        ----------
        sed : np.array([wave, flux])

        Returns
        -------
        float
            Physical flux (erg/s/cm^2/A)
        """
        # convolve SED with filter profile
        sed_filtered_wave, sed_filtered_flux = filtered_SED(sed[0], sed[1], self.filter_wave, self.filter_trans)
        # return the integrated flux
        return my_integral(sed_filtered_wave, sed_filtered_flux)


filter_dictionary = {}
for f in filter_list:
    profile_path = os.path.join(package_directory, transmission_file_location, f[1])
    filter_dictionary[f[0]] = Filter(profile_path, f[2])
FilterList = [x[0] for x in filter_list]


def d_spec(SED_x: np.array, SED_y: np.array, mv: float, mass: float, logg: float, rv: float, ebmv: float) -> float:
    """
    Compute spectroscopic distance

    Parameters
    ----------
    SED_x: np.array
        wavelength [A]
    SED_y: np.array
        radiation flux [erg/cm^2/s/A]
    mv: float
        visible magnitude [mag]
    mass: float
        stellar mass [M_sol]
    logg: float
        surface gravity [log(cgs)]
    rv: float
        ratio of of total to selective extinction RV
    ebmv: float
        color excess E(B-V) [mag]

    Returns
    -------
    float
        spectroscopic distance [pc]
    """
    SED_y = reddening(SED_x, SED_y, rv, ebmv)
    ms = filter_dictionary["V"].mag(SED_x, SED_y)
    return np.round(6.6349 * 10 ** (-6) * 10 ** (0.2 * (mv - ms)) * np.sqrt(mass * 10 ** (-logg)), 2)


def d_spec_err(SED_x: np.array, SED_y: np.array, mv: float, mass: float, logg: float,
               dm: float, dg: float, rv: float, ebmv: float) -> float:
    """
    Compute error of the spectroscopic distance

    Parameters
    ----------
    SED_x: np.array
        wavelength [A]
    SED_y: np.array
        radiation flux [erg/cm^2/s/A]
    mv: float
        visible magnitude [mag]
    mass: float
        stellar mass [M_sol]
    logg: float
        surface gravity [log(cgs)]
    dm: float
        stellar mass error [M_sol]
    dg: float
        surface gravity error [log(cgs)]
    rv: float
        ratio of of total to selective extinction R(V)
    ebmv: float
        color excess E(B-V) [mag]

    Returns
    -------
    float
        spectroscopic distance uncertainty [pc]
    """
    SED_y = reddening(SED_x, SED_y, rv, ebmv)
    ms = filter_dictionary["V"].mag(SED_x, SED_y)
    out = np.round(6.6349 * 10 ** (-6) * 10 ** (0.2 * (mv - ms)) * 0.5 *
                   np.sqrt((10 ** (-logg) * (dm ** 2 + (dg * mass * 2.30259) ** 2)) / mass), 2)
    return out


def BOL(SED_x: np.array, SED_y: np.array) -> float:
    """
    Bolometric magnitude, calibrated with solar ATLAS9 model (https://wwwuser.oats.inaf.it/castelli/sun.html)
    such that BOL(SED_x_sun,SED_y_sun)+solar_magnitude_correction = 4.74.
    Without correction for distance and radius of the star (-2.5*np.log10(np.pi*R**2/d**2))

    Parameters
    ----------
    SED_x: np.array
        wavelength [A]
    SED_y: np.array
        Astrophysical flux [erg/cm^2/s/A]

    Returns
    -------
    float:
        bolometric magnitude
    """
    return -2.5 * np.log10(my_integral(SED_x, SED_y)) - 11.4915


def BC(SED_x: np.array, SED_y: np.array) -> float:
    """
    Bolometric Correction

    Parameters
    ----------
    SED_x: np.array
        wavelength [A]
    SED_y: np.array
        Astrophysical flux [erg/cm^2/s/A]

    Returns
    -------
    float
        Bolometric Correction
    """
    mV = filter_dictionary["V"].mag(SED_x, SED_y)
    bol = BOL(SED_x, SED_y)
    return np.round(bol - mV, 3)


"""
If you want to use the reddening law by Cardelli, use this one:

def reddening_cardelli(wave, flux, rgal, ebvgal, rlmc, ebvlmc,deredden=False):
    if len(wave)==0: return np.array([])
    dimw = len(wave)
    x = 10000/wave
    extgal = np.zeros(dimw)
    extlmc = np.zeros(dimw)
    a = np.zeros(dimw)
    b = np.zeros(dimw)
    fa = np.zeros(dimw)
    fb = np.zeros(dimw)
    y1 = np.zeros(dimw)
    y2 = np.zeros(dimw)
    y3 = np.zeros(dimw)
    y4 = np.zeros(dimw)
    y5 = np.zeros(dimw)
    y6 = np.zeros(dimw)
    y7 = np.zeros(dimw)
    h1 = np.zeros(dimw)
    h2 = np.zeros(dimw)
    h3 = np.zeros(dimw)
    i1 = np.where(x >= 8.00)[0]
    i2 = np.where((x >= 5.9) & (x <8.00))[0]
    i3 = np.where((x >= 3.3) & (x <5.9))[0]
    i4 = np.where((x >= 1.1) & (x <3.3))[0]
    i5 = np.where((x >= 0.2) & (x <1.1))[0]
    i6 = np.where((x < 0.2))[0]
    if len(i1) != 0:
        h1[i1] = x[i1] - 8
        h2[i1] = h1[i1]*h1[i1]
        h3[i1] = h2[i1]*h1[i1]
        a[i1] = -1.073-0.628*h1[i1]+0.137*h2[i1]-0.070*h3[i1]
        b[i1] = 13.670+4.257*h1[i1]-0.420*h2[i1]+0.374*h3[i1]
        extgal[i1] = rgal*a[i1] + b[i1]
    if len(i2) != 0:
        h1[i2] = x[i2] - 5.9
        h2[i2] = h1[i2]*h1[i2]
        h3[i2] = h2[i2]*h1[i2]
        fa[i2] = -0.04473*h2[i2]-0.009779*h3[i2]
        fb[i2] = 0.2130*h2[i2]+0.1207*h3[i2]
        a[i2] =  1.752-0.316*x[i2]-0.104/((x[i2]-4.67)**2+0.341)+fa[i2]
        b[i2] = -3.090+1.825*x[i2]+1.206/((x[i2]-4.62)**2+0.263)+fb[i2]
        extgal[i2] = rgal*a[i2] + b[i2]
    if len(i3) != 0:
        a[i3] =  1.752-0.316*x[i3]-0.104/((x[i3]-4.67)**2+0.341)
        b[i3] = -3.090+1.825*x[i3]+1.206/((x[i3]-4.62)**2+0.263)
        extgal[i3] = rgal*a[i3] + b[i3]
    if len(i4) != 0:
        y1[i4]=x[i4]-1.82
        y2[i4]=y1[i4]*y1[i4]
        y3[i4]=y2[i4]*y1[i4]
        y4[i4]=y3[i4]*y1[i4]
        y5[i4]=y4[i4]*y1[i4]
        y6[i4]=y5[i4]*y1[i4]
        y7[i4]=y6[i4]*y1[i4]
        a[i4] = 1+0.17699*y1[i4]-0.50447*y2[i4]-0.02427*y3[i4]+0.72085*y4[i4]+0.01979*y5[i4]-
                0.77530*y6[i4]+0.32999*y7[i4]
        b[i4] = 1.41338*y1[i4]+2.28305*y2[i4]+1.07233*y3[i4]-5.38434*y4[i4]-0.62251*y5[i4]+5.30260*
                y6[i4]-2.09002*y7[i4]
        extgal[i4] = rgal*a[i4] + b[i4]
    if len(i5) != 0:
        a[i5] =  0.574*x[i5]**1.61
        b[i5] = -0.527*x[i5]**1.61
        extgal[i5] = rgal*a[i5] + b[i5]
    if len(i6) != 0:
        xx = (0.2)**1.61
        hilfy = (rgal*0.574-0.527)*xx/0.05056
        if hilfy < 0.0:
            raise("ERROR DEREDDENING")
        extgal[i6] = hilfy*x[i6]*((1.86-0.48*x[i6])*x[i6]-0.1)
    j1 = np.where(x > 2.75)[0]
    j2 = np.where((x > 1.83) & (x <= 2.75))[0]
    j3 = np.where(x <= 1.83)[0]
    if len(j1) != 0:
        extlmc[j1] = rlmc - 0.236 + 0.462*x[j1] + 0.105*(x[j1])**2 + 0.454/((x[j1] - 4.557)**2 + 0.293)
    if len(j2) != 0:
        extlmc[j2] = rlmc + 2.04*(x[j2] - 1.83) + 0.094*(x[j2] - 1.83)**2
    if len(j3) != 0:
        extlmc[j3] = rlmc/3.1 * ((1.86 - 0.48*x[j3])*x[j3] - 0.1)*x[j3]
    fluxnew=np.zeros(dimw)
    if deredden:
        for ij in range(dimw):
            fluxnew[ij] = flux[ij] * (10.**(0.4*(extlmc[ij]*ebvlmc + extgal[ij]*ebvgal)))
        return fluxnew
    else:
        for ij in range(dimw):
            fluxnew[ij] = flux[ij] / (10.**(0.4*(extlmc[ij]*ebvlmc + extgal[ij]*ebvgal)))
        return fluxnew"""


def reddening(wave: np.array, flux: np.array, rv: float, ebv: float, lmc2=False,
              avg_lmc=False, deredden=False, x0: float = None, gamma: float = None, c1: float = None,
              c2: float = None, c3: float = None, c4: float = None, return_curve: bool = False) -> np.array:
    """
    Apply the reddening law by Fitzpatrick (1999).
    Paper DOI: 10.1086/316293

    Parameters
    ----------
    wave: np.array
        wavelength [A]
    flux: np.array
        Astrophysical flux [erg/cm^2/s/A]
    rv: float
        ratio of total to selective extinction
    ebv: float
        color excess E(B-V)
    deredden: bool
        If True, a observed spectrum can be dereddened.
    lmc2 : bool
    avg_lmc : bool
    x0 : float
        central wavelength of the 2175 Angstrom (UV-)-bump
    gamma : float
        Width parameter uf UV-bump
    c3 : float
        UV-bump strength
    c1 : float
        UV linear extinction intercept
    c2 : float
        UV linear extinction slope
    c4 : float
        far-UV curvature
    return_curve : bool
        If set to true, the function returns the extinction curve in magnitudes (default: False)

    Returns
    -------
    np.array:
        reddened/dereddened flux / extinction curve
    """
    if len(wave) == 0:
        return np.array([])
    # https://pyastronomy.readthedocs.io/en/latest/pyaslDoc/aslDoc/unredDoc.html
    x = 10000. / wave  # Convert to inverse microns
    curve = np.zeros(len(x))

    # Set some standard values:
    if x0 is None:
        x0 = 4.596
    if gamma is None:
        gamma = 0.99
    if c3 is None:
        c3 = 3.23
    if c4 is None:
        c4 = 0.41
    if c2 is None:
        c2 = -0.824 + 4.717 / rv
    if c1 is None:
        c1 = 2.030 - 3.007 * c2

    if lmc2:
        x0 = 4.626
        gamma = 1.05
        c4 = 0.42
        c3 = 1.92
        c2 = 1.31
        c1 = -2.16
    elif avg_lmc:
        x0 = 4.596
        gamma = 0.91
        c4 = 0.64
        c3 = 2.73
        c2 = 1.11
        c1 = -1.28

    # Compute UV portion of A(lambda)/E(B-V) curve using FM fitting function and
    # R-dependent coefficients
    xcutuv = np.array([10000.0 / 2700.0])
    xspluv = 10000.0 / np.array([2700.0, 2600.0])

    iuv = np.where(x >= xcutuv)[0]
    N_UV = len(iuv)
    iopir = np.where(x < xcutuv)[0]
    Nopir = len(iopir)
    if (N_UV > 0):
        xuv = np.concatenate((xspluv, x[iuv]))
    else:
        xuv = xspluv

    yuv = c1 + c2 * xuv
    yuv = yuv + c3 * xuv ** 2 / ((xuv ** 2 - x0 ** 2) ** 2 + (xuv * gamma) ** 2)
    yuv = yuv + c4 * (0.5392 * (np.maximum(xuv, 5.9) - 5.9) ** 2 +
                      0.05644 * (np.maximum(xuv, 5.9) - 5.9) ** 3)
    yuv = yuv + rv
    yspluv = yuv[0:2]  # save spline points

    if (N_UV > 0):
        curve[iuv] = yuv[2::]  # remove spline points

    # Compute optical portion of A(lambda)/E(B-V) curve
    # using cubic spline anchored in UV, optical, and IR
    xsplopir = np.concatenate(
        ([0], 10000.0 / np.array([26500.0, 12200.0, 6000.0, 5470.0, 4670.0, 4110.0])))
    ysplir = np.array([0.0, 0.26469, 0.82925]) * rv / 3.1
    ysplop = np.array((np.polyval([-4.22809e-01, 1.00270, 2.13572e-04][::-1], rv),
                       np.polyval(
                           [-5.13540e-02, 1.00216, -7.35778e-05][::-1], rv),
                       np.polyval(
                           [7.00127e-01, 1.00184, -3.32598e-05][::-1], rv),
                       np.polyval([1.19456, 1.01707, -5.46959e-03, 7.97809e-04, -4.45636e-05][::-1], rv)))
    ysplopir = np.concatenate((ysplir, ysplop))

    if (Nopir > 0):
        tck = interpolate.splrep(np.concatenate(
            (xsplopir, xspluv)), np.concatenate((ysplopir, yspluv)), s=0)
        curve[iopir] = interpolate.splev(x[iopir], tck)

    # Now apply extinction correction to input flux vector
    curve *= ebv
    if deredden:
        return flux * 10. ** (0.4 * curve)
    elif return_curve:
        return curve
    else:
        return flux * 10. ** (-0.4 * curve)


def load_IUE(filename: str, has_error=True) -> 'tuple(np.array,np.array,np.array)':
    """
    load an IUE spectrum (or STIS or whatever you like)
    file columns: wavelength [A], flux [erg/cm^2/s/A], flux uncertainty [erg/cm^2/s/A]

    Parameters
    ----------
    filename: string
        name of the file containing the spectrum
    has_error: bool
        set it to false if the file has no error column

    Returns
    -------
    tuple of np.array
        wavelength, flux, flux_uncertainty (set to 1 if has_error = False)
    """
    data = np.genfromtxt(filename)
    x = data.T[0]
    y = data.T[1]
    if has_error:
        y_err = data.T[2]
    else:
        y_err = np.ones(len(x))
    return (x, y, y_err)


def spec_phot_red_chisq(model_sed, spec_phot):
    """
    Calculates the reduced chi square between a model SED flux and spectrophotometry flux.
    If an error column is given, the weighted variance is calculated.

    Parameters
    ----------
    model_sed : np.array
        Model SED in Spectrum format [wave, flux].
    spec_phot : np.array
        E.g. IUE data [wave, flux, (optional: error)].

    Returns
    -------
    float
        Chi square between model and observation.
    """
    sed_x = model_sed[0]
    sed_redd = model_sed[1]
    iue_x = spec_phot[0]
    iue_y = spec_phot[1]

    idx0 = max(0, find_nearest_index(sed_x, iue_x[0], True) - 1)
    idx1 = min(len(sed_x) - 1, find_nearest_index(sed_x, iue_x[-1], True) + 2)
    # calculate interpolation function of model SED
    f_interp = interpolate.interp1d(sed_x[idx0:idx1], sed_redd[idx0:idx1], kind="quadratic")
    sed_at_iue = f_interp(iue_x)  # calculate model SED flux at observed wavelengths
    # calculate variance in mag space
    iue_diff = (2.5 * np.log10(iue_y) - 2.5 * np.log10(sed_at_iue)) ** 2
    # iue_diff = (2.5*np.log10(sed_at_iue/iue_y)) ** 2

    if len(spec_phot) > 2:
        iue_error = spec_phot[2]
        # transform the flux error into a magnitude error
        iue_e = np.square(2.5 * np.log10(iue_y + iue_error) - 2.5 * np.log10(iue_y))
        iue_diff = iue_diff / iue_e

    else:
        iue_e = np.ones(len(iue_x))

    return np.sum(iue_diff) / np.sum(1 / iue_e)


def fit_SED(SED_x, SED_y, IUE_x, IUE_y, magnitude_array, start, output_all=False,
            IUE_error=[], magnitude_error=[], normalizeV=False, showPlot=False) -> 'tuple(float,float,float)':
    """
    Fitting routine to get RV and E(B-V)
    V-magnitude IS MANDATORY!!!


    Parameters
    ----------
    SED_x: np.array
        SED wavelength
    SED_y: np.array
        SED flux
    IUE_x: np.array
        IUE wavelength (or STIS...) OR empty array
    IUE_y: np.array
        IUE flux (or STIS...) OR empty array
    magnitude_array: np.array
        contains measured magnitudes;
        IS SORTED, NEEDS A VALUE FOR EACH MAGNITUDE (np.nan if not available)
    start: list
        initial parameters for RV and E(B-V): [RV_start, EBMV_start]
    output_all: bool
        if set to True the result of the chi2 fit is shown
    IUE_error: np.array
        IUE flux error (or STIS...); IS OPTIONAL
    magnitude_error: np.array
        contains magnitude uncertainties; IS OPTIONAL
    normalizeV: bool
        if set to True, the fit goes through the measured V-magnitude
    showPlot: bool
        if set to True, the best fit is shown in a plot

    Returns
    -------
    tuple
        (RV, E(B-V), offset)
    """
    rv_start, ebmv_start = start
    SED_redd = reddening(SED_x, SED_y, rv_start, ebmv_start)
    v = filter_dictionary["V"].mag(SED_x, SED_redd)
    offset_mag_start = magnitude_array[2] - v

    def chi(args):
        rv = args[0]
        ebmv = args[1]
        if normalizeV:
            SED_redd = reddening(SED_x, SED_y, rv, ebmv)
            v = filter_dictionary["V"].mag(SED_x, SED_redd)
            mag_offset = magnitude_array[2] - v
            SED_redd = SED_redd * 10 ** (-0.4 * mag_offset)
        else:
            mag_offset = args[2]
            SED_redd = reddening(SED_x, SED_y, rv, ebmv) * 10 ** (-0.4 * mag_offset)
        # Magnitude difference
        mag_diff = np.array([filter_dictionary[myFilter].mag(
            SED_x, SED_redd) for myFilter in FilterList])
        mag_diff -= magnitude_array
        mag_diff = np.square(mag_diff)
        keep = np.logical_not(np.isnan(mag_diff))
        if len(magnitude_error) > 0:
            mag_diff = mag_diff[keep] / np.square(magnitude_error[keep])
        else:
            mag_diff = mag_diff[keep]
        mag_diff = np.sum(mag_diff)
        # IUE difference
        if len(IUE_x) != 0:
            idx0 = max(0, find_nearest_index(SED_x, IUE_x[0], True) - 1)
            idx1 = min(
                len(SED_x) - 1, find_nearest_index(SED_x, IUE_x[-1], True) + 2)
            f = interpolate.interp1d(np.log10(SED_x[idx0:idx1]), np.log10(
                SED_redd[idx0:idx1]), kind="quadratic", assume_sorted=True)
            SED_at_IUE = f(np.log10(IUE_x))
            IUE_diff = (np.log10(IUE_y) - SED_at_IUE) ** 2
            if len(IUE_error) > 0:
                IUE_e = np.square(np.log10(IUE_y + IUE_error) - np.log10(IUE_y))
                IUE_diff = IUE_diff / IUE_e

            IUE_diff = np.sum(IUE_diff)
        else:
            IUE_diff = 0
        return mag_diff + IUE_diff

    res = minimize(chi, np.array([rv_start, ebmv_start, offset_mag_start]), method='Nelder-Mead')
    """res = minimize(chi, [rv_start, ebmv_start, offset_mag_start],
                   method="L-BFGS-B", bounds=[(2, 4), (0, 1), (-np.inf, np.inf)])"""
    if output_all:
        print(res)
    rv_best = res.x[0]
    ebmv_best = res.x[1]
    if normalizeV:
        SED_redd = reddening(SED_x, SED_y, rv_best, ebmv_best)
        v = filter_dictionary["V"].mag(SED_x, SED_redd)
        offset_best = magnitude_array[2] - v
    else:
        offset_best = res.x[2]

    SED_redd = reddening(SED_x, SED_y, rv_best, ebmv_best) * 10 ** (-0.4 * offset_best)
    idx0 = max(0, find_nearest_index(SED_x, IUE_x[0], True) - 1)
    idx1 = min(len(SED_x) - 1, find_nearest_index(SED_x, IUE_x[-1], True) + 2)
    f = interpolate.interp1d(np.log10(SED_x[idx0:idx1]), np.log10(
        SED_redd[idx0:idx1]), kind="quadratic", assume_sorted=True)
    mag_diff = np.array([filter_dictionary[myFilter].mag(
        SED_x, SED_redd) for myFilter in FilterList])
    mag_diff -= magnitude_array  # difference observed-synthetic magnitude
    mean_wave = np.array([filter_dictionary[myFilter].effective_wavelength(SED_x, SED_redd)
                          for myFilter in FilterList])
    idx0 = max(0, find_nearest_index(SED_x, min(mean_wave), True) - 1)
    idx1 = min(len(SED_x) - 1, find_nearest_index(SED_x, max(mean_wave), True) + 2)
    f = interpolate.interp1d(np.log10(SED_x[idx0:idx1]), np.log10(
        SED_redd[idx0:idx1]), kind="quadratic", assume_sorted=True)
    SED_at_mag = f(np.log10(mean_wave))
    if showPlot:
        keep = SED_redd > 1e-30
        plt.plot(np.log10(SED_x[keep]), np.log10(SED_redd[keep]))
        plt.plot(np.log10(IUE_x), np.log10(IUE_y))
        plt.plot(np.log10(mean_wave), -0.4 * mag_diff +
                 SED_at_mag, "ks", markerfacecolor='none')
        plt.show()

    # disrad = np.sqrt(np.pi*10**(0.4*offset_best)) # Ratio Distance/Radius

    return (rv_best, ebmv_best, offset_best)


def plot_SED_redd(SED_x: np.array, SED_y: np.array, IUE_x: np.array, IUE_y: np.array, magnitude_array: np.array,
                  rv: float, ebmv: float, offset: float, normalizeV=False):
    """
    Plotting the reddened SED with IUE spectrum and magnitudes
    V-magnitude IS MANDATORY!!!
    It is an interactive plot to fit RV and E(B-V) by eye

    Parameters
    ----------
    SED_x: np.array
        SED wavelength
    SED_y: np.array
        SED flux
    IUE_x: np.array
        IUE wavelength (or STIS...) OR empty array
    IUE_y: np.array
        IUE flux (or STIS...) OR empty array
    rv: float
        ratio of total to selective extiction
    ebmv: float
        E(B-V)
    offset: float
        the offset provided by the fit_SED() function; ignored if normalizeV=True
    normalizeV: bool
        if set to True, the SED goes through the measured V-magnitude
    """

    if normalizeV:
        SED_redd = reddening(SED_x, SED_y, rv, ebmv)
        v = filter_dictionary["V"].mag(SED_x, SED_redd)
        offset = magnitude_array[2] - v
        SED_redd = SED_redd * 10 ** (-0.4 * offset)

    else:
        SED_redd = reddening(SED_x, SED_y, rv, ebmv) * 10 ** (-0.4 * offset)
    keep = SED_redd > 1e-30
    mag_diff = np.array([filter_dictionary[myFilter].mag(
        SED_x, SED_redd) for myFilter in FilterList])
    mag_diff = mag_diff - magnitude_array
    mean_wave = np.array([filter_dictionary[myFilter].effective_wavelength(SED_x, SED_redd)
                          for myFilter in FilterList])
    idx0 = max(0, find_nearest_index(SED_x, min(mean_wave), True) - 1)
    idx1 = min(len(SED_x) - 1, find_nearest_index(SED_x, max(mean_wave), True) + 2)
    f = interpolate.interp1d(np.log10(SED_x[idx0:idx1]), np.log10(
        SED_redd[idx0:idx1]), kind="quadratic", assume_sorted=True)
    SED_at_mag = f(np.log10(mean_wave))

    fig = plt.figure(figsize=(10, 7))

    axes_plot = plt.axes([0.1, 0.25, 0.8, 0.65])
    slider_Rv_ax = plt.axes([0.1, 0.15, 0.8, 0.05])
    slider_EBMV_ax = plt.axes([0.1, 0.1, 0.8, 0.05])
    slider_offset_ax = plt.axes([0.1, 0.05, 0.8, 0.05])
    plt.axes(axes_plot)
    if len(IUE_x) != 0:
        plt.ylim(min(-0.4 * mag_diff + SED_at_mag) - 2, 2 + max(np.log10(IUE_y)))
    else:
        plt.ylim(min(-0.4 * mag_diff + SED_at_mag) - 2,
                 2 + max(-0.4 * mag_diff + SED_at_mag) - 2)
    mag_plt, = plt.plot(np.log10(mean_wave), 0.4 * mag_diff +
                        SED_at_mag, "ks", markerfacecolor='none')
    SED_plt, = plt.plot(np.log10(SED_x[keep]), np.log10(SED_redd[keep]), "r-")
    IUE_plt, = plt.plot(np.log10(IUE_x), np.log10(IUE_y), "k-", alpha=0.5)

    RV_slider = Slider(slider_Rv_ax, "RV", rv - 1, rv + 1, valinit=rv)
    EBMV_slider = Slider(slider_EBMV_ax, "E(B-V)", 0, ebmv + 0.500, valinit=ebmv)
    OFFSET_slider = Slider(slider_offset_ax, "Offset",
                           offset - 1, offset + 1, valinit=offset)
    check = CheckButtons(plt.axes([0.8, 0.8, 0.1, 0.1]), [
        "V norm"], [normalizeV])

    def update(self):
        rv_new = RV_slider.val
        ebmv_new = EBMV_slider.val
        if check.get_status()[0]:
            SED_redd = reddening(SED_x, SED_y, rv_new, ebmv_new)
            v = filter_dictionary["V"].mag(SED_x, SED_redd)
            offset_new = magnitude_array[2] - v
            SED_redd = SED_redd * 10 ** (-0.4 * offset_new)
        else:
            offset_new = OFFSET_slider.val
            SED_redd = reddening(SED_x, SED_y, rv_new,
                                 ebmv_new) * 10 ** (-0.4 * offset_new)
        mag_diff = np.array([filter_dictionary[myFilter].mag(
            SED_x, SED_redd) for myFilter in FilterList])
        mag_diff = mag_diff - magnitude_array
        mean_wave = np.array([filter_dictionary[myFilter].effective_wavelength(
            SED_x, SED_redd) for myFilter in FilterList])
        idx0 = max(0, find_nearest_index(SED_x, min(mean_wave), True) - 1)
        idx1 = min(len(SED_x) - 1, find_nearest_index(SED_x,
                                                      max(mean_wave), True) + 2)
        f = interpolate.interp1d(np.log10(SED_x[idx0:idx1]), np.log10(
            SED_redd[idx0:idx1]), kind="quadratic", assume_sorted=True)
        SED_at_mag = f(np.log10(mean_wave))
        SED_plt.set_ydata(np.log10(SED_redd[keep]))
        mag_plt.set_ydata(0.4 * mag_diff + SED_at_mag)
        fig.canvas.draw_idle()

    RV_slider.on_changed(update)
    EBMV_slider.on_changed(update)
    OFFSET_slider.on_changed(update)
    check.on_clicked(update)
    plt.show()


# read filter_data file
filter_data_path = files('astro_scripts_uibk') / 'filter_profiles/filter_data.csv'
filter_data_df = pd.read_csv(filter_data_path, index_col=[0], header=[0], comment='#')

# load filters from filter_data file and filter profiles in "/filter_profiles"
filter_dict_2 = {}
for df_index in filter_data_df.index:
    profile_path = os.path.join(package_directory, transmission_file_location, df_index + '.dat')
    filter_dict_2[df_index] = Filter(profile_path, filter_data_df.loc[df_index, 'zp'])
    filter_dict_2[df_index].central_wave = filter_data_df.loc[df_index, 'wave']


def sed_plotter(sed: np.array, magnitude_df: pd.DataFrame, spec_phot: np.array = None, rv: float = 3.1,
                ebv: float = 0.7, block: bool = True, fitzpatrick_parameters: pd.Series = None,
                plot_filtered_sed: bool = False):
    """
    Plots observed magnitudes (magnitude_df) and optionally spectrophotometry (spec_phot) in units of physical flux
    (erg cm-2 s-1 Å-1) in black.
    A synthetic SED is plotted in red. This SED is reddened by the reddening law of Fitzpatrick.
    R_V and E(B-V) can be changed interactively.
    Photometry filters are applied to the synthetic SED and displayed as black '+'-signs.

    Parameters
    ----------
    sed : np.array([wave, flux, additional_columns])
        synthetic-/model-SED
    magnitude_df : pd.DataFrame(columns=['flux', 'wave', 'mag', additional_columns])
        Array of observed magnitudes in units of physical flux.
    spec_phot : np.array([wave, flux, additional_columns])
        Spectrophotometry, e.g. IUE.
    rv : float
        starting R_V value
    ebv : float
        starting E(B-V) value
    fitzpatrick_parameters : pd.Series
        pd.Series containing all additional Fitzpatrick extinction curve parameters: lambda_0, gamma, c1, c2, c3, c4
    block : bool
        If set to False, the code after the sed_plotter is executed (default: True).
    plot_filtered_sed : bool
        If set to True, the model SED convolved by the filter curves is plotted.

    Returns
    -------
    None
    """

    if fitzpatrick_parameters is None:
        def sed_plot_reddening(sed_wave, sed_flux, my_rv, my_ebv):
            return reddening(sed_wave, sed_flux, my_rv, my_ebv)
    else:
        def sed_plot_reddening(sed_wave, sed_flux, my_rv, my_ebv):
            return reddening(sed_wave, sed_flux, my_rv, my_ebv,
                             x0=fitzpatrick_parameters['lambda_0'],
                             gamma=fitzpatrick_parameters['gamma'],
                             c1=fitzpatrick_parameters['c1'],
                             c2=fitzpatrick_parameters['c2'],
                             c3=fitzpatrick_parameters['c3'],
                             c4=fitzpatrick_parameters['c4'])

    # redden the SED with the current E(B-V) and R_V
    sed_red_flux = sed_plot_reddening(sed[0], sed[1], rv, ebv)
    sed_red = np.array([sed[0], sed_red_flux])

    magnitude_df = apply_flux(magnitude_df)  # add physical fluxes to DataFrame
    magnitude_df = apply_wave(magnitude_df)  # add mean filter wavelengths to DataFrame

    # apply flux offset to model SED
    v_model_sed = filter_dictionary["V"].flux(sed_red)
    offset = magnitude_df.loc['V', 'flux'] / v_model_sed
    sed_red[1] *= offset

    # Plotting setup start --------------
    pub_plot.pub_style_fig()
    fig = plt.figure(figsize=(10, 7))
    ax = fig.add_axes([0.1, 0.31, 0.8, 0.65])
    slider_rv_ax = plt.axes([0.1, 0.15, 0.8, 0.05])
    slider_ebv_ax = plt.axes([0.1, 0.1, 0.8, 0.05])
    slider_offset_ax = plt.axes([0.1, 0.05, 0.8, 0.05])
    ax.set_xlabel(r"$\mathregular{log\,\lambda\,(\AA}$)")
    ax.set_ylabel(r"$\mathregular{log\,F_\lambda}$ (erg cm$^{-2}$ s$^{-1}\ \mathregular{\AA}^{-1}$)")
    rv_slider = Slider(slider_rv_ax, "RV", rv - 1, rv + 1, valinit=rv)
    ebv_slider = Slider(slider_ebv_ax, "E(B-V)", 0, ebv + 0.500, valinit=ebv)
    offset_slider = Slider(slider_offset_ax, "Offset",
                           offset - 1, offset + 1, valinit=offset)
    # Plotting setup end ----------------

    # Plot observed filter fluxes
    _, = ax.plot(magnitude_df.loc[:, 'wave'], magnitude_df.loc[:, 'flux'], "ks",
                 markerfacecolor='none')

    # If available, plot spectrophotometry
    if spec_phot is not None:
        _, = ax.plot(spec_phot[0], spec_phot[1], "k-", alpha=0.5)

        if len(spec_phot) > 2:
            ax.errorbar(spec_phot[0], spec_phot[1], yerr=spec_phot[2], color="k", alpha=0.5)

    # freeze plot limits to limits of observations
    ax.set_xscale('log')
    ax.set_yscale('log')
    y_lim = ax.get_ylim()
    x_lim = ax.get_xlim()
    ax.set_ylim(y_lim)
    ax.set_xlim(x_lim)

    # plot synthetic SED
    sed_plt, = ax.plot(sed_red[0], sed_red[1], "r-")

    # calculate filter fluxes for SED
    magnitude_df['flux_model'] = magnitude_df.apply(lambda x: filter_dict_2[x.name].flux(sed_red), axis=1)
    sed_filter_plt, = ax.plot(magnitude_df.loc[:, 'wave'], magnitude_df.loc[:, 'flux_model'], "k+",
                              markerfacecolor='none')
    # calculate filtered SEDs
    if plot_filtered_sed:
        # set up array for filtered SEDs
        filtered_sed = np.array([[], []])
        for ind in magnitude_df.index:
            filtered_sed = np.concatenate((filtered_sed, filter_dict_2[ind].filtered_sed(sed_red)), axis=1)
        filtered_sed_plot, = ax.plot(filtered_sed[0], filtered_sed[1], 'b.')

    def update(_):
        """Update the plot if a slider is moved or button is pushed."""
        rv_new = rv_slider.val
        ebv_new = ebv_slider.val

        # redden the SED with the current E(B-V) and R_V
        sed_red_flux_new = sed_plot_reddening(sed[0], sed[1], rv_new, ebv_new)
        sed_red_new = np.array([sed[0], sed_red_flux_new])

        # apply flux offset to model SED
        v_model_sed_new = filter_dict_2["V"].flux(sed_red_new)
        offset_new = magnitude_df.loc['V', 'flux'] / v_model_sed_new
        sed_red_new[1] *= offset_new

        sed_plt.set_ydata(sed_red_new[1])  # plot new reddened model SED

        # calculate filter fluxes for SED
        magnitude_df['flux_model'] = magnitude_df.apply(lambda x: filter_dict_2[x.name].flux(sed_red_new), axis=1)
        sed_filter_plt.set_ydata(magnitude_df.loc[:, 'flux_model'])

        # calculate filtered SEDs
        if plot_filtered_sed:
            # set up array for filtered SEDs
            filtered_sed_new = np.array([[], []])
            for ind_new in magnitude_df.index:
                filtered_sed_new = np.concatenate((filtered_sed_new, filter_dict_2[ind_new].filtered_sed(sed_red)),
                                                  axis=1)
            filtered_sed_plot.set_ydata(filtered_sed_new[1])

        fig.canvas.draw_idle()

    rv_slider.on_changed(update)
    ebv_slider.on_changed(update)
    offset_slider.on_changed(update)
    # check.on_clicked(update)
    plt.show(block=block)
