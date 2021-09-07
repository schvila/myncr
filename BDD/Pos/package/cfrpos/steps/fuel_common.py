from core.bdd_utils.timeouter import timeouter
import math
import time
from behave import *
from behave.runner import Context
from cfrpos.core.pos.ui_metadata import POSButton, POSFrame
from sim4cfrpos.api.fcs_sim.fuel_control import FuelPumpStates

# region Given clauses (configuration)
@given('the POS has following pumps configured')
def step_impl(context: Context):
    fueling_points = {}
    for row in context.table:
        fueling_point_id = row["fueling_point"]
        hoses = fueling_points.get(fueling_point_id, [])
        hose = {}
        hose["hose_number"] = row["hose_number"] if "hose_number" in row.headings else 1
        hose["product_number"] = row["product_number"] if "product_number" in row.headings else 70000019
        hose["unit_price"] = row["unit_price"] if "unit_price" in row.headings else 1000
        hoses.append(hose)
        fueling_points[fueling_point_id] = hoses

    for fueling_point_id, hoses in fueling_points.items():
        context.pos.relay_catalog.create_pump_with_hoses(fueling_point=fueling_point_id, hoses=hoses)


@given('the POS has {amount} pumps configured')
def step_impl(context: Context, amount: int):
    for pump_number in range(int(amount)+1):
        if not context.pos.relay_catalog.fuel_dispenser_relay.is_pump_configured(pump_number):
            context.pos.relay_catalog.create_pump(fueling_point=pump_number)


@given('the POS has FPR discount configured')
def step_impl(context: Context):
    for row in context.table:
        context.pos.relay_catalog.create_reduction(row["description"], row["reduction_value"], row["disc_type"], row["disc_mode"], row["disc_quantity"], reduces_tax=True)
        reduction_id = context.pos.relay_catalog.reduction_relay.get_reduction_id(row["description"])
        context.pos.relay_catalog.set_fuel_grades_for_fpr(reduction_id=reduction_id)
        context.pos.relay_catalog.set_relay_records_for_fpr(description=row["description"], reduction_id=reduction_id)


@given('the customer dispensed {grade} for {price:f} price at pump {pump_id:d}')
def step_impl(context: Context, grade: str, price:float, pump_id: int):
    hose_id = context.fuel_sim.get_hose_id(pump_id, grade)
    assert hose_id != -1, f"The hose with grade {grade} was not found on the given pump with id {pump_id}."
    context.pos.select_pump(pump_id)
    context.fuel_sim.pick_up_handle(pump_id, hose_id)
    context.fuel_sim.wait_for_pump_to_authorize(pump_id)
    assert context.fuel_sim.dispense_by_price(pump_id, price), f"The fuel was not dispensed correctly and returned false."


@given('the pump {pump_id:d} was authorized for {grade} fuel postpay')
def step_impl(context: Context, grade: str, pump_id: int):
    hose_id = context.fuel_sim.get_hose_id(pump_id, grade)
    assert hose_id != -1, f"The hose with grade {grade} was not found on the given pump with id {pump_id}."
    context.pos.select_pump(pump_id)
    context.fuel_sim.pick_up_handle(pump_id, hose_id)
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton.PUMP_START_STOP)
    context.fuel_sim.wait_for_pump_to_authorize(pump_id)


@given('the postpay from pump {pump_id:d} is present in the transaction')
def step_impl(context: Context, pump_id: int):
    context.execute_steps("""
        When the cashier adds a postpay from pump {pump_id} to the transaction
        """.format(pump_id=pump_id))


@given('the cashier selected a {grade_type} grade prepay at pump {pump_id:d}')
def step_impl(context: Context, grade_type: str, pump_id: int):
    context.execute_steps('''
        given the cashier pressed the prepay button for pump {pump_id:d}
        when the cashier selects {type} grade
    '''.format(type=grade_type, pump_id=pump_id))


@given('the cashier enters price {price:f} to prepay pump')
def step_impl(context: Context, price: float):
    context.execute_steps('''
        when the cashier enters price {price:f} to prepay pump
    '''.format(price=price))


@given('the cashier pressed the prepay button for pump {pump_id:d}')
def step_impl(context: Context, pump_id: int):
    context.execute_steps('''
        when the cashier selects pump {pump_id:d}
        when the cashier presses the prepay button on POS
    '''.format(pump_id=pump_id))


