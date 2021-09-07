from behave import *
from behave.runner import Context

from typing import Union
from cfrpos.core.pos.ui_metadata import POSButton


# region Given clauses
@given('a fuel sale for pump {pump:d} is authorized with epsilon number from the prepaid transaction')
def step_impl(context: Context, pump: int):
    transaction = context.pos.get_previous_transaction()
    assert transaction is not None
    epsilon_tran_numbers = transaction.epsilon_tran_numbers
    assert epsilon_tran_numbers is not None and len(epsilon_tran_numbers) > 0
    response = context.fuel_sim.start_outside_sale(pump, epsilon_tran_numbers[0])
    assert response is not None and response['Result'] == 'Success'


@given('an outside sale fuel for price {amount:f} tendered in {tender_type} is present at pump {pump:d}')
def step_impl(context: Context, amount: float, pump: int, tender_type: str):
    context.execute_steps("""
    Given a prepay for pump 1 with a price of {amount1} is tendered in {tender_type} and finalized
    Given a fuel sale for pump {pump} is authorized with epsilon number from the prepaid transaction
    Given the customer dispensed regular for {amount2} price at pump {pump}
    """.format(amount1=2 * amount, pump=pump, amount2=amount, tender_type=tender_type))


@given('a {amount1:f} outside sale fuel authorized for {amount2:f} tendered in {tender_type} is present at pump {pump:d}')
def step_impl(context: Context, amount1: float, amount2: float, pump: int, tender_type: str):
    context.execute_steps("""
    Given a prepay for pump 1 with a price of {amount2} is tendered in {tender_type} and finalized
    Given a fuel sale for pump {pump} is authorized with epsilon number from the prepaid transaction
    Given the customer dispensed regular for {amount1} price at pump {pump}
    """.format(amount1=amount1, pump=pump, amount2=amount2, tender_type=tender_type))


@given('a {amount:f} postpay from outside sale overrun is present at pump {pump:d}')
def step_impl(context: Context, amount: float, pump: int):
    context.execute_steps("""
    Given a {amount1} outside sale fuel authorized for {amount2} tendered in credit is present at pump {pump}
    When the application sends |["Pos/FinalizeOrder", {{"ItemList": [{{"Type": "Fuel", "PumpNumber": 2, "SaleType": "Outside", "SaleId": 1}}]}}]| to the POS Connect
    Then the postpay for {amount3} is present on pump {pump}
    """.format(amount1=amount + 20.00, amount2=20.00, pump=pump, amount3=amount))


@given('an outside sale fuel for {amount:f} authorized with eps tran {eps_tran} is present at pump {pump:d}')
def step_impl(context: Context, amount: float, eps_tran: Union[int, str], pump: int):
    try:
        eps_tran_number = int(eps_tran)
    except ValueError:
        raise Exception("Eps tran number needs to be an integer")
    response = context.fuel_sim.start_outside_sale(pump, eps_tran_number)
    assert response is not None and response['Result'] == 'Success'
    context.execute_steps("""
    Given the customer dispensed regular for {amount} price at pump {pump}
    """.format(amount=amount, pump=pump))


@given('an outside sale fuel for {amount:f} authorized with an already used eps tran is present at pump {pump:d}')
def step_impl(context: Context, amount: float, pump: int):
    request = '["Pos/FinalizeOrder", {{"ItemList": [{{"Type": "Fuel", "PumpNumber": {pump}, "SaleType": "Outside", "SaleId": 1}}]}}]'.format(pump=pump)
    context.execute_steps("""
    Given an outside sale fuel for price {amount:f} tendered in credit is present at pump {pump:d}
    When the application sends |{request}| to the POS Connect
    Then the transaction is finalized
    """.format(amount=amount, pump=pump, request=request))
    transaction = context.pos.get_previous_transaction()
    eps_tran_number = transaction.epsilon_tran_numbers[0]
    response = context.fuel_sim.start_outside_sale(pump, eps_tran_number)
    assert response is not None and response['Result'] == 'Success'
    context.execute_steps("""
    Given the customer dispensed regular for {amount} price at pump {pump}
    """.format(amount=amount, pump=pump))
# endregion


# region When clauses
# endregion


# region Then clauses
@then('the Pay buttons are not enabled')
def step_impl(context: Context):
    menu_frame = context.pos.control.get_menu_frame()
    assert not menu_frame.has_button(POSButton.PAY_FIRST)
    assert not menu_frame.has_button(POSButton.PAY_SECOND)


@then('epsilon sends capture for {amount:f} amount')
def step_impl(context: Context, amount: float):
    transaction = context.pos.get_previous_transaction()
    assert transaction is not None
    epsilon_tran_number = transaction.epsilon_tran_numbers[0]
    nvps = {'mmAMOUNTTENDERED': '{:.2f}'.format(amount), 'smTRANTYPE': 'CAPTURE'}
    assert context.epc_sim.eps.has_tran_nvps(nvps, epsilon_tran_number)
# endregion
