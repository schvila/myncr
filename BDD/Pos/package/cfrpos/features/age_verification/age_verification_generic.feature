@pos
Feature: Age verification
    This feature file focuses on adding items with age verification required and different methods to confirm customer's age.
    Military ID, Effective date and similar enhancements to age verification are covered in separate feature files.

    Background: POS is properly configured for Age verification feature
        Given the POS has essential configuration
        # "Age verification" option set to "By birthdate or license swipe"
        And the POS option 1010 is set to 2
        # "Age verification failure tracking" option set to "NO"
        And the POS option 1024 is set to 0
        And the POS has following sale items configured
            | barcode      | description       | price  | external_id          | age restriction |
            | 022222222220 | Age 21 Restricted | 4.69   | ITT-022222222220-0-1 | 21              |
            | 0369369369   | Age 18 Restricted | 3.69   | ITT-0369369369-0-1   | 18              |


    @fast
    Scenario Outline: Adding an age restricted item results in displaying the age verification frame
        Given the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then a new transaction is started
        And the POS displays the Age verification frame

        Examples:
        | barcode      |
        | 022222222220 |


    @fast
    Scenario Outline: Providing a valid birth date over the verification limit by manual entry adds the item to the transaction
        Given the POS is in a ready to sell state
        And the POS displays Age verification frame after scanning an item barcode <barcode>
        When the cashier manually enters the customer's birthday <birthday>
        Then the POS displays main menu frame
        And an item <description> with price <price> is in the virtual receipt
        And an item <description> with price <price> is in the current transaction

        Examples:
        | barcode      | birthday    | description       | price |
        | 022222222220 | 08-29-1989  | Age 21 Restricted | 4.69  |
        | 0369369369   | 09-19-1999  | Age 18 Restricted | 3.69  |


    @fast
    Scenario Outline: Providing a valid birth date over the verification limit by swiping a DL adds the item to the transaction
        Given the POS is in a ready to sell state
        And the POS displays Age verification frame after scanning an item barcode <barcode>
        When the cashier swipes a driver's license valid DL
        Then the POS displays main menu frame
        And an item <description> with price <price> is in the virtual receipt
        And an item <description> with price <price> is in the current transaction

        Examples:
        | barcode      | description       | price |
        | 022222222220 | Age 21 Restricted | 4.69  |


    @fast
    Scenario Outline: Providing a valid birth date over the verification limit by scanning a DL adds the item to the transaction
        Given the POS is in a ready to sell state
        And the POS displays Age verification frame after scanning an item barcode <barcode>
        When the cashier scans a driver's license valid DL
        Then the POS displays main menu frame
        And an item <description> with price <price> is in the virtual receipt
        And an item <description> with price <price> is in the current transaction

        Examples:
        | barcode      | description       | price |
        | 022222222220 | Age 21 Restricted | 4.69  |


    @fast
    Scenario Outline: Providing a valid birth date over the verification limit by pressing the instant approval button
        Given the POS is in a ready to sell state
        And the POS displays Age verification frame after scanning an item barcode <barcode>
        When the cashier presses the instant approval button
        Then the POS displays main menu frame
        And an item <description> with price <price> is in the virtual receipt
        And an item <description> with price <price> is in the current transaction

        Examples:
        | barcode      | description       | price |
        | 022222222220 | Age 21 Restricted | 4.69  |


    @fast
    Scenario Outline: Providing an invalid birth date by manual entry does not add the item to the transaction and displays an error message
        Given the POS is in a ready to sell state
        And the POS displays Age verification frame after scanning an item barcode <barcode>
        When the cashier manually enters the customer's birthday <birthday>
        Then the POS displays an Error frame saying Input out of range
        And an item <description> with price <price> is not in the virtual receipt
        And an item <description> with price <price> is not in the current transaction

        Examples:
        | barcode      | birthday    | description       | price |
        | 022222222220 | 99-99-9999  | Age 21 Restricted | 4.69  |


    @fast
    Scenario Outline: Providing a valid birth date under the verification limit by manual entry does not add the item to the transaction and displays an error message
        Given the POS is in a ready to sell state
        And the POS displays Age verification frame after scanning an item barcode <barcode>
        When the cashier manually enters the customer's birthday <birthday>
        Then the POS displays an Error frame saying Customer does not meet age requirement
        And an item <description> with price <price> is not in the virtual receipt
        And an item <description> with price <price> is not in the current transaction

        Examples:
        | barcode      | birthday    | description       | price |
        | 022222222220 | 10-10-2015  | Age 21 Restricted | 4.69  |


    @fast
    Scenario Outline: Recall a transaction containing age restricted item
        Given the POS is in a ready to sell state
        And an age restricted item with barcode <barcode> is present in the transaction after instant approval age verification
        And the cashier stored the transaction
        When the cashier recalls the last stored transaction
        Then the POS displays the Age verification frame

        Examples:
        | barcode      |
        | 022222222220 |


    @fast
    Scenario Outline: Recall of a transaction with age restricted item into another transaction with age restricted item - customer does not meet age requirements
        Given the POS is in a ready to sell state
        And the cashier stored a transaction with age restricted item with barcode <barcode1>
        And an age restricted item with barcode <barcode2> is in the transaction after manual verification of <customer_age>yo customer
        When the cashier recalls the last stored transaction
        Then the POS displays an Error frame saying Customer does not meet age requirement
        And an item <description1> with price <price1> is not in the virtual receipt
        And an item <description1> with price <price1> is not in the current transaction
        And an item <description2> with price <price2> is in the virtual receipt
        And an item <description2> with price <price2> is in the current transaction

        Examples:
        | barcode1     | barcode2   | customer_age | description1       | price1 | description2      | price2 |
        | 022222222220 | 0369369369 | 19           | Age 21 Restricted  | 4.69   | Age 18 Restricted | 3.69   |


    @fast
    Scenario Outline: Recall a transaction with age restricted item into another transaction with age restricted item verified by instant approval button,
                      the item is added without prompting for another verification
        Given the POS is in a ready to sell state
        And the cashier stored a transaction with age restricted item with barcode <barcode1>
        And an age restricted item with barcode <barcode2> is present in the transaction after instant approval age verification
        When the cashier recalls the last stored transaction
        Then the POS displays main menu frame
        And an item <description1> with price <price1> is in the virtual receipt
        And an item <description1> with price <price1> is in the current transaction
        And an item <description2> with price <price2> is in the virtual receipt
        And an item <description2> with price <price2> is in the current transaction

        Examples:
        | barcode1     | barcode2   | description1       | price1 | description2      | price2 |
        | 022222222220 | 0369369369 | Age 21 Restricted  | 4.69   | Age 18 Restricted | 3.69   |


    @fast
    Scenario Outline: Setting Age verification pos option to Yes/No displays a different verification frame asking if the customer was born before or after a certain date
        # "Age verification" option set to "Prompt for Yes/No"
        Given the POS option 1010 is set to 0
        And the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then a new transaction is started
        And the POS displays Over/Under Age verification frame

        Examples:
        | barcode      |
        | 022222222220 |


    @fast
    Scenario Outline: Selecting that the customer was born before the date adds the item to the transaction
        # "Age verification" option set to "Prompt for Yes/No"
        Given the POS option 1010 is set to 0
        And the POS is in a ready to sell state
        And the POS displays Over/Under Age verification frame after scanning an item barcode <barcode>
        When the cashier presses the Over button
        Then the POS displays main menu frame
        And an item <description> with price <price> is in the virtual receipt
        And an item <description> with price <price> is in the current transaction

        Examples:
        | barcode      | description       | price |
        | 022222222220 | Age 21 Restricted | 4.69  |
        | 0369369369   | Age 18 Restricted | 3.69  |


    @fast
    Scenario Outline: Selecting that the customer was born after the date does not add the item to the transaction
        # "Age verification" option set to "Prompt for Yes/No"
        Given the POS option 1010 is set to 0
        And the POS is in a ready to sell state
        And the POS displays Over/Under Age verification frame after scanning an item barcode <barcode>
        When the cashier presses the Under button
        Then the POS displays main menu frame
        And an item <description> with price <price> is not in the virtual receipt
        And an item <description> with price <price> is not in the current transaction

        Examples:
        | barcode      | description       | price |
        | 022222222220 | Age 21 Restricted | 4.69  |
        | 0369369369   | Age 18 Restricted | 3.69  |


    @fast
    Scenario Outline: Attempting to add the same age restricted item a second time after the first one failed verification does not add the item to the transaction and displays an error
        # "Age verification" option set to "Prompt for Yes/No"
        Given the POS option 1010 is set to 0
        And the POS is in a ready to sell state
        And the customer failed Over/Under age verification after scanning an item barcode <barcode>
        When the cashier scans a barcode <barcode>
        Then the POS displays an Error frame saying Customer does not meet age requirement
        And an item <description> with price <price> is not in the virtual receipt
        And an item <description> with price <price> is not in the current transaction

        Examples:
        | barcode      | description       | price |
        | 022222222220 | Age 21 Restricted | 4.69  |
        | 0369369369   | Age 18 Restricted | 3.69  |


    @fast
    Scenario Outline: Attempting to add a less restricted item after the first one failed verification reprompts for age verification with the new required age
        # "Age verification" option set to "Prompt for Yes/No"
        Given the POS option 1010 is set to 0
        And the POS is in a ready to sell state
        And the customer failed Over/Under age verification after scanning an item barcode <more_restricted_barcode>
        When the cashier scans a barcode <less_restricted_barcode>
        Then the POS displays Over/Under Age verification frame

        Examples:
        | more_restricted_barcode | less_restricted_barcode |
        | 022222222220            | 0369369369              |


    @fast
    Scenario Outline: Attempting to add a more restricted item after the first one passed verification reprompts for age verification with the new required age
        # "Age verification" option set to "Prompt for Yes/No"
        Given the POS option 1010 is set to 0
        And the POS is in a ready to sell state
        And an age restricted item with barcode <less_restricted_barcode> is present in the transaction after Over/Under age verification
        When the cashier scans a barcode <more_restricted_barcode>
        Then the POS displays Over/Under Age verification frame

        Examples:
        | more_restricted_barcode | less_restricted_barcode |
        | 022222222220            | 0369369369              |


    @fast
    Scenario Outline: Attempting to add a more restricted item after the first one failed verification does not add the item to the transaction and displays an error
        # "Age verification" option set to "Prompt for Yes/No"
        Given the POS option 1010 is set to 0
        And the POS is in a ready to sell state
        And the customer failed Over/Under age verification after scanning an item barcode <less_restricted_barcode>
        When the cashier scans a barcode <more_restricted_barcode>
        Then the POS displays an Error frame saying Customer does not meet age requirement

        Examples:
        | more_restricted_barcode | less_restricted_barcode |
        | 022222222220            | 0369369369              |


    @fast
    Scenario Outline: Attempting to add a less restricted item after the first one passed verification adds the item into the transaction
        # "Age verification" option set to "Prompt for Yes/No"
        Given the POS option 1010 is set to 0
        And the POS is in a ready to sell state
        And an age restricted item with barcode <more_restricted_barcode> is present in the transaction after Over/Under age verification
        When the cashier scans a barcode <less_restricted_barcode>
        Then the POS displays main menu frame
        And an item <description1> with price <price1> is in the virtual receipt
        And an item <description1> with price <price1> is in the current transaction
        And an item <description2> with price <price2> is in the virtual receipt
        And an item <description2> with price <price2> is in the current transaction

        Examples:
        | more_restricted_barcode | less_restricted_barcode | description1      | price1 | description2      | price2 |
        | 022222222220            | 0369369369              | Age 21 Restricted | 4.69   | Age 18 Restricted | 3.69   |
