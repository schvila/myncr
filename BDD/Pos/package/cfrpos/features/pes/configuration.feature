@pos @pes
Feature: Promotion Execution Service - configuration
    This feature file focuses on PES configuration

    Background: POS is configured for PES feature
       Given the POS has essential configuration
        And the POS is configured to communicate with PES
        # Cloud Loyalty Interface is set to PES
        And the POS option 5284 is set to 1
        And the nep-server has default configuration

    @slow
    Scenario: The configuration file is created by POS if gets deleted
        Given the POS is in a ready to start shift state
        And the cashier pressed the Start shift button
        And the PES configuration on site controller has following values
            | parameter              | value                                |
            | applicationKey         | XX8a00872e63ee3c6801653a0eed9f000b   |
            | baseServiceUrl         | http://127.0.0.1:8083                |
            | deviceId               | SC-123-OrderService                  |
            | enterpriseUnit         | XX13de0ec5e16244498473693ce3a8555c   |
            | notificationServiceUrl | wss://notifications.ncrplatform.com/ |
            | organization           | pcr-sitecontroller                   |
            | proxyServerUrl         |                                      |
            | secretKey              | XX99de0ec5e16244498473693ce3a8555c   |
            | sharedKey              | XX8a00860b6641a0ae016659377a510021   |
        And the PES configuration file does not exist
        When the cashier enters 1234 pin
        Then the PES configuration file is created within 3s


    @slow
    Scenario: The configuration file is updated by POS on login, secret key is stored encrypted
        Given the POS is in a ready to start shift state
        And the cashier pressed the Start shift button
        And the PES configuration on site controller has following values
            | parameter              | value                                |
            | applicationKey         | YY8a00872e63ee3c6801653a0eed9f000b   |
            | baseServiceUrl         | http://127.0.0.1:8083                |
            | deviceId               | SC-123-OrderService                  |
            | enterpriseUnit         | YY13de0ec5e16244498473693ce3a8555c   |
            | notificationServiceUrl | wss://notifications.ncrplatform.com/ |
            | organization           | pcr-sitecontroller                   |
            | proxyServerUrl         |                                      |
            | secretKey              | YY99de0ec5e16244498473693ce3a8555c   |
            | sharedKey              | YY8a00860b6641a0ae016659377a510021   |
        When the cashier enters 1234 pin
        Then the PES configuration file contains following values after 3s
            | applicationKey         | YY8a00872e63ee3c6801653a0eed9f000b   |
            | deviceId               | SC-123-OrderService                  |
            | enterpriseUnit         | YY13de0ec5e16244498473693ce3a8555c   |
            | hostName               | 127.0.0.1                            |
            | hostPort               | 8083                                 |
            | organization           | pcr-sitecontroller                   |
            | protocol               | http                                 |
            | secretKey              | YY99de0ec5e16244498473693ce3a8555c   |
            | sharedKey              | YY8a00860b6641a0ae016659377a510021   |
