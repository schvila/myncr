@pos @postpay
Feature: Postpay
    This feature file focuses on postpay fuel transactions.

    Background:
        Given the POS has essential configuration
        And the EPS simulator has essential configuration
        And the POS has following pumps configured
            | fueling_point | hose_number | product_number | unit_price |
            | 5             | 1           | 70000019       | 1000       |


    @fast @positive
    Scenario Outline: Customer dispenses fuel with automatic authorization, dispensed amount is visible on the pumpbar and can be tendered
        Given the pump <pump_id> has automatic postpay authorization configured
        And the POS is in a ready to sell state
        And the pump <pump_id> was authorized for <grade> fuel postpay
        When the customer dispenses fuel for <price> price at pump <pump_id>
        Then the postpay for <price> is present on pump <pump_id>

        Examples:
            | grade   | pump_id | price |
            | Regular | 2       | 5.00  |


    @fast @positive
    Scenario Outline: Customer dispenses fuel with manual authorization, dispensed amount is visible on the pumpbar and can be tendered
        Given the pump <pump_id> has manual postpay authorization configured
        And the POS is in a ready to sell state
        And the pump <pump_id> was authorized for <grade> fuel postpay
        When the customer dispenses fuel for <price> price at pump <pump_id>
        Then the postpay for <price> is present on pump <pump_id>

        Examples:
            | grade   | pump_id | price |
            | Regular | 1       | 5.00  |


    @fast @positive
    Scenario Outline: Dispense fuel on pump, fuel item appears in the transaction
        Given the POS is in a ready to sell state
        And the customer dispensed <grade> for <price> price at pump <pump_id>
        When the cashier presses Pay button
        Then an item <fuel_item> with price <price> is in the virtual receipt

        Examples:
            | grade  | pump_id | price | fuel_item      |
            | Diesel | 5       | 10.00 | 10.000G Diesel |


    @fast @positive @smoke
    Scenario Outline: Dispense fuel on pump, tender the transaction with postpay item, the postpay is no longer present on the pump
        Given the POS is in a ready to sell state
        And the customer dispensed <grade> for <price> price at pump <pump_id>
        And the postpay from pump <pump_id> is present in the transaction
        When the cashier tenders the transaction with amount <price> in cash
        Then the postpay is not present on pump <pump_id>

        Examples:
            | grade  | pump_id | price | fuel_item      |
            | Diesel | 5       | 10.00 | 10.000G Diesel |
