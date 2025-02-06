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
from edibles_dr5 import paths, edr5_functions
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


def parse_xfb_name(wave_map_file):
    if wave_map_file.name == 'wave_map_blue.fits':
        xfb_file = 'xfb_blue.fits'
    elif wave_map_file.name == 'wave_map_redl.fits':
        xfb_file = 'xfb_redl.fits'
    elif wave_map_file.name == 'wave_map_redu.fits':
        xfb_file = 'xfb_redu.fits'
    else:
        print(wave_map_file.name)
        raise FileNotFoundError('No correct wavemap file!')
    return xfb_file


def modify_sof(sof_file: Path, wm_file: Path, xfb_file: Path, mjd_obs, time_dependent_flats=True):
    """Opens SOF file and saves modified copy with superflats for calibration.


    Parameters
    ----------
    sof_file : Path
        _description_
    wm_file : Path
        _description_
    xfb_file : Path
        _description_
    time_dependent_flats : bool, optional
        _description_, by default True

    Raises
    ------
    ValueError
        _description_
    ValueError
        _description_
    """
    
    super_bias_blue = paths.edr5_dir / 'superbias/superbias_blue.fits'
    super_bias_redl = paths.edr5_dir / 'superbias/superbias_redl.fits'
    super_bias_redu = paths.edr5_dir / 'superbias/superbias_redu.fits'

    print('Making modified copy with superflats of', wm_file)

    with fits.open(wm_file) as f:
        hdr = f[0].header

    try:
        wave_setting = hdr['ESO INS GRAT1 WLEN']
    except KeyError:
        wave_setting = hdr['ESO INS GRAT2 WLEN']

    if 'blue' in xfb_file.name:
        setting = 'blue'
    elif 'redl' in xfb_file.name:
        setting = 'red'
    elif 'redu' in xfb_file.name:
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
        superflat_name = f'{wave_setting:.0f}nm_{setting}_2016-04-22_2018-12-03'
        superflat_name_l = f'{wave_setting:.0f}nm_{setting}l_2016-04-22_2018-12-03'
        superflat_name_u = f'{wave_setting:.0f}nm_{setting}u_2016-04-22_2018-12-03'
        superflat_dir = paths.edr5_dir / 'superflats' / 'data'
    

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
        # elif 'MASTER_BIAS_BLUE' in line:
        #     line_end = line.split(' ')[-1]
        #     lines[i] = f'{super_bias_blue} {line_end}'
        # elif 'MASTER_BIAS_REDL' in line:
        #     line_end = line.split(' ')[-1]
        #     lines[i] = f'{super_bias_redl} {line_end}'
        # elif 'MASTER_BIAS_REDU' in line:
        #     line_end = line.split(' ')[-1]
        #     lines[i] = f'{super_bias_redu} {line_end}'

    new_sof_file = str(sof_file).replace('input.sof', 'input_edibles.sof')
    with open(new_sof_file, 'w') as f:
        f.writelines(lines)

# Dictionary of Merge_delt for order merging, dependent on setting wavelength. Units are in Angstrom.
merge_delt_dict = {346: [10, 10], 437: [13, 7], 564: [19, 4], 860: [20, 1]}

