@pos
Feature: Support for JUUL quantity restrictions and enhanced age verification

Background:
  Given the POS has essential configuration
  # JUUL restrictions are enabled
  And the POS option 1385 is set to 1
  # Quantity restrictions for items in group A
  And the POS option 1386 is set to 2
  # Quantity restrictions for items in group B
  And the POS option 1387 is set to 5
  # Quantity restrictions for items in group C
  And the POS option 1388 is set to 3
  # Consolidate line items set to YES
  And the POS option 901 is set to 1
  # Consolidate on subtotal set to YES
  And the POS option 922 is set to 1
  # Age verification failure tracking to YES
  And the POS option 1024 is set to 1
  And the pricebook contains retail items
   | description       | price  | age_restriction | barcode      | item_id      | modifier1_id |
   | JUUL A            | 10.00  | 18              | 1111111      | 1111111      | 0            |
   | JUUL B            | 20.00  | 18              | 2222222      | 2222222      | 0            |
   | JUUL C            | 30.00  | 18              | 3333333      | 3333333      | 0            |
   | JUUL AB           | 40.00  | 18              | 4444444      | 4444444      | 0            |
   | JUUL AC           | 50.00  | 18              | 5555555      | 5555555      | 0            |
   | JUUL BC           | 60.00  | 18              | 6666666      | 6666666      | 0            |
   | JUUL ABC          | 70.00  | 18              | 7777777      | 7777777      | 0            |
   | JUUL B 4-pack     | 80.00  | 18              | 8888888      | 8888888      | 0            |
   | JUUL B 8-pack     | 160.00 | 18              | 9999999      | 9999999      | 0            |
   | Age 21 Restricted | 4.69   | 21              | 022222222220 | 990000000009 | 990000000007 |
  And the pricebook contains retail item groups
   | description  | external_id | group_id |
   | JUUL Group A | RposETob-A  | 12345678 |
   | JUUL Group B | RposETob-B  | 23456789 |
   | JUUL Group C | RposETob-C  | 34567890 |
  # Assign items to JUUL Group A
  And retail item group with id 12345678 contains items
   | items    | item_id |
   | JUUL A   | 1111111 |
   | JUUL AB  | 4444444 |
   | JUUL AC  | 5555555 |
   | JUUL ABC | 7777777 |
  # Assign items to JUUL Group B
  And retail item group with id 23456789 contains items
   | items         | item_id |
   | JUUL B        | 2222222 |
   | JUUL AB       | 4444444 |
   | JUUL BC       | 6666666 |
   | JUUL ABC      | 7777777 |
   | JUUL B 4-pack | 8888888 |
   | JUUL B 8-pack | 9999999 |
  # Assign items to JUUL Group C
  And retail item group with id 34567890 contains items
   | items    | item_id |
   | JUUL C   | 3333333 |
   | JUUL AC  | 5555555 |
   | JUUL BC  | 6666666 |
   | JUUL ABC | 7777777 |


@fast @positive
Scenario Outline: JUUL item requires age verification by ID scan or swipe
  Given the POS is in a ready to sell state
  When the cashier scans a barcode <item_barcode>
  Then the POS displays JUUL Age verification frame
  And the instant verification button is not displayed on the current frame
  And the manual entry keyboard is not displayed on the current frame
  And an item <item_name> with price <item_price> is not in the virtual receipt
  And an item <item_name> with price <item_price> is not in the current transaction

  Examples:
   | item_name | item_barcode | item_price |
   | JUUL A    | 1111111      | 10.00      |
   | JUUL B    | 2222222      | 20.00      |
   | JUUL C    | 3333333      | 30.00      |
   | JUUL AB   | 4444444      | 40.00      |
   | JUUL AC   | 5555555      | 50.00      |
   | JUUL BC   | 6666666      | 60.00      |
   | JUUL ABC  | 7777777      | 70.00      |

