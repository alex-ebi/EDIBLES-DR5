from astroquery.vizier import Vizier
import numpy as np
from astropy import units as u
import pandas as pd
from astroquery.utils.commons import TableList
from astropy.table.table import Table
from astro_scripts_uibk.transformations import mag_to_flux
from importlib.resources import files


def multi_row_exception(result: Table):
    """Handle exception if multiple targets are found in the search radius."""
    if len(result) > 1:
        df = result.to_pandas()
        print('Exception in asu.query: Multiple values found for search radius!',
              'Result:\n')
        with pd.option_context('display.max_rows', None, 'display.max_columns', None):  # more options can be specified
            print(df)
        index = int(input('Type the line index, you want to select, or enter "-1" '
                          'if you dont want any of those lines.'))

        if index == -1:
            return None
        else:
            return result[[index]]
    else:
        return result


def mask_as_nan(df: pd.DataFrame) -> pd.DataFrame:
    """
    Replaces nan values in a DataFrame with np.nan.
    Possible masks of the input DataFrame are defined in map_func.
    """

    def map_func(x):
        """Converts several nan masks to np.nan."""
        if np.ma.is_masked(x) or x == '':
            return np.nan
        else:
            return x

    return df.map(map_func)


def apply_flux(df: pd.DataFrame) -> pd.DataFrame:
    """
    Apply the asu.transformations.mag_to_flux function to a magnitude DataFrame.
    """

    def app_func(x: pd.Series):
        """Define applied function for photometry DataFrames."""
        return mag_to_flux(x.name, x['mag'])

    df['flux'] = df.apply(app_func, axis=1)

    return df


def filter_wave(filter_name: str) -> float:
    """
    Add wavelength to a filter in a row of a DataFrame.
    """
    filter_data_path = files('astro_scripts_uibk') / 'filter_profiles/filter_data.csv'
    filter_data_df = pd.read_csv(filter_data_path, index_col=[0], header=[0], comment='#')
    return filter_data_df.loc[filter_name, 'wave']


def apply_wave(df: pd.DataFrame) -> pd.DataFrame:
    """
    Apply the asu.query.filter_wave function to a magnitude DataFrame.
    """

    def app_func(x: pd.Series):
        """Define applied function for photometry DataFrames."""
        return filter_wave(x.name)

    df['wave'] = df.apply(app_func, axis=1)

    return df


def get_ans_mags(obj_name: str, radius: float = 10) -> pd.DataFrame:
    """
    Makes a Vizier query for an object in the ANS catalog.

    Parameters
    ----------
    obj_name : str
        Simbad object name.
    radius : float
        search radius in arc-seconds.

    Returns
    -------
    pd.DataFrame(columns=['mag', 'mag_error', 'flux', 'wave'])
        DataFrame with filter names as index with Magnitudes, magnitude errors, physical flux calculated from
        magnitude and effective filter wavelength.
    """
    catalog = 'II/97/ans'  # ANS (Wesselius+ 1982)

    # Perform a query on the star and save data in query_object
    result: TableList = Vizier.query_object(obj_name, radius=radius * u.arcsec, catalog=[catalog])
    df = pd.DataFrame(columns=['mag', 'mag_error'])

    if len(result.keys()) == 0:
        print('No ANS data found for %s with the search radius r = %f arcsec!' % (obj_name, radius))
        return df

    ans = result[catalog]  # Extract ANS result from TableList
    ans = multi_row_exception(ans)  # Handle multiple measurements.

    if ans is None:
        return df

    else:
        # Write magnitudes to DataFrame
        df.loc["ANS_15W", 'mag'] = ans["_15W"][0]
        df.loc["ANS_18", 'mag'] = ans["_18"][0]
        df.loc["ANS_22", 'mag'] = ans["_22"][0]
        df.loc["ANS_25", 'mag'] = ans["_25"][0]
        df.loc["ANS_33", 'mag'] = ans["_33"][0]

        # Write magnitude errors to DataFrame
        df.loc["ANS_15W", 'mag_error'] = ans["l_15W"][0]
        df.loc["ANS_18", 'mag_error'] = ans["l_18"][0]
        df.loc["ANS_22", 'mag_error'] = ans["l_22"][0]
        df.loc["ANS_25", 'mag_error'] = ans["l_25"][0]
        df.loc["ANS_33", 'mag_error'] = ans["l_33"][0]

        df = apply_flux(df)  # add physical fluxes to DataFrame
        df = apply_wave(df)  # add mean filter wavelengths to DataFrame
        df = mask_as_nan(df)  # replace nan values with np.nan
        df.dropna(subset=['mag'], inplace=True)  # drop rows without magnitude values

        return df


