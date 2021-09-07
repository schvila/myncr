from behave import *
from behave.runner import Context

import time
from jsonschema import validate
from cfrpos.core.bdd_utils.bdd_environment import table_to_str
from cfrpos.core.bdd_utils.pes_utils import MessageComparator, HelperFunctions
from cfrpos.core.bdd_utils.poscache_utils import POSCacheUtils
from cfrpos.steps.pes_schemas import schema
from cfrpos.core.pos.ui_metadata import POSFrame, POSButton
from sim4cfrpos.api.nepsvcs_sim.nepsvcs_sim_control import PromotionsSim


# region Given clauses
@given('the POS is configured to communicate with PES')
def step_impl(context: Context):
    context.pos.reset_pes_configuration()
    context.pos.create_pes_configuration_file()
    context.pos.relay_catalog.enable_feature("loyalty")
    context.pos.relay_catalog.enable_feature("pes")


@given('the PES configuration file does not exist')
def step_impl(context: Context):
    context.pos.delete_pes_configuration_file()


@given('the nep-server has default configuration')
def step_impl(context: Context):
    context.execute_steps(
        '''
        given the PES loyalty host simulator has default configuration
        given the ULP loyalty host simulator has default configuration
        '''
    )


@given('the POS recognizes following PES cards')
def step_impl(context: Context):
    context.execute_steps("""given the POS recognizes following cards
    {table}""".format(table=table_to_str(context.table)))
    context.pos.create_radgcm_reg_entry_for_pes()


@given('the nep-server provides a discount with value of {discount:f} for transactions with value over {threshold:f}')
def step_impl(context: Context, discount: float, threshold: float):
    discounts = []
    discounts.append({'discount': discount, 'type': 'transactionOverLimit', 'limit': float(threshold), 'promotion_id': 'over_limit',
            'reward_approval': None, 'unit_type': 'SIMPLE_QUANTITY', 'reward_limit': 0, 'is_apply_as_tender': False, 'receipt_text': None})

    context.nepsvcs_sim.set_discounts(discounts, PromotionsSim.PES)
    context.nepsvcs_sim.configure(PromotionsSim.PES)


@given('the PES has {delay:d} seconds delay')
def step_impl(context: Context, delay: int):
    context.nepsvcs_sim.create_delay_trap(None, float(delay), PromotionsSim.PES)


@given('the PES has {delay:d} seconds delay for {action_type} request')
def step_impl(context: Context, delay: int, action_type: str):
    action_type = HelperFunctions.convert_action_type(action_type, PromotionsSim.PES)
    context.nepsvcs_sim.create_delay_trap(action_type, float(delay), PromotionsSim.PES)


@given('the nep-server has following receipt message configured for {action_type} request')
def step_impl(context: Context, action_type: str):
    # Use context.table with columns:
    # * 'content',
    # * 'type',
    # * 'location',
    # * 'alignment'
    # * 'formats'
    # * 'line_break'
    action_type = HelperFunctions.convert_action_type(action_type, PromotionsSim.PES)
    lines = []
    sort_id = 0
    for row in context.table.rows:
        content = row.cells[0]
        type = row.cells[1]
        location = row.cells[2]
        alignment = row.cells[3]
        formats = [x.strip() for x in row.cells[4].split(',')]
        line_break = row.cells[5]
        lines.append({
            'content': content,
            'attributes': {
                'location': location,
                'type': type,
                'sortId': sort_id,
                'contentType': 'GENERAL_RECEIPT_MESSAGE',
                'alignment': alignment,
                'formats': formats,
                'lineBreak': line_break
            }
        })
        sort_id += 1

    context.nepsvcs_sim.add_receipt_message(action_type, {'lines': lines, 'locale': 'en-GB'}, PromotionsSim.PES)
    context.nepsvcs_sim.configure(PromotionsSim.PES)


@given('the nep-server is offline')
def step_impl(context: Context):
    context.nepsvcs_sim.set_custom_status_code(404, PromotionsSim.PES)


@given('the nep-server is online')
def step_impl(context: Context):
    context.nepsvcs_sim.clear_custom_status_code(PromotionsSim.PES)


