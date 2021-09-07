@pos @mfc
Feature: MFC
    Manufacturer coupons are correctly applied on eligible items.

    Background:
      Given the POS has essential configuration
        # Allow manufacturer coupons set to Yes
        And the POS option 1109 is set to 1
        # Manufacturer coupon reduces tax set to No
        And the POS option 1111 is set to 0
        And the POS has following sale items configured
            | barcode       | description  | price |
            | 099999999990  | Sale Item A  | 0.99  |
            | 088888888880  | Sale Item B  | 1.99  |
            | 066666666660  | Sale Item D  | 2.39  |
        And the pricebook contains coupons
            | description                   | reduction_value | disc_type        | disc_mode         | disc_quantity   |
            | Preset Percentage Coupon 50   | 500000          | PRESET_PERCENT   | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |
            | Preset Amount Coupon 50       | 5000            | PRESET_AMOUNT    | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |
        And the pricebook contains discounts
            | description                   | reduction_value | disc_type        | disc_mode         | disc_quantity   |
            | Preset Percentage Discount 50 | 500000          | PRESET_PERCENT   | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |
            | Preset Amount Discount 50     | 5000            | PRESET_AMOUNT    | WHOLE_TRANSACTION | ALLOW_ONLY_ONCE |

    @fast @negative
    Scenario Outline: Apply MFC when MFC are not allowed displays Manufacturer Coupons Not Allowed error frame
        # Allow manufacturer coupons set to No
        Given the POS option 1109 is set to 0
        And the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        When the cashier scans coupon <mfc_barcode> of type UPC_EAN
        Then the POS displays Manufacturer Coupons Not Allowed error frame
        And the transaction does not contain a manufacturer coupon with a discount value of <mfc_price>
        And the coupon with price <mfc_price> is not in the virtual receipt

        Examples:
        | item_barcode | mfc_barcode  | mfc_price |
        | 066666666660 | 566666000032 | 1.10      |


    @fast @negative
    Scenario Outline: Apply MFC when MFC requirements not met displays Manufacturer Coupon requirements not met error frame
        Given the POS is in a ready to sell state
        When the cashier scans coupon <mfc_barcode> of type UPC_EAN
        Then the POS displays Manufacturer Coupon requirements not met error frame
        And no transaction is in progress

        Examples:
        | mfc_barcode  |
        | 566666000032 |


    @fast
    Scenario Outline: Apply MFC 'get $X.XX off' to eligible item
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        When the cashier scans coupon <mfc_barcode> of type UPC_EAN
        Then the transaction contains a manufacturer coupon with a discount value of <mfc_price>
        And the coupon with price <mfc_price> is in the virtual receipt

        Examples:
        | item_barcode | mfc_barcode  | mfc_price |
        | 066666666660 | 566666000032 | 1.10      |
        | 066666666660 | 566666000049 | 1.35      |
        | 066666666660 | 566666000056 | 1.40      |
        | 066666666660 | 566666000063 | 1.60      |
        | 066666666660 | 566666000100 | 0.10      |
        | 099999999990 | 599999000103 | 0.10      |
        | 066666666660 | 566666000117 | 1.85      |
        | 066666666660 | 566666000124 | 0.12      |
        | 099999999990 | 599999000127 | 0.12      |
        | 066666666660 | 566666000155 | 0.15      |
        | 099999999990 | 599999000158 | 0.15      |
        | 066666666660 | 566666000209 | 0.20      |
        | 099999999990 | 599999000202 | 0.20      |
        | 066666666660 | 566666000254 | 0.25      |
        | 099999999990 | 599999000257 | 0.25      |
        | 066666666660 | 566666000292 | 0.29      |
        | 099999999990 | 599999000295 | 0.29      |
        | 066666666660 | 566666000308 | 0.30      |
        | 066666666660 | 566666000353 | 0.35      |
        | 066666666660 | 566666000391 | 0.39      |
        | 066666666660 | 566666000407 | 0.40      |
        | 066666666660 | 566666000452 | 0.45      |
        | 066666666660 | 566666000490 | 0.49      |
        | 066666666660 | 566666000506 | 0.50      |
        | 066666666660 | 566666000551 | 0.55      |
        | 066666666660 | 566666000599 | 0.59      |
        | 066666666660 | 566666000605 | 0.60      |
        | 066666666660 | 566666000650 | 0.65      |
        | 066666666660 | 566666000698 | 0.69      |
        | 066666666660 | 566666000704 | 0.70      |
        | 099999999990 | 599999000707 | 0.70      |
        | 066666666660 | 566666000759 | 0.75      |
        | 099999999990 | 599999000752 | 0.75      |
        | 066666666660 | 566666000766 | 1.00      |
        | 066666666660 | 566666000773 | 1.25      |
        | 066666666660 | 566666000780 | 1.50      |
        | 066666666660 | 566666000797 | 0.79      |
        | 066666666660 | 566666000803 | 0.80      |
        | 066666666660 | 566666000810 | 1.75      |
        | 066666666660 | 566666000827 | 2.00      |
        | 066666666660 | 566666000834 | 2.25      |
        | 066666666660 | 566666000858 | 0.85      |
        | 066666666660 | 566666000896 | 0.89      |
        | 066666666660 | 566666000902 | 0.90      |
        | 066666666660 | 566666000957 | 0.95      |
        | 066666666660 | 566666000995 | 0.99      |


    @fast @negative
    Scenario Outline: Apply MFC 'Fixed Value Off' to a transaction with multiple cheap but otherwise eligible items
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode_1> is present in the transaction 5 times
        And an item with barcode <item_barcode_2> is present in the transaction 2 times
        When the cashier scans coupon <mfc_barcode> of type UPC_EAN
        Then the POS displays Coupon amount too large error frame
        And the coupon with price <mfc_price> is not in the virtual receipt
        And the transaction does not contain a manufacturer coupon with a discount value of <mfc_price>

       Examples:
       | item_barcode_1 | item_barcode_2 | mfc_barcode  | mfc_price |
       | 066666666660   | 099999999990   | 566666000742 |  5.00     |
       | 066666666660   | 099999999990   | 566666000612 | 10.00     |
       | 066666666660   | 099999999990   | 566666000629 |  9.50     |
       | 066666666660   | 099999999990   | 566666000636 |  9.00     |


    @fast
    Scenario Outline: Manually apply 'Fixed Value Off' coupon to eligible item
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        When the cashier manually enters coupon <mfc_barcode> of type UPC_EAN
        Then the coupon with price <mfc_price> is in the virtual receipt
        And the transaction contains a manufacturer coupon with a discount value of <mfc_price>

        Examples:
        | item_barcode | mfc_barcode    | mfc_price    |
        | 066666666660 | 566666000032   | 1.10         |
        | 066666666660 | 566666000049   | 1.35         |
        | 066666666660 | 566666000056   | 1.40         |
        | 066666666660 | 566666000063   | 1.60         |
        | 066666666660 | 566666000100   | 0.10         |
        | 099999999990 | 599999000103   | 0.10         |
        | 066666666660 | 566666000117   | 1.85         |
        | 066666666660 | 566666000124   | 0.12         |
        | 099999999990 | 599999000127   | 0.12         |
        | 066666666660 | 566666000155   | 0.15         |
        | 099999999990 | 599999000158   | 0.15         |
        | 066666666660 | 566666000209   | 0.20         |
        | 099999999990 | 599999000202   | 0.20         |
        | 066666666660 | 566666000254   | 0.25         |
        | 099999999990 | 599999000257   | 0.25         |
        | 066666666660 | 566666000292   | 0.29         |
        | 099999999990 | 599999000295   | 0.29         |
        | 066666666660 | 566666000308   | 0.30         |
        | 066666666660 | 566666000353   | 0.35         |
        | 066666666660 | 566666000391   | 0.39         |
        | 066666666660 | 566666000407   | 0.40         |
        | 066666666660 | 566666000452   | 0.45         |
        | 066666666660 | 566666000490   | 0.49         |
        | 066666666660 | 566666000506   | 0.50         |
        | 066666666660 | 566666000551   | 0.55         |
        | 066666666660 | 566666000599   | 0.59         |
        | 066666666660 | 566666000605   | 0.60         |
        | 066666666660 | 566666000650   | 0.65         |
        | 066666666660 | 566666000698   | 0.69         |
        | 066666666660 | 566666000704   | 0.70         |
        | 099999999990 | 599999000707   | 0.70         |
        | 066666666660 | 566666000759   | 0.75         |
        | 099999999990 | 599999000752   | 0.75         |
        | 066666666660 | 566666000766   | 1.00         |
        | 066666666660 | 566666000773   | 1.25         |
        | 066666666660 | 566666000780   | 1.50         |
        | 066666666660 | 566666000797   | 0.79         |
        | 066666666660 | 566666000803   | 0.80         |
        | 066666666660 | 566666000810   | 1.75         |
        | 066666666660 | 566666000827   | 2.00         |
        | 066666666660 | 566666000834   | 2.25         |
        | 066666666660 | 566666000858   | 0.85         |
        | 066666666660 | 566666000896   | 0.89         |
        | 066666666660 | 566666000902   | 0.90         |
        | 066666666660 | 566666000957   | 0.95         |
        | 066666666660 | 566666000995   | 0.99         |


    @fast
    Scenario Outline: Apply MFC 'Buy 2 or more, get $X.XX off' to same two eligible items
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction 2 times
        When the cashier scans coupon <mfc_barcode> of type UPC_EAN
        Then the coupon with price <mfc_price> is in the virtual receipt
        And the transaction contains a manufacturer coupon with a discount value of <mfc_price>

        Examples:
        | item_barcode | mfc_barcode    | mfc_price    |
        | 099999999990 | 599999000219   | 0.35         |
        | 099999999990 | 599999000226   | 0.40         |
        | 099999999990 | 599999000233   | 0.45         |
        | 099999999990 | 599999000240   | 0.50         |
        | 099999999990 | 599999000288   | 0.55         |
        | 099999999990 | 599999000318   | 0.60         |
        | 099999999990 | 599999000325   | 0.75         |
        | 066666666660 | 566666000339   | 1.00         |
        | 066666666660 | 566666000346   | 1.25         |
        | 066666666660 | 566666000360   | 1.50         |
        | 066666666660 | 566666000438   | 1.10         |
        | 066666666660 | 566666000445   | 1.35         |
        | 066666666660 | 566666000469   | 1.60         |
        | 066666666660 | 566666000476   | 1.75         |
        | 066666666660 | 566666000483   | 1.85         |
        | 066666666660 | 566666000513   | 2.00         |
        | 099999999990 | 599999000530   | 0.10         |
        | 099999999990 | 599999000547   | 0.15         |
        | 099999999990 | 599999000561   | 0.20         |
        | 099999999990 | 599999000578   | 0.25         |
        | 099999999990 | 599999000585   | 0.30         |
        | 099999999990 | 599999000981   | 0.65         |

    @fast
    Scenario Outline: "Apply MFC 'Buy 3 or more, get $X.XX off' to same three eligible items"
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction 3 times
        When the cashier scans coupon <mfc_barcode> of type UPC_EAN
        Then the coupon with price <mfc_price> is in the virtual receipt
        And the transaction contains a manufacturer coupon with a discount value of <mfc_price>

        Examples:
        | item_barcode | mfc_barcode    | mfc_price    |
        | 066666666660 | 566666000070   | 1.50         |
        | 066666666660 | 566666000094   | 2.00         |
        | 066666666660 | 566666000377   | 0.25         |
        | 099999999990 | 599999000370   | 0.25         |
        | 066666666660 | 566666000384   | 0.30         |
        | 066666666660 | 566666000414   | 0.50         |
        | 099999999990 | 599999000417   | 0.50         |
        | 066666666660 | 566666000421   | 1.00         |
        | 066666666660 | 566666000520   | 0.55         |

    @fast
    Scenario Outline: Apply MFC 'Buy 4 or more, get $X.XX off' to same four eligible items
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction 4 times
        When the cashier scans coupon <mfc_barcode> of type UPC_EAN
        Then the coupon with price <mfc_price> is in the virtual receipt
        And the transaction contains a manufacturer coupon with a discount value of <mfc_price>

        Examples:
        | item_barcode | mfc_barcode    | mfc_price    |
        | 066666666660 | 566666000131   | 1.00         |


    @fast
    Scenario Outline: Apply MFC with prompted value, Enter amount frame is displayed.
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        When the cashier scans coupon <mfc_barcode> of type UPC_EAN
        Then the POS displays Enter amount frame

        Examples:
        | item_barcode | mfc_barcode    |
        | 099999999990 | 599999000004   |

    @fast @negative
    Scenario Outline: Enter 0.00 value to a prompted MFC, Tender not allowed error frame is displayed.
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        And the cashier scanned coupon <mfc_barcode> of type UPC_EAN
        When the cashier enters a 0.00 value to the prompted coupon
        Then the POS displays Tender not allowed error frame

        Examples:
        | item_barcode | mfc_barcode    |
        | 099999999990 | 599999000004   |

    @fast
    Scenario Outline: Enter value to a prompted MFC.
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        And the cashier scanned coupon <mfc_barcode> of type UPC_EAN
        When the cashier enters a <mfc_price> value to the prompted coupon
        Then the coupon with price <mfc_price> is in the virtual receipt
        And the transaction contains a manufacturer coupon with a discount value of <mfc_price>

        Examples:
        | item_barcode | mfc_barcode    | mfc_price    |
        | 099999999990 | 599999000004   | 0.50         |
        | 099999999990 | 599999000004   | 0.60         |
        | 066666666660 | 566666000001   | 0.50         |
        | 066666666660 | 566666000001   | 0.60         |

    @fast
    Scenario Outline: Apply MFC to an eligible items and void the coupon
        Given the POS is in a ready to sell state
        And the cashier applied coupon <mfc_barcode> of type UPC_EAN to 3 item/s with barcode <item_barcode>
        When the cashier voids Coupon with price <mfc_price>
        Then the coupon with price <mfc_price> is not in the virtual receipt
        And the transaction does not contain a manufacturer coupon with a discount value of <mfc_price>

        Examples:
        | item_barcode | mfc_barcode     | mfc_price    |
        | 066666666660 | 566666000094    | 2.00         |

    @fast
    Scenario Outline: Apply MFC to an eligible items, void the coupon and reapply
        Given the POS is in a ready to sell state
        And the cashier applied coupon <mfc_barcode_1> of type UPC_EAN to 3 item/s with barcode <item_barcode>
        And the cashier voided Coupon with price <mfc_price_1>
        When the cashier scans coupon <mfc_barcode_2> of type UPC_EAN
        Then the coupon with price <mfc_price_2> is in the virtual receipt
        And the transaction contains a manufacturer coupon with a discount value of <mfc_price_2>

        Examples:
        | item_barcode | mfc_barcode_1  | mfc_price_1  | mfc_barcode_2 | mfc_price_2  |
        | 066666666660 | 566666000094   | 2.00         | 566666000421  | 1.00         |

    @fast
    Scenario Outline: Apply MFC 'Buy one, get one free' to eligible items with reduced tax
        # Manufacturer coupon reduces tax set to Yes
        Given the POS option 1111 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction 2 times
        When the cashier scans coupon <mfc_barcode> of type UPC_EAN
        Then the coupon with price <mfc_price> is in the virtual receipt
        And the transaction contains a manufacturer coupon with a discount value of <mfc_price>
        And the total tax is changed in current transaction to <tax_amount>

        Examples:
        | item_barcode  | mfc_barcode   | mfc_price | tax_amount |
        | 099999999990  | 599999000141  | 0.99      | 0.07       |
        | 088888888880  | 588888000140  | 1.99      | 0.14       |

    @fast
    Scenario Outline: Apply MFC 'Buy one, get one free' to eligible items
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction 2 times
        When the cashier scans coupon <mfc_barcode> of type UPC_EAN
        Then the coupon with price <mfc_price> is in the virtual receipt
        And the transaction contains a manufacturer coupon with a discount value of <mfc_price>
        And the total tax <tax_amount> is not changed in current transaction

        Examples:
        | item_barcode  | mfc_barcode   | mfc_price | tax_amount |
        | 099999999990  | 599999000141  | 0.99      | 0.14       |
        | 088888888880  | 588888000140  | 1.99      | 0.28       |

    @fast
    Scenario Outline: Manually apply MFC 'Buy one, get one free' to eligible items
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction 2 times
        When the cashier manually enters coupon <mfc_barcode> of type UPC_EAN
        Then the coupon with price <mfc_price> is in the virtual receipt
        And the transaction contains a manufacturer coupon with a discount value of <mfc_price>
        And the total tax <tax_amount> is not changed in current transaction

        Examples:
        | item_barcode  | mfc_barcode   | mfc_price | tax_amount |
        | 099999999990  | 599999000141  | 0.99      | 0.14       |
        | 088888888880  | 588888000140  | 1.99      | 0.28       |

    @fast @negative
    Scenario Outline: Apply expired MFC to eligible item
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction 2 times
        When the cashier scans expired coupon <mfc_barcode> of type UPC_EAN
        Then the POS displays Coupon Expired error frame
        And the coupon with price <mfc_price> is not in the virtual receipt
        And the transaction does not contain a manufacturer coupon with a discount value of <mfc_price>

        Examples:
        | item_barcode   | mfc_barcode                | mfc_price |
        | 099999999990   | 59999900020281010000001216 | 0.20      |

    @fast @negative
    Scenario Outline: Manually apply expired MFC to eligible items
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction 2 times
        When the cashier manually enters coupon <mfc_barcode> of type UPC_EAN
        Then the POS displays Coupon Expired error frame
        And the coupon with price <mfc_price> is not in the virtual receipt
        And the transaction does not contain a manufacturer coupon with a discount value of <mfc_price>

        Examples:
        | item_barcode   | mfc_barcode                | mfc_price |
        | 099999999990   | 59999900020281010000001216 | 0.20      |

    @fast @positive
    Scenario Outline: Apply MFC 'Free Merchandise' to eligible item
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        When the cashier scans coupon <mfc_barcode> of type UPC_EAN
        Then the coupon with price <mfc_price> is in the virtual receipt
        And the transaction contains a manufacturer coupon with a discount value of <mfc_price>
        And the total tax <tax_amount> is not changed in current transaction

        Examples:
        | item_barcode | mfc_barcode                        | mfc_price    | tax_amount |
        | 099999999990 | 59999900001181005000002100000000   | 0.99         | 0.07       |
        | 088888888880 | 58888800001081005000002100000000   | 1.99         | 0.14       |

    @fast
    Scenario Outline: Manually apply MFC 'Free Merchandise' to eligible item
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        When the cashier manually enters coupon <mfc_barcode> of type UPC_EAN
        Then the coupon with price <mfc_price> is in the virtual receipt
        And the transaction contains a manufacturer coupon with a discount value of <mfc_price>
        And the total tax <tax_amount> is not changed in current transaction

        Examples:
        | item_barcode | mfc_barcode                        | mfc_price    | tax_amount |
        | 099999999990 | 59999900001181005000002100000000   | 0.99         | 0.07       |
        | 088888888880 | 58888800001081005000002100000000   | 1.99         | 0.14       |

    @fast
    Scenario Outline: Apply MFC 'Buy X, Get $X.XX Off' to eligible items
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction 2 times
        When the cashier scans coupon <mfc_barcode> of type UPC_EAN
        Then the coupon with price <mfc_price> is in the virtual receipt
        And the transaction contains a manufacturer coupon with a discount value of <mfc_price>
        And the total tax <tax_amount> is not changed in current transaction

        Examples:
        | item_barcode | mfc_barcode                            | mfc_price    | tax_amount |
        | 099999999990 | 599999000240810100000012252100000000   | 0.50         | 0.14       |
        | 099999999990 | 599999000288810100000012252100000000   | 0.55         | 0.14       |
        | 099999999990 | 599999000332810100000012252100000000   | 1.00         | 0.14       |
        | 099999999990 | 599999000578810100000012252100000000   | 0.25         | 0.14       |
        | 099999999990 | 599999000585810100000012252100000000   | 0.30         | 0.14       |

    @fast
    Scenario Outline: Manually apply MFC 'Buy X, Get $X.XX Off' to eligible items
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction 2 times
        When the cashier manually enters coupon <mfc_barcode> of type UPC_EAN
        Then the coupon with price <mfc_price> is in the virtual receipt
        And the transaction contains a manufacturer coupon with a discount value of <mfc_price>
        And the total tax <tax_amount> is not changed in current transaction

        Examples:
        | item_barcode | mfc_barcode                            | mfc_price    | tax_amount |
        | 099999999990 | 599999000240810100000012252100000000   | 0.50         | 0.14       |
        | 099999999990 | 599999000288810100000012252100000000   | 0.55         | 0.14       |
        | 099999999990 | 599999000332810100000012252100000000   | 1.00         | 0.14       |
        | 099999999990 | 599999000578810100000012252100000000   | 0.25         | 0.14       |
        | 099999999990 | 599999000585810100000012252100000000   | 0.30         | 0.14       |

    @fast @negative
    Scenario Outline: Apply expired MFC  'Buy X, Get $X.XX Off' with longer barcode formats to eligible items
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction 2 times
        When the cashier scans expired coupon <mfc_barcode> of type UPC_EAN
        Then the POS displays Coupon Expired error frame
        And the coupon with price <mfc_price> is not in the virtual receipt
        And the transaction does not contain a manufacturer coupon with a discount value of <mfc_price>

        Examples:
        | item_barcode | mfc_barcode                            | mfc_price |
        | 099999999990 | 599999000240810100000012112100000000   | 0.50      |
        | 099999999990 | 599999000288810100000012112100000000   | 0.55      |
        | 099999999990 | 599999000332810100000012112100000000   | 1.00      |
        | 099999999990 | 599999000578810100000012112100000000   | 0.25      |
        | 099999999990 | 599999000585810100000012112100000000   | 0.30      |

    @fast @negative
    Scenario Outline: Manually apply expired MFC 'Buy X, Get $X.XX Off' with longer barcode formats to eligible items
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction 2 times
        When the cashier manually enters coupon <mfc_barcode> of type UPC_EAN
        Then the POS displays Coupon Expired error frame
        And the coupon with price <mfc_price> is not in the virtual receipt
        And the transaction does not contain a manufacturer coupon with a discount value of <mfc_price>

        Examples:
        | item_barcode | mfc_barcode                            | mfc_price |
        | 099999999990 | 599999000240810100000012112100000000   | 0.50      |
        | 099999999990 | 599999000288810100000012112100000000   | 0.55      |
        | 099999999990 | 599999000332810100000012112100000000   | 1.00      |
        | 099999999990 | 599999000578810100000012112100000000   | 0.25      |
        | 099999999990 | 599999000585810100000012112100000000   | 0.30      |

    @fast
    Scenario Outline: Apply only UPC-A portion of a MFC 'Buy 2, Get 1 Free' to eligible items
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction 3 times
        When the cashier scans coupon <mfc_barcode> of type UPC_EAN
        Then the coupon with price <mfc_price> is in the virtual receipt
        And the transaction contains a manufacturer coupon with a discount value of <mfc_price>
        And the total tax <tax_amount> is not changed in current transaction

        Examples:
        | item_barcode | mfc_barcode    | mfc_price    | tax_amount |
        | 066666666660 | 566666000162   | 2.39         |    0.42    |
        | 099999999990 | 599999000165   | 0.99         |    0.21    |

    @fast
    Scenario Outline: Scan MFC for free item after applying a discount, POS displays frame Tender not allowed for all items
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        And the cashier added a <discount_type> <discount_name>
        When the cashier scans coupon <mfc_barcode> of type UPC_EAN
        Then POS displays Amount will be restricted to amount frame

        Examples:
        | item_barcode | mfc_barcode  | discount_type | discount_name                 |
        | 088888888880 | 588888000010 | coupon        | Preset Percentage Coupon 50   |
        | 066666666660 | 566666000018 | coupon        | Preset Amount Coupon 50       |
        | 088888888880 | 588888000010 | discount      | Preset Percentage Discount 50 |
        | 066666666660 | 566666000018 | discount      | Preset Amount Discount 50     |

    @fast
    Scenario Outline: Confirm the restricted amount on the Tender not allowed for all items frame after applying a discount and adding a MFC for free item
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        And the cashier added a <discount_type> <discount_name>
        And the cashier scanned coupon <mfc_barcode> of type UPC_EAN
        And POS displayed Amount will be restricted to amount frame
        When the cashier selects Yes button
        Then the coupon with price <mfc_price> is in the virtual receipt
        And the transaction contains a manufacturer coupon with a discount value of <mfc_price>

        Examples:
        | item_barcode | mfc_barcode  | mfc_price | discount_type | discount_name                 |
        | 088888888880 | 588888000010 | 0.99      | coupon        | Preset Percentage Coupon 50   |
        | 066666666660 | 566666000018 | 1.89      | coupon        | Preset Amount Coupon 50       |
        | 088888888880 | 588888000010 | 0.99      | discount      | Preset Percentage Discount 50 |
        | 066666666660 | 566666000018 | 1.89      | discount      | Preset Amount Discount 50     |

    @fast
    Scenario Outline: Decline the restricted amount on the Tender not allowed for all items frame after applying a discount and adding a MFC for free item
        Given the POS is in a ready to sell state
        And an item with barcode <item_barcode> is present in the transaction
        And the cashier added a <discount_type> <discount_name>
        And the cashier scanned coupon <mfc_barcode> of type UPC_EAN
        And POS displayed Amount will be restricted to amount frame
        When the cashier selects No button
        Then the coupon with price <mfc_price> is not in the virtual receipt
        And the transaction does not contain a manufacturer coupon with a discount value of <mfc_price>

        Examples:
        | item_barcode | mfc_barcode  | mfc_price | discount_type | discount_name                 |
        | 088888888880 | 588888000010 | 0.99      | coupon        | Preset Percentage Coupon 50   |
        | 066666666660 | 566666000018 | 1.89      | coupon        | Preset Amount Coupon 50       |
        | 088888888880 | 588888000010 | 0.99      | discount      | Preset Percentage Discount 50 |
        | 066666666660 | 566666000018 | 1.89      | discount      | Preset Amount Discount 50     |