from typing import Callable
import time


def timeouter(function: Callable[[], any], timeout: float, *arguments, expected_result: any=True, result_comparator: Callable[[any], bool]=None) -> bool:
    """Helper function for the repeating timeout code template.
    Take a function and repeat it until the return value matches expected_result or until the timeout is reached.

    :param function: Function that should be repeated, must return value convertible to bool and have no parameters
    :param timeout: Timeout in seconds
    :param expected_result: Expected result of the called function.
    :param arguments: Arguments that function needs to be called with.
    :param result_comparator: Function that will be called to validate that the result is what we expected.
    :return: Result returned byt the input function
    """
    start_time = time.perf_counter()
    duration = 0
    if arguments is None:
        result = function()
    else:
        result = function(*arguments)

    def is_expected_result(result: any) -> bool:
        if result_comparator is not None:
            return result_comparator(result)
        else:
            return result == expected_result

    while not is_expected_result(result) and duration < timeout:
        time.sleep(0.2)
        if arguments is None:
            result = function()
        else:
            result = function(*arguments)
        duration = time.perf_counter() - start_time
    return result
