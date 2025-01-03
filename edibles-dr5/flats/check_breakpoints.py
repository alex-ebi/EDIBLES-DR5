import paths
import numpy as np
import matplotlib.pyplot as plt
from astropy.time import Time

data_dir = paths.diss_dibs / 'edibles_reduction/qc_uves/fmtchk'

breakpoints=[56667, 57119, 57360, 57448, 57777, 58140, 58455]
breakpoints=[56667, 57119, 57448, 57777, 58140, 58455]

for file in data_dir.glob('*.txt'):
    data = np.genfromtxt(file, unpack=True, skip_header=2)
    # data[0] = data[0] / 365.25 -155+2014
    plt.scatter(data[0], data[1], label=file.name)

for pp in breakpoints:
    plt.axvline(pp, linestyle='--')
    plt.annotate(Time(pp, format='mjd').iso.split(' ')[0], (pp, 10))
plt.legend()
plt.show()