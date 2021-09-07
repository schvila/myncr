from behave import *
from behave.runner import Context
import math

from cfrpos.core.bdd_utils.errors import ProductError
from cfrpos.core.pos.ui_metadata import POSFrame, POSButton


# region Given clauses (configuration)
# endregion


# region Given clauses
@given('the POS has following tender groups configured')
def step_impl(context: Context):
    for row in context.table:
        tender_group_id = row["tender_group_id"] if "tender_group_id" in row.headings else None
        position = row["position"] if "position" in row.headings else None
        context.pos.relay_catalog.create_tender_group(row["description"], tender_group_id, position)


@given('tender group with id {tender_group_id} contains tenders')
def step_impl(context: Context, tender_group_id: int):
    for row in context.table:
        context.pos.relay_catalog.assign_tender_to_group(tender_group_id, row["tender_id"])


@given('the EPS simulator has essential configuration')
def step_impl(context):
    context.pos.return_to_mainframe()
    assert context.epc_sim.eps.reset()


@given('the EPS simulator uses {card_name} card configuration')
def step_impl(context: Context, card_name: str):
    if not context.epc_sim.eps.set_active_card(card_name):
        raise ProductError('The EPS card "{}" was not setup correctly. Check the spelling, the cards are case sensitive.'.format(card_name))


@given('the EPS simulator uses {card_name} card configuration with card number {card_number}')
def step_impl(context: Context, card_name: str, card_number: str):
    context.execute_steps('''
        given the EPS simulator uses {card_name} card configuration
    '''.format(card_name=card_name))
    context.epc_sim.eps.add_nvp(card_name, 'smCARDNUMBERBO', card_number)


@given('the EPS simulator uses {card_name} card configured to trigger {discount_type} PDL discount with amount {discount:f}')
def step_impl(context: Context, card_name: str, discount_type: str, discount: float):
    context.execute_steps('''
        given the EPS simulator uses {card_name} card configuration
    '''.format(card_name=card_name))
    if not context.epc_sim.eps.set_card_for_pdl_discounts(card_name, discount, discount_type):
        raise ProductError('The needed card NVPs were not set.')


@given('the EPS simulator uses {card_name} card configured to trigger {discount_type} PDL discount with amount {discount:f} for prepays')
def step_impl(context: Context, card_name: str, discount_type: str, discount: float):
    context.execute_steps('''
        given the EPS simulator uses {card_name} card configuration
    '''.format(card_name=card_name))
    if not context.epc_sim.eps.set_card_for_pdl_discounts(card_name, discount, discount_type, tran_type='AUTH'):
        raise ProductError('The needed card NVPs were not set.')


@given('the EPS simulator uses {card_name} card configured to trigger {discount_type} PDL discount with amount {discount:f} for dry stock')
def step_impl(context: Context, card_name: str, discount_type: str, discount: float):
    context.execute_steps('''
        given the EPS simulator uses {card_name} card configuration
    '''.format(card_name=card_name))
    if not context.epc_sim.eps.set_card_for_pdl_discounts(card_name, discount, discount_type, product_code_range='1000-9999'):
        raise ProductError('The needed card NVPs were not set.')


@given('the EPS simulator uses {card_name} card configured to trigger {discount_type} PDL HDD discount with amount {discount:f} and quantity limit {quantity_limit} for {discount_mode}')
def step_impl(context: Context, card_name: str, discount_type: str, discount: float, quantity_limit: int, discount_mode: str):
    context.execute_steps('''
        given the EPS simulator uses {card_name} card configuration
    '''.format(card_name=card_name))
    if not context.epc_sim.eps.set_card_for_single_hdd_pdl_discount(card_name, discount, quantity_limit, discount_type, discount_mode):
        raise ProductError('The needed card NVPs were not set.')


@given('the EPS simulator uses {card_name} card configured to trigger {discount_type} PDL HDD discount with amount {discount:f} for dry stock')
def step_impl(context: Context, card_name: str, discount_type: str, discount: float):
    context.execute_steps('''
        given the EPS simulator uses {card_name} card configuration
    '''.format(card_name=card_name))
    if not context.epc_sim.eps.set_card_for_single_hdd_pdl_discount(card_name, discount, discount_type=discount_type, product_code_range="1000-9999"):
        raise ProductError('The needed card NVPs were not set.')


@given('the EPS simulator uses {card_name} card configured to trigger following PDL HDD discounts')
def step_impl(context: Context, card_name: str):
    context.execute_steps('''
        given the EPS simulator uses {card_name} card configuration
    '''.format(card_name=card_name))

    if not context.epc_sim.eps.set_card_for_hdd_pdl_discounts(card_name, context.table):
        raise ProductError('The needed card NVPs were not set.')


@given('the POS displays Ask tender amount {tender_type} frame')
def step_impl(context: Context, tender_type: str):
    tender_button = context.pos.convert_tender_type_to_button_use(tender_type)
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton(tender_button))
    tender_frame = 'ask-tender-amount-{}'.format(tender_type.lower())
    context.pos.wait_for_frame_open(POSFrame(tender_frame))


