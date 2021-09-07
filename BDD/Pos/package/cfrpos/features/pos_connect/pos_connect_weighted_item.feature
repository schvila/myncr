@pos @pos_connect
Feature: POS Connect weighted item
    Pos/SellItem request and response are modified to have weight information which will be processed on POS node using FractionalQuantity parameter.
    POSOption 1578 -A unit symbol defining base on uom (unit of measure) on the system. It will be used on virtual receipt, printed receipts, exports.
    Set unit of measure as kg or lb


    Background: POS is ready to sell and no transaction is in progress
        Given the POS has essential configuration
        And the POS has the feature PosApiServer enabled
        And the pricebook contains retail items
        | description        | price  | barcode      | item_id     | weighted_item |
        | Item Weighted      | 0.99   | 101          | 5070000090  | True          |


    @positive @fast
    Scenario Outline: send Pos/SellItem command with weighted item identified by its POSItemId and weight specified in request and validate that the weighted item is added to VR
        Given the POS option 1578 is set to <pos_option_val>
        And the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|
        And an item <item_name> with uom <uom> and price <price> is in the virtual receipt

        Examples:
         | pos_option_val | item_name | uom | price | request | response_data |
         | 0 | 0.010 Item Weighted | kg | 0.01 | ["Pos/SellItem", {"POSItemId": 5070000090, "FractionalQuantity": 0.01}]   | {"TransactionData": {"ItemList": [{"Description": "Item Weighted", "ExtendedPriceAmount": 0.01, "FractionalQuantity": 0.01, "ItemNumber": 1, "POSItemId": 5070000090, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "TransactionBalance": 0.01, "TransactionSubTotal": 0.01, "TransactionTaxAmount": 0, "TransactionTotal": 0.01}, "TransactionSequenceNumber": "*"}  |
         | 0 | 0.990 Item Weighted | kg | 0.98 | ["Pos/SellItem", {"POSItemId": 5070000090, "FractionalQuantity": 0.99}]   | {"TransactionData": {"ItemList": [{"Description": "Item Weighted", "ExtendedPriceAmount": 0.98, "FractionalQuantity": 0.99, "ItemNumber": 1, "POSItemId": 5070000090, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "TransactionBalance": 1.05, "TransactionSubTotal": 0.98, "TransactionTaxAmount": 0.07, "TransactionTotal": 1.05}, "TransactionSequenceNumber": "*"}  |
         | 0 | 2.556 Item Weighted | kg | 2.53 | ["Pos/SellItem", {"POSItemId": 5070000090, "FractionalQuantity": 2.556}]  | {"TransactionData": {"ItemList": [{"Description": "Item Weighted", "ExtendedPriceAmount": 2.53, "FractionalQuantity": 2.556, "ItemNumber": 1, "POSItemId": 5070000090, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "TransactionBalance": 2.71, "TransactionSubTotal": 2.53, "TransactionTaxAmount": 0.18, "TransactionTotal": 2.71}, "TransactionSequenceNumber": "*"} |
         | 0 | 2.557 Item Weighted | kg | 2.53 | ["Pos/SellItem", {"POSItemId": 5070000090, "FractionalQuantity": 2.5567}] | {"TransactionData": {"ItemList": [{"Description": "Item Weighted", "ExtendedPriceAmount": 2.53, "FractionalQuantity": 2.557, "ItemNumber": 1, "POSItemId": 5070000090, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "TransactionBalance": 2.71, "TransactionSubTotal": 2.53, "TransactionTaxAmount": 0.18, "TransactionTotal": 2.71}, "TransactionSequenceNumber": "*"} |
         | 1 | 0.01 Item Weighted  | lb | 0.01 | ["Pos/SellItem", {"POSItemId": 5070000090, "FractionalQuantity": 0.01}]   | {"TransactionData": {"ItemList": [{"Description": "Item Weighted", "ExtendedPriceAmount": 0.01, "FractionalQuantity": 0.01, "ItemNumber": 1, "POSItemId": 5070000090, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "TransactionBalance": 0.01, "TransactionSubTotal": 0.01, "TransactionTaxAmount": 0, "TransactionTotal": 0.01}, "TransactionSequenceNumber": "*"}               |
         | 1 | 0.99 Item Weighted  | lb | 0.98 | ["Pos/SellItem", {"POSItemId": 5070000090, "FractionalQuantity": 0.99}]   | {"TransactionData": {"ItemList": [{"Description": "Item Weighted", "ExtendedPriceAmount": 0.98, "FractionalQuantity": 0.99, "ItemNumber": 1, "POSItemId": 5070000090, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "TransactionBalance": 1.05, "TransactionSubTotal": 0.98, "TransactionTaxAmount": 0.07, "TransactionTotal": 1.05}, "TransactionSequenceNumber": "*"}  |
         | 1 | 2.56 Item Weighted  | lb | 2.53 | ["Pos/SellItem", {"POSItemId": 5070000090, "FractionalQuantity": 2.556}]  | {"TransactionData": {"ItemList": [{"Description": "Item Weighted", "ExtendedPriceAmount": 2.53, "FractionalQuantity": 2.56, "ItemNumber": 1, "POSItemId": 5070000090, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "TransactionBalance": 2.71, "TransactionSubTotal": 2.53, "TransactionTaxAmount": 0.18, "TransactionTotal": 2.71}, "TransactionSequenceNumber": "*"} |


    @positive @fast
    Scenario Outline: send Pos/SellItem command with weighted item identified by its Barcode and weight specified in request and validate that the weighted item is added to VR and current transaction
        Given the POS option 1578 is set to <pos_option_val>
        And the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|
        And an item <item_name> with uom <uom> and price <price> is in the virtual receipt

         Examples:
         | pos_option_val | item_name | uom | price | request | response_data |
         | 0 | 0.010 Item Weighted | kg | 0.01 | ["Pos/SellItem", {"Barcode": "101", "FractionalQuantity": 0.01}]        | {"TransactionData": {"ItemList": [{"Description": "Item Weighted", "ExtendedPriceAmount": 0.01, "FractionalQuantity": 0.01, "ItemNumber": 1, "POSItemId": 5070000090, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "TransactionBalance": 0.01, "TransactionSubTotal": 0.01, "TransactionTaxAmount": 0, "TransactionTotal": 0.01}, "TransactionSequenceNumber": "*"}      |
         | 0 | 0.990 Item Weighted | kg | 0.98 | ["Pos/SellItem", {"Barcode": "101", "FractionalQuantity": 0.99}]        | {"TransactionData": {"ItemList": [{"Description": "Item Weighted", "ExtendedPriceAmount": 0.98, "FractionalQuantity": 0.99, "ItemNumber": 1, "POSItemId": 5070000090, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "TransactionBalance": 1.05, "TransactionSubTotal": 0.98, "TransactionTaxAmount": 0.07, "TransactionTotal": 1.05}, "TransactionSequenceNumber": "*"}   |
         | 0 | 2.556 Item Weighted | kg | 2.53 | ["Pos/SellItem", {"Barcode": "101", "FractionalQuantity": 2.556}]       | {"TransactionData": {"ItemList": [{"Description": "Item Weighted", "ExtendedPriceAmount": 2.53, "FractionalQuantity": 2.556, "ItemNumber": 1, "POSItemId": 5070000090, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "TransactionBalance": 2.71, "TransactionSubTotal": 2.53, "TransactionTaxAmount": 0.18, "TransactionTotal": 2.71}, "TransactionSequenceNumber": "*"}  |
         | 0 | 2.557 Item Weighted | kg | 2.53 | ["Pos/SellItem", {"Barcode": "101", "FractionalQuantity": 2.5567}]      | {"TransactionData": {"ItemList": [{"Description": "Item Weighted", "ExtendedPriceAmount": 2.53, "FractionalQuantity": 2.557, "ItemNumber": 1, "POSItemId": 5070000090, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "TransactionBalance": 2.71, "TransactionSubTotal": 2.53, "TransactionTaxAmount": 0.18, "TransactionTotal": 2.71}, "TransactionSequenceNumber": "*"} |
         | 1 | 0.01 Item Weighted  | lb | 0.01 | ["Pos/SellItem", {"Barcode": "101", "FractionalQuantity": 0.01}]        | {"TransactionData": {"ItemList": [{"Description": "Item Weighted", "ExtendedPriceAmount": 0.01, "FractionalQuantity": 0.01, "ItemNumber": 1, "POSItemId": 5070000090, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "TransactionBalance": 0.01, "TransactionSubTotal": 0.01, "TransactionTaxAmount": 0, "TransactionTotal": 0.01}, "TransactionSequenceNumber": "*"}      |
         | 1 | 0.99 Item Weighted  | lb | 0.98 | ["Pos/SellItem", {"Barcode": "101", "FractionalQuantity": 0.99}]        | {"TransactionData": {"ItemList": [{"Description": "Item Weighted", "ExtendedPriceAmount": 0.98, "FractionalQuantity": 0.99, "ItemNumber": 1, "POSItemId": 5070000090, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "TransactionBalance": 1.05, "TransactionSubTotal": 0.98, "TransactionTaxAmount": 0.07, "TransactionTotal": 1.05}, "TransactionSequenceNumber": "*"}   |
         | 1 | 2.56 Item Weighted  | lb | 2.53 | ["Pos/SellItem", {"Barcode": "101", "FractionalQuantity": 2.556}]       | {"TransactionData": {"ItemList": [{"Description": "Item Weighted", "ExtendedPriceAmount": 2.53, "FractionalQuantity": 2.56, "ItemNumber": 1, "POSItemId": 5070000090, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "TransactionBalance": 2.71, "TransactionSubTotal": 2.53, "TransactionTaxAmount": 0.18, "TransactionTotal": 2.71}, "TransactionSequenceNumber": "*"}  |


    @positive @fast
    Scenario Outline: send Pos/SellItem command with weighted item and no weight specified in request then the POS displays Enter weight frame
        Given the POS option 1578 is set to <pos_option_val>
        And the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data are |<dataneeded_response>|
        And the POS displays the enter weight frame

       Examples:
           | pos_option_val | request | dataneeded_response |
           | 0              | ["Pos/SellItem", {"POSItemId": 5070000090}] | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}], "DataType": "Number", "PromptId": 5033, "PromptText": "Please Enter Weight"}   |
           | 0              | ["Pos/SellItem", {"Barcode": "101"}]        | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}], "DataType": "Number", "PromptId": 5033, "PromptText": "Please Enter Weight"}   |
           | 1              | ["Pos/SellItem", {"POSItemId": 5070000090}] | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}], "DataType": "Number", "PromptId": 5033, "PromptText": "Please Enter Weight"}   |
           | 1              | ["Pos/SellItem", {"Barcode": "101"}]        | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}], "DataType": "Number", "PromptId": 5033, "PromptText": "Please Enter Weight"}   |


    @positive @fast
    Scenario Outline: Send Pos/SellItem command with weighted item and weight specified in request while transaction is in progress then the weight item is added to the VR
        Given the POS option 1578 is set to <pos_option_val>
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|
        And an item <item_name> with uom <uom> and price <price> is in the virtual receipt

         Examples:
        | pos_option_val | item_name | uom | price | request | response_data |
        | 0 | 2.556 Item Weighted | kg | 2.53 | ["Pos/SellItem", {"POSItemId": 5070000090, "FractionalQuantity": 2.556}]   | {"TransactionData": {"ItemList": [{"Description": "Sale Item A", "ExtendedPriceAmount": 0.99, "ExternalId": "ITT-099999999990-0-1", "FractionalQuantity": 1.0, "ItemNumber": 1, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}, {"Description": "Item Weighted", "ExtendedPriceAmount": 2.53, "FractionalQuantity": 2.556, "ItemNumber": 2, "POSItemId": 5070000090, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "TransactionBalance": 3.77, "TransactionSubTotal": 3.52, "TransactionTaxAmount": 0.25, "TransactionTotal": 3.77}, "TransactionSequenceNumber": "*"} |
        | 1 | 0.99 Item Weighted  | lb | 0.98 | ["Pos/SellItem", {"Barcode": "101", "FractionalQuantity": 0.99}]   | {"TransactionData": {"ItemList": [{"Description": "Sale Item A", "ExtendedPriceAmount": 0.99, "ExternalId": "ITT-099999999990-0-1", "FractionalQuantity": 1.0, "ItemNumber": 1, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}, {"Description": "Item Weighted", "ExtendedPriceAmount": 0.98, "FractionalQuantity": 0.99, "ItemNumber": 2, "POSItemId": 5070000090, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "TransactionBalance": 2.11, "TransactionSubTotal": 1.97, "TransactionTaxAmount": 0.14, "TransactionTotal": 2.11}, "TransactionSequenceNumber": "*"}  |


    @negative @fast
    Scenario Outline: Send Pos/SellItem command with weighted item contains invalid value to the fractionalquantity and validate the related error message in the response
     Given the POS option 1578 is set to <pos_option_val>
        And the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data are |<response>|

        Examples:
         | pos_option_val | request | response |
         | 0              | ["Pos/SellItem", {"Barcode": "101", "FractionalQuantity": -2.556}]                         | {"ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter FractionalQuantity is out of range.", "TransactionSequenceNumber": "*"} |
         | 0              | ["Pos/SellItem", {"Barcode": "101", "FractionalQuantity": "abcd"}]                         | {"ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter FractionalQuantity contains an invalid value.", "TransactionSequenceNumber": "*"} |
         | 0              | ["Pos/SellItem", {"Barcode": "101", "FractionalQuantity": "12"}]                           | {"ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter FractionalQuantity contains an invalid value.", "TransactionSequenceNumber": "*"} |
         | 0              | ["Pos/SellItem", {"Barcode": "101", "FractionalQuantity": 2147483649}]                     | {"ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter FractionalQuantity is out of range.", "TransactionSequenceNumber": "*"} |
         | 0              | ["Pos/SellItem", {"POSItemId": 5070000090, "FractionalQuantity": 0.0003}]                  | {"ReturnCode": 1119, "ReturnCodeDescription": "Zero weight not allowed.", "TransactionSequenceNumber": "*"} |
         | 1              | ["Pos/SellItem", {"POSItemId": 5070000090, "FractionalQuantity": -2.556}]                  | {"ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter FractionalQuantity is out of range.", "TransactionSequenceNumber": "*"} |
         | 1              | ["Pos/SellItem", {"POSItemId": 5070000090, "FractionalQuantity": "Send Pos/SellItem"}]     | {"ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter FractionalQuantity contains an invalid value.", "TransactionSequenceNumber": "*"} |
         | 1              | ["Pos/SellItem", {"POSItemId": 5070000090, "FractionalQuantity": 0}]                       | {"ReturnCode": 1119, "ReturnCodeDescription": "Zero weight not allowed.", "TransactionSequenceNumber": "*"} |
         | 1              | ["Pos/SellItem", {"POSItemId": 5070000090, "FractionalQuantity": 0.004}]                   | {"ReturnCode": 1119, "ReturnCodeDescription": "Zero weight not allowed.", "TransactionSequenceNumber": "*"} |


    @fast
    Scenario Outline: Send Pos/SellItem command with weighted item which has Quantity and FractionalQuantity specified and validate  response
        Given the POS option 1578 is set to <pos_option_val>
        And the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data are |<response>|

          Examples:
         | pos_option_val | request | response |
         | 0              | ["Pos/SellItem", {"POSItemId": 5070000090, "Quantity": 0, "FractionalQuantity": 1.6}]       | {"ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter Quantity is out of range.", "TransactionSequenceNumber": "*"} |
         | 1              | ["Pos/SellItem", {"POSItemId": 5070000090, "Quantity": 1, "FractionalQuantity": 2.55}]      | {"TransactionData": {"ItemList": [{"Description": "Item Weighted", "ExtendedPriceAmount": 2.52, "FractionalQuantity": 2.55, "IsWeighted": true, "ItemNumber": 1, "POSItemId": 5070000090, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "TransactionBalance": 2.7, "TransactionSubTotal": 2.52, "TransactionTaxAmount": 0.18, "TransactionTotal": 2.7}, "TransactionSequenceNumber": "*"} |
         | 1              | ["Pos/SellItem", {"POSItemId": 5070000090, "Quantity": 2, "FractionalQuantity": 3}]         | {"TransactionData": {"ItemList": [{"Description": "Item Weighted", "ExtendedPriceAmount": 2.97, "FractionalQuantity": 3.0, "IsWeighted": true, "ItemNumber": 1, "POSItemId": 5070000090, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "TransactionBalance": 3.18, "TransactionSubTotal": 2.97, "TransactionTaxAmount": 0.21, "TransactionTotal": 3.18}, "TransactionSequenceNumber": "*"} |
         | 0              | ["Pos/SellItem", {"Barcode": "101", "Quantity": 1, "FractionalQuantity": 2.556}]            | {"TransactionData": {"ItemList": [{"Description": "Item Weighted", "ExtendedPriceAmount": 2.53, "FractionalQuantity": 2.556, "IsWeighted": true, "ItemNumber": 1, "POSItemId": 5070000090, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 0.99}], "TransactionBalance": 2.71, "TransactionSubTotal": 2.53, "TransactionTaxAmount": 0.18, "TransactionTotal": 2.71}, "TransactionSequenceNumber": "*"} |


    @fast 
    Scenario Outline: Send Pos/SellItem command with non-weighted item which has Quantity and FractionalQuantity specified and validate the response
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data are |<response>|

         Examples:
         | request | response |
         | ["Pos/SellItem", {"POSItemId": 990000000002, "Quantity": 1, "FractionalQuantity": 1.2}]    | {"ReturnCode": 1120, "ReturnCodeDescription": "Invalid Quantity not allowed.", "TransactionSequenceNumber": "*"} |
         | ["Pos/SellItem", {"POSItemId": 990000000002, "Quantity": 0, "FractionalQuantity": 15}]     | {"ReturnCode": 1001, "ReturnCodeDescription": "Invalid Parameter Quantity is out of range.", "TransactionSequenceNumber": "*"} |
         | ["Pos/SellItem", {"POSItemId": 990000000002, "Quantity": 1, "FractionalQuantity": 2}]      | {"TransactionData": {"ItemList": [{"Description": "Sale Item A", "ExtendedPriceAmount": 1.98, "ExternalId": "ITT-099999999990-0-1", "FractionalQuantity": 2.0, "ItemNumber": 1, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 2, "Type": "Regular", "UnitPriceAmount": 0.99}], "TransactionBalance": 2.12, "TransactionSubTotal": 1.98, "TransactionTaxAmount": 0.14, "TransactionTotal": 2.12}, "TransactionSequenceNumber": "*"} |
         | ["Pos/SellItem", {"POSItemId": 990000000002, "Quantity": 2, "FractionalQuantity": 5}]      | {"TransactionData": {"ItemList": [{"Description": "Sale Item A", "ExtendedPriceAmount": 4.95, "ExternalId": "ITT-099999999990-0-1", "FractionalQuantity": 5.0, "ItemNumber": 1, "POSItemId": 990000000002, "POSModifier1Id": 990000000007, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 5, "Type": "Regular", "UnitPriceAmount": 0.99}], "TransactionBalance": 5.3, "TransactionSubTotal": 4.95, "TransactionTaxAmount": 0.35, "TransactionTotal": 5.3}, "TransactionSequenceNumber": "*"} |