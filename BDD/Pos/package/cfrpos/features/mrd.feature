@pos @mrd
Feature: Machine Readable Discounts
    This feature file focuses on Machine Readable Discounts cards

    Background: POS is configured for MRD feature
        Given the POS has essential configuration
        And the POS recognizes following cards
            | card_definition_id | card_role  | card_name | barcode_range_from | card_definition_group_id |
            | 1                  | 1          | MRD card  | 00002255           | 70000000020              |
        And the POS recognizes MRD card role
        And the POS has the feature Loyalty enabled
        And the POS has following discounts configured
            | description     | price  | external_id | card_definition_group_id |
            | MRD             | 0.50   | 1           | 70000000020              |


    @fast
    Scenario Outline: MRD card is scanned, recognized and added to the transaction
        Given the POS is in a ready to sell state
        When the cashier scans a MRD card with barcode <barcode>
        Then a MRD trigger card <card_name> with value of 0.00 is in the virtual receipt
        And a MRD trigger card <card_name> with value of 0.00 is in the current transaction

        Examples:
        | barcode  | card_name |
        | 00002255 | MRD card  |


    @fast
    Scenario Outline: MRD card is scanned with dry stock in transaction, discount is awarded
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        When the cashier scans a MRD card with barcode <card_barcode>
        Then a MRD trigger card <card_name> with value of 0.00 is in the virtual receipt
        And a MRD trigger card <card_name> with value of 0.00 is in the current transaction
        And an item <item_name> with price <item_price> is in the virtual receipt
        And an item <item_name> with price <item_price> is in the current transaction
        And a triggered discount MRD with value of 0.50 is in the virtual receipt
        And a triggered discount MRD with value of 0.50 is in the current transaction

        Examples:
        | card_barcode | card_name | item_barcode | item_price | item_name   |
        | 00002255     | MRD card  | 099999999990 | 0.99       | Sale Item A |