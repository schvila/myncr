import sys
import json
import os
import winreg
import ipaddress
import importlib
import xml.etree.ElementTree as ET
import stat
import shutil
import subprocess
import glob
import platform
import tempfile
import argparse

from urllib.request import urlopen, Request
from urllib.error import URLError
from importlib import util
import pkg_resources


PRESERVE_RADIANT_FOLDER_ON_X64 = False
AUTO_SCRIPT = False


def parse_input_args(default_config: str) -> argparse.Namespace:
    """Parse the input arguments using the argparse module

    :param default_config: Path to default JSON configuration
    :return: Parsed arguments
    """
    parser = argparse.ArgumentParser()
    parser.add_argument('-a', '--auto',
                        help="runs the script without user input using the configuration one_click_setup.json file", 
                        action="store_true")
    parser.add_argument('-i', '--install',
                        help="check and install required packages ",
                        action="store_true")
    parser.add_argument('-c', '--configuration',
                        help='path to the configuration file, defaults to one_click_setup.json in the folder with this script', 
                        nargs='?',
                        default=default_config)
    return parser.parse_args()


def print_success(text='ok'):
    if 'colorama' in sys.modules:
        print(colorama.Fore.GREEN + text + colorama.Style.RESET_ALL)
    else:
        print(text)
    print()


def print_warning(text='WARNING'):
    if 'colorama' in sys.modules:
        print(colorama.Fore.YELLOW + colorama.Style.BRIGHT + text + colorama.Style.RESET_ALL, file=sys.stderr)
    else:
        print(text, file=sys.stderr)
    print()


def print_failure(text='FAILED'):
    if 'colorama' in sys.modules:
        print(colorama.Fore.RED + colorama.Style.BRIGHT + text + colorama.Style.RESET_ALL, file=sys.stderr)
    else:
        print(text, file=sys.stderr)
    print()


def print_message(text):
    if 'colorama' in sys.modules:
        print(colorama.Fore.CYAN + text + colorama.Style.RESET_ALL)
    else:
        print(text)


def prompt_user(text, default_value, validity_check):
    question = '{0} [{1}]: '.format(text, default_value)
    # Commented out due to bug in Python 3.5+, colorama does not work inside input. This need to placed in the
    # colorama if.
    # question = colorama.Fore.LIGHTMAGENTA_EX + '{0} '.format(text) + \
    #           colorama.Fore.LIGHTBLUE_EX + '[{0}]'.format(default_value) + \
    #           colorama.Fore.LIGHTMAGENTA_EX + ': ' + \
    #           colorama.Style.RESET_ALL
    while True:
        value = input(question).strip()
        if value == '':
            value = default_value
        if validity_check is None or validity_check(value):
            print()
            return value
        else:
            print_failure('ERROR: Input not valid.')


def prompt_user_bool(text, default_value):
    if default_value is True or default_value in ['y', 'Y']:
        yes_no_default = 'y'
    elif default_value is False or default_value in ['n', 'N']:
        yes_no_default = 'n'
    else:
        raise Exception('ERROR: Unexpected input in default_value: [{}].'.format(default_value))
    return 'y' == prompt_user(text, yes_no_default, check_yes_no).lower()


def install_python_package(package_name, package=None, always_install=False, version=None):
    installed = False
    if package is None:
        package = package_name

    if not always_install:
        print_message('Checking availability of package [{}].'.format(package_name))
        pkg = None
        try:
            pkg = pkg_resources.get_distribution(package_name)
        except pkg_resources.DistributionNotFound:
            pkg = None
        if pkg is not None:
            installed = True
            if version is not None and pkg_resources.get_distribution(package_name).version != version:
                installed = False
        else:
            print_warning('Package [{}] not found.'.format(package_name))

    if not installed:
        print_message('Installing package [{}]...'.format(package_name))
        if version is not None:
            package += '==' + version
        try:
            subprocess.check_call([sys.executable, '-m', 'pip', 'install', package])
            importlib.invalidate_caches()
        except ValueError:
            print_failure('ERROR: Failed to install [{}] package using pip install.'.format(package_name))
            return False

    # Verify package installed successfully
    if pkg_resources.get_distribution is None:
        print_failure('Package [{}] not installed.'.format(package_name))
        return False

    print_success()
    return True


def check_dotnet_version():
    print_message('Checking installed version of Microsoft .NET Framework.')
    try:
        with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r'SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full') as subkey:
            pack_version = winreg.QueryValueEx(subkey, 'Release')[0]
            if pack_version <= 379893:
                print_failure('ERROR: Please install .NET 4.5.2 or higher.')
                print('Offline installer of .NET 4.5.2 is here: '
                      'https://www.microsoft.com/en-us/download/details.aspx?id=42642')
                return False
            else:
                print_success()
                return True
    except WindowsError as error:
        # ERROR_FILE_NOT_FOUND in this case means that the registry key does not exist
        if error.errno == 2:
            print_failure('ERROR: Please install .NET 4.5.2 or higher.')
            print('Offline installer of .NET 4.5.2 is here: '
                  'https://www.microsoft.com/en-us/download/details.aspx?id=42642')
            return False
        else:
            raise


def check_nodejs_version():
    print_message('Checking installed version of Node.js.')
    try:
        with winreg.OpenKeyEx(winreg.HKEY_LOCAL_MACHINE, r'SOFTWARE\Node.js', 0, winreg.KEY_READ | winreg.KEY_WOW64_64KEY) as subkey:
            version_string = winreg.QueryValueEx(subkey, 'Version')[0]
            version = version_string.split('.')
            if len(version) < 3:
                print_failure('ERROR: Invalid Node.js version string \'' + version_string + '\'! Expected XX.XX.XX')
                print('Please install Node.js 10.13 or higher from: '
                      'https://nodejs.org/en/')
                return False
            else:
                major = int(version[0])
                minor = int(version[1])
                if major < 10 or (major == 10 and minor < 13):
                    print_failure('ERROR: Please install Node.js 10.13 or higher.')
                    print('Please install Node.js 10.13 or higher from: '
                          'https://nodejs.org/en/')
                    return False
                else:
                    print_success()
                    return True
    except WindowsError as error:
        # ERROR_FILE_NOT_FOUND in this case means that the registry key does not exist
        if error.errno == 2:
            print_failure('ERROR: Please install Node.js 10.13 or higher.')
            print('Please install Node.js 10.13 or higher from: '
                  'https://nodejs.org/en/')
            return False
        else:
            raise


def copy_replace(src, tgt):
    if os.path.exists(tgt):
        os.chmod(tgt, stat.S_IWRITE | stat.S_IREAD)
        os.remove(tgt)
    shutil.copy(src, tgt)
    os.chmod(tgt, stat.S_IWRITE | stat.S_IREAD)


def copy_replace_file(src_dir, tgt_dir, filename):
    copy_replace(os.path.join(src_dir, filename), os.path.join(tgt_dir, filename))


def copy_replace_dir(src_dir, tgt_dir):
    if not os.path.exists(tgt_dir):
        os.mkdir(tgt_dir)
    for file_name in os.listdir(src_dir):
        path_name = os.path.join(src_dir, file_name)
        if os.path.isfile(path_name):
            copy_replace_file(src_dir, tgt_dir, file_name)
        elif os.path.isdir(path_name):
            copy_replace_dir(path_name, os.path.join(tgt_dir, file_name))


def check_is_dir(value):
    if os.path.isdir(value):
        return True
    else:
        print_failure('ERROR: Directory [{}] not found.'.format(value))
        return False


def check_build_configuration(value: str) -> bool:
    result = False
    if isinstance(value, str):
        if value.lower() == "debug" or value.lower() == "release":
            result = True
    return result


def check_make_dir(value):
    if not os.path.isabs(value):
        print_failure('ERROR: Path [{}] is not an absolute path.'.format(value))
        return False

    if 'program files' in value.lower() and 'radiant' in value.lower():
        if not check_make_radiant_folder():
            return False

    if os.path.isdir(value):
        return True
    else:
        try:
            os.makedirs(value)
            return True
        except OSError as e:
            print_failure('ERROR: Directory [{}] cannot be created ({}).'.format(value, e))
            return False


def check_make_radiant_folder():
    global PRESERVE_RADIANT_FOLDER_ON_X64
    path_dir = os.path.abspath('c:\\Program Files\\Radiant')
    if platform.machine() == 'AMD64':
        path_link = path_dir
        path_dir = os.path.abspath('c:\\Program Files (x86)\\Radiant')

        if os.path.isdir(path_link) and not os.path.islink(path_link):
            if PRESERVE_RADIANT_FOLDER_ON_X64:
                print_message("Folder structure seems to be ok...")
                print_success()
                return True
            print_warning("On 64-bit OS the [Program Files\\Radiant] folder should be a symlink to "
                          "[Program Files (x86)\\Radiant] folder. On this system it is a folder.")
            path_backup = path_link + "_backup"
            answer = prompt_user_bool("Do you want to backup and then delete [{}] folder? This will delete the "
                                      "previous backup folder [{}] if exists. y/n".format(path_link, path_backup), "y")
            if answer:
                print_message("Moving [{}] folder to [{}] folder...".format(path_link, path_backup))
                try:
                    if os.path.isdir(path_backup):
                        shutil.rmtree(path_backup, ignore_errors=True)
                    shutil.move(path_link, path_backup)
                    print_success()
                except OSError as e:
                    print_failure("ERROR: Could not move folder [{}] to [{}] folder because of error [{}]...".format(
                        path_link, path_backup, e))
            else:
                print_warning("Preserving actual folder structure...")
                PRESERVE_RADIANT_FOLDER_ON_X64 = True
                return True

        if os.path.islink(path_link) and os.path.isdir(path_dir):
            return True
        else:
            try:
                if not os.path.isdir(path_dir):
                    print_message("Creating dir [{}]...".format(path_dir))
                    os.makedirs(path_dir)
                    print_success()
                if not os.path.islink(path_link):
                    print_message("Creating dir symlink [{}] pointing to [{}]".format(path_link, path_dir))
                    os.symlink(path_dir, path_link)
                    print_success()
                return True
            except PermissionError:
                print_failure("ERROR: Access denied to create [{}] folder! "
                              "Run the script as administrator!".format(path_dir))
                return False
            except OSError as e:
                print_failure('ERROR: Directory [{}] cannot be created ({}).'.format(path_dir, e))
                return False
    else:
        if os.path.isdir(path_dir):
            return True
        else:
            try:
                os.makedirs(path_dir)
                return True
            except OSError as e:
                print_failure('ERROR: Directory [{}] cannot be created ({}).'.format(path_dir, e))
                return False


