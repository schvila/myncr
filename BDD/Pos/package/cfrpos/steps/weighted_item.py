from behave import *
from behave.runner import Context

from cfrpos.core.pos.ui_metadata import POSFrame, POSButton


# region Given clauses
@given('the POS displays Enter weight frame after item with barcode {barcode} was added to transaction')
def step_impl(context: Context, barcode: str):
    context.pos.scan_item_barcode(barcode=barcode)
    context.pos.wait_for_frame_open(POSFrame.ASK_ITEM_WEIGHT)


@given('a weighted item with barcode {barcode} is present in the transaction with weight {weight}')
def step_impl(context: Context, barcode: str, weight: str):
    context.pos.scan_item_barcode(barcode=barcode)
    context.pos.wait_for_frame_open(POSFrame.ASK_ITEM_WEIGHT)
    context.pos.press_digits(POSFrame.ASK_ITEM_WEIGHT, weight)
    context.pos.press_button_on_frame(POSFrame.ASK_ITEM_WEIGHT, POSButton.ENTER)
# endregion


# region When clauses
@when('the cashier enters {weight} weight')
def step_impl(context: Context, weight: str):
    context.pos.press_digits(POSFrame.ASK_ITEM_WEIGHT, weight)
    context.pos.press_button_on_frame(POSFrame.ASK_ITEM_WEIGHT, POSButton.ENTER)
# endregion


# region Then clauses
@then('the POS displays the enter weight frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_ITEM_WEIGHT)


@then('an item {item_name} with uom {uom} and price {price:f} is in the virtual receipt')
def step_impl(context: Context, item_name: str, uom: str, price: float):
    assert context.pos.verify_virtual_receipt_contains_item(item_name=item_name, unit_of_measure=uom, item_price=price)


@then('an item {item_name} with NVPs {nvp} is in the {transaction} transaction')
def step_impl(context: Context, item_name: str, nvp: dict, transaction: str):
    tran_detail = context.pos.get_transaction(transaction)
    assert tran_detail.has_item_nvp(item_name=item_name, nvp=nvp)
# endregion