@fast @positive
Scenario Outline: JUUL item requires additional validation after ID scan
  Given the POS is in a ready to sell state
  And the POS displays JUUL Age verification frame after scanning a JUUL item barcode <item_barcode>
  When the cashier scans a driver's license <drivers_license>
  Then the POS displays ID validation frame

  Examples:
   | drivers_license | customer_name | customer_ID_number | item_barcode |
   | valid DL        | John Doe      | 12345678987654321  | 1111111      |

@fast @positive
Scenario Outline: JUUL item requires additional validation after ID swipe
  Given the POS is in a ready to sell state
  And the POS displays JUUL Age verification frame after scanning a JUUL item barcode <item_barcode>
  When the cashier swipes a driver's license <drivers_license>
  Then the POS displays ID validation frame

  Examples:
   | drivers_license | customer_name | customer_ID_number | item_barcode |
   | valid DL        | John Doe      | 12345678987654321  | 1111111      |

@fast @positive
Scenario Outline: Cashier selects Go back on the JUUL Age verification prompt, JUUL item is not added
  Given the POS is in a ready to sell state
  And the POS displays JUUL Age verification frame after scanning a JUUL item barcode <item_barcode>
  When the cashier selects Go back button
  Then the POS displays main menu frame
  And an item CANC: <item_name> with price <item_price> is in the virtual receipt
  And an item <item_name> with price <item_price> is in the current transaction with status IGNORE_PRICE

  Examples:
   | item_name | item_barcode | item_price |
   | JUUL A    | 1111111      | 10.00      |

@fast @positive
Scenario Outline: Cashier selects No on the ID validation prompt, JUUL item is not added
  Given the POS is in a ready to sell state
  And the POS displays ID validation frame after scanning a JUUL item barcode <item_barcode>
  When the cashier selects No button
  Then the POS displays main menu frame
  And an item FAIL: <item_name> with price <item_price> is in the virtual receipt
  And an item <item_name> with price <item_price> is in the current transaction with status IGNORE_PRICE

  Examples:
   | item_name | item_barcode | item_price |
   | JUUL A    | 1111111      | 10.00      |

@fast @positive
Scenario Outline: Cashier selects Yes on the ID validation prompt, JUUL item is added
  Given the POS is in a ready to sell state
  And the POS displays ID validation frame after scanning a JUUL item barcode <item_barcode>
  When the cashier selects Yes button
  Then the POS displays main menu frame
  And an item <item_name> with price <item_price> is in the virtual receipt
  And an item <item_name> with price <item_price> is in the current transaction

  Examples:
   | item_name | item_barcode | item_price |
   | JUUL A    | 1111111      | 10.00      |

@fast @positive
Scenario Outline: JUUL quantity limits - over the limit (change quantity button) is disallowed
  Given the POS is in a ready to sell state
  And a JUUL item with barcode <item_barcode> is present in the transaction
  When the cashier updates quantity of the item <item_name> to <quantity>
  Then the POS displays Item count exceeds maximum error
  And an item <item_name> with price <item_price> and quantity 1 is in the virtual receipt
  And an item <item_name> with price <item_price> and quantity 1 is in the current transaction

  Examples:
   | item_name | item_barcode | item_price | quantity |
   | JUUL A    | 1111111      | 10.00      | 3        |
   | JUUL B    | 2222222      | 20.00      | 6        |
   | JUUL C    | 3333333      | 30.00      | 4        |

@fast @positive
Scenario Outline: JUUL quantity limits - over the limit (repeated scan of the same item) is disallowed
  Given the POS is in a ready to sell state
  And a JUUL item <item_name> with barcode <item_barcode> is present in the transaction <allowed_quantity> times
  When the cashier scans a barcode <item_barcode>
  Then the POS displays Item count exceeds maximum error
  And an item <item_name> with price <item_total> and quantity <allowed_quantity> is in the virtual receipt
  And an item <item_name> with price <item_total> and quantity <allowed_quantity> is in the current transaction

  Examples:
   | item_name | item_barcode | item_total | allowed_quantity |
   | JUUL A    | 1111111      | 20.00      | 2                |
   | JUUL B    | 2222222      | 100.00     | 5                |
   | JUUL C    | 3333333      | 90.00      | 3                |

