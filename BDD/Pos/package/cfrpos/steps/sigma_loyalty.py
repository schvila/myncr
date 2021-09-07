from behave import *
from behave.runner import Context
from cfrpos.core.pos.ui_metadata import POSFrame, POSButton


# region Given clauses
@given("the Sigma recognizes following cards")
def step_impl(context: Context):
    # Use context.table with columns:
    # * 'card_number',
    # * 'card_description' (optional),
    # * 'is_valid' (optional),
    # * 'track1' (optional),
    # * 'track2' (optional),
    # * 'alt_id' (optional),
    # * 'is_employee_card' (optional)
    for row in context.table:
        card_number = row["card_number"] if "card_number" in row.headings else None
        card_description = row["card_description"] if "card_description" in row.headings else "loyalty card"
        is_valid = row["is_valid"] if "is_valid" in row.headings else True
        track1 = row["track1"] if "track1" in row.headings else ''
        track2 = row["track2"] if "track2" in row.headings else ''
        alt_id = row["alt_id"] if "alt_id" in row.headings else ''

        is_valid = False if is_valid == 0 else True
        is_employee_card = False
        if "is_employee_card" in row.headings:
            if str(row["is_employee_card"]).lower() in ['true', '1', 'yes']:
                is_employee_card = True

        context.epc_sim.sigma.create_loyalty_card(card_number=card_number, description=card_description,
                                                    valid=is_valid, track1=track1, track2=track2, alt_id=alt_id, is_employee_card=is_employee_card)


@given(u'an item {description} with barcode {barcode} and price {price} is eligible for discount {reward_type} {discount} when using loyalty card {card}')
def step_impl(context, description: str, barcode: str, price: str, reward_type: str, discount: str, card: str):
    assert context.epc_sim.sigma.create_discount_for_card(card, barcode, discount, "item", reward_type) != 0


@given(u'a loyalty card {card} with description {description} is present in the transaction')
def step_impl(context, card: str, description: str):
    context.execute_steps(
        '''
        when a customer adds a loyalty card with a number {card_number} on the pinpad
        then a loyalty card {card_description} is added to the transaction
        '''.format(card_number=card, card_description=description))


@given('the Sigma simulator has essential configuration')
def step_impl(context):
    assert context.epc_sim.sigma.reset()


@given('the POS displays Last chance loyalty frame after selecting a {tender} tender button')
def step_impl(context: Context, tender: str):
    context.execute_steps(
        '''when the cashier presses the {tender_type} tender button'''.format(tender_type=tender))
    context.pos.wait_for_frame_open(POSFrame.LAST_CHANCE_LOYALTY)


@given('the cashier returns back from Ask {tender} tender frame')
def step_impl(context: Context, tender: str):
    context.pos.wait_for_frame_open('ask-tender-amount-{}'.format(tender.lower()))
    context.pos.press_goback_on_current_frame()
    context.pos.wait_for_frame_open(POSFrame.MAIN)


@given('the POS returns to main menu frame after selecting continue on Last chance loyalty frame')
def step_impl(context: Context):
    context.execute_steps(
        '''
        Given the POS displays Last chance loyalty frame after selecting a cash tender button
        When the cashier presses Continue button
        Given the cashier returns back from Ask cash tender frame
        ''')


@given('the Sigma option {name} is set to {value}')
def step_impl(context, name: str, value: str):
    assert context.epc_sim.sigma.set_option(name, value)


@given('next Sigma transaction has NVP {name} set to {value}')
def step_impl(context, name: str, value: str):
    assert context.epc_sim.sigma.set_nvp(None, name, value)
# endregion


# region When clauses
@when(u'a customer adds a loyalty card with a number {card_number} on the pinpad')
def step_impl(context, card_number: str):
    context.epc_sim.sigma.swipe_ahead_at_pinpad(card_number)


@when('the cashier totals the transaction to receive the RLM loyalty discount')
def step_impl(context):
    tender_button = context.pos.convert_tender_type_to_button_use('cash')
    assert context.pos.navigate_to_tenderbar_button(POSButton(tender_button))
    item_count = context.pos.get_transaction_item_count()
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton(tender_button))
    context.pos.wait_for_transaction_item_count_increase(item_count)


@when('the cashier swipes a Sigma loyalty card {card_name} on the POS')
def step_impl(context: Context, card_name: str):
    context.pos.swipe_card(card_name)


@when('the cashier scans Sigma loyalty card {card_number}')
def step_impl(context: Context, card_number: str):
    context.execute_steps(f'''
        When the cashier scans a barcode {card_number}
    ''')


@when('the cashier manually adds a Sigma loyalty card with number {card_number} on the POS')
def step_impl(context: Context, card_number: str):
    context.execute_steps(f'''
        When the cashier manually adds an item with barcode {card_number} on the POS
    ''')


@when('the cashier presses Continue button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.LAST_CHANCE_LOYALTY, POSButton.CONTINUE)
# endregion


# region Then clauses
@then(u'a RLM discount {discount_name} with value of {discount_value} is in the virtual receipt')
def step_impl(context, discount_name: str, discount_value: int):
    assert context.pos.wait_for_item_added_to_VR(discount_name, discount_value), 'Loyalty discount not found in VR'


@then(u'a RLM discount {discount_name} with value of {discount_value} is in the {transaction} transaction')
def step_impl(context, discount_name: str, discount_value: int, transaction: str):
    assert context.pos.wait_for_item_added(description=discount_name, price=discount_value, item_type=29, transaction=transaction), 'Loyalty discount not found in transaction'


@then(u'the Sigma {action} receive request of type {transaction_type} from POS')
def step_impl(context, action: str, transaction_type: str):
    assert action == 'does' or action == 'does not', 'Unsupported action: [{}]'.format(action)

    request = context.epc_sim.sigma.get_request(transaction_type)
    if action == 'does':
        assert request.get('Type') == transaction_type, "Sigma did not receive [{}] from POS".format(transaction_type)
    elif action == 'does not':
        assert request.get('Type') is None, "Sigma received [{}] from POS".format(transaction_type)


@then(u'the Sigma does not receive transactions from POS')
def step_impl(context):
    trans = context.epc_sim.sigma.get_all_transactions()
    assert len(trans) == 0, "Sigma receives transactions from POS"


@then('the POS displays Last chance loyalty frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.LAST_CHANCE_LOYALTY)


@then('the Sigma option {name} is set to {value}')
def step_impl(context, name: str, value: str):
    option_value = context.epc_sim.sigma.get_option(name)
    assert option_value == value, "Unexpected Sigma Option [{}] value: [{}]!=[{}]".format(name, option_value, value)


@then('the POS displays Additional loyalty cards not allowed error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_ADDITIONAL_LOYALTY_NOT_ALLOWED)


@then('the Sigma request data contains {data_json}')
def step_impl(context, name: str, value: str):
    expected_data = json.loads(data_json)
    relax_dict_subset(expected_data)
    last_response = context.epc_sim.sigma.get_request(200000001)
    not_found = contains_dict_subset(expected_data, last_response.data)
    assert not_found == {}, 'Not found key-values "{}" in a response {}'.format(not_found, last_response)
# endregion
