from behave import *
from behave.runner import Context
from cfrpos.core.pos.ui_metadata import POSButton, POSFrame


# region Given clauses
@given('the cashier pressed SVC Activation button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton.SVC_ACTIVATION)


@given('the POS displays Enter activation amount frame')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton.SVC_ACTIVATION)
    context.pos.wait_for_frame_open(POSFrame.ASK_SVC_ACTIVATION_AMOUNT)


@given('the cashier entered amount {amount:f} on Enter activation amount frame')
def step_impl(context: Context, amount: float):
    context.execute_steps('''
        given the POS displays Enter activation amount frame
        when the cashier enters amount {amount:f} on Enter activation amount frame
    '''.format(amount=amount))
    context.pos.wait_for_frame_open(POSFrame.MSG_CARD_ACTIVATION_SUCCESSFUL)


@given('a gift card activated for amount {card_value:f} is in the current transaction')
def step_impl(context: Context, card_value: float):
    context.execute_steps('''
        given the cashier entered amount {amount:f} on Enter activation amount frame
        when the cashier presses Go back button on Card activation successful frame
        then a gift card activated for amount {card_value:f} is in the {transaction} transaction
    '''.format(amount=card_value, card_value=card_value, transaction='current'))
# endregion


# region When clauses
@when('the cashier presses SVC Activation button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton.SVC_ACTIVATION)


@when('the cashier presses Go back button on Card activation successful frame')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.MSG_CARD_ACTIVATION_SUCCESSFUL, POSButton.GO_BACK)


@when('the cashier swipes an epsilon card {card_name} on the POS')
def step_impl(context: Context, card_name: str):
    context.pos.swipe_card(card_name)


@when('the cashier enters amount {amount:f} on Enter activation amount frame')
def step_impl(context: Context, amount: float):
    context.pos.wait_for_frame_open(POSFrame.ASK_SVC_ACTIVATION_AMOUNT)
    context.pos.press_digits(POSFrame.ASK_SVC_ACTIVATION_AMOUNT, amount)
    context.pos.press_button_on_frame(POSFrame.ASK_SVC_ACTIVATION_AMOUNT, POSButton.ENTER)
# endregion


# region Then clauses
@then('the POS displays Card activation successful frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_CARD_ACTIVATION_SUCCESSFUL)


@then('the POS displays Card deactivation successful frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_CARD_DEACTIVATION_SUCCESSFUL)


@then('the POS displays Enter activation amount frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_SVC_ACTIVATION_AMOUNT)


@then('a gift card activated for amount {card_value:f} is in the {transaction} transaction')
def step_impl(context: Context, card_value: float, transaction: str):
    context.execute_steps('''
        then a card {card_name} with value of {card_value:f} and type {item_type:d} is in the {transaction} transaction
    '''.format(card_name='Gift Card Activation', card_value=card_value, item_type=20, transaction=transaction))
# endregion
