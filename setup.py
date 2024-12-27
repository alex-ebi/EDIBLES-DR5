from os import path
from setuptools import setup, find_packages
import sys
import versioneer

# NOTE: This file must remain Python 2 compatible for the foreseeable future,
# to ensure that we error out properly for people with outdated setuptools
# and/or pip.
min_version = (3, 10)
sys_version = sys.version_info[:2]
if sys.version_info < min_version:
    error = f"""
astro_scripts_uibk does not support Python {sys_version[0]}.{sys_version[1]}.
Python {min_version[0]}.{min_version[1]} and above is required. Check your Python version like so:

python3 -V

This may be due to an out-of-date pip. Make sure you have pip >= 9.0.1.
Upgrade pip like so:

pip install --upgrade pip
"""
    sys.exit(error)

here = path.abspath(path.dirname(__file__))

with open(path.join(here, 'README.md'), encoding='utf-8') as readme_file:
    readme = readme_file.read()

with open(path.join(here, 'requirements.txt')) as requirements_file:
    # Parse requirements.txt, ignoring any commented-out lines.
    requirements = [line for line in requirements_file.read().splitlines()
                    if not line.startswith('#')]

setup(
    name='EDIBLES-DR5',
    version=0.1,
    cmdclass=versioneer.get_cmdclass(),
    description="Repository of the EDIBLES data release 5.",
    long_description=readme,
    author="Alexander Ebenbichler",
    author_email='alexander@ebenbichler.net',
    url='https://github.com/alex-ebi/EDIBLES-DR5',
    python_requires='>={}'.format('.'.join(str(n) for n in min_version)),
    packages=find_packages(exclude=['docs', 'tests']),
    entry_points={
        'console_scripts': [
            # 'command = some.module:some_function',
        ],
    },
    include_package_data=True,
    package_data={
        'edibles-dr5': [
            # When adding files here, remember to update MANIFEST.in as well,
            # or else they will not be included in the distribution on PyPI!
            # 'test_data/*',
            # 'config_files/*',
            # 'filter_profiles/*',
            # 'example_data/*'
        ]
    },
    install_requires=requirements,
    license="BSD (3-clause)",
    classifiers=[
        'Development Status :: Beta',
        'Natural Language :: English',
        'Programming Language :: Python :: 3',
    ],
)
