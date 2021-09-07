@pos @pos_connect
Feature: POS Connect v3
    Most notable changes in v3 is that URI and content is standardized and follows the OpenAPI specification rules
    to provide easy to understand messaging. All messages use the HTTP POST method and HTTP version 1.1 is supported.

    http://{pos-connect-server}:{port}{prefix}/api/v3/{message-name}

    The /api/v3 defines that the caller wants to communicate using the version 3 which requires a message name being
    part of the URI. The {message-name} must match the message name as defined in the message specification.
    The request body has to be JSON object matching the format as defined in the message specification.

    Actors
    * application: an application which uses the POS Connect
    * POS: a POS application
    * POS Connect: a POS Connect server

    Background: POS is ready to sell and no transaction is in progress
        Given the POS has essential configuration
        And the POS has the feature PosApiServer enabled
        And the POS Connect client uses version 3 standard
        # "Age verification failure tracking" option set to "NO"
        And the POS option 1024 is set to 0
        And the POS has following sale items configured
              | barcode       | description    | price  | external_id          | internal_id                   |
              | 099999999990  | Sale Item A    | 0.99   | ITT-099999999990-0-1 | 990000000002-990000000007-0-0 |
              | 088888888880  | Sale Item B    | 1.99   | ITT-088888888880-0-1 | 990000000003-990000000007-0-0 |
              | 055555555550  | Container Item | 1.29   | ITT-055555555550-0-1 | 990000000006-990000000007-0-0 |
              | 0369369369 | Age 18 Restricted | 3.69   | ITT-0369369369-0-1   |                               |
              | 404  | Deposit (for Container) | 0.05   | ITT-404-4-0          | 990000000013-990000000004-0-0 |


    @positive @fast
    Scenario Outline: Send GetState command to POS and validate the response.
        Given the POS is in a ready to sell state
        When the application sends Pos/GetState message with |{}| payload to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|

        Examples:
        | response_data |
        | {"DeviceStates": {"ElectronicPayment": {"IsConfigured": "*", "IsOnline": "*"}, "Pinpad": {"IsOnline": "*"}, "ReceiptPrinter": {"IsOnline": "*"}, "SiteController": {"IsOnline": "*"}}, "IsCashAlertActive": "*", "IsPaymentAvailable": "*", "IsUpdateRequired": "*", "NodeNumber": "*", "Shift": {"CurrentBusinessDay": "*", "IsManualShiftFlow": "*", "IsShiftOpened": "*", "NewBusinessDay": "*"}, "State": "Ready", "TransactionSequenceNumber": "*"} |


    @positive @fast
    Scenario Outline: Send GetState command to POS and validate the POS state in the response.
        Given the POS is set to <state> state
        When the application sends Pos/GetState message with |{}| payload to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect response tells that the POS is in <state> state

        Examples:
        | state        |
        | Locked       |
        | Ready        |


    @positive @fast
    Scenario Outline: Add some items to the transaction and send GetTransaction command, validate the POSAPI response.
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction <item_count> times
        When the application sends Pos/GetTransaction message with |{}| payload to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|

        Examples:
        | item_barcode | item_count | response_data |
        | 099999999990 | 1          | {"TransactionTaxAmount": 0.07, "TransactionTotal": 1.06, "TransactionSequenceNumber": "*", "ItemList": [{"Description": "Sale Item A", "ExternalId": "ITT-099999999990-0-1", "ExtendedPriceAmount": 0.99, "POSModifier1Id": 990000000007, "ItemNumber": 1, "Type": "Regular", "POSModifier2Id": 0, "Quantity": 1, "POSModifier3Id": 0, "POSItemId": 990000000002, "UnitPriceAmount": 0.99}], "TransactionBalance": 1.06, "TransactionSubTotal": 0.99} |
        | 088888888880 | 2          | {"TransactionTaxAmount": 0.28, "TransactionTotal": 4.26, "TransactionSequenceNumber": "*", "ItemList": [{"Description": "Sale Item B", "ExternalId": "ITT-088888888880-0-1", "ExtendedPriceAmount": 1.99, "POSModifier1Id": 990000000007, "ItemNumber": 1, "Type": "Regular", "POSModifier2Id": 0, "Quantity": 1, "POSModifier3Id": 0, "POSItemId": 990000000003, "UnitPriceAmount": 1.99}, {"Description": "Sale Item B", "ExternalId": "ITT-088888888880-0-1", "ExtendedPriceAmount": 1.99, "POSModifier1Id": 990000000007, "ItemNumber": 2, "Type": "Regular", "POSModifier2Id": 0, "Quantity": 1, "POSModifier3Id": 0, "POSItemId": 990000000003, "UnitPriceAmount": 1.99}], "TransactionBalance": 4.26, "TransactionSubTotal": 3.98} |
        | 055555555550 | 1          | {"TransactionTaxAmount": 0.09, "TransactionTotal": 1.43, "TransactionSequenceNumber": "*", "ItemList": [{"Description": "Container Item", "ExternalId": "ITT-055555555550-0-1", "POSModifier2Id": 0, "ExtendedPriceAmount": 1.29, "ItemNumber": 1, "ItemList": [{"Description": "Deposit (for Container)", "ExternalId": "ITT-404-4-0", "ExtendedPriceAmount": 0.05, "POSModifier1Id": 990000000004, "ItemNumber": 2, "Type": "ContainerDeposit", "POSModifier2Id": 0, "Quantity": 1, "POSModifier3Id": 0, "POSItemId": 990000000013, "UnitPriceAmount": 0.05}], "Type": "Regular", "POSModifier1Id": 990000000007, "Quantity": 1, "POSModifier3Id": 0, "POSItemId": 990000000006, "UnitPriceAmount": 1.29}], "TransactionBalance": 1.43, "TransactionSubTotal": 1.34} |


    @positive @fast
    Scenario Outline: Send AddTender command, validate that the tender is in current transaction.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction 5 times
        When the application sends Pos/AddTender message with |<json_payload>| payload to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And a tender <tender_name> with amount <tender_amount> is in the virtual receipt
        And a tender <tender_name> with amount <tender_amount> is in the current transaction

        Examples:
        | json_payload                                        | tender_name | tender_amount | response_data |
        | {"TenderExternalId": "70000000023", "Amount": 1.00} | Cash        | 1.00          | {"TransactionData": {"TransactionSubTotal": 4.95, "TransactionBalance": 4.3, "TransactionTotal": 5.3, "TransactionTaxAmount": 0.35, "ItemList": [{"ExtendedPriceAmount": 4.95, "POSModifier3Id": 0, "Type": "Regular", "Quantity": 5, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "ItemNumber": 1, "Description": "Sale Item A", "ExternalId": "ITT-099999999990-0-1", "POSModifier2Id": 0, "UnitPriceAmount": 0.99}, {"ExtendedPriceAmount": -1.0, "Quantity": 1, "Type": "Tender", "ItemNumber": 6, "Description": "Cash", "ExternalId": "70000000023"}]}, "TransactionSequenceNumber": "*", "TenderAmount": 1.0} |


    @positive @fast
    Scenario: Send GetPumpState command and check the state of the pumps.
        Given the POS is in a ready to sell state
        And the POS has following pumps configured:
            | fueling_point |
            | 1             |
            | 2             |
            | 3             |
            | 4             |
        When the application sends Pos/GetPumpState message with |{}| payload to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |{"PumpList": [{"IsStackedSalesFull": false, "PumpNumber": 1, "State": "Idle", "HoseList": "*"}, {"IsStackedSalesFull": false, "PumpNumber": 2, "State": "Idle", "HoseList": "*"}, {"IsStackedSalesFull": false, "PumpNumber": 3, "State": "Idle", "HoseList": "*"}, {"IsStackedSalesFull": false, "PumpNumber": 4, "State": "Idle", "HoseList": "*"}], "TransactionSequenceNumber": "*"}|


    @positive @fast @smoke
    Scenario: Send GetVersion command to the POS, response contains the current API version and the POS version.
        Given the POS is in a ready to sell state
        When the application sends Server/GetVersion message with |{}| payload to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |{"APIVersion": "3.0.3", "POSVersion": "*"}|


    @positive @fast
    Scenario Outline: Send SellItem command to the POS, item is added to transaction, response contains transaction details.
        Given the POS is in a ready to sell state
        When the application sends Pos/SellItem message with |<json_payload>| payload to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And an item <item_name> with price <item_total> and quantity <item_quantity> is in the virtual receipt
        And an item <item_name> with price <item_total> and quantity <item_quantity> is in the current transaction

    Examples:
    | json_payload                               | item_name   | item_total | item_quantity | response_data |
    | {"Barcode": "099999999990", "Quantity": 1} | Sale Item A | 0.99       | 1             | {"TransactionData": {"ItemList": [{"Description": "Sale Item A", "ExtendedPriceAmount": 0.99, "ExternalId": "ITT-099999999990-0-1", "ItemNumber": 1, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "TransactionBalance": 1.06, "TransactionSubTotal": 0.99, "TransactionTaxAmount": 0.07, "TransactionTotal": 1.06}, "TransactionSequenceNumber": "*"} |
    | {"Barcode": "099999999990", "Quantity": 4} | Sale Item A | 3.96       | 4             | {"TransactionData": {"TransactionSubTotal": 3.96, "TransactionBalance": 4.24, "TransactionTotal": 4.24, "TransactionTaxAmount": 0.28, "ItemList": [{"ExtendedPriceAmount": 3.96, "POSModifier3Id": 0, "Type": "Regular", "Quantity": 4, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "ItemNumber": 1, "Description": "Sale Item A", "ExternalId": "ITT-099999999990-0-1", "POSModifier2Id": 0, "UnitPriceAmount": 0.99}]}, "TransactionSequenceNumber": "*"} |


    @positive @fast
    Scenario Outline: Send StoreOrder command to the POS with no transaction in progress and validate the response.
        Given the POS is in a ready to sell state
        When the application sends Pos/StoreOrder message with |<json_payload>| payload to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|

        Examples:
        | json_payload | response_data |
        | {"OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [ {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4 }, {"RposId": "990000000002-990000000007-0-0", "Quantity": 2} ] } | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 7.96, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 1.99}, {"Description": "Sale Item A", "ExtendedPriceAmount": 1.98, "ExternalId": "ITT-099999999990-0-1", "ItemNumber": 2, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 2, "Type": "Regular", "UnitPriceAmount": 0.99}, {"Description": "Hammer City Tax", "ExtendedPriceAmount": 0.1, "RposId": "101-0-0-0", "Type": "Tax"}, {"Description": "Hammer County Tax", "ExtendedPriceAmount": 0.2, "RposId": "102-0-0-0", "Type": "Tax"}, {"Description": "Hammer State Tax", "ExtendedPriceAmount": 0.4, "RposId": "103-0-0-0", "Type": "Tax"}], "OriginSystemId": "ForeCourt", "TransactionBalance": 10.64, "TransactionSequenceNumber": "*", "TransactionSubTotal": 9.94, "TransactionTaxAmount": 0.7, "TransactionTotal": 10.64} |


    @positive @fast
    Scenario Outline: Send FinalizeOrder command to the POS with no transaction in progress and validate the Standard Response.
                      UnitPriceAmount and/or ExtendedPriceAmount can be used for items in ItemList to specify price, ExtendedPriceAmount has priority if different.
        Given the POS is in a ready to sell state
        When the application sends Pos/FinalizeOrder message with |<json_payload>| payload to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|

        Examples:
        | json_payload     | response_data |
        | {"OriginReferenceId": "", "CustomerName": "Test Customer Name", "ItemList": [{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2}, {"RposId": "990000000002-990000000007-0-0", "Quantity": 2}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 5.96} ]} | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 3.98, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 1.99}, {"Description": "Sale Item A", "ExtendedPriceAmount": 1.98, "ExternalId": "ITT-099999999990-0-1", "ItemNumber": 2, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 2, "Type": "Regular", "UnitPriceAmount": 0.99}, {"Description": "Cash", "ExtendedPriceAmount": -5.96, "ExternalId": "70000000023", "ItemNumber": 3, "Quantity": 1, "RequestItemNumber": 3, "Type": "Tender"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 5.96, "TransactionTaxAmount": 0.0, "TransactionTotal": 5.96} |
        | {"OriginReferenceId": "", "CustomerName": "Test Customer Name", "ItemList": [{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2, "UnitPriceAmount": 1.05}, {"RposId": "990000000002-990000000007-0-0", "Quantity": 2, "ExtendedPriceAmount": 2.50}, {"RposId": "990000000002-990000000007-0-0", "Quantity": 2, "UnitPriceAmount": 1.25,"ExtendedPriceAmount": 2.50}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 7.1} ]} | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 2.1, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 1.05}, {"Description": "Sale Item A", "ExtendedPriceAmount": 5.00, "ExternalId": "ITT-099999999990-0-1", "ItemNumber": 2, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4, "RequestItemNumber": 2, "Type": "Regular", "UnitPriceAmount": 1.25}, {"Description": "Cash", "ExtendedPriceAmount": -7.1, "ExternalId": "70000000023", "ItemNumber": 4, "Quantity": 1, "RequestItemNumber": 4, "Type": "Tender"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 7.1, "TransactionTaxAmount": 0.0, "TransactionTotal": 7.1} |
        | {"OriginReferenceId": "", "CustomerName": "Test Customer Name", "ItemList": [{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2, "UnitPriceAmount": 0.1, "ExtendedPriceAmount": 1.98}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 1.98} ]} | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 1.98, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 0.99}, {"Description": "Cash", "ExtendedPriceAmount": -1.98, "ExternalId": "70000000023", "ItemNumber": 2, "Quantity": 1, "RequestItemNumber": 2, "Type": "Tender"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 1.98, "TransactionTaxAmount": 0.0, "TransactionTotal": 1.98} |


    @positive @fast
    Scenario Outline: Send FinalizeOrder command with autocombo to the POS, validate the autocombo is present in the response.
        Given the pricebook contains autocombos
              | description         | external_id | reduction_value | disc_type           | disc_mode         | disc_quantity | item_name   | quantity |
              | MyAutocombo         | 12345       | 10000           | AUTO_COMBO_AMOUNT   | WHOLE_TRANSACTION | STACKABLE     | Sale Item B | 1        |
        And the POS is in a ready to sell state
        When the application sends Pos/FinalizeOrder message with |<json_payload>| payload to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<autocombo_response>|

        Examples:
        | autocombo_response | json_payload |
        | {"Description": "MyAutocombo", "DiscountType": "AutoCombo", "ExtendedPriceAmount": -10.0, "ItemNumber": 8, "Quantity": 10, "ReductionList": [{"Description": "MyAutocombo", "DiscountedItemNumber": 1, "ExtendedPriceAmount": -1.0, "ExternalId": "12345", "ItemNumber": 5, "Quantity": 1, "RposId": "990000000050-0-0-0", "Type": "Discount", "UnitPriceAmount": -1.0}], "RequestItemNumber": 2, "RposId": "990000000050-0-0-0", "Type": "Discount", "UnitPriceAmount": -1.0} | {"OriginSystemId": "Batch-test", "ItemList": [{"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 10}, {"Type": "AutoCombo", "ExternalId": "12345", "Quantity": 10, "ReductionList": [{"ExternalId": "12345", "Type": "Discount", "Quantity": 1, "Amount": 1.00, "DiscountedItemNumber": 1}]}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 10.6, "BatchNumber": 90, "BatchSequenceNumber": 654}, {"Type": "Tax", "ExternalId": "103", "Amount": 0.4}, {"Type": "Tax", "ExternalId": "102", "Amount": 0.2}, {"Type": "Tax", "ExternalId": "101", "Amount": 0.1}]} |


    @negative @fast
    Scenario Outline: Send a locked item in an ItemList batch through various requests, validate that a proper error
                      code is returned even when other valid items are in the request as well.
        Given the POS has following sale items locked
            | barcode      | description | price  | item_id      | modifier1_id |
            | 099999999990 | Sale Item A | 0.99   | 990000000002 | 990000000007 |
            | 088888888880 | Sale Item B | 1.99   | 990000000003 | 990000000007 |
            | 077777777770 | Sale Item C | 1.49   | 990000000004 | 990000000007 |
        And the POS is in a ready to sell state
        When the application sends <message> message with |<json_payload>| payload to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|

        Examples:
        | message           | json_payload | response_data |
        | Pos/SellItem      | {"Barcode": "099999999990", "Quantity": 1} | {"ReturnCode": 1108, "ReturnCodeDescription": "Item is locked.", "TransactionSequenceNumber": "*"} |
        | Pos/SubTotalOrder | {"ItemList": [{"ExternalId": "ITT-099999999990-0-1", "Quantity": 1}, {"Barcode": "077777777770", "Quantity": 1}, {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1}, {"Barcode": "066666666660", "Quantity": 1}]} | {"ItemList": [{"ExternalId": "ITT-099999999990-0-1", "POSItemId": 0, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 1, "ReturnCode": 1108, "ReturnCodeDescription": "Item is locked."}, {"Barcode": "077777777770", "POSItemId": 0, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 2, "ReturnCode": 1108, "ReturnCodeDescription": "Item is locked."}, {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 3, "ReturnCode": 1108, "ReturnCodeDescription": "Item is locked."}, {"Description": "Sale Item D", "ExtendedPriceAmount": 2.39, "ExternalId": "ITT-066666666660-0-1", "ItemNumber": 1, "POSItemId": 990000000005, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "RequestItemNumber": 4, "Type": "Regular", "UnitPriceAmount": 2.39}, {"Description": "Hammer City Tax", "ExtendedPriceAmount": 0.02, "RposId": "101-0-0-0", "Type": "Tax"}, {"Description": "Hammer County Tax", "ExtendedPriceAmount": 0.05, "RposId": "102-0-0-0", "Type": "Tax"}, {"Description": "Hammer State Tax", "ExtendedPriceAmount": 0.1, "RposId": "103-0-0-0", "Type": "Tax"}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 2.56, "TransactionSequenceNumber": "*", "TransactionSubTotal": 2.39, "TransactionTaxAmount": 0.17, "TransactionTotal": 2.56} |
        | Pos/StoreOrder    | {"ItemList": [{"ExternalId": "ITT-099999999990-0-1", "Quantity": 1}, {"Barcode": "077777777770", "Quantity": 1}, {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1}, {"Barcode": "066666666660", "Quantity": 1}]} | {"ItemList": [{"ExternalId": "ITT-099999999990-0-1", "POSItemId": 0, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 1, "ReturnCode": 1108, "ReturnCodeDescription": "Item is locked."}, {"Barcode": "077777777770", "POSItemId": 0, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 2, "ReturnCode": 1108, "ReturnCodeDescription": "Item is locked."}, {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 3, "ReturnCode": 1108, "ReturnCodeDescription": "Item is locked."}, {"Description": "Sale Item D", "ExtendedPriceAmount": 2.39, "ExternalId": "ITT-066666666660-0-1", "ItemNumber": 1, "POSItemId": 990000000005, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "RequestItemNumber": 4, "Type": "Regular", "UnitPriceAmount": 2.39}, {"Description": "Hammer City Tax", "ExtendedPriceAmount": 0.02, "RposId": "101-0-0-0", "Type": "Tax"}, {"Description": "Hammer County Tax", "ExtendedPriceAmount": 0.05, "RposId": "102-0-0-0", "Type": "Tax"}, {"Description": "Hammer State Tax", "ExtendedPriceAmount": 0.1, "RposId": "103-0-0-0", "Type": "Tax"}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 2.56, "TransactionSequenceNumber": "*", "TransactionSubTotal": 2.39, "TransactionTaxAmount": 0.17, "TransactionTotal": 2.56} |
        | Pos/FinalizeOrder | {"ItemList": [{"ExternalId": "ITT-099999999990-0-1", "Quantity": 1}, {"Barcode": "077777777770", "Quantity": 1}, {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1}, {"Barcode": "066666666660", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 6.86}]} | {"ItemList": [{"ExternalId": "ITT-099999999990-0-1", "POSItemId": 0, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 1, "ReturnCode": 1108, "ReturnCodeDescription": "Item is locked."}, {"Barcode": "077777777770", "POSItemId": 0, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 2, "ReturnCode": 1108, "ReturnCodeDescription": "Item is locked."}, {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 3, "ReturnCode": 1108, "ReturnCodeDescription": "Item is locked."}, {"Description": "Sale Item D", "ExtendedPriceAmount": 2.39, "ExternalId": "ITT-066666666660-0-1", "ItemNumber": 1, "POSItemId": 990000000005, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "RequestItemNumber": 4, "Type": "Regular", "UnitPriceAmount": 2.39}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 2.39, "TransactionSequenceNumber": 0, "TransactionSubTotal": 2.39, "TransactionTaxAmount": 0.0, "TransactionTotal": 2.39} |


    @positive @fast
    Scenario Outline: Send SellItem command to the POS for an Age restricted item, validate the DataNeeded Response, Age verification frame is displayed
        Given the POS is in a ready to sell state
        When the application sends Pos/SellItem message with |{"Barcode": "0369369369"}| payload to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS displays the Age verification frame

        Examples:
        | response_data                             |
        | {"DataNeeded": {"AvailableOperations": [{"Name": "Cancel", "Text": ""}, {"Name": "InstantApproval", "Text": "Over"}], "DataNeededId": "*", "DataType": "Date", "PromptId": 5072, "PromptText": "Enter Customer's Birthday (MM/DD/YYYY)"}} |


    @positive @fast
    Scenario Outline: Send DataNeededResponse command to the POS with a valid birthday format (YYYY-MM-DD or MMDDYYYY)
                      after attempting to sell an Age restricted item, validate the response, item is added to the transaction
        Given the POS is in a ready to sell state
        And the application sent Pos/SellItem message with |{"Barcode": "0369369369"}| payload to the POS Connect
        When the application sends Pos/DataNeededResponse message with |<json_payload>| payload to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS displays main menu frame
        And an item <item_description> with price <item_price> is in the current transaction

        Examples:
        | json_payload                               | item_description  | item_price | response_data                             |
        | {"DataType": "Date", "Date": "06091985"}   | Age 18 Restricted | 3.69       | {"TransactionData": {"ItemList": [{"Description": "Age 18 Restricted", "ExtendedPriceAmount": 3.69, "ExternalId": "ITT-0369369369-0-1", "ItemNumber": 1, "POSItemId": 990000000010, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 3.69}], "TransactionBalance": 3.95, "TransactionSubTotal": 3.69, "TransactionTaxAmount": 0.26, "TransactionTotal": 3.95}, "TransactionSequenceNumber": "*"}|
        | {"DataType": "Date", "Date": "1985-06-09"} | Age 18 Restricted | 3.69       | {"TransactionData": {"ItemList": [{"Description": "Age 18 Restricted", "ExtendedPriceAmount": 3.69, "ExternalId": "ITT-0369369369-0-1", "ItemNumber": 1, "POSItemId": 990000000010, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 3.69}], "TransactionBalance": 3.95, "TransactionSubTotal": 3.69, "TransactionTaxAmount": 0.26, "TransactionTotal": 3.95}, "TransactionSequenceNumber": "*"}|


    @positive @fast
    Scenario Outline: Send DataNeededResponse command to the POS with an instant approval operation after attempting to
                      sell an Age restricted item, validate the response, item is added to the transaction
        Given the POS is in a ready to sell state
        And the application sent Pos/SellItem message with |{"Barcode": "0369369369"}| payload to the POS Connect
        When the application sends Pos/DataNeededResponse message with |<json_payload>| payload to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS displays main menu frame
        And an item <item_description> with price <item_price> is in the current transaction

        Examples:
        | json_payload                                 | item_description  | item_price | response_data                             |
        | {"SelectedOperationName": "InstantApproval"} | Age 18 Restricted | 3.69       | {"TransactionData": {"ItemList": [{"Description": "Age 18 Restricted", "ExtendedPriceAmount": 3.69, "ExternalId": "ITT-0369369369-0-1", "ItemNumber": 1, "POSItemId": 990000000010, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 3.69}], "TransactionBalance": 3.95, "TransactionSubTotal": 3.69, "TransactionTaxAmount": 0.26, "TransactionTotal": 3.95}, "TransactionSequenceNumber": "*"} |


    @positive @fast
    Scenario Outline: Send DataNeededResponse command to the POS with a cancel operation after attempting to sell an
                      Age restricted item, validate the response, item is not added to the transaction
        Given the POS is in a ready to sell state
        And the application sent Pos/SellItem message with |{"Barcode": "0369369369"}| payload to the POS Connect
        When the application sends Pos/DataNeededResponse message with |<json_payload>| payload to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS displays main menu frame
        And an item <item_description> with price <item_price> is not in the current transaction

        Examples:
        | json_payload                        | item_description  | item_price | response_data                             |
        | {"SelectedOperationName": "Cancel"} | Age 18 Restricted | 3.69       | {"ReturnCode": 1016, "ReturnCodeDescription": "Operation was cancelled.", "TransactionSequenceNumber": "*"} |
