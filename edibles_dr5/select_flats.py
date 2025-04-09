"""
Checking how many flats are downloaded per time bin.
To keep the use of data limited, only flats with an exposure time exceeding a certain threshold are downloaded.
"""
import pandas as pd
from importlib.resources import files

file_dir = files('edibles_dr5') / 'supporting_data'
out_dir = files('edibles_dr5') / 'supporting_data/selected_flats'

breakpoint_file = files('edibles_dr5') / 'supporting_data/breakpoints_4.csv'
breakpoints = pd.read_csv(breakpoint_file, index_col=0)

# Files listing the complete flats over the time frame from 2014.01.01 to 2019.12.31.
files = [
    ('wdb_query_16130_eso_346.csv', 346),
    ('wdb_query_17425_eso_437.csv', 437),
    ('wdb_query_17655_eso_564.csv', 564),
    ('wdb_query_17713_eso_860.csv', 860),
]

for file, setting in files:
    df = pd.read_csv(file_dir / file, skipfooter=6)
    df = df.sort_values(by=['Exptime', 'MJD-OBS'], ascending=False)
    for i, row in breakpoints.iloc[:-1].iterrows():
        bps = (breakpoints.loc[i, 'MJD'], breakpoints.loc[i+1, 'MJD'])
        bpdates = (breakpoints.loc[i, 'DATE-OBS'], breakpoints.loc[i+1, 'DATE-OBS'])
        sub_df = df.loc[(df['MJD-OBS'] > bps[0]) & (df['MJD-OBS'] < bps[1])].iloc[:100]
        sub_df.to_csv(out_dir / f'{setting}nm_{bpdates[0]}_{bpdates[1]}.csv')

