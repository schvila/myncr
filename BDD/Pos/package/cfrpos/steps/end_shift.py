from behave import *
from behave.runner import Context

from cfrpos.core.pos.ui_metadata import POSButton, POSFrame


# region Given clauses
@given('the POS displays the Drawer count frame')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.END_SHIFT)
    context.pos.wait_for_frame_open(POSFrame.ASK_DRAWER_COUNT_CASH)


@given('the POS displays the Drawer amount correct prompt')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.END_SHIFT)
    context.pos.press_digits(POSFrame.ASK_DRAWER_COUNT_CASH, 25.25)
    context.pos.press_button_on_frame(POSFrame.ASK_DRAWER_COUNT_CASH, POSButton.ENTER)
    context.pos.wait_for_frame_open(POSFrame.ASK_DRAWER_COUNT_CORRECT)
    # there will be usage of POSHeap with the amount to enter
    # the POSHeap will be solved in Jira task RPOS-5554 or in Jira task RPOS-6967
    # Depends on which one will be solved first


@given('the POS asks for pin to sign out')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.END_SHIFT)
    context.pos.press_digits(POSFrame.ASK_DRAWER_COUNT_CASH, 25.25)
    context.pos.press_button_on_frame(POSFrame.ASK_DRAWER_COUNT_CASH, POSButton.ENTER)
    context.pos.press_button_on_frame(POSFrame.ASK_DRAWER_COUNT_CORRECT, POSButton.YES)
    context.pos.wait_for_frame_open(POSFrame.ASK_OPERATOR_PIN)


@given('the POS displays the Perform final safe drop prompt')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.END_SHIFT)
    context.pos.wait_for_frame_open(POSFrame.ASK_SAFE_DROP_PERFORM)


@given('the POS displays the Safe drop tender selection frame')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.END_SHIFT)
    context.pos.wait_for_frame_open(POSFrame.ASK_SAFE_DROP_TENDER_SELECTION)


@given('the POS displays the Safe drop tender selection after safe drop done')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.END_SHIFT)
    context.pos.press_button_on_frame(POSFrame.ASK_SAFE_DROP_TENDER_SELECTION, POSButton.TENDER_CASH)
    context.pos.press_digits(POSFrame.ASK_SAFE_DROP_AMOUNT_CASH, 35.00)
    context.pos.press_button_on_frame(POSFrame.ASK_SAFE_DROP_AMOUNT_CASH, POSButton.ENTER)
    context.pos.wait_for_frame_open(POSFrame.ASK_SAFE_DROP_TENDER_SELECTION)


@given('the cashier confirmed the Safe drop prompt')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.END_SHIFT)
    context.pos.press_button_on_frame(POSFrame.ASK_SAFE_DROP_PERFORM, POSButton.YES)
    context.pos.wait_for_frame_open(POSFrame.ASK_DRAWER_COUNT_CASH)


@given('the cashier confirmed the drawer amount')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.ASK_DRAWER_COUNT_CORRECT, POSButton.YES)


@given('the {user} with pin {pin:d} ended the shift')
def step_impl(context: Context, user: str, pin: int):
    context.pos.end_shift(pin)


@given('the POS displays the Ending count tender selection frame')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.END_SHIFT)
    context.pos.wait_for_frame_open(POSFrame.ASK_TENDER_ENDING_COUNTS)


@given('the POS displays the Ending count tender selection frame after entering all tender amounts')
def step_impl(context: Context):
    context.execute_steps("given the POS displays the Ending count tender selection frame")
    context.pos.enter_all_tender_counts(frame_use=POSFrame.ASK_TENDER_ENDING_COUNTS, confirm=False)
    context.pos.wait_for_frame_open(POSFrame.ASK_TENDER_ENDING_COUNTS)
# endregion


# region When clauses
@when('the cashier presses the End shift button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.END_SHIFT)


@when('the cashier enters the drawer amount {amount:f}')
def step_impl(context: Context, amount: float):
    context.pos.press_digits(POSFrame.ASK_DRAWER_COUNT_CASH, amount)
    context.pos.press_button_on_frame(POSFrame.ASK_DRAWER_COUNT_CASH, POSButton.ENTER)


@when('the cashier declines the drawer amount')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.ASK_DRAWER_COUNT_CORRECT, POSButton.NO)


@when('the cashier confirms to perform safe drop')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.ASK_SAFE_DROP_PERFORM, POSButton.YES)


@when('the cashier declines to perform safe drop')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.ASK_SAFE_DROP_PERFORM, POSButton.NO)


@when('the cashier selects cash tender for safe drop')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.ASK_SAFE_DROP_TENDER_SELECTION, POSButton.TENDER_CASH)


@when('the cashier confirms to finish the safe drop')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.ASK_SAFE_DROP_TENDER_SELECTION, POSButton.DONE)


@when('the cashier enters the safe drop amount {amount}')
def step_impl(context: Context, amount: float):
    context.pos.press_digits(POSFrame.ASK_SAFE_DROP_AMOUNT_CASH, amount)
    context.pos.press_button_on_frame(POSFrame.ASK_SAFE_DROP_AMOUNT_CASH, POSButton.ENTER)


@when('the cashier selects cash tender for ending count')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.ASK_TENDER_ENDING_COUNTS, POSButton.TENDER_CASH)


@when('the cashier presses the Done button')
def step_impl(context: Context):
    context.pos.press_done_on_current_frame()
# endregion


# region Then clauses
@then('the POS displays the Drawer count frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_DRAWER_COUNT_CASH)


@then('the POS displays the Drawer amount confirmation prompt')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_DRAWER_COUNT_CORRECT)


@then('the POS displays the Start shift frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.START_SHIFT)


@then('no cashier is signed in to the POS')
def step_impl(context: Context):
    assert context.pos.is_someone_signed_in() is False


@then('the POS displays the Perform final safe drop prompt')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_SAFE_DROP_PERFORM)


@then('the POS displays the Cash safe drop amount frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_SAFE_DROP_AMOUNT_CASH)


@then('the POS displays the Safe drop tender selection frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_SAFE_DROP_TENDER_SELECTION)


@then('the POS displays the Ending count tender selection frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_TENDER_ENDING_COUNTS)


@then('the shift is closed')
def step_impl(context: Context):
    pass


@then("the POS displays the Enter pin to end shift frame")
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_OPERATOR_PIN)
# endregion
