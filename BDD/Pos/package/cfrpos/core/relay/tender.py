__all__ = [
    "TenderRelay"
]

import yattag

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from ..bdd_utils.errors import ProductError
from . import RelayFile
from enum import Enum


BUTTON_ITERATION_LIMIT = 50


class ButtonActions(Enum):
    QUICK_TENDER_BUTTON = 0
    AMOUNT_SELECTION = 1
    EXACT_DOLLAR = 2
    NEXT_DOLLAR = 3


@wrap_all_methods_with_log_trace
class TenderRelay(RelayFile):
    """
    Representation of the tender relay file.
    """
    _pos_name = "Tender"
    _filename = "Tender.xml"
    _pos_reboot_required = False
    _default_version = 16
    _sort_rules = [
        ("Tenders", [
            ("TenderId", int),
            ("TenderTypeId", int)
        ]),
        ("TenderTypes", [
             ("TenderTypeId", int)
         ]),
        ("ReconciliationGroups", [
             ("ReconciliationGroupId", int),
             ("TenderTypeId", int)
         ]),
        ("TenderButtons", [
            ("TenderId", int)
        ]),
        ("TenderExternalIds", [
            ("TenderId", int)
        ]),
        ("TenderBarGroupButtonRecords", [
            ("TenderBarGroupButtonId", int)
        ]),
        ("TenderBarGroupButtonListRecords", [
            ("TenderId", int)
        ])
    ]

    def create_tender(self, tender_id: int = 70000000023, description: str = 'Cash', tender_type_id: int = 1,
                      exchange_rate: float = 1, currency_symbol: str = '$', tender_mode: int = 1331912704, tender_mode_2: int = 16, device_control: int = 131072,
                      required_security: int = 0) -> None:
        """
        Creates a new tender record or modifies an existing one. Most of the values are hardcoded based on a default
        cash tender and will be implemented later if needed.

        :param tender_id: Tender ID, leaving the default value will modify existing cash tender.
        :param tender_type_id: Tender type ID.
        :param description: Description of the tender, will be displayed on VR, reports, etc.
        :param exchange_rate: Conversion rate against the site's default currency.
        :param currency_symbol: Currency symbol to be used with this tender.
        :param tender_mode: tender mode flags for this tender
        :param tender_mode_2: tender mode flag for this tender
        :param device_control: receipt print and drawer options
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("TenderId", tender_id)
            line("DescriptionId", 0)
            line("TenderTypeId", tender_type_id)
            line("RequiredSecurity", required_security)
            line("DeviceListId", 1)
            line("DeviceControl", device_control)
            line("TenderMode", tender_mode)
            line("TenderModes2", tender_mode_2)
            line("StartingAmount", 0)
            line("ItemizerMask", 0)
            line("AccumulatedCashIntake", 0)
            line("ReconciliationGroupId", 70000000030)
            line("ExchangeRate", exchange_rate)
            line("CurrencySymbol", currency_symbol)
            line("Description", description)
            line("TenderBarText", description)
            line("BitmapFileName", '')
            line("UseChangeTenderId", tender_id)
            line("OverridePaymentLimit", 0)
            line("AbsoluteRaymentLimit", 0)
            line("OverrideRefundLimit", 0)
            line("AbsoluteRefundLimit", 0)
            line("CardValidationType", 0)

        if self.contains_tender_id_in_section('Tenders', tender_id):
            parent = self._find_parent('Tenders', 'TenderId', tender_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.Tenders, doc)
            self.mark_dirty()

    def create_tender_type(self, tender_type_id: int, description: str, tender_type_mode: int = 0, tender_ranking: int = 0, tier_number:int = 0) -> None:
        """ Creates a new tender type record or modifies an existing one.

        :param tender_type_id: ID
        :param description: Description
        :param tender_type_mode: Mode, defaults to 0
        :param tender_ranking: Ranking, defaults to 0
        :param tier_number: Tier number, defaults to 0
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("TenderTypeId", tender_type_id)
            line("TenderTypeMode", tender_type_mode)
            line("TenderRanking", tender_ranking)
            line("Description", description)
            line("TierNumber", tier_number)

        if self.contains_tender_type_id_in_section('TenderTypes', tender_type_id):
            parent = self._find_parent('TenderTypes', 'TenderTypeId', tender_type_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.TenderTypes, doc)
            self.mark_dirty()

    def create_tender_external_id(self, tender_id: int, external_id: str):
        """
        Creates a external id for a given tender_id and with a given external_id.
        :param tender_id: ID of the tender which will be assigned to the new button.
        :param external_id: New external ID for given tender.
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("TenderId", tender_id)
            line("ExternalId", external_id)

        if self.contains_tender_id_in_section('TenderExternalIds', tender_id):
            parent = self._find_parent('TenderExternalIds', 'TenderId', tender_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.TenderExternalIds, doc)

    def create_tender_button(self, tender_id: int, description: str, position: int = None,
                             action: ButtonActions = 'AMOUNT_SELECTION', preset_amount: int = 0) -> None:
        """
        Creates a tender button for a given tender_id and with a given description.
        :param tender_id: ID of the tender which will be assigned to the new button.
        :param description: Button text of the new tender button.
        :param position: Position of the new button on the tender bar. If none is supplied, the first free one is used.
        :param action: Determines what the button does, actions are defined in a separate enum
        :param preset_amount: Used to setup a quick tender button with some value, 10000 is 1$
        """
        for ButtonAction in ButtonActions:
            if ButtonAction.name == action.upper():
                button_action = ButtonAction.value
                break
        else:
            raise ProductError('Supplied parameter {} is not one of the supported values for button action'.format(action))

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("TenderId", tender_id)
            line("Position", position if position is not None else self._get_free_button_position())
            line("Location", 1)
            line("Action", button_action)
            line("PresetAmount", preset_amount)
            line("ButtonText", description)
            line("BitmapFilename", '')

        self._append_tag(self._soup.RelayFile.TenderButtons, doc)
        self.mark_dirty()

    def create_tender_group(self, tender_group_id: int, description: str, position: int = None) -> None:
        """
        Creates a tender bar group and its button. This functionality was merged from a PS project and helps group tender
        buttons together to save space and lengthy scrolling through the dynamic tender bar. Once a group button is pressed,
        a frame with a 4x4 button grid is displayed with assigned tenders to choose from.
        :param tender_group_id: ID of the tender group being created.
        :param description: Button text for the new tender group button.
        :param position: Position of the new button on the tender bar. If none is supplied, the first free one is used.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("TenderBarGroupButtonId", tender_group_id)
            line("Position", position if position is not None else self._get_free_button_position())
            line("ButtonText", description)
            line("BitmapFileName", '')

        if self._contains_tender_group_id_in_section('TenderBarGroupButtonRecords', tender_group_id):
            parent = self._find_parent('TenderBarGroupButtonRecords', 'TenderBarGroupButtonId', tender_group_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.TenderBarGroupButtonRecords, doc)

    def assign_tender_to_group(self, tender_group_id: int, tender_id: int) -> None:
        """
        Assigns a tender to a preexisting tender group.
        :param tender_group_id: ID of the target tender group.
        :param tender_id: ID of the tender being assigned.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("TenderId", tender_id)
            line("TenderBarGroupButtonId", tender_group_id)

        if self.contains_tender_id_in_section('TenderBarGroupButtonListRecords', tender_id):
            parent = self._find_parent('TenderBarGroupButtonListRecords', 'TenderId', tender_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.TenderBarGroupButtonListRecords, doc)

    def contains_tender_id(self, tender_id: int) -> bool:
        """
        Check whether the relay file contains a tender ID.
        :param tender_id: ID to check.
        :return: Whether the ID is present.
        """
        match = self._soup.find("TenderId", string=str(tender_id))
        return match is not None

    def contains_tender_id_in_section(self, relay_section: str, tender_id: int) -> bool:
        """
        Check whether the relay file contains a tender ID in a given section.

        :param relay_section: This specifies the section of the relay to search, it is necessary because a relay file
        can reuse the same column names through multiple sections
        :param tender_id: ID to check.
        :return: Whether the ID is present.
        """
        match = getattr(self._soup.RelayFile, relay_section).find("TenderId", string=str(tender_id))
        return match is not None

    def contains_tender_type_id_in_section(self, relay_section: str, tender_type_id: int) -> bool:
        """
        Check whether the relay file contains a tender type ID in a given section.

        :param relay_section: This specifies the section of the relay to search, it is necessary because a relay file
        can reuse the same column names through multiple sections
        :param tender_type_id: ID to check.
        :return: Whether the ID is present.
        """
        match = getattr(self._soup.RelayFile, relay_section).find("TenderTypeId", string=str(tender_type_id))
        return match is not None

    def contains_tender_group_id(self, tender_group_id: int) -> bool:
        """
        Check whether the relay file contains a tender group ID.

        :param tender_group_id: ID to check.
        :return: Whether the ID is present.
        """
        match = self._soup.find("TenderBarGroupButtonId", string=str(tender_group_id))
        return match is not None

    def _contains_tender_group_id_in_section(self, relay_section: str, tender_group_id: int) -> bool:
        """
        Check whether the relay file contains a tender group ID in a given section.

        :param relay_section: This specifies the section of the relay to search, it is necessary because a relay file
        can reuse the same column names through multiple sections
        :param tender_group_id: ID to check.
        :return: Whether the ID is present.
        """
        match = getattr(self._soup.RelayFile, relay_section).find("TenderBarGroupButtonId", string=str(tender_group_id))
        return match is not None

    def _get_free_button_position(self, limit: int = BUTTON_ITERATION_LIMIT) -> int:
        """
        Returns the first free button position on the tender bar.
        """
        free_position = 1
        while self._contains_position(free_position):
            if free_position == limit:
                raise ProductError('No empty position on the tender bar was found in the limit of {} iterations'.format(limit))
            free_position += 1
        return free_position

    def _contains_position(self, position) -> bool:
        """
        Check whether the relay file contains a tender button with a given position.
        :param position: position to check.
        :return: Whether the position is already present.
        """
        match = self._soup.find("Position", string=str(position))
        return match is not None
