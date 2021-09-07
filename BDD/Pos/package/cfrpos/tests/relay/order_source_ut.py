import os
import unittest
import bs4
from typing import Union
from cfrpos.core.relay import OrderSourceRelay


class TestOrderSourceRelay(unittest.TestCase):
    def setUp(self):
        self.relay = OrderSourceRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

    def tearDown(self):
        del self.relay

    def extract_tag(self, xml: str, tag_name: str) -> Union[None, str]:
        xml_tree = bs4.BeautifulSoup(xml, "xml")
        tag = xml_tree.find(tag_name)
        return str(tag) if tag is not None else ''

    def test_dataset(self):
        self.assertTrue(self.relay.update_required)
        self.relay.notify_applied()
        self.assertFalse(self.relay.update_required)

    def test_create_order_source_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.define_order_source_behavior('Order source 1', True)
        self.relay.define_order_source_behavior('Order source 2', True)
        self.relay.define_order_source_behavior('Order source 2', False) # This record should override the last one
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<OrderSourceRecs>'
                    '<record>'
                        '<ExternalId>Order source 1</ExternalId>'
                        '<DeferAgeVerificationFlag>1</DeferAgeVerificationFlag>'
                    '</record>'
                    '<record>'
                        '<ExternalId>Order source 2</ExternalId>'
                        '<DeferAgeVerificationFlag>0</DeferAgeVerificationFlag>'
                    '</record>'
                '</OrderSourceRecs>',
                self.extract_tag(self.relay.to_xml(), 'OrderSourceRecs'))

if __name__ == '__main__':
    unittest.main()
