from behave import *
from behave.runner import Context

from cfrpos.core.bdd_utils.errors import ProductError
from cfrpos.core.pos.ui_metadata import POSButton, POSFrame
from cfrpos.core.pos.pos_product import BarcodeInputMethod


# region Given clauses
@given('the cashier scanned coupon {mfc_barcode} of type {barcode_type}')
def step_impl(context: Context, mfc_barcode: str, barcode_type: str):
    context.pos.add_manufacturer_coupon(mfc_barcode, barcode_type, input_method=BarcodeInputMethod.SCAN)


@given('the cashier applied coupon {mfc_barcode} of type {mfc_type} to {item_count} item/s with barcode {item_barcode}')
def step_impl(context: Context, mfc_barcode: str, mfc_type: str, item_count: int, item_barcode: str):
    count = int(item_count)
    while count > 0:
        context.pos.scan_item_barcode(barcode=item_barcode)
        count = count - 1
    context.pos.add_manufacturer_coupon(barcode=mfc_barcode, barcode_type=mfc_type, input_method=BarcodeInputMethod.SCAN)


@given('the cashier voided Coupon with price {mfc_price:f}')
def step_impl(context: Context, mfc_price: float):
    context.pos.void_item(item_name='Coupon', item_price=-mfc_price)


@given('POS displayed Amount will be restricted to amount frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.TENDER_NOT_ALLOWED_FOR_ALL_ITEMS_ASK_ACCEPT_AMOUNT_WILL_BE_RESTRICTED)


@given('the POS displays Enter amount frame')
def step_impl(context: Context):
   context.execute_steps('''
    then the POS displays Enter amount frame
    ''')


# endregion


# region When clauses
@when('the cashier scans coupon {mfc_barcode} of type {barcode_type}')
def step_impl(context: Context, mfc_barcode: str, barcode_type: str):
    context.pos.add_manufacturer_coupon(mfc_barcode, barcode_type, input_method=BarcodeInputMethod.SCAN)


@when('the cashier scans expired coupon {mfc_barcode} of type {barcode_type}')
def step_impl(context: Context, mfc_barcode: str, barcode_type: str):
    context.pos.add_manufacturer_coupon(mfc_barcode, barcode_type, input_method=BarcodeInputMethod.SCAN)


@when('the cashier manually enters coupon {mfc_barcode} of type {barcode_type}')
def step_impl(context: Context, mfc_barcode: str, barcode_type: str):
    context.pos.add_manufacturer_coupon(mfc_barcode, barcode_type, input_method=BarcodeInputMethod.MANUAL)


@when('the cashier enters a {mfc_price:f} value to the prompted coupon')
def step_impl(context: Context, mfc_price: float):
    context.pos.press_digits(POSFrame.ASK_ENTER_DOLLAR_AMOUNT, mfc_price)
    context.pos.press_button_on_frame(POSFrame.ASK_ENTER_DOLLAR_AMOUNT, POSButton.ENTER)
    if mfc_price > 0:
        context.pos.wait_for_tender_added(tender_type='mfc')

@when('the cashier voids Coupon with price {mfc_price:f}')
def step_impl(context: Context, mfc_price: float):
    context.pos.void_item(item_name='Coupon', item_price=-mfc_price)
# endregion


# region Then clauses
@then('the transaction contains a manufacturer coupon with a discount value of {mfc_price:f}')
def step_impl(context: Context, mfc_price: float):
    assert context.pos.wait_for_item_added(description="Coupon", price=-mfc_price)


@then('the transaction does not contain a manufacturer coupon with a discount value of {mfc_price:f}')
def step_impl(context: Context, mfc_price: float):
    if context.pos.is_item_in_transaction(description="Coupon", price=-mfc_price):
        raise ProductError("The coupon is in the transaction")


@then('the POS displays Coupon amount too large error frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_COUPON_AMOUNT_TOO_LARGE)


@then('the coupon with price {mfc_price:f} is not in the virtual receipt')
def step_impl(context: Context, mfc_price: float, item_name: str ='Coupon'):
    assert not context.pos.wait_for_item_added_to_VR(item_name=item_name, item_price=-mfc_price)


@then('the coupon with price {mfc_price:f} is in the virtual receipt')
def step_impl(context: Context, mfc_price: float, item_name: str ='Coupon'):
    assert context.pos.wait_for_item_added_to_VR(item_name=item_name, item_price=-mfc_price)


@then('the POS displays Coupon Expired error frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_COUPON_EXPIRED)


@then('the POS displays Manufacturer Coupons Not Allowed error frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_COUPONS_NOT_ALLOWED)


@then('the POS displays Manufacturer Coupon requirements not met error frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_COUPON_REQUIREMENTS_NOT_MET)


@then('the POS displays Enter amount frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_ENTER_DOLLAR_AMOUNT)


@then('POS displays Amount will be restricted to amount frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.TENDER_NOT_ALLOWED_FOR_ALL_ITEMS_ASK_ACCEPT_AMOUNT_WILL_BE_RESTRICTED)
# endregion