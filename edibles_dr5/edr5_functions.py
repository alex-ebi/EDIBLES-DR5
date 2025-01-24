from pathlib import Path
import numpy as np
import sqlite3
from importlib.resources import files
from astropy.io import fits
import pandas as pd


def get_wave_path(hdr):
    try:
        wave = hdr['ESO INS GRAT1 WLEN']
    except KeyError:
        wave = hdr['ESO INS GRAT2 WLEN']

    setting = hdr['ESO INS PATH'].lower()

    return wave, setting


def get_filter_name(hdr):
    try:
        filter_name = hdr['ESO INS FILT2 NAME']
    except KeyError:
        filter_name = hdr['ESO INS FILT3 NAME']

    return filter_name


def wave_from_dispersion(flux, start_wave, dispersion, crpix=0):
    """
    Calculates a wavelength array as a equidistant grid.
    Starts from 'star_wave' and makes further points with a constant separation 'dispersion'.

    Parameters
    ----------
    flux : np.array
        Flux array. Needed to know length of spectrum.
    start_wave : float
        Starting wavelength.
    dispersion : float
        Wavelength step.
    crpix : int
        Index of reference pixel.

    Returns
    -------
    np.array
        Wavelength array matching to flux array in length.
    """
    index_col = np.array(range(len(flux)))
    index_col = index_col - crpix
    wave = index_col * dispersion + start_wave

    return wave


def make_reduction_database(edps_object_dir: Path):
    """
    Makes a database of the directories in EDPS/UVES/objects to make it easier to find the reductions of certain observations.
    """        
    obj_dir_list = list(edps_object_dir.iterdir())
    edps_obj_list_file = files('edibles_dr5') / 'tmp' / 'edps_obs_list.pkl'
    print(len(obj_dir_list))

    if edps_obj_list_file.is_file():
        edps_obs_df = pd.read_pickle(edps_obj_list_file)
        obj_dir_list = [item for item in obj_dir_list if item not in edps_obs_df['sub_dir'].values]
        edps_obs_list = list(edps_obs_df.itertuples(index=False))
 
    else: 
        edps_obs_list = []

    for sub_dir in obj_dir_list:
        # List all resampled science files in EDPS directory
        science_files = list(sub_dir.glob('*resampled_science_*'))
        # Skip sub-directory if there are no fully processed science files
        if len(science_files) == 0:
            continue
        with fits.open(science_files[0]) as f:
            hdr = f[0].header
        # If the file does not match the current OB, skip
        star_name = hdr['OBJECT'].strip(' ')
        eso_tpl_start = hdr['ESO TPL START']
        edps_obs_list.append((sub_dir, star_name, eso_tpl_start))   

    edps_obs_df = pd.DataFrame(edps_obs_list , columns=['sub_dir', 'OBJECT', 'ESO TPL START'])
    edps_obs_df.to_pickle(files('edibles_dr5') / 'tmp' / 'edps_obs_list.pkl')

    return edps_obs_df



if __name__ == '__main__':
    make_reduction_database()