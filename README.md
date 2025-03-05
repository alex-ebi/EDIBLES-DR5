# EDIBLES data release 5

## Requirements
Before using this package, you need to install the esorex UVES pipeline and EDPS

## Install
For best practice, make a virtual environment for the package.

To install the package, run 

```console
python -m pip install -e .
```

## Paths
To define your system paths, copy the file **paths_bac.py** and rename the copy it to **paths.py** 

```console
cp paths_bac.py paths.py
```
Then, change the paths according to your data structure.

## Workflow
To run the full reduction workflow, run the file **workflow.ipynb** or **workflow.py**

**Note:** if you change the Notebook, you can convert it to a Python file using:
```console
jupyter nbconvert --to script workflow.ipynb
```