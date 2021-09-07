from behave import *
from behave.runner import Context

from cfrpos.core.relay.tax import TaxType

# region Given clauses
@given('the POS has tax plan {tax_plan_description} with id {tax_plan_id} configured with following taxes')
def step_impl(context: Context, tax_plan_id:int, tax_plan_description:str):
    plan_itemizer_mask = 0
    for row in context.table:
        tax_control_id = int(row["tax_control_id"]) if "tax_control_id" in row.headings else None
        tax_value = float(row["tax_value"]) if "tax_value" in row.headings else None
        tax_description = row["tax_description"] if "tax_description" in row.headings else None
        destination_id = int(row["destination_id"]) if "destination_id" in row.headings else 0
        tax_type = TaxType[row["tax_type"]] if "tax_type" in row.headings else TaxType.PERCENT
        itemizer_num = int(row["itemizer_num"]) if "itemizer_num" in row.headings else None
        
        itemizer_mask = context.pos.relay_catalog.create_tax(tax_description=tax_description, tax_type=tax_type
                                            , tax_value=tax_value, itemizer_num=itemizer_num
                                            ,tax_control_id=tax_control_id, destination_id=destination_id)
        if not(plan_itemizer_mask & itemizer_mask):
            plan_itemizer_mask += itemizer_mask

    context.pos.relay_catalog.create_tax_plan_with_tax(itemizer_mask=plan_itemizer_mask, plan_description=tax_plan_description, tax_plan_schedule_id=tax_plan_id)

# endregion
