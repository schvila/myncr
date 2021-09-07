@pos @pes
Feature: Promotion Execution Service - local discounts
    This feature file focuses on scenarios covering combining local discounts with PES discounts. Local discounts should take a preference over loyalty discounts.

    Background: POS is configured for PES feature
        Given the POS has essential configuration
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        And the POS option 5277 is set to 1
        # Default Loyalty Discount Id is set to PES_basic
        And the POS parameter 120 is set to PES_basic
        # Add configured 'PES_tender' loyalty tender record
        And the pricebook contains PES loyalty tender
        And the POS has following discounts configured
            | reduction_id | description | price | external_id |
            | 1            | PES loyalty | 0.00  | PES_basic   |
        And the POS recognizes following PES cards
            | card_definition_id | card_role | card_name | barcode_range_from | card_definition_group_id |
            | 70000001142        | 3         | PES card  | 3104174102936582   | 70000010042              |
        And the POS is configured to communicate with PES
        # Cloud Loyalty Interface is set to PES
        And the POS option 5284 is set to 1
        And the nep-server has default configuration


    @positive @fast
    Scenario Outline: Add items to the transaction, the autocombo appears in the VR before subtotal.
        Given the pricebook contains autocombos
            | description | reduction_value | disc_type         | disc_mode         | disc_quantity | item_name   | quantity |
            | 2As Combo   | 17800           | AUTO_COMBO_AMOUNT | WHOLE_TRANSACTION | ALLOW_ALWAYS  | Sale Item A | 2        |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        When the cashier scans barcode <barcode> 2 times
        Then the autocombo <combo_description> with discount of <combo_value> is in the current transaction
        And the autocombo <combo_description> with discount of <combo_value> is in the virtual receipt
        And a card PES card with value of 0.00 is in the current transaction

        Examples:
            | combo_description | barcode      | combo_value |
            | 2As Combo         | 099999999990 | 0.20        |


    @positive @fast
    Scenario Outline: Add items to the transaction, the autocombo is still in the VR after subtotal.
        Given the pricebook contains autocombos
            | description | reduction_value | disc_type         | disc_mode         | disc_quantity | item_name   | quantity |
            | 2As Combo   | 17800           | AUTO_COMBO_AMOUNT | WHOLE_TRANSACTION | ALLOW_ALWAYS  | Sale Item A | 2        |
        And the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction 2 times
        And a PES loyalty card 3104174102936582 is present in the transaction
        When the cashier presses the cash tender button
        Then the autocombo <combo_description> with discount of <combo_value> is in the current transaction
        And the autocombo <combo_description> with discount of <combo_value> is in the virtual receipt
        And a card PES card with value of 0.00 is in the current transaction

        Examples:
            | combo_description | barcode      | combo_value |
            | 2As Combo         | 099999999990 | 0.20        |


    @positive @fast
    Scenario Outline: Add items and PES loyalty card to the transaction, the autocombo appears in the VR and the loyalty discount appears in the VR after subtotal.
        Given the pricebook contains autocombos
            | description | reduction_value | disc_type         | disc_mode         | disc_quantity | item_name   | quantity |
            | 2As Combo   | 17800           | AUTO_COMBO_AMOUNT | WHOLE_TRANSACTION | ALLOW_ALWAYS  | Sale Item A | 2        |
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description   | discount_value | discount_level   | promotion_id            | unit_type       | is_apply_as_tender |
            | 400            | <discount_description> | 0.30           | <discount_level> | 30cents off merchandise | SIMPLE_QUANTITY | False              |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode <barcode> is present in the transaction 2 times
        When the cashier presses the cash tender button
        Then a card PES card with value of 0.00 is in the current transaction
        And a loyalty discount <discount_description> with value of <discount_value> and quantity <quantity> is in the current transaction
        And a loyalty discount <discount_description> with value of <discount_value> and quantity <quantity> is in the virtual receipt
        And the autocombo <combo_description> with discount of <combo_value> is in the current transaction
        And the autocombo <combo_description> with discount of <combo_value> is in the virtual receipt

        Examples:
            | quantity | discount_description | discount_value | combo_description | barcode      | combo_value | discount_level |
            | 2        | Miscellaneous        | 0.60           | 2As Combo         | 099999999990 | 0.20        | item           |
            # Simulator sends only one transaction discount for 2 items
            | 1        | Miscellaneous        | 0.30           | 2As Combo         | 099999999990 | 0.20        | transaction    |


    @positive @fast
    Scenario Outline: Add items and PES loyalty card to the transaction, the autocombo appears in the VR and the loyalty tender appears in the VR after subtotal.
        Given the pricebook contains autocombos
            | description | reduction_value | disc_type         | disc_mode         | disc_quantity | item_name   | quantity |
            | 2As Combo   | 17800           | AUTO_COMBO_AMOUNT | WHOLE_TRANSACTION | ALLOW_ALWAYS  | Sale Item A | 2        |
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | unit_type       | is_apply_as_tender |
            | 400            | <tender_description> | <tender_value> | transaction    | 30cents off merchandise | SIMPLE_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode <barcode> is present in the transaction 2 times
        When the cashier presses the cash tender button
        Then a card PES card with value of 0.00 is in the current transaction
        And a tender <tender_description> with amount <tender_value> is in the current transaction
        And a tender <tender_description> with amount <tender_value> is in the virtual receipt
        And the autocombo <combo_description> with discount of <combo_value> is in the current transaction
        And the autocombo <combo_description> with discount of <combo_value> is in the virtual receipt

        Examples:
            | tender_description | tender_value | combo_description | barcode      | combo_value |
            | Miscellaneous      | 0.30         | 2As Combo         | 099999999990 | 0.20        |


    @positive @fast
    Scenario Outline: Partial discounts are enabled. Add items and PES loyalty card in the transaction, the autocombo appears in the VR,
        the subtotal has lower value than the loyalty discount, the loyalty discount appears in the VR after subtotal with reduced value.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the pricebook contains autocombos
            | description | reduction_value | disc_type         | disc_mode         | disc_quantity | item_name   | quantity |
            | 2As Combo   | 2000            | AUTO_COMBO_AMOUNT | WHOLE_TRANSACTION | ALLOW_ALWAYS  | Sale Item A | 2        |
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level   | promotion_id            | unit_type       | is_apply_as_tender |
            | 400            | Miscellaneous        | 0.30           | <discount_level> | 30cents off merchandise | SIMPLE_QUANTITY | False              |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode <barcode> is present in the transaction 2 times
        When the cashier presses the cash tender button
        Then a card PES card with value of 0.00 is in the current transaction
        And a loyalty discount <discount_description> with value of <discount_value> is in the current transaction
        And a loyalty discount <discount_description> with value of <discount_value> is in the virtual receipt
        And the autocombo <combo_description> with discount of <combo_value> is in the current transaction
        And the autocombo <combo_description> with discount of <combo_value> is in the virtual receipt
        And the transaction's subtotal is 0.00

        Examples:
            | discount_description | discount_value | combo_description | barcode      | combo_value | discount_level |
            | Miscellaneous        | 0.20           | 2As Combo         | 099999999990 | 1.78        | item           |
            | Miscellaneous        | 0.20           | 2As Combo         | 099999999990 | 1.78        | transaction    |


    @positive @fast
    Scenario Outline: Partial discounts are enabled. Add items and PES loyalty card in the transaction, the autocombo appears in the VR,
        the subtotal has lower value than the loyalty tender, the loyalty tender appears in the VR after subtotal with reduced value.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the pricebook contains autocombos
            | description | reduction_value | disc_type         | disc_mode         | disc_quantity | item_name   | quantity |
            | 2As Combo   | 2000            | AUTO_COMBO_AMOUNT | WHOLE_TRANSACTION | ALLOW_ALWAYS  | Sale Item A | 2        |
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | unit_type       | is_apply_as_tender |
            | 400            | <tender_description> | 0.30           | transaction    | 30cents off merchandise | SIMPLE_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode <barcode> is present in the transaction 2 times
        When the cashier presses the cash tender button
        Then a card PES card with value of 0.00 is in the current transaction
        And a tender <tender_description> with amount <tender_value> is in the current transaction
        And a tender <tender_description> with amount <tender_value> is in the virtual receipt
        And the autocombo <combo_description> with discount of <combo_value> is in the current transaction
        And the autocombo <combo_description> with discount of <combo_value> is in the virtual receipt
        And the transaction's subtotal is <subtotal>
        And the transaction's balance is 0.00

        Examples:
            # tender_value includes tax
            | tender_description | tender_value | combo_description | barcode      | combo_value | subtotal |
            | Miscellaneous      | 0.21         | 2As Combo         | 099999999990 | 1.78        | 0.20     |


    @negative @fast
    Scenario Outline: Partial discounts are disabled. Add items and PES loyalty card in the transaction, the autocombo appears in the VR,
        the subtotal has lower value than the loyalty discount, the loyalty discount does not appear in the VR after subtotal.
        # Promotion Execution Service Allow partial discounts is set to No
        Given the POS option 5278 is set to 0
        And the pricebook contains autocombos
            | description | reduction_value | disc_type         | disc_mode         | disc_quantity | item_name   | quantity |
            | 2As Combo   | 2000            | AUTO_COMBO_AMOUNT | WHOLE_TRANSACTION | ALLOW_ALWAYS  | Sale Item A | 2        |
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description   | discount_value   | discount_level   | promotion_id            | unit_type       | is_apply_as_tender |
            | 400            | <discount_description> | <discount_value> | <discount_level> | 30cents off merchandise | SIMPLE_QUANTITY | False              |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction 2 times
        When the cashier presses the cash tender button
        Then a card PES card with value of 0.00 is in the current transaction
        And a loyalty discount <discount_description> with value of <discount_value> is not in the current transaction
        And a loyalty discount <discount_description> with value of <discount_value> is not in the virtual receipt
        And the autocombo <combo_description> with discount of <combo_value> is in the current transaction
        And the autocombo <combo_description> with discount of <combo_value> is in the virtual receipt

        Examples:
            | discount_description | discount_value | combo_description | barcode      | combo_value | discount_level |
            | Miscellaneous        | 0.30           | 2As Combo         | 099999999990 | 1.78        | item           |
            | Miscellaneous        | 0.30           | 2As Combo         | 099999999990 | 1.78        | transaction    |


    @negative @fast
    Scenario Outline: Partial discounts are disabled. Add items and PES loyalty card in the transaction, the autocombo appears in the VR,
        the subtotal has lower value than the loyalty tender, the loyalty tender does not appear in the VR after subtotal.
        # Promotion Execution Service Allow partial discounts is set to No
        Given the POS option 5278 is set to 0
        And the pricebook contains autocombos
            | description | reduction_value | disc_type         | disc_mode         | disc_quantity | item_name   | quantity |
            | 2As Combo   | 2000            | AUTO_COMBO_AMOUNT | WHOLE_TRANSACTION | ALLOW_ALWAYS  | Sale Item A | 2        |
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value   | discount_level | promotion_id            | unit_type       | is_apply_as_tender |
            | 400            | <tender_description> | <discount_value> | transaction    | 30cents off merchandise | SIMPLE_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction 2 times
        When the cashier presses the cash tender button
        Then a card PES card with value of 0.00 is in the current transaction
        And a tender <tender_description> is not in the current transaction
        And a tender <tender_description> is not in the virtual receipt
        And the autocombo <combo_description> with discount of <combo_value> is in the current transaction
        And the autocombo <combo_description> with discount of <combo_value> is in the virtual receipt

        Examples:
            | tender_description | discount_value | combo_description | barcode      | combo_value |
            | Miscellaneous      | 0.30           | 2As Combo         | 099999999990 | 1.78        |


    @positive @fast
    Scenario Outline: Cashier adds item with applied promotion and PES loyalty card in the transaction, the loyalty discount is added to the transaction after subtotal.
        Given the pricebook contains promotions
            | item_name   | promotion_price |
            | Sale Item A | 5000            |
            | Sale Item B | 12000           |
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description   | discount_value   | discount_level   | promotion_id            | unit_type       | is_apply_as_tender |
            | 400            | <discount_description> | <discount_value> | <discount_level> | 30cents off merchandise | SIMPLE_QUANTITY | False              |
        And the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And a PES loyalty card 3104174102936582 is present in the transaction
        When the cashier presses the cash tender button
        Then a card PES card with value of 0.00 is in the current transaction
        And a loyalty discount <discount_description> with value of <discount_value> is in the current transaction
        And a loyalty discount <discount_description> with value of <discount_value> is in the virtual receipt
        And an item <item_name> with price <price> is in the current transaction
        And an item <item_name> with price <price> is in the virtual receipt

        Examples:
            | item_name   | barcode      | price | discount_description | discount_value | discount_level |
            | Sale Item A | 099999999990 | 0.50  | Miscellaneous        | 0.30           | item           |
            | Sale Item B | 088888888880 | 1.20  | Miscellaneous        | 0.30           | item           |
            | Sale Item A | 099999999990 | 0.50  | Miscellaneous        | 0.30           | transaction    |
            | Sale Item B | 088888888880 | 1.20  | Miscellaneous        | 0.30           | transaction    |


    @positive @fast
    Scenario Outline: Cashier adds item with applied promotion and PES loyalty card in the transaction, the loyalty tender is added to the transaction after subtotal.
        Given the pricebook contains promotions
            | item_name   | promotion_price |
            | Sale Item A | 5000            |
            | Sale Item B | 12000           |
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | unit_type       | is_apply_as_tender |
            | 400            | <tender_description> | <tender_value> | transaction    | 30cents off merchandise | SIMPLE_QUANTITY | True               |
        And the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And a PES loyalty card 3104174102936582 is present in the transaction
        When the cashier presses the cash tender button
        Then a card PES card with value of 0.00 is in the current transaction
        And a tender <tender_description> with amount <tender_value> is in the current transaction
        And a tender <tender_description> with amount <tender_value> is in the virtual receipt
        And an item <item_name> with price <price> is in the current transaction
        And an item <item_name> with price <price> is in the virtual receipt

        Examples:
            | item_name   | barcode      | price | tender_description | tender_value |
            | Sale Item A | 099999999990 | 0.50  | Miscellaneous      | 0.30         |
            | Sale Item B | 088888888880 | 1.20  | Miscellaneous      | 0.30         |


    @positive @fast
    Scenario Outline: Partial discounts are enabled. Cashier adds item with applied promotion and PES loyalty card in the transaction,
        subtotal has lower value than loyalty discount, the loyalty discount is added to the transaction with reduced value.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the pricebook contains promotions
            | item_name   | promotion_price |
            | Sale Item A | 2000            |
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description   | discount_value | discount_level   | promotion_id            | unit_type       | is_apply_as_tender |
            | 400            | <discount_description> | 0.30           | <discount_level> | 30cents off merchandise | SIMPLE_QUANTITY | False              |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode <barcode> is present in the transaction
        When the cashier presses the cash tender button
        Then a card PES card with value of 0.00 is in the current transaction
        And a loyalty discount <discount_description> with value of <discount_value> is in the current transaction
        And a loyalty discount <discount_description> with value of <discount_value> is in the virtual receipt
        And an item <item_name> with price <price> is in the current transaction
        And an item <item_name> with price <price> is in the virtual receipt
        And the transaction's subtotal is 0.00

        Examples:
            | item_name   | barcode      | price | discount_description | discount_value | discount_level |
            | Sale Item A | 099999999990 | 0.20  | Miscellaneous        | 0.20           | item           |
            | Sale Item A | 099999999990 | 0.20  | Miscellaneous        | 0.20           | transaction    |


    @positive @fast
    Scenario Outline: Partial discounts are enabled. Cashier adds item with applied promotion and PES loyalty card in the transaction,
        subtotal has lower value than loyalty tender, the loyalty tender is added to the transaction with reduced value.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the pricebook contains promotions
            | item_name   | promotion_price |
            | Sale Item A | 2000            |
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | unit_type       | is_apply_as_tender |
            | 400            | <tender_description> | 0.30           | transaction    | 30cents off merchandise | SIMPLE_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode <barcode> is present in the transaction
        When the cashier presses the cash tender button
        Then a card PES card with value of 0.00 is in the current transaction
        And a tender <tender_description> with amount <tender_value> is in the current transaction
        And a tender <tender_description> with amount <tender_value> is in the virtual receipt
        And an item <item_name> with price <price> is in the current transaction
        And an item <item_name> with price <price> is in the virtual receipt
        And the transaction's subtotal is <price>
        And the transaction's balance is 0.00

        Examples:
            # tender_value includes the tax
            | item_name   | barcode      | price | tender_description | tender_value |
            | Sale Item A | 099999999990 | 0.20  | Miscellaneous      | 0.21         |


    @negative @fast
    Scenario Outline: Partial discounts are disabled. Cashier adds item with applied promotion and PES loyalty card in the transaction,
        subtotal has lower value than loyalty discount, the loyalty discount is not added to the transaction.
        # Promotion Execution Service Allow partial discounts is set to No
        Given the POS option 5278 is set to 0
        And the pricebook contains promotions
            | item_name   | promotion_price |
            | Sale Item A | 2000            |
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description   | discount_value   | discount_level   | promotion_id            | unit_type       | is_apply_as_tender |
            | 400            | <discount_description> | <discount_value> | <discount_level> | 30cents off merchandise | SIMPLE_QUANTITY | False              |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode <barcode> is present in the transaction
        When the cashier presses the cash tender button
        Then a card PES card with value of 0.00 is in the current transaction
        And a loyalty discount <discount_description> with value of <discount_value> is not in the current transaction
        And a loyalty discount <discount_description> with value of <discount_value> is not in the virtual receipt
        And an item <item_name> with price <price> is in the current transaction
        And an item <item_name> with price <price> is in the virtual receipt

        Examples:
            | item_name   | barcode      | price | discount_description | discount_value | discount_level |
            | Sale Item A | 099999999990 | 0.20  | Miscellaneous        | 0.30           | item           |
            | Sale Item A | 099999999990 | 0.20  | Miscellaneous        | 0.30           | transaction    |


    @negative @fast
    Scenario Outline: Partial discounts are disabled. Cashier adds item with applied promotion and PES loyalty card in the transaction,
        subtotal has lower value than loyalty tender, the loyalty tender is not added to the transaction.
        # Promotion Execution Service Allow partial discounts is set to No
        Given the POS option 5278 is set to 0
        And the pricebook contains promotions
            | item_name   | promotion_price |
            | Sale Item A | 2000            |
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | unit_type       | is_apply_as_tender |
            | 400            | <tender_description> | <tender_value> | transaction    | 30cents off merchandise | SIMPLE_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode <barcode> is present in the transaction
        When the cashier presses the cash tender button
        Then a card PES card with value of 0.00 is in the current transaction
        And a tender <tender_description> is not in the current transaction
        And a tender <tender_description> is not in the virtual receipt
        And an item <item_name> with price <price> is in the current transaction
        And an item <item_name> with price <price> is in the virtual receipt

        Examples:
            | item_name   | barcode      | price | tender_description | tender_value |
            | Sale Item A | 099999999990 | 0.20  | Miscellaneous      | 0.30         |


    @positive @fast
    Scenario Outline: POS coupons/discounts are added to the transaction together with PES loyalty card, both loyalty and POS discounts appear in the VR.
        Given the pricebook contains coupons
            | description                 | reduction_value | disc_type      | disc_mode         | disc_quantity   |
            | Preset Percentage Coupon 20 | 200000          | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |
        And the pricebook contains discounts
            | description                   | reduction_value | disc_type      | disc_mode         | disc_quantity   |
            | Preset Percentage Discount 30 | 300000          | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value            | discount_level   | promotion_id            | unit_type       | is_apply_as_tender |
            | 400            | <loyalty_discount>   | <loyalty_discount_amount> | <discount_level> | 30cents off merchandise | SIMPLE_QUANTITY | False              |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the cashier added a <type> <local_discount>
        When the cashier presses the cash tender button
        Then a <type> <local_discount> is in the current transaction
        And a <type> <local_discount> with value of <local_discount_amount> is in the virtual receipt
        And a loyalty discount <loyalty_discount> with value of <loyalty_discount_amount> is in the current transaction
        And a loyalty discount <loyalty_discount> with value of <loyalty_discount_amount> is in the virtual receipt

        Examples:
            | type     | local_discount                | local_discount_amount | loyalty_discount | loyalty_discount_amount | discount_level |
            # Item discounts causes the local_discount_amount to change (20% and 30% from 0.69)
            #| coupon   | Preset Percentage Coupon 20   | 0.20                  | Miscellaneous    | 0.30                    | item           |
            #| discount | Preset Percentage Discount 30 | 0.30                  | Miscellaneous    | 0.30                    | item           |
            | coupon   | Preset Percentage Coupon 20   | 0.20                  | Miscellaneous    | 0.30                    | transaction    |
            | discount | Preset Percentage Discount 30 | 0.30                  | Miscellaneous    | 0.30                    | transaction    |


    @positive @fast
    Scenario Outline: POS coupons/discounts are added to the transaction together with PES loyalty card, POS discounts and loyalty tender appear in the VR.
        Given the pricebook contains coupons
            | description                 | reduction_value | disc_type      | disc_mode         | disc_quantity   |
            | Preset Percentage Coupon 20 | 200000          | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |
        And the pricebook contains discounts
            | description                   | reduction_value | disc_type      | disc_mode         | disc_quantity   |
            | Preset Percentage Discount 30 | 300000          | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value          | discount_level | promotion_id            | unit_type       | is_apply_as_tender |
            | 400            | <loyalty_tender>     | <loyalty_tender_amount> | transaction    | 30cents off merchandise | SIMPLE_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the cashier added a <type> <local_discount>
        When the cashier presses the cash tender button
        Then a <type> <local_discount> is in the current transaction
        And a <type> <local_discount> with value of <local_discount_amount> is in the virtual receipt
        And a tender <loyalty_tender> with amount <loyalty_tender_amount> is in the current transaction
        And a tender <loyalty_tender> with amount <loyalty_tender_amount> is in the virtual receipt

        Examples:
            | type     | local_discount                | local_discount_amount | loyalty_tender | loyalty_tender_amount |
            | coupon   | Preset Percentage Coupon 20   | 0.20                  | Miscellaneous  | 0.30                  |
            | discount | Preset Percentage Discount 30 | 0.30                  | Miscellaneous  | 0.30                  |


    @positive @fast
    Scenario Outline: Partial discounts are enabled. POS coupons/discounts and PES loyalty card are added to the transaction,
        the subtotal has lower value than the loyalty discount, loyalty discount is added to the transaction with reduced value.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the pricebook contains coupons
            | description                 | reduction_value | disc_type      | disc_mode         | disc_quantity   |
            | Preset Percentage Coupon 80 | 800000          | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |
        And the pricebook contains discounts
            | description                   | reduction_value | disc_type      | disc_mode         | disc_quantity   |
            | Preset Percentage Discount 90 | 900000          | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level   | promotion_id            | unit_type       | is_apply_as_tender |
            | 400            | <loyalty_discount>   | 0.30           | <discount_level> | 30cents off merchandise | SIMPLE_QUANTITY | False              |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the cashier added a <type> <local_discount>
        When the cashier presses the cash tender button
        Then a <type> <local_discount> is in the current transaction
        And a <type> <local_discount> with value of <local_discount_amount> is in the virtual receipt
        And a loyalty discount <loyalty_discount> with value of <loyalty_discount_amount> is in the current transaction
        And a loyalty discount <loyalty_discount> with value of <loyalty_discount_amount> is in the virtual receipt
        And the transaction's subtotal is 0.00

        Examples:
            | type     | local_discount                | local_discount_amount | loyalty_discount | loyalty_discount_amount | discount_level |
            # Item discounts causes the local_discount_amount to change
            #| coupon   | Preset Percentage Coupon 80   | 0.79                  | Miscellaneous    | 0.20                    | item           |
            #| discount | Preset Percentage Discount 90 | 0.89                  | Miscellaneous    | 0.10                    | item           |
            | coupon   | Preset Percentage Coupon 80   | 0.79                  | Miscellaneous    | 0.20                    | transaction    |
            | discount | Preset Percentage Discount 90 | 0.89                  | Miscellaneous    | 0.10                    | transaction    |


    @positive @fast
    Scenario Outline: Partial discounts are enabled. POS coupons/discounts, loyalty tender and PES loyalty card are added to the transaction,
        the subtotal has lower value than the loyalty tender, loyalty tender is added to the transaction with reduced value.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the pricebook contains coupons
            | description                 | reduction_value | disc_type      | disc_mode         | disc_quantity   |
            | Preset Percentage Coupon 80 | 800000          | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |
        And the pricebook contains discounts
            | description                   | reduction_value | disc_type      | disc_mode         | disc_quantity   |
            | Preset Percentage Discount 90 | 900000          | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | unit_type       | is_apply_as_tender |
            | 400            | <loyalty_tender>     | 0.30           | transaction    | 30cents off merchandise | SIMPLE_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the cashier added a <type> <local_discount>
        When the cashier presses the cash tender button
        Then a <type> <local_discount> is in the current transaction
        And a <type> <local_discount> with value of <local_discount_amount> is in the virtual receipt
        And a tender <loyalty_tender> with amount <loyalty_tender_amount> is in the current transaction
        And a tender <loyalty_tender> with amount <loyalty_tender_amount> is in the virtual receipt
        And the transaction's subtotal is <subtotal>
        And the transaction's balance is 0.00

        Examples:
            # loyalty_tender_amount is with tax included
            | type     | local_discount                | local_discount_amount | loyalty_tender | loyalty_tender_amount | subtotal |
            | coupon   | Preset Percentage Coupon 80   | 0.79                  | Miscellaneous  | 0.27                  | 0.20     |
            | discount | Preset Percentage Discount 90 | 0.89                  | Miscellaneous  | 0.17                  | 0.10     |


    @positive @fast
    Scenario Outline: Partial discounts are disabled. POS coupons/discounts and PES loyalty card are added to the transaction,
        the subtotal has lower value than the loyalty discount, loyalty discount is not added to the transaction.
        # Promotion Execution Service Allow partial discounts is set to No
        Given the POS option 5278 is set to 0
        And the pricebook contains coupons
            | description                 | reduction_value | disc_type      | disc_mode         | disc_quantity   |
            | Preset Percentage Coupon 80 | 800000          | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |
        And the pricebook contains discounts
            | description                   | reduction_value | disc_type      | disc_mode         | disc_quantity   |
            | Preset Percentage Discount 90 | 900000          | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level   | promotion_id            | unit_type       | is_apply_as_tender |
            | 400            | <loyalty_discount>   | 0.30           | <discount_level> | 30cents off merchandise | SIMPLE_QUANTITY | False              |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the cashier added a <type> <local_discount>
        When the cashier presses the cash tender button
        Then a <type> <local_discount> is in the current transaction
        And a <type> <local_discount> with value of <local_discount_amount> is in the virtual receipt
        And a loyalty discount <loyalty_discount> with value of <loyalty_discount_amount> is not in the current transaction
        And a loyalty discount <loyalty_discount> with value of <loyalty_discount_amount> is not in the virtual receipt

        Examples:
            | type     | local_discount                | local_discount_amount | loyalty_discount | loyalty_discount_amount | discount_level |
            # Item discounts causes the local_discount_amount to change
            #| coupon   | Preset Percentage Coupon 80   | 0.79                  | Miscellaneous    | 0.30                    | item           |
            #| discount | Preset Percentage Discount 90 | 0.89                  | Miscellaneous    | 0.30                    | item           |
            | coupon   | Preset Percentage Coupon 80   | 0.79                  | Miscellaneous    | 0.30                    | transaction    |
            | discount | Preset Percentage Discount 90 | 0.89                  | Miscellaneous    | 0.30                    | transaction    |


    @positive @fast
    Scenario Outline: Partial discounts are disabled. POS coupons/discounts, loyalty tender and PES loyalty card are added to the transaction,
        the subtotal has lower value than the loyalty tender, loyalty tender is not added to the transaction.
        # Promotion Execution Service Allow partial discounts is set to No
        Given the POS option 5278 is set to 0
        And the pricebook contains coupons
            | description                 | reduction_value | disc_type      | disc_mode         | disc_quantity   |
            | Preset Percentage Coupon 80 | 800000          | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |
        And the pricebook contains discounts
            | description                   | reduction_value | disc_type      | disc_mode         | disc_quantity   |
            | Preset Percentage Discount 90 | 900000          | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | unit_type       | is_apply_as_tender |
            | 400            | <loyalty_tender>     | 0.30           | transaction    | 30cents off merchandise | SIMPLE_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the cashier added a <type> <local_discount>
        When the cashier presses the cash tender button
        Then a <type> <local_discount> is in the current transaction
        And a <type> <local_discount> with value of <local_discount_amount> is in the virtual receipt
        And a tender <loyalty_tender> is not in the current transaction
        And a tender <loyalty_tender> is not in the virtual receipt

        Examples:
            | type     | local_discount                | local_discount_amount | loyalty_tender |
            | coupon   | Preset Percentage Coupon 80   | 0.79                  | Miscellaneous  |
            | discount | Preset Percentage Discount 90 | 0.89                  | Miscellaneous  |


    @positive @fast
    Scenario Outline: POS coupons/discounts with tax reduction allowed are added to the transaction together with PES loyalty card, POS discounts and loyalty tender appear in the VR,
                      the transaction tax amount is reduced according to the coupons/discounts value and is not being paid with loyalty tender.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the pricebook contains coupons
            | description                  | reduction_value | disc_type      | disc_mode         | disc_quantity   | reduces_tax |
            | Preset Percentage Coupon S50 | 500000          | PRESET_PERCENT | SINGLE_ITEM       | ALLOW_ONLY_ONCE | true        |
        And the pricebook contains discounts
            | description                    | reduction_value | disc_type      | disc_mode   | disc_quantity   | reduces_tax |
            | Preset Percentage Discount S50 | 500000          | PRESET_PERCENT | SINGLE_ITEM | ALLOW_ONLY_ONCE | true        |
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level   | promotion_id            | unit_type       | is_apply_as_tender |
            | 400            | <loyalty_discount>   | 1.00           | <discount_level> | 30cents off merchandise | SIMPLE_QUANTITY | False              |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the tax amount from current transaction is 0.07
        And the cashier added a <type> <local_discount>
        When the cashier presses the cash tender button
        Then a <type> <local_discount> is in the current transaction
        And a <type> <local_discount> with value of <local_discount_amount> is in the virtual receipt
        And a loyalty discount <loyalty_discount> with value of <loyalty_discount_amount> is in the current transaction
        And a loyalty discount <loyalty_discount> with value of <loyalty_discount_amount> is in the virtual receipt
        And the transaction's subtotal is 0.00
        And the tax amount from current transaction is 0.03

        Examples:
            | type     | local_discount                 | local_discount_amount | loyalty_discount | loyalty_discount_amount | discount_level |
            | coupon   | Preset Percentage Coupon S50   | 0.50                  | Miscellaneous    | 0.49                    | item           |
            | discount | Preset Percentage Discount S50 | 0.50                  | Miscellaneous    | 0.49                    | item           |
