"""
File: alignment
Version:
Date: 13.02.2023
Author: Alexander Ebenbichler
Description:
Module for finding DIBs with similar profiles in wave number space.
"""
import pathlib
from pathlib import Path
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import scipy
from lmfit import Model
from scipy import signal, stats
from tqdm import tqdm
from sklearn.cluster import DBSCAN
import astro_scripts_uibk as asu


def rest_frame_resample(spec: np.array, query_rv: float, grid_res: float):
    """
    Transform into DIB rest frame and resample to equidistant wavenumber grid.

    Parameters
    ----------
    spec : np.array([wave, flux, additional_columns])
        Input spectrum in wavenumbers.
    query_rv : float
        Radial velocity of query in km/s.
    grid_res : float
        Resolution of resampled grid. Points per wavenumber.
        For grid_resolution = 100 , the distance between two grid points is 0.01 cm-1.

    Returns
    -------
    np.array
        Resampled spectrum in query rest frame.
    """

    # apply doppler shift to transform to cloud rest frame
    spec[0] = asu.transformations.doppler_shift_wn(spec[0], -query_rv)

    # resampling
    grid_lims = [np.nanmin(spec[0]), np.nanmax(spec[0])]
    new_grid = np.linspace(*grid_lims, int((grid_lims[1] - grid_lims[0]) * grid_res))
    spec = asu.convolve.resample(spec, new_grid, assume_sorted=False)

    return spec


def gauss_skew(x, a, m, w, s):
    """
    Returns a skewed Gaussian on a specified x-axis.
    The function is an un-skewed Gaussian multiplied by an exponential function derived from a Pearson IV distribution.

    Parameters
    ----------
    x : np.array
        Array of x-axis, typically wavelength or wavenumber.
    a : float
        Amplitude coefficient. The real amplitude, i.e. the maximum of the curve is different and has to be determined
        numerically (or you work out an analytic way).
    m : float
        Center of the un-skewed gaussian. Again, the real center is shifted because of the skewing.
    w : float
        Width of the un-skewed Gaussian. Real width is different.
    s : float
        Skewness parameter. For s = 0, the Gaussian is not skewed at all.

    Returns
    -------
    np.array
        Skewed Gaussian curve on basis of array x.
    """
    return a * np.exp(-((x - m) / (2 * w)) ** 2) * np.exp(-s * np.arctan((x - m) / w))


def gauss_skew_slope(x, a, m, w, s, cont, slope):
    """
    Returns a skewed Gaussian as an absorption in a linear continuum.

    Parameters
    ----------
    x : np.array
        Array of x-axis, typically wavelength or wavenumber.
    a : float
        Amplitude coefficient. The real amplitude, i.e. the maximum of the curve is different and has to be determined
        numerically (or you work out an analytic way).
    m : float
        Center of the un-skewed gaussian. Again, the real center is shifted because of the skewing.
    w : float
        Width of the un-skewed Gaussian. Real width is different.
    s : float
        Skewness parameter. For s = 0, the Gaussian is not skewed at all.
    cont : float
        Constant offset of continuum.
    slope : float
        Slope of continuum.

    Returns
    -------
    np.array
        Skewed Gaussian absorption on linear continuum.
    """
    return (cont + slope * x) * (1 - gauss_skew(x, a, m, w, s))


def fit_gauss_skew(dib_fwhm, query_wavenumber, query_fit_spec, cont_lim=0.02, center_limits=None, width_limits=None):
    """
    Fits a skewed gaussian to a spectrum.

    Parameters
    ----------
    dib_fwhm : float
        Nominal FWHM of the query DIB. The FWHM of the fitting function is bound close to this value.
    query_wavenumber : float
        Rest wavelength of query.
    query_fit_spec : np.array
        Spectrum with query in wavenumbers.
    cont_lim : float
        Defines where the DIB ends. It ends when the fitted function absorbs less than the central depth times cont_lim.
        Default: 0.02
    center_limits : list
        Limits of central absorption for Query. Default: [-4, 4]
    width_limits : list
        Relative limits of fwhm for query, compared to literature FWHM. Default: [0.5, 2]

    Returns
    -------
    tuple
        (fitting result, limits of query in wavenumbers, central wavelength of query,
        central depth of fit, FWHM of fit, success (bool))
    """
    if center_limits is None:
        center_limits = [-4, +4]

    if width_limits is None:
        width_limits = [0.5, 2]

    success = True
    gmodel = Model(gauss_skew_slope)
    params = gmodel.make_params()

    gauss_sigma = dib_fwhm / 2.35

    params['a'].value = .1
    params['a'].min = 0
    params['a'].max = 1
    params['m'].value = query_wavenumber
    params['m'].min = query_wavenumber + center_limits[0]
    params['m'].max = query_wavenumber + center_limits[1]
    params['w'].value = gauss_sigma
    params['w'].min = gauss_sigma * width_limits[0]
    params['w'].max = gauss_sigma * width_limits[1]
    params['s'].value = 0
    params['s'].min = -2
    params['s'].max = 2

    params['cont'].value = np.nanmedian(query_fit_spec[1])
    params['slope'].value = 0

    result = gmodel.fit(query_fit_spec[1], params, x=query_fit_spec[0])

    bw = result.best_values
    fit_x = np.linspace(np.min(query_fit_spec[0]) - 5, np.max(query_fit_spec[0]) + 5, 10000)
    p_model = gauss_skew(fit_x, bw['a'], bw['m'], bw['w'], bw['s'])
    # find central peak
    cen_ind = np.argmax(p_model)
    cen_wave = fit_x[cen_ind]
    # Set ft success to false if bounds are exceeded or feature is emission
    if cen_wave <= params['m'].min or cen_wave >= params['m'].max or result.best_values['a'] <= 0:
        print('Wavenumber outside of limits.')
        success = False

    cen_peak = cen_wave
    max_peak = np.max(p_model)  # find right and left end of fit
    over_peak = fit_x[p_model > cont_lim * max_peak]  # get part of spectrum which is over the line threshold
    if len(over_peak) == 0:
        print('Bad Pearson-fit result: ', result.best_values)
        success = False
        return result, np.array([0, 1]), query_wavenumber, 0.5, dib_fwhm, success

    query_points = np.array([np.min(over_peak), np.max(over_peak)])
    qpr = query_points[1] - query_points[0]  # Query point range
    # Extend Query point range by 10%
    query_points = np.array([query_points[0] - qpr * 0.1, query_points[1] + qpr * 0.1])
    # query_points = query_points / cen_wave * query_wavenumber

    over_fwhm = fit_x[p_model > 0.5 * max_peak]  # get part of spectrum which is over the FWHM threshold
    fit_fwhm = np.max(over_fwhm) - np.min(over_fwhm)

    if fit_fwhm <= dib_fwhm * width_limits[0] or fit_fwhm >= dib_fwhm * width_limits[1]:
        print('Width outside of limits.')
        success = False

    return result, query_points, cen_peak, max_peak, fit_fwhm, success


