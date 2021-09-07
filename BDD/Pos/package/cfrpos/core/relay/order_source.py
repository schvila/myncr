__all__ = [
    "OrderSourceRelay"
]

import yattag

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from . import RelayFile


@wrap_all_methods_with_log_trace
class OrderSourceRelay(RelayFile):
    """
    Representation of the order source relay file.
    """
    _pos_name = "OrderSource"
    _pos_reboot_required = True
    _filename = "OrderSource.xml"
    _default_version = 1
    _sort_rules = [
        ("OrderSourceRecs", [
            ("ExternalId", str),
            ("DeferAgeVerificationFlag", int),
        ])
    ]

    def define_order_source_behavior(self, external_id: str, defer_verification: bool) -> None:
        """
        Creates a record defining the pos connect age restriction behavior of orders coming from a source specified by
        its external ID or modifies an existing record.

        :param external_id: ID of the order source whose behavior will be set.
        :param defer_verification: True if all age restricted items in the pos connect request should be accepted and
        verified later, False if the order should get rejected if it contains AR items.
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("ExternalId", external_id)
            line("DeferAgeVerificationFlag", 1 if defer_verification else 0)

        if self.contains_id_in_section('OrderSourceRecs', 'ExternalId', external_id):
            parent = self._find_parent('OrderSourceRecs', 'ExternalId', external_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.OrderSourceRecs, doc)
            self.mark_dirty()
