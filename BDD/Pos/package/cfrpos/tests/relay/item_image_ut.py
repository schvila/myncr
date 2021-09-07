import os
import unittest
import bs4
from typing import Union
from cfrpos.core.relay import ItemImageRelay


class TestItemImageRelay(unittest.TestCase):
    def setUp(self):
        self.relay = ItemImageRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

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

    def test_create_sale_item_definition(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_sale_item_definition(9900000100, 0)
        self.relay.create_sale_item_definition(100, 10)
        self.relay.create_sale_item_definition(100, 0) # This record should override the last one

        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<SalesItemDefRecs>'
                    '<record>'
                        '<ItemId>100</ItemId>'
                        '<Modifier1DefaultId>0</Modifier1DefaultId>'
                        '<Modifier2DefaultId>0</Modifier2DefaultId>'
                        '<Modifier3DefaultId>0</Modifier3DefaultId>'
                        '<Modifier1Required>0</Modifier1Required>'
                        '<Modifier2Required>0</Modifier2Required>'
                        '<Modifier3Required>0</Modifier3Required>'
                    '</record>'
                    '<record>'
                        '<ItemId>9900000100</ItemId>'
                        '<Modifier1DefaultId>0</Modifier1DefaultId>'
                        '<Modifier2DefaultId>0</Modifier2DefaultId>'
                        '<Modifier3DefaultId>0</Modifier3DefaultId>'
                        '<Modifier1Required>0</Modifier1Required>'
                        '<Modifier2Required>0</Modifier2Required>'
                        '<Modifier3Required>0</Modifier3Required>'
                    '</record>'
                '</SalesItemDefRecs>',
                self.extract_tag(self.relay.to_xml(), 'SalesItemDefRecs'))


if __name__ == '__main__':
    unittest.main()