def fit_plotting(dark_style, spec_path, query_fit_spec, result, max_peak, query_points, q_cen, query_wavenumber):
    if dark_style:
        asu.pub_plot.dark_style_fig()
        q_style = '-'
        f_style = '--'
        vline_color = 'w'
    else:
        asu.pub_plot.pub_style_fig()
        q_style = 'r'
        f_style = 'k--'
        vline_color = 'k'

    # plot gaussian fit of query
    mpl.rcParams['xtick.top'] = False
    f, ax = plt.subplots(label=Path(spec_path).name)
    sec_ax = ax.secondary_xaxis('top', functions=(asu.transformations.wavenumber_to_angstrom,
                                                  asu.transformations.angstrom_to_wavenumber))

    ax.plot(query_fit_spec[0], query_fit_spec[1], q_style, label='Query')
    ax.plot(query_fit_spec[0], result.best_fit, f_style, label='Fit')

    # Plot the limit where the fitted profile has 2% of its maximal absorption.
    c = result.best_values['cont']
    s = result.best_values['slope']
    model_cont = c + query_fit_spec[0] * s
    flux_limit = model_cont - np.mean(model_cont) * max_peak * .02

    ax.plot(query_fit_spec[0], flux_limit, 'k-.')

    ax.axvline(query_points[0], color=vline_color, linestyle=':')
    ax.axvline(query_points[1], color=vline_color, linestyle=':')
    ax.set_xlabel(r'$\tilde \nu$(cm$^{-1}$)')
    ax.set_ylabel('Flux')
    sec_ax.set_xlabel(r'$\lambda(\AA)$')
    plt.tight_layout()
    plt.show()


def query_preparation(query_spec, spec_path, query_wavenumber, query_fit_half_width, dib_fwhm, grid_res, plot_fit=False,
                      smoothing=True, dark_style=False, sm_ratio=0.1, center_limits=None, width_limits=None,
                      cont_lim=0.02, snr_limit=3):
    """
    Prepares a query spectrum and extracts the query used for DIB alignment.

    Parameters
    ----------
    snr_limit : float
        Minimum S/N ratio of the detected query and the noise level. (Default: 3)
    query_spec : np.array
        Spectrum with query in wavenumbers.
    spec_path : Path
        Path of spectrum.
    query_wavenumber : float
        Rest wavelength of query.
    query_fit_half_width : float
        Half width of spectrum which should be used for the fitting process.
    dib_fwhm : float
        Nominal FWHM of the query DIB. The FWHM of the fitting function is bound close to this value.
    grid_res : float
        Resolution of resampled grid. Points per wavenumber.
        For grid_resolution = 100 , the distance between two grid points is 0.01 cm-1.
    plot_fit : bool
        If True, the fit is plotted. Default: False
    smoothing : bool
        If True, the spectrum will be smoothed with a boxcar kernel.
    dark_style : bool
        If True, the query fit is plotted in dark style. Default: False
    sm_ratio : float
        Smoothing range relative to query range.
    center_limits : list
        Limits of central absorption for Query. Default: [-4, 4]
    width_limits : list
        Relative limits of fwhm for query, compared to literature FWHM. Default: [0.5, 2]
    cont_lim : float
        Defines where the DIB ends. It ends when the fitted function absorbs less than the central depth times cont_lim.
        Default: 0.02

    Returns
    -------
    tuple
        (query spectrum, fitting result, central wavelength of query, RV of query, size of smoothing kernel,
        limits of query in wavenumbers in query rest frame, central depth of fit, FWHM of fit, success (bool))
    """
    if center_limits is None:
        center_limits = [-4, +4]

    if width_limits is None:
        width_limits = [0.5, 2]
    # Crop query spectrum for gaussian fit to get DIB doppler shift
    query_fit_spec = asu.spectrum_reduction.crop_spectrum(query_spec,
                                                          query_wavenumber - query_fit_half_width,
                                                          query_wavenumber + query_fit_half_width)

    # Fit query DIB with gaussian to find doppler shift
    result, query_points, q_cen, max_peak, fit_fwhm, success = fit_gauss_skew(dib_fwhm, query_wavenumber,
                                                                              query_fit_spec,
                                                                              center_limits=center_limits,
                                                                              width_limits=width_limits,
                                                                              cont_lim=cont_lim)

    # q_cen = np.mean(query_points)  # center of query is not the central peak, but the middle of the query
    print('q wn', query_wavenumber)
    print('fitted wn', q_cen)
    print('fit success', success)
    print('lit fwhm', dib_fwhm)
    print('fit fwhm', fit_fwhm)

    # Calculate Signal to noise ratio
    sn_spec = asu.spectrum_reduction.crop_spectrum(query_spec, query_points[0] - 1, query_points[0])
    nsr = np.std(sn_spec[1]) / np.mean(sn_spec[1])  # Noise over signal

    # Set fit success to False if query strength is below 3 sigma of noise
    if max_peak < nsr * snr_limit:
        print(f'Query below {snr_limit} sigma noise level.')
        print('peak', max_peak, 'N/S', nsr)
        success = False

    if plot_fit:  # If wanted, plot the fit of the query.
        fit_plotting(dark_style, spec_path, query_fit_spec, result, max_peak, query_points, q_cen, query_wavenumber)
    # calculate radial velocity of query DIB in barycentric frame
    query_rv = asu.transformations.wavenumber_to_rv(q_cen, query_wavenumber)

    # Transform into DIB rest frame and resample to equidistant wavenumber grid.
    query_spec = rest_frame_resample(query_spec, query_rv, grid_res)
    crop_points = asu.transformations.doppler_shift_wn(query_points, -query_rv)
    query_tmp = asu.spectrum_reduction.crop_spectrum(query_spec, *crop_points)
    sm_len = max(int(len(query_tmp[0]) * sm_ratio), 2)

    if smoothing and len(query_spec[0] > 0):
        query_spec = asu.spectrum_reduction.smooth_spec(query_spec, sm_len)

    query_spec = asu.spectrum_reduction.crop_spectrum(query_spec, *crop_points)
    sm_len = max(int(len(query_spec[0]) * sm_ratio), 2)

    return query_spec, result, q_cen, query_rv, sm_len, max_peak, fit_fwhm, success


def compile_iter_vars(star_names, outer_query_key, lit_dibs, data_index_outer):
    iter_vars_tmp = zip(star_names, [outer_query_key] * len(star_names))
    # Build iter_vars containing query sets
    iter_vars = []
    for star_n, q_key in iter_vars_tmp:
        query_wavelength = lit_dibs.loc[q_key, 'wl']
        # Filter index for observations which have the Query spectrum for this sight line
        queries = data_index_outer.loc[(data_index_outer['star_name'] == star_n) &
                                       (data_index_outer['x_min'] < query_wavelength) &
                                       (data_index_outer['x_max'] > query_wavelength), :]
        for _, sl_query in queries.iterrows():
            iter_vars.append((star_n, sl_query))

    return iter_vars


def plotting_query(query_obs, query_series, q_style, grid_res):
    mpl.rcParams['xtick.top'] = True
    plt.figure(Path(query_obs.spec_path).name)
    x_plot = np.arange(len(query_series)) / grid_res
    plt.plot(x_plot, query_series, q_style, label='Query')
    plt.xlabel(r'$\tilde \nu$(cm$^{-1}$)')
    plt.ylabel('Standardised Flux')
    plt.tight_layout()
    plt.show()


def plot_distances(subject_spec, subject_series, wave_grid, euc_dist, q_style, f_style):
    mpl.rcParams['xtick.top'] = False
    f, ax = plt.subplots(figsize=[15, 8])
    ax.plot(wave_grid, euc_dist, q_style)
    ax.plot(wave_grid, subject_spec[1][subject_series.index] /
            np.nanmedian(subject_spec[1][subject_series.index]) * np.nanmax(euc_dist), f_style)

    ax.set_xlabel(r'$\tilde \nu$(cm$^{-1}$)')
    sec_ax = ax.secondary_xaxis('top', functions=(asu.transformations.wavenumber_to_angstrom,
                                                  asu.transformations.angstrom_to_wavenumber))
    sec_ax.set_xlabel(r'$\lambda(\AA)$')

    plt.show()