@given('the nep-server is online after {sec:d} seconds')
def step_impl(context: Context, sec: int):
    time.sleep(sec)
    # Clear the trapped messages, since we are interested in any new ones
    context.nepsvcs_sim.clear_custom_status_code(clear_trapped_messages=True, promotions_sim=PromotionsSim.PES)


@given('the transaction with a barcode {barcode} is finalized while the PES server is offline')
def step_impl(context: Context, barcode: str):
    context.execute_steps('''
        given an item with barcode {barcode} is present in the transaction
        given the nep-server is offline
        given the transaction is finalized
    '''.format(barcode=barcode))


@given('the POS displays a PES discount approval frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_CONFIRM_PES_DISCOUNT)


@given('the POS displays a PES discount approval frame after scanning a barcode {barcode}')
def step_impl(context: Context, barcode: str):
    context.execute_steps('''
        when the cashier scans a barcode {barcode}
    '''.format(barcode=barcode))
    context.pos.wait_for_frame_open(POSFrame.ASK_CONFIRM_PES_DISCOUNT)


@given('the POS displays a PES discount approval frame after selecting a {tender} tender button')
def step_impl(context: Context, tender: str):
    context.execute_steps('''
        when the cashier presses the {tender_type} tender button
    '''.format(tender_type=tender))
    context.pos.wait_for_frame_open(POSFrame.ASK_CONFIRM_PES_DISCOUNT)


@given('the POS displays a Wait for customer confirmation frame after scanning a barcode {barcode}')
def step_impl(context: Context, barcode: str):
    context.execute_steps('''
        when the cashier scans a barcode {barcode}
    '''.format(barcode=barcode))
    context.pos.wait_for_frame_open(POSFrame.WAIT_CUSTOMER_CONFIRMATION)


@given('the POS displays a Wait for customer confirmation frame after selecting a {tender} tender button')
def step_impl(context: Context, tender: str):
    context.execute_steps('''
        when the cashier presses the {tender_type} tender button
    '''.format(tender_type=tender))
    context.pos.wait_for_frame_open(POSFrame.WAIT_CUSTOMER_CONFIRMATION)


@given('the PES configuration on site controller has following values')
def step_impl(context: Context):
    # Use context.table with columns:
    # * 'parameter',
    # * 'value'
    configuration = {row.cells[0]:row.cells[1] for row in context.table.rows}

    context.pos.set_pes_configuration(configuration)

@given('the pricebook contains PES loyalty tender')
def step_impl(context: Context):
    context.pos.relay_catalog.create_tender(tender_id=999, description='PES_tender', tender_type_id=16,
        exchange_rate=1, currency_symbol='$', external_id=999, tender_mode=4096, tender_mode_2=1, create_buttons=False,
        device_control=524288, required_security=1048576)
    context.pos.relay_catalog.create_tender_type(tender_type_id=16, description='Loyalty Points', tender_ranking=1, tier_number=2)


@given('the pricebook contains PES loyalty tender allowed to exceed total amount')
def step_impl(context: Context):
    context.pos.relay_catalog.create_tender(tender_id=999, description='PES_tender', tender_type_id=16,
        exchange_rate=1, currency_symbol='$', external_id=999, tender_mode=0, tender_mode_2=1, create_buttons=False,
        device_control=524288, required_security=1048576)
    context.pos.relay_catalog.create_tender_type(tender_type_id=16, description='Loyalty Points', tender_ranking=1, tier_number=2)


@given('the pricebook contains PES loyalty tender with restriction level {restriction_level}')
def step_impl(context: Context, restriction_level: int):
    context.pos.relay_catalog.create_tender(tender_id=999, description='PES_tender', tender_type_id=16,
        exchange_rate=1, currency_symbol='$', external_id=999, tender_mode=0, tender_mode_2=1, create_buttons=False,
        device_control=524288, required_security=1048576)
    context.pos.relay_catalog.create_tender_type(tender_type_id=16, description='Loyalty Points', tender_ranking=restriction_level, tier_number=2)


@given('the POS displays Alternate ID frame')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.ALTERNATE_ID_LOYALTY)
    context.pos.wait_for_frame_open(POSFrame.ASK_ALTERNATE_ID)


