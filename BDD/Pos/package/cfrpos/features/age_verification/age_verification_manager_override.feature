@pos
Feature: Age verification - Manager override
    This feature file focuses on a portion of age verification, where items can be marked with a flag, forcing a
    manager to first approve the cashier to perform a manual entry age verification.

    Background: POS is properly configured for Age verification feature
        Given the POS has essential configuration
        # "Age verification" option set to "By birthdate or license swipe"
        And the POS option 1010 is set to 2
        # "Age verification failure tracking" option set to "NO"
        And the POS option 1024 is set to 0
        And the pricebook contains retail items
            | description        | price  | age_restriction | barcode      | item_id      | modifier1_id | manager_override_required |
            | Manager req item   | 4.69   | 21              | 987654321    | 987654321    | 0            | True                      |
            | Age 18 Restricted  | 3.69   | 18              | 0369369369   | 990000000010 | 990000000007 | False                     |
        And the following cashiers are configured
            | first_name | last_name | security_role | PIN  |
            | cashier    | 1234      | cashier       | 1234 |
            | manager    | 2345      | manager       | 2345 |


    @fast
    Scenario Outline: Age restricted item without the manager_override flag displays a generic age verification frame with the keyboard on scan
        Given the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then the POS displays the Age verification frame
        And the Manual entry button is not displayed on the current frame

        Examples:
        | barcode      |
        | 0369369369   |


    @fast
    Scenario Outline: Age restricted item with the manager_override flag displays an age verification frame without the keyboard and a Manual entry button on scan
        Given the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then the POS displays restricted Age verification frame
        And the instant verification button is not displayed on the current frame
        And the manual entry keyboard is not displayed on the current frame
        And the military ID button is not displayed on the current frame
        And the Manual entry button is displayed on the current frame

        Examples:
        | barcode      |
        | 987654321    |


    @fast
    Scenario Outline: Pressing Manual entry button after scanning an age restricted item displays the manager override frame
        Given the POS is in a ready to sell state
        And the POS displays restricted Age verification frame after scanning an item barcode <barcode>
        When the cashier selects Manual entry button
        Then the POS displays Manager override frame

        Examples:
        | barcode      |
        | 987654321    |


    @fast
    Scenario Outline: Pressing Go back button on the age verification frame cancels the age verification and displays the main menu frame
        Given the POS is in a ready to sell state
        And the POS displays restricted Age verification frame after scanning an item barcode <barcode>
        When the cashier selects Go back button
        Then the POS displays main menu frame
        And an item <description> with price <price> is not in the current transaction
        And an item <description> with price <price> is not in the virtual receipt

        Examples:
        | barcode      | description       | price |
        | 987654321    | Manager req item  | 4.69  |


    @fast
    Scenario Outline: Manager signs in using his PIN, a regular age verification frame with keyboard and instant approval button is displayed
        Given the POS is in a ready to sell state
        And the POS displays Manager override frame after scanning an item barcode <barcode>
        When the manager signs in using <PIN> PIN
        Then the POS displays the Age verification frame
        And the Manual entry button is not displayed on the current frame

        Examples:
        | barcode      | PIN  |
        | 987654321    | 2345 |


    @fast
    Scenario Outline: Cashier signs in using his PIN, Insufficient security rights frame is displayed
        Given the POS is in a ready to sell state
        And the POS displays Manager override frame after scanning an item barcode <barcode>
        When the cashier signs in using <PIN> PIN
        Then the POS displays Security denied error frame

        Examples:
        | barcode      | PIN  |
        | 987654321    | 1234 |


    @fast
    Scenario Outline: Pressing Go back button on the manager override frame goes back to the restricted age verification frame
        Given the POS is in a ready to sell state
        And the POS displays Manager override frame after scanning an item barcode <barcode>
        When the cashier selects Go back button
        Then the POS displays restricted Age verification frame
        And an item <description> with price <price> is not in the current transaction
        And an item <description> with price <price> is not in the virtual receipt

        Examples:
        | barcode      | description       | price |
        | 987654321    | Manager req item  | 4.69  |


    @fast
    Scenario Outline: Enter a valid birthdate manually after manager confirmation, item gets added to transaction
        Given the POS is in a ready to sell state
        And the POS displays Manager override frame after scanning an item barcode <barcode>
        And the POS displays Age verification frame after manager signed in using <PIN> PIN
        When the cashier manually enters the 30yo customer's birthday
        Then the POS displays main menu frame
        And an item <description> with price <price> is in the current transaction
        And an item <description> with price <price> is in the virtual receipt

        Examples:
        | barcode      | PIN  | description       | price |
        | 987654321    | 2345 | Manager req item  | 4.69  |


    @fast
    Scenario Outline: Enter an underage birthdate manually after manager confirmation, item gets rejected
        Given the POS is in a ready to sell state
        And the POS displays Manager override frame after scanning an item barcode <barcode>
        And the POS displays Age verification frame after manager signed in using <PIN> PIN
        When the cashier manually enters the 12yo customer's birthday
        Then the POS displays an Error frame saying Customer does not meet age requirement
        And an item <description> with price <price> is not in the virtual receipt
        And an item <description> with price <price> is not in the current transaction

        Examples:
        | barcode      | PIN  | description       | price |
        | 987654321    | 2345 | Manager req item  | 4.69  |


    @fast
    Scenario Outline: Scan a valid driver's license after manager confirmation of manual entry, item gets added to transaction
        Given the POS is in a ready to sell state
        And the POS displays Manager override frame after scanning an item barcode <barcode>
        And the POS displays Age verification frame after manager signed in using <PIN> PIN
        When the cashier scans a driver's license valid DL
        Then the POS displays main menu frame
        And an item <description> with price <price> is in the current transaction
        And an item <description> with price <price> is in the virtual receipt

        Examples:
        | barcode      | PIN  | description       | price |
        | 987654321    | 2345 | Manager req item  | 4.69  |


    @fast
    Scenario Outline: Scan an underage driver's license after manager confirmation of manual entry, item gets rejected
        Given the POS is in a ready to sell state
        And the POS displays Manager override frame after scanning an item barcode <barcode>
        And the POS displays Age verification frame after manager signed in using <PIN> PIN
        When the cashier scans a driver's license underage DL
        Then the POS displays an Error frame saying Customer does not meet age requirement
        And an item <description> with price <price> is not in the virtual receipt
        And an item <description> with price <price> is not in the current transaction

        Examples:
        | barcode      | PIN  | description       | price |
        | 987654321    | 2345 | Manager req item  | 4.69  |


    @fast
    Scenario Outline: Swipe a valid driver's license after manager confirmation of manual entry, item gets added to transaction
        Given the POS is in a ready to sell state
        And the POS displays Manager override frame after scanning an item barcode <barcode>
        And the POS displays Age verification frame after manager signed in using <PIN> PIN
        When the cashier swipes a driver's license valid DL
        Then the POS displays main menu frame
        And an item <description> with price <price> is in the current transaction
        And an item <description> with price <price> is in the virtual receipt

        Examples:
        | barcode      | PIN  | description       | price |
        | 987654321    | 2345 | Manager req item  | 4.69  |


    @fast
    Scenario Outline: Swipe an underage driver's license after manager confirmation of manual entry, item gets rejected
        Given the POS is in a ready to sell state
        And the POS displays Manager override frame after scanning an item barcode <barcode>
        And the POS displays Age verification frame after manager signed in using <PIN> PIN
        When the cashier swipes a driver's license underage DL
        Then the POS displays an Error frame saying Customer does not meet age requirement
        And an item <description> with price <price> is not in the virtual receipt
        And an item <description> with price <price> is not in the current transaction

        Examples:
        | barcode      | PIN  | description       | price |
        | 987654321    | 2345 | Manager req item  | 4.69  |


    @fast
    Scenario Outline: An age restriction item without manager override required is in the transaction verified by manual entry,
                      second age restricted item which required manager override forces reverification
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode_1> is in the transaction after manual verification of 25yo customer
        When the cashier scans a barcode <barcode_2>
        Then the POS displays restricted Age verification frame

        Examples:
        | barcode_1    | barcode_2    |
        | 022222222220 | 987654321    |


    @fast
    Scenario Outline: An age restriction item without manager override required is in the transaction verified by instant approval button,
                      second age restricted item which required manager override forces reverification
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode_1> is present in the transaction after instant verification
        When the cashier scans a barcode <barcode_2>
        Then the POS displays restricted Age verification frame

        Examples:
        | barcode_1    | barcode_2    |
        | 022222222220 | 987654321    |


    @fast
    Scenario Outline: A manager is signed in, age restricted item requiring manager override skips the Enter pin frame
                      after selecting manual entry and displays the unrestricted age verification frame
        Given the POS is in a ready to start shift state
        And the cashier entered <manager_pin> pin after pressing Start shift button
        And the POS displays restricted Age verification frame after scanning an item barcode <barcode>
        When the cashier selects Manual entry button
        Then the POS displays the Age verification frame

        Examples:
        | barcode      | manager_pin |
        | 987654321    | 2345        |


    @fast @pos_connect
    Scenario Outline: POSConnect - Send SellItem command to the POS for an Age restricted item with Manager override flag,
                      validate the DataNeeded Response, Instant approval is not available, Manual keyboard is not available
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data contain |<response_data>|
        And the POS displays restricted Age verification frame

        Examples:
        | request                                    | response_data |
        | ["Pos/SellItem", {"Barcode": "987654321"}] | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}, {"Name": "ManualEntry", "Text": ""}], "DataType": "Date", "PromptId": 5072, "PromptText": "Scan/Swipe Customer's Drivers License"}|


    @fast @pos_connect
    Scenario Outline: POSConnect - Send DataNeededResponse command to the POS with a valid birthday format after attempting to sell
                      an Age restricted item with Manager override flag, validate the response, operation not allowed
        Given the POS is in a ready to sell state
        And the application sent |["Pos/SellItem", {"Barcode": "987654321"}]| to the POS Connect
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data contain |<response_data>|
        And the POS displays restricted Age verification frame
        And an item <item_description> with price <item_price> is not in the current transaction

        Examples:
        | request                                                              | item_description | item_price | response_data |
        | ["Pos/DataNeededResponse", {"DataType": "Date", "Date": "06091985"}] | Manager req item | 4.69       | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}, {"Name": "ManualEntry", "Text": ""}], "DataType": "Date", "PromptId": 5072, "PromptText": "Scan/Swipe Customer's Drivers License", "ReturnCode": 1096, "ReturnCodeDescription": "Age verification failed, used method is disabled."}|


    @fast @pos_connect
    Scenario Outline: POSConnect - Send DataNeededResponse command to the POS with an instant approval operation after attempting to sell
                      an Age restricted item with Manager override flag, validate the response, operation not allowed
        Given the POS is in a ready to sell state
        And the application sent |["Pos/SellItem", {"Barcode": "987654321"}]| to the POS Connect
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data contain |<response_data>|
        And the POS displays restricted Age verification frame
        And an item <item_description> with price <item_price> is not in the current transaction

        Examples:
        | request                                                                  | item_description | item_price | response_data |
        | ["Pos/DataNeededResponse", {"SelectedOperationName": "InstantApproval"}] | Manager req item | 4.69       | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}, {"Name": "ManualEntry", "Text": ""}], "DataType": "Date", "PromptId": 5072, "PromptText": "Scan/Swipe Customer's Drivers License", "ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter SelectedOperationName contains an unexpected value."}|


    @fast @pos_connect
    Scenario Outline: POSConnect - Send DataNeededResponse command to the POS with a valid driver's license barcode after attempting to sell
                      an Age restricted item with Manager override flag, validate the response, item is added to the transaction
        Given the POS is in a ready to sell state
        And the application sent |["Pos/SellItem", {"Barcode": "987654321"}]| to the POS Connect
        When the application sends a valid DL barcode to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|
        And the POS displays main menu frame
        And an item <item_description> with price <item_price> is in the current transaction

        Examples:
        | item_description | item_price | response_data |
        | Manager req item | 4.69       | {"TransactionData": {"ItemList": [{"Description": "Manager req item", "ExtendedPriceAmount": 4.69, "ItemNumber": 1, "POSItemId": 987654321, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "*": "*"}], "TransactionBalance": 5.02, "TransactionSubTotal": 4.69, "TransactionTaxAmount": 0.33, "TransactionTotal": 5.02}, "TransactionSequenceNumber": "*"}|


    @fast @pos_connect
    Scenario Outline: POSConnect - Send DataNeededResponse command to the POS with a ManualEntry operation after attempting to sell
                      an Age restricted item with Manager override flag, validate the response, Enter PIN frame is displayed
        Given the POS is in a ready to sell state
        And the application sent |["Pos/SellItem", {"Barcode": "987654321"}]| to the POS Connect
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data contain |<response_data>|
        And the POS displays Manager override frame
        And an item <item_description> with price <item_price> is not in the current transaction

        Examples:
        | request                                                              | item_description | item_price | response_data |
        | ["Pos/DataNeededResponse", {"SelectedOperationName": "ManualEntry"}] | Manager req item | 4.69       | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}], "DataType": "Integer", "PromptId": 5037, "PromptText": "Enter User Code to Override Security"}|


    @fast @pos_connect
    Scenario Outline: POSConnect - Send DataNeededResponse command to the POS with a Cashier's PIN after attempting to sell
                      an Age restricted item with Manager override flag and selecting Manual entry, response includes Insufficient security rights
        Given the POS is in a ready to sell state
        And the application sent |["Pos/SellItem", {"Barcode": "987654321"}]| to the POS Connect
        And the application sent |["Pos/DataNeededResponse", {"SelectedOperationName": "ManualEntry"}]| to the POS Connect
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data contain |<response_data>|
        And the POS displays Manager override frame
        And an item <item_description> with price <item_price> is not in the current transaction

        Examples:
        | request                                                                  | item_description | item_price | response_data |
        | ["Pos/DataNeededResponse", {"DataType": "Integer", "NumericData": 1234}] | Manager req item | 4.69       | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}], "DataType": "Integer", "PromptId": 5037, "PromptText": "Enter User Code to Override Security", "ReturnCode": 1028, "ReturnCodeDescription": "Security denied."}|


    @fast @pos_connect
    Scenario Outline: POSConnect - Send DataNeededResponse command to the POS with an unknown PIN after attempting to sell
                      an Age restricted item with Manager override flag and selecting Manual entry, response includes operator unknown
        Given the POS is in a ready to sell state
        And the application sent |["Pos/SellItem", {"Barcode": "987654321"}]| to the POS Connect
        And the application sent |["Pos/DataNeededResponse", {"SelectedOperationName": "ManualEntry"}]| to the POS Connect
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data contain |<response_data>|
        And the POS displays Manager override frame
        And an item <item_description> with price <item_price> is not in the current transaction

        Examples:
        | request                                                                  | item_description | item_price | response_data |
        | ["Pos/DataNeededResponse", {"DataType": "Integer", "NumericData": 4321}] | Manager req item | 4.69       | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}], "DataType": "Integer", "PromptId": 5037, "PromptText": "Enter User Code to Override Security", "ReturnCode": 1029, "ReturnCodeDescription": "Operator was not found."}|


    @fast @pos_connect
    Scenario Outline: POSConnect - Send DataNeededResponse command to the POS with a Manager's PIN after attempting to sell
                      an Age restricted item with Manager override flag and selecting Manual entry, validate response, generic age verification frame is displayed
        Given the POS is in a ready to sell state
        And the application sent |["Pos/SellItem", {"Barcode": "987654321"}]| to the POS Connect
        And the application sent |["Pos/DataNeededResponse", {"SelectedOperationName": "ManualEntry"}]| to the POS Connect
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data contain |<response_data>|
        And the POS displays the Age verification frame
        And an item <item_description> with price <item_price> is not in the current transaction

        Examples:
        | request                                                                  | item_description | item_price | response_data |
        | ["Pos/DataNeededResponse", {"DataType": "Integer", "NumericData": 2345}] | Manager req item | 4.69       | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}, {"Name": "InstantApproval", "Text": "Over"}], "DataType": "Date", "PromptId": 5072, "PromptText": "Enter Customer's Birthday (MM/DD/YYYY)"}|


    @fast @pos_connect
    Scenario Outline: POSConnect - Send DataNeededResponse command to the POS with a manual entry operation after attempting to sell
                      an Age restricted item with Manager override flag providing a valid manager PIN, validate response, item is added to the transaction
        Given the POS is in a ready to sell state
        And the application sent |["Pos/SellItem", {"Barcode": "987654321"}]| to the POS Connect
        And the application sent |["Pos/DataNeededResponse", {"SelectedOperationName": "ManualEntry"}]| to the POS Connect
        And the application sent |["Pos/DataNeededResponse", {"DataType": "Integer", "NumericData": 2345}]| to the POS Connect
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|
        And the POS displays main menu frame
        And an item <item_description> with price <item_price> is in the current transaction

        Examples:
        | request                                                              | item_description | item_price | response_data |
        | ["Pos/DataNeededResponse", {"DataType": "Date", "Date": "06091985"}] | Manager req item | 4.69       | {"TransactionData": {"ItemList": [{"Description": "Manager req item", "ExtendedPriceAmount": 4.69, "ItemNumber": 1, "POSItemId": 987654321, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "*": "*"}], "TransactionBalance": 5.02, "TransactionSubTotal": 4.69, "TransactionTaxAmount": 0.33, "TransactionTotal": 5.02}, "TransactionSequenceNumber": "*"}|


    @fast @pos_connect
    Scenario Outline: POSConnect - Add an age restricted item to the transaction using instant approval button, then lower
                      the verified age after reverification triggered by a manager override required item, first item gets removed
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode_1> is present in the transaction after instant verification
        And the application sent |["Pos/SellItem", {"Barcode": "987654321"}]| to the POS Connect
        And the application sent |["Pos/DataNeededResponse", {"SelectedOperationName": "ManualEntry"}]| to the POS Connect
        And the application sent |["Pos/DataNeededResponse", {"DataType": "Integer", "NumericData": 2345}]| to the POS Connect
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|
        And the POS displays main menu frame
        And an item <description_1> with price <price_1> is not in the current transaction
        And an item <description_2> with price <price_2> is not in the current transaction

        Examples:
        | request                                                              | barcode_1    | description_1     | price_1 | description_2    | price_2 | response_data |
        | ["Pos/DataNeededResponse", {"DataType": "Date", "Date": "06092010"}] | 022222222220 | Age 21 Restricted | 4.69    | Manager req item | 4.69    | {"RemovedItemList": [{"Description": "Age 21 Restricted", "ItemNumber": 1, "Quantity": 1}], "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement.", "TransactionData": {"TransactionBalance": 0.00, "TransactionSubTotal": 0.00, "TransactionTaxAmount": 0.00, "TransactionTotal": 0.00}, "TransactionSequenceNumber": "*"}|


    @fast @pos_connect
    Scenario Outline: POSConnect - Add an age restricted item to the transaction using manual entry, then lower
                      the verified age after reverification triggered by a manager override required item, first item gets removed
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode_1> is in the transaction after manual verification of 25yo customer
        And the application sent |["Pos/SellItem", {"Barcode": "987654321"}]| to the POS Connect
        And the application sent |["Pos/DataNeededResponse", {"SelectedOperationName": "ManualEntry"}]| to the POS Connect
        And the application sent |["Pos/DataNeededResponse", {"DataType": "Integer", "NumericData": 2345}]| to the POS Connect
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|
        And the POS displays main menu frame
        And an item <description_1> with price <price_1> is not in the current transaction
        And an item <description_2> with price <price_2> is not in the current transaction

        Examples:
        | request                                                              | barcode_1    | description_1     | price_1 | description_2    | price_2 | response_data |
        | ["Pos/DataNeededResponse", {"DataType": "Date", "Date": "06092010"}] | 022222222220 | Age 21 Restricted | 4.69    | Manager req item | 4.69    | {"RemovedItemList": [{"Description": "Age 21 Restricted", "ItemNumber": 1, "Quantity": 1}], "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement.", "TransactionData": {"TransactionBalance": 0.00, "TransactionSubTotal": 0.00, "TransactionTaxAmount": 0.00, "TransactionTotal": 0.00}, "TransactionSequenceNumber": "*"}|


    @fast @pos_connect
    Scenario Outline: POSConnect - Add an age restricted item to the transaction using DL scan, manager override item does
                      not trigger reverification and gets added to the transaction
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode_1> is present in the transaction after a scanned DL valid DL age verification
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|
        And the POS displays main menu frame
        And an item <description_1> with price <price_1> is in the current transaction
        And an item <description_2> with price <price_2> is in the current transaction

        Examples:
        | request                                    | barcode_1    | description_1     | price_1 | description_2    | price_2 | response_data |
        | ["Pos/SellItem", {"Barcode": "987654321"}] | 022222222220 | Age 21 Restricted | 4.69    | Manager req item | 4.69    | {"TransactionData": {"ItemList": [{"Description": "Age 21 Restricted", "ExtendedPriceAmount": 4.69, "ExternalId": "ITT-022222222220-0-1", "ItemNumber": 1, "POSItemId": 990000000009, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "*": "*"}, {"Description": "Manager req item", "ExtendedPriceAmount": 4.69, "ItemNumber": 2, "POSItemId": 987654321, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "*": "*"}], "TransactionBalance": 10.04, "TransactionSubTotal": 9.38, "TransactionTaxAmount": 0.66, "TransactionTotal": 10.04}, "TransactionSequenceNumber": "*"}|


    @fast @pos_connect
    Scenario Outline: POSConnect - A manager is signed in, age restricted item requiring manager override skips the Enter pin frame
                      after selecting manual entry and displays the unrestricted age verification frame
        Given the POS is in a ready to start shift state
        And the cashier entered <manager_pin> pin after pressing Start shift button
        And the application sent |["Pos/SellItem", {"Barcode": "987654321"}]| to the POS Connect
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data contain |<response_data>|
        And the POS displays the Age verification frame

        Examples:
        | request                                                              | manager_pin | response_data |
        | ["Pos/DataNeededResponse", {"SelectedOperationName": "ManualEntry"}] | 2345        | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}, {"Name": "InstantApproval", "Text": "Over"}], "DataType": "Date", "PromptId": 5072, "PromptText": "Enter Customer's Birthday (MM/DD/YYYY)"}|


    @fast
    Scenario Outline: Age restricted item with the manager_override flag displays an age verification frame without the
                      keyboard and a Manual entry button on scan (pos option 1010 set to 1)
        # "Age verification" option set to "By birthdate"
        Given the POS option 1010 is set to 1
        And the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then the POS displays restricted Age verification frame
        And the instant verification button is not displayed on the current frame
        And the manual entry keyboard is not displayed on the current frame
        And the Manual entry button is displayed on the current frame

        Examples:
        | barcode      |
        | 987654321    |


    @fast
    Scenario Outline: Manager signs in using his PIN, a regular age verification frame with keyboard and instant approval button is displayed (pos option 1010 set to 1)
        # "Age verification" option set to "By birthdate"
        Given the POS option 1010 is set to 1
        And the POS is in a ready to sell state
        And the POS displays Manager override frame after scanning an item barcode <barcode>
        When the manager signs in using <PIN> PIN
        Then the POS displays the Age verification frame
        And the Manual entry button is not displayed on the current frame

        Examples:
        | barcode      | PIN  |
        | 987654321    | 2345 |


    @fast
    Scenario Outline: Age restricted item with the manager_override flag displays an age verification frame without the
                      keyboard and a Manual entry button on scan (pos option 1010 set to 0)
        # "Age verification" option set to "Prompt for Yes/No"
        Given the POS option 1010 is set to 0
        And the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then the POS displays restricted Age verification frame
        And the instant verification button is not displayed on the current frame
        And the manual entry keyboard is not displayed on the current frame
        And the Manual entry button is displayed on the current frame

        Examples:
        | barcode      |
        | 987654321    |


    @fast
    Scenario Outline: Manager signs in using his PIN, a regular age verification frame with keyboard and instant approval button is displayed (pos option 1010 set to 0)
        # "Age verification" option set to "Prompt for Yes/No"
        Given the POS option 1010 is set to 0
        And the POS is in a ready to sell state
        And the POS displays Manager override frame after scanning an item barcode <barcode>
        When the manager signs in using <PIN> PIN
        Then the POS displays the Age verification frame
        And the Manual entry button is not displayed on the current frame

        Examples:
        | barcode      | PIN  |
        | 987654321    | 2345 |