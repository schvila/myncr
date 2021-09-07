from behave import *
from behave.runner import Context
import math
import time

from cfrpos.core.bdd_utils.pos_utils import POSUtils
from cfrpos.core.pos.ui_metadata import POSFrame, POSButton


# region Given clauses (configuration)
@given('the POS has a sale item with barcode {barcode} and price {price:f}')
def step_impl(context: Context, barcode: str, price: float):
    pass


@given('the POS has essential configuration')
def step_impl(context: Context):
    if context.dc_server.is_active():
        context.dc_server.shutdown_server()
    context.pos.relay_catalog.reset()


@given('the POS has following sale items configured')
def step_impl(context: Context):
    # Use context.table with columns:
    # * 'barcode' (optional),
    # * 'price',
    # * 'description' (optional),
    # * 'external_id' (optional),
    # * 'internal_id' (optional)
    # This method will be replaced with "the pricebook contains retail items"
    pass


@given('the POS has following discount triggers configured')
def step_impl(context: Context):
    # Use context.table with columns:
    # * 'barcode',
    # * 'description',
    # * 'price'
    pass


@given('the following cashiers are configured')
def step_impl(context: Context):
    # Use context.table with columns:
    # * 'first_name'
    # * 'last_name'
    # * 'security_role'
    # * 'PIN'
    pass


@given('the POS has following discounts configured')
def step_impl(context: Context):
    # Use context.table with columns:
    # * 'description',
    # * 'price', positive value,
    # * 'external_id',
    # * 'card_definition_group_id' (optional)
    for row in context.table:
        context.pos.relay_catalog.create_reduction(row["description"],
            POSUtils.convert_float_to_pos_amount(row["price"]),
            'Preset_Amount', 'Single_Item', 'Stackable',
            card_definition_group_id=int(row["card_definition_group_id"]) if "card_definition_group_id" in row.headings else 0,
            external_id=row["external_id"], reduction_id=row["reduction_id"] if "reduction_id" in row.headings else None)


@given('the pricebook contains retail items')
def step_impl(context: Context):
    military_item_present = False
    for row in context.table:
        item_id = int(row["item_id"]) if "item_id" in row.headings else None
        modifier1_id = int(row["modifier1_id"]) if "modifier1_id" in row.headings else None
        unit_packing_id = int(row["unit_packing_id"]) if "unit_packing_id" in row.headings else 990000000007
        age_restriction = int(row["age_restriction"]) if "age_restriction" in row.headings else 0
        age_restriction_before_eff_date = int(row["age_restriction_before_eff_date"]) if "age_restriction_before_eff_date" in row.headings else 0
        effective_date_year = int(row["effective_date_year"]) if "effective_date_year" in row.headings else 0
        effective_date_month = int(row["effective_date_month"]) if "effective_date_month" in row.headings else 0
        effective_date_day = int(row["effective_date_day"]) if "effective_date_day" in row.headings else 0
        credit_category = int(row["credit_category"]) if "credit_category" in row.headings else None
        item_type = int(row["item_type"]) if "item_type" in row.headings else 1
        item_mode = int(row["item_mode"]) if "item_mode" in row.headings else 0
        pack_size = int(row["pack_size"]) if "pack_size" in row.headings else 1
        group_id = int(row["group_id"]) if "group_id" in row.headings else 990000000004
        tax_plan_id = int(row["tax_plan_id"]) if "tax_plan_id" in row.headings else 7
        tender_itemizer_rank = int(row["tender_itemizer_rank"]) if "tender_itemizer_rank" in row.headings else 0
        family_code = int(row["family_code"]) if "family_code" in row.headings else 0
        if "military_age_restriction" in row.headings:
            military_age_restriction = int(row["military_age_restriction"])
            military_item_present = True
        else:
            military_age_restriction = 0
        disable_over_button = False
        if "disable_over_button" in row.headings:
            if str(row["disable_over_button"]).lower() in ['true', '1', 'yes']:
                disable_over_button = True
        weighted_item = False
        if "weighted_item" in row.headings:
            if str(row["weighted_item"]).lower() in ['true', '1', 'yes']:
                weighted_item = True
        validate_id = False
        if "id_validation_required" in row.headings:
            if str(row["id_validation_required"]).lower() in ['true', '1', 'yes']:
                validate_id = True
        manager_required = False
        if "manager_override_required" in row.headings:
            if str(row["manager_override_required"]).lower() in ['true', '1', 'yes']:
                manager_required = True

        context.pos.relay_catalog.create_sale_item(row["barcode"], float(row["price"]), row["description"],
                                                    item_id, modifier1_id, unit_packing_id,
                                                    age_restriction, age_restriction_before_eff_date,
                                                    effective_date_year, effective_date_month,
                                                    effective_date_day, credit_category, disable_over_button,
                                                    validate_id, manager_required, military_age_restriction,
                                                    item_type, item_mode, pack_size, group_id, tax_plan_id,
                                                    weighted_item, tender_itemizer_rank, family_code)

    if military_item_present:
        context.pos.relay_catalog.flag_military_item_present()

