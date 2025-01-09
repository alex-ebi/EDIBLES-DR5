import nbformat
from nbconvert.preprocessors import ExecutePreprocessor
from importlib.resources import files

notebook_filename = files('edibles_dr5')

with open(notebook_filename) as f:
    nb = nbformat.read(f, as_version=4)


ep = ExecutePreprocessor()

