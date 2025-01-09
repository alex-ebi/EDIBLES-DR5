"""
Checking eso download table.
"""
import pandas as pd
from importlib.resources import files
import numpy as np


file = files('edibles_dr5') / 'supporting_data/wdb_query_18095_eso_edibles.csv'
df = pd.read_csv(file, skipfooter=6)
print(df)
print(df.columns)
print(df.Filter.unique())


def parse_obs_name(row):
    return f'{row.OBJECT}__{row["TPL START"]}'


df['obs_name'] = df.apply(parse_obs_name, axis=1)

print(df)
unique_obs = df.obs_name.unique()

objects = [item.split('__')[0] for item in unique_obs]
obs_times = [item.split('__')[1] for item in unique_obs]

print(len(unique_obs))
df_unique = pd.DataFrame(data=np.array([objects, obs_times]).T, columns=['OBJECT', 'TPL START'])

df_unique.to_csv(files('edibles_dr5') / 'supporting_data/obs_names.csv')
