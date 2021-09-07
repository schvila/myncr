@pos @pes
Feature: PES Alt ID
    This feature file focuses on the Alternate ID functionality in combination with PES loyalty subsystem.

    Background: POS is properly configured for Alternate ID picklist and PES
        Given the POS has essential configuration
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        And the POS option 5277 is set to 1
        # Default Loyalty Discount Id is set to PES_basic
        And the POS parameter 120 is set to PES_basic
        # Promotion Execution Service Allow partial discounts is set to Yes
        And the POS option 5278 is set to 1
        And the POS has following sale items configured
            | barcode      | description | price | external_id          |
            | 099999999990 | Sale item A | 0.99  | ITT-099999999990-0-1 |
        # Add configured 'PES_tender' loyalty tender record
        And the pricebook contains PES loyalty tender
        And the POSCache simulator has default configuration
        And the POS has following discounts configured
            | reduction_id | description | price | external_id |
            | 1            | PES loyalty | 0.00  | PES_basic   |
        And the POS recognizes following PES cards
            | card_definition_id | card_role | card_name | barcode_range_from | card_definition_group_id | track_format_1 | track_format_2 | mask_mode |
            | 70000001142        | 3         | PES card  | 3104174102936582   | 70000010042              | bt%at?         | bt;at?         | 21        |
            | 70000001142        | 3         | PES card  | 3104174102936558   | 70000010043              | bt%at?         | bt;at?         | 21        |
        And the POS has following loyalty programs configured
            | external_id  | program_name | card_definition_id | card_name | barcode_range_from | card_definition_group_id |
            | EXT Alt id 1 | PES Alt id 1 | 70000001142        | PES card  | 3104174102936582   | 70000010042              |
            | EXT Alt id 2 | PES Alt id 2 | 70000001142        | PES card  | 3104174102936558   | 70000010043              |
        And the POS is configured to communicate with PES
        # Cloud Loyalty Interface is set to PES
        And the POS option 5284 is set to 1
        And the nep-server has default configuration
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id     | unit_type       | is_apply_as_tender |
            | 400            | Loyalty tender       | 10.00          | transaction    | 10.00 off tender | SIMPLE_QUANTITY | True               |
        And the Sigma simulator has essential configuration
        And the Sigma recognizes following cards
            | card_description | card_number      | track1                       | track2                       |
            | Kroger Loyalty   | 6042400114771120 | 6042400114771120^CARD/S^0000 | 6042400114771120=0000?S^0000 |
        And the nep-server has following cards configured
            | card_number   | prompt_message                    | prompt_type | notification_for |
            | 123456789     | Do you wanna apply this discount? | NUMERIC     | CONSUMER         |


    @fast
    Scenario: Customer presses Alt ID button on the pinpad while transaction is in progress, pinpad displays a list of available loyalty programs.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When a customer presses the Alt ID button
        Then the pinpad displays following list of available loyalty programs
            | program_description |
            | PES Alt id 1        |
            | PES Alt id 2        |
            | Awesome BDD Sigma   |
            | Regular BDD Sigma   |


    @fast
    Scenario: Customer selects loyalty program from the pick list, pinpad displays frame to enter the alt ID.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        When a customer selected loyalty program with name PES Alt id 1 from the picklist
        Then the pinpad displays Enter alt ID frame


    @fast
    Scenario: Customer adds alt ID on pinpad, the alt ID item is added into the transaction.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        And the customer selected a loyalty program with name PES Alt id 1 from the picklist
        When the customer enters a valid Alt ID 123456789 on the pinpad
        Then an item Alternate ID with price 0.0 and type 26 is in the current transaction
        And an item Alternate ID with price 0.0 is in the virtual receipt


    @fast
    Scenario: Customer adds alt ID on pinpad, the cash tender button is selected, pinpad displays frame to enter the alt ID.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        And the customer selected a loyalty program with name PES Alt id 1 from the picklist and entered valid Alt ID 123456789
        When the cashier presses the cash tender button
        Then the pinpad displays Enter loyalty pin frame


    @fast
    Scenario: Customer enters Alt ID on Last chance loyalty prompt, Alt ID item and PES discount are added into the transaction.
        # Set Loyalty prompt control to Prompt always
        Given the POS option 4214 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the POS displays Last chance loyalty frame after selecting a cash tender button
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        And the customer selected a loyalty program with name PES Alt id 1 from the picklist and entered valid Alt ID 123456789
        When the customer enters a valid PIN 1234 on the pinpad
        Then the POS sends DECODECOMPLETE request
        And the POS displays Ask tender amount cash frame
        And an item Alternate ID with price 0.0 and type 26 is in the current transaction
        And an item Alternate ID with price 0.0 is in the virtual receipt
        And a tender Loyalty tender with amount 1.06 is in the current transaction
        And a tender Loyalty tender with amount 1.06 is in the virtual receipt


    @fast
    Scenario: Enable Last chance loyalty, Alt ID item is added into the transaction, the tender button is selected,
             the Last chance loyalty prompt is not displayed, customer adds loyalty pin on pinpad,
             PES discount is added into the transaction.
        # Set Loyalty prompt control to Prompt always
        Given the POS option 4214 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        And the customer selected a loyalty program with name PES Alt id 1 from the picklist and entered valid Alt ID 123456789
        And the POS displays a Wait for customer confirmation frame after selecting a cash tender button
        When the customer enters a valid PIN 1234 on the pinpad
        Then the POS sends DECODECOMPLETE request
        And an item Alternate ID with price 0.0 and type 26 is in the current transaction
        And an item Alternate ID with price 0.0 is in the virtual receipt
        And a tender Loyalty tender with amount 1.06 is in the current transaction
        And a tender Loyalty tender with amount 1.06 is in the virtual receipt


    @fast @negative @manual
    Scenario: The POS cancels alt ID flow after no loyalty program is selected within timeout.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        When the POS is inactive for 11 seconds
        Then the POS sends CANCEL request


    @fast
    Scenario Outline: Cashier scans a loyalty card while pinpad displays picklist frame,
                    the pinpad flow is canceled and the card is added to the transaction
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        When the cashier scans <loyalty> loyalty card <card_number>
        Then the POS sends CANCEL request
        And a card <card_description> with value of 0.00 is in the virtual receipt
        And a card <card_description> with value of 0.00 is in the current transaction

        Examples:
        | loyalty | card_number      | card_description |
        | PES     | 3104174102936558 | PES card         |
        | Sigma   | 6042400114771120 | Loyalty Item     |


    @fast
    Scenario Outline: Cashier swipes a loyalty card on POS while pinpad displays picklist frame,
                    the pinpad flow is canceled and the card is added to the transaction
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        When the cashier swipes a <step_to_use> on the POS
        Then the POS sends CANCEL request
        And a card <card_description> with value of 0.00 is in the virtual receipt
        And a card <card_description> with value of 0.00 is in the current transaction

        Examples:
        | step_to_use                                | card             | card_description |
        | PES loyalty card with number <card>        | 3104174102936558 | PES card         |
        | Sigma loyalty card <card>                  | Kroger Loyalty   | Loyalty Item     |


    @fast
    Scenario Outline: Cashier manually adds a loyalty card on POS while pinpad displays picklist frame,
                    the pinpad flow is canceled and the card is added to the transaction
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        When the cashier manually adds a <loyalty> loyalty card with number <card_number> on the POS
        Then the POS sends CANCEL request
        And a card <card_description> with value of 0.00 is in the virtual receipt
        And a card <card_description> with value of 0.00 is in the current transaction

        Examples:
        | loyalty | card_number      | card_description |
        | PES     | 3104174102936558 | PES card         |
        | Sigma   | 6042400114771120 | Loyalty Item     |


    @fast
    Scenario Outline: Cashier scans a loyalty card while pinpad displays get alt id frame,
                    the pinpad flow is canceled and the card is added to the transaction
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        And the customer selected a loyalty program with name PES Alt id 1 from the picklist
        When the cashier scans <loyalty> loyalty card <card_number>
        Then the POS sends CANCEL request
        And a card <card_description> with value of 0.00 is in the virtual receipt
        And a card <card_description> with value of 0.00 is in the current transaction

        Examples:
        | loyalty | card_number      | card_description |
        | PES     | 3104174102936558 | PES card         |
        | Sigma   | 6042400114771120 | Loyalty Item     |


    @fast
    Scenario Outline: Cashier swipes a loyalty card on POS while pinpad displays get alt id frame,
                    the pinpad flow is canceled and the card is added to the transaction
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        And the customer selected a loyalty program with name PES Alt id 1 from the picklist
        When the cashier swipes a <step_to_use> on the POS
        Then the POS sends CANCEL request
        And a card <card_description> with value of 0.00 is in the virtual receipt
        And a card <card_description> with value of 0.00 is in the current transaction

        Examples:
        | step_to_use                                | card             | card_description |
        | PES loyalty card with number <card>        | 3104174102936558 | PES card         |
        | Sigma loyalty card <card>                  | Kroger Loyalty   | Loyalty Item     |


    @fast
    Scenario Outline: Cashier manually adds a loyalty card on POS while pinpad displays get alt id frame,
                    the pinpad flow is canceled and the card is added to the transaction
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        And the customer selected a loyalty program with name PES Alt id 1 from the picklist
        When the cashier manually adds a <loyalty> loyalty card with number <card_number> on the POS
        Then the POS sends CANCEL request
        And a card <card_description> with value of 0.00 is in the virtual receipt
        And a card <card_description> with value of 0.00 is in the current transaction

        Examples:
        | loyalty | card_number      | card_description |
        | PES     | 3104174102936558 | PES card         |
        | Sigma   | 6042400114771120 | Loyalty Item     |


    @manual
    # Will be updated after EPSP-21204 is solved.
    Scenario: Customer selects go back on pinpad, while the pinpad displays a list of available loyalty programs,
              the alt id flow is being canceled, and Alt ID item is not in the transaction.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        When the customer selects Go back on pinpad
        #Then the POS sends CANCEL request
        Then an item Alternate ID with price 0.0 and type 26 is not in the current transaction
        And an item Alternate ID with price 0.0 is not in the virtual receipt


    @manual
    # Will be updated after EPSP-21204 is solved.
    Scenario: Customer selects go back on pinpad, while the pinpad displays a frame to enter alt ID,
              the alt id flow is being canceled, and Alt ID item is not in the transaction.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays Enter alt ID frame after the customer chose PES Alt id 1 loyalty program
        When the customer selects Go back on pinpad
        #Then the POS sends CANCEL request
        Then an item Alternate ID with price 0.0 and type 26 is not in the current transaction
        And an item Alternate ID with price 0.0 is not in the virtual receipt


    @manual
    # Will be updated after EPSP-21204 is solved.
    Scenario: Customer selects go back on pinpad, while the pinpad displays frame to enter loyalty pin and the Alt ID item is in the transaction,
              the alt id flow is being canceled and PES discount is not added into the transaction.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        And the customer selected a loyalty program with name PES Alt id 1 from the picklist and entered valid Alt ID 123456789
        And the pinpad displays Enter loyalty pin frame after cashier selected cash tender button
        When the customer selects Go back on pinpad
        #Then the POS sends CANCEL request
        Then an item Alternate ID with price 0.0 and type 26 is in the current transaction
        And an item Alternate ID with price 0.0 is in the virtual receipt
        And a tender Loyalty tender with amount 1.06 is not in the current transaction
        And a tender Loyalty tender with amount 1.06 is not in the virtual receipt


    @fast @positive @manual
    Scenario: Customer selects Sigma loyalty program, the POS is displaying enter alt id frame and pinpad returns to its main frame
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        When a customer selected loyalty program with name RLM from the picklist
        Then the POS displays Enter alt id frame
        And the pinpad displays main frame


    @fast @positive @manual
    Scenario: Customer selects Sigma loyalty program and cashier enters a valid alt ID, the alt id is added to the transaction
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        And the customer selected a loyalty program with name RLM from the picklist
        When the cashier enters Alt ID 1234567890
        Then an item Alternate ID with price 0.0 and type 26 is in the current transaction
        And an item Alternate ID with price 0.0 is in the virtual receipt
        And the POS sends no GetPromotions requests after last action


    @fast @positive @manual
    Scenario: Customer selects Sigma loyalty program, cashier enters a valid alt ID and totals the transaction, no request is sent to PES after transaction total
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        And the customer selected a loyalty program with name RLM from the picklist
        And the cashier entered Alt ID 1234567890
        When the cashier totals the transaction using cash tender
        Then a card Loyalty Item with value of 0.00 is in the virtual receipt
        And a card Loyalty Item with value of 0.00 is in the current transaction
        And the POS sends no GetPromotions requests after last action


    @fast @negative @manual
    Scenario: Customer selects Sigma loyalty program and cashier enters invalid alt ID, no request is sent to PES after transaction total
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        And the customer selected a loyalty program with name RLM from the picklist
        When the cashier enters Alt ID 111111111
        Then the pinpad displays Card failed frame
        Then the POS displays Loyalty error frame



    @fast
    Scenario: The POS has only one loyalty program configured. Alternate ID item is added into the transaction
              after only providing the Alternate ID, without displaying a list of available loyalty programs.
        Given the POS has following loyalty programs configured
            | external_id  | program_name    | card_definition_id | card_name | barcode_range_from | card_definition_group_id |
            | EXT Alt id 1 | PES Alt id Test | 70000001142        | PES card  | 3104174102936582   | 70000010042              |
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And a customer presses the Alt ID button
        And the POS sends GETMANUAL request
        When the customer enters a valid Alt ID 123456789 on the pinpad
        Then an item Alternate ID with price 0.0 and type 26 is in the current transaction
        And an item Alternate ID with price 0.0 is in the virtual receipt
