import numpy as np
from astropy.io import fits
import matplotlib.pyplot as plt
from pathlib import Path
from pprint import pprint
import psutil
from edibles_dr5.paths import edr5_dir
from astropy.time import Time
import sys
import gc
from importlib.resources import files
import pandas as pd


breakpoint_file = files('edibles_dr5') / 'supporting_data/breakpoints_3.csv'
breakpoints = pd.read_csv(breakpoint_file, index_col=0).loc[:,'MJD'].values


def save_fits_image(file, header, data):
    primary_hdu = fits.PrimaryHDU(data=data, header=header)
    hdul = fits.HDUList(hdus=[primary_hdu])

    hdul.writeto(file, overwrite=True)

def shrink(data):
    return data.reshape(int(data.shape[0]/2), 2, int(data.shape[1]/2), 2).sum(axis=1).sum(axis=2)

def main():
    process = psutil.Process()
    setting_list = [
        [860.0, 'redu'], [860.0, 'redl'], [346.0, 'blue'], [437.0, 'blue'], 
        [564.0, 'redl'], [564.0, 'redu'],
                    ]
    
    for t1, t2 in zip(breakpoints[:-1], breakpoints[1:]):
        print(t1, t2)
        t1_human = Time(t1, format='mjd').iso.split(' ')[0]
        t2_human = Time(t2, format='mjd').iso.split(' ')[0]
        print(t1_human)

        for wave_setting, setting in setting_list:
            print('Setting:', setting, wave_setting)
            flat_name = f'masterflat_{setting}.fits'
            flat_name = f'LAMP,FLAT_MASTER_FLAT_{setting.upper()}.fits'
            super_flat_dir = edr5_dir / 'superflats'
            # file_dir = edr5_dir / 'EDPS/UVES/flat'
            file_dir = edr5_dir / 'masterflats'

            file_list_start = list(file_dir.rglob(f'*{flat_name}'))
            # print('File list', file_list)
            flat_list = []
            file_list = []

            for file in file_list_start:
                with fits.open(file) as f:
                    hdr = f[0].header
                    data = f[0].data
                    mjd_obs = hdr['MJD-OBS']

                    try:
                        this_wave_setting = hdr['ESO INS GRAT1 WLEN']
                    except KeyError:
                        this_wave_setting = hdr['ESO INS GRAT2 WLEN']
                    if this_wave_setting == wave_setting and t1 < mjd_obs < t2:
                        flat_list.append(data)
                        file_list.append(file)
                        print(len(flat_list), 'master flats -', 'Memory:', process.memory_info().rss / 1e9, 'GB')  # in bytes

            flat_list = np.array(flat_list)
            super_flat = np.mean(flat_list, axis=0)
            print(super_flat.shape)
            print("Length flat list: ", len(flat_list))
            flat_list_len = len(flat_list)
            del flat_list

            norm_flat_list = []
            for file in file_list:
                with fits.open(file) as f:
                    data = f[0].data / np.mean(f[0].data)
                    data = shrink(data)
                    norm_flat_list.append(data)
                    print(len(norm_flat_list), 'master flats -', 'Memory:', process.memory_info().rss / 1e9, 'GB')  # in bytes
                    gc.collect()

            norm_flat_list = np.array(norm_flat_list)
            std = np.std(norm_flat_list, axis=0)
            del norm_flat_list

            f, [ax1, ax2] = plt.subplots(nrows=2, figsize=(15, 12))
            im1 = ax1.imshow(super_flat)
            plt.colorbar(im1, ax=ax1)
            im2 = ax2.imshow(std)
            plt.colorbar(im2, ax=ax2)
            ax1.set_title('superflat')
            ax2.set_title('std superflat')
            plt.figtext(0.01, 0.01, f"Length flat list: {flat_list_len}")
            plt.savefig(super_flat_dir / 'img' / f'superflat_{wave_setting:.0f}nm_{setting}_{t1_human}_{t2_human}.png')
            plt.close()

            save_fits_image(super_flat_dir / 'data' / f'superflat_{wave_setting:.0f}nm_{setting}_{t1_human}_{t2_human}.fits', hdr, super_flat)

            # master background
            # bkg_file_list = [str(item).replace('masterflat_', 'masterflat_bkg_') for item in file_list]
            bkg_file_list = [str(item).replace('_MASTER_', '_BKG_') for item in file_list]
            bkg_list = []

            for file in bkg_file_list:
                with fits.open(file) as f:
                    hdr = f[0].header
                    data = f[0].data
                    bkg_list.append(data)
                    print(len(bkg_list), 'master backgrounds -', 'Memory:', process.memory_info().rss / 1e9, 'GB')  # in bytes

            super_flat_bkg = np.mean(bkg_list, axis=0)
            del bkg_list

            norm_bkg_list = []
            for file in bkg_file_list:
                with fits.open(file) as f:
                    hdr = f[0].header
                    data = f[0].data / np.mean(f[0].data)
                    data = shrink(data)

                    norm_bkg_list.append(data)
                    print(len(norm_bkg_list), 'master backgrounds -', 'Memory:', process.memory_info().rss / 1e9, 'GB')  # in bytes

            norm_bkg_list = np.array(norm_bkg_list)
            std = np.std(norm_bkg_list, axis=0)
            del norm_bkg_list

            f, [ax1, ax2] = plt.subplots(nrows=2, figsize=(15, 12))
            im1 = ax1.imshow(super_flat_bkg)
            plt.colorbar(im1, ax=ax1)
            im2 = ax2.imshow(std)
            plt.colorbar(im2, ax=ax2)
            ax1.set_title('superflat BKG')
            ax2.set_title('std superflat BKG')
            plt.savefig(super_flat_dir / 'img' / f'superflat_bkg_{wave_setting:.0f}nm_{setting}_{t1_human}_{t2_human}.png')
            plt.close()

            save_fits_image(super_flat_dir / 'data' / f'superflat_bkg_{wave_setting:.0f}nm_{setting}_{t1_human}_{t2_human}.fits', hdr, super_flat_bkg)


if __name__ == '__main__':
    main()
