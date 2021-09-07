@pos
Feature: Identify Employee
    This feature file tests the Identify Employee functionality.
    Pressing the button and entering the employee card number displays the employee's status.

Background: 
    Given the POS has essential configuration
    #Employee Discounts support is set to Yes
    And the POS option 1877 is set to 1
    And the Identify Employee button is configured
    And the Sigma simulator has essential configuration
    And the Sigma recognizes following cards
    | card_number  | card_description | is_employee_card     |
    | 01231234     | Employee Card    | True                 |

    @fast @positive
    Scenario: POS should display frame to enter Employee card number when the cashier presses Identify Employee button
        Given the POS is in a ready to sell state
        And the POS displays Other functions frame
        When the cashier presses Identify Employee button
        Then the POS displays Employee Identification frame

    @fast @positive
    Scenario: POS should display frame for manual card entry when the cashier presses Enter Card button
        Given the POS is in a ready to sell state
        And the POS displays Employee Identification frame
        When the cashier presses Enter Card button on Employee Identification frame
        Then the POS displays frame for manual card entry

    @fast @positive
    Scenario: POS should display Employee status when the cashier manually enters the employee card number.
        Given the POS is in a ready to sell state
        And the POS shows frame for manual card entry
        When the cashier manually enters the employee card 01231234
        Then the POS displays Employee Status frame
