def _generator_dict_extract(key, dictionary: dict):
    """Iterate over dictionary

    :param key: Key to search for
    :type key: Any key type
    :param dictionary: Dictionary to search through
    :type dictionary: dict
    :rtype: Any dictionary value

    Generator iterates over dictionary with nested dictionaries and lists in
    search for a key. Yields the found values.
    """

    if hasattr(dictionary, 'items'):
        for k, v in dictionary.items():
            if k == key:
                yield v

            if isinstance(v, dict):
                for result in _generator_dict_extract(key, v):
                    yield result
            elif isinstance(v, list):
                for d in v:
                    for result in _generator_dict_extract(key, d):
                        yield result


def _compare(value_1, value_2) -> bool:
    """Compares any two values iteratively

    :param value_1: First value, subset data with support for wildcard
    :type value_1: Any basic or comperable type
    :param value_2: Second value, the superset data
    :type value_2: Any basic or comperable type
    :return: True if the same, false if not
    :rtype: bool

    Compares two values of any basic type. The types of value_1 and value_2
    must be the same with the exception of wildcard '*' for value_1
    """

    if isinstance(value_1, str) and value_1 == '*':
        return True
    elif isinstance(value_1, (int, float)) and isinstance(value_2, (int, float)):
        return value_1 == value_2 # Special case for numbers (int and float) 
    elif type(value_1) != type(value_2):
        return False
    elif isinstance(value_1, dict):
        return _compare_dict(value_1, value_2)
    elif isinstance(value_1, list):
        return _compare_list(value_1, value_2)

    return value_1 == value_2


def _compare_dict(dict_1: dict, dict_2: dict) -> bool:
    """Compares two dictionaries

    :param dict_1: Dictionary from subset with support for wildcard
    :type dict_1: dict
    :param dict_2: Dictionary from superset
    :type dict_2: dict
    :return: True if the same, false if not
    :rtype: bool

    All values must be the same.
    Use wildcard '*' for exceptions.
    """

    if '*' not in dict_1:
        if len(dict_1) != len(dict_2):
            return False

    for key, value in dict_1.items():
        if isinstance(key, str) and key == '*':
            continue
        elif key not in dict_2:
            return False

        superset_value = dict_2[key]
        if isinstance(value, str) and value == '*':
            continue
        elif not _compare(value, superset_value):
            return False

    return True


def _compare_list(list_1: list, list_2: list) -> bool:
    """Compares two lists

    :param list_1: List from subset with support for wildcard
    :type list_1: list
    :param list_2: List from superset with support for wildcard
    :type list_2: list
    :return: True if the same, false if not
    :rtype: bool

    All values must be the same. The order does not matter.
    Use wildcard '*' for exceptions.

    Note: We have to use two forcycles, since the value
    order does not matter and the list may not be sortable.
    """

    if '*' not in list_1:
        if len(list_1) != len(list_2):
            return False

    for item_1 in list_1:
        if isinstance(item_1, str) and item_1 == '*':
            continue

        for item_2 in list_2:
            if _compare(item_1, item_2):
                break
        else:
            return False

    return True


def _relax_value(value):
    """Adds wildcard '*' to list or dict recursively

    :param value: Value to be relaxed
    :type value: Any, but checks for list and dict
    """
    if isinstance(value, dict):
        for v in value.values():
            _relax_value(v)

        if '*' not in value:
            value['*'] = '*'

    elif isinstance(value, list):
        for item in value:
            _relax_value(item)

        if '*' not in value:
            value.append('*')


def contains_dict_subset(subset: dict, superset: dict) -> dict:
    """Compare two dictionaries

    :param subset: Subset containing key-value pairs
    :type subset: dict
    :param superset: The bigger dictionary, the one that is searched through
    :type superset: dict
    :return: Not found key-value pairs
    :rtype: dict

    Function takes dictionary subset and checks, whether all the key-value
    pairs are present in dictionary superset.
    It returns all NOT found items. If all items found, returns empty dictionary.

    It searches using top-level keys in subset and compares it to any
    nested key in the superset.
    The values of dictionary subset can be any basic type - number, string, list
    or dictionary.

    The compared value types must match. In case of string or number the values are
    just compared. In case of a list or a dictionary, ALL the items must match.

    Wildcard "*" can be used to allow for extra items or values that does not matter.

    Some examples pof wildcard usage:
    {'A': 1, 'B': 2, 'C': '*'}
        = The value of C does not matter
    {'T': {'A': 1, 'B': 2, '*': '*'}}
        = The superset must contain 'T' with 'A' and 'B', other values in 'T' are ignored
    {'T': ['A', 'B', '*']}
        = The superset must contain 'T' with list containing 'A' and 'B',
        other values in list are ignored
    """

    not_found = {}
    for key_subset, value_subset in subset.items():
        for value_superset in _generator_dict_extract(key_subset, superset):
            if _compare(value_subset, value_superset):
                break
        else:
            not_found[key_subset] = value_subset

    return not_found


def check_dict_contains_element_value(element: str, value: str, last_response: dict):
    """ Checks that dict contains element with value.
    :param element: element name
    :type element: str
    :param value: value of element
    :type element: str
    :param last_response: dictionary, where pair {element: value} is searching
    :type last_response: dict
    :return : pair (element_value json, not_found_pair)
    """
    if value.replace('.','',1).isdigit():
        value = float(value)
    expected_data = {element: value}
    not_found = contains_dict_subset(expected_data, last_response.data)
    return (expected_data, not_found)


def relax_dict_subset(dictionary: dict):
    """Relaxes json dictionary recursively by adding wildcards '*'

    :param dictionary: Dictionary, where values should be relaxed with '*'
    :type dictionary: dict
    """
    for value in dictionary.values():
        _relax_value(value)
