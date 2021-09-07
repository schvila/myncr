import os
import unittest
import bs4
from typing import Union
from cfrpos.core.relay import ModifierRelay


class TestModifierRelay(unittest.TestCase):
    def setUp(self):
        self.relay = ModifierRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

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

    def test_create_modifier_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_modifier(123, 456, 'Modifier name')
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<ModifierRecs>'
                    '<record>'
                        '<ModifierId>123</ModifierId>'
                        '<DescriptionId>0</DescriptionId>'
                        '<ModifierLevel>456</ModifierLevel>'
                        '<Description>Modifier name</Description>'
                        '<LockStatus>0</LockStatus>'
                    '</record>'
                '</ModifierRecs>',
                self.extract_tag(self.relay.to_xml(), 'ModifierRecs'))

if __name__ == '__main__':
    unittest.main()
