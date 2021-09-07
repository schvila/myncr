@pos @manual
Feature: MobilePay functionality, first phase of TS focuses on PDL enhancement

Background:
  Given the POS has essential configuration
  And the EPS simulator has essential configuration
  # MobilePay feature is enabled
  And the POS option 1240 is set to 1
  # Fuel credit prepay method is set to Auth and Capture
  And the POS option 1851 is set to 1
  And the RLM option RLMSendAuthAfterDecode is set to YES
  And the RLM option RLMDelayAuthForMOP is set to NO
  And the pricebook contains fuel grades
    | name    | price_per_gallon |
    | Premium | 5.00             |
    | Regular | 1.00             |
  And the pricebook contains discounts
    | name                    | external_id | type                           | value |
    | PDL_FPR_flat            | Z001        | fuel_price_rollback            | 0.00  |
    | PDL_non_fuel_percentage | Z002        | preset_percentage              | 0.00  |
    | PDL_FPR_percentage      | Z003        | percentage_fuel_price_rollback | 0.00  |
    | PDL_non_fuel_flat       | Z004        | preset_amount                  | 0.00  |
    | 10%_disc                |             | transaction_percentage         | 10.00 |
  And the pricebook contains fuel price rollbacks
    | name     | trigger | value |
    | MRD_FPR  | card1   | 0.15  |
  And the pricebook contains following MRD cards
    | name  | barcode |
    | card1 | 1234    |
  And the pump 1 has following hoses configured
    | hose_number | grade   |
    | 1           | Premium |
    | 2           | Regular |
  And the epsilon host rewards card Default with $0.25 PDL for all product codes
  And the epsilon host rewards card Discover with $0.10 PDL for all product codes
  And the epsilon host rewards card Amex with 1% PDL for all product codes
  And the epsilon host has no reward for card Mastercard
  And the epsilon host approves the next auth and capture request


@fast @positive @manual
Scenario Outline: Please scan a barcode frame is displayed after selecting a MobilePay tender
  Given the POS is in a ready to sell state
  And an item with barcode <item_barcode> is present in the transaction
  When the cashier presses mobilepay tender button
  Then a decode request with mobilepay flag is sent to EPS
  And a request for barcode scan is received from EPS
  And the POS displays Please scan a barcode frame

  Examples:
   | item_barcode |
   | 099999999990 |

@fast @positive @manual
Scenario Outline: Default PDL discount is awarded after credit decode for Credit tender (sanity check)
  Given the POS is in a ready to sell state
  And an item with barcode <item_barcode> is present in the transaction
  When the cashier swipes a credit card Discover after credit tender was selected
  Then a decode request is sent to EPS
  And a decode complete is received from EPS
  And the PDL discount with value $<amount> is in the virtual receipt
  And the PDL discount with value $<amount> is in the transaction
  And a sale request is sent to EPS
  And a sale response is received from EPS

  Examples:
   | item_barcode | amount |
   | 099999999990 | 0.25   |

@fast @positive @manual
Scenario Outline: Dry stock tendered by MobilePay, flat amount (item) PDL received (card specific, default is ignored for MobilePay) - flow described in detail, simplified duplicate for automation purposes is below
  Given the POS is in a ready to sell state
  And an item with barcode <item_barcode> is present in the transaction
  And the POS displays Please scan a barcode frame after MobilePay tender was selected
  When the cashier scans Discover card barcode
  Then a decode complete is received from EPS
  And an auth request with line items and current total is sent to EPS
  And an auth response with the awarded PDL is received from EPS
  And the PDL discount with value $<amount> is in the virtual receipt
  And the PDL discount with value $<amount> is in the transaction
  And a capture request for the final amount is sent to EPS
  And a capture response with is received from EPS
  And the transaction is finalized

  Examples:
   | item_barcode | amount |
   | 099999999990 | 0.10   |

