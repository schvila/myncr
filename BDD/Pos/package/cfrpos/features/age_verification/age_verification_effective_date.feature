@pos
Feature: Age verification with effective date
    This feature file focuses on adding items with age verification with effective date required and different methods to confirm customer's age.
    We assume the two age restriction levels to be 18 years and 21 years.
    
    Background: POS is properly configured for Age verification with effective date feature
        Given the POS has essential configuration
        # "Age verification" option set to "By birthdate or license swipe"
        And the POS option 1010 is set to 2 
        And the POS has following sale items with future effective date configured
            | barcode      | description         | price  | item_id     | modifier1_id | effective_date_after_years |
            | 01234543210  | Tobacco Item F      | 5.69   | 01234543210 | 0            | 2                          |
        And the POS has following sale items with past effective date configured
            | barcode      | description         | price  | item_id     | modifier1_id | effective_date_before_years |
            | 05432123450  | Tobacco Item P1     | 8.69   | 01234543211 | 0            | 1                           |
            | 05544334450  | Tobacco Item P5     | 9.69   | 01234543212 | 0            | 5                           |

    @fast
    Scenario Outline: Tobacco item has an effective date in the future for tobacco 21 law, 18yo and older customer passes age verification
        Given the POS is in a ready to sell state
        And the POS displays Age verification frame after scanning an item barcode <barcode>
        When the cashier manually enters the <customer_age>yo customer's birthday
        Then the POS displays main menu frame
        And an item <description> with price <price> is in the virtual receipt
        And an item <description> with price <price> is in the current transaction

        Examples:
        | barcode     | description    | price | customer_age |
        | 01234543210 | Tobacco Item F | 5.69  | 18           |
        | 01234543210 | Tobacco Item F | 5.69  | 21           |


    @fast
    Scenario Outline: Tobacco item has an effective date in the future for tobacco 21 law, under 18yo customer does not pass age verification
        Given the POS is in a ready to sell state
        And the POS displays Age verification frame after scanning an item barcode <barcode>
        When the cashier manually enters the <customer_age>yo customer's birthday
        Then the POS displays an Error frame saying Customer does not meet age requirement
        And an item <description> with price <price> is not in the virtual receipt
        And an item <description> with price <price> is not in the current transaction

        Examples:
        | barcode     | description    | price | customer_age |
        | 01234543210 | Tobacco Item F | 5.69  | 16           |
        | 01234543210 | Tobacco Item F | 5.69  | 17           |


    @fast
    Scenario Outline: Tobacco item has an effective date in the past for tobacco 21 law, 21yo and older customer passes age verification
        Given the POS is in a ready to sell state
        And the POS displays Age verification frame after scanning an item barcode <barcode>
        When the cashier manually enters the <customer_age>yo customer's birthday
        Then the POS displays main menu frame
        And an item <description> with price <price> is in the virtual receipt
        And an item <description> with price <price> is in the current transaction

        Examples:
        | barcode     | description     | price | customer_age |
        | 05432123450 | Tobacco Item P1 | 8.69  | 21           |
        | 05544334450 | Tobacco Item P5 | 9.69  | 21           |
        | 05432123450 | Tobacco Item P1 | 8.69  | 29           |
        | 05544334450 | Tobacco Item P5 | 9.69  | 29           |


    @fast
    Scenario Outline: Tobacco item has an effective date in the past for tobacco 21 law, 18yo customer does not pass age verification
        Given the POS is in a ready to sell state
        And the POS displays Age verification frame after scanning an item barcode <barcode>
        When the cashier manually enters the <customer_age>yo customer's birthday
        Then the POS displays an Error frame saying Customer does not meet age requirement
        # TODO The error message will probably be customized to reflect the effective date of the 21-to-buy-tobacco law
        And an item <description> with price <price> is not in the virtual receipt
        And an item <description> with price <price> is not in the current transaction

        Examples:
        | barcode     | description     | price | customer_age |
        | 05544334450 | Tobacco Item P5 | 9.69  | 18           |


    @fast
    Scenario Outline: Tobacco item has an effective date in the past for tobacco 21 law, 20yo customer passes age verification because he already was 18 when effective date hit
        Given the POS is in a ready to sell state
        And the POS displays Age verification frame after scanning an item barcode <barcode>
        When the cashier manually enters the <customer_age>yo customer's birthday
        Then the POS displays main menu frame
        And an item <description> with price <price> is in the virtual receipt
        And an item <description> with price <price> is in the current transaction

        Examples:
        | barcode     | description     | price | customer_age |
        | 05432123450 | Tobacco Item P1 | 8.69  | 20           |


    @fast
    Scenario Outline: Tobacco item has an effective date in the past for tobacco 21 law, customer, who had 18th birthday one day after the law has become effective, does not pass age verification
        Given the POS is in a ready to sell state
        And the POS displays Age verification frame after scanning an item barcode <barcode>
        When the cashier manually enters the birthday of a customer who was 18 one day after the effective date hit <effective_date_before_years> years ago
        Then the POS displays an Error frame saying Customer was not 18 when effective date hit <effective_date_before_years> years age and restriction moved to 21
        And an item <description> with price <price> is not in the virtual receipt
        And an item <description> with price <price> is not in the current transaction

        Examples:
        | barcode     | description     | price | effective_date_before_years |
        | 05432123450 | Tobacco Item P1 | 8.69  | 1                           |


    @fast
    Scenario Outline: Tobacco item has an effective date in the past for tobacco 21 law, customer, who had 18th birthday the same day as the law has become effective, does not pass age verification
        Given the POS is in a ready to sell state
        And the POS displays Age verification frame after scanning an item barcode <barcode>
        When the cashier manually enters the birthday of a customer who was 18 the same day as the effective date hit <effective_date_before_years> years ago
        Then the POS displays an Error frame saying Customer was not 18 when effective date hit <effective_date_before_years> years age and restriction moved to 21
        And an item <description> with price <price> is not in the virtual receipt
        And an item <description> with price <price> is not in the current transaction

        Examples:
        | barcode     | description     | price | effective_date_before_years |
        | 05432123450 | Tobacco Item P1 | 8.69  | 1                           |


    @fast
    Scenario Outline: Tobacco item has an effective date in the past for tobacco 21 law, customer, who had 18th birthday one day earlier than the law has become effective, passes age verification
        Given the POS is in a ready to sell state
        And the POS displays Age verification frame after scanning an item barcode <barcode>
        When the cashier manually enters the birthday of a customer who was 18 one day before the effective date hit <effective_date_before_years> years ago
        Then the POS displays main menu frame
        And an item <description> with price <price> is in the virtual receipt
        And an item <description> with price <price> is in the current transaction

        Examples:
        | barcode     | description     | price | effective_date_before_years |
        | 05432123450 | Tobacco Item P1 | 8.69  | 1                           |
