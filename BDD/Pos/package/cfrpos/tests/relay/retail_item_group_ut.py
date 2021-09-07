import os
import unittest
import bs4
from typing import Union
from cfrpos.core.relay import RetailItemGroupRelay


class TestRetailItemGroupRelay(unittest.TestCase):
    def setUp(self):
        self.relay = RetailItemGroupRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

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

    def test_create_retail_item_group(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_group(123456789, '')
        self.relay.create_group(456, '123abc')

        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<RetailItemGroupExternalIds>'
                    '<record>'
                        '<RetailItemGroupId>456</RetailItemGroupId>'
                        '<ExternalId>123abc</ExternalId>'
                    '</record>' 
                    '<record>'
                        '<RetailItemGroupId>123456789</RetailItemGroupId>'
                        '<ExternalId/>'
                    '</record>'               
                '</RetailItemGroupExternalIds>',
                self.extract_tag(self.relay.to_xml(), 'RetailItemGroupExternalIds'))

    def test_assign_item_to_group(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.assign_item_to_group(123456789, 123456, 0, 1)
        
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<RetailItemGroupItemList>'
                    '<record>'
                        '<RetailItemGroupId>123456789</RetailItemGroupId>'
                        '<ItemId>123456</ItemId>'
                        '<Modifier1Id>0</Modifier1Id>'
                        '<Modifier2Id>0</Modifier2Id>'
                        '<Modifier3Id>0</Modifier3Id>'
                        '<ItemType>1</ItemType>'
                        '<ItemMode2>0</ItemMode2>'
                    '</record>'     
                '</RetailItemGroupItemList>',
                self.extract_tag(self.relay.to_xml(), 'RetailItemGroupItemList'))
        

if __name__ == '__main__':
    unittest.main()
