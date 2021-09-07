@pos @pes
Feature: Promotion Execution Service - fuel prepay overruns.

    Background: POS is configured for PES feature
        Given the POS has essential configuration
        # Set Fuel Smart Prepay Overrun to Postpay option to False
        And the POS option 1849 is set to 0
        # Set Fuel credit prepay method to Auth and Capture
        And the POS option 1851 is set to 1
        # Set Prepay Grade Select Type option as One Touch
        And the POS option 5124 is set to 1
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        And the POS option 5277 is set to 1
        # Promotion Execution Service Allow partial discounts is set to Yes
        And the POS option 5278 is set to 1
        # Promotion Execution Service Send only loyalty transactions is set to Yes
        And the POS option 5279 is set to 1
        # Default Loyalty Discount Id is set to PES_basic
        And the POS parameter 120 is set to PES_basic
        # Add configured 'PES_tender' loyalty tender record
        And the pricebook contains PES loyalty tender
        And the POS has following discounts configured
            | reduction_id | description | price | external_id |
            | 1            | PES loyalty | 0.00  | PES_basic   |
        And the POS recognizes following PES cards
            | card_definition_id | card_role | card_name | barcode_range_from | card_definition_group_id |
            | 70000001142        | 3         | PES card  | 3104174102936582   | 70000010042              |
        And the pricebook contains retail items
            | description  | price | item_id | barcode | credit_category | category_code |
            | Large Fries  | 2.19  | 111     | 001     | 2010            | 400           |
            | Generic Item | 3.99  | 333     | 003     | 2000            | 400           |
        And the nep-server is online
        And the POS is configured to communicate with PES
        # Cloud Loyalty Interface is set to PES
        And the POS option 5284 is set to 1
        And the nep-server has default configuration
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id   | unit_type              | is_apply_as_tender |
            | 001            | Discount Tender      | 20.00          | transaction    | regular tender | GENERAL_SALES_QUANTITY | True               |


    @fast
    Scenario: Prepay with loyalty tender discount is not overrun and the transaction is finalized right away
        Given the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the prepay of the fuel grade regular with price 20.00 at pump id 1 is present in the transaction
        And the transaction is tendered
        When the customer dispensed regular for 20.00 price at pump 1
        Then the transaction is finalized
        And a tender Discount Tender with amount 20.00 is in the previous transaction
        And the POS sends a FinalizePromotions request to PES with following elements
            | element               | value   |
            | transactionType       | PREPAY  |
            | tenders[0].tenderType | LOYALTY |
            | tenders[0].amount     | 20.00   |
            | tenders[1].tenderType | CASH    |
            | tenders[1].amount     | 0.00    |


    @fast
    Scenario: Prepay with loyalty tender discount is overrun, but the discount can cover the overrun value,
        so the transaction is finalized right away
        Given the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the prepay of the fuel grade regular with price 10.00 at pump id 1 is present in the transaction
        And the transaction is tendered
        When the customer dispensed regular for 15.00 price at pump 1
        Then the transaction is finalized
        And a tender Discount Tender with amount 15.00 is in the previous transaction
        And the POS sends a FinalizePromotions request to PES with following elements
            | element               | value   |
            | transactionType       | PREPAY  |
            | tenders[0].tenderType | LOYALTY |
            | tenders[0].amount     | 15.00   |
            | tenders[1].tenderType | CASH    |
            | tenders[1].amount     | 0.00    |


    @fast
    Scenario: Prepay with loyalty tender discount is overrun, the overrun is moved to postpay and the POS does not send FinalizePromotions
        Given the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the prepay of the fuel grade regular with price 20.00 at pump id 1 is present in the transaction
        And the transaction is tendered
        When the customer dispensed regular for 25.00 price at pump 1
        Then the postpay for 5.00 is present on pump 1
        And the POS sends no FinalizePromotions requests after last action

    
    @fast
    Scenario: Prepay with loyalty tender discount is overrun, the discount can not cover the overrun value,
        the transaction is tendered as postpay
        Given the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the prepay of the fuel grade regular with price 20.00 at pump id 1 is present in the transaction
        And the transaction is tendered
        And the customer dispensed regular for 25.00 price at pump 1
        And the postpay from pump 1 is present in the transaction
        When the cashier tenders the transaction with amount 5.00 in cash
        Then a tender Discount Tender with amount 20.00 is in the previous transaction
        And a tender Cash with amount 5.00 is in the previous transaction
        And the POS sends no GetPromotions requests after last action
        And the POS sends a FinalizePromotions request to PES with following elements
            | element               | value   |
            | transactionType       | PREPAY  |
            | tenders[0].tenderType | LOYALTY |
            | tenders[0].amount     | 20.00   |
            | tenders[1].tenderType | CASH    |
            | tenders[1].amount     | 0.00    |
            | tenders[2].tenderType | CASH    |
            | tenders[2].amount     | 5.00    |