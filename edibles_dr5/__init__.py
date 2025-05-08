from ._version import get_versions
from . import check_extraction_results
from . import cleanup_edps
from . import edr5_functions
from . import get_best_reductions
from . import get_observation_list
from . import io
from . import list_flats
from . import paths
from . import plot_formatchecks
from . import transformations

__version__ = get_versions()['version']
del get_versions

__all__ = ['check_extraction_results', 'cleanup_edps', 'edr5_functions', 'get_best_reductions', 'get_observation_list', 'io', 'list_flats', 'paths',
           'plot_formatchecks', 'transformations']
