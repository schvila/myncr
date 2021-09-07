@pos @pinpad_reboot
Feature: Daily pinpad reboot
    This feature file covers scenarios related to the daily reboot of pinpad device. POS cache first notifies the POS
    that the reboot is going to happen in five minutes and POS reacts by displaying an alert. Upon touching the alert,
    POS should display a frame with the remaining time until the reboot happens. Once the pinpad is rebooted, poscache
    sends another notification and POS removes the alert.

    Background: POS is properly configured for daily pinpad reboot feature
        Given the POS has essential configuration


    @fast
    Scenario: PosCache sends the "pinpad reboot in 5 minutes" notification, POS displays the alert
        Given the POS is in a ready to sell state
        When the POSCache simulator sends a message PinPadRebootWarning to the POS
        Then the POS displays the STM_PINPAD_REBOOT_ALERT alert


    @fast
    Scenario: PosCache sends the "pinpad rebooted" notification, POS removes the alert
        Given the POS is in a ready to sell state
        And the POS displays the STM_PINPAD_REBOOT_ALERT alert
        When the POSCache simulator sends a message PinPadRebooted to the POS
        Then the POS does not display the STM_PINPAD_REBOOT_ALERT alert


    @fast
    Scenario: Cashier presses reboot alert and POS displays a message "pinpad is rebooting"
        Given the POS is in a ready to sell state
        And the POS does not display the STM_PINPAD_REBOOT_ALERT alert
        And the pinpad is set to reboot in 0 min 1 sec
        And the POSCache simulator sent a message PinPadRebootWarning to the POS
        When the cashier presses alert STM_PINPAD_REBOOT_ALERT
        Then the POS displays Pinpad rebooting frame with no time


    @fast
    Scenario: Cashier presses reboot alert and POS displays a message "pinpad reboots in a minute"
        Given the POS is in a ready to sell state
        And the POS does not display the STM_PINPAD_REBOOT_ALERT alert
        And the pinpad is set to reboot in 1 min 0 sec
        And the POSCache simulator sent a message PinPadRebootWarning to the POS
        When the cashier presses alert STM_PINPAD_REBOOT_ALERT
        Then the POS displays Pinpad will reboot frame in less than minute


    @fast
    Scenario: Cashier presses reboot alert and POS displays a message "pinpad reboots in 5 minutes"
        Given the POS is in a ready to sell state
        And the POS does not display the STM_PINPAD_REBOOT_ALERT alert
        And the pinpad is set to reboot in 5 min 0 sec
        And the POSCache simulator sent a message PinPadRebootWarning to the POS
        When the cashier presses alert STM_PINPAD_REBOOT_ALERT
        Then the POS displays Pinpad will reboot frame in less than 5 minutes


    @fast
    Scenario: Cashier presses reboot alert multiple times, only one instance of the pinpad reboot frame is opened
        Given the POS is in a ready to sell state
        And the POS displays the STM_PINPAD_REBOOT_ALERT alert
        And the cashier pressed alert STM_PINPAD_REBOOT_ALERT 5 times
        When the cashier presses Go back button
        Then the POS displays main menu frame


    @fast
    Scenario: Cashier presses reboot alert when POS displays a modal frame, pinpad reboot frame is not displayed
        Given the POS is in a ready to sell state
        And the POS displays the STM_PINPAD_REBOOT_ALERT alert
        And the POS displays Price check frame
        When the cashier presses alert STM_PINPAD_REBOOT_ALERT
        Then the POS displays Price check frame


    @glacial
    Scenario: PosCache does not send the "pinpad rebooted" notification, POS removes the alert after 5 minutes of expected reboot time
        Given the POS is in a ready to sell state
        And the POS does not display the STM_PINPAD_REBOOT_ALERT alert
        And the pinpad is set to reboot in 0 min 1 sec
        And the POSCache simulator sent a message PinPadRebootWarning to the POS
        When the POS is inactive for 300 seconds
        Then the POS does not display the STM_PINPAD_REBOOT_ALERT alert


    @glacial
    Scenario: PosCache does not send the "pinpad rebooted" notification, POS displays the alert until 5 minutes of expected reboot time
        Given the POS is in a ready to sell state
        And the POS does not display the STM_PINPAD_REBOOT_ALERT alert
        And the pinpad is set to reboot in 0 min 1 sec
        And the POSCache simulator sent a message PinPadRebootWarning to the POS
        When the POS is inactive for 200 seconds
        Then the POS displays the STM_PINPAD_REBOOT_ALERT alert


    @glacial
    Scenario: PosCache does not send the "pinpad rebooted" notification, POS is offline 5 minutes after expected reboot time,
              the alert is removed once POS comes online
        Given the POS is in a ready to sell state
        And the POS does not display the STM_PINPAD_REBOOT_ALERT alert
        And the pinpad is set to reboot in 0 min 1 sec
        And the POSCache simulator sent a message PinPadRebootWarning to the POS
        When the POS is inactive for 297 seconds and then reboots
        Then the POS does not display the STM_PINPAD_REBOOT_ALERT alert


    @slow
    Scenario: POS has been restarted after receiving pin-pad reboot warning, cashier presses pinpad reboot alert,
              the POS displays a reboot message
        Given the POS is in a ready to sell state
        And the POS does not display the STM_PINPAD_REBOOT_ALERT alert
        And the pinpad is set to reboot in 1 min 0 sec
        And the POSCache simulator sent a message PinPadRebootWarning to the POS
        And the POS has rebooted
        When the cashier presses alert STM_PINPAD_REBOOT_ALERT
        Then the POS displays Pinpad will reboot frame in less than minute