def main():
    obs_list_path = files('edibles_dr5') / 'supporting_data/obs_names.csv'
    obs_list = pd.read_csv(obs_list_path, index_col=0)
    obs_list = obs_list.iloc[6:7]
    edps_object_dir = paths.edr5_dir / 'EDPS/UVES/object'
    output_dir = paths.edr5_dir / 'extracted_added_xfb'
    output_dir_online = Path('/home/alex/diss_dibs/edibles_reduction/orders_average')
    cleanup = True
    output_dir_online.mkdir(exist_ok=True)

    # Make / update database of objects in EDPS directory with OBJECT names and TPL START
    edps_obs_df = edr5_functions.make_reduction_database(edps_object_dir)
    
    for _, row in obs_list.iterrows():  # Iterate through all OB's
        print('Row', row)
        spec_list = []  # This list will hold all order spectra from sub-integrations.
        file_set = set()
        # Select the sub directories which contain data of the current OB
        print(row)
        sub_dirs = edps_obs_df.loc[edps_obs_df['OBJECT'] == row['OBJECT'], :]
        sub_dirs = sub_dirs.loc[sub_dirs['ESO TPL START'] == row['TPL START'], 'sub_dir']
        for sub_dir in sub_dirs:
            # List all resampled science files in EDPS directory
            science_files = list(sub_dir.glob('*resampled_science_*'))

            # Skip sub-directory if there are no fully processed science files
            if len(science_files) == 0:
                continue
            with fits.open(science_files[0]) as f:
                hdr = f[0].header

            wave_setting, _ = edr5_functions.get_wave_path(hdr)

            # Chdir to sub-directory
            print('Match. object', hdr['OBJECT'], 'time', hdr['ESO TPL START'])
            os.chdir(sub_dir)

            # List all wave_maps. There can be one (blue) or two (red)
            all_wave_maps = list(sub_dir.glob('*wave_map*'))
            # Exclude backup wavemaps
            wave_maps = [item for item in all_wave_maps if not item.name.endswith('_bac.fits')]

            # If there is no wave map, make copy from the backup
            if len(wave_maps) == 0:
                for wm_file in all_wave_maps:
                    if wm_file.name.endswith('_bac.fits'):
                        os.system(f'cp {wm_file} {str(wm_file).replace("_bac.fits", ".fits")}')

            # List wave maps again
            wave_maps = list(sub_dir.glob('*wave_map*'))
            wave_maps = [item for item in wave_maps if not item.name.endswith('_bac.fits')]
            wave_maps = [item for item in wave_maps if not item.name.endswith('_2.fits')]
            wave_maps = [item for item in wave_maps if not item.name.endswith('_1.fits')]

            # Modify inpuf.sof file to use super flats (and super bias)
            fxb_file = sub_dir / parse_xfb_name(wave_maps[0])
            sof_file = sub_dir / 'input.sof'
            modify_sof(sof_file, wave_maps[0], fxb_file, row['MJD-OBS'])

            # Make backup of wave map
            for wm_file in wave_maps:
                with fits.open(wm_file) as f:
                    if f[0].header.get('MJD-OBS') is not None:
                        os.system(f'cp {wm_file} {str(wm_file).replace(".fits", "_bac.fits")}')
            
            crop_limits = merge_delt_dict[wave_setting]

            # Run esorex on input_edibles.sof
            # flatfield pixel per pixel
            os.system(f'/usr/bin/nice {paths.esorex_path} '
                    '--suppress-prefix=true '
                    f'--recipe-dir={paths.recipe_dir} '
                    f'--output-dir={sub_dir} '
                    f'uves_obs_scired --debug=true --reduce.tiltcorr=true --reduce.ffmethod="pixel" '
                    f'--reduce.merge_delt1={float(crop_limits[0]):.0f} --reduce.merge_delt2={float(crop_limits[1]):.0f} '
                    '--reduce.extract.method="average" '
                    f'{sub_dir / "input_edibles.sof"}')

            # Extract reductions which were made with super flats
            for wm_file in wave_maps:
                xfb_name = parse_xfb_name(wm_file).replace('.fits', '_2.fits')
                fxb_file = sub_dir / xfb_name
                fxb_err_file = sub_dir / ('err' + xfb_name)
                sky_file = sub_dir / xfb_name.replace('xfb_', 'xfsky_')
                flat_file = sub_dir / xfb_name.replace('xfb_', 'xmf_')

                # Read wavelength map
                print('Reading wave map', wm_file)
                with fits.open(wm_file) as f:
                    wave_map = f[0].data
                # get wavelengths from wave map
                wave_cols = wave_from_map(wave_map)

                # Open XFB file. if none is found, skip it.
                try:
                    with fits.open(fxb_file) as f:
                        xfb_hdr = f[0].header
                        xfb_data = f[0].data
                except FileNotFoundError:
                    continue

                # Open XFB error file
                with fits.open(fxb_err_file) as f:
                    errfxb = f[0].data

                # # Open Sky file
                # with fits.open(sky_file) as f:
                #     xfsky = f[0].data

                # Open extracted flat file
                with fits.open(flat_file) as f:
                    xmf = f[0].data

                if 'blue' in fxb_file.name:
                    wave_setting = xfb_hdr['ESO INS GRAT1 WLEN']
                else:
                    wave_setting = xfb_hdr['ESO INS GRAT2 WLEN']

                star_name = xfb_hdr['ESO OBS TARG NAME'].strip(' ')
                obs_time = xfb_hdr['ESO TPL START']
                
                for i, (w, f, err, xmf_col) in enumerate(zip(wave_cols, xfb_data, errfxb, xmf)):
                    order = i + 1

                    # Correct pixel shift
                    w = w[1:]
                    f = f[:-1]
                    err = err[:-1]
                    # sky_col = sky_col[:-1]
                    xmf_col = xmf_col[:-1]

                    # Making name of final order product
                    name_end = fxb_file.name.replace("xfb_", "").replace(".fits", "_O") + f"{order}.fits"
                    file_name = f'{star_name}_{obs_time}_{wave_setting:.0f}nm_{name_end}'
                    spec = np.array([w, f, err, xmf_col])

                    # Add spectrum information to list
                    spec_list.append([file_name, spec, xfb_hdr])
                    # Add file name to set of file names, so we have no duplicates
                    file_set.add(file_name)
            if cleanup:
                edr5_functions.cleanup_edps_subdir(sub_dir)

        # Add spectra with same star name, setting, observation time and order
        for file_name in file_set:
            print(file_name)
            flux_cols = []
            err_cols = []
            # sky_cols = []
            xmf_cols = []
            for iter_name, spec, xfb_hdr in spec_list:
                if iter_name == file_name:
                    add_wave = spec[0]
                    my_hdr = xfb_hdr
                    flux_cols.append(spec[1])
                    err_cols.append(spec[2] ** 2)
                    xmf_cols.append(spec[3])

            add_flux = np.zeros(flux_cols[0].shape)
            add_error = np.zeros(err_cols[0].shape)
            add_xmf = np.zeros(err_cols[0].shape)
            for err_col, my_flux, my_xmf in zip(err_cols, flux_cols, xmf_cols):
                add_flux += my_flux
                add_error += err_col
                add_xmf += my_xmf

            add_error = np.sqrt(add_error)

            # Save file
            # Write data to file
            columns = [fits.Column(name='WAVE', array=add_wave, format='D'),
                    fits.Column(name='FLUX', array=add_flux, format='D'),
                    fits.Column(name='ERROR', array=add_error, format='D'),
                    fits.Column(name='FLAT', array=add_xmf, format='D')]

            wl_hdu = fits.BinTableHDU.from_columns(columns)

            primary_hdu = fits.PrimaryHDU(header=my_hdr)

            hdul = fits.HDUList(hdus=[primary_hdu, wl_hdu])

            # output_dir.mkdir(parents=True, exist_ok=True)
            # hdul.writeto(output_dir / file_name, overwrite=True)

            if output_dir_online is not None:
                output_dir_online.mkdir(parents=True, exist_ok=True)
                # Make file name which is valid for windows
                file_name_online = file_name  # .replace(':', '_')
                hdul.writeto(output_dir_online / file_name_online, overwrite=True)


if __name__ == '__main__':
    main()