@given('the POS displays No balance due frame')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton.TENDER_CASH)
    context.pos.wait_for_frame_open(POSFrame.ASK_FINALIZE_ZERO_TRANSACTION)


@given('the POS displays Partial approval frame')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton.TENDER_CREDIT)
    context.pos.press_button_on_frame(POSFrame.ASK_TENDER_AMOUNT_CREDIT, POSButton.EXACT_DOLLAR)
    context.pos.wait_for_frame_open(POSFrame.ASK_AMOUNT_CONFIRMATION)


@given('the POS displays Amount will be restricted prompt after attempting to tender {amount:f} in {tender} with external id {external_id} and type id {type_id}')
def step_impl(context: Context, amount: float, tender: str, external_id: str, type_id: int):
    context.execute_steps('''
            when the cashier tenders the transaction with {amount:f} in {tender} with external id {external_id} and type id {type_id}
        '''.format(amount=amount, tender=tender, external_id=external_id, type_id=type_id))
    context.pos.wait_for_frame_open(POSFrame.ASK_ACCEPT_AMOUNT_WILL_BE_RESTRICTED)


@given('a {amount:f} {tender_type} partial tender is present in the transaction')
def step_impl(context: Context, amount: float, tender_type:str):
    tender_type = tender_type.lower()
    context.pos.tender_transaction(tender_type=tender_type, amount=amount)
    context.pos.wait_for_frame_open(POSFrame.MAIN)


@given('the cashier pressed Void item button {amount} times')
def step_impl(context: Context, amount: str):
    count = int(amount)
    while count > 0:
        context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.VOID_ITEM)
        count = count - 1


@given('the transaction\'s subtotal is {subtotal:f}')
def step_impl(context: Context, subtotal: float):
    context.execute_steps('''
            Then the transaction\'s subtotal is {subtotal:f}
        '''.format(subtotal=subtotal))


@given('the cashier tendered transaction with credit')
def  step_impl(context: Context):
    context.execute_steps('''
        When the cashier tenders the transaction with hotkey exact_dollar in credit
    ''')


@given('the cashier tendered transaction with cash')
def  step_impl(context: Context):
    context.execute_steps('''
        When the cashier tenders the transaction with hotkey exact_dollar in cash
    ''')


@given('the cashier tendered the transaction with {quick_button} on the current frame')
def step_impl(context: Context, quick_button: str):
    context.execute_steps('''
        when the cashier tenders the transaction with {quick_button} on the current frame
    '''.format(quick_button=quick_button))


@given('the cashier tendered the transaction with {amount:f} amount in {tender_type}')
def step_impl(context: Context, amount: float, tender_type: str):
    context.execute_steps('''
        when the cashier tenders the transaction with amount {amount:f} in {tender_type}
    '''.format(amount=amount, tender_type=tender_type))


@given('the transaction is tendered')
def step_impl(context: Context):
    context.pos.tender_transaction()


@given('the transaction is tendered with {amount:f} in {tender_type}')
def step_impl(context: Context, amount: float, tender_type: str):
    context.pos.tender_transaction(tender_type=tender_type, amount=amount)


@given('a tender {tender_description} with amount {tender_amount:f} is in the {transaction} transaction')
def step_impl(context: Context, tender_description: str, tender_amount: float, transaction: str):
        context.execute_steps("""
            then a tender {tender_description} with amount {tender_amount:f} is in the {transaction} transaction
        """.format(tender_description=tender_description, tender_amount=tender_amount, transaction=transaction))


@given('the authorization amount for credit tender is {amount:f}')
def step_impl(context: Context, amount: float):
    # The amount is set in parameter:
    # <NVP name="noAUTHAMOUNT">XX.XX</NVP>
    # in card XML file:
    # 6.1\POS\Simulators\package\sim4cfrpos\runtime\epc_sim\configuration\cards\card_default.xml
    pass

@given('the cashier started tender the transaction with hotkey {hotkey} in {tender_type}')
def step_impl(context: Context, hotkey: str, tender_type: str):
    context.execute_steps("""
        Given the POS displays Ask tender amount {tender_type} frame
        When the cashier presses {hotkey} button
    """.format(tender_type=tender_type, hotkey=hotkey))

# endregion


# region When clauses
@when('the cashier starts tender the transaction with hotkey {hotkey} in {tender_type}')
def step_impl(context: Context, hotkey: str, tender_type: str):
    context.execute_steps("""
        Given the cashier started tender the transaction with hotkey {hotkey} in {tender_type}
        """.format(hotkey=hotkey, tender_type=tender_type))

@when('the cashier presses {button} button on finalize zero balance transaction prompt')
def step_impl(context: Context, button: str):
    if button.lower() == 'yes':
        button = POSButton.YES
    elif button.lower() == 'no':
        button = POSButton.NO
    else:
        raise ProductError('The button "{}" is not yes or no button.'.format(button))
    context.pos.press_button_on_frame(POSFrame.ASK_FINALIZE_ZERO_TRANSACTION, button)


@when('the cashier presses the {tender_type} tender button')
def step_impl(context: Context, tender_type: str):
    tender_button = context.pos.convert_tender_type_to_button_use(tender_type)
    assert context.pos.navigate_to_tenderbar_button(POSButton(tender_button))
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton(tender_button))


