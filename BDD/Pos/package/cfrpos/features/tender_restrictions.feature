@pos
Feature: Tender restrictions
    This feature file covers tender restriction scenarios. For example, an item with level 3 can only be paid for by tenders with level 3 or lower.

    Background: The POS has essential configuration.
        Given the POS has essential configuration
        And the pricebook contains retail items
            | barcode      | description       | price  | tender_itemizer_rank |
            | 011111222220 | Restricted Item A | 1.50   | 2                    |
            | 011111333330 | Restricted Item B | 2.50   | 4                    |


        @fast
        Scenario: Add restricted item to the transaction, attempt to pay using a tender with higher restriction level than the item, the tender button is disabled.
            Given the POS has following tenders configured
            | description  | tender_id   | tender_type_id | external_id   | tender_ranking  |
            | Tender_A     | 12345       | 102            | 12345         | 3               |
            And the POS is in a ready to sell state
            When the cashier scans a barcode 011111222220
            Then the Tender_A tender button with external id 12345 and type id 102 is disabled
            And an item Restricted Item A with price 1.50 is in the virtual receipt
            And an item Restricted Item A with price 1.50 is in the current transaction


        @fast
        Scenario Outline: Add restricted item to the transaction, pay using a tender with equal to/lower restriction level than the item,
                         the transaction is finalized.
            Given the POS has following tenders configured
            | description  | tender_id   | tender_type_id | external_id   | tender_ranking      |
            | Tender_A     | 12345       | 102            | 12345         | <restriction_level> |
            And the POS is in a ready to sell state
            And an item with barcode 011111222220 is present in the transaction
            And the POS displays Amount selection frame after selecting Tender_A tender with external id 12345 and type id 102
            When the cashier tenders the transaction with exact-dollar on the current frame
            Then the transaction is finalized
            And a tender Tender_A with amount 1.61 is in the previous transaction
            And an item Restricted Item A with price 1.50 and type 1 is in the previous transaction

            Examples:
            | restriction_level |
            | 1                 |
            | 2                 |


        @fast
        Scenario: Add two items to the transaction, restricted and non-restricted, tender the transaction with tender
                having restriction level set higher than the restricted item, only the non-restricted item is tendered.
            Given the POS has following tenders configured
            | description  | tender_id   | tender_type_id | external_id   | tender_ranking |
            | Tender_A     | 12345       | 102            | 12345         | 3              |
            And the POS is in a ready to sell state
            And an item with barcode 011111222220 is present in the transaction
            And an item with barcode 099999999990 is present in the transaction
            And the POS displays Amount selection frame after selecting Tender_A tender with external id 12345 and type id 102
            When the cashier tenders the transaction with exact-dollar on the current frame
            Then an item Restricted Item A with price 1.50 is in the virtual receipt
            And an item Restricted Item A with price 1.50 is in the current transaction
            And a tender Tender_A with amount 1.06 is in the virtual receipt
            And a tender Tender_A with amount 1.06 is in the current transaction
            And the transaction's balance is 1.60


        @fast
        Scenario: Add two items with different restriction levels to the transaction, tender the transaction with tender
                having restriction level set higher than one of the items, only the item with lower restriction level is tendered.
            Given the POS has following tenders configured
            | description  | tender_id   | tender_type_id | external_id   | tender_ranking |
            | Tender_A     | 12345       | 102            | 12345         | 3              |
            And the POS is in a ready to sell state
            And an item with barcode 011111222220 is present in the transaction
            And an item with barcode 011111333330 is present in the transaction
            And the POS displays Amount selection frame after selecting Tender_A tender with external id 12345 and type id 102
            When the cashier tenders the transaction with exact-dollar on the current frame
            Then an item Restricted Item A with price 1.50 is in the virtual receipt
            And an item Restricted Item A with price 1.50 is in the current transaction
            And an item Restricted Item B with price 2.50 is in the virtual receipt
            And an item Restricted Item B with price 2.50 is in the current transaction
            And a tender Tender_A with amount 2.68 is in the virtual receipt
            And a tender Tender_A with amount 2.68 is in the current transaction
            And the transaction's balance is 1.60
