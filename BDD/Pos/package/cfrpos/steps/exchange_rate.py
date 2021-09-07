from behave import *
from behave.runner import Context
from cfrpos.core.pos.ui_metadata import POSButton, POSFrame
import math


# region Given clauses (configuration)
@given('the POS has following tenders configured')
def step_impl(context: Context):
    for row in context.table:
        exchange_rate = row["exchange_rate"] if "exchange_rate" in row.headings else 1
        currency_symbol = row["currency_symbol"] if "currency_symbol" in row.headings else '$'
        tender_mode_2 = int(row["tender_mode_2"]) if "tender_mode_2" in row.headings else 16
        tender_ranking = int(row["tender_ranking"]) if "tender_ranking" in row.headings else 1
        context.pos.relay_catalog.create_tender(tender_id=row["tender_id"], description=row["description"], tender_type_id=row["tender_type_id"],
                                                external_id=row["external_id"], currency_symbol=currency_symbol, exchange_rate=exchange_rate, tender_mode_2=tender_mode_2)
        context.pos.relay_catalog.create_tender_type(tender_type_id=row["tender_type_id"], description=row["description"], tender_ranking=tender_ranking)
# endregion


# region Given clauses (state)
@given('the POS displays Amount selection frame after selecting {tender} tender with external id {external_id} and type id {type_id}')
def step_impl(context: Context, tender: str, external_id: str, type_id: int):
    context.execute_steps('''
        when the cashier presses the {tender} tender button with external id {external_id} and type id {type_id}
    '''.format(tender=tender, external_id=external_id, type_id=type_id))
# endregion


# region When clauses
@when('the cashier presses the {tender_type} tender button with external id {external_id} and type id {type_id}')
def step_impl(context: Context, tender_type: str, external_id: str, type_id: int):
    tender_button = "tender-type-" + str(type_id) + "-" + external_id
    tender_button_prefix = "tender-type-" + str(type_id) + "-"
    assert context.pos.navigate_to_tenderbar_button(tender_button)
    context.pos.control.press_button_on_frame(POSFrame.MAIN, POSButton(tender_button_prefix), button_suffix=external_id)
# endregion


# region Then clauses
@then('the POS displays recalculated Balance due amount {calculated_amount:f} and currency {currency}')
def step_impl(context: Context, calculated_amount: float, currency: str):
    frame = context.pos.control.get_menu_frame()
    amount = frame.use_details.get('RestrictedAmountCurrency')
    currency_symbol = frame.use_details.get('CurrencySymbol')
    assert math.isclose(float(amount), calculated_amount, rel_tol=1e-2)
    assert currency_symbol == currency
# endregion
