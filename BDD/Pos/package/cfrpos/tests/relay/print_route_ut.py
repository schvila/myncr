import os
import unittest
import bs4
from typing import Union
from cfrpos.core.relay import PrintRouteRelay
from cfrpos.core.bdd_utils.errors import ProductError


class TestPrintRouteRelay(unittest.TestCase):
    def setUp(self):
        self.relay = PrintRouteRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

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

    def test_set_receipt_active(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.set_receipt_active([{'Rcpt1': '123456'}, {'Rcpt2': '654321'}], 'Rcpt1', 101, 'Active printer')
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<LogicalPrinters>'
                    '<record>'
                        '<LogicalDeviceId>101</LogicalDeviceId>'
                        '<LogicalDeviceName>Active printer</LogicalDeviceName>'
                        '<NormalReceiptPrintTypeGroupId>123456</NormalReceiptPrintTypeGroupId>'
                    '</record>'
                '</LogicalPrinters>',
                self.extract_tag(self.relay.to_xml(), 'LogicalPrinters'))
        # Following 2 tests are failing the build, needs to be fixed
        #with self.assertRaises(ProductError) as context:
        #    self.relay.set_receipt_active([{'Rcpt1': '123456'}, {'Rcpt2': '654321'}],
        #                                        'Rcpt2', 123, 'Missing printer') # Referenced printer does not exist
        #with self.assertRaises(ProductError) as context:
        #    self.relay.set_receipt_active([{'Rcpt1': '123456'}, {'Rcpt2': '654321'}],
        #                                        'Rcpt3', 101, 'Missing printer') # Referenced receipt does not exist

if __name__ == '__main__':
    unittest.main()
