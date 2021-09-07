@pos @pos_security
Feature: POS Security
    This feature deals with POS security and the cashier/manager security rights
    Background: POS is properly configured
        Given the POS has essential configuration
        And the POS has the following operators with security rights configured
        | operator_id | pin  | last_name  | first_name | security_group_id | security_application_id | operator_role |
        | 70000000014 | 1234 | 1234       | Cashier    | 70000010          | 10                      | Cashier       |
        | 70000000015 | 2345 | 2345       | Manager    | 70000025          | 10                      | Manager       |
        And the POS has following sale items configured
        | barcode      | description | price  |
        | 066666666660 | Sale Item D | 1.99   |
        And the pricebook contains coupons
        | description                 | reduction_value | disc_type      | disc_mode         | disc_quantity   | required_security |
        | Preset Percentage Coupon L0 | 100000          | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |                   |
        | Preset Percentage Coupon L1 | 150000          | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE | LOW               |
        | Preset Percentage Coupon L2 | 200000          | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE | MEDIUM            |
        | Preset Percentage Coupon L3 | 300000          | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE | HIGH              |
        | Preset Percentage Coupon L4 | 400000          | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE | VERY_HIGH         |
        And the pricebook contains discounts
        | description                   | reduction_value | disc_type      | disc_mode         | disc_quantity   | required_security |
        | Preset Percentage Discount L0 | 100000          | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |                   |
        | Preset Percentage Discount L1 | 150000          | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE | LOW               |
        | Preset Percentage Discount L2 | 200000          | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE | MEDIUM            |
        | Preset Percentage Discount L3 | 300000          | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE | HIGH              |
        | Preset Percentage Discount L4 | 400000          | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE | VERY_HIGH         |

    @fast
    Scenario Outline: Cashier/manager adds a discount with a security level 0, discount appears in VR, select discount frame is displayed
        Given the POS is in a ready to start shift state
        And the <user> started a shift with PIN <pin>
        And an item with barcode 066666666660 is present in the transaction
        When the <user> adds a discount <discount>
        Then the POS displays main menu frame
        And a discount <discount> is in the current transaction
        And a discount <discount> with value of <value> is in the virtual receipt

        Examples:
        | user    | pin  | discount                      | value  |
        | cashier | 1234 | Preset Percentage Discount L0 | 0.24   |
        | manager | 2345 | Preset Percentage Discount L0 | 0.24   |


    @fast
    Scenario Outline: Cashier/manager adds a coupon with a security level 0, coupon appears in VR, main menu is displayed
        Given the POS is in a ready to start shift state
        And the <user> started a shift with PIN <pin>
        And an item with barcode 066666666660 is present in the transaction
        When the <user> adds a coupon <coupon>
        Then the POS displays main menu frame
        And a coupon <coupon> is in the current transaction
        And a coupon <coupon> with value of <value> is in the virtual receipt

        Examples:
        | user    | pin  | coupon                      | value  |
        | cashier | 1234 | Preset Percentage Coupon L0 | 0.24   |
        | manager | 2345 | Preset Percentage Coupon L0 | 0.24   |


    @fast
    Scenario Outline: Manager adds a discount with higher security level than 0, discount appears in VR, main menu frame is displayed
        Given the POS is in a ready to start shift state
        And the manager started a shift with PIN 2345
        And an item with barcode 066666666660 is present in the transaction
        When the manager adds a discount <discount>
        Then the POS displays main menu frame
        And a discount <discount> is in the current transaction
        And a discount <discount> with value of <value> is in the virtual receipt

        Examples:
        | discount                      | value  |
        | Preset Percentage Discount L1 | 0.36   |
        | Preset Percentage Discount L2 | 0.48   |
        | Preset Percentage Discount L3 | 0.72   |
        | Preset Percentage Discount L4 | 0.96   |


    @fast
    Scenario Outline: Manager adds a coupon with higher security level than 0, coupon appears in VR
        Given the POS is in a ready to start shift state
        And the manager started a shift with PIN 2345
        And an item with barcode 066666666660 is present in the transaction
        When the manager adds a coupon <coupon>
        Then the POS displays main menu frame
        And a coupon <coupon> is in the current transaction
        And a coupon <coupon> with value of <value> is in the virtual receipt

        Examples:
        | coupon                      | value  |
        | Preset Percentage Coupon L1 | 0.36   |
        | Preset Percentage Coupon L2 | 0.48   |
        | Preset Percentage Coupon L3 | 0.72   |
        | Preset Percentage Coupon L4 | 0.96   |


    @fast
    Scenario Outline: Cashier adds a discount with higher security level than 0, ask security override frame is displayed
        Given the POS is in a ready to start shift state
        And the cashier started a shift with PIN 1234
        And an item with barcode 066666666660 is present in the transaction
        When the cashier adds a discount <discount>
        Then the POS displays Ask security override frame

        Examples:
        | discount                      |
        | Preset Percentage Discount L1 |
        | Preset Percentage Discount L2 |
        | Preset Percentage Discount L3 |
        | Preset Percentage Discount L4 |


    @fast
    Scenario Outline: Manager enters pin on Ask security override frame, while cashier is adding a coupon with higher security level than 0,
                      main menu is displayed, coupon appears in VR
        Given the POS is in a ready to start shift state
        And the cashier started a shift with PIN 1234
        And an item with barcode 066666666660 is present in the transaction
        And the cashier added a coupon <coupon>
        When the manager enters 2345 pin on Ask security override frame
        Then the POS displays main menu frame
        And a coupon <coupon> is in the current transaction
        And a coupon <coupon> with value of <value> is in the virtual receipt

        Examples:
        | coupon                      | value  |
        | Preset Percentage Coupon L1 | 0.36   |
        | Preset Percentage Coupon L2 | 0.48   |
        | Preset Percentage Coupon L3 | 0.72   |
        | Preset Percentage Coupon L4 | 0.96   |


    @fast
    Scenario Outline: Manager enters pin on Ask security override frame, while cashier is adding a discount with higher security level than 0,
                      main menu is displayed, discount appears in VR
        Given the POS is in a ready to start shift state
        And the cashier started a shift with PIN 1234
        And an item with barcode 066666666660 is present in the transaction
        And the cashier added a discount <discount>
        When the manager enters 2345 pin on Ask security override frame
        Then the POS displays main menu frame
        And a discount <discount> is in the current transaction
        And a discount <discount> with value of <value> is in the virtual receipt

        Examples:
        | discount                      | value  |
        | Preset Percentage Discount L1 | 0.36   |
        | Preset Percentage Discount L2 | 0.48   |
        | Preset Percentage Discount L3 | 0.72   |
        | Preset Percentage Discount L4 | 0.96   |


    @fast
    Scenario Outline: Manager enters a wrong pin on ask security override frame, while cashier is attempting to add discount with security level 4,
                      an error is displayed
        Given the POS is in a ready to start shift state
        And the cashier started a shift with PIN 1234
        And an item with barcode 066666666660 is present in the transaction
        And the cashier added a discount <discount>
        When the manager enters 2222 pin on Ask security override frame
        Then the POS displays Operator not found error

        Examples:
        | discount                      |
        | Preset Percentage Discount L4 |


    @fast
    Scenario Outline: Manager enters a wrong pin on ask security override frame, while cashier is attempting to add coupon with security level 4,
                      an error is displayed
        Given the POS is in a ready to start shift state
        And the cashier started a shift with PIN 1234
        And an item with barcode 066666666660 is present in the transaction
        And the cashier added a coupon <coupon>
        When the manager enters 2222 pin on Ask security override frame
        Then the POS displays Operator not found error

        Examples:
        | coupon                      |
        | Preset Percentage Coupon L4 |