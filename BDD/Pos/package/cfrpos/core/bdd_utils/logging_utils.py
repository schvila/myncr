"""
Holds utility functions for logging different messages
"""

__all__ = [
    "EVCoreLogger",
    "LOG_LEVEL_TRACE",
    "get_ev_logger",
    "configure_ev_logger",
    "log_formatter",
    "log_trace",
    "wrap_all_methods_with_log_trace"
]

import os
import logging
import functools
import inspect
from typing import Union

LOG_LEVEL_TRACE = 5


class EVCoreLogger(logging.getLoggerClass()):
    """
    Wrapper to allow adding the "TRACE" level to the logger
    """
    def __init__(self, name, level=logging.NOTSET):
        super().__init__(name, level)

        logging.addLevelName(LOG_LEVEL_TRACE, "TRACE")

    def trace(self, msg, *args, **kwargs):
        if self.isEnabledFor(LOG_LEVEL_TRACE):
            self._log(LOG_LEVEL_TRACE, msg, args, **kwargs)


class EVCoreLoggingFormatter(logging.Formatter):
    # Using a different format for TRACE logs to avoid having a ton of lines mentioning the location
    # of the log_trace function
    trace_fmt = "{asctime} | {levelname} | {message}"

    def __init__(self,
                 fmt="{asctime} | {levelname} | [{filename}:{lineno} - {funcName}] {message}",
                 datefmt="%Y-%m-%d %H:%M:%S",
                 style="{"):
        logging.Formatter.__init__(self, fmt, datefmt, style)

    def format(self, record):

        if record.levelno == LOG_LEVEL_TRACE:
            orig_format = self._fmt
            orig_style_format = self._style._fmt
            self._fmt = EVCoreLoggingFormatter.trace_fmt
            self._style._fmt = EVCoreLoggingFormatter.trace_fmt
            result = logging.Formatter.format(self, record)
            self._fmt = orig_format
            self._style._fmt = orig_style_format
        else:
            result = logging.Formatter.format(self, record)

        return result


log_formatter = EVCoreLoggingFormatter()


def configure_ev_logger(log_file: Union[str, None]=None,
                        log_console: Union[bool, None]=False,
                        log_level: Union[str, None]=None):
    logger = get_ev_logger()
    logger.handlers.clear()

    if log_level is None:
        logger.setLevel(logging.INFO)
    elif str(log_level).lower() == 'trace':
        logger.setLevel(LOG_LEVEL_TRACE)
    elif str(log_level).lower() == 'debug':
        logger.setLevel(logging.DEBUG)
    elif str(log_level).lower() == 'info':
        logger.setLevel(logging.INFO)
    elif str(log_level).lower() == 'warning':
        logger.setLevel(logging.WARNING)
    else:
        logger.setLevel(logging.ERROR)

    if log_console:
        console = logging.StreamHandler()
        console.setFormatter(log_formatter)
        logger.addHandler(console)
    if log_file is not None:
        file_log = logging.FileHandler(log_file)
        file_log.setFormatter(log_formatter)
        logger.addHandler(file_log)


def get_ev_logger():
    """
    Simple abstraction of logging.getLogger() so we can more easily
    make sweeping changes in the future if necessary.

    :return: Singleton logger
    :rtype: EVCoreLogger
    """
    cls = logging.getLoggerClass()

    if cls is not EVCoreLogger:
        logging.setLoggerClass(EVCoreLogger)
    return logging.getLogger("EVLogger")


def log_trace(func):
    """Decorates a function to log trace information when the config file's
    "trace_logging" attribute is set to true

    :param func: Function to decorate
    :return: Decorated function
    :rtype: function
    """
    @functools.wraps(func)
    def _log_trace(*args, **kwargs):
        logger = get_ev_logger()

        file_name = os.path.basename(inspect.getsourcefile(func))
        logger.trace('>>>: [%s - %s], [%s], [%s]' % (file_name, func.__name__, args, kwargs))
        ret = func(*args, **kwargs)
        logger.trace('<<<: [%s - %s], [%s]' % (file_name, func.__name__, ret))
        return ret

    return _log_trace


# TODO: Need to figure out how to have the wrapper work with @staticmethod and @classmethod
def wrap_all_methods_with_log_trace(cls):
    """
    Allows decorating a class such that all methods in the class will be wrapped
    with the log_trace wrapper

    Note: This will not wrap static or class methods as log_trace needs to be applied prior to them.
    As such, you must explicitly wrap static and class methods with log_trace within the class.
    Be sure to place "@log_trace" just above the method def and underneath the "@staticmethod" or
    "@classmethod" line like so:

        @staticmethod
        @log_trace
        def some_function_name():
            ...

    :param cls: Class to decorate the methods of
    :return: Decorated class
    :rtype: class
    """
    for key in cls.__dict__:
        value = getattr(cls, key)

        if callable(value):
            if inspect.isroutine(value):
                binded_value = cls.__dict__[key]
                if not isinstance(binded_value, staticmethod) and not isinstance(binded_value, classmethod):
                    setattr(cls, key, log_trace(value))

    return cls
