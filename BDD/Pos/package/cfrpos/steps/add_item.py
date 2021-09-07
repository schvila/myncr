from behave import *
from behave.runner import Context

from cfrpos.core.bdd_utils.errors import ProductError
from cfrpos.core.pos.ui_metadata import POSFrame, POSButton


# region Given clauses
@given('the pricebook contains department sale items')
def step_impl(context: Context):
    for row in context.table:
        modifier1_id = int(row["modifier1_id"]) if "modifier1_id" in row.headings else 0
        unit_packing_id = int(row["unit_packing_id"]) if "unit_packing_id" in row.headings else 990000000007
        age_restriction = int(row["age_restriction"]) if "age_restriction" in row.headings else 0
        age_restriction_before_eff_date = int(row["age_restriction_before_eff_date"]) if "age_restriction_before_eff_date" in row.headings else 0
        effective_date_year = int(row["effective_date_year"]) if "effective_date_year" in row.headings else 0
        effective_date_month = int(row["effective_date_month"]) if "effective_date_month" in row.headings else 0
        effective_date_day = int(row["effective_date_day"]) if "effective_date_day" in row.headings else 0
        credit_category = int(row["credit_category"]) if "credit_category" in row.headings else 2010
        military_age_restriction = int(row["military_age_restriction"]) if "military_age_restriction" in row.headings else 0
        item_type = int(row["item_type"]) if "item_type" in row.headings else 1
        item_mode = int(row["item_mode"]) if "item_mode" in row.headings else 0
        if "barcode" in row.headings:
            barcode = row["barcode"]
        else:
            raise ProductError("The department item barcode is not provided")
        if "price" in row.headings:
            price = float(row["price"])
        else:
            raise ProductError("The department item price is not provided")
        if "description" in row.headings:
            description = row["description"]
        else:
            raise ProductError("The department item description is not provided")
        if "item_id" in row.headings:
            item_id = row["item_id"]
        else:
            raise ProductError("The department item id is not provided")
        disable_over_button = False
        if "disable_over_button" in row.headings:
            if str(row["disable_over_button"]).lower() in ['true', '1', 'yes']:
                disable_over_button = True
        validate_id = False
        if "id_validation_required" in row.headings:
            if str(row["id_validation_required"]).lower() in ['true', '1', 'yes']:
                validate_id = True
        manager_required = False
        if "manager_override_required" in row.headings:
            if str(row["manager_override_required"]).lower() in ['true', '1', 'yes']:
                manager_required = True

        context.pos.relay_catalog.create_sale_item(barcode, price, description,
                                                    item_id, modifier1_id, unit_packing_id,
                                                    age_restriction, age_restriction_before_eff_date,
                                                    effective_date_year, effective_date_month,
                                                    effective_date_day, credit_category, disable_over_button,
                                                    validate_id, manager_required, military_age_restriction,
                                                    item_type, item_mode)


@given('the POS displays Select department sale frame')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton.DEPARTMENT_SALE)
    context.pos.wait_for_frame_open(POSFrame.SELECT_DEPARTMENT_SALE)


@given('the POS displays Ask enter dollar amount frame after selecting a department sale item {description}')
def step_impl(context: Context, description: str):
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton.DEPARTMENT_SALE)
    button = description.replace(' ', '-').lower()
    context.pos.press_button_on_frame(POSFrame.SELECT_DEPARTMENT_SALE, button)
    context.pos.wait_for_frame_open(POSFrame.ASK_ENTER_DOLLAR_AMOUNT)


@given('the POS displays Select a carwash item frame')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton.SELL_CARWASH)
    context.pos.wait_for_frame_open(POSFrame.ASK_CARWASH_SALE_SELECT)
# endregion


# region When clauses
@when('the cashier presses Department sale button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton.DEPARTMENT_SALE)


@when('the cashier presses Sell carwash button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton.SELL_CARWASH)


@when('the cashier selects a carwash item Full Car wash while carwash online')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton.SELL_CARWASH)


@when('the cashier selects department item {item_name} from select department sale frame')
def step_impl(context: Context, item_name: str):
    button = item_name.replace(' ', '-').lower()
    context.pos.press_button_on_frame(POSFrame.SELECT_DEPARTMENT_SALE, button)


@when('the cashier presses Clear button')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.ASK_ENTER_DOLLAR_AMOUNT, POSButton.CLEAR)


@when('the cashier adds department sale item {item_name} with price {item_price:f} in the transaction')
def step_impl(context: Context, item_name: str, item_price: float):
    context.pos.press_button_on_frame(POSFrame.MAIN, POSButton.DEPARTMENT_SALE)
    button = item_name.replace(' ', '-').lower()
    context.pos.press_button_on_frame(POSFrame.SELECT_DEPARTMENT_SALE, button)
    context.pos.press_digits(POSFrame.ASK_ENTER_DOLLAR_AMOUNT, item_price)
    context.pos.press_button_on_frame(POSFrame.ASK_ENTER_DOLLAR_AMOUNT, POSButton.ENTER)


@when('the cashier presses Clear button on Ask barcode entry frame')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.ASK_BARCODE_ENTRY, POSButton.CLEAR)
# endregion


# region Then clauses
@then('the POS displays Select department sale frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.SELECT_DEPARTMENT_SALE)


@then('the POS displays Select a carwash item frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_CARWASH_SALE_SELECT)
# endregion
