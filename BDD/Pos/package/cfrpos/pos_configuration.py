def initialize_context(context):
    context.pos_options = {
                "Starting amounts": {
                    "option_id": 1448,
                    "option_values": {
                        "Use end of shift counts": 0,
                        "Prompt for amount": 1,
                        "Fixed amount": 2
                    }
                },
                "Fuel credit prepay method": {
                    "option_id": 1851,
                    "option_values": {
                        "Auth and Capture": 1,
                        "Sale and Refund": 2
                    }
                },
                "Loyalty Prompt Control": {
                    "option_id": 4214,
                    "option_values": {
                        "Do Not Prompt": 0,
                        "Prompt Always": 1
                    }
                },
                "Prepay Grade Select Type": {
                    "option_id": 5124,
                    "option_values": {
                        "None": 0,
                        "One Touch": 1,
                        "Confirmation": 2,
                        "Card Configuration": 3
                    }
                },
    }
    context.pos_operators = {
                "Cashier": "1234",
                "Manager": "2345",
    }


