from importlib.resources import files
from astro_scripts_uibk import photometry
from astro_scripts_uibk import io_asu


def test():
    atmosphere_file = files("astro_scripts_uibk") / "test_data/sun_struct"
    sed_x, sed_y = io_asu.read_atlas9_flux(atmosphere_file)

    bol = photometry.BOL(sed_x, sed_y) + photometry.solar_magnitude_correction
    # u = photometry.filter_dictionary["U"].mag(
    #     sed_x, sed_y) + photometry.solar_magnitude_correction
    # b = photometry.filter_dictionary["B"].mag(
    #     sed_x, sed_y) + photometry.solar_magnitude_correction
    v = photometry.filter_dictionary["V"].mag(
        sed_x, sed_y) + photometry.solar_magnitude_correction
    # print("Sun:")
    # print("Mbol = {:.2f}mag".format(bol))
    # print("U = {:.2f}mag".format(u))
    # print("B = {:.2f}mag".format(b))
    # print("V = {:.2f}mag".format(v))
    # print("BC = Mbol-V = {:.3f}mag".format(photometry.BC(sed_x, sed_y)))

    assert "{:.2f}".format(bol) == "4.74"
    assert "{:.2f}".format(v) == "4.81"