@fast @positive @manual
Scenario Outline: Dry stock tendered by MobilePay, flat amount (item) PDL received
  Given the POS is in a ready to sell state
  And an item with barcode <item_barcode> is present in the transaction
  And the POS displays Please scan a barcode frame after MobilePay tender was selected
  When the cashier scans Discover card barcode
  Then the PDL discount with value $<amount> is in the virtual receipt
  And the PDL discount with value $<amount> is in the transaction

  Examples:
   | item_barcode | amount |
   | 099999999990 | 0.10   |

@fast @positive @manual
Scenario Outline: Dry stock tendered by MobilePay, percentage (item) PDL received
  Given the POS is in a ready to sell state
  And an item with barcode <item_barcode> is present in the transaction
  And the POS displays Please scan a barcode frame after MobilePay tender was selected
  When the cashier scans Amex card barcode
  Then the POS displays main menu frame
  And the PDL discount with value $<amount> is in the virtual receipt
  And the PDL discount with value $<amount> is in the transaction

  Examples:
   | item_barcode | amount |
   | 099999999990 | 0.01   |

@fast @positive @manual
Scenario Outline: Classic prepay cannot be tendered by MobilePay, error message is displayed
  # Fuel credit prepay method is set to Sale and Refund
  Given the POS option 1851 is set to 2
  And the POS is in a ready to sell state
  And a $<prepay_amount> prepay of Premium grade is present in the transaction
  When the cashier presses tender MobilePay button on main menu
  Then the POS displays an Error frame saying Classic prepay cannot be tendered by MobilePay

  Examples:
   | prepay_amount |
   | 20.00         |

@fast @positive @manual
Scenario Outline: Smart prepay tendered by MobilePay, flat amount (FPR) PDL received
  Given the POS is in a ready to sell state
  And a $<prepay_amount> prepay of Premium grade is present in the transaction
  And the POS displays Please scan a barcode frame after MobilePay tender was selected
  When the cashier scans Discover card barcode
  Then the POS displays main menu frame
  And the PDL discount without value is in the virtual receipt
  And the PDL discount without value is in the transaction
  And the Premium grade price per gallon on pump 1 is lowered by $0.10

  Examples:
   | prepay_amount |
   | 20.00         |

@fast @positive @manual
Scenario Outline: Smart prepay tendered by MobilePay, percentage (FPR) PDL received
  Given the POS is in a ready to sell state
  And a $<prepay_amount> prepay of Premium grade is present in the transaction
  And the POS displays Please scan a barcode frame after MobilePay tender was selected
  When the cashier scans Amex card barcode
  Then the POS displays main menu frame
  And the PDL discount without value is in the virtual receipt
  And the PDL discount without value is in the transaction
  And the Premium grade price per gallon on pump 1 is lowered by $0.05

  Examples:
   | prepay_amount |
   | 20.00         |

@fast @positive @manual
Scenario Outline: Postpay tendered by MobilePay, flat amount (FPR) PDL received
  Given the POS is in a ready to sell state
  And a $<postpay_amount> postpay of Premium grade is present in the transaction
  And the POS displays Please scan a barcode frame after MobilePay tender was selected
  When the cashier scans Discover card barcode
  Then the POS displays main menu frame
  And the PDL discount with value $<amount> is in the virtual receipt
  And the PDL discount with value $<amount> is in the transaction

  Examples:
   | postpay_amount | amount |
   | 20.00          | 0.40   |

@fast @positive @manual
Scenario Outline: Postpay tendered by MobilePay, percentage (FPR) PDL received
  Given the POS is in a ready to sell state
  And a $<postpay_amount> postpay of Premium grade is present in the transaction
  And the POS displays Please scan a barcode frame after MobilePay tender was selected
  When the cashier scans Amex card barcode
  Then the POS displays main menu frame
  And the PDL discount with value $<amount> is in the virtual receipt
  And the PDL discount with value $<amount> is in the transaction

  Examples:
   | postpay_amount | amount |
   | 20.00          | 0.20   |

