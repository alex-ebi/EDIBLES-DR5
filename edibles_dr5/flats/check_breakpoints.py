"""
Analysing quality control parameters of fmtchk frames of EDIBLES data from 2014.01.01 to 2019.12.31.
Used to find time frames for flat coaddition.
Data files are for different chips.
"""
from importlib.resources import files
import numpy as np
import matplotlib.pyplot as plt
from astropy.time import Time
import pandas as pd

data_dir = files('edibles_dr5') / 'supporting_data/fmtchk'
breakpoint_file = files('edibles_dr5') / 'supporting_data/breakpoints_3.csv'
breakpoints = pd.read_csv(breakpoint_file, index_col=0)

def main():
    for file in data_dir.glob('*.txt'):
        data = np.genfromtxt(file, unpack=True, skip_header=2)
        plt.scatter(data[0], data[1], label=file.name)
        plt.scatter(data[0], data[2], label=file.name.replace('dy', 'dx'), marker='x')

    for i, row in breakpoints.iterrows():
        pp = row['MJD']
        plt.axvline(pp, linestyle='--')
        date = Time(pp, format='mjd').iso.split(' ')[0]
        breakpoints.loc[i, 'DATE-OBS'] = date
        plt.annotate(date, (pp, 10))
    
    breakpoints.to_csv(breakpoint_file)
    plt.legend()
    plt.show()

if __name__ == '__main__':
    main()