def normalize_series(s_in, cont_points):
    # Input spectrum to be preprocessed
    s_in = s_in.to_numpy()
    # Calculate mean gradient of spectrum
    cont_gradient = (cont_points[1][1] - cont_points[0][1]) / len(s_in)
    # Produce linear slope from gradient
    cont_slope = np.cumsum(np.full(len(s_in), cont_gradient)) + cont_points[0][1]
    # Divide spectrum by linear slope - correct for slope
    s_out = s_in / cont_slope

    return s_out


def i_fit_function(x, i, cont_shift):
    return x * i + cont_shift


def calc_i_ratio(s_query, s_subject):
    fit_model = Model(i_fit_function)
    result = fit_model.fit(s_subject, i=1, cont_shift=0, x=s_query)
    return result


def convolve_lorentzian(conv_sub, grid_res, subject_spec_r):
    grid_lims = [-conv_sub * 6, conv_sub * 6]
    lor_x = np.linspace(*grid_lims, int((grid_lims[1] - grid_lims[0]) * grid_res))
    lor = asu.convolve.lorentzian(lor_x, x0=0, a=1, gam=conv_sub)
    lor_sum = np.sum(lor)
    lor /= lor_sum
    subject_spec_r_conv = []
    for i in range(len(subject_spec_r)):
        smoothed_column = np.convolve(subject_spec_r[i], lor, mode='valid')
        subject_spec_r_conv.append(smoothed_column)

    return np.array(subject_spec_r_conv)


