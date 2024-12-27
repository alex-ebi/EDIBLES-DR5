from astro_scripts_uibk.convolve import find_nearest_value
import numpy as np


def met_to_str(met: float) -> str:
    """
    Converts the float value of the logarithmic metallicity relative to the sun to its string representation.
    e.g. -0.1 -> M01, +0.2 -> P02, 0.0 -> P00
    :param met: Metallicity relative to solar value
    :return: string

    Parameters
    ----------
    met : float
        Metallicity relative to solar value.

    Returns
    -------
    string
        Metallicity string.
    """
    if met >= 0:
        _met_sign = "P"
    else:
        _met_sign = "M"
    return _met_sign + f'{abs(met):3.1f}'[0] + f'{abs(met):3.1f}'[2]


def ds_abundance_table(com_list: list, abundance_dict: dict) -> list:
    """
    Writes elemental abundances from a dictionary into a DETAIL/SURFACE command file.
    Only changes the present table. If an element key is not present, an error is raised.

    Parameters
    ----------
    com_list : list
        List of lines (i.e. strings) of a DETAIL/SURFACE command file.

    abundance_dict : dict
        Dictionary of elemental abundances.

    Returns
    -------
    list
        List of lines (i.e. strings) of a DETAIL/SURFACE command file with new abundances.
    """

    for key, value in abundance_dict.items():  # loop over elemental abundances
        element_found = False  # assign boolean indicating if the element key word was found

        for i, line_string in enumerate(com_list):  # loop over lines in command file
            if line_string.startswith('ABUNDANCE'):  # find abundance table lines
                key_loc = line_string.find(f' {key} ')  # find the element name in the abundance table

                if key_loc != -1:  # if the element key is found, initiate assignment of abundance
                    element_found = True  # indicate that the element was found
                    val_start = key_loc + len(key) + 2  # assign location of start of value string
                    val_end = val_start + 5  # assign location of end of value string

                    # rewrite the line of abundance table with new abundance value
                    com_list[i] = f'{com_list[i][:val_start]}{value:5.2f}{com_list[i][val_end:]}'

        if not element_found:  # raise error if element key is not found in abundance table
            raise KeyError(f'The key for the element "{key}" was not found in the DETAIL/SURFACE command file.')

    return com_list


def change_output_path(com_list: list, output_name: str, key='<input > ') -> list:
    """
    Changes the output file path.

    Parameters
    ----------
    com_list : list
        List of lines (i.e. strings) of a DETAIL/SURFACE/Atlas command file.

    output_name : string
        New output file path.

    key : str
        String before the output path in the command file. (Default: '<input > ')

    Returns
    -------
    list
        List of lines (i.e. strings) of a DETAIL/SURFACE command file with output file path.
    """
    key_found = False  # assign boolean indicating if the key word was found

    for i, line_string in enumerate(com_list):  # loop over lines in command file
        if key in line_string:  # find line with key
            key_found = True  # indicate that the key was found
            key_loc = line_string.find(key)  # find key location in line
            # rewrite output name
            com_list[i] = f'{line_string[:key_loc + len(key)]}{output_name}\n'

    if not key_found:  # raise error if element key is not found in abundance table
        raise KeyError(f'The key "{key}" was not found in the DETAIL/SURFACE command file.')

    return com_list


def ds_microturbulence(com_list: list, microturbulence: float) -> list:
    """
    Changes the microturbulence in a Detail or Surface command file.

    Parameters
    ----------
    com_list : list
        List of lines (i.e. strings) of a DETAIL/SURFACE command file.

    microturbulence : float
        New microturbulence (km/s).

    Returns
    -------
    list
        List of lines (i.e. strings) of a DETAIL/SURFACE command file with output file path.
    """
    for i, line_string in enumerate(com_list):  # loop over lines in command file
        if line_string.startswith('TURBULENCE'):  # find microturbulence line
            com_list[i] = f'TURBULENCE {microturbulence:3.1f}\n'

    return com_list


def atlas_z(com_list: list, z: float):
    """
    Changes the metallicity in an Atlas command file for the kappa ros and ODF file names.

    Parameters
    ----------
    com_list : list
        List of lines (i.e. strings) of a DETAIL/SURFACE command file.

    z : float
        Metallicity relative to solar value.

    Returns
    -------
    list
        List of lines (i.e. strings) of an Atlas command file with new ODF and ros file names.
    """
    met_str = met_to_str(z).lower()
    for i, line_string in enumerate(com_list):  # loop over lines in command file
        if line_string.replace(' ', '').endswith('fort.1\n'):  # find kappa rosseland line
            key_loc = line_string.find('.ros ')  # find kappa file ending as key
            # insert the new metallicity
            com_list[i] = f'{line_string[:key_loc - 3]}{met_str}{line_string[key_loc:]}'
        # ODF FILE LINE
        elif line_string.replace(' ', '').endswith('fort.9\n'):  # find ODF line
            key_loc = line_string.find('.bdf ')  # find ODF file ending as key
            # insert the new metallicity
            com_list[i] = f'{line_string[:key_loc - 7]}{met_str}{line_string[key_loc - 4:]}'

    return com_list


