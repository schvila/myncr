import json
from behave import *
from behave.runner import Context

from cfrpos.core.bdd_utils.comparers import contains_dict_subset, check_dict_contains_element_value, relax_dict_subset
from cfrpos.core.pos.ui_metadata import POSFrame


# region Given clauses
@given('the device {device} is in {device_state} state')
def step_impl(context: Context, device: str, device_state: str):
    # set device to some state, will be solved in Jira task RPOS-5517
    pass


@given('the POS does not need an update')
def step_impl(context: Context):
    context.pos.send_config()


@given('the POS needs an update')
def step_impl(context: Context):
    # ensure that POS needs an update, will be solved in Jira task RPOS-5516
    pass


@given('current transaction is stored under Stored Transaction Sequence Number')
def step_impl(context: Context):
    assert context.pos_connect.send_formatted_message('["Pos/StoreTransaction", {}]')
    context.pos_connect.last_stored_tran_number = context.pos_connect.last_response.data.get('StoredTransactionSequenceNumber')


@given('the application sent a |{request}| to the POS Connect to store a transaction under Transaction Sequence Number')
def step_impl(context: Context, request: str):
    context.execute_steps('''
        when the application sends |{formatted_message}| to the POS Connect
        '''.format(formatted_message=request))
    context.pos_connect.last_stored_tran_number = context.pos_connect.last_response.data.get('TransactionSequenceNumber')


@given('a transaction with item |{item_barcode}| is present in the Store and Recall queue')
def step_impl(context: Context, item_barcode: str):
    context.execute_steps('''
    given an item with barcode {barcode} is present in the transaction
    given current transaction is stored under Stored Transaction Sequence Number
    '''.format(barcode=item_barcode))


@given('the application sent |{request}| to the POS Connect')
def step_impl(context: Context, request: str):
    context.execute_steps('''
    when the application sends |{formatted_message}| to the POS Connect
    '''.format(formatted_message=request))


@given('the application sent {message} message with |{json_data}| payload to the POS Connect')
def step_impl(context: Context, message: str, json_data: str):
    context.execute_steps('''
    when the application sends {message} message with |{json_data}| payload to the POS Connect
    '''.format(message=message, json_data=json_data))


@given('the POS does not have any stored transactions')
def step_impl(context: Context):
    context.pos.delete_all_stored_transactions()


@given('an age restricted item with barcode {item_barcode} is present in the transaction after instant approval age verification through POSConnect')
def step_impl(context: Context, item_barcode: str):
    assert context.pos_connect.send_formatted_message('["Pos/SellItem", {{"Barcode": "{item_barcode}"}}]'.format(item_barcode=item_barcode)) is not None
    assert context.pos_connect.send_formatted_message('["Pos/DataNeededResponse", {"SelectedOperationName": "InstantApproval"}]') is not None
    assert context.pos.wait_for_item_added(item_barcode)


@given('an age restricted item with barcode {item_barcode} is present in the transaction after manual entry age verification through POSConnect')
def step_impl(context: Context, item_barcode: str):
    assert context.pos_connect.send_formatted_message('["Pos/SellItem", {{"Barcode": "{item_barcode}"}}]'.format(item_barcode=item_barcode)) is not None
    assert context.pos_connect.send_formatted_message('["Pos/DataNeededResponse", {"DataType": "Date", "Date": "06091985"}]') is not None
    assert context.pos.wait_for_item_added(item_barcode)


@given('the application sent a valid DL barcode to the POS Connect')
def step_impl(context: Context):
    formatted_message = '["Pos/DataNeededResponse",{"DataType": "Date","DateBarcode": "@\n\u001E\rAAMVA6360250101DL00290196DAQ29987353\nDAAJOHN SMITH            \nDAG1234 YOUR ROAD\nDAIPHILADELPHIA\nDAJPA\nDAK12345      \nDARC   \nDAS*/*             \nDAT---- \nDAU123\nDAYHAZ\nDBA20220320\nDBB19910728\nDBCM\nDBD20110121\nDBF00\nDBHY\r"}]'
    assert context.pos_connect.send_formatted_message(formatted_message) is not None


