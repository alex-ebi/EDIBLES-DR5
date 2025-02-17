"""
Choosing the best reductions based on the FWHM relative to the slit width.
"""

from astropy.io import fits
import paths
from importlib.resources import files
import pandas as pd
import os
from pathlib import Path


opt_spec_dir = Path('/home/alex/diss_dibs/edibles_reduction/orders')
avg_spec_dir = Path('/home/alex/diss_dibs/edibles_reduction/orders_average')
best_spec_dir = Path('/home/alex/diss_dibs/edibles_reduction/orders_best')

obs_list = pd.read_csv(files('edibles_dr5') / 'supporting_data/obs_names.csv')

settings = ['blue', 'red']

fwhm_threshold = 0.25

def main():
    best_spec_dir.mkdir(exist_ok=True)
    for i, row in obs_list.iterrows():
        print(i)
        star_name = row.OBJECT.replace(' ', '')
        obs_date = row['TPL START']

        for setting in settings:
            spec_list = list(opt_spec_dir.rglob('*.fits'))
            spec_list = [item for item in spec_list if star_name in item.name]
            spec_list = [item for item in spec_list if setting in item.name]

            if isinstance(obs_date, str):
                spec_list = [item for item in spec_list if obs_date in item.name]

            if len(spec_list) == 0:
                continue

            fwhm_list = []

            for spec_path in spec_list:
                hdul = fits.open(spec_path)

                hdr = hdul[0].header

                fwhm_list.append(hdr['REL OBJ FWHM'])
            
            max_fwhm = max(fwhm_list)

            if max_fwhm > fwhm_threshold:
                spec_list = [avg_spec_dir / item.name for item in spec_list]
            
            for spec_path in spec_list:
                os.system(f'cp {spec_path} {best_spec_dir / spec_path.name}')
  



 


if __name__ == '__main__':
    main()

