@pos @pes
Feature: Promotion Execution Service - delay discount
    This feature file focuses on PES delay discount. The POS should be waiting for the discount to be added in the trasnaction if the PES delay trap is not longer than 5 seconds.

    Background: POS is configured for PES feature
        Given the POS has essential configuration
        And the POS is configured to communicate with PES
        # Cloud Loyalty Interface is set to PES
        And the POS option 5284 is set to 1
        And the EPS simulator has essential configuration
        And the nep-server has default configuration
        # Default Loyalty Discount Id is set to PES_basic
        And the POS parameter 120 is set to PES_basic
        And the POS has following discounts configured
            | reduction_id | description | price | external_id |
            | 1            | PES loyalty | 0.00  | PES_basic   |
        And the pricebook contains retail items
            | description   | price | item_id | barcode | credit_category | category_code |
            | Coca Cola     | 2.39  | 222     | 002     | 2018            | 421           |
            | Chips         | 2.49  | 333     | 003     | 2021            | 441           |
            | Ice           | 0.99  | 555     | 005     | 2019            | 401           |
            ###"retail items" with generic service credit category
            | Refresher     | 0.55  | 777     | 007     | 1400            | 100           |
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id                   | unit_type              |
            | 441, 421       | Snacks + drink       | 0.42           | item           | 42cents off snack+drink combo  | SIMPLE_QUANTITY        |
            | 401, 100       | Ice+Refresher        | 0.65           | transaction    | 65cents off accsessories combo | SIMPLE_QUANTITY        |


    @fast
    Scenario Outline: The PES discount is delayed by less than 5 seconds, the POS waits for delayed GetPromotions response before tendering,
                      the discount is in the previous transaction.
        # The discounts are received if the delay trap is no longer than 2 seconds
        Given the POS is in a ready to sell state
        And the PES has <delay_time> seconds delay
        And an item with barcode <barcode_1> is present in the transaction
        And an item with barcode <barcode_2> is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in <tender_type>
        Then the POS displays main menu frame
        And no transaction is in progress
        And a loyalty discount <discount_description> with value of <discount_value> is in the previous transaction

        Examples:
        | barcode_1 | barcode_2 | discount_description | discount_value | tender_type | delay_time |
        | 002       | 003       | Snacks + drink       | 0.42           | cash        | 2          |
        | 002       | 003       | Snacks + drink       | 0.42           | credit      | 2          |
        | 005       | 007       | Ice+Refresher        | 0.65           | cash        | 2          |
        | 005       | 007       | Ice+Refresher        | 0.65           | credit      | 2          |


    @slow
    Scenario Outline: The PES discount is delayed by 5 seconds or more, the POS does not wait for responses on GetPromotions and continues the flow,
                      the discount is not in the previous transaction.
        Given the POS is in a ready to sell state
        And the PES has <delay_time> seconds delay
        And an item with barcode <barcode_1> is present in the transaction
        And an item with barcode <barcode_2> is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in <tender_type>
        Then the POS displays main menu frame
        And no transaction is in progress
        And a loyalty discount <discount_description> with value of <discount_value> is not in the previous transaction

        Examples:
        | barcode_1 | barcode_2 | discount_description | discount_value | tender_type | delay_time |
        | 002       | 003       | Snacks + drink       | 0.42           | cash        | 5          |
        | 002       | 003       | Snacks + drink       | 0.42           | credit      | 10         |