class SpectralAligner:
    """
    Class for spectral alignment.
    """

    def __init__(self,
                 query_list: pd.DataFrame,
                 query_key: int,
                 data_index: pd.DataFrame,
                 io_function,
                 spec_dir: pathlib.Path,
                 max_dist: float = 0.5,
                 test_run: bool = False,
                 plot_query: bool = False,
                 dark_style: bool = False,
                 smoothing_range_ratio: float = 0.1,
                 star_names=None,
                 wavenumber_grid_resolution=40,
                 query_fit_range_factor=3,
                 query_width_limits=None,
                 query_center_limits=None,
                 cont_lim=0.02,
                 snr_limit=3):
        """
        Class for spectral alignment.

        Parameters
        ----------
        query_list : pd.DataFrame
            DataFrame of queries.
        query_key : int
            Name of the query in query_list.
        data_index : pd.DataFrame
            Index of spectra. Necessary Columns: x_min, x_max, star_name, spec_path.
            Needed to find the spectra for a specific sightline and/or wavelength.
        io_function : function
            IO function for reading spectra.
            Argument: file_path : str
            Returns: np.array([wave(wavenumber), flux])
        spec_dir : Path
            Path of spectra directory. All paths of data_index have to be relative to spec_dir
        max_dist : float
            Maximal allowed match distance to save as result. Minima with larger distances are ignored.
        test_run : bool
            If True, then some intermediate results are plotted. Don't use for parallel processing. (Default: False)
        plot_query : bool
            If True, the extracted query is plotted. (Default: False)
        dark_style : bool
            If True, all plots are made in dark style. (Default: False)
        smoothing_range_ratio : float
            Smoothing range relative to query range. (Default: 0.1)
        wavenumber_grid_resolution : int
            Resolution of resampled grid. Points per wavenumber.
            For grid_resolution = 100 , the distance between two grid points is 0.01 cm-1.
        query_fit_range_factor : float
            Factor to establish query fitting range. The range of a DIB will be the FWHM times the
            query_fit_range_factor.
        query_center_limits : list
            Limits of central absorption for Query. Default: [-4, 4]
        query_width_limits : list
            Relative limits of fwhm for query, compared to literature FWHM. Default: [0.5, 2]
        cont_lim : float
            Defines where the DIB ends. It ends when the fitted function absorbs less than the central depth times cont_lim.
            Default: 0.02
        snr_limit : float
            Minimum S/N ratio of the detected query and the noise level. (Default: 3)

        """
        if query_center_limits is None:
            query_center_limits = [-4, 4]
        if query_width_limits is None:
            query_width_limits = [.5, 2]

        self.qcl = query_center_limits
        self.fwhm_l = query_width_limits
        self.query_list = query_list
        self.query_key = query_key
        self.data_index = data_index
        self.io_function = io_function
        self.spec_dir = spec_dir
        self.max_dist = max_dist
        self.test_run = test_run
        self.plot_query = plot_query
        self.dark_style = dark_style
        self.sm_r = smoothing_range_ratio
        self.grid_res = wavenumber_grid_resolution

        self.query_wavenumber = query_list.loc[self.query_key, 'wn']
        self.query_fwhm = query_list.loc[self.query_key, 'fwhm_wn']
        self.qfhw = self.query_fwhm * query_fit_range_factor
        self.cont_lim = cont_lim
        self.snr_limit = snr_limit

        if star_names is None:
            self.star_names = self.data_index.loc[:, 'star_name'].unique()
        else:
            self.star_names = star_names

        self.iter_vars = compile_iter_vars(self.star_names, self.query_key, self.query_list, self.data_index)

    def preprocessing(self, s_in: pd.Series, analyse=False):
        """
        Correct constant slope around DIB and do standardisation.

        Parameters
        ----------
        s_in : pd.Series
            Series of flux values in an equidistant wavenumber grid with the resolution grid_res.
        analyse : bool
            If False, the function returns only the preprocessed spectrum.
            If True, it additionally returns the mean, standard deviation and equivalent width (in wavenumbers!) of
            the query. (Default: False)

        Returns
        -------
        np.array
            Normalized and standardized spectrum.
        """
        # Input spectrum to be preprocessed
        s_in = s_in.to_numpy()
        # Calculate mean gradient of spectrum
        cont_gradient = (s_in[-1] - s_in[0]) / len(s_in)
        # Produce linear slope from gradient
        cont_slope = np.cumsum(np.full(len(s_in), cont_gradient)) + s_in[0]
        # Divide spectrum by linear slope - correct for slope
        s_out = s_in / cont_slope
        if analyse:
            # Calculate equivalent width
            ew = np.sum(1 - s_out) / self.grid_res
        # Standardise spectrum
        spec_mean = np.nanmean(s_out)
        dib_std = np.nanstd(s_out)

        s_out = (s_out - spec_mean) / dib_std

        if analyse:

            return s_out, spec_mean, dib_std, ew
        else:
            return s_out, dib_std

    def corr_func(self, sub_win, query_series):
        """
        Calculates the distance between query and subject in rolling window operation.
        The subject in the window is compared to the query which has equal length.
        Only flux and no wavelength is used.

        Parameters
        ----------
        sub_win : pd.Series
            Subject in window of rolling window operation.
        query_series : pd.Series
            Query flux.

        Returns
        -------
        dist : float
            Euclidean distance between query and subject window.
        """
        s_std = np.nanstd(sub_win)  # calculate standard deviation of subject window
        if s_std == 0:  # if standard deviation is zero, return nan
            return np.nan
        else:
            # Standardize subject window
            s, s_std = self.preprocessing(sub_win)
            if s_std == 0 or np.isnan(s).any():
                return np.nan

            else:
                dist = scipy.spatial.distance.euclidean(s, query_series)
                return dist

    def one_query_analysis(self, star_name, query_obs):
        """
        Performs DIB alignment for one query.

        Parameters
        ----------
        star_name : string
            Star name of query sight line.
        query_obs : pd.Series
            Row of data_index. Contains spec_path and star_name.

        Returns
        -------
        pd.Dataframe
            DataFrame of DIB alignment results.

            'grid_res': Resolution of wavenumber grid (points per wavenumber)

            'spec_path_q': Path of Query spectrum relative to spectra directory.

            'spec_path_s': Path of Subject spectrum relative to spectra directory.

            'star_name': Star name

            'match_dist': d(Q,S) of this match pair

            'match_wave': Wavenumber of the subject.

            'sigma_s': Standard deviation of the subject flux.

            'mean_s': Mean flux of subject.

            'ew_s': Equivalent width of the subject in wavenumbers.

            'sigma_q': Standard deviation of the query flux.

            'mean_q': Mean flux of query.

            'center_q': Central wavenumber of the query.

            'fwhm_q': FWHM of the query in wavenumbers.

            'ew_q': Equivalent width of the query in wavenumbers.

            'query_rv': Radial velocity of the query in km/s.

            'c0xq': Wavenumber coordinate of the first continuum point of the query.

            'c0yq': Flux coordinate of the first continuum point of the query.

            'c1xq': Wavenumber coordinate of the second continuum point of the query.

            'c1yq': Flux coordinate of the second continuum point of the query.

            'c0xs': Wavenumber coordinate of the first continuum point of the subject.

            'c0ys': Flux coordinate of the first continuum point of the subject.

            'c1xs': Wavenumber coordinate of the second continuum point of the subject.

            'c1ys': Flux coordinate of the second continuum point of the subject.

        """
        if self.dark_style:
            asu.pub_plot.dark_style_fig()
            q_style = '-'
            f_style = '--'
        else:
            asu.pub_plot.pub_style_fig()
            q_style = 'r'
            f_style = 'k--'

        # Filter index for all observations of this sight line
        subjects = self.data_index.loc[self.data_index['star_name'] == star_name, :]
        # Define output dataframe of this subprocess for one sight line
        # It will contain the wavelength of the strongest peaks
        out_df = pd.DataFrame()

        spec_path = self.spec_dir / query_obs.spec_path
        print(spec_path)
        query_spec = self.io_function(spec_path)  # read query spectrum

        # remove spikes
        query_spec = asu.spectrum_reduction.filter_spikes_normalized(query_spec, threshold=0.01)

        query_spec_sm, result, q_cen, query_rv, sm_len, max_peak, fit_fwhm, success = \
            query_preparation(query_spec, spec_path, self.query_wavenumber, self.qfhw,
                              self.query_fwhm, self.grid_res,
                              plot_fit=self.plot_query, dark_style=self.dark_style,
                              sm_ratio=self.sm_r, center_limits=self.qcl, width_limits=self.fwhm_l,
                              cont_lim=self.cont_lim, snr_limit=self.snr_limit)

        if len(query_spec_sm[0]) < 2 or q_cen == self.query_wavenumber or not success:
            return None
        # save points used for correction of slope
        query_slope_points = np.array(
            [[query_spec_sm[0][0], query_spec_sm[1][0]], [query_spec_sm[0][-1], query_spec_sm[1][-1]]])

        query_series = pd.Series(query_spec_sm[1], name='query')

        # Preprocessing
        query_series, query_mean, query_sigma, query_ew = \
            self.preprocessing(query_series, analyse=True)

        query_spec_r = asu.convolve.resample(query_spec, query_spec_sm[0], assume_sorted=False)
        query_series_r = pd.Series(query_spec_r[1], name='query')

        query_series_r = normalize_series(query_series_r, query_slope_points)

        # If the standard deviation from the Query DIB rescaling is Zero, skip this iteration, because the preprocessed
        # Query is only inf values and not usable.
        # Also, don't use queries where the central depth is smaller than 0.001
        if query_sigma == 0 or np.isnan(query_series).any() or max_peak < 0.001 or \
                fit_fwhm >= self.query_fwhm * self.fwhm_l[1] or fit_fwhm <= self.query_fwhm * self.fwhm_l[0]:
            print('Query sigma', query_sigma)
            print('Is nan', np.isnan(query_series).any())
            print('max_peak < 0.001', max_peak)
            print(f'FWHM: {self.query_fwhm * self.fwhm_l[0]} < {fit_fwhm} < {self.query_fwhm * self.fwhm_l[1]}')
            return None

        query_len = len(query_series)

        if self.plot_query:
            plotting_query(query_obs, query_series, q_style, self.grid_res)
        else:

            for si, subject_obs in tqdm(subjects.iterrows()):
                subject_spec = self.io_function(self.spec_dir / subject_obs.spec_path)  # read spectrum

                # remove spikes
                subject_spec = asu.spectrum_reduction.filter_spikes_normalized(subject_spec, threshold=0.01)

                # Transform into DIB rest frame and resample to equidistant wavenumber grid.
                subject_spec = rest_frame_resample(subject_spec, query_rv, self.grid_res)

                # Smoothing
                subject_spec_sm = asu.spectrum_reduction.smooth_spec(subject_spec, sm_len)

                # resample unsmoothed subject spectrum to smoothed binning
                subject_spec_r = asu.convolve.resample(subject_spec, subject_spec_sm[0], assume_sorted=False)

                # Transform flux column of np.array to pd.Series for rolling window comparison
                subject_series = pd.Series(subject_spec_sm[1], name='subject')
                subject_series_r = pd.Series(subject_spec_r[1], name='subject_r')

                # Calculate Euclidean distance between query and subject rolling through subject
                euc_dist = subject_series.rolling(window=query_len, center=True).apply(self.corr_func,
                                                                                       args=(query_series,))

                # Normalize Euclidean distance by length of example_data points
                euc_dist /= np.sqrt(query_len)

                # Find minima or 'peaks'
                peaks, props = signal.find_peaks(-euc_dist, height=[-np.inf, 1], distance=100)
                euc_dist_peaks = -props['peak_heights']

                peaks = peaks[euc_dist_peaks < self.max_dist]  # Select peaks above threshold
                euc_dist_peaks = euc_dist_peaks[euc_dist_peaks < self.max_dist]  # Select peak heights above threshold

                wave_grid = subject_spec_sm[0][subject_series.index]  # Define wavenumber grid
                peak_waves = [wave_grid[peak] for peak in peaks]  # mark matches

                if self.test_run:
                    plot_distances(subject_spec_sm, subject_series, wave_grid, euc_dist, q_style, f_style)

                # Calculate relevant values for the matches
                for peak_ind, peak_wave, rolling_dist in zip(peaks, peak_waves, euc_dist_peaks):
                    subject_plot = subject_series[
                                   peak_ind - int(query_len * .5):peak_ind - int(query_len * .5) + query_len]

                    subject_plot_r = subject_series_r[
                                     peak_ind - int(query_len * .5):peak_ind - int(query_len * .5) + query_len]

                    # save points used for correction of slope
                    subject_slope_points = np.array(
                        [[wave_grid[subject_plot.index[0]], subject_plot.iloc[0]],
                         [wave_grid[subject_plot.index[-1]], subject_plot.iloc[-1]]])

                    match_dist = self.corr_func(pd.Series(subject_plot), query_series) / np.sqrt(query_len)
                    subject_plot, sub_mean, sub_sigma, sub_ew = self.preprocessing(
                        subject_plot,
                        analyse=True)

                    subject_plot_r = normalize_series(subject_plot_r, subject_slope_points)

                    i_result = calc_i_ratio(query_series_r, subject_plot_r)
                    i = i_result.best_values['i']
                    i_err = np.sqrt(i_result.covar[0][0])
                    i_shift = i_result.best_values['cont_shift']

                    # Calculate EW
                    if self.test_run:
                        # plt.plot(subject_plot, label='s')
                        plt.plot(subject_plot_r, label='s_r')
                        # plt.plot(query_series, label='q')
                        # plt.plot(query_series_r, label='q_r')
                        plt.plot(i_result.best_fit, label='best_fit')
                        plt.legend()
                        plt.show()

                    # Construct dataset for one match
                    out_s = pd.Series({'grid_res': self.grid_res,
                                       'spec_path_q': query_obs.spec_path,
                                       'spec_path_s': subject_obs.spec_path,
                                       'star_name': star_name,
                                       'match_dist': match_dist,
                                       'match_wave': peak_wave,
                                       'sigma_s': sub_sigma,
                                       'mean_s': sub_mean,
                                       'ew_s': sub_ew,
                                       'sigma_q': query_sigma,
                                       'mean_q': query_mean,
                                       'center_q': q_cen,
                                       'fwhm_q': fit_fwhm,
                                       'ew_q': query_ew,
                                       'query_rv': query_rv,
                                       'c0xq': query_slope_points[0][0],
                                       'c0yq': query_slope_points[0][1],
                                       'c1xq': query_slope_points[1][0],
                                       'c1yq': query_slope_points[1][1],
                                       'c0xs': subject_slope_points[0][0],
                                       'c0ys': subject_slope_points[0][1],
                                       'c1xs': subject_slope_points[1][0],
                                       'c1ys': subject_slope_points[1][1],
                                       'i': i,
                                       'i_err': i_err,
                                       'i_shift': i_shift
                                       })
                    # Append dataset to output DataFrame
                    out_df = pd.concat((out_df, out_s), axis=1, ignore_index=True)
        return out_df.T