def check_dir_for_access(value):
    if check_is_dir(value):
        try:
            os.chmod(value, stat.S_IWRITE | stat.S_IREAD)
            return True
        except Exception as e:
            print_failure('ERROR: Directory [{}] cannot be accessed for reading and writing ({}).'.format(value, e))
    else:
        print_failure('ERROR: Directory [{}] not found.'.format(value))
    return False


def check_make_dir_with_access(value):
    if not check_make_dir(value) or not check_dir_for_access(value):
        print_failure('ERROR: Folder {} does not exist or cannot be written to.'.format(value))
        return False
    else:
        return True


def check_yes_no(value):
    return value.lower() in ['y', 'n']


def check_is_node_number(value):
    try:
        value = int(value)
        return 0 < value < 255
    except ValueError:
        print_failure('ERROR: [{}] is not a valid node number.'.format(value))
        return False


def check_is_port(value):
    try:
        value = int(value)
        return 0 < value < 65535
    except ValueError:
        print_failure('ERROR: [{}] is not a valid port number.'.format(value))
        return False


def check_is_ip(value):
    try:
        ipaddress.IPv4Address(str(value))
        return True
    except ValueError:
        print_failure('ERROR: [{}] is not an IPv4 IP.'.format(value))
        return False


def check_valid_width(value):
    try:
        value = int(value)
        return value in [800, 1024, 1280, 1366, 1920]
    except ValueError:
        print_failure('ERROR: [{}] is not an valid width.'.format(value))
        return False


def move_dir(src, tgt):
    if os.path.islink(tgt):
        os.unlink(tgt)
    if os.path.isdir(tgt):
        shutil.rmtree(tgt)
    os.makedirs(tgt)
    os.rmdir(tgt)
    shutil.move(src, tgt)


def find_process(process_name):
    process_name = process_name.upper()
    for process in psutil.process_iter():
        try:
            if process.name().upper() == process_name:
                return process
        except psutil.NoSuchProcess:
            pass
    return None


def find_package(directory, prefix, build=None):
    files = glob.glob(os.path.join(directory, '{}{}.zip'.format(prefix, '*' if build is None else build)))
    if len(files) == 0:
        return None, None
    else:
        package_file = sorted(files)[len(files) - 1]
        build = package_file[package_file.rfind(prefix) + len(prefix):len(package_file) - 4]
        return package_file, build


def install_prerequisites():
    """ Pre-check prerequisites: .Net Framework Version
    """
    if not check_dotnet_version():
        raise Exception('Check that minimal version of .NET Framework is .NET 4.5.2.')

    """ Pre-check prerequisites: Node.js version
    """
    if not check_nodejs_version():
        raise Exception('Check that minimal version of Node.js is 10.13.')

    """ Pre-check prerequisites: Install python packages if needed
    """
    install_python_package('colorama')
    install_python_package('behave')
    install_python_package('jsonpickle')
    install_python_package('nose')
    install_python_package('psutil', version='5.6.3')
    install_python_package('requests')
    install_python_package('flask')
    install_python_package('lxml')
    install_python_package('zeep')
    install_python_package('bs4')
    install_python_package('yattag')
    install_python_package('python-dateutil')
    install_python_package('jinja2')
    install_python_package('peewee')
    install_python_package('pypiwin32')


def load_configuration(config_file_path):
    """ Load stored configuration.
    """
    config_load = {}

    # Determine if configuration file exists
    # Either force (if config file is not find) or prompt for walking through re-configuration wizard)
    if os.path.isfile(config_file_path):
        print_message('Loading previous configuration from {}.'.format(config_file_path))
        with open(config_file_path, 'r', encoding='utf-8') as config_file:
            config_load = {**config_load, **json.load(config_file)}
        # Prompt for Reconfigure

        if AUTO_SCRIPT:
            configure_again = False
        else:
            configure_again = prompt_user_bool('Reconfigure? y/n', 'n')
    else:
        print_message('Configuration file ({}) not found.'.format(config_file_path))
        print_message('The script will guide you through the configuration options.\n')
        configure_again = True
    return configure_again, config_load


def evaluate_environment(curr_root_path, configure_again, configuration):
    """ Determine mode of execution: "Dev-Env" vs "Deployed build"
    """
    if 'dev_env' not in configuration:
        # Determine default value by checking surrounding folder structure
        configuration['dev_env'] = os.path.isdir(os.path.join(curr_root_path, 'package', 'cfrpos', 'core'))

    if configure_again:
        # This if-else might look too complicated but the intention is to ask with a nice prompt
        # which is closer to expected answer (based on surrounding folder structure)
        if configuration['dev_env']:
            configuration['dev_env'] = \
                prompt_user_bool('Execute in "Dev-Env" mode [y] (or in "Deployed build" mode [n])?',
                                 configuration['dev_env'])
        else:
            configuration['dev_env'] = \
                not prompt_user_bool('Execute in "Deployed build" mode [y] (or in "Dev-Env" mode [n])?',
                                     not configuration['dev_env'])

    # See if selection of "config['dev_env']" matches surrounding folder structure.
    print_message('Sanity check: Does the surrounding folder structure match selection of execution mode: '
                  '"{0}"...?'.format('Dev-Env' if configuration['dev_env'] else 'Deployed build'))
    if configuration['dev_env']:
        # Source code folder structure (expected in "Dev-Env" mode)
        # <src root>/6.1/POS/BDD/Pos/
        # <src root>/6.1/POS/BDD/Pos/package/cfrpos/core
        # <src root>/6.1/POS/BDD/Pos/package/cfrpos/features
        # <src root>/6.1/POS/BDD/Pos/package/cfrpos/steps
        # <src root>/6.1/POS/BDD/Pos/once_click_setup.py # <-- this script
        if (not check_is_dir(os.path.join(curr_root_path, 'package', 'cfrpos', 'core'))
                or not check_is_dir(os.path.join(curr_root_path, 'package', 'cfrpos', 'features'))
                or not check_is_dir(os.path.join(curr_root_path, 'package', 'cfrpos', 'steps'))):
            raise Exception('ERROR: Dev-Env folder structure expected but not found.')
        else:
            print_message('OK. Surrounding folder structure looks correct.')
            print_message('Mode of execution: "Dev-Env".')
    else:  # not dev_env:
        # Expected folder structure in build output (expected in "Deployed build" mode)
        # <build>/Testing/POS/
        # <build>/Testing/POS/Python/
        # <build>/Testing/POS/once_click_setup.py # <-- this script
        if not check_is_dir(os.path.join(curr_root_path, 'Python')):
            raise Exception('ERROR: Found folder structure does not seem to be correctly deployed.')
        else:
            print_message('OK. Surrounding folder structure looks correct.')
            print_warning('Mode of execution: "Deployed build".')


def get_sdk_folder(current_path: str) -> str:
    """
        Retrieves the SDK folder.

        :param current_path: String. Contains current working directory. Assumes 6.1/POS/Bdd/Pos
        :return: Path to the SDK folder
    """
    sdk_folder = os.path.abspath(os.path.join(current_path, os.pardir, os.pardir, os.pardir, os.pardir, '.sdk'))
    if not os.path.isdir(sdk_folder):
        print_failure("Folder [%s] does not exist! Please make sure, that you've downloaded SDKs" % sdk_folder)
        raise Exception("ERROR: unable to find the SDK folder.")
    return sdk_folder


def get_platsys_folder(current_path: str, build_configuration: str = "Debug") -> str:
    """
        Retrieves the folder with Platform System binaries.

        :param current_path: String. Contains current working directory. Assumes 6.1/POS/Bdd/Pos
        :param build_configuration: String. Debug or Release. Specifies which version
                of built binaries do you want to use.
        :return: Path to the folder with platsys binaries
    """
    sdk_folder = get_sdk_folder(current_path)
    platsys_folder = os.path.abspath(
                os.path.join(sdk_folder, os.pardir, '6.1', 'bin'))
    if not os.path.isdir(platsys_folder):
        print_failure("Folder [%s] does not exist! Please make sure, that you've downloaded ALL SDKs" % platsys_folder)
        raise Exception("ERROR: unable to find the PlatSys binary folder.")
    return platsys_folder


