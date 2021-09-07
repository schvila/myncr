from behave import *
from behave.runner import Context

from cfrpos.core.bdd_utils.errors import ProductError
from cfrpos.core.pos.ui_metadata import POSFrame, POSButton


# region Given clauses
@given('the POS has following sale items with past effective date configured')
def step_impl(context: Context):
    for row in context.table:
        year, month, day = context.pos.calculate_and_parse_effective_date(-int(row["effective_date_before_years"]))
        context.pos.relay_catalog.create_sale_item(row["barcode"], float(row["price"]), row["description"], 
                                                   int(row["item_id"]), int(row["modifier1_id"]), 
                                                   age_restriction=21, age_restriction_before_eff_date=18,
                                                   effective_date_year=year, effective_date_month=month,
                                                   effective_date_day=day)


@given('the POS has following sale items with future effective date configured')
def step_impl(context: Context):
    for row in context.table:
        year, month, day = context.pos.calculate_and_parse_effective_date(int(row["effective_date_after_years"]))
        context.pos.relay_catalog.create_sale_item(row["barcode"], float(row["price"]), row["description"],
                                                   int(row["item_id"]), int(row["modifier1_id"]),
                                                   age_restriction=21, age_restriction_before_eff_date=18,
                                                   effective_date_year=year, effective_date_month=month,
                                                   effective_date_day=day)
# endregion


# region When clauses
@when('the cashier manually enters the birthday of a customer who was 18 one day after the effective date hit {years:n} years ago')
def step_impl(context: Context, years: int):
    birthday = context.pos.calculate_birthday(age=18 + int(years), day_offset=1)
    context.pos.enter_birthday_manually(birthday)


@when('the cashier manually enters the birthday of a customer who was 18 the same day as the effective date hit {years:n} years ago')
def step_impl(context: Context, years: int):
    birthday = context.pos.calculate_birthday(age=18 + int(years))
    context.pos.enter_birthday_manually(birthday)


@when('the cashier manually enters the birthday of a customer who was 18 one day before the effective date hit {years:n} years ago')
def step_impl(context: Context, years: int):
    birthday = context.pos.calculate_birthday(age=18 + int(years), day_offset=-1)
    context.pos.enter_birthday_manually(birthday)
# endregion


# region Then clauses
@then('the POS displays an Error frame saying Customer was not {age_before:n} when effective date hit {date:n} years age and restriction moved to {age_after:n}')
def step_impl(context: Context, age_before: int, date: int, age_after: int):
    context.pos.wait_for_frame_open(POSFrame.MSG_AGE_REQUIREMENTS_NOT_MET_EFFECTIVE)
    eff_date = context.pos.calculate_effective_date(year_dif=-date)
    eff_date = eff_date.strftime("%#m/%#d/%Y")
    assert context.pos.validate_use_details({'RequiredAge': age_before, 'InEffectAge': age_after, 'TransitionDate': eff_date})


# endregion
