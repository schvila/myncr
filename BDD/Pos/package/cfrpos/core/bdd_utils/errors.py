"""
This module contains EVCore's custom exceptions.
"""

__all_ = [
    "ComparisonError",
    "LoggedError",
    "NetworkError",
    "ProductError"
]

from . logging_utils import get_ev_logger, wrap_all_methods_with_log_trace

logger = get_ev_logger()


@wrap_all_methods_with_log_trace
class LoggedError(Exception):
    """An error that should be logged to the main log file."""

    def __init__(self, message, name=None, *args, **kwargs):
        if name:
            message = "{}: {}".format(name, message)

        logger.exception(message)
        super().__init__(message, *args, **kwargs)


@wrap_all_methods_with_log_trace
class ComparisonError(LoggedError):
    """An error during comparison, with optional logging of the values compared."""

    def __init__(self, message, expected, actual, name=None, location=None, *args, **kwargs):
        """
        :param str message: Message to log and include in raised exception
        :param expected: Expected value
        :param actual: Actual value
        :param str name: Optional prefix for the log message
        :param args: Pass-through to super()
        :param kwargs: Pass-through to super()
        """

        logger.debug("Expected comparison data: {}".format(expected))
        logger.debug("Actual comparison data: {}".format(actual))
        super().__init__(message, name, *args, **kwargs)


@wrap_all_methods_with_log_trace
class ProductError(LoggedError):
    """An error that occurs within an RPOS product."""

    def __init__(self, message, name=None, *args, **kwargs):
        """
        :param str message: Message to log and include in raised exception
        :param str name: Optional prefix for the log message
        :param args: Pass-through to super()
        :param kwargs: Pass-through to super()
        """

        logger.debug(message)
        super().__init__(message, name, *args, **kwargs)


@wrap_all_methods_with_log_trace
class NetworkError(LoggedError):
    """An error that occurs in network communication."""

    def __init__(self, message, name=None, *args, **kwargs):
        """
        :param str message: Message to log and include in raised exception
        :param str name: Optional prefix for the log message
        :param args: Pass-through to super()
        :param kwargs: Pass-through to super()
        """

        logger.debug(message)
        super().__init__(message, name, *args, **kwargs)