@fast @positive
Scenario Outline: JUUL quantity limits - over the limit (combination of items in the same group) is disallowed
  Given the POS is in a ready to sell state
  And a JUUL item <item_1_name> with barcode <item_1_barcode> is present in the transaction <item_1_quantity> times
  And a JUUL item <item_2_name> with barcode <item_2_barcode> is present in the transaction <item_2_quantity> times
  When the cashier scans a barcode <item_2_barcode>
  Then the POS displays Item count exceeds maximum error
  And an item <item_1_name> with price <item_1_total> and quantity <item_1_quantity> is in the virtual receipt
  And an item <item_1_name> with price <item_1_total> and quantity <item_1_quantity> is in the current transaction
  And an item <item_2_name> with price <item_2_total> and quantity <item_2_quantity> is in the virtual receipt
  And an item <item_2_name> with price <item_2_total> and quantity <item_2_quantity> is in the current transaction

  Examples:
   | item_1_name | item_1_barcode | item_1_total | item_1_quantity | item_2_name | item_2_barcode | item_2_total | item_2_quantity |
   | JUUL A      | 1111111        | 10.00        | 1               | JUUL AB     | 4444444        | 40.00        | 1               |
   | JUUL B      | 2222222        | 60.00        | 3               | JUUL BC     | 6666666        | 120.00       | 2               |
   | JUUL C      | 3333333        | 60.00        | 2               | JUUL AC     | 5555555        | 50.00        | 1               |

@fast @positive
Scenario Outline: JUUL quantity limits - multipack is considered as a single item
  Given the POS is in a ready to sell state
  When the cashier adds a JUUL item with barcode <item_barcode>
  Then the POS displays main menu frame
  And an item <item_name> with price <item_price> is in the virtual receipt
  And an item <item_name> with price <item_price> is in the current transaction

  Examples:
   | item_name     | item_barcode | item_price |
   | JUUL B 4-pack | 8888888      | 80.00      |
   | JUUL B 8-pack | 9999999      | 160.00     |

@fast @positive
Scenario Outline: JUUL quantity limits - under the limit (removing and reintroducing items) is allowed
  Given the POS is in a ready to sell state
  And a JUUL item <item_1_name> with barcode <item_1_barcode> is present in the transaction 2 times
  And a JUUL item with barcode <item_2_barcode> is present in the transaction
  And the cashier voided the <item_1_name>
  When the cashier scans a barcode <item_2_barcode>
  Then the POS displays main menu frame
  And an item <item_1_name> with price <item_1_total> and quantity 1 is in the virtual receipt
  And an item <item_1_name> with price <item_1_total> and quantity 1 is in the current transaction
  And an item <item_2_name> with price <item_2_total> and quantity 2 is in the consolidated virtual receipt
  And an item <item_2_name> with price <item_2_total> and quantity 2 is in the consolidated current transaction

  Examples:
   | item_1_name | item_1_barcode | item_1_total | item_2_name | item_2_barcode | item_2_total |
   | JUUL AC     | 5555555        | 50.00        | JUUL C      | 3333333        | 60.00        |

