from behave import *
from behave.runner import Context

from cfrpos.core.pos.ui_metadata import POSFrame, POSButton


# region Given clauses
@given('an age restricted item with barcode {barcode} is present in the transaction after instant approval age verification')
def step_impl(context: Context, barcode: str):
    context.execute_steps('''
        given the POS displays Age verification frame after scanning an item barcode {barcode}
        when the cashier presses the instant approval button
    '''.format(barcode=barcode))
    assert context.pos.wait_for_item_added(barcode=barcode)


@given('the cashier stored a transaction with age restricted item with barcode {barcode}')
def step_impl(context: Context, barcode: str):
    context.execute_steps('''
        given an age restricted item with barcode {barcode} is present in the transaction after instant approval age verification
        given the cashier stored the transaction
    '''.format(barcode=barcode))


@given('an age restricted item with barcode {barcode} is in the transaction after manual verification of {years:n}yo customer')
def step_impl(context: Context, barcode: str, years: int):
    context.execute_steps('''
        given the POS displays Age verification frame after scanning an item barcode {barcode}
    '''.format(barcode=barcode))
    birthday = context.pos.calculate_birthday(years)
    context.pos.enter_birthday_manually(birthday)


@given('the customer failed age verification after scanning an item barcode {barcode}')
def step_impl(context: Context, barcode: str):
    context.execute_steps('''
        given the POS displays Age verification frame after scanning an item barcode {barcode}
    '''.format(barcode=barcode))
    birthday = context.pos.calculate_birthday(1)
    context.pos.enter_birthday_manually(birthday)


@given('the POS displays Over/Under Age verification frame after scanning an item barcode {barcode}')
def step_impl(context: Context, barcode: str):
    context.pos.scan_item_barcode(barcode=barcode, barcode_type='UPC_EAN')
    context.pos.wait_for_frame_open(frame=POSFrame.ASK_VERIFY_AGE_OVER_UNDER, timeout=3)


@given('the customer failed Over/Under age verification after scanning an item barcode {barcode}')
def step_impl(context: Context, barcode: str):
    context.execute_steps('''
        given the POS displays Over/Under Age verification frame after scanning an item barcode {barcode}
    '''.format(barcode=barcode))
    context.pos.press_button_on_frame(POSFrame.ASK_VERIFY_AGE_OVER_UNDER, POSButton.UNDER)


@given('an age restricted item with barcode {barcode} is present in the transaction after Over/Under age verification')
def step_impl(context: Context, barcode: str):
    context.execute_steps('''
        given the POS displays Over/Under Age verification frame after scanning an item barcode {barcode}
    '''.format(barcode=barcode))
    context.pos.press_button_on_frame(POSFrame.ASK_VERIFY_AGE_OVER_UNDER, POSButton.OVER)


@given('the POS displays Manual only Age verification frame after scanning an item barcode {barcode}')
def step_impl(context: Context, barcode: str):
    context.pos.scan_item_barcode(barcode=barcode, barcode_type='UPC_EAN')
    context.pos.wait_for_frame_open(frame=POSFrame.ASK_VERIFY_AGE_MANUAL, timeout=3)


@given('an age restricted item with barcode {barcode} is present in the transaction after instant approval on the manual age verification frame')
def step_impl(context: Context, barcode: str):
    context.execute_steps('''
        given the POS displays Manual only Age verification frame after scanning an item barcode {barcode}
    '''.format(barcode=barcode))
    context.pos.press_button_on_frame(POSFrame.ASK_VERIFY_AGE_MANUAL, POSButton.INSTANT_APPROVAL)
    assert context.pos.wait_for_item_added(barcode=barcode)


@given('the POS displays the Age verification frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_VERIFY_AGE)


@given('the POS displays Age verification frame after scanning an item barcode {barcode}')
def step_impl(context: Context, barcode: str):
    context.pos.wait_for_frame_open(frame=POSFrame.MAIN)
    context.pos.scan_item_barcode(barcode=barcode, barcode_type='UPC_EAN')
    context.pos.wait_for_frame_open(frame=POSFrame.ASK_VERIFY_AGE, timeout=3)
# endregion


# region When clauses
@when('the cashier manually enters the customer\'s {birthday}')
def step_impl(context: Context, birthday: str):
    context.pos.enter_birthday_manually(birthday)


@when('the cashier presses the instant approval button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.ASK_VERIFY_AGE, POSButton.INSTANT_APPROVAL)


@when('the cashier presses the Over button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.ASK_VERIFY_AGE_OVER_UNDER, POSButton.OVER)


@when('the cashier presses the Under button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.ASK_VERIFY_AGE_OVER_UNDER, POSButton.UNDER)


@when('the cashier scans a driver\'s license {drivers_license}')
def step_impl(context: Context, drivers_license: str):
    context.pos.scan_drivers_license(drivers_license)


@when('the cashier swipes a driver\'s license {drivers_license}')
def step_impl(context: Context, drivers_license: str):
    context.pos.swipe_card(drivers_license)


@when('the cashier manually enters the {age:n}yo customer\'s birthday')
def step_impl(context: Context, age: int):
    birthday = context.pos.calculate_birthday(age)
    context.pos.enter_birthday_manually(birthday)
# endregion


# region Then clauses
@then('the POS displays an Error frame saying Input out of range')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_INPUT_OUT_OF_RANGE)


@then('the POS displays the Age verification frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_VERIFY_AGE)


@then('the POS displays Over/Under Age verification frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_VERIFY_AGE_OVER_UNDER)


@then('the POS displays an Error frame saying Customer does not meet age requirement')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_AGE_REQUIREMENTS_NOT_MET)
# endregion
