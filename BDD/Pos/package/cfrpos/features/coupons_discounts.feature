@pos @coupon_discounts
Feature: Coupon-discounts
This feature tests operations with coupons and discounts

Background: The POS needs to have some items configured to manipulate with them.
    Given the POS has essential configuration
    And the pricebook contains coupons
    | description                 | reduction_value | disc_type        | disc_mode         | disc_quantity   | retail_item_group_id | free_item_flag | reduces_tax |
    | Preset Percentage Coupon 20 | 200000          | PRESET_PERCENT   | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |                      |                |             |
    | Preset Percentage Coupon 50 | 500000          | PRESET_PERCENT   | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |                      |                |             |
    | Prompted Percentage Coupon  | 0               | PROMPTED_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |                      |                |             |
    | Prompted Amount Coupon W rt | 0               | PROMPTED_Amount  | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |                      |                | True        |
    | Prompted Amount Coupon W    | 0               | PROMPTED_Amount  | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |                      |                | False       |
    | Prompted Amount Coupon S rt | 0               | PROMPTED_Amount  | SINGLE_ITEM       | ALLOW_ONLY_ONCE |                      |                | True        |
    | Prompted Amount Coupon S    | 0               | PROMPTED_Amount  | SINGLE_ITEM       | ALLOW_ONLY_ONCE |                      |                | False       |
    | Free Item Coupon            | 0               | FREE_ITEM        | SINGLE_ITEM       | ALLOW_ONLY_ONCE | 990000000006         | True           |             |
    | Preset Amount Coupon S rt   | 5000            | PRESET_Amount    | SINGLE_ITEM       | ALLOW_ONLY_ONCE |                      |                | True        |
    | Preset Amount Coupon S      | 5000            | PRESET_Amount    | SINGLE_ITEM       | ALLOW_ONLY_ONCE |                      |                | False       |
    | Preset Amount Coupon W rt   | 10000           | PRESET_Amount    | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |                      |                | True        |
    | Preset Amount Coupon W      | 10000           | PRESET_Amount    | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |                      |                | False       |
    And the pricebook contains autocombos
    | description       | reduction_value | disc_type          | disc_mode         | disc_quantity   | item_name   | quantity |
    | 2As Combo         | 1000            | AUTO_COMBO_AMOUNT  | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE | Sale Item A | 2        |
    | 4Bs 20% Off Combo | 200000          | AUTO_COMBO_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE | Sale Item B | 4        |
    | 1A+1D Combo       | 2000            | AUTO_COMBO_AMOUNT  | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE | Sale Item A | 1        |
    | 1A+1D Combo       | 13000           | AUTO_COMBO_AMOUNT  | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE | Sale Item D | 1        |

    @fast
    Scenario: Attempt to add Preset percentage coupon in the transaction, main menu frame is displayed, coupon is displayed in the VR
        Given the POS is in a ready to sell state
        And an item with barcode 066666666660 is present in the transaction
        When the cashier adds a coupon Preset Percentage Coupon 50
        Then the POS displays main menu frame
        And a coupon Preset Percentage Coupon 50 is in the current transaction


    @fast
    Scenario: Attempt to change a quantity of the Preset percentage coupon in the transaction, an error is displayed
        Given the POS is in a ready to sell state
        And an item with barcode 066666666660 is present in the transaction
        And the cashier added a coupon Preset Percentage Coupon 50
        When the cashier updates quantity of the coupon Preset Percentage Coupon 50 to 10
        Then the POS displays Quantity not allowed error


    @fast
    Scenario: Attempt to add Prompted percentage coupon in the transaction, enter percent frame is displayed
        Given the POS is in a ready to sell state
        And an item with barcode 066666666660 is present in the transaction
        When the cashier adds a coupon Prompted Percentage Coupon
        Then the POS displays Enter percent frame


    @fast
    Scenario: Attempt to add a Prompted percentage coupon with value over 100, an error is displayed
        Given the POS is in a ready to sell state
        And an item with barcode 066666666660 is present in the transaction
        When the cashier adds Prompted Percentage Coupon with 101 value
        Then the POS displays Coupon amount too large error


    @fast
    Scenario: Press Go back button after the attempt to add Prompted percentage coupon with value over 100 without confirming it, select coupon frame is displayed
        Given the POS is in a ready to sell state
        And an item with barcode 066666666660 is present in the transaction
        And the cashier entered value 101 on Prompted Percentage Coupon without confirming it
        When the cashier presses Go back button
        Then the POS displays Select coupon frame


    @fast
    Scenario: Press Go back button on Enter percent frame, select coupon frame is displayed
        Given the POS is in a ready to sell state
        And an item with barcode 066666666660 is present in the transaction
        And the cashier added a coupon Prompted Percentage Coupon
        When the cashier presses Go back button
        Then the POS displays Select coupon frame


    @fast
    Scenario: Attempt to add Preset percentage coupon, with allow just once flag, more than once in the transaction, main menu frame is displayed
        Given the POS is in a ready to sell state
        And an item with barcode 066666666660 is present in the transaction
        When the cashier adds a Preset Percentage Coupon 20 2 times
        Then the POS displays Coupon already added frame


    @fast @smoke
    Scenario Outline: Cashier adds items in the transaction, autocombo appears in VR
        Given the POS is in a ready to sell state
        When the cashier scans barcode <barcode> <amount> times
        Then the autocombo <autocombo> with discount of <discount> is in the current transaction
        And the autocombo <autocombo> with discount of <discount> is in the virtual receipt

        Examples:
        | autocombo         | barcode      | amount | discount |
        | 2As Combo         | 099999999990 | 2      | 0.10     |
        | 4Bs 20% Off Combo | 088888888880 | 4      | 1.59     |


    @fast
    Scenario Outline: Cashier adds two different items in the transaction, autocombo appears in VR
        Given the POS is in a ready to sell state
        And an item with barcode <barcode_1> is present in the transaction <amount_1> times
        When the cashier scans barcode <barcode_2> <amount_2> times
        Then the autocombo <autocombo> with discount of <discount> is in the current transaction
        And the autocombo <autocombo> with discount of <discount> is in the virtual receipt

        Examples:
        | autocombo   | barcode_1    | amount_1 | barcode_2    | amount_2 | discount |
        | 1A+1D Combo | 099999999990 | 1        | 066666666660 | 1        | 1.50     |


    @fast
    Scenario Outline: Cashier voids one of the items suitable for autocombo discount, verify autocombo is not in the transaction.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode_1> is present in the transaction <amount_1> times
        And an item with barcode <barcode_2> is present in the transaction <amount_2> times
        When the cashier voids the Sale Item A with price 0.99
        Then the autocombo <autocombo> with discount of <discount> is not in the current transaction
        And the autocombo <autocombo> with discount of <discount> is not in the virtual receipt

        Examples:
        | autocombo   | barcode_1    | amount_1 | barcode_2    | amount_2 | discount |
        | 1A+1D Combo | 099999999990 | 1        | 066666666660 | 1        | 1.50     |    


    @fast
     Scenario Outline: Cashier adds items suitable for multipule autocombo discounts, verify all autocombos are present in the transaction.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode_1> is present in the transaction <amount_1> times
        When the cashier scans barcode <barcode_2> <amount_2> times
        Then the autocombo <autocombo_1> with discount of <discount_1> is in the current transaction
        And the autocombo <autocombo_2> with discount of <discount_2> is in the current transaction
        And the autocombo <autocombo_1> with discount of <discount_1> is in the virtual receipt
        And the autocombo <autocombo_2> with discount of <discount_2> is in the virtual receipt 

        Examples:
            | autocombo_1       | discount_1 | barcode_1    | amount_1 | autocombo_2 | discount_2 | barcode_2    | amount_2 |
            | 4Bs 20% Off Combo | 1.59       | 088888888880 | 4        | 2As Combo   | 0.10       | 099999999990 | 2        |


    @fast
     Scenario Outline: Add items suitable for two autocombos to the transaction, cashier voids one of the items needed for one of the autocombo discounts, 
                       verify the correct autocombo is removed from the transaction.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode_1> is present in the transaction <amount_1> times
        And an item with barcode <barcode_2> is present in the transaction <amount_2> times
        When the cashier voids the Sale Item A with price 0.99
        Then the autocombo <autocombo_1> with discount of <discount_1> is in the current transaction
        And the autocombo <autocombo_2> with discount of <discount_2> is not in the current transaction
        And the autocombo <autocombo_1> with discount of <discount_1> is in the virtual receipt
        And the autocombo <autocombo_2> with discount of <discount_2> is not in the virtual receipt 

        Examples:
            | autocombo_1       | discount_1 | barcode_1    | amount_1 | autocombo_2 | discount_2 | barcode_2    | amount_2 |
            | 4Bs 20% Off Combo | 1.59       | 088888888880 | 4        |  2As Combo  | 0.10       | 099999999990 | 2        |

    @fast
    Scenario Outline: Cashier selects a Free Item coupon, main menu frame is displayed, and the coupon appears in VR
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        When the cashier adds a coupon <Coupon Description>
        Then the POS displays main menu frame
        And a coupon <Coupon Description> is in the current transaction
        And a coupon <Coupon Description> with value of <coupon_amount> is in the virtual receipt

        Examples:
        | Coupon Description    | barcode      | coupon_amount |
        | Free Item Coupon      | 077777777770 | 1.49          |


    @fast
    Scenario Outline: Add Preset amount coupon in the transaction, verify coupon is displayed in the VR.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction 2 times
        When the cashier adds a coupon <coupon>
        Then a coupon <coupon> with value of <coupon_amount> is in the virtual receipt
        And the coupon <coupon> with value of <coupon_amount> is in the current transaction
        And a coupon <coupon> is in the current transaction
        And the transaction's subtotal is <subtotal>
        And the tax amount from current transaction is <tax_amount>
        
        Examples:
        | barcode      | subtotal | coupon                    | coupon_amount | tax_amount |
        | 088888888880 | 3.48     | Preset Amount Coupon S rt | 0.50          | 0.24       |
        | 088888888880 | 3.48     | Preset Amount Coupon S    | 0.50          | 0.28       |
        | 088888888880 | 2.98     | Preset Amount Coupon W rt | 1.00          | 0.06       |
        | 088888888880 | 2.98     | Preset Amount Coupon W    | 1.00          | 0.28       |


    @fast
    Scenario Outline: Add items applicable for autocombo to the transaction, apply Present amount coupon, verify both coupon and autocombo are present in the VR.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode_2> is present in the transaction 2 times
        And an item with barcode <barcode_1> is present in the transaction
        When the cashier adds a coupon <coupon>
        Then a coupon <coupon> with value of <coupon_amount> is in the virtual receipt
        And the coupon <coupon> with value of <coupon_amount> is in the current transaction
        And a coupon <coupon> is in the current transaction
        And the autocombo <autocombo> with discount of <autocombo_discount> is in the virtual receipt
        And the autocombo <autocombo> with discount of <autocombo_discount> is in the current transaction
        And the transaction's subtotal is <subtotal>
        And the tax amount from current transaction is <tax_amount>

        Examples:
        | barcode_1    | barcode_2     | subtotal | coupon                      | coupon_amount | tax_amount | autocombo | autocombo_discount|
        | 077777777770 | 099999999990  | 2.37     | Preset Amount Coupon W rt   | 1.00          | 0.01       | 2As Combo | 0.10              |
        | 077777777770 | 099999999990  | 2.37     | Preset Amount Coupon W      | 1.00          | 0.23       | 2As Combo | 0.10              |
        | 077777777770 | 099999999990  | 2.87     | Preset Amount Coupon S rt   | 0.50          | 0.20       | 2As Combo | 0.10              |
        | 077777777770 | 099999999990  | 2.87     | Preset Amount Coupon S      | 0.50          | 0.23       | 2As Combo | 0.10              |
    

    @fast
    Scenario Outline: Select Prompted amount coupon to add in the transaction, the POS displays Ask coupon amount frame.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        When the cashier adds a coupon <coupon>
        Then the POS displays Ask coupon amount frame

        Examples:
        | barcode      | coupon                      |
        | 066666666660 | Prompted Amount Coupon S rt |
        | 066666666660 | Prompted Amount Coupon S    |
        | 066666666660 | Prompted Amount Coupon W rt |
        | 066666666660 | Prompted Amount Coupon W    |
    

    @fast
    Scenario Outline: Add Prompted amount coupon in the transaction, verify coupon appears in the transaction with correct amount. 
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction 
        And the cashier added a coupon <coupon>
        When the cashier enters <coupon_amount> coupon amount in Ask coupon amount frame
        Then a coupon <coupon> with value of <coupon_amount> is in the virtual receipt
        And the coupon <coupon> with value of <coupon_amount> is in the current transaction
        And the tax amount from current transaction is <tax>

        Examples:
        | barcode      | coupon                       | tax  | coupon_amount |
        | 066666666660 | Prompted Amount Coupon S rt  | 0.16 | 0.10          |
        | 066666666660 | Prompted Amount Coupon S     | 0.17 | 0.10          |
        | 066666666660 | Prompted Amount Coupon W rt  | 0.12 | 0.20          |
        | 066666666660 | Prompted Amount Coupon W     | 0.17 | 0.20          |


    @fast
    Scenario Outline: Cashier adds Present amount coupon two times, the POS displays Coupon is already added error frame.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        When the cashier adds a <coupon> 2 times
        Then the POS displays Coupon already added frame
        And a coupon <coupon> with value of <coupon_amount> is in the virtual receipt
        And the coupon <coupon> with value of <coupon_amount> is in the current transaction

        Examples:
        | barcode      | coupon                    | coupon_amount |
        | 066666666660 | Preset Amount Coupon W    | 1.00          |
        | 066666666660 | Preset Amount Coupon W rt | 1.00          |


    @fast
    Scenario Outline: Cashier adds item with applied promotion in the transaction, item with promotion price appears in VR
        Given the pricebook contains promotions
        | item_name   | promotion_price |
        | Sale Item A | 5000            |
        | Sale Item B | 12000           |
        And the POS is in a ready to sell state 
        When the cashier scans a barcode <barcode>
        Then an item <item_name> with price <price> is in the current transaction
        And an item <item_name> with price <price> is in the virtual receipt

        Examples:
        | item_name   | barcode      | price |
        | Sale Item A | 099999999990 | 0.50  |
        | Sale Item B | 088888888880 | 1.20  |