@fast @positive
Scenario Outline: JUUL quantity limits - over the limit (removing and reintroducing items) is disallowed
  Given the POS is in a ready to sell state
  And a JUUL item <item_1_name> with barcode <item_1_barcode> is present in the transaction 2 times
  And the cashier voided the <item_1_name>
  And the cashier voided the <item_1_name>
  And a JUUL item <item_2_name> with barcode <item_2_barcode> is present in the transaction <item_2_quantity> times
  When the cashier scans a barcode <item_2_barcode>
  Then the POS displays Item count exceeds maximum error
  And an item <item_1_name> with price <item_1_price> is not in the virtual receipt
  And an item <item_1_name> with price <item_1_price> is not in the current transaction
  And an item <item_2_name> with price <item_2_total> and quantity <item_2_quantity> is in the virtual receipt
  And an item <item_2_name> with price <item_2_total> and quantity <item_2_quantity> is in the current transaction

  Examples:
   | item_1_name | item_1_barcode | item_1_price | item_2_name | item_2_barcode | item_2_total | item_2_quantity |
   | JUUL ABC    | 7777777        | 70.00        | JUUL C      | 3333333        | 90.00        | 3               |

@fast @positive
Scenario Outline: Non-JUUL age restricted items can still be approved with manual entry
  Given the POS is in a ready to sell state
  And the POS displays Age verification frame after scanning an item barcode <item_barcode>
  When the cashier manually enters the customer's birthday <birthday>
  Then the POS displays main menu frame
  And an item <item_name> with price <item_price> is in the virtual receipt
  And an item <item_name> with price <item_price> is in the current transaction

  Examples:
   | item_barcode | birthday    | item_name         | item_price |
   | 022222222220 | 08-29-1989  | Age 21 Restricted | 4.69       |

@fast @positive
Scenario Outline: Non-JUUL age restricted items can still be approved with instant approval button
  Given the POS is in a ready to sell state
  And the POS displays Age verification frame after scanning an item barcode <item_barcode>
  When the cashier presses the instant approval button
  Then the POS displays main menu frame
  And an item <item_name> with price <item_price> is in the virtual receipt
  And an item <item_name> with price <item_price> is in the current transaction

  Examples:
   | item_barcode | item_name         | item_price |
   | 022222222220 | Age 21 Restricted | 4.69       |

@fast @positive
Scenario Outline: Non-JUUL age restricted items require additional validation after ID swipe
  Given the POS is in a ready to sell state
  And the POS displays Age verification frame after scanning an item barcode <item_barcode>
  When the cashier swipes a driver's license <drivers_license>
  Then the POS displays ID validation frame

  Examples:
   | item_barcode | item_name         | drivers_license |
   | 022222222220 | Age 21 Restricted | valid DL        |

@fast @positive
Scenario Outline: Non-JUUL age restricted items require additional validation after ID scan
  Given the POS is in a ready to sell state
  And the POS displays Age verification frame after scanning an item barcode <item_barcode>
  When the cashier scans a driver's license <drivers_license>
  Then the POS displays ID validation frame

  Examples:
   | item_barcode | item_name         | drivers_license |
   | 022222222220 | Age 21 Restricted | valid DL        |

@fast @positive
Scenario Outline: JUUL forces age reverification by ID if previous one was manual entry
  Given the POS is in a ready to sell state
  And an age restricted item with barcode <item_1_barcode> is present in the transaction after manual entry verification
  When the cashier scans a barcode <item_2_barcode>
  Then the POS displays JUUL Age verification frame
  And the instant verification button is not displayed on the current frame
  And the manual entry keyboard is not displayed on the current frame
  And an item <item_2_name> with price <item_2_price> is not in the virtual receipt
  And an item <item_2_name> with price <item_2_price> is not in the current transaction

  Examples:
   | item_1_barcode | item_2_name | item_2_barcode | item_2_price |
   | 022222222220   | JUUL A      | 1111111        | 10.00        |

@fast @positive
Scenario Outline: JUUL forces age reverification by ID if previous one (non-JUUL) was instant approval button
  Given the POS is in a ready to sell state
  And an age restricted item with barcode <item_1_barcode> is present in the transaction after instant verification
  When the cashier scans a barcode <item_2_barcode>
  Then the POS displays JUUL Age verification frame
  And the instant verification button is not displayed on the current frame
  And the manual entry keyboard is not displayed on the current frame
  And an item <item_2_name> with price <item_2_price> is not in the virtual receipt
  And an item <item_2_name> with price <item_2_price> is not in the current transaction

  Examples:
   | item_1_barcode | item_2_name | item_2_barcode | item_2_price |
   | 022222222220   | JUUL A      | 1111111        | 10.00        |

