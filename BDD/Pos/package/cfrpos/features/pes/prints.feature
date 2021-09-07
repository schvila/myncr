@pos @pes @print_receipt
Feature: Promotion Execution Service - prints
    This feature file focuses on printing data received from PES onto the loyalty footer/header receipt sections as well
    as other related information.

    Background: POS is configured for PES feature
        Given the POS has essential configuration
        And the POS is configured to communicate with PES
        # Cloud Loyalty Interface is set to PES
        And the POS option 5284 is set to 1
        And the nep-server has default configuration
        # Default Loyalty Discount Id is set to PES_basic
        And the POS parameter 120 is set to PES_basic
        And the POS has following discounts configured
            | reduction_id | description | price | external_id |
            | 1            | PES loyalty | 0.00  | PES_basic   |
        And the pricebook contains retail items
            | description | price | item_id | barcode | credit_category | category_code |
            | Coca Cola   | 2.39  | 222     | 002     | 2018            | 421           |
        And the POS recognizes following PES cards
            | card_definition_id | card_role | card_name | barcode_range_from | card_definition_group_id |
            | 70000001142        | 3         | PES card  | 3104174102936582   | 70000010042              |
        And a header section Header includes
            |line                                                                                               | variable     |
            |<span class="width-30 left">Register:</span><span class="width-10 right">{$P_REGISTER}</span>      | $P_REGISTER  |
        And a loyalty_header section LoyaltyHeader includes
            | line                                                                | variable                       |
            | <span class="width-40 left">{$P_LOYALTY_RECEIPT_HEADER_LINE}</span> | $P_LOYALTY_RECEIPT_HEADER_LINE |
        And a loyalty_footer section LoyaltyFooter includes
            | line                                                                | variable                       |
            | <span class="width-40 left">{$P_LOYALTY_RECEIPT_FOOTER_LINE}</span> | $P_LOYALTY_RECEIPT_FOOTER_LINE |
        And a detail section Items includes
            | line                                                     | condition | variable            |
            | <span class="width-40 left">{$P_ITEM_DESCRIPTION}</span> | ITEM      | $P_ITEM_DESCRIPTION |
            | <span class="width-40 left">{$P_ITEM_PRICE}</span>       | ITEM      | $P_ITEM_PRICE       |
        And the following receipts are available
            | receipt    | section       |
            | PesReceipt | Header        |
            | PesReceipt | LoyaltyHeader |
            | PesReceipt | Items         |
            | PesReceipt | LoyaltyFooter |
        And the POS has a receipt PesReceipt set as active


    @fast
    Scenario: The POS prints and displays Loyalty Balance Inquiry info received in Get promotions response
        Given the POS is in a ready to sell state
        And the nep-server has following receipt message configured for GetPromotions request
            | content           | type | location | alignment | formats         | line_break                  |
            | Points activity   | TEXT | DEFAULT  | LEFT      | BOLD            | NO_BREAK_LINE               |
            | Earned 156 points | TEXT | DEFAULT  | LEFT      | NO_FORMATTING,  | LINE_BREAK_BEFORE_PRINTLINE |
            | Used 156 points   | TEXT | DEFAULT  | LEFT      | UNDERLINE, BOLD | PRINTER_CUT_AFTER_PRINTLINE |
            | Thank you         | TEXT | DEFAULT  | LEFT      | NO_FORMATTING   | LINE_BREAK_AFTER_PRINTLINE  |
        And the POS displays other functions frame
        And the cashier pressed Loyalty Balance Inquiry button
        When the cashier scans PES loyalty card 3104174102936582
        Then the POS displays Balance Inquiry frame
        And the receipt contains following lines
            | line                                                      |
            | <span class="left bold">Points activity</span>            |
            | <span class="left">Earned 156 points</span>               |
            | <span class="left bold underlined">Used 156 points</span> |
            | <span class="left">Thank you</span>                       |


    @fast
    Scenario: The POS prints PES loyalty info received in FinalizePromotions request in a newly created receipt
        Given the POS is in a ready to sell state
        And the nep-server has following receipt message configured for GetPromotions request
            | content              | type | location | alignment | formats                      | line_break    |
            | This is the footer   | TEXT | BACK     | LEFT      | DOUBLE_HIGH                  | NO_LINE_BREAK |
            | Footer has two lines | TEXT | BACK     | CENTER    | BOLD, DOUBLE_WIDE, UNDERLINE | NO_LINE_BREAK |
            | This is the header   | TEXT | FRONT    | RIGHT     | NO_FORMATTING                | NO_LINE_BREAK |
        And the nep-server has following receipt message configured for FinalizePromotions request
            | content              | type | location | alignment | formats                      | line_break    |
            | This is the footer   | TEXT | BACK     | LEFT      | DOUBLE_HIGH                  | NO_LINE_BREAK |
            | Footer has two lines | TEXT | BACK     | CENTER    | BOLD, DOUBLE_WIDE, UNDERLINE | NO_LINE_BREAK |
            | This is the header   | TEXT | FRONT    | RIGHT     | NO_FORMATTING                | NO_LINE_BREAK |
        And an item with barcode 002 is present in the transaction
        And the transaction is finalized
        When the cashier presses print receipt button
        Then the receipt is printed with following lines
            | line                                                                              |
            | <span class="width-30 left">Register:</span><span class="width-10 right">1</span> |
            | <span class="left"></span>                                                        |
            | <span class="right">This is the header</span>                                     |
            | <span class="left"></span>                                                        |
            | <span class="width-40 left">Coca Cola</span>                                      |
            | <span class="width-40 left">$2.39</span>                                          |
            | <span class="left"></span>                                                        |
            | <span class="left double-height">This is the footer</span>                        |
            | <span class="center bold double-width underlined">Footer has two lines</span>     |
            | <span class="left"></span>                                                        |


    @slow
    Scenario: The POS prints PES loyalty info received in GetPromotions when FinalizePromotions was not received in time
        Given the POS is in a ready to sell state
        And the nep-server has following receipt message configured for GetPromotions request
            | content                             | type | location | alignment | formats                | line_break    |
            | Welcome to PES loyalty              | TEXT | FRONT    | LEFT      | UNDERLINE, DOUBLE_HIGH | NO_LINE_BREAK |
            | Thank you for using our loyalty     | TEXT | BACK     | CENTER    | BOLD, DOUBLE_WIDE      | NO_LINE_BREAK |
            | You are getting many cool discounts | TEXT | BACK     | RIGHT     | NO_FORMATTING          | NO_LINE_BREAK |
        And the nep-server has following receipt message configured for FinalizePromotions request
            | content                     | type | location | alignment | formats                      | line_break    |
            | Greetings to PES loyalty    | TEXT | FRONT    | LEFT      | DOUBLE_HIGH                  | NO_LINE_BREAK |
            | This should not get printed | TEXT | BACK     | CENTER    | BOLD, DOUBLE_WIDE, UNDERLINE | NO_LINE_BREAK |
            | Enjoy best discounts        | TEXT | BACK     | RIGHT     | NO_FORMATTING                | NO_LINE_BREAK |
        And an item with barcode 002 is present in the transaction
        And the PES has 7 seconds delay for FinalizePromotions request
        And the transaction is finalized
        When the cashier presses print receipt button
        Then the receipt contains following lines
            | line                                                                          |
            | <span class="left double-height underlined">Welcome to PES loyalty</span>     |
            | <span class="center bold double-width">Thank you for using our loyalty</span> |
            | <span class="right">You are getting many cool discounts</span>                |


    @fast
    Scenario: Reprint PAP transaction tendered by PES discounts
        Given the POS is in a ready to sell state
        And the customer performed PAP transaction on pump 2 for amount 20.00 with PES discount applied as tender
        And the cashier selected last transaction on the Scroll previous list
        When the cashier prints the selected transaction in Scroll previous list
        Then the receipt contains following lines
            | line                                                                          |
            | <span class="left double-height underlined">Welcome to PES loyalty</span>     |
            | <span class="center bold double-width">Thank you for using our loyalty</span> |
            | <span class="right">You are getting many cool discounts</span>                |


    @fast
    Scenario: Reprint PAP transaction tendered partially with PES discounts
        Given the POS is in a ready to sell state
        And the customer performed PAP transaction on pump 2 for amount 20.00 partially tendered with PES discount for value 10.00
        And the cashier selected last transaction on the Scroll previous list
        When the cashier prints the selected transaction in Scroll previous list
        Then the receipt contains following lines
            | line                                                                          |
            | <span class="left double-height underlined">Welcome to PES loyalty</span>     |
            | <span class="center bold double-width">Thank you for using our loyalty</span> |
            | <span class="right">You are getting many cool discounts</span>                |


    @fast
    Scenario: Reprint transaction tendered with loyalty points on another POS node.
        Given the POS is in a ready to sell state
        And a transaction with Sale Item A was tendered by loyalty points on POS 2
        And the cashier selected last transaction on the Scroll previous list
        When the cashier prints the selected transaction in Scroll previous list
        Then the receipt contains following lines
        | line                                                                                                                                                                                                               |
        | <span class="width-30 left">Register:</span><span class="width-10 right">2</span> |
        | <span class="width-40 left">Sale Item A</span>                                    |
        | <span class="width-40 left">$0.99</span>                                          |
        | <span class="left double-height underlined">Welcome to PES loyalty</span>         |
        | <span class="center bold double-width">Thank you for using our loyalty</span>     |
        | <span class="right">You are getting many cool discounts</span>                    |


    @fast
    Scenario: Transaction is finalized while the PES server is offline, no loyalty receipt section is printed.
        Given the POS is in a ready to sell state
        And the nep-server has following receipt message configured for FinalizePromotions request
            | content             | type | location | alignment | formats     | line_break    |
            | PES Loyalty Message | TEXT | FRONT    | CENTER    | DOUBLE_HIGH | NO_LINE_BREAK |
        And the transaction with a barcode 002 is finalized while the PES server is offline
        When the cashier presses print receipt button
        Then the receipt does not contain following lines
            | line                                                          |
            | <span class="center double-height">PES Loyalty Message</span> |


    @glacial
    Scenario: Transaction is finalized while the PES server is offline, the FinalizePromotions is repeated after any following
              request receives a response, print receipt of the first tran, the loyalty receipt section is included.
        Given the POS is in a ready to sell state
        And the nep-server has following receipt message configured for FinalizePromotions request
            | content             | type | location | alignment | formats     | line_break    |
            | PES Loyalty Message | TEXT | FRONT    | CENTER    | DOUBLE_HIGH | NO_LINE_BREAK |
        And the transaction with a barcode 002 is finalized while the PES server is offline
        And the nep-server is online after 10 seconds
        And the POS sends a GetPromotions request to PES after scanning an item with barcode 099999999990
        And the PES receives FinalizePromotions request within 120 seconds
        And the cashier tendered transaction with cash
        And the cashier selected next to last transaction on the Scroll previous list
        When the cashier prints the selected transaction in Scroll previous list
        Then the receipt contains following lines
            | line                                                          |
            | <span class="center double-height">PES Loyalty Message</span> |


    @positive @fast
    Scenario: Prepay is added into transaction, transaction is tendered, prepaid fuel is dispensed,
        SyncFinalize message is sent, the response is received and the receipt is updated
        # Set Fuel credit prepay method to Auth and Capture
        Given the POS option 1851 is set to 1
        # Set Prepay Grade Select Type option as One Touch
        And the POS option 5124 is set to 1
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        And the POS option 5277 is set to 1
        And the POS is in a ready to sell state
        And the nep-server has following receipt message configured for FinalizePromotions request
            | content             | type | location | alignment | formats     | line_break    |
            | PES Loyalty Message | TEXT | FRONT    | CENTER    | DOUBLE_HIGH | NO_LINE_BREAK |
        And the PES has 3 seconds delay for FinalizePromotions request
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the prepay of the fuel grade regular with price 5.00 at pump id 1 is present in the transaction
        And the transaction is tendered
        And the customer dispensed regular for 5.00 price at pump 1
        And the POS processes the FinalizePromotions response
        When the cashier prints the last prepay transaction on the Scroll previous list
        Then the receipt contains following lines
            | line                                                          |
            | <span class="center double-height">PES Loyalty Message</span> |
            | <span class="width-40 left">PES card</span>                   |
            | <span class="width-40 left">$0.00</span>                      |
            | <span class="width-40 left">Sale Item A</span>                |
            | <span class="width-40 left">$0.99</span>                      |


    @positive @fast
    Scenario: Prepay is added into transaction, transaction is tendered, prepaid fuel is under-dispensed,
        cashier refunds the fuel, SyncFinalize message is sent, the response is received and receipt is updated
        # Set Fuel credit prepay method to Auth and Capture
        Given the POS option 1851 is set to 1
        # Set Prepay Grade Select Type option as One Touch
        And the POS option 5124 is set to 1
        # Promotion Execution Service Get Mode is set to PES Get After Subtotal
        And the POS option 5277 is set to 1
        And the POS is in a ready to sell state
        And the nep-server has following receipt message configured for FinalizePromotions request
            | content             | type | location | alignment | formats     | line_break    |
            | PES Loyalty Message | TEXT | FRONT    | CENTER    | DOUBLE_HIGH | NO_LINE_BREAK |
        And the PES has 3 seconds delay for FinalizePromotions request
        And a PES loyalty card 3104174102936582 is present in the transaction
        And an item with barcode 099999999990 is present in the transaction
        And the prepay of the fuel grade regular with price 5.00 at pump id 1 is present in the transaction
        And the transaction is tendered
        And the customer dispensed regular for 4.00 price at pump 1
        And the cashier refunds the fuel from pump 1
        And the POS processes the FinalizePromotions response
        When the cashier presses print receipt button
        Then the receipt contains following lines
            | line                                                          |
            | <span class="center double-height">PES Loyalty Message</span> |
            | <span class="width-40 left">PES card</span>                   |
            | <span class="width-40 left">$0.00</span>                      |
            | <span class="width-40 left">Sale Item A</span>                |
            | <span class="width-40 left">$0.99</span>                      |
