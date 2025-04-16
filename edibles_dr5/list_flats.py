from pathlib import Path
from edibles_dr5 import edr5_functions, paths

dir = Path('/home/alex/data/EDR5/selected_flats/860nm_2015-04-07_2015-11-26')

for file in dir.glob('*.fits'):
    print(file, 'FLAT_RED')