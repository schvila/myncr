from behave import *
from behave.runner import Context
from time import sleep
from cfrpos.core.bdd_utils.errors import ProductError
from cfrpos.core.bdd_utils.receipt_comparer import compare_receipts
import datetime


# region Given clauses
@given('the POS has a receipt {receipt_name} set as active')
def step_impl(context: Context, receipt_name: str):
    context.pos.relay_catalog.print_route_relay.set_receipt_active(receipts_available=context.pos.receipts_available, receipt_name=receipt_name, device_id=101, device_name='001 Receipt Printer')


@given('a {section} section {section_name} includes')
def step_impl(context: Context, section: str, section_name: str):
    new_receipt_sections_data, section_id = context.pos.relay_catalog.create_receipt_section(receipt_sections=context.pos.receipt_sections, section_name=section_name)
    line_number = 1
    for row in context.table:
        condition = row["condition"] if "condition" in row.headings else ''
        locale_specification = row["locale"] if "locale" in row.headings else ''
        variable_id = int(context.pos.relay_catalog.print_format_relay.find_variable_id(row["variable"])) if "variable" in row.headings else 0
        line = row["line"] if "line" in row.headings else None

        context.pos.relay_catalog.print_format_relay.set_receipt_section_content(section_id=section_id, section=section, locale_specification=locale_specification,
                                                                                 line=line, line_number=line_number, condition=condition, variable_id=variable_id)
        line_number = line_number + 1


@given('the following receipts are available')
def step_impl(context: Context):
    for row in context.table:
        receipt = row["receipt"] if "receipt" in row.headings else ''
        section = row["section"] if "section" in row.headings else ''

        context.pos.receipts_available = context.pos.relay_catalog.create_receipt(receipts_available=context.pos.receipts_available, receipt_sections=context.pos.receipt_sections, receipt=receipt, section=section)


@given('the Cash tender is configured to print twice')
def step_impl(context: Context):
    context.pos.relay_catalog.tender_relay.create_tender(description='Cash', device_control=135168)
# endregion


# region When clauses
@when('the cashier presses print receipt button')
def step_impl(context: Context):
    result = context.pos.print_and_wait_for_receipt()
    assert result, 'Receipt was not printed'
# endregion


# region Then clauses
@then('the receipt is printed with following lines')
def step_impl(context: Context):
    receipt = context.pos.get_latest_printed_receipt()
    list_of_lines = receipt.split('<br/>')
    tran = context.pos.get_transaction('current')
    if tran is None:
        tran = context.pos.get_transaction('previous')
    tran_date = tran.tran_end_time.strftime('%#m/%#d/%Y')
    tran_time = tran.tran_end_time.strftime('%#I:%M:%S %p')

    result = compare_receipts(context.table, list_of_lines, tran_date=tran_date,
                           tran_time=tran_time, tran_number=tran.sequence_number,
                           register_number=tran.terminal_id)
    # TODO
    # Hot fix, the receipt in scenario in pos_connect_print_receipt.feature
    # Scenario Outline: Send StoredOrder command to the POS with PrintReceipt variable and validate the receipt after the stored transaction is recalled, restored and printed
    # has current time, not the time of the original transaction.
    if not result:
        for delay in range(1,6):
            tran_time_inaccuracy = (tran.tran_end_time + datetime.timedelta(seconds=delay)).strftime('%#I:%M:%S %p')
            result = compare_receipts(context.table, list_of_lines, tran_date=tran_date,
                           tran_time=tran_time_inaccuracy, tran_number=tran.sequence_number,
                           register_number=tran.terminal_id)
            if result:
                break

    assert result, 'Receipts do not match'

@then('the previous receipt is printed with following lines')
def step_impl(context: Context):
    receipts = context.pos.get_all_printed_receipts()
    assert len(receipts) >= 2, 'Missing receipts, expected at least 2'
    receipt = receipts[-2]
    list_of_lines = receipt.split('<br/>')
    previous_tran = context.pos.get_transaction('previous')
    tran_date = previous_tran.tran_end_time.strftime('%#m/%#d/%Y')
    tran_time = previous_tran.tran_end_time.strftime('%#I:%M:%S %p')

    assert compare_receipts(context.table, list_of_lines, tran_date=tran_date,
                           tran_time=tran_time, tran_number=previous_tran.sequence_number,
                           register_number=previous_tran.terminal_id), 'Receipts do not match'


@then('the receipt is printed with following lines (plaintext)')
def step_impl(context: Context):
    receipt = context.pos.get_latest_printed_receipt()
    list_of_lines = receipt.split('<br/>')

    assert compare_receipts(context.table, list_of_lines, html=False), 'Receipts do not match'


@then('the receipt contains following lines')
def step_impl(context: Context):
    context.pos.print_receipt()
    receipt = context.pos.get_latest_printed_receipt()
    assert receipt != '', 'No receipt was printed'

    list_of_lines = receipt.split('<br/>')
    lines_missing = []
    for row in context.table.rows:
        if row[0] not in list_of_lines:
            lines_missing.append(row[0])

    assert not lines_missing, 'Following lines were not found in receipt:\n' + ''.join(lines_missing)


@then('the receipt does not contain following lines')
def step_impl(context: Context):
    context.pos.print_receipt()
    receipt = context.pos.get_latest_printed_receipt()
    assert receipt != '', 'No receipt was printed'

    list_of_lines = receipt.split('<br/>')
    lines_found = []
    for row in context.table.rows:
        if row[0] in list_of_lines:
            lines_found.append(row[0])

    assert not lines_found, 'Following lines were found in receipt:\n' + ''.join(lines_found)


@then('no receipt is printed')
def step_impl(context: Context):
    orig_count = context.pos.get_receipt_count()
    assert context.pos.wait_for_receipt_count_increase(orig_count, timeout=5) is False
# endregion
