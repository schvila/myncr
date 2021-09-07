@pos
Feature: End Shift
    End shift feature should cover the possible end shift flows with ending counts, safe drops and cashier sign out.

Background: Cashier should be signed in so he can go through end shift flow.
    Given the POS has essential configuration
    # End shift - Safe drops is set to No safe drop on EOS
    And the POS option 1908 is set to 2

@slow @positive
Scenario: Multiple tenders are configured for ending counts, the POS asks to select a tender to perform ending counts
          after the cashier presses the end shift button.
    Given the POS has following tenders configured
    | tender_id  | description | tender_type_id | exchange_rate | currency_symbol | external_id  |
    | 111        | cash2       | 1              | 1             | $               | 111          |
    | 222        | cash3       | 1              | 1             | $               | 222          |
    | 333        | cash4       | 1              | 1             | $               | 333          |
    | 444        | cash5       | 1              | 1             | $               | 444          |
    | 555        | cash6       | 1              | 1             | $               | 555          |
    And the POS is in a ready to sell state
    When the cashier presses the End shift button
    Then the POS displays the Ending count tender selection frame

@slow @positive
Scenario: Multiple tenders are configured for ending counts, the POS asks to enter an amount in drawer after the cashier
          selected a tender.
    Given the POS has following tenders configured
    | tender_id  | description | tender_type_id | exchange_rate | currency_symbol | external_id  |
    | 111        | cash2       | 1              | 1             | $               | 111          |
    | 222        | cash3       | 1              | 1             | $               | 222          |
    | 333        | cash4       | 1              | 1             | $               | 333          |
    | 444        | cash5       | 1              | 1             | $               | 444          |
    | 555        | cash6       | 1              | 1             | $               | 555          |
    And the POS is in a ready to sell state
    And the POS displays the Ending count tender selection frame
    When the cashier selects cash tender for ending count
    Then the POS displays the Drawer count frame

@slow @positive
Scenario: Multiple tenders are configured for ending counts, the POS asks the cashier for PIN after pressing the Done button,
          which gets displayed once all tender ending counts are entered.
    Given the POS has following tenders configured
    | tender_id  | description | tender_type_id | exchange_rate | currency_symbol | external_id  |
    | 111        | cash2       | 1              | 1             | $               | 111          |
    | 222        | cash3       | 1              | 1             | $               | 222          |
    | 333        | cash4       | 1              | 1             | $               | 333          |
    | 444        | cash5       | 1              | 1             | $               | 444          |
    | 555        | cash6       | 1              | 1             | $               | 555          |
    And the POS is in a ready to sell state
    And the POS displays the Ending count tender selection frame after entering all tender amounts
    When the cashier presses the Done button
    Then the POS displays the Enter pin to end shift frame

@slow @positive
Scenario: The POS asks to enter an amount in drawer after the cashier presses the end shift button if only one tender
          is configured for starting/ending counts.
    Given the POS is in a ready to sell state
    When the cashier presses the End shift button
    Then the POS displays the Drawer count frame

@fast @positive
Scenario: The POS asks for confirmation after the cashier enters an amount to drawer count.
    Given the POS is in a ready to sell state
    And the POS displays the Drawer count frame
    When the cashier enters the drawer amount 25.25
    Then the POS displays the Drawer amount confirmation prompt

@fast @positive
Scenario: The POS asks for entering an amount into the drawer after the cashier declines the previous amount.
    Given the POS is in a ready to sell state
    And the POS displays the Drawer amount correct prompt
    When the cashier declines the drawer amount
    Then the POS displays the Drawer count frame

@fast @positive @smoke
Scenario: The shift is ended and cashier signed out after the cashier enters his pin.
    Given the POS is in a ready to sell state
    And the POS displays the Drawer amount correct prompt
    And the cashier confirmed the drawer amount
    When the cashier enters 1234 pin
    Then the POS displays the Start shift frame
    And the shift is closed
    And no cashier is signed in to the POS

@fast @manual
Scenario: The POS asks for performing safe drop after the cashier presses the end shift button.
    # End shift - Safe drops is set to Prompted safe drop on EOS
    Given the POS option 1908 is set to 1
    And the POS is in a ready to sell state
    When the cashier presses the end shift button
    Then the POS displays the Perform final safe drop prompt
    # The safe drop does not have correct metadata
    # Will be solved after Jira task RPOS-6966

@fast @manual
Scenario: The POS asks for entering an amount into the drawer after the cashier declines the safe drop.
    # End shift - Safe drops is set to Prompted safe drop on EOS
    Given the POS option 1908 is set to 1
    And the POS is in a ready to sell state
    And the POS displays the Perform final safe drop prompt
    When the cashier declines to perform safe drop
    Then the POS displays the Drawer count frame

@fast @manual
Scenario: The POS asks for entering an amount to safe drop after the cashier confirms the safe drop prompt.
    # End shift - Safe drops is set to Prompted safe drop on EOS
    Given the POS option 1908 is set to 1
    And the POS is in a ready to sell state
    And the POS displays the Perform final safe drop prompt
    When the cashier confirms to perform safe drop
    Then the POS displays the Cash safe drop amount frame

@fast @manual
Scenario: The POS asks for entering an amount into the drawer after the cashier enters an amount to safe drop.
    # End shift - Safe drops is set to Prompted safe drop on EOS
    Given the POS option 1908 is set to 1
    And the POS is in a ready to sell state
    And the cashier confirmed the Safe drop prompt
    When the cashier enters the safe drop amount 35.00
    Then the POS displays the Drawer count frame

@fast @manual
Scenario: The POS asks for entering an amount to safe drop after the cashier presses the end shift button.
    # End shift - Safe drops is set to Safe drop on EOS required
    Given the POS option 1908 is set to 0
    And the POS is in a ready to sell state
    When the cashier presses the End shift button
    Then the POS displays the Cash safe drop amount frame

@fast @manual
Scenario: The cashier is asked to select tender to safe drop after he presses the end shift button.
    # End shift - Safe drops is set to Safe drop on EOS required
    Given the POS option 1908 is set to 0
    And the POS is in a ready to sell state
    And the cash tender is configured to be available for safe drops
    When the cashier presses the End shift button
    Then the POS displays the Safe drop tender selection frame

@fast @manual
Scenario: The cashier is asked for entering an amount into safe drop after he selects the tender.
    # End shift - Safe drops is set to Safe drop on EOS required
    Given the POS option 1908 is set to 0
    And the POS is in a ready to sell state
    And the cash tender is configured to be available for safe drops
    And the POS displays the Safe drop tender selection frame
    When the cashier selects cash tender for safe drop
    Then the POS displays the Cash safe drop amount frame

@fast @manual
Scenario: The cashier selected tender and an amount and he confirms to finish the safe drop.
    # End shift - Safe drops is set to Safe drop on EOS required
    Given the POS option 1908 is set to 0
    And the POS is in a ready to sell state
    And the cash tender is configured to be available for safe drops
    And the POS displays the Safe drop tender selection frame after safe drop done
    When the cashier confirms to finish the safe drop
    Then the POS displays the Drawer count frame