@given('all fuel items are not discountable')
def step_impl(context: Context):
    context.pos.relay_catalog.set_discount_itemizer_mask(item_ids=[5070000019, 5070000020, 5070000021, 5070000022], discount_itemizer_mask=0)


@given('all fuel items are discountable')
def step_impl(context: Context):
    context.pos.relay_catalog.set_discount_itemizer_mask(item_ids=[5070000019, 5070000020, 5070000021, 5070000022], discount_itemizer_mask=4)


@given('the transaction is finalized')
def step_impl(context: Context):
    context.pos.tender_transaction()
    pes_frame = context.pos._control.get_menu_frame()
    if pes_frame.use_description == POSFrame.WAIT_PES_PROCESSING.value:
        timeout = 10.0
        assert context.pos._control.wait_for_frame_close(pes_frame, timeout), "The transaction is not finalized in {} secs".format(timeout)


@given('the POS sends a {action_type} request to PES after scanning an item with barcode {item_barcode}')
def step_impl(context: Context, action_type: str, item_barcode: str):
    context.nepsvcs_sim.create_traps()
    context.execute_steps('''
        Given an item with barcode {item_barcode} is present in the transaction
    '''.format(item_barcode=item_barcode))
    action = HelperFunctions.convert_action_type(action_type, PromotionsSim.PES)
    last_captured_massage, context.last_pes_messages  =  context.pes_nep_sim.get_message_and_update(action, context.last_pes_messages)
    assert last_captured_massage, 'The message was not found'


@given('a loyalty discount {discount} with value of {value:f} is present in the transaction after subtotal')
def step_impl(context: Context, discount: str, value: float):
    context.execute_steps('''
        Given the POS displays Ask tender amount cash frame
    ''')
    assert context.pos.wait_for_item_added(description=discount, price=-value, item_type=29)
    context.pos.press_goback_on_current_frame()


@given('a loyalty tender {loyalty_tender} with value of {value:f} is present in the transaction after subtotal')
def step_impl(context: Context, loyalty_tender: str, value: float):
    context.execute_steps('''
        Given the POS displays Ask tender amount cash frame
    ''')
    assert context.pos.wait_for_item_added(description=loyalty_tender, price=-value, item_type=6)
    context.pos.press_goback_on_current_frame()


@given('the nep-server has following cards configured')
def step_impl(context: Context):
    cards = []
    for row in context.table.rows:
        card = {}
        card['cardNumber'] = row.get('card_number')
        card['promptMessage'] = row.get('prompt_message')
        card['promptType'] = row.get('prompt_type')
        card['notificationFor'] = row.get('notification_for', 'CASHIER_AND_CONSUMER')
        card['maskInput'] = row.get('mask_input', 'True')
        card['minPinLength'] = int(row.get('min_pin_length', 4))
        card['maxPinLength'] = int(row.get('max_pin_length', 6))
        timeout_data = {}
        timeout_data['timeUnit'] = row.get('time_unit', 'SECONDS')
        timeout_data['timeout'] = int(row.get('timeout', 0))
        card['timeoutData'] = timeout_data
        cards.append(card)
    context.nepsvcs_sim.add_supported_cards(cards, PromotionsSim.PES)
    context.nepsvcs_sim.configure(PromotionsSim.PES)


@given('a manually added card {card_name} with number {card_number} is present in the transaction')
def step_impl(context: Context, card_name: str, card_number: str):
    context.execute_steps('''
        when the cashier manually adds a PES loyalty card with number {card_number} on the POS
        then a card {card_name} with value of 0.00 is in the current transaction
    '''.format(card_number=card_number, card_name=card_name))


@given('PES discount approval frame is displayed after POS sends card {card_name} with number {card_number} to PES')
def step_impl(context: Context, card_name: str, card_number: str):
    context.execute_steps('''
        given a manually added card {card_name} with number {card_number} is present in the transaction
        when the cashier presses the cash tender button
        then the POS sends a card with number {card_number} to PES with manual entry method
        and the POS displays a PES discount approval frame
    '''.format(card_name=card_name, card_number=card_number))


@given('the customer performed PAP transaction on pump {pump_number:n} for amount {amount:f} with PES discount applied as tender')
def step_impl(context: Context, pump_number: int, amount: float):
    context.sc.reset_tran_repository()
    context.sc.inject_transaction(pump_number=pump_number, credit_amount=0.00, discount_amount=amount, pap=True, pes=True)


