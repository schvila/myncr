@pos
Feature: Quantity restrictions
POS is able to set quantity and/or amount limits for groups of items and forbid adding items which would exceed these limits.

Background: The POS needs to have some items configured to manipulate with them.
  Given the POS has essential configuration
  # Consolidate line items set to YES
  And the POS option 901 is set to 1
  And the pricebook contains retail items
   | description           | barcode    | item_id   | modifier1_id | price | unit_packing_id | pack_size |
   | can of beer           | 0789000002 | 789000002 | 0            | 2.1   | 100000          | 1         |
   | bottle of beer        | 0789000003 | 789000003 | 0            | 2.2   | 100000          | 1         |
   | sixpack of beer       | 0789000005 | 789000005 | 0            | 7.5   | 666666          | 6         |
   | box of champagne      | 0789000103 | 789000103 | 0            | 27.5  | 999999          | 4         |
   | wine bottle           | 0789000101 | 789000101 | 0            | 3.5   | 100000          | 1         |
   | vodka bottle          | 0789000201 | 789000201 | 0            | 10    | 100000          | 1         |
   | big scotch bottle     | 0789000202 | 789000202 | 0            | 15    | 100000          | 1         |
   | martini bottle        | 0789000203 | 789000203 | 0            | 12    | 100000          | 1         |
   | bisquits              | 0789000301 | 789000301 | 0            | 1.1   | 100000          | 1         |
   | limited box of sweets | 0789000306 | 789000306 | 0            | 3.9   | 111111          | 10        |
  And the pricebook contains retail item groups
   | description    | external_id      | group_id |
   | alcohol        | Rpos-alc-a       | 10300000 |
   | alcohol-more   | Rpos-alc-m       | 10600000 |
   | limited        | Rpos-limited     | 10400000 |
   | non-restricted | Rpos-restricted  | 10500000 |
  And retail item group with id 10300000 contains items
   | item_id   |
   | 789000002 |
   | 789000101 |
   | 789000201 |
  And retail item group with id 10600000 contains items
   | item_id   |
   | 789000202 |
   | 789000203 |
  And retail item group with id 10400000 contains items
   | item_id   |
   | 789000306 |
   | 789000301 |
  And retail item group with id 10500000 contains items
   | item_id   |
   | 789000005 |
   | 789000103 |
   | 789000003 |
  And quantity restriction groups contain items
   | sale_quantity_id  | name  | retail_item_group_id | transaction_limit | item_id   | modifier1_id | quantity |
   | 6000323           | First | 10300000             | 5                 | 789000002 | 0            | 1        |
   | 6000323           | First | 10300000             | 5                 | 789000101 | 0            | 2        |
   | 6000323           | First | 10300000             | 5                 | 789000201 | 0            | 3        |
   | 6000324           | Sec   | 10600000             | 7                 | 789000202 | 0            | 5        |
   | 6000324           | Sec   | 10600000             | 7                 | 789000203 | 0            | 3        |
   | 6000324           | Sec   | 10600000             | 7                 | 789000204 | 0            | 7        |
   | 6000325           | Third | 10500000             | 200               | 789000005 | 0            | 60       |
   | 6000325           | Third | 10500000             | 200               | 789000103 | 0            | 70       |
   | 6000325           | Third | 10500000             | 200               | 789000003 | 0            | 10       |

@fast @positive
Scenario Outline: Attempt to add more items than the transaction limit, item is disallowed, an error is displayed
  Given the POS is in a ready to sell state
  And an item with barcode <barcode> is present in the transaction <limit> times
  When the cashier scans a barcode <barcode>
  Then the POS displays Item count exceeds maximum error
  And an item <description> with price <final_price> and quantity <limit> is in the consolidated current transaction

  Examples:
   | description  | barcode    | final_price | limit |
   | can of beer  | 0789000002 | 10.5        | 5     |
   | wine bottle  | 0789000101 | 7.0         | 2     |


@fast @positive
Scenario Outline: Attempt to add non-restricted item in the transaction, after the restricted item limit is reached, items appear in the transaction
  Given the POS is in a ready to sell state
  And an item with barcode <barcode1> is present in the transaction <limit> times
  When the cashier scans a barcode <barcode2>
  Then an item <description1> with price <final_price1> and quantity <limit> is in the consolidated current transaction
  And an item <description2> with price <price2> and type <item_type2> is in the current transaction

  Examples:
   | description1 | barcode1   | final_price1 | limit | description2          | barcode2   | price2 | item_type2 |
   | wine bottle  | 0789000101 | 7.0          | 2     | limited box of sweets | 0789000306 | 3.9    | 1          |
   | vodka bottle | 0789000201 | 10.0         | 1     | bisquits              | 0789000301 | 1.1    | 1          |


@fast @positive
Scenario Outline: Attempt to add different items from the same group in the transaction, quantity limit is calculated together,
                  an error is displayed in attempt to add more items than transaction limit allows
  Given the POS is in a ready to sell state
  And an item with barcode <barcode1> is present in the transaction <amount1> times
  And an item with barcode <barcode2> is present in the transaction <amount2> times
  When the cashier scans a barcode <barcode1>
  Then the POS displays Item count exceeds maximum error
  And an item <description1> with price <final_price1> and quantity <limit1> is in the consolidated current transaction
  And an item <description2> with price <final_price2> and quantity <limit2> is in the consolidated current transaction

  Examples:
   | description1 | barcode1   | final_price1 | description2 | barcode2   | final_price2 | limit1 | limit2 | amount1 | amount2 |
   | can of beer  | 0789000002 | 6.3          | wine bottle  | 0789000101 | 3.5          | 3      | 1      | 3       | 1       |
   | wine bottle  | 0789000101 | 3.5          | vodka bottle | 0789000201 | 10.0         | 1      | 1      | 1       | 1       |


