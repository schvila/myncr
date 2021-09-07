@pos @ulp
Feature: Unified Loyalty and Promotions - item level discounts
    This feature file focuses on ULP item level discounts. If discount description is not provided, 
    the discount will have a default name "PES loyalty".

    Background: POS is configured for ULP feature
        Given the POS has essential configuration
        And the POS is configured to communicate with PES
        # Cloud Loyalty Interface is set to ULP
        And the POS option 5284 is set to 0
        And the nep-server has default configuration
        # Default Loyalty Discount Id is set to PES_basic
        And the POS parameter 120 is set to PES_basic
        # Promotion Execution Service Get Mode is set to ULP Get After Subtotal
        Given the POS option 5277 is set to 1
        And the POS has following discounts configured
            | reduction_id | description | price | external_id |
            | 1            | PES loyalty | 0.00  | PES_basic   |
        And the pricebook contains retail items
            | description | price | item_id | barcode | credit_category | category_code |
            | Large Fries | 2.19  | 111     | 001     | 2010            | 400           |
            | Coca Cola   | 2.39  | 222     | 002     | 2018            | 421           |
            | Chips       | 2.49  | 333     | 003     | 2021            | 441           |
        And the ULP loyalty host simulator has following combo discounts configured
            | promotion_id | discount_value | item_codes  | discount_level | unit_type       |
            | 30_cents_off | 0.30           | 001;002;003 | item           | SIMPLE_QUANTITY |
        And the ULP simulator has following referenced promotions configured
            | promotion_id | description            |
            | 30_cents_off | Referenced Description |


    @fast
    Scenario Outline: Add a single item providing a ULP discount in the transaction, ULP discount appears in the VR.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        When the cashier presses the cash tender button
        Then the POS applies ULP discounts
        And a loyalty discount <discount_description> with value of <discount_value> is in the virtual receipt
        And a loyalty discount <discount_description> with value of <discount_value> is in the current transaction
        And the transaction's subtotal is <subtotal>

        Examples:
            | barcode | discount_description   | discount_value | subtotal |
            | 001     | Referenced Description | 0.30           | 1.89     |


    @fast
    Scenario Outline: Configure ULP discount to need two different items in the transaction to be applied. Add just one of the needed items,
                      ULP discount does not appear in the VR.
        Given the POS is in a ready to sell state
        And the ULP loyalty host simulator has following combo discounts configured
            | promotion_id | discount_value | item_codes        | discount_level | unit_type       |
            | 50_cents_off | 0.50           | 099999999990, 001 | item           | SIMPLE_QUANTITY |
        And the ULP simulator has following referenced promotions configured
            | promotion_id | description  |
            | 50_cents_off | ULP discount |
        And an item with barcode <barcode> is present in the transaction
        When the cashier presses the cash tender button
        Then a loyalty discount <discount_description> with value of <discount_value> is not in the virtual receipt
        And a loyalty discount <discount_description> with value of <discount_value> is not in the current transaction

        Examples:
        | barcode      | discount_description | discount_value |
        | 099999999990 | ULP discount         | 0.50           |


    @fast
    Scenario Outline: Change the quantity of the item providing a ULP discount, the discount quantity is updated as well.
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And a loyalty discount <discount_description> with value of <discount_value_1> is present in the transaction after subtotal
        And an item Large Fries with price 2.19 has changed quantity to <quantity>
        When the cashier presses the cash tender button
        Then a loyalty discount <discount_description> with value of <discount_value_2> and quantity <quantity> is in the virtual receipt
        And a loyalty discount <discount_description> with value of <discount_value_2> and quantity <quantity> is in the current transaction

        Examples:
        | quantity | discount_description   | discount_value_1 | discount_value_2 |
        | 2        | Referenced Description | 0.30             | 0.60             |
        | 4        | Referenced Description | 0.30             | 1.20             |


    @fast
    Scenario Outline: Void an item with ULP discount, the discount is not present in the transaction.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And a loyalty discount <discount_description> with value of <discount_value> is present in the transaction after subtotal
        When the cashier voids the <item_description> with price <amount>
        Then an item <item_description> with price <amount> is not in the virtual receipt
        And an item <item_description> with price <amount> is not in the current transaction
        And a loyalty discount <discount_description> with value of <discount_value> is not in the virtual receipt
        And a loyalty discount <discount_description> with value of <discount_value> is not in the current transaction

        Examples:
        | barcode | item_description | discount_description   | amount | discount_value |
        | 001     | Large Fries      | Referenced Description | 2.19   | 0.30           |


    @fast
    Scenario Outline: Void the ULP discount from the transaction, received after an item was added,
                      the discount is removed from the transaction.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And a loyalty discount <discount_description> with value of <discount_value> is present in the transaction after subtotal
        When the cashier voids the <discount_description> with price <discount_price>
        Then a loyalty discount <discount_description> with value of <discount_value> is not in the virtual receipt
        And a loyalty discount <discount_description> with value of <discount_value> is not in the current transaction

        Examples:
        | barcode| discount_description   | discount_value | discount_price |
        | 001    | Referenced Description | 0.30           | -0.30          |


    @fast
    Scenario Outline: Void the ULP discount from the transaction, add few more items, validate that the voided discount is resent and present
                      in the transaction after second subtotal together with the discounts for additionaly added items.
        # There is discrepancy in this scenario compared to the behavior with host. Host will in this case return
        # only first discount that was voided, and it will not return the discounts for additionaly added items.
        Given the POS is in a ready to sell state
        And the ULP loyalty host simulator has following combo discounts configured
            | promotion_id | discount_value | item_codes   | discount_level | unit_type       |
            | 30_cents_off | 0.30           | 001          | item           | SIMPLE_QUANTITY |
            | 50_cents_off | 0.50           | 099999999990 | item           | SIMPLE_QUANTITY |
        And the ULP simulator has following referenced promotions configured
            | promotion_id | description    |
            | 30_cents_off | ULP discount 1 |
            | 50_cents_off | ULP discount 2 |
        And an item with barcode <barcode_1> is present in the transaction
        And a loyalty discount <discount_description_1> with value of <discount_value_1> is present in the transaction after subtotal
        And the cashier voided the <discount_description_1> with price <discount_price_1>
        And an item with barcode <barcode_2> is present in the transaction 2 times
        When the cashier presses the cash tender button
        Then a loyalty discount <discount_description_1> with value of <discount_value_1> and quantity <quantity_1> is in the virtual receipt
        And a loyalty discount <discount_description_1> with value of <discount_value_1> and quantity <quantity_1> is in the current transaction
        And a loyalty discount <discount_description_2> with value of <discount_value_2> and quantity <quantity_2> is in the virtual receipt
        And a loyalty discount <discount_description_2> with value of <discount_value_2> and quantity <quantity_2> is in the current transaction

        Examples:
        | barcode_1 | barcode_2    | discount_description_1 | discount_value_1 | discount_price_1 | quantity_1 |discount_description_2 | discount_value_2 | quantity_2 |
        | 001       | 099999999990 | ULP discount 1         | 0.30             | -0.30            | 1          | ULP discount 2        | 1.00             | 2          |


    @fast
    Scenario Outline: Configure ULP discount with higher value than item price. Add item to the transaction,
                      ULP discount does not appear in the VR.
        Given the POS is in a ready to sell state
        And the ULP loyalty host simulator has following combo discounts configured
            | promotion_id | discount_value | item_codes   | discount_level | unit_type       |
            | 50_cents_off | 2.00           | 099999999990 | item           | SIMPLE_QUANTITY |
        And the ULP simulator has following referenced promotions configured
            | promotion_id | description  |
            | 50_cents_off | ULP discount |
        And an item with barcode <barcode> is present in the transaction
        When the cashier presses the cash tender button
        Then a loyalty discount <discount_description> with value of <discount_value> is not in the virtual receipt
        And a loyalty discount <discount_description> with value of <discount_value> is not in the current transaction

        Examples:
        | barcode      | discount_description | discount_value |
        | 099999999990 | ULP discount         | 2.00           |