@given('the customer performed PAP transaction on pump {pump_number:n} for amount {total_amount:f} partially tendered with PES discount for value {pes_amount:f}')
def step_impl(context: Context, pump_number: int, total_amount: float, pes_amount: float):
    context.sc.reset_tran_repository()
    context.sc.inject_transaction(pump_number=pump_number, credit_amount=total_amount-pes_amount, discount_amount=pes_amount, pap=True, pes=True)


@given('the PES receives {action_type} request within {sec:d} seconds')
def step_impl(context: Context, action_type: str, sec: int):
    action_type = HelperFunctions.convert_action_type(action_type, PromotionsSim.PES)
    messages: dict = context.nepsvcs_sim.get_trapped_messages(action_type, PromotionsSim.PES, sec)
    assert messages, f'No {action_type} request was sent.'


@given('the POS displays enter loyalty PIN frame after manually entering card {card_name} with a number {card_number}')
def step_impl(context: Context, card_name: str, card_number: str):
        context.execute_steps('''
        given PES discount approval frame is displayed after POS sends card {card_name} with number {card_number} to PES
        when the cashier selects yes button
        then the POS displays enter loyalty PIN frame
        '''.format(card_name=card_name, card_number=card_number))


@given('a transaction with {item_name} was tendered by loyalty points on POS 2')
def step_impl(context: Context, item_name: str):
    context.sc.reset_tran_repository()
    context.sc.inject_transaction(tran_xml='pes_dry_stock_transaction.xml')


@given('the POS processes the {action_type} response')
def step_impl(context: Context, action_type: str):
        context.execute_steps('''
        when the POS processes the {action_type} response
        '''.format(action_type=action_type))


@given('the POS displays the STM_PES_LOYALTY_OFFLINE_ALERT alert after totaling the transaction')
def step_impl(context: Context):
    context.execute_steps("""
        given the transaction is totaled
        then the POS displays the STM_PES_LOYALTY_OFFLINE_ALERT alert""")
# endregion

# region When clauses
@when(u'the nep-server becomes online')
def step_impl(context: Context):
    context.nepsvcs_sim.clear_custom_status_code(PromotionsSim.PES)


@when('the cashier overrides price of item {item_name} to {new_price:f}')
def step_impl(context: Context, item_name: str, new_price: float):
    context.pos.select_item_in_virtual_receipt(item_name)
    context.pos.press_button_on_frame(POSFrame.RECEIPT, POSButton.PRICE_OVERRIDE)
    context.pos.press_digits(POSFrame.PRICE_OVERRIDE_FRAME, new_price)
    context.pos.press_button_on_frame(POSFrame.PRICE_OVERRIDE_FRAME, POSButton.ENTER)
    context.pos.wait_for_frame_open(POSFrame.ASK_FOR_A_REASON)
    context.pos.select_item_in_list(POSFrame.ASK_FOR_A_REASON, item_position=0)


@when('the cashier enters {alternate_id:d} alternate id')
def step_impl(context: Context, alternate_id: int):
    context.pos.press_digits(POSFrame.ASK_ALTERNATE_ID, alternate_id)
    context.pos.press_button_on_frame(POSFrame.ASK_ALTERNATE_ID, POSButton.ENTER)


@when('the cashier enters loyalty PIN {pin} on POS')
def step_impl(context: Context, pin: str):
    context.pos.press_digits(POSFrame.ASK_ENTER_LOYALTY_PIN, pin)
    context.pos.press_button_on_frame(POSFrame.ASK_ENTER_LOYALTY_PIN, POSButton.ENTER)


@when('a customer enters loyalty PIN {pin} on pinpad')
def step_impl(context: Context, pin: str):
    context.epc_sim.poscache.post_complete_numeric(pin)


@when('a customer cancels the numeric prompt on pinpad')
def step_impl(context: Context):
    context.epc_sim.poscache.cancel_numeric_prompt()


@when('a customer cancels the boolean prompt on pinpad')
def step_impl(context: Context):
    context.epc_sim.poscache.cancel_bool_prompt()


