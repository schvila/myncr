@pos @pos_connect @print_receipt
Feature: POS Connect PrintReceipt attribute
    This feature file validates Sheetz enhancement of POS Connect integrated to core (POSAPI 2.85.1) PrintReceipt attribute.
    Empty PrintReceipt block (e.g.'PrintReceipt':{}) disables receipt printing while absence of PrintReceipt block doesnot override behavior of Pos option 1550 for POS Stored transactions and checkbox 'Print transactions as they are stored' in the properties of a CSS terminal for CSS transactions.( Recommended Configuration)
    Actors
    * application: an application which uses the POS Connect
    * POS: a POS application
    * POS Connect: a POS Connect server

Background: The POS and the printer have default configuration
    Given the POS has essential configuration
    And the POS Option 1550 is set to 1


    @positive @fast
    Scenario Outline: Send StoreOrder command to the POS without PrintReceipt variable and validate that the receipt is printed
        Given the POS is in a ready to sell state
        When the application sends print request |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/StoreOrderResponse
        And the receipt is printed with following lines
        | line                                           |
        |<span class="width-40 center bold">POSBDD</span>|
        |<span class="width-40 center bold">Python Lane 702</span>|
        |<span class="width-40 center bold">Behave City, BDD State 79201</span>|
        |<span class="width-40 center">------------------------------------------------------------------------</span>|
        |<span class="width-19 right">{{ tran_date }}</span><span class="width-2 left"></span><span class="width-19 left">{{ tran_time }}</span>|
        |<span class="width-40 left"></span>|
        |<span class="width-9 left">Register:</span><span class="left"> </span><span class="width-7 left">1</span><span class="width-13 left">Tran Seq No:</span><span class="width-10 right">{{ tran_number }}</span>|
        |<span class="width-9 left">Store No:</span><span class="left"> </span><span class="width-5 left">79201-1</span><span class="width-25 right">1234, 🞀Cashier🞁</span>|
        |<span class="width-40 left"></span>|
        |<span class="width-40 center">(CUSTOMER RECEIPT)</span>|
        |<span class="width-1 left">I</span><span class="width-4 left">4</span><span class="left"> </span><span class="width-24 left">Sale Item B</span><span class="left"> </span><span class="width-9 right">$7.96</span>|
        |<span class="width-40 right">-----------</span>|
        |<span class="width-30 left">Sub. Total:</span><span class="width-10 right">$7.96</span>|
        |<span class="width-30 left">Tax:</span><span class="width-10 right">$0.56</span>|
        |<span class="width-30 left">Total:</span><span class="width-10 right">$8.52</span>|
        |<span class="width-30 left">Discount Total:</span><span class="width-10 right">$0.00</span>|
        |<span class="width-40 left"></span>|
        |<span class="width-40 center bold double-height">Thanks</span>|
        |<span class="width-40 center bold double-height">For Your Business</span>|
        |<span class="width-40 left"></span>|

        Examples:
        | request |
        | ["Pos/StoreOrder", {"OriginSystemId": "PayInStore", "OriginReferenceId": "1234567890", "CustomerName": "Ben Example Order", "ItemList":[{"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4 }]}] |


    @fast
    Scenario Outline: Send StoreOrder command to the POS with PrintReceipt variable and validate that the receipt is not printed
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/StoreOrderResponse
        And no receipt is printed

        Examples:
        | request |
        | ["Pos/StoreOrder",{"OriginSystemId": "ForeCourt", "PrintReceipt": {}, "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList":[{"POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2 }]}] |


    @fast
    Scenario Outline: Send StoreOrder command to the POS with invalid PrintReceipt variable and validate that the response code is 200 and the receipt is not printed
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/StoreOrderResponse
        And POS Connect response data contain |<response_data>|
        And no receipt is printed

        Examples:
        | request | response_data |
        | ["Pos/StoreOrder",{"OriginSystemId": "ForeCourt", "PrintReceipt": {"Customer": 0}, "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList":[{"POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2 }]}] | {"ItemList": [{"Description": "Sale Item A", "ExtendedPriceAmount": 1.98, "ExternalId": "ITT-099999999990-0-1", "ItemNumber": 1, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "OriginSystemId": "ForeCourt", "TransactionBalance": 2.12, "TransactionSubTotal": 1.98, "TransactionTaxAmount": 0.14, "TransactionTotal": 2.12} |
        | ["Pos/StoreOrder",{"OriginSystemId": "ForeCourt", "PrintReceipt": {"Customer": -123}, "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList":[{"POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2 }]}] | {"ItemList": [{"Description": "Sale Item A", "ExtendedPriceAmount": 1.98, "ExternalId": "ITT-099999999990-0-1", "ItemNumber": 1, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "OriginSystemId": "ForeCourt", "TransactionBalance": 2.12, "TransactionSubTotal": 1.98, "TransactionTaxAmount": 0.14, "TransactionTotal": 2.12} |
        | ["Pos/StoreOrder",{"OriginSystemId": "ForeCourt", "PrintReceipt": {"Customer": 123456789}, "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList":[{"POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2 }]}] | {"ItemList": [{"Description": "Sale Item A", "ExtendedPriceAmount": 1.98, "ExternalId": "ITT-099999999990-0-1", "ItemNumber": 1, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "OriginSystemId": "ForeCourt", "TransactionBalance": 2.12, "TransactionSubTotal": 1.98, "TransactionTaxAmount": 0.14, "TransactionTotal": 2.12} |
        | ["Pos/StoreOrder",{"OriginSystemId": "ForeCourt", "PrintReceipt": {"Customer": "123abc"}, "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList":[{"POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2 }]}] | {"ItemList": [{"Description": "Sale Item A", "ExtendedPriceAmount": 1.98, "ExternalId": "ITT-099999999990-0-1", "ItemNumber": 1, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "OriginSystemId": "ForeCourt", "TransactionBalance": 2.12, "TransactionSubTotal": 1.98, "TransactionTaxAmount": 0.14, "TransactionTotal": 2.12} |


    @positive @fast
    Scenario Outline: Send StoreOrder command to the POS with PrintReceipt variable and validate that the StoreOrder response does not have PrintReceipt variable
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/StoreOrderResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_data |
        | ["Pos/StoreOrder",{"OriginSystemId": "ForeCourt", "PrintReceipt": {}, "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList":[{"POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2 }]}] | {"ItemList": [{"Description": "Sale Item A", "ExtendedPriceAmount": 1.98, "ExternalId": "ITT-099999999990-0-1", "ItemNumber": 1, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "RequestItemNumber": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "OriginSystemId": "ForeCourt", "TransactionBalance": 2.12, "TransactionSubTotal": 1.98, "TransactionTaxAmount": 0.14, "TransactionTotal": 2.12} |


    @positive @fast
    Scenario Outline: Send StoreOrder command to the POS with PrintReceipt variable and validate that the ViewStoredOrders response does not have PrintReceipt variable
        Given the POS is in a ready to sell state
        And the application sent a |<request>| to the POS Connect to store a transaction under Transaction Sequence Number
        When the application sends ViewStoredOrders command with last stored order to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is <response_type>
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | response_type | response_data |
        | ["Pos/StoreOrder", {"OriginSystemId": "PayInStore", "PrintReceipt": {}, "OriginReferenceId": "1234567890", "CustomerName": "Ben Example Order", "ItemList":[{"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4 }]}] | Pos/ViewStoredOrdersResponse | {"TransactionData": {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 7.96, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4, "Type": "Regular", "UnitPriceAmount": 1.99}], "TransactionBalance": 8.52, "TransactionSubTotal": 7.96, "TransactionTaxAmount": 0.56, "TransactionTotal": 8.52}} |
        | ["Pos/StoreOrder", {"OriginSystemId": "PayInStore", "PrintReceipt": {"Customer": 1}, "OriginReferenceId": "1234567890", "CustomerName": "Ben Example Order", "ItemList":[{"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4 }]}] | Pos/ViewStoredOrdersResponse | {"TransactionData": {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 7.96, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4, "Type": "Regular", "UnitPriceAmount": 1.99}], "TransactionBalance": 8.52, "TransactionSubTotal": 7.96, "TransactionTaxAmount": 0.56, "TransactionTotal": 8.52}} |


    @positive @fast
    Scenario Outline: Send StoreOrder command to the POS with PrintReceipt variable and validate that the RemoveStoredOrder response does not have PrintReceipt variable
        Given the POS is in a ready to sell state
        And the application sent a |<request>| to the POS Connect to store a transaction under Transaction Sequence Number
        When the application sends RemoveStoredOrder command with the last stored transaction number to the POS
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/RemoveStoredOrdersResponse
        And POS Connect response data contain |<response_data>|
        And the last stored transaction is removed from the store recall queue

        Examples:
        | request | response_data |
        | ["Pos/StoreOrder", {"OriginSystemId": "PayInStore", "PrintReceipt": {}, "OriginReferenceId": "1234567890", "CustomerName": "Ben Example Order", "ItemList":[{"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4 }]}] | {"Transactions": [{"TransactionData": {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 7.96, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4, "Type": "Regular", "UnitPriceAmount": 1.99}], "TransactionBalance": 8.52, "TransactionSubTotal": 7.96, "TransactionTaxAmount": 0.56, "TransactionTotal": 8.52}, "TransactionSequenceNumber": "*"}]} |
        | ["Pos/StoreOrder", {"OriginSystemId": "PayInStore", "PrintReceipt": {"Customer": 1}, "OriginReferenceId": "1234567890", "CustomerName": "Ben Example Order", "ItemList":[{"POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4 }]}] | {"Transactions": [{"TransactionData": {"ItemList": [{"Description": "Sale Item B", "ExtendedPriceAmount": 7.96, "ExternalId": "ITT-088888888880-0-1", "ItemNumber": 1, "POSItemId": 990000000003, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 4, "Type": "Regular", "UnitPriceAmount": 1.99}], "TransactionBalance": 8.52, "TransactionSubTotal": 7.96, "TransactionTaxAmount": 0.56, "TransactionTotal": 8.52}, "TransactionSequenceNumber": "*"}]} |


    @fast
    Scenario Outline: Send StoreOrder command to the POS with PrintReceipt variable and validate that the receipt is printed after the stored transaction is recalled and tendered
        Given the POS is in a ready to sell state
        And the application sent a |<request>| to the POS Connect to store a transaction under Transaction Sequence Number
        And the application sent RecallTransaction command with last stored Sequence Number to the POS Connect
        And the transaction is tendered
        When the cashier presses print receipt button
        Then the receipt is printed with following lines
        | line                                          |
        |<span class="width-40 center bold">POSBDD</span>|
        |<span class="width-40 center bold">Python Lane 702</span>|
        |<span class="width-40 center bold">Behave City, BDD State 79201</span>|
        |<span class="width-40 center">------------------------------------------------------------------------</span>|
        |<span class="width-19 right">{{ tran_date }}</span><span class="width-2 left"></span><span class="width-19 left">{{ tran_time }}</span>|
        |<span class="width-40 left"></span>|
        |<span class="width-9 left">Register:</span><span class="left"> </span><span class="width-7 left">1</span><span class="width-13 left">Tran Seq No:</span><span class="width-10 right">{{ tran_number }}</span>|
        |<span class="width-9 left">Store No:</span><span class="left"> </span><span class="width-5 left">79201-1</span><span class="width-25 right">1234, 🞀Cashier🞁</span>|
        |<span class="width-40 left"></span>|
        |<span class="width-40 center">(CUSTOMER RECEIPT)</span>|
        |<span class="width-1 left">I</span><span class="width-4 left">2</span><span class="left"> </span><span class="width-24 left">Sale Item A</span><span class="left"> </span><span class="width-9 right">$1.98</span>|
        |<span class="width-40 right">-----------</span>|
        |<span class="width-30 left">Sub. Total:</span><span class="width-10 right">$1.98</span>|
        |<span class="width-30 left">Tax:</span><span class="width-10 right">$0.14</span>|
        |<span class="width-30 left">Total:</span><span class="width-10 right">$2.12</span>|
        |<span class="width-30 left">Discount Total:</span><span class="width-10 right">$0.00</span>|
        |<span class="width-40 left"></span>|
        |<span class="width-30 left">Cash</span><span class="width-10 right">$2.12</span>|
        |<span class="width-30 left">Change</span><span class="width-10 right">$0.00</span>|
        |<span class="width-40 center bold double-height">Thanks</span>|
        |<span class="width-40 center bold double-height">For Your Business</span>|
        |<span class="width-40 left"></span>|

        Examples:
        | request |
        | ["Pos/StoreOrder",{"OriginSystemId": "ForeCourt", "PrintReceipt": {}, "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList":[{"POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2 }]}] |


    @positive @fast
    Scenario Outline: Send StoreOrder command to the POS with PrintReceipt variable and validate the receipt after the stored transaction is recalled, restored and printed
        Given the POS is in a ready to sell state
        And the application sent a |<request>| to the POS Connect to store a transaction under Transaction Sequence Number
        And the cashier recalled last stored transaction
        And the cashier stored the transaction
        When the cashier presses print receipt button
        Then the receipt is printed with following lines
        | line                                          |
        |<span class="width-40 center bold">POSBDD</span>|
        |<span class="width-40 center bold">Python Lane 702</span>|
        |<span class="width-40 center bold">Behave City, BDD State 79201</span>|
        |<span class="width-40 center">------------------------------------------------------------------------</span>|
        |<span class="width-19 right">{{ tran_date }}</span><span class="width-2 left"></span><span class="width-19 left">{{ tran_time }}</span>|
        |<span class="width-40 left"></span>|
        |<span class="width-9 left">Register:</span><span class="left"> </span><span class="width-7 left">1</span><span class="width-13 left">Tran Seq No:</span><span class="width-10 right">{{ tran_number }}</span>|
        |<span class="width-9 left">Store No:</span><span class="left"> </span><span class="width-5 left">79201-1</span><span class="width-25 right">1234, 🞀Cashier🞁</span>|
        |<span class="width-40 left"></span>|
        |<span class="width-40 center">(CUSTOMER RECEIPT)</span>|
        |<span class="width-1 left">I</span><span class="width-4 left">2</span><span class="left"> </span><span class="width-24 left">Sale Item A</span><span class="left"> </span><span class="width-9 right">$1.98</span>|
        |<span class="width-40 right">-----------</span>|
        |<span class="width-30 left">Sub. Total:</span><span class="width-10 right">$1.98</span>|
        |<span class="width-30 left">Tax:</span><span class="width-10 right">$0.14</span>|
        |<span class="width-30 left">Total:</span><span class="width-10 right">$2.12</span>|
        |<span class="width-30 left">Discount Total:</span><span class="width-10 right">$0.00</span>|
        |<span class="width-40 left"></span>|
        |<span class="width-40 center bold double-height">Thanks</span>|
        |<span class="width-40 center bold double-height">For Your Business</span>|
        |<span class="width-40 left"></span>|

        Examples:
        | request |
        | ["Pos/StoreOrder",{"OriginSystemId": "ForeCourt", "PrintReceipt": {}, "OriginReferenceId": "8", "CustomerName": "Test Customer Name", "ItemList":[{"POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2 }]}] |