@given('the response data contain |{data_json}| after the application sent |{request}| to the POS Connect')
def step_impl(context: Context, data_json: str, request: str):
    context.execute_steps('''
    when the application sends |{request}| to the POS Connect
    then the POS Connect response code is 200
    and POS Connect response data contain |{data}|
    '''.format(request=request, data=data_json))


@given('the POS has following POSConnect age restriction behavior configured')
def step_impl(context: Context):
    for row in context.table:
        allow_processing = True if str(row["allow_processing"]).lower() in ['true', '1', 'yes'] else False
        context.pos.relay_catalog.define_order_source_behavior(external_id=row["OriginSystemId"], defer_verification=allow_processing)


@given('the POS displays Unknown Alt ID frame after sending the request |{formatted_message}|')
def step_impl(context: Context, formatted_message: str):
    context.execute_steps('''
    when the application sends |{request}| to the POS Connect
    then the POS displays Unknown Alt ID frame
    and the POS Connect message type is Pos/DataNeeded
    '''.format(request=formatted_message))


@given('the application sent RecallTransaction command with last stored Sequence Number to the POS Connect')
def step_impl(context: Context):
    context.execute_steps('''
    When the application sends RecallTransaction command with last stored Sequence Number to the POS Connect''')


@given('POS Connect response data contain |{data_json}|')
def step_impl(context: Context, data_json: str):
    context.execute_steps('''
     then POS Connect response data contain |{data_json}|
     '''.format(data_json=data_json))


@given('the POS Connect client uses version {version:d} standard')
def step_impl(context: Context, version: int):
    context.pos_connect.activate_version(version)
# endregion


# region When clauses
@when('the application sends RecallTransaction command with last stored Sequence Number to the POS Connect')
def step_impl(context: Context):
    sequence_number = context.pos_connect.last_stored_tran_number
    message = '["Pos/RecallTransaction", {{"TransactionSequenceNumber": {} }}]'.format(sequence_number)
    assert context.pos_connect.send_formatted_message(message) is not None


@when('the application sends ViewStoredOrders command with last stored order to the POS Connect')
def step_impl(context: Context):
    sequence_number = context.pos_connect.last_stored_tran_number
    message = '["Pos/ViewStoredOrders", {{"TransactionSequenceNumber": {} }}]'.format(sequence_number)
    assert context.pos_connect.send_formatted_message(message) is not None


@when('the application sends ViewStoredOrders command with non-existing transactionSequenceNumber ending with existing transactionSequenceNumber to the POS Connect')
def step_impl(context: Context):
    sequence_number = context.pos_connect.last_stored_tran_number
    message = '["Pos/ViewStoredOrders", {{"TransactionSequenceNumber": {}, "TransactionSequenceNumber": {} }}]'.format(844, sequence_number)
    assert context.pos_connect.send_formatted_message(message) is not None


@when('the application sends ViewStoredOrders command with existing transactionSequenceNumber ending with non-existing transactionSequenceNumber to the POS Connect')
def step_impl(context: Context):
    sequence_number = context.pos_connect.last_stored_tran_number
    message = '["Pos/ViewStoredOrders", {{"TransactionSequenceNumber": {}, "TransactionSequenceNumber": {} }}]'.format(sequence_number, 844)
    assert context.pos_connect.send_formatted_message(message) is not None


@when('the application sends RemoveStoredOrder command with the last stored transaction number to the POS')
def step_impl(context: Context):
    sequence_number = context.pos_connect.last_stored_tran_number
    message = '["Pos/RemoveStoredOrders", {{"TransactionList": [{{"TransactionSequenceNumber": {} }}]}}]'.format(sequence_number)
    assert context.pos_connect.send_formatted_message(message) is not None


