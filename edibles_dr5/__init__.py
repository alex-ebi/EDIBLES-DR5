from ._version import get_versions
# from . import check_extraction_results
# from . import cleanup_edps
from . import edr5_functions
# from . import get_best_reductions
# from . import get_observation_list
from . import io
# from . import list_flats
from . import paths
# from . import plot_formatchecks
from . import transformations

__version__ = get_versions()['version']
del get_versions

__all__ = ['edr5_functions', 'io', 'paths', 'transformations']
