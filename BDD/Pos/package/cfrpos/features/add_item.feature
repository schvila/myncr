@pos
Feature: Add item
    POS can add sale items.

Background: The POS has essential configuration so we can add items to the transaction.
    Given the POS has essential configuration
    And the pricebook contains department sale items
     | description  | price | barcode | item_id      | modifier1_id | item_type | item_mode |
     | Dept 88 Sale | 10    | 9088    | 990000000015 | 990000000002 | 11        | 2         |
     | Dept 99 Sale | 5     | 9099    | 990000000016 | 990000000003 | 11        | 2         |

    @fast
    Scenario Outline: Add an item to the transaction by pressing main menu button with Sell barcode action assigned.
       Given the POS is in a ready to sell state
        When the cashier selects item with barcode <barcode> on the main menu
        Then a transaction is in progress
        And an item <item_name> with price <price> is in the virtual receipt
        And an item <item_name> with price <price> is in the current transaction

        Examples:
        | barcode      | item_name   | price |
        | 099999999990 | Sale Item A | 0.99  |
        | 088888888880 | Sale Item B | 1.99  |


    @fast
    Scenario Outline: Add an item to the transaction by scanning an item barcode.
        Given the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then a transaction is in progress
        And an item <item_name> with price <price> is in the virtual receipt
        And an item <item_name> with price <price> is in the current transaction

        Examples:
        | barcode      | item_name   | price |
        | 099999999990 | Sale Item A | 0.99  |
        | 088888888880 | Sale Item B | 1.99  |
        
        
    @fast 
    Scenario Outline: Add an item to the transaction by manually entering UPC barcode, item appears in the transaction.
        Given the POS is in a ready to sell state
        And the cashier pressed Enter PLU/UPC button
        When the cashier manually entered a barcode <barcode>
        Then an item <item_name> with price <price> is in the current transaction
        And an item <item_name> with price <price> is in the virtual receipt

        Examples:
        | barcode      | item_name   | price |
        | 099999999990 | Sale Item A | 0.99  |
        | 088888888880 | Sale Item B | 1.99  |


    @fast
    Scenario Outline: Add an item to the transaction with a linked child item.
        Given the POS is in a ready to sell state
        When the cashier selects item with barcode <item_barcode> on the main menu
        Then an item <item_name> with price <price> is in the virtual receipt
        And an item <item_name> with price <price> is in the current transaction
        And an item <child_item_name> with price <child_price> is in the virtual receipt
        And an item <child_item_name> with price <child_price> is in the current transaction

        Examples:
        | item_barcode | item_name      | price | child_item_name         | child_price |
        | 011111111110 | Parent Item    | 0.39  | Child Item              | 0.19        |


    @fast
    Scenario Outline: Add an item to the transaction with a linked deposit item.
        Given the POS is in a ready to sell state
        When the cashier selects item with barcode <item_barcode> on the main menu
        Then an item <item_name> with price <price> is in the virtual receipt
        And an item <item_name> with price <price> is in the current transaction
        And a deposit <deposit_item> with price <deposit_price> is in the virtual receipt
        And a deposit <deposit_item> with price <deposit_price> is in the current transaction

        Examples:
        | item_barcode | item_name      | price | deposit_item            | deposit_price |
        | 055555555550 | Container Item | 1.29  | Deposit (for Container) | 0.05          |


    @fast
    Scenario Outline: Add a deposit item in the transaction.
        Given the POS is in a ready to sell state
        And the POS displays Container Deposit Redemption frame
        When the cashier enters a barcode <barcode> of an item with a container
        Then an item <refund_item> with refund value of <value> is in the current transaction
        And an item <refund_item> with refund value of <value> is in the virtual receipt

        Examples:
        | barcode    | refund_item             | value  |
        | 5555555555 | Deposit (for Container) | 0.05   |


     @fast
     Scenario: Press Sell Carwash button on the main menu, the POS displays Select a car wash item frame.
        Given the POS is in a ready to sell state
        When the cashier presses Sell carwash button
        Then the POS displays Select a carwash item frame


     @fast @waitingforfix @manual
     # Since the void of the transaction is added to the POS is ready to sell Given clause, this test ends up with
     # an error note that the car wash is offline. The carwash simulator needs to be enhanced to be able to react
     # to POS request to delete the code. BUG 465464
     Scenario Outline: Add a carwash item with a code to the transaction, a carwash item appears in the VR.
        Given the POS is in a ready to sell state
        And the POS displays Select a carwash item frame
        When the cashier selects a carwash item <item_name> while carwash online
        Then an item <item_name> with price <item_price> is in the current transaction
        And an item <item_name> with price <item_price> is in the virtual receipt

         Examples:
         | item_name         | item_price |
         | Full Car wash     | 9.99       |
         | PDI Car Wash Item | 5.19       |


    @fast
    Scenario: Press Department sale button, a grid of available department items is displayed.
       Given the POS is in a ready to sell state
       When the cashier presses Department sale button
       Then the POS displays Select department sale frame


    @fast
    Scenario: Choose a department item on the select department sale frame, ask enter dollar amount frame is displayed.
       Given the POS is in a ready to sell state
       And the POS displays Select department sale frame
       When the cashier selects department item Dept 88 from select department sale frame
       Then the POS displays Ask enter dollar amount frame


    @fast
    Scenario: Scan a department item barcode, ask enter dollar amount frame is displayed.
       Given the POS is in a ready to sell state
       When the cashier scans a barcode 9088
       Then the POS displays Ask enter dollar amount frame


    @fast
    Scenario: Press Go back button on Ask enter dollar amount frame when adding department item, main menu is displayed.
        Given the POS is in a ready to sell state
        And the POS displays Ask enter dollar amount frame after selecting a department sale item Dept 88
        When the cashier presses Go back button
        Then the POS displays main menu frame


    @fast
    Scenario: Press Clear button on Ask enter dollar amount frame with some amount entered without confirming it, ask enter dollar amount frame is displayed.
        Given the POS is in a ready to sell state
        And the POS displays Ask enter dollar amount frame after selecting a department sale item Dept 99
        And the cashier entered 10.00 dollar amount in Ask enter dollar amount frame without confirming it
        When the cashier presses Clear button
        Then the POS displays Ask enter dollar amount frame


    @fast
    Scenario: Confirm the department sale price, item is added to the transaction.
        Given the POS is in a ready to sell state
        And the POS displays Ask enter dollar amount frame after selecting a department sale item Dept 99
        And the cashier entered 20.00 dollar amount in Ask enter dollar amount frame without confirming it
        When the cashier presses Enter button
        Then an item Dept 99 Sale with price 20.00 and type 11 is in the current transaction
        And an item Dept 99 Sale with price 20.00 is in the virtual receipt


    @fast
    Scenario: The transaction is switched to refund and a department item was added, item appears in the transaction.
        Given the POS is in a ready to sell state
        And the transaction is switched to refund
        And the POS displays Ask enter dollar amount frame after selecting a department sale item Dept 88
        And the cashier entered 10.00 dollar amount in Ask enter dollar amount frame without confirming it
        When the cashier presses Enter button
        Then an item Dept 88 Sale with price 10.00 and type 11 is in the current transaction
        And an item Dept 88 Sale with price -10.00 is in the virtual receipt


    @fast 
    Scenario Outline: Add an item to the transaction by manually entering PLU barcode, item appears in the transaction.
        Given the POS is in a ready to sell state
        And the cashier pressed Enter PLU/UPC button
        And the cashier manually entered a barcode <barcode>
        And the cashier entered <price> dollar amount in Ask enter dollar amount frame without confirming it
        When the cashier presses Enter button
        Then an item <item_description> with price <price> is in the virtual receipt
        And an item <item_description> with price <price> and type 11 is in the current transaction
                 
        Examples:    
        | barcode | item_description | price |
        | 9088    | Dept 88 Sale     | 10.00 |
        | 9099    | Dept 99 Sale     | 5.00  |


    @fast 
    Scenario Outline: Manually enter invalid PLU barcode, the item is not added to the transaction.
        Given the POS is in a ready to sell state
        And the cashier pressed Enter PLU/UPC button
        When the cashier manually entered a barcode <barcode>
        Then an item <item_description> with price <price> is not in the current transaction
        And an item <item_description>  with price <price> is not in the virtual receipt
        
        Examples:    
        | barcode | item_description | price |
        | 9081    | Dept 81 Sale     | 10.00 |      

