@pos @tender
Feature: Tender transaction
    Transaction can be tendered.

Background: The POS has essential configuration to be able to tender any items.
    Given the POS has essential configuration
    And the EPS simulator has essential configuration
    And the POS option 1109 is set to 1
    # Allow manufacturer coupons set to Yes
    And the EPS simulator uses default card configuration
    And the POS has following tenders configured
    | tender_id  | description   | tender_type_id | exchange_rate | currency_symbol | external_id  |
    | 777        | MFC_tender    | 21             | 1             | $               | 777          |
    And the POS has following sale items configured
    | barcode      | description | price  |
    | 099999999990 | Sale Item A | 0.99   |
    | 088888888880 | Sale Item B | 1.99   |
    | 066666666660 | Sale Item D | 1.99   |


    @fast
    Scenario: Zero balance transaction, Yes/No frame is displayed on finalization.
        Given the POS is in a ready to sell state
        And an empty transaction is in progress
        When the cashier presses the cash tender button
        Then the POS displays No balance due frame

    @fast
    Scenario: Zero balance transaction, "Yes" on finalization prompt.
        Given the POS is in a ready to sell state
        And an empty transaction is in progress
        And the POS displays No balance due frame
        When the cashier presses Yes button on finalize zero balance transaction prompt
        Then the transaction is finalized

    @fast
    Scenario: Zero balance transaction, "No" on finalization prompt.
        Given the POS is in a ready to sell state
        And an empty transaction is in progress
        And the POS displays No balance due frame
        When the cashier presses No button on finalize zero balance transaction prompt
        Then a transaction is in progress

    @fast @positive
    Scenario Outline: Press any tender type and verify the displayed frame.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the cashier presses the <tender_type> tender button
        Then the POS displays Ask tender amount <tender_type> frame

        Examples:
        | tender_type   |
        | Cash          |
        | Credit        |
        | Debit         |
        | Check         |

    @positive @fast
    Scenario Outline: Press go-back button in tender amount frame.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the POS displays Ask tender amount <tender_type> frame
        When the cashier presses Go back button
        Then a transaction is in progress
        And an item Sale Item A with price 0.99 is in the virtual receipt
        And an item Sale Item A with price 0.99 is in the current transaction

        Examples:
        | tender_type   |
        | Cash          |
        | Credit        |
        | Debit         |
        | Check         |

    @positive @fast
    Scenario Outline: Enter 0 amount in tender amount frame, an error is displayed.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the POS displays Ask tender amount <tender_type> frame
        When the cashier enters 0.00 dollar amount in Ask tender amount <tender_type> frame
        Then the POS displays No amount entered error

        Examples:
        | tender_type   |
        | Cash          |
        | Credit        |
        | Debit         |
        | Check         |


    @positive @fast
    Scenario Outline: Pay through hotkeys in cash tender.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction 4 times
        When the cashier tenders the transaction with hotkey <fast_button> in cash
        Then no transaction is in progress
        And a tender Cash with amount <amount> is in the previous transaction

        Examples:
        | fast_button  | amount |
        | exact_dollar | 4.24   |
        | next_dollar  | 5.00   |
        | 5            | 5.00   |
        | 10           | 10.00  |
        | 20           | 20.00  |


    @positive @fast
    Scenario Outline: Tender more than the transaction total using cash.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction <count> times
        When the cashier tenders the transaction with amount <amount> in cash
        Then no transaction is in progress
        And a tender Cash with amount <amount> is in the previous transaction

        Examples:
        | barcode       | count | amount |
        | 099999999990  | 4     | 5.25   |


    @positive @fast
    Scenario: Partially tender the transaction with cash.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction 4 times
        When the cashier tenders the transaction with amount 1.50 in cash
        Then a transaction is in progress
        And an item Sale Item A with price 3.96 and quantity 4 is in the virtual receipt
        And an item Sale Item A with price 3.96 and quantity 4 is in the current transaction
        And a tender Cash with amount 1.50 is in the virtual receipt
        And a tender Cash with amount 1.50 is in the current transaction
        And the transaction's balance is 2.74


    @positive @fast
    Scenario: Tender the transaction with credit using an exact dollar hotkey.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction 4 times
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then the transaction is finalized
        And a tender Credit with amount 4.24 is in the previous transaction


    @positive @fast
    Scenario: Tender the transaction with credit using the keyboard to enter an exact dollar amount.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction 4 times
        When the cashier tenders the transaction with amount 4.24 in credit
        Then the transaction is finalized
        And a tender Credit with amount 4.24 is in the previous transaction


    @positive @fast
    Scenario Outline: Attempt to tender more than the transaction total using credit, an error is displayed.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction <count> times
        When the cashier tenders the transaction with amount <amount> in credit
        Then the POS displays Amount too large error

        Examples:
        | barcode       | count | amount |
        | 099999999990  | 4     | 15.00  |


    @positive @fast
    Scenario: Partially tender the transaction with credit.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction 4 times
        When the cashier tenders the transaction with amount 1.25 in credit
        Then the POS displays Credit processing followed by main menu frame
        And a transaction is in progress
        And an item Sale Item A with price 3.96 and quantity 4 is in the virtual receipt
        And an item Sale Item A with price 3.96 and quantity 4 is in the current transaction
        And a tender Credit with amount 1.25 is in the virtual receipt
        And a tender Credit with amount 1.25 is in the current transaction
        And the transaction's balance is 2.99


    @positive @fast
    Scenario: Tender the transaction with debit using an exact dollar hotkey.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction 4 times
        When the cashier starts tender the transaction with hotkey Exact Dollar in Debit
        Then the POS displays Credit processing followed by main menu frame
        And no transaction is in progress
        And a tender Credit with amount 4.24 is in the previous transaction


    @positive @fast
    Scenario Outline: Tender the transaction with debit using the keyboard to enter an exact dollar amount.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction <count> times
        When the cashier tenders the transaction with amount <amount> in debit
        Then the POS displays Credit processing followed by main menu frame
        And no transaction is in progress
        And a tender Credit with amount <amount> is in the previous transaction

        Examples:
        | barcode       | count | amount |
        | 099999999990  | 4     | 4.24   |


    @positive @fast
    Scenario Outline: Attempt to tender more than the transaction total using debit, an error is displayed.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction <count> times
        When the cashier tenders the transaction with amount <amount> in debit
        Then the POS displays Amount too large error

        Examples:
        | barcode       | count | amount |
        | 099999999990  | 4     | 6.00   |


    @positive @fast
    Scenario: Partially tender the transaction with debit.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction 4 times
        When the cashier tenders the transaction with amount 1.50 in debit
        Then the POS displays Credit processing followed by main menu frame
        And a transaction is in progress
        And an item Sale Item A with price 3.96 and quantity 4 is in the virtual receipt
        And an item Sale Item A with price 3.96 and quantity 4 is in the current transaction
        And a tender Credit with amount 1.50 is in the virtual receipt
        And a tender Credit with amount 1.50 is in the current transaction
        And the transaction's balance is 2.74


    @positive @fast
    Scenario: Tender the transaction with check using an exact dollar hotkey.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction 4 times
        When the cashier tenders the transaction with hotkey exact_dollar in check
        Then no transaction is in progress
        And a tender Check with amount 4.24 is in the previous transaction


    @positive @fast
    Scenario: Overpay with check the total of the transaction.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction 4 times
        When the cashier tenders the transaction with amount 15.00 in check
        Then no transaction is in progress
        And a tender Check with amount 15.00 is in the previous transaction


    @positive @fast
    Scenario: Partially tender the transaction with check.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction 4 times
        When the cashier tenders the transaction with amount 1.50 in check
        Then a transaction is in progress
        And an item Sale Item A with price 3.96 and quantity 4 is in the virtual receipt
        And an item Sale Item A with price 3.96 and quantity 4 is in the current transaction
        And a tender Check with amount 1.50 is in the virtual receipt
        And a tender Check with amount 1.50 is in the current transaction
        And the transaction's balance is 2.74


    @positive @fast
    Scenario: Tender the transaction with credit, the host declines the card.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the EPS simulator uses Decline card configuration
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then the POS displays Card declined frame
        And a transaction is in progress


    @positive @fast
    Scenario: Tender the transaction with credit, the host partially approves the transaction.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the EPS simulator uses PartialApproval card configuration
        When the cashier tenders the transaction with hotkey exact_dollar in credit
        Then the POS displays Partial approval frame
        And a transaction is in progress


    @positive @fast
    Scenario: Tender the transaction with credit, the host partially approves the transaction and the cashier accepts it, the partial payment is in the transaction.
        Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        And the EPS simulator uses PartialApproval card configuration
        And the POS displays Partial approval frame
        When the cashier presses Yes on Partial approval frame
        Then the POS displays Credit processing followed by main menu frame
        And a transaction is in progress
        And a tender Credit with amount 0.53 is in the virtual receipt
        And a tender Credit with amount 0.53 is in the current transaction
        And the transaction's balance is 0.53


    @positive @fast
    Scenario Outline: Tender the transaction including tax with MFC using quick buttons.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And the POS displays Amount selection frame after selecting <tender> tender with external id <external_id> and type id 21
        When the cashier tenders the transaction with <quick_button> on the current frame
        Then no transaction is in progress
        And a tender <tender> with amount <amount> is in the previous transaction

        Examples:
        | barcode       | amount | tender      | quick_button | external_id  |
        | 066666666660  | 2.56   | MFC_tender  | exact-dollar | 777          |


    @positive @fast
    Scenario Outline: Tender the transaction including tax with MFC using manual entry.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        When the cashier tenders the transaction with <amount> in <tender> with external id <external_id> and type id 21
        Then no transaction is in progress
        And a tender <tender> with amount <amount> is in the previous transaction

        Examples:
        | barcode       | amount | tender      | external_id  |
        | 066666666660  | 2.56   | MFC_tender  | 777          |


    @positive @fast
    Scenario Outline: Attempting to tender more than the transaction total using MFC tender - quick buttons leads to Amount will be restricted prompt.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And the POS displays Amount selection frame after selecting <tender> tender with external id <external_id> and type id 21
        When the cashier tenders the transaction with <quick_button> on the current frame
        Then the POS displays Amount will be restricted prompt

        Examples:
        | barcode       | quick_button | tender     | external_id  |
        | 066666666660  | preset-20    | MFC_tender | 777          |
        | 099999999990  | next-dollar  | MFC_tender | 777          |


    @positive @fast
    Scenario Outline: Attempting to tender more than the transaction total using MFC tender - manual entry leads to Amount will be restricted prompt.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        When the cashier tenders the transaction with <amount> in <tender> with external id <external_id> and type id 21
        Then the POS displays Amount will be restricted prompt

        Examples:
        | barcode       | amount | tender      | external_id  |
        | 066666666660  | 15.00  | MFC_tender  | 777          |


    @positive @fast @manual @waitingforfix
    Scenario Outline: Accepting amount restriction after trying to tender more than transaction total finalizes the transaction.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And the POS displays Amount will be restricted prompt after attempting to tender <amount> in <tender> with external id <external_id> and type id 21
        When the cashier selects Yes button
        Then no transaction is in progress
        And a tender <tender> with amount <tendered_amount> is in the previous transaction

        Examples:
        | barcode       | amount | tender      | external_id | tendered_amount |
        | 066666666660  | 15.00  | MFC_tender  | 777         | 2.56            |


    @positive @fast
    Scenario Outline: Declining amount restriction after trying to tender more than transaction total goes back to the amount selection frame.
        Given the POS is in a ready to sell state
        And an item with barcode <barcode> is present in the transaction
        And the POS displays Amount will be restricted prompt after attempting to tender <amount> in <tender> with external id <external_id> and type id 21
        When the cashier selects No button
        Then the POS displays Ask tender amount <tender_type> frame

        Examples:
        | barcode       | amount | tender      | external_id | tender_type |
        | 066666666660  | 15.00  | MFC_tender  | 777         | type-21     |


	@positive @fast
	Scenario Outline: Changing max tenders value and attempt transaction with more tenders that allowed
		Given the POS option 1215 is set to <new_value>
		# Max methods of payment allowed is set to <new_value>
		And the POS is in a ready to sell state
		And an item with barcode <barcode_1> is present in the transaction <count_1> times
        And an item with barcode <barcode_2> is present in the transaction <count_2> times
        When the cashier tenders the transaction <tender_times> times with amount <amount> in cash
        Then the POS displays Partial tender not allowed error

		Examples:
        | barcode_1       | barcode_2     | count_1 | count_2 | amount    | tender_times | new_value |
        | 099999999990    | 088888888880  | 6       | 4       | 5.00      | 2            | 2         |
        | 099999999990    | 088888888880  | 3       | 5       | 3.00      | 3            | 3         |


	@positive @fast @smoke
    Scenario Outline: Tender the transaction with two tenders
        Given the POS is in a ready to sell state
		And an item with barcode 099999999990 is present in the transaction 3 times
        And an item with barcode 088888888880 is present in the transaction 2 times
		And a <amount_1> <tender_type_1> partial tender is present in the transaction
		When the cashier tenders the transaction with hotkey <fast_button> in <tender_type_2>
        Then the transaction is finalized

		Examples:
        |tender_type_1 | tender_type_2    | fast_button  | amount_1 |
        | cash         | cash             | 20           | 5.00     |
        | cash         | check            | exact_dollar | 4.00     |
        | cash         | credit           | exact_dollar | 4.55     |
        | check        | credit           | exact_dollar | 5.00     |
		| cash         | gift certificate | exact_dollar | 4.75     |
        | cash         | manual imprint   | exact_dollar | 5.11     |
        | check        | gift certificate | exact_dollar | 4.00     |
        | check        | manual imprint   | exact_dollar | 4.55     |


	@positive @fast
	Scenario Outline: Tender the transaction partially with food stamps and another tender
        Given the POS option 1215 is set to 3
		# Max methods of payment allowed is set to 3
		And the POS is in a ready to sell state
		And an item with barcode <barcode> is present in the transaction
		And a <amount> food stamps partial tender is present in the transaction
		When the cashier tenders the transaction with hotkey <fast_button> in <tender_type>
		Then the transaction is finalized

		Examples:
        | barcode      | tender_type      | fast_button  | amount |
        | 099999999990 | cash             | exact_dollar | 0.40   |
        | 099999999990 | gift certificate | exact_dollar | 0.40   |
        | 099999999990 | check            | exact_dollar | 0.40   |


    @positive @fast
	Scenario Outline: Attempt to tender the transaction partially with food stamps, when one tender is already in the transaction, the button for food stamps is disabled
        Given the POS is in a ready to sell state
		And an item with barcode <barcode> is present in the transaction
		And a <amount> <tender_type> partial tender is present in the transaction
		When the cashier navigates to the food stamps tender button
		Then the food stamps tender button is disabled

		Examples:
        | barcode      | tender_type      | amount |
        | 099999999990 | cash             | 0.40   |
        | 099999999990 | gift certificate | 0.40   |
        | 099999999990 | check            | 0.40   |


    @positive @fast
	Scenario Outline: Void tenders after partial tender
        Given the POS option 1215 is set to 3
		# Max methods of payment allowed is set to 3
		And the POS is in a ready to sell state
		And an item with barcode 099999999990 is present in the transaction 2 times
		And a <amount_1> <tender_type_1> partial tender is present in the transaction
		And a <amount_2> <tender_type_2> partial tender is present in the transaction
		And the cashier pressed Void item button 2 times
		When the cashier tenders the transaction with hotkey <fast_button> in <tender_type_2>
		Then the transaction is finalized

		Examples:
        | tender_type_1 | tender_type_2    | fast_button  | amount_1 | amount_2 |
        | cash          | check            | exact_dollar | 0.30     | 0.40     |


	@positive @fast
	Scenario: Attempt to tender a non-fuel item with Drive off, an error is displayed
		Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
		And the POS displays Other functions frame
		When the cashier presses Drive Off button
		Then the POS displays Tender not allowed on non-fuel items error


	@positive @fast
	Scenario: Press Pump Test button on non-fuel item, an error is displayed
		Given the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
		And the POS displays Other functions frame
		When the cashier presses Pump Test button
		Then the POS displays Tender not allowed on non-fuel items error


	@positive @fast
	Scenario: Press Drive Off button on PrePay transaction, an error is displayed
		Given the POS is in a ready to sell state
        And a prepay with price 6.00 on the pump 1 is present in the transaction
		And a 5.00 cash partial tender is present in the transaction
		And the POS displays Other functions frame
		When the cashier presses Drive off button
		Then the POS displays Prepay drive off not allowed error


	@positive @fast
	Scenario: Press Pump Test button in a partially tendered transaction, an error is displayed
		Given the POS is in a ready to sell state
        And a prepay with price 6.00 on the pump 1 is present in the transaction
		And a 5.00 cash partial tender is present in the transaction
		And the POS displays Other functions frame
		When the cashier presses Pump Test button
		Then the POS displays Partial tender not allowed for pump test


	@positive @fast
    Scenario Outline: Tender the transaction with three tender types
        Given the POS option 1215 is set to 3
		# Max methods of payment allowed is set to 3
		And the POS is in a ready to sell state
		And an item with barcode 099999999990 is present in the transaction 6 times
        And an item with barcode 088888888880 is present in the transaction 4 times
		And a <amount_1> <tender_type_1> partial tender is present in the transaction
		And a <amount_2> <tender_type_2> partial tender is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in <tender_type_3>
        Then the transaction is finalized

		Examples:
        | amount_1 | amount_2 | tender_type_1 | tender_type_2 | tender_type_3 |
        | 4.55     | 5.00     | cash          | check         | cash          |
        | 4.00     | 5.00     | food stamps   | check         | cash          |