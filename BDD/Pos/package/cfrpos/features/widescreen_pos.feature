@pos @widescreen_pos @manual
Feature: This feature file tests wide screen POS layout. Since BDD is not suitable for testing GUI, this script verifies
         that the proper resolution is used and that frames like pump bar and tender bar are extended (30 pumps instead
         of 22 and 6 tenders instead of 4) by using components which would not be displayed on a low res POS.

    Background:
        Given the POS has essential configuration
        And the POS screen resolution is 1366 and corresponding relay files are configured
        And the POS has the feature PosApiServer enabled
        And the POS has 27 pumps configured
        And the POS has following tenders configured
        | tender_id  | description      | tender_type_id | tender_mode | exchange_rate | currency_symbol | external_id  |
        | 100        | Cash 100         | 1              | 39854592    | 1             | $               | 100          |
        | 200        | Cash 200         | 1              | 39854592    | 1             | $               | 200          |
        | 300        | Cash 300         | 1              | 39854592    | 1             | $               | 300          |
        | 400        | Cash 400         | 1              | 39854592    | 1             | $               | 400          |
        | 500        | Cash 500         | 1              | 39854592    | 1             | $               | 500          |
        | 600        | Cash 600         | 1              | 39854592    | 1             | $               | 600          |
        | 700        | Cash 700         | 1              | 39854592    | 1             | $               | 700          |
        | 800        | Cash 800         | 1              | 39854592    | 1             | $               | 800          |
        | 900        | Cash 900         | 1              | 39854592    | 1             | $               | 900          |

    @positive
    Scenario Outline: Dispense fuel on a pump which would not be present on low res POS, fuel item appears in the transaction
        Given the POS is in a ready to sell state
        And the customer dispensed <grade> for <price> price at pump <pump_id>
        When the cashier presses Pay button
        Then an item <fuel_item> with price <price> is in the virtual receipt

        Examples:
        | grade  | pump_id | price | fuel_item      |
        | Diesel | 27      | 10.00 | 10.000G Diesel |


    @positive
    Scenario Outline: Tender a transaction with a tender which would not be present on low res POS, transaction is finalized
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the cashier presses the <tender> tender button with external id <external_id> and type id <tender_type_id> on the current frame
        Then the POS displays Ask tender amount <tender> frame

        Examples:
        | tender | external_id | tender_type_id |
        | Cash   | 500         | 1              |


    @fast @positive @pos_connect
    Scenario Outline: Send SignOff request to POS and validate if all the configured tenders are present in Response
        Given the POS option 1448 is set to 2
        And the POS option 1908 is set to 2
        And the POS option 1909 is set to 1
        And the POS is in a ready to sell state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data contain |<response_data>|

        Examples:
        | request                             | response_data                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
        | ["Pos/SignOff", {"Password": 1234}] | {"AvailableOperations": [{"Name": "Cancel", "Text": ""}], "DataType": "ListSelection", "ListSelections": [{"Id": 70000000023, "Text": "Cash"}, {"Id": 100, "Text": "Cash 100"}, {"Id": 200, "Text": "Cash 200"}, {"Id": 300, "Text": "Cash 300"}, {"Id": 400, "Text": "Cash 400"}, {"Id": 500, "Text": "Cash 500"}, {"Id": 600, "Text": "Cash 600"}, {"Id": 700, "Text": "Cash 700"}, {"Id": 800, "Text": "Cash 800"}, {"Id": 900, "Text": "Cash 900"}], "PromptId": 5715, "PromptText": "Ending Counts Tender Selection"} |


    @fast @positive @pos_connect
    Scenario Outline: Send SignIn request to POS and validate if all the configured tenders are present in Response
        Given the POS option 1448 is set to 1
        And the POS option 1908 is set to 2
        And the POS option 1909 is set to 1
        And the POS is in a ready to start shift state
        When the application sends |<request>| to the POS Connect
        Then the POS Connect response code is 200
        And the POS Connect message type is Pos/DataNeeded
        And POS Connect response data contain |<response_data>|

        Examples:
         | request                            | response_data                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
         | ["Pos/SignOn", {"Password": 1234}] | {"DataType": "ListSelection", "ListSelections": [{"Id": 70000000023, "Text": "Cash"}, {"Id": 100, "Text": "Cash 100"}, {"Id": 200, "Text": "Cash 200"}, {"Id": 300, "Text": "Cash 300"}, {"Id": 400, "Text": "Cash 400"}, {"Id": 500, "Text": "Cash 500"}, {"Id": 600, "Text": "Cash 600"}, {"Id": 700, "Text": "Cash 700"}, {"Id": 800, "Text": "Cash 800"}, {"Id": 900, "Text": "Cash 900"}], "PromptId": 5715, "PromptText": "Starting Counts Tender Selection"} |
