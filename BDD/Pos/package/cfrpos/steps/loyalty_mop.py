from behave import *
from behave.runner import Context

from cfrpos.core.pos.ui_metadata import POSFrame, POSButton


# region Given clauses
@given('the POS displays Ask tender amount cash frame after LoyaltyMOP was applied')
def step_impl(context: Context):
    context.execute_steps(
        """
        when the cashier totals the transaction to receive the RLM loyalty discount
        then the POS displays Ask tender amount cash frame
        """)


@given(u'an item {description} with barcode {barcode} and price {price} is eligible for LMOP discount {discount} when using loyalty card {card}')
def step_impl(context, description: str, barcode: str, price: str, discount: str, card: str):
    assert context.epc_sim.sigma.create_discount_for_card(card, barcode, discount, 'tender', 'cash') != 0


@given('the transaction was tendered with cash after LoyaltyMOP was applied')
def step_impl(context):
    context.execute_steps(
        """
        given the POS displays Ask tender amount cash frame after LoyaltyMOP was applied
        when the cashier presses Exact dollar button
        then the transaction is finalized
        """)
# endregion


# region When clauses
@when('the cashier totals the transaction using cash tender')
def step_impl(context):
    tender_button = context.pos.convert_tender_type_to_button_use('cash')
    assert context.pos.navigate_to_tenderbar_button(POSButton(tender_button))
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton(tender_button))
# endregion


# region Then clauses
@then('a redeemed amount {amount:f} is sent to loyalty host')
def step_impl(context: Context, amount: float):
    sigma_tran = context.epc_sim.sigma.get_all_transactions()[-1]
    assert context.epc_sim.sigma.validate_captured_amount(tender_type_id=16, amount=amount, sigma_tran=sigma_tran)


@then('the POS displays Loyalty points cannot be used to pay for all items frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_LMOP_RESTRICTED)


@then('loyalty {loyalty_msg_type} for amount {amount:f} is sent to loyalty host')
def step_impl(context: Context, loyalty_msg_type:str, amount: float):
    sigma_tran = context.epc_sim.sigma.get_all_transactions()[-1]
    assert context.epc_sim.sigma.validate_captured_amount(tender_type_id=2, amount=amount, sigma_tran=sigma_tran)


@then('loyalty {loyalty_msg_type} for amount {amount:f} is not sent to loyalty host')
def step_impl(context: Context, loyalty_msg_type: str, amount: float):
    sigma_tran = context.epc_sim.sigma.get_all_transactions()[-1]
    assert not context.epc_sim.sigma.validate_captured_amount(tender_type_id=2, amount=amount, sigma_tran=sigma_tran)
# endregion
