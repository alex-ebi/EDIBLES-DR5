"""
Finding the best matching flat frames from a collection.
"""
import numpy as np
from astropy.io import fits
from pathlib import Path
import matplotlib.pyplot as plt
from astropy.io import fits
from pprint import pprint

# load master flats
# m_blue =

# Load flat collection
# collection_dir = Path('/home/alex/EDR5/flat')
collection_dir = Path('/home/alex/edps_test/HD170740')

my_wave_setting = 860.0

for file in collection_dir.glob('*.fits'):
    with fits.open(file) as f:
        hdr = f[0].header
        if len(f) == 1:
            data = f[0].data
        elif len(f) == 3:
            data = np.concatenate((f[1].data, f[2].data), axis=1)
        if hdr["ESO DPR TYPE"] == 'LAMP,FLAT':
            try:
                wave_setting = hdr['ESO INS GRAT1 WLEN']
            except KeyError:
                wave_setting = hdr['ESO INS GRAT2 WLEN']

            if 1:  # wave_setting == my_wave_setting:
                plt.figure(figsize=(15, 12))
                plt.imshow(data)
                plt.figtext(0.01, 0.01,
                            f'{file}\n{hdr["OBJECT"]}\n{wave_setting:.0f}_{hdr["ESO INS PATH"]}, '
                            f'EXPTIME: {hdr["EXPTIME"]}')
                plt.show()
                print(file, f'{wave_setting:.0f}_{hdr["ESO INS PATH"]}')
            # pprint(hdr)
