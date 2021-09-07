import os
import unittest
import bs4
from typing import Union
from cfrpos.core.relay import BarcodeRelay


class TestBarcodeRelay(unittest.TestCase):
    def setUp(self):
        self.relay = BarcodeRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

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

    def test_create_barcode_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_barcode(1, 2, '09876543210', 3)
        self.relay.create_barcode(1, 4, '19876543210', 5) # This record should override the last one
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<BarcodeRecs>'
                    '<record>'
                        '<POSCode>19876543210</POSCode>'
                        '<POSCodeLength>11</POSCodeLength>'
                        '<POSCodeType>1</POSCodeType>'
                        '<UnitPackingID>5</UnitPackingID>'
                        '<ObjectID>1</ObjectID>'
                        '<Modifier1>4</Modifier1>'
                        '<Modifier2>0</Modifier2>'
                        '<Modifier3>0</Modifier3>'
                    '</record>'
                '</BarcodeRecs>',
                self.extract_tag(self.relay.to_xml(), 'BarcodeRecs'))

    def test_create_unit_packing_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_unit_packing(1, 6, 'sixpack')
        self.relay.create_unit_packing(1, 12, 'twelvepack') # This record should override the last one
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<UnitPackingIDRecs>'
                    '<record>'
                        '<UnitPackingID>1</UnitPackingID>'
                        '<PackQuantity>12</PackQuantity>'
                        '<Description>twelvepack</Description>'
                    '</record>'
                '</UnitPackingIDRecs>',
                self.extract_tag(self.relay.to_xml(), 'UnitPackingIDRecs'))

if __name__ == '__main__':
    unittest.main()
