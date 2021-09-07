@pos @ulp
Feature: Unified Loyalty and Promotions - fuel postpay
    This feature file covers test cases with ULP FRP discounts for postpay.

    Background: POS is configured for ULP feature
        Given the POS has essential configuration
        # Promotion Execution Service Get Mode is set to Get After Subtotal
        And the POS option 5277 is set to 1
        # Cloud Loyalty Interface is set to ULP
        And the POS option 5284 is set to 0
        And the POS is configured to communicate with PES
        And the nep-server has default configuration
        # Default Loyalty Discount Id is set to ULP_basic
        And the POS parameter 120 is set to ULP_basic
        And the POS has following discounts configured
            | reduction_id | description | price | external_id |
            | 1            | ULP loyalty | 0.00  | ULP_basic   |
        And the POS recognizes following PES cards
            | card_definition_id | card_role | card_name | barcode_range_from | barcode_range_to | card_definition_group_id | track_format_1 | track_format_2 | mask_mode |
            | 70000001142        | 3         | ULP card  | 111222333000       | 3210321032103210 | 70000010042              | bt%at?         | bt;at?         | 21        |
        And the ULP loyalty host simulator has following combo discounts configured
            | item_codes | discount_value | discount_level | promotion_id | unit_type        | is_apply_as_tender |
            | fuel_004   | 0.50           | item           | 50_cents_fpr | GALLON_US_LIQUID | False              |
        And the ULP simulator has following referenced promotions configured
            | promotion_id | description | fuel_limit |
            | 50_cents_fpr | Premium FPR | 10.00      |


    @positive @fast
    Scenario Outline: FPR discount is added to transaction with postpay after pressing the tender button.
        Given the POS is in a ready to sell state
        And a <grade> postpay fuel with <fuel_price> price on pump 2 is present in the transaction
        And a PES loyalty card 111222333000 is present in the transaction
        When the cashier presses the cash tender button
        Then a fuel item <item_name> with price <fuel_price> and prefix P2 is in the virtual receipt
        And a fuel item <grade> with price <fuel_price> and volume <gallons> is in the current transaction
        And a loyalty discount <discount_name> with value of <discount_value> is in the virtual receipt
        And a loyalty discount <discount_name> with value of <discount_value> is in the current transaction

        Examples:
            | grade   | item_name      | fuel_price | gallons | discount_name | discount_value |
            | Premium | 2.500G Premium | 10.00      | 2.5     | Premium FPR   | 1.25           |
            | Premium | 5.000G Premium | 20.00      | 5.0     | Premium FPR   | 2.50           |


    @positive @fast
    Scenario Outline: Postpay FPR discount received from ULP is limited to 10 gallons.
        Given the POS is in a ready to sell state
        And a <grade> postpay fuel with <fuel_price> price on pump 2 is present in the transaction
        And a PES loyalty card 111222333000 is present in the transaction
        When the cashier presses the cash tender button
        Then a fuel item <item_name> with price <fuel_price> and prefix P2 is in the virtual receipt
        And a fuel item <grade> with price <fuel_price> and volume <gallons> is in the current transaction
        And a loyalty discount <discount_name> with value of <discount_value> is in the virtual receipt
        And a loyalty discount <discount_name> with value of <discount_value> is in the current transaction

        Examples:
            | grade   | item_name       | fuel_price | gallons | discount_name | discount_value |
            | Premium | 10.000G Premium | 40.00      | 10.0    | Premium FPR   | 5.00           |
            | Premium | 20.000G Premium | 80.00      | 20.0    | Premium FPR   | 5.00           |