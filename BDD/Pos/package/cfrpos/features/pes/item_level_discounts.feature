@pos @pes
Feature: Promotion Execution Service - item level discounts
    This feature file focuses on PES item level discounts. If discount description is not provided, the discount will have a default name "PES loyalty".

    Background: POS is configured for PES feature
        Given the POS has essential configuration
        And the POS is configured to communicate with PES
        # Cloud Loyalty Interface is set to PES
        And the POS option 5284 is set to 1
        And the nep-server has default configuration
        # Default Loyalty Discount Id is set to PES_basic
        And the POS parameter 120 is set to PES_basic
        And the POS has following discounts configured
            | reduction_id | description | price | external_id |
            | 1            | PES loyalty | 0.00  | PES_basic   |
        And the pricebook contains retail items
            | description   | price | item_id | barcode | credit_category | category_code |
            | Large Fries   | 2.19  | 111     | 001     | 2010            | 400           |
            | Coca Cola     | 2.39  | 222     | 002     | 2018            | 421           |
            | Chips         | 2.49  | 333     | 003     | 2021            | 441           |
            | Snickers      | 4.69  | 444     | 004     | 2023            | 443           |
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id                  | unit_type       |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise       | SIMPLE_QUANTITY |
            | 421            | Soft drinks          | 0.26           | item           | 26cents off soft drinks       | SIMPLE_QUANTITY |
            | 441, 421       | Snacks + drink       | 0.42           | item           | 42cents off snack+drink combo | SIMPLE_QUANTITY |
            | 443            | Packed sweets        | 0.50           | transaction    | 50cents off snacks            | SIMPLE_QUANTITY |


    @fast
    Scenario Outline: Add a single item providing a PES discount in the transaction, PES discounts appear in the VR.
        Given the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then the POS applies PES discounts
        And a loyalty discount <discount_description> with value of <discount> is in the virtual receipt
        And a loyalty discount <discount_description> with value of <discount> is in the current transaction
        And the transaction's subtotal is <subtotal>

        Examples:
        | barcode | discount_description | discount | subtotal |
        | 001     | Miscellaneous        | 0.30     | 1.89     |


    @fast
    Scenario Outline: Swipe a PES loyalty card on pinpad, add a single item providing a PES discount in the transaction,
                      PES discounts and PES loyalty card appear in the VR.
        Given the POS recognizes following cards
            | card_definition_id | card_role  | card_name | barcode_range_from | card_definition_group_id | track_format_1 | track_format_2 | mask_mode |
            | 70000001142        | 3          | PES card  | 3104174102936582   | 70000010042              | bt%at?         | bt;at?         | 21        |
        And the POS is in a ready to sell state
        And a customer swiped a PES loyalty card with number <card_number> on pinpad
        When the cashier scans a barcode <barcode>
        Then the POS applies PES discounts
        And a loyalty discount <discount_description> with value of <discount> is in the virtual receipt
        And a loyalty discount <discount_description> with value of <discount> is in the current transaction
        And a card <card_name> with value of 0.00 is in the virtual receipt
        And a card <card_name> with value of 0.00 is in the current transaction
        And the POS sends a card with number <card_number> to PES with swipe entry method

        Examples:
        | barcode | discount_description | discount | card_name | card_number      |
        | 001     | Miscellaneous        | 0.30     | PES card  | 3104174102936582 |


    @fast
    Scenario Outline: Void an item with PES discount, the discount is not in the VR.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And a loyalty discount <discount_description> with value of <discount_value> is present in the transaction
        When the cashier voids the <item_description> with price <amount>
        Then an item <item_description> with price <amount> is not in the virtual receipt
        And an item <item_description> with price <amount> is not in the current transaction
        And a loyalty discount <discount_description> with value of <discount_value> is not in the virtual receipt
        And a loyalty discount <discount_description> with value of <discount_value> is not in the current transaction
        And the transaction's balance is 0.00

        Examples:
        | barcode | item_description | discount_description | amount | discount_value |
        | 001     | Large Fries      | Miscellaneous        | 2.19   | 0.30           |
        | 004     | Snickers         | Packed sweets        | 4.69   | 0.50           |


    @fast
    Scenario Outline: Void an item from the transaction, when two items and loyalty discount are in the transaction,
                      the discount is removed from the transaction after one of the items is voided.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode_1> is present in the transaction
        And an item with barcode <barcode_2> is present in the transaction
        And a loyalty discount <discount_description> with value of <discount_value> is present in the transaction
        When the cashier voids the <item_name> with price <item_price>
        Then an item <item_name> with price <item_price> is not in the virtual receipt
        And a loyalty discount <discount_description> with value of <discount_value> is not in the virtual receipt
        And a loyalty discount <discount_description> with value of <discount_value> is not in the current transaction

        Examples:
        | barcode_1 | barcode_2 | discount_description | discount_value | item_name   | item_price |
        | 002       | 003       | Snacks + drink       | 0.42           | Coca Cola   | 2.39       |
        | 002       | 003       | Snacks + drink       | 0.42           | Chips       | 2.49       |
        | 003       | 002       | Snacks + drink       | 0.42           | Coca Cola   | 2.39       |
        | 003       | 002       | Snacks + drink       | 0.42           | Chips       | 2.49       |


    @fast
    Scenario Outline: Void the PES discount from the transaction, received after an item was added,
                      the discount is removed from the transaction.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And a loyalty discount <discount_description> with value of <discount_value> is present in the transaction
        When the cashier voids the <discount_description> with price <discount_price>
        Then a loyalty discount <discount_description> with value of <discount_value> is not in the virtual receipt
        And a loyalty discount <discount_description> with value of <discount_value> is not in the current transaction

        Examples:
        | barcode| discount_description | discount_value | discount_price |
        | 001    | Miscellaneous        | 0.30           | -0.30          |


    @fast
    Scenario Outline: Void the PES discount from the transaction, add one more item,
                      only one discount is present in the transaction.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode_1> is present in the transaction
        And a loyalty discount <discount_description> with value of <discount_value> is present in the transaction
        And the cashier voided the <discount_description> with price <discount_price>
        When the cashier scans a barcode <barcode_2>
        Then a loyalty discount <discount_description> with value of <discount_value> is in the virtual receipt
        And a loyalty discount <discount_description> with value of <discount_value> is in the current transaction

        Examples:
        | barcode_1 | barcode_2 | discount_description | discount_value | discount_price |
        | 001       | 003       | Miscellaneous        | 0.30           | -0.30          |


    @fast
    Scenario Outline: Change the quantity of the item providing a PES discount, the discount quantity is updated as well.
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        When the cashier updates quantity of the item Large Fries to <quantity>
        Then a loyalty discount <discount_description> with value of <discount_value> and quantity <quantity> is in the virtual receipt
        And a loyalty discount <discount_description> with value of <discount_value> and quantity <quantity> is in the current transaction
        And the transaction's subtotal is <subtotal>

        Examples:
        | quantity | discount_description | discount_value | subtotal |
        | 2        | Miscellaneous        | 0.60           | 3.78     |
        | 4        | Miscellaneous        | 1.20           | 7.56     |


    @fast
    Scenario Outline: Add a single item providing a PES discount in the transaction, change the discount value, the PES discount is updated in the VR after receiving new value
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And a loyalty discount <discount_description> with value of <discount_value> is present in the transaction
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id                  |
            | 421            | Soft drinks          | 0.36           | item           | new disc soft drinks          |
            | 443            | Packed sweets        | 0.60           | transaction    | new disc Packed sweet snacks  |
        When the cashier scans a barcode 003
        Then a loyalty discount <discount_description> with value of <new_discount> is in the virtual receipt
        And a loyalty discount <discount_description> with value of <new_discount> is in the current transaction
        And the transaction's subtotal is <subtotal>

        Examples:
        | barcode | discount_description | discount_value | new_discount | subtotal |
        | 002     | Soft drinks          | 0.26           | 0.36         | 4.52     |
        | 004     | Packed sweets        | 0.50           | 0.60         | 6.58     |


    @fast
    Scenario Outline: POS applies a PES discount with the default name PES loyalty when no receipt text is provided.
        Given the POS is in a ready to sell state
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | unit_type       |
            | 400            |                      | 0.30           | item           | 30cents off merchandise | SIMPLE_QUANTITY |
        When the cashier scans a barcode <barcode>
        Then the POS applies PES discounts
        And a loyalty discount <discount_description> with value of <discount> is in the virtual receipt
        And a loyalty discount <discount_description> with value of <discount> is in the current transaction
        And the transaction's subtotal is <subtotal>

        Examples:
        | barcode | discount_description | discount | subtotal |
        | 001     | PES loyalty          | 0.30     | 1.89     |
