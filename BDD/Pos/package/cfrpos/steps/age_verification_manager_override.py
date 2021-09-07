from behave import *
from behave.runner import Context

from cfrpos.core.pos.ui_metadata import POSFrame, POSButton


# region Given clauses
@given('the POS displays restricted Age verification frame after scanning an item barcode {barcode}')
def step_impl(context: Context, barcode: str):
    context.execute_steps(
        '''
            when the cashier scans a barcode {barcode}
        '''.format(barcode=barcode))
    context.pos.wait_for_frame_open(POSFrame.ASK_VERIFY_AGE_NO_MANUAL)


@given('the POS displays Manager override frame after scanning an item barcode {barcode}')
def step_impl(context: Context, barcode: str):
    context.execute_steps(
        '''
            given the POS displays restricted Age verification frame after scanning an item barcode {barcode}
            when the cashier selects Manual entry button
            then the POS displays Manager override frame
        '''.format(barcode=barcode))


@given('the POS displays Age verification frame after manager signed in using {pin:d} PIN')
def step_impl(context: Context, pin: int):
    context.execute_steps(
        '''
            when the {operator} signs in using {pin:d} PIN
            then the POS displays the Age verification frame
        '''.format(operator='manager', pin=pin))
# endregion


# region When clauses
@when('the cashier selects Manual entry button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.ASK_VERIFY_AGE_NO_MANUAL, POSButton.MANUAL_ENTRY)


@when('the {operator} signs in using {pin:d} PIN')
def step_impl(context: Context, operator: str, pin: int):
    context.pos.press_digits(POSFrame.ASK_SECURITY_OVERRIDE, pin)
    context.pos.press_button_on_frame(POSFrame.ASK_SECURITY_OVERRIDE, POSButton.ENTER)
# endregion


# region Then clauses
@then('the Manual entry button is not displayed on the current frame')
def step_impl(context: Context):
    menu_frame = context.pos.control.get_menu_frame()
    assert not menu_frame.has_button(POSButton.MANUAL_ENTRY)


@then('the Manual entry button is displayed on the current frame')
def step_impl(context: Context):
    menu_frame = context.pos.control.get_menu_frame()
    assert menu_frame.has_button(POSButton.MANUAL_ENTRY)


@then('the POS displays restricted Age verification frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_VERIFY_AGE_NO_MANUAL)


@then('the POS displays Manager override frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_SECURITY_OVERRIDE)


@then('the POS displays Security denied error frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_SECURITY_DENIED)
# endregion
