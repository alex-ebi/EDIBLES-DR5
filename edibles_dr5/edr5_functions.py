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

    wave = int(wave)

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
        star_name = hdr['OBJECT'].replace(' ', '')
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


def remove_nan_spec(spec: np.array, col: int) -> np.array:
    """
    Removes spectrum bin with nan values in column **col**.

    Parameters
    ----------
    spec : np.array([wave, flux, additional columns])
        Spectrum with nan values.
    col : int
        Index of column to be searched for nan values.

    Returns
    -------
    np.array([wave, flux, additional columns])
        Spectrum without nan values.
    """
    not_nan_ind = ~np.isnan(spec[col])
    return spec.T[not_nan_ind].T


def setting_dependent_crop(spec, wave, merge_delt_dict):
    crop_limits = np.array(merge_delt_dict[wave])
    cl_ang = [np.nanmin(spec[0]) + crop_limits[0], np.nanmax(spec[0]) - crop_limits[1]]

    return cl_ang


def crop_spectrum(array_in: np.array, x_min: float, x_max: float) -> np.array:
    """
    Returns a spectrum interval for x_min < wave < x_max.

    Parameters
    ----------
    array_in : np.array([wave, flux, additional_columns])
        Input spectrum.
    x_min : float
        Minimum wave coordinate of slice.
    x_max : float
        Maximum wave coordinate of slice.

    Returns
    -------
    np.array([wave, flux, additional_columns])
        Spectrum slice
    """
    if x_min > x_max:
        raise ValueError('Slice_spectrum error: x_min is larger than x_max!')

    b1 = array_in[0] < x_max  # boolean array of wave values smaller than x_max
    b2 = x_min < array_in[0]  # boolean array of wave values larger than x_min
    bool_array = np.logical_and(b1, b2)  # boolean array of wave values larger than x_min and smaller than x_max

    return array_in[:, bool_array]


if __name__ == '__main__':
    cleanup_edps_subdir(Path('/home/Alex/EDPS_data/UVES'))