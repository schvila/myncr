@pos @card_circuit_nvps @brand @shell_vantage
Feature: Card circuit NVPs
    This feature tests if a proper NVP is attached to the payment detail information in the transaction xml when a primary payment card is used.
    Secondary and non-electronic payments are not impacted.


    Background: POS is properly configured to be able to tender item in Shell Vantage solution
        Given RPOS is running with Shell Vantage brand
        And the EPS simulator has essential configuration


    @positive @fast
    Scenario Outline: Transaction is tendered with primary payment card, transaction xml contains a credit section with proper NVPs
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction 2 times
        And the cashier selected Credit tender without loyalty
        When the customer swipes a primary payment credit card <credit_card>
        Then the POS displays Please wait frame followed by main menu frame
        And <item_name> item detail from the previous transaction contains NVP <nvp>

        Examples:
        | credit_card  | nvp                                                                             | item_name |
        | AMEX         | {'name': 'RPOS.ExternalCardType', 'type': '4', 'persist': 'true', 'text': 'AX'} | credit    |
