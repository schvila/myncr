@pos @pos_connect
Feature: POS Connect RemoveStoredOrder attribute
    This feature file validates Sheetz enhancement of POS Connect integrated to core (POSAPI 2.85.1) RemoveStoredOrder attribute.
    This feature Returns detail of transactions which are removed from store recall queue.
    Actors
    * application: an application which uses the POS Connect
    * POS: a POS application
    * POS Connect: a POS Connect server

Background: POS is ready to sell and no transaction is in progress
    Given the POS has essential configuration
    And the Sigma simulator has essential configuration
    And the POS has the feature Loyalty enabled
    And the Sigma recognizes following cards
            | card_number       | card_description |
            | 12879784762398321 | Happy Card       |
    And the POS has the feature PosApiServer enabled
    And the POS has following sale items configured
        | barcode       | description    | price  | external_id          | internal_id                   |
        | 099999999990  | Sale Item A    | 0.99   | ITT-099999999990-0-1 | 990000000002-990000000007-0-0 |
        | 088888888880  | Sale Item B    | 1.99   | ITT-088888888880-0-1 | 990000000003-990000000007-0-0 |


    @positive @fast @manual
    # waiting for RPOS-26850
    Scenario Outline: Send RemoveStoredOrder command to the POS and validate the stored order is removed from store recall queue and its details sent in the response.
        Given the POS is in a ready to sell state
        And the application sent a |<request>| to the POS Connect to store a transaction under Transaction Sequence Number
        When the application sends RemoveStoredOrder command with the last stored transaction number to the POS
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/RemoveStoredOrdersResponse
        And POS Connect response data contain |<response_data>|
        And the last stored transaction is removed from the store recall queue

        Examples:
        | request | response_data |
        | ["Pos/StoreOrder", {"OriginSystemId": "PayInStore", "OriginReferenceId": "1234567890", "CustomerName": "Ben Example Order", "ItemList":[{"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4 }]}] | {"Transactions": [{"TransactionData": {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 7.96, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4, "Type": "Regular", "UnitPriceAmount": 1.99}], "TransactionBalance": 8.52, "TransactionSubTotal": 7.96, "TransactionTaxAmount": 0.56, "TransactionTotal": 8.52}, "TransactionSequenceNumber": "*"}]} |
        | ["Pos/StoreOrder", {"OriginSystemId": "PayInStore", "OriginReferenceId": "1234567890", "CustomerName": "Ben Example Order", "ItemList":[{"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4 }, {"POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4}, {"Type": "Loyalty","EntryMethod": "Manual","Barcode": "12879784762398321","CustomerName": "John Doe"}]}] | {"Transactions": [{"TransactionData": {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 7.96, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4, "Type": "Regular", "UnitPriceAmount": 1.99}, {"Description": "Sale Item A", "ExtendedPriceAmount": 3.96, "ExternalId": "ITT-099999999990-0-1", "ItemNumber": 2, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4, "Type": "Regular", "UnitPriceAmount": 0.99}, {"Description": "3As+2Bs Combo", "DiscountType": "AutoCombo", "ExtendedPriceAmount": -0.95, "ExternalId": "1", "ItemNumber": 16, "Quantity": 1, "ReductionList": [{"Description": "3As+2Bs Combo", "DiscountedItemNumber": 2, "ExtendedPriceAmount": -0.47, "ExternalId": "Combo1a", "ItemNumber": 10, "Quantity": 1, "RposId": "990000000002-0-0-0", "Type": "Discount", "UnitPriceAmount": -0.47}, {"Description": "3As+2Bs Combo", "DiscountedItemNumber": 1, "ExtendedPriceAmount": -0.48, "ExternalId": "Combo1b", "ItemNumber": 13, "Quantity": 1, "RposId": "990000000003-0-0-0", "Type": "Discount", "UnitPriceAmount": -0.48}], "RposId": "990000000002-0-0-0", "Type": "Discount", "UnitPriceAmount": -0.95}], "TransactionBalance": 11.74, "TransactionSubTotal": 10.97, "TransactionTaxAmount": 0.77, "TransactionTotal": 11.74}, "TransactionSequenceNumber": "*"}]} |


    @negative @fast
    Scenario Outline: Send RemoveStoredOrder command to the POS with no stored transactions and verify the transaction not found response
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/RemoveStoredOrdersResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/RemoveStoredOrders", {"TransactionList": [{"TransactionSequenceNumber": 123}]}] | {"ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionSequenceNumber": 0, "Transactions": [{"ErrorCode": 1035, "ErrorCodeDescription": "Transaction was not found.", "TransactionSequenceNumber": 123}]} |


    @negative @fast
    Scenario Outline: Send RemoveStoredOrder command to the POS with no transaction sequence number parameter and verify the invalid parameter response
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And current transaction is stored under Stored Transaction Sequence Number
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/RemoveStoredOrdersResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/RemoveStoredOrders", {"TransactionList": [{}]}] | {"ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter TransactionSequenceNumber is missing or the provided value is invalid.", "TransactionSequenceNumber": 0, "Transactions": []} |


    @negative @fast
    Scenario Outline: Send RemoveStoredOrder command to the POS with transaction present in VR and verify Transaction already in progress response
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the application sends RemoveStoredOrder command with the last stored transaction number to the POS
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/RemoveStoredOrdersResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | response_data |
        | {"ReturnCode": 1027, "ReturnCodeDescription": "The action failed because there is a transaction in progress."} |