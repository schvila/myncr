import os
from os import path
import stat
import time
import json
import psutil
import shutil
import subprocess
import importlib.util
from . errors import *


def find_process(process_name):
    if process_name is None:
        return None
    process_name = process_name.upper()
    for process in psutil.process_iter():
        try:
            if process.name().upper() == process_name:
                return process
        except psutil.NoSuchProcess:
            pass
    return None


def start_binary(control, environment: dict, start_if_not_started=True):
    """
    Make sure that a binary required by BDD is running.
    :param control: Control Python object of the binary. The object is expected to include properties:
    binary, bin_dir, and functions is_active(), __str__(). Function start() will be used if available.
    If binary is None, it is assumed that there is no process associated with the control.
    :param start_if_not_started: True to start the binary if it is not running.
    :param environment: Dictionary with the current environment variables. You can update set an example PATH in it.y
    """
    started = False
    binary_path = path.join(control.bin_dir, control.binary)
    if control.binary is None and control.is_active():
        started = True
    elif find_process(control.binary):
        started = wait_for_process_start(find_process(control.binary), control, timeout=10)
    elif not start_if_not_started:
        print('{} is not started'.format(control))
    elif binary_path is not None and not path.isfile(binary_path):
        print('Binary of {} not found (binary: [{}])'.format(control, binary_path))
    else:
        process = None
        if 'start' in dir(control):
            print('Starting {} (binary: [{}]).'.format(control, binary_path))
            process = control.start(environment)
        else:
            print('Starting {} directly (binary: [{}]).'.format(control, binary_path))
            os.chdir(control.bin_dir)
            info = subprocess.STARTUPINFO()
            info.dwFlags = subprocess.STARTF_USESHOWWINDOW
            # 6 means SW_MINIMIZE
            info.wShowWindow = 6
            process = subprocess.Popen([control.binary], cwd=control.bin_dir, startupinfo=info, env=environment)
        started = wait_for_process_start(process, control)

        # because we are using popen quite often we cannot rely on garbage collector
        #       -> it can lead to "Invalid handle error"
        if process is not None:
            del process
    return started


def stop_binary(control, stop_if_running=True):
    """
    Make sure that a binary required by BDD is stopped or closed.
    :param control: Control Python object of the binary. The object is expect to include functions __str__(). Function close() and stop() will be used if available.
    :param stop_if_running: True to start the binary if it is not running.
    """
    stopped = False
    if control is not None:
        if 'close' in dir(control):
            print('Closing {}'.format(control))
            stopped = control.close()

        process = find_process(control.binary)
        if process is not None:
            if stop_if_running:
                if 'stop' in dir(control):
                    print('Stopping {}'.format(control))
                    stopped = control.stop()
                else:
                    print('Stop not supported for {}'.format(control))

    return stopped


def start_script(control, environment: dict):
    """
    Make sure that a simulator server script required by BDD is running.
    :param control: Control Python object of the server. The object is expected to include functions:
    is_active() and __str__(). Function start() will be used if available.
    :param environment: Dictionary with the environmental variables
    """
    started = None
    process = None
    print('Starting {} (server script: [{}]).'.format(control, control.script_path))
    process = control.start(environment)
    started = wait_for_process_start(process, control)

    # because we are using popen quite often we cannot rely on garbage collector
    #       -> it can lead to "Invalid handle error"
    if process is not None:
        del process
    return started


def wait_for_process_start(process, control, timeout=120):
    """
    Wait for a given process to become active, used by simulators running from binaries or scripts
    :param process: Process for which to wait and periodicaly prompt its status
    :param control: Control python object of the server
    :param timeout: Controls how long the method should wait for the process to start
    :rtype: Bool
    :return: Whether or not the process became active within the timeout frame
    """

    active = control.is_active()
    if active:
        print('Process {} is up and running'.format(str(control)))
    else:
        timer_start = time.perf_counter()
        elapsed = 0

        while not active and elapsed < timeout:
            if isinstance(process, psutil.Popen) and process.returncode:
                print('Process of {} terminated prematurely (process id {}) with return code {} at {} seconds.'.format(
                    str(control), process.pid, process.returncode, elapsed))
                break
            print('Waiting for {} to become active (process id {}), elapsed {} seconds.'.format(
                str(control), process.pid, elapsed))
            time.sleep(5)
            elapsed = time.perf_counter() - timer_start
            if isinstance(process, psutil.Popen):
                process.poll()
            active = control.is_active()

        if not active:
            print('{} did not respond in {} seconds.'.format(str(control), elapsed))
        else:
            print('{} is up and running after {} seconds.'.format(str(control), elapsed))
    return active


