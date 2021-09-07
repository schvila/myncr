@pos
Feature: Age verification - disable instant approval button (over 30) on demand
    This feature file focuses on a portion of age verification, where items can be marked with a flag, disallowing it
    to be verified with the instant approval button - manual entry, swipe or scan need to be used instead.

    Background: POS is properly configured for Age verification feature
        Given the POS has essential configuration
        # "Age verification" option set to "By birthdate or license swipe"
        And the POS option 1010 is set to 2
        # "Age check instant approval age" option set to "30"
        And the POS option 1012 is set to 30
        # "Age verification failure tracking" option set to "NO"
        And the POS option 1024 is set to 0
        And the pricebook contains retail items
            | description       | price  | age_restriction | barcode      | item_id      | modifier1_id | disable_over_button |
            | Age 21 Restricted | 4.69   | 21              | 022222222220 | 990000000009 | 990000000007 | False               |
            | Age 18 Restricted | 3.69   | 18              | 0369369369   | 990000000010 | 990000000007 | False               |
            | 21 No Over Button | 1.23   | 21              | 0123456789   | 0123456789   | 0            | True                |

    @fast
    Scenario Outline: Adding an age restricted item without the disable_over_button flag results in displaying the age verification frame with the instant approval button
        Given the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then a new transaction is started
        And the POS displays the Age verification frame with the instant approval button

        Examples:
        | barcode      |
        | 022222222220 |
        | 0369369369   |


    @fast
    Scenario Outline: Adding an age restricted item with the disable_over_button flag results in displaying the age verification frame without the instant approval button
        Given the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then a new transaction is started
        And the POS displays the Age verification frame without the instant approval button

        Examples:
        | barcode    |
        | 0123456789 |


    @fast
    Scenario Outline: Adding an age restricted item using the instant approval button followed by an item with the disable_over_button flag results in
                      displaying the age verification frame again without the instant approval button
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode1> is present in the transaction after instant approval age verification
        When the cashier scans a barcode <barcode2>
        Then the POS displays the Age verification frame without the instant approval button

        Examples:
        | barcode1     | barcode2   |
        | 022222222220 | 0123456789 |


    @fast
    Scenario Outline: Performing a second age verification (non-instant approval) rewrites the original verification method
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode1> is present in the transaction after instant approval age verification
        And the POS displays Age verification frame after scanning an item barcode <barcode2>
        When the cashier swipes a driver's license valid DL
        Then the POS displays main menu frame
        And an item <description2> with price <price2> is in the virtual receipt
        And an item <description2> with price <price2> is in the current transaction
        And the license swipe age verification method is in the current transaction

        Examples:
        | barcode1     | barcode2   | description2      | price2 |
        | 022222222220 | 0123456789 | 21 No Over Button | 1.23   |


    @fast
    Scenario Outline: Performing a second age verification (non-instant approval) which lowers the customer's age below the threshold
                      of previously added displays an error saying Customer does not meet age requirements
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode1> is present in the transaction after instant approval age verification
        And the POS displays Age verification frame after scanning an item barcode <barcode2>
        When the cashier swipes a driver's license underage DL
        Then the POS displays an Error frame saying Customer does not meet age requirement

        Examples:
        | barcode1     | barcode2   |
        | 022222222220 | 0123456789 |


    @fast
    Scenario Outline: Performing a second age verification (non-instant approval) which lowers the customer's age below the threshold
                      of previously added items lists the offending items to be removed from the transaction
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode1> is present in the transaction after instant approval age verification
        And the POS displays an Error frame saying Customer does not meet age requirement after scanning an age restricted item barcode <barcode2> and scanning a driver's license underage DL
        When the cashier selects Go back button
        Then the POS displays a list of previously added age restricted items to remove which contains <description1>
        And an item <description2> with price <price2> is not in the virtual receipt
        And an item <description2> with price <price2> is not in the current transaction
        And the license scan fail age verification method is in the current transaction

        Examples:
        | barcode1     | barcode2   | description1      | description2      | price2 |
        | 022222222220 | 0123456789 | Age 21 Restricted | 21 No Over Button | 1.23   |


    @fast
    Scenario Outline: Confirming the prompt to take back ineligible items after failed verification automatically removes the offending items from the transaction
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode1> is present in the transaction after instant approval age verification
        And the POS displays a list of items to remove after failing age verification of item <barcode2>
        When the cashier selects Go back button
        Then the POS displays main menu frame
        And an item <description1> with price <price1> is not in the virtual receipt
        And an item <description1> with price <price1> is not in the current transaction
        And the license scan fail age verification method is in the current transaction

        Examples:
        | barcode1     | barcode2   | description1      | price1 |
        | 022222222220 | 0123456789 | Age 21 Restricted | 4.69   |


    @fast
    Scenario Outline: Recall a transaction with a disallowed instant approval button into a transaction with already instantly approved age restricted item
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode1> is present in the transaction after manual entry age verification
        And the cashier stored the transaction
        And an age restricted item with barcode <barcode2> is present in the transaction after instant approval age verification
        When the cashier recalls the last stored transaction
        Then the POS displays the Age verification frame without the instant approval button

        Examples:
        | barcode1   | barcode2     |
        | 0123456789 | 022222222220 |


    @fast
    Scenario Outline: Adding an age restricted item without the disable_over_button flag results in displaying the age verification frame
                      with the instant approval button (POS option 1010 set to 1)
        # "Age verification" option set to "By birthdate"
        Given the POS option 1010 is set to 1
        And the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then a new transaction is started
        And the POS displays the Manual only Age verification frame with the instant approval button

        Examples:
        | barcode      |
        | 022222222220 |
        | 0369369369   |


    @fast
    Scenario Outline: Adding an age restricted item with the disable_over_button flag results in displaying the age verification frame
                      without the instant approval button (POS option 1010 set to 1)
        # "Age verification" option set to "By birthdate"
        Given the POS option 1010 is set to 1
        And the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then a new transaction is started
        And the POS displays the Manual only Age verification frame without the instant approval button

        Examples:
        | barcode    |
        | 0123456789 |


    @fast
    Scenario Outline: Adding an age restricted item using the instant approval button followed by an item with the disable_over_button flag results in
                      displaying the age verification frame again without the instant approval button (POS option 1010 set to 1)
        # "Age verification" option set to "By birthdate"
        Given the POS option 1010 is set to 1
        And the POS is in a ready to sell state
        And an age restricted item with barcode <barcode1> is present in the transaction after instant approval on the manual age verification frame
        When the cashier scans a barcode <barcode2>
        Then the POS displays the Manual only Age verification frame without the instant approval button

        Examples:
        | barcode1     | barcode2   |
        | 022222222220 | 0123456789 |


    @fast
    Scenario Outline: Adding an age restricted item without the disable_over_button flag but with the instant approval button disabled by pos option
                      results in displaying the age verification frame without the instant approval button
        # "Age check instant approval age" option set to "Do not use"
        Given the POS option 1012 is set to 0
        And the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then a new transaction is started
        And the POS displays the Age verification frame without the instant approval button

        Examples:
        | barcode      |
        | 022222222220 |
        | 0123456789   |


    @fast
    Scenario Outline: Adding an age restricted item without the disable_over_button flag but with the instant approval button disabled by pos option
                      results in displaying the age verification frame without the instant approval button (POS option 1010 set to 1)
        # "Age verification" option set to "By birthdate"
        Given the POS option 1010 is set to 1
        # "Age check instant approval age" option set to "Do not use"
        And the POS option 1012 is set to 0
        And the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then a new transaction is started
        And the POS displays the Manual only Age verification frame without the instant approval button

        Examples:
        | barcode      |
        | 022222222220 |
        | 0123456789   |


    @fast
    Scenario Outline: Adding an age restricted item with the disable_over_button flag while validation method is set to Over/Under results in displaying the
                      "By birthday or license swipe" age verification frame without the instant approval button
        # "Age verification" option set to "Prompt for Yes/No"
        Given the POS option 1010 is set to 0
        And the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then a new transaction is started
        And the POS displays the Age verification frame without the instant approval button

        Examples:
        | barcode    |
        | 0123456789 |


    @fast
    Scenario Outline: Adding an age restricted item using the instant approval button followed by an item with the disable_over_button flag results in
                      displaying the age verification frame again without the instant approval button
        # "Age verification" option set to "Prompt for Yes/No"
        Given the POS option 1010 is set to 0
        And the POS is in a ready to sell state
        And an age restricted item with barcode <barcode1> is present in the transaction after Over/Under age verification
        When the cashier scans a barcode <barcode2>
        Then the POS displays the Age verification frame without the instant approval button

        Examples:
        | barcode1     | barcode2   |
        | 022222222220 | 0123456789 |


    @fast
    Scenario Outline: Recall a transaction with a disallowed instant approval button into a transaction with already instantly approved age restricted item
        # "Age verification" option set to "Prompt for Yes/No"
        Given the POS option 1010 is set to 0
        And the POS is in a ready to sell state
        And an age restricted item with barcode <barcode1> is present in the transaction after manual entry age verification
        And the cashier stored the transaction
        And an age restricted item with barcode <barcode2> is present in the transaction after Over/Under age verification
        When the cashier recalls the last stored transaction
        Then the POS displays the Age verification frame without the instant approval button

        Examples:
        | barcode1   | barcode2     |
        | 0123456789 | 022222222220 |


    @fast
    Scenario Outline: Adding an age restricted item using the instant approval button followed by an item with the disable_over_button flag results in
                      displaying the age verification frame again without the instant approval button
        # "Age verification" option set to "Prompt for Yes/No"
        Given the POS option 1010 is set to 0
        # "Age check instant approval age" option set to "Do not use"
        And the POS option 1012 is set to 0
        And the POS is in a ready to sell state
        And an age restricted item with barcode <barcode1> is present in the transaction after Over/Under age verification
        When the cashier scans a barcode <barcode2>
        Then the POS displays the Age verification frame without the instant approval button

        Examples:
        | barcode1     | barcode2   |
        | 022222222220 | 0123456789 |


    @fast @pos_connect
    Scenario Outline: POSConnect - Send SellItem command to the POS for an Age restricted item with Hide over 30 button flag,
                      validate the DataNeeded Response, Instant approval is not available, Age verification frame is displayed
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data are |<response_data>|
        And the POS displays the Age verification frame without the instant approval button

        Examples:
        | request                                     | response_data                             |
        | ["Pos/SellItem", {"Barcode": "0123456789"}] | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}], "DataType": "Date", "PromptId": 5072, "PromptText": "Enter Customer's Birthday (MM/DD/YYYY)"}|


    @fast @pos_connect
    Scenario Outline: POSConnect - Send DataNeededResponse command to the POS with a valid birthday format after attempting to sell
                      an Age restricted item with Hide over 30 button flag, validate the response, item is added to the transaction
        Given the POS is in a ready to sell state
        And the application sent |["Pos/SellItem", {"Barcode": "0123456789"}]| to the POS Connect
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|
        And the POS displays main menu frame
        And an item <item_description> with price <item_price> is in the current transaction

        Examples:
        | request                                                              | item_description  | item_price | response_data                             |
        | ["Pos/DataNeededResponse", {"DataType": "Date", "Date": "06091985"}] | 21 No Over Button | 1.23       | {"TransactionData": {"ItemList": [{"Description": "21 No Over Button", "ExtendedPriceAmount": 1.23, "ItemNumber": 1, "POSItemId": 123456789, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "*": "*"}], "TransactionBalance": 1.31, "TransactionSubTotal": 1.23, "TransactionTaxAmount": 0.08, "TransactionTotal": 1.31}, "TransactionSequenceNumber": "*"}|


    @fast @pos_connect
    Scenario Outline: POSConnect - Send DataNeededResponse command to the POS with an instant approval operation after attempting to sell
                      an Age restricted item with Hide over 30 button flag, validate the response, operation not allowed
        Given the POS is in a ready to sell state
        And the application sent |["Pos/SellItem", {"Barcode": "0123456789"}]| to the POS Connect
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data contain |<response_data>|
        And the POS displays the Age verification frame without the instant approval button

        Examples:
        | request                                                                  | response_data                             |
        | ["Pos/DataNeededResponse", {"SelectedOperationName": "InstantApproval"}] | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}], "DataType": "Date", "PromptId": 5072, "PromptText": "Enter Customer's Birthday (MM/DD/YYYY)", "ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter SelectedOperationName contains an unexpected value."} |


    @fast @pos_connect
    Scenario Outline: POSConnect - Send SellItem command to the POS for an Age restricted item with Hide over 30 button flag,
                      after an age restricted item was already added to the transaction via POSConnect and approved by
                      instant approval button, POS reprompts for a different age verification, Instant approval is not available
        Given the POS is in a ready to sell state
        And an age restricted item with barcode 022222222220 is present in the transaction after instant approval age verification through POSConnect
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data contain |<response_data>|
        And the POS displays the Age verification frame without the instant approval button

        Examples:
        | request                                     | response_data                             |
        | ["Pos/SellItem", {"Barcode": "0123456789"}] | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}], "DataType": "Date", "PromptId": 5072, "PromptText": "Enter Customer's Birthday (MM/DD/YYYY)"}|


    @fast @pos_connect
    Scenario Outline: POSConnect - Performing a second age verification (non-instant approval) rewrites the original verification method, item is added to the transaction
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode1> is present in the transaction after instant approval age verification through POSConnect
        And the application sent |["Pos/SellItem", {"Barcode": "<barcode2>"}]| to the POS Connect
        When the application sends a valid DL barcode to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|
        And the POS displays main menu frame
        And an item <description2> with price <price2> is in the virtual receipt
        And an item <description2> with price <price2> is in the current transaction
        And the license scan age verification method is in the current transaction

        Examples:
        | barcode1     | barcode2   | description2      | price2 | response_data |
        | 022222222220 | 0123456789 | 21 No Over Button | 1.23   | {"TransactionData": {"ItemList": [{"Description": "Age 21 Restricted", "ExtendedPriceAmount": 4.69, "ExternalId": "ITT-022222222220-0-1", "ItemNumber": 1, "POSItemId": 990000000009, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "*": "*"}, {"Description": "21 No Over Button", "ExtendedPriceAmount": 1.23, "ItemNumber": 2, "POSItemId": 123456789, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "*": "*"}], "TransactionBalance": 6.34, "TransactionSubTotal": 5.92, "TransactionTaxAmount": 0.42, "TransactionTotal": 6.34}, "TransactionSequenceNumber": "*"}|


    @fast @pos_connect
    Scenario Outline: POSConnect - Performing a second age verification (non-instant approval) which lowers the customer's age below the threshold
                      of previously added items lists the offending items to be physically removed by the cashier, removes them from the transaction and
                      lists the transaction data, POS displays main menu frame
        Given the POS is in a ready to sell state
        And the application sent |["Pos/SellItem", {"Barcode": "<barcode1>"}]| to the POS Connect
        And an age restricted item with barcode <barcode2> is present in the transaction after instant approval age verification through POSConnect
        And the application sent |["Pos/SellItem", {"Barcode": "<barcode3>"}]| to the POS Connect
        When the application sends an underage DL barcode to the POS Connect
        Then the POS displays main menu frame
        And the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | barcode1     | barcode2     | barcode3   | response_data |
        | 099999999990 | 022222222220 | 0123456789 | {"RemovedItemList": [{"Description": "Age 21 Restricted", "ItemNumber": 2, "Quantity": 1}], "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement.", "TransactionData": {"ItemList": [{"Description": "Sale Item A", "ExtendedPriceAmount": 0.99, "ExternalId": "ITT-099999999990-0-1", "ItemNumber": 1, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "*": "*"}], "TransactionBalance": 1.06, "TransactionSubTotal": 0.99, "TransactionTaxAmount": 0.07, "TransactionTotal": 1.06}, "TransactionSequenceNumber": "*"}|


    @fast @pos_connect
    Scenario Outline: POSConnect - Recall a transaction with a disallowed instant approval button into a transaction with already instantly approved age restricted item
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode1> is present in the transaction after manual entry age verification through POSConnect
        And current transaction is stored under Stored Transaction Sequence Number
        And an age restricted item with barcode <barcode2> is present in the transaction after instant approval age verification through POSConnect
        When the application sends RecallTransaction command with last stored Sequence Number to the POS Connect
        Then the POS displays the Age verification frame without the instant approval button
        And the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data contain |<response_data>|

        Examples:
        | barcode1   | barcode2     | response_data |
        | 0123456789 | 022222222220 | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}], "DataType": "Date", "PromptId": 5072, "PromptText": "Enter Customer's Birthday (MM/DD/YYYY)"}|
