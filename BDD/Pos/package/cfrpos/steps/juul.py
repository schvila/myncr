from behave import *
from behave.runner import Context

from cfrpos.core.bdd_utils.errors import ProductError
from cfrpos.core.pos.ui_metadata import POSButton, POSFrame
from cfrpos.core.pos.pos_product import POSProduct
from cfrpos.core.pos.pos_control import POSControl
from cfrpos.core.pos.user_interface import MenuFrame

# region Given clauses (configuration)
@given('the pricebook contains retail item groups')
def step_impl(context: Context):
    for row in context.table:
        context.pos.relay_catalog.create_retail_item_group(row["group_id"], row["external_id"])

@given('retail item group with id {group_id} contains items')
def step_impl(context: Context, group_id: int):
    for row in context.table:
        context.pos.relay_catalog.assign_item_to_retail_item_group(group_id, row["item_id"])

@given('the POS displays JUUL Age verification frame after scanning a JUUL item barcode {item_barcode}')
def step_impl(context: Context, item_barcode: str):
    context.execute_steps('''
        when the cashier scans a barcode {barcode}
        then the POS displays JUUL Age verification frame
    '''.format(barcode=item_barcode))

@given('the POS displays ID validation frame after scanning a JUUL item barcode {item_barcode}')
def step_impl(context: Context, item_barcode: str):
    context.execute_steps('''
        when the cashier scans a barcode {barcode}
        then the POS displays JUUL Age verification frame
        when the cashier scans a driver\'s license valid DL
        then the POS displays ID validation frame
    '''.format(barcode=item_barcode))

@given('a JUUL item with barcode {item_barcode} is present in the transaction')
def step_impl(context: Context, item_barcode: str):
    context.execute_steps('''when the cashier adds a JUUL item with barcode {item_barcode}'''.format(
        item_barcode=item_barcode))

@given('a JUUL item {item_name} with barcode {item_barcode} is present in the transaction {allowed_quantity} times')
def step_impl(context: Context, item_name: str, item_barcode: str, allowed_quantity: int):
    context.execute_steps('''
        when the cashier adds a JUUL item with barcode {item_barcode}
        when the cashier updates quantity of the item {item_name} to {quantity}
    '''.format(item_barcode=item_barcode, item_name=item_name, quantity=allowed_quantity))

@given('an age restricted item with barcode {item_barcode} is present in the transaction after manual entry verification')
def step_impl(context: Context, item_barcode: str):
    context.execute_steps('''
        given the POS displays Age verification frame after scanning an item barcode {item_barcode}
        when the cashier manually enters the customer's birthday 01-01-1970
    '''.format(item_barcode=item_barcode))

@given('an age restricted item with barcode {item_barcode} is present in the transaction after instant verification')
def step_impl(context: Context, item_barcode: str):
    context.execute_steps('''
        given the POS displays Age verification frame after scanning an item barcode {item_barcode}
        when the cashier presses the instant approval button
    '''.format(item_barcode=item_barcode))

@given('an age restricted item with barcode {item_barcode} is present in the transaction after driver\'s license scan verification')
def step_impl(context: Context, item_barcode: str):
    context.execute_steps('''
        given the POS displays Age verification frame after scanning an item barcode {item_barcode}
        when the cashier scans a driver's license valid DL
        then the POS displays ID validation frame
        when the cashier selects Yes button
    '''.format(item_barcode=item_barcode))
    context.pos.wait_for_item_added(item_barcode)

@given('an age restricted item with barcode {item_barcode} is present in the transaction after driver\'s license swipe verification')
def step_impl(context: Context, item_barcode: str):
    context.execute_steps('''
        given the POS displays Age verification frame after scanning an item barcode {item_barcode}
        when the cashier swipes a driver's license valid DL
        then the POS displays ID validation frame
        when the cashier selects Yes button
    '''.format(item_barcode=item_barcode))
    context.pos.wait_for_item_added(item_barcode)

@given('the POS displays an Error frame saying Customer does not meet age requirement after scanning a JUUL item barcode {item_barcode} and scanning a driver\'s license {drivers_license}')
def step_impl(context: Context, item_barcode: str, drivers_license: str):
    context.execute_steps('''
        when the cashier scans a barcode {barcode}
        when the cashier scans a driver\'s license {drivers_license}
        then the POS displays an Error frame saying Customer does not meet age requirement
    '''.format(barcode=item_barcode, drivers_license=drivers_license))
# endregion

# region When clauses
@when('the cashier adds a JUUL item with barcode {item_barcode}')
def step_impl(context: Context, item_barcode: str):
    context.execute_steps(
        'when the cashier scans a barcode {barcode}'.format(barcode=item_barcode))
    if context.pos.control.wait_for_frame_open(frame=POSFrame.ASK_VERIFY_AGE_JUUL, timeout=2):
        context.execute_steps('''
            when the cashier scans a driver\'s license valid DL
            then the POS displays ID validation frame
            when the cashier selects Yes button
        ''')
    context.pos.wait_for_item_added(barcode=item_barcode)
# endregion

# region Then clauses
@then('the POS displays JUUL Age verification frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(frame=POSFrame.ASK_VERIFY_AGE_JUUL, timeout=2)

@then('the POS displays ID validation frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(frame=POSFrame.ASK_VALIDATE_ID, timeout=2)

@then('the instant verification button is not displayed on the current frame')
def step_impl(context: Context):
    menu_frame = context.pos.control.get_menu_frame()
    assert not menu_frame.has_button(POSButton.INSTANT_APPROVAL)

@then('the manual entry keyboard is not displayed on the current frame')
def step_impl(context: Context):
    menu_frame = context.pos.control.get_menu_frame()
    manual_entry_keyboard = [POSButton.KEY_7, POSButton.KEY_8, POSButton.KEY_9,
                             POSButton.KEY_4, POSButton.KEY_5, POSButton.KEY_6,
                             POSButton.KEY_1, POSButton.KEY_2, POSButton.KEY_3,
                             POSButton.BACKSPACE, POSButton.KEY_0, POSButton.CLEAR]
    assert not any(menu_frame.has_button(button) for button in manual_entry_keyboard)

@then('the POS displays Item count exceeds maximum error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(frame=POSFrame.MSG_ITEM_COUNT_EXCEEDS_MAXIMUM, timeout=2)

@then('the POS displays a list of previously added age restricted items to remove which contains {item_name}')
def step_impl(context: Context, item_name: str):
    context.pos.wait_for_frame_open(frame=POSFrame.MSG_VERIFIED_AGE_LOWERED, timeout=2)
# endregion
