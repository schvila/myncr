import os
import pkg_resources
from pkg_resources.extern.packaging.version import Version

from setuptools import setup, find_packages


# Utility function to read the README file.
# Used for the long_description.  It's nice, because now 1) we have a top level
# README file and 2) it's easier to type in the README file than to put a raw
# string in below ...
def read(file_name):
    curr_path = os.path.abspath(os.path.dirname(os.path.realpath(__file__)))
    return open(os.path.normpath(os.path.join(curr_path, file_name))).read()


class CfrRposVersion(Version):
    package_version = read('version').strip()

    def __init__(self, version):
        super().__init__(version)
        if Version(CfrRposVersion.package_version) == self:
            self._cfr_version = CfrRposVersion.package_version
        else:
            self._cfr_version = None

    def __str__(self):        
        return self._cfr_version if self._cfr_version is not None else super().__str__()


pkg_resources.extern.packaging.version.Version = CfrRposVersion


setup(
    name="cfrpos",
    version=CfrRposVersion.package_version,
    author="NCR Corp.",
    author_email="",
    description=("POS BDD API for POSEngine application and POS BDD simulators."),
    license="NCR Corp. Internal only. Not for public use.",
    keywords="library posengine",
    url="",
    packages=find_packages(),
    include_package_data=True,
    long_description=read('readme.txt'),
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Topic :: Utilities",
        "License :: NCR corp",
    ],
    install_requires=['behave', 'jsonpickle', 'requests', 'psutil', 'xmltodict', 'nose', 'flask', 'lxml', 'bs4', 'zeep', 'yattag', 'python-dateutil', 'jinja2', 'jmespath', 'jsonschema', 'pywinauto', 'pillow', 'pyyaml'],
)
