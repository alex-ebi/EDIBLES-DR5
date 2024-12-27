from astro_scripts_uibk import convolve
import numpy as np

wave_array = np.array([1, 2, 3, 4, 5, 6])


def test_find_nearest_index():
    value = 3.3
    expected = 2

    actual = convolve.find_nearest_index(wave_array, value)

    assert actual == expected


def test_find_nearest_value():
    value = 3.6
    expected = 4.

    actual = convolve.find_nearest_value(wave_array, value)

    assert actual == expected


def test_get_lower_interval_index():
    value = 3.6
    expected = 2

    actual = convolve.get_lower_interval_index(wave_array, value)

    assert actual == expected


def test_wave_to_bin():
    value = np.array([1, 2, 3, 4, 5, 6, 6.2])
    expected = np.array([0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.1, 6.3])

    actual = convolve.wave_to_bin(value)

    assert np.allclose(expected, actual)


def test_rebin_plot():
    model_wave = np.linspace(start=-5, stop=15, num=30000)
    model_flux = np.linspace(start=-2, stop=2, num=30000)
    model_spec = np.array([model_wave, model_flux])
    obs_wave = np.linspace(start=0, stop=10, num=11)[1:-1]
    expected = np.linspace(start=-1, stop=1, num=11)[1:-1]

    model_spec_rebinned = convolve.rebin_plot(obs_wave=obs_wave, model_spec=model_spec)
    actual = model_spec_rebinned[1]

    assert np.allclose(actual, expected, atol=.00034)


def test_resample():
    obs_wave = np.linspace(start=0, stop=10, num=11)
    obs_flux = np.linspace(start=-1, stop=1, num=11)
    obs_spec = np.array([obs_wave, obs_flux])

    model_wave = np.linspace(start=0, stop=10, num=101)[1:-1]
    expected = np.linspace(start=-1, stop=1, num=101)[1:-1]

    obs_spec_resampled = convolve.resample(obs_spec, model_wave)

    actual = obs_spec_resampled[1]

    assert np.allclose(actual, expected)
