from edibles_dr5 import paths
from astropy.io import fits
from pathlib import Path
from edibles_dr5 import edr5_functions
import pandas as pd
from importlib.resources import files

raw_path = Path('/run/media/Alex/PortableSSD/DR5_workdir')

raw_dirs = [raw_path / 'calib_raw', raw_path / 'EDIBLES_raw_all']

orderdef_df = pd.DataFrame()

for raw_dir in raw_dirs:
    for file in raw_dir.glob('*.fits'):
        with fits.open(file) as hdul:
            hdr = hdul[0].header
            if hdr.get('OBJECT') == 'LAMP,ORDERDEF':
                wave, _ = edr5_functions.get_wave_path(hdr)
                
                rel_path = file.relative_to(raw_path)
                out_series = pd.Series({'file_name': file.name, 'wave_setting': wave, 'MJD-OBS': hdr['MJD-OBS'], 'path': rel_path})

                orderdef_df = pd.concat((orderdef_df, out_series), ignore_index=True, axis=1)

orderdef_df = orderdef_df.T
orderdef_df = orderdef_df.sort_values(by=['wave_setting', 'MJD-OBS'], ignore_index=True)
orderdef_df.to_csv(files('edibles_dr5') / f'supporting_data/orderdef_list.csv')


    
