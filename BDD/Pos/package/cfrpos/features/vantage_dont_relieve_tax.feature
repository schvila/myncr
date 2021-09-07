@pos @brand @shell_vantage 
Feature: Do Not Relieve Tax
    This feature adds the "reduce tax" option support as we know it from RPOS local discounts to Vantage host discounts (item level) in the
    form of "donotrelievetax" flag. If we set the "donotrelievetax" flag to true, then the tax will be applied on the amount before the 
    discount is added. If the flag is set to false, the tax will be applied on the amount after discount is applied. If we do not set the 
    flag, it will default to false and tax will be applied on the amount after discount is applied.

    Background:
        Given RPOS is running with Shell Vantage brand
        And the EPS simulator has essential configuration

    @fast
    Scenario Outline: Perform a Sale transaction by selecting an Item for which the DoNotRelieveTaxFlag tag is set to true
        Given the POS is in a ready to sell state
        And an item with barcode 033333333330 is present in the transaction
        And the tax amount from current transaction is 0.05
        And the cashier selected Credit tender with Loyalty
        And the customer swiped a loyalty card <card_name> at the pinpad
        And the cashier pressed Exact dollar button on the current frame
        When the customer swipes a primary payment <card_type> card <card>
        Then the transaction is finalized
        And a loyalty discount <discount_description> with value of <discount_value> is in the previous transaction
        And a tender credit with amount <final_amount> is in the previous transaction
        And the tax amount from previous transaction is <tax_amount>
        
        Examples:
        | card_type |    card       |   card_name   | tax_amount | discount_description | discount_value| final_amount |
        | credit    |    AMEX       | Shell Loyalty |    0.05    |      Reward G        |     0.32      |     0.42     |

    @fast
    Scenario Outline: Perform a Sale transaction by selecting an Item for which the DoNotRelieveTaxFlag tag is set to false
        Given the POS is in a ready to sell state
        And an item with barcode 066666666660 is present in the transaction
        And the tax amount from current transaction is 0.17
        And the cashier selected Credit tender with Loyalty
        And the customer swiped a loyalty card <card_name> at the pinpad
        And the cashier pressed Exact dollar button on the current frame
        When the customer swipes a primary payment <card_type> card <card>
        Then the transaction is finalized
        And a loyalty discount <discount_description> with value of <discount_value> is in the previous transaction
        And a tender credit with amount <final_amount> is in the previous transaction
        And the tax amount from previous transaction is <tax_amount>

        Examples:
        | card_type |    card       |   card_name   | tax_amount | discount_description | discount_value| final_amount |
        | credit    |    AMEX       | Shell Loyalty |    0.14    |      Reward D        |     0.35      |     2.18     |

    
    @fast
    Scenario Outline: Perform a Sale transaction by selecting an Item for which the DoNotRelieveTaxFlag tag is not set 
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the tax amount from current transaction is 0.07
        And the cashier selected Credit tender with Loyalty
        And the customer swiped a loyalty card <card_name> at the pinpad
        And the cashier pressed Exact dollar button on the current frame
        When the customer swipes a primary payment <card_type> card <card>
        Then the transaction is finalized
        And a loyalty discount <discount_description> with value of <discount_value> is in the previous transaction
        And a tender credit with amount <final_amount> is in the previous transaction
        And the tax amount from previous transaction is <tax_amount>

        Examples:
        | card_type |    card       |   card_name   | tax_amount | discount_description | discount_value| final_amount |
        | credit    |    AMEX       | Shell Loyalty |    0.05    |      Reward A        |     0.30      |     0.74     |
