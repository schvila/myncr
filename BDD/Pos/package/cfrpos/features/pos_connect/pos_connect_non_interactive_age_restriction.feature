@pos @pos_connect
Feature: POS Connect - Non-interactive age restriction
    This feature, originally requested for BSP mobile ordering, introduces the ability to process paid/unpaid orders through
    POSConnect even when they contain age restricted items which did not pass any kind of age verification. New relay file
    will contain a list of OriginSystemIds and their desired behavior. Should the order not contain OriginSystemId, any age
    restricted items will be declined by default and the order will not be processed. This enhancement is valid only for
    batch POSConnect requests - FinalizeOrder, SubTotalOrder and StoreOrder. When an order with AR item is processed, KPS
    should be notified and display message to check customer age. The same should also be printed on KPS and POS receipts.

    Background: POS is ready to sell and no transaction is in progress
        Given the POS has essential configuration
        And the POS has the feature PosApiServer enabled
        And the KPS has essential configuration
        # "Age verification failure tracking" option set to "NO"
        And the POS option 1024 is set to 0
        # Default external age verification result is set to No
        And the POS option 1521 is set to 0
        And the pricebook contains retail items
            | barcode      | description       | price  | age_restriction | disable_over_button | manager_override_required | military_age_restriction | id_validation_required | item_id      | modifier1_id |
            | 022222222220 | Age 21 Restricted | 4.69   | 21              | False               | False                     | 0                        | False                  | 990000000009 | 990000000007 |
            | 0369369369   | Age 18 Restricted | 3.69   | 18              | False               | False                     | 0                        | False                  | 990000000010 | 990000000007 |
            | 0123456789   | 21 No Over Button | 1.23   | 21              | True                | False                     | 0                        | False                  | 0123456789   | 0            |
            | 987654321    | Man Req Item      | 5.69   | 21              | False               | True                      | 0                        | False                  | 987654321    | 0            |
            | 234565432    | Military ID       | 2.69   | 21              | False               | False                     | 18                       | False                  | 234565432    | 0            |
            | 987656789    | ID Required       | 6.69   | 21              | False               | False                     | 0                        | True                   | 987656789    | 0            |
            | 345676543    | Uber Item         | 7.69   | 21              | True                | True                      | 18                       | True                   | 345676543    | 0            |
        And the POS has following POSConnect age restriction behavior configured
            | OriginSystemId | allow_processing |
            | AllowProc      | true             |
            | DisallowProc   | false            |


    @positive @fast
    Scenario Outline: Send a FinalizeOrder batch command with age restricted item with OriginSystemId that accepts AR
                      items to the POS, order is processed and KPS notified.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS notifies KPS about pending age verification of <age> years

        Examples:
        | age | request      | response_data |
        | 21  | ["Pos/FinalizeOrder", {"OriginSystemId": "AllowProc", "CustomerName": "John Doe", "FormatReceipt": {"PrintFormat": "NCRPRINTAPI", "Merchant": 1, "Customer": 1}, "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "022222222220", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 12.38} ]}] | {"ItemList":[{"Description": "Age 21 Restricted", "ExtendedPriceAmount": 4.69, "MinimumAge": 21, "Quantity": 1, "*": "*"}], "OriginSystemId": "AllowProc", "TransactionBalance": 0.0, "TransactionSubTotal": 12.38, "TransactionTaxAmount": 0.0, "TransactionTotal": 12.38, "TransactionSequenceNumber": "*"} |
        | 18  | ["Pos/FinalizeOrder", {"OriginSystemId": "AllowProc", "CustomerName": "John Doe", "FormatReceipt": {"PrintFormat": "NCRPRINTAPI", "Merchant": 1, "Customer": 1}, "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "0369369369", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 12.38} ]}] | {"ItemList":[{"Description": "Age 18 Restricted", "ExtendedPriceAmount": 3.69, "MinimumAge": 18, "Quantity": 1, "*": "*"}], "OriginSystemId": "AllowProc", "TransactionBalance": 0.0, "TransactionSubTotal": 11.38, "TransactionTaxAmount": 0.0, "TransactionTotal": 11.38, "TransactionSequenceNumber": "*"} |


    @positive @fast
    Scenario Outline: Send a StoreOrder/SubTotalOrder batch command with age restricted item with OriginSystemId that accepts AR
                      items to the POS, order is processed but KPS is NOT notified since proper age verification will be done later.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS does not notify KPS about pending age verification

        Examples:
        | age | request      | response_data |
        | 18  | ["Pos/StoreOrder", {"OriginSystemId": "AllowProc", "CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "0369369369", "Quantity": 1}]}]    | {"ItemList":[{"Description": "Age 18 Restricted", "ExtendedPriceAmount": 3.69, "MinimumAge": 18, "Quantity": 1, "*": "*"}], "OriginSystemId": "AllowProc", "TransactionBalance": 12.11, "TransactionSubTotal": 11.38, "TransactionTaxAmount": 0.73, "TransactionTotal": 12.11, "TransactionSequenceNumber": "*"} |
        | 21  | ["Pos/SubTotalOrder", {"OriginSystemId": "AllowProc", "CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "022222222220", "Quantity": 1}]}] | {"ItemList":[{"Description": "Age 21 Restricted", "ExtendedPriceAmount": 4.69, "MinimumAge": 21, "Quantity": 1, "*": "*"}], "TransactionBalance": 13.18, "TransactionSubTotal": 12.38, "TransactionTaxAmount": 0.8, "TransactionTotal": 13.18} |



    @positive @fast
    Scenario Outline: Send a batch command with age restricted item with OriginSystemId that declines AR items to the POS,
                      order is rejected and proper error code returned, KPS is not notified.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS does not notify KPS about pending age verification

        Examples:
        | request      | response_data |
        | ["Pos/FinalizeOrder", {"OriginSystemId": "DisallowProc", "CustomerName": "John Doe", "FormatReceipt": {"PrintFormat": "NCRPRINTAPI", "Merchant": 1, "Customer": 1}, "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "022222222220", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 12.38} ]}] | {"ItemList": [{"Barcode": "022222222220", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}], "OriginSystemId": "DisallowProc", "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 7.69, "TransactionSequenceNumber": 0, "TransactionSubTotal": 7.69, "TransactionTaxAmount": 0.0, "TransactionTotal": 7.69} |
        | ["Pos/SubTotalOrder", {"OriginSystemId": "DisallowProc", "CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "022222222220", "Quantity": 1}]}] | {"ItemList": [{"Barcode": "022222222220", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 8.15, "TransactionSequenceNumber": 0, "TransactionSubTotal": 7.69, "TransactionTaxAmount": 0.46, "TransactionTotal": 8.15}  |
        | ["Pos/StoreOrder", {"OriginSystemId": "DisallowProc", "CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "0369369369", "Quantity": 1}]}]    | {"ItemList": [{"Barcode": "0369369369", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}], "OriginSystemId": "DisallowProc", "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 8.15, "TransactionSequenceNumber": 0, "TransactionSubTotal": 7.69, "TransactionTaxAmount": 0.46, "TransactionTotal": 8.15}  |


    @negative @fast
    Scenario Outline: Send a batch command with age restricted item with OriginSystemId that is not in the relay file to the POS,
                      order is rejected by default and proper error code returned, KPS is not notified.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS does not notify KPS about pending age verification

        Examples:
        | request      | response_data |
        | ["Pos/FinalizeOrder", {"OriginSystemId": "Unknown", "CustomerName": "John Doe", "FormatReceipt": {"PrintFormat": "NCRPRINTAPI", "Merchant": 1, "Customer": 1}, "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "022222222220", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 12.38} ]}] | {"ItemList": [{"Barcode": "022222222220", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}], "OriginSystemId": "Unknown", "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 7.69, "TransactionSequenceNumber": 0, "TransactionSubTotal": 7.69, "TransactionTaxAmount": 0.0, "TransactionTotal": 7.69} |
        | ["Pos/SubTotalOrder", {"OriginSystemId": "Unknown", "CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "022222222220", "Quantity": 1}]}] | {"ItemList": [{"Barcode": "022222222220", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 8.15, "TransactionSequenceNumber": 0, "TransactionSubTotal": 7.69, "TransactionTaxAmount": 0.46, "TransactionTotal": 8.15}  |
        | ["Pos/StoreOrder", {"OriginSystemId": "Unknown", "CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "0369369369", "Quantity": 1}]}]    | {"ItemList": [{"Barcode": "0369369369", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}], "OriginSystemId": "Unknown", "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 8.15, "TransactionSequenceNumber": 0, "TransactionSubTotal": 7.69, "TransactionTaxAmount": 0.46, "TransactionTotal": 8.15}  |


    @negative @fast
    Scenario Outline: Send a batch command with age restricted item with OriginSystemId field missing to the POS,
                      order is rejected and proper error code returned, KPS is not notified.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS does not notify KPS about pending age verification

        Examples:
        | request      | response_data |
        | ["Pos/FinalizeOrder", {"CustomerName": "John Doe", "FormatReceipt": {"PrintFormat": "NCRPRINTAPI", "Merchant": 1, "Customer": 1}, "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "022222222220", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 12.38} ]}] | {"ItemList": [{"Barcode": "022222222220", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 7.69, "TransactionSequenceNumber": 0, "TransactionSubTotal": 7.69, "TransactionTaxAmount": 0.0, "TransactionTotal": 7.69} |
        | ["Pos/SubTotalOrder", {"CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "022222222220", "Quantity": 1}]}] | {"ItemList": [{"Barcode": "022222222220", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 8.15, "TransactionSequenceNumber": 0, "TransactionSubTotal": 7.69, "TransactionTaxAmount": 0.46, "TransactionTotal": 8.15}  |
        | ["Pos/StoreOrder", {"CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "0369369369", "Quantity": 1}]}]    | {"ItemList": [{"Barcode": "0369369369", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 8.15, "TransactionSequenceNumber": 0, "TransactionSubTotal": 7.69, "TransactionTaxAmount": 0.46, "TransactionTotal": 8.15}  |


    @positive @fast
    Scenario Outline: Send a batch command with age restricted item with OriginSystemId field missing to the POS,
                      the pos option 1521 allows processing of the transaction when the OriginSystemId value is missing,
                      order is processed and KPS notified about the highest restriction only.
        # Default external age verification result is set to Yes
        Given the POS option 1521 is set to 1
        And the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS does not notify KPS about pending age verification

        Examples:
        | request      | response_data |
        | ["Pos/StoreOrder", {"CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "0369369369", "Quantity": 1}]}]   |   {"ItemList":[{"Description": "Age 18 Restricted", "ExtendedPriceAmount": 3.69, "MinimumAge": 18, "Quantity": 1, "*": "*"}], "TransactionBalance": 12.11, "TransactionSubTotal": 11.38, "TransactionTaxAmount": 0.73, "TransactionTotal": 12.11, "TransactionSequenceNumber": "*"} |
        | ["Pos/SubTotalOrder", {"CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "022222222220", "Quantity": 1}]}]   |   {"ItemList":[{"Description": "Age 21 Restricted", "ExtendedPriceAmount": 4.69, "MinimumAge": 21, "Quantity": 1, "*": "*"}], "TransactionBalance": 13.18, "TransactionSubTotal": 12.38, "TransactionTaxAmount": 0.8, "TransactionTotal": 13.18} |


    @positive @fast
    Scenario Outline: Send a FinalizeOrder command with age restricted item with OriginSystemId field missing to the POS,
                      the pos option 1521 allows processing of the transaction when the OriginSystemId value is missing,
                      order is processed and KPS notified about the highest restriction only.
        # Default external age verification result is set to Yes
        Given the POS option 1521 is set to 1
        And the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS notifies KPS about pending age verification of 21 years

        Examples:
        | request      | response_data |
        | ["Pos/FinalizeOrder", {"CustomerName": "John Doe", "FormatReceipt": {"PrintFormat": "NCRPRINTAPI", "Merchant": 1, "Customer": 1}, "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "022222222220", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 12.38} ]}] | {"ItemList":[{"Description": "Age 21 Restricted", "ExtendedPriceAmount": 4.69, "MinimumAge": 21, "Quantity": 1, "*": "*"}], "TransactionBalance": 0.0, "TransactionSubTotal": 12.38, "TransactionTaxAmount": 0.0, "TransactionTotal": 12.38, "TransactionSequenceNumber": "*"} |


    @positive @fast
    Scenario Outline: Send a batch command with age restricted item with OriginSystemId that accepts AR items or unknown to the POS,
                      the pos option 1521 allows processing of the transaction when the OriginSystemId value is unknown or allows processing,
                      order is processed and KPS notified about the highest restriction only.
        # Default external age verification result is set to Yes
        Given the POS option 1521 is set to 1
        And the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS does not notify KPS about pending age verification

        Examples:
        | request      | response_data |
        | ["Pos/StoreOrder", {"OriginSystemId": "AllowProc", "CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "0369369369", "Quantity": 1}]}]   |   {"OriginSystemId": "AllowProc", "ItemList":[{"Description": "Age 18 Restricted", "ExtendedPriceAmount": 3.69, "MinimumAge": 18, "Quantity": 1, "*": "*"}], "TransactionBalance": 12.11, "TransactionSubTotal": 11.38, "TransactionTaxAmount": 0.73, "TransactionTotal": 12.11, "TransactionSequenceNumber": "*"} |
        | ["Pos/StoreOrder", {"OriginSystemId": "Unknown", "CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "0369369369", "Quantity": 1}]}]   |   {"OriginSystemId": "Unknown", "ItemList":[{"Description": "Age 18 Restricted", "ExtendedPriceAmount": 3.69, "MinimumAge": 18, "Quantity": 1, "*": "*"}], "TransactionBalance": 12.11, "TransactionSubTotal": 11.38, "TransactionTaxAmount": 0.73, "TransactionTotal": 12.11, "TransactionSequenceNumber": "*"} |
        | ["Pos/SubTotalOrder", {"OriginSystemId": "AllowProc", "CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "022222222220", "Quantity": 1}]}]   |   {"OriginSystemId": "AllowProc", "ItemList":[{"Description": "Age 21 Restricted", "ExtendedPriceAmount": 4.69, "MinimumAge": 21, "Quantity": 1, "*": "*"}], "TransactionBalance": 13.18, "TransactionSubTotal": 12.38, "TransactionTaxAmount": 0.8, "TransactionTotal": 13.18} |
        | ["Pos/SubTotalOrder", {"OriginSystemId": "Unknown", "CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "022222222220", "Quantity": 1}]}]   |   {"OriginSystemId": "Unknown", "ItemList":[{"Description": "Age 21 Restricted", "ExtendedPriceAmount": 4.69, "MinimumAge": 21, "Quantity": 1, "*": "*"}], "TransactionBalance": 13.18, "TransactionSubTotal": 12.38, "TransactionTaxAmount": 0.8, "TransactionTotal": 13.18} |


    @positive @fast
    Scenario Outline: Send a FinalizeOrder command with age restricted item with OriginSystemId that accepts AR items or unknown to the POS,
                      the pos option 1521 allows processing of the transaction when the OriginSystemId value is unknown or allows processing,
                      order is processed and KPS notified about the highest restriction only.
        # Default external age verification result is set to Yes
        Given the POS option 1521 is set to 1
        And the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS notifies KPS about pending age verification of 21 years

        Examples:
        | request      | response_data |
        | ["Pos/FinalizeOrder", {"OriginSystemId": "AllowProc", "CustomerName": "John Doe", "FormatReceipt": {"PrintFormat": "NCRPRINTAPI", "Merchant": 1, "Customer": 1}, "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "022222222220", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 12.38} ]}] | {"OriginSystemId": "AllowProc", "ItemList":[{"Description": "Age 21 Restricted", "ExtendedPriceAmount": 4.69, "MinimumAge": 21, "Quantity": 1, "*": "*"}], "TransactionBalance": 0.0, "TransactionSubTotal": 12.38, "TransactionTaxAmount": 0.0, "TransactionTotal": 12.38, "TransactionSequenceNumber": "*"} |
        | ["Pos/FinalizeOrder", {"OriginSystemId": "Unknown", "CustomerName": "John Doe", "FormatReceipt": {"PrintFormat": "NCRPRINTAPI", "Merchant": 1, "Customer": 1}, "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "022222222220", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 12.38} ]}] | {"OriginSystemId": "Unknown", "ItemList":[{"Description": "Age 21 Restricted", "ExtendedPriceAmount": 4.69, "MinimumAge": 21, "Quantity": 1, "*": "*"}], "TransactionBalance": 0.0, "TransactionSubTotal": 12.38, "TransactionTaxAmount": 0.0, "TransactionTotal": 12.38, "TransactionSequenceNumber": "*"} |


    @positive @fast
    Scenario Outline: Send a batch command with age restricted item with OriginSystemId that declines AR items to the POS,
                      the pos option 1521 does not change the behavior of processing of the transaction when the OriginSystemId disallows processing,
                      order is rejected and proper error code returned, KPS is not notified.
        # Default external age verification result is set to Yes
        Given the POS option 1521 is set to 1
        And the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS does not notify KPS about pending age verification

        Examples:
        | request      | response_data |
        | ["Pos/FinalizeOrder", {"OriginSystemId": "DisallowProc", "CustomerName": "John Doe", "FormatReceipt": {"PrintFormat": "NCRPRINTAPI", "Merchant": 1, "Customer": 1}, "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "022222222220", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 12.38} ]}] | {"ItemList": [{"Barcode": "022222222220", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}], "OriginSystemId": "DisallowProc", "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 7.69, "TransactionSequenceNumber": 0, "TransactionSubTotal": 7.69, "TransactionTaxAmount": 0.0, "TransactionTotal": 7.69} |
        | ["Pos/SubTotalOrder", {"OriginSystemId": "DisallowProc", "CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "022222222220", "Quantity": 1}]}] | {"ItemList": [{"Barcode": "022222222220", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 8.15, "TransactionSequenceNumber": 0, "TransactionSubTotal": 7.69, "TransactionTaxAmount": 0.46, "TransactionTotal": 8.15}  |
        | ["Pos/StoreOrder", {"OriginSystemId": "DisallowProc", "CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "0369369369", "Quantity": 1}]}]    | {"ItemList": [{"Barcode": "0369369369", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}], "OriginSystemId": "DisallowProc", "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 8.15, "TransactionSequenceNumber": 0, "TransactionSubTotal": 7.69, "TransactionTaxAmount": 0.46, "TransactionTotal": 8.15}  |



    @positive @fast
    Scenario Outline: Send a FinalizeOrder command with multiple age restricted items with OriginSystemId that accepts AR items,
                      order is processed and KPS notified about the highest restriction only.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS notifies KPS about pending age verification of <age> years

        Examples:
        | age | request      | response_data |
        | 21  | ["Pos/FinalizeOrder", {"OriginSystemId": "AllowProc", "CustomerName": "John Doe", "FormatReceipt": {"PrintFormat": "NCRPRINTAPI", "Merchant": 1, "Customer": 1}, "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "022222222220", "Quantity": 1}, {"Barcode": "0369369369", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 16.07} ]}] | {"ItemList":[{"Description": "Age 18 Restricted", "ExtendedPriceAmount": 3.69, "MinimumAge": 18, "Quantity": 1, "*": "*"}, {"Description": "Age 21 Restricted", "ExtendedPriceAmount": 4.69, "MinimumAge": 21, "Quantity": 1, "*": "*"}], "OriginSystemId": "AllowProc", "TransactionBalance": 0.0, "TransactionSubTotal": 16.07, "TransactionTaxAmount": 0.0, "TransactionTotal": 16.07, "TransactionSequenceNumber": "*"} |
        | 21  | ["Pos/FinalizeOrder", {"OriginSystemId": "AllowProc", "CustomerName": "John Doe", "FormatReceipt": {"PrintFormat": "NCRPRINTAPI", "Merchant": 1, "Customer": 1}, "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "0369369369", "Quantity": 1}, {"Barcode": "022222222220", "Quantity": 1}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 16.07} ]}] | {"ItemList":[{"Description": "Age 18 Restricted", "ExtendedPriceAmount": 3.69, "MinimumAge": 18, "Quantity": 1, "*": "*"}, {"Description": "Age 21 Restricted", "ExtendedPriceAmount": 4.69, "MinimumAge": 21, "Quantity": 1, "*": "*"}], "OriginSystemId": "AllowProc", "TransactionBalance": 0.0, "TransactionSubTotal": 16.07, "TransactionTaxAmount": 0.0, "TransactionTotal": 16.07, "TransactionSequenceNumber": "*"} |


    @positive @fast
    Scenario Outline: Send a FinalizeOrder command with multiple items with various age restriction features (disable over 30 button,
                      military ID, manager override, validate ID) and OriginSystemId that accepts AR items, order is processed
                      successfully and KPS notified about the highest restriction only. No special age verification frame is displayed.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS notifies KPS about pending age verification of <age> years
        And the POS displays main menu frame

        Examples:
        | age | request      | response_data |
        | 21  | ["Pos/FinalizeOrder", {"OriginSystemId": "AllowProc", "CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "0123456789", "Quantity": 2}, {"Barcode": "987654321", "Quantity": 3}, {"Barcode": "234565432", "Quantity": 4}, {"Barcode": "987656789", "Quantity": 5}, {"Barcode": "345676543", "Quantity": 6}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 117.57} ]}] | {"ItemList":[{"Description": "21 No Over Button", "ExtendedPriceAmount": 2.46, "MinimumAge": 21, "Quantity": 2}, {"Description": "Man Req Item", "ExtendedPriceAmount": 17.07, "MinimumAge": 21, "Quantity": 3}, {"Description": "Military ID", "ExtendedPriceAmount": 10.76, "MinimumAge": 21, "Quantity": 4}, {"Description": "ID Required", "ExtendedPriceAmount": 33.45, "MinimumAge": 21, "Quantity": 5}, {"Description": "Uber Item", "ExtendedPriceAmount": 46.14, "MinimumAge": 21, "Quantity": 6}], "OriginSystemId": "AllowProc", "TransactionBalance": 0.0, "TransactionSubTotal": 117.57, "TransactionTaxAmount": 0.0, "TransactionTotal": 117.57, "TransactionSequenceNumber": "*"} |


    @positive @fast
    Scenario Outline: Send a batch command with multiple items with various age restriction features (disable over 30 button,
                      military ID, manager override, validate ID) and OriginSystemId that declines AR items, order is
                      rejected and proper error code returned, KPS is not notified. No special age verification frame is displayed.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS does not notify KPS about pending age verification
        And the POS displays main menu frame

        Examples:
        | request      | response_data |
        | ["Pos/FinalizeOrder", {"OriginSystemId": "DisallowProc", "CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "0123456789", "Quantity": 2}, {"Barcode": "987654321", "Quantity": 3}, {"Barcode": "234565432", "Quantity": 4}, {"Barcode": "987656789", "Quantity": 5}, {"Barcode": "345676543", "Quantity": 6}, {"Type": "Tender", "ExternalId": "70000000023", "Amount": 117.57} ]}] | {"ItemList":[{"Barcode": "0123456789", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}, {"Barcode": "987654321", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}, {"Barcode": "234565432", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}, {"Barcode": "987656789", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}, {"Barcode": "345676543", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}], "OriginSystemId": "DisallowProc", "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 7.69, "TransactionSubTotal": 7.69, "TransactionTaxAmount": 0.0, "TransactionTotal": 7.69, "TransactionSequenceNumber": "*"} |
        | ["Pos/SubTotalOrder", {"CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "0123456789", "Quantity": 2}, {"Barcode": "987654321", "Quantity": 3}, {"Barcode": "234565432", "Quantity": 4}, {"Barcode": "987656789", "Quantity": 5}, {"Barcode": "345676543", "Quantity": 6}]}] | {"ItemList":[{"Barcode": "0123456789", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}, {"Barcode": "987654321", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}, {"Barcode": "234565432", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}, {"Barcode": "987656789", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}, {"Barcode": "345676543", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}], "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 8.15, "TransactionSubTotal": 7.69, "TransactionTaxAmount": 0.46, "TransactionTotal": 8.15} |
        | ["Pos/StoreOrder", {"OriginSystemId": "Unknown", "CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "0123456789", "Quantity": 2}, {"Barcode": "987654321", "Quantity": 3}, {"Barcode": "234565432", "Quantity": 4}, {"Barcode": "987656789", "Quantity": 5}, {"Barcode": "345676543", "Quantity": 6}]}]    | {"ItemList":[{"Barcode": "0123456789", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}, {"Barcode": "987654321", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}, {"Barcode": "234565432", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}, {"Barcode": "987656789", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}, {"Barcode": "345676543", "ReturnCode": 1047, "ReturnCodeDescription": "Customer does not meet age requirement."}], "OriginSystemId": "Unknown", "ReturnCode": 2000, "ReturnCodeDescription": "Composite action failed, please check response message for additional return codes.", "TransactionBalance": 8.15, "TransactionSubTotal": 7.69, "TransactionTaxAmount": 0.46, "TransactionTotal": 8.15, "TransactionSequenceNumber": "*"} |


    @negative @fast
    Scenario Outline: Send a non-batch command with age restricted item with OriginSystemId that accepts AR items,
                      OriginSystemId field is not accepted, DataNeeded response is returned.
        Given the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS displays the Age verification frame

        Examples:
        | request      | response_data |
        | ["Pos/SellItem", {"OriginSystemId": "AllowProc", "Barcode": "0369369369"}] | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}, {"Name": "InstantApproval", "Text": "Over"}], "DataType": "Date", "PromptId": 5072, "PromptText": "Enter Customer's Birthday (MM/DD/YYYY)"} |


    @positive @fast
    Scenario Outline: Send a StartTransaction command with OriginSystemId that accepts AR, then send a non-batch command
                      with age restricted item items, DataNeeded response is returned since it is not a batch request.
        Given the POS is in a ready to sell state
        And the application sent |<request1>| to the POS Connect
        When the application sends |<request2>| to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS displays the Age verification frame

        Examples:
        | request1 | request2      | response_data |
        | ["Pos/StartTransaction", {"OriginSystemId": "AllowProc"}] | ["Pos/SellItem", {"Barcode": "0369369369"}] | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}, {"Name": "InstantApproval", "Text": "Over"}], "DataType": "Date", "PromptId": 5072, "PromptText": "Enter Customer's Birthday (MM/DD/YYYY)"} |


    @positive @fast
    Scenario Outline: Recall a transaction stored using StoreOrder with OriginSystemId that accepts AR, DataNeeded response
                      is returned, POS displays Age verification frame.
        Given the POS is in a ready to sell state
        And the application sent a |<request>| to the POS Connect to store a transaction under Transaction Sequence Number
        When the application sends RecallTransaction command with last stored Sequence Number to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data contain |<response_data>|
        And the POS displays the Age verification frame

        Examples:
        | request | response_data |
        | ["Pos/StoreOrder", {"OriginSystemId": "AllowProc", "CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "0369369369", "Quantity": 1}]}] | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}, {"Name": "InstantApproval", "Text": "Over"}], "DataType": "Date", "PromptId": 5072, "PromptText": "Enter Customer's Birthday (MM/DD/YYYY)"} |


    @positive @fast
    Scenario Outline: Recall a transaction stored using StoreOrder with various age restriction features (disable over 30 button,
                      military ID, manager override, validate ID) and OriginSystemId that accepts AR, DataNeeded response
                      is returned, POS displays the corresponding Age verification frame.
        Given the POS is in a ready to sell state
        And the application sent a |<request>| to the POS Connect to store a transaction under Transaction Sequence Number
        When the application sends RecallTransaction command with last stored Sequence Number to the POS Connect
        Then the POS Connect response code is 200
        And POS Connect response data are |<response_data>|
        And the POS displays <frame>

        Examples:
        | frame | request | response_data |
        | the Age verification frame without the instant approval button | ["Pos/StoreOrder", {"OriginSystemId": "AllowProc", "CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "0123456789", "Quantity": 2}]}] | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}, {"Name": "MilitaryIdManualEntry", "Text": ""}], "DataType": "Date", "PromptId": 5072, "PromptText": "Enter Customer's Birthday (MM/DD/YYYY)"} |
        | restricted Age verification frame | ["Pos/StoreOrder", {"OriginSystemId": "AllowProc", "CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "987654321", "Quantity": 3}]}] | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}, {"Name": "ManualEntry", "Text": ""}], "DataType": "Date", "PromptId": 5072, "PromptText": "Scan/Swipe Customer's Drivers License"} |
        | the Age verification frame | ["Pos/StoreOrder", {"OriginSystemId": "AllowProc", "CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "234565432", "Quantity": 4}]}] | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}, {"Name": "InstantApproval", "Text": "Over"}, {"Name": "MilitaryIdManualEntry", "Text": ""}], "DataType": "Date", "PromptId": 5072, "PromptText": "Enter Customer's Birthday (MM/DD/YYYY)"} |
        | the Age verification frame | ["Pos/StoreOrder", {"OriginSystemId": "AllowProc", "CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "987656789", "Quantity": 5}]}] | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}, {"Name": "InstantApproval", "Text": "Over"}, {"Name": "MilitaryIdManualEntry", "Text": ""}], "DataType": "Date", "PromptId": 5072, "PromptText": "Enter Customer's Birthday (MM/DD/YYYY)"} |
        | restricted Age verification frame | ["Pos/StoreOrder", {"OriginSystemId": "AllowProc", "CustomerName": "John Doe", "ItemList": [{"RposId": "5070000318-70000000021-0-0", "Quantity": 1}, {"Barcode": "345676543", "Quantity": 6}]}] | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}, {"Name": "ManualEntry", "Text": ""}], "DataType": "Date", "PromptId": 5072, "PromptText": "Scan/Swipe Customer's Drivers License"} |