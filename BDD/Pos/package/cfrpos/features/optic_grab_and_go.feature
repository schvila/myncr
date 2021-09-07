@pos @pos_connect
Feature: Optic Grab & Go
    This feature file targets POS part of the Optic: Grab & Go feature a.k.a. Optic One swipe.
    The goal of the whole feature is to enable customers doing a PAP transaction using Optic to add dry stock items to
    the same order, without having to add additional tenders. This is achieved by a new type of fuel transaction called
    Outside Sale, which is passed to a POS/CSS node through POSConnect together with the dry stock, POS/CSS applies
    discounts, autocombos, FPRs, loyalty, etc., captures the full EPS amount, finalizes the transaction and sends the
    receipt back to Optic. If the sale cannot be completed, it is stored instead and customer has to go inside.

    IMPORTANT: We are not able to simulate outside sale with attached eps tran number yet - as a workaround the tests
    require a tendered and finalized prepay at one pump, whose epsilon transaction number is then used for the outside sale.

    Background: POS is ready to sell and no transaction is in progress
        Given the POS has essential configuration
        And the EPS simulator has essential configuration
        And the EPS simulator uses default card configuration
        # Set Fuel credit prepay method as Auth and Capture
        And the POS option 1851 is set to 1
        # Set Prepay Grade Select Type as None
        And the POS option 5124 is set to 0
        # Set PAPOVERRUNTOPREPAY ICR option to False
        And the POS option 5280 is set to 0
        And the pricebook contains discounts
        | description | reduction_value | disc_type           | disc_mode         | disc_quantity   | external_id |
        | CW FPR      | 1000            | FUEL_PRICE_ROLLBACK | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE | cw_fpr_ext  |

    @fast @positive @manual
    # waiting for RPOS-22651
    Scenario: Outside sale is visible on a pump just like other fuel items but cannot be manually tendered by a cashier.
        Given the POS is in a ready to sell state
        And an outside sale fuel for 5.00 is present at pump 2
        When the cashier selects pump 2
        Then the Pay buttons are not enabled


    @fast @positive
    Scenario Outline: Send a FinalizeOrder request with outside sale fuel item and a dry stock item/carwash,
                      verify the response, transaction is finalized.
        Given the POS is in a ready to sell state
        And an outside sale fuel for price 5.00 tendered in credit is present at pump 2
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/FinalizeOrderResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/FinalizeOrder",{"ItemList":[{"POSItemId":990000000002,"POSModifier1Id":990000000007,"POSModifier2Id":0,"POSModifier3Id":0,"Quantity":1},{"Type": "Fuel", "PumpNumber":2,"SaleType":"Outside","SaleId":1}]}] | {"ItemList":[{"Description":"Sale Item A","*":"*"},{"Description":"Regular","SaleType":"Outside","Type":"Fuel","*":"*"},{"Description":"Credit","Type":"Tender","*":"*"}],"TransactionBalance":0,"TransactionSequenceNumber":"*","TransactionSubTotal":"*","TransactionTaxAmount":0,"TransactionTotal":"*"} |
        | ["Pos/FinalizeOrder",{"ItemList":[{"RposId":"990000000002-990000000007-0-0","Quantity":1},{"Type": "Fuel", "PumpNumber":2,"SaleType":"Outside","SaleId":1},{"RposId":"5070000057-0-0-0","Quantity":1, "Carwash": {"Code": "123", "ExpirationDate": "2025-04-21T11:00:00"}}]}] | {"ItemList":[{"Description":"Sale Item A","*":"*"},{"Description":"Regular","SaleType":"Outside","Type":"Fuel","*":"*"},{"Description":"Credit","Type":"Tender","*":"*"}],"TransactionBalance":0,"TransactionSequenceNumber":"*","TransactionSubTotal":"*","TransactionTaxAmount":0,"TransactionTotal":"*"} |


    @fast @negative
    Scenario Outline: Send a FinalizeOrder request with invalid outside sale fuel item and a dry stock item,
                      verify the error response, transaction is not finalized.
        Given the POS is in a ready to sell state
        And an outside sale fuel for price 5.00 tendered in credit is present at pump 2
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/FinalizeOrderResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/FinalizeOrder",{"ItemList":[{"POSItemId":990000000002,"POSModifier1Id":990000000007,"POSModifier2Id":0,"POSModifier3Id":0,"Quantity":1},{"Type": "Fuel","PumpNumber":2,"SaleType":"Outside","SaleId":2}]}] | {"ItemList": [{"RequestItemNumber": 2,"ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter SaleId is out of range."}, {"Description": "Sale Item A", "*": "*"}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes."} |
        | ["Pos/FinalizeOrder",{"ItemList":[{"POSItemId":990000000002,"POSModifier1Id":990000000007,"POSModifier2Id":0,"POSModifier3Id":0,"Quantity":1},{"Type": "Fuel","PumpNumber":123,"SaleType":"Outside","SaleId":1}]}] | {"ItemList": [{"RequestItemNumber": 2,"ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter PumpNumber is out of range."}, {"Description": "Sale Item A", "*": "*"}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes."} |


    @fast @negative
    Scenario Outline: Send a FinalizeOrder request with outside sale fuel item authorized with an invalid eps tran number,
                      verify the error response, transaction is not finalized.
        Given the POS is in a ready to sell state
        And an outside sale fuel for 5.00 authorized with eps tran <eps_tran_num> is present at pump 2
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/FinalizeOrderResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | eps_tran_num | request | response_data |
        | 99999999     | ["Pos/FinalizeOrder",{"ItemList":[{"Type": "Fuel","PumpNumber":2,"SaleType":"Outside","SaleId":1}]}] | {"ItemList": [{"ReturnCode":1110, "ReturnCodeDescription": "Invalid Epsilon Transaction Number.", "*":"*"}, {"SaleType": "Outside", "Type": "Fuel", "*": "*"}], "TransactionBalance": 5.00, "TransactionSequenceNumber": 0, "TransactionTotal": 5.00} |


    @fast @negative
    Scenario Outline: Send a FinalizeOrder request with outside sale fuel item authorized with an already used eps tran number,
                      verify the error response, transaction is not finalized.
        Given the POS is in a ready to sell state
        And an outside sale fuel for 5.00 authorized with an already used eps tran is present at pump 2
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/FinalizeOrderResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/FinalizeOrder",{"ItemList":[{"Type": "Fuel","PumpNumber":2,"SaleType":"Outside","SaleId":1}]}] | {"ItemList": [{"ReturnCode": 1111, "ReturnCodeDescription": "Epsilon transaction has already been captured.", "*":"*"}, {"SaleType": "Outside", "Type": "Fuel", "*": "*"}], "TransactionBalance": 5.00, "TransactionSequenceNumber": 0, "TransactionTotal": 5.00} |


    @fast @negative
    Scenario Outline: Send a FinalizeOrder request with outside sale fuel item and dry stock items, total value is higher
                      than eps auth amount, verify the error response, transaction is not finalized.
        Given the POS is in a ready to sell state
        And an outside sale fuel for price 5.00 tendered in credit is present at pump 2
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/FinalizeOrderResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/FinalizeOrder",{"ItemList":[{"POSItemId":990000000002,"POSModifier1Id":990000000007,"POSModifier2Id":0,"POSModifier3Id":0,"Quantity":20},{"Type": "Fuel", "PumpNumber":2,"SaleType":"Outside","SaleId":1}]}] | {"ItemList": [{"ReturnCode": 1115, "ReturnCodeDescription": "Capture amount is greater than authorization amount.", "*": "*"}, {"SaleType": "Outside", "Type": "Fuel", "*": "*"}, {"Description": "Sale Item A", "*": "*"}], "TransactionBalance": 24.80, "TransactionSequenceNumber": 0, "TransactionTotal": 24.80} |


    @fast @negative @manual
    # waiting for RPOS-22789
    Scenario Outline: Send a FinalizeOrder request with outside sale fuel item and dry stock items, fuel only card authorized
                      the sale, verify the error response, transaction is not finalized.
        Given the POS is in a ready to sell state
        And an outside sale fuel for 5.00 authorized by fleet card is present at pump 2
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/FinalizeOrderResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/FinalizeOrder",{"ItemList":[{"POSItemId":990000000002,"POSModifier1Id":990000000007,"POSModifier2Id":0,"POSModifier3Id":0,"Quantity":1},{"Type": "Fuel", "PumpNumber":2,"SaleType":"Outside","SaleId":1}]}] | {"ItemList": [{"RequestItemNumber": 2,"ReturnCode": 1114, "ReturnCodeDescription": "Merchandise is paid by fuel only card."}, {"Description": "Sale Item A", "*": "*"}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes."} |
        | ["Pos/FinalizeOrder",{"ItemList":[{"POSItemId":990000000002,"POSModifier1Id":990000000007,"POSModifier2Id":0,"POSModifier3Id":0,"Quantity":20},{"Type": "Fuel", "PumpNumber":2,"SaleType":"Outside","SaleId":1}]}] | {"ItemList": [{"RequestItemNumber": 2,"ReturnCode": 1114, "ReturnCodeDescription": "Merchandise is paid by fuel only card."}, {"Description": "Sale Item A", "*": "*"}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes."} |


    @fast @positive
    Scenario Outline: Send a FinalizeOrder request with outside sale fuel only, total value is higher than eps auth
                      amount (overrun), PAPOVERRUNTOPREPAY ICR option is set to No, only auth amount is captured by eps.
        Given the POS is in a ready to sell state
        And a 25.00 outside sale fuel authorized for 20.00 tendered in credit is present at pump 2
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/FinalizeOrderResponse
        And POS Connect response data contain |<response_data>|
        And epsilon sends capture for 20.00 amount

        Examples:
        | request | response_data |
        | ["Pos/FinalizeOrder", {"ItemList": [{"Type": "Fuel", "PumpNumber": 2, "SaleType": "Outside", "SaleId": 1}]}] | {"ItemList":[{"Description": "Regular", "ExtendedPriceAmount": 25.0, "HoseNumber": 2, "ItemNumber": 1, "POSItemId": 5070000022, "PumpNumber": 2, "Quantity": 11.364, "SaleType": "Outside", "TierNumber": 2, "Type": "Fuel", "UnitPriceAmount": 2.2}, {"Description": "Credit", "Type": "Tender", "ExtendedPriceAmount": -20.0, "*": "*"}], "TransactionBalance": 0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 20.00, "TransactionTaxAmount":0, "TransactionTotal": 20.00} |


    @fast @positive
    Scenario Outline: Send a FinalizeOrder request with outside sale fuel only, total value is higher than eps auth
                      amount (overrun), PAPOVERRUNTOPREPAY ICR option is set to Yes, only auth amount is captured,
                      rest of the fuel is converted to postpay, response includes notification about the postpay.
        # waiting for RPOS-22652 to introduce validation of the postpay on pump
        # Set PAPOVERRUNTOPREPAY ICR option to True
        Given the POS option 5280 is set to 1
        And the POS is in a ready to sell state
        And a 25.00 outside sale fuel authorized for 20.00 tendered in credit is present at pump 2
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/FinalizeOrderResponse
        And POS Connect response data contain |<response_data>|
        And the postpay for 5.00 is present on pump 2

        Examples:
        | request | response_data |
        | ["Pos/FinalizeOrder", {"ItemList": [{"Type": "Fuel", "PumpNumber": 2, "SaleType": "Outside", "SaleId": 1}]}] | {"ItemList":[{"ExtendedPriceAmount": 25.0, "ReturnCode": 1118, "ReturnCodeDescription": "Fuel Overrun Converted to Postpay.", "SaleType": "Outside", "Type": "Fuel", "*": "*"}, {"Description": "Credit", "Type": "Tender", "ExtendedPriceAmount": -20.0, "*": "*"}], "TransactionBalance": 0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 20.00, "TransactionTaxAmount":0, "TransactionTotal": 20.00} |


    @fast @positive
    Scenario: The postpay created from an outside sale overrun behaves like a regular postpay and can be added
              to the VR/current transaction by the cashier through the Pay buttons.
        # Set PAPOVERRUNTOPREPAY ICR option to True
        Given the POS option 5280 is set to 1
        And the POS is in a ready to sell state
        And a 5.50 postpay from outside sale overrun is present at pump 2
        When the cashier adds a postpay from pump 2 to the transaction
        Then an item 2.500G Regular with price 5.50 is in the virtual receipt
        And an item Regular with price 5.50 and type 7 is in the current transaction


    @fast @positive
    Scenario: The postpay created from an outside sale overrun behaves like a regular postpay and can be tendered inside
              together with other dry stock, transaction is finalized.
        # Set PAPOVERRUNTOPREPAY ICR option to True
        Given the POS option 5280 is set to 1
        And the POS is in a ready to sell state
        And a 5.00 postpay from outside sale overrun is present at pump 2
        And the postpay from pump 2 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the transaction is finalized
        And an item Regular with price 5.00 and type 7 is in the previous transaction
        And an item Sale Item A with price 0.99 and type 1 is in the previous transaction


    @fast @positive
    Scenario Outline: Send a FinalizeOrder request with outside sale fuel item and a local FPR, verify the response,
                      transaction is finalized. When a Description field is supplied, it is used instead of the one from relay file.
                      The FPR in the request is only for reporting purposes, discount was already applied at the pump before fueling.
        Given the POS is in a ready to sell state
        And an outside sale fuel for price 5.00 tendered in credit is present at pump 2
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/FinalizeOrderResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/FinalizeOrder", {"ItemList": [{"Type": "Fuel", "PumpNumber": 2, "SaleType": "Outside", "SaleId": 1}, {"Type": "Discount", "DiscountType": "Discount", "Mode": "FuelPriceRollback", "Description": "New Description", "ExternalId": "cw_fpr_ext", "FractionalQuantity": 2.500, "ExtendedPriceAmount": -0.25, "DiscountedItemList": [{"ItemNumber": 1, "Quantity": 1}]}]}] | {"ItemList": [{"SaleType": "Outside", "Type": "Fuel", "*": "*"}, {"Description": "New Description", "DiscountType": "Discount", "ExtendedPriceAmount": -0.25, "Type": "Discount", "UnitPriceAmount": -0.1, "*": "*"}, {"Description": "Credit", "ExtendedPriceAmount": -5.00, "Type": "Tender", "*": "*"}], "TransactionBalance": 0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 5.00, "TransactionTaxAmount": 0, "TransactionTotal": 5.00} |
        | ["Pos/FinalizeOrder", {"ItemList": [{"Type": "Fuel", "PumpNumber": 2, "SaleType": "Outside", "SaleId": 1}, {"Type": "Discount", "DiscountType": "Discount", "Mode": "FuelPriceRollback", "ExternalId": "cw_fpr_ext", "FractionalQuantity": 2.5, "ExtendedPriceAmount": -0.25, "DiscountedItemList": [{"ItemNumber": 1, "Quantity": 1}]}]}] | {"ItemList": [{"SaleType": "Outside", "Type": "Fuel", "*": "*"}, {"Description": "CW FPR", "DiscountType": "Discount", "ExtendedPriceAmount": -0.25, "Type": "Discount", "UnitPriceAmount": -0.1, "*": "*"}, {"Description": "Credit", "ExtendedPriceAmount": -5.00, "Type": "Tender", "*": "*"}], "TransactionBalance": 0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 5.00, "TransactionTaxAmount": 0, "TransactionTotal": 5.00} |


    @positive @fast
    Scenario Outline: Send FinalizeOrder request with an outside sale fuel item which has a debit/EBT fee linked,
                      the request does not need to have the fee mentioned, transaction is finalized.
        Given the EPS simulator uses DebitFee card configuration
        And the POS is in a ready to sell state
        And an outside sale fuel for price 5.00 tendered in debit is present at pump 2
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS displays main menu frame
        And an item Debit Fee with price 0.12 and type 32 is in the previous transaction
        And epsilon sends capture for 5.12 amount

        Examples:
        | request | response_data |
        | ["Pos/FinalizeOrder", {"ItemList": [{"Type": "Fuel", "PumpNumber": 2, "SaleType": "Outside", "SaleId": 1}]}]  | {"ItemList": [{"ExtendedPriceAmount": 5.0, "SaleType": "Outside", "Type": "Fuel", "*": "*"}, {"Description": "Debit", "ExtendedPriceAmount": -5.12, "TenderModifiers": [{"Description": "Debit Fee", "ExtendedPriceAmount": 0.12000, "SurchargeType": "Debit", "Type": "Surcharge"}], "Type": "Tender", "*": "*"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 5.12, "TransactionTaxAmount": 0.0, "TransactionTotal": 5.12} |


    @positive @fast
    Scenario Outline: Send FinalizeOrder request with an outside sale fuel item which has a debit/EBT fee linked,
                      the fee pushes the fuel over auth limit, PAPOVERRUNTOPREPAY ICR option is set to No,
                      only auth amount is captured, the rest is ignored, transaction is finalized.
        Given the EPS simulator uses DebitFee card configuration
        And the POS is in a ready to sell state
        And a 19.99 outside sale fuel authorized for 20.00 tendered in debit is present at pump 2
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS displays main menu frame
        And an item Debit Fee with price 0.12 and type 32 is in the previous transaction
        And epsilon sends capture for 20.00 amount

        Examples:
        | request | response_data |
        | ["Pos/FinalizeOrder", {"ItemList": [{"Type": "Fuel", "PumpNumber": 2, "SaleType": "Outside", "SaleId": 1}]}]  | {"ItemList": [{"ExtendedPriceAmount": 19.99, "SaleType": "Outside", "Type": "Fuel", "*": "*"}, {"Description": "Debit", "ExtendedPriceAmount": -20.00, "TenderModifiers": [{"Description": "Debit Fee", "ExtendedPriceAmount": 0.12000, "SurchargeType": "Debit", "Type": "Surcharge"}], "Type": "Tender", "*": "*"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 20.00, "TransactionTaxAmount": 0.0, "TransactionTotal": 20.00} |


    @positive @fast
    Scenario Outline: Send FinalizeOrder request with an outside sale fuel item which has a debit/EBT fee linked,
                      the fee pushes the fuel over auth limit, PAPOVERRUNTOPREPAY ICR option is set to Yes,
                      only auth amount is captured, the rest is converted to postpay, transaction is finalized.
        # waiting for RPOS-22652 to introduce validation of the postpay
        # Set PAPOVERRUNTOPREPAY ICR option to True
        Given the POS option 5280 is set to 1
        And the EPS simulator uses DebitFee card configuration
        And the POS is in a ready to sell state
        And a 19.99 outside sale fuel authorized for 20.00 tendered in debit is present at pump 2
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS displays main menu frame
        And an item Debit Fee with price 0.12 and type 32 is in the previous transaction
        And epsilon sends capture for 20.00 amount
        And the postpay for 0.11 is present on pump 2

        Examples:
        | request | response_data |
        | ["Pos/FinalizeOrder", {"ItemList": [{"Type": "Fuel", "PumpNumber": 2, "SaleType": "Outside", "SaleId": 1}]}]  | {"ItemList": [{"ExtendedPriceAmount": 19.99, "ReturnCode": 1118, "ReturnCodeDescription": "Fuel Overrun Converted to Postpay.", "SaleType": "Outside", "Type": "Fuel", "*": "*"}, {"Description": "Debit", "ExtendedPriceAmount": -20.00, "TenderModifiers": [{"Description": "Debit Fee", "ExtendedPriceAmount": 0.12000, "SurchargeType": "Debit", "Type": "Surcharge"}], "Type": "Tender", "*": "*"}], "TransactionBalance": 0.0, "TransactionSequenceNumber": "*", "TransactionSubTotal": 20.00, "TransactionTaxAmount": 0.0, "TransactionTotal": 20.00} |


    @fast @negative @manual
    Scenario: Attempt to refund an outside fuel sale from scroll previous frame, Refund not allowed error message is displayed
        # Scroll Previous frame missing metadata and ability to select transactions - RPOS-15608
        Given the POS is in a ready to sell state
        And an outside sale fuel for 5.00 was completed at pump 2
        And the previous transaction is selected on Scroll Previous frame
        When the cashier selects Refund Fuel button
        Then the POS displays Refund not allowed error frame
