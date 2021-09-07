@pos @loyalty
Feature: Sigma Loyalty
    This feature targets RLM functionality for basic cases like recognizing and adding a loyalty card into the transaction,
    evaluating whether this card and the items in the transaction are eligible for discounts and applying them, etc.

Background:
    Given the POS has essential configuration
    And the EPS simulator has essential configuration
    And the Sigma simulator has essential configuration
    And the POS has the feature Loyalty enabled
    And the Sigma recognizes following cards
        | card_number       | card_description |
        | 12879784762398321 | Happy Card       |
    And the POS has following sale items configured
        | barcode       | description  | price |
        | 099999999990  | Sale Item A  | 0.99  |
        | 088888888880  | Sale Item B  | 1.99  |

    @fast @smoke
    Scenario: Loyalty card can be added to the POS transaction through pinpad
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When a customer adds a loyalty card with a number 12879784762398321 on the pinpad
        Then a loyalty card Happy Card is added to the transaction


    @fast @smoke
    Scenario Outline: Loyalty discounts are added to the POS transaction after total
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And an item <description> with barcode <barcode> and price <price> is eligible for discount <type> <discount> when using loyalty card <card>
        And a loyalty card <card> with description Happy Card is present in the transaction
        When the cashier totals the transaction to receive the RLM loyalty discount
        Then a loyalty card Happy Card is added to the transaction
        And a RLM discount Loyalty Discount with value of <awarded_discount> is in the virtual receipt
        And a RLM discount Loyalty Discount with value of <awarded_discount> is in the current transaction

        Examples:
        | barcode      | description | price | type       | discount | card              | awarded_discount |
        | 099999999990 | Sale Item A | 0.99  | cash       | 0.50     | 12879784762398321 | -0.50            |
        | 088888888880 | Sale Item B | 1.99  | percentage | 0.35     | 12879784762398321 | -0.70            |


    @fast
    Scenario Outline: Loyalty card can be added to the transaction by swiping on the POS
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And the Sigma recognizes following cards
            | card_number | track1   | track2   |
            | <number>    | <track1> | <track2> |
        When the cashier swipes a Sigma loyalty card <card_name> on the POS
        Then a loyalty card Loyalty Item is added to the transaction

        Examples:
        | card_name      | barcode      | track1                       | track2                       | number           |
        | Kroger Loyalty | 099999999990 | 6042400114771120^CARD/S^0000 | 6042400114771120=0000?S^0000 | 6042400114771120 |


    @fast
    Scenario: Enable last chance loyalty, cashier presses credit tender button, Last chance loyalty frame is displayed
        # Set Loyalty prompt control to Prompt always
        Given the POS option 4214 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the cashier presses the credit tender button
        Then the POS displays Last chance loyalty frame


    @fast
    Scenario: Cashier presses Continue on Last chance loyalty frame, the Ask tender amount credit frame is displayed
        # Set Loyalty prompt control to Prompt always
        Given the POS option 4214 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the POS displays Last chance loyalty frame after selecting a credit tender button
        When the cashier presses Continue button
        Then the POS displays Ask tender amount credit frame


    @fast
    Scenario Outline: Customer swipes a loyalty card while Last chance loyalty frame is displayed on POS, the loyalty card and loyalty discount
                      are added into the transaction
        # Set Loyalty prompt control to Prompt always
        Given the POS option 4214 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And an item <description> with barcode <barcode> and price <price> is eligible for discount <type> <discount> when using loyalty card <card>
        And the POS displays Last chance loyalty frame after selecting a <type> tender button
        When a customer adds a loyalty card with a number <card> on the pinpad
        Then the POS displays Ask tender amount <type> frame
        And a loyalty card Happy Card is added to the transaction
        And a RLM discount Loyalty Discount with value of <awarded_discount> is in the virtual receipt
        And a RLM discount Loyalty Discount with value of <awarded_discount> is in the current transaction

        Examples:
        | barcode      | description | price | type       | discount | card              | awarded_discount |
        | 099999999990 | Sale Item A | 0.99  | cash       | 0.50     | 12879784762398321 | -0.50            |