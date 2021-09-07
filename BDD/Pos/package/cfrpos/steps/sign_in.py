import time

from behave import *
from behave.runner import Context
from cfrpos.core.bdd_utils.errors import ProductError
from cfrpos.core.pos.ui_metadata import POSFrame, POSButton


# region Given clauses
@given("the POS has the following operators configured")
def step_impl(context: Context):
    for row in context.table:
        password = int(row["pin"])
        first_name = row["first_name"] if "first_name" in row.headings else "Cashier"
        last_name = row["last_name"] if "last_name" in row.headings else str(password)
        handle = last_name + ", " + first_name
        operator_id = row["operator_id"] if "operator_id" in row.headings else None
        operator_role = row["operator_role"] if "operator_role" in row.headings else "Cashier"
        external_id = row["external_id"] if "external_id" in row.headings else ""
        order_source_id = row["order_source_id"] if "order_source_id" in row.headings else None
        context.pos.relay_catalog.create_operator(
            password=password,
            handle=handle,
            last_name=last_name,
            first_name=first_name,
            operator_id=operator_id,
            operator_role=operator_role,
            external_id=external_id,
            order_source_id=order_source_id)


@given('the POS is in a ready to start shift state')
def step_impl(context: Context):
    context.pos.send_config()
    context.pos.ensure_ready_to_start_shift()
    context.fuel_sim.reset_fuel_sim()


@given('the cashier pressed the Start shift button')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.START_SHIFT)
    context.execute_steps('''
        when the cashier presses the Start shift button
    ''')
    context.pos.wait_for_frame_open(POSFrame.ASK_OPERATOR_PIN)


@given('the POS displays Confirm user override frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_CONFIRM_USER_OVERRIDE)


@given("the {user} started a shift with PIN {pin:d}")
def step_impl(context: Context, user: str, pin: int):
    context.pos.start_shift(pin)
    context.pos.wait_for_frame_open(POSFrame.MAIN)


@given('the cashier entered {pin} pin after pressing Start shift button')
def step_impl(context: Context, pin: int):
    context.execute_steps('''
        given the cashier pressed the Start shift button
    ''')
    context.pos.press_digits(POSFrame.ASK_OPERATOR_PIN, pin)
    context.pos.press_button_on_frame(POSFrame.ASK_OPERATOR_PIN, POSButton.SHIFT)


@given('the cashier entered the drawer amount {amount:f} after starting a shift with pin {pin}')
def step_impl(context: Context, amount: float, pin: int):
    context.execute_steps('''
        given the cashier entered {pin} pin after pressing Start shift button
    '''.format(pin=pin))
    context.pos.press_digits(POSFrame.ASK_DRAWER_COUNT_CASH, amount)
    context.pos.press_button_on_frame(POSFrame.ASK_DRAWER_COUNT_CASH, POSButton.ENTER)
    context.pos.wait_for_frame_open(POSFrame.ASK_DRAWER_COUNT_CORRECT)


@given('the POS displays an Enter user code to start shift frame')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.START_SHIFT, POSButton.SHIFT)
    context.pos.wait_for_frame_open(POSFrame.ASK_OPERATOR_PIN)


@given('the {user} with pin {pin:d} ended the shift')
def step_impl(context: Context, user: str, pin: int):
    context.pos.end_shift(pin)


@given('the POS displays the Starting counts tender selection frame')
def step_impl(context: Context):
    context.execute_steps('''
    given the cashier entered 1234 pin after pressing Start shift button
    ''')
    context.pos.wait_for_frame_open(POSFrame.ASK_TENDER_STARTING_COUNTS)


@given('the POS displays the Starting counts tender selection frame after entering all tender amounts')
def step_impl(context: Context):
    context.execute_steps("given the POS displays the Starting counts tender selection frame")
    context.pos.enter_all_tender_counts(frame_use=POSFrame.ASK_TENDER_STARTING_COUNTS, confirm=False)
    context.pos.wait_for_frame_open(POSFrame.ASK_TENDER_STARTING_COUNTS)


@given('the cashier selects {button} button on Confirm user override frame')
def step_impl(context: Context, button: str):
    if button.lower() == 'no':
        context.pos.press_button_on_frame(frame=POSFrame.ASK_CONFIRM_USER_OVERRIDE, button=POSButton.NO)
    elif button.lower() == 'yes':
        context.pos.press_button_on_frame(frame=POSFrame.ASK_CONFIRM_USER_OVERRIDE, button=POSButton.YES)
    else:
        raise ProductError('Wrong button name is provided.')
# endregion


# region When clauses
@when("the cashier presses the Start shift button")
def step_impl(context: Context):
    context.pos.control.press_button_on_frame(POSFrame.START_SHIFT, POSButton.SHIFT)


@when('the cashier confirms the drawer amount')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.ASK_DRAWER_COUNT_CORRECT, POSButton.YES)


@when("the {user} starts a shift with PIN {pin:d}")
def step_impl(context: Context, user: str, pin: int):
    context.pos.start_shift(pin)


@when('the cashier presses Enter button on Enter user code to start shift frame')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.ASK_OPERATOR_PIN, POSButton.SHIFT)


@when('the cashier selects cash tender for starting count')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.ASK_TENDER_STARTING_COUNTS, POSButton.TENDER_CASH)
# endregion


# region Then clauses
@then("the POS displays Enter user code to start shift frame")
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_OPERATOR_PIN)


@then('the POS displays Confirm user override frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_CONFIRM_USER_OVERRIDE)


@then('the POS displays Incorrect locking operator error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_INCORRECT_LOCKING_OPERATOR)


@then('the POS displays Operator not found error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_OPERATOR_NOT_FOUND)


@then('the POS displays the Starting counts tender selection frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_TENDER_STARTING_COUNTS)
# endregion
