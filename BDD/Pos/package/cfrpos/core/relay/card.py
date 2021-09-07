__all__ = [
    "CardRelay"
]

import yattag

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from . import RelayFile


@wrap_all_methods_with_log_trace
class CardRelay(RelayFile):
    """
    Representation of the card relay file.
    """
    _pos_name = "card"
    _pos_reboot_required = True
    _filename = "Card.xml"
    _default_version = 9
    _sort_rules = [
        ("CardDefinitionRecords", [
            ("CardDefinitionId", int),
            ("CardRole", int),
            ("Name", str),
            ("BarcodeLength", int)
        ]),
        ("CardDefinitionGroupListRecords", [
            ("CardDefinitionId", int),
            ("CardDefinitionGroupId", int)
        ]),
        ("MSRCardNumberRangeListRecords", [
            ("CardDefinitionId", int),
        ]),
        ("BarcodeRangeListRecords", [
            ("CardDefinitionId", int),
            ("BarcodeRangeFrom", int),
            ("BarcodeRangeTo", int)
        ]),
        ("ManualCardNumberRangeListRecords", [
            ("CardDefinitionId", int)
        ]),
        ("LoyaltyProgramListRecords", [
            ("PosName", str)
        ]),
        ("LoyaltyProgramCardDefinitionListRecords", [
            ("LoyaltyProgramId", int),
            ("CardDefinitionId", str)
        ])]

    def create_card_definition(self, card_definition_id: int, card_role: int, name: str, barcode_len: int,
                              track_format_1: str = '', track_format_2:str = '', mask_mode: int = 0) -> None:
        """
        Creates a card record or modifies an existing one.

        :param card_definition_id: Card definition ID.
        :param card_role: Card role number.
        :param name: Card name.
        :param barcode_len: Length of the barcode.
        :param track_format_1: Card track format 1, needed in case of MSRCardNumberRangeListRecords usage.
        :param track_format_2: Card track format 2, needed in case of MSRCardNumberRangeListRecords usage.
        :param mode_mask: Card mode mask. Reads order of track data.
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("CardDefinitionId", card_definition_id)
            line("CardRole", card_role)
            line("Name", name)
            line("Priority", 0)
            line("ActiveFlag", 1)
            line("HideOnPosFlag", 0)
            line("MSRCardNumberLength", barcode_len)
            line("MSRTrackFormat1", track_format_1)
            line("MSRTrackFormat2", track_format_2)
            line("MSRMaskReadMode", mask_mode)
            line("BarcodeLength", barcode_len)
            line("ManualCardNumberLength", barcode_len)

        if self.contains_id_in_section('CardDefinitionRecords', 'CardDefinitionId', card_definition_id):
            parent = self._find_parent('CardDefinitionRecords', 'CardDefinitionId', card_definition_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.CardDefinitionRecords, doc)
            self.mark_dirty()

    def create_card_definition_group(self, card_definition_id: int, card_definition_group_id: int) -> None:
        """
        Creates a card definition group record or modifies an existing one.

        :param card_definition_id: Card definition ID.
        :param card_definition_group_id: Card definition group ID.
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("CardDefinitionId", card_definition_id)
            line("CardDefinitionGroupId", card_definition_group_id)

        if self.contains_id_in_section('CardDefinitionGroupListRecords', 'CardDefinitionGroupId', card_definition_group_id):
            parent = self._find_parent('CardDefinitionGroupListRecords', 'CardDefinitionGroupId', card_definition_group_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.CardDefinitionGroupListRecords, doc)

    def create_barcode_range_list(self, card_definition_id: int, barcode_range_from: str, barcode_range_to: str) -> None:
        """
        Creates a barcode range list record or modifies an existing one.

        :param card_definition_id: Card definition ID.
        :param barcode_range_from: Barcode range from.
        :param barcode_range_to: Barcode range to.
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("CardDefinitionId", card_definition_id)
            line("BarcodeRangeFrom", barcode_range_from)
            line("BarcodeRangeTo", barcode_range_to)

        if self.contains_id_in_section('BarcodeRangeListRecords', 'CardDefinitionId', card_definition_id):
            parent = self._find_parent('BarcodeRangeListRecords', 'CardDefinitionId', card_definition_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.BarcodeRangeListRecords, doc)

    def create_msr_range_list(self, card_definition_id: int, msr_range_from: str, msr_range_to: str) -> None:
        """
        Creates a MSR range list record or modifies an existing one. The record is needed for swiping a card on pinpad.

        :param card_definition_id: Card definition ID.
        :param msr_range_from: MSR card range from.
        :param msr_range_to: MSR card range to.
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("CardDefinitionId", card_definition_id)
            line("MSRCardNumberRangeFrom", msr_range_from)
            line("MSRCardNumberRangeTo", msr_range_to)

        if self.contains_id_in_section('MSRCardNumberRangeListRecords', 'CardDefinitionId', card_definition_id):
            parent = self._find_parent('MSRCardNumberRangeListRecords', 'CardDefinitionId', card_definition_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.MSRCardNumberRangeListRecords, doc)

    def remove_existing_loyalty_programs(self):
        """
        Removes all records from loyalty program list
        """
        loyalty_program_list = self._soup.RelayFile.LoyaltyProgramListRecords
        records = loyalty_program_list.find_all('record')
        for record in records:
            self._remove_tag(record)

    def create_loyalty_program(self, loyalty_program_id: int, external_id: str, program_name: str, display_order: int = 0, alternate_id_eligible: int = 1,
                              alternate_id_min_length: int = 1, alternate_id_max_length: int = 10) -> None:

        """
        Creates a loyalty program record or modifies an existing one.

        :param loyalty_program_id: Unique ID of the loyalty program
        :param external_id: String with external ID
        :param program_name: String with POS program name displayed on pinpads and screens
        :param display_order: Order in which the records should be displayed. If 0, will be displayed last in the list.
        :param alternate_id_eligible: Is this program eligible for alternate ID? Yes = 1, No = 0
        :param alternate_id_min_length: Number of characters in alternate ID, minimum
        :param alternate_id_max_length: Number of characters in alternate ID, maximum
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("LoyaltyProgramId", loyalty_program_id)
            line("ExternalId", external_id)
            line("PosName", program_name)
            line("DisplayOrder", display_order)
            line("AlternateIdEligible", alternate_id_eligible)
            line("AlternateIdMinLength", alternate_id_min_length)
            line("AlternateIdMaxLength", alternate_id_max_length)

        if self.contains_id_in_section('LoyaltyProgramListRecords', 'PosName', program_name):
            parent = self._find_parent('LoyaltyProgramListRecords', 'PosName', program_name)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.LoyaltyProgramListRecords, doc)
            self.mark_dirty()

    def get_loyalty_program_id(self, program_name: str):
        """
        Get a loyalty program id of loyalty program with given name.

        :param program_name: Loyalty program name.
        """
        if self.contains_id_in_section('LoyaltyProgramListRecords', 'PosName', program_name):
            parent = self._find_parent('LoyaltyProgramListRecords', 'PosName', program_name)
            return parent.find('LoyaltyProgramId').next
        else:
            return None

    def create_loyalty_program_id(self):
        """
        Create a new loyalty program id for each new loyalty program.
        """
        program_id = 10000000002
        while self.contains_id_in_section('LoyaltyProgramCardDefinitionListRecords', 'LoyaltyProgramId', program_id):
            program_id = program_id + 1
        return program_id

    def assign_card_to_loyalty_program(self, loyalty_program_id: str, card_definition_id: str) -> None:
        """
        Creates a record for Loyalty program card definition. It assigns the card to loyalty program with given loyalty program ID.

        :param loyalty_program_id: Loyalty program ID.
        :param card_definition_id: Card definition ID.
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("LoyaltyProgramId", loyalty_program_id)
            line("CardDefinitionId", card_definition_id)

        if self.contains_id_in_section('LoyaltyProgramCardDefinitionListRecords', 'LoyaltyProgramId', loyalty_program_id):
            parent = self._find_parent('LoyaltyProgramCardDefinitionListRecords', 'LoyaltyProgramId', loyalty_program_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.LoyaltyProgramCardDefinitionListRecords, doc)