@fast @positive @manual
Scenario Outline: Postpay tendered by MobilePay, partial approval from host, PDL (FPR) received
  Given the POS is in a ready to sell state
  And the epsilon host partially approves the next auth and capture requests
  And a $<postpay_amount> postpay of Premium grade is present in the transaction
  And the POS displays Please scan a barcode frame after MobilePay tender was selected
  When the cashier scans Amex card barcode
  Then the POS displays main menu frame
  And the PDL discount with value $<amount> is in the virtual receipt
  And the PDL discount with value $<amount> is in the transaction
  And the MobilePay tender with value $<tendered_amount> is in the virtual receipt
  And the MobilePay tender with value $<tendered_amount> is in the transaction

  Examples:
   | postpay_amount | amount | tendered_amount |
   | 20.00          | 0.20   | 10.00           |

@fast @positive @manual
Scenario Outline: Postpay tendered by MobilePay, decline from host, no PDL received
  Given the POS is in a ready to sell state
  And the epsilon host declines the next auth and capture requests
  And a $<postpay_amount> postpay of Premium grade is present in the transaction
  And the POS displays Please scan a barcode frame after MobilePay tender was selected
  When the cashier scans Amex card barcode
  Then the POS displays Declined error message
  And the PDL discount is not in the virtual receipt
  And the PDL discount is not in the transaction
  And the MobilePay tender is not in the virtual receipt
  And the MobilePay tender is not in the transaction

  Examples:
   | postpay_amount |
   | 20.00          |

@fast @positive @manual
Scenario Outline: Postpay tendered by MobilePay, no response from host, no PDL received
  Given the POS is in a ready to sell state
  And the epsilon host does not respond to the next auth request
  And a $<postpay_amount> postpay of Premium grade is present in the transaction
  And the POS displays Please scan a barcode frame after MobilePay tender was selected
  When the cashier scans Amex card barcode
  Then the POS displays Timeout error message
  And the PDL discount is not in the virtual receipt
  And the PDL discount is not in the transaction
  And the MobilePay tender is not in the virtual receipt
  And the MobilePay tender is not in the transaction

  Examples:
   | postpay_amount |
   | 20.00          |

@fast @positive @manual
Scenario Outline: Postpay tendered by MobilePay with loyalty, RLM and PDL (FPR) discounts received
  Given the POS is in a ready to sell state
  And the sigma host rewards card Loyalty1 with $0.20 RLM discount
  And a $<postpay_amount> postpay of Premium grade is present in the transaction
  And a loyalty card Loyalty1 is present in the transaction
  And the POS displays Please scan a barcode frame after MobilePay tender was selected
  When the cashier scans Amex card barcode
  Then the POS displays main menu frame
  And the PDL discount with value $<amount> is in the virtual receipt
  And the PDL discount with value $<amount> is in the transaction
  And the RLM discount with value $0.20 is in the virtual receipt
  And the RLM discount with value $0.20 is in the transaction

  Examples:
   | postpay_amount | amount |
   | 20.00          | 0.20   |

@fast @positive @manual
Scenario Outline: Postpay tendered by MobilePay, local discount and PDL (FPR) received
  Given the POS is in a ready to sell state
  And a $<postpay_amount> postpay of Premium grade is present in the transaction
  And the cashier applied discount <discount> to the transaction
  And the POS displays Please scan a barcode frame after MobilePay tender was selected
  When the cashier scans Amex card barcode
  Then the POS displays main menu frame
  And the PDL discount with value $<amount> is in the virtual receipt
  And the PDL discount with value $<amount> is in the transaction
  And the discount with value $<discount_value> is in the virtual receipt
  And the discount with value $<discount_value> is in the transaction

  Examples:
   | postpay_amount | amount | discount | discount_value |
   | 20.00          | 0.20   | 10%_disc | 0.20           |