def update_configuration_defaults(curr_root_path, configuration):
    """ Update configuration with defaults if a setting is missing.
    """
    if configuration['dev_env']:  # For "Dev-Env" mode
        build_config = configuration.setdefault('build_configuration', 'Debug')
        configuration.setdefault('product_bin_dir', os.path.abspath(
                os.path.join(curr_root_path, os.pardir, os.pardir, os.pardir, 'bin', 'NT', 'Debug')))
        configuration.setdefault('platsys_bin_dir', os.path.abspath(get_platsys_folder(curr_root_path, build_config)))
        configuration.setdefault('extract_bdd_scripts', False)
        configuration.setdefault('additional_data_dir', curr_root_path)
        configuration.setdefault('extract_bdd_data_and_media', True)
        configuration.setdefault('bdd_log_dir', os.path.abspath(os.path.join(curr_root_path, 'BDD_Logs')))
        configuration.setdefault('bdd_config_dir', os.path.abspath(os.path.join(curr_root_path, 'config')))
        configuration.setdefault('extract_nep_services', False)
        configuration.setdefault('nep_services_dir', os.path.abspath(os.path.join(
            curr_root_path, os.pardir, os.pardir, os.pardir, 'SiteServer', 'Simulators', 'nep-services')))
        configuration.setdefault('wincor_dir', os.path.abspath(
                os.path.join(curr_root_path, os.pardir, os.pardir, os.pardir, 'bin', 'NT', 'Debug', 'pos', 'automation', 'WincorEPSSimulator')))

    else:  # For "Deployed build" mode
        configuration.setdefault('product_bin_dir', r'C:\Program Files\Radiant\Fastpoint\Bin')
        configuration.setdefault('extract_bdd_scripts', True)
        configuration.setdefault('additional_data_dir', os.path.abspath(os.path.join(
            curr_root_path, os.pardir, os.pardir, '_BDD')))
        configuration.setdefault('extract_bdd_data_and_media', True)
        configuration.setdefault('bdd_log_dir', os.path.abspath(
            os.path.join(configuration['additional_data_dir'], 'BDD_Logs')))
        configuration.setdefault('bdd_config_dir',os.path.abspath(
            os.path.join(configuration['additional_data_dir'], 'config')))
        configuration.setdefault('extract_nep_services', True)
        configuration.setdefault('nep_services_dir', os.path.abspath(
            os.path.join(curr_root_path, os.pardir, os.pardir, 'nep_services')))
        configuration.setdefault('wincor_dir',  r'C:\Program Files\Radiant\Fastpoint\Bin')
    configuration.setdefault('pos_node_number', 1)
    configuration.setdefault('css_node_number', 45)
    configuration.setdefault('node_type', 1)
    configuration.setdefault('pos_resolution', 800)
    configuration.setdefault('enable_SCPOSSimulator', True)
    configuration.setdefault('sc_sim_address', '127.0.0.1')
    configuration.setdefault('sc_sim_port_number', 8900)
    configuration.setdefault('sc_sim_pos_services_dir', r'C:\Program Files\Radiant\Fastpoint\POSServices')
    configuration.setdefault('nep_install', True)
    configuration.setdefault('nep_server_port', 8083)
    configuration.setdefault('nep_notification_server_port', 8082)
    configuration.setdefault('use_radio_bdd', True)
    configuration.setdefault('use_logger_bdd', True)
    configuration.setdefault('update_xml2dat', True)
    configuration.setdefault('start_apps', True)
    configuration.setdefault('run_with_OpenCPPCoverage', False)
    configuration.setdefault('run_bdd_tests', True)
    configuration.setdefault('product_data_dir', r'C:\Program Files\Radiant\Fastpoint\data')
    configuration.setdefault('product_media_dir', r'C:\Program Files\Radiant\Fastpoint\media')
    configuration.setdefault('rpos_env', os.environ.copy())
    configuration.setdefault('pes_configuration_path', r'C:\Program Files\Radiant\Fastpoint\data\DirectPes.json')


def stop_apps(configuration):
    """ Stop POS and its simulators
    """
    print_message("Checking running applications...")
    apps = ['TeleQ.exe', 'POSEngine.exe', 'SCPOSServicesSimulator.exe', 'WincorEPSSimulator.exe']
    running_apps = []
    for app in apps:
        status = False
        if find_process(app):
            running_apps.append(app)
            status = True
        print_application_status(app, status)
#    running_apps = [app for app in apps if find_process(app)]
    if is_epc_simulator_running():
        running_apps.append("EPCSimulator")
        print_application_status("EPCSimulator (EPS, POSCache, Sigma)", True)
    else:
        print_application_status("EPCSimulator (EPS, POSCache, Sigma)")
    if is_scan_simulator_running():
        running_apps.append("ScannerSimulator")
        print_application_status("ScannerSimulator", True)
    else:
        print_application_status("ScannerSimulator")
    if is_printer_simulator_running():
        running_apps.append("PrinterSimulator")
        print_application_status("PrinterSimulator", True)
    else:
        print_application_status("PrinterSimulator")
    if is_swipe_simulator_running():
        running_apps.append("SwipeSimulator")
        print_application_status("SwipeSimulator", True)
    else:
        print_application_status("SwipeSimulator")
    if is_checkreader_simulator_running():
        running_apps.append("CheckreaderSimulator")
        print_application_status("CheckreaderSimulator", True)
    else:
        print_application_status("CheckreaderSimulator")
    if is_nepsvcs_simulator_running(configuration):
        running_apps.append('NEPServiceSimulator')
        print_application_status('NEPServiceSimulator', True)
    else:
        print_application_status('NEPServiceSimulator')
    if is_stmapi_simulator_running(configuration):
        running_apps.append("STMAPISimulator")
        print_application_status("STMAPISimulator", True)
    else:
        print_application_status("STMAPISimulator")
    if is_dc_server_running():
        running_apps.append("DCServer")
        print_application_status("DCServer", True)
    else:
        print_application_status("DCServer")
    if is_kps_simulator_running():
        running_apps.append("KPSSimulator")
        print_application_status("KPSSimulator", True)
    else:
        print_application_status("KPSSimulator")

    if len(running_apps) > 0:
        print_message('POS/CSS related apps will be stopped, so the installation can proceed.')

        for app in running_apps:
            if app == "EPCSimulator":
                stop_epc_simulator()
            elif app == "ScannerSimulator":
                stop_scan_simulator()
            elif app == "PrinterSimulator":
                stop_printer_simulator()
            elif app == "SwipeSimulator":
                stop_swipe_simulator()
            elif app == "CheckreaderSimulator":
                stop_checkreader_simulator()
            elif app == "NEPServiceSimulator":
                stop_nepsvcs_simulator()
            elif app == "DCServer":
                stop_dc_server()
            elif app == "STMAPISimulator":
                stop_stmapi_simulator(configuration)
            elif app == "KPSSimulator":
                stop_kps_simulator()
            else:
                os.system('TASKKILL /F /IM {}'.format(app))
    print_success()


def print_application_status(app_name, status: bool = False):
    """ Prints status of the application (running or not running on the system)
    """
    if 'colorama' in sys.modules:
        if status:
            print(colorama.Fore.LIGHTRED_EX + '{} is running...'.format(app_name) + colorama.Style.RESET_ALL)

        else:
            print(colorama.Fore.GREEN + '{} is not running...'.format(app_name) + colorama.Style.RESET_ALL)
    else:
        if status:
            print("{} is running...".format(app_name))
        else:
            print("{} is not running...".format(app_name))


def is_epc_simulator_running(address='127.0.0.1', port=5001):
    """ Check if EPC simulator is running.
    """
    try:
        url = 'http://{}:{}/v1/epc/check_status'.format(address, port)
        return urlopen(url).msg == 'OK'
    except URLError:
        return False


def stop_epc_simulator(address='127.0.0.1', port=5001):
    """ Stop EPC simulator.
    """
    try:
        url = 'http://{}:{}/v1/epc/shutdown'.format(address, port)
        return urlopen(url).msg == 'OK'
    except URLError as e:
        print_failure('ERROR: Unable to stop EPC simulator. Error "{}"'.format(e))


def is_scan_simulator_running(address='127.0.0.1', port=5002):
    """ Check if scan simulator is running.
    """
    try:
        url = 'http://{}:{}/bdd/pos/scanner/check_status'.format(address, port)
        return urlopen(url).msg == 'OK'
    except URLError:
        return False


def stop_scan_simulator(address='127.0.0.1', port=5002):
    """ Stop Scan simulator.
    """
    try:
        urlopen('http://{}:{}/bdd/pos/scanner/shutdown'.format(address, port))
    except URLError as e:
        print_failure('ERROR: Unable to stop Scan simulator. Error "{}"'.format(e))


def is_printer_simulator_running(address='127.0.0.1', port=5004):
    """ Check if Scan simulator is running.
    """
    try:
        url = 'http://{}:{}/bdd/pos/printer/check_status'.format(address, port)
        return urlopen(url).msg == 'OK'
    except URLError:
        return False


def stop_printer_simulator(address='127.0.0.1', port=5004):
    """ Stop printer simulator.
    """
    try:
        urlopen('http://{}:{}/bdd/pos/printer/shutdown'.format(address, port))
    except URLError as e:
        print_failure('ERROR: Unable to stop printer simulator. Error "{}"'.format(e))


def is_swipe_simulator_running(address='127.0.0.1', port=5000):
    """ Check if Swipe simulator is running.
    """
    try:
        url = 'http://{}:{}/bdd/pos/swiper/check_status'.format(address, port)
        return urlopen(url).msg == 'OK'
    except URLError:
        return False


def is_checkreader_simulator_running(address='127.0.0.1', port=5025):
    """ Check if Checkreader simulator is running.
    """
    try:
        url = 'http://{}:{}/v1/check_reader/check_status'.format(address, port)
        return urlopen(url).msg == 'OK'
    except URLError:
        return False


def is_kps_simulator_running(address='127.0.0.1', port=5007):
    """ Check if KPS simulator is running
    """
    try:
        url='http://{}:{}/bdd/pos/kps/check_status'.format(address, port)
        return urlopen(url).msg == 'OK'
    except URLError:
        return False


def stop_swipe_simulator(address='127.0.0.1', port=5000):
    """ Stop Swipe simulator.
    """
    try:
        urlopen('http://{}:{}/bdd/pos/swiper/shutdown'.format(address, port))
    except URLError as e:
        print_failure('ERROR: Unable to stop swipe simulator. Error "{}"'.format(e))


def stop_checkreader_simulator(address='127.0.0.1', port=5025):
    """ Stop Checkreader simulator.
    """
    try:
        urlopen('http://{}:{}/v1/check_reader/shutdown'.format(address, port))
    except URLError as e:
        print_failure('ERROR: Unable to stop checkreader simulator. Error "{}"'.format(e))