@given('an item {item_name} is set not to be discountable')
def step_impl(context: Context, item_name: str):
    context.pos.relay_catalog.set_discount_itemizer_mask(item_name=item_name, discount_itemizer_mask=0)


@given('an item {item_name} is set to be discountable')
def step_impl(context: Context, item_name: str):
    context.pos.relay_catalog.set_discount_itemizer_mask(item_name=item_name, discount_itemizer_mask=4)


@given('the POS has the feature {feature} enabled')
def step_impl(context: Context, feature: str):
    context.pos.relay_catalog.enable_feature(feature)


@given('the POS has the feature {feature} disabled')
def step_impl(context: Context, feature: str):
    context.pos.relay_catalog.disable_feature(feature)


@given('the POS parameter {option} is set to {value}')
def step_impl(context: Context, option: int, value: str):
    context.pos.relay_catalog.set_control_override_parameter(option, value)


@given('the POS option {option} is set to {value}')
def step_impl(context: Context, option: int, value: int):
    context.pos.relay_catalog.set_control_option(option, value)


@given('the POS control parameter {parameter} is set to {value}')
def step_impl(context: Context, parameter: int, value: int):
    context.pos.relay_catalog.control_override_relay.delete_parameter_rec(parameter)
    context.pos.relay_catalog.set_control_parameter(parameter, value)


@given('the POS recognizes following cards')
def step_impl(context: Context):
    # Use context.table with columns:
    # * 'card_role',
    # * 'name',
    # * 'barcode_range_from',
    # * 'barcode_range_to' (optional),
    # * 'card_definition_id' (optional)
    # * 'card_definition_group_id' (optional)
    for row in context.table:
        barcode_range_to = row["barcode_range_to"] if "barcode_range_to" in row.headings else None
        card_definition_id = row["card_definition_id"] if "card_definition_id" in row.headings else None
        card_definition_group_id = row["card_definition_group_id"] if "card_definition_group_id" in row.headings else None
        track_format_1 = row["track_format_1"] if "track_format_1" in row.headings else ''
        track_format_2 = row["track_format_2"] if "track_format_2" in row.headings else ''
        mask_mode = row["mask_mode"] if "mask_mode" in row.headings else 0

        context.pos.relay_catalog.create_card(row["card_role"], row["card_name"],
                                             row["barcode_range_from"],
                                             card_definition_group_id,
                                             card_definition_id, barcode_range_to, track_format_1, track_format_2, mask_mode)


@given('the KPS has essential configuration')
def step_impl(context: Context):
    context.pos.relay_catalog.create_kps()


@given('the following destinations are configured')
def step_impl(context: Context):
    for row in context.table:
        destination_id = int(row["destination_id"]) if "destination_id" in row.headings else None
        description = row["description"] if "description" in row.headings else None
        external_id = int(row["external_id"]) if "external_id" in row.headings else None

        assert context.pos.relay_catalog.create_destination(destination_id=destination_id,
                                                    description=description, external_id=external_id)
# endregion


# region Given clauses (state)
@given('the POS is in a ready to sell state')
def step_impl(context: Context):
    if context.pos.is_someone_signed_in() and not context.pos.is_signed_in(operator_name="1234, 🞀Cashier🞁"):
        context.pos.ensure_ready_to_start_shift()
    context.pos.send_config()
    context.pos.ensure_ready_to_sell()
    context.fuel_sim.reset_fuel_sim()
    context.sc.reset_sim_requests()
    context.sc.reset_tran_repository()
    if 'pes' in context.tags or 'ulp' in context.tags:
        context.pos.control.begin_waiting_for_event('pes-response-processed')


@given('the POS is set to {state} state')
def step_impl(context: Context, state: str):
    if state.lower() == 'ready':
        context.pos.ensure_ready_to_sell()
    elif state.lower() == 'locked':
        context.pos.lock_pos()
    else:
        assert False, 'Device state "{}" is not a valid state.'.format(state)