@given('the cashier authorized the prepay at pump {pump_id:d}')
def step_impl(context: Context, pump_id: int):
    context.fuel_sim.wait_for_pump_to_authorize(pump_id)
    context.pos.wait_for_prepay_finalization()


@given('a prepay with price {price:f} on the pump {pump_id:d} is present in the transaction')
def step_impl(context: Context, price:float, pump_id: int):
    context.execute_steps('''
        when the cashier selects pump {pump_id:d}
        when the cashier presses the prepay button on POS
        when the cashier enters price {price:f} to prepay pump
    '''.format(price=price, pump_id = pump_id))


@given('the prepay of the fuel grade {grade_type} with price {price:f} at pump id {pump_id:d} is present in the transaction')
def step_impl(context: Context, grade_type: str, price: float, pump_id: int):
    context.execute_steps('''
        when the cashier prepays the fuel grade {grade_type} for price {price:f} at pump id {pump_id:d}
    '''.format(grade_type=grade_type, price=price, pump_id=pump_id))
    context.pos.wait_for_frame_open(POSFrame.MAIN)


@given('the customer dispensed for price {price:f} at pump {pump_id:d}')
def step_impl(context: Context, price: float, pump_id: int):
    context.fuel_sim.wait_for_pump_to_authorize(pump_id)
    assert context.fuel_sim.dispense_by_price(pump_id, price), f'The fueling did not work on pump {pump_id}.'


@given('a prepay item {description} with price {price:f} is in the {transaction} transaction')
def step_impl(context: Context, description: str, price: float, transaction: str):
    context.execute_steps('''
        when the cashier selects Rest in gas button on Prepay amount frame
        then a prepay item {description} with price {price:f} is in the {transaction} transaction
    '''.format(description=description, price=price, transaction=transaction))


@given('a {grade} prepay fuel with {price:f} price on pump {pump:d} is present in the transaction')
def step_impl(context: Context, grade: str, price: float, pump: int):
    context.execute_steps("""
        given the cashier selected a {grade} grade prepay at pump {pump:d}
        given the cashier enters price {price:f} to prepay pump
    """.format(grade=grade, price=price, pump=pump))


@given('a {grade} prepay for pump {pump:d} with a price of {price:f} is tendered in {tender_type} and finalized')
def step_impl(context: Context, grade: str, pump: int, price: float, tender_type: str):
    context.execute_steps("""
        given the cashier selected a {grade} grade prepay at pump {pump:d}
        given the cashier enters price {amount:f} to prepay pump
        when the cashier tenders the transaction with amount {amount:f} in {tender_type}
        then the POS displays main menu frame
        then the transaction is finalized
        then a pump {pump:d} is authorized with a price of {amount:f}
    """.format(grade=grade, amount=price, pump=pump, tender_type=tender_type))


@given('a prepay for pump {pump_id:d} with a price of {price:f} is tendered in {tender_type} and finalized')
def step_impl(context: Context, pump_id: int, price: float, tender_type: str):
    context.execute_steps(f"""
        given a prepay with price {price} on the pump {pump_id} is present in the transaction
        when the cashier tenders the transaction with amount {price} in {tender_type}
        then the POS displays main menu frame
        then the transaction is finalized
        then a pump {pump_id} is authorized with a price of {price}
    """)


@given('a {grade} postpay fuel with {price:f} price on pump {pump:d} is present in the transaction')
def step_impl(context: Context, grade: str, price: float, pump: int):
    context.execute_steps("""
        given the customer dispensed {grade} for {price:f} price at pump {pump:d}
        when the cashier adds a postpay from pump {pump:d} to the transaction
    """.format(grade=grade, price=price, pump=pump))


@given('a fuel item {item_name} is set not to be discountable')
def step_impl(context: Context, item_name: str):
    item_name = item_name + "," + "Self Serve,Cash"
    context.pos.relay_catalog.set_discount_itemizer_mask(item_name=item_name, discount_itemizer_mask=0)


@given('a fuel item {item_name} is set to be discountable')
def step_impl(context: Context, item_name: str):
    item_name = item_name + "," + "Self Serve,Cash"
    context.pos.relay_catalog.set_discount_itemizer_mask(item_name=item_name, discount_itemizer_mask=4)