def read_bdd_config(filename):
    config = None
    if filename is None:
        print('Config file not defined.')
    else:
        filepath = path.normpath(filename)
        if not path.exists(filepath):
            print('Config file [{}] not found.'.format(filepath))
        else:
            with open(filepath) as json_config_file:
                config = json.load(json_config_file)

            # defaults
            if 'bin_dir' not in config:
                config['bin_dir'] = 'C:\\Program Files\\Radiant\\Fastpoint\\bin'

            # Hardcoded paths required by POS due to various harcoded settings
            if 'data_dir' not in config:
                config['data_dir'] = 'C:\\Program Files\\Radiant\\Fastpoint\\data'
            if 'media_dir' not in config:
                config['media_dir'] = 'C:\\Program Files\\Radiant\\Fastpoint\\media'
    return config


def _is_relaydat_xml_file(file_path):
    name, ext = os.path.splitext(file_path)
    if ext.lower() != '.xml':
        return False
    with open(file_path, mode='r', encoding='utf8') as file:
        if file.readline().find('<RelayFile>') < 0 \
                and file.readline().find('<RelayFile>') < 0:
            return False
    return True


def _deploy_data_dir(target, source, copy_function, copy_function_parameters, xml2relaydat_tool=None):
    if path.isdir(target):
        files = os.listdir(target)
        for file in files:
            filepath = path.join(target, file)
            try:
                os.chmod(filepath, stat.S_IWRITE | stat.S_IREAD)
                if os.path.isdir(filepath):
                    shutil.rmtree(filepath)
                else:
                    os.remove(filepath)
            except OSError as e:
                print('Removing a file [{}] failed with [{}].'.format(filepath, e))
                return False
    else:
        try:
            os.makedirs(target)
        except os.OSError as e:
            print('Making a dir [{}] failed with [{}].'.format(target, e))
            return False
    try:
        os.chmod(target, stat.S_IWRITE | stat.S_IREAD)
    except Exception as e:
        print('Directory [{}] cannot be accessed for reading and/or writing ({}).'.format(target, e))
        return False

    files = os.listdir(source)
    for file in files:
        src_file_path = path.join(source, file)
        tgt_file_path = path.join(target, file)

        if _is_relaydat_xml_file(src_file_path):
            if xml2relaydat_tool is None or not os.path.exists(xml2relaydat_tool):
                print('File [{}] is an XML version of a relay file but conversion tool [{}] is not available.'.format(src_file_path, xml2relaydat_tool))
                return False
            def_name, ext = os.path.splitext(file)

            # Exceptions in RelayFile naming.
            if (def_name.lower() == 'systemframes') or (def_name.lower() == 'systemframescss'):
                def_name = 'FramesX_ver15'
            elif def_name.lower() == 'systemframeswide':
                def_name = 'FramesX_ver19'
                tgt_file_path = target + '\\SystemFrames.xml'

            process = subprocess.Popen([
                    xml2relaydat_tool,
                    '/xml2dat',
                    '/embdef:{}'.format(def_name),
                    '/i:{}'.format(src_file_path),
                    '/o:{0}.dat'.format(os.path.splitext(tgt_file_path)[0])])
            if process.wait() != 0:
                print('Converting file [{}] using relay definition [{}] failed.'.format(src_file_path, def_name))
                return False
        else:
            try:
                copy_function(tgt_file_path, src_file_path, copy_function_parameters)
            except Exception as e:
                print('Copying a file [{}] to [{}] failed with [{}].'.format(src_file_path, tgt_file_path, e))
                return False

    return True


def _copy_file(tgt, src, params):
    if os.path.isdir(src):
        shutil.copytree(src, tgt)
    else:
        shutil.copy(src, tgt)
    os.chmod(tgt, stat.S_IWRITE | stat.S_IREAD)


def deploy_data(bdd_config, data_src=None, media_src=None):
    if data_src is None:
        data_src = path.join(path.join(bdd_config['bdd_dir'], 'config'), 'data')
    if not _deploy_data_dir(bdd_config['data_dir'], data_src, _copy_file, None, os.path.join(bdd_config['bin_dir'], 'xml2relaydat.exe')):
        return False

    if media_src is None:
        media_src = path.join(path.join(bdd_config['bdd_dir'], 'config'), 'media')
    if not _deploy_data_dir(bdd_config['media_dir'], media_src, _copy_file, None):
        return False

    return True

def table_to_str(table):
    """
    Helper method to convert a context.table to a string so it can be passed as an argument to a substep and processed
    as a table there again.
    """
    result = ''
    if table.headings:
        result = '|'
    for heading in table.headings:
        result += heading + '|'
    result += '\n'
    for row in table.rows:
        if row.cells:
            result += '|'
        for cell in row.cells:
            result += cell + '|'
        result += '\n'
    return result