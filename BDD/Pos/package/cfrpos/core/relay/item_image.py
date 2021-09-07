__all__ = [
    "ItemImageRelay"
]

import yattag

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from . import RelayFile


@wrap_all_methods_with_log_trace
class ItemImageRelay(RelayFile):
    """
    Representation of the item image relay file.
    """
    _pos_name = "itemimg"
    _filename = "ItemImg.xml"
    _default_version = 31
    _sort_rules = [
        ("SalesItemDefRecs", [
            ("ItemId", int),
            ("Modifier1DefaultId", int),
            ("Modifier2DefaultId", int),
            ("Modifier3DefaultId", int)
        ]),
        ("SalesItemRecs", [
            ("ItemId", int),
            ("Modifier1Id", int),
            ("Modifier2Id", int),
            ("Modifier3Id", int)
        ]),
        ("ItemBitmap", [
            ("ItemId", int),
            ("Modifier1Id", int),
            ("Modifier2Id", int),
            ("Modifier3Id", int)
        ]),
        ("FuelProductItem", [
            ("ProductNumber", int)
        ]),
        ("AlternativeDescription", [
            ("ItemId", int),
            ("Modifier1Id", int),
            ("Modifier2Id", int),
            ("Modifier3Id", int),
            ("DescriptionUsageCode", str)
        ]),
        ("SalesItemCustomerText", [
            ("ItemId", int)
        ])
    ]

    def contains_item_id(self, item_id: int) -> bool:
        """
        Check whether the relay file contains an item ID.

        :param item_id: Item ID to check.
        :return: Whether the item ID is preseent.
        """

        matches = self._soup.find_all("ItemId", string=str(item_id))
        return len(matches) > 0

    def contains_item_id_in_section(self, relay_section: str, item_id: int) -> bool:
        """
        Check whether the relay file contains an item ID.

        :param relay_section: This specifies the section of the relay to search, it is necessary because a relay file
        can reuse the same column names through multiple sections
        :param item_id: Item ID to check.
        :return: Whether the item ID is preseent.
        """
        match = getattr(self._soup.RelayFile, relay_section).find("ItemId", string=str(item_id))
        return match is not None

    def create_sale_item(self, item_id: int, modifier1_id: int, name: str, price: float, age_restriction: int = 0,
                         age_restriction_before_eff_date: int = 0, effective_date_year: int = 0, effective_date_month: int = 0,
                         effective_date_day: int = 0, credit_category: int = 2010, disable_over_button: bool = False,
                         validate_id: bool = False, manager_required: bool = False, military_age_restriction: int = 0,
                         item_type: int = 1, item_mode: int = 0, pack_size: int = 1, group_id: int = 990000000004,
                         tax_plan_id: int = 0, weighted_item: bool = False, tender_itemizer_rank: int = 0, family_code: int = 0,
                         subcategory_id: int = 990000000002, discount_itemizer_mask: int = 1, owner_id: int = 70000000003, device_id: int = 1) -> None:
        """
        Create a new sale item record or modifies an existing one.

        :param item_id: Item ID.
        :param modifier1_id: Modifier1 ID.
        :param name: Name.
        :param price: Price.
        :param item_type: Item type
        :param item_mode: Item mode
        :param age_restriction: Minimum age required to sell the item.
        :param age_restriction_before_eff_date: Minimum age required to sell the item in case an effective date is supplied and is in the future.
        :param effective_date_year: Year when the age_restriction_before_eff_date limit is replaced with age_restriction
        :param effective_date_month: Month when the age_restriction_before_eff_date limit is replaced with age_restriction
        :param effective_date_day: Day when the age_restriction_before_eff_date limit is replaced with age_restriction
        :param credit_category: The credit category of the item. The default value is 2010 (general merchandise)
        :param disable_over_button: Controls whether or not the Over x button used for instant age verification should be displayed
        :param validate_id: Controls whether or not the ID validation frame should be used after swipe/scan of driver's license during age verification
        :param manager_required: Controls whether or not the manager override is required for manual age verification
        :param military_age_restriction: Minimum age required at age verification check when presenting military ID.
        :param pack_size: Number of items included.
        :param group_id: Autocombo item group ID.
        :param tax_plan_id: ID of the tax plan that will be applied on the item price, 0 stands for no tax.
        :param weighted_item: Tells if the item is weighted or not.
        :param tender_itemizer_rank: Specifies the item restriction level. An item with level 3 can only be paid for by tenders with level 3 or lower.
        :param family_code: Family code.
        :param subcategory_id: Item sub-category identifier.
        :param discount_itemizer_mask: Discount itemizer mask, 0 if item should be set not to be discountable.
        :param device_id: Device ID.
        :param owner_id: Owner ID.
        """

        item_mode_2 = 0
        if disable_over_button:
            item_mode_2 += 0x00008000
        if validate_id:
            item_mode_2 += 0x00020000
        if manager_required:
            item_mode_2 += 0x00010000
        if weighted_item:
            item_mode_2 += 0x00040000

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("ItemId", item_id)
            line("Modifier1Id", modifier1_id)
            line("Modifier2Id", 0)
            line("Modifier3Id", 0)
            line("DescriptionId", 0)
            line("ItemMode", item_mode)
            line("ItemMode2", item_mode_2)
            line("ItemLock", 0)
            line("ItemActive", 1)
            line("CondimentListId", 0)
            line("ComboId", 0)
            line("DepartmentCategoryId", 0)
            line("SubCategoryId", subcategory_id)
            line("ItemType", item_type)
            line("PriceTableId", 0)
            line("ReceiptDescription", name)
            line("AgeMinimum", age_restriction)
            line("AgeMinimumBeforeTransition", age_restriction_before_eff_date)
            line("AgeMinimumTransitionStartDateYear", effective_date_year)
            line("AgeMinimumTransitionStartDateMonth", effective_date_month)
            line("AgeMinimumTransitionStartDateDay", effective_date_day)
            line("MultiGroupFlag", 0)
            line("AgeMinimumWithMilitaryId", military_age_restriction)
            line("GroupId", group_id)
            line("DiscountItemizerMask", discount_itemizer_mask)
            line("TaxPlanScheduleId", tax_plan_id)
            line("AccountableOwnerId", owner_id)
            line("DeviceListId", device_id)
            line("KdsRoutingNumber", 0)
            line("SecuritySentinel", 0)
            line("DeviceControl", 0)
            line("FlavorId", 0)
            line("FlavorCount", 0)
            line("Amount", int(price * 100) * 100)
            line("CreditCategory", credit_category)
            line("TenderItemizerRank", tender_itemizer_rank)
            line("ItemRestrictionGroupId", 0)
            line("ReceiptPriority", 0)
            line("FamilyCode", family_code)
            line("PackSize", pack_size)
            line("LinkedRetailItemGroupId", 0)

        if self.contains_item_id_in_section('SalesItemRecs', item_id):
            parent = self._find_parent('SalesItemRecs', 'ItemId', item_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.SalesItemRecs, doc)

    def create_sale_item_definition(self, item_id: int, modifier1_id: int) -> None:
        """
        Create a new sale item definition record or modifies an existing one.

        :param item_id: Item ID.
        :param modifier1_id: Modifier1 ID.
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("ItemId", item_id)
            line("Modifier1DefaultId", modifier1_id)
            line("Modifier2DefaultId", 0)
            line("Modifier3DefaultId", 0)
            line("Modifier1Required", 0)
            line("Modifier2Required", 0)
            line("Modifier3Required", 0)

        if self.contains_item_id_in_section('SalesItemDefRecs', item_id):
            parent = self._find_parent('SalesItemDefRecs', 'ItemId', item_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.SalesItemDefRecs, doc)

    def flag_military_item_present(self):
        """
        Set the flag indicating at least one item contains military ID age restriction level and therefore the military
        ID button should be displayed during age verification.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("HaveMilitaryAge"):
            text("1")
        military_flag = self._find_tag('HaveMilitaryAge')
        self._modify_tag(military_flag, doc)

    def set_discount_itemizer_mask(self, item_ids: list, discount_itemizer_mask: int) -> None:
        """
        Sets discount itemizer mask to all items having the given item id
        """
        doc, tag, text, line = yattag.Doc().ttl()

        for item_id in item_ids:
            match = getattr(self._soup.RelayFile, 'SalesItemRecs').find_all("ItemId", string=str(item_id))

            for item in match:
                parent = item.parent
                discount_itemizer_mask_tag = parent.find('DiscountItemizerMask')
                discount_itemizer_mask_tag.string = str(discount_itemizer_mask)

            if match:
                self.mark_dirty()

        return None


    def find_group_id(self, item_name: str):
        """
        Method to find which autocombo item group given item belongs.

        :param item_name: Item name to be checked.
        """
        match = getattr(self._soup.RelayFile, 'SalesItemRecs').find('ReceiptDescription', string=item_name)
        return match.parent.find("GroupId").string


    def find_item_id(self, item_name: str):
        """
        Method to find id of the item with provided name.

        :param item_name: Item name to be checked.
        """
        match = getattr(self._soup.RelayFile, 'SalesItemRecs').find('ReceiptDescription', string=item_name)
        return match.parent.find("ItemId").string


    def find_modifier_id(self, item_name: str):
        """
        Method to find modifier1 id of the item with provided name.

        :param item_name: Item name to be checked.
        """
        match = getattr(self._soup.RelayFile, 'SalesItemRecs').find('ReceiptDescription', string=item_name)
        return match.parent.find("Modifier1Id").string