__all__ = [
    "BarcodeRelay"
]

import yattag

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from . import RelayFile


@wrap_all_methods_with_log_trace
class BarcodeRelay(RelayFile):
    """
    Representation of the barcode relay file.
    """
    _pos_name = "barcodes"
    _filename = "Barcodes.xml"
    _default_version = 3
    _sort_rules = [
        ("BarcodeRecs", [
            ("POSCode", int),
            ("POSCodeLength", int),
            ("POSCodeType", int),
            ("UnitPackingID", int)
        ]),
         ("UnitPackingIDRecs", [
            ("UnitPackingID", int)
        ])
    ]

    def contains_unit_packing_id(self, unit_packing_id: int) -> bool:
        """
        Check whether the relay file contains a unit packing ID.

        :param unit_packing_id: ID to check.
        :return: Whether the ID is present.
        """
        match = self._soup.find("UnitPackingID", string=str(unit_packing_id))
        return match is not None

    def contains_unit_packing_id_in_section(self, relay_section: str, unit_packing_id: int) -> bool:
        """
        Check whether the relay file contains a unit packing ID.

        :param relay_section: This specifies the section of the relay to search, it is necessary because a relay file
        can reuse the same column names through multiple sections
        :param unit_packing_id: ID to check.
        :return: Whether the ID is present.
        """
        match = getattr(self._soup.RelayFile, relay_section).find("UnitPackingID", string=str(unit_packing_id))
        return match is not None

    def contains_item_id(self, item_id: int) -> bool:
        """
        Check whether the relay file contains an object ID.

        :param item_id: Item ID to check.
        :return: Whether the item ID is preseent.
        """

        matches = self._soup.find_all("ObjectID", string=str(item_id))
        return matches is not None

    def contains_item_id_in_section(self, relay_section: str, item_id: int) -> bool:
        """
        Check whether the relay file contains an object ID.

        :param relay_section: This specifies the section of the relay to search, it is necessary because a relay file
        can reuse the same column names through multiple sections
        :param item_id: Item ID to check.
        :return: Whether the item ID is preseent.
        """
        match = getattr(self._soup.RelayFile, relay_section).find("ObjectID", string=str(item_id))
        return match is not None

    def create_barcode(self, item_id: int, modifier1_id: int, barcode: str, unit_packing_id: int) -> None:
        """
        Create or modify a barcode record.

        :param item_id: Item ID
        :param modifier1_id: Modifier1 ID.
        :param barcode: Barcode.
        :param unit_packing_id: Unit packing ID.
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("POSCode", int(barcode))
            line("POSCodeLength", len(barcode))
            line("POSCodeType", 1)
            line("UnitPackingID", unit_packing_id)
            line("ObjectID", item_id)
            line("Modifier1", modifier1_id)
            line("Modifier2", 0)
            line("Modifier3", 0)

        if self.contains_item_id_in_section('BarcodeRecs', item_id):
            parent = self._find_parent('BarcodeRecs', 'ObjectID', item_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.BarcodeRecs, doc)

    def create_unit_packing(self, unit_packing_id: int, pack_quantity: int, description: str) -> None:
        """
        Create or modify a unit packing record.

        :param unit_packing_id: Unit packing ID.
        :param pack_quantity: Pack quantity.
        :param description: Description.
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("UnitPackingID", unit_packing_id)
            line("PackQuantity", pack_quantity)
            line("Description", description)

        if self.contains_unit_packing_id_in_section('UnitPackingIDRecs', unit_packing_id):
            parent = self._find_parent('UnitPackingIDRecs', 'UnitPackingID', unit_packing_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.UnitPackingIDRecs, doc)