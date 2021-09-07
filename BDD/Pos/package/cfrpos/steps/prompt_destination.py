from behave import *
from behave.runner import Context

from cfrpos.core.pos.ui_metadata import POSFrame, POSButton



# region Given clauses

# endregion


# region When clauses

# endregion

# region Then clauses
@then('the POS displays ask confirm destination frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_CONFIRM_DESTINATION)
# endregion