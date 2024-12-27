from astro_scripts_uibk import transformations
import numpy as np

c_light = 299792.458  # speed of light in km/s

angstrom_list = np.array([10999, 11000, 11001, 11002])
wavenumber_list = np.array([9091.735612328, 9090.909090909, 9090.082719753, 9089.256498818])
ref_wavelength = 11000
ref_wavenumber = 9090.909090909

# calculated from angstrom_list, non relativistic approximation
rv_list = np.array([-27.25385, 0, 27.25385, 54.50771])


def test_angstrom_to_wavenumber():
    value = transformations.angstrom_to_wavenumber(angstrom_list, air_to_vac=False)

    assert np.allclose(value, wavenumber_list)


def test_wavenumber_to_angstrom():
    value = transformations.wavenumber_to_angstrom(wavenumber_list, vac_to_air=False)

    assert np.allclose(value, angstrom_list)


def test_wavenumber_to_rv():
    value = transformations.wavenumber_to_rv(wavenumber_list, ref_wavenumber=ref_wavenumber)

    assert np.allclose(value, rv_list, rtol=1.e-4)  # tolerance reduced due to non-relativistic expected value


def test_rv_to_wavenumber():
    value = transformations.rv_to_wavenumber(rv_list, ref_wavenumber=ref_wavenumber)

    assert np.allclose(value, wavenumber_list)


def test_wavelength_to_rv():
    value = transformations.wavelength_to_rv(angstrom_list, ref_wavelength=ref_wavelength)

    assert np.allclose(value, rv_list, rtol=1.e-4)  # tolerance reduced due to non-relativistic expected value


def test_rv_to_wavelength():
    value = transformations.rv_to_wavelength(rv_list, ref_wavelength=ref_wavelength)

    assert np.allclose(value, angstrom_list)


def test_doppler_wavelength_reverse():
    tmp = transformations.rv_to_wavelength(rv_list, ref_wavelength=ref_wavelength)
    value = transformations.wavelength_to_rv(tmp, ref_wavelength=ref_wavelength)

    assert np.allclose(rv_list, value)


def test_doppler_wavenumber_reverse():
    tmp = transformations.rv_to_wavenumber(rv_list, ref_wavenumber=ref_wavenumber)
    value = transformations.wavenumber_to_rv(tmp, ref_wavenumber=ref_wavenumber)

    assert np.allclose(rv_list, value)


def test_bary_corr():
    obs_loc = 'paranal'
    obs_time = 55932.29083402
    star_name = 'HD183143'

    # barycentric correction velocity from https://astroutils.astronomy.osu.edu/exofast/barycorr.html
    rv_bary = -4.728775

    expected = angstrom_list * (1 + rv_bary / c_light)

    actual = transformations.bary_corr(wavelength=angstrom_list, obs_name=obs_loc, obs_time=obs_time,
                                       star_name=star_name, time_format='mjd')

    assert np.allclose(actual, expected)


def test_air_vac_air():
    air_expected = angstrom_list

    vac = transformations.angstrom_air_to_vac(air_expected)

    air_actual = transformations.angstrom_vac_to_air(vac)

    assert np.allclose(air_expected, air_actual)


def test_mag_to_flux():
    # physical flux density of Vega
    flux_v_vega_expected = 3.63e-9
    # Vega magnitude in V filter - zero by definition
    m_vega = 0

    flux_v_vega_actual = transformations.mag_to_flux('V', m_vega)

    assert np.allclose(flux_v_vega_actual, flux_v_vega_expected)