@when('the application sends |{formatted_message}| to the POS Connect')
def step_impl(context: Context, formatted_message: str):
    assert context.pos_connect.send_formatted_message(formatted_message) is not None


@when('the application sends {message_name} message with |{payload}| payload to the POS Connect')
def step_impl(context: Context, message_name: str, payload: str):
    assert context.pos_connect.send_formatted_message(payload, message_name=message_name) is not None


@when('the application sends |{formatted_message}| to the POS Connect with the first reason for action |{select_reason_request}|')
def step_impl(context: Context, formatted_message: str, select_reason_request: str):
    assert context.pos_connect.send_formatted_message(formatted_message) is not None
    assert context.pos_connect.send_formatted_message(select_reason_request) is not None


@when('the application sends |{formatted_message}| to the POS Connect with the override request |{override_request}| and the first reason for action |{select_reason_request}|')
def step_impl(context: Context, formatted_message: str, override_request: str, select_reason_request: str):
    assert context.pos_connect.send_formatted_message(formatted_message) is not None
    assert context.pos_connect.send_formatted_message(override_request) is not None
    assert context.pos_connect.send_formatted_message(select_reason_request) is not None


@when('the application sends |{formatted_message}| to the POS Connect {repeat_times:n} times')
def step_impl(context: Context, formatted_message: str, repeat_times: int):
    if repeat_times < 0:
        assert False, 'Number of repeating can not be lower than 0'
    # TODO introduce more accurate check
    pass


@when('the application sends a valid DL barcode to the POS Connect')
def step_impl(context: Context):
    formatted_message = '["Pos/DataNeededResponse",{"DataType": "Date","DateBarcode": "@\n\u001E\rAAMVA6360250101DL00290196DAQ29987353\nDAAJOHN SMITH            \nDAG1234 YOUR ROAD\nDAIPHILADELPHIA\nDAJPA\nDAK12345      \nDARC   \nDAS*/*             \nDAT---- \nDAU123\nDAYHAZ\nDBA20220320\nDBB19910728\nDBCM\nDBD20110121\nDBF00\nDBHY\r"}]'
    assert context.pos_connect.send_formatted_message(formatted_message) is not None


@when('the application sends an underage DL barcode to the POS Connect')
def step_impl(context: Context):
    formatted_message = '["Pos/DataNeededResponse",{"DataType": "Date","DateBarcode": "@\n\u001E\rAAMVA7360190851DL00290196DAQ29987353\nDAAJOHN SMITH\nDAG1234 DUSTY LN\nDAISMALLVILLE\nDAJPA\nDAK16635      \nDARC   \nDAS*/*             \nDAT---- \nDAU951\nDAYHAZ\nDBA20360523\nDBB20050815\nDBCM\nDBD20120326\nDBF00\nDBHY\r"}]'
    assert context.pos_connect.send_formatted_message(formatted_message) is not None


@when('the application sends print request |{formatted_message}| to the POS Connect')
def step_impl(context: Context, formatted_message: str):
    orig_count = context.pos.get_receipt_count()
    assert context.pos_connect.send_formatted_message(formatted_message) is not None
    context.pos.wait_for_receipt_count_increase(orig_count, timeout=15)


@when('the application voids last loyalty transaction')
def step_impl(context: Context):
    loyalty_transaction_id = context.pos_connect.last_response.extract_loyalty_transaction_id()
    context.execute_steps('''
    when the application voids |{loyalty_transaction}| loyalty transaction
    '''.format(loyalty_transaction=loyalty_transaction_id))


@when('the application voids |{loyalty_id}| loyalty transaction')
def step_impl(context: Context, loyalty_id: str):
    context.execute_steps('''
    when the application sends |{formated_message}| to the POS Connect
    '''.format(formated_message='["Pos/VoidLoyaltyTransaction", {"LoyaltyType": "Sigma", "LoyaltyTransactionId" :"' + loyalty_id + '"}]'))

