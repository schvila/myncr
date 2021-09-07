@pos @swipe_ahead
Feature: Swipe ahead
    This feature file focuses on validating the fix of a preexisting gap, where two tender processes started almost simultaneously
    (one on the pinpad by customer, one on the POS by cashier) would cause inconsistent declines. After fix, the pinpad entry is prioritized.

    Background: POS is properly configured for swipe ahead including sigma and epsilon
        Given the POS has essential configuration
        And the POS has the feature Loyalty enabled
        And the EPS simulator has essential configuration
        And the EPS simulator uses default card configuration
        And the POSCache simulator has default configuration
        And the POS has following sale items configured
            | barcode      | description | price  | external_id          |
            | 099999999990 | Sale item A | 0.99   | ITT-099999999990-0-1 |

    @fast @manual
    Scenario Outline: Customer's payment card is declined by host
        Given the POS is in a ready to sell state
        And the EPS simulator uses <card_name> card configuration
        And an item with barcode <barcode> is present in the transaction
        And the cashier tendered transaction with credit
        When the POSCache simulator sends a message <message_name> to the POS
        Then the POS displays Payment declined frame

        Examples:
        | barcode      | card_name       | message_name    |
        | 099999999990 | SwipeProgress   | PaymentDeclined |

    @fast @manual
    Scenario Outline: Customer cancels payment on the pinpad
        Given the POS is in a ready to sell state
        And the EPS simulator uses <card_name> card configuration
        And an item with barcode <barcode> is present in the transaction
        And the cashier tendered transaction with credit
        When the POSCache simulator sends a message <message_name> to the POS
        Then the POS displays Payment cancelled frame

        Examples:
        | barcode      | card_name       | message_name     |
        | 099999999990 | SwipeProgress   | PaymentCancelled |

    @fast
    Scenario Outline: Cashier starts the tendering process at the same time as the customer
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And the EPS simulator uses SwipeAhead card configuration
        And the cashier started tender the transaction with hotkey Exact Dollar in Credit
        When the EPS sends the card data obtained through swipe-ahead to the POS
        Then the transaction is finalized

        Examples:
        | barcode      |
        | 099999999990 |

    @fast @manual
    Scenario Outline: Customer presents (swipes) a valid payment on the pinpad - prompted to select a card type
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        When the customer initiates a payment by swiping a card <card> on the pinpad
        Then a transaction is in progress
        And an Epsilon transaction initiated on the pinpad is in progress
        And the Payment_Presented alert is not displayed

        Examples:
        | barcode      | card       |
        | 099999999990 | valid_card |


    @fast @manual
    Scenario Outline: Customer presents (swipes) a valid payment on the pinpad and selects the card type credit - payment ready, alert displayed
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And the customer initiated a payment by swiping a card <card> on the pinpad
        When the customer selects the type credit on the pinpad
        Then a transaction is in progress
        And an Epsilon transaction initiated on the pinpad is in progress
        And the Payment_Presented alert is displayed

        Examples:
        | barcode      | card       |
        | 099999999990 | valid_card |


    @fast @manual
    Scenario Outline: Customer swipes a valid payment card on the pinpad followed by cashier starting a tender process on the POS (credit/Exact Dollar)
                      before customer selects card type - POS displays Credit processing please wait frame
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And the customer initiated a payment by swiping a card <card> on the pinpad
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then the POS displays Credit processing frame
        And an Epsilon transaction initiated on the pinpad is in progress
        And the Payment_Presented alert is not displayed

        Examples:
        | barcode      | card       |
        | 099999999990 | valid_card |


    @fast @manual
    Scenario Outline: Customer swipes a valid card on the pinpad and selects the type credit followed by cashier starting a tender process on the POS
                      (credit/Exact Dollar) - transaction tendered
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And the customer completed a swipe ahead by swiping a card <card> on the pinpad and selecting the card type credit
        And the Payment_Presented alert is displayed
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then the POS displays Credit processing followed by main menu frame
        And no transaction is in progress
        And no Epsilon transaction is in progress
        And a tender Credit with amount <amount> is in the previous transaction
        And the Payment_Presented alert is not displayed

        Examples:
        | barcode      | card       | amount |
        | 099999999990 | valid_card | 1.06   |


    @fast @manual
    Scenario Outline: Cashier starts a tender process on the POS (credit/Exact Dollar) followed by the customer swiping a valid card on the pinpad and
                      selects the type credit - transaction tendered
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And the cashier selected the hotkey exact_dollar on credit tender frame
        And the customer initiated a payment by swiping a card <card> on the pinpad
        When the customer selects the type credit on the pinpad
        Then the POS displays Credit processing followed by main menu frame
        And no transaction is in progress
        And no Epsilon transaction is in progress
        And a tender Credit with amount <amount> is in the previous transaction
        And the Payment_Presented alert is not displayed

        Examples:
        | barcode      | card       | amount |
        | 099999999990 | valid_card | 1.06   |


    @fast @manual
    Scenario Outline: Customer swipes an invalid payment card on the pinpad followed by cashier starting a tender process on the POS (credit/Exact Dollar)
                      before customer selects card type - POS displays Credit processing please wait frame - then unknown card but stays on the frame and pinpad reprompts for swipe
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And the customer initiated a payment by swiping a card <card> on the pinpad
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then the POS displays Credit processing frame
        And an Epsilon transaction initiated on the pinpad is in progress
        And the Payment_Presented alert is not displayed

        Examples:
        | barcode      | card         |
        | 099999999990 | invalid_card |


    @fast @manual
    Scenario Outline: Customer swipes a valid loyalty card on the pinpad before cashier starts a tender process on the POS - loyalty card is added
                      to the transaction, main menu frame displayed
        Given the Sigma recognizes following cards
            | card_number | card_description   |
            | <card>      | <description>      |
        And the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        When a customer swipes a loyalty card with a number <card> on the pinpad
        Then a loyalty card <description> is added to the transaction
        And the POS displays main menu frame

        Examples:
        | barcode      | description  | card   |
        | 099999999990 | loyalty_card | 123456 |


    @fast @manual
    Scenario Outline: Customer swipes a valid loyalty card on the pinpad after the cashier starts a tender process on the POS - loyalty card is added
                      to the transaction, please swipe a card displayed
        Given the Sigma recognizes following cards
            | card_number | card_description   |
            | <card>      | <description>      |
        And the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And the cashier selected the hotkey exact_dollar on credit tender frame
        When a customer swipes a loyalty card with a number <card> on the pinpad
        Then a loyalty card <description> is added to the transaction
        And the POS displays Credit processing frame

        Examples:
        | barcode      | description  | card   |
        | 099999999990 | loyalty_card | 123456 |


    @fast @manual
    Scenario Outline: Customer swipes an invalid loyalty card on the pinpad after the cashier starts a tender process on the POS - POS displays
                      Credit processing please wait frame - then unknown card but stays on the frame and pinpad reprompts for swipe
        Given the Sigma recognizes but declines a card <card> with description <description>
        And the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And the cashier selected the hotkey exact_dollar on credit tender frame
        When a customer swipes a loyalty card with a number <card> on the pinpad
        Then a loyalty card <description> is not in the transaction
        And the POS displays Credit processing frame

        Examples:
        | barcode      | description      | card   |
        | 099999999990 | inv_loyalty_card | 654321 |


    @fast @manual
    Scenario Outline: Customer swipes a valid cobranded card on the pinpad before the cashier starts a tender process on the POS - loyalty card is added
                      to the transaction, customer prompted to select a card type for the payment
        Given the Sigma recognizes following cards
            | card_number | card_description   |
            | <card>      | <description>      |
        And the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        When a customer swipes a cobranded card with a number <card> on the pinpad
        Then a loyalty card <description> is added to the transaction
        And an Epsilon transaction initiated on the pinpad is in progress
        And the POS displays main menu frame

        Examples:
        | barcode      | description    | card   |
        | 099999999990 | cobranded_card | 234567 |


    @fast @manual
    Scenario Outline: Customer swipes a valid cobranded card on the pinpad before the cashier starts a tender process on the POS and selects the credit card type
                      - loyalty card is added to the transaction, Payment presented button is displayed
        Given the Sigma recognizes following cards
            | card_number | card_description   |
            | <card>      | <description>      |
        And the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And the customer initiated a payment by swiping a cobranded card <card> on the pinpad
        When the customer selects the type credit on the pinpad
        Then a loyalty card <description> is added to the transaction
        And an Epsilon transaction initiated on the pinpad is in progress
        And the Payment_Presented alert is displayed

        Examples:
        | barcode      | description    | card   |
        | 099999999990 | cobranded_card | 234567 |


    @fast @manual
    Scenario Outline: Customer swipes a valid cobranded card on the pinpad after the cashier starts a tender process on the POS - loyalty card is added
                      to the transaction, customer prompted to select a card type for the payment
        Given the Sigma recognizes following cards
            | card_number | card_description   |
            | <card>      | <description>      |
        And the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And the cashier selected the hotkey exact_dollar on credit tender frame
        When a customer swipes a cobranded card with a number <card> on the pinpad
        Then a loyalty card <description> is added to the transaction
        And an Epsilon transaction initiated on the pinpad is in progress
        And the POS displays Credit processing frame

        Examples:
        | barcode      | description    | card   |
        | 099999999990 | cobranded_card | 234567 |


    @fast @manual
    Scenario Outline: Customer swipes a valid cobranded card on the pinpad after the cashier starts a tender process on the POS and selects the credit card type
                      - loyalty card is added to the transaction, payment is finalized
        Given the Sigma recognizes following cards
            | card_number | card_description   |
            | <card>      | <description>      |
        And the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And the cashier selected the hotkey exact_dollar on credit tender frame
        And the customer swiped a cobranded card <card> on the pinpad
        When the customer selects the type credit on the pinpad
        Then the POS displays Credit processing followed by main menu frame
        And the transaction is finalized
        And no Epsilon transaction is in progress
        And a tender Credit with amount <amount> is in the previous transaction
        And the Payment_Presented alert is not displayed
        Then a loyalty card <description> is added to the transaction

        Examples:
        | barcode      | description    | card   | amount |
        | 099999999990 | cobranded_card | 234567 | 1.06   |


    @fast @manual
    Scenario Outline: Customer swipes a valid loyalty card on the pinpad and a valid cobranded card before cashier starts a tender process on the POS
                      - loyalty card is added to the transaction, message informing the loyalty from cobranded cannot be used is displayed on the pinpad,
                      payment flow continues with the cobranded card, select credit card type is displayed
        Given the Sigma recognizes following cards
            | card_number      | card_description        |
            | <loyalty_card>   | <loyalty_description>   |
            | <cobranded_card> | <cobranded_description> |
        And the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And a customer swiped a loyalty card with a number <loyalty_card> on the pinpad
        When a customer swipes a cobranded card with a number <cobranded_card> on the pinpad
        Then a loyalty card <loyalty_description> is added to the transaction
        And the POS displays main menu frame
        And the pinpad displays Additional loyalty cards not allowed message followed by card type selection
        And an Epsilon transaction initiated on the pinpad is in progress
        And the Payment_Presented alert is not displayed

        Examples:
        | barcode      | loyalty_description | loyalty_card   | cobranded_description | cobranded_card |
        | 099999999990 | loyalty_card        | 123456         | cobranded_card        | 234567         |


    @fast @manual
    Scenario Outline: Customer swipes a valid loyalty card on the pinpad, cashier selects the credit tender on the POS and customer swipes a valid cobranded card
                      - loyalty card is added to the transaction, message informing the loyalty from cobranded cannot be used is displayed on the pinpad and POS,
                      payment flow continues with the cobranded card, select credit card type is displayed
        Given the Sigma recognizes following cards
            | card_number      | card_description        |
            | <loyalty_card>   | <loyalty_description>   |
            | <cobranded_card> | <cobranded_description> |
        And the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And a customer swiped a loyalty card with a number <loyalty_card> on the pinpad
        And the cashier selected the hotkey exact_dollar on credit tender frame
        When a customer swipes a cobranded card with a number <cobranded_card> on the pinpad
        Then a loyalty card <loyalty_description> is added to the transaction
        And the POS displays Additional loyalty cards not allowed error
        And the pinpad displays Additional loyalty cards not allowed message followed by card type selection
        And an Epsilon transaction initiated on the pinpad is in progress
        And the Payment_Presented alert is not displayed

        Examples:
        | barcode      | loyalty_description | loyalty_card   | cobranded_description | cobranded_card |
        | 099999999990 | loyalty_card        | 123456         | cobranded_card        | 234567         |


    @glacial @manual
    Scenario Outline: Customer does not finish the pinpad operation after he swipes a valid payment card on the pinpad followed by cashier starting a tender
                      process on the POS - POS displays Credit processing please wait frame and shows a cancel button after the timeout
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And the customer initiated a payment by swiping a card <card> on the pinpad
        And the cashier selected the hotkey exact_dollar on credit tender frame
        When no operation is performed on the POS or pinpad for <timeout> seconds
        Then the POS displays Credit processing frame with a cancel button
        And an Epsilon transaction initiated on the pinpad is in progress
        And the Payment_Presented alert is not displayed

        Examples:
        | barcode      | card       | timeout |
        | 099999999990 | valid_card | 35      |