from behave import *
from behave.runner import Context
from cfrpos.core.pos.ui_metadata import POSFrame


# region Given clauses (configuration)
@given("the POSCache simulator has default configuration")
def step_impl(context: Context):
    assert context.epc_sim.poscache.reset()


@given("the POSCache simulator sent a message {message_name} to the POS")
def step_impl(context: Context, message_name: str):
    context.execute_steps('''
        when the POSCache simulator sends a message {message_name} to the POS
    '''.format(message_name=message_name))
# endregion


# region When clauses
@when("the POSCache simulator sends a message {message_name} to the POS")
def step_impl(context: Context, message_name: str):
    context.epc_sim.poscache.create_transaction()
    context.epc_sim.poscache.post_complete_with_message(message_name)
# endregion


# region Then clauses
# TODO
NOT_IMPLEMENTED = 'story: RPOS-15707 is not ready and it is not possible to take content of the frame'


@then("the POS displays Payment declined frame")
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_SWIPE_AHEAD)
    raise AssertionError(NOT_IMPLEMENTED)


@then("the POS displays Payment cancelled frame")
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_SWIPE_AHEAD)
    raise AssertionError(NOT_IMPLEMENTED)
# endregion
