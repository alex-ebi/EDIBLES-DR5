from astropy.io import fits
import pandas as pd
from edibles_dr5 import edr5_functions, paths
from importlib.resources import files
import numpy as np
import os


def main(raw_dir, out_dir):
    breakpoint_file = files('edibles_dr5') / 'supporting_data/breakpoints_4.csv'
    breakpoints = pd.read_csv(breakpoint_file, index_col=0)

    flatlist_file = files('edibles_dr5') / 'supporting_data/flat_list.csv'
    flatlist = pd.read_csv(flatlist_file, index_col=0)

    for i, row in flatlist.iterrows():
        bpdates = (breakpoints.loc[row.flat_bin-1, 'DATE-OBS'], breakpoints.loc[row.flat_bin, 'DATE-OBS'])
        out_path = out_dir / f'{row.wave:.0f}nm_{bpdates[0]}_{bpdates[1]}' / row['name']
        out_path.parent.mkdir(parents=True,exist_ok=True)
        os.system(f'cp {raw_dir / row['name']} {out_path}')


if __name__ == '__main__':
    print(paths.edr5_dir / 'calib_raw')
    main(paths.edr5_dir / 'calib_raw', paths.edr5_dir / 'selected_flats')
