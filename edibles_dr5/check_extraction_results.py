import matplotlib.pyplot as plt
import numpy as np
from astropy.io import fits
import pandas as pd
from pathlib import Path
from pprint import pprint
from edibles_w import eio
from edibles_DR5.workflow.edr5_functions import edr5_dir
import paths

plot_method = 'linear'



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


obs_list = pd.read_csv(paths.coding_dir / 'EDIBLES-DR5/edibles_dr5/supporting_data/obs_names.csv')
# obs_list = obs_list.loc[obs_list.OBJECT.isin(eio.split_stars)]
# obs_list = obs_list.loc[obs_list.OBJECT == 'HD185859']
# obs_list = obs_list.loc[(obs_list['MJD-OBS'] > 57352) & (obs_list['MJD-OBS'] < 57450)]
# obs_list = obs_list.loc[obs_list['MJD-OBS'] < 57777]

print(obs_list)


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


def main():
    for i, row in obs_list.iterrows():
        print(i)
        star_name = row.OBJECT
        obs_date = row['TPL START']
        plt.figure(figsize=(30, 15))

        if plot_time_dep:
            spec_dir = paths.diss_dibs / 'edibles_reduction/time_dep_flat'
            cont_flag = plot_product(spec_dir, star_name, obs_date, 'b')

            if not cont_flag:
                plt.close()
                continue

        if plot_average:
            spec_dir = paths.diss_dibs / 'edibles_reduction/orders_average'
            cont_flag = plot_product(spec_dir, star_name, obs_date, 'r')

            if not cont_flag:
                plt.close()
                continue

        if plot_new_breakpoint:
            spec_dir = paths.diss_dibs / 'edibles_reduction/new_breakpoint'
            cont_flag = plot_product(spec_dir, star_name, obs_date, 'r')

            if not cont_flag:
                plt.close()
                continue

        if plot_linear:
            spec_dir = paths.diss_dibs / 'edibles_reduction/extracted_linear'
            cont_flag = plot_product(spec_dir, star_name, obs_date, 'orange')

            if not cont_flag:
                plt.close()
                continue

        if plot_optimal:
            spec_dir = paths.diss_dibs / 'edibles_reduction/orders'
            cont_flag = plot_product(spec_dir, star_name, obs_date, 'b')

            if not cont_flag:
                plt.close()
                continue

        if plot_no_tilt:
            spec_dir = Path('/home/alex/data/EDR5/extracted_added_xfb')
            cont_flag = plot_product(spec_dir, star_name, obs_date, 'g')

            if not cont_flag:
                plt.close()
                continue

        if plot_best:
            spec_dir = paths.spectra / 'EDR5/orders'
            cont_flag = plot_product(spec_dir, star_name, obs_date, 'b', use_mask=False)

            if not cont_flag:
                plt.close()
                continue

        if plot_2d:
            # XFB extraction time dependent / super bias
            spec_dir = paths.diss_dibs / 'edibles_reduction/extracted_added_2d'
            spec_list = list(spec_dir.rglob('*.fits'))
            spec_list = [item for item in spec_list if star_name in item.name]

            if filter_dates:
                if isinstance(obs_date, str):
                    spec_list = [item for item in spec_list if obs_date in item.name]

            for spec_path in spec_list:
                hdul = fits.open(spec_path)

                hdr = hdul[0].header
                data = hdul[1].data

                error = hdul[2].data
                flux = np.sum(data, axis=0)
                wave = asu.io_asu.wave_from_dispersion(flux, hdr['CRVAL1'], hdr['CDELT1'], hdr['CRPIX1'])

                plt.plot(wave, flux / np.median(flux), 'g')

        if plot_eso:
            eso_dir = edr5_dir / 'science_archive'
            eso_files = eso_dir.glob('*.fits')
            for eso_file in eso_files:
                with fits.open(eso_file) as f:
                    hdr = f[0].header
                    data = f[1].data
                if hdr['ESO TPL START'] == obs_date:
                    eso_spec = np.array([data['WAVE'][0], data['FLUX_REDUCED'][0]])

                    eso_spec[1] /= np.median(eso_spec[1])

                    if plot_method == 'step':
                        plt.step(eso_spec[0], eso_spec[1], where='mid', color='k')
                    else:
                        plt.plot(eso_spec[0], eso_spec[1], 'k')
                    break

        if plot_edr4:
            dr4_dir = paths.spectra / 'EDIBLES/orders/'
            file_list = list(dr4_dir.rglob('*.fits'))
            file_list = [item for item in file_list if item.match(f'*{star_name}*')]
            if filter_dates:
                file_list = [item for item in file_list if item.match(f'*{"".join(obs_date[:10].split('-'))}*')]

            for edibles_file in file_list:
                edibles_spec = eio.read_spec(edibles_file, bary_corr=False)

                edibles_spec[1] /= np.median(edibles_spec[1])

                if plot_method == 'step':
                    plt.step(edibles_spec[0], edibles_spec[1], where='mid', color='g')
                else:
                    plt.plot(edibles_spec[0], edibles_spec[1], 'g')

        plt.ylim(0, 5)
        plt.xlabel(asu.pub_plot.ang_str)
        plt.ylabel('Flux')
        plt.title(f'{star_name} {obs_date}')
        plt.show()


if __name__ == '__main__':
    main()