@fast @positive
Scenario Outline: JUUL does not force age reverification by ID if previous one (non-JUUL) was driver's license scan
  Given the POS is in a ready to sell state
  And an age restricted item with barcode <item_1_barcode> is present in the transaction after driver's license scan verification
  When the cashier scans a barcode <item_2_barcode>
  Then the POS displays main menu frame
  And an item <item_1_name> with price <item_1_price> is in the virtual receipt
  And an item <item_1_name> with price <item_1_price> is in the current transaction
  And an item <item_2_name> with price <item_2_price> is in the virtual receipt
  And an item <item_2_name> with price <item_2_price> is in the current transaction

  Examples:
   | item_1_name       | item_1_barcode | item_1_price | item_2_name | item_2_barcode | item_2_price |
   | Age 21 Restricted | 022222222220   | 4.69         | JUUL A      | 1111111        | 10.00      |

@fast @positive
Scenario Outline: JUUL does not force age reverification by ID if previous one (non-JUUL) was driver's license swipe
  Given the POS is in a ready to sell state
  And an age restricted item with barcode <item_1_barcode> is present in the transaction after driver's license swipe verification
  When the cashier scans a barcode <item_2_barcode>
  Then the POS displays main menu frame
  And an item <item_1_name> with price <item_1_price> is in the virtual receipt
  And an item <item_1_name> with price <item_1_price> is in the current transaction
  And an item <item_2_name> with price <item_2_price> is in the virtual receipt
  And an item <item_2_name> with price <item_2_price> is in the current transaction

  Examples:
   | item_1_name       | item_1_barcode | item_1_price | item_2_name | item_2_barcode | item_2_price |
   | Age 21 Restricted | 022222222220   | 4.69         | JUUL A      | 1111111        | 10.00      |

@fast @positive
Scenario Outline: POS displays Customer does not meet age requirement when items are added after instant/manual entry verification and underage driver's license is swiped
  Given the POS is in a ready to sell state
  And an age restricted item with barcode <item_1_barcode> is present in the transaction after instant verification
  And the POS displays JUUL Age verification frame after scanning a JUUL item barcode <item_2_barcode>
  When the cashier swipes a driver's license <drivers_license>
  Then the POS displays an Error frame saying Customer does not meet age requirement

  Examples:
   | item_1_name       | item_1_barcode | item_2_name | item_2_barcode | item_2_price | drivers_license |
   | Age 21 Restricted | 022222222220   | JUUL A      | 1111111        | 10.00        | underage DL     |

@fast @positive
Scenario Outline: Items added after instant/manual entry verification are listed for cashier to remove when underage driver's licence is swiped
  Given the POS is in a ready to sell state
  And an age restricted item with barcode <item_1_barcode> is present in the transaction after instant verification
  And the POS displays an Error frame saying Customer does not meet age requirement after scanning a JUUL item barcode <item_2_barcode> and scanning a driver's license <drivers_license>
  When the cashier selects Go back button
  Then the POS displays a list of previously added age restricted items to remove which contains <item_1_name>
  And an item <item_2_name> with price <item_2_price> is not in the virtual receipt
  And an item <item_2_name> with price <item_2_price> is not in the current transaction

  Examples:
   | item_1_name       | item_1_barcode | item_2_name | item_2_barcode | item_2_price | drivers_license |
   | Age 21 Restricted | 022222222220   | JUUL A      | 1111111        | 10.00        | underage DL     |