@when('the application sends |{request}| for last transaction')
def step_impl(context: Context, request: str):
    loyalty_transaction_id = context.pos_connect.last_response.extract_loyalty_transaction_id()
    context.execute_steps('''
        when the application sends |{request}| for transaction with loyalty |{loyalty_id}|
    '''.format(request=request, loyalty_id=loyalty_transaction_id))


@when('the application sends |{request}| for transaction with loyalty |{loyalty_id}|')
def step_impl(context: Context, request: str, loyalty_id: str):
    context.execute_steps('''
        when the application sends |{formated_message}| to the POS Connect
    '''.format(formated_message=request.format(loyalty_id=loyalty_id)))


@when('the application sends |{request}| with PosConnect-RequestId from previous response in the header')
def step_impl(context: Context, request: str):
    request_id = context.pos_connect.last_response.extract_request_id()
    assert context.pos_connect.send_formatted_message(request, 30, request_id) is not None

# endregion


# region Then clauses
@then('the POS Connect response code is {code:n}')
def step_impl(context: Context, code: int):
    assert context.pos_connect.last_response.code == int(code),\
            'Expected code {} in a response {}'.format(code, context.pos_connect.last_response)


@then('the POS Connect message type is {message}')
def step_impl(context: Context, message: str):
    assert context.pos_connect.last_response.message == message,\
            'Expected message "{}" in a response {}'.format(message, context.pos_connect.last_response)


@then('POS Connect response data are |{data_json}|')
def step_impl(context: Context, data_json: str):
    """
    Checks for every object in data_json where every value must match the response exactly.
    Can be relaxed with '*'.
    """
    expected_data = json.loads(data_json)
    last_response = context.pos_connect.last_response

    not_found = contains_dict_subset(expected_data, last_response.data)
    assert not_found == {}, 'Not found key-values "{}" in a response {}'.format(not_found, last_response)


@then('POS Connect response data does not contain |{data_json}|')
def step_impl(context: Context, data_json: str):
    """
    Checks for every object in data_json, where the response can have more nested values.
    Values for keys can be relaxed with '*'.
    """
    expected_data = json.loads(data_json)
    relax_dict_subset(expected_data)
    last_response = context.pos_connect.last_response
    found = contains_dict_subset(expected_data, last_response.data)
    assert found != {}, 'Found key-values "{}" in a response {}'.format(found, last_response)


@then('POS Connect response data contain |{data_json}|')
def step_impl(context: Context, data_json: str):
    """
    Checks for every object in data_json, where the response can have more nested values.
    Values for keys can be relaxed with '*'.
    """
    expected_data = json.loads(data_json)
    relax_dict_subset(expected_data)
    last_response = context.pos_connect.last_response
    not_found = contains_dict_subset(expected_data, last_response.data)
    assert not_found == {}, 'Not found key-values "{}" in a response {}'.format(not_found, last_response)


@then('the POS Connect response data does not contain element {element} with value {value}')
def step_impl(context: Context, element: str, value: str):
    expected_data, not_found = check_dict_contains_element_value(element, value, context.pos_connect.last_response)
    assert not_found == expected_data, 'Found key-values "{}" in a response {}'.format(expected_data, context.pos_connect.last_response)


@then('the POS Connect response data does not contain element {element}')
def step_impl(context: Context, element: str):
    """
    Verifies that response does NOT contain provided element
    Searches recursively through nested objects.
    """
    expected_data = {element: '*'}
    not_found = contains_dict_subset(expected_data , context.pos_connect.last_response)
    assert not_found != {}, 'Found key-values "{}" in a response {}'.format(expected_data, context.pos_connect.last_response)


@then('the POS Connect response data contain element {element} with value {value}')
def step_impl(context: Context, element: str, value: str):
    """
    Checks for element with number or string value in a response.
    If value does not matter, use with wildcard *.
    Searches recursively through nested objects.
    """
    expected_data, not_found = check_dict_contains_element_value(element, value, context.pos_connect.last_response)
    assert not_found == {}, 'Not found key-values "{}" in a response {}'.format(not_found, context.pos_connect.last_response)


