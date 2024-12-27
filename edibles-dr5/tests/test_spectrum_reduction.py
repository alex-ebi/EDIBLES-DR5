from astro_scripts_uibk import spectrum_reduction
import numpy as np

spectrum = np.array([[1, 2, 3, 4, 5, 6, 7, 8, 9], [1, 1.01, 1.03, 3, 0.98, 1, 1.04, 1.02, 1.01], np.ones(9),
                     np.zeros(9)])


def test_crop_spectrum():
    expected = np.array([[3, 4, 5, 6, 7, 8], [1.03, 3, 0.98, 1, 1.04, 1.02], np.ones(6), np.zeros(6)])
    value = spectrum_reduction.crop_spectrum(spectrum, x_min=2.3, x_max=9)

    assert np.allclose(expected, value)


def test_exclude_spikes_limits():
    expected = np.array([[1, 2, 3, 5, 6, 7, 8, 9], [1, 1.01, 1.03, 0.98, 1, 1.04, 1.02, 1.01], np.ones(8),
                         np.zeros(8)])
    value = spectrum_reduction.exclude_spikes_limits(spectrum, flux_max=2)

    assert np.allclose(expected, value)


def test_filter_spikes_normalized():
    expected = np.array([[1, 2, 3, 5, 6, 7, 8, 9], [1, 1.01, 1.03, 0.98, 1, 1.04, 1.02, 1.01], np.ones(8),
                         np.zeros(8)])
    value = spectrum_reduction.filter_spikes_normalized(spectrum, threshold=0.05)

    assert np.allclose(expected, value)


def test_normalize_spectrum_linear():
    expected = np.array([[1, 2, 3, 4, 5, 6, 7, 8, 9], np.array([1, 1.01, 1.03, 3, 0.98, 1, 1.04, 1.02, 1.01]) * .5,
                         np.ones(9), np.zeros(9)])
    cont_1 = np.array([1, 2])
    cont_2 = np.array([9, 2])
    value = spectrum_reduction.normalize_spectrum_linear(spectrum, cont_1=cont_1, cont_2=cont_2)

    assert np.allclose(expected, value)


def test_smooth_spec():
    spec = np.array([np.arange(10), [-1, 1, -1, 1, -1, 1, -1, 1, -1, 1]])

    # Expected wavelengths are at .5 positions and expected flux is zero
    # Valid points are one less than the original array due to the kernel size of 2
    expected = np.array([np.arange(9) + 0.5, np.zeros(9)])
    value = spectrum_reduction.smooth_spec(spec, 2)

    assert np.allclose(expected, value)
