@pos @pes
Feature: Promotion Execution Service - PDL discounts
    This feature file covers test cases with PES discounts received together with HDD PDLs.

    Background: POS is configured for PES feature and PDL
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
        # Set Prepay Grade Select Type option as One Touch
        And the POS option 5124 is set to 1
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        And the POS option 5277 is set to 1
        And the pricebook contains PES loyalty tender
        And the POS recognizes following PES cards
            | card_definition_id | card_role  | card_name     | barcode_range_from     | barcode_range_to       | card_definition_group_id | track_format_1 | track_format_2 | mask_mode |
            | 70000001142        | 3          | PES card      | 3104174102936582       | 3104174102936583       | 70000010042              | bt%at?         | bt;at?         | 21        |
        And the nep-server has default configuration
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id   | unit_type              | is_apply_as_tender |
            | 004            | Premium discount     | 10.00          | transaction    | premium tender | GENERAL_SALES_QUANTITY | False              |
        And the pricebook contains discounts
            | description  | reduction_value | disc_type                      | disc_mode   | disc_quantity                 | external_id | reduces_tax | max_quantity |
            | PDL FPR unit | 0               | FUEL_PRICE_ROLLBACK            | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z001        | false       | 0            |
            | PDL FPR perc | 0               | PERCENTAGE_FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | Z003        | false       | 0            |
            | PES loyalty  | 0               | PRESET_AMOUNT                  | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE | PES_basic   | false       | 0            |


    @fast @positive
    Scenario Outline: Configure PDL discounts, tender a postpay by credit, both discounts are applied.
        Given the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount 0.50 and quantity limit 0 for PostPay
        And the POS is in a ready to sell state
        And a Premium postpay fuel with <fuel_price> price on pump 2 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then the transaction is finalized
        And a PDL discount <pdl_description> with price <pdl_amount> is in the previous transaction
        And a tender credit with amount <credit_amount> is in the previous transaction
        And a fuel item Premium with price <fuel_price> and volume <gallons> is in the previous transaction
        And a loyalty discount Premium discount with value of 10.00 is in the previous transaction

        Examples:
        | disc_type | item_name      | fuel_price | gallons | pdl_amount | credit_amount | pdl_description |
        | unit      | 5.000G Premium | 20.00      | 5.0     | 2.50       | 7.50          | PDL FPR unit    |
        | percent   | 7.500G Premium | 30.00      | 7.5     | 15.00      | 5.00          | PDL FPR perc    |


    @fast @positive
    Scenario Outline: Configure PDL discounts with combined amount larger than tran total, tender a postpay by credit,
                      PDL is not awarded to not drive the balance into negative.
        Given the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount 0.50 and quantity limit 0 for PostPay
        And the POS is in a ready to sell state
        And a Premium postpay fuel with <fuel_price> price on pump 2 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then the transaction is finalized
        And a PDL discount <pdl_description> is not in the previous transaction
        And a tender credit with amount <credit_amount> is in the previous transaction
        And a fuel item Premium with price <fuel_price> and volume <gallons> is in the previous transaction
        And a loyalty discount Premium discount with value of 10.00 is in the previous transaction

        Examples:
        | disc_type | fuel_price | gallons | credit_amount | pdl_description |
        | unit      | 11.00      | 2.75    | 1.00          | PDL FPR unit    |
        | percent   | 11.00      | 2.75    | 1.00          | PDL FPR perc    |


    @fast @positive
    Scenario Outline: Configure PDL discounts, tender a prepay by credit, both discounts are applied.
        Given the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount 0.50 and quantity limit 0 for PrePay
        And the POS is in a ready to sell state
        And a Premium prepay fuel with <fuel_price> price on pump 1 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then the transaction is finalized
        And a PDL discount <pdl_description> without a price is in the previous transaction
        And a tender credit with amount <credit_amount> is in the previous transaction
        And a loyalty discount Premium discount with value of 10.00 is in the previous transaction
        And a pump 1 is authorized with a price of <fuel_price>

        Examples:
        | disc_type | fuel_price | credit_amount | pdl_description |
        | unit      | 20.00      | 10.00         | PDL FPR unit    |
        | percent   | 30.00      | 20.00         | PDL FPR perc    |


    @fast @positive
    Scenario Outline: Configure PDL discounts, dispense the prepaid fuel previously tendered by credit,
                      verify both discounts are applied with correct value.
        Given the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount 0.50 and quantity limit 0 for PrePay
        And the POS is in a ready to sell state
        And a Premium prepay fuel with <fuel_price> price on pump 1 is present in the transaction
        And the cashier tendered transaction with credit
        When the customer dispenses Premium fuel for <fuel_price> price on the pump 1
        Then the transaction is finalized
        And a fuel item premium with price <fuel_price> and volume <dispensed_volume> is in the previous transaction
        And a PDL discount <pdl_description> without a price is in the previous transaction
        And a tender credit with amount <credit_amount> is in the previous transaction

        Examples:
            | disc_type | fuel_price | dispensed_volume | credit_amount | pdl_description |
            | unit      | 37.00      | 10.00            | 27.00         | PDL FPR unit    |
            | percent   | 31.50      | 15.00            | 21.50         | PDL FPR perc    |


    @negative @fast
    Scenario Outline: Allow/Disallow combining PDL discounts with loyalty tenders. Configure PDL discount and loyalty tender, tender prepay fully by loyalty points,
                     verify the PDL discount is not added to the transaction when tender other than credit is used.
        # Set Allow combining PDL discounts with loyalty tenders to Yes/No
        Given the POS option 1117 is set to <pos_option_value>
        And the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount 0.50 and quantity limit 0 for PrePay
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id     | unit_type              | is_apply_as_tender |
            | 004            | Loyalty Tender       | 10.00          | transaction    | loyalty tender   | GENERAL_SALES_QUANTITY | True               |
        And the POS is in a ready to sell state
        And the prepay of the fuel grade premium with price <fuel_price> at pump id 1 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then a PDL discount <pdl_description> is not in the virtual receipt
        And a PDL discount <pdl_description> is not in the previous transaction
        And a tender Loyalty Tender with amount <loyalty_amount> is in the previous transaction
        And a pump 1 is authorized with a price of <fuel_price>

        Examples:
            | pos_option_value | disc_type | item_name      | fuel_price | loyalty_amount | pdl_description |
            | 0                | unit      | 1.000G Premium | 4.00       | 4.00           | PDL FPR unit    |
            | 0                | percent   | 2.000G Premium | 8.00       | 8.00           | PDL FPR perc    |
            | 1                | unit      | 1.000G Premium | 4.00       | 4.00           | PDL FPR unit    |
            | 1                | percent   | 2.000G Premium | 8.00       | 8.00           | PDL FPR perc    |


    @negative @fast
    Scenario Outline: Combining PDL discounts with loyalty tenders is not enabled. Configure PDL discount and loyalty tender,
                      tender prepay partially by loyalty points and credit, verify the PDL discount is not added to the transaction.
        # Set Allow combining PDL discounts with loyalty tenders to No
        Given the POS option 1117 is set to 0
        And the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount 0.50 and quantity limit 0 for PrePay
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id     | unit_type              | is_apply_as_tender |
            | 004            | Loyalty Tender       | 10.00          | transaction    | loyalty tender   | GENERAL_SALES_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a premium prepay fuel with <fuel_price> price on pump 1 is present in the transaction
        And a loyalty tender Loyalty tender with value of 10.00 is present in the transaction after subtotal
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then a PDL discount <pdl_description> is not in the virtual receipt
        And a PDL discount <pdl_description> is not in the previous transaction
        And a tender Loyalty Tender with amount 10.00 is in the previous transaction
        And a tender credit with amount <credit_amount> is in the previous transaction
        And a pump 1 is authorized with a price of <fuel_price>

        Examples:
            | disc_type | fuel_price | credit_amount | pdl_description |
            | unit      | 12.00      | 2.00          | PDL FPR unit    |
            | percent   | 16.00      | 6.00          | PDL FPR perc    |


    @positive @fast
    Scenario Outline: Allow combining PDL discounts with loyalty tenders. Configure PDL discount and loyalty tender, tender
                      prepay partially by loyalty points and credit, verify the PDL discount is added to the transaction.
        # Set Allow combining PDL discounts with loyalty tenders to Yes
        Given the POS option 1117 is set to 1
        And the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount 0.50 and quantity limit 0 for PrePay
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id     | unit_type              | is_apply_as_tender |
            | 004            | Loyalty Tender       | 10.00          | transaction    | loyalty tender   | GENERAL_SALES_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a premium prepay fuel with <fuel_price> price on pump 1 is present in the transaction
        And a loyalty tender Loyalty tender with value of 10.00 is present in the transaction after subtotal
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then a PDL discount <pdl_description> is in the virtual receipt
        And a PDL discount <pdl_description> without a price is in the previous transaction
        And a tender Loyalty Tender with amount 10.00 is in the previous transaction
        And a tender credit with amount <credit_amount> is in the previous transaction
        And a pump 1 is authorized with a price of <fuel_price>

        Examples:
            | disc_type | fuel_price | credit_amount | pdl_description |
            | unit      | 12.00      | 2.00          | PDL FPR unit    |
            | percent   | 16.00      | 6.00          | PDL FPR perc    |


    @positive @fast
    Scenario Outline: Allow combining PDL discounts with loyalty tenders. Configure PDL discount and loyalty tender, dispense the prepaid fuel previously tendered
                      partially by loyalty points and credit, verify the PDL discount value is correctly updated.
        # Set Allow combining PDL discounts with loyalty tenders to Yes
        Given the POS option 1117 is set to 1
        And the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount 0.50 and quantity limit 0 for PrePay
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id     | unit_type              | is_apply_as_tender |
            | 004            | Loyalty Tender       | 10.00          | transaction    | loyalty tender   | GENERAL_SALES_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a premium prepay fuel with <fuel_price> price on pump 1 is present in the transaction
        And a loyalty tender Loyalty tender with value of 10.00 is present in the transaction after subtotal
        And the cashier tendered transaction with credit
        When the customer dispenses premium fuel for <fuel_price> price on the pump 1
        Then a PDL discount <pdl_description> is in the virtual receipt
        And a PDL discount <pdl_description> without a price is in the previous transaction
        And a fuel item premium with price <fuel_price> and volume <gallons> is in the previous transaction
        And a tender Loyalty Tender with amount 10.00 is in the previous transaction
        And a tender credit with amount <credit_amount> is in the previous transaction

        Examples:
            | disc_type | fuel_price | gallons | credit_amount | pdl_description |
            | unit      | 14.80      | 4.0     | 4.80          | PDL FPR unit    |
            | percent   | 16.80      | 8.0     | 6.80          | PDL FPR perc    |


    @positive @fast
    Scenario Outline: Allow combining PDL discounts with loyalty tenders. Configure PDL discount and loyalty tender, under-dispense the prepaid fuel
                      previously tendered partially by loyalty points and credit, verify the PDL discount value is correctly updated.
        # Set Allow combining PDL discounts with loyalty tenders to Yes
        Given the POS option 1117 is set to 1
        And the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount 0.50 and quantity limit 0 for PrePay
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id     | unit_type              | is_apply_as_tender |
            | 004            | Loyalty Tender       | 10.00          | transaction    | loyalty tender   | GENERAL_SALES_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a premium prepay fuel with 15.00 price on pump 1 is present in the transaction
        And a loyalty tender Loyalty tender with value of 10.00 is present in the transaction after subtotal
        And the cashier tendered transaction with credit
        When the customer dispenses premium fuel for <fuel_price> price on the pump 1
        Then a PDL discount <pdl_description> without a price is in the previous transaction
        And a fuel item premium with price <fuel_price> and volume <gallons> is in the previous transaction
        And a tender Loyalty Tender with amount <loyalty_amount> is in the previous transaction
        And a tender credit with amount <credit_amount> is in the previous transaction

        Examples:
            | disc_type | fuel_price | gallons | loyalty_amount | credit_amount | pdl_description |
            | unit      | 7.40       | 2.0     | 7.40           | 0.00          | PDL FPR unit    |
            | percent   | 8.40       | 4.0     | 8.40           | 0.00          | PDL FPR perc    |
            | percent   | 12.60      | 6.0     | 10.00          | 2.60          | PDL FPR perc    |


    @positive @fast
    Scenario Outline: Allow combining PDL discounts with loyalty tenders. Configure PDL discount with quantity limit and loyalty tender, tender prepay partially
                      by loyalty points and credit, verify the PDL discount is added to the transaction. Limit on the discount does not restrict the prepay amount.
        # Set Allow combining PDL discounts with loyalty tenders to Yes
        Given the POS option 1117 is set to 1
        And the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount 0.50 and quantity limit <quantity_limit> for PrePay
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id     | unit_type              | is_apply_as_tender |
            | 004            | Loyalty Tender       | 10.00          | transaction    | loyalty tender   | GENERAL_SALES_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a premium prepay fuel with 12.00 price on pump 1 is present in the transaction
        And a loyalty tender Loyalty tender with value of 10.00 is present in the transaction after subtotal
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then a PDL discount <pdl_description> is in the virtual receipt
        And a PDL discount <pdl_description> without a price is in the previous transaction
        And a tender Loyalty Tender with amount 10.00 is in the previous transaction
        And a tender credit with amount <credit_amount> is in the previous transaction
        And a pump 1 is authorized with a price of <fuel_price>

        Examples:
            | quantity_limit | disc_type | credit_amount | pdl_description | fuel_price |
            | 100            | unit      | 2.00          | PDL FPR unit    | 12.00      |
            | 2              | unit      | 2.00          | PDL FPR unit    | 12.00      |
            | 100            | percent   | 2.00          | PDL FPR perc    | 12.00      |
            | 2              | percent   | 2.00          | PDL FPR perc    | 12.00      |


    @positive @fast
    Scenario Outline: Allow combining PDL discounts with loyalty tenders. Configure PDL discount with quantity limit and loyalty tender, dispense the prepaid fuel previously tendered
                      partially by loyalty points and credit, cannot dispense more than PDL limit, verify the PDL discount value is correctly updated.
        # Set Allow combining PDL discounts with loyalty tenders to Yes
        Given the POS option 1117 is set to 1
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id     | unit_type              | is_apply_as_tender |
            | 004            | Loyalty Tender       | 10.00          | transaction    | loyalty tender   | GENERAL_SALES_QUANTITY | True               |
        And the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount 0.50 and quantity limit <quantity_limit> for PrePay
        And the POS is in a ready to sell state
        And a premium prepay fuel with <fuel_price> price on pump 1 is present in the transaction
        And a loyalty tender Loyalty tender with value of 10.00 is present in the transaction after subtotal
        And the cashier tendered transaction with credit
        When the customer dispenses premium fuel for <fuel_price> price on the pump 1
        Then a PDL discount <pdl_description> is in the virtual receipt
        And a PDL discount <pdl_description> without a price is in the previous transaction
        And a fuel item premium with price <dispensed_price> and volume <gallons> is in the previous transaction
        And a tender Loyalty Tender with amount 10.00 is in the previous transaction
        And a tender credit with amount <credit_amount> is in the previous transaction

        Examples:
            | quantity_limit | disc_type | fuel_price | dispensed_price | gallons | credit_amount | pdl_description |
            | 100            | unit      | 14.80      | 14.80           | 4.0     | 4.80          | PDL FPR unit    |
            | 3              | unit      | 14.00      | 11.10           | 3.0     | 1.10          | PDL FPR unit    |
            | 100            | percent   | 16.80      | 16.80           | 8.0     | 6.80          | PDL FPR perc    |
            | 5              | percent   | 16.00      | 10.50           | 5.0     | 0.50          | PDL FPR perc    |


    @positive @fast
    Scenario Outline: Grade selection is disabled. Allow combining PDL discounts with loyalty tenders. Configure a PDL discount with quantity limit,
                      tender prepay by credit, verify the PDL discount is added to the transaction. Limit on the discount does not restrict the prepay amount.
        # Set Allow combining PDL discounts with loyalty tenders to Yes
        Given the POS option 1117 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id     | unit_type              | is_apply_as_tender |
            | 004            | Loyalty Tender       | 10.00          | transaction    | loyalty tender   | GENERAL_SALES_QUANTITY | True               |
        And the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount 0.50 and quantity limit <quantity_limit> for PrePay
        And the POS is in a ready to sell state
        And a prepay with price <fuel_price> on the pump 1 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then the transaction is finalized
        And a PDL discount <pdl_description> without a price is in the previous transaction
        And a tender credit with amount <credit_amount> is in the previous transaction
        And a tender Loyalty Tender with amount 10.00 is in the previous transaction
        And a pump 1 is authorized with a price of <fuel_price>

        Examples:
            | quantity_limit | disc_type | fuel_price | credit_amount | pdl_description |
            | 100            | unit      | 12.00      | 2.00          | PDL FPR unit    |
            | 3              | unit      | 12.00      | 2.00          | PDL FPR unit    |
            | 100            | percent   | 16.00      | 6.00          | PDL FPR perc    |
            | 3              | percent   | 12.00      | 2.00          | PDL FPR perc    |


    @positive @fast
    Scenario Outline: Grade selection is disabled. Allow combining PDL discounts with loyalty tenders. Configure a PDL discount with quantity limit,
                      dispense a prepaid fuel by credit, cannot dispense more than PDL limit, validate discounts were correctly updated.
        # Set Allow combining PDL discounts with loyalty tenders to Yes
        Given the POS option 1117 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id     | unit_type              | is_apply_as_tender |
            | 004            | Loyalty Tender       | 10.00          | transaction    | loyalty tender   | GENERAL_SALES_QUANTITY | True               |
        And the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount 0.50 and quantity limit <quantity_limit> for PrePay
        And the POS is in a ready to sell state
        And a prepay with price <fuel_price> on the pump 1 is present in the transaction
        And the cashier tendered transaction with credit
        When the customer dispenses premium fuel for <fuel_price> price on the pump 1
        Then a PDL discount <pdl_description> without a price is in the previous transaction
        And a fuel item premium with price <dispensed_price> and volume <gallons> is in the previous transaction
        And a tender Loyalty Tender with amount 10.00 is in the previous transaction
        And a tender credit with amount <credit_amount> is in the previous transaction

        Examples:
            | quantity_limit | disc_type | item_name      | fuel_price | dispensed_price | gallons | credit_amount | pdl_description |
            | 100            | unit      | 3.243G Premium | 12.00      | 12.00           | 3.243   | 2.00          | PDL FPR unit    |
            | 3              | unit      | 3.000G Premium | 12.00      | 11.10           | 3.00    | 1.10          | PDL FPR unit    |
            | 100            | percent   | 8.000G Premium | 16.80      | 16.80           | 8.0     | 6.80          | PDL FPR perc    |
            | 5              | percent   | 5.000G Premium | 12.00      | 10.50           | 5.0     | 0.50          | PDL FPR perc    |


    @positive @fast
    Scenario Outline: Allow combining PDL discounts with loyalty tenders. Configure PDL discount and loyalty tender, tender
                      postpay partially by loyalty points and credit, verify the PDL discount is added to the transaction.
        # Set Allow combining PDL discounts with loyalty tenders to Yes
        Given the POS option 1117 is set to 1
        And the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount 0.50 and quantity limit 0 for PostPay
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id     | unit_type              | is_apply_as_tender |
            | 004            | Loyalty Tender       | 10.00          | transaction    | loyalty tender   | GENERAL_SALES_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a Premium postpay fuel with <fuel_price> price on pump 2 is present in the transaction
        And a loyalty tender Loyalty tender with value of 10.00 is present in the transaction after subtotal
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then a PDL discount <pdl_description> is in the virtual receipt
        And a PDL discount <pdl_description> with price <pdl_amount> is in the previous transaction
        And a tender Loyalty Tender with amount 10.00 is in the previous transaction
        And a tender credit with amount <credit_amount> is in the previous transaction

        Examples:
            | disc_type | item_name      | fuel_price | credit_amount | pdl_description | pdl_amount |
            | unit      | 4.000G Premium | 16.00      | 4.00          | PDL FPR unit    | 2.00       |
            | percent   | 8.000G Premium | 32.00      | 6.00          | PDL FPR perc    | 16.00      |


    @positive @fast
    Scenario Outline: Allow combining PDL discounts with loyalty tenders. Configure PDL discount and loyalty tender, tender postpay partially by loyalty points and credit,
                      verify the PDL discount is not added to the transaction when the PDL discount is higher than the transaction balance.
        # Set Allow combining PDL discounts with loyalty tenders to Yes
        Given the POS option 1117 is set to 1
        And the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount 0.50 and quantity limit 0 for PostPay
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id   | unit_type              | is_apply_as_tender |
            | 004            | Loyalty Tender       | 10.00          | transaction    | loyalty tender | GENERAL_SALES_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a Premium postpay fuel with <fuel_price> price on pump 2 is present in the transaction
        And a loyalty tender Loyalty tender with value of 10.00 is present in the transaction after subtotal
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then a PDL discount <pdl_description> is not in the virtual receipt
        And a PDL discount <pdl_description> is not in the previous transaction
        And a tender Loyalty Tender with amount 10.00 is in the previous transaction
        And a tender credit with amount <credit_amount> is in the previous transaction

        Examples:
            | disc_type | item_name      | fuel_price | gallons | credit_amount | pdl_description |
            | unit      | 2.600G Premium | 10.40      | 2.60    | 0.40          | PDL FPR unit    |
            | percent   | 4.000G Premium | 16.00      | 4.00    | 6.00          | PDL FPR perc    |


    @negative @fast
    Scenario Outline: Combining PDL discounts with loyalty tenders is not allowed. Configure a PDL discount and loyalty tender,
                      tender postpay partially by loyalty points and credit, verify the PDL discount is not added to the transaction.
        # Set Allow combining PDL discounts with loyalty tenders to No
        Given the POS option 1117 is set to 0
        And the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount 0.50 and quantity limit 0 for PrePay
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id     | unit_type              | is_apply_as_tender |
            | 004            | Loyalty Tender       | 10.00          | transaction    | loyalty tender   | GENERAL_SALES_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a Premium postpay fuel with <fuel_price> price on pump 2 is present in the transaction
        And a loyalty tender Loyalty tender with value of 10.00 is present in the transaction after subtotal
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then a PDL discount <pdl_description> is not in the virtual receipt
        And a PDL discount <pdl_description> is not in the previous transaction
        And a tender Loyalty Tender with amount 10.00 is in the previous transaction
        And a tender credit with amount <credit_amount> is in the previous transaction

        Examples:
        | disc_type | item_name      | fuel_price | gallons | credit_amount | pdl_description |
        | unit      | 2.750G Premium | 11.00      | 2.75    | 1.00          | PDL FPR unit    |
        | percent   | 2.750G Premium | 11.00      | 2.75    | 1.00          | PDL FPR perc    |


    @positive @fast
    Scenario Outline: Allow combining PDL discounts with loyalty tenders. Transfer the prepay, previously tendered partially by loyalty points and credit,
                      verify the PDL discount is transferred as well.
        # Set Allow combining PDL discounts with loyalty tenders to Yes
        Given the POS option 1117 is set to 1
        And the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount 0.50 and quantity limit 0 for PrePay
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id     | unit_type              | is_apply_as_tender |
            | 004            | Loyalty Tender       | 10.00          | transaction    | loyalty tender   | GENERAL_SALES_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a premium prepay fuel with <fuel_price> price on pump 1 is present in the transaction
        And a loyalty tender Loyalty tender with value of 10.00 is present in the transaction after subtotal
        And the cashier tendered transaction with credit
        When the cashier transfers the prepay from pump 1 to pump 2
        Then a PDL discount <pdl_description> without a price is in the previous transaction
        And a tender Loyalty Tender with amount 10.00 is in the previous transaction
        And a tender credit with amount <credit_amount> is in the previous transaction
        And a pump 2 is authorized with a price of <fuel_price>

        Examples:
        | disc_type | item_name      | fuel_price | gallons | credit_amount | pdl_description |
        | unit      | 3.000G Premium | 12.00      | 3.0     | 2.00          | PDL FPR unit    |
        | percent   | 4.000G Premium | 16.00      | 4.0     | 6.00          | PDL FPR perc    |


    @positive @fast
    Scenario Outline: Allow combining PDL discounts with loyalty tenders. Transfer the prepay, dispense the prepaid fuel previously tendered
                      partially by loyalty points and credit, verify the PDL discount value is transferred and correctly updated.
        # Set Allow combining PDL discounts with loyalty tenders to Yes
        Given the POS option 1117 is set to 1
        And the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount 0.50 and quantity limit 0 for PrePay
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id     | unit_type              | is_apply_as_tender |
            | 004            | Loyalty Tender       | 10.00          | transaction    | loyalty tender   | GENERAL_SALES_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a premium prepay fuel with <fuel_price> price on pump 1 is present in the transaction
        And a loyalty tender Loyalty tender with value of 10.00 is present in the transaction after subtotal
        And the cashier tendered transaction with credit
        And the cashier transferred the prepay from pump 1 to pump 2
        When the customer dispenses premium fuel for <fuel_price> price on the pump 2
        Then a PDL discount <pdl_description> without a price is in the previous transaction
        And a fuel item premium with price <fuel_price> and volume <gallons> is in the previous transaction
        And a tender Loyalty Tender with amount 10.00 is in the previous transaction
        And a tender credit with amount <credit_amount> is in the previous transaction

        Examples:
            | disc_type | item_name      | fuel_price | gallons | credit_amount | pdl_description |
            | unit      | 4.000G Premium | 14.80      | 4.0     | 4.80          | PDL FPR unit    |
            | percent   | 8.000G Premium | 16.80      | 8.0     | 6.80          | PDL FPR perc    |


    @positive @fast
    Scenario Outline: Grade selection is disabled. Allow combining PDL discounts with loyalty tenders. Configure PDL and local FPR discounts,
                      tender a prepay by credit, validate all discounts are in the transaction.
        # Set Allow combining PDL discounts with loyalty tenders to Yes
        Given the POS option 1117 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id     | unit_type              | is_apply_as_tender |
            | 004            | Loyalty Tender       | 10.00          | transaction    | loyalty tender   | GENERAL_SALES_QUANTITY | True               |
        And the POS has FPR discount configured
            | description    | reduction_value | disc_type           | disc_mode   | disc_quantity   |
            | Loyalty FPR    | 2000            | FUEL_PRICE_ROLLBACK | SINGLE_ITEM | ALLOW_ONLY_ONCE |
        And the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount 0.50 and quantity limit 0 for PrePay
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And a prepay with price <fuel_price> on the pump 1 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then the transaction is finalized
        And a FPR discount Loyalty FPR is in the previous transaction
        And a PDL discount <pdl_description> without a price is in the previous transaction
        And a tender credit with amount <credit_amount> is in the previous transaction
        And a tender Loyalty Tender with amount 10.00 is in the previous transaction
        And a pump 1 is authorized with a price of <fuel_price>

        Examples:
        | disc_type | fuel_price | credit_amount | pdl_description |
        | unit      | 20.00      | 10.00         | PDL FPR unit    |
        # Percentage PDL does not get to the transaction, will be resolved under RPOS-34284.
        #| percent   | 30.00      | 20.00         | PDL FPR perc    |



    @fast @manual
    # PDL disappears from transaction after dispensing fuel. Will be resolved in RPOS-34284.
    Scenario Outline: Grade selection is disabled. Allow combining PDL discounts with loyalty tenders. Configure PDL and local FPR discounts,
                      dispense a prepaid fuel by credit, validate discounts were correctly updated.
        # Set Allow combining PDL discounts with loyalty tenders to Yes
        Given the POS option 1117 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id     | unit_type              | is_apply_as_tender |
            | 004            | Loyalty Tender       | 10.00          | transaction    | loyalty tender   | GENERAL_SALES_QUANTITY | True               |
        And the POS has FPR discount configured
            | description    | reduction_value | disc_type           | disc_mode   | disc_quantity                 |
            | Loyalty FPR    | 2000            | FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE |
        And the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount 0.50 and quantity limit 0 for PrePay
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And a prepay with price <fuel_price> on the pump 1 is present in the transaction
        And the cashier tendered transaction with credit
        When the customer dispenses premium fuel for <fuel_price> price on the pump 1
        Then a FPR discount Loyalty FPR is in the previous transaction
        And a PDL discount <pdl_description> without a price is in the previous transaction
        And a fuel item premium with price <fuel_price> and volume <gallons> is in the previous transaction
        And a tender Loyalty Tender with amount 10.00 is in the previous transaction
        And a tender credit with amount <credit_amount> is in the previous transaction

        Examples:
            | disc_type | item_name      | fuel_price | gallons | credit_amount | pdl_description |
            | unit      | 4.000G Premium | 14.00      | 4.242   | 4.00          | PDL FPR unit    |
            #| percent   | 8.000G Premium | 16.00      | 8.0     | 6.00          | PDL FPR perc    |


    @positive @fast
    Scenario Outline: Grade selection is disabled. Allow combining PDL discounts with loyalty tenders. Configure a PDL discount with quantity limit,
                      local FPR discount, tender prepay by credit, verify the PDL discount is added to the transaction. Limit on the discount does not restrict the prepay amount.
        # Set Allow combining PDL discounts with loyalty tenders to Yes
        Given the POS option 1117 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id     | unit_type              | is_apply_as_tender |
            | 004            | Loyalty Tender       | 10.00          | transaction    | loyalty tender   | GENERAL_SALES_QUANTITY | True               |
        And the POS has FPR discount configured
            | description    | reduction_value | disc_type           | disc_mode   | disc_quantity                 |
            | Loyalty FPR    | 2000            | FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE |
        And the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount 0.50 and quantity limit <quantity_limit> for PrePay
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And a prepay with price <fuel_price> on the pump 1 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then the transaction is finalized
        And a FPR discount Loyalty FPR is in the previous transaction
        And a PDL discount <pdl_description> without a price is in the previous transaction
        And a tender credit with amount <credit_amount> is in the previous transaction
        And a tender Loyalty Tender with amount 10.00 is in the previous transaction
        And a pump 1 is authorized with a price of <fuel_price>

        Examples:
            | quantity_limit | disc_type | fuel_price | credit_amount | pdl_description |
            | 0              | unit      | 12.00      | 2.00          | PDL FPR unit    |
            | 3              | unit      | 12.00      | 2.00          | PDL FPR unit    |
            #| 100            | percent   | 16.00      | 6.00          | PDL FPR perc    |
            #| 3              | percent   | 12.00      | 2.00          | PDL FPR perc    |


    @manual
    # PDL disappears from transaction after dispensing fuel. Will be resolved in RPOS-34284.
    Scenario Outline: Grade selection is disabled. Allow combining PDL discounts with loyalty tenders. Configure a PDL discount with quantity limit,
                      local FPR discount, dispense a prepaid fuel by credit, cannot dispense more than PDL limit, validate discounts were correctly updated.
        # Set Allow combining PDL discounts with loyalty tenders to Yes
        Given the POS option 1117 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id     | unit_type              | is_apply_as_tender |
            | 004            | Loyalty Tender       | 10.00          | transaction    | loyalty tender   | GENERAL_SALES_QUANTITY | True               |
        And the POS has FPR discount configured
            | description    | reduction_value | disc_type           | disc_mode   | disc_quantity                 |
            | Loyalty FPR    | 2000            | FUEL_PRICE_ROLLBACK | SINGLE_ITEM | STACKABLE_AND_ALLOW_ONLY_ONCE |
        And the EPS simulator uses Default card configured to trigger <disc_type> PDL HDD discount with amount 0.50 and quantity limit <quantity_limit> for PrePay
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And a prepay with price <fuel_price> on the pump 1 is present in the transaction
        And the cashier tendered transaction with credit
        When the customer dispenses premium fuel for <fuel_price> price on the pump 1
        Then a FPR discount Loyalty FPR is in the previous transaction
        And a PDL discount <pdl_description> without a price is in the previous transaction
        And a fuel item premium with price <fuel_price> and volume <gallons> is in the previous transaction
        And a tender Loyalty Tender with amount 10.00 is in the previous transaction
        And a tender credit with amount <credit_amount> is in the previous transaction

        Examples:
            | quantity_limit | disc_type | item_name      | fuel_price | gallons | credit_amount | pdl_description |
            | 100            | unit      | 3.000G Premium | 12.00      | 3.00    | 2.00          | PDL FPR unit    |
            | 3              | unit      | 3.000G Premium | 12.00      | 3.0     | 2.00          | PDL FPR unit    |
            | 100            | percent   | 4.211G Premium | 16.00      | 8.0     | 6.00          | PDL FPR perc    |
            | 3              | percent   | 3.000G Premium | 12.00      | 3.0     | 2.00          | PDL FPR perc    |