def atlas_he(com_list: list, he: float):
    """
    Changes the helium abundance of an Atlas command file.
    The line containing the H and He abundance has to start with the string: " ABUNDANCE CHANGE  1 ".

    Parameters
    ----------
    com_list : list
        List of lines (i.e. strings) of an Atlas command file.

    he : float
        Linear helium abundance

    Returns
    -------
    list
        List of lines (i.e. strings) of an Atlas command file with new helium abundance.
    """
    h = 1 - he  # calculate hydrogen abundance
    for i, line_string in enumerate(com_list):  # loop over lines in command file
        if line_string.startswith(' ABUNDANCE CHANGE  1 '):  # find line with H and He abundances
            # insert the new helium abundance
            com_list[i] = f' ABUNDANCE CHANGE  1 {h:6.2f}  2 {he:6.2f}\n'

    return com_list


def atlas_microturbulence(com_list: list, microturbulence: float) -> list:
    """
    Changes the microturbulence in an Atlas command file.
    Also changes the ODF file to the closest microturbulence.

    Parameters
    ----------
    com_list : list
        List of lines (i.e. strings) of an Atlas command file.

    microturbulence : float
        New microturbulence (km/s).

    Returns
    -------
    list
        List of lines (i.e. strings) of an Atlas command file with new output file path.
    """
    allowed_odf_microturbulence = np.array([0, 1, 2, 4, 8])

    for i, line_string in enumerate(com_list):  # loop over lines in command file
        # VTURB LINE
        if line_string.startswith('VTURB'):  # find microturbulence line
            com_list[i] = f'VTURB {microturbulence:3.1f}E+5\n'
        # ODF FILE LINE
        elif line_string.replace(' ', '').endswith('fort.9\n'):  # find ODF line
            key_loc = line_string.find('.bdf ')  # find ODF file ending as key
            # find the nearest allowed value for an ODF file
            odf_vel = find_nearest_value(allowed_odf_microturbulence, microturbulence)
            # insert the new microturbulence
            com_list[i] = f'{line_string[:key_loc - 1]}{int(odf_vel)}{line_string[key_loc:]}'

    return com_list


def atlas_teff_logg(com_list: list, t_eff: float, log_g: float):
    """
    Changes Teff and log(g) in the line 'SCALE' of an Atlas command file.

    Parameters
    ----------
    com_list : list
        List of lines (i.e. strings) of a Atlas command file.

    t_eff : float
        Effective temperature.

    log_g : float
        Surface gravity (cm/s^2).

    Returns
    -------
    list
        List of lines (i.e. strings) of an Atlas command file with new 'SCALE' parameters.
    """
    for i, line_string in enumerate(com_list):  # loop over lines in command file
        if line_string.startswith('SCALE'):  # find microturbulence line
            params = line_string.split(' ')  # split strings of line
            # assign new value strings to locations in line
            com_list[i] = f'SCALE {params[1]} {params[2]} {params[3]} {int(t_eff)}. {log_g:4.2f}\n'

    return com_list


def ds_input(com_list: list, input_path: str, key='fort.8'):
    """
    Changes the path of an input file (atlas.struct or detail.pops) of a Detail or Surface command file.

    Parameters
    ----------
    com_list : list
        List of lines (i.e. strings) of a DETAIL/SURFACE command file.

    input_path : string | Path
        New input file path.

    key : string
        String at the end of the input line. (Default: 'fort.8' - for atlas struct input)

    Returns
    -------
    list
        List of lines (i.e. strings) of a DETAIL/SURFACE command file with new Atlas.struct file path.
    """
    key_found = False  # assign boolean indicating if the key word was found
    for i, line_string in enumerate(com_list):  # loop over lines in command file
        if line_string.replace(' ', '').endswith(f'{key}\n'):  # find line with key
            key_found = True  # indicate that the key was found
            com_list[i] = f'cp {input_path} {key}\n'

    if not key_found:  # raise error if element key is not found in abundance table
        raise KeyError(f'The key "{key}" was not found in the DETAIL/SURFACE command file.')

    return com_list