@given('an item with barcode {item_barcode} is present in the transaction')
def step_impl(context: Context, item_barcode: str):
    context.pos.scan_item_barcode(barcode=item_barcode, barcode_type="UPC_EAN")
    assert context.pos.wait_for_item_added(barcode=item_barcode)


@given('an item with barcode {item_barcode} is present in the transaction {item_count:d} times')
def step_impl(context: Context, item_barcode: str, item_count: int):
    count = int(item_count)
    while count > 0:
        context.pos.scan_item_barcode(barcode=item_barcode)
        context.pos.wait_for_item_added(item_barcode)
        count = count - 1


@given('the cashier stored the transaction')
def step_impl(context: Context):
    context.pos.store_transaction()
    assert context.pos.get_current_transaction() is None


@given('the transaction was voided by manager with pin {manager_pin:d} for a reason {reason}')
def step_impl(context: Context, manager_pin: int, reason: str):
    context.pos.void_transaction(manager_pin=manager_pin, reason=reason)


@given('the POS displays Select reason frame after voiding a transaction with the pin {manager_pin}')
def step_impl(context: Context, manager_pin: int):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.VOID_RECEIPT)
    context.pos.wait_for_frame_open(POSFrame.ASK_SECURITY_OVERRIDE)
    context.pos.press_digits(POSFrame.ASK_SECURITY_OVERRIDE, manager_pin)
    context.pos.press_button_on_frame(POSFrame.ASK_SECURITY_OVERRIDE, POSButton.ENTER)
    context.pos.wait_for_frame_open(POSFrame.ASK_FOR_A_REASON)


@given("no shift is started on the POS")
def step_impl(context: Context):
    if context.pos.is_someone_signed_in():
        context.sc.close_pos_shift(context.pos.node_number)
        context.pos.restart()
        context.pos.press_button_on_frame(POSFrame.MSG_OPERATOR_NOT_OPENED, POSButton.GO_BACK)


@given('the POS is locked')
def step_impl(context: Context):
    context.pos.lock_pos()


@given('an empty transaction is in progress')
def step_impl(context: Context):
    context.pos.scan_item_barcode('0')
    context.pos.press_button_on_frame(POSFrame.MSG_ITEM_NOT_FOUND, POSButton.GO_BACK)
    context.pos.wait_for_frame_open(POSFrame.MAIN)
    assert context.pos.get_current_transaction() is not None


@given('a loyalty discount {discount} with value of {value:f} is present in the transaction')
def step_impl(context: Context, discount: str, value: float):
    assert context.pos.wait_for_item_added(description=discount, price=-value, item_type=29)


@given('a loyalty discount {discount} with value of {value:f} is not present in the transaction')
def step_impl(context: Context, discount: str, value: float):
    assert not context.pos.wait_for_item_added(description=discount, price=-value, item_type=29)


@given('the transaction is totaled')
def step_impl(context: Context):
    context.execute_steps('''
        when the cashier presses the {tender_type} tender button
    '''.format(tender_type="cash"))
    context.pos.wait_for_frame_open(POSFrame.ASK_TENDER_AMOUNT_CASH)
    context.execute_steps('''
        when the cashier presses Go back button
    ''')
    context.pos.wait_for_frame_open(POSFrame.MAIN)


@given('the POS has rebooted')
def step_impl(context: Context):
    context.pos.restart()


@given('the cashier pressed Go back button')
def step_impl(context: Context):
    context.execute_steps("""
    when the cashier presses Go back button
    """)


@given('the cashier selected an item with barcode {barcode} on the main menu')
def step_impl(context: Context, barcode: str):
        context.execute_steps("""
            when the cashier selects item with barcode {barcode} on the main menu
        """.format(barcode=barcode))


@given('the POS displays barcode entry frame for pricecheck')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.PRICE_CHECK)
    context.pos.wait_for_frame_open(POSFrame.PRICE_CHECK_FRAME)
    context.pos.press_button_on_frame(POSFrame.PRICE_CHECK_FRAME, POSButton.MANUAL_ENTER)
    context.pos.wait_for_frame_open(POSFrame.ASK_BARCODE_ENTRY)


