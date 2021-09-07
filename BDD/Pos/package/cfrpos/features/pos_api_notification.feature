@pos @posapi @notifier
Feature: Pos Api notifications
    This feature file focuses on various topics sent from POS and captured on server/controller. These topics are generic and
    configured using LHModuleManagementValues.xml file. Controllers's end point are configured in LhDevCfg. PosApi reads these topics
    and controller's URI from PosApiNotifiation.dat file and send notification to registered Controllers.
    This feature file attempts to validate following topics.
        posconnect-v1-heart-beat
        posconnect-v1-transaction-started
        posconnect-v1-transaction-finalized
        posconnect-v1-transaction-canceled
        posconnect-v1-transaction-refunded
    Alerts are risen when server/controller (STM_CONTROLLER_OFFLINE alert) or their devices (STM_DEVICE_OFFLINE alert) don't work.
    There can be multiple services (controllers) configured, but alerts are not distinguishable. Thus, it's desirable
    to use just one configured service in the test environment.


    Background: POS is ready to sell and no transaction is in progress
        Given the POS has essential configuration
        And the POS has the feature PosApiServer enabled
        And the POS API notification server has default configuration
        And the POS has following sale items configured
        | barcode       | description    | price  | external_id          | internal_id                   |
        | 099999999990  | Sale Item A    | 0.99   | ITT-099999999990-0-1 | 990000000002-990000000007-0-0 |


    @slow
    Scenario: Pos sends heart beat topic to server to verify connection on every 20 seconds, validate the server captures the heart beat topic id.
        Given the POS is in a ready to sell state
        When the cashier scans a barcode 099999999990
        Then the POS API notification server captures topic id posconnect-v1-heart-beat


    @fast
     Scenario: Start the transaction, validate that server captures topic id from started transaction.
        Given the POS is in a ready to sell state
        When the cashier scans a barcode 099999999990
        Then the POS API notification server captures topic id posconnect-v1-transaction-started


    @fast
     Scenario: Finalize the transaction, validate that server captures topic id from finalized transaction.
        Given an item with barcode 099999999990 is present in the transaction
        When the cashier tenders the transaction with hotkey exact_dollar in cash
        Then the POS API notification server captures topic id posconnect-v1-transaction-finalized


    @fast
     Scenario: Void the transaction, validate that server captures topic id from void transaction.
        Given an item with barcode 099999999990 is present in the transaction
        When the cashier voids the transaction
        Then the POS API notification server captures topic id posconnect-v1-transaction-canceled


    @fast
    Scenario: Refund the transaction, validate the server captures topic id from refunded transaction.
        # "Allows refund after items" when pos option is enabled
        Given the POS option 1301 is set to 1
        And the POS is in a ready to sell state
        And an item with barcode 099999999990 is present in the transaction
        When the cashier switches the transaction to refund
        Then the POS API notification server captures topic id posconnect-v1-transaction-refunded


    @negative @fast
    Scenario: The transaction is switched to refund and an item was added, select tender, validate server does not capture topic id from refunded transaction
        Given the POS is in a ready to sell state
        And the transaction is switched to refund
        And an item with barcode 099999999990 is present in the transaction
        When the cashier presses the cash tender button
        Then the POS API notification server does not capture topic id posconnect-v1-transaction-refunded


    @pos @slow
    Scenario: Controller alert is displayed when POS cannot obtain response on notification request
        Given the POS is in a ready to sell state
        When the POS API notification server does not respond
        Then the POS displays the STM_CONTROLLER_OFFLINE alert


    @pos @fast
    Scenario: No alert is displayed when POS obtains empty alert list
        Given the POS is in a ready to sell state
        When the POS API notification server returns empty alert list
        Then the POS does not display any notification alert


    @pos @fast
    Scenario: Displayed alerts disappear when POS obtains empty alert list
        Given the POS API notification server does not respond
        And the POS is in a ready to sell state
        And the POS displays the POS API notification alert STM_CONTROLLER_OFFLINE
        When the POS API notification server returns empty alert list
        Then the POS does not display any notification alert


    @pos @fast
    Scenario: Device alert is displayed when POS obtains non-empty alert list
        Given the POS is in a ready to sell state
        When the POS API notification server returns alert Device offline
        Then the POS displays the STM_DEVICE_OFFLINE alert
        And the POS does not display the STM_CONTROLLER_OFFLINE alert
