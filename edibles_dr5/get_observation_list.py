"""
Making table of all EDIBLES OB's.
This is extracted from the download shellscript 'wdb_query_18095_eso_edibles.csv'
"""
import pandas as pd
from importlib.resources import files
import numpy as np


file = files('edibles_dr5') / 'supporting_data/wdb_query_18095_eso_edibles.csv'
df = pd.read_csv(file, skipfooter=6)

df_unique = df.drop_duplicates(subset=['OBJECT', 'TPL START'], ignore_index=True)

print(df)
print(df_unique)

df_unique.to_csv(files('edibles_dr5') / 'supporting_data/obs_names.csv')
