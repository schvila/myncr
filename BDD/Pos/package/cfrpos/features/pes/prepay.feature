@pos @pes
Feature: Promotion Execution Service - fuel prepay
    This feature file covers test cases with PES discounts and PES tenders received in fuel prepay transactions.

    Background: POS is configured for PES feature
        Given the POS has essential configuration
        And the EPS simulator has essential configuration
        # Set Fuel credit prepay method to Auth and Capture
        And the POS option 1851 is set to 1
        # Set Prepay Grade Select Type option as One Touch
        And the POS option 5124 is set to 1
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        And the POS option 5277 is set to 1
        # Default Loyalty Discount Id is set to PES_basic
        And the POS parameter 120 is set to PES_basic
        # Add configured 'PES_tender' loyalty tender record
        And the pricebook contains PES loyalty tender allowed to exceed total amount
        And the POS has the following operators with security rights configured
        | operator_id | pin  | last_name  | first_name | security_group_id | security_application_id | operator_role |
        | 70000000014 | 1234 | 1234       | Cashier    | 70000025          | 10                      | Cashier       |
        And the POS has following discounts configured
            | reduction_id | description | price | external_id |
            | 1            | PES loyalty | 0.00  | PES_basic   |
        And the POS recognizes following PES cards
            | card_definition_id | card_role | card_name | barcode_range_from | card_definition_group_id |
            | 70000001142        | 3         | PES card  | 3104174102936582   | 70000010042              |
        And the pricebook contains retail items
            | description     | price | item_id | barcode | credit_category | category_code |
            | Large Fries     | 2.19  | 111     | 001     | 2010            | 400           |
            | Generic Item    | 3.99  | 333     | 003     | 2000            | 400           |
        And the POS is configured to communicate with PES
        # Cloud Loyalty Interface is set to PES
        And the POS option 5284 is set to 1
        And the nep-server has default configuration
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id             | unit_type              | is_apply_as_tender |
            | 004            | Premium FPR          | 0.50           | item           | 50cents off premium fuel | GALLON_US_LIQUID       | False              |
            | 004            | Premium Tender       | 20.00          | transaction    | premium tender           | GENERAL_SALES_QUANTITY | True               |
            | 400            | Miscellaneous        | 0.30           | transaction    | 30cents off merchandise  | SIMPLE_QUANTITY        | False              |


    @positive @fast
    Scenario: Prepay is added into transaction, cashier presses the tender button, no SyncFinalize message is sent,
        GetPromotions message is sent and discounts are received
        Given the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the prepay of the fuel grade regular with price 5.00 at pump id 1 is present in the transaction
        When the cashier totals the transaction using cash tender
        Then a card PES card with value of 0.00 is in the current transaction
        And a loyalty discount Miscellaneous with value of 0.30 is in the current transaction
        And a loyalty discount Miscellaneous with value of 0.30 is in the virtual receipt
        And the POS sends no FinalizePromotions requests after last action
        And the POS sends a GetPromotions request to PES with following elements
            | element            | value       |
            | items[0].itemName  | Sale Item A |
            | items[0].unitPrice | 0.99        |
            | items[1].itemName  | Regular     |
            | items[1].unitPrice | 2.00        |


    @positive @fast
    Scenario: Prepay is added into transaction, transaction is tendered, all prepaid fuel is dispensed,
        SyncFinalize message is sent and discounts are received
        Given the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the prepay of the fuel grade regular with price 5.00 at pump id 1 is present in the transaction
        And the transaction is tendered
        When the customer dispensed regular for 5.00 price at pump 1
        Then the transaction is finalized
        And a card PES card with value of 0.00 is in the previous transaction
        And a loyalty discount Miscellaneous with value of 0.30 is in the previous transaction
        And the POS sends a FinalizePromotions request to PES with following elements
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


    @positive @fast
    Scenario: Prepay is added into transaction, transaction is tendered, prepaid fuel is under-dispensed,
        cashier refunds the fuel, SyncFinalize message is sent and discounts are received
        Given the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the prepay of the fuel grade regular with price 5.00 at pump id 1 is present in the transaction
        And the transaction is tendered
        And the customer dispensed regular for 4.00 price at pump 1
        When the cashier refunds the fuel from pump 1
        Then the transaction is finalized
        And a card PES card with value of 0.00 is in the previous transaction
        And a loyalty discount Miscellaneous with value of 0.30 is in the previous transaction
        And the POS sends a FinalizePromotions request to PES with following elements
            | element                    | value            |
            | transactionType            | PREPAY           |
            | tenders[0].tenderType      | CASH             |
            | tenders[0].amount          | 5.76             |
            | tenders[1].tenderType      | CASH             |
            | tenders[1].amount          | -1.00            |
            | orderTotals[2].type        | ITEM_TOTAL       |
            | orderTotals[2].value       | 4.99             |
            | items[0].itemName          | Sale Item A      |
            | items[0].unitPrice         | 0.99             |
            | items[1].itemName          | Regular          |
            | items[1].unitPrice         | 2.00             |
            | items[1].quantity.unitType | GALLON_US_LIQUID |
            | items[1].quantity.units    | 2.00             |


    @positive @fast
    Scenario: Prepay is added into transaction, cashier presses the tender button, no SyncFinalize message is sent,
        GetPromotions message is sent and discount and loyalty tender are received
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the prepay of the fuel grade premium with price 5.00 at pump id 1 is present in the transaction
        When the cashier totals the transaction using cash tender
        Then a card PES card with value of 0.00 is in the current transaction
        And a discount Premium FPR is in the current transaction
        And a discount Premium FPR with value of 0.00 is in the virtual receipt
        And a tender Premium Tender is in the current transaction
        And a tender Premium Tender is in the virtual receipt
        And the transaction's balance is 0.00
        And the POS sends no FinalizePromotions requests after last action
        And the POS sends a GetPromotions request to PES with following elements
            | element            | value   |
            | items[0].itemName  | Premium |
            | items[0].unitPrice | 4.00    |


    @positive @fast
    Scenario: Prepay is added into transaction, transaction is tendered with PES loyalty tender, all prepaid fuel is dispensed,
        SyncFinalize message is sent and discounts are received
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the prepay of the fuel grade premium with price 5.00 at pump id 1 is present in the transaction
        And the transaction is tendered
        When the customer dispensed premium for 5.00 price at pump 1
        Then the transaction is finalized
        And a card PES card with value of 0.00 is in the previous transaction
        And a discount Premium FPR is in the previous transaction
        And a tender Premium Tender is in the previous transaction
        And the POS sends a FinalizePromotions request to PES with following elements
            | element                    | value            |
            | transactionType            | PREPAY           |
            | tenders[0].tenderType      | LOYALTY          |
            | tenders[0].amount          | 5.00             |
            | tenders[1].tenderType      | CASH             |
            | tenders[1].amount          | 0.00             |
            | orderTotals[2].type        | ITEM_TOTAL       |
            | orderTotals[2].value       | 5.00             |
            | items[0].itemName          | Premium          |
            | items[0].unitPrice         | 3.70             |
            | items[0].quantity.unitType | GALLON_US_LIQUID |
            | items[0].quantity.units    | 1.351            |


    @positive @fast
    Scenario: Prepay is added into transaction, transaction is tendered with PES loyalty tender and cash, prepaid fuel is under-dispensed,
        cashier refunds the fuel, SyncFinalize message is sent and discounts are received
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the prepay of the fuel grade premium with price 5.00 at pump id 1 is present in the transaction
        And the transaction is tendered
        When the customer dispensed premium for 4.00 price at pump 1
        Then the transaction is finalized
        And a card PES card with value of 0.00 is in the previous transaction
        And a loyalty discount Miscellaneous with value of 0.30 is in the previous transaction
        And a discount Premium FPR is in the previous transaction
        And a tender Premium Tender is in the previous transaction
        And the POS sends a FinalizePromotions request to PES with following elements
            | element                                 | value                    |
            | transactionType                         | PREPAY                   |
            | tenders[0].tenderType                   | LOYALTY                  |
            | tenders[0].amount                       | 4.76                     |
            | tenders[1].tenderType                   | CASH                     |
            | tenders[1].amount                       | 0.00                     |
            | orderTotals[2].type                     | ITEM_TOTAL               |
            | orderTotals[2].value                    | 4.99                     |
            | items[0].itemName                       | Sale Item A              |
            | items[0].unitPrice                      | 0.99                     |
            | items[1].itemName                       | Premium                  |
            | items[1].quantity.unitType              | GALLON_US_LIQUID         |
            | items[1].quantity.units                 | 1.081                    |
            | items[1].unitPrice                      | 3.70                     |
            | items[1].adjustments[0].promotionId     | 50cents off premium fuel |
            | items[1].adjustments[0].adjustmentValue | 0.50                     |


    @positive @fast
    Scenario: Prepay is completed, PES discounts are received and POS transfers the PES response to fuel interface
        Given the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the prepay of the fuel grade regular with price 5.00 at pump id 1 is present in the transaction
        And the transaction is tendered
        When the customer dispensed regular for 5.00 price at pump 1
        Then the transaction is finalized
        And the POS processes the FinalizePromotions response
        And a card PES card with value of 0.00 is in the previous transaction
        And a loyalty discount Miscellaneous with value of 0.30 is in the previous transaction
        And the PES response is sent to pump 1


    @fast
    Scenario Outline: The POS sends VoidPromotions request after voiding transaction with prepay tendered with loyalty points.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the prepay of the fuel grade premium with price 5.00 at pump id 1 is present in the transaction
        And a loyalty tender Premium Tender with value of 5.00 is present in the transaction after subtotal
        When the manager voids the transaction with <manager_pin> pin and reason <reason>
        Then the POS sends VoidPromotions request to PES after last action
        And the POS displays main menu frame
        And no transaction is in progress

        Examples:
        | manager_pin | reason                    |
        | 2345        | Cancel Transaction Reason |


    @fast
    Scenario Outline: The POS sends VoidPromotions request after voiding transaction with prepay and dry stock tendered with loyalty points.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 001 is present in the transaction
        And the prepay of the fuel grade premium with price 5.00 at pump id 1 is present in the transaction
        And a loyalty tender Premium Tender with value of 7.04 is present in the transaction after subtotal
        When the manager voids the transaction with <manager_pin> pin and reason <reason>
        Then the POS sends VoidPromotions request to PES after last action
        And the POS displays main menu frame
        And no transaction is in progress

        Examples:
        | manager_pin | reason                    |
        | 2345        | Cancel Transaction Reason |


    @fast
    Scenario: The cashier cancels and refunds prepaid fuel tendered with loyalty points, the FinalizePromotions
             request was sent containing orderLevelAdjustments element with value 0.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the prepay of the fuel grade premium with price 5.00 at pump id 1 is present in the transaction
        And the cashier tendered transaction with cash
        When the cashier cancels and refunds the fuel from pump 1
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                                  | value        |
            | orderLevelAdjustments[0].adjustmentValue | 0.00         |
        And the POS displays main menu frame
        And no transaction is in progress


    @fast
    Scenario: The cashier cancels and refunds prepaid fuel tendered with loyalty points together dry stock, the FinalizePromotions
             request was sent containing orderLevelAdjustments element with value of dry stock.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 001 is present in the transaction
        And the prepay of the fuel grade premium with price 5.00 at pump id 1 is present in the transaction
        And the cashier tendered transaction with cash
        When the cashier cancels and refunds the fuel from pump 1
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                                  | value        |
            | orderLevelAdjustments[0].adjustmentValue | 2.04         |
        And the POS displays main menu frame
        And no transaction is in progress


    @fast
    Scenario: Pump goes offline after the loyalty tender is applied for transaction with prepay, attempt to finalize trasaction,
                the Authorization failed refund customer error is displayed
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And the prepay of the fuel grade premium with price 5.00 at pump id 1 is present in the transaction
        And the transaction is totaled
        And the pump 1 went offline
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS displays Pump authorization failed, customer has been refunded error


    @fast
    Scenario: The cashier refunds fuel after selecting Go Back on Authorization failed refund customer error frame, the FinalizePromotions
             request was sent containing orderLevelAdjustments element with value of 0.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the prepay of the fuel grade premium with price 5.00 at pump id 1 is present in the transaction
        When the cashier selects Go back button on Pump authorization failed, customer has been refunded error frame
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                                  | value        |
            | orderLevelAdjustments[0].adjustmentValue | 0.00         |


    @fast
    Scenario: The cashier refunds fuel after selecting Go Back on Authorization failed refund customer error frame, the FinalizePromotions
             request was sent containing orderLevelAdjustments element with value of dry stock.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the prepay of the fuel grade premium with price 20.00 at pump id 1 is present in the transaction
        And the cashier selected Go back button on Pump authorization failed, refund customer error frame
        When the cashier refunds the fuel from pump 1
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                                  | value        |
            | orderLevelAdjustments[0].adjustmentValue | 2.04         |


    @fast @positive
    Scenario Outline: FPR discounts with reward limit, test refund for cash tenders
        # Set Prepay Grade Select Type option as One Touch
        Given the POS option 5124 is set to 1
        # And Premium cash price per gallon is $4.00
        # And Premium credit price per gallon is $4.20
        # And Regular cash price per gallon is $2.00
        # And Regular credit price per gallon is $2.20
        And the PES loyalty host simulator has following combo discounts configured
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
    Scenario Outline: The POS option for smart prepay with grade selection is enabled, prepay is added in the transaction, the correct reward limit is set on the pump.
        # Set Prepay Grade Select Type option as One Touch
        Given the POS option 5124 is set to 1
        And the PES loyalty host simulator has following combo discounts configured
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


    @fast @negative
    Scenario Outline: The POS option for smart prepay with grade selection is not enabled, prepay is added in the transaction, the correct reward limit is set on the pump.
        # Set Prepay Grade Select Type option as None
        Given the POS option 5124 is set to 0
        And the PES loyalty host simulator has following combo discounts configured
        | category_codes   | discount_description | discount_value | discount_level | promotion_id             | unit_type        | reward_limit |
        | 001              | Regular FPR          | 0.25           | item           | 25cents off regular fuel | GALLON_US_LIQUID | 2            |
        And the POS is in a ready to sell state
        And a prepay with price <prepay_amount> on the pump <pump_id> is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then reward limit is set to <reward_limit> at pump <pump_id>

       Examples:
        | prepay_amount | pump_id | reward_limit |
        | 10.00         | 2       | 2            |


    @positive @fast
    Scenario: Grade selection is enabled, no request is sent to PES when a prepay gets transferred.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the prepay of the fuel grade premium with price 5.00 at pump id 1 is present in the transaction
        And the transaction is finalized
        When the cashier transfers the prepay from pump 1 to pump 2
        Then the POS does not send any requests after last action


    @positive @fast
    Scenario: Grade selection is enabled, no request is sent to PES when a prepay with merchandise gets transferred.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the prepay of the fuel grade premium with price 5.00 at pump id 1 is present in the transaction
        And the transaction is finalized
        When the cashier transfers the prepay from pump 1 to pump 2
        Then the POS does not send any requests after last action


    @positive @fast
    Scenario: Grade selection is enabled, correct finalize request is sent with correct pump number
                to PES when a prepay is finished after transfer.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the cashier prepaid pump 1 for price 5.0 of premium and transferred it to pump 2
        When the customer dispensed premium for 5.00 price at pump 2
        Then all pumps are in idle state
        And the POS sends a FinalizePromotions request to PES with following elements
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
    Scenario: Grade selection is enabled, correct finalize request is sent with correct pump number
                to PES when a prepay with merchandise is finished after transfer.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the cashier prepaid pump 1 for price 5.0 of premium and transferred it to pump 2
        When the customer dispensed premium for 5.00 price at pump 2
        Then all pumps are in idle state
        And the POS sends a FinalizePromotions request to PES with following elements
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


    @positive @fast
    Scenario: Grade selection is enabled, correct finalize request is sent with correct pump number
                to PES when a prepay is canceled on POS after transfer.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the cashier prepaid pump 1 for price 5.0 of premium and transferred it to pump 2
        When the cashier cancels the prepay on pump 2
        Then all pumps are in idle state
        And the POS sends a FinalizePromotions request to PES with following elements
            | element                    | value            |
            | checkDetails.pumpId        | 2                |
            | transactionType            | PREPAY           |
            | tenders[0].tenderType      | LOYALTY          |
            | tenders[0].amount          | 0.00             |
            | tenders[1].tenderType      | CASH             |
            | tenders[1].amount          | 0.00             |
            | orderTotals[2].type        | ITEM_TOTAL       |
            | orderTotals[2].value       | 0.00             |
            | items[0].itemName          | Premium          |
            | items[0].unitPrice         | 3.70             |
            | items[0].quantity.unitType | GALLON_US_LIQUID |
            | items[0].quantity.units    | 0.00             |


    @positive @fast
    Scenario: Grade selection is enabled, correct finalize request is sent with correct pump number
                to PES when a prepay with merchandise is canceled on POS after transfer.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the cashier prepaid pump 1 for price 5.0 of premium and transferred it to pump 2
        When the cashier cancels the prepay on pump 2
        Then all pumps are in idle state
        And the POS sends a FinalizePromotions request to PES with following elements
            | element                    | value            |
            | checkDetails.pumpId        | 2                |
            | transactionType            | PREPAY           |
            | tenders[0].tenderType      | LOYALTY          |
            | tenders[0].amount          | 0.76             |
            | tenders[1].tenderType      | CASH             |
            | tenders[1].amount          | 0.00             |
            | orderTotals[2].type        | ITEM_TOTAL       |
            | orderTotals[2].value       | 0.99             |
            | items[0].itemName          | Sale Item A      |
            | items[0].unitPrice         | 0.99             |
            | items[1].itemName          | Premium          |
            | items[1].unitPrice         | 3.70             |
            | items[1].quantity.unitType | GALLON_US_LIQUID |
            | items[1].quantity.units    | 0.00             |


    @positive @fast
    Scenario: Grade selection is enabled, correct finalize request is sent with correct pump number
                to PES when a prepay is canceled on pump after transfer.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the cashier prepaid pump 1 for price 5.0 of premium and transferred it to pump 2
        When the customer cancels the prepay on pump 2
        Then all pumps are in idle state
        And the POS sends a FinalizePromotions request to PES with following elements
            | element                    | value            |
            | checkDetails.pumpId        | 2                |
            | transactionType            | PREPAY           |
            | tenders[0].tenderType      | LOYALTY          |
            | tenders[0].amount          | 0.00             |
            | tenders[1].tenderType      | CASH             |
            | tenders[1].amount          | 0.00             |
            | orderTotals[2].type        | ITEM_TOTAL       |
            | orderTotals[2].value       | 0.00             |
            | items[0].itemName          | Premium          |
            | items[0].unitPrice         | 3.70             |
            | items[0].quantity.unitType | GALLON_US_LIQUID |
            | items[0].quantity.units    | 0.00             |


    @positive @fast
    Scenario: Grade selection is enabled, correct finalize request is sent with correct pump number
                to PES when a prepay with merchandise is canceled on pump after transfer.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the cashier prepaid pump 1 for price 5.0 of premium and transferred it to pump 2
        When the customer cancels the prepay on pump 2
        Then all pumps are in idle state
        And the POS sends a FinalizePromotions request to PES with following elements
            | element                    | value            |
            | checkDetails.pumpId        | 2                |
            | transactionType            | PREPAY           |
            | tenders[0].tenderType      | LOYALTY          |
            | tenders[0].amount          | 0.76             |
            | tenders[1].tenderType      | CASH             |
            | tenders[1].amount          | 0.00             |
            | orderTotals[2].type        | ITEM_TOTAL       |
            | orderTotals[2].value       | 0.99             |
            | items[0].itemName          | Sale Item A      |
            | items[0].unitPrice         | 0.99             |
            | items[1].itemName          | Premium          |
            | items[1].unitPrice         | 3.70             |
            | items[1].quantity.unitType | GALLON_US_LIQUID |
            | items[1].quantity.units    | 0.00             |


    @positive @fast
    Scenario: Grade selection is disabled, no request is sent to PES when a prepay gets transferred.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And a prepay with price 5.00 on the pump 1 is present in the transaction
        And the transaction is finalized
        When the cashier transfers the prepay from pump 1 to pump 2
        Then the POS does not send any requests after last action


    @positive @fast
    Scenario: Grade selection is disabled, no request is sent to PES when a prepay with merchandise gets transferred.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And a PES loyalty card 3104174102936582 is present in the transaction
        And a prepay with price 5.00 on the pump 1 is present in the transaction
        And the transaction is finalized
        When the cashier transfers the prepay from pump 1 to pump 2
        Then the POS does not send any requests after last action


    @positive @fast
    Scenario: Grade selection is disabled, correct finalize request is sent with correct pump number
                to PES when a prepay is finished after transfer.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the cashier prepaid pump 1 for price 5.00 and transferred it to pump 2
        When the customer dispensed premium for 5.00 price at pump 2
        Then all pumps are in idle state
        And the POS sends a FinalizePromotions request to PES with following elements
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
                to PES when a prepay with merchandise is finished after transfer.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the cashier prepaid pump 1 for price 5.00 and transferred it to pump 2
        When the customer dispensed premium for 5.00 price at pump 2
        Then all pumps are in idle state
        And the POS sends a FinalizePromotions request to PES with following elements
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


    @positive @fast
    Scenario: Grade selection is disabled, correct finalize request is sent with correct pump number
                to PES when a prepay is canceled on POS after transfer.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the cashier prepaid pump 1 for price 5.00 and transferred it to pump 2
        When the cashier cancels the prepay on pump 2
        Then all pumps are in idle state
        And the POS sends a FinalizePromotions request to PES with following elements
            | element                    | value            |
            | checkDetails.pumpId        | 2                |
            | transactionType            | PREPAY           |
            | tenders[0].tenderType      | LOYALTY          |
            | tenders[0].amount          | 0.00             |
            | tenders[1].tenderType      | CASH             |
            | tenders[1].amount          | 0.00             |
            | orderTotals[2].type        | ITEM_TOTAL       |
            | orderTotals[2].value       | 0.00             |
            | items[0].itemName          | Fuel             |
            | items[0].unitPrice         | 1.00             |
            | items[0].quantity.unitType | GALLON_US_LIQUID |
            | items[0].quantity.units    | 0.00             |


    @positive @fast
    Scenario: Grade selection is disabled, correct finalize request is sent with correct pump number
                to PES when a prepay with merchandise is canceled on POS after transfer.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the cashier prepaid pump 1 for price 5.00 and transferred it to pump 2
        When the cashier cancels the prepay on pump 2
        Then all pumps are in idle state
        And the POS sends a FinalizePromotions request to PES with following elements
            | element                    | value            |
            | checkDetails.pumpId        | 2                |
            | transactionType            | PREPAY           |
            | tenders[0].tenderType      | LOYALTY          |
            | tenders[0].amount          | 0.76             |
            | tenders[1].tenderType      | CASH             |
            | tenders[1].amount          | 0.00             |
            | orderTotals[2].type        | ITEM_TOTAL       |
            | orderTotals[2].value       | 0.99             |
            | items[0].itemName          | Sale Item A      |
            | items[0].unitPrice         | 0.99             |
            | items[1].itemName          | Fuel             |
            | items[1].unitPrice         | 1.00             |
            | items[1].quantity.unitType | GALLON_US_LIQUID |
            | items[1].quantity.units    | 0.00             |


    @positive @fast
    Scenario: Grade selection is disabled, correct finalize request is sent with correct pump number
                to PES when a prepay is canceled on pump after transfer.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the cashier prepaid pump 1 for price 5.00 and transferred it to pump 2
        When the customer cancels the prepay on pump 2
        Then all pumps are in idle state
        And the POS sends a FinalizePromotions request to PES with following elements
            | element                    | value            |
            | checkDetails.pumpId        | 2                |
            | transactionType            | PREPAY           |
            | tenders[0].tenderType      | LOYALTY          |
            | tenders[0].amount          | 0.00             |
            | tenders[1].tenderType      | CASH             |
            | tenders[1].amount          | 0.00             |
            | orderTotals[2].type        | ITEM_TOTAL       |
            | orderTotals[2].value       | 0.00             |
            | items[0].itemName          | Fuel             |
            | items[0].unitPrice         | 1.00             |
            | items[0].quantity.unitType | GALLON_US_LIQUID |
            | items[0].quantity.units    | 0.00             |


    @positive @fast
    Scenario: Grade selection is disabled, correct finalize request is sent with correct pump number
                to PES when a prepay with merchandise is canceled on pump after transfer.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the cashier prepaid pump 1 for price 5.00 and transferred it to pump 2
        When the customer cancels the prepay on pump 2
        Then all pumps are in idle state
        And the POS sends a FinalizePromotions request to PES with following elements
            | element                    | value            |
            | checkDetails.pumpId        | 2                |
            | transactionType            | PREPAY           |
            | tenders[0].tenderType      | LOYALTY          |
            | tenders[0].amount          | 0.76             |
            | tenders[1].tenderType      | CASH             |
            | tenders[1].amount          | 0.00             |
            | orderTotals[2].type        | ITEM_TOTAL       |
            | orderTotals[2].value       | 0.99             |
            | items[0].itemName          | Sale Item A      |
            | items[0].unitPrice         | 0.99             |
            | items[1].itemName          | Fuel             |
            | items[1].unitPrice         | 1.00             |
            | items[1].quantity.unitType | GALLON_US_LIQUID |
            | items[1].quantity.units    | 0.00             |


    @fast
    Scenario: The cashier tenders the prepay partially with loyalty points, the loyalty tender appears in the transaction,
              the balance remains to be covered by other tender.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        # Promotion Prepay tenders limit is set to 2
        And the POS option 5127 is set to 2
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the prepay of the fuel grade premium with price 50.00 at pump id 1 is present in the transaction
        When the cashier totals the transaction using cash tender
        Then a tender Premium Tender with amount 20.00 is in the current transaction
        And a tender Premium Tender with amount 20.00 is in the virtual receipt
        And the POS displays Ask tender amount cash frame
        And the transaction's balance is 30.00


    @fast
    Scenario Outline: The cashier tenders the prepay partially with loyalty points and other tender, both tenders appear in the transaction.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        # Promotion Prepay tenders limit is set to 2
        And the POS option 5127 is set to 2
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the prepay of the fuel grade premium with price 50.00 at pump id 1 is present in the transaction
        And a loyalty tender Premium Tender with value of 20.00 is present in the transaction after subtotal
        When the cashier tenders the transaction with hotkey exact_dollar in <tender_type>
        Then a tender Premium Tender with amount 20.00 is in the previous transaction
        And a tender <tender_type> with amount 30.00 is in the previous transaction
        And the transaction is finalized

        Examples:
        | tender_type      |
        | Cash             |
        | Check            |
        | Gift certificate |
        | Manual imprint   |


    @fast
    Scenario: The cashier tenders the prepay partially with loyalty points and cash, refund prepaid fuel, verify the FinalizePromotions request is sent with correct values.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        # Promotion Prepay tenders limit is set to 2
        And the POS option 5127 is set to 2
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the prepay of the fuel grade premium with price 50.00 at pump id 1 is present in the transaction
        And a loyalty tender Premium Tender with value of 20.00 is present in the transaction after subtotal
        And the cashier tendered transaction with cash
        When the cashier cancels and refunds the fuel from pump 1
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                                  | value        |
            | orderLevelAdjustments[0].adjustmentValue | 0.00         |
            | tenders[0].tenderType                    | LOYALTY      |
            | tenders[0].amount                        | 0.00         |
            | tenders[1].tenderType                    | CASH         |
            | tenders[1].amount                        | 30.00        |
            | tenders[2].tenderType                    | CASH         |
            | tenders[2].amount                        | -30.00       |


    @fast
    Scenario: The cashier tenders the prepay partially with loyalty points and credit, refund prepaid fuel, verify the FinalizePromotions request is sent with correct values.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the prepay of the fuel grade premium with price 50.00 at pump id 1 is present in the transaction
        And a loyalty tender Premium Tender with value of 20.00 is present in the transaction after subtotal
        And the cashier tendered transaction with credit
        When the cashier cancels and refunds the fuel from pump 1
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                                  | value        |
            | orderLevelAdjustments[0].adjustmentValue | 0.00         |
            | tenders[0].tenderType                    | LOYALTY      |
            | tenders[0].amount                        | 0.00         |
            | tenders[1].tenderType                    | CREDIT_DEBIT |
            | tenders[1].amount                        | 0.00         |


    @fast
    Scenario: The cashier tenders the prepay partially with loyalty points and credit, dispense the fuel for the amount smaller than the loyalty tender,
              verify the FinalizePromotions request is sent with correct values.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        # Promotion Prepay tenders limit is set to 2
        And the POS option 5127 is set to 2
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the prepay of the fuel grade premium with price 30.00 at pump id 1 is present in the transaction
        And a loyalty tender Premium Tender with value of 20.00 is present in the transaction after subtotal
        And the cashier tendered transaction with credit
        When the customer dispensed regular for 5.00 price at pump 1
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                                  | value        |
            | orderLevelAdjustments[0].adjustmentValue | 5.00         |
            | tenders[0].tenderType                    | LOYALTY      |
            | tenders[0].amount                        | 5.00         |
            | tenders[1].tenderType                    | CREDIT_DEBIT |
            | tenders[1].amount                        | 0.00         |


    @fast
    Scenario: The cashier tenders the prepay partially with loyalty points, cash and credit, dispense
              the fuel over the amount paid by loyalty points and refund the rest, verify the FinalizePromotions request is sent with correct values.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        # Promotion Prepay tenders limit is set to 3
        And the POS option 5127 is set to 3
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the prepay of the fuel grade premium with price 50.00 at pump id 1 is present in the transaction
        And a loyalty tender Premium Tender with value of 20.00 is present in the transaction after subtotal
        And the cashier tendered the transaction with 20.00 amount in cash
        And the cashier tendered the transaction with 10.00 amount in credit
        And the customer dispensed regular for 25.00 price at pump 1
        When the cashier refunds the fuel from pump 1
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                                  | value        |
            | orderLevelAdjustments[0].adjustmentValue | 20.00        |
            | tenders[0].tenderType                    | LOYALTY      |
            | tenders[0].amount                        | 20.00        |
            | tenders[1].tenderType                    | CASH         |
            | tenders[1].amount                        | 20.00        |
            | tenders[2].tenderType                    | CREDIT_DEBIT |
            | tenders[2].amount                        | 0.00         |
            | tenders[3].tenderType                    | CASH         |
            | tenders[3].amount                        | -15.00       |


    @fast
    Scenario: The cashier tenders the prepay partially with loyalty points, cash and credit, dispense
              all the fuel, verify the FinalizePromotions request is sent with correct values.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        # Promotion Prepay tenders limit is set to 3
        And the POS option 5127 is set to 3
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the prepay of the fuel grade premium with price 50.00 at pump id 1 is present in the transaction
        And a loyalty tender Premium Tender with value of 20.00 is present in the transaction after subtotal
        And the cashier tendered the transaction with 20.00 amount in cash
        And the cashier tendered the transaction with 10.00 amount in credit
        When the customer dispensed regular for 50.00 price at pump 1
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                                  | value        |
            | orderLevelAdjustments[0].adjustmentValue | 20.00        |
            | tenders[0].tenderType                    | LOYALTY      |
            | tenders[0].amount                        | 20.00        |
            | tenders[1].tenderType                    | CASH         |
            | tenders[1].amount                        | 20.00        |
            | tenders[2].tenderType                    | CREDIT_DEBIT |
            | tenders[2].amount                        | 10.00        |


    @fast
    Scenario: The cashier tenders the prepay partially with loyalty points, cash and credit, dispense
              the fuel under the amount paid by loyalty points and refund the rest, verify the FinalizePromotions request is sent with correct values.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        # Promotion Prepay tenders limit is set to 3
        And the POS option 5127 is set to 3
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And the prepay of the fuel grade premium with price 50.00 at pump id 1 is present in the transaction
        And a loyalty tender Premium Tender with value of 20.00 is present in the transaction after subtotal
        And the cashier tendered the transaction with 20.00 amount in cash
        And the cashier tendered the transaction with 10.00 amount in credit
        And the customer dispensed regular for 10.00 price at pump 1
        When the cashier refunds the fuel from pump 1
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                                  | value        |
            | orderLevelAdjustments[0].adjustmentValue | 10.00        |
            | tenders[0].tenderType                    | LOYALTY      |
            | tenders[0].amount                        | 10.00        |
            | tenders[1].tenderType                    | CASH         |
            | tenders[1].amount                        | 20.00        |
            | tenders[2].tenderType                    | CREDIT_DEBIT |
            | tenders[2].amount                        | 0.00         |
            | tenders[3].tenderType                    | CASH         |
            | tenders[3].amount                        | -20.00       |


    @fast
    Scenario: The cashier tenders the transaction with prepay and dry stock partially with loyalty points, cash and credit, dispense
              the fuel under the amount paid by loyalty points,  verify the FinalizePromotions request is sent with correct values
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        # Promotion Prepay tenders limit is set to 3
        And the POS option 5127 is set to 3
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 001 is present in the transaction 3 times
        And the prepay of the fuel grade premium with price 50.00 at pump id 1 is present in the transaction
        And a loyalty tender Premium Tender with value of 20.00 is present in the transaction after subtotal
        And the cashier tendered the transaction with 20.00 amount in cash
        And the cashier tendered transaction with credit
        And the customer dispensed regular for 10.00 price at pump 1
        When the cashier refunds the fuel from pump 1
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                                  | value        |
            | orderLevelAdjustments[0].adjustmentValue | 16.73        |
            | tenders[0].tenderType                    | LOYALTY      |
            | tenders[0].amount                        | 16.73        |
            | tenders[1].tenderType                    | CASH         |
            | tenders[1].amount                        | 20.00        |
            | tenders[2].tenderType                    | CREDIT_DEBIT |
            | tenders[2].amount                        | 0.00         |
            | tenders[3].tenderType                    | CASH         |
            | tenders[3].amount                        | -20.00       |


    @fast
    Scenario: Grade selection is enabled. Add Rest in gas item to the transaction, select tender button,
              the POS sends GetPromotion request to PES with correct elements.
        # Set Display Rest in Gas button to Yes
        Given the POS option 5130 is set to 1
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 001 is present in the transaction
        And the cashier selected a Premium grade prepay at pump 1
        And a prepay item Rest in gas:Prem with price 0.00 is in the current transaction
        When the cashier presses the cash tender button
        Then the POS sends a GetPromotions request to PES with following elements
            | element_name                             | value            |
            | items[1].discountable                    | True             |
            | items[1].itemName                        | Premium          |
            | items[1].unitPrice                       | 4.00             |
            | items[1].itemName                        | Premium          |
            | items[1].quantity.unitType               | GALLON_US_LIQUID |
            | items[1].quantity.units                  | 0                |


    @fast
    Scenario Outline: Grade selection is enabled. Add Rest in gas item to the transaction, tender the transaction with loyalty points with amount larger/lower than balance,
                      add cash tender, the pump is prepaid with extra amount.
        # Set Display Rest in Gas button to Yes
        Given the POS option 5130 is set to 1
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value   | discount_level | promotion_id             | unit_type              | is_apply_as_tender |
            | 004            | Premium Tender       | <discount_value> | transaction    | premium tender           | GENERAL_SALES_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 001 is present in the transaction
        And the cashier selected a Premium grade prepay at pump 1
        And a prepay item Rest in gas:Prem with price 0.00 is in the current transaction
        And a loyalty tender Premium Tender with value of <discount_value> is present in the transaction after subtotal
        When the cashier tenders the transaction with <type> <tender_value> in cash
        Then the transaction is finalized
        And a pump 1 is authorized with a price of <prepaid_amount>

        Examples:
        | discount_value | prepaid_amount | type    | tender_value |
        | 20.00          | 17.66          | hotkey  | exact_dollar |
        | 20.00          | 27.66          | amount  | 10.00        |
        | 1.00           | 8.66           | amount  | 10.00        |


    @fast
    Scenario Outline: Grade selection is disabled. Add Rest in gas item to the transaction, tender the transaction with loyalty points with amount larger/lower than balance,
                      add cash tender, the pump is prepaid with extra amount.
        # Set Display Rest in Gas button to Yes
        Given the POS option 5130 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value   | discount_level | promotion_id             | unit_type              | is_apply_as_tender |
            | 004            | Premium Tender       | <discount_value> | transaction    | premium tender           | GENERAL_SALES_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 001 is present in the transaction
        And the cashier pressed the prepay button for pump 1
        And a prepay item Rest in gas with price 0.00 is in the current transaction
        And a loyalty tender Premium Tender with value of <discount_value> is present in the transaction after subtotal
        When the cashier tenders the transaction with <type> <tender_value> in cash
        Then the transaction is finalized
        And a pump 1 is authorized with a price of <prepaid_amount>

        Examples:
        | discount_value | prepaid_amount | type    | tender_value |
        | 20.00          | 17.66          | hotkey  | exact_dollar |
        | 20.00          | 27.66          | amount  | 10.00        |
        | 1.00           | 8.66           | amount  | 10.00        |


    @fast
    Scenario: Grade selection is disabled. Add Rest in gas item to the transaction, tender the transaction with loyalty points having lower amount than balance,
              add cash tender with amount equal to balance, the POS displays Cancel Rest in gas item frame.
        # Set Display Rest in Gas button to Yes
        Given the POS option 5130 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id             | unit_type              | is_apply_as_tender |
            | 004            | Premium Tender       | 2.00           | transaction    | premium tender           | GENERAL_SALES_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 001 is present in the transaction
        And the cashier pressed the prepay button for pump 1
        And a prepay item Rest in gas with price 0.00 is in the current transaction
        And a loyalty tender Premium Tender with value of 2.00 is present in the transaction after subtotal
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS displays Cancel Rest in gas prompt


    @fast
    Scenario: Grade selection is enabled. Add Rest in gas item to the transaction, tender the transaction with loyalty points having lower amount than balance,
              add cash tender with amount equal to balance, the POS displays Cancel Rest in gas item frame.
        # Set Display Rest in Gas button to Yes
        Given the POS option 5130 is set to 1
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id             | unit_type              | is_apply_as_tender |
            | 004            | Premium Tender       | 2.00           | transaction    | premium tender           | GENERAL_SALES_QUANTITY | True               |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 001 is present in the transaction
        And the cashier selected a Premium grade prepay at pump 1
        And a prepay item Rest in gas:Prem with price 0.00 is in the current transaction
        And a loyalty tender Premium Tender with value of 2.00 is present in the transaction after subtotal
        And the POS displays Cancel Rest in gas prompt after transaction is tendered
        When the cashier selects Yes button
        Then the POS displays Ask tender amount cash frame
        And a prepay item Rest in gas:Prem with price 0.00 is not in the current transaction


    @fast
    Scenario: Grade selection is enabled. Add dry stock items to the transaction, tender transaction with loyalty points, go back and add Rest in gas item,
              loyalty tender value is getting updated to maximum value of the discount, the pump is prepaid with extra amount.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        # Set Display Rest in Gas button to Yes
        And the POS option 5130 is set to 1
        # Allow transaction modification after loyalty authorization is set to Yes
        And the POS option 5275 is set to 1
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id             | unit_type              | is_apply_as_tender |
            | 400            | Loyalty Tender       | 30.00          | transaction    | loyalty tender           | SIMPLE_QUANTITY        | True               |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 001 is present in the transaction
        And a loyalty tender Loyalty Tender with value of 2.34 is present in the transaction after subtotal
        And the cashier selected a Regular grade prepay at pump 1
        And a prepay item Rest in gas:Regu with price 0.00 is in the current transaction
        And a loyalty tender Loyalty Tender with value of 30.00 is present in the transaction after subtotal
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the transaction is finalized
        And a pump 1 is authorized with a price of 27.66


    @fast
    Scenario: Grade selection is disabled. Add dry stock items to the transaction, tender transaction with loyalty points, go back and add Rest in gas item,
              loyalty tender value is getting updated to maximum value of the discount, the pump is prepaid with extra amount.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        # Set Display Rest in Gas button to Yes
        And the POS option 5130 is set to 1
        # Allow transaction modification after loyalty authorization is set to Yes
        And the POS option 5275 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id             | unit_type              | is_apply_as_tender |
            | 400            | Loyalty Tender       | 30.00          | transaction    | loyalty tender           | SIMPLE_QUANTITY        | True               |
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 001 is present in the transaction
        And a loyalty tender Loyalty Tender with value of 2.34 is present in the transaction after subtotal
        And the cashier pressed the prepay button for pump 1
        And a prepay item Rest in gas with price 0.00 is in the current transaction
        And a loyalty tender Loyalty Tender with value of 30.00 is present in the transaction after subtotal
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the transaction is finalized
        And a pump 1 is authorized with a price of 27.66


    @fast
    Scenario: Grade selection is enabled. Add Rest in gas item to the transaction, tender the transaction with loyalty points with amount larger than balance,
              the pump is prepaid with extra amount. Dispense the fuel, verify the FinalizePromotions request is sent to PES with correct elements.
        # Set Display Rest in Gas button to Yes
        Given the POS option 5130 is set to 1
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 001 is present in the transaction
        And the cashier selected a Premium grade prepay at pump 1
        And a prepay item Rest in gas:Prem with price 0.00 is in the current transaction
        And a loyalty tender Premium Tender with value of 20.00 is present in the transaction after subtotal
        And the cashier tendered transaction with cash
        When the customer dispensed premium for 17.96 price at pump 1
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element_name                             | value            |
            | items[1].discountable                    | True             |
            | items[1].itemName                        | Premium          |
            | items[1].unitPrice                       | 3.7              |
            | items[1].quantity.unitType               | GALLON_US_LIQUID |
            | items[1].quantity.units                  | 4.854            |
            | orderLevelAdjustments[0].adjustmentValue | 20.00            |
            | tenders[0].tenderType                    | LOYALTY          |
            | tenders[0].amount                        | 20.00            |
            | tenders[1].tenderType                    | CASH             |
            | tenders[1].amount                        | 0.00             |


    @fast
    Scenario: Grade selection is disabled. Add Rest in gas item to the transaction, tender the transaction with loyalty points with amount larger than balance,
              the pump is prepaid with extra amount. Dispense the fuel, verify the FinalizePromotions request is sent to PES with correct elements.
        # Set Display Rest in Gas button to Yes
        Given the POS option 5130 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the POS is in a ready to sell state
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 001 is present in the transaction
        And the cashier pressed the prepay button for pump 1
        And a prepay item Rest in gas with price 0.00 is in the current transaction
        And a loyalty tender Premium Tender with value of 20.00 is present in the transaction after subtotal
        And the cashier tendered transaction with cash
        When the customer dispensed premium for 17.96 price at pump 1
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element_name                             | value            |
            | items[1].discountable                    | True             |
            | items[1].itemName                        | Premium          |
            | items[1].unitPrice                       | 3.7              |
            | items[1].quantity.unitType               | GALLON_US_LIQUID |
            | items[1].quantity.units                  | 4.854            |
            | orderLevelAdjustments[0].adjustmentValue | 20.00            |
            | tenders[0].tenderType                    | LOYALTY          |
            | tenders[0].amount                        | 20.00            |
            | tenders[1].tenderType                    | CASH             |
            | tenders[1].amount                        | 0.00             |


    @positive @fast
    Scenario Outline: Prepay is completed, PES card credentials are stored to and retrieved from fuel interface
        Given the POS is in a ready to sell state
        And a PES loyalty card <pes_card> is present in the transaction
        And the prepay of the fuel grade regular with price <prepaid_amount> at pump id <pump_id> is present in the transaction
        And the transaction is tendered
        When the customer dispensed regular for <prepaid_amount> price at pump <pump_id>
        Then the transaction is finalized
        And the PES card <pes_card> is stored at pump <pump_id>
        And the POS sends a FinalizePromotions request to PES with following elements
            | element_name              | value      |
            | consumerIds[0].identifier | <pes_card> |

        Examples:
            | pes_card         | prepaid_amount | pump_id |
            | 3104174102936582 | 5.00           | 1       |


    @positive @fast
    Scenario Outline: Prepay is transferred to another pump and completed, PES card credentials are stored to and retrieved from fuel interface
        Given the POS is in a ready to sell state
        And a PES loyalty card <pes_card> is present in the transaction
        And the cashier prepaid pump <pump_original> for price <prepaid_amount> of premium and transferred it to pump <pump_transferred>
        When the customer dispensed regular for <prepaid_amount> price at pump <pump_transferred>
        Then the transaction is finalized
        And the PES card <pes_card> is stored at pump <pump_transferred>
        And the POS sends a FinalizePromotions request to PES with following elements
            | element_name              | value      |
            | consumerIds[0].identifier | <pes_card> |

        Examples:
            | pes_card         | prepaid_amount | pump_original | pump_transferred |
            | 3104174102936582 | 10.00          | 1             | 2                |


    @fast
    Scenario: Add restricted item to the transaction with prepay, the loyalty tender has restriction level higher than
              the restricted item, only prepaid fuel is tendered by loyalty points.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the pricebook contains PES loyalty tender with restriction level 3
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id             | unit_type              | is_apply_as_tender |
            | 400            | Loyalty Tender       | 30.00          | transaction    | loyalty tender           | SIMPLE_QUANTITY        | True               |
        And the pricebook contains retail items
            | barcode      | description     | price  | tender_itemizer_rank |
            | 011111222220 | Restricted Item | 1.50   | 2                    |
        And the POS is in a ready to sell state
        And an item with barcode 011111222220 is present in the transaction
        And the prepay of the fuel grade premium with price 10.00 at pump id 1 is present in the transaction
        When the cashier totals the transaction using cash tender
        Then an item Restricted Item with price 1.50 is in the current transaction
        And an item Restricted Item with price 1.50 is in the virtual receipt
        And a tender Loyalty Tender with amount 10.00 is in the current transaction
        And a tender Loyalty Tender with amount 10.00 is in the virtual receipt
        And the transaction's balance is 1.61


    @fast
    Scenario: Add restricted item to the transaction with prepay, the loyalty tender has restriction level higher than
              the restricted item, only prepaid fuel is tendered by loyalty points, restricted item is tendered by cash.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the pricebook contains PES loyalty tender with restriction level 3
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id   | unit_type       | is_apply_as_tender |
            | 400            | Loyalty Tender       | 30.00          | transaction    | loyalty tender | SIMPLE_QUANTITY | True               |
        And the pricebook contains retail items
        | barcode      | description     | price  | tender_itemizer_rank |
        | 011111222220 | Restricted Item | 1.50   | 2                    |
        And the POS is in a ready to sell state
        And an item with barcode 011111222220 is present in the transaction
        And the prepay of the fuel grade premium with price 10.00 at pump id 1 is present in the transaction
        And a loyalty tender Loyalty Tender with value of 10.00 is present in the transaction after subtotal
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then an item Restricted Item with price 1.50 and type 1 is in the previous transaction
        And a tender Loyalty Tender with amount 10.00 is in the previous transaction
        And a tender Cash with amount 1.61 is in the previous transaction
        And the transaction is finalized
        And a pump 1 is authorized with a price of 10.00


    @fast
    Scenario: The cashier tenders the transaction with prepay and restricted item, partially with loyalty points and cash,
              refund prepaid fuel, verify the FinalizePromotions request is sent with correct values.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the pricebook contains PES loyalty tender with restriction level 3
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id   | unit_type       | is_apply_as_tender |
            | 400            | Loyalty Tender       | 30.00          | transaction    | loyalty tender | SIMPLE_QUANTITY | True               |
        And the pricebook contains retail items
        | barcode      | description     | price  | tender_itemizer_rank |
        | 011111222220 | Restricted Item | 1.50   | 2                    |
        And the POS is in a ready to sell state
        And an item with barcode 011111222220 is present in the transaction
        And the prepay of the fuel grade premium with price 10.00 at pump id 1 is present in the transaction
        And the cashier tendered transaction with cash
        When the cashier cancels and refunds the fuel from pump 1
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                    | value        |
            | checkDetails.pumpId        | 1                |
            | transactionType            | PREPAY           |
            | tenders[0].tenderType      | LOYALTY          |
            | tenders[0].amount          | 0.00             |
            | tenders[1].tenderType      | CASH             |
            | tenders[1].amount          | 1.61             |
            | items[0].itemName          | Restricted Item  |
            | items[0].unitPrice         | 1.50             |
            | items[1].itemName          | Premium          |
            | items[1].unitPrice         | 4.00             |
            | items[1].quantity.unitType | GALLON_US_LIQUID |
            | items[1].quantity.units    | 0.00             |


    @manual
    # POS option 900004 does not work, will be resolved in https://jira.ncr.com/browse/RPOS-31824.
    Scenario: POS option Fuel and Prepay item tender restriction ranking is set to 2. Add non-restricted item to the transaction with restricted prepay,
              the loyalty tender has restriction level higher than the restricted prepay, only non-restricted item is tendered by loyalty points.
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        # Fuel and Prepay item tender restriction ranking is set to 2
        And the POS option 900004 is set to 2
        And the pricebook contains PES loyalty tender with restriction level 3
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id             | unit_type              | is_apply_as_tender |
            | 400            | Loyalty Tender       | 30.00          | transaction    | loyalty tender           | SIMPLE_QUANTITY        | True               |
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the prepay of the fuel grade premium with price 10.00 at pump id 1 is present in the transaction
        When the cashier totals the transaction using cash tender
        Then a tender Loyalty Tender with amount 1.06 is in the current transaction
        And a tender Loyalty Tender with amount 1.06 is in the virtual receipt
        And the transaction's balance is 10.00
