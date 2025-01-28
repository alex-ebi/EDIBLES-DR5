import numpy as np
from astropy.io import fits
import matplotlib.pyplot as plt
from pathlib import Path
from pprint import pprint
import psutil
from edibles_dr5.paths import edr5_dir
from edibles_dr5.flats.check_breakpoints import breakpoints
from astropy.time import Time
import sys
import gc


def save_fits_image(file, header, data):
    primary_hdu = fits.PrimaryHDU(data=data, header=header)
    hdul = fits.HDUList(hdus=[primary_hdu])

    hdul.writeto(file, overwrite=True)

def shrink(data):
    return data.reshape(int(data.shape[0]/2), 2, int(data.shape[1]/2), 2).sum(axis=1).sum(axis=2)

def slice_order(data, wave_setting, setting):
    print(wave_setting, setting)

    # plt.imshow(data, aspect='auto')
    # plt.show()

    if wave_setting == 860.0 and setting == 'redu':
        b = 165/len(data[0])
        h = 90
        h_start = 700
    elif wave_setting == 860.0 and setting == 'redl':
        b = 165/len(data[0])
        h = 120
        h_start = 1470
    elif wave_setting == 564.0 and setting == 'redu':
        b = 185/len(data[0])
        h = 100
        h_start = 530

    elif wave_setting == 564.0 and setting == 'redl':
        b = 177/len(data[0])
        h = 80
        h_start = 1205

    elif wave_setting == 346.0 and setting == 'blue':
        b = 130/len(data[0])
        h = 60
        h_start = 571

    elif wave_setting == 437.0 and setting == 'blue':
        b = 125/len(data[0])
        h = 80
        h_start = 1650

    h_index = [h_start,h_start + int(b * len(data[0]) + h)]
    print(h_index)
    sub_set = data[h_index[0]:h_index[1]]
    x = np.arange(len(sub_set[0]))
    order_line = x * b

    # plt.imshow(sub_set, aspect='auto')
    # plt.plot(x, order_line)
    # plt.show()

    slanted_image = []
    for i, row in enumerate(sub_set.T):
        start_ind = int(b*i)
        slanted_image.append(row[start_ind: start_ind + h])

    slanted_image = np.array(slanted_image).T

    # plt.imshow(slanted_image, aspect='auto')
    # plt.show()

    spec = np.sum(slanted_image, axis=0)[:-2]

    # plt.plot(spec)
    # plt.show()

    return spec

def main():
    process = psutil.Process()
    setting_list = [[437.0, 'blue'], [346.0, 'blue'], [564.0, 'redu'],[564.0, 'redl'], [860.0, 'redl'], 
        [860.0, 'redu'], 
        
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

            file_list_start = sorted(list(file_dir.rglob(f'*{flat_name}')))
            print(file_list_start)
            flat_list = []
            file_list = []
            test_spec_list = []
            mjd_list = []

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
                        test_spec = slice_order(data, wave_setting, setting)
                        test_spec_list.append(test_spec)
                        mjd_list.append(mjd_obs)

            flat_list = np.array(flat_list)
            test_spec_list = np.array(test_spec_list)
            super_flat = np.mean(flat_list, axis=0)
            super_test_spec = np.mean(test_spec_list, axis=0)
            super_test_spec_2 = slice_order(super_flat, wave_setting, setting)
            super_test_spec = test_spec_list[0]


            for mjd_obs, test_spec in zip(mjd_list, test_spec_list):
                plt.figure(figsize=(25, 20))
                plt.title(mjd_obs)
                plt.plot(test_spec / np.median(test_spec), label='test')
                plt.plot(super_test_spec / np.median(super_test_spec), label='super 1')
                # plt.plot(super_test_spec_2 / np.median(super_test_spec_2), label='super 2')
                plt.legend()
                plt.show()

            for mjd_obs, test_spec in zip(mjd_list, test_spec_list):
                plt.scatter(mjd_obs, np.linalg.norm(super_test_spec / np.median(super_test_spec) - test_spec / np.median(test_spec), ord=2))
            plt.show()
            

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
            # plt.savefig(super_flat_dir / 'img' / f'superflat_{wave_setting:.0f}nm_{setting}_{t1_human}_{t2_human}.png')
            # plt.close()

            # save_fits_image(super_flat_dir / 'data' / f'superflat_{wave_setting:.0f}nm_{setting}_{t1_human}_{t2_human}.fits', hdr, super_flat)

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

            # save_fits_image(super_flat_dir / 'data' / f'superflat_bkg_{wave_setting:.0f}nm_{setting}_{t1_human}_{t2_human}.fits', hdr, super_flat_bkg)


if __name__ == '__main__':
    main()