def stop_kps_simulator(address='127.0.0.1', port=5007):
    """ Stop KPS simulator
    """
    try:
        urlopen('http://{}:{}/bdd/pos/kps/shutdown'.format(address, port))
    except URLError as e:
        print_failure('ERROR: Unable to stop KPS simulator. Error "{}"'.format(e))


def is_nepsvcs_simulator_running(configuration, address='localhost'):
    """ Check if NEP Services simulator is running
    """
    try:
        url = 'http://{}:{}/state'.format(address, configuration.get('nep_server_port', 8080))
        return urlopen(url).msg == 'OK'
    except URLError:
        return False


def stop_nepsvcs_simulator(address='127.0.0.1', port=8083):
    """ Stop NEP Services simulator.
    """
    try:
        request = Request(
            url='http://{}:{}/simulator/shutdown'.format(address, port),
            headers={ 'Content-Type': 'application/json' },
            data=b'{}',
            method='POST')
        urlopen(request)
    except URLError as e:
        print_failure('ERROR: Unable to stop nep-simulator. Error "{}"'.format(e))


def is_stmapi_simulator_running(configuration, address='127.0.0.1'):
    """ Check if Stmapi simulator is running.
    """
    try:
        url = 'http://{}:{}/v1/stmapi/status'.format(address, configuration.get(
            'api', {}).get('stmapi_sim', {}).get('port', 5005))
        return urlopen(url).msg == 'OK'
    except URLError:
        return False


def stop_stmapi_simulator(configuration, address='127.0.0.1'):
    """ Stop Stmapi simulator.
    """
    try:
        request = Request(
            url='http://{}:{}/v1/stmapi/shutdown'.format(address, configuration.get(
                'api', {}).get('stmapi_sim', {}).get('port', 5005)),
            headers={'Content-Type': 'application/json'},
            data=b'{}',
            method='POST')
        urlopen(request)
    except URLError as e:
        print_failure('ERROR: Unable to stop STMAPI simulator. Error "{}"'.format(e))


def is_dc_server_running(address='127.0.0.1', port=5020):
    """ Check if DC server is running.
    """
    try:
        url = 'http://{}:{}/v1/dcserver/status'.format(address, port)
        return urlopen(url).msg == 'OK'
    except URLError:
        return False


def stop_dc_server(address='127.0.0.1', port=5020):
    """ Stop DC server.
    """
    try:
        urlopen('http://{}:{}/v1/dcserver/shutdown'.format(address, port))
    except URLError as e:
        print_failure('ERROR: Unable to stop DC server. Error "{}"'.format(e))


def install_bdd_python_package(curr_root_path, package_name, dev_root_path, configuration):
    """ Install package.
    """
    print_message('Installing the "{}" package.'.format(package_name))

    # "Dev-Env": Uninstall the package and create editable link to location of sources of the package
    if configuration['dev_env']:
        configuration['build'] = '1.00.0000'
        package_path = os.path.join(dev_root_path, 'package')
        if util.find_spec(package_name) is not None:
            importlib.invalidate_caches()

        # Create version file which is expected by core/setup.py
        with open(os.path.join(package_path, 'version'), "w+") as f:
            f.write(configuration['build'])  # just a dummy version

        subprocess.check_call([sys.executable, '-m', 'pip', 'install', '--editable', package_path])
        importlib.invalidate_caches()

        # Extend path because path is not updated when the editable package is installed.
        if package_path not in sys.path:
            sys.path.append(package_path)

        print_success()

    # "Deployed build": Install package
    else:
        # Install <package name>-<build number>.zip package
        file_path, build = find_package(os.path.join(curr_root_path, 'Python'), '{}-'.format(package_name))
        if file_path is None or build is None:
            raise Exception('ERROR: Package file ({}) not found'.format(package_name))
        configuration['build'] = build
        print_message('Found build: {}'.format(build))
        if not install_python_package(package_name, file_path, always_install=True):
            raise Exception('ERROR: Installing python package [{}] failed'.format(package_name))


def install_cfrpos_package(curr_root_path, configuration):
    install_bdd_python_package(
            curr_root_path,
            'cfrpos',
            curr_root_path,
            configuration)


def install_sim4cfrpos_package(curr_root_path, configuration):
    install_bdd_python_package(
            curr_root_path,
            'sim4cfrpos',
            os.path.abspath(os.path.join(curr_root_path, '..', '..', 'Simulators')),
            configuration)


def install_bdd_steps_features(curr_root_path, configure_again, configuration):
    # "Deployed build": Extract BDD tests
    if not configuration['dev_env']:  # in Dev-Env mode, the BDD tests left in their place

        # Create _BDD folder
        if configure_again:
            configuration['additional_data_dir'] = prompt_user(
                'Enter absolute path to desired location of BDD test suite.',
                configuration['additional_data_dir'], check_make_dir_with_access)
        else:
            assert check_make_dir_with_access(configuration['additional_data_dir']), 'Creating BDD script dir failed.'
        update_configuration_path_scripts(configuration)

        # Extract BDD scripts form bddtests.zip
        if configure_again:
            configuration['extract_bdd_scripts'] = prompt_user_bool('Extract BDD scripts (bddtest.zip)? y/n',
                                                                    configuration['extract_bdd_scripts'])
        if configuration['extract_bdd_scripts']:
            # Extract scripts
            src_dir = os.path.join(curr_root_path, 'Python')
            print_message('Extracting "bddtests.zip" to "{}" ...'.format(configuration['additional_data_dir']))
            shutil.unpack_archive(os.path.join(src_dir, 'bddtests.zip'), configuration['additional_data_dir'], 'zip')
            print_success()


def extract_nep_services(curr_root_path, configure_again, configuration):
    # "Deployed build": Extract nep-services
    if not configuration['dev_env']:    # in Dev-Env mode are nep-services left in their place

        src_dir = os.path.join(curr_root_path, os.pardir, 'SC')
        nep_services_package = find_package(src_dir, 'nep-services-simulator-')[0]

        if nep_services_package is None:
            print_failure('Missing "nep-services-simulator-*.zip" in "{}".'.format(src_dir))
            raise Exception('ERROR: Missing "nep-services-simulator-*.zip" in "{}".'.format(src_dir))
        else:
            nep_services_package = os.path.basename(nep_services_package)

        if configure_again:
            configuration['extract_nep_services'] = prompt_user_bool('Extract NEP Services simulator ({})? y/n'.format(nep_services_package),
                                                                    configuration['extract_nep_services'])

        if configuration['extract_nep_services']:
            # Extract NEP Services simulator
            print_message('Extracting "{}" to "{}" ...'.format(nep_services_package, configuration['additional_data_dir']))
            shutil.unpack_archive(os.path.join(src_dir, nep_services_package), configuration['additional_data_dir'], 'zip')
            print_success()


def update_configuration_path_scripts(configuration):
    """ Updates some paths in configuration to reflect changes when script path changes.
    """
    configuration['bdd_log_dir'] = os.path.abspath(os.path.join(configuration['additional_data_dir'], 'BDD_Logs'))
    configuration['bdd_config_dir'] = os.path.abspath(os.path.join(configuration['additional_data_dir'], 'config'))
    configuration['nep_services_dir'] = os.path.abspath(os.path.join(configuration['additional_data_dir'], 'nep-services'))


def update_node_type(configuration, reconfigure: bool = False):
    """ Determines which node configuration should be used (CSS or POS) """
    node_type = configuration.get('node_type', 1)

    print_warning("Currently used node type: '{}'".format(
        'POS' if node_type == 1 else 'CSS'))
    if AUTO_SCRIPT:
        pass
    elif reconfigure:
        question = "Do you want to switch to {}?".format(
            'CSS' if node_type == 1 else 'POS')
        answer = prompt_user_bool(question, 'n')
        if answer:
            configuration['node_type'] = 1 if node_type == 2 else 2


def update_dev_binary_folder(configuration: dict):
    """
    Updates the path to the folder with RPOS binaries
    """
    path_set = False
    for x in range(0, 3):
        base_path = prompt_user("Please provide the path to the binary folder without Debug or Release at the end",
                                'C:\\Git\\Rpos\\6.1\Bin\\NT\\', check_is_dir)
        build_configuration = prompt_user("Do you want to use Release or Debug?",
                                          configuration['build_configuration'],
                                          check_build_configuration)
        bin_path = os.path.join(base_path, build_configuration)
        if check_is_dir(bin_path):
            configuration['build_configuration'] = build_configuration
            configuration['product_bin_dir'] = bin_path
            current_folder = os.path.abspath(os.path.dirname(os.path.realpath(__file__)))
            configuration['platsys_bin_dir'] = os.path.abspath(
                get_platsys_folder(current_folder, build_configuration))
            if configuration['dev_env']:
                configuration['rpos_env'] = os.environ.copy()
                configuration['rpos_env']['PATH'] += ';' + configuration.get('platsys_bin_dir')
            path_set = True
            break
        else:
            print_failure("The folder [%s] does not exist. Please provide a valid path components." % bin_path)

    if not path_set:
        raise Exception("Valid path to the binary folder was not provided.")


