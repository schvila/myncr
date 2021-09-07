@pos
Feature: Tender groups
    Tender groups feature introduces the option to group tenders together to save space on the tenderbar. This group only has one button on the tenderbar which then opens a separate frame with a 4x4 grid of assigned tenders. This feature file focuses on tests around the tender flow using this new functionality

Background: The POS has essential configuration to be able to tender any items and configured tender groups.
    Given the POS has essential configuration
    And the EPS simulator has essential configuration
    And the POS has following tender groups configured
    | tender_group_id | description |
    | 123             | Group A     |
    And the POS has following tenders configured
    | tender_id  | description | tender_type_id | exchange_rate | currency_symbol | external_id  |
    | 111        | check       | 2              | 1             | $               | 111          |
    | 222        | credit      | 3              | 1             | $               | 222          |
    And tender group with id 123 contains tenders
    | tender_id |
    | 111       |
    | 222       |
    And the POS has following sale items configured
    | barcode      | description | price  |
    | 099999999990 | Sale Item A | 0.99   |
    | 088888888880 | Sale Item B | 1.99   |
    | 066666666660 | Sale Item D | 1.99   |


    @positive @fast
    Scenario: Configure a tender group and validate that selecting the tender group button opens a frame with the proper tenders in a grid
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the cashier selects tender group button with id 123 on the tenderbar
        Then the POS displays a grid of available tenders


    @positive @fast
    Scenario Outline: Press any tender button in tender group and verify the displayed frame.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the cashier selects the <tender> tender button with external id <external_id> from the tender group <group_id>
        Then the POS displays Ask tender amount <tender_frame> frame

        Examples:
        | tender      | external_id | tender_frame | group_id |
        | check        | 111        | check        | 123      |

    @positive @fast
    Scenario Outline: Tender the transaction with one of the tenders of tender group using an exact dollar hotkey.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction 4 times
        And the POS displays Amount selection frame after cashier selecting <tender> tender button with external id <external_id> from the tender group <group_id>
        When the cashier tenders the transaction with <quick_button> on the current frame
        Then the transaction is finalized
        And a tender Check with amount 4.24 is in the previous transaction

        Examples:
        | tender      | external_id  | group_id | quick_button |
        | check       | 111          | 123      | exact-dollar |

    @positive @fast
    Scenario Outline: Press go-back button in tender amount frame in tender group.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the POS displays Amount selection frame after cashier selecting <tender> tender button with external id <external_id> from the tender group <group_id>
        When the cashier presses Go back button
        Then the POS displays main menu frame
        And a transaction is in progress
        And an item Sale Item A with price 0.99 is in the virtual receipt
        And an item Sale Item A with price 0.99 is in the current transaction

        Examples:
        | tender      | external_id | group_id |
        | check       | 111         | 123      |