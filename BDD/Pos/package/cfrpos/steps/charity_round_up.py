from behave import *
from behave.runner import Context
from cfrpos.core.pos.ui_metadata import POSButton, POSFrame
import math


# region Given clauses
@given('the pricebook contains charity item')
def step_impl(context: Context):
    for row in context.table:
        modifier1_id = int(row["modifier1_id"]) if "modifier1_id" in row.headings else 0
        unit_packing_id = int(row["unit_packing_id"]) if "unit_packing_id" in row.headings else 990000000007
        tax_plan_id = int(row["tax_plan_id"]) if "tax_plan_id" in row.headings else 0
        age_restriction = int(row["age_restriction"]) if "age_restriction" in row.headings else 0
        age_restriction_before_eff_date = int(row["age_restriction_before_eff_date"]) if "age_restriction_before_eff_date" in row.headings else 0
        effective_date_year = int(row["effective_date_year"]) if "effective_date_year" in row.headings else 0
        effective_date_month = int(row["effective_date_month"]) if "effective_date_month" in row.headings else 0
        effective_date_day = int(row["effective_date_day"]) if "effective_date_day" in row.headings else 0
        credit_category = int(row["credit_category"]) if "credit_category" in row.headings else None
        context.pos.relay_catalog.create_sale_item(row["barcode"], float(row["price"]), row["description"], row["item_id"], modifier1_id,
                                                  unit_packing_id, age_restriction, age_restriction_before_eff_date,
                                                    effective_date_year, effective_date_month,
                                                    effective_date_day, credit_category, tax_plan_id)
        context.pos.relay_catalog.item_codes_relay.create_item_external_code(row["item_id"], row["external_id"])

@given('the cashier pressed Charity Round up button after selecting {tender_type} tender')
def step_impl(context: Context, tender_type: str):
    context.execute_steps('''
        given the POS displays Ask tender amount {tender_type} frame
    '''.format(tender_type=tender_type))
    tender_frame = 'ask-tender-amount-{}'.format(tender_type.lower())
    context.pos.press_button_on_frame(POSFrame(tender_frame), POSButton.CHARITY_DONATION)


@given('the total from current transaction is rounded to {total:f}')
def step_impl(context: Context, total: float):
    context.execute_steps('''
        then the total from current transaction is rounded to {total:f}
    '''.format(total=total))


@given('the Donation item with price {price:f} is present in the transaction after using Charity roundup button on {tender_type} tender frame')
def step_impl(context: Context, price: float, tender_type: str):
    context.execute_steps('''
        given the cashier pressed Charity Round up button after selecting {tender_type} tender
        then an item Donation item with price {price:f} is in the current transaction
        when the cashier presses Go back button
        then the POS displays main menu frame
    '''.format(price=price, tender_type=tender_type))


@given('the total from current transaction is rounded to {total:f} after using charity roundup button on {tender_type} tender frame with donation {price:f}')
def step_impl(context: Context, price: float, tender_type: str, total:float):
    context.execute_steps('''
        given the Donation item with price {price:f} is present in the transaction after using Charity roundup button on {tender_type} tender frame
        then the total from current transaction is rounded to {total:f}
    '''.format(price=price, tender_type=tender_type, total=total))


@given('the POS displays Container Deposit Redemption frame')
def step_impl(context: Context):
    context.execute_steps(''' given the POS displays Other functions frame ''')
    context.pos.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.CONTAINER_DEPOSIT_REDEMPTION)
    frame = context.pos.control.get_menu_frame()
    if frame.use_description == POSFrame.ASK_SECURITY_OVERRIDE.value:
        context.execute_steps('''
            given the manager entered 2345 pin on Ask security override frame
        '''.format())
    context.pos.wait_for_frame_open(POSFrame.CONTAINER_DEPOSIT_REDEMPTION_FRAME)


@given('the cashier entered a barcode {barcode} of an item with a container')
def step_impl(context: Context, barcode: int):
    context.pos.press_button_on_frame(POSFrame.CONTAINER_DEPOSIT_REDEMPTION_FRAME, POSButton.MANUAL_ENTER_BARCODE)
    context.pos.press_digits(POSFrame.ASK_BARCODE_ENTRY, barcode)
    context.pos.press_button_on_frame(POSFrame.ASK_BARCODE_ENTRY, POSButton.ENTER)
    context.pos.return_to_mainframe()
# endregion


# region When clauses
@when('the cashier presses Charity Round up button after selecting {tender_type} tender')
def step_impl(context: Context, tender_type: str):
    context.execute_steps('''
        given the cashier pressed Charity Round up button after selecting {tender_type} tender
    '''.format(tender_type=tender_type))


@when('the cashier enters a barcode {barcode} of an item with a container')
def step_impl(context: Context, barcode: int):
    context.execute_steps('''
        given the cashier entered a barcode {barcode} of an item with a container
    '''.format(barcode=barcode))
# endregion


# region Then clauses
@then('the total from current transaction is rounded to {total:f}')
def step_impl(context: Context, total: float):
    assert math.isclose(context.pos.get_current_transaction().balance, float(total), rel_tol=1e-5)


@then('the POS displays Item not found error')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_ITEM_NOT_FOUND)


@then('the Charity Round up button on {tender_type} tender frame is disabled')
def step_impl(context: Context, tender_type: str):
    tender_frame = 'ask-tender-amount-{}'.format(tender_type.lower())
    assert not context.pos.press_button_on_frame(POSFrame(tender_frame), POSButton.CHARITY_DONATION)


@then('the Charity Round up button on cash tender frame is not displayed')
def step_impl(context: Context):
    assert not context.pos.current_frame_has_button(POSButton.CHARITY_DONATION)
# endregion
