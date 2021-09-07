@pos @pes
Feature: Promotion Execution Service Requests
    This feature file focuses on validating the PES request content sent by POS.

    Background: POS is configured for PES feature
        Given the POS has essential configuration
        And the EPS simulator has essential configuration
        And the POS is configured to communicate with PES
        # Cloud Loyalty Interface is set to PES
        And the POS option 5284 is set to 1
        And the nep-server has default configuration
        # Default Loyalty Discount Id is set to PES_basic
        And the POS parameter 120 is set to PES_basic
        # Promotion Execution Service Allow partial discounts is set to Yes
        And the POS option 5278 is set to 1
        And the following cashiers are configured
            | first_name | last_name | security_role | PIN  |
            | cashier    | 1234      | cashier       | 1234 |
            | manager    | 2345      | manager       | 2345 |
        And the POS has following discounts configured
            | reduction_id | description | price | external_id |
            | 1            | PES loyalty | 0.00  | PES_basic   |
        And the pricebook contains retail items
            | description     | price | item_id | barcode | credit_category | category_code |
            | Large Fries     | 2.19  | 111     | 001     | 2010            | 400           |
            | Generic Item    | 3.99  | 333     | 003     | 2000            | 400           |
            ###### Defaul Station Service
            | Refresher       | 0.55  | 222     | 002     | 1400            | 100           |
            | Generic Service | 3.99  | 444     | 004     | 1001            | 100           |
            | Carwash         | 3.33  | 666     | 006     | 1000            | 102           |
            | Carwash Extra   | 20.25 | 999     | 009     | 1000            | 102           |
        # Add configured 'PES_tender' loyalty tender record
        And the pricebook contains PES loyalty tender
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id            | is_apply_as_tender |
            | 400            | Miscellaneous        | 0.30           | item           | 30cents off merchandise | False              |
            | 100            | Refresher            | 0.25           | item           | 25cents off accessories | False              |
            | 102            | Carwash (102)        | 10.25          | item           | 10.25 off carwash items | False              |
            | 102, 100       | Car+Refresher        | 0.63           | transaction    | 20.45 off a combo       | False              |
            | 102, 400       | Carwash+fries        | 10.00          | transaction    | 10.00 off a combo       | True               |
        And the POS recognizes following PES cards
            | card_definition_id | card_role  | card_name | barcode_range_from | card_definition_group_id |
            | 70000001142        | 3          | PES card  | 3104174102936582   | 70000010042              |


    @fast
    Scenario: Check that the PES received a message with specific elements from POS
        Given the POS is in a ready to sell state
        When the cashier scans a barcode 001
        Then the POS sends a GetPromotions request to PES with following elements
            | element              | value        |
            | orderTotals[0].value | 2.34         |
            | orderTotals[0].type  | TAX_INCLUDED |
            | orderTotals[1].value | 2.19         |
            | orderTotals[1].type  | TAX_EXCLUDED |
            | orderTotals[2].value | 2.19         |
            | orderTotals[2].type  | ITEM_TOTAL   |


    @fast
    Scenario Outline: POS sends GetPromotions request to PES with correct categoryCode/itemCode
        Given the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then the POS sends a GetPromotions request to PES with following elements
            | element               | value           |
            | items[0].categoryCode | <category_code> |
            | items[0].itemCode     | <item_code>     |

        Examples:
        | barcode | category_code | item_code |
        | 001     | 400           | 001       |
        | 002     | 100           | 002       |


    @fast
    Scenario: Add an item to the transaction, POS sends GetPromotions request to PES with correct totals flag
        Given the POS is in a ready to sell state
        When the cashier scans a barcode 001
        Then the POS sends a GetPromotions request to PES with following elements
            | element | value |
            | totals  | False |


    @fast
    Scenario Outline: POS sends FinalizePromotions request to PES with correct categoryCode/itemCode
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element               | value           |
            | items[0].categoryCode | <category_code> |
            | items[0].itemCode     | <item_code>     |

        Examples:
        | barcode | category_code | item_code |
        | 001     | 400           | 001       |
        | 002     | 100           | 002       |


    @fast
    Scenario Outline: POS sends FinalizePromotions request to PES with tender details containing correct card information
        Given the EPS simulator uses <configuration> card configuration
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then the FinalizePromotions request contains <name> card with prefix <card_prefix>

        Examples:
            | configuration | name        | card_prefix |
            | default       | DefaultCard | 123456      |
            | VISA          | VISA        | 987654      |


    @fast
    Scenario Outline: POS sends GetPromotions request to PES with default categoryCode
                    for items with not defined credit_category conversion into NACS code
        Given the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then the POS sends a GetPromotions request to PES with following elements
            | element               | value           |
            | items[0].categoryCode | <category_code> |

        Examples:
        | barcode | category_code |
        | 003     | 400           |
        | 004     | 100           |


    @fast
    Scenario Outline: Add an item with FamilyCode parameter set, POS sends GetPromotions request to PES with correct familyCode element value
        Given the pricebook contains retail items
            | description  | price | barcode         | item_id      | modifier1_id   | family_code |
            | Sale Item A  | 0.99  | 099999999990    | 990000000002 | 990000000007   | 400         |
        And the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then the POS sends a GetPromotions request to PES with following elements
            | element               | value           |
            | items[0].familyCode   | <family_code>   |

        Examples:
        | barcode          | family_code   |
        | 099999999990     | 400           |


    @fast
    Scenario Outline: Add an item with FamilyCode parameter set, POS sends FinalizePromotions request to PES with correct familyCode element value
        Given the pricebook contains retail items
            | description  | price | barcode         | item_id      | modifier1_id | family_code  |
            | Sale Item A  | 0.99  | 099999999990    | 990000000002 | 990000000007 | 400          |
        And the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        And the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element               | value           |
            | items[0].familyCode   | <family_code>   |

        Examples:
        | barcode          | family_code   |
        | 099999999990     | 400           |


    @fast
    Scenario: POS sends GetPromotion request to PES with correct itemCode/categoryCode for prepaid fuel item
        Given the POS is in a ready to sell state
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id             | unit_type              | is_apply_as_tender |
            | 1              | Regular Fuel         | 0.25           | item           | 25cents off regular fuel | GENERAL_SALES_QUANTITY | False              |
        When the cashier prepays the fuel for price 10.00 at pump id 1
        Then an item Prepay Fuel with price 10.00 is in the virtual receipt
        And the POS sends a GetPromotions request to PES with following elements
            | element               | value |
            | items[0].categoryCode | 019   |
            | items[0].itemCode     | 0     |


    @fast
    Scenario: POS sends GetPromotion request to PES with correct itemCode/categoryCode for postpaid fuel item
        Given the POS is in a ready to sell state
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id             | unit_type              | is_apply_as_tender |
            | 1              | Regular Fuel         | 0.25           | item           | 25cents off regular fuel | GENERAL_SALES_QUANTITY | False              |
        And the customer dispensed regular for 10.00 price at pump 2
        When the cashier adds a postpay from pump 2 to the transaction
        Then a fuel item 5.000G Regular with price 10.00 and prefix P2 is in the virtual receipt
        And the POS sends a GetPromotions request to PES with following elements
            | element               | value |
            | items[0].categoryCode | 001   |
            | items[0].itemCode     | 0     |


    @fast
    Scenario: POS sends FinalizePromotions request to PES with an element orderTotals with correct subelement values
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element              | value        |
            | orderTotals[0].value | 2.34         |
            | orderTotals[0].type  | TAX_INCLUDED |
            | orderTotals[1].value | 2.19         |
            | orderTotals[1].type  | TAX_EXCLUDED |
            | orderTotals[2].value | 2.19         |
            | orderTotals[2].type  | ITEM_TOTAL   |


    @fast
    Scenario: POS sends GetPromotions request to PES with correct element values
        Given the POS is in a ready to sell state
        When the cashier scans a barcode 001
        Then the POS sends a GetPromotions request to PES with following elements
            | element_name                          | value       |
            | items[0].sequenceId                   | 1           |
            | items[0].categoryCode                 | 400         |
            | items[0].itemName                     | Large Fries |
            | items[0].unitPrice                    | 2.19        |
            | items[0].discountable                 | True        |
            | items[0].considerForOrderLevelRewards | True        |


    @fast
    Scenario: POS sends FinalizePromotions request to PES with correct element values
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element_name                          | value       |
            | items[0].sequenceId                   | 1           |
            | items[0].categoryCode                 | 400         |
            | items[0].itemName                     | Large Fries |
            | items[0].unitPrice                    | 2.19        |
            | items[0].discountable                 | True        |
            | items[0].considerForOrderLevelRewards | True        |


    @fast
    Scenario: POS sends GetPromotions request to PES with correct checkDetails element
        Given the POS is in a ready to sell state
        When the cashier scans a barcode 001
        Then the POS sends a GetPromotions request to PES with following elements
            | element                     | value       |
            | checkDetails.trainingMode   | False       |
            | checkDetails.cashierID      | 70000000014 |
        And following fields are presented in the GetPromotions PES request
            | element                     |
            | checkDetails.checkId        |
            | checkDetails.dateOfBusiness |


    @fast
    Scenario: POS sends FinalizePromotions request to PES with an element checkDetails with correct values
        Given the POS is in a ready to sell state
        When the cashier scans a barcode 001
        And the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                     | value       |
            | checkDetails.trainingMode   | False       |
            | checkDetails.cashierID      | 70000000014 |
        And following fields are presented in the FinalizePromotions PES request
            | element                     |
            | checkDetails.checkId        |
            | checkDetails.dateOfBusiness |


    @fast
    Scenario: POS sends GetPromotions request to PES with correct payment element
        Given the POS is in a ready to sell state
        When the cashier scans a barcode 001
        Then the POS sends a GetPromotions request to PES with following elements
            | element | value         |
            | payment | NOT_COLLECTED |


    @fast
    Scenario: POS sends FinalizePromotions request to PES with correct payment element
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element | value     |
            | payment | COLLECTED |


    @fast
    Scenario Outline: POS sends Get Promotions request to PES with NOT_COLLECTED payment element after partial tender.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        When the cashier tenders the transaction with amount 0.5 in cash
        Then the POS sends a GetPromotions request to PES with following elements
            | element | value         |
            | payment | NOT_COLLECTED |

        Examples:
        | barcode | category_code |
        | 001     | 400           |
        | 002     | 100           |


    @fast
    Scenario: Configure POS to send Get requests to PES only after Subtotal. Add an item to the transaction,
                      the POS does not send GetPromotions request to PES
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        Given the POS option 5277 is set to 1
        And the POS is in a ready to sell state
        When the cashier scans a barcode 001
        Then the POS sends no GetPromotion requests after last action


    @fast
    Scenario: The POS sends GetPromotions request after subtotalling the transaction.
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        Given the POS option 5277 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        When the cashier presses the cash tender button
        Then the POS sends a GetPromotions request to PES with following elements
            | element_name | value |
            | totals       | True  |


    @fast
    Scenario: The POS sends GetPromotions only once during subtotalling and adding a partial tender to the transaction.
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        Given the POS option 5277 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        When the cashier tenders the transaction with amount 1.00 in cash
        Then the POS sends a GetPromotions request to PES with following elements
            | element_name | value |
            | totals       | True  |


    @fast
    Scenario: The POS does not send a GetPromotions request on subtotalling after a partial tender, when no change was made to the transaction
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the transaction is tendered with 1.00 in cash
        When the cashier presses the cash tender button
        Then the POS sends no GetPromotion requests after last action


    @fast
    Scenario Outline: Add an item to the transaction after partial tender, loyalty card is not in the transaction,
                      the POS sends a GetPromotions request on subtotalling.
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        Given the POS option 5277 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode <barcode_1> is present in the transaction
        And the transaction is tendered with 1.00 in cash
        And an item with barcode <barcode_2> is present in the transaction
        When the cashier presses the cash tender button
        Then the POS sends a GetPromotions request to PES with following elements
        | element_name      | value       |
        | items[0].itemName | Large Fries |
        | items[1].itemName | Refresher   |

        Examples:
        | barcode_1 | item_name_1 | barcode_2 | item_name_2 |
        | 001       | Large Fries | 002       | Refresher   |


    @fast
    Scenario Outline: Add a loyalty card to the transaction after partial tender, the POS sends a GetPromotions request on subtotalling.
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        Given the POS option 5277 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And the transaction is tendered with 1.00 in cash
        And a PES loyalty card <card_number> is present in the transaction
        When the cashier presses the cash tender button
        Then the POS sends a GetPromotions request to PES with following elements
        | element_name       | value       |
        | items[-1].itemName | Large Fries |

        Examples:
        | barcode | item_name   | card_number      |
        | 001     | Large Fries | 3104174102936582 |


    @fast
    Scenario Outline: The POS sends VoidPromotions request after voiding transaction, when GetPromotions request was sent after adding an item.
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        When the manager voids the transaction with <manager_pin> pin and reason <reason>
        Then the POS sends VoidPromotions request to PES after last action
        And the POS displays main menu frame
        And no transaction is in progress

        Examples:
        | manager_pin | reason                    |
        | 2345        | Cancel Transaction Reason |


    @fast
    Scenario: The POS sends VoidPromotions request after storing transaction, when GetPromotions request was sent after adding an item.
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        When the cashier stores the transaction
        Then the POS sends VoidPromotions request to PES after last action
        And the POS displays main menu frame
        And no transaction is in progress


    @fast
    Scenario Outline: The POS sends FinalizePromotions request to PES with an element appliedRewards with correct values.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                           | value          |
            | appliedRewards[0].amount          | <amount>       |
            | appliedRewards[0].promotionId     | <promotion_id> |
            | appliedRewards[0].redemptionCount | 1              |

        Examples:
        | barcode | amount | promotion_id            |
        | 001     | 0.3    | 30cents off merchandise |
        | 004     | 0.25   | 25cents off accessories |


    @fast
    Scenario: Tender a transaction while server is offline, the POS resends FinalizePromotions request once the server is online again.
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the nep-server is offline
        And the transaction is tendered
        And the POS displays main menu frame
        When the nep-server becomes online
        Then the POS sends FinalizePromotions request to PES after last action


    @fast
    Scenario: Void a transaction while server is offline, the POS resends VoidPromotions request once the server is online again.
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the nep-server is offline
        And the transaction was voided by manager with pin 2345 for a reason Cancel Transaction Reason
        And the POS displays main menu frame
        When the nep-server becomes online
        Then the POS sends VoidPromotions request to PES after last action


    @slow
    Scenario: Tender a transaction while server is offline, POS is rebooted, the POS resends FinalizePromotions request after reboot once the server is online again.
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the nep-server is offline
        And the transaction is tendered
        And the POS has rebooted
        And the POS is set to ready state
        When the nep-server becomes online
        Then the POS sends FinalizePromotions request to PES after last action


    @slow
    Scenario: Void a transaction while server is offline, POS is rebooted, the POS resends VoidPromotions request after reboot once the server is online again.
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the nep-server is offline
        And the transaction was voided by manager with pin 2345 for a reason Cancel Transaction Reason
        And the POS has rebooted
        And the POS is set to ready state
        When the nep-server becomes online
        Then the POS sends VoidPromotions request to PES after last action


    @fast
    Scenario: POS displays Loyalty offline alert when PES host goes offline.
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        Given the POS option 5277 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the nep-server is offline
        When the cashier totals the transaction using cash tender
        Then the POS displays the STM_PES_LOYALTY_OFFLINE_ALERT alert


    @fast
    Scenario: PES host is offline, POS removes Loyalty offline alert once the response from host is received.
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        Given the POS option 5277 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the nep-server is offline
        And the POS displays the STM_PES_LOYALTY_OFFLINE_ALERT alert after totaling the transaction
        And the nep-server is online
        And an item with barcode 001 is present in the transaction
        When the cashier totals the transaction using cash tender
        Then the POS does not display the STM_PES_LOYALTY_OFFLINE_ALERT alert


    @slow
    Scenario: Reboot the POS after a GetPromotions request was sent to PES, the POS sends a VoidPromotions request.
        Given the POS is in a ready to sell state
        And the POS sends a GetPromotions request to PES after scanning an item with barcode 001
        When the POS reboots
        Then the POS sends VoidPromotions request to PES after last action


    @slow
    Scenario Outline: Reboot the POS after a GetPromotions request for added postpaid item was sent to PES, the POS sends a VoidPromotions request.
        # Promotion Execution Service Get Mode is set to None
        Given the POS option 5277 is set to 0
        And the POS is in a ready to sell state
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id                   | unit_type              | is_apply_as_tender |
            | 001            | Regular Fuel         | 0.25           | item           | 25cents off regular fuel       | GENERAL_SALES_QUANTITY | False              |
            | 004            | Premium Fuel         | 0.50           | item           | 50cents off premium fuel       | GALLON_US_LIQUID       | False              |
        And a <grade> postpay fuel with 10.00 price on pump 2 is present in the transaction
        When the POS reboots
        Then the POS sends VoidPromotions request to PES after last action

        Examples:
        | grade   | fuel_item      | discount     | discount_value |
        | Premium | 2.500G Premium | Premium Fuel | 1.25           |
        | Regular | 5.000G Regular | Regular Fuel | 0.25           |


    @slow
    Scenario Outline: Reboot the POS after a GetPromotions request for postpaid item was sent to PES after subtotal, the POS sends a VoidPromotions request.
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        Given the POS option 5277 is set to 1
        And the POS is in a ready to sell state
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id                   | unit_type              | is_apply_as_tender |
            | 001            | Regular Fuel         | 0.25           | item           | 25cents off regular fuel       | GENERAL_SALES_QUANTITY | False              |
            | 004            | Premium Fuel         | 0.50           | item           | 50cents off premium fuel       | GALLON_US_LIQUID       | False              |
        And a <grade> postpay fuel with 10.00 price on pump 2 is present in the transaction
        And the transaction is totaled
        When the POS reboots
        Then the POS sends VoidPromotions request to PES after last action

        Examples:
        | grade   | fuel_item      | discount     | discount_value |
        | Premium | 2.500G Premium | Premium Fuel | 1.25           |
        | Regular | 5.000G Regular | Regular Fuel | 0.25           |


    @slow
    Scenario: Reboot the POS, the GetPromotions request was not sent to PES, the POS does not send VoidPromotions request.
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        Given the POS option 5277 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        When the POS reboots
        Then the POS sends no VoidPromotions requests after last action


    @fast
    Scenario: Create prepay, no grade is selected, the POS sends GetPromotions request with correct elements.
        # Set Fuel credit prepay method to Auth and Capture
        Given the POS option 1851 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the POS is in a ready to sell state
        When the cashier prepays the fuel for price 10.00 at pump id 1
        Then the POS sends a GetPromotions request to PES with following elements
            | element             | value    |
            | items[0].itemName   | Diesel   |
            | items[0].tenderType | CASH     |
            | items[1].itemName   | Diesel   |
            | items[1].tenderType | CREDIT   |
            | items[2].itemName   | Regular  |
            | items[2].tenderType | CASH     |
            | items[3].itemName   | Regular  |
            | items[3].tenderType | CREDIT   |
            | items[4].itemName   | Midgrade |
            | items[4].tenderType | CASH     |
            | items[5].itemName   | Midgrade |
            | items[5].tenderType | CREDIT   |
            | items[6].itemName   | Premium  |
            | items[6].tenderType | CASH     |
            | items[7].itemName   | Premium  |
            | items[7].tenderType | CREDIT   |


    @fast
    Scenario: Pump is prepaid for some amount, fuel is dispensed and refunded, the FinalizePromotions request only contains dispensed grade.
        # Set Fuel credit prepay method to Auth and Capture
        Given the POS option 1851 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the POS is in a ready to sell state
        And a prepay with price 5.00 on the pump 1 is present in the transaction
        And the transaction is tendered
        And the customer dispensed regular for 2.50 price at pump 1
        When the cashier refunds the fuel from pump 1
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element             | value         |
            | items[0].itemName   | Regular       |
        And the last FinalizePromotions request sent to PES has got 1 items in element items


    @fast
    Scenario Outline: Pump is prepaid with selected grade, the POS sends GetPromotions request containing selected grade.
        # Set Fuel credit prepay method to Auth and Capture
        Given the POS option 1851 is set to 1
        # Set Prepay Grade Select Type option as One Touch
        And the POS option 5124 is set to 1
        And the POS is in a ready to sell state
        When the cashier prepays the fuel grade <grade_name> for price 10.00 at pump id 1
        Then the POS sends a GetPromotions request to PES with following elements
            | element             | value         |
            | items[0].itemName   | <grade_name>  |
        And the last GetPromotions request sent to PES has got 2 items in element items

        Examples:
        | grade_name |
        | Regular    |
        | Premium    |


    @fast
    Scenario: Pay for prepaid fuel, the POS sends no FinalizePromotions requests to PES.
        # Set Fuel credit prepay method to Auth and Capture
        Given the POS option 1851 is set to 1
        # Set Prepay Grade Select Type option as One Touch
        And the POS option 5124 is set to 1
        And the POS is in a ready to sell state
        And the prepay of the fuel grade regular with price 10.00 at pump id 1 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS sends no FinalizePromotions requests after last action
        And the POS displays main menu frame


    @fast
    Scenario Outline: Add a postpaid fuel to the transaction, the POS sends GetPromotions request with the fuel to PES.
        Given the POS is in a ready to sell state
        And the customer dispensed <grade_name> for 10.00 price at pump 2
        When the cashier adds a postpay from pump 2 to the transaction
        Then the POS sends a GetPromotions request to PES with following elements
            | element             | value        |
            | items[0].itemName   | <grade_name> |

        Examples:
        | grade_name |
        | Regular    |


    @fast
    Scenario Outline: The POS does not send VoidPromotions request after voiding transaction, when no GetPromotions request was sent to PES.
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        Given the POS option 5277 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        When the manager voids the transaction with <manager_pin> pin and reason <reason>
        Then the POS sends no VoidPromotions requests after last action
        And the POS displays main menu frame
        And no transaction is in progress

        Examples:
        | manager_pin | reason                    |
        | 2345        | Cancel Transaction Reason |


    @fast
    Scenario Outline: The POS sends VoidPromotions request after voiding transaction, when GetPromotions request was sent by subtotal.
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        Given the POS option 5277 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the transaction is totaled
        When the manager voids the transaction with <manager_pin> pin and reason <reason>
        Then the POS sends VoidPromotions request to PES after last action
        And the POS displays main menu frame
        And no transaction is in progress

        Examples:
        | manager_pin | reason                    |
        | 2345        | Cancel Transaction Reason |


    @fast
    Scenario: The POS does not send VoidPromotions request after storing transaction, when no GetPromotions request was sent.
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        Given the POS option 5277 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        When the cashier stores the transaction
        Then the POS sends no VoidPromotions requests after last action
        And the POS displays main menu frame
        And no transaction is in progress


    @fast
    Scenario: The POS sends VoidPromotions request after storing transaction, when GetPromotions request was sent by subtotal.
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        Given the POS option 5277 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And the transaction is totaled
        When the cashier stores the transaction
        Then the POS sends VoidPromotions request to PES after last action
        And the POS displays main menu frame
        And no transaction is in progress


    @fast
    Scenario: The POS sends a GetPromotions request with aggregated applied reward after changed quantity
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And an item Large Fries with price 2.19 has changed quantity to 2
        When the cashier presses the cash tender button
        Then the POS displays Ask tender amount cash frame
        And the POS sends a GetPromotions request to PES with following elements
            | element                           | value                   |
            | appliedRewards[0].amount          | 0.3                     |
            | appliedRewards[0].promotionId     | 30cents off merchandise |
            | appliedRewards[0].redemptionCount | 2                       |


    @fast
    Scenario: The POS sends a GetPromotions request with non-aggregated applied reward after changed quantity
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And an item Large Fries with price 2.19 has changed quantity to 2
        And an item Large Fries with price 4.38 has changed quantity to 1
        When the cashier presses the cash tender button
        Then the POS displays Ask tender amount cash frame
        And the POS sends a GetPromotions request to PES with following elements
            | element                           | value                   |
            | appliedRewards[0].amount          | 0.3                     |
            | appliedRewards[0].promotionId     | 30cents off merchandise |
            | appliedRewards[0].redemptionCount | 1                       |


    @fast
    Scenario: The POS sends a GetPromotions request with single aggregated applied reward
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And an item with barcode 001 is present in the transaction
        When the cashier presses the cash tender button
        Then the POS displays Ask tender amount cash frame
        And the POS sends a GetPromotions request to PES with following elements
            | element                           | value                   |
            | appliedRewards[0].amount          | 0.3                     |
            | appliedRewards[0].promotionId     | 30cents off merchandise |
            | appliedRewards[0].redemptionCount | 2                       |


    @fast
    Scenario: The POS sends a FinalizePromotions request with single aggregated applied reward
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And an item with barcode 001 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS displays main menu frame
        And the POS sends a FinalizePromotions request to PES with following elements
            | element                           | value                   |
            | appliedRewards[0].amount          | 0.3                     |
            | appliedRewards[0].promotionId     | 30cents off merchandise |
            | appliedRewards[0].redemptionCount | 2                       |


    @fast
    Scenario: The POS sends a GetPromotions request with multiple aggregated applied rewards
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And an item with barcode 002 is present in the transaction
        And an item with barcode 001 is present in the transaction
        And an item with barcode 002 is present in the transaction
        And an item with barcode 002 is present in the transaction
        When the cashier presses the cash tender button
        Then the POS displays Ask tender amount cash frame
        And the POS sends a GetPromotions request to PES with following elements
            | element                           | value                   |
            | appliedRewards[0].amount          | 0.25                    |
            | appliedRewards[0].promotionId     | 25cents off accessories |
            | appliedRewards[0].redemptionCount | 3                       |
            | appliedRewards[1].amount          | 0.3                     |
            | appliedRewards[1].promotionId     | 30cents off merchandise |
            | appliedRewards[1].redemptionCount | 2                       |


    @fast
    Scenario: The POS sends a FinalizePromotions request with multiple aggregated applied rewards
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And an item with barcode 002 is present in the transaction
        And an item with barcode 001 is present in the transaction
        And an item with barcode 002 is present in the transaction
        And an item with barcode 002 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                           | value                   |
            | appliedRewards[0].amount          | 0.25                    |
            | appliedRewards[0].promotionId     | 25cents off accessories |
            | appliedRewards[0].redemptionCount | 3                       |
            | appliedRewards[1].amount          | 0.3                     |
            | appliedRewards[1].promotionId     | 30cents off merchandise |
            | appliedRewards[1].redemptionCount | 2                       |


    @fast
    Scenario: The POS sends a GetPromotions request with multiple aggregated applied rewards when there is a partial discount
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 006 is present in the transaction
        And an item with barcode 009 is present in the transaction
        And an item with barcode 006 is present in the transaction
        When the cashier presses the cash tender button
        Then the POS displays Ask tender amount cash frame
        And the POS sends a GetPromotions request to PES with following elements
            | element                           | value                   |
            | appliedRewards[0].amount          | 3.33                    |
            | appliedRewards[0].promotionId     | 10.25 off carwash items |
            | appliedRewards[0].redemptionCount | 2                       |
            | appliedRewards[1].amount          | 10.25                   |
            | appliedRewards[1].promotionId     | 10.25 off carwash items |
            | appliedRewards[1].redemptionCount | 1                       |


    @fast
    Scenario: The POS sends a FinalizePromotions request with multiple aggregated applied rewards when there is a partial discount
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 006 is present in the transaction
        And an item with barcode 009 is present in the transaction
        And an item with barcode 006 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                           | value                   |
            | appliedRewards[0].amount          | 3.33                    |
            | appliedRewards[0].promotionId     | 10.25 off carwash items |
            | appliedRewards[0].redemptionCount | 2                       |
            | appliedRewards[1].amount          | 10.25                   |
            | appliedRewards[1].promotionId     | 10.25 off carwash items |
            | appliedRewards[1].redemptionCount | 1                       |


    @fast
    Scenario: The POS sends a GetPromotions request with single aggregated applied reward after removing an item
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 006 is present in the transaction
        And an item with barcode 009 is present in the transaction
        And an item with barcode 006 is present in the transaction
        And the cashier voided the Carwash Extra
        When the cashier presses the cash tender button
        Then the POS sends a GetPromotions request to PES with following elements
            | element                           | value                   |
            | appliedRewards[0].amount          | 3.33                    |
            | appliedRewards[0].promotionId     | 10.25 off carwash items |
            | appliedRewards[0].redemptionCount | 2                       |


    @fast
    Scenario: The POS sends a FinalizePromotions request with single aggregated applied reward after removing an item
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 006 is present in the transaction
        And an item with barcode 009 is present in the transaction
        And an item with barcode 006 is present in the transaction
        And the cashier voided the Carwash Extra
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                           | value                   |
            | appliedRewards[0].amount          | 3.33                    |
            | appliedRewards[0].promotionId     | 10.25 off carwash items |
            | appliedRewards[0].redemptionCount | 2                       |


    @fast
    Scenario: Create prepay, POS sends a GetPromotions request with correct transactionOrigin/transactionType elements
        # Set Fuel credit prepay method to Auth and Capture
        Given the POS option 1851 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the POS is in a ready to sell state
        When the cashier prepays the fuel for price 10.00 at pump id 1
        Then the POS sends a GetPromotions request to PES with following elements
            | element           | value  |
            | transactionOrigin | POS    |
            | transactionType   | PREPAY |


    @fast
    Scenario Outline: Create prepay, POS sends GetPromotions request to PES with correct pumpId
        Given the POS is in a ready to sell state
        When the cashier prepays the fuel for price 10.00 at pump id <pump_id>
        Then the POS sends a GetPromotions request to PES with following elements
            | element                     | value       |
            | checkDetails.pumpId         | <pump_id>   |

        Examples:
        | pump_id |
        | 1       |
        | 2       |


    @fast
    Scenario: POS sends balance inquiry to PES
        Given the POS is in a ready to sell state
        And the Sigma simulator has essential configuration
        And the nep-server has following receipt message configured for get request
            | content           | type | location | alignment | formats              | line_break                  |
            | Points activity   | TEXT | DEFAULT  | LEFT      | BOLD                 | NO_BREAK_LINE               |
            | Earned 200 points | TEXT | DEFAULT  | LEFT      | NO_FORMATTING,       | LINE_BREAK_BEFORE_PRINTLINE |
            | Used 200 points   | TEXT | DEFAULT  | LEFT      | UNDERLINE, BOLD      | PRINTER_CUT_AFTER_PRINTLINE |
            | Thank you         | TEXT | DEFAULT  | LEFT      | NO_FORMATTING        | LINE_BREAK_AFTER_PRINTLINE  |
        And the POS displays other functions frame
        And the cashier pressed Loyalty Balance Inquiry button
        When the cashier scans PES loyalty card 3104174102936582
        Then the POS sends a GetPromotions request to PES with following elements
            | element                    | value            |
            | consumerIds[0].entryMethod | SCAN             |
            | consumerIds[0].identifier  | 3104174102936582 |
            | consumerIds[0].type        | LOYALTY_ID       |
            | orderTotals[0].type        | TAX_INCLUDED     |
            | orderTotals[0].value       | 0                |
            | orderTotals[1].type        | TAX_EXCLUDED     |
            | orderTotals[1].value       | 0                |
            | orderTotals[2].type        | ITEM_TOTAL       |
            | orderTotals[2].value       | 0                |
        And following fields are not present in the GetPromotions request
            | element           |
            | items             |
       And the Sigma does not receive transactions from POS


    @fast
    Scenario: POS sends VoidRequest after balance inquiry to PES
        Given the POS is in a ready to sell state
        And the nep-server has following receipt message configured for get request
            | content           | type | location | alignment | formats              | line_break                  |
            | Points activity   | TEXT | DEFAULT  | LEFT      | BOLD                 | NO_BREAK_LINE               |
            | Earned 200 points | TEXT | DEFAULT  | LEFT      | NO_FORMATTING,       | LINE_BREAK_BEFORE_PRINTLINE |
            | Used 200 points   | TEXT | DEFAULT  | LEFT      | UNDERLINE, BOLD      | PRINTER_CUT_AFTER_PRINTLINE |
            | Thank you         | TEXT | DEFAULT  | LEFT      | NO_FORMATTING        | LINE_BREAK_AFTER_PRINTLINE  |
        And the POS displays other functions frame
        And the cashier pressed Loyalty Balance Inquiry button
        And a PES loyalty card 3104174102936582 is present in the transaction
        When the cashier selects Go back button
        Then the POS sends VoidPromotions request to PES after last action
        And no transaction is in progress


    @fast
    Scenario: The POS sends a FinalizePromotions request with correct loyalty tender data
        Given the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And an item with barcode 009 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                                                | value                   |
            | tenders[0].amount                                      | 10                      |
            | tenders[0].tenderType                                  | LOYALTY                 |
            | orderLevelAdjustments[0].adjustmentValue               | 10                      |
            | orderLevelAdjustments[0].appliesToNonDiscountableItems | True                    |
            | orderLevelAdjustments[0].calculationType               | CENTS_OFF               |
            | orderLevelAdjustments[0].fundingDepartmentId           |                         |
            | orderLevelAdjustments[0].priority                      | 0                       |
            | orderLevelAdjustments[0].promotionId                   | 10.00 off a combo       |
            | orderLevelAdjustments[0].type                          | PROMOTIONAL_DISCOUNT    |


    @fast
    Scenario: The POS sends a FinalizePromotions request with correct loyalty tender data for partial promotion
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        And an item with barcode 006 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                                                | value                   |
            | tenders[0].amount                                      | 2.28                    |
            | tenders[0].tenderType                                  | LOYALTY                 |
            | orderLevelAdjustments[0].adjustmentValue               | 2.28                    |
            | orderLevelAdjustments[0].appliesToNonDiscountableItems | True                    |
            | orderLevelAdjustments[0].calculationType               | CENTS_OFF               |
            | orderLevelAdjustments[0].fundingDepartmentId           |                         |
            | orderLevelAdjustments[0].priority                      | 0                       |
            | orderLevelAdjustments[0].promotionId                   | 10.00 off a combo       |
            | orderLevelAdjustments[0].type                          | PROMOTIONAL_DISCOUNT    |


    @fast
    Scenario: The POS sends a FinalizePromotions request with single item adjustment
        Given the POS is in a ready to sell state
        And an item with barcode 009 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                                               | value                   |
            | items[0].adjustments[0].calculationType               | CENTS_OFF               |
            | items[0].adjustments[0].adjustmentValue               | 10.25                   |
            | items[0].adjustments[0].appliesToNonDiscountableItems | True                    |
            | items[0].adjustments[0].fundingDepartmentId           |                         |
            | items[0].adjustments[0].priority                      | 0                       |
            | items[0].adjustments[0].type                          | PROMOTIONAL_DISCOUNT    |
            | items[0].adjustments[0].promotionId                   | 10.25 off carwash items |
            | items[0].adjustments[0].quantity.units                | 1                       |
            | items[0].adjustments[0].quantity.unitType             | SIMPLE_QUANTITY         |


    @fast
    Scenario: The POS sends a FinalizePromotions request with single item adjustment with multiple quantity units
        Given the POS is in a ready to sell state
        And an item with barcode 009 is present in the transaction
        And an item with barcode 009 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                                               | value                   |
            | items[0].adjustments[0].calculationType               | CENTS_OFF               |
            | items[0].adjustments[0].adjustmentValue               | 10.25                   |
            | items[0].adjustments[0].appliesToNonDiscountableItems | True                    |
            | items[0].adjustments[0].fundingDepartmentId           |                         |
            | items[0].adjustments[0].priority                      | 0                       |
            | items[0].adjustments[0].type                          | PROMOTIONAL_DISCOUNT    |
            | items[0].adjustments[0].promotionId                   | 10.25 off carwash items |
            | items[0].adjustments[0].quantity.units                | 2                       |
            | items[0].adjustments[0].quantity.unitType             | SIMPLE_QUANTITY         |


    @fast
    Scenario: The POS sends a FinalizePromotions request with multiple item adjustments
        # Promotion Execution Service Allow partial discounts is set to Yes
        Given the POS option 5278 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 006 is present in the transaction
        And an item with barcode 009 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                                               | value                   |
            | items[0].adjustments[0].calculationType               | CENTS_OFF               |
            | items[0].adjustments[0].adjustmentValue               | 3.33                    |
            | items[0].adjustments[0].appliesToNonDiscountableItems | True                    |
            | items[0].adjustments[0].fundingDepartmentId           |                         |
            | items[0].adjustments[0].priority                      | 0                       |
            | items[0].adjustments[0].type                          | PROMOTIONAL_DISCOUNT    |
            | items[0].adjustments[0].promotionId                   | 10.25 off carwash items |
            | items[0].adjustments[0].quantity.units                | 1                       |
            | items[0].adjustments[0].quantity.unitType             | SIMPLE_QUANTITY         |
            | items[1].adjustments[0].calculationType               | CENTS_OFF               |
            | items[1].adjustments[0].adjustmentValue               | 10.25                   |
            | items[1].adjustments[0].appliesToNonDiscountableItems | True                    |
            | items[1].adjustments[0].fundingDepartmentId           |                         |
            | items[1].adjustments[0].priority                      | 0                       |
            | items[1].adjustments[0].type                          | PROMOTIONAL_DISCOUNT    |
            | items[1].adjustments[0].promotionId                   | 10.25 off carwash items |
            | items[1].adjustments[0].quantity.units                | 1                       |
            | items[1].adjustments[0].quantity.unitType             | SIMPLE_QUANTITY         |


    @fast
    Scenario: The POS sends a FinalizePromotions request with single order level adjustment
        Given the POS is in a ready to sell state
        And an item with barcode 002 is present in the transaction
        And an item with barcode 009 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                                                | value                   |
            | orderLevelAdjustments[0].calculationType               | CENTS_OFF               |
            | orderLevelAdjustments[0].adjustmentValue               | 0.63                    |
            | orderLevelAdjustments[0].appliesToNonDiscountableItems | True                    |
            | orderLevelAdjustments[0].fundingDepartmentId           |                         |
            | orderLevelAdjustments[0].priority                      | 0                       |
            | orderLevelAdjustments[0].type                          | PROMOTIONAL_DISCOUNT    |
            | orderLevelAdjustments[0].promotionId                   | 20.45 off a combo       |


    @fast
    Scenario Outline: The POS sends FPR discount in finalize request for prepay sales
        # Set Fuel credit prepay method to Auth and Capture
        Given the POS option 1851 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And the POS is in a ready to sell state
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id | unit_type              | is_apply_as_tender |
            | 001            | Regular Fuel         | <discount>     | item           | <promotion>  | GALLON_US_LIQUID       | False              |
        And a prepay with price 10.00 on the pump 1 is present in the transaction
        And the transaction is tendered
        And the customer dispensed regular for 10.00 price at pump 1
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                                               | value                |
            | appliedRewards[0].amount                              | 1.43                 |
            | appliedRewards[0].promotionId                         | <promotion>          |
            | appliedRewards[0].redemptionCount                     | 1                    |
            | items[0].adjustments[0].adjustmentValue               | <discount>           |
            | items[0].adjustments[0].appliesToNonDiscountableItems | True                 |
            | items[0].adjustments[0].calculationType               | CENTS_OFF            |
            | items[0].adjustments[0].fundingDepartmentId           |                      |
            | items[0].adjustments[0].priority                      | 0                    |
            | items[0].adjustments[0].type                          | PROMOTIONAL_DISCOUNT |
            | items[0].adjustments[0].promotionId                   | <promotion>          |
            | items[0].adjustments[0].quantity.unitType             | GALLON_US_LIQUID     |
            | items[0].adjustments[0].quantity.units                | 5.714                |
            | items[0].adjustments[0].type                          | PROMOTIONAL_DISCOUNT |
            | items[0].quantity.unitType                            | GALLON_US_LIQUID     |
            | items[0].quantity.units                               | 5.714                |
            | items[0].unitPrice                                    | 1.75                 |
            | tenders[0].amount                                     | 10                   |

        Examples:
        | discount | promotion             |
        | 0.25     | 0.25 off regular fuel |


    @fast @manual
    # FPR discount included, will require research if intentional change or not
    Scenario Outline: The POS does not send FPR discount in finalize request for prepay sales when nothing gets dispensed
        # Set Fuel credit prepay method to Auth and Capture
        Given the POS option 1851 is set to 1
        # Set Prepay Grade Select Type option as One touch
        And the POS option 5124 is set to 1
        And the POS is in a ready to sell state
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id | unit_type        | is_apply_as_tender |
            | 001            | Regular Fuel         | <discount>     | item           | <promotion>  | GALLON_US_LIQUID | False              |
        And a regular prepay for pump 1 with a price of 20.00 is tendered in cash and finalized
        And the customer dispensed prepaid regular fuel for 0.0 price on the pump 1
        When the cashier refunds the fuel from pump 1
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                 | value |
            | appliedRewards[0]       | None  |
            | items[0].adjustments[0] | None  |

        Examples:
        | discount | promotion             |
        | 0.25     | 0.25 off regular fuel |


    @fast @manual
    # Alternate ID entry is supported from pinpad only (RPOS 2021.1 and older)
    Scenario Outline: The POS sends GetPromotions request after entering alternate ID on POS. The correct alternate ID is sent in the request.
        Given the POS is in a ready to sell state
        And the POS displays Alternate ID frame
        When the cashier enters <alternate_id> alternate id
        Then an Alternate ID is in the virtual receipt
        And an Alternate ID is in the current transaction
        And the POS sends a GetPromotions request to PES with following elements
            | element                   | value             |
            | consumerIds[0].internalId | <alternate_id>    |
            | consumerIds[0].type       | PHONE             |

        Examples:
        | alternate_id  |
        | 123456789     |


    @fast
    Scenario: No fuel items are discountable. Prepay and check that the correct discountable field is sent in the GetPromotions request.
       # Set Fuel credit prepay method to Auth and Capture
        Given the POS option 1851 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And all fuel items are not discountable
        And the POS is in a ready to sell state
        When the cashier prepays the fuel for price 10.00 at pump id 1
        Then all fuel products have discountable flag set to False in the last GetPromotions request


    @fast
    Scenario: All fuel items are discountable. Prepay and check that the correct discountable field is sent in the GetPromotions request.
       # Set Fuel credit prepay method to Auth and Capture
        Given the POS option 1851 is set to 1
        # Set Prepay Grade Select Type option as None
        And the POS option 5124 is set to 0
        And all fuel items are discountable
        And the POS is in a ready to sell state
        When the cashier prepays the fuel for price 10.00 at pump id 1
        Then all fuel products have discountable flag set to True in the last GetPromotions request


    @fast
    Scenario Outline: Set fuel item to be discountable and add it to the transation, POS sends GetPromotions request to PES with correct disocuntable element value.
        # Set Fuel credit prepay method to Auth and Capture
        Given the POS option 1851 is set to 1
        # Set Prepay Grade Select Type option as One touch
        And the POS option 5124 is set to 1
        And a fuel item <grade> is set to be discountable
        And the POS is in a ready to sell state
        When the cashier prepays the fuel grade <grade> for price 25.00 at pump id 2
        Then the POS sends a GetPromotions request to PES with following elements
            | element_name           | value |
            | items[0].discountable  | True  |

        Examples:
        | grade   |
        | Premium |
        | Regular |


    @fast
    Scenario Outline: Set fuel item not to be discountable and add it to the transation, POS sends GetPromotions request to PES with correct disocuntable element value.
        # Set Fuel credit prepay method to Auth and Capture
        Given the POS option 1851 is set to 1
        # Set Prepay Grade Select Type option as One touch
        And the POS option 5124 is set to 1
        And a fuel item <grade> is set not to be discountable
        And the POS is in a ready to sell state
        When the cashier prepays the fuel grade <grade> for price 25.00 at pump id 2
        Then the POS sends a GetPromotions request to PES with following elements
            | element_name           | value |
            | items[0].discountable  | False |

        Examples:
        | grade   |
        | Premium |
        | Regular |


    @fast
    Scenario Outline: Tender transaction by credit/debit, when EPS transaction masked the first digits of card number,
                      POS sends FinalizePromotions request to PES without IssuerIDNumber element.
        Given the EPS simulator uses <configuration> card configuration with card number <card_number>
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in <tender>
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                                  | value        |
            | tenders[0].amount                        | 2.04         |
            | tenders[0].tenderType                    | CREDIT_DEBIT |
        And the POS sends a FinalizePromotions request to PES without any of the following elements
            | element                   |
            | tenders[0].issuerIDNumber |

        Examples:
            | configuration | card_number | tender |
            | VISA          | X876543210  | credit |
            | VISA          | X876543210  | debit  |


    @fast
    Scenario Outline: Tender transaction partially by loyalty points and credit/debit, when EPS trasnaction masked the first digits of card number,
                      POS sends FinalizePromotions request to PES without IssuerIDNumber element.
        Given the EPS simulator uses <configuration> card configuration with card number <card_number>
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        And the POS option 5277 is set to 1
        And the PES loyalty host simulator has following combo discounts configured
            | category_codes | discount_description | discount_value | discount_level | promotion_id   | is_apply_as_tender |
            | 400            | PES tender           | 1.00           | transaction    | loyalty tende  | True               |
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in <tender>
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                                  | value        |
            | tenders[0].tenderType                    | LOYALTY      |
            | tenders[0].amount                        | 1.00         |
            | tenders[1].tenderType                    | CREDIT_DEBIT |
            | tenders[1].amount                        | 1.34         |
        And the POS sends a FinalizePromotions request to PES without any of the following elements
            | element                   |
            | tenders[1].issuerIDNumber |

        Examples:
            | configuration | card_number | tender |
            | VISA          | X876543210  | credit |
            | VISA          | X876543210  | debit  |


    @fast
    Scenario Outline: Tender transaction by credit/debit, when the EPS does not have masked the first digits of card number,
                      POS sends FinalizePromotions request to PES with IssuerIDNumber element.
        Given the EPS simulator uses <configuration> card configuration with card number <card_number>
        And the POS is in a ready to sell state
        And an item with barcode 001 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in <tender>
        Then the POS sends a FinalizePromotions request to PES with following elements
            | element                                  | value        |
            | tenders[0].tenderType                    | CREDIT_DEBIT |
            | tenders[0].amount                        | 2.04         |
            | tenders[0].issuerIDNumber                | 987654       |

        Examples:
            | configuration | card_number | tender |
            | VISA          | 9876543210  | credit |
            | VISA          | 9876543210  | debit  |

