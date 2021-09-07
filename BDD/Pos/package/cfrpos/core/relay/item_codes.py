__all__ = [
    "ItemCodesRelay"
]

import yattag
from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from . import RelayFile


@wrap_all_methods_with_log_trace
class ItemCodesRelay(RelayFile):
    """
    Representation of the ItemCodes relay file.
    """
    _pos_name = "ItemCodes"
    _filename = "ItemCodes.xml"
    _default_version = 3
    _sort_rules = [
        ("ExternalCodes", [
            ("ItemId", int)
        ])]

    def create_item_external_code(self, item_id: int, external_id: str) -> None:
        """
        Create or modify an external code for item with given ID.

        :param item_id: Item ID.
        :param external_id: External ID.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("ItemId", item_id)
            line("ExternalId", external_id)

        if self.contains_id_in_section('ExternalCodes', 'ItemId', item_id):
            parent = self._find_parent('ExternalCodes', 'ItemId', item_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.ExternalCodes, doc)