@when('the cashier navigates to the {tender_type} tender button')
def step_impl(context: Context, tender_type: str):
    tender_button = context.pos.convert_tender_type_to_button_use(tender_type)
    context.pos.navigate_to_tenderbar_button(POSButton(tender_button))


@when('the cashier enters {amount:f} dollar amount in Ask tender amount {tender_type} frame')
def step_impl(context: Context, amount: float, tender_type: str):
    tender_frame = 'ask-tender-amount-{}'.format(tender_type.lower())
    context.pos.press_digits(POSFrame(tender_frame), amount)
    context.pos.press_button_on_frame(POSFrame(tender_frame), POSButton.ENTER)


@when('the cashier tenders the transaction with hotkey {hotkey} in {tender_type}')
def step_impl(context: Context, hotkey: str, tender_type: str):
    context.pos.tender_transaction(tender_type=tender_type.lower(), amount=hotkey)


@when('the cashier presses {button} on Partial approval frame')
def step_impl(context: Context, button: str):
    if button.lower() == 'yes':
        button = POSButton.YES
    elif button.lower() == 'no':
        button = POSButton.NO
    else:
        raise ProductError('The button "{}" is not yes or no button.'.format(button))
    context.pos.press_button_on_frame(POSFrame.ASK_AMOUNT_CONFIRMATION, button)


@when('the cashier presses Drive Off button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.DRIVE_OFF)


@when('the cashier presses Pump Test button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.PUMP_TEST)


@when('the EPS sends the card data obtained through swipe-ahead to the POS')
def step_impl(context: Context):
    tran_number = context.pos.get_current_transaction().sequence_number
    context.epc_sim.eps.perform_swipe_ahead(tran_number)


@when('the cashier selects tender group button with id {tender_group_id} on the tenderbar')
def step_impl(context: Context, tender_group_id: str):
    context.pos.select_tender_group_from_tenderbar(tender_group_id)


@when('the cashier tenders the transaction with {quick_button} on the current frame')
def step_impl(context: Context, quick_button: str):
    frame = context.pos.control.get_menu_frame()
    context.pos.control.press_button(frame.instance_id, quick_button)


@when('the cashier tenders the transaction {tender_times:n} times with amount {amount:f} in {tender_type}')
def step_impl(context: Context, amount: float, tender_type: str, tender_times: int):
    tender_type = tender_type.lower()
    count = tender_times
    while count > 0:
        context.pos.tender_transaction(tender_type=tender_type, amount=amount)
        count = count - 1


@when('the cashier presses the {tender_type} tender button on Select refund tender frame')
def step_impl(context: Context, tender_type: str):
    tender_button = context.pos.convert_tender_type_to_button_use(tender_type)
    context.pos.press_button_on_frame(POSFrame.SELECT_REFUND_TENDER, POSButton(tender_button))
# endregion


# region Then clauses
@then('the POS displays Credit processing followed by main menu frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.WAIT_CREDIT_PROCESSING)
    context.pos.wait_for_frame_open(POSFrame.MAIN)


@then('the POS displays No balance due frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_FINALIZE_ZERO_TRANSACTION)


@then('the POS displays Amount will be restricted prompt')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_ACCEPT_AMOUNT_WILL_BE_RESTRICTED)


@then('the POS displays Ask tender amount {tender_type} frame')
def step_impl(context: Context, tender_type: str):
    tender_frame = 'ask-tender-amount-{}'.format(tender_type.lower())
    context.pos.wait_for_frame_open(tender_frame)


@then('the POS displays No amount entered error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_NO_AMOUNT_ENTERED)


@then('the POS displays Partial tender not allowed error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_PARTIAL_TENDER_NOT_ALLOWED)


@then('the POS displays Tender not allowed on non-fuel items error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_TENDER_NOT_ALLOWED_NON_FUEL)


@then('the POS displays Amount too large error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_AMOUNT_TOO_LARGE)


@then('the POS displays Amount too small error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_AMOUNT_TOO_SMALL)


@then('the POS displays Card declined frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.CREDIT_PROCESSING_DECLINED)


@then('the POS displays Partial approval frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_AMOUNT_CONFIRMATION)


@then('the POS displays Partial tender not allowed for pump test')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_PARTIAL_TENDER_NOT_ALLOWED_PUMP_TEST)


@then('the {tender_type} tender button is disabled')
def step_impl(context: Context, tender_type: str):
    tender_button = context.pos.convert_tender_type_to_button_use(tender_type)
    assert not context.pos.navigate_to_tenderbar_button(POSButton(tender_button))


@then('the POS displays a grid of available tenders')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.SELECT_TENDER_FROM_GROUP)


@then('the {tender_name} tender button with external id {external_id} and type id {type_id} is disabled')
def step_impl(context: Context, tender_name: str, external_id: str, type_id: int):
    tender_button = "tender-type-" + str(type_id) + "-" + external_id
    assert not context.pos.navigate_to_tenderbar_button(tender_button)
# endregion
