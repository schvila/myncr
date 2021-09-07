@pos @pes
Feature: Promotion Execution Service - boolean confirmation prompts
    There are several types of confirmation prompts in PES:
    - freestanding prompt: uses prompts field in the request and is not tied to a discount
    - reward discounts: uses rewardApproval field in the request
    - prompt discounts: uses prompt_id field of a discount to retrieve a prompt from the prompts field in the request

    This feature file focuses on boolean Yes/No confirmation prompts.
    Freestanding prompts are intended as a replacement for prompt discounts, but we're keeping the functionality for the time being
    Reward discounts will be used by the PES server in the future, prompt discounts are used now and should become obsolete
    For prompt discounts, prompt_id has to be set, otherwise it won't work

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


    @fast
    Scenario Outline: The POS (and pinpad) displays reward discount confirmation prompt with custom title and text if configured,
                      otherwise a default one is used.
        Given the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | approval_for         | approval_name | approval_description |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | CASHIER_AND_CONSUMER | <custom_title>| <custom_text>        |
        And the POS is in a ready to sell state
        When the cashier scans a barcode 001
        Then the POS displays a PES discount approval frame with title <displayed_title> and description <displayed_text>
        And a loyalty discount Miscellaneous with value of 0.30 is not in the virtual receipt
        And a loyalty discount Miscellaneous with value of 0.30 is not in the current transaction

        Examples:
        | custom_title | displayed_title | custom_text                         | displayed_text                      |
        | Best Reward  | Best Reward     | Do you want to get the best reward? | Do you want to get the best reward? |
        |              | Apply Discount  |                                     | Do you want to apply the discount?  |


    @fast
    Scenario Outline: The POS (not pinpad) displays reward discount confirmation prompt with custom title and text if configured,
                      otherwise a default one is used.
        Given the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | approval_for | approval_name | approval_description |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | CASHIER      | <custom_title>| <custom_text>        |
        And the POS is in a ready to sell state
        When the cashier scans a barcode 001
        Then the POS displays a PES discount approval frame with title <displayed_title> and description <displayed_text>
        And a loyalty discount Miscellaneous with value of 0.30 is not in the virtual receipt
        And a loyalty discount Miscellaneous with value of 0.30 is not in the current transaction

        Examples:
        | custom_title | displayed_title | custom_text                         | displayed_text                      |
        | Best Reward  | Best Reward     | Do you want to get the best reward? | Do you want to get the best reward? |
        |              | Apply Discount  |                                     | Do you want to apply the discount?  |


    @fast
    Scenario Outline: The POS displays Please wait for customer confirmation frame while the pinpad displays the reward discount confirmation prompt.
        Given the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | approval_for | approval_name | approval_description |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | CONSUMER     | <custom_title>| <custom_text>        |
        And the POS is in a ready to sell state
        When the cashier scans a barcode 001
        Then the POS displays Wait for customer confirmation frame
        And a loyalty discount Miscellaneous with value of 0.30 is not in the virtual receipt
        And a loyalty discount Miscellaneous with value of 0.30 is not in the current transaction

        Examples:
        | custom_title | displayed_title | custom_text                         | displayed_text                      |
        | Best Reward  | Best Reward     | Do you want to get the best reward? | Do you want to get the best reward? |
        |              | Apply Discount  |                                     | Do you want to apply the discount?  |


    @fast
    Scenario Outline: The discount is added to the transaction after accepting it in reward discount confirmation prompt.
        Given the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | approval_for   | approval_name | approval_description                |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | <confirmed_by> | Best Reward   | Do you want to get the best reward? |
        And the POS is in a ready to sell state
        And the POS displays a PES discount approval frame after scanning a barcode 001
        When the cashier selects Yes button
        Then the POS displays main menu frame
        And a loyalty discount Miscellaneous with value of 0.30 is in the virtual receipt
        And a loyalty discount Miscellaneous with value of 0.30 is in the current transaction
        And the POS sends a GetPromotions request to PES with following elements
            | element                         | value                   |
            | rewardApprovals[0].approvalFlag | APPROVE                 |
            | rewardApprovals[0].promotionId  | 30cents off merchandise |

        Examples:
        | confirmed_by         |
        | CASHIER_AND_CONSUMER |
        | CASHIER              |


    @fast
    Scenario Outline: The discount is not added to the transaction after declining it in reward discount confirmation prompt.
        Given the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | approval_for   | approval_name | approval_description                |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | <confirmed_by> | Best Reward   | Do you want to get the best reward? |
        And the POS is in a ready to sell state
        And the POS displays a PES discount approval frame after scanning a barcode 001
        When the cashier selects No button
        Then the POS displays main menu frame
        And a loyalty discount Miscellaneous with value of 0.30 is not in the virtual receipt
        And a loyalty discount Miscellaneous with value of 0.30 is not in the current transaction
        And the POS sends a GetPromotions request to PES with following elements
            | element                         | value                   |
            | rewardApprovals[0].approvalFlag | REJECT                  |
            | rewardApprovals[0].promotionId  | 30cents off merchandise |

        Examples:
        | confirmed_by         |
        | CASHIER_AND_CONSUMER |
        | CASHIER              |


    @fast
    Scenario: The discount is not added to the transaction after cancelling the discount prompt on the pinpad.
        Given the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | approval_for         | approval_name | approval_description                |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | CASHIER_AND_CONSUMER | Best Reward   | Do you want to get the best reward? |
        And the POS is in a ready to sell state
        And the POS displays a PES discount approval frame after scanning a barcode 001
        When a customer cancels the boolean prompt on pinpad
        Then the POS displays main menu frame
        And a loyalty discount Miscellaneous with value of 0.30 is not in the virtual receipt
        And a loyalty discount Miscellaneous with value of 0.30 is not in the current transaction
        And the POS sends a GetPromotions request to PES with following elements
            | element                         | value                   |
            | rewardApprovals[0].approvalFlag | REJECT                  |
            | rewardApprovals[0].promotionId  | 30cents off merchandise |


    @fast
    Scenario: The POS displays discount confirmation prompt (tied to a discount with prompt id) when the item is configured for it.
        Given the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | prompt_approval      | prompt_id |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | CASHIER_AND_CONSUMER | 1         |
        And the POS is in a ready to sell state
        When the cashier scans a barcode 001
        Then the POS displays a PES discount approval frame
        And a loyalty discount Miscellaneous with value of 0.30 is not in the virtual receipt
        And a loyalty discount Miscellaneous with value of 0.30 is not in the current transaction


    @fast
    Scenario: The discount is added to the transaction after accepting it in discount confirmation prompt (tied to a previously
              received discount with a prompt id, following GET request does not contain prompt response).
        Given the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | prompt_approval      | prompt_id |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | CASHIER_AND_CONSUMER | 1         |
        And the POS is in a ready to sell state
        And the POS displays a PES discount approval frame after scanning a barcode 001
        When the cashier selects Yes button
        Then the POS displays main menu frame
        And a loyalty discount Miscellaneous with value of 0.30 is in the virtual receipt
        And a loyalty discount Miscellaneous with value of 0.30 is in the current transaction
        And following fields are not present in the GetPromotions request
            | element         |
            | prompts         |
            | rewardApprovals |


    @fast
    Scenario: The discount is not added to the transaction after declining it in discount confirmation prompt (tied to a previously
              received discount with a prompt id, PES is not notified again)
        Given the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | prompt_approval      | prompt_id |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | CASHIER_AND_CONSUMER | 1         |
        And the POS is in a ready to sell state
        And the POS displays a PES discount approval frame after scanning a barcode 001
        When the cashier selects No button
        Then the POS displays main menu frame
        And a loyalty discount Miscellaneous with value of 0.30 is not in the virtual receipt
        And a loyalty discount Miscellaneous with value of 0.30 is not in the current transaction
        And the POS sends no GetPromotions requests after last action


    @fast
    Scenario: The discount is not added to the transaction after cancelling the prompt on the pinpad (tied to a previously
              received discount with a prompt id, PES is not notified again)
        Given the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | prompt_approval      | prompt_id |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | CASHIER_AND_CONSUMER | 1         |
        And the POS is in a ready to sell state
        And the POS displays a PES discount approval frame after scanning a barcode 001
        When a customer cancels the boolean prompt on pinpad
        Then the POS displays main menu frame
        And a loyalty discount Miscellaneous with value of 0.30 is not in the virtual receipt
        And a loyalty discount Miscellaneous with value of 0.30 is not in the current transaction
        And the POS sends no GetPromotions requests after last action


    @fast
    Scenario Outline: The freestanding discount prompt is displayed after subtotal when PES card is present in the transaction
        Given the nep-server has following cards configured
            | card_number   | prompt_message                 | prompt_type |
            | <card_number> | Apply this fantastic discount? | BOOLEAN     |
        And the POS recognizes following PES cards
            | card_definition_id | card_role  | card_name    | barcode_range_from  | card_definition_group_id | track_format_1 | track_format_2 | mask_mode |
            | 70000001142        | 3          | <card_name>  | <card_number>       | 70000010042              | bt%at?         | bt;at?         | 21        |
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And a manually added card <card_name> with number <card_number> is present in the transaction
        When the cashier presses the cash tender button
        Then the POS sends a card with number <card_number> to PES with manual entry method
        And the POS displays a PES discount approval frame

        Examples:
        | card_number | card_name |
        | 1234444321  | PES card  |


    @fast
    Scenario Outline: Freestanding prompt cancelled on pinpad, Ask Tender amount frame is displayed, decline is sent in GET request
        Given the nep-server has following cards configured
            | card_number   | prompt_message                 | prompt_type | notification_for     |
            | <card_number> | Apply this fantastic discount? | BOOLEAN     | CASHIER_AND_CONSUMER |
        And the POS recognizes following PES cards
            | card_definition_id | card_role  | card_name    | barcode_range_from  | card_definition_group_id | track_format_1 | track_format_2 | mask_mode |
            | 70000001142        | 3          | <card_name>  | <card_number>       | 70000010042              | bt%at?         | bt;at?         | 21        |
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And PES discount approval frame is displayed after POS sends card <card_name> with number <card_number> to PES
        When a customer cancels the boolean prompt on pinpad
        Then the POS displays Ask tender amount cash frame
        And the POS sends a GetPromotions request to PES with following elements
            | element                    | value |
            | prompts[0].booleanResponse | False |

        Examples:
        | card_number | card_name |
        | 1234567895  | PES Card  |