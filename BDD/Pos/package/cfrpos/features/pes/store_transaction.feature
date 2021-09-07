@pos @pes
Feature: Promotion Execution Service - store transaction
    This feature file focuses on tests covering store and recall functionality with PES cards and discounts in the transaction.
    The PES discounts and PES card are discarded when the transaction is stored, the same behavior as with sigma.

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
            | Snickers      | 4.69  | 444     | 004     | 2023            | 443           |
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id                   | unit_type              | is_apply_as_tender |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise        | SIMPLE_QUANTITY        | False              |
            | 421            | Soft drinks          | 0.40           | transaction    | 40cents as tender              | SIMPLE_QUANTITY        | True               |
            | 443            | Packed sweets        | 0.50           | transaction    | 50cents off snacks             | SIMPLE_QUANTITY        | False              |
        And the POS recognizes following PES cards
            | card_definition_id | card_role  | card_name | barcode_range_from | card_definition_group_id |
            | 70000001142        | 3          | PES card  | 3104174102936582   | 70000010042              |
        And the pricebook contains PES loyalty tender


    @fast
    Scenario Outline: The POS does not keep the promotions after storing transaction - triggered by adding an item to the transaction.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And a loyalty discount <discount_description> with value of <discount_value> is present in the transaction
        When the cashier stores the transaction
        Then the POS displays main menu frame
        And no transaction is in progress
        And a loyalty discount <discount_description> with value of <discount_value> is not in the previous transaction

        Examples:
        | barcode | discount_description | discount_value |
        | 001     | Miscellaneous        | 0.30           |
        | 004     | Packed sweets        | 0.50           |


    @fast
    Scenario: The POS does not keep the PES card after storing the transaction.
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And a PES loyalty card 3104174102936582 is present in the transaction
        When the cashier stores the transaction
        Then the POS displays main menu frame
        And no transaction is in progress
        And a card PES card with value of 0.00 is not in the previous transaction


    @fast
    Scenario Outline: The POS stores and recalls a transaction with a PES discount. The discount is reapplied automatically, PES card is not.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And a loyalty discount <discount_description> with value of <discount_value> is present in the transaction
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the cashier stored the transaction
        When the cashier recalls the last stored transaction
        Then the POS displays main menu frame
        And a loyalty discount <discount_description> with value of <discount_value> is in the current transaction
        And a card PES card with value of 0.00 is not in the current transaction

        Examples:
        | barcode | discount_description | discount_value |
        | 001     | Miscellaneous        | 0.30           |
        | 004     | Packed sweets        | 0.50           |


    @fast
    Scenario Outline: The POS does not keep the promotions after storing transaction - triggered by total.
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        Given the POS option 5277 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And the transaction is totaled
        And a loyalty discount <discount_description> with value of <discount_value> is present in the transaction
        When the cashier stores the transaction
        Then the POS displays main menu frame
        And no transaction is in progress
        And a loyalty discount <discount_description> with value of <discount_value> is not in the previous transaction

        Examples:
        | barcode | discount_description | discount_value |
        | 001     | Miscellaneous        | 0.30           |


    @fast
    Scenario Outline: The POS can store a transaction with a PES discount applied as a tender. The tender is removed in the
                      same way as any of the promotions after storing the transaction.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And a tender <discount_description> with amount <discount_value> is in the current transaction
        When the cashier stores the transaction
        Then the POS displays main menu frame
        And no transaction is in progress
        And a tender <discount_description> with amount <discount_value> is not in the previous transaction

        Examples:
        | barcode | discount_description | discount_value |
        | 002     | Soft drinks          | 0.40           |


    @fast
    Scenario Outline: The POS stores and recalls a transaction with a PES discount applied as a tender. The discount is
                      reapplied automatically (received again), PES card is not.
        # Allow transaction modification after loyalty authorization is set to Yes
        Given the POS option 5275 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the cashier stored the transaction
        When the cashier recalls the last stored transaction
        Then the POS displays main menu frame
        And a tender <discount_description> with amount <discount_value> is in the current transaction
        And a card PES card with value of 0.00 is not in the current transaction

        Examples:
        | barcode | discount_description | discount_value |
        | 002     | Soft drinks          | 0.40           |
