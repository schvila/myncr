from behave import *
from behave.runner import Context
from cfrpos.core.pos.ui_metadata import POSButton, POSFrame


# region Given clauses
# endregion

# region When clauses
# endregion

# region Then clauses
@then('the POS displays Please wait frame followed by main menu frame')
def step_impl(context: Context):
     context.pos.wait_for_frame_open(POSFrame.WAIT_WINCOR_PROCESSING)
     context.pos.wait_for_frame_open(POSFrame.MAIN)

# endregion