@when('the POS processes the {action_type} response')
def step_impl(context: Context, action_type: str):
    action_type = HelperFunctions.convert_action_type(action_type, PromotionsSim.PES)
    assert context.pos.wait_for_pes_response(action_type, 'success', 10), 'PES discounts were not applied'
# endregion

# region Then clauses
@then('the POS does not send an item with name {item_name} to PES')
def step_impl(context: Context, item_name: str):
    elements = {
        'items[-1].itemName' : item_name
    }
    message = context.pes_nep_sim.find_message_with_elements('get', MessageComparator.EXACT_MATCH, elements)
    assert not message, 'The message was found'


@then('the POS sends a {action_type} request to PES with following elements')
def step_impl(context: Context, action_type: str):
    # Use context.table with columns:
    # * 'element',
    # * 'value'
    elements: dict = {}
    for row in context.table.rows:
        elements[row.cells[0]] = row.cells[1]

    action = HelperFunctions.convert_action_type(action_type, PromotionsSim.PES)
    last_captured_massage = context.pes_nep_sim.wait_for_message_with_elements(action, MessageComparator.EXACT_MATCH, elements, 2)
    assert last_captured_massage, 'The message was not found'


@then('the POS sends a {action_type} request to PES without any of the following elements')
def step_impl(context: Context, action_type: str):
    action = HelperFunctions.convert_action_type(action_type, PromotionsSim.PES)
    for row in context.table.rows:
        elements: dict = {row.cells[0] : 0}
        last_captured_message = context.pes_nep_sim.wait_for_message_with_elements(action, MessageComparator.EXACT_MATCH, elements, 1.5)
        assert last_captured_message is None, 'The message is found'



@then('the POS sends a {action_type} request to PES containing items with following values in element {element}')
def step_impl(context: Context, action_type: str, element: str):
    # This step only can validate items[] in request and only tested behavior is with itemNames (getting strings).
    # Use context.table with columns:
    # * 'value'
    item_values_reference = []
    for row in context.table.rows:
        item_values_reference.append(row.cells[0])

    action_type = HelperFunctions.convert_action_type(action_type, PromotionsSim.PES)

    messages = context.nepsvcs_sim.get_trapped_messages(action_type, PromotionsSim.PES, 1)
    if not messages:
        assert False, f'No {action_type} message was sent.'
    items = messages[-1].get('items', None)
    if items is None or not items:
        assert False, f'No items were sent in the {action_type} message.'

    item_values_contained = []
    for item in items:
        item_values_contained.append(item.get(element))

    item_values_reference.sort()
    item_values_contained.sort()
    if item_values_reference != item_values_contained:
        assert False, f'Item names does not match. Expected: {item_values_reference}, found: {item_values_contained}'


@then('the last {action_type} request sent to PES has got {count:d} items in element {element}')
def step_impl(context: Context, action_type: str, count: int, element: str):
    action_type = HelperFunctions.convert_action_type(action_type, PromotionsSim.PES)
    messages = context.nepsvcs_sim.get_trapped_messages(action_type, PromotionsSim.PES, 1)
    if not messages:
        assert False, f'No {action_type} message was sent.'
    items = messages[-1].get(element, None)
    if items is None or not items:
        assert False, f'Nothing found in element {element} in {action_type} message.'
    assert len(items) == count, f'There was sent more or less than {count} items. Exactly {len(items)} items was sent.'


@then('following fields are presented in the {action_type} PES request')
def step_impl(context: Context, action_type: str):
    # Use context.table with columns:
    # * 'element'
    elements: dict = {}
    for row in context.table.rows:
        elements[row.cells[0]] = None

    action = HelperFunctions.convert_action_type(action_type, PromotionsSim.PES)
    message = context.pes_nep_sim.find_message_with_elements_and_update(action, MessageComparator.ANY_VALUE, context.last_pes_messages, elements)
    assert message, 'The message was not found'


@then('the POS sends a card with number {barcode} to PES')
def step_impl(context: Context, barcode: str):
    elements = {
        'consumerIds[0].identifier' : barcode
    }
    message = context.pes_nep_sim.find_message_with_elements('get', MessageComparator.EXACT_MATCH, elements)
    assert message, 'The message was not found'


