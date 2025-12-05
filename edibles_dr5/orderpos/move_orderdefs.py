from edibles_dr5 import paths
from astropy.io import fits
import os

edr5_raw_dir = paths.edr5_dir / 'EDIBLES_raw'
backup_dir = paths.edr5_dir / 'EDIBLES_raw_old_orderdefs'

backup_dir.mkdir(exist_ok=True)

for file in edr5_raw_dir.glob('*.fits'):
    with fits.open(file) as hdul:
        obj_type = hdul[0].header.get('OBJECT')
    
    if obj_type == 'LAMP,ORDERDEF':
        os.system(f'mv {file} {backup_dir / file.name}')
