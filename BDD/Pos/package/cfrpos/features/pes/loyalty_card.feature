@pos @pes
Feature: Promotion Execution Service - loyalty card
    This feature file focuses on operations with PES loyalty card.

    Background: POS is configured for PES feature
        Given the POS has essential configuration
        And the POS is configured to communicate with PES
        # Cloud Loyalty Interface is set to PES
        And the POS option 5284 is set to 1
        And the nep-server has default configuration
        And the POS recognizes following PES cards
            | card_definition_id | card_role  | card_name     | barcode_range_from     | barcode_range_to       | card_definition_group_id | track_format_1 | track_format_2 | mask_mode |
            | 70000001142        | 3          | PES card      | 3104174102936582       | 3104174102936583       | 70000010042              | bt%at?         | bt;at?         | 21        |
            | 70000001144        | 3          | PES card 2    | 3104174102936584       | 3104174102936585       | 70000010044              | bt%at?         | bt;at?         | 21        |
            | 70000001143        | 3          | PES card long | 8018131041741029365821 | 8018131041741029365821 | 70000010043              | bt%at?         | bt;at?         | 21        |
        And the POS has the feature Loyalty enabled
        And the Sigma simulator has essential configuration
        And the Sigma recognizes following cards
            | card_number       | card_description |
            | 12879784762398321 | Sigma Card       |
        And the POSCache simulator has default configuration


    @fast
    Scenario Outline: Scan a PES loyalty card, the card appears in VR and is sent to the PES.
        Given the POS is in a ready to sell state
        When the cashier scans PES loyalty card <card_number>
        Then a card <card_name> with value of 0.00 is in the virtual receipt
        And a card <card_name> with value of 0.00 is in the current transaction
        And the POS sends a card with number <card_number> to PES
        And the pinpad was notified that a PES card was added to the transaction

        Examples:
        | card_number            | card_name     |
        | 3104174102936582       | PES card      |
        | 8018131041741029365821 | PES card long |


    @fast
    Scenario Outline: Swipe a PES loyalty card on pinpad, the card appears in VR and is sent to the PES.
        Given the POS is in a ready to sell state
        When a customer swipes a PES loyalty card with number <card_number> on pinpad
        Then a card <card_name> with value of 0.00 is in the virtual receipt
        And a card <card_name> with value of 0.00 is in the current transaction
        And the POS sends a card with number <card_number> to PES with swipe entry method
        And the pinpad was notified that a PES card was added to the transaction

        Examples:
        | card_number            | card_name     |
        | 3104174102936582       | PES card      |
        | 8018131041741029365821 | PES card long |


    @fast
    Scenario Outline: Swipe a PES loyalty card on POS, the card appears in VR and is sent to the PES.
        Given the POS is in a ready to sell state
        When the cashier swipes a PES loyalty card with number <card_number> on the POS
        Then a card <card_name> with value of 0.00 is in the virtual receipt
        And a card <card_name> with value of 0.00 is in the current transaction
        And the POS sends a card with number <card_number> to PES with swipe entry method
        And the pinpad was notified that a PES card was added to the transaction

        Examples:
        | card_number            | card_name     |
        | 3104174102936582       | PES card      |
        | 8018131041741029365821 | PES card long |


    @fast
    Scenario Outline: Manually enter a PES loyalty card on POS, the card appears in VR and is sent to the PES.
        Given the POS is in a ready to sell state
        When the cashier manually adds a PES loyalty card with number <card_number> on the POS
        Then a card <card_name> with value of 0.00 is in the virtual receipt
        And a card <card_name> with value of 0.00 is in the current transaction
        And the POS sends a card with number <card_number> to PES with manual entry method
        And the pinpad was notified that a PES card was added to the transaction

        Examples:
        | card_number            | card_name     |
        | 3104174102936582       | PES card      |
        | 8018131041741029365821 | PES card long |


    @fast
    Scenario Outline: Scan a PES loyalty card with another PES/sigma card already in transaction, Additional loyalty
                      cards not allowed error is displayed on the POS, second card is not added to transaction.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And <step_to_use> is present in the transaction
        When the cashier scans PES loyalty card 3104174102936582
        Then the POS displays Additional loyalty cards not allowed error
        And a card <card_name> with value of 0.00 is not in the virtual receipt
        And a card <card_name> with value of 0.00 is not in the current transaction
        And the POS does not send any requests after last action

        Examples:
        | step_to_use                                              | card_number            | card_name |
        | a PES loyalty card <card_number>                         | 3104174102936584       | PES card  |
        | a PES loyalty card <card_number>                         | 8018131041741029365821 | PES card  |
        | a loyalty card <card_number> with description Sigma Card | 12879784762398321      | PES card  |


    @fast
    Scenario Outline: Swipe a PES loyalty card on pinpad, with another PES/sigma card already in transaction, Additional
                      loyalty cards not allowed error is displayed on the pinpad, second card is not added to transaction.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And <step_to_use> is present in the transaction
        When a customer swipes a PES loyalty card with number 3104174102936582 on pinpad
        Then a card <card_name> with value of 0.00 is not in the virtual receipt
        And a card <card_name> with value of 0.00 is not in the current transaction
        And the POS does not send any requests after last action
        And the pinpad displays Additional Loyalty Cards Not Allowed message

        Examples:
        | step_to_use                                              | card_number            | card_name |
        | a PES loyalty card <card_number>                         | 3104174102936584       | PES card  |
        | a PES loyalty card <card_number>                         | 8018131041741029365821 | PES card  |
        | a loyalty card <card_number> with description Sigma Card | 12879784762398321      | PES card  |


    @fast
    Scenario Outline: Swipe a PES loyalty card on POS, with another PES/sigma card already in transaction, Additional loyalty
                      cards not allowed error is displayed on the POS, second card is not added to transaction.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And <step_to_use> is present in the transaction
        When the cashier swipes a PES loyalty card with number 3104174102936582 on the POS
        Then the POS displays Additional loyalty cards not allowed error
        And a card <card_name> with value of 0.00 is not in the virtual receipt
        And a card <card_name> with value of 0.00 is not in the current transaction
        And the POS does not send any requests after last action

        Examples:
        | step_to_use                                              | card_number            | card_name |
        | a PES loyalty card <card_number>                         | 3104174102936584       | PES card  |
        | a PES loyalty card <card_number>                         | 8018131041741029365821 | PES card  |
        | a loyalty card <card_number> with description Sigma Card | 12879784762398321      | PES card  |


    @fast
    Scenario Outline: Manually enter a PES loyalty card on POS, with another PES/sigma card already in transaction, Additional loyalty
                      cards not allowed error is displayed on the POS, second card is not added to transaction.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And <step_to_use> is present in the transaction
        When the cashier manually adds a PES loyalty card with number 3104174102936582 on the POS
        Then the POS displays Additional loyalty cards not allowed error
        And a card <card_name> with value of 0.00 is not in the virtual receipt
        And a card <card_name> with value of 0.00 is not in the current transaction
        And the POS does not send any requests after last action

        Examples:
        | step_to_use                                              | card_number            | card_name |
        | a PES loyalty card <card_number>                         | 3104174102936584       | PES card  |
        | a PES loyalty card <card_number>                         | 8018131041741029365821 | PES card  |
        | a loyalty card <card_number> with description Sigma Card | 12879784762398321      | PES card  |


    @fast
    Scenario Outline: Change the quantity of the item, PES loyalty card is in the transaction, the PES card and item with updated quantity appear in VR.
        Given the POS is in a ready to sell state
        And a PES loyalty card <card_number> is present in the transaction
        And an item with barcode <item_barcode> is present in the transaction
        When the cashier updates quantity of the item <item_name> to <quantity>
        Then a card <card_name> with value of 0.00 is in the virtual receipt
        And a card <card_name> with value of 0.00 is in the current transaction
        And an item <item_name> with price <item_price> and quantity <quantity> is in the virtual receipt
        And an item <item_name> with price <item_price> and quantity <quantity> is in the current transaction

        Examples:
        | card_number      | card_name | item_barcode | item_name   | quantity | item_price |
        | 3104174102936582 | PES card  | 099999999990 | Sale Item A | 3        | 2.97       |


    @fast
    Scenario: Enable sending only loyalty transactions to PES, PES loyalty card is in the transaction,
              the transaction is captured on PES.
        # Promotion Execution Service Send only loyalty transactions is set to Yes
        Given the POS option 5279 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And a PES loyalty card 3104174102936582 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS displays main menu frame
        And the transaction is finalized
        And a card PES card with value of 0.00 is in the previous transaction
        And a loyalty transaction is received on PES


    @fast
    Scenario: Enable sending only loyalty transactions to PES, PES loyalty card is not in the transaction,
              no transaction is captured on PES.
        # Promotion Execution Service Send only loyalty transactions is set to Yes
        Given the POS option 5279 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS displays main menu frame
        And the transaction is finalized
        And a card PES card with value of 0.00 is not in the previous transaction
        And no transaction is received on PES


    @fast
    Scenario Outline: Add a postpay fuel with PES card and discount to a transaction
        Given the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the customer dispensed <grade> for 10.00 price at pump 2
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id             | unit_type        |
            | 004            | Premium Fuel         | 0.50           | item           | 50cents off premium fuel | GALLON_US_LIQUID |
        When the cashier adds a postpay from pump 2 to the transaction
        Then a fuel item <item> with price 10.00 and prefix P2 is in the virtual receipt
        And a loyalty discount <discount> with value of <discount_value> and quantity 1 is in the virtual receipt
        And a loyalty discount <discount> with value of <discount_value> is in the current transaction
        And the transaction's subtotal is <balance>
        And the transaction's balance is <balance>

        Examples:
            | grade   | item           | discount     | discount_value | balance |
            | Premium | 2.500G Premium | Premium Fuel | 1.25           | 8.75    |


    @fast
    Scenario Outline: Tender a postpay fuel with PES card and discount. Add first card, then fuel to the transaction.
        Given the POS is in a ready to sell state
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id             | unit_type        |
            | 004            | Premium Fuel         | 0.50           | item           | 50cents off premium fuel | GALLON_US_LIQUID |
        And a PES loyalty card 3104174102936582 is present in the transaction
        And a <grade> postpay fuel with 10.00 price on pump 2 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS displays main menu frame
        And no transaction is in progress
        And a card PES card with value of 0.00 is in the previous transaction
        And a loyalty discount <discount> with value of <discount_value> is in the previous transaction

        Examples:
            | grade   | item           | discount     | discount_value | balance |
            | Premium | 2.500G Premium | Premium Fuel | 1.25           | 8.75    |


    @fast
    Scenario Outline: Tender a postpay fuel with PES card and discount. Add first fuel, then card to the transaction.
        Given the POS is in a ready to sell state
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id             | unit_type        |
            | 004            | Premium Fuel         | 0.50           | item           | 50cents off premium fuel | GALLON_US_LIQUID |
        And a <grade> postpay fuel with 10.00 price on pump 2 is present in the transaction
        And a PES loyalty card 3104174102936582 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS displays main menu frame
        And no transaction is in progress
        And a card PES card with value of 0.00 is in the previous transaction
        And a loyalty discount <discount> with value of <discount_value> is in the previous transaction

        Examples:
            | grade   | item           | discount     | discount_value | balance |
            | Premium | 2.500G Premium | Premium Fuel | 1.25           | 8.75    |


    @fast
    Scenario Outline: Tender a transaction with prepaid fuel and PES card present, dispense fuel partially and refund the rest.
        # Set Prepay Grade Select Type option as One Touch
        Given the POS option 5124 is set to 1
        And the POS is in a ready to sell state
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id             | unit_type        |
            | 004            | Premium Fuel         | 0.50           | item           | 50cents off premium fuel | GALLON_US_LIQUID |
        And a PES loyalty card 3104174102936582 is present in the transaction
        And a <grade> prepay fuel with <prepaid> price on pump <pump_number> is present in the transaction
        And the transaction is tendered
        And the customer dispensed <grade> for <dispensed> price at pump <pump_number>
        When the cashier refunds the fuel from pump <pump_number>
        Then the POS displays main menu frame
        And no transaction is in progress

        Examples:
            | grade   | pump_number | prepaid | dispensed |
            | Premium | 1           | 20.00   | 10.00     |