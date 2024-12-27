# astro_scripts_uibk

Pipeline
status: [![CircleCI](https://circleci.com/gh/alex-ebi/astro_scripts_uibk.svg?style=svg)](https://app.circleci.com/pipelines/github/alex-ebi/astro_scripts_uibk)

## Installation

### If you have not yet installed git enter in your terminal:

```console
sudo apt install git
```

### If you have not used git on your machine before:

```console
git config --global user.name "FirstName LastName"
git config --global user.email "FirstName.LastName@student.uibk.ac.at"
```

### After that:

```console
git clone https://github.com/alex-ebi/astro_scripts_uibk.git
python3 -m pip install -e ./astro_scripts_uibk
```

### Build Documentation:

```console
cd astro_scripts_uibk
python3 -m pip install --upgrade -r requirements-dev.txt
make -C docs html
firefox docs/build/html/index.html 
```

*(or use your favourite browser)*

# DIB alignment

The DIB alignment algorithm is in the module [alignment.py](astro_scripts_uibk/alignment.py).
A use example with real data is given in [alignment_full_example](examples/alignment_full_example.py).
For this example to run properly, it is important to install the repository with the flag '-e'.

## Publications

If you use this code for a publication, please cite our
paper [The EDIBLES Survey. VIII. Band profile alignment of diffuse interstellar bands](https://doi.org/10.1051/0004-6361/202348871).

## Bugs

I prepared the DIB alignment algorithm to be reusable. But if you find any bug, please create an issue!
Especially in the [alignment_full_example](examples/alignment_full_example.py).

## Development

I want to improve this algorithm and if you want to contribute, you are welcome to contact me.
