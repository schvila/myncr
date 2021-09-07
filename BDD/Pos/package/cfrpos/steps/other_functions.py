from behave import *
from behave.runner import Context
import time

from cfrpos.core.bdd_utils.errors import ProductError
from cfrpos.core.pos.ui_metadata import POSFrame, POSButton
from cfrpos.core.pos.pos_product import POSProduct


# region Given clauses (configuration)
@given('the POS displays Other functions frame')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
    context.pos.wait_for_frame_open(POSFrame.OTHER_FUNCTIONS)


@given('the POS displays Version info frame')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.VERSION_INFO)
    context.pos.wait_for_frame_open(POSFrame.VERSION_INFO)


@given('the cashier pressed Version info button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.VERSION_INFO)


@given('the cashier pressed Lock POS button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.LOCK)


@given('the cashier entered {pin} pin on Terminal lock frame and pressed unlock button')
def step_impl(context: Context, pin: int):
    context.pos.press_digits(POSFrame.TERMINAL_LOCK, pin)
    context.pos.press_button_on_frame(POSFrame.TERMINAL_LOCK, POSButton.UNLOCK)


@given('the {user} pressed {button} button on Ask to lock terminal frame')
def step_impl(context: Context, button: str, user: str):
    if button.lower() == 'yes':
        button = POSButton.YES
    elif button.lower() == 'no':
        button = POSButton.NO
    else:
        raise ProductError('The button "{}" is not yes or no button.'.format(button))
    context.pos.press_button_on_frame(POSFrame.ASK_CONFIRM_LOCK_TERMINAL, button)


@given('the cashier pressed Loyalty Balance Inquiry button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.LOYALTY_BALANCE_INQUIRY)
    context.pos.wait_for_frame_open(POSFrame.ASK_LOYALTY_CARD)


@given('the {button} button is not on a frame {frame}')
def step_impl(context: Context, button: str, frame: str):
    assert not context.pos.relay_catalog.menu_frames_relay.find_button(frame, button)


@given('the {button} button is displayed on a frame {frame}')
def step_impl(context: Context, button: str, frame: str):
    context.pos.relay_catalog.menu_frames_relay.find_button(frame, button)


@given('the transaction is switched to refund')
def step_impl(context: Context):
    context.execute_steps('''
        When the cashier switches the transaction to refund
    ''')
# endregion


# region When clauses
@when('the cashier presses Show business day button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.SHOW_BUSINESS_DAY)


@when('the cashier presses Lock POS button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.LOCK)


@when('the {user} enters {pin} pin on Terminal lock frame and presses unlock button')
def step_impl(context: Context, pin: int, user: str):
    context.pos.press_digits(POSFrame.TERMINAL_LOCK, pin)
    context.pos.press_button_on_frame(POSFrame.TERMINAL_LOCK, POSButton.UNLOCK)


@when('the cashier presses Version Info button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.VERSION_INFO)


@when('the cashier presses {button_type} button on receipt frame')
def step_impl(context: Context, button_type: str):
    button = button_type.lower()
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton(button))


@when('the POS is inactive for {seconds:d} seconds')
def step_impl(context: Context, seconds: int):
    time.sleep(seconds)


@when('the button {button} is removed from a frame {frame}')
def step_impl(context: Context, button: str, frame: str):
    context.pos.relay_catalog.menu_frames_relay.delete_button(frame, button)
    context.pos.send_config()
    context.pos.restart()
    context.pos.ensure_ready_to_sell()

@when('the button {button_name} is added on a frame {frame}')
def step_impl(context: Context, button_name: str, frame: str):
    # Hard-coded values for button position will be removed once the RPOS-21891 is resolved
    context.pos.relay_catalog.create_button_on_frame(frame_name=frame, text_string=button_name, button_left=596, button_top=280)
    context.pos.send_config()
    context.pos.restart()
    context.pos.ensure_ready_to_sell()


@when('the cashier switches the transaction to refund')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.REFUND)
    context.pos.press_button_on_frame(POSFrame.ASK_CONFIRM_REFUND, POSButton.YES)
    context.pos.select_item_in_list(frame=POSFrame.ASK_FOR_A_REASON, item_position=0)
# endregion


# region Then clauses
@then('the POS displays Other functions frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.OTHER_FUNCTIONS)


@then('the POS displays Version info frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.VERSION_INFO)


@then('the POS displays Terminal lock frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.TERMINAL_LOCK)


@then('the POS displays Ask to lock terminal frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_CONFIRM_LOCK_TERMINAL)


@then('the POS displays Lock while transaction in progress error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_LOCK_WHILE_TRAN_IN_PROGRESS)


@then('the POS displays Current business day frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_OTHER)


@then('the {button} button is not on the frame {frame}')
def step_impl(context: Context, button: str, frame: str):
    assert not context.pos.relay_catalog.menu_frames_relay.find_button(frame, button)


@then('the {button} button is on the frame {frame}')
def step_impl(context: Context, button: str, frame: str):
    context.pos.relay_catalog.menu_frames_relay.find_button(frame, button)
# endregion