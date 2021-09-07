@pos @pes
Feature: Promotion Execution Service - numeric prompts
    There are several types of confirmation prompts in PES:
    - freestanding prompt: uses prompts field in the request and is not tied to a discount
    - reward discounts: uses rewardApproval field in the request
    - prompt discounts: uses prompt_id field of a discount to retrieve a prompt from the prompts field in the request

    This feature file focuses on numeric confirmation prompts, typically used for PIN entries. Right now the numeric prompt
    is only available after a Yes/No freestanding prompt is accepted (hardcoded in nep simulator).

    Background: POS is configured for PES feature
        Given the POS has essential configuration
        And the POS is configured to communicate with PES
        # Cloud Loyalty Interface is set to PES
        And the POS option 5284 is set to 1
        And the nep-server has default configuration
        # Default Loyalty Discount Id is set to PES_basic
        And the POS parameter 120 is set to PES_basic
        And the POS has following discounts configured
            | reduction_id | description | price | external_id |
            | 1            | PES loyalty | 0.00  | PES_basic   |
        And the pricebook contains retail items
            | description | price | item_id | barcode | credit_category | category_code |
            | Large Fries | 2.19  | 111     | 001     | 2010            | 400           |
        And the POS recognizes following PES cards
            | card_definition_id | card_role  | card_name | barcode_range_from | barcode_range_to | card_definition_group_id | track_format_1 | track_format_2 | mask_mode |
            | 70000001142        | 3          | PES Card  | 1234567890         | 1234567900       | 70000010042              | bt%at?         | bt;at?         | 21        |


    @fast
    Scenario Outline: Numeric prompt (loyalty PIN entry) is displayed on the POS after freestanding discount prompt is accepted
        # Numeric prompt after freestanding discount prompt sequence is hardcoded in the nep sim for now, similar to Comarch host flow
        Given the nep-server has following cards configured
            | card_number   | prompt_message                 | prompt_type | notification_for      |
            | <card_number> | Apply this fantastic discount? | BOOLEAN     | <notification_target> |
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And PES discount approval frame is displayed after POS sends card <card_name> with number <card_number> to PES
        When the cashier selects yes button
        Then the POS displays enter loyalty PIN frame
        And the POS sends a GetPromotions request to PES with following elements
            | element                    | value |
            | prompts[0].booleanResponse | True  |

        Examples:
        | card_number | card_name | notification_target  |
        | 1234567890  | PES Card  | CASHIER_AND_CONSUMER |
        | 1234567891  | PES Card  | CASHIER              |


    @fast @manual
    Scenario Outline: Numeric prompt (loyalty PIN entry) is displayed on the pinpad after freestanding discount prompt is accepted,
                      POS displays the Wait for customer confirmation frame during both prompts
        # Yes/No input on pinpad will have to be discussed with DEV
        Given the nep-server has following cards configured
            | card_number   | prompt_message                 | prompt_type | notification_for      |
            | <card_number> | Apply this fantastic discount? | BOOLEAN     | CONSUMER              |
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And Wait for customer confirmation frame is displayed after POS sends card <card_name> with number <card_number> to PES
        When the customer selects yes button on the pinpad
        Then the POS displays Wait for customer confirmation frame

        Examples:
        | card_number | card_name |
        | 1234567892  | PES Card  |


    @fast
    Scenario Outline: Valid PIN is entered on the Numeric prompt on POS, Ask tender amount frame is displayed
        Given the nep-server has following cards configured
            | card_number   | prompt_message                 | prompt_type | notification_for      | min_pin_length | max_pin_length |
            | <card_number> | Apply this fantastic discount? | BOOLEAN     | <notification_target> | 2              | 8              |
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the POS displays enter loyalty PIN frame after manually entering card <card_name> with a number <card_number>
        When the cashier enters loyalty PIN <pin> on POS
        Then the POS displays Ask tender amount cash frame
        And the POS sends a GetPromotions request to PES with following elements
            | element                    | value    |
            | prompts[0].numericResponse | <pin>    |
            | prompts[0].promptId        | PIN_AUTH |

        Examples:
        | card_number | card_name | pin      | notification_target  |
        | 1234567893  | PES Card  | 12       | CASHIER              |
        | 1234567894  | PES Card  | 12345678 | CASHIER_AND_CONSUMER |


    @fast
    Scenario Outline: Valid PIN is entered on the Numeric prompt on pinpad, Ask tender amount frame is displayed
        Given the nep-server has following cards configured
            | card_number   | prompt_message                 | prompt_type | min_pin_length | max_pin_length |
            | <card_number> | Apply this fantastic discount? | BOOLEAN     | 2              | 8              |
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the POS displays enter loyalty PIN frame after manually entering card <card_name> with a number <card_number>
        When a customer enters loyalty PIN <pin> on pinpad
        Then the POS displays Ask tender amount cash frame
        And the POS sends a GetPromotions request to PES with following elements
            | element                    | value    |
            | prompts[0].numericResponse | <pin>    |
            | prompts[0].promptId        | PIN_AUTH |

        Examples:
        | card_number | card_name | pin      |
        | 1234567895  | PES Card  | 12       |
        | 1234567896  | PES Card  | 12345678 |

    @fast
    Scenario Outline: Numeric prompt cancelled on POS, Ask Tender amount frame is displayed, empty prompt is sent in the request
        Given the nep-server has following cards configured
            | card_number   | prompt_message                 | prompt_type | min_pin_length | max_pin_length |
            | <card_number> | Apply this fantastic discount? | BOOLEAN     | 2              | 8              |
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the POS displays enter loyalty PIN frame after manually entering card <card_name> with a number <card_number>
        When the cashier presses Go back button
        Then the POS displays Ask tender amount cash frame
        And the POS sends a GetPromotions request to PES with following elements
            | element                    | value    |
            | prompts[0].promptId        | PIN_AUTH |
        And the POS sends a GetPromotions request to PES without any of the following elements
            | element                    |
            | prompts[0].numericPrompt   |
            | prompts[0].booleanPrompt   |

        Examples:
        | card_number | card_name |
        | 1234567895  | PES Card  |

    @fast
    Scenario Outline: Numeric prompt cancelled on pinpad, Ask Tender amount frame is displayed, empty prompt is sent in the request
        Given the nep-server has following cards configured
            | card_number   | prompt_message                 | prompt_type | min_pin_length | max_pin_length |
            | <card_number> | Apply this fantastic discount? | BOOLEAN     | 2              | 8              |
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the POS displays enter loyalty PIN frame after manually entering card <card_name> with a number <card_number>
        When a customer cancels the numeric prompt on pinpad
        Then the POS displays Ask tender amount cash frame
        And the POS sends a GetPromotions request to PES with following elements
            | element                    | value    |
            | prompts[0].promptId        | PIN_AUTH |
        And the POS sends a GetPromotions request to PES without any of the following elements
            | element                    |
            | prompts[0].numericPrompt   |
            | prompts[0].booleanPrompt   |

        Examples:
        | card_number | card_name |
        | 1234567895  | PES Card  |

    @fast
    Scenario Outline: Invalid PIN is entered (short) on the Numeric prompt on POS, Too few characters error frame is displayed
        Given the nep-server has following cards configured
            | card_number   | prompt_message                 | prompt_type | min_pin_length | max_pin_length |
            | <card_number> | Apply this fantastic discount? | BOOLEAN     | 2              | 8              |
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the POS displays enter loyalty PIN frame after manually entering card <card_name> with a number <card_number>
        When the cashier enters loyalty PIN <pin> on POS
        Then enter loyalty PIN frame is closed
        And the POS displays Too few characters error
        And the POS sends no GetPromotion requests after last action

        Examples:
        | card_number | card_name | pin |
        | 1234567897  | PES Card  | 1   |


    @fast
    Scenario Outline: Invalid PIN is entered (long) on the Numeric prompt on POS, POS stops accepting more chars after max length is reached,
                      input is accepted and POS displays Ask tender amount frame
        Given the nep-server has following cards configured
            | card_number   | prompt_message                 | prompt_type | min_pin_length | max_pin_length |
            | <card_number> | Apply this fantastic discount? | BOOLEAN     | 2              | 8              |
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the POS displays enter loyalty PIN frame after manually entering card <card_name> with a number <card_number>
        When the cashier enters loyalty PIN <pin> on POS
        Then enter loyalty PIN frame is closed
        And the POS displays Ask tender amount cash frame
        And the POS sends a GetPromotions request to PES with following elements
            | element                    | value           |
            | prompts[0].numericResponse | <truncated_pin> |
            | prompts[0].promptId        | PIN_AUTH        |

        Examples:
        | card_number | card_name | pin                 | truncated_pin |
        | 1234567898  | PES Card  | 1234567890123456789 | 12345678      |


    @fast
    Scenario Outline: Numeric prompt is not displayed when previous freestanding discount prompt is rejected, ask tender amount frame is displayed
        Given the nep-server has following cards configured
            | card_number   | prompt_message                 | prompt_type |
            | <card_number> | Apply this fantastic discount? | BOOLEAN     |
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And PES discount approval frame is displayed after POS sends card <card_name> with number <card_number> to PES
        When the cashier selects no button
        Then the POS displays Ask tender amount cash frame
        And the POS sends a GetPromotions request to PES with following elements
            | element                    | value |
            | prompts[0].booleanResponse | False |

        Examples:
        | card_number | card_name |
        | 1234567900  | PES Card  |


    @fast
    Scenario Outline: No PIN is entered on the Numeric prompt and confirmed, the value 0 is sent to host,
                      Ask tender amount frame is displayed
        Given the nep-server has following cards configured
            | card_number   | prompt_message                 | prompt_type | min_pin_length | max_pin_length |
            | <card_number> | Apply this fantastic discount? | BOOLEAN     | 0              | 8              |
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the POS displays enter loyalty PIN frame after manually entering card <card_name> with a number <card_number>
        When the cashier presses Enter button
        Then the POS displays Ask tender amount cash frame
        And the POS sends a GetPromotions request to PES with following elements
            | element                    | value    |
            | prompts[0].numericResponse | 0        |
            | prompts[0].promptId        | PIN_AUTH |

        Examples:
        | card_number | card_name |
        | 1234567895  | PES Card  |