def update_runtime_configuration(reconfigure_again, configuration):
    if reconfigure_again:
        # Bin path for the POS
        question = "Enter absolute path to the product's Bin folder."
        if configuration['dev_env']:
            if prompt_user_bool("The current Bin folder is [%s]. Do you want to change it?"
                                % configuration['product_bin_dir'], 'n'):
                update_dev_binary_folder(configuration)
        else:
            configuration['product_bin_dir'] = prompt_user(question, configuration['product_bin_dir'],
                                                           check_make_dir_with_access)

        print_warning("Actual configuration: ")
        print_warning("    POS node number    = {}".format(configuration['pos_node_number']))
        print_warning("    CSS node number    = {}".format(configuration['css_node_number']))
        print_warning("    Node screen resolution = {}".format(configuration['pos_resolution']))
        print_warning("    SC sim address     = {}".format(configuration['sc_sim_address']))
        print_warning("    SC sim port        = {}".format(configuration['sc_sim_port_number']))
        print_warning("    NEP server port    = {}".format(configuration['nep_server_port']))
        print_warning("    NEP notification server port = {}".format(configuration['nep_notification_server_port']))

        answer = prompt_user_bool('Do you want to change these properties? y/n', 'n')
        if answer:
            # Query POS environment setup
            configuration['pos_node_number'] = prompt_user('Enter node number of your POS', configuration['pos_node_number'],
                                                           check_is_node_number)
            configuration['css_node_number'] = prompt_user('Enter node number of your CSS', configuration['css_node_number'],
                                                           check_is_node_number)

            # Determine POS screen resolution
            configuration['pos_resolution'] = int(prompt_user('Choose window width? 800/1024/1280/1366/1920',
                                                              configuration['pos_resolution'], check_valid_width))

            # Query further environment setup
            configuration['sc_sim_address'] = prompt_user('Enter IP address the SC Simulator will be running on.',
                                                          configuration['sc_sim_address'], check_is_ip)
            configuration['sc_sim_port_number'] = prompt_user('Enter port the SC Simulator will be running on',
                                                              configuration['sc_sim_port_number'], check_is_port)

            # Query NEP environment setup
            configuration['nep_server_port'] = prompt_user('Enter port the NEP server will be running on',
                                                            configuration['nep_server_port'], check_is_port)
            configuration['nep_notification_server_port'] = prompt_user('Enter port the NEP notification server will be running on',
                                                            configuration['nep_notification_server_port'], check_is_port)

        # CPP coverage - not fully supported yet
        # configuration['run_with_OpenCPPCoverage'] = prompt_user_bool('Start POSEngine with OpenCPPCoverage? y/n',
        #                                                             configuration['run_with_OpenCPPCoverage'])

    # Create the environment
    print_message("Updating environment...")
    os.makedirs(configuration['bdd_log_dir'], exist_ok=True)
    print_success()


def stage_pos(curr_root_path, configuration):
    """ Prepare POS for installation
    """
    if not configuration['dev_env']:  # in Dev-Env mode, binaries are built by DEV
        print_message('Staging POS.')
        packages = [('ProductionPos.', '.'),
                    ('SimulatorsPos.', 'simulators'),
                    ('ProductBddPos.', '.'),
                    ('ToolsPos.', '.')]
        configuration['staging_dir'] = os.path.join(curr_root_path, 'staging')
        if os.path.isdir(configuration['staging_dir']):
            shutil.rmtree(configuration['staging_dir'])
        os.mkdir(configuration['staging_dir'])
        for package in packages:
            package_name, package_tgt_dir = package
            print_message('Staging package [{}]'.format(package_name))
            file_path = find_package(curr_root_path, package_name, configuration['build'])[0]
            assert file_path is not None, 'Package [{}{}.zip] not found.'.format(package_name, configuration['build'])
            tgt_path = os.path.normpath(os.path.join(configuration['staging_dir'], package_tgt_dir))
            shutil.unpack_archive(file_path, tgt_path, 'zip')

        # Consolidate simulators
        sim_dir = os.path.join(configuration['staging_dir'], 'simulators')
        staging_bin_dir = os.path.join(configuration['staging_dir'], 'bin')
        dir_names = os.listdir(sim_dir)
        for dir_name in dir_names:
            if os.path.isdir(os.path.join(sim_dir, dir_name)):
                print_message('Consolidating simulator [{}]'.format(dir_name))
                directory = os.path.join(sim_dir, dir_name)
                copy_replace_dir(directory, staging_bin_dir)

        configuration['staging_bin_dir'] = staging_bin_dir
        configuration['staging_data_dir'] = os.path.join(configuration['staging_dir'], 'data')
        configuration['staging_data_css_dir'] = os.path.join(configuration['staging_dir'], 'data_css')
        configuration['staging_media_dir'] = os.path.join(configuration['staging_dir'], 'media')
        configuration['staging_data_shell_vantage_dir'] = os.path.join(configuration['staging_dir'], 'data_shell_vantage')
        print_success()
    else:
        configuration['staging_bin_dir'] = None
        configuration['staging_data_dir'] = os.path.join(curr_root_path, 'config', 'data')
        configuration['staging_data_dir_1366_pos'] = os.path.join(curr_root_path, 'config', 'data_1366')
        configuration['staging_data_dir_1920_pos'] = os.path.join(curr_root_path, 'config', 'data_1920')
        configuration['staging_data_css_dir'] = os.path.join(curr_root_path, 'config', 'data_css')
        configuration['staging_media_dir'] = os.path.join(curr_root_path, 'config', 'media')
        configuration['staging_data_shell_vantage_dir'] = os.path.join(curr_root_path, 'config', 'data_shell_vantage')
        print_success()


def install_pos(curr_root_path, configuration):
    print_message('Installing POSEngine...')
    if configuration['staging_bin_dir'] is not None:
        move_dir(configuration['staging_bin_dir'], configuration['product_bin_dir'])

    # Complete staging data with files available elsewhere in source control
    if configuration['dev_env']:
        source_control_root = os.path.abspath(os.path.join(curr_root_path, os.pardir, os.pardir, os.pardir, os.pardir))
        copy_replace_file(
            os.path.join(source_control_root, 'Setup', '6.1', 'ISSETUPFILES'),
            configuration['staging_data_dir'],
            'DriversLicenseValidation.xml')
        copy_replace_file(
            os.path.join(source_control_root, '6.1', 'SiteServer', 'Site Deployment Files'),
            configuration['staging_data_dir'],
            'PosConnectMessages.json')
        sc_folder = os.path.join(configuration['product_bin_dir'], 'sc')
        copy_replace_file(sc_folder, configuration['product_bin_dir'], 'SiteServerApiClientCpp.dll')

    # Check that POSBDD.dll is present in the Bin folder
    tgt = os.path.join(configuration['product_bin_dir'], 'POSBDD.dll')
    if not os.path.isfile(tgt):
        raise Exception('ERROR: The POSBDD.dll is not present at the expected location: [{}]. '
                        '(Did you build it?)'.format(tgt))
    print_success()


def prepare_data_files_for_conversion(configuration: dict):
    directory = configuration['staging_data_dir']
    temp_directory_created = False
    if configuration.get('node_type', 1) == 2:
        temp_directory = tempfile.mkdtemp()
        temp_directory_created = True
        copy_replace_dir(directory, temp_directory)
        directory = temp_directory
        staging_data_css_dir = configuration['staging_data_css_dir']
        if not os.path.exists(staging_data_css_dir):
            print_failure('Configuration files for CSS are missing')
            raise Exception('ERROR: Configuration files for CSS are missing')
        else:
            for file_name in os.listdir(staging_data_css_dir):
                copy_replace_file(staging_data_css_dir, temp_directory, file_name)
    else:
        temp_directory = tempfile.mkdtemp()
        temp_directory_created = True
        copy_replace_dir(directory, temp_directory)
        directory = temp_directory
        staging_data_shell_vantage_dir = configuration['staging_data_shell_vantage_dir']

        if configuration['pos_resolution'] == 1366:
            directory_1366 = configuration['staging_data_dir_1366_pos']
            if os.path.exists(directory_1366):
                copy_replace_dir(directory_1366, directory)

        if configuration['pos_resolution'] == 1920:
            directory_1920 = configuration['staging_data_dir_1920_pos']
            if os.path.exists(directory_1920):
                copy_replace_dir(directory_1920, directory)

        if not os.path.exists(staging_data_shell_vantage_dir):
            print_failure('Configuration files for Shell Vantage are missing')
            raise Exception('ERROR: Configuration files for Shell Vantage are missing')
        else:
            for file_name in os.listdir(staging_data_shell_vantage_dir):
                copy_replace_file(staging_data_shell_vantage_dir, temp_directory, file_name)
    return directory, temp_directory_created


