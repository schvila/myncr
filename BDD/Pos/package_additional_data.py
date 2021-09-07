import os
import stat
import shutil
import tempfile

def copy_writable(src, dst):
    shutil.copy(src, dst)
    

def copy_writable_file(src_dir, dst_dir, file_name):
    copy_writable(os.path.join(src_dir, file_name), os.path.join(dst_dir, file_name))

def on_rm_error( func, path, exc_info):
    print('Adding write permission to file {}'.format(path))
    os.chmod(path, stat.S_IWRITE)

print('Packaging BDD scripts')

curr_path = os.path.abspath(os.path.dirname(os.path.realpath(__file__)))
temp_path = os.path.join(tempfile.mkdtemp())
os.makedirs(os.path.join(temp_path, 'config', 'data'))
setup_path = os.path.join(os.path.abspath(os.path.join(curr_path ,'../../../..')), 'Setup/6.1/ISSETUPFILES')

try:
    # Copy all files
    copy_writable_file(os.path.join(curr_path, 'config'), os.path.join(temp_path, 'config'), 'config.json')
    copy_writable(os.path.join(curr_path, 'config', 'logging_template.json'), os.path.join(temp_path, 'config', 'logging.json'))
    copy_writable_file(setup_path, os.path.join(temp_path, 'config', 'data'), 'DriversLicenseValidation.xml')
    
    # Generate final zip archive
    shutil.make_archive('dist/bddtests', 'zip', temp_path)

finally:
    shutil.rmtree(temp_path, onerror = on_rm_error)

print('Done')

