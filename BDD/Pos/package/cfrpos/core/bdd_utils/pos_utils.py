"""The goal of this module is to provide helper methods, which will be commonly used among POS objects."""
__all__ = [
    "POSUtils"
]

from decimal import Decimal
from typing import Union
from lxml import etree

from . logging_utils import wrap_all_methods_with_log_trace


@wrap_all_methods_with_log_trace
class POSUtils:
    """Wraps all helper methods."""

    @staticmethod
    def convert_pos_amount_to_float(amount: Union[int, str, tuple, Decimal, None]) -> float:
        """
        Tries to convert the given POS amount into the float value.

        :param amount: POS amount which should be converted into float value.
        :return: float representation of the provided POS amount. Zero, if the value is not convertible.
        :rtype: float
        """
        if amount is None:
            return 0.0
        try:
            return float(amount) / 10000.0
        except Exception:
            return 0.0

    @staticmethod
    def convert_float_to_pos_amount(amount: Union[float, int, str, tuple, Decimal, None]) -> int:
        """
        Tries to convert the given amount into the pos amount value.

        :param amount: float which should be converted into pos amount value.
        :return: int representation of the provided POS amount. Zero, if the value is not convertible.
        :rtype: int
        """
        if amount is None:
            return 0
        try:
            return int(float(amount) * float(10000.0))
        except Exception:
            return 0

    @staticmethod
    def first_or_default(array: list, default: Union[str, int, float]) -> Union[str, int, float]:
        """
        Returns the first value from the given list. If there is no item, then the default value is returned instead.

        :param list array: List of the values.
        :param default: The default value which will be used in case of the empty list.
        :return: The first value of the list or the default value if the list is empty.
        :rtype: Any of str, int or float
        """
        if array is not None and len(array) > 0:
            return array[0]
        else:
            return default

    @staticmethod
    def get_nvp_info(root: etree._Element, xpath: str) -> list:
        """
        Method to parse all available NVPs and their attributes based on the given xpath. The result is saved as a list of dicts.

        :param root: Transaction xml to be parsed.
        :param xpath: xpath to the nvp elements.
        """
        nvps = root.xpath(xpath) if type(root.xpath(xpath)) == list else None
        list_of_nvps = []
        if nvps is not None:
            for nvp in nvps:
                attrs = {}
                for att in nvp.attrib:
                    attrs[att] = nvp.attrib[att]
                attrs['text'] = nvp.text
                list_of_nvps.append(attrs)
        return list_of_nvps
 