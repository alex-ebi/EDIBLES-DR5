import numpy as np
from astro_scripts_uibk import query
from importlib.resources import files
import pandas as pd


def test_sed_mags():
    # test for hd 183143
    mag_path = files("astro_scripts_uibk") / "test_data/hd183143.xlsx"
    expected = np.array(pd.read_excel(mag_path, index_col=[0])['mag'], dtype=float)

    actual = np.array(query.sed_mags('hd183143')['mag'], dtype=float)

    assert np.allclose(actual, expected)