@given('the POS displays main menu frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MAIN)


@given('the tax amount from current transaction is {tax_amount:f}')
def step_impl(context: Context, tax_amount: float):
    assert math.isclose(context.pos.get_current_transaction().tax_amount, float(tax_amount), rel_tol=1e-5)


@given('the cashier manually entered the barcode {barcode} without confirming it')
def step_impl(context: Context, barcode: str):
    context.pos.press_button_on_frame(POSFrame.RECEIPT,POSButton.ENTER_PLU_UPC)
    context.pos.wait_for_frame_open(POSFrame.ASK_BARCODE_ENTRY)
    context.pos.press_digits(POSFrame.ASK_BARCODE_ENTRY, barcode)


@given('the cashier manually entered a barcode {barcode}')
def step_impl(context: Context, barcode: str):
    context.pos.wait_for_frame_open(POSFrame.ASK_BARCODE_ENTRY)
    context.pos.press_digits(POSFrame.ASK_BARCODE_ENTRY, barcode)
    context.pos.press_button_on_frame(POSFrame.ASK_BARCODE_ENTRY, POSButton.ENTER)


@given('the cashier pressed Enter PLU/UPC button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.RECEIPT,POSButton.ENTER_PLU_UPC)
    context.pos.wait_for_frame_open(POSFrame.ASK_BARCODE_ENTRY)
# endregion


# region When clauses
@when('the cashier presses Go back button')
def step_impl(context: Context):
    context.pos.press_goback_on_current_frame()


@when('the cashier presses Done button')
def step_impl(context: Context):
    context.pos.press_done_on_current_frame()


@when('the cashier selects item with barcode {barcode} on the main menu')
def step_impl(context: Context, barcode: str):
    context.pos.press_item_button(barcode)


@when('the cashier scans a barcode {barcode}')
def step_impl(context: Context, barcode: str):
    context.pos.scan_item_barcode(barcode=barcode)


@when('the cashier scans barcode {item_barcode} {item_count} times')
def step_impl(context: Context, item_barcode: str, item_count: int):
    count = int(item_count)
    while count > 0:
        context.pos.scan_item_barcode(barcode=item_barcode)
        count = count - 1


@when('the cashier stores the transaction')
def step_impl(context: Context):
    context.pos.store_transaction()


@when('the cashier recalls the last stored transaction')
def step_impl(context: Context):
    context.pos.recall_transaction(position=0)


@when('the cashier voids the transaction')
def step_impl(context: Context):
    context.pos.return_to_mainframe()
    context.pos.void_transaction()


@when('the manager voids the transaction with {manager_pin:d} pin and reason {reason}')
def step_impl(context: Context, manager_pin: int, reason: str):
    context.pos.void_transaction(manager_pin=manager_pin, reason=reason)


@when('the cashier selects {button_id} button')
def step_impl(context: Context, button_id: str):
    button_id = button_id.lower()
    current_frame = POSFrame(context.pos.control.get_menu_frame().use_description)
    if button_id == 'go back':
        context.pos.press_button_on_frame(frame=current_frame, button=POSButton.GO_BACK)
    elif button_id == 'no':
        context.pos.press_button_on_frame(frame=current_frame, button=POSButton.NO)
    elif button_id == 'yes':
        context.pos.press_button_on_frame(frame=current_frame, button=POSButton.YES)
    else:
        raise NotImplementedError(
            'STEP: When the cashier selects {button_id} button'.format(button_id=button_id))


@when('the cashier tenders the transaction with {amount:f} in {tender} with external id {external_id} and type id {type_id}')
def step_impl(context: Context, amount: float, tender: str, external_id: str, type_id: int):
    context.execute_steps('''
        when the cashier presses the {tender_type} tender button with external id {external_id} and type id {type_id}
    '''.format(tender_type=tender, external_id=external_id, type_id=type_id))
    frame = context.pos.control.get_menu_frame()
    context.pos.press_digits(frame.use_description, amount)
    context.pos.press_button_on_frame(frame.use_description, POSButton.ENTER)


@when('the cashier tenders the transaction with amount {amount:f} in {tender_type}')
def step_impl(context: Context, amount: float, tender_type: str):
    context.pos.wait_for_frame_open(POSFrame.MAIN)
    tender_type = tender_type.lower()
    context.pos.tender_transaction(tender_type=tender_type, amount=amount)


@when('the cashier enters {pin} pin')
def step_impl(context: Context, pin: str):
    context.pos.press_digits(POSFrame.ASK_OPERATOR_PIN, pin)
    context.pos.press_button_on_frame(POSFrame.ASK_OPERATOR_PIN, POSButton.SHIFT)


@when('the cashier presses Enter button')
def step_impl(context: Context):
    context.pos.press_enter_on_current_frame()


@when('the POS reboots')
def step_impl(context: Context):
    context.pos.restart()


@when('the cashier presses Exact dollar button')
def step_impl(context: Context):
    frame = context.pos.control.get_menu_frame()
    context.pos.control.press_button(frame.instance_id, POSButton.EXACT_DOLLAR.value)


@when('the cashier selects the first reason from the displayed list')
def step_impl(context: Context):
    context.pos.select_item_in_list(frame=POSFrame.ASK_FOR_A_REASON, item_position=0)


@when('the cashier manually entered a barcode {barcode}')
def step_impl(context: Context, barcode: str):
    context.pos.press_digits(POSFrame.ASK_BARCODE_ENTRY, barcode)
    context.pos.press_button_on_frame(POSFrame.ASK_BARCODE_ENTRY, POSButton.ENTER)


@when('the cashier presses Enter PLU/UPC button')
def step_impl(context: Context):
    context.execute_steps("""
    given the cashier pressed Enter PLU/UPC button
    """)
# endregion


# region Then clauses
@then('the POS displays main menu frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MAIN)


@then('the POS displays {tender_type} tender frame')
def step_impl(context: Context, tender_type: str):
    context.pos.wait_for_frame_open(POSFrame("ask-tender-amount-{}".format(tender_type.lower())))


@then('the POS displays Tender not allowed error frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_TENDER_NOT_ALLOWED)


@then('the cashier "{operator}" is signed in to the POS')
def step_impl(context: Context, operator: str):
    assert context.pos.is_signed_in(operator_name=operator)


@then('the POS displays No tran in progress error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_NO_TRAN_IN_PROGRESS)


@then('the POS displays Tender not allowed for non-fuel items error frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_TENDER_NOT_ALLOWED_FOR_NON_FUEL_ITEMS)


@then('the POS displays Store tran not allowed message')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(frame=POSFrame.MSG_STORE_TRAN_NOT_ALLOWED, timeout=2)


@then('the POS displays Ask tender amount cash frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_TENDER_AMOUNT_CASH)


@then('the POS displays Ask barcode entry frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_BARCODE_ENTRY)
# endregion


# region Then clauses (VR verification)
@then('an item {item_name} with price {price:f} is in the virtual receipt')
def step_impl(context: Context, item_name: str, price: float):
    assert context.pos.wait_for_item_added_to_VR(item_name, price)


@then('an item {item_name} with price {price:f} is not in the virtual receipt')
def step_impl(context: Context, item_name: str, price: float):
    assert not context.pos.wait_for_item_added_to_VR(item_name, price)


@then('an item {item_name} with price {price:f} and quantity {item_quantity:n} is in the virtual receipt')
def step_impl(context: Context, item_name: str, price: float, item_quantity: int):
    assert context.pos.wait_for_item_added_to_VR(item_name, price, item_quantity=item_quantity)


@then('an item {item_name} with price {price:f} and quantity {item_quantity:n} is in the consolidated virtual receipt')
def step_impl(context: Context, item_name: str, price: float, item_quantity: int):
    assert context.pos.wait_for_item_added_to_VR(item_name, price, item_quantity=item_quantity, consolidate=True)


@then('an item {refund_item} with refund value of {value:f} is in the virtual receipt')
def step_impl(context: Context, refund_item: str, value: float):
    assert context.pos.wait_for_item_added_to_VR(item_name=refund_item, item_price=-value)


@then('a tender {tender_description} with amount {tender_amount:f} is in the virtual receipt')
def step_impl(context: Context, tender_description: str, tender_amount: float):
    assert context.pos.wait_for_item_added_to_VR(tender_description, -tender_amount)


@then('a tender {tender_description} with amount {tender_amount:f} is not in the virtual receipt')
def step_impl(context: Context, tender_description: str, tender_amount: float):
    assert not context.pos.wait_for_item_added_to_VR(tender_description, -tender_amount)


@then('a tender {tender_description} is in the virtual receipt')
def step_impl(context: Context, tender_description: str):
    assert context.pos.wait_for_item_added_to_VR(tender_description)


@then('a tender {tender_description} is not in the virtual receipt')
def step_impl(context: Context, tender_description: str):
    assert not context.pos.wait_for_item_added_to_VR(tender_description)


@then('the autocombo {autocombo_description} with discount of {discount_value:f} is in the virtual receipt')
def step_impl(context: Context, autocombo_description: str, discount_value: float):
    assert context.pos.wait_for_item_added_to_VR(item_name=autocombo_description, item_price=-discount_value)


@then('the autocombo {autocombo_description} with discount of {discount_value:f} is not in the virtual receipt')
def step_impl(context: Context, autocombo_description: str, discount_value: float):
    assert not context.pos.wait_for_item_added_to_VR(item_name=autocombo_description, item_price=-discount_value)


@then('a loyalty discount {discount_description} with value of {discount_value:f} is in the virtual receipt')
def step_impl(context: Context, discount_description: str, discount_value: float):
    assert context.pos.wait_for_item_added_to_VR(item_name=discount_description, item_price=-discount_value)


@then('a loyalty discount {discount_description} with value of {discount_value:f} is not in the virtual receipt')
def step_impl(context: Context, discount_description: str, discount_value: float):
    assert not context.pos.wait_for_item_added_to_VR(item_name=discount_description, item_price=-discount_value)


@then('a loyalty discount {discount_description} with value of {discount_value:f} and quantity {item_quantity:n} is in the virtual receipt')
def step_impl(context: Context, discount_description: str, discount_value: float, item_quantity: int):
    assert context.pos.wait_for_item_added_to_VR(item_name=discount_description, item_price=-discount_value, item_quantity=item_quantity)


@then('a card {card_name} with value of {card_value:f} is in the virtual receipt')
def step_impl(context: Context, card_name: str, card_value: float):
    assert context.pos.wait_for_item_added_to_VR(card_name, card_value)


@then('a card {card_name} with value of {card_value:f} is not in the virtual receipt')
def step_impl(context: Context, card_name: str, card_value: float):
    assert not context.pos.wait_for_item_added_to_VR(card_name, card_value)


@then('a fuel item {item_name} with price {price:f} and prefix {prefix} is in the virtual receipt')
def step_impl(context: Context, item_name: str, price: float, prefix: str):
    assert context.pos.verify_virtual_receipt_contains_fuel_item(item_name, price, pump_prefix=prefix)


@then('a deposit {deposit_item} with price {deposit_price:f} is in the virtual receipt')
def step_impl(context: Context, deposit_item: str, deposit_price: float):
    assert context.pos.wait_for_item_added_to_VR(item_name=deposit_item, item_price=deposit_price)


@then('an Alternate ID is in the virtual receipt')
def step_impl(context: Context):
    assert context.pos.wait_for_item_added_to_VR(item_name="Alternate ID", item_price="0.00")
#endregion


# region Then clauses (Transaction verification)
@then('no transaction is in progress')
def step_impl(context: Context):
    assert context.pos.get_current_transaction() == None


@then('the transaction is finalized')
def step_impl(context: Context):
    assert context.pos.control.wait_for_transaction_end() is not None


@then('a new transaction is started')
def step_impl(context: Context):
    assert context.pos.get_current_transaction() is not None


@then('a transaction is in progress')
def step_impl(context: Context):
    assert context.pos.get_current_transaction() is not None


@then('the tax amount from {tran} transaction is {tax_amount}')
def step_impl(context: Context, tran: str, tax_amount: float):
    assert math.isclose(context.pos.get_transaction(tran).tax_amount, float(tax_amount), rel_tol=1e-5)


@then('the total tax {tax_amount} is not changed in current transaction')
def step_impl(context: Context, tax_amount: str):
    assert math.isclose(context.pos.get_current_transaction().tax_amount, float(tax_amount), rel_tol=1e-5)


@then('the total tax is changed in current transaction to {tax_amount}')
def step_impl(context: Context, tax_amount: str):
    assert math.isclose(context.pos.get_current_transaction().tax_amount, float(tax_amount), rel_tol=1e-5)


@then('the transaction\'s balance is {balance:f}')
def step_impl(context: Context, balance: float):
    assert math.isclose(context.pos.get_current_transaction().balance, balance, rel_tol=1e-5)


@then('the transaction\'s subtotal is {subtotal:f}')
def step_impl(context: Context, subtotal: float):
    assert math.isclose(context.pos.get_current_transaction().subtotal, subtotal, rel_tol=1e-5)


@then('an item {description} with price {price:f} is in the current transaction')
def step_impl(context: Context, description: str, price: float):
    assert context.pos.wait_for_item_added(description=description, price=price, item_type=1)


@then('an item {description} with price {price:f} and type {item_type:n} is in the {transaction} transaction')
def step_impl(context: Context, description: str, price: float, item_type: int, transaction: str):
    assert context.pos.wait_for_item_added(description=description, price=price, item_type=item_type, transaction=transaction)


@then('an item {description} with price {price:f} is in the current transaction with status {status}')
def step_impl(context: Context, description: str, price: float, status: str):
    assert context.pos.wait_for_item_added(description=description, price=price, item_type=1, has_status=status)


@then('an item {description} with price {price:f} and quantity {item_quantity:n} is in the current transaction')
def step_impl(context: Context, description: str, price: float, item_quantity: int):
    assert context.pos.wait_for_item_added(description=description, price=price, item_type=1, quantity=item_quantity)


@then('an item {description} with price {price:f}, quantity {item_quantity:n} and type {item_type:n} is in the {transaction} transaction')
def step_impl(context: Context, description: str, price: float, item_quantity: int, item_type: int, transaction: str):
    assert context.pos.wait_for_item_added(description=description, price=price, quantity=item_quantity, item_type=item_type, transaction=transaction)


@then('an item {description} with price {price:f} and quantity {item_quantity:n} is in the consolidated current transaction')
def step_impl(context: Context, description: str, price: float, item_quantity: int):
    assert context.pos.wait_for_item_added(description=description, price=price, quantity=item_quantity, consolidate=True)


@then('an item {description} with price {price:f} is not in the current transaction')
def step_impl(context: Context, description: str, price: float):
    assert not context.pos.is_item_in_transaction(description=description, price=price, item_type=1)


@then('an item {description} with price {price:f} and type {item_type:d} is not in the current transaction')
def step_impl(context: Context, description: str, price: float, item_type: int):
    assert not context.pos.is_item_in_transaction(description=description, price=price, item_type=item_type)


@then('an item {refund_item} with refund value of {value:f} is in the {transaction} transaction')
def step_impl(context: Context, refund_item: str, value: float, transaction: str):
    assert context.pos.wait_for_item_added(description=refund_item, price=-value, item_type=15, transaction=transaction)


@then('a tender {tender_description} with amount {tender_amount:f} is in the {transaction} transaction')
def step_impl(context: Context, tender_description: str, tender_amount: float, transaction: str):
    assert context.pos.wait_for_item_added(description=tender_description, price=-tender_amount, item_type=6, transaction=transaction)


@then('a tender {tender_description} with amount {tender_amount:f} is not in the {transaction} transaction')
def step_impl(context: Context, tender_description: str, tender_amount: float, transaction: str):
    assert not context.pos.wait_for_item_added(description=tender_description, price=-tender_amount, item_type=6, transaction=transaction)


@then('a tender {tender_description} with change amount {tender_amount:f} is in the {transaction} transaction')
def step_impl(context: Context, tender_description: str, tender_amount: float, transaction: str):
    assert context.pos.wait_for_item_added(description=tender_description, price=tender_amount, item_type=6, transaction=transaction)


@then('a tender {tender_description} is in the {transaction} transaction')
def step_impl(context: Context, tender_description: str, transaction: str):
    assert context.pos.wait_for_item_added(description=tender_description, item_type=6, transaction=transaction)


@then('a tender {tender_description} is not in the {transaction} transaction')
def step_impl(context: Context, tender_description: str, transaction: str):
    assert not context.pos.wait_for_item_added(description=tender_description, transaction=transaction)


@then('a loyalty discount {discount_description} with value of {discount_value:f} is in the {transaction} transaction')
def step_impl(context: Context, discount_description: str, discount_value: float, transaction: str):
    assert context.pos.wait_for_item_added(description=discount_description, price=-discount_value, item_type=29, transaction=transaction)


@then('a loyalty discount {discount_description} with value of {discount_value:f} is not in the {transaction} transaction')
def step_impl(context: Context, discount_description: str, discount_value: float, transaction: str):
    assert not context.pos.wait_for_item_added(description=discount_description, price=-discount_value, item_type=29, transaction=transaction)


@then('no loyalty discount {discount_description} is in the {transaction} transaction')
def step_impl(context: Context, discount_description: str, transaction: str):
    assert not context.pos.wait_for_item_added(description=discount_description, item_type=29, transaction=transaction)


@then('a loyalty discount {discount_description} with value of {discount_value:f} and quantity {item_quantity:n} is in the {transaction} transaction')
def step_impl(context: Context, discount_description: str, discount_value: float, item_quantity: int, transaction: str):
    assert context.pos.wait_for_item_added(description=discount_description, price=-discount_value, item_type=29, transaction=transaction, quantity=item_quantity)


@then('a discount trigger {trigger_name} is in the {transaction} transaction')
def step_impl(context: Context, trigger_name: str, transaction: str):
    assert context.pos.wait_for_item_added(description=trigger_name, transaction=transaction)


@then('a {discount_name} discount triggered by the card barcode number {barcode} is in the {transaction} transaction')
def step_impl(context: Context, discount_name: str, barcode: str, transaction: str):
    assert context.pos.wait_for_item_added(description=discount_name, barcode=barcode, transaction=transaction)


@then('a card {card_name} with value of {card_value:f} is in the {transaction} transaction')
def step_impl(context: Context, card_name: str, card_value: float, transaction: str):
    assert context.pos.wait_for_item_added(description=card_name, price=card_value, item_type=26, transaction=transaction)


@then('a card {card_name} with value of {card_value:f} and type {item_type:d} is in the {transaction} transaction')
def step_impl(context: Context, card_name: str, card_value: float, item_type: int, transaction: str):
    assert context.pos.wait_for_item_added(description=card_name, price=card_value, item_type=item_type, transaction=transaction)


@then('a card {card_name} with value of {card_value:f} is not in the {transaction} transaction')
def step_impl(context: Context, card_name: str, card_value: float, transaction: str):
    assert not context.pos.is_item_in_transaction(description=card_name, price=card_value, item_type=26, transaction=transaction)


@then(u'a loyalty card {card_description} is added to the transaction')
def step_impl(context, card_description: str):
    assert context.pos.wait_for_item_added(description=card_description, item_type=26), 'Loyalty card [{}] not found.'.format(card_description)


@then('a condiment {description} with price {price:f} is in the current transaction')
def step_impl(context: Context, description: str, price: float):
    assert context.pos.wait_for_item_added(description=description, price=price, item_type=2)


@then('the autocombo {autocombo_description} with discount of {discount_value:f} is in the current transaction')
def step_impl(context: Context, autocombo_description: str, discount_value: float):
    assert context.pos.wait_for_item_added(description=autocombo_description, price=-discount_value, item_type=0)

@then('the autocombo {autocombo_description} with discount of {discount_value:f} is not in the current transaction')
def step_impl(context: Context, autocombo_description: str, discount_value: float):
    assert not context.pos.wait_for_item_added(description=autocombo_description, price=-discount_value, item_type=0)


@then('a deposit {deposit_item} with price {deposit_price:f} is in the current transaction')
def step_impl(context: Context, deposit_item: str, deposit_price: float):
    assert context.pos.wait_for_item_added(description=deposit_item, price=deposit_price, item_type=15)


@then('a lottery item {item_name} with price {price:f} is in the {transaction} transaction')
def step_impl(context: Context, item_name: str, price: float, transaction: str):
    assert context.pos.wait_for_item_added(description=item_name, price=price, item_type=12, transaction=transaction)


@then('an Alternate ID is in the current transaction')
def step_impl(context: Context):
    assert context.pos.wait_for_item_added(description="Alternate ID", price="0.00", item_type=26)


@then('a {section} section from the previous transaction contains NVP {nvp}')
def step_impl(context: Context, section: str, nvp: dict):
    tran_detail = context.pos.control.wait_for_transaction_end()
    assert tran_detail.has_tran_nvp(section=section, nvp=nvp)


@then('a {section} section from the current transaction contains NVP {nvp}')
def step_impl(context: Context, section: str, nvp: dict):
    tran_detail = context.pos.get_current_transaction()
    assert tran_detail.has_tran_nvp(section=section, nvp=nvp)


@then('{item_name} item detail from the previous transaction contains NVP {nvp}')
def step_impl(context: Context, item_name: str, nvp: dict):
    tran_detail = context.pos.control.wait_for_transaction_end()
    assert tran_detail.has_item_nvp(item_name=item_name, nvp=nvp)


@then('a {section} section from a {transaction} transaction contains NVP {nvp}')
def step_impl(context: Context, section: str, transaction: str, nvp: dict):
    tran_detail = context.pos.get_transaction(transaction)
    assert tran_detail.has_tran_nvp(nvp)


@then('a {section} section from the {transaction} transaction does not contain NVP with {nvp_element} {nvp_value}')
def step_impl(context: Context, section: str, transaction: str, nvp_element: str, nvp_value: str):
    tran_detail = context.pos.get_transaction(transaction)
    assert not tran_detail.has_tran_nvp_with_element(nvp_element, nvp_value, section)
#endregion