@fast @positive @manual
Scenario Outline: Postpay tendered by MobilePay, QMOP FPR and PDL (FPR) received
  Given the pricebook contains fuel price rollbacks
    | name     | trigger | value |
    | QMOP_FPR | QMOP    | 0.10  |
  # Tender qualification mode set to all from tender setup
  And the POS option 1223 is set to 6
  And the MobilePay tender is configured as qualifying for a QMOP
  And the POS is in a ready to sell state
  And a $<postpay_amount> postpay of Premium grade is present in the transaction
  And the POS displays Please scan a barcode frame after MobilePay tender was selected
  When the cashier scans Amex card barcode
  Then the POS displays main menu frame
  And the PDL discount with value $<amount> is in the virtual receipt
  And the PDL discount with value $<amount> is in the transaction
  And the fuel price rollback <fpr_name> with value $<fpr_value> is in the virtual receipt
  And the fuel price rollback <fpr_name> with value $<fpr_value> is in the transaction

  Examples:
   | postpay_amount | amount | fpr_name | fpr_value |
   | 20.00          | 0.20   | QMOP FPR | 0.40      |

@fast @positive @manual
Scenario Outline: Postpay tendered by MobilePay, MRD FPR and PDL (FPR) received
  Given the POS is in a ready to sell state
  And a $<postpay_amount> postpay of Premium grade is present in the transaction
  And the cashier scans a barcode <MRD_card_barcode>
  And the POS displays Please scan a barcode frame after MobilePay tender was selected
  When the cashier scans Amex card barcode
  Then the POS displays main menu frame
  And the PDL discount with value $<amount> is in the virtual receipt
  And the PDL discount with value $<amount> is in the transaction
  And the fuel price rollback <fpr_name> with value $<fpr_value> is in the virtual receipt
  And the fuel price rollback <fpr_name> with value $<fpr_value> is in the transaction

  Examples:
   | postpay_amount | amount | fpr_name | fpr_value |
   | 20.00          | 0.20   | MRD_FPR  | 0.60      |

@fast @positive @manual
Scenario Outline: Postpay tendered partially by cash and MobilePay, PDL (FPR) received
  Given the POS is in a ready to sell state
  And a $<postpay_amount> postpay of Premium grade is present in the transaction
  And the transaction is partially tendered with $<cash_tender> in cash
  And the POS displays Please scan a barcode frame after MobilePay tender was selected
  When the cashier scans Discover card barcode
  Then the POS displays main menu frame
  And the PDL discount with value $<amount> is in the virtual receipt
  And the PDL discount with value $<amount> is in the transaction

  Examples:
   | postpay_amount | cash_tender | amount |
   | 20.00          | 5.00        | 0.40   |

@fast @positive @manual
Scenario Outline: Postpay and dry stock tendered MobilePay, PDL received on both (FPR on fuel, flat amount on dry stock)
  Given the POS is in a ready to sell state
  And an item with barcode <item_barcode> is present in the transaction
  And a $<postpay_amount> postpay of Premium grade is present in the transaction
  And the POS displays Please scan a barcode frame after MobilePay tender was selected
  When the cashier scans Discover card barcode
  Then the PDL discount with value $<fuel_amount> is in the virtual receipt
  And the PDL discount with value $<fuel_amount> is in the transaction
  And the PDL discount with value $<dry_stock_amount> is in the virtual receipt
  And the PDL discount with value $<dry_stock_amount> is in the transaction

  Examples:
   | item_barcode | postpay_amount | fuel_amount | dry_stock_amount |
   | 099999999990 | 20.00          | 0.40        | 0.10             |

@fast @positive @manual
Scenario Outline: MobilePay feature disabled, MobilePay tender button is not displayed
  # MobilePay feature is disabled
  Given the POS option 1240 is set to 0
  And the POS is in a ready to sell state
  When the cashier scans a barcode <barcode>
  Then the MobilePay tender button is not displayed

  Examples:
    | barcode      |
    | 099999999990 |