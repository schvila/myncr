from behave import *
from behave.runner import Context

from cfrpos.core.pos.ui_metadata import POSFrame, POSButton

import time

# region Given clauses
@given('the POS API notification server has default configuration')
def step_impl(context: Context):
    context.nepsvcs_sim.clear_request_messages()
    context.nepsvcs_sim.prepare_message_response()
 
@given('the POS API notification server does not respond')
def step_impl(context: Context):
    context.nepsvcs_sim.clear_request_messages()
    context.nepsvcs_sim.prepare_message_response("Fail")

@given('the POS displays the POS API notification alert {alert}')
def step_impl(context: Context, alert: str):
    assert context.stmapi_sim.wait_for_alert(alert)
# endregion

# region When clauses
@when('the POS API notification server does not respond')
def step_impl(context: Context):
    context.nepsvcs_sim.prepare_message_response("Fail")

@when('the POS API notification server returns empty alert list')
def step_impl(context: Context):
    context.nepsvcs_sim.prepare_message_response()

@when('the POS API notification server returns alert {alert}')
def step_impl(context: Context, alert:str):
    context.nepsvcs_sim.prepare_message_response(alert_text=alert)
# endregion


# region Then clauses
@then('the POS API notification server captures topic id {topic_id}')
def step_impl(context: Context, topic_id: str):
    assert context.nepsvcs_sim.wait_for_notification(topic_id)

@then('the POS API notification server does not capture topic id {topic_id}')
def step_impl(context: Context, topic_id: str):
    time_out = 1
    assert not context.nepsvcs_sim.wait_for_notification(topic_id, time_out)

@then('the POS does not display any notification alert')
def step_impl(context: Context):
    controller_alert_removed = context.stmapi_sim.wait_for_alert_removed("STM_CONTROLLER_OFFLINE")
    device_alert_removed = context.stmapi_sim.wait_for_alert_removed("STM_DEVICE_OFFLINE")
    assert (controller_alert_removed and device_alert_removed)
# endregion
