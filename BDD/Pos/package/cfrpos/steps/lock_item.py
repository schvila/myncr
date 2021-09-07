from behave import *
from behave.runner import Context

from cfrpos.core.bdd_utils.errors import ProductError
from cfrpos.core.pos.ui_metadata import POSFrame, POSButton


# region Given clauses
@given('the POS has following sale items locked')
def step_impl(context: Context):        
    for row in context.table:
        context.pos.relay_catalog.set_sale_item_locked(int(row["item_id"]), int(row["modifier1_id"]), True)

@given('an item {item_id:d} with modifier {modifier1_id:d} is locked')
def step_impl(context: Context, item_id: int, modifier1_id: int):        
    context.pos.relay_catalog.set_sale_item_locked(item_id, modifier1_id, True)

@given('an item {item_id:d} with modifier {modifier1_id:d} is not locked')
def step_impl(context: Context, item_id: int, modifier1_id: int):        
    context.pos.relay_catalog.set_sale_item_locked(item_id, modifier1_id, False)
# endregion


# region When clauses
# endregion


# region Then clauses
@then('the POS displays Locked frame')
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.MSG_ITEM_LOCKED)
