from pathlib import Path
import pandas as pd
from astropy.io import fits
import matplotlib.pyplot as plt
import numpy as np
from pprint import pprint
from edibles_dr5.edr5_functions import get_wave_path

edps_wavecal_dir = Path('/run/media/Alex/CrucialX10/EDPS_data/UVES/arc')
sub_dirs = edps_wavecal_dir.glob('*/')


df = pd.DataFrame()
setting_df = pd.DataFrame()

for sub_dir in sub_dirs:
    files = sub_dir.glob('*linetable_*')
    for file in files:
        print(file)
        with fits.open(file) as hdul:
            hdr = hdul[0].header
            # pprint(hdr)

            mean_res = hdr['HIERARCH ESO QC RESOLAVG']
            std_res = hdr['HIERARCH ESO QC RESOLRMS']

            wave, path = get_wave_path(hdr)

            if 'redl' in hdr['PIPEFILE']:
                path = 'redl'
            elif 'redu' in hdr['PIPEFILE']:
                path = 'redu'

            print(wave, path)

            if path == 'redl':
                wave += 100

            s = pd.Series({'wave': wave, 'setting': path, 'mean_res': mean_res, 'std_res': std_res})
            df = pd.concat((df, s), axis=1)

            try:
                slit_width = hdr['ESO INS SLIT2 WID']
            except KeyError:
                slit_width = hdr['ESO INS SLIT3 WID']

            data = hdul[4].data
            resol = data['Resol']
            orders = data['Order']
            wave = data['WaveC']


            s = pd.Series({'slit_width': slit_width, 'order': np.nan, 'resol': np.nanmean(resol), 'resol_std': np.nanstd(resol), 'wave': np.nanmin(wave)})
            setting_df = pd.concat((setting_df, s), axis=1)

            for order in np.unique(orders):
                order_mask = orders == order
                resol_order = resol[order_mask]
                wave_order = wave[order_mask]

                s = pd.Series({'slit_width': slit_width, 'order': order, 'resol': np.nanmean(resol_order), 'resol_std': np.nanstd(resol_order), 'wave': np.nanmean(wave_order)})

                setting_df = pd.concat((setting_df, s), axis=1)

                # plt.scatter(wave_order, resol_order)

                # plt.title(slit_width)
                # plt.show()
            
            print(setting_df)
plt.errorbar(setting_df.loc['wave'], setting_df.loc['resol'], yerr=setting_df.loc['resol_std'], fmt='o')
plt.show()

plt.errorbar(df.loc['wave'], df.loc['mean_res'], yerr=df.loc['std_res'], fmt='o')
plt.show()

