@pos @requires_sc @requires_sigma @requires_epsilon

Feature: Single use coupon
    Cashier must be able to use single coupons according to configuration.
    This feature should cover the entire flow of transactions with single use coupons.
    The unauthorized coupons have 0 value and authorized have some other value greater than 0.

Background: cashier should be signed-in, so he can add single use coupons to the order.
    Given the POS is in a ready to sell state
    And POS option xxxxx is set to xxx
    And the loyalty host has configured Item Level Flat Amount ($) coupon with 0.50 value to Sale Item A item

@fast @manual
Scenario Outline: Adding a coupon to the transaction.
    When the cashier adds <input_method> coupon <coupon_type>
    Then a new transaction is started
    And the coupon <coupon_type> is added to VR with 0 value

    Examples:
        | input_method  | coupon_type                   |
        | Manually      | Item Level Flat Amount ($)    |
        | Scanned       | Item Level Flat Percentage ($)|
        | Swiped        | Buy one Get one Free          |

@fast @manual
Scenario Outline: The auth request to loyalty host is sent after the cashier totals the transaction.
    Given the transaction contains Sale Item A item
    And the transaction contains Item Level Flat Amount ($) coupon with 0 value
    When the cashier totals the transaction
    Then the POS sends auth request to loyalty host

@fast @manual
Scenario Outline: The items are discounted by the coupons and matched with correct items after the cashier totals the transaction.
    Given the transaction contains <item_name> item
    And the transaction contains <coupon_type> coupon with 0 value
    And the loyalty host has configured <coupon_type> coupon with <coupon_value> value to <item_name> item
    And the transaction was totaled
    When the POS receives auth response from loyalty host
    Then the coupon <coupon_type> is assigned to the <item_name> item
    And the coupon <coupon_type> changes value to <coupon_value>

    Examples:
        | item_name     | coupon_type                   | coupon_value      | note                                |
        | Sale Item A   | Item Level Flat Amount ($)    | 0.50              |                                     |
        | Sale Item B   | Item Level Flat Percentage ($)| 0.20              | value calculated from 20% discount  |

@fast @manual 
Scenario Outline: The one item is discounted after Buy one Get one Free coupon is assigned.
    Given the transaction contains 2 Sale Item D items
    And the transaction contains Buy one Get one Free coupon with 0 value
    And the loyalty host has configured Buy one Get one Free coupon to 2 Sale Item D items
    And the transaction was totaled
    When the POS receives auth response from loyalty host
    Then the coupon Buy one Get one Free is assigned to the Sale Item D item
    Then the whole amount of one Sale Item D item was discounted by coupon

@fast @manual
Scenario Outline: The POS sends capture request after the cashier tenders the transaction.
    Given the transaction contains Sale Item A item
    And the transaction contains Item Level Flat Amount ($) coupon with 0 value
    And the transaction was totaled
    When the cashier tenders the transaction
    Then the POS sends capture request to loyalty host

@fast @manual
Scenario Outline: The transaction is finalized after the POS receives the capture response from loyalty host.
    Given the transaction contains Sale Item A item
    And the transaction contains Item Level Flat Amount ($) coupon with 0 value
    And the transaction was totaled
    And the loyalty host approves Single use coupons capture requests
    And the transaction was tendered
    When the POS receives capture response from loyalty host
    Then the transaction is finalized
    And the coupon Item Level Flat Amount ($) with amount 0.50 is in the current transaction

@fast @manual
Scenario Outline: Adding Unsupported/expired coupon to the transaction will display Unsupported/expired message.
    When the cashier adds <input_method> coupon <coupon_type>
    Then the POS displays Unsupported/expired coupon message
    And the coupon <coupon_type> is not added to the transaction

    Examples:
        | input_method | coupon_type    |
        | Manually     | expired        |
        | Scanned      | unsupported    |
        | Swiped       | invalid        |

@fast @manual
Scenario Outline: cashier is warned about unmatched coupons after getting the response from auth request.
    Given the transaction contains 2 Item Level Flat Amount ($) coupons with 0 value
    And the transaction was totaled
    When the POS receives auth response from loyalty host
    Then the POS displays Unmatched coupons message

@fast @manual
Scenario Outline: Unmatched coupons are removed from the transaction after cashier acknowledges it.
    Given the transaction contains 2 Item Level Flat Amount ($) coupons with 0 value
    And the transaction was totaled
    And the POS displays Unmatched coupons message
    When the cashier presses Ok button
    Then the 2 coupons Item Level Flat Amount ($) are removed from the transaction

@fast @manual
Scenario Outline: cashier voids the unauthorized coupon.
    Given the transaction contains Item Level Flat Amount ($) coupon with 0 value
    When the cashier voids the Item Level Flat Amount ($) coupon
    Then the coupon Item Level Flat Amount ($) is removed from the transaction

