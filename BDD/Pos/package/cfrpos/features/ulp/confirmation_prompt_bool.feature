@pos @ulp
Feature: Unified Loyalty and Promotions - boolean confirmation prompts
    This feature file focuses on boolean Yes/No confirmation prompts.

    Background: POS is configured for ULP feature
        Given the POS has essential configuration
        And the POS is configured to communicate with PES
        # Cloud Loyalty Interface is set to ULP
        And the POS option 5284 is set to 0
        And the nep-server has default configuration
        # Default Loyalty Discount Id is set to ULP_basic
        And the POS parameter 120 is set to ULP_basic
        And the POS has following discounts configured
            | reduction_id | description | price | external_id |
            | 1            | ULP loyalty | 0.00  | ULP_basic   |
        And the pricebook contains retail items
            | description     | price | item_id | barcode | credit_category | category_code |
            | Large Fries     | 2.19  | 111     | 001     | 2010            | 400           |
            | Marlboro Lights | 4.00  | 112     | 002     | 2010            | 400           |
        And an item Marlboro Lights is set not to be discountable


    @fast
    Scenario Outline: The POS (and pinpad) displays reward discount confirmation prompt with custom title and text if configured,
                      otherwise a default one is used.
        Given the ULP loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | approval_for         | approval_name | approval_description | approval_description_key |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | CASHIER_AND_CONSUMER | <custom_title>| <custom_text>        | en-US                    |
        And the POS is in a ready to sell state
        When the cashier scans a barcode 001
        Then the POS displays a PES discount approval frame with title <displayed_title> and description <displayed_text>
        And the pinpad displays boolean prompt with title <displayed_title> and description <displayed_text>
        And a loyalty discount Miscellaneous with value of 0.30 is not in the virtual receipt
        And a loyalty discount Miscellaneous with value of 0.30 is not in the current transaction

        Examples:
        | custom_title | displayed_title | custom_text                         | displayed_text                      |
        | Best Reward  | Best Reward     | Do you want to get the best reward? | Do you want to get the best reward? |
        |              | Apply Discount  |                                     | Do you want to apply the discount?  |


    @fast
    Scenario: The POS does not display reward discount confirmation prompt if there are no discountable items in the transaction
        Given the ULP loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | approval_for         | approval_name | approval_description                | approval_description_key |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | CASHIER_AND_CONSUMER | Best Reward   | Do you want to get the best reward? | en-US                    |
        And the POS is in a ready to sell state
        When the cashier scans a barcode 002
        Then the POS displays main menu frame
        And a loyalty discount Miscellaneous with value of 0.30 is not in the virtual receipt
        And a loyalty discount Miscellaneous with value of 0.30 is not in the current transaction


    @fast
    Scenario Outline: The POS displays reward discount confirmation prompt if there is at least one discountable item in the transaction
        Given the ULP loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | approval_for         | approval_name | approval_description | approval_description_key |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | CASHIER_AND_CONSUMER | <custom_title>| <custom_text>        | en-US                    |
        And the POS is in a ready to sell state
        And an item with barcode 002 is present in the transaction
        When the cashier scans a barcode 001
        Then the POS displays a PES discount approval frame with title <displayed_title> and description <displayed_text>
        And the pinpad displays boolean prompt with title <displayed_title> and description <displayed_text>
        And a loyalty discount Miscellaneous with value of 0.30 is not in the virtual receipt
        And a loyalty discount Miscellaneous with value of 0.30 is not in the current transaction

        Examples:
        | custom_title | displayed_title | custom_text                         | displayed_text                      |
        | Best Reward  | Best Reward     | Do you want to get the best reward? | Do you want to get the best reward? |


    @fast
    Scenario Outline: The POS (not pinpad) displays reward discount confirmation prompt with custom title and text if configured,
                      otherwise a default one is used.
        Given the ULP loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | approval_for | approval_name | approval_description | approval_description_key |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | CASHIER      | <custom_title>| <custom_text>        | en-US                    |
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
        Given the ULP loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | approval_for | approval_name | approval_description | approval_description_key |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | CONSUMER     | <custom_title>| <custom_text>        | en-US                    |
        And the POS is in a ready to sell state
        When the cashier scans a barcode 001
        Then the POS displays Wait for customer confirmation frame
        And the pinpad displays boolean prompt with title <displayed_title> and description <displayed_text>
        And a loyalty discount Miscellaneous with value of 0.30 is not in the virtual receipt
        And a loyalty discount Miscellaneous with value of 0.30 is not in the current transaction

        Examples:
        | custom_title | displayed_title | custom_text                         | displayed_text                      |
        | Best Reward  | Best Reward     | Do you want to get the best reward? | Do you want to get the best reward? |
        |              | Apply Discount  |                                     | Do you want to apply the discount?  |


    @fast
    Scenario Outline: The discount is added to the transaction after accepting it in reward discount confirmation prompt.
        Given the ULP loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | approval_for   | approval_name | approval_description                | approval_description_key |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | <confirmed_by> | Best Reward   | Do you want to get the best reward? | en-US                    |
        And the POS is in a ready to sell state
        And the POS displays a PES discount approval frame after scanning a barcode 001
        When the cashier selects Yes button
        Then the POS displays main menu frame
        And a loyalty discount Miscellaneous with value of 0.30 is in the virtual receipt
        And a loyalty discount Miscellaneous with value of 0.30 is in the current transaction
        And the POS sends a GetPromotions request to ULP with following elements
            | element                         | value                   |
            | rewardApprovals[0].approvalFlag | APPROVE                 |
            | rewardApprovals[0].promotionId  | 30cents off merchandise |

        Examples:
        | confirmed_by         |
        | CASHIER_AND_CONSUMER |
        | CASHIER              |


    @fast
    Scenario Outline: The discount is not added to the transaction after declining it in reward discount confirmation prompt.
        Given the ULP loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | approval_for   | approval_name | approval_description                | approval_description_key |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | <confirmed_by> | Best Reward   | Do you want to get the best reward? | en-US                    |
        And the POS is in a ready to sell state
        And the POS displays a PES discount approval frame after scanning a barcode 001
        When the cashier selects No button
        Then the POS displays main menu frame
        And a loyalty discount Miscellaneous with value of 0.30 is not in the virtual receipt
        And a loyalty discount Miscellaneous with value of 0.30 is not in the current transaction
        And the POS sends a GetPromotions request to ULP with following elements
            | element                         | value                   |
            | rewardApprovals[0].approvalFlag | REJECT                  |
            | rewardApprovals[0].promotionId  | 30cents off merchandise |

        Examples:
        | confirmed_by         |
        | CASHIER_AND_CONSUMER |
        | CASHIER              |


    @fast
    Scenario: The discount is not added to the transaction after cancelling the discount prompt on the pinpad
        Given the ULP loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | approval_for         | approval_name     | approval_description | approval_description_key |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | CASHIER_AND_CONSUMER | <displayed_title> | <displayed_text>     | en-US                    |
        And the POS is in a ready to sell state
        And the POS displays a PES discount approval frame after scanning a barcode 001
        And the pinpad displays boolean prompt with title <displayed_title> and description <displayed_text>
        When a customer cancels the boolean prompt on pinpad
        Then the POS displays main menu frame
        And a loyalty discount Miscellaneous with value of 0.30 is not in the virtual receipt
        And a loyalty discount Miscellaneous with value of 0.30 is not in the current transaction
        And the POS sends a GetPromotions request to ULP with following elements
            | element                         | value                   | displayed_title | displayed_text                      |
            | rewardApprovals[0].approvalFlag | REJECT                  | Best Reward     | Do you want to get the best reward? |
            | rewardApprovals[0].promotionId  | 30cents off merchandise | Best Reward     | Do you want to get the best reward? |


    @fast
    Scenario: The POS displays discount confirmation prompt (tied to a discount with prompt id) when the item is configured for it.
        Given the ULP loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | prompt_approval      | prompt_id |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | CASHIER_AND_CONSUMER | 1         |
        And the POS is in a ready to sell state
        When the cashier scans a barcode 001
        Then the POS displays a PES discount approval frame
        And the pinpad displays boolean prompt
        And a loyalty discount Miscellaneous with value of 0.30 is not in the virtual receipt
        And a loyalty discount Miscellaneous with value of 0.30 is not in the current transaction


    @fast
    Scenario: The discount is added to the transaction after accepting it in discount confirmation prompt (tied to a previously
              received discount with a prompt id, following GET request does not contain prompt response).
        Given the ULP loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | prompt_approval      | prompt_id |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | CASHIER_AND_CONSUMER | 1         |
        And the POS is in a ready to sell state
        And the POS displays a PES discount approval frame after scanning a barcode 001
        And the pinpad displays boolean prompt
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
              received discount with a prompt id, ULP is not notified again)
        Given the ULP loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | prompt_approval      | prompt_id |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | CASHIER_AND_CONSUMER | 1         |
        And the POS is in a ready to sell state
        And the POS displays a PES discount approval frame after scanning a barcode 001
        And the pinpad displays boolean prompt
        When the cashier selects No button
        Then the POS displays main menu frame
        And a loyalty discount Miscellaneous with value of 0.30 is not in the virtual receipt
        And a loyalty discount Miscellaneous with value of 0.30 is not in the current transaction
        And the POS sends no GetPromotions requests after last action


    @fast
    Scenario: The discount is not added to the transaction after cancelling the prompt on the pinpad (tied to a previously
              received discount with a prompt id, ULP is not notified again)
        Given the ULP loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | prompt_approval      | prompt_id |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | CASHIER_AND_CONSUMER | 1         |
        And the POS is in a ready to sell state
        And the POS displays a PES discount approval frame after scanning a barcode 001
        And the pinpad displays boolean prompt
        When a customer cancels the boolean prompt on pinpad
        Then the POS displays main menu frame
        And a loyalty discount Miscellaneous with value of 0.30 is not in the virtual receipt
        And a loyalty discount Miscellaneous with value of 0.30 is not in the current transaction
        And the POS sends no GetPromotions requests after last action

