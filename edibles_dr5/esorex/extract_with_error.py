"""
Extracting all observations from an observation with same "ESO OBS START".
Errors are included and added quadratically.
"""
from pathlib import Path
import os
from astropy.io import fits
from pprint import pprint
import numpy as np
from matplotlib import pyplot as plt
from edibles_dr5 import paths
from edibles_dr5.flats.check_breakpoints import breakpoints
from importlib.resources import files
from astropy.time import Time
import pandas as pd


def wave_from_map(wave_map):
    """
    Make spectrum from wavelength map and fxb file

    Parameters
    ----------
    wave_map

    Returns
    -------
    np.ndarray
    """

    extr_cols = []

    for col in wave_map.T:
        # Get unique values from each column, as each order has the same wavelength values along a column
        extr_col = np.unique(col)
        extr_col = extr_col[extr_col != 0]  # Only take values which are not zero. Those are the inter-order regions.
        extr_cols.append(extr_col)

    col_lens = [len(x) for x in extr_cols]
    max_col_len = np.max(col_lens)

    # Determine columns with maximal length
    max_cols = [i for i, col_len in enumerate(col_lens) if col_len == max_col_len]
    max_col_mid = np.mean(max_cols)

    # Each column is along the cross dispersion axis. The bluest or reddest order can be off the chip in the corner.
    # So there is a missing value and the column is too short.
    # If this is the case, we append a np.nan value.

    for i, extr_col in enumerate(extr_cols):
        if len(extr_col) < max_col_len:
            # If we are LEFT of the middle of the chip and the column is too short, we append a np.nan to the first
            # value (bottom left), because the orders are always slanted from bottom left to top right.
            nan_col = np.full(max_col_len - len(extr_col), np.nan)  # Make column of nans with length of missing values
            if i < max_col_mid:
                extr_cols[i] = np.concatenate((nan_col, extr_col))
            else:
                extr_cols[i] = np.concatenate((extr_col, nan_col))
    try:
        extr_cols = np.array(extr_cols).T
    except ValueError as e:
        plt.imshow(wave_map)
        plt.savefig(files('edibles_dr5') / 'error_log/wavemap_error.png')
        plt.close()
        raise e

    return extr_cols


def parse_fxb_name(wave_map_file, xfb_fxb_string='fxb'):
    if wave_map_file.name == 'wave_map_blue_bac.fits':
        fxb_file = f'{xfb_fxb_string}_blue.fits'
    elif wave_map_file.name == 'wave_map_redl_bac.fits':
        fxb_file = f'{xfb_fxb_string}_redl.fits'
    elif wave_map_file.name == 'wave_map_redu_bac.fits':
        fxb_file = f'{xfb_fxb_string}_redu.fits'
    else:
        print(wave_map_file.name)
        raise FileNotFoundError('No correct wavemap file!')
    return fxb_file


