@pos
Feature: Item Management
         This feature performs different operations on the selected item.

Background: The POS needs to have some items configured to manipulate with them.
    Given the POS has essential configuration

    @fast
    Scenario Outline: Press Change quantity button with an item in the transaction.
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        When the cashier presses Change quantity button
        Then the POS displays Enter quantity amount frame
        And an item <item_name> with price <price> and quantity 1 is in the virtual receipt
        And an item <item_name> with price <price> and quantity 1 is in the current transaction

        Examples:
        | item_barcode | item_name    | price |
        | 099999999990 | Sale Item A  | 0.99  |


    @fast
    Scenario: Press Change quantity button with no transaction in progress.
        Given the POS is in a ready to sell state
        When the cashier presses Change quantity button
        Then the POS displays No tran in progress error
        And no transaction is in progress

    @fast
    Scenario: Press Change quantity button with no items in the transaction.
        Given the POS is in a ready to sell state
        And an empty transaction is in progress
        When the cashier presses Change quantity button
        Then the POS displays No tran in progress error


    @fast
    Scenario Outline: Press go back button in Change quantity frame.
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        And the POS displays Enter quantity amount frame
        When the cashier presses Go back button
        Then the POS displays main menu frame
        And an item <item_name> with price <price> and quantity 1 is in the virtual receipt
        And an item <item_name> with price <price> and quantity 1 is in the current transaction

        Examples:
        | item_barcode | item_name    | price  |
        | 099999999990 | Sale Item A  | 0.99   |


    @fast
    Scenario Outline: Change quantity of an item in the transaction to 0 is disallowed.
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        And the POS displays Enter quantity amount frame
        When the cashier enters 0 quantity
        Then the POS displays Zero quantity not allowed error
        And an item <item_name> with price <price> and quantity 1 is in the virtual receipt
        And an item <item_name> with price <price> and quantity 1 is in the current transaction

        Examples:
        | item_barcode | item_name    | price  |
        | 099999999990 | Sale Item A  | 0.99   |


    @fast
    Scenario Outline: Change quantity of an item in the transaction to higher than 999 is disallowed.
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        And the POS displays Enter quantity amount frame
        When the cashier enters <quantity> quantity
        Then the POS displays Quantity too large error
        And an item <item_name> with price <price> and quantity 1 is in the virtual receipt
        And an item <item_name> with price <price> and quantity 1 is in the current transaction

        Examples:
        | item_barcode | quantity | item_name    | price  |
        | 099999999990 | 1000     | Sale Item A  | 0.99   |
        | 099999999990 | 12345678 | Sale Item A  | 0.99   |


    @fast @smoke
    Scenario Outline: Change quantity of an item in the transaction.
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        And the POS displays Enter quantity amount frame
        When the cashier enters <quantity> quantity
        Then an item <item_name> with price <price> and quantity <quantity> is in the virtual receipt
        And an item <item_name> with price <price> and quantity <quantity> is in the current transaction

        Examples:
        | item_barcode | item_name    | quantity | price  |
        | 099999999990 | Sale Item A  | 10       | 9.90   |
        | 088888888880 | Sale Item B  | 7        | 13.93  |
        | 077777777770 | Sale Item C  | 5        | 7.45   |
        | 066666666660 | Sale Item D  | 46       | 109.94 |


    @fast
    Scenario Outline: Change quantity of an item in the transaction with quick buttons.
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        And the POS displays Enter quantity amount frame
        When the cashier presses the quick button of quantity <quantity>
        Then an item <item_name> with price <price> and quantity <quantity> is in the virtual receipt
        And an item <item_name> with price <price> and quantity <quantity> is in the current transaction

        Examples:
        | item_barcode | item_name    | quantity | price  |
        | 099999999990 | Sale Item A  | 2        | 1.98   |
        | 088888888880 | Sale Item B  | 5        | 9.95   |
        | 077777777770 | Sale Item C  | 6        | 8.94   |
        | 066666666660 | Sale Item D  | 9        | 21.51  |


    @fast
    Scenario: Press Item price check button.
        Given the POS is in a ready to sell state
        When the cashier presses Price check button
        Then the POS displays Price check frame


    @fast
    Scenario: Press Manual enter button in Price check frame.
        Given the POS is in a ready to sell state
        And the POS displays Price check frame
        When the cashier presses Manual enter button
        Then the POS displays Barcode entry frame


    @fast
    Scenario: Press Add to order button in Price check frame without any item added.
        Given the POS is in a ready to sell state
        And the POS displays Price check frame
        When the cashier presses Add to order button
        Then the POS displays No item to add error


    @fast @manual @waitingforfix
    Scenario Outline: Check item price with barcode manual entry
        Given the POS is in a ready to sell state
        And the POS displays Price check frame
        When the cashier manually enters barcode <item_barcode> for price check
        Then the item <item_name> with price <price> is displayed on the Item price check frame
        # The displayed item can not be seen, it is missing metadata
        # Will be solved in Jira task RPOS-6966

        Examples:
        | item_barcode | item_name    | price |
        | 099999999990 | Sale Item A  | 0.99  |
        | 088888888880 | Sale Item B  | 1.99  |
        | 077777777770 | Sale Item C  | 1.49  |
        | 066666666660 | Sale Item D  | 2.39  |


    @fast @manual @waitingforfix
    Scenario Outline: Check item price with barcode scan
        Given the POS is in a ready to sell state
        And the POS displays Price check frame
        When the cashier scans a barcode <item_barcode>
        Then the item <item_name> with price <price> is displayed on the Item price check frame
        # The displayed item can not be seen, it is missing metadata
        # Will be solved in Jira task RPOS-6966

        Examples:
        | item_barcode | item_name    | price |
        | 099999999990 | Sale Item A  | 0.99  |
        | 088888888880 | Sale Item B  | 1.99  |
        | 077777777770 | Sale Item C  | 1.49  |
        | 066666666660 | Sale Item D  | 2.39  |


    @fast @smoke
    Scenario Outline: Check item price, then add that item to the transaction
        Given the POS is in a ready to sell state
        And the cashier performed price check of item with barcode <item_barcode>
        When the cashier presses Add to order button
        Then an item <item_name> with price <price> is in the virtual receipt
        And an item <item_name> with price <price> is in the current transaction

        Examples:
        | item_barcode | item_name    | price |
        | 099999999990 | Sale Item A  | 0.99  |
        | 088888888880 | Sale Item B  | 1.99  |
        | 077777777770 | Sale Item C  | 1.49  |
        | 066666666660 | Sale Item D  | 2.39  |


    @fast
    Scenario: Press Go back button in Price check frame.
        Given the POS is in a ready to sell state
        And the POS displays Price check frame
        When the cashier presses Go back button
        Then no transaction is in progress
        And the POS displays main menu frame


    @fast
    Scenario Outline: Check item price, then press Go back button.
        Given the POS is in a ready to sell state
        And the cashier performed price check of item with barcode <item_barcode>
        When the cashier presses Go back button
        Then no transaction is in progress
        And the POS displays main menu frame

        Examples:
        | item_barcode |
        | 099999999990 |
        | 088888888880 |


    @fast @smoke
    Scenario Outline: Press Void item button with an item in the transaction.
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        When the cashier voids the <item_name> with price <price>
        Then an item <item_name> with price <price> is not in the virtual receipt
        And an item <item_name> with price <price> is not in the current transaction

        Examples:
        | item_barcode | item_name    | price |
        | 099999999990 | Sale Item A  | 0.99  |
        | 088888888880 | Sale Item B  | 1.99  |
        | 077777777770 | Sale Item C  | 1.49  |
        | 066666666660 | Sale Item D  | 2.39  |


    @fast
    Scenario: Press Void item button without any items in the transaction.
        Given the POS is in a ready to sell state
        And an empty transaction is in progress
        When the cashier presses the Void button
        Then the POS displays No item to void error


    @fast
    Scenario: Press Void item button without an active transaction.
        Given the POS is in a ready to sell state
        When the cashier presses the Void button
        Then the POS displays No tran in progress error


    @fast
    Scenario Outline: Autocombo feature to avail special discount into the transaction which is triggered by a combination of items.
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode_1> is present in the transaction <count> times
        When the cashier scans a barcode <item_barcode_2>
        Then the autocombo <autocombo_description> with discount of <discount_value> is in the virtual receipt
        And the autocombo <autocombo_description> with discount of <discount_value> is in the current transaction

        Examples:
        | item_barcode_1 | count | item_barcode_2 | autocombo_description | discount_value |
        | 077777777770   | 1     | 077777777770   | 2Cs for $2.49 Combo   | 0.49           |
        | 077777777770   | 3     | 077777777770   | 2Cs for $2.49 Combo   | 0.98           |
        | 066666666660   | 1     | 066666666660   | 2Ds 25% Off Combo     | 1.20           |
        | 066666666660   | 2     | 066666666660   | 2Ds 25% Off Combo     | 1.20           |
        | 044444444440   | 1     | 033333333330   | 2  F and G MixMatch   | 0.29           |


    @fast
    Scenario Outline: Press Price override button with an item in the transaction.
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        When the cashier presses Price override button
        Then the POS displays Enter new price frame

        Examples:
        | item_barcode |
        | 099999999990 |


    @fast
    Scenario: Press Price override button with no items in the transaction.
        Given the POS is in a ready to sell state
        And an empty transaction is in progress
        When the cashier presses Price override button
        Then the POS displays No tran in progress error


    @fast
    Scenario: Press Price override button with no active transaction
        Given the POS is in a ready to sell state
        When the cashier presses Price override button
        Then the POS displays No tran in progress error


    @fast @waitingforfix @manual
    Scenario Outline: Enter a new price for an item using Price override.
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        And the POS displays Enter new price frame
        When the cashier enters new price <price>
        Then the POS displays Please select a reason frame
        # The go back button in select a reason has metadata cancel instead of go back
        # Will be solved in Jira task RPOS-6966

        Examples:
        | item_barcode | price |
        | 099999999990 | 1.20  |


    @fast
    Scenario Outline: Press Go back button from Price override frame.
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        And the POS displays Enter new price frame
        When the cashier presses Go back button
        Then an item <item_name> with price <price> is in the virtual receipt
        And an item <item_name> with price <price> is in the current transaction

        Examples:
        | item_barcode | item_name   | price |
        | 099999999990 | Sale Item A | 0.99  |


    @fast @waitingforfix @manual
    Scenario Outline: Go back from selecting a reason in Price override
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        And the POS displays Select a reason after overriding price with <new_price>
        When the cashier presses button Go back button
        # The go back button in select a reason has metadata cancel instead of go back
        # Will be solved in Jira task RPOS-6966
        Then the POS displays Enter new price frame

        Examples:
        | item_barcode | new_price |
        | 099999999990 | 1.20      |


    @fast @smoke
    Scenario Outline: Select a reason in Price Override and finalize the Price override action
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        And the POS displays Select a reason after overriding price with <new_price>
        When the cashier selects the <reason> reason code
        Then an item <item_name> with price <new_price> is in the virtual receipt
        And an item <item_name> with price <new_price> is in the current transaction
        And the total tax is changed in current transaction to <tax>

        Examples:
        | item_barcode | item_name   | new_price | reason                 | tax  |
        | 099999999990 | Sale Item A | 1.20      | Price Override Reason  | 0.08 |
        | 088888888880 | Sale Item B | 0.09      | RS 20 - Price override | 0.00 |
        | 077777777770 | Sale Item C | 1.05      | RS 20 - Price override | 0.07 |
        | 066666666660 | Sale Item D | 12.34     | Price Override Reason  | 0.86 |


    @fast
    Scenario: Press Change quantity button when no transaction is in progress, an error is displayed
        Given the POS is in a ready to sell state
        When the cashier presses Change quantity button
        Then the POS displays No tran in progress error


    @fast
    Scenario: Press Change quantity button when a finalized transaction is displayed in the VR, an error is displayed
        Given the POS is in a ready to sell state
        And a finalized transaction is present
        When the cashier presses Change quantity button
        Then the POS displays No tran in progress error


    @fast
    Scenario: Press Enter UPC/PLU button, the POS displays Barcode entry frame 
        Given the POS is in a ready to sell state
        When the cashier presses Enter PLU/UPC button
        Then the POS displays Barcode entry frame


    @fast
    Scenario Outline: Press Clear button on Ask barcode entry frame with some barcode entered without confirming it,
                      the item is not added to the transaction.
        Given the POS is in a ready to sell state
        And the cashier manually entered the barcode <barcode> without confirming it
        When the cashier presses Clear button on Ask barcode entry frame
        Then an item <item_name> with price <price> is not in the current transaction
        And an item <item_name> with price <price> is not in the virtual receipt

        Examples:
        | barcode      | item_name    | price |
        | 099999999990 | Sale Item A  | 0.99  |
        | 9099         | Dept 99 Sale | 5.00  |


    @fast
    Scenario Outline: Press Go back on Ask barcode entry frame with some barcode entered without confirming it,
                      the POS displays main menu frame, and item is not added to the transaction.
        Given the POS is in a ready to sell state
        And the cashier manually entered the barcode <barcode> without confirming it
        When the cashier presses Go back button
        Then the POS displays main menu frame
        And an item <item_name> with price <price> is not in the current transaction
        And an item <item_name> with price <price> is not in the virtual receipt

        Examples:
        | barcode      | item_name    | price |
        | 099999999990 | Sale Item A  | 0.99  |
        | 9099         | Dept 99 Sale | 5.00  |

    
    @fast
    Scenario: Press Change quantity button when a stored transaction is displayed in the VR, an error is displayed
        Given the POS is in a ready to sell state
        And a stored transaction is present
        When the cashier presses Change quantity button
        Then the POS displays No tran in progress error