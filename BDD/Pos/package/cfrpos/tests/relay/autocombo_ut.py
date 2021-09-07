import os
import unittest
import bs4
from typing import Union
from cfrpos.core.relay import AutoComboRelay


class TestAutoComboRelay(unittest.TestCase):
    def setUp(self):
        self.relay = AutoComboRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

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

    def test_create_autocombo_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_autocombo_record(100, 'Autocombo UT 1', 'ext ID', '2013-06-25T00:00:00', '1999-01-01T00:00:00', 2, 3)
        self.relay.create_autocombo_record(101, 'Autocombo UT 2')
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<AutoComboRecord>'
                    '<record>'
                        '<ComboId>100</ComboId>'
                        '<StartDateTime>2013-06-25T00:00:00</StartDateTime>'
                        '<EndDateTime>1999-01-01T00:00:00</EndDateTime>'
                        '<Description>Autocombo UT 1</Description>'
                        '<MaxPerTran>3</MaxPerTran>'
                        '<ModeFlag>2</ModeFlag>'
                        '<ExternalId>ext ID</ExternalId>'
                    '</record>'
                    '<record>'
                        '<ComboId>101</ComboId>'
                        '<StartDateTime>2012-06-25T00:00:00</StartDateTime>'
                        '<EndDateTime>1899-01-01T00:00:00</EndDateTime>'
                        '<Description>Autocombo UT 2</Description>'
                        '<MaxPerTran>0</MaxPerTran>'
                        '<ModeFlag>0</ModeFlag>'
                        '<ExternalId/>'
                    '</record>'
                '</AutoComboRecord>',
                self.extract_tag(self.relay.to_xml(), 'AutoComboRecord'))

    def test_create_requirement_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_requirement_record('req desc', 123, 321, 3, 2, 1)
        self.relay.create_requirement_record('req desc2', 1234, 4321, 5)
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<ComboRequirementRecord>'
                    '<record>'
                        '<ComboRequirementId>123</ComboRequirementId>'
                        '<ComboId>123</ComboId>'
                        '<GroupId>321</GroupId>'
                        '<ModeFlag>2</ModeFlag>'
                        '<QuantityRequired>3</QuantityRequired>'
                        '<AmountRequired>1</AmountRequired>'
                    '</record>'
                    '<record>'
                        '<ComboRequirementId>1234</ComboRequirementId>'
                        '<ComboId>1234</ComboId>'
                        '<GroupId>4321</GroupId>'
                        '<ModeFlag>0</ModeFlag>'
                        '<QuantityRequired>5</QuantityRequired>'
                        '<AmountRequired>0</AmountRequired>'
                    '</record>'
                '</ComboRequirementRecord>',
                self.extract_tag(self.relay.to_xml(), 'ComboRequirementRecord'))

    def test_create_autocombo_external_id_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_autocombo_external_id(1, 'ext id 1')
        self.relay.create_autocombo_external_id(1, 'ext id 2') # This record should override the last one
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<AutoComboExternalIds>'
                    '<record>'
                        '<ComboId>1</ComboId>'
                        '<ExternalId>ext id 2</ExternalId>'
                    '</record>'
                '</AutoComboExternalIds>',
                self.extract_tag(self.relay.to_xml(), 'AutoComboExternalIds'))

    def test_create_discount_id_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_discount_id(9, 8, 7)
        self.relay.create_discount_id(9, 6, 5) # This record should override the last one
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<DiscountIdRecord>'
                    '<record>'
                        '<ComboRequirementId>9</ComboRequirementId>'
                        '<DiscountId>6</DiscountId>'
                        '<MinDiscountAmount>5</MinDiscountAmount>'
                    '</record>'
                '</DiscountIdRecord>',
                self.extract_tag(self.relay.to_xml(), 'DiscountIdRecord'))

    def test_create_item_group_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_item_group_record(10, 20, 30, 1, 2, 3)
        self.relay.create_item_group_record(11, 12)
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<ItemGroupRecord>'
                    '<record>'
                        '<ItemId>10</ItemId>'
                        '<Modifier1Id>20</Modifier1Id>'
                        '<Modifier2Id>2</Modifier2Id>'
                        '<Modifier3Id>3</Modifier3Id>'
                        '<GroupId>30</GroupId>'
                        '<ItemType>1</ItemType>'
                    '</record>'
                    '<record>'
                        '<ItemId>11</ItemId>'
                        '<Modifier1Id>12</Modifier1Id>'
                        '<Modifier2Id>0</Modifier2Id>'
                        '<Modifier3Id>0</Modifier3Id>'
                        '<GroupId>990000000004</GroupId>'
                        '<ItemType>0</ItemType>'
                    '</record>'
                '</ItemGroupRecord>',
                self.extract_tag(self.relay.to_xml(), 'ItemGroupRecord'))

if __name__ == '__main__':
    unittest.main()
