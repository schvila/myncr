@pos @ulp
Feature: Unified Loyalty and Promotions - fuel prepay
    This feature file covers test cases with ULP discounts and ULP tenders received in fuel prepay transactions.

    Background: POS is configured for ULP feature
        Given the POS has essential configuration
        And the EPS simulator has essential configuration
        # Set Fuel credit prepay method to Auth and Capture
        And the POS option 1851 is set to 1
        # Set Prepay Grade Select Type option as One Touch
        And the POS option 5124 is set to 1
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        And the POS option 5277 is set to 1
        # Default Loyalty Discount Id is set to ULP_basic
        And the POS parameter 120 is set to ULP_basic
        # Add configured 'PES_tender' loyalty tender record
        And the pricebook contains PES loyalty tender allowed to exceed total amount
        And the POS has the following operators with security rights configured
            | operator_id | pin  | last_name  | first_name | security_group_id | security_application_id | operator_role |
            | 70000000014 | 1234 | 1234       | Cashier    | 70000025          | 10                      | Cashier       |
        And the POS has following discounts configured
            | reduction_id | description | price | external_id |
            | 1            | ULP loyalty | 0.00  | ULP_basic   |
        And the POS recognizes following PES cards
            | card_definition_id | card_role | card_name | barcode_range_from | card_definition_group_id |
            | 70000001142        | 3         | ULP card  | 3104174102936582   | 70000010042              |
        And the pricebook contains retail items
            | description     | price | item_id | barcode | credit_category | category_code |
            | Large Fries     | 2.19  | 111     | 001     | 2010            | 400           |
            | Generic Item    | 3.99  | 333     | 003     | 2000            | 400           |
        And the POS is configured to communicate with PES
        # Cloud Loyalty Interface is set to ULP
        And the POS option 5284 is set to 0
        And the nep-server has default configuration
        And the ULP loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id             | unit_type              | is_apply_as_tender |
            | 004            | Premium FPR          | 0.50           | item           | 50cents off premium fuel | GALLON_US_LIQUID       | False              |
            | 004            | Premium Tender       | 20.00          | transaction    | premium tender           | GENERAL_SALES_QUANTITY | True               |
            | 400            | Miscellaneous        | 0.30           | transaction    | 30cents off merchandise  | SIMPLE_QUANTITY        | False              |


    @positive @fast
    Scenario: Prepay is added into transaction, cashier presses the tender button, no SyncFinalize message is sent,
        GetPromotions message is sent and discounts are received
        Given the POS is in a ready to sell state
        And a ULP loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the prepay of the fuel grade regular with price 5.00 at pump id 1 is present in the transaction
        When the cashier totals the transaction using cash tender
        Then a card ULP card with value of 0.00 is in the current transaction
        And a loyalty discount Miscellaneous with value of 0.30 is in the current transaction
        And a loyalty discount Miscellaneous with value of 0.30 is in the virtual receipt
        And the POS sends no FinalizePromotions requests after last action
        And the POS sends a GetPromotions request to ULP with following elements
            | element            | value       |
            | items[0].itemName  | Sale Item A |
            | items[0].unitPrice | 0.99        |
            | items[1].itemName  | Regular     |
            | items[1].unitPrice | 2.00        |


    @positive @fast
    Scenario: Prepay is added into transaction, transaction is tendered, all prepaid fuel is dispensed,
        SyncFinalize message is sent and discounts are received
        Given the POS is in a ready to sell state
        And a ULP loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the prepay of the fuel grade regular with price 5.00 at pump id 1 is present in the transaction
        And the transaction is tendered
        When the customer dispensed regular for 5.00 price at pump 1
        Then the transaction is finalized
        And a card ULP card with value of 0.00 is in the previous transaction
        And a loyalty discount Miscellaneous with value of 0.30 is in the previous transaction
        And the POS sends a FinalizePromotions request to ULP with following elements
            | element                    | value            |
            | transactionType            | PREPAY           |
            | tenders[0].tenderType      | CASH             |
            | orderTotals[2].type        | ITEM_TOTAL       |
            | orderTotals[2].value       | 5.99             |
            | items[0].itemName          | Sale Item A      |
            | items[0].unitPrice         | 0.99             |
            | items[1].itemName          | Regular          |
            | items[1].unitPrice         | 2.00             |
            | items[1].quantity.unitType | GALLON_US_LIQUID |
            | items[1].quantity.units    | 2.50             |


    @fast @positive
    Scenario Outline: FPR discounts with reward limit, test refund for cash tenders
        Given the ULP loyalty host simulator has following combo discounts configured
            | category_codes   | discount_description | discount_value | discount_level | promotion_id             | unit_type        | reward_limit |
            | 004              | Premium FPR          | 0.50           | item           | 50cents off premium fuel | GALLON_US_LIQUID | 2            |
            | 001              | Regular FPR          | 0.25           | item           | 25cents off regular fuel | GALLON_US_LIQUID | 3            |
        And the POS is in a ready to sell state
        And the cashier selected a <grade_type> grade prepay at pump <pump_id>
        And the cashier enters price <prepay_amount> to prepay pump
        And the transaction is tendered
        And the customer dispensed <grade_type> for <dispense_price> price at pump <pump_id>
        When the cashier refunds the fuel from pump <pump_id>
        Then the transaction is finalized
        And an item <discount_description> with price <discount_value> and type 0 is in the previous transaction
        And a tender <tender_type> with amount <amount> is in the previous transaction

       Examples:
        | grade_type | prepay_amount | discount_description | discount_value | dispense_price | pump_id | tender_type | amount  |
        | Premium    | 25.00         | Premium FPR          | -1.00          | 8.00           | 1       | cash        | -18.00  |
        | Regular    | 10.00         | Regular FPR          | -0.75          | 8.00           | 2       | cash        | -4.75   |


    @fast @positive
    Scenario Outline: The POS option for smart prepay with grade selection is enabled, 
        prepay is added in the transaction, the correct reward limit is set on the pump.
        Given the ULP loyalty host simulator has following combo discounts configured
            | category_codes   | discount_description | discount_value | discount_level | promotion_id             | unit_type        | reward_limit |
            | 004              | Premium FPR          | 0.50           | item           | 50cents off premium fuel | GALLON_US_LIQUID | 2            |
            | 001              | Regular FPR          | 0.25           | item           | 25cents off regular fuel | GALLON_US_LIQUID | 3            |
        And the POS is in a ready to sell state
        And the cashier selected a <grade_type> grade prepay at pump <pump_id>
        And the cashier enters price <prepay_price> to prepay pump
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then reward limit is set to <reward_limit> at pump <pump_id>

       Examples:
        | grade_type | prepay_price | pump_id | reward_limit |
        | Premium    | 10.00        | 1       | 2            |
        | Regular    | 10.00        | 2       | 3            |

        
    @positive @fast
    Scenario: Grade selection is disabled, no request is sent to ULP when a prepay gets transferred.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the POS is in a ready to sell state
        And a ULP loyalty card 3104174102936582 is present in the transaction
        And a prepay with price 5.00 on the pump 1 is present in the transaction
        And the transaction is finalized
        When the cashier transfers the prepay from pump 1 to pump 2
        Then the POS does not send any requests after last action


    @positive @fast
    Scenario: Grade selection is disabled, no request is sent to ULP when a prepay with merchandise gets transferred.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And a ULP loyalty card 3104174102936582 is present in the transaction
        And a prepay with price 5.00 on the pump 1 is present in the transaction
        And the transaction is finalized
        When the cashier transfers the prepay from pump 1 to pump 2
        Then the POS does not send any requests after last action


    @positive @fast
    Scenario: Grade selection is disabled, correct finalize request is sent with correct pump number
                to ULP when a prepay is finished after transfer.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the POS is in a ready to sell state
        And a ULP loyalty card 3104174102936582 is present in the transaction
        And the cashier prepaid pump 1 for price 5.00 and transferred it to pump 2
        When the customer dispensed premium for 5.00 price at pump 2
        Then all pumps are in idle state
        And the POS sends a FinalizePromotions request to ULP with following elements
            | element                    | value            |
            | checkDetails.pumpId        | 2                |
            | transactionType            | PREPAY           |
            | tenders[0].tenderType      | LOYALTY          |
            | tenders[0].amount          | 5.00             |
            | tenders[1].tenderType      | CASH             |
            | tenders[1].amount          | 0.00             |
            | orderTotals[2].type        | ITEM_TOTAL       |
            | orderTotals[2].value       | 5.00             |
            | items[0].itemName          | Premium          |
            | items[0].unitPrice         | 4.20             |
            | items[0].quantity.unitType | GALLON_US_LIQUID |
            | items[0].quantity.units    | 1.19             |


    @positive @fast
    Scenario: Grade selection is disabled, correct finalize request is sent with correct pump number
                to ULP when a prepay with merchandise is finished after transfer.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And a ULP loyalty card 3104174102936582 is present in the transaction
        And the cashier prepaid pump 1 for price 5.00 and transferred it to pump 2
        When the customer dispensed premium for 5.00 price at pump 2
        Then all pumps are in idle state
        And the POS sends a FinalizePromotions request to ULP with following elements
            | element                    | value            |
            | checkDetails.pumpId        | 2                |
            | transactionType            | PREPAY           |
            | tenders[0].tenderType      | LOYALTY          |
            | tenders[0].amount          | 5.76             |
            | tenders[1].tenderType      | CASH             |
            | tenders[1].amount          | 0.00             |
            | orderTotals[2].type        | ITEM_TOTAL       |
            | orderTotals[2].value       | 5.99             |
            | items[0].itemName          | Sale Item A      |
            | items[0].unitPrice         | 0.99             |
            | items[1].itemName          | Premium          |
            | items[1].unitPrice         | 4.20             |
            | items[1].quantity.unitType | GALLON_US_LIQUID |
            | items[1].quantity.units    | 1.19             |
