@pos @weighteditem
Feature: Weighted item
This feature allows POS to sell Weighted items. Each retail item which should be sold by weight has a specific weighted item flag.
By this flag POS recognizes, that this Retail Item should prompt for weight and displays a frame where cashier can manually enter
the weight (kg - 3 decimals, lb - 2decimals).
This flag can be configured via RCM/RSM retail item setup applet or Naxml imports.
Weighted Items can not be consolidated.
POS Option 1578 specifies UOM (unit of measure) of the system (kg/lb). It will be used by virtual receipt, printed receipts, exports.


Background: POS is properly configured for weighted item feature
    Given the POS has essential configuration
    And the pricebook contains retail items
        | description  | price  | barcode      | item_id       | weighted_item |
        | WT Item      | 1.00   | 022222222220 | 990000000009  | True          |
        | Zero WTItem  | 0.00   | 022222222221 | 990000000010  | True          |


    @fast
    Scenario Outline: Scan a weighted item barcode, POS displays Enter weight modal frame
        # Set unit of measure as kg and lb
        Given the POS option 1578 is set to <pos_option_val>
        And the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then the POS displays the enter weight frame

        Examples:
        | pos_option_val | barcode      |
        | 0              | 022222222220 |
        | 1              | 022222222220 |
        | 0              | 022222222221 |
        | 1              | 022222222221 |


    @fast
    Scenario Outline: Cashier enters the item's weight when prompted, item is added to the transaction
        Given the POS option 1578 is set to <pos_option_val>
        And the POS is in a ready to sell state
        And the POS displays Enter weight frame after item with barcode <barcode> was added to transaction
        When the cashier enters <weight> weight
        Then an item <item_name> with UOM <UOM> and price <price> is in the virtual receipt
        And an item <name> with NVPs <nvp> is in the current transaction

        Examples:
        | barcode      | item_name         | UOM | price | weight  | pos_option_val | name         | nvp                                                                                               |
        | 022222222220 | 2.345 WT Item     | kg  | 2.35  | 2.345   | 0              | wt item      | {'name': 'PosReceiptPrinter.ReceiptWeightedItemUOM', 'type': '1', 'persist': 'true', 'text': '0'} |
        | 022222222221 | 2.345 Zero WTItem | kg  | 0.00  | 2.345   | 0              | zero wtitem  | {'name': 'PosReceiptPrinter.ReceiptWeightedItemUOM', 'type': '1', 'persist': 'true', 'text': '0'} |
        | 022222222220 | 2.34 WT Item      | lb  | 2.34  | 2.34    | 1              | wt item      | {'name': 'PosReceiptPrinter.ReceiptWeightedItemUOM', 'type': '1', 'persist': 'true', 'text': '1'} |
        | 022222222221 | 2.34 Zero WTItem  | lb  | 0.00  | 2.34    | 1              | zero wtitem  | {'name': 'PosReceiptPrinter.ReceiptWeightedItemUOM', 'type': '1', 'persist': 'true', 'text': '1'} |


    @fast
    Scenario Outline: Add weighted and non-weighted items to the transaction - weighted item first, only WI displays UOM
        Given the POS is in a ready to sell state
        And a weighted item with barcode <barcode_w1> is present in the transaction with weight <weight>
        When the cashier scans a barcode <barcode_nw2>
        Then an item <item_name_w1> with UOM <UOM> and price <price_w1> is in the virtual receipt
        And an item <item_name_nw2> with price <price_nw2> and quantity <quantity> is in the virtual receipt
        And the transaction's balance is <transaction_balance>

        Examples:
        | barcode_w1   | item_name_w1  | UOM | price_w1 | weight | barcode_nw2  | item_name_nw2 | quantity | price_nw2 | transaction_balance |
        | 022222222220 | 2.345 WT Item | kg  | 2.35     | 2.345  | 099999999990 | Sale Item A   | 1        | 0.99      | 3.57                |


    @fast
    Scenario Outline: Add weighted and non-weighted items to the transaction - non-weighted item first, only WI displays UOM
        Given the POS option 1578 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode <barcode_nw2> is present in the transaction
        And the POS displays Enter weight frame after item with barcode <barcode_w1> was added to transaction
        When the cashier enters <weight> weight
        Then an item <item_name_nw2> with price <price_nw2> and quantity <quantity> is in the virtual receipt
        And an item <item_name_w1> with UOM <UOM> and price <price_w1> is in the virtual receipt
        And the transaction's balance is <transaction_balance>

        Examples:
        | barcode_w1   | item_name_w1 | UOM | price_w1 | weight | barcode_nw2  | item_name_nw2 | quantity | price_nw2 | transaction_balance |
        | 022222222220 | 2.34 WT Item | lb  | 2.34     | 2.34   | 099999999990 | Sale Item A   | 1        | 0.99      | 3.56                |


    @fast
    Scenario Outline: Add a weighted item to the transaction and refund it, transaction is finalized
        Given the POS option 1578 is set to <pos_option_val>
        And the POS is in a ready to sell state
        And a weighted item with barcode <barcode> is present in the transaction with weight <weight>
        And the transaction is switched to refund
        When the cashier presses the cash tender button on Select refund tender frame
        Then the transaction is finalized
        And an item <item_name> with UOM <UOM> and price <refund_price> is in the virtual receipt
        And an item <name> with NVPs <nvp> is in the previous transaction

        Examples:
        | barcode      | item_name     | UOM | refund_price | weight  | pos_option_val | name    | nvp                                                                                               |
        | 022222222220 | 2.345 WT Item | kg  | -2.35        | 2.345   | 0              | wt item | {'name': 'PosReceiptPrinter.ReceiptWeightedItemUOM', 'type': '1', 'persist': 'true', 'text': '0'} |
        | 022222222220 | 2.34 WT Item  | lb  | -2.34        | 2.34    | 1              | wt item | {'name': 'PosReceiptPrinter.ReceiptWeightedItemUOM', 'type': '1', 'persist': 'true', 'text': '1'} |


    @fast
    Scenario Outline: Start a refund transaction, add a weighted item and tender it, the transaction is finalized
        Given the POS option 1578 is set to <pos_option_val>
        And the POS is in a ready to sell state
        And the transaction is switched to refund
        And a weighted item with barcode <barcode> is present in the transaction with weight <weight>
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the transaction is finalized
        And an item <item_name> with UOM <UOM> and price <refund_price> is in the virtual receipt
        And an item <name> with NVPs <nvp> is in the previous transaction

        Examples:
        | barcode      | item_name     | UOM | weight | pos_option_val | refund_price | name    | nvp                                                                                               |
        | 022222222220 | 2.345 WT Item | kg  | 2.345  | 0              | -2.35        | wt item | {'name': 'PosReceiptPrinter.ReceiptWeightedItemUOM', 'type': '1', 'persist': 'true', 'text': '0'} |
        | 022222222220 | 2.34 WT Item  | lb  | 2.34   | 1              | -2.34        | wt item | {'name': 'PosReceiptPrinter.ReceiptWeightedItemUOM', 'type': '1', 'persist': 'true', 'text': '1'} |


    @fast
    Scenario Outline: Void weighted item, item is removed from the transaction
        Given the POS option 1578 is set to <pos_option_val>
        And the POS is in a ready to sell state
        And a weighted item with barcode <barcode> is present in the transaction with weight <weight>
        When the cashier presses Void-Item button on receipt frame
        Then an item <item_name> with price <price> is not in the virtual receipt
        And an item <item_name> with price <price> is not in the current transaction
        And the transaction's balance is 0.00

        Examples:
        | barcode      | item_name     | UOM | price | weight | pos_option_val |
        | 022222222220 | 2.345 WT Item | kg  | 2.35  | 2.345  | 0              |
        | 022222222220 | 2.34 WT Item  | lb  | 2.34  | 2.34   | 1              |


    @fast
    Scenario Outline: Void transaction with a weighted item, no transaction is open
        Given the POS option 1578 is set to <pos_option_val>
        And the POS is in a ready to sell state
        And a weighted item with barcode <barcode> is present in the transaction with weight <weight>
        And the POS displays Select reason frame after voiding a transaction with the pin 2345
        When the cashier selects the first reason from the displayed list
        Then no transaction is in progress

        Examples:
        | barcode      | pos_option_val | weight  |
        | 022222222220 | 0              | 2.345   |
        | 022222222220 | 1              | 2.34    |


    @fast @negative
    Scenario Outline: Attempt to change quantity of a weighted item, Quantity not allowed error is displayed
        Given the POS option 1578 is set to <pos_option_val>
        And the POS is in a ready to sell state
        And a weighted item with barcode <barcode> is present in the transaction with weight <weight>
        When the cashier updates quantity of the item <item_name> to <update_quantity>
        Then the POS displays Quantity not allowed error

        Examples:
        | barcode      | item_name     | weight | pos_option_val | update_quantity |
        | 022222222220 | 2.345 WT Item | 2.345  | 0              | 5               |
        | 022222222220 | 2.34 WT Item  | 2.34   | 1              | 2               |


    @fast @negative
    Scenario Outline: Attempt to override price of a weighted item, Price override not allowed error is displayed
        Given the POS option 1578 is set to <pos_option_val>
        And the POS is in a ready to sell state
        And a weighted item with barcode <barcode> is present in the transaction with weight <weight>
        When the cashier overrides price of the item <item_name> to price <new_price>
        Then the POS displays Price override not allowed error frame

        Examples:
        | barcode      | item_name     | quantity | total| weight | pos_option_val | new_price       |
        | 022222222220 | 2.345 WT Item | kg       | 2.35 | 2.345  | 0              | 5.12            |
        | 022222222220 | 2.34 WT Item  | lb       | 2.34 | 2.34   | 1              | 1.99            |


    @fast @negative
    Scenario Outline: Attempt to tender a weighted item as drive off, Tender not allowed for non-fuel items is displayed
        Given the POS option 1578 is set to <pos_option_val>
        And the POS is in a ready to sell state
        And a weighted item with barcode <barcode> is present in the transaction with weight <weight>
        And the POS displays Other functions frame
        When the cashier presses Drive Off button
        Then the POS displays Tender not allowed for non-fuel items error frame

        Examples:
        | barcode      | weight | pos_option_val |
        | 022222222220 | 2.345  | 0              |
        | 022222222220 | 2.34   | 1              |


    @fast @negative
    Scenario Outline: Attempt to tender a  weighted item as pump test, Tender not allowed for non-fuel items is displayed
        Given the POS option 1578 is set to <pos_option_val>
        And the POS is in a ready to sell state
        And a weighted item with barcode <barcode> is present in the transaction with weight <weight>
        And the POS displays Other functions frame
		When the cashier presses Pump Test button
        Then the POS displays Tender not allowed for non-fuel items error frame

        Examples:
        | barcode      | weight | pos_option_val |
        | 022222222220 | 2.345  | 0              |
        | 022222222220 | 2.34   | 1              |


    @fast
    Scenario Outline: Review a weighted item sale transaction in Scroll Previous frame, all information is displayed correctly
        Given the POS option 1578 is set to <pos_option_val>
        And the POS is in a ready to sell state
        And a weighted item with barcode <barcode> is present in the transaction with weight <weight>
        And the transaction is tendered
        And the POS displays Other functions frame
        When the cashier presses Scroll previous button
        Then the POS displays Scroll previous frame
        And an item <item_name> with UOM <UOM> and price <price> is in the virtual receipt

        Examples:
        | barcode      | item_name     | UOM | price | weight | pos_option_val |
        | 022222222220 | 2.345 WT Item | kg  | 2.35  | 2.345  | 0              |
        | 022222222220 | 2.34 WT Item  | lb  | 2.34  | 2.34   | 1              |


    @fast
    Scenario Outline: Store and recall a transaction with weighted item, all information is displayed correctly
        Given the POS option 1578 is set to <pos_option_val>
        And the POS is in a ready to sell state
        And a weighted item with barcode <barcode> is present in the transaction with weight <weight>
        And the cashier stored the transaction
        When the cashier recalls the last stored transaction
        Then an item <item_name> with UOM <UOM> and price <price> is in the virtual receipt

        Examples:
        | barcode      | item_name     | UOM | price | weight | pos_option_val |
        | 022222222220 | 2.345 WT Item | kg  | 2.35  | 2.345  | 0              |
        | 022222222220 | 2.34 WT Item  | lb  | 2.34  | 2.34   | 1              |


    @fast
    Scenario Outline: Apply item level discount to a weighted item, discount is present in the transaction
        Given the POS option 1578 is set to <pos_option_val>
        And the POS is in a ready to sell state
        And a weighted item with barcode <barcode> is present in the transaction with weight <weight>
        When the cashier adds a discount <discount_name>
        Then a discount <discount_name> with value of <value> is in the virtual receipt

        Examples:
        | barcode      | weight | pos_option_val | discount_name         | value |
        | 022222222220 | 2.345  | 0              | Dsc $0.99 PreTax Item | 0.99  |
        | 022222222220 | 2.34   | 1              | Dsc $0.99 PreTax Item | 0.99  |


    @fast
    Scenario Outline: Apply item level coupon to a weighted item, coupon is present in the transaction
        Given the POS option 1578 is set to <pos_option_val>
        And the POS is in a ready to sell state
        And a weighted item with barcode <barcode> is present in the transaction with weight <weight>
        When the cashier adds a coupon <coupon_name>
        Then a discount <coupon_name> with value of <value> is in the virtual receipt

        Examples:
        | barcode      | weight | pos_option_val | coupon_name          | value |
        | 022222222220 | 2.345  | 0              | Cpn $0.99 PreTax Itm | 0.99  |
        | 022222222220 | 2.34   | 1              | Cpn $0.99 PreTax Itm | 0.99  |


    @manual
    Scenario Outline: Attempt to price check a weighted item
        Given the POS is in a ready to sell state
        And the POS displays barcode entry frame for pricecheck
        When the cashier manually enters a barcode <barcode>
        #TODO: there is no item description and price visible in metadata (in the url http://localhost:10000/v1/posengine/opened-frame?type=menu),
        Then an item <item_name> with price <price> is displayed on item price check frame

        Examples:
        | barcode      | item_name | price |
        | 022222222220 | WT Item   | 1.00  |