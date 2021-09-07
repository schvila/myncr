from behave import *
from behave.runner import Context

from sim4cfrpos.api.nepsvcs_sim.nepsvcs_sim_control import PromotionsSim
from cfrpos.core.bdd_utils.pes_utils import HelperFunctions, MessageComparator
import time


# region Given clauses
@given('the ULP simulator has default configuration')
def step_impl(context: Context):
    context.nepsvcs_sim.clear_message_cache(PromotionsSim.ULP)
    context.nepsvcs_sim.clear_discount_cache(PromotionsSim.ULP)
    context.nepsvcs_sim.clear_referenced_promotions_cache(PromotionsSim.ULP)
    context.nepsvcs_sim.clear_receipt_message_cache(PromotionsSim.ULP)
    context.nepsvcs_sim.clear_custom_status_code(PromotionsSim.ULP)
    context.nepsvcs_sim.clear_all_trapped_messages(PromotionsSim.ULP)
    context.nepsvcs_sim.clear_supported_cards_cache(PromotionsSim.ULP)
    context.nepsvcs_sim.configure(PromotionsSim.ULP)


@given('the ULP simulator has following referenced promotions configured')
def step_impl(context: Context):
    promotions = HelperFunctions.prepare_referenced_promotion(context.table.rows)
    context.nepsvcs_sim.set_referenced_promotions(promotions, PromotionsSim.ULP)
    context.nepsvcs_sim.configure(PromotionsSim.ULP)


@given('the POS sends a {action_type} request to ULP after scanning an item with barcode {item_barcode}')
def step_impl(context: Context, action_type: str, item_barcode: str):
    context.nepsvcs_sim.create_traps()
    context.execute_steps('''
        Given an item with barcode {item_barcode} is present in the transaction
    '''.format(item_barcode=item_barcode))
    action = HelperFunctions.convert_action_type(action_type, PromotionsSim.ULP)
    last_captured_massage, context.last_ulp_messages  =  context.ulp_nep_sim.get_message_and_update(action, context.last_ulp_messages)
    assert last_captured_massage, 'The message was not found'

# endregion

# region When clauses
# endregion

# region Then clauses
@then('the POS applies ULP discounts')
def step_impl(context: Context):
    assert context.pos.wait_for_pes_response('get', 'success', 10), 'ULP discounts were not applied'


@then('the POS sends a {action_type} request to ULP with following elements')
def step_impl(context: Context, action_type: str):
    # Use context.table with columns:
    # * 'element',
    # * 'value'
    elements: dict = {}
    for row in context.table.rows:
        elements[row.cells[0]] = row.cells[1]

    action = HelperFunctions.convert_action_type(action_type, PromotionsSim.ULP)
    last_captured_massage = context.ulp_nep_sim.wait_for_message_with_elements(action, MessageComparator.EXACT_MATCH, elements, 2)
    assert last_captured_massage, 'The message was not found'


@then('following fields are presented in the {action_type} ULP request')
def step_impl(context: Context, action_type: str):
    # Use context.table with columns:
    # * 'element'
    elements: dict = {}
    for row in context.table.rows:
        elements[row.cells[0]] = None

    action = HelperFunctions.convert_action_type(action_type, PromotionsSim.ULP)
    message = context.ulp_nep_sim.find_message_with_elements_and_update(action, MessageComparator.ANY_VALUE, context.last_ulp_messages, elements)
    assert message, 'The message was not found'


@then('the POS sends {action_type} request to ULP after last action')
def step_impl(context: Context, action_type: str):
    action_type = HelperFunctions.convert_action_type(action_type, PromotionsSim.ULP)
    last_messages: dict = context.nepsvcs_sim.get_trapped_messages(action_type, PromotionsSim.ULP, 1)
    saved_messages = context.last_ulp_messages
    assert len(last_messages) == 1 or len(last_messages) >= len(saved_messages)


@then('the last {action_type} request sent to ULP has got {count:d} items in element {element}')
def step_impl(context: Context, action_type: str, count: int, element: str):
    action_type = HelperFunctions.convert_action_type(action_type, PromotionsSim.ULP)
    messages = context.nepsvcs_sim.get_trapped_messages(action_type, PromotionsSim.ULP, 1)
    if not messages:
        assert False, f'No {action_type} message was sent.'
    items = messages[-1].get(element, None)
    if items is None or not items:
        assert False, f'Nothing found in element {element} in {action_type} message.'
    assert len(items) == count, f'There was sent more or less than {count} items. Exactly {len(items)} items was sent.'


@then('the POS sends a {action_type} request to ULP without any of the following elements')
def step_impl(context: Context, action_type: str):
    action = HelperFunctions.convert_action_type(action_type, PromotionsSim.ULP)
    for row in context.table.rows:
        elements: dict = {row.cells[0] : 0}
        last_captured_message = context.ulp_nep_sim.wait_for_message_with_elements(action, MessageComparator.EXACT_MATCH, elements, 1.5)
        assert last_captured_message is None, 'The message is found'


@then('the {action_type} request to ULP contains {card_type} card with prefix {card_prefix}')
def step_impl(context: Context, action_type: str, card_type: str, card_prefix: str):
    action_type = HelperFunctions.convert_action_type(action_type, PromotionsSim.ULP)
    time.sleep(0.5)
    messages = context.nepsvcs_sim.get_trapped_messages(action_type, PromotionsSim.ULP, 1)
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


@then('the POS sends no {action_type} requests to ULP after last action')
def step_impl(context: Context, action_type: str):
    action_type = HelperFunctions.convert_action_type(action_type, PromotionsSim.ULP)
    last_messages: dict = context.nepsvcs_sim.get_trapped_messages(action_type, PromotionsSim.ULP, 1)
    saved_messages = context.last_ulp_messages
    assert len(last_messages) == len(saved_messages)
# endregion
