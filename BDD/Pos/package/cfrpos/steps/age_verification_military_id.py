from behave import *
from behave.runner import Context

from cfrpos.core.pos.ui_metadata import POSFrame, POSButton


# region Given clauses
@given('an age restricted item with barcode {barcode} is present in the transaction after military ID age verification of {age:n} years')
def step_impl(context: Context, barcode: str, age: int):
    context.execute_steps('''
            when the cashier scans a barcode {barcode}
            when the cashier manually enters the {age:n}yo customer\'s birthday and confirms with military id button
        '''.format(barcode=barcode, age=age))
    assert context.pos.wait_for_item_added(barcode=barcode)
# endregion


# region When clauses
@when('the cashier manually enters the {age:n}yo customer\'s birthday and confirms with military id button')
def step_impl(context: Context, age: int):
    birthday = context.pos.calculate_birthday(age)
    context.pos.enter_birthday_manually(birthday, confirm_with_enter=False)
    context.pos.press_button_on_frame(POSFrame.ASK_VERIFY_AGE, POSButton.MILITARY_ID)
# endregion


# region Then clauses
@then('the Military ID button is displayed on the current frame')
def step_impl(context: Context):
    menu_frame = context.pos.control.get_menu_frame()
    assert menu_frame.has_button(POSButton.MILITARY_ID)


@then('the Military ID button is not displayed on the current frame')
def step_impl(context: Context):
    menu_frame = context.pos.control.get_menu_frame()
    assert not menu_frame.has_button(POSButton.MILITARY_ID)
# endregion
