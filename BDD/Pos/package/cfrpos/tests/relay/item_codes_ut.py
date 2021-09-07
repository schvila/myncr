import os
import unittest
import bs4
from typing import Union
from cfrpos.core.relay import ItemCodesRelay


class TestItemCodesRelay(unittest.TestCase):
    def setUp(self):
        self.relay = ItemCodesRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

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

    def test_create_external_id_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_item_external_code(123, '321')
        self.relay.create_item_external_code(123, '456') # This record should override the last one
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<ExternalCodes>'
                    '<record>'
                        '<ItemId>123</ItemId>'
                        '<ExternalId>456</ExternalId>'
                    '</record>'
                '</ExternalCodes>',
                self.extract_tag(self.relay.to_xml(), 'ExternalCodes'))

if __name__ == '__main__':
    unittest.main()
