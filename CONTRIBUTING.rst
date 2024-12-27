============
Contributing
============

Contributions are welcome, and they are greatly appreciated! Every
little bit helps, and credit will always be given.

You can contribute in many ways:

Types of Contributions
----------------------

Report Bugs
~~~~~~~~~~~

Report bugs at https://git.uibk.ac.at/csap5791/astro_scripts_uibk/issues.

If you are reporting a bug, please include:

* Any details about your local setup that might be helpful in troubleshooting.
* Detailed steps to reproduce the bug.

Fix Bugs
~~~~~~~~

Look through the GitLab issues for bugs. Anything tagged with "bug"
is open to whoever wants to implement it.

Implement Features
~~~~~~~~~~~~~~~~~~

Look through the GitLab issues for features. Anything tagged with "feature"
is open to whoever wants to implement it.

Write Documentation
~~~~~~~~~~~~~~~~~~~

astro_scripts_uibk could always use more documentation, whether
as part of the official astro_scripts_uibk docs, in docstrings,
or even on the web in blog posts, articles, and such.

Submit Feedback
~~~~~~~~~~~~~~~

The best way to send feedback is to file an issue at https://git.uibk.ac.at/csap5791/astro_scripts_uibk/issues.

If you are proposing a feature:

* Explain in detail how it would work.
* Keep the scope as narrow as possible, to make it easier to implement.
* Remember that this is a volunteer-driven project, and that contributions
  are welcome :)

============
Rules for developing
============

* Rules can be still discussed, just a starting point.
* READ `Scientific Python Cookiecutter <https://nsls-ii.github.io/scientific-python-cookiecutter/philosophy.html>`_
  to get used to some rules for collaborative programming.
* Use numpy arrays as our standard data structure. It's basic, efficient and easy to understand.
* It's okay to use some classes - sometimes it's easier to use class-attributes or fields as function-parameters and
  incorporate the function as a method of the class.
  BUT you should always define the standalone function first (e.g. func(x,y,z)).
  Then you can use it as a method of the class (e.g. class Example: def func(x): return func(x, self.y, self.z)).
  This way, the function (func(x,y,z)) is still easy to implement somewhere else but can also be used as a method
  (Example.func(x)).
* For documentation we use "Sphinx", as our docstring format we use "NumPy".


Get Started!
------------

Ready to contribute? Here's how to set up `astro_scripts_uibk` for local development.

1. Fork the `astro_scripts_uibk` repo on GitLab.
2. Clone your fork locally::

    git clone https://git.uibk.ac.at/your_name_here/astro_scripts_uibk.git

3. Install your local copy into a virtualenv. Assuming you have virtualenvwrapper installed, this is how you set up your fork for local development::

    mkvirtualenv astro_scripts_uibk
    cd astro_scripts_uibk/
    python3 -m pip install -e .
    python3 -m pip install --upgrade -r requirements-dev.txt

4. Create a branch for local development::

    git checkout -b name-of-your-bugfix-or-feature

   Now you can make your changes locally.

5. When you're done making changes, check that your changes pass flake8 and the tests, including testing other Python versions with tox::

    flake8 astro_scripts_uibk
    coverage run -m pytest

   To get flake8, just pip install it into your virtualenv.

6. Commit your changes and push your branch to GitLab::

    git add .
    git commit -m "Your detailed description of your changes."
    git push origin name-of-your-bugfix-or-feature

   When pushing your commit, the tests are automatically run on gitlab.

7. Submit a pull request or merge request with master through the GitLab website.

Update the Wiki Documentation - Modules
-----------------------------

If you merge a new Master branch, you have to update the Wiki.
The Wiki includes a page named **Modules**.
This is a workaround for the normal **Pages**, which is not supported by git.uibk.ac.at.

Update the **Modules** page by building a Markdown Documentation::

    sphinx-build -M markdown docs/source docs/build

Then open the modules.md file::

    gedit docs/build/markdown/modules.md

Finally, copy all the text in Wikis **Modules** Page and commit the new documentation.
