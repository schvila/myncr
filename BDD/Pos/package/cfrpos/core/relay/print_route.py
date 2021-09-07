__all__ = [
    "PrintRouteRelay"
]

import yattag

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from .. bdd_utils.errors import ProductError
from . import RelayFile


@wrap_all_methods_with_log_trace
class PrintRouteRelay(RelayFile):
    """
    Representation of the print route relay file.
    """
    _pos_name = "PrintRoute"
    _pos_reboot_required = True
    _filename = "PrintRoute.xml"
    _default_version = 10
    _sort_rules = [
        ("LogicalPrinters", [
            ("NormalReceiptPrintTypeGroupId", int)
        ])
    ]

    def _modify_active_printer(self, device_id: int, device_name: str, receipt_group_id: int) -> None:
        """
        Allows to modify the receipt printer record.

        :param device_id: Printer ID
        :param device_name: Printer name
        :param receipt_group_id: Group ID of receipt that is going to be printed
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("LogicalDeviceId", device_id)
            line("LogicalDeviceName", device_name)
            line("NormalReceiptPrintTypeGroupId", receipt_group_id)

        match_device_id = getattr(self._soup.RelayFile, 'LogicalPrinters').find('LogicalDeviceId', string=str(device_id))
        if match_device_id is not None:
            parent = self._find_parent('LogicalPrinters', 'LogicalDeviceId', device_id)
            self._modify_tag(parent, doc)
        else:
            raise ProductError("The receipt printer with id [{}] is not defined.".format(device_id))

    def contains_name_in_list(self, find_in_list: str, name: str) -> dict:
        """
        Checks if the name is in the list, and if yes returns the dictionary element which contains given name.
        Example: Checking if the receipt Rcpt1 is in the list available_receipts.

        :param find_in_list: List to search in
        :param name: Name to be checked
        """
        match_dict= {}
        for element in find_in_list:
            if name in element:
                match_dict = element

        return match_dict

    def set_receipt_active(self, receipts_available, receipt_name, device_id, device_name) -> None:
        """
        Allows to set desired receipt active, so it can be printed.

        :param receipts_available: List of already created receipts.
        :param receipt_name: Receipt name to be checked.
        :param device_id: Printer ID.
        :param device_name: Printer name.
        """
        if self.contains_name_in_list(receipts_available, receipt_name):
            receipt_data = self.contains_name_in_list(receipts_available, receipt_name)
            group_id = receipt_data[receipt_name]
        else:
            raise ProductError("There is no receipt [{}] created".format(receipt_name))

        self._modify_active_printer(device_id=device_id, device_name=device_name, receipt_group_id=group_id)
