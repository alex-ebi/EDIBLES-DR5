import astro_scripts_uibk as asu
import matplotlib.pyplot as plt
import numpy as np
from astropy.io import fits
import pandas as pd
from pathlib import Path
from pprint import pprint
import paths
from matplotlib.widgets import SpanSelector
from matplotlib.backend_bases import MouseButton
from operator import itemgetter
from importlib.resources import files

plot_method = 'linear'
# plot_method = 'step'

asu.pub_plot.pub_style_fig()


def get_wave_path(hdr):
    try:
        wave = hdr['ESO INS GRAT1 WLEN']
    except KeyError:
        wave = hdr['ESO INS GRAT2 WLEN']

    setting = hdr['ESO INS PATH'].lower()

    return wave, setting


def setting_dependent_crop(spec, wave):
    crop_lim_dict = {346: [10, 10], 437: [13, 7], 564: [19, 4], 860: [20, 0]}
    crop_limits = np.array(crop_lim_dict[wave])
    cl_ang = [np.nanmin(spec[0]) + crop_limits[0], np.nanmax(spec[0]) - crop_limits[1]]

    return cl_ang


incl_stars = ['HD186841', 'HD183143', 'HD185859', 'HD63804']
incl_stars = pd.read_excel('/home/Alex/diss_dibs/EDIBLES/gauss_fits/sigma_zeta.xlsx').loc[:,'star_name'][:15]

obs_list = pd.read_csv(files('edibles_dr5') / 'supporting_data/obs_names.csv')
# obs_list = obs_list.loc[obs_list.OBJECT.isin(eio.split_stars)]
# obs_list = obs_list.loc[obs_list.OBJECT == 'HD183143']
obs_list = obs_list.loc[obs_list.OBJECT.isin(incl_stars)]
# obs_list = obs_list.loc[(obs_list['MJD-OBS'] > 57352) & (obs_list['MJD-OBS'] < 57450)]
# obs_list = obs_list.loc[obs_list['MJD-OBS'] < 57777]

print(obs_list)

filter_dates = False
plot_eso = False
plot_edr4 = False   
plot_2d = False
plot_linear = False
plot_average = False
plot_new_breakpoint = False
plot_optimal = False
plot_optimal_no_sky_corr = False
plot_time_dep = False
plot_best = True
plot_no_tilt = False
plot_tell_corr = True
bary_corr=False


def plot_product(spec_dir, star_name, obs_date, plt_color, use_mask=False):
    spec_list = list(spec_dir.rglob('*.fits'))
    spec_list = [item for item in spec_list if star_name in item.name]

    if filter_dates:
        if isinstance(obs_date, str):
            spec_list = [item for item in spec_list if obs_date in item.name]

    if len(spec_list) == 0:
        return False

    for spec_path in spec_list:
        hdul = fits.open(spec_path)

        hdr = hdul[0].header
        # pprint(hdr)
        data = hdul[1].data
        wave, _ = get_wave_path(hdr)

        try:
            spec = np.array([data['WAVE'], data['FLUX'], data['ERROR'], data['SKY'], data['FLAT'], data['FLUX_OPT']])
        except KeyError:
            spec = np.array([data['WAVE'], data['FLUX'], data['ERROR']])
        cl_ang = setting_dependent_crop(spec, wave)

        if use_mask:
            mask = np.array(data['MASK'], dtype=bool)
            # print(mask)
            # plt.plot(spec[0], mask)
            cropped_spec = spec.T[mask].T
        
        else:
            cropped_spec = spec

        cropped_spec = asu.spectrum_reduction.crop_spectrum(spec, cl_ang[0], cl_ang[1])
        # cropped_spec = spec
        # v_rad = hdr['HIERARCH ESO QC VRAD BARYCOR']
        if bary_corr:
            cropped_spec[0] = asu.transformations.bary_corr(cropped_spec[0], star_name=hdr['ESO OBS TARG NAME'], obs_name='paranal', obs_time=hdr['ESO TPL START'], time_format='isot')

        alpha_obj = 1

        if 'REL OBJ FWHM' in hdr:
            if hdr['REL OBJ FWHM'] > 0.3:
                alpha_obj = 0.5
                alpha_sky = 1
            else:
                alpha_obj = 1
                alpha_sky = 0.5

        # Transform to microns in vacuum
        spec[0] = asu.transformations.angstrom_air_to_vac(spec[0]) / 10000
        cropped_spec[0] = asu.transformations.angstrom_air_to_vac(cropped_spec[0]) / 10000


        if plot_method == 'step':
            plt.step(spec[0], spec[1] / np.median(spec[1]), where='mid', color=plt_color)
        else:
            # plt.plot(spec[0], spec[1] / np.median(spec[1]), plt_color, alpha=0.3)
            plt.plot(cropped_spec[0], cropped_spec[1] / np.median(spec[1]), color=plt_color)
            # plt.plot(cropped_spec[0], cropped_spec[1] / np.median(spec[5]), 'orange')
            # plt.errorbar(cropped_spec[0], cropped_spec[1] / np.median(spec[1]), yerr=cropped_spec[2] / np.median(spec[1]), color=plt_color,
                        #  alpha=1)
            # plt.annotate(f'{spec_path.name}',(cropped_spec[0][0], cropped_spec[1][0] / np.median(spec[1])))
            # if plot_optimal_no_sky_corr and 'REL OBJ FWHM' in hdr:
            #     plt.plot(cropped_spec[0],
            #              (cropped_spec[1] + cropped_spec[3]) / np.median(spec[1] + spec[3]), 'g',
            #              alpha=alpha_sky)
            # if len(spec) > 3:
            #     plt.plot(spec[0], spec[3] / np.median(spec[1]), plt_color)

    return True

