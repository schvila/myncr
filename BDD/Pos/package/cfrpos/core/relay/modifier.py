__all__ = [
    "ModifierRelay"
]

import yattag

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from . import RelayFile


@wrap_all_methods_with_log_trace
class ModifierRelay(RelayFile):
    """
    Representation of the modifier relay file.
    """
    _pos_name = "modifier"
    _filename = "Modifier.xml"
    _default_version = 5
    _sort_rules = [
        ("ModifierRecs", [
            ("ModifierId", int)
        ])
    ]

    def contains_modifier_id(self, modifier_id: int) -> bool:
        """
        Check whether the relay file contains a modifier ID.

        :param modifier_id: Modifier ID to check.
        :return: Whether the modifier ID is present.
        """

        match = self._soup.find("ModifierId", string=str(modifier_id))
        return match is not None

    def create_modifier(self, modifier_id: int, modifier_level: int, description: str) -> None:
        """
        Create a modifier record.

        :param modifier_id: Modifier ID.
        :param modifier_level: Modifier level.
        :param description: Description.
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("ModifierId", modifier_id)
            line("DescriptionId", 0)
            line("ModifierLevel", modifier_level)
            line("Description", description)
            line("LockStatus", 0)

        self._append_tag(self._soup.RelayFile.ModifierRecs, doc)
