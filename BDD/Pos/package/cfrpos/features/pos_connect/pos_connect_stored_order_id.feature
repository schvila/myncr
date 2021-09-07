@pos @pos_connect
Feature: POS Connect ViewStoredOrder attribute
    This feature file validates Sheetz enhancement of POS Connect integrated to core (POSAPI 2.85.1) ViewStoredOrder attribute.
    This feature returns detail of transaction from store recall queue which is stored using the StoreOrder feature of the PosConnect.
    According to the design, if we have two TransactionSequenceNumber parameter in the request, it considers the first one as a comment and second as an actual one. In case of multiple TransactionSequenceNumber parameters, it always considers the last one
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
    Scenario Outline: Send ViewStoredOrders command to the POS and validate the stored order with the given transaction sequence number is retrieved.
        Given the POS is in a ready to sell state
        And the application sent a |<request>| to the POS Connect to store a transaction under Transaction Sequence Number
        When the application sends ViewStoredOrders command with last stored order to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is <response_type>
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_type | response_data |
        | ["Pos/StoreOrder", {"OriginSystemId": "PayInStore", "OriginReferenceId": "1234567890", "CustomerName": "Ben Example Order", "ItemList":[{"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4 }]}] | Pos/ViewStoredOrdersResponse | {"TransactionData": {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 7.96, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4, "Type": "Regular", "UnitPriceAmount": 1.99}], "TransactionBalance": 8.52, "TransactionSubTotal": 7.96, "TransactionTaxAmount": 0.56, "TransactionTotal": 8.52}} |
        | ["Pos/StoreOrder", {"OriginSystemId": "PayInStore", "OriginReferenceId": "1234567890", "CustomerName": "Ben Example Order", "ItemList":[{"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4 }, {"POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4}, {"Type": "Loyalty","EntryMethod": "Manual","Barcode": "12879784762398321","CustomerName": "John Doe"}]}] | Pos/ViewStoredOrdersResponse | {"TransactionData": {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 7.96, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4, "Type": "Regular", "UnitPriceAmount": 1.99}, {"Description": "Sale Item A", "ExtendedPriceAmount": 3.96, "ExternalId": "ITT-099999999990-0-1", "ItemNumber": 2, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4, "Type": "Regular", "UnitPriceAmount": 0.99}, {"Description": "3As+2Bs Combo", "DiscountType": "AutoCombo", "ExtendedPriceAmount": -0.95, "ExternalId": "1", "ItemNumber": 16, "Quantity": 1, "ReductionList": [{"Description": "3As+2Bs Combo", "DiscountedItemNumber": 2, "ExtendedPriceAmount": -0.47, "ExternalId": "Combo1a", "ItemNumber": 10, "Quantity": 1, "RposId": "990000000002-0-0-0", "Type": "Discount", "UnitPriceAmount": -0.47}, {"Description": "3As+2Bs Combo", "DiscountedItemNumber": 1, "ExtendedPriceAmount": -0.48, "ExternalId": "Combo1b", "ItemNumber": 13, "Quantity": 1, "RposId": "990000000003-0-0-0", "Type": "Discount", "UnitPriceAmount": -0.48}], "RposId": "990000000002-0-0-0", "Type": "Discount", "UnitPriceAmount": -0.95}], "TransactionBalance": 11.74, "TransactionSubTotal": 10.97, "TransactionTaxAmount": 0.77, "TransactionTotal": 11.74}, "TransactionSequenceNumber": "*"} |


    # list of non-existing transaction # should not prevent ViewStoredOrders to process correctly the valid transaction  at the end of list
    # list of non-existing transaction #  should return same error as the single non-existing transaction #
    # from list of existing transaction# , last one should be used and succeeding non-existent transaction (s) should not prevent it to be correctly processed
    @positive @fast
    Scenario Outline: Send ViewStoredOrders command with non-existing transactionSequenceNumber ending with existing transactionSequenceNumber and validate only the last one is retrieved
        Given the POS is in a ready to sell state
        And the application sent a |<request>| to the POS Connect to store a transaction under Transaction Sequence Number
        When the application sends ViewStoredOrders command with non-existing transactionSequenceNumber ending with existing transactionSequenceNumber to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is <response_type>
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_type | response_data |
        | ["Pos/StoreOrder", {"OriginSystemId": "PayInStore", "OriginReferenceId": "123", "CustomerName": "Ben Example Order", "ItemList":[{"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4 }]}] | Pos/ViewStoredOrdersResponse | {"TransactionData": {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 7.96, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4, "Type": "Regular", "UnitPriceAmount": 1.99}], "TransactionBalance": 8.52, "TransactionSubTotal": 7.96, "TransactionTaxAmount": 0.56, "TransactionTotal": 8.52}} |


    @negative @fast
    Scenario Outline: Send ViewStoredOrders command with existing transactionSequenceNumber ending with non-existing transactionSequenceNumber and validate only the last one is retrieved
        Given the POS is in a ready to sell state
        And the application sent a |<request>| to the POS Connect to store a transaction under Transaction Sequence Number
        When the application sends ViewStoredOrders command with existing transactionSequenceNumber ending with non-existing transactionSequenceNumber to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is <response_type>
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_type | response_data |
        | ["Pos/StoreOrder", {"OriginSystemId": "PayInStore", "OriginReferenceId": "123", "CustomerName": "Ben Example Order", "ItemList":[{"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4 }]}] | Pos/ViewStoredOrdersResponse | {"ReturnCode": 1035, "ReturnCodeDescription": "Transaction was not found.", "TransactionSequenceNumber": "*"} |


    @positive @fast
    Scenario Outline: Send ViewStoredOrders command to the PosConnect and the transaction must exist in stored state and must not be changed in any way
        Given the POS is in a ready to sell state
        And the application sent a |<request>| to the POS Connect to store a transaction under Transaction Sequence Number
        When the application sends ViewStoredOrders command with last stored order to the POS Connect
        And the cashier recalls the last stored transaction
        Then the POS Connect response code is 200
        And an item <description> with price <amount> and quantity <quantity> is in the current transaction

        Examples:
        | request | description | amount | quantity |
        | ["Pos/StoreOrder", {"OriginSystemId": "PayInStore", "OriginReferenceId": "123", "CustomerName": "Ben Example Order", "ItemList":[{"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4 }]}] | Sale Item B | 7.96 | 4 |


    @negative @fast
    Scenario Outline: Send ViewStoredOrders command to the POS with no transaction sequence number and validate that the error with invalid parameter is returned.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is <response_type>
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_type | response_data |
        | ["Pos/ViewStoredOrders", {}] | Pos/ViewStoredOrdersResponse | {"ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter TransactionSequenceNumber is missing or the provided value is invalid.", "TransactionSequenceNumber": 0} |


    @negative @fast
    Scenario Outline: Send ViewStoredOrders command to the POS with no stored order and validate the transaction not found error response.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is <response_type>
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_type | response_data |
        | ["Pos/ViewStoredOrders", {"TransactionSequenceNumber": 10}] | Pos/ViewStoredOrdersResponse | {"ReturnCode": 1035, "ReturnCodeDescription": "Transaction was not found.", "TransactionSequenceNumber": 0 } |


    @negative @fast
    Scenario Outline: Send ViewStoredOrders command to the POS with some invalid transaction sequence numbers and validate the transaction not found or invalid parameter error.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is <response_type>
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_type | response_data |
        | ["Pos/ViewStoredOrders", {"TransactionSequenceNumber": 0}] | Pos/ViewStoredOrdersResponse | {"ReturnCode": 1035, "ReturnCodeDescription": "Transaction was not found.", "TransactionSequenceNumber": 0 } |
        | ["Pos/ViewStoredOrders", {"TransactionSequenceNumber": -123}] | Pos/ViewStoredOrdersResponse | {"ReturnCode": 1035, "ReturnCodeDescription": "Transaction was not found.", "TransactionSequenceNumber": 0 } |
        | ["Pos/ViewStoredOrders", {"TransactionSequenceNumber": 1234567890}] | Pos/ViewStoredOrdersResponse | {"ReturnCode": 1035, "ReturnCodeDescription": "Transaction was not found.", "TransactionSequenceNumber": 0 } |
        | ["Pos/ViewStoredOrders", {"TransactionSequenceNumber": 12.23}] | Pos/ViewStoredOrdersResponse | {"ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter TransactionSequenceNumber is missing or the provided value is invalid.", "TransactionSequenceNumber": 0 } |
        | ["Pos/ViewStoredOrders", {"TransactionSequenceNumber": "1a.2@"}] | Pos/ViewStoredOrdersResponse | {"ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter TransactionSequenceNumber is missing or the provided value is invalid.", "TransactionSequenceNumber": 0 } |
        | ["Pos/ViewStoredOrders", {"TransactionSequenceNumber": "12345678901234567890123456789 0123456789012345678901234567890"}] | Pos/ViewStoredOrdersResponse | {"ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter TransactionSequenceNumber is missing or the provided value is invalid.", "TransactionSequenceNumber": 0 } |


    @negative @fast
    Scenario Outline: Send ViewStoredOrders command to the POS with transaction already in progress and validate the Transaction already in progress response
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the application sent a |<request>| to the POS Connect to store a transaction under Transaction Sequence Number
        When the application sends ViewStoredOrders command with last stored order to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is <response_type>
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_type | response_data |
        |  ["Pos/StoreOrder", {"OriginSystemId": "PayInStore", "OriginReferenceId": "1234567890", "CustomerName": "Ben Example Order", "ItemList":[{"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4 }]}] | Pos/ViewStoredOrdersResponse | {"ReturnCode": 1006, "ReturnCodeDescription": "Transaction cannot be started. Transaction is already in progress." } |
