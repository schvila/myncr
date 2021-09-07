@pos @pes
Feature: Promotion Execution Service - transaction level discounts
    This feature file focuses on PES transaction level discounts

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
            | Some Item     | 4.99  | 888     | 008     | 2007            | 410           |
            ###"retail items" with generic service credit category
            | Carwash       | 3.33  | 666     | 006     | 1000            | 102           |
            | Carwash Extra | 20.25 | 999     | 009     | 1000            | 102           |
        # Add configured 'PES_tender' loyalty tender record
        And the pricebook contains PES loyalty tender


    @fast
    Scenario Outline: The POS applies PES discount for transaction with subtotal over some amount.
        Given the nep-server provides a discount with value of 0.50 for transactions with value over 2.00
        And the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then a loyalty discount <discount_description> with value of <discount> is in the virtual receipt
        And a loyalty discount <discount_description> with value of <discount> is in the current transaction
        And the transaction's subtotal is <subtotal>

        Examples:
        | barcode | discount_description | discount | subtotal |
        | 008     | PES loyalty          | 0.50     | 4.49     |


    @fast
    Scenario: Mark a promotion to be/not to be applied as a tender. Verify the promotion is applied according to this setting.
        Given the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id      | unit_type       | is_apply_as_tender |
            | 102, 443       | Carwash+snack        | 10.00          | transaction    | 10.00 off a combo | SIMPLE_QUANTITY | True               |
            | 102, 421       | Carwash+drink        | 8.00           | transaction    | 8.00 off a combo  | SIMPLE_QUANTITY | True               |
            | 443, 421       | Snack+drink          | 3.00           | transaction    | 3.00 off a combo  | SIMPLE_QUANTITY | False              |
        And the POS is in a ready to sell state
        And an item with barcode 002 is present in the transaction
        And an item with barcode 004 is present in the transaction
        When the cashier scans a barcode 009
        Then the POS applies PES discounts
        And a tender Carwash+snack with amount 10.00 is in the virtual receipt
        And a tender Carwash+snack with amount 10.00 is in the current transaction
        And a tender Carwash+drink with amount 8.00 is in the virtual receipt
        And a tender Carwash+drink with amount 8.00 is in the current transaction
        And a loyalty discount Snack+drink with value of 3.00 is in the virtual receipt
        And a loyalty discount Snack+drink with value of 3.00 is in the current transaction


    @fast
    Scenario: The POS applies a promotion as a tender with default name PES_tender when no receipt text is provided.
        Given the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | unit_type       | is_apply_as_tender |
            | 400            |                      | 0.30           | transaction    | 30cents off merchandise | SIMPLE_QUANTITY | True               |
        And the POS is in a ready to sell state
        When the cashier scans a barcode 001
        Then the POS applies PES discounts
        And a tender PES_tender with amount 0.30 is in the virtual receipt
        And a tender PES_tender with amount 0.30 is in the current transaction


    @fast
    Scenario Outline: The POS applies a promotion as a tender. The promotion is described in VR according to its discount description in PES.
        Given the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id      | unit_type       | is_apply_as_tender |
            | 102, 443       | <disc_description>   | 10.00          | transaction    | 10.00 off a combo | SIMPLE_QUANTITY | True               |
        And the POS is in a ready to sell state
        And an item with barcode 004 is present in the transaction
        When the cashier scans a barcode 009
        Then the POS applies PES discounts
        And a tender <disc_description> with amount 10.00 is in the virtual receipt
        And a tender <disc_description> with amount 10.00 is in the current transaction

        Examples:
        | disc_description      |
        | Custom description    |


    @fast
    Scenario: The POS applies multiple loyalty tenders over the transaction tender limit.
        # Set the maximal number of tenders on transaction to 2
        Given the POS option 1215 is set to 2
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id      | unit_type       | is_apply_as_tender |
            | 102, 443       | Carwash+snack        | 10.00          | transaction    | 10.00 off a combo | SIMPLE_QUANTITY | True               |
            | 102, 421       | Carwash+drink        | 8.00           | transaction    | 8.00 off a combo  | SIMPLE_QUANTITY | True               |
            | 443, 421       | Snack+drink          | 3.00           | transaction    | 3.00 off a combo  | SIMPLE_QUANTITY | True               |
        And the POS is in a ready to sell state
        And an item with barcode 002 is present in the transaction
        And an item with barcode 004 is present in the transaction
        When the cashier scans a barcode 009
        Then the POS applies PES discounts
        And a tender Carwash+snack with amount 10.00 is in the virtual receipt
        And a tender Carwash+snack with amount 10.00 is in the current transaction
        And a tender Carwash+drink with amount 8.00 is in the virtual receipt
        And a tender Carwash+drink with amount 8.00 is in the current transaction
        And a tender Snack+drink with amount 3.00 is in the virtual receipt
        And a tender Snack+drink with amount 3.00 is in the current transaction


    @fast
    Scenario: The POS applies a promotion as a tender over transaction limit without finalizing the transaction.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id      | unit_type       | is_apply_as_tender |
            | 102, 443       | Carwash+snack        | 10.00          | transaction    | 10.00 off a combo | SIMPLE_QUANTITY | True               |
        And the POS is in a ready to sell state
        And an item with barcode 004 is present in the transaction
        When the cashier scans a barcode 006
        Then the POS applies PES discounts
        And a tender Carwash+snack with amount 8.58 is in the virtual receipt
        And a tender Carwash+snack with amount 8.58 is in the current transaction
        And the transaction's balance is 0.00


    @fast
    Scenario: The promotion has higher value than the transaction limit, partial discounts are not enabled,
              the promotion is not in the transaction and is not applied as a tender.
        # Promotion Execution Service Allow partial discounts is set to No
        Given the POS option 5278 is set to 0
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id      | unit_type       | is_apply_as_tender |
            | 102, 443       | Carwash+snack        | 10.00          | transaction    | 10.00 off a combo | SIMPLE_QUANTITY | True               |
        And the POS is in a ready to sell state
        And an item with barcode 004 is present in the transaction
        When the cashier scans a barcode 006
        Then a tender Carwash+snack with amount 8.58 is not in the virtual receipt
        And a tender Carwash+snack with amount 8.58 is not in the current transaction
