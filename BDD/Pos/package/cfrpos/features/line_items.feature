@pos
Feature: Line item restriction on pinpad
    This feature shows the functionality of pinpad to display last "N" line items based on the value of POS Option 1243(Number of Line Items diplayed on PIN pad).
    This POS Option can take values from 0 to 4. When set to 0, the pinpad displays all items without any restrictions.
    
Background: 
    Given the POS has essential configuration
    Given the pricebook contains coupons
        | description                   | reduction_value | disc_type        | disc_mode         | disc_quantity   | reduces_tax |
        | Preset Percentage Coupon 20   | 200000          | PRESET_PERCENT   | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |             |
        | Preset Percentage Coupon S20  | 200000          | PRESET_PERCENT   | SINGLE_ITEM       | ALLOW_ONLY_ONCE | True        |
    And the pricebook contains discounts
        | description                   | reduction_value | disc_type      | disc_mode         | disc_quantity   | reduces_tax |
        | Preset Percentage Discount 30 | 300000          | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |             |
        | Preset Percentage Discount S30| 300000          | PRESET_PERCENT | SINGLE_ITEM       | ALLOW_ONLY_ONCE | True        |
    And the EPS simulator has essential configuration
    And the POSCache simulator has default configuration
    And the POS has Customer Display configured
    
    
    Scenario Outline: Set number of items to be displayed on pinpad. Add multiple items to the transaction and verify the pinpad displays correct line items.
        # Number of Line Items diplayed on PIN pad is set to <pos_option_value>
        Given the POS option 1243 is set to <pos_option_value>
        And the POS is in a ready to sell state
        When the cashier scans following barcodes <barcode_list>
        Then the pinpad displays line items <items> 

        Examples:
        | pos_option_value | items                                                          | barcode_list                                                             |
        | 0                | Sale Item A, Sale Item B, MM Item G, Sale Item D, Sale Item C  | 099999999990, 088888888880, 033333333330, 066666666660, 077777777770 | 
        | 1                | Sale Item C                                                    | 099999999990, 088888888880, 033333333330, 066666666660, 077777777770 | 
        | 2                | Sale Item D, Sale Item C                                       | 099999999990, 088888888880, 033333333330, 066666666660, 077777777770 | 
        | 3                | MM Item G, Sale Item D, Sale Item C                            | 099999999990, 088888888880, 033333333330, 066666666660, 077777777770 | 
        | 4                | Sale Item B, MM Item G, Sale Item D, Sale Item C               | 099999999990, 088888888880, 033333333330, 066666666660, 077777777770 | 


    @manual
    # Since before storing the transactions, items are already pushed to the dictionary and on recalling the same transaction,
    # pinpad only displays Order# but VR displays all items in the recalled transaction. From obtanied poscache_data, start of a recall transaction
    # should be identified and the items only corresponding to that transaction have to be cleared.
    Scenario Outline: Set number of line items to be displayed on pinpad. Recall a stored transaction and verify pinpad displays correct line items
        # Number of Line Items diplayed on PIN pad is set to <pos_option_value>
        Given the POS option 1243 is set to <pos_option_val>
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the cashier stored the transaction
        When the cashier recalls the last stored transaction
        Then the pinpad displays line items <items> 

        Examples:
        | pos_option_value   | items    |
        | 1                  | Order# * |

    
    Scenario Outline: Set number of line items to be displayed on pinpad. Add a coupon/discount to the transaction when multiple items are already present.
                       Verify the pinpad displays correct line items
       # Number of Line Items diplayed on PIN pad is set to <pos_option_value>
        Given the POS option 1243 is set to <pos_option_val>
        And the POS is in a ready to sell state
        And items with barcodes <barcodes> are present in the transaction
        When the cashier adds a <type> <name>
        Then a <type> <name> is in the current transaction
        And the pinpad displays line items <items> 

        Examples:
        |pos_option_val |type        | name                           | items                                                               | barcodes                                               |
        | 1             | discount   | Preset Percentage Discount S30 | Preset Percentage Discount S30                                      | 099999999990, 088888888880, 033333333330, 077777777770 |
        | 1             | coupon     | Preset Percentage Coupon S20   | Preset Percentage Coupon S20                                        | 099999999990, 088888888880, 033333333330, 077777777770 |
        | 2             | discount   | Preset Percentage Discount S30 | Sale Item C, Preset Percentage Discount S30                         | 099999999990, 088888888880, 033333333330, 077777777770 |
        | 2             | coupon     | Preset Percentage Coupon S20   | Sale Item C, Preset Percentage Coupon S20                           | 099999999990, 088888888880, 033333333330, 077777777770 |
        | 3             | discount   | Preset Percentage Discount S30 | MM Item G, Sale Item C, Preset Percentage Discount S30              | 099999999990, 088888888880, 033333333330, 077777777770 |
        | 3             | coupon     | Preset Percentage Coupon S20   | MM Item G, Sale Item C, Preset Percentage Coupon S20                | 099999999990, 088888888880, 033333333330, 077777777770 |
        | 4             | discount   | Preset Percentage Discount S30 | Sale Item B, MM Item G, Sale Item C, Preset Percentage Discount S30 | 099999999990, 088888888880, 033333333330, 077777777770 |
        | 4             | coupon     | Preset Percentage Coupon S20   | Sale Item B, MM Item G, Sale Item C, Preset Percentage Coupon S20   | 099999999990, 088888888880, 033333333330, 077777777770 |
