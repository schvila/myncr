@pos @prepay
Feature: Classic and smart prepays
    This feature file focuses on pre-pay fuel transactions.

    Background: POS is ready to sell and no transaction is in progress
        Given the POS has essential configuration
        And the EPS simulator has essential configuration
        # Set Fuel credit prepay method to Auth and Capture
        And the POS option 1851 is set to 1
        # Set Prepay Grade Select Type option as One Touch
        And the POS option 5124 is set to 1
        And the POS has the feature Loyalty enabled
        And the Sigma simulator has essential configuration
        And the Sigma recognizes following cards
            | card_number       | card_description |
            | 12879784762398321 | Happy Card       |


    @fast @positive
    Scenario: Enter amount frame is displayed after cashier presses a prepay button (smart prepay with grade selection not enabled).
        # Set Prepay Grade Select Type option as None
        Given the POS option 5124 is set to 0
        And the POS is in a ready to sell state
        When the cashier presses the prepay button on POS
        Then the POS displays frame for enter amount to prepay


    @fast @positive
    Scenario: Grade selection frame is displayed after cashier presses a prepay button (smart prepay with grade selection enabled).
        Given the POS is in a ready to sell state
        When the cashier presses the prepay button on POS
        Then the POS displays frame for the grade selection


    @fast @positive
    Scenario Outline: Prepay amount selection frame is displayed after cashier presses a prepay grade button (smart prepay with grade selection enabled).
        Given the POS is in a ready to sell state
        And the cashier pressed the prepay button for pump <pump_id>
        When the cashier selects <grade> grade
        Then the POS displays frame for enter amount to prepay

        Examples:
            | grade    | pump_id |
            | Midgrade | 1       |
            | Diesel   | 2       |


    @fast @positive
    Scenario Outline: Prepay is added into transaction after cashier enters prepay amount and pump is not authorized.
        Given the POS is in a ready to sell state
        And the cashier selected a <grade_type> grade prepay at pump <pump_id>
        When the cashier enters price <price> to prepay pump
        Then an item <prepay_grade> with price <price> is in the virtual receipt
        And a prepay item <prepay_grade> with price <price> is in the current transaction
        And a pump <pump_id> is not authorized

        Examples:
            | grade_type | prepay_grade   | price | pump_id |
            | Premium    | Prepay:Premium | 25.00 | 1       |
            | Regular    | Prepay:Regular | 30.00 | 2       |


    @fast @positive @smoke
    Scenario Outline: Pump is prepaid for the correct amount after the prepay is tendered.
        Given the POS is in a ready to sell state
        And the cashier selected a <grade_type> grade prepay at pump 1
        And the cashier enters price <amount> to prepay pump
        When the cashier tenders the transaction with amount <amount> in <tender_type>
        Then the POS displays main menu frame
        And the transaction is finalized
        And a tender <tender_type> with amount <amount> is in the previous transaction
        And a pump 1 is authorized with a price of <amount>

        Examples:
            | grade_type | amount | tender_type |
            | Premium    | 25.00  | Cash        |
            | Regular    | 30.00  | Credit      |


    @fast @positive @smoke
    Scenario Outline: Fully dispense the prepaid fuel, prepay completion transaction is finalized.
        Given the POS is in a ready to sell state
        And a <grade_type> prepay for pump <pump_id> with a price of <price> is tendered in <tender_type> and finalized
        When the customer dispenses <grade_type> fuel for <price> price on the pump <pump_id>
        Then a fuel item <grade_type> with price <price> and volume <volume> is in the previous transaction
        And the POS finalizes the prepay completion transaction for price <price> at pump <pump_id>

        Examples:
            | grade_type | price | volume | tender_type | pump_id |
            | Premium    | 25.00 | 6.25   | Cash        | 1       |
            | Midgrade   | 20.00 | 6.25   | Credit      | 2       |


    @fast @positive
    Scenario Outline: Partially dispense the fuel prepaid by non-electronic tender, refund amount button is displayed.
        Given the POS is in a ready to sell state
        And a <grade_type> prepay for pump <pump_id> with a price of <prepay_amount> is tendered in cash and finalized
        When the customer dispenses <grade_type> fuel for <dispense_price> price on the pump <pump_id>
        Then the POS displays <refund_amount> refund on pump <pump_id>

        Examples:
            | grade_type | prepay_amount | dispense_price | dispense_volume | refund_amount | pump_id |
            | Premium    | 25.00         | 20.00          | 5.00            | 5.00          | 1       |
            | Premium    | 25.00         | 12.00          | 3.00            | 13.00         | 2       |


    @fast @positive
    Scenario Outline: Partially dispense the fuel prepaid by electronic tender, dispensed amount gets captured automatically,
                      completion transaction is finalized.
        Given the POS is in a ready to sell state
        And a <grade_type> prepay for pump <pump_id> with a price of <prepay_amount> is tendered in credit and finalized
        When the customer dispenses <grade_type> fuel for <dispense_price> price on the pump <pump_id>
        Then a fuel item <grade_type> with price <dispense_price> and volume <dispense_volume> is in the previous transaction
        And a tender credit with amount <dispense_price> is in the previous transaction

        Examples:
            | grade_type | prepay_amount | dispense_price | dispense_volume | pump_id |
            | Premium    | 25.00         | 21.00          | 5.00            | 1       |
            | Premium    | 25.00         | 12.60          | 3.00            | 2       |


    @fast @positive
    Scenario Outline: Refund an underdispensed prepay tendered by non-electronic tender, customer receives change back,
                      completion transaction is finalized.
        Given the POS is in a ready to sell state
        And a <grade_type> prepay for pump <pump_id> with a price of <prepay_amount> is tendered in cash and finalized
        And the customer dispensed prepaid <grade_type> fuel for <dispense_price> price on the pump <pump_id>
        When the cashier refunds the fuel from pump <pump_id>
        Then a fuel item <grade_type> with price <dispense_price> and volume <dispense_volume> is in the previous transaction
        And a tender cash with amount <prepay_amount> is in the previous transaction
        And a tender cash with amount -<refund_amount> is in the previous transaction

        Examples:
            | grade_type | prepay_amount | dispense_price | dispense_volume | refund_amount | pump_id |
            | Premium    | 25.00         | 20.00          | 5.00            | 5.00          | 1       |


    @fast @positive
    Scenario: Grade selection is enabled. Add Rest in gas item to the transaction.
        # Set Display Rest in Gas button to Yes
        Given the POS option 5130 is set to 1
        And the POS is in a ready to sell state
        And the cashier selected a Premium grade prepay at pump 1
        When the cashier selects Rest in gas button on Prepay amount frame
        Then a prepay item Rest in gas:Prem with price 0.00 is in the current transaction


    @fast @positive
    Scenario: Grade selection is disabled. Add Rest in gas item to the transaction.
        # Set Prepay Grade Select Type option as None
        Given the POS option 5124 is set to 0
        # Set Display Rest in Gas button to Yes
        And the POS option 5130 is set to 1
        And the POS is in a ready to sell state
        And the cashier pressed the prepay button for pump 1
        When the cashier selects Rest in gas button on Prepay amount frame
        Then a prepay item Rest in gas with price 0.00 is in the current transaction


    @fast @positive
    Scenario: Grade selection is enabled. Attempt to tender the transaction with only Rest in gas item present in the transaction,
        the POS displays Cancel Rest in gas item prompt.
        # Set Display Rest in Gas button to Yes
        Given the POS option 5130 is set to 1
        And the POS is in a ready to sell state
        And the cashier selected a Premium grade prepay at pump 1
        And a prepay item Rest in gas:Prem with price 0.00 is in the current transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS displays Cancel Rest in gas prompt


    @fast @positive
    Scenario: Grade selection is enabled. Add Rest in gas item to the transaction, tender the transaction with amount larger than balance,
        the pump is prepaid with extra amount.
        # Set Display Rest in Gas button to Yes
        Given the POS option 5130 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the cashier selected a Premium grade prepay at pump 1
        And a prepay item Rest in gas:Prem with price 0.00 is in the current transaction
        And the cashier tendered the transaction with 10.00 amount in cash
        When the manager enters 2345 pin on Ask security override frame
        Then the transaction is finalized
        And a pump 1 is authorized with a price of 8.94


    @fast @positive
    Scenario: Grade selection is enabled. Transfer prepaid fuel from one pump to another, verify correct pump is being autorized for prepaid amount.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And the prepay of the fuel grade premium with price 5.00 at pump id 1 is present in the transaction
        And the transaction is finalized
        When the cashier transfers the prepay from pump 1 to pump 2
        Then a pump 2 is authorized with a price of 5.00


    @fast @positive
    Scenario: Grade selection is disabled. Transfer prepaid fuel from one pump to another, verify correct pump is being autorized for prepaid amount.
        # Set Prepay Grade Select Type option as None
        Given the POS option 5124 is set to 0
        And the POS is in a ready to sell state
        And a prepay with price 5.00 on the pump 1 is present in the transaction
        And the transaction is finalized
        When the cashier transfers the prepay from pump 1 to pump 2
        Then a pump 2 is authorized with a price of 5.00


    @fast @positive
    Scenario: Grade selection is disabled. Create a FPR discount to be triggered by loyalty card, tender prepaid fuel,
              verify the FPR discount is added to the transaction.
        # Set Prepay Grade Select Type option as None
        Given the POS option 5124 is set to 0
        And the POS has FPR discount configured
        | description    | reduction_value | disc_type           | disc_mode   | disc_quantity   |
        | Loyalty FPR    | 2000            | FUEL_PRICE_ROLLBACK | SINGLE_ITEM | ALLOW_ONLY_ONCE |
        And the POS is in a ready to sell state
        And a prepay with price 5.00 on the pump 1 is present in the transaction
        And a loyalty card 12879784762398321 with description Happy Card is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the transaction is finalized
        And a pump 1 is authorized with a price of 5.00
        And a FPR discount Loyalty FPR is in the previous transaction


    @fast @manual
    # Fuel cannot be dispensed.
    Scenario: Grade selection is disabled. Create a FPR discount to be triggered by loyalty card, dispense prepaid fuel,
              verify the FPR discount is added to the transaction, and correct amount of fuel is dispensed.
        # Set Prepay Grade Select Type option as None
        Given the POS option 5124 is set to 0
        And the POS has FPR discount configured
        | description    | reduction_value | disc_type           | disc_mode   | disc_quantity   |
        | Loyalty FPR    | 2000            | FUEL_PRICE_ROLLBACK | SINGLE_ITEM | ALLOW_ONLY_ONCE |
        And the POS is in a ready to sell state
        And a prepay with price 5.00 on the pump 1 is present in the transaction
        And a loyalty card 12879784762398321 with description Happy Card is present in the transaction
        And the cashier tendered transaction with cash
        When the customer dispenses Premium fuel for 5.00 price on the pump 1
        Then a FPR discount Loyalty FPR is in the previous transaction
        And a fuel item Premium with price 5.00 and volume 1.316 is in the previous transaction