@pos @pos_connect
Feature: This feature introduces the ability to cancel DataNeeded requests from POS, not just by a posconnect response.
    - If the DataNeeded cancel happens by posconnect, 'RequestId' field can be found in the response header.
    - If the DataNeeded cancel happens by POS interaction, 'RequestId' can be obtained by sending a GetState request.

    Background: The POS needs to have some items configured to manipulate with them.
        Given the POS has essential configuration
        And the POS has the feature PosApiServer enabled
        And the pricebook contains department sale items
        | description  | price | barcode | item_id      | modifier1_id | item_type | item_mode |
        | Dept 99 Sale | 5     | 9099    | 990000000016 | 990000000003 | 11        | 2         |


    @fast
    Scenario Outline: DataNeeded request asking for amount answered by POSConnect, GetState response does not contain RequestId
        Given the POS is in a ready to sell state
        And the application sent |<request>| to the POS Connect
        And the POS displays Enter amount frame
        And the application sent |<dataneeded_response>| to the POS Connect
        And POS Connect response data contain |<response_data>|
        When the application sends |["Pos/GetState", {}]| to the POS Connect
        Then POS Connect response data does not contain |{"Messages": [{"Payload": {"RequestId":"*"}, "TopicId": "posconnect-v1-data-needed-cancelled"}]}|

        Examples:
        | request                              | dataneeded_response                                                    | response_data                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
        | ["Pos/SellItem",{"Barcode": "9099"}] | ["Pos/DataNeededResponse",{"DataType": "Amount", "NumericData": 1.00}] | {"TransactionData": {"ItemList": [{"Description": "Dept 99 Sale", "ExtendedPriceAmount": 1.0, "ExternalId": "ITT-9099-4-1", "FractionalQuantity": 1.0, "ItemNumber": 1, "POSItemId": 990000000016, "POSModifier1Id": 990000000003, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 1.0}], "TransactionBalance": 1.0, "TransactionSubTotal": 1.0, "TransactionTaxAmount": 0.0, "TransactionTotal": 1.0}, "TransactionSequenceNumber": "*"} |


    @fast
    Scenario Outline: DataNeeded request asking for amount answered by POSConnect and the request is cancelled by POSConnect, GetState response does not contain RequestId
        Given the POS is in a ready to sell state
        And the application sent |<request>| to the POS Connect
        And the POS displays Enter amount frame
        And the application sent |<dataneeded_response>| to the POS Connect
        And POS Connect response data contain |<response_data>|
        When the application sends |["Pos/GetState", {}]| to the POS Connect
        Then POS Connect response data does not contain |{"Messages": [{"Payload": {"RequestId":"*"}, "TopicId": "posconnect-v1-data-needed-cancelled"}]}|

        Examples:
        | request                              | dataneeded_response                                                    | response_data                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
        | ["Pos/SellItem",{"Barcode": "9099"}] | ["Pos/DataNeededResponse",{"SelectedOperationName":"Cancel" }]         | {"ReturnCode":1016,"ReturnCodeDescription":"Operation was cancelled.","TransactionSequenceNumber":"*"}                                                                                                                                                                                                                                                                                                                                                                                   |


    @fast
    Scenario Outline: DataNeeded request asking for amount which is cancelled by input on POS, GetState response contains RequestId
        Given the POS is in a ready to sell state
        And the application sent |<request>| to the POS Connect
        And the POS displays Enter amount frame
        And the cashier entered 1.00 dollar amount in Ask enter dollar amount frame
        When the application sends |<getstate_request>| to the POS Connect
        Then POS Connect response data contain |{"Messages": [{"Payload": {"RequestId":"*"}, "TopicId": "posconnect-v1-data-needed-cancelled"}]}|

        Examples:
        | request                              | getstate_request     |
        | ["Pos/SellItem",{"Barcode": "9099"}] | ["Pos/GetState", {}] |


    @fast
    Scenario Outline: DataNeeded request asking for amount is cancelled by input on POS and then is finished by POSConnect, GetPendingResult request, with RequestId from previous response added into header, returns a final transaction data
        Given the POS is in a ready to sell state
        And the application sent |<request>| to the POS Connect
        And the POS displays Enter amount frame
        And the cashier entered 1.00 dollar amount in Ask enter dollar amount frame
        And the application sent |<getstate_request>| to the POS Connect
        And POS Connect response data contain |{"Messages": [{"Payload": {"RequestId":"*"}, "TopicId": "posconnect-v1-data-needed-cancelled"}]}|
        When the application sends |<pendingresult_request>| with PosConnect-RequestId from previous response in the header
        Then POS Connect response data contain |<response_data>|

        Examples:
        | request                              | getstate_request     | pendingresult_request          | response_data                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
        | ["Pos/SellItem",{"Barcode": "9099"}] | ["Pos/GetState", {}] | ["Server/GetPendingResult",{}] |  {"TransactionData": {"ItemList": [{"Description": "Dept 99 Sale", "ExtendedPriceAmount": 1.0, "ExternalId": "ITT-9099-4-1", "FractionalQuantity": 1.0, "ItemNumber": 1, "POSItemId": 990000000016, "POSModifier1Id": 990000000003, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 1.0}], "TransactionBalance": 1.0, "TransactionSubTotal": 1.0, "TransactionTaxAmount": 0.0, "TransactionTotal": 1.0}, "TransactionSequenceNumber": "*"} |
