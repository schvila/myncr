__all__ = [
    "LockedRetailItemRelay"
]

import yattag

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from . import RelayFile


@wrap_all_methods_with_log_trace
class LockedRetailItemRelay(RelayFile):
    """
    Representation of the locked retail items relay file.
    """
    _pos_name = "LockedRetailItem"
    _pos_reboot_required = True
    _filename = "LockedRetailItem.xml"
    _default_version = 1
    _sort_rules = [
        ("LockedRetailItemRecs", [
            ("ItemId", int),
            ("Modifier1Id", int),
            ("Modifier2Id", int),
            ("Modifier3Id", int)
        ])
    ]

    def contains_item_id(self, item_id: int) -> bool:
        """
        Check whether the relay file contains an item ID.

        :param item_id: Item ID to check.
        :return: Whether the item ID is present.
        """

        match = self._soup.find("ItemId", string=str(item_id))
        return match is not None

    def create_locked_sale_item(self, item_id: int, modifier1_id: int) -> None:
        """
        Create a locked retail item record or modifies an existing one.

        :param item_id: Item ID.
        :param modifier1_id: Modifier1 ID.
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("ItemId", item_id)
            line("Modifier1Id", modifier1_id)
            line("Modifier2Id", 0)
            line("Modifier3Id", 0)

        if self.contains_item_id(item_id):
            parent = self._find_parent('LockedRetailItemRecs', 'ItemId', item_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.LockedRetailItemRecs, doc)

    def remove_locked_sale_item(self, item_id: int) -> None:
        """
        Remove a locked retail item record if exists.

        :param item_id: Item ID.
        """

        if self.contains_item_id(item_id):
            parent = self._find_parent('LockedRetailItemRecs', 'ItemId', item_id)
            self._remove_tag(parent)