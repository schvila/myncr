from behave import *
from behave.runner import Context

from cfrpos.core.pos.ui_metadata import POSFrame, POSButton

# region Given clauses
@given('the Identify Employee button is configured')
def step_impl(context: Context):
    context.pos.relay_catalog.create_button_on_frame(frame_name="Hammer OtherFunc", text_string="Identify Employee", button_left=596, button_top=475, action_event=10290, action_sub_event=26)


@given('the POS displays Employee Identification frame')
def step_impl(context: Context):
    context.execute_steps('''
        given the POS displays Other functions frame  
        when the cashier presses Identify Employee button  
        ''')
    context.pos.wait_for_frame_open(POSFrame.ASK_CARD_SWIPE_FOR_SIGMA)


@given('the POS shows frame for manual card entry')
def step_impl(context: Context):
    context.execute_steps('''
        given the POS displays Other functions frame  
        when the cashier presses Identify Employee button
        then the POS displays Employee Identification frame
        when the cashier presses Enter Card button on Employee Identification frame  
        ''')
    context.pos.wait_for_frame_open(POSFrame.ASK_MANUAL_CARD_ENTRY)
#endregion


#region When clauses
@when('the cashier presses Identify Employee button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.IDENTIFY_EMPLOYEE)


@when('the cashier presses Enter Card button on Employee Identification frame')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.ASK_CARD_SWIPE_FOR_SIGMA, POSButton.ENTER_CARD)


@when('the cashier manually enters the employee card {employee_card}')
def step_impl(context: Context, employee_card:str):
    context.pos.press_digits(POSFrame.ASK_MANUAL_CARD_ENTRY, employee_card)
    context.pos.press_enter_on_current_frame()
#endregion


#region Then clauses
@then('the POS displays Employee Identification frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_CARD_SWIPE_FOR_SIGMA)


@then('the POS displays frame for manual card entry')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_MANUAL_CARD_ENTRY)


@then('the POS displays Employee Status frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_OTHER)
#endregion