@then('the POS sends a card with number {barcode} to PES with {method} entry method')
def step_impl(context: Context, barcode: str, method: str):
    elements = {
        'consumerIds[0].identifier' : barcode,
        'consumerIds[0].entryMethod' : method.upper()
    }
    message = context.pes_nep_sim.wait_for_message_with_elements('get', MessageComparator.EXACT_MATCH, elements, 1)
    assert message, 'The message was not found'


@then('the POS applies PES discounts')
def step_impl(context: Context):
    assert context.pos.wait_for_pes_response('get', 'success', 10), 'PES discounts were not applied'


@then('the POS sends no {action_type} requests after last action')
def step_impl(context: Context, action_type: str):
    action_type = HelperFunctions.convert_action_type(action_type, PromotionsSim.PES)
    last_messages: dict = context.nepsvcs_sim.get_trapped_messages(action_type, PromotionsSim.PES, 1)
    saved_messages = context.last_pes_messages
    assert len(last_messages) == len(saved_messages)


@then('the POS does not send any requests after last action')
def step_impl(context: Context):
    context.execute_steps('''
        then the POS sends no GetPromotions requests after last action
        then the POS sends no VoidPromotions requests after last action
        then the POS sends no FinalizePromotions requests after last action
    ''')


@then('the POS sends {action_type} request to PES after last action')
def step_impl(context: Context, action_type: str):
    action_type = HelperFunctions.convert_action_type(action_type, PromotionsSim.PES)
    last_messages: dict = context.nepsvcs_sim.get_trapped_messages(action_type, PromotionsSim.PES, 1)
    saved_messages = context.last_pes_messages
    assert len(last_messages) == 1 or len(last_messages) >= len(saved_messages)


@then('the POS displays a PES discount approval frame')
def step_impl(context: Context):
    context.execute_steps('''
        Given the POS displays a PES discount approval frame
    ''')


