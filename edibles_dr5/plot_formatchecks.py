"""
Plotting the formatcheck and flat frames from the raw calib data.
"""
from edibles_dr5 import paths
from astropy.io import fits
from pprint import pprint
import matplotlib.pyplot as plt
from pathlib import Path
from edibles_dr5.edr5_functions import get_wave_path

calib_dir = paths.edr5_dir / 'calib_raw'
plot_dir_flat = Path('/home/alex/diss_dibs/edibles_reduction/calib_check/flat')
plot_dir_fmt = Path('/home/alex/diss_dibs/edibles_reduction/calib_check/fmtchk')

for file in calib_dir.glob('*.fits'):
    with fits.open(file) as f:
        hdr = f[0].header
        if len(f) == 1:
            data = [f[0].data]
        else:
            data = [f[1].data, f[2].data]
    
    for i, img in enumerate(data):
        if hdr['OBJECT'] == 'LAMP,FMTCHK':
            plot_dir = plot_dir_fmt
        elif hdr['OBJECT'] == 'LAMP,FLAT':
            plot_dir = plot_dir_flat
        else:
            continue
        im = plt.imshow(img.T)
        plt.colorbar(im)

        wave, setting = get_wave_path(hdr)
        print(f'{wave}_{setting}')

        if i == 0:
            lu='l'
        elif i == 1:
            lu='u'
        (plot_dir / f'{wave:.0f}_{setting}{lu}').mkdir(exist_ok=True)
        plt.savefig(plot_dir / f'{wave:.0f}_{setting}{lu}' / f'{hdr['DATE'][:10]}.png')
        # plt.show()
        plt.close()


        