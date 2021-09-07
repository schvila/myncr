from behave import *
from behave.runner import Context

from cfrpos.core.bdd_utils.errors import ProductError
from cfrpos.core.pos.ui_metadata import POSFrame, POSButton
from cfrpos.core.pos.pos_product import POSProduct



# region Given clauses
@given('the POS has the following operators with security rights configured')
def step_impl(context: Context):
    for row in context.table:
        password = int(row["pin"])
        first_name = row["first_name"] if "first_name" in row.headings else "Cashier"
        last_name = row["last_name"] if "last_name" in row.headings else str(password)
        handle = last_name + ", " + first_name
        operator_id = row["operator_id"] if "operator_id" in row.headings else None
        operator_role = row["operator_role"] if "operator_role" in row.headings else "Cashier"
        security_group_id = row['security_group_id'] if 'security_group_id' in row.headings else None
        security_application_id = row['security_application_id'] if 'security_application_id' in row.headings else None
        context.pos.relay_catalog.create_operator(
            password=password,
            handle=handle,
            last_name=last_name,
            first_name=first_name,
            operator_id=operator_id,
            operator_role=operator_role,
            security_group_id=security_group_id)

        context.pos.relay_catalog.pos_man_relay.create_security_group(group_id=security_group_id, security_application_id=security_application_id, operator=operator_role)


@given('the POS displays Operator not found error')
def step_impl(context: Context):
    context.pos.press_button_on_frame(POSFrame.START_SHIFT, POSButton.SHIFT)
    context.pos.press_button_on_frame(POSFrame.ASK_OPERATOR_PIN, POSButton.SHIFT)
    context.pos.wait_for_frame_open(POSFrame.MSG_OPERATOR_NOT_FOUND)


@given('the {user} entered {pin} pin on Ask security override frame')
def step_impl(context: Context, user: str, pin: int):
    context.pos.wait_for_frame_open(POSFrame.ASK_SECURITY_OVERRIDE)
    context.pos.press_digits(POSFrame.ASK_SECURITY_OVERRIDE, pin)
    context.pos.press_button_on_frame(POSFrame.ASK_SECURITY_OVERRIDE, POSButton.ENTER)


@given("the cashier is overriden by user with pin {user_pin}")
def step_impl(context: Context, user_pin: int):
    context.pos.override_current_operator(user_pin)
# endregion


# region When clauses
@when('the {user} enters {pin} pin on Ask security override frame')
def step_impl(context: Context, user: str, pin: int):
    context.execute_steps('''
        given the {user} entered {pin} pin on Ask security override frame
    '''.format(user=user, pin=pin))
# endregion


# region Then clauses
@then('the POS displays Ask security override frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_SECURITY_OVERRIDE)
# endregion