# def
def extract_clusters_1d(r_df: pd.DataFrame, eps=0.1, mem_range=None, show=False, min_cluster_size=5):
    """
    Extracts clusters of DIB matches from DIB alignment result DataFrame.

    Parameters
    ----------
    r_df : pd.Dataframe
        DataFrame read from DIB alignment result file (pickles format) and cropped to the matches which
        should be plotted.
    eps : float
        Minimum distance between matches in wavenumber space to be considered members of the same cluster.
    mem_range : float
        Half width of range for included matches.
    show : bool
        If True, the plots are shown interactively and not saved. (Default: False)
    min_cluster_size : int
        Minimal number of matches needed to be considered a cluster.

    Returns
    -------
    pd.DataFrame
        DataFrame of the found match clusters.

        Columns:

        'mean_wavenumber': Mean wavenumber.

        'mean_angstrom': Mean wavelength.

        'pearson_r': Pearson coefficient of band strength correlation.

        'wn_range': Half width of range for included matches.

        'median_dist': Median euclidean distance.

        'std_wn': Standard deviation of the wavenumbers.

    """
    # define features for clustering: match wavenumber
    features = r_df.match_wave.to_numpy().reshape(-1, 1)
    model = DBSCAN(eps=eps, min_samples=min_cluster_size)
    # fit model and predict clusters
    yhat = model.fit_predict(features)

    # retrieve unique clusters
    clusters = np.unique(yhat)
    # create scatter plot for samples from each cluster

    hist_bins = np.arange(r_df.match_wave.min(), r_df.match_wave.max(), 0.1)

    out_df = pd.DataFrame()

    asu.pub_plot.pub_style_fig()
    mpl.rcParams['xtick.top'] = False
    f, ax = plt.subplots()
    sec_ax = ax.secondary_xaxis('top', functions=(asu.transformations.wavenumber_to_angstrom,
                                                  asu.transformations.angstrom_to_wavenumber))

    for my_cluster in clusters:
        # get row indexes for samples with this cluster
        row_ix = np.where(yhat == my_cluster)
        # create scatter of these samples
        if show:
            my_bins = hist_bins[(hist_bins > min(features[row_ix, 0][0])) & (hist_bins < max(features[row_ix, 0][0]))]
            ax.hist(features[row_ix, 0][0], my_bins)
        # mean cluster wave number
        mean_wn = np.mean(features[row_ix, 0])
        std_wn = np.std(features[row_ix, 0])
        if mem_range is None:
            wn_range = std_wn * 3
        else:
            wn_range = mem_range
        if my_cluster >= 0:
            c_mem = r_df[(r_df.match_wave > mean_wn - wn_range) & (r_df.match_wave < mean_wn + wn_range)]
            mean_ang = asu.transformations.wavenumber_to_angstrom(c_mem.match_wave.mean(), vac_to_air=True)
            s = pd.Series({'mean_wavenumber': c_mem.match_wave.mean(),
                           'mean_angstrom': mean_ang,
                           'pearson_r': stats.pearsonr(c_mem.sigma_q, c_mem.sigma_s).statistic,
                           'wn_range': wn_range,
                           'median_dist': np.nanmedian(c_mem.match_dist),
                           'std_wn': c_mem.match_wave.std()},
                          name=int(np.round(mean_ang)))

            out_df = pd.concat((out_df, s), axis=1)

    if show:
        ax.set_xlabel(asu.pub_plot.wn_str)
        sec_ax.set_xlabel(asu.pub_plot.ang_str)
        plt.tight_layout()
        plt.show()

    plt.close()

    return out_df.T


def rest_frame_crop(spec_in: np.array, query_rv: float, grid_lims, padding_factor=.5, crop=True):
    """
    Transform into DIB rest frame and transform to wavenumbers.

    Parameters
    ----------
    crop
    spec_in
    query_rv
    grid_lims
    padding_factor

    Returns
    -------
    np.array
    """

    # apply doppler shift to transform to cloud rest frame
    wave = asu.transformations.doppler_shift_wn(spec_in[0], -query_rv)
    spec = np.array([wave, spec_in[1]])

    # remove spikes
    spec = asu.spectrum_reduction.filter_spikes_normalized(spec)

    # resampling
    lim_range = (grid_lims[1] - grid_lims[0]) * padding_factor
    if crop:
        crop_lims = [grid_lims[0] - lim_range, grid_lims[1] + lim_range]
        spec = asu.spectrum_reduction.crop_spectrum(spec, *crop_lims)

    return spec


def prep_spec(spec, cont_points, sigma, mean, m_df, padding_factor=.5):
    out_spec = rest_frame_crop(spec, m_df.query_rv, cont_points.T[0], padding_factor=padding_factor)
    out_spec = asu.spectrum_reduction.normalize_spectrum_linear(out_spec, cont_points[0], cont_points[1])
    out_spec[1] = (out_spec[1] - mean) / sigma
    out_spec[0] -= np.mean(cont_points.T[0])

    return out_spec


