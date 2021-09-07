@pos @lottery
Feature: Lottery
    This feature tests cases with lottery sale/redemption being added in the transaction.

Background: The POS has essential configuration so we can add items to the transaction.
    Given the POS has essential configuration


    @fast
    Scenario: Press Lottery Sale button on the main menu frame, the Select lottery sale frame is displayed
        Given the POS is in a ready to sell state
        When the cashier presses Lottery Sale button
        Then the POS displays Select lottery sale frame


    @fast
    Scenario: Press Lottery Redemption button on the main menu frame, the Select lottery redemption frame is displayed
        Given the POS is in a ready to sell state
        When the cashier presses Lottery Sale button
        Then the POS displays Select lottery sale frame


	@fast
    Scenario Outline: Select a button to add lottery sale item in the transaction, the Age verication frame is displayed
        Given the POS is in a ready to sell state
        And the POS displays Select lottery sale frame
        When the cashier selects <button> button on Select lottery sale frame
        Then the POS displays the Age verification frame

        Examples:
        | button                 |
        | PDI Instant Lottery Tx |
        | PDI Machine Lottery Tx |


    @fast
    Scenario Outline: Add a lottery sale item with predefined amount in the transaction
        Given the POS is in a ready to sell state
        And the POS displays the Age verification frame after selling a lottery ticket <item_name> with price <price>
        When the cashier presses the instant approval button
        Then a lottery item <item_name> with price <price> is in the current transaction

        Examples:
        | item_name              | price |
        | PDI Instant Lottery Tx | 2.50  |
        | PDI Machine Lottery Tx | 5.00  |


    @fast
    Scenario: Press Instant lottery redemption button, the Select lottery prize type frame is displayed
        Given the POS is in a ready to sell state
        And the POS displays Select lottery redemption frame
        When the cashier selects PDI Instant Lottery Tx button on Select lottery redemption frame
        Then the POS displays Select lottery prize type frame


    @fast
    Scenario: Press Machine lottery redemption button, the Enter lottery amount frame is displayed
        Given the POS is in a ready to sell state
        And the POS displays Select lottery redemption frame
        When the cashier selects PDI Machine Lottery Tx button on Select lottery redemption frame
        Then the POS displays Enter lottery amount frame


    @fast
    Scenario: Select cash lottery prize type while adding Instant lottery redemption item,
               the Ask tender amount frame is displayed
        Given the POS is in a ready to sell state
        And the POS displays Select lottery prize type frame
        When the cashier selects cash on Select lottery prize type frame
        Then the POS displays Enter lottery amount frame


    @fast
    Scenario: Select ticket lottery prize type while adding Instant lottery redemption item,
               the Age verication frame is displayed
        Given the POS is in a ready to sell state
        And the cashier selected PDI Instant Lottery Tx button on Select lottery redemption frame
        When the cashier selects ticket on Select lottery prize type frame
        Then the POS displays the Age verification frame


    @fast
    Scenario Outline: Add incorrect age on Age verication frame, while attempting to add lottery sale item,
                      the POS displays Customer does not meet age requirement error
        Given the POS is in a ready to sell state
        And the cashier selected <lottery_name> button on Select lottery sale frame
        And the POS displays the Age verification frame
        When the cashier manually enters the customer's birthday 08-29-2008
        Then the POS displays an Error frame saying Customer does not meet age requirement

        Examples:
        | lottery_name           | error                        |
        | PDI Instant Lottery Tx | FAIL: PDI Instant Lottery Tx |
        | PDI Machine Lottery Tx | FAIL: PDI Instant Lottery Tx |
