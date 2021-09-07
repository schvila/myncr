from behave import *
from behave.runner import Context
from cfrpos.core.pos.ui_metadata import POSFrame
import time


# region Given clauses (configuration)
@given('the POS does not display the {alert} alert')
def step_impl(context: Context, alert: str):
    alert_index = context.stmapi_sim.find_alert(alert)
    assert alert_index != 0, 'given alert {} is not in the enum of eligible alerts'.format(alert)
    if alert_index != -1:
        context.stmapi_sim.clear_alert(alert_index)


@given('the POS displays the {alert} alert')
def step_impl(context: Context, alert: str):
    if not context.stmapi_sim.is_alert_displayed(alert):
        context.execute_steps(
            """
            given the POS does not display the {alert} alert
            given the pinpad is set to reboot in 5 min 0 sec
            given the POSCache simulator sent a message PinPadRebootWarning to the POS
            """.format(alert=alert))
    assert context.stmapi_sim.wait_for_alert(alert)


@given('the pinpad is set to reboot in {minutes:d} min {seconds:d} sec')
def step_impl(context: Context, minutes: int, seconds: int = 0):
    assert context.epc_sim.poscache.update_pinpad_reboot_time(minutes, seconds)


@given('the cashier pressed alert {alert_name} {number:d} times')
def step_impl(context: Context, alert_name: str, number: int):
    for i in range(number):
        context.execute_steps(
            """
            when the cashier presses alert {alert_name}
            """.format(alert_name=alert_name))
        context.pos.wait_for_frame_open(POSFrame.MSG_PINPAD_REBOOT_IN_5_MINUTES)
# endregion


# region When clauses
@when('the cashier presses alert {alert_name}')
def step_impl(context: Context, alert_name: str):
    assert context.stmapi_sim.wait_for_alert(alert_name)
    assert context.stmapi_sim.select_alert(alert_name)


@when('the POS is inactive for {seconds:d} seconds and then reboots')
def step_impl(context: Context, seconds: int):
    time.sleep(seconds)
    context.pos.restart()
# endregion


# region Then clauses
@then('the POS displays the {alert} alert')
def step_impl(context: Context, alert: str):
    assert context.stmapi_sim.wait_for_alert(alert)


@then('the POS does not display the {alert} alert')
def step_impl(context: Context, alert: str):
    assert context.stmapi_sim.wait_for_alert_removed(alert)


@then('the POS displays Pinpad rebooting frame with no time')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_PINPAD_REBOOTING)


@then('the POS displays Pinpad will reboot frame in less than minute')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_PINPAD_REBOOT_IN_MINUTE)


@then('the POS displays Pinpad will reboot frame in less than 5 minutes')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_PINPAD_REBOOT_IN_5_MINUTES)
# endregion
