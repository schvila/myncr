@pos @ulp
Feature: Unified Loyalty and Promotions - weighted items
    This feature focuses on discounts for weighted items

    Background: POS is configured for ULP weighted items feature
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
            | description  | price  | barcode | item_id       | weighted_item |
            | Banana       | 1.50   | 001     | 990000000009  | True          |
        And the ULP loyalty host simulator has following combo discounts configured
            | promotion_id        | discount_value | item_codes  | discount_level | unit_type |
            | 50_cents_per_lb_off | 0.50           | 001;002;003 | item           | POUNDS    |
        And the ULP simulator has following referenced promotions configured
            | promotion_id        | description            |
            | 50_cents_per_lb_off | Referenced Description |

    @fast @positive
    Scenario Outline: Add weighted items to transaction, ULP discount appears in the VR on subtotal.
        # Set weight units to kilograms (0) or pounds (1)
        Given the POS option 1578 is set to <pos_option_val>
        And the POS is in a ready to sell state
        And a weighted item with barcode <barcode> is present in the transaction with weight <weight>
        When the cashier presses the cash tender button
        Then the POS applies ULP discounts
        And a loyalty discount <discount_description> with value of <discount_value> is in the virtual receipt
        And a loyalty discount <discount_description> with value of <discount_value> is in the current transaction
        And the transaction's subtotal is <subtotal>

        Examples:
        | barcode | item_name   | UOM | price | weight  | pos_option_val | name         | discount_description   | discount_value | subtotal |
        | 001     | 0.90 Banana | lb  | 1.35  | 0.90    | 1              | wt item      | Referenced Description | 0.45           | 0.90     |
        | 001     | 0.90 Banana | kg  | 1.35  | 0.900   | 0              | wt item      | Referenced Description | 0.45           | 0.90     |
        