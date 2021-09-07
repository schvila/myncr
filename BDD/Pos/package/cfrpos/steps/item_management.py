from behave import *
from behave.runner import Context

from cfrpos.core.bdd_utils.errors import ProductError
from cfrpos.core.pos.ui_metadata import POSFrame, POSButton


# region Given clauses
@given('the cashier performed price check of item with barcode {barcode}')
def step_impl(context: Context, barcode: str):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.PRICE_CHECK)
    context.pos.press_button_on_frame(POSFrame.PRICE_CHECK_FRAME, POSButton.MANUAL_ENTER)
    context.pos.press_digits(POSFrame.ASK_BARCODE_ENTRY, barcode)
    context.pos.press_button_on_frame(POSFrame.ASK_BARCODE_ENTRY, POSButton.ENTER)
    context.pos.wait_for_frame_open(POSFrame.PRICE_CHECK_FRAME)


@given('the POS displays Enter quantity amount frame')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.CHANGE_QUANTITY)
    context.pos.wait_for_frame_open(POSFrame.ENTER_QUANTITY_AMOUNT)


@given('the POS displays Price check frame')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.PRICE_CHECK)
    context.pos.wait_for_frame_open(POSFrame.PRICE_CHECK_FRAME)


@given('the POS displays Enter new price frame')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.PRICE_OVERRIDE)
    context.pos.wait_for_frame_open(POSFrame.PRICE_OVERRIDE_FRAME)


@given('the POS displays Select a reason after overriding price with {new_price:f}')
def step_impl(context: Context, new_price: float):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.PRICE_OVERRIDE)
    context.pos.press_digits(POSFrame.PRICE_OVERRIDE_FRAME, new_price)
    context.pos.press_button_on_frame(POSFrame.PRICE_OVERRIDE_FRAME, POSButton.ENTER)
    context.pos.wait_for_frame_open(POSFrame.ASK_FOR_A_REASON)


@given('the POS displays Please select a reason frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_FOR_A_REASON)


@given('the cashier pressed the Void button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.VOID_ITEM)


@given('no transaction is in progress')
def step_impl(context: Context):
    assert context.pos.get_current_transaction() == None


@given('the cashier entered {amount:f} dollar amount in Ask enter dollar amount frame without confirming it')
def step_impl(context: Context, amount: float):
    context.pos.press_digits(POSFrame.ASK_ENTER_DOLLAR_AMOUNT, amount)


@given('the cashier entered {amount:f} dollar amount in Ask enter dollar amount frame')
def step_impl(context: Context, amount: float):
    context.pos.press_digits(POSFrame.ASK_ENTER_DOLLAR_AMOUNT, amount)
    context.pos.press_button_on_frame(POSFrame.ASK_ENTER_DOLLAR_AMOUNT, POSButton.ENTER)


@given('a finalized transaction is present')
def step_impl(context: Context):
    context.pos.scan_item_barcode(barcode='099999999990')
    context.pos.tender_transaction(tender_type="cash", amount="exact_dollar")


@given('a stored transaction is present')
def step_impl(context: Context):
    context.pos.scan_item_barcode(barcode='099999999990')
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.STORE_TRANSACTION)


@given('the cashier voided the {item_name} with price {item_price:f}')
def step_impl(context: Context, item_name: str, item_price: float):
    context.pos.void_item(item_name=item_name, item_price=item_price)


@given('the cashier voided the {item_name}')
def step_impl(context: Context, item_name: str):
    context.pos.void_item(item_name=item_name)


@given('an item {item_name} with price {item_price:f} has changed quantity to {quantity:n}')
def step_impl(context: Context, item_name: str, item_price: float, quantity: int):
    context.pos.change_quantity(item_name=item_name, item_price=item_price, quantity=quantity)
# endregion


# region When clauses
@when('the cashier presses Change quantity button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.CHANGE_QUANTITY)


@when('the cashier presses Add to order button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.PRICE_CHECK_FRAME, POSButton.ADD_TO_ORDER)


@when('the cashier selects the {reason} reason code')
def step_impl(context: Context, reason: str):
    context.pos.select_item_in_list(POSFrame.ASK_FOR_A_REASON, item_name=reason)


@when('the cashier enters {quantity:d} quantity')
def step_impl(context: Context, quantity: int):
    context.pos.press_digits(POSFrame.ENTER_QUANTITY_AMOUNT, quantity)
    context.pos.press_button_on_frame(POSFrame.ENTER_QUANTITY_AMOUNT, POSButton.ENTER)


@when('the cashier presses the quick button of quantity {quantity:n}')
def step_impl(context: Context, quantity: int):
    button = POSButton("qnt-0" + str(quantity))
    context.pos.press_button_on_frame(POSFrame.ENTER_QUANTITY_AMOUNT, button)


@when('the cashier presses Price check button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.PRICE_CHECK)


@when('the cashier presses Manual enter button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.PRICE_CHECK_FRAME, POSButton.MANUAL_ENTER)


@when('the cashier presses Price override button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.PRICE_OVERRIDE)


@when('the cashier enters new price {price:f}')
def step_impl(context: Context, price: float):
    context.pos.press_digits(POSFrame.PRICE_OVERRIDE_FRAME, price)
    context.pos.press_button_on_frame(POSFrame.PRICE_OVERRIDE_FRAME, POSButton.ENTER)


@when('the cashier presses the Void button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.VOID_ITEM)


@when('the cashier manually adds an item with barcode {barcode} on the POS')
def step_impl(context: Context, barcode: str):
    context.pos.enter_barcode_manually(barcode)


@when('the cashier voids the {item_name} with price {item_price:f}')
def step_impl(context: Context, item_name: str, item_price: float):
    context.pos.void_item(item_name=item_name, item_price=item_price)


@when('the cashier updates quantity of the item {item_name} to {quantity}')
def step_impl(context: Context, item_name: str, quantity: int):
    context.pos.change_quantity(item_name=item_name, quantity=quantity)


@when('the cashier overrides price of the item {item_name} to price {item_price:f}')
def step_impl(context: Context, item_name: str, item_price: float):
    context.pos.price_override(item_name=item_name, updated_item_price=item_price)
# endregion


# region Then clauses
@then('the POS displays Enter quantity amount frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ENTER_QUANTITY_AMOUNT)


@then('the POS displays Zero quantity not allowed error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_ZERO_QUANTITY_NOT_ALLOWED)


@then('the POS displays Price check frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.PRICE_CHECK_FRAME)


@then('the POS displays Barcode entry frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_BARCODE_ENTRY)


@then('the POS displays No item to add error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_NO_ITEM_TO_ADD)


@then('the POS displays Enter new price frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.PRICE_OVERRIDE_FRAME)


@then('the POS displays Please select a reason frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_FOR_A_REASON)


@then('the POS displays Quantity too large error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_QUANTITY_TOO_LARGE)


@then('the POS displays No item to void error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_NO_ITEM_TO_VOID)


@then('the POS displays Cancel not allowed for item error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_CANCEL_NOT_ALLOWED)


@then('the POS displays Not allowed after total error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_NOT_ALLOWED_AFTER_TOTAL)


@then('the POS displays Ask enter dollar amount frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_ENTER_DOLLAR_AMOUNT)


@then('the POS displays Quantity not allowed error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_QUANTITY_NOT_ALLOWED)


@then('the POS displays Price override not allowed error frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_PRICE_OVERRIDE_NOT_ALLOWED)
# endregion
