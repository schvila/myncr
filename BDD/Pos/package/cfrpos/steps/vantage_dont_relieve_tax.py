import time
import math
from behave import *
from behave.runner import Context

from cfrpos.core.pos.ui_metadata import POSFrame, POSButton

@given('the cashier selected Credit tender with Loyalty')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton.TENDER_CREDIT)
    context.pos.press_button_on_frame(POSFrame.ASK_EXTERNAL_QUESTION, POSButton.YES)

@given('the customer swiped a loyalty card {card_name} at the pinpad')
def step_impl(context: Context, card_name: str):
    context.wincor_sim.swipe_card(pos='1', card=card_name)

@given('the cashier pressed Exact dollar button on the current frame')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.ASK_TENDER_AMOUNT_CREDIT, POSButton.EXACT_DOLLAR)
    context.pos.control.wait_for_frame_open(frame=POSFrame.MAIN)
