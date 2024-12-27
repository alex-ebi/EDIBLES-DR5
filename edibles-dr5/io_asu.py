import numpy as np
from astropy.io import fits


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


def read_surface_spectrum(file_name: str) -> np.array:
    """
    Reads the spectrum of a surface output-file (e.g. "T9000G1.50X7.0M02HE.100C8.41_flux").

    It first looks for the line in the output, which starts with " SURFACE".
    If no such line is found, the function reads all lines starting at line 100 as spectrum points.

    Parameters
    ----------
    file_name : str
        Name of the surface file

    Returns
    -------
    np.array([wave, flux])
        Surface spectrum in this format: *np.array([wave (Angstrom), normalized flux])*
    """

    with open(file_name) as f:
        data = f.readlines()

    # search for the starting line of the flux columns
    for ind in range(len(data)):
        if data[ind][0:8] == ' SURFACE':
            start_ind = ind + 1

    ind_range = np.arange(start_ind, len(data) - 2)

    dat = np.zeros((2 * len(ind_range), 2))

    i = 0
    for j in ind_range:
        temp = data[j].split()
        dat[i][0] = float(temp[0])
        dat[i][1] = float(temp[1])
        dat[i + 1][0] = float(temp[2])
        dat[i + 1][1] = float(temp[3])
        i += 2

    spec = dat.transpose()

    return spec


def read_atlas9_flux(atlas9_file: str) -> np.array:
    r"""
    Load the radiation flux from an ATLAS9 output file (\*_struct).
    The ATLAS9 Eddington flux gets converted to the Astrophysical flux.

    Parameters
    ----------
    atlas9_file: str
        Name of the file

    Returns
    -------
    np.array([wave, flux])
        wavelength [A], Astrophysical flux [erg/cm^2/s/A]
    """
    wave = np.array([])
    flux = np.array([])
    file = open(atlas9_file, "r")
    for line in file:
        if line[:5] != "FLUX ":
            continue
        data = np.genfromtxt([line], delimiter=[5, 4, 9, 20, 13, 13, 10], usecols=(2, 4))
        wave = np.append(wave, data[0])
        flux = np.append(flux, data[1])
    file.close()
    wave *= 10  # Convert nm to Angstrom
    # (erg/cm^2/s/A); Convert from Eddington to Astrophysical flux
    flux *= 2.9979e18 * 4 / wave ** 2
    flux = np.nan_to_num(flux, copy=False, nan=0)
    return np.array([wave, flux])


def read_atlas9_struct(atlas9_file: str) -> np.array:
    r"""
    Load the atmosphere structure from an ATLAS9 output file (\*_struct).

    Columns:
        RHOX : column mass density [g*cm/s^2]

        T : Kinetic Temperature [K]

        P : Total gas pressure [dyn/cm^2]

        XNE : Free electron number density [cm^-3]

        ABROSS : Rosseland mean mass extinction [cm^2/g]

        ACCRAD : Radiative acceleration [cm/s^2]

        VTURB : Turbulent velocity [cm/s]

        FLXCNV : Convective flux

        VCOMV : Velocity of convective cells [cm/s]

        VELSND : Local sound speed [cm/s]

    Parameters
    ----------
    atlas9_file: str
        Name of the file

    Returns
    -------
    np.array([RHOX, T, P, XNE, ABROSS, ACCRAD, VTURB, FLXCNV, VCOMV, VELSND])
        Atmospheric structure of Atlas9 model.
    """
    file = open(atlas9_file, "r")
    lines = open(atlas9_file, "r").readlines()

    struct_start_index = None

    # Search for header line of structure table
    for i in range(len(lines)):
        if lines[i].startswith('READ '):
            struct_start_index = i + 1
            break

    # If the header is not found, a syntax error gets raised.
    if struct_start_index is None:
        raise SyntaxError('The input file does not have the expected format.\n'
                          'The structure table has to begin with the header line:\n'
                          'READ DECK6 72 RHOX,T,P,XNE,ABROSS,ACCRAD,VTURB, FLXCNV,VCOMV,VELSND')

    struct_array = np.genfromtxt(file, skip_header=struct_start_index, unpack=True, invalid_raise=False)

    return struct_array


def read_molecfit_crires_spec(file_path: str, chip: int = None) -> np.array:
    """
    Reads a molecfit output fits file of oCRIRES with a specified chip number.
    Returns a spectrum. Use *read_molecfit_crires_col_names* to get the column names.
    Can also be used for most other fits files.


    Parameters
    ----------
    file_path : str
        Name of fits file.
    chip : int
        Chip number.

    Returns
    -------
    np.array([Spectrum from fits file])
        Spectrum without the usual ordering ([wave, flux, additional_columns]).
        Order it yourself.
    """
    hdu = fits.open(file_path)  # open fits file

    spec = hdu[chip].data  # get spectrum data of specified chip

    # construct output array for spectrum
    r = np.core.records.fromrecords(spec).tolist()
    out_spec = np.array(r)  # spectrum array in our standard format

    return out_spec


def read_molecfit_crires_col_names(file_path, chip: int = None) -> np.array:
    """
    Reads a molecfit output fits file of oCRIRES with a specified chip number.
    Returns the column names of the spectrum (*read_molecfit_crires_spec*).

    Parameters
    ----------
    file_path : str
        Name of fits file.
    chip : int
        Chip number.

    Returns
    -------
    np.array([column_names:str])
        1D array of column names.
    """
    hdu = fits.open(file_path)  # open fits file

    spec = hdu[chip].data  # get spectrum data of specified chip

    # extract column names
    col_names = spec.names

    return np.array(col_names)


def read_molecfit_crires_header(file_path, chip: int = None) -> dict:
    """
    Reads a molecfit output fits file of oCRIRES with a specified chip number.
    Returns the merged Primary header and Header of the specified chip as a dictionary.

    Parameters
    ----------
    file_path : str
        Name of fits file.
    chip : int
        Chip number.

    Returns
    -------
    dict
        Dictionary containing header information.
    """
    hdu = fits.open(file_path)  # open fits file

    # merge primary header and header of chip hdu
    header = {**hdu[0].header, **hdu[chip].header}

    return header


def read_iue_stis(filename: str, has_error=True) -> np.array:
    """
    Reads an spectrophotometry file (IUE or STIS)
    file columns: wavelength [A], flux [erg/cm^2/s/A], flux uncertainty [erg/cm^2/s/A]

    Parameters
    ----------
    filename: string
        name of the file containing the spectrum
    has_error: bool
        set it to false if the file has no error column

    Returns
    -------
    np.array
        Spectrum with wavelength, flux, flux_uncertainty (set to 1 if has_error = False)
    """
    data = np.genfromtxt(filename)
    x = data.T[0]
    y = data.T[1]
    if has_error:
        y_err = data.T[2]
    else:
        y_err = np.ones(len(x))
    return np.array([x, y, y_err])


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


def read_carmenes(filename: str, return_header=False):
    hdu = fits.open(filename)
    header = hdu[0].header

    spec = np.array([np.concatenate(hdu[4].data), np.concatenate(hdu[1].data)])

    if return_header:
        return spec, header
    else:
        return spec


def read_gaia(filename):
    spec_phot = np.genfromtxt(filename, unpack=True)

    return spec_phot
