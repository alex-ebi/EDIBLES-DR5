"""
Checking how many flats are downloaded per time bin.
To keep the use of data limited, only flats with an exposure time exceeding a certain threshold are downloaded.
"""
import pandas as pd
import matplotlib.pyplot as plt
from importlib.resources import files

file_dir = files('edibles_dr5') / 'supporting_data'

# Files listing the complete flats over the time frame from 2014.01.01 to 2019.12.31.
# The second part of the tuple is the lower exposure time limit of the flats.
files = [
    ('wdb_query_16130_eso_346.csv', 20),
    ('wdb_query_17425_eso_437.csv', 110),
    ('wdb_query_17655_eso_564.csv', 14),
    ('wdb_query_17713_eso_860.csv', 23),
]

for file, min_exp in files:
    df = pd.read_csv(file_dir / file, skipfooter=6)
    sub_df = df.loc[df.Exptime > min_exp]

    plt.hist(df['TPL START'], bins=6, label='Full sample')
    plt.hist(sub_df['TPL START'], bins=6, label='Sample with time limit')
    plt.legend()
    plt.show()
