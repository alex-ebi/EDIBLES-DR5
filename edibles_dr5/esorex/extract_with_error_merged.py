from astropy.io import fits
import numpy as np
from edibles_dr5.edr5_functions import get_wave_path, wave_from_dispersion
from edibles_dr5 import paths
import os
from importlib.resources import files
from pathlib import Path
import pandas as pd


def main():
    obs_list_path = files('edibles_dr5') / 'supporting_data/obs_names.csv'
    obs_list = pd.read_csv(obs_list_path, index_col=0)
    obs_list = obs_list.loc[obs_list.OBJECT.str.strip(' ') == 'HD170740']
    edps_object_dir = paths.edr5_dir / 'EDPS/UVES/object'
    output_dir = paths.edr5_dir / 'extracted_merged'
    output_dir_online = Path('/home/alex/diss_dibs/edibles_reduction/extracted_merged')

    spec_list = []
    file_set = set()

    for _, row in obs_list.iterrows():  # Iterate through all OB's
        # List all reduced merged spectra
        all_reduced_specs = list(edps_object_dir.rglob('red_science_*'))
        for red_file in all_reduced_specs:
            with fits.open(red_file) as f:
                hdr = f[0].header
                data = f[0].data
            # If the file does not match the current OB, skip
            if not(hdr['OBJECT'] == row['OBJECT'] and hdr['ESO TPL START'] == row['TPL START']):
                continue

            print('Match. object', hdr['OBJECT'], 'time', hdr['ESO TPL START'])


            error_file = str(red_file).replace('red_science', 'error_red_science')
            with fits.open(error_file) as f:
                err_data = f[0].data

            # star_name = hdr['ESO OBS TARG NAME']
            star_name = hdr['OBJECT']
            obs_time = hdr['ESO TPL START']

            error = err_data
            flux = data
            wave = wave_from_dispersion(flux, hdr['CRVAL1'], hdr['CDELT1'], hdr['CRPIX1'])
            spec = np.array([wave, flux, error])
            ending = red_file.name.replace('red_science_', '')
            wave_setting, _ = get_wave_path(hdr)
            file_name = f'{star_name}_{obs_time}_{wave_setting:.0f}nm_{ending}'

            spec_list.append([file_name, spec, hdr])
            file_set.add(file_name)

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

            # output_dir.mkdir(parents=True, exist_ok=True)
            # hdul.writeto(output_dir / file_name, overwrite=True)

            output_dir_online.mkdir(parents=True, exist_ok=True)
            hdul.writeto(output_dir_online / file_name, overwrite=True)


if __name__ == '__main__':
    main()
