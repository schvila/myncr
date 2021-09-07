import sys
import os
from pathlib import Path, PurePath
import importlib
from typing import Tuple
import unittest
import yaml
import argparse
import logging

CONFIGURATION_FILE = 'config/unit_tests.yaml'


def set_parser():
    """Prepares the argument parser and parses the arguments
    :return: Parsed arguments and list of unknown arguments
    """
    parser = argparse.ArgumentParser(description='Run BDD unit tests.')
    parser.add_argument('-r', '--repeats', type=int, default=1, help='Run all unit tests REPEATS times')
    return parser.parse_known_args()


def join_paths(*paths) -> str:
    """Helper function for joining multiple string system paths
    :return: One string system path
    """
    return str(PurePath(*paths))


def format_list(list_to_format: list) -> str:
    """Helper function, creates pretty formatted string from list
    :param list_to_format: List to be formatted
    :return: Pretty string to print
    """
    result = ''
    for element in list_to_format:
        result += '\n\t- ' + str(element)
    return result


def get_paths() -> Tuple[str, str]:
    """Get paths needed for running the unit tests
    :return: Absolute path to the repository and to the script folder
    """
    path = PurePath(os.path.abspath(os.path.realpath(__file__)))

    if len(path.parts) < 5 or path.parts[-5] != '6.1':
        raise Exception("Unexpected script location: " + str(path) + ". Expected: ...\\6.1\\POS\\BDD\\Pos\\run_unit_tests.py")

    path_script = str(path.parent)
    path_repository = str(path.parents[4])

    logging.info('Detected repository path: ' + path_repository)
    return path_repository, path_script


def load_configuration(path: str) -> dict:
    """Loads configuration with unit tests
    :param path: Path to configuration file
    :return: Dictionary with the configuration
    """
    configuration = {}
    with open(path) as config_file:
        configuration = yaml.load(config_file, Loader=yaml.FullLoader)
    return configuration


def extend_system_path(base_path: str, paths: list) -> list:
    """Temporarily extends system path, needed for module importing
    :param base_path: Path to the code repository
    :param paths: List with string paths to folders with unit test modules
    :return: List of strings with absolute paths
    """
    absolute_paths = [join_paths(base_path, path) for path in paths]
    logging.info('Extending system path with:' + format_list(absolute_paths))
    sys.path.extend(absolute_paths)
    return absolute_paths


def get_modules(paths: list, include: list, exclude: list) -> list:
    """ Collect modules from the given paths. 
    :param paths: Paths to search the modules in
    :param include: Pattern or file names to include
    :param exclude: File names to exclude
    :return: List of string with module names
    """
    modules = set()
    for path in paths:
        for pattern in include:
            for file in Path(path).glob(pattern):
                if file.is_file() and file.name not in exclude:
                    modules.add(file.stem)

    return sorted(modules)


def import_modules(modules: list):
    """Import all definitions and statements (=symbols) for given modules
    :param modules: List of module names
    """
    logging.info('Importing modules:' + format_list(modules))
    module_imports = {}
    module_symbols = set()
    for module_name in modules:
        module = importlib.import_module(module_name)
        symbols = [name for name in module.__dict__ if not name.startswith('_')]
        module_imports = dict(module_imports, **module.__dict__)
        module_symbols.update(symbols)

    logging.info('Importing symbols from modules:' + format_list(sorted(module_symbols)))
    globals().update({name: module_imports[name] for name in module_symbols})


# Save the result of tests to global variable
# Unfortunately we can not get the results from unittest.main() directly
global_result = 0


class MyResult(unittest.TextTestResult):
    def setGlobalError(self):
        global global_result
        global_result = -1

    def addError(self, test, err):
        self.setGlobalError()
        super().addError(test, err)

    def addFailure(self, test, err):
        self.setGlobalError()
        super().addFailure(test, err)


class MyRunner(unittest.TextTestRunner):
    resultclass = MyResult


if __name__ == '__main__':
    logging.basicConfig(format='%(levelname)s: %(message)s', level=logging.INFO)
    args, args_unknown = set_parser()

    path_repository, path_script = get_paths()
    config = load_configuration(join_paths(path_script, CONFIGURATION_FILE))
    paths = extend_system_path(path_repository, config['paths'])
    modules = get_modules(paths, config['include'], config['exclude'])
    import_modules(modules)

    for x in range(args.repeats):
        logging.info(f'Running loaded unit tests ({x}).')
        unittest.main(verbosity=2, testRunner=MyRunner, exit=False, argv=[sys.argv[0], *args_unknown])
    logging.info('Finished.')

    sys.exit(global_result)