@given('the customer performed PAP transaction on pump {pump_number:d} for amount {amount:f}')
def step_impl(context: Context, pump_number: int, amount: float):
    context.sc.reset_tran_repository()
    context.sc.inject_transaction(pump_number=pump_number, credit_amount=amount, pap=True)


@given('the cashier prepaid pump {pump_id_from:d} for price {price:f} of {grade} and transferred it to pump {pump_id_to:d}')
def step_impl(context: Context, grade: str, pump_id_from: int, pump_id_to: int, price: float):
    context.execute_steps(f"""
        Given the prepay of the fuel grade {grade} with price {price} at pump id {pump_id_from} is present in the transaction
        Given the transaction is finalized
        When the cashier transfers the prepay from pump {pump_id_from} to pump {pump_id_to}
    """)


@given('the cashier prepaid pump {pump_id_from:d} for price {price:f} and transferred it to pump {pump_id_to:d}')
def step_impl(context: Context, pump_id_from: int, pump_id_to: int, price: float):
    context.execute_steps(f"""
        Given a prepay with price {price} on the pump {pump_id_from} is present in the transaction
        Given the transaction is finalized
        When the cashier transfers the prepay from pump {pump_id_from} to pump {pump_id_to}
    """)


@given('the cashier transferred the prepay from pump {pump_id_from:d} to pump {pump_id_to:d}')
def step_impl(context: Context, pump_id_from: int, pump_id_to: int):
    context.execute_steps(f"""
        When the cashier transfers the prepay from pump {pump_id_from} to pump {pump_id_to}
    """)


@given('the cashier refunds the fuel from pump {pump_id:d}')
def step_impl(context: Context, pump_id: int):
    context.execute_steps("""
        when the cashier refunds the fuel from pump {pump_id:d}
    """.format(pump_id=pump_id))


@given('the pump {pump_id:d} went offline')
def step_impl(context: Context, pump_id: int):
    context.fuel_sim.set_pump_state(pump_id=pump_id, state=9)
    context.fuel_sim.validate_pump_status(pump_id=pump_id, state=FuelPumpStates.OFFLINE)


@given('the cashier selected Go back button on {msg_text} error frame')
def step_impl(context: Context, msg_text: str):
    context.execute_steps("""
        given the transaction is totaled
        given the pump 1 went offline
        when the cashier tenders the transaction with hotkey exact_dollar in cash
        then the POS displays {msg_text} error
        given the cashier pressed Go back button
        """.format(msg_text=msg_text))
    context.pos.wait_for_frame_open(POSFrame.MAIN)


@given('the pump {pump_id:d} has {auth_type} postpay authorization configured')
def step_impl(context: Context, pump_id: int, auth_type: str):
    if pump_id == 1:
        assert auth_type.lower() == 'manual', 'Pump 1 must have manual authorization'
    else:
        assert auth_type.lower() == 'automatic', 'Other pumps must have automatic authorization'


@given('the POS displays Cancel Rest in gas prompt after transaction is tendered')
def step_impl(context: Context):
    context.execute_steps("""
        given the cashier tendered transaction with cash
        """)
    context.pos.wait_for_frame_open(POSFrame.ASK_CANCEL_REST_IN_GAS)


@given('the customer dispensed prepaid {grade} fuel for {price:f} price on the pump {pump_id:d}')
def step_impl(context: Context, grade: str, price: float, pump_id: int):
    context.execute_steps("""
            when the customer dispenses {grade} fuel for {price:f} price on the pump {pump_id:d}
            """.format(grade=grade, price=price, pump_id=pump_id))
# endregion


# region When clauses
@when('the cashier selects Go back button on {msg_text} error frame')
def step_impl(context: Context, msg_text: str):
    context.execute_steps("""
        given the cashier selected Go back button on {msg_text} error frame
        """.format(msg_text=msg_text))

@when('the cashier adds a postpay from pump {pump_id:d} to the transaction')
def step_impl(context: Context, pump_id: int):
    stacked_sales = context.pos.get_count_of_stacked_sales_on_pump(pump_id)
    assert stacked_sales == 1, f"Expecting exactly one fuel sale on the pump {pump_id}. There were {stacked_sales} stacked sales on the pump."
    context.pos.select_pump(pump_id)
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton.PAY_FIRST)


