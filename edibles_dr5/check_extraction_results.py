import matplotlib.pyplot as plt
import numpy as np
from astropy.io import fits
import pandas as pd
from pathlib import Path
import paths
from importlib.resources import files

plot_method = 'linear'

# Directory containing the EDIBLES DR4 spectra
dr4_dir = paths.dr4_dir

# Directory containing the EDIBLES DR5 spectra
edr5_dir = paths.edr5_orders_dir

# Directory containing ESO spectra from the science archive
eso_dir = paths.edr5_dir / 'science_archive'


def get_wave_path(hdr):
    try:
        wave = hdr['ESO INS GRAT1 WLEN']
    except KeyError:
        wave = hdr['ESO INS GRAT2 WLEN']

    setting = hdr['ESO INS PATH'].lower()

    return wave, setting


def setting_dependent_crop(spec, wave):
    crop_lim_dict = {346: [10, 10], 437: [13, 7], 564: [19, 4], 860: [20, 0]}
    crop_limits = np.array(crop_lim_dict[wave])
    cl_ang = [np.nanmin(spec[0]) + crop_limits[0], np.nanmax(spec[0]) - crop_limits[1]]

    return cl_ang


obs_list = pd.read_csv(files('edibles_dr5') / 'supporting_data/obs_names.csv', index_col=0)

print(obs_list)

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


def plot_product(spec_dir, star_name, obs_date, plt_color, use_mask=False):
    spec_list = list(spec_dir.rglob('*.fits'))
    spec_list = [item for item in spec_list if star_name in item.name]

    if isinstance(obs_date, str):
        spec_list = [item for item in spec_list if obs_date in item.name]

    if len(spec_list) == 0:
        return False

    for spec_path in spec_list:
        hdul = fits.open(spec_path)

        hdr = hdul[0].header
        data = hdul[1].data
        wave, _ = get_wave_path(hdr)

        spec = np.array([data['WAVE'], data['FLUX'], data['ERROR']])

        cl_ang = setting_dependent_crop(spec, wave)
        
        cropped_spec = crop_spectrum(spec, cl_ang[0], cl_ang[1])

        if plot_method == 'step':
            plt.step(spec[0], spec[1] / np.median(spec[1]), where='mid', color=plt_color, alpha=0.3)
            plt.step(cropped_spec[0], cropped_spec[1] / np.median(spec[1]), where='mid', color=plt_color)
        else:
            plt.plot(spec[0], spec[1] / np.median(spec[1]), color=plt_color, alpha=0.3)
            plt.plot(cropped_spec[0], cropped_spec[1] / np.median(spec[1]), color=plt_color)

    return True

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

def read_uves(filename: str, return_header=False):
    """
    Reads ESO-UVES data.
    Calculates the wavelengths from the header keywords 'CRVAL1' and 'CDELT1'.

    Parameters
    ----------
    filename : str
        File path.
    return_header : bool
        If True, the function returns a tuple: spectrum and header. Default: False.

    Returns
    -------
    np.array or (np.array, fits.Header)
    """
    hdu = fits.open(filename)
    header = hdu[0].header
    flux = hdu[0].data

    wave = wave_from_dispersion(flux, header['CRVAL1'], header['CDELT1'])

    spec = np.array([wave, flux])

    if return_header:
        return spec, header
    else:
        return spec



def main():
    for i, row in obs_list.iterrows():
        print(i)
        star_name = row.OBJECT
        obs_date = row['TPL START']
        plt.figure(figsize=(20, 10))

        cont_flag = plot_product(edr5_dir, star_name, obs_date, 'b', use_mask=False)

        if not cont_flag:
            plt.close()
            continue


        # ESO science archive spectra
        eso_files = eso_dir.glob('*.fits')
        for eso_file in eso_files:
            with fits.open(eso_file) as f:
                hdr = f[0].header
                data = f[1].data
            if hdr['ESO TPL START'] == obs_date:
                eso_spec = np.array([data['WAVE'][0], data['FLUX_REDUCED'][0]])

                eso_spec[1] /= np.median(eso_spec[1])

                if plot_method == 'step':
                    plt.step(eso_spec[0], eso_spec[1], where='mid', color='k')
                else:
                    plt.plot(eso_spec[0], eso_spec[1], 'k')
                break

        # DR4 spectra
        file_list = list(dr4_dir.rglob('*.fits'))
        file_list = [item for item in file_list if item.match(f'*{star_name}*')]
        print("".join(obs_date[:10].split('-')))

        file_list = [item for item in file_list if item.match(f'*{"".join(obs_date[:10].split('-'))}*')]

        for edibles_file in file_list:
            edibles_spec = read_uves(edibles_file)

            edibles_spec[1] /= np.median(edibles_spec[1])

            if plot_method == 'step':
                plt.step(edibles_spec[0], edibles_spec[1], where='mid', color='g')
            else:
                plt.plot(edibles_spec[0], edibles_spec[1], 'g')

        plt.ylim(0, 5)
        plt.xlabel(r'$\lambda(\AA)$')
        plt.ylabel('Flux')
        plt.title(f'{star_name} {obs_date}')
        plt.show()


if __name__ == '__main__':
    main()
