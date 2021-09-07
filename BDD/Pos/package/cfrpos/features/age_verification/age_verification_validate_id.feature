@pos
Feature: Age verification - force secondary ID verification by the cashier
    This feature file focuses on a portion of age verification, where items can be marked with a flag, forcing the
    cashier to verify several parsed fields from the ID and the customer's photo.

    Background: POS is properly configured for Age verification feature
        Given the POS has essential configuration
        # "Age verification failure tracking" option set to "NO"
        And the POS option 1024 is set to 0
        # "Age verification" option set to "By birthdate or license swipe"
        And the POS option 1010 is set to 2
        And the pricebook contains retail items
            | description        | price  | age_restriction | barcode      | item_id      | modifier1_id | id_validation_required |
            | Age 21 Restricted  | 4.69   | 21              | 022222222220 | 990000000009 | 990000000007 | false                  |
            | Age 18 Restricted  | 3.69   | 18              | 0369369369   | 990000000010 | 990000000007 | false                  |
            | ID Validation item | 3.21   | 21              | 0123456789   | 0123456789   | 0            | true                   |


    @fast
    Scenario Outline: Age restricted item with the id_validation flag requires additional validation after ID scan
        Given the POS is in a ready to sell state
        And the POS displays Age verification frame after scanning an item barcode <barcode>
        When the cashier scans a driver's license <drivers_license>
        Then the POS displays ID validation frame

        Examples:
        | drivers_license | barcode    |
        | valid DL        | 0123456789 |


    @fast
    Scenario Outline: Age restricted item with the id_validation flag requires additional validation after ID swipe
        Given the POS is in a ready to sell state
        And the POS displays Age verification frame after scanning an item barcode <barcode>
        When the cashier swipes a driver's license <drivers_license>
        Then the POS displays ID validation frame

        Examples:
        | drivers_license | barcode    |
        | valid DL        | 0123456789 |


    @fast
    Scenario Outline: Cashier selects No on the ID validation prompt, item is not added
        Given the POS is in a ready to sell state
        And the POS displays ID validation frame after scanning an age restricted item barcode <barcode> and scanning a DL
        When the cashier selects No button
        Then the POS displays main menu frame
        And an item <item_name> with price <item_price> is not in the virtual receipt
        And an item <item_name> with price <item_price> is not in the current transaction

        Examples:
        | item_name          | barcode    | item_price |
        | ID Validation item | 0123456789 | 3.21       |


    @fast
    Scenario Outline: Cashier selects Yes on the ID validation prompt, item is added
        Given the POS is in a ready to sell state
        And the POS displays ID validation frame after scanning an age restricted item barcode <barcode> and scanning a DL
        When the cashier selects Yes button
        Then the POS displays main menu frame
        And an item <item_name> with price <item_price> is in the virtual receipt
        And an item <item_name> with price <item_price> is in the current transaction

        Examples:
        | item_name          | barcode    | item_price |
        | ID Validation item | 0123456789 | 3.21       |


    @fast
    Scenario Outline: Age verified by swipe and ID already validated, another item with the id_validation flag added, POS does not prompt again
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode> is present in the transaction after scanning a DL and its secondary validation
        When the cashier scans a barcode <barcode> and totals the transaction
        Then the POS displays Ask tender amount cash frame
        And an item <item_name> with price <total_price> and quantity 2 is in the virtual receipt
        And an item <item_name> with price <total_price> and quantity 2 is in the current transaction

        Examples:
        | item_name          | barcode    | total_price |
        | ID Validation item | 0123456789 | 6.42        |


    @fast
    Scenario Outline: Age verified by swipe but ID not validated, another item with the id_validation flag added, POS reprompts for age verification
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode1> is present in the transaction after a scanned DL valid DL age verification
        When the cashier scans a barcode <barcode2>
        Then the POS displays the Age verification frame

        Examples:
        | barcode1     | barcode2   |
        | 022222222220 | 0123456789 |


    @fast
    Scenario Outline: Age verified by swipe but ID not validated, another item with the id_validation flag added, POS reprompts for age verification and ID validation
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode1> is present in the transaction after a scanned DL valid DL age verification
        And the POS displays Age verification frame after scanning an item barcode <barcode2>
        When the cashier scans a driver's license valid DL
        Then the POS displays ID validation frame

        Examples:
        | barcode1     | barcode2   |
        | 022222222220 | 0123456789 |


    @fast
    Scenario Outline: Age verified by swipe but ID not validated, another item with the id_validation flag added, POS reprompts
        for age verification and ID validation, does not remove previous item if cashier does not confirm the ID
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode1> is present in the transaction after a scanned DL valid DL age verification
        And the POS displays ID validation frame after scanning an age restricted item barcode <barcode2> and scanning a DL
        When the cashier selects No button
        Then the POS displays main menu frame
        And an item <description1> with price <price1> is in the virtual receipt
        And an item <description1> with price <price1> is in the current transaction
        And an item <description2> with price <price2> is not in the virtual receipt
        And an item <description2> with price <price2> is not in the current transaction

        Examples:
        | description1      | description2       | barcode1     | barcode2   | price1 | price2 |
        | Age 21 Restricted | ID Validation item | 022222222220 | 0123456789 | 4.69   | 3.21   |


    @fast
    Scenario Outline: Age verified by swipe but ID not validated, another item with the id_validation flag added, POS reprompts
        for age verification and ID validation, item is added if cashier confirms the ID
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode1> is present in the transaction after a scanned DL valid DL age verification
        And the POS displays ID validation frame after scanning an age restricted item barcode <barcode2> and scanning a DL
        When the cashier selects Yes button
        Then the POS displays main menu frame
        And an item <description1> with price <price1> is in the virtual receipt
        And an item <description1> with price <price1> is in the current transaction
        And an item <description2> with price <price2> is in the virtual receipt
        And an item <description2> with price <price2> is in the current transaction

        Examples:
        | description1      | description2       | barcode1     | barcode2   | price1 | price2 |
        | Age 21 Restricted | ID Validation item | 022222222220 | 0123456789 | 4.69   | 3.21   |


    @fast
    Scenario Outline: Age (19) verified by swipe but ID not validated, another item (21) with the id_validation flag scanned but rejected right away
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode1> is present in the transaction after a scanned DL valid 19yo DL age verification
        When the cashier scans a barcode <barcode2>
        Then the POS displays an Error frame saying Customer does not meet age requirement
        And an item <description1> with price <price1> is in the virtual receipt
        And an item <description1> with price <price1> is in the current transaction
        And an item <description2> with price <price2> is not in the virtual receipt
        And an item <description2> with price <price2> is not in the current transaction

        Examples:
        | description1      | description2       | barcode1     | barcode2   | price1 | price2 |
        | Age 18 Restricted | ID Validation item | 0369369369   | 0123456789 | 3.69   | 3.21   |

    @fast
    Scenario Outline: Age verified by manual entry, another item with the id_validation flag added, POS does not reprompt
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode1> is present in the transaction after manual entry age verification
        When the cashier scans a barcode <barcode2>
        Then the POS displays main menu frame
        And an item <description1> with price <price1> is in the virtual receipt
        And an item <description1> with price <price1> is in the current transaction
        And an item <description2> with price <price2> is in the virtual receipt
        And an item <description2> with price <price2> is in the current transaction

        Examples:
        | description1      | description2       | barcode1     | barcode2   | price1 | price2 |
        | Age 21 Restricted | ID Validation item | 022222222220 | 0123456789 | 4.69   | 3.21   |


    @fast
    Scenario Outline: Age verified by instant approval button, another item with the id_validation flag added, POS does not reprompt
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode1> is present in the transaction after instant approval age verification
        When the cashier scans a barcode <barcode2>
        Then the POS displays main menu frame
        And an item <description1> with price <price1> is in the virtual receipt
        And an item <description1> with price <price1> is in the current transaction
        And an item <description2> with price <price2> is in the virtual receipt
        And an item <description2> with price <price2> is in the current transaction

        Examples:
        | description1      | description2       | barcode1     | barcode2   | price1 | price2 |
        | Age 21 Restricted | ID Validation item | 022222222220 | 0123456789 | 4.69   | 3.21   |


    @fast
    Scenario Outline: Recall a transaction with a validated ID into a transaction with an age restricted item verified by DL scan without ID validation,
                      POS reprompts for age verification
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode1> is present in the transaction after scanning a DL and its secondary validation
        And the cashier stored the transaction
        And an age restricted item with barcode <barcode2> is present in the transaction after scanning a valid DL
        When the cashier recalls the last stored transaction
        Then the POS displays the Age verification frame

        Examples:
        | barcode1   | barcode2     |
        | 0123456789 | 022222222220 |


    @fast
    Scenario Outline: Recall a transaction with a validated ID into a transaction with an age restricted item verified by instant approval button,
                      POS does not reprompt for age verification
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode1> is present in the transaction after scanning a DL and its secondary validation
        And the cashier stored the transaction
        And an age restricted item with barcode <barcode2> is present in the transaction after instant approval age verification
        When the cashier recalls the last stored transaction
        Then the POS displays main menu frame
        And an item <description1> with price <price1> is in the virtual receipt
        And an item <description1> with price <price1> is in the current transaction
        And an item <description2> with price <price2> is in the virtual receipt
        And an item <description2> with price <price2> is in the current transaction

        Examples:
        | description1       | description2      | barcode1   | barcode2     | price1 | price2 |
        | ID Validation item | Age 21 Restricted | 0123456789 | 022222222220 | 3.21   | 4.69   |


    @fast
    Scenario Outline: Recall a transaction with a validated ID into a transaction with an age restricted item verified by manual entry,
                      POS does not reprompt for age verification
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode1> is present in the transaction after scanning a DL and its secondary validation
        And the cashier stored the transaction
        And an age restricted item with barcode <barcode2> is present in the transaction after manual entry age verification
        When the cashier recalls the last stored transaction
        Then the POS displays main menu frame
        And an item <description1> with price <price1> is in the virtual receipt
        And an item <description1> with price <price1> is in the current transaction
        And an item <description2> with price <price2> is in the virtual receipt
        And an item <description2> with price <price2> is in the current transaction

        Examples:
        | description1       | description2      | barcode1   | barcode2     | price1 | price2 |
        | ID Validation item | Age 21 Restricted | 0123456789 | 022222222220 | 3.21   | 4.69   |


    @fast @pos_connect
    Scenario Outline: Sell an item with id validation flag and validate the response after valid driver's license is scanned
        Given the POS has the feature PosApiServer enabled
        And the POS is in a ready to sell state
        And the application sent |["Pos/SellItem", {"Barcode": "0123456789"}]| to the POS Connect
		When the application sends a valid DL barcode to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data contain |<response_data>|

        Examples:
        | response_data |
        | {"DataType": "YesNo", "PromptId": 5054, "PromptText": "PLEASE CHECK ID PHOTO\n\nPLEASE CHECK ID FIELDS\nID #: 29987353\nNAME: JOHN SMITH            "} |


    @fast @pos_connect
    Scenario Outline: Item with id validation flag is added to transaction when id does match
        Given the POS has the feature PosApiServer enabled
        And the POS is in a ready to sell state
        And the application sent |["Pos/SellItem", {"Barcode": "0123456789"}]| to the POS Connect
        And the application sent a valid DL barcode to the POS Connect
        When the application sends |["Pos/DataNeededResponse",{"DataType": "YesNo", "YesNoData": "Yes"}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|

		Examples:
        | response_data |
        | {"TransactionData": {"ItemList": [{"Description": "ID Validation item", "ExtendedPriceAmount": 3.21, "ItemNumber": 1, "POSItemId": 123456789, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "*": "*"}], "TransactionBalance": 3.43, "TransactionSubTotal": 3.21, "TransactionTaxAmount": 0.22, "TransactionTotal": 3.43}, "TransactionSequenceNumber": "*"} |


    @fast @pos_connect
    Scenario Outline: Item with id validation flag is not added to transaction when id does not match
        Given the POS has the feature PosApiServer enabled
        And the POS is in a ready to sell state
        And the application sent |["Pos/SellItem", {"Barcode": "0123456789"}]| to the POS Connect
        And the application sent a valid DL barcode to the POS Connect
        When the application sends |["Pos/DataNeededResponse",{"DataType": "YesNo", "YesNoData": "No"}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|

		Examples:
        | response_data |
        | {"ReturnCode":1099,"ReturnCodeDescription":"Visual check of presented ID failed.","TransactionSequenceNumber":"*"} |


    @fast @pos_connect
    Scenario Outline: Age verification frame is displayed again after and item with id validation flag is recalled from the store queue
        Given the POS has the feature PosApiServer enabled
        And the POS is in a ready to sell state
        And the application sent |["Pos/SellItem", {"Barcode": "0123456789"}]| to the POS Connect
        And the application sent a valid DL barcode to the POS Connect
        And the application sent |["Pos/DataNeededResponse",{"DataType": "YesNo", "YesNoData": "Yes"}]| to the POS Connect
        And  current transaction is stored under Stored Transaction Sequence Number
		When the application sends RecallTransaction command with last stored Sequence Number to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data contain |<response_data>|

		Examples:
        | response_data |
        | {"AvailableOperations":[{"Name":"Cancel","Text":""},{"Name":"InstantApproval","Text":"Over"}],"DataType":"Date","PromptId":5072,"PromptText":"Enter Customer's Birthday (MM/DD/YYYY)"} |


    @fast @pos_connect
    Scenario Outline:  Age verification frame is displayed again after adding an item with id validation flag to transaction which already contains age restricted item which doesn't require id validation
        Given the POS has the feature PosApiServer enabled
        And the POS is in a ready to sell state
        And the application sent |["Pos/SellItem", {"Barcode": "022222222220"}]| to the POS Connect
        And the application sent a valid DL barcode to the POS Connect
        When the application sends |["Pos/SellItem", {"Barcode": "0123456789"}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data contain |<response_data>|

        Examples:
        | response_data |
        | {"AvailableOperations":[{"Name":"Cancel","Text":""},{"Name":"InstantApproval","Text":"Over"}],"DataType":"Date","PromptId":5072,"PromptText":"Enter Customer's Birthday (MM/DD/YYYY)"} |


    @fast @pos_connect
    Scenario Outline: Age restricted item which doesn't require id validation is not removed from transaction when another item with id validation flag is scanned but id does not match
        Given the POS has the feature PosApiServer enabled
        And the POS is in a ready to sell state
        And the application sent |["Pos/SellItem", {"Barcode": "022222222220"}]| to the POS Connect
        And the application sent a valid DL barcode to the POS Connect
        And the application sent |["Pos/SellItem", {"Barcode": "0123456789"}]| to the POS Connect
        And the application sent a valid DL barcode to the POS Connect
        When the application sends |["Pos/DataNeededResponse",{"DataType": "YesNo", "YesNoData": "No"}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|
        And an item <item_description1> with price <item_price1> is in the current transaction
        And an item <item_description2> with price <item_price2> is not in the current transaction

        Examples:
        | response_data | item_description1 | item_price1 | item_description2 | item_price2 |
        | {"ReturnCode":1099,"ReturnCodeDescription":"Visual check of presented ID failed.","TransactionSequenceNumber":"*"} | Age 21 Restricted | 4.69 | ID Validation item | 3.21 |
