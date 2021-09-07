from behave import *
from behave.runner import Context
from cfrpos.core.pos.ui_metadata import POSButton, POSFrame
from cfrpos.core.bdd_utils.errors import ProductError


# region Given clauses
@given('a lottery ticket {lottery_name} with price {price:f} is present in the transaction')
def step_impl(context: Context, lottery_name: str, price: float):
    context.execute_steps(''' given the POS displays Select lottery sale frame ''')
    button = lottery_name.replace(' ', '-').lower()
    context.pos.press_button_on_frame(POSFrame.ASK_LOTTERY_SALE_SELECT, button)
    context.pos.press_button_on_frame(POSFrame.ASK_VERIFY_AGE, POSButton.INSTANT_APPROVAL)


@given('a lottery redemption item {lottery_name} with price {price:f} is present in the transaction')
def step_impl(context: Context, lottery_name: str, price: float):
    context.pos.press_button_on_frame(frame=POSFrame.MAIN, button=POSButton.LOTTERY_REDEMPTION)
    context.pos.wait_for_frame_open(POSFrame.ASK_LOTTERY_REDEMPTION_SELECT)
    button = lottery_name.replace(' ', '-').lower()
    context.pos.press_button_on_frame(POSFrame.ASK_LOTTERY_REDEMPTION_SELECT, button)
    frame = context.pos.control.get_menu_frame()
    if frame.use_description == POSFrame.ASK_LOTTERY_PRIZE_TYPE.value:
        context.pos.press_button_on_frame(POSFrame.ASK_LOTTERY_PRIZE_TYPE, POSButton.LOTTERY_CASH)
    context.pos.press_digits(POSFrame.ASK_ENTER_LOTTERY_AMOUNT, price)
    context.pos.press_button_on_frame(POSFrame.ASK_ENTER_LOTTERY_AMOUNT, POSButton.ENTER)
    frame = context.pos.control.get_menu_frame()
    if frame.use_description == POSFrame.ASK_VERIFY_AGE.value:
        context.pos.press_button_on_frame(POSFrame.ASK_VERIFY_AGE, POSButton.INSTANT_APPROVAL)
    context.pos.wait_for_frame_open(POSFrame.MAIN)


@given('the POS displays Select lottery sale frame')
def step_impl(context: Context):
    context.pos.press_button_on_frame(frame=POSFrame.MAIN, button=POSButton.LOTTERY_SALE)
    context.pos.wait_for_frame_open(POSFrame.ASK_LOTTERY_SALE_SELECT)


@given('the POS displays Select lottery redemption frame')
def step_impl(context: Context):
    context.pos.press_button_on_frame(frame=POSFrame.MAIN, button=POSButton.LOTTERY_REDEMPTION)
    context.pos.wait_for_frame_open(POSFrame.ASK_LOTTERY_REDEMPTION_SELECT)


@given('the POS displays Select lottery prize type frame')
def step_impl(context: Context):
    context.execute_steps('''
        given the POS displays Select lottery redemption frame
        when the cashier selects PDI Instant Lottery Tx button on Select lottery redemption frame
        then the POS displays Select lottery prize type frame
   ''')


@given('the cashier selected {button} button on Select lottery sale frame')
def step_impl(context: Context, button: str):
    context.execute_steps('''
        given the POS displays Select lottery sale frame
        when the cashier selects {button} button on Select lottery sale frame
   '''.format(button=button))


@given('the cashier selected {button} button on Select lottery redemption frame')
def step_impl(context: Context, button: str):
    context.execute_steps('''
        given the POS displays Select lottery redemption frame
        when the cashier selects {button} button on Select lottery redemption frame
        then the POS displays Select lottery prize type frame
   '''.format(button=button))


@given('the POS displays the Age verification frame after selling a lottery ticket {lottery_name} with price {price:f}')
def step_impl(context: Context, lottery_name: str, price: float):
    context.execute_steps(''' given the POS displays Select lottery sale frame ''')
    button = lottery_name.replace(' ', '-').lower()
    context.pos.press_button_on_frame(POSFrame.ASK_LOTTERY_SALE_SELECT, button)
    context.pos.wait_for_frame_open(POSFrame.ASK_VERIFY_AGE)
# endregion


# region When clauses
@when('the cashier presses Lottery Sale button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton.LOTTERY_SALE)


@when('the cashier presses Lottery Redemption button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton.LOTTERY_REDEMPTION)


@when('the cashier selects {button} button on Select lottery sale frame')
def step_impl(context: Context, button: str):
    if button == "PDI Instant Lottery Tx":
        context.pos.press_button_on_frame(POSFrame.ASK_LOTTERY_SALE_SELECT, POSButton.PDI_INSTANT_LOTTERY_TX)
    elif button == "PDI Machine Lottery Tx":
        context.pos.press_button_on_frame(POSFrame.ASK_LOTTERY_SALE_SELECT, POSButton.PDI_MACHINE_LOTTERY_TX)
    else:
        raise ProductError("Wrong button name is provided.")


@when('the cashier selects {button} button on Select lottery redemption frame')
def step_impl(context: Context, button: str):
    if button == "PDI Instant Lottery Tx":
        context.pos.press_button_on_frame(POSFrame.ASK_LOTTERY_REDEMPTION_SELECT, POSButton.PDI_INSTANT_LOTTERY_TX)
    elif button == "PDI Machine Lottery Tx":
        context.pos.press_button_on_frame(POSFrame.ASK_LOTTERY_REDEMPTION_SELECT, POSButton.PDI_MACHINE_LOTTERY_TX)
    else:
        raise ProductError("Wrong button name is provided.")


@when('the cashier selects {button} on Select lottery prize type frame')
def step_impl(context: Context, button: str):
    if button.lower() == "cash":
        context.pos.press_button_on_frame(POSFrame.ASK_LOTTERY_PRIZE_TYPE, POSButton.LOTTERY_CASH)
    elif button.lower() == "ticket":
        context.pos.press_button_on_frame(POSFrame.ASK_LOTTERY_PRIZE_TYPE, POSButton.LOTTERY_TICKET)
    else:
        raise ProductError("Wrong button name is provided.")
# endregion


# region Then clauses
@then('the POS displays Select lottery sale frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(frame=POSFrame.ASK_LOTTERY_SALE_SELECT)


@then('the POS displays Select lottery redemption frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(frame=POSFrame.ASK_LOTTERY_REDEMPTION_SELECT)


@then('the POS displays Select lottery prize type frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(frame=POSFrame.ASK_LOTTERY_PRIZE_TYPE)


@then('the POS displays Enter lottery amount frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(frame=POSFrame.ASK_ENTER_LOTTERY_AMOUNT)
# endregion
