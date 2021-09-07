BDD for CFR POS
===============

This file contains a complete guide to install and setup environment to run BDD scripts.

There are two ways of working with BDD tests and both are supported by the "one click setup" guide:

- Running BDD tests **from build drop folder** ideally copied to a blank VM (no RPOS or other products installed), useful for QA not used to working with source control. This is called ``Deployed build`` configuration (in ``one_click_setup.py`` guide). It will install the cfrpos python package, deploy needed binaries and configuration files and finally extract and run the BDD tests.
- Executing BDD tests directly **from source control directory**. This is called ``Dev-Env`` configuration (in ``one_click_setup.py`` guide). This is recommended to both develop and run BDD tests.

Installation steps
------------------
First, install python (see below) and then follow the "one click setup" guide to prepare the rest.

Install python
``````````````
1. Install 32bit version of python 3.5+, ensure you check the "Add PYTHON to PATH" checkbox during installation.

2. Install Python for Windows extension package (pywin32). You must use the msi package provided on the project page, because the pip package is not compatible with python 3.5+ (5.1.2017). Download from https://sourceforge.net/projects/pywin32/files/. See troubleshooting section for some assistance in case of problems.

One click setup
```````````````
It is required to run this script as administrator.

The script will fully prepare your environment to run BDD. It will guide you through the process of setup and prompt you with several questions in order to allow customization, nevertheless feel free to rely on default values.

The script will check system readiness (prerequisites), deploy configuration and media files, guide you through configuration, in "Deployed build" setup it will install CFRPOS package automatically to python package repository and extracts the bdd scripts to ``<drop folder directory>\_BDD\bddtests``. Lastly, it will ask you to run the actual BDD scripts.

The script will save your answers on the prompts and will allow you to choose to use this saved configuration in ongoing runs of the script.

Additional setup
````````````````
Most of the configuration is prepared during execution of the One click setup and dumped into the json files listed below. Additionally, it can be edited manually but the recommendation is to run one click at least for the first time to set the initial values:

- ``<bdd_root>/config.user.json``

- ``<bdd_root>/config/logging.json``


Execute BDD tests
-----------------

The one_click_setup.py may run the BDD tests for you (it will prompt you). Nevertheless, you can run them manually:

1. Open command prompt and set the current directory to ``<bdd_root>``.

2. Run scripts using behave (you must supply ``config.user.json`` as the parameter, other optional tags are ``-i`` to specify a feature file to be run):
   ``behave -D bdd_config=config.user.json``


Configure project in PyCharm
----------------------------
When working with PyCharm one must open the project from a particular folder depending on your working scheme:

- When cfrpos python package was installed (deployed build):
    - Open project from the BDDtests directory

- When using source control (dev-env)
    - It is recommended to setup your TFS workspace as local (not server) in order to get rid of the readonly flag on files.
    - Open project from the ``$/PCS_RPOS_Version_6/Releases/06_12_C1/6.1/POS/BDD`` directory
    - Add BDD/Pos/cfrpos directory to the Source folders. (Settings/Project BDD/Project structure). This is important
      only for the 'intellisense' to find cfrpos package even though it is available to the python so it can be executed
      without issues

Execute/Debug tests from Pycharm
````````````````````````````````
To execute or debug tests directly from PyCharm one must setup a new execution configuration:

1. Go to Run/Edit configurations
2. On the tree view navigate to Python Tests and click +
3. Pick a name for your configuration (e.g. BDD)
4. Set target to BDDtests directory
5. Set working directory to BDDtests directory
6. (optional) Configure additional py test arguments using the Options field.
   (e.g. --html=.reports\report.html --junitxml=.reports\report.xml --json=.reports\reports.json)
7. Hit OK.
8. Select your configuration in the upper right corner and click execute or debug icons on the right.
   Or click Run/Run BDD or Run/Debug BDD if you have chosen the BDD name for your configuration.


Troubleshooting
---------------

- The "pip install" failed: If you have installed python for all users, then the pip requires admin rights.

- Some processes need to run as administrator to correctly operate (TeleQ). You may want to run one_click_setup as administrator.

- There may be insufficient access rights to the program files folder. Make sure a directory 'C:\Program files\Radiant\' (including all sub-directories) has read-write access for you.

- The pywin32 may complain that it cannot find the python installation. Ensure that you have installed 32bit version of python (just execute python.exe)
  and that you have attempted to install the 32 bit version of pywin32. If you think that is correct and the pywin32 installation still complains, then manually add the following registry:
  ``HKEY_LOCAL_MACHINE/SOFTWARE/Wow6432Node/Python/PythonCore/[version]/InstallPath`` and set value to your python installation (e.g. C:/Python37-32). Substitute the [version] part with your python version (e.g. 3.5, 3.6 ...)

- No module named 'cfrpos': install the cfrpos package, note that it may require admin rights.

- Python execution troubles:
    - Ensure the parent directory of bddtests contain neither __init__ nor conftest.py.

- POS is not responding to the script:
    - Use web browser to verify that POSBDD server is available:
      http://localhost:10000/v1/posengine/state
      If the response is not HTTP code 200 or 500, ensure that POSBDD.dll is in dll.dat relay file (on some machines you must edit the relay file as admin).
      And restart POSEngine manually.


Optional
--------
consider using TeleView.exe to inspect radram files