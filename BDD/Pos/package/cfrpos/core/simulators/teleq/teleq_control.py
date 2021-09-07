import os
import psutil
from cfrpos.core.bdd_utils.logging_utils import get_ev_logger, wrap_all_methods_with_log_trace

TELEQ_DEFAULT_BINARY = 'TeleQ.exe'
TELEQ_DEFAULT_BIN_DIR = 'C:\\Program Files\\Radiant\\Fastpoint\\Bin'


@wrap_all_methods_with_log_trace
class TeleQControl:
    def __init__(self, config: dict):
        """
        The constructor of this controller.

        :param dict config: Dictionary which contains address of the simulator, its port, name of the binary,
        location of the binary folder and optionally the path to the python script
        """
        self.logger = get_ev_logger()
        self._bin_dir = config.get('bin_dir', TELEQ_DEFAULT_BIN_DIR)
        self._binary = config.get('binary', TELEQ_DEFAULT_BINARY)

    @property
    def binary(self):
        """Name of the binary required by this controller."""
        return self._binary

    @property
    def bin_dir(self):
        """Name of the folder containing the required binary."""
        return self._bin_dir

    def is_active(self):
        for process in psutil.process_iter():
            try:
                if process.name().upper() == "TELEQ.EXE":
                    return True
            except psutil.NoSuchProcess:
                pass
        return False

    def __str__(self):
        return 'TeleQ.exe'
