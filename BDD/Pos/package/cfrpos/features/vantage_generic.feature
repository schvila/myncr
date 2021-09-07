@pos @vantage_generic @brand @shell_vantage
Feature: Vantage generic
    This feature file tests Shell Vantage brand cases not related to a specific feature.

    Background:
        Given RPOS is running with Shell Vantage brand
        And the EPS simulator has essential configuration
        And the POS has following sale items configured
        | barcode     | description     | price  |
        | 7777107     | Cty+Cnty+State  | 10.00  |

    @fast
    Scenario: Select credit tender button, please wait frame is displayed on the POS while waiting for a payment
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the cashier selects Credit tender without loyalty
        Then the POS displays Please wait frame


    @fast
    Scenario Outline: Transaction is tendered with primary payment card, no transaction is in progress
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction 2 times
        And the cashier selected Credit tender without loyalty
        When the customer swipes a primary payment <card_type> card <card>
        Then the transaction is finalized

        Examples:
        | card_type | card  |
        | debit     | Debit |
        | credit    | AMEX  |


    @fast
    Scenario: Select credit tender button with mobile payment enabled, scan barcode frame is displayed
        Given mobile payments are enabled on wincor side
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the cashier selects Credit tender without loyalty
        Then the POS displays Scan barcode credit frame


    @manual
    Scenario: Select credit tender button with secondary mobile payment enabled, barcode is not recognized by Wincor, transaction is finalized by EPS
        Given the EPS is using the default configuration
        And the GCM recognizes the barcode 782603469036000967 as an EPS barcode
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And mobile payments are enabled on wincor side
        And the POS displayed Scan barcode frame after selecting credit tender
        When the customer scans a barcode 782603469036000967
        Then the request to process a payment is sent to EPS
        And the transaction is finalized
        And a tender Credit with amount 1.06 is in the previous transaction.


    @manual
    Scenario: Select credit tender button with primary mobile payment enabled, barcode is recognized by Wincor, transaction is finalized
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And mobile payments are enabled on wincor side
        And the POS displayed Scan barcode frame after selecting credit tender
        When the customer scans a barcode Mobile1234567890
        Then the transaction is finalized
        And a tender Credit with amount 1.06 is in the previous transaction


    @fast
    Scenario Outline: Add an item with quantity lower than needed for loyalty discount to be applied, verify no loyalty discount is added to the transaction
        Given the POS is in a ready to sell state
        And an item with barcode 7777107 is present in the transaction <count> times
        And the cashier selected Credit tender with loyalty <card_name>
        When the customer swipes a primary payment <card_type> card <card>
        Then the transaction is finalized
        And a tender credit with amount <amount> is in the previous transaction
        And a loyalty discount <discount_description> with value of <discount_value> is not in the previous transaction
        
        Examples:
        | card_type | card | card_name     | discount_description | discount_value | count | amount |
        | credit    | AMEX | Shell Loyalty |      Reward New      |     1.69       |   1   | 10.70  |


    @fast
    Scenario Outline: Add an item with quantity needed for loyalty discount to be applied, verify loyalty discount is added to the transaction
        Given the POS is in a ready to sell state
        And an item with barcode 7777107 is present in the transaction <count> times
        And the cashier selected Credit tender with loyalty <card_name>
        When the customer swipes a primary payment <card_type> card <card>
        Then the transaction is finalized
        And a tender credit with amount <amount> is in the previous transaction
        And a loyalty discount <discount_description> with value of <discount_value> is in the previous transaction
        
        Examples:
        | card_type | card |   card_name   | discount_description | discount_value | count | amount |
        | credit    | AMEX | Shell Loyalty |      Reward New      |     1.69       |   2   | 19.59  |


    @fast
    Scenario Outline: Add an item with quantity larger than needed for loyalty discount to be applied verify loyalty discount is added to the transaction with correct quantity.
        Given the POS is in a ready to sell state
        And an item with barcode 7777107 is present in the transaction <count> times
        And the cashier selected Credit tender with loyalty <card_name>
        When the customer swipes a primary payment <card_type> card <card>
        Then the transaction is finalized
        And a tender credit with amount <amount> is in the previous transaction
        And a loyalty discount <discount_description> with value of <discount_value> is in the previous transaction
        
        Examples:
        | card_type | card |   card_name   | discount_description | discount_value | count | amount |
        | credit    | AMEX | Shell Loyalty |      Reward New      |     1.69       |   5   | 51.69  |


    @manual
    Scenario Outline: Void an item needed for loyalty discount after loyalty discount is applied, verify loyalty discount is removed from the transaction
        Given the POS is in a ready to start shift state
        And the manager started a shift with PIN 2345
        And an item with barcode 7777107 is present in the transaction <count> times
        And the cashier selected Credit tender with Loyalty
        And the cashier presses Go back button on Credit Tender frame
        And the cashier pressed Void item button <count2> times  
        And the cashier selected Credit tender without prompt with loyalty <card_name>
        When the customer swipes a primary payment <card_type> card <card>
        Then the transaction is finalized
        And a tender credit with amount <amount> is in the previous transaction
        And a loyalty discount <discount_description> with value of <discount_value> is not in the previous transaction
        
        Examples:
        | card_type | card |   card_name   | discount_description | discount_value| count | count2 | amount |
        | credit    | AMEX | Shell Loyalty |      Reward New      |     1.69      |   2   |    1   | 10.70  |


    @manual
    Scenario Outline: Void an item with quantity greater than needed for loyalty discount after loyalty discount is applied, verify loyalty discount is in the transaction
        Given the POS is in a ready to start shift state
        And the manager started a shift with PIN 2345
        And an item with barcode 7777107 is present in the transaction <count> times
        And the cashier selected Credit tender with Loyalty
        And the cashier presses Go back button on Credit Tender frame
        And the cashier pressed Void item button <count2> times
        And the cashier selected Credit tender without prompt with loyalty <card_name>
        When the customer swipes a primary payment <card_type> card <card>
        Then the transaction is finalized
        And a tender credit with amount <amount> is in the previous transaction
        And a loyalty discount <discount_description> with value of <discount_value> is in the previous transaction
        
        Examples:
        | card_type | card |   card_name   | discount_description | discount_value | count | count2 | amount |
        | credit    | AMEX | Shell Loyalty |      Reward New      |     1.69       |   5   |    1   | 40.99  |