@fast @positive
Scenario Outline: Items added after instant/manual entry verification are removed from transaction after the cashier acknowledges
the prompt with listed items to remove when an underage driver's licence is swiped
  Given the POS is in a ready to sell state
  And an age restricted item with barcode <item_1_barcode> is present in the transaction after instant verification
  And the POS displays an Error frame saying Customer does not meet age requirement after scanning a JUUL item barcode <item_2_barcode> and scanning a driver's license <drivers_license>
  When the cashier selects Go back button
  And the cashier selects Go back button
  Then the POS displays main menu frame
  And an item FAIL: <item_1_name> with price <item_1_price> is in the virtual receipt
  And an item <item_1_name> with price <item_1_price> is in the current transaction with status IGNORE_PRICE
  And an item FAIL: <item_2_name> with price <item_2_price> is in the virtual receipt
  And an item <item_2_name> with price <item_2_price> is in the current transaction with status IGNORE_PRICE

  Examples:
   | item_1_name       | item_1_barcode | item_1_price | item_2_name | item_2_barcode | item_2_price | drivers_license |
   | Age 21 Restricted | 022222222220   | 4.69         | JUUL A      | 1111111        | 10.00        | underage DL     |

@fast @positive
Scenario Outline: JUUL item cannot be stored
  Given the POS is in a ready to sell state
  And a JUUL item with barcode <item_barcode> is present in the transaction
  When the cashier stores the transaction
  Then the POS displays Store tran not allowed message

  Examples:
   | item_barcode |
   | 4444444      |

@fast @positive
Scenario Outline: Refund JUUL items - age verification is not required
  Given the POS is in a ready to sell state
  And the transaction is switched to refund
  When the cashier scans a barcode <item_barcode>
  Then the POS displays main menu frame
  And an item <item_name> with price -<item_price> is in the virtual receipt
  And an item <item_name> with price <item_price> is in the current transaction

  Examples:
   | item_barcode | item_name | item_price |
   | 2222222      | JUUL B    | 20.00      |

@fast @positive
Scenario Outline: Refund JUUL items - group limit is not applied
  Given the POS is in a ready to sell state
  And the transaction is switched to refund
  And a JUUL item with barcode <item_barcode> is present in the transaction
  When the cashier updates quantity of the item <item_name> to <quantity>
  Then the POS displays main menu frame
  And an item <item_name> with price -<item_total> is in the virtual receipt
  And an item <item_name> with price <item_total> is in the current transaction

  Examples:
   | item_barcode | item_name | item_total | quantity |
   | 2222222      | JUUL B    | 400.00     | 20       |
   | 7777777      | JUUL ABC  | 700.00     | 10       |

@fast @positive
Scenario Outline: Quantity limit set to 0 on one of the JUUL groups, no limit is enforced
  Given the POS option <pos_option> is set to 0
  And the POS is in a ready to sell state
  And an age restricted item with barcode <item_barcode> is present in the transaction after instant verification
  When the cashier updates quantity of the item <item_name> to <quantity>
  Then the POS displays main menu frame
  And an item <item_name> with price <item_total> is in the virtual receipt
  And an item <item_name> with price <item_total> is in the current transaction

  Examples:
   | pos_option | item_barcode | item_name | item_total | quantity |
   | 1386       | 1111111      | JUUL A    | 200.00     | 20       |
   | 1387       | 2222222      | JUUL B    | 200.00     | 10       |
   | 1388       | 3333333      | JUUL C    | 300.00     | 10       |

@fast @positive
Scenario Outline: Quantity limit set to 0 on one of the JUUL groups, other group limits still apply - under
  Given the POS option <pos_option> is set to 0
  And the POS is in a ready to sell state
  And a JUUL item with barcode <item_barcode> is present in the transaction
  When the cashier updates quantity of the item <item_name> to <quantity>
  Then the POS displays main menu frame
  And an item <item_name> with price <item_total> and quantity <quantity> is in the virtual receipt
  And an item <item_name> with price <item_total> and quantity <quantity> is in the current transaction

  Examples:
   | pos_option | item_barcode | item_name | item_total | quantity |
   | 1386       | 4444444      | JUUL AB   | 200.00     | 5        |
   | 1387       | 6666666      | JUUL BC   | 180.00     | 3        |
   | 1388       | 5555555      | JUUL AC   | 100.00     | 2        |
   | 1386       | 7777777      | JUUL ABC  | 210.00     | 3        |

