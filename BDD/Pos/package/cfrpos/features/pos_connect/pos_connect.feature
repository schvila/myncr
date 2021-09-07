@pos @pos_connect
Feature: POS Connect
    This feature file validates message protocol of the POS Connect (POSAPI 3.0.3).
    Actors
    * application: an application which uses the POS Connect
    * POS: a POS application
    * POS Connect: a POS Connect server

    Background: POS is ready to sell and no transaction is in progress
        Given the POS has essential configuration
        And the POS has the feature PosApiServer enabled
        # "Age verification failure tracking" option set to "NO"
        And the POS option 1024 is set to 0
        And the POS has following sale items configured
              | barcode       | description    | price  | external_id          | internal_id                   |
              | 099999999990  | Sale Item A    | 0.99   | ITT-099999999990-0-1 | 990000000002-990000000007-0-0 |
              | 088888888880  | Sale Item B    | 1.99   | ITT-088888888880-0-1 | 990000000003-990000000007-0-0 |
              | 055555555550  | Container Item | 1.29   | ITT-055555555550-0-1 | 990000000006-990000000007-0-0 |
              | 0369369369 | Age 18 Restricted | 3.69   | ITT-0369369369-0-1   |                               |
              | 404  | Deposit (for Container) | 0.05   | ITT-404-4-0          | 990000000013-990000000004-0-0 |
        And the POS has following discount triggers configured:
              | barcode       | description     | price  |
              | 000111222333  | Coupon discount | -1.50  |


    @positive @slow @requires_sc @waitingforfix @manual
    Scenario Outline: Send GetState command to POS and validate that response contains states for configured devices.
        Given the device <device> is in <device_state> state
        When the application sends |["Pos/GetState", {}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/GetStateResponse
        And the POS Connect response tells that the device <device> is in <device_state> state

        Examples:
        | device            | device_state |
        | CarWash           | Offline      |
        | CarWash           | Online       |
        | Pinpad            | Offline      |
        | Pinpad            | Online       |
        | SiteController    | Offline      |
        | SiteController    | Online       |
        | ElectronicPayment | Offline      |
        | ElectronicPayment | Online       |
        | ReceiptPrinter    | Offline      |
        | ReceiptPrinter    | Online       |


    @positive @fast
    Scenario Outline: Send GetState command to POS and validate the state, where the POS is.
        Given the POS is set to <state> state
        When the application sends |["Pos/GetState", {}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/GetStateResponse
        And the POS Connect response tells that the POS is in <state> state

        Examples:
        | state        |
        | Locked       |
        | Ready        |


    @positive @slow @manual @waitingforfix
    Scenario: Send GetState command to POS, that needs to be updated and validate, that there is an update required.
        Given the POS needs an update
        When the application sends |["Pos/GetState", {}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/GetStateResponse
        And the POS Connect response for update required is true


    @positive @slow
    Scenario: Send GetState command to POS, that does not need to be updated and validate, that there is not update required.
        Given the POS does not need an update
        When the application sends |["Pos/GetState", {}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/GetStateResponse
        And the POS Connect response for update required is false


    @positive @slow
    Scenario: Send ApplyUpdate command when update needed, Validate the ApplyUpdate response.
        Given the POS needs an update
        When the application sends |["Pos/ApplyUpdate", {}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/ApplyUpdateResponse
        And POS Connect response data are |{}|
        And the POS is updated


    @negative @slow
    Scenario: Send ApplyUpdate command when no update needed, Validate the ApplyUpdate response.
        Given the POS does not need an update
        When the application sends |["Pos/ApplyUpdate", {}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/ApplyUpdateResponse
        And POS Connect response data contain |{"TransactionSequenceNumber": "*", "ReturnCode": 1018, "ReturnCodeDescription": "POS API restart invalid at this time because an update is not required."}|


    @positive @fast
    Scenario Outline: Add some items to the transaction and send GetTransaction command, validate the POSAPI response.
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction <item_count> times
        When the application sends |["Pos/GetTransaction", {}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/GetTransactionResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | item_barcode | item_count | response_data |
        | 099999999990 | 1          | {"TransactionTaxAmount": 0.07, "TransactionTotal": 1.06, "TransactionSequenceNumber": "*", "ItemList": [{"Description": "Sale Item A", "ExternalId": "ITT-099999999990-0-1", "ExtendedPriceAmount": 0.99, "POSModifier1Id": 990000000007, "ItemNumber": 1, "Type": "Regular", "POSModifier2Id": 0, "Quantity": 1, "POSModifier3Id": 0, "POSItemId": 990000000002, "UnitPriceAmount": 0.99}], "TransactionBalance": 1.06, "TransactionSubTotal": 0.99} |
        | 088888888880 | 2          | {"TransactionTaxAmount": 0.28, "TransactionTotal": 4.26, "TransactionSequenceNumber": "*", "ItemList": [{"Description": "Sale Item B", "ExternalId": "ITT-088888888880-0-1", "ExtendedPriceAmount": 1.99, "POSModifier1Id": 990000000007, "ItemNumber": 1, "Type": "Regular", "POSModifier2Id": 0, "Quantity": 1, "POSModifier3Id": 0, "POSItemId": 990000000003, "UnitPriceAmount": 1.99}, {"Description": "Sale Item B", "ExternalId": "ITT-088888888880-0-1", "ExtendedPriceAmount": 1.99, "POSModifier1Id": 990000000007, "ItemNumber": 2, "Type": "Regular", "POSModifier2Id": 0, "Quantity": 1, "POSModifier3Id": 0, "POSItemId": 990000000003, "UnitPriceAmount": 1.99}], "TransactionBalance": 4.26, "TransactionSubTotal": 3.98} |
        | 055555555550 | 1          | {"TransactionTaxAmount": 0.09, "TransactionTotal": 1.43, "TransactionSequenceNumber": "*", "ItemList": [{"Description": "Container Item", "ExternalId": "ITT-055555555550-0-1", "POSModifier2Id": 0, "ExtendedPriceAmount": 1.29, "ItemNumber": 1, "ItemList": [{"Description": "Deposit (for Container)", "ExternalId": "ITT-404-4-0", "ExtendedPriceAmount": 0.05, "POSModifier1Id": 990000000004, "ItemNumber": 2, "Type": "ContainerDeposit", "POSModifier2Id": 0, "Quantity": 1, "POSModifier3Id": 0, "POSItemId": 990000000013, "UnitPriceAmount": 0.05}], "Type": "Regular", "POSModifier1Id": 990000000007, "Quantity": 1, "POSModifier3Id": 0, "POSItemId": 990000000006, "UnitPriceAmount": 1.29}], "TransactionBalance": 1.43, "TransactionSubTotal": 1.34} |


    @positive @fast
    Scenario Outline: Send different commands from the application repeatedly and ensure POS can handle them all.
        Given the POS is in a ready to sell state
        When the application sends |<formatted_message>| to the POS Connect <repeat_times> times
        Then the POS Connect response message <response_message> with response code 200 is received for all <repeat_times> requests

        Examples:
        | formatted_message         | response_message          | repeat_times  |
        | ["Pos/GetState", {}]      | Pos/GetStateResponse      | 1             |
        | ["Pos/GetPumpState", {}]  | Pos/GetPumpStateResponse  | 2             |
        | ["Server/GetVersion", {}] | Server/GetVersionResponse | 3             |


    @positive @fast
    Scenario: Send an AbortTransaction command, validate the transaction in progress was voided.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the application sends |["Pos/AbortTransaction", {}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/AbortTransactionResponse
        And no transaction is in progress


    @positive @fast @manual @waitingforfix
    Scenario Outline: Send AddDiscountTrigger command, validate that the discount is in current transaction.
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction <count> times
        When the application sends |<formatted_message>| to the POS Connect
        Then the POS Connect response code is 200
        And an item <discount_name> with amount <discount_amount> is in the virtual receipt
        And an item <discount_name> with amount <discount_amount> is in the current transaction

        Examples:
        | formatted_message                                                                 |
        | ["Pos/AddDiscountTrigger", {"Barcode": "000111222333", "EntryMethod": "Scanned"}] |


    @positive @fast
    Scenario Outline: Send AddLoyalty command, validate that the loyalty card is added into the transaction.
        Given the Sigma simulator has essential configuration
        And the Sigma recognizes following cards
            | card_description | card_number      | track1                       | track2                       | alt_id    |
            | Kroger Loyalty A | 6042400114771120 | 6042400114771120^CARD/S^0000 | 6042400114771120=0000?S^0000 | 123456789 |
            | Kroger Loyalty B | 3042400114771120 | 3042400114771120^CARD/S^0000 | 3042400114771120=0000?S^0000 | 003456789 |
        And the POS is in a ready to sell state
        When the application sends |<formatted_message>| to the POS Connect
        Then a card Loyalty Item with value of 0.00 is in the virtual receipt
        And a card Loyalty Item with value of 0.00 is in the current transaction

        Examples:
        | formatted_message                                                             |
        | ["Pos/AddLoyalty", {"EntryMethod": "Scanned", "Barcode": "6042400114771120"}] |
        | ["Pos/AddLoyalty", {"EntryMethod": "Manual", "Barcode": "3042400114771120"}]  |


    @positive @fast
    Scenario Outline: Send AddLoyalty command with correct Alt ID, validate that the loyalty card is added into the transaction.
        Given the Sigma simulator has essential configuration
        And the Sigma recognizes following cards
            | card_description | card_number      | track1                       | track2                       | alt_id    |
            | Kroger Loyalty A | 6042400114771120 | 6042400114771120^CARD/S^0000 | 6042400114771120=0000?S^0000 | 123456789 |
            | Kroger Loyalty B | 3042400114771120 | 3042400114771120^CARD/S^0000 | 3042400114771120=0000?S^0000 | 003456789 |
        And the Sigma option RLMSendAuthAfterLoyaltyPresented is set to POS
        And the POS is in a ready to sell state
        When the application sends |<formatted_message>| to the POS Connect
        Then a card Loyalty Item with value of 0.00 is in the virtual receipt
        And a card Loyalty Item with value of 0.00 is in the current transaction

        Examples:
        | formatted_message                                 |
        | ["Pos/AddLoyalty", {"AlternateId": "123456789"}]  |
        | ["Pos/AddLoyalty", {"AlternateId": "003456789"}]  |


    @negative @fast
    Scenario Outline: Send AddLoyalty command with incorrect Alt ID, the POS displays Unknown Alt Id frame and reprompts to enter Alt ID.
        Given the Sigma simulator has essential configuration
        And the Sigma recognizes following cards
            | card_description | card_number      | track1                       | track2                       | alt_id    |
            | Kroger Loyalty A | 6042400114771120 | 6042400114771120^CARD/S^0000 | 6042400114771120=0000?S^0000 | 123456789 |
            | Kroger Loyalty B | 3042400114771120 | 3042400114771120^CARD/S^0000 | 3042400114771120=0000?S^0000 | 003456789 |
        And the Sigma option RLMSendAuthAfterLoyaltyPresented is set to POS
        And the Sigma option AlternateIdRetryCount is set to 1
        And the POS is in a ready to sell state
        When the application sends |<formatted_message>| to the POS Connect
        Then the POS displays Unknown Alt ID frame
        And the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data contain |<response_data>|

        Examples:
        | formatted_message                                 | response_data                                                                                                                     |
        | ["Pos/AddLoyalty", {"AlternateId": "1000000014"}] | {"AvailableOperations":[{"Name":"Cancel","Text":""}],"DataType":"NumericString","PromptId":5086,"PromptText":"Unknown Alt ID"}    |
        | ["Pos/AddLoyalty", {"AlternateId": "0000000000"}] | {"AvailableOperations":[{"Name":"Cancel","Text":""}],"DataType":"NumericString","PromptId":5086,"PromptText":"Unknown Alt ID"}    |


    @positive @fast
    Scenario Outline: Send DataNeededResponse command with correct Alt ID, after AddLoyalty command was sent with incorrect Alt ID,
                      the POS displays main frame, validate that the loyalty card is added into the transaction.
        Given the Sigma simulator has essential configuration
        And the Sigma recognizes following cards
            | card_description | card_number      | track1                       | track2                       | alt_id    |
            | Kroger Loyalty A | 6042400114771120 | 6042400114771120^CARD/S^0000 | 6042400114771120=0000?S^0000 | 123456789 |
            | Kroger Loyalty B | 3042400114771120 | 3042400114771120^CARD/S^0000 | 3042400114771120=0000?S^0000 | 003456789 |
        And the Sigma option RLMSendAuthAfterLoyaltyPresented is set to POS
        And the Sigma option AlternateIdRetryCount is set to 1
        And the POS is in a ready to sell state
        And the POS displays Unknown Alt ID frame after sending the request |<formatted_message_1>|
        When the application sends |<formatted_message_2>| to the POS Connect
        Then the POS displays main menu frame
        Then a card Loyalty Item with value of 0.00 is in the virtual receipt
        And a card Loyalty Item with value of 0.00 is in the current transaction

        Examples:
        | formatted_message_1                                | formatted_message_2                                                               |
        | ["Pos/AddLoyalty", {"AlternateId": "0004567890"}]  | ["Pos/DataNeededResponse",{"DataType": "NumericString", "TextData": "123456789"}] |
        | ["Pos/AddLoyalty", {"AlternateId": "0004567890"}]  | ["Pos/DataNeededResponse",{"DataType": "NumericString", "TextData": "003456789"}] |


    @negative @fast
    Scenario Outline: Send DataNeededResponse command with incorrect Alt ID, after AddLoyalty command was sent with incorrect Alt ID,
                      the POS displays main frame, validate that the loyalty card is not added into the transaction.
        Given the Sigma simulator has essential configuration
        And the Sigma recognizes following cards
            | card_description | card_number      | track1                       | track2                       | alt_id    |
            | Kroger Loyalty A | 6042400114771120 | 6042400114771120^CARD/S^0000 | 6042400114771120=0000?S^0000 | 123456789 |
            | Kroger Loyalty B | 3042400114771120 | 3042400114771120^CARD/S^0000 | 3042400114771120=0000?S^0000 | 003456789 |
        And the Sigma option RLMSendAuthAfterLoyaltyPresented is set to POS
        And the Sigma option AlternateIdRetryCount is set to 1
        And the POS is in a ready to sell state
        And the POS displays Unknown Alt ID frame after sending the request |<formatted_message_1>|
        When the application sends |<formatted_message_2>| to the POS Connect
        Then the POS displays main menu frame
        And the POS Connect response code is 200
        And the POS Connect message type is Pos/AddLoyaltyResponse
        And POS Connect response data contain |<response_data>|
        And a card Loyalty Item with value of 0.00 is not in the virtual receipt

        Examples:
        | formatted_message_1                                | formatted_message_2                                                               | response_data |
        | ["Pos/AddLoyalty", {"AlternateId": "0004567890"}]  | ["Pos/DataNeededResponse",{"DataType": "NumericString", "TextData": "000111222"}] | {"ReturnCode": 1020, "ReturnCodeDescription": "Loyalty sigma error.", "TransactionSequenceNumber": "*"} |


    @positive @fast
    Scenario Outline: Send AddTender command, validate that the tender is in current transaction.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction 5 times
        When the application sends |<formatted_message>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/AddTenderResponse
        And POS Connect response data contain |<response_data>|
        And a tender <tender_name> with amount <tender_amount> is in the virtual receipt
        And a tender <tender_name> with amount <tender_amount> is in the current transaction

        Examples:
        | formatted_message                                                         | tender_name | tender_amount | response_data |
        | ["Pos/AddTender", {"TenderExternalId": "70000000023", "Amount": 1.00}]    | Cash        | 1.00          | {"TransactionData": {"TransactionSubTotal": 4.95, "TransactionBalance": 4.3, "TransactionTotal": 5.3, "TransactionTaxAmount": 0.35, "ItemList": [{"ExtendedPriceAmount": 4.95, "POSModifier3Id": 0, "Type": "Regular", "Quantity": 5, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "ItemNumber": 1, "Description": "Sale Item A", "ExternalId": "ITT-099999999990-0-1", "POSModifier2Id": 0, "UnitPriceAmount": 0.99}, {"ExtendedPriceAmount": -1.0, "Quantity": 1, "Type": "Tender", "ItemNumber": 6, "Description": "Cash", "ExternalId": "70000000023"}]}, "TransactionSequenceNumber": "*", "TenderAmount": 1.0} |


    @positive @fast
    Scenario Outline: Send message AddTender with more amount than the active transaction contains, so it pays the whole transaction.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the application sends |<formatted_message>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/AddTenderResponse
        And POS Connect response data contain |<response_data>|
        And no transaction is in progress

        Examples:
        | formatted_message                                                         | response_data |
        | ["Pos/AddTender", {"TenderExternalId": "70000000023", "Amount": 25.25}]   | {"CashBack": 24.19, "TransactionData": {"TransactionTotal": 1.06, "TransactionSubTotal": 0.99, "TransactionBalance": 0.0, "ItemList": [{"POSModifier2Id": 0, "ExternalId": "ITT-099999999990-0-1", "Description": "Sale Item A", "ItemNumber": 1, "POSItemId": 990000000002, "Type": "Regular", "POSModifier3Id": 0, "Quantity": 1, "POSModifier1Id": 990000000007, "ExtendedPriceAmount": 0.99, "UnitPriceAmount": 0.99}, {"ExternalId": "70000000023", "Description": "Cash", "ItemNumber": 2, "Type": "Tender", "Quantity": 1, "ExtendedPriceAmount": -25.25}, {"Description": "Tax Item", "ExtendedPriceAmount": 0.01000, "RposId": "101-0-0-0", "Type": "Tax"}, {"Description": "Tax Item", "ExtendedPriceAmount": 0.02000, "RposId": "102-0-0-0", "Type": "Tax"}, {"Description": "Tax Item", "ExtendedPriceAmount": 0.04000, "RposId": "103-0-0-0", "Type": "Tax"}], "TransactionTaxAmount": 0.07}, "TransactionSequenceNumber": "*", "TenderAmount": 1.06} |


    @positive @fast
    Scenario Outline: Send CancelItem command, validate that the item is canceled and is not in the current transaction.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And an item Sale Item A with price 0.99 has changed quantity to 4
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/CancelItemResponse
        And POS Connect response data contain |<response_data>|
        And an item <item_name> with price <item_total> and quantity <item_quantity> is in the virtual receipt
        And an item <item_name> with price <item_total> and quantity <item_quantity> is in the current transaction

        Examples:
        | request                                               | item_name   | item_total | item_quantity | response_data |
        | ["Pos/CancelItem", {"ItemNumber": 1}]                 | Sale Item A | 2.97       | 3             | {"TransactionData": {"TransactionTotal": 3.18, "ItemList": [{"ExtendedPriceAmount": 2.97, "Quantity": 3, "Description": "Sale Item A", "POSItemId": 990000000002}]}} |
        | ["Pos/CancelItem", {"ItemNumber": 1, "Quantity": 1}]  | Sale Item A | 2.97       | 3             | {"TransactionData": {"TransactionTotal": 3.18, "ItemList": [{"ExtendedPriceAmount": 2.97, "Quantity": 3, "Description": "Sale Item A", "POSItemId": 990000000002}]}} |
        | ["Pos/CancelItem", {"ItemNumber": 1, "Quantity": 3}]  | Sale Item A | 0.99       | 1             | {"TransactionData": {"TransactionTotal": 1.06, "ItemList": [{"ExtendedPriceAmount": 0.99, "Quantity": 1, "Description": "Sale Item A", "POSItemId": 990000000002}]}} |


    @positive @fast
    Scenario Outline: Send CancelItem command for second item, validate that the item is canceled and is not in the current transaction.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And an item with barcode 088888888880 is present in the transaction
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/CancelItemResponse
        And POS Connect response data contain |<response_data>|
        And an item <item_name> with price <item_total> is not in the virtual receipt
        And an item <item_name> with price <item_total> is not in the current transaction

        Examples:
        | request                                               | item_name   | item_total | response_data |
        | ["Pos/CancelItem", {"ItemNumber": 2}]                 | Sale Item B | 1.99       | {"TransactionData": {"TransactionSubTotal": 0.99, "TransactionBalance": 1.06, "TransactionTotal": 1.06, "TransactionTaxAmount": 0.07, "ItemList": [{"ExtendedPriceAmount": 0.99, "POSModifier3Id": 0, "Type": "Regular", "Quantity": 1, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "ItemNumber": 1, "Description": "Sale Item A", "ExternalId": "ITT-099999999990-0-1", "POSModifier2Id": 0, "UnitPriceAmount": 0.99}]}, "TransactionSequenceNumber": "*"} |


    @negative @fast
    Scenario Outline: Send a request with wrong parameter, missing item or for item which is not allowed to cancel.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is <response_message>
        And POS Connect response data contain |<response_data>|

        Examples:
        | response_message            | request                                               | response_data |
        | Pos/CancelItemResponse      | ["Pos/CancelItem", {"ItemNumber": 0}]                 | {"ReturnCodeDescription": "Invalid Parameter ItemNumber is out of range.", "ReturnCode": 1001, "TransactionSequenceNumber": "*"} |
        | Pos/CancelItemResponse      | ["Pos/CancelItem", {"ItemNumber": 1, "Quantity": 0}]  | {"ReturnCodeDescription": "Invalid Parameter Quantity is out of range.", "ReturnCode": 1001, "TransactionSequenceNumber": "*"} |
        | Pos/CancelItemResponse      | ["Pos/CancelItem", {"ItemNumber": 2, "Quantity": 1}]  | {"ReturnCodeDescription": "Item not found.", "ReturnCode": 1002, "TransactionSequenceNumber": "*"} |
        | Pos/ChangeItemPriceResponse | ["Pos/ChangeItemPrice", {"ItemNumber": 0, "UnitPriceAmount" : 1.0}] | {"ReturnCodeDescription": "Invalid Parameter ItemNumber is out of range.", "ReturnCode": 1001, "TransactionSequenceNumber": "*"} |
        | Pos/ChangeItemPriceResponse | ["Pos/ChangeItemPrice", {"ItemNumber": 1, "UnitPriceAmount" : 100000000.0}] | {"ReturnCodeDescription": "Invalid Parameter UnitPriceAmount contains a value that is too large.", "ReturnCode": 1001, "TransactionSequenceNumber": "*"} |
        | Pos/ChangeItemQuantityResponse | ["Pos/ChangeItemQuantity", {"Quantity": 2, "ItemNumber": 0}] | {"ReturnCodeDescription": "Invalid Parameter ItemNumber is out of range.", "ReturnCode": 1001, "TransactionSequenceNumber": "*"} |
        | Pos/ChangeItemQuantityResponse | ["Pos/ChangeItemQuantity", {"Quantity": 9999, "ItemNumber": 1}] | {"ReturnCodeDescription": "Invalid Parameter Quantity contains a value that is too large.", "ReturnCode": 1001, "TransactionSequenceNumber": "*"} |


    @negative @fast
    Scenario Outline: Send a request when there is no transaction started, but the request needs transaction.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is <response_message>
        And POS Connect response data contain |{"ReturnCodeDescription": "There is no transaction currently in progress.", "ReturnCode": 1017, "TransactionSequenceNumber": "*"}|

        Examples:
        | response_message              | request |
        | Pos/CancelItemResponse        | ["Pos/CancelItem", {"ItemNumber": 1}] |
        | Pos/ChangeItemPriceResponse   | ["Pos/ChangeItemPrice", {"ItemNumber": 1, "UnitPriceAmount" : 1.0}] |
        | Pos/CancelTransactionResponse | ["Pos/CancelTransaction", {}] |
        | Pos/ChangeItemQuantityResponse | ["Pos/ChangeItemQuantity", {"Quantity": 2, "ItemNumber": 1}] |
        | Pos/GetTransactionResponse    | ["Pos/GetTransaction", {}] |
        | Pos/AddTenderResponse         | ["Pos/AddTender", {"TenderExternalId": "70000000023", "Amount": 1.00}] |
        | Pos/AbortTransactionResponse  | ["Pos/AbortTransaction", {}] |


    @positive @fast
    Scenario Outline: Send ChangeItemPrice command, validate that the item has changed price in the current transcation.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And an item with barcode 088888888880 is present in the transaction
        When the application sends |<request>| to the POS Connect with the first reason for action |<select_reason_request>|
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/ChangeItemPriceResponse
        And POS Connect response data contain |<response_data>|
        And an item <item_name> with price <item_price> is in the virtual receipt
        And an item <item_name> with price <item_price> is in the current transaction

        Examples:
        | request                                                               | item_name   | item_price | response_data | select_reason_request |
        | ["Pos/ChangeItemPrice", {"ItemNumber": 1, "UnitPriceAmount" : 12.0}]  | Sale Item A | 12.00      | {"TransactionData": {"TransactionTotal": 14.97, "TransactionSubTotal": 13.99, "TransactionBalance": 14.97, "ItemList": [{"POSModifier2Id": 0, "ExternalId": "ITT-099999999990-0-1", "Description": "Sale Item A", "ItemNumber": 1, "POSItemId": 990000000002, "Type": "Regular", "POSModifier3Id": 0, "Quantity": 1, "POSModifier1Id": 990000000007, "ExtendedPriceAmount": 12.0, "UnitPriceAmount": 12.00}, {"POSModifier2Id": 0, "ExternalId": "ITT-088888888880-0-1", "Description": "Sale Item B", "ItemNumber": 2, "POSItemId": 990000000003, "Type": "Regular", "POSModifier3Id": 0, "Quantity": 1, "POSModifier1Id": 990000000007, "ExtendedPriceAmount": 1.99, "UnitPriceAmount": 1.99}], "TransactionTaxAmount": 0.98}, "TransactionSequenceNumber": "*"} | ["Pos/DataNeededResponse", {"DataType": "ListSelection", "SelectedIndex": 0}] |
        | ["Pos/ChangeItemPrice", {"ItemNumber": 2, "UnitPriceAmount" : 8.0}]   | Sale Item B | 8.0        | {"TransactionData": {"TransactionTotal": 9.62, "TransactionSubTotal": 8.99, "TransactionBalance": 9.62, "ItemList": [{"POSModifier2Id": 0, "ExternalId": "ITT-099999999990-0-1", "Description": "Sale Item A", "ItemNumber": 1, "POSItemId": 990000000002, "Type": "Regular", "POSModifier3Id": 0, "Quantity": 1, "POSModifier1Id": 990000000007, "ExtendedPriceAmount": 0.99, "UnitPriceAmount": 0.99}, {"POSModifier2Id": 0, "ExternalId": "ITT-088888888880-0-1", "Description": "Sale Item B", "ItemNumber": 2, "POSItemId": 990000000003, "Type": "Regular", "POSModifier3Id": 0, "Quantity": 1, "POSModifier1Id": 990000000007, "ExtendedPriceAmount": 8.0, "UnitPriceAmount": 8.00}], "TransactionTaxAmount": 0.63}, "TransactionSequenceNumber": "*"} | ["Pos/DataNeededResponse", {"DataType": "ListSelection", "SelectedIndex": 0}] |
        | ["Pos/ChangeItemPrice", {"ItemNumber": 1, "UnitPriceAmount" : 0.0}]   | Sale Item A | 0.0        | {"TransactionData": {"TransactionTotal": 2.13, "TransactionSubTotal": 1.99, "TransactionBalance": 2.13, "ItemList": [{"POSModifier2Id": 0, "ExternalId": "ITT-099999999990-0-1", "Description": "Sale Item A", "ItemNumber": 1, "POSItemId": 990000000002, "Type": "Regular", "POSModifier3Id": 0, "Quantity": 1, "POSModifier1Id": 990000000007, "ExtendedPriceAmount": 0.0, "UnitPriceAmount": 0.00}, {"POSModifier2Id": 0, "ExternalId": "ITT-088888888880-0-1", "Description": "Sale Item B", "ItemNumber": 2, "POSItemId": 990000000003, "Type": "Regular", "POSModifier3Id": 0, "Quantity": 1, "POSModifier1Id": 990000000007, "ExtendedPriceAmount": 1.99, "UnitPriceAmount": 1.99}], "TransactionTaxAmount": 0.14}, "TransactionSequenceNumber": "*"} | ["Pos/DataNeededResponse", {"DataType": "ListSelection", "SelectedIndex": 0}] |
        | ["Pos/ChangeItemPrice", {"ItemNumber": 1, "UnitPriceAmount" : -4.0}]  | Sale Item A | -4.0       | {"TransactionData": {"TransactionTotal": -2.15, "TransactionSubTotal": -2.01, "TransactionBalance": -2.15, "ItemList": [{"POSModifier2Id": 0, "ExternalId": "ITT-099999999990-0-1", "Description": "Sale Item A", "ItemNumber": 1, "POSItemId": 990000000002, "Type": "Regular", "POSModifier3Id": 0, "Quantity": 1, "POSModifier1Id": 990000000007, "ExtendedPriceAmount": -4.0, "UnitPriceAmount": -4.00}, {"POSModifier2Id": 0, "ExternalId": "ITT-088888888880-0-1", "Description": "Sale Item B", "ItemNumber": 2, "POSItemId": 990000000003, "Type": "Regular", "POSModifier3Id": 0, "Quantity": 1, "POSModifier1Id": 990000000007, "ExtendedPriceAmount": 1.99, "UnitPriceAmount": 1.99}], "TransactionTaxAmount": -0.14}, "TransactionSequenceNumber": "*"} | ["Pos/DataNeededResponse", {"DataType": "ListSelection", "SelectedIndex": 0}] |


    @positive @fast
    Scenario Outline: Send CancelTransaction with an item in the transaction.
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        When the application sends |["Pos/CancelTransaction", {}]| to the POS Connect with the override request |<override_request>| and the first reason for action |<select_reason_request>|
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/CancelTransactionResponse
        And POS Connect response data contain |<response_data>|
        And no transaction is in progress

        Examples:
        | item_barcode | response_data | override_request | select_reason_request |
        | 099999999990 | {"CancelledTransactionSequenceNumber": "*", "TransactionData": {"TransactionSubTotal": 0.99, "ItemList": [{"POSModifier1Id": 990000000007, "ExternalId": "ITT-099999999990-0-1", "POSModifier2Id": 0, "Quantity": 1, "Description": "Sale Item A", "POSModifier3Id": 0, "POSItemId": 990000000002, "ExtendedPriceAmount": 0.99, "Type": "Regular", "ItemNumber": 1, "UnitPriceAmount": 0.99}], "TransactionBalance": 1.06, "TransactionTotal": 1.06, "TransactionTaxAmount": 0.07}, "TransactionSequenceNumber": "*"} | ["Pos/DataNeededResponse", {"DataType": "Integer", "NumericData": 2345}] | ["Pos/DataNeededResponse", {"DataType": "ListSelection", "SelectedIndex": 0}] |
        | 088888888880 | {"CancelledTransactionSequenceNumber": "*", "TransactionData": {"TransactionSubTotal": 1.99, "ItemList": [{"POSModifier1Id": 990000000007, "ExternalId": "ITT-088888888880-0-1", "POSModifier2Id": 0, "Quantity": 1, "Description": "Sale Item B", "POSModifier3Id": 0, "POSItemId": 990000000003, "ExtendedPriceAmount": 1.99, "Type": "Regular", "ItemNumber": 1, "UnitPriceAmount": 1.99}], "TransactionBalance": 2.13, "TransactionTotal": 2.13, "TransactionTaxAmount": 0.14}, "TransactionSequenceNumber": "*"} | ["Pos/DataNeededResponse", {"DataType": "Integer", "NumericData": 2345}] | ["Pos/DataNeededResponse", {"DataType": "ListSelection", "SelectedIndex": 0}] |


    @positive @fast
    Scenario Outline: Send ChangeItemQuantity command, validate that the item has changed quantity in the current transaction.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/ChangeItemQuantityResponse
        And POS Connect response data contain |<response_data>|
        And an item <item_name> with price <item_total> and quantity <item_quantity> is in the virtual receipt
        And an item <item_name> with price <item_total> and quantity <item_quantity> is in the current transaction

        Examples:
        | request                                                       | item_name   | item_total | item_quantity | response_data |
        | ["Pos/ChangeItemQuantity", {"Quantity": 99, "ItemNumber": 1}] | Sale Item A | 98.01      | 99            | {"TransactionData": {"TransactionSubTotal": 98.01, "TransactionTaxAmount": 6.86, "TransactionBalance": 104.87, "ItemList": [{"POSItemId": 990000000002, "Type": "Regular", "ItemNumber": 1, "ExternalId": "ITT-099999999990-0-1", "ExtendedPriceAmount": 98.01, "Description": "Sale Item A", "POSModifier3Id": 0, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "Quantity": 99, "UnitPriceAmount": 0.99}], "TransactionTotal": 104.87}, "TransactionSequenceNumber": "*"} |


    @positive @fast
    Scenario Outline: Send DrawerLoan with no active transaction.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect with the override request |<override_request>| and the first reason for action |<select_reason_request>|
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DrawerLoanResponse
        And the POS Connect response data contain element TransactionSequenceNumber with value *

        Examples:
        | request                               | override_request | select_reason_request |
        | ["Pos/DrawerLoan", {"Amount":123.21}] | ["Pos/DataNeededResponse", {"DataType": "Integer", "NumericData": 2345}] | ["Pos/DataNeededResponse", {"DataType": "ListSelection", "SelectedIndex": 0}] |


    @negative @fast
    Scenario: Send DrawerLoan with an active transaction.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the application sends |["Pos/DrawerLoan", {"Amount":123.21}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DrawerLoanResponse
        And POS Connect response data contain |{"ReturnCodeDescription": "The action failed because there is a transaction in progress.", "ReturnCode": 1027, "TransactionSequenceNumber": "*"}|


	@negative @fast
    Scenario Outline: Send DrawerLoan with no active transaction, but with an invalid amount.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DrawerLoanResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request                                     | response_data |
        | ["Pos/DrawerLoan", {}]                      | {"ReturnCodeDescription": "Invalid Parameter Amount is missing or the provided value is invalid.", "ReturnCode": 1001, "TransactionSequenceNumber": "*"} |
        | ["Pos/DrawerLoan", {"Amount":-0.01}]        | {"ReturnCodeDescription": "Invalid Parameter Amount is out of range.", "ReturnCode": 1001, "TransactionSequenceNumber": "*"} |
        | ["Pos/DrawerLoan", {"Amount":21474836.40}]  | {"ReturnCodeDescription": "Invalid Parameter Amount is out of range.", "ReturnCode": 1001, "TransactionSequenceNumber": "*"} |


    @positive @fast
    Scenario Outline: Send DecodeBarcode command with some barcode and check, if it recognized the barcode.
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DecodeBarcodeResponse
        And the decoded type is <decoded_type>

        Examples:
        | request                                                                    | decoded_type       |
        | ["Pos/DecodeBarcode",{"Barcode": "1234","EntryMethod": "Scanned"}]         | Unknown            |
        | ["Pos/DecodeBarcode",{"Barcode": "099999999990","EntryMethod": "Manual"}]  | RetailItem         |
        | ["Pos/DecodeBarcode",{"Barcode": "599999000141","EntryMethod": "Scanned"}] | ManufacturerCoupon |
        | ["Pos/DecodeBarcode",{"Barcode": "0010000000003749","EntryMethod": "Scanned"}] | StoredTransaction  |
        # waitingforfix
        # | ["Pos/DecodeBarcode",{"Barcode": "","EntryMethod": "Scanned"}]           | Coupon             |
        # | ["Pos/DecodeBarcode",{"Barcode": "","EntryMethod": "Scanned"}]           | Loyalty            |
        # | ["Pos/DecodeBarcode",{"Barcode": "","EntryMethod": "Scanned"}]           | DriversLicense     |
        # | ["Pos/DecodeBarcode",{"Barcode": "","EntryMethod": "Scanned"}]           | Svc                |
        # | ["Pos/DecodeBarcode",{"Barcode": "","EntryMethod": "Scanned"}]           | LocalAccount       |
        # | ["Pos/DecodeBarcode",{"Barcode": "","EntryMethod": "Scanned"}]           | DiscountTrigger    |
        # | ["Pos/DecodeBarcode",{"Barcode": "","EntryMethod": "Scanned"}]           | DualPurposeCard    |


    @positive @fast
    Scenario: Send GetPumpState command and check the state of the pumps.
        Given the POS is in a ready to sell state
        And the POS has following pumps configured:
            | fueling_point |
            | 1             |
            | 2             |
            | 3             |
            | 4             |
        When the application sends |["Pos/GetPumpState", {}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/GetPumpStateResponse
        And POS Connect response data contain |{"PumpList": [{"IsStackedSalesFull": false, "PumpNumber": 1, "State": "Idle", "HoseList": "*"}, {"IsStackedSalesFull": false, "PumpNumber": 2, "State": "Idle", "HoseList": "*"}, {"IsStackedSalesFull": false, "PumpNumber": 3, "State": "Idle", "HoseList": "*"}, {"IsStackedSalesFull": false, "PumpNumber": 4, "State": "Idle", "HoseList": "*"}], "TransactionSequenceNumber": "*"}|


    @positive @fast @smoke
    Scenario: Response to the message GetVersion contains the current API version and the POS version.
        Given the POS is in a ready to sell state
        When the application sends |["Server/GetVersion", {}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Server/GetVersionResponse
        And POS Connect response data contain |{"APIVersion": "3.0.3", "POSVersion": "*"}|

    @positive @fast
    Scenario Outline: Response to the message SellItem contains transaction details.
        Given the POS is in a ready to sell state
        When the application sends |<formatted_message>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|
        And an item <item_name> with price <item_total> and quantity <item_quantity> is in the virtual receipt
        And an item <item_name> with price <item_total> and quantity <item_quantity> is in the current transaction

    Examples:
    | formatted_message                                            | item_name   | item_total | item_quantity | response_data |
    | ["Pos/SellItem", {"Barcode": "099999999990", "Quantity": 1}] | Sale Item A | 0.99       | 1             | {"TransactionData": {"ItemList": [{"Description": "Sale Item A", "ExtendedPriceAmount": 0.99, "ExternalId": "ITT-099999999990-0-1", "ItemNumber": 1, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "TransactionBalance": 1.06, "TransactionSubTotal": 0.99, "TransactionTaxAmount": 0.07, "TransactionTotal": 1.06}, "TransactionSequenceNumber": "*"} |
    | ["Pos/SellItem", {"Barcode": "099999999990", "Quantity": 4}] | Sale Item A | 3.96       | 4             | {"TransactionData": {"TransactionSubTotal": 3.96, "TransactionBalance": 4.24, "TransactionTotal": 4.24, "TransactionTaxAmount": 0.28, "ItemList": [{"ExtendedPriceAmount": 3.96, "POSModifier3Id": 0, "Type": "Regular", "Quantity": 4, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "ItemNumber": 1, "Description": "Sale Item A", "ExternalId": "ITT-099999999990-0-1", "POSModifier2Id": 0, "UnitPriceAmount": 0.99}]}, "TransactionSequenceNumber": "*"} |


    @positive @fast
    Scenario Outline: The message SellItem adds a sale item identified by Barcode, ExternalId, POSItemId or RposId.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response transaction data contain an item with type Regular and description <description> and amount <amount> and quantity <quantity>
        And an item <description> with price <amount> and quantity <quantity> is in the virtual receipt
        And an item <description> with price <amount> and quantity <quantity> is in the current transaction

        Examples:
        | description | amount | quantity | request |
        | Sale Item A | 0.99   | 1        | ["Pos/SellItem", {"Barcode": "099999999990", "Quantity": 1}] |
        | Sale Item A | 0.99   | 1        | ["Pos/SellItem", {"ExternalId": "ITT-099999999990-0-1", "Quantity": 1}] |
        | Sale Item A | 0.99   | 1        | ["Pos/SellItem", {"POSItemId": 990000000002, "POSModifier1Id": 990000000007, "Quantity": 1}] |
        | Sale Item A | 0.99   | 1        | ["Pos/SellItem", {"RposId": "990000000002-990000000007-0-0", "Quantity": 1}] |


    @negative @fast
    Scenario Outline: Send an unsupported barcode length (27-30) through various requests, validate that a proper error
                      code and RequestItemNumbers are returned even when other valid items are in the request as well.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And no transaction is in progress

        Examples:
        | request | response_data |
        | ["Pos/SellItem", {"Barcode": "123456789012345678901234567", "Quantity": 1}] | {"ReturnCode": 1002, "ReturnCodeDescription": "Item not found.", "TransactionSequenceNumber": 0} |
        | ["Pos/SubTotalOrder", {"ItemList": [{"Barcode": "099999999990", "Quantity": 1}, {"Barcode": "1234567890123456789012345678", "Quantity": 1}, {"Barcode": "088888888880", "Quantity": 1}]}] | {"ItemList": [{"Barcode": "1234567890123456789012345678", "POSItemId": 0, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 2, "ReturnCode": 1002, "ReturnCodeDescription": "Item not found."}, {"Description": "Sale Item A", "ExtendedPriceAmount": 0.99, "ExternalId": "ITT-099999999990-0-1", "ItemNumber": 1, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 0.99}, {"Description": "Sale Item B", "ExtendedPriceAmount": 1.99, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 2, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "RequestItemNumber": 3, "Type": "Regular", "UnitPriceAmount": 1.99}, {"Description": "Hammer City Tax", "ExtendedPriceAmount": 0.03, "RposId": "101-0-0-0", "Type": "Tax"}, {"Description": "Hammer County Tax", "ExtendedPriceAmount": 0.06, "RposId": "102-0-0-0", "Type": "Tax"}, {"Description": "Hammer State Tax", "ExtendedPriceAmount": 0.12, "RposId": "103-0-0-0", "Type": "Tax"}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 3.19, "TransactionSequenceNumber": "*", "TransactionSubTotal": 2.98, "TransactionTaxAmount": 0.21, "TransactionTotal": 3.19} |
        | ["Pos/StoreOrder",{"ItemList": [{"Barcode": "099999999990", "Quantity": 1}, {"Barcode": "12345678901234567890123456789", "Quantity": 1}, {"Barcode": "088888888880", "Quantity": 1}]}] | {"ItemList": [{"Barcode": "12345678901234567890123456789", "POSItemId": 0, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 2, "ReturnCode": 1002, "ReturnCodeDescription": "Item not found."}, {"Description": "Sale Item A", "ExtendedPriceAmount": 0.99, "ExternalId": "ITT-099999999990-0-1", "ItemNumber": 1, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 0.99}, {"Description": "Sale Item B", "ExtendedPriceAmount": 1.99, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 2, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "RequestItemNumber": 3, "Type": "Regular", "UnitPriceAmount": 1.99}, {"Description": "Hammer City Tax", "ExtendedPriceAmount": 0.03, "RposId": "101-0-0-0", "Type": "Tax"}, {"Description": "Hammer County Tax", "ExtendedPriceAmount": 0.06, "RposId": "102-0-0-0", "Type": "Tax"}, {"Description": "Hammer State Tax", "ExtendedPriceAmount": 0.12, "RposId": "103-0-0-0", "Type": "Tax"}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 3.19, "TransactionSequenceNumber": "*", "TransactionSubTotal": 2.98, "TransactionTaxAmount": 0.21, "TransactionTotal": 3.19} |
        | ["Pos/FinalizeOrder", {"ItemList": [{"Barcode": "099999999990", "Quantity": 1}, {"Barcode": "123456789012345678901234567890", "Quantity": 1}, {"Barcode": "088888888880", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 2.98}]}] | {"ItemList": [{"Barcode": "123456789012345678901234567890", "POSItemId": 0, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 2, "ReturnCode": 1002, "ReturnCodeDescription": "Item not found."}, {"Description": "Sale Item A", "ExtendedPriceAmount": 0.99, "ExternalId": "ITT-099999999990-0-1", "ItemNumber": 1, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 0.99}, {"Description": "Sale Item B", "ExtendedPriceAmount": 1.99, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 2, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "RequestItemNumber": 3, "Type": "Regular", "UnitPriceAmount": 1.99}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 2.98, "TransactionSequenceNumber": 0, "TransactionSubTotal": 2.98, "TransactionTaxAmount": 0.0, "TransactionTotal": 2.98} |


    @positive @fast
    Scenario Outline: Send StoreTransaction command to POS, validate the StoreTransaction response is received and transaction is stored.
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction <item_count> times
        When the application sends |["Pos/StoreTransaction", {}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/StoreTransactionResponse
        And the transaction is stored with StoredTransactionSequenceNumber
        # Check stored transaction"s number with POSHeap being solved in RPOS-5293

        Examples:
        | item_barcode | item_count |
        | 099999999990 | 3          |
        | 088888888880 | 4          |
        | 077777777770 | 5          |


    @negative @fast
    Scenario: Send StoreTransaction command, while no transaction is in progress and validate the response with an error notification.
        Given the POS is in a ready to sell state
        When the application sends |["Pos/StoreTransaction", {}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/StoreTransactionResponse
        And POS Connect response data contain |{"ReturnCodeDescription": "There is no transaction currently in progress.", "TransactionSequenceNumber": "*", "ReturnCode": 1017}|


    @negative @fast
    Scenario: Send StoreTransaction command, while a transaction is partially tendered and validate the response with an error notification.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction 3 times
        And the transaction is tendered with 3.00 in cash
        When the application sends |["Pos/StoreTransaction", {}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/StoreTransactionResponse
        And POS Connect response data contain |{"ReturnCode": 1058, "TransactionSequenceNumber": "*", "ReturnCodeDescription": "Cannot store tendered transaction."}|


    @positive @fast
    Scenario Outline: Send SetState command for UI with UI enabled or disabled, Validate the SetState response is received.
        Given the POS is in a ready to sell state
        When the application sends |<formatted_message>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SetStateResponse

        Examples:
        | formatted_message                         |
        | ["Pos/SetState", {"State": "UIDisabled"}] |
        | ["Pos/SetState", {"State": "UIEnabled"}]  |


    @positive @fast
    Scenario: Send GetOperator command to POS, Validate the GetOperator response.
        Given the POS is in a ready to sell state
        When the application sends |["Pos/GetOperator", {}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/GetOperatorResponse
        And POS Connect response data contain |{"TransactionSequenceNumber": "*", "ShiftId": "*", "Name": "1234, 🞀Cashier🞁", "IsOverridden": "*"}|


    @negative @fast
    Scenario: Send GetOperator command to POS while signed out, validate "Operator not signed in" error notification.
        Given the POS is in a ready to start shift state
        When the application sends |["Pos/GetOperator", {}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/GetOperatorResponse
        And POS Connect response data contain |{"ReturnCodeDescription": "Operator is not signed in.", "TransactionSequenceNumber": "*", "ReturnCode": 1013}|


    @positive @fast @manual @waitingforfix
    Scenario: Send GetOperator command to POS while operator is overridden, Validate IsOverridden value is true.
        Given the POS is in a ready to sell state
        And the cashier is overriden by user with pin 2345
        And the cashier selects yes button on Confirm user override frame
        When the application sends |["Pos/GetOperator", {}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/GetOperatorResponse
        And POS Connect response data contain |{"TransactionSequenceNumber": "*", "ShiftId": "*", "Name": "2345, 🞂Manager🞃", "IsOverridden": true}|


    @positive @fast @manual @waitingforfix
    Scenario: Send GetOperator command with original value set as true to POS while operator is overridden, Validate IsOverridden value is false.
        Given the POS is in a ready to sell state
        And the cashier is overriden by user with pin 2345
        And the cashier selects yes button on Confirm user override frame
        When the application sends |["Pos/GetOperator", {"Original": true}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/GetOperatorResponse
        And POS Connect response data contain |{"TransactionSequenceNumber": "*", "ShiftId": "*", "Name": "1234, 🞀Cashier🞁", "IsOverridden": false}|


    @positive @fast
    Scenario: Send Sign On command, Validate the Sign On response, validate current signed on operator.
        Given the POS is in a ready to start shift state
        When the application sends |["Pos/SignOn", {"Password": 1234}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SignOnResponse
        And POS Connect response data contain |{"TransactionSequenceNumber": "*", "OfflineSignOn": "*", "NewDayNotCreated": "*"}|
        And the cashier "1234, 🞀Cashier🞁" is signed in to the POS


    @positive @fast
    Scenario: Send Sign On command when POS is locked, Validate the Sign On response
        Given the POS is in a ready to sell state
        And the POS is locked
        When the application sends |["Pos/SignOn", {"Password": 1234}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SignOnResponse
        And POS Connect response data contain |{"TransactionSequenceNumber": "*", "OfflineSignOn": "*", "NewDayNotCreated": "*"}|
        And the cashier "1234, 🞀Cashier🞁" is signed in to the POS


    @fast @negative
    Scenario: Send Sign On command when other operator is already signed on and validate the response with an error notification.
        Given the POS is in a ready to sell state
        When the application sends |["Pos/SignOn", {"Password": 2345}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SignOnResponse
        And POS Connect response data contain |{"TransactionSequenceNumber": "*", "ReturnCode": 1026, "ReturnCodeDescription": "Another operator is already signed in."}|


    @fast @negative
    Scenario: Send Sign On command with invalid operator and validate the response with an error notification.
        Given the POS is in a ready to start shift state
        When the application sends |["Pos/SignOn", {"Password": 9}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SignOnResponse
        And POS Connect response data contain |{"TransactionSequenceNumber": "*", "ReturnCode": 1029, "ReturnCodeDescription": "Operator was not found."}|


    @fast @positive
    Scenario Outline: Send PrintReceipt command for previous transaction and validate the response.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the transaction is tendered
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/PrintReceiptResponse
        And POS Connect response data contain |{"TransactionSequenceNumber": "*"}|

        Examples:
        | request |
        | ["Pos/PrintReceipt", {"TransactionSequenceNumber": 0}] |
        | ["Pos/PrintReceipt", {}] |


    @negative @fast
    Scenario Outline: Send CancelRequest command to POS with no pending AddTender request and validate the response with an error notification.
        Given the POS is in a ready to sell state
        When the application sends |["Server/CancelRequest", {}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Server/CancelRequestResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | response_data |
        | {"ReturnCode": 2002, "ReturnCodeDescription": "No associated pending result."} |


    #TODO: Requires Epsilon simulator and credit tender, solved under RPOS-6597
	@positive @fast @manual
    Scenario Outline: Send CancelRequest command to POS with a pending AddTender request and validate the Standard Response.
		Given the POS is in a ready to sell state
		And an item with barcode 099999999990 is present in the transaction
		And the POS Connect has a pending |<request>|
		When the application sends |["Server/CancelRequest", {}]| to the POS Connect
		Then the POS Connect response code is 200
		And the POS Connect message type is Server/CancelRequestResponse
		And POS Connect response data contain |<response_data>|

		Examples:
		| request | response_data |
		| ["Pos/AddTender", {"TenderExternalId": "70000000025", "Amount": 1.00}] | TODO |


    @positive @fast
    Scenario Outline: Send StoreOrder command to the POS with no transaction in progress and validate the response.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/StoreOrderResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/StoreOrder", {"OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [ {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4 }, {"RposId": "990000000002-990000000007-0-0", "Quantity": 2} ] }]   | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 7.96, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 1.99}, {"Description": "Sale Item A", "ExtendedPriceAmount": 1.98, "ExternalId": "ITT-099999999990-0-1", "ItemNumber": 2, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 2, "Type": "Regular", "UnitPriceAmount": 0.99}, {"Description": "Hammer City Tax", "ExtendedPriceAmount": 0.1, "RposId": "101-0-0-0", "Type": "Tax"}, {"Description": "Hammer County Tax", "ExtendedPriceAmount": 0.2, "RposId": "102-0-0-0", "Type": "Tax"}, {"Description": "Hammer State Tax", "ExtendedPriceAmount": 0.4, "RposId": "103-0-0-0", "Type": "Tax"}], "OriginSystemId": "ForeCourt", "TransactionBalance": 10.64, "TransactionSequenceNumber": "*", "TransactionSubTotal": 9.94, "TransactionTaxAmount": 0.7, "TransactionTotal": 10.64} |


    @negative @fast
    Scenario Outline: Send StoreOrder command to the POS with a transaction in progress and validate the response with an error notification.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/StoreOrderResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/StoreOrder", {"OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [ {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4 } ] }]   | {"TransactionSequenceNumber": "*", "ReturnCode": 1006, "ReturnCodeDescription": "Transaction cannot be started. Transaction is already in progress."} |


    #TODO: missing 'response_data' - have to be added a Loyalty card (then should be response with code: 1081 - Failed to store the transaction.)
    @negative @fast @manual
    Scenario Outline: Send StoreOrder command (contains nothing but a loyalty item) to the POS with no transaction in progress and validate the response with an error notification.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/StoreOrderResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/StoreOrder", {"OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [ {"Type": "Loyalty", "EntryMethod": "Manual", "Barcode": "700511866611", "CustomerName": "John Doe" } ] }]   |  |


    @positive @fast
    Scenario Outline: Send StoreOrder command to the POS containing items with configured autocombo and validate the response with autocombo items.
        Given the pricebook contains autocombos
              | description         | external_id | reduction_value | disc_type           | disc_mode         | disc_quantity | item_name   | quantity |
              | MyAutocombo         | 12345       | 10000           | AUTO_COMBO_AMOUNT   | WHOLE_TRANSACTION | STACKABLE     | Sale Item B | 1        |
        And the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/StoreOrderResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/StoreOrder", {"ItemList": [{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 1}]}] | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 1.99, "ExternalId": "ITT-088888888880-0-1", "FractionalQuantity": 1.00000, "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 1.99}, {"Description": "MyAutocombo", "DiscountType": "AutoCombo", "ExtendedPriceAmount": -1.00, "ExternalId": "12345", "FractionalQuantity": 1.00000, "ItemNumber": 5, "Quantity": 1, "ReductionList": [{"Description": "MyAutocombo", "DiscountedItemList": [{"ItemNumber": 1, "Quantity": 1}], "DiscountedItemNumber": 1, "ExtendedPriceAmount": -1.0000, "ExternalId": "12345", "ItemNumber": 2, "Quantity": 1, "RposId": "990000000050-0-0-0", "Type": "Discount", "UnitPriceAmount": -1.0000}], "RposId": "990000000050-0-0-0", "Type": "Discount", "UnitPriceAmount": -1.00}, {"Description": "Hammer City Tax", "ExtendedPriceAmount": 0.0100, "RposId": "101-0-0-0", "Type": "Tax"}, {"Description": "Hammer County Tax", "ExtendedPriceAmount": 0.0200, "RposId": "102-0-0-0", "Type": "Tax"}, {"Description": "Hammer State Tax", "ExtendedPriceAmount": 0.0400, "RposId": "103-0-0-0", "Type": "Tax"}]} |


    @positive @fast
    Scenario Outline: Send SubTotalTransaction command to the POS with a transaction in progress and validate the Standard Response.
        Given the POS is in a ready to sell state
        And an item with barcode 088888888880 is present in the transaction
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SubTotalTransactionResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request                                                              | response_data |
        | ["Pos/SubTotalTransaction", {}]                                      | {"TransactionData": {"TransactionSubTotal": 1.99, "TransactionTaxAmount": 0.14, "TransactionTotal": 2.13, "TransactionBalance": 2.13, "ItemList": [{"POSModifier2Id": 0, "ExternalId": "ITT-088888888880-0-1", "Quantity": 1, "ItemNumber": 1, "ExtendedPriceAmount": 1.99, "Description": "Sale Item B", "POSModifier1Id": 990000000007, "POSModifier3Id": 0, "POSItemId": 990000000003, "Type": "Regular", "UnitPriceAmount": 1.99}]}, "TransactionSequenceNumber": "*"} |
        | ["Pos/SubTotalTransaction", {"TenderExternalId":"70000000023"}]      | {"TransactionData": {"TransactionSubTotal": 1.99, "TransactionTaxAmount": 0.14, "TransactionTotal": 2.13, "TransactionBalance": 2.13, "ItemList": [{"POSModifier2Id": 0, "ExternalId": "ITT-088888888880-0-1", "Quantity": 1, "ItemNumber": 1, "ExtendedPriceAmount": 1.99, "Description": "Sale Item B", "POSModifier1Id": 990000000007, "POSModifier3Id": 0, "POSItemId": 990000000003, "Type": "Regular", "UnitPriceAmount": 1.99}]}, "TransactionSequenceNumber": "*"} |
        | ["Pos/SubTotalTransaction", {"TenderExternalId":"70000000025"}]    | {"TransactionData": {"TransactionSubTotal": 1.99, "TransactionTaxAmount": 0.14, "TransactionTotal": 2.13, "TransactionBalance": 2.13, "ItemList": [{"POSModifier2Id": 0, "ExternalId": "ITT-088888888880-0-1", "Quantity": 1, "ItemNumber": 1, "ExtendedPriceAmount": 1.99, "Description": "Sale Item B", "POSModifier1Id": 990000000007, "POSModifier3Id": 0, "POSItemId": 990000000003, "Type": "Regular", "UnitPriceAmount": 1.99}]}, "TransactionSequenceNumber": "*"} |
        | ["Pos/SubTotalTransaction", {"TenderExternalId":"70000000026"}]    | {"TransactionData": {"TransactionSubTotal": 1.99, "TransactionTaxAmount": 0.14, "TransactionTotal": 2.13, "TransactionBalance": 2.13, "ItemList": [{"POSModifier2Id": 0, "ExternalId": "ITT-088888888880-0-1", "Quantity": 1, "ItemNumber": 1, "ExtendedPriceAmount": 1.99, "Description": "Sale Item B", "POSModifier1Id": 990000000007, "POSModifier3Id": 0, "POSItemId": 990000000003, "Type": "Regular", "UnitPriceAmount": 1.99}]}, "TransactionSequenceNumber": "*"} |
        | ["Pos/SubTotalTransaction", {"TenderExternalId":"70000000028"}] | {"TransactionData": {"TransactionSubTotal": 1.99, "TransactionTaxAmount": 0.14, "TransactionTotal": 2.13, "TransactionBalance": 2.13, "ItemList": [{"POSModifier2Id": 0, "ExternalId": "ITT-088888888880-0-1", "Quantity": 1, "ItemNumber": 1, "ExtendedPriceAmount": 1.99, "Description": "Sale Item B", "POSModifier1Id": 990000000007, "POSModifier3Id": 0, "POSItemId": 990000000003, "Type": "Regular", "UnitPriceAmount": 1.99}]}, "TransactionSequenceNumber": "*"} |
        | ["Pos/SubTotalTransaction", {"TenderExternalId":"70000000029"}]  | {"TransactionData": {"TransactionSubTotal": 1.99, "TransactionTaxAmount": 0.14, "TransactionTotal": 2.13, "TransactionBalance": 2.13, "ItemList": [{"POSModifier2Id": 0, "ExternalId": "ITT-088888888880-0-1", "Quantity": 1, "ItemNumber": 1, "ExtendedPriceAmount": 1.99, "Description": "Sale Item B", "POSModifier1Id": 990000000007, "POSModifier3Id": 0, "POSItemId": 990000000003, "Type": "Regular", "UnitPriceAmount": 1.99}]}, "TransactionSequenceNumber": "*"} |


    @negative @fast
    Scenario Outline: Send SubTotalTransaction command to the POS with a transaction in progress and validate the Standard Response for disallowed types.
        Given the POS is in a ready to sell state
        And an item with barcode 088888888880 is present in the transaction
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SubTotalTransactionResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request                                                              | response_data |
        | ["Pos/SubTotalTransaction", {"TenderExternalId":"70000000024"}]    | { "ReturnCodeDescription": "Tender type is not allowed.", "ReturnCode": 1024, "TransactionSequenceNumber": "*"} |
        | ["Pos/SubTotalTransaction", {"TenderExternalId":"70000000030"}]    | { "ReturnCodeDescription": "Tender type is not allowed.", "ReturnCode": 1024, "TransactionSequenceNumber": "*"} |


    @negative @fast
    Scenario Outline: Send SubTotalTransaction command to the POS with no transaction in progress and validate No Transaction Found error notification.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SubTotalTransactionResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request                         | response_data |
        | ["Pos/SubTotalTransaction", {}] | {"ReturnCodeDescription": "There is no transaction currently in progress.", "ReturnCode": 1017, "TransactionSequenceNumber": 0} |


    @positive @fast
    Scenario Outline: Send SubTotalOrder command to the POS with no transaction in progress and validate the Standard Response.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SubTotalOrderResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/SubTotalOrder", {"OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [ {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4 } ] }]  | {"ItemList": [{"POSModifier2Id": 0, "POSItemId": 990000000003, "RequestItemNumber": 1, "POSModifier1Id": 990000000007, "ExtendedPriceAmount": 7.96, "Description": "Sale Item B", "ExternalId": "ITT-088888888880-0-1", "Quantity": 4, "ItemNumber": 1, "POSModifier3Id": 0, "Type": "Regular", "UnitPriceAmount": 1.99}, {"Description": "Hammer City Tax", "ExtendedPriceAmount": 0.08000, "RposId": "101-0-0-0", "Type": "Tax"}, {"Description": "Hammer County Tax", "ExtendedPriceAmount": 0.16000, "RposId": "102-0-0-0", "Type": "Tax"}, {"Description": "Hammer State Tax", "ExtendedPriceAmount": 0.32000, "RposId": "103-0-0-0", "Type": "Tax"}], "TransactionTotal": 8.52, "TransactionTaxAmount": 0.56, "TransactionBalance": 8.52, "TransactionSubTotal": 7.96} |
        | ["Pos/SubTotalOrder", {"OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [ {"RposId": "990000000003-990000000007-0-0", "Quantity": 4 } ] }]  | {"ItemList": [{"POSModifier2Id": 0, "POSItemId": 990000000003, "RequestItemNumber": 1, "POSModifier1Id": 990000000007, "ExtendedPriceAmount": 7.96, "Description": "Sale Item B", "ExternalId": "ITT-088888888880-0-1", "Quantity": 4, "ItemNumber": 1, "POSModifier3Id": 0, "Type": "Regular", "UnitPriceAmount": 1.99}, {"Description": "Hammer City Tax", "ExtendedPriceAmount": 0.08000, "RposId": "101-0-0-0", "Type": "Tax"}, {"Description": "Hammer County Tax", "ExtendedPriceAmount": 0.16000, "RposId": "102-0-0-0", "Type": "Tax"}, {"Description": "Hammer State Tax", "ExtendedPriceAmount": 0.32000, "RposId": "103-0-0-0", "Type": "Tax"}], "TransactionTotal": 8.52, "TransactionTaxAmount": 0.56, "TransactionBalance": 8.52, "TransactionSubTotal": 7.96} |


    #TODO: add step-example either with condiments and missing parameter POSItemId and ExternalId
    @negative @fast
    Scenario Outline: Send SubTotalOrder command to the POS with no transaction in progress but with too large quantity / with no POSItemId.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SubTotalOrderResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/SubTotalOrder", {"OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [ {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4000 } ] }]  | {"ItemList": [{"POSModifier2Id": 0, "RequestItemNumber": 1, "POSModifier1Id": 990000000007, "ReturnCodeDescription": "Invalid Parameter Quantity contains a value that is too large.", "POSItemId": 990000000003, "POSModifier3Id": 0, "ReturnCode": 1001}], "TransactionTotal": 0.0, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionSubTotal": 0.0, "TransactionSequenceNumber": 0, "ReturnCode": 2000, "TransactionBalance": 0.0, "TransactionTaxAmount": 0.0} |
        | ["Pos/SubTotalOrder", {"OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [ {"POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 40 } ] }]  | {"ItemList": [{"POSModifier2Id": 0, "RequestItemNumber": 1, "POSModifier1Id": 0, "ReturnCodeDescription": "Failed to match exactly one field set.", "POSItemId": 0, "POSModifier3Id": 0, "ReturnCode": 1001}], "TransactionTotal": 0.0, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionSubTotal": 0.0, "TransactionSequenceNumber": 0, "ReturnCode": 2000, "TransactionBalance": 0.0, "TransactionTaxAmount": 0.0} |
		| ["Pos/SubTotalOrder", {"OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [ {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4 }, {"POSItemId": 990000000002, "CondimentList": [{"POSItemId": 990000000179}] } ] }] | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 7.96, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 1.99}, {"Description": "Sale Item A", "ExtendedPriceAmount": 0.99, "ExternalId": "ITT-099999999990-0-1", "ItemList": [{"POSItemId": 990000000179, "RequestItemNumber": 3, "ReturnCode": 1002, "ReturnCodeDescription": "Item not found."}], "ItemNumber": 2, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "RequestItemNumber": 2, "Type": "Regular", "UnitPriceAmount": 0.99}, {"Description": "Hammer City Tax", "ExtendedPriceAmount": 0.09, "RposId": "101-0-0-0", "Type": "Tax"}, {"Description": "Hammer County Tax", "ExtendedPriceAmount": 0.18, "RposId": "102-0-0-0", "Type": "Tax"}, {"Description": "Hammer State Tax", "ExtendedPriceAmount": 0.36, "RposId": "103-0-0-0", "Type": "Tax"}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 9.58, "TransactionSequenceNumber": 0, "TransactionSubTotal": 8.95, "TransactionTaxAmount": 0.63, "TransactionTotal": 9.58} |


	#TODO: Requires Epsilon simulator and credit tender, solved under RPOS-6597
    @positive @fast @manual
    Scenario Outline: Send CancelSwipe command to the POS and validate the Standard Response.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/CancelSwipeResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request                                 | response_data |
        | ["Pos/CancelSwipe", {"Token":"xxxxxx"}] | {"TransactionSequenceNumber": 0, "ReturnCodeDescription": ""} |


    @negative @fast
    Scenario Outline: Send CancelSwipe command with no token parameter to the POS and validate the response with an error notification.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/CancelSwipeResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request                 | response_data |
        | ["Pos/CancelSwipe", {}] | {"TransactionSequenceNumber": 0, "ReturnCodeDescription": "Invalid Parameter Token is missing.", "ReturnCode": 1001} |


	#TODO: Add the positive scenario, Requires Epsilon simulator and credit tender, solved under RPOS-6597
    @negative @fast
    Scenario Outline: Send CaptureSwipe command to the POS and validate the response with an error notification.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/CaptureSwipeResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request                                                                                          | response_data |
        | ["Pos/CaptureSwipe", {"AllowedEntryMethods": ["Manual", "Barcode"], "PromptTimeoutSeconds": 50}] | {"TransactionSequenceNumber": "*", "ReturnCodeDescription": "Operation is not allowed at this time", "ReturnCode": 1085} |


    #TODO: Requires a Customer display simulator
    @positive @fast @manual
    Scenario Outline: Send CustomerDisplayMessage command to the POS and validate the Standard Response.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/CustomerDisplayMessageResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/CustomerDisplayMessage", {"CustomerText": "What would you like?", "PromptTimeoutSeconds": 50, "MessageTarget": ["CustomerDisplay", "POS"]}] | TODO |


    @positive @fast
    Scenario Outline: Send CustomerPrintReceipt command to the POS and validate the Standard Response.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/CustomerPrintReceiptResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/CustomerPrintReceipt", {"PrintFormat": "NCRPRINTAPI", "PrintCommands": ["Text", "Barcode", "Image"]}] | {"Token": "*"} |
        | ["Pos/CustomerPrintReceipt", {"PrintFormat": "NCRPRINTAPI", "PrintCommands": [{"Command": "Text", "Text": "Have a nice day", "Align": "Center", "Font": "Normal", "Width": "Double", "Height": "Double", "Bold": "Yes", "Underline": "No", "Italics": "No", "NewLine": "Yes"}, {"Command": "HorizontalLine"}]}] | {"Token": "*"} |


    @positive @fast @print_receipt
    Scenario: Send CustomerPrintReceipt command to the POS with a text which should be printed and validate the output.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the transaction is tendered
        When the application sends print request |["Pos/CustomerPrintReceipt", {"PrintFormat":"NCRPRINTAPI", "PrintCommands": [{ "Command": "Text", "Text": "Have a nice day", "Align": "Center", "Font": "Normal", "Width": "Double", "Height": "Double", "Bold": "Yes", "Underline": "No", "Italics": "No", "NewLine": "No" },{ "Command": "Text", "Text": "User", "Align": "Center", "Font": "Normal", "Width": "Normal", "Height": "Double", "Bold": "Yes", "Underline": "No", "Italics": "No", "NewLine": "Yes" },{ "Command": "Text", "Text": "Goodbye", "Align": "Center", "Font": "Normal", "Width": "Normal", "Height": "Normal", "Bold": "Yes", "Underline": "No", "Italics": "No", "NewLine": "Yes" }] }]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/CustomerPrintReceiptResponse
        And the receipt is printed with following lines
        | line                                                                      |
        |<span class="center bold double-height double-width">Have a nice day</span><span class="center bold double-height">User</span>|
        |<span class="center bold">Goodbye</span>|


	#TODO: iEntryMethods == eCustDevMgrCardEntryMethod::Unknown
	#      - no card entry method is recognized and response is now always with an error code 1001
    @positive @fast @manual
    Scenario Outline: Send PromptForSwipe command to the POS and validate the Standard Response.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/PromptForSwipeResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/PromptForSwipe", {"OperatorTitle": "ThisIsTheTitle", "OperatorText": "This is the message text", "AllowedEntryMethods": ["Manual", "Barcode"], "ManualEntryTitle": "This is the manualentry title", "ManualEntryText": "This is the manual entry text", "ManualEntryMinLength": 0, "ManualEnteryMaxLength": 30, "PromptTimeoutSeconds": 50}] | TODO |


    @negative @fast
    Scenario Outline: Send PromptForSwipe command to the POS with a modal frame opened and validate the response with an error notification.
        Given the POS is in a ready to sell state
        And the POS displays Age verification frame after scanning an item barcode 0369369369
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/PromptForSwipeResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/PromptForSwipe", {"OperatorTitle": "ThisIsTheTitle", "OperatorText": "This is the message text", "AllowedEntryMethods": ["Manual", "Barcode"], "ManualEntryTitle": "This is the manualentry title", "ManualEntryText": "This is the manual entry text", "ManualEntryMinLength": 0, "ManualEnteryMaxLength": 30, "PromptTimeoutSeconds": 50}] | {"ReturnCode": 1085, "ReturnCodeDescription": "Operation is not allowed at this time", "TransactionSequenceNumber": "*"} |


	@positive @fast
    Scenario Outline: Send RecallTransaction command to the POS and validate the Standard Response.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And current transaction is stored under Stored Transaction Sequence Number
        When the application sends RecallTransaction command with last stored Sequence Number to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/RecallTransactionResponse
        And POS Connect response data contain |<response_data>|
		And an item <item_name> with price <price> is in the virtual receipt
        And an item <item_name> with price <price> is in the current transaction

        Examples:
        | item_name   | price | response_data |
        | Sale Item A | 0.99  | {"TransactionData": {"TransactionTotal": 1.06, "TransactionSubTotal": 0.99, "TransactionBalance": 1.06, "TransactionTaxAmount": 0.07, "ItemList": [{"ExternalId": "ITT-099999999990-0-1", "Description": "Sale Item A", "ExtendedPriceAmount": 0.99, "POSModifier3Id": 0, "POSItemId": 990000000002, "Type": "Regular", "Quantity": 1, "ItemNumber": 1, "POSModifier2Id": 0, "POSModifier1Id": 990000000007, "UnitPriceAmount": 0.99}]}, "TransactionSequenceNumber": "*"} |


    @negative @fast
    Scenario Outline: Send RecallTransaction command with not existing transaction barcode to the POS and validate the response with an error notification.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/RecallTransactionResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/RecallTransaction", {"TransactionBarcode": "0010000000003749"}] | {"ReturnCode": 1035, "TransactionSequenceNumber": 0, "ReturnCodeDescription": "Transaction was not found."} |


	#TODO: SellFuel command with parameter "Type": "Postpay", find out how to get correct SaleNumber
    @positive @fast
    Scenario Outline: Send SellFuel command to the POS with a transaction in progress and validate the Standard Response.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellFuelResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/SellFuel", {"PumpNumber": 1, "Type": "Prepay", "Amount": 21.0}] | {"TransactionData": {"TransactionTotal": 22.06, "TransactionSubTotal": 21.99, "TransactionBalance": 22.06, "TransactionTaxAmount": 0.07, "ItemList": [{"ExternalId": "ITT-099999999990-0-1", "Description": "Sale Item A", "ExtendedPriceAmount": 0.99, "POSModifier3Id": 0, "POSItemId": 990000000002, "Type": "Regular", "Quantity": 1, "ItemNumber": 1, "POSModifier2Id": 0, "POSModifier1Id": 990000000007, "UnitPriceAmount": 0.99}, {"Description": "Prepay Fuel", "ExtendedPriceAmount": 21.0, "SaleType": "Prepay", "POSItemId": 5000000001, "Type": "Fuel", "PumpNumber": 1, "Quantity": 21.0, "ItemNumber": 2, "UnitPriceAmount": 1.00}]}, "TransactionSequenceNumber": "*"} |
        #TODO | ["Pos/SellFuel", {"PumpNumber": 1, "Type": "Postpay", "SaleNumber": TODO }] |  |


    @negative @fast
    Scenario Outline: Send SellFuel command with missing parameter to the POS and validate the response with an error notification.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellFuelResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/SellFuel", {"PumpNumber": 1, "Type": "Postpay"}] | {"ReturnCode": 1001, "TransactionSequenceNumber": "*", "ReturnCodeDescription": "Invalid Parameter SaleNumber is missing or the provided value is invalid."} |


	#TODO: have to be closed dialog frame: Ask-for-reason, RPOS-6966 incorrect metadata for Go Back button
    @positive @fast @manual
    Scenario Outline: Send DataNeeded command to the POS as a response to prompting for some data and validate the Standard Response.
        Given the POS is in a ready to sell state
        And the POS Connect has a pending |<pending_request>|
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data contain |<response_data>|

        Examples:
        | pending_request                       | request                                                                  | response_data |
        | ["Pos/DrawerLoan", {"Amount": 33.88}] | ["Pos/DataNeededResponse", {"DataType": "Integer", "NumericData": 2345}] | {"PromptId": 5031, "ListSelections": [{"Id": 70000000150, "Text": "RS 23 - Safe Loan"}, {"Id": 70000000072, "Text": "Safe Loan Reason"}], "PromptText": "Please Select a Reason", "DataType": "ListSelection", "AvailableOperations": [{"Name": "Cancel", "Text": ""}]} |


    @positive @fast
    Scenario Outline: Send SafeDrop command to the POS and validate the Standard Response.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SafeDropResponse
        And POS Connect response data contain |<response_data>|
        And an item <item_name> with price <item_price> is in the virtual receipt

        Examples:
        | request                            | item_name | item_price     | response_data                        |
        | ["Pos/SafeDrop", {"Amount": 10.5}] | Cash      | 10.5           | {"TransactionSequenceNumber": "*"}   |


    @positive @fast @manual
    Scenario Outline: Send SelectCoupon command to the POS with a transaction in progress and validate the Standard Response.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data contain |<response_data>|

        Examples:
        | request                                 | response_data   |
        | ["Pos/SelectCoupon", {"ItemNumber": 1}] | {"PromptText": "Coupon Lookup", "DataType": "ListSelection", "ListSelections": [{"Text": "Cpn $0.99 PreTax Itm", "Id": 75000000004}, {"Text": "Cpn $0.99 PstTax Itm", "Id": 75000000005}, {"Text": "Cpn $0.99 PstTax Tran", "Id": 75000000006}], "AvailableOperations": [{"Name": "Cancel", "Text": ""}], "PromptId": 0} |


    @negative @fast @manual
    Scenario Outline: Send SelectCoupon command to the POS with no transaction in progress and validate the response with an error notification.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SelectCouponResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request                                 | response_data   |
        | ["Pos/SelectCoupon", {"ItemNumber": 3}] | {"TransactionSequenceNumber": 0, "ReturnCode": 1017, "ReturnCodeDescription": "There is no transaction currently in progress."} |


    @negative @fast @manual
    Scenario Outline: Send SelectCoupon command to the POS with another request in progress and validate the response with an error notification.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the POS Connect has a pending |<pending_request>|
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SelectCouponResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | pending_request                         | request                                 | response_data                                                                               |
        | ["Pos/SelectCoupon", {"ItemNumber": 1}] | ["Pos/SelectCoupon", {"ItemNumber": 3}] | {"ReturnCode": 1022, "ReturnCodeDescription": "Another request is already in progress."}    |


	# TODO: there is an issue (temp: RPOS-8629) in character u/U and request SelectDiscount, specifically in the part {"ItemNUmber": 2}
    # only in form of capital letter U: 'ItemNUmber' are responses correctly
    @positive @fast @manual
    Scenario Outline: Send SelectDiscount command to the POS with no transaction in progress and validate the Standard Response.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data contain |<response_data>|

        Examples:
        | request                                   | response_data   |
        | ["Pos/SelectDiscount", {"ItemNUmber": 2}] | {"AvailableOperations": [{"Text": "", "Name": "Cancel"}], "PromptId": 1001, "PromptText": "Select Discount", "DataType": "ListSelection"} |


    # TODO: there is an issue (temp: RPOS-8629) in character u/U and request SelectDiscount, specifically in the part {"ItemNUmber": 2}
    # only in form of capital letter U: 'ItemNUmber' are responses correctly
    @positive @fast @manual
    Scenario Outline: Send SelectDiscount command to the POS with a transaction in progress and validate the Standard Response.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data contain |<response_data>|

        Examples:
        | request                                   | response_data                                                                                                                                                                                                                                                                                                                   |
        | ["Pos/SelectDiscount", {"ItemNUmber": 2}] | {"AvailableOperations": [{"Text": "", "Name": "Cancel"}], "ListSelections": [{"Text": "Dsc $0.99 PreTax Item", "Id": 75000000005}, {"Text": "Dsc $0.99 PstTax Item", "Id": 75000000006}, {"Text": "Dsc $0.99 PstTax Tran", "Id": 75000000007}], "PromptId": 1001, "PromptText": "Select Discount", "DataType": "ListSelection"} |


    @negative @fast @manual
    Scenario Outline: Send SelectDiscount command to the POS with another request in progress and validate the response with an error notification.
        Given the POS is in a ready to sell state
        And the POS Connect has a pending |<pending_request>|
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SelectDiscountResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | pending_request                           | request                                   | response_data                                                                            |
        | ["Pos/SelectDiscount", {"ItemNUmber": 2}] | ["Pos/SelectDiscount", {"ItemNUmber": 1}] | {"ReturnCodeDescription": "Another request is already in progress.", "ReturnCode": 1022} |


	#TODO: have to be ended the started transaction, POS is not set to Ready for sell state by the Given step
    @positive @fast @manual
    Scenario Outline: Send StartTransaction command to the POS with no transaction in progress and validate the Standard Response.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/StartTransactionResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request                                                                          | response_data                      |
        | ["Pos/StartTransaction", {"OriginSystemId": "Mobile", "OriginReferenceId": "M"}] | {"TransactionSequenceNumber": "*"} |


	@negative @fast
    Scenario Outline: Send StartTransaction command to the POS with a transaction in progress and validate the response with an error notification.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/StartTransactionResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request                                                                          | response_data                                                                                                                                         |
        | ["Pos/StartTransaction", {"OriginSystemId": "Mobile", "OriginReferenceId": "M"}] | {"TransactionSequenceNumber": "*", "ReturnCodeDescription": "Transaction cannot be started. Transaction is already in progress.", "ReturnCode": 1006} |


	@negative @fast
    Scenario Outline: Send FinalizeOrder command to the POS with a transaction in progress and validate the response with an error notification.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/FinalizeOrderResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request     | response_data |
        | ["Pos/FinalizeOrder", {"OriginReferenceId": "", "CustomerName": "Test Customer Name", "ItemList": [{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2}, {"POSItemId": 5070000031, "CondimentList": [{"POSItemId": 5070000032}, { "POSItemId": 5070000033}] }, { "Type": "Other", "ExternalId": "cash_tender", "Amount": 1.23 } ]}] | {"ReturnCodeDescription": "Transaction cannot be started. Transaction is already in progress.", "ReturnCode": 1006, "TransactionSequenceNumber": "*"} |


	@positive @fast
    Scenario Outline: Send FinalizeOrder command to the POS with no transaction in progress and validate the Standard Response.
                      UnitPriceAmount and/or ExtendedPriceAmount can be used for items in ItemList to specify price, ExtendedPriceAmount has priority if different.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/FinalizeOrderResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request     | response_data |
        | ["Pos/FinalizeOrder", {"OriginReferenceId": "", "CustomerName": "Test Customer Name", "ItemList": [{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2}, {"RposId": "990000000002-990000000007-0-0", "Quantity": 2}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 5.96} ]}]  | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 3.98, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 1.99}, {"Description": "Sale Item A", "ExtendedPriceAmount": 1.98, "ExternalId": "ITT-099999999990-0-1", "ItemNumber": 2, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 2, "Type": "Regular", "UnitPriceAmount": 0.99}, {"Description": "Cash", "ExtendedPriceAmount": -5.96, "ExternalId": "70000000023", "ItemNumber": 3, "Quantity": 1, "RequestItemNumber": 3, "Type": "Tender"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 5.96, "TransactionTaxAmount": 0.0, "TransactionTotal": 5.96} |
        | ["Pos/FinalizeOrder", {"OriginReferenceId": "", "CustomerName": "Test Customer Name", "ItemList": [{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2, "UnitPriceAmount": 1.05}, {"RposId": "990000000002-990000000007-0-0", "Quantity": 2, "ExtendedPriceAmount": 2.50}, {"RposId": "990000000002-990000000007-0-0", "Quantity": 2, "UnitPriceAmount": 1.25,"ExtendedPriceAmount": 2.50}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 7.1} ]}]  | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 2.1, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 1.05}, {"Description": "Sale Item A", "ExtendedPriceAmount": 5.00, "ExternalId": "ITT-099999999990-0-1", "ItemNumber": 2, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4, "RequestItemNumber": 2, "Type": "Regular", "UnitPriceAmount": 1.25}, {"Description": "Cash", "ExtendedPriceAmount": -7.1, "ExternalId": "70000000023", "ItemNumber": 4, "Quantity": 1, "RequestItemNumber": 4, "Type": "Tender"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 7.1, "TransactionTaxAmount": 0.0, "TransactionTotal": 7.1} |
        | ["Pos/FinalizeOrder", {"OriginReferenceId": "", "CustomerName": "Test Customer Name", "ItemList": [{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2, "UnitPriceAmount": 0.1, "ExtendedPriceAmount": 1.98}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 1.98} ]}]  | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 1.98, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 0.99}, {"Description": "Cash", "ExtendedPriceAmount": -1.98, "ExternalId": "70000000023", "ItemNumber": 2, "Quantity": 1, "RequestItemNumber": 2, "Type": "Tender"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 1.98, "TransactionTaxAmount": 0.0, "TransactionTotal": 1.98} |


    @positive @fast
    Scenario Outline: Send SellCondiment command to the POS with no transaction in progress, validate condiment is not added and correct response received.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellCondimentResponse
        And POS Connect response data contain |<response_data>|
        And no transaction is in progress

        Examples:
        | request                                          | response_data |
        | ["Pos/SellCondiment", {"POSItemId": 5070000296}] | {"ReturnCode": 1017, "ReturnCodeDescription": "There is no transaction currently in progress.", "TransactionSequenceNumber": 0} |


    @positive @fast
    Scenario Outline: Send SellCondiment command to the POS with no valid parent item in transaction, validate condiment is not added and correct response received.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellCondimentResponse
        And POS Connect response data contain |<response_data>|
        And an item <item_name> with price <price> is not in the current transaction

        Examples:
        | request                                          | item_name   | price | response_data |
        | ["Pos/SellCondiment", {"POSItemId": 5070000296}] | Mustard     | 0.0   | {"ReturnCode": 1002, "ReturnCodeDescription": "Item not found.", "TransactionSequenceNumber": "*"} |


    @positive @fast
    Scenario Outline: Send SellCondiment command to the POS with a valid parent item already in transaction, validate that the condiment is added to VR and current transaction.
        Given the POS is in a ready to sell state
        And the application sent |<request1>| to the POS Connect
        When the application sends |<request2>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellCondimentResponse
        And POS Connect response data contain |<response_data>|
        And a condiment <item_name> with price <price> is in the current transaction

        Examples:
        | request1                                                | item_name | price | request2 | response_data |
        | ["Pos/SellItem", {"POSItemId": 5070000318-70000000021}] | Mustard   | 0.0   | ["Pos/SellCondiment", {"POSItemId": 5070000296}] | {"TransactionData": {"ItemList": [{"Description": "Burger Classic 150 g", "ExtendedPriceAmount": 7.19, "ItemList": [{"Description": "Sesame Bun", "ExtendedPriceAmount": 0.0, "ItemNumber": 2, "POSItemId": 5070000290, "Quantity": 1, "Type": "Condiment", "UnitPriceAmount": 0.00}, {"Description": "Mayonnaise with Pepper", "ExtendedPriceAmount": 0.0, "ItemNumber": 3, "POSItemId": 5070000294, "Quantity": 1, "Type": "Condiment", "UnitPriceAmount": 0.00}, {"Description": "Gouda Slice", "ExtendedPriceAmount": 0.0, "ItemNumber": 4, "POSItemId": 5070000300, "Quantity": 1, "Type": "Condiment", "UnitPriceAmount": 0.00}, {"Description": "Bacon Chips", "ExtendedPriceAmount": 0.0, "ItemNumber": 5, "POSItemId": 5070000304, "Quantity": 1, "Type": "Condiment", "UnitPriceAmount": 0.00}, {"Description": "Pickle Slices", "ExtendedPriceAmount": 0.0, "ItemNumber": 6, "POSItemId": 5070000307, "Quantity": 1, "Type": "Condiment", "UnitPriceAmount": 0.00}, {"Description": "Red Onion Slices", "ExtendedPriceAmount": 0.0, "ItemNumber": 7, "POSItemId": 5070000312, "Quantity": 1, "Type": "Condiment", "UnitPriceAmount": 0.00}, {"Description": "Salad", "ExtendedPriceAmount": 0.0, "ItemNumber": 8, "POSItemId": 5070000316, "Quantity": 1, "Type": "Condiment", "UnitPriceAmount": 0.00}, {"Description": "Mustard","ExtendedPriceAmount": 0.0, "ItemNumber": 9, "POSItemId": 5070000296, "Quantity": 1, "Type": "Condiment", "UnitPriceAmount": 0.00}], "ItemNumber": 1, "POSItemId": 5070000318, "POSModifier1Id": 70000000020, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 7.19}], "TransactionBalance": 7.62, "TransactionSubTotal": 7.19, "TransactionTaxAmount": 0.43, "TransactionTotal": 7.62}, "TransactionSequenceNumber": "*"} |


    @positive @fast
    Scenario Outline: Send SellCondiment command to the POS with quantity greater than 1 and a valid parent item already in transaction, validate that the condiment is added to VR and current transaction.
        Given the POS is in a ready to sell state
        And the application sent |<request1>| to the POS Connect
        When the application sends |<request2>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellCondimentResponse
        And POS Connect response data contain |<response_data>|
        And a condiment <item_name> with price <price> is in the current transaction

        Examples:
        | request1                                                | item_name | price | request2 | response_data |
        | ["Pos/SellItem", {"POSItemId": 5070000318-70000000021}] | Mustard   | 0.0   | ["Pos/SellCondiment", {"POSItemId": 5070000296, "Quantity": 2}] | {"TransactionData": {"ItemList": [{"Description": "Burger Classic 150 g", "ExtendedPriceAmount": 7.19, "ItemList": [{"Description": "Sesame Bun", "ExtendedPriceAmount": 0.0, "ItemNumber": 2, "POSItemId": 5070000290, "Quantity": 1, "Type": "Condiment", "UnitPriceAmount": 0.00}, {"Description": "Mayonnaise with Pepper", "ExtendedPriceAmount": 0.0, "ItemNumber": 3, "POSItemId": 5070000294, "Quantity": 1, "Type": "Condiment", "UnitPriceAmount": 0.00}, {"Description": "Gouda Slice", "ExtendedPriceAmount": 0.0, "ItemNumber": 4, "POSItemId": 5070000300, "Quantity": 1, "Type": "Condiment", "UnitPriceAmount": 0.00}, {"Description": "Bacon Chips", "ExtendedPriceAmount": 0.0, "ItemNumber": 5, "POSItemId": 5070000304, "Quantity": 1, "Type": "Condiment", "UnitPriceAmount": 0.00}, {"Description": "Pickle Slices", "ExtendedPriceAmount": 0.0, "ItemNumber": 6, "POSItemId": 5070000307, "Quantity": 1, "Type": "Condiment", "UnitPriceAmount": 0.00}, {"Description": "Red Onion Slices", "ExtendedPriceAmount": 0.0, "ItemNumber": 7, "POSItemId": 5070000312, "Quantity": 1, "Type": "Condiment", "UnitPriceAmount": 0.00}, {"Description": "Salad", "ExtendedPriceAmount": 0.0, "ItemNumber": 8, "POSItemId": 5070000316, "Quantity": 1, "Type": "Condiment", "UnitPriceAmount": 0.00}, {"Description": "Mustard","ExtendedPriceAmount": 0.0, "ItemNumber": 9, "POSItemId": 5070000296, "Quantity": 2, "Type": "Condiment", "UnitPriceAmount": 0.00}], "ItemNumber": 1, "POSItemId": 5070000318, "POSModifier1Id": 70000000020, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 7.19}], "TransactionBalance": 7.62, "TransactionSubTotal": 7.19, "TransactionTaxAmount": 0.43, "TransactionTotal": 7.62}, "TransactionSequenceNumber": "*"} |


	@positive @fast
    Scenario Outline: Send GetStoredTransactions command to the POS with no stored transactions and validate the Standard Response.
        Given the POS is in a ready to sell state
        And the POS does not have any stored transactions
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/GetStoredTransactionsResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request                           | response_data               |
        | ["Pos/GetStoredTransactions", {}] | {"StoredTransactions": []}  |


    @positive @fast
    Scenario Outline: Send GetStoredTransactions command to the POS with stored transaction present and validate the Standard Response.
        Given the POS is in a ready to sell state
        And a transaction with item |<item_barcode>| is present in the Store and Recall queue
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/GetStoredTransactionsResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | item_barcode | request                           | response_data                             |
        | 099999999990 | ["Pos/GetStoredTransactions", {}] | {"StoredTransactions": [{"Number": "*"}]} |


    @positive @fast
    Scenario Outline: Send SellItem command to the POS for an Age restricted item, validate the DataNeeded Response, Age verification frame is displayed
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data contain |<response_data>|
        And the POS displays the Age verification frame

        Examples:
        | request                                     | response_data                             |
        | ["Pos/SellItem", {"Barcode": "0369369369"}] | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}, {"Name": "InstantApproval", "Text": "Over"}], "DataType": "Date", "PromptId": 5072, "PromptText": "Enter Customer's Birthday (MM/DD/YYYY)"} |


    @positive @fast
    Scenario Outline: Send DataNeededResponse command to the POS with a valid birthday format (YYYY-MM-DD or MMDDYYYY)
                      after attempting to sell an Age restricted item, validate the response, item is added to the transaction
        Given the POS is in a ready to sell state
        And the application sent |["Pos/SellItem", {"Barcode": "0369369369"}]| to the POS Connect
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|
        And the POS displays main menu frame
        And an item <item_description> with price <item_price> is in the current transaction

        Examples:
        | request                                                                | item_description  | item_price | response_data                             |
        | ["Pos/DataNeededResponse", {"DataType": "Date", "Date": "06091985"}]   | Age 18 Restricted | 3.69       | {"TransactionData": {"ItemList": [{"Description": "Age 18 Restricted", "ExtendedPriceAmount": 3.69, "ExternalId": "ITT-0369369369-0-1", "ItemNumber": 1, "POSItemId": 990000000010, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 3.69}], "TransactionBalance": 3.95, "TransactionSubTotal": 3.69, "TransactionTaxAmount": 0.26, "TransactionTotal": 3.95}, "TransactionSequenceNumber": "*"}|
        | ["Pos/DataNeededResponse", {"DataType": "Date", "Date": "1985-06-09"}] | Age 18 Restricted | 3.69       | {"TransactionData": {"ItemList": [{"Description": "Age 18 Restricted", "ExtendedPriceAmount": 3.69, "ExternalId": "ITT-0369369369-0-1", "ItemNumber": 1, "POSItemId": 990000000010, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 3.69}], "TransactionBalance": 3.95, "TransactionSubTotal": 3.69, "TransactionTaxAmount": 0.26, "TransactionTotal": 3.95}, "TransactionSequenceNumber": "*"}|


    @positive @fast
    Scenario Outline: Send DataNeededResponse command to the POS with a valid driver's license barcode after attempting to sell
                      an Age restricted item, validate the response, item is added to the transaction
        Given the POS is in a ready to sell state
        And the application sent |["Pos/SellItem", {"Barcode": "0369369369"}]| to the POS Connect
        When the application sends a valid DL barcode to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|
        And the POS displays main menu frame
        And an item <item_description> with price <item_price> is in the current transaction

        Examples:
        | item_description  | item_price | response_data                             |
        | Age 18 Restricted | 3.69       | {"TransactionData": {"ItemList": [{"Description": "Age 18 Restricted", "ExtendedPriceAmount": 3.69, "ExternalId": "ITT-0369369369-0-1", "ItemNumber": 1, "POSItemId": 990000000010, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 3.69}], "TransactionBalance": 3.95, "TransactionSubTotal": 3.69, "TransactionTaxAmount": 0.26, "TransactionTotal": 3.95}, "TransactionSequenceNumber": "*"}|


    @positive @fast
    Scenario Outline: Send DataNeededResponse command to the POS with an instant approval operation after attempting to sell
                      an Age restricted item, validate the response, item is added to the transaction
        Given the POS is in a ready to sell state
        And the application sent |["Pos/SellItem", {"Barcode": "0369369369"}]| to the POS Connect
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|
        And the POS displays main menu frame
        And an item <item_description> with price <item_price> is in the current transaction

        Examples:
        | request                                                                  | item_description  | item_price | response_data                             |
        | ["Pos/DataNeededResponse", {"SelectedOperationName": "InstantApproval"}] | Age 18 Restricted | 3.69       | {"TransactionData": {"ItemList": [{"Description": "Age 18 Restricted", "ExtendedPriceAmount": 3.69, "ExternalId": "ITT-0369369369-0-1", "ItemNumber": 1, "POSItemId": 990000000010, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 3.69}], "TransactionBalance": 3.95, "TransactionSubTotal": 3.69, "TransactionTaxAmount": 0.26, "TransactionTotal": 3.95}, "TransactionSequenceNumber": "*"} |


    @positive @fast
    Scenario Outline: Send DataNeededResponse command to the POS with a cancel operation after attempting to sell
                      an Age restricted item, validate the response, item is not added to the transaction
        Given the POS is in a ready to sell state
        And the application sent |["Pos/SellItem", {"Barcode": "0369369369"}]| to the POS Connect
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|
        And the POS displays main menu frame
        And an item <item_description> with price <item_price> is not in the current transaction

        Examples:
        | request                                                         | item_description  | item_price | response_data                             |
        | ["Pos/DataNeededResponse", {"SelectedOperationName": "Cancel"}] | Age 18 Restricted | 3.69       | {"ReturnCode": 1016, "ReturnCodeDescription": "Operation was cancelled.", "TransactionSequenceNumber": "*"} |


    @positive @fast
    Scenario Outline: Send Carwash code together with a SellItem request for a Carwash item, validate the response,
                      Carwash is added to the transaction.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|
        And an item <description> with price <amount> and quantity <quantity> is in the virtual receipt
        And an item <description> with price <amount> and type 10 is in the current transaction

        Examples:
        | description   | amount | quantity | request | response_data |
        | Full Car wash | 9.99   | 1        | ["Pos/SellItem", {"Barcode": "1234567890", "Quantity": 1, "Carwash": {"Code": "123"}}] | {"TransactionData": {"ItemList": [{"Description": "Full Car wash", "ExtendedPriceAmount": 9.99, "ExternalId": "Full Carwash Ext ID", "ItemNumber": 1, "POSItemId": 5070000057, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 9.99}], "TransactionBalance": 9.99, "TransactionSubTotal": 9.99, "TransactionTaxAmount": 0.00, "TransactionTotal": 9.99}, "TransactionSequenceNumber": "*"}|
        | Full Car wash | 9.99   | 1        | ["Pos/SellItem", {"ExternalId": "Full Carwash Ext ID", "Quantity": 1, "Carwash": {"Code": "123"}}] | {"TransactionData": {"ItemList": [{"Description": "Full Car wash", "ExtendedPriceAmount": 9.99, "ExternalId": "Full Carwash Ext ID", "ItemNumber": 1, "POSItemId": 5070000057, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 9.99}], "TransactionBalance": 9.99, "TransactionSubTotal": 9.99, "TransactionTaxAmount": 0.00, "TransactionTotal": 9.99}, "TransactionSequenceNumber": "*"}|
        | Full Car wash | 9.99   | 1        | ["Pos/SellItem", {"POSItemId": 5070000057, "Quantity": 1, "Carwash": {"Code": "123"}}] | {"TransactionData": {"ItemList": [{"Description": "Full Car wash", "ExtendedPriceAmount": 9.99, "ExternalId": "Full Carwash Ext ID", "ItemNumber": 1, "POSItemId": 5070000057, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 9.99}], "TransactionBalance": 9.99, "TransactionSubTotal": 9.99, "TransactionTaxAmount": 0.00, "TransactionTotal": 9.99}, "TransactionSequenceNumber": "*"}|


    @positive @fast
    Scenario Outline: Send Carwash code and a valid expiration date together with a SellItem request for a Carwash item,
                      validate the response, Carwash is added to the transaction.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|
        And an item <description> with price <amount> and quantity <quantity> is in the virtual receipt
        And an item <description> with price <amount> and type 10 is in the current transaction

        Examples:
        | description   | amount | quantity | request | response_data |
        | Full Car wash | 9.99   | 1        | ["Pos/SellItem", {"Barcode": "1234567890", "Quantity": 1, "Carwash": {"Code": "123", "ExpirationDate": "2025-04-21T11:00:00"}}] | {"TransactionData": {"ItemList": [{"Description": "Full Car wash", "ExtendedPriceAmount": 9.99, "ExternalId": "Full Carwash Ext ID", "ItemNumber": 1, "POSItemId": 5070000057, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 9.99}], "TransactionBalance": 9.99, "TransactionSubTotal": 9.99, "TransactionTaxAmount": 0.00, "TransactionTotal": 9.99}, "TransactionSequenceNumber": "*"}|
        | Full Car wash | 9.99   | 1        | ["Pos/SellItem", {"ExternalId": "Full Carwash Ext ID", "Quantity": 1, "Carwash": {"Code": "123", "ExpirationDate": "2025-04-21T11:00:00"}}] | {"TransactionData": {"ItemList": [{"Description": "Full Car wash", "ExtendedPriceAmount": 9.99, "ExternalId": "Full Carwash Ext ID", "ItemNumber": 1, "POSItemId": 5070000057, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 9.99}], "TransactionBalance": 9.99, "TransactionSubTotal": 9.99, "TransactionTaxAmount": 0.00, "TransactionTotal": 9.99}, "TransactionSequenceNumber": "*"}|
        | Full Car wash | 9.99   | 1        | ["Pos/SellItem", {"POSItemId": 5070000057, "Quantity": 1, "Carwash": {"Code": "123", "ExpirationDate": "2025-04-21T11:00:00"}}] | {"TransactionData": {"ItemList": [{"Description": "Full Car wash", "ExtendedPriceAmount": 9.99, "ExternalId": "Full Carwash Ext ID", "ItemNumber": 1, "POSItemId": 5070000057, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 9.99}], "TransactionBalance": 9.99, "TransactionSubTotal": 9.99, "TransactionTaxAmount": 0.00, "TransactionTotal": 9.99}, "TransactionSequenceNumber": "*"}|
        | Full Car wash | 9.99   | 1        | ["Pos/SellItem", {"RposId": "5070000057-0-0-0", "Quantity": 1, "Carwash": {"Code": "123", "ExpirationDate": "2025-04-21T11:00:00"}}] | {"TransactionData": {"ItemList": [{"Description": "Full Car wash", "ExtendedPriceAmount": 9.99, "ExternalId": "Full Carwash Ext ID", "ItemNumber": 1, "POSItemId": 5070000057, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 9.99}], "TransactionBalance": 9.99, "TransactionSubTotal": 9.99, "TransactionTaxAmount": 0.00, "TransactionTotal": 9.99}, "TransactionSequenceNumber": "*"}|


    @negative @fast
    Scenario Outline: Send Carwash code together with a SellItem request for non-Carwash retail item, validate the response,
                      proper error code is returned, item is not added to the transaction.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|
        And an item <description> with price <amount> is not in the virtual receipt
        And an item <description> with price <amount> and type 10 is not in the current transaction

        Examples:
        | description | amount | request | response_data |
        | Sale Item A | 0.99   | ["Pos/SellItem", {"Barcode": "099999999990", "Quantity": 1, "Carwash": {"Code": "123"}}] | {"ReturnCode": 1107, "ReturnCodeDescription": "Carwash code is in invalid item.", "TransactionSequenceNumber": "*"}|
        | Sale Item A | 0.99   | ["Pos/SellItem", {"ExternalId": "ITT-099999999990-0-1", "Quantity": 1, "Carwash": {"Code": "123"}}] | {"ReturnCode": 1107, "ReturnCodeDescription": "Carwash code is in invalid item.", "TransactionSequenceNumber": "*"}|
        | Sale Item A | 0.99   | ["Pos/SellItem", {"POSItemId": 990000000002, "POSModifier1Id": 990000000007, "Quantity": 1, "Carwash": {"Code": "123"}}] | {"ReturnCode": 1107, "ReturnCodeDescription": "Carwash code is in invalid item.", "TransactionSequenceNumber": "*"}|
        | Sale Item A | 0.99   | ["Pos/SellItem", {"Barcode": "099999999990", "Quantity": 1, "Carwash": {"Code": "123", "ExpirationDate": "2025-04-21T11:00:00"}}] | {"ReturnCode": 1107, "ReturnCodeDescription": "Carwash code is in invalid item.", "TransactionSequenceNumber": "*"}|
        | Sale Item A | 0.99   | ["Pos/SellItem", {"ExternalId": "ITT-099999999990-0-1", "Quantity": 1, "Carwash": {"Code": "123", "ExpirationDate": "1989-04-21T11:00:00"}}] | {"ReturnCode": 1107, "ReturnCodeDescription": "Carwash code is in invalid item.", "TransactionSequenceNumber": "*"}|
        | Sale Item A | 0.99   | ["Pos/SellItem", {"POSItemId": 990000000002, "POSModifier1Id": 990000000007, "Quantity": 1, "Carwash": {"Code": "123", "ExpirationDate": "1989-04-21T11:00:00"}}] | {"ReturnCode": 1107, "ReturnCodeDescription": "Carwash code is in invalid item.", "TransactionSequenceNumber": "*"}|


    @negative @fast
    Scenario Outline: Send Carwash code and invalid expiration date together with a SellItem request for a Carwash retail item,
                      validate the response, proper error code is returned, item is not added to the transaction.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|
        And an item <description> with price <amount> is not in the virtual receipt
        And no transaction is in progress

        Examples:
        | description   | amount | request | response_data |
        | Full Car wash | 9.99   | ["Pos/SellItem", {"Barcode": "1234567890", "Quantity": 1, "Carwash": {"Code": "123", "ExpirationDate": "04-21-2021T11:00:00"}}] | {"ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter ExpirationDate isn't validly fomratted as ISO date (YYYY-MM-DDTHH:mm:SS).", "TransactionSequenceNumber": "*"} |
        | Full Car wash | 9.99   | ["Pos/SellItem", {"ExternalId": "Full Carwash Ext ID", "Quantity": 1, "Carwash": {"Code": "123", "ExpirationDate": "11:00:00T2021-04-21"}}] | {"ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter ExpirationDate isn't validly fomratted as ISO date (YYYY-MM-DDTHH:mm:SS).", "TransactionSequenceNumber": "*"}|
        | Full Car wash | 9.99   | ["Pos/SellItem", {"POSItemId": 5070000057, "Quantity": 1, "Carwash": {"Code": "123", "ExpirationDate": "2019"}}] | {"ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter ExpirationDate isn't validly fomratted as ISO date (YYYY-MM-DDTHH:mm:SS).", "TransactionSequenceNumber": "*"} |


    @positive @fast
    Scenario Outline: Send Carwash code together with a Carwash item in FinalizeOrder command to the POS and validate
                      the response, the transaction is finalized.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/FinalizeOrderResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request     | response_data |
        | ["Pos/FinalizeOrder", {"OriginReferenceId": "", "CustomerName": "Test Customer Name", "ItemList": [{"POSItemId": 5070000057, "Quantity": 1, "Carwash": {"Code": "123"}}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 9.99} ]}]  | {"ItemList": [{"Description": "Full Car wash", "ExtendedPriceAmount": 9.99, "ExternalId": "Full Carwash Ext ID", "ItemNumber": 1, "POSItemId": 5070000057, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 9.99}, {"Description": "Cash", "ExtendedPriceAmount": -9.99, "ExternalId": "70000000023", "ItemNumber": 3, "Quantity": 1, "RequestItemNumber": 2, "Type": "Tender"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 9.99, "TransactionTaxAmount": 0.0, "TransactionTotal": 9.99} |
        | ["Pos/FinalizeOrder", {"OriginReferenceId": "Some ID 123456", "CustomerName": "Test Customer Name", "ItemList": [{"Barcode": "1234567890", "Quantity": 1, "Carwash": {"Code": "123"}}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 9.99} ]}]  | {"ItemList": [{"Description": "Full Car wash", "ExtendedPriceAmount": 9.99, "ExternalId": "Full Carwash Ext ID", "ItemNumber": 1, "POSItemId": 5070000057, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 9.99}, {"Description": "Cash", "ExtendedPriceAmount": -9.99, "ExternalId": "70000000023", "ItemNumber": 3, "Quantity": 1, "RequestItemNumber": 2, "Type": "Tender"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 9.99, "TransactionTaxAmount": 0.0, "TransactionTotal": 9.99} |
        | ["Pos/FinalizeOrder", {"OriginReferenceId": "Origin unknown", "CustomerName": "Test Customer Name", "ItemList": [{"ExternalId": "Full Carwash Ext ID", "Quantity": 1, "Carwash": {"Code": "123"}}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 9.99} ]}]  | {"ItemList": [{"Description": "Full Car wash", "ExtendedPriceAmount": 9.99, "ExternalId": "Full Carwash Ext ID", "ItemNumber": 1, "POSItemId": 5070000057, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 9.99}, {"Description": "Cash", "ExtendedPriceAmount": -9.99, "ExternalId": "70000000023", "ItemNumber": 3, "Quantity": 1, "RequestItemNumber": 2, "Type": "Tender"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 9.99, "TransactionTaxAmount": 0.0, "TransactionTotal": 9.99} |


    @positive @fast
    Scenario Outline: Send Carwash code and a valid format of expiration date together with a Carwash item in
                      FinalizeOrder command to the POS and validate the response, the transaction is finalized.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/FinalizeOrderResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request     | response_data |
        | ["Pos/FinalizeOrder", {"OriginReferenceId": "", "CustomerName": "Test Customer Name", "ItemList": [{"POSItemId": 5070000057, "Quantity": 1, "Carwash": {"Code": "123", "ExpirationDate": "2021-04-21T11:00:00"}}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 9.99} ]}]  | {"ItemList": [{"Description": "Full Car wash", "ExtendedPriceAmount": 9.99, "ExternalId": "Full Carwash Ext ID", "ItemNumber": 1, "POSItemId": 5070000057, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 9.99}, {"Description": "Cash", "ExtendedPriceAmount": -9.99, "ExternalId": "70000000023", "ItemNumber": 3, "Quantity": 1, "RequestItemNumber": 2, "Type": "Tender"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 9.99, "TransactionTaxAmount": 0.0, "TransactionTotal": 9.99} |
        | ["Pos/FinalizeOrder", {"OriginReferenceId": "", "CustomerName": "Test Customer Name", "ItemList": [{"RposId": "5070000057-0-0-0", "Quantity": 1, "Carwash": {"Code": "123", "ExpirationDate": "2021-04-21T11:00:00"}}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 9.99} ]}]  | {"ItemList": [{"Description": "Full Car wash", "ExtendedPriceAmount": 9.99, "ExternalId": "Full Carwash Ext ID", "ItemNumber": 1, "POSItemId": 5070000057, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 9.99}, {"Description": "Cash", "ExtendedPriceAmount": -9.99, "ExternalId": "70000000023", "ItemNumber": 3, "Quantity": 1, "RequestItemNumber": 2, "Type": "Tender"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 9.99, "TransactionTaxAmount": 0.0, "TransactionTotal": 9.99} |
        | ["Pos/FinalizeOrder", {"OriginReferenceId": "", "CustomerName": "Test Customer Name", "ItemList": [{"Barcode": "1234567890", "Quantity": 1, "Carwash": {"Code": "123", "ExpirationDate": "2021-04-21T11:00:00"}}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 9.99} ]}]  | {"ItemList": [{"Description": "Full Car wash", "ExtendedPriceAmount": 9.99, "ExternalId": "Full Carwash Ext ID", "ItemNumber": 1, "POSItemId": 5070000057, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 9.99}, {"Description": "Cash", "ExtendedPriceAmount": -9.99, "ExternalId": "70000000023", "ItemNumber": 3, "Quantity": 1, "RequestItemNumber": 2, "Type": "Tender"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 9.99, "TransactionTaxAmount": 0.0, "TransactionTotal": 9.99} |
        | ["Pos/FinalizeOrder", {"OriginReferenceId": "", "CustomerName": "Test Customer Name", "ItemList": [{"ExternalId": "Full Carwash Ext ID", "Quantity": 1, "Carwash": {"Code": "123", "ExpirationDate": "1989-04-21T11:00:00"}}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 9.99} ]}]  | {"ItemList": [{"Description": "Full Car wash", "ExtendedPriceAmount": 9.99, "ExternalId": "Full Carwash Ext ID", "ItemNumber": 1, "POSItemId": 5070000057, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 9.99}, {"Description": "Cash", "ExtendedPriceAmount": -9.99, "ExternalId": "70000000023", "ItemNumber": 3, "Quantity": 1, "RequestItemNumber": 2, "Type": "Tender"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 9.99, "TransactionTaxAmount": 0.0, "TransactionTotal": 9.99} |


    @negative @fast
    Scenario Outline: Send Carwash code together with a non-Carwash item in FinalizeOrder command to the POS and validate
                      the response, proper error code is returned.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/FinalizeOrderResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request     | response_data |
        | ["Pos/FinalizeOrder", {"OriginReferenceId": "", "CustomerName": "Test Customer Name", "ItemList": [{"POSItemId": 990000000002, "POSModifier1Id": 990000000007, "Quantity": 1, "Carwash": {"Code": "123"}}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 9.99} ]}]  | {"ItemList": [{"POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 1, "ReturnCode": 1107, "ReturnCodeDescription": "Carwash code is in invalid item."}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 0.0, "TransactionSequenceNumber": 0, "TransactionSubTotal": 0.0, "TransactionTaxAmount": 0.0, "TransactionTotal": 0.0} |
        | ["Pos/FinalizeOrder", {"OriginReferenceId": "", "CustomerName": "Test Customer Name", "ItemList": [{"Barcode": "099999999990", "Quantity": 1, "Carwash": {"Code": "123"}}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 9.99} ]}]  | {"ItemList": [{"Barcode": "099999999990", "POSItemId": 0, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 1, "ReturnCode": 1107, "ReturnCodeDescription": "Carwash code is in invalid item."}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 0.0, "TransactionSequenceNumber": 0, "TransactionSubTotal": 0.0, "TransactionTaxAmount": 0.0, "TransactionTotal": 0.0} |
        | ["Pos/FinalizeOrder", {"OriginReferenceId": "", "CustomerName": "Test Customer Name", "ItemList": [{"ExternalId": "ITT-099999999990-0-1", "Quantity": 1, "Carwash": {"Code": "123"}}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 9.99} ]}]  | {"ItemList": [{"ExternalId": "ITT-099999999990-0-1", "POSItemId": 0, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 1, "ReturnCode": 1107, "ReturnCodeDescription": "Carwash code is in invalid item."}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 0.0, "TransactionSequenceNumber": 0, "TransactionSubTotal": 0.0, "TransactionTaxAmount": 0.0, "TransactionTotal": 0.0} |


    @negative @fast
    Scenario Outline: Send Carwash code and an invalid expiration date together with a Carwash item in FinalizeOrder command
                      to the POS and validate the response, proper error code is returned.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/FinalizeOrderResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request     | response_data |
        | ["Pos/FinalizeOrder", {"OriginReferenceId": "", "CustomerName": "Test Customer Name", "ItemList": [{"POSItemId": 5070000057, "Quantity": 1, "Carwash": {"Code": "123", "ExpirationDate": "2010-04T11:00"}}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 9.99} ]}]  | {"ItemList": [{"POSItemId": 5070000057, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 1, "ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter ExpirationDate isn't validly fomratted as ISO date (YYYY-MM-DDTHH:mm:SS)."}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 0.0, "TransactionSequenceNumber": 0, "TransactionSubTotal": 0.0, "TransactionTaxAmount": 0.0, "TransactionTotal": 0.0} |
        | ["Pos/FinalizeOrder", {"OriginReferenceId": "", "CustomerName": "Test Customer Name", "ItemList": [{"Barcode": "1234567890", "Quantity": 1, "Carwash": {"Code": "123", "ExpirationDate": "11:00:00T2010-04-21"}}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 9.99} ]}]  | {"ItemList": [{"Barcode": "1234567890", "POSItemId": 0, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 1, "ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter ExpirationDate isn't validly fomratted as ISO date (YYYY-MM-DDTHH:mm:SS)."}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 0.0, "TransactionSequenceNumber": 0, "TransactionSubTotal": 0.0, "TransactionTaxAmount": 0.0, "TransactionTotal": 0.0} |
        | ["Pos/FinalizeOrder", {"OriginReferenceId": "", "CustomerName": "Test Customer Name", "ItemList": [{"ExternalId": "Full Carwash Ext ID", "Quantity": 1, "Carwash": {"Code": "123", "ExpirationDate": "11:00:00"}}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 9.99} ]}]  | {"ItemList": [{"ExternalId": "Full Carwash Ext ID", "POSItemId": 0, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 1, "ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter ExpirationDate isn't validly fomratted as ISO date (YYYY-MM-DDTHH:mm:SS)."}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 0.0, "TransactionSequenceNumber": 0, "TransactionSubTotal": 0.0, "TransactionTaxAmount": 0.0, "TransactionTotal": 0.0} |


    @positive @fast
    Scenario Outline: Send FormatReceipt block with different values of customer and merchant copies in FinalizeOrder
                      command to the POS and validate the response, the transaction is finalized. Any integer value > 0
                      is treated as 1, anything else as 0 (even incorrect data types).
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/FinalizeOrderResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request     | response_data |
        | ["Pos/FinalizeOrder", {"ItemList": [{"Barcode": "099999999990", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 0.99 } ]}]                                                                                      | {"ItemList": [{"Description": "Sale Item A", "ExtendedPriceAmount": 0.99, "ExternalId": "ITT-099999999990-0-1", "ItemNumber": 1, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 0.99}, {"Description": "Cash", "ExtendedPriceAmount": -0.99, "ExternalId": "70000000023", "ItemNumber": 2, "Quantity": 1, "RequestItemNumber": 2, "Type": "Tender"}], "TransactionBalance": 0.00, "TransactionSequenceNumber": "*", "TransactionSubTotal": 0.99, "TransactionTaxAmount": 0.00, "TransactionTotal": 0.99} |
        | ["Pos/FinalizeOrder", {"FormatReceipt": {"PrintFormat": "NCRPRINTAPI", "Merchant": 1, "Customer": 1}, "ItemList": [{"Barcode": "099999999990", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 0.99 } ]}]       | {"ItemList":"*","Receipt":{"Customer":{"PrintCommands":[{"Align":"Center","Bold":"Yes","CellWidth":40,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"POSBDD","Underline":"No","Width":"Normal"},{"Align":"Center","Bold":"Yes","CellWidth":40,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"Python Lane 702","Underline":"No","Width":"Normal"},{"Align":"Center","Bold":"Yes","CellWidth":40,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"Behave City, BDD State 79201","Underline":"No","Width":"Normal"},{"Align":"Center","Bold":"No","CellWidth":40,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"------------------------------------------------------------------------","Underline":"No","Width":"Normal"},{"Align":"Right","Bold":"No","CellWidth":19,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"*","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":2,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":19,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"*","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":40,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":9,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"Register:","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":" ","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":7,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"1","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":13,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"Tran Seq No:","Underline":"No","Width":"Normal"},{"Align":"Right","Bold":"No","CellWidth":10,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"*","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":9,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"Store No:","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":" ","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":5,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"79201-1","Underline":"No","Width":"Normal"},{"Align":"Right","Bold":"No","CellWidth":25,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"1234, 🞀Cashier🞁","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":40,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"","Underline":"No","Width":"Normal"},{"Align":"Center","Bold":"No","CellWidth":40,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"(CUSTOMER RECEIPT)","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":1,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"I","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":4,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"1","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":" ","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":24,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"Sale Item A","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":" ","Underline":"No","Width":"Normal"},{"Align":"Right","Bold":"No","CellWidth":9,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"$0.99","Underline":"No","Width":"Normal"},{"Align":"Right","Bold":"No","CellWidth":40,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"-----------","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":30,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"Sub. Total:","Underline":"No","Width":"Normal"},{"Align":"Right","Bold":"No","CellWidth":10,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"$0.99","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":30,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"Tax:","Underline":"No","Width":"Normal"},{"Align":"Right","Bold":"No","CellWidth":10,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"$0.00","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":30,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"Total:","Underline":"No","Width":"Normal"},{"Align":"Right","Bold":"No","CellWidth":10,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"$0.99","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":30,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"Discount Total:","Underline":"No","Width":"Normal"},{"Align":"Right","Bold":"No","CellWidth":10,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"$0.00","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":40,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":30,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"Cash","Underline":"No","Width":"Normal"},{"Align":"Right","Bold":"No","CellWidth":10,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"$0.99","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":30,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"Change","Underline":"No","Width":"Normal"},{"Align":"Right","Bold":"No","CellWidth":10,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"$0.00","Underline":"No","Width":"Normal"},{"Align":"Center","Bold":"Yes","CellWidth":40,"Command":"Text","Font":"Normal","Height":"Double","Italics":"No","NewLine":"Yes","Text":"Thanks","Underline":"No","Width":"Normal"},{"Align":"Center","Bold":"Yes","CellWidth":40,"Command":"Text","Font":"Normal","Height":"Double","Italics":"No","NewLine":"Yes","Text":"For Your Business","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":40,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"","Underline":"No","Width":"Normal"},{"Command":"CutPaper","HalfCut":"No"}],"PrintFormat":"NCRPRINTAPI"},"Merchant":{"PrintCommands":[{"Align":"Center","Bold":"Yes","CellWidth":40,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"POSBDD","Underline":"No","Width":"Normal"},{"Align":"Center","Bold":"Yes","CellWidth":40,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"Python Lane 702","Underline":"No","Width":"Normal"},{"Align":"Center","Bold":"Yes","CellWidth":40,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"Behave City, BDD State 79201","Underline":"No","Width":"Normal"},{"Align":"Center","Bold":"No","CellWidth":40,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"------------------------------------------------------------------------","Underline":"No","Width":"Normal"},{"Align":"Right","Bold":"No","CellWidth":19,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"*","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":2,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":19,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"*","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":40,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":9,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"Register:","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":" ","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":7,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"1","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":13,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"Tran Seq No:","Underline":"No","Width":"Normal"},{"Align":"Right","Bold":"No","CellWidth":10,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"*","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":9,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"Store No:","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":" ","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":5,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"79201-1","Underline":"No","Width":"Normal"},{"Align":"Right","Bold":"No","CellWidth":25,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"1234, 🞀Cashier🞁","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":40,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"","Underline":"No","Width":"Normal"},{"Align":"Center","Bold":"No","CellWidth":40,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"(MERCHANT RECEIPT)","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":1,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"I","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":4,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"1","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":" ","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":24,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"Sale Item A","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":" ","Underline":"No","Width":"Normal"},{"Align":"Right","Bold":"No","CellWidth":9,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"$0.99","Underline":"No","Width":"Normal"},{"Align":"Right","Bold":"No","CellWidth":40,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"-----------","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":30,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"Sub. Total:","Underline":"No","Width":"Normal"},{"Align":"Right","Bold":"No","CellWidth":10,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"$0.99","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":30,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"Tax:","Underline":"No","Width":"Normal"},{"Align":"Right","Bold":"No","CellWidth":10,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"$0.00","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":30,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"Total:","Underline":"No","Width":"Normal"},{"Align":"Right","Bold":"No","CellWidth":10,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"$0.99","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":30,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"Discount Total:","Underline":"No","Width":"Normal"},{"Align":"Right","Bold":"No","CellWidth":10,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"$0.00","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":40,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":30,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"Cash","Underline":"No","Width":"Normal"},{"Align":"Right","Bold":"No","CellWidth":10,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"$0.99","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":30,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"No","Text":"Change","Underline":"No","Width":"Normal"},{"Align":"Right","Bold":"No","CellWidth":10,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"$0.00","Underline":"No","Width":"Normal"},{"Align":"Center","Bold":"Yes","CellWidth":40,"Command":"Text","Font":"Normal","Height":"Double","Italics":"No","NewLine":"Yes","Text":"Thanks","Underline":"No","Width":"Normal"},{"Align":"Center","Bold":"Yes","CellWidth":40,"Command":"Text","Font":"Normal","Height":"Double","Italics":"No","NewLine":"Yes","Text":"For Your Business","Underline":"No","Width":"Normal"},{"Align":"Left","Bold":"No","CellWidth":40,"Command":"Text","Font":"Normal","Height":"Normal","Italics":"No","NewLine":"Yes","Text":"","Underline":"No","Width":"Normal"},{"Command":"CutPaper","HalfCut":"No"}],"PrintFormat":"NCRPRINTAPI"}},"TransactionBalance":0.00,"TransactionSequenceNumber":"*","TransactionSubTotal":0.99,"TransactionTaxAmount":0.00,"TransactionTotal":0.99} |
        | ["Pos/FinalizeOrder", {"FormatReceipt": {"PrintFormat": "NCRPRINTAPI", "Customer": 1}, "ItemList": [{"Barcode": "099999999990", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 0.99 } ]}]                      | {"ItemList":"*","Receipt":{"Customer":{"PrintCommands":"*","PrintFormat":"NCRPRINTAPI"}},"TransactionBalance":0.0,"TransactionSequenceNumber":"*","TransactionSubTotal":0.99,"TransactionTaxAmount":0.0,"TransactionTotal":0.99} |
        | ["Pos/FinalizeOrder", {"FormatReceipt": {"PrintFormat": "NCRPRINTAPI", "Customer": 0, "Merchant": 1}, "ItemList": [{"Barcode": "099999999990", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 0.99 } ]}]       | {"ItemList":"*","Receipt":{"Merchant":{"PrintCommands":"*","PrintFormat":"NCRPRINTAPI"}},"TransactionBalance":0,"TransactionSequenceNumber":"*","TransactionSubTotal":0.99,"TransactionTaxAmount":0,"TransactionTotal":0.99}|
        | ["Pos/FinalizeOrder", {"FormatReceipt": {"PrintFormat": "NCRPRINTAPI", "Customer": 5, "Merchant": "No"}, "ItemList": [{"Barcode": "099999999990", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 0.99 } ]}]    | {"ItemList":"*","Receipt":{"Customer":{"PrintCommands":"*","PrintFormat":"NCRPRINTAPI"}},"TransactionBalance":0,"TransactionSequenceNumber":"*","TransactionSubTotal":0.99,"TransactionTaxAmount":0,"TransactionTotal":0.99} |
        | ["Pos/FinalizeOrder", {"FormatReceipt": {"PrintFormat": "NCRPRINTAPI", "Customer": -1, "Merchant": 1.0}, "ItemList": [{"Barcode": "099999999990", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 0.99 } ]}]    | {"ItemList":"*","TransactionBalance":0,"TransactionSequenceNumber":"*","TransactionSubTotal":0.99,"TransactionTaxAmount":0,"TransactionTotal":0.99} |
        | ["Pos/FinalizeOrder", {"FormatReceipt": {"PrintFormat": "WRONGPRINTAPI", "Customer": 1, "Merchant": 1}, "ItemList": [{"Barcode": "099999999990", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 0.99 } ]}]     | {"ItemList":"*","TransactionBalance":0,"TransactionSequenceNumber":"*","TransactionSubTotal":0.99,"TransactionTaxAmount":0,"TransactionTotal":0.99} |


    @positive @fast
    Scenario Outline: Send FinalizeOrder command with autocombo to the POS, validate the autocombo is present in the response.
        Given the pricebook contains autocombos
              | description         | external_id | reduction_value | disc_type           | disc_mode         | disc_quantity | item_name   | quantity |
              | MyAutocombo         | 12345       | 10000           | AUTO_COMBO_AMOUNT   | WHOLE_TRANSACTION | STACKABLE     | Sale Item B | 1        |
        And the POS is in a ready to sell state
        When the application sends |<finalize_order_request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/FinalizeOrderResponse
        And POS Connect response data contain |<autocombo_response>|

        Examples:
        | autocombo_response | finalize_order_request |
        | {"Description": "MyAutocombo", "DiscountType": "AutoCombo", "ExtendedPriceAmount": -10.0, "ItemNumber": 8, "Quantity": 10, "ReductionList": [{"Description": "MyAutocombo", "DiscountedItemNumber": 1, "ExtendedPriceAmount": -1.0, "ExternalId": "12345", "ItemNumber": 5, "Quantity": 1, "RposId": "990000000050-0-0-0", "Type": "Discount", "UnitPriceAmount": -1.0}], "RequestItemNumber": 2, "RposId": "990000000050-0-0-0", "Type": "Discount", "UnitPriceAmount": -1.0} | ["Pos/FinalizeOrder", {"OriginSystemId": "Batch-test", "ItemList": [{"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 10}, {"Type": "AutoCombo", "ExternalId": "12345", "Quantity": 10, "ReductionList": [{"ExternalId": "12345", "Type": "Discount", "Quantity": 1, "Amount": 1.00, "DiscountedItemNumber": 1}]}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 10.6, "BatchNumber": 90, "BatchSequenceNumber": 654}, {"Type": "Tax", "ExternalId": "103", "Amount": 0.4}, {"Type": "Tax", "ExternalId": "102", "Amount": 0.2}, {"Type": "Tax", "ExternalId": "101", "Amount": 0.1}]}] |


    @negative @fast
    Scenario Outline: Send a locked item in an ItemList batch through various requests, validate that a proper error
                      code is returned even when other valid items are in the request as well.
        Given the POS has following sale items locked
            | barcode      | description | price  | item_id      | modifier1_id |
            | 099999999990 | Sale Item A | 0.99   | 990000000002 | 990000000007 |
            | 088888888880 | Sale Item B | 1.99   | 990000000003 | 990000000007 |
            | 077777777770 | Sale Item C | 1.49   | 990000000004 | 990000000007 |
        And the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/SellItem", {"Barcode": "099999999990", "Quantity": 1}] | {"ReturnCode": 1108, "ReturnCodeDescription": "Item is locked.", "TransactionSequenceNumber": "*"} |
        | ["Pos/SubTotalOrder", {"ItemList": [{"ExternalId": "ITT-099999999990-0-1", "Quantity": 1}, {"Barcode": "077777777770", "Quantity": 1}, {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1}, {"Barcode": "066666666660", "Quantity": 1}]}] | {"ItemList": [{"ExternalId": "ITT-099999999990-0-1", "POSItemId": 0, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 1, "ReturnCode": 1108, "ReturnCodeDescription": "Item is locked."}, {"Barcode": "077777777770", "POSItemId": 0, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 2, "ReturnCode": 1108, "ReturnCodeDescription": "Item is locked."}, {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 3, "ReturnCode": 1108, "ReturnCodeDescription": "Item is locked."}, {"Description": "Sale Item D", "ExtendedPriceAmount": 2.39, "ExternalId": "ITT-066666666660-0-1", "ItemNumber": 1, "POSItemId": 990000000005, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "RequestItemNumber": 4, "Type": "Regular", "UnitPriceAmount": 2.39}, {"Description": "Hammer City Tax", "ExtendedPriceAmount": 0.02, "RposId": "101-0-0-0", "Type": "Tax"}, {"Description": "Hammer County Tax", "ExtendedPriceAmount": 0.05, "RposId": "102-0-0-0", "Type": "Tax"}, {"Description": "Hammer State Tax", "ExtendedPriceAmount": 0.1, "RposId": "103-0-0-0", "Type": "Tax"}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 2.56, "TransactionSequenceNumber": "*", "TransactionSubTotal": 2.39, "TransactionTaxAmount": 0.17, "TransactionTotal": 2.56} |
        | ["Pos/StoreOrder", {"ItemList": [{"ExternalId": "ITT-099999999990-0-1", "Quantity": 1}, {"Barcode": "077777777770", "Quantity": 1}, {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1}, {"Barcode": "066666666660", "Quantity": 1}]}] | {"ItemList": [{"ExternalId": "ITT-099999999990-0-1", "POSItemId": 0, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 1, "ReturnCode": 1108, "ReturnCodeDescription": "Item is locked."}, {"Barcode": "077777777770", "POSItemId": 0, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 2, "ReturnCode": 1108, "ReturnCodeDescription": "Item is locked."}, {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 3, "ReturnCode": 1108, "ReturnCodeDescription": "Item is locked."}, {"Description": "Sale Item D", "ExtendedPriceAmount": 2.39, "ExternalId": "ITT-066666666660-0-1", "ItemNumber": 1, "POSItemId": 990000000005, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "RequestItemNumber": 4, "Type": "Regular", "UnitPriceAmount": 2.39}, {"Description": "Hammer City Tax", "ExtendedPriceAmount": 0.02, "RposId": "101-0-0-0", "Type": "Tax"}, {"Description": "Hammer County Tax", "ExtendedPriceAmount": 0.05, "RposId": "102-0-0-0", "Type": "Tax"}, {"Description": "Hammer State Tax", "ExtendedPriceAmount": 0.1, "RposId": "103-0-0-0", "Type": "Tax"}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 2.56, "TransactionSequenceNumber": "*", "TransactionSubTotal": 2.39, "TransactionTaxAmount": 0.17, "TransactionTotal": 2.56} |
        | ["Pos/FinalizeOrder", {"ItemList": [{"ExternalId": "ITT-099999999990-0-1", "Quantity": 1}, {"Barcode": "077777777770", "Quantity": 1}, {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1}, {"Barcode": "066666666660", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 6.86}]}] | {"ItemList": [{"ExternalId": "ITT-099999999990-0-1", "POSItemId": 0, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 1, "ReturnCode": 1108, "ReturnCodeDescription": "Item is locked."}, {"Barcode": "077777777770", "POSItemId": 0, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 2, "ReturnCode": 1108, "ReturnCodeDescription": "Item is locked."}, {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 3, "ReturnCode": 1108, "ReturnCodeDescription": "Item is locked."}, {"Description": "Sale Item D", "ExtendedPriceAmount": 2.39, "ExternalId": "ITT-066666666660-0-1", "ItemNumber": 1, "POSItemId": 990000000005, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "RequestItemNumber": 4, "Type": "Regular", "UnitPriceAmount": 2.39}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 2.39, "TransactionSequenceNumber": 0, "TransactionSubTotal": 2.39, "TransactionTaxAmount": 0.0, "TransactionTotal": 2.39} |


    @positive @fast
    Scenario Outline: Cashier adds item with applied promotion to the transaction, GetTransaction response contains info about the promotion.
        Given the pricebook contains promotions
        | item_name   | promotion_price |
        | Sale Item A | 5000            |
        And the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        When the application sends |["Pos/GetTransaction", {}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/GetTransactionResponse
        And POS Connect response data contain |<promotions_response>|

        Examples:
        | barcode | promotions_response |
        | 099999999990 | {"Description": "Sale Item A", "PriceModifiers": [{"RposId": "*", "Type": "Promotion", "UnitPriceAmount": 0.49}]} |


    @negative @fast
    Scenario Outline: Send StoreOrder command to the POS with condiments present in the ItemList batch, validate the condiments are not accepted as items.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/StoreOrder", {"ItemList": [{"POSItemId": 5070000298}]}] | {"ItemList": [{"POSItemId": 5070000298, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "RequestItemNumber": 1, "ReturnCode": 1109, "ReturnCodeDescription":"Condiment is not allowed to be a main item."}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 0.00, "TransactionSequenceNumber": "*", "TransactionSubTotal": 0.00, "TransactionTaxAmount": 0.00, "TransactionTotal": 0.00} |
        | ["Pos/StoreOrder", {"ItemList": [{"POSItemId": 5070000322, "POSModifier1Id": 70000000020, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "CondimentList": []}, {"POSItemId": 5070000308}]}] | {"ItemList": [{"POSItemId": 5070000308, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0,"RequestItemNumber": 2, "ReturnCode": 1109, "ReturnCodeDescription": "Condiment is not allowed to be a main item."}, {"Description": "Burger Mushrom 150 g", "ExtendedPriceAmount": 7.59, "ItemList": [{"Description": "Poppy Bun", "ExtendedPriceAmount": 0.00, "ItemNumber": 2, "POSItemId": 5070000292, "Quantity": 1, "Type": "Condiment", "UnitPriceAmount": 0.00}, {"Description": "Mustard", "ExtendedPriceAmount": 0.00, "ItemNumber": 3, "POSItemId": 5070000296, "Quantity": 1, "Type": "Condiment", "UnitPriceAmount": 0.00}, {"Description": "Bacon Chips", "ExtendedPriceAmount": 0.00, "ItemNumber": 4, "POSItemId": 5070000304, "Quantity": 1, "Type": "Condiment", "UnitPriceAmount": 0.00}, {"Description": "Grilled Tomato", "ExtendedPriceAmount": 0.00, "ItemNumber": 5, "POSItemId": 5070000310, "Quantity": 1, "Type": "Condiment", "UnitPriceAmount": 0.00}, {"Description": "Salad", "ExtendedPriceAmount": 0.00, "ItemNumber": 6, "POSItemId": 5070000316, "Quantity": 1, "Type": "Condiment", "UnitPriceAmount": 0.00}, {"Description": "Sauteed Mushrooms", "ExtendedPriceAmount": 0.00, "ItemNumber": 7, "POSItemId": 5070000317, "Quantity": 1, "Type": "Condiment", "UnitPriceAmount": 0.00}], "ItemNumber": 1, "POSItemId": 5070000322, "POSModifier1Id": 70000000020, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 7.59}, {"Description": "Hammer County Tax", "ExtendedPriceAmount": 0.15000, "RposId": "102-0-0-0", "Type": "Tax"}, {"Description": "Hammer State Tax", "ExtendedPriceAmount": 0.30000, "RposId": "103-0-0-0", "Type": "Tax"}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 8.04, "TransactionSequenceNumber": 0, "TransactionSubTotal": 7.59, "TransactionTaxAmount": 0.45, "TransactionTotal": 8.04} |


    @positive @fast
    Scenario Outline: Send FinalizeOrder command with DiscountTrigger and LinkedItemNumber to the POS, validate the response and transaction.
        Given the POS recognizes following cards
            | card_definition_id | card_role  | card_name | barcode_range_from | card_definition_group_id |
            | 1                  | 1          | MRD card  | 00002255           | 70000000020              |
        And the POS recognizes MRD card role
        And the POS has the feature Loyalty enabled
        And the POS has following discounts configured
            | description     | price  | external_id | card_definition_group_id |
            | MRD             | 0.50   | 1           | 70000000020              |
        And the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/FinalizeOrderResponse
        And POS Connect response data contain |<response_data>|
        And a discount trigger MRD card is in the previous transaction
        And a MRD discount triggered by the card barcode number 00002255 is in the previous transaction

        Examples:
        | request | response_data |
        | ["Pos/FinalizeOrder",{"OriginSystemId":"DiscountTest","ItemList":[{"POSItemId":990000000002,"POSModifier1Id":990000000007,"POSModifier2Id":0,"POSModifier3Id":0,"Quantity":1},{"Type":"DiscountTrigger","RposId":"1-0-0-0","CardNumber":"00002255"},{"Type":"Discount","ExternalId":"1","Amount":0.5,"LinkedItemNumber":2},{"Type":"Tender","ExternalId":"70000000023","Amount":0.49}]}] | {"ItemList":[{"Description":"Sale Item A","*":"*"},{"Description":"MRD","DiscountType":"Discount","ExtendedPriceAmount":-0.5,"*":"*"},{"CardId":1,"CardName":"MRD card","CardNumber":"00002255","Type":"DiscountTrigger","*":"*"},{"Description":"Cash","ExtendedPriceAmount":-0.49,"Type":"Tender","*":"*"}],"TransactionTotal":0.49} |


    @negative @fast
    Scenario Outline: Enable last chance loyalty, send FinalizeOrder command to the POS, validate the Last chance loyalty prompt is not displayed.
        # Set Loyalty prompt control to Prompt always
        Given the POS option 4214 is set to 1
        And the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS displays main menu frame

        Examples:
        | request | response_data |
        | ["Pos/FinalizeOrder", {"OriginReferenceId": "", "ItemList": [{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 3.98} ]}]  | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 3.98, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 1.99}, {"Description": "Cash", "ExtendedPriceAmount": -3.98, "ExternalId": "70000000023", "ItemNumber": 2, "Quantity": 1, "RequestItemNumber": 2, "Type": "Tender"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 3.98, "TransactionTaxAmount": 0.0, "TransactionTotal": 3.98} |


    @positive @fast
    Scenario Outline: Send FinalizeOrder command to the POS with a tender which has a debit/EBT fee configured, the request does not need to have
                      the fee mentioned, it is added automatically to the response
        Given the EPS simulator uses DebitFee card configuration
        And the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS displays main menu frame
        And an item Debit Fee with price 0.12 and type 32 is in the previous transaction

        Examples:
        | request | response_data |
        | ["Pos/FinalizeOrder", {"OriginReferenceId": "", "ItemList": [{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2}, {"Type": "Tender", "ExternalId": "70000000026", "Amount": 3.98, "TenderModifiers": [{ "Description": "Debit Fee", "ExtendedPriceAmount": 0.12, "SurchargeType": "Debit",  "Type": "Surcharge" }]} ]}]  | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 3.98, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 1.99}, {"Description": "Debit", "ExtendedPriceAmount": -4.10, "ExternalId": "70000000026", "ItemNumber": 2, "Quantity": 1, "RequestItemNumber": 2, "TenderModifiers": [{"Description": "Debit Fee", "ExtendedPriceAmount": 0.12000, "SurchargeType": "Debit", "Type": "Surcharge"}], "Type": "Tender"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 4.10, "TransactionTaxAmount": 0.0, "TransactionTotal": 4.10} |
        | ["Pos/FinalizeOrder", {"OriginReferenceId": "", "ItemList": [{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2}, {"Type": "Tender", "ExternalId": "70000000026", "Amount": 3.98, "TenderModifiers": [{ "Description": "EBT Fake Fee", "ExtendedPriceAmount": 1.50, "SurchargeType": "EBT",  "Type": "Surcharge" }]} ]}]  | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 3.98, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 1.99}, {"Description": "Debit", "ExtendedPriceAmount": -4.10, "ExternalId": "70000000026", "ItemNumber": 2, "Quantity": 1, "RequestItemNumber": 2, "TenderModifiers": [{"Description": "Debit Fee", "ExtendedPriceAmount": 0.12000, "SurchargeType": "Debit", "Type": "Surcharge"}], "Type": "Tender"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 4.10, "TransactionTaxAmount": 0.0, "TransactionTotal": 4.10} |
        | ["Pos/FinalizeOrder", {"OriginReferenceId": "", "ItemList": [{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2}, {"Type": "Tender", "ExternalId": "70000000026", "Amount": 3.98} ]}]  | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 3.98, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 1.99}, {"Description": "Debit", "ExtendedPriceAmount": -4.10, "ExternalId": "70000000026", "ItemNumber": 2, "Quantity": 1, "RequestItemNumber": 2, "TenderModifiers": [{"Description": "Debit Fee", "ExtendedPriceAmount": 0.12000, "SurchargeType": "Debit", "Type": "Surcharge"}], "Type": "Tender"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 4.10, "TransactionTaxAmount": 0.0, "TransactionTotal": 4.10} |


    @positive @fast
    Scenario Outline: Void loyalty transaction after SubtotalOrder command was sent to POS, validate the correct response
        Given the Sigma simulator has essential configuration
        And the POS is in a ready to sell state
        And the POS has the feature Loyalty enabled
        And the Sigma recognizes following cards
            | card_number  | card_description |
            | 700511866611 | Happy Card       |
        And the application sent |<request>| to the POS Connect
        When the application voids last loyalty transaction
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/VoidLoyaltyTransactionResponse
        And POS Connect response data are |{}|

        Examples:
        | request |
        | ["Pos/SubTotalOrder", {"PerformSubtotal": true, "OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [{"Type": "Loyalty","EntryMethod": "Manual","Barcode": "700511866611","CustomerName": "John Doe"}, {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4 }]}] |


    @negative @fast
    Scenario Outline: Attempt to send VoidLoyaltyTransaction command with incorrect loyalty transaction id, after SubtotalOrder command was sent to POS, validate the response with an error notification.
        Given the Sigma simulator has essential configuration
        And the POS is in a ready to sell state
        And the POS has the feature Loyalty enabled
        And the Sigma recognizes following cards
            | card_number  | card_description |
            | 700511866611 | Happy Card       |
        And the application sent |<request>| to the POS Connect
        When the application voids |<loyalty_transaction>| loyalty transaction
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/VoidLoyaltyTransactionResponse
        And POS Connect response data are |<response>|

        Examples:
        | loyalty_transaction | request | response |
        | 'test1234'          | ["Pos/SubTotalOrder", {"PerformSubtotal": true, "OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [{"Type": "Loyalty","EntryMethod": "Manual","Barcode": "700511866611","CustomerName": "John Doe"}, {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4 }]}] | {"ReturnCode": 1116, "ReturnCodeDescription": "Loyalty transaction number is incorrectly formatted.", "TransactionSequenceNumber": 0} |
        | '1234'              | ["Pos/SubTotalOrder", {"PerformSubtotal": true, "OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [{"Type": "Loyalty","EntryMethod": "Manual","Barcode": "700511866611","CustomerName": "John Doe"}, {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4 }]}] | {"ReturnCode": 1116, "ReturnCodeDescription": "Loyalty transaction number is incorrectly formatted.", "TransactionSequenceNumber": 0} |
        |  ''                 | ["Pos/SubTotalOrder", {"PerformSubtotal": true, "OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [{"Type": "Loyalty","EntryMethod": "Manual","Barcode": "700511866611","CustomerName": "John Doe"}, {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4 }]}] | {"ReturnCode": 1116, "ReturnCodeDescription": "Loyalty transaction number is incorrectly formatted.", "TransactionSequenceNumber": 0} |


   @positive @fast
    Scenario Outline: Send SubtotalOrder command to POS with PerformSubtotal parameter set to true and loyalty item present,
                      validate the response contains loyalty transaction id and loyalty discounts.
        Given the POS is in a ready to sell state
        And the Sigma simulator has essential configuration
        And the POS has the feature Loyalty enabled
        And the Sigma recognizes following cards
            | card_number  | card_description |
            | 700511866611 | Happy Card       |
        And an item Sale Item A with barcode 099999999990 and price 0.99 is eligible for discount cash 0.50 when using loyalty card 700511866611
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SubTotalOrderResponse
        And the POS Connect response data contain element LoyaltyTransactionId with value *
        And the POS Connect response data contain element Type with value Discount
        And the POS Connect response data contain element DiscountType with value Loyalty

        Examples:
        | request |
        | ["Pos/SubTotalOrder", {"PerformSubtotal": true, "OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [{"Barcode": "099999999990", "Quantity": 1}, {"Type": "Loyalty","EntryMethod": "Manual","Barcode": "700511866611","CustomerName": "John Doe"}]}] |


    @negative @fast
    Scenario Outline: Send SubtotalOrder command to POS without PerformSubtotal parameter set and with loyalty item present. Validate the
                      response contains loyalty transaction id, but not loyalty discounts.
        Given the POS is in a ready to sell state
        And the Sigma simulator has essential configuration
        And the POS has the feature Loyalty enabled
        And the Sigma recognizes following cards
            | card_number  | card_description |
            | 700511866611 | Happy Card       |
        And an item Sale Item A with barcode 099999999990 and price 0.99 is eligible for discount cash 0.50 when using loyalty card 700511866611
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SubTotalOrderResponse
        And the POS Connect response data contain element LoyaltyTransactionId with value *
        And the POS Connect response data does not contain element DiscountType with value Loyalty

        Examples:
        | request |
        | ["Pos/SubTotalOrder", {"OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [{"Barcode": "099999999990", "Quantity": 1}, {"Type": "Loyalty","EntryMethod": "Manual","Barcode": "700511866611","CustomerName": "John Doe"}]}] |


    @negative @fast
    Scenario Outline: Send SubtotalOrder command to POS without PerformSubtotal parameter set/or set to false and without loyalty item present.
                      Validate the response doesn't contains loyalty transaction id, and loyalty discounts.
        Given the POS is in a ready to sell state
        And the Sigma simulator has essential configuration
        And the POS has the feature Loyalty enabled
        And the Sigma recognizes following cards
            | card_number  | card_description |
            | 700511866611 | Happy Card       |
        And an item Sale Item A with barcode 099999999990 and price 0.99 is eligible for discount cash 0.50 when using loyalty card 700511866611
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SubTotalOrderResponse
        And the POS Connect response data does not contain element LoyaltyTransactionId
        And the POS Connect response data does not contain element DiscountType with value Loyalty

        Examples:
        | request |
        | ["Pos/SubTotalOrder", {"PerformSubtotal": true, "OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [{"Barcode": "099999999990", "Quantity": 1}]}] |
        | ["Pos/SubTotalOrder", {"PerformSubtotal": false, "OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [{"Barcode": "099999999990", "Quantity": 1}]}] |


    @positive @fast
    # Double curly braces in finalize request are required because we use format method on the request and single braces confuse it
    Scenario Outline: Send FinalizeOrder command with loyalty transaction id to POS, after the SubtotalOrder command was received, validate the correct response
        Given the Sigma simulator has essential configuration
        And the POS is in a ready to sell state
        And the POS has the feature Loyalty enabled
        And the Sigma recognizes following cards
            | card_number  | card_description |
            | 700511866611 | Happy Card       |
        And the application sent |<subtotal_request>| to the POS Connect
        When the application sends |<finalize_request>| for last transaction
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/FinalizeOrderResponse
        And POS Connect response data contain |<response>|

        Examples:
        | subtotal_request | finalize_request | response |
        | ["Pos/SubTotalOrder", {"PerformSubtotal": true, "OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [{"Type": "Loyalty","EntryMethod": "Manual","Barcode": "700511866611","CustomerName": "John Doe"}, {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2 }]}] | ["Pos/FinalizeOrder", {{"OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [{{"Type": "Loyalty","LoyaltyType": "Sigma", "LoyaltyTransactionId": "{loyalty_id}"}}, {{"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2 }}, {{"Type": "Tender", "ExternalId": "70000000026", "Amount": 4.10}}]}}] | {"Description": "*", "ExtendedPriceAmount": 0.00, "LoyaltyTransactionId": "*", "LoyaltyType": "Sigma", "Type": "Loyalty"} |


    @negative @fast
    # Double curly braces in finalize request are required because we use format method on the request and single braces confuse it
    Scenario Outline: Send FinalizeOrder command with invalid loyalty transaction id to POS, after the SubtotalOrder command was received, validate the proper error code in response
        Given the Sigma simulator has essential configuration
        And the POS is in a ready to sell state
        And the POS has the feature Loyalty enabled
        And the Sigma recognizes following cards
            | card_number  | card_description |
            | 700511866611 | Happy Card       |
        And the application sent |<subtotal_request>| to the POS Connect
        When the application sends |<finalize_request>| for transaction with loyalty |<loyalty_id>|
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/FinalizeOrderResponse
        And POS Connect response data contain |<response>|

        Examples:
        | subtotal_request | finalize_request | loyalty_id | response |
        | ["Pos/SubTotalOrder", {"PerformSubtotal": true, "OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [{"Type": "Loyalty","EntryMethod": "Manual","Barcode": "700511866611","CustomerName": "John Doe"}, {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2 }]}] | ["Pos/FinalizeOrder", {{"OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [{{"Type": "Loyalty","LoyaltyType": "Sigma", "LoyaltyTransactionId": "{loyalty_id}"}}, {{"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2 }}, {{"Type": "Tender", "ExternalId": "70000000026", "Amount": 3.98}}]}}] | 999999999 |{"ReturnCode" : 1117, "ReturnCodeDescription": "Invalid Loyalty transaction number."} |


    @positive @fast @manual
    # waiting for RPOS-19995
    Scenario Outline: Send FinalizeOrder command to the POS with long OriginReferenceId value, the related transaction NVP is
                      populated only with the last x digits according to pos option 5147
        # "Limit displayed reference number to X digits" option
        Given the POS option 5147 is set to <value>
        And the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS displays main menu frame
        And a header section from the previous transaction contains NVP <NVP>

        Examples:
        | NVP | value | request | response_data |
        | TBD | 0     | ["Pos/FinalizeOrder", {"OriginReferenceId": "123456789", "ItemList": [{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 3.98} ]}]  | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 3.98, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 1.99}, {"Description": "Cash", "ExtendedPriceAmount": -3.98, "ExternalId": "70000000023", "ItemNumber": 2, "Quantity": 1, "RequestItemNumber": 2, "Type": "Tender"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 3.98, "TransactionTaxAmount": 0.0, "TransactionTotal": 3.98} |
        | TBD | 5     | ["Pos/FinalizeOrder", {"OriginReferenceId": "123456789", "ItemList": [{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 3.98} ]}]  | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 3.98, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 1.99}, {"Description": "Cash", "ExtendedPriceAmount": -3.98, "ExternalId": "70000000023", "ItemNumber": 2, "Quantity": 1, "RequestItemNumber": 2, "Type": "Tender"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 3.98, "TransactionTaxAmount": 0.0, "TransactionTotal": 3.98} |
        | TBD | 5     | ["Pos/FinalizeOrder", {"OriginReferenceId": "12345", "ItemList": [{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 3.98} ]}]  | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 3.98, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 1.99}, {"Description": "Cash", "ExtendedPriceAmount": -3.98, "ExternalId": "70000000023", "ItemNumber": 2, "Quantity": 1, "RequestItemNumber": 2, "Type": "Tender"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 3.98, "TransactionTaxAmount": 0.0, "TransactionTotal": 3.98} |
        | TBD | 5     | ["Pos/FinalizeOrder", {"OriginReferenceId": "123", "ItemList": [{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 3.98} ]}]  | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 3.98, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 1.99}, {"Description": "Cash", "ExtendedPriceAmount": -3.98, "ExternalId": "70000000023", "ItemNumber": 2, "Quantity": 1, "RequestItemNumber": 2, "Type": "Tender"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 3.98, "TransactionTaxAmount": 0.0, "TransactionTotal": 3.98} |
        | TBD | 5     | ["Pos/FinalizeOrder", {"OriginReferenceId": "", "ItemList": [{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 3.98} ]}]  | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 3.98, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 1.99}, {"Description": "Cash", "ExtendedPriceAmount": -3.98, "ExternalId": "70000000023", "ItemNumber": 2, "Quantity": 1, "RequestItemNumber": 2, "Type": "Tender"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 3.98, "TransactionTaxAmount": 0.0, "TransactionTotal": 3.98} |
        | TBD | 5     | ["Pos/FinalizeOrder", {"ItemList": [{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 3.98} ]}]  | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 3.98, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 1.99}, {"Description": "Cash", "ExtendedPriceAmount": -3.98, "ExternalId": "70000000023", "ItemNumber": 2, "Quantity": 1, "RequestItemNumber": 2, "Type": "Tender"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 3.98, "TransactionTaxAmount": 0.0, "TransactionTotal": 3.98} |


    @positive @fast @manual
    # waiting for RPOS-19995
    Scenario Outline: Send StoreOrder command to the POS with long OriginReferenceId value, the related transaction NVP is
                      populated only with the last x digits according to pos option 5147
        # "Limit displayed reference number to X digits" option
        Given the POS option 5147 is set to <value>
        And the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS displays main menu frame
        And a header section from the last stored transaction contains NVP <NVP>

        Examples:
        | NVP | value | request | response_data |
        | TBD | 0     | ["Pos/StoreOrder", {"OriginReferenceId": "123456789", "ItemList": [{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2}]}]  | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 3.98, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 1.99}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 3.98, "TransactionTaxAmount": 0.0, "TransactionTotal": 3.98} |
        | TBD | 5     | ["Pos/StoreOrder", {"OriginReferenceId": "123456789", "ItemList": [{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2}]}]  | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 3.98, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 1.99}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 3.98, "TransactionTaxAmount": 0.0, "TransactionTotal": 3.98} |
        | TBD | 5     | ["Pos/StoreOrder", {"OriginReferenceId": "12345", "ItemList": [{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2}]}]  | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 3.98, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 1.99}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 3.98, "TransactionTaxAmount": 0.0, "TransactionTotal": 3.98} |
        | TBD | 5     | ["Pos/StoreOrder", {"OriginReferenceId": "123", "ItemList": [{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2}]}]  | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 3.98, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 1.99}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 3.98, "TransactionTaxAmount": 0.0, "TransactionTotal": 3.98} |
        | TBD | 5     | ["Pos/StoreOrder", {"OriginReferenceId": "", "ItemList": [{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2}]}]  | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 3.98, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 1.99}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 3.98, "TransactionTaxAmount": 0.0, "TransactionTotal": 3.98} |
        | TBD | 5     | ["Pos/StoreOrder", {"ItemList": [{"POSItemId": 990000000003,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 2}]}]  | {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 3.98, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 1.99}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 3.98, "TransactionTaxAmount": 0.0, "TransactionTotal": 3.98} |


    @positive @fast @manual
    # waiting for RPOS-19995
    Scenario Outline: Send StartTransaction command to the POS with long OriginReferenceId value, the related transaction NVP is
                      populated only with the last x digits according to pos option 5147
        # "Limit displayed reference number to X digits" option
        Given the POS option 5147 is set to <value>
        And the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS displays main menu frame
        And a header section from the current transaction contains NVP <NVP>

        Examples:
        | NVP | value | request | response_data |
        | TBD | 0     | ["Pos/StartTransaction", {"OriginReferenceId": "123456789"}]  | TBD |
        | TBD | 5     | ["Pos/StartTransaction", {"OriginReferenceId": "123456789"}]  | TBD |
        | TBD | 5     | ["Pos/StartTransaction", {"OriginReferenceId": "12345"}]  | TBD |
        | TBD | 5     | ["Pos/StartTransaction", {"OriginReferenceId": "123"}]  | TBD |
        | TBD | 5     | ["Pos/StartTransaction", {"OriginReferenceId": ""}]  | TBD |
        | TBD | 5     | ["Pos/StartTransaction", {}]  | TBD |


    @positive @fast
    Scenario Outline: Send GetState command to POS and validate that response
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/GetStateResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/GetState", {}]    | {"DeviceStates": {"ElectronicPayment": {"IsConfigured": "*", "IsOnline": "*"}, "Pinpad": {"IsOnline": "*"}, "ReceiptPrinter": {"IsOnline": "*"}, "SiteController": {"IsOnline": "*"}}, "IsCashAlertActive": "*", "IsPaymentAvailable": "*", "IsUpdateRequired": "*", "NodeNumber": "*", "Shift": {"CurrentBusinessDay": "*", "IsManualShiftFlow": "*", "IsShiftOpened": "*", "NewBusinessDay": "*"}, "State": "Ready", "TransactionSequenceNumber": "*"} |


    @positive @fast
    Scenario Outline: Set RLM registry RLMDelayAuthForMOP and RLMSendAuthAfterCreditDecode to YES or NO,
                      send SubtotalOrder command to POS with PerformSubtotal parameter set to true and loyalty item present,
                      validate the response contains loyalty transaction id and loyalty discounts.
        Given the Sigma simulator has essential configuration
        And the Sigma option RLMSendAuthAfterCreditDecode is set to <value1>
        And the Sigma option RLMDelayAuthForMOP is set to <value2>
        And the Sigma recognizes following cards
            | card_number  | card_description |
            | 700511866611 | Happy Card       |
        And an item Sale Item A with barcode 099999999990 and price 0.99 is eligible for discount cash 0.50 when using loyalty card 700511866611
        And the POS has the feature Loyalty enabled
        And the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SubTotalOrderResponse
        And the POS Connect response data contain element LoyaltyTransactionId with value *
        And the POS Connect response data contain element Type with value Discount
        And the POS Connect response data contain element DiscountType with value Loyalty

        Examples:
        | value1 | value2 | request |
        | NO     | NO     | ["Pos/SubTotalOrder", {"PerformSubtotal": true, "OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [{"Barcode": "099999999990", "Quantity": 1}, {"Type": "Loyalty","EntryMethod": "Manual","Barcode": "700511866611","CustomerName": "John Doe"}]}] |
        | NO     | YES    | ["Pos/SubTotalOrder", {"PerformSubtotal": true, "OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [{"Barcode": "099999999990", "Quantity": 1}, {"Type": "Loyalty","EntryMethod": "Manual","Barcode": "700511866611","CustomerName": "John Doe"}]}] |
        | YES    | NO     | ["Pos/SubTotalOrder", {"PerformSubtotal": true, "OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [{"Barcode": "099999999990", "Quantity": 1}, {"Type": "Loyalty","EntryMethod": "Manual","Barcode": "700511866611","CustomerName": "John Doe"}]}] |
        | YES    | YES    | ["Pos/SubTotalOrder", {"PerformSubtotal": true, "OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [{"Barcode": "099999999990", "Quantity": 1}, {"Type": "Loyalty","EntryMethod": "Manual","Barcode": "700511866611","CustomerName": "John Doe"}]}] |

    @positive
    Scenario Outline: Send parameter CardType in the SubTotalOrder and FinalizeOrder requests and verify that requests were successfully processed
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/SubTotalOrder",{"ItemList":[{"Barcode": "099999999990", "Quantity": 1},{"ExternalId":"70000000026","Amount":0.0,"CardType":"1234","Type":"Tender"}]}]|{"ItemList": [{"Description": "Sale Item A", "ExtendedPriceAmount": 0.99, "ExternalId": "ITT-099999999990-0-1", "FractionalQuantity": 1.0, "ItemNumber": 1, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "TransactionBalance": 1.06, "TransactionSubTotal": 0.99, "TransactionTaxAmount": 0.07, "TransactionTotal": 1.06} |
        | ["Pos/FinalizeOrder", {"OriginReferenceId": "", "ItemList": [{"POSItemId": 990000000002,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000026", "Amount": 0.99,"CardType":"1234"} ]}] | {"ItemList": [{"Description": "Sale Item A","ExtendedPriceAmount": 0.99,"ExternalId": "ITT-099999999990-0-1","FractionalQuantity": 1.0,"ItemNumber": 1,"POSItemId": 990000000002,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 1,"RequestItemNumber": 1,"Type": "Regular","UnitPriceAmount": 0.99},{"Description": "Credit","ExtendedPriceAmount": -0.99,"ExternalId": "70000000026","ItemNumber": 3,"Quantity": 1,"Type": "Tender"}],"TransactionSubTotal": 0.99,"TransactionTotal": 0.99} |

    @positive @manual @waitingforfix
    # Waiting for https://jira.ncr.com/browse/RPOS-32377
    #TODO: extend Sigma simulator to add tender information into request/transaction if they were send in request by POS (behavior can be based on Sigma options RLMSendAuthAfterCreditDecode and RLMAllowExtendedTenderType)
    Scenario Outline: Send tender section and with CardType parameter in the SubTotalOrder request with loyalty card and verify CardType was sent to Sigma
        Given the Sigma simulator has essential configuration
        And the Sigma option RLMSendAuthAfterCreditDecode is set to YES
        And the Sigma option RLMAllowExtendedTenderType is set to YES
        And the Sigma recognizes following cards
            | card_number  | card_description |
            | 700511866611 | Happy Card       |
        And the POS has the feature Loyalty enabled
        And the POS is in a ready to sell state
        When the application sends |<subtotal_request>| to the POS Connect
        Then the POS Connect response code is 200
        And the Sigma does receive request of type AUTH from POS
        # And the Sigma request data contains {"TenderSubCodeExternalId"="1234"}

        Examples:
        | subtotal_request |
        | ["Pos/SubTotalOrder", {"PerformSubtotal": true, "OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [{"Type": "Loyalty","EntryMethod": "Manual","Barcode": "700511866611","CustomerName": "John Doe"}, {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2 },{"Type": "Tender", "ExternalId": "70000000023", "Amount": 0.0,"CardType":"1234"}]}]|

    @positive @manual @waitingforfix
    # Waiting for https://jira.ncr.com/browse/RPOS-32377
    #TODO: extend Sigma simulator to set properly CAPTURE transaction type
    #TODO: extend Sigma simulator to add tender information into request/transaction if they were send in request by POS (behavior can be based on Sigma options RLMSendAuthAfterCreditDecode and RLMAllowExtendedTenderType)
    Scenario Outline: Send parameter CardType in the tender section in FinalizeOrder request  with loyalty card and verify CardType was sent to Sigma
        Given the Sigma simulator has essential configuration
        And the Sigma option RLMSendAuthAfterCreditDecode is set to YES
        And the Sigma option RLMAllowExtendedTenderType is set to YES
        And the Sigma recognizes following cards
            | card_number  | card_description |
            | 700511866611 | Happy Card       |
        And the POS has the feature Loyalty enabled
        And the POS is in a ready to sell state
        And the application sent |<subtotal_request>| to the POS Connect
        When the application sends |<finalize_request>| to the POS Connect
        Then the POS Connect response code is 200
        # And the Sigma does receive request of type CAPTURE from POS
        # And the Sigma request data contains {"TenderSubCodeExternalId"="1234"}

        Examples:
        | subtotal_request | finalize_request |
        | ["Pos/SubTotalOrder", {"PerformSubtotal": true, "OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [{"Type": "Loyalty","EntryMethod": "Manual","Barcode": "700511866611","CustomerName": "John Doe"}, {"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2 },{"Type": "Tender", "ExternalId": "70000000023", "Amount": 0.0,"CardType":"1234"}]}]| ["Pos/FinalizeOrder", {"OriginSystemId": "ForeCourt", "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList": [{"Type": "Loyalty","LoyaltyType": "Sigma", "LoyaltyTransactionId": "{loyalty_id}"},{"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2 }, {"Type": "Tender", "ExternalId": "70000000026", "Amount": "3.98","CardType":"1234"}]}] |
