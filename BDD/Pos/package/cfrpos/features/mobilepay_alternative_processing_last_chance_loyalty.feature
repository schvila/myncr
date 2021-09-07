@pos @manual
Feature: MobilePay functionality, Loyalty alternative processing, last chance loyalty
    POS Option 4219 changes handling of loyalty card sent from EPS. If set to 1, any previously entered loyalty cards should be removed if mobile tender is linked with loyalty ID.
    Last chance loyalty prompt should not be displayed, if Mobile Tender used at the time of payment is linked with loyalty ID.

Background:
    Given the POS has essential configuration
    And the EPS simulator has essential configuration
    And the Sigma simulator has essential configuration
    And the POS has the feature Loyalty enabled
    # MobilePay feature is enabled
    And the POS option 1240 is set to 1
    # Fuel credit prepay method is set to Auth and Capture
    And the POS option 1851 is set to 1
    # "Max methods of payment allowed" option set to "4"
    And the POS option 1215 is set to 4
    # Loyalty prompt control is Prompt always
    And the POS option 4214 is set to 1
    #Alternative processing feature is enabled
    And the POS option 4219 is set to 1
    And the RLM option RLMSendAuthAfterDecode is set to YES
    And the RLM option RLMDelayAuthForMOP is set to NO
    And the Sigma recognizes following cards
        | card_number       | card_description |
        | 12879784762398321 | Physical Loyalty |
        | 12879784762398322 | Mobile Loyalty   |
    And the POS has following sale items configured
        | barcode       | description     | price |
        | 099999999990  | Sale Item A     | 10.00 |
    And the epsilon host has no reward for card Mastercard
    And the epsilon host approves the next auth and capture request

@fast @positive
Scenario: Alternative processing feature is disabled, no loyalty card in a transaction, last chance loyalty prompt appear after mobile tender selection (before scanning)
    Given the POS is in a ready to sell state
    #Alternative processing feature is disabled
    And the POS option 4219 is set to 0
    And an item with barcode 099999999990 is present in the transaction
    Then the POS displays Last chance loyalty frame after MobilePay tender was selected

@fast @positive
Scenario: no loyalty card in a transaction, MobilePay without additional loyalty, last chance loyalty prompt appear after QR code scanning
    Given the POS is in a ready to sell state
    And an item with barcode 099999999990 is present in the transaction
    And the POS displays Please scan a barcode frame after MobilePay tender was selected
    When the cashier scans Mobile QR Barcode without additional loyalty card
    Then the POS displays Last chance loyalty frame

@fast @positive
Scenario: no loyalty card in a transaction, MobilePay with additional loyalty, last chance loyalty prompt does not appear after QR code scanning
    Given the POS is in a ready to sell state
    And an item with barcode 099999999990 is present in the transaction
    And the POS displays Please scan a barcode frame after MobilePay tender was selected
    When the cashier scans Mobile QR Barcode with additional loyalty card with description Mobile Loyalty
    Then the transaction is finalized
    And a loyalty card with description Mobile Loyalty is present in the previous transaction

@fast @positive
Scenario: transaction without loyalty card partialy tendered by cash, MobilePay without additional loyalty, last chance loyalty prompt does not appear after QR code scanning
    Given the POS is in a ready to sell state
    And an item with barcode 099999999990 is present in the transaction
    And the POS displays Last chance loyalty frame after selecting a cash tender button
    And the cashier presses Continue button
    And the cashier tenders the transaction with amount 5.00 in cash
    And the POS displays Please scan a barcode frame after MobilePay tender was selected
    When the cashier scans Mobile QR Barcode without additional loyalty card
    Then the transaction is finalized

@fast @positive
Scenario: transaction without loyalty card partialy tendered by cash, MobilePay with additional loyalty, last chance loyalty prompt does not appear after QR code scanning
    Given the POS is in a ready to sell state
    And an item with barcode 099999999990 is present in the transaction
    And the POS displays Last chance loyalty frame after selecting a cash tender button
    And the cashier presses Continue button
    And the cashier tenders the transaction with amount 5.00 in cash
    And the POS displays Please scan a barcode frame after MobilePay tender was selected
    When the cashier scans Mobile QR Barcode with additional loyalty card with description Mobile Loyalty
    Then the transaction is finalized
    And a loyalty card with description Mobile Loyalty is present in the previous transaction
