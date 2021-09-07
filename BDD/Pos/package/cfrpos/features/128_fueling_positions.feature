@pos @128_fp @manual
Feature: 128 fueling positions
    This feature file tests cases with 128 pumps configured on POS.

    Background:
        Given the POS has essential configuration
        And the POS has 128 pumps configured

    @positive
    Scenario Outline: Dispense fuel on pump, fuel item appears in the transaction
        Given the POS is in a ready to sell state
        And the customer dispensed <grade> for <price> price at pump <pump_id>
        When the cashier presses Pay button
		Then an item <fuel_item> with price <price> is in the virtual receipt

        Examples:
        | grade  | pump_id  | price | fuel_item      |
        | Diesel | 120      | 10.00 | 10.000G Diesel |


    @positive
    Scenario: Customer performs PAP transaction, verify the transaction appears in Scroll previous list
        Given the POS is in a ready to sell state
        And the customer performed PAP transaction on pump 100 for amount 50.00
        And the POS displays Scroll previous frame
        When the cashier selects last transaction on the Scroll previous list
        Then the selected line in Scroll previous contains following elements
            | element      | value |
            | node type    | Pump  |
            | node number  | 100   |
