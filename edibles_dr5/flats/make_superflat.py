import numpy as np
from astropy.io import fits
import matplotlib.pyplot as plt
from pathlib import Path
from pprint import pprint
import psutil
from edibles_dr5.paths import edr5_dir


def save_fits_image(file, header, data):
    primary_hdu = fits.PrimaryHDU(data=data, header=header)
    hdul = fits.HDUList(hdus=[primary_hdu])

    hdul.writeto(file, overwrite=True)


def main():
    process = psutil.Process()
    setting_list = [
        [860.0, 'redu'], [860.0, 'redl'], [346.0, 'blue'], [437.0, 'blue'], 
        [564.0, 'redl'], [564.0, 'redu'],
                    ]

    for wave_setting, setting in setting_list:
        print('Setting:', setting, wave_setting)
        flat_name = f'masterflat_{setting}.fits'
        super_flat_dir = edr5_dir / 'superflats'
        file_dir = edr5_dir / 'EDPS/UVES/flat'

        file_list_start = list(file_dir.rglob(f'*{flat_name}'))
        # print('File list', file_list)
        flat_list = []
        file_list = []

        for file in file_list_start:
            with fits.open(file) as f:
                hdr = f[0].header
                data = f[0].data
                try:
                    this_wave_setting = hdr['ESO INS GRAT1 WLEN']
                except KeyError:
                    this_wave_setting = hdr['ESO INS GRAT2 WLEN']
                if this_wave_setting == wave_setting:
                    flat_list.append(data)
                    file_list.append(file)
                    print(len(flat_list), 'master flats -', 'Memory:', process.memory_info().rss / 1e9, 'GB')  # in bytes

        flat_list = np.array(flat_list)
        super_flat = np.mean(flat_list, axis=0)
        print(super_flat.shape)
        print("Length flat list: ", len(flat_list))
        del flat_list

        norm_flat_list = []
        for file in file_list:
            with fits.open(file) as f:
                hdr = f[0].header
                data = f[0].data
            norm_flat_list.append(data / np.mean(data))
            print(len(norm_flat_list), 'master flats -', 'Memory:', process.memory_info().rss / 1e9, 'GB')  # in bytes

        norm_flat_list = np.array(norm_flat_list)
        std = np.std(norm_flat_list, axis=0)
        del norm_flat_list

        f, [ax1, ax2] = plt.subplots(nrows=2, figsize=(15, 12))
        ax1.imshow(super_flat)
        ax2.imshow(std)
        ax1.set_title('superflat')
        ax2.set_title('std superflat')
        plt.show()

        # save_fits_image(super_flat_dir / f'superflat_{wave_setting:.0f}nm_{setting}.fits', hdr, super_flat)

        # master background
        bkg_file_list = [str(item).replace('masterflat_', 'masterflat_bkg_') for item in file_list]
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
                data = f[0].data
                norm_bkg_list.append(data / np.mean(data))
                print(len(norm_bkg_list), 'master backgrounds -', 'Memory:', process.memory_info().rss / 1e9, 'GB')  # in bytes

        norm_bkg_list = np.array(norm_bkg_list)
        std = np.std(norm_bkg_list, axis=0)
        del norm_bkg_list

        f, [ax1, ax2] = plt.subplots(nrows=2, figsize=(15, 12))
        ax1.imshow(super_flat_bkg)
        ax2.imshow(std)
        ax1.set_title('superflat BKG')
        ax2.set_title('std superflat BKG')
        plt.show()

        # save_fits_image(super_flat_dir / f'superflat_bkg_{wave_setting:.0f}nm_{setting}.fits', hdr, super_flat_bkg)


if __name__ == '__main__':
    main()
