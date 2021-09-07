@pos @pos_connect
Feature: POS Connect OriginSystemId attribute
    This feature file validates Sheetz enhancement of POS Connect integrated to core (POSAPI 2.85.1) OriginSystemId attribute
    OriginSystemId attribute can be present in any POSConnect request; OriginSystemId starting with string "RPOS-" is not allowed
    OriginSystemId is returned in StoreOrderResponse and FinalizeOrderResponse
    OriginSystemId is not displayed on POS (VR, Store/Recall queue, Previous transactions); it's only displayed on KPS and printed on KPS slips
    OriginSystemId is exported to transaction XML as Header/OriginSystemId
    Actors
    * application: an application which uses the POS Connect
    * POS: a POS application
    * POS Connect: a POS Connect server


    Background: POS is ready to sell and no transaction is in progress
        Given the POS has essential configuration
        And the POS has the feature PosApiServer enabled
        And the POS has following sale items configured
                | barcode       | description    | price  | external_id          | internal_id                   |
                | 099999999990  | Sale Item A    | 0.99   | ITT-099999999990-0-1 | 990000000002-990000000007-0-0 |
                | 088888888880  | Sale Item B    | 1.99   | ITT-088888888880-0-1 | 990000000003-990000000007-0-0 |


    @positive @fast
    Scenario Outline: Send Pos/GetState command with valid OriginSystemId and check the response indicates success and OriginSystemId is not returned in GetStateResponse
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/GetStateResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/GetState", {"OriginSystemId": "InternetOrder"}] | {"DeviceStates": {"CarWash": {"IsConfigured": "*", "IsOnline": "*"}, "ElectronicPayment": {"IsConfigured": "*", "IsOnline": "*"}, "Pinpad": {"IsOnline": "*"}, "ReceiptPrinter": {"IsOnline": "*"}, "SiteController": {"IsOnline": "*"}}, "IsPaymentAvailable": "*", "IsUpdateRequired": "*", "NodeNumber": "*", "State": "Ready", "TransactionSequenceNumber": 0} |


    @positive @fast
    Scenario Outline: Send POSConnect command requiring an opened transaction with valid OriginSystemId and check the response indicates success and OriginSystemId is not returned in Response
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is <response_type>
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_type | response_data |
        | ["Pos/GetTransaction",{"OriginSystemId": "ProvideSomeVeryLongAndMeaninglessIdStringForThisTest"}] | Pos/GetTransactionResponse | {"TransactionTaxAmount": 0.07, "TransactionTotal": 1.06, "TransactionSequenceNumber": "*", "ItemList": [{"Description": "Sale Item A", "ExternalId": "ITT-099999999990-0-1", "ExtendedPriceAmount": 0.99, "POSModifier1Id": 990000000007, "ItemNumber": 1, "Type": "Regular", "POSModifier2Id": 0, "Quantity": 1, "POSModifier3Id": 0, "POSItemId": 990000000002, "UnitPriceAmount": 0.99}], "TransactionBalance": 1.06, "TransactionSubTotal": 0.99} |
        | ["Pos/SellItem", {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "Quantity": 3, "OriginSystemId": "PayInside"}] | Pos/SellItemResponse | {"TransactionData": {"ItemList": [{"Description": "Sale Item A","ExtendedPriceAmount": 0.99,"ExternalId": "ITT-099999999990-0-1","ItemNumber": 1,"POSItemId": 990000000002,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 1,"Type": "Regular","UnitPriceAmount": 0.99},{"Description": "Sale Item B","ExtendedPriceAmount": 5.97,"ExternalId": "ITT-088888888880-0-1","ItemNumber": 2,"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 3,"Type": "Regular","UnitPriceAmount": 1.99}], "TransactionBalance": 7.45,"TransactionSubTotal": 6.96,"TransactionTaxAmount": 0.49,"TransactionTotal": 7.45}, "TransactionSequenceNumber": "*" } |


    @positive @fast
    Scenario Outline: Send a POSConnect command creating new transaction to the POS with no transaction in progress and validate the response indicates success and OriginSystemId is returned in Response
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is <response_type>
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_type | response_data |
        | ["Pos/StoreOrder",{"OriginSystemId": "PayInStore", "OriginReferenceId": "1234567890", "CustomerName": "Ben Example Order", "ItemList":[{"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4 }]}] | Pos/StoreOrderResponse | {"ItemList": [{"Description": "Sale Item B","ExtendedPriceAmount": 7.96,"ExternalId": "ITT-088888888880-0-1","ItemNumber": 1,"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 4,"RequestItemNumber": 1,"Type": "Regular", "UnitPriceAmount": 1.99}], "OriginSystemId": "PayInStore", "TransactionBalance": 8.52,"TransactionSequenceNumber": "*","TransactionSubTotal": 7.96,"TransactionTaxAmount": 0.56,"TransactionTotal": 8.52} |
        | ["Pos/FinalizeOrder",{"OriginSystemId": "Batch-test","ItemList":[{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2},{"Type": "Tender","ExternalId": "70000000023","Amount": 5.21,"CardType": "1600","MaskedCardNumber": "1234","STAN": 56,"ApprovalCode": "78","BatchNumber": 90,"BatchSequenceNumber": 654},{"Type": "Tax","ExternalId": "589","Amount": 1.23}]}] | Pos/FinalizeOrderResponse | {"ItemList": [{"Description": "Sale Item B","ExtendedPriceAmount": 3.98,"ExternalId": "ITT-088888888880-0-1","ItemNumber": 1,"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2,"RequestItemNumber": 1,"Type": "Regular","UnitPriceAmount": 1.99},{"Description": "SB tax", "ExtendedPriceAmount": 1.23, "RposId": "589-0-0-0", "Type": "Tax"},{"Description": "Cash","ExtendedPriceAmount": -5.21,"ExternalId": "70000000023","ItemNumber": 3,"Quantity": 1,"RequestItemNumber": 2,"Type": "Tender"}],"OriginSystemId": "Batch-test","TransactionBalance": 0.0,"TransactionSequenceNumber": "*","TransactionSubTotal": 3.98,"TransactionTaxAmount": 1.23,"TransactionTotal": 5.21} |


    @negative @fast
    Scenario Outline: Send Store or Finalize order with OriginSystemId set to a value failing the "RPOS-" validation and check error is returned
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is <response_type>
        And POS Connect response data contain |<response_data>|

         Examples:
        | request | response_type | response_data |
        | ["Pos/StoreOrder",{"OriginSystemId": "RPOS-PayInStore", "OriginReferenceId": "1234567890", "CustomerName": "Ben Example Order", "ItemList":[{"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4 }]}] | Pos/StoreOrderResponse | {"ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter OriginSystemId contains an invalid value.", "TransactionSequenceNumber": "*"} |
        | ["Pos/FinalizeOrder",{"OriginSystemId": "RPOS-Batch-test","ItemList":[{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2},{"Type": "Tender","ExternalId": "70000000023","Amount": 5.21,"CardType": "1600","MaskedCardNumber": "1234","STAN": 56,"ApprovalCode": "78","BatchNumber": 90,"BatchSequenceNumber": 654},{"Type": "Tax","ExternalId": "589","Amount": 1.23}]}] | Pos/FinalizeOrderResponse | {"ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter OriginSystemId contains an invalid value.", "TransactionSequenceNumber": "*"} |


    @negative @fast
    Scenario Outline: Send Pos/GetState command with OriginSystemId set to a value failing the "RPOS-" validation and check the GetStateResponse returns error
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/GetStateResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/GetState", {"OriginSystemId": "RPOS-InternetOrder"}] | {"ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter OriginSystemId contains an invalid value.", "TransactionSequenceNumber": 0} |


    @negative @fast
    Scenario Outline: Send POSConnect command requiring an opened transaction with OriginSystemId set to a value failing the "RPOS-" validation and check the response returns error
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction 2 times
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is <response_type>
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_type | response_data |
        | ["Pos/GetTransaction", {"OriginSystemId": "RPOS-ProvideSomeVeryLongAndMeaninglessIdStringForThisTest"}] | Pos/GetTransactionResponse | {"ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter OriginSystemId contains an invalid value.", "TransactionSequenceNumber": "*"} |
        | ["Pos/SellItem", {"POSItemId": 990000000002, "POSModifier1Id": 990000000007, "Quantity": 3, "OriginSystemId": "RPOS-Provide Some Very Long And Meaningless Id String With Spaces For This Test_"}] | Pos/SellItemResponse | {"ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter OriginSystemId contains an invalid value.", "TransactionSequenceNumber": "*"} |
        | ["Pos/AddTender", {"TenderExternalId": "70000000023", "Amount": 10, "OriginSystemId": "RPOS-123"}] | Pos/AddTenderResponse | {"ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter OriginSystemId contains an invalid value.", "TransactionSequenceNumber": "*"} |


    @positive @fast
    Scenario Outline: Send a FinalizeOrder command with OriginSystemId matching OrderSystemId of an existing operator,
                      or value of POS parameter 1382 matching the external ID of an existing operator,
                      validate the overriding operator in the NVPs from finalized transaction.
        Given the POS has the following operators configured
        | operator_id | pin  | last_name  | first_name | order_source_id | external_id |
        | 70000000014 | 1234 | 1234       | Cashier    | Cahier Operator | 1234        |
        | 70000000015 | 2345 | 2345       | Manager    | Test Operator   | 2345        |
        # Set Operator External Id for POS Connect orders to external Id of existing operator
        And the POS control parameter 1382 is set to <external_id>
        And the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is <response_message>
        And a header section from a previous transaction contains NVP <nvp>

        Examples:
        | request | nvp | external_id | response_message |
        | ["Pos/FinalizeOrder", {"OriginSystemId": "Cashier Operator", "ItemList": [{"Barcode": "099999999990", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 0.99}]}] | {'name': 'OverridingOperator', 'persist': 'true', 'text': '70000000014', 'type': '2'} | 1234 | Pos/FinalizeOrderResponse |
        | ["Pos/FinalizeOrder", {"OriginSystemId": "Test Operator", "ItemList": [{"Barcode": "099999999990", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 0.99}]}]    | {'name': 'OverridingOperator', 'persist': 'true', 'text': '70000000015', 'type': '2'} | 5555 | Pos/FinalizeOrderResponse |
        | ["Pos/FinalizeOrder", {"OriginSystemId": "Operator X", "ItemList": [{"Barcode": "099999999990", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 0.99}]}]       | {'name': 'OverridingOperator', 'persist': 'true', 'text': '70000000015', 'type': '2'} | 2345 | Pos/FinalizeOrderResponse |


    @negative @fast
    Scenario Outline: Send FinalizeOrder command with OriginSystemId not matching OrderSystemId of any existing operator,
                      or value of POS parameter 1382 not matching the external ID of any existing operator,
                      or OrderSystemId is matching signed operator and value of POS parameter 1382 not matching the external ID of any existing operator,
                      validate the overriding operator in not present in the NVPs from finalized transaction
        Given the POS has the following operators configured
        | operator_id | pin  | last_name  | first_name | order_source_id | external_id |
        | 70000000014 | 1234 | 1234       | Cashier    | Cahier Operator | 1234        |
        # Set Operator External Id for POS Connect orders to external Id of non-existing operator
        Given the POS control parameter 1382 is set to 5555
        And the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is <response_message>
        And a header section from the previous transaction does not contain NVP with name <nvp>

        Examples:
        | request | nvp | response_message |
        | ["Pos/FinalizeOrder", {"OriginSystemId": "Cashier Operator", "ItemList": [{"Barcode": "099999999990", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 0.99}]}] | OverridingOperator | Pos/FinalizeOrderResponse |
        | ["Pos/FinalizeOrder", {"OriginSystemId": "Operator X", "ItemList": [{"Barcode": "099999999990", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 0.99}]}]       | OverridingOperator | Pos/FinalizeOrderResponse |


    @positive @fast
    Scenario Outline: Send a StoreOrder command with OriginSystemId matching OrderSystemId of an existing operator,
                      or value of POS parameter 1382 matching the external ID of an existing operator,
                      validate the overriding operator in the NVPs from recalled transaction.
        Given the POS has the following operators configured
        | operator_id | pin  | last_name  | first_name | order_source_id | external_id |
        | 70000000014 | 1234 | 1234       | Cashier    | Cahier Operator | 1234        |
        | 70000000015 | 2345 | 2345       | Manager    | Test Operator   | 2345        |
        # Set Operator External Id for POS Connect orders to external Id of existing operator
        And the POS control parameter 1382 is set to <external_id>
        And the POS is in a ready to sell state
        And the application sent a |<request>| to the POS Connect to store a transaction under Transaction Sequence Number
        When the application sends RecallTransaction command with last stored Sequence Number to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is <response_message>
        And a header section from a current transaction contains NVP <nvp>

        Examples:
        | request | nvp | external_id | response_message |
        | ["Pos/StoreOrder", {"OriginSystemId": "Cashier Operator", "ItemList": [{"Barcode": "099999999990", "Quantity": 1}]}] | {'name': 'OverridingOperator', 'persist': 'true', 'text': '70000000014', 'type': '2'} | 1234 | Pos/RecallTransactionResponse |
        | ["Pos/StoreOrder", {"OriginSystemId": "Test Operator", "ItemList": [{"Barcode": "099999999990", "Quantity": 1}]}]    | {'name': 'OverridingOperator', 'persist': 'true', 'text': '70000000015', 'type': '2'} | 5555 | Pos/RecallTransactionResponse |
        | ["Pos/StoreOrder", {"OriginSystemId": "Operator X", "ItemList": [{"Barcode": "099999999990", "Quantity": 1}]}]       | {'name': 'OverridingOperator', 'persist': 'true', 'text': '70000000015', 'type': '2'} | 2345 | Pos/RecallTransactionResponse |


    @negative @fast
    Scenario Outline: Send StoreOrder command with OriginSystemId not matching OrderSystemId of any existing operator,
                      or value of POS parameter 1382 not matching the external ID of any existing operator,
                      or OrderSystemId is matching signed operator and value of POS parameter 1382 not matching the external ID of any existing operator,
                      validate the overriding operator in not present in the NVPs from recalled transaction
        Given the POS has the following operators configured
        | operator_id | pin  | last_name  | first_name | order_source_id | external_id |
        | 70000000014 | 1234 | 1234       | Cashier    | Cahier Operator | 1234        |
        # Set Operator External Id for POS Connect orders to external Id of non-existing operator
        Given the POS control parameter 1382 is set to 5555
        And the POS is in a ready to sell state
        And the application sent a |<request>| to the POS Connect to store a transaction under Transaction Sequence Number
        When the application sends RecallTransaction command with last stored Sequence Number to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is <response_message>
        And a header section from the current transaction does not contain NVP with name <nvp>

        Examples:
        | request | nvp | response_message |
        | ["Pos/StoreOrder", {"OriginSystemId": "Cashier Operator", "ItemList": [{"Barcode": "099999999990", "Quantity": 1}]}] | OverridingOperator | Pos/RecallTransactionResponse |
        | ["Pos/StoreOrder", {"OriginSystemId": "Operator X", "ItemList": [{"Barcode": "099999999990", "Quantity": 1}]}]       | OverridingOperator | Pos/RecallTransactionResponse |