@fast @manual
Scenario Outline: cashier voids the authorized coupon from loyalty host.
    Given the transaction contains Sale Item A item
    And the transaction contains Item Level Flat Amount ($) coupon with 0 value
    And the transaction was totaled
    When the cashier voids the Item Level Flat Amount ($) coupon with 0.50 value
    Then the coupon Item Level Flat Amount ($) is removed from the transaction
    And the coupon Item Level Flat Amount ($) is still reusable

@fast @manual
Scenario Outline: Prompt is displayed when cashier tries to add a coupon to the transaction when the feature is disabled.
    Given POS option xxxxx is set to xxx
    When the cashier adds <input_method> coupon <coupon_type>
    Then the POS displays Single use coupon Functionality disabled message

    Examples:
        | input_method  | coupon_type                   |
        | Manually      | Item Level Flat Amount ($)    |
        | Scanned       | Item Level Flat Percentage ($)|
        | Swiped        | Buy one Get one Free          |

@fast @manual
Scenario Outline: The coupons are not added to the transaction, when the Single use coupon functionality is disabled.
    Given POS option xxxxx is set to xxx
    And the POS displays Single use coupon Functionality disabled message
    When the cashier presses Ok button
    Then the coupon <coupon_type> is not added to the transaction

    Examples:
        | coupon_type                   |
        | Item Level Flat Amount ($)    |
        | Item Level Flat Percentage ($)|
        | Buy one Get one Free          |

@fast @manual
Scenario Outline: If the POS is not connected to POS net, a message will be displayed.
    Given the transaction contains Sale Item A item
    And the transaction contains Item Level Flat Amount ($) coupon with 0 value
    And the transaction contains Item Level Flat Percentage ($) coupon with 0 value
    And the POS is disconnected from POS net
    When the cashier totals the transaction
    Then the POS displays POS net offline message

@fast @manual
Scenario Outline: If the coupons are not sent to host with auth, they are removed from transaction.
    Given the transaction contains Sale Item A item
    And the transaction contains Item Level Flat Amount ($) coupon with 0 value
    And the transaction contains Item Level Flat Percentage ($) coupon with 0 value
    And the POS is disconnected from POS net
    And the transaction was totaled
    And the POS displays POS net offline message
    When the cashier presses Ok button
    Then the POS displays Coupons are unused message

@fast @manual
Scenario Outline: The POS displays information about coupons not used.
    Given the transaction contains Sale Item A item
    And the transaction contains Item Level Flat Amount ($) coupon with 0 value
    And the transaction contains Item Level Flat Percentage ($) coupon with 0 value
    And the POS is disconnected from POS net
    And the transaction was totaled
    And the POS displays Coupons are unused message
    When the cashier presses Ok button
    Then the coupon Item Level Flat Amount ($) is removed from the transaction
    And the coupon Item Level Flat Percentage ($) is removed from the transaction

@fast @manual
Scenario Outline: Single use coupon discount and autocombo discount can be in one transaction.
    Given the transaction contains 2 Sale Item C items
    And the transaction contains 2Cs for $2.49 Combo autocombo with $0.49 discount
    And the transaction contains Sale Item A item
    And the transaction contains Item Level Flat Amount ($) coupon with 0 value
    And the transaction was totaled
    When the POS receives auth response from loyalty host
    Then the coupon Item Level Flat Amount ($) is assigned to the Sale Item A item
    And the coupon Item Level Flat Amount ($) changes value to 0.50

@fast @manual
Scenario Outline: Auth request was declined and coupon is removed from the transaction.
    Given the transaction contains Sale Item A item
    And the transaction contains Item Level Flat Amount ($) coupon with 0 value
    And the loyalty host declines every auth request from single use coupon
    And the transaction was totaled
    When the POS receives declined auth response from loyalty host
    Then the POS displays xxx message
    And the coupon Item Level Flat Amount ($) is removed from the transaction

@fast @manual
Scenario Outline: Capture request was declined.
    Given the transaction contains Sale Item A item
    And the transaction contains Item Level Flat Amount ($) coupon with 0 value
    And the transaction was totaled
    And the loyalty host declines every capture request from single use coupon
    And the transaction was tendered
    When the POS receives declined capture response from loyalty host
    Then the transaction is finalized

@slow @manual
Scenario Outline: The POS does not receive the response from loyalty host and timeouts.
    Given the transaction contains Sale Item A item
    And the transaction contains Item Level Flat Amount ($) coupon with 0 value
    And the transaction was totaled
    When the POS does not receive response from loyalty host
    Then the POS displays Loyalty unavailable message after a timeout
