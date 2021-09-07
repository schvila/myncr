__all__ = [
    "RetailItemGroupRelay"
]

import yattag

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from . import RelayFile


@wrap_all_methods_with_log_trace
class RetailItemGroupRelay(RelayFile):
    """
    Representation of the retail item group relay file.
    """
    _pos_name = "RetailItemGroup"
    _filename = "RetailItemGroup.xml"
    _default_version = 5
    _sort_rules = [
        ("RetailItemGroupItemList", [
            ("RetailItemGroupId", int),
            ("ItemId", int),
            ("Modifier1Id", int),
            ("ItemType", int)
        ]),
         ("RetailItemGroupCategoryList", [
             ("RetailItemGroupId", int),
             ("SalesDepartmentId", int),
             ("SalesCategoryId", int)
         ]),
         ("RetailItemGroupItemTypeList", [
             ("RetailItemGroupId", int),
             ("ItemType", int)
         ]),
         ("RetailItemGroupExternalIds", [
            ("RetailItemGroupId", int),
            ("ExternalId", str)
        ])
    ]

    def create_group(self, retail_item_group_id: int, external_id: str) -> None:
        """
        Creates a new retail item group record or modifies an existing one with the given parameters.

        :param retail_item_group_id: Retail item group ID
        :param external_id: External ID
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("RetailItemGroupId", retail_item_group_id)
            line("ExternalId", external_id)

        if self.contains_retail_item_group_id_in_section('RetailItemGroupExternalIds', retail_item_group_id):
            parent = self._find_parent('RetailItemGroupExternalIds', 'RetailItemGroupId', retail_item_group_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.RetailItemGroupExternalIds, doc)

    def assign_item_to_group(self, retail_item_group_id: int, item_id: int, modifier1_id: int, item_type: int = 1,
                             modifier2_id: int = 0, modifier3_id: int = 0, item_mode2: int = 0) -> None:
        """
        Creates a new record or modifies an existing one to assign a retail item to a retail item group.

        :param retail_item_group_id: Retail item group ID
        :param item_id: Item ID
        :param modifier1_id: Modifier 1 ID
        :param item_type: Item type
        :param modifier2_id: Modifier 2 ID
        :param modifier3_id: Modifier 3 ID
        :param item_mode2: Item mode 2
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("RetailItemGroupId", retail_item_group_id)
            line("ItemId", item_id)
            line("Modifier1Id", modifier1_id)
            line("Modifier2Id", modifier2_id)
            line("Modifier3Id", modifier3_id)
            line("ItemType", item_type)
            line("ItemMode2", item_mode2)

        if self.contains_retail_item_group_id_in_section('RetailItemGroupItemList', retail_item_group_id):
            parent = self._find_parent('RetailItemGroupItemList', 'RetailItemGroupId', retail_item_group_id)
            if parent.find('ItemId', string=str(item_id)) is not None:
                self._modify_tag(parent, doc)
            else:
                self._append_tag(self._soup.RelayFile.RetailItemGroupItemList, doc)
        else:
            self._append_tag(self._soup.RelayFile.RetailItemGroupItemList, doc)

    def contains_retail_item_group_id(self, retail_item_group_id: int) -> bool:
        """
        Check whether the relay file contains a retail item group ID.
        :param retail_item_group_id: ID to check.
        :return: Whether the ID is present.
        """
        match = self._soup.find("RetailItemGroupId", string=str(retail_item_group_id))
        return match is not None

    def contains_retail_item_group_id_in_section(self, relay_section: str, retail_item_group_id: int) -> bool:
        """
        Check whether the relay file contains a retail item group ID.

        :param relay_section: This specifies the section of the relay to search, it is necessary because a relay file
        can reuse the same column names through multiple sections
        :param retail_item_group_id: ID to check.
        :return: Whether the ID is present.
        """
        match = getattr(self._soup.RelayFile, relay_section).find("RetailItemGroupId", string=str(retail_item_group_id))
        return match is not None

    def contains_retail_item_group_external_id(self, external_id: str) -> bool:
        """
        Check whether the relay file contains a retail item group external ID.
        :param external_id: ID to check.
        :return: Whether the ID is present.
        """
        match = self._soup.find("ExternalId", string=external_id)
        return match is not None


    def find_relay_group_id(self, item_id: str):
        """
        Method to find which retail group item with provided id belongs.

        :param item_id: Item ID to be checked.
        """
        match = getattr(self._soup.RelayFile, 'RetailItemGroupItemList').find('ItemId', string=item_id)
        return match.parent.find("RetailItemGroupId").string