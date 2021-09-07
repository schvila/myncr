@pos @charity
Feature: Charity Round Up
    This feature targets the usage of charity round up button. Pressing this button will add Donation item to the transaction that will round balance up to the nearest dollar.
    To be able to see the button on tender frame, parameter tender_mode_2 should be set to the tender_mode_2 = original_value + 256, and control parameter 1241 should be set
    to external ID value of the Donation item.

    Scenarios that will be tested/covered by SIT team:
        - Swipe/Insert/Tap ahead payment
        - Payment with dual purpose (Loyalty + Payment) card


    Background: POS is ready to sell and no transaction is in progress
        Given the POS has essential configuration
        And the EPS simulator has essential configuration
        # Set Charity donation round up item External ID option to external ID of Donation item
        And the POS control parameter 1241 is set to 224466
        And the POS has following tenders configured
        | tender_id   | description      | tender_type_id | exchange_rate | currency_symbol | external_id  | tender_mode_2 | tender_ranking |
        | 70000000023 | Cash             | 1              | 1             | $               | 70000000023  | 272           | 1              |
        | 70000000024 | Check            | 2              | 1             | $               | 70000000024  | 256           | 2              |
        | 70000000025 | Credit           | 3              | 1             | $               | 70000000025  | 385           | 2              |
        And the pricebook contains charity item
        | description   | barcode    | item_id   | price | external_id | credit_category |
        | Donation item | 0789001112 | 789001112 | 0.0   | 224466      | 0555            |
        And the POS has following sale items configured
        | barcode      | description | price  |
        | 099999999990 | Sale Item A | 0.99   |
        | 088888888880 | Sale Item B | 1.99   |
        | 033333333330 | Sale Item G | 0.69   |


    @positive @fast
    Scenario Outline: Select charity round up button on a tender frame, Donation item is added into the transaction,
                the transaction total is rounded to the nearest dollar, the transaction tax amount remains the same.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the cashier presses Charity Round up button after selecting <tender_type> tender
        Then the POS displays Ask tender amount <tender_type> frame
        And an item Donation item with price 0.94 is in the virtual receipt
        And an item Donation item with price 0.94 is in the current transaction
        And the total from current transaction is rounded to 2.00
        And the tax amount from current transaction is 0.07

        Examples:
        | tender_type       |
        | cash              |
        | credit            |
        | check             |


    @negative @fast
    Scenario: Set Charity donation round up item External ID to incorrect value, select charity round up button on a tender frame,
             the POS displays Item not found error frame.
        # Set Charity donation round up item External ID option to invalid external ID
        Given the POS control parameter 1241 is set to 1111111
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the cashier presses Charity Round up button after selecting cash tender
        Then the POS displays Item not found error


    @positive @fast
    Scenario: Add MRD card into the transaction, select charity round up button on a tender frame,
              Donation item is added into the transaction, the transaction total is rounded to the nearest dollar.
        Given the POS recognizes MRD card role
        And the POS recognizes following cards
        | card_definition_id | card_role  | card_name | barcode_range_from | card_definition_group_id |
        | 1                  | 1          | MRD card  | 00002255           | 70000000020              |
        And the POS has following discounts configured
        | description     | price  | external_id | card_definition_group_id |
        | MRD             | 0.50   | 1           | 70000000020              |
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the cashier scanned a MRD card with barcode 00002255
        When the cashier presses Charity Round up button after selecting cash tender
        Then the POS displays Ask tender amount cash frame
        And an item Donation item with price 0.44 is in the virtual receipt
        And an item Donation item with price 0.44 is in the current transaction
        And a triggered discount MRD with value of 0.50 is in the virtual receipt
        And a triggered discount MRD with value of 0.50 is in the current transaction
        And the total from current transaction is rounded to 1.00
        And the tax amount from current transaction is 0.07


    @positive @fast
    Scenario Outline: Add loyalty into the transaction, select charity round up button on a tender frame, Donation item is added into the transaction,
                    the transaction total is rounded to the nearest dollar.
        Given the Sigma simulator has essential configuration
        And the POS has the feature Loyalty enabled
        And the Sigma recognizes following cards
            | card_number       | card_description |
            | <card>            | Happy Card       |
        And an item <description> with barcode <barcode> and price <price> is eligible for discount <type> <discount> when using loyalty card <card>
        And the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And a loyalty card <card> with description Happy Card is present in the transaction
        When the cashier presses Charity Round up button after selecting cash tender
        Then the POS displays Ask tender amount cash frame
        And an item Donation item with price 0.48 is in the virtual receipt
        And an item Donation item with price 0.48 is in the current transaction
        And a RLM discount Loyalty Discount with value of <awarded_discount> is in the virtual receipt
        And a RLM discount Loyalty Discount with value of <awarded_discount> is in the current transaction
        And the total from current transaction is rounded to 1.00
        And the tax amount from current transaction is 0.03

        Examples:
        | barcode      | description | price | type       | discount | card              | awarded_discount |
        | 099999999990 | Sale Item A | 0.99  | cash       | 0.50     | 12879784762398321 | -0.50            |



    @positive @fast
    Scenario Outline: Add coupons/discounts with/without tax reduction allowed in the transaction, select charity round up button on a tender frame,
                    the Donation item is in the transaction, the transaction total is rounded to the nearest dollar,
                    the transaction tax amount is reduced in case of the tax reduction allowed.
        Given the pricebook contains coupons
        | description                   | reduction_value | disc_type        | disc_mode         | disc_quantity   | reduces_tax |
        | Preset Percentage Coupon 20   | 200000          | PRESET_PERCENT   | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |             |
        | Preset Percentage Coupon S20  | 200000          | PRESET_PERCENT   | SINGLE_ITEM       | ALLOW_ONLY_ONCE | True        |
        And the pricebook contains discounts
        | description                   | reduction_value | disc_type      | disc_mode         | disc_quantity   | reduces_tax |
        | Preset Percentage Discount 30 | 300000          | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |             |
        | Preset Percentage Discount S30| 300000          | PRESET_PERCENT | SINGLE_ITEM       | ALLOW_ONLY_ONCE | True        |
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction 2 times
        And the cashier added a <type> <name>
        When the cashier presses Charity Round up button after selecting cash tender
        Then the POS displays Ask tender amount cash frame
        And an item Donation item with price <donation_amount> is in the virtual receipt
        And an item Donation item with price <donation_amount> is in the current transaction
        And a <type> <name> with value of <discount_amount> is in the virtual receipt
        And the total from current transaction is rounded to <total_amount>
        And the tax amount from current transaction is <tax_amount>

        Examples:
        | type      | name                          | discount_amount | donation_amount | total_amount | tax_amount |
        | coupon    | Preset Percentage Coupon 20   | 0.40            | 0.28            | 2.00         | 0.14       |
        | coupon    | Preset Percentage Coupon S20  | 0.20            | 0.09            | 2.00         | 0.13       |
        | discount  | Preset Percentage Discount 30 | 0.59            | 0.47            | 2.00         | 0.14       |
        | discount  | Preset Percentage Discount S30| 0.30            | 0.20            | 2.00         | 0.12       |


    @positive @fast
    Scenario Outline: Add autocombos into the transaction, select charity round up button on a tender frame,
                    the Donation item is in the transaction, the transaction total is rounded to the nearest dollar.
        Given the pricebook contains autocombos
        | description         | reduction_value | disc_type           | disc_mode         | disc_quantity | item_name   | quantity |
        | 2As Combo           | 17800           | AUTO_COMBO_AMOUNT   | WHOLE_TRANSACTION | ALLOW_ALWAYS  | Sale Item A | 2        |
        And the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction <quantity> times
        When the cashier presses Charity Round up button after selecting cash tender
        Then the POS displays Ask tender amount cash frame
        And an item Donation item with price <donation_amount> is in the virtual receipt
        And an item Donation item with price <donation_amount> is in the current transaction
        And the autocombo <autocombo> with discount of <discount> is in the current transaction
        And the autocombo <autocombo> with discount of <discount> is in the virtual receipt
        And the total from current transaction is rounded to 2.00
        And the tax amount from current transaction is 0.13

        Examples:
        | autocombo         | barcode      | quantity | discount | donation_amount |
        | 2As Combo         | 099999999990 | 2        | 0.20     | 0.09            |


    @positive @fast
    Scenario: Pump is prepaid for a not rounded amount, select charity round up button on a tender frame,
              the Donation item is in the transaction, the transaction total is rounded to the nearest dollar.
        # Set Fuel credit prepay method to Auth and Capture
        Given the POS option 1851 is set to 1
        # Set Prepay Grade Select Type option as One Touch
        And the POS option 5124 is set to 1
        And the POS is in a ready to sell state
        And the cashier selected a Premium grade prepay at pump 1
        And the cashier enters price 20.48 to prepay pump
        When the cashier presses Charity Round up button after selecting cash tender
        Then the POS displays Ask tender amount cash frame
        And an item Donation item with price 0.52 is in the virtual receipt
        And an item Donation item with price 0.52 is in the current transaction
        And the total from current transaction is rounded to 21.00


    @positive @fast
    Scenario: Pump is prepaid for a rounded amount, select charity round up button on tender frame,
            the Donation item is not in the transaction, the Charity round up button is disabled.
        # Set Fuel credit prepay method to Auth and Capture
        Given the POS option 1851 is set to 1
        # Set Prepay Grade Select Type option as One Touch
        And the POS option 5124 is set to 1
        And the POS is in a ready to sell state
        And the cashier selected a Premium grade prepay at pump 1
        And the cashier enters price 20.00 to prepay pump
        When the cashier presses the cash tender button
        Then the POS displays Ask tender amount cash frame
        And the Charity Round up button on cash tender frame is disabled


    @positive @fast
    Scenario: Add Rest in gas item into the transaction with donation item present,
                tender the transaction with amount larger than rounded balance, validate the pump is prepaid for residual amount
        # Set Fuel credit prepay method to Auth and Capture
        Given the POS option 1851 is set to 1
        # Set Prepay Grade Select Type option as One Touch
        And the POS option 5124 is set to 1
        # Set Display Rest in Gas button to Yes
        And the POS option 5130 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the cashier selected a Premium grade prepay at pump 1
        And a prepay item Rest in gas:Prem with price 0.00 is in the current transaction
        And the Donation item with price 0.94 is present in the transaction after using Charity roundup button on cash tender frame
        And the total from current transaction is rounded to 2.00
        And the cashier tendered the transaction with 10.00 amount in cash
        When the manager enters 2345 pin on Ask security override frame
        Then the transaction is finalized
        And a pump 1 is authorized with a price of 8.00


    @positive @fast
    Scenario: Add Donation item into the transaction, attempt to press charity round up button once more time, the button is disabled.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the Donation item with price 0.94 is present in the transaction after using Charity roundup button on cash tender frame
        When the cashier presses the cash tender button
        Then the POS displays Ask tender amount cash frame
        And the Charity Round up button on cash tender frame is disabled
        And the total from current transaction is rounded to 2.00


    @positive @fast
    Scenario Outline: Split tender in a transaction with a restricted item, charity round up during both tenders,
                       transaction total is rounded to the nearest dollar twice.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And a lottery ticket PDI Instant Lottery Tx with price 2.50 is present in the transaction
        And the cashier pressed Charity Round up button after selecting <tender_type> tender
        And the cashier tendered the transaction with exact-dollar on the current frame
        When the cashier presses Charity Round up button after selecting cash tender
        Then the POS displays Ask tender amount cash frame
        And an item Donation item with price 0.94 is in the virtual receipt
        And an item Donation item with price 0.50 is in the virtual receipt
        And an item Donation item with price 0.94 is in the current transaction
        And an item Donation item with price 0.50 is in the current transaction
        And the total from current transaction is rounded to 3.00

        Examples:
        | tender_type       |
        | credit            |
        | check             |


    @positive @fast
    Scenario: Add lottery redemption item in the transaction, charity round up button is disabled on tender frame.
        Given the POS is in a ready to sell state
        And a lottery redemption item PDI Instant Lottery Tx with price 2.50 is present in the transaction
        When the cashier presses the cash tender button
        Then the POS displays Ask tender amount cash frame
        And the Charity Round up button on cash tender frame is disabled


    @positive @fast
    Scenario Outline: Split tender, add additional items after first charity round up,
                       transaction total is rounded to the nearest dollar twice.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the cashier pressed Charity Round up button after selecting <tender_type_1> tender
        And the cashier pressed Go back button
        And the total from current transaction is rounded to 2.00
        And an item with barcode 088888888880 is present in the transaction 2 times
        When the cashier presses Charity Round up button after selecting <tender_type_2> tender
        Then the POS displays Ask tender amount <tender_type_2> frame
        And an item Donation item with price 0.94 is in the virtual receipt
        And an item Donation item with price 0.74 is in the virtual receipt
        And an item Donation item with price 0.94 is in the current transaction
        And an item Donation item with price 0.74 is in the current transaction
        And the total from current transaction is rounded to 7.00
        And the tax amount from current transaction is 0.35

        Examples:
        | tender_type_1     | tender_type_2 |
        | credit            | cash          |
        | check             | cash          |


    @positive @fast
    Scenario: The transaction balance is rounded value, select charity round up button on tender frame,
              the Donation item is not in the transaction, the Charity round up button is disabled.
        Given the POS is in a ready to sell state
        And an item with barcode 033333333330 is present in the transaction 12 times
        And the total from current transaction is rounded to 7.00
        When the cashier presses the cash tender button
        Then the POS displays Ask tender amount cash frame
        And the Charity Round up button on cash tender frame is disabled


    @positive @fast
    Scenario: Finalize the tranaction with Donation item present
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the Donation item with price 0.94 is present in the transaction after using Charity roundup button on cash tender frame
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS displays main menu frame
        And the transaction is finalized


    @positive @fast
    Scenario: Recall a stored transaction with a donation item present, after the new transaction is started,
            the Donation item appears in the transaction with previously stored value
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the Donation item with price 0.94 is present in the transaction after using Charity roundup button on cash tender frame
        And the cashier stored the transaction
        And an item with barcode 033333333330 is present in the transaction
        When the cashier recalls the last stored transaction
        Then the POS displays main menu frame
        And an item Donation item with price 0.94 is in the virtual receipt
        And an item Donation item with price 0.94 is in the current transaction
        And the tax amount from current transaction is 0.12


    @positive @fast
    Scenario Outline: Add manufacturer coupon with no tax reduction in the transaction, select charity round up button on a tender frame,
                      the Donation item is in the transaction, the transaction total is rounded to the nearest dollar.
        # Allow manufacturer coupons set to Yes
        Given the POS option 1109 is set to 1
        # Manufacturer coupon reduces tax set to No
        And the POS option 1111 is set to 0
        And the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        And the cashier scanned coupon <mfc_barcode> of type UPC_EAN
        When the cashier presses Charity Round up button after selecting cash tender
        Then the POS displays Ask tender amount cash frame
        And the transaction contains a manufacturer coupon with a discount value of <mfc_price>
        And the coupon with price <mfc_price> is in the virtual receipt
        And an item Donation item with price <donation_amount> is in the virtual receipt
        And an item Donation item with price <donation_amount> is in the current transaction
        And the total from current transaction is rounded to <total_amount>
        And the tax amount from current transaction is <tax_amount>

        Examples:
        | item_barcode | mfc_barcode  | mfc_price | total_amount | tax_amount| donation_amount |
        | 066666666660 | 566666000254 | 0.25      | 3.00         | 0.17      | 0.69            |
        | 099999999990 | 599999000257 | 0.25      | 1.00         | 0.07      | 0.19            |


    @positive @fast
    Scenario Outline: Add manufacturer coupon with tax reduction allowed in the transaction, select charity round up button on a tender frame,
                      the Donation item is in the transaction, the transaction total is rounded to the nearest dollar, the transaction tax amount is reduced.
        # Allow manufacturer coupons set to Yes
        Given the POS option 1109 is set to 1
        # Manufacturer coupon reduces tax set to Yes
        And the POS option 1111 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        And the cashier scanned coupon <mfc_barcode> of type UPC_EAN
        When the cashier presses Charity Round up button after selecting cash tender
        Then the POS displays Ask tender amount cash frame
        And the transaction contains a manufacturer coupon with a discount value of <mfc_price>
        And the coupon with price <mfc_price> is in the virtual receipt
        And an item Donation item with price <donation_amount> is in the virtual receipt
        And an item Donation item with price <donation_amount> is in the current transaction
        And the total from current transaction is rounded to <total_amount>
        And the tax amount from current transaction is <tax_amount>

        Examples:
        | item_barcode | mfc_barcode  | mfc_price | total_amount | tax_amount| donation_amount |
        | 066666666660 | 566666000254 | 0.25      | 3.00         | 0.15      | 0.71            |
        | 099999999990 | 599999000257 | 0.25      | 1.00         | 0.05      | 0.21            |


    @positive @fast
    Scenario: The transaction is switched to refund and an item was added, select tender, the Charity round up button is not displayed.
        Given the POS is in a ready to sell state
        And the transaction is switched to refund
        And an item with barcode 099999999990 is present in the transaction
        When the cashier presses the cash tender button
        Then the POS displays Ask tender amount cash frame
        And the Charity Round up button on cash tender frame is not displayed


    @positive @fast
    Scenario Outline: Add an item to the transaction with a linked deposit item, select charity round up button on a tender frame,
                      the Donation item is in the transaction, the transaction total is rounded to the nearest dollar.
        Given the POS is in a ready to sell state
        And the cashier selected an item with barcode <item_barcode> on the main menu
        When the cashier presses Charity Round up button after selecting cash tender
        Then the POS displays Ask tender amount cash frame
        And an item <item_name> with price <price> is in the virtual receipt
        And an item <item_name> with price <price> is in the current transaction
        And a deposit <deposit_item> with price <deposit_price> is in the virtual receipt
        And a deposit <deposit_item> with price <deposit_price> is in the current transaction
        And an item Donation item with price 0.57 is in the virtual receipt
        And an item Donation item with price 0.57 is in the current transaction
        And the total from current transaction is rounded to 2.00
        And the tax amount from current transaction is 0.09

        Examples:
        | item_barcode | item_name      | price | deposit_item            | deposit_price |
        | 055555555550 | Container Item | 1.29  | Deposit (for Container) | 0.05          |


    @positive @fast
    Scenario Outline: Add a deposit item in the transaction, select charity round up button on tender frame,
              the Donation item is not in the transaction, the Charity round up button is disabled.
        Given the POS is in a ready to sell state
        And the POS displays Container Deposit Redemption frame
        And the cashier entered a barcode <barcode> of an item with a container
        When the cashier presses the cash tender button
        Then the POS displays Ask tender amount cash frame
        And the Charity Round up button on cash tender frame is disabled
        And an item <refund_item> with refund value of <value> is in the current transaction

        Examples:
        | barcode    | refund_item             | value  |
        | 5555555555 | Deposit (for Container) | 0.05   |


    @positive @fast
    Scenario Outline: Configure HDD PDL discount. Add an item to the transaction, round transaction balance using charity round up button,
    tender transaction with credit, validate Donation item and PDL discount are in the transaction.
        Given the pricebook contains discounts
        | description | reduction_value | disc_type      | disc_mode         | disc_quantity   | external_id | reduces_tax |max_quantity|
        | PDL perc    | 0               | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE | Z003        | false       | 0          |
        | PDL unit    | 0               | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE | Z001        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount <discount> for dry stock
        And the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And the total from current transaction is rounded to <credit_amount> after using charity roundup button on <type> tender frame with donation <donation>
        When the cashier tenders the transaction with hotkey exact_dollar in <type>
        Then a PDL discount <pdl_description> is in the virtual receipt
        And a PDL discount <pdl_description> with price <discount_total> is in the previous transaction
        And an item Donation item with price <donation_amount> is in the virtual receipt
        And a tender credit with amount <final_amount> is in the previous transaction

        Examples:
        | barcode      | type       | discount | discount_total | credit_amount | donation | donation_amount | disc_type | pdl_description | final_amount |
        | 099999999990 | credit     | 0.10     | 0.10           | 2.00          | 0.94     | 0.04            | percent   | PDL perc        | 1.00         |
        | 099999999990 | credit     | 1.00     | 0.01           | 2.00          | 0.94     | 0.95            | unit      | PDL unit        | 2.00         |


    @positive @fast
    Scenario Outline: Configure HDD PDL discount. Add an item to the transaction with loyalty card,
    round transaction balance using charity round up button, tender transaction with credit, validate Donation item,
    PDL discount, and loyalty discounts are in the transaction.
        Given the Sigma simulator has essential configuration
        And the POS has the feature Loyalty enabled
        And the POS option 4214 is set to 1
        And the Sigma recognizes following cards
            | card_number       | card_description |
            | <card>            | Happy Card       |
        And an item <description> with barcode <barcode> and price <price> is eligible for discount percentage 0.50 when using loyalty card <card>
        And the pricebook contains discounts
        | description | reduction_value | disc_type      | disc_mode         | disc_quantity   | external_id | reduces_tax |max_quantity|
        | PDL perc    | 0               | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE | Z003        | false       | 0          |
        | PDL unit    | 0               | PRESET_PERCENT | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE | Z001        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount <discount> for dry stock
        And the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And a loyalty card <card> with description Happy Card is present in the transaction
        And the total from current transaction is rounded to <credit_amount> after using charity roundup button on <type> tender frame with donation <donation>
        When the cashier tenders the transaction with hotkey exact_dollar in <type>
        Then a RLM discount Loyalty Discount with value of <awarded_discount> is in the virtual receipt
        And a RLM discount Loyalty Discount with value of <awarded_discount> is in the previous transaction
        And a PDL discount <pdl_description> is in the virtual receipt
        And a PDL discount <pdl_description> with price <discount_total> is in the previous transaction
        And an item Donation item with price <donation_amount> is in the virtual receipt
        And a tender credit with amount <credit_amount> is in the previous transaction

        Examples:
        | barcode      | description | price | type   | discount | discount_total  | card              | awarded_discount | credit_amount | donation | donation_amount | disc_type | pdl_description |
        | 099999999990 | Sale Item A | 0.99  | credit | 0.10     | 0.10            | 12879784762398321 | -0.50            | 1.00          | 0.48     | 0.58            | percent   | PDL perc        |
        | 099999999990 | Sale Item A | 0.99  | credit | 1.00     | 0.01            | 12879784762398321 | -0.50            | 1.00          | 0.48     | 0.49            | unit      | PDL unit        |