"""
Absolute paths_dir are defined in this module - import it if needed.
"""
from pathlib import Path

spectra = Path('/home/alex/spectra')
home_dir = Path('/home/alex')
diss_dibs = home_dir / 'diss_dibs'
skirt = home_dir / 'SKIRT'
aanda_2019 = home_dir / 'aanda_2019'
master = home_dir / 'master'
master_local = home_dir / 'master_local'
programs = home_dir / 'programs'

# spectra
optical = diss_dibs / 'spectra/optical'
opt_bary_corr = diss_dibs / 'spectra/optical/bary_corr'
crires_bary_corr = diss_dibs / 'spectra/CRIRES/bary_corr'

# tables
nir_dib_list = diss_dibs / 'tables/paper/nir_dib_list.xlsx'
ism_lines = diss_dibs / 'tables/vrad_fit_data/ism_lines.xlsx'

# WSL
wsl_spectra = spectra
wsl_home_dir = home_dir

# Molecfit and calctrans
molecfit_bin = Path('/home/alex/molecfit/bin')
