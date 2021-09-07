#
# File constains common functions and steps for cloud loyalty - pes.py and loyalty.py
#
from behave import *
from behave.runner import Context
from cfrpos.core.bdd_utils.promotion_utils import HelperFunctions
from sim4cfrpos.api.nepsvcs_sim.nepsvcs_sim_control import PromotionsSim
from cfrpos.core.bdd_utils.poscache_utils import POSCacheUtils, PromptType
from cfrpos.core.pos.ui_metadata import POSFrame, POSButton


# region Given clauses
@given('the POS has the Cloud Loyalty feature enabled')
def step_impl(context: Context):
    context.pos.relay_catalog.enable_feature("loyalty")
    context.pos.relay_catalog.enable_feature("pes")


@given('the Cloud Loyalty configuration on site controller has default configuration')
def step_impl(context: Context):
    # This provides the credential configuration for DirectPesApi
    context.pos.reset_pes_configuration()
    context.pos.create_pes_configuration_file()


@given('the {loyalty_host_name} loyalty host simulator has default configuration')
def step_impl(context: Context, loyalty_host_name: str):
    loyalty_host: PromotionsSim = PromotionsSim.PES
    if loyalty_host_name == 'ULP':
        loyalty_host = PromotionsSim.ULP

    context.nepsvcs_sim.clear_message_cache(loyalty_host)
    context.nepsvcs_sim.clear_discount_cache(loyalty_host)
    context.nepsvcs_sim.clear_receipt_message_cache(loyalty_host)
    context.nepsvcs_sim.clear_custom_status_code(loyalty_host)
    context.nepsvcs_sim.clear_all_trapped_messages(loyalty_host)
    context.nepsvcs_sim.clear_supported_cards_cache(loyalty_host)
    context.nepsvcs_sim.configure(loyalty_host)


@given('the {loyalty_host_name} loyalty host simulator has following combo discounts configured')
def step_impl(context: Context, loyalty_host_name: str):
    loyalty_host: PromotionsSim = PromotionsSim.PES
    if loyalty_host_name == 'ULP':
        loyalty_host = PromotionsSim.ULP

    discounts = HelperFunctions.prepare_discounts(context.table.rows)
    context.nepsvcs_sim.set_discounts(discounts, loyalty_host)
    context.nepsvcs_sim.configure(loyalty_host)


@given('the pinpad displays boolean prompt')
def step_impl(context: Context):
    context.execute_steps('''
        then the pinpad displays boolean prompt
    ''')


@given('the pinpad displays boolean prompt with title {title} and description {description}')
def step_impl(context: Context, title: str, description: str):
    context.execute_steps('''
        then the pinpad displays boolean prompt with title {title} and description {description}
    '''.format(title=title, description=description))


@given('a customer swiped a {loyalty_host_name} loyalty card with number {card_number} on pinpad')
def step_impl(context: Context, loyalty_host_name: str, card_number: str):
    context.execute_steps('''
        When a customer swipes a {loyalty_host_name} loyalty card with number {card_number} on pinpad
    '''.format(loyalty_host_name=loyalty_host_name, card_number=card_number))
    assert context.pos.wait_for_item_added(barcode=card_number)


@given('a {loyalty_host_name} loyalty card with number {card_number} is entered on Last chance loyalty prompt')
def step_impl(context: Context, loyalty_host_name: str, card_number: str):
    context.execute_steps('''
        Given the POS displays Last chance loyalty frame after selecting a cash tender button
        Given a customer swiped a {loyalty_host_name} loyalty card with number {card_number} on pinpad
    '''.format(loyalty_host_name=loyalty_host_name, card_number=card_number))


@given('a {loyalty_host_name} loyalty card {card_number} is present in the transaction')
def step_impl(context: Context, loyalty_host_name: str, card_number: str):
    context.pos.scan_item_barcode(barcode=card_number, barcode_type="UPC_EAN")
    assert context.pos.wait_for_item_added(barcode=card_number)


# endregion

# region When clauses
@when('the cashier scans PES loyalty card {card_number}')
def step_impl(context: Context, card_number: str):
    context.pos.scan_item_barcode(barcode=card_number, barcode_type="UPC_EAN")


@when('the cashier scans ULP loyalty card {card_number}')
def step_impl(context: Context, card_number: str):
    context.pos.scan_item_barcode(barcode=card_number, barcode_type="UPC_EAN")


@when('a customer swipes a {loyalty_host_name} loyalty card with number {card_number} on pinpad')
def step_impl(context: Context, loyalty_host_name: str, card_number: str):
    context.epc_sim.poscache.create_transaction(tran_type="default")
    context.epc_sim.poscache.set_pes_card_data(card_number)
    context.epc_sim.poscache.post_complete_with_message(message_name="PassCardData", post_point="DEFAULT")
    frame = context.pos._control.get_menu_frame()
    if frame.use_description == POSFrame.LAST_CHANCE_LOYALTY.value:
        context.pos._control.wait_for_frame_close(frame)


@when('the cashier swipes a {loyalty_host_name} loyalty card with number {card_number} on the POS')
def step_impl(context: Context, loyalty_host_name: str, card_number: str):
    context.pos.swipe_card_tracks(card_number, card_number)


@when('the cashier manually adds a PES loyalty card with number {card_number} on the POS')
def step_impl(context: Context, card_number: str):
    context.pos.enter_barcode_manually(card_number)


@when('the cashier manually adds a ULP loyalty card with number {card_number} on the POS')
def step_impl(context: Context, card_number: str):
    context.pos.enter_barcode_manually(card_number)

# endregion

# region Then clauses
@then('the pinpad displays boolean prompt')
def step_impl(context: Context):
    data = context.epc_sim.poscache.get_poscache_data()
    result = POSCacheUtils.was_prompt_request_sent(data, PromptType.BOOLEAN)
    assert result, "Boolean prompt was not sent to POSCache"


@then('the pinpad displays boolean prompt with title {title} and description {description}')
def step_impl(context: Context, title: str, description: str):
    data = context.epc_sim.poscache.get_poscache_data()
    result = POSCacheUtils.was_prompt_request_sent(data, PromptType.BOOLEAN, title, description)
    assert result, "Boolean prompt with title {title} and description {description} was not sent to POSCache".format(title=title, description=description)
# endregion