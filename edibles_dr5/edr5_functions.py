from pathlib import Path
import numpy as np
from importlib.resources import files
from astropy.io import fits
import pandas as pd
import os


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


def make_reduction_database(edps_object_dir: Path) -> pd.DataFrame:
    """
    Makes a database of the directories in EDPS/UVES/objects to make it easier to find the reductions of certain 
    observations.

    Parameters
    ----------
    edps_object_dir : Path
        Path to EDPS object directory.

    Returns
    -------
    pd.DataFrame
        DataFrame of object sub-directories ('sub_dir') with associated star name ('OBJECT') and observation date 
        ('ESO TPL START')
    """
    obj_dir_list = list(edps_object_dir.iterdir())
    edps_obj_list_file = files('edibles_dr5') / 'tmp' / 'edps_obs_list.pkl'

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


def cleanup_edps_subdir(sub_dir: Path) -> None:
    """
    Deletes additional products from the esorex debug mode to conserve disk space.

    Parameters
    ----------
    sub_dir : Path
        _description_
    """

    file_list = list(sub_dir.glob('*.fits'))

    file_list = [item for item in file_list if 'resampled_science_' not in item.name]
    file_list = [item for item in file_list if 'wave_map' not in item.name]
    file_list = [item for item in file_list if 'merged_sky' not in item.name]
    file_list = [str(item) for item in file_list]

    rm_str = ' '.join(file_list)

    os.system(f'rm {rm_str}')