def get_swift_mags(obj_name: str, radius: float = 10) -> pd.DataFrame:
    """
    Makes a Vizier query for an object in the SWIFT catalog.

    Parameters
    ----------
    obj_name : str
        Simbad object name.
    radius : float
        search radius in arc-seconds.

    Returns
    -------
    pd.DataFrame(columns=['mag', 'mag_error', 'flux', 'wave'])
        DataFrame with filter names as index with Magnitudes, magnitude errors, physical flux calculated from
        magnitude and effective filter wavelength.
    """
    catalog = 'II/339/uvotssc1'  # SWIFT

    # Perform a query on the star and save data in query_object
    result = Vizier.query_object(obj_name, radius=radius * u.arcsec, catalog=[catalog])
    df = pd.DataFrame(columns=['mag', 'mag_error'])

    if len(result.keys()) == 0:
        print('No SWIFT data found for %s with the search radius r = %f arcsec!' % (obj_name, radius))
        return df

    swift = result[catalog]  # Extract ANS result from TableList
    swift = multi_row_exception(swift)  # Handle multiple measurements.

    if swift is None:
        return df

    else:
        # Write magnitudes to DataFrame
        df.loc["Swift_UVW1", 'mag'] = swift["UVW1-AB"][0]
        df.loc["Swift_UVW2", 'mag'] = swift["UVW2-AB"][0]
        df.loc["Swift_UVM2", 'mag'] = swift["UVM2-AB"][0]

        # Write magnitude errors to DataFrame by dividing values by S/N
        df.loc["Swift_UVW1", 'mag_error'] = swift["UVW1-AB"][0]/swift["sUVW1"][0]
        df.loc["Swift_UVW2", 'mag_error'] = swift["UVW2-AB"][0]/swift["sUVW2"][0]
        df.loc["Swift_UVM2", 'mag_error'] = swift["UVM2-AB"][0]/swift["sUVM2"][0]

        df = apply_flux(df)  # add physical fluxes to DataFrame
        df = apply_wave(df)  # add mean filter wavelengths to DataFrame
        df = mask_as_nan(df)  # replace nan values with np.nan
        df.dropna(subset=['mag'], inplace=True)  # drop rows without magnitude values

        return df


def get_mermilliod_mags(obj_name: str, radius: float = 10) -> pd.DataFrame:
    """
    Makes a Vizier query for an object in the Mermilliod catalog.

    Parameters
    ----------
    obj_name : str
        Simbad object name.
    radius : float
        search radius in arc-seconds.

    Returns
    -------
    pd.DataFrame(columns=['mag', 'mag_error', 'flux', 'wave'])
        DataFrame with filter names as index with Magnitudes, magnitude errors, physical flux calculated from
        magnitude and effective filter wavelength.
    """
    catalog = 'II/168/ubvmeans'  # Mermilliod 1991

    # Perform a query on the star and save data in query_object
    result = Vizier.query_object(obj_name, radius=radius * u.arcsec, catalog=[catalog])
    df = pd.DataFrame(columns=['mag', 'mag_error'])

    if len(result.keys()) == 0:
        print('No Mermilliod (UVB) data found for %s with the search radius r = %f arcsec!' % (obj_name, radius))
        return df

    mermilliod = result[catalog]  # Extract ANS result from TableList
    mermilliod = multi_row_exception(mermilliod)  # Handle multiple measurements.

    if mermilliod is None:
        return df

    else:
        # calculate magnitudes
        v_mag = mermilliod["Vmag"]
        b_mag = v_mag + mermilliod["B-V"]
        u_mag = b_mag + mermilliod["U-B"]
        # assign magnitudes to DataFrame
        df.loc["U", 'mag'] = u_mag[0]
        df.loc["B", 'mag'] = b_mag[0]
        df.loc["V", 'mag'] = v_mag[0]

        # calculate magnitude errors
        e_v_mag = mermilliod["e_Vmag"]
        e_b_mag = np.sqrt(e_v_mag ** 2 + mermilliod["e_B-V"] ** 2)
        e_u_mag = np.sqrt(e_b_mag ** 2 + mermilliod["e_U-B"] ** 2)
        # assign magnitude errors to DataFrame
        df.loc["U", 'mag_error'] = e_u_mag[0]
        df.loc["B", 'mag_error'] = e_b_mag[0]
        df.loc["V", 'mag_error'] = e_v_mag[0]

        df = apply_flux(df)  # add physical fluxes to DataFrame
        df = apply_wave(df)  # add mean filter wavelengths to DataFrame
        df = mask_as_nan(df)  # replace nan values with np.nan
        df.dropna(subset=['mag'], inplace=True)  # drop rows without magnitude values

        return df


