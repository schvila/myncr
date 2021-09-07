@pos @requires_sc @requires_sigma @requires_epsilon

Feature: Any Customer
    Any customer feature allows a store customer to receive discounts from loyalty host
    even if they provide no loyalty ID to the transaction.

Background: cashier should be signed in so he can make transactions.
    Given the POS is in a ready to sell state
    And POS option xxxxx is set to xxx
    And the loyalty host awards any customer with Item Level Flat Amount ($) discount of value 0.50 to Sale Item A item

@fast @manual
Scenario Outline: The auth request is sent after the cashier totals the operation.
    Given the transaction contains Sale Item A item
    When the cashier totals the transaction
    Then the POS sends auth request to loyalty host

@fast @manual
Scenario Outline: The discount is added to VR once the auth response is received.
    Given the transaction contains <item_name> item
    And the loyalty host awards any customer with <discount_type> discount of value <discount_amount> to <item_name> item
    And the transaction was totaled
    When the POS receives auth response from loyalty host
    Then the loyalty discount <discount_type> is added to VR with <discount_amount> amount

    Examples:
        | item_name     | discount_type                 | discount_amount  | note                                 |
        | Sale Item A   | Item Level Flat Amount ($)    | 0.50             |                                      |
        | Sale Item B   | Item Level Flat Percentage ($)| 0.20             | amount calculated from 20% discount  |

@fast @manual
Scenario Outline: The discount Buy one Get one Free discounts the item.
    Given the transaction contains 2 Sale Item D items
    And the loyalty host awards any customer with Buy one Get one Free to 2 Sale Item D items
    And the transaction was totaled
    When the POS receives auth response from loyalty host
    Then the whole amount of one Sale Item D item was discounted by loyalty discount

@fast @manual
Scenario Outline: The capture request is sent after the cashier tenders the operation.
    Given the transaction contains Sale Item A item
    And the transaction was totaled
    When the cashier tenders the transaction
    Then the POS sends capture request to loyalty host

@fast @manual
Scenario Outline: The transaction is finalized after the POS receives an approved capture response from loyalty host.
    Given the transaction contains Sale Item A item
    And the transaction was totaled
    And the loyalty host approves any customer capture requests
    And the transaction was tendered
    When the POS receives capture response from loyalty host
    Then the transaction is finalized
    And Any customer loyalty is printed on the receipt with $0.50 amount
    And the loyalty discount Item Level Flat Amount ($) with value of 0.50 is in the current transaction

@fast @manual
Scenario Outline: Voiding item will remove the discount from the transaction.
    Given the transaction contains Sale Item A item
    And the transaction was totaled
    And the transaction contains Item Level Flat Amount ($) loyalty discount with 0.50 amount
    When the cashier voids the discounted Sale Item A item
    Then the loyalty discount Item Level Flat Amount ($) is removed from the transaction
    And the item Sale Item A is removed from the transaction

@fast @manual
Scenario Outline: Voiding the transaction will send auth cancel.
    Given the transaction contains Sale Item A item
    And the transaction was totaled
    When the cashier voids the transaction
    Then the POS sends auth cancel request to loyalty host
    And the transaction is voided

@fast @manual
Scenario Outline: After refunding the transaction, no request to loyalty host is sent.
    Given the transaction contains Sale Item A item
    And the transaction is in refund state
    When the cashier tenders the transaction
    Then the transaction is finalized
    And the POS does not send an auth request
    And the POS does not send an capture request
    And the POS does not send an auth cancel request

@fast @manual
Scenario Outline: No discount is added into the transaction, if the POS is not connected to POS net.
    Given the transaction contains Sale Item A item
    And the POS is disconnected from POS net
    When the cashier totals the transaction
    Then the POS displays POS net offline message
    And no loyalty discount is added into the transaction

@fast @manual
Scenario Outline: If auth request was declined, no discount is added to the transaction.
    Given the transaction contains Sale Item A item
    And the loyalty host declines every auth request from any customer
    And the transaction was totaled
    When the POS receives declined auth response from loyalty host
    Then the POS displays Loyalty unavailable message
    And no loyalty discount is added into the transaction

@fast @manual
Scenario Outline: Capture request was declined.
    Given the transaction contains Sale Item A item
    And the transaction was totaled
    And the loyalty host declines every capture request from any customer
    And the transaction was tendered
    When the POS receives declined capture response from loyalty host
    Then the transaction is finalized

@slow @manual
Scenario Outline: The POS does not receive the response from loyalty host and timeouts.
    Given the transaction contains Sale Item A item
    And the transaction was totaled
    When the POS does not receive response from loyalty host
    Then the POS displays Loyalty unavailable message after a timeout
