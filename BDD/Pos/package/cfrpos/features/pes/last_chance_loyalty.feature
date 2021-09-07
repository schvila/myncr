@pos @pes
Feature: Promotion Execution Service - last chance loyalty prompt
    This feature file tests the last chance loyalty (POS option 4214) prompt with PES cards.

    Background: POS is configured for PES feature
        Given the POS has essential configuration
        And the EPS simulator has essential configuration
        And the pricebook contains retail items
            | description   | price | item_id | barcode | credit_category | category_code |
            | Large Fries   | 2.19  | 111     | 001     | 2010            | 400           |
        # Set Loyalty prompt control to Prompt always
        And the POS option 4214 is set to 1
        And the POS is configured to communicate with PES
        # Cloud Loyalty Interface is set to PES
        And the POS option 5284 is set to 1
        # Default Loyalty Discount Id is set to PES_basic
        And the POS parameter 120 is set to PES_basic
        # Promotion Execution Service Send only loyalty transactions is set to No
        And the POS option 5279 is set to 0
        # Promotion Execution Service Get Mode is set to PES Get After Item and Subtotal
        And the POS option 5277 is set to 0
        And the POS has following discounts configured
            | reduction_id | description | price | external_id |
            | 1            | PES loyalty | 0.00  | PES_basic   |
        And the nep-server has default configuration
        And the POS recognizes following PES cards
            | card_definition_id | card_role | card_name | barcode_range_from | card_definition_group_id | track_format_1 | track_format_2 | mask_mode |
            | 70000001142        | 3         | PES Card  | 3104174102936582   | 70000010042              | bt%at?         | bt;at?         | 21        |


    @fast
    Scenario: Cashier presses the cash tender button, no loyalty card is in the transaction, Last chance loyalty frame is displayed,
               the POS sends no GetPromotions request to PES.
        Given the POS is in a ready to sell state
        And the POS sends a GetPromotions request to PES after scanning an item with barcode 001
        When the cashier presses the cash tender button
        Then the POS sends no GetPromotions requests after last action
        And the POS displays Last chance loyalty frame


    @fast
    Scenario: Cashier presses Continue on Last chance loyalty frame, no loyalty card is added in the transaction, the Ask tender amount frame is displayed,
              the POS sends GetPromotions requests without loyalty identifier included.
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the POS displays Last chance loyalty frame after selecting a credit tender button
        When the cashier presses Continue button
        Then the POS sends a GetPromotions request to PES with following elements
            | element     | value |
            | totals      | True  |
            | consumerIds | None  |
        And the POS displays Ask tender amount credit frame


    @fast
    Scenario: Select tender button, PES card is in the transaction, Last chance loyalty frame is not displayed,
              the POS sends GetPromotions requests with loyalty identifier included.
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And a PES loyalty card 3104174102936582 is present in the transaction
        When the cashier presses the cash tender button
        Then the POS sends a GetPromotions request to PES with following elements
            | element                   | value            |
            | totals                    | True             |
            | consumerIds[0].identifier | 3104174102936582 |
            | consumerIds[0].type       | LOYALTY_ID       |
        And the POS displays Ask tender amount cash frame
        And a loyalty card Pes Card is added to the transaction


    @fast
    Scenario: Swipe a PES card on pinpad while POS displays Last chance loyalty prompt,
              the POS sends GetPromotions requests with loyalty identifier included.
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the POS displays Last chance loyalty frame after selecting a cash tender button
        When a customer swipes a PES loyalty card with number 3104174102936582 on pinpad
        Then the POS sends a GetPromotions request to PES with following elements
            | element                   | value            |
            | totals                    | True             |
            | consumerIds[0].identifier | 3104174102936582 |
            | consumerIds[0].type       | LOYALTY_ID       |
        And the POS displays Ask tender amount cash frame
        And a card Pes Card with value of 0.00 is in the current transaction


    @fast
    Scenario: Swipe a PES card on the POS while POS displays Last chance loyalty prompt,
              the POS sends GetPromotions requests with loyalty identifier included.
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the POS displays Last chance loyalty frame after selecting a cash tender button
        When the cashier swipes a PES loyalty card with number 3104174102936582 on the POS
        Then the POS sends a GetPromotions request to PES with following elements
            | element                   | value            |
            | totals                    | True             |
            | consumerIds[0].identifier | 3104174102936582 |
            | consumerIds[0].type       | LOYALTY_ID       |
        And the POS displays Ask tender amount cash frame
        And a card Pes Card with value of 0.00 is in the current transaction


    @fast
    Scenario: PES card is scanned on Last chance loyalty prompt and PES request contains loyalty identifier.
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the POS displays Last chance loyalty frame after selecting a cash tender button
        When the cashier scans PES loyalty card 3104174102936582
        Then the POS sends a GetPromotions request to PES with following elements
            | element                   | value            |
            | totals                    | True             |
            | consumerIds[0].identifier | 3104174102936582 |
            | consumerIds[0].type       | LOYALTY_ID       |
        And the POS displays Ask tender amount cash frame
        And a loyalty card Pes Card is added to the transaction


    @fast
    Scenario: Select a tender button second time, after pressing Continue on Last chance loyalty frame in first attempt,
              the Ask tender amount frame is displayed, the POS does not send additional GetPromotions request.
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the POS returns to main menu frame after selecting continue on Last chance loyalty frame
        When the cashier presses the credit tender button
        Then the POS sends no GetPromotion requests after last action
        And the POS displays Ask tender amount credit frame


    @fast
    Scenario: Add PES card to the transaction after the Last chance loyalty frame is closed. Select a tender button,
              the Last chance loyalty frame is not displayed again, the POS sends a GetPromotion request with loyalty identifier included.
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the POS returns to main menu frame after selecting continue on Last chance loyalty frame
        And a PES loyalty card 3104174102936582 is present in the transaction
        When the cashier presses the cash tender button
        Then the POS sends a GetPromotions request to PES with following elements
            | element                   | value            |
            | totals                    | True             |
            | consumerIds[0].identifier | 3104174102936582 |
            | consumerIds[0].type       | LOYALTY_ID       |
        And the POS displays Ask tender amount cash frame


    @fast
    Scenario: Sigma card is entered on Last chance loyalty prompt and PES request does not contain loyalty identifier.
        Given the Sigma simulator has essential configuration
        And the POS has the feature Loyalty enabled
        And the Sigma recognizes following cards
            | card_number       | card_description |
            | 12879784762398321 | Happy Card       |
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the POS displays Last chance loyalty frame after selecting a cash tender button
        When a customer adds a loyalty card with a number 12879784762398321 on the pinpad
        Then the POS sends a GetPromotions request to PES with following elements
            | element     | value        |
            | totals      | False        |
            | consumerIds | None         |
        And the POS displays Ask tender amount cash frame
        And a loyalty card Happy Card is added to the transaction


    @fast
    Scenario: Enable sending only loyalty transaction to PES. POS sends a GetPromotions request to PES when the PES card is entered on Last chance loyalty prompt.
        # Promotion Execution Service Send only loyalty transactions is set to Yes
        Given the POS option 5279 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the POS displays Last chance loyalty frame after selecting a cash tender button
        When a customer swipes a PES loyalty card with number 3104174102936582 on pinpad
        Then the POS sends a GetPromotions request to PES with following elements
            | element                   | value            |
            | totals                    | True             |
            | consumerIds[0].identifier | 3104174102936582 |
            | consumerIds[0].type       | LOYALTY_ID       |
        And the POS displays Ask tender amount cash frame
        And a loyalty card Pes Card is added to the transaction


    @fast
    Scenario: Enable sending only loyalty transaction to PES. POS does not send any request to PES when the PES card is not in the transaction.
        # Promotion Execution Service Send only loyalty transactions is set to Yes
        Given the POS option 5279 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the POS displays Last chance loyalty frame after selecting a credit tender button
        When the cashier presses Continue button
        Then no transaction is received on PES
        And the POS displays Ask tender amount credit frame


    @fast
    Scenario: Discounts are received after PES card is entered on Last chance loyalty prompt.
        Given the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | unit_type       |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | SIMPLE_QUANTITY |
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the POS displays Last chance loyalty frame after selecting a cash tender button
        When a customer swipes a PES loyalty card with number 3104174102936582 on pinpad
        Then the POS sends a GetPromotions request to PES with following elements
            | element                   | value            |
            | totals                    | True             |
            | consumerIds[0].identifier | 3104174102936582 |
            | consumerIds[0].type       | LOYALTY_ID       |
        And the POS displays Ask tender amount cash frame
        And a loyalty discount Miscellaneous with value of 0.30 is in the virtual receipt
        And a loyalty discount Miscellaneous with value of 0.30 is in the current transaction
        And a card PES Card with value of 0.00 is in the virtual receipt
        And a card PES Card with value of 0.00 is in the current transaction


    @fast
    Scenario: Swipe PES card on pinpad while POS displays Last chance loyalty prompt, the POS sends GetPromotions request to PES with
              loyalty identifier included and the discount confirmation prompt is displayed.
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        Given the POS option 5277 is set to 1
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | prompt_approval      | prompt_id |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | CASHIER_AND_CONSUMER | 1         |
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the POS displays Last chance loyalty frame after selecting a cash tender button
        When a customer swipes a PES loyalty card with number 3104174102936582 on pinpad
        Then the POS sends a GetPromotions request to PES with following elements
            | element                   | value            |
            | totals                    | True             |
            | consumerIds[0].identifier | 3104174102936582 |
            | consumerIds[0].type       | LOYALTY_ID       |
        And the POS displays a PES discount approval frame


    @fast
    Scenario: Configure POS to send Get requests to PES only after Subtotal. Add a PES card on Last chance loyalty prompt,
              the POS sends GetPromotions request to PES with loyalty identifier included, the discounts are applied after
              cashier confirmed it on confirmation prompt.
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        Given the POS option 5277 is set to 1
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | approval_for         |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | CASHIER_AND_CONSUMER |
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And a PES loyalty card with number 3104174102936582 is entered on Last chance loyalty prompt
        And the POS displays a PES discount approval frame
        When the cashier selects Yes button
        Then the POS sends a GetPromotions request to PES with following elements
            | element                   | value            |
            | totals                    | True             |
            | consumerIds[0].identifier | 3104174102936582 |
            | consumerIds[0].type       | LOYALTY_ID       |
        And the POS displays Ask tender amount cash frame
        And a card PES Card with value of 0.00 is in the virtual receipt
        And a loyalty discount Miscellaneous with value of 0.30 is in the virtual receipt
        And a loyalty discount Miscellaneous with value of 0.30 is in the current transaction


    @fast
    Scenario: Configure POS to send Get requests to PES only after Subtotal. Select Continue on Last chance loyalty prompt,
              POS sends GetPromotions request to PES without loyalty identifier included.
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        Given the POS option 5277 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the POS displays Last chance loyalty frame after selecting a credit tender button
        When the cashier presses Continue button
        Then the POS sends a GetPromotions request to PES with following elements
            | element     | value |
            | totals      | True  |
            | consumerIds | None  |
        And the POS displays Ask tender amount credit frame


    @fast
    Scenario: Configure POS to send Get requests to PES only after Subtotal. Add a PES loyalty card on Last chance loyalty prompt,
              POS sends GetPromotions request to PES with loyalty identifier included.
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        Given the POS option 5277 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the POS displays Last chance loyalty frame after selecting a credit tender button
        When a customer swipes a PES loyalty card with number 3104174102936582 on pinpad
        Then the POS sends a GetPromotions request to PES with following elements
            | element                   | value            |
            | totals                    | True             |
            | consumerIds[0].identifier | 3104174102936582 |
            | consumerIds[0].type       | LOYALTY_ID       |
        And the POS displays Ask tender amount credit frame
        And a loyalty card Pes Card is added to the transaction


    @fast
    Scenario: Configure POS to send GetPromotions requests to PES only after Subtotal. Add a Sigma loyalty card on Last chance loyalty prompt,
              POS sends GetPromotions request to PES without loyalty identifier included.
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        Given the POS option 5277 is set to 1
        And the Sigma simulator has essential configuration
        And the POS has the feature Loyalty enabled
        And the Sigma recognizes following cards
            | card_number       | card_description |
            | 12879784762398321 | Happy Card       |
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the POS displays Last chance loyalty frame after selecting a cash tender button
        When a customer adds a loyalty card with a number 12879784762398321 on the pinpad
        Then the POS sends a GetPromotions request to PES with following elements
            | element     | value |
            | totals      | True  |
            | consumerIds | None  |
        And the POS displays Ask tender amount cash frame
        And a loyalty card Happy Card is added to the transaction
