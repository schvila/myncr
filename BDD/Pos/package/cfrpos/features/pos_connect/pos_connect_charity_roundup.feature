@pos @pos_connect

Feature: POS Connect Charity Round Up
    Pos/SubTotalTransaction request and response are modified to have donation item as charity on round up that will round balance up to the nearest dollar.
    To be able to add donation item, tender_mode_2 should be set to the tender_mode_2 = original_value + 256, and control parameter 1241 should be set
    to external ID value of the Donation item.


    Background: POS is ready to sell and no transaction is in progress
        Given the POS has essential configuration
        And the EPS simulator has essential configuration
        And the POS has the feature PosApiServer enabled
        # Set Charity donation round up item External ID option to external ID of Donation item
        And the POS control parameter 1241 is set to 224466
        And the POS has following tenders configured
        | tender_id   | description      | tender_type_id | exchange_rate | currency_symbol | external_id  | tender_mode_2 | tender_ranking |
        | 70000000023 | Cash             | 1              | 1             | $               | 70000000023  | 272           | 1              |
        | 70000000024 | Debit            | 4              | 1             | $               | 70000000024  | 222           | 2              |
        | 70000000025 | Credit           | 3              | 1             | $               | 70000000025  | 385           | 2              |
        And the pricebook contains charity item
        | description   | barcode    | item_id   | price | external_id | credit_category |
        | Donation item | 0789001112 | 789001112 | 0.0   | 224466      | 0555            |
        And the POS has following sale items configured
        | barcode      | description | price  |
        | 099999999990 | Sale Item A | 0.99   |


    @positive @fast
    Scenario Outline: Send Pos/SubTotalTransaction with IsCharityAllowed flag enabled/disable and observe that charity yes/no frame is/is not displayed
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is <response_type>
        And POS Connect response data contain |<response_data>|

        Examples:
         | request | response_type | response_data |
         | ["Pos/SubTotalTransaction", {"TenderExternalId": "70000000023", "IsCharityAllowed": true}] | Pos/DataNeeded | {"DataType": "YesNo", "PromptId": 5054, "PromptText": "Would you like to donate to charity by rounding up to the next $?", "PromptType": "ask-charity" }|
         | ["Pos/SubTotalTransaction", {"TenderExternalId": "70000000023", "IsCharityAllowed": false}] | Pos/SubTotalTransactionResponse | {"TransactionData": {"ItemList": [{"Description": "Sale Item A","ExtendedPriceAmount": 0.99,"ExternalId": "ITT-099999999990-0-1","FractionalQuantity": 1,"ItemNumber": 1,"POSItemId": 990000000002,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 1,"Type": "Regular","UnitPriceAmount": 0.99}],"TransactionBalance": 1.06,"TransactionSubTotal": 0.99,"TransactionTaxAmount": 0.07,"TransactionTotal": 1.06},"TransactionSequenceNumber": "*"} |
         | ["Pos/SubTotalTransaction", {"TenderExternalId": "70000000025", "IsCharityAllowed": true}] | Pos/DataNeeded | {"DataType": "YesNo", "PromptId": 5054, "PromptText": "Would you like to donate to charity by rounding up to the next $?", "PromptType": "ask-charity" }|
         | ["Pos/SubTotalTransaction", {"TenderExternalId": "70000000025", "IsCharityAllowed": false}] | Pos/SubTotalTransactionResponse | {"TransactionData": {"ItemList": [{"Description": "Sale Item A","ExtendedPriceAmount": 0.99,"ExternalId": "ITT-099999999990-0-1","FractionalQuantity": 1,"ItemNumber": 1,"POSItemId": 990000000002,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 1,"Type": "Regular","UnitPriceAmount": 0.99}],"TransactionBalance": 1.06,"TransactionSubTotal": 0.99,"TransactionTaxAmount": 0.07,"TransactionTotal": 1.06},"TransactionSequenceNumber": "*"} |


    @negative @fast
    Scenario Outline: Send Pos/SubTotalTransaction without IsCharityAllowed flag and the charity yes/no frame is not displayed
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is <response_type>
        And POS Connect response data contain |<response_data>|
    
        Examples:
         | request | response_type | response_data |
         | ["Pos/SubTotalTransaction", {"TenderExternalId": "70000000023"}] | Pos/SubTotalTransactionResponse | {"TransactionData": {"ItemList": [{"Description": "Sale Item A","ExtendedPriceAmount": 0.99,"ExternalId": "ITT-099999999990-0-1","FractionalQuantity": 1,"ItemNumber": 1,"POSItemId": 990000000002,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 1,"Type": "Regular","UnitPriceAmount": 0.99}],"TransactionBalance": 1.06,"TransactionSubTotal": 0.99,"TransactionTaxAmount": 0.07,"TransactionTotal": 1.06},"TransactionSequenceNumber": "*"} |

    @negative @fast
    Scenario Outline: Send Pos/SubTotalTransaction with debit tender whose mode2 is not set for charity and the charity yes/no frame is not displayed
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is <response_type>
        And POS Connect response data contain |<response_data>|

        Examples:
         | request | response_type | response_data |
         | ["Pos/SubTotalTransaction", {"TenderExternalId": "70000000024", "IsCharityAllowed": true}] | Pos/SubTotalTransactionResponse | {"TransactionData": {"ItemList": [{"Description": "Sale Item A","ExtendedPriceAmount": 0.99,"ExternalId": "ITT-099999999990-0-1","FractionalQuantity": 1,"ItemNumber": 1,"POSItemId": 990000000002,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 1,"Type": "Regular","UnitPriceAmount": 0.99}],"TransactionBalance": 1.06,"TransactionSubTotal": 0.99,"TransactionTaxAmount": 0.07,"TransactionTotal": 1.06},"TransactionSequenceNumber": "*"} |


    @negative @fast
    Scenario Outline: Set Charity donation round up item External ID to incorrect value, dataneeded response will not be prompted
        # Set Charity donation round up item External ID option to invalid external ID
        Given the POS control parameter 1241 is set to 1111111
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is <response_type>
        And POS Connect response data contain |<response_data>|

        Examples:
          | request | response_type | response_data |
          | ["Pos/SubTotalTransaction", {"TenderExternalId": "70000000024", "IsCharityAllowed": true}] | Pos/SubTotalTransactionResponse | {"TransactionData": {"ItemList": [{"Description": "Sale Item A","ExtendedPriceAmount": 0.99,"ExternalId": "ITT-099999999990-0-1","FractionalQuantity": 1,"ItemNumber": 1,"POSItemId": 990000000002,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 1,"Type": "Regular","UnitPriceAmount": 0.99}],"TransactionBalance": 1.06,"TransactionSubTotal": 0.99,"TransactionTaxAmount": 0.07,"TransactionTotal": 1.06},"TransactionSequenceNumber": "*"} |


    @positive @fast
    Scenario Outline: Send DataNeededResponse command to the POS as response to charity YesNo frame and validate the response
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the application sent |<request1>| to the POS Connect
        When the application sends |<request2>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SubTotalTransactionResponse
        And POS Connect response data contain |<response_data>|

        Examples:
         | request1 | request2 | response_data |
         | ["Pos/SubTotalTransaction", {"TenderExternalId": "70000000023", "IsCharityAllowed": true}] | ["Pos/DataNeededResponse",{"DataType": "YesNo", "YesNoData": "Yes"}] | {"TransactionData": {"ItemList": [{"Description": "Sale Item A", "ExtendedPriceAmount": 0.99, "ExternalId": "ITT-099999999990-0-1", "FractionalQuantity": 1.0, "ItemNumber": 1, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}, {"Description": "Donation item", "ExtendedPriceAmount": 0.94, "ExternalId": "224466", "FractionalQuantity": 1.0, "ItemNumber": 2, "POSItemId": 789001112, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.94}], "TransactionBalance": 2.0, "TransactionSubTotal": 1.93, "TransactionTaxAmount": 0.07, "TransactionTotal": 2.0}, "TransactionSequenceNumber": "*"}|
         | ["Pos/SubTotalTransaction", {"TenderExternalId": "70000000023", "IsCharityAllowed": true}] | ["Pos/DataNeededResponse",{"DataType": "YesNo", "YesNoData": "No"}]  | {"TransactionData": {"ItemList": [{"Description": "Sale Item A","ExtendedPriceAmount": 0.99,"ExternalId": "ITT-099999999990-0-1","FractionalQuantity": 1,"ItemNumber": 1,"POSItemId": 990000000002,"POSModifier1Id": 990000000007,"POSModifier2Id": 0,"POSModifier3Id": 0,"Quantity": 1,"Type": "Regular","UnitPriceAmount": 0.99}],"TransactionBalance": 1.06,"TransactionSubTotal": 0.99,"TransactionTaxAmount": 0.07,"TransactionTotal": 1.06},"TransactionSequenceNumber": "*"} |


    @positive @fast
    Scenario Outline: Finalize the tranaction after charity is allowed through dataneeded response
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the application sent |<request1>| to the POS Connect
        And the application sent |<request2>| to the POS Connect
        When the application sends |<request3>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/AddTenderResponse
        And POS Connect response data contain |<response_data>|

        Examples:
         | request1 | request2 | request3 | response_data |
         | ["Pos/SubTotalTransaction", {"TenderExternalId": "70000000023", "IsCharityAllowed": true}] | ["Pos/DataNeededResponse",{"DataType": "YesNo", "YesNoData": "Yes"}] | ["Pos/AddTender", {"TenderExternalId": "70000000023", "Amount": 2.00}] | {"CashBack": 0.0, "TenderAmount": 2.0, "TransactionData": {"ItemList": [{"Description": "Sale Item A", "ExtendedPriceAmount": 0.99, "ExternalId": "ITT-099999999990-0-1", "FractionalQuantity": 1.0, "ItemNumber": 1, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}, {"Description": "Donation item", "ExtendedPriceAmount": 0.94, "ExternalId": "224466", "FractionalQuantity": 1.0, "ItemNumber": 2, "POSItemId": 789001112, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.94}, {"Description": "Cash", "ExtendedPriceAmount": -2.0, "ExternalId": "70000000023", "ItemNumber": 3, "Quantity": 1, "Type": "Tender"}, {"Description": "Tax Item", "ExtendedPriceAmount": 0.01, "RposId": "101-0-0-0", "Type": "Tax"}, {"Description": "Tax Item", "ExtendedPriceAmount": 0.02, "RposId": "102-0-0-0", "Type": "Tax"}, {"Description": "Tax Item", "ExtendedPriceAmount": 0.04, "RposId": "103-0-0-0", "Type": "Tax"}], "TransactionBalance": 0.0, "TransactionSubTotal": 1.93, "TransactionTaxAmount": 0.07, "TransactionTotal": 2.0}, "TransactionSequenceNumber": "*"} |


    @positive @fast
    Scenario Outline: Send AddLoyalty command, allow charity through prompt by dataneeded response
        Given the Sigma simulator has essential configuration
        And the Sigma recognizes following cards
            | card_description | card_number      | track1                       | track2                       | alt_id    |
            | Kroger Loyalty A | 6042400114771120 | 6042400114771120^CARD/S^0000 | 6042400114771120=0000?S^0000 | 123456789 |
            | Kroger Loyalty B | 3042400114771120 | 3042400114771120^CARD/S^0000 | 3042400114771120=0000?S^0000 | 003456789 |
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the application sent |<request1>| to the POS Connect
        And the application sent |<request2>| to the POS Connect
        When the application sends |<formatted_message>| to the POS Connect
        Then a card Loyalty Item with value of 0.00 is in the virtual receipt
        And a card Loyalty Item with value of 0.00 is in the current transaction
        And an item Donation item with price 0.94 is in the virtual receipt
        And the total from current transaction is rounded to 2.00

        Examples:
        | request1 | request2 | formatted_message                                                             |
        | ["Pos/SubTotalTransaction", {"TenderExternalId": "70000000023", "IsCharityAllowed": true}] | ["Pos/DataNeededResponse",{"DataType": "YesNo", "YesNoData": "Yes"}] | ["Pos/AddLoyalty", {"EntryMethod": "Scanned", "Barcode": "6042400114771120"}] |
        | ["Pos/SubTotalTransaction", {"TenderExternalId": "70000000023", "IsCharityAllowed": true}] | ["Pos/DataNeededResponse",{"DataType": "YesNo", "YesNoData": "Yes"}] | ["Pos/AddLoyalty", {"EntryMethod": "Manual", "Barcode": "3042400114771120"}]  |
