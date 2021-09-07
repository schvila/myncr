__all__ = [
    "ReductionRelay",
    "DiscType",
    "DiscQuantity",
    "DiscMode",
    "CouponDiscountSecurityLevel"
]

import yattag

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from . import RelayFile
from ..bdd_utils.errors import ProductError
from enum import Enum


class DiscType(Enum):
    PRESET_AMOUNT = 0x00000000
    PRESET_PERCENT = 0x00000001
    PROMPTED_AMOUNT = 0x00000002
    PROMPTED_PERCENT = 0x00000004
    PRESET_RETAIL_PRICE = 0x00080000
    PROMPTED_RETAIL_PRICE = 0x00080002
    FUEL_PRICE_ROLLBACK = 0x000484010000
    PERCENTAGE_FUEL_PRICE_ROLLBACK = 0x000484010001
    AUTO_COMBO_AMOUNT = 0x400000000
    AUTO_COMBO_PERCENT = 0x400000001
    FREE_ITEM = 0x00002000
    PDL_FUEL_PRICE_ROLLBACK = 0x80010010
    PDL_PERCENTAGE_FUEL_PRICE_ROLLBACK = 0x80010011


class DiscMode(Enum):
    WHOLE_TRANSACTION = 0x00000000
    SINGLE_ITEM = 0x00008000
    EMPLOYEE_DISCOUNT_TRANSACTION = 0x40000000


class DiscQuantity(Enum):
    ALLOW_ALWAYS = 0x00080000
    ALLOW_ONLY_ONCE = 0x00800000
    STACKABLE = 0x05000000
    STACKABLE_ONLY_ONCE = 0x07000000
    STACKABLE_AND_ALLOW_ONLY_ONCE = 0x09800000


class CouponDiscountSecurityLevel(Enum):
    LOW = 0x70011000
    MEDIUM = 0x70022000
    HIGH = 0x70044000
    VERY_HIGH = 0x70088000


SHOW_MANUAL_LOOKUP = 0x00000010
BEST_DEAL = 0x00400000


