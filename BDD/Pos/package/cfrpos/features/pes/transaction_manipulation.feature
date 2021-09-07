@pos @pes
Feature: Promotion Execution Service - voiding the PES loyalty card and changing a transaction after subtotal
    This feature tests transactions with PES loyalty card. The card can never be voided and the transaction
    cannot be changed after subtotal unless the POS option 5275 Allow transaction modification after loyalty
    authorization is set to Yes.

    Background: POS is configured for PES feature
        Given the POS has essential configuration
        And the POS has following sale items configured
            | barcode      | description | price |
            | 099999999990 | Sale Item A | 0.99  |
            | 088888888880 | Sale Item B | 1.99  |
        And the POS is configured to communicate with PES
        # Cloud Loyalty Interface is set to PES
        And the POS option 5284 is set to 1
        # Default Loyalty Discount Id is set to PES_basic
        And the POS parameter 120 is set to PES_basic
        And the POS has following discounts configured
            | reduction_id | description | price | external_id |
            | 1            | PES loyalty | 0.00  | PES_basic   |
        # Promotion Execution Service Send only loyalty transactions is set to Yes
        And the POS option 5279 is set to 1
        # Promotion Execution Service Allow partial discounts is set to Yes
        And the POS option 5278 is set to 1
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        And the POS option 5277 is set to 1
        And the POS has following discounts configured
            | reduction_id | description | price | external_id |
            | 1            | PES loyalty | 0.00  | PES_basic   |
        # Add configured 'PES_tender' loyalty tender record
        And the pricebook contains PES loyalty tender
        And the nep-server has default configuration
        And the POS recognizes following PES cards
            | card_definition_id | card_role | card_name | barcode_range_from | card_definition_group_id | track_format_1 | track_format_2 | mask_mode |
            | 70000001142        | 3         | PES card  | 3104174102936582   | 70000010042              | bt%at?         | bt;at?         | 21        |


    @fast @negative
    Scenario Outline: Attempt to void the PES loyalty card before subtotal, Cancel not allowed error frame is displayed and the card is not voided
        # Allow transaction modification after loyalty authorization is set to No/Yes
        Given the POS option 5275 is set to <pos_option_value>
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        When the cashier voids the PES card with price 0.00
        Then the POS displays Cancel not allowed for item error
        And an item PES card with price 0.00 is in the virtual receipt
        And a card PES card with value of 0.00 is in the current transaction

        Examples:
            | pos_option_value |
            | 0                |
            | 1                |


    @fast @negative
    Scenario Outline: Set POS option to not allow transaction modification after loyalty authorization,
                    attempt to void the PES loyalty card after subtotal, Not allowed after total error frame is displayed and the card is not voided
        # Allow transaction modification after loyalty authorization is set to No
        Given the POS option 5275 is set to 0
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the transaction is totaled
        When the cashier voids the PES card with price 0.00
        Then the POS displays Not allowed after total error
        And an item PES card with price 0.00 is in the virtual receipt
        And a card PES card with value of 0.00 is in the current transaction


    @fast @negative
    Scenario Outline: Set POS option to allow transaction modification after loyalty authorization,
                    attempt to void the PES loyalty card after subtotal, Cancel not allowed for item error frame is displayed and the card is not voided
        # Allow transaction modification after loyalty authorization is set to Yes
        Given the POS option 5275 is set to 1
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the transaction is totaled
        When the cashier voids the PES card with price 0.00
        Then the POS displays Cancel not allowed for item error
        And an item PES card with price 0.00 is in the virtual receipt
        And a card PES card with value of 0.00 is in the current transaction


    @fast @negative
    Scenario Outline: Set POS option to not allow transaction modification after loyalty authorization,
                    attempt to void an item/discount from the transaction after subtotal is performed,
                    Not allowed after total error frame is displayed and the item is not voided
        # Allow transaction modification after loyalty authorization is set to No
        Given the POS option 5275 is set to 0
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id  | unit_type       | is_apply_as_tender |
            | 400            | Misc item disc       | 0.10           | item           | promo1        | SIMPLE_QUANTITY | False              |
            | 400            | Misc tran disc       | 0.10           | transaction    | promo2        | SIMPLE_QUANTITY | False              |
            | 400            | Misc tran tender     | 0.10           | transaction    | promo3        | SIMPLE_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the transaction is totaled
        When the cashier voids the <item_name> with price <item_price>
        Then the POS displays Not allowed after total error
        And an item <item_name> with price <item_price> is in the virtual receipt
        And an item <item_name> with price <item_price> and type <item_type> is in the current transaction

        Examples:
            | item_name         | item_price | item_type |
            | Sale Item A       | 0.99       | 1         |
            | Misc item disc    | -0.10      | 29        |
            | Misc tran disc    | -0.10      | 29        |
            | Misc tran tender  | -0.10      | 6         |


    @fast @positive
    Scenario Outline: Set POS option to allow transaction modification after loyalty authorization,
                    attempt to void an item/discount from the transaction after subtotal is performed,
                    the item is voided
        # Allow transaction modification after loyalty authorization is set to Yes
        Given the POS option 5275 is set to 1
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id  | unit_type       | is_apply_as_tender |
            | 400            | Misc item disc       | 0.10           | item           | promo1        | SIMPLE_QUANTITY | False              |
            | 400            | Misc tran disc       | 0.10           | transaction    | promo2        | SIMPLE_QUANTITY | False              |
            | 400            | Misc tran tender     | 0.10           | transaction    | promo3        | SIMPLE_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the transaction is totaled
        When the cashier voids the <item_name> with price <item_price>
        Then the POS displays main menu frame
        And an item <item_name> with price <item_price> is not in the virtual receipt
        And an item <item_name> with price <item_price> and type <item_type> is not in the current transaction

        Examples:
            | item_name         | item_price | item_type |
            | Sale Item A       | 0.99       | 1         |
            | Misc item disc    | -0.10      | 29        |
            | Misc tran disc    | -0.10      | 29        |
            | Misc tran tender  | -0.10      | 6         |


    @fast @negative
    Scenario Outline: Set POS option to not allow transaction modification after loyalty authorization, attempt to scan an item to the transaction
                      after subtotal is performed and the POS displays Not allowed after total error.
        # Allow transaction modification after loyalty authorization is set to No
        Given the POS option 5275 is set to 0
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the transaction is totaled
        When the cashier scans a barcode <barcode>
        Then the POS displays Not allowed after total error
        And an item <description> with price <price> is not in the virtual receipt
        And an item <description> with price <price> is not in the current transaction

        Examples:
            | barcode      | description | price |
            | 088888888880 | Sale Item B | 1.99  |


    @fast @negative
    Scenario Outline: Set POS option to not allow transaction modification after loyalty authorization,
                      attempt to manually add an item to the transaction
                      after subtotal is performed and the POS displays Not allowed after total error.
        # Allow transaction modification after loyalty authorization is set to No
        Given the POS option 5275 is set to 0
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the transaction is totaled
        When the cashier manually adds an item with barcode <barcode> on the POS
        Then the POS displays Not allowed after total error
        And an item <description> with price <price> is not in the virtual receipt
        And an item <description> with price <price> is not in the current transaction

        Examples:
            | barcode      | description | price |
            | 088888888880 | Sale Item B | 1.99  |


    @fast @positive
    Scenario Outline: Set POS option to not allow transaction modification after loyalty authorization,
                    discount is successfully added to transaction when approved after subtotal
        # Allow transaction modification after loyalty authorization is set to No
        Given the POS option 5275 is set to 0
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description   | discount_value | discount_level   | promotion_id  | unit_type       | is_apply_as_tender   | approval_for         | approval_name   | approval_description      |
            | 400            | <discount_description> | 0.10           | <discount_level> | promo1        | SIMPLE_QUANTITY | <is_apply_as_tender> | CASHIER_AND_CONSUMER | Accept discount | Do you want the discount? |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the POS displays a PES discount approval frame after selecting a cash tender button
        When the cashier selects Yes button
        Then the POS displays main menu frame
        And a loyalty discount <discount_description> with value of 0.10 is in the virtual receipt
        And an item <discount_description> with price 0.10 and type <item_type> is not in the current transaction

        Examples:
            | discount_description | discount_level | is_apply_as_tender | item_type |
            | Misc item disc       | item           | False              | 29        |
            | Misc tran disc       | transaction    | False              | 29        |
            | Misc tran tender     | transaction    | True               | 6         |


    @fast @positive
    Scenario Outline: Set POS option to allow transaction modification after loyalty authorization, successfully scan an item to the transaction
                      after subtotal is performed and the item appears in the VR
        # Allow transaction modification after loyalty authorization is set to Yes
        Given the POS option 5275 is set to 1
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the transaction is totaled
        When the cashier scans a barcode <barcode>
        Then the POS displays main menu frame
        And an item <description> with price <price> is in the virtual receipt
        And an item <description> with price <price> is in the current transaction

        Examples:
            | barcode      | description | price |
            | 088888888880 | Sale Item B | 1.99  |


    @fast @positive
    Scenario Outline: Set POS option to allow transaction modification after loyalty authorization, successfully manually add an item to the transaction
                      after subtotal is performed and the item appears in the VR
        # Allow transaction modification after loyalty authorization is set to Yes
        Given the POS option 5275 is set to 1
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the transaction is totaled
        When the cashier manually adds an item with barcode <barcode> on the POS
        Then the POS displays main menu frame
        And an item <description> with price <price> is in the virtual receipt
        And an item <description> with price <price> is in the current transaction

        Examples:
            | barcode      | description | price |
            | 088888888880 | Sale Item B | 1.99  |


    @fast @negative
    Scenario Outline: Set POS option to not allow transaction modification after loyalty authorization, attempt to change quantity to an item
                      after subtotal is performed and the POS displays Not allowed after total error.
        # Allow transaction modification after loyalty authorization is set to No
        Given the POS option 5275 is set to 0
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id  | unit_type       | is_apply_as_tender |
            | 400            | Misc item disc       | 0.10           | item           | promo1        | SIMPLE_QUANTITY | False              |
            | 400            | Misc tran disc       | 0.10           | transaction    | promo2        | SIMPLE_QUANTITY | False              |
            | 400            | Misc tran tender     | 0.10           | transaction    | promo3        | SIMPLE_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the transaction is totaled
        When the cashier updates quantity of the item <item_name> to 2
        Then the POS displays Not allowed after total error
        And an item <item_name> with price <item_price> and quantity 1 is in the virtual receipt
        And an item <item_name> with price <item_price>, quantity 1 and type <item_type> is in the current transaction

        Examples:
            | item_name         | item_price | item_type |
            | Sale Item A       | 0.99       | 1         |
            | Misc item disc    | -0.10      | 29        |
            | Misc tran disc    | -0.10      | 29        |
            | Misc tran tender  | -0.10      | 6         |


    @fast @positive
    Scenario Outline: Set POS option to allow transaction modification after loyalty authorization, attempt to change quantity to an item
                      after subtotal is performed and the quantity of the item is updated
        # Allow transaction modification after loyalty authorization is set to Yes
        Given the POS option 5275 is set to 1
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the transaction is totaled
        When the cashier updates quantity of the item <item_name> to 2
        Then the POS displays main menu frame
        And an item <item_name> with price <item_price> and quantity 2 is in the virtual receipt
        And an item <item_name> with price <item_price> and quantity 2 is in the current transaction

        Examples:
            | item_name         | item_price | item_type |
            | Sale Item A       | 1.98       | 1         |


    @fast @negative
    Scenario Outline: Set POS option to not allow transaction modification after loyalty authorization, attempt to change quantity to a discount
                      after subtotal is performed and the quantity of the discount is not updated
        # Allow transaction modification after loyalty authorization is set to Yes
        Given the POS option 5275 is set to 1
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id  | unit_type       | is_apply_as_tender |
            #| 400            | Misc item disc       | 0.10           | item           | promo1        | SIMPLE_QUANTITY | False              |
            #| 400            | Misc tran disc       | 0.10           | transaction    | promo2        | SIMPLE_QUANTITY | False              |
            | 400            | Misc tran tender     | 0.10           | transaction    | promo3        | SIMPLE_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the transaction is totaled
        When the cashier updates quantity of the item <item_name> to 2
        Then the POS displays Quantity not allowed error
        And an item <item_name> with price <item_price> and quantity 1 is in the virtual receipt
        And an item <item_name> with price <item_price>, quantity 1 and type <item_type> is in the current transaction

        Examples:
            | item_name         | item_price | item_type |
            #| Misc item disc    | -0.10      | 29        | out of scope
            #| Misc tran disc    | -0.10      | 29        | out of scope
            | Misc tran tender  | -0.10      | 6         |


    @fast @negative
    Scenario Outline: Set POS option to not allow transaction modification after loyalty authorization, attempt to override price to an item
                      after subtotal is performed and the POS displays Not allowed after total error.
        # Allow transaction modification after loyalty authorization is set to No
        Given the POS option 5275 is set to 0
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id  | unit_type       | is_apply_as_tender |
            | 400            | Misc item disc       | 0.10           | item           | promo1        | SIMPLE_QUANTITY | False              |
            | 400            | Misc tran disc       | 0.10           | transaction    | promo2        | SIMPLE_QUANTITY | False              |
            | 400            | Misc tran tender     | 0.10           | transaction    | promo3        | SIMPLE_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the transaction is totaled
        When the cashier overrides price of the item <item_name> to price 5.00
        Then the POS displays Not allowed after total error
        And an item <item_name> with price <item_price> is in the virtual receipt
        And an item <item_name> with price <item_price> and type <item_type> is in the current transaction

        Examples:
            | item_name         | item_price | item_type |
            | Sale Item A       | 0.99       | 1         |
            | Misc item disc    | -0.10      | 29        |
            | Misc tran disc    | -0.10      | 29        |
            | Misc tran tender  | -0.10      | 6         |


    @fast @positive
    Scenario Outline: Set POS option to allow transaction modification after loyalty authorization, attempt to override price to an item
                      after subtotal is performed and the price of the item is updated
        # Allow transaction modification after loyalty authorization is set to Yes
        Given the POS option 5275 is set to 1
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the transaction is totaled
        When the cashier overrides price of the item <item_name> to price <new_item_price>
        Then the POS displays main menu frame
        And an item <item_name> with price <new_item_price> is in the virtual receipt
        And an item <item_name> with price <new_item_price> is in the current transaction

        Examples:
            | item_name         | item_price | item_type | new_item_price |
            | Sale Item A       | 0.99       | 1         | 5.00           |


    @fast @negative
    Scenario Outline: Set POS option to not allow transaction modification after loyalty authorization, attempt to override price to a discount
                      after subtotal is performed and the quantity of the discount is not updated
        # Allow transaction modification after loyalty authorization is set to Yes
        Given the POS option 5275 is set to 1
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id  | unit_type       | is_apply_as_tender |
            #| 400            | Misc item disc       | 0.10           | item           | promo1        | SIMPLE_QUANTITY | False              |
            #| 400            | Misc tran disc       | 0.10           | transaction    | promo2        | SIMPLE_QUANTITY | False              |
            | 400            | Misc tran tender     | 0.10           | transaction    | promo3        | SIMPLE_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the transaction is totaled
        When the cashier overrides price of the item <item_name> to price 5.00
        Then the POS displays Price override not allowed error frame
        And an item <item_name> with price <item_price> is in the virtual receipt
        And an item <item_name> with price <item_price> and type <item_type> is in the current transaction

        Examples:
            | item_name         | item_price | item_type |
            #| Misc item disc    | -0.10      | 29        | out of scope
            #| Misc tran disc    | -0.10      | 6         | out of scope
            | Misc tran tender  | -0.10      | 6         |