@when('the cashier presses Pay button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton.PAY_FIRST)


@when('the cashier selects {grade_type} grade')
def step_impl(context: Context, grade_type: str):
    current_frame = POSFrame(context.pos.control.get_menu_frame().use_description)
    try:
        context.pos.press_button_on_frame(frame=current_frame, button=POSButton(grade_type))
    except ValueError:
        context.pos.press_button_on_frame(frame=current_frame, button=grade_type)


@when('the cashier presses the prepay button on POS')
def step_impl(context: Context):
    context.pos.press_button_on_frame(frame=POSFrame.MAIN, button=POSButton.PREPAY_CANCEL_PREPAY)


@when('the cashier presses the cancel prepay button on POS')
def step_impl(context: Context):
    context.pos.press_button_on_frame(frame=POSFrame.MAIN, button=POSButton.PREPAY_CANCEL_PREPAY)


@when('the cashier enters price {price:f} to prepay pump')
def step_impl(context: Context, price: float):
    context.pos.press_digits(POSFrame.PREPAY_AMOUNT, price)
    context.pos.press_button_on_frame(POSFrame.PREPAY_AMOUNT, POSButton.ENTER)


@when('the cashier selects Rest in gas button on Prepay amount frame')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.PREPAY_AMOUNT, POSButton.REST_IN_GAS)


@when('the cashier selects pump {pump_id:d}')
def step_impl(context: Context, pump_id: int):
    context.pos.select_pump(pump_id)


@when('the customer dispenses {grade} fuel for {price:f} price on the pump {pump_id:d}')
def step_impl(context: Context, grade: str, price: float, pump_id: int):
    context.fuel_sim.wait_for_pump_to_authorize(pump_id)
    context.pos.wait_for_prepay_finalization()
    context.fuel_sim.pick_up_handle(pump_id, grade=grade)
    assert context.fuel_sim.dispense_by_price(pump_id, price)


@when('the cashier prepays the fuel grade {grade_type} for price {price:f} at pump id {pump_id:d}')
def step_impl(context: Context, grade_type: str, price: float, pump_id: int):
    context.execute_steps('''
        when the cashier selects pump {pump_id:d}
        when the cashier presses the prepay button on POS
        when the cashier selects {grade_type} grade
        when the cashier enters price {price:f} to prepay pump
    '''.format(pump_id=pump_id, grade_type=grade_type, price=price))


@when('the cashier prepays the fuel for price {price:f} at pump id {pump_id:d}')
def step_impl(context: Context, price: float, pump_id: int):
    context.execute_steps('''
        when the cashier selects pump {pump_id:d}
        when the cashier presses the prepay button on POS
        when the cashier enters price {price:f} to prepay pump
    '''.format(price=price, pump_id=pump_id))


@when('the cashier refunds the fuel from pump {pump_id:d}')
def step_impl(context: Context, pump_id: int):
    stacked_sales = context.pos.get_count_of_stacked_sales_on_pump(pump_id)
    assert stacked_sales == 1, f"Expecting exactly one fuel sale on the pump {pump_id}. There were {stacked_sales} stacked sales on the pump."
    context.pos.select_pump(pump_id)
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton.REFUND_FIRST)


@when('the cashier cancels and refunds the fuel from pump {pump_id:d}')
def step_impl(context: Context, pump_id: int):
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton.PREPAY_CANCEL_PREPAY)
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton.PAY_FIRST)


@when('the customer dispensed {grade} for {price:f} price at pump {pump_id:d}')
def step_impl(context: Context, grade: str, price: float, pump_id: int):
    context.execute_steps('''
        given the customer dispensed {grade} for {price:f} price at pump {pump_id:d}
    '''.format(grade=grade, price=price, pump_id=pump_id))


@when('the customer dispenses fuel for {price:f} price at pump {pump_id:d}')
def step_impl(context: Context, price:float, pump_id: int):
    assert context.fuel_sim.dispense_by_price(pump_id, price), f"The fuel was not dispensed correctly and returned false."


@when('the cashier transfers the prepay from pump {pump_id_from:d} to pump {pump_id_to:d}')
def step_impl(context: Context, pump_id_from: int, pump_id_to: int):
    context.pos.transfer_prepay(pump_id_from, pump_id_to)
    assert context.fuel_sim.wait_for_state_on_pump(pump_id_from, FuelPumpStates.IDLE)
    assert context.fuel_sim.wait_for_state_on_pump(pump_id_to, FuelPumpStates.AUTHORIZED)


