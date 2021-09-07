@pos @fuel_metrics
Feature: Fuel metrics
    This feature file focuses on checking of the fuel metrics in transactions.

    Background: POS is ready to sell and no transaction is in progress
        Given the POS has essential configuration
        And the EPS simulator has essential configuration
        And the POS has following pumps configured
            | fueling_point | hose_number | product_number | unit_price |
            | 5             | 1           | 70000019       | 1000       |
        # Set Fuel credit prepay method to Auth and Capture
        And the POS option 1851 is set to 1
        # Set Prepay Grade Select Type option as One Touch
        And the POS option 5124 is set to 1

    @fast @positive @prepay
    Scenario Outline: Fully dispense the prepaid fuel, prepay completion transaction is finalized.
        Given the POS is in a ready to sell state
        And a <grade> prepay for pump <pump_id> with a price of <price> is tendered in <tender_type> and finalized
        When the customer dispenses <grade> fuel for <price> price on the pump <pump_id>
        Then a fuel item <grade> with price <price> and volume <volume> is in the previous transaction
        And the POS finalizes the prepay completion transaction for price <price> at pump <pump_id>
        And fuel item <grade> detail from the previous transaction contains fuel metrics

        Examples:
            | grade    | pump_id | price | volume | tender_type |
            | Premium  | 1       | 25.00 | 6.25   | Cash        |
            | Midgrade | 2       | 20.00 | 6.25   | Credit      |


    @fast @positive @prepay
    Scenario Outline: Partially dispense the fuel prepaid by electronic tender, dispensed amount gets captured automatically,
                      completion transaction is finalized.
        Given the POS is in a ready to sell state
        And a <grade> prepay for pump <pump_id> with a price of <prepay_amount> is tendered in credit and finalized
        When the customer dispenses <grade> fuel for <dispense_price> price on the pump <pump_id>
        Then a fuel item <grade> with price <dispense_price> and volume <dispense_volume> is in the previous transaction
        And fuel item <grade> detail from the previous transaction contains fuel metrics
        And a tender credit with amount <dispense_price> is in the previous transaction

        Examples:
            | grade   | pump_id | prepay_amount | dispense_price | dispense_volume |
            | Premium | 1       | 25.00         | 21.00          | 5.00            |
            | Premium | 2       | 25.00         | 12.60          | 3.00            |


    @fast @positive @prepay
    Scenario Outline: Refund an underdispensed prepay tendered by non-electronic tender, customer receives change back,
                      completion transaction is finalized.
        Given the POS is in a ready to sell state
        And a <grade> prepay for pump <pump_id> with a price of <prepay_amount> is tendered in cash and finalized
        And the customer dispensed prepaid <grade> fuel for <dispense_price> price on the pump <pump_id>
        When the cashier refunds the fuel from pump <pump_id>
        Then a fuel item <grade> with price <dispense_price> and volume <dispense_volume> is in the previous transaction
        And fuel item <grade> detail from the previous transaction contains fuel metrics
        And a tender cash with amount <prepay_amount> is in the previous transaction
        And a tender cash with amount -<refund_amount> is in the previous transaction

        Examples:
            | grade   | pump_id | prepay_amount | dispense_price | dispense_volume | refund_amount |
            | Premium | 1       | 25.00         | 20.00          | 5.00            | 5.00          |


    @fast @prepay
    Scenario Outline: Cancel the prepaid fuel, prepay completion transaction is finalized. Refund a prepay tendered by non-electronic tender, customer receives money back,
                      completion transaction is finalized and fuel item does not contain fuel metrics.
        Given the POS is in a ready to sell state
        And a <grade> prepay for pump <pump_id> with a price of <prepay_amount> is tendered in cash and finalized
        When the cashier presses the cancel prepay button on POS
        And the cashier refunds the fuel from pump <pump_id>
        Then fuel item <grade> detail from the previous transaction does not contain fuel metrics
        And a tender cash with amount <prepay_amount> is in the previous transaction
        And a tender cash with amount -<prepay_amount> is in the previous transaction

        Examples:
            | grade   | pump_id |prepay_amount |
            | Premium | 1       | 25.00        |


    @fast @positive @postpay
    Scenario Outline: Dispense fuel on pump, fuel item appears in the transaction.
        Given the POS is in a ready to sell state
        And the customer dispensed <grade> for <price> price at pump <pump_id>
        When the cashier presses Pay button
        Then fuel item <grade> detail in the current transaction contains fuel metrics

        Examples:
            | grade  | pump_id | price |
            | Diesel | 5       | 10.00 |

