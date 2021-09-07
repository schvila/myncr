from behave import *
from behave.runner import Context
import math
import time

from cfrpos.core.bdd_utils.pos_utils import POSUtils
from cfrpos.core.bdd_utils.errors import ProductError
from cfrpos.core.pos.ui_metadata import POSFrame, POSButton


# region Given clauses (configuration)
@given('quantity restriction groups contain items')
def step_impl(context: Context):
    for row in context.table:
        sale_quantity_id = int(row["sale_quantity_id"]) if "sale_quantity_id" in row.headings else None
        description = str(row["name"]) if "name" in row.headings else "New restricted group"
        retail_item_group_id = int(row["retail_item_group_id"]) if "retail_item_group_id" in row.headings else None
        transaction_limit = int(row["transaction_limit"]) if "transaction_limit" in row.headings else 1
        item_id = int(row["item_id"]) if "item_id" in row.headings else None
        modifier1_id = int(row["modifier1_id"]) if "modifier1_id" in row.headings else 0
        modifier2_id = int(row["modifier2_id"]) if "modifier2_id" in row.headings else 0
        modifier3_id = int(row["modifier3_id"]) if "modifier3_id" in row.headings else 0
        quantity = int(row["quantity"]) if "quantity" in row.headings else 1

        context.pos.relay_catalog.create_quantity_restriction(
            retail_item_group_id, item_id, modifier1_id, modifier2_id, modifier3_id, quantity,
            transaction_limit, description, sale_quantity_id)


@given('the cashier stored a transaction containing {amount} items with barcode {barcode}')
def step_impl(context: Context, barcode: str, amount: int):
    context.execute_steps('''
    Given an item with barcode {barcode} is present in the transaction {amount} times
    When the cashier stores the transaction
    '''.format(barcode=barcode, amount=amount))


@given('the cashier recalled last stored transaction')
def step_impl(context: Context):
    context.execute_steps('''
    When the cashier recalls the last stored transaction
    ''')
# endregion


# region When clauses
@when('the cashier adds item {barcode} from the price check menu')
def step_impl(context: Context, barcode: str):
    context.execute_steps('''
    Given the cashier performed price check of item with barcode {barcode}
    When the cashier presses Add to order button
    '''.format(barcode=barcode))
# endregion