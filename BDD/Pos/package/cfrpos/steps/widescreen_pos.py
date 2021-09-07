from behave import *
from behave.runner import Context
from cfrpos.core.pos.ui_metadata import POSButton, POSFrame


# region Given clauses
@given('the POS screen resolution is {resolution} and corresponding relay files are configured')
def step_impl(context: Context, resolution: int):
    assert context.bdd_config is not None
    context.bdd_config['pos_resolution'] = resolution
    context.pos.relay_catalog.reset()
# endregion


# region When clauses
@when('the cashier presses a {tender_type} tender button with external id {external_id} and type id {type_id} on the current frame')
def step_impl(context: Context, tender_type: str, external_id: str, type_id: int):
    tender_button = "tender-type-" + str(type_id) + "-" + external_id
    tender_button_prefix = "tender-type-" + str(type_id) + "-"
    context.pos.control.press_button_on_frame(POSFrame.MAIN, POSButton(tender_button_prefix), button_suffix=external_id)
# endregion