@then('the POS displays enter loyalty PIN frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_ENTER_LOYALTY_PIN)


@then('enter loyalty PIN frame is closed')
def step_impl(context: Context):
    pes_frame = context.pos._control.get_menu_frame()
    if pes_frame.use_description == POSFrame.ASK_ENTER_LOYALTY_PIN.value:
        timeout = 10.0
        assert context.pos._control.wait_for_frame_close(pes_frame, timeout), "The transaction is not finalized in {} secs".format(timeout)


@then('the POS displays a PES discount approval frame with title {title} and description {description}')
def step_impl(context: Context, title: str, description: str):
    title = title.strip('\"').strip("\'")
    description = description.strip('\"').strip("\'")
    context.pos.wait_for_frame_open(POSFrame.ASK_CONFIRM_PES_DISCOUNT)
    frame = context.pos.control.get_menu_frame()
    assert frame.use_details.get('title', '') == title, f"The title is {frame.use_details.get('title')}"
    assert frame.use_details.get('description', '') == description, f"The description is {frame.use_details.get('description')}"


@then('the POS displays Wait for customer confirmation frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.WAIT_CUSTOMER_CONFIRMATION)


@then('the PES configuration file is created within {seconds:d}s')
def step_impl(context: Context, seconds: int):
    time.sleep(seconds)
    assert context.pos.pes_configuration_file_exists(), ' the configuration file does not exist'


@then('the PES configuration file contains following values after {seconds:d}s')
def step_impl(context: Context, seconds: int):
    # Use context.table with columns:
    # * 'parameter',
    # * 'value'
    configuration = {row.cells[0]:row.cells[1] for row in context.table.rows}

    time.sleep(seconds)
    context.pos.pes_configuration_file_contains(configuration)


@then('following fields are not present in the {action_type} request')
def step_impl(context: Context, action_type: str):
    # Use context.table with columns:
    # * 'element'
    elements: dict = {}
    for row in context.table.rows:
        elements[row.cells[0]] = None

    action = HelperFunctions.convert_action_type(action_type, PromotionsSim.PES)
    last_captured_massage, context.last_pes_messages =  context.pes_nep_sim.find_message_with_elements_and_update(action, MessageComparator.ANY_VALUE, context.last_pes_messages, elements)
    assert not last_captured_massage, 'The message was found'


@then('the POS displays Balance Inquiry frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_OTHER)


@then('reward limit is set to {reward_limit:d} at pump {pump_id:d}')
def step_impl(context: Context, reward_limit: int, pump_id: int):
    assert context.fuel_sim.validate_pump_max_volume(pump_id, reward_limit), 'Unexpected reward limit'


@then('all fuel products have discountable flag set to {value} in the last {action_type} request')
def step_impl(context: Context, value: str, action_type: str):
    action = HelperFunctions.convert_action_type(action_type, PromotionsSim.PES)
    last_captured_massage, context.last_pes_messages = context.pes_nep_sim.get_message_and_update(action, context.last_pes_messages)
    assert last_captured_massage, 'The message was not found'

    for item in last_captured_massage.get("items", None):
        if item.get("quantity") and item["quantity"].get("unitType", None) == "GALLON_US_LIQUID":
            assert str(item.get("discountable", None)) == value, "item.discountable: {0} != {1}".format(str(item.get("discountable", None)), value)


@then('a loyalty transaction is received on PES')
def step_impl(context: Context):
    trapped_messages: dict = context.nepsvcs_sim.get_trapped_messages('get', PromotionsSim.PES, 1)
    assert len(trapped_messages) > 0


@then('no transaction is received on PES')
def step_impl(context: Context):
    trapped_messages: dict = context.nepsvcs_sim.get_trapped_messages('get', PromotionsSim.PES, 1)
    assert not len(trapped_messages) > 0


@then('the {action_type} request contains {card_type} card with prefix {card_prefix}')
def step_impl(context: Context, action_type: str, card_type: str, card_prefix: str):
    action_type = HelperFunctions.convert_action_type(action_type, PromotionsSim.PES)
    time.sleep(0.5)
    messages = context.nepsvcs_sim.get_trapped_messages(action_type, PromotionsSim.PES, 1)
    assert messages, f'No {action_type} message was sent.'
    tenders = messages[-1].get('tenders', [])
    assert tenders, 'Message got no tender details.'

    tender = tenders[0]
    assert tender.get('tenderType', '') == 'CREDIT_DEBIT', 'Key tenderType is not CREDIT_DEBIT'
    if tender.get('tenderSubType', '') == 'OTHER':
        assert tender.get('otherSubTenderType', '') == card_type, f'Key otherSubTenderType is not {card_type}'
    else:
        assert tender.get('tenderSubType', '') == card_type, f'Key tenderSubType is not {card_type}'
        assert not tender.get('otherSubTenderType', None), 'Key otherSubTenderType is forbidden for given card'
    card_number_trimmed = card_prefix[0:6]
    assert tender.get('issuerIDNumber', '') == card_number_trimmed, f'Key issuerIDNumber is not {card_number_trimmed}'


@then('the pinpad was notified that a PES card was added to the transaction')
def step_impl(context: Context):
    data = context.epc_sim.poscache.get_poscache_data()
    result = POSCacheUtils.was_loyalty_card_added(data)
    assert result, "POSCache was not informed about PES loyalty card"


@then('the pinpad displays {message} message')
def step_impl(context: Context, message: str):
    data = context.epc_sim.poscache.get_poscache_data()
    result = POSCacheUtils.was_message_displayed(data, message)
    assert result, "POSCache was not informed about the {} message".format(message)


@then('the PES response is sent to pump {pump_id:d}')
def step_impl(context: Context, pump_id: int):
    response = context.fuel_sim.get_stored_ext_data(pump_id, 'PES_SYNC_FINALIZE')
    assert HelperFunctions.check_pumps_ext_data(response), 'Error, data were not transferred.'


@then('the PES card {card_number} is stored at pump {pump_id:d}')
def step_impl(context: Context, card_number: str, pump_id: int):
    response = context.fuel_sim.get_stored_ext_data(pump_id, 'Pes.CustomerIds')
    assert HelperFunctions.check_pumps_user_ids(response, card_number), 'Error, ID is not stored.'


@then('the POS displays Too few characters error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_TOO_FEW_CHARS)


@then('the POS processes the {action_type} response')
def step_impl(context: Context, action_type: str):
        context.execute_steps('''
        when the POS processes the {action_type} response
        '''.format(action_type=action_type))
# endregion
