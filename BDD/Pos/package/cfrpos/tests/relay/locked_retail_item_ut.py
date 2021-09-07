import os
import unittest
import bs4
from typing import Union
from cfrpos.core.relay import LockedRetailItemRelay


class TestLockedRetailItemRelay(unittest.TestCase):
    def setUp(self):
        self.relay = LockedRetailItemRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

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

    def test_lock_retail_item_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_locked_sale_item(123, 456)
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<LockedRetailItemRecs>'
                    '<record>'
                        '<ItemId>123</ItemId>'
                        '<Modifier1Id>456</Modifier1Id>'
                        '<Modifier2Id>0</Modifier2Id>'
                        '<Modifier3Id>0</Modifier3Id>'
                    '</record>'
                '</LockedRetailItemRecs>',
                self.extract_tag(self.relay.to_xml(), 'LockedRetailItemRecs'))

    def test_unlock_retail_item_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_locked_sale_item(123, 456)
        self.relay.remove_locked_sale_item(123)
        self.assertTrue(self.relay.update_required)
        self.assertEqual('<LockedRetailItemRecs/>', self.extract_tag(self.relay.to_xml(), 'LockedRetailItemRecs'))

if __name__ == '__main__':
    unittest.main()
