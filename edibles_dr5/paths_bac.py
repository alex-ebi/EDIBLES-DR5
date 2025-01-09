"""
Absolute paths_dir are defined in this module - import it if needed.
"""
from pathlib import Path

# Path to the EDR5 data
edr5_dir = Path('/home/alex/data/EDR5')

# Path to an optional directory where the extracted spectra are copied to
extracted_added_online = Path('/home/alex/diss_dibs/edibles_reduction/extracted_added_xfb')

# Path to EDPS directory
edps_dir = Path('/home/alex/PycharmProjects/edps')

esorex_path = Path('/home/alex/programs/esoreflex/install/bin/esorex')

recipe_dir = Path('/home/alex/programs/esoreflex/install/lib/esopipes-plugins/uves-6.4.6')
