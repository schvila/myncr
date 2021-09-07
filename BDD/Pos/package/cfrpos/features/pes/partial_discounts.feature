@pos @pes
Feature: Promotion Execution Service - partial discounts
    This feature file focuses on PES partial discounts.

    Background: POS is configured for PES feature
        Given the POS has essential configuration
        And the POS is configured to communicate with PES
        # Cloud Loyalty Interface is set to PES
        And the POS option 5284 is set to 1
        And the nep-server has default configuration
        # Default Loyalty Discount Id is set to PES_basic
        And the POS parameter 120 is set to PES_basic
        # Promotion Execution Service Allow partial discounts is set to Yes
        And the POS option 5278 is set to 1
        And the POS has following discounts configured
            | reduction_id | description | price | external_id |
            | 1            | PES loyalty | 0.00  | PES_basic   |
        And the pricebook contains retail items
            | description   | price | item_id | barcode | credit_category | category_code |
            | Banana        | 5.00  | 842424  | 842     | 2010            | 400           |
            | Carwash       | 3.33  | 666     | 006     | 1000            | 102           |
            | Refresher     | 0.55  | 777     | 007     | 1400            | 100           |
            | Carwash Extra | 20.25 | 999     | 009     | 1000            | 102           |
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id                   | unit_type              |
            | 400            | Banana for free      | 5.99           | item           | banana free combo              | SIMPLE_QUANTITY        |
            | 102            | Carwash (102)        | 10.25          | item           | 10.25 off carwash items        | SIMPLE_QUANTITY        |
            | 102, 100       | Car+Refresher        | 0.63           | transaction    | 20.45 off a combo              | SIMPLE_QUANTITY        |


    @fast @positive
    Scenario Outline: POS applies partial PES discounts after adding a single item to the transaction.
        Given the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then the POS applies PES discounts
        And a loyalty discount <discount_description> with value of <discount> is in the virtual receipt
        And a loyalty discount <discount_description> with value of <discount> is in the current transaction
        And the transaction's subtotal is <subtotal>

        Examples:
        | barcode | discount_description | discount | subtotal |
        | 842     | Banana for free      | 5.00     | 0.00     |


    @fast
    Scenario Outline: The partial discounts are updated after changing a quantity of the item.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And a loyalty discount <discount_description> with value of <discount> is present in the transaction
        When the cashier updates quantity of the item Banana to 3
        Then the POS applies PES discounts
        And a loyalty discount <discount_description> with value of <new_discount> is in the virtual receipt
        And a loyalty discount <discount_description> with value of <new_discount> is in the current transaction
        And the transaction's subtotal is <subtotal>

        Examples:
        | barcode | discount_description | discount | new_discount | subtotal |
        | 842     | Banana for free      | 5.00     | 15.0         | 0.00     |


    @fast
    Scenario Outline: Override an item price to the lower value, the item discount is decreased according to the item price change.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        When the cashier overrides price of item <item_name> to <new_price>
        Then an item <item_name> with price <new_price> is in the virtual receipt
        And an item <item_name> with price <new_price> is in the current transaction
        And a loyalty discount <discount> with value of <discount_value> and quantity 1 is in the virtual receipt
        And a loyalty discount <discount> with value of <discount_value> is in the current transaction
        And the transaction's subtotal is <subtotal>

        Examples:
        | barcode | item_name     | new_price | discount        | discount_value | subtotal |
        | 842     | Banana        | 3.50      | Banana for free | 3.50           | 0.0      |
        | 009     | Carwash Extra | 10.0      | Carwash (102)   | 10.0           | 0.0      |


    @fast
    Scenario Outline: Add an item to the transaction, after the single item with partial discount was added,
                      two discounts appear in VR, item discount and transaction discount.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode_1> is present in the transaction
        When the cashier scans a barcode <barcode_2>
        Then the POS applies PES discounts
        And a loyalty discount <discount_description_1> with value of <discount_value_1> is in the virtual receipt
        And a loyalty discount <discount_description_1> with value of <discount_value_1> is in the current transaction
        And a loyalty discount <discount_description_2> with value of <discount_value_2> is in the virtual receipt
        And a loyalty discount <discount_description_2> with value of <discount_value_2> is in the current transaction
        And the transaction's subtotal is <subtotal>

        Examples:
        | barcode_1 | barcode_2 | discount_description_1 | discount_value_1 | discount_description_2 | discount_value_2  | subtotal |
        | 007       | 006       | Carwash (102)          | 3.33             | Car+Refresher          | 0.55              | 0.00     |
        | 007       | 009       | Carwash (102)          | 10.25            | Car+Refresher          | 0.63              | 9.92     |


    @fast
    Scenario Outline: Partial discounts are disabled. Override an item price to higher value than the discount.
                      Check that the discount was added to the transaction.
        # Promotion Execution Service Allow partial discounts is set to No
        Given the POS option 5278 is set to 0
        And the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        When the cashier overrides price of item <item_name> to <new_price>
        Then an item <item_name> with price <new_price> is in the virtual receipt
        And an item <item_name> with price <new_price> is in the current transaction
        And a loyalty discount <discount> with value of <discount_value> and quantity 1 is in the virtual receipt
        And a loyalty discount <discount> with value of <discount_value> is in the current transaction
        And the transaction's subtotal is <subtotal>

        Examples:
        | barcode | item_name     | new_price | discount        | discount_value | subtotal |
        | 842     | Banana        | 6.00      | Banana for free | 5.99           | 0.01     |


    @fast @negative
    Scenario Outline: Partial discounts are disabled. Single item is added to the transaction and
                      the POS does not apply any PES discounts.
        # Promotion Execution Service Allow partial discounts is set to No
        Given the POS option 5278 is set to 0
        And the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then the POS applies PES discounts
        And a loyalty discount <discount_description> with value of <discount> is not in the virtual receipt
        And a loyalty discount <discount_description> with value of <discount> is not in the current transaction
        And the transaction's subtotal is <subtotal>

        Examples:
        | barcode | discount_description | discount | subtotal |
        | 842     | Banana for free      | 5.99     | 5.00     |

