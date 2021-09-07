from behave import *
from behave.runner import Context


# region Given clauses
@given('the POS recognizes MRD card role')
def step_impl(context: Context):
    context.pos.create_radgcm_reg_entry_for_mrd()


@given('the cashier scanned a MRD card with barcode {barcode}')
def step_impl(context: Context, barcode: str):
    context.execute_steps('''
        when the cashier scans a MRD card with barcode {barcode}
    '''.format(barcode=barcode))
# endregion


# region When clauses
@when('the cashier scans a MRD card with barcode {barcode}')
def step_impl(context: Context, barcode: str):
    context.item_count = context.pos.get_transaction_item_count()
    context.pos.scan_item_barcode(barcode)
    context.pos.wait_for_transaction_item_count_increase(context.item_count)
# endregion


# region Then clauses
@then('a MRD trigger card {card_name} with value of {card_value:f} is in the virtual receipt')
def step_impl(context: Context, card_name: str, card_value: float):
    assert context.pos.verify_virtual_receipt_contains_item(item_name=card_name, item_price=card_value)


@then('a MRD trigger card {card_name} with value of {card_value:f} is in the {transaction} transaction')
def step_impl(context: Context, card_name: str, card_value: float, transaction: str):
    assert context.pos.wait_for_item_added(description=card_name, price=card_value, item_type=46, transaction=transaction)


@then('a triggered discount {card_name} with value of {card_value:f} is in the virtual receipt')
def step_impl(context: Context, card_name: str, card_value: float):
    assert context.pos.verify_virtual_receipt_contains_item(item_name=card_name, item_price=-card_value)


@then('a triggered discount {card_name} with value of {card_value:f} is in the {transaction} transaction')
def step_impl(context: Context, card_name: str, card_value: float, transaction: str):
    assert context.pos.wait_for_item_added(description=card_name, price=-card_value, item_type=4, transaction=transaction)
# endregion
