@pos @certegy
Feature: Certegy feature
   This feature file tests/covers transaction flow with certegy checks. The enhancement was to print a receipt slip with
   check terms and possible fees before EOT (end of transaction) so the tender can be cancelled should the customer not
   sign the receipt. The transaction stays open in that case and can be tendered with other MOP or voided.

    Background:
        Given the POS has essential configuration
        And the POS has the feature Loyalty enabled
        And the EPS simulator has essential configuration
        And the EPS simulator uses ECHECK_APPROVAL card configuration
        And the Sigma simulator has essential configuration
        And the Sigma recognizes following cards
            | card_number       | card_description |
            | 12879784762398321 | Happy Card       |
        # "Enter check data manually" pos option is allowed
        And the POS option 1864 is set to 1
        And the POS has e-check tender configured
        | description  | tender_id   | external_id   |
        | E-check      | 70000000038 | 00038         |
        And the POS has e-check reader configured

    @fast
    Scenario: Cashier presses e-check tender button, Manual check transit frame is displayed
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the cashier selects the e-check tender button
        Then the POS displays Manual check transit entry frame


    @fast
    Scenario: Cashier enters e-check data manually on Manual check transit frame, Manual check account frame is displayed
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the POS displays Manual check transit entry frame after selecting e-check tender button
        When the cashier enters the check transit number 123456789
        Then the POS displays Manual check account entry frame


    @fast
    Scenario: Cashier enters e-check data manually on Manual check account frame, Manual check sequence frame is displayed
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the POS displays Manual check account entry frame
        When the cashier enters the check account number 987654321
        Then the POS displays Manual check sequence entry frame


    @fast
    Scenario: Cashier presses Go Back button on Manual check account frame, Manual check transit frame is displayed
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the POS displays Manual check account entry frame
        When the cashier presses Go back button
        Then the POS displays Manual check transit entry frame


    @fast
    Scenario: Cashier enters e-check data manually on Manual check sequence frame, Ask tender amount check frame is displayed
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the POS displays Manual check sequence entry frame
        When the cashier enters the check sequence number 1234
        Then the POS displays Ask tender amount check frame


    @fast
    Scenario: Cashier presses Go Back button on Manual check sequence frame, Ask tender amount check frame is displayed
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the POS displays Manual check sequence entry frame
        When the cashier presses Go back button
        Then the POS displays Manual check account entry frame


    @fast
    Scenario: Customer swipes e-check, Ask tender amount check frame is displayed
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the POS displays Manual check transit entry frame after selecting e-check tender button
        When the customer swipes e-check Paragon check
        Then the POS displays Ask tender amount check frame


    @fast @print_receipt
    Scenario: Cashier selects amount on Ask tender amount check frame after swiping a check, the check terms slip is printed,
              Did customer agree to check terms frame is displayed
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the POS displays Ask tender amount check frame after swiping an e-check Paragon check
        When the cashier enters 1.00 dollar amount in Ask tender amount check frame
        Then the POS displays Did customer agree to check terms frame
        And the receipt is printed with following lines
        | line                                                                                               |
        | <span class="width-40 center">E-CHECK AGREEMENT SLIP RECEIPT</span>                                |
        | <span class="left"></span>                                                                         |
        | <span class="width-9 left">Register:</span><span class="width-8 left"> 1</span><span class="width-13 left">Tran Seq No:</span><span class="width-10 right">{{ tran_number }}</span>     |
        | <span class="width-30 left">Transaction Total:</span><span class="width-10 right">$1.06</span>     |
        | <span class="width-30 left">E-check:</span><span class="width-10 right">($1.00)</span>             |
        | <span class="left"></span>                                                                         |
        | <span class="left">Auth Code: 99999999</span>                                                      |
        | <span class="left">Ref: 123456789012345</span>                                                     |
        | <span class="left">Certegy UID: 987654321098765</span>                                             |
        | <span class="left"></span>                                                                         |
        | <span class="left">I authorize the use of the information</span>                                   |
        | <span class="left">from my check to make a one-time</span>                                         |
        | <span class="left">electronic funds transfer (EFT) or</span>                                       |
        | <span class="left">back draft from my account for the</span>                                       |
        | <span class="left">amount of the check or to process this</span>                                   |
        | <span class="left">payment as a check transaction. If my</span>                                    |
        | <span class="left">payment is returned due to</span>                                               |
        | <span class="left">insufficient or uncollected funds, I</span>                                     |
        | <span class="left">authorize the collection of the</span>                                          |
        | <span class="left">service charge. including a one-time</span>                                     |
        | <span class="left">EFT or bank draft from my account in</span>                                     |
        | <span class="left">the amount of $5.25.</span>                                                     |
        | <span class="left">Signature: _______________</span>                                               |
        | <span class="left">THANK YOU</span>                                                                |
        | <span class="left">ANY QUESTIONS, CALL CERTEGY</span>                                              |
        | <span class="left">1-800-539-3677</span>                                                           |
        | <span class="left"></span>                                                                         |
        | <span class="left"></span>                                                                         |


    @fast
    Scenario: Cashier presses Go Back button on Ask tender amount check frame after swiping a check, Manual check transit frame is displayed
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the POS displays Ask tender amount check frame after swiping an e-check Paragon check
        When the cashier presses Go back button
        Then the POS displays Manual check transit entry frame


    @fast
    Scenario: Cashier presses Go Back button on Ask tender amount check frame after manually entering check data, Manual check sequence frame is displayed
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the POS displays Ask tender amount check frame after manually entering check data
        When the cashier presses Go back button
        Then the POS displays Manual check sequence entry frame


    @fast
    Scenario: Tender transaction with e-check, check terms slip is signed, the transaction is finalized
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the POS displays Did customer agree to check terms frame after swiping a check Paragon check
        When the cashier presses Yes on Did customer agree to check terms frame
        Then the transaction is finalized
        And a tender e-check with amount 1.06 is in the previous transaction


    @fast
    Scenario: Tender transaction with e-check, check terms slip is not signed, e-check tender is rolled back, transaction is in progress
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the POS displays Did customer agree to check terms frame after swiping a check Paragon check
        When the cashier presses No on Did customer agree to check terms frame
        Then a tender e-check with amount 1.06 is not in the current transaction
        And a transaction is in progress


    @fast @manual
    Scenario: POS Option for manual entry disabled, Cashier presses e-check tender button, Manual check transit frame is displayed
        # TODO investigate why the Please swipe check is skipped and the tender progresses without check swipe or manual entry
        # "Enter check data manually" pos option is disabled
        Given the POS option 1864 is set to 0
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the cashier selects the e-check tender button
        Then the POS displays Please swipe check frame


    @fast
    Scenario Outline: Tender transaction partially, first with e-check and then with another tender, transaction is finalized
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction 3 times
        And a 1.0 e-check partial tender is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in <tender_type>
        Then the transaction is finalized
        And a tender e-check with amount 1.00 is in the previous transaction
        And a tender <tender_type> with amount 2.18 is in the previous transaction

        Examples:
        | tender_type      |
        | cash             |
        | gift certificate |
        | credit           |


    @fast
    Scenario Outline: Tender transaction partially, first with non-check tender and then with e-check, transaction is finalized
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction 3 times
        And a 1.0 <tender_type> partial tender is present in the transaction
        And the POS displays Did customer agree to check terms frame after swiping a check Paragon check
        When the cashier presses Yes on Did customer agree to check terms frame
        Then the transaction is finalized
        And a tender <tender_type> with amount 1.00 is in the previous transaction
        And a tender e-check with amount 2.18 is in the previous transaction

        Examples:
        | tender_type      |
        | cash             |
        | gift certificate |
        | credit           |


    @fast
    Scenario: Tender transaction partially with two e-checks, transaction is finalized
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction 3 times
        And a 1.0 e-check partial tender is present in the transaction
        And the POS displays Did customer agree to check terms frame after swiping a check Valid e-check
        When the cashier presses Yes on Did customer agree to check terms frame
        Then the transaction is finalized
        And a tender e-check with amount 1.00 is in the previous transaction
        And a tender e-check with amount 2.18 is in the previous transaction


    @fast
    Scenario Outline: Attempt to tender transaction partially, first with non-check tender and then with e-check,
                      check terms slip is not signed, e-check tender is rolled back, the transaction is in progress
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction 3 times
        And a 1.0 <tender_type> partial tender is present in the transaction
        And the POS displays Did customer agree to check terms frame after swiping a check Paragon check
        When the cashier presses No on Did customer agree to check terms frame
        Then a transaction is in progress
        And a tender <tender_type> with amount 1.0 is in the current transaction
        And a tender e-check is not in the current transaction

        Examples:
        | tender_type      |
        | cash             |
        | gift certificate |
        | credit           |


    @fast
    Scenario Outline: Attempt to tender transaction partially, first with e-check, check terms slip is not signed,
                      e-check tender is rolled back, transaction is finalized with another tender
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction 3 times
        And the cashier tendered the transaction with amount 1.0 by swiping an e-check Paragon check
        And the cashier pressed No on Did customer agree to check terms frame
        When the cashier tenders the transaction with hotkey exact_dollar in <tender_type>
        Then the transaction is finalized
        And a tender <tender_type> with amount 3.18 is in the previous transaction
        And a tender e-check is not in the previous transaction

        Examples:
        | tender_type      |
        | cash             |
        | gift certificate |
        | credit           |


    @fast
    Scenario: Tender transaction with loyalty using e-check, discount is awarded, check terms slip is signed,
              loyalty capture is sent to the host with the correct amount
        Given an item Sale Item A with barcode 099999999990 and price 0.99 is eligible for discount cash 0.50 when using loyalty card 12879784762398321
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And a loyalty card 12879784762398321 with description Happy Card is present in the transaction
        And the POS displays Did customer agree to check terms frame after swiping a check Paragon check
        When the cashier presses Yes on Did customer agree to check terms frame
        Then the transaction is finalized
        And a tender e-check with amount 0.52 is in the previous transaction
        And a RLM discount Loyalty Discount with value of -0.5 is in the previous transaction
        And loyalty capture for amount 0.52 is sent to loyalty host


    @manual
    Scenario: Tender transaction with loyalty using e-check, discount is awarded, check terms slip is not signed,
              the loyalty capture is not sent to the host, transaction is in progress
        Given an item Sale Item A with barcode 099999999990 and price 0.99 is eligible for discount cash 0.50 when using loyalty card 12879784762398321
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And a loyalty card 12879784762398321 with description Happy Card is present in the transaction
        And the POS displays Did customer agree to check terms frame after swiping a check Paragon check
        When the cashier presses No on Did customer agree to check terms frame
        Then a transaction is in progress
        And a tender e-check is not in the current transaction
        And a RLM discount Loyalty Discount with value of -0.5 is in the current transaction
        And loyalty capture for amount 0.52 is not sent to loyalty host


    @fast
    Scenario: Tender transaction with postpay using e-check, check terms slip is not signed, the tender is rolled back,
              the fuel is not paid for and remains in the transaction/on the pump
        Given the POS is in a ready to sell state
        And a Premium postpay fuel with 10.00 price on pump 2 is present in the transaction
        And the POS displays Did customer agree to check terms frame after swiping a check Paragon check
        When the cashier presses No on Did customer agree to check terms frame
        Then a transaction is in progress
        And a tender e-check is not in the current transaction
        And an item 2.500G Premium with price 10.00 is in the virtual receipt


    @fast
    Scenario: Tender transaction with prepay using e-check, check terms slip is not signed, the tender is rolled back,
              the fuel is not paid for and remains in the transaction, pump is not authorized for dispensing
        # Set Prepay Grade Select Type option as One Touch
        Given the POS option 5124 is set to 1
        And the POS is in a ready to sell state
        And a Regular prepay fuel with 10.00 price on pump 1 is present in the transaction
        And the POS displays Did customer agree to check terms frame after swiping a check Paragon check
        When the cashier presses No on Did customer agree to check terms frame
        Then a transaction is in progress
        And a tender e-check is not in the current transaction
        And a pump 1 is not authorized