from behave import *
from behave.runner import Context

from cfrpos.core.pos.ui_metadata import POSFrame, POSButton


# region Given clauses
@given('an age restricted item with barcode {barcode} is present in the transaction after manual entry age verification')
def step_impl(context: Context, barcode: str):
    context.execute_steps('''
            given an age restricted item with barcode {barcode} is in the transaction after manual verification of {years:n}yo customer
        '''.format(barcode=barcode, years=25))


@given('the POS displays an Error frame saying Customer does not meet age requirement after scanning an age restricted item barcode {barcode} and scanning a driver\'s license {drivers_license}')
def step_impl(context: Context, barcode: str, drivers_license: str):
    context.execute_steps('''
            when the cashier scans a barcode {barcode}
            when the cashier scans a driver\'s license {drivers_license}
            then the POS displays an Error frame saying Customer does not meet age requirement
        '''.format(barcode=barcode, drivers_license=drivers_license))


@given('the POS displays a list of items to remove after failing age verification of item {barcode}')
def step_impl(context: Context, barcode: str):
    context.execute_steps('''
            given the POS displays an Error frame saying Customer does not meet age requirement after scanning an age restricted item barcode {barcode} and scanning a driver\'s license {drivers_license} 
            when the cashier selects Go back button
        '''.format(barcode=barcode, drivers_license='underage DL'))

# endregion


# region When clauses

# endregion


# region Then clauses
@then('the POS displays the Age verification frame with the instant approval button')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_VERIFY_AGE)
    assert context.pos.current_frame_has_button(POSButton.INSTANT_APPROVAL)


@then('the POS displays the Age verification frame without the instant approval button')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_VERIFY_AGE)
    assert not context.pos.current_frame_has_button(POSButton.INSTANT_APPROVAL)


@then('the POS displays the Manual only Age verification frame with the instant approval button')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_VERIFY_AGE_MANUAL)
    assert context.pos.current_frame_has_button(POSButton.INSTANT_APPROVAL)


@then('the POS displays the Manual only Age verification frame without the instant approval button')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_VERIFY_AGE_MANUAL)
    assert not context.pos.current_frame_has_button(POSButton.INSTANT_APPROVAL)


@then('the {method} age verification method is in the current transaction')
def step_impl(context: Context, method: str):
    assert context.pos.get_transaction_age_verification_method() == method
# endregion
