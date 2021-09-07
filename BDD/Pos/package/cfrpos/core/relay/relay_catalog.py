__all__ = [
    "RelayCatalog"
]

from typing import Iterator
import math

from .. bdd_utils.errors import ProductError
from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from .. bdd_utils.performance_stats import PerfomanceCounter, PerformanceStats
from . import (
    AutoComboRelay,
    BarcodeRelay,
    CardRelay,
    ControlRelay,
    ControlOverrideRelay,
    DestinationRelay,
    EmployeeRelay,
    FuelDispenserRelay,
    FuelPumpsRelay,
    ItemImageRelay,
    ItemCodesRelay,
    LockedRetailItemRelay,
    ModifierRelay,
    MenuFramesRelay,
    POSManRelay,
    DevSetRelay,
    DllRelay,
    PrintFormatRelay,
    PrintRouteRelay,
    PromotionsRelay,
    RetailItemGroupRelay,
    ReductionRelay,
    TenderRelay,
    QuantityRestrictionRelay,
    TaxRelay,
    TaxType,
    OrderSourceRelay,
    POSAPINotificationRelay,
    RelayFile
)


@wrap_all_methods_with_log_trace
class RelayCatalog:
    """
    Representation of a collection of relay files. This class provides a
    higher level interface to ensure that the relay files stay synchronized
    with matching information.
    """

    def __init__(self, data_dir: str, initial_id: int = 219000000001, prefer_files: bool = True):
        """
        :param str data_dir: The folder which contains initial configuration files
        :param initial_id: First ID to try generating. Each generated ID will
            increase by 1, unless it needs to skip because of a collision.
        :param prefer_files: If true, try to load the user's custom overrides
            before loading the built-in empty templates.
        """

        self.initial_id = initial_id
        self._next_id = self.initial_id
        self._data_dir = data_dir

        self.autocombo_relay = AutoComboRelay.load(self._data_dir, prefer_files)
        self.barcode_relay = BarcodeRelay.load(self._data_dir, prefer_files)
        self.card_relay = CardRelay.load(self._data_dir, prefer_files)
        self.control_relay = ControlRelay.load(self._data_dir, prefer_files)
        self.control_override_relay = ControlOverrideRelay.load(self._data_dir, prefer_files)
        self.destination_relay = DestinationRelay.load(self._data_dir, prefer_files)
        self.employee_relay = EmployeeRelay.load(self._data_dir, prefer_files)
        self.fuel_dispenser_relay = FuelDispenserRelay.load(self._data_dir, prefer_files)
        self.fuel_pumps_relay = FuelPumpsRelay.load(self._data_dir, prefer_files)
        self.item_image_relay = ItemImageRelay.load(self._data_dir, prefer_files)
        self.item_codes_relay = ItemCodesRelay.load(self._data_dir, prefer_files)
        self.locked_retail_item_relay = LockedRetailItemRelay.load(self._data_dir, prefer_files)
        self.modifier_relay = ModifierRelay.load(self._data_dir, prefer_files)
        self.menu_frames_relay = MenuFramesRelay.load(self._data_dir, prefer_files)
        self.pos_man_relay = POSManRelay.load(self._data_dir, prefer_files)
        self.dev_set_relay = DevSetRelay.load(self._data_dir, prefer_files)
        self.dll_relay = DllRelay.load(self._data_dir, prefer_files)
        self.retail_item_group_relay = RetailItemGroupRelay.load(self._data_dir, prefer_files)
        self.reduction_relay = ReductionRelay.load(self._data_dir, prefer_files)
        self.tender_relay = TenderRelay.load(self._data_dir, prefer_files)
        self.tax_relay = TaxRelay.load(self._data_dir, prefer_files)
        self.print_format_relay = PrintFormatRelay.load(self._data_dir, prefer_files)
        self.print_route_relay = PrintRouteRelay.load(self._data_dir, prefer_files)
        self.promotions_relay = PromotionsRelay.load(self._data_dir, prefer_files)
        self.quantity_restriction_relay = QuantityRestrictionRelay.load(self._data_dir, prefer_files)
        self.order_source_relay = OrderSourceRelay.load(self._data_dir, prefer_files)
        self.pos_api_notification = POSAPINotificationRelay.load(self._data_dir, prefer_files)

    def iter_relays(self) -> Iterator[RelayFile]:
        """
        Yield all relay files in the catalog.

        :return: Relay files.
        """

        for relay in {
            value for key, value in self.__dict__.items()
            if not key.startswith("_")
            and isinstance(value, RelayFile)
        }:
            yield relay

    def iter_update_required(self) -> Iterator[RelayFile]:
        """
        Yield all relay files in the catalog which require update, meaning whichever ones
        have been edited since the catalog's instantiation.

        :return: Relay files.
        """
        for relay in self.iter_relays():
            if relay.update_required:
                yield relay

    def reset(self) -> None:
        """
        Reset all relay files in the catalog to their initial state, clear
        their dirty statuses, and restart ID generation from the initial ID.
        """

        self._next_id = self.initial_id
        for relay in self.iter_relays():
            relay.reset()

    def _get_new_generic_id(self) -> int:
        """
        Generate a new ID without checking for collisions.

        :return: New ID.
        """

        new_id = self._next_id
        self._next_id += 1
        return new_id

    def get_new_item_id(self) -> int:
        """
        Generate the next available item ID.

        :return: New item ID.
        """

        while True:
            candidate = self._get_new_generic_id()
            if not self.item_image_relay.contains_item_id(candidate):
                return candidate

    def get_new_modifier_id(self) -> int:
        """
        Generate the next available modifier ID.

        :return: New modifier ID.
        """

        while True:
            candidate = self._get_new_generic_id()
            if not self.modifier_relay.contains_modifier_id(candidate):
                return candidate

    def get_new_unit_packing_id(self) -> int:
        """
        Generate the next available unit packing ID.

        :return: New unit packing ID.
        """

        while True:
            candidate = self._get_new_generic_id()
            if not self.barcode_relay.contains_unit_packing_id(candidate):
                return candidate

    def get_new_operator_id(self) -> int:
        """
        Generate the next available operator ID.

        :return: New operator ID.
        """

        while True:
            candidate = self._get_new_generic_id()
            if not self.employee_relay.contains_employee_id(candidate):
                return candidate

    def get_new_security_group_id(self) -> int:
        """
        Generate the next available security group ID.

        :return: New security group ID.
        """

        # Needs to be i32, but the catalog's initial ID is too large.
        candidate = 70000001

        while True:
            if not self.pos_man_relay.contains_security_group(candidate):
                return candidate
            candidate += 1

    def _get_new_retail_item_group_id(self) -> int:
        """
        Generate the next available retail item group ID.

        :return: New retail item group ID.
        """

        while True:
            candidate = self._get_new_generic_id()
            if not self.retail_item_group_relay.contains_retail_item_group_id(candidate):
                return candidate

    def _get_new_retail_item_group_external_id(self) -> str:
        """
        Generate the next available retail item group external ID.

        :return: New retail item group ID.
        """

        while True:
            candidate = self._get_new_generic_id()
            if not self.retail_item_group_relay.contains_retail_item_group_external_id(candidate):
                return str(candidate)

    def _get_new_tender_group_id(self) -> int:
        """
        Generate the next available tender group ID.

        :return: New tender group ID.
        """

        while True:
            candidate = self._get_new_generic_id()
            if not self.tender_relay.contains_tender_group_id(candidate):
                return candidate

    def _get_new_reduction_id(self, is_discount) -> str:
        """
        Generate the next available reduction ID.

        :return: New reduction ID.
        """

        while True:
            candidate = self._get_new_generic_id()
            if not self.reduction_relay.contains_reduction_id(candidate):
                if is_discount:
                    return str(candidate)
                else:
                    return str(-candidate)

    def _get_new_itemizer_num(self) -> str:
        """
        Generate the next available reduction ID.

        :return: New Itemizer number.
        """
        new_itemizer_num = 0
        while True:
            new_itemizer_num += 1
            if not self.tax_relay.contains_id_in_section('Itemizers', 'ItemizerNum', new_itemizer_num):
                return new_itemizer_num

    def _get_new_tax_control_id(self) -> str:
        """
        Generate the next available tax control ID.

        :return: New Tax control ID.
        """
        while True:
            candidate = self._get_new_generic_id()
            if not self.tax_relay.contains_id_in_section('TaxControls', 'TaxControlId', candidate):
                return candidate

    def _get_new_tax_plan_schedule_id(self) -> str:
        """
        Generate the next available tax plan schedule ID.

        :return: New Tax Plan Schedule ID.
        """
        while True:
            candidate = self._get_new_generic_id()
            if not self.tax_relay.contains_id_in_section('TaxPlanScheduleTimetables', 'TaxPlanScheduleId', candidate):
                return candidate

    def _get_new_card_definition_id(self) -> str:
        """
        Generate the next available card definition ID.

        :return: New card definition ID.
        """
        while True:
            candidate = self._get_new_generic_id()
            if not self.card_relay.contains_id_in_section('CardDefinitionRecords', 'CardDefinitionId', candidate):
                return candidate

    def _get_new_sale_quantity_id(self) -> int:
        while True:
            candidate = 1
            if not self.quantity_restriction_relay.contains_id_in_section('SalesQuantityAttributes', 'SalesQuantityId', candidate):
                return candidate
            candidate += 1

    def _get_new_card_definition_group_id(self) -> str:
        """
        Generate the next available card definition group ID.

        :return: New card definition group ID.
        """
        while True:
            candidate = self._get_new_generic_id()
            if not self.card_relay.contains_id_in_section('CardDefinitionGroupListRecords', 'card_definition_group_id', candidate):
                return candidate

    def contains_operator_password(self, password: int) -> bool:
        """
        Check if the catalog contains a matching operator.

        :param password: Password to match.
        :return: Whether such an operator exists.
        """

        return self.pos_man_relay.contains_operator_password(password)

    def get_operators_id(self, password: int) -> int:
        """
        Translate operator's pin into his ID

        :param int password: The password of the searched operator
        :return: The id the operator with the given password. -1 if operator does not exist.
        """
        return self.pos_man_relay.get_operators_id(password)

    def create_sale_item(
            self,
            barcode: str,
            price: float,
            name: str,
            item_id: int = None,
            modifier1_id: int = None,
            unit_packing_id: int = None,
            age_restriction: int = 0,
            age_restriction_before_eff_date: int = 0,
            effective_date_year: int = 0,
            effective_date_month: int = 0,
            effective_date_day: int = 0,
            credit_category: int = 2010,
            disable_over_button: bool = False,
            validate_id: bool = False,
            manager_required: bool = False,
            military_age_restriction: int = 0,
            item_type: int = 1,
            item_mode: int = 0,
            pack_size: int = 1,
            group_id: int = 990000000004,
            tax_plan_id: int = 0,
            weighted_item: bool = False,
            tender_itemizer_rank: int = 0,
            family_code: int = 0
    ) -> None:
        """
        Create a new sale item.

        :param barcode: Barcode.
        :param price: Price.
        :param name: Name.
        :param item_id: Item ID. Will be generated if not set.
        :param modifier1_id: Modifier1 ID. Will be generated if not set.
        :param unit_packing_id: Unit packing ID. Will be generated if not set.
        :param item_type: Item type.
        :param item_mode: Item mode.
        :param age_restriction: Minimum age required at age verification check.
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
        """

        if item_id is None:
            item_id = self.get_new_item_id()
        if modifier1_id is None:
            modifier1_id = self.get_new_modifier_id()
            self.create_modifier(1, "bdd-generated", modifier1_id)
        if unit_packing_id is None:
            unit_packing_id = self.get_new_unit_packing_id()
            self.create_unit_packing(1, "bdd-generated", unit_packing_id)
        if credit_category is None:
            credit_category = 2010
        self.barcode_relay.create_barcode(item_id, modifier1_id, barcode, unit_packing_id)
        self.item_image_relay.create_sale_item(item_id, modifier1_id, name, price, age_restriction,
                                               age_restriction_before_eff_date, effective_date_year, effective_date_month,
                                               effective_date_day, credit_category, disable_over_button, validate_id,
                                               manager_required, military_age_restriction, item_type, item_mode,
                                               pack_size, group_id, tax_plan_id, weighted_item, tender_itemizer_rank, family_code)
        self.item_image_relay.create_sale_item_definition(item_id, modifier1_id)

    def set_sale_item_locked(self, item_id: int, modifier1_id: int, locked: bool = True) -> None:
        """
        Lock sale item. This item should exist, create it with create_sale_item().

        :param item_id: Item ID of existing item.
        :param locked: Item should be locked (True) or unlocked (False)
        """
        if locked:
            self.locked_retail_item_relay.create_locked_sale_item(item_id, modifier1_id)
        else:
            self.locked_retail_item_relay.remove_locked_sale_item(item_id)

    def flag_military_item_present(self) -> None:
        """
        Set the flag in ItemImg.xml indicating at least one item contains military ID age restriction level and
        therefore the military ID button should be displayed during age verification.
        """

        self.item_image_relay.flag_military_item_present()

    def set_discount_itemizer_mask(self, discount_itemizer_mask: int, item_ids: list = [], item_name: str = None) -> None:
        """
        Sets discount itemizer mask to all items having the given item id.

        :param discount_itemizer_mask: 0 if item should be set not to be discountable, 4 if discountable.
        :param item_ids: List of the ids of items that should have discountable flag set.
        :param item_name: Name of the item that should be set as discountable.
        """
        if item_name is not None:
            item_id = self.item_image_relay.find_item_id(item_name=item_name)
            if item_id not in item_ids:
               item_ids.append(item_id)
        if item_ids == []:
            raise ProductError("There is no item id provided so item could have set discount itemizer mask.")
        self.item_image_relay.set_discount_itemizer_mask(item_ids=item_ids, discount_itemizer_mask=discount_itemizer_mask)

    def set_control_option(self, option: int, value: int) -> None:
        """
        Create or update a control option.

        :param option: Option to set.
        :param value: New value.
        """

        self.control_relay.set_option(option, value)

    def set_control_parameter(self, option: int, value: str) -> None:
        """
        Create or update a control option parameter.

        :param option: Option parameter to set.
        :param value: New value.
        """

        self.control_relay.set_parameter(option, value)

    def set_control_override_parameter(self, option: int, value: str) -> None:
        """
        Create or update a control override option parameter.

        :param option: Option parameter to set.
        :param value: New value.
        """

        self.control_override_relay.set_parameter(option, value)

    def create_modifier(self, modifier_level: int, description: str, modifier_id: int = None) -> None:
        """
        Create a modifier.

        :param modifier_level: Modifier level.
        :param description: Description.
        :param modifier_id: Modifier ID. Will be generated if not set.
        """

        if modifier_id is None:
            modifier_id = self.get_new_modifier_id()
        self.modifier_relay.create_modifier(modifier_id, modifier_level, description)

    def create_unit_packing(self, pack_quantity: int, description: str, unit_packing_id: int = None) -> None:
        """
        Create a unit packing.

        :param pack_quantity: Pack quantity.
        :param description: Description.
        :param unit_packing_id: Unit packing ID. Will be generated if not set.
        """

        if unit_packing_id is None:
            unit_packing_id = self.get_new_unit_packing_id()
        self.barcode_relay.create_unit_packing(unit_packing_id, pack_quantity, description)

    def create_operator(
            self,
            password: int,
            handle: str,
            last_name: str,
            first_name: str,
            operator_id: int = None,
            external_id: str = "",
            operator_role: str = 'Cashier',
            security_group_id: int = None,
            order_source_id: str = None
    ) -> None:
        """
        Create an operator.

        :param password: Password.
        :param handle: Handle.
        :param last_name: Last name.
        :param first_name: First name.
        :param operator_id: Operator ID. Will be generated if not set.
        :param operator_role: Operator role, can be cashier/manager.
        :param external_id: External ID of operator.
        :param security_group_id: Security group ID, if None it will be generated.
        :param order_source_id: Order source ID.
        """

        if operator_id is None:
            operator_id = self.get_new_operator_id()
        if not self.pos_man_relay.contains_job_code(1):
            self.pos_man_relay.create_job_description(job_code=1, job_code_flags=1, description="Default")
        if order_source_id is not None and self.pos_man_relay.find_order_source_id(order_source_id) is None:
            self.pos_man_relay.create_order_source_id_record(order_source_id, operator_id)
        self.employee_relay.create_employee(operator_id, last_name, first_name)
        self.pos_man_relay.create_operator(operator_id, password, last_name, first_name, handle, external_id, job_codes=[1])

        if security_group_id is None:
            # For now, automatically assign some permissions based on operator 1234
            # from the POS BDD configuration.
            security_group_id = self.get_new_security_group_id()
            self.pos_man_relay.create_security_group(security_group_id, 0, 1081345, operator_role)
            self.pos_man_relay.create_security_group(security_group_id, 10, 2003830647, operator_role)
            self.pos_man_relay.create_security_group(security_group_id, 11, 1080913322, operator_role)
            self.pos_man_relay.create_security_group(security_group_id, 12, 133435340, operator_role)
            self.pos_man_relay.create_security_group(security_group_id, 14, 40, operator_role)
            self.pos_man_relay.create_security_group(security_group_id, 19, 1030, operator_role)
        self.pos_man_relay.create_security_group_assignment(operator_id, security_group_id)

    def create_retail_item_group(self, retail_item_group_id: int = None, external_id: str = None) -> int:
        """
        Create a new retail item group.

        :param retail_item_group_id: ID of the new retail item group.
        :param external_id: External ID of the new retail item group.
        :return: ID of the new retail item group
        """

        if retail_item_group_id is None:
            retail_item_group_id = self._get_new_retail_item_group_id()
        if external_id is None:
            external_id = self._get_new_retail_item_group_external_id()

        self.retail_item_group_relay.create_group(retail_item_group_id, external_id)
        return retail_item_group_id

    def assign_item_to_retail_item_group(self, retail_item_group_id: int, item_id: int, modifier1_id: int = 0,
                                         item_type: int = 1, modifier2_id: int = 0, modifier3_id: int = 0,
                                         item_mode2: int = 0) -> None:
        """
        Assign an existing retail item to an existing retail item group

        :param retail_item_group_id: Retail item group ID
        :param item_id: Item ID
        :param modifier1_id: Modifier 1 ID
        :param item_type: Item type
        :param modifier2_id: Modifier 2 ID
        :param modifier3_id: Modifier 3 ID
        :param item_mode2: Item mode 2
        """

        self.retail_item_group_relay.assign_item_to_group(retail_item_group_id, item_id, modifier1_id, item_type, modifier2_id, modifier3_id)

    def create_reduction(self, description: str, reduction_value: int, disc_type: str, disc_mode: str, disc_quantity: str,
                         is_discount: bool = True, show_manual_lookup: bool = True, best_deal: bool = False,
                         reduction_id: int = None, reduces_tax: bool = False, start_date: str = '2012-06-25T00:00:00',
                         end_date: str = '1899-01-01T00:00:00', max_amount: int = 0, max_quantity: int = 0,
                         card_definition_group_id: int = 0, external_id: str = '', required_security: str = '',
                         retail_item_group_id: int = 0, free_item_flag: bool = False) -> int:
        """
        Creates a new reduction record (discount/coupon/autocombo/FPR/MRD) or modifies an existing one.

        :param reduction_id: Reduction ID.
        :param description: Description.
        :param reduction_value: Value of the reduction, 10000 means 1$ or 1% and is ignored if a prompted type is selected.
        :param disc_type: type of the discount created, accepted values are "FUEL_PRICE_ROLLBACK",
        "PERCENTAGE_FUEL_PRICE_ROLLBACK", "PRESET_AMOUNT", "PRESET_PERCENT", "PRESET_RETAIL_PRICE", "PROMPTED_AMOUNT",
        "PROMPTED_PERCENT" or "PROMPTED_RETAIL_PRICE"
        :param disc_mode: mode of the discount created, accepted values are "SINGLE_ITEM", "WHOLE_TRANSACTION" or
        "EMPLOYEE_DISCOUNT_TRANSACTION"
        :param disc_quantity: decides whether the discount is (not) reapplicable on the same item or on different items
        in the transaction. accepted values are "STACKABLE", "STACKABLE_ONLY_ONCE", "ALLOW_ONLY_ONCE"
        :param is_discount: True if reduction record is discount, false if reduction record is coupon
        :param show_manual_lookup: Decides if the new discount should be visible in manual lookup frame
        :param best_deal: Decides if the new discount should be applied to an item which will yield the biggest
        discount automatically
        :param reduces_tax: Decides whether or not the reduction should influence tax or not.
        :param start_date: Date when the reduction starts to be usable, keep default to already be active.
        :param end_date: Date when the reduction stops being usable, keep default to never expire.
        :param max_amount: Maximum possible discount value, 0 means no limit
        :param max_quantity: Maximum possible number of reductions in the transaction
        :param card_definition_group_id: Card definition group ID that triggers this discount
        :param external_id: discount external id
        :param required_security: Security level for coupons/discounts, allowed values LOW/MEDIUM/HIGH/VERY_HIGH, if not provided ''.
        :param retail_item_group_id: Retail item group linked to the 'Reductions record' associated with the coupon.
        :param free_item_flag: If coupon type is Free Item then True, otherwise False.
        """

        if reduction_id is None:
            reduction_id = self._get_new_reduction_id(is_discount)

        self.reduction_relay.create_reduction(reduction_id, description, reduction_value, disc_type, disc_mode,
                                              disc_quantity, is_discount, show_manual_lookup, best_deal,
                                              reduces_tax, start_date, end_date, max_amount, max_quantity,
                                              card_definition_group_id, external_id, required_security,
                                              retail_item_group_id, free_item_flag)

        return reduction_id

    def create_tender(self, tender_id: int = 70000000023, description: str = 'Cash', tender_type_id: int = 1, exchange_rate: int = 1,
                      currency_symbol: str = '$', external_id: str = '', tender_mode: int = 1331912704, tender_mode_2: int = 16, create_buttons: bool = True, device_control: int = 131072,
                      required_security: int = 0) -> None:
        """
        Creates a new tender record or modifies an existing one. Most of the values are hardcoded based on a default
        cash tender and will be implemented later if needed. If the created tender does not have a tender button, it
        creates one with the manual entry frame and exact dollar, next dollar and quick 20 buttons.

        :param tender_id: tender ID, leaving the default value will modify existing cash tender
        :param tender_type_id: tender type ID
        :param description: description of the tender, will be displayed on VR, reports, etc.
        :param exchange_rate: conversion rate against the site's default currency
        :param currency_symbol: currency symbol to be used with this tender
        :param tender_mode: tender mode flags for this tender
        :param tender_mode_2: tender mode flag for this tender
        :param create_buttons: indicates whether the tender buttons will be created for this tender
        :param device_control: receipt print and drawer options
        """
        self.tender_relay.create_tender(tender_id, description, tender_type_id, exchange_rate, currency_symbol, tender_mode, tender_mode_2, device_control, required_security)
        if not self.tender_relay.contains_tender_id_in_section('TenderButtons', tender_id) and create_buttons:
            self.tender_relay.create_tender_button(tender_id, description)
            self.tender_relay.create_tender_button(tender_id, description, action='EXACT_DOLLAR')
            self.tender_relay.create_tender_button(tender_id, description, action='NEXT_DOLLAR')
            self.tender_relay.create_tender_button(tender_id, description, action='QUICK_TENDER_BUTTON', preset_amount=200000)
        if external_id != '':
            self.tender_relay.create_tender_external_id(tender_id, external_id)

    def create_tender_type(self, tender_type_id: int, description: str, tender_ranking: int, tier_number: int = 0):
        """Creates a new tender type record or modifies an existing one.

        :param tender_type_id: Tender type ID.
        :param description: Tender description.
        :param tender_ranking: Tender restriction level. An item with level 3 can only be paid for by tenders with level 3 or lower.
        :param tier_number: Tier number, Cash = 1, Credit = 2
        """
        self.tender_relay.create_tender_type(tender_type_id=tender_type_id, description=description, tender_ranking=tender_ranking, tier_number=tier_number)

    def create_tender_group(self, description: str, tender_group_id: int = None, position: int = None) -> int:
        """
        Creates a tender bar group and its button. This functionality was merged from a PS project and helps group tender
        buttons together to save space and lengthy scrolling through the dynamic tender bar. Once a group button is pressed,
        a frame with a 4x4 button grid is displayed with assigned tenders to choose from.
        :param tender_group_id: ID of the tender group being created.
        :param description: Button text for the new tender group button.
        :param position: Position of the new button on the tender bar. If none is supplied, the first free one is used.
        """
        if tender_group_id is None:
            tender_group_id = self._get_new_tender_group_id()
        self.tender_relay.create_tender_group(tender_group_id, description, position)
        return tender_group_id

    def assign_tender_to_group(self, tender_group_id: int, tender_id: int) -> None:
        """
        Assigns a tender to a preexisting tender group.
        :param tender_group_id: ID of the target tender group.
        :param tender_id: ID of the tender being assigned.
        """
        self.tender_relay.assign_tender_to_group(tender_group_id, tender_id)

    def enable_feature(self, feature: str) -> None:
        """
        Enable a feature.
        :param feature: Feature name.
        """
        self.dll_relay.enable_feature(feature)

    def disable_feature(self, feature: str) -> None:
        """
        Disable a feature.
        :param feature: Feature name.
        """
        self.dll_relay.disable_feature(feature)


    def create_tax(self, tax_description: str, tax_type: TaxType, tax_value: float,
                   effective_year: int=2000, effective_month: int=1, effective_day: int=1,
                   itemizer_num: int=None, tax_control_id: int=None, tax_authority_id: int=70000000004, destination_id: int=None) -> int:
        """
        Creates a tax and a tax rate or modifies an existing one.

        :param str tax_description: Description of the tax.
        :param TaxType tax_type: Enum, what type of the tax should be created. For example TaxType.PERCENT
        :param float tax_value: The value of the tax. For percentage tax, it is in percent (8.88%)
        :param int effective_year: The year of the date, when the tax starts to be effective.
        :param int effective_month: The month of the date, when the tax starts to be effective.
        :param int effective_day: The day of the date, when the tax starts to be effective.
        :param int itemizer_num: The ID of the tax. If none, the ID is automatically generated.
        :param int tax_control_id: The ID of the tax rate. If none, the ID is automatically generated.
        :param int tax_authority_id: The ID of the authority of the tax.
        :param int destination_id: Determines whether the item will be consumed on premise or as take away, this can result in different tax rates in some states.
        :return int: The itemizer_num generated by this class or given by user.
        """

        if tax_control_id is None:
            tax_control_id = self._get_new_tax_control_id()
        else:
            if itemizer_num is None:
                itemizer_num = self.tax_relay.find_itemizer_num(tax_control_id)
            if tax_value is None:
                tax_value = 0.0
        self.tax_relay.create_tax_rate(tax_control_id, tax_value,
                                    effective_year, effective_month, effective_day, destination_id)

        if itemizer_num is None:
            itemizer_num = self._get_new_itemizer_num()
        if tax_description is None:
            tax_description = self.tax_relay.create_tax_description("Tax_{itemizer}".format(itemizer=itemizer_num))
        return self.tax_relay.create_tax(itemizer_num, tax_control_id, tax_description,
                                tax_authority_id, tax_type)


    def create_tax_plan_with_tax(self, itemizer_mask: int, plan_description: str,
                                tax_plan_schedule_id: int=None, allow_tax_change_on_pos: bool=True,
                              effective_year: int=1900, effective_month: int=1, effective_day: int=1) -> int:
        """
        Creates a tax plan with given tax or modifies an existing one.

        :param int itemizer_mask: Combined IDs of all taxes applicable in the tax plan.
        :param str plan_description: The description of the plan.
        :param int tax_plan_schedule_id: The ID of the tax plan schedule. If none, the ID is automatically generated.
        :param bool allow_tax_change_on_pos: If the tax is allowed to be changed on POS.
        :param int effective_year: The year of the date, when the tax starts to be effective.
        :param int effective_month: The month of the date, when the tax starts to be effective.
        :param int effective_day: The day of the date, when the tax starts to be effective.
        :return int: The tax_plan_schedule_id generated by this class or given by user.
        """
        if tax_plan_schedule_id is None:
            tax_plan_schedule_id = self._get_new_tax_plan_schedule_id()

        self.tax_relay.create_tax_plan_with_tax(tax_plan_schedule_id, itemizer_mask, plan_description,
                                    allow_tax_change_on_pos, effective_year, effective_month, effective_day)


    def create_card(self, card_role: int, name: str, barcode_range_from: str,
                   card_definition_group_id: int = None,
                   card_definition_id: int = None, barcode_range_to: str = None, track_format_1: str = '', track_format_2: str = '', mask_mode: int = 0) -> None:
        """
        Creates a card record or modifies an existing one.

        :param card_definition_id: Card definition ID.
        :param card_role: Card role number.
        :param name: Card name.
        :param card_definition_group_id: Card definition group ID.
        :param barcode_range_from: Barcode range from.
        :param barcode_range_to: Barcode range to.
        :param track_format_1: Card track format 1, needed in case of MSRCardNumberRangeListRecords usage.
        :param track_format_2: Card track format 2, needed in case of MSRCardNumberRangeListRecords usage.
        :param mode_mask: Card mode mask. Reads order of track data.
        """

        barcode_len = len(barcode_range_from)

        if card_definition_id is None:
            card_definition_id = self._get_new_card_definition_id()

        if card_definition_group_id is None:
            card_definition_group_id = self._get_new_card_definition_group_id()

        if barcode_range_to is None:
            barcode_range_to = barcode_range_from

        self.card_relay.create_card_definition(card_definition_id, card_role, name, barcode_len, track_format_1, track_format_2, mask_mode)
        self.card_relay.create_card_definition_group(card_definition_id, card_definition_group_id)
        self.card_relay.create_barcode_range_list(card_definition_id, barcode_range_from, barcode_range_to)
        self.card_relay.create_msr_range_list(card_definition_id, barcode_range_from, barcode_range_to)

    def create_quantity_restriction(self, retail_item_group_id: int, item_id: int, modifier1_id: int, modifier2_id: int,
                                   modifier3_id: int, quantity: int, transaction_limit: int = None, description: str = None,
                                   sale_quantity_id: int = None):
        """
        Creates a quantity restriction or modifies an existing one.

        :param retail_item_group_id: Retail item group id to apply the restriction to.
        :param item_id: Item ID of the item to receive the restriction attribute.
        :param modifier1_id: Modifier1 ID of the item.
        :param modifier2_id: Modifier2 ID of the item.
        :param modifier3_id: Modifier3 ID of the item.
        :param quantity: Amount which the item contributes into the transaction restriction limit.
        :param transaction_limit: Transaction restriction limit, once reached no additional item can be added.
        :param description: Description of the restriction.
        :param sale_quantity_id: Unique ID for the created restriction.
        """

        if sale_quantity_id is None:
            sale_quantity_id = self._get_new_sale_quantity_id()

        if description is not None:
            self.quantity_restriction_relay.create_sales_quantity_attributes(sale_quantity_id, description)

        if transaction_limit is not None:
            self.quantity_restriction_relay.create_sales_quantity_restrictions(retail_item_group_id,
                                                                  sale_quantity_id, transaction_limit)

        self.quantity_restriction_relay.create_retail_item_sales_quantity_attributes(item_id,
                                 modifier1_id, modifier2_id, modifier3_id, sale_quantity_id, quantity)

    def collect_performance(self):
        summary = PerformanceStats()
        for relay_name in dir(self):
            relay = getattr(self, relay_name)
            if isinstance(relay, RelayFile):
                summary.add(relay.performance_stats)
        return summary

    def create_kps(self):
        self.dev_set_relay.create_device_record(device_type='KDS', logical_name='KDS', device_name='X', port_name='X', data_info='X', location='X')

    def create_pump(self, fueling_point: int, hose_number: int = 1, product_number: int = 70000019, unit_price: int = 1000):
        """
        This method allows to create or modify a pump.

        :param fueling_point: Fuel point number.
        :param hose_number: Hose number.
        :param product_number: Hose product number.
        :param unit_price: Fuel price.
        """
        self.fuel_pumps_relay.create_pump_configuration_record(fueling_point)
        self.fuel_pumps_relay.create_pump_week_time_records(fueling_point)
        self.dev_set_relay.create_device_record(device_type='FuelPumps', logical_name='FUEL100/10002/3', device_name='X', port_name='X',
                                    data_info='0' + str(fueling_point), parameters=fueling_point, location='Virtual')
        self.fuel_dispenser_relay.create_fueling_point_record(fueling_point)
        self.fuel_dispenser_relay.create_hose_record(fueling_point, hose_number=hose_number, product_number=product_number, primary_tank=hose_number)
        self.fuel_dispenser_relay.create_tier_service_mode_prices(fueling_point=fueling_point, hose_number=hose_number, unit_price=unit_price)

    def create_pump_with_hoses(self, fueling_point: int, hoses: list):
        self.fuel_pumps_relay.create_pump_configuration_record(fueling_point)
        self.fuel_pumps_relay.create_pump_week_time_records(fueling_point)
        self.dev_set_relay.create_device_record(device_type='FuelPumps', logical_name='FUEL100/10002/3', device_name='X', port_name='X',
                                    data_info='0' + str(fueling_point), parameters=fueling_point, location='Virtual')
        self.fuel_dispenser_relay.create_fueling_point_record(fueling_point)
        for hose in hoses:
            self.fuel_dispenser_relay.create_hose_record(fueling_point, hose_number=hose["hose_number"], product_number=hose["product_number"], primary_tank=hose["hose_number"])
            self.fuel_dispenser_relay.create_tier_service_mode_prices(fueling_point=fueling_point, hose_number=hose["hose_number"], unit_price=hose["unit_price"])

    def create_receipt_section(self, receipt_sections, section_name) -> [list, int]:
        """
        Checks if receipt section is created, if not, creates a new one.

        :param receipt_sections: List of already created receipts sections.
        :param section_name: Section name.
        :return: Updated list of all created sections, and section ID of new section if created.
        """
        if not self.print_route_relay.contains_name_in_list(receipt_sections, section_name):
            section_id = self.print_format_relay.get_new_section_id()
            receipt_sections.append({section_name: section_id})
        return receipt_sections, section_id

    def create_receipt(self, receipts_available, receipt_sections, receipt, section) -> list:
        """
        Checks if receipt is already created, if not, creates a new one.

        :param receipts_available: List of already created receipts.
        :param receipts_sections: List of already created receipts sections.
        :param receipt: Receipt with name to be set active.
        :param section: Section name.
        :return: Updated list of all available receipts.
        """
        if not self.print_route_relay.contains_name_in_list(receipts_available, receipt):
            group_id = self.print_format_relay.get_new_group_id()
            receipts_available.append({receipt: group_id})
        else:
            receipt_available = self.print_route_relay.contains_name_in_list(receipts_available, receipt)
            group_id = receipt_available[receipt]
        if self.print_route_relay.contains_name_in_list(receipt_sections, section):
            receipt_sections = self.print_route_relay.contains_name_in_list(receipt_sections, section)
            section_id = receipt_sections[section]
        else:
            raise ProductError("There is no section [{}] defined.".format(section))
        self.print_format_relay.create_group_record(PrintFormatRelay.GroupRec(print_type_group_id=group_id, print_section_id=section_id))
        return receipts_available

    def create_autocombo(self, description: str, quantity: int, combo_id: int, external_id: str = '', group_id: int = 990000000004, modifier1_id: int = 990000000007) -> None:
        """
        Create an autocombo discount.

        :param description: Autocombo description.
        :param quantity: Item quantity for autocombo to be applied on.
        :param combo_id: Autocombo ID.
        :param external_id: External autocombo ID.
        :param group_id: Autocombo item group ID.
        :param modifier1_id: Modifier1 ID of the item that triggers autocombo.
        """
        self.autocombo_relay.create_autocombo_record(combo_id=combo_id, description=description, external_id=external_id)
        if external_id != '':
            self.autocombo_relay.create_autocombo_external_id(combo_id=combo_id, external_id=external_id)
        self.autocombo_relay.create_requirement_record(description=description, requirement_id=combo_id, group_id=group_id, quantity_required=quantity)
        self.autocombo_relay.create_discount_id(requirement_id=combo_id, discount_id=combo_id)
        self.autocombo_relay.create_item_group_record(item_id=combo_id, modifier_id=modifier1_id, group_id=group_id)

    def create_button_on_frame(self, frame_name: str, text_string: str, button_left: int, button_top: int,
                               action_event: int=10144, action_sub_event:int=0) -> None:
        """
        Create a button on a desired frame.

        :param frame_name: Frame name.
        :param text_string: Name of the button to be created.
        :param action_event: Action event.
        :param button_left: First coordinate of the button on a frame grid.
        :param button_top: Second coordinate of the button on a frame grid.
        :param action_event: Action event assigned to the button, defines what will happen after button is pressed.
        Default value 1044 means go back action.
        :param action_sub_event: Action sub event assigned to the button.
        """
        button = self.menu_frames_relay.find_button(frame_name, text_string)
        if button is None:
            self.menu_frames_relay.create_button_record(frame_name=frame_name, button_left=button_left, button_top=button_top)
            match_record = self.menu_frames_relay.find_button_record(frame_name=frame_name, button_left=button_left, button_top=button_top)
            self.menu_frames_relay.create_button_state(frame_name=frame_name, button_left=button_left, button_top=button_top)
            self.menu_frames_relay.create_button_action(frame_name=frame_name, button_left=button_left, button_top=button_top, action_event=action_event, action_sub_event=action_sub_event)
            self.menu_frames_relay.create_button_text(frame_name=frame_name, button_left=button_left, button_top=button_top, text_string=text_string)
        else:
            raise ProductError("Given button [{}] already exists on the frame [{}].".format(text_string, frame_name))

    def define_order_source_behavior(self, external_id: str, defer_verification: bool) -> None:
        """
        Creates a record defining the pos connect age restriction behavior of orders coming from a source specified by
        its external ID or modifies an existing record.

        :param external_id: ID of the order source whose behavior will be set.
        :param defer_verification: True if all age restricted items in the pos connect request should be accepted and
        verified later, False if the order should get rejected if it contains AR items.
        """
        self.order_source_relay.define_order_source_behavior(external_id, defer_verification)

    def create_notification_uri(self, notification_id: int, terminal_node: int, notification_uri: str, device_name: str) -> None:
        """
        Create new or update existing pos api notification record which provides notification uri on which message should be sent
        :param notification_id: unique id for configured controller
        :param terminal_node: Pos node on which end points are configured.
        :param notification_uri: Controller end points on which Pos should send the message
        :param device_name: device where the message will be sent by controller
        """
        self.pos_api_notification.create_notification_uri(notification_id, terminal_node, notification_uri, device_name)

    def create_notification_topic(self, topic_notification_id: int, notification_id: int, topic_id: str) -> None:
        """
        Creates notification topic which will be part of payload sent to corresponding configured controller
        :param topic_notification_id: Distinct id to each topic configured for notification
        :param notification_id: Maps to controller for which different topics are added
        :param topic_id: topicid as part of payload tells controller what command to be sent on device
        """
        self.pos_api_notification.create_notification_topic(topic_notification_id, notification_id, topic_id)

    def create_destination(self, description: str, destination_id: int = None, external_id: int = None, device_list_id: int = None, kds_dest_id: int = None) -> int:
        """
        Creates destination (tax relevant POS attribute).

        :param str description: Destination description text.
        :param int destination_id: Unique Destination ID.
        :param int external_id: Destination external ID.
        :param int device_list_id: Device list ID.
        :param int kds_dest_id: KDS destination ID.
        :return int: Destination ID of created or modified destination.
        """
        if destination_id is None:
            destination_id = self._get_new_destination_id()
        if not device_list_id:
            device_list_id = 1
        if not kds_dest_id:
            kds_dest_id = destination_id
        if not external_id:
            external_id = destination_id

        return self.destination_relay.create_destination(destination_id=destination_id, device_list_id=device_list_id, description=description, kds_dest_id=kds_dest_id, external_id=external_id)

    def _get_new_destination_id(self) -> int:
        """
        Generate the next available destination ID.

        :return: New destination ID.
        """
        while True:
            candidate = self._get_new_generic_id()
            if not self.destination_relay.contains_destination_id(candidate):
                return candidate

    def create_loyalty_program(self, external_id: str, program_name: str):
        """
        Creates a loyalty program. The program will be listed in picklist displayed on pinpad, in case of use of Alternate ID.
        :param external_id: Loyalty program external ID.
        :param program_name: Loyalty program name.
        """
        loyalty_program_id = self.card_relay.create_loyalty_program_id()
        self.card_relay.create_loyalty_program(loyalty_program_id, external_id, program_name)

    def assign_card_to_loyalty_program(self, card_definition_id: str, program_name: str):
        """
        Assigns a card to loyalty program with given name.

        :param card_definition_id: Card definition ID.
        :param program_name: Loyalty program name.
        """
        loyalty_program_id = self.card_relay.get_loyalty_program_id(program_name)
        self.card_relay.assign_card_to_loyalty_program(loyalty_program_id, card_definition_id)

    def clear_existing_loyalty_programs(self):
        """
        Remove all created loyalty programs.
        """
        self.card_relay.remove_existing_loyalty_programs()

    def set_fuel_grades_for_fpr(self, reduction_id: int, fuel_grades: list = [{'grade_id': 5070000019, 'modifier_id': 70000019}, {'grade_id': 5070000020, 'modifier_id': 70000020},
                                                                             {'grade_id': 5070000021, 'modifier_id': 70000021}, {'grade_id': 5070000022, 'modifier_id': 70000022}]):
        """
        Sets general prepay item and all grades to be eligable for FPR discount.

        :param reduction_id: Reduction ID.
        :param fuel_grades: Fuel grades to be set for FPR discounts.
        """
        self.reduction_relay.create_reduction_target(reduction_id=reduction_id, item_id=5000000001, item_type=7)
        for item in fuel_grades:
            self.reduction_relay.create_reduction_target(reduction_id=reduction_id, item_id=item['grade_id'], item_type=7, modifier1_id=item['modifier_id'])
            self.reduction_relay.create_reduction_target(reduction_id=reduction_id, item_id=item['grade_id'], item_type=7, modifier1_id=item['modifier_id'], modifier3_id=2)


    def set_relay_records_for_fpr(self, description: str, reduction_id: int, trigger_type: int = 26):
        """
        Sets relay records needed to trigger FPR discount for prepay item.

        Note: Group ID value 990000000009 is requirement group id for all items that could trigger FPR discounts. All the fuel items that the discount should be applied to
              will be grouped under new requirement group id.
              Two requirement IDs are needed so one points to the fuel item the discount will be applied at and
              one points to the item that needs to be in transaction so discount is applied.

        :param description: FPR name.
        :param reduction_id: Reduction ID of the FPR.
        :param trigger_type: Type of the item that triggers FPR, by default loyalty card.
        """
        combo_id = self.autocombo_relay.create_new_autocombo_id()
        fuel_group_id = self.autocombo_relay.create_new_combo_group_id()
        requirement_id_1 = self.autocombo_relay.create_new_requirement_id()
        requirement_id_2 = requirement_id_1 + 1
        self.autocombo_relay.create_autocombo_record(combo_id, description, mode_flag=1, max_per_tran=3)
        self.autocombo_relay.create_item_group_record(item_id=0, modifier_id=0, group_id=990000000009, item_type=trigger_type)
        self.autocombo_relay.create_item_group_record(item_id=5000000001, modifier_id=0, group_id=fuel_group_id, item_type=0)
        self.autocombo_relay.create_requirement_record(description=description, requirement_id=requirement_id_1, group_id=990000000009, mode_flag=4,quantity_required=0, amount_required=0)
        self.autocombo_relay.create_requirement_record(description=description, requirement_id=requirement_id_2, group_id=fuel_group_id, quantity_required=0, amount_required=100)
        self.autocombo_relay.create_discount_id(requirement_id=requirement_id_2, discount_id=reduction_id)
        self.item_image_relay.create_sale_item(name='Prepaid Fuel', item_id=5000000001, group_id=fuel_group_id, item_type=7, modifier1_id=0, price=0, credit_category=600)