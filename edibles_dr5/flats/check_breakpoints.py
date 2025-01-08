"""
Analysing quality control parameters of fmtchk frames of EDIBLES data from 2014.01.01 to 2019.12.31.
Used to find time frames for flat coaddition.
Data files are for different chips.
"""
from importlib.resources import files
import numpy as np
import matplotlib.pyplot as plt
from astropy.time import Time

data_dir = files('edibles_dr5') / 'qc_uves/fmtchk'

breakpoints=[56667, 57119, 57360, 57448, 57777, 58140, 58455]
breakpoints=[56667, 57119, 57448, 57777, 58140, 58455]

for file in data_dir.glob('*.txt'):
    data = np.genfromtxt(file, unpack=True, skip_header=2)
    plt.scatter(data[0], data[1], label=file.name)

for pp in breakpoints:
    plt.axvline(pp, linestyle='--')
    plt.annotate(Time(pp, format='mjd').iso.split(' ')[0], (pp, 10))
plt.legend()
plt.show()