@when('the cashier cancels the prepay on pump {pump_id:d}')
def step_impl(context: Context, pump_id: int):
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton.PREPAY_CANCEL_PREPAY)


@when('the customer cancels the prepay on pump {pump_id:d}')
def step_impl(context: Context, pump_id: int):
    context.fuel_sim.finish_fueling(pump_id)
# endregion


# region Then clauses
@then('fuel grade {grade} is dispensed for price {dispense_price:f} on the pump {pump_id:d}')
def step_impl(context: Context, grade: str, dispense_price: float, pump_id: int):
    hose_id = context.fuel_sim.get_hose_id(pump_id, grade)
    assert hose_id != -1, f"The hose with grade {grade} was not found on the given pump with id {pump_id}."
    context.fuel_sim.pick_up_handle(pump_id, hose_id)
    assert context.fuel_sim.dispense_by_price(pump_id, dispense_price)


@then('the POS displays frame for the grade selection')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.GRADE_SELECTION)


@then('the POS displays frame for enter amount to prepay')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.PREPAY_AMOUNT)


@then('a prepay item {description} with price {price:f} is in the {transaction} transaction')
def step_impl(context: Context, description: str, price: float, transaction: str):
    assert context.pos.wait_for_item_added(description=description, price=price, item_type=7, transaction=transaction)


@then('a prepay item {description} with price {price:f} is not in the {transaction} transaction')
def step_impl(context: Context, description: str, price: float, transaction: str):
    assert not context.pos.wait_for_item_added(description=description, price=price, item_type=7, transaction=transaction)


@then('a PDL discount {description} with price {price:f} is in the {transaction} transaction')
def step_impl(context: Context, description: str, price: float, transaction: str):
    tran_number = context.pos.get_transaction(transaction).sequence_number
    assert  context.pos.is_item_in_transaction(description=description, price=-price, transaction=tran_number)


@then('a PDL discount {description} without a price is in the {transaction} transaction')
def step_impl(context: Context, description: str, transaction: str):
    tran_number = context.pos.get_transaction(transaction).sequence_number
    # IGNORE_PRICE status doesn't exactly correspond to the price not being shown, but it's the best option we have at the moment
    assert context.pos.is_item_in_transaction(description=description, has_status="IGNORE_PRICE", transaction=tran_number)


@then('a PDL discount {description} with price {price:f} is not in the {transaction} transaction')
def step_impl(context: Context, description: str, price: float, transaction: str):
    tran_number = context.pos.get_transaction(transaction).sequence_number
    assert not context.pos.is_item_in_transaction(description=description, price=-price, transaction=tran_number)


@then('a PDL discount {description} is not in the {transaction} transaction')
def step_impl(context: Context, description: str, transaction: str):
    tran_number = context.pos.get_transaction(transaction).sequence_number
    assert not context.pos.is_item_in_transaction(description=description, transaction=tran_number)


@then('a PDL discount {discount} is in the virtual receipt')
def step_impl(context: Context, discount: str):
    context.pos.wait_for_frame_open(POSFrame.MAIN)
    assert context.pos.verify_virtual_receipt_contains_item(item_name=discount)


@then('a PDL discount {discount} is not in the virtual receipt')
def step_impl(context: Context, discount: str):
    context.pos.wait_for_frame_open(POSFrame.MAIN)
    assert not context.pos.verify_virtual_receipt_contains_item(item_name=discount)


@then('a FPR discount {description} is in the {transaction} transaction')
def step_impl(context: Context, description: str, transaction: str):
    tran_number = context.pos.get_transaction(transaction).sequence_number
    assert context.pos.is_item_in_transaction(description=description, transaction=tran_number)


@then('a fuel item {description} with price {price:f} and volume {volume:f} is in the {transaction} transaction')
def step_impl(context: Context, description: str, price: float, volume: float, transaction: str):
    assert context.pos.wait_for_item_added(description=description, price=price, quantity=volume, item_type=7, transaction=transaction)