def get_2mass_mags(obj_name: str, radius: float = 10) -> pd.DataFrame:
    """
    Makes a Vizier query for an object in the 2MASS catalog.

    Parameters
    ----------
    obj_name : str
        Simbad object name.
    radius : float
        search radius in arc-seconds.

    Returns
    -------
    pd.DataFrame(columns=['mag', 'mag_error', 'flux', 'wave'])
        DataFrame with filter names as index with Magnitudes, magnitude errors, physical flux calculated from
        magnitude and effective filter wavelength.
    """
    catalog = 'II/246/out'  # 2MASS (Cutri+ 2003)

    # Perform a query on the star and save data in query_object
    result = Vizier.query_object(obj_name, radius=radius * u.arcsec, catalog=[catalog])
    df = pd.DataFrame(columns=['mag', 'mag_error'])

    if len(result.keys()) == 0:
        print('No 2MASS data found for %s with the search radius r = %f arcsec!' % (obj_name, radius))
        return df

    two_mass = result[catalog]  # Extract ANS result from TableList
    two_mass = multi_row_exception(two_mass)  # Handle multiple measurements.

    if two_mass is None:
        return df

    else:
        # assign magnitudes to DataFrame
        df.loc["2MASS_J", 'mag'] = two_mass["Jmag"][0]
        df.loc["2MASS_H", 'mag'] = two_mass["Hmag"][0]
        df.loc["2MASS_K", 'mag'] = two_mass["Kmag"][0]

        # assign magnitude errors to DataFrame
        df.loc["2MASS_J", 'mag_error'] = two_mass["e_Jmag"][0]
        df.loc["2MASS_H", 'mag_error'] = two_mass["e_Hmag"][0]
        df.loc["2MASS_K", 'mag_error'] = two_mass["e_Kmag"][0]

        df = apply_flux(df)  # add physical fluxes to DataFrame
        df = apply_wave(df)  # add mean filter wavelengths to DataFrame
        df = mask_as_nan(df)  # replace nan values with np.nan
        df.dropna(subset=['mag'], inplace=True)  # drop rows without magnitude values

        return df


def get_allwise_mags(obj_name: str, radius: float = 10) -> pd.DataFrame:
    """
    Makes a Vizier query for an object in the AllWISE Source Catalog.

    Parameters
    ----------
    obj_name : str
        Simbad object name.
    radius : float
        search radius in arc-seconds.

    Returns
    -------
    pd.DataFrame(columns=['mag', 'mag_error', 'flux', 'wave'])
        DataFrame with filter names as index with Magnitudes, magnitude errors, physical flux calculated from
        magnitude and effective filter wavelength.
    """
    catalog = 'II/328/allwise'  # AllWISE (Cutri+ 2013)

    # Perform a query on the star and save data in query_object
    result = Vizier.query_object(obj_name, radius=radius * u.arcsec, catalog=[catalog])
    df = pd.DataFrame(columns=['mag', 'mag_error'])

    if len(result.keys()) == 0:
        print('No AllWISE data found for %s with the search radius r = %f arcsec!' % (obj_name, radius))
        return df

    all_wise = result[catalog]  # Extract ANS result from TableList
    all_wise = multi_row_exception(all_wise)  # Handle multiple measurements.

    if all_wise is None:
        return df

    else:
        # assign magnitudes to DataFrame
        df.loc["W1", 'mag'] = all_wise['W1mag'][0]
        df.loc["W2", 'mag'] = all_wise['W2mag'][0]
        df.loc["W3", 'mag'] = all_wise['W3mag'][0]
        df.loc["W4", 'mag'] = all_wise['W4mag'][0]

        # assign magnitude errors to DataFrame
        df.loc["W1", 'mag_error'] = all_wise['e_W1mag'][0]
        df.loc["W2", 'mag_error'] = all_wise['e_W2mag'][0]
        df.loc["W3", 'mag_error'] = all_wise['e_W3mag'][0]
        df.loc["W4", 'mag_error'] = all_wise['e_W4mag'][0]

        df = apply_flux(df)  # add physical fluxes to DataFrame
        df = apply_wave(df)  # add mean filter wavelengths to DataFrame
        df = mask_as_nan(df)  # replace nan values with np.nan
        df.dropna(subset=['mag'], inplace=True)  # drop rows without magnitude values

        return df


