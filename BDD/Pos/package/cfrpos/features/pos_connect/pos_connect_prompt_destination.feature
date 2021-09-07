@pos @pos_connect
Feature: POS Connect support prompt for change destination.
     If an item added to the POS transaction is taxed differently based on destination where it will be consumed (i.e. either on-premise or off-premise) 
     then POS terminal will display a Yes/No prompt (aka Destination Prompt) to customer with question about where item will be consumed.
     The POS control parameter 200 is used to set the differently taxed Destination ID, POS control parameter 201 holds the prompt text to display to customer.
     Items will be taxed per tax configuration for the destination selected by customer via the Destination Prompt
     Destination Prompt will only be shown once per transaction


    Background: POS is ready to sell and no transaction is in progress
        Given the POS has essential configuration
        And the POS has the feature PosApiServer enabled
        And the following destinations are configured
        | destination_id | description  |
        | 10001          | Eat In       |
        # POS ctrl par 200 sets the differently taxed Destination ID
        And the POS control parameter 200 is set to 10001
        # POS ctrl par 201 sets the prompt to display to customer at SCO when dual taxed item ordered
        And the POS control parameter 201 is set to Will you eat in?
        And the POS has tax plan QA test plan with id 6 configured with following taxes
        | tax_control_id | destination_id | tax_value | tax_description |
        | 102            | 10001          | 10        | QA Eat In High  |
        | 103            | 1              | 20        | QA Take Away    |
        | 104            | 10001          | 4.75      | QA Eat In Low   |
        And the pricebook contains retail items
        | description         | price  | item_id     | barcode | tax_plan_id |
        | Zuppa Di Champignon | 5.50   | 5070000088  | 001     | 6           |


    @positive @fast
    Scenario Outline: Send SellItem command with food item in request, the POS displays Ask confirmation frame to change the destination
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data are |<dataneeded_response>|
        And the POS displays Ask confirm destination frame

        Examples:
            | request | dataneeded_response |
            | ["Pos/SellItem", {"POSItemId": 5070000088, "FractionalQuantity": 1}]  | {"DataType": "YesNo", "PromptId": 5054, "PromptText": "Will you eat in?", "PromptType": "ask-confirm-destination"}  |


    @positive @fast
    Scenario Outline: Send DataNeededResponse command to the POS as YesNo and validate the response
        Given the POS is in a ready to sell state
        And the application sent |["Pos/SellItem", {"POSItemId": 5070000088, "FractionalQuantity": 1}]| to the POS Connect
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request                                                               | response_data                             |
        | ["Pos/DataNeededResponse",{"DataType": "YesNo", "YesNoData": "Yes"}]  | {"TransactionData": {"ItemList": [{"Description": "Zuppa Di Champignon", "ExtendedPriceAmount": 5.5, "FractionalQuantity": 1.0, "ItemNumber": 1, "POSItemId": 5070000088, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 5.5}], "TransactionBalance": 6.31, "TransactionSubTotal": 5.5, "TransactionTaxAmount": 0.81, "TransactionTotal": 6.31}, "TransactionSequenceNumber": "*"}|
        | ["Pos/DataNeededResponse",{"DataType": "YesNo", "YesNoData": "No"}]   | {"TransactionData": {"ItemList": [{"Description": "Zuppa Di Champignon", "ExtendedPriceAmount": 5.5, "FractionalQuantity": 1.0, "ItemNumber": 1, "POSItemId": 5070000088, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 5.5}], "TransactionBalance": 6.6, "TransactionSubTotal": 5.5, "TransactionTaxAmount": 1.1, "TransactionTotal": 6.6}, "TransactionSequenceNumber": "*"}|


    @negative @fast
    Scenario Outline: Send SellItem command with food item in request, then validate the response after second SellItem command with food item in request, Ask confirmation frame is not displayed on POS
        Given the POS is in a ready to sell state
        And the application sent |<request>| to the POS Connect
        And the application sent |<dataneeded_response>| to the POS Connect
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/SellItemResponse
        And POS Connect response data contain |<response_data>|

        Examples:
        | request | dataneeded_response | response_data |
        |["Pos/SellItem", {"POSItemId": 5070000088, "FractionalQuantity": 1}]   | ["Pos/DataNeededResponse",{"DataType": "YesNo", "YesNoData": "Yes"}]  | {"TransactionData": {"ItemList": [{"Description": "Zuppa Di Champignon", "ExtendedPriceAmount": 5.5, "FractionalQuantity": 1.0, "ItemNumber": 1, "POSItemId": 5070000088, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 5.5}, {"Description": "Zuppa Di Champignon", "ExtendedPriceAmount": 5.5, "FractionalQuantity": 1.0, "ItemNumber": 2, "POSItemId": 5070000088, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 5.5}], "TransactionBalance": 12.62, "TransactionSubTotal": 11.0, "TransactionTaxAmount": 1.62, "TransactionTotal": 12.62}, "TransactionSequenceNumber": "*"}|
        |["Pos/SellItem", {"POSItemId": 5070000088, "FractionalQuantity": 1}]   | ["Pos/DataNeededResponse",{"DataType": "YesNo", "YesNoData": "No"}]  | {"TransactionData": {"ItemList": [{"Description": "Zuppa Di Champignon", "ExtendedPriceAmount": 5.5, "FractionalQuantity": 1.0, "ItemNumber": 1, "POSItemId": 5070000088, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 5.5}, {"Description": "Zuppa Di Champignon", "ExtendedPriceAmount": 5.5, "FractionalQuantity": 1.0, "ItemNumber": 2, "POSItemId": 5070000088, "POSModifier1Id": 219000000001, "POSModifier2Id": 0, "POSModifier3Id": 0, "Quantity": 1, "Type": "Regular", "UnitPriceAmount": 5.5}], "TransactionBalance": 13.2, "TransactionSubTotal": 11.0, "TransactionTaxAmount": 2.2, "TransactionTotal": 13.2}, "TransactionSequenceNumber": "*"}|
