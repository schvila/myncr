@pos @requires_sc @requires_sigma @requires_epsilon

Feature: Suspend and Resume
    Suspend and resume allows to the customer to leave his transaction for later.

@fast @manual
Scenario Outline: The cashier can not store, when no transaction is active.
    When the cashier stores the transaction
    Then the POS displays No tran in progress message

@fast @manual
Scenario Outline: The cashier can not store an empty transaction.
    Given a new transaction was started
    When the cashier stores the transaction
    Then the POS displays Store tran not allowed message

@fast @manual
Scenario Outline: The cashier stores the transaction after total with any customer discount in it.
    Given the loyalty host awards any customer with Item Level Flat Amount ($) discount of value 0.50 to Sale Item A item
    And the transaction contains Sale Item A item
    And the transaction was totaled
    And the transaction contains Item Level Flat Amount ($) loyalty discount with 0.50 amount
    When the cashier stores the transaction
    Then the POS sends auth cancel request to loyalty host

@fast @manual
Scenario Outline: The cashier recalls the transaction with any customer discount.
    Given the loyalty host awards any customer with Item Level Flat Amount ($) discount of value 0.50 to Sale Item A item
    And the transaction contains Sale Item A item
    And the transaction was totaled
    And the transaction contains Item Level Flat Amount ($) loyalty discount with 0.50 amount
    And the cashier stored the transaction
    When the cashier recalls the transaction
    Then the transaction contains Sale Item A item

@fast @manual
Scenario Outline: The cashier stores the transaction after total with single use coupon in it.
    Given the loyalty host has configured Item Level Flat Amount ($) coupon with 0.50 value to Sale Item A item
    And the transaction contains Sale Item A item
    And the transaction contains Item Level Flat Amount ($) coupon with 0 value
    And the transaction was totaled
    When the cashier stores the transaction
    Then the POS sends auth cancel request to loyalty host

@fast @manual
Scenario Outline: The cashier recalls the transaction with single use coupon.
    Given the loyalty host has configured Item Level Flat Amount ($) coupon with 0.50 value to Sale Item A item
    And the transaction contains Sale Item A item
    And the transaction contains Item Level Flat Amount ($) coupon with 0 value
    And the transaction was totaled
    And the cashier stored the transaction
    When the cashier recalls the transaction
    Then the transaction contains Sale Item A item
