import numpy as np
from astropy.io import fits
import matplotlib.pyplot as plt
import astro_scripts_uibk as asu
from pathlib import Path
from pprint import pprint
from edibles_DR5.workflow.edr5_functions import edr5_dir


def save_fits_image(file, header, data):
    primary_hdu = fits.PrimaryHDU(data=data, header=header)
    hdul = fits.HDUList(hdus=[primary_hdu])

    hdul.writeto(file, overwrite=True)


def main():
    setting_list = ['redl', 'redu', 'blue']
    super_bias_dir = edr5_dir / 'superbias'
    file_dir = edr5_dir / 'EDPS/UVES/bias'

    for setting in setting_list:
        print('Setting:', setting)
        bias_name = f'masterbias_{setting}.fits'

        file_list = list(file_dir.rglob(f'*{bias_name}'))
        bias_list = []
        for file in file_list:
            with fits.open(file) as f:
                hdr = f[0].header
                data = f[0].data
                if 'red' in setting and hdr['ESO DET OUT1 NX'] == 2048:
                    bias_list.append(data)
                elif 'blue' in setting and hdr['ESO DET OUT1 NX'] == 2048:
                    bias_list.append(data)

        bias_list = np.array(bias_list)

        std = np.std(bias_list, axis=0)
        super_bias = np.mean(bias_list, axis=0)

        plt.imshow(super_bias, norm='log')
        print(len(bias_list))
        plt.title(f'Super bias {setting}')
        plt.show()

        plt.imshow(std, norm='log')
        print(len(bias_list))
        plt.title(f'Super bias standard deviation {setting}')
        plt.show()

        save_fits_image(super_bias_dir / f'superbias_{setting}.fits', hdr, super_bias)


if __name__ == '__main__':
    main()
