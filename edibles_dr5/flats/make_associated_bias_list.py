"""
Downloading associated bias frames of flat fields.
"""
from pathlib import Path
from astropy.io import fits
from edibles_DR5.workflow import edr5_functions
import urllib
import os
import pandas as pd


def main(flat_dir):
    df = pd.DataFrame()
    for file in flat_dir.glob('*.fits'):
        with fits.open(file) as f:
            hdr = f[0].header

        if hdr['OBJECT'] == 'BIAS':
            continue

        # Get wavelength and path (red or blue) of flat
        wave, path = edr5_functions.get_wave_path(hdr)

        # Removing flats which have the wrong wavelength setting
        if wave not in [860.0]:
            print("NOT WHAT WE WANT!!!!!!!!!!!!!!!!!!!")
            print(wave)
            # os.system(f'rm {file}')
            continue

        # Removing files which have the wrong filter
        filter_name = edr5_functions.get_filter_name(hdr)
        if wave in [346.0, 437.0]:
            if filter_name != 'HER_5':
                print("NOT WHAT WE WANT!!!!!!!!!!!!!!!!!!!")
                os.system(f'rm {file}')
                continue
        elif wave == 564.0:
            if filter_name != 'SHP700':
                print("NOT WHAT WE WANT!!!!!!!!!!!!!!!!!!!")
                os.system(f'rm {file}')
                continue
        elif wave == 860.0:
            if filter_name != 'OG590':
                print("NOT WHAT WE WANT!!!!!!!!!!!!!!!!!!!")
                os.system(f'rm {file}')
                continue

        night_log_file = Path(str(file).replace('.fits', '.NL.txt'))

        if night_log_file.is_file():
            with open(night_log_file, 'r') as f:
                lines = f.readlines()
            binning = True
            for line in lines:
                if line.startswith('CCD: ') and '/1x1/' in line:
                    binning = False
                elif line.startswith('CCD: ') and '/1x1/' not in line:
                    binning = True
                if f'{path.upper()}_BIAS' in line and not binning:  # Only downloading bias if it is taken for 1x1 binning.
                    bias_archive_name = line.split('\t')[1]
                    print(bias_archive_name)
                    s = pd.Series([file.name, bias_archive_name])
                    df = pd.concat((df, s), axis=1, ignore_index=True)
    df = df.T
    print(df)
    df.to_excel('/home/alex/EDR5/flat_and_bias_860nm.xlsx')


if __name__ == '__main__':
    main(Path('/home/alex/EDR5/flat_2024_11_25'))
