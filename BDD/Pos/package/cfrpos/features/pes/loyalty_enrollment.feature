@pos @pes @manual
Feature: Promotion Execution Service - loyalty enrollment
    The loyalty enrollment process consists of a single yes/no prompt, that should be displayed when an unknown alt ID is included in the transaction,
    asking whether the customer wants to register. It is a process driven by host, which can be enabled per site.
    If the customer answers yes, the printed receipt will include an extra line with instructions how to finish the enrollment.
    If the customer accepts the enrollment, the phone number is saved and the customer is not prompted in the future transactions for loyalty enrollment.
    If the customer declines the enrollment, the phone number is not saved and the customer will be promted in the future transactions for loyalty enrollment.

    Background: POS is configured for PES feature
        Given the POS has essential configuration
        And the POS is configured to communicate with PES
        # Cloud Loyalty Interface is set to PES
        And the POS option 5284 is set to 1
        And the nep-server has default configuration
        # Default Loyalty Discount Id is set to PES_basic
        And the POS parameter 120 is set to PES_basic
        And the POS has following sale items configured
            | barcode      | description | price  | external_id          |
            | 099999999990 | Sale item A | 0.99   | ITT-099999999990-0-1 |
        And the POS recognizes following PES cards
            | card_definition_id | card_role  | card_name     | barcode_range_from     | barcode_range_to       | card_definition_group_id | track_format_1 | track_format_2 | mask_mode |
            | 70000001142        | 3          | PES card      | 3104174102936582       | 3104174102936583       | 70000010042              | bt%at?         | bt;at?         | 21        |
            | 70000001144        | 3          | PES card 2    | 3104174102936584       | 3104174102936585       | 70000010044              | bt%at?         | bt;at?         | 21        |
        And the POS has following loyalty programs configured
            | external_id  | program_name | card_definition_id | card_name | barcode_range_from | card_definition_group_id |
            | EXT Alt id 1 | PES Alt id 1 | 70000001142        | PES card  | 3104174102936582   | 70000010042              |
            | EXT Alt id 2 | PES Alt id 2 | 70000001142        | PES card  | 3104174102936558   | 70000010043              |
        And the nep-server has following customers configured
            | card_number       | customer_name | phone_number | pin  |
            | 3104174102936582  | John Doe      | 19991234526  | 1234 |
        And a loyalty_footer section LoyaltyFooter includes
            | line                                                                | variable                       |
            | <span class="width-40 left">{$P_LOYALTY_RECEIPT_FOOTER_LINE}</span> | $P_LOYALTY_RECEIPT_FOOTER_LINE |
        And the following receipts are available
            | receipt    | section       |
            | PesReceipt | LoyaltyFooter |
        And the POS has a receipt PesReceipt set as active
        And the nep-server is configured for loyalty enrollment
        And the nep-server has following receipt message configured for loyalty enrollment request
            | content                                        | type | location | alignment | formats                | line_break    |
            | Go to our web page and finish enrollment there | TEXT | BACK     | CENTER    | BOLD, DOUBLE_WIDE      | NO_LINE_BREAK |


    @fast @positive
    Scenario Outline: A customer uses an unregistered phone number as alternate ID, loyalty host prompts for enrollment.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        And the customer selected a loyalty program with name PES Alt id 1 from the picklist and entered valid Alt ID 123456789
        When the cashier totals the transaction using cash tender
        Then the POS displays Waiting for customer input frame
        And the pinpad displays Loyalty enrollment prompt
        And an item Alternate ID with price 0.0 and type 26 is in the current transaction
        And an item Alternate ID with price 0.0 is in the virtual receipt


    @fast @negative
    Scenario Outline: A customer uses a registered phone number as alternate ID, loyalty host does not prompt for enrollment.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        And the customer selected a loyalty program with name PES Alt id 1 from the picklist and entered valid Alt ID 19991234526
        When the cashier totals the transaction using cash tender
        Then the POS displays Cash tender frame
        And the pinpad displays main frame
        And an item Alternate ID with price 0.0 and type 26 is in the current transaction
        And an item Alternate ID with price 0.0 is in the virtual receipt


    @fast @negative
    Scenario Outline: A loyalty host is offline, loyalty host does not prompt for enrollment.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        And the customer selected a loyalty program with name PES Alt id 1 from the picklist and entered valid Alt ID 19991234526
        When the cashier totals the transaction using cash tender
        Then the POS displays Cash tender frame
        And the pinpad displays main frame
        And an item Alternate ID with price 0.0 and type 26 is in the current transaction
        And an item Alternate ID with price 0.0 is in the virtual receipt


    @fast @positive
    Scenario Outline: A customer presses Yes for loyalty enrollment, POS sends GetPromotions with response as accepted.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        And the customer selected a loyalty program with name PES Alt id 1 from the picklist and entered valid Alt ID 123456789
        And the cashier pressed the Cash tender button
        And the POS displays Waiting for customer input frame
        When the customer presses Yes button on pinpad for loyalty enrollment
        Then the POS displays Cash tender frame
        And an item Alternate ID with price 0.0 and type 26 is in the current transaction
        And an item Alternate ID with price 0.0 is in the virtual receipt
        And the POS sends a GetPromotions request to PES with following elements
            | element                    | value   |
            | prompts[0].booleanResponse | true    |
            | prompts[0].promptId        | SMS_ENR |


    @fast @negative
    Scenario Outline: A customer presses No for loyalty enrollment, POS sends GetPromotions with response as declined.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        And the customer selected a loyalty program with name PES Alt id 1 from the picklist and entered valid Alt ID 123456789
        And the cashier pressed the Cash tender button
        And the POS displays Waiting for customer input frame
        When the customer presses No button on pinpad for loyalty enrollment
        Then the POS displays Cash tender frame
        And an item Alternate ID with price 0.0 and type 26 is in the current transaction
        And an item Alternate ID with price 0.0 is in the virtual receipt
        And the POS sends a GetPromotions request to PES with following elements
            | element                    | value   |
            | prompts[0].booleanResponse | false   |
            | prompts[0].promptId        | SMS_ENR |


    @fast @negative
    Scenario Outline: A customer presses Go Back on frame loyalty enrollment, POS sends GetPromotions with response as declined.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        And the customer selected a loyalty program with name PES Alt id 1 from the picklist and entered valid Alt ID 123456789
        And the cashier pressed the Cash tender button
        And the POS displays Waiting for customer input frame
        When the customer presses Go Back button on pinpad for loyalty enrollment
        Then the POS displays Cash tender frame
        And an item Alternate ID with price 0.0 and type 26 is in the current transaction
        And an item Alternate ID with price 0.0 is in the virtual receipt
        And the POS sends a GetPromotions request to PES with following elements
            | element                    | value   |
            | prompts[0].booleanResponse | false   |
            | prompts[0].promptId        | SMS_ENR |


    @fast @negative
    Scenario Outline: The loyalty enrollment times out, POS sends GetPromotions with response as declined.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        And the customer selected a loyalty program with name PES Alt id 1 from the picklist and entered valid Alt ID 123456789
        And the cashier pressed the Cash tender button
        And the POS displays Waiting for customer input frame
        When the loyalty enrollment frame on pinpad times out
        Then the POS displays Cash tender frame
        And an item Alternate ID with price 0.0 and type 26 is in the current transaction
        And an item Alternate ID with price 0.0 is in the virtual receipt
        And the POS sends a GetPromotions request to PES with following elements
            | element                    | value   |
            | prompts[0].booleanResponse | false   |
            | prompts[0].promptId        | SMS_ENR |


    @fast @positive
    Scenario Outline: A customer presses yes for enrollment after added unregistered phone number as alternative ID,
                    the instructions for enrollment are printed on the receipt.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        And the customer selected a loyalty program with name PES Alt id 1 from the picklist and entered valid Alt ID 123456789
        And the cashier pressed the Cash tender button
        And the POS displays Waiting for customer input frame
        And the customer pressed Yes button on pinpad for loyalty enrollment
        And the transaction is finalized
        When the cashier presses print receipt button
        Then the receipt contains following lines
            | line                                                                                         |
            | <span class="center bold double-width">Go to our web page and finish enrollment there</span> |


    @fast @negative
    Scenario Outline: A customer presses no for enrollment after added unregistered phone number as alternative ID,
                    the instructions for enrollment are not printed on the receipt.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        And the customer selected a loyalty program with name PES Alt id 1 from the picklist and entered valid Alt ID 123456789
        And the cashier pressed the Cash tender button
        And the POS displays Waiting for customer input frame
        And the customer pressed No button on pinpad for loyalty enrollment
        And the transaction is finalized
        When the cashier presses print receipt button
        Then the receipt does not contain following lines
            | line                                                                                         |
            | <span class="center bold double-width">Go to our web page and finish enrollment there</span> |

