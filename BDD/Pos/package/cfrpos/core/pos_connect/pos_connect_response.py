import json
from cfrpos.core.bdd_utils.errors import ProductError

class POSConnectResponse:
    def __init__(self, response_code):
        self.code = int(response_code)
        self.message = ''
        self.data = {}

    def is_success(self):
        return self.code == 200 and self.message is not None and str(self.message) != ''

    def __str__(self):
        return '[code {}, message "{}", data {}]'.format(self.code, self.message, json.dumps(self.data))

    def pretty_str(self) -> str:
        """
        Returns response in more human readable form.
        :rtype: str
        """
        return '[\ncode: {}\nmessage: "{}"\n{}\n]'.format(self.code, self.message, json.dumps(self.data, sort_keys=True, indent=4))

    def extract_loyalty_transaction_id(self) -> str:
        """
        Get loyalty transaction ID from items returned in response on POSConnect requests.
        """
        loyalty_transaction_id = None
        for item in self.data.get('ItemList', []):
            if 'LoyaltyTransactionId' in item:
                loyalty_transaction_id = item['LoyaltyTransactionId']
                break

        if loyalty_transaction_id is None:
            raise ProductError('LoyaltyTransactionId was not found in response.')
     
        return loyalty_transaction_id

   
    def extract_request_id(self) -> str:
        """
        Get RequestId from the messages element returned in response on POSConnect requests.
        """
        request_id = None
        messages = self.data.get("Messages")
        if messages is not None:
            for message in messages:
                for key, value in message.items():
                            if 'Payload' in key:
                                request_id = value.get("RequestId")
                                return request_id                            
        if request_id is None:
            raise ProductError('request_id was not found in response.')