def modify_atlas_com(com_list: list, t_eff=None, log_g=None, microturbulence=None, z=None, he=None,
                     out_control_path=None, out_struct_path=None) -> list:
    """
    Modifies several parameters of an Atlas9 command file.

    Parameters
    ----------
    com_list : list
        List of lines (i.e. strings) of an Atlas command file.

    t_eff : float
        Effective temperature.

    log_g : float
        Surface gravity (cm/s^2).

    microturbulence : float
        New microturbulence (km/s).

    z : float
        Metallicity relative to solar value.

    he : float
        Linear helium abundance

    out_control_path : string | Path
        Path of output control file.

    out_struct_path : string | Path
        Path of output struct file.

    Returns
    -------
    list
        List of lines (i.e. strings) of a Atlas command file with output file path.
    """
    if z is not None:  # change metallicity for ODFs and kappa rosseland file names
        com_list = atlas_z(com_list, z)

    if he is not None:
        com_list = atlas_he(com_list, he)

    if microturbulence is not None:  # change microturbulence
        com_list = atlas_microturbulence(com_list, microturbulence)

    if t_eff is not None or log_g is not None:  # change Teff and log(g)
        com_list = atlas_teff_logg(com_list, t_eff, log_g)

    if out_control_path is not None:  # change output control file path
        com_list = change_output_path(com_list, out_control_path, key='<EOF>')

    if out_struct_path is not None:  # change output struct file path
        com_list = change_output_path(com_list, out_struct_path, key='fort.7 ')

    return com_list


def modify_detail_com(com_list: list, microturbulence=None, abundance_dict=None, atlas_struct_path=None,
                      out_control_path=None, out_pops_path=None) -> list:
    """
    Modifies several parameters of an Detail command file.


    Parameters
    ----------
    com_list : list
        List of lines (i.e. strings) of a Detail command file.

    microturbulence : float
        New microturbulence (km/s).

    abundance_dict : dict
        Dictionary of elemental abundances.

    atlas_struct_path : string | Path
        New ATLAS.struct input file path.

    out_control_path : string | Path
        Path of output control file.

    out_pops_path : string | Path
        Path of output pops file.

    Returns
    -------
    list
        List of lines (i.e. strings) of a DETAIL/SURFACE command file with output file path.
    """

    if abundance_dict is not None:  # change abundances
        com_list = ds_abundance_table(com_list, abundance_dict)

    if microturbulence is not None:  # change microturbulence
        com_list = ds_microturbulence(com_list, microturbulence)

    if atlas_struct_path is not None:  # change Atlas input file (.struct)
        com_list = ds_input(com_list, atlas_struct_path)

    if out_control_path is not None:  # change output control file (.dout)
        com_list = change_output_path(com_list, out_control_path)

    if out_pops_path is not None:  # change output pops file (.pops)
        com_list = change_output_path(com_list, out_pops_path, key='fort.7 > ')

    return com_list


def modify_surface_com(com_list: list, microturbulence=None, abundance_dict=None, atlas_struct_path=None,
                       detail_pops_dict=None, out_control_path=None, out_flux_path=None) -> list:
    """
    Modifies several parameters of an Surface command file.


    Parameters
    ----------
    com_list : list
        List of lines (i.e. strings) of a Surface command file.

    microturbulence : float
        New microturbulence (km/s).

    abundance_dict : dict
        Dictionary of elemental abundances.

    atlas_struct_path : string | Path
        New ATLAS.struct input file path.

    detail_pops_dict : dict
        Dictionary of paths of the Detail pops files.
        Syntax in surface command file: e.g. "cp path key" (key = 'pops')
        The keys are then part of the input: "cat srf model key enddat > input" (this line has to be changed manually)

    out_control_path : string | Path
        Path of output control file.

    out_flux_path : string | Path
        Path of output flux file.

    Returns
    -------
    list
        List of lines (i.e. strings) of a DETAIL/SURFACE command file with output file path.
    """

    if abundance_dict is not None:  # change abundances
        com_list = ds_abundance_table(com_list, abundance_dict)

    if microturbulence is not None:  # change microturbulence
        com_list = ds_microturbulence(com_list, microturbulence)

    if atlas_struct_path is not None:  # change Atlas input file (.struct)
        com_list = ds_input(com_list, atlas_struct_path)

    if detail_pops_dict is not None:  # change detail pops files (.pops)
        for key, path in detail_pops_dict.items():
            com_list = ds_input(com_list, path, key=key)

    if out_control_path is not None:  # change output control file (.sout)
        com_list = change_output_path(com_list, out_control_path)

    if out_flux_path is not None:  # change output flux file (.flux)
        com_list = change_output_path(com_list, out_flux_path, key='fort.70 ')

    return com_list
