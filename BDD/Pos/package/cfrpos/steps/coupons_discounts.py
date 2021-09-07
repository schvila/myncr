from behave import *
from behave.runner import Context

from cfrpos.core.pos.ui_metadata import POSFrame, POSButton


# region Given clauses (configuration)
@given('the pricebook contains coupons')
def step_impl(context: Context):
    for row in context.table:
        start_date = row["start_date"] if "start_date" in row.headings else '2012-06-25T00:00:00'
        end_date = row["end_date"] if "end_date" in row.headings else '1899-01-01T00:00:00'
        max_amount = int(row["max_amount"]) if "max_amount" in row.headings else 0
        max_quantity = int(row["max_quantity"]) if "max_quantity" in row.headings else 1
        card_definition_group_id = int(row["card_definition_group_id"]) if "card_definition_group_id" in row.headings else 0
        external_id = row["external_id"] if "external_id" in row.headings else ''
        reduction_id = int(row["reduction_id"]) if "reduction_id" in row.headings else None
        required_security = row["required_security"] if "required_security" in row.headings else ''
        is_discount = False
        show_manual_lookup = True
        if "show_manual_lookup" in row.headings:
            if str(row["show_manual_lookup"]).lower() in ['false', '0', 'no']:
                show_manual_lookup = False
        best_deal = False
        if "best_deal" in row.headings:
            if str(row["best_deal"]).lower() in ['true', '1', 'yes']:
                best_deal = True
        reduces_tax = False
        if "reduces_tax" in row.headings:
            if str(row["reduces_tax"]).lower() in ['true', '1', 'yes']:
                reduces_tax = True
        free_item_flag = False
        if "free_item_flag" in row.headings:
            if str(row["free_item_flag"]).lower() in ['true', '1', 'yes']:
                free_item_flag = True
        retail_item_group_id = 0
        if "retail_item_group_id" in row.headings:
            if str(row["retail_item_group_id"]).isnumeric():
                retail_item_group_id = row["retail_item_group_id"]
        context.pos.relay_catalog.create_reduction(row["description"], row["reduction_value"], row["disc_type"], row["disc_mode"], row["disc_quantity"],
                                                  is_discount, show_manual_lookup, best_deal, reduction_id, reduces_tax,
                                                  start_date, end_date, max_amount, max_quantity, card_definition_group_id,
                                                  external_id, required_security, retail_item_group_id, free_item_flag)


@given('the pricebook contains discounts')
def step_impl(context: Context):
    for row in context.table:
        start_date = row["start_date"] if "start_date" in row.headings else '2012-06-25T00:00:00'
        end_date = row["end_date"] if "end_date" in row.headings else '1899-01-01T00:00:00'
        max_amount = int(row["max_amount"]) if "max_amount" in row.headings else 0
        max_quantity = int(row["max_quantity"]) if "max_quantity" in row.headings else 1
        card_definition_group_id = int(row["card_definition_group_id"]) if "card_definition_group_id" in row.headings else 0
        external_id = row["external_id"] if "external_id" in row.headings else ''
        reduction_id = int(row["reduction_id"]) if "reduction_id" in row.headings else None
        required_security = row["required_security"] if "required_security" in row.headings else ''
        is_discount = True
        show_manual_lookup = True
        if "show_manual_lookup" in row.headings:
            if str(row["show_manual_lookup"]).lower() in ['false', '0', 'no']:
                show_manual_lookup = False
        best_deal = False
        if "best_deal" in row.headings:
            if str(row["best_deal"]).lower() in ['true', '1', 'yes']:
                best_deal = True
        reduces_tax = False
        if "reduces_tax" in row.headings:
            if str(row["reduces_tax"]).lower() in ['true', '1', 'yes']:
                reduces_tax = True
        context.pos.relay_catalog.create_reduction(row["description"], row["reduction_value"], row["disc_type"], row["disc_mode"], row["disc_quantity"],
                                                  is_discount, show_manual_lookup, best_deal, reduction_id, reduces_tax,
                                                  start_date, end_date, max_amount, max_quantity, card_definition_group_id,
                                                  external_id, required_security)


@given('the pricebook contains autocombos')
def step_impl(context: Context):
    for row in context.table:
        is_discount = True
        max_quantity = int(row["max_quantity"]) if "max_quantity" in row.headings else 0
        combo_group_id = context.pos.relay_catalog.item_image_relay.find_group_id(row["item_name"])
        combo_id = context.pos.relay_catalog.autocombo_relay.create_new_autocombo_id()
        if "external_id" in row.headings:
            external_id = row["external_id"]
        else:
            external_id = ""
        context.pos.relay_catalog.create_reduction(row["description"], row["reduction_value"], row["disc_type"], row["disc_mode"], row["disc_quantity"],
             reduction_id=combo_id, external_id=external_id, is_discount=is_discount, reduces_tax=True, max_quantity=max_quantity)
        context.pos.relay_catalog.create_autocombo(description=row["description"], quantity=row["quantity"], external_id=external_id, combo_id=combo_id, group_id=combo_group_id)