def spec_plot(m_df: pd.DataFrame, ax, plot_offset=5, padding_factor=.5, dark_style=False, smooth=True, mean_i=None,
              sm_ratio=0.1, io_function=None, spec_dir=None):
    """
    Plots several spectra with a vertical offset.

    Parameters
    ----------
    m_df
    ax
    plot_offset
    padding_factor
    dark_style
    smooth
    mean_i
    sm_ratio
    io_function
    spec_dir

    Returns
    -------

    """
    s_names, x_lim_list = [], []
    if dark_style:
        q_color = 'dodgerblue'
        s_color = 'orange'
        face_color = 'k'
    else:
        q_color = 'r'
        s_color = 'k'
        face_color = 'w'
    to = (len(m_df) - 1) * plot_offset  # Total offset, so y-axis starts with 0
    grid_res = 40
    for i, (_, m_s) in enumerate(m_df.iterrows()):
        spec_q = io_function(spec_dir / m_s.spec_path_q)
        spec_s = io_function(spec_dir / m_s.spec_path_s)

        spec_q = prep_spec(spec_q, np.array([[m_s.c0xq, m_s.c0yq], [m_s.c1xq, m_s.c1yq]]),
                           m_s.sigma_q, m_s.mean_q, m_s, padding_factor=padding_factor)

        if mean_i is None:
            sigma_s = m_s.sigma_s
        else:
            sigma_s = m_s.sigma_q * mean_i
        spec_s = prep_spec(spec_s, np.array([[m_s.c0xs, m_s.c0ys], [m_s.c1xs, m_s.c1ys]]),
                           sigma_s, m_s.mean_s, m_s, padding_factor=padding_factor)

        # smoothed spectra
        grid_lims = [np.nanmin(spec_q[0]), np.nanmax(spec_q[0])]
        new_grid = np.linspace(*grid_lims, int((grid_lims[1] - grid_lims[0]) * grid_res))

        spec_q_sm = asu.convolve.resample(spec_q, new_grid, assume_sorted=False)

        grid_lims = [np.nanmin(spec_s[0]), np.nanmax(spec_s[0])]
        new_grid = np.linspace(*grid_lims, int((grid_lims[1] - grid_lims[0]) * grid_res))

        spec_s_sm = asu.convolve.resample(spec_s, new_grid, assume_sorted=False)

        sm_len = int((m_s.c1xq - m_s.c0xq) * grid_res * sm_ratio)

        if smooth:
            spec_q_sm = asu.spectrum_reduction.smooth_spec(spec_q_sm, sm_len)
            spec_s_sm = asu.spectrum_reduction.smooth_spec(spec_s_sm, sm_len)

            ax.plot(spec_q[0], spec_q[1] - i * plot_offset + to, q_color, alpha=.3)
            ax.plot(spec_s[0], spec_s[1] - i * plot_offset + to, color=s_color, linestyle='--', alpha=.3)

            ax.plot(spec_q_sm[0], spec_q_sm[1] - i * plot_offset + to, q_color)
            ax.plot(spec_s_sm[0], spec_s_sm[1] - i * plot_offset + to, color=s_color, linestyle='--')

        else:
            ax.plot(spec_q[0], spec_q[1] - i * plot_offset + to, q_color)
            ax.plot(spec_s[0], spec_s[1] - i * plot_offset + to, color=s_color, linestyle='--')

        s_names.append((m_s.star_name, m_s.sigma_s / m_s.sigma_q))
        x_lim_list.append([min(spec_q[0]), max(spec_s[0])])

    x_lims = np.median(np.array(x_lim_list), axis=0)

    if len(s_names) > 0:
        ax.set_xlim(x_lims)
        for i, (star_name, ratio) in enumerate(s_names):
            plt.annotate(f'{star_name}', (x_lims[0] * .95, - i * plot_offset + 2 + to),
                         ha='left',
                         va='bottom',
                         bbox=dict(facecolor=face_color))


def res_plot(m_df: pd.DataFrame, ax, padding_factor=.5, grid_res=40, smooth_kernel=None, ax2=None,
             io_function=None, spec_dir=None):
    q_spectra, s_spectra = [], []
    for i, (_, m_s) in enumerate(m_df.iterrows()):
        spec_q = io_function(spec_dir / m_s.spec_path_q)
        spec_s = io_function(spec_dir / m_s.spec_path_s)

        spec_q = prep_spec(spec_q, np.array([[m_s.c0xq, m_s.c0yq], [m_s.c1xq, m_s.c1yq]]),
                           m_s.sigma_q, m_s.mean_q, m_s, padding_factor=padding_factor)

        spec_s = prep_spec(spec_s, np.array([[m_s.c0xs, m_s.c0ys], [m_s.c1xs, m_s.c1ys]]),
                           m_s.sigma_s, m_s.mean_s, m_s, padding_factor=padding_factor)

        # shift wavenumber 0 from center of window to maximum absorption
        cen_q_wn = asu.transformations.doppler_shift_wn(m_s.center_q, -m_s.query_rv)
        cen_shift = np.mean([m_s.c0xq, m_s.c1xq]) - cen_q_wn
        spec_q[0] += cen_shift
        spec_s[0] += cen_shift

        if smooth_kernel is not None:
            spec_q = asu.spectrum_reduction.smooth_spec(spec_q, smooth_kernel)
            spec_s = asu.spectrum_reduction.smooth_spec(spec_s, smooth_kernel)

        q_spectra.append(spec_q)
        s_spectra.append(spec_s)

    wave_mins = [min(spec[0]) for spec in q_spectra]
    wave_mins = wave_mins + [min(spec[0]) for spec in s_spectra]

    wave_maxs = [max(spec[0]) for spec in q_spectra]
    wave_maxs = wave_maxs + [max(spec[0]) for spec in s_spectra]

    # Calculate grid for residuals
    rg_min = max(wave_mins)
    rg_max = min(wave_maxs)

    if rg_min >= rg_max:
        return

    res_grid = np.linspace(rg_min, rg_max, int((rg_max - rg_min) * grid_res))

    residuals = []
    coadd_q, coadd_s = [], []

    for spec_q, spec_s in zip(q_spectra, s_spectra):
        spec_q = asu.convolve.resample(spec_q, res_grid, assume_sorted=False)
        spec_s = asu.convolve.resample(spec_s, res_grid, assume_sorted=False)

        residuals.append(spec_s[1] - spec_q[1])
        if ax2 is not None:
            coadd_q.append(spec_q[1])
            coadd_s.append(spec_s[1])

    residuals = np.array(residuals)
    res_mean = np.nanmean(residuals, axis=0)
    res_std = np.nanstd(residuals, axis=0)

    q_mean = np.nanmean(coadd_q, axis=0)
    s_mean = np.nanmean(coadd_s, axis=0)

    ax.plot(res_grid, res_mean, 'k')
    ax.fill_between(res_grid, res_mean - res_std, res_mean + res_std)
    if ax2 is not None:
        ax2.plot(res_grid, q_mean, '-')
        ax2.plot(res_grid, s_mean, '--')

    return