def configure_pos(configure_again, configuration):
    node = "POS" if configuration.get('node_type', 1) == 1 else "CSS"
    print_message("Configuring '{}'...".format(node))
    if configure_again and configuration["dev_env"]:
        if not check_make_radiant_folder():
            raise Exception("Could not create Radiant folder...")
    # Always Run POS in window
    with winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, r'Software\Radiant\Radio') as radio_key:
        winreg.SetValueEx(radio_key, "WindowBased", 0, winreg.REG_DWORD, 1)
    with winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, r'Software\Radiant\Radio') as radio_key:
        resolution_map = {800: 'Force800by600', 1024: 'Force1024by768', 1280: 'Force1280by1024', 1366: 'Force1366by768', 1920: 'Force1920by1080'}
        for key in resolution_map:
            try:
                if key == configuration['pos_resolution']:
                    winreg.SetValueEx(radio_key, resolution_map.get(key), 0, winreg.REG_DWORD, 1)
                else:
                    winreg.DeleteValue(radio_key, resolution_map.get(key))
            except OSError as e:
                if e.errno != 2:
                    raise

    # Set directories
    with winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, r'Software\Radiant\System Manager') as radio_key:
        winreg.SetValueEx(radio_key, 'Data Directory', 0, winreg.REG_SZ, configuration['product_data_dir'])

    winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, r'Software\RadiantSystems\RadGCM')

    # Re-deploy Data & Media?
    if configure_again:
        configuration['extract_bdd_data_and_media'] = prompt_user_bool(r'(Re-)Deploy "Fastpoint\Data" and '
                                                                       r'"Fastpoint\Media"? y/n',
                                                                       configuration['extract_bdd_data_and_media'])
    if configuration['extract_bdd_data_and_media']:
        print_message('Deploying Data and Media files...')
        from cfrpos.core.bdd_utils import bdd_environment

        staging_data_dir, temp_dir = prepare_data_files_for_conversion(configuration)
        if not bdd_environment.deploy_data({
                         'bin_dir': configuration['product_bin_dir'],
                         'data_dir': configuration['product_data_dir'],
                         'media_dir': configuration['product_media_dir'],
                         'pos_resolution': configuration['pos_resolution']
                 },
                 staging_data_dir,
                 configuration['staging_media_dir']):
            raise Exception('ERROR: Deployment of data or media failed.')
        if temp_dir:
            shutil.rmtree(staging_data_dir)
        print_success()

        # Modify the POS SOAP configuration file to properly communicate with simulator
        soap_config_pathname = os.path.join(configuration['product_data_dir'], 'SOAPConfigLocation.xml')
        print_message('Configuring SOAP [{}]...'.format(soap_config_pathname))
        if os.path.isfile(soap_config_pathname):
            os.chmod(soap_config_pathname, stat.S_IWRITE | stat.S_IREAD)
            tree = ET.parse(soap_config_pathname)
            root = tree.getroot()
            root.find('Path').text = '/POSServicesConfiguration/WebConfiguration.xml'
            root.find('Host').text = str(configuration['sc_sim_address'])
            root.find('SocketPort').text = str(configuration['sc_sim_port_number'])
            tree.write(soap_config_pathname)
        else:
            raise Exception('File not found: {}'.format(soap_config_pathname))

        print_success()

    # Add necessary registry values for SigmaGCM_Plugin
    with winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, r'Software\RadiantSystems\RadGCM\PlugInDLLs\SIGMA') as radgcm_key:
        winreg.SetValueEx(radgcm_key, 'DllName', 0, winreg.REG_SZ, 'Sigma_GCMPlugInBDD.dll')
        winreg.SetValueEx(radgcm_key, 'SortOrder', 0, winreg.REG_SZ, '250')

    with winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, r'Software\RadiantSystems\RadGCM\PlugInDLLs\EPSILON') as radgcm_key:
        winreg.SetValueEx(radgcm_key, 'DllName', 0, winreg.REG_SZ, 'Epsilon_GCMPlugInBDD.dll')
        winreg.SetValueEx(radgcm_key, 'SortOrder', 0, winreg.REG_SZ, '255')


def install_radio_bdd(configure_again, configuration):
    # Install RadioBDD
    if configure_again:
        configuration['use_radio_bdd'] = prompt_user_bool('Enable RadioBDD? y/n', configuration['use_radio_bdd'])

    if configuration['use_radio_bdd']:
        print_message('Installing RadioBDD.dll.')

        # Check that RadioBDD.dll and RadioLocal.dll are present in the Bin folder
        tgt = os.path.join(configuration['product_bin_dir'], 'RadioBDD.dll')
        if not os.path.isfile(tgt):
            raise Exception('ERROR: You have chosen to use the RadioBDD, but [{}] does not exist. '
                            '(Did you build it?)'.format(tgt))
        tgt = os.path.join(configuration['product_bin_dir'], 'RadioLocal.dll')
        if not os.path.isfile(tgt):
            raise Exception('ERROR: You have chosen to use the RadioBDD, but [{}] does not exist. '
                            '(Did you build it?)'.format(tgt))

        print_message('    Enabling RadioBDD in registry...')
        with winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, r'Software\Radiant\RadioProxy') as radio_proxy_key:
            winreg.SetValueEx(radio_proxy_key, "RadioDLL", 0, winreg.REG_SZ, 'RadioBDD.dll')

        with winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, r'Software\Radiant\BDD\Radio') as radio_BDD_key:
            tgt = os.path.join(configuration['bdd_config_dir'], "RadioBDD_Settings.json")
            print_message('    RadioBDD will use configuration from [{}].'.format(tgt))
            winreg.SetValueEx(radio_BDD_key, "Settings", 0, winreg.REG_SZ, tgt)

            print_message('    Creating RadioBDD configuration file [{}].'.format(tgt))
            node_type = configuration.get('node_type', 1)
            node_number = configuration.get('pos_node_number', 1)
            if node_type == 2:
                node_number = configuration.get('css_node_number', 45)

            with open(tgt, 'w') as setting_file:
                sc_info = build_radiobdd_info('123', configuration['sc_sim_address'])
                pos_info = build_radiobdd_info(node_number, '127.0.0.1')
                setting_file.write('[\n' + sc_info + ',\n' + pos_info + '\n' + ']\n')

            tgt = os.path.join(configuration['bdd_log_dir'], 'RadioBDD.log')
            print_message('    RadioBDD will log to [{}].'.format(tgt))
            winreg.SetValueEx(radio_BDD_key, 'LogFile', 0, winreg.REG_SZ, tgt)

        print_success()


def install_xml2dat(configure_again, configuration):
    print_message('Setting Xml2Dat settings.')

    # Check that Xml2Dat.exe is present in the bin folder
    tgt = os.path.join(configuration['product_bin_dir'], 'Xml2RelayDat.exe')
    if not os.path.isfile(tgt):
        raise Exception('ERROR: You have chosen to set-up Xml2dat, but [{}] does not exist. '
                        '(Did you build it?)'.format(tgt))

    print_message('    Setting Xml2RelayDat.exe in registry...')
    with winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, r'Software\Radiant\BDD\XML2Dat') as xml2dat_key:
        winreg.SetValueEx(xml2dat_key, "Binary", 0, winreg.REG_SZ, str(tgt))
        winreg.SetValueEx(xml2dat_key, "DataDir", 0, winreg.REG_SZ, configuration['product_data_dir'])
    print_success()


def build_radiobdd_info(node_number, ip_address, mask="255.255.255.0"):
    """ Builds a node information for radioBDD to save it to its config file
    """
    info = dict()
    info["RSSysGetLocalClientNumber"] = int(node_number)
    info["RSSysGetParameter"] = {"PRIMARY_IP_INFORMATION": {"IPAddress": str(ip_address), "SubnetMask": str(mask)}}
#    return str(info).replace(' ', '').replace("'", '"')
    return json.dumps(info, separators=(',', ':'))


def install_logger_bdd(configure_again, configuration):
    # Install LoggerBDD
    if configure_again:
        configuration['use_logger_bdd'] = prompt_user_bool('Enable LoggerBDD? y/n', configuration['use_logger_bdd'])
    if configuration['use_logger_bdd']:
        print_message('Installing LoggerBDD.dll.')

        # Check that LoggerBDD.dll is present in the Bin folder
        tgt = os.path.join(configuration['product_bin_dir'], 'LoggerBDD.dll')
        if not os.path.isfile(tgt):
            raise Exception('ERROR: You have chosen to use the LoggerBDD, but [{}] does not exist. '
                            '(Did you build it?)'.format(tgt))

        print_message('    Enabling LoggerBDD in registry...')
        with winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, r'Software\Radiant\PlatformSystems\StdLogger') as playtsys_key:
            winreg.SetValueEx(playtsys_key, 'STDLoggerPluginDLL', 0, winreg.REG_SZ,
                              os.path.join(configuration['product_bin_dir'], 'LoggerBDD.dll'))

        print_message('    POSEngine will log to [{0}].'.format(os.path.join(configuration['bdd_log_dir'], 'PosBdd.log')))
        with winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, r'Software\Radiant\BDD\Logger') as logger_key:
            winreg.SetValueEx(logger_key, 'LogFile', 0, winreg.REG_SZ,
                              os.path.join(configuration['bdd_log_dir'], 'PosBdd.log'))
        print_success()


def install_sc_pos_simulator(configure_again, configuration):
    # Install SC POS Services Simulator
    print_message('Installing SCPOSServicesSimulator...')

    # Check that the SC simulator is present at desired location
    sc_simulator_tgt_path = configuration['product_bin_dir']
    tgt = os.path.join(sc_simulator_tgt_path, 'SCPOSServicesSimulator.exe')
    if not os.path.isfile(tgt):
        raise Exception('ERROR: File {} not found. (Did you build it?)'.format(tgt))
    tgt = os.path.join(sc_simulator_tgt_path, 'POSServiceSimulator.dll')
    if not os.path.isfile(tgt):
        raise Exception('ERROR: File {} not found. (Did you build it?)'.format(tgt))
    tgt = os.path.join(sc_simulator_tgt_path, 'SCPOSServicesSimulator.exe.config')
    if not os.path.isfile(tgt):
        raise Exception('ERROR: File {} not found. (Did you build it?)'.format(tgt))

    # Prompt for customization folder.
    if configure_again:
        configuration['sc_sim_pos_services_dir'] = \
            prompt_user("Enter absolute path to the SC POS simulator folder for custom WSML, WSDL, and other "
                        "downloadable files.", configuration['sc_sim_pos_services_dir'], check_make_dir_with_access)

    # Modify SC POS Simulator configuration file to start on desired address and port
    sc_simulator_config_path_name = os.path.join(sc_simulator_tgt_path, 'SCPOSServicesSimulator.exe.config')
    print_message('    Configuring SC simulator for POSEngine: [{}].'.format(sc_simulator_config_path_name))
    if os.path.isfile(sc_simulator_config_path_name):
        tree = ET.parse(sc_simulator_config_path_name)
        root = tree.getroot()
        app_settings = root.find('appSettings')
        for entry in app_settings.findall('add'):
            if 'key' in entry.attrib:
                key_name = entry.attrib['key']
                if key_name == 'IPAddress':
                    entry.attrib['value'] = str(configuration['sc_sim_address'])
                elif key_name == 'IPPort':
                    entry.attrib['value'] = str(configuration['sc_sim_port_number'])
                elif key_name == 'POSServiceDirectory':
                    entry.attrib['value'] = configuration['sc_sim_pos_services_dir']
        tree.write(sc_simulator_config_path_name)
    else:
        raise Exception('ERROR: File {} not found.'.format(sc_simulator_config_path_name))
    print_success()


