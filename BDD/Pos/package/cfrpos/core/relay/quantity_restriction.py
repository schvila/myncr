__all__ = [
    "QuantityRestrictionRelay"
]

import yattag
import bs4

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from . import RelayFile


@wrap_all_methods_with_log_trace
class QuantityRestrictionRelay(RelayFile):
    """
    Representation of the quantity restriction relay file.
    """
    _pos_name = "QuantityRestriction"
    _filename = "QuantityRestriction.xml"
    _pos_reboot_required = True
    _default_version = 1
    _sort_rules = [
        ("SalesQuantityAttributes", [
            ("SalesQuantityId", int),
            ("Text", str)
        ]),
         ("SalesQuantityRestrictions", [
             ("RetailItemGroupId", int),
             ("SalesQuantityId", int),
             ("TransactionLimit", int)
         ]),
         ("RetailItemSalesQuantityAttributes", [
             ("ItemId", int),
             ("Modifier1Id", int),
             ("Modifier2Id", int),
             ("Modifier3Id", int),
             ("SalesQuantityId", int),
             ("Quantity", int)
         ])
    ]

    def create_sales_quantity_attributes(self, sale_quantity_id: int, description: str) -> None:
        """
        Creates or modifies a sales quantity attribute.
        E.g. Creates a restriction called "Volume restriction" with the ID 123456.

        :param sale_quantity_id: Unique ID for the created restriction.
        :param description: Description of the restriction.
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("SalesQuantityId", sale_quantity_id)
            line("Text", description)

        if self.contains_id_in_section('SalesQuantityAttributes', 'SalesQuantityId', sale_quantity_id):
            parent = self._find_parent('SalesQuantityAttributes', 'SalesQuantityId', sale_quantity_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.SalesQuantityAttributes, doc)

    def create_sales_quantity_restrictions(self, retail_item_group_id: int, sale_quantity_id: int, transaction_limit: int) -> None:
        """
        Creates or modifies a restriction limit on a retail item group.
        E.g. Soft drinks retail item group will be assigned the restriction called "Volume restriction" with the limit of 10.

        :param retail_item_group_id: Retail item group ID
        :param sale_quantity_id: Sale quantity ID
        :param transaction_limit: Transaction limit of given quantity
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("RetailItemGroupId", retail_item_group_id)
            line("SalesQuantityId", sale_quantity_id)
            line("TransactionLimit", transaction_limit)

        if self.contains_id_in_section('SalesQuantityRestrictions', 'RetailItemGroupId', retail_item_group_id):
            parent = self._find_parent('SalesQuantityRestrictions', 'RetailItemGroupId', retail_item_group_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.SalesQuantityRestrictions, doc)

    def create_retail_item_sales_quantity_attributes(self, item_id: int, modifier1_id: int, modifier2_id: int,
                                                     modifier3_id: int, sale_quantity_id: int, quantity: int) -> None:
        """
        Establishes or modifies by how much given items increase the restricted quantity of a given transaction limit.
        E.g. Small coca cola will increase current volume of soft drinks by 0.3 while large coca cola will
          increase it by 2. Should a limit of 10 be reached, additional soft drinks would not be allowed.

        :param item_id: Item ID
        :param modifier1_id: Modifier1 ID
        :param modifier2_id: Modifier2 ID
        :param modifier3_id: Modifier3 ID
        :param sale_quantity_id: Sale quantity ID
        :param quantity: Quantity attribute
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("ItemId", item_id)
            line("Modifier1Id", modifier1_id)
            line("Modifier2Id", modifier2_id)
            line("Modifier3Id", modifier3_id)
            line("SalesQuantityId", sale_quantity_id)
            line("Quantity", quantity)

        parent = self.contains_item('RetailItemSalesQuantityAttributes', item_id, modifier1_id, modifier2_id, modifier3_id)
        if parent is not None:
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.RetailItemSalesQuantityAttributes, doc)

    def contains_item(self, relay_section: str, item_id: int,
                      modifier1_id: int, modifier2_id: int, modifier3_id: int) -> bs4.Tag:
        """
        Check whether the relay file contains an sale quantity attributes for given item.

        :param relay_section: This specifies the section of the relay to search, it is necessary because a relay file
        can reuse the same column names through multiple sections
        :param item_id: Item ID to check.
        :param modifier1_id: Modifier1 ID to check.
        :param modifier2_id: Modifier2 ID to check.
        :param modifier3_id: Modifier3 ID to check.
        :return: Return the find item or None.
        """
        match = None
        items = getattr(self._soup.RelayFile, relay_section).findAll('ItemId', text=str(item_id))
        for item in items:
            parent = item.parent
            if ((parent.find('Modifier1Id', string=str(modifier1_id)) is not None)
            and (parent.find('Modifier2Id', string=str(modifier2_id)) is not None)
            and (parent.find('Modifier3Id', string=str(modifier3_id)) is not None)):
                match = parent
                break
        return match