@then('the POS Connect response transaction data contain an item with type {item_type} and description {description}'
      ' and amount {amount:f} and quantity {quantity:n}')
def step_impl(context: Context, item_type: str, description: str, amount: float, quantity: int):
    last_response = context.pos_connect.last_response
    assert 'TransactionData' in last_response.data,\
            'Field TransactionData not found in a response {}'.format(last_response)
    transaction_data = last_response.data['TransactionData']
    assert 'ItemList' in transaction_data, 'Field ItemList not found in {}'.format(last_response)
    items = transaction_data.get('ItemList', [])
    for item in items:
        if item.get('Type', '') == item_type \
                and item.get('Description', '') == description \
                and item.get('ExtendedPriceAmount', float(0)) == float(amount) \
                and item.get('Quantity', 0) == int(quantity):
            return
    assert False, 'Item "{}" not found in a response {}'.format(description, last_response)


@then('the POS Connect response message {response_message} with response code {code:n} is received for all {requests_count:n} requests')
def step_impl(context: Context, response_message: str, code: int, requests_count: int):
    # TODO introduce valid check
    pass


@then('the POS Connect response tells that the device {device} is in {device_state} state')
def step_impl(context: Context, device: str, device_state: str):
    if device_state.lower() == "online":
        assert context.pos_connect.is_device_online(device)
    elif device_state.lower() == "offline":
        assert not context.pos_connect.is_device_online(device)
    else:
        assert False, 'Device state "{}" is not a valid state.'.format(device_state)


@then('the POS Connect response tells that the POS is in {state} state')
def step_impl(context: Context, state: str):
    if state.lower() == 'locked':
        assert context.pos_connect.last_response.data.get('State') == 'Locked'
    elif state.lower() == 'ready':
        assert context.pos_connect.last_response.data.get('State') == 'Ready'
    else:
        assert False, 'Device state "{}" is not a valid state.'.format(state)


@then('the transaction is stored with StoredTransactionSequenceNumber')
def step_impl(context: Context):
    assert 'StoredTransactionSequenceNumber' in context.pos_connect.last_response.data.keys()
    assert context.pos_connect.last_response.data.get('StoredTransactionSequenceNumber') > 0
    # TODO introduce more accurate check of tran number


@then('the POS is updated')
def step_impl(context: Context):
    context.pos_connect.send_formatted_message('["Pos/GetState", {}]')
    message = context.pos_connect.last_response
    assert not message.data.get('IsUpdateRequired')


@then('the decoded type is {decoded_type}')
def step_impl(context: Context, decoded_type: str):
    message = context.pos_connect.last_response
    assert message.data.get('DecodedType').lower() == decoded_type.lower()


@then('the POS Connect response for update required is {is_update_required}')
def step_impl(context: Context, is_update_required: str):
    message = context.pos_connect.last_response
    assert str(message.data.get('IsUpdateRequired')).lower() == is_update_required.lower()


@then('the last stored transaction is removed from the store recall queue')
def step_impl(context: Context):
    sequence_number = context.pos_connect.last_stored_tran_number
    message = '["Pos/RecallTransaction", {{"TransactionSequenceNumber": {} }}]'.format(sequence_number)
    context.pos_connect.send_formatted_message(message)
    response = context.pos_connect.last_response
    assert response.data.get('ReturnCode') == 1035


@then('the POS notifies KPS about pending age verification of {age} years')
def step_impl(context: Context, age: int):
    expected_msg = 'Check ID - Minimum age required is {0}'.format(age)
    response = context.kps_sim.get_age_restriction_msg()
    assert expected_msg == response


@then('the POS does not notify KPS about pending age verification')
def step_impl(context: Context):
    assert 'Check ID - Minimum age required' not in context.kps_sim.get_age_restriction_msg()
