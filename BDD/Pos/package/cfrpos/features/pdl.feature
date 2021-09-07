@pos @pdl
Feature: PDL discounts
    This feature file focuses on both legacy and new approach to PDL discounts - meaning discounts awarded by epsilon.
    These discounts can be configured as a FPR/flat/percentage for a specific product code and card type. The new approach
    called HDD (Host Driven Discounts) also supports quantity limit for fuel. Percentage discounts are calculated pre-tax.

    Background: POS is ready to sell and no transaction is in progress
        Given the POS has essential configuration
        And the EPS simulator has essential configuration
        # Set Fuel credit prepay method to Auth and Capture
        And the POS option 1851 is set to 1
        # Set Prepay Grade Select Type option as One Touch
        And the POS option 5124 is set to 1
        And the Sigma simulator has essential configuration
        And the Sigma recognizes following cards
            | card_number       | card_description |
            | 12879784762398321 | Happy Card       |
        And the POS has following tenders configured
            | tender_id | description    | tender_type_id | exchange_rate | currency_symbol | external_id | tender_ranking |
            | 987       | Loyalty_points | 16             | 1             | $               | 987         | 6              |


    @fast
    Scenario: Configure a legacy PDL discount (unit FPR), tender prepay by credit, verify the PDL discount is added to the transaction.
        Given the pricebook contains discounts
            | description     | reduction_value | disc_type               | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z001        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger unit PDL discount with amount 0.50 for prepays
        And the POS is in a ready to sell state
        And a premium prepay fuel with 2.00 price on pump 1 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then a PDL discount PDL FPR is in the virtual receipt
        And a PDL discount PDL FPR without a price is in the previous transaction
        And a pump 1 is authorized with a price of 2.00


    @fast
    Scenario Outline: Configure a legacy PDL discount (unit FPR), dispense the prepaid fuel previously tendered by credit,
                      verify the PDL discount value is correctly updated.
        Given the pricebook contains discounts
            | description     | reduction_value | disc_type               | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z001        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger unit PDL discount with amount <amount> for prepays
        And the POS is in a ready to sell state
        And a premium prepay fuel with 12.00 price on pump 1 is present in the transaction
        And the cashier tendered transaction with credit
        When the customer dispenses premium fuel for 12.00 price on the pump 1
        Then a fuel item premium with price 12.0 and volume <dispensed_volume> is in the previous transaction
        And a PDL discount PDL FPR without a price is in the previous transaction
        And a tender credit with amount 12.00 is in the previous transaction

        Examples:
        | amount | dispensed_volume |
        | 2.00   | 5.455            |
        | 1.00   | 3.750            |


    @fast
    Scenario: Configure a legacy PDL discount (percentage FPR), tender prepay by credit, verify the PDL discount is added to the transaction.
        Given the pricebook contains discounts
            | description     | reduction_value | disc_type                          | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_PERCENTAGE_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z003        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger percent PDL discount with amount 0.50 for prepays
        And the POS is in a ready to sell state
        And a premium prepay fuel with 2.00 price on pump 1 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then a PDL discount PDL FPR is in the virtual receipt
        And a PDL discount PDL FPR without a price is in the previous transaction
        And a pump 1 is authorized with a price of 2.00


    @fast
    Scenario Outline: Configure a legacy PDL discount (percentage FPR), dispense the prepaid fuel previously tendered by credit,
                      verify the PDL discount value is correctly updated.
        Given the pricebook contains discounts
            | description     | reduction_value | disc_type                          | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_PERCENTAGE_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z003        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger percent PDL discount with amount <amount> for prepays
        And the POS is in a ready to sell state
        And a premium prepay fuel with 12.00 price on pump 1 is present in the transaction
        And the cashier tendered transaction with credit
        When the customer dispenses premium fuel for 12.00 price on the pump 1
        Then a fuel item premium with price 12.0 and volume <dispensed_volume> is in the previous transaction
        And a PDL discount PDL FPR without a price is in the previous transaction
        And a tender credit with amount 12.00 is in the previous transaction

        Examples:
        | amount | dispensed_volume |
        | 0.50   | 5.714            |
        | 0.20   | 3.571            |


    @fast
    Scenario Outline: Configure a HDD PDL discount (unit FPR) with quantity limit, tender prepay by credit, verify the
                      PDL discount is added to the transaction. Limit on the discount does not restrict the prepay amount.
        Given the pricebook contains discounts
            | description     | reduction_value | disc_type               | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z001        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger unit PDL HDD discount with amount 0.50 and quantity limit <quantity_limit> for PrePay
        And the POS is in a ready to sell state
        And a premium prepay fuel with 10.00 price on pump 1 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then a PDL discount PDL FPR is in the virtual receipt
        And a PDL discount PDL FPR without a price is in the previous transaction
        And a pump 1 is authorized with a price of <authorized_amount>

        Examples:
        | quantity_limit | authorized_amount |
        | 100            | 10.00             |
        | 2              | 10.00             |
        | 0              | 10.00             |


    @fast
    Scenario Outline: Configure a HDD PDL discount (unit FPR) with quantity limit, dispense the prepaid fuel previously tendered
                      by credit, cannot dispense more than PDL limit, verify the PDL discount value is correctly updated.
        Given the pricebook contains discounts
            | description     | reduction_value | disc_type               | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z001        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger unit PDL HDD discount with amount 1.00 and quantity limit <quantity_limit> for PrePay
        And the POS is in a ready to sell state
        And a premium prepay fuel with 12.00 price on pump 1 is present in the transaction
        And the cashier tendered transaction with credit
        When the customer dispenses premium fuel for <attempt_to_dispense> price on the pump 1
        Then a fuel item premium with price <dispensed_price> and volume <dispensed_volume> is in the previous transaction
        And a PDL discount PDL FPR without a price is in the previous transaction
        And a tender credit with amount <dispensed_price> is in the previous transaction

        Examples:
        | quantity_limit | attempt_to_dispense | dispensed_volume | dispensed_price |
        | 100            | 12.00               | 3.750            | 12.00           |
        | 2              | 12.00               | 2.00             | 6.40            |
        | 0              | 12.00               | 3.750            | 12.00           |


    @fast
    Scenario Outline: Grade selection is disabled. Configure a HDD PDL discounts (unit FPR) with quantity limit, tender prepay by credit, verify the
                      PDL discount is added to the transaction. Limit on the discount does not restrict the prepay amount.
        # Disable Prepay Grade Selection
        Given the POS option 5124 is set to 0
        And the pricebook contains discounts
            | description     | reduction_value | disc_type               | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z001        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger unit PDL HDD discount with amount 0.20 and quantity limit <quantity_limit> for PrePay
        And the POS is in a ready to sell state
        And a prepay with price 10.00 on the pump 1 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then the transaction is finalized
        And a PDL discount PDL FPR without a price is in the previous transaction
        And a tender credit with amount 10.00 is in the previous transaction
        And a pump 1 is authorized with a price of <authorized_amount>

        Examples:
        | quantity_limit | authorized_amount |
        | 100            | 10.00             |
        | 2              | 10.00             |
        | 0              | 10.00             |


    @fast
    Scenario Outline: Grade selection is disabled. Configure a HDD PDL discount (unit FPR) with quantity limit, dispense the prepaid fuel previously tendered
                      by credit, cannot dispense more than PDL limit, verify the PDL discount value is correctly updated.
        # Disable Prepay Grade Selection
        Given the POS option 5124 is set to 0
        And the pricebook contains discounts
            | description     | reduction_value | disc_type               | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z001        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger unit PDL HDD discount with amount 1.00 and quantity limit <quantity_limit> for PrePay
        And the POS is in a ready to sell state
        And a prepay with price 12.00 on the pump 1 is present in the transaction
        And the cashier tendered transaction with credit
        When the customer dispenses premium fuel for <attempt_to_dispense> price on the pump 1
        Then a fuel item premium with price <dispensed_price> and volume <dispensed_volume> is in the previous transaction
        And a PDL discount PDL FPR without a price is in the previous transaction
        And a tender credit with amount <dispensed_price> is in the previous transaction

        Examples:
        | quantity_limit | attempt_to_dispense | dispensed_volume | dispensed_price |
        | 100            | 12.00               | 3.750            | 12.00           |
        | 2              | 12.00               | 2.00             | 6.40            |
        | 0              | 12.00               | 3.750            | 12.00           |


    @fast
    Scenario Outline: Grade selection is disabled. Configure overlapping HDD PDL discounts (unit FPR) with quantity limits, dispense the prepaid fuel previously tendered
                      by credit, cannot dispense more than the PDL limit of first configured discount, verify the PDL discount value is correctly updated with first discount in
                      the list applied.
        # Disable Prepay Grade Selection
        Given the POS option 5124 is set to 0
        And the pricebook contains discounts
            | description     | reduction_value | disc_type               | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z001        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger following PDL HDD discounts
            | discount_value | quantity_limit | discount_mode |
            | 1.00           | 4              | PrePay        |
            | 0.20           | 2              | PrePay        |
        And the POS is in a ready to sell state
        And a prepay with price 36.00 on the pump 1 is present in the transaction
        And the cashier tendered transaction with credit
        When the customer dispenses premium fuel for <attempt_to_dispense> price on the pump 1
        Then a fuel item premium with price <dispensed_price> and volume <dispensed_volume> is in the previous transaction
        And a PDL discount PDL FPR without a price is in the previous transaction
        And a tender credit with amount <dispensed_price> is in the previous transaction

        Examples:
        | attempt_to_dispense | dispensed_volume | dispensed_price |
        | 20.00               | 4.00             | 12.80           |


    @fast
    Scenario Outline: Grade selection is enabled. Configure overlapping HDD PDL discounts (unit FPR) with quantity limits, dispense the prepaid fuel previously tendered
                      by credit, cannot dispense more than the PDL limit of first configured discount, verify the PDL discount value is correctly updated
                      with first discount in the list applied.
        Given the pricebook contains discounts
            | description     | reduction_value | disc_type               | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z001        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger following PDL HDD discounts
            | discount_value | quantity_limit | discount_mode |
            | 1.00           | 4              | PrePay        |
            | 0.20           | 2              | PrePay        |
        And the POS is in a ready to sell state
        And a premium prepay fuel with 36.00 price on pump 1 is present in the transaction
        And the cashier tendered transaction with credit
        When the customer dispenses premium fuel for <attempt_to_dispense> price on the pump 1
        Then a fuel item premium with price <dispensed_price> and volume <dispensed_volume> is in the previous transaction
        And a PDL discount PDL FPR without a price is in the previous transaction
        And a tender credit with amount <dispensed_price> is in the previous transaction

        Examples:
        | attempt_to_dispense | dispensed_volume | dispensed_price |
        | 20.00               | 4.00             | 12.80           |


    @fast
    Scenario Outline: Configure a HDD PDL discount (percentage FPR) with quantity limit, tender prepay by credit, verify the
                      PDL discount is added to the transaction. Limit on the discount does not restrict the prepay amount.
        Given the pricebook contains discounts
            | description     | reduction_value | disc_type                          | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_PERCENTAGE_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z003        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger percent PDL HDD discount with amount 0.20 and quantity limit <quantity_limit> for PrePay
        And the POS is in a ready to sell state
        And a premium prepay fuel with 10.00 price on pump 1 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then a PDL discount PDL FPR is in the virtual receipt
        And a PDL discount PDL FPR without a price is in the previous transaction
        And a pump 1 is authorized with a price of <authorized_amount>

        Examples:
        | quantity_limit | authorized_amount |
        | 100            | 10.00             |
        | 2              | 10.00             |
        | 0              | 10.00             |


    @fast
    Scenario Outline: Configure a HDD PDL discount (percentage FPR) with quantity limit, dispense the prepaid fuel previously tendered
                      by credit, cannot dispense more than PDL limit, verify the PDL discount value is correctly updated.
        Given the pricebook contains discounts
            | description     | reduction_value | disc_type                          | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_PERCENTAGE_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z003        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger percent PDL HDD discount with amount 0.20 and quantity limit <quantity_limit> for PrePay
        And the POS is in a ready to sell state
        And a premium prepay fuel with 12.00 price on pump 1 is present in the transaction
        And the cashier tendered transaction with credit
        When the customer dispenses premium fuel for <attempt_to_dispense> price on the pump 1
        Then a fuel item premium with price <dispensed_price> and volume <dispensed_volume> is in the previous transaction
        And a PDL discount PDL FPR without a price is in the previous transaction
        And a tender credit with amount <dispensed_price> is in the previous transaction

        Examples:
        | quantity_limit | attempt_to_dispense | dispensed_volume | dispensed_price |
        | 100            | 12.00               | 3.571            | 12.00           |
        | 2              | 12.00               | 2.00             | 6.72            |
        | 0              | 12.00               | 3.571            | 12.00           |


    @fast
    Scenario Outline: Grade selection is disabled. Configure a HDD PDL discount (percentage FPR) with quantity limit, tender prepay by credit, verify the
                      PDL discount is added to the transaction. Limit on the discount does not restrict the prepay amount.
        # Disable Prepay Grade Selection
        Given the POS option 5124 is set to 0
        And the pricebook contains discounts
            | description     | reduction_value | disc_type                          | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_PERCENTAGE_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z003        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger percent PDL HDD discount with amount 0.20 and quantity limit <quantity_limit> for PrePay
        And the POS is in a ready to sell state
        And a prepay with price 10.00 on the pump 1 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then a PDL discount PDL FPR is in the virtual receipt
        And a PDL discount PDL FPR without a price is in the previous transaction
        And a pump 1 is authorized with a price of <authorized_amount>

        Examples:
        | quantity_limit | authorized_amount |
        | 100            | 10.00             |
        | 2              | 10.00             |
        | 0              | 10.00             |


    @fast
    Scenario Outline: Grade selection is disabled. Configure a HDD PDL discount (percentage FPR) with quantity limit, dispense the prepaid fuel previously tendered
                      by credit, cannot dispense more than PDL limit, verify the PDL discount value is correctly updated.
        # Disable Prepay Grade Selection
        Given the POS option 5124 is set to 0
        And the pricebook contains discounts
            | description     | reduction_value | disc_type                          | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_PERCENTAGE_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z003        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger percent PDL HDD discount with amount 0.20 and quantity limit <quantity_limit> for PrePay
        And the POS is in a ready to sell state
        And a prepay with price 12.00 on the pump 1 is present in the transaction
        And the cashier tendered transaction with credit
        When the customer dispenses premium fuel for <attempt_to_dispense> price on the pump 1
        Then a fuel item premium with price <dispensed_price> and volume <dispensed_volume> is in the previous transaction
        And a PDL discount PDL FPR without a price is in the previous transaction
        And a tender credit with amount <dispensed_price> is in the previous transaction

        Examples:
        | quantity_limit | attempt_to_dispense | dispensed_volume | dispensed_price |
        | 100            | 12.00               | 3.571            | 12.00           |
        | 2              | 12.00               | 2.00             | 6.72            |
        | 0              | 12.00               | 3.571            | 12.00           |


    @fast
    Scenario Outline: Grade selection is disabled. Configure overlapping HDD PDL discounts (percentage FPR) with quantity limits, dispense the prepaid fuel previously tendered
                      by credit, cannot dispense more than the PDL limit of first configured discount, verify the PDL discount value is correctly updated with first discount in
                      the list applied.
        # Disable Prepay Grade Selection
        Given the POS option 5124 is set to 0
        And the pricebook contains discounts
            | description     | reduction_value | disc_type                          | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_PERCENTAGE_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z003        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger following PDL HDD discounts
            | discount_value | quantity_limit | discount_mode | discount_type |
            | 0.50           | 4              | PrePay        | percent       |
            | 0.20           | 2              | PrePay        | percent       |
        And the POS is in a ready to sell state
        And a prepay with price 36.00 on the pump 1 is present in the transaction
        And the cashier tendered transaction with credit
        When the customer dispenses premium fuel for <attempt_to_dispense> price on the pump 1
        Then a fuel item premium with price <dispensed_price> and volume <dispensed_volume> is in the previous transaction
        And a PDL discount PDL FPR without a price is in the previous transaction
        And a tender credit with amount <dispensed_price> is in the previous transaction

        Examples:
        | attempt_to_dispense | dispensed_volume | dispensed_price |
        | 12.00               | 4.00             | 8.40            |


    @fast
    Scenario Outline: Grade selection is enabled. Configure overlapping HDD PDL discounts (percentage FPR) with quantity limits, dispense the prepaid fuel previously tendered
                      by credit, cannot dispense more than the PDL limit of first configured discount, verify the PDL discount value is correctly
                      updated with first discount in the list applied.
        Given the pricebook contains discounts
            | description     | reduction_value | disc_type                          | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_PERCENTAGE_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z003        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger following PDL HDD discounts
            | discount_value | quantity_limit | discount_mode | discount_type |
            | 0.50           | 4              | PrePay        | percent       |
            | 0.20           | 2              | PrePay        | percent       |
        And the POS is in a ready to sell state
        And a premium prepay fuel with 10.00 price on pump 1 is present in the transaction
        And the cashier tendered transaction with credit
        When the customer dispenses premium fuel for <attempt_to_dispense> price on the pump 1
        Then a fuel item premium with price <dispensed_price> and volume <dispensed_volume> is in the previous transaction
        And a PDL discount PDL FPR without a price is in the previous transaction
        And a tender credit with amount <dispensed_price> is in the previous transaction

        Examples:
        | attempt_to_dispense | dispensed_volume | dispensed_price |
        | 12.00               | 4.00             | 8.40            |


    @fast
    Scenario Outline: Grade selection is disabled. Configure overlapping HDD PDL discounts (for prepay and postpay) with quantity limits, dispense the prepaid fuel previously tendered
                      by credit, cannot dispense more than the prepay PDL limit, verify the PDL discount value is correctly updated.
        # Disable Prepay Grade Selection
        Given the POS option 5124 is set to 0
        And the pricebook contains discounts
            | description     | reduction_value | disc_type                          | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_PERCENTAGE_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z003        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger following PDL HDD discounts
            | discount_value | quantity_limit | discount_mode | discount_type |
            | 0.50           | 4              | PrePay        | percent       |
            | 0.20           | 2              | PostPay       | percent       |
        And the POS is in a ready to sell state
        And a prepay with price 36.00 on the pump 1 is present in the transaction
        And the cashier tendered transaction with credit
        When the customer dispenses premium fuel for <attempt_to_dispense> price on the pump 1
        Then a fuel item premium with price <dispensed_price> and volume <dispensed_volume> is in the previous transaction
        And a PDL discount PDL FPR without a price is in the previous transaction
        And a tender credit with amount <dispensed_price> is in the previous transaction

        Examples:
        | attempt_to_dispense | dispensed_volume | dispensed_price |
        | 24.00               | 4.00             | 8.40            |


    @fast
    Scenario Outline: Grade selection is disabled. Configure overlapping HDD PDL unit discounts (different product ranges) with quantity limits, dispense the prepaid fuel previously tendered
                      by credit, cannot dispense more than the prepay PDL limit, verify the PDL discount value is correctly updated.
        # Disable Prepay Grade Selection
        Given the POS option 5124 is set to 0
        And the pricebook contains discounts
            | description     | reduction_value | disc_type               | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z001        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger following PDL HDD discounts
            | discount_value | quantity_limit | discount_mode | discount_type | product_code_range |
            | 0.50           | 2              | PrePay        | unit          | 0003               |
            | 0.20           | 4              | PrePay        | unit          | 0005               |
        And the POS is in a ready to sell state
        And a prepay with price 36.00 on the pump 1 is present in the transaction
        And the cashier tendered transaction with credit
        When the customer dispenses premium fuel for <attempt_to_dispense> price on the pump 1
        Then a fuel item premium with price <dispensed_price> and volume <dispensed_volume> is in the previous transaction
        And a PDL discount PDL FPR without a price is in the previous transaction
        And a tender credit with amount <dispensed_price> is in the previous transaction

        Examples:
        | attempt_to_dispense | dispensed_volume | dispensed_price |
        | 24.00               | 2.00             | 8.00            |


    @fast
    Scenario Outline: Grade selection is disabled. Configure HDD PDL percent discounts (with product range) with quantity limit, dispense the prepaid fuel previously tendered
                      by credit, cannot dispense more than the prepay PDL limit, verify the PDL discount value is correctly updated.
        # Disable Prepay Grade Selection
        Given the POS option 5124 is set to 0
        And the pricebook contains discounts
            | description     | reduction_value | disc_type                          | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_PERCENTAGE_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z003        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger following PDL HDD discounts
            | discount_value | quantity_limit | discount_mode | discount_type | product_code_range |
            | 0.50           | 2              | PrePay        | percent       | 0200               |
        And the POS is in a ready to sell state
        And a prepay with price 36.00 on the pump 1 is present in the transaction
        And the cashier tendered transaction with credit
        When the customer dispenses diesel fuel for <attempt_to_dispense> price on the pump 1
        Then a fuel item diesel with price <dispensed_price> and volume <dispensed_volume> is in the previous transaction
        And a PDL discount PDL FPR without a price is in the previous transaction
        And a tender credit with amount <dispensed_price> is in the previous transaction
        Examples:
        | attempt_to_dispense | dispensed_volume | dispensed_price |
        | 24.00               | 2.00             | 1.20            |



    @fast
    Scenario Outline: Grade selection is disabled. Configure HDD PDL unit discounts (with product range) with quantity limit, dispense the prepaid fuel previously tendered
                      by credit, cannot dispense more than the prepay PDL limit, verify the PDL discount value is correctly updated.
        # Disable Prepay Grade Selection
        Given the POS option 5124 is set to 0
        And the pricebook contains discounts
            | description     | reduction_value | disc_type               | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z001        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger following PDL HDD discounts
            | discount_value | quantity_limit | discount_mode | discount_type | product_code_range |
            | 0.50           | 2              | PrePay        | unit          | 0007               |
        And the POS is in a ready to sell state
        And a prepay with price 36.00 on the pump 1 is present in the transaction
        And the cashier tendered transaction with credit
        When the customer dispenses midgrade fuel for <attempt_to_dispense> price on the pump 1
        Then a fuel item midgrade with price <dispensed_price> and volume <dispensed_volume> is in the previous transaction
        And a PDL discount PDL FPR without a price is in the previous transaction
        And a tender credit with amount <dispensed_price> is in the previous transaction
        Examples:
        | attempt_to_dispense | dispensed_volume | dispensed_price |
        | 24.00               | 2.00             | 5.40            |


    @fast
    Scenario Outline: Grade selection is disabled. Configure a HDD PDL discount (unit/percent) with quantity limit, transfer the prepay,
                      previously tendered by credit, verify the PDL discount is transfered as well.
        # Disable Prepay Grade Selection
        Given the POS option 5124 is set to 0
        And the pricebook contains discounts
            | description     | reduction_value | disc_type                          | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR unit    | 0               | PDL_FUEL_PRICE_ROLLBACK            | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z001        | false       | 0          |
            | PDL FPR perc    | 0               | PDL_PERCENTAGE_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z003        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount 0.50 and quantity limit 0 for PrePay
        And the POS is in a ready to sell state
        And a prepay with price <fuel_price> on the pump 1 is present in the transaction
        And the cashier tendered transaction with credit
        When the cashier transfers the prepay from pump 1 to pump 2
        Then a PDL discount <pdl_description> without a price is in the previous transaction
        And a tender credit with amount <credit_amount> is in the previous transaction
        And a pump 2 is authorized with a price of <fuel_price>

        Examples:
        | disc_type | fuel_price | credit_amount | pdl_description |
        | unit      | 12.00      | 12.00         | PDL FPR unit    |
        | percent   | 12.00      | 12.00         | PDL FPR perc    |


    @fast
    Scenario Outline: Grade selection is disabled. Configure a HDD PDL discount (unit) with quantity limit, transfer and dispense the prepay,
                      previously tendered by credit, verify the PDL discount is transfered as well.
        # Disable Prepay Grade Selection
        Given the POS option 5124 is set to 0
        And the pricebook contains discounts
            | description     | reduction_value | disc_type                   | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_FUEL_PRICE_ROLLBACK     | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z001        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger unit PDL HDD discount with amount 0.50 and quantity limit <quantity_limit> for PrePay
        And the POS is in a ready to sell state
        And a prepay with price 12.00 on the pump 1 is present in the transaction
        And the cashier tendered transaction with credit
        And the cashier transferred the prepay from pump 1 to pump 2
        When the customer dispenses premium fuel for <dispense_price> price on the pump 2
        Then a PDL discount <pdl_description> without a price is in the previous transaction
        And a fuel item premium with price <fuel_price> and volume <gallons> is in the previous transaction
        And a tender credit with amount <credit_amount> is in the previous transaction

        Examples:
        | dispense_price | fuel_price | gallons | credit_amount | pdl_description | quantity_limit |
        | 12.00          | 7.40       | 2.00    | 7.40          | PDL FPR         | 2              |


    @fast
    Scenario Outline: Grade selection is disabled. Configure a HDD PDL discount (percentage) with quantity limit, transfer the prepay,
                      previously tendered by credit, verify the PDL discount is transfered as well.
        # Disable Prepay Grade Selection
        Given the POS option 5124 is set to 0
        And the pricebook contains discounts
            | description     | reduction_value | disc_type                          | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_PERCENTAGE_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z003        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger percent PDL HDD discount with amount 0.50 and quantity limit <quantity_limit> for PrePay
        And the POS is in a ready to sell state
        And a prepay with price 12.00 on the pump 1 is present in the transaction
        And the cashier tendered transaction with credit
        And the cashier transferred the prepay from pump 1 to pump 2
        When the customer dispenses premium fuel for <dispense_price> price on the pump 2
        Then a PDL discount <pdl_description> without a price is in the previous transaction
        And a fuel item premium with price <fuel_price> and volume <gallons> is in the previous transaction
        And a tender credit with amount <credit_amount> is in the previous transaction

        Examples:
        | dispense_price | fuel_price | gallons | credit_amount | pdl_description | quantity_limit |
        | 12.00          | 4.20       | 2.00    | 4.20          | PDL FPR         | 2              |


    @fast
    Scenario Outline: Configure a legacy PDL discount (unit FPR), perform postpay on pump, tender the transaction with credit,
                      verify unit PDL discount is added to transaction
        Given the pricebook contains discounts
            | description     | reduction_value | disc_type               | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z001        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger unit PDL discount with amount 0.20
        And the POS is in a ready to sell state
        And the customer dispensed <grade> for <price> price at pump <pump_id>
        And the postpay from pump <pump_id> is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then a PDL discount PDL FPR is in the virtual receipt
        And a PDL discount PDL FPR with price <discount_total> is in the previous transaction
        And a tender credit with amount <tendered_amount> is in the previous transaction

        Examples:
            | grade   | pump_id | price | fuel_item      | discount_total | tendered_amount |
            | Regular | 2       | 10.00 | 5.000G Regular | 1.00           | 9.00            |


    @fast
    Scenario Outline: Configure a legacy PDL discount (percentage FPR), perform postpay on pump, tender the transaction
                      with credit, verify percentage PDL discount is added to transaction
        Given the pricebook contains discounts
            | description     | reduction_value | disc_type                          | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_PERCENTAGE_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z003        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger percent PDL discount with amount 0.20
        And the POS is in a ready to sell state
        And the customer dispensed <grade> for <price> price at pump <pump_id>
        And the postpay from pump <pump_id> is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then an item <fuel_item> with price <price> is in the virtual receipt
        And a PDL discount PDL FPR is in the virtual receipt
        And a PDL discount PDL FPR with price <discount_total> is in the previous transaction
        And a tender credit with amount <tendered_amount> is in the previous transaction

        Examples:
            | grade   | pump_id | price | fuel_item      | discount_total | tendered_amount |
            | Regular | 2       | 10.00 | 5.000G Regular | 2.00           | 8.00            |


    @fast
    Scenario Outline: Configure a HDD PDL discount (unit FPR) with quantity limit, perform postpay on pump, tender the transaction
                      with credit, verify unit PDL discount is added to transaction
        Given the pricebook contains discounts
            | description     | reduction_value | disc_type               | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z001        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger unit PDL HDD discount with amount 0.50 and quantity limit <quantity_limit> for PostPay
        And the POS is in a ready to sell state
        And the customer dispensed <grade> for <price> price at pump <pump_id>
        And the postpay from pump <pump_id> is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then an item <fuel_item> with price <price> is in the virtual receipt
        And a PDL discount PDL FPR is in the virtual receipt
        And a PDL discount PDL FPR with price <discount_total> is in the previous transaction
        And a tender credit with amount <tendered_amount> is in the previous transaction

        Examples:
            | grade   | pump_id | price | fuel_item      | quantity_limit | discount_total | tendered_amount |
            | Regular | 2       | 10.00 | 5.000G Regular | 100            | 2.50           | 7.50            |
            | Regular | 2       | 10.00 | 5.000G Regular | 2              | 1.00           | 9.00            |
            | Regular | 2       | 10.00 | 5.000G Regular | 0              | 2.50           | 7.50            |


    @fast
    Scenario Outline: Configure a HDD PDL discount (percentage FPR) with quantity limit, perform postpay on pump, tender the transaction
                      with credit, verify percentage PDL discount is added to transaction
        Given the pricebook contains discounts
            | description     | reduction_value | disc_type                          | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_PERCENTAGE_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z003        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger percent PDL HDD discount with amount 0.2 and quantity limit <quantity_limit> for PostPay
        And the POS is in a ready to sell state
        And the customer dispensed <grade> for <price> price at pump <pump_id>
        And the postpay from pump <pump_id> is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then an item <fuel_item> with price <price> is in the virtual receipt
        And a PDL discount PDL FPR is in the virtual receipt
        And a PDL discount PDL FPR with price <discount_total> is in the previous transaction
        And a tender credit with amount <tendered_amount> is in the previous transaction

        Examples:
            | grade   | pump_id | price | fuel_item      | quantity_limit | discount_total | tendered_amount |
            | Regular | 2       | 10.00 | 5.000G Regular | 100            | 2.00           | 8.00            |
            | Regular | 2       | 10.00 | 5.000G Regular | 2              | 0.80           | 9.20            |
            | Regular | 2       | 10.00 | 5.000G Regular | 0              | 2.00           | 8.00            |


    @fast
    Scenario: Configure a HDD PDL discount larger than tran total, perform postpay on pump, tender the transaction
              with credit, verify that the discount is not added to the transaction
        Given the pricebook contains discounts
            | description     | reduction_value | disc_type               | disc_mode   | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL FPR         | 0               | PDL_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z001        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger unit PDL HDD discount with amount 5.00 and quantity limit 0 for PostPay
        And the POS is in a ready to sell state
        And the customer dispensed Regular for 10.00 price at pump 2
        And the postpay from pump 2 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then the transaction is finalized
        And a PDL discount PDL FPR is not in the previous transaction


    @fast
    Scenario: Configure a legacy PDL discount (transaction percent), tender dry stock by credit, verify the PDL discount is added to the transaction.
        Given the pricebook contains discounts
            | description | reduction_value | disc_type      | disc_mode         | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL perc    | 0               | PRESET_PERCENT | WHOLE_TRANSACTION | STACKABLE_AND_ALLOW_ONLY_ONCE | Z003        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger percent PDL discount with amount 0.50 for dry stock
        And the POS is in a ready to sell state
        And an item with barcode 088888888880 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then an item Sale Item B with price 1.99 is in the virtual receipt
        And a PDL discount PDL perc is in the virtual receipt
        And a PDL discount PDL perc with price 1.00 is in the previous transaction
        And a tender credit with amount 1.13 is in the previous transaction


    @fast
    Scenario: Configure a legacy PDL discount (transaction flat), tender dry stock by credit, verify the PDL discount is added to the transaction.
        Given the pricebook contains discounts
            | description | reduction_value | disc_type     | disc_mode         | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL flat    | 0               | PRESET_AMOUNT | WHOLE_TRANSACTION | STACKABLE_AND_ALLOW_ONLY_ONCE | Z004        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger flat PDL discount with amount 0.50 for dry stock
        And the POS is in a ready to sell state
        And an item with barcode 088888888880 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then an item Sale Item B with price 1.99 is in the virtual receipt
        And a PDL discount PDL flat is in the virtual receipt
        And a PDL discount PDL flat with price 0.50 is in the previous transaction
        And a tender credit with amount 1.63 is in the previous transaction


    @fast
    Scenario: Configure a HDD PDL discount (transaction percent), tender dry stock by credit, verify the PDL discount is added to the transaction.
        Given the pricebook contains discounts
            | description | reduction_value | disc_type      | disc_mode         | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL perc    | 0               | PRESET_PERCENT | WHOLE_TRANSACTION | STACKABLE_AND_ALLOW_ONLY_ONCE | Z003        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger percent PDL HDD discount with amount 0.50 for dry stock
        And the POS is in a ready to sell state
        And an item with barcode 088888888880 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then an item Sale Item B with price 1.99 is in the virtual receipt
        And a PDL discount PDL perc is in the virtual receipt
        And a PDL discount PDL perc with price 1.00 is in the previous transaction
        And a tender credit with amount 1.13 is in the previous transaction


    @fast
    Scenario: Configure a HDD PDL discount (transaction flat), tender dry stock by credit, verify the PDL discount is added to the transaction.
        Given the pricebook contains discounts
            | description | reduction_value | disc_type     | disc_mode         | disc_quantity                 | external_id | reduces_tax |max_quantity|
            | PDL flat    | 0               | PRESET_AMOUNT | WHOLE_TRANSACTION | STACKABLE_AND_ALLOW_ONLY_ONCE | Z004        | false       | 0          |
        And the EPS simulator uses Default card configured to trigger flat PDL HDD discount with amount 0.50 for dry stock
        And the POS is in a ready to sell state
        And an item with barcode 088888888880 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then an item Sale Item B with price 1.99 is in the virtual receipt
        And a PDL discount PDL flat is in the virtual receipt
        And a PDL discount PDL flat with price 0.50 is in the previous transaction
        And a tender credit with amount 1.63 is in the previous transaction


    @fast
    Scenario: Combining PDL discounts with loyalty tenders is not allowed. Configure a PDL discount and loyalty tender, tender prepay partially 
              by loyalty points and credit, verify the PDL discount is not added to the transaction.
        Given the POS has the feature Loyalty enabled
        # Set Allow combining PDL discounts with loyalty tenders to No
        And the POS option 1117 is set to 0
        And the pricebook contains discounts
            | description  | reduction_value | disc_type               | disc_mode   | disc_quantity                 | external_id | reduces_tax | max_quantity |
            | PDL FPR unit | 0               | PDL_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z001        | false       | 0            |
        And an item Sale Item A with barcode 099999999990 and price 0.99 is eligible for LMOP discount 0.50 when using loyalty card 12879784762398321
        And the EPS simulator uses Default card configured to trigger unit PDL HDD discount with amount 1.00 and quantity limit 0 for PrePay
        And the POS is in a ready to sell state
        And a premium prepay fuel with 6.00 price on pump 1 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And a loyalty card 12879784762398321 with description Happy Card is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then the transaction is finalized
        And a tender Loyalty_points with amount 0.50 is in the previous transaction
        And a PDL discount PDL FPR unit is not in the previous transaction


    @fast
    Scenario: Allow combining PDL discounts with loyalty tenders. Configure PDL discount and loyalty tender, tender prepay partially 
              by loyalty points and credit, verify the PDL discount is added to the transaction.
        Given the POS has the feature Loyalty enabled
        # Set Allow combining PDL discounts with loyalty tenders to Yes
        And the POS option 1117 is set to 1
        And the pricebook contains discounts
            | description  | reduction_value | disc_type               | disc_mode   | disc_quantity                 | external_id | reduces_tax | max_quantity |
            | PDL FPR unit | 0               | PDL_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z001        | false       | 0            |
        And an item Sale Item A with barcode 099999999990 and price 0.99 is eligible for LMOP discount 0.50 when using loyalty card 12879784762398321
        And the EPS simulator uses Default card configured to trigger unit PDL HDD discount with amount 1.00 and quantity limit 0 for PrePay
        And the POS is in a ready to sell state
        And a premium prepay fuel with 6.00 price on pump 1 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And a loyalty card 12879784762398321 with description Happy Card is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then the transaction is finalized
        And a tender Loyalty_points with amount 0.50 is in the previous transaction
        And a PDL discount PDL FPR unit without a price is in the previous transaction


    @fast
    Scenario: Allow combining PDL discounts with loyalty tenders. Configure PDL discount and loyalty tender, dispense the prepaid fuel 
              previously tendered partially by loyalty points and credit, verify the PDL discount is added to the transaction.
        Given the POS has the feature Loyalty enabled
        # Set Allow combining PDL discounts with loyalty tenders to Yes
        And the POS option 1117 is set to 1
        And the pricebook contains discounts
            | description  | reduction_value | disc_type               | disc_mode   | disc_quantity                 | external_id | reduces_tax | max_quantity |
            | PDL FPR unit | 0               | PDL_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z001        | false       | 0            |
        And an item Sale Item A with barcode 099999999990 and price 0.99 is eligible for LMOP discount 0.50 when using loyalty card 12879784762398321
        And the EPS simulator uses Default card configured to trigger unit PDL HDD discount with amount 1.00 and quantity limit 0 for PrePay
        And the POS is in a ready to sell state
        And a premium prepay fuel with 6.00 price on pump 1 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And a loyalty card 12879784762398321 with description Happy Card is present in the transaction
        And the cashier tendered transaction with credit
        When the customer dispenses Premium fuel for 6.00 price on the pump 1
        Then the transaction is finalized
        And a tender Loyalty_points with amount 0.50 is in the previous transaction
        And a PDL discount PDL FPR unit without a price is in the previous transaction
        And a fuel item premium with price 6.00 and volume 1.875 is in the previous transaction