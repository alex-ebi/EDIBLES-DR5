from ._version import get_versions
from . import alignment
from . import convolve
from . import data_handling
from . import io_asu
from . import photometry
from . import pub_plot
from . import query
from . import spas
from . import spectrum_reduction
from . import stellar_modelling
from . import transformations
from . import widgets

__version__ = get_versions()['version']
del get_versions

__all__ = ['alignment', 'convolve', 'data_handling', 'io_asu', 'photometry', 'pub_plot', 'query', 'spas',
           'spectrum_reduction', 'stellar_modelling', 'transformations', 'widgets']
