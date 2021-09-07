@pos @pes
Feature: Promotion Execution Service - confirmation prompt timeout
    Confirmation prompts for PES are driven by the POS option 5282 (PES Loyalty Prompt Timeout). The default value is 30 seconds.
    It can be overridden by the PES GetPromotion response notification prompt timeoutData.
    Reminder: Some types of prompts are not expected to send GET request with the prompt answer back to PES host.

    Background: POS is configured for PES feature
        Given the POS has essential configuration
        And the POS is configured to communicate with PES
        # Cloud Loyalty Interface is set to PES
        And the POS option 5284 is set to 1
        # Default Loyalty Discount Id is set to PES_basic
        And the POS parameter 120 is set to PES_basic
        # PES Loyalty prompt timeout option is set to 8 seconds
        And the POS option 5282 is set to 8
        And the POS has following discounts configured
            | reduction_id | description | price | external_id |
            | 1            | PES loyalty | 0.00  | PES_basic   |
        And the pricebook contains retail items
            | description | price | item_id | barcode | credit_category | category_code |
            | Large Fries | 2.19  | 111     | 001     | 2010            | 400           |
        And the nep-server has default configuration
        And the POS recognizes following PES cards
            | card_definition_id | card_role | card_name | barcode_range_from | card_definition_group_id | track_format_1 | track_format_2 | mask_mode |
            | 70000001142        | 3         | PES card  | 1234444321         | 70000010042              | bt%at?         | bt;at?         | 21        |


    @slow
    Scenario Outline: The POS displays discount confirmation prompt, host-supplied timeout value takes priority over POS option,
                      the main frame is displayed after timeout is reached
        Given the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | prompt_approval | prompt_id | timeout   |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | <target>        | 1         | <timeout> |
        And the POS is in a ready to sell state
        And the POS displays a PES discount approval frame after scanning a barcode 001
        When the POS is inactive for <sleep> seconds
        Then the POS displays main menu frame
        And the POS sends no GetPromotions requests after last action

        Examples:
            | target               | timeout | sleep |
            | CASHIER_AND_CONSUMER | 2       | 5     |
            | CASHIER              | 3       | 5     |
            # 0 means the host does not send the timeout field at all, fallback to pos option
            | CASHIER_AND_CONSUMER | 0       | 10    |
            | CASHIER              | 0       | 10    |


    @slow
    Scenario Outline: The pinpad displays discount confirmation prompt, POS displays a Wait for customer confirmation frame,
                      host-supplied timeout value takes priority over POS option, the main frame is displayed after timeout is reached
        Given the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | prompt_approval | prompt_id | timeout   |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | <target>        | 1         | <timeout> |
        And the POS is in a ready to sell state
        And the POS displays a Wait for customer confirmation frame after scanning a barcode 001
        When the POS is inactive for <sleep> seconds
        Then the POS displays main menu frame
        And the POS sends no GetPromotions requests after last action

        Examples:
            | target   | timeout | sleep |
            | CONSUMER | 3       | 5     |
            # 0 means the host does not send the timeout field at all, fallback to pos option
            | CONSUMER | 0       | 10    |


    @slow
    Scenario Outline: The POS displays freestanding prompt after subtotal, host-supplied timeout value takes priority
                      over POS option, the Ask amount frame is displayed after timeout is reached, host is notified
        Given the nep-server has following cards configured
            | card_number | prompt_message               | prompt_type | notification_for | timeout   |
            | 1234444321  | I'm just waiting for timeout | BOOLEAN     | <target>         | <timeout> |
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And a manually added card PES card with number 1234444321 is present in the transaction
        And the POS displays a PES discount approval frame after selecting a cash tender button
        When the POS is inactive for <sleep> seconds
        Then the POS displays Ask tender amount cash frame
        And the POS sends a GetPromotions request to PES with following elements
            | element_name               | value |
            | prompts[0].booleanResponse | False |

        Examples:
            | target               | timeout | sleep |
            | CASHIER_AND_CONSUMER | 2       | 5     |
            | CASHIER              | 3       | 5     |
            # 0 means the host does not send the timeout field at all, fallback to pos option
            | CASHIER_AND_CONSUMER | 0       | 10    |
            | CASHIER              | 0       | 10    |


    @slow
    Scenario Outline: The pinpad displays freestanding prompt after subtotal, POS displays a Wait for customer confirmation frame,
                      host-supplied timeout value takes priority over POS option, the Ask amount frame is displayed after
                      timeout is reached, host is notified
        Given the nep-server has following cards configured
            | card_number | prompt_message               | prompt_type | notification_for | timeout   |
            | 1234444321  | I'm just waiting for timeout | BOOLEAN     | <target>         | <timeout> |
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And a manually added card PES card with number 1234444321 is present in the transaction
        And the POS displays a Wait for customer confirmation frame after selecting a cash tender button
        When the POS is inactive for <sleep> seconds
        Then the POS displays Ask tender amount cash frame
        And the POS sends a GetPromotions request to PES with following elements
            | element_name               | value |
            | prompts[0].booleanResponse | False |

        Examples:
            | target   | timeout | sleep |
            | CONSUMER | 3       | 5     |
            # 0 means the host does not send the timeout field at all, fallback to pos option
            | CONSUMER | 0       | 10    |


    @slow
    Scenario Outline: The POS displays Numeric prompt (loyalty PIN entry) after subtotal, host-supplied timeout value takes
                      priority over POS option, the Ask amount frame is displayed after timeout is reached, host is notified
        Given the nep-server has following cards configured
            | card_number | prompt_message                 | prompt_type | notification_for | timeout   |
            | 1234444321  | Apply this fantastic discount? | BOOLEAN     | <target>         | <timeout> |
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the POS displays enter loyalty PIN frame after manually entering card PES card with a number 1234444321
        When the POS is inactive for <sleep> seconds
        Then the POS displays Ask tender amount cash frame
        And the POS sends a GetPromotions request to PES with following elements
            | element_name               | value |
            | prompts[0].numericResponse | 0     |

        Examples:
            | target               | timeout | sleep |
            | CASHIER_AND_CONSUMER | 2       | 5     |
            | CASHIER              | 3       | 5     |
            # 0 means the host does not send the timeout field at all, fallback to pos option
            | CASHIER_AND_CONSUMER | 0       | 10    |
            | CASHIER              | 0       | 10    |


    @slow @manual
    Scenario Outline: The pinpad displays Numeric prompt (loyalty PIN entry) after subtotal, host-supplied timeout value takes
                      priority over POS option, the Ask amount frame is displayed after timeout is reached, host is notified
        # Yes/No input on pinpad will have to be discussed with DEV
        Given the nep-server has following cards configured
            | card_number | prompt_message                 | prompt_type | notification_for | timeout   |
            | 1234444321  | Apply this fantastic discount? | BOOLEAN     | <target>         | <timeout> |
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the POS displays Wait for customer confirmation frame after manually entering card PES card with a number 1234444321
        When the POS is inactive for <sleep> seconds
        Then the POS displays Ask tender amount cash frame
        And the POS sends a GetPromotions request to PES with following elements
            | element_name               | value |
            | prompts[0].numericResponse | 0     |

        Examples:
            | target   | timeout | sleep |
            | CONSUMER | 3       | 5     |
            # 0 means the host does not send the timeout field at all, fallback to pos option
            | CONSUMER | 0       | 10    |
