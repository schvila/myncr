@pos @svc
Feature: SVC - Stored value cards
    This feature file tests cases with pre-tender and post-tender SVC card activation.

    Background: POS has essential configuration and EPS sim uses proper configuration
        Given the POS has essential configuration
        And the EPS simulator has essential configuration
        And the EPS simulator uses SVC card configuration
        And the POS has following sale items configured
            | barcode       | description  | price |
            | 099999999990  | Sale Item A  | 0.99  |


    @fast
    Scenario: Cashier selects Activate SVC button, Enter activation amount frame is displayed
        Given the POS is in a ready to sell state
        When the cashier presses SVC Activation button
        Then the POS displays Enter activation amount frame


    @manual
    Scenario: Cashier enters amount for SVC card post-tender activation, main menu frame is displayed, SVC card is in the transaction
        Given the POS is in a ready to sell state
        And the EPS simulator uses SVC post tender
        And the POS displays Enter activation amount frame
        When the cashier enters amount 10.0 on Enter activation amount frame
        Then the POS displays main menu frame
        And a gift card activated for amount 10.0 is in the current transaction


    @fast
    Scenario: Cashier enters amount for SVC card pre-tender activation, Card activation successful frame is displayed
        Given the POS is in a ready to sell state
        And the POS displays Enter activation amount frame
        When the cashier enters amount 10.0 on Enter activation amount frame
        Then the POS displays Card activation successful frame


    @fast
    Scenario: Cashier presses Go back button on Card activation successful frame, main menu frame is displayed, SVC card is in the transaction
        Given the POS is in a ready to sell state
        And the cashier entered amount 10.0 on Enter activation amount frame
        When the cashier presses Go back button on Card activation successful frame
        Then the POS displays main menu frame
        And a gift card activated for amount 10.0 is in the current transaction


    @fast
    Scenario: Cashier voids SVC card from the transaction, Card deactivation successful frame is displayed
        Given the POS is in a ready to sell state
        And a gift card activated for amount 10.0 is in the current transaction
        When the cashier presses Void-Item button on receipt frame
        Then the POS displays Card deactivation successful frame


    @fast
    Scenario: Cashier activates pre-tender SVC card with amount 100, transaction is finalized in cash
        Given the POS is in a ready to sell state
        And a gift card activated for amount 100.0 is in the current transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the transaction is finalized


    @fast
    Scenario: Tender the transaction partially with SVC pre-tender activated card and cash
        Given the POS is in a ready to sell state
        And a gift card activated for amount 10.0 is in the current transaction
        And an item with barcode 099999999990 is present in the transaction 10 times
        And a 5.30 credit partial tender is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the transaction is finalized


    @fast
    Scenario Outline: SVC card can be added to the transaction by swiping on the POS
        Given the POS is in a ready to sell state
        And the EPS simulator uses default card configuration
        And an item with barcode <barcode> is present in the transaction
        When the cashier swipes an epsilon card <card_name> on the POS
        Then the transaction is finalized
        And a tender credit with amount 1.06 is in the previous transaction

        Examples:
        | card_name      | barcode      |
        | SVC card       | 099999999990 |