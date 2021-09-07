@pos
Feature: Support for exchange rate calculations between multiple currencies

Background:
  Given the POS has essential configuration
  And the POS has following tenders configured
   | description  | tender_id   | tender_type_id | exchange_rate | currency_symbol | external_id   |
   | Tender_A     | 12345       | 102            | 0.0005        | Kc              | 12345         |
   | Tender_B     | 23456       | 102            | 0.895         | @#              | 23456         |
   | Tender_C     | 34567       | 102            | 1.50          | ---             | 34567         |
   | Tender_D     | 45678       | 102            | 2.0123456789  | USD             | 45678         |
   | Tender_E     | 56789       | 102            | 999999        | GBP             | 56789         |


@fast @positive
Scenario Outline: Tender with exchange rate selected, Amount selection frame has a recalculated Amount due displayed
  Given the POS is in a ready to sell state
  And an item with barcode <item_barcode> is present in the transaction
  When the cashier presses the <tender> tender button with external id <external_id> and type id 102
  Then the POS displays Ask tender amount type-102 frame
  And the POS displays recalculated Balance due amount <recalculated_amount> and currency <currency>
  And an item <item_name> with price <item_price> is in the virtual receipt
  And an item <item_name> with price <item_price> is in the current transaction

  Examples:
   | tender    | item_barcode | item_price | item_name   | recalculated_amount | currency | external_id |
   | Tender_A  | 099999999990 | 0.99       | Sale Item A | 2120.00             | Kc       | 12345       |
   | Tender_B  | 099999999990 | 0.99       | Sale Item A | 1.18                | @#       | 23456       |
   | Tender_C  | 099999999990 | 0.99       | Sale Item A | 0.71                | ---      | 34567       |
   | Tender_D  | 088888888880 | 1.99       | Sale Item B | 1.06                | USD      | 45678       |

@fast @positive
Scenario Outline: Transaction tendered with foreign tender, VR and transaction has all info in default tender, quick buttons used
  Given the POS is in a ready to sell state
  And an item with barcode <item_barcode> is present in the transaction
  And the POS displays Amount selection frame after selecting <tender> tender with external id <external_id> and type id 102
  When the cashier tenders the transaction with <quick_button> on the current frame
  Then no transaction is in progress
  And a tender <tender> with amount <tendered_amount> is in the previous transaction
  And a tender <tender> with change amount <change_amount> is in the previous transaction

  Examples:
   | item_barcode | tender   | quick_button | tendered_amount | change_amount | external_id |
   | 099999999990 | Tender_A | exact-dollar | 1.06            | 0.00          | 12345       |
   | 088888888880 | Tender_B | next-dollar  | 2.69            | 0.56          | 23456       |
   | 088888888880 | Tender_C | preset-20    | 30.00           | 27.87         | 34567       |
   | 088888888880 | Tender_D | preset-20    | 40.25           | 38.12         | 45678       |

@fast @positive
Scenario Outline: Transaction tendered with foreign tender, VR and transaction has all info in default tender, manual entry used
  Given the POS is in a ready to sell state
  And an item with barcode <item_barcode> is present in the transaction
  When the cashier tenders the transaction with <paid_amount> in <tender> with external id <external_id> and type id 102
  Then no transaction is in progress
  And a tender <tender> with amount <recalculated_amount> is in the previous transaction
  And a tender <tender> with change amount <change_amount> is in the previous transaction

  Examples:
   | item_barcode | tender   | paid_amount  | recalculated_amount | change_amount | external_id |
   | 099999999990 | Tender_A | 2120.00      | 1.06                | 0.00          | 12345       |
   | 088888888880 | Tender_B | 2.50         | 2.24                | 0.11          | 23456       |

@fast @positive
Scenario Outline: Transaction partially tendered with foreign tender
  Given the POS is in a ready to sell state
  And an item with barcode <item_barcode> is present in the transaction
  When the cashier tenders the transaction with <paid_amount> in <tender> with external id <external_id> and type id 102
  Then an item <item_description> with price <item_price> is in the virtual receipt
  And an item <item_description> with price <item_price> is in the current transaction
  And a tender <tender> with amount <recalculated_amount> is in the virtual receipt
  And a tender <tender> with amount <recalculated_amount> is in the current transaction
  And the transaction's balance is <balance>

  Examples:
   | item_barcode | tender   | paid_amount | item_description | item_price | recalculated_amount | balance | external_id |
   | 099999999990 | Tender_A | 1000.00     | Sale Item A      | 0.99       | 0.50                | 0.56    | 12345       |
   | 088888888880 | Tender_B | 1.99        | Sale Item B      | 1.99       | 1.78                | 0.35    | 23456       |

@fast @positive @manual
Scenario Outline: Tender with huge exchange rate should always round amount due to at least 0.01 (not 0)
  Given the POS is in a ready to sell state
  And an item with barcode <item_barcode> is present in the transaction
  When the cashier presses the <tender> tender button
  Then the POS displays Ask tender amount type-102 frame
  And the POS displays recalculated Balance due amount <recalculated_amount> and currency <currency>

  Examples:
   | item_barcode | tender   | recalculated_amount | currency |
   | 099999999990 | Tender_E | 0.01                | GBP      |
