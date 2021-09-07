__all__ = [
    "AutoComboRelay"
]

import yattag

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from .. bdd_utils.errors import ProductError
from . import RelayFile
from random import randint


@wrap_all_methods_with_log_trace
class AutoComboRelay(RelayFile):
    """
    Representation of the Autocombo relay file.
    """
    _pos_name = "Autocombo"
    _filename = "AutoCombo.xml"
    _default_version = 7
    _sort_rules = [
        ("AutoComboRecord", [
            ("Description", str)
        ]),
        ("ComboRequirementRecord", [
            ("ComboRequirementId", int)
        ]),
        ("AutoComboExternalIds", [
            ("ComboId", int)
        ]),
        ("DiscountIdRecord", [
            ("ComboRequirementId", int)
        ]),
        ("ItemGroupRecord", [
            ("ItemId", int)
        ])

    ]

    def create_autocombo_record(self, combo_id: int, description: str, external_id: str = '', start_date: str = '2012-06-25T00:00:00', end_date: str = '1899-01-01T00:00:00',
                                 mode_flag: int = 0, max_per_tran: int = 0) -> None:
        """
        Create an autocombo record.

        :param combo_id: Autocombo record ID.
        :param description: Autocombo name.
        :param external_id: External ID.
        :param start_date: Start date.
        :param end_date: End date.
        :param mode_flag: Mode flag. For example, 4 says that the loyalty card has to be present in the transaction.
        :param max_per_tran: Maximum number of autocombos that can be added to the transaction, 0 stands for unlimited.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("ComboId", combo_id)
            line("StartDateTime", start_date)
            line("EndDateTime", end_date)
            line("Description", description)
            line("MaxPerTran", max_per_tran)
            line("ModeFlag", mode_flag)
            line("ExternalId", external_id)

        match_description = getattr(self._soup.RelayFile, 'AutoComboRecord').find('Description', string=description)
        if match_description is None:
            self._append_tag(self._soup.RelayFile.AutoComboRecord, doc)


    def create_requirement_record(self, description: str, requirement_id: int, group_id: int, quantity_required: int, mode_flag: int = 0, amount_required: int = 0) -> None:
        """
        Create a combo requirement record. Each part of autocombo discount needs a requirement ID, so the autocombo
        could be created from different items (2As+1B Combo).

        :param description: Autocombo description.
        :param requirement_id: Requirement ID.
        :param group_id: Autocombo item group ID.
        :param quantity_required: Item quantity required for applying autocombo.
        :param mode_flag: Mode flag. For example, 4 says that the loyalty card has to be present in the transaction.
        :param amount_required: Amount required.
        """

        if self._find_combo_id(description) is not None:
            combo_id = self._find_combo_id(description)
        else:
            combo_id = requirement_id

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("ComboRequirementId", requirement_id)
            line("ComboId", combo_id)
            line("GroupId", group_id)
            line("ModeFlag", mode_flag)
            line("QuantityRequired", quantity_required)
            line("AmountRequired", amount_required)

        match_requirement_id = getattr(self._soup.RelayFile, 'ComboRequirementRecord').find('ComboRequirementId', string=int(requirement_id))
        if match_requirement_id is None:
            self._append_tag(self._soup.RelayFile.ComboRequirementRecord, doc)


    def create_autocombo_external_id(self, combo_id: int, external_id: str) -> None:
        """
        Create or modify autocombo external id.

        :param combo_id: Autocombo record ID.
        :param external_id: External ID.

        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("ComboId", combo_id)
            line("ExternalId", external_id)

        match_combo_id = getattr(self._soup.RelayFile, 'AutoComboExternalIds').find('ComboId', string=int(combo_id))
        if match_combo_id is not None:
            parent = self._find_parent('AutoComboExternalIds', 'ComboId', combo_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.AutoComboExternalIds, doc)


    def create_discount_id(self, requirement_id: int, discount_id: int, min_amount: int = 0) -> None:
        """
        Create or modify autocombo discount id record.

        :param requirement_id: Requirement ID.
        :param discount_id: Discount ID.
        :param min_amount: Minimum amount for autocombo to be applied on.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("ComboRequirementId", requirement_id)
            line("DiscountId", discount_id)
            line("MinDiscountAmount", min_amount)

        match_requirement_id = getattr(self._soup.RelayFile, 'DiscountIdRecord').find('ComboRequirementId', string=int(requirement_id))
        if match_requirement_id is not None:
            parent = self._find_parent('DiscountIdRecord', 'ComboRequirementId', requirement_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.DiscountIdRecord, doc)


    def create_item_group_record(self, item_id: int, modifier_id: int, group_id: int = 990000000004, item_type: int = 0, modifier2_id: int = 0, modifier3_id: int = 0) -> None:
        """
        Create item group record.

        :param combo_id: Autocombo record ID.
        :param modifier_id: Modifier1 ID of the item that triggers autocombo.
        :param modifier2_id: Modifier2 ID of the item that triggers autocombo.
        :param modifier3_id: Modifier3 ID of the item that triggers autocombo.
        :param group_id: Autocombo item group ID.
        :param item_type: Item type, if not provided 0.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("ItemId", item_id)
            line("Modifier1Id", modifier_id)
            line("Modifier2Id", modifier2_id)
            line("Modifier3Id", modifier3_id)
            line("GroupId", group_id)
            line("ItemType", item_type)

        self._append_tag(self._soup.RelayFile.ItemGroupRecord, doc)


    def create_new_autocombo_id(self) -> int:
        """
        Generate a new autocombo id for each new autocombo record.
        """
        combo_id = 990000000050
        while self.contains_id_in_section('AutoComboRecord', 'ComboId', combo_id):
            combo_id = combo_id + 1
        return combo_id


    def create_new_requirement_id(self) -> int:
        """
        Generate a new requirement id for each new combo requirement record.
        """
        requirement_id = 7000000
        while self.contains_id_in_section('ComboRequirementRecord', 'ComboRequirementId', requirement_id):
            requirement_id = requirement_id + 1
        return requirement_id


    def create_new_combo_group_id(self) -> int:
        """
        Generate a new combo group id.
        """
        group_id = 75000000300
        while self.contains_id_in_section('ComboRequirementRecord', 'GroupId', group_id):
            group_id = group_id + 1
        return group_id


    def _find_combo_id(self, description: str):
        """
        Method to find autocombo ID based on given autocombo name.

        :param description: Autocombo name.
        """
        match_description = getattr(self._soup.RelayFile, 'AutoComboRecord').find('Description', string=description)
        if match_description is not None:
            return match_description.parent.find("ComboId").string