def modify_sof(sof_file, wm_file, fxb_file, time_dependent_flats=True):
    super_bias_blue = paths.edr5_dir / 'superbias/superbias_blue.fits'
    super_bias_redl = paths.edr5_dir / 'superbias/superbias_redl.fits'
    super_bias_redu = paths.edr5_dir / 'superbias/superbias_redu.fits'

    with fits.open(wm_file) as f:
        hdr = f[0].header

    print(wm_file)

    mjd_obs = hdr['MJD-OBS']

    try:
        wave_setting = hdr['ESO INS GRAT1 WLEN']
    except KeyError:
        wave_setting = hdr['ESO INS GRAT2 WLEN']

    if 'blue' in fxb_file.name:
        setting = 'blue'
    elif 'redl' in fxb_file.name:
        setting = 'red'
    elif 'redu' in fxb_file.name:
        setting = 'red'
    else:
        raise ValueError(f'Wrong setting suffix.')
    
    print(breakpoints)
    print(mjd_obs)
    
    superflat_index = np.searchsorted(breakpoints, mjd_obs)

    print(superflat_index)

    t1 = breakpoints[superflat_index-1]
    t2 = breakpoints[superflat_index]

    t1_human = Time(t1, format='mjd').iso.split(' ')[0]
    t2_human = Time(t2, format='mjd').iso.split(' ')[0]

    if time_dependent_flats:
        superflat_name = f'{wave_setting:.0f}nm_{setting}_{t1_human}_{t2_human}'
        superflat_name_l = f'{wave_setting:.0f}nm_{setting}l_{t1_human}_{t2_human}'
        superflat_name_u = f'{wave_setting:.0f}nm_{setting}u_{t1_human}_{t2_human}'
        superflat_dir = paths.edr5_dir / 'superflats' / 'data'
    else:
        superflat_name = f'{wave_setting:.0f}nm_{setting}'
        superflat_name_l = f'{wave_setting:.0f}nm_{setting}l'
        superflat_name_u = f'{wave_setting:.0f}nm_{setting}u'
        superflat_dir = paths.edr5_dir / 'superflats'
    

    if setting == 'blue':
        super_flat_file_l = superflat_dir / f'superflat_{superflat_name}.fits'
        super_flat_bkg_file_l = superflat_dir / f'superflat_bkg_{superflat_name}.fits'
        super_flat_file_u = super_flat_file_l
        super_flat_bkg_file_u = super_flat_bkg_file_l
    elif setting == 'red':
        super_flat_file_l = superflat_dir / f'superflat_{superflat_name_l}.fits'
        super_flat_bkg_file_l = superflat_dir / f'superflat_bkg_{superflat_name_l}.fits'
        super_flat_file_u = superflat_dir / f'superflat_{superflat_name_u}.fits'
        super_flat_bkg_file_u = superflat_dir / f'superflat_bkg_{superflat_name_u}.fits'
    else:
        raise ValueError('Wrong wavelength setting!')
    with open(sof_file, 'r') as f:
        lines = f.readlines()

    for i, line in enumerate(lines):
        if 'MASTER_FLAT_BLUE' in line:
            line_end = line.split(' ')[-1]
            lines[i] = f'{super_flat_file_l} {line_end}'
        elif 'BKG_FLAT_' in line:
            line_end = line.split(' ')[-1]
            lines[i] = f'{super_flat_bkg_file_l} {line_end}'
        if 'MASTER_FLAT_REDL' in line:
            line_end = line.split(' ')[-1]
            lines[i] = f'{super_flat_file_l} {line_end}'
        elif 'BKG_FLAT_REDL' in line:
            line_end = line.split(' ')[-1]
            lines[i] = f'{super_flat_bkg_file_l} {line_end}'
        elif 'MASTER_FLAT_REDU' in line:
            line_end = line.split(' ')[-1]
            lines[i] = f'{super_flat_file_u} {line_end}'
        elif 'BKG_FLAT_REDU' in line:
            line_end = line.split(' ')[-1]
            lines[i] = f'{super_flat_bkg_file_u} {line_end}'
        elif 'MASTER_BIAS_BLUE' in line:
            line_end = line.split(' ')[-1]
            lines[i] = f'{super_bias_blue} {line_end}'
        elif 'MASTER_BIAS_REDL' in line:
            line_end = line.split(' ')[-1]
            lines[i] = f'{super_bias_redl} {line_end}'
        elif 'MASTER_BIAS_REDU' in line:
            line_end = line.split(' ')[-1]
            lines[i] = f'{super_bias_redu} {line_end}'

    new_sof_file = str(sof_file).replace('input.sof', 'input_edibles.sof')
    with open(new_sof_file, 'w') as f:
        f.writelines(lines)



