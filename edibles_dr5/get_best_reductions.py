"""
Choosing the best reductions based on the FWHM relative to the slit width.
"""

from astropy.io import fits
from edibles_dr5 import paths
from importlib.resources import files
import pandas as pd
import os
from pathlib import Path


opt_spec_dir = Path('/home/alex/diss_dibs/edibles_reduction/orders')
avg_spec_dir = Path('/home/alex/diss_dibs/edibles_reduction/orders_average_sky_sub')
best_spec_dir = Path('/home/alex/spectra/EDR5/orders')

obs_list = pd.read_csv(files('edibles_dr5') / 'supporting_data/obs_names.csv')
reduction_grade_list = pd.read_csv(files('edibles_dr5') / 'supporting_data/best_reductions.csv', index_col=0, na_values=['na'])


def main():
    best_spec_dir.mkdir(exist_ok=True)
    for i, row in obs_list.iterrows():
        print(i)
        star_name = row.OBJECT.replace(' ', '')
        obs_date = row['TPL START']

        spec_list = list(opt_spec_dir.rglob('*.fits'))
        spec_list = [item for item in spec_list if star_name in item.name]

        if isinstance(obs_date, str):
            spec_list = [item for item in spec_list if obs_date in item.name]

        if len(spec_list) == 0:
            continue

        grade_row = reduction_grade_list.loc[reduction_grade_list['DATE-OBS'] == obs_date]
        
        for spec_path in spec_list:
            grade_row = reduction_grade_list.loc[reduction_grade_list['spec_path'] == spec_path.name].dropna()
            if grade_row.size == 0:
                continue
            grade_row = reduction_grade_list.loc[reduction_grade_list['spec_path'] == spec_path.name].iloc[0]
            if grade_row.method == 'average':
                spec_list = [avg_spec_dir / item.name for item in spec_list]
            elif grade_row.method == 'na':
                continue
            os.system(f'cp {spec_path} {best_spec_dir / spec_path.name}')
  



 


if __name__ == '__main__':
    main()

