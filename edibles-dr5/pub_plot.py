from importlib.resources import files
import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib import font_manager

# Some strings for axis labels
wn_str = r'$\tilde \nu$(cm$^{-1}$)'
ang_str = r'$\lambda(\AA)$'


def pub_style_fig():
    """
    Set the matplotlib plot style for publication plots.
    Reads the style sheet in "config_files/pub_plot.mplstyle".
    Setup for one x axis - unit and one y axis unit.
    E.g. if you want to use a second x axis on top, use:

    import astro_scripts_uibk as asu
    import matplotlib as mpl

    mpl.rcParams['xtick.top'] = False
    f, ax = plt.subplots()
    sec_ax = ax.secondary_xaxis('top', functions=(asu.transformations.wavenumber_to_angstrom,
                                                  asu.transformations.angstrom_to_wavenumber))

    Returns
    -------
    None
    """
    # filename of matplotlib style sheet
    style_path = files("astro_scripts_uibk") / "config_files/pub_plot.mplstyle"

    # path of font file
    font_path = files("astro_scripts_uibk") / "config_files/NimbusRomNo9L-Reg.otf"

    # add font to matplotlib
    font_manager.fontManager.addfont(font_path)
    plt.style.use(style_path)  # load style sheet


def pub_ticks(_ax, xticks=None, yticks=None):
    """
    Set major tick separation. Minor ticks will have a fifth of the major separation.

    Parameters
    ----------
    _ax : matplotlib.axes._axes.Axes
        Axis of modified ticks.
    xticks : float
        x tick separation
    yticks : float
        x tick separation

    Returns
    -------
    None
    """
    if xticks is not None:
        _ax.xaxis.set_major_locator(mpl.ticker.MultipleLocator(xticks))
        _ax.xaxis.set_minor_locator(mpl.ticker.MultipleLocator(xticks / 5))
    if yticks is not None:
        _ax.yaxis.set_major_locator(mpl.ticker.MultipleLocator(yticks))
        _ax.yaxis.set_minor_locator(mpl.ticker.MultipleLocator(yticks / 5))


def dark_style_fig():
    """
    Cooler black background plot style.
    Set the matplotlib plot style for publication plots.
    Reads the style sheet in "config_files/dark_plot.mplstyle".
    Setup for one x axis - unit and one y axis unit.
    E.g. if you want to use a second x axis on top, use:

    mpl.rcParams['xtick.top'] = False

    f, ax = plt.subplots()

    sec_ax = ax.secondary_xaxis('top', functions=(rv_to_wavenumber, wavenumber_to_rv))

    Returns
    -------
    None
    """
    # filename of matplotlib style sheet
    style_path = files("astro_scripts_uibk") / "config_files/dark_plot.mplstyle"
    plt.style.use(style_path)  # load dark style sheet
