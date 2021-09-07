__all__ = [
    "TaxType",
    "TaxRelay"
]

import math
import random
import string
import yattag
from enum import Enum

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from . import RelayFile

class TaxType(Enum):
    PERCENT = 1
    AMOUNT = 2
    TAX_TABLE = 3


@wrap_all_methods_with_log_trace
class TaxRelay(RelayFile):
    """
    Representation of the tax relay file.
    """
    _pos_name = "tax"
    _pos_reboot_required = False
    _filename = "Tax.xml"
    _default_version = 18
    _sort_rules = [
        ("Itemizers", [
            ("ItemizerNum", int),
            ("TaxControlId", int),
            ("TaxAuthorityId", int),
            ("ExternalId", int),
            ("Description", str),
            ("TaxCalcMethod", int)
        ]),
        ("TaxControls", [
            ("TaxControlId", int),
            ("DestinationId", int),
            ("TaxPercentOrAmount", float),
            ("EffectiveYear", int),
            ("EffectiveMonth", int),
            ("EffectiveDay", int)
        ]),
        ("BrkptHeaders", [
            ("TaxBreakpointId", int),
        ]),
        ("ExemptRecs", [
        ]),
        ("ItemizerMasks", [
            ("ItemizerMask", int),
            ("Description", str)
        ]),
        ("TaxPrintSections", [
        ]),
        ("AccountableOwners", [
            ("AccountableOwnerId", int),
            ("Name", str)
        ]),
        ("AccountableOwnerTaxPlanLists", [
        ]),
        ("TaxPlanScheduleTimetables", [
            ("TaxPlanScheduleId", int),
            ("ItemizerMask", int),
            ("EffectiveYear", int),
            ("EffectiveMonth", int),
            ("EffectiveDay", int)
        ]),
        ("TaxAccounts", [
        ])
    ]

    def create_tax_rate(self, tax_control_id: int, tax_value: float,
                    effective_year: int, effective_month: int, effective_day: int, destination_id: int = None) -> None:
        """
        Create a new tax rate record or modifies an existing one.

        :param float tax_value: The value of the tax. For percentage tax, it is in percent (8.88%)
        :param int effective_year: The year of the date, when the tax starts to be effective.
        :param int effective_month: The month of the date, when the tax starts to be effective.
        :param int effective_day: The day of the date, when the tax starts to be effective.
        :param int tax_control_id: The ID of the tax rate.
        :param int destination_id: The tax rate is specified for the destination_id.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("TaxControlId", tax_control_id)
            line("DestinationId", destination_id if destination_id != None else 0)
            line("TaxBreakpointId", 0)
            line("TaxPercentOrAmount", tax_value)
            line("RepeatAmount", 0)
            line("RepeatTax", 0)
            line("RepeatStart", 0)
            line("DescriptionId", 0)
            line("Flags", 0)
            line("ThresholdQuantity", 0)
            line("ThresholdTaxPercent", 0)
            line("EffectiveYear", effective_year)
            line("EffectiveMonth", effective_month)
            line("EffectiveDay", effective_day)

        if self.contains_id_in_section('TaxControls', 'TaxControlId', tax_control_id):
            parent = self._find_parent('TaxControls', 'TaxControlId', tax_control_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.TaxControls, doc)


    def create_tax(self, itemizer_num: int, tax_control_id: int, tax_description: str,
                                tax_authority_id: int, tax_type: TaxType) -> int:
        """
        Create a new tax record or modifies an existing one.

        :param str tax_description: Description of the tax.
        :param TaxType tax_type: Enum, what type of the tax should be created. For example TaxType.PERCENT
        :param int itemizer_num: The ID of the tax.
        :param int tax_control_id: The ID of the tax rate.
        :param int tax_authority_id: The ID of the authority of the tax.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("ItemizerNum", itemizer_num)
            line("TaxControlId", tax_control_id)
            line("TaxAuthorityId", tax_authority_id)
            line("ExternalId", tax_control_id)
            line("Description", tax_description)
            line("TaxCalcMethod", tax_type.value)
            line("TaxOrder", 0)
            line("Flags", 0)

        if self.contains_id_in_section('Itemizers', 'ItemizerNum', itemizer_num):
            parent = self._find_parent('Itemizers', 'ItemizerNum', itemizer_num)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.Itemizers, doc)

        itemizer_mask = self.create_itemizer_mask_value(itemizer_num)
        self._create_itemizer_mask_record(itemizer_mask, tax_description, 1)

        return itemizer_mask


    def create_tax_plan_with_tax(self, tax_plan_schedule_id: int, itemizer_mask: int,
                                 plan_description: str, allow_tax_change_on_pos: bool,
                              effective_year: int, effective_month: int, effective_day: int) -> None:
        """
        Create a new tax plan with a tax or modifies an existing one.

        :param int tax_plan_schedule_id: The ID of the tax plan schedule.
        :param int itemizer_mask: Combined IDs of all taxes applicable in the tax plan.
        :param str plan_description: The description of the plan.
        :param bool allow_tax_change_on_pos: If the tax is allowed to be changed on POS.
        :param int effective_year: The year of the date, when the tax starts to be effective.
        :param int effective_month: The month of the date, when the tax starts to be effective.
        :param int effective_day: The day of the date, when the tax starts to be effective.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("TaxPlanScheduleId", tax_plan_schedule_id)
            line("ItemizerMask", itemizer_mask)
            line("EffectiveYear", effective_year)
            line("EffectiveMonth", effective_month)
            line("EffectiveDay", effective_day)

        if self.contains_id_in_section('TaxPlanScheduleTimetables', 'TaxPlanScheduleId', tax_plan_schedule_id):
            parent = self._find_parent('TaxPlanScheduleTimetables', 'TaxPlanScheduleId', tax_plan_schedule_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.TaxPlanScheduleTimetables, doc)

        self._create_itemizer_mask_record(itemizer_mask, plan_description, allow_tax_change_on_pos)


    def _create_itemizer_mask_record(self, itemizer_mask: int, plan_description: str,
                              allow_tax_change_on_pos: bool) -> None:
        """
        Create a new itemizer mask or modifies an existing one.

        :param int itemizer_mask: The mask of the ID of the tax, which should be in the plan.
        :param str plan_description: The description of the plan.
        :param bool allow_tax_change_on_pos: If the tax is allowed to be changed on POS.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("ItemizerMask", itemizer_mask)
            line("Description", plan_description)
            line("AllowTaxChangeAtPosFlag", int(allow_tax_change_on_pos))

        if self.contains_id_in_section('ItemizerMasks', 'ItemizerMask', itemizer_mask):
            parent = self._find_parent('ItemizerMasks', 'ItemizerMask', itemizer_mask)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.ItemizerMasks, doc)


    def find_itemizer_num(self, tax_control_id: int) -> int:
        """
        Method to find itemizer num of given tax control id.

        :param tax_control_id: Tax control id to be searched for.
        :return int: Itemizer num for given tax control id or None.
        """
        match = getattr(self._soup.RelayFile, 'Itemizers').find('TaxControlId', string=str(tax_control_id))
        if match:
            return int(match.parent.find("ItemizerNum").string)
        else:
            return None


    def create_tax_description(self, user_string: str) -> str:
        """
        Creates an unique tax/plan description. BEWARE: I had problem with descriptions nor starting with 'h '.

        :param str descr_stem: String provided to use it in description.
        :return str: tax plan description.
        """
        letters = string.ascii_uppercase
        random_string = ''.join(random.choice(letters) for i in range(5))
        return "h {user_string} {random_string}".format(user_string=user_string, random_string=random_string)


    def create_itemizer_mask_value(self, itemizer_num: int) -> int:
        """
        Calculates itemizer_mask for given itemizer_num.

        :param int itemizer_num: Itemizer_num from which will be itemizer mask calculated.
        :return int: Itemizer mask.
        """
        #we are doing this operation, because almost the same thing does the RCM with the itemizer_mask
        #at first, the itemizer_bit is added by one - thats the divide 2 we have here
        #then there is the same operation with pow on the itemizer_bit added by one
        return int(math.pow(2, itemizer_num)/2)