@fast @positive
Scenario Outline: Attempt to add items from different groups in the transaction, quantity limit is calculated separately for each of them,
                  an error is displayed in attempt to add some of the items more than transaction limit allows
  Given the POS is in a ready to sell state
  And an item with barcode <barcode1> is present in the transaction <limit1> times
  When the cashier scans barcode <barcode2> <limit2> times
  Then an item <description1> with price <final_price1> and quantity <limit1> is in the consolidated current transaction
  And an item <description2> with price <final_price2> and quantity <limit2> is in the consolidated current transaction

  Examples:
   | description1 | barcode1   | final_price1 | limit1 | description2      | barcode2   | final_price2 | limit2 |
   | wine bottle  | 0789000101 | 7.0          | 2      | martini bottle    | 0789000203 | 24.0         | 2      |
   | vodka bottle | 0789000201 | 10.0         | 1      | big scotch bottle | 0789000202 | 15.0         | 1      |


@fast @positive
Scenario Outline: Attempt to change the quantity of restricted item to exceed transaction limit, an error is displayed
  Given the POS is in a ready to sell state
  And an item with barcode <barcode> is present in the transaction <limit> times
  When the cashier updates quantity of the item <description> to <quantity>
  Then the POS displays Item count exceeds maximum error
  And an item <description> with price <final_price> and quantity <limit> is in the consolidated current transaction

  Examples:
   | description       | barcode    | final_price | limit | quantity |
   | big scotch bottle | 0789000202 | 15.0        | 1     | 2        |
   | martini bottle    | 0789000203 | 24.0        | 2     | 3        |


@fast @positive
Scenario Outline: Maximum number of the restricted items is added to the transaction, attempt to recall a transaction containing items from the same group, an error is displayed
  Given the POS is in a ready to sell state
  And the cashier stored a transaction containing <limit> items with barcode <barcode>
  And an item with barcode <barcode> is present in the transaction <limit> times
  When the cashier recalls the last stored transaction
  Then the POS displays Item count exceeds maximum error
  And an item <description> with price <price> is in the current transaction

  Examples:
   | description       | barcode    | price | limit | quantity |
   | big scotch bottle | 0789000202 | 15.0  | 1     | 2        |
   | martini bottle    | 0789000203 | 12.0  | 2     | 3        |


@fast @positive
Scenario Outline: Maximum number of the restricted items is added to the transaction, attempt to recall a transaction containing maximum number of items from different group,
                  items from both groups appear in the transaction
  Given the POS is in a ready to sell state
  And the cashier stored a transaction containing <limit1> items with barcode <barcode1>
  And an item with barcode <barcode2> is present in the transaction <limit2> times
  When the cashier recalls the last stored transaction
  Then an item <description1> with price <final_price1> and quantity <limit1> is in the consolidated current transaction
  And an item <description2> with price <final_price2> and quantity <limit2> is in the consolidated current transaction

  Examples:
   | description1     | barcode1   | final_price1 | limit1 | description2   | barcode2   | final_price2 | limit2 |
   | sixpack of beer  | 0789000005 | 22.5         | 3      | bottle of beer | 0789000003 | 4.4          | 2      |
   | box of champagne | 0789000103 | 55.0         | 2      | bottle of beer | 0789000003 | 13.2         | 6      |

@fast @positive
Scenario Outline: Attempt to add a restricted items in the transaction, after one restricted item reached transaction limit is voided, items appear in the transaction
  Given the POS is in a ready to sell state
  And an item with barcode <barcode> is present in the transaction <limit> times
  And the cashier voided the <description>
  When the cashier scans a barcode <barcode>
  Then an item <description> with price <final_price> and quantity <limit> is in the consolidated current transaction

  Examples:
   | description       | barcode    | final_price | limit |
   | big scotch bottle | 0789000202 | 15.0        | 1     |
   | martini bottle    | 0789000203 | 24.0        | 2     |


@fast @positive
Scenario Outline: Attempt to add restricted item from Price check menu more than transaction limit allows, an error is displayed
  Given the POS is in a ready to sell state
  And an item with barcode <barcode> is present in the transaction <limit> times
  When the cashier adds item <barcode> from the price check menu
  Then the POS displays Item count exceeds maximum error
  And an item <description> with price <final_price> and quantity <limit> is in the consolidated current transaction

  Examples:
   | description       | barcode    | final_price | limit |
   | big scotch bottle | 0789000202 | 15.0        | 1     |
   | martini bottle    | 0789000203 | 24.0        | 2     |

@negative @fast @pos_connect
Scenario Outline: Send SellItem command to exceed allowed item quantity, item is not added to the transaction.
    Given the POS is in a ready to sell state
    And an item with barcode 0789000002 is present in the transaction
    And an item can of beer with price 2.1 has changed quantity to 5
    When the application sends |<request>| to the POS Connect
    Then the POS Connect response code is 200
    And the POS Connect message type is Pos/SellItemResponse
    And POS Connect response data contain |<response_data>|

    Examples:
    | request     | response_data |
    | ["Pos/SellItem", {"Barcode": "0789000002"}] | {"ReturnCodeDescription": "Item count exceeds maximum.", "ReturnCode": 1094, "TransactionSequenceNumber": "*"} |