@then('a pump {pump_id:d} is authorized with a price of {price:f}')
def step_impl(context: Context, pump_id: int, price: float):
    assert context.fuel_sim.wait_for_state_on_pump(pump_id, FuelPumpStates.AUTHORIZED, price)


@then('a pump {pump_id:d} is not authorized')
def step_impl(context: Context, pump_id: int):
    assert not context.fuel_sim.wait_for_state_on_pump(pump_id, FuelPumpStates.AUTHORIZED, timeout=2)


@then('the POS finalizes the prepay completion transaction for price {price:f} at pump {pump_number:d}')
def step_impl(context: Context, price: float, pump_number: int):
    context.pos.wait_for_complete_prepay_finalization(pump_number, price)


@then('the POS displays {amount:f} refund on pump {pump_number:d}')
def step_impl(context: Context, amount: float, pump_number: int):
    context.pos.wait_for_refund_on_pump(pump_number, amount)


@then('the POS displays Prepay drive off not allowed error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_PREPAY_NOT_ALLOWED)


@then('all pumps are in idle state')
def step_impl(context: Context):
    time.sleep(0.5) # Wait for the pumps to process the last step
    default_state_pumps = len(context.fuel_sim.get_pumps_with_state([FuelPumpStates.IDLE]))
    pumps = len(context.fuel_sim.get_pump_list().get('Pumps', ''))
    assert default_state_pumps == pumps,\
                    f"Some pumps seem not to be in default state. {default_state_pumps} != {pumps}"


@then('the POS displays Pump authorization failed, refund customer error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_PUMP_AUTH_FAILED_REFUND_CUSTOMER)


@then('the POS displays Pump authorization failed, customer has been refunded error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_PUMP_AUTH_FAILED_CUSTOMER_REFUNDED)


@then('the postpay for {amount:f} is present on pump {pump:d}')
def step_impl(context: Context, amount: float, pump: int):
    assert context.pos.verify_fuel_sale_on_pump(pump_id=pump, sale_type='postpay', sale_amount=amount)
    pump_info = context.fuel_sim.get_pump_info(pump)
    last_sale = pump_info['CompletedSaleList'][-1]
    type_info = last_sale.get('TransactionType', '')
    amount_dispensed = last_sale.get('Money', 0) / 100
    if type_info == 'POSTPAY':
        assert math.isclose(amount, amount_dispensed, rel_tol=1e-3), f"Wrong amount {amount_dispensed}"
    elif type_info == 'PREPAY':
        amount_authorization = last_sale.get('AuthorizationAmount', 0) / 100
        amount_postpay = amount_dispensed - amount_authorization
        assert math.isclose(amount, amount_postpay, rel_tol=1e-3), f"Wrong overrun amount {amount_postpay}"
        pass
    else:
        assert False, f"Wrong transaction type {type_info}"


@then('the postpay is not present on pump {pump:d}')
def step_impl(context: Context, pump: int):
    assert not timeouter(context.pos.verify_fuel_sale_on_pump, 1, pump, 'postpay', None, expected_result=False)
    pump_info = context.fuel_sim.get_pump_info(pump)
    completed_sales = pump_info.get('CompletedSaleList')
    if completed_sales and len(completed_sales) >= 1:
        last_sale = completed_sales[-1]
        type_info = last_sale.get('TransactionType', '')
        assert type_info != 'POSTPAY', f"Transaction type POSTPAY detected"


@then('the POS displays Cancel Rest in gas prompt')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_CANCEL_REST_IN_GAS)


@then('fuel item {item_name} detail from the previous transaction contains fuel metrics')
def step_impl(context: Context, item_name: str):
    transaction = context.pos.control.wait_for_transaction_end()
    assert transaction != None
    assert transaction.check_fuel_metrics(fuel_item_name=item_name, should_be_included=True)


@then('fuel item {item_name} detail in the current transaction contains fuel metrics')
def step_impl(context: Context, item_name: str):
    transaction = context.pos.get_current_transaction()
    assert transaction != None
    assert transaction.check_fuel_metrics(fuel_item_name=item_name, should_be_included=True)


@then('fuel item {item_name} detail from the previous transaction does not contain fuel metrics')
def step_impl(context: Context, item_name: str):
    transaction = context.pos.control.wait_for_transaction_end()
    assert transaction != None
    assert transaction.check_fuel_metrics(fuel_item_name=item_name, should_be_included=False)
# endregion