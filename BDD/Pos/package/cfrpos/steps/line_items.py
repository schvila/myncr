from behave import *
from behave.runner import Context
from cfrpos.core.bdd_utils.poscache_utils import POSCacheUtils

# region Given clauses
@given('the POS has Customer Display configured')
def step_impl(context: Context):
    if not context.pos.relay_catalog.dev_set_relay.is_device_record_added(device_name='CustomerDisplay'):
        context.pos.relay_catalog.dev_set_relay.create_device_record(device_type='PCSCust_Monitor', logical_name='CUSTDISP', device_name='OPOS_CustDisplay',
                                     port_name='opos:NCRXSeries2x20LineDisplay.USB', data_info='cp=858', parameters='None', location='Local')


@given('items with barcodes {barcodes} are present in the transaction')
def step_impl(context: Context, barcodes: str):
    context.execute_steps('''
        when the cashier scans following barcodes {barcode_list}
        '''.format(barcode_list=barcodes))

# endregion

# region When clauses
@when('the cashier scans following barcodes {barcode_list}')
def step_impl(context: Context, barcode_list: str):
    barcodes = barcode_list.split(', ')
    for barcode in barcodes:
        context.pos.scan_item_barcode(barcode=barcode)
        context.pos.wait_for_item_added(barcode)

# endregion

# region Then clauses
@then('the pinpad displays line items {items}')
def step_impl(context: Context, items: str):
    expected_items = items.split(', ')
    data = context.epc_sim.poscache.get_poscache_data()
    actual_items = POSCacheUtils.get_displayed_items(data)
    assert expected_items == list(actual_items.values())   

# endregion