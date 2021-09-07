@pos
Feature: Sign-in/Start shift
    This feature file focuses on the basic start shift flow as well as several scenarios for locking/unlocking the terminal and manager overrides.
    Background: The POS has essential configuration to be able to tender any items.
        Given the POS has essential configuration
        # "Starting amounts" pos option set to "Use end of shift count"
        And the POS option 1448 is set to 0
        And the POS has the following operators configured
            | operator_id | pin  | last_name  | first_name |
            | 70000000016 | 5678 | 5678       | Cashier    |
            | 70000000014 | 1234 | 1234       | Cashier    |
            | 70000000015 | 2345 | 2345       | Manager    |


    @fast @positive
    Scenario: Cashier presses the start shift button, prompt to input the user pin is displayed
        Given the POS is in a ready to start shift state
        When the cashier presses the Start shift button
        Then the POS displays Enter user code to start shift frame


    @fast @positive
    Scenario: Cashier presses the Go back button after selecting the Start shift button, Start shift frame is displayed again
        Given the POS is in a ready to start shift state
        And the cashier pressed the Start shift button
        When the cashier presses Go back button
        Then the POS displays the Start shift frame


    @fast @positive @smoke
    Scenario Outline: Cashier/manager inputs a correct PIN after pressing Start shift button, starting drawer count is
                      taken from the previous end shift count, new shift is started, main frame is displayed
        Given the POS is in a ready to start shift state
        And the cashier pressed the Start shift button
        When the cashier enters <pin> pin
        Then the POS displays main menu frame

    Examples:
        | pin  |
        | 1234 |
        | 2345 |


    @fast @positive
    Scenario Outline: Cashier inputs an incorrect PIN after pressing Start shift button, Operator not found in db error is displayed
        Given the POS is in a ready to start shift state
        And the cashier pressed the Start shift button
        When the cashier enters <pin> pin
        Then the POS displays Operator not found error

    Examples:
        | pin      |
        | 12345678 |
        | 0        |
        | 1243     |


    @fast @positive
    Scenario Outline: Cashier/manager inputs a correct PIN after pressing Start shift button, Enter starting drawer count
                      frame is displayed if only one tender is configured for starting counts (POS option 1448 set to 1)
        # "Starting amounts" pos option set to "Prompt for amount"
        Given the POS option 1448 is set to 1
        And the POS is in a ready to start shift state
        And the cashier pressed the Start shift button
        When the cashier enters <pin> pin
        Then the POS displays the Drawer count frame

    Examples:
        | pin  |
        | 1234 |
        | 2345 |


    @fast @positive
    Scenario Outline: Multiple tenders are configured for starting counts, Cashier/manager inputs a correct PIN after
                      pressing Start shift button, Starting count tender selection frame is displayed (POS option 1448 set to 1)
        # "Starting amounts" pos option set to "Prompt for amount"
        Given the POS option 1448 is set to 1
        And the POS has following tenders configured
            | tender_id  | description | tender_type_id | exchange_rate | currency_symbol | external_id  |
            | 111        | cash2       | 1              | 1             | $               | 111          |
            | 222        | cash3       | 1              | 1             | $               | 222          |
            | 333        | cash4       | 1              | 1             | $               | 333          |
            | 444        | cash5       | 1              | 1             | $               | 444          |
            | 555        | cash6       | 1              | 1             | $               | 555          |
        And the POS is in a ready to start shift state
        And the cashier pressed the Start shift button
        When the cashier enters <pin> pin
        Then the POS displays the Starting counts tender selection frame

    Examples:
        | pin  |
        | 1234 |
        | 2345 |


    @slow @positive
    Scenario: Multiple tenders are configured for starting counts, the POS asks to enter an amount in drawer after the
              cashier selected a tender.
        # "Starting amounts" pos option set to "Prompt for amount"
        Given the POS option 1448 is set to 1
        And the POS has following tenders configured
        | tender_id  | description | tender_type_id | exchange_rate | currency_symbol | external_id  |
        | 111        | cash2       | 1              | 1             | $               | 111          |
        | 222        | cash3       | 1              | 1             | $               | 222          |
        | 333        | cash4       | 1              | 1             | $               | 333          |
        | 444        | cash5       | 1              | 1             | $               | 444          |
        | 555        | cash6       | 1              | 1             | $               | 555          |
        And the POS is in a ready to start shift state
        And the POS displays the Starting counts tender selection frame
        When the cashier selects cash tender for starting count
        Then the POS displays the Drawer count frame


    @slow @positive
    Scenario: Multiple tenders are configured for starting counts, the POS starts a new shift after pressing the Done button,
              which gets displayed once all tender ending counts are entered.
        # "Starting amounts" pos option set to "Prompt for amount"
        Given the POS option 1448 is set to 1
        And the POS has following tenders configured
        | tender_id  | description | tender_type_id | exchange_rate | currency_symbol | external_id  |
        | 111        | cash2       | 1              | 1             | $               | 111          |
        | 222        | cash3       | 1              | 1             | $               | 222          |
        | 333        | cash4       | 1              | 1             | $               | 333          |
        | 444        | cash5       | 1              | 1             | $               | 444          |
        | 555        | cash6       | 1              | 1             | $               | 555          |
        And the POS is in a ready to start shift state
        And the POS displays the Starting counts tender selection frame after entering all tender amounts
        When the cashier presses the Done button
        Then the POS displays main menu frame


    @fast @positive
    Scenario Outline: Cashier/manager enters the starting count, Drawer amount confirmation prompt is displayed
                      (POS option 1448 set to 1)
        # "Starting amounts" pos option set to "Prompt for amount"
        Given the POS option 1448 is set to 1
        And the POS is in a ready to start shift state
        And the cashier entered <pin> pin after pressing Start shift button
        When the cashier enters the drawer amount <amount>
        Then the POS displays the Drawer amount confirmation prompt

    Examples:
        | pin  | amount |
        | 1234 | 25.00  |
        | 2345 | 0.00   |


    @fast @positive
    Scenario Outline: Cashier confirms the starting count, new shift is started, main frame is displayed
                      (POS option 1448 set to 1)
        # "Starting amounts" pos option set to "Prompt for amount"
        Given the POS option 1448 is set to 1
        And the POS is in a ready to start shift state
        And the cashier entered the drawer amount <amount> after starting a shift with pin <pin>
        When the cashier confirms the drawer amount
        Then the POS displays main menu frame

    Examples:
        | pin  | amount |
        | 1234 | 25.00  |
        | 2345 | 0.00   |


    @fast @positive
    Scenario Outline: Cashier declines the starting count, Enter starting drawer amount frame is displayed again
                      (POS option 1448 set to 1)
        # "Starting amounts" pos option set to "Prompt for amount"
        Given the POS option 1448 is set to 1
        And the POS is in a ready to start shift state
        And the cashier entered the drawer amount <amount> after starting a shift with pin <pin>
        When the cashier declines the drawer amount
        Then the POS displays the Drawer count frame

    Examples:
        | pin  | amount |
        | 1234 | 25.00  |
        | 2345 | 0.00   |


    @fast @positive
    Scenario Outline: Cashier/manager inputs a correct PIN after pressing Start shift button, starting drawer count is
                      a fixed amount, new shift is started, main frame is displayed (POS option 1448 set to 2)
        # "Starting amounts" pos option set to "Preset amount"
        Given the POS option 1448 is set to 2
        And the POS is in a ready to start shift state
        And the cashier pressed the Start shift button
        When the cashier enters <pin> pin
        Then the POS displays main menu frame

    Examples:
        | pin  |
        | 1234 |
        | 2345 |


  @fast @positive
  Scenario: Manager attempts to unlock a terminal locked by cashier, the confirm user override frame is displayed
    Given the POS is in a ready to sell state
    And the POS is locked
    When the manager enters 2345 pin on Terminal lock frame and presses unlock button
    Then the POS displays Confirm user override frame


  @fast @positive
  Scenario: Cashier attempts to unlock a terminal locked by manager, incorrect locking operator error is displayed
    Given the POS is in a ready to start shift state
    And the manager started a shift with PIN 2345
    And the POS is locked
    When the cashier enters 1234 pin on Terminal lock frame and presses unlock button
    Then the POS displays Incorrect locking operator error


  @fast @positive
  Scenario: Cashier attempts to unlock a terminal locked by another cashier with invalid user code, the operator not found error is displayed
    Given the POS is in a ready to sell state
    And the POS is locked
    When the cashier enters 2012 pin on Terminal lock frame and presses unlock button
    Then the POS displays Operator not found error


  @manual
  Scenario: Cashier attempts to unlock a terminal locked by another cashier, the override partial window is displayed
    Given the POS is in a ready to sell state
    And the POS is locked
    When the cashier enters 5678 pin on Terminal lock frame and presses unlock button
    Then the POS displays Override partial window


    @slow
    Scenario: Reboot the POS, terminal lock frame is displayed
        Given The POS is in a ready to sell state
        When the POS reboots
        Then the POS displays Terminal lock frame


    @slow
    Scenario: Reboot the POS after the shift is ended, start shift frame is displayed
        Given the POS is in a ready to start shift state
        When the POS reboots
        Then the POS displays the Start shift frame


    @fast
    Scenario: Press Enter button on Enter user code to start shift frame when no pin was entered for starting shift, an error is displayed
        Given the POS is in a ready to start shift state
        And the POS displays an Enter user code to start shift frame
        When the cashier presses Enter button on Enter user code to start shift frame
        Then the POS displays Operator not found error


    @fast
    Scenario: Press Go back button on Operator not found error frame, Enter user code to start shift frame is displayed
        Given the POS is in a ready to start shift state
        And the POS displays Operator not found error
        When the cashier presses Go back button
        Then the POS displays Enter user code to start shift frame


    @slow
    Scenario Outline: Cashier/manager starts the shift after cashier/manager ended shift, main menu frame is displayed
        Given the POS is in a ready to start shift state
        And the <operator_1> started a shift with PIN <pin_1>
        And the <operator_1> with pin <pin_1> ended the shift
        And the POS is in a ready to start shift state
        When the <operator_2> starts a shift with PIN <pin_2>
        Then the POS displays main menu frame

        Examples:
        | operator_1 | pin_1 | operator_2 | pin_2 |
        | cashier    | 1234  | manager    | 2345  |
        | manager    | 2345  | cashier    | 1234  |
        | cashier    | 1234  | cashier    | 5678  |