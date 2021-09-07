@pos @loyalty
Feature: VIP Loyalty Message
    Display loyalty program message on Indoor Pinpad before Tender is initiated (RPOS-15954)
    Send Loyalty AUTH immediately after loyalty card is presented (if configured)
    Send Loyalty AUTH even if POS transaction has no items (if configured)
    BDD script developed as RPOS-16015

    Background:
        Given the POS has essential configuration
        And the Sigma simulator has essential configuration
        And the POS has the feature Loyalty enabled
        And the Sigma recognizes following cards
            | card_number       | card_description |
            | 12879784762398321 | Happy Card       |
        And the Sigma option RLMSendAuthAfterLoyaltyPresented is set to NONE
        And the POS has following sale items configured
            | barcode       | description  | price | discount |
            | 099999999990  | Sale Item A  | 0.99  | 0.20     |
            | 088888888880  | Sale Item B  | 1.99  | 0.50     |


    @pos @fast
    Scenario Outline: Loyalty AUTH is sent and VIP message is displayed after loyalty swipe
        # Basic test if LOYALTYAUTH is or is not sent after swipe based on RLMSendAuthAfterLoyaltyPresented value

        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And an item "Sale Item A" with barcode 099999999990 and price 0.99 is eligible for discount cash 0.20 when using loyalty card 12879784762398321
        And the Sigma option RLMSendAuthAfterLoyaltyPresented is set to <RLMSendAuthAfterLoyaltyPresented>
        When a customer adds a loyalty card with a number 12879784762398321 on the pinpad
        Then a loyalty card Happy Card is added to the transaction
        And the Sigma <action> receive request of type AUTH from POS

        Examples:
        | RLMSendAuthAfterLoyaltyPresented | action   |
        | NONE                             | does not |
        | POS                              | does     |
        | ICR                              | does not |
        | ALL                              | does     |

    @pos @fast
    Scenario: Loyalty discounts are added to POS transaction after loyalty swipe with VIP message display
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And an item "Sale Item A" with barcode 099999999990 and price 0.99 is eligible for discount cash 0.20 when using loyalty card 12879784762398321
        And the Sigma option RLMSendAuthAfterLoyaltyPresented is set to POS
        When a customer adds a loyalty card with a number 12879784762398321 on the pinpad
        Then a loyalty card Happy Card is added to the transaction
        And the Sigma does receive request of type AUTH from POS
        And a RLM discount Loyalty Discount with value of -0.20 is in the virtual receipt
        And a RLM discount Loyalty Discount with value of -0.20 is in the current transaction

    @pos @fast
    Scenario: Loyalty discounts are added after swipe and after transaction total if VR changes after swipe
        # --- this behavior might change in future if LOYALTYAUTH will be sent after each VR item

        Given the POS is in a ready to sell state
        And an item "Sale Item A" with barcode 099999999990 and price 0.99 is eligible for discount cash 0.20 when using loyalty card 12879784762398321
        And the Sigma option RLMSendAuthAfterLoyaltyPresented is set to POS
        And an item with barcode 088888888880 is present in the transaction
        When a customer adds a loyalty card with a number 12879784762398321 on the pinpad
        Then a loyalty card Happy Card is added to the transaction
        And the Sigma does receive request of type AUTH from POS
        Given an item with barcode 099999999990 is present in the transaction
        When the cashier totals the transaction to receive the RLM loyalty discount
        Then a RLM discount Loyalty Discount with value of -0.20 is in the virtual receipt
        And a RLM discount Loyalty Discount with value of -0.20 is in the current transaction

    @pos @fast
    Scenario Outline: POS sends Loyalty AUTH even when loyalty card is added to an empty/itemless VR
        Given the POS is in a ready to sell state
        And the Sigma option RLMSendAuthAfterLoyaltyPresented is set to <RLMSendAuthAfterLoyaltyPresented>
        When the cashier scans a barcode 12879784762398321
        Then a loyalty card Loyalty Item is added to the transaction
        And the Sigma <action> receive request of type AUTH from POS

        Examples:
        | RLMSendAuthAfterLoyaltyPresented | action   |
        | NONE                             | does not |
        | POS                              | does     |

    @pos @fast @pos_connect
    Scenario: No host message means no Messages in POS Connect GetState Response
        Given the POS is in a ready to sell state
        When the application sends |["Pos/GetState", {}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/GetStateResponse
        And the POS Connect response data does not contain element Messages

    @pos @fast @pos_connect
    Scenario: Host message reported in GetState response when present in AUTH, next GetState no longer contain message
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And an item "Sale Item A" with barcode 099999999990 and price 0.99 is eligible for discount cash 0.20 when using loyalty card 12879784762398321
        And the Sigma option RLMSendAuthAfterLoyaltyPresented is set to POS
        And next Sigma transaction has NVP soAUTHCUSTMSG set to Some Nice VIP Loyalty Message
        And next Sigma transaction has NVP noAUTHCUSTMSGTO set to 99
        And a loyalty card 12879784762398321 with description Happy Card is present in the transaction
        And the response data contain |{"Messages": [{"Payload": {"MessageTime": "*","Text": "Some Nice VIP Loyalty Message","Timeout": 99},"TopicId": "posconnect-v2-loyalty"}]}| after the application sent |["Pos/GetState", {}]| to the POS Connect
        When the application sends |["Pos/GetState", {}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/GetStateResponse
        And the POS Connect response data does not contain element Messages

    @pos @fast @pos_connect
    Scenario: Two loyalty cards in transaction result in two host message in GetState response
        Given the POS is in a ready to sell state
        And the Sigma recognizes following cards
            | card_number       | card_description |
            | 98765432101234567 | Happy Card2      |
        And an item with barcode 099999999990 is present in the transaction
        And an item "Sale Item A" with barcode 099999999990 and price 0.99 is eligible for discount cash 0.20 when using loyalty card 12879784762398321
        And the Sigma option RLMSendAuthAfterLoyaltyPresented is set to POS
        And next Sigma transaction has NVP soAUTHCUSTMSG set to Some Nice VIP Loyalty Message
        And next Sigma transaction has NVP noAUTHCUSTMSGTO set to 99
        And a loyalty card 12879784762398321 with description Happy Card is present in the transaction
        And next Sigma transaction has NVP soAUTHCUSTMSG set to Some Nice VIP Loyalty Message2
        And next Sigma transaction has NVP noAUTHCUSTMSGTO set to 9
        And a loyalty card 98765432101234567 with description Happy Card2 is present in the transaction
        When the application sends |["Pos/GetState", {}]| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/GetStateResponse
        And POS Connect response data contain |{"Messages": [{"Payload": {"MessageTime": "*","Text": "Some Nice VIP Loyalty Message","Timeout": 99},"TopicId": "posconnect-v2-loyalty"},{"Payload": {"MessageTime": "*","Text": "Some Nice VIP Loyalty Message2","Timeout": 9},"TopicId": "posconnect-v2-loyalty"}]}|