def main():
    obs_list_path = '/home/alex/PycharmProjects/EDIBLES-DR5/edibles_dr5/supporting_data/obs_names.csv'
    obs_list = pd.read_csv(obs_list_path, index_col=0)
    obs_list = obs_list.loc[obs_list.OBJECT.str.strip(' ') == 'HD170740']
    xfb_fxb_string = 'xfb'
    edps_object_dir = paths.edr5_dir / 'EDPS/UVES/object'
    output_dir = paths.edr5_dir / f'extracted_added_{xfb_fxb_string}'
    # output_dir_online = paths.extracted_added_online
    # output_dir_online = Path('/home/alex/diss_dibs/edibles_reduction/time_dep_flat')
    output_dir_online = Path('/home/alex/diss_dibs/edibles_reduction/super_bias')

    
    for i, row in obs_list.iterrows():
        print('Row', row)
        spec_list = []
        file_set = set()
        for sub_dir in edps_object_dir.iterdir():
            science_files = list(sub_dir.glob('*resampled_science_*'))
            if len(science_files) == 0:
                continue
            with fits.open(science_files[0]) as f:
                hdr = f[0].header
            if not(hdr['OBJECT'] == row['OBJECT'] and hdr['ESO TPL START'] == row['TPL START']):
                print(hdr['ESO TPL START'])
                continue

            print('Match. object', hdr['OBJECT'], 'time', hdr['ESO TPL START'])

            os.chdir(sub_dir)

            all_wave_maps = list(sub_dir.glob('*wave_map*'))
            wave_maps = [item for item in all_wave_maps if not item.name.endswith('_bac.fits')]

            if len(wave_maps) == 0:
                for wm_file in all_wave_maps:
                    if wm_file.name.endswith('_bac.fits'):
                        os.system(f'cp {wm_file} {str(wm_file).replace("_bac.fits", ".fits")}')

            wave_maps = list(sub_dir.glob('*wave_map*'))
            wave_maps = [item for item in wave_maps if not item.name.endswith('_bac.fits')]
            # print(wave_maps)

            new_wave_maps = []
            for wm_file in wave_maps:
                new_wm_file = Path(str(wm_file).replace('.fits', '_bac.fits'))
                new_wave_maps.append(new_wm_file)
                os.system(f'cp {wm_file} {new_wm_file}')

            fxb_file = sub_dir / parse_fxb_name(new_wave_maps[0], xfb_fxb_string=xfb_fxb_string)

            # Modify inpuf.sof file
            sof_file = sub_dir / 'input.sof'
            modify_sof(sof_file, wm_file, fxb_file)
    
            if xfb_fxb_string == 'xfb':
                os.system(f'/usr/bin/nice {paths.esorex_path} '
                        '--suppress-prefix=true '
                        f'--recipe-dir={paths.recipe_dir} '
                        f'--output-dir={sub_dir} '
                        f'uves_obs_scired --debug=true --reduce.tiltcorr=true --reduce.ffmethod="pixel" '
                        f'--reduce.merge_delt1=14 --reduce.merge_delt2=4 '
                        f'{sub_dir / "input_edibles.sof"}')

            elif xfb_fxb_string == 'fxb':
                os.system(f'/usr/bin/nice {paths.esorex_path} '
                        '--suppress-prefix=true '
                        f'--recipe-dir={paths.recipe_dir} '
                        f'--output-dir={sub_dir} '
                        f'uves_obs_scired --debug=true --reduce.tiltcorr=true '
                        f'{sub_dir / "input_edibles.sof"}')
            else:
                raise ValueError('Wrong xfb string!')

            # Extract reductions which were made with super flats
            for new_wm_file in new_wave_maps:
                fxb_file = sub_dir / parse_fxb_name(new_wm_file, xfb_fxb_string=xfb_fxb_string)
                fxb_err_file = sub_dir / ('err' + parse_fxb_name(new_wm_file, xfb_fxb_string=xfb_fxb_string))

                # Read wavelength map
                print(new_wm_file)
                wave_map = fits.open(new_wm_file)[0].data

                wave_cols = wave_from_map(wave_map)
                # print('wave map', wave_map)

                try:
                    # Open XFB file
                    with fits.open(fxb_file) as f:
                        fxb_hdr = f[0].header
                        fxb = f[0].data
                except FileNotFoundError:
                    continue
                # Open XFB error file
                with fits.open(fxb_err_file) as f:
                    errfxb = f[0].data

                star_name = fxb_hdr['ESO OBS TARG NAME']
                obs_time = fxb_hdr['ESO OBS START']
                if 'blue' in fxb_file.name:
                    wave_setting = fxb_hdr['ESO INS GRAT1 WLEN']
                else:
                    wave_setting = fxb_hdr['ESO INS GRAT2 WLEN']

                for i, (w, f, err) in enumerate(zip(wave_cols, fxb, errfxb)):
                    order = i + 1
                    # Try to correct pixel shift
                    w = w[1:]
                    f = f[:-1]
                    err = err[:-1]
                    name_end = fxb_file.name.replace(f"{xfb_fxb_string}_", "").replace(".fits", "_O") + f"{order}.fits"
                    file_name = f'{star_name}_{obs_time}_{wave_setting:.0f}nm_{name_end}'
                    spec = np.array([w, f, err])

                    spec_list.append([file_name, spec, fxb_hdr])
                    file_set.add(file_name)

        # Add spectra with same star name, setting, observation time and order
        for file_name in file_set:
            print(file_name)
            flux_cols = []
            err_cols = []
            for iter_name, spec, fxb_hdr in spec_list:
                if iter_name == file_name:
                    add_wave = spec[0]
                    my_hdr = fxb_hdr
                    flux_cols.append(spec[1])
                    err_cols.append(spec[2] ** 2)
                    # plt.plot(spec[0], spec[1] / np.mean(spec[1]))

            add_flux = np.zeros(flux_cols[0].shape)
            add_error = np.zeros(err_cols[0].shape)
            for err_col, my_flux in zip(err_cols, flux_cols):
                add_flux += my_flux
                add_error += err_col

            add_error = np.sqrt(add_error)

            # plt.errorbar(add_wave, add_flux, yerr=add_error)
            # plt.plot(add_wave, add_flux / np.mean(add_flux))
            # plt.show()

            # Save file
            # Write data to file
            columns = [fits.Column(name='WAVE', array=add_wave, format='D'),
                    fits.Column(name='FLUX', array=add_flux, format='D'),
                    fits.Column(name='ERROR', array=add_error, format='D')]

            wl_hdu = fits.BinTableHDU.from_columns(columns)

            primary_hdu = fits.PrimaryHDU(header=my_hdr)

            hdul = fits.HDUList(hdus=[primary_hdu, wl_hdu])

            output_dir.mkdir(parents=True, exist_ok=True)
            hdul.writeto(output_dir / file_name, overwrite=True)

            if output_dir_online is not None:
                output_dir_online.mkdir(parents=True, exist_ok=True)
                # Make file name which is valid for windows
                file_name_online = file_name  # .replace(':', '_')
                hdul.writeto(output_dir_online / file_name_online, overwrite=True)


if __name__ == '__main__':
    main()