def install_nepsvcs_simulator(configure_again, configuration):
    # Install NEP Services Simulator
    print_message('Installing NEPServicesSimulator...')

    # Prompt for simulator folder.
    if configure_again:
        configuration['nep_services_dir'] = \
            prompt_user('Enter absolute path to the NEP Services simulator folder.',
                        configuration['nep_services_dir'], check_make_dir_with_access)

    nep_dir = configuration['nep_services_dir']

    # Get Node.js install directory where npm.cmd should be located
    with winreg.OpenKeyEx(winreg.HKEY_LOCAL_MACHINE, r'SOFTWARE\Node.js', 0, winreg.KEY_READ | winreg.KEY_WOW64_64KEY) as subkey:
        nodejs_dir = winreg.QueryValueEx(subkey, 'InstallPath')[0]

    # Check necessary files: ${nodejs_dir}\\npm.cmd will execute ${nep_dir}\\package.json
    nep_package = os.path.join(nep_dir, 'package.json')
    npm_cmd = os.path.join(nodejs_dir, 'npm.cmd')

    if not os.path.isfile(nep_package):
        raise Exception('ERROR: File {} not found.'.format(nep_package))
    if not os.path.isfile(npm_cmd):
        raise Exception('ERROR: File {} not found.'.format(npm_cmd))

    if configure_again:
        configuration['nep_install'] = \
            prompt_user_bool('(Re-)Install NEP Services simulator? y/n', configuration['nep_install'])

    if configuration['nep_install']:
        # 'npm install' will prepare NEP Services simulator
        subprocess.check_call(
            [
                npm_cmd,
                'install'
            ],
            cwd=nep_dir
        )
        # 'npm audit fix' should get rid of vulnerabilities in package
        subprocess.check_call(
            [
                npm_cmd,
                'audit',
                'fix'
            ],
            cwd=nep_dir
        )

        # It is desired to call 'npm install' only the first time.
        # Next time user has to reconfigure to allow another 'npm install' call.
        configuration['nep_install'] = 'n'

    print_success()


def install_wincor_simulator(configure_again, configuration):
    print_message('Installing Wincor EPS simulator...')

    if configure_again:
        configuration['wincor_dir'] = \
            prompt_user('Enter absolute path to the Wincor EPS simulator folder.',
                        configuration['wincor_dir'], check_make_dir_with_access)
    wincor_simulator_path = configuration['wincor_dir']
    tgt = os.path.join(wincor_simulator_path, 'WincorEPSSimulator.exe')
    if not os.path.isfile(tgt):
        raise Exception('ERROR: File {} not found. (Did you build it?)'.format(tgt))
    print_success()


def build_bdd_config(curr_root_path, configuration):
    # Prepare BDD configuration (config.json)
    print_message('Preparing BDD config.json...')
    config_pathname_default = os.path.join(configuration['bdd_config_dir'], 'config.json')
    config_pathname_override = os.path.join(configuration['bdd_config_dir'], 'config.user.json')
    configuration['bdd_config_file'] = config_pathname_override
    source_control_pos = os.path.abspath(os.path.join(curr_root_path, os.pardir, os.pardir))

    if not os.path.isfile(config_pathname_default):
        raise Exception('Default BDD config file not found: [{}]'.format(config_pathname_default))

    print_message('    Configuring [{}]...'.format(config_pathname_override))
    with open(config_pathname_default, 'rt', encoding='utf8') as file:
        config_bdd = json.load(file)
        config_bdd['bin_dir'] = configuration['product_bin_dir']
        config_bdd['data_dir'] = configuration['product_data_dir']
        config_bdd['media_dir'] = configuration['product_media_dir']
        config_bdd['initial_data_dir'] = configuration['staging_data_dir']
        config_bdd['bdd_config_file'] = configuration['bdd_config_file']
        config_bdd['rpos_env'] = configuration['rpos_env']
        config_bdd['api']['pos']['pos_node_number'] = int(configuration['pos_node_number'])
        config_bdd['api']['pos']['css_node_number'] = int(configuration['css_node_number'])
        config_bdd['api']['pos']['node_type'] = int(configuration['node_type'])
        config_bdd['api']['sc_sim']['address'] = configuration['sc_sim_address']
        config_bdd['api']['sc_sim']['port'] = int(configuration['sc_sim_port_number'])
        if configuration['dev_env']:
            config_bdd['api']['swipe_sim']['cards'] = os.path.abspath(os.path.join(
                source_control_pos, 'Simulators', 'package', 'sim4cfrpos', 'api', 'swipe_sim', 'SimCards.xml'))
            config_bdd['api']['checkreader_sim']['checks'] = os.path.abspath(os.path.join(
                source_control_pos, 'Simulators', 'package', 'sim4cfrpos', 'api', 'checkreader_sim', 'CheckData.xml'))
            config_bdd['api']['scan_sim']['barcodes'] = os.path.abspath(os.path.join(
                source_control_pos, 'Simulators', 'package', 'sim4cfrpos', 'api', 'scan_sim', 'SimBarcodes.xml'))
            config_bdd['api']['epc_sim']['configuration_folder'] = os.path.abspath(os.path.join(
                source_control_pos, 'Simulators', 'package', 'sim4cfrpos', 'runtime', 'epc_sim', 'configuration'))
            config_bdd['wincor_dir'] = os.path.abspath(
                os.path.join(curr_root_path, os.pardir, os.pardir, os.pardir, 'bin', 'NT', 'Debug', 'pos', 'automation', 'WincorEPSSimulator'))
            config_bdd['api']['sc_sim']['data'] = os.path.abspath(os.path.join(
                source_control_pos, 'BDD', 'Pos', 'package', 'cfrpos', 'core', 'simulators', 'sc_sim', 'data'))
        else:
            config_bdd['api']['swipe_sim']['cards'] = os.path.join(configuration['product_data_dir'], 'SimCards.xml')
            config_bdd['api']['checkreader_sim']['checks'] = os.path.join(configuration['product_data_dir'], 'CheckData.xml')
            config_bdd['api']['scan_sim']['barcodes'] = os.path.join(configuration['product_data_dir'], 'SimBarcodes.xml')
            config_bdd['api']['epc_sim']['configuration_folder'] = os.path.join(configuration['product_data_dir'], 'configuration')
            config_bdd['wincor_dir'] = configuration['product_bin_dir']
            config_bdd['api']['sc_sim']['data'] = os.path.join(configuration['product_data_dir'], 'sc_sim_data')

        config_bdd['api']['swipe_sim']['log_file'] = os.path.join(configuration['bdd_log_dir'], 'SwipeSim.log')
        config_bdd['api']['swipe_sim']['server_log_file'] = os.path.join(configuration['bdd_log_dir'], 'SwipeSimServer.log')
        config_bdd['api']['checkreader_sim']['log_file'] = os.path.join(configuration['bdd_log_dir'], 'CheckreaderSim.log')
        config_bdd['api']['scan_sim']['log_file'] = os.path.join(configuration['bdd_log_dir'], 'ScanSim.log')
        config_bdd['api']['scan_sim']['server_log_file'] = os.path.join(configuration['bdd_log_dir'], 'ScanSimServer.log')
        config_bdd['api']['print_sim']['log_file'] = os.path.join(configuration['bdd_log_dir'], 'PrintSim.log')
        config_bdd['api']['print_sim']['server_log_file'] = os.path.join(configuration['bdd_log_dir'], 'PrintSimServer.log')
        config_bdd['api']['epc_sim']['eps_sim']['log_file'] = os.path.join(configuration['bdd_log_dir'], 'EpsSim.log')
        config_bdd['api']['epc_sim']['eps_sim']['journal_log_file_name'] = 'EpsSimJournal.log'
        config_bdd['api']['epc_sim']['poscache_sim']['log_file'] = os.path.join(configuration['bdd_log_dir'], 'POSCacheSim.log')
        config_bdd['api']['epc_sim']['poscache_sim']['journal_log_file_name'] = 'POSCacheSimJournal.log'
        config_bdd['api']['epc_sim']['sigma']['log_file'] = os.path.join(configuration['bdd_log_dir'], 'SigmaSim.log')
        config_bdd['api']['nepsvcs_sim']['nep_server_port'] = int(configuration['nep_server_port'])
        config_bdd['api']['nepsvcs_sim']['nep_notification_server_port'] = int(configuration['nep_notification_server_port'])
        config_bdd['api']['nepsvcs_sim']['nep_services_dir'] = configuration['nep_services_dir']
        config_bdd['api']['stmapi_sim']['log_file'] = os.path.join(configuration['bdd_log_dir'], 'StmapiSim.log')
        config_bdd['api']['stmapi_sim']['server_log_file'] = os.path.join(configuration['bdd_log_dir'], 'StmapiSimServer.log')
        config_bdd['api']['kps_sim']['log_file'] = os.path.join(configuration['bdd_log_dir'], 'KPSSimulator.log')
        config_bdd['pos_resolution'] = configuration['pos_resolution']
        if config_bdd['pos_resolution'] == 1366:
            config_bdd['ws_data_dir'] = configuration['staging_data_dir_1366_pos']
        elif config_bdd['pos_resolution'] == 1920:
            config_bdd['ws_data_dir'] = configuration['staging_data_dir_1920_pos']
        config_bdd['pes_configuration_path'] = configuration['pes_configuration_path']

    with open(config_pathname_override, 'w', encoding='utf8') as file:
        content = json.dumps(config_bdd)
        file.write(content)
    print_success()
    return config_bdd


