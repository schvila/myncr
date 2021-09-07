@pos @other_functions
Feature: Other functions
This feature tests operations on Other functions frame

Background:
    Given the POS has essential configuration
    And the EPS simulator has essential configuration


    @positive
    Scenario: Press Version info button on Other functions frame, Version info frame is displayed
        Given the POS is in a ready to sell state
        And the POS displays Other functions frame
        When the cashier presses Version Info button
        Then the POS displays Version info frame


    @positive
    Scenario: Press Go back button on Version info frame, Other functions frame is displayed
        Given the POS is in a ready to sell state
        And the POS displays Version info frame
        When the cashier presses Go back button
        Then the POS displays Other functions frame


    @positive
    Scenario: Press Lock POS button on Other functions frame, Ask to lock terminal frame is displayed
        Given the POS is in a ready to sell state
        And the POS displays Other functions frame
        When the cashier presses Lock POS button
        Then the POS displays Ask to lock terminal frame


    @positive
    Scenario Outline: Attempt to press the buttons on receipt frame when the POS terminal is locked, POS stays on Terminal locked frame
        Given the POS is in a ready to sell state
        And the POS is locked
        When the cashier presses <button> button on receipt frame
        Then the POS displays Terminal lock frame

        Examples:
        | button          |
        | Other-functions |
        | Enter-plu/upc   |
        | Price-check     |
        | Change-Quantity |
        | Void-Item       |
        | Price-Override  |
        | Rcpt-scrolldown |
        | Rcpt-scrollup   |
        | Print-Receipt   |


    @positive
    Scenario: Attempt to lock the POS when a transaction is in progress, Cannot lock terminal with tran in progress error is displayed
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the POS displays Other functions frame
        When the cashier presses Lock POS button
        Then the POS displays Lock while transaction in progress error


    @positive
    Scenario: Press Show business day button on Other functions frame, the Current business day frame is displayed
        Given the POS is in a ready to sell state
        And the POS displays Other functions frame
        When the cashier presses Show business day button
        Then the POS displays Current business day frame


    @positive
    Scenario: Set Inactivity timeout value for POS, POS gets locked after timeout is reached
        #Inactivity time out on POS is set to 1 second
        Given the POS option 1506 is set to 1
        And the POS is in a ready to sell state
        When the POS is inactive for 3 seconds
        Then the POS displays Terminal lock frame


    @negative
    Scenario: Set Inactivity timeout value for POS, POS does not get locked after timeout is reached when a transaction is in progress
        #Inactivity time out on POS is set to 1 second
        Given the POS option 1506 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the POS is inactive for 3 seconds
        Then the POS displays main menu frame


    @manual
    Scenario: Attempt to swipe a payment card when the POS terminal is locked, the terminal remains locked
        Given the POS is in a ready to sell state
        And the POS is locked
        When the customer initiates a payment by swiping a card credit on the pinpad
        Then the POS displays Terminal lock frame
