from behave import *
from behave.runner import Context
from cfrpos.core.bdd_utils.errors import ProductError
from cfrpos.core.pos.ui_metadata import POSButton, POSFrame


# region Given clauses
@given('the POS has e-check tender configured')
def step_impl(context: Context):
    for row in context.table:
        context.pos.relay_catalog.tender_relay.create_tender(tender_id=row["tender_id"], description=row["description"], tender_type_id=2, tender_mode=35660288, tender_mode_2=128)
        context.pos.relay_catalog.tender_relay.create_tender_button(tender_id=row["tender_id"], description=row["description"], action='AMOUNT_SELECTION')
        context.pos.relay_catalog.tender_relay.create_tender_button(tender_id=row["tender_id"], description=row["description"], action='EXACT_DOLLAR')
        context.pos.relay_catalog.tender_relay.create_tender_external_id(tender_id=row["tender_id"], external_id=row["external_id"])
        context.echeck_external_id = row["external_id"]


@given('the POS has e-check reader configured')
def step_impl(context: Context):
    if not context.pos.relay_catalog.dev_set_relay.is_device_record_added(device_name='CheckReader'):
        context.pos.relay_catalog.dev_set_relay.create_device_record(device_type='CheckReader', logical_name='CHECKREADE', device_name='MagtekMiniMICR',
                                     port_name='client=0,type=com,number=4', data_info='9600_N_8_1', parameters='None', location='Local')
    if not context.checkreader_sim.is_active():
        context.checkreader_sim.start()


@given('the POS displays Manual check transit entry frame after selecting e-check tender button')
def step_impl(context: Context):
    external_id = context.echeck_external_id
    context.execute_steps('''
        when the cashier selects the {tender_type} tender button
    '''.format(tender_type="e-check", external_id=external_id))
    context.pos.wait_for_frame_open(POSFrame.ASK_CHECK_TRANSIT_NUMBER)


@given('the POS displays Manual check account entry frame')
def step_impl(context: Context):
    context.execute_steps('''
        given the POS displays Manual check transit entry frame after selecting e-check tender button
        when the cashier enters the check transit number {check_number:d}
    '''.format(check_number=123456789))
    context.pos.wait_for_frame_open(POSFrame.ASK_CHECK_ACCOUNT_NUMBER)


@given('the POS displays Manual check sequence entry frame')
def step_impl(context: Context):
    context.execute_steps('''
        given the POS displays Manual check account entry frame
        when the cashier enters the check account number {check_number:d}
    '''.format(check_number=987654321))
    context.pos.wait_for_frame_open(POSFrame.ASK_CHECK_SEQUENCE_NUMBER)


@given('the cashier pressed the e-check tender button')
def step_impl(context: Context):
    external_id = context.echeck_external_id
    tender_button = "tender-check" + "-" + external_id
    assert context.pos.navigate_to_tenderbar_button(tender_button)
    context.pos.control.press_button_on_frame(POSFrame.MAIN, POSButton.TENDER_CHECK_NO_EXTERNAL_ID, button_suffix='-' + external_id)


@given('the cashier entered {amount:f} dollar amount in Ask tender amount {tender_type} frame')
def step_impl(context: Context, amount: float, tender_type: str):
    context.execute_steps('''
        when the cashier enters {amount:f} dollar amount in Ask tender amount {tender_type} frame
    '''.format(amount=amount, tender_type=tender_type))


@given('the cashier tendered the transaction with amount {amount:f} by swiping an e-check {check_name}')
def step_impl(context: Context, amount: float, check_name: str):
    external_id = context.echeck_external_id
    context.receipt_count = context.print_sim.get_receipt_count()
    context.pos.tender_transaction(tender_type="e-check", external_id=external_id, amount=amount, check_name=check_name)


@given('the POS displays Ask tender amount check frame after swiping an e-check {check_name}')
def step_impl(context: Context, check_name: str):
    external_id = context.echeck_external_id
    context.execute_steps('''
        given the cashier pressed the {tender_type} tender button
    '''.format(tender_type='e-check', external_id=external_id))
    context.checkreader_sim.read(check_name=check_name)
    context.pos.wait_for_frame_open(POSFrame.ASK_TENDER_AMOUNT_CHECK)
    context.receipt_count = context.print_sim.get_receipt_count()