# span1 = plt.axvspan(min(spectrum[0]) - cont_range * .5, min(spectrum[0]) + cont_range * .5,
#                     alpha=.5, color='orange')
# span2 = plt.axvspan(max(spectrum[0]) - cont_range * .5, max(spectrum[0]) + cont_range * .5,
#                     alpha=.5, color='orange')

def onselect(x, y):
    print(x, y)
    plt.axvspan(x, y, alpha=.5, color='orange')
    # s1min = x - cont_range * .5
    # s1max = x + cont_range * .5
    # span1.set_xy(np.array([[s1min] * 2 + [s1max] * 2, span1.xy[:-1, 1]]).T)

    # s2min = y - cont_range * .5
    # s2max = y + cont_range * .5
    # span2.set_xy(np.array([[s2min] * 2 + [s2max] * 2, span2.xy[:-1, 1]]).T)

    # # calculate normalized spectrum and weights of continuum regions (which is (S/N))
    # norm_spec, w = spectrum_reduction.normalize_mean_flux(spectrum, x, y, cont_range=cont_range, return_weight=True)
    # # crop spectrum to integrated area
    # int_spec = spectrum_reduction.crop_spectrum(norm_spec, x, y)
    # # EW
    # ew_set.ew = np.trapz(1 - int_spec[1], x=int_spec[0])
    # # EW error
    # spec_disp = np.mean([x, y]) / resolution  # calculate spectral dispersion
    # ew_range = y - x
    # ew_set.ew_error = np.sqrt(2 * ew_range * spec_disp) / w




def main():
    obs_list = pd.read_csv(files('edibles_dr5') / 'supporting_data/obs_names.csv')
    # obs_list = obs_list.loc[obs_list.OBJECT.isin(eio.split_stars)]
    # obs_list = obs_list.loc[obs_list.OBJECT == 'HD183143']
    obs_list = obs_list.loc[obs_list.OBJECT.isin(incl_stars)]
    # include_path = paths.diss_dibs / 'molecfit/EDR5/include.dat'
    include_path = files('edibles_dr5') / 'molecfit/include.dat'
    include_list = list(np.genfromtxt(include_path))

    def onselect(x, y):
        print(x, y)
        plt.axvspan(x, y, alpha=.5, color='orange')
        include_list.append([x, y])
        np.savetxt(include_path, sorted(include_list, key=itemgetter(0)), fmt='%.8f')

    def onselect_del(x, y):
        for i, row in enumerate(include_list):
            if row[0] < x < row[1]:
                plt.axvspan(row[0], row[1], alpha=.5, color='blue')
                include_list.pop(i)
                np.savetxt(include_path, sorted(include_list, key=itemgetter(0)), fmt='%.8f')


    print(obs_list)
    if not filter_dates:
        obs_list = obs_list.drop_duplicates(subset='OBJECT')
    
    # plt.figure(figsize=(30, 15))

    for i, row in obs_list.iterrows():
        print(i)
        star_name = row.OBJECT
        obs_date = row['TPL START']
        f, ax = plt.subplots(figsize=(30, 15))

        for row in include_list:
            plt.axvspan(row[0], row[1], alpha=.5, color='orange')

        rs = SpanSelector(ax, onselect, 'horizontal', props=dict(alpha=0.5, facecolor="tab:blue"), button=MouseButton(1))
        rs_del = SpanSelector(ax, onselect_del, 'horizontal', props=dict(alpha=0.5, facecolor="tab:green"), button=MouseButton(3))


        if plot_best:
            spec_dir = paths.edr5_orders_dir
            cont_flag = plot_product(spec_dir, star_name, obs_date, 'k', use_mask=False)

            if not cont_flag:
                plt.close()
                continue

        if plot_tell_corr:
            spec_dir = paths.edr5_tell_corr_dir
            spec_list = list(spec_dir.rglob('*.fits'))
            spec_list = [item for item in spec_list if star_name in item.name]
            plt_color = 'g'

            if filter_dates:
                if isinstance(obs_date, str):
                    spec_list = [item for item in spec_list if obs_date in item.name]

            if len(spec_list) > 0:
                    for spec_path in spec_list:
                        hdul = fits.open(spec_path)

                        hdr = hdul[0].header
                        pprint(hdul[1].header)
                        data = hdul[1].data
                        wave, _ = get_wave_path(hdr)

                        x = data['lambda']

                        spec = np.array([x, data['cflux']])

                        cl_ang = setting_dependent_crop(spec, wave)

                        cropped_spec = spec
                        # cropped_spec = spec
                        # v_rad = hdr['HIERARCH ESO QC VRAD BARYCOR']
                        if bary_corr:
                            cropped_spec[0] = asu.transformations.bary_corr(cropped_spec[0], star_name=hdr['ESO OBS TARG NAME'], obs_name='paranal', obs_time=hdr['ESO TPL START'], time_format='isot')

                        if plot_method == 'step':
                            plt.step(spec[0], spec[1] / np.median(spec[1]), where='mid', color=plt_color)
                        else:
                            plt.plot(cropped_spec[0], cropped_spec[1] / np.median(spec[1]), color=plt_color)

            else:
                plt.close()
                continue


        plt.ylim(0, 5)
        plt.xlabel(r'$\lambda (\mu$m)')
        plt.ylabel('Flux')
        plt.title(f'{star_name} {obs_date}')
        plt.show()


if __name__ == '__main__':
    main()
