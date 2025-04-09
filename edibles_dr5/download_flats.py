"""
Checking how many flats are downloaded per time bin.
To keep the use of data limited, only flats with an exposure time exceeding a certain threshold are downloaded.
"""
import pandas as pd
from importlib.resources import files
import os
from edibles_dr5.paths import edr5_dir
import urllib.request

edr5_dir.mkdir(exist_ok=True)
flat_dir = edr5_dir / 'calib_raw'
flat_dir.mkdir(exist_ok=True)

download_list_dir = files('edibles_dr5') / 'supporting_data/selected_flats'

# Execute shell scripts
os.chdir(flat_dir)
list_names = download_list_dir.glob('*.csv')

for dl_list in list_names:
    df = pd.read_csv(dl_list, index_col=0)
    for i, row in df.iterrows():
        print(row)
        archive_name = row['Dataset ID']
        dp_id = archive_name
        download_url = f'http://archive.eso.org/datalink/links?ID=ivo://eso.org/ID?{dp_id}&eso_download=file'
        print(f'Retrieving file {archive_name}.fits')
        urllib.request.urlretrieve(download_url, filename=flat_dir / (archive_name + '.fits.Z'))
        print(f'File {archive_name}.fits downloaded')
        os.system(f'uncompress {flat_dir / (archive_name + ".fits.Z")}')

