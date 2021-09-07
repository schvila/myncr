import time
from behave import *
from behave.runner import Context
from cfrpos.core.bdd_utils.errors import ProductError
from cfrpos.core.pos.ui_metadata import POSButton, POSFrame


# region Given clauses
@given('the pricebook contains reason codes for transaction refund')
def step_impl(context: Context):
    pass


@given('the POS displays Scroll previous frame')
def step_impl(context: Context):
    time.sleep(1) # Wait for the previous transaction to be loaded by SC simulator
    context.execute_steps('''
        Given the POS displays Other functions frame
        When the cashier presses Scroll previous button
    ''')
    context.pos.wait_for_frame_open(POSFrame.SCROLL_PREVIOUS)


@given('the cashier pressed Refund Fuel button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.SCROLL_PREVIOUS, POSButton.REFUND_FUEL)


@given('the cashier selected a reason {reason} to refund a transaction')
def step_impl(context: Context, reason: str):
    context.pos.wait_for_frame_open(POSFrame.ASK_FOR_A_REASON)
    context.pos.select_item_in_list(POSFrame.ASK_FOR_A_REASON, item_name=reason)


@given('a dummy transaction was finalized on POS')
def step_impl(context: Context):
    context.execute_steps('''
        Given an item with barcode 099999999990 is present in the transaction
        And the transaction is tendered
        Then the transaction is finalized
    ''')


@given('{tran_count:d} dummy transactions were finalized on POS')
def step_impl(context: Context, tran_count: int):
    count = int(tran_count)
    while count > 0:
        context.execute_steps('''Given a dummy transaction was finalized on POS''')
        count = count - 1


@given('the cashier selected last transaction on the Scroll previous list')
def step_impl(context: Context):
    time.sleep(1)  # Wait for the previous transaction to be loaded by SC simulator
    context.execute_steps('''
        Given the POS displays Other functions frame
        When the cashier presses Scroll previous button
        And the cashier selects last transaction on the Scroll previous list
    ''')
    assert context.pos.get_tran_param_from_scroll_previous_line() is not None


@given('the cashier selected next to last transaction on the Scroll previous list')
def step_impl(context: Context):
    time.sleep(1) # Wait for the previous transaction to be loaded by SC simulator
    context.execute_steps('''
        Given the POS displays Other functions frame
        When the cashier presses Scroll previous button
    ''')
    context.pos.select_item_in_scroll_previous_list(position=1)
    assert context.pos.get_tran_param_from_scroll_previous_line() is not None


@given('a transaction with {item_name} was tendered by cash on POS {node_number:n}')
def step_impl(context: Context, item_name: str, node_number: int):
    context.sc.reset_tran_repository()
    context.sc.inject_transaction(tran_xml='dry_stock_transaction.xml')


@given('the cashier selected a reason to refund fuel from last transaction')
def step_impl(context: Context):
    context.pos.select_item_in_scroll_previous_list(position=1)
    assert context.pos.get_tran_param_from_scroll_previous_line() is not None
    context.pos.press_button_on_frame(POSFrame.SCROLL_PREVIOUS, POSButton.REFUND_FUEL)
    context.pos.wait_for_frame_open(POSFrame.ASK_FOR_A_REASON)
    context.execute_steps('''
        When the cashier selects the first reason from the displayed list
    ''')
# endregion


# region When clauses
@when('the cashier presses Scroll previous button')
def step_impl(context: Context):
    time.sleep(1) # Wait for the previous transaction to be loaded by SC simulator
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.SCROLL_PREVIOUS)


@when('the cashier selects last transaction on the Scroll previous list')
def step_impl(context: Context):
    context.pos.select_item_in_scroll_previous_list(position=0)


@when('the cashier selects transaction with number {tran_number:d} on the Scroll previous list')
def step_impl(context: Context, tran_number: int):
    context.pos.select_item_in_scroll_previous_list(transaction_sequence_number=tran_number)


@when('the cashier prints the selected transaction in Scroll previous list')
def step_impl(context: Context):
    result = context.pos.print_receipt_from_scroll_previous()
    assert result, 'Receipt was not printed'


@when('the cashier prints the last prepay transaction on the Scroll previous list')
def step_impl(context: Context):
    context.execute_steps('''
        Given the POS displays Other functions frame
        When the cashier presses Scroll previous button
        And the cashier selects last transaction on the Scroll previous list
    ''')
    time.sleep(1.0) # Wait for the transaction from SyncFinalize response to be loaded by SC simulator
    orig_count = context.pos.get_receipt_count()
    context.pos.press_button_on_frame(POSFrame.SCROLL_PREVIOUS, POSButton.PRINT_RECEIPT)
    result = context.pos.wait_for_receipt_count_increase(orig_count, 5)
    assert result, "Receipt was not printed"


@when('the cashier selects {button_id} button on the Scroll previous frame')
def step_impl(context: Context, button_id: str):
    button_id = button_id.lower()
    if button_id == 'refund fuel':
        context.pos.press_button_on_frame(frame=POSFrame.SCROLL_PREVIOUS, button=POSButton.REFUND_FUEL)
    elif button_id == 'related prepay':
        context.pos.press_button_on_frame(frame=POSFrame.SCROLL_PREVIOUS, button=POSButton.RELATED_PREPAY)
    else:
        raise ProductError('The given button {button_id} is not available on the frame {current_frame}'.format(button_id=button_id, current_frame=POSFrame.SCROLL_PREVIOUS))
# endregion


# region Then clauses
@then('the POS displays Scroll previous frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.SCROLL_PREVIOUS)


@then('the selected line in Scroll previous contains a {element}')
def step_impl(context: Context, element: str):
    selected_line = context.pos.get_tran_param_from_scroll_previous_line()
    assert selected_line is not None

    for row in context.table.rows:
        assert getattr(selected_line, row.cells[0].replace(' ', '_')) is not None


@then('the selected line in Scroll previous contains following elements')
def step_impl(context: Context):
    selected_line = context.pos.get_tran_param_from_scroll_previous_line()
    assert selected_line is not None

    for row in context.table.rows:
        assert str(getattr(selected_line, row.cells[0].replace(' ', '_'))) == row.cells[1]


@then('the POS displays Refund not allowed error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_REFUND_NOT_ALLOWED)


@then('the Scroll previous list contains the last performed transaction')
def step_impl(context: Context):
    context.pos.select_item_in_scroll_previous_list(transaction_sequence_number=context.pos.get_transaction('previous').sequence_number)
    assert context.pos.get_tran_param_from_scroll_previous_line() is not None
# endregion