def start_apps(curr_root_path, config_bdd, configure_again, configuration):
    # Run Apps?
    if configure_again:
        configuration['start_apps'] = prompt_user_bool('Start Apps? (POSEngine, TeleQ, simulators...) y/n',
                                                       configuration['start_apps'])
    if configuration['start_apps']:
        from cfrpos.core.bdd_utils import bdd_environment

        # Run SCPOSServicesSimulator.exe.
        print_message("Starting SCPOSServicesSimulator...")
        from cfrpos.core.simulators.sc_sim import pos_services_control
        sc_sim = pos_services_control.PosServicesControl({**config_bdd, **config_bdd.get('api', {}).get('sc_sim', {})})
        assert bdd_environment.start_binary(sc_sim, configuration['rpos_env'], True), "POSServices (Site Controller) simulator not available."
        print_success()

        # Run ScanSimulator.
        print_message("Starting ScanSimulator...")
        from sim4cfrpos.api.scan_sim.scan_sim_control import ScanSimControl
        scan_sim = ScanSimControl({**config_bdd, **config_bdd.get('api', {}).get('scan_sim', {})})
        assert bdd_environment.start_script(scan_sim, configuration['rpos_env']), "Scan simulator not available."
        print_success()

        # Run SwipeSimulator.
        print_message("Starting SwipeSimulator...")
        from sim4cfrpos.api.swipe_sim.swipe_sim_control import SwipeSimControl
        swipe_sim = SwipeSimControl({**config_bdd, **config_bdd.get('api', {}).get('swipe_sim', {})})
        assert bdd_environment.start_script(swipe_sim, configuration['rpos_env']), "Swipe simulator not available."
        print_success()

        # Run CheckreaderSimulator.
        print_message("Starting CheckreaderSimulator...")
        from sim4cfrpos.api.checkreader_sim.check_reader_control import CheckReaderSimControl
        checkreader_sim = CheckReaderSimControl(config_bdd)
        assert bdd_environment.start_script(checkreader_sim, configuration['rpos_env']), "Checkreader simulator not available."
        print_success()

        # Run PrintSimulator
        print_message("Starting PrintSimulator...")
        from sim4cfrpos.api.print_sim.print_sim_control import PrintSimControl
        print_sim = PrintSimControl({**config_bdd, **config_bdd.get('api', {}).get('print_sim', {})})
        assert bdd_environment.start_script(print_sim, configuration['rpos_env']), "Print simulator not available."
        print_success()

        # Run EPCSimulator
        print_message("Starting EPC Simulator (EPS, POSCache and Sigma)...")
        from sim4cfrpos.api.epc_sim.electronic_payments_control import ElectronicPaymentsControl
        epc_sim = ElectronicPaymentsControl({**config_bdd, **config_bdd.get('api', {}).get('epc_sim', {})})
        assert bdd_environment.start_script(epc_sim, configuration['rpos_env']), "Electronic Payment Control simulator not available."
        print_success()

        # Run NEPServicesSimulator
        print_message("Starting NEPServicesSimulator...")
        from sim4cfrpos.api.nepsvcs_sim.nepsvcs_sim_control import NepSvcsSimControl
        nepsvcs_sim = NepSvcsSimControl({**config_bdd, **config_bdd.get('api', {}).get('nepsvcs_sim', {})})
        assert bdd_environment.start_script(nepsvcs_sim, configuration['rpos_env']), "NEP Services simulator not available."
        print_success()

        # Run StmapiSimulator.
        print_message("Starting StmapiSimulator...")
        from sim4cfrpos.api.stmapi_sim.stmapi_control import StmapiControl
        stmapi_simulator = StmapiControl({**config_bdd, **config_bdd.get('api', {}).get('stmapi_sim', {})})
        assert bdd_environment.start_script(stmapi_simulator, configuration['rpos_env']), "Stmapi simulator not available."
        print_success()

        # Run KPSSimulator.
        print_message("Starting KPSSimulator...")
        from sim4cfrpos.api.kps_sim.kps_sim_control import KPSSimControl
        kps_simulator = KPSSimControl({**config_bdd, **config_bdd.get('api', {}).get('kps_sim', {})})
        assert bdd_environment.start_script(kps_simulator, configuration['rpos_env']), "KPS simulator not available."
        print_success()

        # TeleQ
        print_message("Starting TeleQ...")
        from cfrpos.core.simulators.teleq.teleq_control import TeleQControl
        teleq = TeleQControl({**config_bdd, **config_bdd.get('api', {}).get('teleq', {})})
        assert bdd_environment.start_binary(teleq, configuration['rpos_env'], True), "TeleQ not available."
        print_success()

        # Run WincorEPSSimulator.exe.
        print_message("Starting Wincor EPS Protocol Simulator...")
        from sim4cfrpos.api.wincor_sim.wincor_sim_control import WincorSimControl
        wincor_eps_sim = WincorSimControl({**config_bdd, **config_bdd.get('api', {}).get('wincor_eps_sim', {})})
        assert bdd_environment.start_binary(wincor_eps_sim, configuration['rpos_env'], True), "Wincor EPS Protocol Simulator not available."
        print_success()

        # POSEngine
        print_message("Starting POSEngine...")
        from cfrpos.core.pos.pos_product import POSProduct
        if configuration['run_with_OpenCPPCoverage']:
            class PosProductWithCoverage(POSProduct):
                # Overriding 'start' method of PosControl to start POSEngine with OpenCPPCoverage
                def start(self):
                    open_cpp = os.path.join(curr_root_path, 'OpenCppCoverage_POSEngine.bat')
                    if not os.path.isfile(open_cpp):
                        raise Exception('ERROR: File {} not found.'.format(open_cpp))
                    binary_path = os.path.join(self.bin_dir, self.binary)
                    if not os.path.isfile(binary_path):
                        raise Exception('ERROR: File {} not found.'.format(binary_path))
                    process = subprocess.Popen([open_cpp, binary_path], cwd=self.bin_dir,
                                               creationflags=subprocess.CREATE_NEW_CONSOLE)
                    return process

            pos_with_coverage = PosProductWithCoverage(
                {**config_bdd, **config_bdd.get('api', {}).get('pos', {})}, scan_sim)
            assert bdd_environment.start_binary(pos_with_coverage, configuration['rpos_env'], True), "POSEngine not available."
        else:
            pos = POSProduct({**config_bdd, **config_bdd.get('api', {}).get('pos', {})}, scan_sim)
            assert bdd_environment.start_binary(pos, configuration['rpos_env'], True), "POSEngine not available."
        print_success()


def save_configuration(file_path, configuration):
    """ Save configuration to one_click_setup.json
    """
    print_message('Saving "one click setup" configuration to [{}]...'.format(file_path))
    config_dump_file_path_new = file_path + '.new'
    config_json = json.dumps(configuration)
    with open(config_dump_file_path_new, 'w', encoding='utf-8') as config_file:
        config_file.write(config_json)
    if os.path.isfile(config_dump_file_path_new):
        copy_replace(config_dump_file_path_new, file_path)
        os.remove(config_dump_file_path_new)
    print_success()


def run_tests(curr_root_path, configuration):
    # Run POS BDD tests
    if configuration['run_bdd_tests']:
        config_pathname = configuration['bdd_config_file']
        junit_pathname = os.path.join(configuration['bdd_log_dir'], 'junit')
        assert check_make_dir_with_access(junit_pathname), 'Creating junit JUnit report folder failed.'
        print_message('Running POS BDD tests.')

        arguments = ['behave',
                     '-D', 'bdd_config="' + config_pathname + '"',
                     '--tags=@pos', '--tags=~@waitingforfix', '--tags=~@manual',
                     '--junit',
                     '--junit-directory', junit_pathname]
        if configuration['dev_env']:
            subprocess.Popen(arguments, shell=True,
                             cwd=os.path.join(curr_root_path, 'package', 'cfrpos')).wait()
        else:
            subprocess.Popen(arguments, shell=True,
                             cwd=os.path.dirname(os.path.abspath(cfrpos.__file__))).wait()

        print_success()


# ----------------------------------------------------------------------
# Entry Point
# ----------------------------------------------------------------------
if __name__ == "__main__":
    root_path = os.path.abspath(os.path.dirname(os.path.realpath(__file__)))
    config_dump_file_path = os.path.join(root_path, 'one_click_setup.json')
    config = None

    args = parse_input_args(config_dump_file_path)
    config_dump_file_path = args.configuration
    if args.auto:
        AUTO_SCRIPT = True

    try:
        if args.install:
            install_prerequisites()
        else:
            install_prerequisites()
            import psutil
            import colorama
            # strip=False enables colors on GIT Bash console
            colorama.init(strip=False)

            reconfigure, config = load_configuration(config_dump_file_path)
            evaluate_environment(root_path, reconfigure, config)
            update_configuration_defaults(root_path, config)
            stop_apps(config)
            install_cfrpos_package(root_path, config)
            import cfrpos
            install_sim4cfrpos_package(root_path, config)
            import sim4cfrpos

            install_bdd_steps_features(root_path, reconfigure, config)
            extract_nep_services(root_path, reconfigure, config)
            update_runtime_configuration(reconfigure, config)
            update_node_type(config, reconfigure)
            stage_pos(root_path, config)
            install_pos(root_path, config)
            configure_pos(reconfigure, config)
            install_radio_bdd(reconfigure, config)
            install_logger_bdd(reconfigure, config)
            install_xml2dat(reconfigure, config)
            install_sc_pos_simulator(reconfigure, config)
            install_nepsvcs_simulator(reconfigure, config)
            install_wincor_simulator(reconfigure, config)
            bdd_config = build_bdd_config(root_path, config)
            start_apps(root_path, bdd_config, reconfigure, config)

            # Prompt to run POS BDD tests?
            if reconfigure:
                config['run_bdd_tests'] = prompt_user_bool(
                    'Run POS BDD tests? [behave -D bdd_config="config\\config.json"] y/n', config['run_bdd_tests'])
            save_configuration(config_dump_file_path, config)
            run_tests(root_path, config)

    except Exception as exception:
        print_failure(str(exception))
        if not AUTO_SCRIPT \
                and config is not None \
                and config.keys() != [] \
                and config.keys() != ['dev-env'] \
                and prompt_user_bool('Error occurred! Save configuration? y/n', True):
            save_configuration(config_dump_file_path, config)
        raise