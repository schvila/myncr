import time
from behave import *
from behave.runner import Context

from cfrpos.core.pos.ui_metadata import POSFrame, POSButton


# region Given clauses (configuration)
@given('RPOS is running with Shell Vantage brand')
def step_impl(context: Context):
    rpos_env = context.pos.rpos_env
    context.pos.relay_catalog.reset()
    if not context.wincor_sim.is_active():
        context.wincor_sim.start(rpos_env)
    context.wincor_sim.set_ask_for_qr_on_cardread('false')

    if not context.pos.relay_catalog.dev_set_relay.is_device_record_added(device_name='IFSFDCPosEps'):
        context.pos.relay_catalog.dev_set_relay.create_device_record(device_type='PayAndLoyClient', logical_name='IFSFPOSEPS', device_name='IFSFDCPosEps',
                                    port_name='client=0,type=com,number=0', data_info='0__0_0', parameters='None', location='Primary')

    context.pos.relay_catalog.dll_relay.modify_dll_tag(old_dll='EpsilonClient.dll', new_dll='EPSILONCLIENT_PLC.dll')
    context.pos.relay_catalog.dll_relay.modify_dll_tag(old_dll='POSSigmaClient.dll', new_dll='POSSigmaClientPLC.dll')
    if not context.dc_server.is_active():
        context.dc_server.start(rpos_env)


@given('the cashier selected Credit tender without loyalty')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton.TENDER_CREDIT)
    context.pos.press_button_on_frame(POSFrame.ASK_EXTERNAL_QUESTION, POSButton.NO)
    context.pos.press_button_on_frame(POSFrame.ASK_TENDER_AMOUNT_CREDIT, POSButton.EXACT_DOLLAR)
    time.sleep(2)


@given('mobile payments are enabled on wincor side')
def step_impl(context: Context):
    context.wincor_sim.set_ask_for_qr_on_cardread("true")


@given('the POS displayed Scan barcode frame after selecting credit tender')
def step_impl(context: Context):
    context.execute_steps('''
        given the cashier selected Credit tender without loyalty
    ''')
    context.pos.wait_for_frame_open(frame=POSFrame.ASK_BARCODE_SCAN)


@given('the cashier presses Go back button on Credit Tender frame')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.ASK_TENDER_AMOUNT_CREDIT, POSButton.GO_BACK)


@given('the cashier selects Credit tender button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton.TENDER_CREDIT)
    context.pos.wait_for_frame_open(POSFrame.ASK_TENDER_AMOUNT_CREDIT)


@given('the cashier selected Credit tender with loyalty {card_name}')
def step_impl(context: Context, card_name:str):
    context.execute_steps('''
        given the cashier selected Credit tender with loyalty
        given the customer swiped a loyalty card {card_name} at the pinpad
        given the cashier pressed Exact dollar button on the current frame
    '''.format(card_name = card_name))


@given('the cashier selected Credit tender without prompt with loyalty {card_name}')
def step_impl(context: Context, card_name:str):
    context.execute_steps('''
        given the cashier selects Credit tender button
        given the customer swiped a loyalty card {card_name} at the pinpad
        given the cashier pressed Exact dollar button on the current frame
    '''.format(card_name = card_name))
# endregion


# region When clauses
@when('the customer swipes a primary payment {card_type} card {card}')
def step_impl(context: Context, card_type: str, card: str):
    context.wincor_sim.swipe_card(pos='1', card=card)


@when('the cashier selects Credit tender without loyalty')
def step_impl(context: Context):
    context.execute_steps('''
        given the cashier selected Credit tender without loyalty
    ''')
# endregion


# region Then clauses
@then('the POS displays Scan barcode credit frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(frame=POSFrame.ASK_BARCODE_SCAN)


@then('the POS displays Please wait frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(frame=POSFrame.WAIT_WINCOR_PROCESSING)
# endregion