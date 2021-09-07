@pos @pes
Feature: Promotion Execution Service - get on subtotal
    This feature file focuses on PES discounts received only while subtotalling the transaction. Adding items without attempt of tendering the transaction,
    will not add PES discounts in the transaction.

    Background: POS is configured for PES feature
        Given the POS has essential configuration
        And the EPS simulator has essential configuration
        And the POS is configured to communicate with PES
        # Cloud Loyalty Interface is set to PES
        And the POS option 5284 is set to 1
        And the nep-server has default configuration
        # Default Loyalty Discount Id is set to PES_basic
        And the POS parameter 120 is set to PES_basic
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        And the POS option 5277 is set to 1
        And the POS has following discounts configured
            | reduction_id | description | price | external_id |
            | 1            | PES loyalty | 0.00  | PES_basic   |
        And the pricebook contains retail items
            | description   | price | item_id | barcode | credit_category | category_code |
            | Large Fries   | 2.19  | 111     | 001     | 2010            | 400           |
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id                   | unit_type              | is_apply_as_tender |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise        | SIMPLE_QUANTITY        | False              |


    @fast
    Scenario Outline: Add an item to the transaction, the POS does not send a GetPromotion request, the PES discount does not appear in the VR.
        Given the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then the POS does not send an item with name <item_name> to PES
        And a loyalty discount <discount_description> with value of <discount_value> is not in the virtual receipt
        And a loyalty discount <discount_description> with value of <discount_value> is not in the current transaction

        Examples:
        | barcode | discount_description | discount_value |
        | 001     | Miscellaneous        | 0.30           |


    @fast
    Scenario Outline: Change the quantity of the items in the transaction, no PES discounts appear on the VR.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And a loyalty discount <discount_description> with value of <discount_value1> is not present in the transaction
        When the cashier updates quantity of the item <item_name> to <quantity>
        Then a loyalty discount <discount_description> with value of <discount_value2> is not in the virtual receipt
        And a loyalty discount <discount_description> with value of <discount_value2> is not in the current transaction

        Examples:
        | barcode | item_name   | quantity | discount_description | discount_value1 | discount_value2 |
        | 001     | Large Fries | 2        | Miscellaneous        | 0.30            | 0.60            |


    @fast
    Scenario Outline: Select a tender button to total the transaction, PES discounts appear in the VR.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And a loyalty discount <discount_description> with value of <discount_value> is not present in the transaction
        When the cashier totals the transaction using cash tender
        Then the POS applies PES discounts
        And a loyalty discount <discount_description> with value of <discount_value> is in the virtual receipt
        And a loyalty discount <discount_description> with value of <discount_value> is in the current transaction

        Examples:
        | barcode | tender_type | discount_description | discount_value |
        | 001     | cash        | Miscellaneous        | 0.30           |
        | 001     | credit      | Miscellaneous        | 0.30           |


    @fast
    Scenario Outline: Press Go back on tender frame, after a PES discount is received, the main frame is displayed.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction 2 times
        And the POS displays Ask tender amount cash frame
        When the cashier presses Go back button
        Then the POS displays main menu frame
        And a loyalty discount <discount_description> with value of <discount_value> and quantity <quantity> is in the virtual receipt
        And a loyalty discount <discount_description> with value of <discount_value> and quantity <quantity> is in the current transaction

        Examples:
        | barcode | discount_description | discount_value | quantity |
        | 001     | Miscellaneous        | 0.60           | 2        |


    @fast
    Scenario Outline: Add an item after the PES discount was added to the transaction after subtotal, select tender button,
                      the discount quantity is updated in the transaction.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction 2 times
        And a loyalty discount <discount_description> with value of <discount_value> is present in the transaction after subtotal
        And an item with barcode <barcode> is present in the transaction
        When the cashier totals the transaction using cash tender
        Then a loyalty discount <discount_description> with value of <new_discount_value> and quantity <quantity> is in the virtual receipt
        And a loyalty discount <discount_description> with value of <new_discount_value> and quantity <quantity> is in the current transaction

        Examples:
        | barcode | discount_description | discount_value | new_discount_value | quantity |
        | 001     | Miscellaneous        | 0.60           | 0.90               | 3        |


    @fast
    Scenario Outline: Void an item after the PES discount was added to the transaction after subtotal, select tender button,
                      the discount quantity is updated after the item was removed.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction 2 times
        And a loyalty discount <discount_description> with value of <discount_value> is present in the transaction after subtotal
        And the cashier voided the Large Fries
        When the cashier totals the transaction using cash tender
        Then a loyalty discount <discount_description> with value of <new_discount_value> and quantity <quantity> is in the virtual receipt
        And a loyalty discount <discount_description> with value of <new_discount_value> and quantity <quantity> is in the current transaction

        Examples:
        | barcode | discount_description | discount_value | new_discount_value | quantity |
        | 001     | Miscellaneous        | 0.60           | 0.30               | 1        |


    @fast
    Scenario Outline: Update an item's quantity with PES discount, perform another subtotal by selecting the cash tender,
                      the discount amount gets updated.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction 2 times
        And a loyalty discount <discount_description> with value of <discount_value> is present in the transaction after subtotal
        And an item Large Fries with price 4.38 has changed quantity to 5
        When the cashier totals the transaction using cash tender
        Then a loyalty discount <discount_description> with value of <new_discount_value> and quantity <quantity> is in the virtual receipt
        And a loyalty discount <discount_description> with value of <new_discount_value> and quantity <quantity> is in the current transaction

        Examples:
        | barcode| discount_description | discount_value | new_discount_value | quantity |
        | 001    | Miscellaneous        | 0.60           | 1.50               | 5        |
