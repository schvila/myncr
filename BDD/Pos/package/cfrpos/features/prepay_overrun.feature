@pos @prepay
Feature: Fuel prepay overruns
    This feature file focuses on pre-pay fuel transactions with overruns.

    Background: POS is ready to sell and no transaction is in progress
        Given the POS has essential configuration
        And the EPS simulator has essential configuration
        # Set Fuel Smart Prepay Overrun to Postpay option to False
        And the POS option 1849 is set to 0
        # Set Fuel credit prepay method to Auth and Capture
        And the POS option 1851 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0


    @fast
    Scenario: The credit prepay method is set to classic prepay, prepay is overrun, the overrun is moved to postpay
        # Fuel credit prepay method is set to Sale and Refund
        Given the POS option 1851 is set to 2
        And the POS is in a ready to sell state
        And a prepay for pump 1 with a price of 12.34 is tendered in credit and finalized
        When the customer dispensed regular for 13.34 price at pump 1
        Then the postpay for 1.00 is present on pump 1


    @fast
    Scenario: Smart prepay overrun to postpay is disabled, prepay is overrun,
        the overrun is added to the credit tender and pump sale is cleared
        Given the POS is in a ready to sell state
        And a prepay for pump 1 with a price of 12.34 is tendered in credit and finalized
        When the customer dispensed regular for 13.34 price at pump 1
        Then the postpay is not present on pump 1
        And a tender Credit with amount 13.34 is in the previous transaction


    @fast
    Scenario: Smart prepay overrun to postpay is disabled, customer pays in cash, prepay is overrun,
        the overrun is moved to postpay
        Given the POS is in a ready to sell state
        And a prepay for pump 1 with a price of 12.34 is tendered in cash and finalized
        When the customer dispensed regular for 13.34 price at pump 1
        Then the postpay for 1.00 is present on pump 1


    @fast
    Scenario: Smart prepay overrun to postpay is enabled, prepay is overrun, the overrun is moved to postpay
        # Set Fuel Smart Prepay Overrun to Postpay option to True
        Given the POS option 1849 is set to 1
        And the POS is in a ready to sell state
        And a prepay for pump 1 with a price of 12.34 is tendered in credit and finalized
        When the customer dispensed regular for 13.34 price at pump 1
        Then the postpay for 1.00 is present on pump 1


    @fast
    Scenario: Smart prepay overrun to postpay is disabled, prepay is overrun above the credit authorization limit,
        the overrun is moved to postpay
        Given the authorization amount for credit tender is 20.00
        And the POS is in a ready to sell state
        And a prepay for pump 1 with a price of 19.00 is tendered in credit and finalized
        When the customer dispensed regular for 21.00 price at pump 1
        Then the postpay for 2.00 is present on pump 1


    @fast
    Scenario Outline: Prepay is overrun, the correct dispensed value is in the postpay transaction
        Given the POS is in a ready to sell state
        And a prepay for pump <pump_id> with a price of <price_prepaid> is tendered in credit and finalized
        And the customer dispensed <grade> for <price_dispensed> price at pump <pump_id>
        When the cashier presses Pay button
        Then an item <fuel_item> with price <price_dispensed> is in the virtual receipt
        And a tender Credit with amount <price_prepaid> is in the virtual receipt

        Examples:
            | grade   | pump_id | price_prepaid | price_dispensed | fuel_item      |
            | Regular | 1       | 20.00         | 21.00           | 9.545G Regular |


    @fast
    Scenario Outline: Prepay is overrun, the postpay is paid for and transaction is finalized
        Given the POS is in a ready to sell state
        And a prepay for pump <pump_id> with a price of <price_prepaid> is tendered in credit and finalized
        And the customer dispensed <grade> for <price_dispensed> price at pump <pump_id>
        And the postpay from pump <pump_id> is present in the transaction
        When the cashier tenders the transaction with amount <price_rest> in cash
        Then the transaction is finalized

        Examples:
            | grade   | pump_id | price_prepaid | price_dispensed | price_rest | fuel_item       |
            | Regular | 1       | 20.00         | 25.00           | 5.00       | 10.500G Regular |