def plot_matches(m_df: pd.DataFrame, query_key, mean_ang, plot_path, sample_number=7, dark_style=False,
                 padding_factor=.5, annotate=False, show=False, smooth=True, sm_ratio=0.1, io_function=None,
                 spec_dir=None, sigma_zeta_df=None, sc_df=None):
    """
    Plots matching DIB pairs on a A4 page.

    Parameters
    ----------
    m_df : pd.Dataframe
        DataFrame read from DIB alignment result file (pickles format) and cropped to the matches which
        should be plotted.
    query_key : int
        Key of the query DIB.
    mean_ang : float
        Mean wavelength of detected matches.
    plot_path : Path
        Filename of plot without suffix. PDF and PNG will be created.
    sample_number : int
        Number of spectra which will be plotted per spectrum panel.
    dark_style : bool
        Bool to set dark plot style. (Default: False)
    padding_factor : float
        Padding which will be added to each spectrum plot in multiples of the fitted DIB range.
    annotate : bool
        If True, all example_data points in the correlation plots are annotated. (Default: False)
    show : bool
        If True, the plots are shown interactively and not saved. (Default: False)
    smooth : bool
        If True, the smoothed spectra are shown, along with the un-smoothed in the background.
        If False, only the un-smoothed spectra are shown. (Default: False)
    sm_ratio :
        Smoothing range relative to query range. (Default: 0.1)
    io_function : function
        IO function for reading spectra.
        Argument: file_path : str
        Returns: np.array([wave(wavenumber), flux])
    spec_dir : Path
        Path of spectra directory. All paths of data_index have to be relative to spec_dir
    sigma_zeta_df : pd.DataFrame
        DataFrame with EW5797/EW5780 values for the sight lines
    sc_df : pd.DataFrame
        DataFrame of DIB alignment results for single cloud sight lines.

    Returns
    -------
    None
    """
    m_df = m_df[(m_df['ew_q'] > 0) & (m_df['ew_s'] > 0)]

    if dark_style:
        asu.pub_plot.dark_style_fig()
        f = plt.figure(layout='compressed', figsize=(16, 9), label=f'{query_key}_{int(np.round(mean_ang))}')
        gs = f.add_gridspec(6, 4)

    else:
        asu.pub_plot.pub_style_fig()
        f = plt.figure(layout='compressed', figsize=(10, 13), label=f'{query_key}_{int(np.round(mean_ang))}')
        gs = f.add_gridspec(5, 3, height_ratios=[4, 4, 3, 2, 3])

    mpl.rcParams.update({'font.size': 14})
    # Sort by match distance
    plot_m = m_df.sort_values(by=['match_dist'])
    # Drop duplicate sightlines
    plot_m = plot_m.drop_duplicates(subset='star_name')

    plot_offset = 5
    ax_spec_1 = f.add_subplot(gs[:-2, 0])
    spec_plot(plot_m.iloc[:sample_number, :], ax_spec_1, plot_offset=plot_offset, padding_factor=padding_factor,
              dark_style=dark_style, smooth=smooth, sm_ratio=sm_ratio, io_function=io_function, spec_dir=spec_dir)
    ax_spec_1.set_ylim(-4, sample_number * plot_offset)

    ax_spec_2 = f.add_subplot(gs[:-2, 1])
    spec_plot(plot_m.iloc[-sample_number:, :], ax_spec_2, plot_offset=plot_offset,
              padding_factor=padding_factor, dark_style=dark_style, smooth=smooth, sm_ratio=sm_ratio,
              io_function=io_function, spec_dir=spec_dir)
    ax_spec_2.set_ylim(-4, sample_number * plot_offset)

    ax_spec_sc = f.add_subplot(gs[:-2, 2])
    if sc_df is not None:
        # Sort by match distance
        sc_df = sc_df.sort_values(by=['match_dist'])
        # Drop duplicate sightlines
        sc_df = sc_df.drop_duplicates(subset='star_name')
        spec_plot(sc_df.iloc[-sample_number:, :], ax_spec_sc, plot_offset=plot_offset,
                  padding_factor=padding_factor, dark_style=dark_style, smooth=smooth, sm_ratio=sm_ratio,
                  io_function=io_function, spec_dir=spec_dir)
        ax_spec_sc.set_ylim(-4, sample_number * plot_offset)

    for ax_spec in [ax_spec_1, ax_spec_2, ax_spec_sc]:
        ax_spec.set_xlabel(r'$\tilde \nu$(cm$^{-1}$)')
    ax_spec_1.set_ylabel('Standardised Flux + Offset')

    if dark_style:
        ax_res = f.add_subplot(gs[-2:, 0])
    else:
        ax_res = f.add_subplot(gs[-2, 0])
    res_plot(plot_m.iloc[:sample_number * 2, :], ax_res, io_function=io_function, spec_dir=spec_dir)
    ax_res.set_xlim(ax_spec_1.get_xlim())
    ax_res.set_title(r'$\mu(residual)$')
    ax_res.set_xlabel(r'$\tilde \nu$(cm$^{-1}$)')
    ax_res.set_ylabel('Standardised Flux')

    if dark_style:
        ax_sigma = f.add_subplot(gs[2:4, 3])
    else:
        ax_sigma = f.add_subplot(gs[-1, 1])
    plt.scatter(m_df.sigma_q, m_df.sigma_s, c=m_df.match_dist * 100)

    if annotate:
        for _, m_s in m_df.iterrows():
            plt.annotate(m_s.star_name, xy=(m_s.sigma_q, m_s.sigma_s))
    pearson_r = stats.pearsonr(m_df.sigma_q, m_df.sigma_s).statistic
    sigma_ratio = np.median(m_df.sigma_s / m_df.sigma_q)

    ax_sigma.set_title(f'r = {pearson_r: .2f}, ' +
                       r'Med($\sigma_\mathregular{S}/\sigma_\mathregular{Q}$)' + f'= {sigma_ratio:.2f}')
    ax_sigma.set_xlabel(r'$\sigma$' + f'(DIB {query_key})')
    ax_sigma.set_ylabel(r'$\sigma$' + f'(DIB {int(np.round(mean_ang))})')
    ax_sigma.set_xlim(xmin=0)
    ax_sigma.set_ylim(ymin=0.000000001)

    ax_sz = f.add_subplot((gs[-1, 2]))
    ax_sz.set_xlabel('EW5797/EW5780')
    ax_sz.set_ylabel(f'I({int(np.round(mean_ang))}/{query_key})')
    if sigma_zeta_df is not None:
        df_sz = plot_m.loc[plot_m.star_name.isin(sigma_zeta_df.index)]
        df_sz.loc[:, 'I'] = df_sz.loc[:, 'sigma_s'] / df_sz.loc[:, 'sigma_q']

        sigma_zeta_col = sigma_zeta_df.loc[df_sz.star_name, 'EW5797/EW5780']

        ax_sz.scatter(sigma_zeta_col, df_sz.I, c=df_sz.match_dist * 100)
        ax_sz.set_title(f'r={stats.pearsonr(sigma_zeta_col, df_sz.I).statistic:.2f}')

        ax_sz.set_ylim(ymin=0)

    if dark_style:
        ax_ew = f.add_subplot(gs[:2, 3])
    else:
        ax_ew = f.add_subplot(gs[-1, 0])

    if not isinstance(query_key, str):
        # Transform EW from wavenumber to mA
        ew_q = m_df.ew_q / 10 ** 5 * query_key ** 2
        ew_s = m_df.ew_s / 10 ** 5 * mean_ang ** 2
        plt.scatter(ew_q, ew_s, c=m_df.match_dist * 100)
        ew_pearson_r = stats.pearsonr(ew_q, ew_s).statistic
        ax_ew.set_title(f'r = {ew_pearson_r: .2f}')
        ax_ew.set_xlabel(r'$EW$' + f'(DIB {query_key})' + r'(m$\AA$)')
        ax_ew.set_ylabel(r'$EW$' + f'(DIB {int(np.round(mean_ang))})' + r'(m$\AA$)')
        ax_ew.set_xlim(0, ax_ew.get_xlim()[1])
        ax_ew.set_ylim(0.0001, ax_ew.get_ylim()[1])

    plt.colorbar(label=r'$d(Q,S) \cdot 100$', ax=[ax_ew, ax_sz, ax_sigma], location='bottom', aspect=30, shrink=0.4)

    mpl.rcParams['xtick.top'] = False
    if dark_style:
        ax_rv = f.add_subplot(gs[-2:, -1])
        rv_style = 'orange'
    else:
        ax_rv = f.add_subplot(gs[-2, 2])
        rv_style = 'k'

    ax_rv.hist(m_df.match_wave, bins=30, color=rv_style)
    ax_rv.set_xlabel(r'$\tilde \nu$(cm$^{-1}$)')
    ax_rv.set_xlim(np.nanmean(m_df.match_wave) - 2, np.nanmean(m_df.match_wave) + 2)
    sec_ax = ax_rv.secondary_xaxis('top', functions=(asu.transformations.wavenumber_to_angstrom,
                                                     asu.transformations.angstrom_to_wavenumber))
    sec_ax.set_xlabel(r'$\lambda(\AA)$')

    if dark_style:
        ax_dh = f.add_subplot(gs[2:4, 2])

    else:
        ax_dh = f.add_subplot(gs[-2, 1])

    ax_dh.set_title(f'{len(m_df.match_dist)} counts')
    ax_dh.hist(m_df.match_dist * 100, color='r', bins=20)
    ax_dh.set_xlim(xmin=0)
    ax_dh.set_xlabel(r'$d(Q,S) \cdot 100$')
    ax_dh.set_ylabel('Counts')

    if show:
        plt.show()
    else:
        plt.savefig(str(plot_path) + '.pdf')
        plt.savefig(str(plot_path) + '.png')
        plt.close()


