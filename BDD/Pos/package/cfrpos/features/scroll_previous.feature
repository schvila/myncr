@pos @scroll_previous
Feature: Scroll previous
This feature tests operations on Scroll previous frame

Background: The POS needs to have some items configured to manipulate with them.
    Given the POS has essential configuration
    And the pricebook contains reason codes for transaction refund
        | refund_reason              |
        | Refund Tran Reason         |
        | RS 21 - Refund Transaction |

   @fast
    Scenario: Press Scroll previous button, the Scroll previous frame is displayed
        Given the POS is in a ready to sell state
        And a dummy transaction was finalized on POS
        And the POS displays Other functions frame
        When the cashier presses Scroll previous button
        Then the POS displays Scroll previous frame


    @fast
    Scenario: Press Done button on the Scroll previous frame, main menu frame is displayed
        Given the POS is in a ready to sell state
        And a dummy transaction was finalized on POS
        And the POS displays Scroll previous frame
        When the cashier presses Done button
        Then the POS displays main menu frame


    @fast
    Scenario: Press Go back button when choosing a reason to refund previous non-fuel transaction, Scroll previous frame is displayed
        Given the POS is in a ready to sell state
        And a dummy transaction was finalized on POS
        And the POS displays Scroll previous frame
        And the cashier pressed Refund Fuel button
        And the POS displays Please select a reason frame
        When the cashier presses Go back button
        Then the POS displays Scroll previous frame


    @fast
    Scenario: Select the line on the Scroll previous list, verify the selected line contains given element
        Given the POS is in a ready to sell state
        And a dummy transaction was finalized on POS
        And the POS displays Scroll previous frame
        When the cashier selects last transaction on the Scroll previous list
        Then the selected line in Scroll previous contains a <element>
            | element                     |
            | transaction sequence number |
            | node type                   |
            | node number                 |
            | transaction time            |
            | transaction total           |


    @manual
    Scenario: Select a line with some transaction number on the Scroll previous list,
                      verify the elements in the selected line have correct values
        Given the POS is in a ready to sell state
        And 3 dummy transactions were finalized on POS
        And the POS displays Scroll previous frame
        When the cashier selects transaction with number 2 on the Scroll previous list
        Then the selected line in Scroll previous contains following elements
            | element                     | value |
            | transaction sequence number | 2     |
            | node type                   | POS   |
            | node number                 | 1     |


    @fast
    Scenario: Customer performs PAP transaction, verify the transaction is in the Scroll previous list, and has elements with correct values
        Given the POS is in a ready to sell state
        And the customer performed PAP transaction on pump 2 for amount 20.00
        And the POS displays Scroll previous frame
        When the cashier selects last transaction on the Scroll previous list
        Then the selected line in Scroll previous contains following elements
            | element           | value       |
            | node type         | Pump        |
            | node number       | 2           |
            | transaction type  | Pay at Pump |


    @fast
    Scenario: The transaction performed on another node appears in the Scroll previous list of current node.
        Given the POS is in a ready to sell state
        And a transaction with Sale Item A was tendered by cash on POS 2
        And the POS displays Scroll previous frame
        When the cashier selects last transaction on the Scroll previous list
        Then the selected line in Scroll previous contains following elements
            | element           | value       |
            | node type         | POS         |
            | node number       | 2           |


    @fast @print_receipt
    Scenario: Reprint transaction created on another POS node.
        Given the POS is in a ready to sell state
        And a transaction with Sale Item A was tendered by cash on POS 2
        And the cashier selected last transaction on the Scroll previous list
        When the cashier prints the selected transaction in Scroll previous list
        Then the receipt contains following lines
        | line                                                                                                                                                                                                               |
        | <span class="width-9 left">Register:</span><span class="left"> </span><span class="width-7 left">2</span><span class="width-13 left">Tran Seq No:</span><span class="width-10 right">3</span>                      |
        | <span class="width-1 left">I</span><span class="width-4 left">1</span><span class="left"> </span><span class="width-24 left">Sale Item A</span><span class="left"> </span><span class="width-9 right">$0.99</span> |
        | <span class="width-30 left">Cash</span><span class="width-10 right">$1.06</span>                                                                                                                                   |


    @fast @pes
    Scenario: The transaction performed on another node and tendered with loyalty points appears in the Scroll previous list of current node.
        Given the POS is in a ready to sell state
        And a transaction with Sale Item A was tendered by loyalty points on POS 2
        And the POS displays Scroll previous frame
        When the cashier selects last transaction on the Scroll previous list
        Then the selected line in Scroll previous contains following elements
            | element           | value       |
            | node type         | POS         |
            | node number       | 2           |


    @fast
    Scenario: Press Refund Fuel button after selecting last transaction in Scroll previous list, the POS displays Select a reason frame.
        Given the POS is in a ready to sell state
        And a dummy transaction was finalized on POS
        And the cashier selected last transaction on the Scroll previous list
        When the cashier selects Refund Fuel button on the Scroll previous frame
        Then the POS displays Please select a reason frame


    @manual
    # Missing metadata for This will cancel the transaction prompt, will be solved under RPOS-26206
    Scenario: Attempt to refund fuel from previous non-fuel transaction, refund not allowed error is displayed
        Given the POS is in a ready to sell state
        And a dummy transaction was finalized on POS
        And the POS displays Scroll previous frame
        And the cashier selected a reason to refund fuel from last transaction
        And the POS displays This will cancel the transaction prompt
        When the cashier selects Yes button
        Then the POS displays Refund not allowed error


    @manual
    # Missing metadata for This will cancel the transaction prompt, will be solved under RPOS-26206
    Scenario: Attempt to refund fuel from previous fuel transaction, Scroll previous frame is displayed
        Given the POS is in a ready to sell state
        And a Regular postpay fuel with 10.00 price on pump 2 is present in the transaction
        And the transaction is tendered
        And the POS displays Scroll previous frame
        And the cashier selected a reason to refund fuel from last transaction
        And the POS displays This will cancel the transaction prompt
        When the cashier selects Yes button
        Then the POS displays Scroll previous frame
        And the refunded amount 10 is present on pump 1


    @fast
    Scenario: Perform a transaction, validate that the transaction is present in scroll previous list after starting a new shift.
        Given the POS is in a ready to sell state
        And a dummy transaction was finalized on POS
        And the POS is in a ready to start shift state
        And the manager started a shift with PIN 2345
        And the POS displays Other functions frame
        When the cashier presses Scroll previous button
        Then the POS displays Scroll previous frame
        And the Scroll previous list contains the last performed transaction