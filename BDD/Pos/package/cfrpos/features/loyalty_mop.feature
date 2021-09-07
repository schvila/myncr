@pos @loyaltymop
Feature: LoyaltyMOP
    This feature tests RLM functionality to apply a loyalty discount as a MOP. The loyalty host is supposed to reply with
    the available discount, pinpad optionally prompts whether or not the customer wishes to apply the discount and if so, apply
    as much as possible given item restrictions, etc. Finally RPOS should report the transaction total and tax back to the host.
    Note that the customer confirmation prompt is an interaction solely between sigma and poscache so it is not included in POS
    product tests - should be covered in system level testing.

Background:
    Given the POS has essential configuration
    And the Sigma simulator has essential configuration
    And the POS has the feature Loyalty enabled
    # "Max methods of payment allowed" option set to "4"
    And the POS option 1215 is set to 4
    And the Sigma recognizes following cards
            | card_number       | card_description |
            | 12879784762398321 | Happy Card       |
    And the POS has following sale items configured
        | barcode       | description     | price |
        | 099999999990  | Sale Item A     | 0.99  |
        | 088888888880  | Sale Item B     | 1.99  |
        | 077777777770  | Sale Item C     | 1.49  |
        | 7777205       | Restricted Item | 50.00 |
    And an item Sale Item A with barcode 099999999990 and price 0.99 is eligible for LMOP discount 0.50 when using loyalty card 12879784762398321
    And an item Sale Item B with barcode 088888888880 and price 1.99 is eligible for LMOP discount 3.00 when using loyalty card 12879784762398321
    And an item Restricted Item with barcode 7777205 and price 50.00 is eligible for LMOP discount 10.00 when using loyalty card 12879784762398321
    And the POS has following tenders configured
        | tender_id  | description    | tender_type_id | exchange_rate | currency_symbol | external_id | tender_ranking |
        | 987        | Loyalty_points | 16             | 1             | $               | 987         | 6              |


    @fast
    Scenario: Loyalty host sends available discount (higher than transaction total), full amount is paid, POS sends a capture with
              the correct amount to host
        Given the POS is in a ready to sell state
        And an item with barcode 088888888880 is present in the transaction
        And a loyalty card 12879784762398321 with description Happy Card is present in the transaction
        When the cashier totals the transaction to receive the RLM loyalty discount
        Then the transaction is finalized
        And a tender Loyalty_points with amount 2.13 is in the previous transaction
        And a redeemed amount 2.13 is sent to loyalty host


    @fast
    Scenario: Loyalty host sends available discount (lower than transaction total), partial amount is paid
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And a loyalty card 12879784762398321 with description Happy Card is present in the transaction
        When the cashier totals the transaction to receive the RLM loyalty discount
        Then the POS displays Ask tender amount cash frame
        And the transaction's balance is 0.56
        And a tender Loyalty_points with amount 0.50 is in the current transaction


    @fast
    Scenario: Cashier tenders the rest of the transaction with cash after LoyaltyMOP was applied, transaction is finalized,
              POS sends a capture with the correct amount to host
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And a loyalty card 12879784762398321 with description Happy Card is present in the transaction
        And the POS displays Ask tender amount cash frame after LoyaltyMOP was applied
        When the cashier presses Exact dollar button
        Then the transaction is finalized
        And a tender Cash with amount 0.56 is in the previous transaction
        And a tender Loyalty_points with amount 0.50 is in the previous transaction
        And a redeemed amount 0.50 is sent to loyalty host


    @fast
    Scenario: Loyalty host sends a discount with restricted and unrestricted items in the transaction,
              only unrestricted items are discounted, Tender not allowed for these items error frame is displayed
        Given the POS is in a ready to sell state
        And an item with barcode 088888888880 is present in the transaction
        And an item with barcode 7777205 is present in the transaction
        And a loyalty card 12879784762398321 with description Happy Card is present in the transaction
        When the cashier totals the transaction to receive the RLM loyalty discount
        Then the POS displays Loyalty points cannot be used to pay for all items frame
        And the transaction's balance is 53.50
        And a tender Loyalty_points with amount 2.13 is in the current transaction


    @fast
    Scenario: Loyalty host sends a discount with only restricted items in the transaction, no discount is applied
        Given the POS is in a ready to sell state
        And an item with barcode 7777205 is present in the transaction
        And a loyalty card 12879784762398321 with description Happy Card is present in the transaction
        When the cashier totals the transaction using cash tender
        Then the POS displays Loyalty points cannot be used to pay for all items frame
        And the transaction's balance is 53.50
        And a tender Loyalty_points is not in the current transaction


    @fast
    Scenario: Loyalty host sends a discount with multiple unrestricted items in the transaction, sum of the individual discounts
              is applied (higher than balance), pinpad prompts only for the highest one (if enabled), transaction is finalized
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And an item with barcode 088888888880 is present in the transaction
        And a loyalty card 12879784762398321 with description Happy Card is present in the transaction
        When the cashier totals the transaction to receive the RLM loyalty discount
        Then the transaction is finalized
        And a tender Loyalty_points with amount 2.69 is in the previous transaction
        And a tender Loyalty_points with amount 0.50 is in the previous transaction
        And a redeemed amount 2.69 is sent to loyalty host
        And a redeemed amount 0.50 is sent to loyalty host


    @fast
    Scenario: Loyalty host sends a discount with multiple unrestricted items in the transaction, sum of the individual discounts
              is applied (lower than balance), pinpad prompts only for the highest one
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And an item with barcode 088888888880 is present in the transaction
        And an item with barcode 077777777770 is present in the transaction
        And a loyalty card 12879784762398321 with description Happy Card is present in the transaction
        When the cashier totals the transaction to receive the RLM loyalty discount
        Then the POS displays Ask tender amount cash frame
        And the transaction's balance is 1.28
        And a tender Loyalty_points with amount 3.00 is in the current transaction
        And a tender Loyalty_points with amount 0.50 is in the current transaction
        And a redeemed amount 3.00 is sent to loyalty host
        And a redeemed amount 0.50 is sent to loyalty host


    @fast @manual
    # Sigma transaction still has loyalty points tender with 0.50 amount, would be ok if it was AUTH CANCEL or VOID,
    # CAPTURE should be 0.00
    Scenario: Cashier voids the transaction after LoyaltyMOP was applied, no amount was captured
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And a loyalty card 12879784762398321 with description Happy Card is present in the transaction
        And the POS displays Ask tender amount cash frame after LoyaltyMOP was applied
        When the cashier voids the transaction
        Then no transaction is in progress
        And a tender Loyalty_points with amount 0.50 is in the previous transaction
        And a redeemed amount 0.00 is sent to loyalty host


    @fast @manual @print_receipt
    # Sigma sim does not provide any loyalty information, manual only, should be tested by system level automation
    Scenario: The loyalty footer section on the printed receipt includes transaction total and discounted amount
        Given a loyalty_footer section LoyaltyFooter includes
            | line                                                                 | variable                       |
            | <span class="width-40 left">{$P_LOYALTY_RECEIPT_FOOTER_LINE}</span>  | $P_LOYALTY_RECEIPT_FOOTER_LINE |
        And the following receipts are available
            | receipt | section       |
            | LoyRcpt | LoyaltyFooter |
        And the POS has a receipt LoyRcpt set as active
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And a loyalty card 12879784762398321 with description Happy Card is present in the transaction
        And the transaction was tendered with cash after LoyaltyMOP was applied
        When the cashier presses print receipt button
        Then the receipt is printed with following lines (plaintext)
        | line                                     |
        |*Radiant Loyalty                         *|
        |*Card Num : XXXXXXXXXXXXX8321            *|
        |*Terminal : 123                          *|
        |*Approval : 1234567890                   *|
        |*                                        *|
        |*Point Balance :                         *|
        |*Default Club :                          *|
        |*            customer message            *|
        |*  This whole section will have to be    *|
        |*  coordinated with SigmaAPI sim dev     *|
