from behave import *
from behave.runner import Context
import math
import time

from cfrpos.core.bdd_utils.errors import ProductError
from cfrpos.core.pos.ui_metadata import POSFrame, POSButton


# region Given clauses
@given('the POS displays Amount selection frame after cashier selecting {tender} tender button with external id {external_id} from the tender group {group_id}')
def step_impl(context: Context, tender: str, external_id: str, group_id: str):
    context.execute_steps('''when the cashier selects the {tender} tender button with external id {external_id} from the tender group {group_id}'''.format(tender=tender, external_id=external_id, group_id=group_id))
    tender_frame = 'ask-tender-amount-{}'.format(tender.lower())
    context.pos.wait_for_frame_open(tender_frame)
# endregion


# region When clauses
@when('the cashier selects the {tender} tender button with external id {external_id} from the tender group {group_id}')
def step_impl(context: Context, tender: str, external_id: str, group_id: str):
    context.pos.select_tender_group_from_tenderbar(group_id)
    tender_button = "tender-" + str(tender) + "-" + external_id
    context.pos.select_tender_from_tender_group(tender_button)
# endregion


# region Then clauses

# endregion
