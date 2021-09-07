@pos @pes
Feature: Promotion Execution Service - fuel discounts
    This feature file covers test cases with PES discounts received in fuel transactions.

    Background: POS is configured for PES feature
        Given the POS has essential configuration
        And the EPS simulator has essential configuration
        And the POS is configured to communicate with PES
        # Cloud Loyalty Interface is set to PES
        And the POS option 5284 is set to 1
        # Default Loyalty Discount Id is set to PES_basic
        And the POS parameter 120 is set to PES_basic
        # Promotion Execution Service Allow partial discounts is set to Yes
        And the POS option 5278 is set to 1
        # Set Fuel credit prepay method to Auth and Capture
        And the POS option 1851 is set to 1
        And the POS has following discounts configured
            | reduction_id | description | price | external_id |
            | 1            | PES loyalty | 0.00  | PES_basic   |
        And the pricebook contains PES loyalty tender
        And the nep-server has default configuration
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id             | unit_type              | is_apply_as_tender |
            | 004            | Premium Tender       | 10.00          | transaction    | premium tender           | GENERAL_SALES_QUANTITY | True               |


    @fast @positive
    Scenario Outline: Dispense fuel on pump for exact/higher price than the discount, the PES tender appears in the VR after the postpay fuel is added to the transaction.
        Given the POS is in a ready to sell state
        And the customer dispensed Premium for <fuel_price> price at pump 2
        When the cashier adds a postpay from pump 2 to the transaction
        Then a fuel item <item_name> with price <fuel_price> and prefix P2 is in the virtual receipt
        And a fuel item Premium with price <fuel_price> and volume <gallons> is in the current transaction
        And a tender Premium Tender with amount 10.00 is in the virtual receipt
        And a tender Premium Tender with amount 10.00 is in the current transaction

        Examples:
        | item_name      | fuel_price | gallons |
        | 2.500G Premium | 10.00      | 2.5     |
        | 3.750G Premium | 15.00      | 3.75    |


    @fast @positive
    Scenario: Dispense fuel on pump under the discount price, the PES tender appears in the VR after the postpay fuel is added to the transaction.
        Given the POS is in a ready to sell state
        And the customer dispensed Premium for 5.00 price at pump 2
        When the cashier adds a postpay from pump 2 to the transaction
        Then a fuel item 1.250G Premium with price 5.00 and prefix P2 is in the virtual receipt
        And a fuel item Premium with price 5.00 and volume 1.25 is in the current transaction
        And a tender Premium Tender with amount 5.00 is in the virtual receipt
        And a tender Premium Tender with amount 5.00 is in the current transaction


    @fast @positive
    Scenario Outline: Dispense fuel on pump over or exact the discount price, the PES tender appears in the VR after the subtotal.
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        Given the POS option 5277 is set to 1
        And the POS is in a ready to sell state
        And a Premium postpay fuel with <fuel_price> price on pump 2 is present in the transaction
        When the cashier presses the cash tender button
        Then a fuel item <item_name> with price <fuel_price> and prefix P2 is in the virtual receipt
        And a fuel item Premium with price <fuel_price> and volume <gallons> is in the current transaction
        And a tender Premium Tender with amount 10.00 is in the virtual receipt
        And a tender Premium Tender with amount 10.00 is in the current transaction

        Examples:
        | item_name      | fuel_price | gallons |
        | 2.500G Premium | 10.00      | 2.5     |
        | 3.750G Premium | 15.00      | 3.75    |


    @fast @positive
    Scenario: Dispense fuel on pump under the discount price, the PES tender appears in the VR after the subtotal with value of dispensed fuel.
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        Given the POS option 5277 is set to 1
        And the POS is in a ready to sell state
        And a Premium postpay fuel with 5.00 price on pump 2 is present in the transaction
        When the cashier presses the cash tender button
        Then a fuel item 1.250G Premium with price 5.00 and prefix P2 is in the virtual receipt
        And a fuel item Premium with price 5.00 and volume 1.25 is in the current transaction
        And a tender Premium Tender with amount 5.00 is in the virtual receipt
        And a tender Premium Tender with amount 5.00 is in the current transaction


    @fast @negative
    Scenario: Dispense fuel on pump while nep server is offline, the PES tender does not appear in the VR after the subtotal.
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        Given the POS option 5277 is set to 1
        And the POS is in a ready to sell state
        And a Premium postpay fuel with 10.00 price on pump 2 is present in the transaction
        And the nep-server is offline
        When the cashier presses the cash tender button
        Then the POS displays Ask tender amount cash frame
        And a tender Premium Tender is not in the virtual receipt
        And a tender Premium Tender is not in the current transaction


    @fast
    Scenario Outline: Customer performs PAP transaction, verify the transaction was tendered using PES discounts
        Given the POS is in a ready to sell state
        And the customer performed PAP transaction on pump 2 for amount <dispensed_amount> with PES discount applied as tender
        And the POS displays Scroll previous frame
        When the cashier selects last transaction on the Scroll previous list
        Then a fuel item <fuel_item> with price <dispensed_amount> and prefix P2 is in the virtual receipt
        And a loyalty discount <discount> with value of <dispensed_amount> and quantity 1 is in the virtual receipt
        And a tender Credit with amount 0.00 is in the virtual receipt

        Examples:
        | fuel_item       | discount | dispensed_amount |
        | 10.000G Regular | EMReward | 50.00            |


    @fast
    Scenario Outline: Customer performs PAP transaction, the transaction is tendered partially using PES discounts and credit
        Given the POS is in a ready to sell state
        And the customer performed PAP transaction on pump 2 for amount <dispensed_amount> partially tendered with PES discount for value <discount_value>
        And the POS displays Scroll previous frame
        When the cashier selects last transaction on the Scroll previous list
        Then a fuel item <fuel_item> with price <dispensed_amount> and prefix P2 is in the virtual receipt
        And a loyalty discount <discount> with value of <discount_value> and quantity 1 is in the virtual receipt
        And a tender Credit with amount <credit_value> is in the virtual receipt

        Examples:
        | fuel_item       | discount | dispensed_amount | discount_value | credit_value |
        | 10.000G Regular | EMReward | 20.00            | 10.00          | 10.00        |


    @fast
    Scenario: Grade selection is disabled. Create a FPR discount to be triggered by loyalty card, tender prepaid fuel, verify the discount is added to the transaction.
        # Set Prepay Grade Select Type option as None
        Given the POS option 5124 is set to 0
        And the POS recognizes following PES cards
            | card_definition_id | card_role  | card_name     | barcode_range_from     | barcode_range_to       | card_definition_group_id | track_format_1 | track_format_2 | mask_mode |
            | 70000001142        | 3          | PES card      | 3104174102936582       | 3104174102936583       | 70000010042              | bt%at?         | bt;at?         | 21        |
        And the POS has FPR discount configured
            | description    | reduction_value | disc_type           | disc_mode   | disc_quantity   |
            | Loyalty FPR    | 2000            | FUEL_PRICE_ROLLBACK | SINGLE_ITEM | ALLOW_ONLY_ONCE |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And a prepay with price 5.00 on the pump 1 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then a pump 1 is authorized with a price of 5.00
        And a FPR discount Loyalty FPR is in the previous transaction


    @fast
    Scenario: Grade selection is disabled. Create a FPR discount to be triggered by loyalty card, dispense prepaid fuel, verify the discount is added to the transaction and
              correct amount of fuel is dispensed.
        # Set Prepay Grade Select Type option as None
        Given the POS option 5124 is set to 0
        And the POS recognizes following PES cards
            | card_definition_id | card_role  | card_name     | barcode_range_from     | barcode_range_to       | card_definition_group_id | track_format_1 | track_format_2 | mask_mode |
            | 70000001142        | 3          | PES card      | 3104174102936582       | 3104174102936583       | 70000010042              | bt%at?         | bt;at?         | 21        |
        And the POS has FPR discount configured
            | description    | reduction_value | disc_type           | disc_mode   | disc_quantity   |
            | Loyalty FPR    | 2000            | FUEL_PRICE_ROLLBACK | SINGLE_ITEM | ALLOW_ONLY_ONCE |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And a prepay with price 5.00 on the pump 1 is present in the transaction
        And the cashier tendered transaction with cash
        When the customer dispenses Premium fuel for 5.00 price on the pump 1
        Then a FPR discount Loyalty FPR is in the previous transaction
        And a fuel item Premium with price 5.00 and volume 1.250 is in the previous transaction