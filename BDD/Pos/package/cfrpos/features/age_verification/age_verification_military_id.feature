@pos
Feature: Age verification - Military ID
    This feature file focuses on a portion of age verification, where military ID holders can have lowered age
    restriction levels for some items.

    Background: POS is properly configured for Age verification feature
        Given the POS has essential configuration
        # "Age verification" option set to "By birthdate or license swipe"
        And the POS option 1010 is set to 2
        # "Age verification failure tracking" option set to "NO"
        And the POS option 1024 is set to 0
        And the pricebook contains retail items
            | description        | price  | age_restriction | barcode      | item_id      | modifier1_id | military_age_restriction |
            | Age 21 Restricted  | 4.69   | 21              | 022222222220 | 990000000009 | 990000000007 | 0                        |
            | Military ID lower  | 4.44   | 21              | 0123454321   | 0123454321   | 0            | 18                       |
            | Military ID equal  | 5.55   | 18              | 1234565432   | 1234565432   | 0            | 18                       |
            | Military ID higher | 6.66   | 18              | 2345676543   | 2345676543   | 0            | 21                       |


    @fast
    Scenario Outline: Age restricted item with or without the military_age_restriction level displays a generic age
                      verification frame with the military ID button displayed on scan when at least one item in the
                      pricebook has the military_age_restriction level set
        Given the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then the POS displays the Age verification frame
        And the Military ID button is displayed on the current frame

        Examples:
        | barcode      |
        | 022222222220 |
        | 0123454321   |
        | 1234565432   |


    @fast
    Scenario Outline: Enter an age above the age_restriction level for an age restricted item with the military_age_restriction and
                      confirm with the military ID button, item gets added to the transaction
        Given the POS is in a ready to sell state
        And the POS displays Age verification frame after scanning an item barcode <barcode>
        When the cashier manually enters the <years>yo customer's birthday and confirms with military id button
        Then the POS displays main menu frame
        And an item <description> with price <price> is in the current transaction
        And an item <description> with price <price> is in the virtual receipt

        Examples:
        | barcode      | description        | price | years |
        | 022222222220 | Age 21 Restricted  | 4.69  | 25    |
        | 0123454321   | Military ID lower  | 4.44  | 30    |
        | 1234565432   | Military ID equal  | 5.55  | 35    |
        | 2345676543   | Military ID higher | 6.66  | 40    |
        | 0123454321   | Military ID lower  | 4.44  | 20    |


    @fast
    Scenario Outline: Enter an age equal to the age_restriction level for an age restricted item with the military_age_restriction and
                      confirm with the military ID button, item gets added to the transaction
        Given the POS is in a ready to sell state
        And the POS displays Age verification frame after scanning an item barcode <barcode>
        When the cashier manually enters the <years>yo customer's birthday and confirms with military id button
        Then the POS displays main menu frame
        And an item <description> with price <price> is in the current transaction
        And an item <description> with price <price> is in the virtual receipt

        Examples:
        | barcode      | description        | price | years |
        | 022222222220 | Age 21 Restricted  | 4.69  | 21    |
        | 0123454321   | Military ID lower  | 4.44  | 18    |
        | 1234565432   | Military ID equal  | 5.55  | 18    |
        | 2345676543   | Military ID higher | 6.66  | 21    |


    @fast
    Scenario Outline: Enter an age below the age_restriction level for an age restricted item with the military_age_restriction and
                      confirm with the military ID button, Age requirements not met error is displayed
        Given the POS is in a ready to sell state
        And the POS displays Age verification frame after scanning an item barcode <barcode>
        When the cashier manually enters the <years>yo customer's birthday and confirms with military id button
        Then the POS displays an Error frame saying Customer does not meet age requirement
        And an item <description> with price <price> is not in the virtual receipt
        And an item <description> with price <price> is not in the current transaction

        Examples:
        | barcode      | description        | price | years |
        | 022222222220 | Age 21 Restricted  | 4.69  | 16    |
        | 0123454321   | Military ID lower  | 4.44  | 16    |
        | 1234565432   | Military ID equal  | 5.55  | 16    |
        | 2345676543   | Military ID higher | 6.66  | 20    |


    @fast
    Scenario Outline: Recall a transaction with an item with military_age_restriction level into a transaction with already
                      approved age restricted item, verified age is enough for the military restriction but not the regular one
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode1> is present in the transaction after instant approval age verification
        And the cashier stored the transaction
        And an age restricted item with barcode <barcode2> is present in the transaction after military ID age verification of 19 years
        When the cashier recalls the last stored transaction
        Then the POS displays main menu frame
        And an item <description1> with price <price1> is in the current transaction
        And an item <description1> with price <price1> is in the virtual receipt
        And an item <description2> with price <price2> is in the current transaction
        And an item <description2> with price <price2> is in the virtual receipt

        Examples:
        | barcode1   | barcode2     | description1      | description2      | price1 | price2 |
        | 0123454321 | 1234565432   | Military ID lower | Military ID equal | 4.44   | 5.55   |


    @fast
    Scenario Outline: Age restricted item with or without the military_age_restriction level set displays a manual age
                      verification frame with the military ID button displayed on scan (pos option 1010 set to 1)
        Given the POS option 1010 is set to 1
        And the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then the POS displays the Manual only Age verification frame with the instant approval button
        And the Military ID button is displayed on the current frame

        Examples:
        | barcode      |
        | 022222222220 |
        | 0123454321   |


    @fast
    Scenario Outline: Military ID age restriction level is ignored when Over/Under age verification method is used (pos option 1010 set to 0)
        Given the POS option 1010 is set to 0
        And the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then the POS displays Over/Under Age verification frame

        Examples:
        | barcode      |
        | 022222222220 |
        | 0123454321   |


    @fast
    Scenario Outline: Military ID button is not displayed when no item in the pricebook has a military_age_restriction set
        Given the POS has essential configuration
        And the pricebook contains retail items
            | description        | price  | age_restriction | barcode      | item_id      | modifier1_id |
            | Age 21 Restricted  | 4.69   | 21              | 022222222220 | 990000000009 | 990000000007 |
        And the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then the POS displays the Age verification frame
        And the Military ID button is not displayed on the current frame

        Examples:
        | barcode      |
        | 022222222220 |


    @positive @fast @pos_connect
    Scenario Outline: Send SellItem command to the POS for item with military_age_restriction, validate the DataNeeded Response, Age verification frame is displayed
	    Given the POS has the feature PosApiServer enabled
        And the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data contain |<response_data>|
        And the POS displays the Age verification frame

        Examples:
        | request                                     | response_data                             |
        | ["Pos/SellItem", {"Barcode": "1234565432"}] | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}, {"Name": "InstantApproval", "Text": "Over"}, {"Name": "MilitaryIdManualEntry", "Text": ""}], "DataType": "Date", "PromptId": 5072, "PromptText": "Enter Customer's Birthday (MM/DD/YYYY)"} |


    @positive @fast @pos_connect
    Scenario Outline: Send DataNeededResponse command to the POS with a valid birthday format after attempting to sell
                      an item with military_age_restriction, validate the response, item is added to the transaction
		Given the POS has the feature PosApiServer enabled
        And the POS is in a ready to sell state
        And the application sent |["Pos/SellItem", {"Barcode": "1234565432"}]| to the POS Connect
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|
        And the POS displays main menu frame
        And an item <item_description> with price <item_price> is in the current transaction

        Examples:
        | request                                                              													 | item_description  | item_price | response_data                             |
        | ["Pos/DataNeededResponse", {"DataType": "Date", "Date": "01012002", "SelectedOperationName": "MilitaryIdManualEntry"}] | Military ID equal | 5.55       | {"TransactionData": {"ItemList": [{"Description": "Military ID equal", "ExtendedPriceAmount": 5.55, "ItemNumber": 1, "POSItemId": 1234565432, "POSModifier1Id": 0, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "*": "*"}], "TransactionBalance": 5.94, "TransactionSubTotal": 5.55, "TransactionTaxAmount": 0.39, "TransactionTotal": 5.94}, "TransactionSequenceNumber": "*"}|