@fast @positive
Scenario Outline: Quantity limit set to 0 on one of the JUUL groups, other group limits still apply - over
  Given the POS option <pos_option> is set to 0
  And the POS is in a ready to sell state
  And a JUUL item with barcode <item_barcode> is present in the transaction
  When the cashier updates quantity of the item <item_name> to <quantity>
  Then the POS displays Item count exceeds maximum error
  And an item <item_name> with price <item_price> and quantity 1 is in the virtual receipt
  And an item <item_name> with price <item_price> and quantity 1 is in the current transaction

  Examples:
   | pos_option | item_barcode | item_name | item_price | quantity |
   | 1386       | 4444444      | JUUL AB   | 40.00    | 6          |
   | 1387       | 6666666      | JUUL BC   | 60.00    | 4          |
   | 1388       | 5555555      | JUUL AC   | 50.00    | 3          |
   | 1386       | 7777777      | JUUL ABC  | 70.00    | 4          |

@fast @positive
Scenario Outline: Feature is turned off, instant approval age verification is possible for JUUL items
  Given the POS option 1385 is set to 0
  And the POS is in a ready to sell state
  And the POS displays Age verification frame after scanning an item barcode <item_barcode>
  When the cashier presses the instant approval button
  Then the POS displays main menu frame
  And an item <item_name> with price <item_price> is in the virtual receipt
  And an item <item_name> with price <item_price> is in the current transaction

  Examples:
   | item_barcode | item_name | item_price |
   | 4444444      | JUUL AB   | 40.00      |

@fast @positive
Scenario Outline: Feature is turned off, manual entry age verification is possible for JUUL items
  Given the POS option 1385 is set to 0
  And the POS is in a ready to sell state
  And the POS displays Age verification frame after scanning an item barcode <item_barcode>
  When the cashier manually enters the customer's birthday <birthday>
  Then the POS displays main menu frame
  And an item <item_name> with price <item_price> is in the virtual receipt
  And an item <item_name> with price <item_price> is in the current transaction

  Examples:
   | item_barcode | birthday    | item_name | item_price |
   | 5555555      | 08-29-1989  | JUUL AC   | 50.00      |

@fast @positive
Scenario Outline: Feature is turned off, no quantity limit is enforced for JUUL items
  Given the POS option 1385 is set to 0
  And the POS is in a ready to sell state
  And an age restricted item with barcode <item_barcode> is present in the transaction after instant verification
  When the cashier updates quantity of the item <item_name> to <quantity>
  Then the POS displays main menu frame
  And an item <item_name> with price <item_total> and quantity <quantity> is in the virtual receipt
  And an item <item_name> with price <item_total> and quantity <quantity> is in the current transaction

  Examples:
   | item_barcode | item_name | item_total | quantity |
   | 4444444      | JUUL AB   | 800.00     | 20       |
   | 6666666      | JUUL BC   | 600.00     | 10       |
   | 5555555      | JUUL AC   | 750.00     | 15       |
   | 7777777      | JUUL ABC  | 700.00     | 10       |

@fast @positive
Scenario Outline: Feature is turned off, JUUL items can be stored
  Given the POS option 1385 is set to 0
  And the POS is in a ready to sell state
  And an age restricted item with barcode <item_barcode> is present in the transaction after instant verification
  When the cashier stores the transaction
  Then the POS displays main menu frame
  And no transaction is in progress

  Examples:
   | item_barcode | item_name | item_price |
   | 4444444      | JUUL AB   | 40.00      |