@wrap_all_methods_with_log_trace
class ReductionRelay(RelayFile):
    """
    Representation of the reduction relay file.
    """
    _pos_name = "reduction"
    _filename = "Reduction.xml"
    _pos_reboot_required = True
    _default_version = 2
    _sort_rules = [
        ("Reductions", [
            ("ReductionId", int),
            ("ReductionMode", int),
            ("ReductionValue", int),
            ("Description", str)
        ]),
        ("ReductionDestinations", [
            ("ReductionId", int),
            ("DestinationId", int)
        ]),
        ("ReductionTargets", [
            ("ReductionId", int),
            ("ItemId", int),
            ("Modifier1Id", int),
            ("Modifier2Id", int),
            ("Modifier3Id", int)
        ]),
        ("ReductionItemRequirements", [
            ("ReductionId", int),
            ("RetailItemGroupId", int),
            ("FreeItemFlag", int)
        ]),
        ("ManufacturerCoupons", [
            ("ValueCodeId", int),
            ("MaxAllowed", int),
            ("CouponValue", int),
            ("QuantityRequired", int)
        ])
    ]

    def calculate_reduction_mode(self, disc_type: str, disc_mode: str, disc_quantity: str,
                               show_manual_lookup: bool = True, best_deal: bool = False) -> int:
        """
        Method to calculate a reduction ID which will be used during the discount creation based on a set of
        configuration values. The parameter names copy the names from RSM/RCM during actual discount creation.

        :param disc_type: type of the discount created, names of members from DiscType Enum are expected
        :param disc_mode: mode of the discount created, names of members from DiscMode Enum are expected
        :param disc_quantity: A combination of "Allow only once" and "Stackable" flags, decides whether the discount is
        (not) reapplicable on the same item or on different items in the transaction, names of members from DiscQuantity
        Enum are expected
        :param show_manual_lookup: Decides if the new discount should be visible in manual lookup frame
        :param best_deal: Decides if the new discount should be applied to an item which will yield the biggest
        discount automatically
        """
        reduction_mode = 0
        for Dtype in DiscType:
            if Dtype.name == disc_type.upper():
                reduction_mode += Dtype.value
                break
        else:
            raise ProductError('Supplied parameter {} is not one of the supported values for discount type'.format(disc_type))

        for Dmode in DiscMode:
            if Dmode.name == disc_mode.upper():
                reduction_mode += Dmode.value
                break
        else:
            raise ProductError('Supplied parameter {} is not one of the supported values for discount mode'.format(disc_mode))

        for Dquantity in DiscQuantity:
            if Dquantity.name == disc_quantity.upper():
                # for some reason FPRs have an exception and do not use any of the Discount quantity constants
                if disc_type.upper() != 'FUEL_PRICE_ROLLBACK' and disc_type.upper() != 'PERCENTAGE_FUEL_PRICE_ROLLBACK':
                    reduction_mode += Dquantity.value
                break
        else:
            raise ProductError('Supplied parameter {} is not one of the supported values for discount quantity'.format(disc_quantity))

        if not show_manual_lookup:
            reduction_mode += SHOW_MANUAL_LOOKUP

        if best_deal:
            reduction_mode += BEST_DEAL

        return reduction_mode

    def contains_reduction_id(self, reduction_id: int) -> bool:
        """
        Check whether the relay file contains a reduction ID.

        :param reduction_id: Reduction ID to check.
        :return: Whether the reduction ID is present.
        """

        matches = self._soup.find_all("ReductionId", string=str(reduction_id))
        return len(matches) > 0

    def contains_reduction_id_in_section(self, relay_section: str, reduction_id: int) -> bool:
        """
        Check whether the relay file contains a reduction ID.

        :param relay_section: This specifies the section of the relay to search, it is necessary because a relay file
        can reuse the same column names through multiple sections
        :param reduction_id: Reduction ID to check.
        :return: Whether the reduction ID is preseent.
        """
        match = getattr(self._soup.RelayFile, relay_section).find("ReductionId", string=str(reduction_id))
        return match is not None

    def create_reduction(self, reduction_id: int, description: str, reduction_value: int, disc_type: DiscType,
                         disc_mode: DiscMode, disc_quantity: DiscQuantity, is_discount: bool = True,
                         show_manual_lookup: bool = True, best_deal: bool = False, reduces_tax: bool = False,
                         start_date: str = '2012-06-25T00:00:00', end_date: str = '1899-01-01T00:00:00',
                         max_amount: int = 0, max_quantity: int = 1, card_definition_group_id: int = 0,
                         external_id: str = '', required_security: str = '', retail_item_group_id: int = 0,
                         free_item_flag: bool = False) -> None:
        """
        Creates a new reduction record (discount/coupon/autocombo/FPR/MRD) or modifies an existing one.

        :param reduction_id: Reduction ID, positive values are treated as discounts, negative as coupons.
        :param description: Description of the reduction.
        :param reduction_value: Value of the reduction, 10000 means 1$ or 1%, is ignored if any prompted mode is selected.
        :param disc_type: type of the discount created, names of members from DiscType Enum are expected
        :param disc_mode: mode of the discount created, names of members from DiscMode Enum are expected
        :param disc_quantity: A combination of "Allow only once" and "Stackable" flags, decides whether the discount is
        (not) reapplicable on the same item or on different items in the transaction, names of members from DiscQuantity
        Enum are expected
        :param is_discount: True if reduction record is discount, false if reduction record is coupon
        :param show_manual_lookup: Decides if the new discount should be visible in manual lookup frame
        :param best_deal: Decides if the new discount should be applied to an item which will yield the biggest
        discount automatically
        :param reduces_tax: Decides whether or not the reduction should influence tax or not.
        :param start_date: Date when the reduction starts to be usable.
        :param end_date: Date when the reduction stops being usable.
        :param max_amount: Maximum possible discount value, 0 means no limit
        :param max_quantity: Maximum possible number of reductions in the transaction
        :param card_definition_group_id: Card definition group ID that triggers this discount
        :param external_id: discount external id
        :param required_security: Security level for coupons/discounts, allowed values (LOW/MEDIUM/HIGH/VERY_HIGH), if not provided ''.
        :param retail_item_group_id: Retail item group linked to the 'Reductions record' associated with the coupon.
        :param free_item_flag: If coupon is type Free Item then True, otherwise False.
        """
        reduction_mode = self.calculate_reduction_mode(disc_type, disc_mode, disc_quantity,
                                                     show_manual_lookup, best_deal)

        for SecurityLevel in CouponDiscountSecurityLevel:
            if required_security != '' and SecurityLevel.name == required_security.upper():
                required_security = SecurityLevel.value
                break
        else:
            required_security = 0

        if disc_type.upper() == DiscType.FREE_ITEM.name:
            device_list_id = -1 * int(reduction_id)
            validation_group_id = reduction_id
        else:
            device_list_id = 1
            validation_group_id = 0

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("ReductionId", reduction_id)
            line("DescriptionId", 0)
            line("ReductionMode", reduction_mode)
            line("DeviceListId", device_list_id)
            line("DeviceControl", 0)
            line("RequiredSecurity", required_security)
            line("ReductionValue", reduction_value)
            line("MaxAmount", max_amount)
            line("MaxQuantity", max_quantity)
            line("ReductionItemizerMask", 2147483645)
            line("TaxItemizerMask", 4294967295 if reduces_tax else 0)
            line("ValidationGroupId", validation_group_id)
            line("DepartmentCategoryId", 0)
            line("CardDefinitionGroupId", card_definition_group_id)
            line("StartDate", start_date)
            line("EndDate", end_date)
            line("Description", description)
            line("ExternalId", external_id)
            line("Priority", 0)

        if self.contains_reduction_id_in_section('Reductions', reduction_id):
            parent = self._find_parent('Reductions', 'ReductionId', reduction_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.Reductions, doc)
            self.mark_dirty()

        if int(retail_item_group_id) != 0:
            self.create_reduction_item_requirements(reduction_id, retail_item_group_id, free_item_flag)

    def create_reduction_item_requirements(self, reduction_id: int, retail_item_group_id: int, free_item_flag: bool) -> None:
        """
        Creates a new ReductionItemRequirements record or modifies an existing one.
        This method restricts a given coupon to be used only with a given a retail item group.
        For example, it is used for creating a free item coupon.

        :param reduction_id: Reduction ID. A negative integer is expected, since it's a coupon.
        :param retail_item_group_id: Retail item group linked to the 'Reductions record' associated with the coupon.
        :param free_item_flag: Coupon won't be free, if set to False
        """
        free_item_flag_value = int(free_item_flag == True)

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("ReductionId", reduction_id)
            line("RetailItemGroupId", retail_item_group_id)
            line("FreeItemFlag", free_item_flag_value)

        if self.contains_reduction_id_in_section('ReductionItemRequirements', reduction_id):
            parent = self._find_parent('ReductionItemRequirements', 'ReductionId', reduction_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.ReductionItemRequirements, doc)
            self.mark_dirty()

    def create_reduction_target(self, reduction_id: int, item_id: int, item_type: int, modifier1_id: int = 1, modifier2_id: int = 1, modifier3_id: int = 1) -> None:
        """
        Creates a ReductionTargets record and allows to create a list of items the discount will be applicable for.

        :param reduction_id: Reduction ID to which items will be assigned to be applicable for.
        :param item_id: Item ID.
        :param item_type: Item type.
        :param modifier1_id: Modifier1 ID of the item.
        :param modifier2_id: Modifier2 ID of the item.
        :param modifier3_id: Modifier3 ID of the item.
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("ReductionId", reduction_id)
            line("ItemId", item_id)
            line("Modifier1Id", modifier1_id)
            line("Modifier2Id", modifier2_id)
            line("Modifier3Id", modifier3_id)
            line("ItemType", item_type)

        self._append_tag(self._soup.RelayFile.ReductionTargets, doc)
        self.mark_dirty()


    def get_reduction_id(self, reduction_name: str):
        """
        Get the ID of a reduction with given name.

        :param reduction_name: Reduction name.
        """
        if self.contains_id_in_section('Reductions', 'Description', reduction_name):
            parent = self._find_parent('Reductions', 'Description', reduction_name)
            return parent.find('ReductionId').next
        else:
            return None

