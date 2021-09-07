@pos  @print @print_receipt
Feature: Print a receipt

Background: The POS and the printer have default configuration
    Given the POS has essential configuration
    And the EPS simulator has essential configuration
    And the pricebook contains retail items
    | barcode      | description  | price   | weighted_item |
    | 123123123    | Round Item A | 17.00   | False         |
    | 321321321    | Round Item B | 17.11   | False         |
    | 0005         | Sale Item W1 | 1.25    | True          |
    And the POS has following sale items configured
    | barcode      | description | price  |
    | 099999999990 | Sale Item A | 0.99   |
    And a header section Header1 includes
    | line                                                            | variable             |
    |<span class="width-40 center bold">{$P_STORE_DESCRIPTION}</span> | $P_STORE_DESCRIPTION |
    |<span class="width-40 center bold">{$P_STORE_ADDRESS}</span>     | $P_STORE_ADDRESS     |
    And a header section Header2 includes
    |line                                                             | condition | variable             |
    |<span class="width-40 center bold">{$P_STORE_DESCRIPTION}</span> |           | $P_STORE_DESCRIPTION |
    |<span class="width-40 center bold">{$P_STORE_ADDRESS}</span>     | VOIDED    | $P_STORE_ADDRESS     |
    And a header section Header3 includes
    | line                                                            | condition        | variable             |
    |<span class="width-40 center bold">{$P_STORE_DESCRIPTION}</span> |                  | $P_STORE_DESCRIPTION |
    |<span class="width-40 center bold">{$P_STORE_ADDRESS}</span>     |                  | $P_STORE_ADDRESS     |
    |<span class="width-40 center">(MERCHANT RECEIPT)</span>          | MERCHANT_RECEIPT |                      |
    |<span class="width-40 center">(CUSTOMER RECEIPT)</span>          | CUSTOMER_RECEIPT |                      |
    And a detail section Item1 includes
    | line                                                             | condition          | variable                     |
    |<span class="width-40 left">{$P_ITEM_DESCRIPTION}</span>          | ITEM               | $P_ITEM_DESCRIPTION          |
    |<span class="width-40 left">{$P_ITEM_PRICE}</span>                | ITEM               | $P_ITEM_PRICE                |
    |<span class="width-40 left">{$P_ITEM_DESCRIPTION}</span>          | WEIGHTED_ITEM_SALE | $P_ITEM_DESCRIPTION          |
    |<span class="width-40 left">{$P_WEIGHTED_ITEM_DESCRIPTION}</span> | WEIGHTED_ITEM_SALE | $P_WEIGHTED_ITEM_DESCRIPTION |
    |<span class="width-40 left">{$P_ITEM_PRICE}</span>                | WEIGHTED_ITEM_SALE | $P_ITEM_PRICE                |
    # The BDD framework makes currently possible only 1 variable per line, thus, $P_WEIGHTED_ITEM_DESCRIPTION or $P_ITEM_DESCRIPTION
    # and $P_ITEM_PRICE must be printed on two lines despite on typical receipt printed on one line
    And a total section Total1 includes
    | line                                                                                           | variable     |
    |<span class="width-30 left">Sub. Total</span><span class="width-10 right">{$P_SUB_TOTAL}</span> | $P_SUB_TOTAL |
    And a total section Total2 includes
    | line                                                                                           | locale | variable     |
    |<span class="width-30 left">Sub. Total</span><span class="width-10 right">{$P_SUB_TOTAL}</span> | fr-CA  | $P_SUB_TOTAL |
    And a total section Total3 includes
    | line                                                                                                      | condition             | variable           |
    |<span class="width-30 left">Rounding Amount</span><span class="width-10 right">{$P_ROUNDING_AMOUNT}</span> | ROUNDING_AMOUNT_EXIST | $P_ROUNDING_AMOUNT |
    And a footer section Footer1 includes
    |line                                                                                      | condition | variable    |
    |<span class="width-30 left">Change</span><span class="width-10 right">{$P_BALANCE}</span> | CHANGE    | $P_BALANCE  |
    And a footer section Footer2 includes
    |line                                                                                          | condition                        | variable    |
    |<span class="width-30 left">Change NCB</span><span class="width-10 right">{$P_BALANCE}</span> | NOT_NO_CHANGE_BACK_TENDER_CHANGE | $P_BALANCE  |
    And the following receipts are available
    | receipt | section |
    | Rcpt1   | Header1 |
    | Rcpt1   | Total2  |
    | Rcpt2   | Total1  |
    | Rcpt2   | Footer1 |
    | Rcpt3   | Header2 |
    | Rcpt4   | Header3 |
    | Rcpt5   | Header1 |
    | Rcpt5   | Item1   |
    | Rcpt6   | Item1   |
    | Rcpt6   | Total3  |
    | Rcpt7   | Total1  |
    | Rcpt7   | Footer2 |


    @fast
    Scenario: The active receipt has a line with locale parameter set to non-used one, line does not appear on the printed receipt
        Given the POS has a receipt Rcpt1 set as active
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the transaction is tendered
        When the cashier presses print receipt button
        Then the receipt is printed with following lines
        | line                                                     |
        |<span class="width-40 center bold">POSBDD</span>          |
        |<span class="width-40 center bold">Python Lane 702</span> |


    @fast
    Scenario: The active receipt contains a line with a condition and variable included, line appears on the printed receipt
        Given the POS has a receipt Rcpt2 set as active
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the transaction is tendered
        When the cashier presses print receipt button
        Then the receipt is printed with following lines
        | line                                                                                   |
        | <span class="width-30 left">Sub. Total</span><span class="width-10 right">$0.99</span> |
        | <span class="width-30 left">Change</span><span class="width-10 right">$0.00</span>     |


    @fast
    Scenario: The active receipt contains line with a condition VOIDED included, line does not appear on a printed receipt of a regular sale transaction
        Given the POS has a receipt Rcpt3 set as active
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the transaction is tendered
        When the cashier presses print receipt button
        Then the receipt is printed with following lines
        | line                                            |
        |<span class="width-40 center bold">POSBDD</span> |


    @fast
    Scenario: Print a receipt from a transaction and validate the output (html-like or plaintext expected result).
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the transaction is tendered
        When the cashier presses print receipt button
        Then the receipt is printed with following lines
        | line                                          |
        |<span class="width-40 center bold">POSBDD</span>|
        |<span class="width-40 center bold">Python Lane 702</span>|
        |<span class="width-40 center bold">Behave City, BDD State 79201</span>|
        |<span class="width-40 center">------------------------------------------------------------------------</span>|
        |<span class="width-19 right">{{ tran_date }}</span><span class="width-2 left"></span><span class="width-19 left">{{ tran_time }}</span>|
        |<span class="width-40 left"></span>|
        |<span class="width-9 left">Register:</span><span class="left"> </span><span class="width-7 left">1</span><span class="width-13 left">Tran Seq No:</span><span class="width-10 right">{{ tran_number }}</span>|
        |<span class="width-9 left">Store No:</span><span class="left"> </span><span class="width-5 left">79201-1</span><span class="width-25 right">1234, 🞀Cashier🞁</span>|
        |<span class="width-40 left"></span>|
        |<span class="width-40 center">(CUSTOMER RECEIPT)</span>|
        |<span class="width-1 left">I</span><span class="width-4 left">1</span><span class="left"> </span><span class="width-24 left">Sale Item A</span><span class="left"> </span><span class="width-9 right">$0.99</span>|
        |<span class="width-40 right">-----------</span>|
        |<span class="width-30 left">Sub. Total:</span><span class="width-10 right">$0.99</span>|
        |<span class="width-30 left">Tax:</span><span class="width-10 right">$0.07</span>|
        |<span class="width-30 left">Total:</span><span class="width-10 right">$1.06</span>|
        |<span class="width-30 left">Discount Total:</span><span class="width-10 right">$0.00</span>|
        |<span class="width-40 left"></span>|
        |<span class="width-30 left">Cash</span><span class="width-10 right">$1.06</span>|
        |<span class="width-30 left">Change</span><span class="width-10 right">$0.00</span>|
        |<span class="width-40 center bold double-height">Thanks</span>|
        |<span class="width-40 center bold double-height">For Your Business</span>|
        |<span class="width-40 left"></span>|
        And the receipt is printed with following lines (plaintext)
        | line                                     |
        |*                 POSBDD                 *|
        |*            Python Lane 702             *|
        |*      Behave City, BDD State 79201      *|
        |*----------------------------------------*|
        |*    {{ tran_date }}  {{ tran_time }}    *|
        |*                                        *|
        |*    {{ register_and_tran_number }}      *|
        |*Store No: 79201          1234, 🞀Cashier🞁*|
        |*                                        *|
        |*           (CUSTOMER RECEIPT)           *|
        |*I1    Sale Item A                  $0.99*|
        |*                             -----------*|
        |*Sub. Total:                        $0.99*|
        |*Tax:                               $0.07*|
        |*Total:                             $1.06*|
        |*Discount Total:                    $0.00*|
        |*                                        *|
        |*Cash                               $1.06*|
        |*Change                             $0.00*|
        |*                 Thanks                 *|
        |*           For Your Business            *|
        |*                                        *|

    @fast
    Scenario: The active receipt has a line which prints customer or merchant receipt but only once receipt will be printed
        Given the POS has a receipt Rcpt4 set as active
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the transaction is tendered
        When the cashier presses print receipt button
        Then the receipt is printed with following lines
        | line                                                     |
        |<span class="width-40 center bold">POSBDD</span>          |
        |<span class="width-40 center bold">Python Lane 702</span> |
        |<span class="width-40 center">(CUSTOMER RECEIPT)</span>   |

    @fast
    Scenario: The active receipt has a line which prints customer or merchant receipt both will be printed the last one is customer receipt
        Given the Cash tender is configured to print twice
        And the POS has a receipt Rcpt4 set as active
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the transaction is tendered
        When the cashier presses print receipt button
        Then the receipt is printed with following lines
        | line                                                     |
        |<span class="width-40 center bold">POSBDD</span>          |
        |<span class="width-40 center bold">Python Lane 702</span> |
        |<span class="width-40 center">(CUSTOMER RECEIPT)</span>   |
        And the previous receipt is printed with following lines
        | line                                                     |
        |<span class="width-40 center bold">POSBDD</span>          |
        |<span class="width-40 center bold">Python Lane 702</span> |
        |<span class="width-40 center">(MERCHANT RECEIPT)</span>   |

    @fast
    Scenario: Perform sale transaction with rounding and verify total rounding amount printed on receipt
        Given the POS has a receipt Rcpt6 set as active
        # Rounding Method enabled to Round Nearest Value
        And the POS Option 1014 is set to 1
        # Rounding value enabled to value 500
        And the POS Option 1015 is set to 500
        # Set Print Rounding Item option to FALSE
        And the POS Option 1594 is set to 0
        And the POS is in a ready to sell state
        And an item with barcode 123123123 is present in the transaction
        And the transaction is tendered
        When the cashier presses print receipt button
        Then the receipt is printed with following lines
        | line                                           |
        |<span class="width-40 left">Round Item A</span> |
        |<span class="width-40 left">$17.00</span>       |
        # Rounding Total section verification
        |<span class="width-30 left">Rounding Amount</span><span class="width-10 right">$0.01</span>|

    @fast
    Scenario: Perform sale transaction without rounding and verify total rounding amount is not printed on receipt
        Given the POS has a receipt Rcpt6 set as active
        # Rounding Method enabled to Round Nearest Value
        And the POS Option 1014 is set to 1
        # Rounding value enabled to value 500
        And the POS Option 1015 is set to 500
        # Set Print Rounding Item option to FALSE
        And the POS Option 1594 is set to 0
        And the POS is in a ready to sell state
        And an item with barcode 321321321 is present in the transaction
        And the transaction is tendered
        When the cashier presses print receipt button
        Then the receipt is printed with following lines
        | line                                           |
        |<span class="width-40 left">Round Item B</span> |
        |<span class="width-40 left">$17.11</span>       |

    @fast
    Scenario: Peform sale transaction with rounding and verify rounding line item & Total rounding amount printed on receipt
        Given the POS has a receipt Rcpt6 set as active
        # Rounding Method enabled to Round Nearest Value
        And the POS Option 1014 is set to 1
        # Rounding value enabled to value 500
        And the POS Option 1015 is set to 500
        # Set Print Rounding Item option to TRUE
        And the POS Option 1594 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 123123123 is present in the transaction
        And the transaction is tendered
        When the cashier presses print receipt button
        # Then the receipt contains following lines
        Then the receipt is printed with following lines
        | line                                           |
        |<span class="width-40 left">Round Item A</span> |
        |<span class="width-40 left">$17.00</span>       |
        #Rounding Item detail section verification
        |<span class="width-40 left">Rounding</span>     |
        |<span class="width-40 left">$0.01</span>        |
        # Rounding Total section verification
        |<span class="width-30 left">Rounding Amount</span><span class="width-10 right">$0.01</span>|

    @fast
    Scenario: Perform sale transaction without rounding and verify no rounding line item & Total rounding amount printed on receipt
        Given the POS has a receipt Rcpt6 set as active
        # Rounding Method enabled to Round Nearest Value
        And the POS Option 1014 is set to 1
        # Rounding value enabled to value 500
        And the POS Option 1015 is set to 500
        # Set Print Rounding Item option to TRUE
        And the POS Option 1594 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 321321321 is present in the transaction
        And the transaction is tendered
        When the cashier presses print receipt button
        Then the receipt is printed with following lines
        | line                                           |
        |<span class="width-40 left">Round Item B</span> |
        |<span class="width-40 left">$17.11</span>       |

    @fast
    Scenario: Perform sale transaction with rounding and rounding line item is not configured but default set to TRUE
        Given the POS has a receipt Rcpt6 set as active
        # Rounding Method enabled to Round Nearest Value
        And the POS Option 1014 is set to 1
         # Rounding value enabled to value 500
        And the POS Option 1015 is set to 500
        And the POS is in a ready to sell state
        And an item with barcode 123123123 is present in the transaction
        And the transaction is tendered
        When the cashier presses print receipt button
        Then the receipt is printed with following lines
        | line                                           |
        |<span class="width-40 left">Round Item A</span> |
        |<span class="width-40 left">$17.00</span>       |
        #Rounding Item detail section verification
        |<span class="width-40 left">Rounding</span>     |
        |<span class="width-40 left">$0.01</span>        |
        # Rounding Total section verification
        |<span class="width-30 left">Rounding Amount</span><span class="width-10 right">$0.01</span>|

    @fast
    Scenario: Print a receipt from a transaction with weighted item and validate the output
        Given the POS has a receipt Rcpt5 set as active
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And a weighted item with barcode 0005 is present in the transaction with weight 2345
        And the transaction is tendered
        When the cashier presses print receipt button
        Then the receipt is printed with following lines
        | line                                           |
        |<span class="width-40 center bold">POSBDD</span>|
        |<span class="width-40 center bold">Python Lane 702</span>|
        |<span class="width-40 left">Sale Item A</span>|
        |<span class="width-40 left">$0.99</span>|
        |<span class="width-40 left">Sale Item W1</span>|
        |<span class="width-40 left">2.345 Kilograms @ $1.25/kg</span>|
        |<span class="width-40 left">$2.93</span>|


    @fast
    Scenario: Print change line on receipt for a transaction paid only by a tender which is eligible for change back, if printing condition NOT_NO_CHANGE_BACK_TENDER is configured for the line
        Given the POS has a receipt Rcpt7 set as active
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the cashier tendered transaction with cash
        When the cashier presses print receipt button
        Then the receipt is printed with following lines
        | line                                                                                   |
        | <span class="width-30 left">Sub. Total</span><span class="width-10 right">$0.99</span> |
        | <span class="width-30 left">Change NCB</span><span class="width-10 right">$0.00</span> |


    @fast
    Scenario: Do NOT print change line on receipt for a transaction paid only by a tender which is NOT eligible for change back, if printing condition NOT_NO_CHANGE_BACK_TENDER is configured for the line
        Given the POS has a receipt Rcpt7 set as active
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the cashier tendered transaction with credit
        When the cashier presses print receipt button
        Then the receipt is printed with following lines
        | line                                                                                   |
        | <span class="width-30 left">Sub. Total</span><span class="width-10 right">$0.99</span> |


    @fast
    Scenario: Print change line on receipt for a transaction paid by two tenders, the first one being eligible for change back and the other not being eligible for change back, if printing condition NOT_NO_CHANGE_BACK_TENDER is configured for the line
        Given the POS has a receipt Rcpt7 set as active
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the cashier tendered the transaction with 0.56 amount in cash
        And the cashier tendered transaction with credit
        When the cashier presses print receipt button
        Then the receipt is printed with following lines
        | line                                                                                   |
        | <span class="width-30 left">Sub. Total</span><span class="width-10 right">$0.99</span> |
        | <span class="width-30 left">Change NCB</span><span class="width-10 right">$0.00</span> |


    @fast
    Scenario: Print change line on receipt for a transaction paid by two tenders, the second one being eligible for change back and the other not being eligible for change back, if printing condition NOT_NO_CHANGE_BACK_TENDER is configured for the line
        Given the POS has a receipt Rcpt7 set as active
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And a 0.60 credit partial tender is present in the transaction
        And the cashier tendered the transaction with 0.56 amount in cash
        When the cashier presses print receipt button
        Then the receipt is printed with following lines
        | line                                                                                   |
        | <span class="width-30 left">Sub. Total</span><span class="width-10 right">$0.99</span> |
        | <span class="width-30 left">Change NCB</span><span class="width-10 right">$0.10</span> |