@given('the pricebook contains promotions')
def step_impl(context: Context):
    for row in context.table:
        item_id = context.pos.relay_catalog.item_image_relay.find_item_id(row["item_name"])
        modifier1_id = context.pos.relay_catalog.item_image_relay.find_modifier_id(row["item_name"])
        promotion_id = context.pos.relay_catalog.promotions_relay.get_new_promotion_id()
        context.pos.relay_catalog.promotions_relay.create_promotion(item_id, modifier1_id , row["promotion_price"], promotion_id)


@given('the cashier added a coupon {coupon}')
def step_impl(context: Context, coupon: str):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.COUPON_LOOKUP)
    context.pos.select_item_in_list(POSFrame.SELECT_COUPON, coupon, only_highlighted=True)
    context.pos.press_button_on_frame(POSFrame.SELECT_COUPON, POSButton.ENTER)


@given('the cashier entered value {amount} on {prompted_coupon} without confirming it')
def step_impl(context: Context, amount: int, prompted_coupon: str):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.COUPON_LOOKUP)
    context.pos.select_item_in_list(POSFrame.SELECT_COUPON, prompted_coupon)
    context.pos.press_button_on_frame(POSFrame.SELECT_COUPON, POSButton.ENTER)
    context.pos.wait_for_frame_open(POSFrame.ASK_COUPON_PERCENT)
    context.pos.press_digits(POSFrame.ASK_COUPON_PERCENT, amount)


@given('the cashier added a discount {discount}')
def step_impl(context: Context, discount: str):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.DISCOUNT_LOOKUP)
    context.pos.select_item_in_list(POSFrame.SELECT_DISCOUNT, item_name=discount, only_highlighted=True)
    context.pos.press_button_on_frame(POSFrame.SELECT_DISCOUNT, POSButton.ENTER)
# endregion


# region When clauses
@when('the cashier presses Coupon Lookup button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.COUPON_LOOKUP)


@when('the {user} adds a coupon {coupon}')
def step_impl(context: Context, user: str, coupon: str):
    context.execute_steps('''
    given the cashier added a coupon {coupon}
    '''.format(coupon=coupon))


@when('the cashier adds a {preset_coupon} {amount:d} times')
def step_impl(context: Context, preset_coupon: str, amount: int):
    count = amount
    while count > 0:
        context.execute_steps('''
        given the cashier added a coupon {coupon}
        '''.format(coupon=preset_coupon))
        count = count - 1


@when('the cashier adds {prompted_coupon} with {amount} value')
def step_impl(context: Context, prompted_coupon: str, amount: int):
    context.execute_steps('''
        given the cashier entered value {amount} on {prompted_coupon} without confirming it
    '''.format(amount=amount, prompted_coupon=prompted_coupon))
    context.pos.press_button_on_frame(POSFrame.ASK_COUPON_PERCENT, POSButton.ENTER)


@when('the cashier updates quantity of the coupon {preset_coupon} to {quantity}')
def step_impl(context: Context, preset_coupon: str, quantity: int):
    context.pos.change_quantity(item_name=preset_coupon, quantity=quantity)


@when('the {user} adds a discount {discount}')
def step_impl(context: Context, user: str, discount: str):
        context.execute_steps('''
        given the cashier added a discount {discount}
        '''.format(discount=discount))


@when('the cashier enters {amount:f} coupon amount in Ask coupon amount frame')
def step_impl(context: Context, amount: float):
    context.pos.wait_for_frame_open(POSFrame.ASK_COUPON_AMOUNT)
    context.pos.press_digits(POSFrame.ASK_COUPON_AMOUNT, amount)
    context.pos.press_button_on_frame(POSFrame.ASK_COUPON_AMOUNT, POSButton.ENTER)
# endregion


# region Then clauses
@then('a coupon {coupon} is in the {transaction} transaction')
def step_impl(context: Context, coupon: str, transaction: str):
    assert context.pos.wait_for_item_added(description=coupon, transaction=transaction)


@then('a coupon {coupon} with value of {value:f} is in the virtual receipt')
def step_impl(context: Context, coupon: str, value: float):
    assert context.pos.wait_for_item_added_to_VR(item_name=coupon, item_price=-value)


@then('the coupon {coupon} with value of {value:f} is in the {transaction} transaction')
def step_impl(context: Context, coupon: str, value: float, transaction: str):
    assert context.pos.wait_for_item_added(description=coupon, price=-value, transaction=transaction)


@then('a discount {discount} is in the {transaction} transaction')
def step_impl(context: Context, discount: str, transaction: str):
    assert context.pos.wait_for_item_added(description=discount, transaction=transaction)


@then('a discount {discount} with value of {value:f} is in the virtual receipt')
def step_impl(context: Context, discount: str, value: float):
    assert context.pos.wait_for_item_added_to_VR(item_name=discount, item_price=-value)


@then('the POS displays Select coupon frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.SELECT_COUPON)


@then('the POS displays Enter percent frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_COUPON_PERCENT)


@then('the POS displays Coupon amount too large error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_COUPON_AMOUNT_TOO_LARGE)


@then('the POS displays Coupon already added frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.COUPON_ALREADY_ADDED)


@then('the POS displays Select discount frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.SELECT_DISCOUNT)


@then('the POS displays Ask coupon amount frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_COUPON_AMOUNT)
# endregion
