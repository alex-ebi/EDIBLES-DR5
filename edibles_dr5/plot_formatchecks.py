"""
Plotting the formatcheck and flat frames from the raw calib data.
"""
from edibles_dr5 import paths
from astropy.io import fits
from pprint import pprint
import matplotlib.pyplot as plt
from pathlib import Path

calib_dir = paths.edr5_dir / 'flat_346'
plot_dir_flat = Path('/home/alex/diss_dibs/edibles_reduction/calib_check/flat')
plot_dir_fmt = Path('/home/alex/diss_dibs/edibles_reduction/calib_check/fmtchk')

for file in calib_dir.glob('*.fits'):
    with fits.open(file) as f:
        hdr = f[0].header
        if len(f) == 1:
            data = [f[0].data]
        else:
            data = [f[1].data[0], f[2].data[0]]

    for i, img in enumerate(data):
        im = plt.imshow(img.T)
        plt.colorbar(im)
        if hdr['OBJECT'] == 'LAMP,FMTCHK':
            plot_dir = plot_dir_fmt
        elif hdr['OBJECT'] == 'LAMP,FLAT':
            plot_dir = plot_dir_flat
        plt.savefig(plot_dir / f'{hdr['DATE']}_{i}.png')
        # plt.show()
        plt.close()


        