@given('the POS displays Ask tender amount check frame after manually entering check data')
def step_impl(context: Context):
    context.execute_steps('''
        given the POS displays Manual check sequence entry frame
        when the cashier enters the check sequence number {check_number:d}
    '''.format(check_number=1234))
    context.pos.wait_for_frame_open(POSFrame.ASK_TENDER_AMOUNT_CHECK)
    context.receipt_count = context.print_sim.get_receipt_count()


@given('the POS displays Did customer agree to check terms frame after swiping a check {check}')
def step_impl(context: Context, check: str):
    external_id = context.echeck_external_id
    context.receipt_count = context.print_sim.get_receipt_count()
    context.pos.tender_transaction(tender_type="e-check", external_id=external_id, check_name=check)
    context.pos.wait_for_frame_open(POSFrame.ASK_ECHECK_AGREEMENT)
    context.pos.wait_for_receipt_count_increase(context.receipt_count, timeout=15)


@given('the cashier pressed {button} on Did customer agree to check terms frame')
def step_impl(context: Context, button: str):
    context.pos.wait_for_frame_open(POSFrame.ASK_ECHECK_AGREEMENT)
    context.pos.wait_for_receipt_count_increase(context.receipt_count, timeout=15)
    context.execute_steps('''
        when the cashier presses {button} on Did customer agree to check terms frame
    '''.format(button=button))
    if button.lower() == 'no':
        context.pos.return_to_mainframe()


@given('a {amount:f} e-check partial tender is present in the transaction')
def step_impl(context: Context, amount: float):
    context.execute_steps('''
        given the cashier tendered the transaction with amount {amount:f} by swiping an e-check {check_name}
        given the cashier pressed {button} on Did customer agree to check terms frame
    '''.format(amount=amount, check_name='Paragon check', button='Yes'))
    context.pos.wait_for_frame_open(POSFrame.MAIN)
# endregion


# region When clauses
@when('the cashier selects the e-check tender button')
def step_impl(context: Context):
    external_id = context.echeck_external_id
    context.execute_steps('''
        given the cashier pressed the {tender_type} tender button
    '''.format(tender_type="e-check", external_id=external_id))


@when('the cashier enters the check transit number {check_number:d}')
def step_impl(context: Context, check_number: int):
    context.pos.press_digits(POSFrame.ASK_CHECK_TRANSIT_NUMBER, check_number)
    context.pos.press_enter_on_current_frame()


@when('the cashier enters the check account number {check_number:d}')
def step_impl(context: Context, check_number: int):
    context.pos.press_digits(POSFrame.ASK_CHECK_ACCOUNT_NUMBER, check_number)
    context.pos.press_enter_on_current_frame()


@when('the cashier enters the check sequence number {check_number:d}')
def step_impl(context: Context, check_number: int):
    context.pos.press_digits(POSFrame.ASK_CHECK_SEQUENCE_NUMBER, check_number)
    context.pos.press_enter_on_current_frame()


@when('the customer swipes e-check {check_name}')
def step_impl(context: Context, check_name: str):
    context.receipt_count = context.print_sim.get_receipt_count()
    context.checkreader_sim.read(check_name=check_name)


@when('the cashier presses {button} on Did customer agree to check terms frame')
def step_impl(context: Context, button: str):
    if button.lower() == 'yes':
        button = POSButton.YES
    elif button.lower() == 'no':
        button = POSButton.NO
    else:
        raise ProductError('The button "{}" is not yes or no button.'.format(button))
    context.pos.press_button_on_frame(POSFrame.ASK_ECHECK_AGREEMENT, button)
# endregion


# region Then clauses
@then('the POS displays Manual check transit entry frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_CHECK_TRANSIT_NUMBER)


@then('the POS displays Manual check account entry frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_CHECK_ACCOUNT_NUMBER)


@then('the POS displays Manual check sequence entry frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_CHECK_SEQUENCE_NUMBER)


@then('the POS displays Did customer agree to check terms frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_ECHECK_AGREEMENT)
    context.pos.wait_for_receipt_count_increase(context.receipt_count, timeout=15)
# endregion
