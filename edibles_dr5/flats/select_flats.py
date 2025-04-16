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
    # df = df.sort_values(by=['Exptime', 'MJD-OBS'], ascending=False)
    for i, row in breakpoints.iloc[:-1].iterrows():
        bps = (breakpoints.loc[i, 'MJD'], breakpoints.loc[i+1, 'MJD'])
        bpdates = (breakpoints.loc[i, 'DATE-OBS'], breakpoints.loc[i+1, 'DATE-OBS'])
        sub_df = df.loc[(df['MJD-OBS'] > bps[0]) & (df['MJD-OBS'] < bps[1])]#.sort_values(by='Exptime').iloc[:100]

        # Make grouped Dataframe to find calibrations with highest Exptime
        g_series = sub_df.groupby(by='TPL START')['Exptime'].mean().sort_values(ascending=False).iloc[:30]
        print(g_series.index)
        print('serries',g_series)

        out_df = pd.DataFrame()
        for i, row in g_series.items():
            tmp = sub_df.loc[sub_df['TPL START']==i]
            out_df = pd.concat((out_df, tmp), ignore_index=True)

        print(out_df)
        out_df.to_csv(out_dir / f'{setting}nm_{bpdates[0]}_{bpdates[1]}.csv')

