@pos
Feature: Lock retail item
    This feature file checks the locking functionality. 
    It locks and unlocks items and tries to tender them.
    It internally uses the LockedRetailItem relay file.
    
    Background: POS is properly configured, items are configured and some of them are locked
        Given the POS has essential configuration
        And the POS has following sale items locked
        | barcode      | description | price  | item_id      | modifier1_id |
        | 099999999990 | Sale Item A | 0.99   | 990000000002 | 990000000007 |
        | 088888888880 | Sale Item B | 1.99   | 990000000003 | 990000000007 |
        And the POS has following sale items configured
        | 099999999990 | Sale Item A | 0.99   | 990000000002 | 990000000007 |
        | 088888888880 | Sale Item B | 1.99   | 990000000003 | 990000000007 |
        | 077777777770 | Sale Item C | 7.45   | 990000000004 | 990000000007 |

    @fast
    Scenario Outline: Attempt to scan a locked item, Locked item frame is displayed and the item is not added to the transaction.
        Given the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then the POS displays Locked frame
        And an item <description> with price <price> is not in the current transaction

        Examples:
        | barcode      | description | price  | item_id      | modifier1_id |
        | 099999999990 | Sale Item A | 0.99   | 990000000002 | 990000000007 |
        | 088888888880 | Sale Item B | 1.99   | 990000000003 | 990000000007 |

    @fast
    Scenario Outline: Set an item as locked, attempt to scan the item, Locked item frame is displayed and the item is not added to the transaction
        Given an item <item_id> with modifier <modifier1_id> is locked
        And the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then the POS displays Locked frame
        And an item <description> with price <price> is not in the current transaction

        Examples:
        | barcode      | description | price  | item_id      | modifier1_id |
        | 077777777770 | Sale Item C | 7.45   | 990000000004 | 990000000007 |

    @fast
    Scenario Outline: Set an item as unlocked, attempt to scan the item, Main menu frame is displayed and the item is added to the transaction
        Given an item <item_id> with modifier <modifier1_id> is not locked
        And the POS is in a ready to sell state
        When the cashier scans a barcode <barcode>
        Then the POS displays main menu frame
        And an item <description> with price <price> is in the virtual receipt
        And an item <description> with price <price> is in the current transaction

        Examples:
        | barcode      | description | price  | item_id      | modifier1_id |
        | 099999999990 | Sale Item A | 0.99   | 990000000002 | 990000000007 |
        | 088888888880 | Sale Item B | 1.99   | 990000000003 | 990000000007 |

    @manual @css
    Scenario Outline: A locked item is not displayed on CSS menu and cannot be selected
        Given an item <item_id> with modifier <modifier1_id> is locked
        And the CSS is in a ready to sell state
        And the CSS displays the screensaver
        When the customer presses the screensaver
        Then the CSS displays the main menu frame
        And an item <description> is not displayed on the current frame

        Examples:
        | barcode      | description | price  | item_id      | modifier1_id |
        | 099999999990 | Sale Item A | 0.99   | 990000000002 | 990000000007 |
        | 088888888880 | Sale Item B | 1.99   | 990000000003 | 990000000007 |