def get_wise_all_sky_mags(obj_name: str, radius: float = 10) -> pd.DataFrame:
    """
    Makes a Vizier query for an object in the WISE All-Sky Source Catalog.

    Parameters
    ----------
    obj_name : str
        Simbad object name.
    radius : float
        search radius in arc-seconds.

    Returns
    -------
    pd.DataFrame(columns=['mag', 'mag_error', 'flux', 'wave'])
        DataFrame with filter names as index with Magnitudes, magnitude errors, physical flux calculated from
        magnitude and effective filter wavelength.
    """
    catalog = 'II/311/wise'  # AllWISE (Cutri+ 2013)

    # Perform a query on the star and save data in query_object
    result = Vizier.query_object(obj_name, radius=radius * u.arcsec, catalog=[catalog])
    df = pd.DataFrame(columns=['mag', 'mag_error'])

    if len(result.keys()) == 0:
        print('No WISE All-sky data found for %s with the search radius r = %f arcsec!' % (obj_name, radius))
        return df

    wise_all_sky = result[catalog]  # Extract ANS result from TableList
    wise_all_sky = multi_row_exception(wise_all_sky)  # Handle multiple measurements.

    if wise_all_sky is None:
        return df

    else:
        # assign magnitudes to DataFrame
        df.loc["W1", 'mag'] = wise_all_sky['W1mag'][0]
        df.loc["W2", 'mag'] = wise_all_sky['W2mag'][0]
        df.loc["W3", 'mag'] = wise_all_sky['W3mag'][0]
        df.loc["W4", 'mag'] = wise_all_sky['W4mag'][0]

        # assign magnitude errors to DataFrame
        df.loc["W1", 'mag_error'] = wise_all_sky['e_W1mag'][0]
        df.loc["W2", 'mag_error'] = wise_all_sky['e_W2mag'][0]
        df.loc["W3", 'mag_error'] = wise_all_sky['e_W3mag'][0]
        df.loc["W4", 'mag_error'] = wise_all_sky['e_W4mag'][0]

        df = apply_flux(df)  # add physical fluxes to DataFrame
        df = apply_wave(df)  # add mean filter wavelengths to DataFrame
        df = mask_as_nan(df)  # replace nan values with np.nan
        df.dropna(subset=['mag'], inplace=True)  # drop rows without magnitude values

        return df


def get_wise_mags(obj_name: str, radius: float = 10) -> pd.DataFrame:
    """
    Query for one target!
    Makes a Vizier query for an object in the AllWISE Source Catalog and WISE All-Sky Source Catalog.
    If no targets are found in AllWISE, the WISE All-Sky Source Catalog is searched.

    Parameters
    ----------
    obj_name : str
        Simbad object name.
    radius : float
        search radius in arc-seconds.

    Returns
    -------
    pd.DataFrame(columns=['mag', 'mag_error', 'flux', 'wave'])
        DataFrame with filter names as index with Magnitudes, magnitude errors, physical flux calculated from
        magnitude and effective filter wavelength.
    """
    df = get_allwise_mags(obj_name, radius)
    if df.empty:
        print('No values found in AllWISE Source Catalog. Now searching in WISE All-Sky Source Catalog.')
        df = get_wise_all_sky_mags(obj_name, radius)

    return df


def sed_mags(obj_name: str, radius: float = 10, file_path=None) -> pd.DataFrame:
    """
    Makes a Vizier query for an object in the catalogs used for SED fitting.

    Surveys: ANS, SWIFT, Mermilliod, 2MASS, WISE (AllWISE, WISE All-Sky)

    Parameters
    ----------
    obj_name : str
        Simbad object name.
    radius : float
        search radius in arc-seconds.
    file_path: str or Path
        Specify a file path if you want to save the data directly to a xlsx file.

    Returns
    -------
    pd.DataFrame(columns=['mag', 'mag_error', 'flux', 'wave'])
        DataFrame with filter names as index with Magnitudes, magnitude errors, physical flux calculated from
        magnitude and effective filter wavelength.
    """

    df_ans = get_ans_mags(obj_name, radius)  # create DataFrame with ANS magnitudes
    df_swift = get_swift_mags(obj_name, radius)  # create DataFrame with SWIFT magnitudes
    df_mermilliod = get_mermilliod_mags(obj_name, radius)  # create DataFrame with Mermilliod magnitudes
    df_2mass = get_2mass_mags(obj_name, radius)  # create DataFrame with 2MASS magnitudes
    df_wise = get_wise_mags(obj_name, radius)  # create DataFrame with AllWISE magnitudes

    out_df = pd.concat([df_ans, df_swift, df_mermilliod, df_2mass, df_wise])  # concatenate DataFrame

    if file_path is not None:
        out_df.to_excel(file_path)

    return out_df  # return concatenated dataframe
