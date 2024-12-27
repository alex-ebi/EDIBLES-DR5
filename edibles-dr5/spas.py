import numpy as np
import struct
import os
from astro_scripts_uibk.convolve import find_nearest_index


def float_to_single_precision(value: float) -> bytes:
    """
    Convert float to 4 byte representaion

    Parameters
    ----------
    value: float
        float value to convert

    Returns
    -------
    byte representation
    """
    return struct.pack('<f', value)


def float_to_double_precision(value: float) -> bytes:
    """
    Convert float to 8 byte representaion

    Parameters
    ----------
    value: float
        float value to convert

    Returns
    -------
    byte representation
    """
    return struct.pack('<d', value)


def crop_spectrum(wave: np.array, flux: np.array,
                  lower_bound: float, upper_bound: float) -> np.array:
    """
    Get a part of a spectrum, specified by wavelength bounds.
    It makes sure that the number of points is even (necessary for SPAS)

    Parameters
    ----------
    wave: np.array
        wavelength points, sorted
    flux: np.array
        flux points
    lower_bound: float
        lower wavelength bound of new spectrum
    upper_bound: float
        upper wavelength bound of new spectrum

    Returns
    -------
    first array: new wavelength array
    second array: new flux array
    """
    idx0 = find_nearest_index(wave, lower_bound, is_sorted=True)-1
    if idx0 < 0:
        idx0 = 0
    idx1 = find_nearest_index(wave, upper_bound, is_sorted=True)+1
    idx1 += ((idx1-idx0) % 2)
    return np.array([wave[idx0:idx1], flux[idx0:idx1]])


def is_valid_input(wave: np.array, flux_array: list,
                   temperature_array: np.array, logg_array: np.array):
    """
    Test if given parameters for a spas binary are valid.
    It is possible that this function is not complete.

    Parameters
    ----------
    wave: np.array
        wavelength points, sorted
    flux_array: list
        list that contains numpy flux arrays
    temperature_array: np.array
        array of temperature value for each flux
    logg_array: np.array
        array of log(g) value for each flux

    Returns
    -------
    None
    """
    number_points = len(wave)
    number_fluxes = len(flux_array)

    if number_points % 2 == 1:
        raise ValueError('The number of flux points is not even.')

    for flux in flux_array:
        if len(flux) != number_points:
            raise ValueError('The length of a flux array is not the same length as the wave array.')

    if len(temperature_array) != number_fluxes:
        raise ValueError('The temperature array has a different length than the flux grid.')

    if len(logg_array) != number_fluxes:
        raise ValueError('The log_g array has a different length than the flux grid.')

    for i in range(1, number_fluxes):
        if temperature_array[i] < temperature_array[i-1]:
            raise ValueError('The temperature grid is not in increasing monotonically.')
        if temperature_array[i] <= temperature_array[i-1] and logg_array[i] <= logg_array[i-1]:
            raise ValueError(f'The log_g grid is not increasing while the temperature is constant.\n'
                             f't_eff_grid: {temperature_array}\n'
                             f'log_g_grid: {logg_array}')


def create_binary(wave: np.array, flux_array: list, temperature_array: np.array, logg_array: np.array,
                  abundance: float, file_name: str):
    """
    Function to create SPAS binaries.

    Parameters
    ----------
    wave: np.array
        wavelength points, sorted
    flux_array: list | np.array
        list that contains numpy flux arrays
    temperature_array: np.array
        array of temperature value for each flux array
    logg_array: np.array
        array of log(g) value for each flux array
    abundance: float
        abundance value, same for all flux arrays
    file_name: str | Path
        name of the output file (usually *.bin*)
    """
    is_valid_input(wave, flux_array, temperature_array, logg_array)

    def write_flux(file_descriptor, t, g, abun, f):
        file_descriptor.write(float_to_double_precision(t))
        file_descriptor.write(float_to_double_precision(g))
        file_descriptor.write(float_to_double_precision(abun))
        for flux_point in f:
            file_descriptor.write(float_to_single_precision(flux_point))

    number_fluxes = len(flux_array)
    number_points = len(wave)

    out_file = open(file_name, "wb")

    out_file.write(number_points.to_bytes(4, byteorder="little"))
    zero = 0
    out_file.write(zero.to_bytes(4, byteorder="little"))
    for wave_point in wave:
        out_file.write(float_to_double_precision(wave_point))

    for i in range(number_fluxes):
        temperature = temperature_array[i]
        logg = logg_array[i]
        flux = flux_array[i]

        write_flux(out_file, temperature, logg, abundance, flux)

    if number_fluxes == 1:
        i = 0
        temperature = temperature_array[i]
        logg = logg_array[i]
        flux = flux_array[i]
        write_flux(out_file, temperature, logg+0.05, abundance, flux)
        write_flux(out_file, temperature+100, logg, abundance, flux)
        write_flux(out_file, temperature+100, logg+0.05, abundance, flux)

    out_file.close()


def load_binary_file(file_name: str) -> 'tuple':
    """
    Load the content of a spas binary file

    Parameters
    ----------
    file_name: str
        File name of the spas binary

    Returns
    -------
    tuple:
        float: abundance
        np.array(): Temperature values
        np.array(): Surface gravity values
        np.array(): Wavelength points
        np.array(): Array of fluxes, for each T/logg pair
    """
    file_size = os.path.getsize(file_name)  # file size in bytes
    f = open(file_name, "rb")

    len_wave = int.from_bytes(f.read(4), byteorder="little")
    f.read(4)  # leading zeros
    T = []
    G = []
    flux = []
    abun = 0
    wave = np.array([struct.unpack('<d', f.read(8))[0]
                     for _ in range(len_wave)])
    for _ in range(int((file_size-8-len_wave*8)/(24+4*len_wave))):
        T += [struct.unpack('<d', f.read(8))[0]]  # read temperature
        G += [struct.unpack('<d', f.read(8))[0]]  # read logg
        abun = struct.unpack('<d', f.read(8))[0]  # read abundance
        temp = [struct.unpack('<f', f.read(4))[0]
                for _ in range(len_wave)]  # read flux
        flux += [np.array(temp)]

    f.close()
    return (abun, np.array(T), np.array(G), wave, np.array(flux))


def microgrid(t_eff: float, logg: float, abundance: float, spec: np.array, file_name: str):
    """
    Creates a microgrid binary file for spas.
    A microgrid model only has one Teff and logg, but tricks spas into thinking that there are 2 values each,
    so it accepts the model as a grid.

    Parameters
    ----------
    t_eff : float
        Efficetive temperature
    logg : float
        Surface gravity
    abundance : float
        Elemental abundance (add normalization factor, e.g, 12)
    spec : np.array
        Input spectrum (*np.array([wave, flux])*)
    file_name : str | Path
        Path of output binary file.

    Returns
    -------
    None
    """
    wave = spec[0]  # extract wavelength array
    flux_array = np.repeat([spec[1]], 4, axis=0)  # expand fluxes in microgrid
    # construct Teff and logg microgrids
    t_eff_array = np.repeat([t_eff, t_eff + 1], 2)
    logg_array = np.tile([logg, logg + .01], 2)
    create_binary(wave, flux_array, t_eff_array, logg_array, abundance + 12.04, file_name)