def auto_plot_clusters(io_function=None, spec_dir=None,
                       result_file=None, mem_range=1., query_key=None, number_cut=None, pearson_r_cut=None, eps=0.1,
                       plot_dir=None, sort_by=None, ascending=True,
                       padding_factor=.5,
                       match_dist_cut=None, ang_range=None, dark_style=False, show=False, excluded_stars=None,
                       sample_number=7, annotate=False, min_cluster_size=5, sm_ratio=0.1, smooth=True,
                       single_cloud_sightlines=None, sigma_zeta_df=None, cluster_df_path=None):
    """
    Automatically plotting some matches for a query DIB.
    Several parameters can be changed to change the output.

    Parameters
    ----------
    result_file : Path
        Name of DIB alignment result file (pickle format).
    mem_range : float
        Half width of range for included matches.
    query_key : int
        Name of the query DIB.
    number_cut : int
        Maximum number of matches to be plotted.
    pearson_r_cut : float
        Minimum Pearson coefficient of band strength correlation.
    eps : float
        Minimum distance between matches in wavenumber space to be considered members of the same cluster.
    plot_dir : Path
        Directory where the plots will be saved.
    sort_by : str
        Key to sort found clusters by. (Default: None)
    ascending : bool
        If True, found clusters are sorted ascending. (Default: True)
    padding_factor : float
        Padding which will be added to each spectrum plot in multiples of the fitted DIB range.
    match_dist_cut : float
        Maximum match distance to be considered BEFORE match clusters are found.
    ang_range : list
        If set, only matches in this wavelength range are considered.
    dark_style : bool
        Bool to set dark plot style. (Default: False)
    show : bool
        If True, the plots are shown interactively and not saved. (Default: False)
    excluded_stars : list
        list of excluded stars.
    sample_number : int
        Number of spectra which will be plotted per spectrum panel.
    annotate : bool
        If True, all example_data points in the correlation plots are annotated. (Default: False)
    min_cluster_size : int
        Minimal number of matches needed to be considered a cluster.
    sm_ratio :
        Smoothing range relative to query range. (Default: 0.1)
    smooth : bool
        If True, the smoothed spectra are shown, along with the un-smoothed in the background.
        If False, only the un-smoothed spectra are shown. (Default: False)
    io_function : function
        IO function for reading spectra.
        Argument: file_path : str
        Returns: np.array([wave(wavenumber), flux])
    spec_dir : Path
        Path of spectra directory. All paths of data_index have to be relative to spec_dir
    single_cloud_sightlines : list
        List of star names for single cloud sight lines.
    sigma_zeta_df : pd.DataFrame
        DataFrame with EW5797/EW5780 values for the sight lines.
    cluster_df_path : str
        Path of the file containing the found clusters of profile matches.

    Returns
    -------
    None
    """
    if not result_file.is_file():
        return

    r_df = pd.read_pickle(result_file)

    if excluded_stars is not None:
        for ex_star in excluded_stars:
            r_df = r_df[r_df['star_name'] != ex_star]

    if match_dist_cut is not None:
        r_df = r_df[r_df['match_dist'] < match_dist_cut]

    c_df = r_df.sort_values(by='match_wave')

    cluster_df = asu.alignment.extract_clusters_1d(c_df, eps=eps, mem_range=mem_range, show=show,
                                                   min_cluster_size=min_cluster_size)

    if cluster_df.empty:
        return

    if ang_range is not None:
        cluster_df = cluster_df[
            (cluster_df['mean_angstrom'] < ang_range[1]) & (cluster_df['mean_angstrom'] > ang_range[0])]

    if sort_by is not None:
        cluster_df.sort_values(sort_by, inplace=True, ascending=ascending)

    if pearson_r_cut is not None:
        cluster_df = cluster_df.loc[cluster_df['pearson_r'] > pearson_r_cut, :]
    if number_cut is not None:
        cluster_df = cluster_df.iloc[:number_cut, :]

    if cluster_df_path is not None:
        cluster_df.to_excel(cluster_df_path)

    for _, cluster_s in cluster_df.iterrows():
        mean_wave = cluster_s.mean_wavenumber
        mean_ang = cluster_s.mean_angstrom

        if query_key - 2 < mean_ang < query_key + 2:
            continue

        m_df = r_df.loc[(mean_wave - mem_range < r_df['match_wave']) & (r_df['match_wave'] < mean_wave + mem_range), :]
        if single_cloud_sightlines is None:
            sc_df = None
        else:
            sc_df = m_df.loc[m_df.star_name.isin(single_cloud_sightlines)]

        plot_path = plot_dir / f'profiles_{query_key}_{int(np.round(mean_ang))}'
        asu.alignment.plot_matches(m_df, query_key, mean_ang, plot_path, sample_number=sample_number,
                                   dark_style=dark_style,
                                   padding_factor=padding_factor, annotate=annotate, show=show, sm_ratio=sm_ratio,
                                   smooth=smooth,
                                   io_function=io_function, spec_dir=spec_dir, sc_df=sc_df, sigma_zeta_df=sigma_zeta_df)


def transform_normalized_dib(spectrum: np.array, strength_factor: float, wn_shift: float):
    """
    Transforms a DIB in an already normalized spectrum by scaling its strength and shifting it, to match a DIB profile
    family member.

    Parameters
    ----------
    spectrum : np.array([wave, flux, additional_columns])
        Input spectrum with wavelengths in Angstroms.
    strength_factor : float
        Intensity ratio between the DIBs.
    wn_shift : float
        Shift between DIBs in wavenumbers.

    Returns
    -------
    np.array
        Rescaled spectrum. Wavelengths are in Angstroms.
    """
    # calculate optical depth at all flux points
    opt_depth = - np.log(spectrum[1])
    # rescale optical depth with strength factor
    rescaled_opt_depth = opt_depth * strength_factor
    # calculate flux from optical depth
    rescaled_flux = np.exp(-rescaled_opt_depth)
    # rescaled_flux = 1 - strength_factor * (1 - spectrum[1])
    wn = asu.transformations.angstrom_to_wavenumber(spectrum[0], air_to_vac=True)
    wn += wn_shift
    ang = asu.transformations.wavenumber_to_angstrom(wn, vac_to_air=True)

    return np.array([ang, rescaled_flux])
